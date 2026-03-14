local configui = require("libs/configui")

local configDefinition = {
	{
		panelLabel = "RoboCop Config", 
		saveFile = "config_main",
		layout = 
		{		
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
				initialValue = false
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
		}	
	}
}

configui.create(configDefinition)

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
