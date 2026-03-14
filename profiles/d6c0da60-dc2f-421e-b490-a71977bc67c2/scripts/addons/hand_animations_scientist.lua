
local M = {}

local initialTransform = {}
initialTransform["right_hand"] = {}
--initialTransform["right_hand"]["lowerarm_r"] = {rotation = {0.0, -90.0, 90.0}, location = {0.0, 0.0, 0.0}}
initialTransform["right_hand"]["lowerarm_twist_01_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.0, 0.0, 0.0}}
initialTransform["right_hand"]["elbow_out_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.5837, 0.5756, -2.7212}}
initialTransform["right_hand"]["elbow_in_r"] = {rotation = {0.0007, -0.0021, -180.0}, location = {-0.7169, 0.7192, 3.9889}}
initialTransform["right_hand"]["elbow_front_r"] = {rotation = {0.0, 0.0, 90.0002}, location = {-1.6932, -3.6587, 0.4389}}
initialTransform["right_hand"]["elbow_back_r"] = {rotation = {0.0, 0.0, -89.9998}, location = {-0.662, 4.9187, 1.1643}}
initialTransform["right_hand"]["lowerarm_twist_02_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-6.8128, -0.0003, -0.0003}}
initialTransform["right_hand"]["lowerarm_twist_03_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-13.6255, -0.0004, -0.0002}}
initialTransform["right_hand"]["lowerarm_twist_04_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-20.4383, -0.0004, -0.0002}}
initialTransform["right_hand"]["hand_r"] = {rotation = {0.0, 0.0, -90.0001}, location = {-27.2511, 0.0, 0.0}}
initialTransform["right_hand"]["wrist_in_r"] = {rotation = {-16.065, -2.5609, -92.3428}, location = {0.7033, 1.6591, -0.0382}}
initialTransform["right_hand"]["wrist_out_r"] = {rotation = {-16.065, -2.5608, 87.6572}, location = {-0.02, -2.2383, 0.1239}}
initialTransform["right_hand"]["pinky_metacarpal_r"] = {rotation = {19.0555, -12.792, -28.0809}, location = {-3.3143, -0.306, -2.3911}}
initialTransform["right_hand"]["pinky_01_r"] = {rotation = {-2.524, -20.353, 10.7706}, location = {-4.957, -0.1429, 0.1984}}
initialTransform["right_hand"]["pinky_02_r"] = {rotation = {0.0, -26.3566, 0.0}, location = {-3.8161, 0.0, 0.0}}
initialTransform["right_hand"]["pinky_03_r"] = {rotation = {-0.1721, -10.1718, 0.0496}, location = {-2.04, 0.0, 0.0}}
initialTransform["right_hand"]["pinky_03_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.5296, 0.5683, 0.0}}
initialTransform["right_hand"]["pinky_03_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.0897, -0.6415, 0.0}}
initialTransform["right_hand"]["pinky_02_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.0425, -0.8126, -0.0002}}
initialTransform["right_hand"]["pinky_02_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.5869, 0.6727, -0.0002}}
initialTransform["right_hand"]["pinky_02_low_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-1.3629, 0.5862, -0.0002}}
initialTransform["right_hand"]["pinky_01_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.015, -1.0696, 0.0}}
initialTransform["right_hand"]["pinky_01_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-2.2687, 0.7697, 0.0}}
initialTransform["right_hand"]["pinky_01_low_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-3.2866, 0.7348, 0.0}}
initialTransform["right_hand"]["pinky_metacarpal_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-3.7446, -1.1379, -0.0002}}
initialTransform["right_hand"]["pinky_metacarpal_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-5.2253, 1.2218, -0.0002}}
initialTransform["right_hand"]["ring_metacarpal_r"] = {rotation = {11.5756, 0.5954, -13.5029}, location = {-3.3747, -0.5421, -1.092}}
initialTransform["right_hand"]["ring_01_r"] = {rotation = {1.6345, -32.6442, 6.2958}, location = {-5.6452, -0.042, 0.0208}}
initialTransform["right_hand"]["ring_02_r"] = {rotation = {0.0, -22.2856, 0.0}, location = {-4.9772, 0.0, 0.0}}
initialTransform["right_hand"]["ring_03_r"] = {rotation = {0.0, -12.424, 0.0}, location = {-2.2651, 0.0, 0.0}}
initialTransform["right_hand"]["ring_03_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.6381, 0.7332, 0.0}}
initialTransform["right_hand"]["ring_03_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.0673, -0.7447, 0.0}}
initialTransform["right_hand"]["ring_02_low_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-1.5704, 0.8897, -0.0002}}
initialTransform["right_hand"]["ring_02_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.8891, 0.8481, -0.0002}}
initialTransform["right_hand"]["ring_02_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.0798, -0.9139, -0.0002}}
initialTransform["right_hand"]["ring_01_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-2.7848, 1.0887, -0.0002}}
initialTransform["right_hand"]["ring_01_low_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-4.2159, 0.92, 0.0}}
initialTransform["right_hand"]["ring_01_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.1242, -0.8824, -0.0002}}
initialTransform["right_hand"]["ring_metacarpal_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-4.0552, -0.8867, 0.0}}
initialTransform["right_hand"]["ring_metacarpal_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-5.3642, 2.2839, 0.0}}
initialTransform["right_hand"]["middle_metacarpal_r"] = {rotation = {0.0556, 1.3154, -4.2742}, location = {-3.3758, -0.7536, 0.1828}}
initialTransform["right_hand"]["middle_01_r"] = {rotation = {-0.7366, -34.095, -0.0364}, location = {-6.0986, 0.0004, 0.0}}
initialTransform["right_hand"]["middle_02_r"] = {rotation = {0.0, -23.283, 0.0}, location = {-5.1688, 0.0, 0.0001}}
initialTransform["right_hand"]["middle_03_r"] = {rotation = {0.0, -12.483, 0.0}, location = {-2.474, 0.0, 0.0}}
initialTransform["right_hand"]["middle_03_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.147, -0.8722, -0.0002}}
initialTransform["right_hand"]["middle_03_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.6407, 0.778, -0.0002}}
initialTransform["right_hand"]["middle_02_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.2462, -0.9414, -0.0002}}
initialTransform["right_hand"]["middle_02_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.613, 0.9092, -0.0002}}
initialTransform["right_hand"]["middle_02_low_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-1.7652, 0.9191, -0.0002}}
initialTransform["right_hand"]["middle_01_low_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-4.3317, 0.8823, 0.0}}
initialTransform["right_hand"]["middle_01_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-2.7794, 1.0189, 0.0}}
initialTransform["right_hand"]["middle_01_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.1225, -0.8498, 0.0}}
initialTransform["right_hand"]["middle_metacarpal_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-4.2267, -0.9406, -0.0002}}
initialTransform["right_hand"]["middle_metacarpal_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-5.6625, 2.1946, 0.0}}
initialTransform["right_hand"]["index_metacarpal_r"] = {rotation = {-7.2667, -0.4061, 3.4162}, location = {-3.4444, -0.3848, 2.3793}}
initialTransform["right_hand"]["index_01_r"] = {rotation = {0.7225, -24.1712, -0.0562}, location = {-5.8776, 0.0436, -0.2411}}
initialTransform["right_hand"]["index_02_r"] = {rotation = {0.0785, -16.2323, 0.0903}, location = {-4.0797, -0.0002, 0.0001}}
initialTransform["right_hand"]["index_03_r"] = {rotation = {0.0945, -13.9759, 0.0735}, location = {-2.595, 0.0, 0.0}}
initialTransform["right_hand"]["index_03_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.4001, 0.6999, -0.0002}}
initialTransform["right_hand"]["index_03_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.0, -0.8001, -0.0002}}
initialTransform["right_hand"]["index_02_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.0, -0.8001, -0.0002}}
initialTransform["right_hand"]["index_02_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.7001, 0.9999, -0.0002}}
initialTransform["right_hand"]["index_02_low_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-2.0001, 0.6999, -0.0002}}
initialTransform["right_hand"]["index_01_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.1302, -0.7782, 0.0}}
initialTransform["right_hand"]["index_01_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-1.9998, 0.9998, 0.0}}
initialTransform["right_hand"]["index_01_low_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-3.2998, 0.8124, 0.0}}
initialTransform["right_hand"]["index_metacarpal_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-4.0004, -0.9998, -0.0002}}
initialTransform["right_hand"]["index_metacarpal_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-5.7004, 1.8002, -0.0002}}
initialTransform["right_hand"]["thumb_01_r"] = {rotation = {-21.7331, -19.6005, 91.2947}, location = {-1.9925, 1.3567, 2.5815}}
initialTransform["right_hand"]["thumb_02_r"] = {rotation = {1.8917, -22.5943, 3.552}, location = {-4.3782, 0.0002, 0.0}}
initialTransform["right_hand"]["thumb_03_r"] = {rotation = {0.0, -9.3327, 0.0}, location = {-3.0856, -0.0004, -0.0003}}
initialTransform["right_hand"]["thumb_03_up_r"] = {rotation = {-0.0002, 24.5343, -0.0002}, location = {-0.0004, -0.9998, 0.0}}
initialTransform["right_hand"]["thumb_03_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.8004, 1.1002, 0.0}}
initialTransform["right_hand"]["thumb_02_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.3001, -1.0001, -0.0002}}
initialTransform["right_hand"]["thumb_02_dn_r"] = {rotation = {0.0001, 0.0, 0.0}, location = {-1.4999, 0.9999, -0.0002}}
initialTransform["right_hand"]["thumb_02_low_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-2.5999, 1.0503, -0.0002}}
initialTransform["right_hand"]["thumb_01_in_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-3.9999, 0.4992, -1.9996}}
initialTransform["right_hand"]["thumb_01_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-1.9999, 2.4992, 0.0004}}
initialTransform["right_hand"]["thumb_01_low_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-4.0328, 1.6081, 0.0}}
initialTransform["right_hand"]["thumb_01_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-1.9999, -1.0007, 0.0004}}
initialTransform["right_hand"]["thumb_01_out_r"] = {rotation = {-0.0002, 0.0, 0.0}, location = {-1.9999, -0.0007, 1.5004}}
initialTransform["right_hand"]["prop_root_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.0, 0.0, 0.0}}
initialTransform["right_hand"]["prop_r"] = {rotation = {0.0, 90.0, 0.0}, location = {-8.0, 3.4999, -0.6725}}
initialTransform["right_hand"]["upperarm_twist_01_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.0, 0.0, 0.0}}
initialTransform["right_hand"]["shoulder_out_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.2208, 0.0521, -5.8038}}
initialTransform["right_hand"]["shoulder_in_r"] = {rotation = {48.1943, -0.0043, 179.9968}, location = {-6.4106, -0.5441, 4.762}}
initialTransform["right_hand"]["shoulder_back_r"] = {rotation = {0.0003, 0.0, -71.3386}, location = {-1.4681, 7.6447, -0.3856}}
initialTransform["right_hand"]["shoulder_front_r"] = {rotation = {1.9524, -11.8776, 98.9451}, location = {-3.2555, -8.5089, 1.0632}}
initialTransform["right_hand"]["upperarm_twist_02_r"] = {rotation = {0.0003, 0.0, 0.0}, location = {-6.943, -0.0003, -0.0003}}
initialTransform["right_hand"]["upperarm_twist_03_r"] = {rotation = {-0.0006, 0.0, 0.0}, location = {-13.886, 0.0, -0.0003}}
initialTransform["right_hand"]["bicep_front_r"] = {rotation = {0.4254, -0.8683, 85.0435}, location = {-0.7218, -4.4432, 1.7657}}
initialTransform["right_hand"]["bicep_back_r"] = {rotation = {0.4253, -0.8683, -94.9565}, location = {-0.6752, 4.8772, 0.1783}}
initialTransform["right_hand"]["upperarm_twist_04_r"] = {rotation = {-0.0002, 0.0, 0.0}, location = {-20.829, -0.0003, -0.0003}}


initialTransform["left_hand"] = {}
--initialTransform["left_hand"]["lowerarm_l"] = {rotation = {0.0, 89.9999, -90.0}, location = {0.0, 0.0, 0.0}}
initialTransform["left_hand"]["lowerarm_twist_01_l"] = {rotation = {0.0, 0.0, 0.0}, location = {0.0, 0.0, 0.0}}
initialTransform["left_hand"]["elbow_in_l"] = {rotation = {0.0, 0.0, 180.0}, location = {0.7171, -0.7189, -3.989}}
initialTransform["left_hand"]["elbow_out_l"] = {rotation = {0.0, 0.0, 0.0}, location = {0.5839, -0.5752, 2.7212}}
initialTransform["left_hand"]["elbow_front_l"] = {rotation = {0.0, 0.0, 89.9999}, location = {1.6934, 3.659, -0.4389}}
initialTransform["left_hand"]["elbow_back_l"] = {rotation = {0.0, 0.0, -90.0}, location = {0.6623, -4.9183, -1.1643}}
initialTransform["left_hand"]["lowerarm_twist_02_l"] = {rotation = {0.0, 0.0, 0.0}, location = {6.8127, -0.0003, -0.0003}}
initialTransform["left_hand"]["lowerarm_twist_03_l"] = {rotation = {0.0, 0.0, 0.0}, location = {13.6255, -0.0003, -0.0003}}
initialTransform["left_hand"]["lowerarm_twist_04_l"] = {rotation = {0.0, 0.0, 0.0}, location = {20.4382, -0.0003, -0.0003}}
initialTransform["left_hand"]["hand_l"] = {rotation = {0.0, 0.0, -90.0}, location = {27.251, 0.0, 0.0}}
initialTransform["left_hand"]["wrist_in_l"] = {rotation = {-16.065, -2.5609, -92.3426}, location = {-0.7036, -1.6589, 0.0379}}
initialTransform["left_hand"]["wrist_out_l"] = {rotation = {-16.065, -2.5609, 87.6574}, location = {0.0196, 2.2384, -0.1242}}
initialTransform["left_hand"]["thumb_01_l"] = {rotation = {-39.9042, -20.5087, 73.5644}, location = {1.9924, -1.3567, -2.5816}}
initialTransform["left_hand"]["thumb_02_l"] = {rotation = {1.8662, -23.194, 3.4899}, location = {4.3779, 0.0, 0.0}}
initialTransform["left_hand"]["thumb_03_l"] = {rotation = {0.0, -10.0, 0.0}, location = {3.0859, 0.0, 0.0}}
initialTransform["left_hand"]["thumb_03_dn_l"] = {rotation = {0.0, 0.0, 0.0}, location = {0.8, -1.1001, 0.0}}
initialTransform["left_hand"]["thumb_03_up_l"] = {rotation = {0.0, 0.0, 0.0}, location = {0.0, 1.0, 0.0}}
initialTransform["left_hand"]["thumb_02_up_l"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.3001, 0.9999, 0.0}}
initialTransform["left_hand"]["thumb_02_dn_l"] = {rotation = {0.0, 0.0, 0.0}, location = {1.5, -1.0001, 0.0}}
initialTransform["left_hand"]["thumb_02_low_l"] = {rotation = {0.0, 0.0, 0.0}, location = {2.5999, -1.0504, 0.0}}
initialTransform["left_hand"]["thumb_01_low_l"] = {rotation = {0.0, 0.0, 0.0}, location = {4.0327, -1.6081, 0.0}}
initialTransform["left_hand"]["thumb_01_up_l"] = {rotation = {0.0, 0.0, 0.0}, location = {2.0, 0.9999, 0.0}}
initialTransform["left_hand"]["thumb_01_in_l"] = {rotation = {0.0, 0.0, 0.0}, location = {4.0, -0.5001, 2.0}}
initialTransform["left_hand"]["thumb_01_out_l"] = {rotation = {0.0, 0.0, 0.0}, location = {2.0, 0.0, -1.5}}
initialTransform["left_hand"]["thumb_01_dn_l"] = {rotation = {0.0, 0.0, 0.0}, location = {1.9999, -2.5001, 0.0}}
initialTransform["left_hand"]["index_metacarpal_l"] = {rotation = {-7.3256, 0.6061, 3.2877}, location = {3.4445, 0.3846, -2.3794}}
initialTransform["left_hand"]["index_metacarpal_up_l"] = {rotation = {0.0, 0.0, 0.0}, location = {4.0, 0.9999, 0.0}}
initialTransform["left_hand"]["index_metacarpal_dn_l"] = {rotation = {0.0, 0.0, 0.0}, location = {5.6999, -1.8, 0.0}}
initialTransform["left_hand"]["index_01_l"] = {rotation = {0.0, -23.373, 0.0}, location = {5.877, -0.0432, 0.2408}}
initialTransform["left_hand"]["index_02_l"] = {rotation = {0.0, -14.8926, 0.0}, location = {4.0799, 0.0, 0.0}}
initialTransform["left_hand"]["index_03_l"] = {rotation = {0.0, -12.5165, 0.0}, location = {2.595, 0.0, 0.0}}
initialTransform["left_hand"]["index_03_up_l"] = {rotation = {0.0, 0.0, 0.0}, location = {0.0, 0.8, 0.0}}
initialTransform["left_hand"]["index_03_dn_l"] = {rotation = {0.0, 0.0, 0.0}, location = {0.4, -0.7, 0.0}}
initialTransform["left_hand"]["index_02_up_l"] = {rotation = {0.0, 0.0, 0.0}, location = {0.0, 0.8, 0.0}}
initialTransform["left_hand"]["index_02_dn_l"] = {rotation = {0.0, 0.0, 0.0}, location = {0.6999, -1.0001, 0.0}}
initialTransform["left_hand"]["index_02_low_l"] = {rotation = {0.0, 0.0, 0.0}, location = {2.0, -0.7, 0.0}}
initialTransform["left_hand"]["index_01_up_l"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.1303, 0.7781, 0.0}}
initialTransform["left_hand"]["index_01_dn_l"] = {rotation = {0.0, 0.0, 0.0}, location = {1.9999, -1.0, 0.0}}
initialTransform["left_hand"]["index_01_low_l"] = {rotation = {0.0, 0.0, 0.0}, location = {3.2999, -0.8126, 0.0}}
initialTransform["left_hand"]["middle_metacarpal_l"] = {rotation = {0.1307, 2.3183, -4.2726}, location = {3.3758, 0.7535, -0.1829}}
initialTransform["left_hand"]["middle_metacarpal_up_l"] = {rotation = {0.0, 0.0, 0.0}, location = {4.2264, 0.9407, 0.0}}
initialTransform["left_hand"]["middle_metacarpal_dn_l"] = {rotation = {0.0, 0.0, 0.0}, location = {5.6622, -2.1945, 0.0}}
initialTransform["left_hand"]["middle_01_l"] = {rotation = {0.0, -31.5727, 0.0}, location = {6.0982, 0.0, 0.0}}
initialTransform["left_hand"]["middle_02_l"] = {rotation = {0.0, -20.7693, 0.0}, location = {5.169, 0.0, 0.0}}
initialTransform["left_hand"]["middle_03_l"] = {rotation = {0.0, -10.0, 0.0}, location = {2.4739, 0.0, 0.0}}
initialTransform["left_hand"]["middle_03_up_l"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.1472, 0.872, 0.0}}
initialTransform["left_hand"]["middle_03_dn_l"] = {rotation = {0.0, 0.0, 0.0}, location = {0.6405, -0.7782, 0.0}}
initialTransform["left_hand"]["middle_02_up_l"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.2463, 0.9412, 0.0}}
initialTransform["left_hand"]["middle_02_dn_l"] = {rotation = {0.0, 0.0, 0.0}, location = {0.6129, -0.9094, 0.0}}
initialTransform["left_hand"]["middle_02_low_l"] = {rotation = {0.0, 0.0, 0.0}, location = {1.7651, -0.9193, 0.0}}
initialTransform["left_hand"]["middle_01_up_l"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.1225, 0.8495, 0.0}}
initialTransform["left_hand"]["middle_01_dn_l"] = {rotation = {0.0, 0.0, 0.0}, location = {2.7794, -1.0192, 0.0}}
initialTransform["left_hand"]["middle_01_low_l"] = {rotation = {0.0, 0.0, 0.0}, location = {4.3318, -0.8826, 0.0}}
initialTransform["left_hand"]["ring_metacarpal_l"] = {rotation = {11.8093, 1.5945, -13.2999}, location = {3.3743, 0.5425, 1.0917}}
initialTransform["left_hand"]["ring_metacarpal_up_l"] = {rotation = {0.0, 0.0, 0.0}, location = {4.0553, 0.8863, 0.0}}
initialTransform["left_hand"]["ring_metacarpal_dn_l"] = {rotation = {0.0, -0.0215, 0.0}, location = {5.3642, -2.2842, 0.0}}
initialTransform["left_hand"]["ring_01_l"] = {rotation = {0.1169, -29.4145, 6.3958}, location = {5.6455, 0.0416, -0.0207}}
initialTransform["left_hand"]["ring_02_l"] = {rotation = {0.0, -18.964, 0.0}, location = {4.977, 0.0, 0.0}}
initialTransform["left_hand"]["ring_03_l"] = {rotation = {0.0, -9.168, 0.0}, location = {2.265, 0.0, 0.0}}
initialTransform["left_hand"]["ring_03_up_l"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.0675, 0.7446, 0.0}}
initialTransform["left_hand"]["ring_03_dn_l"] = {rotation = {0.0, 0.0, 0.0}, location = {0.6379, -0.7333, 0.0}}
initialTransform["left_hand"]["ring_02_up_l"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.08, 0.9137, 0.0}}
initialTransform["left_hand"]["ring_02_dn_l"] = {rotation = {0.0, 0.0, 0.0}, location = {0.8889, -0.8483, 0.0}}
initialTransform["left_hand"]["ring_02_low_l"] = {rotation = {0.0, 0.0, 0.0}, location = {1.5702, -0.8899, 0.0}}
initialTransform["left_hand"]["ring_01_up_l"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.1245, 0.8823, 0.0}}
initialTransform["left_hand"]["ring_01_dn_l"] = {rotation = {0.0, -0.0143, 0.0}, location = {2.7845, -1.0888, 0.0}}
initialTransform["left_hand"]["ring_01_low_l"] = {rotation = {0.0, 0.0, 0.0}, location = {4.2155, -0.9201, 0.0}}
initialTransform["left_hand"]["pinky_metacarpal_l"] = {rotation = {19.5277, -11.8507, -27.7691}, location = {3.3143, 0.3059, 2.3911}}
initialTransform["left_hand"]["pinky_metacarpal_up_l"] = {rotation = {0.0, 0.0, 0.0}, location = {3.7441, 1.1379, 0.0}}
initialTransform["left_hand"]["pinky_metacarpal_dn_l"] = {rotation = {0.0, 0.0, 0.0}, location = {5.2249, -1.2218, 0.0}}
initialTransform["left_hand"]["pinky_01_l"] = {rotation = {-0.605, -14.834, 10.492}, location = {4.9601, 0.1291, -0.2012}}
initialTransform["left_hand"]["pinky_02_l"] = {rotation = {0.0, -21.287, 0.0}, location = {3.8159, 0.0, 0.0}}
initialTransform["left_hand"]["pinky_03_l"] = {rotation = {0.0, -4.9171, 0.0}, location = {2.0399, 0.0, 0.0}}
initialTransform["left_hand"]["pinky_03_up_l"] = {rotation = {0.0, 0.0, 0.0}, location = {0.0895, 0.6413, 0.0}}
initialTransform["left_hand"]["pinky_03_dn_l"] = {rotation = {0.0, 0.0, 0.0}, location = {0.5294, -0.5684, 0.0}}
initialTransform["left_hand"]["pinky_02_up_l"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.0426, 0.8124, 0.0}}
initialTransform["left_hand"]["pinky_02_dn_l"] = {rotation = {0.0, 0.0, 0.0}, location = {0.5867, -0.6729, 0.0}}
initialTransform["left_hand"]["pinky_02_low_l"] = {rotation = {0.0, 0.0, 0.0}, location = {1.3628, -0.5864, 0.0}}
initialTransform["left_hand"]["pinky_01_up_l"] = {rotation = {0.0, -0.0157, 0.0}, location = {0.0147, 1.0694, 0.0}}
initialTransform["left_hand"]["pinky_01_dn_l"] = {rotation = {0.0, -0.0157, 0.0}, location = {2.2685, -0.7698, 0.0}}
initialTransform["left_hand"]["pinky_01_low_l"] = {rotation = {0.0, 0.0, 0.0}, location = {3.2864, -0.7349, 0.0}}
initialTransform["left_hand"]["prop_root_l"] = {rotation = {0.0, 0.0, 0.0}, location = {0.0, 0.0, 0.0}}
initialTransform["left_hand"]["prop_l"] = {rotation = {0.0, 89.9999, 179.9999}, location = {7.9999, -3.5, 0.6723}}
initialTransform["left_hand"]["upperarm_twist_01_l"] = {rotation = {0.0, 0.0, 0.0}, location = {0.0, 0.0, 0.0}}
initialTransform["left_hand"]["shoulder_back_l"] = {rotation = {0.0, 0.0, -71.3387}, location = {1.4677, -7.6445, 0.3859}}
initialTransform["left_hand"]["shoulder_front_l"] = {rotation = {1.952, -11.8776, 98.9451}, location = {3.255, 8.5091, -1.0631}}
initialTransform["left_hand"]["shoulder_in_l"] = {rotation = {48.1941, 0.0, 180.0}, location = {6.4101, 0.5444, -4.7618}}
initialTransform["left_hand"]["shoulder_out_l"] = {rotation = {0.0, 0.0, 0.0}, location = {0.2203, -0.0518, 5.804}}
initialTransform["left_hand"]["upperarm_twist_02_l"] = {rotation = {0.0, 0.0, 0.0}, location = {6.9429, -0.0003, -0.0003}}
initialTransform["left_hand"]["upperarm_twist_03_l"] = {rotation = {0.0, 0.0, 0.0}, location = {13.886, 0.0, -0.0003}}
initialTransform["left_hand"]["bicep_back_l"] = {rotation = {0.4244, -0.8684, -94.9565}, location = {0.6747, -4.8769, -0.1775}}
initialTransform["left_hand"]["bicep_front_l"] = {rotation = {0.4244, -0.8684, 85.0435}, location = {0.7212, 4.4435, -1.765}}
initialTransform["left_hand"]["upperarm_twist_04_l"] = {rotation = {0.0, 0.0, 0.0}, location = {20.8289, -0.0003, -0.0003}}


local handPositions = {}
handPositions["right_grip_weapon"] = {}
handPositions["right_grip_weapon"]["on"] = {}
-- handPositions["right_grip_weapon"]["on"]["thumb_01_r"] = {-24.20783976116, -51.272386127135, 137.38483033276}
-- handPositions["right_grip_weapon"]["on"]["thumb_02_r"] = {-1.5356912528246, -31.275827620646, -1.2953207312888}
-- handPositions["right_grip_weapon"]["on"]["thumb_03_r"] = {0.34186023960116, -38.059592850004, 1.9242381438882}
-- handPositions["right_grip_weapon"]["on"]["index_01_r"] = {7.0920929088624, 4.7986127324078, 5.0669146679995}
-- handPositions["right_grip_weapon"]["on"]["index_02_r"] = {-4.6990534898581, -30.197812903734, 1.3075262985282}
-- handPositions["right_grip_weapon"]["on"]["index_03_r"] = {-4.0495760352831, -52.008498512292, -0.23633296373659}
-- handPositions["right_grip_weapon"]["on"]["middle_01_r"] = {0.52773803768421, -62.555259712865, -1.4417866199984}
-- handPositions["right_grip_weapon"]["on"]["middle_02_r"] = {-7.9244756038727, -37.922313050749, 2.2669434745052}
-- handPositions["right_grip_weapon"]["on"]["middle_03_r"] = {-8.5498751750898, -63.672823136749, 7.9168822604688}
-- handPositions["right_grip_weapon"]["on"]["ring_01_r"] = {-5.5174528245127, -71.597171596966, -14.774660635087}
-- handPositions["right_grip_weapon"]["on"]["ring_02_r"] = {0.85263322079528, -36.8142585252, 2.8827740756073}
-- handPositions["right_grip_weapon"]["on"]["ring_03_r"] = {-0.79957075601282, -73.25505341347, 0.3547396539162}
-- handPositions["right_grip_weapon"]["on"]["pinky_01_r"] = {-10.941003094511, -66.746702048574, -26.790252074308}
-- handPositions["right_grip_weapon"]["on"]["pinky_02_r"] = {7.2843824085156, -34.137070742496, 0.63067189632459}
-- handPositions["right_grip_weapon"]["on"]["pinky_03_r"] = {7.4794350327117, -45.522169160321, -0.52771348875812}
handPositions["right_grip_weapon"]["on"]["thumb_01_r"] = {-10.2745, -59.5442, 140.0936}
handPositions["right_grip_weapon"]["on"]["thumb_02_r"] = {4.8187, -43.4889, 5.4115}
handPositions["right_grip_weapon"]["on"]["thumb_03_r"] = {-0.0013, -23.637, -0.0028}
handPositions["right_grip_weapon"]["on"]["index_01_r"] = {2.9219, -32.1992, -0.9429}
handPositions["right_grip_weapon"]["on"]["index_02_r"] = {0.0, -4.8926, 0.0}
handPositions["right_grip_weapon"]["on"]["index_03_r"] = {0.0005, -28.5116, -0.0026}
handPositions["right_grip_weapon"]["on"]["middle_01_r"] = {9.7554, -59.0362, -0.0766}
handPositions["right_grip_weapon"]["on"]["middle_02_r"] = {-0.0011, -64.376, 0.0002}
handPositions["right_grip_weapon"]["on"]["middle_03_r"] = {0.1969, -70.3748, 1.9692}
handPositions["right_grip_weapon"]["on"]["ring_01_r"] = {15.7394, -60.0242, 10.5881}
handPositions["right_grip_weapon"]["on"]["ring_02_r"] = {-3.0297, -52.2022, -2.1299}
handPositions["right_grip_weapon"]["on"]["ring_03_r"] = {0.0401, -79.5923, 1.7956}
handPositions["right_grip_weapon"]["on"]["pinky_01_r"] = {41.6416, 17.1891, 117.9267}
handPositions["right_grip_weapon"]["on"]["pinky_02_r"] = {0.4712, -49.3726, 0.6422}
handPositions["right_grip_weapon"]["on"]["pinky_03_r"] = {-0.2562, -72.1729, 1.1708}

handPositions["right_trigger_weapon"] = {}
handPositions["right_trigger_weapon"]["on"] = {}
-- handPositions["right_trigger_weapon"]["on"]["index_01_r"] = {7.0920929088625, 4.7986127324078, 5.0669146679995}
-- handPositions["right_trigger_weapon"]["on"]["index_02_r"] = {-4.699053489859, -67.197812903735, 1.3075262985293}
-- handPositions["right_trigger_weapon"]["on"]["index_03_r"] = {-4.0495760352832, -72.008498512293, -0.2363329637356}
handPositions["right_trigger_weapon"]["on"]["index_01_r"] = {2.9219, -32.1992, -0.9429}
handPositions["right_trigger_weapon"]["on"]["index_02_r"] = {0.0, -34.8926, 0.0}
handPositions["right_trigger_weapon"]["on"]["index_03_r"] = {0.0005, -43.5116, -0.0026}
handPositions["right_trigger_weapon"]["off"] = {}
-- handPositions["right_trigger_weapon"]["off"]["index_01_r"] = {7.0920929088624, 4.7986127324078, 5.0669146679995}
-- handPositions["right_trigger_weapon"]["off"]["index_02_r"] = {-4.6990534898581, -30.197812903734, 1.3075262985282}
-- handPositions["right_trigger_weapon"]["off"]["index_03_r"] = {-4.0495760352831, -52.008498512292, -0.23633296373659}
handPositions["right_trigger_weapon"]["off"]["index_01_r"] = {2.9219, -32.1992, -0.9429}
handPositions["right_trigger_weapon"]["off"]["index_02_r"] = {0.0, -4.8926, 0.0}
handPositions["right_trigger_weapon"]["off"]["index_03_r"] = {0.0005, -28.5116, -0.0026}

handPositions["right_grip"] = {}
handPositions["right_grip"]["on"] = {}
-- handPositions["right_grip"]["on"]["thumb_01_r"] = {-24.20783976116, -51.272386127135, 137.38483033276}
-- handPositions["right_grip"]["on"]["thumb_02_r"] = {-1.5356912528246, -31.275827620646, -1.2953207312888}
-- handPositions["right_grip"]["on"]["thumb_03_r"] = {0.34186023960116, -38.059592850004, 1.9242381438882}
-- --handPositions["right_grip"]["on"]["index_01_r"] = {7.0920929088624, 4.7986127324078, 5.0669146679995}
-- --handPositions["right_grip"]["on"]["index_02_r"] = {-4.6990534898581, -30.197812903734, 1.3075262985282}
-- --handPositions["right_grip"]["on"]["index_03_r"] = {-4.0495760352831, -52.008498512292, -0.23633296373659}
-- handPositions["right_grip"]["on"]["middle_01_r"] = {0.52773803768421, -62.555259712865, -1.4417866199984}
-- handPositions["right_grip"]["on"]["middle_02_r"] = {-7.9244756038727, -37.922313050749, 2.2669434745052}
-- handPositions["right_grip"]["on"]["middle_03_r"] = {-8.5498751750898, -63.672823136749, 7.9168822604688}
-- handPositions["right_grip"]["on"]["ring_01_r"] = {-5.5174528245127, -71.597171596966, -14.774660635087}
-- handPositions["right_grip"]["on"]["ring_02_r"] = {0.85263322079528, -36.8142585252, 2.8827740756073}
-- handPositions["right_grip"]["on"]["ring_03_r"] = {-0.79957075601282, -73.25505341347, 0.3547396539162}
-- handPositions["right_grip"]["on"]["pinky_01_r"] = {-10.941003094511, -66.746702048574, -26.790252074308}
-- handPositions["right_grip"]["on"]["pinky_02_r"] = {7.2843824085156, -34.137070742496, 0.63067189632459}
-- handPositions["right_grip"]["on"]["pinky_03_r"] = {7.4794350327117, -45.522169160321, -0.52771348875812}
handPositions["right_grip"]["on"]["thumb_01_r"] = {-24.9043, -25.5087, 63.5643}
handPositions["right_grip"]["on"]["thumb_02_r"] = {1.8661, -23.1941, 3.4899}
handPositions["right_grip"]["on"]["thumb_03_r"] = {0.0, -65.0001, 0.0}
handPositions["right_grip"]["on"]["middle_01_r"] = {0.0, -96.5728, 0.0}
handPositions["right_grip"]["on"]["middle_02_r"] = {0.0, -75.7694, 0.0}
handPositions["right_grip"]["on"]["middle_03_r"] = {0.0, -70.0001, 0.0}
handPositions["right_grip"]["on"]["ring_01_r"] = {0.1168, -94.4145, 6.3958}
handPositions["right_grip"]["on"]["ring_02_r"] = {0.0, -78.9641, 0.0}
handPositions["right_grip"]["on"]["ring_03_r"] = {0.0, -64.1681, 0.0}
handPositions["right_grip"]["on"]["pinky_01_r"] = {4.3949, -84.834, 10.4919}
handPositions["right_grip"]["on"]["pinky_02_r"] = {0.0, -81.2871, 0.0}
handPositions["right_grip"]["on"]["pinky_03_r"] = {0.0, -59.9171, 0.0}


handPositions["right_grip"]["off"] = {}
handPositions["right_grip"]["off"]["thumb_01_r"] = {-39.9042, -20.5087, 73.5644}
handPositions["right_grip"]["off"]["thumb_02_r"] = {1.8662, -23.194, 3.4899}
handPositions["right_grip"]["off"]["thumb_03_r"] = {0.0, -10.0, 0.0}
--handPositions["right_grip"]["off"]["index_01_r"] = {-13.579874286286, -0.53973389491354, 0.83556637092762}
--handPositions["right_grip"]["off"]["index_02_r"] = {-0.86297378936018, -2.3855033056582, 1.3962212178538}
--handPositions["right_grip"]["off"]["index_03_r"] = {-1.0207031394195, -1.5925566715179, 1.3048430900779}
handPositions["right_grip"]["off"]["middle_01_r"] = {-0.7366, -34.095, -0.0364}
handPositions["right_grip"]["off"]["middle_02_r"] = {0.0, -23.283, 0.0}
handPositions["right_grip"]["off"]["middle_03_r"] = {0.0, -12.483, 0.0}
handPositions["right_grip"]["off"]["ring_01_r"] = {1.6345, -32.6442, 6.2958}
handPositions["right_grip"]["off"]["ring_02_r"] = {0.0, -22.2856, 0.0}
handPositions["right_grip"]["off"]["ring_03_r"] = {0.0, -12.424, 0.0}
handPositions["right_grip"]["off"]["pinky_01_r"] = {-2.524, -20.353, 10.7706}
handPositions["right_grip"]["off"]["pinky_02_r"] = {0.0, -26.3566, 0.0}
handPositions["right_grip"]["off"]["pinky_03_r"] = {-0.1721, -10.1718, 0.0496}


handPositions["right_trigger"] = {}
handPositions["right_trigger"]["on"] = {}
-- handPositions["right_trigger"]["on"]["index_01_r"] = {7.0920929088621, -50.201387267592, 5.0669146679995}
-- handPositions["right_trigger"]["on"]["index_02_r"] = {-4.6990534898584, -65.197812903735, 1.3075262985288}
-- handPositions["right_trigger"]["on"]["index_03_r"] = {-4.0495760352828, -62.008498512293, -0.23633296373576}
handPositions["right_trigger"]["on"]["index_01_r"] = {0.0, -88.373, 0.0}
handPositions["right_trigger"]["on"]["index_02_r"] = {0.0, -74.8927, 0.0}
handPositions["right_trigger"]["on"]["index_03_r"] = {5.0, -47.5166, 0.0}
handPositions["right_trigger"]["off"] = {}
handPositions["right_trigger"]["off"]["index_01_r"] = {0.7225, -24.1712, -0.0562}
handPositions["right_trigger"]["off"]["index_02_r"] = {0.0785, -16.2323, 0.0903}
handPositions["right_trigger"]["off"]["index_03_r"] = {0.0945, -13.9759, 0.0735}

handPositions["right_thumb"] = {}
handPositions["right_thumb"]["on"] = {}
-- handPositions["right_thumb"]["on"]["thumb_01_r"] = {-24.20783976116, -51.272386127135, 137.38483033276}
-- handPositions["right_thumb"]["on"]["thumb_02_r"] = {-1.5356912528246, -31.275827620646, -1.2953207312888}
-- handPositions["right_thumb"]["on"]["thumb_03_r"] = {0.34186023960116, -38.059592850004, 1.9242381438882}
handPositions["right_thumb"]["on"]["thumb_01_r"] = {-24.9043, -25.5087, 63.5643}
handPositions["right_thumb"]["on"]["thumb_02_r"] = {1.8661, -23.1941, 3.4899}
handPositions["right_thumb"]["on"]["thumb_03_r"] = {0.0, -65.0001, 0.0}
handPositions["right_thumb"]["off"] = {}
-- handPositions["right_thumb"]["off"]["thumb_01_r"] = {-49.577805387668, -13.69705658123, 96.563956884076}
-- handPositions["right_thumb"]["off"]["thumb_02_r"] = {-0.33185244686191, 0.9015362340615, -0.93989411285643}
-- handPositions["right_thumb"]["off"]["thumb_03_r"] = {1.3812861319926, -5.8651630444374, 2.3493002638159}
handPositions["right_thumb"]["off"]["thumb_01_r"] = {-39.9042, -20.5087, 73.5644}
handPositions["right_thumb"]["off"]["thumb_02_r"] = {1.8662, -23.194, 3.4899}
handPositions["right_thumb"]["off"]["thumb_03_r"] = {0.0, -10.0, 0.0}

--left hand
handPositions["left_grip_weapon"] = {}
handPositions["left_grip_weapon"]["on"] = {}
handPositions["left_grip_weapon"]["on"]["thumb_01_l"] = {-24.20783976116, -51.272386127135, 137.38483033276}
handPositions["left_grip_weapon"]["on"]["thumb_02_l"] = {-1.5356912528246, -31.275827620646, -1.2953207312888}
handPositions["left_grip_weapon"]["on"]["thumb_03_l"] = {0.34186023960116, -38.059592850004, 1.9242381438882}
handPositions["left_grip_weapon"]["on"]["index_01_l"] = {7.0920929088624, 4.7986127324078, 5.0669146679995}
handPositions["left_grip_weapon"]["on"]["index_02_l"] = {-4.6990534898581, -30.197812903734, 1.3075262985282}
handPositions["left_grip_weapon"]["on"]["index_03_l"] = {-4.0495760352831, -52.008498512292, -0.23633296373659}
handPositions["left_grip_weapon"]["on"]["middle_01_l"] = {0.52773803768421, -62.555259712865, -1.4417866199984}
handPositions["left_grip_weapon"]["on"]["middle_02_l"] = {-7.9244756038727, -37.922313050749, 2.2669434745052}
handPositions["left_grip_weapon"]["on"]["middle_03_l"] = {-8.5498751750898, -63.672823136749, 7.9168822604688}
handPositions["left_grip_weapon"]["on"]["ring_01_l"] = {-5.5174528245127, -71.597171596966, -14.774660635087}
handPositions["left_grip_weapon"]["on"]["ring_02_l"] = {0.85263322079528, -36.8142585252, 2.8827740756073}
handPositions["left_grip_weapon"]["on"]["ring_03_l"] = {-0.79957075601282, -73.25505341347, 0.3547396539162}
handPositions["left_grip_weapon"]["on"]["pinky_01_l"] = {-10.941003094511, -66.746702048574, -26.790252074308}
handPositions["left_grip_weapon"]["on"]["pinky_02_l"] = {7.2843824085156, -34.137070742496, 0.63067189632459}
handPositions["left_grip_weapon"]["on"]["pinky_03_l"] = {7.4794350327117, -45.522169160321, -0.52771348875812}

handPositions["left_trigger_weapon"] = {}
handPositions["left_trigger_weapon"]["on"] = {}
handPositions["left_trigger_weapon"]["on"]["index_01_l"] = {7.0920929088625, 4.7986127324078, 5.0669146679995}
handPositions["left_trigger_weapon"]["on"]["index_02_l"] = {-4.699053489859, -67.197812903735, 1.3075262985293}
handPositions["left_trigger_weapon"]["on"]["index_03_l"] = {-4.0495760352832, -72.008498512293, -0.2363329637356}
handPositions["left_trigger_weapon"]["off"] = {}
handPositions["left_trigger_weapon"]["off"]["index_01_l"] = {7.0920929088624, 4.7986127324078, 5.0669146679995}
handPositions["left_trigger_weapon"]["off"]["index_02_l"] = {-4.6990534898581, -30.197812903734, 1.3075262985282}
handPositions["left_trigger_weapon"]["off"]["index_03_l"] = {-4.0495760352831, -52.008498512292, -0.23633296373659}

handPositions["left_trigger"] = {}
handPositions["left_trigger"]["on"] = {}
handPositions["left_trigger"]["on"]["index_01_l"] = {0.0, -88.373, 0.0}
handPositions["left_trigger"]["on"]["index_02_l"] = {0.0, -74.8927, 0.0}
handPositions["left_trigger"]["on"]["index_03_l"] = {5.0, -47.5166, 0.0}
handPositions["left_trigger"]["off"] = {}
handPositions["left_trigger"]["off"]["index_01_l"] = {0.0, -23.373, 0.0}
handPositions["left_trigger"]["off"]["index_02_l"] = {0.0, -14.8926, 0.0}
handPositions["left_trigger"]["off"]["index_03_l"] = {0.0, -12.5165, 0.0}

handPositions["left_grip"] = {}
handPositions["left_grip"]["on"] = {}
handPositions["left_grip"]["on"]["thumb_01_l"] = {-24.9043, -25.5087, 63.5643}
handPositions["left_grip"]["on"]["thumb_02_l"] = {1.8661, -23.1941, 3.4899}
handPositions["left_grip"]["on"]["thumb_03_l"] = {0.0, -65.0001, 0.0}
handPositions["left_grip"]["on"]["middle_01_l"] = {0.0, -96.5728, 0.0}
handPositions["left_grip"]["on"]["middle_02_l"] = {0.0, -75.7694, 0.0}
handPositions["left_grip"]["on"]["middle_03_l"] = {0.0, -70.0001, 0.0}
handPositions["left_grip"]["on"]["ring_01_l"] = {0.1168, -94.4145, 6.3958}
handPositions["left_grip"]["on"]["ring_02_l"] = {0.0, -78.9641, 0.0}
handPositions["left_grip"]["on"]["ring_03_l"] = {0.0, -64.1681, 0.0}
handPositions["left_grip"]["on"]["pinky_01_l"] = {4.3949, -84.834, 10.4919}
handPositions["left_grip"]["on"]["pinky_02_l"] = {0.0, -81.2871, 0.0}
handPositions["left_grip"]["on"]["pinky_03_l"] = {0.0, -59.9171, 0.0}


handPositions["left_grip"]["off"] = {}
handPositions["left_grip"]["off"]["thumb_01_l"] = {-39.9042, -20.5087, 73.5644}
handPositions["left_grip"]["off"]["thumb_02_l"] = {1.8662, -23.194, 3.4899}
handPositions["left_grip"]["off"]["thumb_03_l"] = {0.0, -10.0, 0.0}
handPositions["left_grip"]["off"]["middle_01_l"] = {0.0, -31.5727, 0.0}
handPositions["left_grip"]["off"]["middle_02_l"] = {0.0, -20.7693, 0.0}
handPositions["left_grip"]["off"]["middle_03_l"] = {0.0, -10.0, 0.0}
handPositions["left_grip"]["off"]["ring_01_l"] = {0.1169, -29.4145, 6.3958}
handPositions["left_grip"]["off"]["ring_02_l"] = {0.0, -18.964, 0.0}
handPositions["left_grip"]["off"]["ring_03_l"] = {0.0, -9.168, 0.0}
handPositions["left_grip"]["off"]["pinky_01_l"] = {-0.605, -14.834, 10.492}
handPositions["left_grip"]["off"]["pinky_02_l"] = {0.0, -21.287, 0.0}
handPositions["left_grip"]["off"]["pinky_03_l"] ={0.0, -4.9171, 0.0}

handPositions["left_thumb"] = {}
handPositions["left_thumb"]["on"] = {}
handPositions["left_thumb"]["on"]["thumb_01_l"] = {-24.9043, -25.5087, 63.5643}
handPositions["left_thumb"]["on"]["thumb_02_l"] = {1.8661, -23.1941, 3.4899}
handPositions["left_thumb"]["on"]["thumb_03_l"] = {0.0, -65.0001, 0.0}
handPositions["left_thumb"]["off"] = {}
handPositions["left_thumb"]["off"]["thumb_01_l"] = {-39.9042, -20.5087, 73.5644}
handPositions["left_thumb"]["off"]["thumb_02_l"] = {1.8662, -23.194, 3.4899}
handPositions["left_thumb"]["off"]["thumb_03_l"] = {0.0, -10.0, 0.0}

local poses = {}
poses["open_left"] = { {"left_grip","off"}, {"left_trigger","off"}, {"left_thumb","off"} }
poses["open_right"] = { {"right_grip","off"}, {"right_trigger","off"}, {"right_thumb","off"} }
poses["grip_right_weapon"] = { {"right_grip_weapon","on"}, {"right_trigger_weapon","off"} }
poses["grip_left_weapon"] = { {"left_grip_weapon","on"}, {"left_trigger_weapon","off"} }

M.positions = handPositions
M.poses = poses
M.initialTranform = initialTransform

return M


