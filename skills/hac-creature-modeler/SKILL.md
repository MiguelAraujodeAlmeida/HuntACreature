---
name: hac-creature-modeler
description: Create or revise Hunt A Creature creature models in Blender from 2D concepts, using the project's faceted toy style and producing reviewable Blender/FBX files and visual sheets. Use for creature art, not world props or Roblox Studio installation.
---

# Hunt A Creature creature modeling

Turn the user's concept into a distinctive, reviewable creature. The concept determines anatomy, proportions, palette and personality. The game's common language is large readable masses, visible facets, controlled chamfers, geometric color layers and discreet studs in 1–3 suitable areas. Do not copy a reference species' anatomy onto a new creature.

## Before building

- Read the current project's Obsidian `README.md`, `AGENTS.md`, manifest bootstrap and `ui_ux` domain when available. The current design rules there supersede this skill's examples. On another machine, locate the actual vault clone from its GitHub repository; do not assume the original Windows path.
- Inspect the supplied concept, especially front, side and back. Treat conflicting three-quarter views as depth suggestions. Identify body archetype, dominant mass, signature features, floor contact or hover height, color regions, attachment pivots and desired physical size. Ask about a consequential ambiguity instead of inventing anatomy.
- Read [references/modeling-standard.md](references/modeling-standard.md) for geometry, materials, axes, metadata, handoff and review criteria. Inspect only the relevant sheets in [references/examples](references/examples); they are style examples, not templates. `lumito-base.png` illustrates the base creature already in the game; `lumito-ornate-concept.png` is a separate, unimplemented variant concept.

## Build and deliver

1. Use Blender MCP for scene inspection and authoring. Keep the user's existing scene intact; create the creature in a new file or isolated scene. The reusable primitives and materials in [scripts/creature_geometry.py](scripts/creature_geometry.py) are available when procedural construction helps. Extend the kit when anatomy requires it; preserve the shared visual rules.
2. Set `1 BU = 1 stud`, front `-Y`, up `+Z` and an art root at ground origin. Group only creature meshes and pivots in `<Species>_Base`; put review lights, cameras and scale avatar outside the export collection. Apply `ColorRole` to meshes and materials and `FootSide` to applicable feet. Use a versioned name for each revision.
3. Produce `<Species>_Base_vNN.blend`, `<Species>_Base_vNN.fbx`, its reproducible build `.py`, a 12-view sheet and `scale_vs_avatar.png`. Export the creature collection with `export_fbx_collection` from the geometry kit and use [scripts/render_review.py](scripts/render_review.py) for consistent view renders and sheet assembly. Inspect the images yourself and fix disconnected parts, intersections, poor silhouettes, lost details and misleading scale before delivery.
4. Report what matches the concept, any deliberate interpretation and limitations. Show the sheet and scale comparison to the developer for visual approval. Do not import into Roblox Studio, replace the existing Lumito or produce mutations unless specifically requested.

The Blender art root at ground level is an export convention. The current Studio Lumito template uses a different `Root`/collision setup; adapting a reviewed FBX to that runtime contract is separate work.
