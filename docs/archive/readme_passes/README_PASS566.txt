Pass 566 - Static Value/Image interaction

Implemented bounded static evaluation for scalar Image attributes used as the static string argument to Value.

Highlights:
- `T'Value (U'Image (X))` can now initialize typed discrete static constants when `U` is subtype-compatible with `T`.
- Chained base forms such as `Color'Value (Color'Base'Image (Blue))` are accepted.
- Boolean image/value constants are retained.
- Constrained subtype checks are preserved, so image/value results outside the target subtype stay nonstatic and continue to produce the existing static-value diagnostic.
- Extended the scalar Value regression test to cover Image-fed enumeration, Base enumeration, Boolean, and out-of-range constrained subtype cases.
