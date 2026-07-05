with Ada.Characters.Latin_1;
with Ada.Strings.Fixed;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Name_Profile_Helpers;
with Editor.Ada_Syntax_Core;

package body Editor.Ada_Declaration_Parser.Target_Helpers is

   use Editor.Ada_Declaration_Parser.Lexical_Helpers;
   use Editor.Ada_Declaration_Parser.Name_Profile_Helpers;

   function Skip_Component_Qualifiers
     (Line  : String;
      Start : Natural) return Natural
   is
      I : Natural := Start;

      procedure Skip_Blanks is
      begin
         while I <= Line'Last
           and then (Line (I) = ' ' or else Line (I) = Ada.Characters.Latin_1.HT)
         loop
            I := I + 1;
         end loop;
      end Skip_Blanks;

      procedure Skip_Word (Word : String) is
      begin
         Skip_Blanks;
         if I + Word'Length - 1 <= Line'Last
           and then Lower (Line (I .. I + Word'Length - 1)) = Word
           and then (I + Word'Length > Line'Last
                     or else not Is_Word_Char (Line (I + Word'Length)))
         then
            I := I + Word'Length;
         end if;
      end Skip_Word;
   begin
      Skip_Blanks;
      Skip_Word ("aliased");
      Skip_Word ("constant");
      Skip_Word ("in");
      Skip_Word ("out");
      Skip_Word ("all");
      Skip_Word ("not");
      Skip_Word ("null");
      Skip_Word ("access");
      Skip_Word ("all");
      Skip_Word ("constant");
      Skip_Blanks;
      return I;
   end Skip_Component_Qualifiers;

   function Array_Element_Target (Line : String) return String is
      L      : constant String := Lower (Editor.Ada_Syntax_Core.Sanitize_Line (Line));
      Of_Pos : constant Natural := Ada.Strings.Fixed.Index (L, " of ");
      Start  : Natural;
   begin
      if Of_Pos = 0 then
         return "";
      end if;

      Start := Skip_Component_Qualifiers
        (Line, Line'First + (Of_Pos - L'First) + 4);
      if Start > Line'Last then
         return "";
      end if;

      declare
         Target : constant String := Read_Subtype_Mark (Line, Positive (Start), True);
         Target_Lower : constant String := Lower (Target);
      begin
         if Target_Lower = "procedure" or else Target_Lower = "function" then
            return "";
         end if;
         return Target;
      end;
   end Array_Element_Target;

   function Access_Subprogram_Profile (Line : String) return String is
      --  Access-to-subprogram profiles may be ordinary or protected:
      --     access procedure (...)
      --     access protected procedure (...)
      --  Protected access-to-subprogram result profiles use the same reader
      --  so functions returning anonymous protected callbacks do not stamp
      --  "protected" as a target subtype.  Preserve the protected prefix as
      --  profile metadata and still keep anonymous profile parameters out of
      --  the language-model symbol tree.
      L          : constant String := Lower (Editor.Ada_Syntax_Core.Sanitize_Line (Line));
      Access_Pos : constant Natural := Token_Source_Position (Line, "access");
      Start      : Natural := 0;

      function Top_Level_Semicolon (First, Last : Natural) return Natural is
         Nesting : Natural := 0;
      begin
         if First > Last then
            return 0;
         end if;

         for I in First .. Last loop
            declare
               Code_Pos : constant Natural := L'First + (I - Line'First);
               Ch       : constant Character := L (Code_Pos);
            begin
               if Ch = '(' then
                  Nesting := Nesting + 1;
               elsif Ch = ')' then
                  if Nesting > 0 then
                     Nesting := Nesting - 1;
                  end if;
               elsif Ch = ';' and then Nesting = 0 then
                  return I;
               end if;
            end;
         end loop;

         return 0;
      end Top_Level_Semicolon;
   begin
      if Access_Pos /= 0 then
         declare
            After_Access : constant Natural := L'First + (Access_Pos - Line'First) + 6;
         begin
            if After_Access <= L'Last then
               declare
                  Tail : constant String := L (After_Access .. L'Last);
                  Protected_Proc_Pos : constant Natural :=
                    Ada.Strings.Fixed.Index (Tail, "protected procedure");
                  Protected_Func_Pos : constant Natural :=
                    Ada.Strings.Fixed.Index (Tail, "protected function");
                  Proc_Pos : constant Natural :=
                    Ada.Strings.Fixed.Index (Tail, "procedure");
                  Func_Pos : constant Natural :=
                    Ada.Strings.Fixed.Index (Tail, "function");
               begin
                  if Protected_Proc_Pos /= 0 then
                     Start := Protected_Proc_Pos;
                  elsif Protected_Func_Pos /= 0 then
                     Start := Protected_Func_Pos;
                  elsif Proc_Pos /= 0 then
                     Start := Proc_Pos;
                  elsif Func_Pos /= 0 then
                     Start := Func_Pos;
                  end if;
               end;
            end if;
         end;
      else
         declare
            Source_First : Natural := Line'First;
            Source_Last  : Natural := Line'Last;
         begin
            while Source_First <= Source_Last
              and then (Line (Source_First) = ' '
                        or else Line (Source_First) = Ada.Characters.Latin_1.HT)
            loop
               Source_First := Source_First + 1;
            end loop;

            while Source_Last >= Source_First
              and then (Line (Source_Last) = ' '
                        or else Line (Source_Last) = Ada.Characters.Latin_1.HT)
            loop
               Source_Last := Source_Last - 1;
            end loop;

            if Source_First <= Source_Last then
               declare
                  Trimmed_Line  : constant String := Line (Source_First .. Source_Last);
                  Lower_Trimmed : constant String := Lower (Trimmed_Line);
               begin
                  if Starts_With_Word (Lower_Trimmed, "procedure")
                    or else Starts_With_Word (Lower_Trimmed, "function")
                    or else Starts_With_Word (Lower_Trimmed, "protected procedure")
                    or else Starts_With_Word (Lower_Trimmed, "protected function")
                  then
                     declare
                        Stop : Natural := Source_Last;
                        Semi : constant Natural :=
                          Top_Level_Semicolon (Source_First, Source_Last);
                     begin
                        if Semi /= 0 then
                           Stop := Semi - 1;
                        end if;
                        if Stop < Source_First then
                           return "";
                        end if;
                        return Trim (Line (Source_First .. Stop));
                     end;
                  end if;
               end;
            end if;
         end;
      end if;

      if Start = 0 then
         return "";
      end if;

      declare
         Source_Start : constant Natural := Line'First + (Start - L'First);
         Stop         : Natural := Line'Last;
         Semi         : constant Natural :=
           Top_Level_Semicolon (Source_Start, Line'Last);
         With_Pos     : constant Natural :=
           Ada.Strings.Fixed.Index
             (Lower (Editor.Ada_Syntax_Core.Sanitize_Line
                (Line (Source_Start .. Line'Last))), " with ");
      begin
         if Semi /= 0 then
            Stop := Natural'Min (Stop, Semi - 1);
         end if;
         if With_Pos /= 0 then
            Stop := Natural'Min
              (Stop, Source_Start + (With_Pos - 1) - 1);
         end if;
         if Stop < Source_Start then
            return "";
         end if;
         return Trim (Line (Source_Start .. Stop));
      end;
   end Access_Subprogram_Profile;

   function Access_Object_Target (Line : String) return String is
      L          : constant String := Lower (Editor.Ada_Syntax_Core.Sanitize_Line (Line));
      Access_Pos : constant Natural := Token_Source_Position (Line, "access");
      Start      : Natural;
   begin
      if Access_Pos = 0
        or else Has_Token (L, "procedure")
        or else Has_Token (L, "function")
      then
         return "";
      end if;

      Start := Skip_Component_Qualifiers (Line, Access_Pos + 6);
      if Start > Line'Last then
         return "";
      end if;

      return Read_Subtype_Mark (Line, Positive (Start), True);
   end Access_Object_Target;

   function Object_Target_After_Colon (Line : String) return String is
      Code  : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      Colon : Natural := 0;
      Start : Natural;
      Mark  : String (1 .. 256) := (others => ' ');
      Len   : Natural := 0;
   begin
      for I in Code'Range loop
         if Code (I) = ':' then
            Colon := I;
            exit;
         elsif Code (I) = ';' then
            return "";
         end if;
      end loop;

      if Colon = 0
        or else Line'First + (Colon - Code'First) >= Line'Last
      then
         return "";
      end if;

      Start := Skip_Component_Qualifiers
        (Line, Line'First + (Colon - Code'First) + 1);
      if Start > Line'Last then
         return "";
      end if;

      declare
         Candidate : constant String := Read_Subtype_Mark (Line, Positive (Start), True);
         Candidate_Lower : constant String := Lower (Candidate);
      begin
         if Candidate_Lower = "array" then
            declare
               Element_Target : constant String := Array_Element_Target (Line);
            begin
               if Element_Target'Length = 0 then
                  return "";
               end if;

               Len := Natural'Min (Element_Target'Length, Mark'Length);
               Mark (1 .. Len) :=
                 Element_Target (Element_Target'First .. Element_Target'First + Len - 1);
               return Mark (1 .. Len);
            end;
         elsif Candidate_Lower = "access" then
            if Has_Token (Lower (Line), "procedure")
              or else Has_Token (Lower (Line), "function")
            then
               return "";
            end if;

            declare
               Designated_Target : constant String := Access_Object_Target (Line);
            begin
               if Designated_Target'Length = 0 then
                  return "";
               end if;

               Len := Natural'Min (Designated_Target'Length, Mark'Length);
               Mark (1 .. Len) :=
                 Designated_Target
                   (Designated_Target'First .. Designated_Target'First + Len - 1);
               return Mark (1 .. Len);
            end;
         elsif Candidate_Lower = "protected"
           and then (Has_Token (Lower (Line), "procedure")
                     or else Has_Token (Lower (Line), "function"))
         then
            return "";
         end if;

         if Candidate'Length = 0
           or else Candidate_Lower = "record"
           or else Candidate_Lower = "range"
           or else Candidate_Lower = "procedure"
           or else Candidate_Lower = "function"
           or else Candidate_Lower = "exception"
           or else Candidate_Lower = "renames"
           or else Candidate_Lower = "with"
         then
            return "";
         end if;

         Len := Natural'Min (Candidate'Length, Mark'Length);
         Mark (1 .. Len) := Candidate (Candidate'First .. Candidate'First + Len - 1);
      end;

      return Mark (1 .. Len);
   end Object_Target_After_Colon;

   function Return_Target_From_Position
     (Line  : String;
      Start : Natural) return String
   is
      Target : String (1 .. 256) := (others => ' ');
      Len    : Natural := 0;
      First  : Natural := Skip_Component_Qualifiers (Line, Start);
   begin
      if First > Line'Last then
         return "";
      end if;

      declare
         Candidate       : constant String := Read_Subtype_Mark (Line, Positive (First), True);
         Lower_Candidate : constant String := Lower (Candidate);
      begin
         if Candidate'Length = 0
           or else Lower_Candidate = "with"
           or else Lower_Candidate = "renames"
           or else Lower_Candidate = "is"
           or else Lower_Candidate = "separate"
           or else Lower_Candidate = "procedure"
           or else Lower_Candidate = "function"
           or else Lower_Candidate = "protected"
         then
            return "";
         end if;

         Len := Natural'Min (Candidate'Length, Target'Length);
         Target (1 .. Len) := Candidate (Candidate'First .. Candidate'First + Len - 1);
         return Target (1 .. Len);
      end;
   end Return_Target_From_Position;

   function Return_Target_From_Line_Start (Line : String) return String is
      L     : constant String := Lower (Trim (Line));
      Start : Natural := Line'First;
   begin
      while Start <= Line'Last
        and then (Line (Start) = ' ' or else Line (Start) = Ada.Characters.Latin_1.HT)
      loop
         Start := Start + 1;
      end loop;

      if L'Length < 6 or else not Starts_With_Word (L, "return") then
         return "";
      end if;

      return Return_Target_From_Position (Line, Start + 6);
   end Return_Target_From_Line_Start;

   function Function_Return_Target (Line : String) return String is
      L          : constant String := Lower (Line);
      Return_Pos : constant Natural := Ada.Strings.Fixed.Index (L, " return ");
   begin
      if Return_Pos = 0 then
         return Return_Target_From_Line_Start (Line);
      end if;

      return Return_Target_From_Position (Line, Return_Pos + 8);
   end Function_Return_Target;

   function Interface_Parent_Target (Line : String) return String is
      L       : constant String := Lower (Line);
      And_Pos : constant Natural := Ada.Strings.Fixed.Index (L, " and ");
      Start   : Natural;
   begin
      if And_Pos = 0 or else not Has_Token (L, "interface") then
         return "";
      end if;

      Start := And_Pos + 5;
      while Start <= Line'Last
        and then (Line (Start) = ' ' or else Line (Start) = Ada.Characters.Latin_1.HT)
      loop
         Start := Start + 1;
      end loop;

      if Start > Line'Last then
         return "";
      end if;

      return Read_Subtype_Mark (Line, Positive (Start), True);
   end Interface_Parent_Target;

   function Interface_Target_From_Line_Start (Line : String) return String is
      Start : Natural := Line'First;
   begin
      while Start <= Line'Last
        and then (Line (Start) = ' ' or else Line (Start) = Ada.Characters.Latin_1.HT)
      loop
         Start := Start + 1;
      end loop;

      if Start > Line'Last then
         return "";
      end if;

      declare
         Target       : constant String := Read_Subtype_Mark (Line, Positive (Start), True);
         Target_Lower : constant String := Lower (Target);
      begin
         if Target'Length = 0
           or else Target_Lower = "and"
           or else Target_Lower = "interface"
           or else Target_Lower = "limited"
           or else Target_Lower = "synchronized"
           or else Target_Lower = "private"
           or else Target_Lower = "with"
           or else Target_Lower = "is"
         then
            return "";
         end if;

         return Target;
      end;
   end Interface_Target_From_Line_Start;

   function Subtype_Target_After_Is (Line : String) return String is
      L      : constant String := Lower (Editor.Ada_Syntax_Core.Sanitize_Line (Line));
      Is_Pos : constant Natural := Ada.Strings.Fixed.Index (L, " is");
      Start  : Natural;
   begin
      if Is_Pos = 0 then
         return "";
      end if;

      Start := Line'First + (Is_Pos - L'First) + 3;
      while Start <= Line'Last
        and then (Line (Start) = ' ' or else Line (Start) = Ada.Characters.Latin_1.HT)
      loop
         Start := Start + 1;
      end loop;

      if Start + 7 <= Line'Last
        and then Lower (Line (Start .. Start + 7)) = "not null"
      then
         Start := Start + 8;
         while Start <= Line'Last
           and then (Line (Start) = ' ' or else Line (Start) = Ada.Characters.Latin_1.HT)
         loop
            Start := Start + 1;
         end loop;
      end if;

      if Start > Line'Last then
         return "";
      end if;

      return Read_Subtype_Mark (Line, Positive (Start), True);
   end Subtype_Target_After_Is;

end Editor.Ada_Declaration_Parser.Target_Helpers;
