--[[
--
-- Author: OndraK
--
-- This piece of lua code can be distributed under the terms of GNU GPL v3
--
--]]

local system = {}

local localeCategories = { "collate", "ctype", "monetary", "time" }

for _, category in pairs(localeCategories) do
	os.setlocale("cs_CZ.UTF-8", category)
end

local dirDelimiter = "/"

-- -- -- -- -- -- -- -- -- -- -- --
-- -- -- private functions -- -- --
-- -- -- -- -- -- -- -- -- -- -- --

local function createEscapings(escaped)
	local escapings = {}
	-- omit opening and closing [ ]
	for i = 2, escaped:len() - 1 do
		local char = escaped:sub(i, i)
		escapings[char] = "\\" .. char
	end
	return escapings
end

local function isDir(node)
	return lfs.attributes(node, "mode") == "directory"
end

-- -- -- -- -- -- -- -- -- -- -- --
-- -- -- public functions  -- -- --
-- -- -- -- -- -- -- -- -- -- -- --
function system.escape(str)
	local toEscape = "[ ;&()'\"]"
	local escaped = str:gsub(toEscape, createEscapings(toEscape))
	return escaped
end

function system.cmd(...)
	local parts = { ... }
	return table.concat(parts, " ")
end

function system.singleResult(cmd)
	local resultStream = io.popen(cmd)
	local result = resultStream:read("*line")
	resultStream:close()
	return result
end

function system.resultLines(cmd)
	local resultStream = io.popen(cmd)
	return coroutine.wrap(function()
		for line in resultStream:lines() do
			coroutine.yield(line)
		end
	end)
end

function system.which(cmd)
	local which = string.format("which %s 2> /dev/null 1>&2 && echo true", cmd)
	local grepTrue = "grep -o true"
	local response = system.singleResult(system.pipe(which, grepTrue))
	return system.singleResult(system.pipe(which, "grep -o true")) == "true"
end

function system.pipe(...)
	local cmds = { ... }
	return table.concat(cmds, " | ")
end

function system.path(...)
	local parts = { ... }
	fullPath = table.concat(parts, dirDelimiter):gsub(string.format("%s+", dirDelimiter), dirDelimiter)
	return fullPath
end

function system.parentDir(path)
	directory = path:gsub("[^/]+$", "")
	return directory
end

return system

