local Page = {}
function Page.Render(ui)
	ui.pageTitle = "Settings"
	for _, entry in ipairs({
		{ id = "Sound", title = "Sound", description = "Game audio and character sounds." },
		{
			id = "BaseCreatures",
			title = "Base creatures",
			description = "Show creatures roaming in bases. Income is unchanged.",
		},
	}) do
		local enabled = ui.data.profile.settings[entry.id] ~= false
		local card = ui:Card(entry.title, entry.description, 148)
		local skin = ui:ActionButton(card, "Setting:" .. entry.id, enabled and "ON" or "OFF", function()
			ui:Send("SetSetting", entry.id, { value = not enabled })
		end, UDim2.new(1, -12, 0, 40), UDim2.new(0, 6, 1, -46))
		skin:SetSelected(enabled)
	end
end
return Page
