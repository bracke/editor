with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Ada.Directories;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Command_Execution;
with Editor.Configuration_Recovery;
with Editor.Executor;
with Editor.Keybinding_Config;
with Editor.Keybinding_Management;
use type Editor.Keybinding_Management.Keybinding_Action_Status;
use type Editor.Keybinding_Management.Keybinding_Capture_State;
with Editor.Keybindings;
use type Editor.Keybindings.Keybinding_Validation_Status;
with Editor.Messages;
use type Editor.Messages.Message_Severity;
with Editor.Project;
with Editor.Recent_Projects;
with Editor.Render_Cache;
with Editor.Settings;
use type Editor.Settings.Settings_Status;
with Editor.Settings_Management;
use type Editor.Settings_Management.Setting_Update_Status;
with Editor.Startup_Readiness;
with Editor.State;
with Editor.Workspace_Persistence;

package body Editor.Executor.Configuration_Commands is

   use Editor.Commands;

   function Configuration_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
      pragma Unreferenced (S);
   begin
      case Id is
         when Command_Save_Settings
            | Command_Reload_Settings
            | Command_Reset_Settings_To_Defaults
            | Command_Validate_Keybindings
            | Command_Keybindings_Show
            | Command_Keybindings_Focus
            | Command_Keybindings_Filter_Conflicts
            | Command_Keybindings_Filter_Unbound
            | Command_Keybindings_Clear_Filter =>
            return Editor.Commands.Available;

         when Command_Startup_Show_Summary =>
            if not Editor.Startup_Readiness.Has_Recorded_Startup_Summary then
               return Editor.Commands.Unavailable ("No startup summary available.");
            end if;
            return Editor.Commands.Available;

         when Command_Configuration_Recover_Show
            | Command_Configuration_Audit =>
            return Editor.Commands.Available;

         when Command_Configuration_Reset_All_Confirm
            | Command_Configuration_Reset_All_Cancel =>
            if not Editor.Configuration_Recovery.Has_Pending_Reset_All_Confirmation then
               return Editor.Commands.Unavailable ("No recovery actions available.");
            end if;
            return Editor.Commands.Available;

         when Command_Configuration_Reset_Settings
            | Command_Configuration_Reset_Keybindings
            | Command_Configuration_Reset_Workspace
            | Command_Configuration_Reset_Recent_Projects
            | Command_Configuration_Reset_All
            | Command_Configuration_Save_Clean_Settings
            | Command_Configuration_Save_Clean_Keybindings
            | Command_Configuration_Save_Clean_Workspace
            | Command_Configuration_Save_Clean_Recent_Projects =>
            if Editor.Configuration_Recovery.Has_Pending_Reset_All_Confirmation then
               return Editor.Commands.Unavailable
                 ("Command unavailable while confirmation is pending");
            end if;
            return Editor.Commands.Available;

         when Command_Keybindings_Cancel_Capture =>
            if Editor.Keybinding_Management.Has_Pending_Reset
              or else Editor.Keybinding_Management.Current_Capture_State
                /= Editor.Keybinding_Management.Capture_Inactive
            then
               return Editor.Commands.Available;
            end if;
            return Editor.Commands.Unavailable ("Shortcut capture is not active");

         when Command_Save_Keybindings
            | Command_Reload_Keybindings =>
            if Editor.Keybinding_Management.Has_Pending_Reset
              or else Editor.Keybinding_Management.Current_Capture_State
                /= Editor.Keybinding_Management.Capture_Inactive
            then
               return Editor.Commands.Unavailable
                 ("Command unavailable while confirmation is pending");
            end if;
            return Editor.Commands.Available;

         when Command_Keybindings_Assign_Selected =>
            if not Editor.Keybinding_Management.Is_Visible then
               return Editor.Commands.Unavailable ("Keybindings view is not open");
            elsif Editor.Keybinding_Management.Has_Pending_Reset then
               return Editor.Commands.Unavailable
                 ("Command unavailable while confirmation is pending");
            elsif Editor.Keybinding_Management.Current_Capture_State
              /= Editor.Keybinding_Management.Capture_Inactive
            then
               return Editor.Commands.Unavailable ("Shortcut capture is active");
            elsif Editor.Keybinding_Management.Selected_Command = Editor.Commands.No_Command then
               return Editor.Commands.Unavailable ("No command selected");
            elsif not Editor.Keybindings.Is_Normal_Assignable_Command
              (Editor.Keybinding_Management.Selected_Command)
            then
               return Editor.Commands.Unavailable ("Selected command is not bindable");
            end if;
            return Editor.Commands.Available;

         when Command_Keybindings_Remove_Selected =>
            if not Editor.Keybinding_Management.Is_Visible then
               return Editor.Commands.Unavailable ("Keybindings view is not open");
            elsif Editor.Keybinding_Management.Has_Pending_Reset
              or else Editor.Keybinding_Management.Current_Capture_State
                /= Editor.Keybinding_Management.Capture_Inactive
            then
               return Editor.Commands.Unavailable
                 ("Command unavailable while confirmation is pending");
            elsif Editor.Keybinding_Management.Has_Selected_Chord then
               return Editor.Commands.Available;
            elsif Editor.Keybinding_Management.Selected_Command = Editor.Commands.No_Command
            then
               return Editor.Commands.Unavailable ("No keybinding selected");
            elsif not Editor.Keybindings.Is_Normal_Assignable_Command
              (Editor.Keybinding_Management.Selected_Command)
            then
               return Editor.Commands.Unavailable ("Selected command is not bindable");
            elsif Editor.Keybindings.Binding_Count_For_Command
              (Editor.Keybinding_Management.Selected_Command) = 0
            then
               return Editor.Commands.Unavailable ("No user binding to remove");
            end if;
            return Editor.Commands.Available;

         when Command_Keybindings_Reset_To_Defaults =>
            if Editor.Keybinding_Management.Current_Capture_State
              /= Editor.Keybinding_Management.Capture_Inactive
            then
               return Editor.Commands.Unavailable
                 ("Command unavailable while confirmation is pending");
            end if;
            return Editor.Commands.Available;

         when others =>
            return Editor.Commands.Unavailable
              ("Command is not a configuration command");
      end case;
   end Configuration_Command_Availability;

   function Result_After_Command
     (S               : Editor.State.State_Type;
      Command         : Editor.Commands.Command_Id;
      Before_Messages : Natural)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Found : Boolean := False;
      Msg   : Editor.Messages.Editor_Message;
   begin
      if Editor.Messages.Count (S.Messages) > Before_Messages then
         Msg := Editor.Messages.Active_Message (S.Messages, Found);
         if Found then
            if Editor.Messages.Severity (Msg) =
              Editor.Messages.Error_Message
            then
               return Editor.Command_Execution.Failed (Command);
            elsif Editor.Messages.Severity (Msg) =
              Editor.Messages.Warning_Message
            then
               return Editor.Command_Execution.Unavailable (Command);
            end if;
         end if;
      end if;

      return Editor.Command_Execution.Executed (Command);
   end Result_After_Command;

   function Reject_Configuration_Domain_Mutation_If_Reset_All_Pending
     (S : in out Editor.State.State_Type) return Boolean
   is
   begin
      if Editor.Configuration_Recovery.Has_Pending_Reset_All_Confirmation then
         Report_Error
           (S, "Command unavailable while confirmation is pending.");
         return True;
      end if;
      return False;
   end Reject_Configuration_Domain_Mutation_If_Reset_All_Pending;


   procedure Report_Recovery_Status
     (S      : in out Editor.State.State_Type;
      Status : Editor.Configuration_Recovery.Domain_Recovery_Status;
      Success_When_Clean : Boolean := True)
   is
      Message : constant String := To_String (Status.User_Action_Suggestion);
      Summary : Editor.Configuration_Recovery.Configuration_Recovery_Summary :=
        (others => <>);
   begin
      Editor.Configuration_Recovery.Append_Domain_Local_Status (Summary, Status);
      Editor.Configuration_Recovery.Record_Recovery_Summary (Summary);

      if Status.Error_Count > 0 then
         Report_Error (S, Message);
      elsif Status.Warning_Count > 0 then
         Report_Warning (S, Message);
      elsif Success_When_Clean then
         Report_Success (S, Message);
      else
         Report_Info (S, Message);
      end if;
   end Report_Recovery_Status;


   procedure Execute_Startup_Show_Summary
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Startup_Readiness.Has_Recorded_Startup_Summary then
         Report_Info
           (S, Editor.Startup_Readiness.Startup_Command_Message
             (Editor.Startup_Readiness.Current_Startup_Summary));
      else
         Report_Info (S, "No startup summary available.");
      end if;
   end Execute_Startup_Show_Summary;

   procedure Execute_Configuration_Recover_Show
     (S : in out Editor.State.State_Type)
   is
      Summary : Editor.Configuration_Recovery.Configuration_Recovery_Summary :=
        (others => <>);
      Surface : Editor.Configuration_Recovery.Configuration_Recovery_Surface_Snapshot;
   begin
      if Editor.Configuration_Recovery.Has_Recorded_Recovery_Summary then
         Summary := Editor.Configuration_Recovery.Current_Recovery_Summary;
      elsif Editor.Startup_Readiness.Has_Recorded_Startup_Summary then
         Summary := Editor.Startup_Readiness.Configuration_Recovery_View
           (Editor.Startup_Readiness.Current_Startup_Summary);
         Editor.Configuration_Recovery.Record_Recovery_Summary (Summary);
      else
         Editor.Configuration_Recovery.Append
           (Summary, Editor.Configuration_Recovery.Status_From_Settings
             (Editor.Settings.Settings_Ok));
         Editor.Configuration_Recovery.Append
           (Summary, Editor.Configuration_Recovery.Status_From_Keybindings
             (Editor.Keybinding_Config.Keybinding_Config_Ok));
         Editor.Configuration_Recovery.Append
           (Summary, Editor.Configuration_Recovery.Status_From_Workspace
             (Editor.Workspace_Persistence.Workspace_Persistence_Ok));
         Editor.Configuration_Recovery.Append
           (Summary, Editor.Configuration_Recovery.Status_From_Recent_Projects
             (Editor.Recent_Projects.Recent_Project_Ok));
      end if;
      Surface := Editor.Configuration_Recovery.Build_Surface_Snapshot (Summary);
      pragma Unreferenced (Surface);
      Report_Info (S, Editor.Configuration_Recovery.Summary_Label (Summary));
   end Execute_Configuration_Recover_Show;

   procedure Execute_Configuration_Audit
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Configuration_Recovery.Assert_Configuration_Recovery_Coherent then
         Report_Success (S, "Configuration audit clean");
      else
         Report_Warning (S, "Configuration audit found recovery issues");
      end if;
   end Execute_Configuration_Audit;

   procedure Execute_Configuration_Reset_Settings
     (S : in out Editor.State.State_Type)
   is
      Status : Editor.Configuration_Recovery.Domain_Recovery_Status;
   begin
      if Reject_Configuration_Domain_Mutation_If_Reset_All_Pending (S) then
         return;
      end if;

      Editor.Configuration_Recovery.Reset_Settings_Domain (S.Settings, Status);
      Editor.State.Apply_Settings (S, S.Settings);
      Report_Recovery_Status (S, Status);
   end Execute_Configuration_Reset_Settings;

   procedure Execute_Configuration_Reset_Keybindings
     (S : in out Editor.State.State_Type)
   is
      Action_Status   : Editor.Keybinding_Management.Keybinding_Action_Status;
      Recovery_Status : Editor.Configuration_Recovery.Domain_Recovery_Status;
      Summary         : Editor.Configuration_Recovery.Configuration_Recovery_Summary :=
        (others => <>);
   begin
      if Reject_Configuration_Domain_Mutation_If_Reset_All_Pending (S) then
         return;
      end if;

      Editor.Keybinding_Management.Reset_To_Defaults (Action_Status);
      if Action_Status = Editor.Keybinding_Management.Keybinding_Action_Ok then
         Recovery_Status := Editor.Configuration_Recovery.Status_From_Keybindings
           (Editor.Keybinding_Config.Keybinding_Config_Not_Found);
         Recovery_Status.User_Action_Suggestion :=
           To_Unbounded_String ("Keybindings reset to defaults.");
         Editor.Configuration_Recovery.Append_Domain_Local_Status (Summary, Recovery_Status);
         Editor.Configuration_Recovery.Record_Recovery_Summary (Summary);
         Report_Success (S, "Keybindings reset to defaults.");
      else
         Report_Error (S, Editor.Keybinding_Management.Action_Status_Label (Action_Status));
      end if;
   end Execute_Configuration_Reset_Keybindings;

   procedure Execute_Configuration_Reset_Workspace
     (S : in out Editor.State.State_Type)
   is
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Configuration_Recovery.Domain_Recovery_Status;
      Path     : Unbounded_String := Null_Unbounded_String;
   begin
      if Reject_Configuration_Domain_Mutation_If_Reset_All_Pending (S) then
         return;
      end if;

      Editor.Configuration_Recovery.Reset_Workspace_Domain (Snapshot, Status);
      if Editor.Project.Has_Project (S.Project) then
         Path := To_Unbounded_String
           (Editor.Workspace_Persistence.Session_File_Path
              (Editor.Project.Root_Path (S.Project)));
         if Ada.Directories.Exists (To_String (Path)) then
            begin
               Ada.Directories.Delete_File (To_String (Path));
            exception
               when others =>
                  Status.Error_Count := Status.Error_Count + 1;
                  Status.User_Action_Suggestion :=
                    To_Unbounded_String ("Workspace state clear failed.");
            end;
         end if;
      end if;
      Report_Recovery_Status (S, Status);
   end Execute_Configuration_Reset_Workspace;

   procedure Execute_Configuration_Reset_Recent_Projects
     (S : in out Editor.State.State_Type)
   is
      Status : Editor.Configuration_Recovery.Domain_Recovery_Status;
   begin
      if Reject_Configuration_Domain_Mutation_If_Reset_All_Pending (S) then
         return;
      end if;

      Editor.Configuration_Recovery.Reset_Recent_Projects_Domain
        (S.Recent_Projects, Status);
      S.Recent_Project_Selected_Index := 0;
      Report_Recovery_Status (S, Status);
   end Execute_Configuration_Reset_Recent_Projects;

   procedure Execute_Configuration_Reset_All
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Configuration_Recovery.Request_Reset_All_Confirmation;
      Report_Warning
        (S, "Reset all configuration requested. Run configuration.reset-all.confirm to confirm or configuration.reset-all.cancel to cancel; project files and dirty buffers will not be changed.");
   end Execute_Configuration_Reset_All;

   procedure Execute_Configuration_Reset_All_Confirm
     (S : in out Editor.State.State_Type)
   is
      Key_Status : Editor.Keybinding_Management.Keybinding_Action_Status;
      Summary    : Editor.Configuration_Recovery.Configuration_Recovery_Summary :=
        (others => <>);
      Row        : Editor.Configuration_Recovery.Domain_Recovery_Status;
   begin
      if not Editor.Configuration_Recovery.Has_Pending_Reset_All_Confirmation then
         Report_Info (S, "No pending reset-all confirmation.");
         return;
      end if;

      Editor.Configuration_Recovery.Clear_Reset_All_Confirmation;
      Editor.Settings.Set_Defaults (S.Settings);
      Editor.State.Apply_Settings (S, S.Settings);
      Row := Editor.Configuration_Recovery.Status_From_Settings
        (Editor.Settings.Settings_Not_Found);
      Row.User_Action_Suggestion := To_Unbounded_String ("Settings reset to defaults.");
      Editor.Configuration_Recovery.Append (Summary, Row);

      Editor.Keybinding_Management.Reset_To_Defaults (Key_Status);
      if Key_Status = Editor.Keybinding_Management.Keybinding_Action_Ok then
         Row := Editor.Configuration_Recovery.Status_From_Keybindings
           (Editor.Keybinding_Config.Keybinding_Config_Not_Found);
         Row.User_Action_Suggestion := To_Unbounded_String ("Keybindings reset to defaults.");
      else
         Row := Editor.Configuration_Recovery.Status_From_Keybindings
           (Editor.Keybinding_Config.Keybinding_Config_Write_Error);
         Row.User_Action_Suggestion := To_Unbounded_String
           ("Keybindings reset failed during reset-all confirmation; keybinding runtime state was left unchanged.");
      end if;
      Editor.Configuration_Recovery.Append (Summary, Row);

      if Editor.Project.Has_Project (S.Project) then
         declare
            Path : constant String :=
              Editor.Workspace_Persistence.Session_File_Path
                (Editor.Project.Root_Path (S.Project));
         begin
            if Ada.Directories.Exists (Path) then
               begin
                  Ada.Directories.Delete_File (Path);
               exception
                  when others =>
                     Row := Editor.Configuration_Recovery.Status_From_Workspace
                       (Editor.Workspace_Persistence.Workspace_Persistence_Write_Error);
                     Row.User_Action_Suggestion := To_Unbounded_String
                       ("Workspace state clear failed during reset-all confirmation.");
                     Editor.Configuration_Recovery.Append (Summary, Row);
                     Editor.Configuration_Recovery.Record_Recovery_Summary (Summary);
                     Report_Error (S, "Reset all configuration partially failed while clearing workspace state.");
                     return;
               end;
            end if;
         end;
      end if;

      Row := Editor.Configuration_Recovery.Status_From_Workspace
        (Editor.Workspace_Persistence.Workspace_Persistence_Not_Found);
      Row.User_Action_Suggestion := To_Unbounded_String ("Workspace cleared.");
      Editor.Configuration_Recovery.Append (Summary, Row);

      Editor.Recent_Projects.Clear (S.Recent_Projects);
      S.Recent_Project_Selected_Index := 0;
      Row := Editor.Configuration_Recovery.Status_From_Recent_Projects
        (Editor.Recent_Projects.Recent_Project_Not_Found);
      Row.User_Action_Suggestion := To_Unbounded_String ("Recent Projects cleared.");
      Editor.Configuration_Recovery.Append (Summary, Row);
      Editor.Configuration_Recovery.Record_Recovery_Summary (Summary);

      if Key_Status = Editor.Keybinding_Management.Keybinding_Action_Ok then
         Report_Success
           (S, "All configuration domains reset after explicit confirmation.");
      else
         Report_Error (S, Editor.Keybinding_Management.Action_Status_Label (Key_Status));
      end if;
   end Execute_Configuration_Reset_All_Confirm;

   procedure Execute_Configuration_Reset_All_Cancel
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Configuration_Recovery.Has_Pending_Reset_All_Confirmation then
         Editor.Configuration_Recovery.Clear_Reset_All_Confirmation;
         Report_Info (S, "Reset all configuration cancelled.");
      else
         Report_Info (S, "No pending reset-all confirmation.");
      end if;
   end Execute_Configuration_Reset_All_Cancel;

   procedure Execute_Configuration_Save_Clean_Settings
     (S : in out Editor.State.State_Type)
   is
      Status : Editor.Configuration_Recovery.Domain_Recovery_Status;
   begin
      if Reject_Configuration_Domain_Mutation_If_Reset_All_Pending (S) then
         return;
      end if;

      Editor.Configuration_Recovery.Save_Clean_Settings
        (S.Settings, Editor.Settings.Settings_File_Path, Status);
      Report_Recovery_Status (S, Status);
   end Execute_Configuration_Save_Clean_Settings;

   procedure Execute_Configuration_Save_Clean_Keybindings
     (S : in out Editor.State.State_Type)
   is
      Config : Editor.Keybinding_Config.Keybinding_Config_Model;
      Status : Editor.Configuration_Recovery.Domain_Recovery_Status;
   begin
      if Reject_Configuration_Domain_Mutation_If_Reset_All_Pending (S) then
         return;
      end if;

      Editor.Keybinding_Config.Build_From_Runtime (Config);
      Editor.Configuration_Recovery.Save_Clean_Keybindings
        (Config, Editor.Keybinding_Config.Keybindings_File_Path, Status);
      Report_Recovery_Status (S, Status);
   end Execute_Configuration_Save_Clean_Keybindings;

   procedure Execute_Configuration_Save_Clean_Workspace
     (S : in out Editor.State.State_Type)
   is
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Configuration_Recovery.Domain_Recovery_Status;
   begin
      if Reject_Configuration_Domain_Mutation_If_Reset_All_Pending (S) then
         return;
      end if;

      if not Editor.Project.Has_Project (S.Project) then
         Report_Info (S, "No project open");
         return;
      end if;
      Snapshot := Editor.State.Build_Workspace_Snapshot (S);
      Editor.Configuration_Recovery.Save_Clean_Workspace
        (Snapshot,
         Editor.Workspace_Persistence.Session_File_Path
           (Editor.Project.Root_Path (S.Project)),
         Status);
      Report_Recovery_Status (S, Status);
   end Execute_Configuration_Save_Clean_Workspace;

   procedure Execute_Configuration_Save_Clean_Recent_Projects
     (S : in out Editor.State.State_Type)
   is
      Status : Editor.Configuration_Recovery.Domain_Recovery_Status;
   begin
      if Reject_Configuration_Domain_Mutation_If_Reset_All_Pending (S) then
         return;
      end if;

      Editor.Configuration_Recovery.Save_Clean_Recent_Projects
        (S.Recent_Projects, Editor.Recent_Projects.Recent_Projects_File_Path, Status);
      Report_Recovery_Status (S, Status);
   end Execute_Configuration_Save_Clean_Recent_Projects;

   procedure Execute_Save_Settings
     (S : in out Editor.State.State_Type)
   is
      Snapshot : Editor.Settings.Settings_Model := Editor.Settings.Build_From_Current;
      Summary  : Editor.Settings_Management.Settings_Persistence_Summary;
   begin
      if Editor.Settings_Management.Has_Pending_Reset_All
        (Editor.Settings_Management.Current_Settings_Editor_State)
      then
         Report_Error (S, "Command unavailable while confirmation is pending.");
         return;
      end if;

      Editor.Settings.Normalize (Snapshot);
      Editor.Settings_Management.Save_User_Config
        (Snapshot, Editor.Settings.Settings_File_Path, Summary);

      if Summary.Status = Editor.Settings.Settings_Ok then
         S.Settings := Snapshot;
         Report_Success
           (S, Editor.Settings_Management.Persistence_Summary_Message
             ("save", Summary));
      else
         Report_Error
           (S, Editor.Settings_Management.Persistence_Summary_Message
             ("save", Summary));
      end if;
   end Execute_Save_Settings;

   procedure Execute_Reload_Settings
     (S : in out Editor.State.State_Type)
   is
      Loaded  : Editor.Settings.Settings_Model;
      Summary : Editor.Settings_Management.Settings_Persistence_Summary;
   begin
      if Editor.Settings_Management.Has_Pending_Reset_All
        (Editor.Settings_Management.Current_Settings_Editor_State)
      then
         Report_Error (S, "Command unavailable while confirmation is pending.");
         return;
      end if;

      Editor.Settings_Management.Load_User_Config
        (Editor.Settings.Settings_File_Path, Loaded, Summary);

      case Summary.Status is
         when Editor.Settings.Settings_Ok =>
            Editor.State.Apply_Settings (S, Loaded);
            Report_Success
              (S, Editor.Settings_Management.Persistence_Summary_Message
                ("load", Summary));
         when Editor.Settings.Settings_Partial_Load =>
            Editor.State.Apply_Settings (S, Loaded);
            Report_Warning
              (S, Editor.Settings_Management.Persistence_Summary_Message
                ("load", Summary));
         when Editor.Settings.Settings_Not_Found =>
            Editor.Settings.Set_Defaults (Loaded);
            Editor.State.Apply_Settings (S, Loaded);
            Report_Info (S, "Settings file unavailable.");
         when Editor.Settings.Settings_Invalid_Format =>
            Report_Error (S, "Settings file is invalid.");
         when Editor.Settings.Settings_Unsupported_Version =>
            Report_Error (S, "Settings version is unsupported.");
         when others =>
            Report_Error
              (S, Editor.Settings_Management.Persistence_Summary_Message
                ("load", Summary));
      end case;
   end Execute_Reload_Settings;

   procedure Execute_Reset_Settings_To_Defaults
     (S : in out Editor.State.State_Type)
   is
      UI     : Editor.Settings_Management.Settings_Editor_State :=
        Editor.Settings_Management.Current_Settings_Editor_State;
      Status : Editor.Settings_Management.Setting_Update_Status;
   begin
      if Editor.Settings_Management.Has_Pending_Reset_All (UI) then
         Editor.Settings_Management.Confirm_Reset_All_Settings
           (S.Settings, UI, Status);
         Editor.Settings_Management.Set_Current_Settings_Editor_State (UI);
         if Status = Editor.Settings_Management.Setting_Update_Ok then
            Editor.State.Apply_Settings (S, S.Settings);
            Report_Success (S, "Settings reset to defaults.");
         else
            Report_Error
              (S, Editor.Settings_Management.Setting_Outcome_Message
                ("all settings", Status));
         end if;
      else
         Editor.Settings_Management.Request_Reset_All_Settings (UI);
         Editor.Settings_Management.Set_Current_Settings_Editor_State (UI);
         Report_Warning
           (S, "Reset all settings requested. Invoke reset settings again to confirm; keybindings, workspace, recent projects, and buffers will not be changed.");
      end if;
   end Execute_Reset_Settings_To_Defaults;


   procedure Execute_Save_Keybindings
     (S : in out Editor.State.State_Type)
   is
      Status : Editor.Keybinding_Management.Keybinding_Action_Status;
      Validation : constant Editor.Keybindings.Keybinding_Validation_Result :=
        Editor.Keybindings.Validate;
   begin
      if Editor.Keybinding_Management.Has_Pending_Reset
        or else Editor.Keybinding_Management.Current_Capture_State
          /= Editor.Keybinding_Management.Capture_Inactive
      then
         Report_Error
           (S, "Command unavailable while confirmation is pending");
         return;
      end if;

      if Editor.Keybindings.Status (Validation) /= Editor.Keybindings.Valid_Keybindings then
         Report_Error (S, "Save keybindings failed");
         return;
      end if;

      Editor.Keybinding_Management.Save
        (Editor.Keybinding_Config.Keybindings_File_Path, Status);

      if Status = Editor.Keybinding_Management.Keybinding_Action_Ok then
         Report_Success (S, Editor.Keybinding_Management.Latest_Message);
      else
         Report_Error (S, Editor.Keybinding_Management.Action_Status_Label (Status));
      end if;
   end Execute_Save_Keybindings;

   procedure Execute_Reload_Keybindings
     (S : in out Editor.State.State_Type)
   is
      Status : Editor.Keybinding_Management.Keybinding_Action_Status;
   begin
      Editor.Keybinding_Management.Load
        (Editor.Keybinding_Config.Keybindings_File_Path, Status);

      if Status = Editor.Keybinding_Management.Keybinding_Action_Ok then
         if Editor.Keybinding_Config.Last_Load_Ignored_Count > 0 then
            Report_Warning (S, Editor.Keybinding_Management.Latest_Message);
         else
            Report_Success (S, Editor.Keybinding_Management.Latest_Message);
         end if;
      else
         Report_Error (S, Editor.Keybinding_Management.Latest_Message);
      end if;
   end Execute_Reload_Keybindings;

   procedure Execute_Validate_Keybindings
     (S : in out Editor.State.State_Type)
   is
      Result : constant Editor.Keybindings.Keybinding_Validation_Result :=
        Editor.Keybindings.Validate;
   begin
      if Editor.Keybindings.Status (Result) = Editor.Keybindings.Valid_Keybindings then
         Report_Success (S, "Keybindings valid");
      else
         Report_Warning (S, "Keybindings have conflicts");
      end if;
   end Execute_Validate_Keybindings;

   procedure Execute_Keybinding_UI_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
   is
   begin
      case Id is
         when Command_Keybindings_Show =>
            Editor.Keybinding_Management.Show;
            Report_Info (S, "Keybindings shown");

         when Command_Keybindings_Focus =>
            Editor.Keybinding_Management.Focus;
            Report_Info (S, "Keybindings focused");

         when Command_Keybindings_Assign_Selected =>
            declare
               Status : Editor.Keybinding_Management.Keybinding_Action_Status;
            begin
               Editor.Keybinding_Management.Begin_Assign_Selected (Status);
               if Status = Editor.Keybinding_Management.Keybinding_Action_Ok then
                  Report_Info (S, "Keybinding capture started");
               else
                  Report_Info
                    (S, Editor.Keybinding_Management.Action_Status_Label (Status));
               end if;
            end;

         when Command_Keybindings_Remove_Selected =>
            declare
               Status : Editor.Keybinding_Management.Keybinding_Action_Status;
            begin
               Editor.Keybinding_Management.Remove_Selected (Status);
               if Status = Editor.Keybinding_Management.Keybinding_Action_Ok then
                  Report_Success (S, "Keybinding removed");
               else
                  Report_Info
                    (S, Editor.Keybinding_Management.Action_Status_Label (Status));
               end if;
            end;

         when Command_Keybindings_Reset_To_Defaults =>
            declare
               Status : Editor.Keybinding_Management.Keybinding_Action_Status;
            begin
               if Editor.Keybinding_Management.Current_Capture_State
                 /= Editor.Keybinding_Management.Capture_Inactive
               then
                  Report_Info
                    (S, "Command unavailable while confirmation is pending");
               elsif Editor.Keybinding_Management.Has_Pending_Reset then
                  Editor.Keybinding_Management.Confirm_Reset_To_Defaults (Status);
                  if Status = Editor.Keybinding_Management.Keybinding_Action_Ok then
                     Report_Success (S, "Keybindings reset to defaults");
                  else
                     Report_Info
                       (S, Editor.Keybinding_Management.Action_Status_Label (Status));
                  end if;
               else
                  Editor.Keybinding_Management.Request_Reset_To_Defaults (Status);
                  Report_Info
                    (S, Editor.Keybinding_Management.Action_Status_Label (Status));
               end if;
            end;

         when Command_Keybindings_Filter_Conflicts =>
            Editor.Keybinding_Management.Set_Filter
              (Editor.Keybinding_Management.Filter_Conflicts);
            Report_Info (S, "Keybinding conflicts shown");

         when Command_Keybindings_Filter_Unbound =>
            Editor.Keybinding_Management.Set_Filter
              (Editor.Keybinding_Management.Filter_Unbound);
            Report_Info (S, "Unbound commands shown");

         when Command_Keybindings_Clear_Filter =>
            Editor.Keybinding_Management.Clear_Filter;
            Editor.Keybinding_Management.Clear_Query;
            Report_Info (S, "Keybinding filter cleared");

         when Command_Keybindings_Cancel_Capture =>
            declare
               Status : Editor.Keybinding_Management.Keybinding_Action_Status;
            begin
               if Editor.Keybinding_Management.Has_Pending_Reset then
                  Editor.Keybinding_Management.Cancel_Reset_To_Defaults (Status);
               else
                  Editor.Keybinding_Management.Cancel_Capture (Status);
               end if;
               Report_Info
                 (S, Editor.Keybinding_Management.Action_Status_Label (Status));
            end;

         when others =>
            raise Program_Error with "unsupported keybinding command id";
      end case;
   end Execute_Keybinding_UI_Command;

   function Execute_Configuration_Result_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Before_Messages : constant Natural := Editor.Messages.Count (S.Messages);
   begin
      case Id is
         when Command_Save_Settings
            | Command_Reload_Settings
            | Command_Reset_Settings_To_Defaults
            | Command_Save_Keybindings
            | Command_Reload_Keybindings
            | Command_Validate_Keybindings
            | Command_Startup_Show_Summary
            | Command_Configuration_Recover_Show
            | Command_Configuration_Audit
            | Command_Configuration_Reset_Settings
            | Command_Configuration_Reset_Keybindings
            | Command_Configuration_Reset_Workspace
            | Command_Configuration_Reset_Recent_Projects
            | Command_Configuration_Reset_All
            | Command_Configuration_Reset_All_Confirm
            | Command_Configuration_Reset_All_Cancel
            | Command_Configuration_Save_Clean_Settings
            | Command_Configuration_Save_Clean_Keybindings
            | Command_Configuration_Save_Clean_Workspace
            | Command_Configuration_Save_Clean_Recent_Projects =>
            Execute_Configuration_Kind (S, Editor.Commands.Command_For_Id (Id).Kind);

         when Command_Keybindings_Show
            .. Command_Keybindings_Cancel_Capture =>
            Execute_Keybinding_UI_Command (S, Id);

         when others =>
            raise Program_Error with "unsupported configuration result command";
      end case;

      Editor.Render_Cache.Invalidate_All;
      return Result_After_Command (S, Id, Before_Messages);
   end Execute_Configuration_Result_Command;

   procedure Execute_Configuration_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind)
   is
   begin
      case Kind is
         when Save_Settings =>
            Execute_Save_Settings (S);

         when Reload_Settings =>
            Execute_Reload_Settings (S);

         when Reset_Settings_To_Defaults =>
            Execute_Reset_Settings_To_Defaults (S);

         when Save_Keybindings =>
            Execute_Save_Keybindings (S);

         when Reload_Keybindings =>
            Execute_Reload_Keybindings (S);

         when Validate_Keybindings =>
            Execute_Validate_Keybindings (S);

         when Keybindings_Show =>
            Execute_Keybinding_UI_Command (S, Command_Keybindings_Show);

         when Keybindings_Focus =>
            Execute_Keybinding_UI_Command (S, Command_Keybindings_Focus);

         when Keybindings_Assign_Selected =>
            Execute_Keybinding_UI_Command
              (S, Command_Keybindings_Assign_Selected);

         when Keybindings_Remove_Selected =>
            Execute_Keybinding_UI_Command
              (S, Command_Keybindings_Remove_Selected);

         when Keybindings_Reset_To_Defaults =>
            Execute_Keybinding_UI_Command
              (S, Command_Keybindings_Reset_To_Defaults);

         when Keybindings_Filter_Conflicts =>
            Execute_Keybinding_UI_Command
              (S, Command_Keybindings_Filter_Conflicts);

         when Keybindings_Filter_Unbound =>
            Execute_Keybinding_UI_Command
              (S, Command_Keybindings_Filter_Unbound);

         when Keybindings_Clear_Filter =>
            Execute_Keybinding_UI_Command
              (S, Command_Keybindings_Clear_Filter);

         when Keybindings_Cancel_Capture =>
            Execute_Keybinding_UI_Command
              (S, Command_Keybindings_Cancel_Capture);

         when Startup_Show_Summary =>
            Execute_Startup_Show_Summary (S);

         when Configuration_Recover_Show =>
            Execute_Configuration_Recover_Show (S);

         when Configuration_Audit =>
            Execute_Configuration_Audit (S);

         when Configuration_Reset_Settings =>
            Execute_Configuration_Reset_Settings (S);

         when Configuration_Reset_Keybindings =>
            Execute_Configuration_Reset_Keybindings (S);

         when Configuration_Reset_Workspace =>
            Execute_Configuration_Reset_Workspace (S);

         when Configuration_Reset_Recent_Projects =>
            Execute_Configuration_Reset_Recent_Projects (S);

         when Configuration_Reset_All =>
            Execute_Configuration_Reset_All (S);

         when Configuration_Reset_All_Confirm =>
            Execute_Configuration_Reset_All_Confirm (S);

         when Configuration_Reset_All_Cancel =>
            Execute_Configuration_Reset_All_Cancel (S);

         when Configuration_Save_Clean_Settings =>
            Execute_Configuration_Save_Clean_Settings (S);

         when Configuration_Save_Clean_Keybindings =>
            Execute_Configuration_Save_Clean_Keybindings (S);

         when Configuration_Save_Clean_Workspace =>
            Execute_Configuration_Save_Clean_Workspace (S);

         when Configuration_Save_Clean_Recent_Projects =>
            Execute_Configuration_Save_Clean_Recent_Projects (S);

         when others =>
            raise Program_Error with "unsupported configuration command kind";
      end case;
   end Execute_Configuration_Kind;

end Editor.Executor.Configuration_Commands;
