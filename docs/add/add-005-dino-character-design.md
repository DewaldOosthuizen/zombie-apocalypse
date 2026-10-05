# ADD-005: Dino Character Design

## Status
Accepted

## Context
The dino character (`scripts/dino.gd`) is the only character in the project that does not follow the existing gender-separated, action-complete design pattern established by the ninja and ranger characters. It ships with a restricted animation set (Dead, Idle, Jump, Run, Walk, tail_swipe), no projectile weapon, no slide animation, and two mechanics not present on any other character: an instant-kill stomp when landing on enemies, and a tail-swipe melee implemented through sprite-flip and hitbox activation. Without an ADD, future contributors risk re-introducing shoot/slide behaviour or removing the stomp, mistaking the no-ops for unfinished work.

## Decision
1. **No shoot (action1):** `_shoot_bullet()` is a deliberate no-op. The dino has no projectile weapon and no animation assets for a shooting sequence, so action1 is silenced in `_reset_character_sprite_states` rather than wired to a bullet spawner.
2. **No slide (action3):** `_slide_attack_collision()` is a deliberate no-op. The dino has no slide animation and no body-type that would benefit from a sliding collision frame, so action3 is silenced the same way as action1.
3. **Stomp mechanic:** A `StompArea2D` child node covers the area beneath the dino. `_check_stomp()` runs before `_start_process` (which resets velocity on landing) and inspects `player_speed_y`. If the downward velocity is at least `STOMP_MIN_VELOCITY` (100.0 px/s) and `_stomped_this_jump` is false, every `enemy_character` body overlapping the area takes `body.health + 1` damage (instant kill), is dazed, and the dino receives a small upward bounce (`-JUMPFORCE * 0.5`) and a reset jump count of 1.
4. **Tail-swipe melee (action2):** Pressing action2 inverts the sprite's `flip_h`, holds the `tail_swipe` animation for `TAIL_SWIPE_DURATION` (0.2s), activates the appropriate side attack hitbox (`area_left_attack_collision_shape_2d` or `area_right_attack_collision_shape_2d`), then restores the original flip and clears action2 state. The `_melee_attack_collision()` override selects the hitbox based on `facing_direction`.
5. **Animation naming convention:** All dino animations use the `dino_<anim>` prefix directly, with no gender prefix. `_change_sprite_animation` prepends `"dino_"` and `gender` is left empty in `_ready()` so the generic-behaviour path does not prepend a gender token.

## Alternatives Considered
- **Extend the generic Behaviour to support a "no-shoot / no-slide" character flag.** Rejected: the no-ops are already explicit and self-documenting in `dino.gd`; adding a flag would complicate the generic script for a single outlier character.
- **Make stomp a separate `Area2D` body in the player scene rather than a dino-specific child.** Rejected: the stomp is intrinsic to the dino's design (double-jump + high fall speed) and has no equivalent on other characters, so scoping it to the dino scene is the correct boundary.
- **Use the existing melee animation rather than a custom `tail_swipe`.** Rejected: the tail-swipe is visually and mechanically distinct from the swing melee on the other characters (sprite-flip hold + hitbox activation without a full swing cycle), and reusing the shared melee animation would lose that distinction.

## Consequences
- The `_stomped_this_jump` flag prevents the same landing from killing multiple enemies; a new jump must be performed before the stomp can fire again.
- The double-jump (`max_jump_count > 1`) is a prerequisite for the stomp to be useful: without it, the dino could not regain altitude after landing, and the stomp kill would be a single-use per life in open play.
- Action1 and action3 are silently cleared in `_reset_character_sprite_states` rather than triggering their generic counterparts, so the no-op behaviour is visible in the state machine and not easily removed by a search-and-replace.
- The dino scene must always contain a `StompArea2D` child node named exactly `StompArea2D`, and attack hitbox shapes named `area_left_attack_collision_shape_2d` / `area_right_attack_collision_shape_2d`, or the dino will error or silently lose melee/stomp coverage.
- Animation files must follow the `dino_<anim>` convention; a gender-prefixed name (e.g. `male_dino_idle`) would not resolve and the character would show no animation.

## References
- `scripts/dino.gd` — dino character implementation
- `scripts/generic_character_behaviour.gd` — base behaviour, action1/action2/action3 contracts
- [ADD-002: Generic Behaviour Scripts](add-002-generic-behaviour-scripts.md)
- [ADD-003: Multi-Character World Scene Design](add-003-multi-character-design.md)
