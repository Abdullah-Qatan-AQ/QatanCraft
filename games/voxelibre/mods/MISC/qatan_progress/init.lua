local modname = minetest.get_current_modname()
local storage = minetest.get_mod_storage()
local MAX_COINS = 1000000
local MAX_XP = 100000000
local MAX_LEVEL = 1000
local sessions = {}

local function esc(value)
	return minetest.formspec_escape(tostring(value))
end

local function default_data()
	return {coins = 0, xp = 0, level = 1, achievements = {}, purchases = {}}
end

local function load_data(name)
	local raw = storage:get_string("player:" .. name)
	local data = raw ~= "" and minetest.deserialize(raw) or nil
	if type(data) ~= "table" then data = default_data() end
	data.coins = math.max(0, math.min(MAX_COINS, math.floor(tonumber(data.coins) or 0)))
	data.xp = math.max(0, math.min(MAX_XP, math.floor(tonumber(data.xp) or 0)))
	data.level = math.max(1, math.min(MAX_LEVEL, math.floor(tonumber(data.level) or 1)))
	data.achievements = type(data.achievements) == "table" and data.achievements or {}
	data.purchases = type(data.purchases) == "table" and data.purchases or {}
	return data
end

local function save_data(name, data)
	data.coins = math.max(0, math.min(MAX_COINS, math.floor(data.coins)))
	data.xp = math.max(0, math.min(MAX_XP, math.floor(data.xp)))
	data.level = math.max(1, math.min(MAX_LEVEL, math.floor(data.level)))
	storage:set_string("player:" .. name, minetest.serialize(data))
end

local function level_for_xp(xp)
	local level = math.floor(math.sqrt(xp / 100)) + 1
	return math.max(1, math.min(MAX_LEVEL, level))
end

local function data_for(player)
	local name = player:get_player_name()
	if not sessions[name] then sessions[name] = load_data(name) end
	return sessions[name], name
end

local function notify(player, text)
	minetest.chat_send_player(player:get_player_name(), minetest.colorize("#F3D29B", "QatanCraft: ") .. text)
end

local function award_progress(player, id, title, coins, xp)
	local data, name = data_for(player)
	if data.achievements[id] then return false end
	data.achievements[id] = {title = title, at = os.time()}
	data.coins = math.min(MAX_COINS, data.coins + coins)
	data.xp = math.min(MAX_XP, data.xp + xp)
	local old_level = data.level
	data.level = level_for_xp(data.xp)
	save_data(name, data)
	notify(player, "إنجاز جديد: " .. title .. "  |  +" .. coins .. " عملة")
	if data.level > old_level then
		notify(player, "ارتقيت إلى المستوى " .. data.level .. "!")
	end
	return true
end

local achievements = {
	{
		id = "qatan:first_steps", title = "الخطوات الأولى", coins = 50, xp = 100,
		trigger = {type = "join", target = 1},
	},
	{
		id = "qatan:builder", title = "البنّاء", coins = 100, xp = 250,
		trigger = {type = "place", node = "qatan_decor:wooden_table", target = 1},
	},
	{
		id = "qatan:stone_age", title = "عصر الحجر", coins = 150, xp = 400,
		trigger = {type = "dig", node = "mcl_core:stone", target = 20},
	},
	{
		id = "qatan:well_fed", title = "الشبع", coins = 100, xp = 250,
		trigger = {type = "eat", item = "mcl_farming:bread", target = 5},
	},
	{
		id = "qatan:craftsman", title = "الحِرَفي", coins = 250, xp = 600,
		trigger = {type = "craft", item = "qatan_decor:wooden_chair", target = 1},
	},
}

for _, def in ipairs(achievements) do
	def.type = "Advancement"
	def.group = "QatanCraft"
	def.description = "أكمل هذا التحدي لتحصل على عملات وخبرة."
	def.qatan_id = def.id
	awards.register_achievement(def.id, def)
end

if awards.register_on_unlock then
	awards.register_on_unlock(function(name, def)
		if not def or not def.qatan_id then return false end
		local player = minetest.get_player_by_name(name)
		if player then award_progress(player, def.qatan_id, def.title, def.coins, def.xp) end
		return false
	end)
end

local shop = {
	{ id = "camp-kit", title = "حزمة المخيم", price = 50, stack = "mcl_torches:torch 8" },
	{ id = "wood-kit", title = "حزمة الخشب", price = 100, stack = "mcl_core:wood 32" },
	{ id = "table", title = "طاولة QatanCraft", price = 250, stack = "qatan_decor:wooden_table 1" },
	{ id = "chair", title = "كرسي QatanCraft", price = 250, stack = "qatan_decor:wooden_chair 1" },
	{ id = "planter", title = "صندوق زراعة", price = 500, stack = "qatan_decor:planter_box 1" },
	{ id = "master-kit", title = "حزمة المستكشف الكبرى", price = 1000, stack = "mcl_torches:torch 32" },
}
local shop_by_id = {}
for _, item in ipairs(shop) do shop_by_id[item.id] = item end

local function shop_formspec(player)
	local data = data_for(player)
	local fs = {
		"formspec_version[6]", "size[12,8]", "no_prepend[]",
		"box[0,0;12,8;#101722]", "box[0.35,0.35;11.3,0.8;#16313B]",
		"label[0.7,0.6;QatanCraft • متجر المكافآت المحلي]",
		"label[9.1,0.6;رصيدك: ", esc(data.coins), " عملة]",
		"label[0.7,1.25;هذه العناصر محلية داخل العالم ولا تتصل بمدفوعات أو خوادم خارجية.]",
	}
	for i, item in ipairs(shop) do
		local col = (i - 1) % 2
		local row = math.floor((i - 1) / 2)
		local x, y = 0.6 + col * 5.7, 1.75 + row * 1.55
		fs[#fs + 1] = ("box[%f,%f;5.2,1.2;#16313B]"):format(x, y)
		fs[#fs + 1] = ("label[%f,%f;%s]"):format(x + 0.25, y + 0.2, esc(item.title))
		fs[#fs + 1] = ("label[%f,%f;%d عملة]"):format(x + 0.25, y + 0.62, item.price)
		fs[#fs + 1] = ("button[%f,%f;2.0,0.65;buy_%s;شراء]"):format(x + 2.9, y + 0.27, item.id)
	end
	fs[#fs + 1] = "button_exit[9.2,7.2;2.1,0.6;close;إغلاق]"
	return table.concat(fs, "")
end

local function show_shop(player)
	minetest.show_formspec(player:get_player_name(), modname .. ":shop", shop_formspec(player))
end

local function show_profile(player)
	local data = data_for(player)
	local fs = {
		"formspec_version[6]", "size[10,7]", "no_prepend[]",
		"box[0,0;10,7;#101722]", "box[0.35,0.35;9.3,0.8;#16313B]",
		"label[0.7,0.6;QatanCraft • التقدم والجوائز]",
		"label[0.8,1.45;المستوى: ", data.level, "]",
		"label[0.8,1.9;الخبرة: ", data.xp, "]",
		"label[0.8,2.35;العملات: ", data.coins, "]",
		"label[0.8,2.9;الإنجازات المكتملة: ", tostring((function() local n=0 for _ in pairs(data.achievements) do n=n+1 end return n end)()), "/", #achievements, "]",
		"label[0.8,3.5;الأوامر: /qatan_shop و /qatan_profile و /qatan_achievements]",
		"button[0.8,5.45;2.8,0.75;qatan_shop;فتح المتجر]",
		"button_exit[6.3,5.45;2.8,0.75;close;إغلاق]",
	}
	minetest.show_formspec(player:get_player_name(), modname .. ":profile", table.concat(fs, ""))
end

local function show_achievements(player)
	local data = data_for(player)
	local fs = {"formspec_version[6]", "size[10,8]", "no_prepend[]", "box[0,0;10,8;#101722]", "label[0.7,0.6;QatanCraft • الإنجازات]"}
	for i, def in ipairs(achievements) do
		local done = data.achievements[def.id] ~= nil
		fs[#fs + 1] = ("label[0.8,%f;%s %s — +%d عملة / %d XP]"):format(0.95 + (i - 1) * 0.8, done and "✓" or "○", esc(def.title), def.coins, def.xp)
	end
	fs[#fs + 1] = "button_exit[6.7,6.9;2.5,0.7;close;إغلاق]"
	minetest.show_formspec(player:get_player_name(), modname .. ":achievements", table.concat(fs, ""))
end

local function buy(player, id)
	local item = shop_by_id[id]
	if not item then return end
	local data, name = data_for(player)
	local stack = ItemStack(item.stack)
	if stack:is_empty() or not minetest.registered_items[stack:get_name()] then
		notify(player, "تعذر تجهيز هذه المكافأة.")
		return
	end
	if data.coins < item.price then
		notify(player, "لا تملك عملات كافية.")
		return
	end
	local inv = player:get_inventory()
	if not inv:room_for_item("main", stack) then
		notify(player, "مساحة الحقيبة غير كافية.")
		return
	end
	-- This handler runs on the authoritative game side. Validate, add, then commit once.
	local leftover = inv:add_item("main", stack)
	if not leftover:is_empty() then
		notify(player, "تعذر تسليم العنصر؛ لم يتم خصم العملات.")
		return
	end
	data.coins = data.coins - item.price
	data.purchases[id] = (tonumber(data.purchases[id]) or 0) + 1
	save_data(name, data)
	notify(player, "تم الشراء: " .. item.title .. " مقابل " .. item.price .. " عملة.")
	minetest.show_formspec(name, modname .. ":shop", shop_formspec(player))
end

minetest.register_chatcommand("qatan_shop", {description = "فتح متجر المكافآت المحلي", func = function(name)
	local player = minetest.get_player_by_name(name)
	if player then show_shop(player) end
	return true
end})
minetest.register_chatcommand("qatan_profile", {description = "عرض تقدم QatanCraft", func = function(name)
	local player = minetest.get_player_by_name(name)
	if player then show_profile(player) end
	return true
end})
minetest.register_chatcommand("qatan_achievements", {description = "عرض إنجازات QatanCraft", func = function(name)
	local player = minetest.get_player_by_name(name)
	if player then show_achievements(player) end
	return true
end})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == modname .. ":shop" then
		for _, item in ipairs(shop) do
			local prefix = "buy_"
			if fields[prefix .. item.id] then buy(player, item.id); return true end
		end
		return true
	elseif formname == modname .. ":profile" then
		if fields.qatan_shop then show_shop(player) end
		return true
	end
	return false
end)

minetest.register_on_joinplayer(function(player)
	local data, name = data_for(player)
	if not data.achievements["qatan:first_steps"] and awards and awards.unlock then
		awards.unlock(name, "qatan:first_steps")
	end
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	if sessions[name] then save_data(name, sessions[name]) end
	sessions[name] = nil
end)

minetest.register_on_shutdown(function()
	for name, data in pairs(sessions) do save_data(name, data) end
end)

_G.qatan_progress = {
	get = function(player) return data_for(player) end,
	grant = function(player, coins, xp)
		local data, name = data_for(player)
		data.coins = math.min(MAX_COINS, data.coins + math.max(0, math.floor(coins or 0)))
		data.xp = math.min(MAX_XP, data.xp + math.max(0, math.floor(xp or 0)))
		data.level = level_for_xp(data.xp)
		save_data(name, data)
	end,
}
