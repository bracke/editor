with Editor.Ada_Language_Model;
with Editor.Ada_Declaration_Parser.Declaration_Collectors;
with Editor.Ada_Declaration_Parser.Parse_Line_Contexts;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker is

   use Editor.Ada_Language_Model;

   subtype Collected_Symbol_List is
     Editor.Ada_Declaration_Parser.Declaration_Collectors.Collected_Symbol_List;

   Max_Scope_Nesting : constant Natural :=
     Editor.Ada_Declaration_Parser.Parse_Line_Contexts.Max_Scope_Nesting;
   subtype Scope_Stack_Type is
     Editor.Ada_Declaration_Parser.Parse_Line_Contexts.Scope_Stack_Type;
   subtype Scope_Private_Stack_Type is
     Editor.Ada_Declaration_Parser.Parse_Line_Contexts.Scope_Private_Stack_Type;
   subtype Parse_Line_Scope_Context is
     Editor.Ada_Declaration_Parser.Parse_Line_Contexts.Scope_Context;
   subtype Parse_Line_Declaration_Target_Context is
     Editor.Ada_Declaration_Parser.Parse_Line_Contexts.Declaration_Target_Context;
   subtype Parse_Line_Profile_Context is
     Editor.Ada_Declaration_Parser.Parse_Line_Contexts.Profile_Context;
   subtype Parse_Line_Executable_Binding_Context is
     Editor.Ada_Declaration_Parser.Parse_Line_Contexts.Executable_Binding_Context;
   subtype Parse_Line_Source_Recovery_Context is
     Editor.Ada_Declaration_Parser.Parse_Line_Contexts.Source_Recovery_Context;
   subtype Parse_Line_Context is
     Editor.Ada_Declaration_Parser.Parse_Line_Contexts.Context;

   function Parse
     (Text         : String;
      Buffer_Label : String := "") return Editor.Ada_Language_Model.Analysis_Result;

   procedure Project_Syntax_Tree_Into_Model
     (Analysis    : in out Editor.Ada_Language_Model.Analysis_Result;
      Tree        : Editor.Ada_Syntax_Tree.Tree_Type;
      Source_Text : String);

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker;
