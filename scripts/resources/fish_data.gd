extends Resource
## FishData — one species of fish, authored as a .tres file in res://data/fish/.
##
## Add `class_name FishData` above `extends` once you're ready — that is what makes
## this type appear in the right-click > New Resource dialog.
##
## TODO — declare these with @export so they're editable in the Inspector:
##   display_name   : String
##   texture        : Texture2D
##   base_value     : int      how much the shack pays
##   rarity_weight  : float    higher = shows up more often
##   difficulty     : float    drives the minigame marker speed
##   min_rod_tier   : int      hide this fish until the player owns a good enough rod
##   size_min / size_max : float   flavour text + value variation
