local Kit = require(script.Parent.MenuKit)
local W = require(script.Parent.HUDWidgets)
local TweenService = game:GetService("TweenService")
local Audio = require(script.Parent.AudioFeedback)
local Page = {}
function Page.Render(ui)
	ui.pageTitle = "Settings"
	for order, entry in ipairs({
		{ id = "Sound", title = "Sound", description = "Game & character audio" },
		{ id = "BaseCreatures", title = "Base creatures", description = "Visibility only · income stays on" },
	}) do
		local enabled = ui.data.profile.settings[entry.id] ~= false
		local compact = ui.root.Size.X.Offset < 540
		local row = Kit.Surface(
			ui.scroll,
			entry.id,
			UDim2.new(1, -2, 0, compact and 148 or 128),
			UDim2.new(),
			Kit.Theme.Surface
		)
		row.LayoutOrder = order
		Kit.Label(
			row,
			"Title",
			entry.title,
			UDim2.new(1, compact and -24 or -198, 0, 42),
			UDim2.fromOffset(18, 18),
			compact and 26 or 32,
			nil,
			Enum.TextXAlignment.Left
		)
		Kit.Label(
			row,
			"Description",
			entry.description,
			UDim2.new(1, compact and -24 or -198, 0, 34),
			UDim2.fromOffset(18, 60),
			16,
			Kit.Theme.Muted,
			Enum.TextXAlignment.Left
		)
		local toggle = Instance.new("TextButton")
		toggle.Name, toggle.Text, toggle.AutoButtonColor = "Toggle", "", false
		toggle.Size = UDim2.fromOffset(148, 52)
		toggle.Position = compact and UDim2.new(1, -166, 1, -58) or UDim2.new(1, -166, 0.5, -26)
		toggle.BackgroundColor3, toggle.ZIndex, toggle.Parent = Kit.Theme.Ink, row.ZIndex + 5, row
		toggle:SetAttribute("FocusKey", "Setting:" .. entry.id)
		local corner = Instance.new("UICorner")
		corner.CornerRadius, corner.Parent = UDim.new(0, 9), toggle
		local rim = W.stroke(toggle, enabled and W.Style.UI.Green or Kit.Theme.Muted, 2)
		local knob = Kit.Surface(
			toggle,
			"Knob",
			UDim2.fromOffset(58, 40),
			UDim2.fromOffset(enabled and 84 or 6, 6),
			enabled and W.Style.UI.Green or Kit.Theme.Muted
		)
		local label = Kit.Label(
			toggle,
			"State",
			enabled and "ON" or "OFF",
			UDim2.fromOffset(72, 46),
			UDim2.fromOffset(enabled and 6 or 72, 3),
			21
		)
		local tween
		local pending = false
		local function focus(active)
			rim.Thickness = active and 4 or 2
		end
		toggle.MouseEnter:Connect(function()
			focus(true)
		end)
		toggle.MouseLeave:Connect(function()
			focus(false)
		end)
		toggle.SelectionGained:Connect(function()
			focus(true)
		end)
		toggle.SelectionLost:Connect(function()
			focus(false)
		end)
		toggle.Activated:Connect(function()
			if pending then
				return
			end
			pending = true
			Audio.Play("Click")
			-- Animate intent; authoritative data re-renders the real state.
			tween = TweenService:Create(
				knob,
				TweenInfo.new(0.16, Enum.EasingStyle.Quad),
				{ Position = UDim2.fromOffset(enabled and 6 or 84, 6) }
			)
			tween:Play()
			label.Text = "…"
			ui:Send("SetSetting", entry.id, { value = not enabled })
			task.delay(1.5, function()
				if row.Parent and pending then
					pending = false
					ui:Render()
				end
			end)
		end)
		row.Destroying:Connect(function()
			pending = false
			if tween then
				tween:Cancel()
			end
		end)
	end
end
return Page
