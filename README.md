-- LocalScript (StarterPlayerScripts)

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- GUI
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "SaveTeleportGui"

-- Save Button
local saveBtn = Instance.new("TextButton", gui)
saveBtn.Size = UDim2.new(0,140,0,50)
saveBtn.Position = UDim2.new(0.1,0,0.8,0)
saveBtn.Text = "SAVE PLACE"
saveBtn.TextScaled = true
saveBtn.BackgroundColor3 = Color3.fromRGB(0,200,0)

-- Teleport Button
local tpBtn = Instance.new("TextButton", gui)
tpBtn.Size = UDim2.new(0,140,0,50)
tpBtn.Position = UDim2.new(0.55,0,0.8,0)
tpBtn.Text = "TELEPORT"
tpBtn.TextScaled = true
tpBtn.BackgroundColor3 = Color3.fromRGB(0,120,255)

local savedCFrame = nil

-- Save current place
saveBtn.MouseButton1Click:Connect(function()
	character = player.Character or player.CharacterAdded:Wait()
	if character:FindFirstChild("HumanoidRootPart") then
		savedCFrame = character.HumanoidRootPart.CFrame
		saveBtn.Text = "SAVED!"
		wait(1)
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
