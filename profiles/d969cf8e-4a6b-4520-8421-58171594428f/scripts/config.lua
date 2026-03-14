local configui = require("libs/configui")
local uevrUtils = require("libs/uevr_utils")

-- Config definition
local configDefinition = {
    {
        panelLabel = "Returnal VR Config",
        saveFile = "config_returnal_mod",
        layout = {
            { widgetType = "text_colored", label = "Returnal VR", color = "#00CC66FF" },
            { widgetType = "spacing" },
            { widgetType = "text", label = "UI Follow Mode:" },
            { widgetType = "spacing" },
            {
                widgetType = "checkbox",
                id = "ui_follow_hmd",
                label = "UI Follows HMD (Head)",
                initialValue = true
            },
            {
                widgetType = "checkbox",
                id = "ui_follow_controller",
                label = "UI Follows Right Controller",
                initialValue = false
            },
        }
    }
}

-- Create the panel
configui.create(configDefinition)

-- Make checkboxes mutually exclusive and apply settings
configui.onUpdate("ui_follow_hmd", function(value)
    if value == true then
        configui.setValue("ui_follow_controller", false)
        uevrUtils.enableUIFollowsView(true)
        print("[ReturnalMod] UI now follows HMD")
    end
end)

configui.onUpdate("ui_follow_controller", function(value)
    if value == true then
        configui.setValue("ui_follow_hmd", false)
        uevrUtils.enableUIFollowsView(false)
        print("[ReturnalMod] UI now follows Right Controller")
    end
end)

-- Apply initial setting on load
configui.onCreate("ui_follow_hmd", function(value)
    uevrUtils.enableUIFollowsView(value)
end)

print("[ReturnalMod] Config panel loaded")