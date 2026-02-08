local NULL_COMMIT = "0000000000000000000000000000000000000000"

-- Check for --dry-run flag
local dry_run = false
for _, v in ipairs(arg) do
	if v == "--dry-run" then
		dry_run = true
		break
	end
end

-- extracts `version` and `mod_id` from a .mod file
local function extract(path)
	if not path then return { version = nil, mod_id = nil } end

	local ok, result = pcall(dofile, path)

	if not ok then
		return { version = nil, mod_id = nil, _err = tostring(result) }
	end

	if type(result) ~= "table" then
		return { version = nil, mod_id = nil }
	end

	return { version = result.version, mod_id = result.mod_id }
end

-- zips a mod directory and returns true if successful
local function zip_mod(mod_name)
	local zip_cmd = string.format('zip -r "%s.zip" "%s"', mod_name, mod_name)
	local ok = os.execute(zip_cmd)
	local zip_file = mod_name .. ".zip"
	local f = io.open(zip_file, "r")
	local file_exists = f ~= nil
	if f then f:close() end
	return ok or file_exists
end

-- executes a shell command and returns its output as a string
local function exec(cmd)
	local f = io.popen(cmd)
	if not f then return "" end
	local out = f:read("*a")
	f:close()
	return out
end

-- splits a string into lines and returns them as a table
local function split_lines(s)
	local t = {}
	if not s or s == "" then return t end
	local i = 1
	while true do
		local j = s:find("\n", i)
		if not j then
			local last = s:sub(i)
			if last ~= "" then table.insert(t, last) end
			break
		end
		table.insert(t, s:sub(i, j - 1))
		i = j + 1
	end
	return t
end

-- trims leading and trailing whitespace from a string
local function trim(s)
	if not s then return s end
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- main logic
local before, sha
if dry_run then
	sha = trim(exec("git rev-parse HEAD"))
	before = trim(exec("git rev-parse main"))
	print("Dry run mode:")
	print("Current commit: " .. sha)
	print("Main commit: " .. before)
else
	before = os.getenv("GITHUB_BEFORE")
	sha = os.getenv("GITHUB_SHA")
	if not sha then
		print("missing GITHUB_SHA")
		os.exit(1)
	end
end


local files_raw
if dry_run then
	files_raw = exec([[git diff --name-only "*.mod"]])
else
	if before == nil or before == NULL_COMMIT then
		files_raw = exec([[git ls-files '*.mod']])
	else
		local cmd = string.format('git diff --name-only %s %s -- "*.mod"', before, sha)
		files_raw = exec(cmd)
	end
end

local files = split_lines(files_raw)

-- Filter out template files from .template-dmf and empty strings
local filtered_files = {}
for _, path in ipairs(files) do
	path = trim(path)
	if path ~= "" and not path:find('^%.template%-dmf/') then
		table.insert(filtered_files, path)
	end
end

local changed = {}

for _, path in ipairs(filtered_files) do
	local cur = extract(path)

	local prev_content = nil
	if before and before ~= NULL_COMMIT then
		local esc = path:gsub('"', '\\"')
		local cmd = string.format('git show %s:"%s" 2>/dev/null', before, esc)
		prev_content = exec(cmd)
		if prev_content == nil or prev_content == "" then prev_content = nil end
	end

	local prev = { version = nil, mod_id = nil }
	if prev_content then
		local tmp = os.tmpname()
		local fh = io.open(tmp, "w")
		if fh then
			fh:write(prev_content); fh:close()
			prev = extract(tmp)
			os.remove(tmp)
		end
	end

	if cur and cur.version and cur.mod_id and cur.version ~= (prev and prev.version) then
		local mod_name = path:match("^([^/]+)")
		local upload_cmd = string.format('unex upload %s "%s.zip" -v "%s" -f "%s"', tostring(cur.mod_id),
			mod_name, tostring(cur.version), mod_name)
		if dry_run then
			print("Dry run: Would zip and upload " .. mod_name)
			table.insert(changed, mod_name) -- count in dry run too
		else
			if zip_mod(mod_name) then
				local upload_ok = os.execute(upload_cmd)
				if not upload_ok then
					print("Failed to upload " .. mod_name)
				else
					table.insert(changed, mod_name) -- count successful uploads
				end
			else
				print("Failed to zip " .. mod_name .. ", skipping upload")
			end
		end
	end
end

if #changed == 0 then
	if dry_run then
		print("Dry run: No changed mods with version bumps detected.")
	else
		print("No changed mods with version bumps detected.")
	end
else
	if dry_run then
		print("Dry run: Would upload " .. #changed .. " changed mod(s).")
	else
		print("Uploaded " .. #changed .. " changed mod(s).")
	end
end

os.exit(0)
