extends Resource
## AreaData — one section of the creek, authored as a .tres in res://data/areas/.
## This is the file that makes areas 2-4 cheap: new area = new .tres + new tilemap.
##
## TODO — @export:
##   display_name   : String
##   scene_path     : String            use @export_file("*.tscn")
##   fish_table     : Array[FishData]   what can be caught here
##   music          : AudioStream
##   key_price      : int
##   keys_required  : int               your GDD says 3
##   unlock_order   : int
