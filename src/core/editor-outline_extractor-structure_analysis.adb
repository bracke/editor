with Ada.Characters.Latin_1;
with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Outline_Extractor.Detail_Parsing;
with Editor.Outline_Extractor.Line_Analysis;

package body Editor.Outline_Extractor.Structure_Analysis is

   use type Editor.Outline.Outline_Item_Kind;

   function Form_Needs_Body_Begin (Form : String) return Boolean
   is
   begin
      return Form = "body";
   end Form_Needs_Body_Begin;

   function Last_Label_Word (Label : String) return String
   is
      Stop  : Natural := Label'Last;
      Start : Natural := Label'First;
   begin
      if Label'Length = 0 then
         return "";
      end if;

      while Stop >= Label'First
        and then (Label (Stop) = ' ' or else Label (Stop) = Ada.Characters.Latin_1.HT)
      loop
         if Stop = Label'First then
            return "";
         end if;
         Stop := Stop - 1;
      end loop;

      Start := Stop;
      while Start > Label'First
        and then Label (Start - 1) /= ' '
        and then Label (Start - 1) /= Ada.Characters.Latin_1.HT
      loop
         Start := Start - 1;
      end loop;

      return Label (Start .. Stop);
   end Last_Label_Word;

   function Lowercase_Text (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Translate
        (Text, Ada.Strings.Maps.Constants.Lower_Case_Map);
   end Lowercase_Text;

   function Closing_Line_Name (Lower_Line : String) return String
   is
      I     : Natural := Lower_Line'First;
      First : Natural := 0;
      Last  : Natural := 0;
   begin
      if not Editor.Outline_Extractor.Line_Analysis.Starts_With_Word
        (Lower_Line, "end")
      then
         return "";
      end if;

      I := Lower_Line'First + 3;
      while I <= Lower_Line'Last
        and then (Lower_Line (I) = ' ' or else Lower_Line (I) = Ada.Characters.Latin_1.HT)
      loop
         I := I + 1;
      end loop;

      if I > Lower_Line'Last or else Lower_Line (I) = ';' then
         return "";
      end if;

      First := I;
      while I <= Lower_Line'Last
        and then Lower_Line (I) /= ';'
        and then Lower_Line (I) /= ' '
        and then Lower_Line (I) /= Ada.Characters.Latin_1.HT
      loop
         I := I + 1;
      end loop;

      Last := I - 1;
      if Last < First then
         return "";
      end if;

      return Lower_Line (First .. Last);
   end Closing_Line_Name;

   function Closing_Line_Qualifier (Lower_Line : String) return String
   is
      I     : Natural := Lower_Line'First;
      First : Natural := 0;
      Last  : Natural := 0;
   begin
      if not Editor.Outline_Extractor.Line_Analysis.Starts_With_Word
        (Lower_Line, "end")
      then
         return "";
      end if;

      I := Lower_Line'First + 3;
      while I <= Lower_Line'Last
        and then (Lower_Line (I) = ' ' or else Lower_Line (I) = Ada.Characters.Latin_1.HT)
      loop
         I := I + 1;
      end loop;

      while I <= Lower_Line'Last
        and then Lower_Line (I) /= ';'
        and then Lower_Line (I) /= ' '
        and then Lower_Line (I) /= Ada.Characters.Latin_1.HT
      loop
         I := I + 1;
      end loop;

      while I <= Lower_Line'Last
        and then (Lower_Line (I) = ' ' or else Lower_Line (I) = Ada.Characters.Latin_1.HT)
      loop
         I := I + 1;
      end loop;

      if I > Lower_Line'Last or else Lower_Line (I) = ';' then
         return "";
      end if;

      First := I;
      while I <= Lower_Line'Last
        and then Lower_Line (I) /= ';'
        and then Lower_Line (I) /= ' '
        and then Lower_Line (I) /= Ada.Characters.Latin_1.HT
      loop
         I := I + 1;
      end loop;

      Last := I - 1;
      if Last < First then
         return "";
      end if;

      return Lower_Line (First .. Last);
   end Closing_Line_Qualifier;

   function Root_End_Matches
     (Lower_Line             : String;
      Expected_Lowercase     : String;
      Expected_Close_Keyword : String := "") return Boolean
   is
      Name : constant String := Closing_Line_Name (Lower_Line);
   begin
      if Name'Length = 0 then
         return True;
      end if;

      if Expected_Lowercase'Length > 0 and then Name = Expected_Lowercase then
         return True;
      end if;

      if Expected_Close_Keyword'Length > 0
        and then Name = Expected_Close_Keyword
      then
         declare
            Qualifier : constant String := Closing_Line_Qualifier (Lower_Line);
         begin
            return Qualifier'Length = 0
              or else (Expected_Lowercase'Length > 0
                       and then Qualifier = Expected_Lowercase);
         end;
      end if;

      return Expected_Lowercase'Length = 0
        and then Expected_Close_Keyword'Length = 0;
   end Root_End_Matches;

   function Expected_End_Keyword
     (Item : Editor.Outline.Outline_Item;
      Form : String) return String
   is
   begin
      if Form = "record" or else Form = "variant" then
         return "record";
      elsif Item.Kind = Editor.Outline.Outline_Package
        or else Item.Kind = Editor.Outline.Outline_Package_Body
      then
         return "package";
      elsif Item.Kind = Editor.Outline.Outline_Task then
         return "task";
      elsif Item.Kind = Editor.Outline.Outline_Protected then
         return "protected";
      elsif Item.Kind = Editor.Outline.Outline_Procedure then
         return "procedure";
      elsif Item.Kind = Editor.Outline.Outline_Function then
         return "function";
      else
         return "";
      end if;
   end Expected_End_Keyword;

   function Is_Structure_End_Keyword (Name : String) return Boolean
   is
   begin
      return Name = "if"
        or else Name = "case"
        or else Name = "loop"
        or else Name = "record"
        or else Name = "select"
        or else Name = "package"
        or else Name = "procedure"
        or else Name = "function"
        or else Name = "task"
        or else Name = "protected";
   end Is_Structure_End_Keyword;

   function Structure_Close_Keyword_For_Open (Lower_Line : String) return String
   is
   begin
      if Editor.Outline_Extractor.Line_Analysis.Starts_With_Word (Lower_Line, "if") then
         return "if";
      elsif Editor.Outline_Extractor.Line_Analysis.Starts_With_Word (Lower_Line, "case") then
         return "case";
      elsif Editor.Outline_Extractor.Line_Analysis.Starts_With_Word (Lower_Line, "loop")
        or else Editor.Outline_Extractor.Line_Analysis.Starts_With_Word (Lower_Line, "for")
        or else Editor.Outline_Extractor.Line_Analysis.Starts_With_Word (Lower_Line, "while")
      then
         return "loop";
      elsif Editor.Outline_Extractor.Line_Analysis.Starts_With_Word (Lower_Line, "type")
        and then Editor.Outline_Extractor.Line_Analysis.Has_Token (Lower_Line, "record")
      then
         return "record";
      elsif Editor.Outline_Extractor.Line_Analysis.Starts_With_Word (Lower_Line, "select") then
         return "select";
      elsif Editor.Outline_Extractor.Line_Analysis.Starts_With_Word (Lower_Line, "package") then
         return "package";
      elsif Editor.Outline_Extractor.Line_Analysis.Starts_With_Word (Lower_Line, "procedure") then
         return "procedure";
      elsif Editor.Outline_Extractor.Line_Analysis.Starts_With_Word (Lower_Line, "function") then
         return "function";
      elsif Editor.Outline_Extractor.Line_Analysis.Starts_With_Word (Lower_Line, "task") then
         return "task";
      elsif Editor.Outline_Extractor.Line_Analysis.Starts_With_Word (Lower_Line, "protected") then
         return "protected";
      elsif Editor.Outline_Extractor.Line_Analysis.Starts_With_Word (Lower_Line, "entry") then
         return "entry";
      elsif Editor.Outline_Extractor.Line_Analysis.Starts_With_Word (Lower_Line, "accept")
        or else Editor.Outline_Extractor.Line_Analysis.Starts_With_Word (Lower_Line, "entry")
      then
         return "";
      else
         return "";
      end if;
   end Structure_Close_Keyword_For_Open;

   function Structure_Name_For_Open (Lower_Line : String) return String
   is
      Keyword : constant String := Structure_Close_Keyword_For_Open (Lower_Line);
      Start   : Positive := Lower_Line'First;
   begin
      if Editor.Outline_Extractor.Line_Analysis.Starts_With_Word (Lower_Line, "accept") then
         return Editor.Outline_Extractor.Line_Analysis.Read_Name
           (Lower_Line, Lower_Line'First + 6, True);
      elsif Editor.Outline_Extractor.Line_Analysis.Starts_With_Word (Lower_Line, "entry") then
         return Editor.Outline_Extractor.Line_Analysis.Read_Name
           (Lower_Line, Lower_Line'First + 5, True);
      elsif Keyword = ""
        or else Keyword = "if"
        or else Keyword = "case"
        or else Keyword = "loop"
        or else Keyword = "record"
      then
         if Editor.Outline_Extractor.Line_Analysis.Starts_With_Word (Lower_Line, "type") then
            Start := Lower_Line'First + 4;
            return Editor.Outline_Extractor.Line_Analysis.Read_Name
              (Lower_Line, Start, True);
         end if;

         return "";
      end if;

      Start := Lower_Line'First + Keyword'Length;
      if Keyword = "package"
        and then Editor.Outline_Extractor.Line_Analysis.Starts_With_Phrase
          (Lower_Line, "package body ")
      then
         Start := Lower_Line'First + 12;
      elsif Keyword = "task" then
         if Editor.Outline_Extractor.Line_Analysis.Starts_With_Phrase (Lower_Line, "task body ")
         then
            Start := Lower_Line'First + 10;
         elsif Editor.Outline_Extractor.Line_Analysis.Starts_With_Phrase
           (Lower_Line, "task type ")
         then
            Start := Lower_Line'First + 10;
         end if;
      elsif Keyword = "protected" then
         if Editor.Outline_Extractor.Line_Analysis.Starts_With_Phrase
           (Lower_Line, "protected body ")
         then
            Start := Lower_Line'First + 15;
         elsif Editor.Outline_Extractor.Line_Analysis.Starts_With_Phrase
           (Lower_Line, "protected type ")
         then
            Start := Lower_Line'First + 15;
         end if;
      end if;

      if Keyword = "function" then
         return Editor.Outline_Extractor.Line_Analysis.Read_Function_Name
           (Lower_Line, Start, True);
      else
         return Editor.Outline_Extractor.Line_Analysis.Read_Name
           (Lower_Line, Start, True);
      end if;
   end Structure_Name_For_Open;

   function Stack_End_Matches
     (Lower_Line             : String;
      Expected_Close_Keyword : String;
      Expected_Name          : String) return Boolean
   is
      Name : constant String := Closing_Line_Name (Lower_Line);
   begin
      if Expected_Close_Keyword = "if"
        or else Expected_Close_Keyword = "case"
        or else Expected_Close_Keyword = "loop"
        or else Expected_Close_Keyword = "record"
        or else Expected_Close_Keyword = "select"
      then
         if Name /= Expected_Close_Keyword then
            return False;
         elsif Expected_Name'Length > 0 then
            declare
               Qualifier : constant String := Closing_Line_Qualifier (Lower_Line);
            begin
               return Qualifier'Length = 0 or else Qualifier = Expected_Name;
            end;
         else
            return True;
         end if;
      end if;

      if Expected_Close_Keyword'Length = 0
        and then Expected_Name'Length = 0
      then
         return Name'Length = 0;
      end if;

      if Name'Length = 0 or else Name = Expected_Close_Keyword then
         return True;
      elsif Expected_Name'Length > 0 then
         return Name = Expected_Name;
      else
         return not Is_Structure_End_Keyword (Name);
      end if;
   end Stack_End_Matches;

   function Is_Code_Line_Close (Lower_Line : String) return Boolean
   is
   begin
      if not Editor.Outline_Extractor.Line_Analysis.Starts_With_Word (Lower_Line, "end") then
         return False;
      end if;

      return Editor.Outline_Extractor.Line_Analysis.Has_Code_Character (Lower_Line, ';');
   end Is_Code_Line_Close;

   function Item_May_Have_Structure_Range
     (Item : Editor.Outline.Outline_Item) return Boolean
   is
      Detail : constant String := To_String (Item.Detail);
      Form   : constant String :=
        Editor.Outline_Extractor.Detail_Parsing.Primary_Detail_Form (Detail);
   begin
      if Item.Kind = Editor.Outline.Outline_Package_Body
        or else Item.Kind = Editor.Outline.Outline_Task
        or else Item.Kind = Editor.Outline.Outline_Protected
      then
         return Form = "body"
           or else Form = "task"
           or else Form = "protected"
           or else Form = "type";
      elsif Item.Kind = Editor.Outline.Outline_Package then
         return Form = "spec";
      elsif Item.Kind = Editor.Outline.Outline_Procedure
        or else Item.Kind = Editor.Outline.Outline_Function
      then
         return Form = "body";
      elsif Item.Kind = Editor.Outline.Outline_Type then
         return Form = "record" or else Form = "variant";
      else
         return False;
      end if;
   end Item_May_Have_Structure_Range;

end Editor.Outline_Extractor.Structure_Analysis;
