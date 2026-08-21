# Healthbars Changelog

## 26.08.21

* **Overhauled per-enemy settings.** Each enemy can now be configured individually with separate toggles for the healthbar, damage numbers, DPS report, info label, DoT indicators, and debuff indicators. This also allows combinations such as DoTs or debuffs without showing a healthbar. Existing enemy display settings are migrated automatically.

* **Modernized the settings menu for the current Darktide Mod Framework.** Settings are now structured around DMF's native grouping and nested settings functionality, icon packages are managed through the mod definition, and settings icon handling has been updated. Compatibility with `Alfs_DMF_Extensions` is preserved.

* **Added a separate post-kill duration for DPS reports.** The new `DPS report duration` setting controls how long the final DPS result remains visible after an enemy dies, independently from the normal post-kill healthbar and info label duration. It defaults to 3 seconds and can be configured from 0 to 10 seconds.

## 0.0.0

Empty changelog.
