local _, ns = ...
local LibEditMode = ns.LibEditMode

local LibEditModeOverride = LibStub("LibEditModeOverride-1.0")

loaded, value = C_AddOns.LoadAddOn("Masque")

-- Custom name for control in the game's built-in keybinding UI
_G["BINDING_NAME_CLICK ProteusButton:LeftButton"] = "Click Proteus Button"

--MARK: Database Defaults
local ProteusDB_Defaults = {
	showButton = true,
    showWelcomeMessage = true,
    addonEnabled = true,
    minimap = {
       hide = false,
    },
}

--MARK: Buff List
local buffList = {
    1223631,
    1223630,
    16593,
    16591,
}

--MARK: Pretty printer
function PrettyPrint(text)
    if not text or text == nil then return end

    local startLine = '\124c'
    local endLine = '\124r'

    local addonNameColour = "aa896fff"
    local textColour = "aaaaaaaa"

    local addonName = "Proteus: "
    local version = "v" .. (C_AddOns.GetAddOnMetadata(addonName, "Version") or "???")
    print(startLine .. addonNameColour .. addonName .. endLine .. text .. endLine)
end

function RemoveOtherNoggenfoggerBuffs()
    for index = 255, 1, -1 do
        local data = C_UnitAuras.GetAuraDataByIndex("player", index, "HELPFUL")
        if data and ProteusDB.addonEnabled then
            if canaccessvalue(data) and not issecretvalue(data.spellId) then
                for _,v in pairs(buffList) do
                    if v == data.spellId then
                        if not InCombatLockdown() then
							C_Spell.CancelSpellByID(data.spellId)
                        end
                    end
                end
            end
        end
    end
end

--MARK: Onscreen Button
local OnscreenButton = CreateFrame("Button", "ProteusButton", UIParent,"SecureActionButtonTemplate")
OnscreenButton:SetSize(30,30)
OnscreenButton:SetPoint("CENTER")

OnscreenButton.texture = OnscreenButton:CreateTexture()
OnscreenButton.texture:SetAllPoints(OnscreenButton)
OnscreenButton.texture:SetTexture("Interface\\ICONS\\ships_ability_stealth.blp")

OnscreenButton:SetScript("OnEnter", function(self, button, down)
	OnscreenButton.texture:SetDesaturated(true)
	OnscreenButton.texture:SetDesaturation(0.5)
end)
OnscreenButton:SetScript("OnLeave", function(self, button, down)
	OnscreenButton.texture:SetDesaturated(false)
end)

OnscreenButton:RegisterForClicks("AnyDown")
OnscreenButton:SetAttribute("type","toy")
OnscreenButton:SetAttribute("toy", 226373)

--https://github.com/p3lim-wow/LibEditMode/wiki
local defaultPosition = {
	point = 'CENTER',
	x = 0,
	y = 0,
}

local function onPositionChanged(frame, layoutName, point, x, y)
	ProteusDB[layoutName].point = point
	ProteusDB[layoutName].x = x
	ProteusDB[layoutName].y = y

	LibEditModeOverride:LoadLayouts()
end

local function toggleAddon()
    ProteusDB.addonEnabled = not ProteusDB.addonEnabled
    if ProteusDB.addonEnabled then
        OnscreenButton.texture:SetDesaturation(0.0)
    else
        OnscreenButton.texture:SetDesaturation(1.0)
    end
    if ProteusDB.addonEnabled == true then PrettyPrint("Now enabled.") end
    if ProteusDB.addonEnabled == false then PrettyPrint("Now disabled.") end
end

Proteus = LibStub("AceAddon-3.0"):NewAddon("Proteus")
LDB = LibStub("LibDataBroker-1.1", true)

--MARK: Events List
local ProteusFrame = CreateFrame("Frame")
ProteusFrame:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
ProteusFrame:RegisterEvent("UNIT_AURA")
ProteusFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
ProteusFrame:SetScript("OnEvent", eventHandler)

local enabled = true

--MARK: Event Handler
local function eventHandler(self, event, ...)
	local arg1, arg2, arg3 = ...

    if event == "PLAYER_ENTERING_WORLD" then
        layoutName = LibEditModeOverride:GetActiveLayout()

        local isInitialLogin = arg1
        local isReloadingUI  = arg2

        if isInitialLogin and ProteusDB.showWelcomeMessage then
            if ProteusDB.addonEnabled == true then PrettyPrint("Now enabled.") end
            if ProteusDB.addonEnabled == false then PrettyPrint("Now disabled.") end
        end

    if ProteusDB.minimap.hide == false then
        LDBIcon:Show("ProteusLDB")
    end
    if ProteusDB.minimap.hide == true then
        LDBIcon:Hide("ProteusLDB")
    end

        OnscreenButton:SetShown(ProteusDB.showButton)
	end

	if event == "EDIT_MODE_LAYOUTS_UPDATED" then
		LibEditModeOverride:LoadLayouts()
	end

    if event == "UNIT_AURA" then
        RemoveOtherNoggenfoggerBuffs()
    end
end

--MARK: Initialisation
function Proteus:OnInitialize()
	if not ProteusDB or ProteusDB == nil then
		ProteusDB = ProteusDB_Defaults
	end
    
    if ProteusDB.addonEnabled == nil then ProteusDB.addonEnabled = true end
    if ProteusDB.minimap.hide == nil then ProteusDB.minimap.hide = false end

	-- additional (anonymous) callbacks for edit mode
	LibEditMode:RegisterCallback('enter', function()
		OnscreenButton:SetShown(true)
	end)
	LibEditMode:RegisterCallback('exit', function()
		OnscreenButton:SetShown(ProteusDB.showButton)
	end)
	LibEditMode:RegisterCallback('layout', function(layoutName)
		if not ProteusDB[layoutName] then
			ProteusDB[layoutName] = CopyTable(defaultPosition)
		end

		OnscreenButton:ClearAllPoints()
		OnscreenButton:SetPoint(ProteusDB[layoutName].point, UIParent, ProteusDB[layoutName].x, ProteusDB[layoutName].y)
	end)

	LibEditMode:AddFrame(OnscreenButton, onPositionChanged, defaultPosition)
	LibEditMode:AddFrameSettings(OnscreenButton, {
		{
			name = 'Button Scale',
			kind = LibEditMode.SettingType.Slider,
			default = 1,
			get = function(layoutName)
					return ProteusDB[layoutName].scale
				end,
			set = function(layoutName, value)
					ProteusDB[layoutName].scale = value
					OnscreenButton:SetScale(value)
				end,
			minValue = 0.1,
			maxValue = 5,
			valueStep = 0.05,
			formatter = function(value)
					return FormatPercentage(value, true)
				end,
		},
		{
			name = 'Visibility',
			kind = LibEditMode.SettingType.Checkbox,
			default = ProteusDB.showButton,
			get = function(layoutName)
					return ProteusDB.showButton
				end,
			set = function(layoutName, value)
					ProteusDB.showButton = value
				end,
		},
        {
			name = 'Addon Enabled',
			kind = LibEditMode.SettingType.Checkbox,
			default = ProteusDB.addonEnabled,
			get = function(layoutName)
					return ProteusDB.addonEnabled
				end,
			set = function(layoutName, value)
					ProteusDB.addonEnabled = value
				end,
		},
        {
            name = 'Welcome Message',
			kind = LibEditMode.SettingType.Checkbox,
			default = ProteusDB.showWelcomeMessage,
			get = function(layoutName)
					return ProteusDB.showWelcomeMessage
				end,
			set = function(layoutName, value)
					ProteusDB.showWelcomeMessage = value
				end,
		},
    })

	if C_AddOns.IsAddOnLoaded("Masque") then
		local Masque = LibStub("Masque", true)
		local ProteusGroup = Masque:Group("Proteus")
		ProteusGroup:AddButton(OnscreenButton)
	end

    --MARK: Minimap Button
	LDB = LibStub("LibDataBroker-1.1", true)
	LDBIcon = LDB and LibStub("LibDBIcon-1.0", true)
    if LDB then
        local ProteusMMButton = LDB:NewDataObject("ProteusLDB", {
            type = "launcher",
            text = "Proteus",
            icon = "Interface\\ICONS\\ships_ability_stealth.blp",
            OnClick = function(frame, button)
                if button == "LeftButton" then
                    OnscreenButton:SetShown(not OnscreenButton:IsVisible())
                    ProteusDB.showButton = OnscreenButton:IsVisible()
                end
                if button == "RightButton" then
                    toggleAddon()
                end
            end,
            OnTooltipShow = function(tooltip)
                tooltip:AddLine("Left click: Toggle on-screen button")
                tooltip:AddLine("Right click: Toggle Proteus functionality")

                tooltip:AddLine("  ")
                if ProteusDB.addonEnabled == true then tooltip:AddLine("Proteus is enabled.") end
                if ProteusDB.addonEnabled == false then tooltip:AddLine("Proteus is disabled.") end
            end,
        })
        if LDBIcon then
			LDBIcon:Register("ProteusLDB", ProteusMMButton, ProteusDB.minimap)
		end
    end
end

ProteusFrame:SetScript("OnEvent", eventHandler)

--MARK: Slash Commands
SLASH_PROTEUS1 = "/proteus"
SLASH_PROTEUS2 = "/u91035" --Figure this one out!

SlashCmdList["PROTEUS"] = function(msg, editBox)
	OnChatCommand(msg)
end

-- Handles slash commands
function OnChatCommand(msg)
	local cmd, args = strsplit(" ", strlower(msg))

	if cmd == "button" then
        OnscreenButton:SetShown(not ProteusDB.showButton)
        ProteusDB.showButton = OnscreenButton:IsShown()
	end

    if cmd == "minimap" then
        ProteusDB.minimap.hide = not ProteusDB.minimap.hide
        if ProteusDB.minimap.hide == false then
            LDBIcon:Show("ProteusLDB")
            PrettyPrint("Minimap button enabled.")
        end
        if ProteusDB.minimap.hide == true then
            LDBIcon:Hide("ProteusLDB")
            PrettyPrint("Minimap button disabled.")
        end
    end

    if cmd == "toggle" then
        toggleAddon()
    end

    if cmd == "welcome" then
        ProteusDB.showWelcomeMessage = not ProteusDB.showWelcomeMessage
        if ProteusDB.showWelcomeMessage == true then PrettyPrint("Login message enabled.") end
        if ProteusDB.showWelcomeMessage == false then PrettyPrint("Login message disabled.") end
	end

    if cmd == "help" or cmd == nil or cmd == "" then
        print(" ")
        PrettyPrint("Auto-cancel non-shrink Noggenfogger buffs!")
        print("Valid slash command arguments:")
        print("  toggle: toggle addon functionality")
        print("  button: toggle onscreen button")
        print("  minimap: toggle minimap icon")
        print("  welcome: toggle login welcome message")
        print(" ")
    end

    if cmd == "reset" then
        ProteusDB = ProteusDB_Defaults
        icon:Show("ProteusLDB")
    end
end
