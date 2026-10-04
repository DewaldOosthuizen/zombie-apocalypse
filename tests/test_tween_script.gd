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
	_tween._on_tween_completed(null, "")
	assert_false(_tween.tween_running,
		"tween_running must be cleared after tween completes")

func test_on_tween_completed_updates_movement_position():
	_tween.move_direction_x = 1
	_tween.move_direction_y = 0
	_tween.move_distance_x = 50
	_tween.move_distance_y = 0
	_tween.position = Vector2(100, 100)
	_tween.tween_running = true
	_tween._on_tween_completed(null, "")
	assert_eq(_tween.movement_position, Vector2(150, 100),
		"movement position must update after tween completes")
