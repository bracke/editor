with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Diagnostic_Command_Projection;
with Editor.Feature_Panel;

package Editor.Feature_Diagnostics is

   --  Diagnostics is a synchronous, session-local feature-owned producer seam.
   --  Producers may post diagnostic-like rows through Add_Diagnostic and may
   --  include already-validated buffer target metadata. They must not mutate
   --  Diagnostics storage, feature-panel projection rows, projection tokens,
   --  selection, or action metadata directly. This package intentionally does
   --  not invoke compilers, parse build output, speak LSP, watch files, run
   --  background workers, queue asynchronous diagnostics, analyze projects, or
   --  persist logs.

   type Diagnostic_Id is new Natural;
   No_Diagnostic : constant Diagnostic_Id := 0;
   No_Buffer : constant Natural := 0;

   Max_Diagnostics : constant Natural := 200;
   Max_Diagnostic_Message_Text_Length : constant Natural := 256;
   Max_Diagnostic_Source_Label_Text_Length : constant Natural := 192;
   Max_Quick_Fix_Actions_Per_Diagnostic : constant Natural := 4;
   Diagnostic_Quick_Fix_Picker_Query_Text : constant String :=
     "diagnostic quick fixes";

   type Diagnostic_Quick_Fix_Action_Model is
     (Quick_Fix_Action_Unavailable,
      Quick_Fix_Action_Edit,
      Quick_Fix_Action_Command,
      Quick_Fix_Action_Edit_And_Command);

   type Diagnostic_Severity is
     (Diagnostic_Info,
      Diagnostic_Note,
      Diagnostic_Warning,
      Diagnostic_Error,
      Diagnostic_Unknown);

   --  Source kind is a producer-facing classification used for session-local
   --  filtering and display only. It is not an execution backend, LSP source,
   --  build system identity, persistent log channel, or file-watcher handle.
   type Diagnostic_Source_Kind is
     (Editor_Diagnostic_Source,
      File_Diagnostic_Source,
      Project_Diagnostic_Source,
      External_Diagnostic_Source,
      Unknown_Diagnostic_Source);

   type Diagnostic_Item is private;
   type Diagnostics_Feature_State is private;

   procedure Clear_Diagnostics
     (Diagnostics : in out Diagnostics_Feature_State);

   procedure Clear
     (Diagnostics : in out Diagnostics_Feature_State) renames Clear_Diagnostics;

   procedure Add_Diagnostic
     (Diagnostics  : in out Diagnostics_Feature_State;
      Severity     : Diagnostic_Severity;
      Message      : String;
      Source_Label : String := "";
      Source_Kind  : Diagnostic_Source_Kind := Unknown_Diagnostic_Source;
      Has_Target   : Boolean := False;
      Target_Buffer : Natural := No_Buffer;
      Target_Line   : Natural := 0;
      Target_Column : Natural := 0;
      Build_Produced : Boolean := False;
      Primary_Action_Kind :
        Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind :=
          Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Navigate_To_Diagnostic;
      Has_Edit : Boolean := False;
      Edit_Start_Line   : Natural := 0;
      Edit_Start_Column : Natural := 0;
      Edit_End_Line     : Natural := 0;
      Edit_End_Column   : Natural := 0;
      Replacement_Text  : String := "";
      Quick_Fix_Label   : String := "";
      Quick_Fix_Detail  : String := "");

   procedure Add_Diagnostic_Command_Descriptor
     (Diagnostics : in out Diagnostics_Feature_State;
      Descriptor  :
        Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Descriptor;
      Source_Label : String := "Ada semantic diagnostics";
      Target_Buffer : Natural := No_Buffer);

   procedure Append_Diagnostic_Quick_Fix_Command
     (Diagnostics : in out Diagnostics_Feature_State;
      Index       : Positive;
      Label       : String;
      Detail      : String := "";
      Primary_Action_Kind :
        Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind);

   procedure Append_Diagnostic_Quick_Fix_Edit
     (Diagnostics : in out Diagnostics_Feature_State;
      Index       : Positive;
      Label       : String;
      Detail      : String := "";
      Edit_Start_Line   : Natural;
      Edit_Start_Column : Natural;
      Edit_End_Line     : Natural;
      Edit_End_Column   : Natural;
      Replacement_Text  : String := "");

   procedure Append_Diagnostic_Quick_Fix_Edit_And_Command
     (Diagnostics : in out Diagnostics_Feature_State;
      Index       : Positive;
      Label       : String;
      Detail      : String := "";
      Primary_Action_Kind :
        Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind;
      Edit_Start_Line   : Natural;
      Edit_Start_Column : Natural;
      Edit_End_Line     : Natural;
      Edit_End_Column   : Natural;
      Replacement_Text  : String := "");

   procedure Append_Diagnostic_Quick_Fix_Unavailable
     (Diagnostics : in out Diagnostics_Feature_State;
      Index       : Positive;
      Label       : String;
      Detail      : String := "");
   --  A target is navigable when Has_Target is True, Target_Buffer is set,
   --  and Target_Line is positive. Target_Column = 0 is a line-only target
   --  and is normalized to line start by open-selected navigation. Non-navigable
   --  rows may still retain partial producer target metadata for review labels,
   --  stale marking, and buffer-close cleanup. Build_Produced is explicit
   --  producer metadata supplied only by the build diagnostics ingestion seam;
   --  it is never inferred from display labels.


   type Diagnostics_Severity_Counts is record
      Errors   : Natural := 0;
      Warnings : Natural := 0;
      Info     : Natural := 0;
      Notes    : Natural := 0;
      Unknown  : Natural := 0;
      Total    : Natural := 0;
      Visible  : Natural := 0;
      Visible_Errors   : Natural := 0;
      Visible_Warnings : Natural := 0;
      Visible_Info     : Natural := 0;
      Visible_Notes    : Natural := 0;
      Visible_Unknown  : Natural := 0;
   end record;

   function Severity_Label_For_Display
     (Severity : Diagnostic_Severity) return String;

   function Source_Kind_Label_For_Display
     (Source_Kind : Diagnostic_Source_Kind) return String;

   function Producer_Label_For_Display
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String;

   function Item_Source_Display_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String;

   function Item_Target_Unavailable_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String;

   function Item_Row_State_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String;

   function Item_Is_Build_Produced
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Boolean;

   function Item_Primary_Action_Kind
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive)
      return Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind;

   function Item_Has_Edit
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Boolean;

   function Item_Edit_Start_Line
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural;

   function Item_Edit_Start_Column
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural;

   function Item_Edit_End_Line
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural;

   function Item_Edit_End_Column
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural;

   function Item_Replacement_Text
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String;

   function Item_Quick_Fix_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String;

   function Item_Quick_Fix_Detail
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String;

   function Item_Quick_Fix_Action_Count
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural;

   function Item_Quick_Fix_Action_Label_For_Display
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive) return String;

   function Item_Quick_Fix_Action_Detail_For_Display
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive) return String;

   function Item_Quick_Fix_Action_Kind
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive)
      return Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind;

   function Item_Quick_Fix_Action_Model
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive) return Diagnostic_Quick_Fix_Action_Model;

   function Item_Quick_Fix_Action_Has_Edit
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive) return Boolean;

   function Item_Quick_Fix_Action_Edit_Start_Line
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive) return Natural;

   function Item_Quick_Fix_Action_Edit_Start_Column
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive) return Natural;

   function Item_Quick_Fix_Action_Edit_End_Line
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive) return Natural;

   function Item_Quick_Fix_Action_Edit_End_Column
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive) return Natural;

   function Item_Quick_Fix_Action_Replacement_Text
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive) return String;

   function Quick_Fix_Action_Is_Intrinsically_Available
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Natural) return Boolean;

   function Quick_Fix_Action_Intrinsic_Unavailable_Reason
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Natural) return String;

   function Item_Quick_Fix_Label_For_Display
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String;

   function Item_Quick_Fix_Detail_For_Display
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String;

   function Count_By_Severity
     (Diagnostics : Diagnostics_Feature_State) return Diagnostics_Severity_Counts;

   function Count_Label
     (Counts : Diagnostics_Severity_Counts) return String;

   function Visible_Count_Label
     (Counts : Diagnostics_Severity_Counts) return String;

   type Diagnostics_File_Group is record
      Label            : Ada.Strings.Unbounded.Unbounded_String;
      Diagnostic_Count : Natural := 0;
      Error_Count      : Natural := 0;
      Warning_Count    : Natural := 0;
      Source_Less      : Boolean := False;
   end record;

   package Diagnostics_File_Group_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Diagnostics_File_Group);

   function Visible_File_Groups
     (Diagnostics : Diagnostics_Feature_State)
      return Diagnostics_File_Group_Vectors.Vector;

   function File_Group_Count
     (Diagnostics : Diagnostics_Feature_State) return Natural;

   function File_Group_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String;

   procedure Filter_Errors_Only
     (Diagnostics : in out Diagnostics_Feature_State);

   procedure Filter_Warnings_Only
     (Diagnostics : in out Diagnostics_Feature_State);

   procedure Filter_Info_And_Notes_Only
     (Diagnostics : in out Diagnostics_Feature_State);

   procedure Filter_Build_Produced
     (Diagnostics : in out Diagnostics_Feature_State);

   procedure Filter_Source_Label
     (Diagnostics : in out Diagnostics_Feature_State;
      Source_Text : String);

   function Item_Is_Stale
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Boolean;

   function Item_Stale_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String;

   procedure Mark_Diagnostics_For_Buffer_Stale
     (Diagnostics  : in out Diagnostics_Feature_State;
      Buffer_Token : Natural);

   procedure Mark_Diagnostics_For_Source_Path_Stale
     (Diagnostics : in out Diagnostics_Feature_State;
      Old_Path    : String;
      New_Path    : String := "");

   function Clear_Build_Diagnostics
     (Diagnostics : in out Diagnostics_Feature_State) return Natural;

   function Row_Count
     (Diagnostics : Diagnostics_Feature_State) return Natural;

   function Is_Empty
     (Diagnostics : Diagnostics_Feature_State) return Boolean;

   function Item_Id
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Diagnostic_Id;

   function Item_Severity
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Diagnostic_Severity;

   function Item_Message
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String;

   function Diagnostic_Message_Text_Is_Bounded
     (Diagnostics : Diagnostics_Feature_State) return Boolean;

   function Diagnostic_Source_Label_Text_Is_Bounded
     (Diagnostics : Diagnostics_Feature_State) return Boolean;

   function Item_Source_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String;

   function Item_Source_Kind
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Diagnostic_Source_Kind;

   function Item_Display_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String;

   function Header_Text
     (Diagnostics : Diagnostics_Feature_State) return String;

   function Visible_Row_Count
     (Diagnostics : Diagnostics_Feature_State) return Natural;

   function Severity_Is_Visible
     (Diagnostics : Diagnostics_Feature_State;
      Severity    : Diagnostic_Severity) return Boolean;

   function Source_Is_Visible
     (Diagnostics : Diagnostics_Feature_State;
      Source_Kind : Diagnostic_Source_Kind) return Boolean;

   function Filter_Active
     (Diagnostics : Diagnostics_Feature_State) return Boolean;

   function Filter_Text
     (Diagnostics : Diagnostics_Feature_State) return String;

   procedure Set_Filter_Text
     (Diagnostics : in out Diagnostics_Feature_State;
      Text        : String);

   procedure Clear_Filter
     (Diagnostics : in out Diagnostics_Feature_State);

   procedure Show_All
     (Diagnostics : in out Diagnostics_Feature_State);

   procedure Toggle_Info_Visible
     (Diagnostics : in out Diagnostics_Feature_State);

   procedure Toggle_Warnings_Visible
     (Diagnostics : in out Diagnostics_Feature_State);

   procedure Toggle_Errors_Visible
     (Diagnostics : in out Diagnostics_Feature_State);

   procedure Toggle_Source_Visible
     (Diagnostics : in out Diagnostics_Feature_State;
      Source_Kind : Diagnostic_Source_Kind);


   function Next_Diagnostic_Id
     (Diagnostics : Diagnostics_Feature_State) return Diagnostic_Id;

   function Item_Has_Target
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Boolean;

   function Item_Target_Buffer
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural;

   function Item_Target_Line
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural;

   function Item_Target_Column
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural;

   function Map_Diagnostic_Id_To_Item
     (Diagnostics : Diagnostics_Feature_State;
      Id          : Diagnostic_Id) return Natural;

   function Diagnostic_Id_Is_Live
     (Diagnostics : Diagnostics_Feature_State;
      Id          : Diagnostic_Id) return Boolean;

   function Validate_Diagnostic_Id_Target
     (Diagnostics         : Diagnostics_Feature_State;
      Id                  : Diagnostic_Id;
      Active_Buffer_Token : Natural) return Boolean;

   function Visible_Diagnostic_Count
     (Diagnostics : Diagnostics_Feature_State) return Natural renames Visible_Row_Count;

   function Has_Visible_Diagnostic
     (Diagnostics : Diagnostics_Feature_State) return Boolean;

   function Has_Selected_Diagnostic
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return Boolean;

   function Selected_Diagnostic_Has_Target
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return Boolean;

   function Selected_Diagnostic_Target_Unavailable_Label
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return String;

   function Selected_Diagnostic_Open_Unavailable_Reason
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return String;

   function Build_Diagnostic_Count
     (Diagnostics : Diagnostics_Feature_State) return Natural;

   function Has_Diagnostic_With_Severity
     (Diagnostics : Diagnostics_Feature_State;
      Severity    : Diagnostic_Severity) return Boolean;

   function Has_Info_Or_Note_Diagnostic
     (Diagnostics : Diagnostics_Feature_State) return Boolean;

   function Has_Build_Diagnostic
     (Diagnostics : Diagnostics_Feature_State) return Boolean;

   function Selected_Diagnostic_Id
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return Diagnostic_Id;

   function Selected_Diagnostic_Text
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return String;

   function Selected_Diagnostic_Source_Filter_Label
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return String;

   procedure Select_Next_Diagnostic
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : in out Editor.Feature_Panel.Feature_Panel_State);

   procedure Select_Previous_Diagnostic
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : in out Editor.Feature_Panel.Feature_Panel_State);

   function Format_Diagnostic_For_Copy
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String;

   function Clear_Diagnostic_By_Id
     (Diagnostics : in out Diagnostics_Feature_State;
      Id          : Diagnostic_Id) return Boolean;

   function Clear_Selected_Diagnostic
     (Diagnostics : in out Diagnostics_Feature_State;
      Panel       : in out Editor.Feature_Panel.Feature_Panel_State) return Boolean;

   function Suppress_Selected_Diagnostic
     (Diagnostics : in out Diagnostics_Feature_State;
      Panel       : in out Editor.Feature_Panel.Feature_Panel_State) return Boolean;

   function Restore_Last_Suppressed_Diagnostic
     (Diagnostics : in out Diagnostics_Feature_State;
      Panel       : in out Editor.Feature_Panel.Feature_Panel_State) return Boolean;

   function Restore_Selected_Suppressed_Diagnostic
     (Diagnostics : in out Diagnostics_Feature_State;
      Panel       : in out Editor.Feature_Panel.Feature_Panel_State) return Boolean;

   function Clear_Suppressed_Diagnostics
     (Diagnostics : in out Diagnostics_Feature_State) return Natural;

   function Suppressed_Diagnostic_Count
     (Diagnostics : Diagnostics_Feature_State) return Natural;

   function Selected_Suppressed_Diagnostic
     (Diagnostics : Diagnostics_Feature_State) return Natural;

   function Suppressed_Top_Row
     (Diagnostics    : Diagnostics_Feature_State;
      Visible_Count  : Natural) return Natural;

   procedure Ensure_Selected_Suppressed_Diagnostic_Visible
     (Diagnostics    : in out Diagnostics_Feature_State;
      Visible_Count  : Natural);

   procedure Scroll_Suppressed_Diagnostics
     (Diagnostics    : in out Diagnostics_Feature_State;
      Visible_Count  : Natural;
      Delta_Rows     : Integer);

   procedure Select_Suppressed_Diagnostic
     (Diagnostics : in out Diagnostics_Feature_State;
      Row         : Natural);

   procedure Select_Next_Suppressed_Diagnostic
     (Diagnostics : in out Diagnostics_Feature_State);

   procedure Select_Previous_Suppressed_Diagnostic
     (Diagnostics : in out Diagnostics_Feature_State);

   function Suppressed_Diagnostic_Text
     (Diagnostics : Diagnostics_Feature_State;
      Row         : Positive) return String;

   function Last_Suppressed_Diagnostic_Text
     (Diagnostics : Diagnostics_Feature_State) return String;

   function Clear_Diagnostics_By_Severity
     (Diagnostics : in out Diagnostics_Feature_State;
      Severity    : Diagnostic_Severity) return Natural;

   function Clear_Info_And_Note_Diagnostics
     (Diagnostics : in out Diagnostics_Feature_State) return Natural;

   function Clear_Diagnostics_By_Source
     (Diagnostics : in out Diagnostics_Feature_State;
      Source_Kind : Diagnostic_Source_Kind) return Natural;

   function Clear_Diagnostics_By_Source_And_Label
     (Diagnostics  : in out Diagnostics_Feature_State;
      Source_Kind  : Diagnostic_Source_Kind;
      Source_Label : String) return Natural;

   procedure Reconcile_Diagnostics_Selection_After_Delete
     (Diagnostics     : Diagnostics_Feature_State;
      Panel           : in out Editor.Feature_Panel.Feature_Panel_State;
      Previous_Id     : Diagnostic_Id;
      Previous_Source : Natural);

   procedure Project_Rows
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : in out Editor.Feature_Panel.Feature_Panel_State);

   function Map_Diagnostic_Row_To_Item
     (Diagnostics                    : Diagnostics_Feature_State;
      Panel                          : Editor.Feature_Panel.Feature_Panel_State;
      Row                            : Natural;
      Expected_Projection_Generation : Natural := 0) return Natural;

   function Validate_Diagnostic_Target
     (Diagnostics         : Diagnostics_Feature_State;
      Index               : Positive;
      Active_Buffer_Token : Natural) return Boolean;

   function Validate_Row_Action
     (Diagnostics                    : Diagnostics_Feature_State;
      Panel                          : Editor.Feature_Panel.Feature_Panel_State;
      Row                            : Natural;
      Expected_Projection_Generation : Natural := 0) return Boolean;

   procedure Reset_Diagnostics_For_Buffer_Close
     (Diagnostics : in out Diagnostics_Feature_State;
      Buffer_Token : Natural);

   procedure Reset_Diagnostics_For_Project_Close
     (Diagnostics : in out Diagnostics_Feature_State);

   procedure Reset_Diagnostics_For_Workspace_Close
     (Diagnostics : in out Diagnostics_Feature_State);

   procedure Assert_Diagnostics_State_Consistent
     (Diagnostics : Diagnostics_Feature_State);

   function Message_Diagnostics_Shown return String;
   function Message_Diagnostics_Cleared return String;
   function Message_No_Diagnostics return String;
   function Message_No_Target return String;
   function Message_Target_Unavailable return String;
   function Message_Diagnostic_Added return String;
   function Message_No_Selected_Diagnostic return String;
   function Message_No_Visible_Diagnostic return String;
   function Message_Selected_Diagnostic_Cleared return String;
   function Message_Selected_Diagnostic_Copied return String;
   function Message_Info_Cleared return String;
   function Message_Warnings_Cleared return String;
   function Message_Errors_Cleared return String;
   function Message_Filter_Cleared return String;
   function Message_No_Filter_Active return String;
   function Message_All_Diagnostics_Shown return String;
   function Message_Info_Hidden return String;
   function Message_Info_Shown return String;
   function Message_Warnings_Hidden return String;
   function Message_Warnings_Shown return String;
   function Message_Errors_Hidden return String;
   function Message_Errors_Shown return String;

   function Message_No_Info_Diagnostics return String;
   function Message_No_Warning_Diagnostics return String;
   function Message_No_Error_Diagnostics return String;
   function Message_No_Build_Diagnostics return String;
   function Message_Build_Diagnostics_Cleared return String;
   function Message_Filter_Errors return String;
   function Message_Filter_Warnings return String;
   function Message_Filter_Info_Notes return String;
   function Message_Filter_Selected_Source return String;
   function Message_Filter_Selected_Source_Unavailable return String;
   function Message_Filter_Build return String;

   function Message_Source_Hidden
     (Source_Kind : Diagnostic_Source_Kind) return String;
   function Message_Source_Shown
     (Source_Kind : Diagnostic_Source_Kind) return String;

   procedure Reconcile_Diagnostics_After_Filter_Change
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : in out Editor.Feature_Panel.Feature_Panel_State);

   procedure Reconcile_Diagnostics_After_Row_Change
     (Diagnostics     : Diagnostics_Feature_State;
      Panel           : in out Editor.Feature_Panel.Feature_Panel_State;
      Previous_Id     : Diagnostic_Id := No_Diagnostic;
      Previous_Source : Natural := 0);

private
   type Diagnostic_Quick_Fix_Action is record
      Model :
        Diagnostic_Quick_Fix_Action_Model := Quick_Fix_Action_Unavailable;
      Primary_Action_Kind :
        Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind :=
          Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_None;
      Has_Edit          : Boolean := False;
      Edit_Start_Line   : Natural := 0;
      Edit_Start_Column : Natural := 0;
      Edit_End_Line     : Natural := 0;
      Edit_End_Column   : Natural := 0;
      Replacement_Text  : Ada.Strings.Unbounded.Unbounded_String;
      Label             : Ada.Strings.Unbounded.Unbounded_String;
      Detail            : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Diagnostic_Quick_Fix_Action_Array is
     array (1 .. Max_Quick_Fix_Actions_Per_Diagnostic) of Diagnostic_Quick_Fix_Action;

   type Diagnostic_Item is record
      Id            : Diagnostic_Id := No_Diagnostic;
      Severity      : Diagnostic_Severity := Diagnostic_Info;
      Message       : Ada.Strings.Unbounded.Unbounded_String;
      Source_Label  : Ada.Strings.Unbounded.Unbounded_String;
      Source_Kind   : Diagnostic_Source_Kind := Unknown_Diagnostic_Source;
      Has_Target    : Boolean := False;
      Target_Buffer : Natural := No_Buffer;
      Target_Line   : Natural := 0;
      Target_Column     : Natural := 0;
      Is_Stale          : Boolean := False;
      Is_Build_Produced : Boolean := False;
      Primary_Action_Kind :
        Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind :=
          Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Navigate_To_Diagnostic;
      Has_Edit          : Boolean := False;
      Edit_Start_Line   : Natural := 0;
      Edit_Start_Column : Natural := 0;
      Edit_End_Line     : Natural := 0;
      Edit_End_Column   : Natural := 0;
      Replacement_Text  : Ada.Strings.Unbounded.Unbounded_String;
      Quick_Fix_Label   : Ada.Strings.Unbounded.Unbounded_String;
      Quick_Fix_Detail  : Ada.Strings.Unbounded.Unbounded_String;
      Quick_Fix_Action_Count : Natural := 0;
      Quick_Fix_Actions      : Diagnostic_Quick_Fix_Action_Array;
   end record;

   package Diagnostic_Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Diagnostic_Item);

   type Diagnostics_Filter_State is record
      Active        : Boolean := False;
      Text          : Ada.Strings.Unbounded.Unbounded_String;
      Source_Text   : Ada.Strings.Unbounded.Unbounded_String;
      Show_Info     : Boolean := True;
      Show_Notes    : Boolean := True;
      Show_Warnings : Boolean := True;
      Show_Errors   : Boolean := True;
      Show_Unknown_Severity : Boolean := True;
      Show_Editor   : Boolean := True;
      Show_File     : Boolean := True;
      Show_Project  : Boolean := True;
      Show_External    : Boolean := True;
      Show_Unknown     : Boolean := True;
      Build_Only       : Boolean := False;
   end record;

   type Diagnostics_Feature_State is record
      Rows            : Diagnostic_Row_Vectors.Vector;
      Suppressed_Rows : Diagnostic_Row_Vectors.Vector;
      Selected_Suppressed_Row : Natural := 0;
      Suppressed_Top_Row : Natural := 1;
      Next_Id         : Diagnostic_Id := 1;
      Filter          : Diagnostics_Filter_State;
   end record;

end Editor.Feature_Diagnostics;
