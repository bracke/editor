with Ada.Characters.Handling;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Project_Search.Replace_Preview;

package body Editor.Project_Search.Navigation is

   function Result_At
     (State : Project_Search_State;
      Index : Positive) return Project_Search_Result
   is
   begin
      if Index > Natural (State.Results.Length) then
         return (others => <>);
      end if;
      return State.Results (Index - 1);
   end Result_At;

   function Result_Key
     (State : Project_Search_State;
      Index : Positive) return Project_Search_Result_Key
   is
      Result : constant Project_Search_Result := Result_At (State, Index);
   begin
      if Result.Id = No_Project_Search_Result then
         return (others => <>);
      end if;
      return
        (Project_Relative_Path => Result.Relative_Path,
         Line_Number           => Result.Row,
         Result_Ordinal        => Index);
   end Result_Key;

   function File_Group_At
     (State : Project_Search_State;
      Index : Positive) return Project_Search_File_Group
   is
   begin
      if Index > Natural (State.File_Groups.Length) then
         return (others => <>);
      end if;
      return State.File_Groups (Index - 1);
   end File_Group_At;

   function Selected_Result_Index
     (State : Project_Search_State) return Natural
   is
   begin
      return State.Selected_Index;
   end Selected_Result_Index;

   procedure Set_Selected_Result_Index
     (State : in out Project_Search_State;
      Index : Natural)
   is
   begin
      if Index = 0 or else Natural (State.Results.Length) = 0 then
         State.Selected_Index := 0;
      elsif Index > Natural (State.Results.Length) then
         State.Selected_Index := Natural (State.Results.Length);
      else
         State.Selected_Index := Index;
      end if;
      if Natural (State.Replace_Rows.Length) > 0 then
         Editor.Project_Search.Replace_Preview.Set_Selected_Replace_Preview_Index
           (State, State.Selected_Index);
      end if;
   end Set_Selected_Result_Index;

   procedure Ensure_Valid_Selection
     (State : in out Project_Search_State)
   is
      Count : constant Natural := Natural (State.Results.Length);
   begin
      if Count = 0 then
         State.Selected_Index := 0;
      elsif State.Selected_Index = 0 then
         State.Selected_Index := 1;
      elsif State.Selected_Index > Count then
         State.Selected_Index := Count;
      end if;
      if Natural (State.Replace_Rows.Length) > 0 then
         Editor.Project_Search.Replace_Preview.Set_Selected_Replace_Preview_Index
           (State, State.Selected_Index);
      end if;
   end Ensure_Valid_Selection;

   function Can_Move_Next
     (State : Project_Search_State) return Boolean
   is
   begin
      return Natural (State.Results.Length) > 0;
   end Can_Move_Next;

   function Can_Move_Previous
     (State : Project_Search_State) return Boolean
   is
   begin
      return Natural (State.Results.Length) > 0;
   end Can_Move_Previous;

   procedure Move_Selected_Result
     (State     : in out Project_Search_State;
      Direction : Project_Search_Result_Direction;
      Wrap      : Boolean := True)
   is
      Count : constant Natural := Natural (State.Results.Length);
   begin
      if Count = 0 then
         State.Selected_Index := 0;
         return;
      end if;

      if State.Selected_Index = 0 then
         case Direction is
            when Next_Result =>
               State.Selected_Index := 1;
            when Previous_Result =>
               State.Selected_Index := Count;
         end case;
         if Natural (State.Replace_Rows.Length) > 0 then
            Editor.Project_Search.Replace_Preview.Set_Selected_Replace_Preview_Index
              (State, State.Selected_Index);
         end if;
         return;
      end if;

      Ensure_Valid_Selection (State);
      case Direction is
         when Next_Result =>
            if State.Selected_Index < Count then
               State.Selected_Index := State.Selected_Index + 1;
            elsif Wrap then
               State.Selected_Index := 1;
            end if;
         when Previous_Result =>
            if State.Selected_Index > 1 then
               State.Selected_Index := State.Selected_Index - 1;
            elsif Wrap then
               State.Selected_Index := Count;
            end if;
      end case;
      if Natural (State.Replace_Rows.Length) > 0 then
         Editor.Project_Search.Replace_Preview.Set_Selected_Replace_Preview_Index
           (State, State.Selected_Index);
      end if;
   end Move_Selected_Result;

   procedure Select_First_Result
     (State : in out Project_Search_State)
   is
   begin
      if Natural (State.Results.Length) = 0 then
         State.Selected_Index := 0;
      else
         State.Selected_Index := 1;
      end if;
      if Natural (State.Replace_Rows.Length) > 0 then
         Editor.Project_Search.Replace_Preview.Set_Selected_Replace_Preview_Index
           (State, State.Selected_Index);
      end if;
   end Select_First_Result;

   procedure Select_Last_Result
     (State : in out Project_Search_State)
   is
      Count : constant Natural := Natural (State.Results.Length);
   begin
      State.Selected_Index := Count;
      if Natural (State.Replace_Rows.Length) > 0 then
         Editor.Project_Search.Replace_Preview.Set_Selected_Replace_Preview_Index
           (State, State.Selected_Index);
      end if;
   end Select_Last_Result;

   function Select_First_Result_For_Path
     (State : in out Project_Search_State;
      Path  : String) return Boolean
   is
   begin
      if Natural (State.Results.Length) = 0 then
         State.Selected_Index := 0;
         return False;
      end if;

      if State.Selected_Index in 1 .. Natural (State.Results.Length) then
         declare
            Current : constant Project_Search_Result :=
              State.Results (State.Selected_Index - 1);
         begin
            if To_String (Current.Relative_Path) = Path then
               return True;
            end if;
         end;
      end if;

      for I in 1 .. Natural (State.Results.Length) loop
         declare
            Candidate : constant Project_Search_Result := State.Results (I - 1);
         begin
            if To_String (Candidate.Relative_Path) = Path then
               State.Selected_Index := I;
               if Natural (State.Replace_Rows.Length) > 0 then
                  Editor.Project_Search.Replace_Preview.Set_Selected_Replace_Preview_Index
                    (State, State.Selected_Index);
               end if;
               return True;
            end if;
         end;
      end loop;

      return False;
   end Select_First_Result_For_Path;

   function Directory_Scope_Of_Path
     (Path : String) return String
   is
      Last_Slash : Natural := 0;
   begin
      for I in Path'Range loop
         if Path (I) = '/' then
            Last_Slash := I;
         end if;
      end loop;

      if Last_Slash = 0 then
         return "";
      else
         return Path (Path'First .. Last_Slash);
      end if;
   end Directory_Scope_Of_Path;

   function Selected_Result_Directory
     (State : Project_Search_State;
      Found : out Boolean) return String
   is
      Result : Project_Search_Result;
   begin
      Found := State.Selected_Index in 1 .. Natural (State.Results.Length);
      if not Found then
         return "";
      end if;

      Result := State.Results (State.Selected_Index - 1);
      return Directory_Scope_Of_Path (To_String (Result.Relative_Path));
   end Selected_Result_Directory;

   function Selected_Result
     (State : Project_Search_State;
      Found : out Boolean) return Project_Search_Result
   is
   begin
      Found := State.Selected_Index in 1 .. Natural (State.Results.Length);
      if Found then
         return State.Results (State.Selected_Index - 1);
      else
         return (others => <>);
      end if;
   end Selected_Result;

   procedure Move_Selection_Down
     (State : in out Project_Search_State)
   is
      Count : constant Natural := Natural (State.Results.Length);
   begin
      if Count = 0 then
         State.Selected_Index := 0;
      elsif State.Selected_Index = 0 or else State.Selected_Index >= Count then
         State.Selected_Index := 1;
      else
         State.Selected_Index := State.Selected_Index + 1;
      end if;

      if Natural (State.Replace_Rows.Length) > 0 then
         Editor.Project_Search.Replace_Preview.Set_Selected_Replace_Preview_Index
           (State, State.Selected_Index);
      end if;
   end Move_Selection_Down;

   procedure Move_Selection_Up
     (State : in out Project_Search_State)
   is
      Count : constant Natural := Natural (State.Results.Length);
   begin
      if Count = 0 then
         State.Selected_Index := 0;
      elsif State.Selected_Index <= 1 then
         State.Selected_Index := Count;
      else
         State.Selected_Index := State.Selected_Index - 1;
      end if;

      if Natural (State.Replace_Rows.Length) > 0 then
         Editor.Project_Search.Replace_Preview.Set_Selected_Replace_Preview_Index
           (State, State.Selected_Index);
      end if;
   end Move_Selection_Up;

end Editor.Project_Search.Navigation;
