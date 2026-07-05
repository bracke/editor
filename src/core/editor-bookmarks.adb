with Ada.Containers; use Ada.Containers;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Bookmarks is

   function Entry_Less (Left, Right : Bookmark_Entry) return Boolean is
      L_Path : constant String := To_String (Left.File_Path);
      R_Path : constant String := To_String (Right.File_Path);
      L_Display : constant String := To_String (Left.Display_Path);
      R_Display : constant String := To_String (Right.Display_Path);
   begin
      if L_Path < R_Path then
         return True;
      elsif L_Path > R_Path then
         return False;
      elsif Left.Line_Number < Right.Line_Number then
         return True;
      elsif Left.Line_Number > Right.Line_Number then
         return False;
      elsif Left.Column < Right.Column then
         return True;
      elsif Left.Column > Right.Column then
         return False;
      else
         return L_Display < R_Display;
      end if;
   end Entry_Less;


   function Entry_After_Location
     (Item       : Bookmark_Entry;
      File_Path   : String;
      Line_Number : Natural;
      Column      : Natural;
      Has_Column  : Boolean) return Boolean
   is
      E_Path : constant String := To_String (Item.File_Path);
   begin
      if File_Path < E_Path then
         return True;
      elsif File_Path > E_Path then
         return False;
      elsif Line_Number < Item.Line_Number then
         return True;
      elsif Line_Number > Item.Line_Number then
         return False;
      elsif Has_Column and then Item.Has_Column then
         return Column < Item.Column;
      else
         return False;
      end if;
   end Entry_After_Location;

   function Entry_Before_Location
     (Item       : Bookmark_Entry;
      File_Path   : String;
      Line_Number : Natural;
      Column      : Natural;
      Has_Column  : Boolean) return Boolean
   is
      E_Path : constant String := To_String (Item.File_Path);
   begin
      if E_Path < File_Path then
         return True;
      elsif E_Path > File_Path then
         return False;
      elsif Item.Line_Number < Line_Number then
         return True;
      elsif Item.Line_Number > Line_Number then
         return False;
      elsif Has_Column and then Item.Has_Column then
         return Item.Column < Column;
      else
         return False;
      end if;
   end Entry_Before_Location;

   function Same_Key (Left, Right : Bookmark_Entry) return Boolean is
   begin
      return To_String (Left.File_Path) = To_String (Right.File_Path)
        and then Left.Line_Number = Right.Line_Number
        and then Left.Has_Column = Right.Has_Column
        and then (not Left.Has_Column or else Left.Column = Right.Column);
   end Same_Key;

   function Same_Location
     (Item       : Bookmark_Entry;
      File_Path   : String;
      Line_Number : Natural) return Boolean
   is
   begin
      return To_String (Item.File_Path) = File_Path
        and then Item.Line_Number = Line_Number;
   end Same_Location;

   function Index_Of_Key
     (State : Bookmark_State;
      Key   : Bookmark_Entry) return Natural
   is
   begin
      if State.Entries.Length = 0 then
         return 0;
      end if;
      for I in State.Entries.First_Index .. State.Entries.Last_Index loop
         if Same_Key (State.Entries (I), Key) then
            return I;
         end if;
      end loop;
      return 0;
   end Index_Of_Key;

   procedure Set_Selected_Index
     (State : in out Bookmark_State;
      Index : Natural)
   is
   begin
      if Index in 1 .. Natural (State.Entries.Length) then
         State.Selected_Index := Index;
         State.Selected_Key := State.Entries (Index);
         State.Has_Selected_Key := True;
      else
         State.Selected_Index := 0;
         State.Selected_Key := (others => <>);
         State.Has_Selected_Key := False;
      end if;
   end Set_Selected_Index;

   procedure Sync_Selected_Index_From_Key (State : in out Bookmark_State) is
      Index : Natural := 0;
   begin
      if State.Has_Selected_Key then
         Index := Index_Of_Key (State, State.Selected_Key);
      end if;
      Set_Selected_Index (State, Index);
   end Sync_Selected_Index_From_Key;

   procedure Clamp_Selection (State : in out Bookmark_State) is
   begin
      if State.Entries.Length = 0 then
         Set_Selected_Index (State, 0);
      elsif State.Has_Selected_Key then
         Sync_Selected_Index_From_Key (State);
         if State.Selected_Index = 0 then
            Set_Selected_Index (State, 1);
         end if;
      elsif State.Selected_Index in 1 .. Natural (State.Entries.Length) then
         Set_Selected_Index (State, State.Selected_Index);
      else
         Set_Selected_Index (State, 1);
      end if;
   end Clamp_Selection;

   procedure Select_After_Removing
     (State         : in out Bookmark_State;
      Removed_Index : Natural)
   is
      Len : constant Natural := Natural (State.Entries.Length);
   begin
      if Len = 0 then
         Set_Selected_Index (State, 0);
      elsif Removed_Index <= Len then
         Set_Selected_Index (State, Removed_Index);
      else
         Set_Selected_Index (State, Len);
      end if;
   end Select_After_Removing;

   procedure Clear (State : in out Bookmark_State) is
   begin
      State.Visible := False;
      State.Entries.Clear;
      Set_Selected_Index (State, 0);
   end Clear;

   procedure Clear_Bookmarks (State : in out Bookmark_State) is
   begin
      State.Entries.Clear;
      Set_Selected_Index (State, 0);
   end Clear_Bookmarks;

   function Count (State : Bookmark_State) return Natural is
   begin
      return Natural (State.Entries.Length);
   end Count;

   function Has_Bookmarks (State : Bookmark_State) return Boolean is
   begin
      return State.Entries.Length > 0;
   end Has_Bookmarks;

   function Is_Visible (State : Bookmark_State) return Boolean is
   begin
      return State.Visible;
   end Is_Visible;

   function Selected_Index (State : Bookmark_State) return Natural is
   begin
      if State.Has_Selected_Key then
         return Index_Of_Key (State, State.Selected_Key);
      else
         return 0;
      end if;
   end Selected_Index;

   function Has_Selected (State : Bookmark_State) return Boolean is
   begin
      return State.Has_Selected_Key
        and then Index_Of_Key (State, State.Selected_Key) /= 0;
   end Has_Selected;

   procedure Show (State : in out Bookmark_State) is
   begin
      State.Visible := True;
      Clamp_Selection (State);
   end Show;

   procedure Hide (State : in out Bookmark_State) is
   begin
      State.Visible := False;
   end Hide;

   procedure Toggle_Visible (State : in out Bookmark_State) is
   begin
      if State.Visible then
         State.Visible := False;
      else
         State.Visible := True;
         Clamp_Selection (State);
      end if;
   end Toggle_Visible;

   function Contains
     (State       : Bookmark_State;
      File_Path   : String;
      Line_Number : Natural) return Boolean
   is
   begin
      if State.Entries.Length = 0 then
         return False;
      end if;
      for Item of State.Entries loop
         if Same_Location (Item, File_Path, Line_Number) then
            return True;
         end if;
      end loop;
      return False;
   end Contains;

   procedure Toggle
     (State        : in out Bookmark_State;
      File_Path    : String;
      Display_Path : String;
      Line_Number  : Natural;
      Column       : Natural;
      Has_Column   : Boolean;
      Added        : out Boolean;
      Project_Relative_Path     : String := "";
      Has_Project_Relative_Path : Boolean := False)
   is
      New_Entry : Bookmark_Entry;
      Inserted  : Boolean := False;
      Prior_Key : constant Bookmark_Entry := State.Selected_Key;
      Had_Prior : constant Boolean := State.Has_Selected_Key;
   begin
      New_Entry.File_Path := To_Unbounded_String (File_Path);
      New_Entry.Display_Path := To_Unbounded_String (Display_Path);
      New_Entry.Project_Relative_Path := To_Unbounded_String (Project_Relative_Path);
      New_Entry.Has_Project_Relative_Path := Has_Project_Relative_Path;
      New_Entry.Line_Number := Line_Number;
      New_Entry.Column := Column;
      New_Entry.Has_Column := Has_Column;

      if State.Entries.Length > 0 then
         for I in State.Entries.First_Index .. State.Entries.Last_Index loop
            if Same_Key (State.Entries (I), New_Entry)
              or else Same_Location (State.Entries (I), File_Path, Line_Number)
            then
               declare
                  Removed_Entry : constant Bookmark_Entry := State.Entries (I);
               begin
                  State.Entries.Delete (I);
                  Added := False;
                  if Had_Prior and then Same_Key (Prior_Key, Removed_Entry) then
                     Select_After_Removing (State, I);
                  elsif Had_Prior then
                     State.Selected_Key := Prior_Key;
                     State.Has_Selected_Key := True;
                     Sync_Selected_Index_From_Key (State);
                  else
                     Set_Selected_Index (State, 0);
                  end if;
               end;
               return;
            end if;
         end loop;
      end if;

      if State.Entries.Length = 0 then
         State.Entries.Append (New_Entry);
      else
         for I in State.Entries.First_Index .. State.Entries.Last_Index loop
            if Entry_Less (New_Entry, State.Entries (I)) then
               State.Entries.Insert (I, New_Entry);
               Inserted := True;
               exit;
            end if;
         end loop;
         if not Inserted then
            State.Entries.Append (New_Entry);
         end if;
      end if;

      Added := True;
      if State.Visible then
         Set_Selected_Index (State, Index_Of_Key (State, New_Entry));
      elsif Had_Prior then
         State.Selected_Key := Prior_Key;
         State.Has_Selected_Key := True;
         Sync_Selected_Index_From_Key (State);
      else
         Set_Selected_Index (State, 0);
      end if;
   end Toggle;

   procedure Remove
     (State       : in out Bookmark_State;
      File_Path   : String;
      Line_Number : Natural;
      Removed     : out Boolean)
   is
      Prior_Key : constant Bookmark_Entry := State.Selected_Key;
      Had_Prior : constant Boolean := State.Has_Selected_Key;
   begin
      Removed := False;
      if State.Entries.Length = 0 then
         return;
      end if;

      for I in State.Entries.First_Index .. State.Entries.Last_Index loop
         if Same_Location (State.Entries (I), File_Path, Line_Number) then
            State.Entries.Delete (I);
            Removed := True;
            if Had_Prior and then Same_Location (Prior_Key, File_Path, Line_Number) then
               Select_After_Removing (State, I);
            elsif Had_Prior then
               State.Selected_Key := Prior_Key;
               State.Has_Selected_Key := True;
               Sync_Selected_Index_From_Key (State);
            else
               Set_Selected_Index (State, 0);
            end if;
            return;
         end if;
      end loop;
   end Remove;

   procedure Remove_Selected
     (State   : in out Bookmark_State;
      Removed : out Boolean;
      Item   : out Bookmark_Entry)
   is
      Index : constant Natural := Selected_Index (State);
   begin
      Item := (others => <>);
      Removed := False;
      if Index = 0 then
         return;
      end if;
      Item := State.Entries (Index);
      State.Entries.Delete (Index);
      Removed := True;
      Select_After_Removing (State, Index);
   end Remove_Selected;

   procedure Reveal_Current
     (State       : in out Bookmark_State;
      File_Path   : String;
      Line_Number : Natural;
      Status      : out Reveal_Current_Status;
      Item       : out Bookmark_Entry)
   is
      First_In_File : Natural := 0;
      First_Later   : Natural := 0;
   begin
      Item := (others => <>);
      if State.Entries.Length = 0 then
         Status := Reveal_No_Bookmarks;
         Set_Selected_Index (State, 0);
         return;
      end if;

      for I in State.Entries.First_Index .. State.Entries.Last_Index loop
         if To_String (State.Entries (I).File_Path) = File_Path then
            if First_In_File = 0 then
               First_In_File := I;
            end if;
            if State.Entries (I).Line_Number = Line_Number then
               Set_Selected_Index (State, I);
               Item := State.Entries (I);
               Status := Reveal_Selected_Exact;
               return;
            elsif State.Entries (I).Line_Number > Line_Number and then First_Later = 0 then
               First_Later := I;
            end if;
         end if;
      end loop;

      if First_Later /= 0 then
         Set_Selected_Index (State, First_Later);
         Item := State.Entries (First_Later);
         Status := Reveal_Selected_Nearest_In_File;
      elsif First_In_File /= 0 then
         Set_Selected_Index (State, First_In_File);
         Item := State.Entries (First_In_File);
         Status := Reveal_Selected_Nearest_In_File;
      else
         Status := Reveal_No_Bookmark_In_Active_File;
      end if;
   end Reveal_Current;

   procedure Select_Next (State : in out Bookmark_State) is
      Len : constant Natural := Natural (State.Entries.Length);
      Index : constant Natural := Selected_Index (State);
   begin
      if Len = 0 then
         Set_Selected_Index (State, 0);
      elsif Index = 0 or else Index >= Len then
         Set_Selected_Index (State, 1);
      else
         Set_Selected_Index (State, Index + 1);
      end if;
   end Select_Next;

   procedure Select_Previous (State : in out Bookmark_State) is
      Len : constant Natural := Natural (State.Entries.Length);
      Index : constant Natural := Selected_Index (State);
   begin
      if Len = 0 then
         Set_Selected_Index (State, 0);
      elsif Index <= 1 then
         Set_Selected_Index (State, Len);
      else
         Set_Selected_Index (State, Index - 1);
      end if;
   end Select_Previous;


   procedure Select_Next_From_Location
     (State        : in out Bookmark_State;
      Has_Location : Boolean;
      File_Path    : String;
      Line_Number  : Natural;
      Column       : Natural;
      Has_Column   : Boolean;
      Status       : out Bookmark_Goto_Status;
      Item        : out Bookmark_Entry)
   is
      Target : Natural := 0;
   begin
      Item := (others => <>);
      if State.Entries.Length = 0 then
         Status := Bookmark_Goto_No_Bookmarks;
         Set_Selected_Index (State, 0);
         return;
      end if;

      if Has_Location then
         for I in State.Entries.First_Index .. State.Entries.Last_Index loop
            if Entry_After_Location
              (State.Entries (I), File_Path, Line_Number, Column, Has_Column)
            then
               Target := I;
               exit;
            end if;
         end loop;
      end if;

      if Target = 0 then
         Target := State.Entries.First_Index;
      end if;

      Set_Selected_Index (State, Target);
      Item := State.Entries (Target);
      Status := Bookmark_Goto_Target_Found;
   end Select_Next_From_Location;

   procedure Select_Previous_From_Location
     (State        : in out Bookmark_State;
      Has_Location : Boolean;
      File_Path    : String;
      Line_Number  : Natural;
      Column       : Natural;
      Has_Column   : Boolean;
      Status       : out Bookmark_Goto_Status;
      Item        : out Bookmark_Entry)
   is
      Target : Natural := 0;
   begin
      Item := (others => <>);
      if State.Entries.Length = 0 then
         Status := Bookmark_Goto_No_Bookmarks;
         Set_Selected_Index (State, 0);
         return;
      end if;

      if Has_Location then
         for I in State.Entries.First_Index .. State.Entries.Last_Index loop
            if Entry_Before_Location
              (State.Entries (I), File_Path, Line_Number, Column, Has_Column)
            then
               Target := I;
            else
               exit;
            end if;
         end loop;
      end if;

      if Target = 0 then
         Target := State.Entries.Last_Index;
      end if;

      Set_Selected_Index (State, Target);
      Item := State.Entries (Target);
      Status := Bookmark_Goto_Target_Found;
   end Select_Previous_From_Location;

   function Selected
     (State : Bookmark_State;
      Found : out Boolean) return Bookmark_Entry
   is
      Index : constant Natural := Selected_Index (State);
   begin
      Found := Index /= 0;
      if Found then
         return State.Entries (Index);
      else
         return (others => <>);
      end if;
   end Selected;

   function Entry_At
     (State : Bookmark_State;
      Index : Positive) return Bookmark_Entry
   is
   begin
      return State.Entries (Index);
   end Entry_At;

   function Bookmark_Path_Label_From_Retained_Target
     (Item : Bookmark_Entry) return Unbounded_String
   is
   begin
      return Item.Display_Path;
   end Bookmark_Path_Label_From_Retained_Target;

   function Bookmark_Dirty_Hint_From_Retained_State
     (Item : Bookmark_Entry) return Boolean
   is
      pragma Unreferenced (Item);
   begin
      --  Retained bookmark entries do not own dirty state.  Dirty hints, when
      --  displayed, are derived from canonical buffer state by the render
      --  snapshot enrichment path.
      return False;
   end Bookmark_Dirty_Hint_From_Retained_State;

   function Build_Bookmark_Row_From_Bookmark_Entry
     (Item       : Bookmark_Entry;
      Is_Selected : Boolean := False) return Bookmark_Row
   is
      Row : Bookmark_Row := (others => <>);
   begin
      Row.File_Display_Path := Bookmark_Path_Label_From_Retained_Target (Item);
      Row.Project_Relative_Path := Item.Project_Relative_Path;
      Row.Has_Project_Relative_Path := Item.Has_Project_Relative_Path;
      Row.File_Path := Item.File_Path;
      Row.Line_Number := Item.Line_Number;
      Row.Column := Item.Column;
      Row.Has_Column := Item.Has_Column;
      Row.Is_Selected := Is_Selected;
      Row.Is_Dirty := Bookmark_Dirty_Hint_From_Retained_State (Item);
      --  Open/active/dirty markers are not stored in Bookmark state.  They are
      --  intentionally left false here and may only be enriched by canonical
      --  render snapshot construction from current buffer/open-buffer state.
      return Row;
   end Build_Bookmark_Row_From_Bookmark_Entry;

   function Build_Bookmark_Rows_From_Retained_State
     (State : Bookmark_State) return Bookmark_Row_Vectors.Vector
   is
      Rows     : Bookmark_Row_Vectors.Vector;
      Selected : constant Natural := Selected_Index (State);
   begin
      if State.Entries.Length > 0 then
         for I in State.Entries.First_Index .. State.Entries.Last_Index loop
            Rows.Append
              (Build_Bookmark_Row_From_Bookmark_Entry
                 (State.Entries (I), I = Selected));
         end loop;
      end if;
      return Rows;
   end Build_Bookmark_Rows_From_Retained_State;

   function Same_Row_Retained_Fields
     (Row          : Bookmark_Row;
      Item        : Bookmark_Entry;
      Is_Selected  : Boolean) return Boolean
   is
   begin
      return To_String (Row.File_Display_Path) = To_String (Item.Display_Path)
        and then To_String (Row.Project_Relative_Path) = To_String (Item.Project_Relative_Path)
        and then Row.Has_Project_Relative_Path = Item.Has_Project_Relative_Path
        and then To_String (Row.File_Path) = To_String (Item.File_Path)
        and then Row.Line_Number = Item.Line_Number
        and then Row.Column = Item.Column
        and then Row.Has_Column = Item.Has_Column
        and then Row.Is_Selected = Is_Selected;
   end Same_Row_Retained_Fields;

   procedure Build_Snapshot
     (State    : Bookmark_State;
      Snapshot : out Bookmark_Snapshot)
   is
      Selected : constant Natural := Selected_Index (State);
   begin
      Snapshot.Bookmarks_Visible := State.Visible;
      Snapshot.Bookmark_Count := Natural (State.Entries.Length);
      Snapshot.Bookmark_Selected_Index := Selected;
      Snapshot.Bookmark_Rows.Clear;
      Snapshot.Bookmark_Empty_Message := To_Unbounded_String ("No bookmarks");
      Snapshot.Bookmark_Has_Selected_Key := Selected /= 0;
      if Selected /= 0 then
         Snapshot.Bookmark_Selected_Key_File_Path := State.Entries (Selected).File_Path;
         Snapshot.Bookmark_Selected_Key_Line_Number := State.Entries (Selected).Line_Number;
         Snapshot.Bookmark_Selected_Key_Column := State.Entries (Selected).Column;
         Snapshot.Bookmark_Selected_Key_Has_Column := State.Entries (Selected).Has_Column;
      else
         Snapshot.Bookmark_Selected_Key_File_Path := Null_Unbounded_String;
         Snapshot.Bookmark_Selected_Key_Line_Number := 0;
         Snapshot.Bookmark_Selected_Key_Column := 0;
         Snapshot.Bookmark_Selected_Key_Has_Column := False;
      end if;

      Snapshot.Bookmark_Rows := Build_Bookmark_Rows_From_Retained_State (State);
   end Build_Snapshot;

   function Bookmarks_No_Duplicate_Lifecycle_State
     (State : Bookmark_State) return Boolean
   is
      Snapshot : Bookmark_Snapshot;
      Row      : Bookmark_Row;
      Item    : Bookmark_Entry;
   begin
      --  Retained bookmark rows expose retained target data only.  Derived
      --  lifecycle-visible markers are not cached in Bookmark state or in the
      --  base Bookmark snapshot.
      Build_Snapshot (State, Snapshot);
      if Snapshot.Bookmark_Count /= Natural (State.Entries.Length)
        or else Natural (Snapshot.Bookmark_Rows.Length) /= Natural (State.Entries.Length)
      then
         return False;
      end if;

      if State.Entries.Length = 0 then
         return Snapshot.Bookmark_Selected_Index = 0
           and then not Snapshot.Bookmark_Has_Selected_Key;
      end if;

      for I in State.Entries.First_Index .. State.Entries.Last_Index loop
         Item := State.Entries (I);
         Row := Snapshot.Bookmark_Rows (I);
         if not Same_Row_Retained_Fields (Row, Item, I = Snapshot.Bookmark_Selected_Index)
           or else Row.Is_Open
           or else Row.Is_Active
           or else Row.Is_Dirty
         then
            return False;
         end if;
      end loop;

      return True;
   end Bookmarks_No_Duplicate_Lifecycle_State;

   function Bookmarks_No_Prompt_State
     (State : Bookmark_State) return Boolean
   is
      pragma Unreferenced (State);
   begin
      --  Bookmark_State has no prompt owner, pending target command, prompt
      --  input, prompt confirmation, or prompt cancellation fields.
      return True;
   end Bookmarks_No_Prompt_State;

   function Bookmark_Selection_Source_Target_Boundary
     (State : Bookmark_State) return Boolean
   is
      Count : constant Natural := Natural (State.Entries.Length);
   begin
      --  Selection is local Bookmark UI state only.  Coherence here prevents
      --  a stale selected key from becoming a file lifecycle source/target.
      if Count = 0 then
         return State.Selected_Index = 0 and then not State.Has_Selected_Key;
      end if;

      if State.Selected_Index = 0 then
         return not State.Has_Selected_Key;
      end if;

      return State.Selected_Index in 1 .. Count
        and then State.Has_Selected_Key
        and then Same_Key (State.Selected_Key, State.Entries (State.Selected_Index));
   end Bookmark_Selection_Source_Target_Boundary;

   function Bookmark_Row_Projection_Canonical
     (State : Bookmark_State) return Boolean
   is
      Snapshot : Bookmark_Snapshot;
      Expected : Bookmark_Row;
   begin
      Build_Snapshot (State, Snapshot);
      if Natural (Snapshot.Bookmark_Rows.Length) /= Natural (State.Entries.Length) then
         return False;
      end if;

      if State.Entries.Length > 0 then
         for I in State.Entries.First_Index .. State.Entries.Last_Index loop
            Expected := Build_Bookmark_Row_From_Bookmark_Entry
              (State.Entries (I), I = Snapshot.Bookmark_Selected_Index);
            if not Same_Row_Retained_Fields
              (Snapshot.Bookmark_Rows (I), State.Entries (I), I = Snapshot.Bookmark_Selected_Index)
              or else Snapshot.Bookmark_Rows (I).Is_Open /= Expected.Is_Open
              or else Snapshot.Bookmark_Rows (I).Is_Active /= Expected.Is_Active
              or else Snapshot.Bookmark_Rows (I).Is_Dirty /= Expected.Is_Dirty
            then
               return False;
            end if;
         end loop;
      end if;

      return True;
   end Bookmark_Row_Projection_Canonical;

   function Bookmarks_File_Lifecycle_Observation_Canonical
     (State : Bookmark_State) return Boolean
   is
   begin
      return Bookmarks_No_Duplicate_Lifecycle_State (State)
        and then Bookmarks_No_Prompt_State (State)
        and then Bookmark_Selection_Source_Target_Boundary (State)
        and then Bookmark_Row_Projection_Canonical (State);
   end Bookmarks_File_Lifecycle_Observation_Canonical;

   function Bookmarks_File_Lifecycle_Observation_Frozen
     (State : Bookmark_State) return Boolean
   is
   begin
      --  freezes the foundation model: Bookmarks project retained
      --  bookmark entries and selection only; lifecycle-visible open/active/dirty
      --  facts are read from canonical buffer state by render snapshot code and
      --  are never persisted back into Bookmark state.
      return Bookmarks_File_Lifecycle_Observation_Canonical (State);
   end Bookmarks_File_Lifecycle_Observation_Frozen;

   function Bookmarks_File_Lifecycle_Observation_Reliable
     (State : Bookmark_State) return Boolean
   is
   begin
      --  does not introduce a second model. Reliability is proven by
      --  preserving the frozen structural contract while workflow tests exercise
      --  successful, failed, blocked, prompted, render, audit, lifecycle, and
      --  persistence paths around it.
      return Bookmarks_File_Lifecycle_Observation_Frozen (State);
   end Bookmarks_File_Lifecycle_Observation_Reliable;

   function Bookmarks_File_Lifecycle_Observation_Cleanup_Canonical
     (State : Bookmark_State) return Boolean
   is
      Snapshot : Bookmark_Snapshot;
      Rows     : Bookmark_Row_Vectors.Vector;
   begin
      --  cleanup: Bookmark runtime state contains no stale path-label
      --  cache, dirty cache, operation/target history, prompt state, repair
      --  cache, projection import, or persistence-adjacent lifecycle field.  The
      --  only reachable projection is recomputed from retained Bookmark entries
      --  plus selection on every snapshot build.
      if not Bookmarks_File_Lifecycle_Observation_Reliable (State) then
         return False;
      end if;

      Build_Snapshot (State, Snapshot);
      Rows := Build_Bookmark_Rows_From_Retained_State (State);
      if Natural (Rows.Length) /= Natural (Snapshot.Bookmark_Rows.Length) then
         return False;
      end if;

      if Rows.Length > 0 then
         for I in Rows.First_Index .. Rows.Last_Index loop
            if not Same_Row_Retained_Fields
              (Snapshot.Bookmark_Rows (I), State.Entries (I), I = Snapshot.Bookmark_Selected_Index)
              or else Snapshot.Bookmark_Rows (I).Is_Open
              or else Snapshot.Bookmark_Rows (I).Is_Active
              or else Snapshot.Bookmark_Rows (I).Is_Dirty
            then
               return False;
            end if;
         end loop;
      end if;

      return True;
   end Bookmarks_File_Lifecycle_Observation_Cleanup_Canonical;

   function Bookmarks_File_Lifecycle_Observation_Final_Frozen
     (State : Bookmark_State) return Boolean
   is
      Snapshot : Bookmark_Snapshot;
      Rows     : Bookmark_Row_Vectors.Vector;
   begin
      --  does not add a new observation model.  The final predicate
      --  deliberately revalidates that the only reachable Bookmark projection
      --  is rebuilt from retained bookmark entries and selection, with all
      --  lifecycle-visible buffer/open/dirty facts owned by canonical external
      --  snapshot composition rather than Bookmark_State.
      if not Bookmarks_File_Lifecycle_Observation_Cleanup_Canonical (State) then
         return False;
      end if;

      Build_Snapshot (State, Snapshot);
      Rows := Build_Bookmark_Rows_From_Retained_State (State);

      if Snapshot.Bookmark_Count /= Natural (State.Entries.Length)
        or else Snapshot.Bookmark_Selected_Index /= Selected_Index (State)
        or else Natural (Snapshot.Bookmark_Rows.Length) /= Natural (Rows.Length)
      then
         return False;
      end if;

      if Rows.Length > 0 then
         for I in Rows.First_Index .. Rows.Last_Index loop
            if not Same_Row_Retained_Fields
              (Rows (I), State.Entries (I), I = Snapshot.Bookmark_Selected_Index)
              or else To_String (Rows (I).File_Display_Path) /=
                To_String (Bookmark_Path_Label_From_Retained_Target (State.Entries (I)))
              or else Rows (I).Is_Open
              or else Rows (I).Is_Active
              or else Rows (I).Is_Dirty
            then
               return False;
            end if;
         end loop;
      end if;

      return True;
   end Bookmarks_File_Lifecycle_Observation_Final_Frozen;

end Editor.Bookmarks;
