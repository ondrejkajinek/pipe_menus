--[[
--
-- Author: OndraK
--
-- This piece of lua code can be distributed under the terms of GNU GPL v3
--
--]]

local mpd = {}

local selfPath = debug.getinfo(1).source:gsub("@", "")
local selfDir = selfPath:gsub("[^/]+$", "")

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
			albums[#albums + 1] = {
				name = albumName,
				tracks = {}
			}
		end
		local albumIndex = albumIndices[albumName]
		table.insert(albums[albumIndex].tracks, {
			name = string.format("%02d - %s", trackNumber or 0, trackName),
			number = trackNo
		})
		trackNo = trackNo + 1
	end
	return albums
end
	
function mpd.currentSong()
	return system.singleResult(cmds.currentSong)
end

function mpd.currentSongPath()
	return system.singleResult("mpc -f %file% current")
end

function mpd.currentSongDir()
	return system.parentDir(system.path(mpd.path("music_directory"), mpd.currentSongPath()))
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

function mpd.playlistSeparator()
	return separators.playlist
end

function mpd.savedPlaylists()
	local playlistDir = mpd.path("playlist_directory")
	local lsPlaylistsCmd = system.pipe(string.format("ls %s", playlistDir), filters.playlist)
	local playlists = {}
	local playlistsNameIndex = {}
	for playlist in system.resultLines(lsPlaylistsCmd) do
		local playlistName = system.stripSuffix(playlist)
		if playlistName:find(separators.playlist) then
			local directory, playlistName = unpack(playlistName:split(separators.playlist, 1))
			if not playlistsNameIndex[directory] then
				playlistsNameIndex[directory] = #playlists + 1
				playlists[#playlists + 1] = {
					name = directory,
					playlists = {}
				}
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

function mpd.tagSeparator()
	return separators.tag
end

return mpd

