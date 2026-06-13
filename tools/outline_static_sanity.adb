with Ada.Command_Line;
with Ada.Text_IO;

procedure Outline_Static_Sanity is
   Max_Depth : constant Positive := 4096;

   type Stack_Item is record
      Ch     : Character;
      Line   : Positive;
      Column : Positive;
   end record;

   type Stack_Array is array (Positive range 1 .. Max_Depth) of Stack_Item;

   Had_Error : Boolean := False;

   procedure Report (Message : String) is
   begin
      Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error, Message);
      Had_Error := True;
   end Report;

   function Is_Opening (Ch : Character) return Boolean is
   begin
      return Ch = '(' or else Ch = '[';
   end Is_Opening;

   function Is_Closing (Ch : Character) return Boolean is
   begin
      return Ch = ')' or else Ch = ']';
   end Is_Closing;

   function Matching_Open (Ch : Character) return Character is
   begin
      case Ch is
         when ')' => return '(';
         when ']' => return '[';
         when others => return Character'Val (0);
      end case;
   end Matching_Open;

   function Image_Of (Ch : Character) return String is
   begin
      return "'" & Ch & "'";
   end Image_Of;

   function Number_Image (Value : Natural) return String is
      Raw : constant String := Natural'Image (Value);
   begin
      if Raw'Length > 0 and then Raw (Raw'First) = ' ' then
         return Raw (Raw'First + 1 .. Raw'Last);
      end if;
      return Raw;
   end Number_Image;

   function Simple_Char_Literal_Length
     (Line : String;
      Pos  : Positive) return Natural
   is
   begin
      if Pos + 3 <= Line'Last
        and then Line (Pos .. Pos + 3) = "''''"
      then
         return 4;
      elsif Pos + 2 <= Line'Last
        and then Line (Pos) = Character'Val (39)
        and then Line (Pos + 2) = Character'Val (39)
      then
         return 3;
      else
         return 0;
      end if;
   end Simple_Char_Literal_Length;

   procedure Check_Line
     (Path   : String;
      Line   : String;
      Line_No : Positive;
      Stack  : in out Stack_Array;
      Depth  : in out Natural)
   is
      In_String : Boolean := False;
      Pos       : Positive := Line'First;
      Char_Len  : Natural;
      Ch        : Character;
   begin
      while Pos <= Line'Last loop
         Ch := Line (Pos);

         if In_String then
            if Ch = '"' then
               if Pos + 1 <= Line'Last and then Line (Pos + 1) = '"' then
                  Pos := Pos + 2;
               else
                  In_String := False;
                  Pos := Pos + 1;
               end if;
            else
               Pos := Pos + 1;
            end if;
         else
            Char_Len := Simple_Char_Literal_Length (Line, Pos);
            if Char_Len > 0 then
               Pos := Pos + Char_Len;
            elsif Ch = '"' then
               In_String := True;
               Pos := Pos + 1;
            elsif Ch = '-' and then Pos + 1 <= Line'Last and then Line (Pos + 1) = '-' then
               exit;
            elsif Is_Opening (Ch) then
               if Depth = Max_Depth then
                  Report
                    (Path & ":" & Number_Image (Line_No) & ":" &
                     Number_Image (Pos) & ": grouping-token stack overflow");
               else
                  Depth := Depth + 1;
                  Stack (Depth) := (Ch => Ch, Line => Line_No, Column => Pos);
               end if;
               Pos := Pos + 1;
            elsif Is_Closing (Ch) then
               if Depth = 0 or else Stack (Depth).Ch /= Matching_Open (Ch) then
                  Report
                    (Path & ":" & Number_Image (Line_No) & ":" &
                     Number_Image (Pos) & ": unmatched closing " & Image_Of (Ch));
               else
                  Depth := Depth - 1;
               end if;
               Pos := Pos + 1;
            else
               Pos := Pos + 1;
            end if;
         end if;
      end loop;
   end Check_Line;

   procedure Check_File (Path : String) is
      File    : Ada.Text_IO.File_Type;
      Stack   : Stack_Array;
      Depth   : Natural := 0;
      Line_No : Natural := 0;
      First_Unclosed : Positive;
   begin
      if not Ada.Text_IO.Is_Open (File) then
         null;
      end if;

      begin
         Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      exception
         when others =>
            Report ("missing outline sanity input: " & Path);
            return;
      end;

      while not Ada.Text_IO.End_Of_File (File) loop
         declare
            Line : constant String := Ada.Text_IO.Get_Line (File);
         begin
            Line_No := Line_No + 1;
            if Line'Length > 0 then
               Check_Line (Path, Line, Positive (Line_No), Stack, Depth);
            end if;
         end;
      end loop;

      Ada.Text_IO.Close (File);

      if Depth > 0 then
         if Depth > 10 then
            First_Unclosed := Depth - 9;
         else
            First_Unclosed := 1;
         end if;

         for Index in First_Unclosed .. Depth loop
            Report
              (Path & ":" & Number_Image (Stack (Index).Line) & ":" &
               Number_Image (Stack (Index).Column) & ": unclosed " &
               Image_Of (Stack (Index).Ch));
         end loop;

         if Depth > 10 then
            Report (Path & ": " & Number_Image (Depth) &
                    " total unclosed grouping tokens");
         end if;
      end if;
   end Check_File;

begin
   Check_File ("src/core/editor-outline.ads");
   Check_File ("src/core/editor-outline.adb");
   Check_File ("src/core/editor-outline_extractor.ads");
   Check_File ("src/core/editor-outline_extractor.adb");
   Check_File ("tests/src/editor-outline-tests.adb");

   if Had_Error then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Outline_Static_Sanity;
