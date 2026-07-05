--!strict
--[[
	================================================================
	  STEAL A BRAINROT — ALL-IN-ONE SPAWNER (REAL MODELS)
	================================================================
	ONE Script. Server-authoritative (everyone sees spawns) + a client
	menu drawn by the same file via a RunContext self-clone.

	This version uses your game's REAL Brainrot models & data when it can
	find them, instead of placeholder cubes / hardcoded values:

	  1) MODELS  — discovered from, in order:
	       • CollectionService tags  (MODEL_TAGS below)
	       • a Folder named one of  MODEL_FOLDER_NAMES  in ServerStorage
	       • the same in ReplicatedStorage
	     Each Brainrot Model is cloned on the SERVER so all players see it.

	  2) DATA (name / rarity / income / mutation) — discovered from:
	       • a ModuleScript named like DATA_MODULE_NAMES (require'd)   OR
	       • Attributes on each model (Rarity, Income/BaseIncome, Mutation)
	     Nothing is hardcoded unless discovery finds nothing, in which case
	     it falls back to a BUILT-IN roster + placeholder cubes (and warns).

	INSTALL: put this as a **Script** in ServerScriptService (RunContext =
	Legacy, the default) and press Play. Toggle the menu with RightControl.

	NOTE: Only reuse another game's models/data if you own them or have
	permission — each Roblox creator keeps the rights to their content.
	================================================================
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local REMOTE_EVENT_NAME = "BrainrotSpawnerRemote"
local REMOTE_FUNC_NAME = "BrainrotSpawnerInfo"

--################################################################
--#  CLIENT SIDE  (menu)                                          #
--################################################################
if not RunService:IsServer() then
	local player = Players.LocalPlayer
	while not player do
		task.wait()
		player = Players.LocalPlayer
	end
	local playerGui = player:WaitForChild("PlayerGui")

	local remoteEvent = ReplicatedStorage:WaitForChild(REMOTE_EVENT_NAME) :: RemoteEvent
	local remoteFunc = ReplicatedStorage:WaitForChild(REMOTE_FUNC_NAME) :: RemoteFunction

	local info = remoteFunc:InvokeServer()
	if not info or not info.CanUse then
		return
	end

	local rarities: { { Name: string, Color: Color3 } } = info.Rarities
	local currentInterval: number = info.Interval or 6
	local usingReal: boolean = info.UsingRealModels == true

	local ACCENT = Color3.fromRGB(120, 90, 255)
	local PANEL = Color3.fromRGB(28, 28, 36)
	local PANEL2 = Color3.fromRGB(40, 40, 52)

	local function corner(inst: Instance, radius: number)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, radius)
		c.Parent = inst
	end

	local function makeButton(parent: Instance, text: string, color: Color3): TextButton
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, 0, 0, 30)
		b.BackgroundColor3 = color
		b.AutoButtonColor = true
		b.Text = text
		b.Font = Enum.Font.GothamMedium
		b.TextSize = 14
		b.TextColor3 = Color3.fromRGB(240, 240, 240)
		b.BorderSizePixel = 0
		b.Parent = parent
		corner(b, 6)
		return b
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BrainrotSpawnerMenu"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	local window = Instance.new("Frame")
	window.Name = "Window"
	window.Size = UDim2.fromOffset(260, 410)
	window.Position = UDim2.fromOffset(30, 80)
	window.BackgroundColor3 = PANEL
	window.BorderSizePixel = 0
	window.Active = true
	window.Parent = screenGui
	corner(window, 10)

	local stroke = Instance.new("UIStroke")
	stroke.Color = ACCENT
	stroke.Thickness = 1.5
	stroke.Transparency = 0.3
	stroke.Parent = window

	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 36)
	titleBar.BackgroundColor3 = PANEL2
	titleBar.BorderSizePixel = 0
	titleBar.Parent = window
	corner(titleBar, 10)

	local titleText = Instance.new("TextLabel")
	titleText.BackgroundTransparency = 1
	titleText.Size = UDim2.new(1, -44, 1, 0)
	titleText.Position = UDim2.fromOffset(12, 0)
	titleText.Font = Enum.Font.GothamBold
	titleText.TextSize = 15
	titleText.TextColor3 = Color3.fromRGB(245, 245, 245)
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	titleText.Text = "🧠 Brainrot Spawner"
	titleText.Parent = titleBar

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.fromOffset(28, 28)
	closeBtn.Position = UDim2.new(1, -32, 0, 4)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 70)
	closeBtn.Text = "–"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 18
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.BorderSizePixel = 0
	closeBtn.Parent = titleBar
	corner(closeBtn, 6)

	local body = Instance.new("ScrollingFrame")
	body.Name = "Body"
	body.Size = UDim2.new(1, -16, 1, -44)
	body.Position = UDim2.fromOffset(8, 40)
	body.BackgroundTransparency = 1
	body.BorderSizePixel = 0
	body.ScrollBarThickness = 4
	body.CanvasSize = UDim2.new()
	body.AutomaticCanvasSize = Enum.AutomaticSize.Y
	body.Parent = window

	local uiLayout = Instance.new("UIListLayout")
	uiLayout.Padding = UDim.new(0, 6)
	uiLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiLayout.Parent = body

	local status = Instance.new("TextLabel")
	status.Size = UDim2.new(1, 0, 0, 46)
	status.BackgroundColor3 = PANEL2
	status.BorderSizePixel = 0
	status.Font = Enum.Font.Gotham
	status.TextSize = 12
	status.TextColor3 = Color3.fromRGB(200, 200, 210)
	status.TextWrapped = true
	status.Text = usingReal and "Using REAL game models. Spawns visible to everyone."
		or "Using placeholders (no real models found). Visible to everyone."
	status.Parent = body
	corner(status, 6)

	local function setStatus(text: string)
		status.Text = text
	end

	local spawnBtn = makeButton(body, "🎲  Spawn Random", ACCENT)
	spawnBtn.Activated:Connect(function()
		remoteEvent:FireServer("spawnRandom")
		setStatus("Requested a random brainrot.")
	end)

	local rarityHeader = Instance.new("TextLabel")
	rarityHeader.Size = UDim2.new(1, 0, 0, 20)
	rarityHeader.BackgroundTransparency = 1
	rarityHeader.Font = Enum.Font.GothamBold
	rarityHeader.TextSize = 12
	rarityHeader.TextXAlignment = Enum.TextXAlignment.Left
	rarityHeader.TextColor3 = Color3.fromRGB(160, 160, 175)
	rarityHeader.Text = "SPAWN BY RARITY"
	rarityHeader.Parent = body

	for _, r in ipairs(rarities) do
		local btn = makeButton(body, r.Name, r.Color)
		if r.Color.R + r.Color.G + r.Color.B > 1.6 then
			btn.TextColor3 = Color3.fromRGB(20, 20, 20)
		end
		btn.Activated:Connect(function()
			remoteEvent:FireServer("spawnRarity", r.Name)
			setStatus("Requested a " .. r.Name .. " brainrot.")
		end)
	end

	local autoOn = false
	local autoBtn = makeButton(body, "▶  Auto Spawn: OFF", PANEL2)
	autoBtn.Activated:Connect(function()
		autoOn = not autoOn
		autoBtn.Text = autoOn and "⏸  Auto Spawn: ON" or "▶  Auto Spawn: OFF"
		autoBtn.BackgroundColor3 = autoOn and Color3.fromRGB(60, 160, 90) or PANEL2
		remoteEvent:FireServer("toggleAuto")
	end)

	local intervalRow = Instance.new("Frame")
	intervalRow.Size = UDim2.new(1, 0, 0, 30)
	intervalRow.BackgroundTransparency = 1
	intervalRow.Parent = body

	local intervalLayout = Instance.new("UIListLayout")
	intervalLayout.FillDirection = Enum.FillDirection.Horizontal
	intervalLayout.Padding = UDim.new(0, 6)
	intervalLayout.Parent = intervalRow

	local minusBtn = Instance.new("TextButton")
	minusBtn.Size = UDim2.new(0, 40, 1, 0)
	minusBtn.BackgroundColor3 = PANEL2
	minusBtn.Text = "-"
	minusBtn.Font = Enum.Font.GothamBold
	minusBtn.TextSize = 18
	minusBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
	minusBtn.BorderSizePixel = 0
	minusBtn.Parent = intervalRow
	corner(minusBtn, 6)

	local intervalLabel = Instance.new("TextLabel")
	intervalLabel.Size = UDim2.new(1, -92, 1, 0)
	intervalLabel.BackgroundColor3 = PANEL2
	intervalLabel.Font = Enum.Font.GothamMedium
	intervalLabel.TextSize = 13
	intervalLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
	intervalLabel.Text = string.format("Interval: %ds", currentInterval)
	intervalLabel.BorderSizePixel = 0
	intervalLabel.Parent = intervalRow
	corner(intervalLabel, 6)

	local plusBtn = Instance.new("TextButton")
	plusBtn.Size = UDim2.new(0, 40, 1, 0)
	plusBtn.BackgroundColor3 = PANEL2
	plusBtn.Text = "+"
	plusBtn.Font = Enum.Font.GothamBold
	plusBtn.TextSize = 18
	plusBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
	plusBtn.BorderSizePixel = 0
	plusBtn.Parent = intervalRow
	corner(plusBtn, 6)

	local function pushInterval()
		intervalLabel.Text = string.format("Interval: %ds", currentInterval)
		remoteEvent:FireServer("setInterval", currentInterval)
	end
	minusBtn.Activated:Connect(function()
		currentInterval = math.max(1, currentInterval - 1)
		pushInterval()
	end)
	plusBtn.Activated:Connect(function()
		currentInterval = math.min(60, currentInterval + 1)
		pushInterval()
	end)

	local clearBtn = makeButton(body, "🗑  Clear All", Color3.fromRGB(200, 60, 70))
	clearBtn.Activated:Connect(function()
		remoteEvent:FireServer("clear")
		setStatus("Cleared all brainrots.")
	end)

	do
		local dragging = false
		local dragStart: Vector2 = Vector2.zero
		local startPos: UDim2 = window.Position

		titleBar.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = window.Position
			end
		end)

		UserInputService.InputChanged:Connect(function(input: InputObject)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				window.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y
				)
			end
		end)

		UserInputService.InputEnded:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
	end

	local isOpen = true
	local function setOpen(open: boolean)
		isOpen = open
		body.Visible = open
		window.Size = open and UDim2.fromOffset(260, 410) or UDim2.fromOffset(260, 36)
		closeBtn.Text = open and "–" or "+"
	end
	closeBtn.Activated:Connect(function()
		setOpen(not isOpen)
	end)
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.RightControl then
			setOpen(not isOpen)
		end
	end)

	print("[BrainrotSpawner] Menu loaded (client). Toggle with RightControl.")
	return
end

--################################################################
--#  SERVER SIDE  (discovery + real-model spawner)               #
--################################################################

local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

-- ACCESS CONTROL --------------------------------------------------
local ALLOW_EVERYONE = true
local ADMINS: { [number]: boolean } = {
	-- [123456789] = true,
}

local function canUse(player: Player): boolean
	if ALLOW_EVERYONE then return true end
	if ADMINS[player.UserId] then return true end
	if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
		return true
	end
	return false
end

-- DISCOVERY SETTINGS ---------------------------------------------
-- Where/how to find your REAL brainrot assets. Tweak to match your game.
local MODEL_TAGS = { "Brainrot", "BrainrotModel", "Brainrots" }        -- CollectionService tags
local MODEL_FOLDER_NAMES = { "Brainrots", "BrainrotModels", "Brainrot" } -- Folder/Model container names
local DATA_MODULE_NAMES = { "BrainrotData", "BrainrotConfig", "Brainrots", "BrainrotList" }
-- Attribute names to read off a model (first match wins).
local INCOME_ATTRS = { "Income", "BaseIncome", "Cash", "Money", "Value" }
local RARITY_ATTRS = { "Rarity", "Tier" }
local MUTATION_ATTRS = { "Mutation", "Trait" }

-- CONFIG ----------------------------------------------------------
local Config = {
	AutoSpawnInterval = 6,
	MaxActive = 25,
	Lifetime = 30,
	ConveyorSpeed = 8,
	AnchorClones = true, -- anchor cloned parts so the conveyor can move them reliably
}

type Rarity = { Name: string, Weight: number, Color: Color3, IncomeMultiplier: number }
type Mutation = { Name: string, Chance: number, IncomeMultiplier: number }
type Brainrot = { Name: string, Rarity: string, BaseIncome: number, Model: string? }

-- Fallback rarities (used if no rarity module is found; discovered rarities
-- not listed here are auto-added with a default color/weight).
local BUILTIN_RARITIES: { Rarity } = {
	{ Name = "Common",       Weight = 1000, Color = Color3.fromRGB(180, 180, 180), IncomeMultiplier = 1 },
	{ Name = "Rare",         Weight = 450,  Color = Color3.fromRGB(80, 160, 255),  IncomeMultiplier = 2 },
	{ Name = "Epic",         Weight = 180,  Color = Color3.fromRGB(170, 90, 255),  IncomeMultiplier = 4 },
	{ Name = "Legendary",    Weight = 60,   Color = Color3.fromRGB(255, 190, 40),  IncomeMultiplier = 9 },
	{ Name = "Mythic",       Weight = 18,   Color = Color3.fromRGB(255, 70, 90),   IncomeMultiplier = 20 },
	{ Name = "Brainrot God", Weight = 4,    Color = Color3.fromRGB(0, 255, 200),   IncomeMultiplier = 50 },
	{ Name = "Secret",       Weight = 1,    Color = Color3.fromRGB(20, 20, 20),    IncomeMultiplier = 150 },
	{ Name = "OG",           Weight = 0.3,  Color = Color3.fromRGB(255, 120, 200), IncomeMultiplier = 500 },
}

local MUTATIONS: { Mutation } = {
	{ Name = "Rainbow", Chance = 0.005, IncomeMultiplier = 10 },
	{ Name = "Diamond", Chance = 0.02,  IncomeMultiplier = 5 },
	{ Name = "Gold",    Chance = 0.06,  IncomeMultiplier = 2.5 },
}

-- Last-resort roster if NO data and NO models are discovered anywhere.
local BUILTIN_ROSTER: { Brainrot } = {
	-- Common
	{ Name = "Noobini Pizzanini", Rarity = "Common", BaseIncome = 3 },
	{ Name = "Lirili Larila", Rarity = "Common", BaseIncome = 3 },
	{ Name = "Tim Cheese", Rarity = "Common", BaseIncome = 3 },
	{ Name = "FluriFlura", Rarity = "Common", BaseIncome = 3 },
	{ Name = "Talpa Di Fero", Rarity = "Common", BaseIncome = 3 },
	{ Name = "Svinina Bombardino", Rarity = "Common", BaseIncome = 3 },
	{ Name = "Pipi Kiwi", Rarity = "Common", BaseIncome = 3 },
	{ Name = "Racooni Jandelini", Rarity = "Common", BaseIncome = 3 },
	{ Name = "Pipi Corni", Rarity = "Common", BaseIncome = 3 },
	{ Name = "Noobini Santanini", Rarity = "Common", BaseIncome = 3 },
	-- Rare
	{ Name = "Trippi Troppi", Rarity = "Rare", BaseIncome = 10 },
	{ Name = "Gangster Footera", Rarity = "Rare", BaseIncome = 10 },
	{ Name = "Bandito Bobritto", Rarity = "Rare", BaseIncome = 10 },
	{ Name = "Boneca Ambalabu", Rarity = "Rare", BaseIncome = 10 },
	{ Name = "Cacto Hipopotamo", Rarity = "Rare", BaseIncome = 10 },
	{ Name = "Ta Ta Ta Ta Sahur", Rarity = "Rare", BaseIncome = 10 },
	{ Name = "Tric Trac Baraboom", Rarity = "Rare", BaseIncome = 10 },
	{ Name = "Pipi Avocado", Rarity = "Rare", BaseIncome = 10 },
	{ Name = "Frogo Elfo", Rarity = "Rare", BaseIncome = 10 },
	{ Name = "Tartaragno", Rarity = "Rare", BaseIncome = 10 },
	{ Name = "Cupcake Koala", Rarity = "Rare", BaseIncome = 10 },
	{ Name = "Pinealotto Fruttarino", Rarity = "Rare", BaseIncome = 10 },
	-- Epic
	{ Name = "Cappuccino Assassino", Rarity = "Epic", BaseIncome = 30 },
	{ Name = "Brr Brr Patapim", Rarity = "Epic", BaseIncome = 30 },
	{ Name = "Trulimero Trulicina", Rarity = "Epic", BaseIncome = 30 },
	{ Name = "Bambini Crostini", Rarity = "Epic", BaseIncome = 30 },
	{ Name = "Bananita Dolphinita", Rarity = "Epic", BaseIncome = 30 },
	{ Name = "Perochello Lemonchello", Rarity = "Epic", BaseIncome = 30 },
	{ Name = "Brri Brri Bicus Dicus Bombicus", Rarity = "Epic", BaseIncome = 30 },
	{ Name = "Avocadini Guffo", Rarity = "Epic", BaseIncome = 30 },
	{ Name = "Salamino Penguino", Rarity = "Epic", BaseIncome = 30 },
	{ Name = "Ti Ti Ti Sahur", Rarity = "Epic", BaseIncome = 30 },
	{ Name = "Penguin Tree", Rarity = "Epic", BaseIncome = 30 },
	{ Name = "Penguino Cocosino", Rarity = "Epic", BaseIncome = 30 },
	{ Name = "Avocadini Antilopini", Rarity = "Epic", BaseIncome = 30 },
	-- Legendary
	{ Name = "Burbaloni Loliloli", Rarity = "Legendary", BaseIncome = 90 },
	{ Name = "Chimpazini Bananini", Rarity = "Legendary", BaseIncome = 90 },
	{ Name = "Ballerina Cappuccina", Rarity = "Legendary", BaseIncome = 90 },
	{ Name = "Chef Crabracadabra", Rarity = "Legendary", BaseIncome = 90 },
	{ Name = "Lionel Cactuseli", Rarity = "Legendary", BaseIncome = 90 },
	{ Name = "Glorbo Fruttodrillo", Rarity = "Legendary", BaseIncome = 90 },
	{ Name = "Blueberrinni Octopusini", Rarity = "Legendary", BaseIncome = 90 },
	{ Name = "Strawberrelli Flamingelli", Rarity = "Legendary", BaseIncome = 90 },
	{ Name = "Pandaccini Bananini", Rarity = "Legendary", BaseIncome = 90 },
	{ Name = "Sigma Boy", Rarity = "Legendary", BaseIncome = 90 },
	{ Name = "Pi Pi Watermelon", Rarity = "Legendary", BaseIncome = 90 },
	{ Name = "Sigma Girl", Rarity = "Legendary", BaseIncome = 90 },
	{ Name = "Chocco Bunny", Rarity = "Legendary", BaseIncome = 90 },
	{ Name = "Sealo Regalo", Rarity = "Legendary", BaseIncome = 90 },
	{ Name = "Signore Carapace", Rarity = "Legendary", BaseIncome = 90 },
	-- Mythic
	{ Name = "Frigo Camelo", Rarity = "Mythic", BaseIncome = 280 },
	{ Name = "Orangutini Ananassini", Rarity = "Mythic", BaseIncome = 280 },
	{ Name = "Rhino Toasterino", Rarity = "Mythic", BaseIncome = 280 },
	{ Name = "Bombardiro Crocodilo", Rarity = "Mythic", BaseIncome = 280 },
	{ Name = "Bombombini Gusini", Rarity = "Mythic", BaseIncome = 280 },
	{ Name = "Cavallo Virtuoso", Rarity = "Mythic", BaseIncome = 280 },
	{ Name = "Gorillo Watermelondrillo", Rarity = "Mythic", BaseIncome = 280 },
	{ Name = "Lerulerulerule", Rarity = "Mythic", BaseIncome = 280 },
	{ Name = "Te Te Te Sahur", Rarity = "Mythic", BaseIncome = 280 },
	{ Name = "Tracoducotulu Delapeladustuz", Rarity = "Mythic", BaseIncome = 280 },
	{ Name = "Cachorrito Melonito", Rarity = "Mythic", BaseIncome = 280 },
	{ Name = "Toiletto Focaccino", Rarity = "Mythic", BaseIncome = 280 },
	{ Name = "Elefanto Frigo", Rarity = "Mythic", BaseIncome = 280 },
	{ Name = "Ganganzelli Trulala", Rarity = "Mythic", BaseIncome = 280 },
	{ Name = "Jingle Jingle Sahur", Rarity = "Mythic", BaseIncome = 280 },
	{ Name = "Tree Tree Tree Sahur", Rarity = "Mythic", BaseIncome = 280 },
	{ Name = "Bananito Bandito", Rarity = "Mythic", BaseIncome = 280 },
	{ Name = "Carrotini Brainini", Rarity = "Mythic", BaseIncome = 280 },
	{ Name = "Spioniro Golubiro", Rarity = "Mythic", BaseIncome = 280 },
	{ Name = "Tigrilini Watermelini", Rarity = "Mythic", BaseIncome = 280 },
	-- Brainrot God
	{ Name = "Cocofanto Elefanto", Rarity = "Brainrot God", BaseIncome = 1000 },
	{ Name = "Girafa Celestre", Rarity = "Brainrot God", BaseIncome = 1000 },
	{ Name = "Gattatino Nyanino", Rarity = "Brainrot God", BaseIncome = 1000 },
	{ Name = "Chihuanini Taconini", Rarity = "Brainrot God", BaseIncome = 1000 },
	{ Name = "Matteo", Rarity = "Brainrot God", BaseIncome = 1000 },
	{ Name = "Tralalero Tralala", Rarity = "Brainrot God", BaseIncome = 1000 },
	{ Name = "Espresso Signora", Rarity = "Brainrot God", BaseIncome = 1000 },
	{ Name = "Odin Din Din Dun", Rarity = "Brainrot God", BaseIncome = 1000 },
	{ Name = "Statutino Libertino", Rarity = "Brainrot God", BaseIncome = 1000 },
	{ Name = "Trenostruzzo Turbo 3000", Rarity = "Brainrot God", BaseIncome = 1000 },
	{ Name = "Ballerino Lololo", Rarity = "Brainrot God", BaseIncome = 1000 },
	{ Name = "Los Orcalitos", Rarity = "Brainrot God", BaseIncome = 1000 },
	{ Name = "Dug dug dug", Rarity = "Brainrot God", BaseIncome = 1000 },
	{ Name = "Urubini Flamenguini", Rarity = "Brainrot God", BaseIncome = 1000 },
	{ Name = "Capi Taco", Rarity = "Brainrot God", BaseIncome = 1000 },
	{ Name = "Bombardini Tortinii", Rarity = "Brainrot God", BaseIncome = 1000 },
	{ Name = "Corn Corn Corn Sahur", Rarity = "Brainrot God", BaseIncome = 1000 },
	{ Name = "Ginger Globo", Rarity = "Brainrot God", BaseIncome = 1000 },
	{ Name = "Frio Ninja", Rarity = "Brainrot God", BaseIncome = 1000 },
	{ Name = "Ginger Cisterna", Rarity = "Brainrot God", BaseIncome = 1000 },
	-- Secret
	{ Name = "Las Sis", Rarity = "Secret", BaseIncome = 5000 },
	{ Name = "La Vacca Staturno Saturnita", Rarity = "Secret", BaseIncome = 5000 },
	{ Name = "Chimpanzini Spiderini", Rarity = "Secret", BaseIncome = 5000 },
	{ Name = "Extinct Tralalero", Rarity = "Secret", BaseIncome = 5000 },
	{ Name = "Extinct Matteo", Rarity = "Secret", BaseIncome = 5000 },
	{ Name = "Los Tralaleritos", Rarity = "Secret", BaseIncome = 5000 },
	{ Name = "La Karkerkar Combinasion", Rarity = "Secret", BaseIncome = 5000 },
	{ Name = "Karker Sahur", Rarity = "Secret", BaseIncome = 5000 },
	{ Name = "Las Tralaleritas", Rarity = "Secret", BaseIncome = 5000 },
	{ Name = "Job Job Job Sahur", Rarity = "Secret", BaseIncome = 5000 },
	{ Name = "Graipuss Medussi", Rarity = "Secret", BaseIncome = 5000 },
	{ Name = "La Grande Combinasion", Rarity = "Secret", BaseIncome = 5000 },
	{ Name = "Tacorita Bicicleta", Rarity = "Secret", BaseIncome = 5000 },
	{ Name = "Nuclearo Dinossauro", Rarity = "Secret", BaseIncome = 5000 },
	{ Name = "Money Money Puggy", Rarity = "Secret", BaseIncome = 5000 },
	{ Name = "Chillin Chili", Rarity = "Secret", BaseIncome = 5000 },
	{ Name = "Los Tacoritas", Rarity = "Secret", BaseIncome = 5000 },
	{ Name = "Tang Tang Kelentang", Rarity = "Secret", BaseIncome = 5000 },
	{ Name = "Dragon Cannelloni", Rarity = "Secret", BaseIncome = 5000 },
	{ Name = "Blackhole Goat", Rarity = "Secret", BaseIncome = 5000 },
	-- OG
	{ Name = "Strawberry Elephant", Rarity = "OG", BaseIncome = 25000 },
	{ Name = "Meowl", Rarity = "OG", BaseIncome = 25000 },
	{ Name = "Skibidi Toilet", Rarity = "OG", BaseIncome = 25000 },
}

--==============================================================--
--  DISCOVERY  (find real models + data; no hardcoding required)
--==============================================================--
local SEARCH_ROOTS = { ServerStorage, ReplicatedStorage }

local function firstAttr(inst: Instance, names: { string }): any
	for _, n in ipairs(names) do
		local v = inst:GetAttribute(n)
		if v ~= nil then return v end
	end
	return nil
end

-- Read a numeric value from an attribute or a child *Value object.
local function readNumber(inst: Instance, names: { string }): number?
	local a = firstAttr(inst, names)
	if typeof(a) == "number" then return a end
	for _, n in ipairs(names) do
		local child = inst:FindFirstChild(n)
		if child and (child:IsA("NumberValue") or child:IsA("IntValue")) then
			return child.Value
		end
	end
	return nil
end

local function readString(inst: Instance, names: { string }): string?
	local a = firstAttr(inst, names)
	if typeof(a) == "string" then return a end
	for _, n in ipairs(names) do
		local child = inst:FindFirstChild(n)
		if child and child:IsA("StringValue") then
			return child.Value
		end
	end
	return nil
end

-- 1) Collect real model templates by name.
local modelTemplates: { [string]: Model } = {}

local function considerModel(m: Instance)
	if m:IsA("Model") and not modelTemplates[m.Name] then
		modelTemplates[m.Name] = m
	end
end

local function discoverModels()
	-- Tagged models.
	for _, tag in ipairs(MODEL_TAGS) do
		for _, m in ipairs(CollectionService:GetTagged(tag)) do
			if m:IsDescendantOf(game) then
				considerModel(m)
			end
		end
	end
	-- Named container folders.
	for _, root in ipairs(SEARCH_ROOTS) do
		for _, folderName in ipairs(MODEL_FOLDER_NAMES) do
			local folder = root:FindFirstChild(folderName)
			if folder then
				for _, m in ipairs(folder:GetChildren()) do
					considerModel(m)
				end
			end
		end
	end
end

-- 2) Discover a data table via a ModuleScript, else derive from model attributes.
type Roll = { Brainrot: Brainrot, Rarity: Rarity, Mutation: Mutation?, Income: number, Template: Model? }

local dataEntries: { Brainrot } = {}
local usingRealData = false

local function normalizeEntry(raw: any): Brainrot?
	if typeof(raw) ~= "table" then return nil end
	local name = raw.Name or raw.name
	if typeof(name) ~= "string" then return nil end
	local rarity = raw.Rarity or raw.rarity or raw.Tier or "Common"
	local income = raw.BaseIncome or raw.Income or raw.income or raw.Cash or 1
	if typeof(income) ~= "number" then income = tonumber(income) or 1 end
	return {
		Name = name,
		Rarity = typeof(rarity) == "string" and rarity or "Common",
		BaseIncome = income,
		Model = typeof(raw.Model) == "string" and raw.Model or nil,
	}
end

local function tryRequireDataModule(): boolean
	for _, root in ipairs(SEARCH_ROOTS) do
		for _, obj in ipairs(root:GetDescendants()) do
			if obj:IsA("ModuleScript") then
				local matches = false
				for _, wanted in ipairs(DATA_MODULE_NAMES) do
					if obj.Name == wanted then matches = true break end
				end
				if matches then
					local ok, result = pcall(require, obj)
					if ok and typeof(result) == "table" then
						-- Accept an array of entries or a dict keyed by name.
						local added = 0
						for k, v in pairs(result) do
							local entry = normalizeEntry(v)
							if entry then
								if typeof(k) == "string" and (not entry.Name or entry.Name == "") then
									entry.Name = k
								end
								table.insert(dataEntries, entry)
								added += 1
							end
						end
						if added > 0 then
							print(("[BrainrotSpawner] Loaded %d entries from data module '%s'."):format(added, obj:GetFullName()))
							return true
						end
					elseif not ok then
						warn("[BrainrotSpawner] Failed to require data module:", obj:GetFullName(), result)
					end
				end
			end
		end
	end
	return false
end

local function deriveDataFromModels()
	for name, model in pairs(modelTemplates) do
		local rarity = readString(model, RARITY_ATTRS) or "Common"
		local income = readNumber(model, INCOME_ATTRS) or 1
		table.insert(dataEntries, {
			Name = name,
			Rarity = rarity,
			BaseIncome = income,
			Model = name,
		})
	end
end

-- Run discovery.
discoverModels()
if tryRequireDataModule() then
	usingRealData = true
elseif next(modelTemplates) ~= nil then
	deriveDataFromModels()
	usingRealData = true
else
	dataEntries = BUILTIN_ROSTER
	warn("[BrainrotSpawner] No real models/data found — using built-in roster + placeholder cubes.")
end

local usingRealModels = next(modelTemplates) ~= nil

-- 3) Build the rarity set: builtin rarities + any extra discovered rarities.
local RARITIES: { Rarity } = {}
local rarityByName: { [string]: Rarity } = {}
for _, r in ipairs(BUILTIN_RARITIES) do
	table.insert(RARITIES, r)
	rarityByName[r.Name] = r
end
local extraColors = {
	Color3.fromRGB(120, 220, 120), Color3.fromRGB(220, 120, 120),
	Color3.fromRGB(120, 120, 220), Color3.fromRGB(220, 200, 120),
}
local extraIdx = 0
for _, entry in ipairs(dataEntries) do
	if not rarityByName[entry.Rarity] then
		extraIdx += 1
		local color = extraColors[((extraIdx - 1) % #extraColors) + 1]
		local r: Rarity = { Name = entry.Rarity, Weight = 25, Color = color, IncomeMultiplier = 1 }
		rarityByName[entry.Rarity] = r
		table.insert(RARITIES, r)
	end
end

--==============================================================--
--  ROLLER
--==============================================================--
local rng = Random.new()

local function getRarity(name: string): Rarity?
	return rarityByName[name]
end

local function totalWeightFor(pool: { Brainrot }): number
	local t = 0
	for _, b in ipairs(pool) do
		local r = rarityByName[b.Rarity]
		t += (r and r.Weight or 25)
	end
	return t
end

local function entriesOfRarity(name: string): { Brainrot }
	local out = {}
	for _, b in ipairs(dataEntries) do
		if b.Rarity == name then table.insert(out, b) end
	end
	return out
end

local function pickMutation(): Mutation?
	for _, m in ipairs(MUTATIONS) do
		if rng:NextNumber() <= m.Chance then return m end
	end
	return nil
end

-- Weighted pick across all entries (by their rarity weight).
local function pickWeightedEntry(pool: { Brainrot }): Brainrot?
	if #pool == 0 then return nil end
	local total = totalWeightFor(pool)
	if total <= 0 then return pool[rng:NextInteger(1, #pool)] end
	local roll = rng:NextNumber(0, total)
	local cum = 0
	for _, b in ipairs(pool) do
		local r = rarityByName[b.Rarity]
		cum += (r and r.Weight or 25)
		if roll <= cum then return b end
	end
	return pool[#pool]
end

local function roll(forceRarity: string?): Roll?
	local pool: { Brainrot }
	if forceRarity then
		pool = entriesOfRarity(forceRarity)
		if #pool == 0 then pool = dataEntries end
	else
		pool = dataEntries
	end

	local entry = pickWeightedEntry(pool)
	if not entry then return nil end

	local rarity = rarityByName[entry.Rarity] or BUILTIN_RARITIES[1]
	local mutation = pickMutation()

	local income = entry.BaseIncome * rarity.IncomeMultiplier
	if mutation then income *= mutation.IncomeMultiplier end

	local template = modelTemplates[entry.Model or entry.Name]

	return {
		Brainrot = entry,
		Rarity = rarity,
		Mutation = mutation,
		Income = math.floor(income + 0.5),
		Template = template,
	}
end

--==============================================================--
--  CONVEYOR + WORLD
--==============================================================--
local function buildDefaultConveyor(): Model
	local model = Instance.new("Model")
	model.Name = "Conveyor"

	local belt = Instance.new("Part")
	belt.Name = "Belt"
	belt.Anchored = true
	belt.Size = Vector3.new(6, 1, 80)
	belt.Position = Vector3.new(0, 3, 0)
	belt.Color = Color3.fromRGB(45, 45, 55)
	belt.Material = Enum.Material.Metal
	belt.Parent = model

	local startPart = Instance.new("Part")
	startPart.Name = "Start"
	startPart.Anchored = true
	startPart.Transparency = 1
	startPart.CanCollide = false
	startPart.Size = Vector3.new(6, 1, 1)
	startPart.Position = belt.Position + Vector3.new(0, 1, -belt.Size.Z / 2)
	startPart.Parent = model

	local endPart = Instance.new("Part")
	endPart.Name = "End"
	endPart.Anchored = true
	endPart.Transparency = 1
	endPart.CanCollide = false
	endPart.Size = Vector3.new(6, 1, 1)
	endPart.Position = belt.Position + Vector3.new(0, 1, belt.Size.Z / 2)
	endPart.Parent = model

	model.Parent = Workspace
	return model
end

local function getConveyor(): (BasePart, BasePart)
	local conveyor = Workspace:FindFirstChild("Conveyor")
	if not conveyor then conveyor = buildDefaultConveyor() end
	local s = conveyor:FindFirstChild("Start")
	local e = conveyor:FindFirstChild("End")
	if not (s and s:IsA("BasePart") and e and e:IsA("BasePart")) then
		conveyor:Destroy()
		conveyor = buildDefaultConveyor()
		s = conveyor:FindFirstChild("Start")
		e = conveyor:FindFirstChild("End")
	end
	return s :: BasePart, e :: BasePart
end

local START_PART, END_PART = getConveyor()

local activeFolder = Workspace:FindFirstChild("ActiveBrainrots")
if not activeFolder then
	activeFolder = Instance.new("Folder")
	activeFolder.Name = "ActiveBrainrots"
	activeFolder.Parent = Workspace
end

--==============================================================--
--  MODEL BUILD  (clone real model, else placeholder)
--==============================================================--
local function buildPlaceholder(r: Roll): Model
	local model = Instance.new("Model")
	local bodyPart = Instance.new("Part")
	bodyPart.Name = "Body"
	bodyPart.Anchored = true
	bodyPart.CanCollide = false
	bodyPart.Size = Vector3.new(3, 3, 3)
	bodyPart.Material = Enum.Material.SmoothPlastic
	bodyPart.Color = r.Rarity.Color
	bodyPart.Parent = model
	model.PrimaryPart = bodyPart

	local light = Instance.new("PointLight")
	light.Color = r.Rarity.Color
	light.Range = 10
	light.Brightness = 2
	light.Parent = bodyPart
	return model
end

local function cloneReal(template: Model): Model?
	local wasArchivable = template.Archivable
	if not wasArchivable then template.Archivable = true end
	local ok, clone = pcall(function()
		return template:Clone()
	end)
	if not wasArchivable then template.Archivable = wasArchivable end
	if ok and clone then
		return clone
	end
	warn("[BrainrotSpawner] Could not clone model:", template:GetFullName())
	return nil
end

local function addInfoBillboard(model: Model, r: Roll)
	local head = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not head then return end
	if model:FindFirstChild("SpawnerInfo", true) then return end

	local gui = Instance.new("BillboardGui")
	gui.Name = "SpawnerInfo"
	gui.Size = UDim2.fromScale(6, 2)
	gui.StudsOffset = Vector3.new(0, 4, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 120
	gui.Adornee = head

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(1, 0.5)
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = r.Rarity.Color
	title.TextStrokeTransparency = 0.4
	title.Text = (r.Mutation and (r.Mutation.Name .. " ") or "") .. r.Brainrot.Name
	title.Parent = gui

	local subtitle = Instance.new("TextLabel")
	subtitle.BackgroundTransparency = 1
	subtitle.Size = UDim2.fromScale(1, 0.5)
	subtitle.Position = UDim2.fromScale(0, 0.5)
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextScaled = true
	subtitle.TextColor3 = Color3.fromRGB(235, 235, 235)
	subtitle.TextStrokeTransparency = 0.5
	subtitle.Text = string.format("%s  •  $%d/s", r.Rarity.Name, r.Income)
	subtitle.Parent = gui

	gui.Parent = head
end

local function anchorAll(model: Model)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
end

--==============================================================--
--  SPAWN
--==============================================================--
local function spawnBrainrot(forceRarity: string?): Roll?
	if #activeFolder:GetChildren() >= Config.MaxActive then return nil end
	local r = roll(forceRarity)
	if not r then return nil end

	local model: Model?
	if r.Template then
		model = cloneReal(r.Template)
	end
	local isReal = model ~= nil
	if not model then
		model = buildPlaceholder(r)
	end
	assert(model)

	model.Name = r.Brainrot.Name
	if Config.AnchorClones then
		anchorAll(model)
	end

	-- Prefer the real model's own income attribute if present, else our computed value.
	local realIncome = readNumber(model, INCOME_ATTRS)
	local income = r.Income
	if isReal and realIncome then
		income = realIncome
		if r.Mutation then income = math.floor(income * r.Mutation.IncomeMultiplier + 0.5) end
	end

	model:SetAttribute("BrainrotName", r.Brainrot.Name)
	model:SetAttribute("Rarity", r.Rarity.Name)
	model:SetAttribute("Mutation", r.Mutation and r.Mutation.Name or "None")
	model:SetAttribute("Income", income)
	model:SetAttribute("Claimed", false)
	model:SetAttribute("SpawnClock", os.clock())

	addInfoBillboard(model, r)
	model:PivotTo(CFrame.new(START_PART.Position))
	model.Parent = activeFolder
	Debris:AddItem(model, Config.Lifetime + 5) -- safety net
	return r
end

local function clearAll()
	for _, child in ipairs(activeFolder:GetChildren()) do
		child:Destroy()
	end
end

--==============================================================--
--  CENTRAL CONVEYOR LOOP  (one Heartbeat moves every active model)
--==============================================================--
RunService.Heartbeat:Connect(function()
	local startPos = START_PART.Position
	local endPos = END_PART.Position
	local distance = (endPos - startPos).Magnitude
	local speed = math.max(Config.ConveyorSpeed, 0.1)
	local travelTime = distance / speed
	local now = os.clock()

	for _, model in ipairs(activeFolder:GetChildren()) do
		if model:IsA("Model") then
			if model:GetAttribute("Claimed") == true then
				continue
			end
			local spawnClock = model:GetAttribute("SpawnClock")
			if typeof(spawnClock) ~= "number" then
				model:SetAttribute("SpawnClock", now)
				spawnClock = now
			end
			local alpha = math.clamp((now - spawnClock) / travelTime, 0, 1)
			model:PivotTo(CFrame.new(startPos:Lerp(endPos, alpha)))
			if alpha >= 1 then
				model:Destroy()
			end
		end
	end
end)

--==============================================================--
--  REMOTES
--==============================================================--
local remoteEvent = ReplicatedStorage:FindFirstChild(REMOTE_EVENT_NAME) :: RemoteEvent?
if not remoteEvent then
	remoteEvent = Instance.new("RemoteEvent")
	remoteEvent.Name = REMOTE_EVENT_NAME
	remoteEvent.Parent = ReplicatedStorage
end

local remoteFunc = ReplicatedStorage:FindFirstChild(REMOTE_FUNC_NAME) :: RemoteFunction?
if not remoteFunc then
	remoteFunc = Instance.new("RemoteFunction")
	remoteFunc.Name = REMOTE_FUNC_NAME
	remoteFunc.Parent = ReplicatedStorage
end

-- Only expose rarities that actually have at least one brainrot.
local function usableRarities()
	local list = {}
	for _, r in ipairs(RARITIES) do
		if #entriesOfRarity(r.Name) > 0 then
			table.insert(list, { Name = r.Name, Color = r.Color })
		end
	end
	if #list == 0 then
		for _, r in ipairs(RARITIES) do
			table.insert(list, { Name = r.Name, Color = r.Color })
		end
	end
	return list
end

remoteFunc.OnServerInvoke = function(player: Player)
	return {
		CanUse = canUse(player),
		Rarities = usableRarities(),
		Interval = Config.AutoSpawnInterval,
		UsingRealModels = usingRealModels,
	}
end

local function isKnownRarity(name: string): boolean
	return rarityByName[name] ~= nil
end

local autoOn = false
local lastAction: { [Player]: number } = {}
local ACTION_COOLDOWN = 0.35

remoteEvent.OnServerEvent:Connect(function(player: Player, action: string, arg: any)
	if not canUse(player) then return end
	local now = os.clock()
	if lastAction[player] and (now - lastAction[player]) < ACTION_COOLDOWN then
		return
	end
	lastAction[player] = now

	if action == "spawnRandom" then
		spawnBrainrot()
	elseif action == "spawnRarity" and typeof(arg) == "string" and isKnownRarity(arg) then
		spawnBrainrot(arg)
	elseif action == "clear" then
		clearAll()
	elseif action == "toggleAuto" then
		autoOn = not autoOn
	elseif action == "setInterval" and typeof(arg) == "number" then
		Config.AutoSpawnInterval = math.clamp(math.floor(arg), 1, 60)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastAction[player] = nil
end)

--==============================================================--
--  AUTO-SPAWN LOOP
--==============================================================--
task.spawn(function()
	local acc = 0
	while true do
		local dt = task.wait(0.25)
		if autoOn then
			acc += dt
			if acc >= Config.AutoSpawnInterval then
				acc = 0
				spawnBrainrot()
			end
		end
	end
end)

--==============================================================--
--  CLIENT BOOTSTRAP  (same file runs the menu on every client)
--==============================================================--
local existing = ReplicatedStorage:FindFirstChild("BrainrotSpawnerClient")
if existing then existing:Destroy() end

local clientCopy = script:Clone()
clientCopy.Name = "BrainrotSpawnerClient"
clientCopy.RunContext = Enum.RunContext.Client
clientCopy.Disabled = false
clientCopy.Parent = ReplicatedStorage

print(("[BrainrotSpawner] Server online. Entries=%d  RealModels=%s"):format(#dataEntries, tostring(usingRealModels)))