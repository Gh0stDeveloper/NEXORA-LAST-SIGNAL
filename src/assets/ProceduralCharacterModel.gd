class_name DeadfallProceduralCharacterModel
extends RefCounted

const M = preload("res://src/assets/PresentationMesh.gd")
const Rig = preload("res://src/assets/CharacterRig.gd")
const Cosmetics = preload("res://src/customization/CosmeticCatalog.gd")
const UniversalAnimations = preload("res://src/assets/UniversalAnimationLibrary.gd")

static func create_operator(character_id: StringName = &"operator_01", slot_index: int = 0, appearance: Dictionary = {}) -> Node3D:
	# LAST SIGNAL now uses one universal gameplay character. Gender and wardrobe
	# change its presentation without changing hitboxes, movement or animation rig.
	return create_fallback_operator(character_id, slot_index, appearance)

static func create_fallback_operator(character_id: StringName = &"operator_01", slot_index: int = 0, appearance: Dictionary = {}) -> Node3D:
	var root := Rig.new()
	root.name = "UniversalOperator"
	var gender := String(appearance.get("gender", "female" if character_id == &"operator_01" else "male"))
	gender = "male" if gender == "male" else "female"
	var raw_cosmetics = appearance.get("cosmetics", {})
	var requested: Dictionary = raw_cosmetics if raw_cosmetics is Dictionary else {}
	var cosmetics := Cosmetics.sanitize_loadout(requested, gender)
	root.appearance = {
		"gender":gender,
		"profile_icon":String(appearance.get("profile_icon", Cosmetics.default_profile_icon(gender))),
		"cosmetics":cosmetics.duplicate(true),
	}

	var top := Cosmetics.item_color(StringName(cosmetics["top"]), Color("405052") if gender == "female" else Color("354651"))
	var pants := Cosmetics.item_color(StringName(cosmetics["pants"]), Color("46504a") if gender == "female" else Color("394754"))
	var shoes := Cosmetics.item_color(StringName(cosmetics["shoes"]), Color("293235"))
	var outerwear := Cosmetics.item_color(StringName(cosmetics["outerwear"]), Color("26363b"))
	var cloth := M.material(top)
	var pants_mat := M.material(pants)
	var shoes_mat := M.material(shoes, 0.08, 0.72)
	var armor := M.material(outerwear, 0.12, 0.78)
	var dark := M.material(Color("172329"), 0.1, 0.65)
	var accent := M.material(Color("c78d55") if gender == "female" else Color("53b3ce"), 0.05, 0.82)
	var skin := M.material(Color("aa7860") if gender == "female" else Color("77533f"))
	var steel := M.material(Color("8c9b9b"), 0.7, 0.34)

	_build_operator_limbs(root, cloth, pants_mat, shoes_mat, armor, skin)
	M.box(root, "Pelvis", Vector3(0.35 if gender == "female" else 0.34, 0.19, 0.25), Vector3(0,0.87,0), pants_mat)
	var torso := M.joint(root, "Torso", Vector3(0,1.17,0))
	var jacket := M.capsule(torso,"Jacket",0.215 if gender == "female" else 0.225,0.48,Vector3.ZERO,cloth)
	jacket.scale.z = 0.62
	M.box(torso,"PlateCarrier",Vector3(0.38 if gender == "female" else 0.40,0.38,0.11),Vector3(0,0.02,-0.16),armor)
	M.box(torso,"ChestInsert",Vector3(0.29,0.16,0.045),Vector3(0,0.10,-0.235),dark)
	M.box(torso,"Callsign",Vector3(0.12,0.038,0.02),Vector3(-0.07,0.12,-0.26),accent)
	for i in range(3):
		M.box(torso,"MagazinePouch%d"%i,Vector3(0.09,0.14,0.055),Vector3(-0.105+i*0.105,-0.09,-0.245),armor)
		M.box(torso,"PouchFlap%d"%i,Vector3(0.095,0.033,0.065),Vector3(-0.105+i*0.105,-0.035,-0.25),dark)
	for side in [-1,1]:
		M.box(torso,"Strap%d"%side,Vector3(0.053,0.37,0.043),Vector3(side*0.155,0.10,-0.15),dark)
		M.box(torso,"Buckle%d"%side,Vector3(0.062,0.04,0.052),Vector3(side*0.155,0.12,-0.17),steel)
	M.box(root,"Belt",Vector3(0.38,0.055,0.29),Vector3(0,0.94,0),dark)
	M.box(root,"BeltBuckle",Vector3(0.055,0.045,0.03),Vector3(0,0.94,-0.16),steel)
	M.box(root,"UtilityPouch",Vector3(0.10,0.16,0.11),Vector3(-0.23,0.89,0.02),armor)
	M.box(root,"Holster",Vector3(0.09,0.24,0.10),Vector3(0.23,0.77,0.02),dark)
	M.capsule(root,"Neck",0.062,0.14,Vector3(0,1.43,0),skin)
	var head := M.joint(root,"Head",Vector3(0,1.56,0))
	_build_gender_head(head, gender, skin, dark, armor)
	_add_headwear(head, StringName(cosmetics["headwear"]))
	_add_glasses(head, StringName(cosmetics["glasses"]))
	M.box(torso,"Backpack",Vector3(0.29,0.36,0.15),Vector3(0,0.0,0.18),armor)
	M.box(torso,"Radio",Vector3(0.055,0.13,0.055),Vector3(0.19,0.16,0.10),dark)
	M.cylinder(torso,"Antenna",0.006,0.19,Vector3(0.19,0.29,0.10),steel)
	M.box(root,"SquadStripe",Vector3(0.12,0.04,0.022),Vector3(-0.27,1.30,0),accent)

	if gender == "female":
		root.scale = Vector3(0.955, 1.0, 0.955)
	root.set_meta("source","universal_procedural")
	root.set_meta("visual_height",1.69)
	root.set_meta("character_id",character_id)
	root.set_meta("slot",slot_index)
	root.set_meta("gender",gender)
	root.set_meta("cosmetics",cosmetics.duplicate(true))
	root.set_meta("animation_source_sha256",UniversalAnimations.SOURCE_SHA256)
	root.equip_visual(0)
	root.animate_pose(0,0)
	return root

static func _build_gender_head(head: Node3D, gender: String, skin: Material, dark: Material, armor: Material) -> void:
	if gender == "female":
		preload("res://src/assets/FemaleOperatorDesign.gd").add_head(head, Vector3.ZERO, Vector3(0.21, 0.23, 0.20))
		return
	var skull := M.capsule(head,"Face",0.105,0.23,Vector3.ZERO,skin)
	skull.scale.z = 0.90
	M.box(head,"Brows",Vector3(0.17,0.025,0.018),Vector3(0,0.035,-0.094),dark)
	M.box(head,"HairTop",Vector3(0.18,0.055,0.14),Vector3(0,0.105,0.005),dark)
	M.box(head,"HairBack",Vector3(0.16,0.10,0.055),Vector3(0,0.055,0.085),dark)
	M.box(head,"JawGuard",Vector3(0.15,0.04,0.025),Vector3(0,-0.075,-0.095),armor)

static func _add_headwear(head: Node3D, item_id: StringName) -> void:
	var style := Cosmetics.item_style(item_id)
	if style == "none":
		return
	var color := Cosmetics.item_color(item_id, Color("20262b"))
	var mat := M.material(color, 0.04, 0.72)
	if style == "beanie":
		var beanie := M.capsule(head,"EquippedBeanie",0.118,0.20,Vector3(0,0.105,0.018),mat)
		beanie.scale.y = 0.54
		return
	var crown := M.capsule(head,"EquippedCap",0.116,0.19,Vector3(0,0.105,0.018),mat)
	crown.scale.y = 0.42
	var brim := M.box(head,"CapBrim",Vector3(0.16,0.022,0.11),Vector3(0,0.075,-0.105),mat)
	brim.rotation.x = -0.08

static func _add_glasses(head: Node3D, item_id: StringName) -> void:
	var style := Cosmetics.item_style(item_id)
	if style == "none":
		return
	var color := Cosmetics.item_color(item_id, Color("8ccbd3"))
	var lens := M.material(color, 0.58, 0.22, 0.04 if style == "visor" else 0.0)
	var frame := M.material(Color("151b20"), 0.35, 0.42)
	if style == "visor":
		M.box(head,"EquippedVisor",Vector3(0.19,0.052,0.025),Vector3(0,0.025,-0.111),lens)
		return
	for side in [-1,1]:
		M.box(head,"Lens%d"%side,Vector3(0.074,0.050,0.018),Vector3(side*0.047,0.025,-0.111),lens)
	M.box(head,"GlassesBridge",Vector3(0.035,0.012,0.018),Vector3(0,0.025,-0.112),frame)

static func _build_operator_limbs(root: Node3D, top: Material, pants: Material, shoes: Material, armor: Material, skin: Material) -> void:
	for side in [-1,1]:
		var prefix := "Left" if side<0 else "Right"
		var leg := M.joint(root,prefix+"Leg",Vector3(side*0.115,0.87,0))
		M.capsule(leg,"Thigh",0.091,0.39,Vector3(0,-0.18,0),pants)
		var knee := M.joint(leg,"Knee",Vector3(0,-0.37,0))
		M.capsule(knee,"Shin",0.071,0.35,Vector3(0,-0.17,0),pants)
		M.box(knee,"Kneepad",Vector3(0.13,0.12,0.06),Vector3(0,-0.03,-0.072),armor)
		M.box(knee,"Boot",Vector3(0.15,0.12,0.25),Vector3(0,-0.43,-0.045),shoes)
		var arm := M.joint(root,prefix+"Arm",Vector3(side*0.265,1.34,0))
		M.capsule(arm,"UpperArm",0.067,0.27,Vector3(0,-0.11,0),top)
		M.box(arm,"ShoulderPlate",Vector3(0.13,0.13,0.18),Vector3(side*0.016,-0.025,0),armor)
		var elbow := M.joint(arm,"Elbow",Vector3(0,-0.24,0))
		elbow.rotation.x = -0.82
		M.capsule(elbow,"Forearm",0.052,0.25,Vector3(0,-0.115,0),top)
		M.box(elbow,"Hand",Vector3(0.085,0.10,0.10),Vector3(0,-0.255,0),skin)

static func _build_limbs(root: Node3D, cloth: Material, armor: Material, skin: Material, infected: bool) -> void:
	for side in [-1,1]:
		var prefix := "Left" if side<0 else "Right"
		var leg := M.joint(root,prefix+"Leg",Vector3(side*0.115,0.87,0))
		M.capsule(leg,"Thigh",0.091,0.39,Vector3(0,-0.18,0),cloth)
		var knee := M.joint(leg,"Knee",Vector3(0,-0.37,0))
		M.capsule(knee,"Shin",0.071,0.35,Vector3(0,-0.17,0),cloth)
		M.box(knee,"Kneepad",Vector3(0.13,0.12,0.06),Vector3(0,-0.03,-0.072),armor)
		M.box(knee,"Boot",Vector3(0.15,0.12,0.25),Vector3(0,-0.43,-0.045),armor)
		var arm := M.joint(root,prefix+"Arm",Vector3(side*0.265,1.34,0))
		M.capsule(arm,"UpperArm",0.067,0.27,Vector3(0,-0.11,0),cloth)
		var elbow := M.joint(arm,"Elbow",Vector3(0,-0.24,0))
		elbow.rotation.x = -0.20 if infected else -0.82
		M.capsule(elbow,"Forearm",0.052,0.25,Vector3(0,-0.115,0),skin if infected else cloth)
		M.box(elbow,"Hand",Vector3(0.085,0.10,0.10),Vector3(0,-0.255,0),skin if infected else armor)

static func create_zombie(variant: StringName = &"walker") -> Node3D:
	var root := preload("res://src/assets/SkinnedZombieRig.gd").new()
	root.archetype = variant
	root.name = "TacticalInfected"
	root.set_meta("visual_height", 1.64)
	return root

static func create_fallback_zombie(variant: StringName = &"walker") -> Node3D:
	var root := Rig.new()
	root.name = "ProceduralZombie"
	root.infected = true
	root.archetype = variant
	var kind := String(variant).to_lower()
	var skin_color := Color("818b65")
	if kind.contains("runner"):
		skin_color = Color("9a8a72")
	elif kind.contains("screamer"):
		skin_color = Color("a89995")
	var skin := M.material(skin_color,0,0.96)
	var cloth := M.material(Color("43564e"),0,0.94)
	var dark := M.material(Color("29312a"),0,0.9)
	var wound := M.material(Color("692e28"),0,0.78)
	_build_limbs(root,cloth,dark,skin,true)
	M.box(root,"Pelvis",Vector3(0.32,0.18,0.26),Vector3(0,0.85,0),dark)
	var torso := M.joint(root,"Torso",Vector3(0,1.17,0))
	var chest := M.capsule(torso,"Chest",0.21,0.46,Vector3.ZERO,skin)
	chest.scale.z = 0.66
	M.box(torso,"TornShirt",Vector3(0.34,0.22,0.035),Vector3(-0.04,0.01,-0.14),cloth)
	for index in range(4):
		var rib := M.box(torso,"ExposedRib%d"%index,Vector3(0.15,0.022,0.03),Vector3(0.08,0.06-index*0.042,-0.18),wound)
		rib.rotation.z = -0.20
	M.capsule(root,"Neck",0.055,0.10,Vector3(0,1.42,-0.025),skin)
	var head := M.joint(root,"Head",Vector3(0.015,1.53,-0.06))
	var skull := M.capsule(head,"Skull",0.108,0.22,Vector3.ZERO,skin)
	skull.scale.z=0.88
	M.box(head,"Jaw",Vector3(0.12,0.08,0.10),Vector3(0,-0.09,-0.04),wound)
	for side in [-1,1]:
		M.box(head,"EyeSocket%d"%side,Vector3(0.065,0.055,0.02),Vector3(side*0.049,0.021,-0.092),dark)
		M.box(head,"Eye%d"%side,Vector3(0.024,0.018,0.014),Vector3(side*0.049,0.023,-0.105),M.material(Color("f6b267"),0,0.4,0.6))
	for i in range(4):
		M.box(head,"Tooth%d"%i,Vector3(0.016,0.022,0.01),Vector3(-0.033+i*0.022,-0.06,-0.10),M.material(Color("bfb38f")))
	if kind.contains("tank"):
		M.box(torso,"InfectedArmor",Vector3(0.44,0.29,0.12),Vector3(0,0.0,-0.16),dark)
		root.scale = Vector3(1.2,1.0,1.15)
	elif kind.contains("screamer"):
		M.capsule(root,"ThroatSac",0.084,0.22,Vector3(0,1.36,-0.11),wound)
	elif kind.contains("runner"):
		root.scale = Vector3(0.9,1.0,0.94)
	root.set_meta("source","procedural")
	root.set_meta("visual_height",1.64)
	root.animate_pose(0,0)
	return root
