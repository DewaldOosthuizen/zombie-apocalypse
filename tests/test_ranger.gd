extends GutTest

# The adventure_girl character was replaced by ranger (commit 23e4632). This
# suite is repointed at the ranger scene, which carries the same asset-naming
# contract the old assertions checked: Run*.png movement sheets, no Walk sheet,
# and no jump_shoot / jump_melee variants (those fall back to "jump").

const RANGER_SCENE = preload("res://scenes/characters/ranger/Character_Scene.tscn")


func _make_ranger():
	var character = RANGER_SCENE.instantiate()
	add_child_autofree(character)
	return character


func test_type_is_ranger():
	var character = _make_ranger()
	assert_eq(character.type, "ranger", "type should be ranger after _ready")


func test_gender_is_female():
	var character = _make_ranger()
	assert_eq(character.gender, "female", "gender should be female after _ready")


func test_shoot_while_jumping_uses_jump_not_jump_shoot():
	var character = _make_ranger()
	var frames = character.get_node("AnimatedSprite").sprite_frames
	var has_jump_shoot = false
	for anim in frames.get_animation_names():
		if "jump_shoot" in anim:
			has_jump_shoot = true
	assert_false(has_jump_shoot, "There should be no jump_shoot animation - falls back to jump")


func test_melee_while_jumping_uses_jump_not_jump_melee():
	var character = _make_ranger()
	var frames = character.get_node("AnimatedSprite").sprite_frames
	var has_jump_melee = false
	for anim in frames.get_animation_names():
		if "jump_melee" in anim:
			has_jump_melee = true
	assert_false(has_jump_melee, "There should be no jump_melee animation - falls back to jump")


func test_horizontal_movement_uses_run_not_walk():
	var character = _make_ranger()
	var frames = character.get_node("AnimatedSprite").sprite_frames
	var has_run = false
	var has_walk = false
	for anim in frames.get_animation_names():
		if "run" in anim:
			has_run = true
		if "walk" in anim:
			has_walk = true
	assert_true(has_run, "There should be a run animation")
	assert_false(has_walk, "There should be no walk animation - uses run instead")


func test_run_animation_name_hook_matches_the_run_asset():
	# The base class hook drives the inherited _reset_character_sprite_states,
	# so its return value must match an animation the SpriteFrames actually has.
	var character = _make_ranger()
	var run_animation = character.gender + "_" + character.type + "_" \
		+ character._get_run_animation_name()
	var frames = character.get_node("AnimatedSprite").sprite_frames
	assert_true(frames.has_animation(run_animation),
		"hook must resolve to a real SpriteFrames animation: " + run_animation)
