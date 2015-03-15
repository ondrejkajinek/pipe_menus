--[[
--
-- Author: OndraK
--
-- This piece of lua code can be distributed under the terms of GNU GPL v3
--
--]]

local home = os.getenv("HOME")

local iconSet = setmetatable({}, {
	__index = function()
		return ""
	end
})

iconSet =
{
	mpd = {
		skipBackward = "/usr/share/icons/oxygen/32x32/actions/media-skip-backward.png",
		skipForward = "/usr/share/icons/oxygen/32x32/actions/media-skip-forward.png",
		playbackPause = "/usr/share/icons/oxygen/32x32/actions/media-playback-pause.png",
		seekBackward = "/usr/share/icons/oxygen/32x32/actions/media-seek-backward.png",
		random = home .. "/.icons/actions/media-random-tracks-amarok.png",
		repeatPlaylist = home .. "/.icons/actions/media-repeat-playlist-amarok.png"
	}
}

return iconSet

