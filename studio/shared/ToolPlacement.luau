-- Mesmas regras geométricas na prévia e no servidor; apenas o servidor consome itens.
local C = require(script.Parent.GameplayConfig)
local Placement = {}
function Placement.Resolve(position, rootPosition, ground, params, occupied)
	local rules = C.Placement
	if typeof(position) ~= "Vector3" or position.X ~= position.X or position.Y ~= position.Y or position.Z ~= position.Z
		or (position - rootPosition).Magnitude > rules.Distance then
		return nil, "Escolha o chão a até " .. rules.Distance .. " studs."
	end
	if not ground then return nil, "Área de caça indisponível." end
	local point = ground.CFrame:PointToObjectSpace(position)
	if math.abs(point.X) > ground.Size.X / 2 - rules.Border or math.abs(point.Z) > ground.Size.Z / 2 - rules.Border then
		return nil, "Use na área de caça."
	end
	local hit = workspace:Raycast(position + Vector3.new(0, 4, 0), Vector3.new(0, -10, 0), params)
	if not hit or hit.Instance ~= ground or hit.Normal.Y < 0.9 then return nil, "Posicione em chão livre." end
	if (hit.Position - rootPosition).Magnitude > rules.Distance then return nil, "Aproxime-se do local escolhido." end
	local sight = workspace:Raycast(rootPosition, hit.Position - rootPosition, params)
	if sight and sight.Instance ~= ground then return nil, "Há um obstáculo no caminho." end
	local placed = hit.Position + Vector3.new(0, rules.Height, 0)
	for _, part in ipairs(occupied) do
		if part.Parent and (part.Position - placed).Magnitude < rules.Spacing then return nil, "Muito perto de outra ferramenta." end
	end
	return placed
end
return Placement
