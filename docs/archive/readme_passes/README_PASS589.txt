Pass 589 - Qualified constrained String index/slice bounds

- Extended bounded static String indexing and slicing so qualified constrained
  String prefixes use their retained First/Last bounds instead of always
  rebasing the image at index 1.
- Newly covered forms include Offset_Name'("Green") (2) and
  Offset_Name'("Green") (2 .. 3), where Offset_Name is String (2 .. 6).
- Index and slice validation now converts through the retained lower bound
  before reading the stored image text, while preserving existing out-of-range
  and null-slice rejection behavior.
- Added regression coverage for offset-qualified slices feeding scalar Value
  and offset-qualified indexing feeding Character'Pos arithmetic.
