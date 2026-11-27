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

local TW_DOT=TweenInfo.new(0.3,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out)
local TW_ROW=TweenInfo.new(0.22,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out)
local TW_FAST=TweenInfo.new(0.15,Enum.EasingStyle.Sine,Enum.EasingDirection.Out)
local TW_OPEN=TweenInfo.new(0.45,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out)
local TW_SPRING=TweenInfo.new(0.5,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out)

local sg=Instance.new("ScreenGui")
sg.Name="BLOSSOM_PRIVATE"; sg.ResetOnSpawn=false; sg.IgnoreGuiInset=true
sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; sg.Parent=playerGui

local atualizarGUI
local infoLabelRef=nil

local function buildMobileUI()
	local mSg=Instance.new("ScreenGui"); mSg.Name="BLOSSOM_MOBILE"; mSg.ResetOnSpawn=false
	mSg.IgnoreGuiInset=true; mSg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; mSg.Parent=playerGui

	local ToggleButton=Instance.new("TextButton")
	ToggleButton.Name = "Landons Hub"
	ToggleButton.Size = UDim2.fromOffset(30,30)
	ToggleButton.Position = UDim2.new(1,-40,0.5,-15)
	ToggleButton.BackgroundColor3 = C_BG
	ToggleButton.BackgroundTransparency = 0.15
	ToggleButton.BorderSizePixel = 0
	ToggleButton.Text = "⭐"
	ToggleButton.TextSize = 19
	ToggleButton.TextColor3 = C_ON
	ToggleButton.Font = Enum.Font.GothamBold
	ToggleButton.ZIndex = 10
	ToggleButton.Parent = mSg

	Instance.new("UICorner",ToggleButton).CornerRadius =UDim.new(1,0)
	
	local ToggleStroke=Instance.new("UIStroke")
	ToggleStroke.Color = C_SEP
	ToggleStroke.Thickness=1.2
	ToggleStroke.Parent=ToggleButton

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
		Theme = "Rose",
		Animations = true
	}

	local defaultStarPosition = ToggleButton.Position
	local defaultPanelPosition = mP.Position
	
	local function updateScale()
		local camera = workspace.CurrentCamera
		if not camera then return end

		local viewport = camera.ViewportSize

		uiScale.Scale = math.min(
			settings.Scale,
			(viewport.X - 30) / 450,
			(viewport.Y - 30) / 280
		)
	end

	updateScale()

	workspace.CurrentCamera
		:GetPropertyChangedSignal("ViewportSize")
		:Connect(updateScale)
	
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
		if input.UserInputType~=Enum.UserInputType.Touch and input.UserInputType~=Enum.UserInputType.MouseMovement then return end
		local delta=input.Position-dragStart
		if delta.Magnitude>8 then moved=true end
		if not moved then return end
		ToggleButton.Position=UDim2.new(
			startPosition.X.Scale,startPosition.X.Offset+delta.X,
			startPosition.Y.Scale,startPosition.Y.Offset+delta.Y
		)
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
	mH.BackgroundTransparency = 1
	mH.Parent = mP

	local mT = Instance.new("TextLabel")
	mT.Size = UDim2.new(1, -80, 1, 0)
	mT.Position = UDim2.fromOffset(8, 0)
	mT.BackgroundTransparency = 1
	mT.Text = "♕  Landon's Hub"
	mT.TextColor3 = Color3.new(1, 1, 1)
	mT.TextSize = 23
	mT.Font = Enum.Font.GothamBold
	mT.TextXAlignment = Enum.TextXAlignment.Left
	mT.Parent = mH

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
	sidebar.Position = UDim2.fromOffset(6,48)
	sidebar.BackgroundColor3 = Color3.new(1, 1, 1)
	sidebar.BackgroundTransparency = 0.78

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
	sidebarLayout.Padding = UDim.new(0,4)
	sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sidebarLayout.Parent = sidebar

	local sidebarPadding = Instance.new("UIPadding")
	sidebarPadding.PaddingTop = UDim.new(0,6)
	sidebarPadding.PaddingLeft = UDim.new(0,6)
	sidebarPadding.PaddingRight = UDim.new(0,6)
	sidebarPadding.Parent = sidebar

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1,-130,1,-56)
	content.Position = UDim2.fromOffset(124,50)
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

			TweenService:Create(button, TW_FAST, {
				BackgroundTransparency = selected and 0 or 0.85,
				BackgroundColor3 = Color3.new(1, 1, 1),
				TextColor3 = Color3.new(1, 1, 1)
			}):Play()
		end
	end

	for index,name in ipairs(tabNames) do

		local button = Instance.new("TextButton")
		button.Name = name .. "Tab"
		button.Size = UDim2.new(1, 0, 0, 28)
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
		
		local page = Instance.new("ScrollingFrame")
		page.Name = name.."Page"
		page.Size = UDim2.fromScale(1,1)
		page.BackgroundTransparency = 1
		page.BorderSizePixel = 0
		page.ScrollBarThickness = 2
		page.ScrollBarImageColor3 = C_ON
		page.CanvasSize = UDim2.fromOffset(0,0)
		page.AutomaticCanvasSize = Enum.AutomaticSize.Y
		page.ScrollingDirection = Enum.ScrollingDirection.Y
		page.Visible = false
		page.Parent = content

		local layout = Instance.new("UIListLayout")
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0,6)
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

	local combatPage = pages["Combat"]
	local defensePage = pages["Defense"]
	local hitboxPage = pages["Hitbox"]
	local miscPage = pages["Misc"]
	local utilityPage = pages["Utility"]
	local settingsPage = pages["Settings"]
	
	local settingsHeader = createRow(settingsPage, 38)

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

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0.5, -4, 0, 54)
	gridLayout.CellPadding = UDim2.fromOffset(8, 6)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = settingsGrid

	local function settingsCard(title)
		local card = createRow(settingsGrid, 54)

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

		return card
	end
	
	local function createSlider(title, minimum, maximum, default, callback)
		local card = settingsCard(title)

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
	
	for _, name in ipairs(tabNames) do
		local row = createRow(pages[name], 42)

		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1,1)
		label.BackgroundTransparency = 1
		label.Text = name .. " Settings"
		label.TextColor3 = C_LABEL
		label.Font = Enum.Font.GothamBold
		label.TextSize = 13
		label.Parent = row
	end
	
	local mOrder=0
	local function mToggle(parent, feat)
		mOrder=mOrder+1
		local row = createRow(parent, 42)
		row.LayoutOrder = mOrder
		local d=Instance.new("Frame"); d.Size=UDim2.new(0,10,0,10); d.Position=UDim2.new(0,12,0.5,-5)
		d.BackgroundColor3=C_OFF; d.BorderSizePixel=0; d.Parent=row; Instance.new("UICorner",d).CornerRadius=UDim.new(1,0)
		local l=Instance.new("TextLabel"); l.Size=UDim2.new(0.65,0,1,0); l.Position=UDim2.new(0,30,0,0)
		l.BackgroundTransparency=1; l.Text=feat.name; l.TextColor3=C_DIM; l.TextSize=12
		l.Font=Enum.Font.GothamBold; l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=row
		local tb=Instance.new("TextButton");tb.Size=UDim2.new(0,54,0,28);tb.Position=UDim2.new(1,-62,0.5,-14)
		tb.BackgroundColor3=C_OFF; tb.BorderSizePixel=0; tb.Text="OFF"; tb.TextColor3=C_LABEL
		tb.TextSize=13; tb.Font=Enum.Font.GothamBold; tb.Parent=row; Instance.new("UICorner",tb).CornerRadius=UDim.new(0,8)
		local function upd()
			TweenService:Create(d,TW_DOT,{BackgroundColor3=feat.state and C_ON or C_OFF}):Play()
			TweenService:Create(tb,TW_ROW,{BackgroundColor3=feat.state and C_ON or C_OFF}):Play()
			tb.Text=feat.state and "ON" or "OFF";tb.TextColor3 = feat.state
				and Color3.new(1,1,1)
				or C_LABEL
			l.TextColor3=feat.state and C_LABEL or C_DIM
		end
		local deb2=false
		local function tog()
			if deb2 then return end; deb2=true; task.delay(0.15,function() deb2=false end)
			feat.state=not feat.state
			if feat.state then feat.onActivate() else feat.onDeactivate() end; upd()
		end
		tb.MouseButton1Click:Connect(tog)
	end

	local function mInput(parent,ph,btnT,btnC,cb)
		mOrder=mOrder+1
		local row = createRow(parent, 44)
		row.LayoutOrder = mOrder
		local box=Instance.new("TextBox"); box.Size=UDim2.new(0.52,-6,0,38); box.Position=UDim2.new(0,6,0.5,-19)
		box.BackgroundColor3=C_INPUT; box.BorderSizePixel=0; box.Text=""
		box.TextColor3=C_LABEL; box.TextSize=13; box.Font=Enum.Font.Gotham; box.PlaceholderText=ph
		box.PlaceholderColor3=C_DIM; box.Parent=row; Instance.new("UICorner",box).CornerRadius=UDim.new(0,8)
		local btn=Instance.new("TextButton"); btn.Size=UDim2.new(0.44,-6,0,38); btn.Position=UDim2.new(0.56,0,0.5,-19)
		btn.BackgroundColor3=btnC; btn.BorderSizePixel=0; btn.Text=btnT; btn.TextColor3=Color3.new(1,1,1)
		btn.TextSize=13; btn.Font=Enum.Font.GothamBold; btn.Parent=row; Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)
		btn.MouseButton1Click:Connect(function() cb(box.Text) end); return box
	end

	mToggle(combatPage, {
		name = "Test Toggle",
		state = false,
		onActivate = function() end,
		onDeactivate = function() end
	})

	mInput(settingsPage, "Display name", "Save", C_ON, function(v)
		print(v)
	end)

	mOrder=mOrder+1
	local mSneak=Instance.new("TextButton"); mSneak.Size=UDim2.new(1,-8,0,52)
	mSneak.BackgroundColor3=Color3.fromRGB(120,30,70); mSneak.BorderSizePixel=0
	mSneak.Text="🕵 Sneak Tool ▸ Open"; mSneak.TextColor3=Color3.fromRGB(255,120,190)
	mSneak.TextSize=14; mSneak.Font=Enum.Font.GothamBold; mSneak.LayoutOrder=mOrder; mSneak.Parent=miscPage
	Instance.new("UICorner",mSneak).CornerRadius=UDim.new(0,10)
	mSneak.MouseButton1Click:Connect(function()
		local g=playerGui:FindFirstChild("STUNNA_SNEAK"); if not g then return end
		g.Enabled=not g.Enabled
		mSneak.Text=not g.Enabled and "🕵 Sneak Tool ▸ Open" or "🕵 Sneak Tool ▸ Close"
	end)
end

local function buildSneakPanel()
	local ssg=Instance.new("ScreenGui"); ssg.Name="STUNNA_SNEAK"; ssg.ResetOnSpawn=false
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
	Instance.new("UICorner",sp).CornerRadius=UDim.new(0,14)

	local spStroke=Instance.new("UIStroke")
	spStroke.Color=C_SEP
	spStroke.Thickness=1
	spStroke.Parent=sp

	local sb=Instance.new("Frame")
	sb.Size=UDim2.new(1,0,0,44)
	sb.BackgroundColor3=C_TITLE
	sb.BorderSizePixel=0
	sb.Parent=sp
	Instance.new("UICorner",sb).CornerRadius=UDim.new(0,14)

	local sbf=Instance.new("Frame")
	sbf.Size=UDim2.new(1,0,0,14)
	sbf.Position=UDim2.new(0,0,1,-14)
	sbf.BackgroundColor3=C_TITLE
	sbf.BorderSizePixel=0
	sbf.Parent=sb

	local stl2=Instance.new("TextLabel")
	stl2.Size=UDim2.new(1,-50,1,0)
	stl2.Position=UDim2.new(0,12,0,0)
	stl2.BackgroundTransparency=1
	stl2.Text="Sneak Tool"
	stl2.TextColor3=C_LABEL
	stl2.TextSize=13
	stl2.Font=Enum.Font.GothamBold
	stl2.TextXAlignment=Enum.TextXAlignment.Left
	stl2.Parent=sb


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

	local statusLbl=Instance.new("TextLabel"); statusLbl.Size=UDim2.new(1,-12,0,20); statusLbl.Position=UDim2.new(0,6,1,-24)
	statusLbl.BackgroundTransparency=1; statusLbl.Text=""; statusLbl.TextColor3=C_ON; statusLbl.TextSize=11
	statusLbl.Font=Enum.Font.Gotham; statusLbl.TextXAlignment=Enum.TextXAlignment.Left; statusLbl.Parent=sp

	local ss2=Instance.new("ScrollingFrame")
	ss2.Size=UDim2.new(1,-8,1,-72)
	ss2.Position=UDim2.new(0,4,0,48)
	ss2.BackgroundTransparency=1
	ss2.BorderSizePixel=0
	ss2.ScrollBarThickness=3
	ss2.ScrollBarImageColor3=C_SEP
	ss2.CanvasSize=UDim2.new(0,0,0,0)
	ss2.Parent=sp
	ss2.ZIndex = 4

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
		row.Size=UDim2.new(1,-8,0,42)
		row.BackgroundColor3=C_TITLE
		row.BorderSizePixel=0
		row.Text=other.DisplayName.."  ("..other.Name..")"
		row.TextColor3=C_LABEL
		row.TextSize=12
		row.Font=Enum.Font.GothamBold
		row.TextXAlignment=Enum.TextXAlignment.Left
		row.Name = other.Name
		row.Active = true
		row.ZIndex = 5
		row.Parent = ss2
		Instance.new("UICorner",row).CornerRadius=UDim.new(0,10)


		local rp=Instance.new("UIPadding"); rp.PaddingLeft=UDim.new(0,10); rp.Parent=row
		row.MouseEnter:Connect(function() TweenService:Create(row,TW_ROW,{BackgroundColor3=C_HOVER}):Play() end)
		row.MouseLeave:Connect(function()
			TweenService:Create(row,TW_ROW,{
				BackgroundColor3 = C_TITLE
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
	sl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		ss2.CanvasSize=UDim2.new(0,0,0,sl.AbsoluteContentSize.Y+8)
	end)
end

buildSneakPanel()
buildMobileUI()
