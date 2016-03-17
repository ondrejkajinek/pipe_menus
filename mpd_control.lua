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

package.path = "/home/ondra/programming/lua/?.lua;" .. selfDir .. "?.lua;" .. package.path

require "libs/common"
require "libs/decorators"
local iconSet = require "assets/iconSet"
local l10n = require "assets/l10n"
local mpd = require "libs/mpd"
local openboxMenu = require "libs/openboxMenu"
local system = require "libs/system"

-- use only MPD part of l10n
l10n = l10n[systemLanguage()].mpd
-- use only MPD icons
iconSet = iconSet.mpd

local albumartSize = 80
local albumartName = "albumart.png"
local cmds = {
	convertAlbumart = "convert %s -resize %dx%d %s"
}


-- -- -- -- -- -- -- -- -- -- -- --
-- -- -- helper functions	-- -- --
-- -- -- -- -- -- -- -- -- -- -- --

local function convertButton(songDir, image)
	local imagePath = system.path(songDir, system.escape(image))
	local albumartPath = system.path(songDir, albumartName)
	openboxMenu.button(image, string.format(cmds.convertAlbumart, imagePath, albumartSize, albumartSize, albumartPath))
end

local function modeControls()
	openboxMenu.button(string.format("%s (%s)", l10n.random, mpd.option("random")), "mpc random", iconSet.random)
	openboxMenu.button(string.format("%s (%s)", l10n.repeating, mpd.option("repeat")), "mpc repeat", iconSet.repeatPlaylist)
end

local function playbackControls()
	openboxMenu.button(l10n.previousTrack, "mpc prev", iconSet.skipBackward)
	openboxMenu.button(l10n.playPause, "mpc toggle", iconSet.playbackPause)
	openboxMenu.button(l10n.fromBeginning, "mpc seek 0", iconSet.seekBackward)
	openboxMenu.button(l10n.nextTrack, "mpc next", iconSet.skipForward)
end


local function playlistControls()
	openboxMenu.subPipemenu("mpc-playlist", l10n.currentPlaylist, string.format("%s current-playlist", selfPath))
	openboxMenu.subPipemenu("mpc-playlists", l10n.savedPlaylists, string.format("%s saved-playlists", selfPath))
end

local function otherControls()
	openboxMenu.subPipemenu("mpc-albumarts", l10n.availableAlbumarts, string.format("%s albumart-convert", selfPath))
end

local function switchPlaylistAction(playlistName)
	local escapedPlaylistName = playlistName:gsub('"', '\\"')
	return {
		"mpc clear",
		string.format("mpc load \"%s\"", escapedPlaylistName),
		"mpc toggle"
	}
end

local function savedPlaylistControls(playlist, parent)
	if type(playlist) == "string" then
		local fullName = mpd.fullPlaylistName(playlist, parent)
		openboxMenu.button(playlist, switchPlaylistAction(fullName))
	elseif type(playlist) == "table" then
		local fullPlaylistName = mpd.fullPlaylistName(playlist.name, parent)
		openboxMenu.beginMenu(string.format("mpd-playlists-%s", fullPlaylistName), playlist.name)
		openboxMenu.title(playlist.name)
		for _, subplaylist in ipairs(playlist.content) do
			savedPlaylistControls(subplaylist, fullPlaylistName)
		end
		openboxMenu.endMenu()
	end
end


-- -- -- -- -- -- -- -- -- -- -- --
-- -- -- module functions  -- -- --
-- -- -- -- -- -- -- -- -- -- -- --

local albumartConvert = decorator(openboxMenu.pipemenu(l10n.availableAlbumarts)) ..
function()
	local imagesAvailable = false
	for dir, image in mpd.availableAlbumarts() do
		convertButton(dir, image)
		imagesAvailable = true
	end
	if not imagesAvailable then
		openboxMenu.item(l10n.noImagesFound)
	end
end

local createControls = decorator(openboxMenu.pipemenu(mpd.currentSong() or l10n.notPlaying)) ..
function()
	playbackControls()
	openboxMenu.separator()
	modeControls()
	openboxMenu.separator()
	playlistControls()
	openboxMenu.separator()
	otherControls()
end

local currentPlaylist = decorator(openboxMenu.pipemenu(l10n.currentPlaylist)) ..
function()
	local playlist = mpd.currentPlaylist()
	for _, album in ipairs(playlist) do
		openboxMenu.beginMenu(string.format("mpd-playlist-%s", album.name:lower()), album.name)
		openboxMenu.title(album.name)
		for _, track in ipairs(album.tracks) do
			openboxMenu.button(track.name, string.format("mpc play %d", track.number))
		end
		openboxMenu.endMenu()
	end
end

local function help()
	io.stderr:write([[mpd_control script usage:
mpd_control [OPTION]

Available options:
	controls		Creates menu with playback controls
	saved-playlists		Shows list of saved playlists, provides playlist switching functionality
	current-playlist	Show songs in current playlist, sorted by albums, provides track switching
	albumart-convert	Lists available images in current song directory, able to convert images into small albumarts
	help			Prints this help
]])
end

local savedPlaylists = decorator(openboxMenu.pipemenu(l10n.savedPlaylists)) ..
function()
	local playlists = mpd.savedPlaylists()
	local empty = true
	for _, playlist in pairs(playlists) do
		savedPlaylistControls(playlist)
		empty = false
	end
	if empty then
		openboxMenu.item(l10n.noPlaylistsFound)
	end
end


-- -- -- -- -- -- -- -- -- -- -- --
-- -- -- -- -- MAIN	-- -- -- -- --
-- -- -- -- -- -- -- -- -- -- -- --

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

