Editor pass762

Pass762 adds resolver-facing language-model hints for Ada call-shaped ambiguity.

Changed:

* Added executable binding kinds for selected call prefixes, selected operation leaves, dispatching-style prefixes, indexed call prefixes, and entry-family candidate names.
* Added a bounded parser-owned call ambiguity hint scanner in the Ada declaration parser.
* Added AUnit regression `Test_Language_Model_Call_Ambiguity_Resolver_Hints`.
* Updated validation guards and the parser coverage matrix.

This improves structural grammar/model coverage for call/entry-call ambiguity. It is not compiler-grade overload resolution, dispatching legality, entry-family target resolution, profile conformance, or tasking semantics.
