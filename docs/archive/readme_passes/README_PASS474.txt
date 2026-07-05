Pass 474 - scalar/storage representation attribute legality

Focus:
- Continue the representation/operational legality track beyond duplicate checks and target resolution.

Implemented:
- Added explicit representation clause kinds for Component_Size, Object_Size, Value_Size, Scalar_Storage_Order, Small, and Pack.
- Component_Size now requires an array type target in the retained model.
- Object_Size and Value_Size are classified as size-like representation attributes and require static natural values.
- Scalar_Storage_Order now requires a type-like target and accepts only Low_Order_First / High_Order_First, including System-qualified forms.
- Small now requires a fixed-point type target when the retained model has delta/fixed-point metadata.
- Pack now requires a static Boolean value in the bounded model.

Regression coverage:
- Test_Language_Model_Legality_Scalar_Storage_Representation_Pass
