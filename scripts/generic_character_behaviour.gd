extends CharacterBody2D

# signals
signal reload(character)
signal reposition()
signal refresh_hud(character)
signal character_ready(character)

# Constants
const GRAVITY = 800 # default gravity force
const JUMPFORCE = 400 # default jump force
const BLOOD_PARTICLE_SCENE = preload("res://scenes/Blood_Particle_Scene.tscn")
const BONE_SCENE = preload("res://scenes/environment/Bone_Scene.tscn")
const MOVEMENT_DECELERATION_FACTOR = 2
const HEALTH_SNAP_PRECISION = 0.2
const LOW_HEALTH_THRESHOLD_PERCENT = 40
const BULLET_OFFSET_X = 20
const BULLET_OFFSET_Y = 5
const PIT_DEATH_THRESHOLD = 900 # Y position below which a character is considered to have fallen into a pit
const FLICKER_INTERVAL = 0.12 # seconds between flicker frames
const BLOOD_PARTICLE_Y_OFFSET = 50 # pixels above the character origin when spawning blood particles
const STATIONARY_VELOCITY_THRESHOLD = 0.2 # below this the character counts as airborne/stationary
const DEFAULT_INVINCIBLE_TIME = 3 # seconds of invincibility after taking a hit

# Export variables
@export var max_jump_count = 1 # characters can only jump once by default
@export var max_speed = 350 # character max speed, defaulted to 350
# STAT OWNERSHIP MODEL: ammo, energy, and health starting values are set
# per-character via the Godot Inspector (@export). The values here are base-class
# fallbacks only. Each character scene (ninja, robot, adventure_girl) overrides
# ammo and other stats by serialising @export values in its own .tscn file.
# When authoring a new character, set your starting stats in the Inspector for
# that character's scene — do NOT rely on these fallback defaults unless zero/100
# is intentionally correct for that stat.
@export var ammo = 0 # base-class fallback — override per character via Inspector
@export var energy = 0 # base-class fallback — override per character via Inspector
@export var max_energy = 100 # character max energy
@export var health = 100 # character starts with 100 % health
@export var max_health = 100 # character max health %
@export var action1_damage = 30 # damage dealt with action 1
@export var action2_damage = 20 # damage dealt with action 2
@export var action3_damage = 10 # damage dealt with action 3
@export var character_scale = Vector2(1, 1)
@export var main_character = false # indicate whether the character should have main_character features

var player_sprite # reference to character sprite image
var blood_colour = Color("#b90b0b") # default blood color
var gender = "male" # default character gender
var type = "" # used to define what character is currently active e.g (Robot, Ninja, etc)

# variables defaults, values can be changed from within script extending this script
var player_speed_x = 0 # controlled by this script, speed on x-axis
var player_speed_y = 0 # controlled by this script, speed on y-axis
var facing_direction = 0 # controlled by this script, used for player sprite flip
var movement_direction = 0 # direction in which the character is moving.
var current_jump_count = 0 # checks if character is busy jumping; count = number of jumps

var movement_multiplier = 800 # character movement multiplier
# gravity settles near 0.22 for a grounded character; anything under means the character is in the air
var stationary_velocity = STATIONARY_VELOCITY_THRESHOLD # below this, treated as airborne

# Timers
var death_time = 3
var death_timer = 0
var flicker_timer = 0
var invincible_time = DEFAULT_INVINCIBLE_TIME
var invincible_timer = 0
var dazed_time = 2
var dazed_timer = 0
var glide_timer = 0
var glide_time = 0.6

# Flags
var blood = false # set to true to display blood and automatically reset to false afterwards
var dazed = false # character cannot move when dazed; driven by dazed_time and dazed_timer
var invincible = false # indicate whether the character can be hurt or not
var repeat_frames = true # indicate whether current sprite frames should be repeated or not
var disable_gravity = false # disable character gravity when set to true
var action1 = false # mapped to z
var action2 = false # mapped to x
var action3 = false # mapped to control
var shield_indicator = false # indicate if shield is destroyed

# scenes that can be changed
var bullet_scene

# Collision objects
var area_stand_collision_shape_2d
var area_slide_collision_shape_2d
var area_left_attack_collision_shape_2d
var area_right_attack_collision_shape_2d
var stand_collision_shape_2d
var slide_collision_shape_2d
var _attack_area_2d: Area2D
var _character_area_2d: Area2D

# default character behaviour drive, used for main characters
func _start_process(delta):
	if player_sprite == null:
		return
	# set player speed, gravity and animate sprite
	_animate_player(delta)

	# handle collision on the x-axis
	var collided_object1 = move_and_collide(Vector2(velocity.x, 0))
	_handle_collision(collided_object1, false)

	# handle collision on the y-axis
	var collided_object2 = move_and_collide(Vector2(0, velocity.y))
	_handle_collision(collided_object2, velocity.y > stationary_velocity)

	# pit detection — if character falls below the level floor, trigger death/respawn
	if position.y > PIT_DEATH_THRESHOLD:
		_emit_reposition()


func _animate_player(delta):
	# control speed
	if (dazed or health <= 0):
		player_speed_x = 0
	elif (movement_direction != 0):
		player_speed_x += movement_multiplier * delta
	else:
		player_speed_x -= movement_multiplier * MOVEMENT_DECELERATION_FACTOR * delta

	#apply gravity to jump
	if (disable_gravity):
		player_speed_y += delta
	else:
		player_speed_y += GRAVITY * delta

	#stop player from keeping on increasing speed
	player_speed_x = clamp(player_speed_x, 0, max_speed)
	player_speed_y = clamp(player_speed_y, player_speed_y, max_speed * 3)
	#set player speed
	velocity.x = player_speed_x * delta * movement_direction
	velocity.y = player_speed_y * delta

	if (!repeat_frames and
			player_sprite.frame < player_sprite.get_sprite_frames().get_frame_count(
				player_sprite.animation) - 1):
		player_sprite.play()
	elif (repeat_frames):
		player_sprite.play()
	else:
		player_sprite.pause()  # pause() holds the last frame; stop() resets to frame 0 causing animation to replay

	_handle_timers(delta)


func _tick_glide_timer(delta):
	if (disable_gravity):
		glide_timer += delta
		if (glide_timer > glide_time):
			glide_timer = 0
			disable_gravity = false


func _tick_daze_timer(delta):
	if (dazed):
		dazed_timer += delta
		if (dazed_timer > dazed_time):
			dazed = false
			dazed_timer = 0


func _tick_blood_timer():
	if (blood):
		blood = false
		_emit_refresh_hud()  # always update HUD on hit, even during i-frames
		if (!invincible):
			invincible = true
			# create instance of blood and add it to the scene
			var particle_effect = BLOOD_PARTICLE_SCENE.instantiate()
			particle_effect.modulate = blood_colour
			particle_effect.get_node(".").set_emitting(true)
			particle_effect.position = self.get_position() - Vector2(0, BLOOD_PARTICLE_Y_OFFSET)
			get_tree().root.add_child(particle_effect)


func _tick_invincibility_timer(delta):
	if health <= 0:
		_handle_death_state(delta)
	if (invincible):
		flicker_timer += delta
		invincible_timer += delta

		if (invincible_timer > invincible_time):
			player_sprite.visible = true
			invincible = false
			invincible_timer = 0
			flicker_timer = 0
			shield_indicator = false
			player_sprite.modulate = Color("#ffffff")
	_handle_flicker()


func _handle_death_state(delta):
	_change_sprite_animation("dead")
	repeat_frames = false
	dazed = false
	death_timer += delta
	velocity.x = 0
	velocity.y = 0
	if (death_timer > death_time):
		velocity.y = 1
		death_timer = 0
		_emit_reload()


func _handle_flicker():
	if (flicker_timer > FLICKER_INTERVAL and health > 0):
		if (shield_indicator):
			# indicate shield has been depleted
			if (player_sprite.modulate == Color("#ffffff")):
				player_sprite.modulate = Color("#1d68c9") # blues
			else:
				player_sprite.modulate = Color("#ffffff") # normal
		elif ((snapped(health, HEALTH_SNAP_PRECISION) / snapped(max_health, HEALTH_SNAP_PRECISION) * 100) \
				< LOW_HEALTH_THRESHOLD_PERCENT):
			# indicate that health has dropped below 40%
			if (player_sprite.modulate == Color("#ffffff")):
				player_sprite.modulate = Color("#dd1717") # red
			else:
				player_sprite.modulate = Color("#ffffff") # normal
		else:
			if (player_sprite.visible):
				player_sprite.visible = false
			else:
				player_sprite.visible = true

		flicker_timer = 0


func _handle_timers(delta):
	_tick_glide_timer(delta)
	_tick_daze_timer(delta)
	_tick_blood_timer()
	_tick_invincibility_timer(delta)


func _handle_collision(collided_object, reset_jump):
	if (collided_object):
		#if character is on the floor
		if (reset_jump):
			player_speed_y = 0
			current_jump_count = 0


func _shoot_bullet(power):
	if player_sprite == null:
		return
	if bullet_scene == null:
		push_error("_shoot_bullet called but bullet_scene is not assigned on " + name)
		return
	if ammo <= 0:
		return
	action1 = true
	var bullet = bullet_scene.instantiate()
	bullet.power = power
	bullet.damage = action1_damage
	var bullet_sprite = bullet.get_node("AnimatedSprite")
	ammo -= 1

	if (!player_sprite.flip_h):
		bullet_sprite.flip_h = false
		bullet.movement_direction = 1
		bullet.position = self.get_position() - Vector2(-BULLET_OFFSET_X, BULLET_OFFSET_Y)
	elif (player_sprite.flip_h):
		bullet_sprite.flip_h = true
		bullet.movement_direction = -1
		bullet.position = self.get_position() - Vector2(BULLET_OFFSET_X, BULLET_OFFSET_Y)

	# Add the nodes to the current scene
	get_tree().root.add_child(bullet)


func _process_attack_area():
	var objects_in_attack_area = _attack_area_2d.get_overlapping_bodies()
	if (objects_in_attack_area and objects_in_attack_area.size() != 0):
		for body in objects_in_attack_area:
			if (body and !body.is_queued_for_deletion() and health > 0):
				var parent = body.get_parent()
				if (body.is_in_group("enemy_character")):
					if (action2):
						body._take_damage(action2_damage)
						body._daze()
					elif (action3):
						body._take_damage(action3_damage)
						body._daze()
				elif ((parent.is_in_group("brick") or parent.is_in_group("power_up_brick"))):
					parent.break_object()


func _apply_incoming_damage(parent):
	if (parent.health > 0 and (parent.action1 or parent.action2 or parent.action3) and !dazed):
		if (!action1 and !action2 and !action3):
			if (parent.action1 and !action1):
				_take_damage(parent.action1_damage)
			elif (parent.action2):
				_take_damage(parent.action2_damage)
			elif (parent.action3):
				_take_damage(parent.action3_damage)


func _process_character_area():
	var areas_in_character_area = _character_area_2d.get_overlapping_areas()
	if (areas_in_character_area and areas_in_character_area.size() != 0):
		for area in areas_in_character_area:
			if (area and !area.is_queued_for_deletion() and health > 0):
				var parent = area.get_parent()
				if (area.is_in_group("enemy_attack")):
					_apply_incoming_damage(parent)


func _area_checks():
	_process_attack_area()
	_process_character_area()


func _move_left():
	facing_direction = -1
	movement_direction = facing_direction
	if player_sprite == null:
		return
	player_sprite.flip_h = true


func _move_right():
	facing_direction = 1
	movement_direction = facing_direction
	if player_sprite == null:
		return
	player_sprite.flip_h = false


func _take_damage(damage_amount):
	if (!invincible):
		blood = true
		if (energy > 0):
			energy -= damage_amount

			if (energy <= 0):
				health += energy # adding negative value, to deduct the difference from health
				shield_indicator = true
				energy = 0
		else:
			health -= damage_amount


func _daze():
	dazed = true


func _reset_character_sprite_states(_delta):
	if player_sprite == null:
		return
	if (health <= 0):
		_change_sprite_animation("dead")
		repeat_frames = false
		disable_gravity = false
	elif (dazed):
		_change_sprite_animation("idle")
		disable_gravity = false
	elif (action1 or action2 or action3):
		if (!player_sprite.is_playing()):
			action1 = false
			action2 = false
			action3 = false
			repeat_frames = true
			disable_gravity = false
			if (movement_direction == 0):
				_change_sprite_animation("idle")
			else:
				_change_sprite_animation("walk")
			_default_collision()
	elif (!action1 and !action2 and !action3 and current_jump_count == 0):
		_default_collision()
		repeat_frames = true
		if (movement_direction == 0):
			_change_sprite_animation("idle")
		else:
			_change_sprite_animation("walk")
		disable_gravity = false


func _setup_collision():
	_attack_area_2d    = get_node("AttackArea2D")
	_character_area_2d = get_node("CharacterArea2D")
	area_stand_collision_shape_2d = get_node("CharacterArea2D/StandCollisionShape2D")
	area_slide_collision_shape_2d = get_node("AttackArea2D/SlideAttackCollisionShape2D")
	area_left_attack_collision_shape_2d = get_node("AttackArea2D/LeftAttackCollisionShape2D")
	area_right_attack_collision_shape_2d = get_node("AttackArea2D/RightAttackCollisionShape2D")
	stand_collision_shape_2d = get_node("StandCollisionShape2D")
	slide_collision_shape_2d = get_node("SlideCollisionShape2D")
	_default_collision()


func _default_collision():
	area_stand_collision_shape_2d.disabled = false
	area_slide_collision_shape_2d.disabled = true
	area_left_attack_collision_shape_2d.disabled = true
	area_right_attack_collision_shape_2d.disabled = true
	stand_collision_shape_2d.disabled = false
	slide_collision_shape_2d.disabled = true


func _melee_attack_collision():
	if (action2 and facing_direction == 1):
		area_right_attack_collision_shape_2d.disabled = false
	elif (action2 and facing_direction == -1):
		area_left_attack_collision_shape_2d.disabled = false


func _slide_attack_collision():
	slide_collision_shape_2d.disabled = false
	area_slide_collision_shape_2d.disabled = false
	stand_collision_shape_2d.disabled = true
	area_stand_collision_shape_2d.disabled = true


func _change_sprite_animation(animation_text):
	if player_sprite == null:
		return
	player_sprite.animation = gender + "_" + type + "_" + animation_text


func _take_damage_from_saw(character, saw):
	if (self == character and saw.is_in_group("enemy_saw")):
		_take_damage(15)


# called from world scene when setting up the character
func _subscribe_to_signals():
	var enemy_saws = get_tree().get_nodes_in_group("enemy_saw")
	for i in enemy_saws:
		if (!i.is_connected("touchedSaw", Callable(self, "_take_damage_from_saw"))):
			i.connect("touchedSaw", Callable(self, "_take_damage_from_saw"))


func _emit_reload():
	if (main_character):
		emit_signal("reload", self)
	else:
		var bones = BONE_SCENE.instantiate()
		bones.position = self.get_position() - Vector2(0, -70)
		get_tree().root.add_child(bones)
		self.queue_free()


func _emit_reposition():
	if (main_character):
		emit_signal("reposition")
	else:
		self.queue_free()


func _emit_refresh_hud():
	if (main_character):
		emit_signal("refresh_hud", self)


func _emit_character_ready():
	if (main_character):
		emit_signal("character_ready", self)
