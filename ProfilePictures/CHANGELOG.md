# ProfilePictures Changelog

## 26.08.23

Improved profile image loading reliability by normalizing problematic Steam CDN URLs, loading public avatar textures without backend authentication, adding graceful fallbacks, and introducing an optional image proxy for Linux/Proton users.
Fixed profile pictures being silently skipped when player presence data is not ready yet and re-enabled profile pictures in the pre-mission lobby with safe handling of reassigned player slots.
Added profile picture support to Find Player search results, including correct portrait frame handling and protection against stale image requests.
Added profile picture support to Party Finder player entries and group previews, including safe cleanup when switching groups, recycling entries, or closing the view.
Added profile picture support to the Social Menu player popup and the character loadout screen when viewing players.
Added separate settings for Player HUD, Social Menu, Lobby, End Screen, Party Finder, and Inventory / Character View, and localized all existing and new settings into all 12 supported Darktide languages.
Added profile pictures to Heretical Idol destruction notifications, controlled by the existing Player HUD setting.

## 0.0.0

Empty changelog.
