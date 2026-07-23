with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker;

package Editor.Ada_Declaration_Parser.Parse_Line_Pending_Phase is

   subtype Parse_Line_Context is
     Editor.Ada_Declaration_Parser
       .Semantic_Phases_Engine_Layers_Projection_Worker.Parse_Line_Context;

   procedure Clear_After_Scope_Close (Context : in out Parse_Line_Context);

end Editor.Ada_Declaration_Parser.Parse_Line_Pending_Phase;
