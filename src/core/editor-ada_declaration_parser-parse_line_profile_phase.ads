with Editor.Ada_Language_Model;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker;

package Editor.Ada_Declaration_Parser.Parse_Line_Profile_Phase is

   subtype Symbol_Id is Editor.Ada_Language_Model.Symbol_Id;
   subtype Profile_Context is
     Editor.Ada_Declaration_Parser
       .Semantic_Phases_Engine_Layers_Projection_Worker
       .Parse_Line_Profile_Context;
   subtype Declaration_Target_Context is
     Editor.Ada_Declaration_Parser
       .Semantic_Phases_Engine_Layers_Projection_Worker
       .Parse_Line_Declaration_Target_Context;
   subtype Executable_Binding_Context is
     Editor.Ada_Declaration_Parser
       .Semantic_Phases_Engine_Layers_Projection_Worker
       .Parse_Line_Executable_Binding_Context;
   subtype Scope_Context is
     Editor.Ada_Declaration_Parser
       .Semantic_Phases_Engine_Layers_Projection_Worker
       .Parse_Line_Scope_Context;

   procedure Set_Pending_Profile
     (Profile : in out Profile_Context;
      Owner   : Symbol_Id);
   procedure Clear_Pending_Profile (Profile : in out Profile_Context);
   procedure Clear_Pending_Profile_For_Owner
     (Profile : in out Profile_Context;
      Owner   : Symbol_Id);
   procedure Clear_Pending_Access_Targets
     (Profile : in out Profile_Context);

   procedure Handle_Pending_Profile_Continuation
     (Analysis       : in out Editor.Ada_Language_Model.Analysis_Result;
      Raw_Line       : String;
      Lower_Line     : String;
      Line_Number    : Positive;
      Depth          : Natural;
      Profile        : in out Profile_Context;
      Targets        : in out Declaration_Target_Context;
      Binding        : in out Executable_Binding_Context;
      Scope          : in out Scope_Context);

end Editor.Ada_Declaration_Parser.Parse_Line_Profile_Phase;
