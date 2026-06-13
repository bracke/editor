Pass 607 - Subtype-indication copied String Range constraints
============================================================

Scope
-----
This pass extends the bounded static String range-copy path to recognize copied
Range constraints wrapped in a discrete subtype indication.

Implemented
-----------
- Added stripping for a leading subtype-mark/range marker before resolving the
  final copied `Range` attribute in String index constraints.
- Newly covered form:

  ```ada
  subtype Offset_Name is String (2 .. 6);
  subtype Subtype_Indication_Range_Name is
    String (Positive range Offset_Name'Range);
  ```

- The derived subtype now preserves the copied source bounds:
  - `First = 2`
  - `Last = 6`
  - `Length = 5`
- Plain copied range attributes such as `Offset_Name'Range`, dimensioned forms
  such as `Offset_Name'Range (1)`, named constants, and inline qualified String
  prefixes keep their existing behavior.
- Added regression coverage in the static String qualification pass for the
  subtype-indication copied Range form feeding representation static values.

Limits
------
This remains a bounded one-dimensional String static evaluator. It does not try
to model arbitrary array types, multidimensional ranges, or nonstatic subtype
marks beyond preserving the copied String range metadata.
