--[[
--
-- Author: OndraK
--
-- This piece of lua code can be distributed under the terms of GNU GPL v3
--
--]]

l10n = setmetatable({}, {
	__index = function(tbl, key)
		return key
	end
})

l10n = {
	cz = {
		mpd = {
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
		},
		processManager = {
			endProcess = "Ukončit proces",
			killProcess = "Zabít proces",
			lowerPriority = "Snížit prioritu (nyní: %d)",
			priority = "Priorita: %d",
			nonExistingProcess = "Proces s PID %d neexistuje",
			restartProcess = "Restartovat program"
		},
		removableDevices = {
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
		}
	},
	en = {
		mpd = {
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
		},
		processManager = {
			endProcess = "End process",
			killProcess = "Kill process",
			lowerPriority = "Lower priority (current: %d)",
			priority = "Priority: %d",
			nonExistingProcess = "No process with PID %d",
			restartProcess = "Restart process"
		},
		removableDevices = {
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
		}
	}
}

return l10n

