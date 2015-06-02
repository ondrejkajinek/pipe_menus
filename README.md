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
	- l10n.lua: definition of messages, in format l10n.&lt;language\_code&gt;.&lt;script\_name&gt;.&lt;message\_name&gt;
* scripts for creating different menus:
	- mpd\_control.lua: controls MPD: player controls, switching whole playlists, selecting songs from playlist
	- process\_management.lua: lists top processes, displays some info, able to kill or restart process
	- removable\_devices.lua: lists removable devices, provides mount/unmount actions, displays some basic info about FS
	- service\_management.lua: controls system services: start/stop/restart. Table `managedServices` defines which services are managed. Service can be defined either as a string (single service) or a table (set of services). In the case of services set, all have to be in the same state.

