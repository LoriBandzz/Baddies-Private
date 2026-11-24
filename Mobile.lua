local player = game:GetService("Players").LocalPlayer
local pg = player:WaitForChild("PlayerGui")

-- SETTINGS
local DefaultCooldown = 0.30
local SwitchDelay = 0

-- COMBAT WEAPONS ONLY
local CombatWeapons = {
    ["1 punches"] = true,
    ["punches"] = true,
    ["anchor shooter"] = true,
    ["axe"] = true,
    ["blast bow"] = true,
    ["golden snowball launcher"] = true,
    ["inferno blade"] = true,
    ["katana & kunai set"] = true,
    ["mace"] = true,
    ["sakura blade"] = true,
    ["sledgehammer"] = true,
    ["snowball launcher"] = true,
    ["spearhead stick"] = true,
    ["spiked nightmare purse"] = true,
    ["spiked bat"] = true,
    ["spikedpurse"] = true,
    ["stick"] = true,
    ["taser"] = true,
    ["twin blade"] = true
}

-- WEAPON COOLDOWNS
local WeaponCooldowns = {
    ["1 punches"] = 0.30,
    ["punches"] = 0.30
}

local function getCooldown(tool)
    local name = tool.Name:lower()

    if name == "1 punches" or name == "punches" then

        if player:GetAttribute("SpikedKnucklesEquipped") then
            return 0.30

        elseif player:GetAttribute("BrassKnucklesEquipped") then
            return 0.25

        elseif player:GetAttribute("WepsKnucklesEquipped") then
            return 0.15

        elseif player:GetAttribute("ChampionGlovesEquipped") then
            return 0.20

        elseif player:GetAttribute("PoisonKnucklesEquipped") then
            return 0.22
        end

        return 0.30
    end

    return WeaponCooldowns[name] or DefaultCooldown
end

local running = false
local session = 0
local selected = {}

-- REMOVE OLD GUI
local old = pg:FindFirstChild("CombatMacro")
if old then
    old:Destroy()
end

-- CREATE GUI
local gui = Instance.new("ScreenGui")
gui.Name = "CombatMacro"
gui.ResetOnSpawn = false
gui.DisplayOrder = 9999
gui.Parent = pg

local function makeButton(parent, text, size, pos)
    local b = Instance.new("TextButton")
    b.Size = size
    b.Position = pos
    b.BackgroundColor3 = Color3.fromRGB(35,35,35)
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.Text = text
    b.Active = true
    b.Interactable = true
    b.Draggable = false
    b.Parent = parent

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0,8)
    c.Parent = b

    return b
end

-- TOGGLE BUTTON
local toggle = makeButton(
    gui,
    "MACRO: OFF",
    UDim2.fromOffset(150,45),
    UDim2.new(0.03,0,0.3,0)
)

-- SELECT WEAPONS BUTTON
local selectButton = makeButton(
    gui,
    "SELECT WEAPONS",
    UDim2.fromOffset(150,35),
    UDim2.new(0.03,0,0.3,50)
)

-- WEAPON MENU
local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(240,280)
panel.Position = UDim2.new(0.5,-120,0.5,-140)
panel.BackgroundColor3 = Color3.fromRGB(20,20,20)
panel.Visible = false
panel.Active = true
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,10)
corner.Parent = panel

local close = makeButton(
    panel,
    "DONE",
    UDim2.new(1,-12,0,32),
    UDim2.fromOffset(6,6)
)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1,-12,1,-50)
scroll.Position = UDim2.fromOffset(6,44)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 4
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new()
scroll.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0,4)
layout.Parent = scroll

-- FIND OWNED COMBAT WEAPONS
local function getTools()
    local tools = {}

    local function scan(container)
        if not container then return end

        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") then
                local name = item.Name:lower()
                name = name:match("^%s*(.-)%s*$")

                if CombatWeapons[name] then
                    table.insert(tools,item)
                end
            end
        end
    end

    scan(player:FindFirstChild("Backpack"))
    scan(player.Character)

    table.sort(tools,function(a,b)
        return a.Name < b.Name
    end)

    return tools
end

-- REFRESH SELECTION MENU
local function refreshMenu()
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local seen = {}

    for _, tool in ipairs(getTools()) do
        local name = tool.Name

        if not seen[name] then
            seen[name] = true

            local b = makeButton(
                scroll,
                name,
                UDim2.new(1,-5,0,32),
                UDim2.new()
            )

            local function update()
                b.Text = (selected[name]
                    and "[ON] "
                    or "[OFF] ") .. name

                b.BackgroundColor3 = selected[name]
                    and Color3.fromRGB(30,150,70)
                    or Color3.fromRGB(45,45,45)
            end

            b.Activated:Connect(function()
                selected[name] = not selected[name]
                update()
            end)

            update()
        end
    end

    for name in pairs(selected) do
        if not seen[name] then
            selected[name] = nil
        end
    end

    if not next(seen) then
        makeButton(
            scroll,
            "No combat weapons found",
            UDim2.new(1,-5,0,32),
            UDim2.new()
        )
    end
end

selectButton.Activated:Connect(function()
    panel.Visible = not panel.Visible

    if panel.Visible then
        refreshMenu()
    end
end)

close.Activated:Connect(function()
    panel.Visible = false
end)

-- CHECK MACRO STATE
local function active(id)
    return running
        and session == id
        and gui.Parent ~= nil
end

-- COOLDOWN-AWARE MACRO
local function macro(id)
    while active(id) do
        local char = player.Character
        local hum = char and
            char:FindFirstChildOfClass("Humanoid")

        local tools = {}

        for _, tool in ipairs(getTools()) do
            if selected[tool.Name] then
                table.insert(tools,tool)
            end
        end

        if #tools == 0 then
            toggle.Text = "SELECT WEAPONS"
        end

        if hum and hum.Health > 0 then
            for _, tool in ipairs(tools) do

                if not active(id) then return end
                if player.Character ~= char then break end
                if hum.Health <= 0 then break end

                if selected[tool.Name] and tool.Parent then

                    if tool.Parent ~= char then
                        hum:EquipTool(tool)
                        task.wait(SwitchDelay)
                    end

                    if not active(id) then return end

                    if tool.Parent == char then

                        local cooldown = getCooldown(tool)
                        local started = os.clock()

                        toggle.Text = "MACRO: ON\n" .. tool.Name

                        tool:Activate()
                        task.wait()
                        tool:Deactivate()

                        -- HOLD WEAPON UNTIL
                        -- ESTIMATED COOLDOWN ENDS
                        while os.clock() - started < cooldown do

                            if not active(id) then
                                return
                            end

                            if tool.Parent ~= char then
                                break
                            end

                            if not selected[tool.Name] then
                                break
                            end

                            if player.Character ~= char then
                                break
                            end

                            task.wait()
                        end
                    end
                end
            end
        end

        task.wait()
    end
end

-- MOBILE TOGGLE
toggle.Activated:Connect(function()
    running = not running
    session = session + 1

    toggle.Text = running
        and "MACRO: ON"
        or "MACRO: OFF"

    toggle.BackgroundColor3 = running
        and Color3.fromRGB(30,170,70)
        or Color3.fromRGB(35,35,35)

    if running then
        local id = session

        task.spawn(function()
            local ok, err = pcall(macro,id)

            if not ok and session == id and gui.Parent then
                running = false
                toggle.Text = "MACRO: ERROR"
                toggle.BackgroundColor3 =
                    Color3.fromRGB(180,40,40)

                warn(err)
            end
        end)
    end
end)

print("Combat Macro Loaded")
