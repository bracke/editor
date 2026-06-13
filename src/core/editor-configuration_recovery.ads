with Ada.Strings.Unbounded;
with Editor.Keybinding_Config;
with Editor.Recent_Projects;
with Editor.Settings;
with Editor.Workspace_Persistence;

package Editor.Configuration_Recovery is

   type Configuration_Domain is
     (Settings_Domain,
      Keybindings_Domain,
      Workspace_Domain,
      Recent_Projects_Domain,
      Command_Routes_Domain,
      Runtime_Defaults_Domain);

   type Domain_Load_Status is
     (Domain_Ok,
      Domain_Missing,
      Domain_Unreadable,
      Domain_Malformed,
      Domain_Loaded_With_Warnings,
      Domain_Loaded_With_Defaults,
      Domain_Partially_Loaded,
      Domain_Ignored_Unsupported_Fields,
      Domain_Reset_Required,
      Domain_Reset_Available);

   type Recovery_Action is
     (No_Recovery_Action,
      Use_Safe_Defaults,
      Keep_Valid_Entries,
      Ignore_Invalid_Entries,
      Ignore_Unsupported_Fields,
      Clear_Structural_State,
      Clear_Recent_Project_List,
      Reset_Domain_Available,
      Save_Clean_Available,
      Explicit_Reset_All_Required);


   type Recovery_Command_Action is
     (Recovery_Action_Show,
      Recovery_Action_Audit,
      Recovery_Action_Reset_Settings,
      Recovery_Action_Reset_Keybindings,
      Recovery_Action_Reset_Workspace,
      Recovery_Action_Reset_Recent_Projects,
      Recovery_Action_Reset_All,
      Recovery_Action_Confirm_Reset_All,
      Recovery_Action_Cancel_Reset_All,
      Recovery_Action_Save_Clean_Settings,
      Recovery_Action_Save_Clean_Keybindings,
      Recovery_Action_Save_Clean_Workspace,
      Recovery_Action_Save_Clean_Recent_Projects);

   type Recovery_Command_Availability is record
      Available : Boolean := True;
      Reason    : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   type Recovery_Command_Row is record
      Stable_Name           : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Display_Name          : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Action                : Recovery_Command_Action := Recovery_Action_Show;
      Domain                : Configuration_Domain := Settings_Domain;
      Domain_Specific       : Boolean := True;
      Requires_Confirmation : Boolean := False;
      Confirmation_Action   : Boolean := False;
      Save_Clean_Action     : Boolean := False;
      Reset_Action          : Boolean := False;
      No_Payload            : Boolean := True;
      Mutates_Only_Domain   : Boolean := True;
   end record;

   Max_Recovery_Command_Rows : constant Natural := 13;

   type Recovery_Command_Row_Array is
     array (Positive range 1 .. Max_Recovery_Command_Rows) of Recovery_Command_Row;

   type Recovery_Command_Catalog is record
      Row_Count              : Natural := 0;
      Reset_Count            : Natural := 0;
      Save_Clean_Count       : Natural := 0;
      Confirmation_Count     : Natural := 0;
      Payload_Command_Count  : Natural := 0;
      Cross_Domain_Command_Count : Natural := 0;
      Rows                   : Recovery_Command_Row_Array := (others => <>);
   end record;

   type Domain_Recovery_Status is record
      Domain                  : Configuration_Domain := Settings_Domain;
      Load_Status             : Domain_Load_Status := Domain_Ok;
      Validation_Status       : Domain_Load_Status := Domain_Ok;
      Action                  : Recovery_Action := No_Recovery_Action;
      Ignored_Field_Count     : Natural := 0;
      Invalid_Entry_Count     : Natural := 0;
      Defaulted_Value_Count   : Natural := 0;
      Rejected_Entry_Count    : Natural := 0;
      Warning_Count           : Natural := 0;
      Error_Count             : Natural := 0;
      Missing_File            : Boolean := False;
      Unreadable_File         : Boolean := False;
      Malformed_File          : Boolean := False;
      Safe_Defaults_Active    : Boolean := False;
      User_Action_Suggestion  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   Max_Recovery_Domains : constant Natural := 6;
   Max_Recovery_Message_Length : constant Natural := 160;

   type Domain_Recovery_Status_Array is
     array (Positive range 1 .. Max_Recovery_Domains) of Domain_Recovery_Status;

   type Configuration_Recovery_Summary is record
      Domain_Count                : Natural := 0;
      Warning_Count               : Natural := 0;
      Error_Count                 : Natural := 0;
      Domains_With_Defaults_Count : Natural := 0;
      Domains_With_Issues_Count   : Natural := 0;
      Bounded                     : Boolean := True;
      Rows                        : Domain_Recovery_Status_Array := (others => <>);
   end record;

   type Configuration_Recovery_Row_Snapshot is record
      Domain_Label      : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Status_Label      : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Action_Label      : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Warning_Count     : Natural := 0;
      Error_Count       : Natural := 0;
      Ignored_Field_Count   : Natural := 0;
      Invalid_Entry_Count   : Natural := 0;
      Defaulted_Value_Count : Natural := 0;
      Rejected_Entry_Count  : Natural := 0;
      Missing_File          : Boolean := False;
      Unreadable_File       : Boolean := False;
      Malformed_File        : Boolean := False;
      Safe_Defaults_Active  : Boolean := False;
      Action_Suggestion : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Selected          : Boolean := False;
   end record;

   type Configuration_Recovery_Row_Array is
     array (Positive range 1 .. Max_Recovery_Domains) of Configuration_Recovery_Row_Snapshot;

   type Configuration_Recovery_Surface_Snapshot is record
      Row_Count     : Natural := 0;
      Warning_Count : Natural := 0;
      Error_Count   : Natural := 0;
      Bounded       : Boolean := True;
      Summary_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Rows          : Configuration_Recovery_Row_Array := (others => <>);
   end record;

   function Domain_Label (Domain : Configuration_Domain) return String;
   function Load_Status_Label (Status : Domain_Load_Status) return String;
   function Recovery_Action_Label (Action : Recovery_Action) return String;

   function Recovery_Command_Stable_Name
     (Action : Recovery_Command_Action) return String;

   function Recovery_Command_Availability_For
     (Action                : Recovery_Command_Action;
      Summary               : Configuration_Recovery_Summary;
      Reset_All_Confirmation : Boolean := False) return Recovery_Command_Availability;

   procedure Request_Reset_All_Confirmation;
   procedure Clear_Reset_All_Confirmation;
   function Has_Pending_Reset_All_Confirmation return Boolean;

   function Build_Recovery_Command_Catalog return Recovery_Command_Catalog;

   function Status_From_Settings
     (Status : Editor.Settings.Settings_Status) return Domain_Recovery_Status;

   function Status_From_Keybindings
     (Status : Editor.Keybinding_Config.Keybinding_Config_Status) return Domain_Recovery_Status;

   function Status_From_Workspace
     (Status      : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Diagnostics : Natural := 0) return Domain_Recovery_Status;

   function Status_From_Recent_Projects
     (Status : Editor.Recent_Projects.Recent_Project_Status) return Domain_Recovery_Status;

   procedure Normalize_Recovery_Status
     (Status : in out Domain_Recovery_Status);

   function Recovery_Message_Is_Bounded
     (Status : Domain_Recovery_Status) return Boolean;

   procedure Normalize_Recovery_Summary
     (Summary : in out Configuration_Recovery_Summary);

   procedure Append
     (Summary : in out Configuration_Recovery_Summary;
      Row     : Domain_Recovery_Status);

   function Summary_Label
     (Summary : Configuration_Recovery_Summary) return String;

   function Domain_Has_Recovery_Issue
     (Row : Domain_Recovery_Status) return Boolean;

   function Build_Startup_Recovery_Summary
     (Settings_Row    : Domain_Recovery_Status;
      Keybindings_Row : Domain_Recovery_Status;
      Workspace_Row   : Domain_Recovery_Status;
      Recent_Row      : Domain_Recovery_Status) return Configuration_Recovery_Summary;

   function Build_Surface_Snapshot
     (Summary        : Configuration_Recovery_Summary;
      Selected_Index : Natural := 0) return Configuration_Recovery_Surface_Snapshot;

   procedure Record_Recovery_Summary
     (Summary : Configuration_Recovery_Summary);

   function Has_Recorded_Recovery_Summary return Boolean;

   function Current_Recovery_Summary return Configuration_Recovery_Summary;

   procedure Clear_Recorded_Recovery_Summary;

   procedure Clear_Recovery_Runtime_State;

   function Recovery_Summary_Has_Only_Clean_Domains
     (Summary : Configuration_Recovery_Summary) return Boolean;

   procedure Append_Domain_Local_Status
     (Summary : in out Configuration_Recovery_Summary;
      Status  : Domain_Recovery_Status);

   procedure Load_All_Domains_Safely
     (Settings_Path    : String;
      Keybindings_Path : String;
      Workspace_Path   : String;
      Recent_Path      : String;
      Settings         : out Editor.Settings.Settings_Model;
      Keybindings      : out Editor.Keybinding_Config.Keybinding_Config_Model;
      Workspace        : out Editor.Workspace_Persistence.Workspace_Snapshot;
      Recent           : out Editor.Recent_Projects.Recent_Project_List;
      Summary          : out Configuration_Recovery_Summary);

   procedure Reset_Settings_Domain
     (Settings : in out Editor.Settings.Settings_Model;
      Status   : out Domain_Recovery_Status);

   procedure Reset_Keybindings_Domain
     (Keybindings : in out Editor.Keybinding_Config.Keybinding_Config_Model;
      Status      : out Domain_Recovery_Status);

   procedure Reset_Workspace_Domain
     (Workspace : in out Editor.Workspace_Persistence.Workspace_Snapshot;
      Status    : out Domain_Recovery_Status);

   procedure Reset_Recent_Projects_Domain
     (Recent : in out Editor.Recent_Projects.Recent_Project_List;
      Status : out Domain_Recovery_Status);



   procedure Reset_All_Domains
     (Settings  : in out Editor.Settings.Settings_Model;
      Keybindings : in out Editor.Keybinding_Config.Keybinding_Config_Model;
      Workspace : in out Editor.Workspace_Persistence.Workspace_Snapshot;
      Recent    : in out Editor.Recent_Projects.Recent_Project_List;
      Confirmed : Boolean;
      Summary   : out Configuration_Recovery_Summary);

   procedure Save_Clean_Settings
     (Settings : Editor.Settings.Settings_Model;
      Path     : String;
      Status   : out Domain_Recovery_Status);

   procedure Save_Clean_Keybindings
     (Keybindings : Editor.Keybinding_Config.Keybinding_Config_Model;
      Path        : String;
      Status      : out Domain_Recovery_Status);

   procedure Save_Clean_Workspace
     (Workspace : Editor.Workspace_Persistence.Workspace_Snapshot;
      Path      : String;
      Status    : out Domain_Recovery_Status);

   procedure Save_Clean_Recent_Projects
     (Recent : Editor.Recent_Projects.Recent_Project_List;
      Path   : String;
      Status : out Domain_Recovery_Status);

   function Assert_Configuration_Domains_Load_Independently return Boolean;
   function Assert_Safe_Defaults_Are_Always_Available return Boolean;
   function Assert_Recovery_Commands_Do_Not_Cross_Write_Domains return Boolean;

   function Assert_Reset_All_Requires_Confirmation return Boolean;
   function Assert_Recovery_Command_Catalog_Is_Payload_Free return Boolean;
   function Assert_Load_All_Domains_Contains_Failures return Boolean;
   function Assert_Surface_Contains_Actionable_Domain_Details return Boolean;
   function Assert_Save_Clean_Status_Is_Domain_Local return Boolean;
   function Assert_Recovery_Command_Availability_Is_Domain_Local return Boolean;
   function Assert_Recovery_Summary_Overflow_Is_Bounded return Boolean;
   function Assert_Settings_Recovery_Counts_Are_Actionable return Boolean;
   function Assert_Recent_Projects_Partial_Load_Is_Preserved return Boolean;
   function Assert_Configuration_Recovery_Render_Is_Side_Effect_Free return Boolean;
   function Assert_Recovery_State_Not_Persisted return Boolean;
   function Assert_Recorded_Recovery_Summary_Is_Transient return Boolean;
   function Assert_Recovery_Runtime_State_Clear_Is_Local return Boolean;
   function Assert_Clean_Summary_Disables_Reset_And_Save_Clean return Boolean;
   function Assert_Domain_Local_Status_Record_Is_Bounded return Boolean;
   function Assert_Save_Clean_Failure_Status_Is_Exception_Contained return Boolean;
   function Assert_Recovery_Messages_Are_Bounded return Boolean;
   function Assert_Recovery_Availability_Blocks_Domain_Mutation_While_Pending return Boolean;
   function Assert_Reset_All_Keybinding_Failure_Status_Is_Not_Fabricated return Boolean;
   function Assert_Recovery_Keybindings_Have_No_Payloads return Boolean;
   function Assert_Configuration_Recovery_Coherent return Boolean;

end Editor.Configuration_Recovery;
