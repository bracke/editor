with Ada.Containers.Vectors;
with Ada.Characters.Handling;
with Ada.Strings.Fixed;
with Ada.Strings;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffers;
with Editor.Input_Field;
with Editor.Project;
with Editor.Recent_Buffers;
with Editor.Buffer_Switcher.Labels;
with Editor.Buffer_Switcher.Pending_Close_Operations;
with Editor.Buffer_Switcher.Dirty_Prune_Operations;
with Editor.Buffer_Switcher.Review_Operations;
with Editor.Buffer_Switcher.Row_Operations;

package body Editor.Buffer_Switcher is
   use type Editor.Buffers.Buffer_Close_Eligibility;
   use type Editor.Buffers.Buffer_Ownership_Kind;
   use type Editor.Buffers.Buffer_Dirty_Category;
   use type Editor.Buffer_Switcher.Pending_Marked_Action_Kind;
   use type Editor.Buffer_Switcher.Switcher_Metadata_Filter_Kind;
   use type Editor.Buffer_Switcher.Switcher_Review_Mode;
   use type Editor.Buffer_Switcher.Switcher_Sort_Mode;
   use type Ada.Containers.Count_Type;

   No_Recent_Rank : constant Natural := Natural'Last;

   type Switcher_Candidate is record
      Summary       : Editor.Buffers.Buffer_Summary;
      Metadata      : Editor.Buffers.Buffer_Metadata_Snapshot;
      Default_Index : Natural := 0;
      Recent_Rank   : Natural := No_Recent_Rank;
   end record;

   package Candidate_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Switcher_Candidate);

   function Lower (Text : String) return String
     renames Editor.Buffer_Switcher.Row_Operations.Lower;

   function Contains (Text, Part : String) return Boolean
     renames Editor.Buffer_Switcher.Row_Operations.Contains;

   function Matches_Metadata_Filter
     (Summary : Editor.Buffers.Buffer_Summary;
      Filter  : Switcher_Metadata_Filter) return Boolean
     renames Editor.Buffer_Switcher.Row_Operations.Matches_Metadata_Filter;

   function Matches_Buffer_State_Filter
     (Row    : Buffer_Switcher_Row;
      Filter : Switcher_Metadata_Filter) return Boolean
     renames Editor.Buffer_Switcher.Row_Operations.Matches_Buffer_State_Filter;

   function Trimmed (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trimmed;

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

   procedure Clear_Metadata_Filter (State : in out Buffer_Switcher_State) is
   begin
      State.Active_Filter := (Kind => No_Filter, Text => Null_Unbounded_String);
   end Clear_Metadata_Filter;

   procedure Set_Pinned_Filter (State : in out Buffer_Switcher_State) is
   begin
      State.Active_Filter := (Kind => Pinned_Filter, Text => Null_Unbounded_String);
   end Set_Pinned_Filter;

   procedure Set_Group_Filter (State : in out Buffer_Switcher_State; Name : String) is
      Group : constant String := Trimmed (Name);
   begin
      State.Active_Filter := (Kind => Group_Filter, Text => To_Unbounded_String (Group));
   end Set_Group_Filter;

   procedure Set_Label_Filter (State : in out Buffer_Switcher_State; Label : String) is
      Text : constant String := Trimmed (Label);
   begin
      State.Active_Filter := (Kind => Label_Filter, Text => To_Unbounded_String (Text));
   end Set_Label_Filter;

   procedure Set_Noted_Filter (State : in out Buffer_Switcher_State) is
   begin
      State.Active_Filter := (Kind => Noted_Filter, Text => Null_Unbounded_String);
   end Set_Noted_Filter;

   procedure Set_Dirty_Filter (State : in out Buffer_Switcher_State) is
   begin
      State.Active_Filter := (Kind => Dirty_Filter, Text => Null_Unbounded_String);
   end Set_Dirty_Filter;

   procedure Set_Clean_Filter (State : in out Buffer_Switcher_State) is
   begin
      State.Active_Filter := (Kind => Clean_Filter, Text => Null_Unbounded_String);
   end Set_Clean_Filter;

   procedure Set_Missing_Or_Conflict_Filter (State : in out Buffer_Switcher_State) is
   begin
      State.Active_Filter := (Kind => Missing_Or_Conflict_Filter, Text => Null_Unbounded_String);
   end Set_Missing_Or_Conflict_Filter;

   procedure Set_Project_Owned_Filter (State : in out Buffer_Switcher_State) is
   begin
      State.Active_Filter := (Kind => Project_Owned_Filter, Text => Null_Unbounded_String);
   end Set_Project_Owned_Filter;

   procedure Set_Outside_Project_Filter (State : in out Buffer_Switcher_State) is
   begin
      State.Active_Filter := (Kind => Outside_Project_Filter, Text => Null_Unbounded_String);
   end Set_Outside_Project_Filter;

   procedure Set_Scratch_Filter (State : in out Buffer_Switcher_State) is
   begin
      State.Active_Filter := (Kind => Scratch_Filter, Text => Null_Unbounded_String);
   end Set_Scratch_Filter;

   function Has_Metadata_Filter (State : Buffer_Switcher_State) return Boolean is
   begin
      return State.Active_Filter.Kind /= No_Filter;
   end Has_Metadata_Filter;

   function Metadata_Filter (State : Buffer_Switcher_State) return Switcher_Metadata_Filter is
   begin
      return State.Active_Filter;
   end Metadata_Filter;

   function Metadata_Filter_Description (State : Buffer_Switcher_State) return String is
   begin
      case State.Active_Filter.Kind is
         when No_Filter =>
            return "";
         when Pinned_Filter =>
            return "pinned";
         when Group_Filter =>
            return "group " & To_String (State.Active_Filter.Text);
         when Label_Filter =>
            return "label " & To_String (State.Active_Filter.Text);
         when Noted_Filter =>
            return "noted";
         when Dirty_Filter =>
            return "dirty buffers";
         when Clean_Filter =>
            return "clean buffers";
         when Missing_Or_Conflict_Filter =>
            return "missing or conflicted buffers";
         when Project_Owned_Filter =>
            return "project buffers";
         when Outside_Project_Filter =>
            return "outside project buffers";
         when Scratch_Filter =>
            return "scratch buffers";
      end case;
   end Metadata_Filter_Description;

   procedure Set_Sort_Mode (State : in out Buffer_Switcher_State; Mode : Switcher_Sort_Mode) is
   begin
      State.Active_Sort := Mode;
   end Set_Sort_Mode;

   procedure Clear_Sort_Mode (State : in out Buffer_Switcher_State) is
   begin
      State.Active_Sort := Default_Sort;
   end Clear_Sort_Mode;

   procedure Next_Sort_Mode (State : in out Buffer_Switcher_State) is
   begin
      if State.Active_Sort = Switcher_Sort_Mode'Last then
         State.Active_Sort := Switcher_Sort_Mode'First;
      else
         State.Active_Sort := Switcher_Sort_Mode'Succ (State.Active_Sort);
      end if;
   end Next_Sort_Mode;

   procedure Previous_Sort_Mode (State : in out Buffer_Switcher_State) is
   begin
      if State.Active_Sort = Switcher_Sort_Mode'First then
         State.Active_Sort := Switcher_Sort_Mode'Last;
      else
         State.Active_Sort := Switcher_Sort_Mode'Pred (State.Active_Sort);
      end if;
   end Previous_Sort_Mode;

   function Sort_Mode (State : Buffer_Switcher_State) return Switcher_Sort_Mode is
   begin
      return State.Active_Sort;
   end Sort_Mode;

   function Sort_Mode_Description (State : Buffer_Switcher_State) return String is
   begin
      case State.Active_Sort is
         when Default_Sort =>
            return "default";
         when Recent_Sort =>
            return "recent";
         when Name_Sort =>
            return "name";
         when Pinned_Sort =>
            return "pinned first";
         when Group_Sort =>
            return "group";
         when Label_Sort =>
            return "label";
      end case;
   end Sort_Mode_Description;

   function Recent_Rank
     (Recent : Editor.Recent_Buffers.Recent_Buffer_State;
      Id     : Editor.Buffers.Buffer_Id) return Natural
   is
   begin
      for I in 1 .. Editor.Recent_Buffers.Count (Recent) loop
         if Editor.Recent_Buffers.Id_At (Recent, I) = Natural (Id) then
            return I;
         end if;
      end loop;
      return No_Recent_Rank;
   end Recent_Rank;

   function Name_Sort_Ownership_Priority
     (Kind : Editor.Buffers.Buffer_Ownership_Kind) return Natural
   is
   begin
      case Kind is
         when Editor.Buffers.Buffer_Project_Owned =>
            return 1;
         when Editor.Buffers.Buffer_Outside_Project =>
            return 2;
         when Editor.Buffers.Buffer_Scratch_Unbacked =>
            return 3;
         when Editor.Buffers.Buffer_Missing_Project_Context =>
            return 4;
         when Editor.Buffers.Buffer_Unknown_File_Backed =>
            return 5;
      end case;
   end Name_Sort_Ownership_Priority;

   function Candidate_Base_Name (Candidate : Switcher_Candidate) return String is
      Path : constant String := To_String (Candidate.Metadata.File_Path);
      Last_Sep : Natural := 0;
   begin
      if Candidate.Metadata.Has_File_Path then
         for I in Path'Range loop
            if Path (I) = '/' or else Path (I) = '\' then
               Last_Sep := I;
            end if;
         end loop;
         if Last_Sep = 0 then
            return Path;
         elsif Last_Sep < Path'Last then
            return Path (Last_Sep + 1 .. Path'Last);
         else
            return "";
         end if;
      else
         return To_String (Candidate.Summary.Display_Name);
      end if;
   end Candidate_Base_Name;

   function Candidate_Before
     (Left, Right : Switcher_Candidate;
      Mode        : Switcher_Sort_Mode) return Boolean
   is
      Left_Name  : constant String := Lower (To_String (Left.Summary.Display_Name));
      Right_Name : constant String := Lower (To_String (Right.Summary.Display_Name));
      Left_Base  : constant String := Lower (Candidate_Base_Name (Left));
      Right_Base : constant String := Lower (Candidate_Base_Name (Right));
      Left_Group : constant String := Lower (To_String (Left.Summary.Group_Name));
      Right_Group : constant String := Lower (To_String (Right.Summary.Group_Name));
      Left_Label : constant String := Lower (To_String (Left.Summary.Label_Text));
      Right_Label : constant String := Lower (To_String (Right.Summary.Label_Text));
   begin
      case Mode is
         when Default_Sort =>
            null;

         when Recent_Sort =>
            if Left.Recent_Rank /= Right.Recent_Rank then
               return Left.Recent_Rank < Right.Recent_Rank;
            end if;

         when Name_Sort =>
            if Left_Base /= Right_Base then
               return Left_Base < Right_Base;
            elsif Name_Sort_Ownership_Priority (Left.Metadata.Ownership) /=
              Name_Sort_Ownership_Priority (Right.Metadata.Ownership)
            then
               return Name_Sort_Ownership_Priority (Left.Metadata.Ownership) <
                 Name_Sort_Ownership_Priority (Right.Metadata.Ownership);
            elsif Left.Metadata.Has_Project_Relative_Path
              and then Right.Metadata.Has_Project_Relative_Path
              and then To_String (Left.Metadata.Project_Relative_Path) /=
                To_String (Right.Metadata.Project_Relative_Path)
            then
               return To_String (Left.Metadata.Project_Relative_Path) <
                 To_String (Right.Metadata.Project_Relative_Path);
            elsif Left_Name /= Right_Name then
               return Left_Name < Right_Name;
            elsif To_String (Left.Summary.Display_Name) /= To_String (Right.Summary.Display_Name) then
               return To_String (Left.Summary.Display_Name) < To_String (Right.Summary.Display_Name);
            end if;

         when Pinned_Sort =>
            if Left.Summary.Is_Pinned /= Right.Summary.Is_Pinned then
               return Left.Summary.Is_Pinned;
            end if;

         when Group_Sort =>
            if Left.Summary.Has_Group /= Right.Summary.Has_Group then
               return Left.Summary.Has_Group;
            elsif Left.Summary.Has_Group and then Left_Group /= Right_Group then
               return Left_Group < Right_Group;
            elsif Left.Summary.Has_Group
              and then To_String (Left.Summary.Group_Name) /= To_String (Right.Summary.Group_Name)
            then
               return To_String (Left.Summary.Group_Name) < To_String (Right.Summary.Group_Name);
            end if;

         when Label_Sort =>
            if Left.Summary.Has_Label /= Right.Summary.Has_Label then
               return Left.Summary.Has_Label;
            elsif Left.Summary.Has_Label and then Left_Label /= Right_Label then
               return Left_Label < Right_Label;
            elsif Left.Summary.Has_Label
              and then To_String (Left.Summary.Label_Text) /= To_String (Right.Summary.Label_Text)
            then
               return To_String (Left.Summary.Label_Text) < To_String (Right.Summary.Label_Text);
            end if;
      end case;

      return Left.Default_Index < Right.Default_Index;
   end Candidate_Before;

   procedure Sort_Candidates
     (Items : in out Candidate_Vectors.Vector;
      Mode  : Switcher_Sort_Mode)
   is
   begin
      if Natural (Items.Length) < 2 then
         return;
      end if;

      for I in Items.First_Index + 1 .. Items.Last_Index loop
         declare
            Key : constant Switcher_Candidate := Items (I);
            J   : Natural := I;
         begin
            while J > Items.First_Index and then Candidate_Before (Key, Items (J - 1), Mode) loop
               Items.Replace_Element (J, Items (J - 1));
               J := J - 1;
            end loop;
            Items.Replace_Element (J, Key);
         end;
      end loop;
   end Sort_Candidates;



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

   function Row_From_Candidate (Candidate : Switcher_Candidate) return Buffer_Switcher_Row is
   begin
      return Build_Open_Buffer_Switcher_Row_From_Metadata_Snapshot
        (Candidate.Metadata, Candidate.Summary);
   end Row_From_Candidate;

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


   use Editor.Buffer_Switcher.Review_Operations;

   function Is_Pending_Marked_Close_Target
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffers.Buffer_Id) return Boolean renames
     Pending_Close_Operations.Is_Pending_Marked_Close_Target;

   function Row_Is_Dirty_Prune_Target
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffers.Buffer_Id) return Boolean
   is
   begin
      for I in 1 .. Natural (State.Dirty_Prune_Targets.Length) loop
         if State.Dirty_Prune_Targets (I - 1) = Id then
            return True;
         end if;
      end loop;
      return False;
   end Row_Is_Dirty_Prune_Target;


   function Row_Is_Dirty_Prune_Apply_Target
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffers.Buffer_Id) return Boolean
   is
   begin
      if Id = Editor.Buffers.No_Buffer then
         return False;
      end if;
      for I in 1 .. Natural (State.Dirty_Prune_Apply_Targets.Length) loop
         if State.Dirty_Prune_Apply_Targets (I - 1) = Id then
            return True;
         end if;
      end loop;
      return False;
   end Row_Is_Dirty_Prune_Apply_Target;

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

   function Matches_Active_Review_Constraint
     (State    : Buffer_Switcher_State;
      Summary  : Editor.Buffers.Buffer_Summary;
      Metadata : Editor.Buffers.Buffer_Metadata_Snapshot) return Boolean
   is
   begin
      case State.Active_Review is
         when No_Review =>
            return True;
         when Marked_Review =>
            return Is_Marked (State, Summary.Id);
         when Pending_Marked_Close_Review =>
            return Row_Is_Pending_Marked_Target (State, Summary.Id);
         when Pruned_Pending_Close_Review =>
            return Is_Pruned_Pending_Marked_Close_Target (State, Summary.Id);
         when Dirty_Pending_Close_Review =>
            return Metadata.Dirty_Category /= Editor.Buffers.Buffer_Not_Dirty
              and then Row_Is_Pending_Marked_Target (State, Summary.Id);
         when Dirty_Prune_Preview_Review =>
            return Row_Is_Dirty_Prune_Target (State, Summary.Id);
         when Removed_Dirty_Prune_Preview_Review =>
            return Is_Removed_Dirty_Pending_Marked_Close_Prune_Target (State, Summary.Id);
         when Dirty_Prune_Apply_Review =>
            return Row_Is_Dirty_Prune_Apply_Target (State, Summary.Id);
         when Removed_Dirty_Prune_Apply_Review =>
            return Is_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target (State, Summary.Id);
      end case;
   end Matches_Active_Review_Constraint;

   procedure Recompute_Rows
     (State    : in out Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry;
      Config   : Buffer_Switcher_Config)
   is
      Empty_Recent : Editor.Recent_Buffers.Recent_Buffer_State;
   begin
      Recompute_Rows (State, Registry, Empty_Recent, Config);
   end Recompute_Rows;


   procedure Recompute_Rows
     (State    : in out Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State;
      Config   : Buffer_Switcher_Config)
   is
      No_Project : Editor.Project.Project_State;
   begin
      Recompute_Rows (State, Registry, Recent, No_Project, Config);
   end Recompute_Rows;

   procedure Recompute_Rows
     (State    : in out Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State;
      Project  : Editor.Project.Project_State;
      Config   : Buffer_Switcher_Config)
   is
      Filter : constant String := Lower (Editor.Input_Field.Text (State.Field));
      Active : constant Editor.Buffers.Buffer_Id := Editor.Buffers.Active_Buffer (Registry);
      Previous_Selected : constant Natural := State.Selected_Index;
      Previous_Selected_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Active_Row : Natural := 0;
      Preserved_Selected_Row : Natural := 0;
      Candidates : Candidate_Vectors.Vector;
   begin
      State.Visible_Window := Natural'Max (1, Config.Max_Visible_Results);
      if Previous_Selected /= 0 and then Previous_Selected <= Natural (State.Rows.Length) then
         Previous_Selected_Id := State.Rows (Previous_Selected - 1).Id;
      end if;
      State.Rows.Clear;

      for I in 1 .. Editor.Buffers.Count (Registry) loop
         declare
            Summary : constant Editor.Buffers.Buffer_Summary :=
              Editor.Buffers.Summary_At (Registry, I);
            Metadata : constant Editor.Buffers.Buffer_Metadata_Snapshot :=
              Editor.Buffers.Metadata_For (Registry, Project, Summary.Id);
            Label : constant String := To_String (Metadata.Display_Label);
            Path_Label : constant String := To_String (Metadata.File_Path);
            Project_Label : constant String := To_String (Metadata.Project_Relative_Path);
            Outside_Label : constant String := To_String (Metadata.Outside_Project_Path_Label);
         begin
            if Summary.Id /= Editor.Buffers.No_Buffer
              and then Matches_Active_Review_Constraint (State, Summary, Metadata)
              and then Matches_Metadata_Filter (Summary, State.Active_Filter)
              and then (Contains (Lower (Label), Filter)
                        or else (Metadata.Has_File_Path and then Contains (Lower (Path_Label), Filter))
                        or else (Metadata.Has_Project_Relative_Path and then Contains (Lower (Project_Label), Filter))
                        or else (Metadata.Has_Outside_Project_Path_Label and then Contains (Lower (Outside_Label), Filter)))
            then
               Candidates.Append
                 (Switcher_Candidate'(Summary       => Summary,
                   Metadata      => Metadata,
                   Default_Index => I,
                   Recent_Rank   => Recent_Rank (Recent, Summary.Id)));
            end if;
         end;
      end loop;

      Sort_Candidates (Candidates, State.Active_Sort);

      for I in 1 .. Natural (Candidates.Length) loop
         declare
            Row : Buffer_Switcher_Row :=
              Build_Switcher_Row_Markers
                (State, Row_From_Candidate (Candidates (I - 1)));
         begin
            --  Row ownership and display labels are already
            --  projected from Editor.Buffers.Metadata_For through
            --  Build_Open_Buffer_Switcher_Row_From_Metadata_Snapshot.  Do not
            --  reclassify here through a second project/path code path.
            if not Matches_Buffer_State_Filter (Row, State.Active_Filter) then
               null;
            else
               State.Rows.Append (Row);
                  if Row.Id = Active then
                  Active_Row := Natural (State.Rows.Length);
               end if;
               if Previous_Selected_Id /= Editor.Buffers.No_Buffer
                 and then Row.Id = Previous_Selected_Id
               then
                  Preserved_Selected_Row := Natural (State.Rows.Length);
               end if;
            end if;
         end;
      end loop;

      if State.Rows.Length = 0 then
         State.Selected_Index := 0;
      elsif Preserved_Selected_Row /= 0 then
         State.Selected_Index := Preserved_Selected_Row;
      elsif Active_Row /= 0 then
         State.Selected_Index := Active_Row;
      else
         State.Selected_Index := 1;
      end if;
      Clamp_Window (State);
   end Recompute_Rows;

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
      Row_Operations.Show_Preview (State);
   end Show_Preview;

   procedure Hide_Preview (State : in out Buffer_Switcher_State) is
   begin
      Row_Operations.Hide_Preview (State);
   end Hide_Preview;

   procedure Toggle_Preview (State : in out Buffer_Switcher_State) is
   begin
      Row_Operations.Toggle_Preview (State);
   end Toggle_Preview;

   function Has_Preview (State : Buffer_Switcher_State) return Boolean is
   begin
      return Row_Operations.Has_Preview (State);
   end Has_Preview;

   procedure Set_Preview_Target
     (State       : in out Buffer_Switcher_State;
      Target      : Editor.Buffers.Buffer_Id;
      Anchor_Line : Natural)
   is
   begin
      Row_Operations.Set_Preview_Target (State, Target, Anchor_Line);
   end Set_Preview_Target;

   procedure Clear_Preview_Target (State : in out Buffer_Switcher_State) is
   begin
      Row_Operations.Clear_Preview_Target (State);
   end Clear_Preview_Target;

   function Preview_Target (State : Buffer_Switcher_State) return Editor.Buffers.Buffer_Id is
   begin
      return Row_Operations.Preview_Target (State);
   end Preview_Target;

   function Preview_Anchor_Line (State : Buffer_Switcher_State) return Natural is
   begin
      return Row_Operations.Preview_Anchor_Line (State);
   end Preview_Anchor_Line;

   function Preview_Scroll_Offset (State : Buffer_Switcher_State) return Natural is
   begin
      return Row_Operations.Preview_Scroll_Offset (State);
   end Preview_Scroll_Offset;

   procedure Scroll_Preview_Next_Line (State : in out Buffer_Switcher_State) is
   begin
      Row_Operations.Scroll_Preview_Next_Line (State);
   end Scroll_Preview_Next_Line;

   procedure Scroll_Preview_Previous_Line (State : in out Buffer_Switcher_State) is
   begin
      Row_Operations.Scroll_Preview_Previous_Line (State);
   end Scroll_Preview_Previous_Line;

   procedure Center_Preview_On_Line
     (State       : in out Buffer_Switcher_State;
      Anchor_Line : Natural)
   is
   begin
      Row_Operations.Center_Preview_On_Line (State, Anchor_Line);
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


   function Mark_Index
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffers.Buffer_Id) return Natural
   is
   begin
      if Id = Editor.Buffers.No_Buffer then
         return 0;
      end if;
      for I in 1 .. Natural (State.Marks.Length) loop
         if State.Marks (I - 1) = Id then
            return I;
         end if;
      end loop;
      return 0;
   end Mark_Index;

   function Is_Marked (State : Buffer_Switcher_State; Id : Editor.Buffers.Buffer_Id) return Boolean is
   begin
      return Mark_Index (State, Id) /= 0;
   end Is_Marked;

   procedure Set_Row_Marked (State : in out Buffer_Switcher_State; Id : Editor.Buffers.Buffer_Id; Marked : Boolean) is
   begin
      for I in 1 .. Natural (State.Rows.Length) loop
         if State.Rows (I - 1).Id = Id then
            declare
               Row : Buffer_Switcher_Row := State.Rows (I - 1);
            begin
               Row.Is_Marked := Marked;
               State.Rows.Replace_Element (I - 1, Row);
            end;
         end if;
      end loop;
   end Set_Row_Marked;

   procedure Set_Mark (State : in out Buffer_Switcher_State; Id : Editor.Buffers.Buffer_Id) is
   begin
      if Id /= Editor.Buffers.No_Buffer and then not Is_Marked (State, Id) then
         State.Marks.Append (Id);
      end if;
      Set_Row_Marked (State, Id, True);
   end Set_Mark;

   procedure Clear_Mark (State : in out Buffer_Switcher_State; Id : Editor.Buffers.Buffer_Id) is
      Pos : constant Natural := Mark_Index (State, Id);
   begin
      if Pos /= 0 then
         State.Marks.Delete (Pos - 1);
      end if;
      Set_Row_Marked (State, Id, False);
   end Clear_Mark;

   procedure Toggle_Mark (State : in out Buffer_Switcher_State; Id : Editor.Buffers.Buffer_Id) is
   begin
      if Is_Marked (State, Id) then
         Clear_Mark (State, Id);
      else
         Set_Mark (State, Id);
      end if;
   end Toggle_Mark;

   procedure Clear_All_Marks (State : in out Buffer_Switcher_State) is
   begin
      State.Marks.Clear;
      for I in 1 .. Natural (State.Rows.Length) loop
         declare
            Row : Buffer_Switcher_Row := State.Rows (I - 1);
         begin
            Row.Is_Marked := False;
            State.Rows.Replace_Element (I - 1, Row);
         end;
      end loop;
   end Clear_All_Marks;

   function Marked_Count (State : Buffer_Switcher_State) return Natural is
   begin
      return Natural (State.Marks.Length);
   end Marked_Count;

   function Open_Marked_Count
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 1 .. Natural (State.Marks.Length) loop
         if Editor.Buffers.Contains (Registry, State.Marks (I - 1)) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Open_Marked_Count;

   function Image_No_Leading (Value : Natural) return String is
      Raw : constant String := Natural'Image (Value);
   begin
      if Raw'Length > 0 and then Raw (Raw'First) = ' ' then
         return Raw (Raw'First + 1 .. Raw'Last);
      else
         return Raw;
      end if;
   end Image_No_Leading;

   function Append_Badge
     (Base : String;
      Part : String) return String
   is
   begin
      if Base'Length = 0 then
         return Part;
      else
         return Base & " | " & Part;
      end if;
   end Append_Badge;

   function Review_Display_Name (Mode : Switcher_Review_Mode) return String is
   begin
      case Mode is
         when No_Review =>
            return "";
         when Marked_Review =>
            return "marked";
         when Pending_Marked_Close_Review =>
            return "pending close";
         when Pruned_Pending_Close_Review =>
            return "pruned pending close";
         when Dirty_Pending_Close_Review =>
            return "dirty pending close";
         when Dirty_Prune_Preview_Review =>
            return "dirty prune preview";
         when Removed_Dirty_Prune_Preview_Review =>
            return "removed dirty-prune targets";
         when Dirty_Prune_Apply_Review =>
            return "dirty-prune apply";
         when Removed_Dirty_Prune_Apply_Review =>
            return "removed dirty-prune apply targets";
      end case;
   end Review_Display_Name;

   function Review_Empty_Message (Mode : Switcher_Review_Mode) return String is
   begin
      case Mode is
         when No_Review =>
            return "No matching buffers";
         when Marked_Review =>
            return "No marked buffers";
         when Pending_Marked_Close_Review =>
            return "No pending close targets";
         when Pruned_Pending_Close_Review =>
            return "No pruned pending close targets";
         when Dirty_Pending_Close_Review =>
            return "No dirty pending close targets";
         when Dirty_Prune_Preview_Review =>
            return "No dirty-prune preview targets";
         when Removed_Dirty_Prune_Preview_Review =>
            return "No removed dirty-prune preview targets";
         when Dirty_Prune_Apply_Review =>
            return "No dirty-prune apply targets";
         when Removed_Dirty_Prune_Apply_Review =>
            return "No removed dirty-prune apply targets";
      end case;
   end Review_Empty_Message;

   function Build_Switcher_Count_Badge_Text
     (Snapshot : Switcher_Batch_State_Snapshot) return String
   is
      Text : Unbounded_String := Null_Unbounded_String;

      procedure Add (Part : String) is
      begin
         Text := To_Unbounded_String (Append_Badge (To_String (Text), Part));
      end Add;
   begin
      if Snapshot.Marked_Count > 0 then
         Add ("Marked: " & Image_No_Leading (Snapshot.Marked_Count));
      end if;

      if Snapshot.Has_Pending_Marked_Close then
         Add ("Pending close: " & Image_No_Leading (Snapshot.Pending_Close_Count));
      end if;

      if Snapshot.Dirty_Pending_Close_Count > 0 then
         Add ("Dirty: " & Image_No_Leading (Snapshot.Dirty_Pending_Close_Count));
      end if;

      if Snapshot.Pruned_Pending_Close_Count > 0 then
         Add ("Pruned: " & Image_No_Leading (Snapshot.Pruned_Pending_Close_Count));
      end if;

      if Snapshot.Has_Dirty_Prune_Preview then
         Add ("Dirty prune: " & Image_No_Leading (Snapshot.Dirty_Prune_Preview_Count));
         Add ("Applicable: " & Image_No_Leading (Snapshot.Applicable_Dirty_Prune_Preview_Count));
      end if;

      if Snapshot.Removed_Dirty_Prune_Preview_Count > 0 then
         Add ("Removed: " & Image_No_Leading (Snapshot.Removed_Dirty_Prune_Preview_Count));
      end if;

      if Snapshot.Has_Dirty_Prune_Apply_Confirmation then
         Add ("Apply: " & Image_No_Leading (Snapshot.Dirty_Prune_Apply_Count));
         Add ("Apply applicable: " & Image_No_Leading (Snapshot.Applicable_Dirty_Prune_Apply_Count));
      end if;

      if Snapshot.Removed_Dirty_Prune_Apply_Count > 0 then
         Add ("Apply removed: " & Image_No_Leading (Snapshot.Removed_Dirty_Prune_Apply_Count));
      end if;

      return To_String (Text);
   end Build_Switcher_Count_Badge_Text;

   function Build_Switcher_Header_Badge_Text
     (State    : Buffer_Switcher_State;
      Snapshot : Switcher_Batch_State_Snapshot) return String
   is
      Text : Unbounded_String := Null_Unbounded_String;

      procedure Add (Part : String) is
      begin
         Text := To_Unbounded_String (Append_Badge (To_String (Text), Part));
      end Add;
   begin
      if Snapshot.Active_Review_Mode /= No_Review then
         Add ("Review: " & To_String (Snapshot.Review_Display_Name));
      end if;

      if Has_Metadata_Filter (State) then
         Add ("Filter: " & Metadata_Filter_Description (State));
      end if;

      if Filter_Text (State)'Length > 0 then
         Add ("Query: " & Filter_Text (State));
      end if;

      if State.Active_Sort /= Default_Sort then
         Add ("Sort: " & Sort_Mode_Description (State));
      end if;

      declare
         Count_Text : constant String := Build_Switcher_Count_Badge_Text (Snapshot);
      begin
         if Count_Text'Length > 0 then
            Add (Count_Text);
         end if;
      end;

      return To_String (Text);
   end Build_Switcher_Header_Badge_Text;

   function Build_Switcher_Footer_Badge_Text
     (State    : Buffer_Switcher_State;
      Snapshot : Switcher_Batch_State_Snapshot) return String
   is
      pragma Unreferenced (State);
   begin
      return Build_Switcher_Count_Badge_Text (Snapshot);
   end Build_Switcher_Footer_Badge_Text;

   function Build_Switcher_Batch_State_Snapshot
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Switcher_Batch_State_Snapshot
   is
      Snapshot : Switcher_Batch_State_Snapshot;
   begin
      Snapshot.Active_Review_Mode := State.Active_Review;
      Snapshot.Review_Display_Name := To_Unbounded_String (Review_Display_Name (State.Active_Review));
      Snapshot.Review_Empty_Message := To_Unbounded_String (Review_Empty_Message (State.Active_Review));
      Snapshot.Marked_Count := Open_Marked_Count (State, Registry);
      Snapshot.Pending_Close_Count := Pending_Marked_Open_Count (State, Registry);
      Snapshot.Dirty_Pending_Close_Count := Pending_Marked_Open_Dirty_Count (State, Registry);
      Snapshot.Pruned_Pending_Close_Count := Pruned_Pending_Marked_Close_Target_Count (State);
      Snapshot.Dirty_Prune_Preview_Count := Dirty_Pending_Marked_Close_Prune_Target_Count (State);
      Snapshot.Applicable_Dirty_Prune_Preview_Count :=
        Applicable_Dirty_Pending_Marked_Close_Prune_Target_Count (State, Registry);
      Snapshot.Removed_Dirty_Prune_Preview_Count :=
        Removed_Dirty_Pending_Marked_Close_Prune_Target_Count (State);
      Snapshot.Open_Removed_Dirty_Prune_Preview_Count :=
        Open_Removed_Dirty_Pending_Marked_Close_Prune_Target_Count (State, Registry);
      Snapshot.Stale_Dirty_Prune_Preview_Count :=
        Dirty_Pending_Marked_Close_Prune_Stale_Target_Count (State, Registry);
      Snapshot.Dirty_Prune_Apply_Count :=
        Dirty_Pending_Marked_Close_Prune_Apply_Target_Count (State);
      Snapshot.Applicable_Dirty_Prune_Apply_Count :=
        Applicable_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count (State, Registry);
      Snapshot.Removed_Dirty_Prune_Apply_Count :=
        Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count (State);
      Snapshot.Open_Removed_Dirty_Prune_Apply_Count :=
        Open_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count (State, Registry);
      Snapshot.Stale_Dirty_Prune_Apply_Count :=
        Dirty_Pending_Marked_Close_Prune_Apply_Stale_Target_Count (State, Registry);
      Snapshot.Has_Pending_Marked_Close := State.Pending_Action = Pending_Marked_Close;
      Snapshot.Has_Dirty_Prune_Preview :=
        Snapshot.Dirty_Prune_Preview_Count > 0
        or else Snapshot.Removed_Dirty_Prune_Preview_Count > 0;
      Snapshot.Has_Dirty_Prune_Apply_Confirmation :=
        Snapshot.Dirty_Prune_Apply_Count > 0
        or else Snapshot.Removed_Dirty_Prune_Apply_Count > 0;
      Snapshot.Header_Badge_Text :=
        To_Unbounded_String (Build_Switcher_Header_Badge_Text (State, Snapshot));
      Snapshot.Footer_Badge_Text :=
        To_Unbounded_String (Build_Switcher_Footer_Badge_Text (State, Snapshot));
      return Snapshot;
   end Build_Switcher_Batch_State_Snapshot;

   function Header_Badge_Text
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return String
   is
   begin
      return To_String (Build_Switcher_Batch_State_Snapshot (State, Registry).Header_Badge_Text);
   end Header_Badge_Text;

   function Footer_Badge_Text
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return String
   is
   begin
      return To_String (Build_Switcher_Batch_State_Snapshot (State, Registry).Footer_Badge_Text);
   end Footer_Badge_Text;

   function Count_Badge_Text
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return String
   is
   begin
      return Build_Switcher_Count_Badge_Text
        (Build_Switcher_Batch_State_Snapshot (State, Registry));
   end Count_Badge_Text;

   function Has_Marks (State : Buffer_Switcher_State) return Boolean is
   begin
      return Natural (State.Marks.Length) > 0;
   end Has_Marks;

   procedure Invert_Visible_Marks
     (State          : in out Buffer_Switcher_State;
      Marked_Count   : out Natural;
      Unmarked_Count : out Natural)
   is
   begin
      Marked_Count := 0;
      Unmarked_Count := 0;
      for I in 1 .. Natural (State.Rows.Length) loop
         declare
            Id : constant Editor.Buffers.Buffer_Id := State.Rows (I - 1).Id;
         begin
            if Is_Marked (State, Id) then
               Clear_Mark (State, Id);
               Unmarked_Count := Unmarked_Count + 1;
            else
               Set_Mark (State, Id);
               Marked_Count := Marked_Count + 1;
            end if;
         end;
      end loop;
   end Invert_Visible_Marks;

   procedure Mark_Visible_Marks
     (State : in out Buffer_Switcher_State;
      Count : out Natural)
   is
   begin
      Count := 0;
      for I in 1 .. Natural (State.Rows.Length) loop
         Set_Mark (State, State.Rows (I - 1).Id);
         Count := Count + 1;
      end loop;
   end Mark_Visible_Marks;

   procedure Clear_Visible_Marks
     (State : in out Buffer_Switcher_State;
      Count : out Natural)
   is
   begin
      Count := 0;
      for I in 1 .. Natural (State.Rows.Length) loop
         declare
            Id : constant Editor.Buffers.Buffer_Id := State.Rows (I - 1).Id;
         begin
            if Is_Marked (State, Id) then
               Clear_Mark (State, Id);
               Count := Count + 1;
            end if;
         end;
      end loop;
   end Clear_Visible_Marks;

   procedure Prune_Marks (State : in out Buffer_Switcher_State; Registry : Editor.Buffers.Buffer_Registry) is
      I : Natural := 1;
   begin
      while I <= Natural (State.Marks.Length) loop
         if not Editor.Buffers.Contains (Registry, State.Marks (I - 1)) then
            State.Marks.Delete (I - 1);
         else
            I := I + 1;
         end if;
      end loop;
   end Prune_Marks;


   function Row_Matches_Review_Mode
     (State : Buffer_Switcher_State;
      Row   : Buffer_Switcher_Row;
      Mode  : Switcher_Review_Mode) return Boolean
   is
   begin
      case Mode is
         when No_Review =>
            return True;
         when Marked_Review =>
            return Row.Is_Marked;
         when Pending_Marked_Close_Review =>
            return Row_Is_Pending_Marked_Target (State, Row.Id);
         when Pruned_Pending_Close_Review =>
            return Is_Pruned_Pending_Marked_Close_Target (State, Row.Id);
         when Dirty_Pending_Close_Review =>
            return Row.Is_Dirty and then Row_Is_Pending_Marked_Target (State, Row.Id);
         when Dirty_Prune_Preview_Review =>
            return Row_Is_Dirty_Prune_Target (State, Row.Id);
         when Removed_Dirty_Prune_Preview_Review =>
            return Is_Removed_Dirty_Pending_Marked_Close_Prune_Target (State, Row.Id);
         when Dirty_Prune_Apply_Review =>
            return Row_Is_Dirty_Prune_Apply_Target (State, Row.Id);
         when Removed_Dirty_Prune_Apply_Review =>
            return Is_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target (State, Row.Id);
      end case;
   end Row_Matches_Review_Mode;

   function Select_Next_Switcher_Review_Target
     (State : in out Buffer_Switcher_State;
      Mode  : Switcher_Review_Mode) return Boolean
   is
      Count : constant Natural := Natural (State.Rows.Length);
      Start : Natural := State.Selected_Index;
   begin
      if Count = 0 then
         State.Selected_Index := 0;
         State.Top_Index := 1;
         return False;
      end if;

      if Start = 0 or else Start > Count then
         Start := 0;
      end if;

      for Offset in 1 .. Count loop
         declare
            Candidate : constant Natural := ((Start + Offset - 1) mod Count) + 1;
         begin
            if Row_Matches_Review_Mode (State, State.Rows (Candidate - 1), Mode) then
               State.Selected_Index := Candidate;
               Clamp_Window (State);
               return True;
            end if;
         end;
      end loop;

      return False;
   end Select_Next_Switcher_Review_Target;

   function Select_Previous_Switcher_Review_Target
     (State : in out Buffer_Switcher_State;
      Mode  : Switcher_Review_Mode) return Boolean
   is
      Count : constant Natural := Natural (State.Rows.Length);
      Start : Natural := State.Selected_Index;
   begin
      if Count = 0 then
         State.Selected_Index := 0;
         State.Top_Index := 1;
         return False;
      end if;

      if Start = 0 or else Start > Count then
         Start := 1;
      end if;

      for Offset in 1 .. Count loop
         declare
            Candidate : constant Natural := ((Start + Count - Offset - 1) mod Count) + 1;
         begin
            if Row_Matches_Review_Mode (State, State.Rows (Candidate - 1), Mode) then
               State.Selected_Index := Candidate;
               Clamp_Window (State);
               return True;
            end if;
         end;
      end loop;

      return False;
   end Select_Previous_Switcher_Review_Target;

   function Select_Next_Marked_Buffer (State : in out Buffer_Switcher_State) return Boolean is
   begin
      return Select_Next_Switcher_Review_Target (State, Marked_Review);
   end Select_Next_Marked_Buffer;

   function Select_Previous_Marked_Buffer (State : in out Buffer_Switcher_State) return Boolean is
   begin
      return Select_Previous_Switcher_Review_Target (State, Marked_Review);
   end Select_Previous_Marked_Buffer;

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
