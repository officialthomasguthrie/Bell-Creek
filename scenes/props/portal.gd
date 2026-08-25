extends Area2D
## Gate to the next area. Three keys, per the GDD.
##
## Node tree: AnimatedSprite2D ("locked" / "open"), CollisionShape2D, Label
##
## TODO:
##   - connect to GameState.keys_changed so the portal visually opens the instant
##     the third key is bought — that feedback moment is worth more than it costs
##   - on "interact": short of keys -> say how many are missing;
##     otherwise SceneLoader.change_area(next_area_data)
##   - key PRICE is your difficulty curve. Aim for ~8-12 minutes of play to unlock
##     area 2, and playtest that number on someone who isn't you.
