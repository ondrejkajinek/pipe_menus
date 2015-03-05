--[[
--
-- Author: OndraK
--
-- This piece of lua code can be distributed under the terms of GNU GPL v3
--
--]]

local openboxMenu = {}

-- -- -- -- -- -- -- -- -- -- -- --
-- -- -- private functions -- -- --
-- -- -- -- -- -- -- -- -- -- -- --

local function escapeHtmlEntities(text)
	local escaped = '["&<>]'
	local entities = { ["&"] = "&amp;", ['"'] = "&quot;", ["<"] = "&lt;", [">"] = "&gt;" }
	return text:gsub(escaped, entities)
end

-- -- -- -- -- -- -- -- -- -- -- --
-- -- -- public functions  -- -- --
-- -- -- -- -- -- -- -- -- -- -- --

function openboxMenu.button(text, commands, icon)
	assert(text, "Text of button not specified.")
	assert(commands, "Button command not specified.")
	icon = icon or ""
	if type(commands) == "string" then
		commands = { commands }
	end
	print(string.format('<item label="%s" icon="%s">', escapeHtmlEntities(text), icon))
	for _, command in ipairs(commands) do
		print('<action name="execute">')
		print(string.format('<command>%s</command>', command))
		print('</action>')
	end
	print('</item>')
end

function openboxMenu.item(text, icon)
	assert(text, "Text of menu item not specified.")
	icon = icon or ""
	print(string.format('<item label="%s" icon="%s"/>', escapeHtmlEntities(text), escapeHtmlEntities(icon)))
end

function openboxMenu.separator()
	print('<separator/>')
end

function openboxMenu.title(title)
	assert(title, "Separator label not specified")
	print(string.format('<separator label="%s"/>', escapeHtmlEntities(title)))
end

function openboxMenu.beginMenu(id, label)
	assert(id, "Menu id not specified")
	assert(label, "Menu label not specified")
	print(string.format('<menu id="%s" label="%s">', escapeHtmlEntities(id:gsub(" ", "-")), escapeHtmlEntities(label)))
end

function openboxMenu.endMenu()
	print('</menu>')
end

function openboxMenu.subPipemenu(id, label, execute, icon)
	assert(id, "Pipemenu id not specified")
	assert(label, "Pipemenu label not specified")
	assert(execute, "Pipemenu command not specified")
	icon = icon or ""
	print(string.format('<menu id="%s" label="%s" execute="%s" icon="%s"/>', escapeHtmlEntities(id), escapeHtmlEntities(label), execute, icon))
end

function openboxMenu.beginPipemenu()
	print('<?xml version="1.0" encoding="UTF-8"?>\n<openbox_pipe_menu>')
end

function openboxMenu.endPipemenu()
	print('</openbox_pipe_menu>')
end

return openboxMenu

