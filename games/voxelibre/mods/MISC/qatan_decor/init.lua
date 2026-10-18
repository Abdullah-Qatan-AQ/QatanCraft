local S = minetest.get_translator("qatan_decor")
local wood = "mcl_core:wood"
local stone = "mcl_core:cobble"
local empty = "air"
local wood_sounds = mcl_sounds.node_sound_wood_defaults()

local function furniture_node(name, description, box, tiles)
	minetest.register_node("qatan_decor:" .. name, {
		description = S(description),
		tiles = tiles or {"default_wood.png"},
		inventory_image = "default_wood.png",
		wield_image = "default_wood.png",
		drawtype = "nodebox",
		paramtype = "light",
		paramtype2 = "facedir",
		groups = {handy = 1, axey = 1, deco_block = 1},
		sounds = wood_sounds,
		node_box = {type = "fixed", fixed = box},
	})
end

furniture_node("wooden_table", "Wooden Table", {
	{-0.42, -0.5, -0.42, 0.42, -0.34, 0.42},
	{-0.34, -0.34, -0.34, -0.20, 0.5, -0.20},
	{0.20, -0.34, -0.34, 0.34, 0.5, -0.20},
	{-0.34, -0.34, 0.20, -0.20, 0.5, 0.34},
	{0.20, -0.34, 0.20, 0.34, 0.5, 0.34},
})

furniture_node("wooden_chair", "Wooden Chair", {
	{-0.42, -0.5, -0.42, 0.42, -0.34, 0.42},
	{-0.34, -0.34, -0.34, -0.20, 0.5, -0.20},
	{0.20, -0.34, -0.34, 0.34, 0.5, -0.20},
	{-0.34, -0.34, 0.20, -0.20, 0.5, 0.34},
	{0.20, -0.34, 0.20, 0.34, 0.5, 0.34},
	{-0.45, 0.15, 0.28, 0.45, 0.5, 0.42},
})

furniture_node("wall_shelf", "Wall Shelf", {
	{-0.46, -0.46, -0.5, 0.46, -0.32, -0.24},
	{-0.46, 0.1, -0.5, 0.46, 0.24, -0.24},
	{-0.46, -0.46, -0.35, -0.32, 0.24, -0.24},
	{0.32, -0.46, -0.35, 0.46, 0.24, -0.24},
})

furniture_node("planter_box", "Planter Box", {
	{-0.46, -0.5, -0.42, 0.46, -0.28, 0.42},
	{-0.46, -0.28, -0.42, -0.32, 0.22, 0.42},
	{0.32, -0.28, -0.42, 0.46, 0.22, 0.42},
	{-0.46, -0.28, -0.42, 0.46, 0.22, -0.28},
	{-0.46, -0.28, 0.28, 0.46, 0.22, 0.42},
	{-0.32, -0.28, -0.28, 0.32, -0.08, 0.28},
})

minetest.register_craft({
	output = "qatan_decor:wooden_table",
	recipe = {{wood, wood, wood}, {empty, "mcl_core:stick", empty}, {empty, "mcl_core:stick", empty}},
})
minetest.register_craft({
	output = "qatan_decor:wooden_chair",
	recipe = {{wood, empty}, {wood, wood}, {"mcl_core:stick", empty}},
})
minetest.register_craft({
	output = "qatan_decor:wall_shelf",
	recipe = {{wood, wood, wood}, {"mcl_core:stick", "mcl_core:stick", "mcl_core:stick"}},
})
minetest.register_craft({
	output = "qatan_decor:planter_box",
	recipe = {{wood, wood, wood}, {wood, "mcl_core:dirt", wood}},
})

local function set_node(pos, name)
	local old = minetest.get_node_or_nil(pos)
	if old and (old.name == "air" or old.name == "ignore" or minetest.get_item_group(old.name, "plant") > 0) then
		minetest.set_node(pos, {name = name})
	end
end

local function build_camp(origin, variant)
	local x, y, z = origin.x, origin.y, origin.z
	for dx = -3, 3 do
		for dz = -3, 3 do
			if math.abs(dx) == 3 or math.abs(dz) == 3 or (dx + dz) % 2 == 0 then
				minetest.set_node({x = x + dx, y = y, z = z + dz}, {name = stone})
			end
		end
	end
	for _, p in ipairs({{-2, -2}, {2, -2}, {-2, 2}, {2, 2}}) do
		for h = 1, 3 do
			minetest.set_node({x = x + p[1], y = y + h, z = z + p[2]}, {name = wood})
		end
	end
	for dx = -2, 2 do
		for dz = -2, 2 do
			if math.abs(dx) == 2 or math.abs(dz) == 2 then
				minetest.set_node({x = x + dx, y = y + 4, z = z + dz}, {name = wood})
			end
		end
	end
	set_node({x = x, y = y + 1, z = z}, "mcl_campfires:campfire")
	set_node({x = x - 1, y = y + 1, z = z + 1}, "qatan_decor:wooden_table")
	set_node({x = x + 1, y = y + 1, z = z + 1}, "qatan_decor:wooden_chair")
	set_node({x = x, y = y + 1, z = z - 2}, "mcl_torches:torch")
	if variant then
		set_node({x = x + 2, y = y + 1, z = z}, "qatan_decor:planter_box")
	end
end

local function build_shrine(origin)
	local x, y, z = origin.x, origin.y, origin.z
	for dx = -2, 2 do
		for dz = -2, 2 do
			minetest.set_node({x = x + dx, y = y, z = z + dz}, {name = stone})
		end
	end
	for _, p in ipairs({{-2, -2}, {2, -2}, {-2, 2}, {2, 2}}) do
		for h = 1, 4 do
			minetest.set_node({x = x + p[1], y = y + h, z = z + p[2]}, {name = stone})
		end
	end
	for dx = -2, 2 do
		for dz = -2, 2 do
			if math.abs(dx) == 2 or math.abs(dz) == 2 then
				minetest.set_node({x = x + dx, y = y + 5, z = z + dz}, {name = stone})
			end
		end
	end
	set_node({x = x, y = y + 1, z = z}, "mcl_torches:torch")
	set_node({x = x, y = y + 1, z = z + 1}, "qatan_decor:wall_shelf")
end

minetest.register_on_generated(function(minp, maxp, blockseed)
	if minp.y > 120 or maxp.y < 1 or blockseed % 37 ~= 0 then return end
	local heightmap = minetest.get_mapgen_object("heightmap")
	if not heightmap then return end
	local width = maxp.x - minp.x + 1
	local cx, cz = minp.x + 8, minp.z + 8
	local index = (cz - minp.z) * width + (cx - minp.x) + 1
	local surface = heightmap[index]
	if not surface or surface < 2 or surface > 110 then return end
	local ground = minetest.get_node_or_nil({x = cx, y = surface, z = cz})
	if not ground or minetest.get_item_group(ground.name, "soil") == 0 then return end
	if blockseed % 3 == 0 then build_shrine({x = cx, y = surface + 1, z = cz})
	else build_camp({x = cx, y = surface + 1, z = cz}, blockseed % 2 == 0) end
end)
