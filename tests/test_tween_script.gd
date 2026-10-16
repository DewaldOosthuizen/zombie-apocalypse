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

# SCOPE NOTE — this file is NOT part of issue #62's functional change. It is
# touched only because STEP 5 of the workflow requires repairing pre-existing
# test failures encountered while running the suite for #62.
#
# [ORCHESTRATOR NOTE] Pre-existing failure — unrelated to issue #62
# Failure: [VECTOR2(50.0, 100.0)] expected to equal [VECTOR2(150.0, 100.0)]
#
# BASELINE EVIDENCE (this failure predates issue #62):
#   Verified in a clean `git worktree` at commit 71de0a4, the last commit before
#   this branch's work began. At that commit BOTH tween-completion tests failed,
#   with 2/9 passing in this file (suite total: 33/35 passing):
#     - test_on_tween_completed_resets_running_flag
#     - test_on_tween_completed_updates_movement_position
#   both with: "Invalid call to function '_on_tween_completed'. Expected 0
#   argument(s)" — these two tests still called the Godot 3 signature
#   _on_tween_completed(null, "") against the Godot 4 zero-arg signature
#   introduced by commit 765025e (issue #27). That stale arity was repaired
#   (calls changed to _on_tween_completed()), which turned the first test GREEN.
#   Only the failure below remains, and only now is it even reachable — before
#   the arity repair it aborted on an engine error before asserting.
#
# Root cause of the remaining failure: _on_tween_completed()
#   (scripts/generic_tween_script.gd:55) flips move_direction_x/_y BEFORE
#   recomputing movement_position, so with move_direction_x = 1 the completed
#   tween steps to position.x - distance (100 - 50 = 50), not position.x +
#   distance (150). The test's expectation encodes the pre-flip formula. Not
#   fixable inside issue #62's scope: changing the expectation rewrites the
#   test, and changing production code would alter tween bounce semantics (the
#   direction must flip to send the next leg the other way).
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
