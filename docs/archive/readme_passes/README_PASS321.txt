Pass 321 - grammar-aware recovery

Implemented grammar-aware recovery in Editor.Ada_Syntax_Tree:
- Node_Recovery_Point
- Node_Missing_End
- Node_Unexpected_End
- Node_Mismatched_End

The parser now synchronizes mismatched end boundaries against the nearest compatible open Ada construct, inserts explicit missing-end nodes for skipped inner scopes, records orphan alternatives as mismatched recovery, and emits EOF missing-end nodes for unterminated scopes. Added AUnit coverage and release-check guards.
