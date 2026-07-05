Pass1005 — attribute-reference expression type inference

This pass extends Editor.Ada_Expression_Types with deterministic attribute-reference inference metadata. Attribute references now retain normalized attribute name, prefix text, prefix type, inferred result subtype, per-attribute status, and counters for resolved, static/integer, string, unknown, and prefix-unresolved results.

Covered first-layer attribute families:

* scalar and range bounds: First, Last, Range
* integer-valued scalar/range/storage attributes: Length, Pos, Size, Object_Size, Value_Size, Component_Size, Alignment, Storage_Size, Max_Size_In_Storage_Elements
* enumeration/value attributes: Val, Succ, Pred, Value
* string-valued attributes: Image, Wide_Image, Wide_Wide_Image, Img
* address-valued attributes: Address
* Boolean task-like attributes: Callable, Terminated
* access-valued attributes: Access, Unchecked_Access, Unrestricted_Access

Unknown attributes and unresolved prefixes remain explicit metadata rather than being silently accepted. This is a compiler-grade building block for expression type inference; full compiler-grade Ada analysis still requires deeper attribute-specific legality, overload-aware prefix resolution, expected-type propagation through more expression forms, and cross-unit semantic closure integration.

Regression coverage: Test_Ada_Expression_Attribute_Reference_Inference_Pass1005.
