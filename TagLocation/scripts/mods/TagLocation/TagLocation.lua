local mod = get_mod("TagLocation")

mod:hook("HudElementSmartTagging", "_on_tag_stop_callback", function(func, self, t, ui_renderer, render_settings)
	if self.destroyed then
		return
	end

	func(self, t, ui_renderer, render_settings)

	local _, _, target_position = self:_find_best_smart_tag_interaction(
		ui_renderer,
		render_settings,
		force_update_targets
	)

	local tag_context = self._tag_context

	if tag_context.marker_handled == false and tag_context.enemy_tagged == false then
		-- it didnt tag anything so add a location ping
		self:_trigger_smart_tag("location_ping", nil, target_position)
	end
end)
