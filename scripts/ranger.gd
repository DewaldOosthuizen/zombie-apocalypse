extends "res://scripts/generic_character_behaviour.gd"

func _ready():
	type = "ranger"
	gender = "female"
	player_sprite = get_node("AnimatedSprite")
	if (!get_tree().root.is_queued_for_deletion()):
		_setup_collision()
		velocity = Vector2(0, 0)
		facing_direction = 1
		movement_direction = 1

		_change_sprite_animation("idle")
		bullet_scene = preload("res://scenes/characters/ninja/Bullet_Scene.tscn")

		_emit_character_ready()
		_subscribe_to_signals()
		print(":: " + type + " character spawned ::")


# Ranger sprite sheets are Run*.png — no Walk sheet exists.
# Override the animation name only; state-reset logic lives in the base class.
func _get_run_animation_name() -> String:
	return "run"


func _physics_process(delta):
	_area_checks()
	control_character(delta)
	_start_process(delta)


func control_character(delta):
	# Reset default behaviour
	_reset_character_sprite_states(delta)

	# Shoot (action_1)
	if Input.is_action_just_pressed("action_1") and !action1 and !action2 and !action3 and ammo > 0:
		_shoot_bullet(0)
		repeat_frames = false
		if current_jump_count > 0:
			_change_sprite_animation("jump")   # no jump_shoot asset; fall back to jump
		else:
			_change_sprite_animation("shoot")
		_emit_refresh_hud()

	# Melee (action_2)
	elif Input.is_action_just_pressed("action_2") and !action1 and !action2 and !action3:
		action2 = true
		repeat_frames = false
		_melee_attack_collision()
		if current_jump_count > 0:
			_change_sprite_animation("jump")   # no jump_melee asset; fall back to jump
		else:
			_change_sprite_animation("melee")

	# Slide (action_3)
	elif Input.is_action_just_pressed("action_3") and movement_direction != 0 and !action3:
		action3 = true
		repeat_frames = false
		_change_sprite_animation("slide")
		_slide_attack_collision()

	# Jump
	elif Input.is_action_just_pressed("move_jump") and current_jump_count < max_jump_count and !action3:
		current_jump_count += 1
		player_sprite.frame = 0
		repeat_frames = false
		action1 = false
		action2 = false
		action3 = false
		_change_sprite_animation("jump")
		player_speed_y = -JUMPFORCE

	elif Input.is_action_pressed("move_left"):
		_move_left()
	elif Input.is_action_pressed("move_right"):
		_move_right()
	elif Input.is_action_pressed("respawn"):
		_emit_reposition()
	else:
		movement_direction = 0
		if health <= 0:
			_change_sprite_animation("dead")
			repeat_frames = false
		elif current_jump_count == 0 and !action1 and !action2 and !action3:
			_change_sprite_animation("idle")
			repeat_frames = true
