-- Rebuildable visual pass for HAC_IlhaBase. Run in Studio Edit via execute_luau.
-- Does not move gameplay systems or change HuntACreature.
local island = assert(workspace:FindFirstChild("HAC_IlhaBase"), "HAC_IlhaBase missing")
local lots = assert(island:FindFirstChild("Lotes"), "Lotes missing")
local old = island:FindFirstChild("PreviewV02")
if old then old:Destroy() end
local preview = Instance.new("Folder")
preview.Name = "PreviewV02"
preview:SetAttribute("HACPurpose", "Visual review only; no gameplay bindings")
preview.Parent = island

local C = {
    wood = Color3.fromRGB(170, 108, 58), darkWood = Color3.fromRGB(111, 70, 46),
    cream = Color3.fromRGB(255, 238, 183), white = Color3.fromRGB(255, 250, 228),
    red = Color3.fromRGB(238, 83, 75), cyan = Color3.fromRGB(69, 205, 229),
    blue = Color3.fromRGB(75, 171, 224), navy = Color3.fromRGB(50, 72, 107),
    gold = Color3.fromRGB(255, 199, 73), green = Color3.fromRGB(101, 224, 100),
    purple = Color3.fromRGB(166, 111, 227), sand = Color3.fromRGB(246, 210, 139),
}
local function part(parent, name, size, cf, color, material, shape)
    local p = Instance.new("Part")
    p.Name, p.Size, p.CFrame = name, size, cf
    p.Color, p.Material = color, material or Enum.Material.SmoothPlastic
    if shape then p.Shape = shape end
    p.Anchored, p.CanCollide, p.CanTouch = true, true, false
    p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end
local function group(name)
    local m = Instance.new("Model")
    m.Name = name
    m.Parent = preview
    return m
end
local function label(adornee, title, color)
    local gui = Instance.new("BillboardGui")
    gui.Name = "PreviewLabel"
    gui.Adornee = adornee
    gui.AlwaysOnTop = false
    gui.Size = UDim2.fromOffset(240, 52)
    gui.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
    gui.MaxDistance = 100
    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Size = UDim2.fromScale(1, 1)
    text.Text = title
    text.TextColor3 = color
    text.TextStrokeColor3 = C.navy
    text.TextStrokeTransparency = 0
    text.Font = Enum.Font.FredokaOne
    text.TextScaled = true
    text.Parent = gui
    gui.Parent = adornee
end

-- Ocean is isolated from the old test island and sits below the dry beach.
local sea = group("Ocean")
local water = part(sea, "CalmWater", Vector3.new(0.7, 420, 420), CFrame.new(0, 2.05, -430) * CFrame.Angles(0, 0, math.rad(90)), C.blue, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
water.Transparency = 0.34
water.CanCollide, water.CanQuery = false, false
local shallow = part(sea, "ShallowTint", Vector3.new(0.06, 255, 285), CFrame.new(0, 2.43, -430) * CFrame.Angles(0, 0, math.rad(90)), C.cyan, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
shallow.Transparency = 0.78
shallow.CanCollide, shallow.CanQuery = false, false

local function buildPen(index)
    local lot = assert(lots:FindFirstChild("Lote_Base" .. index))
    local floor = assert(lot:FindFirstChild("Piso"))
    local m = group("CreaturePen" .. index)
    m:SetAttribute("HACLot", lot.Name)
    local root = floor.CFrame
    local halfX, halfZ = floor.Size.X / 2 - 1.4, floor.Size.Z / 2 - 1.4
    local y = 8.95
    local function localPart(name, size, x, cy, z, color)
        return part(m, name, size, root * CFrame.new(x, cy - root.Position.Y, z), color)
    end
    local postH = 3.4
    -- Front opening is deliberately wide so avatars and large creatures can enter.
    local gateHalf = 5.2
    local function rail(name, xa, xb, z, height)
        local length = xb - xa
        if length > 0.1 then localPart(name, Vector3.new(length, 0.42, 0.48), (xa + xb)/2, y + height, z, C.wood) end
    end
    for _, z in ipairs({-halfZ, halfZ}) do
        for _, x in ipairs({-halfX, halfX}) do
            localPart("CornerPost", Vector3.new(0.8, postH, 0.8), x, y + postH/2, z, C.darkWood)
            localPart("PostCap", Vector3.new(1.1, 0.3, 1.1), x, y + postH + 0.15, z, C.cream)
        end
    end
    for _, z in ipairs({-halfZ, halfZ}) do
        for _, h in ipairs({1.1, 2.55}) do
            if z < 0 then
                rail("EntranceRail", -halfX, -gateHalf, z, h)
                rail("EntranceRail", gateHalf, halfX, z, h)
            else rail("BackRail", -halfX, halfX, z, h) end
        end
        for x = -halfX + 6, halfX - 3, 6 do
            if z > 0 or math.abs(x) > gateHalf + 1 then
                localPart("FencePost", Vector3.new(0.55, 2.9, 0.55), x, y + 1.45, z, C.darkWood)
            end
        end
    end
    for _, x in ipairs({-halfX, halfX}) do
        for _, h in ipairs({1.1, 2.55}) do
            localPart("SideRail", Vector3.new(0.48, 0.42, 2*halfZ), x, y + h, 0, C.wood)
        end
        for z = -halfZ + 6, halfZ - 3, 6 do
            localPart("FencePost", Vector3.new(0.55, 2.9, 0.55), x, y + 1.45, z, C.darkWood)
        end
    end
    -- Small sign is a visual placeholder; ownership UI is wired during migration.
    local sign = localPart("PenSign", Vector3.new(5, 2.3, 0.38), 0, y + 3.9, -halfZ, C.navy)
    localPart("SignTrim", Vector3.new(5.4, 0.24, 0.5), 0, y + 5.1, -halfZ, C.gold)
    label(sign, "BASE " .. index, C.white)
    return m
end
for i = 1, 6 do buildPen(i) task.wait() end

local function buildTraining(index)
    local lot = assert(lots:FindFirstChild("Lote_Treino" .. index))
    local floor = assert(lot:FindFirstChild("Piso"))
    local m = group("TrainingStation" .. index)
    m:SetAttribute("HACLot", lot.Name)
    local cf, baseY = floor.CFrame, 8.98
    local function lp(name, size, x, cy, z, col, shape)
        return part(m, name, size, cf * CFrame.new(x, cy - cf.Position.Y, z), col, nil, shape)
    end
    -- Target stays within its reserved circle, with clear room for the avatar.
    lp("TargetStand", Vector3.new(0.8, 3, 0.8), 0, baseY + 1.5, 1.6, C.darkWood)
    lp("TargetBody", Vector3.new(2.2, 2.3, 1.4), 0, baseY + 3.8, 1.6, C.sand)
    lp("TargetHead", Vector3.new(1.5, 1.5, 1.5), 0, baseY + 5.55, 1.6, C.cream, Enum.PartType.Ball)
    lp("TargetBand", Vector3.new(2.35, 0.3, 1.55), 0, baseY + 4.1, 1.6, C.cyan)
    lp("LeftArm", Vector3.new(1.3, 0.55, 0.7), -1.65, baseY + 4.45, 1.6, C.wood)
    lp("RightArm", Vector3.new(1.3, 0.55, 0.7), 1.65, baseY + 4.45, 1.6, C.wood)
    local board = lp("TrainingMarker", Vector3.new(2.7, 0.4, 0.45), 0, baseY + 7.1, 1.6, C.navy)
    label(board, "TRAIN", C.cyan)
end
for i = 1, 6 do buildTraining(i) task.wait() end

local function buildShop(index, title, accent)
    local lot = assert(lots:FindFirstChild("Lote_Loja" .. index))
    local floor = assert(lot:FindFirstChild("Piso"))
    local m = group("ShopBuilding" .. index)
    m:SetAttribute("HACLot", lot.Name)
    local cf, y = floor.CFrame, 8.95
    local function lp(name, size, x, cy, z, color)
        return part(m, name, size, cf * CFrame.new(x, cy - cf.Position.Y, z), color)
    end
    lp("BackWall", Vector3.new(17, 8, 0.7), 0, y+4, 6.6, C.cream)
    lp("LeftWall", Vector3.new(0.7, 8, 12), -8.5, y+4, 0.6, C.cream)
    lp("RightWall", Vector3.new(0.7, 8, 12), 8.5, y+4, 0.6, C.cream)
    lp("Roof", Vector3.new(19.5, 0.8, 15), 0, y+8.5, 0.4, accent)
    for x = -8, 8, 4 do lp("AwningStripe", Vector3.new(3.8, 0.22, 3), x, y+7.95, -7.6, x % 8 == 0 and C.white or accent) end
    lp("Counter", Vector3.new(15, 2.5, 2), 0, y+1.25, -4.7, C.wood)
    lp("CounterTop", Vector3.new(15.6, 0.35, 2.4), 0, y+2.65, -4.7, C.cream)
    local sign = lp("ShopSign", Vector3.new(14, 2.4, 0.45), 0, y+6.2, -7.45, C.navy)
    label(sign, title, C.white)
end
buildShop(1, "HUNTING SHOP", C.red)
task.wait()
buildShop(2, "CREATURE MARKET", C.purple)
task.wait()

local boatLot = assert(lots:FindFirstChild("Lote_Barco1"))
local boatVolume = assert(boatLot:FindFirstChild("Volume"))
local boat = group("TravelBoat")
boat:SetAttribute("HACLot", boatLot.Name)
local bx, bz = boatVolume.Position.X, boatVolume.Position.Z
local function bp(name, size, x, y, z, color)
    return part(boat, name, size, CFrame.new(bx+x, y, bz+z), color)
end
bp("Hull", Vector3.new(17, 2, 18), 0, 3.6, 0, C.darkWood)
bp("Deck", Vector3.new(15.5, 0.55, 17), 0, 4.9, 0, C.wood)
for _, x in ipairs({-8.4, 8.4}) do
    bp("Gunwale", Vector3.new(0.7, 1.1, 18), x, 5.45, 0, C.gold)
end
bp("Bow", Vector3.new(8, 1.5, 2.3), 0, 4.2, -9.5, C.wood)
bp("Mast", Vector3.new(0.9, 14, 0.9), 0, 12.2, 1.6, C.darkWood)
bp("Sail", Vector3.new(9, 10, 0.35), 0, 13.5, 1.6, C.white)
bp("SailStripe", Vector3.new(9, 1, 0.39), 0, 16.4, 1.6, C.cyan)
local bowSign = bp("BoatSign", Vector3.new(7, 1.3, 0.5), 0, 6.5, -8, C.navy)
label(bowSign, "ISLANDS", C.gold)

return "PreviewV02 built: ocean, six pens, six training markers, two shops, one boat. Gameplay still uses HuntACreature."
