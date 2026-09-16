# ProfilePictures Changelog

## 26.08.24

Fixed an error that could appear when inspecting a player from the Party Finder, by ignoring preview players the profile image loader cannot read a platform from.
Added profile pictures to Party Finder inspect paths that only carry an account ID, by resolving it through the social service the way the Party Finder entries already do.
Fixed Social Menu roster entries falling back to the default portrait frame instead of the equipped one, by restoring the frame texture that the unload of a superseded frame icon resets.

## 26.08.23.1

Fixed an error that prevented profile pictures from loading on the loadout screen when inspecting a player from the Party Finder or the social menu.

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
