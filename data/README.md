# data/ — your content lives here

These folders hold `.tres` files: plain data, no code. This is what makes areas 2-4
cheap to build.

You cannot create them yet. The order is:

1. Write `scripts/resources/fish_data.gd` — add `class_name FishData` above `extends`
   and declare the `@export` variables listed in the file's TODO block.
2. In the FileSystem dock, right-click `data/fish/` > **New Resource...**
3. Search for `FishData` in the dialog and create it.
4. Fill in the fields in the Inspector and save as e.g. `creek_minnow.tres`.

`class_name` is the line that makes your type appear in that dialog. Without it,
step 3 won't find anything.

Planned content:

- `fish/`  creek_minnow, orchard_trout, bog_eel, sacred_koi, ... (4-6 per area)
- `rods/`  starter_stick, bamboo_rod, fibreglass_rod, grandfathers_rod
           (keep starter_stick cheap and always in stock — softlock insurance)
- `areas/` area_01_orchard, area_02_desert, area_03_muddy_bog, area_04_stone_ponds
