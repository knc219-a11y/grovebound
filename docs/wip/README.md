2026-10-19: Motion changes have now been manually ported to the current small-actor runtime and revalidated. This patch is retained as historical source only; DO NOT reapply it. See STATUS.md and docs/motion-upgrade-gameplay.gif / .mp4. Dedicated moving-attack frames and boar fast-travel gait remain follow-up work.

Original handoff:
Motion upgrade paused for the world/actor proportion correction. `motion-upgrade.patch` contains uncommitted changes based on commit 840a16b, including matching regression tests. It is NOT applied to runtime. Rebase manually onto the corrected scale before resuming; do not blindly restore the old 2x visual scale. Previous local tests passed: gameplay self-test, pixel actor, action events and combat feedback.
