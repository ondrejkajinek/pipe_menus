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
package.cpath = "/usr/lib/lua/luarocks/lib/lua/5.1/?.so;" .. package.cpath
require "common"
local iconSet = require "iconSet"
local l10n = require "l10n"
local openboxMenu = require "openboxMenu"
local system = require "system"
local lfs = require "lfs"

-- use only MPD part of l10n
local lang = systemLanguage()
l10n = l10n[lang].services
-- use only MPD icons
iconSet = iconSet.services

local optionsTable = {
	"help: Prints this help",
	"menuHelp: Creates pipe menu with help"
}

local cmds = {
	serviceStarted = system.pipe("/etc/init.d/%s status", "grep -o started"),
	sudoCommand = "kdesu -c '%s'"
}

-- -- -- -- -- -- -- -- -- -- -- --
-- -- -- pipemenu settings	-- -- --
-- -- -- -- -- -- -- -- -- -- -- --

local managedServices = {
	{ "apache2", "mysql" },
	"apache2",
	{ "cups-browsed", "cupsd" },
	"mysql",
	"net.eth0",
	"net.ppp0"
}


-- -- -- -- -- -- -- -- -- -- -- --
-- -- -- helper functions	-- -- --
-- -- -- -- -- -- -- -- -- -- -- --

local function serviceStarted(service)
	local command = string.format(cmds.serviceStarted, service)
	return system.singleResult(command) == "started"
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

local function services()
	openboxMenu.beginPipemenu()
	for _, services in ipairs(managedServices) do
		services = table.ensure(services)
		local pipemenuId = string.format("services_management_%s", table.concat(services, "_"))
		local pipemenuTitle = table.concat(services, " & ")
		local pipemenuCommand = system.cmd(selfPath, "control", unpack(services))
		openboxMenu.subPipemenu(pipemenuId, pipemenuTitle, pipemenuCommand)
	end
	openboxMenu.endPipemenu()
end

local function control(services)
	openboxMenu.beginPipemenu()
	services = table.ensure(services)
	local servicesStatus = servicesStatus(services)
	if servicesStatus == "started" then
		openboxMenu.button(l10n.stop, servicesCmd(services, "stop"), iconSet.stop)
		openboxMenu.button(l10n.restart, servicesCmd(services, "restart"), iconSet.restart)
	elseif servicesStatus == "stopped" then
		openboxMenu.button(l10n.start, servicesCmd(services, "start"), iconSet.start)
	else
		openboxMenu.item(l10n.differentStatuses)
	end
	openboxMenu.endPipemenu()
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

local function menuHelp()
	openboxMenu.beginPipemenu()
	openboxMenu.item("service_management script usage:\n")
	openboxMenu.item("service_management [OPTION]\n")
	openboxMenu.separator()
	openboxMenu.item("Available options:\n")
	for _,option in ipairs(optionsTable) do
		openboxMenu.item(option .. "\n")
	end
	openboxMenu.endPipemenu()
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

