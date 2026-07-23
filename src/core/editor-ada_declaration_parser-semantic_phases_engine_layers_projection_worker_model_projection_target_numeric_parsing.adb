with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Numeric_Natural_Parsing;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Numeric_Integer_Parsing;

package body Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Numeric_Parsing is

   package Natural_Parsing renames Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Numeric_Natural_Parsing;
   package Integer_Parsing renames Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Numeric_Integer_Parsing;

   procedure Parse_Static_Natural
     (Ops   : Operations;
      Text  : String;
      Valid : out Boolean;
      Value : out Natural)
   is
   begin
      Natural_Parsing.Parse_Static_Natural (Ops, Text, Valid, Value);
   end Parse_Static_Natural;

   procedure Parse_Static_Integer
     (Ops   : Operations;
      Text  : String;
      Valid : out Boolean;
      Value : out Integer)
   is
   begin
      Integer_Parsing.Parse_Static_Integer (Ops, Text, Valid, Value);
   end Parse_Static_Integer;

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Numeric_Parsing;
