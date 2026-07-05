pass 230

Implemented a bounded parser/model coverage increment for Ada overriding indicators.

Changes:
- Retained explicit overriding and not-overriding indicators in Outline detail projection.
- Added Test_Language_Model_Overriding_Indicator_Metadata.
- Extended language_validation_check for model/parser/test markers.
- Updated README and docs.

The metadata remains declaration-owned: overriding keywords do not create Outline rows, do not open scopes, and are not learned as semantic identifiers.
