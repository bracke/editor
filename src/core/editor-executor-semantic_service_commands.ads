with Editor.Ada_Language_Service;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.State;

package Editor.Executor.Semantic_Service_Commands is

   function Semantic_Find_References
     (S       : Editor.State.State_Type;
      Service : in out Editor.Ada_Language_Service.Service_State;
      Name    : String)
      return Editor.Ada_Language_Service.Language_Target_Set;

   function Semantic_Workspace_Symbols
     (Service : in out Editor.Ada_Language_Service.Service_State;
      Query   : String)
      return Editor.Ada_Language_Service.Language_Target_Set;

   function Semantic_Hover
     (S       : Editor.State.State_Type;
      Service : in out Editor.Ada_Language_Service.Service_State;
      Name    : String)
      return Editor.Ada_Language_Service.Hover_Result;

   function Semantic_Complete
     (S       : Editor.State.State_Type;
      Service : in out Editor.Ada_Language_Service.Service_State;
      Prefix  : String;
      Limit   : Positive)
      return Editor.Ada_Language_Service.Completion_Result;

   function Semantic_Service_Command_Availability
     (S       : Editor.State.State_Type;
      Id      : Editor.Commands.Command_Id;
      Service : in out Editor.Ada_Language_Service.Service_State;
      Name    : String)
      return Editor.Commands.Command_Availability;

   function Execute_Semantic_Service_Command
     (S    : in out Editor.State.State_Type;
      Id   : Editor.Commands.Command_Id;
      Name : String)
      return Editor.Command_Execution.Command_Execution_Result;

end Editor.Executor.Semantic_Service_Commands;
