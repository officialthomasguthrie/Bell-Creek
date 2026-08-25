extends Node
## GameState — the ONLY place mutable player progress lives.
## Register as an Autoload: Project > Project Settings > Globals > Autoload.
## Reachable anywhere as `GameState.money`, etc.
##
## TODO — state:
##   money            : int
##   backpack         : Array[FishData]
##   capacity         : int        the carry cap; upgradable in the shop
##   owned_rods       : Array[RodData]
##   equipped_rod     : RodData
##   keys             : Dictionary  area_id -> int
##   unlocked_areas   : Array[String]
##   boss_defeated    : bool
##
## TODO — signals (declare with `signal name(args)`, fire with `name.emit(...)`):
##   money_changed(new_total)
##   inventory_changed()
##   keys_changed(area_id, count)
##   area_unlocked(area_id)
##
## TODO — methods:
##   add_fish(fish) -> bool     return false when the backpack is full
##   sell_all() -> int          empty the backpack, add up the value, emit money_changed
##   spend(amount) -> bool      refuse if the player can't afford it
##   reset()                    for New Game
