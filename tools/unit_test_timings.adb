with Ada.Command_Line;
with Ada.Directories;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

procedure Unit_Test_Timings is
   use Ada.Strings.Unbounded;

   Timing_Path : constant String := "/tmp/editor_unit_test_timings.tsv";
   Known_Slice_Count : constant Positive := 15;

   function Known_Slice (Index : Positive) return String is
   begin
      case Index is
         when 1 => return "editor-core";
         when 2 => return "executor-diagnostics";
         when 3 => return "executor-search";
         when 4 => return "executor-navigation";
         when 5 => return "executor-buffer-switcher";
         when 6 => return "executor-buffer-prune";
         when 7 => return "executor-lifecycle";
         when 8 => return "editor-ui";
         when 9 => return "project-workspace";
         when 10 => return "diagnostics-problems";
         when 11 => return "build-tools";
         when 12 => return "ada-parser-outline";
         when 13 => return "ada-language-service";
         when 14 => return "ada-language";
         when 15 => return "text";
         when others => return "";
      end case;
   end Known_Slice;

   function Field
     (Line  : String;
      Index : Positive) return String
   is
      Current : Positive := 1;
      Start   : Positive := Line'First;
   begin
      for I in Line'Range loop
         if Line (I) = ASCII.HT then
            if Current = Index then
               return Line (Start .. I - 1);
            end if;
            Current := Current + 1;
            Start := I + 1;
         end if;
      end loop;

      if Current = Index then
         return Line (Start .. Line'Last);
      end if;
      return "";
   end Field;

   function Slice_Index (Slice : String) return Natural is
   begin
      for I in 1 .. Known_Slice_Count loop
         if Slice = Known_Slice (I) then
            return I;
         end if;
      end loop;
      return 0;
   end Slice_Index;

   function Delta_Text (Previous_Line, Latest_Line : String) return String is
      Previous_Seconds : Long_Float;
      Latest_Seconds   : Long_Float;
      Delta_Value      : Long_Float;
      Hundredths       : Long_Long_Integer;
      Whole            : Long_Long_Integer;
      Fraction         : Long_Long_Integer;

      function Trim_Image (Value : Long_Long_Integer) return String is
         Raw : constant String := Long_Long_Integer'Image (Value);
      begin
         if Raw (Raw'First) = ' ' then
            return Raw (Raw'First + 1 .. Raw'Last);
         end if;
         return Raw;
      end Trim_Image;

      function Two_Digits (Value : Long_Long_Integer) return String is
         Raw : constant String := Trim_Image (Value);
      begin
         if Value < 10 then
            return "0" & Raw;
         end if;
         return Raw;
      end Two_Digits;
   begin
      if Previous_Line'Length = 0 or else Latest_Line'Length = 0 then
         return "";
      end if;

      Previous_Seconds := Long_Float'Value (Field (Previous_Line, 3));
      Latest_Seconds := Long_Float'Value (Field (Latest_Line, 3));
      Delta_Value := Latest_Seconds - Previous_Seconds;
      Hundredths := Long_Long_Integer (abs Delta_Value * 100.0 + 0.5);
      Whole := Hundredths / 100;
      Fraction := Hundredths mod 100;
      return (if Delta_Value >= 0.0 then "+" else "-") &
        Trim_Image (Whole) & "." & Two_Digits (Fraction);
   exception
      when others =>
         return "";
   end Delta_Text;

   Previous : array (1 .. Known_Slice_Count) of Unbounded_String;
   Latest : array (1 .. Known_Slice_Count) of Unbounded_String;
   F : Ada.Text_IO.File_Type;
begin
   if not Ada.Directories.Exists (Timing_Path) then
      Ada.Text_IO.Put_Line
        ("unit_test_timings: no timing records yet; run tools/bin/unit_tests <slice>");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
      return;
   end if;

   Ada.Text_IO.Open (F, Ada.Text_IO.In_File, Timing_Path);
   while not Ada.Text_IO.End_Of_File (F) loop
      declare
         Line : constant String := Ada.Text_IO.Get_Line (F);
         Slice : constant String := Field (Line, 1);
         Index : constant Natural := Slice_Index (Slice);
      begin
         if Index > 0 then
            Previous (Index) := Latest (Index);
            Latest (Index) := To_Unbounded_String (Line);
         end if;
      end;
   end loop;
   Ada.Text_IO.Close (F);

   Ada.Text_IO.Put_Line
     ("slice" & ASCII.HT & "runner" & ASCII.HT & "seconds" &
      ASCII.HT & "delta_seconds");
   for I in 1 .. Known_Slice_Count loop
      if Length (Latest (I)) > 0 then
         Ada.Text_IO.Put_Line
           (To_String (Latest (I)) & ASCII.HT &
            Delta_Text (To_String (Previous (I)), To_String (Latest (I))));
      end if;
   end loop;

   Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
exception
   when others =>
      if Ada.Text_IO.Is_Open (F) then
         Ada.Text_IO.Close (F);
      end if;
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "unit_test_timings: failed to read " & Timing_Path);
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
end Unit_Test_Timings;
