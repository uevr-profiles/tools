local uevrUtils = require('libs/uevr_utils')
local controllers = require('libs/controllers')
local configui = require("libs/configui")
local reticule = require("libs/reticule")
local hands = require('libs/hands')
local attachments = require('libs/attachments')
local input = require('libs/input')
local pawnModule = require('libs/pawn')
local animation = require('libs/animation')
local montage = require('libs/montage')
local interaction = require('libs/interaction')
local ui = require('libs/ui')
local remap = require('libs/remap')
local gestures = require('libs/gestures')

uevrUtils.setLogLevel(LogLevel.Debug)
-- reticule.setLogLevel(LogLevel.Debug)
-- -- input.setLogLevel(LogLevel.Debug)
-- attachments.setLogLevel(LogLevel.Debug)
-- -- animation.setLogLevel(LogLevel.Debug)
-- ui.setLogLevel(LogLevel.Debug)
-- remap.setLogLevel(LogLevel.Debug)
-- --hands.setLogLevel(LogLevel.Debug)
--interaction.setLogLevel(LogLevel.Debug)


--uevrUtils.setDeveloperMode(true)
--hands.enableConfigurationTool()

ui.init()
montage.init()
interaction.init()
attachments.init()
attachments.setGripUpdateTimeout(400)
reticule.init()
pawnModule.init()
remap.init()
input.init()

local status = {}

local versionTxt = "v1.0.0"
local title = "A Quiet Place: The Road Ahead, First Person Mod " .. versionTxt
local configDefinition = {
	{
		panelLabel = "A Quiet Place Config",
		saveFile = "a_quiet_place_config",
		layout = spliceableInlineArray
		{
			{ widgetType = "text", id = "title", label = title },
			{ widgetType = "indent", width = 20 }, { widgetType = "text", label = "UI" }, { widgetType = "begin_rect", },
				expandArray(ui.getConfigurationWidgets),
			{ widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 20 },
			{ widgetType = "new_line" },
			{ widgetType = "indent", width = 20 }, { widgetType = "text", label = "Input" }, { widgetType = "begin_rect", },
				expandArray(input.getConfigurationWidgets),
			{ widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 20 },
			{ widgetType = "new_line" },
			{ widgetType = "indent", width = 20 }, { widgetType = "text", label = "Reticule" }, { widgetType = "begin_rect", },
				expandArray(reticule.getConfigurationWidgets,{{id="uevr_reticule_eye_dominance",isHidden=true},{id="uevr_reticule_eye_dominance_offset",isHidden=true}}),
			{ widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 20 },
			{ widgetType = "new_line" },
			-- { widgetType = "indent", width = 20 }, { widgetType = "text", label = "Control" }, { widgetType = "begin_rect", },
			-- 	{
			-- 		widgetType = "checkbox",
			-- 		id = "test_1",
			-- 		label = "Test 1",
			-- 		initialValue = false
			-- 	},
			-- 	{
			-- 		widgetType = "button",
			-- 		id = "pawn_offset",
			-- 		label = "Free Me",
			-- 	},
            -- { widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 20 },
			-- { widgetType = "new_line" },
		}
	}
}
configui.create(configDefinition)

local function getAttachedChild(meshComponent, name)
    if meshComponent ~= nil and meshComponent.AttachChildren ~= nil then
        for index, child in ipairs(meshComponent.AttachChildren) do
            if name == uevrUtils.getShortName(child) then
               return child
            end
        end
    end
end

local defaultAttachOptions = {
	detachFromOriginOnGrip = false,
	maintainWorldPositionOnDetachFromOrigin = false,
	detachFromParentOnRelease = false,
	maintainWorldPositionOnDetachFromParent = false,
	reattachToOriginOnRelease = false,
	restoreTransformToOriginOnReattach = false,
	useZeroTransformOnReattach = false,
	allowChildVisibilityHandling = false,
	allowChildHiddenInGameHandling = false,
	allowRenderInMainPassHandling = true,
}
local specialAttachOptions = {
	detachFromOriginOnGrip = true,
	maintainWorldPositionOnDetachFromOrigin = false,
	detachFromParentOnRelease = true,
	maintainWorldPositionOnDetachFromParent = false,
	reattachToOriginOnRelease = true,
	restoreTransformToOriginOnReattach = false,
	useZeroTransformOnReattach = true,
	allowChildVisibilityHandling = false,
	allowChildHiddenInGameHandling = false,
	allowRenderInMainPassHandling = true,
}
-- local plankAttachOptions = {
-- 	detachFromOriginOnGrip = true,
-- 	maintainWorldPositionOnDetachFromOrigin = false,
-- 	detachFromParentOnRelease = true,
-- 	maintainWorldPositionOnDetachFromParent = false,
-- 	reattachToOriginOnRelease = true,
-- 	restoreTransformToOriginOnReattach = true,
-- 	useZeroTransformOnReattach = false,
-- 	allowChildVisibilityHandling = false,
-- 	allowChildHiddenInGameHandling = false,
-- 	allowRenderInMainPassHandling = true,
-- }

local function createCrank(meshComponent)
    local result = nil
    if meshComponent ~= nil then
        --print("Creating static mesh from handle mesh:", meshComponent.StaticMesh:get_full_name())
        result = uevrUtils.createStaticMeshComponent(meshComponent.StaticMesh)
        status["crankChildComponent"] = result
        local handle = getAttachedChild(meshComponent, "Handle")
        if handle ~= nil then
            status["crankChildHandle"] = handle
            status["handleParent"] = meshComponent
            handle:K2_AttachTo(result, uevrUtils.fname_from_string(""), 0 , false)
            uevrUtils.set_component_relative_location(handle, {18.5, 0, 52})
        end
    end
    return result
end

local function destroyCrank()
    local handle = status["crankChildHandle"]
    local handleParent = status["handleParent"]
    if uevrUtils.getValid(handle) ~= nil and uevrUtils.getValid(handleParent) ~= nil then
        handle:K2_AttachTo(handleParent, uevrUtils.fname_from_string(""), 0 , false)
        uevrUtils.set_component_relative_location(handle, {18.5, 0, 52})
    end
    if uevrUtils.getValid(status["crankChildComponent"]) ~= nil then
        uevrUtils.destroyComponent(status["crankChildComponent"], true, true)
    end
    status["crankChildComponent"] = nil
    status["crankChildHandle"] = nil
    status["handleParent"] = nil
end

local function getWeaponMesh()
    local weaponMeshLeft = nil
    local weaponMeshRight = nil
    status["rightHeldItem"] = nil
    status["leftHeldItem"] = nil
    status["holdingInhaler"] = nil
    local attachOptionsRight = defaultAttachOptions
    local attachOptionsLeft = defaultAttachOptions
	if uevrUtils.getValid(pawn) ~= nil then --and pawn.Children ~= nil then
        if pawn.GetLeftHeldItem ~= nil then
            local leftHeldItem = {}
            pawn:GetLeftHeldItem(leftHeldItem)
            local rightHeldItem = {}
            pawn:GetRightHeldItem(rightHeldItem)
            --print("Left Held Item:", leftHeldItem.result, "Right Held Item:", rightHeldItem.result)
            if leftHeldItem and leftHeldItem.result ~= nil then
                --print("Left Held Item Class:", uevrUtils.getShortName(leftHeldItem.result))
                status["leftHeldItem"] = uevrUtils.getShortName(leftHeldItem.result)
                weaponMeshLeft = leftHeldItem.result.MeshComponent
            end
            if rightHeldItem and rightHeldItem.result ~= nil then
                --print("Right Held Item Class:", uevrUtils.getShortName(rightHeldItem.result))
                status["rightHeldItem"] = uevrUtils.getShortName(rightHeldItem.result)
                if string.sub(status["rightHeldItem"], 1, 10) == "BP_Inhaler" then
                    status["holdingInhaler"] = true
                end

                if string.sub(status["rightHeldItem"], 1, 13) == "BP_WaterValve" then
                    weaponMeshRight = status["valveChild"]
                    if weaponMeshRight == nil then
                        weaponMeshRight = getAttachedChild(rightHeldItem.result.MeshComponent, "Valve Mesh")
                    end
                    status["valveChild"] = weaponMeshRight
                    attachOptionsRight = specialAttachOptions
                elseif string.sub(status["rightHeldItem"], 1, 8) == "BP_Crank" then
                    weaponMeshRight = status["crankChild"]
                    if weaponMeshRight == nil then
                        --create our own mesh out of this since the game one is a mess
                        weaponMeshRight = createCrank(rightHeldItem.result.MeshComponent)
                        --weaponMeshRight = getAttachedChild(rightHeldItem.result.MeshComponent, "Handle")
                        --print("Crank handle found:", weaponMeshRight:get_full_name())
                    end
                    status["crankChild"] = weaponMeshRight
                    attachOptionsRight = defaultAttachOptions
                -- elseif string.sub(status["rightHeldItem"], 1, 14) == "BP_WoodenPlank" then
                --     weaponMeshRight = status["plankChild"]
                --     if weaponMeshRight == nil then
                --         print(rightHeldItem.result.MeshComponent:get_full_name())
                --         local endPivot = getAttachedChild(rightHeldItem.result.MeshComponent, "EndPivot")
                --         if endPivot ~= nil then
                --             weaponMeshRight = getAttachedChild(endPivot, "ActualMesh")
                --         end
                --     end
                --     --print()
                --     status["plankChild"] = weaponMeshRight
                --     attachOptionsRight = plankAttachOptions
                --elseif string.sub(status["rightHeldItem"], 1, 8) ~= "BP_Crank" and string.sub(status["rightHeldItem"], 1, 14) ~= "BP_WoodenPlank" and string.sub(status["rightHeldItem"], 1, 10) ~= "BP_BeerBox" then --and string.sub(status["rightHeldItem"], 1, 13) ~= "BP_WaterValve" then
                elseif string.sub(status["rightHeldItem"], 1, 14) ~= "BP_WoodenPlank" and string.sub(status["rightHeldItem"], 1, 10) ~= "BP_BeerBox" then --and string.sub(status["rightHeldItem"], 1, 13) ~= "BP_WaterValve" then
                    weaponMeshRight = rightHeldItem.result.MeshComponent
                end
            end
        elseif pawn.StormindFPSGunManager ~= nil then
            weaponMeshRight = uevrUtils.getValid(pawn, {"StormindFPSGunManager", "CurrentGun", "GunMesh"})
        end
 	end

    if weaponMeshRight ~= status["valveChild"] then
        status["valveChild"] = nil
    end
    -- if weaponMeshRight ~= status["plankChild"] then
    --     status["plankChild"] = nil
    -- end
    if weaponMeshRight ~= status["crankChild"] then
        if status["crankChild"] ~= nil then
            destroyCrank()
        end
        status["crankChild"] = nil
    end

	return weaponMeshLeft, weaponMeshRight, attachOptionsRight, attachOptionsLeft
end

attachments.registerOnGripUpdateCallback(function()
    local weaponMeshLeft, weaponMeshRight, attachOptionsRight, attachOptionsLeft = getWeaponMesh()
    local leftHand = controllers.getController(Handed.Left)
    local rightHand = controllers.getController(Handed.Right)
    --print(weaponMeshLeft, weaponMeshRight, attachOptionsRight, attachOptionsLeft, rightHand, leftHand)
	return weaponMeshRight, rightHand, weaponMeshRight and weaponMeshRight.AttachSocketName or nil, weaponMeshLeft, leftHand, weaponMeshLeft and weaponMeshLeft.AttachSocketName or nil, attachOptionsRight, attachOptionsLeft
end)

attachments.registerAttachmentChangeCallback(function(id, gripHand, attachment)
    uevrUtils.fixMeshFOV(attachment, "Clip Offset", 0.0, true, true, false)
    --uevrUtils.fixMeshFOV(hands.getHandComponent(Handed.Right), "Clip Offset", 0.0, true, true, false)
end)

function on_montage_change(montageObject, montageName)
    --print("Montage change detected:", montageName)
end

function on_post_engine_tick(engine, delta)
    ---print("here",pawn["Is Player Animation Mode"])
	if uevrUtils.getValid(pawn) ~= nil then
        --Extermely important. Cutscenes and narrow passages are broken without this
        if pawn.bUseControllerRotationYaw ~= nil then
            pawn.bUseControllerRotationYaw = false -- always disable controller rotation on the pawn, even in cutscenes when input is disabled
        end
        
        local isDefaultPawn = pawn["Is Player Animation Mode"] ~= nil
        if status["isDefaultPawn"] ~= isDefaultPawn then
            status["isDefaultPawn"] = isDefaultPawn
            input.setCurrentProfileByLabel(isDefaultPawn and "Default" or "Van")
            pawnModule.setCurrentProfileByLabel(isDefaultPawn and "Default" or "Van Ride")
            reticule.setActiveReticuleByLabel(isDefaultPawn and "None" or "Van Reticule")
        end

        --This game doesnt support standard cutscene detection but provides this variable instead
        uevrUtils.setIsInCutsceneOverride(pawn["Is Player Animation Mode"])

	end
end

uevrUtils.registerOnInputGetStateCallback(function(retval, user_index, state)
	if state.Gamepad.bRightTrigger > 0 then
	    if uevrUtils.getValid(pawn) ~= nil then
            --print("Right trigger pressed, attempting to use inhaler")
            --using the trigger why holding the inhaler in our custom hand does nothing so manually trigger the inhaler action here, but only if we are actually holding the inhaler and it's not on cooldown
            if status["holdingInhaler"] and pawn.BP_AsthmaControllerComponent:GetCanUseInhaler() and status["inhalerCooldown"] ~= true then
                --print("Can use inhaler, executing action")
                pawn.BP_AsthmaControllerComponent:Action_UseInhaler_Exec()
                status["inhalerCooldown"] = true
                delay(5000, function()  -- Set a cooldown of 5 seconds before the inhaler can be used again
                    status["inhalerCooldown"] = nil
                end)
                --pawn.BP_AsthmaControllerComponent:UseInhaler() --reduces asthema but with no animations
                --pawn.BP_AsthmaControllerComponent:TriggerInhalerEffect() --didnt try this because I found Action_UseInhaler_Exec first
            end
        end
    end

end) --increased priority to get values before remap occurs

local function cleanup()
	if uevrUtils.getValid(status["maskEffectComponent"]) ~= nil then
 		uevrUtils.destroyComponent(status["maskEffectComponent"], true, true)
    end
    status["maskEffectComponent"] = nil

    if status["crankChild"] ~= nil then
        destroyCrank()
    end
end

uevr.params.sdk.callbacks.on_script_reset(function()
    cleanup()
end)

local function attachGasMaskEffectToHMD()
    if status["maskEffectComponent"] == nil then
        local widget = uevrUtils.getValid(uevr.api:get_player_controller(0),{"MyHUD", "HUDWidget", "WBP_MaskEffect", "Image_Mask"})
        --print("Widget found:", widget ~= nil)
        if widget ~= nil then
            --widget:SetRenderOpacity(0.7)
            local hudComponent = controllers.getController(2)
            local options = {
                removeFromViewport = false
            }
            local widgetComponent = uevrUtils.createWidgetComponent(widget, options)
            if widgetComponent ~= nil and hudComponent ~= nil then
                widget:RemoveFromParent()
                widgetComponent:K2_AttachTo(hudComponent, uevrUtils.fname_from_string(""), 0 , false)
     			uevrUtils.set_component_relative_transform(widgetComponent, {7,0,-2.25}, {0,0,0}, {-0.05,-0.05, 0.035})
                --print("Attached mask effect to hud")
                status["maskEffectComponent"] = widgetComponent
                return
            end
        end
    end
    --print("Failed to attach mask effect to hud")
end

function on_level_change()
	cleanup()
end

setInterval(1000, function()
    if uevrUtils.getValid(pawn) ~= nil and pawn.GetGasMaskState ~= nil then
        local state = {}
        pawn:GetGasMaskState(state)
        if state ~= 0 and status["maskEffectComponent"] == nil then
            --print("Why is the mask state non-zero")
            attachGasMaskEffectToHMD()
        elseif state == 0 and status["maskEffectComponent"] ~= nil then
            uevrUtils.destroyComponent(status["maskEffectComponent"], true, true)
            status["maskEffectComponent"] = nil
        end
    end
end)

-- local isPaused = false
-- register_key_bind("F1", function()
-- 	isPaused = not isPaused
--     print("Game paused: " .. tostring(isPaused))
-- 	uevrUtils.pauseGame(isPaused)
-- end)

-- register_key_bind("F2", function()
--     print("F2 pressed")
--     --attachGasMaskEffectToHMD()
-- end)

-- configui.onUpdate("test_1", function(value)
--     isPaused = not isPaused
--     print("Game paused: " .. tostring(isPaused))
--     uevrUtils.pauseGame(isPaused)
-- end)

-- configui.onUpdate("pawn_offset", function()
--     if pawn ~= nil then
--         pawn:K2_AddActorLocalOffset(uevrUtils.vector(100, 0, 200), false, reusable_hit_result, true)
--     end
-- end)

