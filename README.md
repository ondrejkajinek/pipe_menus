# Openbox pipe\_menus
Various pipe menus for openbox WM, all scripted in Lua. Feel free to use, modify, do what ever you want (restricted only by GPLv3)

* several lib-like lua scripts providing interface to necessary tools or other utils, in particular:
	- common.lua: package of utils
	- notification.lua: notify-send
	- openboxMenu.lua: creation of openbox menus, submenus, pipe-menus
	- system.lua: creating paths, piping commands, reading cmd stdouts
	- udisks2.lua: udisks2 wrapper
* some assets with l10n or icons:
	- iconSet.lua: containing icon sets for pipe menus
	- l10n.lua: definition of messages, in format l10n.<language\_code>.<script\_name>.<message\_name>
* scripts for creating different menus:
	- mpd_control.lua: controls MPD: player controls, switching whole playlists, selecting songs from playlist
	- process_management.lua: lists top processes, displays some info, able to kill or restart process
	- removable_devices.lua: lists removable devices, provides mount/unmount actions, displays some basic info about FS

