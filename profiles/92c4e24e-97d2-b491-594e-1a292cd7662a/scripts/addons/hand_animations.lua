
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
handPositions["right_grip"]["on"]["RightHandThumb1_JNT"] = {-36.203105926514, 44.766750335693, -85.575386047363}
handPositions["right_grip"]["on"]["RightHandThumb2_JNT"] = {11.012429237366, 42.29390335083, -40.077499389648}
handPositions["right_grip"]["on"]["RightHandThumb3_JNT"] = {-7.0979390144348, 43.205421447754, -4.4764862060547}
--dont move the index finger as part of the grip. It moves separately
-- handPositions["right_grip"]["on"]["RightHandIndex1_JNT"] = {3.9550070762634, 64.658241271973, 7.9599676132202}
-- handPositions["right_grip"]["on"]["RightHandIndex2_JNT"] = {-7.2439274787903, 106.06492614746, -3.0500290393829}
-- handPositions["right_grip"]["on"]["RightHandIndex3_JNT"] = {5.6692137718201, 31.855098724365, -34.870063781738}
handPositions["right_grip"]["on"]["RightHandMiddle1_JNT"] = {-1.7821055650711, 57.142044067383, 17.339141845703}
handPositions["right_grip"]["on"]["RightHandMiddle2_JNT"] = {-7.030668258667, 142.21611022949, 12.343898773193}
handPositions["right_grip"]["on"]["RightHandMiddle3_JNT"] = {9.8199949264526, 49.101493835449, 6.0561537742615}
handPositions["right_grip"]["on"]["RightHandRing1_JNT"] = {-33.489711761475, 49.65669631958, -12.289658546448}
handPositions["right_grip"]["on"]["RightHandRing2_JNT"] = {-27.691537857056, 143.56373596191, -25.069917678833}
handPositions["right_grip"]["on"]["RightHandRing3_JNT"] = {5.6724443435669, 63.004455566406, 5.0134048461914}
handPositions["right_grip"]["on"]["RightHandPinky1_JNT"] = {-40.595561981201, 37.251636505127, -8.3391942977905}
handPositions["right_grip"]["on"]["RightHandPinky2_JNT"] = {-53.668056488037, 140.37017822266, -86.721374511719}
handPositions["right_grip"]["on"]["RightHandPinky3_JNT"] = {-21.260492324829, 28.240776062012, 20.569372177124}
handPositions["right_grip"]["off"] = {}
handPositions["right_grip"]["off"]["RightHandThumb1_JNT"] = {-44.386493682861, 22.437026977539, -76.045600891113}
handPositions["right_grip"]["off"]["RightHandThumb2_JNT"] = {4.0847191810608, 18.195903778076, -11.097467422485}
handPositions["right_grip"]["off"]["RightHandThumb3_JNT"] = {0.0, 0.0, 0.0}
--handPositions["right_grip"]["off"]["RightHandIndex1_JNT"] = {-5.4112854003906, 10.378118515015, -0.9175192117691}
--handPositions["right_grip"]["off"]["RightHandIndex2_JNT"] = {-1.4336975812912, 23.672792434692, -0.97983050346375}
--handPositions["right_grip"]["off"]["RightHandIndex3_JNT"] = {0.0, -8.5377348568727e-07, 0.0}
handPositions["right_grip"]["off"]["RightHandMiddle1_JNT"] = {5.9782729148865, 2.1833770275116, -4.0905966758728}
handPositions["right_grip"]["off"]["RightHandMiddle2_JNT"] = {-28.41870880127, 74.714668273926, 27.525941848755}
handPositions["right_grip"]["off"]["RightHandMiddle3_JNT"] = {0.0, 3.3350531225551e-07, -1.5530051302887e-16}
handPositions["right_grip"]["off"]["RightHandRing1_JNT"] = {-3.3767223358154, 4.1980667114258, -7.3919062614441}
handPositions["right_grip"]["off"]["RightHandRing2_JNT"] = {-45.109657287598, 79.521903991699, 17.716226577759}
handPositions["right_grip"]["off"]["RightHandRing3_JNT"] = {0.0, 3.7352592130446e-07, 0.0}
handPositions["right_grip"]["off"]["RightHandPinky1_JNT"] = {-9.5717582702637, 3.7818260192871, -1.7375682592392}
handPositions["right_grip"]["off"]["RightHandPinky2_JNT"] = {-23.376274108887, 30.071979522705, 5.2131567001343}
handPositions["right_grip"]["off"]["RightHandPinky3_JNT"] = {0.0, 1.7075471987482e-06, -2.544443605465e-14}

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
handPositions["left_grip"]["on"]["thumb_1_LE"] = {-58.639223898252, -13.934154360899, 54.081712130158}
handPositions["left_grip"]["on"]["thumb_2_LE"] = {1.7322600609012e-05, -39.999998269898, 3.6274461781915e-05}
handPositions["left_grip"]["on"]["thumb_3_LE"] = {-3.7040221904564e-06, -63.042103980742, -1.1347323860096e-05}
handPositions["left_grip"]["on"]["index_2_LE"] = {-6.1350551107868, -74.051558049505, 5.0000035098968}
handPositions["left_grip"]["on"]["index_3_LE"] = {-6.2156712138225e-05, -54.637251476399, 9.1543515456419e-05}
handPositions["left_grip"]["on"]["index_4_LE"] = {5.6040194742042e-05, -52.234811946118, -6.4677235417179e-05}
handPositions["left_grip"]["on"]["middle_2_LE"] = {-2.5498594915438, -74.340647456821, -2.1117809645781e-05}
handPositions["left_grip"]["on"]["middle_3_LE"] = {1.5174689833973e-06, -48.128530704764, 4.5635969723885e-06}
handPositions["left_grip"]["on"]["middle_4_LE"] = {-2.8772785391599e-05, -63.467956543429, 9.7621895837685e-05}
handPositions["left_grip"]["on"]["ring_2_LE"] = {2.3617286995183, -80.282469194715, -1.4143034966146e-09}
handPositions["left_grip"]["on"]["ring_3_LE"] = {4.4955168917309e-06, -43.811704123002, 2.8540816368936e-13}
handPositions["left_grip"]["on"]["ring_4_LE"] = {-2.7354199164729e-06, -61.424581873767, 9.7503597772528e-06}
handPositions["left_grip"]["on"]["pinky_2_LE"] = {2.2591228411136, -87.101338593896, -5.0711374367522}
handPositions["left_grip"]["on"]["pinky_3_LE"] = {-0.00010403210795151, -45.994186236877, 0.00011652381594299}
handPositions["left_grip"]["on"]["pinky_4_LE"] = {4.6093473632288e-05, -54.00798649564, 4.0022472089715e-05}


handPositions["left_grip"]["off"] = {}
handPositions["left_grip"]["off"]["thumb_1_LE"] = {-53.639223898248, -3.9341543608976, 54.081712130162}
handPositions["left_grip"]["off"]["thumb_2_LE"] = {1.7322600768738e-05, -24.999998269898, 3.6274461887651e-05}
handPositions["left_grip"]["off"]["thumb_3_LE"] = {-3.7040220615891e-06, -23.042103980742, -1.1347323965875e-05}
handPositions["left_grip"]["off"]["index_2_LE"] = {-6.1350551107866, -34.051558049505, 5.0000035098971}
handPositions["left_grip"]["off"]["index_3_LE"] = {-6.2156712051604e-05, -19.637251476399, 9.15435155626e-05}
handPositions["left_grip"]["off"]["index_4_LE"] = {5.6040195609272e-05, -27.234811946118, -6.4677236612173e-05}
handPositions["left_grip"]["off"]["middle_2_LE"] = {-2.5498594915437, -34.340647456821, -2.1117809672843e-05}
handPositions["left_grip"]["off"]["middle_3_LE"] = {1.5174689522932e-06, -23.128530704764, 4.5635970225456e-06}
handPositions["left_grip"]["off"]["middle_4_LE"] = {-2.8772785243008e-05, -23.467956543429, 9.7621895696846e-05}
handPositions["left_grip"]["off"]["ring_2_LE"] = {2.3617286995184, -40.282469194715, -1.4142819101422e-09}
handPositions["left_grip"]["off"]["ring_3_LE"] = {4.4955170758503e-06, -23.811704123002, 1.0897842436762e-13}
handPositions["left_grip"]["off"]["ring_4_LE"] = {-2.7354196563512e-06, -26.424581873767, 9.7503594596652e-06}
handPositions["left_grip"]["off"]["pinky_2_LE"] = {2.2591228411133, -37.101338593897, -10.071137436752}
handPositions["left_grip"]["off"]["pinky_3_LE"] = {-0.00010403210784358, -30.994186236877, 0.00011652381577409}
handPositions["left_grip"]["off"]["pinky_4_LE"] = {4.6093473539493e-05, -14.00798649564, 4.0022472151134e-05}

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




