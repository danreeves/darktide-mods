return {
	mod_name = {
		en = "Ping Monitor",
		ru = "Индикатор пинга",
		["zh-cn"] = "网络延迟显示",
	},
	mod_description = {
		en = "Displays your ping to the host in the tab menu in game",
		["zh-cn"] = "在游戏内的 Tab 菜单显示到服务器的延迟",
		ru = "Показывает значение пинга в игре, при нажатии ТАВ",
	},
	always_visible = {
		en = "Always show during gameplay",
	},
	always_visible_tooltip = {
		en = "Keeps your ping on screen while you are alive in missions and the Mourningstar, not only while the tactical overlay is open.\nIt stays hidden in menus, cutscenes and loading screens, and while you are dead or spectating, where the tactical overlay still shows it.",
	},
	averaging_samples = {
		en = "Averaging samples",
	},
	averaging_samples_tooltip = {
		en = "How many of the latest ping measurements your ping and its colour are averaged over.\nThe game measures about once per second, so fewer samples react faster to connection changes and more samples give a steadier number.",
	},
	widget_position = {
		en = "Widget position",
	},
	position_anchor = {
		en = "Anchor",
	},
	position_anchor_tooltip = {
		en = "The screen edge or corner the offsets below are measured from.\nChanging it keeps your ping where it is on screen and converts the offsets to the new anchor.",
	},
	anchor_top_left = {
		en = "Top left",
	},
	anchor_top_center = {
		en = "Top centre",
	},
	anchor_top_right = {
		en = "Top right",
	},
	anchor_center_left = {
		en = "Centre left",
	},
	anchor_center = {
		en = "Centre",
	},
	anchor_center_right = {
		en = "Centre right",
	},
	anchor_bottom_left = {
		en = "Bottom left",
	},
	anchor_bottom_center = {
		en = "Bottom centre",
	},
	anchor_bottom_right = {
		en = "Bottom right",
	},
	position_x = {
		en = "Horizontal offset",
	},
	position_x_tooltip = {
		en = "Moves your ping from the anchor, right for positive values and left for negative ones.\nThe offset is in HUD units, which scale with your resolution and HUD scale, so they aren't screen pixels. Your ping stops at the screen edge.",
	},
	position_y = {
		en = "Vertical offset",
	},
	position_y_tooltip = {
		en = "Moves your ping from the anchor, down for positive values and up for negative ones.\nThe offset is in HUD units, which scale with your resolution and HUD scale, so they aren't screen pixels. Your ping stops at the screen edge.",
	},
}
