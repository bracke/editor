with Ada.Strings.Unbounded;
with Editor.Configuration_Recovery;
with Editor.Keybinding_Config;
with Editor.Recent_Projects;
with Editor.Settings;
with Editor.Workspace_Persistence;

package Editor.Startup_Readiness is

   type Startup_Domain_Status is
     (Startup_Ok,
      Startup_Defaulted,
      Startup_Missing_Optional_File,
      Startup_Loaded_With_Warnings,
      Startup_Partial_Restore,
      Startup_Restore_Failed,
      Startup_Unavailable,
      Startup_Not_Requested);

   type Startup_Readiness_Label is
     (Startup_Ready,
      Startup_Ready_With_Warnings,
      Startup_First_Run_Ready,
      Startup_Project_Unavailable,
      Startup_Workspace_Partial_Restore);

   type Startup_Focus_Owner is
     (Startup_Focus_Editor,
      Startup_Focus_File_Tree,
      Startup_Focus_None);

   type Startup_Domain_Row is record
      Label                : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Status               : Startup_Domain_Status := Startup_Not_Requested;
      Warning_Count        : Natural := 0;
      Error_Count          : Natural := 0;
      Invalid_Entry_Count  : Natural := 0;
      Rejected_Entry_Count : Natural := 0;
      Missing_File_Count   : Natural := 0;
      Restored_File_Count  : Natural := 0;
      Safe_Defaults_Active : Boolean := False;
   end record;

   Max_Startup_Domain_Rows : constant Natural := 7;
   Max_Startup_Label_Length : constant Natural := 160;

   type Startup_Domain_Row_Array is
     array (Positive range 1 .. Max_Startup_Domain_Rows) of Startup_Domain_Row;

   type Startup_Summary is record
      Row_Count                 : Natural := 0;
      Rows                      : Startup_Domain_Row_Array := (others => <>);
      Warning_Count             : Natural := 0;
      Error_Count               : Natural := 0;
      Invalid_Entry_Count      : Natural := 0;
      Rejected_Entry_Count     : Natural := 0;
      Missing_File_Count        : Natural := 0;
      Restored_File_Count       : Natural := 0;
      Safe_Default_Domain_Count : Natural := 0;
      First_Run                 : Boolean := False;
      Bounded                   : Boolean := True;
      Transient                 : Boolean := True;
      Readiness                 : Startup_Readiness_Label := Startup_Ready;
      Safe_Focus                : Startup_Focus_Owner := Startup_Focus_None;
      Project_Restore_Uses_Lifecycle : Boolean := True;
      File_Restore_Uses_Lifecycle    : Boolean := True;
      Project_Surfaces_Initialized   : Boolean := True;
      Pending_Confirmation_Restored  : Boolean := False;
      Recovery_View_Auto_Repairs     : Boolean := False;
      Primary_Message           : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Action_Suggestion         : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   type Startup_Run_Policy is record
      Restore_Workspace_On_Startup : Boolean := True;
   end record;

   function Status_Label (Status : Startup_Domain_Status) return String;
   function Readiness_Label (Readiness : Startup_Readiness_Label) return String;
   function Focus_Label (Focus : Startup_Focus_Owner) return String;

   function Domain_Row
     (Label                : String;
      Status               : Startup_Domain_Status;
      Warning_Count        : Natural := 0;
      Error_Count          : Natural := 0;
      Invalid_Entry_Count  : Natural := 0;
      Rejected_Entry_Count : Natural := 0;
      Missing_File_Count   : Natural := 0;
      Restored_File_Count  : Natural := 0;
      Safe_Defaults_Active : Boolean := False) return Startup_Domain_Row;

   procedure Append
     (Summary : in out Startup_Summary;
      Row     : Startup_Domain_Row);

   procedure Normalize (Summary : in out Startup_Summary);

   function Status_From_Settings
     (Status : Editor.Settings.Settings_Status) return Startup_Domain_Row;

   function Status_From_Keybindings
     (Status : Editor.Keybinding_Config.Keybinding_Config_Status) return Startup_Domain_Row;

   function Status_From_Workspace
     (Status      : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Restore_Requested : Boolean := True) return Startup_Domain_Row;

   function Status_From_Recent_Projects
     (Status : Editor.Recent_Projects.Recent_Project_Status) return Startup_Domain_Row;

   function Build_First_Run_Summary return Startup_Summary;

   function Build_Startup_Summary
     (Settings_Row       : Startup_Domain_Row;
      Keybindings_Row    : Startup_Domain_Row;
      Workspace_Row      : Startup_Domain_Row;
      Recent_Row         : Startup_Domain_Row;
      Project_Restored   : Boolean := False;
      Project_Missing    : Boolean := False;
      Files_Restored     : Natural := 0;
      Files_Missing      : Natural := 0;
      Files_Not_Attempted : Natural := 0;
      Active_Buffer_Restored : Boolean := False;
      Panel_Layout_Restored  : Boolean := False;
      Panel_Layout_Warnings  : Natural := 0) return Startup_Summary;

   procedure Startup_Run
     (Settings_Path    : String;
      Keybindings_Path : String;
      Workspace_Path   : String;
      Recent_Path      : String;
      Policy           : Startup_Run_Policy;
      Settings         : out Editor.Settings.Settings_Model;
      Keybindings      : out Editor.Keybinding_Config.Keybinding_Config_Model;
      Workspace        : out Editor.Workspace_Persistence.Workspace_Snapshot;
      Recent           : out Editor.Recent_Projects.Recent_Project_List;
      Summary          : out Startup_Summary);
   function Build_Observed_Startup_Summary
     (Settings_Status       : Editor.Settings.Settings_Status;
      Keybindings_Status    : Editor.Keybinding_Config.Keybinding_Config_Status;
      Workspace_Status      : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Recent_Status         : Editor.Recent_Projects.Recent_Project_Status;
      Workspace             : Editor.Workspace_Persistence.Workspace_Snapshot;
      Restore_Requested     : Boolean := True) return Startup_Summary;


   function Configuration_Recovery_View
     (Summary : Startup_Summary)
      return Editor.Configuration_Recovery.Configuration_Recovery_Summary;

   procedure Record_Startup_Summary (Summary : Startup_Summary);
   function Has_Recorded_Startup_Summary return Boolean;
   function Current_Startup_Summary return Startup_Summary;
   procedure Clear_Startup_Summary;

   function Status_Bar_Label (Summary : Startup_Summary) return String;
   function First_Run_Empty_State_Label (Summary : Startup_Summary) return String;
   function Startup_Command_Message (Summary : Startup_Summary) return String;

   function Assert_Startup_Readiness_Coherent return Boolean;
   function Assert_Startup_Summary_Is_Bounded_And_Transient return Boolean;
   function Assert_Startup_Uses_Safe_Defaults return Boolean;
   function Assert_Startup_Status_Projection_Is_Observational return Boolean;
   function Assert_Startup_State_Not_Persisted return Boolean;
   function Assert_Startup_Keybindings_Have_No_Payloads return Boolean;
   function Assert_Startup_Display_Commands_Route_Through_Executor return Boolean;
   function Assert_Startup_Routes_Restore_Through_Lifecycle return Boolean;
   function Assert_Startup_Project_Surfaces_Initialized_Cleanly return Boolean;
   function Assert_Startup_Restores_No_Pending_Confirmation return Boolean;
   function Assert_Startup_Recovery_View_Is_Bounded return Boolean;
   function Assert_Startup_Aggregate_Counts_Match_Rows return Boolean;

end Editor.Startup_Readiness;
