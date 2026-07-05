Pass1324: Access type/access-to-subprogram vertical slice legality

This pass adds Editor.Ada_Access_Type_Access_Subprogram_Vertical_Slice_Legality.
It is a concrete vertical semantic slice rather than diagnostic/provenance/recheck plumbing.

The pass models Ada access object, anonymous access, access-to-subprogram, null-exclusion,
designated-view, storage-pool, storage-size, profile-conformance, convention, and
accessibility legality.  It rejects missing access types, missing designated types,
missing profiles, access kind mismatches, private/limited/incomplete/generic-formal view
barriers, null-exclusion violations, static accessibility escapes, access-to-subprogram
profile mismatches, convention mismatches, storage pool conflicts, non-static storage-size
requirements, storage-size incompatibilities, and stale source/type/profile/pool evidence.

The accompanying AUnit tests use source-shaped access type, designated type, access use,
profile, accessibility, storage pool, and stale-fingerprint scenarios rather than synthetic
closure-state transitions.
