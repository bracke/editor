Pass 546 - precise static Modulus attribute evaluation
======================================================

This pass extends the retained static-expression evaluator with modular
scalar attribute handling.

Implemented changes
-------------------

* Added a retained modular-type modulus lookup from the existing scalar range
  metadata built for `type T is mod N` declarations.
* `T'Modulus` is now accepted as a static integer value for modular types.
* `T'Base'Modulus` is now accepted through the same chained Base attribute path
  used by `T'Base'First` and `T'Base'Last`.
* Natural-valued representation clauses, signed static expressions, and
  numeric-only clauses such as `Small` all share the same modular attribute
  compatibility check.
* Nonmodular `T'Modulus` remains nonstatic and produces the existing
  representation static-value diagnostic.

Regression coverage
-------------------

Added AUnit coverage for:

* `Byte'Modulus / 8` flowing into a `Size` clause.
* `Byte'Base'Modulus / 16` flowing through chained Base attribute evaluation.
* `Count'Modulus` on a nonmodular integer type staying nonstatic.
* `Byte'Modulus / 2.0` being accepted by the numeric-only `Small` path.
