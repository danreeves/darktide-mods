#!/usr/bin/env python3
"""Detect changed mods and upload them to Nexus Mods using the v3 API.

Reads version, mod_id, and optionally file_group_id from each mod's .mod
file. When file_group_id is not set, it is resolved automatically from the
API using the mod_id: the script fetches all file update groups for the mod
and uses the group if there is exactly one. Set file_group_id explicitly in
the .mod file to choose a specific group when a mod has more than one.

Usage:
    python3 scripts/ci/publish_mods.py [--dry-run]

Required environment variables (unless --dry-run):
    NEXUSMODS_API_KEY       Your Nexus Mods v3 API key
    GITHUB_SHA              The current commit SHA
    GITHUB_BEFORE           The previous commit SHA (set by GitHub Actions on push)

Optional environment variables:
    NEXUSMODS_GAME_DOMAIN   Nexus Mods game domain slug (default: warhammer40kdarktide)
"""

import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, urlopen

NULL_COMMIT = "0000000000000000000000000000000000000000"
API_BASE = os.environ.get("NEXUSMODS_API_BASE", "https://api.nexusmods.com/v3").rstrip("/")
GAME_DOMAIN = os.environ.get("NEXUSMODS_GAME_DOMAIN", "warhammer40kdarktide")
MULTIPART_THRESHOLD = 100 * 1024 * 1024  # 100 MiB


def exec_cmd(args):
    result = subprocess.run(args, capture_output=True, text=True)
    return result.stdout.strip()


def api_request(method, path, api_key, body=None):
    url = f"{API_BASE}{path}"
    headers = {
        "apikey": api_key,
        "User-Agent": "danreeves/darktide-mods publish script",
    }
    data = None
    if body is not None:
        data = json.dumps(body).encode()
        headers["Content-Type"] = "application/json"
    req = Request(url, data=data, headers=headers, method=method)
    try:
        with urlopen(req) as resp:
            return json.loads(resp.read().decode())
    except HTTPError as e:
        body_text = e.read().decode()
        raise RuntimeError(f"HTTP {e.code} from {method} {url}: {body_text}") from e


def extract_mod_info(path):
    """Extract version, mod_id, and file_group_id from a .mod file using regex."""
    try:
        with open(path, "r") as f:
            content = f.read()
    except Exception as e:
        print(f"Warning: could not read {path}: {e}", file=sys.stderr)
        return None

    version_m = re.search(r'\bversion\s*=\s*"([^"]+)"', content)
    mod_id_m = re.search(r'\bmod_id\s*=\s*"([^"]+)"', content)
    file_group_m = re.search(r'\bfile_group_id\s*=\s*"([^"]+)"', content)

    return {
        "version": version_m.group(1) if version_m else None,
        "mod_id": mod_id_m.group(1) if mod_id_m else None,
        "file_group_id": file_group_m.group(1) if file_group_m else None,
    }


def resolve_file_group_id(mod_id, api_key):
    """Resolve file_group_id from the API using the game-scoped mod_id.

    Calls GET /games/{game_domain}/mods/{mod_id} to get the mod UUID, then
    GET /mods/{uuid}/file-update-groups to list all update groups.

    Returns the group ID if exactly one group exists, otherwise raises.
    """
    mod_info = api_request("GET", f"/games/{GAME_DOMAIN}/mods/{mod_id}", api_key)
    mod_uuid = mod_info.get("id")
    if not mod_uuid:
        raise RuntimeError(f"Unexpected response from API: no 'id' field for mod {mod_id}")

    groups_info = api_request("GET", f"/mods/{mod_uuid}/file-update-groups", api_key)
    groups = groups_info.get("groups", [])

    if not groups:
        raise RuntimeError(
            f"No file update groups found for mod {mod_id}. "
            "Create a file update group on Nexus Mods first."
        )
    if len(groups) > 1:
        names = ", ".join(
            f"{g.get('id', '?')} ({g.get('name', '?')})" for g in groups
        )
        raise RuntimeError(
            f"Multiple file update groups found for mod {mod_id}: {names}. "
            "Set file_group_id explicitly in the .mod file."
        )
    group_id = groups[0].get("id")
    if not group_id:
        raise RuntimeError(f"Unexpected response from API: no 'id' in file update group for mod {mod_id}")
    return group_id


def get_prev_version(path, before):
    """Return the version string from the previous commit, or None."""
    if not before or before == NULL_COMMIT:
        return None
    result = subprocess.run(
        ["git", "show", f"{before}:{path}"],
        capture_output=True,
        text=True,
    )
    content = result.stdout
    if not content:
        return None
    version_m = re.search(r'\bversion\s*=\s*"([^"]+)"', content)
    return version_m.group(1) if version_m else None


def get_changed_mod_files(before, sha):
    if not before or before == NULL_COMMIT:
        output = exec_cmd(["git", "ls-files", "*.mod"])
    else:
        output = exec_cmd(["git", "diff", "--name-only", before, sha, "--", "*.mod"])
    files = [line.strip() for line in output.splitlines() if line.strip()]
    return [f for f in files if not f.startswith(".template-dmf/")]


def zip_mod(mod_name):
    result = subprocess.run(
        ["zip", "-r", f"{mod_name}.zip", mod_name],
        capture_output=True,
        text=True,
    )
    return result.returncode == 0 and os.path.exists(f"{mod_name}.zip")


def _put_to_presigned_url(url, data):
    """PUT binary data to a presigned S3 URL and return the ETag."""
    req = Request(
        url,
        data=data,
        method="PUT",
        headers={
            "Content-Type": "application/octet-stream",
            "Content-Length": str(len(data)),
        },
    )
    try:
        with urlopen(req) as resp:
            return resp.headers.get("ETag", "").strip('"')
    except HTTPError as e:
        raise RuntimeError(f"HTTP {e.code} uploading to presigned URL: {e.read().decode()}") from e


def _poll_until_available(upload_id, api_key):
    """Poll GET /uploads/{id} until state is 'available'."""
    for attempt in range(60):
        state_info = api_request("GET", f"/uploads/{upload_id}", api_key)
        state = state_info.get("state")
        print(f"    State: {state}")
        if state == "available":
            return
        delay = min(2 * (1.5 ** attempt), 30)
        time.sleep(delay)
    raise RuntimeError(f"Timed out waiting for upload {upload_id} to become available")


def upload_mod(mod_name, zip_path, version, file_group_id, api_key):
    """Upload a zipped mod to Nexus Mods using the v3 API.

    Uses single-part upload for files up to 100 MiB (POST /uploads), and
    multipart upload (POST /uploads/multipart) for larger files.
    """
    file_size = os.path.getsize(zip_path)
    zip_basename = os.path.basename(zip_path)

    if file_size <= MULTIPART_THRESHOLD:
        # Single-part upload (recommended for files ≤ 100 MiB)
        print(f"  Creating upload ({zip_basename}, {file_size} bytes)...")
        upload_info = api_request(
            "POST",
            "/uploads",
            api_key,
            {"filename": zip_basename, "size_bytes": file_size},
        )
        upload_id = upload_info["id"]
        presigned_url = upload_info["presigned_url"]
        print(f"  Upload ID: {upload_id}")

        print("  Uploading file...")
        with open(zip_path, "rb") as f:
            _put_to_presigned_url(presigned_url, f.read())
    else:
        # Multipart upload (required for files > 100 MiB)
        print(f"  Creating multipart upload ({zip_basename}, {file_size} bytes)...")
        upload_info = api_request(
            "POST",
            "/uploads/multipart",
            api_key,
            {"filename": zip_basename, "size_bytes": file_size},
        )
        upload_id = upload_info["id"]
        part_urls = upload_info["parts_presigned_url"]
        part_size = upload_info["parts_size"]
        complete_url = upload_info["complete_presigned_url"]
        print(f"  Upload ID: {upload_id} ({len(part_urls)} part(s) of {part_size} bytes each)")

        parts = []
        with open(zip_path, "rb") as f:
            for i, part_url in enumerate(part_urls):
                part_number = i + 1
                f.seek(i * part_size)
                chunk = f.read(part_size)
                print(f"  Uploading part {part_number}/{len(part_urls)} ({len(chunk)} bytes)...")
                etag = _put_to_presigned_url(part_url, chunk)
                parts.append((part_number, etag))

        print("  Completing multipart upload...")
        xml_parts = "\n".join(
            f"  <Part>\n    <PartNumber>{pn}</PartNumber>\n    <ETag>{etag}</ETag>\n  </Part>"
            for pn, etag in parts
        )
        xml = f"<CompleteMultipartUpload>\n{xml_parts}\n</CompleteMultipartUpload>"
        req = Request(
            complete_url,
            data=xml.encode(),
            method="POST",
            headers={"Content-Type": "application/xml"},
        )
        with urlopen(req):
            pass

    # Finalise the upload
    print("  Finalising upload...")
    api_request("POST", f"/uploads/{upload_id}/finalise", api_key)

    # Poll until the upload is in the "available" state
    print("  Waiting for upload to be processed...")
    _poll_until_available(upload_id, api_key)

    # Create a new version in the mod file update group
    print(f"  Creating new version in file group {file_group_id}...")
    result = api_request(
        "POST",
        f"/mod-file-update-groups/{file_group_id}/versions",
        api_key,
        {
            "upload_id": upload_id,
            "name": mod_name,
            "version": version,
            "file_category": "main",
        },
    )
    file_uid = result["id"]
    print(f"  Done — new file UID: {file_uid}")
    return file_uid


def main():
    dry_run = "--dry-run" in sys.argv

    if dry_run:
        sha = exec_cmd(["git", "rev-parse", "HEAD"])
        result = subprocess.run(["git", "rev-parse", "main"], capture_output=True, text=True)
        before = result.stdout.strip() if result.returncode == 0 else None
        api_key = None
        print(f"Dry run mode — SHA={sha}, before={before}")
    else:
        api_key = os.environ.get("NEXUSMODS_API_KEY")
        sha = os.environ.get("GITHUB_SHA")
        before = os.environ.get("GITHUB_BEFORE") or None

        if not api_key:
            print("Error: NEXUSMODS_API_KEY is not set", file=sys.stderr)
            sys.exit(1)
        if not sha:
            print("Error: GITHUB_SHA is not set", file=sys.stderr)
            sys.exit(1)

    mod_files = get_changed_mod_files(before, sha)

    if not mod_files:
        print("No changed .mod files detected.")
        sys.exit(0)

    uploaded = []
    skipped = []

    for path in mod_files:
        cur = extract_mod_info(path)
        if not cur or not cur["version"]:
            continue

        prev_version = get_prev_version(path, before)
        if cur["version"] == prev_version:
            continue

        mod_name = Path(path).parts[0]

        file_group_id = cur["file_group_id"]
        if not file_group_id:
            if not cur["mod_id"]:
                print(f"Skipping {mod_name}: neither file_group_id nor mod_id is set in .mod file")
                skipped.append(mod_name)
                continue
            if dry_run:
                print(f"  Dry run: would resolve file_group_id from API for mod_id={cur['mod_id']}")
                uploaded.append(mod_name)
                continue
            try:
                print(f"  Resolving file_group_id from API for mod_id={cur['mod_id']}...")
                file_group_id = resolve_file_group_id(cur["mod_id"], api_key)
                print(f"  Resolved file_group_id: {file_group_id}")
            except RuntimeError as e:
                print(f"Skipping {mod_name}: {e}", file=sys.stderr)
                skipped.append(mod_name)
                continue

        print(f"\nProcessing {mod_name} v{cur['version']} (file_group_id={file_group_id})...")

        if dry_run:
            print(f"  Dry run: would zip and upload {mod_name}")
            uploaded.append(mod_name)
            continue

        if not zip_mod(mod_name):
            print(f"Error: failed to create {mod_name}.zip", file=sys.stderr)
            continue

        try:
            upload_mod(mod_name, f"{mod_name}.zip", cur["version"], file_group_id, api_key)
            uploaded.append(mod_name)
        except Exception as e:
            print(f"Error uploading {mod_name}: {e}", file=sys.stderr)

    print()
    if uploaded:
        verb = "Would upload" if dry_run else "Uploaded"
        print(f"{verb} {len(uploaded)} mod(s): {', '.join(uploaded)}")
    else:
        print("No mods were uploaded.")

    if skipped:
        print(f"Skipped {len(skipped)} mod(s) with no file_group_id: {', '.join(skipped)}")

    sys.exit(0)


if __name__ == "__main__":
    main()
