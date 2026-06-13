with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Diagnostics is

   function Severity_Priority
     (Severity : Diagnostic_Severity) return Natural
   is
   begin
      case Severity is
         when Error       => return 0;
         when Warning     => return 1;
         when Note        => return 2;
         when Information => return 3;
         when Hint        => return 4;
         when Unknown     => return 5;
      end case;
   end Severity_Priority;

   function To_Vector_Index
     (Index : Diagnostic_Index) return Natural
   is
   begin
      return Natural (Index) - 1;
   end To_Vector_Index;

   function To_Diagnostic_Index
     (Vector_Index : Natural) return Diagnostic_Index
   is
   begin
      return Diagnostic_Index (Vector_Index + 1);
   end To_Diagnostic_Index;

   function Location_Row
     (D : Diagnostic_Range) return Natural
   is
   begin
      if D.Has_Location then
         return D.Start_Row;
      else
         return 0;
      end if;
   end Location_Row;

   function Location_Column
     (D : Diagnostic_Range) return Natural
   is
   begin
      if D.Has_Location then
         return D.Start_Column;
      else
         return Natural (D.Start_Index);
      end if;
   end Location_Column;

   function Comes_Before
     (Left_Index  : Natural;
      Left        : Diagnostic_Range;
      Right_Index : Natural;
      Right       : Diagnostic_Range) return Boolean
   is
      Left_Row  : constant Natural := Location_Row (Left);
      Right_Row : constant Natural := Location_Row (Right);
      Left_Col  : constant Natural := Location_Column (Left);
      Right_Col : constant Natural := Location_Column (Right);
   begin
      if Left_Row /= Right_Row then
         return Left_Row < Right_Row;
      elsif Left_Col /= Right_Col then
         return Left_Col < Right_Col;
      elsif Severity_Priority (Left.Severity) /= Severity_Priority (Right.Severity) then
         return Severity_Priority (Left.Severity) < Severity_Priority (Right.Severity);
      else
         return Left_Index < Right_Index;
      end if;
   end Comes_Before;

   function Ordered_Vector_Index_At
     (State            : Diagnostic_Vectors.Vector;
      Ordered_Position : Positive) return Natural
   is
      Best_Index : Natural := 0;
      Best_Set   : Boolean := False;
   begin
      if State.Is_Empty or else Ordered_Position > Natural (State.Length) then
         return 0;
      end if;

      for Position in 1 .. Ordered_Position loop
         Best_Set := False;
         for Index in State.First_Index .. State.Last_Index loop
            declare
               Candidate : constant Diagnostic_Range := State.Element (Index);
               Skip      : Boolean := False;
            begin
               if Position > 1 then
                  for Prior_Position in 1 .. Position - 1 loop
                     declare
                        Prior_Index : constant Natural :=
                          Ordered_Vector_Index_At (State, Prior_Position);
                     begin
                        if Index = Prior_Index then
                           Skip := True;
                        end if;
                     end;
                  end loop;
               end if;

               if not Skip
                 and then (not Best_Set
                   or else Comes_Before
                     (Index, Candidate, Best_Index, State.Element (Best_Index)))
               then
                  Best_Index := Index;
                  Best_Set := True;
               end if;
            end;
         end loop;
      end loop;

      return Best_Index;
   end Ordered_Vector_Index_At;

   procedure Add
     (Diagnostics : in out Diagnostic_Vectors.Vector;
      Start_Index : Editor.Cursors.Cursor_Index;
      End_Index   : Editor.Cursors.Cursor_Index;
      Severity    : Diagnostic_Severity;
      Message     : String := "")
   is
      Lo : constant Editor.Cursors.Cursor_Index :=
        Editor.Cursors.Cursor_Index'Min (Start_Index, End_Index);
      Hi : constant Editor.Cursors.Cursor_Index :=
        Editor.Cursors.Cursor_Index'Max (Start_Index, End_Index);
   begin
      if Lo < Hi then
         Diagnostics.Append
           (Diagnostic_Range'
             (Start_Index  => Lo,
             End_Index    => Hi,
             Severity     => Severity,
             Message      => To_Unbounded_String (Message),
             Has_Location => False,
             Start_Row    => 0,
             Start_Column => Natural (Lo)));
      end if;
   end Add;

   procedure Add
     (Diagnostics  : in out Diagnostic_Vectors.Vector;
      Start_Index  : Editor.Cursors.Cursor_Index;
      End_Index    : Editor.Cursors.Cursor_Index;
      Start_Row    : Natural;
      Start_Column : Natural;
      Severity     : Diagnostic_Severity;
      Message      : String := "")
   is
      Lo : constant Editor.Cursors.Cursor_Index :=
        Editor.Cursors.Cursor_Index'Min (Start_Index, End_Index);
      Hi : constant Editor.Cursors.Cursor_Index :=
        Editor.Cursors.Cursor_Index'Max (Start_Index, End_Index);
   begin
      if Lo < Hi then
         Diagnostics.Append
           (Diagnostic_Range'
             (Start_Index  => Lo,
             End_Index    => Hi,
             Severity     => Severity,
             Message      => To_Unbounded_String (Message),
             Has_Location => True,
             Start_Row    => Start_Row,
             Start_Column => Start_Column));
      end if;
   end Add;

   procedure Clear
     (Diagnostics : in out Diagnostic_Vectors.Vector) is
   begin
      Diagnostics.Clear;
   end Clear;

   function Diagnostic_Count
     (State : Diagnostic_Vectors.Vector) return Natural is
   begin
      return Natural (State.Length);
   end Diagnostic_Count;

   function Diagnostic_At
     (State : Diagnostic_Vectors.Vector;
      Index : Positive) return Diagnostic is
   begin
      return State.Element (Natural (Index - 1));
   end Diagnostic_At;

   function Ordered_Diagnostic_Count
     (State : Diagnostic_Vectors.Vector) return Natural is
   begin
      return Natural (State.Length);
   end Ordered_Diagnostic_Count;

   function Ordered_Diagnostic_Index_At
     (State            : Diagnostic_Vectors.Vector;
      Ordered_Position : Positive) return Diagnostic_Index
   is
   begin
      if State.Is_Empty or else Ordered_Position > Natural (State.Length) then
         return No_Diagnostic;
      end if;
      return To_Diagnostic_Index
        (Ordered_Vector_Index_At (State, Ordered_Position));
   end Ordered_Diagnostic_Index_At;

   function Is_Valid_Diagnostic_Index
     (State : Diagnostic_Vectors.Vector;
      Index : Diagnostic_Index) return Boolean
   is
      V : Natural;
   begin
      if Index = No_Diagnostic or else State.Is_Empty then
         return False;
      end if;
      V := To_Vector_Index (Index);
      return V >= State.First_Index and then V <= State.Last_Index;
   end Is_Valid_Diagnostic_Index;

   function First_Diagnostic
     (State : Diagnostic_Vectors.Vector;
      Found : out Boolean) return Diagnostic_Index
   is
   begin
      Found := not State.Is_Empty;
      if Found then
         return Ordered_Diagnostic_Index_At (State, 1);
      else
         return No_Diagnostic;
      end if;
   end First_Diagnostic;

   function Last_Diagnostic
     (State : Diagnostic_Vectors.Vector;
      Found : out Boolean) return Diagnostic_Index
   is
   begin
      Found := not State.Is_Empty;
      if Found then
         return Ordered_Diagnostic_Index_At (State, Positive (Natural (State.Length)));
      else
         return No_Diagnostic;
      end if;
   end Last_Diagnostic;

   function Next_Diagnostic_After
     (State  : Diagnostic_Vectors.Vector;
      Row    : Natural;
      Column : Natural;
      Wrap   : Boolean := True;
      Found  : out Boolean) return Diagnostic_Index
   is
   begin
      if State.Is_Empty then
         Found := False;
         return No_Diagnostic;
      end if;

      for Pos in 1 .. Natural (State.Length) loop
         declare
            Idx : constant Diagnostic_Index := Ordered_Diagnostic_Index_At (State, Pos);
            D   : constant Diagnostic_Range := State.Element (To_Vector_Index (Idx));
            R   : constant Natural := Location_Row (D);
            C   : constant Natural := Location_Column (D);
         begin
            if R > Row or else (R = Row and then C > Column) then
               Found := True;
               return Idx;
            end if;
         end;
      end loop;

      if Wrap then
         Found := True;
         return Ordered_Diagnostic_Index_At (State, 1);
      else
         Found := False;
         return No_Diagnostic;
      end if;
   end Next_Diagnostic_After;

   function Previous_Diagnostic_Before
     (State  : Diagnostic_Vectors.Vector;
      Row    : Natural;
      Column : Natural;
      Wrap   : Boolean := True;
      Found  : out Boolean) return Diagnostic_Index
   is
   begin
      if State.Is_Empty then
         Found := False;
         return No_Diagnostic;
      end if;

      for Pos in reverse 1 .. Natural (State.Length) loop
         declare
            Idx : constant Diagnostic_Index := Ordered_Diagnostic_Index_At (State, Pos);
            D   : constant Diagnostic_Range := State.Element (To_Vector_Index (Idx));
            R   : constant Natural := Location_Row (D);
            C   : constant Natural := Location_Column (D);
         begin
            if R < Row or else (R = Row and then C < Column) then
               Found := True;
               return Idx;
            end if;
         end;
      end loop;

      if Wrap then
         Found := True;
         return Ordered_Diagnostic_Index_At (State, Positive (Natural (State.Length)));
      else
         Found := False;
         return No_Diagnostic;
      end if;
   end Previous_Diagnostic_Before;

   function Dominant_Diagnostic_On_Row
     (State : Diagnostic_Vectors.Vector;
      Row   : Natural;
      Found : out Boolean) return Diagnostic_Index
   is
      Best_Index : Diagnostic_Index := No_Diagnostic;
      Best_Diag  : Diagnostic_Range;
   begin
      Found := False;
      if State.Is_Empty then
         return No_Diagnostic;
      end if;

      for Index in State.First_Index .. State.Last_Index loop
         declare
            D : constant Diagnostic_Range := State.Element (Index);
         begin
            if Location_Row (D) = Row then
               if not Found
                 or else Severity_Priority (D.Severity) < Severity_Priority (Best_Diag.Severity)
                 or else (Severity_Priority (D.Severity) = Severity_Priority (Best_Diag.Severity)
                   and then Location_Column (D) < Location_Column (Best_Diag))
                 or else (Severity_Priority (D.Severity) = Severity_Priority (Best_Diag.Severity)
                   and then Location_Column (D) = Location_Column (Best_Diag)
                   and then Index < To_Vector_Index (Best_Index))
               then
                  Best_Index := To_Diagnostic_Index (Index);
                  Best_Diag  := D;
                  Found := True;
               end if;
            end if;
         end;
      end loop;

      return Best_Index;
   end Dominant_Diagnostic_On_Row;

   function Target_For_Diagnostic
     (State : Diagnostic_Vectors.Vector;
      Index : Diagnostic_Index) return Diagnostic_Target
   is
      D : Diagnostic_Range;
   begin
      if not Is_Valid_Diagnostic_Index (State, Index) then
         return (Found => False, Row => 0, Column => 0, Index => No_Diagnostic);
      end if;

      D := State.Element (To_Vector_Index (Index));
      return
        (Found  => True,
         Row    => Location_Row (D),
         Column => Location_Column (D),
         Index  => Index);
   end Target_For_Diagnostic;

end Editor.Diagnostics;
