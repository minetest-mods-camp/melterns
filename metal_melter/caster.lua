-- Casts molten metals into a solid form

local have_ui = minetest.get_modpath("unified_inventory")

metal_caster = {}

metal_caster.max_coolant = 8000
metal_caster.max_metal = 16000

-- Use melter values
metal_caster.spec = metal_melter.spec
metal_caster.spec.cast = 288

metal_caster.casts = {
	ingot_cast = {name = "Ingot Cast", result = "%s:%s_ingot",   cost = metal_caster.spec.ingot,   typenames = {"ingot"}},
	lump_cast  = {name = "Lump Cast",  result = "%s:%s_lump",    cost = metal_caster.spec.lump,    typenames = {"lump"}},
	gem_cast   = {name = "Gem Cast",   result = "%s:%s_crystal", cost = metal_caster.spec.crystal, typenames = {"crystal", "gem"}}
}

local metal_cache = {}

function metal_caster.get_metal_caster_formspec_default()
	return "size[8,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"list[context;cast;2.7,0.2;1,1;]"..
		"image[2.7,1.35;1,1;gui_furnace_arrow_bg.png^[transformFY]"..
		"list[context;output;2.7,2.5;1,1;]"..
		"list[context;coolant;0.25,2.5;1,1;]"..
		"image[0.08,0;1.4,2.8;melter_gui_barbg.png]"..
		"image[0.08,0;1.4,2.8;melter_gui_gauge.png]"..
		"label[0.08,3.4;Water: 0/"..metal_caster.max_coolant.." mB]"..
		"image[6.68,0;1.4,2.8;melter_gui_barbg.png]"..
		"image[6.68,0;1.4,2.8;melter_gui_gauge.png]"..
		"label[0.08,3.75;No Molten Metal]"..
		"list[context;bucket_in;4.75,0.2;2,2;]"..
		"list[context;bucket_out;4.75,1.4;2,2;]"..
		"image[5.75,0.2;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
		"image[5.75,1.4;1,1;gui_furnace_arrow_bg.png^[transformR90]"..
		"list[current_player;main;0,4.25;8,1;]"..
		"list[current_player;main;0,5.5;8,3;8]"..
		"listring[context;coolant]"..
		"listring[current_player;main]"..
		"listring[context;cast]"..
		"listring[current_player;main]"..
		"listring[context;output]"..
		"listring[current_player;main]"..
		"listring[context;bucket_in]"..
		"listring[current_player;main]"..
		"listring[context;bucket_out]"..
		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 4.25)
end

function metal_caster.get_metal_caster_formspec(data)
	local water_percent = data.water_level / metal_caster.max_coolant
	local metal_percent = data.metal_level / metal_caster.max_metal

	local metal_formspec = "label[0.08,3.75;No Molten Metal]"

	if data.metal ~= "" then
		metal_formspec = "label[0.08,3.75;"..data.metal..": "..data.metal_level.."/"..metal_caster.max_metal.." mB]"
	end

	return "size[8,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"list[context;cast;2.7,0.2;1,1;]"..
		"image[2.7,1.35;1,1;gui_furnace_arrow_bg.png^[transformFY]"..
		"list[context;output;2.7,2.5;1,1;]"..
		"list[context;coolant;0.25,2.5;1,1;]"..
		"image[0.08,0;1.4,2.8;melter_gui_barbg.png]"..
		"image[0.08,"..(2.44 - water_percent * 2.44)..";1.4,"..(water_percent * 2.8)..";default_water.png]"..
		"image[0.08,0;1.4,2.8;melter_gui_gauge.png]"..
		"label[0.08,3.4;Water: "..data.water_level.."/"..metal_caster.max_coolant.." mB]"..
		"image[6.68,0;1.4,2.8;melter_gui_barbg.png]"..
		"image[6.68,"..(2.44 - metal_percent * 2.44)..";1.4,"..(metal_percent * 2.8)..";"..data.metal_texture.."]"..
		"image[6.68,0;1.4,2.8;melter_gui_gauge.png]"..
		metal_formspec..
		"list[context;bucket_in;4.75,0.2;2,2;]"..
		"list[context;bucket_out;4.75,1.4;2,2;]"..
		"image[5.75,0.2;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
		"image[5.75,1.4;1,1;gui_furnace_arrow_bg.png^[transformR90]"..
		"list[current_player;main;0,4.25;8,1;]"..
		"list[current_player;main;0,5.5;8,3;8]"..
		"listring[context;coolant]"..
		"listring[current_player;main]"..
		"listring[context;cast]"..
		"listring[current_player;main]"..
		"listring[context;output]"..
		"listring[current_player;main]"..
		"listring[context;bucket_in]"..
		"listring[current_player;main]"..
		"listring[context;bucket_out]"..
		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 4.25)
end

-- Find the name of the mod that adds this particular metal into the game.
function metal_caster.get_modname_for_metal(metal_type)
	if not metal_cache[metal_type] then
		for i, v in pairs(minetest.registered_items) do
			if i:find(metal_type) and (i:find("ingot") or i:find("block") or i:find("crystal")) and not metal_cache[metal_type] then
				local modname, metalname = i:match("(%a+):(%a+)")
				metal_cache[metalname] = modname
			end
		end
	end

	return metal_cache[metal_type]
end

-- Check to see if this cast is able to cast this metal type
local function can_cast(metal_name, cast_name)
	local cast = metal_caster.casts[cast_name]

	if cast.mod then
		return cast.mod
	end

	local mod = metal_caster.get_modname_for_metal(metal_name)
	local item_name = cast.result:format(mod, metal_name)

	if minetest.registered_items[item_name] ~= nil then
		return mod
	else
		return nil
	end
end

local function can_dig(pos, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	return inv:is_empty("cast") and inv:is_empty("coolant") and inv:is_empty("bucket_in") and inv:is_empty("bucket_out") and 
		inv:is_empty("output")
end

local function allow_metadata_inventory_put (pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end

	if listname == "bucket_out" then
		if stack:get_name() ~= "bucket:bucket_empty" then
			return 0
		end

		return 1
	end

	if listname == "coolant" then
		if stack:get_name() ~= "bucket:bucket_water" then
			return 0
		end
	end

	if listname == "output" then
		return 0
	end

	return stack:get_count()
end

local function allow_metadata_inventory_move (pos, from_list, from_index, to_list, to_index, count, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local stack = inv:get_stack(from_list, from_index)
	return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end

local function allow_metadata_inventory_take (pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return stack:get_count()
end

-- Increment a stack by one
local function increment_stack(stack, appendix)
	if stack:is_empty() then
		return appendix
	end

	if stack:get_name() ~= appendix:get_name() then
		return stack
	end

	stack:set_count(stack:get_count() + 1)
	return stack
end

-- Decrement a stack by one
local function decrement_stack(stack)
	if stack:get_count() == 1 then
		return nil
	end

	stack:set_count(stack:get_count() - 1)
	return stack
end

-- Get the corresponding cast for an item
local function get_cast_for(item)
	local typename, castname = item:match(":([%a_]+)_(%a+)$")
	if not typename or not castname then
		return nil
	end

	local cast = nil
	for i, v in pairs(metal_caster.casts) do
		for _,k in pairs(v.typenames) do
			if castname == k then
				cast = i
			end
		end
	end

	if not cast then return nil end
	return typename, cast
end

local function caster_node_timer(pos, elapsed)
	local refresh = false
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()

	-- Current amount of water (coolant) in the block
	local coolant_count = meta:get_int("water_level")

	-- Current amount of metal in the block
	local metal_count = meta:get_int("metal_level")

	-- Current metal used
	local metal = meta:get_string("metal")
	local metal_type = ""

	-- Insert water bucket into tank, return empty bucket
	if inv:get_stack("coolant", 1):get_name() == "bucket:bucket_water" then
		if coolant_count + 1000 <= metal_caster.max_coolant then
			coolant_count = coolant_count + 1000
			inv:set_list("coolant", {"bucket:bucket_empty"})
			refresh = true
		end
	end

	-- Handle input bucket, only allow a molten metal
	local bucket_in = inv:get_stack("bucket_in", 1):get_name()
	if bucket_in:find("bucket") and bucket_in ~= "bucket:bucket_empty" then
		local bucket_fluid = fluidity.get_fluid_for_bucket(bucket_in)
		local fluid_is_metal = fluidity.get_metal_for_fluid(bucket_fluid) ~= nil
		local empty_bucket = false

		if fluid_is_metal then
			if metal ~= "" and metal == bucket_fluid then
				if metal_count + 1000 <= metal_caster.max_metal then
					metal_count = metal_count + 1000
					empty_bucket = true
				end
			elseif metal == "" then
				metal_count = 1000
				metal = bucket_fluid
				empty_bucket = true
			end
		end

		if empty_bucket then
			inv:set_list("bucket_in", {"bucket:bucket_empty"})
			refresh = true
		end
	end

	-- Handle bucket output, only allow empty buckets in this slot
	local bucket_out = inv:get_stack("bucket_out", 1):get_name()
	if bucket_out == "bucket:bucket_empty" and metal ~= "" then
		local bucket = fluidity.get_bucket_for_fluid(metal)
		if metal_count >= 1000 then
			metal_count = metal_count - 1000
			inv:set_list("bucket_out", {bucket})
			refresh = true

			if metal_count == 0 then
				metal = ""
			end
		end
	end

	-- If we have a cast, check if we can cast right now.
	if metal ~= "" then
		metal_type = fluidity.get_metal_for_fluid(metal)

		local castname = inv:get_stack("cast", 1):get_name()
		castname = castname:gsub("[a-zA-Z0-9_]+:", "")
		if metal_caster.casts[castname] then
			-- Cast metal using a cast
			local cast = metal_caster.casts[castname]
			local modname = can_cast(metal_type, castname)
			if modname ~= nil then
				local result_name = cast.result:format(modname, metal_type)
				local result_cost = cast.cost
				local coolant_cost = result_cost / 4

				if metal_count >= result_cost and coolant_count >= coolant_cost then
					local stack = ItemStack(result_name)
					local output_stack = inv:get_stack("output", 1)
					if output_stack:item_fits(stack) then
						inv:set_stack("output", 1, increment_stack(output_stack, stack))
						metal_count = metal_count - result_cost
						coolant_count = coolant_count - coolant_cost
						refresh = true
					end
				end
			end
		elseif castname:find("_ingot") or castname:find("_crystal") or castname:find("_lump") and metal_type == "gold" then
			-- Create a new cast
			local result_cost = metal_caster.spec.cast
			local coolant_cost = result_cost / 4
			if metal_count >= result_cost and coolant_count >= coolant_cost then
				local mtype, ctype = get_cast_for(castname)
				if mtype then
					local stack = ItemStack("metal_melter:"..ctype)
					local output_stack = inv:get_stack("output", 1)
					local cast_stack = inv:get_stack("cast", 1)
					if output_stack:item_fits(stack) then
						inv:set_stack("output", 1, increment_stack(output_stack, stack))
						inv:set_stack("cast", 1, decrement_stack(cast_stack))
						metal_count = metal_count - result_cost
						coolant_count = coolant_count - coolant_cost
						refresh = true
					end
				end
			end
		end
	end

	if refresh then
		meta:set_int("water_level", coolant_count)
		meta:set_int("metal_level", metal_count)
		meta:set_string("metal", metal)

		local metal_texture = "default_lava.png"
		local metal_name = ""

		local infotext = "Metal Caster\n"
		infotext = infotext.."Water: "..coolant_count.."/"..metal_caster.max_coolant.." mB \n"
		
		if metal ~= "" then
			metal_texture = "fluidity_"..fluidity.get_metal_for_fluid(metal)..".png"

			local metal_node = minetest.registered_nodes[metal]
			metal_name = fluidity.fluid_name(metal_node.description)
			infotext = infotext..metal_name..": "..metal_count.."/"..metal_caster.max_metal.." mB"
		else
			infotext = infotext.."No Molten Metal"
		end

		meta:set_string("infotext", infotext)
		meta:set_string("formspec", metal_caster.get_metal_caster_formspec(
			{water_level=coolant_count, metal_level=metal_count, metal_texture=metal_texture, metal=metal_name}))
	end

	return refresh
end

local function on_construct(pos)
	local meta = minetest.get_meta(pos)
	meta:set_string("formspec", metal_caster.get_metal_caster_formspec_default())
	
	-- Create inventory
	local inv = meta:get_inventory()
	inv:set_size('cast', 1)
	inv:set_size('output', 1)
	inv:set_size('coolant', 1)
	inv:set_size('bucket_in', 1)
	inv:set_size('bucket_out', 1)

	-- Fluid buffers
	meta:set_int('water_level', 0)
	meta:set_int('metal_level', 0)

	-- Metal source block
	meta:set_string('metal', '')

	-- Default infotext
	meta:set_string("infotext", "Metal Caster Inactive")
end

-- Register a new cast
function metal_caster.register_cast(name, data)
	local modname = data.mod or "metal_melter"

	minetest.register_craftitem(modname..":"..name, {
		description = data.name,
		inventory_image = "caster_"..name..".png",
		stack_max = 1,
		groups = {cast=1}
	})

	if not metal_caster.casts[name] then
		metal_caster.casts[name] = data
	end
end

-- Register the caster
minetest.register_node("metal_melter:metal_caster", {
	description = "Metal Caster",
	tiles = {
		"melter_side.png", "melter_side.png",
		"melter_side.png", "melter_side.png",
		"melter_side.png", "caster_front.png"
	},
	paramtype2 = "facedir",
	groups = {cracky=2},
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),

	can_dig = can_dig,
	on_timer = caster_node_timer,
	on_construct = on_construct,
	on_metadata_inventory_move = function(pos)
		minetest.get_node_timer(pos):start(1.0)
	end,
	on_metadata_inventory_put = function(pos)
		minetest.get_node_timer(pos):start(1.0)
	end,
	on_metadata_inventory_take = function(pos)
		minetest.get_node_timer(pos):start(1.0)
	end,
	on_blast = function(pos)
		local drops = {}
		default.get_inventory_drops(pos, "cast", drops)
		default.get_inventory_drops(pos, "output", drops)
		default.get_inventory_drops(pos, "coolant", drops)
		default.get_inventory_drops(pos, "bucket_in", drops)
		default.get_inventory_drops(pos, "bucket_out", drops)
		drops[#drops+1] = "metal_melter:metal_caster"
		minetest.remove_node(pos)
		return drops
	end,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
})

for i,v in pairs(metal_caster.casts) do
	metal_caster.register_cast(i, v)
end

-- Support Unified Inventory, partially
if have_ui then
	unified_inventory.register_craft_type("casting", {
		description = "Casting",
		width = 2,
		height = 1,
	})

	unified_inventory.register_craft({
		type = "casting",
		output = "metal_melter:ingot_cast",
		items = {"fluidity:bucket_gold", "default:steel_ingot"},
		width = 0,
	})

	unified_inventory.register_craft({
		type = "casting",
		output = "metal_melter:lump_cast",
		items = {"fluidity:bucket_gold", "default:iron_lump"},
		width = 0,
	})

	unified_inventory.register_craft({
		type = "casting",
		output = "metal_melter:gem_cast",
		items = {"fluidity:bucket_gold", "default:mese_crystal"},
		width = 0,
	})
end
