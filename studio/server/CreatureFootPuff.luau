-- One short contact puff shared by grounded creature performances.
local Motion = require(game.ReplicatedStorage.HACShared.LumitoMotionConfig)

local FootPuff = {}

function FootPuff.new(root, attachmentName, offset, scale)
	local attachment = Instance.new("Attachment")
	attachment.Name = attachmentName
	attachment.Position = offset * scale
	attachment.Parent = root
	local puff = Instance.new("ParticleEmitter")
	puff.Name = "StepPuff"
	puff.Texture = Motion.PuffTexture
	puff.Rate = 0
	puff.Lifetime = NumberRange.new(0.28, 0.34)
	puff.Speed = NumberRange.new(0.25, 0.55)
	puff.SpreadAngle = Vector2.new(18, 12)
	puff.Rotation = NumberRange.new(-8, 8)
	puff.RotSpeed = NumberRange.new(-12, 12)
	puff.Color = ColorSequence.new(Color3.new(1, 1, 1))
	puff.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.12), NumberSequenceKeypoint.new(0.78, 0.18), NumberSequenceKeypoint.new(1, 1) })
	local size = math.min(scale, 2)
	puff.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.38 * size), NumberSequenceKeypoint.new(1, 0.74 * size) })
	puff.LightEmission = 0.15
	puff.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid2x2
	puff.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
	puff.FlipbookFramerate = NumberRange.new(12)
	puff.Parent = attachment
	return puff -- owned and cleaned up with the creature model
end

return FootPuff
