local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- 🔥 Configuración editable
_G.FAKE_JUMP_POWER = _G.FAKE_JUMP_POWER or 70
local MAX_DISTANCE = 15

-- =========================
-- TOGGLE REAL
-- =========================
if _G.BombJumpGUI then
	_G.BombJumpGUI:Destroy()
	_G.BombJumpGUI = nil
	return
end

-- =========================
-- GUI
-- =========================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BombJumpGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

_G.BombJumpGUI = ScreenGui

local Button = Instance.new("TextButton")
Button.Size = UDim2.new(0,170,0,55)
Button.Position = UDim2.new(0.5,-85,0.8,0)
Button.Text = "BOMB BOOST"
Button.BackgroundColor3 = Color3.fromRGB(255,80,80)
Button.TextColor3 = Color3.new(1,1,1)
Button.TextScaled = true
Button.Parent = ScreenGui

-- =========================
-- DRAG FIX (ANTI 2 DEDOS)
-- =========================

local dragging = false
local dragInput, dragStart, startPos

Button.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
	or input.UserInputType == Enum.UserInputType.MouseButton1 then
		
		dragging = true
		dragInput = input
		dragStart = input.Position
		startPos = Button.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input == dragInput then
		local delta = input.Position - dragStart
		
		Button.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input == dragInput then
		dragging = false
	end
end)

-- =========================
-- FUNCIONES
-- =========================

local waitingForHandle = false

local function simulateJump()
	local character = LocalPlayer.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return end
	
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	hrp.Velocity = Vector3.new(hrp.Velocity.X, _G.FAKE_JUMP_POWER, hrp.Velocity.Z)
end

local function equipAndDropBomb()
	local character = LocalPlayer.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return end
	
	local tool = character:FindFirstChild("FakeBomb") 
		or LocalPlayer.Backpack:FindFirstChild("FakeBomb")
	if not tool then return end
	
	humanoid:EquipTool(tool)
	
	local remote = tool:FindFirstChild("Remote")
	if not remote then return end
	
	waitingForHandle = true
	remote:FireServer(CFrame.new(hrp.Position - Vector3.new(0,1,0)), 50)
end

-- Detectar Handle y hacer segundo salto
Workspace.ChildAdded:Connect(function(obj)
	if waitingForHandle and obj.Name == "Handle" and obj:IsA("Part") then
		
		local character = LocalPlayer.Character
		if not character then return end
		
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		
		task.wait()
		
		if (obj.Position - hrp.Position).Magnitude <= MAX_DISTANCE then
			obj.CFrame = hrp.CFrame * CFrame.new(0,-2,0)
			waitingForHandle = false
			
			task.wait()
			simulateJump()
		end
	end
end)

-- =========================
-- BOTÓN INTELIGENTE SIN DELAY
-- =========================

Button.MouseButton1Click:Connect(function()

	local character = LocalPlayer.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	local state = humanoid:GetState()
	local isOnGround = (
		state == Enum.HumanoidStateType.Running or
		state == Enum.HumanoidStateType.Landed
	)

	if isOnGround then
		simulateJump()
		
		repeat
			task.wait()
		until humanoid:GetState() == Enum.HumanoidStateType.Freefall
	end
	
	equipAndDropBomb()
end)
