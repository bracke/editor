# End-to-End Editor Integration Validation - Case 1432

Case 1432 adds the project-scale integration gate after release-readiness validation.
It validates editor workflow surfaces rather than reopening Ada RM remediation.

The validated surfaces are:

- startup and project open;
- buffer edit, save, reload, and revert;
- file-tree create, rename, and delete;
- project search;
- outline projection;
- semantic colouring;
- diagnostics/problems;
- build panel;
- workspace restore;
- project close and project switch.

The pass rejects evidence that performs rendering-side parsing, saves or reloads files during analysis, mutates dirty state, leaks analysis mutation into command, keybinding, workspace, or render surfaces, accepts stale snapshots, runs without bounded-work evidence, produces consumer disagreement, or reopens a Remaining_* edge after the case 1428 closure.
