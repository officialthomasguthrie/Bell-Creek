extends CharacterBody2D
## Seagull. A four-state machine is plenty — do NOT reach for pathfinding.
## IDLE -> CHASE -> ATTACK -> FLEE
##
## Node tree:
##   AnimatedSprite2D, CollisionShape2D
##   DetectionArea (Area2D)   mask: Player — a large circle
##   Hitbox (Area2D)          mask: Player — a small circle
##   StateTimer (Timer)
##
## TODO:
##   - CHASE: global_position.direction_to(player.global_position) * speed
##   - ATTACK: steal the fish currently on the line / knock one out of the backpack,
##     play a random Harry SFX, then FLEE for a few seconds and reset
##   - Cost the player TIME and their catch, not health. A fishing game doesn't need
##     a player health system outside the boss fight — that's three systems saved.
