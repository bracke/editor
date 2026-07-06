with Editor.Command_Execution;
with Editor.Commands;
with Editor.Ada_Language_Service;
with Editor.State;

package Editor.Executor.Semantic_Commands is


   function Is_Ada_Source_Path
     (Path : String) return Boolean;

   procedure Publish_Service_Diagnostics_To_Feature
     (S            : in out Editor.State.State_Type;
      Path         : String;
      Buffer_Token : Natural);

   procedure Refresh_Project_Language_Index
     (S                  : in out Editor.State.State_Type;
      Build_Semantics    : Boolean;
      Indexed_File_Count : out Natural;
      Indexed_Symbols    : out Natural;
      Skipped_File_Count : out Natural;
      Read_Error_Count   : out Natural);

   procedure Load_Global_Active_Preserving_Language_Index
     (S : in out Editor.State.State_Type);

   procedure Rebuild_Language_Index_After_File_Lifecycle
     (S : in out Editor.State.State_Type);

   procedure Clear_Service_Semantic_Diagnostics_From_Feature
     (S : in out Editor.State.State_Type);

   function Current_Semantic_Symbol_Name
     (State : Editor.State.State_Type) return String;

   function Selected_Outline_Language_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   function Semantic_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   function Semantic_Completion_Popup_Is_Active
     (S : Editor.State.State_Type) return Boolean;

   function Service_Status_Image
     (Status : Editor.Ada_Language_Service.Service_Status) return String;

   function Execute_Selected_Outline_Language_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id;
      Target_Name : String := "")
      return Editor.Command_Execution.Command_Execution_Result;

   function Execute_Semantic_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id;
      Cmd : Editor.Commands.Command)
      return Editor.Command_Execution.Command_Execution_Result;

end Editor.Executor.Semantic_Commands;
