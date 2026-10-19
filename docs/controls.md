# Controls

## Keyboard

  * ESC: Exit fullscreen, if not in full screen then exit game
  * R: Respawn character at level starting position

## Robot Controls

* MOVEMENTS
  * A, LEFT ARROW        - move left
  * D, RIGHT ARROW:      - move right
  * W, SPACE, UP ARROW:  - jump
* ATTACKS
  * CTRL:    - slide
  * Z:       - shoot
  * X:       - melee

## Male Ninja Controls

* MOVEMENTS
  * A, LEFT ARROW                                 - move left
  * D, RIGHT ARROW:                               - move right
  * W, SPACE, UP ARROW:                           - jump
  * (W, SPACE, UP ARROW) + (W, SPACE, UP ARROW):  - GLIDE
* ATTACKS
  * CTRL:    - slide
  * Z:       - shoot
  * X:       - melee

## Ranger Controls

* MOVEMENTS
  * A, LEFT ARROW        - move left
  * D, RIGHT ARROW       - move right
  * W, SPACE, UP ARROW   - jump
* ATTACKS
  * CTRL   - slide
  * Z      - shoot (female only; male falls back to female animation)
  * X      - melee (female only; male falls back to female animation)

## Gamepad Controls

* MOVEMENT
  * Left Stick / D-Pad Left   - move left
  * Left Stick / D-Pad Right  - move right
  * A / Cross                 - jump
* ACTIONS
  * RB / R1      - shoot (action_1)
  * X / Square   - melee (action_2)
  * B / Circle   - slide (action_3)
  * Start        - respawn

Keyboard mappings remain unchanged. Each playable character responds to the
gamepad bindings of the actions it already implements:
- Robot, Ninja: full set (action_1, action_2, action_3, movement, jump, respawn)
- Ranger: full set; male ranger falls back to female shoot/melee animations
- Dino: movement, jump, and action_2 (tail-swipe melee) only; does not
  implement action_1 (shoot) or action_3 (slide)
