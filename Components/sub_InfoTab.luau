return function(Window)
	local Changelog = {
		"18/10/2026",
		"<font color='rgb(255, 255, 0)'>~ Fixed Crazy Cart Creak</font>",
	}

	local function cloneref(service)
		if Abysall and Abysall.Environment.cloneref then
			return Abysall.Environment.cloneref(service)
		else
			return service
		end
	end

	local Services = setmetatable({}, {
		__index = function(self, serviceName)
			return cloneref(game:GetService(serviceName))
		end,
	})

	local Library = Abysall.Interface.Library
	local SaveManager = Abysall.Interface.SaveManager
	local ThemeManager = Abysall.Interface.ThemeManager
	local Toggles = Library.Toggles
	local Options = Library.Options

	local LocalPlayer = Services.Players.LocalPlayer
	local InfoTab = Window:AddTab("Info", "user")

	local UserInfo = InfoTab:AddLeftGroupbox("User Info")

	local thumbnailSize = Enum.ThumbnailSize.Size420x420
	local thumbnailType = Enum.ThumbnailType.HeadShot
	local userThumbnail = Services.Players:GetUserThumbnailAsync(LocalPlayer.UserId, thumbnailType, thumbnailSize)

	UserInfo:AddImage("UserIcon", {
		Image = userThumbnail,
	})

	UserInfo:AddLabel("ID: " .. LocalPlayer.Name, true)
	UserInfo:AddLabel("Total Executions: " .. ((Abysall.TotalExecutions and Abysall.TotalExecutions) or "N/A"), true)

	local Credits = {
		"<font color='rgb(0, 255, 255)'>CookieMonster — Owner of the Continued Script</font>",
		"<font color='rgb(255, 165, 0)'>FireBacon — Owner of the Discontinued Script</font>",
        "<font color='rgb(255, 165, 0)'>snopiL — Owner of the Modded Script</font>",
		"<font color='rgb(197, 63, 132)'>Rhyan57 — Provided the Infinite Crucifix</font>",
		"<font color='rgb(241, 106, 212)'>Abbas - Basicly a developer</font>",
		"<font color='rgb(120, 200, 255)'>den4ik_top_off - Theme creator</font>",
		"<font color='rgb(120, 200, 255)'>sasanixx - Theme creator</font>",
		"<font color='rgb(50, 205, 50)'>" .. LocalPlayer.Name .. " — For Using This Script</font>",
	}

	local CreditsGroupbox = InfoTab:AddRightGroupbox("Credits")
	for _, credit in pairs(Credits) do
		CreditsGroupbox:AddLabel(credit, true)
	end

	local ChangelogGroupbox = InfoTab:AddRightGroupbox("Changelog")
	for _, log in pairs(Changelog) do
		ChangelogGroupbox:AddLabel(log, true)
	end

	local executorName, executorVersion = Abysall.Environment.identifyexecutor()

	local ExecutorInfo = InfoTab:AddRightGroupbox("Executor Info")
	ExecutorInfo:AddLabel("Name: " .. executorName, true)
	ExecutorInfo:AddLabel("Version: " .. ((executorVersion and executorVersion) or "N/A"), true)
	ExecutorInfo:AddDivider()

	ExecutorInfo:AddLabel("Test Result: ", true)
	for _, result in pairs(Abysall.Environment.Results) do
		result = result:gsub("<", "(")
		result = result:gsub(">", ")")
		ExecutorInfo:AddLabel(result, true)
	end

	local Scripts = InfoTab:AddLeftGroupbox("Scripts")
	Scripts:AddButton("InfiniteYield", {
		Text = "Infinite Yield",
		Default = false,
		Tooltip = "Runs infinite yield.",
		Func = function()
			loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
		end,
	})

	Scripts:AddButton("Dex", {
		Text = "Dex",
		Default = false,
		Tooltip = "Runs Dex.",
		Func = function()
			Library:Notify("Please wait.")
			loadstring(game:HttpGet("https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua"))()
		end,
	})

	local Community = InfoTab:AddLeftGroupbox("Community")
	Community:AddButton("Copy Discord Invite", function()
		toclipboard("https://dsc.gg/abysallhubcontinued")
		Library:Notify("Discord invite copied.")
	end)
end
