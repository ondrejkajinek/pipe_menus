#!/usr/bin/env lua

--[[
--
-- Author: OndraK
--
-- This piece of lua code can be distributed under the terms of GNU GPL v3
--
--]]

local home = os.getenv("HOME")

package.path = home .. "/.config/openbox/pipe_menus/?.lua;" .. package.path
package.cpath = "/usr/lib/lua/luarocks/lib/lua/5.1/?.so;" .. package.cpath
require "common"
local l10n = require "l10n"
local openboxMenu = require "openboxMenu"
local system = require "system"
local lfs = require "lfs"

-- use only MPD part of l10n
l10n = l10n.cz.mpd

local iconSet =
{
	skipBackward = "/usr/share/icons/oxygen/32x32/actions/media-skip-backward.png",
	skipForward = "/usr/share/icons/oxygen/32x32/actions/media-skip-forward.png",
	playbackPause = "/usr/share/icons/oxygen/32x32/actions/media-playback-pause.png",
	seekBackward = "/usr/share/icons/oxygen/32x32/actions/media-seek-backward.png",
	random = home .. "/.icons/actions/media-random-tracks-amarok.png",
	repeatPlaylist = home .. "/.icons/actions/media-repeat-playlist-amarok.png"
}
local albumartSize = 80
local albumartName = "albumart.png"
local imageSuffixes = { "jpg", "jpeg" }
local playlistDirSeparator = "::"
local discographyName = "diskografie"

local cmds = {
	convertAlbumart = "convert '%s' -resize %dx%d '%s'",
	mpcCurrent = "mpc -f '%album% - %title%' current",
	mpcGetPath = system.pipe("grep '^%s' /etc/mpd.conf", "grep -oP '/[/\\w]+'"),
	mpcPlaylist = "mpc -f '%s' playlist",
	mpcStatus = system.pipe("mpc status", "grep -o '%s: on'"),
	mpdControl = debug.getinfo(1).source:gsub("@", "")
}

local function currentSong()
	return system.singleResult(cmds.mpcCurrent) or l10n.notPlaying
end

local function mpdOption(option)
	return system.singleResult(string.format(cmds.mpcStatus, option)) and "on" or "off"
end

local function mpdPath(path)
	return system.singleResult(string.format(cmds.mpcGetPath, path))
end

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

local function currentPlaylist()
	openboxMenu.beginPipemenu()
	local separator = "::C++::"
	local previousAlbumName = nil
	local no = 1
	local albumNo = 1
	local tags = { "%album%", "%track%", "%title%" }
	local playlistCmd = string.format(cmds.mpcPlaylist, table.concat(tags, separator))
	for track in system.resultLines(playlistCmd) do
		local albumName, trackNo, trackName = unpack(track:split(separator, 2))
		-- remove some nasty formats from trackNo
		local trackNo = trackNo:match("%d+")
		if albumName ~= previousAlbumName then
			if albumNo > 1 then
				openboxMenu.endMenu()
			end
			openboxMenu.beginMenu(string.format("mpd-playlist-%s-%d", string.lower(albumName), albumNo), albumName)
			albumNo = albumNo + 1
		end
		openboxMenu.button(string.format("%02d - %s", trackNo or 0, trackName), string.format("mpc play %d", no))
		no = no + 1
		previousAlbumName = albumName
	end
	if albumNo > 1 then
		openboxMenu.endMenu()
	end
	openboxMenu.endPipemenu()
end

local function savedPlaylists()
	openboxMenu.beginPipemenu()
	local playlistDir = mpdPath("playlist_directory")
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
	local library = mpdPath("music_directory")
	local trackFile = system.singleResult("mpc -f %file% current")
	local trackDir = system.parentDir(system.path(library, trackFile))
	local imageFilter = string.format("grep -E '%s'", table.concat(imageSuffixes, "|"))
	local imagesAvailable = false
	for image in system.resultLines(system.pipe(string.format("ls '%s'", trackDir), imageFilter)) do
		local imagePath = system.path(trackDir, image)
		local albumartPath = system.path(trackDir, albumartName)
		openboxMenu.button(image, string.format(cmds.convertAlbumart, imagePath, albumartSize, albumartSize, albumartPath))
		imagesAvailable = true
	end
	if not imagesAvailable then
		openboxMenu.item(l10n.noImagesFound)
	end
	openboxMenu.endPipemenu()
end

local function createControls()
	openboxMenu.beginPipemenu()
	openboxMenu.title(currentSong())
	openboxMenu.button(l10n.previousTrack, "mpc prev", iconSet.skipBackward)
	openboxMenu.button(l10n.playPause, "mpc toggle", iconSet.playbackPause)
	openboxMenu.button(l10n.fromBeginning, "mpc seek 0", iconSet.seekBackward)
	openboxMenu.button(l10n.nextTrack, "mpc next", iconSet.skipForward)

	openboxMenu.separator()

	openboxMenu.button(string.format("%s (%s)", l10n.random, mpdOption("random")), "mpc random", iconSet.random)
	openboxMenu.button(string.format("%s (%s)", l10n.repeating, mpdOption("repeat")), "mpc repeat", iconSet.repeatPlaylist)
	
	openboxMenu.separator()

	openboxMenu.subPipemenu("mpc-playlist", l10n.currentPlaylist, string.format("%s current-playlist", cmds.mpdControl))
	openboxMenu.subPipemenu("mpd-playlists", l10n.savedPlaylists, string.format("%s saved-playlists", cmds.mpdControl))

	openboxMenu.separator()

	openboxMenu.subPipemenu("mpc-albumarts", l10n.availableAlbumarts, string.format("%s albumart-convert", cmds.mpdControl))

	openboxMenu.endPipemenu()
end

local function help()
	print("TODO")
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

