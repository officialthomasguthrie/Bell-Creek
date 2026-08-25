extends CanvasLayer
## The tension-bar minigame. Knows NOTHING about the rest of the game —
## it receives a FishData and a RodData and emits succeeded or failed.
## That isolation is what lets you test it on its own with F6.
##
## Build with Control nodes: TextureProgressBar for the meter, ColorRect or
## NinePatchRect for the bar and the catch zone.
##
## TODO:
##   - fish marker moves up/down the bar; speed + erraticness from fish.difficulty
##   - catch zone: HOLDING "cast" accelerates it up, releasing lets it fall.
##     Size comes from rod.catch_zone_size.
##     Hold-and-release, not mashing — mashing is a real motor-control barrier
##     and this is one of your GDD accessibility answers.
##   - progress meter fills while the marker is inside the zone, drains while it isn't
##   - full  -> succeeded.emit()
##   - empty -> failed.emit()  and the rod loses durability
##   - don't signal rarity by colour alone — add a shape, star count, or label
