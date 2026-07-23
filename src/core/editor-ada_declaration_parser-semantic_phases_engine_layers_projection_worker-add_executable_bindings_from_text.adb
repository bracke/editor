with Editor.Ada_Declaration_Parser.Executable_Binding_Scanner;

separate (Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker)
   procedure Add_Executable_Bindings_From_Text
     (Analysis : in out Analysis_Result;
      Text     : String)
   is
   begin
      Editor.Ada_Declaration_Parser.Executable_Binding_Scanner.
        Add_Executable_Bindings_From_Text
          (Analysis => Analysis,
           Text     => Text);
   end Add_Executable_Bindings_From_Text;
