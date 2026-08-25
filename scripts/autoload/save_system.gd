extends Node
## SaveSystem — JSON in user://save.json.
##
## res:// is READ-ONLY in an exported game. Save files must go in user:// or saving
## will work in the editor and silently fail in the web build.
##
## TODO:
##   - save_game()  build a Dictionary of primitives from GameState.
##       Store fish and rods as their resource PATHS (String), not the objects.
##       JSON.stringify(dict), then FileAccess.open("user://save.json", FileAccess.WRITE)
##   - load_game()  FileAccess READ -> JSON.parse_string() -> load(path) to rebuild
##       the resources -> write back into GameState
##   - has_save() -> bool     so the title screen can grey out "Continue"
##   - signal save_completed()
