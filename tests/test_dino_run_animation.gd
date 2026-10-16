extends GutTest

# Issue #62 / spec Issue 3 — the dino override of _reset_character_sprite_states
# is INTENTIONAL behavioural divergence, not duplication to be collapsed. It must
# keep playing its own prefixed "dino_run" and must never consult the base class's
# _get_run_animation_name() hook introduced by this refactor.
#
# The probe below overrides ONLY _default_collision() (which touches collision
# nodes the bare instance does not have). Dino's real _change_sprite_animation()
# override — the "dino_" prefixing at scripts/dino.gd:100 — is left intact so
# this suite exercises the genuine dino path end to end.

const DINO_SCRIPT = preload("res://scripts/dino.gd")
const TAIL_SWIPE_DURATION = 0.2


class _DinoProbe extends "res://scripts/dino.gd":
	# Records every _default_collision() call so the early-return branches can be
	# asserted: an early return must NOT reach the default collision reset.
	var default_collision_calls := 0

	func _default_collision():
		default_collision_calls += 1


var _dino


# The real dino sheets, by name only — AnimatedSprite2D rejects an animation key
# its SpriteFrames does not define, so the probe needs every name the dino
# override can ask for. Mirrors scenes/characters/dino/Character_Scene.tscn.
func _dino_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	for anim in ["dino_dead", "dino_idle", "dino_jump", "dino_run"]:
		frames.add_animation(anim)
	return frames


func before_each():
	_dino = _DinoProbe.new()
	_dino.player_sprite = AnimatedSprite2D.new()
	_dino.player_sprite.sprite_frames = _dino_frames()
	_dino.type = "dino"
	_dino.gender = ""
	_dino.health = 100
	_dino.dazed = false
	_dino.action1 = false
	_dino.action2 = false
	_dino.action3 = false
	_dino.current_jump_count = 0
	_dino.movement_direction = 1


func after_each():
	_dino.player_sprite.free()
	_dino.free()


func test_dino_grounded_movement_plays_dino_run():
	_dino._reset_character_sprite_states(0.016)
	assert_eq(_dino.player_sprite.animation, "dino_run",
		"Grounded dino movement must play the prefixed dino_run sheet")


func test_dino_idle_when_not_moving():
	_dino.movement_direction = 0
	_dino._reset_character_sprite_states(0.016)
	assert_eq(_dino.player_sprite.animation, "dino_idle",
		"A stationary dino must play dino_idle")


func test_dino_does_not_consult_the_base_run_animation_hook():
	# The dino override hardcodes "run" and relies on its own "dino_" prefixing.
	# Routing it through the hook would produce "dino_walk" (or "walk"), which the
	# dino asset set does not have — so the hook must stay untouched here.
	assert_eq(_dino._get_run_animation_name(), "walk",
		"The base hook default is inherited by dino but must never be called")
	_dino._reset_character_sprite_states(0.016)
	assert_eq(_dino.player_sprite.animation, "dino_run",
		"After a movement reset the dino must be on dino_run, not dino_walk")
	# Strip comments before checking: the intent comment above dino.gd:106 names the
	# hook to explain why the dino path deliberately bypasses it, but no executable
	# line may call it.
	var code := ""
	for line in (DINO_SCRIPT as GDScript).source_code.split("\n"):
		if not line.begins_with("#"):
			code += line + "\n"
	assert_false(code.contains("_get_run_animation_name"),
		"dino.gd must not call the base-class _get_run_animation_name() hook")


func test_dino_dead_branch_returns_early():
	_dino.health = 0
	_dino._reset_character_sprite_states(0.016)
	assert_eq(_dino.player_sprite.animation, "dino_dead",
		"Dead dino must play dino_dead")
	assert_false(_dino.repeat_frames, "Dead dino must clear repeat_frames")
	assert_false(_dino.disable_gravity, "Dead dino must clear disable_gravity")
	assert_eq(_dino.default_collision_calls, 0,
		"The dead branch returns before _default_collision()")


func test_dino_dazed_branch_returns_early():
	_dino.dazed = true
	_dino._reset_character_sprite_states(0.016)
	assert_eq(_dino.player_sprite.animation, "dino_idle",
		"Dazed dino must play dino_idle")
	assert_false(_dino.disable_gravity, "Dazed dino must clear disable_gravity")
	assert_eq(_dino.default_collision_calls, 0,
		"The dazed branch returns before _default_collision()")


func test_dino_tail_swipe_holds_until_the_timer_elapses():
	_dino.action2 = true
	_dino.player_sprite.flip_h = true
	_dino._pre_swipe_flip_h = false
	_dino._reset_character_sprite_states(TAIL_SWIPE_DURATION / 2.0)
	assert_almost_eq(_dino._tail_swipe_timer, TAIL_SWIPE_DURATION / 2.0,
		0.0001, "The tail-swipe timer must tick by delta while action2 is active")
	assert_true(_dino.action2, "An unfinished tail-swipe must keep action2 set")
	assert_true(_dino.player_sprite.flip_h,
		"An unfinished tail-swipe must keep the flipped sprite")
	assert_eq(_dino.default_collision_calls, 0,
		"An unfinished tail-swipe returns before _default_collision()")


func test_dino_tail_swipe_completion_clears_state_and_restores_flip():
	_dino.action2 = true
	_dino.player_sprite.flip_h = true
	_dino._pre_swipe_flip_h = false
	_dino._reset_character_sprite_states(TAIL_SWIPE_DURATION)
	assert_false(_dino.action2, "A completed tail-swipe must clear action2")
	assert_almost_eq(_dino._tail_swipe_timer, 0.0, 0.0001,
		"A completed tail-swipe must reset the timer")
	assert_false(_dino.player_sprite.flip_h,
		"A completed tail-swipe must restore the pre-swipe sprite orientation")
	assert_true(_dino.repeat_frames, "A completed tail-swipe must set repeat_frames")
	assert_eq(_dino.default_collision_calls, 1,
		"A completed tail-swipe must reach _default_collision()")
	assert_eq(_dino.player_sprite.animation, "dino_run",
		"A completed tail-swipe must restore the dino_run sheet while moving")


func test_dino_tail_swipe_completion_plays_idle_when_stationary():
	_dino.action2 = true
	_dino.movement_direction = 0
	_dino._reset_character_sprite_states(TAIL_SWIPE_DURATION)
	assert_eq(_dino.player_sprite.animation, "dino_idle",
		"A completed tail-swipe while stationary must play dino_idle")


func test_dino_silences_action1_immediately():
	_dino.action1 = true
	_dino._reset_character_sprite_states(0.016)
	assert_false(_dino.action1, "action1 (shoot) is a no-op for dino and must be cleared")
	assert_eq(_dino.player_sprite.animation, "dino_run",
		"After silencing action1 the dino must fall back to dino_run")


func test_dino_silences_action3_immediately():
	_dino.action3 = true
	_dino._reset_character_sprite_states(0.016)
	assert_false(_dino.action3, "action3 (slide) is a no-op for dino and must be cleared")
	assert_eq(_dino.player_sprite.animation, "dino_run",
		"After silencing action3 the dino must fall back to dino_run")


func test_dino_holds_the_jump_animation_in_the_air():
	_dino.current_jump_count = 1
	_dino._reset_character_sprite_states(0.016)
	assert_eq(_dino.player_sprite.animation, "dino_jump",
		"An airborne dino must hold dino_jump")
	assert_eq(_dino.default_collision_calls, 0,
		"The airborne branch returns before _default_collision()")


func test_dino_grounded_branch_resets_default_collision():
	_dino._reset_character_sprite_states(0.016)
	assert_eq(_dino.default_collision_calls, 1,
		"The grounded dino branch must reach _default_collision()")
	assert_true(_dino.repeat_frames, "The grounded dino branch must set repeat_frames")
	assert_false(_dino.disable_gravity,
		"The grounded dino branch must clear disable_gravity")
