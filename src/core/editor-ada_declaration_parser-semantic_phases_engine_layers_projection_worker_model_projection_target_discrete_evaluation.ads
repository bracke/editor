with Ada.Strings.Unbounded;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Derivation;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_String_Evaluation;

package Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Discrete_Evaluation is

   package Target_Derivation renames
     Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Derivation;
   package Target_String_Evaluation renames
     Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_String_Evaluation;

   subtype Static_Discrete_Image_Query is
     Target_String_Evaluation.Static_Discrete_Image_Query;
   subtype Static_Discrete_Literal_Query is
     Target_String_Evaluation.Static_Discrete_Literal_Query;

   function Static_Discrete_Default_Position
     (Phase                            : Target_Derivation.Context;
      Type_Name                        : String;
      Default_Text                     : String;
      Parse_Static_Natural             : not null Target_Derivation.Static_Natural_Parser;
      Parse_Static_Integer             : not null Target_Derivation.Static_Integer_Parser;
      Static_Discrete_Literal_Position : not null Static_Discrete_Literal_Query;
      Static_Discrete_Position_Image   : not null Static_Discrete_Image_Query;
      Position                         : out Natural) return Boolean;

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Discrete_Evaluation;
