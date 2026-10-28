-- Studio-only A/B display. It never registers creatures with hunt, capture or saves.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() or game.PlaceId ~= 102310424634629 then return end
if workspace:GetAttribute("HACShowLumitoComparison") ~= true then return end

local Builder = require(game.ServerScriptService.HACServer.LumitoComparisonBuilder)
local Legacy = require(game.ServerScriptService.HACServer.LumitoAnimator)
local arena = Builder.Build()
local original = assert(arena:FindFirstChild("Original"))
local rig = assert(arena:FindFirstChild("Rig"))
local oldAnimator = Legacy.new(original)
oldAnimator.hadAttention = true
oldAnimator.nextGesture = math.huge

local stages = {
	{untilTime = 12, state = "AtBase", speed = 0},
	{untilTime = 23, state = "Wandering", speed = 3.5},
	{untilTime = 30, state = "Panicking", speed = 14},
	{untilTime = 39, state = "Tired", speed = 1.8},
	{untilTime = 46, state = "Capturing", speed = 0},
	{untilTime = 50, state = "AtBase", speed = 0},
}
local gestureTimes = {
	{at = 2.2, number = 1, name = "Curious"},
	{at = 6.0, number = 2, name = "Greeting"},
	{at = 9.4, number = 3, name = "Playful"},
}
local modes = {
	{scale = 1, gold = false}, {scale = 3, gold = false},
	{scale = 1, gold = true}, {scale = 3, gold = true},
}
local elapsed, cycle, angle, clock = 0, 0, 0, 0
local lastState, lastGesture = nil, 0
local gestureSerial = 0

arena:SetAttribute("DemoState", "AtBase")
arena:SetAttribute("DemoSpeed", 0)
arena:SetAttribute("DemoGesture", "")
arena:SetAttribute("DemoGestureSerial", 0)

RunService.Heartbeat:Connect(function(dt)
	if not arena.Parent then return end
	clock += dt
	if clock < 0.05 then return end
	local step = math.min(clock, 0.1)
	clock = 0
	elapsed += step
	if elapsed >= 50 then
		elapsed -= 50
		cycle += 1
		local mode = modes[cycle % #modes + 1]
		original, rig = Builder.RebuildActors(arena, mode.scale, mode.gold)
		oldAnimator = Legacy.new(original)
		oldAnimator.hadAttention = true
		oldAnimator.nextGesture = math.huge
		lastState, lastGesture = nil, 0
	end
	local stage = stages[#stages]
	for _, candidate in ipairs(stages) do
		if elapsed < candidate.untilTime then stage = candidate; break end
	end
	local state, speed = stage.state, stage.speed
	if state ~= lastState then
		lastState = state
		arena:SetAttribute("DemoState", state)
	end
	arena:SetAttribute("DemoSpeed", speed)
	for index, gesture in ipairs(gestureTimes) do
		if elapsed >= gesture.at and lastGesture < index then
			lastGesture = index
			oldAnimator.gesture, oldAnimator.gestureTime = gesture.number, 0
			gestureSerial += 1
			arena:SetAttribute("DemoGesture", gesture.name)
			arena:SetAttribute("DemoGestureSerial", gestureSerial)
		end
	end
	if speed > 0 then
		local tangent = Vector3.new(-12 * math.sin(angle), 0, 3 * math.cos(angle))
		angle += step * speed / math.max(tangent.Magnitude, 2)
	end
	local x, offsetZ = 181 + 12 * math.cos(angle), 3 * math.sin(angle)
	local tangent = Vector3.new(-12 * math.sin(angle), 0, 3 * math.cos(angle)).Unit
	local scale = arena:GetAttribute("DisplayScale") or 1
	local y = 4 + (1.625 + 0.06) * scale
	local sourcePose = CFrame.lookAt(Vector3.new(x, y, -10 + offsetZ), Vector3.new(x, y, -10 + offsetZ) + tangent)
	local rigPose = CFrame.lookAt(Vector3.new(x, y, 10 + offsetZ), Vector3.new(x, y, 10 + offsetZ) + tangent)
	local attention = sourcePose.Position + sourcePose.LookVector * 4 + Vector3.new(2, 0, 0)
	oldAnimator:Step(step, sourcePose, state, speed, attention, state == "Capturing" and "resist" or nil)
	rig.PrimaryPart.CFrame = rigPose
	local collider = rig:FindFirstChild("Corpo")
	if collider then collider.CFrame = rigPose end
end)
