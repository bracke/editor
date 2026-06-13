with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Input_Field;

package body Editor.Go_To_Line is

   procedure Clear (State : in out Go_To_Line_State) is
   begin
      State.Opened := False;
      Editor.Input_Field.Clear (State.Field);
      State.Error := Null_Unbounded_String;
   end Clear;

   procedure Open (State : in out Go_To_Line_State) is
   begin
      State.Opened := True;
   end Open;

   procedure Close (State : in out Go_To_Line_State) is
   begin
      State.Opened := False;
   end Close;

   function Is_Open (State : Go_To_Line_State) return Boolean is
   begin
      return State.Opened;
   end Is_Open;

   function Text (State : Go_To_Line_State) return String is
   begin
      return Editor.Input_Field.Text (State.Field);
   end Text;

   function Has_Error (State : Go_To_Line_State) return Boolean is
   begin
      return Length (State.Error) > 0;
   end Has_Error;

   function Error_Text (State : Go_To_Line_State) return String is
   begin
      return To_String (State.Error);
   end Error_Text;

   procedure Set_Error (State : in out Go_To_Line_State; Text : String) is
   begin
      State.Error := To_Unbounded_String (Text);
   end Set_Error;

   procedure Clear_Error (State : in out Go_To_Line_State) is
   begin
      State.Error := Null_Unbounded_String;
   end Clear_Error;

   procedure Set_Text (State : in out Go_To_Line_State; Text : String) is
   begin
      Editor.Input_Field.Set_Text (State.Field, Text);
      Clear_Error (State);
   end Set_Text;

   procedure Insert_Text (State : in out Go_To_Line_State; Text : String) is
   begin
      for Ch of Text loop
         if Ch >= ' ' and then Ch /= ASCII.DEL then
            Editor.Input_Field.Insert_Text (State.Field, String'(1 => Ch));
            Clear_Error (State);
         end if;
      end loop;
   end Insert_Text;

   procedure Backspace (State : in out Go_To_Line_State) is
   begin
      Editor.Input_Field.Backspace (State.Field);
      Clear_Error (State);
   end Backspace;

   procedure Delete_Forward (State : in out Go_To_Line_State) is
   begin
      Editor.Input_Field.Delete_Forward (State.Field);
      Clear_Error (State);
   end Delete_Forward;

   procedure Move_Cursor_Left (State : in out Go_To_Line_State) is
   begin
      Editor.Input_Field.Move_Cursor_Left (State.Field);
   end Move_Cursor_Left;

   procedure Move_Cursor_Right (State : in out Go_To_Line_State) is
   begin
      Editor.Input_Field.Move_Cursor_Right (State.Field);
   end Move_Cursor_Right;

   procedure Move_Cursor_Start (State : in out Go_To_Line_State) is
   begin
      Editor.Input_Field.Move_Cursor_Start (State.Field);
   end Move_Cursor_Start;

   procedure Move_Cursor_End (State : in out Go_To_Line_State) is
   begin
      Editor.Input_Field.Move_Cursor_End (State.Field);
   end Move_Cursor_End;

   procedure Select_All (State : in out Go_To_Line_State) is
   begin
      Editor.Input_Field.Select_All (State.Field);
   end Select_All;

   function Cursor_Column (State : Go_To_Line_State) return Natural is
   begin
      return Editor.Input_Field.Cursor_Column (State.Field);
   end Cursor_Column;

   function Parse_Positive
     (Text  : String;
      Value : out Natural) return Boolean
   is
      Accum : Natural := 0;
      Digit : Natural := 0;
   begin
      if Text'Length = 0 then
         Value := 0;
         return False;
      end if;

      for Ch of Text loop
         if Ch not in '0' .. '9' then
            Value := 0;
            return False;
         end if;

         Digit := Natural (Character'Pos (Ch) - Character'Pos ('0'));
         if Accum > (Natural'Last - Digit) / 10 then
            Value := 0;
            return False;
         end if;
         Accum := Accum * 10 + Digit;
      end loop;

      if Accum = 0 then
         Value := 0;
         return False;
      end if;

      Value := Accum;
      return True;
   end Parse_Positive;

   function Validate
     (State      : Go_To_Line_State;
      Line_Count : Natural) return Go_To_Line_Validation_Result
   is
      Raw       : constant String := Editor.Input_Field.Text (State.Field);
      T         : constant String := Ada.Strings.Fixed.Trim (Raw, Ada.Strings.Both);
      Sep_Index : Natural := 0;
      Line      : Natural := 0;
      Column    : Natural := 0;
   begin
      if T'Length = 0 then
         return (Status => Go_To_Line_Empty, Line => 0, Has_Column => False, Column => 0);
      end if;

      for I in T'Range loop
         if T (I) = ':' or else T (I) = ',' then
            if Sep_Index /= 0 then
               return (Status => Go_To_Line_Invalid, Line => 0, Has_Column => False, Column => 0);
            end if;
            Sep_Index := I;
         end if;
      end loop;

      if Sep_Index = 0 then
         declare
            Line_Text : constant String := Ada.Strings.Fixed.Trim (T, Ada.Strings.Both);
         begin
            if not Parse_Positive (Line_Text, Line) then
               return (Status => Go_To_Line_Invalid, Line => 0, Has_Column => False, Column => 0);
            end if;
         end;
      else
         if Sep_Index = T'First or else Sep_Index = T'Last then
            return (Status => Go_To_Line_Invalid, Line => 0, Has_Column => False, Column => 0);
         end if;

         declare
            Line_Text : constant String :=
              Ada.Strings.Fixed.Trim (T (T'First .. Sep_Index - 1), Ada.Strings.Both);
            Column_Text : constant String :=
              Ada.Strings.Fixed.Trim (T (Sep_Index + 1 .. T'Last), Ada.Strings.Both);
         begin
            if not Parse_Positive (Line_Text, Line)
              or else not Parse_Positive (Column_Text, Column)
            then
               return (Status => Go_To_Line_Invalid, Line => 0, Has_Column => False, Column => 0);
            end if;
         end;
      end if;

      if Line > Line_Count then
         return (Status => Go_To_Line_Out_Of_Range, Line => Line,
                 Has_Column => Sep_Index /= 0, Column => Column);
      end if;

      return (Status => Go_To_Line_Valid, Line => Line,
              Has_Column => Sep_Index /= 0, Column => Column);
   end Validate;

   function Snapshot
     (State           : Go_To_Line_State;
      Visible_Columns : Natural) return Editor.Input_Field.Field_Snapshot is
   begin
      return Editor.Input_Field.Snapshot (State.Field, Visible_Columns);
   end Snapshot;

end Editor.Go_To_Line;
