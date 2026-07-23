with Editor.Ada_Language_Model;
with Editor.Ada_Declaration_Parser.Parse_Line_Phase_States;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker;

package Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase is

   subtype Symbol_Id is Editor.Ada_Language_Model.Symbol_Id;
   subtype Collected_Symbol_List is
     Editor.Ada_Declaration_Parser
       .Semantic_Phases_Engine_Layers_Projection_Worker.Collected_Symbol_List;
   subtype Declaration_Target_Context is
     Editor.Ada_Declaration_Parser
       .Semantic_Phases_Engine_Layers_Projection_Worker
       .Parse_Line_Declaration_Target_Context;
   subtype Scope_Context is
     Editor.Ada_Declaration_Parser
       .Semantic_Phases_Engine_Layers_Projection_Worker
       .Parse_Line_Scope_Context;
   subtype Profile_Context is
     Editor.Ada_Declaration_Parser
       .Semantic_Phases_Engine_Layers_Projection_Worker
       .Parse_Line_Profile_Context;
   subtype Phase_State is
     Editor.Ada_Declaration_Parser.Parse_Line_Phase_States
       .Parse_Line_Phase_State;

   procedure Begin_Generic (Targets : in out Declaration_Target_Context);
   procedure Consume_Generic_Unit
     (Targets : in out Declaration_Target_Context);

   procedure Set_Pending_Type_Header
     (Targets : in out Declaration_Target_Context;
      Owner   : Symbol_Id);
   procedure Set_Pending_Record_After_Is
     (Targets : in out Declaration_Target_Context;
      Owner   : Symbol_Id);
   procedure Set_Pending_Concurrent_Header
     (Targets : in out Declaration_Target_Context;
      Owner   : Symbol_Id);
   procedure Set_Pending_Array_Target
     (Targets : in out Declaration_Target_Context;
      Owner   : Symbol_Id);
   procedure Set_Pending_Access_Target
     (Targets : in out Declaration_Target_Context;
      Owner   : Symbol_Id);
   procedure Set_Pending_Return_Target
     (Targets : in out Declaration_Target_Context;
      Owner   : Symbol_Id);
   procedure Set_Pending_Return_Access_Target
     (Targets : in out Declaration_Target_Context;
      Owner   : Symbol_Id);
   procedure Set_Pending_Subtype_Target
     (Targets : in out Declaration_Target_Context;
      Owner   : Symbol_Id);
   procedure Set_Pending_Derived_Target
     (Targets : in out Declaration_Target_Context;
      Owner   : Symbol_Id);
   procedure Set_Pending_Interface_Target
     (Targets : in out Declaration_Target_Context;
      Owner   : Symbol_Id);
   procedure Set_Pending_Declaration_Target
     (Targets : in out Declaration_Target_Context;
      Owner   : Symbol_Id);
   procedure Set_Pending_Generic_Formal_Package_Target
     (Targets : in out Declaration_Target_Context;
      Owner   : Symbol_Id);
   procedure Set_Pending_Generic_Formal_Subprogram_Target
     (Targets : in out Declaration_Target_Context;
      Owner   : Symbol_Id);

   procedure Start_Pending_Object_Array_Targets
     (Targets : in out Declaration_Target_Context);
   procedure Start_Pending_Object_Access_Targets
     (Targets : in out Declaration_Target_Context);
   procedure Start_Pending_Object_Access_Subprogram_Profiles
     (Targets : in out Declaration_Target_Context);
   procedure Start_Pending_Generic_Formal_Object_Targets
     (Targets : in out Declaration_Target_Context);

   procedure Set_Pending_Discriminants
     (Targets : in out Declaration_Target_Context;
      Owner   : Symbol_Id);
   procedure Clear_Pending_Discriminants
     (Targets : in out Declaration_Target_Context);

   function Handle_Generic_Formal_Object_Line
     (Analysis    : in out Editor.Ada_Language_Model.Analysis_Result;
      Decl        : String;
      Decl_Lower  : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id;
      Targets     : in out Declaration_Target_Context) return Boolean;

   function Handle_Object_Declaration_Line
     (Analysis    : in out Editor.Ada_Language_Model.Analysis_Result;
      Raw_Line    : String;
      Decl        : String;
      Decl_Lower  : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id;
      Flags       : Editor.Ada_Language_Model.Declaration_Flags;
      Targets     : in out Declaration_Target_Context) return Boolean;

   function Recognize_Declaration_Line
     (Analysis       : in out Editor.Ada_Language_Model.Analysis_Result;
      Raw_Line       : String;
      Raw_Decl       : String;
      Decl           : String;
      Decl_Lower     : String;
      Line_Number    : Positive;
      Depth          : Natural;
      Parent         : Symbol_Id;
      Scope          : in out Scope_Context;
      Targets        : in out Declaration_Target_Context;
      State          : in out Phase_State) return Boolean;

   function Handle_Same_Line_Declaration_Groups
     (Analysis        : in out Editor.Ada_Language_Model.Analysis_Result;
      Raw_Line        : String;
      Decl            : String;
      Decl_Lower      : String;
      Line_Number     : Positive;
      Depth           : Natural;
      Parent          : Symbol_Id;
      Is_Private      : Boolean;
      Pending_Generic : Boolean;
      Profile         : in out Profile_Context) return Boolean;

end Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase;
