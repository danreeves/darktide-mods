#!/usr/bin/env node
/**
 * Detect changed mods and upload them to Nexus Mods using the v3 API.
 *
 * Reads version, mod_id, and optionally file_group_id from each mod's .mod
 * file. When file_group_id is not set, it is resolved automatically from the
 * API using the mod_id: the script fetches all file update groups for the mod
 * and uses the group if there is exactly one. Set file_group_id explicitly in
 * the .mod file to choose a specific group when a mod has more than one.
 *
 * Usage:
 *     node scripts/ci/publish_mods.js [--dry-run]
 *
 * Required environment variables (unless --dry-run):
 *     NEXUSMODS_APIKEY       Your Nexus Mods v3 API key
 *     GITHUB_SHA              The current commit SHA
 *     GITHUB_BEFORE           The previous commit SHA (set by GitHub Actions on push)
 *
 * Optional environment variables:
 *     NEXUSMODS_GAME_DOMAIN   Nexus Mods game domain slug (default: warhammer40kdarktide)
 */

"use strict";

const { spawnSync } = require("child_process");
const fs = require("fs");
const path = require("path");

const NULL_COMMIT = "0000000000000000000000000000000000000000";
const API_BASE = (
  process.env.NEXUSMODS_API_BASE || "https://api.nexusmods.com/v3"
).replace(/\/$/, "");
const GAME_DOMAIN = process.env.NEXUSMODS_GAME_DOMAIN || "warhammer40kdarktide";
const MULTIPART_THRESHOLD = 100 * 1024 * 1024; // 100 MiB

function execCmd(args) {
  const result = spawnSync(args[0], args.slice(1), { encoding: "utf8" });
  return (result.stdout || "").trim();
}

async function apiRequest(method, urlPath, apiKey, body) {
  const url = `${API_BASE}${urlPath}`;
  const headers = {
    apikey: apiKey,
    "User-Agent": "danreeves/darktide-mods publish script",
  };
  const init = { method };
  if (body !== undefined) {
    headers["Content-Type"] = "application/json";
    init.body = JSON.stringify(body);
  }
  init.headers = headers;

  const resp = await fetch(url, init);
  const text = await resp.text();
  if (!resp.ok) {
    throw new Error(`HTTP ${resp.status} from ${method} ${url}: ${text}`);
  }
  return JSON.parse(text);
}

function extractModInfo(filePath) {
  let content;
  try {
    content = fs.readFileSync(filePath, "utf8");
  } catch (e) {
    console.error(`Warning: could not read ${filePath}: ${e.message}`);
    return null;
  }

  const versionM = content.match(/\bversion\s*=\s*"([^"]+)"/);
  const modIdM = content.match(/\bmod_id\s*=\s*"([^"]+)"/);
  const fileGroupM = content.match(/\bfile_group_id\s*=\s*"([^"]+)"/);

  return {
    version: versionM ? versionM[1] : null,
    mod_id: modIdM ? modIdM[1] : null,
    file_group_id: fileGroupM ? fileGroupM[1] : null,
  };
}

async function resolveFileGroupId(modId, apiKey) {
  const modInfo = await apiRequest(
    "GET",
    `/games/${GAME_DOMAIN}/mods/${modId}`,
    apiKey,
  );
  const modUuid = modInfo.id;
  if (!modUuid) {
    throw new Error(
      `Unexpected response from API: no 'id' field for mod ${modId}`,
    );
  }

  const groupsInfo = await apiRequest(
    "GET",
    `/mods/${modUuid}/file-update-groups`,
    apiKey,
  );
  const groups = groupsInfo.groups || [];

  if (groups.length === 0) {
    throw new Error(
      `No file update groups found for mod ${modId}. ` +
        "Create a file update group on Nexus Mods first.",
    );
  }
  if (groups.length > 1) {
    const names = groups
      .map((g) => `${g.id || "?"} (${g.name || "?"})`)
      .join(", ");
    throw new Error(
      `Multiple file update groups found for mod ${modId}: ${names}. ` +
        "Set file_group_id explicitly in the .mod file.",
    );
  }
  const groupId = groups[0].id;
  if (!groupId) {
    throw new Error(
      `Unexpected response from API: no 'id' in file update group for mod ${modId}`,
    );
  }
  return groupId;
}

function getPrevVersion(filePath, before) {
  if (!before || before === NULL_COMMIT) return null;
  const result = spawnSync("git", ["show", `${before}:${filePath}`], {
    encoding: "utf8",
  });
  const content = result.stdout || "";
  if (!content) return null;
  const m = content.match(/\bversion\s*=\s*"([^"]+)"/);
  return m ? m[1] : null;
}

function getChangedModFiles(before, sha) {
  let output;
  if (!before || before === NULL_COMMIT) {
    output = execCmd(["git", "ls-files", "*.mod"]);
  } else {
    output = execCmd([
      "git",
      "diff",
      "--name-only",
      before,
      sha,
      "--",
      "*.mod",
    ]);
  }
  return output
    .split("\n")
    .map((l) => l.trim())
    .filter((l) => l && !l.startsWith(".template-dmf/"));
}

function zipMod(modName) {
  const result = spawnSync("zip", ["-r", `${modName}.zip`, modName], {
    encoding: "utf8",
  });
  return result.status === 0 && fs.existsSync(`${modName}.zip`);
}

async function putToPresignedUrl(url, data) {
  const resp = await fetch(url, {
    method: "PUT",
    headers: {
      "Content-Type": "application/octet-stream",
      "Content-Length": String(data.byteLength ?? data.length),
    },
    body: data,
  });
  if (!resp.ok) {
    const text = await resp.text();
    throw new Error(`HTTP ${resp.status} uploading to presigned URL: ${text}`);
  }
  const etag = resp.headers.get("ETag") || "";
  return etag.replace(/^"|"$/g, "");
}

async function pollUntilAvailable(uploadId, apiKey) {
  for (let attempt = 0; attempt < 60; attempt++) {
    const stateInfo = await apiRequest("GET", `/uploads/${uploadId}`, apiKey);
    const state = stateInfo.state;
    console.log(`    State: ${state}`);
    if (state === "available") return;
    const delay = Math.min(2 * Math.pow(1.5, attempt), 30) * 1000;
    await new Promise((resolve) => setTimeout(resolve, delay));
  }
  throw new Error(
    `Timed out waiting for upload ${uploadId} to become available`,
  );
}

async function uploadMod(modName, zipPath, version, fileGroupId, apiKey) {
  const fileSize = fs.statSync(zipPath).size;
  const zipBasename = path.basename(zipPath);
  let uploadId;

  if (fileSize <= MULTIPART_THRESHOLD) {
    console.log(`  Creating upload (${zipBasename}, ${fileSize} bytes)...`);
    const uploadInfo = await apiRequest("POST", "/uploads", apiKey, {
      filename: zipBasename,
      size_bytes: fileSize,
    });
    uploadId = uploadInfo.id;
    const presignedUrl = uploadInfo.presigned_url;
    console.log(`  Upload ID: ${uploadId}`);

    console.log("  Uploading file...");
    const data = fs.readFileSync(zipPath);
    await putToPresignedUrl(presignedUrl, data);
  } else {
    console.log(
      `  Creating multipart upload (${zipBasename}, ${fileSize} bytes)...`,
    );
    const uploadInfo = await apiRequest("POST", "/uploads/multipart", apiKey, {
      filename: zipBasename,
      size_bytes: fileSize,
    });
    uploadId = uploadInfo.id;
    const partUrls = uploadInfo.parts_presigned_url;
    const partSize = uploadInfo.parts_size;
    const completeUrl = uploadInfo.complete_presigned_url;
    console.log(
      `  Upload ID: ${uploadId} (${partUrls.length} part(s) of ${partSize} bytes each)`,
    );

    const fd = fs.openSync(zipPath, "r");
    const parts = [];
    for (let i = 0; i < partUrls.length; i++) {
      const partNumber = i + 1;
      const chunk = Buffer.alloc(
        Math.max(0, Math.min(partSize, fileSize - i * partSize)),
      );
      fs.readSync(fd, chunk, 0, chunk.length, i * partSize);
      console.log(
        `  Uploading part ${partNumber}/${partUrls.length} (${chunk.length} bytes)...`,
      );
      const etag = await putToPresignedUrl(partUrls[i], chunk);
      parts.push({ partNumber, etag });
    }
    fs.closeSync(fd);

    console.log("  Completing multipart upload...");
    const xmlParts = parts
      .map(
        ({ partNumber, etag }) =>
          `  <Part>\n    <PartNumber>${partNumber}</PartNumber>\n    <ETag>${etag}</ETag>\n  </Part>`,
      )
      .join("\n");
    const xml = `<CompleteMultipartUpload>\n${xmlParts}\n</CompleteMultipartUpload>`;
    const completeResp = await fetch(completeUrl, {
      method: "POST",
      headers: { "Content-Type": "application/xml" },
      body: xml,
    });
    if (!completeResp.ok) {
      const text = await completeResp.text();
      throw new Error(
        `HTTP ${completeResp.status} completing multipart upload: ${text}`,
      );
    }
  }

  console.log("  Finalising upload...");
  await apiRequest("POST", `/uploads/${uploadId}/finalise`, apiKey);

  console.log("  Waiting for upload to be processed...");
  await pollUntilAvailable(uploadId, apiKey);

  console.log(`  Creating new version in file group ${fileGroupId}...`);
  const result = await apiRequest(
    "POST",
    `/mod-file-update-groups/${fileGroupId}/versions`,
    apiKey,
    {
      upload_id: uploadId,
      name: modName,
      version,
      file_category: "main",
    },
  );
  const fileUid = result.id;
  console.log(`  Done — new file UID: ${fileUid}`);
  return fileUid;
}

async function main() {
  const dryRun = process.argv.includes("--dry-run");

  let sha, before, apiKey;

  if (dryRun) {
    sha = execCmd(["git", "rev-parse", "HEAD"]);
    const r = spawnSync("git", ["rev-parse", "main"], { encoding: "utf8" });
    before = r.status === 0 ? r.stdout.trim() : null;
    apiKey = null;
    console.log(`Dry run mode — SHA=${sha}, before=${before}`);
  } else {
    apiKey = process.env.NEXUSMODS_APIKEY;
    sha = process.env.GITHUB_SHA;
    before = process.env.GITHUB_BEFORE || null;

    if (!apiKey) {
      console.error("Error: NEXUSMODS_APIKEY is not set");
      process.exit(1);
    }
    if (!sha) {
      console.error("Error: GITHUB_SHA is not set");
      process.exit(1);
    }
  }

  const modFiles = getChangedModFiles(before, sha);

  if (modFiles.length === 0) {
    console.log("No changed .mod files detected.");
    process.exit(0);
  }

  const uploaded = [];
  const skipped = [];

  for (const filePath of modFiles) {
    const cur = extractModInfo(filePath);
    if (!cur || !cur.version) continue;

    const prevVersion = getPrevVersion(filePath, before);
    if (cur.version === prevVersion) continue;

    const modName = filePath.split("/")[0];

    let fileGroupId = cur.file_group_id;
    if (!fileGroupId) {
      if (!cur.mod_id) {
        console.log(
          `Skipping ${modName}: neither file_group_id nor mod_id is set in .mod file`,
        );
        skipped.push(modName);
        continue;
      }
      if (dryRun) {
        console.log(
          `  Dry run: would resolve file_group_id from API for mod_id=${cur.mod_id}`,
        );
        uploaded.push(modName);
        continue;
      }
      try {
        console.log(
          `  Resolving file_group_id from API for mod_id=${cur.mod_id}...`,
        );
        fileGroupId = await resolveFileGroupId(cur.mod_id, apiKey);
        console.log(`  Resolved file_group_id: ${fileGroupId}`);
      } catch (e) {
        console.error(`Skipping ${modName}: ${e.message}`);
        skipped.push(modName);
        continue;
      }
    }

    console.log(
      `\nProcessing ${modName} v${cur.version} (file_group_id=${fileGroupId})...`,
    );

    if (dryRun) {
      console.log(`  Dry run: would zip and upload ${modName}`);
      uploaded.push(modName);
      continue;
    }

    if (!zipMod(modName)) {
      console.error(`Error: failed to create ${modName}.zip`);
      continue;
    }

    try {
      await uploadMod(
        modName,
        `${modName}.zip`,
        cur.version,
        fileGroupId,
        apiKey,
      );
      uploaded.push(modName);
    } catch (e) {
      console.error(`Error uploading ${modName}: ${e.message}`);
    }
  }

  console.log();
  if (uploaded.length > 0) {
    const verb = dryRun ? "Would upload" : "Uploaded";
    console.log(`${verb} ${uploaded.length} mod(s): ${uploaded.join(", ")}`);
  } else {
    console.log("No mods were uploaded.");
  }

  if (skipped.length > 0) {
    console.log(
      `Skipped ${skipped.length} mod(s) with no file_group_id: ${skipped.join(", ")}`,
    );
  }

  process.exit(0);
}

main().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
