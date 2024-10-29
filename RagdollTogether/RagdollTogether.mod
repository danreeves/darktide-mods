return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`RagdollTogether` encountered an error loading the Darktide Mod Framework.")

		new_mod("RagdollTogether", {
			mod_script       = "RagdollTogether/scripts/mods/RagdollTogether/RagdollTogether",
			mod_data         = "RagdollTogether/scripts/mods/RagdollTogether/RagdollTogether_data",
			mod_localization = "RagdollTogether/scripts/mods/RagdollTogether/RagdollTogether_localization",
		})
	end,
	packages = {},
}
