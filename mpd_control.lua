#!/usr/bin/env lua

--[[
--
-- Author: OndraK
--
-- This piece of lua code can be distributed under the terms of GNU GPL v3
--
--]]

package.path = os.getenv("HOME") .. "/.config/openbox/pipe_menus/libs/?.lua;" .. package.path
package.path = os.getenv("HOME") .. "/.config/openbox/pipe_menus/assets/?.lua;" .. package.path
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
local playlistDirSeparator = "::"
local discographyName = "diskografie"

local cmds = {
	convertAlbumart = "convert '%s' -resize %dx%d '%s'",
	mpdControl = debug.getinfo(1).source:gsub("@", "")
}

-- -- -- -- -- -- -- -- -- -- -- --
-- -- -- helper functions	-- -- --
-- -- -- -- -- -- -- -- -- -- -- --

local function newPlaylistDir(name)
	return {
		name = name,
		playlists = {}
	}
end

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
	openboxMenu.subPipemenu("mpc-playlist", l10n.currentPlaylist, string.format("%s current-playlist", cmds.mpdControl))
	openboxMenu.subPipemenu("mpd-playlists", l10n.savedPlaylists, string.format("%s saved-playlists", cmds.mpdControl))
end

local function otherControls()
	openboxMenu.subPipemenu("mpc-albumarts", l10n.availableAlbumarts, string.format("%s albumart-convert", cmds.mpdControl))
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
	openboxMenu.beginPipemenu()
	local separator = "::C++::"
	local previousAlbumName = nil
	local no = 0
	local albumNo = 0
	local tags = { "%album%", "%track%", "%title%" }
	for track in mpd.playlist(tags, separator) do
		local albumName, trackNo, trackName = unpack(track:split(separator, 2))
		local trackNo = trackNo:match("%d+")
		if albumName ~= previousAlbumName then
			if albumNo > 0 then
				openboxMenu.endMenu()
			end
			albumNo = albumNo + 1
			openboxMenu.beginMenu(string.format("mpd-playlist-%s-%d", string.lower(albumName), albumNo), albumName)
		end
		no = no + 1
		openboxMenu.button(string.format("%02d - %s", trackNo or 0, trackName), string.format("mpc play %d", no))
		previousAlbumName = albumName
	end
	if albumNo > 0 then
		openboxMenu.endMenu()
	end
	openboxMenu.endPipemenu()
end

local function savedPlaylists()
	openboxMenu.beginPipemenu()
	local playlistDir = mpd.path("playlist_directory")
	local lsCmd = system.pipe(string.format("ls %s", playlistDir), "grep '\\.m3u$'")
	local playlists = {}
	local playlistsDirIndex = {}
	for playlist in system.resultLines(lsCmd) do
		playlist = playlist:gsub("%.m3u$", "")
		if playlist:find(playlistDirSeparator) then
			local directory, playlist = unpack(playlist:split(playlistDirSeparator, 1))
			local dirIndex = playlistsDirIndex[directory]
			-- TODO: use __index metamethod
			if not dirIndex then
				dirIndex = #playlists + 1
				playlistsDirIndex[directory] = dirIndex
				playlists[dirIndex] = newPlaylistDir(directory)
			end
			local position = playlist == discographyName and 1 or #playlists[dirIndex].playlists + 1
			table.insert(playlists[dirIndex].playlists, position, playlist)
		else
			table.insert(playlists, playlist)
		end
	end
	for _, item in pairs(playlists) do
		if type(item) == "string" then
			openboxMenu.button(item, switchPlaylistAction(item))
		else
			openboxMenu.beginMenu(string.format("mpd-playlists-%s", item.name), item.name)
			for _, playlist in ipairs(item.playlists) do
				local fullName = string.format("%s%s%s", item.name, playlistDirSeparator, playlist)
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

