--[[
--
-- Author: OndraK
--
-- This piece of lua code can be distributed under the terms of GNU GPL v3
--
--]]

local selfDir = debug.getinfo(1).source:gsub("@", ""):gsub("[^/]+$", "")

require "libs/common"

function DirStructure()
	local function newDir(name)
		return {
			name = name,
			content = {}
		}
	end

	local tree = newDir("")
	local cache = {}
	local self = {}

	self.getDir = function(subdir)
		return subdir and cache[subdir].content or tree.content
	end

	self.addFile = function(file, separator)
		separator = separator or "/"
		local dirs = file:split(separator)
		local name = dirs[#dirs]
		dirs[#dirs] = nil
		local path = ""
		local node = tree
		for _, dir in ipairs(dirs) do
			path = path .. separator .. dir
			if not cache[path] then
				cache[path] = newDir(dir)
				node.content[#node.content + 1] = cache[path]
			end
			node = cache[path]
		end
		node.content[#node.content + 1] = name
	end

	return self
end

