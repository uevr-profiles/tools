local configui = require("libs/configui")

local version = "1.03"
local configDefinition = {
	{
		panelLabel = "RoboCop Config", 
		saveFile = "config_main",
		layout = 
		{		
			{
				widgetType = "text",
				id = "versionTxt",
				label = "First Person Mod"
			},
			{
				widgetType = "checkbox",
				id = "show_hands",
				label = "Show Hands",
				initialValue = true
			},
			{
				widgetType = "checkbox",
				id = "left_hand_mode",
				label = "Left Hand Mode",
				initialValue = false
			},
			{
				widgetType = "checkbox",
				id = "useSnapTurn",
				label = "Use Snap Turn",
				initialValue = useSnapTurn
			},
			{
				widgetType = "checkbox",
				id = "ui_follows_head",
				label = "Head Locked UI",
				initialValue = true
			},
			{
				id = "ui_position",
				label = "UI Position",
				widgetType = "drag_float3",
				speed = .01, 
				range = {-10, 10}, 
				initialValue = {0.0,-0.1,1.0}
			},
			-- {
				-- widgetType = "slider_int",
				-- id = "snapAngle",
				-- label = "Snap Turn Angle",
				-- speed = 1.0,
				-- range = {2, 180},
				-- initialValue = false
			-- },
			{
				widgetType = "checkbox",
				id = "useReticule",
				label = "Show 3D Reticule",
				initialValue = false
			},
			{
				widgetType = "slider_int",
				id = "reticuleDistance",
				label = "Reticule Distance",
				speed = 1.0,
				range = {0, 3000},
				initialValue = 700
			},
			{
				widgetType = "slider_float",
				id = "reticuleScale",
				label = "Reticule Scale",
				speed = 0.1,
				range = {0.1, 5.0},
				initialValue = 1.0
			},
			-- {
				-- widgetType = "drag_float3",
				-- id = "grabbed_item_location",
				-- label = "Grabbed Item Location",
				-- speed = 0.2,
				-- range = {-100, 100},
				-- initialValue = {0.0, 0.0, 0.0}
			-- },
			-- {
				-- widgetType = "drag_float3",
				-- id = "grabbed_item_rotation",
				-- label = "Grabbed Item Rotation",
				-- speed = 0.2,
				-- range = {-90, 90},
				-- initialValue = {0.0, 0.0, 0.0}
			-- },
			{
				widgetType = "combo",
				id = "fixGammaIssue",
				label = "Gamma Fix (experimental)",
				selections = {"None","Standard","Max"},
				initialValue = 2
			},
			{
				widgetType = "combo",
				id = "physical_punch",
				label = "Physical Gesture Mode",
				selections = {"No Physical Gestures", "Physical Punch + Right Grip Punch", "Full Physical Gestures + Buttons", "Full Physical Gestures Only"},
				initialValue = 2
			},
			{
				widgetType = "text",
				id = "physical_desc_0",
				label = "Physical Gestures:"
			},
			{
				widgetType = "text",
				id = "physical_desc_1",
				label = "    Punch (ED209 Stomp) - gun hand punch"
			},
			{
				widgetType = "text",
				id = "physical_desc_2",
				label = "    Heal - non-gun hand to mouth and grip"
			},
			{
				widgetType = "text",
				id = "physical_desc_3",
				label = "    Switch weapons - gun hand straight down to your side and grip"
			},
			{
				widgetType = "text",
				id = "physical_desc_4",
				label = "    Reload - non-gun hand near your gun hand and grip"
			},
			{
				widgetType = "text",
				id = "physical_desc_5",
				label = "    Scan - non-gun hand to the side of your head and grip"
			},
			{
				widgetType = "text",
				id = "physical_desc_6",
				label = "    Bullet time - non-gun hand to the side of your head and trigger"
			},
			{
				widgetType = "text",
				id = "physical_desc_7",
				label = "    Night vision - non-gun hand in front of your eyes and grip"
			},
			{
				widgetType = "text",
				id = "physical_desc_8",
				label = "    Flash Bang - non-gun hand in front of your eyes and trigger"
			},
			{
				widgetType = "text",
				id = "physical_desc_9",
				label = "    Grab Gun, Grab Chair, Open Door, etc - gun hand grip while pointing at the item"
			},
			{
				widgetType = "text",
				id = "physical_desc_10",
				label = "    Throw gripped item - gun hand punch while gripping item"
			},
		}	
	}
}

configui.create(configDefinition)

configui.setLabel("versionTxt", "Robocop First Person Mod v" ..  version)

function setDescriptionState()
	local mode = configui.getValue("physical_punch")
	configui.hideWidget("physical_desc_0", mode == 1)
	configui.hideWidget("physical_desc_1", mode == 1)
	configui.hideWidget("physical_desc_2", mode == 1 or mode == 2)
	configui.hideWidget("physical_desc_3", mode == 1 or mode == 2)
	configui.hideWidget("physical_desc_4", mode == 1 or mode == 2)
	configui.hideWidget("physical_desc_5", mode == 1 or mode == 2)
	configui.hideWidget("physical_desc_6", mode == 1 or mode == 2)
	configui.hideWidget("physical_desc_7", mode == 1 or mode == 2)
	configui.hideWidget("physical_desc_8", mode == 1 or mode == 2)
	configui.hideWidget("physical_desc_9", mode == 1 or mode == 2)
	configui.hideWidget("physical_desc_10", mode == 1 or mode == 2)
end
setDescriptionState()

function hideReticuleWidgets(value)
	configui.hideWidget("reticuleDistance", value)
	configui.hideWidget("reticuleScale", value)
end

configui.onUpdate("useReticule", function(value)
	hideReticuleWidgets(not value)
end)

configui.onUpdate("ui_position", function(value)
	uevr.params.vr.set_mod_value("UI_X_Offset", configui.getValue("ui_position").X)
	uevr.params.vr.set_mod_value("UI_Y_Offset", configui.getValue("ui_position").Y)
	uevr.params.vr.set_mod_value("UI_Distance", configui.getValue("ui_position").Z)
end)

hideReticuleWidgets(not configui.getValue("useReticule"))

configui.hideWidget("ui_position", not configui.getValue("ui_follows_head"))
configui.onUpdate("ui_follows_head", function(value)
	configui.hideWidget("ui_position", not value)
end)

configui.onUpdate("useSnapTurn", function(value)
	--configui.hideWidget("snapAngle", not value)	
end)

configui.onUpdate("physical_punch", function(value)
	setDescriptionState()
end)
