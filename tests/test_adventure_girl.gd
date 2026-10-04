extends GutTest

var AdventureGirlScene = preload("res://scenes/characters/adventure_girl/Character_Scene.tscn")

func test_type_is_adventure_girl():
	var character = AdventureGirlScene.instantiate()
	add_child_autofree(character)
	assert_eq(character.type, "adventure_girl", "type should be adventure_girl after _ready")

func test_gender_is_female():
	var character = AdventureGirlScene.instantiate()
	add_child_autofree(character)
	assert_eq(character.gender, "female", "gender should be female after _ready")

func test_shoot_while_jumping_uses_jump_not_jump_shoot():
	var character = AdventureGirlScene.instantiate()
	add_child_autofree(character)
	# Adventure Girl has no jump_shoot animation; confirm "jump_shoot" is absent from SpriteFrames
	var sprite = character.get_node("AnimatedSprite")
	var frames = sprite.frames
	var has_jump_shoot = false
	for anim in frames.get_animation_names():
		if "jump_shoot" in anim:
			has_jump_shoot = true
	assert_false(has_jump_shoot, "There should be no jump_shoot animation - falls back to jump")

func test_melee_while_jumping_uses_jump_not_jump_melee():
	var character = AdventureGirlScene.instantiate()
	add_child_autofree(character)
	var sprite = character.get_node("AnimatedSprite")
	var frames = sprite.frames
	var has_jump_melee = false
	for anim in frames.get_animation_names():
		if "jump_melee" in anim:
			has_jump_melee = true
	assert_false(has_jump_melee, "There should be no jump_melee animation - falls back to jump")

func test_horizontal_movement_uses_run_not_walk():
	var character = AdventureGirlScene.instantiate()
	add_child_autofree(character)
	var sprite = character.get_node("AnimatedSprite")
	var frames = sprite.frames
	var has_run = false
	var has_walk = false
	for anim in frames.get_animation_names():
		if "run" in anim:
			has_run = true
		if "walk" in anim:
			has_walk = true
	assert_true(has_run, "There should be a run animation")
	assert_false(has_walk, "There should be no walk animation - uses run instead")
