pass 226

Adds bounded Ada callable body-shape metadata to the parser-owned language model:
- Has_Null_Subprogram_Metadata for null procedures.
- Has_Expression_Function_Metadata for expression functions.

The metadata is retained on the owning callable symbol and surfaced in Outline details without creating rows, scopes, or learned semantic symbols from the null/expression body.
