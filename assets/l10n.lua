--[[
--
-- Author: OndraK
--
-- This piece of lua code can be distributed under the terms of GNU GPL v3
--
--]]

local fallbackValue = function(tbl, key)
	io.stderr:write("WARNING: undefined l10n entry: " .. key .. "\n")
	return key
end

local function messagePack(entries)
	return setmetatable(entries, {
		__index = fallbackValue
	})
end

l10n = {
	cs = {
		apache = messagePack({
			differentStatuses = "Jedna služba je spuštěna, druhá zastavena",
			restart = "Restartovat",
			start = "Spustit",
			stop = "Zastavit",
		}),
		mpd = messagePack({
			availableAlbumarts = "Dostupné obrázky k albu",
			currentPlaylist = "Aktuální seznam skladeb",
			fromBeginning = "Od začátku",
			nextTrack = "Následující skladba",
			noImagesFound = "Žádné obrázky nenalezeny",
			notPlaying = "Nepřehrávám",
			playPause = "Přehrát/Pozastavit",
			previousTrack = "Předchozí skladba",
			random = "Náhodně",
			repeating = "Opakovat",
			savedPlaylists = "Uložené seznamy skladeb"
		}),
		processManager = messagePack({
			endProcess = "Ukončit proces",
			killProcess = "Zabít proces",
			lowerPriority = "Snížit prioritu (nyní: %d)",
			priority = "Priorita: %d",
			nonExistingProcess = "Proces s PID %d neexistuje",
			restartProcess = "Restartovat program"
		}),
		removableDevices = messagePack({
			fsType = "Typ",
			info = "Info",
			mount = "Připojit",
			mounted = " (připojeno)",
			notificationHeader = "Oznámení o připojení zařízení",
			noMedium = "Žádné médium",
			noUdisks2 = "udisks2 není k dispozici!",
			open = "Otevřít",
			opticalMedia = "Optická média",
			removableDevices = "Odpojitelná zařízení",
			size = "Velikost",
			unlabeled = " (bez popisku)",
			unmount = "Odpojit"
		})
	},
	en = {
		apache = messagePack({
			differentStatuses = "One is stopped, other started",
			restart = "Restart",
			start = "Start",
			stop = "Stop"
		}),
		mpd = messagePack({
			availableAlbumarts = "Available albumarts",
			currentPlaylist = "Current playlist",
			fromBeginning = "Go to beginning",
			nextTrack = "Next track",
			noImagesFound = "No albumarts found",
			notPlaying = "Not playing",
			playPause = "Play/Pause",
			previousTrack = "Previous track",
			random = "Random",
			repeating = "Repeat",
			savedPlaylists = "Saved playlists"
		}),
		processManager = messagePack({
			endProcess = "End process",
			killProcess = "Kill process",
			lowerPriority = "Lower priority (current: %d)",
			priority = "Priority: %d",
			nonExistingProcess = "No process with PID %d",
			restartProcess = "Restart process"
		}),
		removableDevices = messagePack({
			fsType = "Type",
			info = "Info",
			mount = "Mount",
			mounted = " (mounted)",
			notificationHeader = "Notification of device mounting",
			noMedium = "No medium",
			noUdisks2 = "udisks2 is not available!",
			open = "Open with filemanager",
			opticalMedia = "Optical devices",
			removableDevices = "Removable devices",
			size = "Size",
			unlabeled = " (no label)",
			unmount = "Unmount"
		})
	}
}

return l10n

