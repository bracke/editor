with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffers;
with Editor.Buffer_Switcher.Review_Operations;

package body Editor.Buffer_Switcher.Pending_Close_Operations is

   use type Editor.Buffer_Types.Buffer_Id;

   function Is_Pending_Marked_Close_Target
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffer_Types.Buffer_Id) return Boolean
   is
   begin
      if Id = Editor.Buffers.No_Buffer
        or else State.Pending_Action /= Pending_Marked_Close
      then
         return False;
      end if;

      for I in 1 .. Natural (State.Pending_Targets.Length) loop
         if State.Pending_Targets (I - 1) = Id then
            return True;
         end if;
      end loop;

      return False;
   end Is_Pending_Marked_Close_Target;

   function Row_Is_Dirty_Prune_Apply_Target
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffer_Types.Buffer_Id) return Boolean
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

   function Build_Switcher_Row_Markers
     (State : Buffer_Switcher_State;
      Row   : Buffer_Switcher_Row) return Buffer_Switcher_Row
   is
      Result : Buffer_Switcher_Row := Row;
   begin
      Result.Is_Marked := Is_Marked (State, Row.Id);
      Result.Is_Pending_Close_Target := Is_Pending_Marked_Close_Target (State, Row.Id);
      Result.Is_Ordinary_Pruned_Target := Is_Pruned_Pending_Marked_Close_Target (State, Row.Id);
      Result.Is_Dirty_Prune_Preview_Target := Row_Is_Dirty_Prune_Target (State, Row.Id);
      Result.Is_Removed_Dirty_Prune_Preview_Target :=
        Is_Removed_Dirty_Pending_Marked_Close_Prune_Target (State, Row.Id);
      Result.Is_Dirty_Prune_Apply_Target := Row_Is_Dirty_Prune_Apply_Target (State, Row.Id);
      Result.Is_Removed_Dirty_Prune_Apply_Target :=
        Is_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target (State, Row.Id);
      return Result;
   end Build_Switcher_Row_Markers;

   function Has_Pruned_Pending_Marked_Close_Targets
     (State : Buffer_Switcher_State) return Boolean is
   begin
      return State.Pending_Action = Pending_Marked_Close
        and then Natural (State.Pruned_Pending_Targets.Length) > 0;
   end Has_Pruned_Pending_Marked_Close_Targets;

   function Pruned_Pending_Marked_Close_Target_Count
     (State : Buffer_Switcher_State) return Natural is
   begin
      if State.Pending_Action /= Pending_Marked_Close then
         return 0;
      end if;
      return Natural (State.Pruned_Pending_Targets.Length);
   end Pruned_Pending_Marked_Close_Target_Count;

   function Open_Pruned_Pending_Marked_Close_Target_Count
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural
   is
      Count : Natural := 0;
   begin
      if State.Pending_Action /= Pending_Marked_Close then
         return 0;
      end if;
      for I in 1 .. Natural (State.Pruned_Pending_Targets.Length) loop
         if Editor.Buffers.Contains (Registry, State.Pruned_Pending_Targets (I - 1).Id) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Open_Pruned_Pending_Marked_Close_Target_Count;

   function Last_Pruned_Pending_Marked_Close_Target_Name
     (State : Buffer_Switcher_State) return String is
   begin
      if State.Pending_Action /= Pending_Marked_Close
        or else Natural (State.Pruned_Pending_Targets.Length) = 0
      then
         return "";
      end if;

      return To_String
        (State.Pruned_Pending_Targets
           (Natural (State.Pruned_Pending_Targets.Length) - 1).Display_Name);
   end Last_Pruned_Pending_Marked_Close_Target_Name;

   function Is_Pruned_Pending_Marked_Close_Target
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffer_Types.Buffer_Id) return Boolean
   is
   begin
      if Id = Editor.Buffers.No_Buffer
        or else State.Pending_Action /= Pending_Marked_Close
      then
         return False;
      end if;

      for I in 1 .. Natural (State.Pruned_Pending_Targets.Length) loop
         if State.Pruned_Pending_Targets (I - 1).Id = Id then
            return True;
         end if;
      end loop;

      return False;
   end Is_Pruned_Pending_Marked_Close_Target;

   procedure Clear_Pending_Marked_Action (State : in out Buffer_Switcher_State) is
   begin
      State.Pending_Action := No_Pending_Marked_Action;
      State.Pending_Targets.Clear;
      State.Pending_Target_Original_Positions.Clear;
      State.Pruned_Pending_Targets.Clear;
      State.Dirty_Prune_Targets.Clear;
      State.Removed_Dirty_Prune_Targets.Clear;
      State.Dirty_Prune_Apply_Targets.Clear;
      State.Removed_Dirty_Prune_Apply_Targets.Clear;
      Review_Operations.Clear_Pending_Marked_Review_Modes (State);
      Review_Operations.Clear_Dirty_Prune_Preview_Review_Modes (State);
      Review_Operations.Clear_Dirty_Prune_Apply_Review_Modes (State);
      State.Pending_Count := 0;
      State.Pending_Dirty_Count := 0;
   end Clear_Pending_Marked_Action;

   function Pending_Marked_Action
     (State : Buffer_Switcher_State) return Pending_Marked_Action_Kind is
   begin
      return State.Pending_Action;
   end Pending_Marked_Action;

   function Pending_Marked_Target_Count
     (State : Buffer_Switcher_State) return Natural is
   begin
      return State.Pending_Count;
   end Pending_Marked_Target_Count;

   function Pending_Marked_Dirty_Count
     (State : Buffer_Switcher_State) return Natural is
   begin
      return State.Pending_Dirty_Count;
   end Pending_Marked_Dirty_Count;

   function Pending_Marked_Target_At
     (State : Buffer_Switcher_State;
      Index : Positive) return Editor.Buffer_Types.Buffer_Id
   is
   begin
      if Index > Natural (State.Pending_Targets.Length) then
         return Editor.Buffers.No_Buffer;
      end if;
      return State.Pending_Targets (Index - 1);
   end Pending_Marked_Target_At;

   procedure Prepare_Pending_Marked_Close
     (State       : in out Buffer_Switcher_State;
      Registry    : Editor.Buffers.Buffer_Registry;
      Count       : out Natural;
      Dirty_Count : out Natural)
   is
      Review_Was_Active : constant Boolean := State.Active_Review = Pending_Marked_Close_Review;
   begin
      Clear_Pending_Marked_Action (State);
      Count := 0;
      Dirty_Count := 0;
      for I in 1 .. Natural (State.Marks.Length) loop
         declare
            Id : constant Editor.Buffers.Buffer_Id := State.Marks (I - 1);
         begin
            for J in 1 .. Editor.Buffers.Count (Registry) loop
               declare
                  Summary : constant Editor.Buffers.Buffer_Summary :=
                    Editor.Buffers.Summary_At (Registry, J);
               begin
                  if Summary.Id = Id then
                     State.Pending_Targets.Append (Id);
                     State.Pending_Target_Original_Positions.Append (Count);
                     Count := Count + 1;
                     if Summary.Is_Dirty then
                        Dirty_Count := Dirty_Count + 1;
                     end if;
                     exit;
                  end if;
               end;
            end loop;
         end;
      end loop;
      if Count > 0 then
         State.Pending_Action := Pending_Marked_Close;
         State.Pending_Count := Count;
         State.Pending_Dirty_Count := Dirty_Count;
         if Review_Was_Active then
            State.Active_Review := Pending_Marked_Close_Review;
         end if;
      end if;
   end Prepare_Pending_Marked_Close;

   function Pending_Marked_Open_Count
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural
   is
      Count : Natural := 0;
   begin
      if State.Pending_Action = No_Pending_Marked_Action then
         return 0;
      end if;
      for I in 1 .. Natural (State.Pending_Targets.Length) loop
         for J in 1 .. Editor.Buffers.Count (Registry) loop
            if Editor.Buffers.Summary_At (Registry, J).Id = State.Pending_Targets (I - 1) then
               Count := Count + 1;
               exit;
            end if;
         end loop;
      end loop;
      return Count;
   end Pending_Marked_Open_Count;

   function Pending_Marked_Open_Dirty_Count
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural
   is
      Count : Natural := 0;
   begin
      if State.Pending_Action = No_Pending_Marked_Action then
         return 0;
      end if;

      for I in 1 .. Natural (State.Pending_Targets.Length) loop
         for J in 1 .. Editor.Buffers.Count (Registry) loop
            declare
               Summary : constant Editor.Buffers.Buffer_Summary :=
                 Editor.Buffers.Summary_At (Registry, J);
            begin
               if Summary.Id = State.Pending_Targets (I - 1) then
                  if Summary.Is_Dirty then
                     Count := Count + 1;
                  end if;
                  exit;
               end if;
            end;
         end loop;
      end loop;

      return Count;
   end Pending_Marked_Open_Dirty_Count;

   procedure Remove_Pending_Marked_Close_Target
     (State       : in out Buffer_Switcher_State;
      Registry    : Editor.Buffers.Buffer_Registry;
      Id          : Editor.Buffer_Types.Buffer_Id;
      Removed     : out Boolean;
      Remaining   : out Natural)
   is
      Removed_Index    : Natural := 0;
      Removed_Found    : Boolean := False;
      Dirty_Count      : Natural := 0;
      Removed_Position : Natural := 0;
      Removed_Name     : Unbounded_String := Null_Unbounded_String;
   begin
      Removed := False;
      Remaining := Pending_Marked_Target_Count (State);

      if State.Pending_Action /= Pending_Marked_Close
        or else Id = Editor.Buffers.No_Buffer
      then
         return;
      end if;

      for I in 1 .. Natural (State.Pending_Targets.Length) loop
         if State.Pending_Targets (I - 1) = Id then
            Removed_Index := I - 1;
            Removed_Found := True;
            exit;
         end if;
      end loop;

      if not Removed_Found then
         return;
      end if;

      if Removed_Index < Natural (State.Pending_Target_Original_Positions.Length) then
         Removed_Position := State.Pending_Target_Original_Positions (Removed_Index);
      else
         Removed_Position := Removed_Index;
      end if;

      for J in 1 .. Editor.Buffers.Count (Registry) loop
         declare
            Summary : constant Editor.Buffers.Buffer_Summary := Editor.Buffers.Summary_At (Registry, J);
         begin
            if Summary.Id = Id then
               Removed_Name := To_Unbounded_String (Editor.Buffers.Display_Name (Registry, Id));
               exit;
            end if;
         end;
      end loop;
      if Length (Removed_Name) = 0 then
         Removed_Name := To_Unbounded_String ("unnamed buffer");
      end if;

      State.Pending_Targets.Delete (Removed_Index);
      if Removed_Index < Natural (State.Pending_Target_Original_Positions.Length) then
         State.Pending_Target_Original_Positions.Delete (Removed_Index);
      end if;
      Removed := True;

      if Natural (State.Pending_Targets.Length) = 0 then
         Clear_Pending_Marked_Action (State);
         Remaining := 0;
         return;
      end if;

      declare
         I : Natural := 1;
      begin
         while I <= Natural (State.Pruned_Pending_Targets.Length) loop
            if State.Pruned_Pending_Targets (I - 1).Id = Id then
               State.Pruned_Pending_Targets.Delete (I - 1);
            else
               I := I + 1;
            end if;
         end loop;
      end;
      State.Pruned_Pending_Targets.Append
        (Pruned_Pending_Target'(Id                => Id,
          Display_Name      => Removed_Name,
          Original_Position => Removed_Position));

      State.Pending_Count := Natural (State.Pending_Targets.Length);
      for I in 1 .. Natural (State.Pending_Targets.Length) loop
         declare
            Target : constant Editor.Buffers.Buffer_Id := State.Pending_Targets (I - 1);
         begin
            for J in 1 .. Editor.Buffers.Count (Registry) loop
               declare
                  Summary : constant Editor.Buffers.Buffer_Summary := Editor.Buffers.Summary_At (Registry, J);
               begin
                  if Summary.Id = Target then
                     if Summary.Is_Dirty then
                        Dirty_Count := Dirty_Count + 1;
                     end if;
                     exit;
                  end if;
               end;
            end loop;
         end;
      end loop;
      State.Pending_Dirty_Count := Dirty_Count;
      Remaining := State.Pending_Count;
   end Remove_Pending_Marked_Close_Target;

   procedure Restore_Last_Pruned_Pending_Marked_Close_Target
     (State        : in out Buffer_Switcher_State;
      Registry     : Editor.Buffers.Buffer_Registry;
      Restored     : out Boolean;
      Target       : out Editor.Buffer_Types.Buffer_Id;
      Display_Name : out Ada.Strings.Unbounded.Unbounded_String;
      Remaining    : out Natural)
   is
      Entry_Index  : Natural := 0;
      Item        : Pruned_Pending_Target;
      Insert_Index : Natural := 0;
      Dirty_Count  : Natural := 0;
   begin
      Restored := False;
      Target := Editor.Buffers.No_Buffer;
      Display_Name := Null_Unbounded_String;
      Remaining := Pending_Marked_Target_Count (State);

      if State.Pending_Action /= Pending_Marked_Close
        or else Natural (State.Pruned_Pending_Targets.Length) = 0
      then
         return;
      end if;

      Entry_Index := Natural (State.Pruned_Pending_Targets.Length) - 1;
      Item := State.Pruned_Pending_Targets (Entry_Index);
      Target := Item.Id;
      Display_Name := Item.Display_Name;

      if not Editor.Buffers.Contains (Registry, Item.Id) then
         return;
      end if;

      if Is_Pending_Marked_Close_Target (State, Item.Id) then
         State.Pruned_Pending_Targets.Delete (Entry_Index);
         Restored := True;
         Remaining := State.Pending_Count;
         return;
      end if;

      Insert_Index := Natural (State.Pending_Targets.Length);
      for I in 1 .. Natural (State.Pending_Target_Original_Positions.Length) loop
         if State.Pending_Target_Original_Positions (I - 1) > Item.Original_Position then
            Insert_Index := I - 1;
            exit;
         end if;
      end loop;

      State.Pending_Targets.Insert (Insert_Index, Item.Id);
      State.Pending_Target_Original_Positions.Insert (Insert_Index, Item.Original_Position);
      State.Pruned_Pending_Targets.Delete (Entry_Index);

      State.Pending_Count := Natural (State.Pending_Targets.Length);
      for I in 1 .. Natural (State.Pending_Targets.Length) loop
         declare
            Current : constant Editor.Buffers.Buffer_Id := State.Pending_Targets (I - 1);
         begin
            for J in 1 .. Editor.Buffers.Count (Registry) loop
               declare
                  Summary : constant Editor.Buffers.Buffer_Summary := Editor.Buffers.Summary_At (Registry, J);
               begin
                  if Summary.Id = Current then
                     if Summary.Is_Dirty then
                        Dirty_Count := Dirty_Count + 1;
                     end if;
                     exit;
                  end if;
               end;
            end loop;
         end;
      end loop;
      State.Pending_Dirty_Count := Dirty_Count;
      Restored := True;
      Remaining := State.Pending_Count;
   end Restore_Last_Pruned_Pending_Marked_Close_Target;

   procedure Restore_Pruned_Pending_Marked_Close_Target
     (State        : in out Buffer_Switcher_State;
      Registry     : Editor.Buffers.Buffer_Registry;
      Id           : Editor.Buffer_Types.Buffer_Id;
      Restored     : out Boolean;
      Display_Name : out Ada.Strings.Unbounded.Unbounded_String;
      Remaining    : out Natural)
   is
      Entry_Index  : Natural := 0;
      Item        : Pruned_Pending_Target;
      Found        : Boolean := False;
      Insert_Index : Natural := 0;
      Dirty_Count  : Natural := 0;
   begin
      Restored := False;
      Display_Name := Null_Unbounded_String;
      Remaining := Pending_Marked_Target_Count (State);

      if State.Pending_Action /= Pending_Marked_Close
        or else Id = Editor.Buffers.No_Buffer
      then
         return;
      end if;

      for I in 1 .. Natural (State.Pruned_Pending_Targets.Length) loop
         if State.Pruned_Pending_Targets (I - 1).Id = Id then
            Entry_Index := I - 1;
            Item := State.Pruned_Pending_Targets (I - 1);
            Found := True;
            exit;
         end if;
      end loop;

      if not Found then
         return;
      end if;

      Display_Name := Item.Display_Name;
      if not Editor.Buffers.Contains (Registry, Item.Id) then
         return;
      end if;

      if Is_Pending_Marked_Close_Target (State, Item.Id) then
         State.Pruned_Pending_Targets.Delete (Entry_Index);
         Restored := True;
         Remaining := State.Pending_Count;
         return;
      end if;

      Insert_Index := Natural (State.Pending_Targets.Length);
      for I in 1 .. Natural (State.Pending_Target_Original_Positions.Length) loop
         if State.Pending_Target_Original_Positions (I - 1) > Item.Original_Position then
            Insert_Index := I - 1;
            exit;
         end if;
      end loop;

      State.Pending_Targets.Insert (Insert_Index, Item.Id);
      State.Pending_Target_Original_Positions.Insert (Insert_Index, Item.Original_Position);
      State.Pruned_Pending_Targets.Delete (Entry_Index);

      State.Pending_Count := Natural (State.Pending_Targets.Length);
      for I in 1 .. Natural (State.Pending_Targets.Length) loop
         declare
            Current : constant Editor.Buffers.Buffer_Id := State.Pending_Targets (I - 1);
         begin
            for J in 1 .. Editor.Buffers.Count (Registry) loop
               declare
                  Summary : constant Editor.Buffers.Buffer_Summary := Editor.Buffers.Summary_At (Registry, J);
               begin
                  if Summary.Id = Current then
                     if Summary.Is_Dirty then
                        Dirty_Count := Dirty_Count + 1;
                     end if;
                     exit;
                  end if;
               end;
            end loop;
         end;
      end loop;
      State.Pending_Dirty_Count := Dirty_Count;
      Restored := True;
      Remaining := State.Pending_Count;
   end Restore_Pruned_Pending_Marked_Close_Target;

end Editor.Buffer_Switcher.Pending_Close_Operations;
