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
local l10n = require "assets/l10n"
local system = require "libs/system"
local openboxMenu = require "libs/openboxMenu"

local cmds = {
	processDetail = "ps -o comm,nice,pcpu,%%mem,args --pid %d h",
	topCpuProcesses = "ps -eo pid --sort=-pcpu h | head -%d | tr -d ' '",
	topMemProcesses = "ps -eo pid --sort='-%%mem' h | head -%d | tr -d ' '",
	reniceProcess = "renice -n %d --pid %d"
}

-- use only processManager part of l10n
l10n = l10n[systemLanguage()].processManager

local function processMenu(info)
	openboxMenu.title(info.args)
	openboxMenu.item(string.format("pCPU: %1.2f", info.pcpu))
	openboxMenu.item(string.format("MEM: %1.2f", info.mem))
	openboxMenu.button(l10n.restartProcess, { string.format("kill -9 %d", info.pid), info.args })
	if info.nice < 19 then
		openboxMenu.button(string.format(l10n.lowerPriority, info.nice), string.format(cmds.reniceProcess, info.nice + 5, info.pid))
	else
		openboxMenu.item(string.format(l10n.priority, info.nice))
	end
	openboxMenu.button(l10n.endProcess, string.format("kill %d", info.pid))
	openboxMenu.button(l10n.killProcess, string.format("kill -9 %d", info.pid))
end

local function nonexistingProcess(pid)
	openboxMenu.item(string.format(l10n.nonExistingProcess, pid))
end

local function processManagement(pid)
	local psCmd = system.pipe(string.format(cmds.processDetail, pid), "tr -s ' '")
	local ps = system.singleResult(psCmd) or ""
	local comm, nice, pcpu, mem, args = ps:match("^(%S+)%s+(%d+)%s+(%d+%.%d+)%s+(%d+%.%d+)%s+(.+)$")
	openboxMenu.beginMenu("top_processes_" .. pid, string.format("%s (PID: %d)", comm or "", pid))
	if comm then
		processMenu({
			pid = pid,
			comm = comm,
			nice = tonumber(nice),
			pcpu = pcpu,
			mem = mem,
			args = args })
	else
		nonexistingProcess(pid)
	end
	openboxMenu.endMenu()
end

local topCpuProcesses = decorator(openboxMenu.pipemenu(l10n.topCPU)) ..
function(count)
	for pid in system.resultLines(string.format(cmds.topCpuProcesses, count)) do
		processManagement(pid)
	end
end

local topMemProcesses = decorator(openboxMenu.pipemenu(l10n.topMem)) ..
function(count)
	for pid in system.resultLines(string.format(cmds.topMemProcesses, count)) do
		processManagement(pid)
	end
end

local function help()
	io.stderr:write("process_management script usage:\n")
	io.stderr:write("\process_management [OPTION] [COUNT]\n")
	io.stderr:write("\n")
	io.stderr:write("Available options:\n")
	local optionsTable =
	{
		"top-cpu\t\tPrints <COUNT> top cpu-consuming processes, allows their killing, restarting, renicing",
		"top-mem\t\tPrints <COUNT> top memory-consuming processes, allows their killing, restarting, renicing",
		"help\t\tPrints this help"
	}
	for _,option  in ipairs(optionsTable) do
		io.stderr:write(option .. "\n")
	end
end

local function main(option, count)
	local actions =
	{
		["top-cpu"] = topCpuProcesses,
		["top-mem"] = topMemProcesses,
		["help"] = help
	}
	local option = option or "top-cpu"
	local count = count or 5
	local action = actions[option] or help
	action(count)
end

main(unpack({ ... }))

