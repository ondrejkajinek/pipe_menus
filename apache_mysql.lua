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
local lang = "cz"
l10n = l10n[lang].apache
-- use only MPD icons
iconSet = iconSet.apache

local optionsTable = {
	"help: Prints this help",
	"menuHelp: Creates pipe menu with help"
}

local cmds = {
	serviceStartedTemplate = system.pipe("/etc/init.d/%s status", "grep -o started"),
	sudoCommand = "kdesu -c '%s'"
}

-- -- -- -- -- -- -- -- -- -- -- --
-- -- -- helper functions	-- -- --
-- -- -- -- -- -- -- -- -- -- -- --

local function serviceStarted(service)
	local command = string.format(cmds.serviceStartedTemplate, service)
	return system.singleResult(command) == "started"
end

local function servicesCmd(services, cmd)
	services = type(services) == "table" and services or { services }
	for i,service in ipairs(services) do
		services[i] = string.format("/etc/init.d/%s %s", service, cmd)
	end
	return string.format(cmds.sudoCommand, table.concat(services, ";"))
end

local function controlBothServices()
	local apacheStarted = serviceStarted("apache2")
	local mysqlStarted = serviceStarted("mysql")
	openboxMenu.beginMenu("apache_mysql_both", "Apache & Mysql")
	-- both are stopped or started
	if mysqlStarted == apacheStarted then
		local bothServices = {
			"apache2",
			"mysql"
		}
		if apacheStarted then
			openboxMenu.button(l10n.stop, servicesCmd(bothServices, "stop"), iconSet.stop)
		else
			openboxMenu.button(l10n.start, servicesCmd(bothServices, "start"), iconSet.start)
		end
	-- only one is running
	else
		openboxMenu.item(l10n.differentStatuses)
	end
	openboxMenu.endMenu()
end

local function controlService(service)
	local serviceStarted = serviceStarted(service)
	openboxMenu.beginMenu("apache_mysql_single_" .. service, service)
	if serviceStarted then
		openboxMenu.button(l10n.stop, servicesCmd(service, "stop"), iconSet.stop)
	else
		openboxMenu.button(l10n.start, servicesCmd(service, "start"), iconSet.start)
	end
	openboxMenu.endMenu()
end


-- -- -- -- -- -- -- -- -- -- -- --
-- -- -- module functions  -- -- --
-- -- -- -- -- -- -- -- -- -- -- --

local function control()
	openboxMenu.beginPipemenu()
	controlBothServices()
	controlService("apache2")
	controlService("mysql")
	openboxMenu.endPipemenu()
end

local function help()
	io.stderr:write("apache_mysql script usage:\n")
	io.stderr:write("mpd_control [OPTION]\n")
	io.stderr:write("\n")
	io.stderr:write("Available options:\n")
	for _,option  in ipairs(optionsTable) do
		io.stderr:write(option .. "\n")
	end
end

local function menuHelp()
	openboxMenu.beginPipemenu()
	openboxMenu.item("apache_mysql script usage:\n")
	openboxMenu.item("apache_mysql [OPTION]\n")
	openboxMenu.separator()
	openboxMenu.item("Available options:\n")
	for _,option in ipairs(optionsTable) do
		openboxMenu.item(option .. "\n")
	end
	openboxMenu.endPipemenu()
end

local function main(option)
	local actions =
	{
		["control"] = control,
		["help"] = help,
		["menuHelp"] = menuHelp
	}
	-- local option = option or "controls"
	option = option or "control"
	local action = actions[option] or menuHelp
	action()
end

main(unpack({ ... }))

