local api    = uevr.api
local vr     = uevr.params.vr
local player = api:get_player_controller(0)

-- Hook into HUD draw
local HUDClass = api:find_uobject("Class /Script/Engine.HUD")
local drawFn   = HUDClass:find_function("ReceiveDrawHUD")
drawFn:set_function_flags(drawFn:get_function_flags() | 0x400)
local hudInst  = player:GetHUD()
uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
    local game_engine_class = api:find_uobject("Class /Script/Engine.GameEngine")
    local game_engine = UEVR_UObjectHook.get_first_object_by_class(game_engine_class)
  for _, L in ipairs(CrosshairLayers) do
    local viewport = game_engine.GameViewport
    if viewport == nil then
         L.visible = false
        return
    end
    local world = viewport.World

    if world == nil then
         L.visible = false
         return
    end


    local level = world.PersistentLevel

    if level == nil then
        L.visible = false
        return
    end


    local game_instance = game_engine.GameInstance

    if game_instance == nil then
       L.visible = false
        return
    end

end
end)
-- Max number of crosshair layers
local MAX_LAYERS = 3

-- Available shape types
local SHAPE_TYPES = { "Plus", "X", "Circle" }
-- Available trigger behaviors
local TRIGGERS    = { "None", "HideWhileHeld", "ToggleOnPress" }

-- State: an array of shape-settings tables
local CrosshairLayers = {
  {
    shape           = "Plus",
    length      = 50,
    width       = 50,     -- only used for Plus
    gap         = 5,
    thickness   = 3,
    circle_segs = 32,
    color       = { R=0.8, G=1.0, B=0.8, A=0.7 },
    trigger_idx = 1,      -- 1=None,2=HideWhileHeld,3=ToggleOnPress
    visible     = true,
    prev_lt     = false,
  },
}

-- Draw-hook: loop every layer
local function on_draw(fn, obj, locals, result)
  for _, L in ipairs(CrosshairLayers) do
    if not L.visible then goto continue end

    local w, h  = vr.get_ui_width(), vr.get_ui_height()
    local cx, cy = w*0.5, h*0.5
    -- build color struct
    local col = StructObject.new(
      api:find_uobject("ScriptStruct /Script/CoreUObject.LinearColor")
    )
    col.R, col.G, col.B, col.A =
      L.color.R, L.color.G, L.color.B, L.color.A

    local G, T = L.gap, L.thickness
    local typ   = L.shape

    if typ == "Plus" then
      -- horizontal
      hudInst:DrawLine(cx - G - L.width, cy, cx - G, cy, col, T)
      hudInst:DrawLine(cx + G, cy,           cx + G + L.width, cy, col, T)
      -- vertical
      hudInst:DrawLine(cx, cy - G - L.length, cx, cy - G, col, T)
      hudInst:DrawLine(cx, cy + G,             cx, cy + G + L.length, col, T)

    elseif typ == "X" then
      local L2 = L.length
      hudInst:DrawLine(cx - G - L2, cy - G - L2, cx - G, cy - G, col, T)
      hudInst:DrawLine(cx + G + L2, cy - G - L2, cx + G, cy - G, col, T)
      hudInst:DrawLine(cx - G - L2, cy + G + L2, cx - G, cy + G, col, T)
      hudInst:DrawLine(cx + G + L2, cy + G + L2, cx + G, cy + G, col, T)

    elseif typ == "Circle" then
      local segs = L.circle_segs
      local R    = L.length + G
      for i=0,segs-1 do
        local a1 = i/segs * 2*math.pi
        local a2 = (i+1)/segs * 2*math.pi
        local x1 = cx + math.cos(a1)*R
        local y1 = cy + math.sin(a1)*R
        local x2 = cx + math.cos(a2)*R
        local y2 = cy + math.sin(a2)*R
        hudInst:DrawLine(x1,y1, x2,y2, col, T)
      end
    end

    ::continue::
  end

  return false
end

drawFn:hook_ptr(on_draw, nil)
uevr.sdk.callbacks.on_script_reset(function()
  drawFn:set_function_flags(drawFn:get_function_flags() & ~0x400)
end)

-- Controller callback per-layer
uevr.sdk.callbacks.on_xinput_get_state(function(ret, idx, state)
  for _, L in ipairs(CrosshairLayers) do
    local lt = state.Gamepad.bLeftTrigger ~= 0
    local action = TRIGGERS[L.trigger_idx]

    if action == "HideWhileHeld" then
      L.visible = not lt
    elseif action == "ToggleOnPress" then
      if lt and not L.prev_lt then
        L.visible = not L.visible
      end
    end

    L.prev_lt = lt
  end
end)

-- ImGui panel
uevr.lua.add_script_panel("Crosshair Layers", function()
  -- For each layer: a collapsible group
  for idx, L in ipairs(CrosshairLayers) do
    imgui.push_id(idx)  -- isolate UI IDs

    if imgui.tree_node("Layer "..idx) then
      -- Shape selector
      local changed, newShape = imgui.combo(
        "Shape", L.shape, SHAPE_TYPES
      )
      if changed then L.shape = SHAPE_TYPES[newShape] end

      -- Visibility toggle
      imgui.same_line()
      local vis_c
      vis_c, L.visible = imgui.checkbox("Visible", L.visible)

      -- Trigger action
      local tc, newT = imgui.combo(
        "Trigger", L.trigger_idx - 1, TRIGGERS
      )
      if tc then L.trigger_idx = newT + 1 end

      -- Sliders
      if L.shape == "Plus" then
        local ch, w = imgui.slider_int("Width",  L.width,  0, 200)
        local cl, h = imgui.slider_int("Length", L.length, 0, 200)
        if ch then L.width  = w end
        if cl then L.length = h end

      elseif L.shape == "X" then
        local cL, len = imgui.slider_int("Length", L.length, 0, 200)
        if cL then L.length = len end

      elseif L.shape == "Circle" then
        local cR, len = imgui.slider_int("Radius", L.length, 0, 200)
        if cR then L.length = len end
        local cs, seg = imgui.slider_int(
          "Segments", L.circle_segs, 8, 128
        )
        if cs then L.circle_segs = seg end
      end

      -- Common gap & thickness
      local cg, g = imgui.slider_int("Gap",       L.gap,       0, 100)
      local ct, t = imgui.slider_int("Thickness", L.thickness, 1, 20)
      if cg then L.gap       = g end
      if ct then L.thickness = t end

                -- Color picker
            -- Crosshair color RGBA
          local r_changed, r_val = imgui.slider_float("Color R", L.color.R, 0, 1)
          if r_changed then L.color.R = r_val end
          local g_changed, g_val = imgui.slider_float("Color G", L.color.G, 0, 1)
          if g_changed then L.color.G = g_val end
          local b_changed, b_val = imgui.slider_float("Color B", L.color.B, 0, 1)
          if b_changed then L.color.B = b_val end
          local a_changed, a_val = imgui.slider_float("Alpha", L.color.A, 0, 1)
          if a_changed then L.color.A = a_val end
      -- local colv = { L.color.R, L.color.G, L.color.B, L.color.A }
      -- local cc, newCol = imgui.color_picker("Color", colv)
      -- if cc then
      --   -- L.color.R, L.color.G, L.color.B, L.color.A =
      --   --   newCol[1], newCol[2], newCol[3], newCol[4]
      --   -- colv
      --   L.color = newCol

      -- end

      -- Remove-layer button
      imgui.spacing()
      if imgui.small_button("Remove Layer") then
        table.remove(CrosshairLayers, idx)
        imgui.pop_id()
        return
      end
    imgui.tree_pop()
    end

    imgui.pop_id()
    imgui.new_line()
  end
        if imgui.button("Save Config") then
        json.dump_file("crosshair.json", CrosshairLayers, 4)
       end
        imgui.same_line()
        if imgui.button("Load Config") then
           CrosshairLayers = json.load_file("crosshair.json")
       end
  -- At bottom: Add Layer button
  if #CrosshairLayers < MAX_LAYERS then
    if imgui.button("Add Layer") then
      table.insert(CrosshairLayers, {
        shape_idx   = 1,
        length      = 50,
        width       = 50,
        gap         = 5,
        thickness   = 3,
        circle_segs = 32,
        color       = { R=0.8, G=1.0, B=0.8, A=0.7 },
        trigger_idx = 1,
        visible     = true,
        prev_lt     = false,
      })
    end
  end
end)