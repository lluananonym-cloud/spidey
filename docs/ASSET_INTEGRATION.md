# Asset integration

The playable project includes the uploaded `Spiderman Brand New Day Mask.fbx` and all four supplied textures:

- `T_HerbalFist_Body_D.png`
- `T_HerbalFist_Body_N.png`
- `T_HerbalFist_Mask_D.png`
- `T_HerbalFist_Mask_N.png`

The model is instantiated by `scripts/player.gd`, automatically scaled to the player capsule, and its materials are wired to the supplied diffuse and normal maps. The game keeps a clearly marked training-silhouette fallback only for machines where the Godot FBX importer fails; the HUD reports that state instead of hiding it.

The Drive archive was used as a reference for the original traversal prototype and its Godot documentation. Its uploaded archive did not contain the original scene/script source files, so the playable scene and systems in this ZIP are a clean Godot 4 implementation of the requested upgraded game loop.

Only use the included character asset if you have the right to redistribute it.