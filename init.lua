--[[

  Copyright (C) 2015 - Auke Kok <sofar@foo-projects.org>

  "frame" is free software; you can redistribute it and/or modify
  it under the terms of the GNU Lesser General Public License as
  published by the Free Software Foundation; either version 2.1 of
  the license, or (at your option) any later version.

--]]

frame = {}

local ALPHA_CLIP = core.features.use_texture_alpha_string_modes and "clip" or true

-- handle node removal from frame
local function frame_on_punch(pos, node, puncher, pointed_thing)
	if puncher and not core.check_player_privs(puncher, "protection_bypass") then
		local name = puncher:get_player_name()
		if core.is_protected(pos, name) then
			core.record_protection_violation(pos, name)
			return false
		end
	end

	local def = core.registered_nodes[node.name]
	local item = ItemStack(def.frame_contents)

	-- preserve itemstack metadata and wear
	local meta = core.get_meta(pos)
	local wear = meta:get_int("wear")
	if wear then
		item:set_wear(wear)
	end
	local metadata = meta:get_string("metadata")
	if metadata ~= "" then
		item:set_metadata(metadata)
	end

	--core.handle_node_drops(pos, {item}, puncher)
	local inv = puncher:get_inventory()
	if inv:room_for_item("main", item) then
		inv:add_item("main", item)
		core.sound_play(def.sounds.dug, { pos = pos })
		core.swap_node(pos, { name = "frame:empty", param2 = node.param2 })
	end
end

-- handle node insertion into frame
local function frame_on_rightclick(pos, node, clicker, itemstack, pointed_thing)
	if clicker and not core.check_player_privs(clicker, "protection_bypass") then
		local name = clicker:get_player_name()
		if core.is_protected(pos, name) then
			core.record_protection_violation(pos, name)
			return itemstack
		end
	end

	local nodename = itemstack:get_name()
	if not nodename then
		return itemstack
	end

	local wear = itemstack:get_wear()
	if wear then
		local meta = core.get_meta(pos)
		meta:set_int("wear", wear)
	end
	local metadata = itemstack:get_metadata()
	if metadata ~= "" then
		local meta = core.get_meta(pos)
		meta:set_string("metadata", metadata)
	end

	local name = "frame:" .. nodename:gsub(":", "_")
	local def = core.registered_nodes[name]
	if not def then
		def = core.registered_items[name]
		if not def then
			return itemstack
		end
	end
	core.sound_play(def.sounds.place, { pos = pos })
	core.swap_node(pos, { name = name, param2 = node.param2 })
	if not core.settings:get_bool("creative_mode") then
		itemstack:take_item()
	end
	return itemstack
end

local function build_inventory_image_tiles(inventory_image)
	local tiles = {
		{ name = "frame_frame.png" },
		{ name = inventory_image },
		{ name = "blank.png" },
		{ name = "blank.png" },
		{ name = "blank.png" },
	}

	return tiles
end

local function build_first_tile_tiles(tiles)
	tiles = {
		{ name = "frame_frame.png" },
		{ name = tiles[1] and tiles[1].name or tiles[1] or "blank.png" },
		{ name = "blank.png" },
		{ name = "blank.png" },
		{ name = "blank.png" },
	}

	return tiles
end

local function build_six_tiles_tiles(tiles)
	tiles = {
		{ name = "frame_frame.png" },
		{ name = "blank.png" },
		{
			name = tiles[1] and tiles[1].name or tiles[1]
				or "blank.png"
		},
		{
			name = tiles[2] and tiles[2].name or tiles[2]
				or tiles[1] and tiles[1].name or tiles[1]
				or "blank.png"
		},
		{
			name = tiles[6] and tiles[6].name or tiles[6]
				or tiles[3] and tiles[3].name or tiles[3]
				or tiles[2] and tiles[2].name or tiles[2]
				or tiles[1] and tiles[1].name or tiles[1]
				or "blank.png"
		},
	}

	return tiles
end

local function build_inventory_cube_tiles(tiles)
	tiles = {
		{ name = "frame_frame.png" },
		{ name = "[inventorycube{" .. tiles[1] .. "{" .. tiles[2] .. "{" .. tiles[3] },
		{ name = "blank.png" },
		{ name = "blank.png" },
		{ name = "blank.png" },
	}

	return tiles
end

function frame.register(name)
	local tiles
	local def = core.registered_nodes[name] or core.registered_craftitems[name] or core.registered_tools[name]

	if def.inventory_image and def.inventory_image ~= "" then
		tiles = build_inventory_image_tiles(def.inventory_image)
	elseif def.tiles then
		if def.drawtype ~= "normal" then
			tiles = build_first_tile_tiles(def.tiles)
		else
			tiles = build_six_tiles_tiles(def.tiles)
		end
	else
		tiles = build_inventory_image_tiles("unknown_tile.png")
	end

	assert(def, name .. " is not a known node or item")

	core.register_node(":frame:" .. name:gsub(":", "_"), {
		description = "Item Frame with " .. def.description,
		drawtype = "mesh",
		mesh = "frame.obj",
		tiles = tiles,
		paramtype = "light",
		paramtype2 = "wallmounted",
		sunlight_propagates = true,
		walkable = false,
		use_texture_alpha = ALPHA_CLIP,
		selection_box = {
			type = "wallmounted",
			wall_side = { -1 / 2, -1 / 2, -1 / 2, -3 / 8, 1 / 2, 1 / 2 },
		},
		sounds = default.node_sound_defaults(),
		groups = { attached_node = 1, oddly_breakable_by_hand = 1, snappy = 3, not_in_creative_inventory = 1 },
		frame_contents = name,
		drop = "frame:empty", -- FIXME item should be in there but this would allow free repair
		on_punch = frame_on_punch,
	})
end

-- empty frame
core.register_node("frame:empty", {
	description = "Item Frame",
	drawtype = "mesh",
	mesh = "frame.obj",
	inventory_image = "frame_frame.png",
	wield_image = "frame_frame.png",
	tiles = {
		{ name = "frame_frame.png" },
		{ name = "blank.png" },
		{ name = "blank.png" },
		{ name = "blank.png" },
		{ name = "blank.png" },
	},
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	walkable = false,
	use_texture_alpha = ALPHA_CLIP,
	selection_box = {
		type = "wallmounted",
		wall_side = { -1 / 2, -1 / 2, -1 / 2, -3 / 8, 1 / 2, 1 / 2 },
	},
	sounds = default.node_sound_defaults(),
	groups = { attached_node = 1, oddly_breakable_by_hand = 3, cracky = 1 },
	on_rightclick = frame_on_rightclick,
})

-- craft
core.register_craft({
	output = "frame:empty",
	recipe = {
		{ "default:stick", "default:stick", "default:stick" },
		{ "default:stick", "default:paper", "default:stick" },
		{ "default:stick", "default:stick", "default:stick" },
	}
})

for key, node in pairs(core.registered_nodes) do
	frame.register(key)
end

for key, craftitem in pairs(core.registered_craftitems) do
	frame.register(key)
end

for key, tool in pairs(core.registered_tools) do
	frame.register(key)
end

-- inception!
frame.register("frame:empty")
