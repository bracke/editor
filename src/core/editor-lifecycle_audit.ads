with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.State;

package Editor.Lifecycle_Audit is

   type Lifecycle_Audit_Status is
     (Lifecycle_Audit_Ok,
      Lifecycle_Audit_Failed);

   type Lifecycle_Audit_Result is private;

   type Settings_Lifecycle_Summary is record
      Theme_Id                       : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Line_Number_Mode               : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Cursor_Style                   : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Cursor_Blink_Enabled           : Boolean := True;
      Minimap_Visible                : Boolean := True;
      Scrollbars_Visible             : Boolean := True;
      Command_Palette_Show_Bindings  : Boolean := True;
      Has_Project                    : Boolean := False;
      Dirty_Buffer_Count             : Natural := 0;
      Has_Pending_Transition         : Boolean := False;
      Recent_Project_Count           : Natural := 0;
   end record;

   type Lifecycle_State_Summary is record
      Has_Project                 : Boolean := False;
      Project_Display             : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Buffer_Count                : Natural := 0;
      Dirty_Buffer_Count          : Natural := 0;
      Dirty_File_Backed_Count     : Natural := 0;
      Dirty_Untitled_Count        : Natural := 0;
      Active_Buffer_Exists        : Boolean := False;
      File_Tree_Node_Count        : Natural := 0;
      File_Tree_Expansion_Count   : Natural := 0;
      Project_Search_Result_Count : Natural := 0;
      Search_Results_Row_Count    : Natural := 0;
      Recent_Project_Count        : Natural := 0;
      Has_Pending_Transition      : Boolean := False;
      Pending_Kind_Name           : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Message_Count               : Natural := 0;
   end record;

   --  Reset an audit result to the successful, empty-failure state.
   --  @param Result audit result to clear
   procedure Clear
     (Result : in out Lifecycle_Audit_Result);

   --  Append a deterministic failure message. This does not inspect or mutate
   --  editor state.
   --  @param Result audit result to update
   --  @param Message failure text to append
   procedure Add_Failure
     (Result  : in out Lifecycle_Audit_Result;
      Message : String);

   --  Return the aggregate audit status.
   --  @param Result audit result to inspect
   --  @return Lifecycle_Audit_Failed when at least one failure is present
   function Status
     (Result : Lifecycle_Audit_Result) return Lifecycle_Audit_Status;

   --  Return the number of recorded audit failures.
   --  @param Result audit result to inspect
   --  @return failure count
   function Failure_Count
     (Result : Lifecycle_Audit_Result) return Natural;

   --  Return a one-based failure message.
   --  @param Result audit result to inspect
   --  @param Index one-based failure index
   --  @return failure message, or the empty string when Index is out of range
   function Failure
     (Result : Lifecycle_Audit_Result;
      Index  : Positive) return String;

   --  Return a compact human-readable result summary.
   --  @param Result audit result to summarize
   --  @return deterministic audit summary text
   function Summary
     (Result : Lifecycle_Audit_Result) return String;

   --  Build a side-effect-free lifecycle summary for tests and diagnostics.
   --  This helper does not normalize, repair, validate stale targets, write
   --  files, clear messages, or mutate pending transitions.
   --  @param State editor state to summarize
   --  @return lifecycle-relevant state counters and flags
   function State_Summary
     (State : Editor.State.State_Type) return Lifecycle_State_Summary;


   --  Build a side-effect-free summary of settings-relevant editor state.
   --  This helper is intended for regression tests and lifecycle audits. It
   --  does not normalize, repair, save, reload, apply, or persist settings.
   --  @param State editor state to inspect
   --  @return settings-related summary fields plus lifecycle separation counters
   function Settings_Lifecycle_Summary_For
     (State : Editor.State.State_Type) return Settings_Lifecycle_Summary;

   --  Compare lifecycle summaries and record a failure when they differ in
   --  fields that must remain stable across blocked or read-only operations.
   --  Message count is intentionally excluded by this helper because command
   --  execution may legitimately report one outcome message.
   --  @param Result audit result to update
   --  @param Before expected lifecycle summary
   --  @param After observed lifecycle summary
   --  @param Context failure-message prefix
   procedure Expect_No_Core_Lifecycle_Mutation
     (Result  : in out Lifecycle_Audit_Result;
      Before  : Lifecycle_State_Summary;
      After   : Lifecycle_State_Summary;
      Context : String);

private
   package Failure_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Ada.Strings.Unbounded.Unbounded_String,
      "="          => Ada.Strings.Unbounded."=");

   type Lifecycle_Audit_Result is record
      Failures : Failure_Vectors.Vector;
   end record;

end Editor.Lifecycle_Audit;
