with Editor.Ada_Language_Service;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.State;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package Editor.Executor.Semantic_Rename_Commands is

   function Semantic_Rename_Preview
     (S        : Editor.State.State_Type;
      Service  : in out Editor.Ada_Language_Service.Service_State;
      Old_Name : String;
      New_Name : String)
      return Editor.Ada_Language_Service.Rename_Preview;

   function Rename_Preview_Is_Open_Buffers_Applyable
     (S       : Editor.State.State_Type;
      Preview : Editor.Ada_Language_Service.Rename_Preview;
      Reason  : out Unbounded_String) return Boolean;

   function Semantic_Rename_Command_Availability
     (S       : Editor.State.State_Type;
      Id      : Editor.Commands.Command_Id;
      Service : in out Editor.Ada_Language_Service.Service_State;
      Name    : String)
      return Editor.Commands.Command_Availability;

   function Execute_Semantic_Rename_Command
     (S         : in out Editor.State.State_Type;
      Id        : Editor.Commands.Command_Id;
      Name      : String;
      Rename_To : String)
      return Editor.Command_Execution.Command_Execution_Result;

end Editor.Executor.Semantic_Rename_Commands;
