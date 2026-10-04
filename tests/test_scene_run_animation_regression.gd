extends GutTest

# Issue #62 / spec Issue 4 — scene-level regression surface.
#
# The ninja and robot Character_Scene.tscn files embed GDScript that calls
# `super._reset_character_sprite_states(delta)`. Those scenes do NOT override
# _get_run_animation_name(), so the base default "walk" must still be what their
# inherited state-reset drives. The ranger scene is the only one bound to
# ranger.gd, whose hook returns "run" — and its SpriteFrames must actually have
# a matching animation so the inherited base method drives a real sheet.

const NINJA_SCENE = preload("res://scenes/characters/ninja/Character_Scene.tscn")
const ROBOT_SCENE = preload("res://scenes/characters/robot/Character_Scene.tscn")
const RANGER_SCENE = preload("res://scenes/characters/ranger/Character_Scene.tscn")


func _make(scene):
	var character = scene.instantiate()
	if scene == ROBOT_SCENE:
		# PRE-EXISTING scene bug, unrelated to issue #62: robot's _ready calls
		# _change_sprite_animation("idle") BEFORE assigning type = "robot", so it
		# asks the SpriteFrames for "male__idle" — a key that does not exist and
		# which AnimatedSprite2D rejects with an engine error. Duplicate the
		# frames per-instance and stub that one name so _ready is error-free.
		# Raise separately against scenes/characters/robot/Character_Scene.tscn.
		var sprite = character.get_node("AnimatedSprite")
		var frames: SpriteFrames = sprite.sprite_frames.duplicate()
		frames.add_animation("male__idle")
		sprite.sprite_frames = frames
	add_child_autofree(character)
	return character


func test_ninja_inherited_reset_plays_walk_while_moving():
	var ninja = _make(NINJA_SCENE)
	ninja.movement_direction = 1
	ninja._reset_character_sprite_states(0.016)
	assert_eq(ninja.player_sprite.animation, "male_ninja_walk",
		"Ninja uses the base hook default, so movement must still play walk")


func test_robot_inherited_reset_plays_walk_while_moving():
	var robot = _make(ROBOT_SCENE)
	robot.movement_direction = 1
	robot._reset_character_sprite_states(0.016)
	assert_eq(robot.player_sprite.animation, "male_robot_walk",
		"Robot uses the base hook default, so movement must still play walk")


func test_ninja_sprite_frames_expose_the_walk_animation():
	var ninja = _make(NINJA_SCENE)
	var frames = ninja.player_sprite.sprite_frames
	assert_true(frames.has_animation("male_ninja_walk"),
		"Ninja SpriteFrames must contain the walk sheet the base hook names")


func test_robot_sprite_frames_expose_the_walk_animation():
	var robot = _make(ROBOT_SCENE)
	var frames = robot.player_sprite.sprite_frames
	assert_true(frames.has_animation("male_robot_walk"),
		"Robot SpriteFrames must contain the walk sheet the base hook names")


func test_ninja_and_robot_do_not_override_the_hook():
	var ninja = _make(NINJA_SCENE)
	var robot = _make(ROBOT_SCENE)
	assert_eq(ninja._get_run_animation_name(), "walk",
		"Ninja must inherit the base default, not override the hook")
	assert_eq(robot._get_run_animation_name(), "walk",
		"Robot must inherit the base default, not override the hook")


func test_ranger_inherited_reset_plays_run_while_moving():
	var ranger = _make(RANGER_SCENE)
	ranger.movement_direction = 1
	ranger._reset_character_sprite_states(0.016)
	assert_eq(ranger.player_sprite.animation, "female_ranger_run",
		"Ranger inherits the base reset; its hook must drive the run sheet")


func test_ranger_sprite_frames_expose_the_run_animation():
	# Tasks.md: confirm the inherited base method drives a real animation rather
	# than a missing key — Run (1).png .. Run (8).png back female_ranger_run.
	var ranger = _make(RANGER_SCENE)
	var frames = ranger.player_sprite.sprite_frames
	assert_true(frames.has_animation("female_ranger_run"),
		"Ranger SpriteFrames must contain the run sheet its hook names")
	assert_true(frames.has_animation("male_ranger_run"),
		"Ranger SpriteFrames must contain the male run sheet too")
	assert_false(frames.has_animation("female_ranger_walk"),
		"Ranger has no walk sheet — run replaces it entirely")
