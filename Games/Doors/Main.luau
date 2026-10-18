
--	Functions.Notify({Title = "Used For Notifications."})
-- 	Disabled = not Functions.CheckCompatability({"require"}), DisabledTooltip = Globals.IncompatibleMessage
-- 	Risky = Floor ~= "Mines" (Means it only works on mines)

local LoadStart = tick()

-- Автоматическая очистка старой сессии, если скрипт запускается повторно
if shared.Hastelepasta then
    pcall(function()
        if Library and Library.Unload then
            Library:Unload()
        elseif getgenv().Abysall and getgenv().Abysall.Interface and getgenv().Abysall.Interface.Library then
            getgenv().Abysall.Interface.Library:Unload()
        end
    end)
    shared.Hastelepasta = nil
end

shared.Hastelepasta = true


getgenv().Abysall = {
    Legit = true
}


local BaseUrl = "https://raw.githubusercontent.com/therealcookiemonsterof1966/AbysallContinued/main/"

-- Универсальные файловые функции (поддержка PC и всех мобильных эксплойтов: Delta, Codex, Hydrogen, Arceus, Wave и др.)
local rf = readfile or (getgenv and getgenv().readfile)
local wf = writefile or (getgenv and getgenv().writefile)
local ef = isfile or (getgenv and getgenv().isfile)
local mf = makefolder or (getgenv and getgenv().makefolder)

if mf then
    pcall(mf, "Abysall_Cache")
end

local function ReadLocalFile(name)
    if not rf then return nil end
    local cleanName = name:gsub("[^%w%._%-]", "_")
    local paths = {
        "Abysall_Cache/" .. cleanName,
        "Abysall_" .. cleanName,
        cleanName,
        "Abysall/" .. cleanName
    }
    for _, path in ipairs(paths) do
        local ok, data = pcall(rf, path)
        if ok and type(data) == "string" and #data > 50 then
            return data
        end
    end
    return nil
end

local function SaveLocalFile(name, content)
    if not wf or not content or #content < 50 then return end
    local cleanName = name:gsub("[^%w%._%-]", "_")
    if mf then pcall(mf, "Abysall_Cache") end
    local ok = pcall(wf, "Abysall_Cache/" .. cleanName, content)
    if not ok then
        pcall(wf, "Abysall_" .. cleanName, content)
    end
end

-- Чистый оригинальный HttpGet в обход любых хуков
local rawHttpGet = clonefunction and clonefunction(game.HttpGet) or game.HttpGet

-- Генерация зеркал через сверхбыстрый глобальный CDN jsDelivr (не блокируется и не режется провайдерами)
local function GetMirrorUrls(url)
    local urls = {}
    if type(url) == "string" and (url:find("%?t=") or url:find("nocache")) then
        table.insert(urls, url)
        local base = url:gsub("%?.*$", "")
        if base:find("raw.githubusercontent.com") then
            local user, repo, branch, rest = base:match("raw%.githubusercontent%.com/([^/]+)/([^/]+)/refs/heads/([^/]+)/(.*)")
            if not user then
                user, repo, branch, rest = base:match("raw%.githubusercontent%.com/([^/]+)/([^/]+)/([^/]+)/(.*)")
            end
            if user and repo and branch and rest then
                table.insert(urls, "https://cdn.jsdelivr.net/gh/" .. user .. "/" .. repo .. "@" .. branch .. "/" .. rest)
                table.insert(urls, "https://fastly.jsdelivr.net/gh/" .. user .. "/" .. repo .. "@" .. branch .. "/" .. rest)
            end
        end
        return urls
    end

    if type(url) == "string" and url:find("raw.githubusercontent.com") then
        local user, repo, branch, rest = url:match("raw%.githubusercontent%.com/([^/]+)/([^/]+)/refs/heads/([^/]+)/(.*)")
        if not user then
            user, repo, branch, rest = url:match("raw%.githubusercontent%.com/([^/]+)/([^/]+)/([^/]+)/(.*)")
        end
        if user and repo and branch and rest then
            table.insert(urls, "https://cdn.jsdelivr.net/gh/" .. user .. "/" .. repo .. "@" .. branch .. "/" .. rest)
            table.insert(urls, "https://fastly.jsdelivr.net/gh/" .. user .. "/" .. repo .. "@" .. branch .. "/" .. rest)
        end
    end
    table.insert(urls, url)
    return urls
end

local function DownloadRaw(url)
    local mirrors = GetMirrorUrls(url)
    for _, mirrorUrl in ipairs(mirrors) do
        local ok, res = pcall(rawHttpGet, game, mirrorUrl)
        if ok and type(res) == "string" and #res > 50 then
            return res
        end
    end
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and type(res) == "string" and #res > 50 then
        return res
    end
    return nil
end

local function GetScript(name, url)
    local cached = ReadLocalFile(name)
    if cached then
        return cached
    end

    local content = DownloadRaw(url)
    if content then
        SaveLocalFile(name, content)
        return content
    end

    return ""
end

-- Хук HttpGet для динамических загрузок (ассеты, картинки, звуки)
local function CachedHttpGetHook(self, url, ...)
    if type(url) == "string" and url:find("http") then
        local cleanName = url:match("([^/]+)$") or "module.lua"
        cleanName = cleanName:gsub("%?.*$", ""):gsub("[^%w%._%-]", "_")
        if not cleanName:find("%.lua") and not cleanName:find("%.luau") then
            cleanName = cleanName .. ".lua"
        end

        local cached = ReadLocalFile(cleanName)
        if cached then
            return cached
        end

        local content = DownloadRaw(url)
        if content and #content > 50 then
            SaveLocalFile(cleanName, content)
            return content
        end
    end
    return rawHttpGet(self, url, ...)
end

if not getgenv().Abysall_HttpHooked then
    getgenv().Abysall_HttpHooked = true
    pcall(function()
        if hookmetamethod then
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if (method == "HttpGet" or method == "httpGet") and self == game then
                    local args = { ... }
                    return CachedHttpGetHook(self, args[1], select(2, ...))
                end
                return oldNamecall(self, ...)
            end))
        end
    end)
    pcall(function()
        if hookfunction then
            hookfunction(game.HttpGet, newcclosure(CachedHttpGetHook))
        end
    end)
end

-- Полный список всех компонентов (включая модули интерфейса, чтобы исключить любые повторные сетевые запросы)
local Components = {
    Environment          = { File = "Environment.luau",          Url = BaseUrl .. "Components/Environment.luau" },
    ESPLibrary           = { File = "ESP.luau",                  Url = BaseUrl .. "Components/ESP.luau" },
    Notice16             = { File = "16Notice.luau",             Url = BaseUrl .. "Components/16Notice.luau" },
    Analytics            = { File = "Analytics.luau",            Url = BaseUrl .. "Components/Analytics.luau" },
    STX                  = { File = "STX.luau",                  Url = "https://raw.githubusercontent.com/bocaj111004/Abysall/refs/heads/main/Components/STX.luau" },
    Obsidian_Library     = { File = "Obsidian_Library.lua",      Url = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua" },
    Obsidian_SaveManager = { File = "Obsidian_SaveManager.lua",  Url = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/addons/SaveManager.lua" },
    Obsidian_ThemeManager= { File = "Obsidian_ThemeManager.lua", Url = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/addons/ThemeManager.lua" },
    InfoTab              = { File = "sub_InfoTab.luau",          Url = "https://raw.githubusercontent.com/snopiL0711/Abysall-Hub-Modded/refs/heads/main/Components/sub_InfoTab.luau", Dynamic = true },
    SettingsTab          = { File = "SettingsTab.luau",          Url = BaseUrl .. "Components/SettingsTab.luau" },
}

local LoadedSource = {}
local missingTasks = {}

for key, info in pairs(Components) do
    if not info.Dynamic then
        local cached = ReadLocalFile(info.File)
        if cached then
            LoadedSource[key] = cached
        else
            table.insert(missingTasks, { key = key, file = info.File, url = info.Url, dynamic = false })
        end
    else
        table.insert(missingTasks, { key = key, file = info.File, url = info.Url, dynamic = true })
    end
end

-- Если каких-то компонентов нет на диске (первый запуск) или они динамические (ченжлог), скачиваем их параллельно через скоростной CDN
if #missingTasks > 0 then
    local finished = 0
    for _, t in ipairs(missingTasks) do
        task.spawn(function()
            local fetchUrl = t.dynamic and (t.url .. "?t=" .. tostring(os.time() or tick())) or t.url
            local content = DownloadRaw(fetchUrl)
            if content and #content > 50 then
                LoadedSource[t.key] = content
                SaveLocalFile(t.file, content)
            elseif t.dynamic then
                local cached = ReadLocalFile(t.file)
                if cached then
                    LoadedSource[t.key] = cached
                end
            end
            finished += 1
        end)
    end

    local waitStart = tick()
    while finished < #missingTasks and (tick() - waitStart < 8) do
        task.wait(0.05)
    end

    -- Докачиваем синхронно, если какая-то нить не успела
    for _, t in ipairs(missingTasks) do
        if not LoadedSource[t.key] or #LoadedSource[t.key] < 50 then
            if t.dynamic then
                local fetchUrl = t.url .. "?t=" .. tostring(os.time() or tick())
                local content = DownloadRaw(fetchUrl)
                if content and #content > 50 then
                    LoadedSource[t.key] = content
                    SaveLocalFile(t.file, content)
                else
                    LoadedSource[t.key] = ReadLocalFile(t.file)
                end
            else
                LoadedSource[t.key] = GetScript(t.file, t.url)
            end
        end
    end
end

LoadedSource["16Notice"] = LoadedSource.Notice16

getgenv().Abysall = {
    Environment = loadstring(LoadedSource.Environment)(),
    ESPLibrary = loadstring(LoadedSource.ESPLibrary)(),
    ["16Notice"] = loadstring(LoadedSource.Notice16 or LoadedSource["16Notice"])(),
    Legit = true
}

local Abysall = getgenv().Abysall

if not Abysall.Environment.identifyexecutor then
    Abysall.Environment.identifyexecutor = function()
        local name = (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) or "Executor"
        return name, "1.0"
    end
end

local function CloneReference(Object)
    if Abysall and Abysall.Environment.cloneref then
        return Abysall.Environment.cloneref(Object)
    end
    return Object
end

local Services = setmetatable({}, {
    __index = function(Self, Name)
        return CloneReference(game:GetService(Name))
    end
})

if Abysall.Environment.writefile and Abysall.Environment.readfile then
    if not Abysall.Environment.isfile("Abysall/UserData.json") then
        local Data = {
            TotalExecutions = 0,
            UILibrary = "Obsidian"
        }

        Abysall.Environment.writefile(
            "Abysall/UserData.json",
            Services.HttpService:JSONEncode(Data)
        )
    end

    local UserData = Abysall.Environment.readfile("Abysall/UserData.json")
    local Decoded = Services.HttpService:JSONDecode(UserData)

    if not Decoded.TotalExecutions then
        Decoded.TotalExecutions = 0
    end

    Decoded.TotalExecutions = Decoded.TotalExecutions + 1

    if not Decoded.UILibrary then
        Decoded.UILibrary = "Obsidian"
    end

    Abysall.TotalExecutions = Decoded.TotalExecutions
    Abysall.UILibrary = Decoded.UILibrary

    Abysall.Environment.writefile(
        "Abysall/UserData.json",
        Services.HttpService:JSONEncode(Decoded)
    )
end

local function SafeLoadComponent(key)
    local info = Components[key]
    local src = LoadedSource[key]
    if info and info.Dynamic and (not src or #src < 50) then
        local fetchUrl = info.Url .. "?t=" .. tostring(os.time() or tick())
        local fresh = DownloadRaw(fetchUrl)
        if fresh and #fresh > 50 then
            src = fresh
            LoadedSource[key] = fresh
            SaveLocalFile(info.File, fresh)
        else
            src = ReadLocalFile(info.File)
            LoadedSource[key] = src
        end
    end
    if not src or #src < 50 then
        if info then
            src = GetScript(info.File, info.Url)
            LoadedSource[key] = src
        end
    end
    if key == "InfoTab" and (not src or #src < 50) then
        src = [==[return function(Window)
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
end]==]
        LoadedSource[key] = src
        SaveLocalFile("sub_InfoTab.luau", src)
    end
    local fn, err = loadstring(src)
    if not fn then
        warn("Failed to load component " .. tostring(key) .. ": " .. tostring(err))
        return nil
    end
    return fn()
end

Abysall.Interface = {
    Library = SafeLoadComponent("Obsidian_Library"),
    SaveManager = SafeLoadComponent("Obsidian_SaveManager"),
    ThemeManager = SafeLoadComponent("Obsidian_ThemeManager"),
    ApplyInfoTab = SafeLoadComponent("InfoTab"),
    ApplySettingsTab = SafeLoadComponent("SettingsTab"),
}

Abysall.Interface.ThemeManager.BuiltInThemes = {
	["Rat"] = { 1, { MainColor = "000000", FontFace = "Code", FontColor = "ffffff", OutlineColor = "323232", BackgroundColor = "000000", BackgroundImage = "96328525673956", AccentColor = "3e8846" } },
	["CookieMonster"] = { 2, { MainColor = "191919", FontFace = "Code", FontColor = "68ba95", OutlineColor = "282828", BackgroundColor = "000000", BackgroundImage = "85834287002942", AccentColor = "bb4d4d" } },
	["Default"] = { 3, { FontColor = "ffffff", MainColor = "1c1c1c", AccentColor = "0055ff", BackgroundColor = "141414", OutlineColor = "323232" } },
	["BBot"] = { 4, { FontColor = "ffffff", MainColor = "1e1e1e", AccentColor = "7e48a3", BackgroundColor = "232323", OutlineColor = "141414" } },
	["Fatality"] = { 5, { FontColor = "ffffff", MainColor = "1e1842", AccentColor = "c50754", BackgroundColor = "191335", OutlineColor = "3c355d" } },
	["Jester"] = { 6, { FontColor = "ffffff", MainColor = "242424", AccentColor = "db4467", BackgroundColor = "1c1c1c", OutlineColor = "373737" } },
	["Mint"] = { 7, { FontColor = "ffffff", MainColor = "242424", AccentColor = "3db488", BackgroundColor = "1c1c1c", OutlineColor = "373737" } },
	["Tokyo Night"] = { 8, { FontColor = "ffffff", MainColor = "191925", AccentColor = "6759b3", BackgroundColor = "16161f", OutlineColor = "323232" } },
	["Ubuntu"] = { 9, { FontColor = "ffffff", MainColor = "3e3e3e", AccentColor = "e2581e", BackgroundColor = "323232", OutlineColor = "191919" } },
	["Quartz"] = { 10, { FontColor = "ffffff", MainColor = "232330", AccentColor = "426e87", BackgroundColor = "1d1b26", OutlineColor = "27232f" } },
	["Nord"] = { 11, { FontColor = "eceff4", MainColor = "3b4252", AccentColor = "88c0d0", BackgroundColor = "2e3440", OutlineColor = "4c566a" } },
	["Dracula"] = { 12, { FontColor = "f8f8f2", MainColor = "44475a", AccentColor = "ff79c6", BackgroundColor = "282a36", OutlineColor = "6272a4" } },
	["Monokai"] = { 13, { FontColor = "f8f8f2", MainColor = "272822", AccentColor = "f92672", BackgroundColor = "1e1f1c", OutlineColor = "49483e" } },
	["Gruvbox"] = { 14, { FontColor = "ebdbb2", MainColor = "3c3836", AccentColor = "fb4934", BackgroundColor = "282828", OutlineColor = "504945" } },
	["Solarized"] = { 15, { FontColor = "839496", MainColor = "073642", AccentColor = "cb4b16", BackgroundColor = "002b36", OutlineColor = "586e75" } },
	["Catppuccin"] = { 16, { FontColor = "d9e0ee", MainColor = "302d41", AccentColor = "f5c2e7", BackgroundColor = "1e1e2e", OutlineColor = "575268" } },
	["One Dark"] = { 17, { FontColor = "abb2bf", MainColor = "282c34", AccentColor = "c678dd", BackgroundColor = "21252b", OutlineColor = "5c6370" } },
	["Cyberpunk"] = { 18, { FontColor = "f9f9f9", MainColor = "262335", AccentColor = "00ff9f", BackgroundColor = "1a1a2e", OutlineColor = "413c5e" } },
	["Oceanic Next"] = { 19, { FontColor = "d8dee9", MainColor = "1b2b34", AccentColor = "6699cc", BackgroundColor = "16232a", OutlineColor = "343d46" } },
	["Material"] = { 20, { FontColor = "eeffff", MainColor = "212121", AccentColor = "82aaff", BackgroundColor = "151515", OutlineColor = "424242" } },
	["Nya~!"] = { 21, { MainColor = "43505b", FontFace = "Gotham", FontColor = "ffffff", OutlineColor = "323232", BackgroundColor = "43505b", BackgroundImage = "85504522659236", AccentColor = "d7edff" } },
	["Valentines"] = { 22, { FontColor = "ffffff", MainColor = "321b27", AccentColor = "ff4f81", BackgroundColor = "24131c", OutlineColor = "5a3044" } },
	["St. Patrick's Day"] = { 23, { FontColor = "ffffff", MainColor = "182d20", AccentColor = "3ddc84", BackgroundColor = "0e1b13", OutlineColor = "31543d" } },
	["Easter"] = { 24, { FontColor = "ffffff", MainColor = "302b3d", AccentColor = "c6a7ff", BackgroundColor = "211e2b", OutlineColor = "514963" } },
	["Spooky Scary Skeletons"] = { 25, { FontColor = "ffffff", MainColor = "050717", AccentColor = "e36600", BackgroundColor = "03040d", OutlineColor = "000000", BackgroundImage = "7428858898", FontFace = "Code" } },
	["Thanksgiving"] = { 26, { FontColor = "fff7ed", MainColor = "382719", AccentColor = "e68a2e", BackgroundColor = "24180f", OutlineColor = "62472d" } },
	["Christmas"] = { 27, { MainColor = "070805", FontFace = "Code", FontColor = "ffffff", OutlineColor = "000000", BackgroundColor = "000000", BackgroundImage = "89924308622883", AccentColor = "242599" } },
}

Abysall.Analytics = SafeLoadComponent("Analytics")


Abysall.SavePath = "Doors/Game"

local Library = Abysall.Interface.Library
local SaveManager = Abysall.Interface.SaveManager
local ThemeManager = Abysall.Interface.ThemeManager

local Toggles = Library.Toggles
local Options = Library.Options

local function CloneReference(Object)
	if Abysall and Abysall.Environment.cloneref then
		return Abysall.Environment.cloneref(Object)
	end
	return Object
end

local Services = setmetatable({}, {
	__index = function(Self, Name)
		return CloneReference(game:GetService(Name))
	end
})

if Services.UserInputService.TouchEnabled and not Services.UserInputService.KeyboardEnabled then
	Library.IsMobile = true
	Library.OriginalMinSize = Vector2.new(480, 240)
end



-- archives and stairwell locals
local TimeShowerSourceLabel
local TimeShowerToken = 0
local TimeShowerConnection
local BypassDronesStampedeConnection
local HonchoCorrectBoxConnection
local HonchoAutoDepositConnection
local HonchoESPObjects = {}
local HonchoProcessedRooms = {}
local HonchoDepositCache = {}
local AntiClosetTrash_Connection
local AntiRansom_Connection
local ForgetMeNotConnection
local ForgetMeNotRunning = false
local ForgetMeNotProcessing = {}
local ForgetMeNotNotified = {}
local ForgetMeNotCompleted = {}
local WaterBypassConnection
local WaterParts = {}
local AlmaConnection
local AntiScribbles_Connection
local DroneConnection
local DroneWalkedIntoParents = {}
local OrbitDroppedItemsConnection
local OrbitDroppedItemsAngle = 0
local OrbitDroppedItemsLastTeleport = 0
local OrbitDroppedItemsPauseUntil = 0
local droppedItemsIntervalRunning = false

local Globals = { Running = true }
local Connections = {}
local ESPConnections = {}
local Groupboxes = {}
local FakePrompts = {}
local Functions = {}
local PartProperties = {}

local Objects = {
	Prompts = {},
	Objectives = {},
	Doors = {},
	HidingSpots = {},
	Entities = {},
	SeekObstructions = {},
	Items = {},
	Chests = {},
	Currency = {},
	Ladders = {},
	Misc = {},
	Obstructions = {},
	EventTriggers = {},
	JumpscareModules = {},
	SeekHighlights = {},
	EyestalkHighlights = {},
	SeekNodes = {},
	SeekDuckBoards = {},
	SeekBridges = {},
	PathLights = {}
}

Globals.IncompatibleMessage = "Your executor doesn't support this feature."

Functions.CheckCompatability = function(Array)
	for _, Name in Array do
		if not Abysall.Environment[Name] then
			return false
		end
	end
	return true
end



local LocalPlayer = Services.Players.LocalPlayer


local PortraitName = "MirrorRig_Portrait_" .. LocalPlayer.Name


local Entities = {
	["TV_Stand"] = {
		Alias = "Noise_TV",
		NotifyMessage = { Title = "Noise tv spawned.", Body = "Dont get near it" }
	},
	["Noise_TV"] = {
		Alias = "Noise_TV",
		NotifyMessage = { Title = "Noise tv spawned.", Body = "Dont get near it" }
	},
	["NoiseTV"] = {
		Alias = "Noise_TV",
		NotifyMessage = { Title = "Noise tv spawned.", Body = "Dont get near it" }
	},
	[PortraitName] = {
		Alias = "Portrait",
		NotifyMessage = { Title = "Portrait' has spawned.", Body = "Use him to duplicate items." }
	},
	["StemsEntity"] = {
	    Alias = 'Balls',
		NotifyMessage = { Title = "Balls", Body = "Balls."}
	},
	["Noise"] = {
		Alias = "Noise",
		NotifyMessage = { Title = "Entity 'Noise' has spawned.", Body = "Dont let it touch you." }
	},
	["NoiseModel"] = {
		Alias = "Noise",
		NotifyMessage = { Title = "Entity 'Noise' has spawned.", Body = "Dont let it touch you." }
	},
	["Creak"] = {
		Alias = "Creak",
		NotifyMessage = { Title = "Entity 'Creak' has spawned.", Body = "Dont touch him." }
	},
	["DronesStampede"] = {
		Alias = "DronesStampede",
		NotifyMessage = { Title = "Entity 'Drones Stampede' has spawned.", Body = "Find a hiding spot." }
	},
	["TellerRig"] = {
		Alias = "Teller",
		NotifyMessage = { Title = "Entity 'Teller' has spawned.", Body = "Dont worry, hes only annoying." }
	},
	["Scribbles"] = {
		Alias = "Scribbles",
		NotifyMessage = { Title = "Entity 'Scribbles' has spawned.", Body = "Find a hiding spot." }
	},
	["BashMoving"] = {
		Alias = "Bash",
		NotifyMessage = { Title = "Entity 'Bash' has spawned.", Body = "Find a hiding spot."}
	},
	["RushMoving"] = {
		Alias = "Rush",
		NotifyMessage = { Title = "Entity 'Rush' has spawned.", Body = "Find a hiding spot." }
	},
	["AmbushMoving"] = {
		Alias = "Ambush",
		NotifyMessage = { Title = "Entity 'Ambush' has spawned.", Body = "Find a hiding spot." }
	},
	["Eyes"] = {
		Alias = "Eyes",
		NotifyMessage = { Title = "Entity 'Eyes' has spawned.", Body = "Avoid looking at it." }
	},
	["Lookman"] = {
		Alias = "Eyes",
		NotifyMessage = { Title = "Entity 'Eyes' has spawned.", Body = "Avoid looking at it." }
	},
	["BackdoorRush"] = {
		Alias = "Blitz",
		NotifyMessage = { Title = "Entity 'Blitz' has spawned.", Body = "Find a hiding spot." }
	},
	["BackdoorLookman"] = {
		Alias = "Lookman",
		NotifyMessage = { Title = "Entity 'Lookman' has spawned.", Body = "Avoid looking at its eyes." }
	},
	["Groundskeeper"] = {
		Alias = "Groundskeeper",
		NotifyMessage = { Title = "Entity 'Groundskeeper' has spawned.", Body = "Avoid stepping on the grass." }
	},
	["A60"] = {
		Alias = "A-60",
		NotifyMessage = { Title = "Entity 'A-60' has spawned.", Body = "Find a hiding spot." }
	},
	["A120"] = {
		Alias = "A-120",
		NotifyMessage = { Title = "Entity 'A-120' has spawned.", Body = "Find a hiding spot." }
	},
	["GloombatSwarm"] = {
		Alias = "Gloombat Swarm",
		NotifyMessage = { Title = "Entity 'Gloombat Swarm' has spawned.", Body = "Keep all light sources turned off." }
	},
	["GlitchRush"] = {
		Alias = "RNIUSHCG==",
		NotifyMessage = { Title = "Entity 'RNIUSHCG==' has spawned.", Body = "Find a hiding spot." }
	},
	["GlitchAmbush"] = {
		Alias = "AR0xMBUSH",
		NotifyMessage = { Title = "Entity 'AR0xMBUSH' has spawned.", Body = "Find a hiding spot." }
	},
	["MonumentEntity"] = {
		Alias = "Monument",
		NotifyMessage = { Title = "Entity 'Monument' has spawned.", Body = "It can't move while you are looking at it." }
	},
	["JeffTheKiller"] = {
		Alias = "Jeff the Killer",
		NotifyMessage = { Title = "Entity 'Jeff the Killer' has spawned.", Body = "Avoid touching him." }
	},
	["CustomEntity"] = {
		Alias = "Custom Entity",
		NotifyMessage = { Title = "Entity 'Custom Entity' has spawned.", Body = "Find a hiding spot." }
	},
	["FrozenAmbush"] = {
		Alias = "Frozen Ambush",
		NotifyMessage = { Title = "Entity 'Frozen Ambush' has spawned.", Body = "Find a hiding spot." }
	},
	["SallyMoving"] = {
		Alias = "Sally",
		NotifyMessage = { Title = "Entity 'Sally' has spawned.", Body = "Find her horse and rop it." }
	}
}

local EntityIcons = {
	["RushMoving"]      = "rbxassetid://10716032262",
	["AmbushMoving"]    = "rbxassetid://10110576663",
	["A60"]             = "rbxassetid://12571092295",
	["A120"]            = "rbxassetid://12711591665",
	["BackdoorRush"]    = "rbxassetid://16602023490",
	["Eyes"]            = "rbxassetid://10183704772",
	["Lookman"]         = "rbxassetid://10183704772",
	["BackdoorLookman"] = "rbxassetid://16764872677",
	["GloombatSwarm"]   = "rbxassetid://79221203116470",
	["Halt"]            = "rbxassetid://11331795398",
	["JeffTheKiller"]   = "rbxassetid://94479432156278",
	["GlitchRush"]      = "rbxassetid://73859273102919",
	["GlitchAmbush"]    = "rbxassetid://88369678433359",
	["SallyMoving"]     = "rbxassetid://10840888070",
	["MonumentEntity"]  = "rbxassetid://88933556873017",
	["Groundskeeper"]   = "rbxassetid://114991380115557"
}

local ItemNames = {
	["AbrahamHat"]        = "Hat",
	["LargeScrew"]        = "Screw",
	["DinkyLamp"]         = "Lamp",
	["BottleCrate"]       = "18+ Bottles",
	["GweenSodaPack"]     = "Gween Soda Pack",
	["BrokenMonitor"]     = "Broken Monitor",
	["JerryCan"]          = "Jerry Can",
 	["SallyToyObtain"]    = "Sally Toy",
	["Leftovers"]         = "Lunch Box",
	["HoneyPot"]          = "Honey Pot",
	["FihFlakes"]         = "Fih Food",
	["SecretCD"]          = "CD Disc",
	["Pizza"]             = "Pizza",
	["PaperPlanePickup"]  = "Paper Plane",
	["Lighter"]           = "Lighter",
	["Flashlight"]        = "Flashlight",
	["Lockpick"]          = "Lockpicks",
	["Vitamins"]          = "Vitamins",
	["Bandage"]           = "Bandage",
	["StarVial"]          = "Starlight Vial",
	["StarBottle"]        = "Starlight Bottle",
	["StarJug"]           = "Starlight Barrel",
	["Shakelight"]        = "Gummy Flashlight",
	["Straplight"]        = "Straplight",
	["Bulklight"]         = "Spotlight",
	["Battery"]           = "Battery",
	["Candle"]            = "Candle",
	["Crucifix"]          = "Crucifix",
	["CrucifixWall"]      = "Crucifix",
	["Glowsticks"]        = "Glowstick",
	["SkeletonKey"]       = "Skeleton Key",
	["Candy"]             = "Candy",
	["ShieldMini"]        = "Mini Shield Potion",
	["ShieldBig"]         = "Big Shield Potion",
	["BandagePack"]       = "Bandage Pack",
	["BatteryPack"]       = "Battery Pack",
	["RiftCandle"]        = "Moonlight Candle",
	["LaserPointer"]      = "Laser Pointer",
	["HolyGrenade"]       = "Holy Hand Grenade",
	["Shears"]            = "Shears",
	["Smoothie"]          = "Smoothie",
	["Cheese"]            = "Cheese",
	["Bread"]             = "Bread",
	["AlarmClock"]        = "Alarm Clock",
	["RiftSmoothie"]      = "Moonlight Smoothie",
	["GweenSoda"]         = "Gween Soda",
	["GlitchCube"]        = "Glitch Fragment",
	["Scanner"]           = "Tablet",
	["Bomb"]              = "Bomb",
	["Knockbomb"]         = "Knockbomb",
	["Nanner"]            = "Nanner",
	["BigBomb"]           = "Big Bomb",
	["SnakeBox"]          = "Hiding Box",
	["GoldGun"]           = "Golden Gun",
	["StopSign"]          = "Stop Sign",
	["TipJar"]            = "Tip Jar",
	["Lantern"]           = "Lantern",
	["IronKey"]           = "Iron Key",
	["LotusPetal"]        = "Lotus Petal",
	["Compass"]           = "Compass",
	["LotusPetalPickup"]  = "Lotus Petal",
	["LanternLitItem"]    = "Lantern",
	["KeyIron"]           = "Iron Key",
	["IronKeyForCrypt"]   = "Iron Key",
	["LotusHolder"]       = "Lotus Petal",
	["Multitool"]         = "Multitool",
	["RiftJar"]           = "Rift Jar",
	["AloeVera"]          = "Aloe Vera",
	["Donut"]             = "Donut",
	["Lotus"]             = "Lotus",
	["BoxingGloves"]      = "Boxing Gloves"
}

local CutsceneNames = {
    "Figure",
    "FigureEnd",
    "FigureHotelEnd",
    "FigureHotelFire",
    "SeekIntroFools",
    "SeekIntroHotel",
    "SeekIntroMines",
    "SeekIntroMines2",
    "SerewSeekDrain",
    "SewerSeekLower",
    "GrumbleNestEnd",
    "EyestalkIntro",
}

local Character
local Humanoid
local RootPart

local Collision
local CollisionClone
local CollisionPart
local CollisionPartClone

local Camera

local RemotesFolder   = Services.ReplicatedStorage:FindFirstChild("RemotesFolder")
local LiveModifiers   = Services.ReplicatedStorage:FindFirstChild("LiveModifiers")
local FloorReplicated = Services.ReplicatedStorage:FindFirstChild("FloorReplicated")
local CurrentRooms    = Services.Workspace:WaitForChild("CurrentRooms", 5) or Services.Workspace:FindFirstChild("CurrentRooms")
local Drops           = Services.Workspace:FindFirstChild("Drops")
local GameData        = Services.ReplicatedStorage:WaitForChild("GameData", 5)
local Floor           = (GameData and GameData:WaitForChild("Floor", 5)) and GameData.Floor.Value or "Hotel"
local LatestRoom      = (GameData and GameData:WaitForChild("LatestRoom", 5)) or Instance.new("IntValue")
local FinishedLoadingRoom = GameData and GameData:FindFirstChild("FinishedLoadingRoom")
local RunService = game:GetService("RunService")

if FinishedLoadingRoom then
	FinishedLoadingRoom:Destroy()
end

local function GetHiddenContainer()
	if Functions.CheckCompatability({"gethui"}) then
		return Abysall.Environment.gethui()
	end
	return Services.CoreGui
end

local NotificationLibrary = {
	LiveNotifications = 0,
	Notifications = 1
}

local Container = Instance.new("ScreenGui")
Container.Name = Abysall.ESPLibrary:GenerateRandomString()
Container.Parent = GetHiddenContainer()
Container.DisplayOrder = 32767
Container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

if not Library.Scheme then
	Library.Scheme = setmetatable({}, {
		__index = function(Self, Name)
			return Library[Name]
		end
	})
end

function NotificationLibrary:Notify(TitleText, Desc, Delay)
	task.spawn(function()
		local Notification = Instance.new("Frame")
		local Line = Instance.new("Frame")
		local Warning = Instance.new("ImageLabel")
		local UICorner = Instance.new("UICorner")
		local UICorner2 = Instance.new("UICorner")
		local Title = Instance.new("TextLabel")
		local Description = Instance.new("TextLabel")

		Notification.Name = "Notification"
		Notification.Parent = Container
		Notification.BackgroundColor3 = Library.Scheme.BackgroundColor
		Notification.BackgroundTransparency = 0.4
		Notification.BorderSizePixel = 0
		Notification.Position = UDim2.new(1, 5, 0, 60 + (60 * NotificationLibrary.LiveNotifications))
		Notification.Size = UDim2.new(0, 420, 0, 50)
		Notification:SetAttribute("ID", NotificationLibrary.Notifications)
		Notification:SetAttribute("CurrentPosition", Notification.Position)

		Line.Name = "Line"
		Line.Parent = Notification
		Line.BackgroundColor3 = Library.Scheme.AccentColor
		Line.BorderSizePixel = 0
		Line.Position = UDim2.new(0, 0, 1, -3)
		Line.Size = UDim2.new(0, 0, 0, 3)

		Warning.Name = "Warning"
		Warning.Parent = Notification
		Warning.BackgroundTransparency = 1
		Warning.Position = UDim2.new(0, 10, 0, 5)
		Warning.Size = UDim2.new(0, 40, 0, 40)
		Warning.Image = "rbxassetid://3944668821"
		Warning.ImageColor3 = Library.Scheme.AccentColor
		Warning.ScaleType = Enum.ScaleType.Fit

		UICorner.CornerRadius = UDim.new(0, 20)
		UICorner.Parent = Warning

		UICorner2.CornerRadius = UDim.new(0, 4)
		UICorner2.Parent = Notification

		Title.Name = "Title"
		Title.Parent = Notification
		Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0, 60, 0.155, 0)
		Title.Size = UDim2.new(0, 205, 0, 15)
		Title.Text = TitleText or "..."
		Title.TextColor3 = Library.Scheme.FontColor
		Title.TextSize = 10
		Title.TextStrokeTransparency = 0.75
		Title.TextXAlignment = Enum.TextXAlignment.Left

		Description.Name = "Description"
		Description.Parent = Notification
		Description.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Description.BackgroundTransparency = 1
		Description.Position = UDim2.new(0, 60, 0.483, 0)
		Description.Size = UDim2.new(0, 205, 0, 18)
		Description.Text = Desc or "..."
		Description.TextColor3 = Library.Scheme.FontColor
		Description.TextTransparency = 0.1
		Description.TextSize = 10
		Description.TextStrokeTransparency = 0.75
		Description.TextXAlignment = Enum.TextXAlignment.Left

		NotificationLibrary.LiveNotifications += 1
		NotificationLibrary.Notifications += 1

		Services.TweenService:Create(
			Notification,
			TweenInfo.new(1, Enum.EasingStyle.Exponential),
			{ Position = UDim2.new(1, -370, 0, Notification.Position.Y.Offset) }
		):Play()

		task.wait(0.25)
		if typeof(Delay) == "Instance" then
			Delay.Destroying:Wait()
		else
			Services.TweenService:Create(
				Line,
				TweenInfo.new(Delay - 0.25, Enum.EasingStyle.Linear),
				{ Size = UDim2.new(0, 400, 0, 3) }
			):Play()
			task.wait(Delay - 0.25)
		end

		Notification:SetAttribute("Destroying", true)

		Services.TweenService:Create(
			Notification,
			TweenInfo.new(0.75, Enum.EasingStyle.Exponential, Enum.EasingDirection.In),
			{ Position = UDim2.new(1, 5, 0, Notification.Position.Y.Offset) }
		):Play()

		NotificationLibrary.LiveNotifications -= 1

		local NotifId = Notification:GetAttribute("ID")
		local NotifY = Notification:GetAttribute("CurrentPosition").Y.Offset

		for _, Object in Container:GetChildren() do
			if Object.Name == "Notification"
				and Object:GetAttribute("ID")
				and Object:GetAttribute("ID") > NotifId
				and Object:GetAttribute("Destroying") ~= true
				and Object.Position.Y.Offset ~= 60
			then
				local NewY = Object:GetAttribute("CurrentPosition").Y.Offset - 60
				Object:SetAttribute("CurrentPosition", UDim2.new(1, -450, 0, NewY))
				Services.TweenService:Create(
					Object,
					TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut),
					{ Position = UDim2.new(1, -370, 0, NewY) }
				):Play()
			end
		end

		task.wait(0.75)
		Notification:Destroy()
	end)
end

Globals.DoorsNotify = function(NotifyOptions)
	local function PlaySound(Parent, SoundId, Volume)
		local Sound = Instance.new("Sound")
		Sound.SoundId = SoundId
		Sound.Volume = Volume or 1
		Sound.Parent = Parent
		task.spawn(function()
			task.wait(0.1)
			Sound:Play()
			Sound.Ended:Wait()
			Sound:Destroy()
		end)
	end

	local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
	local UIContainer = PlayerGui:FindFirstChild("GlobalUI") or PlayerGui:FindFirstChild("MainUI")
	if not UIContainer then return end

	local AchievementsHolder = UIContainer:FindFirstChild("AchievementsHolder")
	if not AchievementsHolder then return end

	local Achievement = AchievementsHolder.Achievement:Clone()
	Achievement.Size = UDim2.new(0, 0, 0, 0)
	Achievement.Frame.Position = UDim2.new(1.1, 0, 0, 0)
	Achievement.Name = "LiveAchievement"
	Achievement.Visible = true

	Achievement.Frame.TextLabel.Text = NotifyOptions.Style or "NOTIFICATION"
	Achievement.Frame.Details.Title.Text = NotifyOptions.Title or "Sem Título"
	Achievement.Frame.Details.Desc.Text = NotifyOptions.Description or "Sem Descrição"
	Achievement.Frame.Details.Reason.Text = NotifyOptions.Reason or ""
	Achievement.Frame.ImageLabel.Image = (NotifyOptions.Image ~= "" and NotifyOptions.Image) or "rbxassetid://6023426923"

	local Color = NotifyOptions.Color or Color3.new(1, 1, 1)
	Achievement.Frame.TextLabel.TextColor3 = Color
	Achievement.Frame.UIStroke.Color = Color
	Achievement.Frame.Glow.ImageColor3 = Color
	Achievement.Parent = AchievementsHolder

	PlaySound(AchievementsHolder, "rbxassetid://10469938989", 1)

	task.spawn(function()
		Achievement:TweenSize(UDim2.new(1, 0, 0.2, 0), "In", "Quad", 0.8, true)
		task.wait(0.8)
		Achievement.Frame:TweenPosition(UDim2.new(0, 0, 0, 0), "Out", "Quad", 0.5, true)
		Services.TweenService:Create(
			Achievement.Frame.Glow,
			TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ ImageTransparency = 1 }
		):Play()

		if typeof(NotifyOptions.Time) == "Instance" then
			NotifyOptions.Time.Destroying:Wait()
		else
			task.wait(NotifyOptions.Time or 5)
		end

		Achievement.Frame:TweenPosition(UDim2.new(1.1, 0, 0, 0), "In", "Quad", 0.5, true)
		task.wait(0.5)
		Achievement:TweenSize(UDim2.new(1, 0, -0.1, 0), "InOut", "Quad", 0.5, true)
		task.wait(0.5)
		Achievement:Destroy()
	end)
end

Globals.STX = loadstring(LoadedSource.STX or GetScript("STX.luau", "https://raw.githubusercontent.com/bocaj111004/Abysall/refs/heads/main/Components/STX.luau"))()
Functions.Notify = function(Settings)
	local HiddenContainer = GetHiddenContainer()

	if not Settings.Body then
		Settings.Body = "..."
	end

	if not Options.NotifyStyle or Options.NotifyStyle.Value == "Abysall" then
		local Sound = Instance.new("Sound", HiddenContainer)
		Sound.SoundId = "rbxassetid://8784885431"
		Sound.Volume = (Toggles.NotifyPlaySound and Toggles.NotifyPlaySound.Value and Options.NotifySoundVolume.Value) or (Toggles.NotifyPlaySound and 0 or 3)
		Sound.PlayOnRemove = true
		Sound:Destroy()
		NotificationLibrary:Notify(Settings.Title, Settings.Body, Settings.Time or 5)
	elseif Options.NotifyStyle.Value == "Doors" then
		local IsEntity = false
		local EntityName = ""
		for Index, Object in pairs(Entities) do
			if Object.NotifyMessage.Title == Settings.Title or Object.NotifyMessage.Body == Settings.Body then
				IsEntity = true
				EntityName = Index
			end
		end
		Globals.DoorsNotify({
			Title = "Abysall Hub",
			Description = Settings.Title,
			Reason = Settings.Body,
			Style = IsEntity and "WARNING" or "NOTIFICATION",
			Color = IsEntity and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 222, 189),
			Image = Settings.Image,
			Time = Settings.Time
		})
	elseif Options.NotifyStyle.Value == "STX" then
		local Sound = Instance.new("Sound", HiddenContainer)
		Sound.SoundId = "rbxassetid://4590657391"
		Sound.Volume = (Toggles.NotifyPlaySound and Toggles.NotifyPlaySound.Value and Options.NotifySoundVolume.Value) or (Toggles.NotifyPlaySound and 0 or 3)
		Sound.PlayOnRemove = true
		Sound:Destroy()

		if Settings.Image then
			Globals.STX:Notify(
				{Title = "Abysall Hub", Description = Settings.Title .. "\n" .. Settings.Body},
				{OutlineColor = Library.Scheme.AccentColor,Time = Settings.Time or 5, Type = "image"},
				{Image = Settings.Image, ImageColor = Color3.fromRGB(255, 255, 255)}
			)
		else
			Globals.STX:Notify(
				{Title = "Abysall Hub", Description = Settings.Title .. "\n" .. Settings.Body},
				{OutlineColor = Library.Scheme.AccentColor,Time = Settings.Time or 5, Type = "default"}
			)
		end
	else
		local Sound = Instance.new("Sound", HiddenContainer)
		Sound.SoundId = "rbxassetid://4590662766"
		Sound.Volume = (Toggles.NotifyPlaySound and Toggles.NotifyPlaySound.Value and Options.NotifySoundVolume.Value) or (Toggles.NotifyPlaySound and 0 or 3)
		Sound.PlayOnRemove = true
		Sound:Destroy()
		Library:OldNotify({ Title = Settings.Title, Description = Settings.Body, Time = Settings.Time })
	end
end

Functions.Caption = function(Text, PlaySound)
	if typeof(PlaySound) ~= "boolean" then
		PlaySound = true
	end
	local CaptionValue = Instance.new("NumberValue")
	local Caption = Globals.MainUI:WaitForChild("MainFrame"):WaitForChild("Caption"):Clone()
	local CaptionSound = Globals.MainUI:WaitForChild("Initiator"):WaitForChild("Main_Game"):WaitForChild("Reminder"):WaitForChild("Caption")
	local CaptionSoundClone = CaptionSound:Clone()
	CaptionSoundClone.Parent = CaptionSound.Parent
	CaptionSoundClone.Volume = 0.1

	Caption.Destroying:Connect(function()
		CaptionValue:Destroy()
	end)

	for _, Child in Globals.MainUI:GetChildren() do
		if Child.Name == "LiveCaption" then
			Child:Destroy()
		end
	end

	Caption.Parent = Globals.MainUI
	Caption.Visible = true
	Caption.Name = "LiveCaption"
	Caption.Text = Text

	if PlaySound then
		CaptionSoundClone:Play()
	end

	Services.Debris:AddItem(CaptionSoundClone, 5)

	local HolderTween = Services.TweenService:Create(CaptionValue, TweenInfo.new(3), { Value = 100 })
	HolderTween:Play()
	HolderTween.Completed:Connect(function()
		CaptionValue:Destroy()
		Services.TweenService:Create(Caption, TweenInfo.new(4, Enum.EasingStyle.Linear), { TextTransparency = 1 }):Play()
		Services.TweenService:Create(Caption, TweenInfo.new(4, Enum.EasingStyle.Linear), { TextStrokeTransparency = 1 }):Play()
	end)
end

Functions.GetHasteTime = function()
	local TimeRemaining = FloorReplicated.DigitalTimer.Value
	local Minutes = math.floor(TimeRemaining / 60)
	local Seconds = TimeRemaining - (Minutes * 60)
	local MinutesText = Minutes < 10 and ("0" .. tostring(Minutes)) or tostring(Minutes)
	local SecondsText = Seconds < 10 and ("0" .. tostring(Seconds)) or tostring(Seconds)
	return MinutesText .. ":" .. SecondsText
end

Library.OldNotify = Library.Notify
Library.Notify = function(Data, Body, Time)
	Functions.Notify({ Title = Body, Time = Time or 5 })
end

local waitTimeout = tick() + 8
while (not LocalPlayer.Character or not CurrentRooms or not CurrentRooms:FindFirstChildOfClass("Model")) and tick() < waitTimeout do
	CurrentRooms = Services.Workspace:FindFirstChild("CurrentRooms")
	task.wait(0.1)
end
task.wait(0.1)

if not RemotesFolder then
	RemotesFolder = Services.ReplicatedStorage:WaitForChild("RemotesFolder", 3)
		or Services.ReplicatedStorage:WaitForChild("EntityInfo", 3)
		or Services.ReplicatedStorage:WaitForChild("Bricks", 3)
		or Services.ReplicatedStorage:FindFirstChild("RemotesFolder")
		or Services.ReplicatedStorage:FindFirstChild("EntityInfo")
		or Services.ReplicatedStorage:FindFirstChild("Bricks")
end

if Floor == "Hotel" and RemotesFolder and RemotesFolder.Name == "Bricks" then
	Floor = "OldHotel"
end

if not LiveModifiers then
	LiveModifiers = Instance.new("Folder")
end

if not FloorReplicated then
	FloorReplicated = Instance.new("Folder")
end

local FakeEvents = {
	Screech = Instance.new("RemoteEvent"),
	Shade   = Instance.new("RemoteEvent"),
	A90     = Instance.new("RemoteEvent"),
	Surge   = Instance.new("RemoteEvent"),
}

FakeEvents.Screech.Name  = "Screech"
FakeEvents.Shade.Name    = "ShadeResult"
FakeEvents.A90.Name      = "A90"
FakeEvents.Surge.Name    = "SurgeRemote"

if RemotesFolder then
	FakeEvents.Screech_Real = RemotesFolder:WaitForChild("Screech", 3) or RemotesFolder:FindFirstChild("Screech")
	FakeEvents.Shade_Real   = RemotesFolder:WaitForChild("ShadeResult", 3) or RemotesFolder:FindFirstChild("ShadeResult")
	FakeEvents.A90_Real     = RemotesFolder:FindFirstChild("A90") or RemotesFolder:FindFirstChild("A-90")
	FakeEvents.Surge_Real   = RemotesFolder:FindFirstChild("SurgeRemote")

	RemotesFolder.ChildAdded:Connect(function(child)
		if child.Name == "A90" or child.Name == "A-90" then
			FakeEvents.A90_Real = child
			pcall(function()
				if Functions and Functions.ApplyRemoveA90 and Toggles and Toggles.RemoveA90 and Toggles.RemoveA90.Value then
					Functions.ApplyRemoveA90(true)
				elseif Toggles and Toggles.NoA90Damage and Toggles.NoA90Damage.Value then
					FakeEvents.A90.Parent = RemotesFolder
					FakeEvents.A90_Real.Parent = nil
				end
			end)
		end
	end)
end

if RemotesFolder:FindFirstChild("FootstepRemoteThatWeNeed") then
    local RealRemote = RemotesFolder:FindFirstChild("FootstepRemoteThatWeNeed")
    RealRemote:Destroy()

    local FakeRemote = Instance.new("RemoteEvent", RemotesFolder)
    FakeRemote.Name = "FootstepRemoteThatWeNeed"
end

Globals.FogInstances = {}
Globals.OldFog = Services.Lighting.FogEnd

for _, Object in Services.Lighting:GetChildren() do
	if Object:IsA("Atmosphere") then
		Object:SetAttribute("Density_Old", Object.Density)

		local AtmoConnection = Object:GetPropertyChangedSignal("Density"):Connect(function()
			if Object.Density ~= 0 then
				Object:SetAttribute("Density_Old", Object.Density)
			end
			if Toggles.RemoveCameraFog.Value then
				Object.Density = 0
			end
		end)

		Object.Destroying:Once(function()
			AtmoConnection:Disconnect()
		end)

		table.insert(Connections, AtmoConnection)
		table.insert(Globals.FogInstances, Object)
	end
end

Globals.SeekNodesFolder = Instance.new("Folder", Services.Workspace)
Globals.SeekNodesFolder.Name = Abysall.ESPLibrary:GenerateRandomString()

Globals.RoomsNodesFolder = Instance.new("Folder", Services.Workspace)
Globals.RoomsNodesFolder.Name = Abysall.ESPLibrary:GenerateRandomString()

Functions.SendChat = function(Message)
	local Folder = Services.ReplicatedStorage:FindFirstChild("DefaultChatSystemEvents") or Instance.new("Folder")
	local Event = Folder:FindFirstChild("SayMessageRequest") or Instance.new("RemoteEvent")
	Event:FireServer(Message, "All")
	local Channel = (Services.TextChatService:FindFirstChild("TextChannels") and Services.TextChatService.TextChannels:FindFirstChild("RBXGeneral")) or Instance.new("TextChannel")
	Channel:SendAsync(Message)
end

Functions.IsCrouching = function()
	if Floor == "Fools" or Floor == "OldHotel" then
		return Character:GetAttribute("Crouching")
	end
	return CollisionPart.CollisionGroup == "PlayerCrouching"
end

Functions.GetInjuriesSpeed = function()
	return 0.075 * (Humanoid.MaxHealth - Humanoid.Health)
end

Functions.GetCurrentSpeed = function()
	local Speed = 15
	Speed += Character:GetAttribute("SpeedBoost") or 0
	Speed += Character:GetAttribute("SpeedBoostBehind") or 0
	Speed += Character:GetAttribute("SpeedBoostExtra") or 0
	Speed += (Floor == "Party" and 10 or 0)
	Speed += (LiveModifiers:FindFirstChild("PlayerFast") and 3 or 0)
	Speed += (LiveModifiers:FindFirstChild("PlayerFaster") and 6 or 0)
	Speed += (LiveModifiers:FindFirstChild("PlayerFastest") and 20 or 0)
	Speed -= (LiveModifiers:FindFirstChild("PlayerSlow") and 3 or 0)
	Speed -= (LiveModifiers:FindFirstChild("PlayerSlowHealth") and Functions.GetInjuriesSpeed() or 0)
	if Functions.IsCrouching() then
		if LiveModifiers:FindFirstChild("PlayerCrouchSlow") then
			Speed -= 8
		elseif LiveModifiers:FindFirstChild("PlayerSlow") then
			Speed -= 8
		else
			Speed -= 5
		end
	end
	return Speed
end

Functions.GetMousePosition = function()
	if Library.IsMobile then
		return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	end
	local MouseLocation = Services.UserInputService:GetMouseLocation()
	return Vector2.new(MouseLocation.X, MouseLocation.Y)
end

Functions.FormatOxygen = function(Oxygen)
	return "Oxygen: " .. (math.floor(Oxygen * 10) / 10) .. "%"
end

Functions.IsHidePersistent = function()
	return Floor == "Mines"
		or Floor == "Ripple"
		or Floor == "Party"
		or LiveModifiers:FindFirstChild("HideLevel2") ~= nil
end

Functions.GetPlayerFromMouse = function(TargetPart, MaxDistance)
	local Closest
	local ClosestDistance = math.huge

	for _, Player in Services.Players:GetPlayers() do
		local Char = Player.Character
		if Char then
			local Target = Char:FindFirstChild(TargetPart)
			if Target then
				local Result = Camera:WorldToViewportPoint(Target.Position)
				local ScreenPos = Vector2.new(Result.X, Result.Y)
				local Distance = (Functions.GetMousePosition() - ScreenPos).Magnitude
				if Player.Name ~= LocalPlayer.Name and Distance < ClosestDistance and Distance < MaxDistance then
					Closest = Target
					ClosestDistance = Distance
				end
			end
		end
	end
	return Closest
end

local EntityDistances = {
	["RushMoving"]    = 85,
	["Scribbles"]	  = 100,
	["BashMoving"]    = 150,
	["DronesStampede"] = 100,
	["AmbushMoving"]  = 150,
	["A60"]           = 125,
	["A120"]          = 85,
	["GlitchRush"]    = 90,
	["GlitchAmbush"]  = 175,
	["BackdoorRush"]  = 85,
	["CustomEntity"]  = 85,
}

Functions.GetNearestEntity = function(CheckDisabled, List, UseRaycasting)
	local Nearest = { Distance = math.huge, Object = nil }

	for _, Entity in Objects.Entities do
		if not Entity or not Entity:IsA("Model") or not Entity:IsDescendantOf(Services.Workspace) then continue end
		if not EntityDistances[Entity.Name] or not Entity.PrimaryPart then continue end

		local EntityData = Entities[Entity.Name]
		if not EntityData then continue end
		if List and List[EntityData.Alias] then continue end

		local Distance = LocalPlayer:DistanceFromCharacter(Entity.PrimaryPart.Position)
		if Distance < EntityDistances[Entity.Name] and Distance < Nearest.Distance then
			if not CheckDisabled or Entity:GetAttribute("Inactive") ~= true then
				Nearest.Distance = Distance
				Nearest.Object = Entity
			end
		end
	end
	return Nearest.Object
end

Functions.GetNearestFigure = function()
	local Nearest = { Distance = math.huge, Object = nil }
	local FigureNames = { FigureRig = true, FigureRagdoll = true, Figure = true }

	for _, Object in Objects.Entities do
		if Object:IsA("Model") and Object.PrimaryPart and FigureNames[Object.Name] then
			local Distance = LocalPlayer:DistanceFromCharacter(Object.PrimaryPart.Position)
			if Distance < Nearest.Distance and Distance < 25 then
				Nearest.Distance = Distance
				Nearest.Object = Object
			end
		end
	end
	return Nearest.Object
end

Functions.GetNearestHidingSpot = function()
	local Nearest = { Distance = math.huge, Object = nil }
	local LastHideSpot = Character:FindFirstChild("LastHideSpot")

	local function IsHidingSpotName(Name)
		if typeof(Name) ~= "string" then return false end
		return string.find(string.lower(Name), "hidingspot") or string.find(string.lower(Name), "hiding_spot")
	end

	local function GetHidePrompt(Object)
	if not Object then return nil end

	local Prompt = Object:FindFirstChild("HidePrompt") or Object:FindFirstChild("HidingPrompt")
	if Prompt then return Prompt end

	for _, Child in Object:GetDescendants() do
		if (Child:IsA("ProximityPrompt") or Child:IsA("InteractPrompt"))
			and (Child.Name == "HidePrompt" or Child.Name == "HidingPrompt" or IsHidingSpotName(Child.Name))
		then
			return Child
		end
	end

	if IsHidingSpotName(Object.Name) or IsHidingSpotName(Object.Parent and Object.Parent.Name) then
		return Object:FindFirstChild("HidePrompt") or Object:FindFirstChild("HidingPrompt")
	end

	return nil
	end

	local function TryObject(Object)
		if not Object or not Object:IsDescendantOf(Services.Workspace) then return end
		if not Object.PrimaryPart and not Object:FindFirstChildOfClass("BasePart") then return end
		local Prompt = GetHidePrompt(Object)
		if not Prompt then return end
		local PrimaryPart = Object.PrimaryPart or Object:FindFirstChildOfClass("BasePart")
		if not PrimaryPart then return end
		local Distance = LocalPlayer:DistanceFromCharacter(PrimaryPart.Position)
		if Distance < Prompt.MaxActivationDistance and Distance < Nearest.Distance then
			local Persistent = Functions.IsHidePersistent()
			if not Persistent or (LastHideSpot and LastHideSpot.Value ~= Object) or not LastHideSpot then
				Nearest.Distance = Distance
				Nearest.Object = Object
			end
		end
	end

	for _, Object in Objects.HidingSpots do
		TryObject(Object)
	end

	return Nearest.Object
end

Functions.GetNearestTurnNode = function()
	local Nearest = { Distance = math.huge, Object = nil }

	for _, Node in Objects.SeekNodes do
		local Distance = LocalPlayer:DistanceFromCharacter(Node.Position)
		if Distance < Options.AutoSteerMinecartTurnDistance.Value and Distance < Nearest.Distance then
			Nearest.Distance = Distance
			Nearest.Object = Node
		end
	end
	return Nearest.Object
end

Functions.GetNearestDuckBoard = function()
	local Nearest = { Distance = math.huge, Object = nil }

	for _, Board in Objects.SeekDuckBoards do
		if Board.PrimaryPart then
			local Distance = LocalPlayer:DistanceFromCharacter(Board.PrimaryPart.Position)
			if Distance < Options.AutoSteerMinecartDuckDistance.Value and Distance < Nearest.Distance then
				Nearest.Distance = Distance
				Nearest.Object = Board
			end
		end
	end
	return Nearest.Object
end

Functions.GetCurrentAnchor = function()
	local AnchorCode = Globals.MainUI.AnchorHintFrame.AnchorCode.Text
	for _, Anchor in Objects.Objectives do
		if Anchor.Name == "MinesAnchor" and Anchor:FindFirstChild("Sign") then
			if Anchor.Sign.TextLabel.Text == AnchorCode then
				return Anchor
			end
		end
	end
end

Functions.GetMinecart = function()
	return Camera:FindFirstChild("MinecartRig") ~= nil
end

Functions.HasItem = function(Name, OnlyCharacter)
	if not OnlyCharacter and LocalPlayer.Backpack:FindFirstChild(Name) then
		return LocalPlayer.Backpack:FindFirstChild(Name)
	elseif Character:FindFirstChild(Name) then
		return Character:FindFirstChild(Name)
	end
end

Functions.GetFlyVelocity = function()
	if Humanoid.MoveDirection == Vector3.zero then
		return Humanoid.MoveDirection
	end
	local LookFlat = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z)
	local FlatFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + LookFlat)
	local Velocity = (Camera.CFrame * CFrame.new(FlatFrame:VectorToObjectSpace(Humanoid.MoveDirection))).Position - Camera.CFrame.Position
	if Velocity == Vector3.zero then
		return Velocity
	end
	return Velocity.Unit
end

Globals.PromptContainer = Instance.new("Folder")
Globals.PromptContainer.Name = "PromptContainer"
Globals.PromptContainer.Parent = GetHiddenContainer()

local ESPBlacklist = {}
local RoomBasedESP = {}
local RoomSignalConnection = nil

local function UpdateRoomBasedESP()
	local CurrentRoom = tonumber(LocalPlayer:GetAttribute("CurrentRoom"))
	if not CurrentRoom then return end
	for Object, ESPOptions in pairs(RoomBasedESP) do
		if not Object or Object.Parent == nil then
			RoomBasedESP[Object] = nil
			if Abysall and Abysall.ESPLibrary then
				Abysall.ESPLibrary:RemoveESP(Object)
			end
		else
			local ObjRoom = tonumber(Object:GetAttribute("ParentRoom"))
			if ObjRoom == CurrentRoom or (table.find(Objects.Doors, Object) and ObjRoom == CurrentRoom + 1) then
				if Abysall and Abysall.ESPLibrary and Abysall.ESPLibrary.ColorTable[Object] then
					ESPOptions.Color = Abysall.ESPLibrary.ColorTable[Object]
				end
				if Abysall and Abysall.ESPLibrary then
					Abysall.ESPLibrary:AddESP(ESPOptions)
				end
			else
				if Abysall and Abysall.ESPLibrary then
					Abysall.ESPLibrary:RemoveESP(Object)
				end
			end
		end
	end
end

Functions.AddESP = function(ESPOptions, RoomBased)
	local Object = ESPOptions.Object
	if not Object or table.find(ESPBlacklist, Object) then
		return
	end

	if RoomBased then
		RoomBasedESP[Object] = ESPOptions

		if not RoomSignalConnection then
			RoomSignalConnection = LocalPlayer:GetAttributeChangedSignal("CurrentRoom"):Connect(UpdateRoomBasedESP)
			table.insert(Connections, RoomSignalConnection)
		end

		local CurrentRoom = tonumber(LocalPlayer:GetAttribute("CurrentRoom"))
		local ObjectRoom = tonumber(Object:GetAttribute("ParentRoom"))

		if ObjectRoom == CurrentRoom or (table.find(Objects.Doors, Object) and ObjectRoom == CurrentRoom + 1) then
			Abysall.ESPLibrary:AddESP(ESPOptions)
		end

		Object.Destroying:Once(function()
			RoomBasedESP[Object] = nil
			if Abysall and Abysall.ESPLibrary then
				Abysall.ESPLibrary:RemoveESP(Object)
			end
		end)
	else
		Abysall.ESPLibrary:AddESP(ESPOptions)
	end
end

Functions.RemoveESP = function(Object)
	RoomBasedESP[Object] = nil
	local Conn = ESPConnections[Object]
	if Conn then
		Conn:Disconnect()
		ESPConnections[Object] = nil
		local Pos = table.find(Connections, Conn)
		if Pos then table.remove(Connections, Pos) end
	end
	if Abysall and Abysall.ESPLibrary then
		Abysall.ESPLibrary:RemoveESP(Object)
	end
end

Functions.BlacklistESP = function(Object)
	table.insert(ESPBlacklist, Object)
end

Functions.GetDoorNumber = function(Object)
	local DoorNumber = (Object.Parent and tonumber(Object.Parent.Name)) or (Object.Parent and Object.Parent.Parent and tonumber(Object.Parent.Parent.Name))
	if DoorNumber then
		DoorNumber = DoorNumber + 1
	end
	if Floor == "Mines" then
		DoorNumber = DoorNumber + 100
	end
	if Floor == "Backdoor" then
		DoorNumber = DoorNumber - 50
	end

	return tostring(DoorNumber)
end

Functions.GetLibraryCode = function()
	local Paper = Character:FindFirstChild("LibraryHintPaper")
		or Character:FindFirstChild("LibraryHintPaperHard")
		or LocalPlayer.Backpack:FindFirstChild("LibraryHintPaper")
		or LocalPlayer.Backpack:FindFirstChild("LibraryHintPaperHard")

	if Paper and Paper:FindFirstChild("UI") then
		local Code = {}
		local CodeLength = Floor == "Fools" and 10 or 5
		for I = 1, CodeLength do Code[I] = "_" end

		local HintChildren = LocalPlayer.PlayerGui.PermUI.Hints:GetChildren()
		local UIChildren = Paper.UI:GetChildren()

		for _, Hint in HintChildren do
			for _, UIChild in UIChildren do
				if Hint:IsA("ImageLabel") and UIChild:IsA("ImageLabel")
					and Hint.ImageRectOffset == UIChild.ImageRectOffset
					and Code[tonumber(UIChild.Name)]
				then
					Code[tonumber(UIChild.Name)] = Hint.TextLabel.Text
				end
			end
		end
		return table.concat(Code)
	end
	return Floor == "Fools" and "__________" or "_____"
end

Globals.UsedRandomCodes = {}
Functions.GetRandomCode = function()
    local CodeTemplate = Functions.GetLibraryCode()
    if not CodeTemplate then
        return nil
    end

    local NewCode
    local Tries = 0
    repeat
        NewCode = CodeTemplate:gsub("_", function()
            return tostring(math.random(0, 9))
        end)
        Tries = Tries + 1
    until not Globals.UsedRandomCodes[NewCode] or Tries >= 10

    Globals.UsedRandomCodes[NewCode] = true
    return NewCode
end

local Window = Library:CreateWindow({
	Title = "🎃 Abysall Hub Continued",
	Footer = "dsc.gg/abysallhubcontinued",
	NotifySide = "Right",
	ShowCustomCursor = false,
	AutoShow = true,
	Center = true,
	TabPadding = 3,
	MenuFadeTime = 0,
	CornerRadius = 6,
})




if Abysall.Interface.ApplyInfoTab then
	pcall(Abysall.Interface.ApplyInfoTab, Window)
end

local Tabs = {
	General = Window:AddTab("General", "house"),
	Exploits = Window:AddTab("Exploits", "shield"),
	Visuals = Window:AddTab("Visuals", "eye"),
	Floors = Window:AddTab("Floors", "earth"),
	Archives = Window:AddTab("New - Archives", "rbxassetid://104508835882225"),
	Stairwell = Window:AddTab("New - Stairwell", "rbxassetid://80017304328364"),
}

task.spawn(function()
	task.wait(0.15)
	if Tabs and Tabs.General and Tabs.General.Show then
		Tabs.General:Show()
	end
end)


Groupboxes.General_Character = Tabs.General:AddLeftGroupbox("Character")
Groupboxes.General_Character:AddSlider("SpeedBoostSlider", {
	Text = "Speed Boost", Min = 0, Max = 75, Default = 0, Rounding = 0, Compact = true
})
Groupboxes.General_Character:AddToggle("SpeedBoostToggle", {
	Text = "Enable Speed Boost", Default = false, Tooltip = "Increases your walkspeed by the specified amount."
})
Groupboxes.General_Character:AddToggle("FlyToggle", {
	Text = "Fly", Default = false, Tooltip = "Allows you to freely fly around the map."
})
Toggles.FlyToggle:AddKeyPicker("FlyKeybind", {
	Text = "Fly", Default = "F", Mode = "Toggle", SyncToggleState = true
})
Groupboxes.General_Character:AddSlider("FlySpeed", {
	Text = "Fly Speed", Min = 0, Max = 115, Default = 20, Rounding = 0, Compact = true
})
Groupboxes.General_Character:AddDivider()
Groupboxes.General_Character:AddToggle("NoclipToggle", {
	Text = "Noclip", Default = false, Tooltip = "Allows your character to pass through solid objects."
})
Groupboxes.General_Character:AddToggle("RemoveClosetDelay", {
	Text = "Remove Closet Delay", Default = false,
	Tooltip = "Removes the short window where you can't exit out of a closet after the animation finishes."
})
Groupboxes.General_Character:AddToggle("RemoveAcceleration", {
	Text = "Remove Acceleration", Default = false, Tooltip = "Prevents your character from sliding while moving."
})

local CustomPhysics

Options.SpeedBoostSlider:OnChanged(function(Value)
	if RemotesFolder:FindFirstChild("Crouch") then
		RemotesFolder.Crouch:FireServer(Value and true or Functions.IsCrouching(), true)
	end
end)

Toggles.NoclipToggle:AddKeyPicker("NoclipKeybind", {
	Text = "Noclip", Default = "N", Mode = "Toggle", SyncToggleState = true
})
Toggles.RemoveAcceleration:OnChanged(function(Value)
	for Index, Old in PartProperties do
		Index.CustomPhysicalProperties = Value and CustomPhysics or Old
	end
end)

Groupboxes.General_Character:AddDivider()
Groupboxes.General_Character:AddToggle("EnableCharacterJump", {
	Text = "Enable Jumping", Default = false, Tooltip = "Allows your character to jump."
})
Groupboxes.General_Character:AddToggle("EnableCharacterSlide", {
	Text = "Enable Sliding", Default = false, Tooltip = "Allows your character to slide."
})
Groupboxes.General_Character:AddToggle("InfiniteJumps", {
	Text = "Infinite Jumps", Default = false, Tooltip = "Allows you to jump while in the air."
})

local OldJump = false
local OldSlide = false

Toggles.SpeedBoostToggle:OnChanged(function(Value)
	if Humanoid then
		Humanoid.WalkSpeed = Functions.GetCurrentSpeed() + (Value and Options.SpeedBoostSlider.Value or 0)
	end
end)
Toggles.EnableCharacterJump:OnChanged(function(Value)
	if Character then
		Character:SetAttribute("CanJump", Value and true or OldJump)
	end
end)
Toggles.EnableCharacterSlide:OnChanged(function(Value)
	if Character then
		Character:SetAttribute("CanSlide", Value and true or OldSlide)
	end
end)

Groupboxes.General_Self = Tabs.General:AddLeftGroupbox("Self")
Groupboxes.General_Self:AddToggle("DoorReachToggle", {
	Text = "Door Reach", Default = false, Tooltip = "Allows you to open doors from further away."
})
Groupboxes.General_Self:AddToggle("DisableIdleKick", {
	Text = "Disable Idle Kick", Default = false, Tooltip = "Prevents the kick from being idle for 20 minutes."
})
Toggles.DisableIdleKick:OnChanged(function(Value)
	if Functions.CheckCompatability({"getconnections"}) then
		for _, Conn in Abysall.Environment.getconnections(LocalPlayer.Idled) do
			if Value then Conn:Disable() else Conn:Enable() end
		end
	end
end)
LocalPlayer.Idled:Connect(function()
	if Toggles.DisableIdleKick.Value then
		Services.VirtualUser:CaptureController()
		Services.VirtualUser:ClickButton2(Vector2.new())
	end
end)

Groupboxes.General_Self:AddDivider()
Groupboxes.General_Self:AddSlider("PromptReachSlider", {
	Text = "Prompt Reach Multiplier", Min = 1, Max = 2, Default = 1, Rounding = 1, Compact = true
})
Groupboxes.General_Self:AddToggle("InstantPrompts", {
	Text = "Instant Prompts", Default = false, Tooltip = "Allows you to trigger all prompts instantly."
})
Groupboxes.General_Self:AddToggle("PromptClip", {
	Text = "Prompt Clip", Default = false, Tooltip = "Allows you to interact with prompts through walls."
})

Options.PromptReachSlider:OnChanged(function(Value)
	for _, Prompt in Objects.Prompts do
		if Prompt and Prompt.Parent then
			local oldDist = Prompt:GetAttribute("MaxActivationDistance_Old")
			if oldDist then
				Prompt.MaxActivationDistance = oldDist * Value
			end
		end
	end
end)
Toggles.InstantPrompts:OnChanged(function(Value)
	for _, Prompt in Objects.Prompts do
		if Prompt and Prompt.Parent then
			local oldHold = Prompt:GetAttribute("HoldDuration_Old")
			Prompt.HoldDuration = Value and 0 or (oldHold or Prompt.HoldDuration)
		end
	end
end)
Toggles.PromptClip:OnChanged(function(Value)
	for _, Prompt in Objects.Prompts do
		if Prompt and Prompt.Parent then
			local oldLOS = Prompt:GetAttribute("RequiresLineOfSight_Old")
			Prompt.RequiresLineOfSight = Value and false or (oldLOS ~= nil and oldLOS or Prompt.RequiresLineOfSight)
		end
	end
end)

Groupboxes.Self_Automation = Tabs.General:AddRightGroupbox("Automation")
Groupboxes.Self_Automation:AddToggle("AutoBreakerBox", {
	Text = "Auto Breaker Box", Default = false, Tooltip = "Automatically solves the breaker box."
})
Groupboxes.Self_Automation:AddToggle("AutoSolveAnchors", {
	Text = "Auto Solve Anchors", Default = false,
	Tooltip = "Automatically enters the correct code into anchors when you are near them."
})
Toggles.AutoBreakerBox:OnChanged(function(Value)
	if Value and CurrentRooms:FindFirstChild("ElevatorBreaker", true) then
		if not Globals.BreakerBoxInteracted then
			if not Globals.BreakerBoxNotified then
				Functions.Notify({ Title = "Interact with the breaker box.", Body = "It will be automatically solved." })
				Globals.BreakerBoxInteracted = true
			end
		else
			RemotesFolder.EBF:FireServer()
		end
	end
end)

Groupboxes.Self_Automation:AddToggle("AutoHeartbeatMinigame", { Text = "Auto Heartbeat Minigame", Default = false, Tooltip = "Prevents the 'Figure' minigame from ever failing.", Disabled = not Functions.CheckCompatability({"hookmetamethod", "newcclosure", "getnamecallmethod"}), DisabledTooltip = Globals.IncompatibleMessage })
Groupboxes.Self_Automation:AddDivider()
Groupboxes.Self_Automation:AddToggle("AutoUnlockPadlockToggle", {
	Text = "Auto Unlock Padlock", Default = false, Tooltip = "Automatically enters the code into the library padlock."
})
Groupboxes.Self_Automation:AddSlider("AutoUnlockPadlockSlider", {
	Text = "Unlock Distance", Min = 1, Max = 50, Default = 10, Rounding = 0, Compact = true
})
Groupboxes.Self_Automation:AddToggle("AutoLibraryGuessCode", {
	Text = "Guess Library Code", Default = false,
	Tooltip = "Attempts to guess the library code, but collecting some books is also necessary."
})
Groupboxes.Self_Automation:AddDivider()
Groupboxes.Self_Automation:AddToggle("AutoLibrary", {
	Text = "Auto Library", Default = false,
	Tooltip = "Automatically gets books and paper."
})
Groupboxes.Self_Automation:AddToggle("SkipSeekHotel", {
	Text = "Skip Seek (Hotel)",
	Default = false,
	Tooltip = "Skips the entire Seek sections.",
})
Groupboxes.Self_Automation:AddToggle("AutoBreakerRoom", {
	Text = "Auto Breaker Room",
	Default = false,
	Tooltip = "Automatically completes the breaker sequence in Hotel Room 100.",
})
Groupboxes.Self_Automation:AddDivider()
Toggles.AutoHotel = Groupboxes.Self_Automation:AddToggle("AutoHotel", {
	Text = "Auto Hotel",
	Tooltip = "Automatically progresses through the hotel floor.",
	Risky = Floor ~= "Ballz",
	Default = false
})
Toggles.AutoHotelIgnoreEntities = Groupboxes.Self_Automation:AddToggle("AutoHotelIgnoreEntities", {
	Text = "Ignore Entities",
	Tooltip = "Skip all entity waits and pauses.",
	Default = false
})
Groupboxes.Self_Automation:AddDivider()
Groupboxes.Self_Automation:AddToggle("AutoInteractToggle", {
	Text = "Auto Interact", Default = false, Tooltip = "Automatically triggers nearby prompts."
})
Toggles.AutoInteractToggle:AddKeyPicker("AutoInteractKeybind", {
    Text = "Auto Interact",
    Default = "R",
    Mode = "Toggle",
    SyncToggleState = true
})
Groupboxes.Self_Automation:AddDropdown("AutoInteractIgnoreList", {
	Text = "Ignore List",
	Values = { "Glitch Fragments", "Jeff Items", "Dropped Items", "Currency", "Minecarts", "Locks" },
	Default = { "Glitch Fragments", "Jeff Items", "Dropped Items" },
	Multi = true, AllowNull = true
})
Groupboxes.Self_Automation:AddDivider()
Groupboxes.Self_Automation:AddToggle("AutoClosetToggle", {
	Text = "Auto Closet", Default = false,
	Tooltip = "Automatically hides in a nearby closet when an entity is near."
})
Toggles.AutoClosetToggle:AddKeyPicker("AutoClosetKeybind", {
	Text = "Auto Closet", Default = "Q", Mode = "Toggle", SyncToggleState = true
})
Groupboxes.Self_Automation:AddDropdown("AutoClosetEntityList", {
	Text = "Ignore List",
	Values = { "Rush", "Ambush", "Blitz", "DronesStampede", "Scribbles", "A-60", "A-120", "AR0xMBUSH", "RNIUSHCG==" },
	Multi = true, AllowNull = true
})
Groupboxes.Self_Automation:AddToggle("SpectateEntityToggle", {
	Text = "Spectate Entity",
	Default = false,
	Tooltip = "Spectates the entity while auto hiding."
})
Groupboxes.Self_Automation:AddDropdown("SpecateEntityMode", {
	Values = {"Player to Entity", "Entity to Player"},
	Default = 1,
	AllowNull = true
})

Groupboxes.Self_Misc = Tabs.General:AddRightGroupbox("Miscellaneous")
Groupboxes.Self_Misc:AddButton({
	Text = "Play Again", Tooltip = "Makes you join a new run, click again to cancel.", DoubleClick = true,
	Func = function() RemotesFolder.PlayAgain:FireServer() end
})
Groupboxes.Self_Misc:AddButton({
	Text = "Return to Lobby", Tooltip = "Makes you teleport back to the lobby.", DoubleClick = true,
	Func = function() RemotesFolder.Lobby:FireServer() end
})
Groupboxes.Self_Misc:AddButton({
	Text = "Revive",
	Tooltip = "Makes you revive, if you have a revive and haven't already revived in this run.",
	DoubleClick = true,
	Func = function() RemotesFolder.Revive:FireServer() end
})
Groupboxes.Self_Misc:AddButton({
	Text = "Reset Character",
	Tooltip = "Kills your character on the server. (takes around 20 seconds if replicatesignal isn't supported)",
	DoubleClick = true,
	Func = function()
		Globals.SelfKilled = true
		if Functions.CheckCompatability({"replicatesignal"}) then
			Abysall.Environment.replicatesignal(LocalPlayer.Kill)
		else
			if RemotesFolder:FindFirstChild("Underwater") then
				RemotesFolder.Underwater:FireServer(true)
			else
				Humanoid.Health = 0
			end
		end
	end
})


Tabs.General:UpdateWarningBox({
	Visible = true,
	Title = "Risk Warning",
	Text = "Features highlighted in red are risky.",
})


Toggles.SkipSeekHotel:OnChanged(function(Value)
	if not Value then return end
	if Floor ~= "Hotel" then return end

	task.spawn(function()
		print("started")

		local currentRooms

		repeat
			if not Toggles.SkipSeekHotel.Value or Floor ~= "Hotel" then
				return
			end
			currentRooms = workspace:FindFirstChild("CurrentRooms")
			task.wait()
		until currentRooms

		print("got currentrooms")

		local lastTriggerRoom = nil

		while Toggles.SkipSeekHotel.Value and Floor == "Hotel" do
			local triggerRoom = nil

			print("waiting for trigger")

			repeat
				if not Toggles.SkipSeekHotel.Value or Floor ~= "Hotel" then
					return
				end

				currentRooms = workspace:FindFirstChild("CurrentRooms")
				local currentRoomNum = tonumber(LocalPlayer:GetAttribute("CurrentRoom"))

				if currentRoomNum and currentRoomNum ~= lastTriggerRoom then
					local room = currentRooms and currentRooms:FindFirstChild(tostring(currentRoomNum))
					if room then
						local trigger = room:WaitForChild("TriggerEventCollision", 0.5)
						if trigger then
							triggerRoom = currentRoomNum
							print("found trigger in", triggerRoom)
						end
					end
				end

				task.wait()
			until triggerRoom

			lastTriggerRoom = triggerRoom

			local roomNum = triggerRoom

			while Toggles.SkipSeekHotel.Value and Floor == "Hotel" do
				roomNum += 1
				print("looking for room", roomNum)

				local room
				repeat
					if not Toggles.SkipSeekHotel.Value or Floor ~= "Hotel" then
						return
					end
					currentRooms = workspace:FindFirstChild("CurrentRooms")
					room = currentRooms and currentRooms:FindFirstChild(tostring(roomNum))
					task.wait()
				until room

				print("found room", roomNum)

				local hasSeekArm = false
				local assets = room:FindFirstChild("Assets")
				if assets then
					for _, child in ipairs(assets:GetChildren()) do
						if child.Name == "Seek_Arm" then
							hasSeekArm = true
							print("found seek arm")
							break
						end
					end
				end

				local door
				repeat
					if not Toggles.SkipSeekHotel.Value or Floor ~= "Hotel" then
						return
					end
					door = room:FindFirstChild("Door", true)
					task.wait()
				until door

				print("found door, teleporting")

				repeat
					if not Toggles.SkipSeekHotel.Value or Floor ~= "Hotel" then
						return
					end
					if Character then
						Character:PivotTo(door:GetPivot())
					end
					task.wait()
				until door:GetAttribute("Opened") == true

				print("door opened")

				if hasSeekArm then
					if not Character then
						return
					end

					print("voiding")

					local voidCFrame = Character:GetPivot() + Vector3.new(0, -2500, 0)

					task.wait(0.25)

					for _ = 1, 20 do
						Character:PivotTo(voidCFrame)
						task.wait()
					end

					task.wait(0.3)

					for _ = 1, 15 do
						Character:PivotTo(voidCFrame)
						task.wait()
					end

					task.wait(0.2)

					for _ = 1, 10 do
						Character:PivotTo(voidCFrame)
						task.wait()
					end

					print("done voiding")
					break
				end
			end
		end
	end)
end)

Toggles.AutoLibrary:OnChanged(function(AutoLibraryEnabled)
	if AutoLibraryConnection then
		task.cancel(AutoLibraryConnection)
		AutoLibraryConnection = nil
	end

	if AutoLibraryRoomConnection then
		AutoLibraryRoomConnection:Disconnect()
		AutoLibraryRoomConnection = nil
	end

	if not AutoLibraryEnabled then
		return
	end

	AutoLibraryConnection = task.spawn(function()
		local AutoLibraryPlayers = game:GetService("Players")
		local AutoLibraryLocalPlayer = AutoLibraryPlayers.LocalPlayer
		local AutoLibraryCharacter = AutoLibraryLocalPlayer.Character or AutoLibraryLocalPlayer.CharacterAdded:Wait()
		local AutoLibraryHumanoidRootPart = AutoLibraryCharacter:WaitForChild("HumanoidRootPart")

		local AutoLibraryCurrentRooms = workspace:WaitForChild("CurrentRooms")
		local AutoLibraryRoom50 = AutoLibraryCurrentRooms:WaitForChild("50")
		local AutoLibraryLiveHintBooks = {}
		local AutoLibraryHintPaperObtained = false

		local function AutoLibraryIsInRoom50(AutoLibraryObject)
			return AutoLibraryObject
				and AutoLibraryObject:IsDescendantOf(AutoLibraryRoom50)
				and AutoLibraryObject:IsDescendantOf(AutoLibraryCurrentRooms)
				and AutoLibraryObject:IsDescendantOf(workspace)
		end

		local function AutoLibraryIsActuallyInRoom50()
			return tonumber(AutoLibraryLocalPlayer:GetAttribute("CurrentRoom")) == 50
		end

		while AutoLibraryEnabled and not AutoLibraryIsActuallyInRoom50() do
			task.wait(0.05)
		end

		if not AutoLibraryEnabled then
			return
		end

		local function AutoLibraryHasHintPaper()
			AutoLibraryCharacter = AutoLibraryLocalPlayer.Character

			if not AutoLibraryCharacter then
				return false
			end

			local AutoLibraryBackpackPaper = AutoLibraryLocalPlayer.Backpack:FindFirstChild("LibraryHintPaper", true)
			local AutoLibraryCharacterPaper = AutoLibraryCharacter:FindFirstChild("LibraryHintPaper", true)

			return AutoLibraryBackpackPaper ~= nil or AutoLibraryCharacterPaper ~= nil
		end

		local function AutoLibraryGetObjectCFrame(AutoLibraryObject)
			if not AutoLibraryIsActuallyInRoom50() then
				return nil
			end

			if not AutoLibraryIsInRoom50(AutoLibraryObject) then
				return nil
			end

			if AutoLibraryObject:IsA("Model") then
				return AutoLibraryObject:GetPivot()
			elseif AutoLibraryObject:IsA("BasePart") then
				return AutoLibraryObject.CFrame
			end

			local AutoLibraryObjectPart = AutoLibraryObject:FindFirstChildWhichIsA("BasePart", true)

			if AutoLibraryObjectPart then
				return AutoLibraryObjectPart.CFrame
			end

			return nil
		end

		local function AutoLibraryFindBooks(AutoLibraryObject)
			if not AutoLibraryIsActuallyInRoom50() then
				return
			end

			if not AutoLibraryIsInRoom50(AutoLibraryObject) then
				return
			end

			if AutoLibraryObject.Name == "LiveHintBook" then
				if not table.find(AutoLibraryLiveHintBooks, AutoLibraryObject) then
					table.insert(AutoLibraryLiveHintBooks, AutoLibraryObject)
				end
			end

			for _, AutoLibraryDescendant in ipairs(AutoLibraryObject:GetDescendants()) do
				if AutoLibraryDescendant.Name == "LiveHintBook"
					and AutoLibraryIsInRoom50(AutoLibraryDescendant) then

					if not table.find(AutoLibraryLiveHintBooks, AutoLibraryDescendant) then
						table.insert(AutoLibraryLiveHintBooks, AutoLibraryDescendant)
					end
				end
			end
		end

		for _, AutoLibraryDescendant in ipairs(AutoLibraryRoom50:GetDescendants()) do
			if not AutoLibraryEnabled or not AutoLibraryIsActuallyInRoom50() then
				return
			end

			if AutoLibraryDescendant.Name == "LiveHintBook"
				and AutoLibraryIsInRoom50(AutoLibraryDescendant) then

				if not table.find(AutoLibraryLiveHintBooks, AutoLibraryDescendant) then
					table.insert(AutoLibraryLiveHintBooks, AutoLibraryDescendant)
				end
			end
		end

		AutoLibraryRoomConnection = AutoLibraryRoom50.DescendantAdded:Connect(function(AutoLibraryAddedObject)
			if not AutoLibraryEnabled then
				return
			end

			if not AutoLibraryIsActuallyInRoom50() then
				return
			end

			if not AutoLibraryIsInRoom50(AutoLibraryAddedObject) then
				return
			end

			AutoLibraryFindBooks(AutoLibraryAddedObject)
		end)

		while AutoLibraryEnabled
			and AutoLibraryIsActuallyInRoom50()
			and #AutoLibraryLiveHintBooks < 3 do

			for _, AutoLibraryDescendant in ipairs(AutoLibraryRoom50:GetDescendants()) do
				if not AutoLibraryEnabled or not AutoLibraryIsActuallyInRoom50() then
					return
				end

				if AutoLibraryDescendant.Name == "LiveHintBook"
					and AutoLibraryIsInRoom50(AutoLibraryDescendant)
					and not table.find(AutoLibraryLiveHintBooks, AutoLibraryDescendant) then

					table.insert(AutoLibraryLiveHintBooks, AutoLibraryDescendant)
				end
			end

			if #AutoLibraryLiveHintBooks >= 3 then
				break
			end

			task.wait(0.05)
		end

		while AutoLibraryEnabled
			and AutoLibraryIsActuallyInRoom50()
			and not AutoLibraryHintPaperObtained do

			if AutoLibraryHasHintPaper() then
				AutoLibraryHintPaperObtained = true
				break
			end

			for AutoLibraryIndex = #AutoLibraryLiveHintBooks, 1, -1 do
				if not AutoLibraryIsActuallyInRoom50() then
					return
				end

				local AutoLibraryLiveHintBook = AutoLibraryLiveHintBooks[AutoLibraryIndex]

				if not AutoLibraryIsInRoom50(AutoLibraryLiveHintBook) then
					table.remove(AutoLibraryLiveHintBooks, AutoLibraryIndex)
					continue
				end

				while AutoLibraryEnabled
					and AutoLibraryIsActuallyInRoom50()
					and not AutoLibraryHintPaperObtained
					and AutoLibraryLiveHintBook.Parent
					and AutoLibraryIsInRoom50(AutoLibraryLiveHintBook) do

					if AutoLibraryHasHintPaper() then
						AutoLibraryHintPaperObtained = true
						break
					end

					AutoLibraryCharacter = AutoLibraryLocalPlayer.Character or AutoLibraryLocalPlayer.CharacterAdded:Wait()
					AutoLibraryHumanoidRootPart = AutoLibraryCharacter:FindFirstChild("HumanoidRootPart")

					if not AutoLibraryHumanoidRootPart then
						task.wait()
						continue
					end

					local AutoLibraryBookCFrame = AutoLibraryGetObjectCFrame(AutoLibraryLiveHintBook)

					if AutoLibraryBookCFrame
						and AutoLibraryIsActuallyInRoom50()
						and AutoLibraryIsInRoom50(AutoLibraryLiveHintBook) then

						AutoLibraryHumanoidRootPart.CFrame = AutoLibraryBookCFrame
					end

					for _, AutoLibraryPromptDescendant in ipairs(AutoLibraryLiveHintBook:GetDescendants()) do
						if AutoLibraryPromptDescendant:IsA("ProximityPrompt")
							and AutoLibraryIsInRoom50(AutoLibraryPromptDescendant)
							and AutoLibraryIsActuallyInRoom50() then

							fireproximityprompt(AutoLibraryPromptDescendant)
						end
					end

					task.wait(0.05)
				end

				if AutoLibraryHintPaperObtained then
					break
				end
			end

			if AutoLibraryHasHintPaper() then
				AutoLibraryHintPaperObtained = true
				break
			end

			local AutoLibraryHintPaper = AutoLibraryRoom50:FindFirstChild("LibraryHintPaper", true)

			if AutoLibraryHintPaper
				and AutoLibraryIsInRoom50(AutoLibraryHintPaper)
				and AutoLibraryIsActuallyInRoom50() then

				while AutoLibraryEnabled
					and AutoLibraryIsActuallyInRoom50()
					and not AutoLibraryHintPaperObtained
					and AutoLibraryHintPaper.Parent
					and AutoLibraryIsInRoom50(AutoLibraryHintPaper) do

					if AutoLibraryHasHintPaper() then
						AutoLibraryHintPaperObtained = true
						break
					end

					AutoLibraryCharacter = AutoLibraryLocalPlayer.Character or AutoLibraryLocalPlayer.CharacterAdded:Wait()
					AutoLibraryHumanoidRootPart = AutoLibraryCharacter:FindFirstChild("HumanoidRootPart")

					if not AutoLibraryHumanoidRootPart then
						task.wait()
						continue
					end

					local AutoLibraryPaperCFrame = AutoLibraryGetObjectCFrame(AutoLibraryHintPaper)

					if AutoLibraryPaperCFrame
						and AutoLibraryIsActuallyInRoom50()
						and AutoLibraryIsInRoom50(AutoLibraryHintPaper) then

						AutoLibraryHumanoidRootPart.CFrame = AutoLibraryPaperCFrame * CFrame.new(0, 5, 0)
					end

					for _, AutoLibraryPromptDescendant in ipairs(AutoLibraryHintPaper:GetDescendants()) do
						if AutoLibraryPromptDescendant:IsA("ProximityPrompt")
							and AutoLibraryIsInRoom50(AutoLibraryPromptDescendant)
							and AutoLibraryIsActuallyInRoom50() then

							fireproximityprompt(AutoLibraryPromptDescendant)
						end
					end

					task.wait(0.05)
				end
			end

			task.wait(0.05)
		end
	end)
end)

Toggles.AutoBreakerRoom:OnChanged(function(AutoBreakerRoomEnabled)
	if AutoBreakerRoomConnection then
		task.cancel(AutoBreakerRoomConnection)
		AutoBreakerRoomConnection = nil
	end

	if AutoBreakerRoomRoomConnection then
		AutoBreakerRoomRoomConnection:Disconnect()
		AutoBreakerRoomRoomConnection = nil
	end

	if not AutoBreakerRoomEnabled then
		return
	end

	local AutoBreakerRoomGateFireTime = 5
	local AutoBreakerRoomWaitAfterLever = 5
	local AutoBreakerRoomBreakerSecondTime = 10
	local AutoBreakerRoomWaitBeforeWeb = 4
	local AutoBreakerRoomWebDuration = 20

	AutoBreakerRoomConnection = task.spawn(function()
		local AutoBreakerRoomPlayers = game:GetService("Players")
		local AutoBreakerRoomCurrentRooms = workspace:WaitForChild("CurrentRooms")
		local AutoBreakerRoom100 = AutoBreakerRoomCurrentRooms:WaitForChild("100")

		local function AutoBreakerRoomIsActuallyInRoom100()
			return tonumber(AutoBreakerRoomPlayers.LocalPlayer:GetAttribute("CurrentRoom")) == 100
		end

		local function AutoBreakerRoomIsInRoom100(AutoBreakerRoomObject)
			return AutoBreakerRoomObject
				and AutoBreakerRoomObject.Parent
				and AutoBreakerRoomObject:IsDescendantOf(AutoBreakerRoom100)
				and AutoBreakerRoomObject:IsDescendantOf(AutoBreakerRoomCurrentRooms)
		end

		local function AutoBreakerRoomGetObjectCFrame(AutoBreakerRoomObject)
			if not AutoBreakerRoomIsActuallyInRoom100() or not AutoBreakerRoomIsInRoom100(AutoBreakerRoomObject) then
				return nil
			end

			if AutoBreakerRoomObject:IsA("Model") then
				return AutoBreakerRoomObject:GetPivot()
			elseif AutoBreakerRoomObject:IsA("BasePart") then
				return AutoBreakerRoomObject.CFrame
			end

			local AutoBreakerRoomPart = AutoBreakerRoomObject:FindFirstChildWhichIsA("BasePart", true)
			return AutoBreakerRoomPart and AutoBreakerRoomPart.CFrame
		end

		local function AutoBreakerRoomGetHRP()
			local AutoBreakerRoomCharacter = AutoBreakerRoomPlayers.LocalPlayer.Character
			return AutoBreakerRoomCharacter and AutoBreakerRoomCharacter:FindFirstChild("HumanoidRootPart")
		end

		local function AutoBreakerRoomActivate(AutoBreakerRoomObject)
			if not AutoBreakerRoomObject then
				return
			end

			if AutoBreakerRoomObject:IsA("ProximityPrompt") then
				fireproximityprompt(AutoBreakerRoomObject)
				return
			end

			for _, AutoBreakerRoomDescendant in ipairs(AutoBreakerRoomObject:GetDescendants()) do
				if AutoBreakerRoomDescendant:IsA("ProximityPrompt") then
					fireproximityprompt(AutoBreakerRoomDescendant)
				end
			end
		end

		local function AutoBreakerRoomConstantTPAndActivate(AutoBreakerRoomTarget, AutoBreakerRoomDuration, AutoBreakerRoomInterval, AutoBreakerRoomOffset)
			AutoBreakerRoomInterval = AutoBreakerRoomInterval or 0.04
			AutoBreakerRoomOffset = AutoBreakerRoomOffset or CFrame.new()
			local AutoBreakerRoomEndTime = os.clock() + (AutoBreakerRoomDuration or 3)

			while AutoBreakerRoomEnabled
				and AutoBreakerRoomIsActuallyInRoom100()
				and AutoBreakerRoomIsInRoom100(AutoBreakerRoomTarget)
				and os.clock() < AutoBreakerRoomEndTime do

				local AutoBreakerRoomHRP = AutoBreakerRoomGetHRP()
				local AutoBreakerRoomCF = AutoBreakerRoomGetObjectCFrame(AutoBreakerRoomTarget)

				if AutoBreakerRoomHRP and AutoBreakerRoomCF then
					AutoBreakerRoomHRP.CFrame = AutoBreakerRoomCF * AutoBreakerRoomOffset
				end

				AutoBreakerRoomActivate(AutoBreakerRoomTarget)
				task.wait(AutoBreakerRoomInterval)
			end
		end

		while AutoBreakerRoomEnabled do
			while AutoBreakerRoomEnabled and not AutoBreakerRoomIsActuallyInRoom100() do
				task.wait(0.1)
			end

			if not AutoBreakerRoomEnabled then
				return
			end

			local AutoBreakerRoomPoles = {}

			while AutoBreakerRoomEnabled and AutoBreakerRoomIsActuallyInRoom100() do
				AutoBreakerRoomPoles = {}

				for _, AutoBreakerRoomDescendant in ipairs(AutoBreakerRoom100:GetDescendants()) do
					if AutoBreakerRoomDescendant.Name == "LiveBreakerPolePickup" and AutoBreakerRoomIsInRoom100(AutoBreakerRoomDescendant) then
						if not table.find(AutoBreakerRoomPoles, AutoBreakerRoomDescendant) then
							table.insert(AutoBreakerRoomPoles, AutoBreakerRoomDescendant)
						end
					end
				end

				if #AutoBreakerRoomPoles == 0 then
					break
				end

				for _, AutoBreakerRoomPole in ipairs(AutoBreakerRoomPoles) do
					if not AutoBreakerRoomEnabled or not AutoBreakerRoomIsActuallyInRoom100() then
						break
					end

					if AutoBreakerRoomIsInRoom100(AutoBreakerRoomPole) then
						AutoBreakerRoomConstantTPAndActivate(AutoBreakerRoomPole, 2.8, 0.03)
						task.wait(0.12)
					end
				end

				task.wait(0.05)
			end

			if not AutoBreakerRoomEnabled or not AutoBreakerRoomIsActuallyInRoom100() then
				continue
			end

			local AutoBreakerRoomIndustrialGate = AutoBreakerRoom100:FindFirstChild("IndustrialGate")
			local AutoBreakerRoomBox = AutoBreakerRoomIndustrialGate and AutoBreakerRoomIndustrialGate:FindFirstChild("Box")
			local AutoBreakerRoomLever = AutoBreakerRoomBox and AutoBreakerRoomBox:FindFirstChild("Lever")
			local AutoBreakerRoomActivateEventPrompt = AutoBreakerRoomBox and AutoBreakerRoomBox:FindFirstChild("ActivateEventPrompt")

			if AutoBreakerRoomActivateEventPrompt and AutoBreakerRoomLever then
				local function AutoBreakerRoomGetLeverCFrame()
					if AutoBreakerRoomLever:IsA("Model") then
						return AutoBreakerRoomLever:GetPivot()
					elseif AutoBreakerRoomLever:IsA("BasePart") then
						return AutoBreakerRoomLever.CFrame
					end
					local AutoBreakerRoomPart = AutoBreakerRoomLever:FindFirstChildWhichIsA("BasePart", true)
					return AutoBreakerRoomPart and AutoBreakerRoomPart.CFrame
				end

				local AutoBreakerRoomInitialLeverCFrame = AutoBreakerRoomGetLeverCFrame()
				local AutoBreakerRoomLeverEndTime = os.clock() + 10

				while AutoBreakerRoomEnabled
					and AutoBreakerRoomIsActuallyInRoom100()
					and AutoBreakerRoomIsInRoom100(AutoBreakerRoomLever)
					and os.clock() < AutoBreakerRoomLeverEndTime do

					local AutoBreakerRoomCurrentLeverCFrame = AutoBreakerRoomGetLeverCFrame()

					if AutoBreakerRoomCurrentLeverCFrame and AutoBreakerRoomInitialLeverCFrame
						and AutoBreakerRoomCurrentLeverCFrame ~= AutoBreakerRoomInitialLeverCFrame then
						break
					end

					local AutoBreakerRoomHRP = AutoBreakerRoomGetHRP()
					local AutoBreakerRoomCF = AutoBreakerRoomGetObjectCFrame(AutoBreakerRoomBox)

					if AutoBreakerRoomHRP and AutoBreakerRoomCF then
						AutoBreakerRoomHRP.CFrame = AutoBreakerRoomCF
					end

					AutoBreakerRoomActivate(AutoBreakerRoomActivateEventPrompt)
					task.wait(0.04)
				end
			end

			if not AutoBreakerRoomEnabled or not AutoBreakerRoomIsActuallyInRoom100() then
				continue
			end

			task.wait(AutoBreakerRoomWaitAfterLever)

			if not AutoBreakerRoomEnabled or not AutoBreakerRoomIsActuallyInRoom100() then
				continue
			end

			local AutoBreakerRoomElevatorBreakerEmpty = AutoBreakerRoom100:FindFirstChild("ElevatorBreakerEmpty")
			if not AutoBreakerRoomElevatorBreakerEmpty then
				continue
			end

			local AutoBreakerRoomBreakerPrompt = AutoBreakerRoomElevatorBreakerEmpty:FindFirstChild("Prompt")
			if not AutoBreakerRoomBreakerPrompt then
				continue
			end

			local AutoBreakerRoomBreakerOffset = CFrame.new(0, -1.8, 0)

			while AutoBreakerRoomEnabled and AutoBreakerRoomIsActuallyInRoom100() do
				if AutoBreakerRoomElevatorBreakerEmpty:FindFirstChild("BreakerSwitchInBox") then
					break
				end

				local AutoBreakerRoomHRP = AutoBreakerRoomGetHRP()
				local AutoBreakerRoomCF = AutoBreakerRoomGetObjectCFrame(AutoBreakerRoomElevatorBreakerEmpty)

				if AutoBreakerRoomHRP and AutoBreakerRoomCF then
					AutoBreakerRoomHRP.CFrame = AutoBreakerRoomCF * AutoBreakerRoomBreakerOffset
				end

				AutoBreakerRoomActivate(AutoBreakerRoomBreakerPrompt)
				task.wait(0.04)
			end

			if not AutoBreakerRoomEnabled or not AutoBreakerRoomIsActuallyInRoom100() then
				continue
			end

			task.wait(10)

			AutoBreakerRoomConstantTPAndActivate(
				AutoBreakerRoomElevatorBreakerEmpty,
				AutoBreakerRoomBreakerSecondTime,
				0.04,
				AutoBreakerRoomBreakerOffset
			)

			task.wait(AutoBreakerRoomWaitBeforeWeb)

			if not AutoBreakerRoomEnabled or not AutoBreakerRoomIsActuallyInRoom100() then
				continue
			end

			local AutoBreakerRoomElevatorCar = AutoBreakerRoom100:FindFirstChild("ElevatorCar")
			local AutoBreakerRoomWeb = AutoBreakerRoomElevatorCar and AutoBreakerRoomElevatorCar:FindFirstChild("Web", true)

			if AutoBreakerRoomWeb then
				local AutoBreakerRoomEndTime = os.clock() + AutoBreakerRoomWebDuration

				while AutoBreakerRoomEnabled and AutoBreakerRoomIsActuallyInRoom100() and os.clock() < AutoBreakerRoomEndTime do
					local AutoBreakerRoomHRP = AutoBreakerRoomGetHRP()
					local AutoBreakerRoomCF = AutoBreakerRoomGetObjectCFrame(AutoBreakerRoomWeb)

					if AutoBreakerRoomHRP and AutoBreakerRoomCF then
						AutoBreakerRoomHRP.CFrame = AutoBreakerRoomCF
					end

					task.wait(0.04)
				end
			end

			while AutoBreakerRoomEnabled and AutoBreakerRoomIsActuallyInRoom100() do
				task.wait(0.5)
			end
		end
	end)
end)



do
local AutoHotelConnection
local AutoHotelLibraryConnection
local AutoHotelLibraryRoomConnection
local AutoHotelSeekConnection
local AutoHotelEntityPause = false
local AutoHotelRoomProcessTime = 0.5
local AutoHotelProcessedRooms = {}

local AutoHotelEntityNames = {
	["RushMoving"] = true,
	["Scribbles"] = true,
	["BashMoving"] = true,
	["DronesStampede"] = true,
	["AmbushMoving"] = true,
	["A60"] = true,
	["A120"] = true,
	["GlitchRush"] = true,
	["GlitchAmbush"] = true,
	["BackdoorRush"] = true,
	["CustomEntity"] = true,
}

local function AutoHotelIsEntityPresent()
	if Toggles.AutoHotelIgnoreEntities and Toggles.AutoHotelIgnoreEntities.Value then
		return false
	end
	for _, AutoHotelChild in ipairs(workspace:GetChildren()) do
		if AutoHotelEntityNames[AutoHotelChild.Name] then
			return true
		end
	end
	return false
end

local function AutoHotelWaitForEntities(AutoHotelSeconds)
	if Toggles.AutoHotelIgnoreEntities and Toggles.AutoHotelIgnoreEntities.Value then
		return
	end

	task.wait(AutoHotelSeconds or 5)

	while AutoHotelIsEntityPresent() do
		task.wait(0.15)
	end
end

local function AutoHotelGetNextClosedDoor()
	if not Character then return nil, nil end

	local AutoHotelGameData = game:GetService("ReplicatedStorage"):FindFirstChild("GameData")
	if not AutoHotelGameData then return nil, nil end

	local AutoHotelLatestRoom = AutoHotelGameData:FindFirstChild("LatestRoom")
	if not AutoHotelLatestRoom then return nil, nil end

	local AutoHotelStartRoom = AutoHotelLatestRoom.Value
	local AutoHotelBestDoor, AutoHotelBestNumber = nil, math.huge
	local AutoHotelCurrentRooms = workspace:FindFirstChild("CurrentRooms")

	if AutoHotelCurrentRooms then
		for _, AutoHotelRoom in ipairs(AutoHotelCurrentRooms:GetChildren()) do
			local AutoHotelRoomNum = tonumber(AutoHotelRoom.Name)
			if AutoHotelRoomNum and AutoHotelRoomNum ~= 100 and AutoHotelRoomNum >= AutoHotelStartRoom and AutoHotelRoomNum < AutoHotelBestNumber then
				local AutoHotelDoor = AutoHotelRoom:FindFirstChild("Door")
				if AutoHotelDoor and AutoHotelDoor:IsA("Model") then
					local AutoHotelOpenAttr = AutoHotelDoor:GetAttribute("Open")
					if AutoHotelOpenAttr == false or AutoHotelOpenAttr == nil then
						AutoHotelBestNumber = AutoHotelRoomNum
						AutoHotelBestDoor = AutoHotelDoor
					end
				end
			end
		end
	end

	return AutoHotelBestDoor, AutoHotelBestNumber
end

local function AutoHotelFindKeyObtain(AutoHotelRoom)
	local AutoHotelFound = nil
	local function AutoHotelScan(AutoHotelParent)
		if AutoHotelFound then return end
		for _, AutoHotelChild in ipairs(AutoHotelParent:GetChildren()) do
			if AutoHotelChild.Name == "KeyObtain" then
				AutoHotelFound = AutoHotelChild
				return
			end
			AutoHotelScan(AutoHotelChild)
			if AutoHotelFound then return end
		end
	end
	AutoHotelScan(AutoHotelRoom)
	return AutoHotelFound
end

local function AutoHotelHandleKey(AutoHotelRoomNum)
	local AutoHotelCurrentRooms = workspace:FindFirstChild("CurrentRooms")
	if not AutoHotelCurrentRooms then return false end

	local AutoHotelRoom = AutoHotelCurrentRooms:FindFirstChild(tostring(AutoHotelRoomNum))
	if not AutoHotelRoom then return false end

	local AutoHotelDoor = AutoHotelRoom:FindFirstChild("Door")
	if not AutoHotelDoor or not AutoHotelDoor:FindFirstChild("Lock") then
		return false
	end

	local AutoHotelKeyObtain = AutoHotelFindKeyObtain(AutoHotelRoom)
	if not AutoHotelKeyObtain then return false end

	local AutoHotelStart = tick()
	while tick() - AutoHotelStart < 12 do
		if LocalPlayer.Backpack:FindFirstChild("Key") or (Character and Character:FindFirstChild("Key")) then
			return true
		end

		if Character then
			Character:PivotTo(AutoHotelKeyObtain:GetPivot())
		end

		for _, AutoHotelDesc in ipairs(AutoHotelKeyObtain:GetDescendants()) do
			if AutoHotelDesc:IsA("ProximityPrompt") then
				fireproximityprompt(AutoHotelDesc)
			end
		end

		task.wait(0.12)
	end
	return false
end

local function AutoHotelProcessRoom(AutoHotelRoomNum)
	if AutoHotelProcessedRooms[AutoHotelRoomNum] then
		return
	end
	task.wait(AutoHotelRoomProcessTime)
	AutoHotelProcessedRooms[AutoHotelRoomNum] = true
end

local function AutoHotelRunLibrary()
	local AutoHotelCurrentRooms = workspace:WaitForChild("CurrentRooms")
	local AutoHotelRoom50 = AutoHotelCurrentRooms:WaitForChild("50")
	local AutoHotelLiveHintBooks = {}
	local AutoHotelHintPaperObtained = false

	local function AutoHotelIsInRoom50(AutoHotelObj)
		return AutoHotelObj and AutoHotelObj:IsDescendantOf(AutoHotelRoom50)
	end

	local function AutoHotelIsActuallyInRoom50()
		return tonumber(LocalPlayer:GetAttribute("CurrentRoom")) == 50
	end

	while Toggles.AutoHotel.Value and not AutoHotelIsActuallyInRoom50() do
		task.wait(0.1)
	end
	if not Toggles.AutoHotel.Value then return end

	AutoHotelWaitForEntities(5)

	local function AutoHotelHasHintPaper()
		local AutoHotelChar = LocalPlayer.Character
		if not AutoHotelChar then return false end
		return LocalPlayer.Backpack:FindFirstChild("LibraryHintPaper", true) or AutoHotelChar:FindFirstChild("LibraryHintPaper", true)
	end

	local function AutoHotelGetCFrame(AutoHotelObj)
		if not AutoHotelIsActuallyInRoom50() or not AutoHotelIsInRoom50(AutoHotelObj) then return nil end
		if AutoHotelObj:IsA("Model") then return AutoHotelObj:GetPivot() end
		if AutoHotelObj:IsA("BasePart") then return AutoHotelObj.CFrame end
		local AutoHotelPart = AutoHotelObj:FindFirstChildWhichIsA("BasePart", true)
		return AutoHotelPart and AutoHotelPart.CFrame
	end

	local function AutoHotelCollectBooks()
		for _, AutoHotelDesc in ipairs(AutoHotelRoom50:GetDescendants()) do
			if AutoHotelDesc.Name == "LiveHintBook" and AutoHotelIsInRoom50(AutoHotelDesc) and not table.find(AutoHotelLiveHintBooks, AutoHotelDesc) then
				table.insert(AutoHotelLiveHintBooks, AutoHotelDesc)
			end
		end
	end

	AutoHotelCollectBooks()

	AutoHotelLibraryRoomConnection = AutoHotelRoom50.DescendantAdded:Connect(function(AutoHotelAdded)
		if Toggles.AutoHotel.Value and AutoHotelIsActuallyInRoom50() and AutoHotelIsInRoom50(AutoHotelAdded) then
			if AutoHotelAdded.Name == "LiveHintBook" and not table.find(AutoHotelLiveHintBooks, AutoHotelAdded) then
				table.insert(AutoHotelLiveHintBooks, AutoHotelAdded)
			end
		end
	end)

	while Toggles.AutoHotel.Value and AutoHotelIsActuallyInRoom50() and #AutoHotelLiveHintBooks < 3 do
		AutoHotelCollectBooks()
		if #AutoHotelLiveHintBooks >= 3 then break end
		task.wait(0.1)
	end

	while Toggles.AutoHotel.Value and AutoHotelIsActuallyInRoom50() and not AutoHotelHintPaperObtained do
		if AutoHotelHasHintPaper() then
			AutoHotelHintPaperObtained = true
			break
		end

		for AutoHotelIndex = #AutoHotelLiveHintBooks, 1, -1 do
			local AutoHotelBook = AutoHotelLiveHintBooks[AutoHotelIndex]
			if not AutoHotelIsInRoom50(AutoHotelBook) then
				table.remove(AutoHotelLiveHintBooks, AutoHotelIndex)
				continue
			end

			while Toggles.AutoHotel.Value and AutoHotelIsActuallyInRoom50() and not AutoHotelHintPaperObtained and AutoHotelBook.Parent and AutoHotelIsInRoom50(AutoHotelBook) do
				if AutoHotelHasHintPaper() then
					AutoHotelHintPaperObtained = true
					break
				end

				local AutoHotelChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
				local AutoHotelHRP = AutoHotelChar:FindFirstChild("HumanoidRootPart")
				if not AutoHotelHRP then
					task.wait()
					continue
				end

				local AutoHotelCF = AutoHotelGetCFrame(AutoHotelBook)
				if AutoHotelCF then
					AutoHotelHRP.CFrame = AutoHotelCF
				end

				for _, AutoHotelPrompt in ipairs(AutoHotelBook:GetDescendants()) do
					if AutoHotelPrompt:IsA("ProximityPrompt") then
						fireproximityprompt(AutoHotelPrompt)
					end
				end
				task.wait(0.08)
			end
			if AutoHotelHintPaperObtained then break end
		end

		if AutoHotelHasHintPaper() then
			AutoHotelHintPaperObtained = true
			break
		end

		local AutoHotelPaper = AutoHotelRoom50:FindFirstChild("LibraryHintPaper", true)
		if AutoHotelPaper and AutoHotelIsInRoom50(AutoHotelPaper) then
			while Toggles.AutoHotel.Value and AutoHotelIsActuallyInRoom50() and not AutoHotelHintPaperObtained and AutoHotelPaper.Parent do
				if AutoHotelHasHintPaper() then
					AutoHotelHintPaperObtained = true
					break
				end

				local AutoHotelChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
				local AutoHotelHRP = AutoHotelChar:FindFirstChild("HumanoidRootPart")
				if AutoHotelHRP then
					local AutoHotelCF = AutoHotelGetCFrame(AutoHotelPaper)
					if AutoHotelCF then
						AutoHotelHRP.CFrame = AutoHotelCF * CFrame.new(0, 5, 0)
					end
				end

				for _, AutoHotelPrompt in ipairs(AutoHotelPaper:GetDescendants()) do
					if AutoHotelPrompt:IsA("ProximityPrompt") then
						fireproximityprompt(AutoHotelPrompt)
					end
				end
				task.wait(0.08)
			end
		end
		task.wait(0.1)
	end
end

local function AutoHotelHandleSeek()
	local AutoHotelLastTriggerRoom = nil

	while Toggles.AutoHotel.Value do
		local AutoHotelCurrentRooms = workspace:FindFirstChild("CurrentRooms")
		if not AutoHotelCurrentRooms then
			task.wait(0.2)
			continue
		end

		local TriggerRoomNum = nil

		for _, Room in ipairs(AutoHotelCurrentRooms:GetChildren()) do
			local Num = tonumber(Room.Name)
			if Num and Num ~= AutoHotelLastTriggerRoom then
				local Trigger = Room:FindFirstChild("TriggerEventCollision")
					or Room:FindFirstChild("TriggerEventCollision", true)

				if Trigger then
					TriggerRoomNum = Num
					break
				end
			end
		end

		if not TriggerRoomNum then
			task.wait(0.15)
			continue
		end

		AutoHotelLastTriggerRoom = TriggerRoomNum

		AutoHotelEntityPause = true
		AutoHotelWaitForEntities(10)
		AutoHotelEntityPause = false
	end
end

Toggles.AutoHotel:OnChanged(function(AutoHotelEnabled)
	if AutoHotelConnection then
		task.cancel(AutoHotelConnection)
		AutoHotelConnection = nil
	end
	if AutoHotelLibraryConnection then
		task.cancel(AutoHotelLibraryConnection)
		AutoHotelLibraryConnection = nil
	end
	if AutoHotelLibraryRoomConnection then
		AutoHotelLibraryRoomConnection:Disconnect()
		AutoHotelLibraryRoomConnection = nil
	end
	if AutoHotelSeekConnection then
		task.cancel(AutoHotelSeekConnection)
		AutoHotelSeekConnection = nil
	end

	AutoHotelEntityPause = false
	table.clear(AutoHotelProcessedRooms)

	if not AutoHotelEnabled then return end

	if Options.AutoHotelRoomProcess then
		AutoHotelRoomProcessTime = Options.AutoHotelRoomProcess.Value
		Options.AutoHotelRoomProcess:OnChanged(function(Value)
			AutoHotelRoomProcessTime = Value
		end)
	end

	local AutoHotelCurrentRooms = workspace:FindFirstChild("CurrentRooms")
	if AutoHotelCurrentRooms then
		AutoHotelCurrentRooms.ChildAdded:Connect(function(AutoHotelChild)
			local AutoHotelNum = tonumber(AutoHotelChild.Name)
			if AutoHotelNum then
				AutoHotelProcessRoom(AutoHotelNum)
			end
		end)
	end

	AutoHotelSeekConnection = task.spawn(AutoHotelHandleSeek)

	task.spawn(function()
		while Toggles.AutoHotel.Value do
			if AutoHotelIsEntityPresent() then
				AutoHotelEntityPause = true
				while AutoHotelIsEntityPresent() and Toggles.AutoHotel.Value do
					task.wait(0.15)
				end
				AutoHotelEntityPause = false
			end
			task.wait(0.2)
		end
	end)

	AutoHotelConnection = task.spawn(function()
		while Toggles.AutoHotel.Value do
			if AutoHotelEntityPause then
				task.wait(0.1)
				continue
			end

			local AutoHotelDoor, AutoHotelRoomNum = AutoHotelGetNextClosedDoor()

			if AutoHotelDoor and AutoHotelRoomNum and Character then
				if AutoHotelRoomNum == 50 then
					if not AutoHotelLibraryConnection then
						AutoHotelLibraryConnection = task.spawn(function()
							AutoHotelRunLibrary()
							AutoHotelLibraryConnection = nil
						end)
					end
					task.wait(0.4)
				else
					AutoHotelProcessRoom(AutoHotelRoomNum)
					AutoHotelHandleKey(AutoHotelRoomNum)
					if Character and not AutoHotelEntityPause then
						Character:PivotTo(AutoHotelDoor:GetPivot() * CFrame.new(0, -1, 0))
					end
				end
			end
			task.wait(0.15)
		end
	end)
end)
end


Groupboxes.Debug = Tabs.General:AddRightGroupbox("Debug")
Groupboxes.Debug:AddButton({
	Text = "Ladder Softlock Fix",
	Tooltip = "Ladder Softlock Fix.",
	Func = function()
   		LocalPlayer:SetAttribute("Climbing", false)
	end
})
Groupboxes.Debug:AddButton({
	Text = "Get Current Floor",
	Tooltip = "Prints the current floor to the console.",
	Func = function()
		print("Current Floor:", GameData:WaitForChild("Floor").Value)
	end
})
Groupboxes.Debug:AddButton({
	Text = "Get Current Room",
	Tooltip = "Prints the current room number to the console.",
	Func = function()
		print("Current Room:", LocalPlayer:GetAttribute("CurrentRoom"))
	end
})
Groupboxes.Debug:AddButton({
	Text = "Void",
	Tooltip = "Teleports your character to Y -120.",
	Func = function()
		if not Character then return end
		local Pivot = Character:GetPivot()
		-- Too lazy to loop this
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
	end
})
Groupboxes.Debug:AddButton({
	Text = "Death",
	Tooltip = "Death",
	Func = function()
		Globals.Deathing = true
		LocalPlayer.Character.Humanoid.Health = 0
	end
})
Groupboxes.Debug:AddButton({
	Text = "Exit Closet",
	Tooltip = "Exits the current closet.",
	Func = function()
		if RemotesFolder and RemotesFolder:FindFirstChild("CamLock") then
			RemotesFolder.CamLock:FireServer()
		end
	end
})
local TpNextDoorConnection

local function getNextClosedDoor()
	if not Character then return nil end

	local GameData = game:GetService("ReplicatedStorage"):FindFirstChild("GameData")
	if not GameData then return nil end

	local LatestRoom = GameData:FindFirstChild("LatestRoom")
	if not LatestRoom then return nil end

	local startRoom = LatestRoom.Value
	local bestDoor = nil
	local bestNumber = math.huge

	local function checkDoor(obj)
		if obj and obj.Name == "Door" and obj:IsA("Model") then
			local openAttr = obj:GetAttribute("Open")
			if openAttr == false or openAttr == nil then
				local roomModel = obj.Parent
				local roomNum = tonumber(roomModel and roomModel.Name)

				if roomNum and roomNum >= startRoom and roomNum < bestNumber then
					bestNumber = roomNum
					bestDoor = obj
				end
			end
		end
	end

	if Objects and Objects.Doors and #Objects.Doors > 0 then
		for _, door in ipairs(Objects.Doors) do
			checkDoor(door)
		end
		if bestDoor then return bestDoor end
	end

	local roomsContainer = CurrentRooms or Services.Workspace:FindFirstChild("CurrentRooms")
	local searchContainer = roomsContainer or workspace
	for _, obj in ipairs(searchContainer:GetDescendants()) do
		checkDoor(obj)
	end

	return bestDoor
end

Groupboxes.Debug:AddButton({
	Text = "Tp Next Door",
	Tooltip = "Teleports you to the next sequential unopened door.",
	Func = function()
		local door = getNextClosedDoor()
		if door then
			Character:PivotTo(door:GetPivot() * CFrame.new(0, -1, 0))
		end
	end
})

Toggles.TpNextDoor = Groupboxes.Debug:AddToggle("TpNextDoor", {
	Text = "Auto Tp Next Door",
	Tooltip = "Continuously teleports you to the next sequential unopened door.",
	Default = false
})

Toggles.TpNextDoor:OnChanged(function(TpNextDoorEnabled)
	if TpNextDoorConnection then
		task.cancel(TpNextDoorConnection)
		TpNextDoorConnection = nil
	end

	if not TpNextDoorEnabled then
		return
	end

	TpNextDoorConnection = task.spawn(function()
		while Toggles.TpNextDoor.Value do
			local door = getNextClosedDoor()
			if door and Character then
				Character:PivotTo(door:GetPivot() * CFrame.new(0, -1, 0))
			end
			task.wait(0.15)
		end
		TpNextDoorConnection = nil
	end)
end)


Groupboxes.Exploits_Bypass = Tabs.Exploits:AddLeftGroupbox("Bypass / Solve")

Groupboxes.Exploits_Bypass:AddToggle("BypassGiggle",         { Text = "Bypass Giggle",           Default = false, Tooltip = "Prevents 'Giggle' from attacking you." })
Groupboxes.Exploits_Bypass:AddToggle("BypassDupe",           { Text = "Bypass Dupe",             Default = false, Tooltip = "Prevents you from open 'Dupe' fake doors." })
Groupboxes.Exploits_Bypass:AddToggle("BypassEyes",           { Text = "Bypass Eyes",             Default = false, Tooltip = "Prevents 'Eyes' from hurting you." })
Groupboxes.Exploits_Bypass:AddToggle("BypassLookman",        { Text = "Bypass Lookman",          Default = false, Tooltip = "Prevents 'Lookman' from hurting you." })
Groupboxes.Exploits_Bypass:AddToggle("BypassGloombatEggs",   { Text = "Bypass Gloombat Eggs",    Default = false, Tooltip = "Prevents taking damage from stepping on 'Gloombat' eggs." })
Groupboxes.Exploits_Bypass:AddToggle("BypassSeekObstructions", { Text = "Bypass Seek Obstructions", Default = false, Tooltip = "Prevents obstacles in the 'Seek' chase from harming you." })
Groupboxes.Exploits_Bypass:AddToggle("BypassVacuum",         { Text = "Bypass Vacuum",           Default = false, Tooltip = "Prevents you from falling into 'Vacuum' fake doors." })
Groupboxes.Exploits_Bypass:AddToggle("BypassKillbricks",     { Text = "Bypass Killbricks",       Default = false, Tooltip = "Prevents 'Lava' from hurting you." })
Groupboxes.Exploits_Bypass:AddToggle("BypassSeekingWall",    { Text = "Bypass Seeking Wall",     Default = false, Tooltip = "Prevents 'ScaryWall' from hurting you." })
Groupboxes.Exploits_Bypass:AddToggle("BypassSnare",          { Text = "Bypass Snare",            Default = false, Tooltip = "Prevents 'Snare' from trapping you." })
Groupboxes.Exploits_Bypass:AddToggle("BypassBanana",         { Text = "Bypass Banana",           Default = false, Tooltip = "Prevents 'Banana Peel' from slipping you up (sometimes doesn't work)." })
Groupboxes.Exploits_Bypass:AddToggle("BypassJeff",           { Text = "Bypass Jeff",             Default = false, Tooltip = "Prevents 'Jeff the Killer' from stabbing you (sometimes doesn't work)." })
Groupboxes.Exploits_Skip = Tabs.Exploits:AddLeftGroupbox("Skip")
Groupboxes.Exploits_Skip:AddToggle("SkipGateRooms",        { Text = "Skip Gate Rooms",         Default = false, Tooltip = "Automatically teleports you to the next door when entering a room with a Gate until the door opens (Hotel only)." })


do
	local isSkippingGate = false
	local skipGateTask = nil
	local skippedGateRooms = {}

	local function IsHotelFloor()
		local currentFloor = (GameData and GameData:FindFirstChild("Floor") and GameData.Floor.Value) or Floor
		return currentFloor == "Hotel" or currentFloor == "OldHotel"
	end

	local function IsGateRoom(room)
		if not room or not room:IsA("Model") then return false end
		if room.Name == "100" or tonumber(room.Name) == 100 then return false end

		-- Проверка рычагов и моделей решеток в отеле
		if room:FindFirstChild("LeverForGate", true)
			or room:FindFirstChild("Gate", true)
			or room:FindFirstChild("ThingToOpen", true)
			or room:FindFirstChild("BasementGate", true) then
			return true
		end

		-- Проверка в папке Assets
		local assets = room:FindFirstChild("Assets")
		if assets then
			for _, child in ipairs(assets:GetChildren()) do
				local name = child.Name
				if name == "Gate" or name == "LeverForGate" or name == "ThingToOpen" or name:find("Gate") then
					return true
				end
			end
		end

		-- Прямые дочерние элементы комнаты
		for _, child in ipairs(room:GetChildren()) do
			local name = child.Name
			if name == "Gate" or name == "LeverForGate" or name == "ThingToOpen" then
				return true
			end
		end

		return false
	end

	local function IsDoorOpened(door)
		if not door or not door.Parent then return true end
		if door:GetAttribute("Opened") == true or door:GetAttribute("Open") == true then
			return true
		end
		return false
	end

	local function GetRoomDoor(roomNum)
		local roomsContainer = CurrentRooms or Services.Workspace:FindFirstChild("CurrentRooms")
		if roomsContainer then
			local room = roomsContainer:FindFirstChild(tostring(roomNum))
			if room then
				local d = room:FindFirstChild("Door")
				if d and d:IsA("Model") then
					return d
				end
			end
			local nextRoom = roomsContainer:FindFirstChild(tostring(roomNum + 1))
			if nextRoom then
				local d = nextRoom:FindFirstChild("Door")
				if d and d:IsA("Model") then
					return d
				end
			end
		end
		if Objects and Objects.Doors then
			for _, d in ipairs(Objects.Doors) do
				if d and d.Parent then
					local pNum = tonumber(d.Parent.Name)
					if pNum == roomNum or pNum == roomNum + 1 then
						return d
					end
				end
			end
		end
		if getNextClosedDoor then
			return getNextClosedDoor()
		end
		return nil
	end

	local function ProcessGateRoom(roomNum)
		if tonumber(roomNum) == 100 then return end
		if skippedGateRooms[roomNum] then return end
		if isSkippingGate then return end
		if not Toggles.SkipGateRooms or not Toggles.SkipGateRooms.Value then return end
		if not IsHotelFloor() then return end

		local curNum = tonumber(LocalPlayer:GetAttribute("CurrentRoom"))
		if curNum and curNum > roomNum then
			skippedGateRooms[roomNum] = true
			return
		end

		local roomsContainer = CurrentRooms or Services.Workspace:FindFirstChild("CurrentRooms")
		if not roomsContainer then return end

		local room = roomsContainer:FindFirstChild(tostring(roomNum))
		if not room or not IsGateRoom(room) then return end

		isSkippingGate = true
		if skipGateTask then
			task.cancel(skipGateTask)
			skipGateTask = nil
		end

		skipGateTask = task.spawn(function()
			local startTime = tick()

			while Toggles.SkipGateRooms.Value and IsHotelFloor() and (tick() - startTime < 45) do
				local cur = tonumber(LocalPlayer:GetAttribute("CurrentRoom"))
				if cur and cur > roomNum then
					skippedGateRooms[roomNum] = true
					break
				end

				local door = GetRoomDoor(roomNum)
				if not door or not door.Parent then
					door = getNextClosedDoor and getNextClosedDoor() or nil
				end

				if not door or not door.Parent then
					break
				end

				local char = Character or (LocalPlayer and LocalPlayer.Character)
				if char then
					local doorPivot = door:GetPivot()
					local isOpened = IsDoorOpened(door)

					if isOpened then
						-- Дверь открыта: гарантированно перемещаем игрока вперед сквозь проем в следующую комнату
						local nextRoom = roomsContainer and roomsContainer:FindFirstChild(tostring(roomNum + 1))
						local targetCFrame = nil

						if nextRoom then
							local nextPos = nextRoom:GetPivot().Position
							local doorPos = doorPivot.Position
							local dir = Vector3.new(nextPos.X - doorPos.X, 0, nextPos.Z - doorPos.Z)
							if dir.Magnitude > 1 then
								local forwardDir = dir.Unit
								local targetPos = doorPos + forwardDir * 5 + Vector3.new(0, -1, 0)
								targetCFrame = CFrame.new(targetPos, targetPos + forwardDir)
							end
						end

						if not targetCFrame then
							targetCFrame = doorPivot * CFrame.new(0, -1, -5)
						end

						char:PivotTo(targetCFrame)
					else
						-- Дверь закрыта: стоим прямо у двери и открываем
						char:PivotTo(doorPivot * CFrame.new(0, -1, 0))
						pcall(function() door.ClientOpen:Fire() end)
						pcall(function() door.ClientOpen:FireServer() end)
					end
				end

				task.wait(0.12)
			end

			-- Помечаем комнату пройденной ТОЛЬКО если игрок действительно оказался в следующей комнате
			local finalCur = tonumber(LocalPlayer:GetAttribute("CurrentRoom"))
			if finalCur and finalCur > roomNum then
				skippedGateRooms[roomNum] = true
			end

			isSkippingGate = false
			skipGateTask = nil
		end)
	end

	Toggles.SkipGateRooms:OnChanged(function(Value)
		if not Value then
			isSkippingGate = false
			if skipGateTask then
				task.cancel(skipGateTask)
				skipGateTask = nil
			end
			return
		end

		table.clear(skippedGateRooms)
		if not IsHotelFloor() then return end

		local curNum = tonumber(LocalPlayer:GetAttribute("CurrentRoom"))
		if curNum then
			ProcessGateRoom(curNum)
		end
	end)

	if Connections.SkipGateRooms then
		Connections.SkipGateRooms:Disconnect()
		Connections.SkipGateRooms = nil
	end

	Connections.SkipGateRooms = LocalPlayer:GetAttributeChangedSignal("CurrentRoom"):Connect(function()
		if Toggles.SkipGateRooms and Toggles.SkipGateRooms.Value and IsHotelFloor() then
			local curNum = tonumber(LocalPlayer:GetAttribute("CurrentRoom"))
			if curNum then
				if curNum <= 1 then
					-- Сброс при новом забеге
					table.clear(skippedGateRooms)
				else
					-- Помечаем все пройденные позади комнаты, чтобы при возврате не тпхало
					for r = 0, curNum - 1 do
						skippedGateRooms[r] = true
					end
				end

				if not skippedGateRooms[curNum] then
					ProcessGateRoom(curNum)
				end
			end
		end
	end)

	-- Периодическая проверка на случай поздней догрузки ассетов комнаты (только на этаже Hotel)
	task.spawn(function()
		while true do
			task.wait(0.6)
			if Toggles.SkipGateRooms and Toggles.SkipGateRooms.Value and IsHotelFloor() and not isSkippingGate then
				local curNum = tonumber(LocalPlayer:GetAttribute("CurrentRoom"))
				if curNum then
					if curNum <= 1 then
						table.clear(skippedGateRooms)
					else
						for r = 0, curNum - 1 do
							skippedGateRooms[r] = true
						end
					end

					if not skippedGateRooms[curNum] then
						ProcessGateRoom(curNum)
					end
				end
			end
		end
	end)
end

Toggles.BypassGiggle:OnChanged(function(Value)
	for _, Object in Objects.Entities do
		if Object.Name == "GiggleCeiling" then
			Object:WaitForChild("Hitbox").CanTouch = not Value
		end
	end
end)
Toggles.BypassDupe:OnChanged(function(Value)
	for _, Object in Objects.Entities do
		if Object.Name == "DoorFake" or Object.Name == "FakeDoor" then
			Object:WaitForChild("Hidden").CanTouch = not Value
			if Object:FindFirstChild("Lock") then
				Object.Lock.UnlockPrompt.Enabled = not Value
			end
		end
	end
end)
Toggles.BypassEyes:OnChanged(function(Value)
	if Value and Globals.IsEyes then
		if Floor == "Fools" or Floor == "OldHotel" then
			RemotesFolder.MotorReplication:FireServer(0, (Globals.SpoofOffset == 200 and 65 or -65), 0, false)
		else
			RemotesFolder.MotorReplication:FireServer(-650)
		end
	end
end)
Toggles.BypassLookman:OnChanged(function(Value)
	if Value and Globals.IsLookman then
		if Floor == "Fools" or Floor == "OldHotel" then
			RemotesFolder.MotorReplication:FireServer(0, (Globals.SpoofOffset == 200 and 65 or -65), 0, false)
		else
			RemotesFolder.MotorReplication:FireServer(-650)
		end
	end
end)
Toggles.BypassGloombatEggs:OnChanged(function(Value)
	for _, Object in Objects.Entities do
		for _, Part in Object:GetDescendants() do
			if Part:IsA("BasePart") then
				Part.CanTouch = not Value
			end
		end
	end
end)
Toggles.BypassSeekObstructions:OnChanged(function(Value)
	for _, Object in Objects.SeekObstructions do
		Object.CanTouch = not Value
		if Object.Name == "SeekFloodline" then
			Object.CanCollide = Value
		end
	end
	for _, Object in Objects.SeekBridges do
		Object.CanCollide = Value
		Object.Transparency = Value and 0 or 1
	end
end)
Toggles.BypassVacuum:OnChanged(function(Value)
	for _, Object in Objects.Entities do
		if Object.Name == "SideroomSpace" then
			Object:WaitForChild("Collision").CanCollide = Value
			Object:WaitForChild("Collision").CanTouch = not Value
		end
	end
end)
Toggles.BypassKillbricks:OnChanged(function(Value)
	for _, Object in Objects.Obstructions do
		if Object.Name == "Lava" then Object.CanTouch = not Value end
	end
end)
Toggles.BypassSeekingWall:OnChanged(function(Value)
	for _, Object in Objects.Obstructions do
		if Object.Name == "ScaryWall" then
			for _, Part in Object:GetDescendants() do
				if Part:IsA("BasePart") then
					Part.CanTouch = not Value
					Part.CanCollide = not Value
				end
			end
		end
	end
end)
Toggles.BypassSnare:OnChanged(function(Value)
	for _, Object in Objects.Entities do
		if Object.Name == "Snare" then
			for _, Part in Object:GetDescendants() do
				if Part:IsA("BasePart") then Part.CanTouch = not Value end
			end
		end
	end
end)
Toggles.BypassBanana:OnChanged(function(Value)
	for _, Object in Objects.Entities do
		if Object.Name == "BananaPeel" then Object.CanTouch = not Value end
	end
end)
Toggles.BypassJeff:OnChanged(function(Value)
	for _, Object in Objects.Entities do
		if Object.Name == "JeffTheKiller" then
			for _, Part in Object:GetDescendants() do
				if Part:IsA("BasePart") then
					Part.CanCollide = not Value
					Part.CanTouch = not Value
				end
			end
			Object:WaitForChild("Humanoid").Health = 0
		end
	end
end)







-- Archives

Groupboxes.Archives_Misc = Tabs.Archives:AddRightGroupbox("Exploits / Anti")
Groupboxes.Archives_Misc:AddToggle("AntiRansom", { Text = "Anti Ransom", Default = false, Tooltip = "Prevents 'Ransom' from attacking you." })
Groupboxes.Archives_Misc:AddToggle("AntiClosetTrash", { Text = "Anti Closet Trash", Default = false, Tooltip = "Prevents 'Closet Trash' from spawning." })
Groupboxes.Archives_Misc:AddToggle("ForgetMeNotSolver", { Text = "Forget Me Not Skipper", Default = false, Tooltip = "Automatically Skippes Forget Me Not doors." })
Groupboxes.Archives_Misc:AddToggle("TimeShower", { Text = "Time Shower", Default = false, Tooltip = "Shows the Archives clock time." })
Groupboxes.Archives_Misc:AddToggle("BypassDronesStampede", { Text = "Stop Time/Anti Stampede", Default = false, Tooltip = "Prevents 'The Drones Stampede' from attacking you." })
Groupboxes.Archives_Misc:AddToggle("HonchoCorrectBoxESP", { Text = "Correct Box ESP/Auto Interact", Default = false, Tooltip = "ESP correct Archives boxes in the Honcho sequence and automatically interact with the correct deposit." })

TimeShowerLabel = Instance.new("TextLabel")
TimeShowerLabel.Name = "TimeShower"
TimeShowerLabel.AnchorPoint = Vector2.new(0, 1)
TimeShowerLabel.Position = UDim2.new(0, 12, 1, -12)
TimeShowerLabel.Size = UDim2.new(0, 180, 0, 32)
TimeShowerLabel.BackgroundTransparency = 1
TimeShowerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TimeShowerLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
TimeShowerLabel.TextStrokeTransparency = 0.35
TimeShowerLabel.Font = Enum.Font.GothamBold
TimeShowerLabel.TextSize = 18
TimeShowerLabel.TextXAlignment = Enum.TextXAlignment.Left
TimeShowerLabel.Text = "Time: --:--"
TimeShowerLabel.Visible = false
TimeShowerLabel.Parent = Container



local function GetArchivesClockLabel(Room)
	local Assets = Room and Room:FindFirstChild("Assets", true)
	local Clock = Assets and Assets:FindFirstChild("ArchivesClock", true)
	local Time = Clock and Clock:FindFirstChild("Time", true)
	local TextLabel = Time and Time:FindFirstChild("TextLabel")
	return (TextLabel and TextLabel:IsA("TextLabel")) and TextLabel or nil
end

local function ResolveClockLabel()
	if TimeShowerSourceLabel and TimeShowerSourceLabel.Parent and TimeShowerSourceLabel:IsDescendantOf(game) then
		return TimeShowerSourceLabel
	end
	local currentRooms = workspace:FindFirstChild("CurrentRooms")
	if not currentRooms then return nil end
	local rooms = {}
	for _, room in ipairs(currentRooms:GetChildren()) do
		local num = tonumber(room.Name)
		if num then
			rooms[#rooms + 1] = { room = room, num = num }
		end
	end
	table.sort(rooms, function(a, b) return a.num > b.num end)
	for i = 1, math.min(6, #rooms) do
		local label = GetArchivesClockLabel(rooms[i].room)
		if label then
			TimeShowerSourceLabel = label
			return label
		end
	end
	return nil
end

local function ResolveClockRemote()
	local label = ResolveClockLabel()
	if not label then return nil end
	local clock = label:FindFirstAncestor("ArchivesClock")
	if not clock then return nil end
	local remote = clock:FindFirstChild("LookedAtRemote", true)
	return (remote and remote:IsA("RemoteEvent")) and remote or nil
end

task.spawn(function()
	local lastCheckedRoomCount = 0
	while Globals.Running and game:IsLoaded() do
		local currentRooms = workspace:FindFirstChild("CurrentRooms")
		if currentRooms then
			local roomCount = 0
			for _, child in ipairs(currentRooms:GetChildren()) do
				if tonumber(child.Name) then
					roomCount += 1
				end
			end
			if roomCount > 0 and (lastCheckedRoomCount == 0 or roomCount - lastCheckedRoomCount >= 10) then
				ResolveClockLabel()
				lastCheckedRoomCount = roomCount
			end
		end
		task.wait(0.5)
	end
end)

local function StopTimeShower()
	TimeShowerToken += 1
	if TimeShowerConnection then
		TimeShowerConnection:Disconnect()
		TimeShowerConnection = nil
	end
	if TimeShowerLabel then
		TimeShowerLabel.Visible = false
		TimeShowerLabel.Text = "Time: --:--"
	end
end

Toggles.TimeShower:OnChanged(function(Value)
	StopTimeShower()
	if not Value then return end
	local Token = TimeShowerToken
	TimeShowerLabel.Visible = true
	TimeShowerConnection = Services.RunService.Heartbeat:Connect(function()
		if Token ~= TimeShowerToken then return end
		local TextLabel = ResolveClockLabel()
		TimeShowerLabel.Text = TextLabel and ("Time: " .. TextLabel.Text) or "Time: --:--"
	end)
end)

Toggles.BypassDronesStampede:OnChanged(function(enabled)
	if BypassDronesStampedeConnection then
		task.cancel(BypassDronesStampedeConnection)
		BypassDronesStampedeConnection = nil
	end
	if not enabled then return end
	BypassDronesStampedeConnection = task.spawn(function()
		while Toggles.BypassDronesStampede.Value do
			local remote = ResolveClockRemote()
			if remote then
				remote:FireServer()
				task.wait(0.5)
			else
				task.wait(0.25)
			end
		end
	end)
end)

local function ClearHonchoESP()
	if HonchoCorrectBoxConnection then
		HonchoCorrectBoxConnection:Disconnect()
		HonchoCorrectBoxConnection = nil
	end
	if HonchoAutoDepositConnection then
		HonchoAutoDepositConnection:Disconnect()
		HonchoAutoDepositConnection = nil
	end
	for _, Object in pairs(HonchoESPObjects) do
		if Object and Object.Parent then
			Functions.RemoveESP(Object)
		end
	end
	table.clear(HonchoESPObjects)
	table.clear(HonchoProcessedRooms)
	table.clear(HonchoDepositCache)
end

Toggles.HonchoCorrectBoxESP:OnChanged(function(Value)
	ClearHonchoESP()
	if not Value then return end
	local CurrentRooms = workspace:FindFirstChild("CurrentRooms")
	if not CurrentRooms then return end

	local function GetESPColor()
		return (Options.ObjectiveESPColor and Options.ObjectiveESPColor.Value) or Color3.fromRGB(0, 255, 0)
	end

	local function AddHonchoESP(Object, Text)
		Functions.AddESP({ Object = Object, Text = Text, Color = GetESPColor() }, true)
		HonchoESPObjects[#HonchoESPObjects + 1] = Object
		Object.Destroying:Once(function()
			Functions.RemoveESP(Object)
			local pos = table.find(HonchoESPObjects, Object)
			if pos then table.remove(HonchoESPObjects, pos) end
		end)
	end

	local function ProcessHonchoRoom(Room)
		if not tonumber(Room.Name) or not Room.Parent or HonchoProcessedRooms[Room] then return end
		HonchoProcessedRooms[Room] = true
		task.wait(3)
		if not Toggles.HonchoCorrectBoxESP.Value or not Room.Parent then
			HonchoProcessedRooms[Room] = nil
			return
		end
		local HonchoRoom = Room:FindFirstChild("ArchivesHonchoRoom", true)
		if not HonchoRoom then
			HonchoProcessedRooms[Room] = nil
			return
		end
		local BoxIDs = {}
		local RoomNumber = tonumber(Room.Name)
		for _, Desc in ipairs(Room:GetDescendants()) do
			local name = Desc.Name
			if name == "ArchivesPackageDeposit" or name:match("^ArchivesPackageDeposit") then
				local id = Desc:GetAttribute("BoxID")
				if id ~= nil then
					local idStr = tostring(id)
					BoxIDs[idStr] = true
					HonchoDepositCache[idStr] = Desc
					AddHonchoESP(Desc, "Deposit (" .. idStr .. ")")
					Desc.Destroying:Once(function()
						if HonchoDepositCache[idStr] == Desc then
							HonchoDepositCache[idStr] = nil
						end
					end)
				end
			end
		end
		if not next(BoxIDs) then
			HonchoProcessedRooms[Room] = nil
			return
		end
		for _, Child in ipairs(HonchoRoom:GetDescendants()) do
			if Child.Name == "ArchivesStorageBox" then
				local ToolBoxID = Child:GetAttribute("Tool_BoxID")
				if ToolBoxID ~= nil and BoxIDs[tostring(ToolBoxID)] then
					if not Child:GetAttribute("ParentRoom") then
						Child:SetAttribute("ParentRoom", RoomNumber)
					end
					Child.Name = "ArchivesStorageBoxCorrect"
					AddHonchoESP(Child, "Correct Box (" .. tostring(ToolBoxID) .. ")")
				end
			end
		end
	end

	for _, Room in ipairs(CurrentRooms:GetChildren()) do
		task.spawn(ProcessHonchoRoom, Room)
	end

	HonchoCorrectBoxConnection = CurrentRooms.ChildAdded:Connect(function(Room)
		task.spawn(ProcessHonchoRoom, Room)
	end)

	local lastCheck = 0
	HonchoAutoDepositConnection = game:GetService("RunService").Heartbeat:Connect(function()
		if not Toggles.HonchoCorrectBoxESP.Value then return end
		local now = os.clock()
		if now - lastCheck < 0.1 then return end
		lastCheck = now
		local Character = LocalPlayer and LocalPlayer.Character
		local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
		if not Character or not HumanoidRootPart then return end
		local BoxCandidates = {}
		for _, Object in ipairs(Character:GetChildren()) do
			if (Object:IsA("Tool") or Object:IsA("Model")) and (Object.Name == "ArchivesStorageBox" or Object.Name == "ArchivesStorageBoxCorrect") then
				BoxCandidates[#BoxCandidates + 1] = Object
			end
		end
		local Drops = workspace:FindFirstChild("Drops")
		if Drops then
			for _, Object in ipairs(Drops:GetChildren()) do
				if Object.Name == "ArchivesStorageBox" or Object.Name == "ArchivesStorageBoxCorrect" then
					BoxCandidates[#BoxCandidates + 1] = Object
				end
			end
		end
		for _, Box in ipairs(BoxCandidates) do
			if not (Box and Box.Parent) then continue end
			local BoxID = Box:GetAttribute("Tool_BoxID") or Box:GetAttribute("BoxID")
			if BoxID == nil then continue end
			local Deposit = HonchoDepositCache[tostring(BoxID)]
			if not Deposit or not Deposit.Parent then continue end
			if Box.Parent == Drops and not Box:GetAttribute("HonchoCorrectESP") then
				Box:SetAttribute("HonchoCorrectESP", true)
				AddHonchoESP(Box, "Correct Box (" .. tostring(BoxID) .. ")")
			end
			if Box.Parent == Character then
				local DepositPart = Deposit:IsA("BasePart") and Deposit or Deposit:FindFirstChildWhichIsA("BasePart", true)
				if DepositPart and (HumanoidRootPart.Position - DepositPart.Position).Magnitude <= 10 then
					local Prompt = Deposit:FindFirstChildWhichIsA("ProximityPrompt", true)
					if Prompt then
						fireproximityprompt(Prompt)
					end
				end
			end
		end
	end)
end)


Groupboxes.Archives_Bypasses = Tabs.Archives:AddLeftGroupbox("Bypasses")
Groupboxes.Archives_Bypasses:AddToggle("BypassWater", { Text = "Bypass Electric Water", Default = false, Tooltip = "Prevents electric water from hurting you." })
Groupboxes.Archives_Bypasses:AddToggle("BypassAlma", { Text = "Bypass Alma", Default = false, Tooltip = "Prevents 'Alma' from spawning." })
Groupboxes.Archives_Bypasses:AddToggle("BypassDrones", { Text = "Bypass Drones", Default = false, Tooltip = "Prevents 'Drones' from attacking you." })
Groupboxes.Archives_Bypasses:AddToggle("AntiScribbles", { Text = "Bypass Scribbles", Default = false, Tooltip = "Prevents 'Scribbles' from attacking you." })

Groupboxes.Archives_Experimental = Tabs.Archives:AddLeftGroupbox("Experimental")

Toggles.AntiClosetTrash:OnChanged(function(Value)
	if AntiClosetTrash_Connection then
		AntiClosetTrash_Connection:Disconnect()
		AntiClosetTrash_Connection = nil
	end
	if not Value then return end
	AntiClosetTrash_Connection = workspace.ChildAdded:Connect(function(Child)
		if not Toggles.AntiClosetTrash.Value then return end
		local Name = Child.Name
		if Name:sub(1, 6) == "Binder" or Name:sub(1, 4) == "Shoe" or Name:sub(1, 5) == "Shelf" then
			Child:Destroy()
		end
	end)
end)

Toggles.AntiRansom:OnChanged(function(Value)
	if AntiRansom_Connection then
		AntiRansom_Connection:Disconnect()
		AntiRansom_Connection = nil
	end
	if not Value then return end
	AntiRansom_Connection = workspace.ChildAdded:Connect(function(Child)
		if Child.Name == "Ransom" and Toggles.AntiRansom.Value then
			Child:Destroy()
			print("Ransom gone hehehehehehehehe")
		end
	end)
end)

Toggles.ForgetMeNotSolver:OnChanged(function(Value)
	if ForgetMeNotConnection then
		ForgetMeNotConnection:Disconnect()
		ForgetMeNotConnection = nil
	end
	ForgetMeNotRunning = false
	table.clear(ForgetMeNotProcessing)
	table.clear(ForgetMeNotNotified)
	table.clear(ForgetMeNotCompleted)
	if not Value then return end
	ForgetMeNotRunning = true

	local function GetCharacter()
		return game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
	end

	local function GetNextRoom(Number)
		while ForgetMeNotRunning do
			for RoomNumber = Number + 1, Number + 5 do
				local NextRoom = workspace.CurrentRooms:FindFirstChild(tostring(RoomNumber))
				if NextRoom then return NextRoom end
			end
			task.wait(0.1)
		end
		return nil
	end

	local function FireLookAts(Room)
		for i = 1, 6 do
			local Obj = Room:FindFirstChild(tostring(i))
			if Obj then
				local LookAt = Obj:FindFirstChild("LookAt")
				if LookAt then
					pcall(function() LookAt:FireServer() end)
				end
			end
		end
	end

	local function VoidCharacter()
		local Character = GetCharacter()
		if not Character then return end
		local hrp = Character:FindFirstChild("HumanoidRootPart") or Character.PrimaryPart
		if not hrp then return end

		local curPos = hrp.Position
		local voidCF = CFrame.new(curPos.X, -120, curPos.Z)

		-- Trigger void briefly to reset past vines, without fighting the game's return teleport
		local start = tick()
		while ForgetMeNotRunning and (tick() - start < 0.3) do
			Character:PivotTo(voidCF)
			task.wait(0.08)
			-- If already teleported back up by the game's Void, stop immediately
			if hrp.Position.Y > -50 and (tick() - start > 0.1) then
				break
			end
		end
	end

	local function Run(Room)
		local RoomNumber = tonumber(Room.Name)
		if not RoomNumber or not ForgetMeNotRunning or ForgetMeNotProcessing[RoomNumber] or ForgetMeNotCompleted[RoomNumber] then
			return
		end

		local currentRoomNum = tonumber(LocalPlayer:GetAttribute("CurrentRoom")) or 0
		if currentRoomNum > RoomNumber then
			ForgetMeNotCompleted[RoomNumber] = true
			return
		end

		if not Room:FindFirstChild("ForgetMeNotVineDoors", true) then
			return
		end

		ForgetMeNotProcessing[RoomNumber] = true

		while ForgetMeNotRunning and Room.Parent do
			FireLookAts(Room)

			local NextRoom = GetNextRoom(RoomNumber)
			if not NextRoom then
				task.wait(0.4)
				continue
			end

			local Door = NextRoom:FindFirstChild("Door")

			if not Door then
				local Character = GetCharacter()
				if Character then
					local Target = NextRoom:FindFirstChildWhichIsA("BasePart") or NextRoom
					if Target:IsA("BasePart") then
						Character:PivotTo(Target.CFrame + Vector3.new(0, 3, 0))
					elseif Target:IsA("Model") then
						Character:PivotTo(Target:GetPivot() + Vector3.new(0, 3, 0))
					else
						Character:PivotTo(CFrame.new(NextRoom:GetPivot().Position + Vector3.new(0, 5, 0)))
					end
				end
				ForgetMeNotCompleted[RoomNumber] = true
				break
			end

			-- If the door is already opened, the puzzle is done! Do NOT void!
			if Door:GetAttribute("Opened") == true then
				ForgetMeNotCompleted[RoomNumber] = true
				break
			end

			local Hidden = Door:FindFirstChild("Hidden") or Door:WaitForChild("Hidden", 2)
			if not Hidden then
				task.wait(0.3)
				continue
			end

			local openStart = tick()
			while ForgetMeNotRunning and Room.Parent and NextRoom.Parent and Door.Parent and Door:GetAttribute("Opened") ~= true and (tick() - openStart < 5) do
				local Character = GetCharacter()
				if Character then
					if Hidden:IsA("BasePart") then
						Character:PivotTo(Hidden.CFrame)
					elseif Hidden:IsA("Model") then
						Character:PivotTo(Hidden:GetPivot())
					end
				end
				pcall(function() Door.ClientOpen:Fire() end)
				pcall(function() Door.ClientOpen:FireServer() end)
				task.wait()
			end

			if ForgetMeNotRunning and Door.Parent and Door:GetAttribute("Opened") == true then
				ForgetMeNotCompleted[RoomNumber] = true
				VoidCharacter()
			end

			break
		end

		ForgetMeNotCompleted[RoomNumber] = true
		ForgetMeNotProcessing[RoomNumber] = nil
	end

	local function CheckRooms()
		local LatestRoomNumber = tonumber(LatestRoom.Value) or 0
		local currentRoomNum = tonumber(LocalPlayer:GetAttribute("CurrentRoom")) or LatestRoomNumber
		local FirstRoomNumber = math.max(0, LatestRoomNumber - 2)
		for RoomNumber = FirstRoomNumber, LatestRoomNumber do
			if not ForgetMeNotRunning then return end
			if currentRoomNum > RoomNumber then
				ForgetMeNotCompleted[RoomNumber] = true
			end
			local Room = workspace.CurrentRooms:FindFirstChild(tostring(RoomNumber))
			if Room and not ForgetMeNotProcessing[RoomNumber] and not ForgetMeNotCompleted[RoomNumber] then
				task.spawn(Run, Room)
			end
		end
	end

	ForgetMeNotConnection = workspace.CurrentRooms.ChildAdded:Connect(function(Room)
		local rNum = tonumber(Room.Name)
		if not rNum then return end
		task.spawn(function()
			task.wait(0.5)
			if ForgetMeNotRunning and Room.Parent and not ForgetMeNotCompleted[rNum] and not ForgetMeNotProcessing[rNum] then
				task.spawn(Run, Room)
			end
		end)
	end)

	task.spawn(function()
		while ForgetMeNotRunning do
			CheckRooms()
			task.wait(1)
		end
	end)

	CheckRooms()
end)

Toggles.BypassWater:OnChanged(function(Value)
	Functions.Notify({ Title = "PositionSpoof Will Break This!." })

	if WaterBypassConnection then
		WaterBypassConnection:Disconnect()
		WaterBypassConnection = nil
	end

	if not Value then
		for _, WaterBypassPart in pairs(WaterParts) do
			if WaterBypassPart then
				WaterBypassPart:Destroy()
			end
		end
		table.clear(WaterParts)
		return
	end

	local CurrentRooms = workspace.CurrentRooms

	local function ProcessWaterBypassRoom(WaterBypassRoom)
		if not tonumber(WaterBypassRoom.Name) then return end

		task.wait(3)

		local WaterBypassWater = WaterBypassRoom:FindFirstChild("Water")
		if not WaterBypassWater or WaterParts[WaterBypassWater] then return end

		local WaterBypassPart = Instance.new("Part")
		WaterBypassPart.Name = "WaterBypass"
		WaterBypassPart.Anchored = true
		WaterBypassPart.CanCollide = true
		WaterBypassPart.CanTouch = false
		WaterBypassPart.CanQuery = false
		WaterBypassPart.Transparency = 0.25
		WaterBypassPart.Color = Color3.fromRGB(0, 150, 255)
		WaterBypassPart.Material = Enum.Material.ForceField

		local WaterBypassSize, WaterBypassCFrame
		if WaterBypassWater:IsA("BasePart") then
			WaterBypassSize = WaterBypassWater.Size
			WaterBypassCFrame = WaterBypassWater.CFrame
		elseif WaterBypassWater:IsA("Model") then
			WaterBypassCFrame, WaterBypassSize = WaterBypassWater:GetBoundingBox()
		else
			WaterBypassSize = Vector3.new(10, 1.5, 10)
			WaterBypassCFrame = WaterBypassWater:GetPivot()
		end

		WaterBypassPart.Size = WaterBypassSize + Vector3.new(0, 0.5, 0)
		WaterBypassPart.CFrame = WaterBypassCFrame * CFrame.new(0, 0.25, 0)

		if WaterBypassPart.Size.Y > 3 then
			WaterBypassPart:Destroy()
			Functions.Notify({ Title = "Water Bypass removed: Softlock." })
			return
		end

		WaterBypassPart.Parent = WaterBypassRoom
		WaterParts[WaterBypassWater] = WaterBypassPart
	end

	local WaterBypassLatestRoomNumber = tonumber(LatestRoom.Value) or 0
	for WaterBypassRoomNumber = math.max(0, WaterBypassLatestRoomNumber - 4), WaterBypassLatestRoomNumber do
		local WaterBypassRoom = CurrentRooms:FindFirstChild(tostring(WaterBypassRoomNumber))
		if WaterBypassRoom then
			task.spawn(ProcessWaterBypassRoom, WaterBypassRoom)
		end
	end

	WaterBypassConnection = CurrentRooms.ChildAdded:Connect(function(WaterBypassRoom)
		task.spawn(ProcessWaterBypassRoom, WaterBypassRoom)
	end)
end)

Toggles.BypassAlma:OnChanged(function(Value)
	if AlmaConnection then
		AlmaConnection:Disconnect()
		AlmaConnection = nil
	end
	if Value then
		for _, child in ipairs(workspace:GetChildren()) do
			if child.Name == "Alma" then child:Destroy() end
		end
		AlmaConnection = workspace.ChildAdded:Connect(function(child)
			if child.Name == "Alma" then child:Destroy() end
		end)
	end
end)

Toggles.AntiScribbles:OnChanged(function(Value)
	if AntiScribbles_Connection then
		AntiScribbles_Connection:Disconnect()
		AntiScribbles_Connection = nil
	end
	if not Value then return end
	AntiScribbles_Connection = workspace.ChildAdded:Connect(function(Child)
		if Child.Name == "Scribbles" and Toggles.AntiScribbles.Value then
			local ExploitSribbleWarning = Child:FindFirstChild("IfYoureExploitingDeleteThis")
			if ExploitSribbleWarning then ExploitSribbleWarning:Destroy() end
		end
	end)
end)

Toggles.BypassDrones:OnChanged(function(Value)
	local RS = game:GetService("ReplicatedStorage")
	local function ProcessDrones(drones)
		local WalkedInto = drones:FindFirstChild("WalkedInto") or drones:WaitForChild("WalkedInto", 3)
		if WalkedInto and not DroneWalkedIntoParents[WalkedInto] then
			DroneWalkedIntoParents[WalkedInto] = drones
			WalkedInto.Parent = RS
		end
	end
	if Value then
		for _, child in ipairs(workspace:GetChildren()) do
			if child.Name == "Drones" then ProcessDrones(child) end
		end
		if DroneConnection then DroneConnection:Disconnect() end
		DroneConnection = workspace.ChildAdded:Connect(function(child)
			if child.Name == "Drones" then ProcessDrones(child) end
		end)
	else
		for WalkedInto, originalParent in pairs(DroneWalkedIntoParents) do
			if WalkedInto and WalkedInto.Parent and originalParent and originalParent.Parent then
				WalkedInto.Parent = originalParent
			end
		end
		table.clear(DroneWalkedIntoParents)
		if DroneConnection then
			DroneConnection:Disconnect()
			DroneConnection = nil
		end
	end
end)

Groupboxes.Stairwell_Misc = Tabs.Stairwell:AddLeftGroupbox("Exploits / Anti / Misc")



Groupboxes.Stairwell_Misc:AddDivider()
Groupboxes.Stairwell_Misc:AddToggle("BypassNoise", { Text = "Noise Tv Breaker", Default = false, Tooltip = "Breaks the tv of noise while holding it." })
Groupboxes.Stairwell_Misc:AddDropdown("NoiseTvBreakerMethod", {
	Text = "Breaker Method",
	Values = { "Rotate & Lift", "Under Map" },
	Default = 1,
	Tooltip = "Choose how to break the TV: Rotate & Lift (Orientation 0, 180, 180) or Under Map (Y = -120)."
})


Groupboxes.Stairwell_Misc:AddToggle("DroppedItemValue", { Text = "Item Number", Default = false, Tooltip = "Shows the number of dropped items." })

Groupboxes.Stairwell_Misc:AddToggle("KillAllWithCart", {
	Text = "Kill All (Requires ≥1 Cart)",
	Default = false,
})
Groupboxes.Stairwell_Misc:AddToggle("FlingCreak", {
	Text = "Bug Out Creak (Requires ≥5 Cart)",
	Default = false,
	ToolTip = "DONT TOUCH THE CARTS URSELF, U WILL DIE"
})
Groupboxes.Stairwell_Misc:AddToggle("CrazyCartCreak", {
	Text = "Crazy Cart Creak",
	Default = false,
	Tooltip = "Rapidly thrashes and violently spins shopping carts in all directions inside Creak."
})
Groupboxes.Stairwell_Misc:AddSlider("CrazyCartSpeed", {
	Text = "Crazy Cart Speed",
	Default = 35,
	Min = 10,
	Max = 100,
	Rounding = 0,
	Compact = false,
	Tooltip = "Speed of thrashing and spinning."
})
Groupboxes.Stairwell_Misc:AddSlider("CrazyCartRadius", {
	Text = "Crazy Cart Radius",
	Default = 4,
	Min = 1,
	Max = 15,
	Rounding = 1,
	Compact = false,
	Tooltip = "Displacement distance inside Creak."
})
Groupboxes.Stairwell_Misc:AddSlider("CrazyCartForce", {
	Text = "Crazy Cart Velocity",
	Default = 220,
	Min = 50,
	Max = 1000,
	Rounding = 0,
	Compact = false,
	Tooltip = "Physics linear velocity applied to cart parts."
})
Groupboxes.Stairwell_Misc:AddSlider("CrazyCartCount", {
	Text = "Crazy Cart Count",
	Default = 1,
	Min = 1,
	Max = 5,
	Rounding = 0,
	Compact = false,
	Tooltip = "Number of shopping carts that will spin and attack Creak (1 - 5)."
})
Groupboxes.Stairwell_Misc:AddDropdown("CrazyCartPattern", {
	Text = "Crazy Cart Pattern",
	Values = { "Chaotic Thrash", "Blender Vortex", "Piston Ram" },
	Default = "Chaotic Thrash",
	Tooltip = "Choose the movement and attack pattern of the carts inside Creak."
})
Groupboxes.Stairwell_Misc:AddToggle("CrazyCartAntiFling", {
	Text = "Crazy Cart Anti-Self Fling",
	Default = true,
	Tooltip = "Prevents spinning carts from colliding with or flinging your character."
})
Groupboxes.Stairwell_Misc:AddToggle("CreakAggressionMeter", {
    Text = "Creak Aggression Meter",
    Default = false,
    Tooltip = "Shows Creak's aggression above its head."
})

local CreakAggressionMetersTable = {}
local CreakAggressionCamera = Workspace.CurrentCamera
local CreakAggressionChildAddedConnection = nil

local function CleanupCreakAggressionMeter(CreakModel)
    local CreakMeterData = CreakAggressionMetersTable[CreakModel]
    if not CreakMeterData then return end

    CreakAggressionMetersTable[CreakModel] = nil

    if CreakMeterData.RenderConnection then
        CreakMeterData.RenderConnection:Disconnect()
    end
    if CreakMeterData.DestroyConnection then
        CreakMeterData.DestroyConnection:Disconnect()
    end

    for _, CreakDrawingObject in ipairs(CreakMeterData.Drawings) do
        pcall(function() CreakDrawingObject:Remove() end)
    end
end

local function GetCreakAggressionValue(CreakModel)
    local CreakAnimator = CreakModel:FindFirstChildOfClass("Animator")
        or (CreakModel:FindFirstChild("AnimationController") and CreakModel.AnimationController:FindFirstChildOfClass("Animator"))
        or CreakModel:FindFirstChildOfClass("AnimationController")

    if not CreakAnimator then return nil end

    for _, CreakAnimationTrack in ipairs(CreakAnimator:GetPlayingAnimationTracks()) do
        if CreakAnimationTrack.Name == "CreakGraph" or (CreakAnimationTrack.Animation and CreakAnimationTrack.Animation.Name == "CreakGraph") then
            local CreakSuccess, CreakAggressionValue = pcall(CreakAnimationTrack.GetParameter, CreakAnimationTrack, "Aggression")
            if CreakSuccess and typeof(CreakAggressionValue) == "number" then
                return math.clamp(CreakAggressionValue, 0, 1)
            end
        end
    end
    return nil
end

local function CreateCreakAggressionDrawings()
    local CreakDrawingList = {}

    local function CreateCreakDrawing(CreakDrawingType)
        local CreakNewDrawing = Drawing.new(CreakDrawingType)
        table.insert(CreakDrawingList, CreakNewDrawing)
        return CreakNewDrawing
    end

    local CreakTitleText = CreateCreakDrawing("Text")
    CreakTitleText.Text = "Aggression --%"
    CreakTitleText.Size = 16
    CreakTitleText.Font = Drawing.Fonts.Plex
    CreakTitleText.Color = Color3.fromRGB(255, 255, 255)
    CreakTitleText.Center = true
    CreakTitleText.Outline = true
    CreakTitleText.Visible = false

    local CreakBarBackground = CreateCreakDrawing("Square")
    CreakBarBackground.Size = Vector2.new(112, 6)
    CreakBarBackground.Filled = true
    CreakBarBackground.Color = Color3.fromRGB(58, 58, 64)
    CreakBarBackground.Transparency = 0.15
    CreakBarBackground.Visible = false

    local CreakBarFill = CreateCreakDrawing("Square")
    CreakBarFill.Size = Vector2.new(0, 6)
    CreakBarFill.Filled = true
    CreakBarFill.Visible = false

    return {
        Drawings = CreakDrawingList,
        TitleText = CreakTitleText,
        BarBackground = CreakBarBackground,
        BarFill = CreakBarFill
    }
end

local function AddCreakAggressionMeter(CreakModel)
    if not Toggles.CreakAggressionMeter.Value or CreakModel.Name ~= "Creak" or CreakAggressionMetersTable[CreakModel] then
        return
    end

    local CreakHeadPart = CreakModel:FindFirstChild("Head")
    if not CreakHeadPart or not CreakHeadPart:IsA("BasePart") then return end

    local CreakMeterData = CreateCreakAggressionDrawings()
    CreakAggressionMetersTable[CreakModel] = CreakMeterData

    CreakMeterData.RenderConnection = RunService.RenderStepped:Connect(function()
        if not Toggles.CreakAggressionMeter.Value or not CreakModel.Parent or not CreakHeadPart.Parent then
            CleanupCreakAggressionMeter(CreakModel)
            return
        end

        if not CreakAggressionCamera or not CreakAggressionCamera.Parent then
            CreakAggressionCamera = Workspace.CurrentCamera
            if not CreakAggressionCamera then return end
        end

        local CreakScreenPosition, CreakIsOnScreen = CreakAggressionCamera:WorldToViewportPoint(CreakHeadPart.Position + Vector3.new(0, 1.85, 0))
        if not (CreakIsOnScreen and CreakScreenPosition.Z > 0) then
            CreakMeterData.TitleText.Visible = false
            CreakMeterData.BarBackground.Visible = false
            CreakMeterData.BarFill.Visible = false
            return
        end

        CreakMeterData.TitleText.Position = Vector2.new(CreakScreenPosition.X, CreakScreenPosition.Y - 28)
        CreakMeterData.BarBackground.Position = Vector2.new(CreakScreenPosition.X - 56, CreakScreenPosition.Y - 6)
        CreakMeterData.BarFill.Position = CreakMeterData.BarBackground.Position

        local CreakAggressionValue = GetCreakAggressionValue(CreakModel)

        if not CreakAggressionValue then
            CreakMeterData.TitleText.Text = "Aggression --%"
            CreakMeterData.TitleText.Color = Color3.fromRGB(200, 200, 200)
            CreakMeterData.BarFill.Size = Vector2.new(0, 6)
            CreakMeterData.TitleText.Visible = true
            CreakMeterData.BarBackground.Visible = true
            CreakMeterData.BarFill.Visible = false
            return
        end

        CreakMeterData.TitleText.Text = "Aggression " .. math.floor(CreakAggressionValue * 100 + 0.5) .. "%"
        CreakMeterData.TitleText.Color = Color3.fromRGB(255, 255, 255)
        CreakMeterData.BarFill.Size = Vector2.new(112 * CreakAggressionValue, 6)
        CreakMeterData.BarFill.Color = Color3.fromRGB(70, 220, 100):Lerp(Color3.fromRGB(255, 55, 55), CreakAggressionValue)
        CreakMeterData.TitleText.Visible = true
        CreakMeterData.BarBackground.Visible = true
        CreakMeterData.BarFill.Visible = true
    end)

    CreakMeterData.DestroyConnection = CreakModel.Destroying:Connect(function()
        CleanupCreakAggressionMeter(CreakModel)
    end)
end

local function StartCreakAggressionListener()
    if CreakAggressionChildAddedConnection then return end

    local CreakLiveEntitiesFolder = Workspace:FindFirstChild("LiveEntities")
    if not CreakLiveEntitiesFolder then return end

    CreakAggressionChildAddedConnection = CreakLiveEntitiesFolder.ChildAdded:Connect(function(CreakNewChild)
        if CreakNewChild.Name == "Creak" then
            AddCreakAggressionMeter(CreakNewChild)
        end
    end)
end

local function StopCreakAggressionListener()
    if CreakAggressionChildAddedConnection then
        CreakAggressionChildAddedConnection:Disconnect()
        CreakAggressionChildAddedConnection = nil
    end
end

Toggles.CreakAggressionMeter:OnChanged(function(CreakToggleEnabled)
    if CreakToggleEnabled then
        for _, CreakEntityModel in ipairs(Objects.Entities or {}) do
            AddCreakAggressionMeter(CreakEntityModel)
        end

        local CreakLiveEntitiesFolder = Workspace:FindFirstChild("LiveEntities")
        local CreakExistingModel = CreakLiveEntitiesFolder and CreakLiveEntitiesFolder:FindFirstChild("Creak")
        if CreakExistingModel then
            AddCreakAggressionMeter(CreakExistingModel)
        end

        StartCreakAggressionListener()
    else
        StopCreakAggressionListener()

        for CreakEntityModel in pairs(CreakAggressionMetersTable) do
            CleanupCreakAggressionMeter(CreakEntityModel)
        end
    end
end)

do
	local function IsNoiseTv(instance)
		if not instance then return false end
		local name = instance.Name
		if name == "TV_Stand" or name == "Noise_TV" or name == "NoiseTV" or name == "TV" or name == "Noise" or name == "NoiseModel" then
			return true
		end
		if instance:FindFirstChild("NoiseTV") or instance:FindFirstChild("TV_Stand") or instance:FindFirstChild("Noise_TV") then
			return true
		end
		if instance:FindFirstAncestor("TV_Stand") or instance:FindFirstAncestor("Noise_TV") or instance:FindFirstAncestor("NoiseTV") then
			return true
		end
		return false
	end

	Functions.IsNoiseTv = IsNoiseTv

	Functions.SafeFireEvent = function(eventObj, ...)
		if not eventObj then return end
		if eventObj:IsA("RemoteEvent") then
			pcall(function(...) eventObj:FireServer(...) end, ...)
		elseif eventObj:IsA("BindableEvent") then
			pcall(function(...) eventObj:Fire(...) end, ...)
		end
	end

	Functions.GetShoppingCarts = function()
		local carts = {}
		local seen = {}

		local function add(model)
			if model and model:IsA("Model") and not seen[model] then
				if IsNoiseTv(model) then return end
				if model.Name == "ShoppingCart" or (model:FindFirstChild("CartAttached") and model:FindFirstChild("Handles")) then
					seen[model] = true
					table.insert(carts, model)
				end
			end
		end

		if Objects and Objects.Misc then
			for _, obj in ipairs(Objects.Misc) do
				if obj and obj.Parent and not IsNoiseTv(obj) and (obj.Name == "ShoppingCart" or obj:FindFirstChild("CartAttached")) then
					add(obj)
				end
			end
		end

		local misc = workspace:FindFirstChild("Misc")
		if misc then
			for _, child in ipairs(misc:GetChildren()) do
				if not IsNoiseTv(child) and (child.Name == "ShoppingCart" or child:FindFirstChild("CartAttached")) then
					add(child)
				end
			end
		end

		local currentRooms = workspace:FindFirstChild("CurrentRooms")
		if currentRooms then
			for _, room in ipairs(currentRooms:GetChildren()) do
				for _, child in ipairs(room:GetChildren()) do
					if not IsNoiseTv(child) and (child.Name == "ShoppingCart" or child:FindFirstChild("CartAttached")) then
						add(child)
					elseif child.Name == "Assets" or child.Name == "Misc" then
						for _, asset in ipairs(child:GetChildren()) do
							if not IsNoiseTv(asset) and (asset.Name == "ShoppingCart" or asset:FindFirstChild("CartAttached")) then
								add(asset)
							end
						end
					end
				end
			end
		end

		for _, child in ipairs(workspace:GetChildren()) do
			if not IsNoiseTv(child) and (child.Name == "ShoppingCart" or child:FindFirstChild("CartAttached")) then
				add(child)
			end
		end

		return carts
	end

	Functions.GetCreakMonster = function()
		local creak = workspace:FindFirstChild("LiveEntities") and workspace.LiveEntities:FindFirstChild("Creak")
		if creak and creak.Parent and creak:IsDescendantOf(workspace) then return creak end

		if Objects and Objects.Entities then
			for _, entity in ipairs(Objects.Entities) do
				if entity and entity.Parent and entity.Name == "Creak" and entity:IsDescendantOf(workspace) then
					return entity
				end
			end
		end

		local wsCreak = workspace:FindFirstChild("Creak")
		if wsCreak and wsCreak:IsA("Model") and wsCreak.Parent then
			return wsCreak
		end

		return nil
	end

	Functions.DetachTvFromCart = function(cart)
		if not cart or not cart.Parent then return end

		for _, desc in ipairs(cart:GetDescendants()) do
			if desc:IsA("JointInstance") or desc:IsA("WeldConstraint") then
				local p0 = desc.Part0
				local p1 = desc.Part1
				if (p0 and IsNoiseTv(p0)) or (p1 and IsNoiseTv(p1)) then
					pcall(function() desc:Destroy() end)
				end
			end
		end

		for _, child in ipairs(cart:GetChildren()) do
			if IsNoiseTv(child) then
				pcall(function() child.Parent = workspace:FindFirstChild("Misc") or workspace end)
			elseif child.Name == "StoredItems" or child.Name == "ItemHolders" then
				for _, item in ipairs(child:GetChildren()) do
					if IsNoiseTv(item) then
						pcall(function() item.Parent = workspace:FindFirstChild("Misc") or workspace end)
					end
				end
			end
		end
	end

	Functions.AttachCart = function(cart, target)
		if not cart or not cart.Parent or IsNoiseTv(cart) then return end

		Functions.DetachTvFromCart(cart)

		local attachedEvent = cart:FindFirstChild("CartAttached")
		if attachedEvent then
			if target then
				Functions.SafeFireEvent(attachedEvent, target)
			end
			Functions.SafeFireEvent(attachedEvent, LocalPlayer.Character)
			Functions.SafeFireEvent(attachedEvent)
		end

		local prompt = cart:FindFirstChild("CartPrompt", true)
		if prompt and not IsNoiseTv(prompt) then
			if Functions and Functions.FirePrompt then
				pcall(function() Functions.FirePrompt(prompt) end)
			elseif fireproximityprompt then
				pcall(function() fireproximityprompt(prompt) end)
			end
		end
	end

	Functions.ReleaseCart = function(cart)
		if not cart or not cart.Parent or IsNoiseTv(cart) then return end

		local releasedEvent = cart:FindFirstChild("CartReleased")
		if releasedEvent then
			Functions.SafeFireEvent(releasedEvent, LocalPlayer.Character)
			Functions.SafeFireEvent(releasedEvent)
		end
	end

	local cartCustomPhysicalProperties = PhysicalProperties.new(100, 0.5, 0.5, 100, 100)

	Functions.PrepareCartParts = function(cart)
		if not cart or not cart.Parent or IsNoiseTv(cart) then return end

		Functions.DetachTvFromCart(cart)

		if not cart.PrimaryPart then
			cart.PrimaryPart = cart:FindFirstChild("Base") or cart:FindFirstChild("Collider") or cart:FindFirstChildWhichIsA("BasePart")
		end

		for _, part in ipairs(cart:GetDescendants()) do
			if part:IsA("BasePart") and not IsNoiseTv(part) then
				if part.Name == "Collider" or part.Name == "Base" or part.Name:find("Collider") then
					part.CanCollide = true
					pcall(function()
						part.CustomPhysicalProperties = cartCustomPhysicalProperties
					end)
				end
				part.Massless = false
			end
		end
	end

	local antiFlingConstraints = {}
	local function SetCartAntiFling(cart, enable)
		if not cart or not cart.Parent then return end
		local char = LocalPlayer and LocalPlayer.Character
		if not char then return end

		local prim = cart.PrimaryPart or cart:FindFirstChild("Collider") or cart:FindFirstChild("Base")
		if not prim or not prim:IsA("BasePart") then return end

		if enable then
			if not antiFlingConstraints[cart] then
				antiFlingConstraints[cart] = {}
				for _, part in ipairs(char:GetChildren()) do
					if part:IsA("BasePart") then
						pcall(function()
							local ncc = Instance.new("NoCollisionConstraint")
							ncc.Name = "CrazyCartAntiFling"
							ncc.Part0 = part
							ncc.Part1 = prim
							ncc.Parent = prim
							table.insert(antiFlingConstraints[cart], ncc)
						end)
					end
				end
			end
		else
			if antiFlingConstraints[cart] then
				for _, ncc in ipairs(antiFlingConstraints[cart]) do
					pcall(function() ncc:Destroy() end)
				end
				antiFlingConstraints[cart] = nil
			end
		end
	end

	Toggles.KillAllWithCart:OnChanged(function(KillAllWithCartState)
		if not KillAllWithCartState then return end

		local KillAllWithCartIndex = 1

		task.spawn(function()
			while Toggles.KillAllWithCart.Value do
				local KillAllWithCartCarts = Functions.GetShoppingCarts()
				local KillAllWithCartAlivePlayers = {}
				for _, KillAllWithCartPlayer in ipairs(game.Players:GetPlayers()) do
					if KillAllWithCartPlayer ~= game.Players.LocalPlayer and KillAllWithCartPlayer.Character then
						local KillAllWithCartHumanoid = KillAllWithCartPlayer.Character:FindFirstChildOfClass("Humanoid")
						if KillAllWithCartHumanoid and KillAllWithCartHumanoid.Health > 0 then
							KillAllWithCartAlivePlayers[#KillAllWithCartAlivePlayers + 1] = KillAllWithCartPlayer
						end
					end
				end

				if #KillAllWithCartCarts > 0 and #KillAllWithCartAlivePlayers > 0 then
					if KillAllWithCartIndex > #KillAllWithCartAlivePlayers then
						KillAllWithCartIndex = 1
					end
					local KillAllWithCartTarget = KillAllWithCartAlivePlayers[KillAllWithCartIndex]
					local KillAllWithCartTargetCFrame = KillAllWithCartTarget.Character:GetPivot()
					for KillAllWithCartCartIndex = 1, #KillAllWithCartCarts do
						local cart = KillAllWithCartCarts[KillAllWithCartCartIndex]
						Functions.PrepareCartParts(cart)
						Functions.AttachCart(cart, KillAllWithCartTarget.Character)
						cart:PivotTo(KillAllWithCartTargetCFrame)
					end
					KillAllWithCartIndex = KillAllWithCartIndex + 1
				end
				task.wait(0.10)
			end
		end)
	end)

	Toggles.FlingCreak:OnChanged(function(FlingCreakState)
		if not FlingCreakState then return end

		task.spawn(function()
			while Toggles.FlingCreak.Value do
				local creak = Functions.GetCreakMonster()
				if creak then
					local targetCFrame = creak:GetPivot()
					local carts = Functions.GetShoppingCarts()
					for _, cart in ipairs(carts) do
						Functions.PrepareCartParts(cart)
						Functions.AttachCart(cart, creak)
						cart:PivotTo(targetCFrame)
					end
				end
				task.wait(0.10)
			end
		end)
	end)

	-- Высокопроизводительный кэш для CrazyCartCreak (0% просадки FPS)
	local activeCartEntries = {}
	local takenCarts = {}
	local disabledPlayerJoints = {}
	local promptConnections = {}
	local cachedCreak = nil
	local cachedTargetPart = nil
	local lastScanTime = 0

	local function DetachPlayerJoints(cart)
		local char = LocalPlayer and LocalPlayer.Character
		if not char then return end

		for _, desc in ipairs(cart:GetDescendants()) do
			if desc:IsA("JointInstance") or desc:IsA("WeldConstraint") then
				local p0 = desc.Part0
				local p1 = desc.Part1
				if (p0 and p0:IsDescendantOf(char)) or (p1 and p1:IsDescendantOf(char)) then
					if desc.Enabled then
						pcall(function() desc.Enabled = false end)
						table.insert(disabledPlayerJoints, desc)
					end
				end
			elseif desc:IsA("Constraint") then
				local a0 = desc.Attachment0
				local a1 = desc.Attachment1
				local p0 = a0 and a0.Parent
				local p1 = a1 and a1.Parent
				if (p0 and p0:IsDescendantOf(char)) or (p1 and p1:IsDescendantOf(char)) then
					if desc.Enabled then
						pcall(function() desc.Enabled = false end)
						table.insert(disabledPlayerJoints, desc)
					end
				end
			end
		end

		for _, desc in ipairs(char:GetDescendants()) do
			if desc:IsA("JointInstance") or desc:IsA("WeldConstraint") then
				local p0 = desc.Part0
				local p1 = desc.Part1
				if (p0 and p0:IsDescendantOf(cart)) or (p1 and p1:IsDescendantOf(cart)) then
					if desc.Enabled then
						pcall(function() desc.Enabled = false end)
						table.insert(disabledPlayerJoints, desc)
					end
				end
			elseif desc:IsA("Constraint") then
				local a0 = desc.Attachment0
				local a1 = desc.Attachment1
				local p0 = a0 and a0.Parent
				local p1 = a1 and a1.Parent
				if (p0 and p0:IsDescendantOf(cart)) or (p1 and p1:IsDescendantOf(cart)) then
					if desc.Enabled then
						pcall(function() desc.Enabled = false end)
						table.insert(disabledPlayerJoints, desc)
					end
				end
			end
		end
	end

	local function RestorePlayerJoints()
		for _, j in ipairs(disabledPlayerJoints) do
			if j and j.Parent then
				pcall(function() j.Enabled = true end)
			end
		end
		table.clear(disabledPlayerJoints)
	end

	local function IsCartHeldByPlayer(cart)
		if not cart or not cart.Parent or IsNoiseTv(cart) then return false end
		local char = LocalPlayer and LocalPlayer.Character
		if not char then return false end
		local hrp = char:FindFirstChild("HumanoidRootPart")

		for _, desc in ipairs(cart:GetDescendants()) do
			if desc:IsA("JointInstance") or desc:IsA("WeldConstraint") then
				local p0 = desc.Part0
				local p1 = desc.Part1
				if (p0 and p0:IsDescendantOf(char)) or (p1 and p1:IsDescendantOf(char)) then
					return true
				end
			elseif desc:IsA("Constraint") then
				local a0 = desc.Attachment0
				local a1 = desc.Attachment1
				local p0 = a0 and a0.Parent
				local p1 = a1 and a1.Parent
				if (p0 and p0:IsDescendantOf(char)) or (p1 and p1:IsDescendantOf(char)) then
					return true
				end
			end
		end

		for _, desc in ipairs(char:GetDescendants()) do
			if desc:IsA("JointInstance") or desc:IsA("WeldConstraint") then
				local p0 = desc.Part0
				local p1 = desc.Part1
				if (p0 and p0:IsDescendantOf(cart)) or (p1 and p1:IsDescendantOf(cart)) then
					return true
				end
			elseif desc:IsA("Constraint") then
				local a0 = desc.Attachment0
				local a1 = desc.Attachment1
				local p0 = a0 and a0.Parent
				local p1 = a1 and a1.Parent
				if (p0 and p0:IsDescendantOf(cart)) or (p1 and p1:IsDescendantOf(cart)) then
					return true
				end
			end
		end

		if cart:GetAttribute("Attached") == true or cart:GetAttribute("Holding") == true or cart:GetAttribute("Held") == true then
			return true
		end
		if cart:GetAttribute("Holder") == LocalPlayer.Name or cart:GetAttribute("Player") == LocalPlayer.Name or cart:GetAttribute("User") == LocalPlayer.Name then
			return true
		end
		if char:GetAttribute("HoldingCart") == true or char:GetAttribute("Cart") then
			return true
		end

		if hrp then
			local prim = cart.PrimaryPart or cart:FindFirstChild("Collider") or cart:FindFirstChild("Base")
			if prim and (prim.Position - hrp.Position).Magnitude < 4.5 then
				return true
			end
		end

		return false
	end

	local function GetCartFromPrompt(prompt)
		if not prompt then return nil end
		local cur = prompt.Parent
		while cur and cur ~= workspace and cur ~= game do
			if cur:IsA("Model") and (cur.Name == "ShoppingCart" or cur:FindFirstChild("CartAttached") or cur:FindFirstChild("Handles")) and not IsNoiseTv(cur) then
				return cur
			end
			cur = cur.Parent
		end
		return nil
	end

	local function StopAllActiveCarts()
		for _, entry in ipairs(activeCartEntries) do
			local cart = entry.Cart
			if cart and cart.Parent then
				SetCartAntiFling(cart, false)
				for _, bp in ipairs(entry.BaseParts) do
					if bp and bp.Parent then
						pcall(function()
							bp.AssemblyLinearVelocity = Vector3.zero
							bp.AssemblyAngularVelocity = Vector3.zero
						end)
					end
				end
			end
		end
		table.clear(activeCartEntries)
		table.clear(takenCarts)
		RestorePlayerJoints()
		cachedCreak = nil
		cachedTargetPart = nil
	end

	local function BuildCartEntry(cart)
		Functions.PrepareCartParts(cart)
		local parts = {}
		for _, bp in ipairs(cart:GetDescendants()) do
			if bp:IsA("BasePart") and not IsNoiseTv(bp) then
				table.insert(parts, bp)
			end
		end
		return {
			Cart = cart,
			BaseParts = parts,
			PrimaryPart = cart.PrimaryPart or cart:FindFirstChild("Base") or cart:FindFirstChild("Collider")
		}
	end

	local function RefreshCrazyCarts(forceScan)
		local now = tick()
		if not forceScan and (now - lastScanTime < 1.0) then return end
		lastScanTime = now

		-- 1. Валидация монстра Creak
		if not cachedCreak or not cachedCreak.Parent or not cachedCreak:IsDescendantOf(workspace) then
			cachedCreak = Functions.GetCreakMonster()
			cachedTargetPart = cachedCreak and (cachedCreak:FindFirstChild("HumanoidRootPart") or cachedCreak.PrimaryPart or cachedCreak:FindFirstChildWhichIsA("BasePart")) or nil
		end

		-- 2. Фильтрация только тех тележек, которые игрок взял на E
		local validTaken = {}
		for cart in pairs(takenCarts) do
			if cart and cart.Parent and cart:IsDescendantOf(workspace) then
				table.insert(validTaken, cart)
			else
				takenCarts[cart] = nil
			end
		end

		-- Если игрок не взял тележку через Prompt, проверяем, вдруг он уже держит её
		if #validTaken == 0 then
			for _, cart in ipairs(Functions.GetShoppingCarts()) do
				if IsCartHeldByPlayer(cart) then
					takenCarts[cart] = true
					DetachPlayerJoints(cart)
					table.insert(validTaken, cart)
					break
				end
			end
		end

		local maxCarts = (Options.CrazyCartCount and Options.CrazyCartCount.Value) or 1
		maxCarts = math.clamp(maxCarts, 1, 5)

		-- 3. Формирование activeCartEntries
		local activeSet = {}
		local newEntries = {}
		for i = 1, math.min(#validTaken, maxCarts) do
			local cart = validTaken[i]
			activeSet[cart] = true
			local existing = nil
			for _, e in ipairs(activeCartEntries) do
				if e.Cart == cart then
					existing = e
					break
				end
			end
			if existing then
				table.insert(newEntries, existing)
			else
				local entry = BuildCartEntry(cart)
				table.insert(newEntries, entry)
			end
		end

		-- 4. Очистка старых
		for _, oldEntry in ipairs(activeCartEntries) do
			if not activeSet[oldEntry.Cart] and oldEntry.Cart and oldEntry.Cart.Parent then
				SetCartAntiFling(oldEntry.Cart, false)
				for _, bp in ipairs(oldEntry.BaseParts) do
					if bp and bp.Parent then
						pcall(function()
							bp.AssemblyLinearVelocity = Vector3.zero
							bp.AssemblyAngularVelocity = Vector3.zero
						end)
					end
				end
			end
		end

		activeCartEntries = newEntries

		local antiFling = (Toggles.CrazyCartAntiFling and Toggles.CrazyCartAntiFling.Value) or false
		for _, entry in ipairs(activeCartEntries) do
			SetCartAntiFling(entry.Cart, antiFling)
			DetachPlayerJoints(entry.Cart)
		end
	end

	local function RegisterTakenCart(cart)
		if not cart or not cart.Parent or IsNoiseTv(cart) then return end
		if takenCarts[cart] then return end

		takenCarts[cart] = true
		DetachPlayerJoints(cart)
		Functions.PrepareCartParts(cart)

		local antiFling = (Toggles.CrazyCartAntiFling and Toggles.CrazyCartAntiFling.Value) or false
		SetCartAntiFling(cart, antiFling)

		Functions.Notify({ Title = "Crazy Cart Creak", Body = "Cart grabbed with [E]! Circling Creak started." })
		RefreshCrazyCarts(true)
	end

	local function UnregisterTakenCart(cart)
		if not cart then return end
		takenCarts[cart] = nil
		SetCartAntiFling(cart, false)
		RefreshCrazyCarts(true)
	end

	Toggles.CrazyCartCreak:OnChanged(function(Value)
		if Connections.CrazyCartCreak then
			Connections.CrazyCartCreak:Disconnect()
			Connections.CrazyCartCreak = nil
		end

		for key, conn in pairs(promptConnections) do
			pcall(function() conn:Disconnect() end)
		end
		table.clear(promptConnections)

		if not Value then
			pcall(StopAllActiveCarts)
			return
		end

		-- Подключение отслеживания взятия тележки на E через ProximityPromptService
		local promptService = Services.ProximityPromptService or game:GetService("ProximityPromptService")
		if promptService then
			promptConnections.GlobalPrompt = promptService.PromptTriggered:Connect(function(prompt, player)
				if player == LocalPlayer or not player then
					local cart = GetCartFromPrompt(prompt)
					if cart then
						RegisterTakenCart(cart)
					end
				end
			end)
		end

		-- Подключение событий внутри каждой доступной тележки
		for _, cart in ipairs(Functions.GetShoppingCarts()) do
			local prompt = cart:FindFirstChild("CartPrompt", true)
			if prompt and prompt:IsA("ProximityPrompt") then
				local cId = "Prompt_" .. tostring(cart)
				promptConnections[cId] = prompt.Triggered:Connect(function(player)
					if player == LocalPlayer or not player then
						RegisterTakenCart(cart)
					end
				end)
			end

			local att = cart:FindFirstChild("CartAttached")
			if att then
				local cId = "Att_" .. tostring(cart)
				if att:IsA("BindableEvent") then
					promptConnections[cId] = att.Event:Connect(function(...)
						RegisterTakenCart(cart)
					end)
				elseif att:IsA("RemoteEvent") then
					promptConnections[cId] = att.OnClientEvent:Connect(function(...)
						RegisterTakenCart(cart)
					end)
				end
			end

			local rel = cart:FindFirstChild("CartReleased")
			if rel then
				local cId = "Rel_" .. tostring(cart)
				if rel:IsA("BindableEvent") then
					promptConnections[cId] = rel.Event:Connect(function(...)
						UnregisterTakenCart(cart)
					end)
				elseif rel:IsA("RemoteEvent") then
					promptConnections[cId] = rel.OnClientEvent:Connect(function(...)
						UnregisterTakenCart(cart)
					end)
				end
			end
		end

		-- Первоначальная проверка: если игрок уже держит тележку
		RefreshCrazyCarts(true)

		if #activeCartEntries == 0 then
			Functions.Notify({ Title = "Crazy Cart Creak", Body = "Grab a cart with [E] to start circling Creak!" })
		else
			Functions.Notify({ Title = "Crazy Cart Creak", Body = "Cart detected! Circling started." })
		end

		Connections.CrazyCartCreak = Services.RunService.Heartbeat:Connect(function()
			if not Toggles.CrazyCartCreak.Value then
				if Connections.CrazyCartCreak then
					Connections.CrazyCartCreak:Disconnect()
					Connections.CrazyCartCreak = nil
				end
				return
			end

			local t = tick()

			if t - lastScanTime >= 1.0 then
				RefreshCrazyCarts(false)
			end

			local numCarts = #activeCartEntries
			if numCarts == 0 then
				return
			end

			if not cachedCreak or not cachedCreak.Parent or not cachedCreak:IsDescendantOf(workspace) then
				return
			end

			local creakPivot = cachedTargetPart and cachedTargetPart.CFrame or cachedCreak:GetPivot()
			local speed = (Options.CrazyCartSpeed and Options.CrazyCartSpeed.Value) or 35
			local radius = (Options.CrazyCartRadius and Options.CrazyCartRadius.Value) or 4.0
			local force = (Options.CrazyCartForce and Options.CrazyCartForce.Value) or 220
			local pattern = (Options.CrazyCartPattern and Options.CrazyCartPattern.Value) or "Chaotic Thrash"

			for index, entry in ipairs(activeCartEntries) do
				local cart = entry.Cart
				if not cart or not cart.Parent then continue end

				local cartPhase = ((index - 1) / numCarts) * math.pi * 2
				local offsetX, offsetY, offsetZ
				local rotX, rotY, rotZ, flip

				if pattern == "Blender Vortex" then
					local angle = t * speed * 2.8 + cartPhase
					local currentRadius = radius * (0.6 + 0.4 * math.sin(t * speed * 1.5 + cartPhase))
					offsetX = math.cos(angle) * currentRadius
					offsetY = math.sin(t * speed * 3.2 + cartPhase) * (radius * 0.9)
					offsetZ = math.sin(angle) * currentRadius

					rotX = math.rad((t * speed * 120 + cartPhase * 60) % 360)
					rotY = -angle + math.pi / 2
					rotZ = math.rad((math.sin(t * speed * 2) * 45))
					flip = 0
				elseif pattern == "Piston Ram" then
					local ramDir = (index % 2 == 0) and 1 or -1
					local ramCycle = math.sin(t * speed * 2.5 + cartPhase)
					local punch = math.sign(ramCycle) * (math.abs(ramCycle) ^ 0.5) * radius * 1.2
					offsetX = punch * ramDir
					offsetY = math.sin(t * speed * 1.2 + cartPhase) * 1.5
					offsetZ = math.cos(t * speed * 1.8 + cartPhase) * (radius * 0.3)

					rotX = math.rad((t * speed * 80) % 360)
					rotY = math.rad((ramDir > 0 and 0 or 180) + (t * speed * 40) % 360)
					rotZ = math.rad((t * speed * 90) % 360)
					flip = (ramCycle > 0 and 0 or math.pi)
				else
					local phaseX = t * speed * 2.3 + cartPhase
					local sharpSinX = math.clamp(math.sin(phaseX) * 2.5, -1, 1) * radius
					local joltX = (math.sin(phaseX * 3.7) > 0 and 0.5 or -0.5) * radius * 0.4
					offsetX = sharpSinX + joltX

					local phaseY = t * speed * 3.1 + cartPhase * 1.5
					local sharpCosY = math.clamp(math.cos(phaseY) * 2.5, -1, 1) * (radius * 0.8)
					local joltY = (math.cos(phaseY * 4.3) > 0 and 0.5 or -0.5) * radius * 0.4
					offsetY = sharpCosY + joltY

					local phaseZ = t * speed * 2.7 + cartPhase * 2.0
					local sharpSinZ = math.clamp(math.sin(phaseZ) * 2.5, -1, 1) * radius
					local joltZ = (math.sin(phaseZ * 3.1) > 0 and 0.5 or -0.5) * radius * 0.4
					offsetZ = sharpSinZ + joltZ

					rotX = math.rad((t * speed * 90 + cartPhase * 60) % 360)
					rotY = math.rad((t * speed * 130 + cartPhase * 90) % 360)
					rotZ = math.rad((t * speed * 105 + cartPhase * 45) % 360)
					flip = (math.sin(t * speed * 1.8 + cartPhase) > 0 and 0 or math.pi)
				end

				local transform = CFrame.new(offsetX, offsetY, offsetZ) * CFrame.Angles(rotX + flip, rotY, rotZ + flip)
				cart:PivotTo(creakPivot * transform)

				-- Скорости применяются ТОЛЬКО к предварительно кэшированным деталям
				local vel = Vector3.new(
					(math.random(-100, 100) / 100) * force,
					(math.random(-100, 100) / 100) * force,
					(math.random(-100, 100) / 100) * force
				)
				local angVel = Vector3.new(
					(math.random(-100, 100) / 100) * (force * 0.6),
					(math.random(-100, 100) / 100) * (force * 0.6),
					(math.random(-100, 100) / 100) * (force * 0.6)
				)
				for _, bp in ipairs(entry.BaseParts) do
					if bp.Parent then
						bp.AssemblyLinearVelocity = vel
						bp.AssemblyAngularVelocity = angVel
					end
				end
			end
		end)
	end)

	if Options.CrazyCartCount then
		Options.CrazyCartCount:OnChanged(function()
			if Toggles.CrazyCartCreak.Value then
				RefreshCrazyCarts(true)
			end
		end)
	end

	if Toggles.CrazyCartAntiFling then
		Toggles.CrazyCartAntiFling:OnChanged(function(v)
			if Toggles.CrazyCartCreak.Value then
				for _, entry in ipairs(activeCartEntries) do
					SetCartAntiFling(entry.Cart, v)
				end
			end
		end)
	end
end




Groupboxes.Stairwell_Misc:AddDivider()


Groupboxes.Stairwell_Misc:AddToggle("DisableStairwellCrusherCollision", {
	Text = "Disable Crushers",
	Default = false,
})
Groupboxes.Stairwell_Misc:AddToggle("DeleteStairwellCrusherExceptBasicWall", {
	Text = "Delete Crushers",
	Default = false,
})
Groupboxes.Stairwell_Misc:AddToggle("MeldRemover", {
	Text = "Remove Meld",
	Default = false,
})

Groupboxes.Stairwell_Misc:AddToggle("StairwellLandingSpam", {
	Text = "TP to trash and drop trash.",
	Tooltip = "Combine with orbit, or bring all dropped items.",
	Default = false,
})

Toggles.DisableStairwellCrusherCollision:OnChanged(function(DisableStairwellCrusherCollisionState)
	if not DisableStairwellCrusherCollisionState then return end

	task.spawn(function()
		while Toggles.DisableStairwellCrusherCollision.Value do
			for _, DisableStairwellCrusherRoom in ipairs(workspace.CurrentRooms:GetChildren()) do
				local DisableStairwellCrusherAssets = DisableStairwellCrusherRoom:FindFirstChild("Assets")
				if DisableStairwellCrusherAssets then
					for _, DisableStairwellCrusherContainer in ipairs(DisableStairwellCrusherAssets:GetChildren()) do
						if DisableStairwellCrusherContainer.Name == "StairwellCrusherContainer1" then
							for _, DisableStairwellCrusherDescendant in ipairs(DisableStairwellCrusherContainer:GetDescendants()) do
								if DisableStairwellCrusherDescendant:IsA("BasePart") and DisableStairwellCrusherDescendant.CanCollide then
									local DisableStairwellCrusherUnderBasicWall = false
									local DisableStairwellCrusherParent = DisableStairwellCrusherDescendant.Parent
									while DisableStairwellCrusherParent and DisableStairwellCrusherParent ~= DisableStairwellCrusherContainer do
										if DisableStairwellCrusherParent.Name == "BasicWall" then
											DisableStairwellCrusherUnderBasicWall = true
											break
										end
										DisableStairwellCrusherParent = DisableStairwellCrusherParent.Parent
									end
									if not DisableStairwellCrusherUnderBasicWall then
										DisableStairwellCrusherDescendant.CanCollide = false
									end
								end
							end
						end

						local DisableStairwellCrusher = DisableStairwellCrusherContainer:FindFirstChild("StairwellCrusher")
						if DisableStairwellCrusher then
							local DisableStairwellCrusherOuterTrigger = DisableStairwellCrusher:FindFirstChild("OuterTrigger")
							local DisableStairwellCrusherCoreTrigger = DisableStairwellCrusher:FindFirstChild("CoreTrigger")
							if DisableStairwellCrusherOuterTrigger then
								DisableStairwellCrusherOuterTrigger:Destroy()
							end
							if DisableStairwellCrusherCoreTrigger then
								DisableStairwellCrusherCoreTrigger:Destroy()
							end
						end
					end
				end
			end
			task.wait(0.5)
		end
	end)
end)
Toggles.DeleteStairwellCrusherExceptBasicWall:OnChanged(function(DeleteStairwellCrusherExceptBasicWallState)
	if not DeleteStairwellCrusherExceptBasicWallState then return end

	task.spawn(function()
		while Toggles.DeleteStairwellCrusherExceptBasicWall.Value do
			for _, DeleteStairwellCrusherRoom in ipairs(workspace.CurrentRooms:GetChildren()) do
				local DeleteStairwellCrusherAssets = DeleteStairwellCrusherRoom:FindFirstChild("Assets")
				if DeleteStairwellCrusherAssets then
					for _, DeleteStairwellCrusherContainer in ipairs(DeleteStairwellCrusherAssets:GetChildren()) do
						if DeleteStairwellCrusherContainer.Name == "StairwellCrusherContainer1" then
							local DeleteStairwellCrusherToDestroy = {}
							for _, DeleteStairwellCrusherDescendant in ipairs(DeleteStairwellCrusherContainer:GetDescendants()) do
								local DeleteStairwellCrusherUnderBasicWall = false
								local DeleteStairwellCrusherParent = DeleteStairwellCrusherDescendant.Parent
								while DeleteStairwellCrusherParent and DeleteStairwellCrusherParent ~= DeleteStairwellCrusherContainer do
									if DeleteStairwellCrusherParent.Name == "BasicWall" then
										DeleteStairwellCrusherUnderBasicWall = true
										break
									end
									DeleteStairwellCrusherParent = DeleteStairwellCrusherParent.Parent
								end
								if not DeleteStairwellCrusherUnderBasicWall and DeleteStairwellCrusherDescendant.Name ~= "BasicWall" then
									DeleteStairwellCrusherToDestroy[#DeleteStairwellCrusherToDestroy + 1] = DeleteStairwellCrusherDescendant
								end
							end
							for _, DeleteStairwellCrusherInstance in ipairs(DeleteStairwellCrusherToDestroy) do
								if DeleteStairwellCrusherInstance and DeleteStairwellCrusherInstance.Parent then
									DeleteStairwellCrusherInstance:Destroy()
								end
							end
						end
					end
				end
			end
			task.wait(0.5)
		end
	end)
end)

Toggles.MeldRemover:OnChanged(function(State)
	if not State then return end
	task.spawn(function()
		while Toggles.MeldRemover.Value do
			for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
				for _, folderName in ipairs({"Assets", "Parts"}) do
					local folder = room:FindFirstChild(folderName)
					if folder then
						for _, child in ipairs(folder:GetChildren()) do
							if child.Name == "MeldWall"
								or child.Name == "Boleahghth29tdgfhy2thuy2htuu259uhh3u" -- no qeustions asked
							then
								child:Destroy()
							end
						end
					end
				end
				for _, name in ipairs({"MeldData", "MeldPads", "Meldview", "Meld"}) do
					local obj = room:FindFirstChild(name)
					if obj and obj:IsA("Folder") then
						obj:Destroy()
					end
				end
			end
			task.wait(0.5)
		end
	end)
end)




do
local StairwellLandingToken = 0

local function StairwellSnapshotTools()
	local set = {}
	local char = LocalPlayer and LocalPlayer.Character
	local backpack = LocalPlayer and LocalPlayer:FindFirstChild("Backpack")
	if char then
		for _, item in ipairs(char:GetChildren()) do
			if item:IsA("Tool") then
				set[item] = true
			end
		end
	end
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") then
				set[item] = true
			end
		end
	end
	return set
end

local function StairwellDropTrashTools(previousToolSet)
	local remotes = Services.ReplicatedStorage:FindFirstChild("RemotesFolder") or RemotesFolder
	local dropRemote = remotes and remotes:FindFirstChild("DropItem")
	local char = LocalPlayer and LocalPlayer.Character
	local backpack = LocalPlayer and LocalPlayer:FindFirstChild("Backpack")

	local valuableItems = {
		["Crucifix"] = true,
		["CrucifixWall"] = true,
		["SkeletonKey"] = true,
		["Shears"] = true,
		["Lockpick"] = true,
		["Flashlight"] = true,
		["Shakelight"] = true,
		["Straplight"] = true,
		["Bulklight"] = true,
		["Scanner"] = true,
		["LaserPointer"] = true,
		["HolyGrenade"] = true,
		["GoldGun"] = true,
		["SnakeBox"] = true,
		["Multitool"] = true,
		["Compass"] = true,
		["Lantern"] = true,
		["LanternLitItem"] = true,
	}

	local function DropIfEligible(tool)
		if not tool or not tool:IsA("Tool") then return end
		if valuableItems[tool.Name] then return end

		-- If tool is newly acquired from trash or is a junk item, drop it
		if not previousToolSet or not previousToolSet[tool] then
			if dropRemote then
				pcall(function()
					dropRemote:FireServer(tool)
				end)
			end
		end
	end

	if char then
		for _, item in ipairs(char:GetChildren()) do
			DropIfEligible(item)
		end
	end
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			DropIfEligible(item)
		end
	end

	-- Safe keyboard drop fallback for PC ONLY (Never call on Mobile to prevent native SIGSEGV crashes)
	local isMobileDevice = Library.IsMobile or (Services.UserInputService.TouchEnabled and not Services.UserInputService.KeyboardEnabled)
	if not isMobileDevice then
		pcall(function()
			local vim = game:GetService("VirtualInputManager")
			if vim then
				vim:SendKeyEvent(true, Enum.KeyCode.X, false, game)
				task.wait(0.02)
				vim:SendKeyEvent(false, Enum.KeyCode.X, false, game)
			elseif keypress and keyrelease then
				keypress(0x58)
				task.wait(0.02)
				keyrelease(0x58)
			end
		end)
	end
end

local function CollectStairwellTrashTargets()
	local currentRooms = workspace:FindFirstChild("CurrentRooms")
	if not currentRooms then return {} end

	local targets = {}
	local seenModels = {}

	for _, room in ipairs(currentRooms:GetChildren()) do
		local roomNum = tonumber(room.Name) or math.huge

		-- 1. Check StairwellLandingLogic
		local landingLogic = room:FindFirstChild("StairwellLandingLogic")
		if landingLogic then
			for _, obj in ipairs(landingLogic:GetChildren()) do
				local prompts = {}
				for _, desc in ipairs(obj:GetDescendants()) do
					if desc:IsA("ProximityPrompt") and desc.Enabled and desc.Parent then
						table.insert(prompts, desc)
					end
				end
				if obj:IsA("ProximityPrompt") and obj.Enabled and obj.Parent then
					table.insert(prompts, obj)
				end

				if #prompts > 0 and not seenModels[obj] then
					seenModels[obj] = true
					table.insert(targets, {
						Model = obj,
						Prompts = prompts,
						RoomNum = roomNum,
					})
				end
			end
		end

		-- 2. Check Assets for Trashcan / Trash prompts
		local assets = room:FindFirstChild("Assets")
		if assets then
			for _, obj in ipairs(assets:GetChildren()) do
				local oName = obj.Name:lower()
				local prompts = {}
				for _, desc in ipairs(obj:GetDescendants()) do
					if desc:IsA("ProximityPrompt") and desc.Enabled and desc.Parent then
						local pName = desc.Name:lower()
						if oName:find("trash") or pName:find("trash") or pName == "trashcanprompt" then
							table.insert(prompts, desc)
						end
					end
				end
				if #prompts > 0 and not seenModels[obj] then
					seenModels[obj] = true
					table.insert(targets, {
						Model = obj,
						Prompts = prompts,
						RoomNum = roomNum,
					})
				end
			end
		end
	end

	table.sort(targets, function(a, b)
		return a.RoomNum < b.RoomNum
	end)

	return targets
end

Toggles.StairwellLandingSpam:OnChanged(function(Value)
	StairwellLandingToken += 1

	if not Value then
		return
	end

	local CurrentToken = StairwellLandingToken

	task.spawn(function()
		while Toggles.StairwellLandingSpam.Value and CurrentToken == StairwellLandingToken do
			local targets = CollectStairwellTrashTargets()

			if #targets == 0 then
				task.wait(0.5)
			else
				for _, target in ipairs(targets) do
					if not Toggles.StairwellLandingSpam.Value or CurrentToken ~= StairwellLandingToken then
						break
					end

					local model = target.Model
					if not model.Parent or not model:IsDescendantOf(workspace) then
						continue
					end

					local part = nil
					if model:IsA("BasePart") then
						part = model
					elseif model:IsA("Model") then
						part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
					end
					if not part then
						for _, p in ipairs(target.Prompts) do
							if p.Parent and p.Parent:IsA("BasePart") then
								part = p.Parent
								break
							end
						end
					end

					if not part then
						continue
					end

					local beforeTools = StairwellSnapshotTools()
					local startTime = tick()

					-- Keep player at the target item until it is picked up or timeout (2.0s max)
					while Toggles.StairwellLandingSpam.Value
						and CurrentToken == StairwellLandingToken
						and model.Parent
						and model:IsDescendantOf(workspace)
						and (tick() - startTime < 2.0) do

						local char = LocalPlayer and LocalPlayer.Character
						local hum = char and char:FindFirstChildOfClass("Humanoid")
						local hrp = char and char:FindFirstChild("HumanoidRootPart")
						if not hrp or not hum or hum.Health <= 0 then
							break
						end

						-- Keep player glued right at the item so server registers proximity
						hrp.AssemblyLinearVelocity = Vector3.zero
						hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 1.5, 0))

						local anyPromptActive = false
						for _, prompt in ipairs(target.Prompts) do
							if prompt and prompt.Parent and prompt.Enabled then
								anyPromptActive = true
								prompt.RequiresLineOfSight = false
								prompt.HoldDuration = 0
								prompt.MaxActivationDistance = 99999

								if fireproximityprompt then
									pcall(fireproximityprompt, prompt)
								elseif Functions.FirePrompt then
									pcall(Functions.FirePrompt, prompt)
								end
							end
						end

						-- If all prompts are gone or disabled, the item is taken!
						if not anyPromptActive then
							break
						end

						-- Check if any tool was picked up into character or backpack
						local currentTools = StairwellSnapshotTools()
						local gotTool = false
						for t in pairs(currentTools) do
							if not beforeTools[t] then
								gotTool = true
								break
							end
						end

						if gotTool then
							-- Drop the trash immediately while at the landing
							StairwellDropTrashTools(beforeTools)
							beforeTools = StairwellSnapshotTools()
							task.wait(0.05)
							break
						end

						Services.RunService.Heartbeat:Wait()
					end

					-- Ensure any acquired trash is dropped before moving to next item
					StairwellDropTrashTools(beforeTools)
					task.wait(0.06)
					StairwellDropTrashTools(beforeTools)
				end
				task.wait(0.2)
			end
		end
	end)
end)
end


Groupboxes.Stairwell_Misc:AddDivider()

Groupboxes.Stairwell_Misc:AddButton("TP Shopping Carts To Player", function()
	task.spawn(function()
		local ShoppingCartTargetName = Options.ShoppingCartTarget.Value
		local ShoppingCartTargetPlayer = game.Players:FindFirstChild(ShoppingCartTargetName)
		if not ShoppingCartTargetPlayer or not ShoppingCartTargetPlayer.Character then return end
		local targetPivot = ShoppingCartTargetPlayer.Character:GetPivot()
		local safeFrontCFrame = targetPivot * CFrame.new(0, 0, -4)

		local carts = Functions.GetShoppingCarts and Functions.GetShoppingCarts() or {}
		if #carts == 0 then
			Functions.Notify({ Title = "Shopping Cart", Body = "No Shopping Carts found in workspace!" })
			return
		end

		for _, cart in ipairs(carts) do
			pcall(function()
				if Functions.PrepareCartParts then
					Functions.PrepareCartParts(cart)
				end
				for _, bp in ipairs(cart:GetDescendants()) do
					if bp:IsA("BasePart") then
						bp.AssemblyLinearVelocity = Vector3.zero
						bp.AssemblyAngularVelocity = Vector3.zero
					end
				end
				cart:PivotTo(safeFrontCFrame)
			end)
			task.wait(0.05)
		end
		Functions.Notify({ Title = "Shopping Cart", Body = "Teleported " .. #carts .. " cart(s) to " .. ShoppingCartTargetName })
	end)
end)

Groupboxes.Stairwell_Misc:AddButton("Fire Cart Attached", function()
	task.spawn(function()
		local carts = Functions.GetShoppingCarts and Functions.GetShoppingCarts() or {}
		local creak = Functions.GetCreakMonster and Functions.GetCreakMonster() or nil
		if #carts == 0 then
			Functions.Notify({ Title = "CartAttached", Body = "No carts found!" })
			return
		end
		for _, cart in ipairs(carts) do
			if Functions.AttachCart then
				Functions.AttachCart(cart, creak)
			end
		end
		Functions.Notify({ Title = "CartAttached", Body = "Fired CartAttached on " .. #carts .. " cart(s)!" })
	end)
end)

Groupboxes.Stairwell_Misc:AddButton("Fire Cart Released", function()
	task.spawn(function()
		local carts = Functions.GetShoppingCarts and Functions.GetShoppingCarts() or {}
		if #carts == 0 then
			Functions.Notify({ Title = "CartReleased", Body = "No carts found!" })
			return
		end
		for _, cart in ipairs(carts) do
			if Functions.ReleaseCart then
				Functions.ReleaseCart(cart)
			end
		end
		Functions.Notify({ Title = "CartReleased", Body = "Fired CartReleased on " .. #carts .. " cart(s)!" })
	end)
end)

Groupboxes.Stairwell_Misc:AddButton("Trigger Cart Prompt", function()
	task.spawn(function()
		local carts = Functions.GetShoppingCarts and Functions.GetShoppingCarts() or {}
		if #carts == 0 then
			Functions.Notify({ Title = "CartPrompt", Body = "No carts found!" })
			return
		end
		local triggered = 0
		for _, cart in ipairs(carts) do
			local prompt = cart:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt then
				triggered += 1
				if Functions and Functions.FirePrompt then
					pcall(function() Functions.FirePrompt(prompt) end)
				elseif fireproximityprompt then
					pcall(function() fireproximityprompt(prompt) end)
				end
			end
		end
		Functions.Notify({ Title = "CartPrompt", Body = "Triggered prompt on " .. triggered .. " cart(s)!" })
	end)
end)

Groupboxes.Stairwell_Misc:AddButton("Count / Find Carts", function()
	local carts = Functions.GetShoppingCarts and Functions.GetShoppingCarts() or {}
	local msg = "Found " .. #carts .. " cart(s)."
	for i, c in ipairs(carts) do
		msg = msg .. " [" .. i .. "]: " .. (c.Parent and c.Parent.Name or "nil")
	end
	Functions.Notify({ Title = "Cart Scanner", Body = msg })
	print("[ShoppingCart Scanner]", msg)
end)

Groupboxes.Stairwell_Misc:AddDropdown("ShoppingCartTarget", {
	Text = "Shopping Cart Target",
	Values = (function()
		local ShoppingCartPlayerNames = {}
		for _, ShoppingCartPlayer in ipairs(game.Players:GetPlayers()) do
			ShoppingCartPlayerNames[#ShoppingCartPlayerNames + 1] = ShoppingCartPlayer.Name
		end
		return ShoppingCartPlayerNames
	end)(),
	Default = game.Players.LocalPlayer.Name,
})

Groupboxes.Stairwell_Misc:AddButton("Refresh Players", function()
	local ShoppingCartPlayerNames = {}
	for _, ShoppingCartPlayer in ipairs(game.Players:GetPlayers()) do
		ShoppingCartPlayerNames[#ShoppingCartPlayerNames + 1] = ShoppingCartPlayer.Name
	end
	Options.ShoppingCartTarget:SetValues(ShoppingCartPlayerNames)
end)

Groupboxes.Stairwell_Experimental = Tabs.Stairwell:AddRightGroupbox("Experimental")


local isTPDropsRunning = false
local isBringDropsRunning = false

local function SafeTeleportDropItem(dropItem, targetCFrame)
	if not dropItem or not dropItem.Parent then return end

	if dropItem:IsA("BasePart") then
		dropItem.AssemblyLinearVelocity = Vector3.zero
		dropItem.AssemblyAngularVelocity = Vector3.zero
		dropItem.CFrame = targetCFrame
		return
	end

	if dropItem:IsA("Model") then
		local prim = dropItem.PrimaryPart or dropItem:FindFirstChild("Handle") or dropItem:FindFirstChildWhichIsA("BasePart")
		if prim then
			prim.AssemblyLinearVelocity = Vector3.zero
			prim.AssemblyAngularVelocity = Vector3.zero
		end
		dropItem:PivotTo(targetCFrame)
		if prim then
			prim.AssemblyLinearVelocity = Vector3.zero
			prim.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

local function GetGrinderTarget(scrapper)
	if not scrapper or not scrapper.Parent then return nil end

	local g1 = scrapper:FindFirstChild("Grinder1") or scrapper:FindFirstChild("Grinder")
	if not g1 then
		g1 = scrapper:FindFirstChild("Grinder1", true) or scrapper:FindFirstChild("Grinder", true)
	end
	if g1 and (g1:IsA("BasePart") or g1:IsA("Model")) then
		return g1:GetPivot()
	end

	local prim = (scrapper:IsA("Model") and scrapper.PrimaryPart) or scrapper:FindFirstChildWhichIsA("BasePart")
	if prim then
		return prim.CFrame
	end

	return scrapper:GetPivot()
end

local function TPDropsToNearestGrinder()
	if isTPDropsRunning then return end
	isTPDropsRunning = true

	local ok, err = pcall(function()
		local dropsFolder = workspace:FindFirstChild("Drops")
		local char = LocalPlayer and LocalPlayer.Character or Character
		local rootPart = char and char:FindFirstChild("HumanoidRootPart")

		if not dropsFolder or not rootPart then
			return
		end

		local playerPos = rootPart.Position
		local scrappers = {}

		-- 1. Scan Objects.Objectives (already tracked by HandleObject)
		if Objects and Objects.Objectives then
			for _, obj in ipairs(Objects.Objectives) do
				if obj and obj.Parent and (obj.Name == "StairwellScrapper" or obj.Name == "Scrapper") then
					scrappers[obj] = true
				end
			end
		end

		-- 2. Fast check in CurrentRooms (check direct room children, Assets, and LandingLogic)
		local currentRooms = workspace:FindFirstChild("CurrentRooms") or CurrentRooms
		if currentRooms then
			for _, room in ipairs(currentRooms:GetChildren()) do
				local s = room:FindFirstChild("StairwellScrapper") or room:FindFirstChild("Scrapper")
				if s then scrappers[s] = true end

				local assets = room:FindFirstChild("Assets")
				if assets then
					local as = assets:FindFirstChild("StairwellScrapper") or assets:FindFirstChild("Scrapper")
					if as then scrappers[as] = true end
					for _, ch in ipairs(assets:GetChildren()) do
						if ch.Name == "StairwellScrapper" or ch.Name == "Scrapper" then
							scrappers[ch] = true
						elseif ch.Name == "Grinder1" and ch.Parent then
							scrappers[ch.Parent] = true
						end
					end
				end

				local landing = room:FindFirstChild("StairwellLandingLogic")
				if landing then
					for _, ch in ipairs(landing:GetChildren()) do
						if ch.Name == "StairwellScrapper" or ch.Name == "Scrapper" then
							scrappers[ch] = true
						elseif ch.Name == "Grinder1" and ch.Parent then
							scrappers[ch.Parent] = true
						end
					end
				end
			end
		end

		-- 3. Check workspace top-level roots/folders
		for _, child in ipairs(workspace:GetChildren()) do
			if child.Name == "StairwellScrapper" or child.Name == "Scrapper" then
				scrappers[child] = true
			end
		end

		local misc = workspace:FindFirstChild("Misc")
		if misc then
			for _, child in ipairs(misc:GetChildren()) do
				if child.Name == "StairwellScrapper" or child.Name == "Scrapper" then
					scrappers[child] = true
				end
			end
		end

		-- Find the scrapper truly nearest to the player
		local nearestTargetCFrame = nil
		local nearestDistance = math.huge

		for scrapper in pairs(scrappers) do
			local targetCFrame = GetGrinderTarget(scrapper)
			if targetCFrame then
				local dist = (playerPos - targetCFrame.Position).Magnitude
				if dist < nearestDistance then
					nearestDistance = dist
					nearestTargetCFrame = targetCFrame
				end
			end
		end

		if not nearestTargetCFrame then
			return
		end

		local dropItems = dropsFolder:GetChildren()
		if #dropItems == 0 then return end

		local isMobile = Library.IsMobile or (Services.UserInputService.TouchEnabled and not Services.UserInputService.KeyboardEnabled)
		local batchSize = isMobile and 15 or 50
		local count = 0

		for _, dropItem in ipairs(dropItems) do
			if dropItem and dropItem.Parent then
				local jitter = Vector3.new(
					math.random(-6, 6) * 0.08,
					0.75,
					math.random(-6, 6) * 0.08
				)
				local targetCFrame = CFrame.new(nearestTargetCFrame.Position + jitter)

				SafeTeleportDropItem(dropItem, targetCFrame)

				count += 1
				if isMobile and count % batchSize == 0 then
					task.wait()
				end
			end
		end
	end)

	isTPDropsRunning = false
end

Groupboxes.Stairwell_Experimental:AddButton({
    Text = "TP All Drops to Nearest Grinder",
    Func = function()
        task.spawn(TPDropsToNearestGrinder)
    end,
    DoubleClick = false,
    Tooltip = "Teleports every dropped item to the grinder closest to you",
})

local function BringDroppedItems()
	if isBringDropsRunning then return end
	isBringDropsRunning = true

	local ok, err = pcall(function()
		local dropsFolder = workspace:FindFirstChild("Drops")
		local char = LocalPlayer and LocalPlayer.Character or Character
		local rootPart = char and char:FindFirstChild("HumanoidRootPart")

		if not dropsFolder or not rootPart then
			return
		end

		local dropItems = dropsFolder:GetChildren()
		if #dropItems == 0 then return end

		-- Teleport items to floor in front of player, NOT directly inside body
		local safeFrontCFrame = rootPart.CFrame * CFrame.new(0, -1.8, -3.0)

		local isMobile = Library.IsMobile or (Services.UserInputService.TouchEnabled and not Services.UserInputService.KeyboardEnabled)
		local batchSize = isMobile and 15 or 50
		local count = 0

		for _, dropItem in ipairs(dropItems) do
			if dropItem and dropItem.Parent then
				local jitter = Vector3.new(
					math.random(-8, 8) * 0.12,
					0.1,
					math.random(-8, 8) * 0.12
				)
				local targetCFrame = CFrame.new(safeFrontCFrame.Position + jitter)

				SafeTeleportDropItem(dropItem, targetCFrame)

				count += 1
				if isMobile and count % batchSize == 0 then
					task.wait()
				end
			end
		end
	end)

	isBringDropsRunning = false
end

Groupboxes.Stairwell_Experimental:AddButton({
	Text = "Bring Dropped Items",
	Func = function()
        task.spawn(BringDroppedItems)
    end,
	DoubleClick = false,
	Tooltip = "Brings all dropped items."
})

Groupboxes.Stairwell_Experimental:AddToggle("EnableDroppedItemsInterval", {
	Text = "Enable Interval",
	Default = false,
	Tooltip = "Automatically brings dropped items at the selected interval."
})

Groupboxes.Stairwell_Experimental:AddSlider("DroppedItemsInterval", {
	Text = "Interval",
	Default = 1,
	Min = 0,
	Max = 60,
	Rounding = 1,
	Compact = false,
	Tooltip = "How often dropped items are brought."
})

Toggles.EnableDroppedItemsInterval:OnChanged(function(enabled)
	if enabled then
		if droppedItemsIntervalRunning then return end
		droppedItemsIntervalRunning = true
		task.spawn(function()
			while Toggles.EnableDroppedItemsInterval.Value do
				BringDroppedItems()
				local interval = Options.DroppedItemsInterval.Value
				if interval <= 0 then
					task.wait()
				else
					task.wait(interval)
				end
			end
			droppedItemsIntervalRunning = false
		end)
	end
end)

Groupboxes.Stairwell_Experimental:AddDivider()

Groupboxes.Stairwell_Experimental:AddToggle("OrbitDroppedItems", {
	Text = "Orbit Dropped Items",
	Default = false,
	Tooltip = "Orbits dropped items around you. Teleports them to you every 10s to prevent despawn."
})

Groupboxes.Stairwell_Experimental:AddSlider("OrbitDroppedItemsHeight", {
	Text = "Height",
	Default = 2,
	Min = -20,
	Max = 20,
	Rounding = 1,
	Compact = false,
	Tooltip = "The height of the orbit."
})

Groupboxes.Stairwell_Experimental:AddSlider("OrbitDroppedItemsDistance", {
	Text = "Distance",
	Default = 5,
	Min = 0,
	Max = 50,
	Rounding = 1,
	Compact = false,
	Tooltip = "The distance of the orbit."
})

Groupboxes.Stairwell_Experimental:AddSlider("OrbitDroppedItemsSpeed", {
	Text = "Speed",
	Default = 2,
	Min = 0,
	Max = 20,
	Rounding = 1,
	Compact = false,
	Tooltip = "The speed of the orbit."
})

Toggles.OrbitDroppedItems:OnChanged(function(OrbitDroppedItemsEnabled)
	if OrbitDroppedItemsConnection then
		OrbitDroppedItemsConnection:Disconnect()
		OrbitDroppedItemsConnection = nil
	end
	if not OrbitDroppedItemsEnabled then return end
	OrbitDroppedItemsAngle = 0
	OrbitDroppedItemsLastTeleport = tick()
	OrbitDroppedItemsPauseUntil = 0
	OrbitDroppedItemsConnection = RunService.Heartbeat:Connect(function(OrbitDroppedItemsDeltaTime)
		if not LocalPlayer or not LocalPlayer.Character then return end
		local OrbitDroppedItemsHumanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		local OrbitDroppedItemsDropsFolder = workspace:FindFirstChild("Drops")
		if not OrbitDroppedItemsHumanoidRootPart or not OrbitDroppedItemsDropsFolder then return end
		local OrbitDroppedItemsHeightValue = Options.OrbitDroppedItemsHeight.Value
		local OrbitDroppedItemsDistanceValue = Options.OrbitDroppedItemsDistance.Value
		local OrbitDroppedItemsSpeedValue = Options.OrbitDroppedItemsSpeed.Value
		local OrbitDroppedItemsCurrentTime = tick()
		local OrbitDroppedItemsList = {}
		for _, OrbitDroppedItemsObject in ipairs(OrbitDroppedItemsDropsFolder:GetChildren()) do
			if OrbitDroppedItemsObject:IsA("Model") or OrbitDroppedItemsObject:IsA("BasePart") then
				OrbitDroppedItemsList[#OrbitDroppedItemsList + 1] = OrbitDroppedItemsObject
			end
		end
		local OrbitDroppedItemsCount = #OrbitDroppedItemsList
		if OrbitDroppedItemsCount == 0 then return end
		if OrbitDroppedItemsCurrentTime - OrbitDroppedItemsLastTeleport >= 10 then
			OrbitDroppedItemsLastTeleport = OrbitDroppedItemsCurrentTime
			OrbitDroppedItemsPauseUntil = OrbitDroppedItemsCurrentTime + 2
			local safeCenterCFrame = OrbitDroppedItemsHumanoidRootPart.CFrame * CFrame.new(0, -1.8, -2.5)
			for _, OrbitDroppedItemsObject in ipairs(OrbitDroppedItemsList) do
				local jitter = Vector3.new(
					math.random(-6, 6) * 0.1,
					0.1,
					math.random(-6, 6) * 0.1
				)
				SafeTeleportDropItem(OrbitDroppedItemsObject, CFrame.new(safeCenterCFrame.Position + jitter))
			end
		end
		if OrbitDroppedItemsCurrentTime < OrbitDroppedItemsPauseUntil then return end
		OrbitDroppedItemsAngle += OrbitDroppedItemsDeltaTime * OrbitDroppedItemsSpeedValue
		for OrbitDroppedItemsIndex, OrbitDroppedItemsObject in ipairs(OrbitDroppedItemsList) do
			local OrbitDroppedItemsObjectAngle = OrbitDroppedItemsAngle + ((OrbitDroppedItemsIndex - 1) / OrbitDroppedItemsCount) * math.pi * 2
			local OrbitDroppedItemsOffset = Vector3.new(
				math.cos(OrbitDroppedItemsObjectAngle) * OrbitDroppedItemsDistanceValue,
				OrbitDroppedItemsHeightValue,
				math.sin(OrbitDroppedItemsObjectAngle) * OrbitDroppedItemsDistanceValue
			)
			local OrbitDroppedItemsPosition = OrbitDroppedItemsHumanoidRootPart.Position + OrbitDroppedItemsOffset
			if OrbitDroppedItemsObject:IsA("Model") then
				OrbitDroppedItemsObject:PivotTo(CFrame.new(OrbitDroppedItemsPosition))
			else
				OrbitDroppedItemsObject.CFrame = CFrame.new(OrbitDroppedItemsPosition)
			end
		end
	end)
end)


do
local bypassNoiseToken = 0
local bypassNoiseMiscChildAddedConnection = nil
local bypassNoisePromptTriggeredConnection = nil

-- ==============================================================================
-- НАСТРОЙКИ ДЛЯ NOISE TV BREAKER (ИЗМЕНЯЙТЕ ПАРАМЕТРЫ ЗДЕСЬ):
local TV_BREAKER_OFFSET_Y = 5       -- Подъем телевизора вверх в студах (для Rotate & Lift, по умолчанию 5)
local TV_BREAKER_ROT_X = 0          -- Поворот вокруг оси X в градусах (как на фото: 0)
local TV_BREAKER_ROT_Y = 180        -- Поворот вокруг оси Y в градусах (как на фото: 180)
local TV_BREAKER_ROT_Z = 180        -- Поворот вокруг оси Z в градусах (как на фото: 180)
local TV_BREAKER_UNDER_Y = -120     -- Позиция Y под картой (для Under Map, по умолчанию -120)
local TV_BREAKER_VELOCITY_Y = 0     -- Дополнительная вертикальная скорость (0 = естественное падение)
-- ==============================================================================

local function IsConnectedToCharacter(instance, char)
	if not instance or not char then return false end
	if instance:IsA("JointInstance") or instance:IsA("WeldConstraint") then
		return (instance.Part0 and instance.Part0:IsDescendantOf(char))
			or (instance.Part1 and instance.Part1:IsDescendantOf(char))
	elseif instance:IsA("Constraint") then
		local p0 = instance.Attachment0 and instance.Attachment0.Parent
		local p1 = instance.Attachment1 and instance.Attachment1.Parent
		return (p0 and p0:IsDescendantOf(char))
			or (p1 and p1:IsDescendantOf(char))
	end
	return false
end

local function DisconnectFromCharacter(tvStand, char)
	if not char or not tvStand then return end
	for _, desc in ipairs(tvStand:GetDescendants()) do
		if IsConnectedToCharacter(desc, char) then
			pcall(function() desc:Destroy() end)
		end
	end
	for _, desc in ipairs(char:GetDescendants()) do
		if IsConnectedToCharacter(desc, tvStand) then
			pcall(function() desc:Destroy() end)
		end
	end
	if tvStand:IsDescendantOf(char) then
		local misc = workspace:FindFirstChild("Misc") or workspace
		tvStand.Parent = misc
	end
end

local function IsTvHeldByPlayer(tvStand, char)
	if not tvStand or not char then return false end

	-- 1. Объект физически внутри персонажа
	if tvStand:IsDescendantOf(char) then
		return true
	end

	-- 2. Внутри персонажа есть Tool с моделью или частью ТВ
	for _, child in ipairs(char:GetChildren()) do
		if child:IsA("Tool") then
			local n = child.Name
			if n == "TV_Stand" or n == "TV" or n == "Noise_TV" or n == "NoiseTV" then
				return true
			end
			if child:FindFirstChild("TV_Stand") or child:FindFirstChild("TV") then
				return true
			end
		end
	end

	-- 3. Наличие физической связи (Weld, Motor6D, Constraint) между ТВ и персонажем
	for _, desc in ipairs(tvStand:GetDescendants()) do
		if IsConnectedToCharacter(desc, char) then
			return true
		end
	end
	for _, desc in ipairs(char:GetDescendants()) do
		if IsConnectedToCharacter(desc, tvStand) then
			return true
		end
	end

	-- 4. Атрибуты владения или переноски предмета
	local holder = tvStand:GetAttribute("Holder") or tvStand:GetAttribute("HeldBy") or tvStand:GetAttribute("Carrier")
	if holder and (holder == LocalPlayer.Name or holder == LocalPlayer.UserId) then
		return true
	end
	if tvStand:GetAttribute("IsHeld") == true or tvStand:GetAttribute("Held") == true then
		return true
	end

	local charHolding = char:GetAttribute("Holding") or char:GetAttribute("Carrying") or char:GetAttribute("HeldItem")
	if charHolding and typeof(charHolding) == "string" and (charHolding:find("TV") or charHolding:find("Noise")) then
		return true
	end

	-- 5. Игрок только что завершил взаимодействие (взял в руки по ProximityPrompt) и находится вплотную (<= 5.5 studs)
	if tvStand:GetAttribute("Abysall_PlayerInteracted") == true then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local ok, pivot = pcall(function() return tvStand:GetPivot() end)
			if ok and pivot and (pivot.Position - hrp.Position).Magnitude <= 5.5 then
				return true
			end
		end
	end

	return false
end

local function BreakBypassNoiseTvStand(tvStand)
	if not tvStand or not tvStand.Parent or not tvStand:IsDescendantOf(game) then return end
	if tvStand:GetAttribute("Abysall_BypassNoise_Dropped") then return end
	tvStand:SetAttribute("Abysall_BypassNoise_Dropped", true)

	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")

	-- 1. Разрываем любые крепления к персонажу, чтобы игрок не полетел вниз вместе с ТВ
	DisconnectFromCharacter(tvStand, char)

	-- 2. Симуляция сброса / броска (клавиша 'X' и Remote DropItem при наличии Tool)
	pcall(function()
		if keypress and keyrelease then
			keypress(0x58)
			task.wait(0.02)
			keyrelease(0x58)
		elseif Abysall and Abysall.Environment and Abysall.Environment.keypress and Abysall.Environment.keyrelease then
			Abysall.Environment.keypress(0x58)
			task.wait(0.02)
			Abysall.Environment.keyrelease(0x58)
		end
	end)

	if char then
		local tool = char:FindFirstChildWhichIsA("Tool")
		if tool and (tool.Name == "TV_Stand" or tool.Name == "TV" or tool.Name == "Noise_TV" or tool.Name == "NoiseTV") then
			pcall(function()
				local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("RemotesFolder")
				if remotes and remotes:FindFirstChild("DropItem") then
					remotes.DropItem:FireServer(tool)
				end
			end)
		end
	end

	-- 3. Активируем любые ProximityPrompt внутри ТВ (на бросок/действие)
	for _, prompt in ipairs(tvStand:GetDescendants()) do
		if prompt:IsA("ProximityPrompt") and prompt.Enabled and fireproximityprompt then
			pcall(fireproximityprompt, prompt)
		end
	end

	local method = (Options.NoiseTvBreakerMethod and Options.NoiseTvBreakerMethod.Value) or "Rotate & Lift"

	-- 4. Снимаем Anchored со всех деталей телевизора
	for _, part in ipairs(tvStand:GetDescendants()) do
		if part:IsA("BasePart") then
			pcall(function()
				part.Anchored = false
				part.CanCollide = (method ~= "Under Map")
			end)
		end
	end

	-- 5. Перемещение ТВ согласно выбранному методу
	local ok, tvPivot = pcall(function() return tvStand:GetPivot() end)
	if ok and tvPivot then
		local newCFrame
		if method == "Under Map" then
			newCFrame = CFrame.new(tvPivot.Position.X, TV_BREAKER_UNDER_Y, tvPivot.Position.Z)
		else
			-- "Rotate & Lift" (поворот по фото: X=0, Y=180, Z=180 и подъем вверх на TV_BREAKER_OFFSET_Y студов)
			newCFrame = (tvPivot + Vector3.new(0, TV_BREAKER_OFFSET_Y, 0)) * CFrame.Angles(math.rad(TV_BREAKER_ROT_X), math.rad(TV_BREAKER_ROT_Y), math.rad(TV_BREAKER_ROT_Z))
		end

		pcall(function()
			tvStand:PivotTo(newCFrame)
		end)

		-- 6. Дополнительная скорость (если задана в TV_BREAKER_VELOCITY_Y выше)
		if TV_BREAKER_VELOCITY_Y ~= 0 then
			for _, part in ipairs(tvStand:GetDescendants()) do
				if part:IsA("BasePart") then
					pcall(function()
						part.AssemblyLinearVelocity = Vector3.new(0, TV_BREAKER_VELOCITY_Y, 0)
						part.Velocity = Vector3.new(0, TV_BREAKER_VELOCITY_Y, 0)
					end)
				end
			end
		end
	end
end

Toggles.BypassNoise:OnChanged(function(value)
	bypassNoiseToken += 1
	if bypassNoiseMiscChildAddedConnection then
		bypassNoiseMiscChildAddedConnection:Disconnect()
		bypassNoiseMiscChildAddedConnection = nil
	end
	if bypassNoisePromptTriggeredConnection then
		bypassNoisePromptTriggeredConnection:Disconnect()
		bypassNoisePromptTriggeredConnection = nil
	end

	if not value then return end

	local currentToken = bypassNoiseToken

	-- Отслеживаем взаимодействие игрока с ProximityPrompt телевизора
	if Services.ProximityPromptService then
		bypassNoisePromptTriggeredConnection = Services.ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
			if currentToken ~= bypassNoiseToken or not Toggles.BypassNoise.Value then return end
			if player == LocalPlayer and prompt and prompt.Parent then
				local topTv = prompt:FindFirstAncestor("TV_Stand") or prompt:FindFirstAncestor("Noise_TV") or prompt:FindFirstAncestor("NoiseTV")
				if topTv then
					topTv:SetAttribute("Abysall_PlayerInteracted", true)
				end
			end
		end)
	end

	local function CheckAndBreak(targetTvStand)
		if not targetTvStand or not targetTvStand:IsA("Model") then return end
		local name = targetTvStand.Name
		if name ~= "TV_Stand" and name ~= "Noise_TV" and name ~= "NoiseTV" then return end
		if targetTvStand:GetAttribute("Abysall_BypassNoise_Dropped") then return end

		local char = LocalPlayer.Character
		if not char then return end

		-- Срабатываем ИСКЛЮЧИТЕЛЬНО если телевизор взят игроком в руки
		if IsTvHeldByPlayer(targetTvStand, char) then
			BreakBypassNoiseTvStand(targetTvStand)
		end
	end

	local bypassNoiseMiscFolder = workspace:FindFirstChild("Misc")
	if bypassNoiseMiscFolder then
		bypassNoiseMiscChildAddedConnection = bypassNoiseMiscFolder.ChildAdded:Connect(function(newChild)
			if currentToken ~= bypassNoiseToken or not Toggles.BypassNoise.Value then return end
			CheckAndBreak(newChild)
		end)
	end

	task.spawn(function()
		while Toggles.BypassNoise.Value and currentToken == bypassNoiseToken do
			local char = LocalPlayer.Character
			if char then
				local candidates = {}
				local function addCand(m)
					if m and m:IsA("Model") then
						local n = m.Name
						if (n == "TV_Stand" or n == "Noise_TV" or n == "NoiseTV") and not m:GetAttribute("Abysall_BypassNoise_Dropped") then
							table.insert(candidates, m)
						end
					end
				end

				local misc = workspace:FindFirstChild("Misc")
				if misc then
					for _, c in ipairs(misc:GetChildren()) do addCand(c) end
				end
				for _, c in ipairs(workspace:GetChildren()) do addCand(c) end

				local curRooms = workspace:FindFirstChild("CurrentRooms")
				if curRooms then
					for _, r in ipairs(curRooms:GetChildren()) do
						local assets = r:FindFirstChild("Assets")
						if assets then
							for _, c in ipairs(assets:GetChildren()) do addCand(c) end
						end
						for _, c in ipairs(r:GetChildren()) do addCand(c) end
					end
				end

				for _, c in ipairs(char:GetChildren()) do addCand(c) end

				for _, tv in ipairs(candidates) do
					CheckAndBreak(tv)
				end
			end
			task.wait(0.1)
		end
	end)
end)
end

Toggles.DroppedItemValue:OnChanged(function(DroppedItemValue)
	local DroppedItemValueScreenGui = game:GetService("CoreGui"):FindFirstChild("DropsCoinCounter")
	if not DroppedItemValue then
		if DroppedItemValueScreenGui then DroppedItemValueScreenGui:Destroy() end
		return
	end
	local DroppedItemValueWorkspaceDrops = workspace:WaitForChild("Drops")
	if DroppedItemValueScreenGui then DroppedItemValueScreenGui:Destroy() end
	DroppedItemValueScreenGui = Instance.new("ScreenGui")
	DroppedItemValueScreenGui.Name = "DropsCoinCounter"
	DroppedItemValueScreenGui.ResetOnSpawn = false
	DroppedItemValueScreenGui.Parent = game:GetService("CoreGui")
	local DroppedItemValueCoinText = Instance.new("TextLabel")
	DroppedItemValueCoinText.Name = "CoinText"
	DroppedItemValueCoinText.AnchorPoint = Vector2.new(0.5, 0)
	DroppedItemValueCoinText.Position = UDim2.new(0.5, 0, 0.02, 0)
	DroppedItemValueCoinText.Size = UDim2.new(0, 250, 0, 40)
	DroppedItemValueCoinText.BackgroundTransparency = 1
	DroppedItemValueCoinText.Text = "Items: 0"
	DroppedItemValueCoinText.TextSize = 24
	DroppedItemValueCoinText.Font = Enum.Font.GothamBold
	DroppedItemValueCoinText.TextColor3 = Color3.fromRGB(255, 255, 255)
	DroppedItemValueCoinText.TextStrokeTransparency = 0.5
	DroppedItemValueCoinText.Parent = DroppedItemValueScreenGui
	local DroppedItemValueCountedDrops = {}
	task.spawn(function()
		while Toggles.DroppedItemValue.Value do
			for _, DroppedItemValueDrop in ipairs(DroppedItemValueWorkspaceDrops:GetChildren()) do
				if DroppedItemValueDrop:IsA("Model") and not DroppedItemValueCountedDrops[DroppedItemValueDrop] then
					DroppedItemValueDrop:SetAttribute("CoinsChecked", true)
					DroppedItemValueCountedDrops[DroppedItemValueDrop] = true
				end
			end
			for DroppedItemValueDrop in pairs(DroppedItemValueCountedDrops) do
				if not DroppedItemValueDrop.Parent or DroppedItemValueDrop.Parent ~= DroppedItemValueWorkspaceDrops then
					DroppedItemValueCountedDrops[DroppedItemValueDrop] = nil
				end
			end
			local DroppedItemValueTotalItems = 0
			for DroppedItemValueDrop in pairs(DroppedItemValueCountedDrops) do
				if DroppedItemValueDrop.Parent == DroppedItemValueWorkspaceDrops then
					DroppedItemValueTotalItems += 1
				end
			end
			DroppedItemValueCoinText.Text = "Items: " .. DroppedItemValueTotalItems
			task.wait(1)
		end
		if DroppedItemValueScreenGui and DroppedItemValueScreenGui.Parent then
			DroppedItemValueScreenGui:Destroy()
		end
	end)
end)

-- hi

Groupboxes.Exploits_BypassRight = Tabs.Exploits:AddRightGroupbox("Bypass")
Groupboxes.Exploits_BypassRight:AddToggle("DisableAnticheat", {
	Text = "Anticheat Bypass", Default = false,
	Tooltip = "Completely disables the anticheat, after interacting with a ladder."
})
Groupboxes.Exploits_BypassRight:AddToggle("VelocityManipulationToggle", {
	Text = "Velocity Manipulation", Default = false,
	Tooltip = "Moves your character slowly, mitigating the game's anti-noclip. Supports vertical movement (Space/Ctrl or Camera pitch)."
})
Toggles.DisableAnticheat:OnChanged(function(Value)
	if Globals.AnticheatDisabled == true and not Value then
		RemotesFolder.ClimbLadder:FireServer()
		Globals.AnticheatDisabled = false
	end
end)
Toggles.VelocityManipulationToggle:AddKeyPicker("VelocityManipulationKeybind", {
	Text = "Velocity Manipulation", Default = "V",
	Mode = Library.IsMobile and "Toggle" or "Hold", SyncToggleState = true
})
Groupboxes.Exploits_BypassRight:AddDropdown("VelocityManipulationMode", {
	Values = {"Velocity", "Pivot"}, Text = "Manipulation Method",
	Default = 1,
})
Groupboxes.Exploits_BypassRight:AddSlider("VelocityManipulationSpeed", {
	Text = "Manipulation Speed", Min = 1, Max = 10, Default = 2.25, Rounding = 2, Compact = true,
	Tooltip = "Speed of the velocity manipulation."
})

Groupboxes.Exploits_BypassRight:AddDivider()
Groupboxes.Exploits_BypassRight:AddToggle("InfiniteItemsToggle", {
	Text = "Infinite Items", Default = false,
	Tooltip = "Allows certain items to be used without draining their uses.",
	Disabled = not Functions.CheckCompatability({"fireproximityprompt"}),
	DisabledTooltip = Globals.IncompatibleMessage
})
Groupboxes.Exploits_BypassRight:AddDropdown("InfiniteItemsList", {
	Text = "Item List",
	Values = { "Lockpicks", "Skeleton Key", "Shears", "Multitool" },
	Multi = true, AllowNull = true,
	Disabled = not Functions.CheckCompatability({"fireproximityprompt"}),
	DisabledTooltip = Globals.IncompatibleMessage
})

Groupboxes.Exploits_BypassRight:AddToggle("InfCrucifix", {
	Text = "Infinite Crucifix",
	Default = false,
	Tooltip = "Risky! You can die or lose the Crucifix. Recommended to have low ping and stable fps.",
	Risky = Floor ~= "Ballz",
})


do
	local InfCrucifixDropTable = {
		RushMoving   = 54,
		AmbushMoving = 67,
		A60          = 70,
		GlitchRush   = 120,
		GlitchAmbush = 155,
		A120         = 75,
	}

	local InfCrucifixConnection = nil

	Toggles.InfCrucifix:OnChanged(function(Value)
		if InfCrucifixConnection then
			InfCrucifixConnection:Disconnect()
			InfCrucifixConnection = nil
		end

		if not Value then
			return
		end

		local InfCrucifixRaycastParams = RaycastParams.new()
		InfCrucifixRaycastParams.FilterType = Enum.RaycastFilterType.Blacklist

		InfCrucifixConnection = RunService.RenderStepped:Connect(function()
			if not Toggles.InfCrucifix.Value then
				if InfCrucifixConnection then
					InfCrucifixConnection:Disconnect()
					InfCrucifixConnection = nil
				end
				return
			end

			local InfCrucifixCharacter = Character or (LocalPlayer and LocalPlayer.Character)
			if not InfCrucifixCharacter then
				return
			end

			local InfCrucifixCollision = InfCrucifixCharacter:FindFirstChild("CollisionPart") or InfCrucifixCharacter:FindFirstChild("Collision") or InfCrucifixCharacter:FindFirstChild("HumanoidRootPart")
			if not InfCrucifixCollision then
				return
			end

			InfCrucifixRaycastParams.FilterDescendantsInstances = {InfCrucifixCharacter}

			for _, InfCrucifixEntity in ipairs(Workspace:GetChildren()) do
				local InfCrucifixMaxDistance = InfCrucifixDropTable[InfCrucifixEntity.Name]
				if not InfCrucifixMaxDistance or not InfCrucifixEntity.PrimaryPart then
					continue
				end

				InfCrucifixEntity.PrimaryPart.CanCollide = true
				InfCrucifixEntity.PrimaryPart.CanQuery = true

				local InfCrucifixOrigin = InfCrucifixCollision.Position
				local InfCrucifixDirection = InfCrucifixEntity.PrimaryPart.Position - InfCrucifixOrigin
				local InfCrucifixRayResult = Workspace:Raycast(InfCrucifixOrigin, InfCrucifixDirection, InfCrucifixRaycastParams)

				if not InfCrucifixRayResult or not InfCrucifixRayResult.Instance:IsDescendantOf(InfCrucifixEntity) then
					continue
				end

				local InfCrucifixDistance = (InfCrucifixCollision.Position - InfCrucifixEntity.PrimaryPart.Position).Magnitude
				if InfCrucifixDistance >= InfCrucifixMaxDistance then
					continue
				end

				local InfCrucifixTool = InfCrucifixCharacter:FindFirstChildOfClass("Tool")
				if not InfCrucifixTool or InfCrucifixTool.Name ~= "Crucifix" then
					continue
				end

				task.spawn(function()
					local remotes = RemotesFolder or (Services and Services.ReplicatedStorage and Services.ReplicatedStorage:FindFirstChild("RemotesFolder"))
					if remotes and remotes:FindFirstChild("DropItem") then
						remotes.DropItem:FireServer(InfCrucifixTool)
					end
					task.wait(0.54)
					local InfCrucifixDrops = Workspace:FindFirstChild("Drops")
					if not InfCrucifixDrops then
						return
					end

					local InfCrucifixDropped = InfCrucifixDrops:FindFirstChild("Crucifix")
					if not InfCrucifixDropped then
						return
					end

					local InfCrucifixPrompt = InfCrucifixDropped:FindFirstChildOfClass("ProximityPrompt")
					if InfCrucifixPrompt and fireproximityprompt then
						fireproximityprompt(InfCrucifixPrompt)
					end
				end)
				task.wait(0.6)
			end
		end)
	end)
end


Groupboxes.Exploits_BypassRight:AddDivider()
Groupboxes.Exploits_BypassRight:AddToggle("PositionSpoof", {
	Text = "Position Spoof", Default = false,
	Tooltip = "Makes your character appear underground on the server, protecting you from rush-like entities."
})
Groupboxes.Exploits_BypassRight:AddToggle("AutoPositionSpoof", {
	Text = "Auto Position Spoof", Default = false,
	Tooltip = "Automatically enables Position Spoof when rush-like entities appear, and disables it when they leave."
})
Groupboxes.Exploits_BypassRight:AddToggle("CrouchSpoof", {
	Text = "Crouch Spoof", Default = false, Tooltip = "Makes the game think you are always crouching."
})

Globals.AutoSpoofed = false
Globals.LastMonsterAround = false

Toggles.AutoPositionSpoof:OnChanged(function(Value)
	if not Value then
		Globals.LastMonsterAround = false
		if Globals.AutoSpoofed then
			Globals.AutoSpoofed = false
			if Toggles.PositionSpoof.Value then
				Toggles.PositionSpoof:SetValue(false)
			end
		end
	end
end)

local SpoofMonstersList = {
	["RushMoving"]     = true,
	["AmbushMoving"]   = true,
	["BackdoorRush"]   = true,
	["A60"]            = true,
	["A120"]           = true,
	["GlitchRush"]     = true,
	["GlitchAmbush"]   = true,
	["BashMoving"]     = true,
	["DronesStampede"] = true,
	["Scribbles"]      = true,
	["CustomEntity"]   = true,
	["FrozenAmbush"]   = true,
}

local lastMonsterCheck = 0
local cachedMonsterAround = false

local function IsSpoofMonsterAround()
	local now = tick()
	if now - lastMonsterCheck < 0.15 then
		return cachedMonsterAround
	end
	lastMonsterCheck = now

	for _, child in ipairs(Services.Workspace:GetChildren()) do
		if SpoofMonstersList[child.Name] then
			cachedMonsterAround = true
			return true
		end
	end
	local liveEnts = Services.Workspace:FindFirstChild("LiveEntities")
	if liveEnts then
		for _, child in ipairs(liveEnts:GetChildren()) do
			if SpoofMonstersList[child.Name] then
				cachedMonsterAround = true
				return true
			end
		end
	end
	if Objects and Objects.Entities then
		for _, entity in ipairs(Objects.Entities) do
			if entity and entity.Parent and SpoofMonstersList[entity.Name] then
				cachedMonsterAround = true
				return true
			end
		end
	end

	cachedMonsterAround = false
	return false
end

Toggles.PositionSpoof:OnChanged(function(Value)
	if not Value then
		Globals.AutoSpoofed = false
	end
	if Floor ~= "Fools" and Floor ~= "OldHotel" then
		if Value then
			RootPart.CFrame = RootPart.CFrame * CFrame.new(0, -2.346, 0)
			Humanoid.HipHeight = 0.05
			RemotesFolder.Crouch:FireServer(true, true)
		else
			RootPart.CFrame = RootPart.CFrame * CFrame.new(0, 2.346, 0)
			Humanoid.HipHeight = 2.396
		end
	end
end)
Toggles.PositionSpoof:AddKeyPicker("PositionSpoof", {
	Text = "Position Spoof", Default = "B", Mode = "Toggle", SyncToggleState = true
})
Toggles.CrouchSpoof:OnChanged(function(Value)
	if RemotesFolder:FindFirstChild("Crouch") then
		RemotesFolder.Crouch:FireServer(Value and true or Functions.IsCrouching(), true)
	end
end)

Groupboxes.Exploits_Remove = Tabs.Exploits:AddRightGroupbox("Remove")
Groupboxes.Exploits_Remove:AddToggle("RemoveScreech", { Text = "Remove Screech",  Default = false, Tooltip = "Prevents 'Screech' from spawning." })
Groupboxes.Exploits_Remove:AddToggle("RemoveHalt",    { Text = "Remove Halt",     Default = false, Tooltip = "Prevents 'Halt' from spawning." })
Groupboxes.Exploits_Remove:AddToggle("RemoveA90",     { Text = "Remove A-90",     Default = false, Tooltip = "Prevents 'A-90' from spawning." })
Groupboxes.Exploits_Remove:AddToggle("RemoveDread",   { Text = "Remove Dread",    Default = false, Tooltip = "Prevents 'Dread' from spawning." })
Groupboxes.Exploits_Remove:AddToggle("RemoveSurge", { Text = "Remove Surge", Default = false, Tooltip = "Prevents 'Surge' from spawning."})
Groupboxes.Exploits_Remove:AddDivider()
Groupboxes.Exploits_Remove:AddToggle("NoScreechDamage", { Text = "No Screech Damage", Default = false, Tooltip = "Prevents 'Screech' from hurting you." })
Groupboxes.Exploits_Remove:AddToggle("NoHaltDamage",    { Text = "No Halt Damage",    Default = false, Tooltip = "Prevents 'Halt' from hurting you." })
Groupboxes.Exploits_Remove:AddToggle("NoA90Damage",     { Text = "No A-90 Damage",    Default = false, Tooltip = "Prevents 'A-90' from hurting you." })
Groupboxes.Exploits_Remove:AddToggle("NoSurgeDamage",   { Text = "No Surge Damage",   Default = false, Tooltip = "Prevents 'Surge' from hurting you." })

Toggles.NoScreechDamage:OnChanged(function(Value)
	if not FakeEvents.Screech_Real or not RemotesFolder then return end
	pcall(function()
		if Value then
			if FakeEvents.Screech then FakeEvents.Screech.Parent = RemotesFolder end
			FakeEvents.Screech_Real.Parent = nil
		else
			FakeEvents.Screech_Real.Parent = RemotesFolder
			if FakeEvents.Screech then FakeEvents.Screech.Parent = nil end
		end
	end)
end)
Toggles.NoHaltDamage:OnChanged(function(Value)
	if not FakeEvents.Shade_Real or not RemotesFolder then return end
	pcall(function()
		if Value then
			if FakeEvents.Shade then FakeEvents.Shade.Parent = RemotesFolder end
			FakeEvents.Shade_Real.Parent = nil
		else
			FakeEvents.Shade_Real.Parent = RemotesFolder
			if FakeEvents.Shade then FakeEvents.Shade.Parent = nil end
		end
	end)
end)

Toggles.NoA90Damage:OnChanged(function(Value)
	local realRemote = FakeEvents.A90_Real or (RemotesFolder and (RemotesFolder:FindFirstChild("A90") or RemotesFolder:FindFirstChild("A-90")))
	if realRemote then
		FakeEvents.A90_Real = realRemote
		pcall(function()
			if Value then
				if FakeEvents.A90 then FakeEvents.A90.Parent = RemotesFolder end
				realRemote.Parent = nil
			else
				if not (Toggles.RemoveA90 and Toggles.RemoveA90.Value) then
					realRemote.Parent = RemotesFolder
					if FakeEvents.A90 then FakeEvents.A90.Parent = nil end
				end
			end
		end)
	end
end)
Toggles.NoSurgeDamage:OnChanged(function(Value)
	if RemotesFolder:FindFirstChild("SurgeRemote") or FakeEvents.Surge_Real then
		pcall(function()
			if Value then
				if FakeEvents.Surge then FakeEvents.Surge.Parent = RemotesFolder end
				if FakeEvents.Surge_Real then FakeEvents.Surge_Real.Parent = nil end
			else
				if FakeEvents.Surge_Real then FakeEvents.Surge_Real.Parent = RemotesFolder end
				if FakeEvents.Surge then FakeEvents.Surge.Parent = nil end
			end
		end)
	end
end)

local Modules = {}

Functions.FindA90Module = function()
	if Modules and Modules.A90 and Modules.A90.Parent then
		return Modules.A90
	end
	local mainUI = Globals.MainUI or LocalPlayer.PlayerGui:FindFirstChild("MainUI")
	if mainUI then
		local initiator = mainUI:FindFirstChild("Initiator")
		local mainGame = initiator and initiator:FindFirstChild("Main_Game")
		local remoteListener = mainGame and mainGame:FindFirstChild("RemoteListener")
		local uiModules = remoteListener and remoteListener:FindFirstChild("Modules")
		if uiModules then
			local m = uiModules:FindFirstChild("A90") or uiModules:FindFirstChild("A-90") 
				or uiModules:FindFirstChild("A90_Disabled") or uiModules:FindFirstChild("A-90_Disabled")
			if m then return m end
		end
		for _, desc in ipairs(mainUI:GetDescendants()) do
			if desc:IsA("ModuleScript") and (desc.Name == "A90" or desc.Name == "A-90" or desc.Name == "A90_Disabled" or desc.Name == "A-90_Disabled") then
				return desc
			end
		end
	end
	if ClientModules then
		for _, desc in ipairs(ClientModules:GetDescendants()) do
			if desc:IsA("ModuleScript") and (desc.Name == "A90" or desc.Name == "A-90" or desc.Name == "A90_Disabled" or desc.Name == "A-90_Disabled") then
				return desc
			end
		end
	end
	return nil
end

Functions.ApplyRemoveA90 = function(Value)
	local a90Module = Functions.FindA90Module()
	if a90Module then
		Modules.A90 = a90Module
		pcall(function()
			a90Module.Name = Value and "A90_Disabled" or "A90"
		end)
	end

	local realRemote = FakeEvents.A90_Real or (RemotesFolder and (RemotesFolder:FindFirstChild("A90") or RemotesFolder:FindFirstChild("A-90")))
	if realRemote then
		FakeEvents.A90_Real = realRemote
		if Abysall and Abysall.Environment and Abysall.Environment.getconnections then
			pcall(function()
				local conns = Abysall.Environment.getconnections(realRemote.OnClientEvent)
				if conns then
					for _, conn in ipairs(conns) do
						if Value then
							conn:Disable()
						else
							conn:Enable()
						end
					end
				end
			end)
		end
		if RemotesFolder then
			pcall(function()
				if Value then
					if FakeEvents.A90 then FakeEvents.A90.Parent = RemotesFolder end
					realRemote.Parent = nil
				else
					if not (Toggles.NoA90Damage and Toggles.NoA90Damage.Value) then
						realRemote.Parent = RemotesFolder
						if FakeEvents.A90 then FakeEvents.A90.Parent = nil end
					end
				end
			end)
		end
	end

	if Value then
		local mainUI = Globals.MainUI or LocalPlayer.PlayerGui:FindFirstChild("MainUI")
		if mainUI then
			for _, obj in ipairs(mainUI:GetDescendants()) do
				if obj:IsA("GuiObject") and (obj.Name == "A90" or obj.Name == "A-90" or obj.Name == "A90Frame" or obj.Name == "A90Visual" or string.find(string.lower(obj.Name), "a90") ~= nil) then
					obj.Visible = false
					obj:Destroy()
				end
			end
		end
		for _, s in ipairs(Services.SoundService:GetDescendants()) do
			if s:IsA("Sound") and (s.Name == "A90" or s.Name == "A-90" or string.find(string.lower(s.Name), "a90") ~= nil) then
				s.Volume = 0
				s:Stop()
			end
		end
	end
end

local hookedSpiderFunctions = {}

Functions.FindSpiderModules = function()
	local found = {}
	local seen = {}

	local function checkObj(obj)
		if not obj or not obj:IsA("ModuleScript") or seen[obj] then return end
		local name = obj.Name
		local baseName = name:gsub("_Disabled$", "")
		if baseName == "SpiderJumpscare" or baseName == "Spider" or baseName == "Timothy" or baseName == "TimothyJumpscare" then
			seen[obj] = true
			table.insert(found, obj)
		end
	end

	local mainUI = Globals.MainUI or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("MainUI"))
	if mainUI then
		local initiator = mainUI:FindFirstChild("Initiator")
		local mainGame = initiator and initiator:FindFirstChild("Main_Game")
		local remoteListener = mainGame and mainGame:FindFirstChild("RemoteListener")
		if remoteListener then
			for _, folderName in ipairs({"Modules", "Jumpscares", "Cutscenes"}) do
				local folder = remoteListener:FindFirstChild(folderName) or remoteListener:FindFirstChild(folderName .. "_Disabled")
				if folder then
					for _, child in ipairs(folder:GetChildren()) do
						checkObj(child)
					end
				end
			end
			for _, child in ipairs(remoteListener:GetChildren()) do
				checkObj(child)
			end
		end
		for _, desc in ipairs(mainUI:GetDescendants()) do
			checkObj(desc)
		end
	end

	if ClientModules then
		for _, desc in ipairs(ClientModules:GetDescendants()) do
			checkObj(desc)
		end
	end

	if FloorReplicated then
		for _, desc in ipairs(FloorReplicated:GetDescendants()) do
			checkObj(desc)
		end
	end

	if Services.ReplicatedStorage then
		for _, name in ipairs({"SpiderJumpscare", "Spider", "Timothy", "SpiderJumpscare_Disabled", "Spider_Disabled", "Timothy_Disabled"}) do
			local m = Services.ReplicatedStorage:FindFirstChild(name, true)
			if m then checkObj(m) end
		end
	end

	return found
end

Functions.HookSpiderModule = function(spiderModule)
	if not spiderModule or not spiderModule:IsA("ModuleScript") then return end

	local req = Abysall and Abysall.Environment and Abysall.Environment.require or require
	local hf = hookfunction or (Abysall and Abysall.Environment and Abysall.Environment.hookfunction)
	if not hf then return end

	local ok, res = pcall(req, spiderModule)
	if not ok or not res then return end

	local function hookTarget(fn)
		if type(fn) ~= "function" or hookedSpiderFunctions[fn] then return end
		local oldFn
		oldFn = hf(fn, newcclosure(function(...)
			if Toggles.DisableTimothyJumpscare and Toggles.DisableTimothyJumpscare.Value then
				return
			end
			return oldFn(...)
		end))
		hookedSpiderFunctions[fn] = true
		if oldFn and type(oldFn) == "function" then
			hookedSpiderFunctions[oldFn] = true
		end
	end

	if type(res) == "function" then
		hookTarget(res)
	elseif type(res) == "table" then
		for _, v in pairs(res) do
			if type(v) == "function" then
				hookTarget(v)
			end
		end
	end
end

local function CleanSpiderArtifacts()
	local cam = workspace.CurrentCamera or Camera or workspace:FindFirstChild("Camera")
	if cam then
		for _, obj in ipairs(cam:GetChildren()) do
			local n = obj.Name:lower()
			if n:find("spider") or n:find("timothy") then
				pcall(function() obj:Destroy() end)
			end
		end
	end

	for _, s in ipairs(Services.SoundService:GetDescendants()) do
		if s:IsA("Sound") then
			local n = s.Name:lower()
			if n:find("spider") or n:find("timothy") then
				s.Volume = 0
				s:Stop()
			end
		end
	end

	local mainUI = Globals.MainUI or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("MainUI"))
	if mainUI then
		for _, obj in ipairs(mainUI:GetDescendants()) do
			if obj:IsA("GuiObject") then
				local n = obj.Name:lower()
				if n:find("spider") or n:find("timothy") then
					obj.Visible = false
					pcall(function() obj:Destroy() end)
				end
			end
		end
	end
end

Functions.ApplyDisableTimothyJumpscare = function(Value)
	local modulesList = Functions.FindSpiderModules()
	for _, spiderMod in ipairs(modulesList) do
		Modules.SpiderJumpscare = spiderMod

		Functions.HookSpiderModule(spiderMod)

		local baseName = spiderMod.Name:gsub("_Disabled$", "")
		if Value then
			spiderMod.Name = baseName .. "_Disabled"
		else
			spiderMod.Name = baseName
		end
	end

	local spiderRemote = RemotesFolder and (RemotesFolder:FindFirstChild("Spider") or RemotesFolder:FindFirstChild("Timothy") or RemotesFolder:FindFirstChild("SpiderJumpscare"))
	if spiderRemote and Abysall and Abysall.Environment and Abysall.Environment.getconnections then
		pcall(function()
			local conns = Abysall.Environment.getconnections(spiderRemote.OnClientEvent)
			if conns then
				for _, conn in ipairs(conns) do
					if Value then
						conn:Disable()
					else
						conn:Enable()
					end
				end
			end
		end)
	end

	if Value then
		CleanSpiderArtifacts()
	end
end

Toggles.RemoveScreech:OnChanged(function(Value)
	if Value then
		task.spawn(function()
			while Toggles.RemoveScreech.Value do
				local Camera = workspace:FindFirstChild("Camera")

				if Camera then
					local Screech = Camera:FindFirstChild("Screech")

					if Screech then
						Screech:Destroy()
					end
				end

				task.wait()
			end
		end)
	end
end)
Toggles.RemoveHalt:OnChanged(function(Value)
	if Modules and Modules.Shade then
		Modules.Shade.Name = Value and "Shade_Disabled" or "Shade"
	end
end)
Toggles.RemoveA90:OnChanged(function(Value)
	Functions.ApplyRemoveA90(Value)
	if Value then
		task.spawn(function()
			while Toggles.RemoveA90.Value do
				local a90Module = Functions.FindA90Module()
				if a90Module and a90Module.Name ~= "A90_Disabled" then
					a90Module.Name = "A90_Disabled"
				end

				local realRemote = FakeEvents.A90_Real or (RemotesFolder and (RemotesFolder:FindFirstChild("A90") or RemotesFolder:FindFirstChild("A-90")))
				if realRemote then
					FakeEvents.A90_Real = realRemote
					if Abysall and Abysall.Environment and Abysall.Environment.getconnections then
						pcall(function()
							for _, conn in ipairs(Abysall.Environment.getconnections(realRemote.OnClientEvent)) do
								conn:Disable()
							end
						end)
					end
				end

				local mainUI = Globals.MainUI or LocalPlayer.PlayerGui:FindFirstChild("MainUI")
				if mainUI then
					for _, obj in ipairs(mainUI:GetChildren()) do
						if obj:IsA("GuiObject") and (obj.Name == "A90" or obj.Name == "A-90" or string.find(string.lower(obj.Name), "a90") ~= nil) then
							obj.Visible = false
							obj:Destroy()
						end
					end
					local mf = mainUI:FindFirstChild("MainFrame")
					if mf then
						for _, obj in ipairs(mf:GetChildren()) do
							if obj:IsA("GuiObject") and (obj.Name == "A90" or obj.Name == "A-90" or string.find(string.lower(obj.Name), "a90") ~= nil) then
								obj.Visible = false
								obj:Destroy()
							end
						end
					end
				end

				task.wait(0.2)
			end
		end)
	end
end)
Toggles.RemoveDread:OnChanged(function(Value)
	if Modules.Dread then
		Modules.Dread.Name = Value and "Dread_Disabled" or "Dread"
	end
end)
Toggles.RemoveSurge:OnChanged(function(Value)
	if Globals.SurgeFrame then
		Globals.SurgeFrame.Name = (Value and "SurgeVignette_Disabled" or "SurgeVignette")
	end
end)

Groupboxes.Exploits_Audio = Tabs.Exploits:AddLeftGroupbox("Audio")
do
	local soundMain = Services.SoundService:WaitForChild("Main", 2) or Services.SoundService:FindFirstChild("Main")
	Globals.JamMuffle = (soundMain and soundMain:FindFirstChild("Jamming")) or Instance.new("EqualizerSoundEffect")
end

Groupboxes.Exploits_Audio:AddToggle("RemoveFootstepSounds",    { Text = "Remove Footstep Sounds",    Default = false, Tooltip = "Removes the sounds when walking." })
Groupboxes.Exploits_Audio:AddToggle("RemoveJamminMusic",       { Text = "Remove Jammin Music",       Default = false, Tooltip = "Removes the music and muffle effect from the 'Jammin' modifier." })
Groupboxes.Exploits_Audio:AddToggle("RemoveInteractingSounds", { Text = "Remove Interacting Sounds", Default = false, Tooltip = "Removes the sounds when interacting with proximity prompts." })

Toggles.RemoveJamminMusic:OnChanged(function(Value)
	local Jam = Globals.MainUI.Initiator.Main_Game.Health:FindFirstChild("Jam")
	if Jam then
		Jam.Volume = Value and 0 or 0.45
		Globals.JamMuffle.Enabled = LiveModifiers:FindFirstChild("Jammin") and not Value or false
	end
end)
Toggles.RemoveInteractingSounds:OnChanged(function(Value)
	pcall(function()
		local MainUI = Globals.MainUI or (LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("MainUI"))
		local Initiator = MainUI and MainUI:FindFirstChild("Initiator")
		local MainGame = Initiator and Initiator:FindFirstChild("Main_Game")
		if not MainGame then return end

		local PS = MainGame:FindFirstChild("PromptService")
		if PS then
			if PS:FindFirstChild("Triggered") then PS.Triggered.Volume = Value and 0 or 0.04 end
			if PS:FindFirstChild("Holding") then PS.Holding.Volume = Value and 0 or 0.1 end
			if PS:FindFirstChild("Notification") then PS.Notification.Volume = Value and 0 or 0.03 end
		end

		local Reminder = MainGame:FindFirstChild("Reminder")
		local Caption = Reminder and Reminder:FindFirstChild("Caption")
		if Caption then
			Caption.Volume = Value and 0 or 0.1
		end
	end)
end)

Groupboxes.Visuals_LeftTab = Tabs.Visuals:AddLeftTabbox("Camera / Effects")
Groupboxes.Visuals_Camera = Groupboxes.Visuals_LeftTab:AddTab("Camera")
Groupboxes.Visuals_Camera:AddToggle("AmbientToggle", { Text = "Ambient", Default = false, Tooltip = "Changes the lighting color to the specified value." })
Groupboxes.Visuals_Camera:AddSlider("FieldOfView", { Text = "Field of View", Min = 1, Max = 120, Default = 70, Rounding = 0 })
Groupboxes.Visuals_Camera:AddToggle("FOVToggle", {    Text = "Custom FOV",    Default = false,    Tooltip = "Only applies the Field of View slider when enabled." })
Toggles.FOVToggle:AddKeyPicker("FovToggle", {Text = "Custom Fov", Default = "O", Mode = "Toggle", SyncToggleState = true})
Groupboxes.Visuals_Camera:AddDivider()
Groupboxes.Visuals_Camera:AddToggle("RemoveCameraShake", {
	Text = "Remove Camera Shake", Default = false, Tooltip = "Prevents the camera from shaking.",
	Disabled = not Functions.CheckCompatability({"require"}), DisabledTooltip = Globals.IncompatibleMessage
})
Groupboxes.Visuals_Camera:AddToggle("RemoveCameraBobbing", {
	Text = "Remove Camera Bobbing", Default = false, Tooltip = "Prevents the camera from bobbing when moving.",
	Disabled = not Functions.CheckCompatability({"require"}), DisabledTooltip = Globals.IncompatibleMessage
})
Groupboxes.Visuals_Camera:AddToggle("RemoveCutscenes", { Text = "Remove Cutscenes", Default = false, Tooltip = "Removes all non-necessary cutscenes." })
Groupboxes.Visuals_Camera:AddToggle("RemoveCameraFog", { Text = "Remove Fog", Default = false, Tooltip = "Removes all fog effects from the camera." })
Groupboxes.Visuals_Camera:AddDivider()
Groupboxes.Visuals_Camera:AddToggle("ThirdPersonToggle", { Text = "Third Person", Default = false, Tooltip = "Zooms out your camera, allowing you to see your character from behind." })
Toggles.ThirdPersonToggle:OnChanged(function(Value)
	for _, Part in ipairs(Globals.ThirdPersonParts) do
		if Part and Part.Parent then
			Part.Transparency = 0
			Part.LocalTransparencyModifier = Value and 0 or 1
		end
	end
end)
Toggles.ThirdPersonToggle:AddKeyPicker("ThirdPersonKeybind", { Text = "Third Person", Default = "T", Mode = "Toggle", SyncToggleState = true })
Groupboxes.Visuals_Camera:AddSlider("ThirdPersonOffsetX", { Text = "X Offset", Min = -10, Max = 10, Default = 1.5, Rounding = 1, Compact = true })
Groupboxes.Visuals_Camera:AddSlider("ThirdPersonOffsetY", { Text = "Y Offset", Min = -10, Max = 10, Default = 1,   Rounding = 1, Compact = true })
Groupboxes.Visuals_Camera:AddSlider("ThirdPersonOffsetZ", { Text = "Z Offset", Min = -10, Max = 10, Default = 5,   Rounding = 1, Compact = true })
Groupboxes.Visuals_Camera:AddToggle("ThirdPersonWallCheck", { Text = "Wall Check", Default = false, Tooltip = "Prevents third person from going through walls." })
Groupboxes.Visuals_Camera:AddDivider()
Groupboxes.Visuals_Camera:AddToggle("ViewmodelOffsetToggle", {
	Text = "Viewmodel Offset", Default = false, Tooltip = "Changes the offset of your viewmodel while holding an item.",
	Disabled = not Functions.CheckCompatability({"require"}), DisabledTooltip = Globals.IncompatibleMessage
})
Groupboxes.Visuals_Camera:AddSlider("ViewmodelOffsetX", { Text = "X Offset", Min = -10, Max = 10, Default = 0, Rounding = 1, Compact = true, Disabled = not Functions.CheckCompatability({"require"}), DisabledTooltip = Globals.IncompatibleMessage })
Groupboxes.Visuals_Camera:AddSlider("ViewmodelOffsetY", { Text = "Y Offset", Min = -10, Max = 10, Default = 0, Rounding = 1, Compact = true, Disabled = not Functions.CheckCompatability({"require"}), DisabledTooltip = Globals.IncompatibleMessage })
Groupboxes.Visuals_Camera:AddSlider("ViewmodelOffsetZ", { Text = "Z Offset", Min = -10, Max = 10, Default = 0, Rounding = 1, Compact = true, Disabled = not Functions.CheckCompatability({"require"}), DisabledTooltip = Globals.IncompatibleMessage })

Toggles.AmbientToggle:AddColorPicker("AmbientColor", { Text = "Ambient", Default = Color3.fromRGB(255, 255, 255), Transparency = 0 })
Toggles.AmbientToggle:OnChanged(function(Value)
	local currentRoomNum = LocalPlayer:GetAttribute("CurrentRoom")
	local roomObj = currentRoomNum and CurrentRooms and CurrentRooms:FindFirstChild(tostring(currentRoomNum))
	local OldAmbient = roomObj and roomObj:GetAttribute("Ambient") or Services.Lighting.Ambient

	Services.TweenService:Create(Services.Lighting, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {
		Ambient = Value and Options.AmbientColor.Value or OldAmbient
	}):Play()
end)

local Main_Game
local ClientModules

Toggles.RemoveCameraBobbing:OnChanged(function(Value)
	if Main_Game then Main_Game.spring.Speed = Value and 9e9 or 8 end
end)
Toggles.RemoveCameraFog:OnChanged(function(Value)
	Services.Lighting.FogEnd = Value and 10000000 or Globals.OldFog
	for _, Object in Globals.FogInstances do
		Object.Density = Value and 0 or Object:GetAttribute("Density_Old")
	end
end)
Toggles.RemoveCutscenes:OnChanged(function(Value)
    local Cutscenes = Globals.MainUI.Initiator.Main_Game.RemoteListener.Cutscenes
    for _, Object in pairs(Cutscenes:GetChildren()) do
        if table.find(CutsceneNames, Object.Name) and Object:IsA("ModuleScript") or table.find(CutsceneNames, Object:GetAttribute("OriginalName")) and Object:IsA("ModuleScript") then
            Object.Name = (Value and Object.Name .. "_Disabled" or Object:GetAttribute("OriginalName"))
        end
    end
    for _, Object in pairs(FloorReplicated:GetChildren()) do
        if table.find(CutsceneNames, Object.Name) and Object:IsA("ModuleScript") or table.find(CutsceneNames, Object:GetAttribute("OriginalName")) and Object:IsA("ModuleScript") then
            Object.Name = (Value and Object.Name .. "_Disabled" or Object:GetAttribute("OriginalName"))
        end
    end
end)

Groupboxes.Visuals_Effects = Groupboxes.Visuals_LeftTab:AddTab("Effects")
Groupboxes.Visuals_Effects:AddToggle("TransparentHidingSpotsToggle", { Text = "Transparent Hiding Spots", Default = false, Tooltip = "Makes a hiding spot transparent when you enter it." })
Groupboxes.Visuals_Effects:AddSlider("TransparentHidingSpotsSlider", { Text = "Transparency", Min = 0, Max = 1, Default = 0.5, Rounding = 2, Compact = true })

local function ApplyHidingTransparency(Value, SliderValue)
	for _, Object in Objects.HidingSpots do
		local IsHiding = false
		for _, Child in Object:GetDescendants() do
			if Child.Name == "HiddenPlayer" and Child.Value == Character then
				IsHiding = true
				break
			end
		end
		for _, Part in Object:GetDescendants() do
			if Part:IsA("BasePart") and Part:GetAttribute("Transparency_Old") then
				Services.TweenService:Create(Part, TweenInfo.new(0.25, Enum.EasingStyle.Linear), {
					Transparency = (Value and IsHiding) and SliderValue or Part:GetAttribute("Transparency_Old")
				}):Play()
			end
		end
	end
end

Toggles.TransparentHidingSpotsToggle:OnChanged(function(Value)
	ApplyHidingTransparency(Value, Options.TransparentHidingSpotsSlider.Value)
end)
Options.TransparentHidingSpotsSlider:OnChanged(function(Value)
	ApplyHidingTransparency(Toggles.TransparentHidingSpotsToggle.Value, Value)
end)

Groupboxes.Visuals_Effects:AddDivider()
Groupboxes.Visuals_Effects:AddToggle("DisableGlitchJumpscare",   { Text = "Disable Glitch Jumpscare",   Default = false, Tooltip = "Disables the jumpscare from 'Glitch'" })
Groupboxes.Visuals_Effects:AddToggle("DisableTimothyJumpscare",  { Text = "Disable Timothy Jumpscare",  Default = false, Tooltip = "Disables the jumpscare from 'Timothy'" })
Groupboxes.Visuals_Effects:AddToggle("DisableVoidJumpscare",     { Text = "Disable Void Jumpscare",     Default = false, Tooltip = "Disables the jumpscare from 'Void'" })
Groupboxes.Visuals_Effects:AddDivider()
Groupboxes.Visuals_Effects:AddToggle("DisableHideVignette",      { Text = "Disable Hide Vignette",      Default = false, Tooltip = "Disables the hiding screen effect." })
Groupboxes.Visuals_Effects:AddToggle("DisableFiredampEffect",    { Text = "Disable Firedamp Effect",    Default = false, Tooltip = "Disables the firedamp screen effect." })
Groupboxes.Visuals_Effects:AddToggle("DisableEntityJumpscares",  { Text = "Disable Entity Jumpscares",  Default = false, Tooltip = "Disables jumpscares from entities like Rush and Ambush." })

Toggles.DisableGlitchJumpscare:OnChanged(function(Value)
	if Modules and Modules.Glitch then
		Modules.Glitch.Name = Value and "Glitch_Disabled" or "Glitch"
	end
end)
Toggles.DisableTimothyJumpscare:OnChanged(function(Value)
	if Functions.ApplyDisableTimothyJumpscare then
		Functions.ApplyDisableTimothyJumpscare(Value)
	elseif Modules and Modules.SpiderJumpscare then
		Modules.SpiderJumpscare.Name = Value and "SpiderJumpscare_Disabled" or "SpiderJumpscare"
	end

	if Value then
		task.spawn(function()
			while Toggles.DisableTimothyJumpscare.Value do
				local cam = workspace.CurrentCamera or Camera or workspace:FindFirstChild("Camera")
				if cam then
					for _, obj in ipairs(cam:GetChildren()) do
						local n = obj.Name:lower()
						if n:find("spider") or n:find("timothy") then
							pcall(function() obj:Destroy() end)
						end
					end
				end
				task.wait(0.25)
			end
		end)
	end
end)
Toggles.DisableVoidJumpscare:OnChanged(function(Value)
	if Modules.Void then Modules.Void.Name = Value and "Void_Disabled" or "Void" end
end)
Toggles.DisableHideVignette:OnChanged(function(Value)
	local Vignette = Globals.MainUI:FindFirstChild("HideVignette") or Globals.MainUI.MainFrame:FindFirstChild("HideVignette")
	if Vignette then Vignette.Image = Value and "Disabled" or "rbxassetid://6100076320" end
end)
Toggles.DisableFiredampEffect:OnChanged(function(Value)
	for _, Object in CurrentRooms:GetChildren() do
		if Value then
			Object:SetAttribute("Firedamp", false)
			for _, FiredampObj in Camera:GetChildren() do
				if FiredampObj.Name == "LiveFiredamp" then FiredampObj:Destroy() end
			end
		else
			Object:SetAttribute("Firedamp", Object:GetAttribute("Firedamp_Old"))
		end
	end
	local Old = LocalPlayer:GetAttribute("CurrentRoom")
	LocalPlayer:SetAttribute("CurrentRoom", 0)
	task.wait()
	LocalPlayer:SetAttribute("CurrentRoom", Old)
end)
Toggles.DisableEntityJumpscares:OnChanged(function(Value)
	local Jumpscares = Globals.MainUI.Initiator.Main_Game.RemoteListener:FindFirstChild("Jumpscares")
		or Globals.MainUI.Initiator.Main_Game.RemoteListener:FindFirstChild("Jumpscares_Disabled")
	if Jumpscares then
		Jumpscares.Name = Value and "Jumpscares_Disabled" or "Jumpscares"
		for _, Object in Objects.JumpscareModules do
			Object.Name = Value and (Object:GetAttribute("OriginalName") .. "_Disabled") or Object:GetAttribute("OriginalName")
		end
	end
end)

Groupboxes.Visuals_RightTab     = Tabs.Visuals:AddRightTabbox("Entities / Settings / Entity Nodes")
Groupboxes.Visuals_Entities     = Groupboxes.Visuals_RightTab:AddTab("Entities")
Groupboxes.Visuals_EntitySettings = Groupboxes.Visuals_RightTab:AddTab("Settings")

Groupboxes.Visuals_Entities:AddDropdown("EntityList", {
	Text = "Entity List",
	Values = { "Rush","Bash","Scribbles","Teller","DronesStampede","Creak","Noise","Noise_TV","Balls","Portrait","Ambush","Eyes","Halt","Blitz","Lookman","Gloombat Swarm","A-60","A-120","Sally","Jeff the Killer","Groundskeeper","Monument","AR0xMBUSH","RNIUSHCG==" },
	Multi = true, AllowNull = true
})
Groupboxes.Visuals_Entities:AddToggle("NotifyEntities",    { Text = "Notify Entities",    Default = false, Tooltip = "Sends a notification when an entity spawns." })
Groupboxes.Visuals_Entities:AddDivider()
Groupboxes.Visuals_Entities:AddToggle("ShowEntityPath", {
    Text = "Show Entity Path",
    Default = false,
    Tooltip = "Shows the path of entitys."
})


-- i dont wanna hear it okay? i was sick okay let me be okay fuck u okay




Groupboxes.Visuals_Entities:AddToggle("ShowEntityPath", {
    Text = "Show Entity Path",
    Default = false,
    Tooltip = "Shows the path of entitys."
})

Groupboxes.Visuals_Entities:AddSlider("ShowEntityPathNodeTransparency", {
    Text = "Node Transparency",
    Default = 0,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Compact = false,
    Tooltip = "Transparency of the path nodes when shown"
})

Groupboxes.Visuals_Entities:AddSlider("ShowEntityPathLineTransparency", {
    Text = "Line Transparency",
    Default = 0.15,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Compact = false,
    Tooltip = "Transparency of the path lines"
})

Groupboxes.Visuals_Entities:AddSlider("ShowEntityPathLineThickness", {
    Text = "Line Thickness",
    Default = 0.3,
    Min = 0.08,
    Max = 1.2,
    Rounding = 2
})

do
local ShowEntityPathLines = {}

local function ShowEntityPathClearAllLines()
    for _, ShowEntityPathRoomLines in pairs(ShowEntityPathLines) do
        for _, ShowEntityPathLine in ipairs(ShowEntityPathRoomLines) do
            if ShowEntityPathLine and ShowEntityPathLine.Parent then
                ShowEntityPathLine:Destroy()
            end
        end
    end
    table.clear(ShowEntityPathLines)
end

local function ShowEntityPathCreateLine(ShowEntityPathPoint1, ShowEntityPathPoint2, ShowEntityPathTransparency, ShowEntityPathThickness, ShowEntityPathParent)
    local ShowEntityPathDistance = (ShowEntityPathPoint1 - ShowEntityPathPoint2).Magnitude
    if ShowEntityPathDistance < 0.05 then
        return nil
    end

    local ShowEntityPathLinePart = Instance.new("Part")
    ShowEntityPathLinePart.Name = "PathLine"
    ShowEntityPathLinePart.Anchored = true
    ShowEntityPathLinePart.CanCollide = false
    ShowEntityPathLinePart.CanQuery = false
    ShowEntityPathLinePart.CanTouch = false
    ShowEntityPathLinePart.CastShadow = false
    ShowEntityPathLinePart.Material = Enum.Material.ForceField
    ShowEntityPathLinePart.Color = Color3.fromRGB(0, 255, 210)
    ShowEntityPathLinePart.Transparency = ShowEntityPathTransparency
    ShowEntityPathLinePart.Size = Vector3.new(ShowEntityPathThickness, ShowEntityPathThickness, ShowEntityPathDistance)
    ShowEntityPathLinePart.CFrame = CFrame.lookAt(ShowEntityPathPoint1, ShowEntityPathPoint2) * CFrame.new(0, 0, -ShowEntityPathDistance / 2)
    ShowEntityPathLinePart.Parent = ShowEntityPathParent
    return ShowEntityPathLinePart
end

local function ShowEntityPathGetSortedNodes(ShowEntityPathNodes)
    local ShowEntityPathSortedNodes = {}
    for _, ShowEntityPathNode in ipairs(ShowEntityPathNodes:GetChildren()) do
        if ShowEntityPathNode:IsA("BasePart") then
            local ShowEntityPathNodeNumber = tonumber(ShowEntityPathNode.Name)
            if ShowEntityPathNodeNumber then
                table.insert(ShowEntityPathSortedNodes, {
                    Part = ShowEntityPathNode,
                    Number = ShowEntityPathNodeNumber
                })
            end
        end
    end
    table.sort(ShowEntityPathSortedNodes, function(a, b)
        return a.Number < b.Number
    end)
    return ShowEntityPathSortedNodes
end

local function ShowEntityPathSetNodeTransparency(ShowEntityPathTransparency)
    for _, ShowEntityPathRoom in ipairs(workspace.CurrentRooms:GetChildren()) do
        local ShowEntityPathNodes = ShowEntityPathRoom:FindFirstChild("PathfindNodes")
        if ShowEntityPathNodes then
            for _, ShowEntityPathNode in ipairs(ShowEntityPathNodes:GetChildren()) do
                if ShowEntityPathNode:IsA("BasePart") then
                    ShowEntityPathNode.Transparency = ShowEntityPathTransparency
                end
            end
        end
    end
end

local function ShowEntityPathSetLineTransparency(ShowEntityPathTransparency)
    for _, ShowEntityPathRoomLines in pairs(ShowEntityPathLines) do
        for _, ShowEntityPathLine in ipairs(ShowEntityPathRoomLines) do
            if ShowEntityPathLine and ShowEntityPathLine.Parent then
                ShowEntityPathLine.Transparency = ShowEntityPathTransparency
            end
        end
    end
end

local function ShowEntityPathUpdateAll()
    local ShowEntityPathShow = Toggles.ShowEntityPath.Value
    local ShowEntityPathNodeTransparency = ShowEntityPathShow and Options.ShowEntityPathNodeTransparency.Value or 1
    local ShowEntityPathLineTransparency = Options.ShowEntityPathLineTransparency.Value
    local ShowEntityPathLineThickness = Options.ShowEntityPathLineThickness.Value

    ShowEntityPathClearAllLines()

    if not ShowEntityPathShow then
        ShowEntityPathSetNodeTransparency(1)
        return
    end

    ShowEntityPathSetNodeTransparency(ShowEntityPathNodeTransparency)

    local ShowEntityPathValidRooms = {}
    for _, ShowEntityPathRoom in ipairs(workspace.CurrentRooms:GetChildren()) do
        if ShowEntityPathRoom:FindFirstChild("PathfindNodes") then
            table.insert(ShowEntityPathValidRooms, ShowEntityPathRoom)
        end
    end

    table.sort(ShowEntityPathValidRooms, function(a, b)
        return (tonumber(a.Name) or 0) < (tonumber(b.Name) or 0)
    end)

    for _, ShowEntityPathRoom in ipairs(ShowEntityPathValidRooms) do
        local ShowEntityPathNodes = ShowEntityPathRoom.PathfindNodes
        local ShowEntityPathSortedNodes = ShowEntityPathGetSortedNodes(ShowEntityPathNodes)

        if #ShowEntityPathSortedNodes > 0 then
            local ShowEntityPathRoomLines = {}

            for i = 1, #ShowEntityPathSortedNodes - 1 do
                local ShowEntityPathFrom = ShowEntityPathSortedNodes[i].Part
                local ShowEntityPathTo = ShowEntityPathSortedNodes[i + 1].Part

                local ShowEntityPathLine = ShowEntityPathCreateLine(
                    ShowEntityPathFrom.Position,
                    ShowEntityPathTo.Position,
                    ShowEntityPathLineTransparency,
                    ShowEntityPathLineThickness,
                    ShowEntityPathRoom
                )
                if ShowEntityPathLine then
                    table.insert(ShowEntityPathRoomLines, ShowEntityPathLine)
                end
            end

            if #ShowEntityPathRoomLines > 0 then
                ShowEntityPathLines[ShowEntityPathRoom] = ShowEntityPathRoomLines
            end
        end
    end
end

Toggles.ShowEntityPath:OnChanged(function()
    if ShowEntityPathChildAddedConnection then
        ShowEntityPathChildAddedConnection:Disconnect()
        ShowEntityPathChildAddedConnection = nil
    end

    ShowEntityPathUpdateAll()

    if Toggles.ShowEntityPath.Value then
        ShowEntityPathChildAddedConnection = workspace.CurrentRooms.ChildAdded:Connect(function(ShowEntityPathRoom)
            if ShowEntityPathRoom:WaitForChild("PathfindNodes", 5) then
                task.wait(0.1)
                ShowEntityPathUpdateAll()
            end
        end)
    end
end)

Options.ShowEntityPathNodeTransparency:OnChanged(function()
    if Toggles.ShowEntityPath.Value then
        ShowEntityPathSetNodeTransparency(Options.ShowEntityPathNodeTransparency.Value)
    end
end)

Options.ShowEntityPathLineTransparency:OnChanged(function()
    if Toggles.ShowEntityPath.Value then
        ShowEntityPathSetLineTransparency(Options.ShowEntityPathLineTransparency.Value)
    end
end)

Options.ShowEntityPathLineThickness:OnChanged(function()
    if Toggles.ShowEntityPath.Value then
        ShowEntityPathUpdateAll()
    end
end)
end


Groupboxes.Visuals_Entities:AddDivider()

local ItemsToNotify = {}
for Index, Name in pairs(ItemNames) do
	if not table.find(ItemsToNotify, Name) then
		table.insert(ItemsToNotify, Name)
	end
end
table.sort(ItemsToNotify)

Groupboxes.Visuals_Entities:AddDropdown("NotifyItemList", {
	Text = "Item List",
	Values = ItemsToNotify,
	Multi = true, AllowNull = true
})
Groupboxes.Visuals_Entities:AddToggle("NotifyItemsToggle",    { Text = "Notify Items",    Default = false, Tooltip = "Sends a notification when an item spawns." })
Groupboxes.Visuals_Entities:AddToggle("NotifyItemsShowDistance",    { Text = "Show Distance",    Default = false, Tooltip = "Shows how far away the item is in the notification." })
Groupboxes.Visuals_Entities:AddDivider()
Groupboxes.Visuals_Entities:AddToggle("NotifyLibraryCode", { Text = "Notify Library Code", Default = false, Tooltip = "Automatically solves the code for the library padlock." })
Groupboxes.Visuals_Entities:AddToggle("NotifyOxygen",      { Text = "Notify Oxygen Level", Default = false, Tooltip = "Shows how much oxygen you have remaining." })
Groupboxes.Visuals_Entities:AddToggle("NotifyHasteTime",   { Text = "Notify Haste Time",   Default = false, Tooltip = "Shows how much time you have remaining before 'Haste' spawns." })

Globals.LibraryCodeFound = false
Toggles.NotifyLibraryCode:OnChanged(function(Value)
	if Value then
		local Code = Functions.GetLibraryCode()
		if Code and not Code:find("_") and not Globals.LibraryCodeFound and CurrentRooms:FindFirstChild("50") then
			local Lock = Services.Workspace:FindFirstChild("Padlock", true)
			Functions.Notify({ Title = "Padlock code found!", Body = "The code is: '" .. Code .. "'", Time = Toggles.NotifyKeepNotifications.Value and Lock or 15 })
			Globals.LibraryCodeFound = true
		end
	end
end)

Groupboxes.Visuals_EntitySettings:AddToggle("EntityChatToggle", { Text = "Notify Chat", Default = false, Tooltip = "Sends a message in the chat when an entity spawns." })
Groupboxes.Visuals_EntitySettings:AddInput("EntityChatMessage", { Text = "Message", Default = "spawned!", Numeric = false, Placeholder = "Message" })
Groupboxes.Visuals_EntitySettings:AddDivider()
Groupboxes.Visuals_EntitySettings:AddDropdown("NotifyStyle", { Text = "Notify Style", Values = { "Abysall", "Doors", "STX", "Library" }, Default = 1 })
Groupboxes.Visuals_EntitySettings:AddSlider("NotifySoundVolume", { Text = "Sound Volume", Min = 0, Max = 10, Default = 3, Rounding = 1 })
Groupboxes.Visuals_EntitySettings:AddToggle("NotifyPlaySound", { Text = "Play Sound", Default = true, Tooltip = "Makes notifications play an alert sound." })
Groupboxes.Visuals_EntitySettings:AddToggle("NotifyKeepNotifications", { Text = "Keep Notifications", Default = false, Tooltip = "Certain notifications will stay on screen until they are no longer needed." })
Groupboxes.Visuals_EntitySettings:AddButton({ Text = "Test Notification", DoubleClick = false, Tooltip = "Sends a test notifcation, so you can see how your settings look.", Func = function()
	Functions.Notify({Title = "This is a test."})
end})

Groupboxes.Visuals_ESP          = Tabs.Visuals:AddRightTabbox("ESP/Settings")
Groupboxes.Visuals_ESP_Toggles  = Groupboxes.Visuals_ESP:AddTab("ESP")
Groupboxes.Visuals_ESP_Settings = Groupboxes.Visuals_ESP:AddTab("Settings")

local function MakeESPToggle(ToggleKey, ColorKey, Text, Tooltip, ObjectsTable, LabelFunc, RoomBased)
	Groupboxes.Visuals_ESP_Toggles:AddToggle(ToggleKey, { Text = Text, Default = false, Tooltip = Tooltip })
	Toggles[ToggleKey]:AddColorPicker(ColorKey, { Text = Text, Default = Options[ColorKey] and Options[ColorKey].Value or Color3.new(1,1,1), Transparency = 0 })
	Toggles[ToggleKey]:OnChanged(function(Value)
		for _, Object in ObjectsTable do
			if Value then
				local Label, UseRoom = LabelFunc(Object)
				if Label then
					Functions.AddESP({ Object = Object, Text = Label, Color = Options[ColorKey].Value }, UseRoom ~= nil and UseRoom or RoomBased)
				end
			else
				Functions.RemoveESP(Object)
			end
		end
	end)
	Options[ColorKey]:OnChanged(function(Value)
		for _, Object in ObjectsTable do
			Abysall.ESPLibrary:UpdateObjectColor(Object, Value)
		end
	end)
end

Groupboxes.Visuals_ESP_Toggles:AddToggle("ObjectiveESPToggle", { Text = "Objectives", Default = false, Tooltip = "Highlights all objects required to progress." })
Toggles.ObjectiveESPToggle:AddColorPicker("ObjectiveESPColor", { Text = "Objectives", Default = Color3.fromRGB(0, 255, 0), Transparency = 0 })

local ObjectiveLabels = {
	["StairwellLockpickDoor"]  = "Garage Door",
	["Mirror"]				   = "Mirror",
	["ShoppingCart"]		   = "Shopping Cart",
	["StairwellFireAlarm"]     = "Fire Alarm",
	["StairwellScrapper"]	   = "Scrapper",
	["ArchivesPackageDeposit"] = "BoxDeposit",
	["Cellar"] 				   = "Cellar",
	["ArchivesFihTank"]        = "Fih Tank",
	["KeyObtain"]              = "Door Key",
	["ElectricalKeyObtain"]    = "Electrical Key",
	["MinesGenerator"]         = "Generator",
	["FuseObtain"]             = "Generator Fuse",
	["LiveHintBook"]           = "Hint Book",
	["LiveBreakerPolePickup"]  = "Fuse Breaker",
	["LibraryHintPaper"]       = "Hint Paper",
	["PickupItem"]             = "Hint Paper",
	["CringlePresent"]         = "Present",
	["LeverForGate"]           = "Gate Lever",
	["MinesGateButton"]        = "Gate Button",
	["GardenGateButton"]       = "Gate Button",
}

Toggles.ObjectiveESPToggle:OnChanged(function(Value)
	for _, Object in Objects.Objectives do
		if Value then
			local Label = ObjectiveLabels[Object.Name]
			if Object.Name == "TimerLever" then
				Label = "Time Lever [+" .. Object:GetAttribute("AddTime") .. "s]"
			elseif Object.Name == "MinesAnchor" then
				Label = "Anchor [" .. Object:WaitForChild("Sign").TextLabel.Text .. "]"
			elseif Object.Name == "WaterPump" then
				Functions.AddESP({ Object = Object.Wheel, Text = "Water Pump", Color = Options.ObjectiveESPColor.Value }, true)
			elseif Object.Name == "VineGuillotine" then
				Functions.AddESP({ Object = Object.Lever, Text = "Vine Lever", Color = Options.ObjectiveESPColor.Value }, true)
			end
			if Label then
				Functions.AddESP({ Object = Object, Text = Label, Color = Options.ObjectiveESPColor.Value }, true)
			end
		else
			Functions.RemoveESP(Object)
		end
	end
end)
Options.ObjectiveESPColor:OnChanged(function(Value)
	for _, Object in Objects.Objectives do
		Abysall.ESPLibrary:UpdateObjectColor(Object, Value)
	end
end)

Groupboxes.Visuals_ESP_Toggles:AddToggle("DoorESPToggle",       { Text = "Doors",        Default = false, Tooltip = "Highlights the next door." })
Groupboxes.Visuals_ESP_Toggles:AddToggle("HidingSpotESPToggle", { Text = "Hiding Spots", Default = false, Tooltip = "Highlights places where you can hide from entities" })
Groupboxes.Visuals_ESP_Toggles:AddToggle("PlayerESPToggle",     { Text = "Players",      Default = false, Tooltip = "Highlights other players." })
Groupboxes.Visuals_ESP_Toggles:AddToggle("ChestESPToggle",      { Text = "Chests",       Default = false, Tooltip = "Highlights objects that can contain loot." })
Groupboxes.Visuals_ESP_Toggles:AddToggle("ItemESPToggle",       { Text = "Items",        Default = false, Tooltip = "Highlights all collectable items/consumables." })
Groupboxes.Visuals_ESP_Toggles:AddToggle("CurrencyESPToggle",   { Text = "Currency",     Default = false, Tooltip = "Highlights all currency that spawns." })
Groupboxes.Visuals_ESP_Toggles:AddToggle("LadderESPToggle",     { Text = "Ladders",      Default = false, Tooltip = "Highlights ladders that can be used to disable the anticheat." })
Groupboxes.Visuals_ESP_Toggles:AddToggle("MiscESPToggle",       { Text = "Misc",         Default = false, Tooltip = "Highlights miscellaneous objects that can be used to disable the anticheat." })
Groupboxes.Visuals_ESP_Toggles:AddDivider()
Groupboxes.Visuals_ESP_Toggles:AddDropdown("EntityESPOptions",     { 
	Text = "Entity List",
	Values = { "Rush","Bash","Scribbles","Teller","DronesStampede","Creak","Noise","Noise_TV","Balls","Portrait","Ambush","Eyes","Dupe","Figure","Blitz","Lookman","Snare","Giggle","Gloombat Eggs","Grumble","A-60","A-120","Sally","Jeff the Killer","Groundskeeper","Mandrake Hole","Monument","Bramble","AR0xMBUSH","RNIUSHCG==" },
	Multi = true,
	AllowNull = true
})
Groupboxes.Visuals_ESP_Toggles:AddToggle("EntityESPToggle",     { Text = "Entities",      Default = false, Tooltip = "Highlights all entities that spawn." })

Toggles.DoorESPToggle:AddColorPicker("DoorESPColor",           { Text = "Doors",        Default = Color3.fromRGB(0, 200, 255),  Transparency = 0 })
Toggles.HidingSpotESPToggle:AddColorPicker("HidingSpotESPColor", { Text = "Hiding Spots", Default = Color3.fromRGB(255, 170, 0),  Transparency = 0 })
Toggles.PlayerESPToggle:AddColorPicker("PlayerESPColor",       { Text = "Players",      Default = Color3.fromRGB(255, 255, 255), Transparency = 0 })
Toggles.ChestESPToggle:AddColorPicker("ChestESPColor",         { Text = "Chests",       Default = Color3.fromRGB(255, 255, 0),   Transparency = 0 })
Toggles.ItemESPToggle:AddColorPicker("ItemESPColor",           { Text = "Items",        Default = Color3.fromRGB(170, 0, 255),   Transparency = 0 })
Toggles.CurrencyESPToggle:AddColorPicker("CurrencyESPColor",   { Text = "Currency",     Default = Color3.fromRGB(255, 255, 0),   Transparency = 0 })
Toggles.LadderESPToggle:AddColorPicker("LadderESPColor",       { Text = "Ladders",      Default = Color3.fromRGB(3, 67, 71), Transparency = 0 })
Toggles.MiscESPToggle:AddColorPicker("MiscESPColor",           { Text = "Misc",         Default = Color3.fromRGB(255, 255, 255), Transparency = 0 })
Toggles.EntityESPToggle:AddColorPicker("EntityESPColor",       { Text = "Entities",     Default = Color3.fromRGB(255, 0, 0),     Transparency = 0 })

local HidingSpotLabels = {
	Wardrobe = "Closet", ["Backdoor_Wardrobe"] = "Closet", Toolshed = "Closet",
	RetroWardrobe = "Closet", ["Wardrobe-FOOLS26"] = "Closet",
	Locker_Large = "Locker", Rooms_Locker = "Hiding_Spot", Rooms_Locker_Fridge = "Locker",
	Bed = "Bed", Double_Bed = "Double Bed", CircularVent = "Vent", Dumpster = "Dumpster"
}
local ChestLabels = {
	ChestBox = true, ChestBoxLocked = true, Toolbox = true, Toolbox_Locked = true,
	Chest_Vine = "Vine Chest", Toolshed_Small = "Toolshed", Locker_Small_Locked = "Locked Item Locker", MouseHole = "Mouse"
}
local EntityESPLabels = {
	JeffTheKiller = "Jeff the Killer", GiggleCeiling = "Giggle",
	Snare = "Snare", GrumbleRig = "Grumble",
	Drakobloxxer = "Drakobloxxer", Hole = "Mandrake Hole", Groundskeeper = "Groundskeeper",
	LiveEntityBramble = "Bramble", Figure = "Figure", FigureRig = "Figure", FigureRagdoll = "Figure",
	FakeDoor = "Dupe", DoorFake = "Dupe",
	Noise = "Noise", NoiseModel = "Noise"
}

local NodeEntities = {
	Rush = true, Bash = true, Scribbles = true, DronesStampede = true, Ambush = true, Eyes = true, Blitz = true, Lookman = true, ["A-60"] = true, ["A-120"] = true, Sally = true, ["Jeff The Killer"] = true, Monument = true, ["AR0xMBUSH"] = true, ["RNIUSHCG=="] = true
}

Toggles.DoorESPToggle:OnChanged(function(Value)
	for _, Object in Objects.Doors do
		if Value then Functions.AddESP({ Object = Object, Text = "Door " .. Functions.GetDoorNumber(Object), Color = Options.DoorESPColor.Value }, true)
		else Functions.RemoveESP(Object) end
	end
end)
Options.DoorESPColor:OnChanged(function(Value)
	for _, Object in Objects.Doors do Abysall.ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.HidingSpotESPToggle:OnChanged(function(Value)
	for _, Object in Objects.HidingSpots do
		local Label = HidingSpotLabels[Object.Name]
		if Value and Label then Functions.AddESP({ Object = Object, Text = Label, Color = Options.HidingSpotESPColor.Value }, true)
		elseif not Value then Functions.RemoveESP(Object) end
	end
end)
Options.HidingSpotESPColor:OnChanged(function(Value)
	for _, Object in Objects.HidingSpots do Abysall.ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.PlayerESPToggle:OnChanged(function(Value)
	task.wait()
	for _, Player in Services.Players:GetPlayers() do
		if Player.Character and Player ~= LocalPlayer then
			if Value and Player:GetAttribute("Alive") == true then
				Functions.AddESP({ Object = Player.Character, Text = Player.Name, Color = Options.PlayerESPColor.Value })
			else
				Functions.RemoveESP(Player.Character)
			end
		end
	end
end)
Options.PlayerESPColor:OnChanged(function(Value)
	for _, Player in Services.Players:GetPlayers() do
		if Player.Character and Player ~= LocalPlayer then
			Abysall.ESPLibrary:UpdateObjectColor(Player.Character, Value)
		end
	end
end)

Toggles.ChestESPToggle:OnChanged(function(Value)
	for _, Object in Objects.Chests do
		if Value then
			local Label
			if Object.Name == "ChestBox" or Object.Name == "ChestBoxLocked" then
				Label = Object:GetAttribute("Locked") and "Locked Chest" or "Chest"
			elseif Object.Name == "Toolbox" or Object.Name == "Toolbox_Locked" then
				Label = Object:GetAttribute("Locked") and "Locked Toolbox" or "Toolbox"
			elseif ChestLabels[Object.Name] and ChestLabels[Object.Name] ~= true then
				Label = ChestLabels[Object.Name]
			end
			if Label then Functions.AddESP({ Object = Object, Text = Label, Color = Options.ChestESPColor.Value }, true) end
		else
			Functions.RemoveESP(Object)
		end
	end
end)

Options.ChestESPColor:OnChanged(function(Value)
	for _, Object in Objects.Chests do Abysall.ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.ItemESPToggle:OnChanged(function(Value)
	for _, Object in Objects.Items do
		if Value then
			local Label = ItemNames[Object.Name] or (Object.Name == "Green_Herb" and "Green Herb")
			if Label then
				Functions.AddESP({ Object = Object, Text = Label, Color = Options.ItemESPColor.Value }, Object:GetAttribute("ParentRoom") ~= nil)
			end
		else
			Functions.RemoveESP(Object)
		end
	end
end)
Options.ItemESPColor:OnChanged(function(Value)
	for _, Object in Objects.Items do Abysall.ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.CurrencyESPToggle:OnChanged(function(Value)
	for _, Object in Objects.Currency do
		if Value then
			local Label
			if Object.Name == "GoldPile" and Object:GetAttribute("GoldValue") then
				Label = "Gold Pile [" .. Object:GetAttribute("GoldValue") .. "]"
			elseif Object.Name == "StardustPickup" then
				Label = "Stardust Pile"
			end
			if Label then Functions.AddESP({ Object = Object, Text = Label, Color = Options.CurrencyESPColor.Value }, true) end
		else
			Functions.RemoveESP(Object)
		end
	end
end)
Options.CurrencyESPColor:OnChanged(function(Value)
	for _, Object in Objects.Currency do Abysall.ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.EntityESPToggle:OnChanged(function(Value)
	for _, Object in Objects.Entities do
		if Value then
			local Label = EntityESPLabels[Object.Name]
			if not Label and Entities[Object.Name] then Label = Entities[Object.Name].Alias end
			if Label and Options.EntityESPOptions.Value[Label] then
				Functions.AddESP({ Object = Object, Text = Label, Color = Options.EntityESPColor.Value }, NodeEntities[Label] ~= true)
			else
				Functions.RemoveESP(Object)
			end
		else
			Functions.RemoveESP(Object)
		end
	end
end)

Options.EntityESPOptions:OnChanged(function(Value)
	for _, Object in Objects.Entities do
		if Toggles.EntityESPToggle.Value then
			local Label = EntityESPLabels[Object.Name]
			if not Label and Entities[Object.Name] then Label = Entities[Object.Name].Alias end
			if Label and Options.EntityESPOptions.Value[Label] then
				Functions.AddESP({ Object = Object, Text = Label, Color = Options.EntityESPColor.Value }, NodeEntities[Label] ~= true)
			else
				Functions.RemoveESP(Object)
			end
		else
			Functions.RemoveESP(Object)
		end
	end
end)

Options.EntityESPColor:OnChanged(function(Value)
	for _, Object in Objects.Entities do Abysall.ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.LadderESPToggle:OnChanged(function(Value)
	for _, Object in Objects.Ladders do
		if Value then Functions.AddESP({ Object = Object, Text = "Ladder", Color = Options.LadderESPColor.Value }, true)
		else Functions.RemoveESP(Object) end
	end
end)
Options.LadderESPColor:OnChanged(function(Value)
	for _, Object in Objects.Ladders do Abysall.ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.MiscESPToggle:OnChanged(function(Value)
	for _, Object in Objects.Misc do
		if Value then
			local Label = Object.Name
			if Object.Name == "StairwellLockpickDoor" or Object.Name == "StiarwellLockpickDoor" then
				Label = "Garage Door"
			elseif Object.Name == "StairwellFireAlarm" then
				Label = "Fire Alarm"
			elseif Object.Name == "ShoppingCart" then
				Label = "Shopping Cart"
			elseif Object.Name == "ArchivesFihTank" or Object.Name == "ArchivesFishTank" then
				Label = "Fish Tank"
			end
			Functions.AddESP({ Object = Object, Text = Label, Color = Options.MiscESPColor.Value }, true)
		else
			Functions.RemoveESP(Object)
		end
	end
end)
Options.MiscESPColor:OnChanged(function(Value)
	for _, Object in Objects.Misc do Abysall.ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Groupboxes.Visuals_ESP_Settings:AddToggle("ESPRainbow",     { Text = "Rainbow Effect", Default = false, Tooltip = "Makes the esp objects change colour like a rainbow." })
Groupboxes.Visuals_ESP_Settings:AddToggle("ESPShowDistance",{ Text = "Show Distance",  Default = true,  Tooltip = "Shows how far away your character is from the object." })
Groupboxes.Visuals_ESP_Settings:AddDivider()
Groupboxes.Visuals_ESP_Settings:AddSlider("ESPFillTransparency",        { Text = "Fill Transparency",         Min = 0, Max = 1, Default = 0.75, Rounding = 2, Compact = true })
Groupboxes.Visuals_ESP_Settings:AddSlider("ESPOutlineTransparency",     { Text = "Outline Transparency",      Min = 0, Max = 1, Default = 0,    Rounding = 2, Compact = true })
Groupboxes.Visuals_ESP_Settings:AddSlider("ESPTextTransparency",        { Text = "Text Transparency",         Min = 0, Max = 1, Default = 0,    Rounding = 2, Compact = true })
Groupboxes.Visuals_ESP_Settings:AddSlider("ESPTextOutlineTransparency", { Text = "Text Outline Transparency", Min = 0, Max = 1, Default = 0,    Rounding = 2, Compact = true })
Groupboxes.Visuals_ESP_Settings:AddSlider("ESPFadeTime",                { Text = "Fade Time",                 Min = 0, Max = 1, Default = 0.25, Rounding = 2, Compact = true })
Groupboxes.Visuals_ESP_Settings:AddSlider("ESPRenderLimit",             { Text = "Render Limit",              Min = 30, Max = 240, Default = 240, Rounding = 0, Compact = true })
Groupboxes.Visuals_ESP_Settings:AddSlider("ESPTextSize",                { Text = "Text Size",                 Min = 12, Max = 24, Default = 20, Rounding = 0, Compact = true })
Groupboxes.Visuals_ESP_Settings:AddDropdown("ESPTextFont", {
	Text = "Text Font",
	Values = { "Legacy","Arial","ArialBold","SourceSans","SourceSansBold","SourceSansLight","SourceSansItalic","Bodoni","Garamond","Cartoon","Code","Highway","SciFi","Arcade","Fantasy","Antique","SourceSansSemibold","Gotham","GothamMedium","GothamBold","GothamBlack","AmaticSC","Bangers","Creepster","DenkOne","Fondamento","FredokaOne","GrenzeGotisch","IndieFlower","JosefinSans","Jura","Kalam","LuckiestGuy","Merriweather","Michroma","Nunito","Oswald","PatrickHand","PermanentMarker","Roboto","RobotoCondensed","RobotoMono","Sarpanch","SpecialElite","TitilliumWeb","Ubuntu","BuilderSans","BuilderSansMedium","BuilderSansBold","BuilderSansExtraBold","Arimo","ArimoBold" },
	Default = 12
})
Groupboxes.Visuals_ESP_Settings:AddDivider()
Groupboxes.Visuals_ESP_Settings:AddDropdown("ESPTracersOrigin",  { Text = "Tracer Origin", Values = { "Bottom","Center","Top","Mouse" }, Default = 1 })
Groupboxes.Visuals_ESP_Settings:AddSlider("ESPTracerThickness",  { Text = "Tracer Thickness", Min = 0.5, Max = 2, Default = 0.75, Rounding = 2, Compact = true })
Groupboxes.Visuals_ESP_Settings:AddToggle("ESPTracersToggle",    { Text = "Enable Tracers", Default = false, Tooltip = "Draws a line to highlighted objects." })
Groupboxes.Visuals_ESP_Settings:AddDivider()
Groupboxes.Visuals_ESP_Settings:AddSlider("ESPArrowsRadius",     { Text = "Arrow Radius", Min = 100, Max = 500, Default = 250, Rounding = 0, Compact = true })
Groupboxes.Visuals_ESP_Settings:AddToggle("ESPArrowsToggle",     { Text = "Enable Arrows", Default = false, Tooltip = "Shows arrow that point to off-screen objects." })

Abysall.ESPLibrary:SetRainbow(false)
Abysall.ESPLibrary:SetShowDistance(true)
Abysall.ESPLibrary:SetFillTransparency(0.75)
Abysall.ESPLibrary:SetOutlineTransparency(0)
Abysall.ESPLibrary:SetTextTransparency(0)
Abysall.ESPLibrary:SetTextOutlineTransparency(0)
Abysall.ESPLibrary:SetRenderLimit(240)
Abysall.ESPLibrary:SetFadeTime(0.25)
Abysall.ESPLibrary:SetTextSize(20)
Abysall.ESPLibrary:SetFont(Enum.Font.Highway)
Abysall.ESPLibrary:SetTracers(false)
Abysall.ESPLibrary:SetTracerSize(0.75)
Abysall.ESPLibrary:SetTracerOrigin("Bottom")
Abysall.ESPLibrary:SetArrows(false)
Abysall.ESPLibrary:SetArrowRadius(250)
Abysall.ESPLibrary:SetDistanceSizeRatio(0.8)

Toggles.ESPRainbow:OnChanged(function(V)        Abysall.ESPLibrary:SetRainbow(V) end)
Toggles.ESPShowDistance:OnChanged(function(V)   Abysall.ESPLibrary:SetShowDistance(V) end)
Options.ESPFillTransparency:OnChanged(function(V)        Abysall.ESPLibrary:SetFillTransparency(V) end)
Options.ESPOutlineTransparency:OnChanged(function(V)     Abysall.ESPLibrary:SetOutlineTransparency(V) end)
Options.ESPTextTransparency:OnChanged(function(V)        Abysall.ESPLibrary:SetTextTransparency(V) end)
Options.ESPTextOutlineTransparency:OnChanged(function(V) Abysall.ESPLibrary:SetTextOutlineTransparency(V) end)
Options.ESPFadeTime:OnChanged(function(V)        Abysall.ESPLibrary:SetFadeTime(V) end)
Options.ESPRenderLimit:OnChanged(function(V)     Abysall.ESPLibrary:SetRenderLimit(V) end)
Options.ESPTextSize:OnChanged(function(V)        Abysall.ESPLibrary:SetTextSize(V) end)
Options.ESPTextFont:OnChanged(function(V)        Abysall.ESPLibrary:SetFont(Enum.Font[V]) end)
Toggles.ESPTracersToggle:OnChanged(function(V)   Abysall.ESPLibrary:SetTracers(V) end)
Options.ESPTracersOrigin:OnChanged(function(V)   Abysall.ESPLibrary:SetTracerOrigin(V) end)
Options.ESPTracerThickness:OnChanged(function(V) Abysall.ESPLibrary:SetTracerSize(V) end)
Toggles.ESPArrowsToggle:OnChanged(function(V)    Abysall.ESPLibrary:SetArrows(V) end)
Options.ESPArrowsRadius:OnChanged(function(V)    Abysall.ESPLibrary:SetArrowRadius(V) end)

Tabs.Floors:UpdateWarningBox({
	Visible = true,
	Title = "Compatability/Risk Warning",
	Text = "Features highlighted in red are risky / dont work in the current floor.",
})
Groupboxes.Floors_Automation = Tabs.Floors:AddRightGroupbox("Automation")

Groupboxes.Floors_Automation:AddToggle("SkipSeekMines", {
	Text = "Skip Seek (Mines)",
	Default = false,
	Tooltip = "Skips the entire Seek sections.",
	Risky = Floor ~= "Mines"
})

Toggles.SkipSeekMines:OnChanged(function(Value)
	if Value then
		if Floor ~= "Mines" then
			return
		end
		task.spawn(function()
			local MinesSkipSeekCurrentRooms

			repeat
				if not Toggles.SkipSeekMines.Value then
					return
				end

				MinesSkipSeekCurrentRooms = workspace:FindFirstChild("CurrentRooms")
				task.wait()
			until MinesSkipSeekCurrentRooms

			local MinesSkipSeekStartRoom

			repeat
				if not Toggles.SkipSeekMines.Value then
					return
				end

				MinesSkipSeekCurrentRooms = workspace:FindFirstChild("CurrentRooms")

				if MinesSkipSeekCurrentRooms then
					MinesSkipSeekStartRoom = MinesSkipSeekCurrentRooms:FindFirstChild("42")
				end

				task.wait()
			until MinesSkipSeekStartRoom

			local MinesSkipSeekStartDoor

			repeat
				if not Toggles.SkipSeekMines.Value then
					return
				end

				MinesSkipSeekStartDoor = MinesSkipSeekStartRoom:FindFirstChild("Door", true)
				task.wait()
			until MinesSkipSeekStartDoor

			repeat
				if not Toggles.SkipSeekMines.Value then
					return
				end

				task.wait()
			until MinesSkipSeekStartDoor:GetAttribute("Opened") == true

			if Character and Character:GetAttribute("Minecarting") == true then
				Character:SetAttribute("Minecarting", false)
			end

			for _, MinesSkipSeekRoomNumber in ipairs({
				43, 44, 45, 46, 47, 48, 49,
				78, 79, 80, 81, 82, 83
			}) do
				if not Toggles.SkipSeekMines.Value then
					return
				end

				local MinesSkipSeekRoom

				repeat
					if not Toggles.SkipSeekMines.Value then
						return
					end

					MinesSkipSeekCurrentRooms = workspace:FindFirstChild("CurrentRooms")

					if MinesSkipSeekCurrentRooms then
						MinesSkipSeekRoom = MinesSkipSeekCurrentRooms:FindFirstChild(
							tostring(MinesSkipSeekRoomNumber)
						)
					end

					task.wait()
				until MinesSkipSeekRoom

				local MinesSkipSeekDoor

				repeat
					if not Toggles.SkipSeekMines.Value then
						return
					end

					MinesSkipSeekDoor = MinesSkipSeekRoom:FindFirstChild("Door", true)
					task.wait()
				until MinesSkipSeekDoor

				repeat
					if not Toggles.SkipSeekMines.Value then
						return
					end

					if Character then
						Character:PivotTo(MinesSkipSeekDoor:GetPivot())
					end

					task.wait()
				until MinesSkipSeekDoor:GetAttribute("Opened") == true

				if MinesSkipSeekRoomNumber == 49 or MinesSkipSeekRoomNumber == 83 then
					if not Character then
						return
					end

					local MinesSkipSeekVoidPivot = Character:GetPivot()
					MinesSkipSeekVoidPivot = MinesSkipSeekVoidPivot + Vector3.new(0, -1000, 0)

					task.wait(0.3)

					for MinesSkipSeekVoidCount = 1, 12 do
						Character:PivotTo(MinesSkipSeekVoidPivot)
					end

					for MinesSkipSeekVoidCount = 1, 12 do
						Character:PivotTo(MinesSkipSeekVoidPivot)
					end

					for MinesSkipSeekVoidCount = 1, 12 do
						Character:PivotTo(MinesSkipSeekVoidPivot)
					end

					task.wait(0.3)

					for MinesSkipSeekVoidCount = 1, 6 do
						Character:PivotTo(MinesSkipSeekVoidPivot)
					end
				end

				if MinesSkipSeekRoomNumber == 83 then
					return
				end
			end
		end)
	end
end)

Groupboxes.Floors_Automation:AddToggle("AutoSteerMinecart", {
	Text = "Auto Steer Minecart", Default = false, Tooltip = "Automatically completes the minecart chase.",
	Disabled = not Functions.CheckCompatability({"require"}), DisabledTooltip = Globals.IncompatibleMessage
})
Groupboxes.Floors_Automation:AddSlider("AutoSteerMinecartTurnDistance", {
	Text = "Turn Distance", Min = 20, Max = 40, Default = 30, Rounding = 0,
	Disabled = not Functions.CheckCompatability({"require"}), DisabledTooltip = Globals.IncompatibleMessage
})
Groupboxes.Floors_Automation:AddSlider("AutoSteerMinecartDuckDistance", {
	Text = "Crouch Distance", Min = 20, Max = 40, Default = 30, Rounding = 0,
	Disabled = not Functions.CheckCompatability({"require"}), DisabledTooltip = Globals.IncompatibleMessage
})
Groupboxes.Floors_Automation:AddDivider()
Groupboxes.Floors_Automation:AddToggle("RoomsAutoWalk",             { Text = "Auto Rooms",       Default = false, Tooltip = "Automatically moves and hides from entities in The Rooms." })
Groupboxes.Floors_Automation:AddSlider("RoomsAutoWalkPathfindTimeout", { Text = "Pathfind Timeout", Min = 0.5, Max = 3, Default = 1, Rounding = 1 })
Groupboxes.Floors_Automation:AddToggle("RoomsAutoWalkIgnoreA60",    { Text = "Ignore A-60",      Default = false, Tooltip = "Continues to walk if entity 'A-60' is present, enables position spoof automatically." })
Groupboxes.Floors_Automation:AddToggle("RoomsAutoWalkShowPathToggle", { Text = "Show Path",       Default = false, Tooltip = "Shows the current path of rooms auto-walk." })
Groupboxes.Floors_Automation:AddToggle("RoomsAutoWalkSpoofFootsteps", {
    Text = "Spoof Footsteps", Default = false, Tooltip = "Makes it appear as if your character is walking normally.",
    Disabled = not Functions.CheckCompatability({"hookmetamethod", "newcclosure", "getnamecallmethod"}), DisabledTooltip = Globals.IncompatibleMessage
})

Toggles.RoomsAutoWalk:OnChanged(function()
	for _, Object in Globals.RoomsNodesFolder:GetChildren() do
		if Object.Name == "PathNode" then Object:Destroy() end
	end
end)
Toggles.RoomsAutoWalkShowPathToggle:AddColorPicker("RoomsAutoWalkShowPathColor", { Text = "Path", Default = Color3.fromRGB(0, 255, 0), Transparency = 0 })
Toggles.RoomsAutoWalkShowPathToggle:OnChanged(function(Value)
	for _, Object in Globals.RoomsNodesFolder:GetChildren() do
		if Object.Name == "PathNode" then Object.Transparency = Value and 0.5 or 1 end
	end
end)
Options.RoomsAutoWalkShowPathColor:OnChanged(function(Value)
	for _, Object in Globals.RoomsNodesFolder:GetChildren() do
		if Object.Name == "PathNode" then Object.Color = Value end
	end
end)

Functions.RoomsAutoWalk = {}
Functions.RoomsAutoWalk.GetNearestHidingSpot = function()
	local Nearest = { Distance = math.huge, Object = nil }
	for _, Object in Objects.HidingSpots do
		if Object.PrimaryPart and Object:FindFirstChild("HidePrompt") then
			local Distance = LocalPlayer:DistanceFromCharacter(Object.PrimaryPart.Position)
			if Distance < Nearest.Distance and Object.PrimaryPart.Position.Y > -10 then
				local HiddenPlayer = Object:FindFirstChild("HiddenPlayer", true)
				if HiddenPlayer and not HiddenPlayer.Value then
					Nearest.Distance = Distance
					Nearest.Object = Object
				end
			end
		end
	end
	return Nearest.Object
end

local RoomsEntityList = { "RushMoving","AmbushMoving","BackdoorRush","A60","A120","CustomEntity","GlitchRush","GlitchAmbush" }
Functions.RoomsAutoWalk.GetPathfindTarget = function()
	for _, Object in Services.Workspace:GetChildren() do
		if table.find(RoomsEntityList, Object.Name) and Object.PrimaryPart then
			local Y = Object.PrimaryPart.Position.Y
			if Y > -10 and Y < 150 then
				if Object.Name == "A60" and not Toggles.RoomsAutoWalkIgnoreA60.Value or Object.Name ~= "A60" then
					return Functions.RoomsAutoWalk.GetNearestHidingSpot() or CurrentRooms[tostring(LatestRoom.Value)]:FindFirstChild("RoomExit")
				end
			end
		end
	end
	return CurrentRooms[tostring(LatestRoom.Value)]:FindFirstChild("RoomExit")
end

Connections.RoomsAutoWalkHandler = Services.RunService.Heartbeat:Connect(function()
	if Floor ~= "Rooms" or not Toggles.RoomsAutoWalk.Value or Globals.RoomsAutoWalkActive or not CollisionPart or LatestRoom.Value >= 1000 then return end
	Globals.RoomsAutoWalkActive = true

	local Path = Services.PathfindingService:CreatePath({
		AgentCanJump = true, AgentCanClimb = false, WaypointSpacing = 4,
		AgentRadius = 1.5, AgentHeight = 1.5, Costs = { StuckPart = 8 }
	})

	if Toggles.RoomsAutoWalkIgnoreA60.Value and not Toggles.PositionSpoof.Value then
		Toggles.PositionSpoof:SetValue(true)
	end

	local TargetPart = Functions.RoomsAutoWalk.GetPathfindTarget()
	if not TargetPart then
		Globals.RoomsAutoWalkActive = false
		return
	end

	local TargetPosition
	if TargetPart.Name == "RoomExit" then
		TargetPosition = TargetPart.Position
	elseif TargetPart:FindFirstChild("HidePrompt") then
		for _, Part in TargetPart:GetDescendants() do
			if Part:IsA("BasePart") then Part.CanCollide = false end
		end
		TargetPosition = TargetPart.PrimaryPart.Position
	end

	if CollisionPart.Anchored and not TargetPart:FindFirstChild("HidePrompt") then
		Character:SetAttribute("Hiding", true)
		RemotesFolder.CamLock:FireServer()
		Character:SetAttribute("Hiding", false)
	end

	local CurrentRoom = CurrentRooms[tostring(LatestRoom.Value)]
	if CurrentRoom:FindFirstChild("Door") then
		CurrentRoom.Door.Door.CanCollide = false
	end

	if not TargetPosition or LocalPlayer:DistanceFromCharacter(TargetPosition) >= 750 then
		Globals.RoomsAutoWalkActive = false
		return
	end

	Path:ComputeAsync(CollisionPart.Position, TargetPosition)
	local Waypoints = Path:GetWaypoints()

	if #Waypoints == 0 then
		local RoomExit = CurrentRoom:FindFirstChild("RoomExit")
		if RoomExit then Humanoid:MoveTo(RoomExit.Position) end
		Globals.RoomsAutoWalkActive = false
		return
	end

	for _, Node in Globals.RoomsNodesFolder:GetChildren() do
		if Node.Name == "PathNode" then Node:Destroy() end
	end

	for _, Waypoint in Waypoints do
		local Block = Instance.new("Part", Globals.RoomsNodesFolder)
		Block.Transparency = Toggles.RoomsAutoWalkShowPathToggle.Value and 0.5 or 1
		Block.Size = Vector3.one
		Block.Position = Waypoint.Position
		Block.Shape = Enum.PartType.Ball
		Block.CanCollide = false
		Block.Anchored = true
		Block.Name = "PathNode"
		Block.Color = Options.RoomsAutoWalkShowPathColor.Value
		Block.Material = Enum.Material.Neon
	end

	local Stuck = false
	for _, Waypoint in Waypoints do
		if Stuck or not Toggles.RoomsAutoWalk.Value then break end

		local Finished = false
		local Start = tick()

		local StepConnection = Services.RunService.RenderStepped:Connect(function()
			if Stuck or not Toggles.RoomsAutoWalk.Value then Finished = true return end

			local NewTarget = Functions.RoomsAutoWalk.GetPathfindTarget()
			if NewTarget and NewTarget:FindFirstChild("HidePrompt") and not TargetPart:FindFirstChild("HidePrompt") then
				Finished = true return
			end
			if TargetPart:FindFirstChild("HidePrompt") then
				local HidePrompt = TargetPart:FindFirstChild("HidePrompt")
				if LocalPlayer:DistanceFromCharacter(TargetPosition) < HidePrompt.MaxActivationDistance
					and Character:GetAttribute("Hiding") ~= true
				then
					Functions.ForceFirePrompt(HidePrompt)
				end
			end
			local FlatPos = Vector3.new(Waypoint.Position.X, RootPart.Position.Y, Waypoint.Position.Z)
			if LocalPlayer:DistanceFromCharacter(FlatPos) < 5 then Finished = true end
			Humanoid:MoveTo(Waypoint.Position)
		end)

		while not Finished do
			if tick() - Start > Options.RoomsAutoWalkPathfindTimeout.Value then
				local StuckBlock = Instance.new("Part", Globals.RoomsNodesFolder)
				StuckBlock.Transparency = 1
				StuckBlock.Size = Vector3.one
				StuckBlock.CFrame = Collision.CFrame
				StuckBlock.Shape = Enum.PartType.Ball
				StuckBlock.CanCollide = false
				StuckBlock.Anchored = true
				StuckBlock.Name = "StuckPart"
				local Modifier = Instance.new("PathfindingModifier", StuckBlock)
				Modifier.Label = "StuckPart"
				Stuck = true
				break
			end
			task.wait()
		end
		StepConnection:Disconnect()
		Humanoid:MoveTo(RootPart.Position)
	end

	Globals.RoomsAutoWalkActive = false
end)

Connections.RoomsHandler = CurrentRooms.ChildAdded:Connect(function(Room)
	for _, Object in Globals.RoomsNodesFolder:GetChildren() do
		if Object.Name == "StuckPart" then Object:Destroy() end
	end

	if Room:GetAttribute("RawName") and string.find(Room:GetAttribute("RawName"), "Eyestalk") then
        local PreviousNode = nil

		local function CreateEyestalkNode(WaypointPos)
			local NewNode = Instance.new("Part")
			NewNode.Size = Vector3.one
			NewNode.Transparency = 1
			NewNode.Parent = Globals.SeekNodesFolder
			NewNode.Anchored = true
			NewNode.Position = WaypointPos
			NewNode.CanCollide = false
			NewNode.Name = "SeekLightNode"

			local PrevNode = PreviousNode or NewNode
			PreviousNode = NewNode

			local NewBeam = Instance.new("Beam")
			NewBeam.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Options.ShowEyestalkPathColor.Value), ColorSequenceKeypoint.new(1, Options.ShowEyestalkPathColor.Value) })
			NewBeam.FaceCamera = true
			NewBeam.Width0 = 0.2
			NewBeam.Width1 = 0.2
			NewBeam.Brightness = 10
			NewBeam.LightInfluence = 0
			NewBeam.LightEmission = 0
			NewBeam.Enabled = true

			local Vis = Toggles.ShowEyestalkPathToggle.Value and 0 or 1
			NewBeam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, Vis), NumberSequenceKeypoint.new(1, Vis) })
			NewBeam.Parent = Globals.SeekNodesFolder

			local A0 = Instance.new("Attachment", NewNode)
			local A1 = Instance.new("Attachment", PrevNode)
			NewBeam.Attachment0 = A0
			NewBeam.Attachment1 = A1

			table.insert(Objects.EyestalkHighlights, NewBeam)
		end

		Room:WaitForChild("RoomEntrance", 9e9)
		Room:WaitForChild("RoomExit", 9e9)

		while not Room:GetAttribute("PathFound") do
			if Toggles.ShowEyestalkPathToggle.Value then
				local EyePath = game:GetService("PathfindingService"):CreatePath({
					AgentCanJump = false, AgentCanClimb = false, WaypointSpacing = 2, AgentRadius = 1, AgentHeight = 1
				})
				EyePath:ComputeAsync(RootPart.Position, Room.RoomExit.Position)
				if EyePath.Status == Enum.PathStatus.Success then
					Room:SetAttribute("PathFound", true)
					for _, Waypoint in EyePath:GetWaypoints() do
						CreateEyestalkNode(Waypoint.Position)
						task.wait()
					end
                    break
				end
			end
			task.wait(0.25)
		end
	end
end)

Groupboxes.Floors_Completion = Tabs.Floors:AddRightGroupbox("Completion")
Groupboxes.Floors_Completion:AddButton({
    Text = "Auto Complete Dam Seek",
    Tooltip = "Automatically teleports to and interacts with each water pump.",
    Func = function()
        if LatestRoom.Value < 100 or Floor ~= "Mines" then
            Functions.Notify({Title = "You must be in Room 200 to do this."})
            return
        end

		local IsCutscene = false
		local CutsceneConnection = RemotesFolder.Cutscene.OnClientEvent:Connect(function()
			IsCutscene = true
			task.wait(7)
			IsCutscene = false
		end)

        local function GetNextPump()
            local Highest = {
                Height = -69420,
                Object = nil
            }
            for _, Object in pairs(Objects.Objectives) do
                if Object.Name == "WaterPump" and Object:GetAttribute("Abysall_Completed") ~= true then
                    if Object.PrimaryPart and Object.PrimaryPart.Position.Y > Highest.Height then
                        Highest.Object = Object
                        Highest.Height = Object.PrimaryPart.Position.Y
                    end
                end
            end
            return Highest.Object
        end

        local function HandlePump(Pump)

            while task.wait(0.1) do
				if IsCutscene then
					continue
				end

                Character:PivotTo(Pump:GetPivot())

                local Prompt = Pump:FindFirstChild("ValvePrompt", true)
                if Prompt then
                    Functions.ForceFirePrompt(Prompt)
                end

                if Pump:GetAttribute("Abysall_Completed") then
                    break
                end
            end
        end

        Functions.Notify({Title = "Attempting to complete the valves.", Body = "Please wait."})
        while task.wait(0.1) do
            local Pump = GetNextPump()
            if Pump then
                HandlePump(Pump)
            else
                break
            end
        end
        Functions.Notify({Title = "Successfully completed the valves."})
    end
})

Groupboxes.Floors_Completion:AddButton({
    Text = "Auto Complete Cringle",
    Tooltip = "Instantly completes the quest.",
    Func = function()
        local TouchPart = CurrentRooms:FindFirstChild("RippleExitDoor", true)
        if TouchPart then
            Character:PivotTo(TouchPart:GetPivot())
        end
    end
})

Groupboxes.Floors_Visuals = Tabs.Floors:AddLeftGroupbox("Visuals")
Groupboxes.Floors_Visuals:AddToggle("ShowSeekPathToggle", {
	Text = "Show Seek Path", Default = false, Tooltip = "Shows you the correct path in seek chases.",
	Risky = Floor ~= "Mines"
})
Toggles.ShowSeekPathToggle:AddColorPicker("ShowSeekPathColor", { Text = "Seek Path", Default = Color3.fromRGB(0, 255, 0), Transparency = 0 })

local function UpdateBeamVisibility(BeamTable, ColorKey, Visible)
	local Vis = Visible and 0 or 1
	local Seq = NumberSequence.new({ NumberSequenceKeypoint.new(0, Vis), NumberSequenceKeypoint.new(1, Vis) })
	for _, Beam in BeamTable do Beam.Transparency = Seq end
end
local function UpdateBeamColor(BeamTable, Value)
	local Seq = ColorSequence.new({ ColorSequenceKeypoint.new(0, Value), ColorSequenceKeypoint.new(1, Value) })
	for _, Beam in BeamTable do Beam.Color = Seq end
end

Toggles.ShowSeekPathToggle:OnChanged(function(V)  UpdateBeamVisibility(Objects.SeekHighlights, "ShowSeekPathColor", V) end)
Options.ShowSeekPathColor:OnChanged(function(V)   UpdateBeamColor(Objects.SeekHighlights, V) end)

Groupboxes.Floors_Visuals:AddToggle("ShowEyestalkPathToggle", {
	Text = "Show Eyestalk Path", Default = false, Tooltip = "Shows you the correct path in the eyestalk chase.",
	Risky = Floor ~= "Garden"
})
Toggles.ShowEyestalkPathToggle:AddColorPicker("ShowEyestalkPathColor", { Text = "Eyestalk Path", Default = Color3.fromRGB(0, 255, 0), Transparency = 0 })
Toggles.ShowEyestalkPathToggle:OnChanged(function(V) UpdateBeamVisibility(Objects.EyestalkHighlights, "ShowEyestalkPathColor", V) end)
Options.ShowEyestalkPathColor:OnChanged(function(V)  UpdateBeamColor(Objects.EyestalkHighlights, V) end)

Groupboxes.Floors_Bypass = Tabs.Floors:AddLeftGroupbox("Bypass")
Groupboxes.Floors_Bypass:AddToggle("RemoveSeekTrigger", {
	Text = "Delete Seek Trigger", Default = false, Tooltip = "Diables the 'Seek' chase trigger.",
	Risky = not (Floor == "Fools" or Floor == "OldHotel"),
	Disabled = not Functions.CheckCompatability({"firetouchinterest"}), DisabledTooltip = Globals.IncompatibleMessage
})
Groupboxes.Floors_Bypass:AddToggle("RemoveFigure", {
	Text = "Delete Figure", Default = false, Tooltip = "Completely removes the entity 'Figure' (doesn't always work).",
	Risky = not (Floor == "Fools" or Floor == "OldHotel" or Floor == "Mines"),
	Disabled = not Functions.CheckCompatability({"isnetworkowner"}), DisabledTooltip = Globals.IncompatibleMessage
})
Groupboxes.Floors_Bypass:AddToggle("AutoRevive", {
	Text = "Infinite Revives", Default = false, Tooltip = "Automatically revives after dying, with unlimited respawns.",
	Risky = not (Floor == "Fools" or Floor == "OldHotel")
})
Groupboxes.Floors_Bypass:AddToggle("FigureGodmode", {
	Text = "Figure Godmode", Default = false, Tooltip = "Prevents 'Figure' from hurting you.",
	Risky = not (Floor == "Fools" or Floor == "OldHotel")
})
Groupboxes.Floors_Bypass:AddDivider()
Groupboxes.Floors_Bypass:AddToggle("RemoveBasementGate",  { Text = "Remove Basement Gate",   Default = false, Tooltip = "Removes the gate from basement rooms.",            Risky = not (Floor == "Fools" or Floor == "OldHotel") })
Groupboxes.Floors_Bypass:AddToggle("RemovePaintingsDoor", { Text = "Remove Paintings Door",  Default = false, Tooltip = "Removes the fireplace doors from painting rooms.", Risky = not (Floor == "Fools" or Floor == "OldHotel") })
Groupboxes.Floors_Bypass:AddToggle("RemoveSkeletonDoor",  { Text = "Remove Skeleton Door",   Default = false, Tooltip = "Removes the skeleton door from the infirmary.",    Risky = Floor ~= "Fools" })

local ObstructionNames = { ThingToOpen = "RemoveBasementGate", MovingDoor = "RemovePaintingsDoor", Wax_Door = "RemoveSkeletonDoor" }
for ObjName, ToggleName in ObstructionNames do
	Toggles[ToggleName]:OnChanged(function(Value)
		for _, Object in Objects.Obstructions do
			if Object.Name == ObjName then
				Object:PivotTo(Value and CFrame.new(-10000, -10000, -10000) or Object:GetAttribute("OriginalPosition"))
			end
		end
	end)
end

Groupboxes.Floors_Farming = Tabs.Floors:AddLeftGroupbox("Farming")
Groupboxes.Floors_Farming:AddToggle("KnobFarm", {
    Text = "Knob Farm",
    Default = false,
    Tooltip = "Automatically gains knobs for you, dies and revives repeatedly.",
	Risky = Floor ~= "Ballz",
})

Groupboxes.Floors_Farming:AddButton({
    Text = "Start Knob Farm",
    Tooltip = "Starts farming knobs, click this when you have enough gold.",
    Func = function()
		if LatestRoom.Value ~= 0 then
			Functions.Notify({Title = "You must be in Room 0 to use this."})
			return
		end

		if LocalPlayer.PlayerGui:FindFirstChild("TopbarUI") then 
			local GoldCount = LocalPlayer.PlayerGui.TopbarUI.Topbar.StatsTopbarHandler.StatModules.Gold.GoldVal
			if GoldCount.Value <= 0 then
				Functions.Notify({Title = "You must have gold to do this."})
				return
			end
		end

        Globals.KnobFarmStarted = true
    end
})

Groupboxes.Floors_Farming:AddDivider()
Groupboxes.Floors_Farming:AddButton({
	Text = "Start Death Farm",
	DoubleClick = true,
	Tooltip = "Automatically farms deaths, joining new runs.",
	Func = function()
		loadstring(GetScript("DeathFarm.luau", "https://raw.githubusercontent.com/bocaj111004/Abysall/refs/heads/main/Scripts/DeathFarm.luau"))()
	end,

	Disabled = not Functions.CheckCompatability({"fireproximityprompt", "firesignal"}),
	DisabledTooltip = Globals.ImcompatibleMessage
})
Groupboxes.Floors_Farming:AddButton({
	Text = "Copy Death Farm Loadstring",
	DoubleClick = false,
	Tooltip = "Copies the death farm loadstring to your clipboard.",
	Func = function()
		toclipboard([==[
			loadstring(game:HttpGet("https://raw.githubusercontent.com/bocaj111004/Abysall/refs/heads/main/Scripts/DeathFarm.luau"))()
		]==])
		Library:Notify("Loadstring has been copied to your clipboard.")
	end,

	Disabled = not Functions.CheckCompatability({"fireproximityprompt", "firesignal"}),
	DisabledTooltip = Globals.ImcompatibleMessage
})

Toggles.KnobFarm:OnChanged(function(Value)
    if Value then
        Functions.Notify({Title = "Please collect some gold to earn knobs.", Body = "Click 'Start Knob Farm' when you're ready."})
	else
		Globals.KnobFarmStarted = false
    end
end)

Globals.KnobFarmActive = false
Globals.KnobFarmStarted = false
Connections.KnobFarm = Services.RunService.Heartbeat:Connect(function()
	if Toggles.KnobFarm.Value and Globals.KnobFarmStarted then
		if not Globals.KnobFarmActive then
			Globals.KnobFarmActive = true
			if Functions.CheckCompatability({"replicatesignal"}) then
				Abysall.Environment.replicatesignal(LocalPlayer.Kill)
			else
				LocalPlayer.Character.Humanoid.Health = 0
			end
			while task.wait() do
				if LocalPlayer:GetAttribute("Alive") then
					break
				end
			end
			RemotesFolder.Statistics:FireServer()
			task.wait(0.25)
			Globals.KnobFarmActive = false
		end
	end
end)

local MainHook
local OtherHook
if Functions.CheckCompatability({"hookmetamethod", "newcclosure", "getnamecallmethod"}) then
	MainHook = Abysall.Environment.hookmetamethod(game, "__namecall", Abysall.Environment.newcclosure(function(Self, ...)
		local Args = { ... }
		if Abysall and Abysall.Environment then
			local Method = Abysall.Environment.getnamecallmethod()

			if Self.Name == "Crouch" and Method == "FireServer" then
				if Toggles.CrouchSpoof.Value or Toggles.PositionSpoof.Value then
					Args[1] = true
				end
				Args[2] = true
			end

			if Self.Name == "ClutchHeartbeat" and Method == "FireServer" and Toggles.AutoHeartbeatMinigame.Value or Self.Name == "HideMonster" and Method == "FireServer" and Toggles.AutoHeartbeatMinigame.Value then
				return
			end

			if Self.Name == "MotorReplication" and Method == "FireServer" then
				local DoBypass = (Toggles.BypassEyes.Value and Globals.IsEyes) or (Toggles.BypassLookman.Value and Globals.IsLookman)
				if DoBypass then
					if Floor == "Fools" or Floor == "OldHotel" then
						Args[1] = 0 Args[2] = (Globals.SpoofOffset == 200 and 65 or -65) Args[3] = 0 Args[4] = false
					else
						Args[1] = -650
					end
				end
			end
		end
		return MainHook(Self, table.unpack(Args))
	end))

    OtherHook = Abysall.Environment.hookmetamethod(game, "__index", Abysall.Environment.newcclosure(function(Self, Property)
        local Real = OtherHook(Self, Property)

        if Property == "MoveDirection" and Self == Humanoid and Globals.RoomsAutoWalkActive and Toggles.RoomsAutoWalkSpoofFootsteps.Value and Floor == "Rooms" and not Character:GetAttribute("Hiding") then
            return RootPart.CFrame.LookVector
        end
        
        return Real
    end))
end

if Services.ReplicatedStorage:FindFirstChild("ModulesClient") then
	ClientModules = Services.ReplicatedStorage.ModulesClient
else
	ClientModules = Services.ReplicatedStorage:FindFirstChild("ClientModules")
end

local EntityModules = ClientModules and (ClientModules:FindFirstChild("EntityModules") or ClientModules:FindFirstChild("Entity"))

Modules = {
	Glitch          = EntityModules and EntityModules:FindFirstChild("Glitch"),
	Shade           = EntityModules and EntityModules:FindFirstChild("Shade"),
	Void            = EntityModules and EntityModules:FindFirstChild("Void"),
	SpiderJumpscare = nil,
	A90             = nil,
	Screech         = nil,
	Dread           = nil,
	GlitchScreech   = nil,
}

local CharacterOldConnectionKeys = {
	"MainHandler", "JumpHandler", "SlideHandler", "LibraryCodeHandler1", "LibraryCodeHandler2",
	"OxygenConnection", "AnimationHandler", "AutoHideConnection", "AutoReviveHandler",
	"SHMFixer", "AnticheatDisabler", "AnticheatEnableDetector1", "AnticheatEnableDetector2",
	"AutoSteerMinecartDuckHandler", "AutoSolveAnchorsConnection", "InfiniteJumpsConnection1", "InfiniteJumpsConnection2",
	"FootstepHandler"
}

Globals.IsTyping = false
Connections.TextBoxConnection1 = Services.UserInputService.TextBoxFocused:Connect(function()
	Globals.IsTyping = true
end)
Connections.TextBoxConnection2 = Services.UserInputService.TextBoxFocusReleased:Connect(function()
	Globals.IsTyping = false
end)

Functions.IsValidEyes = function(model)
	if not model or typeof(model) ~= "Instance" or not model.Parent then return false end
	if not model:IsA("Model") then return false end

	local name = model.Name
	if name ~= "Eyes" and name ~= "Lookman" and name ~= "BackdoorLookman" then return false end

	local cached = model:GetAttribute("ValidEyesCached")
	if cached ~= nil then
		return cached
	end

	-- Fast checks
	if model:IsA("Tool") or model:FindFirstAncestorWhichIsA("Tool") then
		model:SetAttribute("ValidEyesCached", false)
		return false
	end

	if model:IsA("Accessory") or model:FindFirstAncestorWhichIsA("Accessory")
		or model:IsA("Accoutrement") or model:FindFirstAncestorWhichIsA("Accoutrement") then
		model:SetAttribute("ValidEyesCached", false)
		return false
	end

	local currentCam = Services.Workspace.CurrentCamera or Camera or Services.Workspace:FindFirstChild("Camera")
	if currentCam and model:IsDescendantOf(currentCam) then
		model:SetAttribute("ValidEyesCached", false)
		return false
	end

	-- O(1) player character check
	local parentModel = model:FindFirstAncestorWhichIsA("Model")
	if parentModel and Services.Players:GetPlayerFromCharacter(parentModel) then
		model:SetAttribute("ValidEyesCached", false)
		return false
	end

	-- Fast ancestor name check
	local cur = model.Parent
	local depth = 0
	while cur and cur ~= Services.Workspace and cur ~= game and depth < 5 do
		local cname = cur.Name:lower()
		if cname:find("fly") or cname:find("flies") or cname:find("swarm")
			or cname:find("gloombat") or cname:find("gloom") or cname:find("bat")
			or cname:find("bug") or cname:find("insect") then
			model:SetAttribute("ValidEyesCached", false)
			return false
		end
		cur = cur.Parent
		depth += 1
	end

	model:SetAttribute("ValidEyesCached", true)
	return true
end

Functions.HandleCharacter = function(NewCharacter)
	for _, Key in CharacterOldConnectionKeys do
		if Connections[Key] then
			Connections[Key]:Disconnect()
			Connections[Key] = nil
		end
	end

	while not LocalPlayer.PlayerGui:FindFirstChild("MainUI") do
		task.wait()
	end

	Character = NewCharacter
	Humanoid = NewCharacter:WaitForChild("Humanoid", 9e9)
	RootPart = NewCharacter:FindFirstChild("HumanoidRootPart")
	Camera   = Services.Workspace.CurrentCamera

	Globals.OldCamera = Camera
	if Functions.HookCamera then
		Functions.HookCamera(Camera)
	end
	Globals.MainUI = LocalPlayer.PlayerGui.MainUI

	Collision = NewCharacter:WaitForChild("Collision", 5) or NewCharacter:FindFirstChild("Collision") or RootPart
	CollisionPart  = NewCharacter:FindFirstChild("CollisionPart") or Collision or RootPart
	if Collision then
		CollisionClone = Collision:Clone()
		CollisionClone.Parent = NewCharacter
		CollisionClone.Name = "CollisionClone"
		CollisionClone.Massless = true
	end

	CollisionPartClone = CollisionPart:Clone()
	CollisionPartClone.Parent = NewCharacter
	CollisionPartClone.Name = "CollisionPartClone"
	CollisionPartClone.CanCollide = false
	CollisionPartClone.Massless = true

	if CollisionPartClone:FindFirstChild("CollisionCrouch") then
		CollisionPartClone.CollisionCrouch:Destroy()
	end

	Character:SetAttribute("SpeedBoost", 0)
	Character:SetAttribute("SpeedBoostBehind", 0)
	Character:SetAttribute("SpeedBoostExtra", 0)

	OldJump  = NewCharacter:GetAttribute("CanJump")
	OldSlide = NewCharacter:GetAttribute("CanSlide")

	if Toggles.EnableCharacterJump.Value  then Character:SetAttribute("CanJump",  true) end
	if Toggles.EnableCharacterSlide.Value then Character:SetAttribute("CanSlide", true) end

	if Functions.CheckCompatability({"require"}) then
		Main_Game = Abysall.Environment.require(Globals.MainUI.Initiator.Main_Game)
	end

	if Main_Game and Toggles.RemoveCameraBobbing.Value then
		Main_Game.spring.Speed = 9e9
	end

	if Main_Game and Functions.CheckCompatability({"require"}) then
		local Controls = require(LocalPlayer.PlayerScripts.PlayerModule):GetControls()
		local OriginalGetMoveVector = Controls.GetMoveVector
		Globals.OriginalGetMoveVector = OriginalGetMoveVector
		Controls.GetMoveVector = function(...)
			if Toggles.AutoSteerMinecart.Value and Floor == "Mines" then
				local Node = Globals.NearestTurnNode
				if Node and Functions.GetMinecart() then
					local Turn = Node:GetAttribute("Turn")
					return Turn == "Left" and Vector3.new(-1, 0, 0) or Turn == "Right" and Vector3.new(1, 0, 0) or Vector3.zero
				end
			end
			return OriginalGetMoveVector(...)
		end
	end

	Globals.AutoMinecartDucked = false
	Globals.LastDuck = tick()
	Connections.AutoSteerMinecartDuckHandler = Services.RunService.Heartbeat:Connect(function()
		if not Toggles.AutoSteerMinecart.Value or not Functions.GetMinecart() or tick() - Globals.LastDuck < 0.1 then return end
		Globals.NearestTurnNode = Functions.GetNearestTurnNode()

		if not Globals.AutoMinecartDucked and Functions.GetNearestDuckBoard() then
			Main_Game.crouch(true)
			Globals.AutoMinecartDucked = true
		elseif not Functions.GetNearestDuckBoard() and Globals.AutoMinecartDucked then
			Main_Game.crouch(false)
			Globals.AutoMinecartDucked = false
		end
		if Main_Game then
			Main_Game.fovtarget = Options.FieldOfView.Value
		else
			Camera.FieldOfView = Options.FieldOfView.Value
		end
		Globals.LastDuck = tick()
	end)

	Globals.AnticheatDisabled = false

	local UIModules = Globals.MainUI and Globals.MainUI:FindFirstChild("Initiator")
		and Globals.MainUI.Initiator:FindFirstChild("Main_Game")
		and Globals.MainUI.Initiator.Main_Game:FindFirstChild("RemoteListener")
		and Globals.MainUI.Initiator.Main_Game.RemoteListener:FindFirstChild("Modules")

	if UIModules then
		Modules.A90             = UIModules:FindFirstChild("A90") or UIModules:FindFirstChild("A-90") or (Functions.FindA90Module and Functions.FindA90Module())
		Modules.Screech         = UIModules:FindFirstChild("Screech") or UIModules:FindFirstChild("Screech_Disabled")
		Modules.Dread           = UIModules:FindFirstChild("Dread") or UIModules:FindFirstChild("Dread_Disabled")
		local foundSpiders      = Functions.FindSpiderModules and Functions.FindSpiderModules()
		Modules.SpiderJumpscare = (foundSpiders and foundSpiders[1]) or UIModules:FindFirstChild("SpiderJumpscare") or UIModules:FindFirstChild("SpiderJumpscare_Disabled")
	else
		if Functions.FindA90Module then Modules.A90 = Functions.FindA90Module() end
		if Functions.FindSpiderModules then
			local foundSpiders = Functions.FindSpiderModules()
			Modules.SpiderJumpscare = foundSpiders and foundSpiders[1]
		end
	end

	if Toggles.RemoveScreech.Value and Modules.Screech then Modules.Screech.Name = "Screech_Disabled" print ("screech gone") end
	if Toggles.RemoveA90.Value and Functions.ApplyRemoveA90 then Functions.ApplyRemoveA90(true) end
	if Toggles.RemoveDread.Value and Modules.Dread then Modules.Dread.Name = "Dread_Disabled" end
	if Toggles.DisableTimothyJumpscare.Value and Functions.ApplyDisableTimothyJumpscare then
		Functions.ApplyDisableTimothyJumpscare(true)
	elseif Toggles.DisableTimothyJumpscare.Value and Modules.SpiderJumpscare then
		Modules.SpiderJumpscare.Name = "SpiderJumpscare_Disabled"
	end

	if Toggles.DisableHideVignette.Value then
		local Vignette = Globals.MainUI:FindFirstChild("HideVignette") or Globals.MainUI.MainFrame:FindFirstChild("HideVignette")
		if Vignette then Vignette.Image = "Disabled" end
	end
	if Toggles.RemoveInteractingSounds.Value then
		pcall(function()
			local MainGame = Globals.MainUI and Globals.MainUI:FindFirstChild("Initiator") and Globals.MainUI.Initiator:FindFirstChild("Main_Game")
			if MainGame then
				local PS = MainGame:FindFirstChild("PromptService")
				if PS then
					if PS:FindFirstChild("Triggered") then PS.Triggered.Volume = 0 end
					if PS:FindFirstChild("Holding") then PS.Holding.Volume = 0 end
					if PS:FindFirstChild("Notification") then PS.Notification.Volume = 0 end
				end
				local Reminder = MainGame:FindFirstChild("Reminder")
				local Caption = Reminder and Reminder:FindFirstChild("Caption")
				if Caption then
					Caption.Volume = 0
				end
			end
		end)
	end
	if Toggles.DisableEntityJumpscares.Value then
		local JS = Globals.MainUI.Initiator.Main_Game.RemoteListener:FindFirstChild("Jumpscares")
		if JS then JS.Name = "Jumpscares_Disabled" end
	end
    local Cutscenes = Globals.MainUI.Initiator.Main_Game.RemoteListener.Cutscenes
    for _, Object in pairs(Cutscenes:GetChildren()) do
        if table.find(CutsceneNames, Object.Name) and Object:IsA("ModuleScript") then
            Object:SetAttribute("OriginalName", Object.Name)
            if Toggles.RemoveCutscenes.Value then
                Object.Name = Object.Name .. "_Disabled"
            end
        end
    end
    for _, Object in pairs(FloorReplicated:GetChildren()) do
        if table.find(CutsceneNames, Object.Name) and Object:IsA("ModuleScript") then
            Object:SetAttribute("OriginalName", Object.Name)
            if Toggles.RemoveCutscenes.Value then
                Object.Name = Object.Name .. "_Disabled"
            end
        end
    end

	CustomPhysics = PhysicalProperties.new(
		100,
		RootPart.CustomPhysicalProperties.Friction,
		RootPart.CustomPhysicalProperties.Elasticity,
		RootPart.CustomPhysicalProperties.FrictionWeight,
		RootPart.CustomPhysicalProperties.ElasticityWeight
	)

	for _, Part in NewCharacter:GetDescendants() do
		if Part:IsA("BasePart") then
			PartProperties[Part] = Part.CustomPhysicalProperties
			if Toggles.RemoveAcceleration.Value then
				Part.CustomPhysicalProperties = CustomPhysics
			end
		end
	end

	Connections.LibraryCodeHandler1 = LocalPlayer.PlayerGui.PermUI.Hints.ChildAdded:Connect(function()
		if Toggles.NotifyLibraryCode.Value then
			local Code = Functions.GetLibraryCode()
			if Code and not Code:find("_") and not Globals.LibraryCodeFound then
				local Lock = Services.Workspace:FindFirstChild("Padlock", true)
				Functions.Notify({ Title = "Padlock code found!", Body = "The code is: '" .. Code .. "'", Time = Toggles.NotifyKeepNotifications.Value and Lock or 15 })
				Globals.LibraryCodeFound = true
			end
		end
	end)

	Connections.LibraryCodeHandler2 = Character.ChildAdded:Connect(function(Child)
		if (Child.Name == "LibraryHintPaper" or Child.Name == "LibraryHintPaperHard") and Toggles.NotifyLibraryCode.Value then
			local Code = Functions.GetLibraryCode()
			if Code and not Code:find("_") and not Globals.LibraryCodeFound then
				local Lock = Services.Workspace:FindFirstChild("Padlock", true)
				Functions.Notify({ Title = "Padlock code found!", Body = "The code is: '" .. Code .. "'", Time = Toggles.NotifyKeepNotifications.Value and Lock or 15 })
				Globals.LibraryCodeFound = true
			end
		end
	end)

	Connections.FootstepHandler = Character.ChildAdded:Connect(function(Object)
		if Object:IsA("Sound") and Object.Name == "Sound" and Toggles.RemoveFootstepSounds.Value then
			Object.Volume = 0
		end
	end)

	Globals.OldOxygen = Character:GetAttribute("Oxygen")
	Connections.OxygenConnection = Character:GetAttributeChangedSignal("Oxygen"):Connect(function()
		local NewOxy = Character:GetAttribute("Oxygen")
		if NewOxy < Globals.OldOxygen and Toggles.NotifyOxygen.Value then
			Functions.Caption(Functions.FormatOxygen(NewOxy), true)
		end
		Globals.OldOxygen = NewOxy
	end)

	Connections.AutoReviveHandler = LocalPlayer:GetAttributeChangedSignal("Alive"):Connect(function()
		if LocalPlayer:GetAttribute("Alive") == false and Toggles.AutoRevive.Value then
			if Floor == "Fools" or Floor == "OldHotel" then
				while LocalPlayer:GetAttribute("Alive") ~= true do
					RemotesFolder.Revive:FireServer()
					task.wait(0.5)
				end
			end
		end
	end)

	Connections.SHMFixer = RootPart:GetPropertyChangedSignal("Anchored"):Connect(function()
		task.wait()
		if Floor == "Fools" and RootPart.Anchored and Character:GetAttribute("Hiding") ~= true then
			RootPart.Anchored = false
		end
	end)

	Connections.AnticheatDisabler = Character:GetAttributeChangedSignal("Climbing"):Connect(function()
		if Character:GetAttribute("Climbing") == true and Toggles.DisableAnticheat.Value and not Globals.AnticheatDisabled then
			task.wait(0.25)
			Character:SetAttribute("Climbing", false)
			Functions.Notify({ Title = "Successfully disabled the anticheat.", Body = "It will be re-enabled after a cutscene or halt room." })
			Globals.AnticheatDisabled = true
		end
	end)

	if RemotesFolder then
		local cutsceneRemote = RemotesFolder:WaitForChild("Cutscene", 3) or RemotesFolder:FindFirstChild("Cutscene")
		if cutsceneRemote and cutsceneRemote:IsA("RemoteEvent") then
			Connections.AnticheatEnableDetector1 = cutsceneRemote.OnClientEvent:Connect(function(CutsceneName)
				if Globals.AnticheatDisabled and not CutsceneName:find("SewerSeek") then
					Globals.AnticheatDisabled = false
					Functions.Notify({ Title = "The anticheat has been re-enabled.", Body = "Interact with a ladder to disable it again." })
				end
			end)
		end

		local useEnemyRemote = RemotesFolder:WaitForChild("UseEnemyModule", 3) or RemotesFolder:FindFirstChild("UseEnemyModule")
		if useEnemyRemote and useEnemyRemote:IsA("RemoteEvent") then
			Connections.AnticheatEnableDetector2 = useEnemyRemote.OnClientEvent:Connect(function(ModuleName)
				if ModuleName == "Void" or ModuleName == "Glitch" then
					if Globals.AnticheatDisabled then
						Globals.AnticheatDisabled = false
						Functions.Notify({ Title = "The anticheat has been re-enabled.", Body = "Interact with a ladder to disable it again." })
					end
					LocalPlayer:SetAttribute("CurrentRoom", LatestRoom.Value)
				end
			end)
		end
	end

	Connections.AnimationHandler = Character.ChildAdded:Connect(function()
		local ToolNames = { "Lockpick","Shears","SkeletonKey","Key","GeneratorFuse","KeyElectrical","KeyBackdoor","KeyIron", "Multitool" }
		local Tool
		for _, Name in ToolNames do
			Tool = Character:FindFirstChild(Name)
			if Tool then break end
		end
		if not Tool then return end

		local UseAnim = Tool:FindFirstChild("use", true) or Tool:FindFirstChild("promptanim", true)
		if UseAnim then
			UseAnim = Humanoid:LoadAnimation(UseAnim)
			UseAnim.Priority = Enum.AnimationPriority.Action4
			Globals.UseAnimation = UseAnim
		end
		local UseAnimBreak = Tool:FindFirstChild("usefinish", true) or Tool:FindFirstChild("promptanimend", true) or Tool:FindFirstChild("lockpickuse", true)
		if UseAnimBreak then
			UseAnimBreak = Humanoid:LoadAnimation(UseAnimBreak)
			UseAnimBreak.Priority = Enum.AnimationPriority.Action4
			Globals.UseAnimationBreak = UseAnimBreak
		end
	end)

	Connections.JumpHandler = Character:GetAttributeChangedSignal("CanJump"):Connect(function()
		local Val = Character:GetAttribute("CanJump")
		if Toggles.EnableCharacterJump.Value and Val ~= true or not Toggles.EnableCharacterJump.Value then
			OldJump = Val
		end
		if Toggles.EnableCharacterJump.Value then Character:SetAttribute("CanJump", true) end
	end)

	Connections.SlideHandler = Character:GetAttributeChangedSignal("CanSlide"):Connect(function()
		local Val = Character:GetAttribute("CanSlide")
		if Toggles.EnableCharacterSlide.Value and Val ~= true or not Toggles.EnableCharacterSlide.Value then
			OldSlide = Val
		end
		if Toggles.EnableCharacterSlide.Value then Character:SetAttribute("CanSlide", true) end
	end)

	Connections.InfiniteJumpsConnection1 = Services.UserInputService.InputBegan:Connect(function(Input)
		if Input.KeyCode == Enum.KeyCode.Space and Toggles.InfiniteJumps.Value and not Globals.IsTyping then
			Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end)

	local JumpButton = Globals.MainUI.MainFrame.MobileButtons:FindFirstChild("JumpButton")
	if JumpButton then
		Connections.InfiniteJumpsConnection2 = JumpButton.MouseButton1Down:Connect(function()
			if Toggles.InfiniteJumps.Value then
				Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end)
	end

	Globals.SpoofOffset = 0
	Globals.LastAutoHide = tick()
	Connections.AutoHideConnection = Services.RunService.Heartbeat:Connect(function()
		if not Toggles.AutoClosetToggle.Value or tick() - Globals.LastAutoHide <= 0.1 then
			Globals.AutoClosetActive = false
			return
		end
		local Entity = Functions.GetNearestEntity(true, Options.AutoClosetEntityList.Value)
		local EntityNearby = Entity and LocalPlayer:DistanceFromCharacter(Entity.PrimaryPart.Position) <= (EntityDistances[Entity.Name] or 150)
		if Character:GetAttribute("Hiding") == true then
			Globals.AutoClosetActive = false
			Globals.SpectateEntity = nil
			if not EntityNearby then
				RemotesFolder.CamLock:FireServer()
			end
			Globals.LastAutoHide = tick()
			return
		end
		if not Entity then
			Globals.SpectateEntity = nil
			Globals.AutoClosetActive = false
			Globals.LastAutoHide = tick()
			return
		end
		if not EntityNearby then
			Globals.SpectateEntity = nil
			Globals.AutoClosetActive = false
			Globals.LastAutoHide = tick()
			return
		end
		local Closet = Functions.GetNearestHidingSpot()
		if Character:GetAttribute("Hiding") ~= true and Closet then
			local Prompt = Closet:FindFirstChild("HidePrompt")
				or Closet:FindFirstChild("HidingPrompt")
				or Closet:FindFirstChild("HidePrompt", true)
				or Closet:FindFirstChild("HidingPrompt", true)

			if not Prompt then
				for _, Child in Closet:GetDescendants() do
					if (Child:IsA("ProximityPrompt") or Child:IsA("InteractPrompt"))
						and (Child.Name == "HidePrompt" or Child.Name == "HidingPrompt")
					then
						Prompt = Child
						break
					end
				end
			end

			if Prompt then
				Globals.AutoClosetActive = true
				Functions.ForceFirePrompt(Prompt)
			end
		end
		if Character:GetAttribute("Hiding") then
			if Toggles.SpectateEntityToggle.Value and Entity.PrimaryPart then
				Globals.SpectateEntity = Entity
			end
		end
		Globals.LastAutoHide = tick()
	end)

	Globals.LastAutoAnchor = tick()
	Connections.AutoSolveAnchorsConnection = Services.RunService.Heartbeat:Connect(function()
		if not Toggles.AutoSolveAnchors.Value then return end
		if not Globals.MainUI:FindFirstChild("AnchorHintFrame") then return end
		if tick() - Globals.LastAutoAnchor <= 0.1 then return end
		local Anchor = Functions.GetCurrentAnchor()
		if Anchor and LocalPlayer:DistanceFromCharacter(Anchor.PrimaryPart.Position) < Anchor.ActivateEventPrompt.MaxActivationDistance and not Anchor:GetAttribute("Activated") then
			Anchor:WaitForChild("AnchorRemote"):InvokeServer(Globals.MainUI.AnchorHintFrame.Code.Text)
		end
		Globals.LastAutoAnchor = tick()
	end)

	Globals.ManipulateBody = Instance.new("BodyVelocity")
	Globals.ManipulateBody.MaxForce = Vector3.new(9e9, 9e9, 9e9)

	Globals.FlyBody = Instance.new("BodyVelocity")
	Globals.FlyBody.MaxForce = Vector3.new(9e9, 9e9, 9e9)

	Globals.SelfKilled = false
	Globals.ThirdPersonParts = {}
	for _, Object in Character:GetDescendants() do
		if Object:IsA("Accessory") and Object:FindFirstChild("Handle") then
			table.insert(Globals.ThirdPersonParts, Object.Handle)
		end
	end
	table.insert(Globals.ThirdPersonParts, Character:WaitForChild("Head"))

	Globals.LastAnimationCheck = tick()
	Globals.LastCrouchFire = tick()
	Globals.OriginalC1 = Character.LowerTorso.Root.C1

	local RayParams = RaycastParams.new()
	RayParams.FilterType = Enum.RaycastFilterType.Exclude

	local MainFrame = Globals.MainUI:FindFirstChild("MainFrame")
	if MainFrame and MainFrame:FindFirstChild("SurgeVignette") then
		Globals.SurgeFrame = MainFrame.SurgeVignette
		if Toggles.RemoveSurge.Value then
			Globals.SurgeFrame.Name = "SurgeVignette_Disabled"
		end
	end

	Connections.MainHandler = Services.RunService.RenderStepped:Connect(function()
		if Services.Workspace.CurrentCamera then
			Camera = Services.Workspace.CurrentCamera
		elseif Services.Workspace:FindFirstChild("Camera") then
			Camera = Services.Workspace:FindFirstChild("Camera")
		end

		-- Быстрое отслеживание и видимость Noise / NoiseModel
		local function ProcessNoiseEntity(noiseInst)
			if not noiseInst or not noiseInst.Parent then return end
			if not noiseInst:GetAttribute("Abysall_NoiseHandled") then
				noiseInst:SetAttribute("Abysall_NoiseHandled", true)
				if Functions.HandleEntitySpawn then
					task.spawn(Functions.HandleEntitySpawn, noiseInst)
				end
			end
			if not noiseInst:GetAttribute("Abysall_VisibleFixed") then
				noiseInst:SetAttribute("Abysall_VisibleFixed", true)
				if noiseInst:IsA("BasePart") and noiseInst.Name ~= "HumanoidRootPart" then
					noiseInst.Transparency = 0
					noiseInst.LocalTransparencyModifier = 0
				end
				for _, part in ipairs(noiseInst:GetDescendants()) do
					if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
						part.Transparency = 0
						part.LocalTransparencyModifier = 0
					elseif part:IsA("Decal") or part:IsA("Texture") then
						part.Transparency = 0
					end
				end
			end
		end

		local activeCam = Services.Workspace.CurrentCamera or Camera or Services.Workspace:FindFirstChild("Camera")
		if activeCam then
			local noiseInCam = activeCam:FindFirstChild("NoiseModel") or activeCam:FindFirstChild("Noise")
			if noiseInCam then ProcessNoiseEntity(noiseInCam) end
		end

		local nowTick = tick()
		if not Globals.LastNoiseCheck or (nowTick - Globals.LastNoiseCheck > 0.5) then
			Globals.LastNoiseCheck = nowTick
			local wsNoise = Services.Workspace:FindFirstChild("NoiseModel") or Services.Workspace:FindFirstChild("Noise")
			if not wsNoise then
				local liveEnts = Services.Workspace:FindFirstChild("LiveEntities")
				if liveEnts then
					wsNoise = liveEnts:FindFirstChild("NoiseModel") or liveEnts:FindFirstChild("Noise")
				end
			end
			if wsNoise and wsNoise.Name ~= "TV_Stand" and wsNoise.Name ~= "Noise_TV" and wsNoise.Name ~= "NoiseTV" and not wsNoise:FindFirstAncestor("TV_Stand") and not wsNoise:FindFirstAncestor("Noise_TV") then
				ProcessNoiseEntity(wsNoise)
			end
		end

		if Toggles.SpeedBoostToggle.Value then
			Humanoid.WalkSpeed = Functions.GetCurrentSpeed() + Options.SpeedBoostSlider.Value
		end

		if Globals.Lagging or (Options.SpeedBoostSlider.Value <= 6 and Options.FlySpeed.Value <= 21) then
			CollisionPartClone.Massless = true
		end

		local hasEyes = false
		local hasLookman = false

		if (Toggles.BypassEyes and Toggles.BypassEyes.Value) or (Toggles.BypassLookman and Toggles.BypassLookman.Value) then
			local wsEyes = Services.Workspace:FindFirstChild("Eyes") or Services.Workspace:FindFirstChild("Lookman")
			if wsEyes and Functions.IsValidEyes(wsEyes) then
				hasEyes = true
			else
				local live = Services.Workspace:FindFirstChild("LiveEntities")
				if live then
					local liveEyes = live:FindFirstChild("Eyes") or live:FindFirstChild("Lookman")
					if liveEyes and Functions.IsValidEyes(liveEyes) then
						hasEyes = true
					end
				end
			end

			local wsLookman = Services.Workspace:FindFirstChild("BackdoorLookman")
			if wsLookman and Functions.IsValidEyes(wsLookman) then
				hasLookman = true
			else
				local live = Services.Workspace:FindFirstChild("LiveEntities")
				if live then
					local liveLookman = live:FindFirstChild("BackdoorLookman")
					if liveLookman and Functions.IsValidEyes(liveLookman) then
						hasLookman = true
					end
				end
			end
		end

		Globals.IsEyes    = hasEyes
		Globals.IsLookman = hasLookman

		if Toggles.AmbientToggle.Value and Services.Lighting.Ambient ~= Options.AmbientColor.Value then
			Services.Lighting.Ambient = Options.AmbientColor.Value
		end

		if Main_Game then
			if Toggles.RemoveCameraShake.Value     then Main_Game.csgo = CFrame.new() end
			if Toggles.ViewmodelOffsetToggle.Value then
				Main_Game.tooloffset = Vector3.new(Options.ViewmodelOffsetX.Value, Options.ViewmodelOffsetY.Value, Options.ViewmodelOffsetZ.Value)
			else
				Main_Game.tooloffset = Vector3.zero
			end
		end

		if Globals.SelfKilled and Globals.MainUI:FindFirstChild("Statistics") then
			Globals.MainUI.Statistics.Death.Text = "Died to Abysall Hub"
		end

		if Globals.Deathing and Globals.MainUI:FindFirstChild("Statistics") then
			Globals.MainUI.Statistics.Death.Text = "Died to Verity"
		end

		local MainFrame = Globals.MainUI:FindFirstChild("MainFrame")
		if MainFrame then
			local Effects = MainFrame.Healthbar:FindFirstChild("Effects")
			if Effects and Effects:FindFirstChild("Crouching") then
				Effects.Crouching.Visible = Functions.IsCrouching()
			end
		end


		-- Auto Position Spoof (включает Position Spoof только при появлении раша/амбуша и выключает когда они ушли)
		if Toggles.AutoPositionSpoof and Toggles.AutoPositionSpoof.Value then
			local monsterAround = IsSpoofMonsterAround()
			if monsterAround and not Globals.LastMonsterAround then
				Globals.LastMonsterAround = true
				Globals.AutoSpoofed = true
				if not Toggles.PositionSpoof.Value then
					Toggles.PositionSpoof:SetValue(true)
				end
			elseif not monsterAround and Globals.LastMonsterAround then
				Globals.LastMonsterAround = false
				if Globals.AutoSpoofed and Toggles.PositionSpoof.Value then
					Toggles.PositionSpoof:SetValue(false)
				end
				Globals.AutoSpoofed = false
			end
		else
			Globals.LastMonsterAround = false
		end

		if (Toggles.CrouchSpoof.Value or Toggles.PositionSpoof.Value) and RemotesFolder:FindFirstChild("Crouch") then
			RemotesFolder.Crouch:FireServer(true, true)
		end

		if Floor ~= "Fools" and Floor ~= "OldHotel" and not Camera:FindFirstChild("MinecartRig") then
			RootPart.CanCollide = false
		end

		for _, Part in ipairs(Character:GetChildren()) do
			if Part:IsA("BasePart") and Part.CanCollide then
				Part.CanCollide = false
			end
		end

		if LocalPlayer:GetAttribute("Alive") == true then
			Services.SoundService:WaitForChild("Main").Volume = 1
		end

		if Floor == "OldHotel" or Floor == "Fools" then
			local SpoofOffset = Toggles.PositionSpoof.Value and Functions.GetNearestEntity() and 200 or Toggles.FigureGodmode.Value and Functions.GetNearestFigure() and 200 or 0
			Globals.SpoofOffset = SpoofOffset
			Collision.Position = RootPart.Position + Vector3.new(0, SpoofOffset, 0)
			Collision.CanCollide = false
			if Floor == "Fools" then
				Collision.CollisionCrouch.CanCollide = false
				CollisionClone.CollisionCrouch.CanCollide = false
			end
			RootPart.CanCollide = not (Toggles.NoclipToggle.Value or Toggles.VelocityManipulationToggle.Value)
		else
			Collision.CanCollide = false
			if Collision:FindFirstChild("CollisionCrouch") then Collision.CollisionCrouch.CanCollide = false end

			if CollisionClone:FindFirstChild("CollisionCrouch") then
				local IsCrouch = Functions.IsCrouching()
				CollisionClone.CanCollide = not (Toggles.NoclipToggle.Value or Toggles.VelocityManipulationToggle.Value or IsCrouch)
				CollisionClone.CollisionCrouch.CanCollide = not (Toggles.NoclipToggle.Value or Toggles.VelocityManipulationToggle.Value or not IsCrouch)
			else
				RootPart.CanCollide = not (Toggles.NoclipToggle.Value or Toggles.VelocityManipulationToggle.Value)
			end

			if Character:FindFirstChild("LowerTorso") and Character.LowerTorso:FindFirstChild("Root") then
				Character.LowerTorso.Root.C1 = Globals.OriginalC1 * CFrame.new(0, Toggles.PositionSpoof.Value and -2.346 or 0, 0)
			end

			local SpoofY = Toggles.PositionSpoof.Value and 2.328 or 0.18
			Collision.Position     = RootPart.Position + Vector3.new(0, SpoofY, 0)
			CollisionPart.Position = RootPart.Position + Vector3.new(0, SpoofY, 0)

			if Collision:FindFirstChild("CollisionCrouch") and CollisionClone:FindFirstChild("CollisionCrouch") then
				local CrouchY = Toggles.PositionSpoof.Value and 1.328 or -0.982
				Collision.CollisionCrouch.Position = RootPart.Position + Vector3.new(0, CrouchY, 0)
				CollisionClone.CollisionCrouch.CollisionGroup = Collision.CollisionCrouch.CollisionGroup
			end
			if CollisionClone:FindFirstChild("CollisionCrouch") then
				CollisionClone.CollisionCrouch.Position = RootPart.Position + Vector3.new(0, Toggles.PositionSpoof.Value and 0.75 or -0.982, 0)
			end
		end

		CollisionClone.CollisionGroup = Collision.CollisionGroup
		CollisionClone.Position = RootPart.Position + Vector3.new(0, Toggles.PositionSpoof.Value and 1.75 or 0.18, 0)

		if Toggles.VelocityManipulationToggle.Value and Options.VelocityManipulationMode.Value == "Velocity" then
			local speed = (Options.VelocityManipulationSpeed and Options.VelocityManipulationSpeed.Value) or 2.25
			local camLook = Camera and Camera.CFrame.LookVector or RootPart.CFrame.LookVector
			local verticalInput = 0
			if not Globals.IsTyping then
				if Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) then
					verticalInput = verticalInput + 1
				end
				if Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
					or Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
					or Services.UserInputService:IsKeyDown(Enum.KeyCode.C)
					or Services.UserInputService:IsKeyDown(Enum.KeyCode.Q)
				then
					verticalInput = verticalInput - 1
				end
			end

			local moveVelocity
			if verticalInput ~= 0 then
				local flatLook = Vector3.new(camLook.X, 0, camLook.Z)
				if flatLook.Magnitude > 0.01 then
					flatLook = flatLook.Unit
				else
					flatLook = Vector3.new(RootPart.CFrame.LookVector.X, 0, RootPart.CFrame.LookVector.Z).Unit
				end
				moveVelocity = (flatLook * speed) + Vector3.new(0, verticalInput * speed, 0)
			else
				moveVelocity = camLook * speed
			end

			Globals.ManipulateBody.Parent = RootPart
			Globals.ManipulateBody.Velocity = moveVelocity
		else
			Globals.ManipulateBody.Parent = nil
		end

		if Toggles.VelocityManipulationToggle.Value and Options.VelocityManipulationMode.Value == "Pivot" and Floor ~= "Fools" and Floor ~= "OldHotel" then
			Character:PivotTo(Camera:GetPivot() * CFrame.new(0, 0, 2560))
		end

		if Toggles.FlyToggle.Value then
			Globals.FlyBody.Parent = RootPart
			Globals.FlyBody.Velocity = Functions.GetFlyVelocity() * Options.FlySpeed.Value
		else
			Globals.FlyBody.Parent = nil
		end

		local DoEyesBypass = (Toggles.BypassEyes.Value and Globals.IsEyes) or (Toggles.BypassLookman.Value and Globals.IsLookman)
		if DoEyesBypass then
			if Floor == "Fools" or Floor == "OldHotel" then
				RemotesFolder.MotorReplication:FireServer(0, (Globals.SpoofOffset == 200 and 65 or -65), 0, false)
			else
				RemotesFolder.MotorReplication:FireServer(-650)
			end
		end

		if RemotesFolder:FindFirstChild("Crouch") and tick() - Globals.LastCrouchFire > 0.1 then
			local IsCrouch = Functions.IsCrouching()
			if Toggles.CrouchSpoof.Value or Toggles.PositionSpoof.Value then IsCrouch = true end
			RemotesFolder.Crouch:FireServer(IsCrouch, true)
			Globals.LastCrouchFire = tick()
		end

		if tick() - Globals.LastAnimationCheck > 0.1 then
			local Sliding = false
			for _, Anim in Humanoid:GetPlayingAnimationTracks() do
				if Anim.Name == "Slide" then Sliding = true break end
			end
			Globals.Sliding = Sliding
			Globals.LastAnimationCheck = tick()
		end

		Character:SetAttribute("Sliding", Globals.Sliding)
		if Character:GetAttribute("Crouching") ~= Functions.IsCrouching() then
			Character:SetAttribute("Crouching", Functions.IsCrouching())
		end

		RayParams.FilterDescendantsInstances = { Character }
		local TPOffset = CFrame.new(Options.ThirdPersonOffsetX.Value, Options.ThirdPersonOffsetY.Value, Options.ThirdPersonOffsetZ.Value)
		local Direction = (Camera.CFrame * TPOffset).Position - Camera.CFrame.Position
		local WallResult = Services.Workspace:Spherecast(Camera.CFrame.Position, 0.2, Direction, RayParams)

		if Toggles.ThirdPersonToggle.Value then
			if Toggles.ThirdPersonWallCheck.Value and WallResult and WallResult.Instance.CanCollide then
				local NewPos = Camera.CFrame.Position + Direction.Unit * WallResult.Distance
				Camera.CFrame = CFrame.new(NewPos, NewPos + Camera.CFrame.LookVector)
			else
				Camera.CFrame = Camera.CFrame * TPOffset
			end
		end

		if Toggles.ThirdPersonToggle.Value then
			for _, Part in ipairs(Globals.ThirdPersonParts) do
				if Part and Part.Parent then
					Part.Transparency = 0
					Part.LocalTransparencyModifier = 0
				end
			end
		end

		if Globals.SpectateEntity and Toggles.AutoClosetToggle.Value and Toggles.SpectateEntityToggle.Value then
			local Entity = Globals.SpectateEntity

			local CamPosition
			if Options.SpecateEntityMode.Value == "Player to Entity" then
				CamPosition = CFrame.lookAt(Character.Head.Position, Entity.PrimaryPart.Position)
			else
				CamPosition = CFrame.lookAt(Entity.PrimaryPart.Position, Character.Head.Position)
			end

			Camera.CFrame = CamPosition
		end

		if Toggles.FOVToggle.Value then
			if Main_Game then
				task.wait()
				Main_Game.fovtarget = Options.FieldOfView.Value
			else
				Camera.FieldOfView = Options.FieldOfView.Value
			end
		end

		if Toggles.RemoveClosetDelay.Value
			and Humanoid.MoveDirection ~= Vector3.zero
			and (CollisionPart.Anchored or RootPart.Anchored)
			and Character:GetAttribute("AnimatingClient") ~= true
			and Character:GetAttribute("Hiding") == true
		then
			RemotesFolder.CamLock:FireServer()
		end

		local ClosestPlayer = { Distance = math.huge, Object = nil }
		for _, Player in Services.Players:GetPlayers() do
			if Player.Character and Player ~= LocalPlayer then
				local Root = Player.Character:FindFirstChild("HumanoidRootPart")
				if Root then
					local D = (Camera.CFrame.Position - Root.Position).Magnitude
					if D < ClosestPlayer.Distance then
						ClosestPlayer.Distance = D
						ClosestPlayer.Object = Player
					end
				end
			end
		end
		if ClosestPlayer.Object and LocalPlayer:GetAttribute("Alive") ~= true then
			LocalPlayer:SetAttribute("CurrentRoom", ClosestPlayer.Object:GetAttribute("CurrentRoom"))
		end
	end)

	task.wait(1)
	if Toggles.PositionSpoof.Value and Floor ~= "Fools" and Floor ~= "OldHotel" and RootPart and Humanoid then
		RootPart.CFrame = RootPart.CFrame * CFrame.new(0, -2.346, 0)
		Humanoid.HipHeight = 0.05
		if RemotesFolder:FindFirstChild("Crouch") then
			RemotesFolder.Crouch:FireServer(true, true)
		end
	end

	local Jam = Globals.MainUI.Initiator.Main_Game.Health:FindFirstChild("Jam")
	if Jam and Toggles.RemoveJamminMusic.Value then
		Jam.Volume = 0
		Globals.JamMuffle.Enabled = false
	end
end

Functions.HandleHidingTransparency = function(Model)
	local Parts = {}
	for _, Part in Model:GetDescendants() do
		if Part:IsA("BasePart") then
			Part:SetAttribute("Transparency_Old", Part.Transparency)
			table.insert(Parts, Part)
		end
		if Part.Name == "HiddenPlayer" then
			local HideConn = Part:GetPropertyChangedSignal("Value"):Connect(function()
				for _, P in Parts do
					if P:GetAttribute("Transparency_Old") then
						Services.TweenService:Create(P, TweenInfo.new(0.25, Enum.EasingStyle.Linear), {
							Transparency = (Part.Value == Character and Toggles.TransparentHidingSpotsToggle.Value)
								and Options.TransparentHidingSpotsSlider.Value
								or P:GetAttribute("Transparency_Old")
						}):Play()
					end
				end
			end)
			table.insert(Connections, HideConn)
			Model.Destroying:Once(function()
				HideConn:Disconnect()
				local Pos = table.find(Connections, HideConn)
				if Pos then table.remove(Connections, Pos) end
			end)
		end
	end
end

Functions.HandleObject = function(Object)
	if CurrentRooms then
		for _, Room in ipairs(CurrentRooms:GetChildren()) do
			if Object:IsDescendantOf(Room) then
				Object:SetAttribute("ParentRoom", tonumber(Room.Name))
				break
			end
		end
	end

	if Object.Parent == CurrentRooms then
		local FiredampVal = Object:GetAttribute("Firedamp")
		Object:SetAttribute("Firedamp_Old", FiredampVal ~= nil and FiredampVal or false)
		if Toggles.DisableFiredampEffect.Value then
			Object:SetAttribute("Firedamp", false)
		end
	end

	local Name = Object.Name

	if Name == "KeyObtain" then
		task.spawn(function()
			task.wait(0.5)
			if Object.Parent then
				if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Door Key", Color = Options.ObjectiveESPColor.Value }, true) end
				table.insert(Objects.Objectives, Object)
			end
		end)
	elseif Name == "ElectricalKeyObtain" then
		task.spawn(function()
			task.wait(0.5)
			if Object.Parent then
				if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Electrical Key", Color = Options.ObjectiveESPColor.Value }, true) end
				table.insert(Objects.Objectives, Object)
			end
		end)
	elseif Name == "TimerLever" then
		task.spawn(function()
			task.wait(0.5)
			if Object.Parent then
				Object:SetAttribute("AddTime", Object.TakeTimer.TextLabel.Text == "01:00" and 60 or 30)
				if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Time Lever [+" .. Object:GetAttribute("AddTime") .. "s]", Color = Options.ObjectiveESPColor.Value }, true) end
				Object:WaitForChild("Main").SoundToPlay.Played:Once(function()
					Functions.RemoveESP(Object)
					Functions.BlacklistESP(Object)
				end)
				table.insert(Objects.Objectives, Object)
			end
		end)
	elseif Name == "StairwellLockpickDoor" then
		if Toggles.MiscESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Garage Door", Color = Options.MiscESPColor.Value }, true) end
		table.insert(Objects.Misc, Object)
	elseif Name == "Mirror" then
		if Toggles.MiscESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Mirror", Color = Options.MiscESPColor.Value }, true) end
		table.insert(Objects.Misc, Object)
	elseif Name == "StairwellFireAlarm" then
		if Toggles.MiscESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Fire Alarm", Color = Options.MiscESPColor.Value }, true) end
		table.insert(Objects.Misc, Object)
	elseif Name == "ShoppingCart" then
		if Toggles.MiscESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Shopping Cart", Color = Options.MiscESPColor.Value }, true) end
		table.insert(Objects.Misc, Object)
	elseif Name == "StairwellScrapper" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Scrapper", Color = Options.ObjectiveESPColor.Value }, true) end
		table.insert(Objects.Objectives, Object)
	elseif Name == "ArchivesPackageDeposit" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Package Deposit", Color = Options.ObjectiveESPColor.Value }, true) end
		table.insert(Objects.Objectives, Object)
	elseif Name == "Cellar" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Cellar", Color = Options.ObjectiveESPColor.Value }, true) end
		table.insert(Objects.Objectives, Object)
	elseif Name == "ArchivesFihTank" then
		if Toggles.MiscESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Fih Tank", Color = Options.MiscESPColor.Value }, true) end
		table.insert(Objects.Misc, Object)
	elseif Name == "LiveHintBook" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Hint Book", Color = Options.ObjectiveESPColor.Value }, true) end
		table.insert(Objects.Objectives, Object)
	elseif Name == "LiveBreakerPolePickup" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Fuse Breaker", Color = Options.ObjectiveESPColor.Value }, true) end
		for _, Child in Object:GetChildren() do
			if Child.Name == "ActivateEventPrompt" and (Child.MaxActivationDistance == 5 or Child:GetAttribute("MaxActivationDistance_Old") == 5) then
				Child:Destroy()
			end
		end
		table.insert(Objects.Objectives, Object)
	elseif Name == "LibraryHintPaper" or Name == "PickupItem" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Hint Paper", Color = Options.ObjectiveESPColor.Value }, true) end
		table.insert(Objects.Objectives, Object)
	elseif Name == "MinesAnchor" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Anchor [" .. Object:WaitForChild("Sign").TextLabel.Text .. "]", Color = Options.ObjectiveESPColor.Value }, true) end
		Object:GetAttributeChangedSignal("Activated"):Once(function()
			Functions.RemoveESP(Object)
			Functions.BlacklistESP(Object)
		end)
		table.insert(Objects.Objectives, Object)
	elseif Name == "WaterPump" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object:WaitForChild("Wheel"), Text = "Water Pump", Color = Options.ObjectiveESPColor.Value }, true) end
		Object:WaitForChild("Wheel").Sound.Played:Once(function()
			Object:SetAttribute("Abysall_Completed", true)

			Functions.RemoveESP(Object.Wheel)
			Functions.BlacklistESP(Object.Wheel)
		end)
		table.insert(Objects.Objectives, Object)
	elseif Name == "CringlePresent" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Present", Color = Options.ObjectiveESPColor.Value }, true) end
		Object:WaitForChild("ToolProp").Highlight:Destroy()
		table.insert(Objects.Objectives, Object)
	elseif Name == "LeverForGate" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Gate Lever", Color = Options.ObjectiveESPColor.Value }, true) end
		Object:WaitForChild("Main").SoundToPlay.Played:Once(function()
			Functions.RemoveESP(Object)
			Functions.BlacklistESP(Object)
		end)
		table.insert(Objects.Objectives, Object)
	elseif Name == "VineGuillotine" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object.Lever, Text = "Vine Lever", Color = Options.ObjectiveESPColor.Value }, true) end
		Object.Lever:WaitForChild("ActivateEventPrompt"):GetAttributeChangedSignal("Interactions"):Once(function()
			Functions.RemoveESP(Object)
			Functions.BlacklistESP(Object)
		end)
		table.insert(Objects.Objectives, Object)
	elseif Name == "MandrakeLive" then
		if Toggles.ObjectiveESPToggle.Value and Options.EntityESPOptions.Value["Mandrake Hole"] then Functions.AddESP({ Object = Object.Hole, Text = "Mandrake Hole", Color = Options.EntityESPColor.Value }, true) end
		table.insert(Objects.Entities, Object.Hole)
	elseif Name == "MinesGenerator" then
		task.spawn(function()
			task.wait(0.75)
			if Object.Parent then
				if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Generator", Color = Options.ObjectiveESPColor.Value }, true) end
				Object:WaitForChild("Lever").Sound.Played:Once(function()
					Functions.RemoveESP(Object)
					Functions.BlacklistESP(Object)
				end)
				table.insert(Objects.Objectives, Object)
			end
		end)
	elseif Name == "FuseObtain" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Generator Fuse", Color = Options.ObjectiveESPColor.Value }, true) end
		table.insert(Objects.Objectives, Object)
		task.spawn(function()
			local cleaned = false
			local function cleanup()
				if cleaned then return end
				cleaned = true
				Functions.RemoveESP(Object)
				Functions.BlacklistESP(Object)
			end

			local hitbox = Object:FindFirstChild("Hitbox") or Object:WaitForChild("Hitbox", 2)
			local fuseModel = (hitbox and hitbox:FindFirstChild("FuseModel"))
				or Object:FindFirstChild("FuseModel")
				or Object:FindFirstChild("FuseModel", true)
				or (hitbox and hitbox:WaitForChild("FuseModel", 2))
				or Object:WaitForChild("FuseModel", 2)

			if fuseModel then
				if fuseModel:IsA("BasePart") then
					fuseModel:GetPropertyChangedSignal("LocalTransparencyModifier"):Once(cleanup)
				else
					local targetPart = fuseModel:FindFirstChildWhichIsA("BasePart", true)
					if targetPart then
						targetPart:GetPropertyChangedSignal("LocalTransparencyModifier"):Once(cleanup)
					end
				end
				fuseModel.AncestryChanged:Once(function(_, parent)
					if not parent or not parent:IsDescendantOf(Services.Workspace) then
						cleanup()
					end
				end)
			end

			if hitbox then
				local prompt = hitbox:FindFirstChildWhichIsA("ProximityPrompt", true)
				if prompt then
					prompt.Triggered:Once(cleanup)
				end
			end

			Object.AncestryChanged:Once(function(_, parent)
				if not parent or not parent:IsDescendantOf(Services.Workspace) then
					cleanup()
				end
			end)
		end)
	elseif Name == "MinesGateButton" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Gate Button", Color = Options.ObjectiveESPColor.Value }, true) end
		Object.Parent:WaitForChild("MinesGate").Main.SoundOpen.Played:Once(function()
			Functions.RemoveESP(Object)
			Functions.BlacklistESP(Object)
		end)
		table.insert(Objects.Objectives, Object)
	elseif Name == "GardenGateButton" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Gate Button", Color = Options.ObjectiveESPColor.Value }, true) end
		Object.Parent:WaitForChild("GardenGate").Collision.Sound.Played:Once(function()
			Functions.RemoveESP(Object)
			Functions.BlacklistESP(Object)
		end)
		table.insert(Objects.Objectives, Object)
	elseif Name == "Ladder" then
		if Toggles.LadderESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Ladder", Color = Options.LadderESPColor.Value }, true) end
		table.insert(Objects.Ladders, Object)
	elseif Name == "Door" and Object.Parent and tonumber(Object.Parent.Name) then
		local DoorParts = {}
		for _, Child in Object:GetChildren() do
			if Child.Name == "Door" and Child:IsA("BasePart") then
				table.insert(DoorParts, Child)
			end
		end

		if #DoorParts == 2 then
			local HighlightModel = Instance.new("Model", Object)
			HighlightModel.Name = "HighlightModel"
			Instance.new("Humanoid", HighlightModel).Name = "HighlightHumanoid"
			HighlightModel:SetAttribute("ParentRoom", tonumber(Object.Parent.Name))

			for _, DoorPart in DoorParts do
				local HP = Instance.new("Part", HighlightModel)
				HP.Transparency = 0.999
				HP.Size = DoorPart.Size
				HP.CanCollide = false
				HP.CFrame = DoorPart.CFrame
				HP.Name = "HighlightPart"
				HP.Material = Enum.Material.Plastic
				HP:SetAttribute("ParentRoom", tonumber(Object.Parent.Name))
				local W = Instance.new("WeldConstraint", HP)
				W.Part0 = HP W.Part1 = DoorPart W.Enabled = true
			end
			table.insert(Objects.Doors, HighlightModel)
			if Toggles.DoorESPToggle.Value then Functions.AddESP({ Object = HighlightModel, Text = "Door " .. Functions.GetDoorNumber(Object), Color = Options.DoorESPColor.Value }, true) end
		else
			local Root = Object:WaitForChild("Door", 9e9)
			local HP = Instance.new("Part", Object)
			HP.Transparency = 0.999
			HP.Size = Root.Size
			HP.CanCollide = false
			HP.CFrame = Root.CFrame
			HP.Name = "HighlightPart"
			HP.Material = Enum.Material.Plastic
			HP:SetAttribute("ParentRoom", tonumber(Object.Parent.Name))
			local W = Instance.new("WeldConstraint", HP)
			W.Part0 = HP W.Part1 = Root W.Enabled = true
			Instance.new("Humanoid", Object).Name = "HighlightHumanoid"
			table.insert(Objects.Doors, HP)
			if Toggles.DoorESPToggle.Value then Functions.AddESP({ Object = HP, Text = "Door " .. Functions.GetDoorNumber(Object), Color = Options.DoorESPColor.Value }, true) end
		end

		local LastDoorFire = tick()
		local DoorConn = Services.RunService.Heartbeat:Connect(function()
			if Object:FindFirstChild("Door") and Object:FindFirstChild("ClientOpen") then
				if LocalPlayer:DistanceFromCharacter(Object.Door.Position) < 75
					and tick() - LastDoorFire > 0.1
					and (Toggles.DoorReachToggle.Value or Functions.GetMinecart())
				then
					Object.ClientOpen:FireServer()
					LastDoorFire = tick()
				end
			end
		end)
		Object.Destroying:Once(function()
			DoorConn:Disconnect()
		end)
		Object:WaitForChild("Door"):WaitForChild("Open").Played:Once(function()
			DoorConn:Disconnect()
		end)
		table.insert(Connections, DoorConn)

	elseif Name == "PathLights" then
		local ObjectsToHighlight = {}
		local PLConn = Object.ChildAdded:Connect(function(Child)
			table.insert(ObjectsToHighlight, Child)
		end)
		for _, Child in Object:GetChildren() do
			table.insert(ObjectsToHighlight, Child)
		end

		local function CreateSeekNode(Light)
			if Light.Name ~= "SeekGuidingLight" or Light:GetAttribute("Highlighted") then return end
			Light:SetAttribute("Highlighted", true)

			local NewNode = Instance.new("Part")
			NewNode.Size = Vector3.one
			NewNode.Transparency = 1
			NewNode.Parent = Globals.SeekNodesFolder
			NewNode.Anchored = true
			NewNode.CFrame = Light.CFrame
			NewNode.CanCollide = false
			NewNode.Name = "SeekLightNode"

			local PrevNode2 = PreviousNode or NewNode
			PreviousNode = NewNode

			local Beam = Instance.new("Beam")
			Beam.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Options.ShowSeekPathColor.Value), ColorSequenceKeypoint.new(1, Options.ShowSeekPathColor.Value) })
			Beam.FaceCamera = true
			Beam.Width0 = 0.2
			Beam.Width1 = 0.2
			Beam.Brightness = 10
			Beam.LightInfluence = 0
			Beam.LightEmission = 0
			Beam.Enabled = true
			local Vis = Toggles.ShowSeekPathToggle.Value and 0 or 1
			Beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, Vis), NumberSequenceKeypoint.new(1, Vis) })
			Beam.Parent = Globals.SeekNodesFolder
			local A0 = Instance.new("Attachment", NewNode)
			local A1 = Instance.new("Attachment", PrevNode2)
			Beam.Attachment0 = A0
			Beam.Attachment1 = A1
			table.insert(Objects.SeekHighlights, Beam)
			Light:Destroy()
		end

		task.spawn(function()
			while task.wait() do
				local Light = table.remove(ObjectsToHighlight, 1)
				if Light then CreateSeekNode(Light) end
			end
		end)

		table.insert(Connections, PLConn)
		table.insert(Objects.PathLights, Object)
		Object.Destroying:Once(function() PLConn:Disconnect() end)
	elseif Name == "SeekMovingNewClone" then
		local Connection = Object.Destroying:Connect(function()
			for _, Folder in pairs(Objects.PathLights) do
				Folder:ClearAllChildren()
			end
			Globals.SeekNodesFolder:ClearAllChildren()
		end)
		table.insert(Connections, Connection)
	elseif Name == "Bridge" then
		for _, Child in Object:GetChildren() do
			if Child.Name == "PlayerBarrier" and Child.Size.Y == 2.75 and (Child.Rotation.X == 0 or Child.Rotation.X == 180) then
				local NewBridge = Child:Clone()
				NewBridge.CFrame = NewBridge.CFrame * CFrame.new(0, 0, -5)
				NewBridge.Name = Abysall.ESPLibrary:GenerateRandomString()
				NewBridge.Size = Vector3.new(NewBridge.Size.X, NewBridge.Size.Y, 11)
				NewBridge.Parent = Object
				NewBridge.CanCollide = Toggles.BypassSeekObstructions.Value
				NewBridge.Color = Color3.fromRGB(0, 255, 255)
				NewBridge.Transparency = Toggles.BypassSeekObstructions.Value and 0 or 1
				NewBridge.Material = Enum.Material.ForceField
				table.insert(Objects.SeekBridges, NewBridge)
			end
			task.wait()
		end
    elseif Name == "MinecartRig" then
        Globals.Minecart = Object
	elseif Name == "RunnerNodes" then
		local function IsBehind(Part1, Part2)
			local P1 = (Part1.CFrame + Part1.CFrame.LookVector).Position
			local P2 = (Part1.CFrame + Part1.CFrame.LookVector * -1).Position
			return (P1 - Part2.Position).Magnitude > (P2 - Part2.Position).Magnitude
		end
		local function GetDirection(Part1, Part2)
			local RightDist = Part1.CFrame.RightVector:Dot(Part1.Position - Part2.Position)
			if RightDist > 0.5    then return IsBehind(Part1, Part2) and "Right" or "Left" end
			if RightDist < -0.5   then return IsBehind(Part1, Part2) and "Left" or "Right" end
			return "Straight"
		end
		local function GetClosestNode(Node)
			local Best, BestDist = nil, math.huge
			local NodeID2 = tonumber(Node.Name:split("MinecartNode")[2])
			for _, OtherNode in Object:GetChildren() do
				local OtherID = tonumber(OtherNode.Name:split("MinecartNode")[2])
				if OtherNode ~= Node and OtherID and NodeID2 and OtherID > NodeID2 then
					local D = (Node.Position - OtherNode.Position).Magnitude
					if D < BestDist and OtherNode:GetAttribute("DistanceBlacklist") ~= true then
						BestDist = D Best = OtherNode
					end
				end
			end
			return Best
		end

		for _, Node in Object:GetChildren() do
			local NodeID = tonumber(Node.Name:split("MinecartNode")[2])
			if Node:GetAttribute("DeathType") then Node:SetAttribute("DistanceBlacklist", true) end
			for I = 1, 20 do
				local NextNode = NodeID and Object:FindFirstChild("MinecartNode" .. NodeID + I)
				if NextNode and NextNode:GetAttribute("DeathType") ~= nil then
					Node:SetAttribute("DistanceBlacklist", true)
				end
			end
			local PrevNode3 = NodeID and Object:FindFirstChild("MinecartNode" .. NodeID - 1)
			if PrevNode3 and PrevNode3:GetAttribute("ForceConnect") then
				Node:SetAttribute("DistanceBlacklist", nil)
			end
			task.wait()
		end

		for _, Node in Object:GetChildren() do
			if Node:GetAttribute("ForceConnect") then
				local NextNode = GetClosestNode(Node)
				if NextNode then
					Node:SetAttribute("Turn", GetDirection(Node, NextNode))
					table.insert(Objects.SeekNodes, Node)
				end
			end
			task.wait()
		end

	elseif Name == "EyestalkEndCutscene" then
		Object.Name = "_EyestalkEndCutscene"
	elseif Name == "DuckBoard" then
		table.insert(Objects.SeekDuckBoards, Object)
	elseif HidingSpotLabels[Name] or string.find(string.lower(Name), "hidingspot") then
		local Label = HidingSpotLabels[Name] or (string.find(string.lower(Name), "hidingspot") and "Hiding Spot" or nil)
		if Label and Toggles.HidingSpotESPToggle.Value then Functions.AddESP({ Object = Object, Text = Label, Color = Options.HidingSpotESPColor.Value }, true) end
		Functions.HandleHidingTransparency(Object)
		table.insert(Objects.HidingSpots, Object)
	elseif Object:FindFirstChild("HidingPrompt") or Object:FindFirstChild("HidePrompt") then
		Functions.HandleHidingTransparency(Object)
		table.insert(Objects.HidingSpots, Object)
	elseif Name == "Lava" then
		if Toggles.BypassKillbricks.Value then Object.CanTouch = false end
		table.insert(Objects.Obstructions, Object)
	elseif Name == "ScaryWall" then
		for _, Part in Object:GetDescendants() do
			if Part:IsA("BasePart") then
				Part.CanTouch = not Toggles.BypassSeekingWall.Value
				Part.CanCollide = not Toggles.BypassSeekingWall.Value

                local Connection1 = Part:GetPropertyChangedSignal("CanTouch"):Connect(function()
                    if Part.CanTouch == Toggles.BypassSeekingWall.Value then
                        Part.CanTouch = not Toggles.BypassSeekingWall.Value
                    end
                end)
                local Connection2 = Part:GetPropertyChangedSignal("CanCollide"):Connect(function()
                    if Part.CanCollide == Toggles.BypassSeekingWall.Value then
                        Part.CanCollide = not Toggles.BypassSeekingWall.Value
                    end
                end)

                table.insert(Connections, Connection1)
                table.insert(Connections, Connection2)
            end
		end
		table.insert(Objects.Obstructions, Object)
	elseif Name == "ChestBox" or Name == "ChestBoxLocked" then
		if Toggles.ChestESPToggle.Value then Functions.AddESP({ Object = Object, Text = Object:GetAttribute("Locked") and "Locked Chest" or "Chest", Color = Options.ChestESPColor.Value }, true) end
		table.insert(Objects.Chests, Object)
	elseif Name == "Toolbox" or Name == "Toolbox_Locked" then
		if Toggles.ChestESPToggle.Value then Functions.AddESP({ Object = Object, Text = Object:GetAttribute("Locked") and "Locked Toolbox" or "Toolbox", Color = Options.ChestESPColor.Value }, true) end
		table.insert(Objects.Chests, Object)
	elseif Name == "Chest_Vine" then
		if Toggles.ChestESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Vine Chest", Color = Options.ChestESPColor.Value }, true) end
		table.insert(Objects.Chests, Object)
	elseif Name == "Toolshed_Small" then
		if Toggles.ChestESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Toolshed", Color = Options.ChestESPColor.Value }, true) end
		table.insert(Objects.Chests, Object)
	elseif Name == "Locker_Small_Locked" then
		if Toggles.ChestESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Locked Item Locker", Color = Options.ChestESPColor.Value }, true) end
		table.insert(Objects.Chests, Object)
	elseif Name == "MouseHole" then
		if Toggles.ChestESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Mouse", Color = Options.ChestESPColor.Value }, true) end
		table.insert(Objects.Chests, Object)
	elseif ItemNames[Name] and Object:FindFirstChild("ModulePrompt") then
		if Toggles.ItemESPToggle.Value then Functions.AddESP({ Object = Object, Text = ItemNames[Name], Color = Options.ItemESPColor.Value }, Object:GetAttribute("ParentRoom") ~= nil) end
		if Name == "LotusHolder" or Name == "LotusPetalPickup" then
			Object.Handle:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
				Abysall.ESPLibrary:RemoveESP(Object)
				Functions.BlacklistESP(Object)
			end)
		end

		if Toggles.NotifyItemsToggle.Value and Options.NotifyItemList.Value[ItemNames[Name]] and Object.Parent.Name ~= "Drops" then
			if Toggles.NotifyItemsShowDistance.Value then
				Functions.Notify({ Title = "Item '" .. ItemNames[Name] .. "' has spawned.", Body = "It is '" .. math.round(LocalPlayer:DistanceFromCharacter(Object.PrimaryPart.Position)) .. "' studs away from you." })
			else
				Functions.Notify({ Title = "Item '" .. ItemNames[Name] .. "' has spawned."})
			end
		end

		table.insert(Objects.Items, Object)
	elseif Name == "Green_Herb" then
		if Toggles.ItemESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Green Herb", Color = Options.ItemESPColor.Value }, true) end
		table.insert(Objects.Items, Object)
	elseif Name == "GoldPile" and Object:GetAttribute("GoldValue") then
		if Toggles.CurrencyESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Gold Pile [" .. Object:GetAttribute("GoldValue") .. "]", Color = Options.CurrencyESPColor.Value }, true) end
		table.insert(Objects.Currency, Object)
	elseif Name == "StardustPickup" then
		if Toggles.CurrencyESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Stardust Pile", Color = Options.CurrencyESPColor.Value }, true) end
		table.insert(Objects.Currency, Object)
	elseif Name == "GiggleCeiling" then
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Giggle"] then Functions.AddESP({ Object = Object, Text = "Giggle", Color = Options.EntityESPColor.Value }, true) end
		if Toggles.BypassGiggle.Value then Object:WaitForChild("Hitbox").CanTouch = false end
		table.insert(Objects.Entities, Object)
	elseif Name == "GloomPile" then
		if Toggles.BypassGloombatEggs.Value then
			for _, Part in Object:GetDescendants() do
				if Part:IsA("BasePart") then Part.CanTouch = false
				end
			end
		end
		local Connection = Object.DescendantAdded:Connect(function(Part)
			if Part:IsA("BasePart") then Part.CanTouch = false end
		end)

		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Gloombat Eggs"] then
			Functions.AddESP({ Object = Object, Text = "Gloombat Eggs", Color = Options.EntityESPColor.Value })
		end

		table.insert(Connections, Connection)
		table.insert(Objects.Entities, Object)
	elseif Name == "TriggerEventCollision" and Functions.CheckCompatability({"firetouchinterest"}) then
		if (Floor == "Fools" or Floor == "OldHotel") and Toggles.RemoveSeekTrigger.Value then
			task.spawn(function()
				while Object:IsDescendantOf(game) do
					for _, Part in Object:GetChildren() do
						if Part:IsA("BasePart") then
							Abysall.Environment.firetouchinterest(RootPart, Part, 0)
							task.wait()
							Abysall.Environment.firetouchinterest(RootPart, Part, 1)
						end
					end
					task.wait()
				end
			end)
		end
		table.insert(Objects.EventTriggers, Object)
	elseif Name == "DoorFake" or Name == "FakeDoor" then
		if Object.Parent and Object:FindFirstChild("Hidden") then
			if Toggles.BypassDupe.Value then
				Object:WaitForChild("Hidden").CanTouch = false
				local Lock = Object:FindFirstChild("Lock")
				if Lock and Lock:FindFirstChild("UnlockPrompt") then Lock.UnlockPrompt.Enabled = false end
			end
			if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Dupe"] then
				Functions.AddESP({ Object = Object, Text = "Dupe", Color = Options.EntityESPColor.Value }, true)
			end
			table.insert(Objects.Entities, Object)
		end
	elseif Name == "SideroomSpace" then
		if Toggles.BypassVacuum.Value then
			Object:WaitForChild("Collision").CanCollide = true
			Object:WaitForChild("Collision").CanTouch = false
		end
		table.insert(Objects.Entities, Object)
	elseif Name == "Snare" then
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Snare"] then Functions.AddESP({ Object = Object, Text = "Snare", Color = Options.EntityESPColor.Value }, true) end
		for _, Part in Object:GetDescendants() do
			if Part:IsA("BasePart") then Part.CanTouch = not Toggles.BypassSnare.Value end
		end
		local Connection = Object.DescendantAdded:Connect(function(Part)
			if Part:IsA("BasePart") then Part.CanTouch = not Toggles.BypassSnare.Value end
		end)
		table.insert(Connections, Connection)
		table.insert(Objects.Entities, Object)

		if Object:FindFirstChild("Snare") then
			Object:WaitForChild("Snare"):WaitForChild("Roots").Transparency = 1
			Object:WaitForChild("Snare"):WaitForChild("SnareBase").Transparency = 1
		end
		if Object:FindFirstChild("Void") then
			Object.Void.Transparency = 0
			Object.Void.Color = Color3.fromRGB(76, 67, 55)
		end
	elseif Name == "Seek_Arm" or Name == "ChandelierObstruction" then
		for _, Part in Object:GetDescendants() do
			if Part:IsA("BasePart") then
				Part.CanTouch = not Toggles.BypassSeekObstructions.Value
				table.insert(Objects.SeekObstructions, Part)
			end
		end
	elseif Name == "SeekFloodline" then
		Object.CanCollide = Toggles.BypassSeekObstructions.Value
		local FloodConn = Object:GetPropertyChangedSignal("CanCollide"):Connect(function()
			if Object.CanCollide ~= Toggles.BypassSeekObstructions.Value then
				Object.CanCollide = Toggles.BypassSeekObstructions.Value
			end
		end)
		Object.Destroying:Once(function() FloodConn:Disconnect() end)
		table.insert(Objects.SeekObstructions, Object)
	elseif Object:GetAttribute("RawName") and Object:GetAttribute("RawName"):find("Halt") or Object:GetAttribute("Shade") == true then
		if Toggles.NotifyEntities.Value and Options.EntityList.Value["Halt"] then
			Functions.Notify({ Title = "Entity 'Halt' will spawn in the next room.", Image = EntityIcons["Halt"] })
			if Toggles.EntityChatToggle.Value then Functions.SendChat("Halt next room!") end
		end
		local HaltLogConn
		HaltLogConn = Services.LogService.MessageOut:Connect(function(Message)
			if Message == "client teleporting" then
				if Globals.AnticheatDisabled then
					Globals.AnticheatDisabled = false
					Functions.Notify({ Title = "The anticheat has been re-enabled.", Body = "Interact with a ladder to disable it again." })
				end
				HaltLogConn:Disconnect()
			end
		end)
	elseif Name == "BananaPeel" then
		if Toggles.BypassBanana.Value then Object.CanTouch = false end
		table.insert(Objects.Entities, Object)
	elseif Name == "JeffTheKiller" then
		if Toggles.BypassJeff.Value then
			for _, Part in Object:GetDescendants() do
				if Part:IsA("BasePart") then Part.CanCollide = false Part.CanTouch = false end
			end
			Object:WaitForChild("Humanoid").Health = 0
		end
	elseif Name == "GrumbleRig" then
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Grumble"] then Functions.AddESP({ Object = Object, Text = "Grumble", Color = Options.EntityESPColor.Value }, true) end
		table.insert(Objects.Entities, Object)
	elseif Name == "LiveEntityBramble" then
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Bramble"] then Functions.AddESP({ Object = Object, Text = "Bramble", Color = Options.EntityESPColor.Value }, true) end
		table.insert(Objects.Entities, Object)
	elseif Name == "Groundskeeper" then
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Groundskeeper"] then Functions.AddESP({ Object = Object, Text = "Groundskeeper", Color = Options.EntityESPColor.Value }, true) end
		if Toggles.NotifyEntities.Value and Options.EntityList.Value["Groundskeeper"] then
			local ED = Entities["Groundskeeper"]
			Functions.Notify({ Title = ED.NotifyMessage.Title, Body = ED.NotifyMessage.Body, Image = EntityIcons["Groundskeeper"] })
		end
		table.insert(Objects.Entities, Object)
	elseif Name == "Figure" or Name == "FigureRig" or Name == "FigureRagdoll" then
		for _, Part in Object:GetDescendants() do
			if Part:IsA("BasePart") then
				Part.CanTouch = false
			end
		end
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Figure"] then Functions.AddESP({ Object = Object, Text = "Figure", Color = Options.EntityESPColor.Value }, true) end
		table.insert(Objects.Entities, Object)
		if Toggles.RemoveFigure.Value and Functions.CheckCompatability({"isnetworkowner"}) then
			if Floor == "Mines" then
				for _, Part in Object:GetDescendants() do
					if Part:IsA("BasePart") then
						task.spawn(function()
							if Abysall.Environment.isnetworkowner(Part) then
								Part.Position = Vector3.new(-49999, -49999, -49999)
							end
						end)
					end
				end
			elseif Floor == "OldHotel" or Floor == "Fools" then
				CurrentRooms.ChildAdded:Wait()
				for _, Part in Object:GetDescendants() do
					if Part:IsA("BasePart") then
						Part.CanCollide = false
						task.spawn(function()
							while Abysall.Environment.isnetworkowner(Part) do
								Part.Position = Vector3.new(math.random(-29999,29999), math.random(-29999,29999), math.random(-29999,29999))
								task.wait()
							end
						end)
					end
				end
			end
		end
	elseif (Name == "ThingToOpen" or Name == "MovingDoor") and (Floor == "Fools" or Floor == "OldHotel")
		or Name == "Wax_Door" and Floor == "Fools"
	then
		Object:SetAttribute("OriginalPosition", Object:GetPivot())
		local ToggleMap = { ThingToOpen = "RemoveBasementGate", MovingDoor = "RemovePaintingsDoor", Wax_Door = "RemoveSkeletonDoor" }
		if ToggleMap[Name] and Toggles[ToggleMap[Name]].Value then
			Object:PivotTo(CFrame.new(-10000, -10000, -10000))
		end
		table.insert(Objects.Obstructions, Object)
	elseif Name == "ElevatorBreaker" then
		if Toggles.AutoBreakerBox.Value and not Globals.BreakerBoxNotified then
			Functions.Notify({ Title = "Interact with the breaker box.", Body = "It will be automatically solved." })
			Globals.BreakerBoxNotified = true
		end
		Connections.BreakerConnection = Object:WaitForChild("SurfaceGui").Frame.Code:GetPropertyChangedSignal("Text"):Connect(function()
			if Toggles.AutoBreakerBox.Value then
				if not Globals.BreakerBoxStartNotified and (Floor == "Fools" or Floor == "OldHotel") then
					Functions.Notify({ Title = "Attempting to solve the breaker box.", Body = "Please wait." })
					Globals.BreakerBoxStartNotified = true
				end
				RemotesFolder.EBF:FireServer()
			end
			Globals.BreakerBoxInteracted = true
		end)
	elseif Name == "ElevatorCar" then
		local ElevConn = Object.DescendantAdded:Connect(function(Desc)
			if Toggles.AutoBreakerBox.Value and Desc.Name == "TouchInterest" and not Globals.BreakerBoxFinishedNotified then
				Functions.Notify({ Title = "Successfully solved the breaker box.", Body = "Try going to the elevator!" })
				Globals.BreakerBoxFinishedNotified = true
			end
		end)
		Object.Destroying:Once(function() ElevConn:Disconnect() end)
	elseif Object.ClassName == "ProximityPrompt" and not Object:GetAttribute("FakePrompt") then
		if Object:HasTag("DisableWhenEnabledOnClient") then Object:RemoveTag("DisableWhenEnabledOnClient") end

		Object:SetAttribute("HoldDuration_Old", Object.HoldDuration)
		Object:SetAttribute("RequiresLineOfSight_Old", Object.RequiresLineOfSight)
		Object:SetAttribute("MaxActivationDistance_Old", Object.MaxActivationDistance)

		if Toggles.InstantPrompts.Value    then Object.HoldDuration = 0 end
		if Toggles.PromptClip.Value        then Object.RequiresLineOfSight = false end
		Object.MaxActivationDistance = Object:GetAttribute("MaxActivationDistance_Old") * Options.PromptReachSlider.Value

		local LockPromptNames = { UnlockPrompt=true, SkullPrompt=true, LockPrompt=true, ThingToEnable=true, FusesPrompt=true }

		if Functions.CheckCompatability({"fireproximityprompt"}) and Floor ~= "OldHotel" and Floor ~= "Fools" then
			local IsLockPrompt = LockPromptNames[Object.Name]
				or (Object.Parent and Object.Parent:GetAttribute("Locked") == true)
				or (Object.Parent and Object.Parent.Parent and Object.Parent.Parent.Name == "Locker_Small_Locked" and Object.Name == "ActivateEventPrompt")

			if IsLockPrompt then
				local FakePrompt = Object:Clone()
				FakePrompt:SetAttribute("FakePrompt", true)
				task.wait()
				FakePrompt.Parent = Object.Parent

				FakePrompt:SetAttribute("HoldDuration_Old", Object:GetAttribute("HoldDuration_Old"))
				FakePrompt:SetAttribute("RequiresLineOfSight_Old", Object:GetAttribute("RequiresLineOfSight_Old"))
				FakePrompt:SetAttribute("MaxActivationDistance_Old", Object:GetAttribute("MaxActivationDistance_Old"))

				FakePrompt.HoldDuration = Object.HoldDuration
				FakePrompt.RequiresLineOfSight = Object.RequiresLineOfSight
				FakePrompt.MaxActivationDistance = Object.MaxActivationDistance

				if Toggles.InstantPrompts.Value    then FakePrompt.HoldDuration = 0 end
				if Toggles.PromptClip.Value        then FakePrompt.RequiresLineOfSight = false end
				FakePrompt.MaxActivationDistance = FakePrompt:GetAttribute("MaxActivationDistance_Old") * Options.PromptReachSlider.Value

				FakePrompts[FakePrompt] = Object
				pcall(function() Object.Parent = Globals.PromptContainer end)

				local FPEnabledConn = Object:GetPropertyChangedSignal("Enabled"):Connect(function()
					FakePrompt.Enabled = Object.Enabled
				end)
				Object:GetPropertyChangedSignal("ActionText"):Once(function()
					Object.Parent = FakePrompt.Parent
					FakePrompt:Destroy()
					FPEnabledConn:Disconnect()
				end)
				Object.Destroying:Once(function()
					FakePrompt:Destroy()
					FPEnabledConn:Disconnect()
				end)
				table.insert(Connections, FPEnabledConn)
				table.insert(Objects.Prompts, FakePrompt)

				FakePrompt.Enabled = false
				task.wait()
				FakePrompt.Enabled = Object.Enabled
			end
		end
		table.insert(Objects.Prompts, Object)
	elseif Name == "Padlock" then
		local PadlockConn = Services.RunService.Heartbeat:Connect(function()
			if Object.PrimaryPart then
				local Distance = LocalPlayer:DistanceFromCharacter(Object.PrimaryPart.Position)
				if Toggles.AutoUnlockPadlockToggle and Toggles.AutoUnlockPadlockToggle.Value then
					local Code = Functions.GetLibraryCode()
					if Code and tonumber(Code) and Distance < (Options.AutoUnlockPadlockSlider and Options.AutoUnlockPadlockSlider.Value or 10) then
						RemotesFolder.PL:FireServer(Code)
					end
				end
				if Toggles.AutoLibraryGuessCode and Toggles.AutoLibraryGuessCode.Value and LatestRoom.Value == 50 then
					local Code = Functions.GetRandomCode()
					if Code then RemotesFolder.PL:FireServer(Code) end
				end
			end
		end)
		table.insert(Connections, PadlockConn)
		Object.Destroying:Once(function()
			PadlockConn:Disconnect()
		end)
	end
end

Connections.PromptAnimationFixer1 = Services.ProximityPromptService.PromptButtonHoldBegan:Connect(function(Object)
	if not Object:GetAttribute("FakePrompt") then return end
	local ToolNames = { "Lockpick","Shears","SkeletonKey","Key","GeneratorFuse","KeyElectrical","KeyBackdoor","KeyIron", "Multitool" }
	local AnimateToolNames = { "Lockpick","Shears","SkeletonKey","Key","KeyElectrical","KeyBackdoor","KeyIron", "Multitool" }
	local Tool
	for _, N in ToolNames do Tool = Character:FindFirstChild(N) if Tool then break end end

	local Prompt = Object
	local LockPromptNames = { UnlockPrompt=true, SkullPrompt=true, LockPrompt=true, ThingToEnable=true, FusesPrompt=true }
	local IsLockPrompt = LockPromptNames[Object.Name]
		or (Object.Parent and Object.Parent:GetAttribute("Locked") == true)
		or (Object.Parent and Object.Parent.Parent and Object.Parent.Parent.Name == "Locker_Small_Locked" and Object.Name == "ActivateEventPrompt")
	if IsLockPrompt then
		if Options.AutoInteractIgnoreList.Value["Locks"] then return end
		local KeyItems = { "Key","GeneratorFuse","KeyBackdoor","KeyElectrical","KeyIron","Lockpick","SkeletonKey","Shears","Multitool" }
		local OffhandKeyItems = { "Key","GeneratorFuse","KeyElectrical","KeyIron" }
		local HasKey = false
		for _, K in KeyItems do if Functions.HasItem(K, true) then HasKey = true break end end
		for _, K in OffhandKeyItems do if Functions.HasItem(K) then HasKey = true break end end
		if not HasKey then return end
	end

	if Prompt.Parent.Name == "CuttableVines" and not Functions.HasItem("Shears", true) and not Functions.HasItem("Multitool", true) or Prompt.Parent.Name == "Chest_Vine" and not Functions.HasItem("Shears", true) and not Functions.HasItem("Multitool", true) or Prompt.Parent.Name == "Cellar" and not Functions.HasItem("Shears", true) and not Functions.HasItem("Multitool", true) then return end
	if Prompt.Parent.Name == "SkullLock" and not Functions.HasItem("SkeletonKey", true) then return end
	if Prompt.Parent.Name == "Lock1" and not Functions.HasItem("Lockpick", true) and not Functions.HasItem("Multitool", true) or Prompt.Parent.Name == "Lock2" and not Functions.HasItem("Lockpick", true) and not Functions.HasItem("Multitool", true) then return end
	if Functions.HasItem("Shears", true) and IsLockPrompt and Prompt.Parent.Name ~= "CuttableVines" and Prompt.Parent.Name ~= "Chest_Vine" and Prompt.Parent.Name ~= "Cellar" then return end
	
	if Tool and table.find(AnimateToolNames, Tool.Name) and Globals.UseAnimation then
		Globals.UseAnimationBreak:Stop()
		Globals.UseAnimation:Stop()
		Globals.UseAnimation:Play()
		if Tool.Name == "Shears" then Tool:WaitForChild("Handle"):WaitForChild("sound_prompt"):Play() end
	end
end)

Globals.ObjectQueue = {}
local AllowedInstances = {
	Lava=true, GoldPile=true, KeyObtain=true, Drakobloxxer=true, FuseObtain=true,
	MinesGenerator=true, JeffTheKiller=true, Snare=true, FakeDoor=true, DoorFake=true, SideroomSpace=true,
	ChestBox=true, ChestBoxLocked=true, Chest_Vine=true, Locker_Small_Locked=true, Toolbox=true,
	Toolbox_Locked=true, Wardrobe=true, ["Wardrobe-FOOLS26"]=true, Toolshed=true, Toolshed_Small=true,
	Bed=true, MinesAnchor=true, Double_Bed=true, RetroWardrobe=true, Backdoor_Wardrobe=true,
	Rooms_Locker=true, Rooms_Locker_Fridge=true, Locker_Large=true, FigureRig=true, FigureRagdoll=true,
	TimerLever=true, Lever=true, Seek_Arm=true, ChandelierObstruction=true, ScaryWall=true, Ladder=true,
	CircularVent=true, Dumpster=true, SquareGrate=true, TriggerEventCollision=true, GrumbleRig=true,
	GiggleCeiling=true, MinesGateButton=true, ElectricalKeyObtain=true, LibraryHintPaper=true,
	WaterPump=true, CringlePresent=true, Wheel=true, PickupItem=true, LiveHintBook=true,
	LiveBreakerPolePickup=true, LeverForGate=true, GloomPile=true, SeekFloodline=true, Door=true,
	Green_Herb=true, Bridge=true, MouseHole=true, BananaPeel=true, NannerPeel=true, PowerupPad=true,
	IndustrialGate=true, CollisionFloor=true, ElevatorCar=true, Wax_Door=true, ThingToOpen=true,
	MovingDoor=true, StardustPickup=true, Hole=true, Groundskeeper=true, MandrakeLive=true,
	GardenGateButton=true, LotusPetalPickup=true, VineGuillotine=true, LiveEntityBramble=true, ArchivesFihTank=true,
	RiftSpawn=true, ElevatorBreaker=true, RunnerNodes=true, PathLights=true, DuckBoard=true,
	Padlock=true, EyestalkEndCutscene=true, MinecartRig=true, SeekMovingNewClone=true, Cellar=true, ArchivesPackageDeposit=true, StairwellScrapper=true,
	StairwellFireAlarm=true, ShoppingCart=true, Mirror=true, StairwellLockpickDoor=true
}

Functions.QueueObject = function(Object)
	if TimeShowerClone and Object:IsDescendantOf(TimeShowerClone) then
		return
	end
	local IsHidingSpot = typeof(Object.Name) == "string" and string.find(string.lower(Object.Name), "hidingspot")
	if not AllowedInstances[Object.Name] and not IsHidingSpot and Object.ClassName ~= "ProximityPrompt" and Object.Parent ~= CurrentRooms and not ItemNames[Object.Name] then
		return
	end
	table.insert(Globals.ObjectQueue, Object)
end

Globals.QueueDone = true
Connections.QueueConnection = Services.RunService.Heartbeat:Connect(function()
	-- Извлечение с конца таблицы O(1) исключает сдвиг массива и микрофризы
	for _ = 1, 20 do
		local Object = table.remove(Globals.ObjectQueue)
		if not Object then break end
		if Object.Parent then
			pcall(Functions.HandleObject, Object)
		end
	end
end)

for _, Object in ipairs(Services.Workspace:GetDescendants()) do
	Functions.QueueObject(Object)
end

-- Отсеиваем визуальный мусор прямо на входе, не перегружая память
local IgnoredClasses = {
	Part = false, Model = false, ProximityPrompt = false,
	ParticleEmitter = true, Attachment = true, Beam = true,
	Trail = true, Decal = true, Texture = true, Sound = true,
	Weld = true, Motor6D = true, WeldConstraint = true, Highlight = true
}

Connections.InstanceHandler = Services.Workspace.DescendantAdded:Connect(function(Object)
	local name = Object.Name
	local isTV = name == "TV_Stand" or name == "Noise_TV" or name == "NoiseTV"
	local isNoise = not isTV and (name == "Noise" or name == "NoiseModel" or (typeof(name) == "string" and string.find(name, "Noise") ~= nil and not string.find(name, "TV")))

	if isTV or isNoise or Entities[name] then
		-- Игнорируем предметы в руках, аксессуары и вьюмоделы в камере
		local isToolOrAcc = Object:FindFirstAncestorWhichIsA("Tool") or Object:FindFirstAncestorWhichIsA("Accessory") or Object:FindFirstAncestorWhichIsA("Accoutrement")
		if not isToolOrAcc then
			local activeCam = Services.Workspace.CurrentCamera or Camera
			local inCam = activeCam and Object:IsDescendantOf(activeCam)
			if not inCam or isNoise then
				if name == "Eyes" or name == "Lookman" or name == "BackdoorLookman" then
					if Object:IsA("Model") and Functions.IsValidEyes(Object) then
						task.spawn(Functions.HandleEntitySpawn, Object)
					end
				else
					local isInsideTV = not isTV and (Object:FindFirstAncestor("TV_Stand") or Object:FindFirstAncestor("Noise_TV"))
					if not isInsideTV and Functions.HandleEntitySpawn then
						task.spawn(Functions.HandleEntitySpawn, Object)
					end
				end
			end
		end
	end
	if IgnoredClasses[Object.ClassName] then return end
	Functions.QueueObject(Object)
end)

for _, Player in Services.Players:GetPlayers() do
	if Player ~= LocalPlayer then
		if Player.Character and Toggles.PlayerESPToggle.Value then
			Functions.AddESP({ Object = Player.Character, Text = Player.Name, Color = Options.PlayerESPColor.Value })
		end
		local CharConn = Player.CharacterAdded:Connect(function(NewCharacter)
			if Toggles.PlayerESPToggle.Value then
				Functions.AddESP({ Object = NewCharacter, Text = Player.Name, Color = Options.PlayerESPColor.Value })
			end
		end)
		local DeadConn = Player:GetAttributeChangedSignal("Alive"):Connect(function()
			if Player:GetAttribute("Alive") ~= true and Player.Character then
				Functions.RemoveESP(Player.Character)
			end
		end)
		table.insert(Connections, CharConn)
		table.insert(Connections, DeadConn)
		Player.Destroying:Once(function()
			CharConn:Disconnect()
			DeadConn:Disconnect()
		end)
	end
end

Connections.PlayerHandler = Services.Players.PlayerAdded:Connect(function(Player)
	if Player == LocalPlayer then return end
	if Player.Character and Toggles.PlayerESPToggle.Value then
		Functions.AddESP({ Object = Player.Character, Text = Player.Name, Color = Options.PlayerESPColor.Value })
	end
	local CharConn = Player.CharacterAdded:Connect(function(NewCharacter)
		if Toggles.PlayerESPToggle.Value then
			Functions.AddESP({ Object = NewCharacter, Text = Player.Name, Color = Options.PlayerESPColor.Value })
		end
	end)
	local DeadConn = Player:GetAttributeChangedSignal("Alive"):Connect(function()
		if Player:GetAttribute("Alive") ~= true and Player.Character then
			Functions.RemoveESP(Player.Character)
		end
	end)
	table.insert(Connections, CharConn)
	table.insert(Connections, DeadConn)
	Player.Destroying:Once(function()
		CharConn:Disconnect()
		DeadConn:Disconnect()
	end)
end)

Functions.FirePrompt      = Abysall.Environment.fireproximityprompt
Functions.ForceFirePrompt = Abysall.Environment.fireproximityprompt

if not Functions.FirePrompt then
	local PromptsToFire = {}
	local PromptCooldown = {}
	Functions.FirePrompt = function(Prompt)
		if not Prompt:IsA("ProximityPrompt") or PromptCooldown[Prompt] or table.find(PromptsToFire, Prompt) or not Camera then return end
		table.insert(PromptsToFire, Prompt)
	end
	Functions.ForceFirePrompt = Functions.FirePrompt

	task.spawn(function()
		while task.wait() do
			local Prompt = table.remove(PromptsToFire, 1)
			if not Prompt then continue end
			PromptCooldown[Prompt] = true

			local OldDist   = Prompt.MaxActivationDistance
			local OldEnable = Prompt.Enabled
			local OldParent = Prompt.Parent
			local OldHold   = Prompt.HoldDuration
			local OldLOS    = Prompt.RequiresLineOfSight

			Prompt.MaxActivationDistance = 99999
			Prompt.Enabled = true
			Prompt.HoldDuration = 0
			Prompt.RequiresLineOfSight = false

			local TempPart = Instance.new("Part")
			TempPart.Parent = Services.Workspace
			TempPart.CanCollide = false TempPart.CanQuery = false TempPart.CanTouch = false
			TempPart.Anchored = true TempPart.Transparency = 1
			TempPart.Size = Vector3.new(0.001, 0.001, 0.001)
			TempPart.Position = Camera.CFrame:ToWorldSpace(CFrame.new(0, 0, -0.1)).Position

			if not Prompt or not OldParent then
				TempPart:Destroy()
				PromptCooldown[Prompt] = nil
				continue
			end

			pcall(function() Prompt.Parent = TempPart end)

			local Shown, Fired = false, false

			local ShownConn = Services.ProximityPromptService.PromptShown:Connect(function(P)
				if P == Prompt then Shown = true end
			end)
			local FiredConn = Prompt.Triggered:Connect(function() Fired = true end)

			local T1 = 0
			while not Shown and T1 < 5 do T1 += 1 task.wait() end

			local T2 = 0
			while not Fired and T2 < 5 do
				Prompt:InputHoldBegin()
				Prompt:InputHoldEnd()
				T2 += 1 task.wait()
			end

			Prompt.MaxActivationDistance = OldDist
			Prompt.Enabled = OldEnable
			Prompt.HoldDuration = OldHold
			Prompt.RequiresLineOfSight = OldLOS
			pcall(function() Prompt.Parent = OldParent end)
			task.wait()
			PromptCooldown[Prompt] = nil
			TempPart:Destroy()
			ShownConn:Disconnect()
			FiredConn:Disconnect()
		end
	end)
end

local AutoInteractBlacklist = {
	HidePrompt=true, RiftPrompt=true, StarRiftPrompt=true, InteractPrompt=true, ClimbPrompt=true,
	DonatePrompt=true, DialoguePrompt=true, RevivePrompt=true, EnterPrompt=true, AnimatePrompt=true,
	ToolEventPrompt=true, Prompt=true, PropPrompt=true
}

local TriggerDebounce = false

local function GetHidingSpotModel(Prompt)
	if not Prompt or not Prompt.Parent then return false end
	local Model = Prompt.Parent
	while Model and not Model:IsA("Model") do
		Model = Model.Parent
	end
	if not Model then return nil end

	local Name = string.lower(Model.Name)
	if not string.find(Name, "hidingspot") and not string.find(Name, "hiding_spot") then
		return nil
	end
	return Model
end

local function HasHidePrompt(Model)
	return Model and (Model:FindFirstChild("HidePrompt") or Model:FindFirstChild("HidingPrompt")) ~= nil
end

local function IsHidingSpotPrompt(Prompt)
	if not Prompt or not Prompt.Parent then return false end
	if Prompt.Name ~= "HidePrompt" and Prompt.Name ~= "HidingPrompt" then return false end
	return HasHidePrompt(GetHidingSpotModel(Prompt))
end

Functions.TriggerPrompt = function(Prompt)
	if not Prompt or not Prompt.Parent then return end
	if Character:GetAttribute("Hiding") == true then return end
	local HidingSpot = GetHidingSpotModel(Prompt)
	if HidingSpot and Prompt.Name ~= "InteractPrompt" then return end
	local IsHidingSpotInteractPrompt = HidingSpot and Prompt.Name == "InteractPrompt"
	if AutoInteractBlacklist[Prompt.Name] and not IsHidingSpotPrompt(Prompt) and not IsHidingSpotInteractPrompt then return end
	if (Prompt.Name == "HidePrompt" or Prompt.Name == "HidingPrompt") and not IsHidingSpotPrompt(Prompt) then return end
	if (Prompt.Name == "HidePrompt" or Prompt.Name == "HidingPrompt" or IsHidingSpotPrompt(Prompt)) then
		if not Toggles.AutoClosetToggle.Value then return end
		local Entity = Functions.GetNearestEntity(true, Options.AutoClosetEntityList.Value)
		if not Entity then return end
		local EntityDistance = LocalPlayer:DistanceFromCharacter(Entity.PrimaryPart.Position)
		if EntityDistance > (EntityDistances[Entity.Name] or 150) then return end
	end
	if TriggerDebounce then return end

	local ParentItem = Functions.HasItem(Prompt.Parent.Name)
	if ParentItem and ParentItem:GetAttribute("Durability") and ParentItem:GetAttribute("DurabilityMax")
		and ParentItem:GetAttribute("Durability") >= ParentItem:GetAttribute("DurabilityMax")
	then return end

	local LockPromptNames = { UnlockPrompt=true, SkullPrompt=true, LockPrompt=true, ThingToEnable=true, FusesPrompt=true }
	local IsLockPrompt = LockPromptNames[Prompt.Name]
		or (Prompt.Parent and Prompt.Parent:GetAttribute("Locked") == true)
		or (Prompt.Parent and Prompt.Parent.Parent and Prompt.Parent.Parent.Name == "Locker_Small_Locked" and Prompt.Name == "ActivateEventPrompt")

	if IsLockPrompt then
		if Options.AutoInteractIgnoreList.Value["Locks"] then return end
		local KeyItems = { "Key","GeneratorFuse","KeyBackdoor","KeyElectrical","KeyIron","Lockpick","SkeletonKey","Shears","Multitool" }
		local OffhandKeyItems = { "Key","GeneratorFuse","KeyElectrical","KeyIron" }
		local HasKey = false
		for _, K in KeyItems do if Functions.HasItem(K, true) then HasKey = true break end end
		for _, K in OffhandKeyItems do if Functions.HasItem(K) then HasKey = true break end end
		if not HasKey then return end
	end

	if Prompt.Parent.Name == "CuttableVines" and not Functions.HasItem("Shears", true) and not Functions.HasItem("Multitool", true) or Prompt.Parent.Name == "Chest_Vine" and not Functions.HasItem("Shears", true) and not Functions.HasItem("Multitool", true) or Prompt.Parent.Name == "Cellar" and not Functions.HasItem("Shears", true) and not Functions.HasItem("Multitool", true) then return end
	if Prompt.Parent.Name == "SkullLock" and not Functions.HasItem("SkeletonKey", true) then return end
	if Prompt.Parent.Name == "Lock1" and not Functions.HasItem("Lockpick", true) and not Functions.HasItem("Multitool", true) or Prompt.Parent.Name == "Lock2" and not Functions.HasItem("Lockpick", true) and not Functions.HasItem("Multitool", true) then return end
	if Functions.HasItem("Shears", true) and IsLockPrompt and Prompt.Parent.Name ~= "CuttableVines" and Prompt.Parent.Name ~= "Chest_Vine" and Prompt.Parent.Name ~= "Cellar" then return end

	if Prompt.Parent.Name == "GlitchCube" and Options.AutoInteractIgnoreList.Value["Glitch Fragments"] then return end

	if (Prompt.Parent.Name == "KeyObtain" and (Functions.HasItem("Key") or Functions.HasItem("KeyBackdoor")))
		or (Prompt.Parent.Name == "ElectricalKeyObtain" and Functions.HasItem("KeyElectrical"))
	then return end

	if Prompt:IsDescendantOf(Drops) and Options.AutoInteractIgnoreList.Value["Dropped Items"] then return end
	if Prompt.Parent.Name == "TrackLever" then return end
	if Prompt.Name == "ActivateEventPrompt" and (Prompt.ActionText == "Close"
		or Prompt.Parent.Name == "ElevatorBreaker"
		or (Prompt.Parent.Parent and Prompt.Parent.Parent.Name == "IndustrialGate"))
	then return end
	if Prompt.Name == "ActivateEventPrompt" and (Prompt.Parent.Name == "Padlock" or Prompt.Parent.Name == "MinesAnchor") then return end
	if Prompt.Parent.Name == "LeverForGate" and Prompt:GetAttribute("Interactions") then return end
	if Prompt.Parent.Parent and (Prompt.Parent.Parent.Name == "DoorFake" or Prompt.Parent.Parent.Name == "FakeDoor") then return end
	if Prompt.Parent:GetAttribute("JeffShop") and Options.AutoInteractIgnoreList.Value["Jeff Items"] then return end
	if Prompt:GetAttribute("AutoInteractIgnore") then return end
	if Prompt.Name == "PushPrompt" and Options.AutoInteractIgnoreList.Value["Minecarts"] then return end
	if (Prompt.Parent.Name == "GoldPile" or Prompt.Parent.Name == "StardustPickup") and Options.AutoInteractIgnoreList.Value["Currency"] then return end

	if Prompt.Parent.Name == "Bandage" then
		local BPack = Functions.HasItem("BandagePack")
		if Humanoid.Health >= Humanoid.MaxHealth and not BPack then return end
		if BPack and BPack:GetAttribute("Durability") >= BPack:GetAttribute("DurabilityMax") then return end
	end

	if Prompt.Parent.Name == "Battery" then
		local Tool = Character:FindFirstChildOfClass("Tool")
		local BPack = Functions.HasItem("BatteryPack")
		if not Tool and not BPack then return end
		if Tool and Tool:GetAttribute("LightSource") then
			if Tool:GetAttribute("Durability") and Tool:GetAttribute("DurabilityMax")
				and Tool:GetAttribute("Durability") > Tool:GetAttribute("DurabilityMax")
			then return end
		elseif not BPack then
			return
		end
		if BPack and BPack:GetAttribute("Durability") >= BPack:GetAttribute("DurabilityMax") then return end
	end

	if Prompt.Name == "HerbPrompt" then
		local Effects = Globals.MainUI.MainFrame.Healthbar:FindFirstChild("Effects")
		if Effects and Effects.HerbGreenEffect.Visible then return end
	end

	if (Prompt.Parent.Name == "LibraryHintPaper" or Prompt.Parent.Name == "PickupItem") and (Functions.HasItem("LibraryHintPaper") or Functions.HasItem("LibraryHintPaperHard")) then return end
	if Prompt.Parent.Name == "AlarmClock" and Functions.HasItem("AlarmClock") then return end
	if Prompt.Parent.Name == "KeyObtainFake" or Prompt.Parent.Name == "TithingPlate" then return end
	if Prompt.Parent.Name == "StarBottle" then return end
    -- archives
	local p1 = Prompt.Parent
	local p2 = p1 and p1.Parent

	if p1 and p1.Name == "ArchivesStorageBox" then return end
	if p1 and p1.Name == "Briefcase" then return end
	if Prompt.Name == "SinkPrompt" or (p1 and p1.Name == "Faucet") then return end
	if p1 and (p1.Name == "PaperPlanePickup" or p1.Name == "PaperPlane") then return end
	if Prompt.Name == "ManualOpenPrompt" or Prompt.Name == "EntryPrompt" then return end
	if p2 and p2.Name == "ArchivesLargePrinter" then return end
	if Prompt.Name == "TrashcanPrompt" then return end
	if p1 and p1.Name == "Keyboard" then return end
	if Prompt.Name == "CartPrompt" or (p2 and p2.Name == "ArchivesOfficeChair") then return end
	if p1 and p1.Name == "ArchivesTerminal" then return end
	if Prompt.Name == "VendorPrompt" then return end
	if p1 and (p1.Name == "SeatPart" or Prompt.Name == "SeatPrompt") then return end

	-- Stairwell
	if p1 and p1.Name == "StairwellScrapper" then return end
	if Prompt.Name == "PortraitDupePrompt" or (p1 and p1.Name == "MirrorTool") then return end
	if Prompt.Name == "LaptopPrompt" or (p1 and p1.Name == "SecretLaptop") then return end
	if p1 and p1.Name == "StairwellFireAlarm" or (p2 and p2.Name == "StairwellFireAlarm") then return end
	if p1 and p1.Name == "CobblerFriendly" then return end
	if p1 and p1.Name == "StairwellTerminal" then return end
	if p2 and p2.Name == "MeldChord" then return end

	Functions.FirePrompt(Prompt)
	TriggerDebounce = true
	if Floor == "OldHotel" then task.wait() end
	TriggerDebounce = false
end

Globals.LastAutoInteractFire = tick()
Connections.AutoInteract = Services.RunService.Heartbeat:Connect(function()
	local Active = Toggles.AutoInteractToggle.Value or Options.AutoInteractKeybind:GetState()
    if not Active then return end
    if tick() - Globals.LastAutoInteractFire < 0.07 then return end

	for _, Prompt in Objects.Prompts do
        if Prompt:GetAttribute("ParentRoom") and tonumber(Prompt:GetAttribute("ParentRoom")) ~= tonumber(LocalPlayer:GetAttribute("CurrentRoom")) then continue end

		if Prompt.Parent and (Prompt.Parent:IsA("BasePart") or Prompt.Parent:IsA("Model")) then
			local Distance
			if Prompt.Parent:IsA("BasePart") then
				Distance = LocalPlayer:DistanceFromCharacter(Prompt.Parent.Position)
			else
				Distance = LocalPlayer:DistanceFromCharacter(Prompt.Parent:GetPivot().Position)
			end
			if Distance <= Prompt.MaxActivationDistance and Prompt.Enabled or Distance <= Prompt.MaxActivationDistance and Prompt.Name == "LongPushPrompt" or Distance <= Prompt.MaxActivationDistance and Prompt.Name == "BigPropPrompt" then
				task.spawn(Functions.TriggerPrompt, Prompt)
			end
		end
	end
    Globals.LastAutoInteractFire = tick()
end)

Connections.InfiniteItemsHandler = Services.ProximityPromptService.PromptTriggered:Connect(function(Object)
	if not Object:GetAttribute("FakePrompt") then return end

	local ToolNames = { "Lockpick","Shears","SkeletonKey","Key","GeneratorFuse","KeyElectrical","KeyBackdoor","KeyIron", "Multitool" }
	local AnimateToolNames = { "Lockpick","Shears","SkeletonKey","Key","KeyElectrical","KeyBackdoor","KeyIron", "Multitool" }
	local Tool
	for _, N in ToolNames do Tool = Character:FindFirstChild(N) if Tool then break end end

	local Prompt = Object
	local LockPromptNames = { UnlockPrompt=true, SkullPrompt=true, LockPrompt=true, ThingToEnable=true, FusesPrompt=true }
	local IsLockPrompt = LockPromptNames[Object.Name]
		or (Object.Parent and Object.Parent:GetAttribute("Locked") == true)
		or (Object.Parent and Object.Parent.Parent and Object.Parent.Parent.Name == "Locker_Small_Locked" and Object.Name == "ActivateEventPrompt")
	if IsLockPrompt then
		if Options.AutoInteractIgnoreList.Value["Locks"] then return end
		local KeyItems = { "Key","GeneratorFuse","KeyBackdoor","KeyElectrical","KeyIron","Lockpick","SkeletonKey","Shears","Multitool" }
		local OffhandKeyItems = { "Key","GeneratorFuse","KeyElectrical","KeyIron" }
		local HasKey = false
		for _, K in KeyItems do if Functions.HasItem(K, true) then HasKey = true break end end
		for _, K in OffhandKeyItems do if Functions.HasItem(K) then HasKey = true break end end
		if not HasKey then return end
	end

	if Prompt.Parent.Name == "CuttableVines" and not Functions.HasItem("Shears", true) and not Functions.HasItem("Multitool", true) or Prompt.Parent.Name == "Chest_Vine" and not Functions.HasItem("Shears", true) and not Functions.HasItem("Multitool", true) or Prompt.Parent.Name == "Cellar" and not Functions.HasItem("Shears", true) and not Functions.HasItem("Multitool", true) then return end
	if Prompt.Parent.Name == "SkullLock" and not Functions.HasItem("SkeletonKey", true) then return end
	if Prompt.Parent.Name == "Lock1" and not Functions.HasItem("Lockpick", true) and not Functions.HasItem("Multitool", true) or Prompt.Parent.Name == "Lock2" and not Functions.HasItem("Lockpick", true) and not Functions.HasItem("Multitool", true) then return end
	if Functions.HasItem("Shears", true) and IsLockPrompt and Prompt.Parent.Name ~= "CuttableVines" and Prompt.Parent.Name ~= "Chest_Vine" and Prompt.Parent.Name ~= "Cellar" then return end

	if Tool and table.find(AnimateToolNames, Tool.Name) and Globals.UseAnimation and Globals.UseAnimationBreak then
		Globals.UseAnimation:Stop()
		Globals.UseAnimationBreak:Stop()
		Globals.UseAnimationBreak:Play()
		if Tool.Name == "Shears" then Tool:WaitForChild("Handle"):WaitForChild("sound_prompt"):Play() end
	end

	local AnyTool = Character:FindFirstChildOfClass("Tool")
	local ToolData = AnyTool and ItemNames[AnyTool.Name]
	if AnyTool and ToolData and Toggles.InfiniteItemsToggle.Value and Options.InfiniteItemsList.Value[ToolData] then
				local RealPrompt = FakePrompts[Object]
		local Handled = false
		local DropConn
		DropConn = Drops.ChildAdded:Connect(function(NewTool)
			if Handled then return end
			Handled = true
			DropConn:Disconnect()

			-- подбор предмета: стреляем сразу и повторяем каждый кадр, пока он не поднят
			task.spawn(function()
				local Pickup = NewTool:FindFirstChild("ModulePrompt") or NewTool:WaitForChild("ModulePrompt", 1)
				if not Pickup then return end
				for _ = 1, 15 do
					if NewTool.Parent ~= Drops then break end
					Functions.FirePrompt(Pickup)
					task.wait()
				end
			end)

			-- настоящий промпт в том же кадре, без ожиданий
			Functions.FirePrompt(RealPrompt)
		end)
		task.delay(3, function()
			if DropConn then DropConn:Disconnect() end
		end)
		Character.ChildAdded:Once(function(NewTool)
			if NewTool.Name == "Shears" then NewTool:WaitForChild("Handle"):WaitForChild("sound_promptend"):Play() end
		end)
		RemotesFolder.DropItem:FireServer(AnyTool)
	else
		local RealPrompt = FakePrompts[Object]
		Functions.FirePrompt(RealPrompt)
	end
end)

Connections.FloorReplicatedHandler = FloorReplicated.DescendantAdded:Connect(function(Object)
	if Object.Name == "GlitchScreech" then
		Modules.GlitchScreech = Object
		if Toggles.RemoveScreech.Value then Object.Name = "GlitchScreech_Disabled" end
	end
	if Object.Name:lower():find("spider") or Object.Name:lower():find("timothy") then
		if Functions.ApplyDisableTimothyJumpscare and Toggles.DisableTimothyJumpscare and Toggles.DisableTimothyJumpscare.Value then
			Functions.ApplyDisableTimothyJumpscare(true)
		end
	end
	if Object.Name:find("Jumpscare") and Object:IsA("ModuleScript")
		and not Object.Name:find("Eyestalk") and not Object.Name:find("Groundskeeper") and not Object.Name:find("Monument")
	then
		Object:SetAttribute("OriginalName", Object.Name)
		if Toggles.DisableEntityJumpscares.Value then Object.Name = Object.Name .. "_Disabled" end
		table.insert(Objects.JumpscareModules, Object)
	end
end)

if FloorReplicated:FindFirstChild("DigitalTimer") then
	Connections.HasteTimerConnection = FloorReplicated.DigitalTimer:GetPropertyChangedSignal("Value"):Connect(function()
		if Toggles.NotifyHasteTime.Value then Functions.Caption(Functions.GetHasteTime(), true) end
	end)
end

Connections.FogHandler = Services.Lighting:GetPropertyChangedSignal("FogEnd"):Connect(function()
	if Services.Lighting.FogEnd ~= 10000000 then
		Globals.OldFog = Services.Lighting.FogEnd
	end
	if Toggles.RemoveCameraFog.Value then
		Services.Lighting.FogEnd = 10000000
	end
end)

Connections.FogHandler2 = Services.Lighting.DescendantAdded:Connect(function(Object)
	if not Object:IsA("Atmosphere") then return end
	Object:SetAttribute("Density_Old", Object.Density)
	if Toggles.RemoveCameraFog.Value then Object.Density = 0 end

	local AtmoConn2 = Object:GetPropertyChangedSignal("Density"):Connect(function()
		if Object.Density ~= 0 then Object:SetAttribute("Density_Old", Object.Density) end
		if Toggles.RemoveCameraFog.Value then Object.Density = 0 end
	end)
	Object.Destroying:Once(function() AtmoConn2:Disconnect() end)
	table.insert(Connections, AtmoConn2)
	table.insert(Globals.FogInstances, Object)
end)

local RusherAliases = { Rush=true, Bash=true, Scribbles=true, DronesStampede=true, Ambush=true, Eyes=true, Lookman=true, Blitz=true, ["A-60"]=true, ["A-120"]=true, AR0xMBUSH=true, ["RNIUSHCG=="]=true, ["Custom Entity"]=true }

Functions.HandleEntitySpawn = function(Entity)
	if not Entity or typeof(Entity) ~= "Instance" then return end

	local Model = Entity
	if Entity:IsA("Humanoid") then
		Model = Entity.Parent
	end
	if not Model or (not Model:IsA("Model") and not Model:IsA("Folder") and not Model:IsA("BasePart")) then return end

	-- Исключаем любые предметы в руках, тулы и аксессуары
	if Model:FindFirstAncestorWhichIsA("Tool") or Model:IsA("Tool") then return end
	if Model:FindFirstAncestorWhichIsA("Accessory") or Model:IsA("Accessory")
		or Model:FindFirstAncestorWhichIsA("Accoutrement") or Model:IsA("Accoutrement") then return end

	-- Исключаем любые части персонажей игроков
	for _, p in ipairs(Services.Players:GetPlayers()) do
		local ch = p.Character
		if ch and (Model == ch or Model:IsDescendantOf(ch)) then
			return
		end
	end

	-- В камере разрешен только Noise
	local camCheck = Services.Workspace.CurrentCamera or Camera or Services.Workspace:FindFirstChild("Camera")
	local isNoiseCheck = (Model.Name == "Noise" or Model.Name == "NoiseModel" or (typeof(Model.Name) == "string" and string.find(Model.Name, "Noise") ~= nil and not string.find(Model.Name, "TV")))
	if camCheck and Model:IsDescendantOf(camCheck) and not isNoiseCheck then
		return
	end

	-- Исключаем мух, мошек и части Gloombats
	local cur = Model.Parent
	while cur and cur ~= Services.Workspace and cur ~= game do
		local cname = string.lower(cur.Name)
		if string.find(cname, "fly") or string.find(cname, "flies") or string.find(cname, "swarm")
			or string.find(cname, "gloombat") or string.find(cname, "gloom") or string.find(cname, "bat")
			or string.find(cname, "bug") or string.find(cname, "insect") then
			if Model.Name ~= "GloombatSwarm" then
				return
			end
		end
		cur = cur.Parent
	end

	-- Для Eyes и Lookman: обязательная строгая валидация (только настоящая модель монстра)
	if (Model.Name == "Eyes" or Model.Name == "Lookman" or Model.Name == "BackdoorLookman") then
		if not Functions.IsValidEyes(Model) then
			return
		end
	end

	-- Если объект находится внутри TV_Stand (или сам является TV_Stand), находим корневой TV_Stand
	local topTV = nil
	if Model.Name == "TV_Stand" or Model.Name == "Noise_TV" or Model.Name == "NoiseTV" then
		topTV = Model
	else
		topTV = Model:FindFirstAncestor("TV_Stand") or Model:FindFirstAncestor("Noise_TV")
	end

	if topTV then
		Model = topTV
		if Model:GetAttribute("Abysall_TV_Handled") then return end
		Model:SetAttribute("Abysall_TV_Handled", true)
		Model:SetAttribute("Abysall_EntityHandled", true)
	else
		if Model:GetAttribute("Abysall_EntityHandled") then return end
		Model:SetAttribute("Abysall_EntityHandled", true)
	end

	local EntityData = nil
	if topTV then
		EntityData = Entities["TV_Stand"] or Entities["Noise_TV"]
	else
		EntityData = Entities[Model.Name]
		if not EntityData then
			local name = Model.Name
			if name == "Noise" or name == "NoiseModel" or (typeof(name) == "string" and string.find(name, "Noise") ~= nil and not string.find(name, "TV")) then
				EntityData = Entities["NoiseModel"] or Entities["Noise"]
			end
			if not EntityData then return end
		end
	end

	local isTV = (topTV ~= nil)
	local isNoise = not isTV and (Model.Name == "Noise" or Model.Name == "NoiseModel" or (typeof(Model.Name) == "string" and string.find(Model.Name, "Noise") ~= nil) or (EntityData and EntityData.Alias == "Noise"))
	local currentActiveCam = Services.Workspace.CurrentCamera or Camera or Services.Workspace:FindFirstChild("Camera")
	local isCameraChild = currentActiveCam and Model:IsDescendantOf(currentActiveCam)

	-- Для Noise / NoiseModel или объектов в Camera немедленно форсируем 100% видимость
	if isNoise or isCameraChild then
		local function ForcePartVisible(Part)
			if Part:IsA("BasePart") and Part.Name ~= "HumanoidRootPart" then
				Part.Transparency = 0
				Part.LocalTransparencyModifier = 0
				Part.CastShadow = true

				local c1 = Part:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
					if Part.LocalTransparencyModifier > 0 then
						Part.LocalTransparencyModifier = 0
					end
				end)
				local c2 = Part:GetPropertyChangedSignal("Transparency"):Connect(function()
					if Part.Transparency > 0 then
						Part.Transparency = 0
					end
				end)
				Part.Destroying:Once(function()
					c1:Disconnect()
					c2:Disconnect()
				end)
			elseif Part:IsA("Decal") or Part:IsA("Texture") then
				Part.Transparency = 0
				local c = Part:GetPropertyChangedSignal("Transparency"):Connect(function()
					if Part.Transparency > 0 then
						Part.Transparency = 0
					end
				end)
				Part.Destroying:Once(function()
					c:Disconnect()
				end)
			end
		end

		if Model:IsA("BasePart") then
			ForcePartVisible(Model)
		end
		for _, Part in ipairs(Model:GetDescendants()) do
			ForcePartVisible(Part)
		end
		Model.DescendantAdded:Connect(function(Part)
			ForcePartVisible(Part)
		end)
	end

	-- Безопасный поиск PrimaryPart с поддержкой BasePart, Model и Folder
	local primaryPart = nil
	if Model:IsA("BasePart") then
		primaryPart = Model
	elseif Model:IsA("Model") then
		primaryPart = Model.PrimaryPart
		if not primaryPart then
			local startWait = tick()
			while not Model.PrimaryPart and (tick() - startWait < 2) do
				for _, Child in ipairs(Model:GetChildren()) do
					if Child:IsA("BasePart") then
						Model.PrimaryPart = Child
						primaryPart = Child
						break
					end
				end
				if not Model.PrimaryPart then
					local anyPart = Model:FindFirstChildWhichIsA("BasePart", true)
					if anyPart then
						Model.PrimaryPart = anyPart
						primaryPart = anyPart
						break
					end
					task.wait(0.05)
				end
			end
			primaryPart = Model.PrimaryPart or Model:FindFirstChildWhichIsA("BasePart", true)
		end
	elseif Model:IsA("Folder") then
		primaryPart = Model:FindFirstChildWhichIsA("BasePart", true)
	end

	if not isNoise and not isTV and not isCameraChild then
		if not primaryPart or LocalPlayer:DistanceFromCharacter(primaryPart.Position) >= 10000 then return end
	end

	local Alias = EntityData.Alias
	local RealAlias = Alias
	if Options.EntityList.Value[Alias] and Toggles.NotifyEntities.Value then
		local NotifyTitle = EntityData.NotifyMessage.Title
		local NotifyBody  = EntityData.NotifyMessage.Body
		local NotifyImage = EntityIcons[Model.Name] or EntityIcons[Alias]

		if Model.Name == "RushMoving" and primaryPart and primaryPart.Name ~= "RushNew" then
			NotifyTitle = NotifyTitle:gsub("Rush", primaryPart.Name)
			local att = primaryPart:WaitForChild("Attachment", 2)
			if att and att:FindFirstChild("ParticleEmitter") then
				NotifyImage = att.ParticleEmitter.Texture
			end
			Alias = primaryPart.Name
		end

		Functions.Notify({ Title = NotifyTitle, Body = NotifyBody, Image = NotifyImage, Time = Toggles.NotifyKeepNotifications.Value and Model or nil })

		if Toggles.EntityChatToggle.Value then
			Functions.SendChat(Alias .. " " .. Options.EntityChatMessage.Value)
		end
	end

	if isTV then
		-- Подсвечиваем саму модель TV_Stand целиком, чтобы весь телевизор нойса подсвечивался полностью
		local espTarget = (Model:IsA("Model") and Model) or primaryPart or Model
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Noise_TV"] then
			Functions.AddESP({ Object = espTarget, Text = "Noise_TV", Color = Options.EntityESPColor.Value })
		end
		table.insert(Objects.Entities, espTarget)
	elseif Model.Name ~= "GloombatSwarm" then
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value[RealAlias] then
			local espTarget = (Model:IsA("Model") and Model) or primaryPart or Model
			if Model.Name == "MonumentEntity" and Model:FindFirstChild("Top") then
				espTarget = Model.Top
			end
			Functions.AddESP({ Object = espTarget, Text = Alias, Color = Options.EntityESPColor.Value })
		end
		table.insert(Objects.Entities, Model)
	end

	if RusherAliases[EntityData.Alias] then
		Instance.new("Humanoid", Model).Name = "HighlightHumanoid"
		local Root = Model:IsA("Model") and Model.PrimaryPart or primaryPart
		if Root then Root.Transparency = 0.999 Root.Material = Enum.Material.Plastic end
	end

	if Model.Name == "Lookman" then
		CurrentRooms.ChildAdded:Wait()
		task.wait(10)
		Model:Destroy()
	end
end

local function HandleEntitySpawn(Entity)
	return Functions.HandleEntitySpawn(Entity)
end

Functions.HookCamera = function(cam)
	if not cam then return end
	if Connections.CameraEntityHandler then
		Connections.CameraEntityHandler:Disconnect()
		Connections.CameraEntityHandler = nil
	end
	if Connections.CameraDescendantHandler then
		Connections.CameraDescendantHandler:Disconnect()
		Connections.CameraDescendantHandler = nil
	end

	local function CheckCamEntity(child)
		if not child or not child.Parent then return end
		local cname = child.Name
		local isNoise = cname == "Noise" or cname == "NoiseModel" or (typeof(cname) == "string" and string.find(cname, "Noise") ~= nil and not string.find(cname, "TV"))
		if isNoise then
			task.spawn(Functions.HandleEntitySpawn, child)
		end
		local isSpider = typeof(cname) == "string" and (cname:lower():find("spider") ~= nil or cname:lower():find("timothy") ~= nil)
		if isSpider and Toggles.DisableTimothyJumpscare and Toggles.DisableTimothyJumpscare.Value then
			task.defer(function()
				pcall(function() child:Destroy() end)
			end)
		end
	end

	Connections.CameraEntityHandler = cam.ChildAdded:Connect(CheckCamEntity)
	Connections.CameraDescendantHandler = cam.DescendantAdded:Connect(CheckCamEntity)

	for _, child in ipairs(cam:GetDescendants()) do
		CheckCamEntity(child)
	end
end

Connections.EntityHandler = Services.Workspace.ChildAdded:Connect(HandleEntitySpawn)

do
local liveEntities = Services.Workspace:FindFirstChild("LiveEntities")
if liveEntities then
	Connections.LiveEntitiesHandler = liveEntities.ChildAdded:Connect(HandleEntitySpawn)
end

-- Подключение обработки TV_Stand и сущностей в Misc
local function HookMiscFolder(folder)
	if not folder then return end
	if Connections.MiscEntityHandler then
		Connections.MiscEntityHandler:Disconnect()
		Connections.MiscEntityHandler = nil
	end
	local function CheckMiscEntity(child)
		if not child or not child.Parent then return end
		local cname = child.Name
		if cname == "TV_Stand" or cname == "Noise_TV" or cname == "NoiseTV" or (Entities and Entities[cname]) then
			task.spawn(Functions.HandleEntitySpawn, child)
		end
	end
	Connections.MiscEntityHandler = folder.ChildAdded:Connect(CheckMiscEntity)
	for _, child in ipairs(folder:GetChildren()) do
		CheckMiscEntity(child)
	end
end

local miscFolder = Services.Workspace:FindFirstChild("Misc")
if miscFolder then
	HookMiscFolder(miscFolder)
end
Services.Workspace.ChildAdded:Connect(function(child)
	if child.Name == "Misc" then
		HookMiscFolder(child)
	end
end)

-- Подключение обработки сущностей в Camera
if Services.Workspace.CurrentCamera then
	Functions.HookCamera(Services.Workspace.CurrentCamera)
elseif Camera then
	Functions.HookCamera(Camera)
end

Connections.CurrentCameraChanged = Services.Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	if Services.Workspace.CurrentCamera then
		Camera = Services.Workspace.CurrentCamera
		Functions.HookCamera(Camera)
	end
end)

-- Проверка уже заспавненных сущностей при запуске скрипта
for _, Obj in ipairs(Services.Workspace:GetDescendants()) do
	if Obj.Name == "TV_Stand" or Obj.Name == "Noise_TV" or Obj.Name == "NoiseModel" or Obj.Name == "Noise" or (Obj:IsA("Model") and Entities[Obj.Name]) then
		if Obj.Name == "Eyes" or Obj.Name == "Lookman" or Obj.Name == "BackdoorLookman" then
			if Functions.IsValidEyes(Obj) then
				task.spawn(HandleEntitySpawn, Obj)
			end
		else
			task.spawn(HandleEntitySpawn, Obj)
		end
	end
end

local LastClean = tick()
Connections.Cleaner = Services.RunService.Heartbeat:Connect(function()
	if tick() - LastClean <= 1 then return end
	LastClean = tick()

	for _, Array in pairs(Objects) do
		local I = #Array
		while I >= 1 do
			local Object = Array[I]
			-- Object.Parent == nil работает в разы быстрее, чем IsDescendantOf
			if not Object or Object.Parent == nil then
				table.remove(Array, I)
				if Abysall and Abysall.ESPLibrary then
					Abysall.ESPLibrary:RemoveESP(Object)
				end
				local Conn = ESPConnections[Object]
				if Conn then
					Conn:Disconnect()
					ESPConnections[Object] = nil
				end
			end
			I -= 1
		end
	end
end)

local LastPromptFix = tick()
Connections.PromptFixer = Services.RunService.Heartbeat:Connect(function()
	if tick() - LastPromptFix <= 0.5 then return end
	LastPromptFix = tick()
	for _, Prompt in Objects.Prompts do
		if Prompt and Prompt.Parent and Prompt:HasTag("DisableWhenEnabledOnClient") then
			Prompt:RemoveTag("DisableWhenEnabledOnClient")
		end
	end
end)
end

if LocalPlayer.Character then
	task.spawn(function() Functions.HandleCharacter(LocalPlayer.Character) end)
end

Connections.LocalCharacterAdded = LocalPlayer.CharacterAdded:Connect(function(NewCharacter)
	if Connections.MainHandler then
		Connections.MainHandler:Disconnect()
		Connections.MainHandler = nil
	end
	task.wait(0.5)
	Functions.HandleCharacter(NewCharacter)
end)

Library:OnUnload(function()
	Globals.Running = false
	table.clear(Globals.ObjectQueue)

	local DummyToggle = { Value = false, GetState = function() return false end, SetValue = function() end }
	local DummyOption = { Value = 0, GetState = function() return 0 end, SetValue = function() end }
	pcall(function()
		setmetatable(Toggles, { __index = function() return DummyToggle end })
		setmetatable(Options, { __index = function() return DummyOption end })
	end)

	StopTimeShower(true)

	-- Отключение Creak Aggression Meter
	if StopCreakAggressionListener then
		StopCreakAggressionListener()
	end
	if CreakAggressionMetersTable then
		for CreakEntityModel in pairs(CreakAggressionMetersTable) do
			CleanupCreakAggressionMeter(CreakEntityModel)
		end
	end

	-- Отключение Honcho
	if ClearHonchoESP then
		ClearHonchoESP()
	end

	-- Отключение Orbit и Bring Interval
	if OrbitDroppedItemsConnection then
		OrbitDroppedItemsConnection:Disconnect()
		OrbitDroppedItemsConnection = nil
	end
	if Connections.CrazyCartCreak then
		Connections.CrazyCartCreak:Disconnect()
		Connections.CrazyCartCreak = nil
	end
	droppedItemsIntervalRunning = false

	-- Завершение отдельных задач и соединений
	if BypassDronesStampedeConnection then task.cancel(BypassDronesStampedeConnection) BypassDronesStampedeConnection = nil end
	if WaterBypassConnection then WaterBypassConnection:Disconnect() WaterBypassConnection = nil end
	if AlmaConnection then AlmaConnection:Disconnect() AlmaConnection = nil end
	if AntiScribbles_Connection then AntiScribbles_Connection:Disconnect() AntiScribbles_Connection = nil end
	if AntiClosetTrash_Connection then AntiClosetTrash_Connection:Disconnect() AntiClosetTrash_Connection = nil end
	if AntiRansom_Connection then AntiRansom_Connection:Disconnect() AntiRansom_Connection = nil end
	if DroneConnection then DroneConnection:Disconnect() DroneConnection = nil end
	if ForgetMeNotConnection then ForgetMeNotConnection:Disconnect() ForgetMeNotConnection = nil end
	ForgetMeNotRunning = false
	table.clear(ForgetMeNotCompleted)
	if TpNextDoorConnection then task.cancel(TpNextDoorConnection) TpNextDoorConnection = nil end

	-- Корректное отключение всех соединений в таблице
	for Key, Connection in pairs(Connections) do
		if typeof(Connection) == "RBXScriptConnection" then
			pcall(function() Connection:Disconnect() end)
		elseif typeof(Key) == "RBXScriptConnection" then
			pcall(function() Key:Disconnect() end)
		end
	end
	table.clear(Connections)

	for _, Object in Objects.Entities do
		if Object.Name == "Snare" or Object.Name == "GiggleCeiling" then
			local Hitbox = Object:FindFirstChild("Hitbox")
			if Hitbox then Hitbox.CanTouch = true end
		end
		if Object.Name == "GloomPile" then
			for _, Part in Object:GetDescendants() do
				if Part:IsA("BasePart") then Part.CanTouch = true end
			end
		end
		if Object.Name == "FakeDoor" or Object.Name == "DoorFake" then
			local Hidden = Object:FindFirstChild("Hidden")
			if Hidden then Hidden.CanTouch = true end
			local Lock = Object:FindFirstChild("Lock")
			if Lock and Lock:FindFirstChild("UnlockPrompt") then Lock.UnlockPrompt.Enabled = true end
		end
		if Object.Name == "SideroomSpace" then
			local Coll = Object:FindFirstChild("Collision")
			if Coll then Coll.CanCollide = false Coll.CanTouch = true end
		end
	end

	for _, Object in Objects.SeekBridges do Object:Destroy() end

	for _, Fog in Globals.FogInstances do
		Fog.Density = Fog:GetAttribute("Density_Old")
	end
	Services.Lighting.FogEnd = Globals.OldFog

	local Vignette = Globals.MainUI:FindFirstChild("HideVignette") or Globals.MainUI.MainFrame:FindFirstChild("HideVignette")
	if Vignette then Vignette.Image = "rbxassetid://6100076320" end

	local ModuleRestores = {
		Screech = "Screech", Glitch = "Glitch", Shade = "Shade",
		SpiderJumpscare = "SpiderJumpscare", A90 = "A90", Dread = "Dread", Void = "Void"
	}
	for Key, OriginalName in ModuleRestores do
		pcall(function()
			if Modules[Key] then Modules[Key].Name = OriginalName end
		end)
	end
	if Functions.ApplyDisableTimothyJumpscare then
		pcall(function() Functions.ApplyDisableTimothyJumpscare(false) end)
	end
	if Functions.ApplyRemoveA90 then
		pcall(function() Functions.ApplyRemoveA90(false) end)
	end

	pcall(function() if FakeEvents.Screech then FakeEvents.Screech:Destroy() end end)
	pcall(function() if FakeEvents.Screech_Real and RemotesFolder then FakeEvents.Screech_Real.Parent = RemotesFolder end end)
	pcall(function() if FakeEvents.Shade then FakeEvents.Shade:Destroy() end end)
	pcall(function() if FakeEvents.Shade_Real and RemotesFolder then FakeEvents.Shade_Real.Parent = RemotesFolder end end)

	pcall(function() if FakeEvents.A90 then FakeEvents.A90:Destroy() end end)
	pcall(function() if FakeEvents.A90_Real and RemotesFolder then FakeEvents.A90_Real.Parent = RemotesFolder end end)

	pcall(function() if FakeEvents.Surge then FakeEvents.Surge:Destroy() end end)
	pcall(function() if FakeEvents.Surge_Real and RemotesFolder then FakeEvents.Surge_Real.Parent = RemotesFolder end end)

	pcall(function() if Globals.SeekNodesFolder then Globals.SeekNodesFolder:Destroy() end end)
	pcall(function() if Globals.RoomsNodesFolder then Globals.RoomsNodesFolder:Destroy() end end)
	pcall(function() if Globals.ManipulateBody then Globals.ManipulateBody:Destroy() end end)

	pcall(function()
		local currentRoomNum = LocalPlayer:GetAttribute("CurrentRoom")
		local roomObj = currentRoomNum and CurrentRooms and CurrentRooms:FindFirstChild(tostring(currentRoomNum))
		local OldAmbient = roomObj and roomObj:GetAttribute("Ambient") or Services.Lighting.Ambient
		Services.TweenService:Create(Services.Lighting, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), { Ambient = OldAmbient }):Play()
	end)

	for _, Prompt in Objects.Prompts do
		pcall(function()
			if FakePrompts[Prompt] then
				if Prompt.Parent then
					FakePrompts[Prompt].Parent = Prompt.Parent
				end
				FakePrompts[Prompt] = nil
				Prompt:Destroy()
			end
			if Prompt and Prompt.Parent then
				Prompt.HoldDuration = Prompt:GetAttribute("HoldDuration_Old") or Prompt.HoldDuration
				Prompt.RequiresLineOfSight = Prompt:GetAttribute("RequiresLineOfSight_Old") or Prompt.RequiresLineOfSight
				Prompt.MaxActivationDistance = Prompt:GetAttribute("MaxActivationDistance_Old") or Prompt.MaxActivationDistance
			end
		end)
	end

	pcall(function()
		if Character and Character.Parent then
			Character:SetAttribute("CanJump",  OldJump)
			Character:SetAttribute("CanSlide", OldSlide)
		end
	end)

	for _, Object in Services.Workspace:GetDescendants() do
		task.spawn(function()
			pcall(function() Functions.RemoveESP(Object) end)
		end)
	end

	pcall(function()
		if Humanoid and Humanoid.Parent then
			Humanoid.WalkSpeed  = Functions.GetCurrentSpeed()
			Humanoid.JumpPower  = 5
			Humanoid.HipHeight  = 2.367
		end
	end)

	pcall(function()
		local BaseY = 0.18
		if Collision and RootPart then Collision.Position = RootPart.Position + Vector3.new(0, BaseY, 0) end
		if CollisionPart and RootPart then CollisionPart.Position = RootPart.Position + Vector3.new(0, BaseY, 0) end
		if CollisionPartClone and RootPart then CollisionPartClone.Position = RootPart.Position + Vector3.new(0, BaseY, 0) end

		if Character and Character:FindFirstChild("LowerTorso") and Character.LowerTorso:FindFirstChild("Root") and Globals.OriginalC1 then
			Character.LowerTorso.Root.C1 = Globals.OriginalC1
		end
		if Collision and Collision:FindFirstChild("CollisionCrouch") and RootPart then
			Collision.CollisionCrouch.Position = RootPart.Position + Vector3.new(0, -0.982, 0)
		end
	end)

	pcall(function() if CollisionClone then CollisionClone:Destroy() end end)
	pcall(function() if CollisionPartClone then CollisionPartClone:Destroy() end end)
	pcall(function() if Abysall.ESPLibrary then Abysall.ESPLibrary:Unload() end end)

	pcall(function()
		if Main_Game then
			Main_Game.fovtarget   = 70
			Main_Game.spring.Speed = 8
			Main_Game.tooloffset   = Vector3.zero
		end
		if Services.Workspace.CurrentCamera then
			Services.Workspace.CurrentCamera.FieldOfView = 70
		end
	end)

	pcall(function()
		if Globals.OriginalGetMoveVector then 
			local Controls = require(LocalPlayer.PlayerScripts.PlayerModule):GetControls()
			Controls.GetMoveVector = Globals.OriginalGetMoveVector
		end
	end)

	getgenv().Abysall = nil
	shared.Hastelepasta = false
end)



do
	local uiWaitTimeout = tick() + 5
	while not Globals.MainUI and tick() < uiWaitTimeout do
		task.wait(0.1)
	end
end

if not Globals.MainUI and LocalPlayer:FindFirstChild("PlayerGui") then
	Globals.MainUI = LocalPlayer.PlayerGui:FindFirstChild("MainUI")
end

Abysall.Interface.ApplySettingsTab(Window)
Functions.Notify({ Title = "Successfully loaded in " .. math.floor((tick() - LoadStart) * 1000) / 1000 .. " seconds." , Body = "Press '" .. tostring(Options.MenuKeybind.Value) .. "' to toggle the UI."})
print("i allive")
