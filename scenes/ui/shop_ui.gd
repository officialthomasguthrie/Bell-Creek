extends CanvasLayer
## Two tabs: Sell and Buy.
##
## SELL — every fish in the backpack with its value, plus a SELL ALL button.
##        Sell All isn't laziness, it's the button players want twenty times an hour.
## BUY  — rods, bait, backpack upgrades, and KEYS. Each row is a reusable
##        ShopItemRow.tscn instanced into a VBoxContainer and populated from a RodData.
##        Grey out and disable anything unaffordable.
##
## TODO:
##   - use container nodes (VBox/HBox/Margin/ScrollContainer), never hand-positioned
##     UI — hand-positioned UI breaks the moment the browser window differs from
##     your editor
##   - get_tree().paused = true when it opens, and set this node's Process Mode to
##     ALWAYS in the Inspector, or the menu freezes along with the game
##   - ALWAYS keep the starter rod in stock and cheap, or a player with a broken rod
##     and no money is softlocked. The design jury caught this one.
