-- Contato contínuo com o corpo, independente de pés/olhos animados.
-- O servidor considera o deslocamento relativo do projétil e da criatura.
local Collision = {}

function Collision.Segment(startPoint, endPoint, previousCenter, center, rotation, radii)
	local a = rotation:VectorToObjectSpace(startPoint - previousCenter) / radii
	local b = rotation:VectorToObjectSpace(endPoint - center) / radii
	local delta = b - a
	local c = a:Dot(a) - 1
	if c <= 0 then return 0 end -- Já está em contato no início do passo.
	local quadratic = delta:Dot(delta)
	if quadratic < 1e-10 then return nil end
	local linear = 2 * a:Dot(delta)
	local discriminant = linear * linear - 4 * quadratic * c
	if discriminant < 0 then return nil end
	local t = (-linear - math.sqrt(discriminant)) / (2 * quadratic)
	return t >= 0 and t <= 1 and t or nil
end

function Collision.Snapshot(folder)
	local result = {}
	for _, model in ipairs(folder:GetChildren()) do
		if model:IsA("Model") and model.PrimaryPart then
			local body = model:FindFirstChild("Corpo") or model.PrimaryPart
			if body:IsA("BasePart") then
				result[model] = { center = body.Position, rotation = body.CFrame.Rotation, size = body.Size }
			end
		end
	end
	return result
end

function Collision.Find(startPoint, endPoint, previous, current, radius, blockerT, params)
	local closest, earliest = nil, blockerT or math.huge
	for model, body in pairs(current) do
		local old = previous[model] or body
		local radii = body.size / 2 + Vector3.one * radius
		local t = Collision.Segment(startPoint, endPoint, old.center, body.center, body.rotation, radii)
		if t and t < earliest then
			local contact = startPoint:Lerp(endPoint, t)
			-- O volume de contato não permite capturar através de uma parede.
			local visible = not workspace:Raycast(contact, body.center - contact, params)
			if visible then closest, earliest = model, t end
		end
	end
	return closest, closest and earliest or nil
end

return Collision
