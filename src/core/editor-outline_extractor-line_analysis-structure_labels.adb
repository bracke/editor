with Ada.Characters.Latin_1;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Core;
with Editor.Outline;
with Editor.Outline_Extractor.Line_Analysis;

package body Editor.Outline_Extractor.Line_Analysis.Structure_Labels is

   use type Editor.Outline.Outline_Item_Kind;

   function Leading_Block_Label (Line : String) return String
   is
      Trimmed : constant String := Line_Analysis.Trim_Code_Whitespace (Line);
      I       : Natural := Trimmed'First;
      Name    : constant String := Line_Analysis.Read_Name (Trimmed, Trimmed'First, False);
      Colon   : Natural := 0;
   begin
      if Name'Length = 0 then
         return "";
      end if;

      I := Trimmed'First + Name'Length;
      while I <= Trimmed'Last
        and then (Trimmed (I) = ' ' or else Trimmed (I) = Ada.Characters.Latin_1.HT)
      loop
         I := I + 1;
      end loop;

      if I > Trimmed'Last or else Trimmed (I) /= ':' then
         return "";
      end if;

      Colon := I;
      I := Colon + 1;
      while I <= Trimmed'Last
        and then (Trimmed (I) = ' ' or else Trimmed (I) = Ada.Characters.Latin_1.HT)
      loop
         I := I + 1;
      end loop;

      if I > Trimmed'Last then
         return "";
      end if;

      declare
         Rest : constant String := Trimmed (I .. Trimmed'Last);
      begin
         if Line_Analysis.Starts_With_Word (Rest, "begin")
           or else Line_Analysis.Starts_With_Word (Rest, "declare")
           or else Line_Analysis.Starts_With_Word (Rest, "loop")
           or else Line_Analysis.Starts_With_Word (Rest, "select")
           or else Line_Analysis.Starts_With_Word (Rest, "for")
           or else Line_Analysis.Starts_With_Word (Rest, "while")
         then
            return Name;
         else
            return "";
         end if;
      end;
   end Leading_Block_Label;

   function Strip_Leading_Block_Label (Line : String) return String
   is
      Trimmed : constant String := Line_Analysis.Trim_Code_Whitespace (Line);
      I       : Natural := Trimmed'First;
      Name    : constant String := Line_Analysis.Read_Name (Trimmed, Trimmed'First, False);
   begin
      if Name'Length = 0 or else Leading_Block_Label (Trimmed)'Length = 0 then
         return Line;
      end if;

      I := Trimmed'First + Name'Length;
      while I <= Trimmed'Last
        and then (Trimmed (I) = ' ' or else Trimmed (I) = Ada.Characters.Latin_1.HT)
      loop
         I := I + 1;
      end loop;

      if I <= Trimmed'Last and then Trimmed (I) = ':' then
         I := I + 1;
      end if;

      while I <= Trimmed'Last
        and then (Trimmed (I) = ' ' or else Trimmed (I) = Ada.Characters.Latin_1.HT)
      loop
         I := I + 1;
      end loop;

      if I <= Trimmed'Last then
         return Trimmed (I .. Trimmed'Last);
      else
         return Line;
      end if;
   end Strip_Leading_Block_Label;

   function Normalize_Structure_Line (Lower_Line : String) return String
   is
      Code_Only : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Lower_Line);
      Trimmed   : constant String := Ada.Strings.Fixed.Trim
        (Code_Only, Ada.Strings.Both);
      Stripped  : constant String := Strip_Leading_Block_Label
        (Line_Analysis.Strip_Private_Package_Prefix
           (Line_Analysis.Strip_Abstract_Prefix
              (Line_Analysis.Strip_Overriding_Prefix
                 (Editor.Ada_Syntax_Core.Strip_Separate_Prefix (Trimmed)))));
   begin
      return Line_Analysis.Trim_Code_Whitespace (Stripped);
   end Normalize_Structure_Line;

   function Declaration_Form
     (Lower_Line : String;
      Kind       : Editor.Outline.Outline_Item_Kind) return String
   is
   begin
      if Line_Analysis.Has_Renames (Lower_Line) then
         return "renames";
      elsif Kind = Editor.Outline.Outline_Package_Body then
         return "body";
      elsif Kind = Editor.Outline.Outline_Package then
         if Line_Analysis.Has_Is_Followed_By (Lower_Line, "new") then
            return "instantiation";
         else
            return "spec";
         end if;
      elsif Kind = Editor.Outline.Outline_Procedure
        or else Kind = Editor.Outline.Outline_Function
        or else Kind = Editor.Outline.Outline_Subprogram
      then
         if Kind = Editor.Outline.Outline_Function
           and then Line_Analysis.Looks_Like_Expression_Function (Lower_Line)
         then
            return "expression";
         elsif Line_Analysis.Has_Is_Followed_By (Lower_Line, "new") then
            return "instantiation";
         elsif Kind = Editor.Outline.Outline_Procedure
           and then Line_Analysis.Has_Token_Is (Lower_Line)
           and then (Line_Analysis.Has_Is_Followed_By (Lower_Line, "null")
                     or else Line_Analysis.Has_Is_Followed_By (Lower_Line, "separate"))
         then
            return "body";
         elsif Kind = Editor.Outline.Outline_Function
           and then Line_Analysis.Has_Token_Is (Lower_Line)
           and then Line_Analysis.Has_Is_Followed_By (Lower_Line, "separate")
         then
            return "body";
         elsif Kind = Editor.Outline.Outline_Subprogram then
            return "declaration";
         elsif Line_Analysis.Declaration_Opens_Block (Lower_Line) then
            return "body";
         elsif Line_Analysis.Declaration_Header_Ends (Lower_Line) then
            return "declaration";
         else
            return "pending";
         end if;
      elsif Kind = Editor.Outline.Outline_Task then
         if Line_Analysis.Starts_With_Phrase (Lower_Line, "task body ") then
            return "body";
         elsif Line_Analysis.Starts_With_Phrase (Lower_Line, "task type ") then
            return "type";
         else
            return "task";
         end if;
      elsif Kind = Editor.Outline.Outline_Protected then
         if Line_Analysis.Starts_With_Phrase (Lower_Line, "protected body ") then
            return "body";
         elsif Line_Analysis.Starts_With_Phrase (Lower_Line, "protected type ") then
            return "type";
         else
            return "protected";
         end if;
      elsif Kind = Editor.Outline.Outline_Exception then
         return "exception";
      elsif Kind = Editor.Outline.Outline_Object then
         if Line_Analysis.Has_Token (Lower_Line, "constant") then
            return "constant";
         elsif Line_Analysis.Has_Renames (Lower_Line) then
            return "renames";
         else
            return "object";
         end if;
      elsif Kind = Editor.Outline.Outline_Discriminant then
         return "discriminant";
      elsif Kind = Editor.Outline.Outline_Enum_Literal then
         return "enumeration";
      elsif Kind = Editor.Outline.Outline_Generic_Formal then
         if Line_Analysis.Starts_With_Word (Lower_Line, "type") then
            return "generic formal type";
         elsif Line_Analysis.Starts_With_Phrase (Lower_Line, "with package ") then
            return "generic formal package";
         elsif Line_Analysis.Starts_With_Phrase (Lower_Line, "with procedure ") then
            return "generic formal procedure";
         elsif Line_Analysis.Starts_With_Phrase (Lower_Line, "with function ") then
            return "generic formal function";
         else
            return "generic formal object";
         end if;
      elsif Kind = Editor.Outline.Outline_Type then
         if Line_Analysis.Starts_With_Word (Lower_Line, "subtype") then
            return "subtype";
         elsif Line_Analysis.Has_Token (Lower_Line, "limited")
           and then Line_Analysis.Has_Token (Lower_Line, "private")
         then
            return "limited private";
         elsif Line_Analysis.Has_Token (Lower_Line, "private") then
            return "private";
         elsif Line_Analysis.Has_Token (Lower_Line, "record") then
            return "record";
         elsif Line_Analysis.Looks_Like_Enumeration_Type_Line (Lower_Line) then
            return "enumeration";
         elsif Line_Analysis.Has_Token (Lower_Line, "array") then
            return "array";
         elsif Line_Analysis.Has_Token (Lower_Line, "access") then
            return "access";
         else
            return "type";
         end if;
      else
         return "";
      end if;
   end Declaration_Form;

   function Line_Closes_Block (Lower_Line : String) return Boolean
   is
   begin
      if not Line_Analysis.Starts_With_Word (Lower_Line, "end") then
         return False;
      end if;

      return Lower_Line = "end;"
        or else Line_Analysis.Starts_With_Keyword (Lower_Line, "end package")
        or else Line_Analysis.Starts_With_Keyword (Lower_Line, "end procedure")
        or else Line_Analysis.Starts_With_Keyword (Lower_Line, "end function")
        or else Line_Analysis.Starts_With_Keyword (Lower_Line, "end task")
        or else Line_Analysis.Starts_With_Keyword (Lower_Line, "end protected")
        or else (Line_Analysis.Has_Code_Character (Lower_Line, ';')
                 and then not Line_Analysis.Starts_With_Keyword (Lower_Line, "end if")
                 and then not Line_Analysis.Starts_With_Keyword (Lower_Line, "end loop")
                 and then not Line_Analysis.Starts_With_Keyword (Lower_Line, "end case")
                 and then not Line_Analysis.Starts_With_Keyword (Lower_Line, "end record")
                 and then not Line_Analysis.Starts_With_Keyword (Lower_Line, "end select"));
   end Line_Closes_Block;

   function Detail_Text
     (Line_Number : Positive;
      Form        : String) return String
   is
   begin
      if Form'Length = 0 then
         return "line" & Natural'Image (Line_Number);
      end if;

      return "line" & Natural'Image (Line_Number) & " " & Form;
   end Detail_Text;

   function Label_Text
     (Prefix : String;
      Name   : String;
      Form   : String) return String
   is
   begin
      if Form = "renames" then
         return Prefix & " " & Name & " renames";
      elsif Form = "expression" and then Prefix = "function" then
         return "expression function " & Name;
      elsif Form = "expression" and then Prefix = "generic function" then
         return "generic expression function " & Name;
      elsif Form = "body" and then Prefix = "procedure" then
         return "procedure body " & Name;
      elsif Form = "body" and then Prefix = "generic procedure" then
         return "generic procedure body " & Name;
      elsif Form = "body" and then Prefix = "function" then
         return "function body " & Name;
      elsif Form = "body" and then Prefix = "generic function" then
         return "generic function body " & Name;
      elsif Form = "record" and then Prefix = "type" then
         return "record type " & Name;
      elsif Form = "enumeration" and then Prefix = "type" then
         return "enum type " & Name;
      elsif Form = "array" and then Prefix = "type" then
         return "array type " & Name;
      elsif Form = "access" and then Prefix = "type" then
         return "access type " & Name;
      elsif (Form = "private" or else Form = "limited private")
        and then Prefix = "type"
      then
         return "private type " & Name;
      elsif Form = "body" and then Prefix = "task" then
         return "task body " & Name;
      elsif Form = "type" and then Prefix = "task" then
         return "task type " & Name;
      elsif Form = "body" and then Prefix = "protected" then
         return "protected body " & Name;
      elsif Form = "type" and then Prefix = "protected" then
         return "protected type " & Name;
      else
         return Prefix & " " & Name;
      end if;
   end Label_Text;

   procedure Append_Item
     (Result      : in out Editor.Outline_Extractor.Extraction_Result;
      Kind        : Editor.Outline.Outline_Item_Kind;
      Prefix      : String;
      Name        : String;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Form        : String := "")
   is
      Detail : constant String := Detail_Text (Line_Number, Form);
      Label  : constant String := Label_Text (Prefix, Name, Form);
   begin
      if Name'Length = 0 then
         return;
      end if;

      Result.Items.Append
        (Editor.Outline.Outline_Item'
          (Kind        => Kind,
           Label       => To_Unbounded_String (Label),
           Detail      => To_Unbounded_String (Detail),
           Depth       => Depth,
           Target_Kind => Editor.Outline.Buffer_Position_Target,
           Buffer_Token => Result.Result_Identity.Active_Buffer_Token,
           Line         => Line_Number,
           Column       => Line_Analysis.Declaration_Target_Column (Raw_Line)));
   end Append_Item;

   procedure Update_Item_Form
     (Result : in out Editor.Outline_Extractor.Extraction_Result;
      Index  : Natural;
      Form   : String)
   is
      Item : Editor.Outline.Outline_Item;
      Label : Unbounded_String;
   begin
      if Form'Length = 0
        or else Result.Items.Is_Empty
        or else Index < Result.Items.First_Index
        or else Index > Result.Items.Last_Index
      then
         return;
      end if;

      Item := Result.Items.Element (Index);
      Item.Detail := To_Unbounded_String (Detail_Text (Positive (Item.Line), Form));
      Label := Item.Label;
      declare
         Current : constant String := To_String (Label);
      begin
         if Form = "body" and then Line_Analysis.Starts_With (Current, "generic procedure ") then
            Item.Label := To_Unbounded_String
              ("generic procedure body " &
               Current (Current'First + 18 .. Current'Last));
         elsif Form = "body" and then Line_Analysis.Starts_With (Current, "procedure ") then
            Item.Label := To_Unbounded_String
              ("procedure body " & Current (Current'First + 10 .. Current'Last));
         elsif Form = "body" and then Line_Analysis.Starts_With (Current, "generic function ") then
            Item.Label := To_Unbounded_String
              ("generic function body " &
               Current (Current'First + 17 .. Current'Last));
         elsif Form = "body" and then Line_Analysis.Starts_With (Current, "function ") then
            Item.Label := To_Unbounded_String
              ("function body " & Current (Current'First + 9 .. Current'Last));
         elsif Form = "expression" and then Line_Analysis.Starts_With (Current, "generic function ") then
            Item.Label := To_Unbounded_String
              ("generic expression function " &
               Current (Current'First + 17 .. Current'Last));
         elsif Form = "expression" and then Line_Analysis.Starts_With (Current, "function ") then
            Item.Label := To_Unbounded_String
              ("expression function " & Current (Current'First + 9 .. Current'Last));
         elsif Form = "renames" then
            Item.Label := To_Unbounded_String (Current & " renames");
         elsif Form = "record" and then Line_Analysis.Starts_With (Current, "type ") then
            Item.Label := To_Unbounded_String
              ("record type " & Current (Current'First + 5 .. Current'Last));
         elsif Form = "enumeration" and then Line_Analysis.Starts_With (Current, "type ") then
            Item.Label := To_Unbounded_String
              ("enum type " & Current (Current'First + 5 .. Current'Last));
         elsif Form = "array" and then Line_Analysis.Starts_With (Current, "type ") then
            Item.Label := To_Unbounded_String
              ("array type " & Current (Current'First + 5 .. Current'Last));
         elsif Form = "access" and then Line_Analysis.Starts_With (Current, "type ") then
            Item.Label := To_Unbounded_String
              ("access type " & Current (Current'First + 5 .. Current'Last));
         elsif (Form = "private" or else Form = "limited private")
           and then Line_Analysis.Starts_With (Current, "type ")
         then
            Item.Label := To_Unbounded_String
              ("private type " & Current (Current'First + 5 .. Current'Last));
         elsif Form = "instantiation" and then Line_Analysis.Starts_With (Current, "generic procedure body ") then
            Item.Label := To_Unbounded_String
              ("generic procedure " & Current (Current'First + 23 .. Current'Last));
         elsif Form = "instantiation" and then Line_Analysis.Starts_With (Current, "procedure body ") then
            Item.Label := To_Unbounded_String
              ("procedure " & Current (Current'First + 15 .. Current'Last));
         elsif Form = "instantiation" and then Line_Analysis.Starts_With (Current, "generic function body ") then
            Item.Label := To_Unbounded_String
              ("generic function " & Current (Current'First + 22 .. Current'Last));
         elsif Form = "instantiation" and then Line_Analysis.Starts_With (Current, "function body ") then
            Item.Label := To_Unbounded_String
              ("function " & Current (Current'First + 14 .. Current'Last));
         elsif Form = "subtype" then
            null;
         end if;
      end;
      Result.Items.Replace_Element (Index, Item);
   end Update_Item_Form;

   function Append_Marker_Line
     (Result      : in out Editor.Outline_Extractor.Extraction_Result;
      Raw_Line    : String;
      Line_Number : Positive) return Boolean
   is
      Trimmed : constant String := Ada.Strings.Fixed.Trim (Raw_Line, Ada.Strings.Both);
      Marker  : constant String := "@outline ";
   begin
      if Line_Analysis.Starts_With (Trimmed, Marker) then
         declare
            Label  : constant String := Ada.Strings.Fixed.Trim
              (Trimmed (Trimmed'First + Marker'Length .. Trimmed'Last), Ada.Strings.Both);
            Detail : constant String := "line" & Natural'Image (Line_Number);
         begin
            if Label'Length = 0 then
               return True;
            end if;

            Result.Items.Append
              (Editor.Outline.Outline_Item'
                 (Kind         => Line_Analysis.Kind_For_Label (Label),
                  Label        => To_Unbounded_String (Label),
                  Detail       => To_Unbounded_String (Detail),
                  Depth        => 0,
                  Target_Kind  => Editor.Outline.Buffer_Position_Target,
                  Buffer_Token => Result.Result_Identity.Active_Buffer_Token,
                  Line         => Line_Number,
                  Column       => Line_Analysis.Declaration_Target_Column (Raw_Line)));
            return True;
         end;
      end if;

      return False;
   end Append_Marker_Line;

end Editor.Outline_Extractor.Line_Analysis.Structure_Labels;
