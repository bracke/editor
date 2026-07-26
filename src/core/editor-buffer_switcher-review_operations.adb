with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffer_Switcher.Reviews;
with Editor.Buffer_Switcher.Rows;
with Editor.Buffer_Switcher.Filters;
with Editor.Buffer_Switcher.Pending_Close_Operations;
with Editor.Buffer_Switcher.Dirty_Prune_Operations;
with Editor.Buffers;
with Editor.Input_Field;
package body Editor.Buffer_Switcher.Review_Operations is
   use Editor.Buffer_Switcher.Reviews;
   use Editor.Buffer_Switcher.Rows;

   use type Editor.Buffer_Switcher.Reviews.Switcher_Review_Mode;
   use type Editor.Buffer_Switcher.Reviews.Pending_Marked_Action_Kind;
   use type Editor.Buffer_Switcher.Filters.Switcher_Sort_Mode;

   procedure Set_Switcher_Review_Mode
     (State : in out Buffer_Switcher_State;
      Mode  : Switcher_Review_Mode)
   is
   begin
      State.Active_Review := Mode;
   end Set_Switcher_Review_Mode;

   procedure Clear_Switcher_Review_Mode
     (State : in out Buffer_Switcher_State;
      Mode  : Switcher_Review_Mode)
   is
   begin
      if State.Active_Review = Mode then
         State.Active_Review := No_Review;
      end if;
   end Clear_Switcher_Review_Mode;

   procedure Toggle_Switcher_Review_Mode
     (State : in out Buffer_Switcher_State;
      Mode  : Switcher_Review_Mode)
   is
   begin
      if State.Active_Review = Mode then
         State.Active_Review := No_Review;
      else
         State.Active_Review := Mode;
      end if;
   end Toggle_Switcher_Review_Mode;

   function Has_Switcher_Review_Mode
     (State : Buffer_Switcher_State;
      Mode  : Switcher_Review_Mode) return Boolean
   is
   begin
      return State.Active_Review = Mode;
   end Has_Switcher_Review_Mode;

   procedure Clear_Dirty_Prune_Apply_Review_Modes
     (State : in out Buffer_Switcher_State)
   is
   begin
      if State.Active_Review = Dirty_Prune_Apply_Review
        or else State.Active_Review = Removed_Dirty_Prune_Apply_Review
      then
         State.Active_Review := No_Review;
      end if;
   end Clear_Dirty_Prune_Apply_Review_Modes;

   procedure Clear_Dirty_Prune_Preview_Review_Modes
     (State : in out Buffer_Switcher_State)
   is
   begin
      if State.Active_Review = Dirty_Prune_Preview_Review
        or else State.Active_Review = Removed_Dirty_Prune_Preview_Review
      then
         State.Active_Review := No_Review;
      end if;
   end Clear_Dirty_Prune_Preview_Review_Modes;

   procedure Clear_Pending_Marked_Review_Modes
     (State : in out Buffer_Switcher_State)
   is
   begin
      case State.Active_Review is
         when Pending_Marked_Close_Review
            | Pruned_Pending_Close_Review
            | Dirty_Pending_Close_Review
            | Dirty_Prune_Preview_Review
            | Removed_Dirty_Prune_Preview_Review
            | Dirty_Prune_Apply_Review
            | Removed_Dirty_Prune_Apply_Review =>
            State.Active_Review := No_Review;
         when No_Review | Marked_Review =>
            null;
      end case;
   end Clear_Pending_Marked_Review_Modes;

   procedure Show_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      Set_Switcher_Review_Mode (State, Marked_Review);
   end Show_Marked_Review;

   procedure Hide_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      Clear_Switcher_Review_Mode (State, Marked_Review);
   end Hide_Marked_Review;

   procedure Toggle_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      Toggle_Switcher_Review_Mode (State, Marked_Review);
   end Toggle_Marked_Review;

   function Has_Marked_Review (State : Buffer_Switcher_State) return Boolean is
   begin
      return Has_Switcher_Review_Mode (State, Marked_Review);
   end Has_Marked_Review;

   function Marked_Review_Description (State : Buffer_Switcher_State) return String is
   begin
      if Has_Marked_Review (State) then
         return "marked";
      else
         return "off";
      end if;
   end Marked_Review_Description;

   procedure Show_Pending_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      if State.Pending_Action /= No_Pending_Marked_Action
        and then Natural (State.Pending_Targets.Length) > 0
      then
         Set_Switcher_Review_Mode (State, Pending_Marked_Close_Review);
      end if;
   end Show_Pending_Marked_Review;

   procedure Hide_Pending_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      Clear_Switcher_Review_Mode (State, Pending_Marked_Close_Review);
   end Hide_Pending_Marked_Review;

   procedure Toggle_Pending_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      if Has_Pending_Marked_Review (State) then
         Hide_Pending_Marked_Review (State);
      else
         Show_Pending_Marked_Review (State);
      end if;
   end Toggle_Pending_Marked_Review;

   function Has_Pending_Marked_Review (State : Buffer_Switcher_State) return Boolean is
   begin
      return Has_Switcher_Review_Mode (State, Pending_Marked_Close_Review);
   end Has_Pending_Marked_Review;

   function Pending_Marked_Review_Description (State : Buffer_Switcher_State) return String is
   begin
      if Has_Pending_Marked_Review (State) then
         return "pending close";
      else
         return "off";
      end if;
   end Pending_Marked_Review_Description;

   procedure Show_Pruned_Pending_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      if State.Pending_Action = Pending_Marked_Close
        and then Natural (State.Pruned_Pending_Targets.Length) > 0
      then
         Set_Switcher_Review_Mode (State, Pruned_Pending_Close_Review);
      end if;
   end Show_Pruned_Pending_Marked_Review;

   procedure Hide_Pruned_Pending_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      Clear_Switcher_Review_Mode (State, Pruned_Pending_Close_Review);
   end Hide_Pruned_Pending_Marked_Review;

   procedure Toggle_Pruned_Pending_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      if Has_Pruned_Pending_Marked_Review (State) then
         Hide_Pruned_Pending_Marked_Review (State);
      else
         Show_Pruned_Pending_Marked_Review (State);
      end if;
   end Toggle_Pruned_Pending_Marked_Review;

   function Has_Pruned_Pending_Marked_Review (State : Buffer_Switcher_State) return Boolean is
   begin
      return Has_Switcher_Review_Mode (State, Pruned_Pending_Close_Review);
   end Has_Pruned_Pending_Marked_Review;

   function Pruned_Pending_Marked_Review_Description (State : Buffer_Switcher_State) return String is
   begin
      if Has_Pruned_Pending_Marked_Review (State) then
         return "pruned pending close";
      else
         return "off";
      end if;
   end Pruned_Pending_Marked_Review_Description;

   procedure Show_Dirty_Pending_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      if State.Pending_Action = Pending_Marked_Close then
         Set_Switcher_Review_Mode (State, Dirty_Pending_Close_Review);
      end if;
   end Show_Dirty_Pending_Marked_Review;

   procedure Hide_Dirty_Pending_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      Clear_Switcher_Review_Mode (State, Dirty_Pending_Close_Review);
   end Hide_Dirty_Pending_Marked_Review;

   procedure Toggle_Dirty_Pending_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      if Has_Dirty_Pending_Marked_Review (State) then
         Hide_Dirty_Pending_Marked_Review (State);
      else
         Show_Dirty_Pending_Marked_Review (State);
      end if;
   end Toggle_Dirty_Pending_Marked_Review;

   function Has_Dirty_Pending_Marked_Review (State : Buffer_Switcher_State) return Boolean is
   begin
      return Has_Switcher_Review_Mode (State, Dirty_Pending_Close_Review);
   end Has_Dirty_Pending_Marked_Review;

   function Dirty_Pending_Marked_Review_Description (State : Buffer_Switcher_State) return String is
   begin
      if Has_Dirty_Pending_Marked_Review (State) then
         return "dirty pending close";
      else
         return "off";
      end if;
   end Dirty_Pending_Marked_Review_Description;

   procedure Show_Dirty_Prune_Review (State : in out Buffer_Switcher_State) is
   begin
      if Natural (State.Dirty_Prune_Targets.Length) > 0 then
         Set_Switcher_Review_Mode (State, Dirty_Prune_Preview_Review);
      end if;
   end Show_Dirty_Prune_Review;

   procedure Hide_Dirty_Prune_Review (State : in out Buffer_Switcher_State) is
   begin
      Clear_Switcher_Review_Mode (State, Dirty_Prune_Preview_Review);
   end Hide_Dirty_Prune_Review;

   procedure Toggle_Dirty_Prune_Review (State : in out Buffer_Switcher_State) is
   begin
      if Has_Dirty_Prune_Review (State) then
         Hide_Dirty_Prune_Review (State);
      else
         Show_Dirty_Prune_Review (State);
      end if;
   end Toggle_Dirty_Prune_Review;

   function Has_Dirty_Prune_Review (State : Buffer_Switcher_State) return Boolean is
   begin
      return Has_Switcher_Review_Mode (State, Dirty_Prune_Preview_Review);
   end Has_Dirty_Prune_Review;

   function Dirty_Prune_Review_Description (State : Buffer_Switcher_State) return String is
   begin
      if Has_Dirty_Prune_Review (State) then
         return "dirty prune preview";
      else
         return "off";
      end if;
   end Dirty_Prune_Review_Description;

   procedure Show_Removed_Dirty_Prune_Review (State : in out Buffer_Switcher_State) is
   begin
      if Natural (State.Removed_Dirty_Prune_Targets.Length) > 0 then
         Set_Switcher_Review_Mode (State, Removed_Dirty_Prune_Preview_Review);
      end if;
   end Show_Removed_Dirty_Prune_Review;

   procedure Hide_Removed_Dirty_Prune_Review (State : in out Buffer_Switcher_State) is
   begin
      Clear_Switcher_Review_Mode (State, Removed_Dirty_Prune_Preview_Review);
   end Hide_Removed_Dirty_Prune_Review;

   procedure Toggle_Removed_Dirty_Prune_Review (State : in out Buffer_Switcher_State) is
   begin
      if Has_Removed_Dirty_Prune_Review (State) then
         Hide_Removed_Dirty_Prune_Review (State);
      else
         Show_Removed_Dirty_Prune_Review (State);
      end if;
   end Toggle_Removed_Dirty_Prune_Review;

   function Has_Removed_Dirty_Prune_Review (State : Buffer_Switcher_State) return Boolean is
   begin
      return Has_Switcher_Review_Mode (State, Removed_Dirty_Prune_Preview_Review);
   end Has_Removed_Dirty_Prune_Review;

   function Removed_Dirty_Prune_Review_Description (State : Buffer_Switcher_State) return String is
   begin
      if Has_Removed_Dirty_Prune_Review (State) then
         return "removed dirty-prune targets";
      else
         return "off";
      end if;
   end Removed_Dirty_Prune_Review_Description;

   procedure Show_Dirty_Prune_Apply_Review (State : in out Buffer_Switcher_State) is
   begin
      if Natural (State.Dirty_Prune_Apply_Targets.Length) > 0 then
         Set_Switcher_Review_Mode (State, Dirty_Prune_Apply_Review);
      end if;
   end Show_Dirty_Prune_Apply_Review;

   procedure Hide_Dirty_Prune_Apply_Review (State : in out Buffer_Switcher_State) is
   begin
      Clear_Switcher_Review_Mode (State, Dirty_Prune_Apply_Review);
   end Hide_Dirty_Prune_Apply_Review;

   procedure Toggle_Dirty_Prune_Apply_Review (State : in out Buffer_Switcher_State) is
   begin
      if Has_Dirty_Prune_Apply_Review (State) then
         Hide_Dirty_Prune_Apply_Review (State);
      else
         Show_Dirty_Prune_Apply_Review (State);
      end if;
   end Toggle_Dirty_Prune_Apply_Review;

   function Has_Dirty_Prune_Apply_Review (State : Buffer_Switcher_State) return Boolean is
   begin
      return Has_Switcher_Review_Mode (State, Dirty_Prune_Apply_Review);
   end Has_Dirty_Prune_Apply_Review;

   function Dirty_Prune_Apply_Review_Description (State : Buffer_Switcher_State) return String is
   begin
      if Has_Dirty_Prune_Apply_Review (State) then
         return "dirty-prune apply";
      else
         return "off";
      end if;
   end Dirty_Prune_Apply_Review_Description;

   procedure Show_Removed_Dirty_Prune_Apply_Review (State : in out Buffer_Switcher_State) is
   begin
      if Natural (State.Removed_Dirty_Prune_Apply_Targets.Length) > 0 then
         Set_Switcher_Review_Mode (State, Removed_Dirty_Prune_Apply_Review);
      end if;
   end Show_Removed_Dirty_Prune_Apply_Review;

   procedure Hide_Removed_Dirty_Prune_Apply_Review (State : in out Buffer_Switcher_State) is
   begin
      Clear_Switcher_Review_Mode (State, Removed_Dirty_Prune_Apply_Review);
   end Hide_Removed_Dirty_Prune_Apply_Review;

   procedure Toggle_Removed_Dirty_Prune_Apply_Review (State : in out Buffer_Switcher_State) is
   begin
      if Has_Removed_Dirty_Prune_Apply_Review (State) then
         Hide_Removed_Dirty_Prune_Apply_Review (State);
      else
         Show_Removed_Dirty_Prune_Apply_Review (State);
      end if;
   end Toggle_Removed_Dirty_Prune_Apply_Review;

   function Has_Removed_Dirty_Prune_Apply_Review (State : Buffer_Switcher_State) return Boolean is
   begin
      return Has_Switcher_Review_Mode (State, Removed_Dirty_Prune_Apply_Review);
   end Has_Removed_Dirty_Prune_Apply_Review;

   function Removed_Dirty_Prune_Apply_Review_Description (State : Buffer_Switcher_State) return String is
   begin
      if Has_Removed_Dirty_Prune_Apply_Review (State) then
         return "removed dirty-prune apply targets";
      else
         return "off";
      end if;
   end Removed_Dirty_Prune_Apply_Review_Description;

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

   function Is_Marked
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffers.Buffer_Id) return Boolean is
   begin
      return Mark_Index (State, Id) /= 0;
   end Is_Marked;

   procedure Set_Row_Marked
     (State  : in out Buffer_Switcher_State;
      Id     : Editor.Buffers.Buffer_Id;
      Marked : Boolean)
   is
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

   procedure Set_Mark
     (State : in out Buffer_Switcher_State;
      Id    : Editor.Buffers.Buffer_Id)
   is
   begin
      if Id /= Editor.Buffers.No_Buffer and then not Is_Marked (State, Id) then
         State.Marks.Append (Id);
      end if;
      Set_Row_Marked (State, Id, True);
   end Set_Mark;

   procedure Clear_Mark
     (State : in out Buffer_Switcher_State;
      Id    : Editor.Buffers.Buffer_Id)
   is
      Pos : constant Natural := Mark_Index (State, Id);
   begin
      if Pos /= 0 then
         State.Marks.Delete (Pos - 1);
      end if;
      Set_Row_Marked (State, Id, False);
   end Clear_Mark;

   procedure Toggle_Mark
     (State : in out Buffer_Switcher_State;
      Id    : Editor.Buffers.Buffer_Id)
   is
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

   procedure Prune_Marks
     (State    : in out Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry)
   is
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

      if Editor.Buffer_Switcher.Filters.Has_Metadata_Filter (State) then
         Add ("Filter: " &
              Editor.Buffer_Switcher.Filters.Metadata_Filter_Description (State));
      end if;

      if Editor.Input_Field.Text (State.Field)'Length > 0 then
         Add ("Query: " & Editor.Input_Field.Text (State.Field));
      end if;

      if State.Active_Sort /= Editor.Buffer_Switcher.Filters.Default_Sort then
         Add ("Sort: " &
              Editor.Buffer_Switcher.Filters.Sort_Mode_Description (State));
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
      Snapshot.Pending_Close_Count :=
        Editor.Buffer_Switcher.Pending_Close_Operations.Pending_Marked_Open_Count
          (State, Registry);
      Snapshot.Dirty_Pending_Close_Count :=
        Editor.Buffer_Switcher.Pending_Close_Operations.Pending_Marked_Open_Dirty_Count
          (State, Registry);
      Snapshot.Pruned_Pending_Close_Count :=
        Editor.Buffer_Switcher.Pending_Close_Operations.Pruned_Pending_Marked_Close_Target_Count
          (State);
      Snapshot.Dirty_Prune_Preview_Count :=
        Editor.Buffer_Switcher.Dirty_Prune_Operations.Dirty_Pending_Marked_Close_Prune_Target_Count
          (State);
      Snapshot.Applicable_Dirty_Prune_Preview_Count :=
        Editor.Buffer_Switcher.Dirty_Prune_Operations.Applicable_Dirty_Pending_Marked_Close_Prune_Target_Count
          (State, Registry);
      Snapshot.Removed_Dirty_Prune_Preview_Count :=
        Editor.Buffer_Switcher.Dirty_Prune_Operations.Removed_Dirty_Pending_Marked_Close_Prune_Target_Count
          (State);
      Snapshot.Open_Removed_Dirty_Prune_Preview_Count :=
        Editor.Buffer_Switcher.Dirty_Prune_Operations.Open_Removed_Dirty_Pending_Marked_Close_Prune_Target_Count
          (State, Registry);
      Snapshot.Stale_Dirty_Prune_Preview_Count :=
        Editor.Buffer_Switcher.Dirty_Prune_Operations.Dirty_Pending_Marked_Close_Prune_Stale_Target_Count
          (State, Registry);
      Snapshot.Dirty_Prune_Apply_Count :=
        Editor.Buffer_Switcher.Dirty_Prune_Operations.Dirty_Pending_Marked_Close_Prune_Apply_Target_Count
          (State);
      Snapshot.Applicable_Dirty_Prune_Apply_Count :=
        Editor.Buffer_Switcher.Dirty_Prune_Operations.Applicable_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count
          (State, Registry);
      Snapshot.Removed_Dirty_Prune_Apply_Count :=
        Editor.Buffer_Switcher.Dirty_Prune_Operations.Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count
          (State);
      Snapshot.Open_Removed_Dirty_Prune_Apply_Count :=
        Editor.Buffer_Switcher.Dirty_Prune_Operations.Open_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count
          (State, Registry);
      Snapshot.Stale_Dirty_Prune_Apply_Count :=
        Editor.Buffer_Switcher.Dirty_Prune_Operations.Dirty_Pending_Marked_Close_Prune_Apply_Stale_Target_Count
          (State, Registry);
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

end Editor.Buffer_Switcher.Review_Operations;
