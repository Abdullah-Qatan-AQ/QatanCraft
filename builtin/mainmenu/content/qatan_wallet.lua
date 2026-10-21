-- QatanCraft local ContentDB install gate.
-- This is a non-monetary client-local wallet and never replaces ContentDB transport.
qatan_wallet = {}

local MAX_COINS = 1000000
local busy = false

local function safe_user_name()
	local name = core.settings:get("name") or "local"
	name = name:gsub("[^%w_%-]", "_")
	return name:sub(1, 48)
end

local function key_name()
	return "qatan_wallet_key_" .. safe_user_name()
end

local function digest(value)
	return core.sha1(value)
end

local function key()
	local setting = key_name()
	local value = core.settings:get(setting)
	if value and #value >= 32 then
		return value
	end
	local seed = table.concat({
		tostring(os.time()), tostring(core.get_us_time and core.get_us_time() or 0),
		tostring(math.random()), safe_user_name(), tostring(core.get_user_path and core.get_user_path() or ""),
	}, "|")
	value = digest(seed)
	core.settings:set(setting, value)
	core.settings:write()
	return value
end

local function mac(balance, nonce)
	return digest(table.concat({"QatanCraft wallet v2", key(), balance, nonce}, "|"))
end

function qatan_wallet.read()
	local suffix = "_" .. safe_user_name()
	local balance = tonumber(core.settings:get("qatan_wallet_balance" .. suffix)) or 0
	local nonce = tonumber(core.settings:get("qatan_wallet_nonce" .. suffix)) or 0
	local stored = core.settings:get("qatan_wallet_mac" .. suffix) or ""
	if balance < 0 or balance > MAX_COINS or nonce < 0 or
			stored ~= mac(math.floor(balance), math.floor(nonce)) then
		core.log("warning", "QatanCraft local wallet validation failed; resetting balance")
		return 0, math.max(0, math.floor(nonce))
	end
	return math.floor(balance), math.floor(nonce)
end

function qatan_wallet.write(balance, nonce)
	balance = math.max(0, math.min(MAX_COINS, math.floor(balance)))
	nonce = math.max(0, math.floor(nonce))
	local suffix = "_" .. safe_user_name()
	core.settings:set("qatan_wallet_balance" .. suffix, tostring(balance))
	core.settings:set("qatan_wallet_nonce" .. suffix, tostring(nonce))
	core.settings:set("qatan_wallet_mac" .. suffix, mac(balance, nonce))
	core.settings:write()
end

function qatan_wallet.price(package)
	local text = tostring(package.url_part or package.name or "package")
	local hash = 5381
	for i = 1, #text do hash = (hash * 33 + text:byte(i)) % 2147483647 end
	return 50 + (hash % 951)
end

function qatan_wallet.debit(package)
	if busy then
		return false, 0, qatan_wallet.read()
	end
	busy = true
	local price = qatan_wallet.price(package)
	local balance, nonce = qatan_wallet.read()
	if balance < price then
		busy = false
		return false, price, balance
	end
	qatan_wallet.write(balance - price, nonce + 1)
	busy = false
	return true, price, balance - price
end
