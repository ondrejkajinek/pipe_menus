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
local openboxMenu = require "libs/openboxMenu"
local system = require "libs/system"

-- use only MPD part of l10n
l10n = l10n[systemLanguage()].services
-- use only MPD icons
iconSet = iconSet.services

local optionsTable = {
	"help: Prints this help",
	"menuHelp: Creates pipe menu with help"
}

local cmds = {
	serviceStatus = system.pipe("/etc/init.d/%s status", "grep -oP '\\S+$'"),
	sudoCommand = "kdesu -c '%s'"
}

-- -- -- -- -- -- -- -- -- -- -- --
-- -- -- pipemenu settings	-- -- --
-- -- -- -- -- -- -- -- -- -- -- --

local managedServices = {
	{ "apache2", "mysql" },
	"apache2",
	"benefity",
	{ "cups-browsed", "cupsd" },
	"mysql",
	"net.eth0",
	"net.wlan0",
	"openvpn.ats",
	"redis"
}


-- -- -- -- -- -- -- -- -- -- -- --
-- -- -- helper functions	-- -- --
-- -- -- -- -- -- -- -- -- -- -- --

local function serviceStarted(service)
	local command = string.format(cmds.serviceStatus, service)
	return system.singleResult(command) ~= "stopped"
end

local function servicesStatus(services)
	local numberStarted = 0
	local statuses = {
		[0] = "stopped",
		[#services] = "started"
	}
	for _, service in pairs(services) do
		if serviceStarted(service) then
			numberStarted = numberStarted + 1
		end
	end
	return statuses[numberStarted] or "mixed"
end

local function servicesCmd(services, cmd)
	servicesCmds = {}
	for i,service in ipairs(services) do
		servicesCmds[i] = string.format("/etc/init.d/%s %s", service, cmd)
	end
	return string.format(cmds.sudoCommand, table.concat(servicesCmds, ";"))
end

-- -- -- -- -- -- -- -- -- -- -- --
-- -- -- module functions  -- -- --
-- -- -- -- -- -- -- -- -- -- -- --

local services = decorator(openboxMenu.pipemenu(l10n.servicesTitle)) ..
function()
	for _, services in ipairs(managedServices) do
		services = table.ensure(services)
		local pipemenuId = string.format("services_management_%s", table.concat(services, "_"))
		local pipemenuTitle = table.concat(services, " & ")
		local pipemenuCommand = system.cmd(selfPath, "control", unpack(services))
		openboxMenu.subPipemenu(pipemenuId, pipemenuTitle, pipemenuCommand)
	end
end

local control = decorator(openboxMenu.pipemenu()) ..
function (services)
	services = table.ensure(services)
	local servicesStatus = servicesStatus(services)
	openboxMenu.title(string.format("%s: %s", table.concat(services, " & "), servicesStatus))
	if servicesStatus == "started" then
		openboxMenu.button(l10n.stop, servicesCmd(services, "stop"), iconSet.stop)
		openboxMenu.button(l10n.restart, servicesCmd(services, "restart"), iconSet.restart)
	elseif servicesStatus == "stopped" then
		openboxMenu.button(l10n.start, servicesCmd(services, "start"), iconSet.start)
	else
		openboxMenu.item(l10n.differentStatuses)
	end
end

local function help()
	io.stderr:write("service_management script usage:\n")
	io.stderr:write("mpd_control [OPTION]\n")
	io.stderr:write("\n")
	io.stderr:write("Available options:\n")
	for _,option  in ipairs(optionsTable) do
		io.stderr:write(option .. "\n")
	end
end

local menuHelp = decorator(openboxMenu.pipemenu()) ..
function()
	openboxMenu.item("service_management script usage:\n")
	openboxMenu.item("service_management [OPTION]\n")
	openboxMenu.separator()
	openboxMenu.item("Available options:\n")
	for _,option in ipairs(optionsTable) do
		openboxMenu.item(option .. "\n")
	end
end

local function main(option, ...)
	local actions = {
		control = control,
		help = help,
		menuHelp = menuHelp,
		services = services
	}
	option = option or "services"
	local action = actions[option] or menuHelp
	action({ ... })
end

main(unpack({ ... }))

