with Ada.Characters.Latin_1;

with Editor.Ada_Declaration_Parser.Declaration_Collectors;
with Editor.Ada_Declaration_Parser.Tail_Analysis_Helpers;
with Editor.Ada_Syntax_Core;
with Editor.Text_Helpers;

package body Editor.Ada_Declaration_Parser.Compact_Record_Tail_Phase is

   use Editor.Ada_Language_Model;
   use Editor.Text_Helpers;

   Max_Scope_Nesting : constant Natural := 128;

   procedure Parse_Compact_Record_Tail
     (Analysis      : in out Analysis_Result;
      Raw_Line      : String;
      Line_Number   : Positive;
      Depth         : Natural;
      Owner         : Symbol_Id;
      Mark_Metadata : not null access procedure
        (Flags : in out Declaration_Flags;
         Line  : String))
   is
      Code         : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
      Lower_Code   : constant String := Lower (Code);
      Nesting      : Natural := 0;
      Record_Start : Natural := 0;
      Record_End   : Natural := 0;
      End_Start    : Natural := 0;

      function Token_At (Pos : Natural; Token : String) return Boolean is
      begin
         return Editor.Ada_Declaration_Parser.Tail_Analysis_Helpers.Tail_Token_At
           (Lower_Code, Pos, Token);
      end Token_At;
   begin
      for I in Code'Range loop
         if Code (I) = '(' then
            Nesting := Nesting + 1;
         elsif Code (I) = ')' then
            if Nesting > 0 then
               Nesting := Nesting - 1;
            end if;
         elsif Nesting = 0 and then Token_At (I, "record") then
            Record_Start := I;
            Record_End := I + 5;
            exit;
         end if;
      end loop;

      if Record_Start = 0 or else Record_End >= Code'Last then
         return;
      end if;

      Nesting := 0;
      for I in Record_End + 1 .. Code'Last loop
         if Code (I) = '(' then
            Nesting := Nesting + 1;
         elsif Code (I) = ')' then
            if Nesting > 0 then
               Nesting := Nesting - 1;
            end if;
         elsif Nesting = 0 and then Token_At (I, "end") then
            declare
               K : Natural := I + 3;
            begin
               while K <= Code'Last
                 and then (Code (K) = ' '
                           or else Code (K) = Ada.Characters.Latin_1.HT)
               loop
                  K := K + 1;
               end loop;

               if K <= Code'Last and then Token_At (K, "record") then
                  End_Start := I;
                  exit;
               end if;
            end;
         end if;
      end loop;

      declare
         Tail_Line : String := Raw_Line;

         function Source_Position (Code_Position : Natural) return Natural is
         begin
            return Raw_Line'First + (Code_Position - Code'First);
         end Source_Position;

         Record_End_Source : constant Natural := Source_Position (Record_End);
      begin
         for I in Tail_Line'First .. Record_End_Source loop
            Tail_Line (I) := ' ';
         end loop;

         if End_Start /= 0 then
            declare
               End_Start_Source : constant Natural := Source_Position (End_Start);
            begin
               for I in End_Start_Source .. Tail_Line'Last loop
                  Tail_Line (I) := ' ';
               end loop;
            end;
         end if;

         if Trim (Editor.Ada_Syntax_Core.Sanitize_Line (Tail_Line))'Length = 0 then
            return;
         end if;

         declare
            Tail_Code : constant String :=
              Editor.Ada_Syntax_Core.Sanitize_Line (Tail_Line);
            Segment_Start : Natural := Tail_Line'First;
            Nesting : Natural := 0;

            procedure Add_Segment (First, Last : Natural) is
            begin
               if First <= Last
                 and then Trim
                   (Editor.Ada_Syntax_Core.Sanitize_Line
                      (Tail_Line (First .. Last)))'Length /= 0
               then
                  declare
                     Segment_Line : String := (Tail_Line'Range => ' ');
                  begin
                     Segment_Line (First .. Last) := Tail_Line (First .. Last);

                  Declaration_Collectors.Add_Record_Component_Names
                    (Analysis, Segment_Line, Line_Number,
                     Natural'Min (Depth + 1, Max_Scope_Nesting), Owner,
                     Mark_Metadata);
                  end;
               end if;
            end Add_Segment;
         begin
            for I in Tail_Code'Range loop
               if Tail_Code (I) = '(' then
                  Nesting := Nesting + 1;
               elsif Tail_Code (I) = ')' then
                  if Nesting > 0 then
                     Nesting := Nesting - 1;
                  end if;
               elsif Tail_Code (I) = ';' and then Nesting = 0 then
                  Add_Segment (Segment_Start, I - 1);
                  Segment_Start := I + 1;
               end if;
            end loop;

            if Segment_Start <= Tail_Line'Last then
               Add_Segment (Segment_Start, Tail_Line'Last);
            end if;
         end;
      end;
   end Parse_Compact_Record_Tail;

end Editor.Ada_Declaration_Parser.Compact_Record_Tail_Phase;
