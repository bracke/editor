with Editor.Ada_Language_Model;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker;

package Editor.Ada_Declaration_Parser.Parse_Line_Executable_Phase is

   subtype Symbol_Id is Editor.Ada_Language_Model.Symbol_Id;
   subtype Executable_Context is
     Editor.Ada_Declaration_Parser
       .Semantic_Phases_Engine_Layers_Projection_Worker
       .Parse_Line_Executable_Binding_Context;
   subtype Declaration_Target_Context is
     Editor.Ada_Declaration_Parser
       .Semantic_Phases_Engine_Layers_Projection_Worker
       .Parse_Line_Declaration_Target_Context;
   subtype Scope_Context is
     Editor.Ada_Declaration_Parser
       .Semantic_Phases_Engine_Layers_Projection_Worker
       .Parse_Line_Scope_Context;

   procedure Set_Pending_Body
     (Executable : in out Executable_Context;
      Owner      : Symbol_Id);
   procedure Clear_Pending_Body
     (Executable : in out Executable_Context);
   procedure Clear_Pending_Body_For_Owner
     (Executable : in out Executable_Context;
      Owner      : Symbol_Id);

   procedure Set_Pending_Enumeration
     (Executable : in out Executable_Context;
      Owner      : Symbol_Id);
   procedure Clear_Pending_Enumeration
     (Executable : in out Executable_Context);

   function Handle_Executable_Continuation
     (Analysis                            : in out Editor.Ada_Language_Model.Analysis_Result;
      Raw_Line                            : String;
      Lower_Line                          : String;
      Line_Number                         : Positive;
      Depth                               : Natural;
      Parent                              : Symbol_Id;
      Starts_With_Declaration_Or_Metadata : Boolean;
      Targets                             : in out Declaration_Target_Context;
      Executable                          : in out Executable_Context;
      Scope                               : in out Scope_Context) return Boolean;

end Editor.Ada_Declaration_Parser.Parse_Line_Executable_Phase;
