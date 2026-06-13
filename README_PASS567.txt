Pass 567 - Static string constants for scalar Value

This pass extends the bounded static-expression evaluator used by Ada
representation legality/projection.

Implemented:
- Retained bounded static string constants initialized by ordinary string
  literals.
- Retained bounded static string constants initialized by scalar Image
  attributes, including Base Image forms.
- Scalar Value evaluation now accepts retained string constants as its image
  argument.
- Typed discrete constants can now be initialized from Value over a named
  string constant, for example:
    Name : constant String := "Green";
    Default : constant Color := Color'Value (Name);
- Image-fed string constants can likewise initialize typed discrete constants,
  for example:
    Name : constant String := Color'Image (Blue);
    Default : constant Color := Color'Value (Name);
- Existing subtype/range compatibility checks are preserved; named strings
  that denote values outside a constrained scalar subtype stay nonstatic.

Regression coverage:
- Named string literal consumed by Color'Value.
- Named Color'Image value consumed by Color'Value.
- Out-of-range constrained subtype constant initialized through a named string
  remains nonstatic and emits the existing static-value diagnostic.

Scope:
- This remains a bounded semantic evaluator for IDE legality/projection.  It
  does not attempt full Ada string-expression folding or wide-character image
  decoding.
