Editor pass371

This pass expands representation-clause interpretation beyond simple record
component layout metadata.

Changes:
- Added bounded non-record representation clause metadata to
  Editor.Ada_Language_Model.
- Added Representation_Clause_Kind / Representation_Clause_Info storage for:
  enumeration representation clauses, Size, Alignment, Bit_Order, Address,
  Storage_Size, Storage_Pool, record clauses, and conservative other clauses.
- Added bounded Enumeration_Representation_Literal_Info storage for
  enumeration representation associations such as:
    for Colour use (Red => 1, Green => 16#10#);
- Syntax-tree projection now converts retained representation clause nodes into
  typed language-model metadata, including parsed static natural values where
  expressions are simple Ada integer literals already supported by the static
  parser.
- Attribute representation clauses such as T'Size and T'Alignment now retain
  target, attribute, raw item text, and simple static values.
- Address-style clauses are retained as explicit address representation metadata
  without attempting unsafe expression evaluation.
- Added regression coverage:
  Test_Language_Model_Representation_Clauses_Beyond_Record_Layout

Conservative boundaries:
- No GNAT-equivalent representation legality checking.
- No arbitrary static-expression evaluation.
- No layout overlap/alignment validation.
- Unsupported representation expressions remain retained as source text without
  a parsed static value.
