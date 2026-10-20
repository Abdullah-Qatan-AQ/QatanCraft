local modname = minetest.get_current_modname()
local storage = minetest.get_mod_storage()
local sessions = {}
local MAX_COINS = 1000000
local MAX_XP = 100000000
local MAX_LEVEL = 1000
local WALLET_SALT = 17382941

local function wallet_mac(balance, nonce)
	return tostring((balance * 1103515245 + nonce * 12345 + WALLET_SALT) % 2147483647)
end

local function wallet_read()
	local balance = tonumber(minetest.settings:get("qatan_wallet_balance")) or 0
	local nonce = tonumber(minetest.settings:get("qatan_wallet_nonce")) or 0
	local mac = minetest.settings:get("qatan_wallet_mac") or ""
	if balance < 0 or balance > MAX_COINS or nonce < 0 or mac ~= wallet_mac(balance, nonce) then
		return 0, math.max(0, math.floor(nonce))
	end
	return math.floor(balance), math.floor(nonce)
end

local function wallet_write(balance, nonce)
	balance = math.max(0, math.min(MAX_COINS, math.floor(balance)))
	nonce = math.max(0, math.floor(nonce))
	minetest.settings:set("qatan_wallet_balance", tostring(balance))
	minetest.settings:set("qatan_wallet_nonce", tostring(nonce))
	minetest.settings:set("qatan_wallet_mac", wallet_mac(balance, nonce))
	if minetest.settings.write then minetest.settings:write() end
	return balance
end

local function default_data()
	return {coins = 0, xp = 0, level = 1, achievements = {}}
end

local function load_data(name)
	local raw = storage:get_string("player:" .. name)
	local data = raw ~= "" and minetest.deserialize(raw) or nil
	if type(data) ~= "table" then data = default_data() end
	data.coins = math.max(0, math.min(MAX_COINS, math.floor(tonumber(data.coins) or 0)))
	data.xp = math.max(0, math.min(MAX_XP, math.floor(tonumber(data.xp) or 0)))
	data.level = math.max(1, math.min(MAX_LEVEL, math.floor(tonumber(data.level) or 1)))
	data.achievements = type(data.achievements) == "table" and data.achievements or {}
	data.coins = wallet_read()
	return data
end

local function save_data(name, data)
	data.coins = math.max(0, math.min(MAX_COINS, math.floor(data.coins)))
	data.xp = math.max(0, math.min(MAX_XP, math.floor(data.xp)))
	data.level = math.max(1, math.min(MAX_LEVEL, math.floor(data.level)))
	storage:set_string("player:" .. name, minetest.serialize(data))
end

local function level_for_xp(xp)
	return math.max(1, math.min(MAX_LEVEL, math.floor(math.sqrt(xp / 100)) + 1))
end

local function data_for(player)
	local name = player:get_player_name()
	if not sessions[name] then sessions[name] = load_data(name) end
	return sessions[name], name
end

local function notify(player, text)
	minetest.chat_send_player(player:get_player_name(), minetest.colorize("#F3D29B", "QatanCraft: ") .. text)
end

local achievements = {
	{ id = "qatan:first_steps", title = "الخطوات الأولى", coins = 50, xp = 100, trigger = {type = "join", target = 1} },
	{ id = "qatan:builder", title = "البنّاء", coins = 100, xp = 250, trigger = {type = "place", node = "qatan_decor:wooden_table", target = 1} },
	{ id = "qatan:stone_age", title = "عصر الحجر", coins = 150, xp = 400, trigger = {type = "dig", node = "mcl_core:stone", target = 20} },
	{ id = "qatan:well_fed", title = "الشبع", coins = 100, xp = 250, trigger = {type = "eat", item = "mcl_farming:bread", target = 5} },
	{ id = "qatan:craftsman", title = "الحِرَفي", coins = 250, xp = 600, trigger = {type = "craft", item = "qatan_decor:wooden_chair", target = 1} },
}

for _, def in ipairs(achievements) do
	def.type = "Advancement"
	def.group = "QatanCraft"
	def.description = "أكمل هذا التحدي لتحصل على عملات وخبرة."
	def.qatan_id = def.id
	awards.register_achievement(def.id, def)
end

local function award_progress(player, def)
	local data, name = data_for(player)
	if not def or not def.qatan_id or data.achievements[def.qatan_id] then return false end
	data.achievements[def.qatan_id] = {title = def.title, at = os.time()}
	local balance, nonce = wallet_read()
	data.coins = wallet_write(balance + math.max(0, math.floor(def.coins or 0)), nonce + 1)
	data.xp = math.min(MAX_XP, data.xp + math.max(0, math.floor(def.xp or 0)))
	local old_level = data.level
	data.level = level_for_xp(data.xp)
	save_data(name, data)
	notify(player, "إنجاز جديد: " .. def.title .. " | +" .. def.coins .. " عملة")
	if data.level > old_level then notify(player, "ارتقيت إلى المستوى " .. data.level .. "!") end
	return true
end

if awards.register_on_unlock then
	awards.register_on_unlock(function(name, def)
		local player = minetest.get_player_by_name(name)
		if player and def and def.qatan_id then award_progress(player, def) end
		return false
	end)
end

local function count_achievements(data)
	local count = 0
	for _ in pairs(data.achievements) do count = count + 1 end
	return count
end

local function show_profile(player)
	local data = data_for(player)
	local fs = {
		"formspec_version[6]", "size[10,7]", "no_prepend[]",
		"box[0,0;10,7;#101722]", "box[0.35,0.35;9.3,0.8;#16313B]",
		"label[0.7,0.6;QatanCraft • التقدم والجوائز]",
		"label[0.8,1.45;المستوى: ", data.level, "]",
		"label[0.8,1.9;الخبرة: ", data.xp, "]",
		"label[0.8,2.35;العملات المكتسبة: ", data.coins, "]",
		"label[0.8,2.9;الإنجازات المكتملة: ", count_achievements(data), "/", #achievements, "]",
		"label[0.8,3.5;العملات محلية لهذا العالم ولا تمثل أموالًا حقيقية.]",
		"button[0.8,5.45;3.0,0.75;qatan_achievements;الإنجازات]",
		"button_exit[6.3,5.45;2.8,0.75;close;إغلاق]",
	}
	minetest.show_formspec(player:get_player_name(), modname .. ":profile", table.concat(fs, ""))
end

local function show_achievements(player)
	local data = data_for(player)
	local fs = {"formspec_version[6]", "size[10,8]", "no_prepend[]", "box[0,0;10,8;#101722]", "label[0.7,0.6;QatanCraft • الإنجازات]"}
	for i, def in ipairs(achievements) do
		local done = data.achievements[def.id] ~= nil
		fs[#fs + 1] = ("label[0.8,%f;%s %s — +%d عملة / %d XP]"):format(0.95 + (i - 1) * 0.8, done and "✓" or "○", def.title, def.coins, def.xp)
	end
	fs[#fs + 1] = "button_exit[6.7,6.9;2.5,0.7;close;إغلاق]"
	minetest.show_formspec(player:get_player_name(), modname .. ":achievements", table.concat(fs, ""))
end

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
	if formname == modname .. ":profile" then
		if fields.qatan_achievements then show_achievements(player) end
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
			local balance, nonce = wallet_read()
			data.coins = wallet_write(balance + math.max(0, math.floor(coins or 0)), nonce + 1)
		data.xp = math.min(MAX_XP, data.xp + math.max(0, math.floor(xp or 0)))
		data.level = level_for_xp(data.xp)
		save_data(name, data)
	end,
}
