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

end Editor.Ada_Declaration_Parser.Target_Helpers;
