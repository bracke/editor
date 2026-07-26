with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffers;
with Editor.Buffer_Switcher_Model.Audits;
with Editor.Buffer_Switcher_Model.Config;
with Editor.Buffer_Switcher_Model.Filters;
with Editor.Buffer_Switcher_Model.Reviews;
with Editor.Buffer_Switcher_Model.Rows;
with Editor.Input_Field;
with Editor.Project;
with Editor.Recent_Buffers;
with Editor.Buffer_Switcher.Filters;
with Editor.Buffer_Switcher.Labels;
with Editor.Buffer_Switcher.Pending_Close_Operations;
with Editor.Buffer_Switcher.Preview;
with Editor.Buffer_Switcher.Dirty_Prune_Operations;
with Editor.Buffer_Switcher.Review_Operations;
with Editor.Buffer_Switcher.Row_Operations;

package body Editor.Buffer_Switcher is
   subtype Pending_Marked_Action_Kind is
     Editor.Buffer_Switcher_Model.Reviews.Pending_Marked_Action_Kind;
   subtype Switcher_Metadata_Filter_Kind is
     Editor.Buffer_Switcher_Model.Filters.Switcher_Metadata_Filter_Kind;
   subtype Switcher_Metadata_Filter is
     Editor.Buffer_Switcher_Model.Filters.Switcher_Metadata_Filter;
   subtype Switcher_Sort_Mode is
     Editor.Buffer_Switcher_Model.Filters.Switcher_Sort_Mode;
   subtype Switcher_Review_Mode is
     Editor.Buffer_Switcher_Model.Reviews.Switcher_Review_Mode;
   subtype Switcher_Batch_State_Snapshot is
     Editor.Buffer_Switcher_Model.Reviews.Switcher_Batch_State_Snapshot;
   subtype Buffer_Project_Ownership_Kind is
     Editor.Buffer_Switcher_Model.Rows.Buffer_Project_Ownership_Kind;
   subtype Buffer_Switcher_Config is
     Editor.Buffer_Switcher_Model.Config.Buffer_Switcher_Config;
   subtype Selected_Buffer_List_Audit is
     Editor.Buffer_Switcher_Model.Audits.Selected_Buffer_List_Audit;
   subtype Buffer_Switcher_Row is
     Editor.Buffer_Switcher_Model.Rows.Buffer_Switcher_Row;

   No_Pending_Marked_Action : constant Pending_Marked_Action_Kind :=
     Editor.Buffer_Switcher_Model.Reviews.No_Pending_Marked_Action;
   Pending_Marked_Close : constant Pending_Marked_Action_Kind :=
     Editor.Buffer_Switcher_Model.Reviews.Pending_Marked_Close;
   No_Filter : constant Switcher_Metadata_Filter_Kind :=
     Editor.Buffer_Switcher_Model.Filters.No_Filter;
   Pinned_Filter : constant Switcher_Metadata_Filter_Kind :=
     Editor.Buffer_Switcher_Model.Filters.Pinned_Filter;
   Group_Filter : constant Switcher_Metadata_Filter_Kind :=
     Editor.Buffer_Switcher_Model.Filters.Group_Filter;
   Label_Filter : constant Switcher_Metadata_Filter_Kind :=
     Editor.Buffer_Switcher_Model.Filters.Label_Filter;
   Noted_Filter : constant Switcher_Metadata_Filter_Kind :=
     Editor.Buffer_Switcher_Model.Filters.Noted_Filter;
   Dirty_Filter : constant Switcher_Metadata_Filter_Kind :=
     Editor.Buffer_Switcher_Model.Filters.Dirty_Filter;
   Clean_Filter : constant Switcher_Metadata_Filter_Kind :=
     Editor.Buffer_Switcher_Model.Filters.Clean_Filter;
   Missing_Or_Conflict_Filter : constant Switcher_Metadata_Filter_Kind :=
     Editor.Buffer_Switcher_Model.Filters.Missing_Or_Conflict_Filter;
   Project_Owned_Filter : constant Switcher_Metadata_Filter_Kind :=
     Editor.Buffer_Switcher_Model.Filters.Project_Owned_Filter;
   Outside_Project_Filter : constant Switcher_Metadata_Filter_Kind :=
     Editor.Buffer_Switcher_Model.Filters.Outside_Project_Filter;
   Scratch_Filter : constant Switcher_Metadata_Filter_Kind :=
     Editor.Buffer_Switcher_Model.Filters.Scratch_Filter;
   Default_Sort : constant Switcher_Sort_Mode :=
     Editor.Buffer_Switcher_Model.Filters.Default_Sort;
   Recent_Sort : constant Switcher_Sort_Mode :=
     Editor.Buffer_Switcher_Model.Filters.Recent_Sort;
   Name_Sort : constant Switcher_Sort_Mode :=
     Editor.Buffer_Switcher_Model.Filters.Name_Sort;
   Pinned_Sort : constant Switcher_Sort_Mode :=
     Editor.Buffer_Switcher_Model.Filters.Pinned_Sort;
   Group_Sort : constant Switcher_Sort_Mode :=
     Editor.Buffer_Switcher_Model.Filters.Group_Sort;
   Label_Sort : constant Switcher_Sort_Mode :=
     Editor.Buffer_Switcher_Model.Filters.Label_Sort;
   No_Review : constant Switcher_Review_Mode :=
     Editor.Buffer_Switcher_Model.Reviews.No_Review;
   Marked_Review : constant Switcher_Review_Mode :=
     Editor.Buffer_Switcher_Model.Reviews.Marked_Review;
   Pending_Marked_Close_Review : constant Switcher_Review_Mode :=
     Editor.Buffer_Switcher_Model.Reviews.Pending_Marked_Close_Review;
   Pruned_Pending_Close_Review : constant Switcher_Review_Mode :=
     Editor.Buffer_Switcher_Model.Reviews.Pruned_Pending_Close_Review;
   Dirty_Pending_Close_Review : constant Switcher_Review_Mode :=
     Editor.Buffer_Switcher_Model.Reviews.Dirty_Pending_Close_Review;
   Dirty_Prune_Preview_Review : constant Switcher_Review_Mode :=
     Editor.Buffer_Switcher_Model.Reviews.Dirty_Prune_Preview_Review;
   Removed_Dirty_Prune_Preview_Review : constant Switcher_Review_Mode :=
     Editor.Buffer_Switcher_Model.Reviews.Removed_Dirty_Prune_Preview_Review;
   Dirty_Prune_Apply_Review : constant Switcher_Review_Mode :=
     Editor.Buffer_Switcher_Model.Reviews.Dirty_Prune_Apply_Review;
   Removed_Dirty_Prune_Apply_Review : constant Switcher_Review_Mode :=
     Editor.Buffer_Switcher_Model.Reviews.Removed_Dirty_Prune_Apply_Review;
   Buffer_Project_Unknown : constant Buffer_Project_Ownership_Kind :=
     Editor.Buffer_Switcher_Model.Rows.Buffer_Project_Unknown;
   Buffer_Project_Owned : constant Buffer_Project_Ownership_Kind :=
     Editor.Buffer_Switcher_Model.Rows.Buffer_Project_Owned;
   Buffer_Project_Outside : constant Buffer_Project_Ownership_Kind :=
     Editor.Buffer_Switcher_Model.Rows.Buffer_Project_Outside;
   Buffer_Project_Scratch : constant Buffer_Project_Ownership_Kind :=
     Editor.Buffer_Switcher_Model.Rows.Buffer_Project_Scratch;
   Buffer_Project_No_Project : constant Buffer_Project_Ownership_Kind :=
     Editor.Buffer_Switcher_Model.Rows.Buffer_Project_No_Project;

   use type Editor.Buffers.Buffer_Close_Eligibility;
   use type Editor.Buffers.Buffer_Ownership_Kind;
   use type Editor.Buffers.Buffer_Dirty_Category;
   use type Pending_Marked_Action_Kind;
   use type Switcher_Metadata_Filter_Kind;
   use type Switcher_Review_Mode;
   use type Switcher_Sort_Mode;
   use type Ada.Containers.Count_Type;

   procedure Clamp_Window (State : in out Buffer_Switcher_State)
     renames Editor.Buffer_Switcher.Row_Operations.Clamp_Window;

   procedure Clear (State : in out Buffer_Switcher_State) is
   begin
      State.Opened := False;
      Editor.Input_Field.Clear (State.Field);
      State.Rows.Clear;
      State.Selected_Index := 0;
      State.Top_Index := 1;
      State.Visible_Window := 12;
      State.Active_Filter := (Kind => No_Filter, Text => Null_Unbounded_String);
      State.Active_Sort := Default_Sort;
      State.Active_Review := No_Review;
      State.Preview_Visible := False;
      State.Preview_Target_Id := Editor.Buffers.No_Buffer;
      State.Preview_Anchor := 1;
      State.Preview_Scroll := 0;
      State.Marks.Clear;
      Clear_Pending_Marked_Action (State);
   end Clear;

   procedure Open (State : in out Buffer_Switcher_State) is
   begin
      State.Opened := True;
      State.Rows.Clear;
      State.Selected_Index := 0;
      State.Top_Index := 1;
      State.Visible_Window := 12;
      State.Preview_Target_Id := Editor.Buffers.No_Buffer;
      State.Preview_Anchor := 1;
      State.Preview_Scroll := 0;
   end Open;

   procedure Close (State : in out Buffer_Switcher_State) is
   begin
      State.Opened := False;
   end Close;

   function Is_Open (State : Buffer_Switcher_State) return Boolean is
   begin
      return State.Opened;
   end Is_Open;

   function Filter_Text (State : Buffer_Switcher_State) return String is
   begin
      return Editor.Input_Field.Text (State.Field);
   end Filter_Text;

   procedure Set_Filter_Text (State : in out Buffer_Switcher_State; Text : String) is
   begin
      Editor.Input_Field.Set_Text (State.Field, Text);
   end Set_Filter_Text;

   procedure Insert_Text (State : in out Buffer_Switcher_State; Text : String) is
   begin
      Editor.Input_Field.Insert_Text (State.Field, Text);
   end Insert_Text;

   procedure Backspace (State : in out Buffer_Switcher_State) is
   begin
      Editor.Input_Field.Backspace (State.Field);
   end Backspace;

   procedure Delete_Forward (State : in out Buffer_Switcher_State) is
   begin
      Editor.Input_Field.Delete_Forward (State.Field);
   end Delete_Forward;

   procedure Move_Cursor_Left (State : in out Buffer_Switcher_State) is
   begin
      Editor.Input_Field.Move_Cursor_Left (State.Field);
   end Move_Cursor_Left;

   procedure Move_Cursor_Right (State : in out Buffer_Switcher_State) is
   begin
      Editor.Input_Field.Move_Cursor_Right (State.Field);
   end Move_Cursor_Right;

   procedure Move_Cursor_Start (State : in out Buffer_Switcher_State) is
   begin
      Editor.Input_Field.Move_Cursor_Start (State.Field);
   end Move_Cursor_Start;

   procedure Move_Cursor_End (State : in out Buffer_Switcher_State) is
   begin
      Editor.Input_Field.Move_Cursor_End (State.Field);
   end Move_Cursor_End;

   procedure Select_All (State : in out Buffer_Switcher_State) is
   begin
      Editor.Input_Field.Select_All (State.Field);
   end Select_All;

   procedure Clear_Metadata_Filter
     (State : in out Buffer_Switcher_State) renames
     Editor.Buffer_Switcher.Filters.Clear_Metadata_Filter;

   procedure Set_Pinned_Filter
     (State : in out Buffer_Switcher_State) renames
     Editor.Buffer_Switcher.Filters.Set_Pinned_Filter;

   procedure Set_Group_Filter
     (State : in out Buffer_Switcher_State;
      Name  : String) renames
     Editor.Buffer_Switcher.Filters.Set_Group_Filter;

   procedure Set_Label_Filter
     (State : in out Buffer_Switcher_State;
      Label : String) renames
     Editor.Buffer_Switcher.Filters.Set_Label_Filter;

   procedure Set_Noted_Filter
     (State : in out Buffer_Switcher_State) renames
     Editor.Buffer_Switcher.Filters.Set_Noted_Filter;

   procedure Set_Dirty_Filter
     (State : in out Buffer_Switcher_State) renames
     Editor.Buffer_Switcher.Filters.Set_Dirty_Filter;

   procedure Set_Clean_Filter
     (State : in out Buffer_Switcher_State) renames
     Editor.Buffer_Switcher.Filters.Set_Clean_Filter;

   procedure Set_Missing_Or_Conflict_Filter
     (State : in out Buffer_Switcher_State) renames
     Editor.Buffer_Switcher.Filters.Set_Missing_Or_Conflict_Filter;

   procedure Set_Project_Owned_Filter
     (State : in out Buffer_Switcher_State) renames
     Editor.Buffer_Switcher.Filters.Set_Project_Owned_Filter;

   procedure Set_Outside_Project_Filter
     (State : in out Buffer_Switcher_State) renames
     Editor.Buffer_Switcher.Filters.Set_Outside_Project_Filter;

   procedure Set_Scratch_Filter
     (State : in out Buffer_Switcher_State) renames
     Editor.Buffer_Switcher.Filters.Set_Scratch_Filter;

   function Has_Metadata_Filter
     (State : Buffer_Switcher_State) return Boolean renames
     Editor.Buffer_Switcher.Filters.Has_Metadata_Filter;

   function Metadata_Filter
     (State : Buffer_Switcher_State) return Switcher_Metadata_Filter renames
     Editor.Buffer_Switcher.Filters.Metadata_Filter;

   function Metadata_Filter_Description
     (State : Buffer_Switcher_State) return String renames
     Editor.Buffer_Switcher.Filters.Metadata_Filter_Description;

   procedure Set_Sort_Mode
     (State : in out Buffer_Switcher_State;
      Mode  : Switcher_Sort_Mode) renames
     Editor.Buffer_Switcher.Filters.Set_Sort_Mode;

   procedure Clear_Sort_Mode
     (State : in out Buffer_Switcher_State) renames
     Editor.Buffer_Switcher.Filters.Clear_Sort_Mode;

   procedure Next_Sort_Mode
     (State : in out Buffer_Switcher_State) renames
     Editor.Buffer_Switcher.Filters.Next_Sort_Mode;

   procedure Previous_Sort_Mode
     (State : in out Buffer_Switcher_State) renames
     Editor.Buffer_Switcher.Filters.Previous_Sort_Mode;

   function Sort_Mode
     (State : Buffer_Switcher_State) return Switcher_Sort_Mode renames
     Editor.Buffer_Switcher.Filters.Sort_Mode;

   function Sort_Mode_Description
     (State : Buffer_Switcher_State) return String renames
     Editor.Buffer_Switcher.Filters.Sort_Mode_Description;

   function Build_Open_Buffer_Switcher_Row_From_Buffer_Snapshot
     (Summary : Editor.Buffers.Buffer_Summary) return Buffer_Switcher_Row
   is
   begin
      return
        (Id            => Summary.Id,
         Display_Label => To_Unbounded_String (To_String (Summary.Display_Name)),
         Is_Dirty      => Summary.Is_Dirty,
         Is_Active     => Summary.Is_Active,
         Has_Path      => Summary.Has_Path,
         Path          => Summary.Path,
         Project_Ownership => (if Summary.Has_Path then Buffer_Project_Unknown else Buffer_Project_Scratch),
         Project_Ownership_Label => To_Unbounded_String ((if Summary.Has_Path then "project unknown" else "scratch")),
         Lifecycle_Status_Label => To_Unbounded_String ((if Summary.Is_Dirty then "Modified" else (if Summary.Has_Path then "Clean" else "Scratch"))),
         Workspace_Persistability_Label => To_Unbounded_String ((if Summary.Has_Path then "Workspace file reference" else "Runtime-only buffer")),
         Close_Eligibility_Label => To_Unbounded_String
           ((if Summary.Blocked_Close_Surfaced then "Blocked by pending confirmation"
             elsif not Summary.Is_Dirty then "Closable clean"
             elsif Summary.Missing_Target_Surfaced or else Summary.External_Change_Surfaced then
                "Requires conflict resolution or discard"
             elsif (not Summary.Has_Path)
               or else Summary.Unwritable_Target_Surfaced
               or else Summary.Last_Save_Failed
               or else Summary.Unreadable_Target_Surfaced
               or else Summary.Last_Reload_Failed
               or else Summary.Last_Revert_Failed
             then "Requires save-as or discard"
             else "Requires dirty confirmation")),
         Stale_Backing_State => Summary.Missing_Target_Surfaced or else Summary.External_Change_Surfaced,
         Is_Project_Owned => False,
         Is_Outside_Project => False,
         Is_File_Backed => Summary.Has_Path,
         Is_Unbacked    => not Summary.Has_Path,
         Last_Save_Failed => Summary.Last_Save_Failed,
         Last_Reload_Failed => Summary.Last_Reload_Failed,
         Last_Revert_Failed => Summary.Last_Revert_Failed,
         Missing_Target_Surfaced => Summary.Missing_Target_Surfaced,
         Unreadable_Target_Surfaced => Summary.Unreadable_Target_Surfaced,
         Unwritable_Target_Surfaced => Summary.Unwritable_Target_Surfaced,
         External_Change_Surfaced => Summary.External_Change_Surfaced,
         Blocked_Close_Surfaced  => Summary.Blocked_Close_Surfaced,
         Is_Pinned     => Summary.Is_Pinned,
         Has_Group     => Summary.Has_Group,
         Group_Name    => To_Unbounded_String (To_String (Summary.Group_Name)),
         Has_Label     => Summary.Has_Label,
         Label_Text    => To_Unbounded_String (To_String (Summary.Label_Text)),
         Has_Note      => Summary.Has_Note,
         Is_Marked     => False,
         Is_Pending_Close_Target => False,
         Is_Ordinary_Pruned_Target => False,
         Is_Dirty_Prune_Preview_Target => False,
         Is_Removed_Dirty_Prune_Preview_Target => False,
         Is_Dirty_Prune_Apply_Target => False,
         Is_Removed_Dirty_Prune_Apply_Target => False);
   end Build_Open_Buffer_Switcher_Row_From_Buffer_Snapshot;


   function Switcher_Ownership_Kind
     (Kind : Editor.Buffers.Buffer_Ownership_Kind) return Buffer_Project_Ownership_Kind
   is
   begin
      case Kind is
         when Editor.Buffers.Buffer_Project_Owned =>
            return Buffer_Project_Owned;
         when Editor.Buffers.Buffer_Outside_Project =>
            return Buffer_Project_Outside;
         when Editor.Buffers.Buffer_Scratch_Unbacked =>
            return Buffer_Project_Scratch;
         when Editor.Buffers.Buffer_Missing_Project_Context =>
            return Buffer_Project_No_Project;
         when Editor.Buffers.Buffer_Unknown_File_Backed =>
            return Buffer_Project_Unknown;
      end case;
   end Switcher_Ownership_Kind;

   function Build_Open_Buffer_Switcher_Row_From_Metadata_Snapshot
     (Metadata : Editor.Buffers.Buffer_Metadata_Snapshot;
      Summary  : Editor.Buffers.Buffer_Summary) return Buffer_Switcher_Row
   is
      Ownership : constant Buffer_Project_Ownership_Kind :=
        Switcher_Ownership_Kind (Metadata.Ownership);
   begin
      return
        (Id            => Metadata.Id,
         Display_Label => Editor.Buffer_Switcher.Labels.Metadata_Display_Label (Metadata),
         Is_Dirty      => Metadata.Is_Dirty,
         Is_Active     => Metadata.Is_Active,
         Has_Path      => Metadata.Has_File_Path,
         Path          => Metadata.File_Path,
         Project_Ownership => Ownership,
         Project_Ownership_Label =>
           To_Unbounded_String
             (Editor.Buffer_Switcher.Labels.Buffer_Project_Ownership_Label (Ownership)),
         Lifecycle_Status_Label => Metadata.Lifecycle_Status_Label,
         Workspace_Persistability_Label =>
           To_Unbounded_String
             (Editor.Buffers.Workspace_Persistability_Label
                (Metadata.Workspace_Persistability)),
         Close_Eligibility_Label =>
           To_Unbounded_String
             (Editor.Buffers.Close_Eligibility_Label
                (Metadata.Close_Eligibility)),
         Stale_Backing_State => Metadata.Stale_Backing_State,
         Is_Project_Owned => Metadata.Ownership = Editor.Buffers.Buffer_Project_Owned,
         Is_Outside_Project => Metadata.Ownership = Editor.Buffers.Buffer_Outside_Project,
         Is_File_Backed => Metadata.Has_File_Path,
         Is_Unbacked    => Metadata.Is_Scratch,
         Last_Save_Failed => Summary.Last_Save_Failed,
         Last_Reload_Failed => Summary.Last_Reload_Failed,
         Last_Revert_Failed => Summary.Last_Revert_Failed,
         Missing_Target_Surfaced => Metadata.Missing_Backing_File,
         Unreadable_Target_Surfaced => Metadata.Unreadable,
         Unwritable_Target_Surfaced => Metadata.Unwritable,
         External_Change_Surfaced => Metadata.External_Conflict,
         Blocked_Close_Surfaced  =>
           Metadata.Close_Eligibility = Editor.Buffers.Buffer_Blocked_By_Pending_Confirmation,
         Is_Pinned     => Summary.Is_Pinned,
         Has_Group     => Summary.Has_Group,
         Group_Name    => To_Unbounded_String (To_String (Summary.Group_Name)),
         Has_Label     => Summary.Has_Label,
         Label_Text    => To_Unbounded_String (To_String (Summary.Label_Text)),
         Has_Note      => Summary.Has_Note,
         Is_Marked     => False,
         Is_Pending_Close_Target => False,
         Is_Ordinary_Pruned_Target => False,
         Is_Dirty_Prune_Preview_Target => False,
         Is_Removed_Dirty_Prune_Preview_Target => False,
         Is_Dirty_Prune_Apply_Target => False,
         Is_Removed_Dirty_Prune_Apply_Target => False);
   end Build_Open_Buffer_Switcher_Row_From_Metadata_Snapshot;

   function Buffer_Row_State_Markers
     (Row : Buffer_Switcher_Row) return String
       renames Editor.Buffer_Switcher.Labels.Buffer_Row_State_Markers;

   function Buffer_Row_Metadata_Render_Label
     (Row : Buffer_Switcher_Row) return String
       renames Editor.Buffer_Switcher.Labels.Buffer_Row_Metadata_Render_Label;

   function Buffer_Project_Ownership_Label
     (Kind : Buffer_Project_Ownership_Kind) return String
       renames Editor.Buffer_Switcher.Labels.Buffer_Project_Ownership_Label;

   procedure Apply_Project_Ownership
     (Row     : in out Buffer_Switcher_Row;
      Project : Editor.Project.Project_State)
       renames Editor.Buffer_Switcher.Labels.Apply_Project_Ownership;

   function Buffer_List_Empty_State_Label
     (State              : Buffer_Switcher_State;
      Open_Buffer_Count  : Natural) return String
   is
   begin
      if Open_Buffer_Count = 0 then
         return "No open buffers";
      elsif Has_Removed_Dirty_Prune_Apply_Review (State) then
         return "No removed dirty-prune apply targets";
      elsif Has_Dirty_Prune_Apply_Review (State) then
         return "No dirty-prune apply targets";
      elsif Has_Removed_Dirty_Prune_Review (State) then
         return "No removed dirty-prune preview targets";
      elsif Has_Dirty_Prune_Review (State) then
         return "No dirty-prune preview targets";
      elsif Has_Dirty_Pending_Marked_Review (State) then
         return "No dirty pending close targets";
      elsif Has_Pruned_Pending_Marked_Review (State) then
         return "No pruned pending close targets";
      elsif Has_Pending_Marked_Review (State) then
         return "No pending marked targets";
      elsif Has_Marked_Review (State) then
         return "No marked buffers";
      elsif Has_Metadata_Filter (State) or else Filter_Text (State)'Length /= 0 then
         return "No matching open buffers";
      else
         return "No matches";
      end if;
   end Buffer_List_Empty_State_Label;

   function Open_Buffer_Switcher_No_Duplicate_Lifecycle_State
     (State : Buffer_Switcher_State) return Boolean
   is
      pragma Unreferenced (State);
   begin
      --  There are no switcher-owned path-label caches, dirty-indicator
      --  caches, filesystem probe caches, association repair caches, or file
      --  lifecycle operation/target-history fields in Buffer_Switcher_State.
      return True;
   end Open_Buffer_Switcher_No_Duplicate_Lifecycle_State;

   function Open_Buffer_Switcher_No_Prompt_State
     (State : Buffer_Switcher_State) return Boolean
   is
      pragma Unreferenced (State);
   begin
      --  Target prompt ownership remains in the canonical Executor prompt
      --  state.  The switcher state retains only its query input field and
      --  local UI selection/review state.
      return True;
   end Open_Buffer_Switcher_No_Prompt_State;

   function Open_Buffer_Switcher_No_File_Lifecycle_Source_Override
     (State : Buffer_Switcher_State) return Boolean
   is
      pragma Unreferenced (State);
   begin
      --  File lifecycle commands continue to use the canonical active-buffer
      --  source; switcher selection is local UI state only.
      return True;
   end Open_Buffer_Switcher_No_File_Lifecycle_Source_Override;

   function Open_Buffer_Switcher_File_Lifecycle_Observation_Frozen
     (State : Buffer_Switcher_State) return Boolean
   is
   begin
      --  final freeze: the switcher retains only UI projection
      --  state.  Lifecycle-visible row data is rebuilt from buffer summaries
      --  by Build_Open_Buffer_Switcher_Row_From_Buffer_Snapshot; the state
      --  model has no duplicated lifecycle cache, prompt ownership, source
      --  override, target history, operation history, probe, repair, or
      --  persistence-adjacent field to consult.
      return Open_Buffer_Switcher_No_Duplicate_Lifecycle_State (State)
        and then Open_Buffer_Switcher_No_Prompt_State (State)
        and then Open_Buffer_Switcher_No_File_Lifecycle_Source_Override (State);
   end Open_Buffer_Switcher_File_Lifecycle_Observation_Frozen;

   procedure Set_Switcher_Review_Mode
     (State : in out Buffer_Switcher_State;
      Mode  : Switcher_Review_Mode) is
   begin
      Editor.Buffer_Switcher.Review_Operations.Set_Switcher_Review_Mode (State, Mode);
   end Set_Switcher_Review_Mode;

   procedure Clear_Switcher_Review_Mode
     (State : in out Buffer_Switcher_State;
      Mode  : Switcher_Review_Mode) is
   begin
      Editor.Buffer_Switcher.Review_Operations.Clear_Switcher_Review_Mode (State, Mode);
   end Clear_Switcher_Review_Mode;

   procedure Toggle_Switcher_Review_Mode
     (State : in out Buffer_Switcher_State;
      Mode  : Switcher_Review_Mode) is
   begin
      Editor.Buffer_Switcher.Review_Operations.Toggle_Switcher_Review_Mode (State, Mode);
   end Toggle_Switcher_Review_Mode;

   function Has_Switcher_Review_Mode
     (State : Buffer_Switcher_State;
      Mode  : Switcher_Review_Mode) return Boolean is
   begin
      return Editor.Buffer_Switcher.Review_Operations.Has_Switcher_Review_Mode (State, Mode);
   end Has_Switcher_Review_Mode;

   procedure Clear_Dirty_Prune_Apply_Review_Modes
     (State : in out Buffer_Switcher_State) is
   begin
      Editor.Buffer_Switcher.Review_Operations.Clear_Dirty_Prune_Apply_Review_Modes (State);
   end Clear_Dirty_Prune_Apply_Review_Modes;

   procedure Clear_Dirty_Prune_Preview_Review_Modes
     (State : in out Buffer_Switcher_State) is
   begin
      Editor.Buffer_Switcher.Review_Operations.Clear_Dirty_Prune_Preview_Review_Modes (State);
   end Clear_Dirty_Prune_Preview_Review_Modes;

   procedure Clear_Pending_Marked_Review_Modes
     (State : in out Buffer_Switcher_State) is
   begin
      Editor.Buffer_Switcher.Review_Operations.Clear_Pending_Marked_Review_Modes (State);
   end Clear_Pending_Marked_Review_Modes;

   procedure Show_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      Editor.Buffer_Switcher.Review_Operations.Show_Marked_Review (State);
   end Show_Marked_Review;

   procedure Hide_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      Editor.Buffer_Switcher.Review_Operations.Hide_Marked_Review (State);
   end Hide_Marked_Review;

   procedure Toggle_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      Editor.Buffer_Switcher.Review_Operations.Toggle_Marked_Review (State);
   end Toggle_Marked_Review;

   function Has_Marked_Review (State : Buffer_Switcher_State) return Boolean is
   begin
      return Editor.Buffer_Switcher.Review_Operations.Has_Marked_Review (State);
   end Has_Marked_Review;

   function Marked_Review_Description (State : Buffer_Switcher_State) return String is
   begin
      return Editor.Buffer_Switcher.Review_Operations.Marked_Review_Description (State);
   end Marked_Review_Description;

   procedure Show_Pending_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      Editor.Buffer_Switcher.Review_Operations.Show_Pending_Marked_Review (State);
   end Show_Pending_Marked_Review;

   procedure Hide_Pending_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      Editor.Buffer_Switcher.Review_Operations.Hide_Pending_Marked_Review (State);
   end Hide_Pending_Marked_Review;

   procedure Toggle_Pending_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      Editor.Buffer_Switcher.Review_Operations.Toggle_Pending_Marked_Review (State);
   end Toggle_Pending_Marked_Review;

   function Has_Pending_Marked_Review (State : Buffer_Switcher_State) return Boolean is
   begin
      return Editor.Buffer_Switcher.Review_Operations.Has_Pending_Marked_Review (State);
   end Has_Pending_Marked_Review;

   function Pending_Marked_Review_Description (State : Buffer_Switcher_State) return String is
   begin
      return Editor.Buffer_Switcher.Review_Operations.Pending_Marked_Review_Description (State);
   end Pending_Marked_Review_Description;

   procedure Show_Pruned_Pending_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      Editor.Buffer_Switcher.Review_Operations.Show_Pruned_Pending_Marked_Review (State);
   end Show_Pruned_Pending_Marked_Review;

   procedure Hide_Pruned_Pending_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      Editor.Buffer_Switcher.Review_Operations.Hide_Pruned_Pending_Marked_Review (State);
   end Hide_Pruned_Pending_Marked_Review;

   procedure Toggle_Pruned_Pending_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      Editor.Buffer_Switcher.Review_Operations.Toggle_Pruned_Pending_Marked_Review (State);
   end Toggle_Pruned_Pending_Marked_Review;

   function Has_Pruned_Pending_Marked_Review (State : Buffer_Switcher_State) return Boolean is
   begin
      return Editor.Buffer_Switcher.Review_Operations.Has_Pruned_Pending_Marked_Review (State);
   end Has_Pruned_Pending_Marked_Review;

   function Pruned_Pending_Marked_Review_Description (State : Buffer_Switcher_State) return String is
   begin
      return Editor.Buffer_Switcher.Review_Operations.Pruned_Pending_Marked_Review_Description (State);
   end Pruned_Pending_Marked_Review_Description;

   procedure Show_Dirty_Pending_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      Editor.Buffer_Switcher.Review_Operations.Show_Dirty_Pending_Marked_Review (State);
   end Show_Dirty_Pending_Marked_Review;

   procedure Hide_Dirty_Pending_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      Editor.Buffer_Switcher.Review_Operations.Hide_Dirty_Pending_Marked_Review (State);
   end Hide_Dirty_Pending_Marked_Review;

   procedure Toggle_Dirty_Pending_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      Editor.Buffer_Switcher.Review_Operations.Toggle_Dirty_Pending_Marked_Review (State);
   end Toggle_Dirty_Pending_Marked_Review;

   function Has_Dirty_Pending_Marked_Review (State : Buffer_Switcher_State) return Boolean is
   begin
      return Editor.Buffer_Switcher.Review_Operations.Has_Dirty_Pending_Marked_Review (State);
   end Has_Dirty_Pending_Marked_Review;

   function Dirty_Pending_Marked_Review_Description (State : Buffer_Switcher_State) return String is
   begin
      return Editor.Buffer_Switcher.Review_Operations.Dirty_Pending_Marked_Review_Description (State);
   end Dirty_Pending_Marked_Review_Description;

   procedure Show_Dirty_Prune_Review (State : in out Buffer_Switcher_State) is
   begin
      Editor.Buffer_Switcher.Review_Operations.Show_Dirty_Prune_Review (State);
   end Show_Dirty_Prune_Review;

   procedure Hide_Dirty_Prune_Review (State : in out Buffer_Switcher_State) is
   begin
      Editor.Buffer_Switcher.Review_Operations.Hide_Dirty_Prune_Review (State);
   end Hide_Dirty_Prune_Review;

   procedure Toggle_Dirty_Prune_Review (State : in out Buffer_Switcher_State) is
   begin
      Editor.Buffer_Switcher.Review_Operations.Toggle_Dirty_Prune_Review (State);
   end Toggle_Dirty_Prune_Review;

   function Has_Dirty_Prune_Review (State : Buffer_Switcher_State) return Boolean is
   begin
      return Editor.Buffer_Switcher.Review_Operations.Has_Dirty_Prune_Review (State);
   end Has_Dirty_Prune_Review;

   function Dirty_Prune_Review_Description (State : Buffer_Switcher_State) return String is
   begin
      return Editor.Buffer_Switcher.Review_Operations.Dirty_Prune_Review_Description (State);
   end Dirty_Prune_Review_Description;

   procedure Show_Removed_Dirty_Prune_Review (State : in out Buffer_Switcher_State) is
   begin
      Editor.Buffer_Switcher.Review_Operations.Show_Removed_Dirty_Prune_Review (State);
   end Show_Removed_Dirty_Prune_Review;

   procedure Hide_Removed_Dirty_Prune_Review (State : in out Buffer_Switcher_State) is
   begin
      Editor.Buffer_Switcher.Review_Operations.Hide_Removed_Dirty_Prune_Review (State);
   end Hide_Removed_Dirty_Prune_Review;

   procedure Toggle_Removed_Dirty_Prune_Review (State : in out Buffer_Switcher_State) is
   begin
      Editor.Buffer_Switcher.Review_Operations.Toggle_Removed_Dirty_Prune_Review (State);
   end Toggle_Removed_Dirty_Prune_Review;

   function Has_Removed_Dirty_Prune_Review (State : Buffer_Switcher_State) return Boolean is
   begin
      return Editor.Buffer_Switcher.Review_Operations.Has_Removed_Dirty_Prune_Review (State);
   end Has_Removed_Dirty_Prune_Review;

   function Removed_Dirty_Prune_Review_Description (State : Buffer_Switcher_State) return String is
   begin
      return Editor.Buffer_Switcher.Review_Operations.Removed_Dirty_Prune_Review_Description (State);
   end Removed_Dirty_Prune_Review_Description;

   procedure Show_Dirty_Prune_Apply_Review (State : in out Buffer_Switcher_State) is
   begin
      Editor.Buffer_Switcher.Review_Operations.Show_Dirty_Prune_Apply_Review (State);
   end Show_Dirty_Prune_Apply_Review;

   procedure Hide_Dirty_Prune_Apply_Review (State : in out Buffer_Switcher_State) is
   begin
      Editor.Buffer_Switcher.Review_Operations.Hide_Dirty_Prune_Apply_Review (State);
   end Hide_Dirty_Prune_Apply_Review;

   procedure Toggle_Dirty_Prune_Apply_Review (State : in out Buffer_Switcher_State) is
   begin
      Editor.Buffer_Switcher.Review_Operations.Toggle_Dirty_Prune_Apply_Review (State);
   end Toggle_Dirty_Prune_Apply_Review;

   function Has_Dirty_Prune_Apply_Review (State : Buffer_Switcher_State) return Boolean is
   begin
      return Editor.Buffer_Switcher.Review_Operations.Has_Dirty_Prune_Apply_Review (State);
   end Has_Dirty_Prune_Apply_Review;

   function Dirty_Prune_Apply_Review_Description (State : Buffer_Switcher_State) return String is
   begin
      return Editor.Buffer_Switcher.Review_Operations.Dirty_Prune_Apply_Review_Description (State);
   end Dirty_Prune_Apply_Review_Description;

   procedure Show_Removed_Dirty_Prune_Apply_Review (State : in out Buffer_Switcher_State) is
   begin
      Editor.Buffer_Switcher.Review_Operations.Show_Removed_Dirty_Prune_Apply_Review (State);
   end Show_Removed_Dirty_Prune_Apply_Review;

   procedure Hide_Removed_Dirty_Prune_Apply_Review (State : in out Buffer_Switcher_State) is
   begin
      Editor.Buffer_Switcher.Review_Operations.Hide_Removed_Dirty_Prune_Apply_Review (State);
   end Hide_Removed_Dirty_Prune_Apply_Review;

   procedure Toggle_Removed_Dirty_Prune_Apply_Review (State : in out Buffer_Switcher_State) is
   begin
      Editor.Buffer_Switcher.Review_Operations.Toggle_Removed_Dirty_Prune_Apply_Review (State);
   end Toggle_Removed_Dirty_Prune_Apply_Review;

   function Has_Removed_Dirty_Prune_Apply_Review (State : Buffer_Switcher_State) return Boolean is
   begin
      return Editor.Buffer_Switcher.Review_Operations.Has_Removed_Dirty_Prune_Apply_Review (State);
   end Has_Removed_Dirty_Prune_Apply_Review;

   function Removed_Dirty_Prune_Apply_Review_Description (State : Buffer_Switcher_State) return String is
   begin
      return Editor.Buffer_Switcher.Review_Operations.Removed_Dirty_Prune_Apply_Review_Description (State);
   end Removed_Dirty_Prune_Apply_Review_Description;

   function Assert_Multi_Buffer_Management_Coherent
     (State : Buffer_Switcher_State) return Boolean
   is
   begin
      if not Open_Buffer_Switcher_File_Lifecycle_Observation_Frozen (State) then
         return False;
      end if;

      if State.Rows.Is_Empty then
         return State.Selected_Index = 0;
      end if;

      if State.Selected_Index < 1
        or else State.Selected_Index > Natural (State.Rows.Length)
      then
         return False;
      end if;

      for Index in State.Rows.First_Index .. State.Rows.Last_Index loop
         declare
            Row : constant Buffer_Switcher_Row := State.Rows.Element (Index);
            Label : constant String := To_String (Row.Display_Label);
            Ownership_Label : constant String := To_String (Row.Project_Ownership_Label);
         begin
            if Row.Id = Editor.Buffers.No_Buffer then
               return False;
            end if;

            if Label'Length = 0 or else Label'Length > 240 then
               return False;
            end if;

            for Ch of Label loop
               if Ch = ASCII.LF or else Ch = ASCII.CR then
                  return False;
               end if;
            end loop;

            if Row.Has_Path /= (Length (Row.Path) > 0) then
               return False;
            end if;

            case Row.Project_Ownership is
               when Buffer_Project_Owned =>
                  if not Row.Is_Project_Owned
                    or else Row.Is_Outside_Project
                    or else Ownership_Label /= "project"
                  then
                     return False;
                  end if;
               when Buffer_Project_Outside =>
                  if Row.Is_Project_Owned
                    or else not Row.Is_Outside_Project
                    or else Ownership_Label /= "outside project"
                  then
                     return False;
                  end if;
               when Buffer_Project_Scratch =>
                  if Row.Is_File_Backed
                    or else not Row.Is_Unbacked
                    or else Ownership_Label /= "scratch"
                  then
                     return False;
                  end if;
               when Buffer_Project_No_Project =>
                  if Row.Is_Project_Owned
                    or else Row.Is_Outside_Project
                    or else Ownership_Label /= "no project"
                  then
                     return False;
                  end if;
               when Buffer_Project_Unknown =>
                  if Row.Is_Project_Owned
                    or else Row.Is_Outside_Project
                    or else Ownership_Label /= "project unknown"
                  then
                     return False;
                  end if;
            end case;
         end;
      end loop;

      return True;
   end Assert_Multi_Buffer_Management_Coherent;


   function Is_Pending_Marked_Close_Target
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffers.Buffer_Id) return Boolean renames
     Pending_Close_Operations.Is_Pending_Marked_Close_Target;

   function Row_Is_Dirty_Prune_Target
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffers.Buffer_Id) return Boolean renames
     Dirty_Prune_Operations.Is_Dirty_Pending_Marked_Close_Prune_Target;


   function Row_Is_Dirty_Prune_Apply_Target
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffers.Buffer_Id) return Boolean renames
     Dirty_Prune_Operations.Is_Dirty_Pending_Marked_Close_Prune_Apply_Target;

   function Row_Is_Pending_Marked_Target
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffers.Buffer_Id) return Boolean
   is
   begin
      return Is_Pending_Marked_Close_Target (State, Id);
   end Row_Is_Pending_Marked_Target;

   function Build_Switcher_Row_Markers
     (State : Buffer_Switcher_State;
      Row   : Buffer_Switcher_Row) return Buffer_Switcher_Row renames
     Pending_Close_Operations.Build_Switcher_Row_Markers;

   function Has_Pruned_Pending_Marked_Close_Targets
     (State : Buffer_Switcher_State) return Boolean renames
     Pending_Close_Operations.Has_Pruned_Pending_Marked_Close_Targets;

   function Pruned_Pending_Marked_Close_Target_Count
     (State : Buffer_Switcher_State) return Natural renames
     Pending_Close_Operations.Pruned_Pending_Marked_Close_Target_Count;

   function Open_Pruned_Pending_Marked_Close_Target_Count
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural renames
     Pending_Close_Operations.Open_Pruned_Pending_Marked_Close_Target_Count;

   function Last_Pruned_Pending_Marked_Close_Target_Name
     (State : Buffer_Switcher_State) return String renames
     Pending_Close_Operations.Last_Pruned_Pending_Marked_Close_Target_Name;

   function Is_Pruned_Pending_Marked_Close_Target
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffers.Buffer_Id) return Boolean renames
     Pending_Close_Operations.Is_Pruned_Pending_Marked_Close_Target;

   procedure Prepare_Dirty_Pending_Marked_Close_Prune
     (State    : in out Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry;
      Count    : out Natural) renames
     Dirty_Prune_Operations.Prepare_Dirty_Pending_Marked_Close_Prune;

   function Has_Dirty_Pending_Marked_Close_Prune
     (State : Buffer_Switcher_State) return Boolean renames
     Dirty_Prune_Operations.Has_Dirty_Pending_Marked_Close_Prune;

   function Dirty_Pending_Marked_Close_Prune_Target_Count
     (State : Buffer_Switcher_State) return Natural renames
     Dirty_Prune_Operations.Dirty_Pending_Marked_Close_Prune_Target_Count;

   function Applicable_Dirty_Pending_Marked_Close_Prune_Target_Count
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural renames
     Dirty_Prune_Operations.Applicable_Dirty_Pending_Marked_Close_Prune_Target_Count;

   function Dirty_Pending_Marked_Close_Prune_Stale_Target_Count
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural renames
     Dirty_Prune_Operations.Dirty_Pending_Marked_Close_Prune_Stale_Target_Count;

   function Has_Stale_Dirty_Pending_Marked_Close_Prune_Targets
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Boolean renames
     Dirty_Prune_Operations.Has_Stale_Dirty_Pending_Marked_Close_Prune_Targets;

   procedure Clear_Stale_Dirty_Pending_Marked_Close_Prune_Targets
     (State     : in out Buffer_Switcher_State;
      Registry  : Editor.Buffers.Buffer_Registry;
      Cleared   : out Natural;
      Remaining : out Natural) renames
     Dirty_Prune_Operations.Clear_Stale_Dirty_Pending_Marked_Close_Prune_Targets;

   function Is_Dirty_Pending_Marked_Close_Prune_Target
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffers.Buffer_Id) return Boolean renames
     Dirty_Prune_Operations.Is_Dirty_Pending_Marked_Close_Prune_Target;

   procedure Remove_Dirty_Pending_Marked_Close_Prune_Target
     (State     : in out Buffer_Switcher_State;
      Registry  : Editor.Buffers.Buffer_Registry;
      Id        : Editor.Buffers.Buffer_Id;
      Removed   : out Boolean;
      Remaining : out Natural) renames
     Dirty_Prune_Operations.Remove_Dirty_Pending_Marked_Close_Prune_Target;

   function Has_Removed_Dirty_Pending_Marked_Close_Prune_Targets
     (State : Buffer_Switcher_State) return Boolean renames
     Dirty_Prune_Operations.Has_Removed_Dirty_Pending_Marked_Close_Prune_Targets;

   function Removed_Dirty_Pending_Marked_Close_Prune_Target_Count
     (State : Buffer_Switcher_State) return Natural renames
     Dirty_Prune_Operations.Removed_Dirty_Pending_Marked_Close_Prune_Target_Count;

   function Open_Removed_Dirty_Pending_Marked_Close_Prune_Target_Count
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural renames
     Dirty_Prune_Operations.Open_Removed_Dirty_Pending_Marked_Close_Prune_Target_Count;

   function Last_Removed_Dirty_Pending_Marked_Close_Prune_Target_Name
     (State : Buffer_Switcher_State) return String renames
     Dirty_Prune_Operations.Last_Removed_Dirty_Pending_Marked_Close_Prune_Target_Name;

   function Is_Removed_Dirty_Pending_Marked_Close_Prune_Target
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffers.Buffer_Id) return Boolean renames
     Dirty_Prune_Operations.Is_Removed_Dirty_Pending_Marked_Close_Prune_Target;

   procedure Restore_Last_Removed_Dirty_Pending_Marked_Close_Prune_Target
     (State        : in out Buffer_Switcher_State;
      Registry     : Editor.Buffers.Buffer_Registry;
      Restored     : out Boolean;
      Target       : out Editor.Buffers.Buffer_Id;
      Display_Name : out Ada.Strings.Unbounded.Unbounded_String;
      Remaining    : out Natural) renames
     Dirty_Prune_Operations.Restore_Last_Removed_Dirty_Pending_Marked_Close_Prune_Target;

   procedure Cancel_Dirty_Pending_Marked_Close_Prune
     (State : in out Buffer_Switcher_State) renames
     Dirty_Prune_Operations.Cancel_Dirty_Pending_Marked_Close_Prune;

   procedure Apply_Dirty_Pending_Marked_Close_Prune
     (State     : in out Buffer_Switcher_State;
      Registry  : Editor.Buffers.Buffer_Registry;
      Applied   : out Natural;
      Remaining : out Natural) renames
     Dirty_Prune_Operations.Apply_Dirty_Pending_Marked_Close_Prune;

   procedure Prepare_Dirty_Pending_Marked_Close_Prune_Apply
     (State      : in out Buffer_Switcher_State;
      Registry   : Editor.Buffers.Buffer_Registry;
      Count      : out Natural;
      Applicable : out Natural) renames
     Dirty_Prune_Operations.Prepare_Dirty_Pending_Marked_Close_Prune_Apply;

   function Has_Dirty_Pending_Marked_Close_Prune_Apply
     (State : Buffer_Switcher_State) return Boolean renames
     Dirty_Prune_Operations.Has_Dirty_Pending_Marked_Close_Prune_Apply;

   function Dirty_Pending_Marked_Close_Prune_Apply_Target_Count
     (State : Buffer_Switcher_State) return Natural renames
     Dirty_Prune_Operations.Dirty_Pending_Marked_Close_Prune_Apply_Target_Count;

   function Applicable_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural renames
     Dirty_Prune_Operations.Applicable_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count;

   function Dirty_Pending_Marked_Close_Prune_Apply_Stale_Target_Count
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural renames
     Dirty_Prune_Operations.Dirty_Pending_Marked_Close_Prune_Apply_Stale_Target_Count;

   procedure Clear_Stale_Dirty_Pending_Marked_Close_Prune_Apply_Targets
     (State     : in out Buffer_Switcher_State;
      Registry  : Editor.Buffers.Buffer_Registry;
      Cleared   : out Natural;
      Remaining : out Natural) renames
     Dirty_Prune_Operations.Clear_Stale_Dirty_Pending_Marked_Close_Prune_Apply_Targets;

   function Is_Dirty_Pending_Marked_Close_Prune_Apply_Target
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffers.Buffer_Id) return Boolean renames
     Dirty_Prune_Operations.Is_Dirty_Pending_Marked_Close_Prune_Apply_Target;

   procedure Remove_Dirty_Pending_Marked_Close_Prune_Apply_Target
     (State     : in out Buffer_Switcher_State;
      Registry  : Editor.Buffers.Buffer_Registry;
      Id        : Editor.Buffers.Buffer_Id;
      Removed   : out Boolean;
      Remaining : out Natural) renames
     Dirty_Prune_Operations.Remove_Dirty_Pending_Marked_Close_Prune_Apply_Target;

   function Has_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Targets
     (State : Buffer_Switcher_State) return Boolean renames
     Dirty_Prune_Operations.Has_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Targets;

   function Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count
     (State : Buffer_Switcher_State) return Natural renames
     Dirty_Prune_Operations.Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count;

   function Open_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural renames
     Dirty_Prune_Operations.Open_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count;

   function Last_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target_Name
     (State : Buffer_Switcher_State) return String renames
     Dirty_Prune_Operations.Last_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target_Name;

   function Is_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffers.Buffer_Id) return Boolean renames
     Dirty_Prune_Operations.Is_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target;

   procedure Restore_Last_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target
     (State        : in out Buffer_Switcher_State;
      Registry     : Editor.Buffers.Buffer_Registry;
      Restored     : out Boolean;
      Target       : out Editor.Buffers.Buffer_Id;
      Display_Name : out Ada.Strings.Unbounded.Unbounded_String;
      Remaining    : out Natural) renames
     Dirty_Prune_Operations.Restore_Last_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target;

   procedure Confirm_Dirty_Pending_Marked_Close_Prune_Apply
     (State     : in out Buffer_Switcher_State;
      Registry  : Editor.Buffers.Buffer_Registry;
      Applied   : out Natural;
      Skipped   : out Natural;
      Remaining : out Natural) renames
     Dirty_Prune_Operations.Confirm_Dirty_Pending_Marked_Close_Prune_Apply;

   procedure Cancel_Dirty_Pending_Marked_Close_Prune_Apply
     (State : in out Buffer_Switcher_State) renames
     Dirty_Prune_Operations.Cancel_Dirty_Pending_Marked_Close_Prune_Apply;


   procedure Clear_Pending_Marked_Action (State : in out Buffer_Switcher_State) renames
     Pending_Close_Operations.Clear_Pending_Marked_Action;

   function Pending_Marked_Action (State : Buffer_Switcher_State) return Pending_Marked_Action_Kind renames
     Pending_Close_Operations.Pending_Marked_Action;

   function Pending_Marked_Target_Count (State : Buffer_Switcher_State) return Natural renames
     Pending_Close_Operations.Pending_Marked_Target_Count;

   function Pending_Marked_Dirty_Count (State : Buffer_Switcher_State) return Natural renames
     Pending_Close_Operations.Pending_Marked_Dirty_Count;

   function Pending_Marked_Target_At
     (State : Buffer_Switcher_State;
      Index : Positive) return Editor.Buffers.Buffer_Id renames
     Pending_Close_Operations.Pending_Marked_Target_At;

   procedure Prepare_Pending_Marked_Close
     (State       : in out Buffer_Switcher_State;
      Registry    : Editor.Buffers.Buffer_Registry;
      Count       : out Natural;
      Dirty_Count : out Natural) renames
     Pending_Close_Operations.Prepare_Pending_Marked_Close;

   function Pending_Marked_Open_Count
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural renames
     Pending_Close_Operations.Pending_Marked_Open_Count;

   function Pending_Marked_Open_Dirty_Count
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural renames
     Pending_Close_Operations.Pending_Marked_Open_Dirty_Count;

   procedure Remove_Pending_Marked_Close_Target
     (State       : in out Buffer_Switcher_State;
      Registry    : Editor.Buffers.Buffer_Registry;
      Id          : Editor.Buffers.Buffer_Id;
      Removed     : out Boolean;
      Remaining   : out Natural) renames
     Pending_Close_Operations.Remove_Pending_Marked_Close_Target;

   procedure Restore_Last_Pruned_Pending_Marked_Close_Target
     (State        : in out Buffer_Switcher_State;
      Registry     : Editor.Buffers.Buffer_Registry;
      Restored     : out Boolean;
      Target       : out Editor.Buffers.Buffer_Id;
      Display_Name : out Ada.Strings.Unbounded.Unbounded_String;
      Remaining    : out Natural) renames
     Pending_Close_Operations.Restore_Last_Pruned_Pending_Marked_Close_Target;

   procedure Restore_Pruned_Pending_Marked_Close_Target
     (State        : in out Buffer_Switcher_State;
      Registry     : Editor.Buffers.Buffer_Registry;
      Id           : Editor.Buffers.Buffer_Id;
      Restored     : out Boolean;
      Display_Name : out Ada.Strings.Unbounded.Unbounded_String;
      Remaining    : out Natural) renames
     Pending_Close_Operations.Restore_Pruned_Pending_Marked_Close_Target;

   procedure Recompute_Rows
     (State    : in out Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry;
      Config   : Buffer_Switcher_Config) renames
      Row_Operations.Recompute_Rows;

   procedure Recompute_Rows
     (State    : in out Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State;
      Config   : Buffer_Switcher_Config) renames
      Row_Operations.Recompute_Rows;

   procedure Recompute_Rows
     (State    : in out Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State;
      Project  : Editor.Project.Project_State;
      Config   : Buffer_Switcher_Config) renames
      Row_Operations.Recompute_Rows;

   procedure Move_Selection_Down (State : in out Buffer_Switcher_State) is
   begin
      Row_Operations.Move_Selection_Down (State);
   end Move_Selection_Down;

   procedure Move_Selection_Up (State : in out Buffer_Switcher_State) is
   begin
      Row_Operations.Move_Selection_Up (State);
   end Move_Selection_Up;

   procedure Show_Preview (State : in out Buffer_Switcher_State) is
   begin
      Preview.Show_Preview (State);
   end Show_Preview;

   procedure Hide_Preview (State : in out Buffer_Switcher_State) is
   begin
      Preview.Hide_Preview (State);
   end Hide_Preview;

   procedure Toggle_Preview (State : in out Buffer_Switcher_State) is
   begin
      Preview.Toggle_Preview (State);
   end Toggle_Preview;

   function Has_Preview (State : Buffer_Switcher_State) return Boolean is
   begin
      return Preview.Has_Preview (State);
   end Has_Preview;

   procedure Set_Preview_Target
     (State       : in out Buffer_Switcher_State;
      Target      : Editor.Buffers.Buffer_Id;
      Anchor_Line : Natural)
   is
   begin
      Preview.Set_Preview_Target (State, Target, Anchor_Line);
   end Set_Preview_Target;

   procedure Clear_Preview_Target (State : in out Buffer_Switcher_State) is
   begin
      Preview.Clear_Preview_Target (State);
   end Clear_Preview_Target;

   function Preview_Target (State : Buffer_Switcher_State) return Editor.Buffers.Buffer_Id is
   begin
      return Preview.Preview_Target (State);
   end Preview_Target;

   function Preview_Anchor_Line (State : Buffer_Switcher_State) return Natural is
   begin
      return Preview.Preview_Anchor_Line (State);
   end Preview_Anchor_Line;

   function Preview_Scroll_Offset (State : Buffer_Switcher_State) return Natural is
   begin
      return Preview.Preview_Scroll_Offset (State);
   end Preview_Scroll_Offset;

   procedure Scroll_Preview_Next_Line (State : in out Buffer_Switcher_State) is
   begin
      Preview.Scroll_Preview_Next_Line (State);
   end Scroll_Preview_Next_Line;

   procedure Scroll_Preview_Previous_Line (State : in out Buffer_Switcher_State) is
   begin
      Preview.Scroll_Preview_Previous_Line (State);
   end Scroll_Preview_Previous_Line;

   procedure Center_Preview_On_Line
     (State       : in out Buffer_Switcher_State;
      Anchor_Line : Natural)
   is
   begin
      Preview.Center_Preview_On_Line (State, Anchor_Line);
   end Center_Preview_On_Line;

   procedure Select_Buffer_Or_Row
     (State          : in out Buffer_Switcher_State;
      Preferred_Id   : Editor.Buffers.Buffer_Id;
      Fallback_Index : Natural)
   is
   begin
      Row_Operations.Select_Buffer_Or_Row (State, Preferred_Id, Fallback_Index);
   end Select_Buffer_Or_Row;

   function Select_Next_Pruned_Pending_Marked_Buffer
     (State : in out Buffer_Switcher_State) return Boolean is
   begin
      return Row_Operations.Select_Next_Pruned_Pending_Marked_Buffer (State);
   end Select_Next_Pruned_Pending_Marked_Buffer;

   function Select_Previous_Pruned_Pending_Marked_Buffer
     (State : in out Buffer_Switcher_State) return Boolean is
   begin
      return Row_Operations.Select_Previous_Pruned_Pending_Marked_Buffer (State);
   end Select_Previous_Pruned_Pending_Marked_Buffer;

   function Select_Next_Dirty_Pending_Marked_Buffer
     (State : in out Buffer_Switcher_State) return Boolean is
   begin
      return Row_Operations.Select_Next_Dirty_Pending_Marked_Buffer (State);
   end Select_Next_Dirty_Pending_Marked_Buffer;

   function Select_Previous_Dirty_Pending_Marked_Buffer
     (State : in out Buffer_Switcher_State) return Boolean is
   begin
      return Row_Operations.Select_Previous_Dirty_Pending_Marked_Buffer (State);
   end Select_Previous_Dirty_Pending_Marked_Buffer;

   function Select_Next_Dirty_Prune_Target
     (State : in out Buffer_Switcher_State) return Boolean is
   begin
      return Row_Operations.Select_Next_Dirty_Prune_Target (State);
   end Select_Next_Dirty_Prune_Target;

   function Select_Previous_Dirty_Prune_Target
     (State : in out Buffer_Switcher_State) return Boolean is
   begin
      return Row_Operations.Select_Previous_Dirty_Prune_Target (State);
   end Select_Previous_Dirty_Prune_Target;

   function Select_Next_Removed_Dirty_Prune_Target
     (State : in out Buffer_Switcher_State) return Boolean is
   begin
      return Row_Operations.Select_Next_Removed_Dirty_Prune_Target (State);
   end Select_Next_Removed_Dirty_Prune_Target;

   function Select_Previous_Removed_Dirty_Prune_Target
     (State : in out Buffer_Switcher_State) return Boolean is
   begin
      return Row_Operations.Select_Previous_Removed_Dirty_Prune_Target (State);
   end Select_Previous_Removed_Dirty_Prune_Target;

   function Select_Next_Pending_Marked_Buffer
     (State : in out Buffer_Switcher_State) return Boolean is
   begin
      return Row_Operations.Select_Next_Pending_Marked_Buffer (State);
   end Select_Next_Pending_Marked_Buffer;

   function Select_Previous_Pending_Marked_Buffer
     (State : in out Buffer_Switcher_State) return Boolean is
   begin
      return Row_Operations.Select_Previous_Pending_Marked_Buffer (State);
   end Select_Previous_Pending_Marked_Buffer;

   function Select_Next_Dirty_Prune_Apply_Target
     (State : in out Buffer_Switcher_State) return Boolean is
   begin
      return Row_Operations.Select_Next_Dirty_Prune_Apply_Target (State);
   end Select_Next_Dirty_Prune_Apply_Target;

   function Select_Previous_Dirty_Prune_Apply_Target
     (State : in out Buffer_Switcher_State) return Boolean is
   begin
      return Row_Operations.Select_Previous_Dirty_Prune_Apply_Target (State);
   end Select_Previous_Dirty_Prune_Apply_Target;

   function Select_Next_Removed_Dirty_Prune_Apply_Target
     (State : in out Buffer_Switcher_State) return Boolean is
   begin
      return Row_Operations.Select_Next_Removed_Dirty_Prune_Apply_Target (State);
   end Select_Next_Removed_Dirty_Prune_Apply_Target;

   function Select_Previous_Removed_Dirty_Prune_Apply_Target
     (State : in out Buffer_Switcher_State) return Boolean is
   begin
      return Row_Operations.Select_Previous_Removed_Dirty_Prune_Apply_Target (State);
   end Select_Previous_Removed_Dirty_Prune_Apply_Target;


   procedure Toggle_Mark
     (State : in out Buffer_Switcher_State;
      Id    : Editor.Buffers.Buffer_Id) renames
     Editor.Buffer_Switcher.Review_Operations.Toggle_Mark;

   procedure Set_Mark
     (State : in out Buffer_Switcher_State;
      Id    : Editor.Buffers.Buffer_Id) renames
     Editor.Buffer_Switcher.Review_Operations.Set_Mark;

   procedure Clear_Mark
     (State : in out Buffer_Switcher_State;
      Id    : Editor.Buffers.Buffer_Id) renames
     Editor.Buffer_Switcher.Review_Operations.Clear_Mark;

   procedure Clear_All_Marks
     (State : in out Buffer_Switcher_State) renames
     Editor.Buffer_Switcher.Review_Operations.Clear_All_Marks;

   function Is_Marked
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffers.Buffer_Id) return Boolean renames
     Editor.Buffer_Switcher.Review_Operations.Is_Marked;

   function Marked_Count
     (State : Buffer_Switcher_State) return Natural renames
     Editor.Buffer_Switcher.Review_Operations.Marked_Count;

   function Open_Marked_Count
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural renames
     Editor.Buffer_Switcher.Review_Operations.Open_Marked_Count;

   function Build_Switcher_Batch_State_Snapshot
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Switcher_Batch_State_Snapshot renames
     Editor.Buffer_Switcher.Review_Operations.Build_Switcher_Batch_State_Snapshot;

   function Header_Badge_Text
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return String renames
     Editor.Buffer_Switcher.Review_Operations.Header_Badge_Text;

   function Footer_Badge_Text
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return String renames
     Editor.Buffer_Switcher.Review_Operations.Footer_Badge_Text;

   function Count_Badge_Text
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return String renames
     Editor.Buffer_Switcher.Review_Operations.Count_Badge_Text;

   function Has_Marks
     (State : Buffer_Switcher_State) return Boolean renames
     Editor.Buffer_Switcher.Review_Operations.Has_Marks;

   procedure Invert_Visible_Marks
     (State          : in out Buffer_Switcher_State;
      Marked_Count   : out Natural;
      Unmarked_Count : out Natural) renames
     Editor.Buffer_Switcher.Review_Operations.Invert_Visible_Marks;

   procedure Mark_Visible_Marks
     (State : in out Buffer_Switcher_State;
      Count : out Natural) renames
     Editor.Buffer_Switcher.Review_Operations.Mark_Visible_Marks;

   procedure Clear_Visible_Marks
     (State : in out Buffer_Switcher_State;
      Count : out Natural) renames
     Editor.Buffer_Switcher.Review_Operations.Clear_Visible_Marks;

   procedure Prune_Marks
     (State    : in out Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) renames
     Editor.Buffer_Switcher.Review_Operations.Prune_Marks;


   function Select_Next_Marked_Buffer
     (State : in out Buffer_Switcher_State) return Boolean renames
     Row_Operations.Select_Next_Marked_Buffer;

   function Select_Previous_Marked_Buffer
     (State : in out Buffer_Switcher_State) return Boolean renames
     Row_Operations.Select_Previous_Marked_Buffer;

   function Row_Count (State : Buffer_Switcher_State) return Natural is
   begin
      return Row_Operations.Row_Count (State);
   end Row_Count;

   function Selected_Row_Index (State : Buffer_Switcher_State) return Natural is
   begin
      return Row_Operations.Selected_Row_Index (State);
   end Selected_Row_Index;

   function Top_Row_Index (State : Buffer_Switcher_State) return Natural is
   begin
      return Row_Operations.Top_Row_Index (State);
   end Top_Row_Index;

   function Row_At (State : Buffer_Switcher_State; Index : Positive) return Buffer_Switcher_Row is
   begin
      return Row_Operations.Row_At (State, Index);
   end Row_At;

   function Row_For_Buffer
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffers.Buffer_Id;
      Found : out Boolean) return Buffer_Switcher_Row
   is
   begin
      return Row_Operations.Row_For_Buffer (State, Id, Found);
   end Row_For_Buffer;

   function Selected_Row
     (State : Buffer_Switcher_State;
      Found : out Boolean) return Buffer_Switcher_Row is
   begin
      return Row_Operations.Selected_Row (State, Found);
   end Selected_Row;

   function Audit_Selected_Buffer_List_State
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Selected_Buffer_List_Audit
   is
   begin
      return Row_Operations.Audit_Selected_Buffer_List_State (State, Registry);
   end Audit_Selected_Buffer_List_State;

   function Query_Snapshot
     (State           : Buffer_Switcher_State;
      Visible_Columns : Natural) return Editor.Input_Field.Field_Snapshot is
   begin
      return Row_Operations.Query_Snapshot (State, Visible_Columns);
   end Query_Snapshot;

   function Geometry
     (Body_Rect   : Editor.Layout.Rect;
      Config      : Buffer_Switcher_Config;
      Cell_Width  : Positive;
      Cell_Height : Positive) return Editor.Layout.Rect
   is
   begin
      return Row_Operations.Geometry (Body_Rect, Config, Cell_Width, Cell_Height);
   end Geometry;

end Editor.Buffer_Switcher;
