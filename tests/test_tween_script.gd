extends GutTest

var _tween

func before_each():
	_tween = load("res://scripts/generic_tween_script.gd").new()

func after_each():
	_tween.free()

func test_change_x_direction_toggles_positive_to_negative():
	_tween.move_direction_x = 1
	_tween._change_x_direction()
	assert_eq(_tween.move_direction_x, -1)

func test_change_x_direction_toggles_negative_to_positive():
	_tween.move_direction_x = -1
	_tween._change_x_direction()
	assert_eq(_tween.move_direction_x, 1)

func test_change_x_direction_noop_when_zero():
	_tween.move_direction_x = 0
	_tween._change_x_direction()
	assert_eq(_tween.move_direction_x, 0,
		"Zero direction should not toggle — no movement axis configured")

func test_change_y_direction_toggles_positive_to_negative():
	_tween.move_direction_y = 1
	_tween._change_y_direction()
	assert_eq(_tween.move_direction_y, -1)

func test_change_y_direction_toggles_negative_to_positive():
	_tween.move_direction_y = -1
	_tween._change_y_direction()
	assert_eq(_tween.move_direction_y, 1)

func test_change_y_direction_noop_when_zero():
	_tween.move_direction_y = 0
	_tween._change_y_direction()
	assert_eq(_tween.move_direction_y, 0)

func test_set_initial_movement_computes_correct_target_x():
	_tween.can_tween = true
	_tween.move_direction_x = 1
	_tween.move_direction_y = 0
	_tween.move_distance_x = 100
	_tween.move_distance_y = 0
	_tween._set_initial_movement(Vector2(50, 50))
	assert_eq(_tween.movement_position, Vector2(150, 50),
		"target X must be origin.x + distance * direction")

func test_on_tween_completed_resets_running_flag():
	_tween.tween_running = true
	_tween._on_tween_completed()
	assert_false(_tween.tween_running,
		"tween_running must be cleared after tween completes")

# [ORCHESTRATOR NOTE] Pre-existing failure — unrelated to issue #62
# Failure: [VECTOR2(50.0, 100.0)] expected to equal [VECTOR2(150.0, 100.0)]
# Root cause: _on_tween_completed() (scripts/generic_tween_script.gd:55) flips
#   move_direction_x/_y BEFORE recomputing movement_position, so with
#   move_direction_x = 1 the completed tween steps to position.x - distance
#   (100 - 50 = 50), not position.x + distance (150). The test's expectation
#   encodes the pre-flip formula. Not fixable inside issue #62's scope: changing
#   the expectation rewrites the test, and changing the production code would
#   alter tween bounce semantics (direction must flip to send the next leg the
#   other way).
# Suggested fix: decide the intended bounce semantics with the level-designer
#   owner, then either drop the direction flip before the recompute or update
#   this expectation to (50, 100).
func test_on_tween_completed_updates_movement_position():
	_tween.move_direction_x = 1
	_tween.move_direction_y = 0
	_tween.move_distance_x = 50
	_tween.move_distance_y = 0
	_tween.position = Vector2(100, 100)
	_tween.tween_running = true
	_tween._on_tween_completed()
	assert_eq(_tween.movement_position, Vector2(150, 100),
		"movement position must update after tween completes")
