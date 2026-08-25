extends Node
## AudioManager — one music player that crossfades, plus a small pool of SFX players
## so overlapping sounds don't cut each other off.
##
## Set up three buses first (Audio panel, bottom of the editor): Master, Music, SFX.
##
## TODO:
##   - play_music(stream, fade_time)   crossfade between area tracks
##   - play_sfx(stream)                grab a free player from the pool
##   - play_random_sfx(array)          use array.pick_random() for Harry's voice lines,
##                                     and randomise pitch_scale ~0.95-1.05 so repeats
##                                     don't become grating
##
## Browser gotcha: do NOT autoplay music on load. Web browsers block audio until the
## first user gesture — start the music on the Play button press.
