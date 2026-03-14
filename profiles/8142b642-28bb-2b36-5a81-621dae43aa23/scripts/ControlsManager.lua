require(".\\Subsystems\\UEHelper")

local api = uevr.api
local params = uevr.params
local callbacks = params.sdk.callbacks
local vr=uevr.params.vr
local isShoulderPressedL=false
local isShoulderPressedR=false

local function UpdateGrab(dstate)
	if CanGrabEnemyL and lShoulder and not isShoulderPressedL and not IsGrabbingR then
		--isShoulderPressedL=true
		IsGrabbingL =true
	end
	if CanGrabEnemyR and rShoulder and not isShoulderPressedR and not IsGrabbingL then
		--isShoulderPressedR=true
		IsGrabbingR =true
	end
	
	if IsGrabbingL  then
		pressButton(dstate,XINPUT_GAMEPAD_RIGHT_SHOULDER)
		uevr.params.vr.set_mod_value("VR_AimMethod", "3")
	end
	if IsGrabbingR  then
		pressButton(dstate,XINPUT_GAMEPAD_RIGHT_SHOULDER)
		uevr.params.vr.set_mod_value("VR_AimMethod", "2")
	end
	
	if  IsGrabbingL and not lShoulder then
		IsGrabbingL=false	
			uevr.params.vr.set_mod_value("VR_AimMethod", "1")
	end
	if  IsGrabbingR and not rShoulder then
		IsGrabbingR=false		
	end
	
	if lShoulder then
		isShoulderPressedL=true
	else isShoulderPressedL=false
	end
	if rShoulder then
		isShoulderPressedR=true
	else isShoulderPressedR=false
	end
end
local ReloadDel=0
local isReloading=false
local SubmittedDelta =0
local function UpdateReload(dstate)
	if CanReload and lShoulder then
		isReloading=true
		--pressButton(dstate,XINPUT_GAMEPAD_Y)
	end
	if SubmittedDelta>0 and SubmittedDelta<1 then
		pressButton(dstate,XINPUT_GAMEPAD_Y)
		SubmittedDelta=0
	elseif SubmittedDelta>1 then
		pressButton(dstate,XINPUT_GAMEPAD_DPAD_DOWN)
		SubmittedDelta=0
	end
end

local function UpdateReloadDelta(ddelta)
	if isReloading then
		ReloadDel=ReloadDel+ddelta
	end
	if isReloading and not lShoulder then
		isReloading=false
		SubmittedDelta=ReloadDel
		ReloadDel=0		
	end
end

local function UpdateCounter(dstate)
	if IsCounter then
		pressButton(dstate,XINPUT_GAMEPAD_X)
		IsCounter=false
	end
end

uevr.sdk.callbacks.on_xinput_get_state(
function(retval, user_index, state)
local dpawn=nil
dpawn=api:get_local_pawn(0)
local player=api:get_player_controller(0)


	--UnpressButtons
if dpawn~=nil then	
	if not isMenu and not dpawn.IsDead then	
		unpressButton(state,XINPUT_GAMEPAD_RIGHT_SHOULDER)
		unpressButton(state,XINPUT_GAMEPAD_LEFT_SHOULDER)
		unpressButton(state,XINPUT_GAMEPAD_A)
		--unpressButton(state,XINPUT_GAMEPAD_DPAD_UP)
		state.Gamepad.bLeftTrigger=0
		if dpawn.SecondaryWeapon~=nil and not dpawn.PrimaryEquipped then
			if string.find(dpawn.SecondaryWeapon:get_full_name(), "Katana") or string.find(dpawn.SecondaryWeapon:get_full_name(), "Bat") then
				state.Gamepad.bRightTrigger=0	
			end
		end
		if Abutton then
			pressButton(state,XINPUT_GAMEPAD_B)
		end	
		if ThumbRY > 28000 and not isKick then
			isKick=true
			pressButton(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
		elseif math.abs(ThumbRY)<1000 then
			isKick=false
		end
		if ThumbRY < -28000 and not isDodge then
			isDodge=true
			pressButton(state, XINPUT_GAMEPAD_A)
		elseif math.abs(ThumbRY)<1000 then
			isDodge=false
		end
		UpdateCounter(state)
		UpdateReload(state)
		UpdateGrab(state)
	end
end
end)

uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)

UpdateReloadDelta(delta)


end)