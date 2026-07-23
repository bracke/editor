with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffers;
with Editor.Buffer_Switcher.Pending_Close_Operations;
with Editor.Buffer_Switcher.Review_Operations;

package body Editor.Buffer_Switcher.Dirty_Prune_Operations is

   use type Editor.Buffer_Types.Buffer_Id;
   use type Editor.Buffers.Buffer_Dirty_Category;

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

   function Is_Open_Dirty_Pending_Target
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry;
      Id       : Editor.Buffers.Buffer_Id) return Boolean
   is
   begin
      if Id = Editor.Buffers.No_Buffer
        or else not Pending_Close_Operations.Is_Pending_Marked_Close_Target (State, Id)
      then
         return False;
      end if;

      for J in 1 .. Editor.Buffers.Count (Registry) loop
         declare
            Summary : constant Editor.Buffers.Buffer_Summary :=
              Editor.Buffers.Summary_At (Registry, J);
         begin
            if Summary.Id = Id then
               declare
                  No_Project : Editor.Project.Project_State;
                  Metadata : constant Editor.Buffers.Buffer_Metadata_Snapshot :=
                    Editor.Buffers.Metadata_For (Registry, No_Project, Summary.Id);
               begin
                  return Metadata.Dirty_Category /= Editor.Buffers.Buffer_Not_Dirty;
               end;
            end if;
         end;
      end loop;

      return False;
   end Is_Open_Dirty_Pending_Target;

   procedure Clear_Dirty_Prune_Apply_State (State : in out Buffer_Switcher_State) is
   begin
      State.Dirty_Prune_Apply_Targets.Clear;
      State.Removed_Dirty_Prune_Apply_Targets.Clear;
      Review_Operations.Clear_Dirty_Prune_Apply_Review_Modes (State);
   end Clear_Dirty_Prune_Apply_State;

   procedure Prepare_Dirty_Pending_Marked_Close_Prune
     (State    : in out Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry;
      Count    : out Natural)
   is
   begin
      State.Dirty_Prune_Targets.Clear;
      State.Removed_Dirty_Prune_Targets.Clear;
      Review_Operations.Clear_Dirty_Prune_Preview_Review_Modes (State);
      Clear_Dirty_Prune_Apply_State (State);
      Count := 0;

      if State.Pending_Action /= Pending_Marked_Close then
         return;
      end if;

      for I in 1 .. Natural (State.Pending_Targets.Length) loop
         declare
            Id : constant Editor.Buffers.Buffer_Id := State.Pending_Targets (I - 1);
         begin
            if Is_Open_Dirty_Pending_Target (State, Registry, Id) then
               State.Dirty_Prune_Targets.Append (Id);
               Count := Count + 1;
            end if;
         end;
      end loop;

      if Count = 0 then
         Review_Operations.Clear_Dirty_Prune_Preview_Review_Modes (State);
         Review_Operations.Clear_Dirty_Prune_Apply_Review_Modes (State);
      end if;
   end Prepare_Dirty_Pending_Marked_Close_Prune;

   function Has_Dirty_Pending_Marked_Close_Prune
     (State : Buffer_Switcher_State) return Boolean is
   begin
      return Natural (State.Dirty_Prune_Targets.Length) > 0;
   end Has_Dirty_Pending_Marked_Close_Prune;

   function Dirty_Pending_Marked_Close_Prune_Target_Count
     (State : Buffer_Switcher_State) return Natural is
   begin
      return Natural (State.Dirty_Prune_Targets.Length);
   end Dirty_Pending_Marked_Close_Prune_Target_Count;

   function Applicable_Dirty_Pending_Marked_Close_Prune_Target_Count
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural
   is
      Count : Natural := 0;
   begin
      if State.Pending_Action /= Pending_Marked_Close then
         return 0;
      end if;

      for I in 1 .. Natural (State.Dirty_Prune_Targets.Length) loop
         if Is_Open_Dirty_Pending_Target (State, Registry, State.Dirty_Prune_Targets (I - 1)) then
            Count := Count + 1;
         end if;
      end loop;

      return Count;
   end Applicable_Dirty_Pending_Marked_Close_Prune_Target_Count;

   function Dirty_Pending_Marked_Close_Prune_Stale_Target_Count
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural
   is
      Count : Natural := 0;
   begin
      if State.Pending_Action /= Pending_Marked_Close then
         return Natural (State.Dirty_Prune_Targets.Length);
      end if;

      for I in 1 .. Natural (State.Dirty_Prune_Targets.Length) loop
         if not Is_Open_Dirty_Pending_Target
           (State, Registry, State.Dirty_Prune_Targets (I - 1))
         then
            Count := Count + 1;
         end if;
      end loop;

      return Count;
   end Dirty_Pending_Marked_Close_Prune_Stale_Target_Count;

   function Has_Stale_Dirty_Pending_Marked_Close_Prune_Targets
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Boolean
   is
   begin
      return Dirty_Pending_Marked_Close_Prune_Stale_Target_Count
        (State, Registry) > 0;
   end Has_Stale_Dirty_Pending_Marked_Close_Prune_Targets;

   procedure Clear_Stale_Dirty_Pending_Marked_Close_Prune_Targets
     (State     : in out Buffer_Switcher_State;
      Registry  : Editor.Buffers.Buffer_Registry;
      Cleared   : out Natural;
      Remaining : out Natural)
   is
      I : Natural := 1;
   begin
      Cleared := 0;
      Remaining := Natural (State.Dirty_Prune_Targets.Length);

      while I <= Natural (State.Dirty_Prune_Targets.Length) loop
         if not Is_Open_Dirty_Pending_Target
           (State, Registry, State.Dirty_Prune_Targets (I - 1))
         then
            State.Dirty_Prune_Targets.Delete (I - 1);
            Cleared := Cleared + 1;
         else
            I := I + 1;
         end if;
      end loop;

      Remaining := Natural (State.Dirty_Prune_Targets.Length);
      if Remaining = 0 then
         State.Dirty_Prune_Targets.Clear;
         State.Removed_Dirty_Prune_Targets.Clear;
         Review_Operations.Clear_Dirty_Prune_Preview_Review_Modes (State);
      end if;
   end Clear_Stale_Dirty_Pending_Marked_Close_Prune_Targets;

   function Is_Dirty_Pending_Marked_Close_Prune_Target
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffers.Buffer_Id) return Boolean
   is
   begin
      return Row_Is_Dirty_Prune_Target (State, Id);
   end Is_Dirty_Pending_Marked_Close_Prune_Target;

   procedure Remove_Dirty_Pending_Marked_Close_Prune_Target
     (State     : in out Buffer_Switcher_State;
      Registry  : Editor.Buffers.Buffer_Registry;
      Id        : Editor.Buffers.Buffer_Id;
      Removed   : out Boolean;
      Remaining : out Natural)
   is
      Removed_Index    : Natural := 0;
      Found            : Boolean := False;
      Removed_Position : Natural := 0;
      Removed_Name     : Unbounded_String := Null_Unbounded_String;
   begin
      Removed := False;
      Remaining := Natural (State.Dirty_Prune_Targets.Length);

      if Id = Editor.Buffers.No_Buffer
        or else Natural (State.Dirty_Prune_Targets.Length) = 0
      then
         return;
      end if;

      for I in 1 .. Natural (State.Dirty_Prune_Targets.Length) loop
         if State.Dirty_Prune_Targets (I - 1) = Id then
            Removed_Index := I - 1;
            Found := True;
            exit;
         end if;
      end loop;

      if not Found then
         return;
      end if;

      Removed_Position := Removed_Index;
      for I in 1 .. Natural (State.Pending_Targets.Length) loop
         if State.Pending_Targets (I - 1) = Id then
            if I - 1 < Natural (State.Pending_Target_Original_Positions.Length) then
               Removed_Position := State.Pending_Target_Original_Positions (I - 1);
            else
               Removed_Position := I - 1;
            end if;
            exit;
         end if;
      end loop;

      for J in 1 .. Editor.Buffers.Count (Registry) loop
         declare
            Summary : constant Editor.Buffers.Buffer_Summary :=
              Editor.Buffers.Summary_At (Registry, J);
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

      State.Dirty_Prune_Targets.Delete (Removed_Index);

      declare
         I : Natural := 1;
      begin
         while I <= Natural (State.Removed_Dirty_Prune_Targets.Length) loop
            if State.Removed_Dirty_Prune_Targets (I - 1).Id = Id then
               State.Removed_Dirty_Prune_Targets.Delete (I - 1);
            else
               I := I + 1;
            end if;
         end loop;
      end;
      State.Removed_Dirty_Prune_Targets.Append
        (Pruned_Pending_Target'(Id                => Id,
          Display_Name      => Removed_Name,
          Original_Position => Removed_Position));

      Removed := True;
      Remaining := Natural (State.Dirty_Prune_Targets.Length);

      if Remaining = 0 then
         State.Dirty_Prune_Targets.Clear;
         State.Removed_Dirty_Prune_Targets.Clear;
         Review_Operations.Clear_Dirty_Prune_Preview_Review_Modes (State);
      end if;
   end Remove_Dirty_Pending_Marked_Close_Prune_Target;

   function Has_Removed_Dirty_Pending_Marked_Close_Prune_Targets
     (State : Buffer_Switcher_State) return Boolean is
   begin
      return Natural (State.Removed_Dirty_Prune_Targets.Length) > 0;
   end Has_Removed_Dirty_Pending_Marked_Close_Prune_Targets;

   function Removed_Dirty_Pending_Marked_Close_Prune_Target_Count
     (State : Buffer_Switcher_State) return Natural is
   begin
      return Natural (State.Removed_Dirty_Prune_Targets.Length);
   end Removed_Dirty_Pending_Marked_Close_Prune_Target_Count;

   function Open_Removed_Dirty_Pending_Marked_Close_Prune_Target_Count
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 1 .. Natural (State.Removed_Dirty_Prune_Targets.Length) loop
         if Editor.Buffers.Contains (Registry, State.Removed_Dirty_Prune_Targets (I - 1).Id) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Open_Removed_Dirty_Pending_Marked_Close_Prune_Target_Count;

   function Last_Removed_Dirty_Pending_Marked_Close_Prune_Target_Name
     (State : Buffer_Switcher_State) return String is
   begin
      if Natural (State.Removed_Dirty_Prune_Targets.Length) = 0 then
         return "";
      end if;
      return To_String
        (State.Removed_Dirty_Prune_Targets
           (Natural (State.Removed_Dirty_Prune_Targets.Length) - 1).Display_Name);
   end Last_Removed_Dirty_Pending_Marked_Close_Prune_Target_Name;

   function Is_Removed_Dirty_Pending_Marked_Close_Prune_Target
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffers.Buffer_Id) return Boolean
   is
   begin
      if Id = Editor.Buffers.No_Buffer then
         return False;
      end if;

      for I in 1 .. Natural (State.Removed_Dirty_Prune_Targets.Length) loop
         if State.Removed_Dirty_Prune_Targets (I - 1).Id = Id then
            return True;
         end if;
      end loop;

      return False;
   end Is_Removed_Dirty_Pending_Marked_Close_Prune_Target;

   procedure Restore_Last_Removed_Dirty_Pending_Marked_Close_Prune_Target
     (State        : in out Buffer_Switcher_State;
      Registry     : Editor.Buffers.Buffer_Registry;
      Restored     : out Boolean;
      Target       : out Editor.Buffers.Buffer_Id;
      Display_Name : out Ada.Strings.Unbounded.Unbounded_String;
      Remaining    : out Natural)
   is
      Entry_Index  : Natural := 0;
      Item        : Pruned_Pending_Target;
      Insert_Index : Natural := 0;
      Current_Position : Natural := 0;
   begin
      Restored := False;
      Target := Editor.Buffers.No_Buffer;
      Display_Name := Null_Unbounded_String;
      Remaining := Natural (State.Dirty_Prune_Targets.Length);

      if Natural (State.Removed_Dirty_Prune_Targets.Length) = 0 then
         return;
      end if;

      Entry_Index := Natural (State.Removed_Dirty_Prune_Targets.Length) - 1;
      Item := State.Removed_Dirty_Prune_Targets (Entry_Index);
      Target := Item.Id;
      Display_Name := Item.Display_Name;

      if not Editor.Buffers.Contains (Registry, Item.Id) then
         return;
      end if;

      if Row_Is_Dirty_Prune_Target (State, Item.Id) then
         State.Removed_Dirty_Prune_Targets.Delete (Entry_Index);
         Restored := True;
         Remaining := Natural (State.Dirty_Prune_Targets.Length);
         return;
      end if;

      Insert_Index := Natural (State.Dirty_Prune_Targets.Length);
      for I in 1 .. Natural (State.Dirty_Prune_Targets.Length) loop
         Current_Position := I - 1;
         for J in 1 .. Natural (State.Pending_Targets.Length) loop
            if State.Pending_Targets (J - 1) = State.Dirty_Prune_Targets (I - 1) then
               if J - 1 < Natural (State.Pending_Target_Original_Positions.Length) then
                  Current_Position := State.Pending_Target_Original_Positions (J - 1);
               else
                  Current_Position := J - 1;
               end if;
               exit;
            end if;
         end loop;

         if Current_Position > Item.Original_Position then
            Insert_Index := I - 1;
            exit;
         end if;
      end loop;

      State.Dirty_Prune_Targets.Insert (Insert_Index, Item.Id);
      State.Removed_Dirty_Prune_Targets.Delete (Entry_Index);
      Restored := True;
      Remaining := Natural (State.Dirty_Prune_Targets.Length);
   end Restore_Last_Removed_Dirty_Pending_Marked_Close_Prune_Target;

   procedure Cancel_Dirty_Pending_Marked_Close_Prune
     (State : in out Buffer_Switcher_State)
   is
   begin
      State.Dirty_Prune_Targets.Clear;
      State.Removed_Dirty_Prune_Targets.Clear;
      Review_Operations.Clear_Dirty_Prune_Preview_Review_Modes (State);
      Clear_Dirty_Prune_Apply_State (State);
   end Cancel_Dirty_Pending_Marked_Close_Prune;

   procedure Apply_Dirty_Pending_Marked_Close_Prune
     (State     : in out Buffer_Switcher_State;
      Registry  : Editor.Buffers.Buffer_Registry;
      Applied   : out Natural;
      Remaining : out Natural)
   is
      Captured : Mark_Vectors.Vector := State.Dirty_Prune_Targets;
      Removed  : Boolean := False;
   begin
      Applied := 0;
      Remaining := Pending_Close_Operations.Pending_Marked_Target_Count (State);

      if State.Pending_Action /= Pending_Marked_Close
        or else Natural (Captured.Length) = 0
      then
         State.Dirty_Prune_Targets.Clear;
         State.Removed_Dirty_Prune_Targets.Clear;
         Review_Operations.Clear_Dirty_Prune_Preview_Review_Modes (State);
         return;
      end if;

      for I in 1 .. Natural (Captured.Length) loop
         exit when State.Pending_Action /= Pending_Marked_Close;
         declare
            Id : constant Editor.Buffers.Buffer_Id := Captured (I - 1);
         begin
            if Is_Open_Dirty_Pending_Target (State, Registry, Id) then
               Pending_Close_Operations.Remove_Pending_Marked_Close_Target
                 (State, Registry, Id, Removed, Remaining);
               if Removed then
                  Applied := Applied + 1;
               end if;
            end if;
         end;
      end loop;

      State.Dirty_Prune_Targets.Clear;
      State.Removed_Dirty_Prune_Targets.Clear;
      Review_Operations.Clear_Dirty_Prune_Preview_Review_Modes (State);
      Remaining := Pending_Close_Operations.Pending_Marked_Target_Count (State);
   end Apply_Dirty_Pending_Marked_Close_Prune;

   procedure Prepare_Dirty_Pending_Marked_Close_Prune_Apply
     (State      : in out Buffer_Switcher_State;
      Registry   : Editor.Buffers.Buffer_Registry;
      Count      : out Natural;
      Applicable : out Natural)
   is
   begin
      Clear_Dirty_Prune_Apply_State (State);
      Count := 0;
      Applicable := 0;
      if not Has_Dirty_Pending_Marked_Close_Prune (State) then
         return;
      end if;
      for I in 1 .. Natural (State.Dirty_Prune_Targets.Length) loop
         declare
            Id : constant Editor.Buffers.Buffer_Id := State.Dirty_Prune_Targets (I - 1);
         begin
            State.Dirty_Prune_Apply_Targets.Append (Id);
            Count := Count + 1;
            if Is_Open_Dirty_Pending_Target (State, Registry, Id) then
               Applicable := Applicable + 1;
            end if;
         end;
      end loop;
   end Prepare_Dirty_Pending_Marked_Close_Prune_Apply;

   function Has_Dirty_Pending_Marked_Close_Prune_Apply
     (State : Buffer_Switcher_State) return Boolean is
   begin
      return Natural (State.Dirty_Prune_Apply_Targets.Length) > 0;
   end Has_Dirty_Pending_Marked_Close_Prune_Apply;

   function Dirty_Pending_Marked_Close_Prune_Apply_Target_Count
     (State : Buffer_Switcher_State) return Natural is
   begin
      return Natural (State.Dirty_Prune_Apply_Targets.Length);
   end Dirty_Pending_Marked_Close_Prune_Apply_Target_Count;

   function Applicable_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 1 .. Natural (State.Dirty_Prune_Apply_Targets.Length) loop
         if Is_Open_Dirty_Pending_Target
           (State, Registry, State.Dirty_Prune_Apply_Targets (I - 1))
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Applicable_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count;

   function Dirty_Pending_Marked_Close_Prune_Apply_Stale_Target_Count
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 1 .. Natural (State.Dirty_Prune_Apply_Targets.Length) loop
         if not Is_Open_Dirty_Pending_Target
           (State, Registry, State.Dirty_Prune_Apply_Targets (I - 1))
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Dirty_Pending_Marked_Close_Prune_Apply_Stale_Target_Count;

   procedure Clear_Stale_Dirty_Pending_Marked_Close_Prune_Apply_Targets
     (State     : in out Buffer_Switcher_State;
      Registry  : Editor.Buffers.Buffer_Registry;
      Cleared   : out Natural;
      Remaining : out Natural)
   is
      I : Natural := 1;
   begin
      Cleared := 0;
      while I <= Natural (State.Dirty_Prune_Apply_Targets.Length) loop
         if not Is_Open_Dirty_Pending_Target
           (State, Registry, State.Dirty_Prune_Apply_Targets (I - 1))
         then
            State.Dirty_Prune_Apply_Targets.Delete (I - 1);
            Cleared := Cleared + 1;
         else
            I := I + 1;
         end if;
      end loop;
      Remaining := Natural (State.Dirty_Prune_Apply_Targets.Length);
      if Remaining = 0 then
         Clear_Dirty_Prune_Apply_State (State);
      end if;
   end Clear_Stale_Dirty_Pending_Marked_Close_Prune_Apply_Targets;

   function Is_Dirty_Pending_Marked_Close_Prune_Apply_Target
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffers.Buffer_Id) return Boolean is
   begin
      return Row_Is_Dirty_Prune_Apply_Target (State, Id);
   end Is_Dirty_Pending_Marked_Close_Prune_Apply_Target;

   procedure Remove_Dirty_Pending_Marked_Close_Prune_Apply_Target
     (State     : in out Buffer_Switcher_State;
      Registry  : Editor.Buffers.Buffer_Registry;
      Id        : Editor.Buffers.Buffer_Id;
      Removed   : out Boolean;
      Remaining : out Natural)
   is
      Removed_Index : Natural := 0;
      Found         : Boolean := False;
      Removed_Name  : Unbounded_String := Null_Unbounded_String;
   begin
      Removed := False;
      Remaining := Natural (State.Dirty_Prune_Apply_Targets.Length);
      if Id = Editor.Buffers.No_Buffer then
         return;
      end if;
      for I in 1 .. Natural (State.Dirty_Prune_Apply_Targets.Length) loop
         if State.Dirty_Prune_Apply_Targets (I - 1) = Id then
            Removed_Index := I - 1;
            Found := True;
            exit;
         end if;
      end loop;
      if not Found then
         return;
      end if;
      for J in 1 .. Editor.Buffers.Count (Registry) loop
         declare
            Summary : constant Editor.Buffers.Buffer_Summary :=
              Editor.Buffers.Summary_At (Registry, J);
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
      State.Dirty_Prune_Apply_Targets.Delete (Removed_Index);
      declare
         I : Natural := 1;
      begin
         while I <= Natural (State.Removed_Dirty_Prune_Apply_Targets.Length) loop
            if State.Removed_Dirty_Prune_Apply_Targets (I - 1).Id = Id then
               State.Removed_Dirty_Prune_Apply_Targets.Delete (I - 1);
            else
               I := I + 1;
            end if;
         end loop;
      end;
      State.Removed_Dirty_Prune_Apply_Targets.Append
        (Pruned_Pending_Target'(Id                => Id,
          Display_Name      => Removed_Name,
          Original_Position => Removed_Index));
      Removed := True;
      Remaining := Natural (State.Dirty_Prune_Apply_Targets.Length);
      if Remaining = 0 then
         Review_Operations.Clear_Dirty_Prune_Apply_Review_Modes (State);
      end if;
   end Remove_Dirty_Pending_Marked_Close_Prune_Apply_Target;

   function Has_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Targets
     (State : Buffer_Switcher_State) return Boolean is
   begin
      return Natural (State.Removed_Dirty_Prune_Apply_Targets.Length) > 0;
   end Has_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Targets;

   function Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count
     (State : Buffer_Switcher_State) return Natural is
   begin
      return Natural (State.Removed_Dirty_Prune_Apply_Targets.Length);
   end Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count;

   function Open_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count
     (State    : Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 1 .. Natural (State.Removed_Dirty_Prune_Apply_Targets.Length) loop
         if Editor.Buffers.Contains (Registry, State.Removed_Dirty_Prune_Apply_Targets (I - 1).Id) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Open_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count;

   function Last_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target_Name
     (State : Buffer_Switcher_State) return String is
   begin
      if Natural (State.Removed_Dirty_Prune_Apply_Targets.Length) = 0 then
         return "";
      end if;
      return To_String
        (State.Removed_Dirty_Prune_Apply_Targets
           (Natural (State.Removed_Dirty_Prune_Apply_Targets.Length) - 1).Display_Name);
   end Last_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target_Name;

   function Is_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target
     (State : Buffer_Switcher_State;
      Id    : Editor.Buffers.Buffer_Id) return Boolean
   is
   begin
      if Id = Editor.Buffers.No_Buffer then
         return False;
      end if;
      for I in 1 .. Natural (State.Removed_Dirty_Prune_Apply_Targets.Length) loop
         if State.Removed_Dirty_Prune_Apply_Targets (I - 1).Id = Id then
            return True;
         end if;
      end loop;
      return False;
   end Is_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target;

   procedure Restore_Last_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target
     (State        : in out Buffer_Switcher_State;
      Registry     : Editor.Buffers.Buffer_Registry;
      Restored     : out Boolean;
      Target       : out Editor.Buffers.Buffer_Id;
      Display_Name : out Ada.Strings.Unbounded.Unbounded_String;
      Remaining    : out Natural)
   is
      Entry_Index  : Natural := 0;
      Item        : Pruned_Pending_Target;
      Insert_Index : Natural := 0;
   begin
      Restored := False;
      Target := Editor.Buffers.No_Buffer;
      Display_Name := Null_Unbounded_String;
      Remaining := Natural (State.Dirty_Prune_Apply_Targets.Length);
      if Natural (State.Removed_Dirty_Prune_Apply_Targets.Length) = 0 then
         return;
      end if;
      Entry_Index := Natural (State.Removed_Dirty_Prune_Apply_Targets.Length) - 1;
      Item := State.Removed_Dirty_Prune_Apply_Targets (Entry_Index);
      Target := Item.Id;
      Display_Name := Item.Display_Name;
      if not Editor.Buffers.Contains (Registry, Item.Id) then
         return;
      end if;
      if Row_Is_Dirty_Prune_Apply_Target (State, Item.Id) then
         State.Removed_Dirty_Prune_Apply_Targets.Delete (Entry_Index);
         Restored := True;
         return;
      end if;
      Insert_Index := Natural'Min (Item.Original_Position, Natural (State.Dirty_Prune_Apply_Targets.Length));
      State.Dirty_Prune_Apply_Targets.Insert (Insert_Index, Item.Id);
      State.Removed_Dirty_Prune_Apply_Targets.Delete (Entry_Index);
      Restored := True;
      Remaining := Natural (State.Dirty_Prune_Apply_Targets.Length);
   end Restore_Last_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target;

   procedure Confirm_Dirty_Pending_Marked_Close_Prune_Apply
     (State     : in out Buffer_Switcher_State;
      Registry  : Editor.Buffers.Buffer_Registry;
      Applied   : out Natural;
      Skipped   : out Natural;
      Remaining : out Natural)
   is
      Captured : Mark_Vectors.Vector := State.Dirty_Prune_Apply_Targets;
      Removed  : Boolean := False;
   begin
      Applied := 0;
      Skipped := 0;
      Remaining := Pending_Close_Operations.Pending_Marked_Target_Count (State);
      for I in 1 .. Natural (Captured.Length) loop
         declare
            Id : constant Editor.Buffers.Buffer_Id := Captured (I - 1);
         begin
            if Is_Open_Dirty_Pending_Target (State, Registry, Id) then
               Pending_Close_Operations.Remove_Pending_Marked_Close_Target
                 (State, Registry, Id, Removed, Remaining);
               if Removed then
                  Applied := Applied + 1;
               else
                  Skipped := Skipped + 1;
               end if;
            else
               Skipped := Skipped + 1;
            end if;
         end;
      end loop;
      Clear_Dirty_Prune_Apply_State (State);
      State.Dirty_Prune_Targets.Clear;
      State.Removed_Dirty_Prune_Targets.Clear;
      Review_Operations.Clear_Dirty_Prune_Preview_Review_Modes (State);
      Remaining := Pending_Close_Operations.Pending_Marked_Target_Count (State);
   end Confirm_Dirty_Pending_Marked_Close_Prune_Apply;

   procedure Cancel_Dirty_Pending_Marked_Close_Prune_Apply
     (State : in out Buffer_Switcher_State) is
   begin
      Clear_Dirty_Prune_Apply_State (State);
   end Cancel_Dirty_Pending_Marked_Close_Prune_Apply;

end Editor.Buffer_Switcher.Dirty_Prune_Operations;
