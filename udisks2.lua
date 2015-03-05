--[[
--
-- Author: OndraK
--
-- This piece of lua code can be distributed under the terms of GNU GPL v3
--
--]]

local system = require "system"

local udisks2 = {}

local udisks2Cmd = "udisksctl"
local dump = system.cmd(udisks2Cmd, "dump")
local info = system.cmd(udisks2Cmd, "info", "-b")
local mnt = system.cmd(udisks2Cmd, "mount", "-b")
local unmnt = system.cmd(udisks2Cmd, "unmount", "-b")

local mountOptions = "nosuid,noexec,noatime"

-- -- -- -- -- -- -- -- -- -- -- --
-- -- -- private functions -- -- --
-- -- -- -- -- -- -- -- -- -- -- --

local function deviceInfo(device, reqInfo, postprocess)
	local infoCmd = system.cmd(info, device)
	local infoFilter = string.format("grep -E \"\\s+%s:\"", reqInfo)
	local sedCmd = string.format("sed -r 's/^\\s+%s:\\s+//g'", reqInfo)
	local infoCmd = system.pipe(infoCmd, infoFilter, sedCmd, "tail -1")
	local info = system.singleResult(infoCmd)
	postprocess = type(postprocess) == "function" and postprocess or function(c) return c end
	return postprocess(info)
end

local function readableSize(size)
	if not size then
		return nil
	end
	local readableSize = assert(tonumber(size), "Given argument can not be cast to numeric type")
	local preficesTable = { [0] = "", "Ki", "Mi", "Gi", "Ti", "Pi" }
	local multiplicator = 1024
	local prefix = 0
	while readableSize >= multiplicator do
		prefix = prefix + 1
		readableSize = readableSize/multiplicator
	end
	return string.format("%0.2f %sB", readableSize, preficesTable[prefix])
end

local function tobool(text)
	return text == "true" or false
end

-- -- -- -- -- -- -- -- -- -- -- --
-- -- -- public functions  -- -- --
-- -- -- -- -- -- -- -- -- -- -- --
function udisks2.check()
	return system.which(udisks2Cmd)
end

function udisks2.devices(filter)
	local deviceFilter = string.format("grep -E \"%s\"", filter)
	local dumpCmd = system.pipe("ls /dev/", deviceFilter)
	local devices = {}
	for device in system.resultLines(dumpCmd) do
		device = "/dev/" .. device
		local hasFS = udisks2.deviceType(device):len() > 0
		local removable = udisks2.deviceRemovable(device)
		if hasFS and removable then
			devices[#devices + 1] = device
		end
	end
	return devices
end

function udisks2.deviceLabel(device)
	return deviceInfo(device, "IdLabel")
end

function udisks2.deviceMounted(device)
	return deviceInfo(device, "MountPoints"):len() > 0
end

function deviceMountPoint(device)
	return deviceInfo(device, "MountPoints")
end

function udisks2.deviceName(device)
	return deviceInfo(device, "Device")
end

function udisks2.deviceRemovable(device)
	return not deviceInfo(device, "HintSystem", tobool)
end

function udisks2.deviceSize(device)
	return deviceInfo(device, "Size", readableSize)
end

function udisks2.deviceType(device)
	return deviceInfo(device, "IdType")
end

function udisks2.deviceUUID(device)
	return deviceInfo(device, "IdUUID")
end

function udisks2.mount(device)
	local mountCmd = system.cmd(mnt, device, "-o", mountOptions)
	return system.singleResult(mountCmd)
end

function udisks2.unmount(device)
	local unmountCmd = system.cmd(unmnt, device)
	return system.singleResult(unmountCmd)
end

function udisks2.eject(device)
	return "Not implemented"
end

return udisks2

