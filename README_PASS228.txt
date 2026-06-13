Pass 228 parser-completeness increment

Adds bounded discriminant-part declaration metadata to the Ada language model and parser. Discriminated type headers are marked on the owning type symbol with Has_Discriminant_Part_Metadata and projected in Outline details as discriminant-part. The pass keeps the feature non-declarative: discriminant expressions do not create standalone Outline rows or semantic symbols, and callable/access profiles are not misclassified as discriminant parts.
