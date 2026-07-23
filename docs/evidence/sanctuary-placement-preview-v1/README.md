# Sanctuary placement preview v1

Display-backed Godot capture from the live `Main` scene at 1280×720.

- `02_placement_preview_active.png`: q0 Workshop blueprint silhouette and measured 6×5 m footprint.
- `03_rotated_placement_preview_active.png`: q1 Workshop blueprint silhouette and rotated 5×6 m world footprint.
- `03_blueprint.png`: persisted blueprint stage after placement.
- `07_operational_structure.png`: same authored Workshop family after completion.

The preview fill, outline, and silhouette are presentation-only. `GameSession`
continues to own the grid claim, access cells, save record, and placement
validity; the preview root applies the quarter-turn once so the visible footprint
does not drift from the persisted collision contract.
