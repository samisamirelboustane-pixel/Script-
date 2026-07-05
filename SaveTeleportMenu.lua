-- LocalScript (place in StarterPlayerScripts)
-- Save & Teleport Menu - All in one script

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "SaveTeleportGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

-- Toggle Button (always visible)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleButton"
toggleBtn.Size = UDim2.new(0, 40, 0, 40)
toggleBtn.Position = UDim2.new(0, 10, 0.5, -20)
toggleBtn.Text = "☰"
toggleBtn.TextSize = 22
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = gui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleBtn

-- Menu Frame
local menuFrame = Instance.new("Frame")
menuFrame.Name = "MenuFrame"
menuFrame.Size = UDim2.new(0, 160, 0, 130)
menuFrame.Position = UDim2.new(0, 60, 0.5, -65)
menuFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
menuFrame.BorderSizePixel = 0
menuFrame.Visible = true
menuFrame.Parent = gui

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 10)
menuCorner.Parent = menuFrame

-- Menu Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 5)
title.Text = "Teleport Menu"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.BackgroundTransparency = 1
title.Parent = menuFrame

-- Save Button
local saveBtn = Instance.new("TextButton")
saveBtn.Name = "SaveButton"
saveBtn.Size = UDim2.new(0.85, 0, 0, 36)
saveBtn.Position = UDim2.new(0.075, 0, 0, 38)
saveBtn.Text = "SAVE PLACE"
saveBtn.TextSize = 14
saveBtn.Font = Enum.Font.GothamBold
saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
saveBtn.BorderSizePixel = 0
saveBtn.Parent = menuFrame

local saveBtnCorner = Instance.new("UICorner")
saveBtnCorner.CornerRadius = UDim.new(0, 6)
saveBtnCorner.Parent = saveBtn

-- Teleport Button
local tpBtn = Instance.new("TextButton")
tpBtn.Name = "TeleportButton"
tpBtn.Size = UDim2.new(0.85, 0, 0, 36)
tpBtn.Position = UDim2.new(0.075, 0, 0, 82)
tpBtn.Text = "TELEPORT"
tpBtn.TextSize = 14
tpBtn.Font = Enum.Font.GothamBold
tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tpBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 220)
tpBtn.BorderSizePixel = 0
tpBtn.Parent = menuFrame

local tpBtnCorner = Instance.new("UICorner")
tpBtnCorner.CornerRadius = UDim.new(0, 6)
tpBtnCorner.Parent = tpBtn

-- Toggle menu visibility
local menuOpen = true
toggleBtn.MouseButton1Click:Connect(function()
	menuOpen = not menuOpen
	menuFrame.Visible = menuOpen
end)

local savedCFrame = nil

-- Save current place
saveBtn.MouseButton1Click:Connect(function()
	character = player.Character or player.CharacterAdded:Wait()
	if character:FindFirstChild("HumanoidRootPart") then
		savedCFrame = character.HumanoidRootPart.CFrame
		saveBtn.Text = "SAVED!"
		task.wait(1)
		saveBtn.Text = "SAVE PLACE"
	end
end)

-- Teleport back
tpBtn.MouseButton1Click:Connect(function()
	character = player.Character or player.CharacterAdded:Wait()
	if savedCFrame and character:FindFirstChild("HumanoidRootPart") then
		character.HumanoidRootPart.CFrame = savedCFrame
	end
end)
