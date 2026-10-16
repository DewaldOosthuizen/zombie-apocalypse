extends "res://scripts/generic_character_behaviour.gd"

# Dino character
# - No gender prefix in animation names (dino_idle, dino_run, etc.)
# - Assets: Dead, Idle, Jump, Run, Walk, tail_swipe (Run 5 x-flipped)
# - Action1 (shoot): no-op — dino has no projectile weapon
# - Action2 (melee): tail-swipe — flips sprite on x, holds Run(5) for 1s,
#     activates melee attack hitbox so enemies in range take action2_damage
# - Action3 (slide): no-op — dino does not slide
# - Stomp mechanic: instant-kill any enemy_character under StompArea2D
#     when falling at >= STOMP_MIN_VELOCITY px/s

const STOMP_MIN_VELOCITY = 100.0  # minimum downward speed to trigger stomp
const TAIL_SWIPE_DURATION = 0.2   # quick tail-swipe hold time

var _stomp_area: Area2D
var _stomped_this_jump := false  # prevent multi-kill on same landing
var _tail_swipe_timer := 0.0     # counts up while tail-swipe is active
var _pre_swipe_flip_h := false   # sprite flip before swipe — restored afterwards


func _ready():
	type = "dino"
	gender = ""  # unused — _change_sprite_animation builds "dino_<anim>" directly
	player_sprite = get_node("AnimatedSprite")
	if (!get_tree().root.is_queued_for_deletion()):
		_setup_collision()
		_stomp_area = get_node("StompArea2D")
		velocity = Vector2(0, 0)
		facing_direction = 1
		player_sprite.animation = "dino_idle"
		player_sprite.play()
		_emit_character_ready()


func _physics_process(delta):
	if player_sprite == null:
		return
	_handle_input()
	_check_stomp()            # capture velocity before _start_process resets it on landing
	super._start_process(delta)
	if health > 0:
		super._area_checks()
	_reset_character_sprite_states(delta)


# --- Input ---------------------------------------------------------------

func _handle_input():
	if health <= 0 or dazed:
		movement_direction = 0
		return

	if Input.is_action_pressed("move_left"):
		_move_left()
	elif Input.is_action_pressed("move_right"):
		_move_right()
	else:
		movement_direction = 0

	if Input.is_action_just_pressed("move_jump") and current_jump_count < max_jump_count:
		player_speed_y = -JUMPFORCE
		current_jump_count += 1
		_stomped_this_jump = false
		repeat_frames = false
		_change_sprite_animation("jump")

	# Tail-swipe melee: action_2, only when not already swiping
	if Input.is_action_just_pressed("action_2") and not action2 and not action1 and not action3:
		action2 = true
		_tail_swipe_timer = 0.0
		repeat_frames = false
		_pre_swipe_flip_h = player_sprite.flip_h
		# Invert sprite x to make it look like hitting with the tail
		player_sprite.flip_h = not player_sprite.flip_h
		_change_sprite_animation("tail_swipe")
		_melee_attack_collision()


# --- Stomp mechanic ------------------------------------------------------

func _check_stomp():
	if player_speed_y < STOMP_MIN_VELOCITY or _stomped_this_jump:
		return
	var bodies = _stomp_area.get_overlapping_bodies()
	for body in bodies:
		if body == null or body.is_queued_for_deletion():
			continue
		if body.is_in_group("enemy_character") and body.health > 0:
			body._take_damage(body.health + 1)  # instant kill
			body._daze()
			_stomped_this_jump = true
			player_speed_y = -JUMPFORCE * 0.5  # small upward bounce
			current_jump_count = 1  # allow one more jump after stomp


# --- Animation override --------------------------------------------------
# Dino uses dino_<anim> — no gender prefix.

func _change_sprite_animation(animation_text):
	if player_sprite == null:
		return
	player_sprite.animation = "dino_" + animation_text


# INTENTIONAL DIVERGENCE — not duplication to be collapsed.
# This override is behavioural, not a mere animation-name swap: it returns early
# for dead/dazed, ticks _tail_swipe_timer on action2, silently clears
# action1/action3, and holds a jump frame in the air. Its own "run" literals
# below are correct for the dino assets (prefixed dino_ by the override above),
# so this path deliberately does NOT use the base class's
# _get_run_animation_name() hook.
func _reset_character_sprite_states(delta):
	if player_sprite == null:
		return
	if health <= 0:
		_change_sprite_animation("dead")
		repeat_frames = false
		disable_gravity = false
		return

	if dazed:
		_change_sprite_animation("idle")
		disable_gravity = false
		return

	# Tail-swipe in progress — tick its timer and hold the frame
	if action2:
		_tail_swipe_timer += delta
		if _tail_swipe_timer >= TAIL_SWIPE_DURATION:
			# Swipe finished — restore sprite orientation and clear state
			player_sprite.flip_h = _pre_swipe_flip_h
			action2 = false
			_tail_swipe_timer = 0.0
			repeat_frames = true
			disable_gravity = false
			_restore_default_collision()
			_play_idle_or_run_animation("run")
			return  # do not fall through while swipe is active

	if action1 or action3:
		# Silenced actions — clear immediately
		action1 = false
		action3 = false
		repeat_frames = true
		disable_gravity = false
		_restore_default_collision()
		_play_idle_or_run_animation("run")
		return

	if current_jump_count > 0:
		# In air — hold jump animation
		_change_sprite_animation("jump")
		return

	# Grounded and idle/running
	_restore_default_collision()
	repeat_frames = true
	disable_gravity = false
	_play_idle_or_run_animation("run")


# --- Melee override: activate hitbox for tail-swipe ----------------------

func _melee_attack_collision():
	# Activate the hitbox on the side the dino is facing.
	if facing_direction == 1:
		area_right_attack_collision_shape_2d.disabled = false
	else:
		area_left_attack_collision_shape_2d.disabled = false


# --- No-op action overrides (document intent explicitly) -----------------

# Dino has no projectile weapon.
func _shoot_bullet(_power):
	pass


# Dino does not slide.
func _slide_attack_collision():
	pass
