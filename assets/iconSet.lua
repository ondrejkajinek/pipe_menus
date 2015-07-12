--[[
--
-- Author: OndraK
--
-- This piece of lua code can be distributed under the terms of GNU GPL v3
--
--]]

local home = os.getenv("HOME")

local fallbackValue = function(tbl, key)
	io.stderr:write("WARNING: undefined icon entry: " .. key .. "\n")
	return ""
end

local function iconPack(entries)
	return setmetatable(entries, {
		__index = fallbackValue
	})
end

iconSet =
{
	services = iconPack({
		start = "/usr/share/icons/oxygen/32x32/actions/media-playback-start.png",
		stop = "/usr/share/icons/oxygen/32x32/actions/media-playback-stop.png"
	}),
	mpd = iconPack({
		skipBackward = "/usr/share/icons/oxygen/32x32/actions/media-skip-backward.png",
		skipForward = "/usr/share/icons/oxygen/32x32/actions/media-skip-forward.png",
		playbackPause = "/usr/share/icons/oxygen/32x32/actions/media-playback-pause.png",
		seekBackward = "/usr/share/icons/oxygen/32x32/actions/media-seek-backward.png",
		random = home .. "/.icons/actions/media-random-tracks-amarok.png",
		repeatPlaylist = home .. "/.icons/actions/media-repeat-playlist-amarok.png"
	})
}

return iconSet

