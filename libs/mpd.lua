--[[
--
-- Author: OndraK
--
-- This piece of lua code can be distributed under the terms of GNU GPL v3
--
--]]

local mpd = {}

local selfDir = debug.getinfo(1).source:gsub("@", ""):gsub("[^/]+$", "")

package.path = selfDir .. "libs/?.lua;" .. package.path
local system = require "system"

-- -- -- -- -- -- -- -- -- -- -- --
-- -- -- private functions -- -- --
-- -- -- -- -- -- -- -- -- -- -- --

local cmds = {
	currentSong = "mpc -f '%album% - %title%' current",
	optionTemplate = system.pipe("mpc status", "grep -o '%s: on'"),
	pathTemplate = system.pipe("grep '^%s' /etc/mpd.conf", "grep -oP '/[/\\w]+'"),
	playlistTemplate = "mpc -f '%s' playlist"
}

local discographyNames = {
	["diskografie"] = true
}

local filters = {
	playlist = "grep '\\.m3u$'"
}

local separators = {
	playlist = "::",
	tag = "::C++::"
}

local tags = {
	"%album%", "%track%", "%title%"
}

local function newAlbumNode(name)
	return {
		name = name,
		tracks = {}
	}
end

local function newPlaylistNode(name)
	return {
		name = name,
		playlists = {}
	}
end

local function newTrackNode(trackNumber, trackName, playlistNumber)
	return {
		name = string.format("%02d - %s", trackNumber or 0, trackName),
		number = playlistNumber
	}
end

-- -- -- -- -- -- -- -- -- -- -- --
-- -- -- public functions  -- -- --
-- -- -- -- -- -- -- -- -- -- -- --

function mpd.currentPlaylist()
	local albums = {}
	local albumIndices = {}
	local trackNo = 1
	for track in mpd.playlist(tags) do
		local albumName, trackNumber, trackName = unpack(track:split(separators.tag, 2))
		local trackNumber = trackNumber:match("%d+")
		if not albumIndices[albumName] then
			albumIndices[albumName] = #albums + 1
			albums[#albums + 1] = newAlbumNode(albumName)
		end
		local albumIndex = albumIndices[albumName]
		table.insert(albums[albumIndex].tracks, newTrackNode(trackNumber, trackName, trackNo))
		trackNo = trackNo + 1
	end
	return albums
end

function mpd.currentSong()
	return system.singleResult(cmds.currentSong)
end

function mpd.currentSongDir()
	return system.parentDir(system.path(mpd.path("music_directory"), mpd.currentSongPath()))
end

function mpd.currentSongPath()
	return system.singleResult("mpc -f %file% current")
end

function mpd.fullPlaylistName(parent, playlist)
	local fullName
	if parent:len() > 0 then
		fullName = string.format("%s%s%s", parent, separators.playlist, playlist)
	else
		fullName = playlist
	end
	return fullName
end

function mpd.option(option)
	return system.singleResult(string.format(cmds.optionTemplate, option)) and "on" or "off"
end

function mpd.path(path)
	return system.singleResult(string.format(cmds.pathTemplate, path))
end

function mpd.playlist(tags)
	local playlistCmd = string.format(cmds.playlistTemplate, table.concat(tags, separators.tag))
	return system.resultLines(playlistCmd)
end

function mpd.playlists()
	local playlistDir = mpd.path("playlist_directory")
	local lsCmd = system.pipe(string.format("ls %s", playlistDir), filters.playlist)
	return system.resultLines(lsCmd)
end

-- TODO: enable multiple separators in playlist file name => multiple levels of playlists...
function mpd.savedPlaylists()
	local playlists = {}
	local playlistsNameIndex = {}
	for playlist in mpd.playlists() do
		local playlistName = system.stripSuffix(playlist)
		if playlistName:find(separators.playlist) then
			local directory, playlistName = unpack(playlistName:split(separators.playlist, 1))
			if not playlistsNameIndex[directory] then
				playlistsNameIndex[directory] = #playlists + 1
				table.insert(playlists, newPlaylistNode(directory))
			end
			local dirIndex = playlistsNameIndex[directory]
			local position = discographyNames[playlistName] and 1 or #playlists[dirIndex].playlists + 1
			table.insert(playlists[dirIndex].playlists, position, playlistName)
		else
			table.insert(playlists, playlistName)
		end
	end
	return playlists
end

return mpd

