--[[
--
-- Author: OndraK
--
-- This piece of lua code can be distributed under the terms of GNU GPL v3
--
--]]

local mpd = {}

package.path = os.getenv("HOME") .. "/.config/openbox/pipe_menus/libs/?.lua;" .. package.path
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

-- -- -- -- -- -- -- -- -- -- -- --
-- -- -- public functions  -- -- --
-- -- -- -- -- -- -- -- -- -- -- --

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

function mpd.playlist(tags, separator)
	local playlistCmd = string.format(cmds.playlistTemplate, table.concat(tags, separator))
	return system.resultLines(playlistCmd)
end

return mpd

