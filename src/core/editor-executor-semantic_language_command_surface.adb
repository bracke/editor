with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Commands.Availability_Metadata;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Ada_Language_Service;
with Editor.Executor.Semantic_Rename_Commands;
with Editor.Executor.Semantic_Service_State;
with Editor.Executor.Semantic_Service_Commands;
with Editor.Executor.Semantic_Symbol_Selection;
with Editor.Executor.Shared_Services;
with Editor.Render_Cache;

package body Editor.Executor.Semantic_Language_Command_Surface is

   use type Editor.Command_Ids.Command_Id;

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Info;

   function Current_Language_Service
     (S : Editor.State.State_Type)
      return Editor.Ada_Language_Service.Service_State
      renames Editor.Executor.Semantic_Service_State.Current_Language_Service;

   procedure Ensure_Current_Language_Service
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Semantic_Service_State
        .Ensure_Current_Language_Service;

   function Selected_Language_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Command_Ids.Command_Id)
      return Editor.Commands.Availability_Metadata.Command_Availability
   is
      Symbol  : constant Editor.Executor.Semantic_Symbol_Selection
        .Selected_Semantic_Symbol :=
        (if Id = Editor.Command_Ids.Command_Show_Completions
         then Editor.Executor.Semantic_Symbol_Selection
           .Current_Completion_Symbol (S)
         else Editor.Executor.Semantic_Symbol_Selection
           .Current_Semantic_Symbol (S));
      Service : Editor.Ada_Language_Service.Service_State :=
        Current_Language_Service (S);
      Name    : constant String := To_String (Symbol.Name);
   begin
      if not Symbol.Available then
         return Editor.Commands.Availability_Metadata.Unavailable
           ("No semantic symbol at cursor or Outline selection.");
      end if;

      case Id is
         when Editor.Command_Ids.Command_Find_References
            | Editor.Command_Ids.Command_Workspace_Symbols
            | Editor.Command_Ids.Command_Show_Hover
            | Editor.Command_Ids.Command_Show_Completions =>
            return Editor.Executor.Semantic_Service_Commands
              .Semantic_Service_Command_Availability (S, Id, Service, Name);

         when Editor.Command_Ids.Command_Rename_Symbol_Preview
            | Editor.Command_Ids.Command_Rename_Symbol_Apply =>
            return Editor.Executor.Semantic_Rename_Commands
              .Semantic_Rename_Command_Availability
                (S, Id, Service, Name);

         when others =>
            return Editor.Commands.Availability_Metadata.Unavailable
              ("Unsupported language command.");
      end case;
   end Selected_Language_Command_Availability;

   function Execute_Selected_Language_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Command_Ids.Command_Id;
      Target_Name : String := "")
      return Editor.Command_Execution.Command_Execution_Result
   is
      Symbol  : constant Editor.Executor.Semantic_Symbol_Selection
        .Selected_Semantic_Symbol :=
        (if Id = Editor.Command_Ids.Command_Show_Completions
         then Editor.Executor.Semantic_Symbol_Selection
           .Current_Completion_Symbol (S)
         else Editor.Executor.Semantic_Symbol_Selection
           .Current_Semantic_Symbol (S));
      Name    : constant String := To_String (Symbol.Name);
      Rename_To : constant String :=
        (if Target_Name'Length > 0 then Target_Name else Name & "_Renamed");
   begin
      Ensure_Current_Language_Service (S);
      if not Symbol.Available then
         Report_Info (S, "No semantic symbol at cursor or Outline selection.");
         Editor.Render_Cache.Invalidate_All;
         return Editor.Command_Execution.Unavailable (Id);
      end if;

      case Id is
         when Editor.Command_Ids.Command_Find_References
            | Editor.Command_Ids.Command_Workspace_Symbols
            | Editor.Command_Ids.Command_Show_Hover
            | Editor.Command_Ids.Command_Show_Completions =>
            return Editor.Executor.Semantic_Service_Commands
              .Execute_Semantic_Service_Command (S, Id, Name);

         when Editor.Command_Ids.Command_Rename_Symbol_Preview
            | Editor.Command_Ids.Command_Rename_Symbol_Apply =>
            return Editor.Executor.Semantic_Rename_Commands
              .Execute_Semantic_Rename_Command (S, Id, Name, Rename_To);

         when others =>
            return Editor.Command_Execution.Unavailable (Id);
      end case;
   end Execute_Selected_Language_Command;

end Editor.Executor.Semantic_Language_Command_Surface;
