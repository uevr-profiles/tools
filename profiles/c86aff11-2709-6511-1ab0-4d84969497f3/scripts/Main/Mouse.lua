
require(".\\Subsystems\\GlobalData")

local rotCurr=nil
function SetMouseLocation(player)
	if isMenu and rShoulder then
		--uevr.params.vr.get_pose(WHandIndex, WeaponHand_Pos, WeaponHand_Rot)	
		if rotCurr=nil then
			rotCurr = right_hand_component:K2_GetComponentRotation()
		end	
		local rotTemp = right_hand_component:K2_GetComponentRotation()
		local CurrentLoc = player:GetMouseLocation()
		
		local rotDiff = kismat_math_library:Subtract_VectorVector(rotCurr,rotTemp)
		
		MouseY = CurrentLoc.X + rotDiff.Pitch/45 * 1080
		MouseX = CurrentLoc.Y + rotDiff.Yaw /45*1920
		player:SetMouseLocation(MouseX,MouseY)
	end
	if not rShoulder then
		rotCurr=nil
	end
end


--uevr.sdk.callbacks.on_xinput_get_state(
--function(retval, user_index, state)
--	local dpawn=nil
--	dpawn=api:get_local_pawn(0)
--	--dpawn:Add
--	UpdateInput(state,dpawn)
--		
--end)
--
--
--testX=0
--
--
--
--uevr.sdk.callbacks.on_pre_engine_tick(
--function(engine, delta)
--player= api:get_player_controller(0)
--pawn= api:get_local_pawn(0)
--
--if testX>1900 then testX=0 end
--testX=testX+1
--player:SetMouseLocation(testX,555)
--
--
--
----TempKey.KeyName="C"
----player:WasInputKeyJustPressed(TempKey,true)--.PlayerInput:SetBind("InputTriggerPressed /Game/Blueprints/InputSystem/InputActions/IA_Fire.IA_Fire.InputTriggerPressed_0","Gamepad_LeftTrigger")
----player:InpActEvt_Zero_K2Node_InputKeyEvent_0(TempKey)
--
--
--
--
--end)