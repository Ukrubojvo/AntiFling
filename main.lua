-- // Services // --
local Services = {
	Players = cloneref(game:GetService("Players")),
	RunService = cloneref(game:GetService("RunService")),
	UserInputService = cloneref(game:GetService("UserInputService")),
	TweenService = cloneref(game:GetService("TweenService"))
}

-- // Player // --
local player = Services.Players.LocalPlayer

-- // AntiFling Variables // --
local antifling_velocity_threshold = 85
local antifling_angular_threshold = 25
local antifling_last_safe_cframe = nil
local antifling_enabled = false

-- // Spring Animation Variables // --
local spring_strength = 0.04
local spring_damping = 0.8
local target_position = UDim2.new(0.5, 0, 0.5, 0)
local current_velocity = Vector2.new(0, 0)
local original_drag_pos = UDim2.new(0.5, 0, 0.5, 65)
local drag_start_pos = UDim2.new(0.5, 0, 0.5, 65)

-- // UI Setup // --
local GUIParent = gethui and gethui() or game.CoreGui

local blocker_ui = GUIParent:FindFirstChild("AntiFlingUI")
if blocker_ui then
	blocker_ui:Destroy()
end

local screen_gui = Instance.new("ScreenGui")
screen_gui.Name = "AntiFlingUI"
screen_gui.ResetOnSpawn = false
screen_gui.IgnoreGuiInset = true
screen_gui.Parent = GUIParent
screen_gui.DisplayOrder = 2147483647

local main_frame = Instance.new("Frame")
main_frame.Size = UDim2.new(0, 260, 0, 110)
main_frame.Position = UDim2.new(0.5, 0, 0.5, 0)
main_frame.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
main_frame.BackgroundTransparency = 0.15
main_frame.BorderSizePixel = 0
main_frame.AnchorPoint = Vector2.new(0.5, 0.5)
main_frame.Active = true
main_frame.Parent = screen_gui

local corner = Instance.new("UICorner", main_frame)
corner.CornerRadius = UDim.new(0, 12)

local close_button = Instance.new("ImageButton")
close_button.Size = UDim2.new(0, 24, 0, 24)
close_button.Position = UDim2.new(1, -26, 0, 2)
close_button.BackgroundTransparency = 1
close_button.BorderSizePixel = 0
close_button.Image = "rbxassetid://82404346839314"
close_button.Parent = main_frame
close_button.ZIndex = 10

close_button.MouseButton1Click:Connect(function()
	screen_gui:Destroy()
end)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundColor3 = Color3.fromRGB(255,255,255)
title.BackgroundTransparency = 1
title.BorderSizePixel = 0
title.Text = "Real-Time AntiFling"
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.ZIndex = 50
title.Parent = main_frame

local title_corner = Instance.new("UICorner", title)
title_corner.CornerRadius = UDim.new(0, 12)

local drag_btn = Instance.new("TextButton")
drag_btn.Size = UDim2.new(0, 130, 0, 15)
drag_btn.Position = UDim2.new(0.5, 0, 0.5, 65)
drag_btn.BackgroundTransparency = 1
drag_btn.BorderSizePixel = 0
drag_btn.AnchorPoint = Vector2.new(0.5, 0.5)
drag_btn.Text = ""
drag_btn.ZIndex = 999
drag_btn.Parent = screen_gui

local drag_frame = Instance.new("Frame")
drag_frame.Size = UDim2.new(0, 130, 0, 4)
drag_frame.Position = UDim2.new(0.5, 0, 0.5, 65)
drag_frame.BackgroundColor3 = Color3.fromRGB(255,255,255)
drag_frame.BackgroundTransparency = 0.5
drag_frame.BorderSizePixel = 0
drag_frame.AnchorPoint = Vector2.new(0.5, 0.5)
drag_frame.Parent = screen_gui

local drag_corner = Instance.new("UICorner", drag_frame)
drag_corner.CornerRadius = UDim.new(0, 60)

local dragging = false
local drag_input, drag_start, start_pos
local tween_info = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, false, 0)
local drag_on = { BackgroundTransparency = 0 }
local drag_off = { BackgroundTransparency = 0.5 }

-- // Spring Animation Function // --
local function update_spring()
	if dragging then
		local current_pos = main_frame.Position
		local current_pixel = Vector2.new(current_pos.X.Offset, current_pos.Y.Offset)
		local target_pixel = Vector2.new(target_position.X.Offset, target_position.Y.Offset)
		
		local displacement = target_pixel - current_pixel
		
		local spring_force = displacement * spring_strength
		current_velocity = current_velocity + spring_force
		current_velocity = current_velocity * spring_damping
		
		local new_pixel = current_pixel + current_velocity
		local new_position = UDim2.new(
			target_position.X.Scale, new_pixel.X,
			target_position.Y.Scale, new_pixel.Y
		)
		
		main_frame.Position = new_position
	end
end

local function update_drag(input)
	local delta = input.Position - drag_start
	target_position = UDim2.new(start_pos.X.Scale, start_pos.X.Offset + delta.X, start_pos.Y.Scale, start_pos.Y.Offset + delta.Y)
	
	drag_btn.Position = UDim2.new(drag_start_pos.X.Scale, drag_start_pos.X.Offset + delta.X, drag_start_pos.Y.Scale, drag_start_pos.Y.Offset + delta.Y)
	drag_frame.Position = UDim2.new(drag_start_pos.X.Scale, drag_start_pos.X.Offset + delta.X, drag_start_pos.Y.Scale, drag_start_pos.Y.Offset + delta.Y)
end

drag_btn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local drag_starts = Services.TweenService:Create(drag_frame, tween_info, drag_on)
        drag_starts:Play()
		dragging = true
		drag_start = input.Position
		start_pos = main_frame.Position
		target_position = start_pos
		drag_start_pos = drag_btn.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
                drag_starts:Cancel()
                local drag_stop = Services.TweenService:Create(drag_frame, tween_info, drag_off)
                drag_stop:Play()
				dragging = false
				current_velocity = Vector2.new(0, 0)
				main_frame.Position = target_position
				drag_btn.Position = UDim2.new(target_position.X.Scale, target_position.X.Offset, target_position.Y.Scale, target_position.Y.Offset + 65)
				drag_frame.Position = UDim2.new(target_position.X.Scale, target_position.X.Offset, target_position.Y.Scale, target_position.Y.Offset + 65)
			end
		end)
	end
end)

drag_btn.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		drag_input = input
	end
end)

Services.UserInputService.InputChanged:Connect(function(input)
	if dragging and input == drag_input then
		update_drag(input)
	end
end)

-- // Spring Animation Loop // --
Services.RunService.Heartbeat:Connect(update_spring)

-- // Toggle Button // --
local toggle_button = Instance.new("TextButton")
toggle_button.Size = UDim2.new(1, -30, 0, 40)
toggle_button.Position = UDim2.new(0, 15, 0, 55)
toggle_button.BackgroundColor3 = Color3.fromRGB(82, 82, 91)
toggle_button.BackgroundTransparency = 0.5
toggle_button.TextColor3 = Color3.new(1, 1, 1)
toggle_button.Font = Enum.Font.GothamBold
toggle_button.TextSize = 16
toggle_button.Text = "Activate AntiFling"
toggle_button.AutoButtonColor = true
toggle_button.BorderSizePixel = 0
toggle_button.ZIndex = 2
toggle_button.Parent = main_frame

local toggle_corner = Instance.new("UICorner", toggle_button)
toggle_corner.CornerRadius = UDim.new(0, 8)

toggle_button.MouseButton1Click:Connect(function()
	antifling_enabled = not antifling_enabled
	toggle_button.Text = antifling_enabled and "AntiFling Activated" or "Activate AntiFling"
end)

-- // AntiFling Logic // --
local function protect_character()
	if not player.Character then return end
	local humanoid = player.Character:FindFirstChild("Humanoid")
	local root = player.Character:FindFirstChild("HumanoidRootPart")

	if root and humanoid and antifling_enabled then
		if root.Velocity.Magnitude <= antifling_velocity_threshold then
			antifling_last_safe_cframe = root.CFrame
		end

		if root.Velocity.Magnitude > antifling_velocity_threshold then
			if antifling_last_safe_cframe then
				root.Velocity = Vector3.new(0,0,0)
				root.AssemblyLinearVelocity = Vector3.new(0,0,0)
				root.AssemblyAngularVelocity = Vector3.new(0,0,0)
				root.CFrame = antifling_last_safe_cframe
			end
		end

		if root.AssemblyAngularVelocity.Magnitude > antifling_angular_threshold then
			root.AssemblyAngularVelocity = Vector3.new(0,0,0)
		end

		if humanoid:GetState() == Enum.HumanoidStateType.FallingDown then
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end
end

Services.RunService.Heartbeat:Connect(protect_character)
