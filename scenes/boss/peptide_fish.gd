extends CharacterBody2D
## The giant ripped fish that stole Bell's tides.
##
## Three phases is just three sets of numbers on one attack pattern:
##   Phase 1  straight-line charge, telegraphed by a ~0.5s wind-up and a flash
##   Phase 2  adds a radial projectile spray — one Projectile.tscn instanced in a
##            for loop with rotating angles
##   Phase 3  both, faster, plus it summons two seagulls (you already have seagulls)
##
## TODO: damage it by LANDING YOUR FISHING MECHANIC on it — cast at the boss, win a
## much harder tension-bar round, deal a chunk of damage. This reuses the system you
## spent two days perfecting and makes the climax about the game's actual verb.
## Make sure a fully-upgraded player wins comfortably — that's the payoff for grinding.
