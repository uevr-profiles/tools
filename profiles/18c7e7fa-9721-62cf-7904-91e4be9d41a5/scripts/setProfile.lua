--[[script by slash0mega
Big thank you to DarkSigma and Pande4360 on the Flatscreen to VR for the help. 

Ingame, you will want to set the fov when in first person to either extreem to eleminate LOD artifacts (mostly dirt piles in the road)
and perhaps tweak game resolution and UI scale for comfort, 
I set option>graphics>screen>resolution to 1360x768 and option>gameplay>hud>ui scale to120%

the crosshair is a /little/ low, but the highlights make it fine, 

TODO:
figure out how to change fov (fixes weird LOD when set to extreem numbers)
add a "headset off" state that will switch between old fov and new fov
learn what cvars turns the rain into a visual nightmare
add roomscale and motion controls (mostly just got to rebind stuff.)

]]

--variable section

local currentProfile = 999 --the current profile between on foot(0) or in car(1), gets set so i am not rewriting values forever, defaults to a dumb number to make changeProfile() sets up the defaults

--function section

function setOptions(count)	--call this to set the on foot or driving profile, don't call directly, use changeProfile()
	if count == 0 then 		--on foot
		print("on foot")
		uevr.params.vr.set_aim_method(1)
		uevr.params.vr.set_decoupled_pitch_enabled(true)
		uevr.params.vr.set_mod_value("VR_RoomscaleMovement","true")
		tweakUI(0,-0.074,1.959,0.942)
	elseif count == 1 then	--driving
		print("driving")
		uevr.params.vr.set_aim_method(0)
		uevr.params.vr.set_decoupled_pitch_enabled(false)
		uevr.params.vr.set_mod_value("VR_RoomscaleMovement","false")
		tweakUI(0,0,1.143,0.5)
	else					--out of bounds, its only 2 settings so i could probably do driving if not 1, but meh. 
		print("you fucked up")
	end
end
		
function changeProfile(pro)		--this will check what profile is loading before loading one, so its not rewriting the same values forever. i think that is a good practice? idk i learned lua from minecraft
	if pro == currentProfile then
--		print("nothing to be done, this is a comment because console spam causes lag")
	else
		print("changing settings")
		setOptions(pro)
		currentProfile = pro
	end
end

function tweakUI(xPos,yPos,zPos,size)		--just an easy, single function for tweaking all hud position variables. 
	uevr.params.vr.set_mod_value("UI_Distance",tostring(zPos))
	uevr.params.vr.set_mod_value("UI_X_Offset",tostring(xPos))
	uevr.params.vr.set_mod_value("UI_Y_Offset",tostring(yPos))
	uevr.params.vr.set_mod_value("UI_Size",tostring(size))
end
	

-- the folowing prints the active pawn
-- print(uevr.api:get_local_pawn(0):get_full_name())
-- MTPlayerCharacter_C /Game/Maps/Jeju/Jeju_World.Jeju_World.PersistentLevel.MTPlayerCharacter_C_2147339433

--code section

print("------------------starting------------------")



uevr.sdk.callbacks.on_post_engine_tick(function(engine, delta) --Main loop, run every frame!
	if uevr.api:get_local_pawn(0) then																		--this checks to make sure an active pawn exists, otherwise the get_full_name errors.
			if string.sub(uevr.api:get_local_pawn(0):get_full_name(),0,19) == "MTPlayerCharacter_C" then	--checks if your a human, not a car
				changeProfile(0)
			else 																							--if your in a car do this. 
				changeProfile(1)
			end
	else																									--if you don't exist (main menu) do this! setting to car profile cause menues
		changeProfile(1)
	end
end)

