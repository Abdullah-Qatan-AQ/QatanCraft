local modname = minetest.get_current_modname()
local storage = minetest.get_mod_storage()

local function show_welcome(player)
	local name = player:get_player_name()
	local formspec = table.concat({
		"formspec_version[6]",
		"size[10,7]",
		"no_prepend[]",
		"box[0,0;10,7;#101722]",
		"label[0.65,0.55;QatanCraft Survival]",
		"label[0.65,1.05;عالمك المكعب يبدأ الآن]",
		"label[0.65,1.75;اجمع الخشب، اصنع الأدوات، وابنِ مأوى قبل حلول الليل.]",
		"label[0.65,2.25;اسحب يسار الشاشة للحركة، واسحب يمينها للنظر.]",
		"label[0.65,2.75;اضغط للقفز، واضغط مطولًا لتكسير الكتل.]",
		"label[0.65,3.45;نصائح البقاء]",
		"label[0.85,3.9;• ابدأ بجمع الخشب والحجر.]",
		"label[0.85,4.3;• اصنع طاولة عمل وأدوات حجرية.]",
		"label[0.85,4.7;• تناول الطعام واستكشف الكهوف بحذر.]",
		"button[0.65,5.65;4.1,0.85;qatan_continue;ابدأ البقاء]",
		"button[5.25,5.65;4.1,0.85;qatan_controls;شرح التحكم]",
	}, "")
	minetest.show_formspec(name, modname .. ":welcome", formspec)
end

local function show_controls(player)
	local name = player:get_player_name()
	minetest.show_formspec(name, modname .. ":controls", table.concat({
		"formspec_version[6]",
		"size[10,6]",
		"no_prepend[]",
		"box[0,0;10,6;#101722]",
		"label[0.65,0.55;التحكم على الهاتف]",
		"label[0.75,1.3;الحركة: عصا اللمس في الجهة اليسرى]",
		"label[0.75,1.75;النظر: اسحب في الجهة اليمنى من الشاشة]",
		"label[0.75,2.2;التفاعل: اضغط على الكتلة أو اضغط مطولًا]",
		"label[0.75,2.65;القفز: زر القفز، أو النقر المزدوج]",
		"label[0.75,3.1;الحقيبة: زر الحقيبة لفتح التصنيع والمخزون]",
		"button[3.0,4.55;4,0.85;qatan_back;رجوع]",
	}, ""))
end

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	if storage:get_string("welcomed:" .. name) == "" then
		minetest.after(1.5, function()
			if player and player:is_player() then show_welcome(player) end
		end)
	end
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= modname .. ":welcome" and formname ~= modname .. ":controls" then return end
	local name = player:get_player_name()
	if fields.qatan_controls then
		show_controls(player)
	elseif fields.qatan_back then
		show_welcome(player)
	elseif fields.qatan_continue or fields.quit then
		storage:set_string("welcomed:" .. name, "1")
		minetest.close_formspec(name, formname)
	end
end)
