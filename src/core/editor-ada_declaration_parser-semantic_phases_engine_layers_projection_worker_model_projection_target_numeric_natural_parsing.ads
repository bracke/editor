with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Numeric_Parsing;

package Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Numeric_Natural_Parsing is

   package Target_Numeric_Parsing renames
     Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Numeric_Parsing;

   procedure Parse_Static_Natural
     (Ops   : Target_Numeric_Parsing.Operations;
      Text  : String;
      Valid : out Boolean;
      Value : out Natural);

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Numeric_Natural_Parsing;
