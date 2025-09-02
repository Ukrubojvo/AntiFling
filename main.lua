function missing(t, f, fallback)
    if type(f) == t then return f end
    return fallback
end

local cloneref = missing("function", cloneref, function(...) return ... end)

-- // Services // --
local AntiLua = loadstring(game:HttpGet("https://raw.githubusercontent.com/Ukrubojvo/Modules/main/AntiLua.lua"))()
local Services = setmetatable({}, {
    __index = function(self, name)
        self[name] = cloneref(game:GetService(name))
        return self[name]
    end
})

-- // Player // --
local player = Services.Players.LocalPlayer

-- // AntiFling Variables // --
local antifling_velocity_threshold = 85
local antifling_angular_threshold = 25
local antifling_last_safe_cframe = nil
local antifling_enabled = false

-- // AntiFling Logic Function // --
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

-- // AntiFling Connection // --
local antifling_connection

-- // AntiLua UI // --
local ui = AntiLua.CreateUI({
    title = "AntiFling System",
    toggle_key = Enum.KeyCode.LeftControl,
    button_text = "Activate AntiFling",
    button_text_active = "AntiFling Activated",
    custom_code = function()
       	
    end,
    on_toggle = function(enabled)
        antifling_enabled = enabled
        
        if enabled then
            if not antifling_connection then
                antifling_connection = Services.RunService.Heartbeat:Connect(protect_character)
            end
			AntiLua.Notify("AntiFling Enabled!", 5, nil, "INFO")
        else
            if antifling_connection then
                antifling_connection:Disconnect()
                antifling_connection = nil
            end
			AntiLua.Notify("AntiFling Disabled!", 5, nil, "INFO")
        end
    end
})

AntiLua.Notify("You can toggle the UI with Left Control!", 10, nil, "INFO")
