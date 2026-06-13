with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Input_Field is

   function Length_Of (Field : Input_Field_State) return Natural is
   begin
      return Length (Field.Value);
   end Length_Of;

   function Normalized_Text (Source : String) return String is
      Result : String (1 .. Source'Length);
      Last   : Natural := 0;
   begin
      for Ch of Source loop
         if Ch = ASCII.CR or else Ch = ASCII.LF then
            exit;
         elsif Ch = ASCII.HT then
            Last := Last + 1;
            Result (Last) := ' ';
         else
            Last := Last + 1;
            Result (Last) := Ch;
         end if;
      end loop;

      if Last = 0 then
         return "";
      end if;
      return Result (1 .. Last);
   end Normalized_Text;

   function Slice_By_Column
     (Value       : String;
      Start_Col   : Natural;
      End_Col     : Natural) return String
   is
   begin
      if Value'Length = 0 or else End_Col <= Start_Col then
         return "";
      end if;
      return Value (Value'First + Start_Col .. Value'First + End_Col - 1);
   end Slice_By_Column;

   procedure Normalize_Selection (Field : in out Input_Field_State) is
      Len : constant Natural := Length_Of (Field);
      Tmp : Natural;
   begin
      Field.Cursor := Natural'Min (Field.Cursor, Len);
      Field.Selection_Anchor := Natural'Min (Field.Selection_Anchor, Len);
      Field.Selection_Start := Natural'Min (Field.Selection_Start, Len);
      Field.Selection_End := Natural'Min (Field.Selection_End, Len);

      if Field.Selection_Start > Field.Selection_End then
         Tmp := Field.Selection_Start;
         Field.Selection_Start := Field.Selection_End;
         Field.Selection_End := Tmp;
      end if;

      if Field.Selection_Start = Field.Selection_End then
         Field.Selection_Mode := No_Field_Selection;
         Field.Selection_Anchor := Field.Cursor;
      end if;
   end Normalize_Selection;

   procedure Delete_Selection (Field : in out Input_Field_State) is
      Old : constant String := To_String (Field.Value);
      A   : Natural := Field.Selection_Start;
      B   : Natural := Field.Selection_End;
   begin
      Normalize_Selection (Field);
      A := Field.Selection_Start;
      B := Field.Selection_End;

      if Field.Selection_Mode = No_Field_Selection then
         return;
      end if;

      Field.Value := To_Unbounded_String
        (Slice_By_Column (Old, 0, A) & Slice_By_Column (Old, B, Old'Length));
      Field.Cursor := A;
      Field.Selection_Mode := No_Field_Selection;
      Field.Selection_Anchor := Field.Cursor;
      Field.Selection_Start := 0;
      Field.Selection_End := 0;
   end Delete_Selection;

   procedure Set_Cursor_Internal
     (Field            : in out Input_Field_State;
      Column           : Natural;
      Extend_Selection : Boolean)
   is
      Old_Cursor : constant Natural := Natural'Min (Field.Cursor, Length_Of (Field));
      New_Cursor : constant Natural := Natural'Min (Column, Length_Of (Field));
   begin
      if Extend_Selection then
         if Field.Selection_Mode = No_Field_Selection then
            Field.Selection_Anchor := Old_Cursor;
         end if;

         Field.Selection_Start := Natural'Min (Field.Selection_Anchor, New_Cursor);
         Field.Selection_End := Natural'Max (Field.Selection_Anchor, New_Cursor);
         Field.Selection_Mode :=
           (if Field.Selection_Start = Field.Selection_End
            then No_Field_Selection else Field_Selection_Active);
      else
         Field.Selection_Mode := No_Field_Selection;
         Field.Selection_Anchor := New_Cursor;
         Field.Selection_Start := 0;
         Field.Selection_End := 0;
      end if;
      Field.Cursor := New_Cursor;
   end Set_Cursor_Internal;

   procedure Clear (Field : in out Input_Field_State) is
   begin
      Field := (Value            => Null_Unbounded_String,
                Cursor           => 0,
                Selection_Mode   => No_Field_Selection,
                Selection_Anchor => 0,
                Selection_Start  => 0,
                Selection_End    => 0);
   end Clear;

   function Text (Field : Input_Field_State) return String is
   begin
      return To_String (Field.Value);
   end Text;

   procedure Set_Text
     (Field : in out Input_Field_State;
      Text  : String) is
      Clean : constant String := Normalized_Text (Text);
   begin
      Field.Value := To_Unbounded_String (Clean);
      Field.Cursor := Clean'Length;
      Field.Selection_Mode := No_Field_Selection;
      Field.Selection_Anchor := Field.Cursor;
      Field.Selection_Start := 0;
      Field.Selection_End := 0;
   end Set_Text;

   function Is_Empty (Field : Input_Field_State) return Boolean is
   begin
      return Length (Field.Value) = 0;
   end Is_Empty;

   function Cursor_Column (Field : Input_Field_State) return Natural is
   begin
      return Natural'Min (Field.Cursor, Length (Field.Value));
   end Cursor_Column;

   procedure Set_Cursor_Column
     (Field  : in out Input_Field_State;
      Column : Natural) is
   begin
      Set_Cursor_Internal (Field, Column, Extend_Selection => False);
   end Set_Cursor_Column;

   procedure Set_Cursor_From_Visible_Column
     (Field           : in out Input_Field_State;
      Visible_Column  : Natural;
      Visible_Columns : Natural)
   is
      Snap : constant Field_Snapshot := Snapshot (Field, Visible_Columns);
   begin
      Set_Cursor_Column (Field, Snap.First_Visible_Column + Visible_Column);
   end Set_Cursor_From_Visible_Column;

   procedure Move_Cursor_Left
     (Field            : in out Input_Field_State;
      Extend_Selection : Boolean := False) is
   begin
      Normalize_Selection (Field);
      if Field.Selection_Mode = Field_Selection_Active and then not Extend_Selection then
         Set_Cursor_Internal (Field, Field.Selection_Start, False);
      elsif Cursor_Column (Field) > 0 then
         Set_Cursor_Internal (Field, Cursor_Column (Field) - 1, Extend_Selection);
      elsif not Extend_Selection then
         Clear_Selection (Field);
      end if;
   end Move_Cursor_Left;

   procedure Move_Cursor_Right
     (Field            : in out Input_Field_State;
      Extend_Selection : Boolean := False) is
   begin
      Normalize_Selection (Field);
      if Field.Selection_Mode = Field_Selection_Active and then not Extend_Selection then
         Set_Cursor_Internal (Field, Field.Selection_End, False);
      else
         Set_Cursor_Internal (Field, Cursor_Column (Field) + 1, Extend_Selection);
      end if;
   end Move_Cursor_Right;

   procedure Move_Cursor_Start
     (Field            : in out Input_Field_State;
      Extend_Selection : Boolean := False) is
   begin
      Set_Cursor_Internal (Field, 0, Extend_Selection);
   end Move_Cursor_Start;

   procedure Move_Cursor_End
     (Field            : in out Input_Field_State;
      Extend_Selection : Boolean := False) is
   begin
      Set_Cursor_Internal (Field, Length_Of (Field), Extend_Selection);
   end Move_Cursor_End;

   procedure Insert_Text
     (Field : in out Input_Field_State;
      Text  : String)
   is
      Clean : constant String := Normalized_Text (Text);
   begin
      if Clean'Length = 0 then
         return;
      end if;

      if Field.Selection_Mode = Field_Selection_Active then
         Delete_Selection (Field);
      end if;

      declare
         Old    : constant String := To_String (Field.Value);
         Cursor : constant Natural := Cursor_Column (Field);
      begin
         Field.Value := To_Unbounded_String
           (Slice_By_Column (Old, 0, Cursor) & Clean &
            Slice_By_Column (Old, Cursor, Old'Length));
         Field.Cursor := Cursor + Clean'Length;
         Clear_Selection (Field);
      end;
   end Insert_Text;

   procedure Backspace (Field : in out Input_Field_State) is
      Old    : constant String := To_String (Field.Value);
      Cursor : constant Natural := Cursor_Column (Field);
   begin
      Normalize_Selection (Field);
      if Field.Selection_Mode = Field_Selection_Active then
         Delete_Selection (Field);
      elsif Cursor > 0 then
         Field.Value := To_Unbounded_String
           (Slice_By_Column (Old, 0, Cursor - 1) &
            Slice_By_Column (Old, Cursor, Old'Length));
         Field.Cursor := Cursor - 1;
      end if;
   end Backspace;

   procedure Delete_Forward (Field : in out Input_Field_State) is
      Old    : constant String := To_String (Field.Value);
      Cursor : constant Natural := Cursor_Column (Field);
   begin
      Normalize_Selection (Field);
      if Field.Selection_Mode = Field_Selection_Active then
         Delete_Selection (Field);
      elsif Cursor < Old'Length then
         Field.Value := To_Unbounded_String
           (Slice_By_Column (Old, 0, Cursor) &
            Slice_By_Column (Old, Cursor + 1, Old'Length));
         Field.Cursor := Cursor;
      end if;
   end Delete_Forward;

   procedure Select_All (Field : in out Input_Field_State) is
      Len : constant Natural := Length_Of (Field);
   begin
      if Len = 0 then
         Clear_Selection (Field);
      else
         Field.Selection_Mode := Field_Selection_Active;
         Field.Selection_Anchor := 0;
         Field.Selection_Start := 0;
         Field.Selection_End := Len;
         Field.Cursor := Len;
      end if;
   end Select_All;

   procedure Clear_Selection (Field : in out Input_Field_State) is
   begin
      Field.Selection_Mode := No_Field_Selection;
      Field.Selection_Anchor := Field.Cursor;
      Field.Selection_Start := 0;
      Field.Selection_End := 0;
   end Clear_Selection;

   function Has_Selection (Field : Input_Field_State) return Boolean is
   begin
      return Field.Selection_Mode = Field_Selection_Active
        and then Field.Selection_End > Field.Selection_Start;
   end Has_Selection;

   function Selected_Text (Field : Input_Field_State) return String is
      Copy : Input_Field_State := Field;
      Old  : constant String := To_String (Field.Value);
   begin
      Normalize_Selection (Copy);
      if Copy.Selection_Mode = No_Field_Selection then
         return "";
      end if;
      return Slice_By_Column (Old, Copy.Selection_Start, Copy.Selection_End);
   end Selected_Text;

   function Snapshot
     (Field           : Input_Field_State;
      Visible_Columns : Natural) return Field_Snapshot
   is
      Copy   : Input_Field_State := Field;
      Old    : constant String := To_String (Field.Value);
      Cursor : Natural;
      First  : Natural := 0;
      Last   : Natural := 0;
   begin
      Normalize_Selection (Copy);
      Cursor := Cursor_Column (Copy);

      if Visible_Columns = 0 then
         First := Cursor;
         Last := Cursor;
      elsif Old'Length <= Visible_Columns then
         First := 0;
         Last := Old'Length;
      elsif Cursor >= Visible_Columns then
         First := Cursor - Visible_Columns + 1;
         Last := Natural'Min (Old'Length, First + Visible_Columns);
      else
         First := 0;
         Last := Natural'Min (Old'Length, Visible_Columns);
      end if;

      return
        (Text                  => Copy.Value,
         Visible_Text          => To_Unbounded_String (Slice_By_Column (Old, First, Last)),
         Cursor_Column         => Cursor,
         First_Visible_Column  => First,
         Cursor_Visible_Column => Cursor - First,
         Has_Selection         => Has_Selection (Copy),
         Selection_Start       => Copy.Selection_Start,
         Selection_End         => Copy.Selection_End);
   end Snapshot;

end Editor.Input_Field;
