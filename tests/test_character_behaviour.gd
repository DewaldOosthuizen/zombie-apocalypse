extends GutTest

const _CHAR_SCRIPT = preload("res://scripts/generic_character_behaviour.gd")

var _char

func before_each():
	_char = _CHAR_SCRIPT.new()

func after_each():
	_char.free()

func test_shoot_bullet_with_null_bullet_scene_pushes_error_and_returns():
	_char.bullet_scene = null
	_char.action1 = false
	_char.ammo = 5
	_char._shoot_bullet(10)
	assert_false(_char.action1, "action1 must remain false when bullet_scene is null")
	assert_eq(_char.ammo, 5, "ammo must not be decremented when bullet_scene is null")

func test_shoot_bullet_with_zero_ammo_is_noop():
	# Use a non-null sentinel for bullet_scene — the ammo guard fires before
	# instantiate() is ever called, so we only need a non-null reference here.
	_char.bullet_scene = _CHAR_SCRIPT
	_char.action1 = false
	_char.ammo = 0
	_char._shoot_bullet(10)
	assert_false(_char.action1, "action1 must remain false when ammo is 0")
	assert_eq(_char.ammo, 0, "ammo must not go negative when already 0")

func test_take_damage_reduces_health_when_no_energy():
	_char.health = 100
	_char.energy = 0
	_char.invincible = false
	_char._take_damage(30)
	assert_eq(_char.health, 70, "Health should drop by damage amount when energy is 0")

func test_take_damage_drains_energy_before_health():
	_char.health = 100
	_char.energy = 50
	_char.invincible = false
	_char._take_damage(30)
	assert_eq(_char.energy, 20, "Energy should absorb the damage first")
	assert_eq(_char.health, 100, "Health must be untouched while energy remains")

func test_take_damage_spills_over_from_energy_to_health():
	# Energy is 10, damage is 30 — 10 absorbed by energy, 20 spills to health
	_char.health = 100
	_char.energy = 10
	_char.invincible = false
	_char._take_damage(30)
	assert_eq(_char.energy, 0, "Energy must be floored to 0")
	assert_eq(_char.health, 80, "Remaining 20 damage must spill to health")

func test_take_damage_blocked_when_invincible():
	_char.health = 100
	_char.energy = 0
	_char.invincible = true
	_char._take_damage(50)
	assert_eq(_char.health, 100, "Invincible character must take no damage")

func test_take_damage_sets_blood_flag():
	_char.health = 100
	_char.energy = 0
	_char.invincible = false
	_char.blood = false
	_char._take_damage(10)
	assert_true(_char.blood, "blood flag must be set true after taking damage")

func test_take_damage_does_not_set_blood_when_invincible():
	_char.invincible = true
	_char.blood = false
	_char._take_damage(10)
	assert_false(_char.blood, "blood flag must remain false when invincible")

func test_invincibility_timer_increments_while_invincible():
	# Safe: only reads invincible_timer after delta — no player_sprite access
	# because invincible_timer (0 + 0.1) does NOT exceed DEFAULT_INVINCIBLE_TIME
	_char.invincible = true
	_char.invincible_timer = 0.0
	_char.flicker_timer = 0.0
	_char.blood = false     # guard against bloodParticle branch
	# player_sprite is null but the reset branch (L172) is NOT reached
	_char._handle_timers(0.1)
	assert_almost_eq(_char.invincible_timer, 0.1, 0.001,
		"invincible_timer should increment by delta each frame")

func test_invincibility_timer_resets_after_duration():
	# player_sprite MUST be assigned — the reset branch executes player_sprite.visible = true
	var stub_sprite = AnimatedSprite2D.new()
	_char.player_sprite = stub_sprite
	_char.invincible = true
	_char.invincible_timer = _CHAR_SCRIPT.DEFAULT_INVINCIBLE_TIME + 0.1   # already past invincible_time
	_char.flicker_timer = 0.0
	_char.blood = false            # guard against bloodParticle branch
	_char._handle_timers(0.0)
	assert_false(_char.invincible,
		"invincible must be cleared once invincible_timer exceeds invincible_time")
	assert_eq(_char.invincible_timer, 0,
		"invincible_timer must reset to 0 after expiry")
	stub_sprite.free()


# ---------------------------------------------------------------------------
# _apply_incoming_damage tests
# ---------------------------------------------------------------------------

func _make_attacker() -> Object:
	# Returns a bare generic_character_behaviour instance configured as an
	# attacker with action1 active and positive health so most tests get a
	# "should deal damage" baseline.
	var attacker = _CHAR_SCRIPT.new()
	attacker.health = 100
	attacker.action1 = true
	attacker.action2 = false
	attacker.action3 = false
	attacker.action1_damage = 30
	attacker.action2_damage = 20
	attacker.action3_damage = 10
	return attacker


func test_apply_incoming_damage_reduces_health_when_action1_active():
	# Target starts healthy, attacker has action1 active → target takes action1_damage.
	_char.health = 100
	_char.energy = 0
	_char.invincible = false
	_char.dazed = false
	_char.action1 = false
	_char.action2 = false
	_char.action3 = false
	var attacker = _make_attacker()
	_char._apply_incoming_damage(attacker)
	assert_eq(_char.health, 70,
		"health must drop by action1_damage (30) when attacker has action1 active")
	attacker.free()


func test_apply_incoming_damage_blocked_when_target_is_dazed():
	# When the target (self) is dazed _apply_incoming_damage must do nothing.
	_char.health = 100
	_char.energy = 0
	_char.invincible = false
	_char.dazed = true
	_char.action1 = false
	_char.action2 = false
	_char.action3 = false
	var attacker = _make_attacker()
	_char._apply_incoming_damage(attacker)
	assert_eq(_char.health, 100,
		"health must be unchanged when target is dazed")
	attacker.free()


func test_apply_incoming_damage_blocked_when_parent_health_zero():
	# Attacker with health == 0 must not deal any damage.
	_char.health = 100
	_char.energy = 0
	_char.invincible = false
	_char.dazed = false
	_char.action1 = false
	_char.action2 = false
	_char.action3 = false
	var attacker = _make_attacker()
	attacker.health = 0
	_char._apply_incoming_damage(attacker)
	assert_eq(_char.health, 100,
		"health must be unchanged when attacker health is 0")
	attacker.free()


func test_apply_incoming_damage_uses_action2_damage():
	# Attacker with action2 active → target takes action2_damage.
	_char.health = 100
	_char.energy = 0
	_char.invincible = false
	_char.dazed = false
	_char.action1 = false
	_char.action2 = false
	_char.action3 = false
	var attacker = _make_attacker()
	attacker.action1 = false
	attacker.action2 = true
	_char._apply_incoming_damage(attacker)
	assert_eq(_char.health, 80,
		"health must drop by action2_damage (20) when attacker has action2 active")
	attacker.free()


func test_apply_incoming_damage_uses_action3_damage():
	# Attacker with action3 active → target takes action3_damage.
	_char.health = 100
	_char.energy = 0
	_char.invincible = false
	_char.dazed = false
	_char.action1 = false
	_char.action2 = false
	_char.action3 = false
	var attacker = _make_attacker()
	attacker.action1 = false
	attacker.action3 = true
	_char._apply_incoming_damage(attacker)
	assert_eq(_char.health, 90,
		"health must drop by action3_damage (10) when attacker has action3 active")
	attacker.free()


func test_apply_incoming_damage_no_damage_when_attacker_has_zero_health():
	# Mirrors test_apply_incoming_damage_blocked_when_parent_health_zero —
	# explicitly verifies the attacker-health guard from the spec requirement.
	_char.health = 50
	_char.energy = 0
	_char.invincible = false
	_char.dazed = false
	_char.action1 = false
	_char.action2 = false
	_char.action3 = false
	var attacker = _make_attacker()
	attacker.health = 0
	attacker.action1 = true
	_char._apply_incoming_damage(attacker)
	assert_eq(_char.health, 50,
		"health must be unchanged when attacker health is 0")
	attacker.free()
