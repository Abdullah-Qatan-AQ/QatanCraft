-- Luanti
-- SPDX-License-Identifier: LGPL-2.1-or-later
local function reset()
	local values = {}
	local writes = 0
	local env = {
		core = {},
		qatan_wallet = {},
		math = math,
		os = os,
		tostring = tostring,
		table = table,
		tonumber = tonumber,
		pairs = pairs,
	}
	env._G = env
	setmetatable(env, {__index = _G})
	local core = env.core
	core.settings = {
		get = function(_, key) return values[key] end,
		set = function(_, key, value) values[key] = value end,
		write = function() writes = writes + 1 end,
	}
	core.sha1 = function(value)
		local sum = 0
		for i = 1, #value do sum = (sum + value:byte(i) * i) % 1000000000 end
		return string.format("%040d", sum)
	end
	core.get_us_time = function() return 123456 end
	core.get_user_path = function() return "/tmp/qatan-test" end
	core.log = function() end
	setfenv(loadfile("builtin/mainmenu/content/qatan_wallet.lua"), env)()
	return env, values, function() return writes end
end

describe("qatan_wallet", function()
	it("rejects a forged balance", function()
		local env, values = reset()
		values.name = "tester"
		values.qatan_wallet_balance_tester = "999999"
		values.qatan_wallet_nonce_tester = "0"
		values.qatan_wallet_mac_tester = "forged"
		local balance = env.qatan_wallet.read()
		assert.are.equal(0, balance)
	end)

	it("does not debit or queue anything when balance is insufficient", function()
		local env, _, writes = reset()
		local package = {name = "example-mod", url_part = "example-mod"}
		env.qatan_wallet.read()
		local before = writes()
		local ok, price, balance = env.qatan_wallet.debit(package)
		assert.is_false(ok)
		assert.is_true(price > balance)
		assert.are.equal(before, writes())
	end)

	it("debits once and refuses a repeated debit without credit", function()
		local env, values = reset()
		values.name = "tester"
		local package = {name = "example-mod", url_part = "example-mod"}
		local price = env.qatan_wallet.price(package)
		env.qatan_wallet.write(price, 0)
		local ok, _, remaining = env.qatan_wallet.debit(package)
		assert.is_true(ok)
		assert.are.equal(0, remaining)
		local ok_again = env.qatan_wallet.debit(package)
		assert.is_false(ok_again)
	end)
end)
