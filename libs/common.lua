--[[
--
-- Author: OndraK
--
-- This piece of lua code can be distributed under the terms of GNU GPL v3
--
--]]

local function escapeLuaMagic(str)
	local escaped = str:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
	return escaped
end

function string.split(str, separator, maxSplits)
	assert(str and separator, "Not enough arguments for string.split")
	assert(separator:len() > 0, "No separator given for string.split")
	maxSplits = maxSplits or math.huge

	str = str .. separator
	local partIterator = str:gmatch("(.-)" .. escapeLuaMagic(separator))
	local part = partIterator()
	local parts = {}
	while maxSplits > 0 and part do
		parts[#parts + 1] = part
		maxSplits = maxSplits - 1
		part = partIterator()
	end
	local tail = part
	for tailPart in partIterator do
		tail = tail .. separator .. tailPart
	end
	parts[#parts + 1] = tail
	return parts
end

