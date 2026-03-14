local WeaponOffsets = {

    -- GLOBAL OFFSET MODIFIER (These values are added globally to all weapons,)
	-- this allows gun stock users to fine tune the weapon sights to line up properly. Before resorting to this, see if UEVR's Controller pitch offset setting works well enough first. Alternatively you can use Mrbelowski's controller offset addition
    GlobalOffset = {
        rotation_offset = { x = 0, y = 0, z = 0 },
        location_offset = { x = 0, y = 0, z = 0 }
    },
		--How to easily Calculate the values to Calibrate your gun stock using the global offset:
			--1: once in game with the profile loaded, Load into the game (Shooting range will do)
			--2: open the UEVR overlay by pressing both sticks in, Under LuaLoader, select Main, and press "Spawn Debug Console"
			--3: close the overlay, and equip a weapon you like with the attachments you like
			--4: in the debug console, you will see the weapon name appear, take note of it
			--5: open the UEVR overlay again, and navigate to UObjectHook -> Main -> Common Objects -> Acknowledged Pawn -> Scroll down until you reach FirstPersonArms and press "adjust"
			--6: Line up your gunstock with the gun as best you can, press both sticks in to confirm, play around with the weapon for a bit to confirm it feels nice, do not switch weapons or you will have to adjust again
			--IMPORTANT: DO NOT PRESS SAVE STATE OR YOUR OFFSETS WILL OVERRIDE FOR EVERY WEAPON. (if you do end up doing that, detach the object with the detach button, and switch weapons to have my script reattach it)
			--7: once you have a calibration you are happy with, open the uevr overlay again, and write down the 6 values you have (Rotation Offset XYZ and Position Offset XYZ, these are your calibration results)
			--8: you'll have to do some math, find the weapon you chose in the list below (using the name seen in the console), and subtract that weapon's existing values from your Calibration Results
			--9: enter the results into the global offset field above, save the file, and turn the dynamic offsets script off and on again to reload it (under LuaLoader -> Main)
	
	--PER WEAPON OFFSETS (You probably shouldn't edit these unless you feel I did a bad job with some weapons)
	
    -- Pistols
	-- is_pistol = true tells the script that the weapon is a handgun, and tweaks will be made to the character's pose to feel more aligned with a VR pistol stance
	["BP_1911_C"] = { is_pistol = true, rotation_offset = { x = 0.414, y = 1.448, z = -0.135 }, location_offset = { x = 36.378, y = 168.661, z = 7.624 } },
    ["BP_360J_C"] = { is_pistol = true, rotation_offset = { x = 0.405, y = 1.518, z = -0.024 }, location_offset = { x = 31.330, y = 167.701, z = 4.369 } },
    ["BP_FiveSeven_C"] = { is_pistol = true, rotation_offset = { x = 0.459, y = 1.447, z = -0.130 }, location_offset = { x = 35.305, y = 166.758, z = 7.729 } },
    ["BP_Glock19X_Big_C"] = { is_pistol = true, rotation_offset = { x = 0.427, y = 1.520, z = -0.005 }, location_offset = { x = 34.942, y = 167.218, z = 5.991 } },	
    ["BP_Glock19X_C"] = { is_pistol = true, rotation_offset = { x = 0.385, y = 1.477, z = -0.151 }, location_offset = { x = 32.288, y = 168.256, z = 5.820 } },
    ["BP_Glock19X_Small_C"] = { is_pistol = true, rotation_offset = { x = 0.427, y = 1.520, z = -0.005 }, location_offset = { x = 34.942, y = 167.218, z = 5.991 } },	
    ["BP_M9_C"] = { is_pistol = true, rotation_offset = { x = 0.443, y = 1.417, z = -0.265 }, location_offset = { x = 30.893, y = 167.681, z = 6.463 } },	
    ["BP_P320_C"] = { is_pistol = true, rotation_offset = { x = 0.392, y = 1.481, z = -0.191 }, location_offset = { x = 36.486, y = 165.640, z = 7.903 } },	
    ["BP_SW500L_C"] = { is_pistol = true,  rotation_offset = { x = 0.347, y = 1.523, z = -0.021 }, location_offset = { x = 39.779, y = 162.497, z = 8.849 } },	
    ["BP_SW500S_C"] = { is_pistol = true, rotation_offset = { x = 0.347, y = 1.523, z = -0.021 }, location_offset = { x = 39.779, y = 162.497, z = 8.849 } },	
    ["BP_StealthHunterRevolver_C"] = { is_pistol = true, rotation_offset = { x = 0.397, y = 1.514, z = -0.088 }, location_offset = { x = 35.277, y = 164.030, z = 8.848 } },	
    ["BP_Welrod_C"] = { is_pistol = true, rotation_offset = { x = 0.420, y = 1.535, z = 0.012 }, location_offset = { x = 35.563, y = 165.722, z = 5.828 } },	
	
	-- Primary
    ["BP_AK103_C"] = { rotation_offset = { x = 0.380, y = 1.591, z = 0.039 }, location_offset = { x = 10.648, y = 152.560, z = 4.226 } },
    ["BP_AK104_C"] = { rotation_offset = { x = 0.380, y = 1.591, z = 0.039 }, location_offset = { x = 10.648, y = 152.560, z = 4.226 } },
    ["BP_AK105_C"] = { rotation_offset = { x = 0.380, y = 1.591, z = 0.039 }, location_offset = { x = 10.648, y = 152.560, z = 4.226 } },
    ["BP_AK74M_C"] = { rotation_offset = { x = 0.380, y = 1.591, z = 0.039 }, location_offset = { x = 10.648, y = 152.560, z = 4.226 } },
    ["BP_AKDRACO_C"] = { rotation_offset = { x = 0.340, y = 1.578, z = 0.088 }, location_offset = { x = 14.447, y = 154.468, z = 5.046 } },
    ["BP_AKs74U_C"] = { rotation_offset = { x = 0.340, y = 1.578, z = 0.088 }, location_offset = { x = 14.447, y = 154.468, z = 5.046 } },
    ["BP_ASVAL_C"] = { rotation_offset = { x = 0.370, y = 1.547, z = 0.056 }, location_offset = { x = 10.097, y = 154.878, z = 3.695 } },
    ["BP_Aug_C"] = { rotation_offset = { x = 0.311, y = 1.536, z = 0.067 }, location_offset = { x = 14.739, y = 150.875, z = 5.582 } },
    ["BP_GM6Bloodhound_C"] = { rotation_offset = { x = 0.277, y = 1.528, z = 0.050 }, location_offset = { x = 21.001, y = 148.739, z = 6.245 } },
    ["BP_GM6LYNX_C"] = { rotation_offset = { x = 0.277, y = 1.528, z = 0.050 }, location_offset = { x = 21.001, y = 148.739, z = 6.245 } },
    ["BP_GalilAce_C"] = { rotation_offset = { x = 0.367, y = 1.570, z = 0.065 }, location_offset = { x = 13.581, y = 150.862, z = 5.834 } },
    ["BP_GalilAce_Pistol_C"] = { rotation_offset = { x = 0.367, y = 1.570, z = 0.065 }, location_offset = { x = 13.581, y = 150.862, z = 5.834 } },
    ["BP_LAMG_C"] = { rotation_offset = { x = 0.372, y = 1.529, z = 0.068 }, location_offset = { x = 12.197, y = 151.979, z = 5.551 } },
    ["BP_M1014_C"] = { rotation_offset = { x = 0.367, y = 1.569, z = 0.058 }, location_offset = { x = 13.926, y = 150.568, z = 4.949 } },
    ["BP_M1014_Short_C"] = { rotation_offset = { x = 0.367, y = 1.569, z = 0.058 }, location_offset = { x = 13.926, y = 150.568, z = 4.949 } },
    ["BP_M24_C"] = { rotation_offset = { x = 0.375, y = 1.542, z = 0.085 }, location_offset = { x = 11.982, y = 151.998, z = 6.137 } },
    ["BP_MK17_C"] = { rotation_offset = { x = 0.376, y = 1.567, z = 0.084 }, location_offset = { x = 8.915, y = 151.559, z = 5.563 } },	
    ["BP_MK17_Short_C"] = { rotation_offset = { x = 0.376, y = 1.567, z = 0.084 }, location_offset = { x = 8.915, y = 151.559, z = 5.563 } },	
    ["BP_MK18_C"] = { rotation_offset = { x = 0.360, y = 1.572, z = 0.075 }, location_offset = { x = 14.353, y = 151.913, z = 4.057 } },
    ["BP_MP5A4_C"] = { rotation_offset = { x = 0.366, y = 1.550, z = 0.053 }, location_offset = { x = 15.597, y = 152.188, z = 5.094 } },
    ["BP_MP5A5_C"] = { rotation_offset = { x = 0.366, y = 1.550, z = 0.053 }, location_offset = { x = 15.597, y = 152.188, z = 5.094 } },
    ["BP_MP5KPDW_C"] = { rotation_offset = { x = 0.366, y = 1.550, z = 0.053 }, location_offset = { x = 15.597, y = 152.188, z = 5.094 } },
    ["BP_MP5K_C"] = { rotation_offset = { x = 0.366, y = 1.550, z = 0.053 }, location_offset = { x = 15.597, y = 152.188, z = 5.094 } },
    ["BP_MP5SD5_C"] = { rotation_offset = { x = 0.366, y = 1.550, z = 0.053 }, location_offset = { x = 15.597, y = 152.188, z = 5.094 } },
    ["BP_MP5SD6_C"] = { rotation_offset = { x = 0.366, y = 1.550, z = 0.053 }, location_offset = { x = 15.597, y = 152.188, z = 5.094 } },
    ["BP_MP7_C"] = { rotation_offset = { x = 0.391, y = 1.556, z = 0.046 }, location_offset = { x = 17.085, y = 152.778, z = 7.810 } },
    ["BP_MP9_C"] = { rotation_offset = { x = 0.398, y = 1.550, z = 0.072 }, location_offset = { x = 16.562, y = 151.286, z = 4.792	} },	
    ["BP_Mossberg590_C"] = { rotation_offset = { x = 0.295, y = 1.558, z = 0.049 }, location_offset = { x = 12.489, y = 155.189, z = 5.204 } },
    ["BP_Mossberg590_Shockwave_C"] = { rotation_offset = { x = 0.295, y = 1.558, z = 0.049 }, location_offset = { x = 12.489, y = 155.189, z = 5.204 } },
    ["BP_P90_C"] = { rotation_offset = { x = 0.408, y = 1.544, z = 0.035 }, location_offset = { x = 19.843, y = 150.046, z = 6.942 } },
    ["BP_SA58_C"] = { rotation_offset = { x = 0.411, y = 1.560, z = 0.044 }, location_offset = { x = 16.386, y = 152.469, z = 3.924 } },
    ["BP_SG553RSBR_C"] = { rotation_offset = { x = 0.394, y = 1.574, z = 0.046 }, location_offset = { x = 15.897, y = 149.838, z = 5.537 } },
    ["BP_SG553R_C"] = { rotation_offset = { x = 0.394, y = 1.574, z = 0.046 }, location_offset = { x = 15.897, y = 149.838, z = 5.537 } },
    ["BP_SG553SBR_C"] = { rotation_offset = { x = 0.394, y = 1.574, z = 0.046 }, location_offset = { x = 15.897, y = 149.838, z = 5.537 } },
    ["BP_SG553_C"] = { rotation_offset = { x = 0.394, y = 1.574, z = 0.046 }, location_offset = { x = 15.897, y = 149.838, z = 5.537 } },
    ["BP_SMLE_C"] = { rotation_offset = { x = 0.407, y = 1.549, z = 0.071 }, location_offset = { x = 16.652, y = 149.359, z = 8.358 } },
    ["BP_SR3M_C"] = { rotation_offset = { x = 0.393, y = 1.553, z = 0.071 }, location_offset = { x = 12.163, y = 153.004, z = 3.967 } },
    ["BP_StribogPistol_C"] = { rotation_offset = { x = 0.339, y = 1.587, z = 0.131 }, location_offset = { x = 9.826, y = 150.233, z = 4.789 } },
    ["BP_Stribog_C"] = { rotation_offset = { x = 0.339, y = 1.587, z = 0.131 }, location_offset = { x = 9.826, y = 150.233, z = 4.789 } },
    ["BP_Tavor_C"] = { rotation_offset = { x = 0.351, y = 1.553, z = 0.087 }, location_offset = { x = 21.595, y = 150.965, z = 4.174 } },
    ["BP_UMP45_C"] = { rotation_offset = { x = 0.369, y = 1.532, z = 0.078 }, location_offset = { x = 17.816, y = 148.509, z = 5.255 } },
    ["BP_VSS_C"] = { rotation_offset = { x = 0.360, y = 1.581, z = 0.069 }, location_offset = { x = 11.676, y = 152.554, z = 4.434 } },	
	
	-- Utility
    ["BP_3199HatchlingThrowable_C"] = { rotation_offset = { x = 0.708, y = 1.104, z = 0.267 }, location_offset = { x = 32.082, y = 154.344, z = 16.600 } },
    ["BP_Baton_C"] = { rotation_offset = { x = 0.197, y = 1.525, z = -0.061 }, location_offset = { x = 33.087, y = 150.998, z = 21.909 } },
    ["BP_BetterChemlight_C"] = { rotation_offset = { x = 0.738, y = 1.241, z = -0.288 }, location_offset = { x = 30.181, y = 144.953, z = 17.382 } },
    ["BP_Chemlight_C"] = { rotation_offset = { x = 0.922, y = 1.041, z = -0.397 }, location_offset = { x = 35.723, y = 146.567, z = 14.903 } },
    ["BP_Cleaver_C"] = { rotation_offset = { x = 1.110, y = 1.185, z = -0.544 }, location_offset = { x = 28.261, y = 150.298, z = 28.234 } },
    ["BP_Flare_C"] = { rotation_offset = { x = 0.960, y = 1.102, z = -0.532 }, location_offset = { x = 35.349, y = 145.306, z = 19.324 } },
    ["BP_FryingPan_C"] = { rotation_offset = { x = 0.827, y = 1.492, z = -0.323 }, location_offset = { x = 38.990, y = 143.595, z = 31.502 } },
    ["BP_Hammer_C"] = { rotation_offset = { x = 0.871, y = 1.444, z = -0.389 }, location_offset = { x = 36.617, y = 143.770, z = 31.275 } },
    ["BP_Katana_C"] = { rotation_offset = { x = 0.673, y = 1.714, z = 0.235 }, location_offset = { x = 33.378, y = 135.246, z = 17.157 } },
    ["BP_M24Grenade_C"] = { rotation_offset = { x = 0.875, y = 1.336, z = 0.312 }, location_offset = { x = 29.653, y = 149.394, z = 19.150 } },
    ["BP_M67_C"] = { rotation_offset = { x = -0.094, y = 1.434, z = 0.024 }, location_offset = { x = 27.509, y = 149.900, z = 12.729 } },
    ["BP_MonkeyWrench_C"] = { rotation_offset = { x = 0.606, y = 1.458, z = -0.229 }, location_offset = { x = 35.016, y = 143.099, z = 30.718 } },	
    ["BP_Mothroach_Throwable_C"] = { rotation_offset = { x = 0.700, y = 0.964, z = -0.116 }, location_offset = { x = 31.826, y = 157.694, z = 20.639 } },	
    ["BP_NoiseMaker_C"] = { rotation_offset = { x = 0.411, y = 1.515, z = -0.001 }, location_offset = { x = 26.803, y = 161.181, z = 25.281 } },	
    ["BP_Pen_C"] = { rotation_offset = { x = 0.258, y = 1.274, z = -0.479 }, location_offset = { x = 29.172, y = 155.883, z = 12.520 } },
    ["BP_Pencil_C"] = { rotation_offset = { x = 0.258, y = 1.274, z = -0.479 }, location_offset = { x = 29.172, y = 155.883, z = 12.520 } },
    ["BP_Pipe_C"] = { rotation_offset = { x = 0.492, y = 1.655, z = 0.258 }, location_offset = { x = 29.547, y = 137.645, z = 16.665 } },
    ["BP_Rock_C"] = { rotation_offset = { x = 0.855, y = 1.499, z = 0.005 }, location_offset = { x = 31.893, y = 147.135, z = 19.821 } },
    ["BP_RubberDucky_C"] = { rotation_offset = { x = 0.918, y = 1.149, z = -0.342 }, location_offset = { x = 29.044, y = 153.260, z = 15.151 } },	
    ["BP_Scissors_C"] = { rotation_offset = { x = 0.595, y = 1.363, z = -0.273 }, location_offset = { x = 34.020, y = 149.901, z = 21.815 } },
    ["BP_Screwdriver_C"] = { rotation_offset = { x = 0.823, y = 1.345, z = -0.073 }, location_offset = { x = 25.409, y = 155.061, z = 11.102 } },	
    ["BP_Stronglite_C"] = { rotation_offset = { x = 0.681, y = 1.417, z = 0.034 }, location_offset = { x = 29.678, y = 148.991, z = 19.678 } },	
    ["BP_TacKnife_C"] = { rotation_offset = { x = 0.293, y = 1.104, z = -0.760 }, location_offset = { x = 30.030, y = 154.333, z = 12.145 } },	
    ["BP_TireIron_C"] = { rotation_offset = { x = 0.446, y = 1.775, z = -0.276 }, location_offset = { x = 36.007, y = 143.512, z = 34.379 } },	
	
	-- Utility
    ["BP_Tablet_C"] = { rotation_offset = { x = 0.771, y = 1.463, z = -0.071 }, location_offset = { x = 28.913, y = 165.314, z = 13.668 } },

}

return WeaponOffsets
