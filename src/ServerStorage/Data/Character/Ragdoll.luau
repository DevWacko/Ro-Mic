local Ragdoll = {}

Ragdoll.Defaults = {
	BallSocketConstrains = {
		UpperAngle = 15,
		TwistLowerAngle = -45,
		TwistUpperAngle = 45,
	}
}

Ragdoll.SocketData = {
	R15 = {
		["Waist"] = {
			A0 = "LowerTorso/WaistRigAttachment",
			A1 = "UpperTorso/WaistRigAttachment",
		},
		["Neck"] = {
			A0 = "UpperTorso/NeckRigAttachment",
			A1 = "Head/NeckRigAttachment",
		},
		
		["RightShoulder"] = {
			A0 = "UpperTorso/RightShoulderRigAttachment",
			A1 = "RightUpperArm/RightShoulderRigAttachment",
		},
		["RightElbow"] = {
			A0 = "RightUpperArm/RightElbowRigAttachment",
			A1 = "RightLowerArm/RightElbowRigAttachment",
			
			UpperAngle = 0,
			TwistLowerAngle = -90,
			TwistUpperAngle = 0,
		},
		["RightWrist"] = {
			A0 = "RightLowerArm/RightWristRigAttachment",
			A1 = "RightHand/RightWristRigAttachment",
		},
		
		["LeftShoulder"] = {
			A0 = "UpperTorso/LeftShoulderRigAttachment",
			A1 = "LeftUpperArm/LeftShoulderRigAttachment"
		},
		["LeftElbow"] = {
			A0 = "LeftUpperArm/LeftElbowRigAttachment",
			A1 = "LeftLowerArm/LeftElbowRigAttachment",
			
			UpperAngle = 0,
			TwistLowerAngle = 0,
			TwistUpperAngle = -90,
		},
		["LeftWrist"] = {
			A0 = "LeftLowerArm/LeftWristRigAttachment",
			A1 = "LeftHand/LeftWristRigAttachment",
		},
		
		["RightHip"] = {
			A0 = "LowerTorso/RightHipRigAttachment",
			A1 = "RightUpperLeg/RightHipRigAttachment",
		},
		["RightKnee"] = {
			A0 = "RightUpperLeg/RightKneeRigAttachment",
			A1 = "RightLowerLeg/RightKneeRigAttachment",
			
			UpperAngle = 0,
			TwistLowerAngle = 0,
			TwistUpperAngle = -90,
		},
		["RightAnkle"] = {
			A0 = "RightLowerLeg/RightAnkleRigAttachment",
			A1 = "RightFoot/RightAnkleRigAttachment",
		},
		
		["LeftHip"] = {
			A0 = "LowerTorso/LeftHipRigAttachment",
			A1 = "LeftUpperLeg/LeftHipRigAttachment",
		},
		["LeftKnee"] = {
			A0 = "LeftUpperLeg/LeftKneeRigAttachment",
			A1 = "LeftLowerLeg/LeftKneeRigAttachment",
			
			UpperAngle = 0,
			TwistLowerAngle = 0,
			TwistUpperAngle = -90,
		},
		["LeftAnkle"] = {
			A0 = "LeftLowerLeg/LeftAnkleRigAttachment",
			A1 = "LeftFoot/LeftAnkleRigAttachment",
		},
	},
}

return Ragdoll