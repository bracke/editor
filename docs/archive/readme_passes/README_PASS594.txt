Pass 594 - Static-expression separator whitespace

- Added a shared bounded static whitespace predicate for ordinary Ada separator characters used inside source expressions.
- Static numeric parsing now skips tab/form-feed/line-separator characters where it previously skipped only literal spaces.
- Static String qualification accepts tab-separated qualifier delimiters such as `String'\t("Gr" & "een")`.
- Qualified static String indexing/slicing paths inherit the broader whitespace handling, so tab-separated suffixes such as `String'("Green")\t(1)` remain static.
- Added regression coverage for tab-separated String qualification feeding scalar `Value` and tab-separated qualified indexing feeding `Character'Pos`.
