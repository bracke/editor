package Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker.Statement_Awareness is

   procedure Mark_Statement_Awareness
     (Analysis   : in out Editor.Ada_Language_Model.Analysis_Result;
      Lower_Line : String;
      Trimmed    : String;
      In_Record  : Boolean);

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker.Statement_Awareness;
