local controllers = require("libs/controllers")
local M = {}

local handPositions = {}

--when holding a weapon in the right hand
handPositions["right_trigger_weapon"] = {}
handPositions["right_trigger_weapon"]["on"] = {}
handPositions["right_trigger_weapon"]["on"]["RightHandIndex1_JNT"] = {13.954909324646, 19.658151626587, 12.959843635559}
handPositions["right_trigger_weapon"]["on"]["RightHandIndex2_JNT"] = {-7.2438044548035, 66.065002441406, -3.0500452518463}
handPositions["right_trigger_weapon"]["on"]["RightHandIndex3_JNT"] = {-4.330756187439, 11.854818344116, -4.8701190948486}
handPositions["right_trigger_weapon"]["off"] = {}
handPositions["right_trigger_weapon"]["off"]["RightHandIndex1_JNT"] = {13.954922676086, 14.658146858215, 12.959842681885}
handPositions["right_trigger_weapon"]["off"]["RightHandIndex2_JNT"] = {-7.2438387870789, 36.064968109131, -3.0500030517578}
handPositions["right_trigger_weapon"]["off"]["RightHandIndex3_JNT"] = {-4.330756187439, 11.854819297791, -4.8701119422913}

handPositions["right_grip_weapon"] = {}
handPositions["right_grip_weapon"]["on"] = {}
handPositions["right_grip_weapon"]["on"]["RightHandThumb1_JNT"] = {-36.203144073486, 34.766864776611, -85.575454711914}
handPositions["right_grip_weapon"]["on"]["RightHandThumb2_JNT"] = {11.012476921082, 42.293972015381, -40.077541351318}
handPositions["right_grip_weapon"]["on"]["RightHandThumb3_JNT"] = {-7.0980415344238, 8.2054109573364, -4.4765815734863}
--dont move the index finger as part of the grip. It moves separately
-- handPositions["right_grip_weapon"]["on"]["RightHandIndex1_JNT"] = {13.954929351807, 14.658153533936, 12.959844589233}
-- handPositions["right_grip_weapon"]["on"]["RightHandIndex2_JNT"] = {-7.2438387870789, 36.064979553223, -3.0500068664551}
-- handPositions["right_grip_weapon"]["on"]["RightHandIndex3_JNT"] = {-4.330756187439, 11.854824066162, -4.8701167106628}
handPositions["right_grip_weapon"]["on"]["RightHandMiddle1_JNT"] = {3.2178385257721, 27.142356872559, 2.3389554023743}
handPositions["right_grip_weapon"]["on"]["RightHandMiddle2_JNT"] = {-27.03067779541, 137.21624755859, -2.6563432216644}
handPositions["right_grip_weapon"]["on"]["RightHandMiddle3_JNT"] = {9.8199949264526, 49.10147857666, 6.0561528205872}
handPositions["right_grip_weapon"]["on"]["RightHandRing1_JNT"] = {-18.489757537842, 24.656513214111, 2.7107570171356}
handPositions["right_grip_weapon"]["on"]["RightHandRing2_JNT"] = {-37.691459655762, 128.56390380859, -15.069981575012}
handPositions["right_grip_weapon"]["on"]["RightHandRing3_JNT"] = {5.6724443435669, 63.004455566406, 5.0134029388428}
handPositions["right_grip_weapon"]["on"]["RightHandPinky1_JNT"] = {-30.595754623413, 12.251677513123, 1.6611989736557}
handPositions["right_grip_weapon"]["on"]["RightHandPinky2_JNT"] = {-58.668590545654, 75.370979309082, -16.722003936768}
handPositions["right_grip_weapon"]["on"]["RightHandPinky3_JNT"] = {-21.26050567627, 28.24077796936, 20.569374084473}

--when not holding a weapon in the right hand




handPositions["right_grip"] = {}
handPositions["right_grip"]["on"] = {}
handPositions["right_grip"]["on"]["thumb_r_01"] = {-4.781132156495e-05, 30.000066757202, 0.00019221004913561}
handPositions["right_grip"]["on"]["thumb_r_claw"] = {4.9999508857727, -4.9999241828918, 15.000334739685}
handPositions["right_grip"]["on"]["elbowTwist01_r"] = {6.8301887949929e-06, 10.000022888184, 2.0731060885737e-06}
handPositions["right_grip"]["on"]["index_r_01"] = {6.8301887949929e-06, 15.000160217285, 5.0000047683716}
handPositions["right_grip"]["on"]["index_r_02"] = {6.8301887949929e-06, 3.9273585571209e-05, 1.1952831300732e-05}
handPositions["right_grip"]["on"]["index_r_claw"] = {6.8301887949929e-06, 2.0292742192396e-05, -15.000015258789}
handPositions["right_grip"]["on"]["middle_r_01"] = {-5.4641510359943e-05, 10.000027656555, -5.0000252723694}
handPositions["right_grip"]["on"]["middle_r_02"] = {-2.0490566384979e-05, -6.4033006310638e-06, -1.7075460618798e-06}
handPositions["right_grip"]["on"]["middle_r_claw"] = {-1.3660377589986e-05, 4.4396230805432e-05, -2.7320762455929e-05}
handPositions["right_grip"]["on"]["ring_r_01"] = {-6.8301887949929e-06, 2.4759438019828e-05, -4.0981132769957e-05}
handPositions["right_grip"]["on"]["ring_r_02"] = {1.3660377589986e-05, 3.3297168556601e-05, -3.4150903047703e-06}
handPositions["right_grip"]["on"]["ring_r_claw"] = {3.4150943974964e-05, 5.3397769079311e-05, -5.0000643730164}
handPositions["right_grip"]["on"]["pinkie_r_01"] = {2.7320755179971e-05, -4.9999551773071, 5.6319836403418e-06}
handPositions["right_grip"]["on"]["pinkie_r_02"] = {1.3660377589986e-05, 3.6712262954097e-05, 3.4150973533542e-06}
handPositions["right_grip"]["on"]["pinkie_r_claw"] = {0.0, 2.0490564565989e-05, -1.7075470168493e-05}
handPositions["right_grip"]["off"] = {}
handPositions["right_grip"]["off"]["thumb_r_01"] = {-6.8301887949929e-05, 54.999034881592, 5.0004544258118}
handPositions["right_grip"]["off"]["thumb_r_claw"] = {5.0000190734863, -4.9996304512024, -149.99949645996}
handPositions["right_grip"]["off"]["elbowTwist01_r"] = {-4.0981132769957e-05, 10.000111579895, 4.9334703362547e-06}
handPositions["right_grip"]["off"]["index_r_01"] = {-0.00027320755179971, 15.001339912415, -24.99941444397}
handPositions["right_grip"]["off"]["index_r_02"] = {-0.0001912452862598, 24.999784469604, 40.000366210938}
handPositions["right_grip"]["off"]["index_r_claw"] = {0.0016529057174921, 36.724685668945, -166.74029541016}
handPositions["right_grip"]["off"]["middle_r_01"] = {-0.00040981132769957, 5.0007271766663, -4.999653339386}
handPositions["right_grip"]["off"]["middle_r_02"] = {-0.00089475471759215, 19.999828338623, -9.9984941482544}
handPositions["right_grip"]["off"]["middle_r_claw"] = {-0.00049860379658639, 9.7814023320097e-05, -174.99983215332}
handPositions["right_grip"]["off"]["ring_r_01"] = {-9.56226431299e-05, -5.1225347306172e-06, -0.00012763915583491}
handPositions["right_grip"]["off"]["ring_r_02"] = {-0.00010245283192489, 1.5065320440044e-05, -14.999568939209}
handPositions["right_grip"]["off"]["ring_r_claw"] = {2.7320755179971e-05, 7.2369480221823e-06, -174.99989318848}
handPositions["right_grip"]["off"]["pinkie_r_01"] = {0.00031418868456967, -9.9998760223389, 10.000162124634}
handPositions["right_grip"]["off"]["pinkie_r_02"] = {-3.4150943974964e-05, 5.5098687880673e-05, -44.99967956543}
handPositions["right_grip"]["off"]["pinkie_r_claw"] = {-0.00045079246046953, -0.00028586230473593, -145.00004577637}





uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)
if controllers.getController(0) ~=nil and controllers.getController(1)~=nil then
	LVec= controllers.getController(0):K2_GetComponentRotation() -- LeftCompRotation
	RVec= controllers.getController(1):K2_GetComponentRotation() -- RightRotator
	if LVec ~=nil then
		handPositions["left_grip"]["on"]["Root"        ]  =  {LVec.X,LVec.Y,LVec.Z}
		handPositions["left_grip"]["off"]["Root"        ] = {LVec.X,LVec.Y,LVec.Z}
		handPositions["right_grip"]["on"]["Root"        ]  =  {RVec.X,RVec.Y,RVec.Z}
		handPositions["right_grip"]["off"]["Root"        ] = {RVec.X,RVec.Y,RVec.Z}
	end
end
end)












handPositions["right_trigger"] = {}
handPositions["right_trigger"]["on"] = {}
handPositions["right_trigger"]["on"]["RightHandIndex1_JNT"] = {3.9550070762634, 64.658241271973, 7.9599676132202}
handPositions["right_trigger"]["on"]["RightHandIndex2_JNT"] = {-7.2439274787903, 106.06492614746, -3.0500290393829}
handPositions["right_trigger"]["on"]["RightHandIndex3_JNT"] = {5.6692137718201, 31.855098724365, -34.870063781738}
handPositions["right_trigger"]["off"] = {}
handPositions["right_trigger"]["off"]["RightHandIndex1_JNT"] = {-5.4112854003906, 10.378118515015, -0.9175192117691}
handPositions["right_trigger"]["off"]["RightHandIndex2_JNT"] = {-1.4336975812912, 23.672792434692, -0.97983050346375}
handPositions["right_trigger"]["off"]["RightHandIndex3_JNT"] = {0.0, -8.5377348568727e-07, 0.0}

handPositions["right_thumb"] = {}
handPositions["right_thumb"]["on"] = {}
handPositions["right_thumb"]["on"]["RightHandThumb1_JNT"] = {-36.203105926514, 44.766750335693, -85.575386047363}
handPositions["right_thumb"]["on"]["RightHandThumb2_JNT"] = {11.012429237366, 42.29390335083, -40.077499389648}
handPositions["right_thumb"]["on"]["RightHandThumb3_JNT"] = {-7.0979390144348, 43.205421447754, -4.4764862060547}
handPositions["right_thumb"]["off"] = {}
handPositions["right_thumb"]["off"]["RightHandThumb1_JNT"] = {-44.386493682861, 22.437026977539, -76.045600891113}
handPositions["right_thumb"]["off"]["RightHandThumb2_JNT"] = {4.0847191810608, 18.195903778076, -11.097467422485}
handPositions["right_thumb"]["off"]["RightHandThumb3_JNT"] = {0.0, 0.0, 0.0}


--left hand
handPositions["left_trigger"] = {}
handPositions["left_trigger"]["on"] = {}
handPositions["left_trigger"]["on"]["LeftHandIndex1_JNT"] = {7.3522610664368, 68.381980895996, 3.1531522274017}
handPositions["left_trigger"]["on"]["LeftHandIndex2_JNT"] = {5.532808303833, 85.33113861084, 39.128715515137}
handPositions["left_trigger"]["on"]["LeftHandIndex3_JNT"] = {4.436897277832, 46.554878234863, 2.77498960495}
handPositions["left_trigger"]["off"] = {}
-- handPositions["left_trigger"]["off"]["LeftHandIndex1_JNT"] = {-7.6476874351501, 18.381666183472, 3.1531648635864}
-- handPositions["left_trigger"]["off"]["LeftHandIndex2_JNT"] = {5.5328216552734, 10.331413269043, 4.1289820671082}
-- handPositions["left_trigger"]["off"]["LeftHandIndex3_JNT"] = {4.4370613098145, -3.4452188014984, 2.7750282287598}
handPositions["left_trigger"]["off"]["LeftHandIndex1_JNT"] = {5.4113330841064, 10.378183364868, 0.91737693548203}
handPositions["left_trigger"]["off"]["LeftHandIndex2_JNT"] = {1.4339435100555, 23.6731300354, 0.97924590110779}
handPositions["left_trigger"]["off"]["LeftHandIndex3_JNT"] = {0.0, 0.0, 0.0}
















handPositions["left_grip"] = {}
handPositions["left_grip"]["on"] = {}
handPositions["left_grip"]["on"]["thumb_l_01"] = {-16.033464431763, 23.64910697937, -34.04708480835}
handPositions["left_grip"]["on"]["thumb_l_claw"] = {-6.8301887949929e-06, -6.8806825765932e-06, 81.800483703613}
handPositions["left_grip"]["on"]["elbowTwist01_l"] = {-6.8301887949929e-06, 1.0245280464005e-05, 4.2688676330727e-05}
handPositions["left_grip"]["on"]["index_l_01"] = {-2.0666239261627, 11.298978805542, -0.64853477478027}
handPositions["left_grip"]["on"]["index_l_02"] = {0.0, 1.5902772534156e-15, 2.1344335721096e-07}
handPositions["left_grip"]["on"]["index_l_claw"] = {-2.0490566384979e-05, -0.00014219731383491, 16.847848892212}
handPositions["left_grip"]["on"]["middle_l_01"] = {-1.6867219209671, 11.74921131134, -0.88481366634369}
handPositions["left_grip"]["on"]["middle_l_02"] = {0.0, 3.4150943974964e-06, 2.1984667910147e-05}
handPositions["left_grip"]["on"]["middle_l_claw"] = {0.00026637734845281, -1.5374060239992e-05, -0.002622578991577}
handPositions["left_grip"]["on"]["ring_l_01"] = {-1.0476211309433, 6.0403280258179, -0.55846619606018}
handPositions["left_grip"]["on"]["ring_l_02"] = {-6.8301887949929e-06, -5.7727065315427e-13, 1.2913324098918e-05}
handPositions["left_grip"]["on"]["ring_l_claw"] = {1.3660377589986e-05, -0.00011607984924922, 19.997554779053}
handPositions["left_grip"]["on"]["pinkie_l_01"] = {-0.47130352258682, -2.9747505187988, 0.09583618491888}
handPositions["left_grip"]["on"]["pinkie_l_02"] = {-2.0490566384979e-05, 1.7075441292036e-06, 1.8729657313088e-05}
handPositions["left_grip"]["on"]["pinkie_l_claw"] = {-9.56226431299e-05, -0.00010137369827135, 19.997800827026}
handPositions["left_grip"]["off"] = {}
handPositions["left_grip"]["off"]["thumb_l_01"] = {-16.033922195435, 23.650197982788, -4.0489630699158}
handPositions["left_grip"]["off"]["thumb_l_claw"] = {0.0001912452862598, -0.00039656751323491, -138.19941711426}
handPositions["left_grip"]["off"]["elbowTwist01_l"] = {0.0, 2.9028289645794e-05, 5.1226393225079e-06}
handPositions["left_grip"]["off"]["index_l_01"] = {-2.0664532184601, 21.298210144043, 34.350917816162}
handPositions["left_grip"]["off"]["index_l_02"] = {-0.00028003775514662, -0.00016132979362737, -20.000062942505}
handPositions["left_grip"]["off"]["index_l_claw"] = {8.1962265539914e-05, -0.00058946118224412, -153.1515045166}
handPositions["left_grip"]["off"]["middle_l_01"] = {-1.6868858337402, 16.749402999878, 54.115020751953}
handPositions["left_grip"]["off"]["middle_l_02"] = {-0.00020490566384979, -0.00014462188119069, -49.999771118164}
handPositions["left_grip"]["off"]["middle_l_claw"] = {-9.56226431299e-05, -0.00025750091299415, -130.0018157959}
handPositions["left_grip"]["off"]["ring_l_01"] = {-1.0476416349411, 1.0402909517288, 44.441135406494}
handPositions["left_grip"]["off"]["ring_l_02"] = {-0.00018441509746481, -0.00013776843843516, -29.999914169312}
handPositions["left_grip"]["off"]["ring_l_claw"] = {-0.00013660377589986, -4.3369866034482e-05, -135.00169372559}
handPositions["left_grip"]["off"]["pinkie_l_01"] = {-0.47115325927734, -12.975063323975, 45.09557723999}
handPositions["left_grip"]["off"]["pinkie_l_02"] = {-6.8301887949929e-06, -6.3975850935094e-05, -35.000179290771}
handPositions["left_grip"]["off"]["pinkie_l_claw"] = {-0.00048494338989258, 0.00017628961359151, -130.00170898438}

handPositions["left_thumb"] = {}
handPositions["left_thumb"]["on"] = {}
handPositions["left_thumb"]["on"]["LeftHandThumb1_JNT"] = {29.340223312378, 14.388812065125, 65.486557006836}
handPositions["left_thumb"]["on"]["LeftHandThumb2_JNT"] = {-10.78872013092, 33.845855712891, 13.92786693573}
handPositions["left_thumb"]["on"]["LeftHandThumb3_JNT"] = {-1.547474861145, -4.5875172615051, 0.33850952982903}
handPositions["left_thumb"]["off"] = {}
handPositions["left_thumb"]["off"]["LeftHandThumb1_JNT"] = {34.340190887451, 14.38916015625, 65.486839294434}
handPositions["left_thumb"]["off"]["LeftHandThumb2_JNT"] = {-10.788597106934, 13.845867156982, 13.92795753479}
handPositions["left_thumb"]["off"]["LeftHandThumb3_JNT"] = {-1.5474680662155, -4.5875201225281, 0.33849230408669}

local poses = {}
poses["open_left"] = { {"left_grip","off"}, {"left_trigger","off"}, {"left_thumb","off"} }
poses["open_right"] = { {"right_grip","off"}, {"right_trigger","off"}, {"right_thumb","off"} }
poses["grip_right_weapon"] = { {"right_grip_weapon","on"}, {"right_trigger_weapon","off"} }

M.positions = handPositions
M.poses = poses

return M




