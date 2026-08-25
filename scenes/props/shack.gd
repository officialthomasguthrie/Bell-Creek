extends StaticBody2D
## The grandparents' shack — sell fish here, buy rods, bait, and keys.
##
## Node tree:
##   Sprite2D
##   CollisionShape2D          the solid footprint of the building
##   InteractZone (Area2D)     layer: Interactable — the doorway
##     CollisionShape2D
##     Prompt (Sprite2D)       a small "E" icon, hidden by default
##
## TODO: use InteractZone's body_entered / body_exited signals to show and hide
## the prompt and set a flag; on "interact" with that flag set, open ShopUI.
