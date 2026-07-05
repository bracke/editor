# Legacy Pass Migration

Active Ada validation units have been migrated away from historical numbered
pass identifiers in file names, package names, release records, and tests. New
work must keep those names case-based and must not reintroduce numbered pass
tokens.

Completed groups:

1. Project-scale validation packages now use descriptive package names.
2. Semantic/RM audit foundation packages now use descriptive package names.
3. RM burn-down packages now use `case_NNNN` files and `Case_NNNN` packages.
4. Remaining RM remediation packages now use `case_NNNN` files and
   `Case_NNNN` packages.

Safe migration order and maintenance rules:

1. Rename Ada files and package declarations together.
2. Update `with` clauses, GPR source references, release-check markers, and
   tests in the same change.
3. Run `tools/bin/test_commands_for --why <changed-files>` and the printed
   slices for each subsystem batch. RM validation changes should select
   `tools/bin/unit_tests ada-rm-validation`.
4. Keep historical `README_PASS*.txt` files in `docs/archive/readme_passes/`;
   do not restore them to the repository root.

The routine hygiene gate rejects live `phase*` artifacts, active numbered pass
tokens, and root-level historical pass logs.
