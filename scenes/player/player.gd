extends CharacterBody2D
## Bell. Attach to Player.tscn.
##
## Node tree to build under this root:
##   AnimatedSprite2D    offset so the sprite's ORIGIN sits at Bell's feet (3/4 depth)
##   CollisionShape2D    a small capsule around the feet only, not the whole body
##   InteractArea (Area2D)   mask: Interactable — a circle in front of the player
##   FishingComponent (Node2D)
##
## TODO:
##   - @export var move_speed: float
##   - var can_move: bool — false while a menu or the minigame is open
##   - _physics_process: Input.get_vector("move_left","move_right","move_up","move_down")
##     * move_speed, then move_and_slide(). get_vector() normalises diagonals for you —
##     without it, diagonal movement is ~41% faster than straight.
##   - remember the last non-zero direction, or Bell snaps to facing down when he stops
##   - six animations only: idle/walk for down, side, up. Flip the side one with
##     sprite.flip_h instead of drawing left and right separately.
