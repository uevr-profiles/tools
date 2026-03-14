uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
	-- local cursorPos = imgui.get_cursor_pos()
	--imgui.get_cursor_screen_pos()
	--print("cursorPos");
end)

uevr.sdk.callbacks.on_frame(function()

	local display_size = imgui.get_display_size()

    -- Set the next window to start at top-left and take full screen size
    imgui.set_next_window_pos(Vector2f.new(0, 0), imgui.ImGuiCond_Always)
    imgui.set_next_window_size(display_size, imgui.ImGuiCond_Always)

    -- Define flags:
	-- NoDecoration, NoMove, NoResize, NoBackground, NoSavedSettings, NoInputs
	-- 43 + 4 + 2 + 128 + 256 + 197120
    local flags = 43 + 4 + 2 + 128 + 256 + 197120

    if imgui.begin_window("FullscreenInvisibleWindow", nil, flags) then
		local cursorPos = imgui.get_mouse()
		uevr.api:dispatch_custom_event("MouseX", cursorPos.x)
		uevr.api:dispatch_custom_event("MouseY", cursorPos.y)
		-- print(cursorPos.x);
		-- print(cursorPos.y);
        -- You can put your content here. 
        -- If you want it truly invisible and click-through, 
        -- add ImGuiWindowFlags.NoInputs to the flags above.
        imgui.end_window()
    end




	--imgui.begin_window("hello", true, 0)

end)

uevr.sdk.callbacks.on_lua_event(function(event_name, event_string)
	-- if event_name == "HideHands" then
	-- 	if event_string == "1" then
	-- 		hands.hideHands(true)
	-- 		hideHands = true
	-- 		handsVisible = false
	-- 	else
	-- 		hands.hideHands(false)
	-- 		hideHands = false
	-- 		handsVisible = true
	-- 	end
	-- end

    -- if event_name == "PlayerTookControl" then
	-- 	if event_string =="1" then
	-- 		print("Player took Control lua")
	-- 		handsRequired = true
	-- 	else
	-- 		print("Player lost Control lua")
	-- 		handsRequired = false
	-- 	end
	-- end
end)

