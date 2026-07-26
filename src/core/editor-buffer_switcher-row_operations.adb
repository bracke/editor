with Ada.Containers.Vectors;
with Ada.Strings.Fixed;
with Ada.Strings;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffers;
with Editor.Buffer_Switcher.Dirty_Prune_Operations;
with Editor.Buffer_Switcher.Pending_Close_Operations;
with Editor.Buffer_Switcher.Review_Operations;
with Editor.Text_Helpers;

package body Editor.Buffer_Switcher.Row_Operations is
   use type Editor.Buffers.Buffer_Close_Eligibility;
   use type Editor.Buffers.Buffer_Ownership_Kind;
   use type Editor.Buffers.Buffer_Dirty_Category;
   use type Editor.Buffer_Switcher.Buffer_Project_Ownership_Kind;
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
     renames Editor.Text_Helpers.Lower;

   function Contains (Text, Part : String) return Boolean
     renames Editor.Text_Helpers.Contains;

   procedure Clamp_Window (State : in out Buffer_Switcher_State) is
      Count : constant Natural := Natural (State.Rows.Length);
   begin
      if Count = 0 then
         State.Selected_Index := 0;
         State.Top_Index := 1;
      else
         if State.Selected_Index = 0 or else State.Selected_Index > Count then
            State.Selected_Index := 1;
         end if;
         if State.Top_Index = 0 or else State.Top_Index > State.Selected_Index then
            State.Top_Index := State.Selected_Index;
         end if;
         if State.Selected_Index >= State.Top_Index + State.Visible_Window then
            State.Top_Index := State.Selected_Index - State.Visible_Window + 1;
         end if;
      end if;
   end Clamp_Window;

   function Matches_Metadata_Filter
     (Summary : Editor.Buffers.Buffer_Summary;
      Filter  : Switcher_Metadata_Filter) return Boolean
   is
      Text : constant String := To_String (Filter.Text);
   begin
      case Filter.Kind is
         when No_Filter =>
            return True;
         when Pinned_Filter =>
            return Summary.Is_Pinned;
         when Group_Filter =>
            return Summary.Has_Group and then To_String (Summary.Group_Name) = Text;
         when Label_Filter =>
            return Summary.Has_Label and then To_String (Summary.Label_Text) = Text;
         when Noted_Filter =>
            return Summary.Has_Note;
         when Dirty_Filter
            | Clean_Filter
            | Missing_Or_Conflict_Filter
            | Project_Owned_Filter
            | Outside_Project_Filter
            | Scratch_Filter =>
            return True;
      end case;
   end Matches_Metadata_Filter;

   function Matches_Buffer_State_Filter
     (Row    : Buffer_Switcher_Row;
      Filter : Switcher_Metadata_Filter) return Boolean
   is
   begin
      case Filter.Kind is
         when Dirty_Filter =>
            return Row.Is_Dirty;
         when Clean_Filter =>
            return not Row.Is_Dirty;
         when Missing_Or_Conflict_Filter =>
            return Row.Missing_Target_Surfaced
              or else Row.External_Change_Surfaced
              or else Row.Unreadable_Target_Surfaced
              or else Row.Unwritable_Target_Surfaced
              or else Row.Last_Save_Failed
              or else Row.Last_Reload_Failed
              or else Row.Last_Revert_Failed;
         when Project_Owned_Filter =>
            return Row.Project_Ownership = Buffer_Project_Owned;
         when Outside_Project_Filter =>
            return Row.Project_Ownership = Buffer_Project_Outside;
         when Scratch_Filter =>
            return Row.Project_Ownership = Buffer_Project_Scratch
              or else Row.Is_Unbacked;
         when No_Filter
            | Pinned_Filter
            | Group_Filter
            | Label_Filter
            | Noted_Filter =>
            return True;
      end case;
   end Matches_Buffer_State_Filter;

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

   function Row_From_Candidate (Candidate : Switcher_Candidate) return Buffer_Switcher_Row is
   begin
      return Build_Open_Buffer_Switcher_Row_From_Metadata_Snapshot
        (Candidate.Metadata, Candidate.Summary);
   end Row_From_Candidate;

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
            return Editor.Buffer_Switcher.Is_Marked (State, Summary.Id);
         when Pending_Marked_Close_Review =>
            return Editor.Buffer_Switcher.Row_Is_Pending_Marked_Target (State, Summary.Id);
         when Pruned_Pending_Close_Review =>
            return Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (State, Summary.Id);
         when Dirty_Pending_Close_Review =>
            return Metadata.Dirty_Category /= Editor.Buffers.Buffer_Not_Dirty
              and then Editor.Buffer_Switcher.Row_Is_Pending_Marked_Target (State, Summary.Id);
         when Dirty_Prune_Preview_Review =>
            return Editor.Buffer_Switcher.Row_Is_Dirty_Prune_Target (State, Summary.Id);
         when Removed_Dirty_Prune_Preview_Review =>
            return Editor.Buffer_Switcher.Is_Removed_Dirty_Pending_Marked_Close_Prune_Target (State, Summary.Id);
         when Dirty_Prune_Apply_Review =>
            return Editor.Buffer_Switcher.Is_Dirty_Pending_Marked_Close_Prune_Apply_Target (State, Summary.Id);
         when Removed_Dirty_Prune_Apply_Review =>
            return Editor.Buffer_Switcher.Is_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target (State, Summary.Id);
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
              Pending_Close_Operations.Build_Switcher_Row_Markers
                (State, Row_From_Candidate (Candidates (I - 1)));
         begin
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
      Count : constant Natural := Natural (State.Rows.Length);
   begin
      if Count = 0 then
         State.Selected_Index := 0;
         State.Top_Index := 1;
      elsif State.Selected_Index = 0 or else State.Selected_Index >= Count then
         State.Selected_Index := 1;
         State.Top_Index := 1;
      else
         State.Selected_Index := State.Selected_Index + 1;
      end if;
      Clamp_Window (State);
   end Move_Selection_Down;

   procedure Move_Selection_Up (State : in out Buffer_Switcher_State) is
      Count : constant Natural := Natural (State.Rows.Length);
   begin
      if Count = 0 then
         State.Selected_Index := 0;
         State.Top_Index := 1;
      elsif State.Selected_Index <= 1 then
         State.Selected_Index := Count;
      else
         State.Selected_Index := State.Selected_Index - 1;
      end if;
      Clamp_Window (State);
   end Move_Selection_Up;

   procedure Show_Preview (State : in out Buffer_Switcher_State) is
   begin
      State.Preview_Visible := True;
   end Show_Preview;

   procedure Hide_Preview (State : in out Buffer_Switcher_State) is
   begin
      State.Preview_Visible := False;
      State.Preview_Target_Id := Editor.Buffers.No_Buffer;
      State.Preview_Anchor := 1;
      State.Preview_Scroll := 0;
   end Hide_Preview;

   procedure Toggle_Preview (State : in out Buffer_Switcher_State) is
   begin
      if State.Preview_Visible then
         Hide_Preview (State);
      else
         Show_Preview (State);
      end if;
   end Toggle_Preview;

   function Has_Preview (State : Buffer_Switcher_State) return Boolean is
   begin
      return State.Preview_Visible;
   end Has_Preview;

   procedure Set_Preview_Target
     (State       : in out Buffer_Switcher_State;
      Target      : Editor.Buffers.Buffer_Id;
      Anchor_Line : Natural)
   is
   begin
      if Target = Editor.Buffers.No_Buffer then
         Clear_Preview_Target (State);
      else
         State.Preview_Target_Id := Target;
         State.Preview_Anchor := Natural'Max (1, Anchor_Line);
         State.Preview_Scroll := 0;
      end if;
   end Set_Preview_Target;

   procedure Clear_Preview_Target (State : in out Buffer_Switcher_State) is
   begin
      State.Preview_Target_Id := Editor.Buffers.No_Buffer;
      State.Preview_Anchor := 1;
      State.Preview_Scroll := 0;
   end Clear_Preview_Target;

   function Preview_Target (State : Buffer_Switcher_State) return Editor.Buffers.Buffer_Id is
   begin
      return State.Preview_Target_Id;
   end Preview_Target;

   function Preview_Anchor_Line (State : Buffer_Switcher_State) return Natural is
   begin
      return State.Preview_Anchor;
   end Preview_Anchor_Line;

   function Preview_Scroll_Offset (State : Buffer_Switcher_State) return Natural is
   begin
      return State.Preview_Scroll;
   end Preview_Scroll_Offset;

   procedure Scroll_Preview_Next_Line (State : in out Buffer_Switcher_State) is
   begin
      if State.Preview_Visible and then State.Preview_Target_Id /= Editor.Buffers.No_Buffer then
         State.Preview_Scroll := State.Preview_Scroll + 1;
      end if;
   end Scroll_Preview_Next_Line;

   procedure Scroll_Preview_Previous_Line (State : in out Buffer_Switcher_State) is
   begin
      if State.Preview_Visible and then State.Preview_Target_Id /= Editor.Buffers.No_Buffer then
         if State.Preview_Scroll > 0 then
            State.Preview_Scroll := State.Preview_Scroll - 1;
         elsif State.Preview_Anchor > 1 then
            State.Preview_Anchor := State.Preview_Anchor - 1;
         end if;
      end if;
   end Scroll_Preview_Previous_Line;

   procedure Center_Preview_On_Line
     (State       : in out Buffer_Switcher_State;
      Anchor_Line : Natural)
   is
   begin
      if State.Preview_Visible and then State.Preview_Target_Id /= Editor.Buffers.No_Buffer then
         State.Preview_Anchor := Natural'Max (1, Anchor_Line);
         State.Preview_Scroll := 0;
      end if;
   end Center_Preview_On_Line;

   procedure Select_Buffer_Or_Row
     (State          : in out Buffer_Switcher_State;
      Preferred_Id   : Editor.Buffers.Buffer_Id;
      Fallback_Index : Natural)
   is
      Count : constant Natural := Natural (State.Rows.Length);
   begin
      if Count = 0 then
         State.Selected_Index := 0;
         State.Top_Index := 1;
         return;
      end if;

      if Preferred_Id /= Editor.Buffers.No_Buffer then
         for I in 1 .. Count loop
            if State.Rows (I - 1).Id = Preferred_Id then
               State.Selected_Index := I;
               Clamp_Window (State);
               return;
            end if;
         end loop;
      end if;

      if Fallback_Index = 0 then
         State.Selected_Index := 1;
      elsif Fallback_Index > Count then
         State.Selected_Index := Count;
      else
         State.Selected_Index := Fallback_Index;
      end if;
      Clamp_Window (State);
   end Select_Buffer_Or_Row;

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
            return Editor.Buffer_Switcher.Is_Marked (State, Row.Id);
         when Pending_Marked_Close_Review =>
            return Editor.Buffer_Switcher.Row_Is_Pending_Marked_Target (State, Row.Id);
         when Pruned_Pending_Close_Review =>
            return Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (State, Row.Id);
         when Dirty_Pending_Close_Review =>
            return Row.Is_Dirty and then Editor.Buffer_Switcher.Row_Is_Pending_Marked_Target (State, Row.Id);
         when Dirty_Prune_Preview_Review =>
            return Editor.Buffer_Switcher.Row_Is_Dirty_Prune_Target (State, Row.Id);
         when Removed_Dirty_Prune_Preview_Review =>
            return Editor.Buffer_Switcher.Is_Removed_Dirty_Pending_Marked_Close_Prune_Target (State, Row.Id);
         when Dirty_Prune_Apply_Review =>
            return Editor.Buffer_Switcher.Is_Dirty_Pending_Marked_Close_Prune_Apply_Target (State, Row.Id);
         when Removed_Dirty_Prune_Apply_Review =>
            return Editor.Buffer_Switcher.Is_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target (State, Row.Id);
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

   function Select_Next_Pending_Marked_Buffer (State : in out Buffer_Switcher_State) return Boolean is
   begin
      return Select_Next_Switcher_Review_Target (State, Pending_Marked_Close_Review);
   end Select_Next_Pending_Marked_Buffer;

   function Select_Previous_Pending_Marked_Buffer (State : in out Buffer_Switcher_State) return Boolean is
   begin
      return Select_Previous_Switcher_Review_Target (State, Pending_Marked_Close_Review);
   end Select_Previous_Pending_Marked_Buffer;

   function Select_Next_Pruned_Pending_Marked_Buffer (State : in out Buffer_Switcher_State) return Boolean is
   begin
      return Select_Next_Switcher_Review_Target (State, Pruned_Pending_Close_Review);
   end Select_Next_Pruned_Pending_Marked_Buffer;

   function Select_Previous_Pruned_Pending_Marked_Buffer (State : in out Buffer_Switcher_State) return Boolean is
   begin
      return Select_Previous_Switcher_Review_Target (State, Pruned_Pending_Close_Review);
   end Select_Previous_Pruned_Pending_Marked_Buffer;

   function Select_Next_Dirty_Pending_Marked_Buffer (State : in out Buffer_Switcher_State) return Boolean is
   begin
      return Select_Next_Switcher_Review_Target (State, Dirty_Pending_Close_Review);
   end Select_Next_Dirty_Pending_Marked_Buffer;

   function Select_Previous_Dirty_Pending_Marked_Buffer (State : in out Buffer_Switcher_State) return Boolean is
   begin
      return Select_Previous_Switcher_Review_Target (State, Dirty_Pending_Close_Review);
   end Select_Previous_Dirty_Pending_Marked_Buffer;

   function Select_Next_Dirty_Prune_Target (State : in out Buffer_Switcher_State) return Boolean is
   begin
      return Select_Next_Switcher_Review_Target (State, Dirty_Prune_Preview_Review);
   end Select_Next_Dirty_Prune_Target;

   function Select_Previous_Dirty_Prune_Target (State : in out Buffer_Switcher_State) return Boolean is
   begin
      return Select_Previous_Switcher_Review_Target (State, Dirty_Prune_Preview_Review);
   end Select_Previous_Dirty_Prune_Target;

   function Select_Next_Removed_Dirty_Prune_Target (State : in out Buffer_Switcher_State) return Boolean is
   begin
      return Select_Next_Switcher_Review_Target (State, Removed_Dirty_Prune_Preview_Review);
   end Select_Next_Removed_Dirty_Prune_Target;

   function Select_Previous_Removed_Dirty_Prune_Target (State : in out Buffer_Switcher_State) return Boolean is
   begin
      return Select_Previous_Switcher_Review_Target (State, Removed_Dirty_Prune_Preview_Review);
   end Select_Previous_Removed_Dirty_Prune_Target;

   function Select_Next_Dirty_Prune_Apply_Target (State : in out Buffer_Switcher_State) return Boolean is
   begin
      return Select_Next_Switcher_Review_Target (State, Dirty_Prune_Apply_Review);
   end Select_Next_Dirty_Prune_Apply_Target;

   function Select_Previous_Dirty_Prune_Apply_Target (State : in out Buffer_Switcher_State) return Boolean is
   begin
      return Select_Previous_Switcher_Review_Target (State, Dirty_Prune_Apply_Review);
   end Select_Previous_Dirty_Prune_Apply_Target;

   function Select_Next_Removed_Dirty_Prune_Apply_Target (State : in out Buffer_Switcher_State) return Boolean is
   begin
      return Select_Next_Switcher_Review_Target (State, Removed_Dirty_Prune_Apply_Review);
   end Select_Next_Removed_Dirty_Prune_Apply_Target;

   function Select_Previous_Removed_Dirty_Prune_Apply_Target (State : in out Buffer_Switcher_State) return Boolean is
   begin
      return Select_Previous_Switcher_Review_Target (State, Removed_Dirty_Prune_Apply_Review);
   end Select_Previous_Removed_Dirty_Prune_Apply_Target;

   function Row_Count (State : Buffer_Switcher_State) return Natural is
   begin
      return Natural (State.Rows.Length);
   end Row_Count;

   function Selected_Row_Index (State : Buffer_Switcher_State) return Natural is
   begin
      return State.Selected_Index;
   end Selected_Row_Index;

   function Top_Row_Index (State : Buffer_Switcher_State) return Natural is
   begin
      return State.Top_Index;
   end Top_Row_Index;

   function Row_At (State : Buffer_Switcher_State; Index : Positive) return Buffer_Switcher_Row is
   begin
      if Index > Natural (State.Rows.Length) then
         return (others => <>);
      end if;
      return State.Rows (Index - 1);
   end Row_At;

   function Row_For_Buffer
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffers.Buffer_Id;
      Found : out Boolean) return Buffer_Switcher_Row
   is
   begin
      for I in 1 .. Natural (State.Rows.Length) loop
         if State.Rows (I - 1).Id = Id then
            Found := True;
            return State.Rows (I - 1);
         end if;
      end loop;
      Found := False;
      return (others => <>);
   end Row_For_Buffer;

   function Selected_Row
     (State : Buffer_Switcher_State;
      Found : out Boolean) return Buffer_Switcher_Row is
   begin
      if State.Selected_Index = 0 or else State.Selected_Index > Natural (State.Rows.Length) then
         Found := False;
         return (others => <>);
      end if;
      Found := True;
      return State.Rows (State.Selected_Index - 1);
   end Selected_Row;

   function Audit_Selected_Buffer_List_State
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry)
      return Editor.Buffer_Switcher.Selected_Buffer_List_Audit
   is
      Result : Editor.Buffer_Switcher.Selected_Buffer_List_Audit;
      Found  : Boolean := False;
      Row    : Buffer_Switcher_Row;
   begin
      Result.Row_Count := Natural (State.Rows.Length);
      Result.Selected_Row_Index := State.Selected_Index;

      if Result.Row_Count = 0 then
         Result.Selection_Cleared_When_No_Rows := State.Selected_Index = 0;
         Result.Selection_Index_Clamped_To_Rows := State.Selected_Index = 0;
         Result.Selected_Row_Is_Buffer := True;
         Result.Selected_Runtime_Id_Registered := True;
         Result.Selected_Row_Valid := Result.Selection_Cleared_When_No_Rows;
      elsif State.Selected_Index = 0 or else State.Selected_Index > Result.Row_Count then
         Result.Selection_Cleared_When_No_Rows := True;
         Result.Selection_Index_Clamped_To_Rows := False;
         Result.Selected_Row_Is_Buffer := False;
         Result.Selected_Runtime_Id_Registered := False;
         Result.Selected_Row_Valid := False;
      else
         Row := Selected_Row (State, Found);
         Result.Selection_Cleared_When_No_Rows := True;
         Result.Selection_Index_Clamped_To_Rows := Found;
         Result.Selected_Row_Is_Buffer := Found and then Row.Id /= Editor.Buffers.No_Buffer;
         Result.Selection_Skips_Status_Rows := Result.Selected_Row_Is_Buffer;
         if Result.Selected_Row_Is_Buffer then
            Result.Selected_Buffer_Id := Row.Id;
            Result.Selected_Runtime_Id_Registered := Editor.Buffers.Contains (Registry, Row.Id);
         else
            Result.Selected_Runtime_Id_Registered := False;
         end if;
         Result.Selected_Row_Valid :=
           Result.Selection_Index_Clamped_To_Rows
           and then Result.Selected_Row_Is_Buffer
           and then Result.Selected_Runtime_Id_Registered;
      end if;

      Result.Selection_Is_Transient := True;
      Result.Selection_Not_Persisted := True;
      Result.Selection_Not_Keybinding_Payload := True;
      return Result;
   end Audit_Selected_Buffer_List_State;

   function Query_Snapshot
     (State           : Buffer_Switcher_State;
      Visible_Columns : Natural) return Editor.Input_Field.Field_Snapshot is
   begin
      return Editor.Input_Field.Snapshot (State.Field, Visible_Columns);
   end Query_Snapshot;

   function Geometry
     (Body_Rect   : Editor.Layout.Rect;
      Config      : Buffer_Switcher_Config;
      Cell_Width  : Positive;
      Cell_Height : Positive) return Editor.Layout.Rect
   is
      Wanted_W : constant Natural := Config.Overlay_Width_In_Columns * Cell_Width;
      Margin   : constant Natural := 2 * Cell_Width;
      Width    : constant Natural :=
        (if Body_Rect.Width > 2 * Margin
         then Natural'Min (Wanted_W, Body_Rect.Width - 2 * Margin)
         else Body_Rect.Width);
      Rows     : constant Natural :=
        Config.Header_Height_In_Rows + Config.Field_Height_In_Rows +
        Config.Max_Visible_Results * Config.Row_Height_In_Rows +
        Config.Preview_Max_Lines + 1;
      Height   : constant Natural := Rows * Cell_Height;
      X        : constant Integer :=
        Body_Rect.X + Integer ((if Body_Rect.Width > Width then (Body_Rect.Width - Width) / 2 else 0));
      Y        : constant Integer := Body_Rect.Y + Integer (Cell_Height);
   begin
      return (X => X, Y => Y, Width => Width, Height => Height);
   end Geometry;

end Editor.Buffer_Switcher.Row_Operations;
