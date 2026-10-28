---
name: hac-creature-integrator
description: Integrate a named 3D creature model into Hunt A Creature through Roblox Studio MCP, with species registration, anatomy-aware animation, personality, capture/base behavior and catalog portraits. Use when adding a creature to the game, rather than creating concept art alone.
---

# Hunt A Creature integration

Read the current project's AGENTS.md and Obsidian bootstrap, then only the gameplay, ui_ux, engineering and validation domains required for this integration. Locate the real clones on another machine. Current developer feedback and vault rules supersede examples here.

Read [the integration guide](references/guia_skill_integracao_criaturas.md) before implementing. It owns the detailed workflow, provisional parameter policy, presentation requirements and acceptance checklist.

## Workflow

1. Locate and visually inspect the named model and its hierarchy. Ask which version to use if ambiguous. Default to a new species, derive its public name by removing technical suffixes, and ask for rarity when absent. Respect existing species IDs; a repeat invocation must not duplicate a registration. Clarify a collision with an existing species before replacing anything.
2. State a short acting direction: locomotion archetype, personality and two distinctive idle gestures. User description takes precedence. Proceed with presentation work without an extra approval gate, while required identity questions remain pending.
3. Prepare an articulated copy preserving approved art, axes, scale, anatomical pivots and explicit groups. Default to a rig with authored, species-specific clips when the model can be articulated; choose Motor6D for rigid pieces or bones for a skinned mesh. Keep the root and capture volume outside cosmetic poses. Inspect the actual Roblox import capabilities; do not silently replace the supplied model with primitive approximations. Ask only if a consequential redesign or unresolved asset choice is necessary.
4. Integrate template, behavior, animation and provisional gameplay data as separate concerns. Version the rig builder and clip sources; use published animation IDs or a deterministic runtime player, never Studio-only preview IDs in a live build. Keep state/navigation server-authoritative and cosmetic posing client-side when feasible. Complete all applicable consumers of the species catalog, including wild spawn, capture, bag/base, sale, favorites, discovery, persistence and portraits. Grounded runners use the shared contact puff at real footfalls; floating creatures do not. Follow the guide for controlled test spawning and Lumito-derived provisional values.
5. Review actual poses, joint ownership, ground contact, scale variants and transitions where permitted; compile in Studio Edit and provide the manual playtest checklist. Do not start Play automatically. Apply through Studio MCP; the developer saves the place manually. Report unverified animation quality honestly.
6. Update the owning vault notes, current state, backlog and history; validate its manifest and synchronize both repositories under the project's workflow. Report implementation, Edit verification, pending playtest and human approval separately.

Do not expand scope into new economy, flight mechanics, a creature purchase shop, save resets or changes to global mutation rules. Loading this skill to create or validate the skill itself does not authorize integration of a sample creature.
