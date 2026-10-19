-- Mesmas regras geométricas na prévia e no servidor; apenas o servidor consome itens.
local C = require(script.Parent.GameplayConfig)
local Placement = {}
function Placement.Resolve(position, rootPosition, ground, params, occupied)
	local rules = C.Placement
	if typeof(position) ~= "Vector3" or position.X ~= position.X or position.Y ~= position.Y or position.Z ~= position.Z
		or (position - rootPosition).Magnitude > rules.Distance then
		return nil, "Choose ground within " .. rules.Distance .. " studs."
	end
	if not ground then return nil, "Hunting area unavailable." end
	local point = ground.CFrame:PointToObjectSpace(position)
	if math.abs(point.X) > ground.Size.X / 2 - rules.Border or math.abs(point.Z) > ground.Size.Z / 2 - rules.Border then
		return nil, "Use in the hunting area."
	end
	local hit = workspace:Raycast(position + Vector3.new(0, 4, 0), Vector3.new(0, -10, 0), params)
	if not hit or hit.Instance ~= ground or hit.Normal.Y < 0.9 then return nil, "Place on clear ground." end
	if (hit.Position - rootPosition).Magnitude > rules.Distance then return nil, "Move closer to the target spot." end
	local sight = workspace:Raycast(rootPosition, hit.Position - rootPosition, params)
	if sight and sight.Instance ~= ground then return nil, "Something is blocking the way." end
	local placed = hit.Position + Vector3.new(0, rules.Height, 0)
	for _, part in ipairs(occupied) do
		if part.Parent and (part.Position - placed).Magnitude < rules.Spacing then return nil, "Too close to another tool." end
	end
	return placed
end
return Placement
