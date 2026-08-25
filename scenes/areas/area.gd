extends Node2D
## Shared behaviour for ALL FOUR areas — attach this one script to each area scene.
## If you find yourself writing a second version of this for area 2, stop: something
## is hardcoded, and areas 3 and 4 just became a week each instead of an afternoon.
##
## Every area scene has the same shape:
##   Ground (TileMapLayer)   no collision
##   Water  (TileMapLayer)   Water physics layer
##   Walls  (TileMapLayer)   collision on World layer
##   YSort  (Node2D)         y_sort_enabled ON — Player, Shack, Portal, props, enemies
##   FishingSpots (Node2D)   Area2D markers over the water
##   Camera2D                limits set to the map bounds
##   CanvasLayer > HUD
##
## Turn on y_sort_enabled on the ROOT and on YSort. Without it the game reads as flat
## and amateurish; with it Bell walks behind a tree when he's above it. One checkbox.
##
## TODO:
##   - @export var area_data: AreaData
##   - on _ready: set the camera limits from the tilemap's get_used_rect(),
##     tell AudioManager to play area_data.music, place the player at the spawn Marker2D
