-- QatanCraft local ContentDB install gate.
-- This is a non-monetary client-local wallet and never replaces ContentDB transport.
qatan_wallet = {}

local WALLET_SALT = 17382941
local MAX_COINS = 1000000

local function mac(balance, nonce)
	return tostring((balance * 1103515245 + nonce * 12345 + WALLET_SALT) % 2147483647)
end

function qatan_wallet.read()
	local balance = tonumber(core.settings:get("qatan_wallet_balance")) or 0
	local nonce = tonumber(core.settings:get("qatan_wallet_nonce")) or 0
	local stored = core.settings:get("qatan_wallet_mac") or ""
	if balance < 0 or balance > MAX_COINS or nonce < 0 or stored ~= mac(balance, nonce) then
		core.log("warning", "QatanCraft local wallet validation failed; resetting balance")
		return 0, math.max(0, math.floor(nonce))
	end
	return math.floor(balance), math.floor(nonce)
end

function qatan_wallet.write(balance, nonce)
	balance = math.max(0, math.min(MAX_COINS, math.floor(balance)))
	nonce = math.max(0, math.floor(nonce))
	core.settings:set("qatan_wallet_balance", tostring(balance))
	core.settings:set("qatan_wallet_nonce", tostring(nonce))
	core.settings:set("qatan_wallet_mac", mac(balance, nonce))
	core.settings:write()
end

function qatan_wallet.price(package)
	local text = tostring(package.url_part or package.name or "package")
	local hash = 5381
	for i = 1, #text do hash = (hash * 33 + text:byte(i)) % 2147483647 end
	return 50 + (hash % 951)
end

function qatan_wallet.debit(package)
	local price = qatan_wallet.price(package)
	local balance, nonce = qatan_wallet.read()
	if balance < price then return false, price, balance end
	qatan_wallet.write(balance - price, nonce + 1)
	return true, price, balance - price
end
