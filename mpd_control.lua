#!/usr/bin/env lua

--[[
--
-- Author: OndraK
--
-- This piece of lua code can be distributed under the terms of GNU GPL v3
--
--]]

local selfPath = debug.getinfo(1).source:gsub("@", "")
local selfDir = selfPath:gsub("[^/]+$", "")

package.path = selfDir .. "libs/?.lua;" .. package.path
package.path = selfDir .. "assets/?.lua;" .. package.path
package.cpath = "/usr/lib/lua/luarocks/lib/lua/5.1/?.so;" .. package.cpath
require "common"
local iconSet = require "iconSet"
local l10n = require "l10n"
local mpd = require "mpd"
local openboxMenu = require "openboxMenu"
local system = require "system"
local lfs = require "lfs"

-- use only MPD part of l10n
local lang = "cz"
l10n = l10n[lang].mpd
-- use only MPD icons
iconSet = iconSet.mpd

local albumartSize = 80
local albumartName = "albumart.png"
local imageSuffixes = { "jpg", "jpeg" }

local cmds = {
	convertAlbumart = "convert '%s' -resize %dx%d '%s'"
}

-- -- -- -- -- -- -- -- -- -- -- --
-- -- -- helper functions	-- -- --
-- -- -- -- -- -- -- -- -- -- -- --

local function switchPlaylistAction(playlistName)
	local escapedPlaylistName = playlistName:gsub("'", "\\'")
	return {
		"mpc clear",
		string.format("mpc load \"%s\"", playlistName),
		"mpc toggle"
	}
end

local function playbackControls()
	openboxMenu.button(l10n.previousTrack, "mpc prev", iconSet.skipBackward)
	openboxMenu.button(l10n.playPause, "mpc toggle", iconSet.playbackPause)
	openboxMenu.button(l10n.fromBeginning, "mpc seek 0", iconSet.seekBackward)
	openboxMenu.button(l10n.nextTrack, "mpc next", iconSet.skipForward)
end

local function modeControls()
	openboxMenu.button(string.format("%s (%s)", l10n.random, mpd.option("random")), "mpc random", iconSet.random)
	openboxMenu.button(string.format("%s (%s)", l10n.repeating, mpd.option("repeat")), "mpc repeat", iconSet.repeatPlaylist)
end

local function playlistControls()
	openboxMenu.subPipemenu("mpc-playlist", l10n.currentPlaylist, string.format("%s current-playlist", selfPath))
	openboxMenu.subPipemenu("mpd-playlists", l10n.savedPlaylists, string.format("%s saved-playlists", selfPath))
end

local function otherControls()
	openboxMenu.subPipemenu("mpc-albumarts", l10n.availableAlbumarts, string.format("%s albumart-convert", selfPath))
end

local function convertButton(songDir, image)
	local imagePath = system.path(songDir, image)
	local albumartPath = system.path(songDir, albumartName)
	openboxMenu.button(image, string.format(cmds.convertAlbumart, imagePath, albumartSize, albumartSize, albumartPath))
end

-- -- -- -- -- -- -- -- -- -- -- --
-- -- -- module functions  -- -- --
-- -- -- -- -- -- -- -- -- -- -- --

local function currentPlaylist()
	local playlist = mpd.currentPlaylist()
	openboxMenu.beginPipemenu()
	for _, album in ipairs(playlist) do
		openboxMenu.beginMenu(string.format("mpd-playlist-%s", album.name:lower()), album.name)
		for _, track in ipairs(album.tracks) do
			openboxMenu.button(track.name, string.format("mpc play %d", track.number))
		end
		openboxMenu.endMenu()
	end
	openboxMenu.endPipemenu()
end

local function savedPlaylists()
	local playlists = mpd.savedPlaylists()
	openboxMenu.beginPipemenu()
	for _, item in pairs(playlists) do
		if type(item) == "string" then
			openboxMenu.button(item, switchPlaylistAction(item))
		else
			openboxMenu.beginMenu(string.format("mpd-playlists-%s", item.name), item.name)
			for _, playlist in ipairs(item.playlists) do
				local fullName = string.format("%s%s%s", item.name, mpd.playlistSeparator(), playlist)
				openboxMenu.button(playlist, switchPlaylistAction(fullName))
			end
			openboxMenu.endMenu()
		end
	end
	openboxMenu.endPipemenu()
end

local function albumartConvert()
	openboxMenu.beginPipemenu()
	local songDir = mpd.currentSongDir()
	local imageFilter = string.format("grep -E '%s'", table.concat(imageSuffixes, "|"))
	local lsCmd = string.format("ls '%s'", songDir)
	local imagesAvailable = false
	for image in system.resultLines(system.pipe(lsCmd, imageFilter)) do
		convertButton(songDir, image)
		imagesAvailable = true
	end
	if not imagesAvailable then
		openboxMenu.item(l10n.noImagesFound)
	end
	openboxMenu.endPipemenu()
end

local function createControls()
	openboxMenu.beginPipemenu()
	openboxMenu.title(mpd.currentSong() or l10n.notPlaying)
	playbackControls()	
	openboxMenu.separator()
	modeControls()
	openboxMenu.separator()
	playlistControls()
	openboxMenu.separator()
	otherControls()
	openboxMenu.endPipemenu()
end

local function help()
	io.stderr:write("mpd_control script usage:\n")
	io.stderr:write("\mpd_control [OPTION]\n")
	io.stderr:write("\n")
	io.stderr:write("Available options:\n")
	local optionsTable =
	{
		"controls\t\tCreates menu with playback controls",
		"saved-playlists\t\tShows list of saved playlists, provides playlist switching functionality",
		"current-playlist\tShow songs in current playlist, sorted by albums, provides track switching",
		"albumart-convert\tLists available images in current song directry, able to convert images into small albumarts",
		"help\t\t\tPrints this help"
	}
	for _,option  in ipairs(optionsTable) do
		io.stderr:write(option .. "\n")
	end
end

local function main(option)
	local actions =
	{
		["controls"] = createControls,
		["saved-playlists"] = savedPlaylists,
		["current-playlist"] = currentPlaylist,
		["albumart-convert"] = albumartConvert,
		["help"] = help
	}
	local option = option or "controls"
	local action = actions[option] or help
	action()
end

main(unpack({ ... }))

