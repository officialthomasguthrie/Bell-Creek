extends Node2D
## FishingComponent — the cast/bite/minigame state machine. Child of Player.
## This is the core of the game. Budget two full days and make it FEEL good
## before building anything on top of it.
##
## TODO — states: IDLE -> CASTING -> WAITING -> BITE -> MINIGAME -> RESOLVED
##
##   CAST     only if overlapping a FishingSpot. Lock the player's movement,
##            play the cast animation, spawn Bobber.tscn in the facing direction,
##            start a Timer with randf_range(1.0, 3.5) scaled by rod.bite_speed
##   PICK     weighted random from AreaData.fish_table:
##            sum every rarity_weight, roll randf() * total, walk the list
##            subtracting weights until you go negative. Filter by rod tier FIRST.
##   BITE     dip the bobber, play a sound, open a ~0.6s window to press "cast".
##            Missing it is what makes fishing feel like fishing.
##   MINIGAME instance FishingMinigame.tscn, hand it the FishData and RodData,
##            connect its succeeded/failed signals
##
## TODO — signals: bite_started(fish), fish_caught(fish), fish_lost()
