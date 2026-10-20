local modname = minetest.get_current_modname()
local storage = minetest.get_mod_storage()
local help_huds = {}

local function close_for(player, formname)
	minetest.close_formspec(player:get_player_name(), formname)
end

local function show_help(player, page)
	local name = player:get_player_name()
	page = page or "survival"
	local content
	if page == "controls" then
		content = {
			"label[0.7,0.55;التحكم على الهاتف]",
			"box[0.55,1.05;8.9,3.55;#1c3540]",
			"label[0.85,1.35;الحركة: عصا اللمس في الجهة اليسرى]",
			"label[0.85,1.8;النظر: اسحب في الجهة اليمنى من الشاشة]",
			"label[0.85,2.25;التفاعل: اضغط على الكتلة أو اضغط مطولًا]",
			"label[0.85,2.7;القفز: زر القفز، أو النقر المزدوج]",
			"label[0.85,3.15;الحقيبة: افتح المخزون للتصنيع وإدارة الأدوات]",
			"label[0.85,3.6;التخفي: استخدم زر الانحناء للمرور تحت الفتحات]",
			"label[0.85,4.05;المكافآت: /qatan_profile لعرض تقدمك وإنجازاتك]",
		}
	else
		content = {
			"label[0.7,0.55;دليل البقاء]",
			"box[0.55,1.05;8.9,3.55;#1c3540]",
			"label[0.85,1.35;اليوم الأول: اجمع الخشب والحجر قبل حلول الليل.]",
			"label[0.85,1.8;الصناعة: اصنع طاولة عمل، أدوات حجرية، ومشاعل.]",
			"label[0.85,2.25;الأمان: ابنِ مأوى وأغلقه، فالمخلوقات تظهر في الظلام.]",
			"label[0.85,2.7;الغذاء: ازرع أو اصطد واحمل طعامًا في رحلاتك.]",
			"label[0.85,3.15;الاستكشاف: الكهوف غنية بالمعادن لكنها تحتاج إضاءة.]",
			"label[0.85,3.15;الأدوات: طوّر أدواتك، ثم استكشف المناطق الأبعد.]",
			"label[0.85,4.05;المكافآت: أكمل الإنجازات واعرضها عبر /qatan_achievements.]",
		}
	end
	local formspec = table.concat({
		"formspec_version[6]", "size[10,6]", "no_prepend[]",
		"box[0,0;10,6;#101722]",
		"label[0.7,0.12;QatanCraft • مركز المساعدة]",
		table.concat(content, ""),
		"button[0.7,4.95;2.6,0.75;qatan_survival;البقاء]",
		"button[3.7,4.95;2.6,0.75;qatan_controls;التحكم]",
		"button_exit[6.7,4.95;2.6,0.75;qatan_close;متابعة اللعب]",
	}, "")
	minetest.show_formspec(name, modname .. ":help", formspec)
end

local function show_welcome(player)
	local name = player:get_player_name()
	local formspec = table.concat({
		"formspec_version[6]", "size[10,7]", "no_prepend[]",
		"box[0,0;10,7;#101722]",
		"box[0.35,0.35;9.3,6.3;#16313b]",
		"label[0.75,0.7;QatanCraft Survival]",
		"label[0.75,1.2;عالمك المكعب يبدأ الآن]",
		"label[0.75,1.9;اجمع الخشب، اصنع الأدوات، وابنِ مأوى قبل حلول الليل.]",
		"label[0.75,2.35;اسحب يسار الشاشة للحركة، واسحب يمينها للنظر.]",
		"label[0.75,2.8;اضغط للقفز، واضغط مطولًا لتكسير الكتل.]",
		"label[0.75,3.5;أول خطواتك]",
		"label[0.95,3.95;١. اجمع الخشب والحجر]",
		"label[0.95,4.35;٢. اصنع طاولة عمل وأدوات حجرية]",
		"label[0.95,4.75;٣. أشعل المشاعل وابنِ مأوى]",
		"button[0.75,5.65;4.1,0.85;qatan_continue;ابدأ البقاء]",
		"button[5.15,5.65;4.1,0.85;qatan_controls;شرح التحكم]",
	}, "")
	minetest.show_formspec(name, modname .. ":welcome", formspec)
end

local function add_hint(player)
	local name = player:get_player_name()
	local id = player:hud_add({
		hud_elem_type = "text",
		position = {x = 0.5, y = 0.96},
		alignment = {x = 0, y = -1},
		offset = {x = 0, y = -18},
		text = "QatanCraft  •  اكتب /qatan_help لفتح الدليل",
		number = 0xF3D29B,
		text_scale = {x = 100, y = 100},
	})
	help_huds[name] = id
	minetest.after(25, function()
		local current = minetest.get_player_by_name(name)
		if current and help_huds[name] == id then
			current:hud_remove(id)
			help_huds[name] = nil
		end
	end)
end

minetest.register_chatcommand("qatan_help", {
	description = "فتح دليل QatanCraft",
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if player then show_help(player, "survival") end
		return true
	end,
})

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	add_hint(player)
	if storage:get_string("welcomed:" .. name) == "" then
		minetest.after(1.5, function()
			if player and player:is_player() then show_welcome(player) end
		end)
	end
end)

minetest.register_on_leaveplayer(function(player)
	help_huds[player:get_player_name()] = nil
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == modname .. ":help" then
		if fields.qatan_controls then show_help(player, "controls")
		elseif fields.qatan_survival then show_help(player, "survival") end
		return true
	end
	if formname ~= modname .. ":welcome" then return end
	local name = player:get_player_name()
	if fields.qatan_controls then
		show_help(player, "controls")
	elseif fields.qatan_continue or fields.quit then
		storage:set_string("welcomed:" .. name, "1")
		close_for(player, formname)
	end
	return true
end)
