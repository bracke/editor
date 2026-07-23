with Editor.Ada_Declaration_Parser.Legality_Diagnostics;

separate (Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker)
   procedure Add_Legality_Diagnostics (Analysis : in out Analysis_Result) is
   begin
      Editor.Ada_Declaration_Parser.Legality_Diagnostics.Add_Legality_Diagnostics
        (Analysis);
   end Add_Legality_Diagnostics;
