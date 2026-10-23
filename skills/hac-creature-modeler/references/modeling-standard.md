# Creature modeling standard

This reference distills the developer's `guia_skill_criaturas_blender.md`. Project design remains revisable; current Obsidian `01_Produto/Design UI UX.md` owns the art direction. The six images in `examples/` are independent concept sheets, not six required deliverables or permission to replace existing game models.

## Read the concept

- Select the archetype the concept actually depicts: compact biped, quadruped, many-legged, serpentine, winged or hovering. Preserve its dominant volume and 1–2 silhouette-defining traits. Orthographic front, side and back resolve inconsistencies in generated three-quarter views.
- Default to roughly 2.4–2.8 studs for the main body only when the request gives no size. A small creature may be 1.4–1.9; a large one 3.5–4.8; a giant 5.5 or more. Wings, tails, horns and halos can extend beyond the body height. Show scale beside a 5.2-stud block avatar.
- Before detail, check a flat black silhouette from front, side, back and three-quarter view. Make proportions recognizable without color or VFX.

## Shared visual language

- Build from a few well-fitted, faceted volumes. Use flat normals and planar bevels on structural pieces; avoid raw cubes, smooth spheres, painted fur/noise and photoreal texture. Curves can use 6-, 8- or 12-sided polygon sections.
- Make major color changes as thin, beveled physical layers: belly, muzzle, face mask, armor, eyes and markings. Align each plate to its supporting plane so it neither floats nor fights the surface. Taper or segment limbs, horns, ears, wings and tails; give grounded feet clear soles or hooves.
- Place small 12-sided studs in 1–3 areas that support the construction, such as a crest, broad back plate or foot top. Keep face and silhouette readable. The concepts may omit studs; add them discreetly rather than changing the species' identity.
- Give the pose a slight intentional asymmetry or tilt. Floating orbitals are allowed when the concept calls for them; parent them to the body pivot they visually follow.

## Materials and metadata

| Finish | Blender intent | Typical use |
|---|---|---|
| `ToyMatte` | Roughness 0.45, metallic 0 | Main body, color plates, soles, studs |
| `ToyGloss` | Roughness 0.20, metallic 0 | Eyes, glints, polished gems |
| `ToyMetal` | Roughness 0.25, metallic 0.70 | Metal trim actually present in the concept |
| `ToyGlow` | Roughness 0.25, emission strength 2 | Only self-lit concept elements |

Use `Main`, `Secondary`, `Accent`, `Ink`, `Glint` on object and material custom properties. Add `Trim`, `Armor`, `Glow` or `Extra_1...` when needed. Sample concept sRGB colors and convert them to linear values for shader inputs. Do not assume Blender custom properties become Roblox attributes on FBX import; verify and map them during a separate Studio integration. Tag grounded foot meshes with `FootSide = L` or `R` where a walk cycle uses alternating contact. For a quadruped, use diagonal pairs; for a hovering creature, omit irrelevant foot tags.

## Scene and export

- Blender metric scale length 1.0: 1 Blender unit is 1 stud. Front is `-Y`, back `+Y`, up `+Z`; anatomical left/right are `-X`/`+X`.
- `<Species>_Root` is an Empty at `(0, 0, 0)`. Ground contact is at `Z = 0`; a hovering `Body_Pivot` sits above it. Use `<Species>_Base` for creature MESH and EMPTY objects only. `ScaleRef_NoExport` and preview equipment stay out of FBX.
- Keep the source `.blend` and a repeatable build `.py`. Export only the creature collection to `.fbx` with custom properties enabled where the Blender version supports them. Version every output with the actual revision number; never overwrite an earlier approved file silently.

## Visual review

Render the 4×3 sheet at 2800×2100 pixels (700×700 cells): front, right, back, left; front three-quarter, back three-quarter, front-left three-quarter, top; black silhouettes from front, right, back and front three-quarter. Render a separate 900×700 orthographic scale comparison with the 5.2-stud avatar. Frame from the evaluated bounding box, including extremities and orbitals, and leave breathing room.

Inspect the outputs, not merely render completion: anatomical fidelity, palette, facial expression, clear 360° silhouette, clean plate attachments, no z-fighting or accidental gaps, no clipped extensions, legible studs and plausible floor contact. If the concept or model fails one of these materially, revise before presenting it. The example images illustrate base Lumito, chicken, pug, cow, cow musician and an ornate Lumito concept; they do not authorize mutations or game installation.
