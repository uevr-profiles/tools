
local M = {}

local initialTransform = {}
initialTransform["right_hand"] = {}
-- initialTransform["right_hand"]["hand_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-27.25107383728, 0, 0}}
-- initialTransform["right_hand"]["index_01_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-5.8775792121887, 0.04368203505868, -0.24108771979809}}
-- initialTransform["right_hand"]["index_02_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-4.0796961784362, -0.00012228822743054, 0.00018851566716194}}
-- initialTransform["right_hand"]["index_03_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-2.5949394702911, -4.3134963902958e-06, -4.9885846294728e-05}}
-- initialTransform["right_hand"]["middle_01_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-6.0985074043273, 0.00040482947952114, -9.7855525325485e-05}}
-- initialTransform["right_hand"]["middle_02_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-5.1687684059143, -9.8246899142396e-05, 0.00011594464740483}}
-- initialTransform["right_hand"]["middle_03_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-2.4739210605622, -2.2848484206861e-05, -2.7938534913119e-05}}
-- initialTransform["right_hand"]["pinky_01_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-4.9604082107544, -0.12903216481203, 0.20100928843027}}
-- initialTransform["right_hand"]["pinky_02_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-3.8160467147827, 3.4487704454023e-05, 3.574102447601e-05}}
-- initialTransform["right_hand"]["pinky_03_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-2.0399484634399, -2.3305647118832e-05, -8.7319866054258e-05}}
-- initialTransform["right_hand"]["ring_01_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-5.645176410675, -0.041973333805799, 0.020851720124483}}
-- initialTransform["right_hand"]["ring_02_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-4.9771065711975, 2.1056330297142e-05, 5.1754278729277e-07}}
-- initialTransform["right_hand"]["ring_03_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-2.2650129795074, -8.114685624605e-05, -2.0429988580872e-05}}
-- initialTransform["right_hand"]["thumb_01_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-1.9924947023391, 1.3567930459976, 2.5815005302429}}
-- initialTransform["right_hand"]["thumb_02_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-4.378129005432, 0.00024236136238187, 4.8823032557266e-05}}
-- initialTransform["right_hand"]["thumb_03_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-3.0855994224548, -0.00032298054412649, -0.00020756483718287}}
-- -- initialTransform["right_hand"]["Weapon"] = {rotation = {10.419982752388, 73.582085143094, -3.6259894516245}, location = {-12.451015874802, 3.6110294952523, 3.2482000744749}}
-- -- initialTransform["right_hand"]["DataSpike_Base"] = {rotation = {-9.0978772512076, 178.2303617748, 94.498933027191}, location = {-10.417257663998, -0.41095891327132, -0.70230375007122}}
-- -- initialTransform["right_hand"]["DataSpike_Needle"] = {rotation = {3.9686767802826e-06, -1.8501944436076e-05, -5.1657290997632e-06}, location = {-13.405740948165, -2.6464840630069e-06, 5.5754208005965e-07}}
-- -- initialTransform["right_hand"]["pinky_r_root"] = {rotation = {24.552292569033, -9.2000132034845, -21.827129800853}, location = {-10.639059378387, 0.21432391487178, -4.4974436082393}}
-- -- initialTransform["right_hand"]["index_r_root"] = {rotation = {-13.47046509913, -0.7552348486881, 1.6188349232933}, location = {-12.428242791204, -0.26114413685718, 3.0921005415512}}
-- -- initialTransform["right_hand"]["middle_r_root"] = {rotation = {-0.54762089399148, 2.5732953136611, 4.2780110837133}, location = {-12.456296574477, -0.54194346484655, 0.063752278436368}}
-- -- initialTransform["right_hand"]["ring_r_root"] = {rotation = {14.440199794306, -7.1000354746915, -8.4487630827588}, location = {-11.773553139858, -0.39023332564102, -2.3762703860702}}
-- initialTransform["right_hand"]["lowerarm_twist_01_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.0, 0.0, 0.0}}
-- initialTransform["right_hand"]["upperarm_twist_01_r"] = {rotation = {0.0, 0.0, 0.0}, location = {1.9749859347939e-07, 9.0920366346836e-08, 9.1068795882165e-07}}


-- initialTransform["right_hand"]["lowerarm_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.0, 0.0, 0.0}}
-- initialTransform["right_hand"]["lowerarm_twist_01_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.0, 0.0, 0.0}}
-- initialTransform["right_hand"]["elbow_out_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.56794506311405, 0.40407261252398, -3.7387101650238}}
-- initialTransform["right_hand"]["elbow_in_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.5269718170166, 0.50011140108109, 4.7102055549622}}
-- initialTransform["right_hand"]["elbow_front_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-7.7265992164612, -6.4369559288026, 1.2296894788741}}
-- initialTransform["right_hand"]["elbow_back_r"] = {rotation = {0.0, 0.0, 0.0}, location = {3.7626206874847, 4.9990062713623, 0.63696265220636}}
-- initialTransform["right_hand"]["lowerarm_twist_02_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-6.8127484321594, -0.00025259115500376, -0.0002346310357666}}
-- initialTransform["right_hand"]["lowerarm_twist_03_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-13.625502586365, -0.00024916857358903, -0.00023406387481373}}
-- initialTransform["right_hand"]["lowerarm_twist_04_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-20.438249588013, -0.00025071439443991, -0.00023480204981752}}
-- initialTransform["right_hand"]["hand_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-27.25107383728, 1.1368683772162e-13, -1.1368683772162e-13}}
-- initialTransform["right_hand"]["wrist_in_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.98317086696625, 1.2344086170195, -0.060026809573174}}
-- initialTransform["right_hand"]["wrist_out_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-2.8420619964599, -3.3296697139741, 0.3630213439464}}
-- initialTransform["right_hand"]["pinky_metacarpal_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-3.3142936229705, -0.30592909455299, -2.3910501003266}}
-- initialTransform["right_hand"]["pinky_01_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-4.9604082107544, -0.12903216481203, 0.20100928843027}}
-- initialTransform["right_hand"]["pinky_02_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-3.8160467147827, 3.4487704454023e-05, 3.574102447601e-05}}
-- initialTransform["right_hand"]["pinky_03_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-2.0399484634399, -2.3305647118832e-05, -8.7319866054258e-05}}
-- initialTransform["right_hand"]["pinky_03_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.73348474502563, 0.6724445223808, -1.8943957854844e-05}}
-- initialTransform["right_hand"]["pinky_03_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.24677044153208, -0.41519230604172, -1.8966949880905e-05}}
-- initialTransform["right_hand"]["pinky_02_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.042531080543966, -0.81257838010788, -0.00010639612446539}}
-- initialTransform["right_hand"]["pinky_02_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.87186515331264, 0.7141141295433, -0.00010631269833539}}
-- initialTransform["right_hand"]["pinky_02_low_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-1.0632416009903, 0.7673757076264, -0.00010628143360236}}
-- initialTransform["right_hand"]["pinky_01_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.29713910818097, -1.0233652591705, -0.0072024129331112}}
-- initialTransform["right_hand"]["pinky_01_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-2.3595197200776, 0.77064037322998, -0.0010948417475447}}
-- initialTransform["right_hand"]["pinky_01_low_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-3.0444424152374, 0.80532604455942, -7.0587935567801e-05}}
-- initialTransform["right_hand"]["pinky_metacarpal_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-3.8218297958375, -1.2819803953171, -0.00014064829156268}}
-- initialTransform["right_hand"]["pinky_metacarpal_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-4.8759298324584, 1.3354572057724, -0.00079234346046064}}
-- initialTransform["right_hand"]["ring_metacarpal_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-3.3746068477629, -0.54204052686697, -1.0919238328933}}
-- initialTransform["right_hand"]["ring_01_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-5.645176410675, -0.041973333805799, 0.020851720124483}}
-- initialTransform["right_hand"]["ring_02_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-4.9771065711975, 2.1056330297142e-05, 5.1754278729277e-07}}
-- initialTransform["right_hand"]["ring_03_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-2.2650129795074, -8.114685624605e-05, -2.0429988580872e-05}}
-- initialTransform["right_hand"]["ring_03_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.96529823541641, 0.96743094921118, -8.7659565906506e-05}}
-- initialTransform["right_hand"]["ring_03_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.49352484941477, -0.49606457352635, -8.7672888184898e-05}}
-- initialTransform["right_hand"]["ring_02_low_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-1.2667579650879, 1.0428738594055, -0.00010808982187882}}
-- initialTransform["right_hand"]["ring_02_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-1.0458997488022, 0.91869235038757, -0.00010814079723787}}
-- initialTransform["right_hand"]["ring_02_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.30667704343793, -0.82828366756439, -0.0001082209055312}}
-- initialTransform["right_hand"]["ring_01_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-2.9328203201294, 1.1077181100845, -0.00010767913045129}}
-- initialTransform["right_hand"]["ring_01_low_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-3.9986629486084, 1.1251951456071, -0.00010763825412141}}
-- initialTransform["right_hand"]["ring_01_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.49720975756637, -0.74567747116083, -0.0001078628629898}}
-- initialTransform["right_hand"]["ring_metacarpal_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-4.1814527511598, -1.0767961740494, 5.8703066315502e-05}}
-- initialTransform["right_hand"]["ring_metacarpal_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-4.5626745223999, 2.3803339004517, 5.8915131262438e-05}}
-- initialTransform["right_hand"]["middle_metacarpal_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-3.3757636547088, -0.75356805324554, 0.18281854689116}}
-- initialTransform["right_hand"]["middle_01_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-6.0985074043273, 0.00040482947952114, -9.7855525325485e-05}}
-- initialTransform["right_hand"]["middle_02_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-5.1687684059143, -9.8246899142396e-05, 0.00011594464740483}}
-- initialTransform["right_hand"]["middle_03_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-2.4739210605622, -2.2848484206861e-05, -2.7938534913119e-05}}
-- initialTransform["right_hand"]["middle_03_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.51773518323898, -0.61081153154367, -0.0001083214810933}}
-- initialTransform["right_hand"]["middle_03_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.83621400594711, 0.94395393133163, -0.00010830535023842}}
-- initialTransform["right_hand"]["middle_02_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.55569928884502, -0.79793649911892, -0.00013639700773638}}
-- initialTransform["right_hand"]["middle_02_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.97778272628786, 1.1101002693176, -0.00013633933849633}}
-- initialTransform["right_hand"]["middle_02_low_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-1.5598024129868, 0.91057127714151, -0.00013625463185463}}
-- initialTransform["right_hand"]["middle_01_low_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-4.0533351898193, 1.0192729234695, -2.0400902997153e-05}}
-- initialTransform["right_hand"]["middle_01_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-2.8859083652497, 1.0808172225953, -2.0450597787658e-05}}
-- initialTransform["right_hand"]["middle_01_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.2842463850975, -0.73380142450327, -2.06240456464e-05}}
-- initialTransform["right_hand"]["middle_metacarpal_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-4.3566308021544, -1.0262367725372, -0.0001187219677945}}
-- initialTransform["right_hand"]["middle_metacarpal_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-4.9798431396484, 2.2772102355958, -0.00011851488676484}}
-- initialTransform["right_hand"]["index_metacarpal_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-3.4443509578704, -0.38474556803709, 2.3793292045593}}
-- initialTransform["right_hand"]["index_01_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-5.8775792121887, 0.04368203505868, -0.24108771979809}}
-- initialTransform["right_hand"]["index_02_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-4.0796961784362, -0.00012228822743054, 0.00018851566716194}}
-- initialTransform["right_hand"]["index_03_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-2.5949394702911, -4.3134963902958e-06, -4.9885846294728e-05}}
-- initialTransform["right_hand"]["index_03_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.34651583433146, 0.70611923933029, -0.00010648272296976}}
-- initialTransform["right_hand"]["index_03_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.18430359661579, -0.82401967048645, 0.00029663398163393}}
-- initialTransform["right_hand"]["index_02_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-6.1497470596805e-05, -0.80002892017353, -0.00015655040624551}}
-- initialTransform["right_hand"]["index_02_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.70006150007254, 0.99997109174728, -0.00015643401997067}}
-- initialTransform["right_hand"]["index_02_low_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-1.9975650310516, 0.71093130111689, -0.00015639913902987}}
-- initialTransform["right_hand"]["index_01_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.19633370637894, -0.73490333557135, 2.8707918374948e-05}}
-- initialTransform["right_hand"]["index_01_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-2.1082413196564, 0.99525427818298, -0.0092530362307457}}
-- initialTransform["right_hand"]["index_01_low_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-3.2997629642487, 0.81244635581965, 3.2033636728102e-05}}
-- initialTransform["right_hand"]["index_metacarpal_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-4.0634307861328, -1.0317858457565, -0.00018105361954213}}
-- initialTransform["right_hand"]["index_metacarpal_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-5.4899377822876, 1.8375984430313, 0.00550089543691}}
-- initialTransform["right_hand"]["thumb_01_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-1.9924947023391, 1.3567930459976, 2.5815005302429}}
-- initialTransform["right_hand"]["thumb_02_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-4.378129005432, 0.00024236136238187, 4.8823032557266e-05}}
-- initialTransform["right_hand"]["thumb_03_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-3.0855994224548, -0.00032298054412649, -0.00020756483718287}}
-- initialTransform["right_hand"]["thumb_03_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.10165080428129, -0.92997610569012, 7.003741481526e-05}}
-- initialTransform["right_hand"]["thumb_03_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.8562319278717, 1.1355873346327, 7.0150679619019e-05}}
-- initialTransform["right_hand"]["thumb_02_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.037134140729904, -1.2190182209014, -0.00013748543280201}}
-- initialTransform["right_hand"]["thumb_02_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-1.2500386238099, 1.0410566329956, -0.00013741370642606}}
-- initialTransform["right_hand"]["thumb_02_low_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-2.5300619602203, 1.073670268059, -0.0016547699924274}}
-- initialTransform["right_hand"]["thumb_01_in_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-3.6961188316344, -0.26129248738283, -1.7977414131165}}
-- initialTransform["right_hand"]["thumb_01_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-2.6225190162657, 2.5136947631835, 0.00044943956889654}}
-- initialTransform["right_hand"]["thumb_01_low_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-4.1562614440916, 1.6022206544876, -8.2435442891438e-05}}
-- initialTransform["right_hand"]["thumb_01_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-2.0336425304412, -1.0626704692841, -0.013145953416839}}
-- initialTransform["right_hand"]["thumb_01_out_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-1.9998319149016, -0.0006983643396552, 1.5004757642746}}
-- initialTransform["right_hand"]["prop_root_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.0, 0.0, -5.6843418860808e-14}}
-- initialTransform["right_hand"]["prop_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-10.458946228027, 3.5681738853455, 0.69981569051737}}
-- initialTransform["right_hand"]["upperarm_twist_01_r"] = {rotation = {0.0, 0.0, 0.0}, location = {1.9749859347939e-07, 9.0920366346836e-08, 9.1068795882165e-07}}
-- initialTransform["right_hand"]["shoulder_out_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.22076117992401, 0.052129585295916, -5.8037457465834}}
-- initialTransform["right_hand"]["shoulder_in_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-6.4105448723421, -0.54409122472862, 4.7620754242234}}
-- initialTransform["right_hand"]["shoulder_back_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-1.4680680037127, 7.6447730064392, -0.3855186701112}}
-- initialTransform["right_hand"]["shoulder_front_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-3.2554750442505, -8.508825302124, 1.0632492303266}}
-- initialTransform["right_hand"]["upperarm_twist_02_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-6.9430041312589, -0.00025122123770416, -0.00023100900580175}}
-- initialTransform["right_hand"]["upperarm_twist_03_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-13.88600063324, 2.9103830456734e-11, -0.00023545991280116}}
-- initialTransform["right_hand"]["bicep_front_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.17139241099358, -5.575855255127, 1.5490089654922}}
-- initialTransform["right_hand"]["bicep_back_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-2.0996656417847, 4.9314041137695, 0.16107603910496}}
-- initialTransform["right_hand"]["upperarm_twist_04_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-20.828996658325, -0.00025169286527671, -0.00023835300817154}}

--initialTransform["right_hand"]["lowerarm_r"] = {rotation = {0.0, -90.0001, 90.0}, location = {0.0, 0.0, 0.0}}
initialTransform["right_hand"]["lowerarm_twist_01_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.0, 0.0, 0.0}}
initialTransform["right_hand"]["elbow_out_r"] = {rotation = {-0.3141, -25.6801, -1.0286}, location = {-0.5676, 0.3992, -3.7674}}
initialTransform["right_hand"]["elbow_in_r"] = {rotation = {-0.4092, -25.5503, -179.1168}, location = {-0.5231, 0.4955, 4.7251}}
initialTransform["right_hand"]["elbow_front_r"] = {rotation = {-0.1845, -36.6544, 90.972}, location = {-7.8795, -6.5074, 1.2497}}
initialTransform["right_hand"]["elbow_back_r"] = {rotation = {0.3101, -58.8954, -89.099}, location = {3.8773, 5.001, 0.6232}}
initialTransform["right_hand"]["lowerarm_twist_02_r"] = {rotation = {0.0, 0.0, -33.6945}, location = {-6.8128, -0.0003, -0.0003}}
initialTransform["right_hand"]["lowerarm_twist_03_r"] = {rotation = {0.0, 0.0, -67.389}, location = {-13.6256, -0.0003, -0.0003}}
initialTransform["right_hand"]["lowerarm_twist_04_r"] = {rotation = {0.0, 0.0, -101.2732}, location = {-20.4383, -0.0003, -0.0003}}
initialTransform["right_hand"]["hand_r"] = {rotation = {0.0, 0.0, -90.0001}, location = {-27.2511, 0.0, 0.0}}
initialTransform["right_hand"]["wrist_in_r"] = {rotation = {-17.8044, -43.3216, -76.0675}, location = {0.9715, 1.2461, -0.0608}}
initialTransform["right_hand"]["wrist_out_r"] = {rotation = {-15.6386, -22.3312, 96.7168}, location = {-2.8065, -3.3195, 0.3603}}
initialTransform["right_hand"]["pinky_metacarpal_r"] = {rotation = {14.2555, -13.7615, -115.2797}, location = {-3.3143, -0.306, -2.3911}}
initialTransform["right_hand"]["pinky_01_r"] = {rotation = {41.6416, 17.1891, 117.9266}, location = {-4.9605, -0.1291, 0.201}}
initialTransform["right_hand"]["pinky_02_r"] = {rotation = {0.4711, -49.3727, 0.6421}, location = {-3.8161, 0.0, 0.0}}
initialTransform["right_hand"]["pinky_03_r"] = {rotation = {-0.2562, -72.1729, 1.1707}, location = {-2.04, 0.0, 0.0}}
initialTransform["right_hand"]["pinky_03_dn_r"] = {rotation = {0.0, 2.2245, 0.0}, location = {-0.7335, 0.6724, 0.0}}
initialTransform["right_hand"]["pinky_03_up_r"] = {rotation = {0.0, 30.4895, 0.0}, location = {0.2467, -0.4152, 0.0}}
initialTransform["right_hand"]["pinky_02_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.0425, -0.8126, -0.0002}}
initialTransform["right_hand"]["pinky_02_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.8719, 0.7141, -0.0002}}
initialTransform["right_hand"]["pinky_02_low_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-1.0633, 0.7673, -0.0002}}
initialTransform["right_hand"]["pinky_01_up_r"] = {rotation = {0.0, 11.4918, 0.0}, location = {0.2971, -1.0234, -0.0073}}
initialTransform["right_hand"]["pinky_01_dn_r"] = {rotation = {0.0, 4.6482, 0.0}, location = {-2.3596, 0.7706, -0.0011}}
initialTransform["right_hand"]["pinky_01_low_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-3.0445, 0.8053, 0.0}}
initialTransform["right_hand"]["pinky_metacarpal_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-3.8219, -1.282, -0.0002}}
initialTransform["right_hand"]["pinky_metacarpal_dn_r"] = {rotation = {0.003, 5.8244, 0.0049}, location = {-4.876, 1.3354, -0.0008}}
initialTransform["right_hand"]["ring_metacarpal_r"] = {rotation = {10.2067, -4.7396, -14.5112}, location = {-3.3747, -0.5421, -1.092}}
initialTransform["right_hand"]["ring_01_r"] = {rotation = {15.7393, -60.0243, 10.5881}, location = {-5.6452, -0.042, 0.0208}}
initialTransform["right_hand"]["ring_02_r"] = {rotation = {-3.0298, -52.2023, -2.1299}, location = {-4.9772, 0.0, 0.0}}
initialTransform["right_hand"]["ring_03_r"] = {rotation = {0.0401, -79.5924, 1.7956}, location = {-2.2651, 0.0, 0.0}}
initialTransform["right_hand"]["ring_03_dn_r"] = {rotation = {0.0, 4.0784, 0.0}, location = {-0.9653, 0.9674, 0.0}}
initialTransform["right_hand"]["ring_03_up_r"] = {rotation = {0.0, 31.8363, 0.0}, location = {0.4935, -0.4961, 0.0}}
initialTransform["right_hand"]["ring_02_low_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-1.2668, 1.0428, -0.0002}}
initialTransform["right_hand"]["ring_02_dn_r"] = {rotation = {0.0, 1.8716, 0.0}, location = {-1.0459, 0.9186, -0.0002}}
initialTransform["right_hand"]["ring_02_up_r"] = {rotation = {0.0, 15.4767, 0.0}, location = {0.3066, -0.8283, -0.0002}}
initialTransform["right_hand"]["ring_01_dn_r"] = {rotation = {0.0, 6.466, 0.0}, location = {-2.9329, 1.1077, -0.0002}}
initialTransform["right_hand"]["ring_01_low_r"] = {rotation = {0.0, 1.4638, 0.0}, location = {-3.9987, 1.1251, -0.0002}}
initialTransform["right_hand"]["ring_01_up_r"] = {rotation = {0.0, 19.6002, 0.0}, location = {0.4972, -0.7457, -0.0002}}
initialTransform["right_hand"]["ring_metacarpal_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-4.1815, -1.0768, 0.0}}
initialTransform["right_hand"]["ring_metacarpal_dn_r"] = {rotation = {0.0, 9.676, 0.0}, location = {-4.5627, 2.3803, 0.0}}
initialTransform["right_hand"]["middle_metacarpal_r"] = {rotation = {3.2546, -2.012, -3.7047}, location = {-3.3758, -0.7536, 0.1828}}
initialTransform["right_hand"]["middle_01_r"] = {rotation = {9.7553, -59.0363, -0.0767}, location = {-6.0986, 0.0004, 0.0}}
initialTransform["right_hand"]["middle_02_r"] = {rotation = {-0.0011, -64.376, 0.0001}, location = {-5.1688, 0.0, 0.0001}}
initialTransform["right_hand"]["middle_03_r"] = {rotation = {0.1968, -70.3749, 1.9692}, location = {-2.474, 0.0, 0.0}}
initialTransform["right_hand"]["middle_03_up_r"] = {rotation = {0.0, 27.5265, 0.0}, location = {0.5177, -0.6109, -0.0002}}
initialTransform["right_hand"]["middle_03_dn_r"] = {rotation = {0.0, 6.5121, 0.0}, location = {-0.8363, 0.9439, -0.0002}}
initialTransform["right_hand"]["middle_02_up_r"] = {rotation = {0.0, 20.1217, 0.0}, location = {0.5556, -0.798, -0.0002}}
initialTransform["right_hand"]["middle_02_dn_r"] = {rotation = {0.0, 5.9982, 0.0}, location = {-0.9778, 1.1101, -0.0002}}
initialTransform["right_hand"]["middle_02_low_r"] = {rotation = {0.0, 1.6408, 0.0}, location = {-1.5599, 0.9105, -0.0002}}
initialTransform["right_hand"]["middle_01_low_r"] = {rotation = {0.0, -3.9353, 0.0}, location = {-4.0534, 1.0192, 0.0}}
initialTransform["right_hand"]["middle_01_dn_r"] = {rotation = {0.0, 0.8547, 0.0}, location = {-2.886, 1.0808, 0.0}}
initialTransform["right_hand"]["middle_01_up_r"] = {rotation = {0.0, 12.511, 0.0}, location = {0.2842, -0.7339, 0.0}}
initialTransform["right_hand"]["middle_metacarpal_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-4.3567, -1.0263, -0.0002}}
initialTransform["right_hand"]["middle_metacarpal_dn_r"] = {rotation = {0.0, 8.2412, 0.0}, location = {-4.9799, 2.2772, -0.0002}}
initialTransform["right_hand"]["index_metacarpal_r"] = {rotation = {-7.4849, 3.6686, 2.8885}, location = {-3.4444, -0.3848, 2.3793}}
initialTransform["right_hand"]["index_01_r"] = {rotation = {2.9219, -32.1992, -0.943}, location = {-5.8776, 0.0436, -0.2411}}
initialTransform["right_hand"]["index_02_r"] = {rotation = {0.0, -4.8927, 0.0}, location = {-4.0797, -0.0002, 0.0001}}
initialTransform["right_hand"]["index_03_r"] = {rotation = {0.0005, -28.5117, -0.0027}, location = {-2.595, 0.0, 0.0}}
initialTransform["right_hand"]["index_03_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.3466, 0.7061, -0.0002}}
initialTransform["right_hand"]["index_03_up_r"] = {rotation = {-0.9093, -10.2536, -0.1134}, location = {-0.1844, -0.8241, 0.0002}}
initialTransform["right_hand"]["index_02_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.0, -0.8001, -0.0002}}
initialTransform["right_hand"]["index_02_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.7001, 0.9999, -0.0002}}
initialTransform["right_hand"]["index_02_low_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-1.9976, 0.7109, -0.0002}}
initialTransform["right_hand"]["index_01_up_r"] = {rotation = {0.0, 4.3529, 0.0}, location = {0.1963, -0.735, 0.0}}
initialTransform["right_hand"]["index_01_dn_r"] = {rotation = {0.0, 1.9096, 0.0}, location = {-2.1083, 0.9952, -0.0093}}
initialTransform["right_hand"]["index_01_low_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-3.2998, 0.8124, 0.0}}
initialTransform["right_hand"]["index_metacarpal_up_r"] = {rotation = {0.0, -0.6823, 0.0}, location = {-4.0635, -1.0318, -0.0002}}
initialTransform["right_hand"]["index_metacarpal_dn_r"] = {rotation = {0.0, -1.5557, 0.0}, location = {-5.49, 1.8375, 0.0055}}
initialTransform["right_hand"]["thumb_01_r"] = {rotation = {-10.2745, -59.5443, 140.0935}, location = {-1.9925, 1.3567, 2.5815}}
initialTransform["right_hand"]["thumb_02_r"] = {rotation = {4.8186, -43.4889, 5.4114}, location = {-4.3782, 0.0002, 0.0}}
initialTransform["right_hand"]["thumb_03_r"] = {rotation = {-0.0014, -23.637, -0.0028}, location = {-3.0856, -0.0004, -0.0003}}
initialTransform["right_hand"]["thumb_03_up_r"] = {rotation = {0.0, 6.3835, 0.0}, location = {0.1016, -0.93, 0.0}}
initialTransform["right_hand"]["thumb_03_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.8563, 1.1355, 0.0}}
initialTransform["right_hand"]["thumb_02_up_r"] = {rotation = {0.0, -2.9895, 0.0}, location = {-0.0372, -1.2191, -0.0002}}
initialTransform["right_hand"]["thumb_02_dn_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-1.2501, 1.041, -0.0002}}
initialTransform["right_hand"]["thumb_02_low_r"] = {rotation = {0.0, 2.0996, 0.0}, location = {-2.5301, 1.0736, -0.0017}}
initialTransform["right_hand"]["thumb_01_in_r"] = {rotation = {4.9664, 5.1043, 13.6933}, location = {-3.6962, -0.2613, -1.7978}}
initialTransform["right_hand"]["thumb_01_dn_r"] = {rotation = {0.0, 2.9405, 0.0}, location = {-2.6226, 2.5136, 0.0004}}
initialTransform["right_hand"]["thumb_01_low_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-4.1563, 1.6022, 0.0}}
initialTransform["right_hand"]["thumb_01_up_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-2.0337, -1.0627, -0.0132}}
initialTransform["right_hand"]["thumb_01_out_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-1.9999, -0.0007, 1.5004}}
initialTransform["right_hand"]["prop_root_r"] = {rotation = {0.0, 0.0, 0.0}, location = {0.0, 0.0, 0.0}}
initialTransform["right_hand"]["prop_r"] = {rotation = {11.8377, 69.3753, 6.5058}, location = {-10.4584, 3.5699, 0.698}}
initialTransform["right_hand"]["upperarm_twist_01_r"] = {rotation = {0.0, 0.0, -24.0535}, location = {0.0, 0.0, 0.0}}
initialTransform["right_hand"]["shoulder_out_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-0.2208, 0.0521, -5.8038}}
initialTransform["right_hand"]["shoulder_in_r"] = {rotation = {48.1939, -0.0022, 179.999}, location = {-6.4106, -0.5441, 4.762}}
initialTransform["right_hand"]["shoulder_back_r"] = {rotation = {0.0, 0.0, -71.3387}, location = {-1.4681, 7.6447, -0.3856}}
initialTransform["right_hand"]["shoulder_front_r"] = {rotation = {1.952, -11.8776, 98.9451}, location = {-3.2555, -8.5089, 1.0632}}
initialTransform["right_hand"]["upperarm_twist_02_r"] = {rotation = {0.0, 0.0, -15.9615}, location = {-6.9431, -0.0003, -0.0003}}
initialTransform["right_hand"]["upperarm_twist_03_r"] = {rotation = {0.0, 0.0, -7.981}, location = {-13.8861, 0.0, -0.0003}}
initialTransform["right_hand"]["bicep_front_r"] = {rotation = {1.7281, -1.9473, 85.0766}, location = {0.1899, -5.5997, 1.5444}}
initialTransform["right_hand"]["bicep_back_r"] = {rotation = {0.7446, -0.6987, -94.9675}, location = {-2.1398, 4.9329, 0.1605}}
initialTransform["right_hand"]["upperarm_twist_04_r"] = {rotation = {0.0, 0.0, 0.0}, location = {-20.829, -0.0003, -0.0003}}


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
handPositions["right_grip"]["on"]["thumb_01_r"] = {-24.20783976116, -51.272386127135, 137.38483033276}
handPositions["right_grip"]["on"]["thumb_02_r"] = {-1.5356912528246, -31.275827620646, -1.2953207312888}
handPositions["right_grip"]["on"]["thumb_03_r"] = {0.34186023960116, -38.059592850004, 1.9242381438882}
--handPositions["right_grip"]["on"]["index_01_r"] = {7.0920929088624, 4.7986127324078, 5.0669146679995}
--handPositions["right_grip"]["on"]["index_02_r"] = {-4.6990534898581, -30.197812903734, 1.3075262985282}
--handPositions["right_grip"]["on"]["index_03_r"] = {-4.0495760352831, -52.008498512292, -0.23633296373659}
handPositions["right_grip"]["on"]["middle_01_r"] = {0.52773803768421, -62.555259712865, -1.4417866199984}
handPositions["right_grip"]["on"]["middle_02_r"] = {-7.9244756038727, -37.922313050749, 2.2669434745052}
handPositions["right_grip"]["on"]["middle_03_r"] = {-8.5498751750898, -63.672823136749, 7.9168822604688}
handPositions["right_grip"]["on"]["ring_01_r"] = {-5.5174528245127, -71.597171596966, -14.774660635087}
handPositions["right_grip"]["on"]["ring_02_r"] = {0.85263322079528, -36.8142585252, 2.8827740756073}
handPositions["right_grip"]["on"]["ring_03_r"] = {-0.79957075601282, -73.25505341347, 0.3547396539162}
handPositions["right_grip"]["on"]["pinky_01_r"] = {-10.941003094511, -66.746702048574, -26.790252074308}
handPositions["right_grip"]["on"]["pinky_02_r"] = {7.2843824085156, -34.137070742496, 0.63067189632459}
handPositions["right_grip"]["on"]["pinky_03_r"] = {7.4794350327117, -45.522169160321, -0.52771348875812}

handPositions["right_grip"]["off"] = {}
handPositions["right_grip"]["off"]["thumb_01_r"] = {-49.577805387668, -13.69705658123, 96.563956884076}
handPositions["right_grip"]["off"]["thumb_02_r"] = {-0.33185244686191, 0.9015362340615, -0.93989411285643}
handPositions["right_grip"]["off"]["thumb_03_r"] = {1.3812861319926, -5.8651630444374, 2.3493002638159}
--handPositions["right_grip"]["off"]["index_01_r"] = {-13.579874286286, -0.53973389491354, 0.83556637092762}
--handPositions["right_grip"]["off"]["index_02_r"] = {-0.86297378936018, -2.3855033056582, 1.3962212178538}
--handPositions["right_grip"]["off"]["index_03_r"] = {-1.0207031394195, -1.5925566715179, 1.3048430900779}
handPositions["right_grip"]["off"]["middle_01_r"] = {-0.61197760426513, 2.6091063423177, 3.5127252293566}
handPositions["right_grip"]["off"]["middle_02_r"] = {0.65851420087222, -1.4360898250764, -2.1628375632663}
handPositions["right_grip"]["off"]["middle_03_r"] = {0.24563439735232, -5.7038263031414, -0.48144010021698}
handPositions["right_grip"]["off"]["ring_01_r"] = {14.242078919551, -7.2583922876718, -9.2103150785967}
handPositions["right_grip"]["off"]["ring_02_r"] = {1.4362708068534, -0.63116075415223, 0.42927614097496}
handPositions["right_grip"]["off"]["ring_03_r"] = {-2.9743965073767, -2.5235424223701, 0.44344084853422}
handPositions["right_grip"]["off"]["pinky_01_r"] = {24.326927168512, -9.4997210434888, -22.628232265789}
handPositions["right_grip"]["off"]["pinky_02_r"] = {2.3322582224589, -2.4051816452145, 1.1126082813598}
handPositions["right_grip"]["off"]["pinky_03_r"] = {-0.56130633446169, -0.91036866551225, 0.22129312654942}


handPositions["right_trigger"] = {}
handPositions["right_trigger"]["on"] = {}
handPositions["right_trigger"]["on"]["index_01_r"] = {7.0920929088621, -50.201387267592, 5.0669146679995}
handPositions["right_trigger"]["on"]["index_02_r"] = {-4.6990534898584, -65.197812903735, 1.3075262985288}
handPositions["right_trigger"]["on"]["index_03_r"] = {-4.0495760352828, -62.008498512293, -0.23633296373576}
handPositions["right_trigger"]["off"] = {}
handPositions["right_trigger"]["off"]["index_01_r"] = {-13.579874286286, -0.53973389491354, 0.83556637092762}
handPositions["right_trigger"]["off"]["index_02_r"] = {-0.86297378936018, -2.3855033056582, 1.3962212178538}
handPositions["right_trigger"]["off"]["index_03_r"] = {-1.0207031394195, -1.5925566715179, 1.3048430900779}

handPositions["right_thumb"] = {}
handPositions["right_thumb"]["on"] = {}
handPositions["right_thumb"]["on"]["thumb_01_r"] = {-24.20783976116, -51.272386127135, 137.38483033276}
handPositions["right_thumb"]["on"]["thumb_02_r"] = {-1.5356912528246, -31.275827620646, -1.2953207312888}
handPositions["right_thumb"]["on"]["thumb_03_r"] = {0.34186023960116, -38.059592850004, 1.9242381438882}
handPositions["right_thumb"]["off"] = {}
handPositions["right_thumb"]["off"]["thumb_01_r"] = {-49.577805387668, -13.69705658123, 96.563956884076}
handPositions["right_thumb"]["off"]["thumb_02_r"] = {-0.33185244686191, 0.9015362340615, -0.93989411285643}
handPositions["right_thumb"]["off"]["thumb_03_r"] = {1.3812861319926, -5.8651630444374, 2.3493002638159}

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


