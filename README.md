# pipe_menus
Various pipe menus for openbox WM

	- several lib-like lua scripts providing interface to neccesary tools or other utils, in particular:
		- common.lua: package of utils
		- l10n.lua: definition of messages, in format l10n.<language_code>.<message_name>
		- notification.lua: notify-send
		- openboxMenu.lua: creation of openbox menus, submenus, pipe-menus
		- system.lua: piping commands, reading theirs stdouts
		- udisks2.lua: udisks2 wrapper
	- scripts for creating different menus:
		- mpd_control.lua: controls MPD: player controls, switching whole playlists, selecting songs from playlist
		- process_management.lua: lists top processes, displays some info, able to kill or restart process
		- removable_devices.lua: lists removable devices, provides mount/unmount actions, displays some basic info about FS
