extends CanvasLayer
## Always-on display: money, backpack count, equipped rod.
##
## TODO:
##   - connect to GameState.money_changed and GameState.inventory_changed in _ready.
##     The HUD must never be referenced BY the fishing code, and vice versa —
##     everything meets at GameState and at signals. That's what lets three people
##     work at once without breaking each other.
##   - show the backpack as "4 / 6" permanently and flash it when it changes.
##     The carry cap is the mechanic that makes your whole loop work, so make it
##     visible.
