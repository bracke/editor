Pass1030 - record layout overlap, size, and alignment validation foundation

- Added Editor.Ada_Record_Layout_Validation.
- Projects record representation component-legality metadata into deterministic physical bit-span layout checks.
- Computes component start/end bit spans from static storage-unit, first-bit, and last-bit values.
- Detects overlapping component spans within a single record representation clause.
- Preserves static component layout errors and unresolved/duplicate component errors as separate layout metadata.
- Added counters for valid spans, overlaps, static layout errors, component errors, size-exceeded placeholders, alignment-warning placeholders, and fingerprints.
- Added AUnit regression Test_Ada_Record_Layout_Overlap_Size_Alignment_Pass1030.
