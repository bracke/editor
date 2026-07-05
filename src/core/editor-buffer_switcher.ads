with Ada.Containers.Vectors;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
limited with Editor.Buffers;
with Editor.Buffer_Types;
use type Editor.Buffer_Types.Buffer_Id;
with Editor.Input_Field;
with Editor.Layout;
with Editor.Project;
with Editor.Recent_Buffers;

package Editor.Buffer_Switcher is

   type Buffer_Switcher_State is private;

   type Pending_Marked_Action_Kind is
     (No_Pending_Marked_Action,
      Pending_Marked_Close);

   type Switcher_Metadata_Filter_Kind is
     (No_Filter,
      Pinned_Filter,
      Group_Filter,
      Label_Filter,
      Noted_Filter,
      Dirty_Filter,
      Clean_Filter,
      Missing_Or_Conflict_Filter,
      Project_Owned_Filter,
      Outside_Project_Filter,
      Scratch_Filter);

   type Switcher_Metadata_Filter is record
      Kind : Switcher_Metadata_Filter_Kind := No_Filter;
      Text : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   type Switcher_Sort_Mode is
     (Default_Sort,
      Recent_Sort,
      Name_Sort,
      Pinned_Sort,
      Group_Sort,
      Label_Sort);

   type Switcher_Review_Mode is
     (No_Review,
      Marked_Review,
      Pending_Marked_Close_Review,
      Pruned_Pending_Close_Review,
      Dirty_Pending_Close_Review,
      Dirty_Prune_Preview_Review,
      Removed_Dirty_Prune_Preview_Review,
      Dirty_Prune_Apply_Review,
      Removed_Dirty_Prune_Apply_Review);

   type Switcher_Batch_State_Snapshot is record
      Active_Review_Mode : Switcher_Review_Mode := No_Review;
      Review_Display_Name : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
      Review_Empty_Message : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
      Marked_Count : Natural := 0;
      Pending_Close_Count : Natural := 0;
      Dirty_Pending_Close_Count : Natural := 0;
      Pruned_Pending_Close_Count : Natural := 0;
      Dirty_Prune_Preview_Count : Natural := 0;
      Applicable_Dirty_Prune_Preview_Count : Natural := 0;
      Removed_Dirty_Prune_Preview_Count : Natural := 0;
      Open_Removed_Dirty_Prune_Preview_Count : Natural := 0;
      Stale_Dirty_Prune_Preview_Count : Natural := 0;
      Dirty_Prune_Apply_Count : Natural := 0;
      Applicable_Dirty_Prune_Apply_Count : Natural := 0;
      Removed_Dirty_Prune_Apply_Count : Natural := 0;
      Open_Removed_Dirty_Prune_Apply_Count : Natural := 0;
      Stale_Dirty_Prune_Apply_Count : Natural := 0;
      Has_Pending_Marked_Close : Boolean := False;
      Has_Dirty_Prune_Preview : Boolean := False;
      Has_Dirty_Prune_Apply_Confirmation : Boolean := False;
      Header_Badge_Text : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
      Footer_Badge_Text : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   type Buffer_Project_Ownership_Kind is
     (Buffer_Project_Unknown,
      Buffer_Project_Owned,
      Buffer_Project_Outside,
      Buffer_Project_Scratch,
      Buffer_Project_No_Project);

   type Buffer_Switcher_Config is record
      Max_Visible_Results      : Natural := 12;
      Query_Field_Min_Columns  : Natural := 24;
      Overlay_Width_In_Columns : Natural := 72;
      Row_Height_In_Rows       : Natural := 1;
      Header_Height_In_Rows    : Natural := 1;
      Field_Height_In_Rows     : Natural := 1;
      Result_Padding_Columns   : Natural := 1;
      Preview_Max_Lines        : Natural := 7;
   end record;


   type Selected_Buffer_List_Audit is record
      Row_Count                        : Natural := 0;
      Selected_Row_Index               : Natural := 0;
      Selected_Row_Valid               : Boolean := True;
      Selected_Row_Is_Buffer           : Boolean := True;
      Selected_Runtime_Id_Registered   : Boolean := True;
      Selection_Cleared_When_No_Rows    : Boolean := True;
      Selection_Index_Clamped_To_Rows   : Boolean := True;
      Selection_Skips_Status_Rows       : Boolean := True;
      Selection_Is_Transient            : Boolean := True;
      Selection_Not_Persisted           : Boolean := True;
      Selection_Not_Keybinding_Payload  : Boolean := True;
      Selected_Buffer_Id                : Editor.Buffer_Types.Buffer_Id := Editor.Buffer_Types.No_Buffer;
   end record;

   type Buffer_Switcher_Row is record
      Id           : Editor.Buffer_Types.Buffer_Id := Editor.Buffer_Types.No_Buffer;
      Display_Label : Ada.Strings.Unbounded.Unbounded_String;
      Is_Dirty     : Boolean := False;
      Is_Active    : Boolean := False;
      Has_Path     : Boolean := False;
      Path          : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
      Project_Ownership : Buffer_Project_Ownership_Kind := Buffer_Project_Unknown;
      Project_Ownership_Label : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
      --  render-facing metadata labels.  These fields are copied
      --  from Buffer_Metadata_Snapshot during row recomputation so render can
      --  display lifecycle/persistability/close markers without deriving or
      --  mutating buffer state.
      Lifecycle_Status_Label : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
      Workspace_Persistability_Label : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
      Close_Eligibility_Label : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
      Stale_Backing_State : Boolean := False;
      Is_Project_Owned  : Boolean := False;
      Is_Outside_Project : Boolean := False;
      Is_File_Backed : Boolean := False;
      Is_Unbacked    : Boolean := False;
      Last_Save_Failed   : Boolean := False;
      Last_Reload_Failed : Boolean := False;
      Last_Revert_Failed : Boolean := False;
      Missing_Target_Surfaced    : Boolean := False;
      Unreadable_Target_Surfaced : Boolean := False;
      Unwritable_Target_Surfaced : Boolean := False;
      External_Change_Surfaced   : Boolean := False;
      Blocked_Close_Surfaced     : Boolean := False;
      Is_Pinned    : Boolean := False;
      Has_Group    : Boolean := False;
      Group_Name   : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
      Has_Label    : Boolean := False;
      Label_Text   : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
      Has_Note     : Boolean := False;
      Is_Marked    : Boolean := False;
      Is_Pending_Close_Target : Boolean := False;
      Is_Ordinary_Pruned_Target : Boolean := False;
      Is_Dirty_Prune_Preview_Target : Boolean := False;
      Is_Removed_Dirty_Prune_Preview_Target : Boolean := False;
      Is_Dirty_Prune_Apply_Target : Boolean := False;
      Is_Removed_Dirty_Prune_Apply_Target : Boolean := False;
   end record;

   --  canonical projection seam: file-lifecycle-visible row
   --  fields are copied only from the current buffer summary snapshot.  This
   --  helper intentionally has no switcher state parameter, no filesystem
   --  parameter, no prompt parameter, and no command-result parameter.
   function Build_Open_Buffer_Switcher_Row_From_Buffer_Snapshot
     (Summary : Editor.Buffer_Types.Buffer_Summary) return Buffer_Switcher_Row;

   --  canonical Buffer List projection seam.  Buffer List rows use
   --  the metadata snapshot for buffer identity, path labels, ownership,
   --  dirty/active/scratch state, and lifecycle markers.  Buffer_Summary is
   --  accepted only for existing switcher-only annotations such as pinned,
   --  group, label, and note metadata that are not part of the lifecycle
   --  metadata snapshot.
   function Build_Open_Buffer_Switcher_Row_From_Metadata_Snapshot
     (Metadata : Editor.Buffers.Buffer_Metadata_Snapshot;
      Summary  : Editor.Buffer_Types.Buffer_Summary) return Buffer_Switcher_Row;

   --  compact observational marker text for render/tests.  The
   --  marker is derived only from a buffer-list row snapshot and never probes
   --  files, switches buffers, closes buffers, or mutates switcher selection.
   function Buffer_Row_State_Markers
     (Row : Buffer_Switcher_Row) return String;

   --  render-facing bounded metadata line.  It is built only from
   --  the already-snapshotted Buffer_Switcher_Row metadata projection.
   function Buffer_Row_Metadata_Render_Label
     (Row : Buffer_Switcher_Row) return String;

   function Buffer_Project_Ownership_Label
     (Kind : Buffer_Project_Ownership_Kind) return String;

   --  row-level ownership projection helper.  It delegates to the
   --  canonical Editor.Buffers.Classify_Buffer_Ownership helper rather than
   --  recomputing project membership locally.  New Buffer List recomputation
   --  paths should prefer Build_Open_Buffer_Switcher_Row_From_Metadata_Snapshot.
   procedure Apply_Project_Ownership
     (Row     : in out Buffer_Switcher_Row;
      Project : Editor.Project.Project_State);

   --  completeness: central display-only empty/status wording for
   --  the open-buffer list.  It observes already-known row/filter counts only;
   --  callers provide the open-buffer count from their own snapshot context.
   function Buffer_List_Empty_State_Label
     (State              : Buffer_Switcher_State;
      Open_Buffer_Count  : Natural) return String;

   --  invariant helpers.  These are structural checks over the
   --  public/private switcher state model; they do not execute commands, do
   --  not probe the filesystem, and do not mutate editor state.
   function Open_Buffer_Switcher_No_Duplicate_Lifecycle_State
     (State : Buffer_Switcher_State) return Boolean;
   function Open_Buffer_Switcher_No_Prompt_State
     (State : Buffer_Switcher_State) return Boolean;
   function Open_Buffer_Switcher_No_File_Lifecycle_Source_Override
     (State : Buffer_Switcher_State) return Boolean;

   --  final freeze helper: compact structural assertion point for
   --  the observation-only model.  It remains an inspector over switcher
   --  state only and intentionally has no filesystem, prompt, command-result,
   --  persistence, or render mutation channel.
   function Open_Buffer_Switcher_File_Lifecycle_Observation_Frozen
     (State : Buffer_Switcher_State) return Boolean;

   --  milestone helper: verifies the open-buffer list remains a
   --  transient runtime projection with coherent row markers/labels and no
   --  lifecycle prompt/source ownership.  It is observational only.
   function Assert_Multi_Buffer_Management_Coherent
     (State : Buffer_Switcher_State) return Boolean;

   procedure Clear (State : in out Buffer_Switcher_State);
   procedure Open (State : in out Buffer_Switcher_State);
   procedure Close (State : in out Buffer_Switcher_State);
   function Is_Open (State : Buffer_Switcher_State) return Boolean;

   function Filter_Text (State : Buffer_Switcher_State) return String;
   procedure Set_Filter_Text (State : in out Buffer_Switcher_State; Text : String);
   procedure Insert_Text (State : in out Buffer_Switcher_State; Text : String);
   procedure Backspace (State : in out Buffer_Switcher_State);
   procedure Delete_Forward (State : in out Buffer_Switcher_State);
   procedure Move_Cursor_Left (State : in out Buffer_Switcher_State);
   procedure Move_Cursor_Right (State : in out Buffer_Switcher_State);
   procedure Move_Cursor_Start (State : in out Buffer_Switcher_State);
   procedure Move_Cursor_End (State : in out Buffer_Switcher_State);
   procedure Select_All (State : in out Buffer_Switcher_State);

   procedure Clear_Metadata_Filter (State : in out Buffer_Switcher_State);
   procedure Set_Pinned_Filter (State : in out Buffer_Switcher_State);
   procedure Set_Group_Filter (State : in out Buffer_Switcher_State; Name : String);
   procedure Set_Label_Filter (State : in out Buffer_Switcher_State; Label : String);
   procedure Set_Noted_Filter (State : in out Buffer_Switcher_State);
   procedure Set_Dirty_Filter (State : in out Buffer_Switcher_State);
   procedure Set_Clean_Filter (State : in out Buffer_Switcher_State);
   procedure Set_Missing_Or_Conflict_Filter (State : in out Buffer_Switcher_State);
   procedure Set_Project_Owned_Filter (State : in out Buffer_Switcher_State);
   procedure Set_Outside_Project_Filter (State : in out Buffer_Switcher_State);
   procedure Set_Scratch_Filter (State : in out Buffer_Switcher_State);
   function Has_Metadata_Filter (State : Buffer_Switcher_State) return Boolean;
   function Metadata_Filter (State : Buffer_Switcher_State) return Switcher_Metadata_Filter;
   function Metadata_Filter_Description (State : Buffer_Switcher_State) return String;

   procedure Set_Sort_Mode (State : in out Buffer_Switcher_State; Mode : Switcher_Sort_Mode);
   procedure Clear_Sort_Mode (State : in out Buffer_Switcher_State);
   procedure Next_Sort_Mode (State : in out Buffer_Switcher_State);
   procedure Previous_Sort_Mode (State : in out Buffer_Switcher_State);
   function Sort_Mode (State : Buffer_Switcher_State) return Switcher_Sort_Mode;
   function Sort_Mode_Description (State : Buffer_Switcher_State) return String;

   procedure Show_Marked_Review (State : in out Buffer_Switcher_State);
   procedure Hide_Marked_Review (State : in out Buffer_Switcher_State);
   procedure Toggle_Marked_Review (State : in out Buffer_Switcher_State);
   function Has_Marked_Review (State : Buffer_Switcher_State) return Boolean;
   function Marked_Review_Description (State : Buffer_Switcher_State) return String;

   procedure Show_Pending_Marked_Review (State : in out Buffer_Switcher_State);
   procedure Hide_Pending_Marked_Review (State : in out Buffer_Switcher_State);
   procedure Toggle_Pending_Marked_Review (State : in out Buffer_Switcher_State);
   function Has_Pending_Marked_Review (State : Buffer_Switcher_State) return Boolean;
   function Pending_Marked_Review_Description (State : Buffer_Switcher_State) return String;

   procedure Show_Pruned_Pending_Marked_Review (State : in out Buffer_Switcher_State);
   procedure Hide_Pruned_Pending_Marked_Review (State : in out Buffer_Switcher_State);
   procedure Toggle_Pruned_Pending_Marked_Review (State : in out Buffer_Switcher_State);
   function Has_Pruned_Pending_Marked_Review (State : Buffer_Switcher_State) return Boolean;
   function Pruned_Pending_Marked_Review_Description (State : Buffer_Switcher_State) return String;

   procedure Show_Dirty_Pending_Marked_Review (State : in out Buffer_Switcher_State);
   procedure Hide_Dirty_Pending_Marked_Review (State : in out Buffer_Switcher_State);
   procedure Toggle_Dirty_Pending_Marked_Review (State : in out Buffer_Switcher_State);
   function Has_Dirty_Pending_Marked_Review (State : Buffer_Switcher_State) return Boolean;
   function Dirty_Pending_Marked_Review_Description (State : Buffer_Switcher_State) return String;

   procedure Show_Dirty_Prune_Review (State : in out Buffer_Switcher_State);
   procedure Hide_Dirty_Prune_Review (State : in out Buffer_Switcher_State);
   procedure Toggle_Dirty_Prune_Review (State : in out Buffer_Switcher_State);
   function Has_Dirty_Prune_Review (State : Buffer_Switcher_State) return Boolean;
   function Dirty_Prune_Review_Description (State : Buffer_Switcher_State) return String;

   procedure Show_Removed_Dirty_Prune_Review (State : in out Buffer_Switcher_State);
   procedure Hide_Removed_Dirty_Prune_Review (State : in out Buffer_Switcher_State);
   procedure Toggle_Removed_Dirty_Prune_Review (State : in out Buffer_Switcher_State);
   function Has_Removed_Dirty_Prune_Review (State : Buffer_Switcher_State) return Boolean;
   function Removed_Dirty_Prune_Review_Description (State : Buffer_Switcher_State) return String;

   procedure Show_Dirty_Prune_Apply_Review (State : in out Buffer_Switcher_State);
   procedure Hide_Dirty_Prune_Apply_Review (State : in out Buffer_Switcher_State);
   procedure Toggle_Dirty_Prune_Apply_Review (State : in out Buffer_Switcher_State);
   function Has_Dirty_Prune_Apply_Review (State : Buffer_Switcher_State) return Boolean;
   function Dirty_Prune_Apply_Review_Description (State : Buffer_Switcher_State) return String;

   procedure Show_Removed_Dirty_Prune_Apply_Review (State : in out Buffer_Switcher_State);
   procedure Hide_Removed_Dirty_Prune_Apply_Review (State : in out Buffer_Switcher_State);
   procedure Toggle_Removed_Dirty_Prune_Apply_Review (State : in out Buffer_Switcher_State);
   function Has_Removed_Dirty_Prune_Apply_Review (State : Buffer_Switcher_State) return Boolean;
   function Removed_Dirty_Prune_Apply_Review_Description (State : Buffer_Switcher_State) return String;

   procedure Prepare_Pending_Marked_Close
     (State       : in out Buffer_Switcher_State;
      Registry    : Editor.Buffers.Buffer_Registry;
      Count       : out Natural;
      Dirty_Count : out Natural);
   procedure Clear_Pending_Marked_Action (State : in out Buffer_Switcher_State);
   function Pending_Marked_Action (State : Buffer_Switcher_State) return Pending_Marked_Action_Kind;
   function Pending_Marked_Target_Count (State : Buffer_Switcher_State) return Natural;
   function Pending_Marked_Dirty_Count (State : Buffer_Switcher_State) return Natural;
   function Pending_Marked_Target_At
     (State : Buffer_Switcher_State;
      Index : Positive) return Editor.Buffer_Types.Buffer_Id;
   function Pending_Marked_Open_Count
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural;
   function Pending_Marked_Open_Dirty_Count
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural;
   function Is_Pending_Marked_Close_Target
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffer_Types.Buffer_Id) return Boolean;
   function Has_Pruned_Pending_Marked_Close_Targets
     (State : Buffer_Switcher_State) return Boolean;
   function Pruned_Pending_Marked_Close_Target_Count
     (State : Buffer_Switcher_State) return Natural;
   function Open_Pruned_Pending_Marked_Close_Target_Count
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural;
   function Last_Pruned_Pending_Marked_Close_Target_Name
     (State : Buffer_Switcher_State) return String;
   function Is_Pruned_Pending_Marked_Close_Target
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffer_Types.Buffer_Id) return Boolean;

   procedure Prepare_Dirty_Pending_Marked_Close_Prune
     (State    : in out Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry;
      Count    : out Natural);
   function Has_Dirty_Pending_Marked_Close_Prune
     (State : Buffer_Switcher_State) return Boolean;
   function Dirty_Pending_Marked_Close_Prune_Target_Count
     (State : Buffer_Switcher_State) return Natural;
   function Applicable_Dirty_Pending_Marked_Close_Prune_Target_Count
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural;
   function Dirty_Pending_Marked_Close_Prune_Stale_Target_Count
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural;
   function Has_Stale_Dirty_Pending_Marked_Close_Prune_Targets
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Boolean;
   procedure Clear_Stale_Dirty_Pending_Marked_Close_Prune_Targets
     (State     : in out Buffer_Switcher_State;
      Registry  : Editor.Buffers.Buffer_Registry;
      Cleared   : out Natural;
      Remaining : out Natural);
   function Is_Dirty_Pending_Marked_Close_Prune_Target
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffer_Types.Buffer_Id) return Boolean;
   procedure Remove_Dirty_Pending_Marked_Close_Prune_Target
     (State     : in out Buffer_Switcher_State;
      Registry  : Editor.Buffers.Buffer_Registry;
      Id        : Editor.Buffer_Types.Buffer_Id;
      Removed   : out Boolean;
      Remaining : out Natural);
   function Has_Removed_Dirty_Pending_Marked_Close_Prune_Targets
     (State : Buffer_Switcher_State) return Boolean;
   function Removed_Dirty_Pending_Marked_Close_Prune_Target_Count
     (State : Buffer_Switcher_State) return Natural;
   function Open_Removed_Dirty_Pending_Marked_Close_Prune_Target_Count
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural;
   function Last_Removed_Dirty_Pending_Marked_Close_Prune_Target_Name
     (State : Buffer_Switcher_State) return String;
   function Is_Removed_Dirty_Pending_Marked_Close_Prune_Target
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffer_Types.Buffer_Id) return Boolean;
   procedure Restore_Last_Removed_Dirty_Pending_Marked_Close_Prune_Target
     (State        : in out Buffer_Switcher_State;
      Registry     : Editor.Buffers.Buffer_Registry;
      Restored     : out Boolean;
      Target       : out Editor.Buffer_Types.Buffer_Id;
      Display_Name : out Ada.Strings.Unbounded.Unbounded_String;
      Remaining    : out Natural);
   procedure Cancel_Dirty_Pending_Marked_Close_Prune
     (State : in out Buffer_Switcher_State);
   procedure Apply_Dirty_Pending_Marked_Close_Prune
     (State     : in out Buffer_Switcher_State;
      Registry  : Editor.Buffers.Buffer_Registry;
      Applied   : out Natural;
      Remaining : out Natural);

   procedure Prepare_Dirty_Pending_Marked_Close_Prune_Apply
     (State      : in out Buffer_Switcher_State;
      Registry   : Editor.Buffers.Buffer_Registry;
      Count      : out Natural;
      Applicable : out Natural);
   function Has_Dirty_Pending_Marked_Close_Prune_Apply
     (State : Buffer_Switcher_State) return Boolean;
   function Dirty_Pending_Marked_Close_Prune_Apply_Target_Count
     (State : Buffer_Switcher_State) return Natural;
   function Applicable_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural;
   function Dirty_Pending_Marked_Close_Prune_Apply_Stale_Target_Count
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural;
   procedure Clear_Stale_Dirty_Pending_Marked_Close_Prune_Apply_Targets
     (State     : in out Buffer_Switcher_State;
      Registry  : Editor.Buffers.Buffer_Registry;
      Cleared   : out Natural;
      Remaining : out Natural);
   function Is_Dirty_Pending_Marked_Close_Prune_Apply_Target
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffer_Types.Buffer_Id) return Boolean;
   procedure Remove_Dirty_Pending_Marked_Close_Prune_Apply_Target
     (State     : in out Buffer_Switcher_State;
      Registry  : Editor.Buffers.Buffer_Registry;
      Id        : Editor.Buffer_Types.Buffer_Id;
      Removed   : out Boolean;
      Remaining : out Natural);
   function Has_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Targets
     (State : Buffer_Switcher_State) return Boolean;
   function Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count
     (State : Buffer_Switcher_State) return Natural;
   function Open_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural;
   function Last_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target_Name
     (State : Buffer_Switcher_State) return String;
   function Is_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffer_Types.Buffer_Id) return Boolean;
   procedure Restore_Last_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target
     (State        : in out Buffer_Switcher_State;
      Registry     : Editor.Buffers.Buffer_Registry;
      Restored     : out Boolean;
      Target       : out Editor.Buffer_Types.Buffer_Id;
      Display_Name : out Ada.Strings.Unbounded.Unbounded_String;
      Remaining    : out Natural);
   procedure Confirm_Dirty_Pending_Marked_Close_Prune_Apply
     (State     : in out Buffer_Switcher_State;
      Registry  : Editor.Buffers.Buffer_Registry;
      Applied   : out Natural;
      Skipped   : out Natural;
      Remaining : out Natural);
   procedure Cancel_Dirty_Pending_Marked_Close_Prune_Apply
     (State : in out Buffer_Switcher_State);
   procedure Remove_Pending_Marked_Close_Target
     (State       : in out Buffer_Switcher_State;
      Registry    : Editor.Buffers.Buffer_Registry;
      Id          : Editor.Buffer_Types.Buffer_Id;
      Removed     : out Boolean;
      Remaining   : out Natural);
   procedure Restore_Last_Pruned_Pending_Marked_Close_Target
     (State        : in out Buffer_Switcher_State;
      Registry     : Editor.Buffers.Buffer_Registry;
      Restored     : out Boolean;
      Target       : out Editor.Buffer_Types.Buffer_Id;
      Display_Name : out Ada.Strings.Unbounded.Unbounded_String;
      Remaining    : out Natural);
   procedure Restore_Pruned_Pending_Marked_Close_Target
     (State        : in out Buffer_Switcher_State;
      Registry     : Editor.Buffers.Buffer_Registry;
      Id           : Editor.Buffer_Types.Buffer_Id;
      Restored     : out Boolean;
      Display_Name : out Ada.Strings.Unbounded.Unbounded_String;
      Remaining    : out Natural);

   procedure Recompute_Rows
     (State    : in out Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry;
      Config   : Buffer_Switcher_Config);

   procedure Recompute_Rows
     (State    : in out Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State;
      Config   : Buffer_Switcher_Config);

   procedure Recompute_Rows
     (State    : in out Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State;
      Project  : Editor.Project.Project_State;
      Config   : Buffer_Switcher_Config);

   procedure Move_Selection_Down (State : in out Buffer_Switcher_State);
   procedure Move_Selection_Up (State : in out Buffer_Switcher_State);

   procedure Show_Preview (State : in out Buffer_Switcher_State);
   procedure Hide_Preview (State : in out Buffer_Switcher_State);
   procedure Toggle_Preview (State : in out Buffer_Switcher_State);
   function Has_Preview (State : Buffer_Switcher_State) return Boolean;

   procedure Set_Preview_Target
     (State       : in out Buffer_Switcher_State;
      Target      : Editor.Buffer_Types.Buffer_Id;
      Anchor_Line : Natural);

   procedure Clear_Preview_Target (State : in out Buffer_Switcher_State);
   function Preview_Target (State : Buffer_Switcher_State) return Editor.Buffer_Types.Buffer_Id;
   function Preview_Anchor_Line (State : Buffer_Switcher_State) return Natural;
   function Preview_Scroll_Offset (State : Buffer_Switcher_State) return Natural;

   procedure Scroll_Preview_Next_Line (State : in out Buffer_Switcher_State);
   procedure Scroll_Preview_Previous_Line (State : in out Buffer_Switcher_State);
   procedure Center_Preview_On_Line
     (State       : in out Buffer_Switcher_State;
      Anchor_Line : Natural);

   procedure Select_Buffer_Or_Row
     (State          : in out Buffer_Switcher_State;
      Preferred_Id   : Editor.Buffer_Types.Buffer_Id;
      Fallback_Index : Natural);

   procedure Toggle_Mark (State : in out Buffer_Switcher_State; Id : Editor.Buffer_Types.Buffer_Id);
   procedure Set_Mark (State : in out Buffer_Switcher_State; Id : Editor.Buffer_Types.Buffer_Id);
   procedure Clear_Mark (State : in out Buffer_Switcher_State; Id : Editor.Buffer_Types.Buffer_Id);
   procedure Clear_All_Marks (State : in out Buffer_Switcher_State);
   function Is_Marked (State : Buffer_Switcher_State; Id : Editor.Buffer_Types.Buffer_Id) return Boolean;
   function Marked_Count (State : Buffer_Switcher_State) return Natural;
   function Open_Marked_Count
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural;
   function Build_Switcher_Batch_State_Snapshot
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Switcher_Batch_State_Snapshot;
   function Header_Badge_Text
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return String;
   function Footer_Badge_Text
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return String;
   function Count_Badge_Text
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return String;
   function Has_Marks (State : Buffer_Switcher_State) return Boolean;
   procedure Invert_Visible_Marks
     (State          : in out Buffer_Switcher_State;
      Marked_Count   : out Natural;
      Unmarked_Count : out Natural);
   procedure Mark_Visible_Marks
     (State : in out Buffer_Switcher_State;
      Count : out Natural);
   procedure Clear_Visible_Marks
     (State : in out Buffer_Switcher_State;
      Count : out Natural);
   procedure Prune_Marks (State : in out Buffer_Switcher_State; Registry : Editor.Buffers.Buffer_Registry);
   function Select_Next_Marked_Buffer (State : in out Buffer_Switcher_State) return Boolean;
   function Select_Previous_Marked_Buffer (State : in out Buffer_Switcher_State) return Boolean;
   function Select_Next_Pending_Marked_Buffer (State : in out Buffer_Switcher_State) return Boolean;
   function Select_Previous_Pending_Marked_Buffer (State : in out Buffer_Switcher_State) return Boolean;
   function Select_Next_Pruned_Pending_Marked_Buffer (State : in out Buffer_Switcher_State) return Boolean;
   function Select_Previous_Pruned_Pending_Marked_Buffer (State : in out Buffer_Switcher_State) return Boolean;
   function Select_Next_Dirty_Pending_Marked_Buffer (State : in out Buffer_Switcher_State) return Boolean;
   function Select_Previous_Dirty_Pending_Marked_Buffer (State : in out Buffer_Switcher_State) return Boolean;
   function Select_Next_Dirty_Prune_Target (State : in out Buffer_Switcher_State) return Boolean;
   function Select_Previous_Dirty_Prune_Target (State : in out Buffer_Switcher_State) return Boolean;
   function Select_Next_Removed_Dirty_Prune_Target (State : in out Buffer_Switcher_State) return Boolean;
   function Select_Previous_Removed_Dirty_Prune_Target (State : in out Buffer_Switcher_State) return Boolean;
   function Select_Next_Dirty_Prune_Apply_Target (State : in out Buffer_Switcher_State) return Boolean;
   function Select_Previous_Dirty_Prune_Apply_Target (State : in out Buffer_Switcher_State) return Boolean;
   function Select_Next_Removed_Dirty_Prune_Apply_Target (State : in out Buffer_Switcher_State) return Boolean;
   function Select_Previous_Removed_Dirty_Prune_Apply_Target (State : in out Buffer_Switcher_State) return Boolean;
   function Row_Is_Dirty_Prune_Target
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffer_Types.Buffer_Id) return Boolean;
   function Row_Is_Pending_Marked_Target
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffer_Types.Buffer_Id) return Boolean;

   function Row_Count (State : Buffer_Switcher_State) return Natural;
   function Selected_Row_Index (State : Buffer_Switcher_State) return Natural;
   function Top_Row_Index (State : Buffer_Switcher_State) return Natural;
   function Row_At (State : Buffer_Switcher_State; Index : Positive) return Buffer_Switcher_Row;
   function Row_For_Buffer
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffer_Types.Buffer_Id;
      Found : out Boolean) return Buffer_Switcher_Row;
   function Selected_Row (State : Buffer_Switcher_State; Found : out Boolean) return Buffer_Switcher_Row;

   --  selected-buffer validity audit over the real Buffer List
   --  state.  This inspects the selected row/index currently held by the
   --  switcher, verifies that it maps to a real open buffer row in the
   --  supplied registry snapshot, and keeps the selection boundary explicit
   --  as transient/non-persisted/non-keybinding-payload state.
   function Audit_Selected_Buffer_List_State
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Selected_Buffer_List_Audit;

   function Query_Snapshot
     (State           : Buffer_Switcher_State;
      Visible_Columns : Natural) return Editor.Input_Field.Field_Snapshot;

   function Geometry
     (Body_Rect   : Editor.Layout.Rect;
      Config      : Buffer_Switcher_Config;
      Cell_Width  : Positive;
      Cell_Height : Positive) return Editor.Layout.Rect;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Buffer_Switcher_Row);

   package Mark_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Editor.Buffer_Types.Buffer_Id);

   package Natural_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Natural);

   type Pruned_Pending_Target is record
      Id                : Editor.Buffer_Types.Buffer_Id := Editor.Buffer_Types.No_Buffer;
      Display_Name      : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
      Original_Position : Natural := 0;
   end record;

   package Pruned_Pending_Target_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Pruned_Pending_Target);

   type Buffer_Switcher_State is record
      Opened         : Boolean := False;
      Field          : Editor.Input_Field.Input_Field_State;
      Rows           : Row_Vectors.Vector;
      Selected_Index : Natural := 0;
      Top_Index      : Natural := 1;
      Visible_Window : Natural := 12;
      Active_Filter  : Switcher_Metadata_Filter;
      Active_Sort    : Switcher_Sort_Mode := Default_Sort;
      Active_Review : Switcher_Review_Mode := No_Review;
      Preview_Visible : Boolean := False;
      Preview_Target_Id : Editor.Buffer_Types.Buffer_Id := Editor.Buffer_Types.No_Buffer;
      Preview_Anchor : Natural := 1;
      Preview_Scroll : Natural := 0;
      Marks          : Mark_Vectors.Vector;
      Pending_Action  : Pending_Marked_Action_Kind := No_Pending_Marked_Action;
      Pending_Targets : Mark_Vectors.Vector;
      Pending_Target_Original_Positions : Natural_Vectors.Vector;
      Pruned_Pending_Targets : Pruned_Pending_Target_Vectors.Vector;
      Dirty_Prune_Targets : Mark_Vectors.Vector;
      Removed_Dirty_Prune_Targets : Pruned_Pending_Target_Vectors.Vector;
      Dirty_Prune_Apply_Targets : Mark_Vectors.Vector;
      Removed_Dirty_Prune_Apply_Targets : Pruned_Pending_Target_Vectors.Vector;
      Pending_Count   : Natural := 0;
      Pending_Dirty_Count : Natural := 0;
   end record;

end Editor.Buffer_Switcher;
