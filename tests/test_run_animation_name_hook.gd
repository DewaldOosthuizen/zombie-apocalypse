extends GutTest

# Tests for the Template Method extraction in issue #62: the base class exposes
# a single virtual hook, _get_run_animation_name(), and both movement branches
# of _reset_character_sprite_states() must go through it instead of a
# hardcoded literal. Subclasses (ranger) override ONLY the getter.

const _RANGER_SCRIPT = preload("res://scripts/ranger.gd")


# Probe: records the animation name it is handed and neutralises the
# node-dependent side effects so the movement-name branch can be asserted alone.
class _MovementNameProbe extends "res://scripts/generic_character_behaviour.gd":
	var last_animation_name = ""

	func _change_sprite_animation(animation_text):
		last_animation_name = animation_text

	func _default_collision():
		pass


# Probe overriding ONLY the animation-name hook — mirrors the ranger case.
class _RunNameProbe extends _MovementNameProbe:
	func _get_run_animation_name() -> String:
		return "run"


var _probe


func before_each():
	_probe = _MovementNameProbe.new()
	_probe.player_sprite = AnimatedSprite2D.new()
	_probe.type = "probe"
	_probe.gender = "female"
	_probe.health = 100
	_probe.dazed = false
	_probe.action1 = false
	_probe.action2 = false
	_probe.action3 = false
	_probe.current_jump_count = 0
	_probe.movement_direction = 1


func after_each():
	_probe.free()


func test_base_get_run_animation_name_defaults_to_walk():
	assert_eq(_probe._get_run_animation_name(), "walk",
		"Base class must default the movement animation name to \"walk\"")


func test_grounded_movement_uses_the_hook_result():
	_probe._reset_character_sprite_states(0.016)
	assert_eq(_probe.last_animation_name, _probe._get_run_animation_name(),
		"Grounded movement must drive the animation named by the hook")
	assert_eq(_probe.last_animation_name, "walk",
		"With the default hook the grounded movement animation must stay \"walk\"")


func test_post_action_movement_uses_the_hook_result():
	# Post-action branch: an action was active and its animation finished, so
	# the movement/idle branch INSIDE that branch is the one exercised.
	_probe.action1 = true
	_probe._reset_character_sprite_states(0.016)
	assert_eq(_probe.last_animation_name, _probe._get_run_animation_name(),
		"Post-action movement must use the hook too, not a hardcoded name")


func test_idle_when_not_moving_ignores_the_hook():
	_probe.movement_direction = 0
	_probe._reset_character_sprite_states(0.016)
	assert_eq(_probe.last_animation_name, "idle",
		"Standing still must play idle, never the movement animation")


func test_dead_branch_wins_over_the_hook():
	_probe.health = 0
	_probe._reset_character_sprite_states(0.016)
	assert_eq(_probe.last_animation_name, "dead",
		"Dead branch must win over the movement animation name")
	assert_false(_probe.repeat_frames, "Dead branch must clear repeat_frames")


func test_dazed_branch_wins_over_the_hook():
	_probe.dazed = true
	_probe._reset_character_sprite_states(0.016)
	assert_eq(_probe.last_animation_name, "idle",
		"Dazed branch must win over the movement animation name")


func test_subclass_overriding_only_the_hook_yields_its_own_name():
	var probe = _RunNameProbe.new()
	probe.player_sprite = AnimatedSprite2D.new()
	probe.type = "ranger"
	probe.gender = "female"
	probe.health = 100
	probe.dazed = false
	probe.action1 = false
	probe.action2 = false
	probe.action3 = false
	probe.current_jump_count = 0
	probe.movement_direction = 1
	probe._reset_character_sprite_states(0.016)
	assert_eq(probe.last_animation_name, "run",
		"A subclass overriding only the hook must yield its own animation")
	probe.free()


func test_ranger_overrides_the_hook_and_not_the_reset_method():
	var ranger = _RANGER_SCRIPT.new()
	assert_eq(ranger._get_run_animation_name(), "run",
		"ranger.gd must return \"run\" (its sprite sheets are Run*.png)")
	var source = (_RANGER_SCRIPT as GDScript).source_code
	assert_false(source.contains("func _reset_character_sprite_states"),
		"ranger.gd must no longer define its own _reset_character_sprite_states")
	ranger.free()
