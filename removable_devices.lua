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

package.path = selfDir .. "libs/?.lua;" .. package.path
package.path = selfDir .. "assets/?.lua;" .. package.path
require "common"
local l10n = require "l10n"
local notification = require "notification"
local openboxMenu = require "openboxMenu"
local system = require "system"
local ud2 = require "udisks2"

-- use only removableDevices part of l10n
local lang = systemLanguage()
l10n = l10n[lang].removableDevices

local ejectableDevicesFilter = "[sh]d[[:lower:]]+[[:digit:]]+|mmcblk[[:digit:]]+"
local opticalDevicesFilter = "sr[[:digit:]]+"
local fileManager = "dolphin"

local function showInfo(info, label)
	if  info:len() > 0 then
		openboxMenu.item(string.format("%s: %s", label, info))
	end
end

local function createDevicesMenu(label, devices)
	openboxMenu.title(label)
	if #devices > 0 then
		for _, device in ipairs(devices) do
			local mounted = ud2.deviceMounted(device) and l10n.mounted or ""
			local name = ud2.deviceName(device)
			local label = ud2.deviceLabel(device) or l10n.unlabeled
			openboxMenu.subPipemenu(string.format("udisks2-%s", name), string.format("%s: %s%s", name, label, mounted), system.cmd(selfPath, "device-control", name))
		end
	else
		openboxMenu.item(l10n.noMedium)
	end
end

local function deviceMenu()
	openboxMenu.beginPipemenu()
	if ud2.check() then
		local ejectableDevices = ud2.devices(ejectableDevicesFilter)
		local opticalDevices = ud2.devices(opticalDevicesFilter)
		createDevicesMenu(l10n.removableDevices, ejectableDevices)
		createDevicesMenu(l10n.opticalMedia, opticalDevices)
	else
		openboxMenu.item(l10n.noUdisks2)
	end
	openboxMenu.endPipemenu()
end

local function deviceControl(device)
	openboxMenu.beginPipemenu()
	local mounted = ud2.deviceMounted(device)
	if mounted then
		openboxMenu.button(l10n.open, system.cmd(selfPath, "open", device ))
		openboxMenu.button(l10n.unmount, system.cmd(selfPath, "unmount", device ))
		-- TODO: if ejectable eject button
	else
		openboxMenu.button(l10n.open, system.cmd(selfPath, "mount-open", device ))
		openboxMenu.button(l10n.mount, system.cmd(selfPath, "mount", device ))
	end
	local name = ud2.deviceName(device)
	openboxMenu.subPipemenu("udisks2-info-" .. name, l10n.info, system.cmd(selfPath, "device-info", device))
	openboxMenu.endPipemenu()
end

local function deviceInfo(device)
	openboxMenu.beginPipemenu()
	showInfo(ud2.deviceType(device), l10n.fsType)
	showInfo(ud2.deviceSize(device), l10n.size)
	openboxMenu.endPipemenu()
end

local function mount(device)
	local mountResponse = ud2.mount(device)
	notification.send(l10n.notificationHeader, mountResponse)
end

local function open(device)
	local mountPoint = ud2.deviceMountPoint(device)
	os.execute(system.cmd(fileManager, mountPoint))
end

local function mountOpen(device)
	mount(device)
	if ud2.deviceMounted(device) then
		os.execute(system.cmd(fileManager, ud2.deviceMountPoint(device)))
	end
end

local function unmount(device)
	local unmountResponse = ud2.unmount(device)
	notification.send(l10n.notificationHeader, unmountResponse)
end

local function eject(device)
	unmount(device)
	if not ud2.deviceMounted(device) then
		notification.send(l10n.notificationHeader, ud2.eject(device))
	end
end

local function help()
	io.stderr:write("removable_devices script usage:\n")
	io.stderr:write("\tremovable_devices [OPTION] [ARGUMENT]\n")
	io.stderr:write("\n")
	io.stderr:write("Available options:\n")
	local optionsTable =
	{
		"device-menu\tDefault option, will print Openbox pipe menu containing removable devices",
		"device-control\tCreates menu for specified device",
		"mount\t\tRequires device name as argument, causes udisks2 to mount the device",
		"open\t\tOpens path in specified file manager (defined as variable fileManager, currently: " .. fileManager .. ")",
		"mount-open\tMount the given device and opens it in file manager",
		"unmount\t\tUnmounts the device",
		"eject\t\tIf given optical media device, ejects the device",
		"help\t\tPrints this help"
	}
	for _,option  in ipairs(optionsTable) do
		io.stderr:write(option .. "\n")
	end
end

local function main(option, argument)
	local argActions =
	{
		["device-menu"] = deviceMenu,
		["device-control"] = deviceControl,
		["device-info"] = deviceInfo,
		["mount"] = mount,
		["open"] = open,
		["mount-open"] = mountOpen,
		["unmount"] = unmount,
		["eject"] = eject,
		["help"] = help
	}
	local option = option or "device-menu"
	local action = argActions[option]
	action(argument)
end

main(unpack({ ... }))

