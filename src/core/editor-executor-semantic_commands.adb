with Editor.Ada_Language_Service;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Executor;
with Editor.Executor.Outline_Commands;
with Editor.Executor.Semantic_Completion_Commands;
with Editor.Executor.Semantic_Index_Commands;
with Editor.Executor.Semantic_Language_Command_Surface;
with Editor.Executor.Semantic_Navigation_Commands;
with Editor.Executor.Semantic_Symbol_Selection;
with Editor.State;

package body Editor.Executor.Semantic_Commands is

   use Editor.Commands;
   use type Editor.Ada_Language_Service.Service_Status;
   use type Editor.Commands.Command_Id;

   function Is_Ada_Source_Path
     (Path : String) return Boolean
      renames Editor.Executor.Semantic_Index_Commands.Is_Ada_Source_Path;

   procedure Publish_Service_Diagnostics_To_Feature
     (S            : in out Editor.State.State_Type;
      Path         : String;
      Buffer_Token : Natural)
      renames Editor.Executor.Semantic_Index_Commands
        .Publish_Service_Diagnostics_To_Feature;

   procedure Refresh_Project_Language_Index
     (S                  : in out Editor.State.State_Type;
      Build_Semantics    : Boolean;
      Indexed_File_Count : out Natural;
      Indexed_Symbols    : out Natural;
      Skipped_File_Count : out Natural;
      Read_Error_Count   : out Natural)
      renames Editor.Executor.Semantic_Index_Commands
        .Refresh_Project_Language_Index;

   procedure Load_Global_Active_Preserving_Language_Index
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Semantic_Index_Commands
        .Load_Global_Active_Preserving_Language_Index;

   procedure Rebuild_Language_Index_After_File_Lifecycle
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Semantic_Index_Commands
        .Rebuild_Language_Index_After_File_Lifecycle;

   procedure Clear_Service_Semantic_Diagnostics_From_Feature
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Semantic_Index_Commands
        .Clear_Service_Semantic_Diagnostics_From_Feature;

   function Current_Semantic_Symbol
     (S : Editor.State.State_Type)
      return Editor.Executor.Semantic_Symbol_Selection.Selected_Semantic_Symbol
      renames Editor.Executor.Semantic_Symbol_Selection
        .Current_Semantic_Symbol;

   function To_Navigation_Symbol
     (Symbol : Editor.Executor.Semantic_Symbol_Selection
                 .Selected_Semantic_Symbol)
      return Editor.Executor.Semantic_Navigation_Commands.Semantic_Symbol
      renames Editor.Executor.Semantic_Symbol_Selection.To_Navigation_Symbol;

   function Service_Status_Image
     (Status : Editor.Ada_Language_Service.Service_Status) return String
   is
   begin
      case Status is
         when Editor.Ada_Language_Service.Service_Success =>
            return "success";
         when Editor.Ada_Language_Service.Service_Unavailable =>
            return "unavailable";
         when Editor.Ada_Language_Service.Service_Ambiguous =>
            return "ambiguous";
         when Editor.Ada_Language_Service.Service_Overflow =>
            return "overflow";
         when Editor.Ada_Language_Service.Service_Stale =>
            return "stale";
      end case;
   end Service_Status_Image;

   function Semantic_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
   begin
      case Id is
         when Editor.Commands.Command_Refresh_Outline_Project_Index
            | Editor.Commands.Command_Semantic_Refresh_Buffer
            | Editor.Commands.Command_Semantic_Refresh_Project_Index
            | Editor.Commands.Command_Language_Index_Clear
            | Editor.Commands.Command_Language_Index_Status =>
            return Editor.Executor.Semantic_Index_Commands
              .Semantic_Index_Command_Availability (S, Id);

         when Editor.Commands.Command_Goto_Declaration =>
            return Editor.Executor.Semantic_Navigation_Commands
              .Semantic_Navigation_Command_Availability
                (S, Id, To_Navigation_Symbol (Current_Semantic_Symbol (S)));

         when Editor.Commands.Command_Goto_Body
            | Editor.Commands.Command_Goto_Spec =>
            return Editor.Executor.Semantic_Navigation_Commands
              .Semantic_Navigation_Command_Availability
                (S, Id, To_Navigation_Symbol (Current_Semantic_Symbol (S)));

         when Editor.Commands.Command_Find_References
            | Editor.Commands.Command_Workspace_Symbols
            | Editor.Commands.Command_Show_Hover
            | Editor.Commands.Command_Show_Completions
            | Editor.Commands.Command_Rename_Symbol_Preview
            | Editor.Commands.Command_Rename_Symbol_Apply =>
            return Editor.Executor.Semantic_Language_Command_Surface
              .Selected_Language_Command_Availability (S, Id);

         when Editor.Commands.Command_Semantic_Completion_Select_Next
            | Editor.Commands.Command_Semantic_Completion_Select_Previous
            | Editor.Commands.Command_Semantic_Completion_Accept
            | Editor.Commands.Command_Semantic_Popup_Dismiss =>
            return Editor.Executor.Semantic_Completion_Commands
              .Semantic_Completion_Command_Availability (S, Id);

         when others =>
            return Editor.Commands.Unavailable
              ("Unsupported semantic command.");
      end case;
   end Semantic_Command_Availability;

   function Execute_Semantic_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id;
      Cmd : Editor.Commands.Command)
      return Editor.Command_Execution.Command_Execution_Result
   is
      function Result_After_Command
        (Command : Editor.Commands.Command_Id)
         return Editor.Command_Execution.Command_Execution_Result is
      begin
         return Editor.Command_Execution.Executed (Command);
      end Result_After_Command;
   begin
      case Id is
         when Editor.Commands.Command_Refresh_Outline_Project_Index
            | Editor.Commands.Command_Semantic_Refresh_Buffer
            | Editor.Commands.Command_Semantic_Refresh_Project_Index
            | Editor.Commands.Command_Language_Index_Clear
            | Editor.Commands.Command_Language_Index_Status =>
            return Editor.Executor.Semantic_Index_Commands
              .Execute_Semantic_Index_Command (S, Id);

         when Editor.Commands.Command_Goto_Declaration =>
            return Editor.Executor.Semantic_Navigation_Commands
              .Execute_Semantic_Navigation_Command
                (S, Id, To_Navigation_Symbol (Current_Semantic_Symbol (S)));

         when Editor.Commands.Command_Goto_Body
            | Editor.Commands.Command_Goto_Spec =>
            return Editor.Executor.Semantic_Navigation_Commands
              .Execute_Semantic_Navigation_Command
                (S, Id, To_Navigation_Symbol (Current_Semantic_Symbol (S)));

         when Editor.Commands.Command_Find_References
            | Editor.Commands.Command_Workspace_Symbols
            | Editor.Commands.Command_Show_Hover
            | Editor.Commands.Command_Show_Completions =>
            return Editor.Executor.Semantic_Language_Command_Surface
              .Execute_Selected_Language_Command (S, Id);

         when Editor.Commands.Command_Rename_Symbol_Preview
            | Editor.Commands.Command_Rename_Symbol_Apply =>
            return Editor.Executor.Semantic_Language_Command_Surface
              .Execute_Selected_Language_Command
                (S, Id, To_String (Cmd.Text));

         when others =>
            return Editor.Command_Execution.Unavailable (Id);
      end case;
   end Execute_Semantic_Command;

end Editor.Executor.Semantic_Commands;
