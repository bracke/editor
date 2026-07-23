with Ada.Characters.Latin_1;
with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Syntax_Core;
with Editor.Outline_Extractor.Line_Analysis.Structure_Labels;

package body Editor.Outline_Extractor.Line_Analysis is

   use type Editor.Outline.Outline_Item_Kind;

   Marker : constant String := "@outline ";

   function Starts_With_Subprogram_Keyword (Text : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Lexical_Helpers.Starts_With_Subprogram_Keyword;

   function First_Non_Blank_Column (Line : String) return Natural
   is
   begin
      for I in Line'Range loop
         if Line (I) /= ' ' and then Line (I) /= Ada.Characters.Latin_1.HT then
            return I - Line'First + 1;
         end if;
      end loop;
      return 1;
   end First_Non_Blank_Column;

   function Trim_Code_Whitespace (Line : String) return String
   is
      First : Natural := Line'First;
      Last  : Natural := Line'Last;
   begin
      if Line'Length = 0 then
         return "";
      end if;

      while First <= Last
        and then (Line (First) = ' '
                  or else Line (First) = Ada.Characters.Latin_1.HT)
      loop
         First := First + 1;
      end loop;

      while Last >= First
        and then (Line (Last) = ' '
                  or else Line (Last) = Ada.Characters.Latin_1.HT)
      loop
         Last := Last - 1;
      end loop;

      if First > Last then
         return "";
      else
         declare
            Slice  : constant String := Line (First .. Last);
            Result : String (1 .. Slice'Length);
         begin
            Result := Slice;
            return Result;
         end;
      end if;
   end Trim_Code_Whitespace;

   function Tabs_As_Spaces (Text : String) return String
   is
      Result : String := Text;
   begin
      for I in Result'Range loop
         if Result (I) = Ada.Characters.Latin_1.HT then
            Result (I) := ' ';
         end if;
      end loop;

      return Result;
   end Tabs_As_Spaces;

   function Starts_With
     (Text   : String;
      Prefix : String) return Boolean
   is
   begin
      return Text'Length >= Prefix'Length
        and then Text (Text'First .. Text'First + Prefix'Length - 1) = Prefix;
   end Starts_With;

   function Ends_With
     (Text   : String;
      Suffix : String) return Boolean
   is
   begin
      return Text'Length >= Suffix'Length
        and then Text (Text'Last - Suffix'Length + 1 .. Text'Last) = Suffix;
   end Ends_With;

   function Kind_For_Label (Label : String) return Editor.Outline.Outline_Item_Kind
   is
      Lower : constant String := Ada.Strings.Fixed.Translate
        (Label, Ada.Strings.Maps.Constants.Lower_Case_Map);
   begin
      if Starts_With (Lower, "variant record type ") then
         return Editor.Outline.Outline_Type;
      elsif Starts_With (Lower, "entry family ") then
         return Editor.Outline.Outline_Subprogram;
      elsif Starts_With (Lower, "generic package ") then
         return Editor.Outline.Outline_Package;
      elsif Starts_With (Lower, "generic procedure body ") then
         return Editor.Outline.Outline_Procedure;
      elsif Starts_With (Lower, "generic procedure ") then
         return Editor.Outline.Outline_Procedure;
      elsif Starts_With (Lower, "generic function body ") then
         return Editor.Outline.Outline_Function;
      elsif Starts_With (Lower, "generic expression function ") then
         return Editor.Outline.Outline_Function;
      elsif Starts_With (Lower, "generic function ") then
         return Editor.Outline.Outline_Function;
      elsif Starts_With (Lower, "package body ") then
         return Editor.Outline.Outline_Package_Body;
      elsif Starts_With (Lower, "package ") then
         return Editor.Outline.Outline_Package;
      elsif Starts_With (Lower, "record type ") then
         return Editor.Outline.Outline_Type;
      elsif Starts_With (Lower, "private type ") then
         return Editor.Outline.Outline_Type;
      elsif Starts_With (Lower, "subtype ") then
         return Editor.Outline.Outline_Type;
      elsif Starts_With (Lower, "type ") then
         return Editor.Outline.Outline_Type;
      elsif Starts_With (Lower, "procedure body ") then
         return Editor.Outline.Outline_Procedure;
      elsif Starts_With (Lower, "procedure ") then
         return Editor.Outline.Outline_Procedure;
      elsif Starts_With (Lower, "function body ") then
         return Editor.Outline.Outline_Function;
      elsif Starts_With (Lower, "expression function ") then
         return Editor.Outline.Outline_Function;
      elsif Starts_With (Lower, "function ") then
         return Editor.Outline.Outline_Function;
      elsif Starts_With (Lower, "task body ") then
         return Editor.Outline.Outline_Task;
      elsif Starts_With (Lower, "task type ") then
         return Editor.Outline.Outline_Task;
      elsif Starts_With (Lower, "task ") then
         return Editor.Outline.Outline_Task;
      elsif Starts_With (Lower, "protected body ") then
         return Editor.Outline.Outline_Protected;
      elsif Starts_With (Lower, "protected type ") then
         return Editor.Outline.Outline_Protected;
      elsif Starts_With (Lower, "protected ") then
         return Editor.Outline.Outline_Protected;
      elsif Starts_With (Lower, "section ") then
         return Editor.Outline.Outline_Section;
      elsif Starts_With (Lower, "entry ") then
         return Editor.Outline.Outline_Subprogram;
      elsif Starts_With (Lower, "field ") then
         return Editor.Outline.Outline_Field;
      elsif Starts_With (Lower, "discriminant ") then
         return Editor.Outline.Outline_Discriminant;
      elsif Starts_With (Lower, "literal ") then
         return Editor.Outline.Outline_Enum_Literal;
      elsif Starts_With (Lower, "exception ") then
         return Editor.Outline.Outline_Exception;
      elsif Starts_With (Lower, "constant ") then
         return Editor.Outline.Outline_Object;
      elsif Starts_With (Lower, "formal ") then
         return Editor.Outline.Outline_Generic_Formal;
      else
         return Editor.Outline.Outline_Unknown;
      end if;
   end Kind_For_Label;

   function Has_File_Extension (Text : String) return Boolean
   is
   begin
      for I in reverse Text'Range loop
         if Text (I) = '.' then
            return I < Text'Last;
         elsif Text (I) = '/' or else Text (I) = Character'Val (16#5C#) then
            return False;
         end if;
      end loop;
      return False;
   end Has_File_Extension;

   function Is_Word_Char (C : Character) return Boolean
   is
   begin
      return (C >= 'A' and then C <= 'Z')
        or else (C >= 'a' and then C <= 'z')
        or else (C >= '0' and then C <= '9')
        or else C = '_';
   end Is_Word_Char;

   function Starts_With_Word
     (Lower_Line : String;
      Word       : String) return Boolean
   is
      After : Natural;
   begin
      if not Starts_With (Lower_Line, Word) then
         return False;
      end if;

      After := Lower_Line'First + Word'Length;
      return After > Lower_Line'Last or else not Is_Word_Char (Lower_Line (After));
   end Starts_With_Word;

   function Starts_With_Keyword
     (Lower_Line : String;
      Keyword    : String) return Boolean
   is
      After : Natural;
   begin
      if not Starts_With (Lower_Line, Keyword) then
         return False;
      end if;

      After := Lower_Line'First + Keyword'Length;
      return After > Lower_Line'Last or else not Is_Word_Char (Lower_Line (After));
   end Starts_With_Keyword;

   function Starts_With_Phrase
     (Lower_Line : String;
      Phrase     : String) return Boolean
   is
   begin
      return Starts_With (Lower_Line, Phrase);
   end Starts_With_Phrase;

   function Declaration_Target_Column (Line : String) return Natural
   is
      First_Column : constant Natural := First_Non_Blank_Column (Line);
      First_Index  : constant Natural := Line'First + First_Column - 1;
      Lower        : constant String (Line'Range) := Ada.Strings.Fixed.Translate
        (Line, Ada.Strings.Maps.Constants.Lower_Case_Map);
      Close        : Natural := 0;
      I            : Natural := First_Index;

      procedure Skip_Blanks is
      begin
         while I <= Line'Last
           and then (Line (I) = ' ' or else Line (I) = Ada.Characters.Latin_1.HT)
         loop
            I := I + 1;
         end loop;
      end Skip_Blanks;
   begin
      if Line'Length = 0 or else First_Index > Line'Last then
         return First_Column;
      end if;

      if Starts_With_Word (Lower (First_Index .. Line'Last), "separate") then
         for J in First_Index .. Line'Last loop
            if Line (J) = ')' then
               Close := J;
               exit;
            end if;
         end loop;

         if Close = 0 or else Close >= Line'Last then
            return First_Column;
         end if;

         I := Close + 1;
         Skip_Blanks;
      end if;

      if I <= Line'Last
        and then Starts_With_Phrase (Lower (I .. Line'Last), "not overriding ")
      then
         I := I + 15;
         Skip_Blanks;
      elsif I <= Line'Last
        and then Starts_With_Phrase (Lower (I .. Line'Last), "overriding ")
      then
         I := I + 11;
         Skip_Blanks;
      end if;

      if I <= Line'Last
        and then Starts_With_Phrase (Lower (I .. Line'Last), "abstract procedure ")
      then
         I := I + 9;
         Skip_Blanks;
      elsif I <= Line'Last
        and then Starts_With_Phrase (Lower (I .. Line'Last), "abstract function ")
      then
         I := I + 9;
         Skip_Blanks;
      end if;

      if I <= Line'Last
        and then Starts_With_Phrase (Lower (I .. Line'Last), "private package ")
      then
         I := I + 8;
         Skip_Blanks;
      end if;

      if I <= Line'Last then
         return I - Line'First + 1;
      end if;

      return First_Column;
   end Declaration_Target_Column;

   function Looks_Like_Record_Field_Line (Lower_Line : String) return Boolean
   is
      Colon : Natural := 0;
   begin
      if Lower_Line'Length = 0
        or else Starts_With_Word (Lower_Line, "end")
        or else Starts_With_Word (Lower_Line, "case")
        or else Starts_With_Word (Lower_Line, "when")
        or else Starts_With_Word (Lower_Line, "null")
        or else Starts_With_Word (Lower_Line, "pragma")
        or else Starts_With_Word (Lower_Line, "type")
        or else Starts_With_Word (Lower_Line, "subtype")
        or else Starts_With_Subprogram_Keyword (Lower_Line)
        or else Starts_With_Word (Lower_Line, "package")
        or else Starts_With_Word (Lower_Line, "task")
        or else Starts_With_Word (Lower_Line, "protected")
        or else Starts_With_Word (Lower_Line, "entry")
        or else not Has_Code_Character (Lower_Line, ';')
      then
         return False;
      end if;

      for I in Lower_Line'Range loop
         if Lower_Line (I) = ':' then
            Colon := I;
            exit;
         elsif Lower_Line (I) = ';' then
            return False;
         end if;
      end loop;

      if Colon = 0 or else Colon = Lower_Line'First then
         return False;
      end if;

      declare
         Prefix : constant String := Ada.Strings.Fixed.Trim
           (Lower_Line (Lower_Line'First .. Colon - 1), Ada.Strings.Both);
      begin
         if Prefix'Length = 0 then
            return False;
         end if;

         for C of Prefix loop
            if not (Is_Word_Char (C)
                    or else C = ','
                    or else C = ' '
                    or else C = Ada.Characters.Latin_1.HT)
            then
               return False;
            end if;
         end loop;
      end;

      return True;
   end Looks_Like_Record_Field_Line;

   function Record_Field_Name (Line : String) return String
   is
      Colon : Natural := 0;
   begin
      for I in Line'Range loop
         if Line (I) = ':' then
            Colon := I;
            exit;
         elsif Line (I) = ';' then
            return "";
         end if;
      end loop;

      if Colon = 0 or else Colon = Line'First then
         return "";
      end if;

      return Ada.Strings.Fixed.Trim
        (Line (Line'First .. Colon - 1), Ada.Strings.Both);
   end Record_Field_Name;

   function First_Colon (Line : String) return Natural
   is
   begin
      for I in Line'Range loop
         if Line (I) = ':' then
            return I;
         elsif Line (I) = ';' then
            return 0;
         end if;
      end loop;
      return 0;
   end First_Colon;

   function Declaration_Name_List_Before_Colon (Line : String) return String
   is
      Colon : constant Natural := First_Colon (Line);
   begin
      if Colon = 0 or else Colon = Line'First then
         return "";
      end if;

      declare
         Prefix : constant String := Ada.Strings.Fixed.Trim
           (Line (Line'First .. Colon - 1), Ada.Strings.Both);
      begin
         if Prefix'Length = 0 then
            return "";
         end if;

         for C of Prefix loop
            if not (Is_Word_Char (C)
                    or else C = ','
                    or else C = ' '
                    or else C = Ada.Characters.Latin_1.HT)
            then
               return "";
            end if;
         end loop;

         return Prefix;
      end;
   end Declaration_Name_List_Before_Colon;

   function Generic_Formal_Prefix (Lower_Line : String) return String
   is
   begin
      if Starts_With_Word (Lower_Line, "type") then
         return "formal type";
      elsif Starts_With_Phrase (Lower_Line, "with package ") then
         return "formal package";
      elsif Starts_With_Phrase (Lower_Line, "with procedure ") then
         return "formal procedure";
      elsif Starts_With_Phrase (Lower_Line, "with function ") then
         return "formal function";
      else
         return "formal object";
      end if;
   end Generic_Formal_Prefix;

   function Generic_Formal_Name (Trimmed : String; Lower_Line : String) return String
   is
      Prefix : constant String := Generic_Formal_Prefix (Lower_Line);
   begin
      if Prefix = "formal type" then
         return Read_Name (Trimmed, Trimmed'First + 5, False);
      elsif Prefix = "formal package" then
         return Read_Name (Trimmed, Trimmed'First + 13, True);
      elsif Prefix = "formal procedure" then
         return Read_Name (Trimmed, Trimmed'First + 15, True);
      elsif Prefix = "formal function" then
         return Read_Function_Name (Trimmed, Trimmed'First + 14, True);
      else
         return Declaration_Name_List_Before_Colon (Trimmed);
      end if;
   end Generic_Formal_Name;

   function Looks_Like_Exception_Declaration (Lower_Line : String) return Boolean
   is
      Colon : constant Natural := First_Colon (Lower_Line);
   begin
      if Colon = 0
        or else Colon >= Lower_Line'Last
        or else not Has_Code_Character (Lower_Line, ';')
        or else Starts_With_Word (Lower_Line, "type")
        or else Starts_With_Word (Lower_Line, "subtype")
      then
         return False;
      end if;

      declare
         Tail : constant String := Ada.Strings.Fixed.Trim
           (Lower_Line (Colon + 1 .. Lower_Line'Last), Ada.Strings.Both);
      begin
         return Starts_With_Word (Tail, "exception");
      end;
   end Looks_Like_Exception_Declaration;

   function Looks_Like_Constant_Declaration (Lower_Line : String) return Boolean
   is
      Colon : constant Natural := First_Colon (Lower_Line);
   begin
      if Colon = 0
        or else Colon >= Lower_Line'Last
        or else not Has_Code_Character (Lower_Line, ';')
        or else Starts_With_Word (Lower_Line, "type")
        or else Starts_With_Word (Lower_Line, "subtype")
        or else Starts_With_Subprogram_Keyword (Lower_Line)
        or else Starts_With_Word (Lower_Line, "entry")
      then
         return False;
      end if;

      declare
         Tail : constant String := Ada.Strings.Fixed.Trim
           (Lower_Line (Colon + 1 .. Lower_Line'Last), Ada.Strings.Both);
      begin
         return Starts_With_Word (Tail, "constant");
      end;
   end Looks_Like_Constant_Declaration;

   function Looks_Like_Object_Declaration (Lower_Line : String) return Boolean
   is
      Colon : constant Natural := First_Colon (Lower_Line);
   begin
      if Colon = 0
        or else Colon >= Lower_Line'Last
        or else not Has_Code_Character (Lower_Line, ';')
        or else Starts_With_Word (Lower_Line, "type")
        or else Starts_With_Word (Lower_Line, "subtype")
        or else Starts_With_Subprogram_Keyword (Lower_Line)
        or else Starts_With_Word (Lower_Line, "entry")
        or else Starts_With_Word (Lower_Line, "package")
        or else Starts_With_Word (Lower_Line, "task")
        or else Starts_With_Word (Lower_Line, "protected")
        or else Starts_With_Word (Lower_Line, "generic")
        or else Starts_With_Word (Lower_Line, "pragma")
        or else Starts_With_Word (Lower_Line, "for")
        or else Starts_With_Word (Lower_Line, "use")
        or else Starts_With_Word (Lower_Line, "with")
        or else Starts_With_Word (Lower_Line, "private")
        or else Starts_With_Word (Lower_Line, "overriding")
        or else Starts_With_Word (Lower_Line, "not")
      then
         return False;
      end if;

      return Declaration_Name_List_Before_Colon (Lower_Line)'Length > 0;
   end Looks_Like_Object_Declaration;

   function First_Enumeration_List_Column (Line : String) return Natural
   is
   begin
      for I in Line'Range loop
         if Line (I) = '(' then
            return I;
         end if;
      end loop;
      return Line'First;
   end First_Enumeration_List_Column;

   procedure Append_Record_Field_Line
     (Result      : in out Extraction_Result;
      In_Record_Type : Boolean;
      Depth       : Natural;
      Raw_Line    : String;
      Line_Number : Positive;
      Lower_Line  : String;
      Trimmed     : String)
   is
      Name : constant String := Record_Field_Name (Trimmed);
   begin
      if In_Record_Type
        and then Looks_Like_Record_Field_Line (Lower_Line)
        and then Name'Length > 0
      then
         Append_Item
           (Result, Editor.Outline.Outline_Field, "field", Name,
            Raw_Line, Line_Number, Depth + 1, "component");
      end if;
   end Append_Record_Field_Line;

   procedure Append_Generic_Formal_Line
     (Result      : in out Extraction_Result;
      Depth       : Natural;
      Raw_Line    : String;
      Line_Number : Positive;
      Lower_Line  : String;
      Trimmed     : String)
   is
      Prefix : constant String := Generic_Formal_Prefix (Lower_Line);
      Name   : constant String := Generic_Formal_Name (Trimmed, Lower_Line);
   begin
      if Name'Length = 0
        or else Starts_With_Word (Lower_Line, "use")
        or else Starts_With_Word (Lower_Line, "pragma")
        or else Starts_With_Word (Lower_Line, "private")
        or else Starts_With_Phrase (Lower_Line, "limited private")
        or else Starts_With_Word (Lower_Line, "range")
        or else Starts_With_Word (Lower_Line, "digits")
        or else Starts_With_Word (Lower_Line, "delta")
        or else Starts_With (Lower_Line, "(")
      then
         return;
      end if;

      Append_Item
        (Result, Editor.Outline.Outline_Generic_Formal, Prefix, Name,
         Raw_Line, Line_Number, Depth + 1,
         Declaration_Form (Lower_Line, Editor.Outline.Outline_Generic_Formal));
   end Append_Generic_Formal_Line;

   procedure Append_Discriminants_From_Type_Line
     (Result      : in out Extraction_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural)
   is
      Code          : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
      Open_Paren    : Natural := 0;
      Close_Paren   : Natural := 0;
      Segment_Start : Natural := 0;

      procedure Append_Segment (First : Natural; Last : Natural) is
      begin
         if First <= Last then
            declare
               Segment : constant String := Ada.Strings.Fixed.Trim
                 (Raw_Line (First .. Last), Ada.Strings.Both);
               Name : constant String := Declaration_Name_List_Before_Colon (Segment);
            begin
               if Name'Length > 0 then
                  Append_Item
                    (Result, Editor.Outline.Outline_Discriminant,
                     "discriminant", Name, Raw_Line, Line_Number, Depth,
                     "discriminant");
               end if;
            end;
         end if;
      end Append_Segment;
   begin
      for I in Code'Range loop
         if Code (I) = '(' then
            Open_Paren := I;
            exit;
         elsif Code (I) = ';' then
            return;
         end if;
      end loop;

      if Open_Paren = 0 then
         return;
      end if;

      for I in Open_Paren + 1 .. Code'Last loop
         if Code (I) = ')' then
            Close_Paren := I;
            exit;
         end if;
      end loop;

      if Close_Paren = 0 or else Close_Paren <= Open_Paren + 1 then
         return;
      end if;

      Segment_Start := Open_Paren + 1;
      for I in Open_Paren + 1 .. Close_Paren - 1 loop
         if Code (I) = ';' then
            Append_Segment (Segment_Start, I - 1);
            Segment_Start := I + 1;
         end if;
      end loop;
      Append_Segment (Segment_Start, Close_Paren - 1);
   end Append_Discriminants_From_Type_Line;

   procedure Append_Enumeration_Literals_From_Line
     (Result      : in out Extraction_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Start_At    : Natural)
   is
      Code : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
      I    : Natural := (if Start_At in Code'Range then Start_At else Code'First);
   begin
      while I <= Code'Last loop
         if Code (I) = ')' or else Code (I) = ';' then
            return;
         elsif Code (I) = Character'Val (16#27#)
           and then Editor.Ada_Syntax_Core.Looks_Like_Simple_Character_Literal (Raw_Line, I)
         then
            declare
               Literal_Last : constant Natural :=
                 (if I + 3 <= Raw_Line'Last
                    and then Raw_Line (I + 1) = Character'Val (16#27#)
                    and then Raw_Line (I + 2) = Character'Val (16#27#)
                    and then Raw_Line (I + 3) = Character'Val (16#27#)
                  then I + 3
                  else I + 2);
               Name : constant String := Raw_Line (I .. Literal_Last);
            begin
               Append_Item
                 (Result, Editor.Outline.Outline_Enum_Literal,
                  "literal", Name, Raw_Line, Line_Number, Depth, "enumeration");
               I := Literal_Last + 1;
            end;
         elsif (Code (I) >= 'A' and then Code (I) <= 'Z')
           or else (Code (I) >= 'a' and then Code (I) <= 'z')
         then
            declare
               J : Natural := I;
            begin
               while J <= Code'Last and then Is_Word_Char (Code (J)) loop
                  J := J + 1;
               end loop;

               declare
                  Name : constant String := Raw_Line (I .. J - 1);
                  Lower_Name : constant String := Ada.Strings.Fixed.Translate
                    (Name, Ada.Strings.Maps.Constants.Lower_Case_Map);
               begin
                  if Lower_Name /= "is" and then Lower_Name /= "range" then
                     Append_Item
                       (Result, Editor.Outline.Outline_Enum_Literal,
                        "literal", Name, Raw_Line, Line_Number, Depth, "enumeration");
                  end if;
               end;
               I := J;
            end;
         else
            I := I + 1;
         end if;
      end loop;
   end Append_Enumeration_Literals_From_Line;

   procedure Append_Marker_Source_Line
     (Result      : in out Extraction_Result;
      Raw_Line    : String;
      Line_Number : Positive)
   is
      Ignored : constant Boolean := Append_Marker_Line (Result, Raw_Line, Line_Number);
   begin
      null;
   end Append_Marker_Source_Line;

   procedure Append_Marker_Lines
     (Result : in out Extraction_Result;
      Text   : String)
   is
      Line_Start  : Positive := Text'First;
      Line_Number : Positive := 1;
   begin
      if Text'Length = 0 then
         return;
      end if;

      for I in Text'Range loop
         if Text (I) = Ada.Characters.Latin_1.LF then
            declare
               Line_End : Natural := I - 1;
            begin
               if Line_End >= Line_Start
                 and then Text (Line_End) = Ada.Characters.Latin_1.CR
               then
                  Line_End := Line_End - 1;
               end if;

               if Line_End >= Line_Start then
                  Append_Marker_Source_Line
                    (Result, Text (Line_Start .. Line_End), Line_Number);
               else
                  Append_Marker_Source_Line (Result, "", Line_Number);
               end if;
            end;
            Line_Start := I + 1;
            Line_Number := Line_Number + 1;
         end if;
      end loop;

      if Line_Start <= Text'Last then
         declare
            Line_End : Natural := Text'Last;
         begin
            if Text (Line_End) = Ada.Characters.Latin_1.CR then
               Line_End := Line_End - 1;
            end if;

            if Line_End >= Line_Start then
               Append_Marker_Source_Line
                 (Result, Text (Line_Start .. Line_End), Line_Number);
            else
               Append_Marker_Source_Line (Result, "", Line_Number);
            end if;
         end;
      end if;
   end Append_Marker_Lines;

   function Looks_Like_Ada_Line (Trimmed : String) return Boolean
   is
   begin
      return Editor.Ada_Syntax_Core.Looks_Like_Ada_Declaration_Line (Trimmed);
   end Looks_Like_Ada_Line;

   function Looks_Like_Ada_Buffer
     (Text         : String;
      Buffer_Label : String) return Boolean
   is
      Lower_Label : constant String := Ada.Strings.Fixed.Translate
        (Buffer_Label, Ada.Strings.Maps.Constants.Lower_Case_Map);
      Line_Start  : Positive := Text'First;
   begin
      if Editor.Ada_Syntax_Core.Is_Ada_Source_Label (Buffer_Label)
      then
         return True;
      elsif Has_File_Extension (Lower_Label) then
         return False;
      end if;

      if Text'Length = 0 then
         return False;
      end if;

      for I in Text'Range loop
         if Text (I) = Ada.Characters.Latin_1.LF then
            declare
               Line_End : Natural := I - 1;
            begin
               if Line_End >= Line_Start
                 and then Text (Line_End) = Ada.Characters.Latin_1.CR
               then
                  Line_End := Line_End - 1;
               end if;

               if Line_End >= Line_Start then
                  declare
                     Trimmed : constant String := Ada.Strings.Fixed.Trim
                       (Editor.Ada_Syntax_Core.Strip_Comment_Safely (Text (Line_Start .. Line_End)), Ada.Strings.Both);
                  begin
                     if Looks_Like_Ada_Line (Trimmed) then
                        return True;
                     end if;
                  end;
               end if;
            end;
            Line_Start := I + 1;
         end if;
      end loop;

      if Line_Start <= Text'Last then
         declare
            Line_End : Natural := Text'Last;
         begin
            if Text (Line_End) = Ada.Characters.Latin_1.CR then
               Line_End := Line_End - 1;
            end if;

            if Line_End >= Line_Start then
               declare
                  Trimmed : constant String := Ada.Strings.Fixed.Trim
                    (Editor.Ada_Syntax_Core.Strip_Comment_Safely (Text (Line_Start .. Line_End)), Ada.Strings.Both);
               begin
                  return Looks_Like_Ada_Line (Trimmed);
               end;
            end if;
         end;
      end if;

      return False;
   end Looks_Like_Ada_Buffer;

   function Is_Name_Character
     (C         : Character;
      Allow_Dot : Boolean) return Boolean
   is
   begin
      return Is_Word_Char (C) or else (Allow_Dot and then C = '.');
   end Is_Name_Character;

   function Read_Name
     (Text      : String;
      Start     : Positive;
      Allow_Dot : Boolean) return String
   is
      I : Natural := Start;
      J : Natural;
   begin
      while I <= Text'Last
        and then (Text (I) = ' ' or else Text (I) = Ada.Characters.Latin_1.HT)
      loop
         I := I + 1;
      end loop;

      if I > Text'Last
        or else not ((Text (I) >= 'A' and then Text (I) <= 'Z')
                     or else (Text (I) >= 'a' and then Text (I) <= 'z'))
      then
         return "";
      end if;

      J := I;
      while J <= Text'Last and then Is_Name_Character (Text (J), Allow_Dot) loop
         J := J + 1;
      end loop;

      return Text (I .. J - 1);
   end Read_Name;

   function Read_Function_Name
     (Text      : String;
      Start     : Positive;
      Allow_Dot : Boolean) return String
   is
      I : Natural := Start;
      J : Natural;
   begin
      while I <= Text'Last
        and then (Text (I) = ' ' or else Text (I) = Ada.Characters.Latin_1.HT)
      loop
         I := I + 1;
      end loop;

      if I <= Text'Last and then Text (I) = '"' then
         J := I + 1;
         while J <= Text'Last and then Text (J) /= '"' loop
            J := J + 1;
         end loop;

         if J <= Text'Last and then J > I + 1 then
            return Text (I .. J);
         end if;

         return "";
      end if;

      return Read_Name (Text, Start, Allow_Dot);
   end Read_Function_Name;

   function Has_Code_Character
     (Lower_Line : String;
      Target     : Character) return Boolean
   is
      Code : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Lower_Line);
   begin
      for I in Code'Range loop
         if Code (I) = Target then
            return True;
         end if;
      end loop;

      return False;
   end Has_Code_Character;

   function Has_Token_Is (Lower_Line : String) return Boolean
   is
   begin
      return Has_Token (Lower_Line, "is");
   end Has_Token_Is;

   function Has_Token
     (Lower_Line : String;
      Token      : String) return Boolean
   is
      Code : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Lower_Line);
      I    : Natural := Code'First;
   begin
      if Token'Length = 0 then
         return False;
      end if;

      while I <= Code'Last loop
         if I + Token'Length - 1 <= Code'Last
           and then Code (I .. I + Token'Length - 1) = Token
           and then (I = Code'First or else not Is_Word_Char (Code (I - 1)))
           and then (I + Token'Length > Code'Last
                     or else not Is_Word_Char (Code (I + Token'Length)))
         then
            return True;
         else
            I := I + 1;
         end if;
      end loop;

      return False;
   end Has_Token;

   function Has_Is_Followed_By
     (Lower_Line : String;
      Token      : String) return Boolean
   is
      Code : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Lower_Line);
      I    : Natural := Code'First;
      J    : Natural;
   begin
      if Token'Length = 0 then
         return False;
      end if;

      while I <= Code'Last loop
         if I + 1 <= Code'Last
           and then Code (I) = 'i'
           and then Code (I + 1) = 's'
           and then (I = Code'First or else not Is_Word_Char (Code (I - 1)))
           and then (I + 2 > Code'Last or else not Is_Word_Char (Code (I + 2)))
         then
            J := I + 2;
            while J <= Code'Last
              and then (Code (J) = ' ' or else Code (J) = Ada.Characters.Latin_1.HT)
            loop
               J := J + 1;
            end loop;

            if J + Token'Length - 1 <= Code'Last
              and then Code (J .. J + Token'Length - 1) = Token
              and then (J = Code'First or else not Is_Word_Char (Code (J - 1)))
              and then (J + Token'Length > Code'Last
                        or else not Is_Word_Char (Code (J + Token'Length)))
            then
               return True;
            end if;
            I := I + 1;
         else
            I := I + 1;
         end if;
      end loop;

      return False;
   end Has_Is_Followed_By;

   function Has_Renames (Lower_Line : String) return Boolean
   is
   begin
      return Has_Token (Lower_Line, "renames");
   end Has_Renames;

   function Has_Is_Followed_By_Open_Paren (Lower_Line : String) return Boolean
   is
      Code : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Lower_Line);
      I    : Natural := Code'First;
      J    : Natural;
   begin
      while I <= Code'Last loop
         if I + 1 <= Code'Last
           and then Code (I) = 'i'
           and then Code (I + 1) = 's'
           and then (I = Code'First or else not Is_Word_Char (Code (I - 1)))
           and then (I + 2 > Code'Last or else not Is_Word_Char (Code (I + 2)))
         then
            J := I + 2;
            while J <= Code'Last
              and then (Code (J) = ' ' or else Code (J) = Ada.Characters.Latin_1.HT)
            loop
               J := J + 1;
            end loop;

            return J <= Code'Last and then Code (J) = '(';
         else
            I := I + 1;
         end if;
      end loop;

      return False;
   end Has_Is_Followed_By_Open_Paren;

   function Looks_Like_Expression_Function (Lower_Line : String) return Boolean
   is
   begin
      return Has_Is_Followed_By_Open_Paren (Lower_Line)
        and then Has_Code_Character (Lower_Line, ';');
   end Looks_Like_Expression_Function;

   function Looks_Like_Enumeration_Type_Line (Lower_Line : String) return Boolean
   is
      Open_Paren : Natural := 0;
   begin
      if not Starts_With_Word (Lower_Line, "type")
        or else not Has_Token_Is (Lower_Line)
        or else Has_Token (Lower_Line, "record")
        or else Has_Token (Lower_Line, "array")
        or else Has_Token (Lower_Line, "access")
        or else Has_Token (Lower_Line, "range")
        or else Has_Token (Lower_Line, "delta")
        or else Has_Token (Lower_Line, "digits")
        or else Has_Token (Lower_Line, "private")
        or else Has_Token (Lower_Line, "new")
      then
         return False;
      end if;

      for I in Lower_Line'Range loop
         if Lower_Line (I) = '(' then
            Open_Paren := I;
            exit;
         elsif Lower_Line (I) = ';' then
            return False;
         end if;
      end loop;

      return Open_Paren /= 0;
   end Looks_Like_Enumeration_Type_Line;

   function Declaration_Header_Ends (Lower_Line : String) return Boolean
   is
   begin
      return Has_Code_Character (Lower_Line, ';')
        or else Has_Token_Is (Lower_Line);
   end Declaration_Header_Ends;

   function Header_Starts_With_Function (Header : String) return Boolean
   is
      Normalized : constant String := Normalize_Structure_Line (Header);
   begin
      return Starts_With_Word (Normalized, "function")
        or else Starts_With (Normalized, "with function");
   end Header_Starts_With_Function;

   function Header_Starts_With_Procedure (Header : String) return Boolean
   is
      Normalized : constant String := Normalize_Structure_Line (Header);
   begin
      return Starts_With_Word (Normalized, "procedure")
        or else Starts_With (Normalized, "with procedure");
   end Header_Starts_With_Procedure;

   function Header_Is_Subprogram_Body (Header : String) return Boolean
   is
   begin
      return Has_Token_Is (Header)
        and then (not Has_Code_Character (Header, ';')
                  or else Has_Is_Followed_By (Header, "separate")
                  or else Has_Is_Followed_By (Header, "null"))
        and then not Has_Is_Followed_By (Header, "new")
        and then not Has_Renames (Header);
   end Header_Is_Subprogram_Body;

   function Is_Code_Line_Open (Lower_Line : String) return Boolean
   is
   begin
      if Lower_Line'Length = 0 then
         return False;
      end if;

      return Declaration_Opens_Block (Lower_Line)
        or else (Starts_With_Word (Lower_Line, "type")
                 and then Has_Token (Lower_Line, "record")
                 and then not Starts_With_Keyword (Lower_Line, "end record"))
        or else (Starts_With_Word (Lower_Line, "if")
                 and then Has_Token (Lower_Line, "then"))
        or else (Starts_With_Word (Lower_Line, "case")
                 and then Has_Token (Lower_Line, "is"))
        or else Starts_With_Word (Lower_Line, "loop")
        or else ((Starts_With_Word (Lower_Line, "for")
                  or else Starts_With_Word (Lower_Line, "while"))
                 and then Has_Token (Lower_Line, "loop"))
        or else Starts_With_Word (Lower_Line, "declare")
        or else Starts_With_Word (Lower_Line, "select")
        or else (Starts_With_Word (Lower_Line, "accept")
                 and then Has_Token (Lower_Line, "do"))
        or else (Starts_With_Word (Lower_Line, "entry")
                 and then Has_Token_Is (Lower_Line));
   end Is_Code_Line_Open;

   function Open_Line_Needs_Body_Begin (Lower_Line : String) return Boolean
   is
   begin
      if Starts_With_Word (Lower_Line, "declare") then
         return True;
      elsif Starts_With_Phrase (Lower_Line, "package body ")
        or else Starts_With_Phrase (Lower_Line, "task body ")
        or else Starts_With_Phrase (Lower_Line, "protected body ")
        or else Starts_With_Word (Lower_Line, "entry")
      then
         return True;
      elsif (Starts_With_Word (Lower_Line, "procedure")
             or else Starts_With_Word (Lower_Line, "function"))
        and then Has_Token_Is (Lower_Line)
        and then not Has_Is_Followed_By (Lower_Line, "new")
        and then not Has_Is_Followed_By (Lower_Line, "separate")
      then
         return True;
      else
         return False;
      end if;
   end Open_Line_Needs_Body_Begin;

   function Declaration_Header_Starts_Construct
     (Lower_Line : String) return Boolean
   is
   begin
      if Lower_Line'Length = 0
        or else Starts_With_Word (Lower_Line, "end")
        or else Has_Token_Is (Lower_Line)
        or else Has_Code_Character (Lower_Line, ';')
      then
         return False;
      end if;

      return Starts_With_Word (Lower_Line, "package")
        or else Starts_With_Subprogram_Keyword (Lower_Line)
        or else Starts_With_Word (Lower_Line, "task")
        or else Starts_With_Word (Lower_Line, "protected")
        or else Starts_With_Word (Lower_Line, "declare")
        or else Starts_With_Word (Lower_Line, "entry");
   end Declaration_Header_Starts_Construct;

   function Header_Start_Needs_Body_Begin (Lower_Line : String) return Boolean
   is
   begin
      return Starts_With_Phrase (Lower_Line, "package body ")
        or else Starts_With_Subprogram_Keyword (Lower_Line)
        or else Starts_With_Phrase (Lower_Line, "task body ")
        or else Starts_With_Phrase (Lower_Line, "protected body ")
        or else Starts_With_Word (Lower_Line, "declare")
        or else Starts_With_Word (Lower_Line, "entry");
   end Header_Start_Needs_Body_Begin;

   function Is_Code_Line_Inline_Balanced_Open
     (Lower_Line : String) return Boolean
   is
   begin
      if Lower_Line'Length = 0
        or else Starts_With_Word (Lower_Line, "end")
        or else not Has_Code_Character (Lower_Line, ';')
        or else not Has_Token (Lower_Line, "end")
      then
         return False;
      end if;

      if Starts_With_Word (Lower_Line, "if")
        and then Has_Token (Lower_Line, "then")
        and then Has_Token (Lower_Line, "if")
      then
         return True;
      elsif Starts_With_Word (Lower_Line, "case")
        and then Has_Token (Lower_Line, "is")
        and then Has_Token (Lower_Line, "case")
      then
         return True;
      elsif (Starts_With_Word (Lower_Line, "loop")
             or else ((Starts_With_Word (Lower_Line, "for")
                       or else Starts_With_Word (Lower_Line, "while"))
                      and then Has_Token (Lower_Line, "loop")))
        and then Has_Token (Lower_Line, "loop")
      then
         return True;
      elsif Starts_With_Word (Lower_Line, "declare")
        and then Has_Token (Lower_Line, "begin")
      then
         return True;
      elsif Starts_With_Word (Lower_Line, "select")
        and then Has_Token (Lower_Line, "select")
      then
         return True;
      elsif Declaration_Opens_Block (Lower_Line)
        and then Open_Line_Needs_Body_Begin (Lower_Line)
        and then Has_Token (Lower_Line, "begin")
      then
         return True;
      else
         return False;
      end if;
   end Is_Code_Line_Inline_Balanced_Open;

   function Declaration_Waits_For_Record_End
     (Lower_Line : String;
      Kind       : Editor.Outline.Outline_Item_Kind) return Boolean
   is
   begin
      return Kind = Editor.Outline.Outline_Type
        and then Starts_With_Word (Lower_Line, "type")
        and then Has_Token_Is (Lower_Line)
        and then not Has_Code_Character (Lower_Line, ';')
        and then not Has_Token (Lower_Line, "record")
        and then not Has_Token (Lower_Line, "private")
        and then not Has_Token (Lower_Line, "access")
        and then not Has_Token (Lower_Line, "array")
        and then not Has_Token (Lower_Line, "range")
        and then not Has_Code_Character (Lower_Line, '(');
   end Declaration_Waits_For_Record_End;

   function Declaration_Waits_For_Instantiation_End
     (Lower_Line : String;
      Kind       : Editor.Outline.Outline_Item_Kind) return Boolean
   is
   begin
      return (Kind = Editor.Outline.Outline_Package
              or else Kind = Editor.Outline.Outline_Procedure
              or else Kind = Editor.Outline.Outline_Function)
        and then Has_Is_Followed_By (Lower_Line, "new")
        and then not Has_Code_Character (Lower_Line, ';');
   end Declaration_Waits_For_Instantiation_End;

   function Pending_Declaration_Ends_With_Is (Lower_Line : String) return Boolean
   is
   begin
      return Lower_Line = "is" or else Ends_With (Lower_Line, " is");
   end Pending_Declaration_Ends_With_Is;

   function Declaration_Could_Be_Split_Instantiation
     (Lower_Line : String;
      Kind       : Editor.Outline.Outline_Item_Kind) return Boolean
   is
   begin
      return (Kind = Editor.Outline.Outline_Package
              or else Kind = Editor.Outline.Outline_Procedure
              or else Kind = Editor.Outline.Outline_Function)
        and then Pending_Declaration_Ends_With_Is (Lower_Line)
        and then not Has_Code_Character (Lower_Line, ';')
        and then not Has_Is_Followed_By (Lower_Line, "new");
   end Declaration_Could_Be_Split_Instantiation;

   function Line_Ends_Record (Lower_Line : String) return Boolean
   is
   begin
      return Starts_With_Keyword (Lower_Line, "end record")
        and then Has_Code_Character (Lower_Line, ';');
   end Line_Ends_Record;

   function Pending_Type_Record_Still_Open
     (Combined_Lower : String;
      Lower_Line     : String;
      Pending_Kind   : Editor.Outline.Outline_Item_Kind) return Boolean
   is
   begin
      return Pending_Kind = Editor.Outline.Outline_Type
        and then Has_Token (Combined_Lower, "record")
        and then not Line_Ends_Record (Lower_Line);
   end Pending_Type_Record_Still_Open;

   function Declaration_Opens_Block (Lower_Line : String) return Boolean
   is
   begin
      return Has_Token_Is (Lower_Line)
        and then not Has_Is_Followed_By (Lower_Line, "abstract")
        and then not Has_Is_Followed_By (Lower_Line, "null")
        and then not Has_Is_Followed_By (Lower_Line, "new")
        and then not Has_Code_Character (Lower_Line, ';')
        and then not Looks_Like_Expression_Function (Lower_Line)
        and then not Has_Renames (Lower_Line);
   end Declaration_Opens_Block;

   function Is_Generic_Formal_Line (Lower_Line : String) return Boolean
   is
   begin
      return Starts_With_Word (Lower_Line, "type")
        or else Starts_With_Word (Lower_Line, "with")
        or else Starts_With_Word (Lower_Line, "use")
        or else Starts_With_Word (Lower_Line, "pragma")
        or else Starts_With_Word (Lower_Line, "private")
        or else Starts_With_Phrase (Lower_Line, "limited private")
        or else Starts_With_Word (Lower_Line, "range")
        or else Starts_With_Word (Lower_Line, "digits")
        or else Starts_With_Word (Lower_Line, "delta")
        or else Starts_With (Lower_Line, "(")
        or else Ada.Strings.Fixed.Index (Lower_Line, "<>") /= 0
        or else Ada.Strings.Fixed.Index (Lower_Line, ":") /= 0;
   end Is_Generic_Formal_Line;

   function Strip_Overriding_Prefix (Line : String) return String
   is
   begin
      if Starts_With_Phrase (Line, "not overriding ")
        and then Line'Length > 15
      then
         return Line (Line'First + 15 .. Line'Last);
      elsif Starts_With_Phrase (Line, "overriding ")
        and then Line'Length > 11
      then
         return Line (Line'First + 11 .. Line'Last);
      else
         return Line;
      end if;
   end Strip_Overriding_Prefix;

   function Strip_Abstract_Prefix (Line : String) return String
   is
   begin
      if Starts_With_Phrase (Line, "abstract procedure ")
        and then Line'Length > 9
      then
         return Line (Line'First + 9 .. Line'Last);
      elsif Starts_With_Phrase (Line, "abstract function ")
        and then Line'Length > 9
      then
         return Line (Line'First + 9 .. Line'Last);
      else
         return Line;
      end if;
   end Strip_Abstract_Prefix;

   function Strip_Private_Package_Prefix (Line : String) return String
   is
   begin
      if Starts_With_Phrase (Line, "private package ")
        and then Line'Length > 8
      then
         return Line (Line'First + 8 .. Line'Last);
      else
         return Line;
      end if;
   end Strip_Private_Package_Prefix;

   function Append_Marker_Line
     (Result      : in out Editor.Outline_Extractor.Extraction_Result;
      Raw_Line    : String;
      Line_Number : Positive) return Boolean
     renames Editor.Outline_Extractor.Line_Analysis.Structure_Labels.Append_Marker_Line;

   function Leading_Block_Label (Line : String) return String
     renames Editor.Outline_Extractor.Line_Analysis.Structure_Labels.Leading_Block_Label;

   function Strip_Leading_Block_Label (Line : String) return String
     renames Editor.Outline_Extractor.Line_Analysis.Structure_Labels.Strip_Leading_Block_Label;

   function Normalize_Structure_Line (Lower_Line : String) return String
     renames Editor.Outline_Extractor.Line_Analysis.Structure_Labels.Normalize_Structure_Line;

   function Declaration_Form
     (Lower_Line : String;
      Kind       : Editor.Outline.Outline_Item_Kind) return String
     renames Editor.Outline_Extractor.Line_Analysis.Structure_Labels.Declaration_Form;

   function Line_Closes_Block (Lower_Line : String) return Boolean
     renames Editor.Outline_Extractor.Line_Analysis.Structure_Labels.Line_Closes_Block;

   function Detail_Text
     (Line_Number : Positive;
      Form        : String) return String
     renames Editor.Outline_Extractor.Line_Analysis.Structure_Labels.Detail_Text;

   function Label_Text
     (Prefix : String;
      Name   : String;
      Form   : String) return String
     renames Editor.Outline_Extractor.Line_Analysis.Structure_Labels.Label_Text;

   procedure Append_Item
     (Result      : in out Editor.Outline_Extractor.Extraction_Result;
      Kind        : Editor.Outline.Outline_Item_Kind;
      Prefix      : String;
      Name        : String;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Form        : String := "")
     renames Editor.Outline_Extractor.Line_Analysis.Structure_Labels.Append_Item;

   procedure Update_Item_Form
     (Result : in out Editor.Outline_Extractor.Extraction_Result;
      Index  : Natural;
      Form   : String)
     renames Editor.Outline_Extractor.Line_Analysis.Structure_Labels.Update_Item_Form;

end Editor.Outline_Extractor.Line_Analysis;
