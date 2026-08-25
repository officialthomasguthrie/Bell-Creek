extends Node
## SceneLoader — every area change goes through here, never through
## get_tree().change_scene_to_file() in gameplay code.
##
## TODO:
##   - a CanvasLayer + ColorRect owned by this autoload, used to fade to black
##   - change_area(area_data: AreaData, spawn_name: String = "default")
##       fade out -> change scene -> place the player at the matching Marker2D -> fade in
##   - signal transition_finished()
##   - call SaveSystem.save_game() on every successful area change
