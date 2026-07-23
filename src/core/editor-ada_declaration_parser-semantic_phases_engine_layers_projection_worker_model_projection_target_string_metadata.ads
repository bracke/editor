with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Derivation;

package Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_String_Metadata is

   package Target_Derivation renames
     Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Derivation;

   procedure Register_Static_String_Constant
     (Phase                       : in out Target_Derivation.Context;
      Name                        : String;
      Type_Name                   : String;
      Default_Text                : String;
      Static_String_Default_Value : not null Target_Derivation.Static_String_Default_Query);

   procedure Store_Static_String_Subtype_Bounds_From_Range_Attribute
     (Phase                                  : in out Target_Derivation.Context;
      Name                                   : String;
      Range_Text                             : String;
      Parse_Static_Integer                   : not null Target_Derivation.Static_Integer_Parser;
      Normalize_Character_Pos_Static_Operands : not null Target_Derivation.String_To_String;
      Static_String_Default_Value            : not null Target_Derivation.Static_String_Default_Query;
      Static_String_Bound_Value              : not null Target_Derivation.Static_String_Bound_Query);

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_String_Metadata;
