with Ada.Strings.Unbounded;
with Editor.Settings;
with Editor.Commands;

package Editor.Settings_Management is

   type Setting_Value_Kind is
     (Setting_Boolean,
      Setting_Enum,
      Setting_Text);

   type Setting_Category is
     (Appearance_Setting,
      Editor_Setting,
      View_Setting,
      Command_Palette_Setting);

   type Settings_Filter is
     (Filter_All_Settings,
      Filter_Modified_Settings,
      Filter_Invalid_Settings,
      Filter_Appearance_Settings,
      Filter_Editor_Settings,
      Filter_View_Settings,
      Filter_Command_Palette_Settings);

   type Setting_Update_Status is
     (Setting_Update_Ok,
      Setting_Update_Unknown,
      Setting_Update_Not_Toggleable,
      Setting_Update_Invalid_Value,
      Setting_Update_Already_Default,
      Setting_Update_No_Selection,
      Setting_Update_Confirmation_Required,
      Setting_Update_Confirmation_Cancelled,
      Setting_Update_Blocked_By_Confirmation);

   type Settings_File_Audit is record
      Load_Status              : Editor.Settings.Settings_Status := Editor.Settings.Settings_Ok;
      Supported_Field_Count    : Natural := 0;
      Unknown_Field_Count      : Natural := 0;
      Invalid_Value_Count      : Natural := 0;
      Forbidden_Domain_Count   : Natural := 0;
      Malformed_Line_Count     : Natural := 0;
   end record;


   type Settings_Persistence_Summary is record
      Status                 : Editor.Settings.Settings_Status := Editor.Settings.Settings_Ok;
      Supported_Field_Count  : Natural := 0;
      Unknown_Field_Count    : Natural := 0;
      Invalid_Value_Count    : Natural := 0;
      Forbidden_Field_Count  : Natural := 0;
      Malformed_Line_Count   : Natural := 0;
   end record;



   type Settings_Command_Surface_Audit is record
      Settings_Command_Count       : Natural := 0;
      Missing_Descriptor_Count     : Natural := 0;
      Wrong_Category_Count         : Natural := 0;
      Non_Configuration_Count      : Natural := 0;
      Payload_Capable_Count        : Natural := 0;
      Hidden_Command_Count         : Natural := 0;
   end record;

   type Domain_Separation_Audit is record
      Settings_Contains_Keybindings : Boolean := False;
      Settings_Contains_Workspace   : Boolean := False;
      Settings_Contains_Recent      : Boolean := False;
      Settings_Contains_Runtime     : Boolean := False;
      Forbidden_Field_Count         : Natural := 0;
   end record;


   type Configuration_Audit_Row is record
      Category : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Message  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Warning  : Boolean := False;
   end record;

   Max_Configuration_Audit_Rows : constant Natural := 24;

   type Configuration_Audit_Row_Array is
     array (Positive range 1 .. Max_Configuration_Audit_Rows) of Configuration_Audit_Row;

   Empty_Configuration_Audit_Row : constant Configuration_Audit_Row := (others => <>);

   type Configuration_Audit_Surface_Snapshot is record
      Row_Count       : Natural := 0;
      Warning_Count   : Natural := 0;
      Display_Count   : Natural := 0;
      Bounded         : Boolean := False;
      Summary         : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Rows            : Configuration_Audit_Row_Array :=
        (others => Empty_Configuration_Audit_Row);
   end record;

   type Setting_Row is record
      Key                 : Ada.Strings.Unbounded.Unbounded_String;
      Display_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Category_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Current_Value       : Ada.Strings.Unbounded.Unbounded_String;
      Default_Value       : Ada.Strings.Unbounded.Unbounded_String;
      Description         : Ada.Strings.Unbounded.Unbounded_String;
      Source_Label        : Ada.Strings.Unbounded.Unbounded_String;
      Validation_Message  : Ada.Strings.Unbounded.Unbounded_String;
      Kind                : Setting_Value_Kind := Setting_Text;
      Category            : Setting_Category := Editor_Setting;
      Editable            : Boolean := True;
      Toggleable          : Boolean := False;
      Modified            : Boolean := False;
      Valid               : Boolean := True;
      Selected            : Boolean := False;
   end record;


   --  Bounded render-facing projection of the settings surface.  Render code
   --  consumes this immutable snapshot instead of consulting Settings while
   --  emitting packets. Query/filter/selection are intentionally absent here
   --  because they are transient UI state and not part of settings
   --  persistence.
   Max_Settings_Surface_Rows : constant Natural := 40;

   type Setting_Row_Array is array (Positive range 1 .. Max_Settings_Surface_Rows)
     of Setting_Row;

   Empty_Setting_Row : constant Setting_Row := (others => <>);


   --  Transient settings surface controls.  This state is intentionally
   --  separate from Settings_Model and must never be written to settings,
   --  keybindings, workspace, or recent-project persistence.
   Max_Settings_Query_Length : constant Natural := 80;

   type Settings_Editor_State is record
      Visible        : Boolean := False;
      Focused        : Boolean := False;
      Selected_Index     : Natural := 0;
      Filter             : Settings_Filter := Filter_All_Settings;
      Pending_Reset_All  : Boolean := False;
      Query              : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   procedure Show_Settings (UI : in out Settings_Editor_State);
   procedure Hide_Settings (UI : in out Settings_Editor_State);
   procedure Focus_Settings (UI : in out Settings_Editor_State);
   procedure Select_Next_Setting (UI : in out Settings_Editor_State);
   procedure Select_Previous_Setting (UI : in out Settings_Editor_State);
   procedure Set_Search_Query (UI : in out Settings_Editor_State; Query : String);
   procedure Clear_Search_Query (UI : in out Settings_Editor_State);
   procedure Set_Filter (UI : in out Settings_Editor_State; Filter : Settings_Filter);
   procedure Clear_Filter (UI : in out Settings_Editor_State);
   procedure Request_Reset_All_Settings (UI : in out Settings_Editor_State);
   procedure Confirm_Reset_All_Settings
     (Settings : in out Editor.Settings.Settings_Model;
      UI       : in out Settings_Editor_State;
      Status   : out Setting_Update_Status);
   procedure Cancel_Reset_All_Settings
     (UI     : in out Settings_Editor_State;
      Status : out Setting_Update_Status);

   function Selected_Key (UI : Settings_Editor_State) return String;
   function Has_Pending_Reset_All (UI : Settings_Editor_State) return Boolean;

   --  Module-local transient surface state used by Executor/Input/Render
   --  integration. This is deliberately not part of Settings_Model and is
   --  excluded from every persistence domain.
   procedure Reset_Transient_State;
   function Current_Settings_Editor_State return Settings_Editor_State;
   procedure Set_Current_Settings_Editor_State (UI : Settings_Editor_State);
   function Current_Settings_Surface_Visible return Boolean;
   function Current_Settings_Surface_Focused return Boolean;


   type Settings_Surface_Snapshot is record
      Visible           : Boolean := False;
      Focused           : Boolean := False;
      Row_Count         : Natural := 0;
      Modified_Count    : Natural := 0;
      Invalid_Count     : Natural := 0;
      Display_Row_Count : Natural := 0;
      Pending_Reset_All : Boolean := False;
      Display_Rows      : Setting_Row_Array := (others => Empty_Setting_Row);
      Audit_Summary     : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Domain_Summary    : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Confirmation_Message : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   function Setting_Count return Natural;

   function Row_At
     (Settings : Editor.Settings.Settings_Model;
      Index    : Positive) return Setting_Row;

   function Index_For_Key (Key : String) return Natural;

   function Category_Label (Category : Setting_Category) return String;
   function Value_Kind_Label (Kind : Setting_Value_Kind) return String;
   function Update_Status_Label (Status : Setting_Update_Status) return String;
   function Setting_Outcome_Message
     (Key    : String;
      Status : Setting_Update_Status) return String;

   function Matches_Search
     (Row   : Setting_Row;
      Query : String) return Boolean;

   function Matches_Filter
     (Row    : Setting_Row;
      Filter : Settings_Filter) return Boolean;

   procedure Toggle_Setting
     (Settings : in out Editor.Settings.Settings_Model;
      Key      : String;
      Status   : out Setting_Update_Status);

   procedure Cycle_Setting
     (Settings : in out Editor.Settings.Settings_Model;
      Key      : String;
      Status   : out Setting_Update_Status);

   procedure Set_Setting_Value
     (Settings : in out Editor.Settings.Settings_Model;
      Key      : String;
      Value    : String;
      Status   : out Setting_Update_Status);

   procedure Reset_Setting
     (Settings : in out Editor.Settings.Settings_Model;
      Key      : String;
      Status   : out Setting_Update_Status);

   procedure Reset_All_Settings
     (Settings : in out Editor.Settings.Settings_Model);

   procedure Toggle_Selected_Setting
     (Settings : in out Editor.Settings.Settings_Model;
      UI       : Settings_Editor_State;
      Status   : out Setting_Update_Status);

   procedure Cycle_Selected_Setting
     (Settings : in out Editor.Settings.Settings_Model;
      UI       : Settings_Editor_State;
      Status   : out Setting_Update_Status);

   procedure Set_Selected_Setting_Value
     (Settings : in out Editor.Settings.Settings_Model;
      UI       : Settings_Editor_State;
      Value    : String;
      Status   : out Setting_Update_Status);

   procedure Reset_Selected_Setting
     (Settings : in out Editor.Settings.Settings_Model;
      UI       : Settings_Editor_State;
      Status   : out Setting_Update_Status);

   procedure Audit_Settings_File
     (Path   : String;
      Result : out Settings_File_Audit);

   procedure Save_User_Config
     (Settings : Editor.Settings.Settings_Model;
      Path     : String;
      Summary  : out Settings_Persistence_Summary);

   procedure Load_User_Config
     (Path     : String;
      Settings : out Editor.Settings.Settings_Model;
      Summary  : out Settings_Persistence_Summary);

   function Persistence_Summary_Message
     (Operation : String;
      Summary   : Settings_Persistence_Summary) return String;

   function Assert_Settings_Save_Writes_Global_Preferences_Only return Boolean;
   function Assert_Settings_Load_Does_Not_Cross_Domains return Boolean;

   procedure Audit_Settings_Command_Surface
     (Result : out Settings_Command_Surface_Audit);

   function Command_Surface_Audit_Summary
     (Result : Settings_Command_Surface_Audit) return String;

   function Build_Configuration_Audit_Surface
     (File_Audit    : Settings_File_Audit;
      Domain_Audit  : Domain_Separation_Audit;
      Command_Audit : Settings_Command_Surface_Audit)
      return Configuration_Audit_Surface_Snapshot;

   function Assert_Configuration_Audit_Surface_Is_Bounded_And_Transient return Boolean;

   function Assert_Settings_Command_Surface_Coherent return Boolean;
   function Assert_Settings_Keybindings_And_Palette_Carry_No_Payloads return Boolean;

   procedure Audit_Domain_Separation_Text
     (Text   : String;
      Result : out Domain_Separation_Audit);

   function File_Audit_Summary (Result : Settings_File_Audit) return String;
   function Domain_Audit_Summary (Result : Domain_Separation_Audit) return String;

   function Build_Surface_Snapshot
     (Settings : Editor.Settings.Settings_Model) return Settings_Surface_Snapshot;

   function Build_Surface_Snapshot
     (Settings : Editor.Settings.Settings_Model;
      UI       : Settings_Editor_State) return Settings_Surface_Snapshot;

   function Build_Current_Surface_Snapshot
     (Settings : Editor.Settings.Settings_Model) return Settings_Surface_Snapshot;



   type Settings_Command_Action is
     (Settings_Action_Show,
      Settings_Action_Focus,
      Settings_Action_Toggle_Selected,
      Settings_Action_Cycle_Selected,
      Settings_Action_Set_Selected_Value,
      Settings_Action_Reset_Selected,
      Settings_Action_Reset_All,
      Settings_Action_Confirm_Reset_All,
      Settings_Action_Cancel_Reset_All,
      Settings_Action_Save,
      Settings_Action_Load,
      Settings_Action_Show_Audit);

   type Settings_Command_Availability is record
      Available : Boolean := True;
      Reason    : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   function Availability_For
     (Action   : Settings_Command_Action;
      Settings : Editor.Settings.Settings_Model;
      UI       : Settings_Editor_State;
      Value    : String := "") return Settings_Command_Availability;

   function Availability_Message
     (Availability : Settings_Command_Availability) return String;

   procedure Execute_Settings_Surface_Command
     (Action   : Settings_Command_Action;
      Settings : in out Editor.Settings.Settings_Model;
      UI       : in out Settings_Editor_State;
      Status   : out Setting_Update_Status;
      Value    : String := "");

   procedure Execute_Settings_Surface_Command
     (Action   : Settings_Command_Action;
      Settings : in out Editor.Settings.Settings_Model;
      Status   : out Setting_Update_Status;
      Value    : String := "");

   function Assert_Settings_Command_Availability_Is_Side_Effect_Free return Boolean;
   function Assert_Reset_All_Settings_Does_Not_Cross_Domains return Boolean;
   function Assert_Reset_All_Settings_Command_Requires_Confirmation return Boolean;

   type Settings_Command_Catalog_Row is record
      Stable_Name       : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Display_Name      : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Availability_Hint : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Action            : Settings_Command_Action := Settings_Action_Show;
      Has_Executor_Command : Boolean := False;
      Surface_Only      : Boolean := False;
      Requires_Selection : Boolean := False;
      Requires_Value    : Boolean := False;
      Requires_Confirmation : Boolean := False;
      No_Payload        : Boolean := True;
      Configuration     : Boolean := True;
   end record;

   Max_Settings_Command_Catalog_Rows : constant Natural := 12;

   type Settings_Command_Catalog_Row_Array is
     array (Positive range 1 .. Max_Settings_Command_Catalog_Rows)
       of Settings_Command_Catalog_Row;

   Empty_Settings_Command_Catalog_Row : constant Settings_Command_Catalog_Row :=
     (others => <>);

   type Settings_Command_Catalog_Snapshot is record
      Row_Count        : Natural := 0;
      Display_Count    : Natural := 0;
      Executor_Command_Count : Natural := 0;
      Surface_Command_Count  : Natural := 0;
      Payload_Command_Count  : Natural := 0;
      Rows             : Settings_Command_Catalog_Row_Array :=
        (others => Empty_Settings_Command_Catalog_Row);
   end record;


   type Settings_Command_Route_Row is record
      Stable_Name        : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Action             : Settings_Command_Action := Settings_Action_Show;
      Executor_Command   : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Executor_Backend   : Boolean := False;
      Typed_Surface      : Boolean := False;
      Palette_Addressable : Boolean := False;
      Keybinding_Addressable : Boolean := False;
      Requires_Value     : Boolean := False;
      No_Payload         : Boolean := True;
   end record;

   Max_Settings_Command_Route_Rows : constant Natural := 12;

   type Settings_Command_Route_Row_Array is
     array (Positive range 1 .. Max_Settings_Command_Route_Rows)
       of Settings_Command_Route_Row;

   Empty_Settings_Command_Route_Row : constant Settings_Command_Route_Row :=
     (others => <>);

   type Settings_Command_Route_Snapshot is record
      Row_Count              : Natural := 0;
      Executor_Route_Count   : Natural := 0;
      Typed_Surface_Count    : Natural := 0;
      Palette_Route_Count    : Natural := 0;
      Keybinding_Route_Count : Natural := 0;
      Payload_Route_Count    : Natural := 0;
      Rows                   : Settings_Command_Route_Row_Array :=
        (others => Empty_Settings_Command_Route_Row);
   end record;

   function Build_Settings_Command_Routes
     return Settings_Command_Route_Snapshot;

   function Assert_Settings_Command_Routes_Are_Executor_Or_Typed_Surface_Only
     return Boolean;

   function Build_Settings_Command_Catalog
     return Settings_Command_Catalog_Snapshot;

   function Build_Current_Settings_Command_Catalog
     return Settings_Command_Catalog_Snapshot;

   function Build_Current_Configuration_Audit_Surface
     (Settings : Editor.Settings.Settings_Model)
      return Configuration_Audit_Surface_Snapshot;

   function Assert_Settings_Command_Catalog_Is_Bounded_And_Payload_Free
     return Boolean;

   function Assert_Settings_Surface_Render_Is_Observational return Boolean;
   function Assert_Settings_Editor_State_Not_Persisted return Boolean;

   function Assert_Settings_Configuration_Management_Coherent return Boolean;

end Editor.Settings_Management;
