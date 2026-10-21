-- Presentation only. New lassos may override these values without changing CaptureConfig.
local default = {
	Radius = 1.1,
	TiltDegrees = 38,
	StartTurnsPerSecond = 1.0,
	FullTurnsPerSecond = 2.5,
	EntrySeconds = 0.28,
	ReleaseSeconds = 0.16,
	CancelSeconds = 0.2,
	TrailLifetime = 0.09,
	WaveAmount = 0.055,
	SegmentCount = 24,
	RemoteViewDistance = 130,
	RopeColor = Color3.fromRGB(255, 199, 62),
	BrightColor = Color3.fromRGB(255, 237, 135),
}

local overrides = {
	["Training Lasso"] = {},
}

local Styles = {}
function Styles.For(lassoName)
	local style = table.clone(default)
	for key, value in pairs(overrides[lassoName] or {}) do
		style[key] = value
	end
	return style
end
return Styles
