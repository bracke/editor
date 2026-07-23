with Ada.Characters.Latin_1;
with Ada.Containers.Vectors;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Core;
with Editor.Ada_Declaration_Parser;
with Editor.Ada_Language_Model;
with Editor.Outline_Extractor.Detail_Parsing;
with Editor.Outline_Extractor.Line_Analysis; use Editor.Outline_Extractor.Line_Analysis;
with Editor.Outline_Extractor.Range_Analysis;
with Editor.Outline_Extractor.Structure_Analysis;
with Editor.Outline_Extractor.Snapshots;
with Editor.Outline_Extractor.Symbols; use Editor.Outline_Extractor.Symbols;

package body Editor.Outline_Extractor is

   use type Editor.Outline.Outline_Item_Kind;

   package Line_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Unbounded_String);

   type Structure_Stack_Entry is record
      Needs_Body_Begin       : Boolean := False;
      Pending_Header         : Boolean := False;
      Expected_Close_Keyword : Unbounded_String := Null_Unbounded_String;
      Expected_Name          : Unbounded_String := Null_Unbounded_String;
   end record;

   package Structure_Stack_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Structure_Stack_Entry);

   Marker : constant String := "@outline ";

   type Scan_State is record
      Pending_Generic    : Boolean := False;
      In_Declaration     : Boolean := False;
      Pending_Item           : Boolean := False;
      Pending_Item_Index     : Natural := 0;
      Pending_Declaration    : Unbounded_String;
      In_Generic_Formal      : Boolean := False;
      Pending_Separate       : Boolean := False;
      Instantiation_Candidate : Boolean := False;
      Instantiation_Candidate_Index : Natural := 0;
      Separate_Body_Candidate : Boolean := False;
      Separate_Body_Candidate_Index : Natural := 0;
      In_Record_Type         : Boolean := False;
      In_Enumeration_Type    : Boolean := False;
      Depth                  : Natural := 0;
   end record;

   function Make_Snapshot
     (Text : String) return Buffer_Text_Snapshot
     renames Editor.Outline_Extractor.Snapshots.Make_Snapshot;

   function Make_Snapshot
     (Text         : String;
      Buffer_Label : String) return Buffer_Text_Snapshot
     renames Editor.Outline_Extractor.Snapshots.Make_Snapshot;

   function Make_Snapshot
     (Text               : String;
      Active_Buffer_Token  : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Request_Token        : Natural) return Buffer_Text_Snapshot
     renames Editor.Outline_Extractor.Snapshots.Make_Snapshot;

   function Make_Snapshot
     (Text               : String;
      Buffer_Label       : String;
      Active_Buffer_Token  : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Request_Token        : Natural) return Buffer_Text_Snapshot
     renames Editor.Outline_Extractor.Snapshots.Make_Snapshot;

   function Identity
     (Snapshot : Buffer_Text_Snapshot) return Editor.Outline.Outline_Snapshot_Identity
     renames Editor.Outline_Extractor.Snapshots.Identity;

   function Status
     (Result : Extraction_Result) return Extraction_Status
     renames Editor.Outline_Extractor.Snapshots.Status;

   function Failure
     (Result : Extraction_Result) return Extraction_Failure_Kind
     renames Editor.Outline_Extractor.Snapshots.Failure;

   function Item_Count
     (Result : Extraction_Result) return Natural
     renames Editor.Outline_Extractor.Snapshots.Item_Count;

   function Identity
     (Result : Extraction_Result) return Editor.Outline.Outline_Snapshot_Identity
     renames Editor.Outline_Extractor.Snapshots.Identity;

   function Is_Success
     (Result : Extraction_Result) return Boolean
     renames Editor.Outline_Extractor.Snapshots.Is_Success;

   function Fingerprint
     (Result : Extraction_Result) return Natural
     renames Editor.Outline_Extractor.Snapshots.Fingerprint;


   procedure Apply_Pending_Generic
     (State       : in out Scan_State;
      Prefix      : in out Unbounded_String)
   is
   begin
      if State.Pending_Generic then
         Prefix := To_Unbounded_String ("generic " & To_String (Prefix));
         State.Pending_Generic := False;
         State.In_Generic_Formal := False;
      end if;
   end Apply_Pending_Generic;



   function Looks_Like_Record_Field_Line (Lower_Line : String) return Boolean
     renames Editor.Outline_Extractor.Line_Analysis.Looks_Like_Record_Field_Line;

   function Record_Field_Name (Line : String) return String
     renames Editor.Outline_Extractor.Line_Analysis.Record_Field_Name;

   procedure Append_Record_Field_Line
     (Result      : in out Extraction_Result;
      State       : Scan_State;
      Raw_Line    : String;
      Line_Number : Positive;
      Lower_Line  : String;
      Trimmed     : String)
   is
   begin
      Editor.Outline_Extractor.Line_Analysis.Append_Record_Field_Line
        (Result, State.In_Record_Type, State.Depth, Raw_Line, Line_Number,
         Lower_Line, Trimmed);
   end Append_Record_Field_Line;

   function First_Colon (Line : String) return Natural
     renames Editor.Outline_Extractor.Line_Analysis.First_Colon;

   function Declaration_Name_List_Before_Colon (Line : String) return String
     renames Editor.Outline_Extractor.Line_Analysis.Declaration_Name_List_Before_Colon;

   function Generic_Formal_Prefix (Lower_Line : String) return String
     renames Editor.Outline_Extractor.Line_Analysis.Generic_Formal_Prefix;

   function Generic_Formal_Name (Trimmed : String; Lower_Line : String) return String
     renames Editor.Outline_Extractor.Line_Analysis.Generic_Formal_Name;

   procedure Append_Generic_Formal_Line
     (Result      : in out Extraction_Result;
      State       : Scan_State;
      Raw_Line    : String;
      Line_Number : Positive;
      Lower_Line  : String;
      Trimmed     : String)
   is
   begin
      Editor.Outline_Extractor.Line_Analysis.Append_Generic_Formal_Line
        (Result, State.Depth, Raw_Line, Line_Number, Lower_Line, Trimmed);
   end Append_Generic_Formal_Line;

   function Looks_Like_Exception_Declaration (Lower_Line : String) return Boolean
     renames Editor.Outline_Extractor.Line_Analysis.Looks_Like_Exception_Declaration;

   function Looks_Like_Constant_Declaration (Lower_Line : String) return Boolean
     renames Editor.Outline_Extractor.Line_Analysis.Looks_Like_Constant_Declaration;

   function Looks_Like_Object_Declaration (Lower_Line : String) return Boolean
     renames Editor.Outline_Extractor.Line_Analysis.Looks_Like_Object_Declaration;

   function First_Enumeration_List_Column (Line : String) return Natural
     renames Editor.Outline_Extractor.Line_Analysis.First_Enumeration_List_Column;

   procedure Append_Discriminants_From_Type_Line
     (Result      : in out Extraction_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural)
   is
   begin
      Editor.Outline_Extractor.Line_Analysis.Append_Discriminants_From_Type_Line
        (Result, Raw_Line, Line_Number, Depth);
   end Append_Discriminants_From_Type_Line;

   procedure Append_Enumeration_Literals_From_Line
     (Result      : in out Extraction_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Start_At    : Natural)
   is
   begin
      Editor.Outline_Extractor.Line_Analysis.Append_Enumeration_Literals_From_Line
        (Result, Raw_Line, Line_Number, Depth, Start_At);
   end Append_Enumeration_Literals_From_Line;

   procedure Append_Marker_Source_Line
     (Result      : in out Extraction_Result;
      Raw_Line    : String;
      Line_Number : Positive)
   is
   begin
      Editor.Outline_Extractor.Line_Analysis.Append_Marker_Source_Line
        (Result, Raw_Line, Line_Number);
   end Append_Marker_Source_Line;

   procedure Append_Marker_Lines
     (Result : in out Extraction_Result;
      Text   : String)
   is
   begin
      Editor.Outline_Extractor.Line_Analysis.Append_Marker_Lines
        (Result, Text);
   end Append_Marker_Lines;


   function Numeric_Suffix (Text : String; Start : Positive) return Natural
     renames Editor.Outline_Extractor.Detail_Parsing.Numeric_Suffix;

   function Detail_Start_Line (Detail : String) return Natural
     renames Editor.Outline_Extractor.Detail_Parsing.Detail_Start_Line;

   function Detail_End_Line (Detail : String) return Natural
     renames Editor.Outline_Extractor.Detail_Parsing.Detail_End_Line;

   function End_Line_Detail
     (Start_Line : Natural;
      End_Line   : Natural;
      Form       : String) return String
     renames Editor.Outline_Extractor.Detail_Parsing.End_Line_Detail;

   function Detail_Form (Detail : String) return String
     renames Editor.Outline_Extractor.Detail_Parsing.Detail_Form;

   function Primary_Detail_Form (Detail : String) return String
     renames Editor.Outline_Extractor.Detail_Parsing.Primary_Detail_Form;

   procedure Build_Line_Vector
     (Text  : String;
      Lines : in out Line_Vectors.Vector)
   is
      Line_Start  : Positive := Text'First;
      Line_Number : Natural := 1;
   begin
      Lines.Clear;
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
                  Lines.Append (To_Unbounded_String (Text (Line_Start .. Line_End)));
               else
                  Lines.Append (Null_Unbounded_String);
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
               Lines.Append (To_Unbounded_String (Text (Line_Start .. Line_End)));
            else
               Lines.Append (Null_Unbounded_String);
            end if;
         end;
      end if;
   end Build_Line_Vector;

   function Code_Lower_Line
     (Lines       : Line_Vectors.Vector;
      Line_Number : Natural) return String
   is
   begin
      if Line_Number = 0
        or else Lines.Is_Empty
        or else Line_Number > Natural (Lines.Length)
      then
         return "";
      end if;

      declare
         Raw     : constant String := To_String (Lines (Line_Number - 1));
         Clean   : constant String := Editor.Ada_Syntax_Core.Strip_Comment_Safely (Raw);
         Code    : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Clean);
         Trimmed : constant String := Trim_Code_Whitespace (Code);
      begin
         return Ada.Strings.Fixed.Translate
           (Trimmed, Ada.Strings.Maps.Constants.Lower_Case_Map);
      end;
   end Code_Lower_Line;

   function Header_Text_From
     (Lines      : Line_Vectors.Vector;
      Start_Line : Natural) return String
   is
      Combined : Unbounded_String;
      Limit    : constant Natural :=
        Natural'Min (Natural (Lines.Length), Start_Line + 8);
   begin
      if Start_Line = 0 or else Lines.Is_Empty then
         return "";
      end if;

      for L in Start_Line .. Limit loop
         declare
            Lower : constant String := Code_Lower_Line (Lines, L);
         begin
            if Lower'Length > 0 then
               if Length (Combined) > 0 then
                  Append (Combined, " ");
               end if;
               Append (Combined, Lower);

               if Has_Code_Character (Lower, ';')
                 or else Has_Token_Is (Lower)
                 or else Starts_With_Word (Lower, "begin")
               then
                  exit;
               end if;
            end if;
         end;
      end loop;

      return To_String (Combined);
   end Header_Text_From;

   function Instantiation_Target_Text_From
     (Lines      : Line_Vectors.Vector;
      Start_Line : Natural) return String
   is
      Combined : Unbounded_String;
      Limit    : constant Natural :=
        Natural'Min (Natural (Lines.Length), Start_Line + 8);
   begin
      if Start_Line = 0 or else Lines.Is_Empty then
         return "";
      end if;

      for L in Start_Line .. Limit loop
         declare
            Raw     : constant String := To_String (Lines (L - 1));
            Clean   : constant String := Editor.Ada_Syntax_Core.Strip_Comment_Safely (Raw);
            Code    : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Clean);
            Trimmed : constant String := Trim_Code_Whitespace (Code);
         begin
            if Trimmed'Length > 0 then
               if Length (Combined) > 0 then
                  Append (Combined, " ");
               end if;
               Append (Combined, Trimmed);

               if Has_Code_Character (Trimmed, ';') then
                  exit;
               end if;
            end if;
         end;
      end loop;

      declare
         Header : constant String := To_String (Combined);
         Lower  : constant String := Ada.Strings.Fixed.Translate
           (Header, Ada.Strings.Maps.Constants.Lower_Case_Map);
         Pos    : constant Natural := Ada.Strings.Fixed.Index (Lower, "is new ");
      begin
         if Pos = 0 then
            return "";
         end if;

         declare
            Start : Natural := Pos + 7;
            Stop  : Natural := Header'Last;
         begin
            while Start <= Header'Last
              and then (Header (Start) = ' '
                        or else Header (Start) = Ada.Characters.Latin_1.HT)
            loop
               Start := Start + 1;
            end loop;

            for I in Start .. Header'Last loop
               if Header (I) = ';' or else Header (I) = '(' then
                  Stop := I - 1;
                  exit;
               end if;
            end loop;

            while Stop >= Start
              and then (Header (Stop) = ' '
                        or else Header (Stop) = Ada.Characters.Latin_1.HT)
            loop
               if Stop = Start then
                  return "";
               end if;
               Stop := Stop - 1;
            end loop;

            if Start > Stop then
               return "";
            end if;
            return Header (Start .. Stop);
         end;
      end;
   end Instantiation_Target_Text_From;

   function Header_Is_Expression_Function
     (Lines      : Line_Vectors.Vector;
      Start_Line : Natural) return Boolean
   is
      Seen_Is : Boolean := False;
      Limit   : constant Natural :=
        Natural'Min (Natural (Lines.Length), Start_Line + 8);
   begin
      if Start_Line = 0 or else Lines.Is_Empty then
         return False;
      end if;

      for L in Start_Line .. Limit loop
         declare
            Lower : constant String := Code_Lower_Line (Lines, L);
         begin
            if Lower'Length = 0 then
               null;
            elsif Starts_With_Word (Lower, "begin") then
               return False;
            elsif not Seen_Is then
               if Has_Is_Followed_By (Lower, "new") then
                  return False;
               end if;

               if Has_Is_Followed_By_Open_Paren (Lower) then
                  return True;
               elsif Has_Token_Is (Lower) then
                  Seen_Is := True;
               elsif Has_Code_Character (Lower, ';') then
                  return False;
               end if;
            else
               return Starts_With (Lower, "(");
            end if;
         end;
      end loop;

      return False;
   end Header_Is_Expression_Function;

   function Header_Is_Instantiation
     (Lines      : Line_Vectors.Vector;
      Start_Line : Natural) return Boolean
   is
      Seen_Is : Boolean := False;
      Limit   : constant Natural :=
        Natural'Min (Natural (Lines.Length), Start_Line + 8);
   begin
      if Start_Line = 0 or else Lines.Is_Empty then
         return False;
      end if;

      for L in Start_Line .. Limit loop
         declare
            Lower : constant String := Code_Lower_Line (Lines, L);
         begin
            if Lower'Length = 0 then
               null;
            elsif Seen_Is then
               return Starts_With_Word (Lower, "new");
            elsif Has_Is_Followed_By (Lower, "new") then
               return True;
            else
               if Has_Token_Is (Lower) then
                  Seen_Is := True;
               elsif Has_Code_Character (Lower, ';') then
                  return False;
               end if;
            end if;
         end;
      end loop;

      return False;
   end Header_Is_Instantiation;

   function Header_Is_Body_Stub
     (Lines      : Line_Vectors.Vector;
      Start_Line : Natural) return Boolean
   is
      Seen_Is : Boolean := False;
      Limit   : constant Natural :=
        Natural'Min (Natural (Lines.Length), Start_Line + 4);
   begin
      if Start_Line = 0 or else Lines.Is_Empty then
         return False;
      end if;

      for L in Start_Line .. Limit loop
         declare
            Lower : constant String := Code_Lower_Line (Lines, L);
         begin
            if Lower'Length = 0 then
               null;
            elsif Seen_Is then
               return Starts_With_Word (Lower, "separate");
            elsif Has_Is_Followed_By (Lower, "separate") then
               return True;
            elsif Has_Token_Is (Lower) then
               Seen_Is := True;
            elsif Has_Code_Character (Lower, ';') then
               return False;
            end if;
         end;
      end loop;

      return False;
   end Header_Is_Body_Stub;

   function Is_Separate_Subunit_Declaration
     (Lines      : Line_Vectors.Vector;
      Start_Line : Natural) return Boolean
   is
      Current  : constant String := Code_Lower_Line (Lines, Start_Line);
      Previous : constant String :=
        (if Start_Line > 1 then Code_Lower_Line (Lines, Start_Line - 1) else "");
   begin
      return Starts_With_Word (Current, "separate")
        or else Starts_With_Word (Previous, "separate");
   end Is_Separate_Subunit_Declaration;

   procedure Decrement_Subsequent_Nested_Depths
     (Result      : in out Extraction_Result;
      After_Index : Natural;
      Base_Depth  : Natural)
   is
   begin
      if Result.Items.Is_Empty or else After_Index >= Result.Items.Last_Index then
         return;
      end if;

      for J in After_Index + 1 .. Result.Items.Last_Index loop
         declare
            Later : Editor.Outline.Outline_Item := Result.Items.Element (J);
         begin
            if Later.Depth > Base_Depth then
               Later.Depth := Later.Depth - 1;
               Result.Items.Replace_Element (J, Later);
            end if;
         end;
      end loop;
   end Decrement_Subsequent_Nested_Depths;

   function Replace_Label_Prefix
     (Label      : String;
      Old_Prefix : String;
      New_Prefix : String) return String
   is
   begin
      if Starts_With (Label, Old_Prefix)
        and then Label'Length >= Old_Prefix'Length
      then
         return New_Prefix &
           Label (Label'First + Old_Prefix'Length .. Label'Last);
      end if;

      return Label;
   end Replace_Label_Prefix;

   function Has_Projected_Formal_Subprogram_Row
     (Result      : Extraction_Result;
      Line_Number : Natural) return Boolean
   is
   begin
      for Item of Result.Items loop
         if Item.Kind = Editor.Outline.Outline_Generic_Formal
           and then Item.Line = Line_Number
         then
            declare
               Label : constant String := To_String (Item.Label);
            begin
               if Starts_With (Label, "formal function ")
                 or else Starts_With (Label, "formal procedure ")
               then
                  return True;
               end if;
            end;
         end if;
      end loop;

      return False;
   end Has_Projected_Formal_Subprogram_Row;

   function Has_Projected_Formal_Type_Row
     (Result      : Extraction_Result;
      Line_Number : Natural) return Boolean
   is
   begin
      for Item of Result.Items loop
         if Item.Kind = Editor.Outline.Outline_Generic_Formal
           and then Item.Line = Line_Number
           and then Ada.Strings.Fixed.Index
             (To_String (Item.Detail), "generic formal type") /= 0
         then
            return True;
         end if;
      end loop;

      return False;
   end Has_Projected_Formal_Type_Row;

   procedure Insert_Source_Ordered
     (Result : in out Extraction_Result;
      Item   : Editor.Outline.Outline_Item)
   is
   begin
      if Result.Items.Is_Empty then
         Result.Items.Append (Item);
         return;
      end if;

      for I in Result.Items.First_Index .. Result.Items.Last_Index loop
         declare
            Existing : constant Editor.Outline.Outline_Item :=
              Result.Items.Element (I);
         begin
            if Existing.Line > Item.Line
              or else (Existing.Line = Item.Line
                       and then Existing.Column > Item.Column)
            then
               Result.Items.Insert (I, Item);
               return;
            end if;
         end;
      end loop;

      Result.Items.Append (Item);
   end Insert_Source_Ordered;

   function Formal_Subprogram_Source_Name
     (Trimmed : String;
      Raw     : String;
      Prefix  : String) return String
   is
      function After_Phrase (Phrase : String) return String
      is
         Pos : constant Natural :=
           Ada.Strings.Fixed.Index
             (Ada.Strings.Fixed.Translate
                (Trimmed, Ada.Strings.Maps.Constants.Lower_Case_Map),
              Ada.Strings.Fixed.Translate
                (Phrase, Ada.Strings.Maps.Constants.Lower_Case_Map));
         First : Natural;
      begin
         if Pos = 0 then
            return "";
         end if;

         First := Pos + Phrase'Length;
         if First > Trimmed'Last then
            return "";
         end if;

         return Ada.Strings.Fixed.Trim
           (Trimmed (First .. Trimmed'Last), Ada.Strings.Both);
      end After_Phrase;
   begin
      if Prefix = "formal function " then
         declare
            Tail : constant String := After_Phrase ("with function");
            Name : constant String :=
              (if Tail'Length > 0
               then Read_Function_Name (Tail, Tail'First, True)
               else "");
         begin
            if Name'Length > 0 then
               return Name;
            elsif Ada.Strings.Fixed.Index (Raw, "<") /= 0 then
               return """<""";
            end if;
         end;
      elsif Prefix = "formal procedure " then
         declare
            Tail : constant String := After_Phrase ("with procedure");
         begin
            if Tail'Length > 0 then
               return Read_Name (Tail, Tail'First, True);
            end if;
         end;
      end if;

      return "";
   end Formal_Subprogram_Source_Name;

   procedure Add_Missing_Generic_Formal_Subprograms
     (Result : in out Extraction_Result;
      Lines  : Line_Vectors.Vector)
   is
   begin
      for L in 1 .. Natural (Lines.Length) loop
         declare
            Raw     : constant String := To_String (Lines (L - 1));
            Trimmed : constant String := Trim_Code_Whitespace
              (Editor.Ada_Syntax_Core.Strip_Comment_Safely (Raw));
            Lower   : constant String := Code_Lower_Line (Lines, L);
            Prefix  : constant String :=
              (if Starts_With (Lower, "with function")
               then "formal function "
               elsif Starts_With (Lower, "with procedure")
               then "formal procedure "
               else "");
            Name    : constant String :=
              Formal_Subprogram_Source_Name (Trimmed, Raw, Prefix);
         begin
            if Prefix'Length > 0
              and then Name'Length > 0
              and then not Has_Projected_Formal_Subprogram_Row (Result, L)
            then
               Insert_Source_Ordered
                 (Result,
                  Editor.Outline.Outline_Item'
                    (Kind        => Editor.Outline.Outline_Generic_Formal,
                     Label       => To_Unbounded_String (Prefix & Name),
                     Detail      => To_Unbounded_String
                       ("line" & Natural'Image (L) &
                        (if Prefix = "formal function "
                         then " generic formal function"
                         else " generic formal procedure")),
                     Depth       => 0,
                     Target_Kind => Editor.Outline.Buffer_Position_Target,
                     Buffer_Token => Result.Result_Identity.Active_Buffer_Token,
                     Line        => L,
                     Column      => Declaration_Target_Column (Raw)));
            end if;
         end;
      end loop;
   end Add_Missing_Generic_Formal_Subprograms;

   function Formal_Type_Label_Prefix_From_Line (Lower : String) return String is
   begin
      if Has_Token (Lower, "array") then
         return "formal array type ";
      elsif Has_Token (Lower, "access")
        and then (Has_Token (Lower, "function")
                  or else Has_Token (Lower, "procedure"))
      then
         return "formal access subprogram type ";
      elsif Has_Token (Lower, "access") then
         return "formal access type ";
      elsif Has_Token (Lower, "new")
        and then Has_Token (Lower, "private")
      then
         return "formal private extension type ";
      elsif Has_Token (Lower, "new") then
         return "formal derived type ";
      elsif Has_Token (Lower, "interface") then
         return "formal interface type ";
      else
         return "formal type ";
      end if;
   end Formal_Type_Label_Prefix_From_Line;

   function Formal_Type_Detail_Metadata_From_Line (Lower : String) return String is
   begin
      return
        (if Has_Token (Lower, "array") then " array" else "") &
        (if Has_Token (Lower, "access") then " access" else "") &
        (if Has_Token (Lower, "function") or else Has_Token (Lower, "procedure")
         then " access-subprogram" else "") &
        (if Has_Token (Lower, "new") then " derived" else "") &
        (if Has_Token (Lower, "range") then " range" else "") &
        (if Ada.Strings.Fixed.Index (Lower, "<>") /= 0 then " box" else "") &
        (if Has_Token (Lower, "private") then " private-extension" else "") &
        (if Has_Token (Lower, "interface") then " interface" else "") &
        (if Has_Token (Lower, "limited") then " limited" else "");
   end Formal_Type_Detail_Metadata_From_Line;

   function Formal_Type_Source_Name (Trimmed : String) return String
   is
      Lower : constant String :=
        Ada.Strings.Fixed.Translate
          (Trimmed, Ada.Strings.Maps.Constants.Lower_Case_Map);
      Pos : constant Natural := Ada.Strings.Fixed.Index (Lower, "with type");
   begin
      if Pos = 0 then
         return "";
      end if;

      return Read_Name (Trimmed, Pos + 9, True);
   end Formal_Type_Source_Name;

   procedure Add_Missing_Generic_Formal_Types
     (Result : in out Extraction_Result;
      Lines  : Line_Vectors.Vector)
   is
   begin
      for L in 1 .. Natural (Lines.Length) loop
         declare
            Raw     : constant String := To_String (Lines (L - 1));
            Trimmed : constant String := Trim_Code_Whitespace
              (Editor.Ada_Syntax_Core.Strip_Comment_Safely (Raw));
            Lower   : constant String := Code_Lower_Line (Lines, L);
            Name    : constant String := Formal_Type_Source_Name (Trimmed);
         begin
            if Starts_With (Lower, "with type ")
              and then Name'Length > 0
              and then not Has_Projected_Formal_Type_Row (Result, L)
            then
               Insert_Source_Ordered
                 (Result,
                  Editor.Outline.Outline_Item'
                    (Kind        => Editor.Outline.Outline_Generic_Formal,
                     Label       => To_Unbounded_String
                       (Formal_Type_Label_Prefix_From_Line (Lower) & Name),
                     Detail      => To_Unbounded_String
                       ("line" & Natural'Image (L) &
                        " generic formal type" &
                        Formal_Type_Detail_Metadata_From_Line (Lower)),
                     Depth       => 0,
                     Target_Kind => Editor.Outline.Buffer_Position_Target,
                     Buffer_Token => Result.Result_Identity.Active_Buffer_Token,
                     Line        => L,
                     Column      => Declaration_Target_Column (Raw)));
            end if;
         end;
      end loop;
   end Add_Missing_Generic_Formal_Types;

   function Has_Projected_Callable_Row
     (Result      : Extraction_Result;
      Line_Number : Natural) return Boolean
   is
   begin
      for Item of Result.Items loop
         if Item.Line = Line_Number
           and then Item.Kind in Editor.Outline.Outline_Procedure
              | Editor.Outline.Outline_Function
              | Editor.Outline.Outline_Subprogram
         then
            return True;
         end if;
      end loop;

      return False;
   end Has_Projected_Callable_Row;

   function Callable_Source_Text (Trimmed : String) return String is
   begin
      return Strip_Abstract_Prefix
        (Strip_Overriding_Prefix
           (Editor.Ada_Syntax_Core.Strip_Separate_Prefix (Trimmed)));
   end Callable_Source_Text;

   procedure Add_Missing_Callable_Declarations
     (Result : in out Extraction_Result;
      Lines  : Line_Vectors.Vector)
   is
   begin
      for L in 1 .. Natural (Lines.Length) loop
         declare
            Raw     : constant String := To_String (Lines (L - 1));
            Trimmed : constant String := Ada.Strings.Fixed.Trim
              (Editor.Ada_Syntax_Core.Strip_Comment_Safely (Raw),
               Ada.Strings.Both);
            Source  : constant String := Callable_Source_Text (Trimmed);
            Lower   : constant String :=
              Ada.Strings.Fixed.Translate
                (Editor.Ada_Syntax_Core.Sanitize_Line (Source),
                 Ada.Strings.Maps.Constants.Lower_Case_Map);
            Header  : constant String := Header_Text_From (Lines, L);
            Is_Func : constant Boolean := Starts_With_Word (Lower, "function");
            Is_Proc : constant Boolean := Starts_With_Word (Lower, "procedure");
            Kind    : constant Editor.Outline.Outline_Item_Kind :=
              (if Is_Func then Editor.Outline.Outline_Function
               else Editor.Outline.Outline_Procedure);
            Prefix  : constant String := (if Is_Func then "function" else "procedure");
            Name    : constant String :=
              (if Is_Func then Read_Function_Name (Source, Source'First + 8, True)
               elsif Is_Proc then Read_Name (Source, Source'First + 9, True)
               else "");
            Form    : constant String :=
              (if Is_Func and then Header_Is_Expression_Function (Lines, L)
               then "expression"
               elsif Is_Func
                 and then Has_Token_Is (Header)
                 and then Has_Is_Followed_By (Header, "separate")
               then "body"
               elsif Is_Proc
                 and then Has_Token_Is (Header)
                 and then (Has_Is_Followed_By (Header, "null")
                           or else Has_Is_Followed_By (Header, "separate"))
               then "body"
               elsif Has_Renames (Header) then "renames"
               else "declaration");
         begin
            if (Is_Func or else Is_Proc)
              and then Name'Length > 0
              and then not Has_Projected_Callable_Row (Result, L)
            then
               Insert_Source_Ordered
                 (Result,
                  Editor.Outline.Outline_Item'
                    (Kind        => Kind,
                     Label       => To_Unbounded_String
                       (Label_Text (Prefix, Name, Form)),
                     Detail      => To_Unbounded_String
                       (Detail_Text (Positive (L), Form)),
                     Depth       => 0,
                     Target_Kind => Editor.Outline.Buffer_Position_Target,
                     Buffer_Token => Result.Result_Identity.Active_Buffer_Token,
                     Line        => L,
                     Column      => Declaration_Target_Column (Raw)));
            end if;
         end;
      end loop;
   end Add_Missing_Callable_Declarations;

   function Is_Generic_Formal_Profile_Continuation
     (Lines       : Line_Vectors.Vector;
      Line_Number : Natural) return Boolean
   is
      Lower : constant String := Code_Lower_Line (Lines, Line_Number);
      First : constant Natural :=
        (if Line_Number > 3 then Line_Number - 3 else 1);
   begin
      if Line_Number <= 1 or else not Starts_With (Lower, "(") then
         return False;
      end if;

      for L in reverse First .. Line_Number - 1 loop
         declare
            Prev : constant String := Code_Lower_Line (Lines, L);
         begin
            if Prev'Length = 0 then
               null;
            elsif Starts_With (Prev, "with function")
              or else Starts_With (Prev, "with procedure")
            then
               return not Has_Code_Character (Prev, ';');
            elsif Has_Code_Character (Prev, ';') then
               return False;
            end if;
         end;
      end loop;

      return False;
   end Is_Generic_Formal_Profile_Continuation;

   procedure Remove_Generic_Formal_Profile_Objects
     (Result : in out Extraction_Result;
      Lines  : Line_Vectors.Vector)
   is
   begin
      if Result.Items.Is_Empty then
         return;
      end if;

      for I in reverse Result.Items.First_Index .. Result.Items.Last_Index loop
         declare
            Item : constant Editor.Outline.Outline_Item :=
              Result.Items.Element (I);
         begin
            if Item.Kind = Editor.Outline.Outline_Generic_Formal
              and then Starts_With (To_String (Item.Label), "formal object ")
              and then Is_Generic_Formal_Profile_Continuation (Lines, Item.Line)
            then
               Result.Items.Delete (I);
            end if;
         end;
      end loop;
   end Remove_Generic_Formal_Profile_Objects;

   procedure Remove_Generic_Formal_Object_Duplicates
     (Result : in out Extraction_Result)
   is
   begin
      if Result.Items.Is_Empty then
         return;
      end if;

      for I in reverse Result.Items.First_Index .. Result.Items.Last_Index loop
         declare
            Item : constant Editor.Outline.Outline_Item :=
              Result.Items.Element (I);
            Label : constant String := To_String (Item.Label);
            Name  : constant String :=
              (if Starts_With (Label, "object ")
               then Label (Label'First + 7 .. Label'Last)
               elsif Starts_With (Label, "constant ")
               then Label (Label'First + 9 .. Label'Last)
               else "");
            Found_Formal : Boolean := False;
         begin
            if Item.Kind = Editor.Outline.Outline_Object
              and then Name'Length > 0
            then
               for Existing of Result.Items loop
                  if Existing.Kind = Editor.Outline.Outline_Generic_Formal
                    and then Existing.Line = Item.Line
                    and then To_String (Existing.Label) = "formal object " & Name
                  then
                     Found_Formal := True;
                     exit;
                  end if;
               end loop;

               if Found_Formal then
                  Result.Items.Delete (I);
               end if;
            end if;
         end;
      end loop;
   end Remove_Generic_Formal_Object_Duplicates;

   procedure Remove_Duplicate_Body_Stubs (Result : in out Extraction_Result) is
   begin
      if Result.Items.Is_Empty then
         return;
      end if;

      for I in reverse Result.Items.First_Index .. Result.Items.Last_Index loop
         declare
            Item_Label : constant String := To_String (Result.Items.Element (I).Label);
            Item_Detail : constant String := To_String (Result.Items.Element (I).Detail);
            Duplicate : Boolean := False;
         begin
            if Ada.Strings.Fixed.Index (Item_Detail, "body-stub") /= 0
              and then I > Result.Items.First_Index
            then
               for J in Result.Items.First_Index .. I - 1 loop
                  declare
                     Existing : constant Editor.Outline.Outline_Item :=
                       Result.Items.Element (J);
                  begin
                     if Existing.Kind = Result.Items.Element (I).Kind
                       and then To_String (Existing.Label) = Item_Label
                       and then Ada.Strings.Fixed.Index
                         (To_String (Existing.Detail), "body-stub") /= 0
                     then
                        Duplicate := True;
                        exit;
                     end if;
                  end;
               end loop;

               if Duplicate then
                  Result.Items.Delete (I);
               end if;
            end if;
         end;
      end loop;
   end Remove_Duplicate_Body_Stubs;

   procedure Remove_Duplicate_Source_Rows (Result : in out Extraction_Result) is
   begin
      if Result.Items.Is_Empty then
         return;
      end if;

      for I in reverse Result.Items.First_Index .. Result.Items.Last_Index loop
         declare
            Item : constant Editor.Outline.Outline_Item :=
              Result.Items.Element (I);
            Duplicate : Boolean := False;
         begin
            if I > Result.Items.First_Index then
               for J in Result.Items.First_Index .. I - 1 loop
                  declare
                     Existing : constant Editor.Outline.Outline_Item :=
                       Result.Items.Element (J);
                  begin
                     if Existing.Kind = Item.Kind
                       and then Existing.Line = Item.Line
                       and then To_String (Existing.Label) = To_String (Item.Label)
                     then
                        Duplicate := True;
                        exit;
                     end if;
                  end;
               end loop;
            end if;

            if Duplicate then
               Result.Items.Delete (I);
            end if;
         end;
      end loop;
   end Remove_Duplicate_Source_Rows;

   procedure Remove_Redundant_Package_Aspect_Rows
     (Result : in out Extraction_Result)
   is
   begin
      if Result.Items.Is_Empty then
         return;
      end if;

      for I in reverse Result.Items.First_Index .. Result.Items.Last_Index loop
         declare
            Item  : constant Editor.Outline.Outline_Item := Result.Items.Element (I);
            Label : constant String := To_String (Item.Label);
            With_Pos : constant Natural := Ada.Strings.Fixed.Index (Label, " with ");
            Duplicate : Boolean := False;
         begin
            if Item.Kind = Editor.Outline.Outline_Package
              and then With_Pos > Label'First
            then
               for Existing of Result.Items loop
                  if Existing.Kind = Item.Kind
                    and then Existing.Line = Item.Line
                    and then To_String (Existing.Label) =
                      Label (Label'First .. With_Pos - 1)
                  then
                     Duplicate := True;
                     exit;
                  end if;
               end loop;

               if Duplicate then
                  Result.Items.Delete (I);
               end if;
            end if;
         end;
      end loop;
   end Remove_Redundant_Package_Aspect_Rows;

   procedure Remove_Redundant_Separate_Body_Rows
     (Result : in out Extraction_Result)
   is
   begin
      if Result.Items.Is_Empty then
         return;
      end if;

      for I in reverse Result.Items.First_Index .. Result.Items.Last_Index loop
         declare
            Item  : constant Editor.Outline.Outline_Item := Result.Items.Element (I);
            Label : constant String := To_String (Item.Label);
            Name  : constant String :=
              (if Starts_With (Label, "separate body ")
               then Label (Label'First + 14 .. Label'Last)
               else "");
            Duplicate : Boolean := False;
         begin
            if Name'Length > 0 then
               for Existing of Result.Items loop
                  declare
                     Existing_Label : constant String := To_String (Existing.Label);
                  begin
                     if Existing.Line = Item.Line
                       and then (Existing_Label = "package body " & Name
                                 or else Existing_Label = "procedure body " & Name
                                 or else Existing_Label = "function body " & Name)
                     then
                        Duplicate := True;
                        exit;
                     end if;
                  end;
               end loop;

               if Duplicate then
                  Result.Items.Delete (I);
               end if;
            end if;
         end;
      end loop;
   end Remove_Redundant_Separate_Body_Rows;

   procedure Remove_Label_Block_Object_Rows
     (Result : in out Extraction_Result;
      Lines  : Line_Vectors.Vector)
   is
   begin
      if Result.Items.Is_Empty then
         return;
      end if;

      for I in reverse Result.Items.First_Index .. Result.Items.Last_Index loop
         declare
            Item  : constant Editor.Outline.Outline_Item := Result.Items.Element (I);
            Lower : constant String := Code_Lower_Line (Lines, Item.Line);
            Colon : constant Natural := Ada.Strings.Fixed.Index (Lower, ":");
         begin
            if Item.Kind = Editor.Outline.Outline_Object
              and then Colon /= 0
              and then Colon < Lower'Last
            then
               declare
                  Tail : constant String := Ada.Strings.Fixed.Trim
                    (Lower (Colon + 1 .. Lower'Last), Ada.Strings.Both);
               begin
                  if Starts_With_Word (Tail, "begin")
                    or else Starts_With_Word (Tail, "declare")
                    or else Starts_With_Word (Tail, "loop")
                    or else Starts_With_Word (Tail, "select")
                  then
                     Result.Items.Delete (I);
                  end if;
               end;
            end if;
         end;
      end loop;
   end Remove_Label_Block_Object_Rows;

   procedure Remove_Redundant_Entry_Barrier_Rows
     (Result : in out Extraction_Result)
   is
   begin
      if Result.Items.Is_Empty then
         return;
      end if;

      for I in reverse Result.Items.First_Index .. Result.Items.Last_Index loop
         declare
            Item  : constant Editor.Outline.Outline_Item := Result.Items.Element (I);
            Label : constant String := To_String (Item.Label);
            When_Pos : constant Natural := Ada.Strings.Fixed.Index (Label, " when ");
            Duplicate : Boolean := False;
         begin
            if Starts_With (Label, "entry ")
              and then When_Pos > Label'First
            then
               for Existing of Result.Items loop
                  if Existing.Kind = Item.Kind
                    and then Existing.Line = Item.Line
                    and then Starts_With (To_String (Existing.Label), "entry ")
                    and then To_String (Existing.Label) =
                      Label (Label'First .. When_Pos - 1)
                  then
                     Duplicate := True;
                     exit;
                  end if;
               end loop;

               if Duplicate then
                  Result.Items.Delete (I);
               end if;
            end if;
         end;
      end loop;
   end Remove_Redundant_Entry_Barrier_Rows;

   procedure Remove_Redundant_Prefixed_Callable_Rows
     (Result : in out Extraction_Result)
   is
   begin
      if Result.Items.Is_Empty then
         return;
      end if;

      for I in reverse Result.Items.First_Index .. Result.Items.Last_Index loop
         declare
            Item  : constant Editor.Outline.Outline_Item := Result.Items.Element (I);
            Label : constant String := To_String (Item.Label);
            Replacement : Unbounded_String := Null_Unbounded_String;
            Duplicate : Boolean := False;
         begin
            if Starts_With (Label, "procedure body overriding procedure ") then
               Replacement := To_Unbounded_String
                 ("procedure body " & Label (Label'First + 36 .. Label'Last));
            elsif Starts_With (Label, "function body overriding function ") then
               Replacement := To_Unbounded_String
                 ("function body " & Label (Label'First + 34 .. Label'Last));
            end if;

            if Length (Replacement) > 0 then
               for Existing of Result.Items loop
                  if Existing.Line = Item.Line
                    and then Existing.Kind = Item.Kind
                    and then To_String (Existing.Label) = To_String (Replacement)
                  then
                     Duplicate := True;
                     exit;
                  end if;
               end loop;

               if Duplicate then
                  Result.Items.Delete (I);
               end if;
            end if;
         end;
      end loop;
   end Remove_Redundant_Prefixed_Callable_Rows;

   use Editor.Outline_Extractor.Range_Analysis;

   procedure Normalize_Projected_Subprogram_Headers
     (Result : in out Extraction_Result;
      Lines  : Line_Vectors.Vector)
   is
   begin
      if Result.Items.Is_Empty then
         return;
      end if;

      for I in Result.Items.First_Index .. Result.Items.Last_Index loop
         declare
            Item   : Editor.Outline.Outline_Item := Result.Items.Element (I);
            Header : constant String := Header_Text_From (Lines, Item.Line);
            Label  : constant String := To_String (Item.Label);
            Form   : constant String := Primary_Detail_Form (To_String (Item.Detail));
         begin
            if Item.Line > 0 and then Item.Line <= Natural (Lines.Length) then
               Item.Column :=
                 Declaration_Target_Column (To_String (Lines (Item.Line - 1)));
            end if;

            if Is_Separate_Subunit_Declaration (Lines, Item.Line)
              and then (Item.Kind = Editor.Outline.Outline_Package_Body
                        or else Item.Kind = Editor.Outline.Outline_Procedure
                        or else Item.Kind = Editor.Outline.Outline_Function)
            then
               Item.Depth := 0;
            end if;

            if Starts_With (Label, "generic procedure ")
              and then Header_Starts_With_Function (Header)
            then
               Item.Kind := Editor.Outline.Outline_Function;
               Item.Label := To_Unbounded_String
                 (Replace_Label_Prefix
                    (Label, "generic procedure ", "generic function "));
            elsif Starts_With (Label, "generic function ")
              and then Header_Starts_With_Procedure (Header)
            then
               Item.Kind := Editor.Outline.Outline_Procedure;
               Item.Label := To_Unbounded_String
                 (Replace_Label_Prefix
                    (Label, "generic function ", "generic procedure "));
            elsif Starts_With (Label, "formal procedure ")
              and then Header_Starts_With_Function (Header)
            then
               Item.Label := To_Unbounded_String
                 (Replace_Label_Prefix
                    (Label, "formal procedure ", "formal function "));
               Item.Detail := To_Unbounded_String
                 (Detail_Text (Positive (Item.Line), "generic formal function"));
            elsif Starts_With (Label, "formal function ")
              and then Header_Starts_With_Procedure (Header)
            then
               Item.Label := To_Unbounded_String
                 (Replace_Label_Prefix
                    (Label, "formal function ", "formal procedure "));
               Item.Detail := To_Unbounded_String
                 (Detail_Text (Positive (Item.Line), "generic formal procedure"));
            elsif Starts_With (Label, "separate body ")
              and then Header_Starts_With_Procedure (Header)
            then
               Item.Kind := Editor.Outline.Outline_Procedure;
               Item.Label := To_Unbounded_String
                 (Replace_Label_Prefix
                    (Label, "separate body ", "procedure body "));
               Item.Detail := To_Unbounded_String
                 (Detail_Text (Positive (Item.Line), "body"));
            elsif Starts_With (Label, "separate body ")
              and then Header_Starts_With_Function (Header)
            then
               Item.Kind := Editor.Outline.Outline_Function;
               Item.Label := To_Unbounded_String
                 (Replace_Label_Prefix
                    (Label, "separate body ", "function body "));
               Item.Detail := To_Unbounded_String
                 (Detail_Text (Positive (Item.Line), "body"));
            elsif Ends_With (Label, " instantiation")
              and then Header_Starts_With_Procedure (Header)
            then
               Item.Kind := Editor.Outline.Outline_Procedure;
               Item.Label := To_Unbounded_String
                 ("procedure " &
                  Label (Label'First + 8 .. Label'Last - 14));
            elsif Ends_With (Label, " instantiation")
              and then Header_Starts_With_Function (Header)
            then
               Item.Kind := Editor.Outline.Outline_Function;
               Item.Label := To_Unbounded_String
                 ("function " &
                  Label (Label'First + 8 .. Label'Last - 14));
            elsif Ends_With (Label, " instantiation")
              and then Starts_With (Label, "package ")
            then
               Item.Label := To_Unbounded_String
                 (Label (Label'First .. Label'Last - 14));
            end if;

            if (Item.Kind = Editor.Outline.Outline_Package
                or else Item.Kind = Editor.Outline.Outline_Procedure
                or else Item.Kind = Editor.Outline.Outline_Function)
              and then Form /= "renames"
              and then Has_Renames (Header)
            then
               declare
                  Current : constant String := To_String (Item.Label);
               begin
                  if not Ends_With (Current, " renames") then
                     Item.Label := To_Unbounded_String (Current & " renames");
                  end if;

                  Item.Detail := To_Unbounded_String
                    (Detail_Text (Positive (Item.Line), "renames"));
               end;
            end if;

            if Item.Kind = Editor.Outline.Outline_Package
              and then Form = "instantiation"
              and then not Header_Is_Instantiation (Lines, Item.Line)
            then
               Item.Detail := To_Unbounded_String
                 (Detail_Text (Positive (Item.Line), "spec"));
            end if;

            if (Item.Kind = Editor.Outline.Outline_Package
                or else Item.Kind = Editor.Outline.Outline_Procedure
                or else Item.Kind = Editor.Outline.Outline_Function)
              and then Form /= "instantiation"
              and then Header_Is_Instantiation (Lines, Item.Line)
            then
               declare
                  Current : constant String := To_String (Item.Label);
               begin
                  if Starts_With (Current, "procedure body ") then
                     Item.Label := To_Unbounded_String
                       (Replace_Label_Prefix
                          (Current, "procedure body ", "procedure "));
                  elsif Starts_With (Current, "function body ") then
                     Item.Label := To_Unbounded_String
                       (Replace_Label_Prefix
                          (Current, "function body ", "function "));
                  elsif Starts_With (Current, "expression function ") then
                     Item.Label := To_Unbounded_String
                       (Replace_Label_Prefix
                          (Current, "expression function ", "function "));
                  elsif Ends_With (Current, " instantiation")
                    and then Starts_With (Current, "package ")
                  then
                     Item.Label := To_Unbounded_String
                       (Current (Current'First .. Current'Last - 14));
                  end if;

                  Item.Detail := To_Unbounded_String
                    (Detail_Text (Positive (Item.Line), "instantiation"));
                  if Item.Kind in Editor.Outline.Outline_Procedure
                    | Editor.Outline.Outline_Function
                  then
                     declare
                        Target : constant String :=
                          Instantiation_Target_Text_From (Lines, Item.Line);
                     begin
                        if Target'Length > 0 then
                           Item.Detail := To_Unbounded_String
                             (Detail_Text
                                (Positive (Item.Line),
                                 "instantiation is new " & Target));
                        end if;
                     end;
                  end if;
                  Decrement_Subsequent_Nested_Depths
                    (Result, I, Item.Depth);
               end;
            end if;

            if (Item.Kind = Editor.Outline.Outline_Procedure
                or else Item.Kind = Editor.Outline.Outline_Function)
              and then Primary_Detail_Form (To_String (Item.Detail)) = "instantiation"
              and then Ada.Strings.Fixed.Index
                (To_String (Item.Detail), " is new ") = 0
            then
               declare
                  Target : constant String :=
                    Instantiation_Target_Text_From (Lines, Item.Line);
               begin
                  if Target'Length > 0 then
                     Item.Detail := To_Unbounded_String
                       (Detail_Text
                          (Positive (Item.Line),
                           "instantiation is new " & Target));
                  end if;
               end;
            end if;

            if Form = "body"
              and then Header_Is_Body_Stub (Lines, Item.Line)
            then
               Decrement_Subsequent_Nested_Depths (Result, I, Item.Depth);
            end if;

            if (Item.Kind = Editor.Outline.Outline_Procedure
                or else Item.Kind = Editor.Outline.Outline_Function)
              and then Form = "body"
              and then not Header_Is_Instantiation (Lines, Item.Line)
              and then not Header_Is_Body_Stub (Lines, Item.Line)
              and then not Has_Token (Header, "begin")
              and then not Header_Is_Subprogram_Body (Header)
            then
               declare
                  Current : constant String := To_String (Item.Label);
               begin
                  if Starts_With (Current, "generic procedure body ") then
                     Item.Label := To_Unbounded_String
                       (Replace_Label_Prefix
                          (Current, "generic procedure body ",
                           "generic procedure "));
                  elsif Starts_With (Current, "generic function body ") then
                     Item.Label := To_Unbounded_String
                       (Replace_Label_Prefix
                          (Current, "generic function body ",
                           "generic function "));
                  elsif Starts_With (Current, "procedure body ") then
                     Item.Label := To_Unbounded_String
                       (Replace_Label_Prefix
                          (Current, "procedure body ", "procedure "));
                  elsif Starts_With (Current, "function body ") then
                     Item.Label := To_Unbounded_String
                       (Replace_Label_Prefix
                          (Current, "function body ", "function "));
                  end if;

                  Item.Detail := To_Unbounded_String
                    (Detail_Text (Positive (Item.Line), "declaration"));
               end;
            end if;

            if Item.Kind = Editor.Outline.Outline_Function
              and then Form /= "expression"
              and then not Header_Is_Instantiation (Lines, Item.Line)
              and then Header_Is_Expression_Function (Lines, Item.Line)
            then
               declare
                  Current : constant String := To_String (Item.Label);
               begin
                  if Starts_With (Current, "generic function body ") then
                     Item.Label := To_Unbounded_String
                       (Replace_Label_Prefix
                          (Current, "generic function body ",
                           "generic expression function "));
                  elsif Starts_With (Current, "function body ") then
                     Item.Label := To_Unbounded_String
                       (Replace_Label_Prefix
                          (Current, "function body ", "expression function "));
                  elsif Starts_With (Current, "generic function ") then
                     Item.Label := To_Unbounded_String
                       (Replace_Label_Prefix
                          (Current, "generic function ",
                           "generic expression function "));
                  elsif Starts_With (Current, "function ") then
                     Item.Label := To_Unbounded_String
                       (Replace_Label_Prefix
                          (Current, "function ", "expression function "));
                  end if;

                  Item.Detail := To_Unbounded_String
                    (Detail_Text (Positive (Item.Line), "expression"));
                  Decrement_Subsequent_Nested_Depths
                    (Result, I, Item.Depth);
               end;
            end if;

            if (Item.Kind = Editor.Outline.Outline_Procedure
                or else Item.Kind = Editor.Outline.Outline_Function)
              and then Primary_Detail_Form (To_String (Item.Detail)) = "body"
              and then not Header_Is_Instantiation (Lines, Item.Line)
            then
               declare
                  Current : constant String := To_String (Item.Label);
               begin
                  if Starts_With (Current, "procedure ")
                    and then not Starts_With (Current, "procedure body ")
                  then
                     Item.Label := To_Unbounded_String
                       (Replace_Label_Prefix
                          (Current, "procedure ", "procedure body "));
                  elsif Starts_With (Current, "function ")
                    and then not Starts_With (Current, "function body ")
                  then
                     Item.Label := To_Unbounded_String
                       (Replace_Label_Prefix
                          (Current, "function ", "function body "));
                  end if;
               end;
            end if;

            if (Item.Kind = Editor.Outline.Outline_Procedure
                or else Item.Kind = Editor.Outline.Outline_Function)
              and then Form = "declaration"
              and then not Header_Is_Instantiation (Lines, Item.Line)
              and then not Header_Is_Expression_Function (Lines, Item.Line)
              and then Header_Is_Subprogram_Body (Header)
            then
               declare
                  Current : constant String := To_String (Item.Label);
               begin
                  if Starts_With (Current, "generic procedure ") then
                     Item.Label := To_Unbounded_String
                       (Replace_Label_Prefix
                          (Current, "generic procedure ", "generic procedure body "));
                  elsif Starts_With (Current, "generic function ") then
                     Item.Label := To_Unbounded_String
                       (Replace_Label_Prefix
                          (Current, "generic function ", "generic function body "));
                  elsif Starts_With (Current, "procedure ") then
                     Item.Label := To_Unbounded_String
                       (Replace_Label_Prefix
                          (Current, "procedure ", "procedure body "));
                  elsif Starts_With (Current, "function ") then
                     Item.Label := To_Unbounded_String
                       (Replace_Label_Prefix
                          (Current, "function ", "function body "));
                  end if;

                  Item.Detail := To_Unbounded_String
                    (Detail_Text (Positive (Item.Line), "body"));
               end;
            end if;

            Result.Items.Replace_Element (I, Item);
         end;
      end loop;
   end Normalize_Projected_Subprogram_Headers;

   function Declaration_Text_Until_Semicolon
     (Lines      : Line_Vectors.Vector;
      Start_Line : Natural) return String
   is
      Combined : Unbounded_String;
      Limit    : constant Natural :=
        Natural'Min (Natural (Lines.Length), Start_Line + 8);
   begin
      if Start_Line = 0 or else Lines.Is_Empty then
         return "";
      end if;

      for L in Start_Line .. Limit loop
         declare
            Lower : constant String := Code_Lower_Line (Lines, L);
         begin
            if Lower'Length > 0 then
               if Length (Combined) > 0 then
                  Append (Combined, " ");
               end if;
               Append (Combined, Lower);
               if Has_Code_Character (Lower, ';') then
                  exit;
               end if;
            end if;
         end;
      end loop;

      return To_String (Combined);
   end Declaration_Text_Until_Semicolon;

   function Has_Enumeration_Literal_Row_After
     (Result      : Extraction_Result;
      Line_Number : Natural;
      Depth       : Natural) return Boolean
   is
   begin
      for Existing of Result.Items loop
         if Existing.Kind = Editor.Outline.Outline_Enum_Literal
           and then Existing.Line >= Line_Number
           and then Existing.Depth = Depth
         then
            return True;
         end if;
      end loop;

      return False;
   end Has_Enumeration_Literal_Row_After;

   procedure Supplement_Split_Enumeration_Literals
     (Result : in out Extraction_Result;
      Lines  : Line_Vectors.Vector)
   is
      Original_Last : Natural;
   begin
      if Result.Items.Is_Empty then
         return;
      end if;

      Original_Last := Result.Items.Last_Index;
      for I in Result.Items.First_Index .. Original_Last loop
         declare
            Item : Editor.Outline.Outline_Item := Result.Items.Element (I);
            Label : constant String := To_String (Item.Label);
            Decl  : constant String :=
              Declaration_Text_Until_Semicolon (Lines, Item.Line);
         begin
            if Item.Kind = Editor.Outline.Outline_Type
              and then Starts_With (Label, "type ")
              and then Looks_Like_Enumeration_Type_Line (Decl)
              and then not Has_Enumeration_Literal_Row_After
                (Result, Item.Line, Item.Depth + 1)
            then
               Item.Label := To_Unbounded_String
                 ("enum type " & Label (Label'First + 5 .. Label'Last));
               Result.Items.Replace_Element (I, Item);

               for L in Item.Line .. Natural'Min (Natural (Lines.Length), Item.Line + 8) loop
                  declare
                     Raw : constant String := To_String (Lines (L - 1));
                  begin
                     if L /= Item.Line
                       or else Ada.Strings.Fixed.Index (Raw, "(") /= 0
                     then
                        Append_Enumeration_Literals_From_Line
                          (Result, Raw, Positive (L), Item.Depth + 1,
                           (if L = Item.Line
                            then First_Enumeration_List_Column (Raw)
                            else Raw'First));
                     end if;
                     exit when Has_Code_Character (Code_Lower_Line (Lines, L), ';');
                  end;
               end loop;
            end if;
         end;
      end loop;
   end Supplement_Split_Enumeration_Literals;

   function Comes_Before
     (Left  : Editor.Outline.Outline_Item;
      Right : Editor.Outline.Outline_Item) return Boolean
   is
   begin
      return Left.Line < Right.Line
        or else (Left.Line = Right.Line and then Left.Column < Right.Column)
        or else (Left.Line = Right.Line
                 and then Left.Column = Right.Column
                 and then Left.Depth < Right.Depth);
   end Comes_Before;

   procedure Sort_Items_By_Source (Result : in out Extraction_Result)
   is
   begin
      if Natural (Result.Items.Length) < 2 then
         return;
      end if;

      for I in Result.Items.First_Index + 1 .. Result.Items.Last_Index loop
         declare
            Current : Editor.Outline.Outline_Item := Result.Items.Element (I);
            J       : Natural := I;
         begin
            while J > Result.Items.First_Index
              and then Comes_Before (Current, Result.Items.Element (J - 1))
            loop
               Result.Items.Replace_Element (J, Result.Items.Element (J - 1));
               J := J - 1;
            end loop;
            Result.Items.Replace_Element (J, Current);
         end;
      end loop;
   end Sort_Items_By_Source;

   function Is_Code_Line_Begin (Lower_Line : String) return Boolean
   is
   begin
      return Starts_With_Word (Lower_Line, "begin");
   end Is_Code_Line_Begin;

   function Is_Separate_Body_Stub
     (Lines      : Line_Vectors.Vector;
      Start_Line : Natural) return Boolean
   is
      Combined : Unbounded_String;
      Limit    : constant Natural :=
        Natural'Min (Natural (Lines.Length), Start_Line + 5);
   begin
      if Start_Line = 0 or else Lines.Is_Empty then
         return False;
      end if;

      for L in Start_Line .. Limit loop
         declare
            Raw     : constant String := To_String (Lines (L - 1));
            Clean   : constant String := Editor.Ada_Syntax_Core.Strip_Comment_Safely (Raw);
            Code    : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Clean);
            Trimmed : constant String := Ada.Strings.Fixed.Trim (Code, Ada.Strings.Both);
            Lower   : constant String := Ada.Strings.Fixed.Translate
              (Trimmed, Ada.Strings.Maps.Constants.Lower_Case_Map);
         begin
            if Lower'Length = 0 then
               null;
            elsif Lower = "separate;" then
               return True;
            else
               Append (Combined, " ");
               Append (Combined, Lower);

               if Has_Code_Character (Lower, ';')
                 or else Starts_With_Word (Lower, "begin")
               then
                  exit;
               end if;
            end if;
         end;
      end loop;

      declare
         Text : constant String := To_String (Combined);
      begin
         return Ada.Strings.Fixed.Index (Text, " is separate;") /= 0
           or else Ada.Strings.Fixed.Index (Text, " is separate ") /= 0;
      end;
   end Is_Separate_Body_Stub;

   function Closing_Line_For
     (Lines                  : Line_Vectors.Vector;
      Start_Line             : Natural;
      Form                   : String;
      Expected_Lower_Name    : String := "";
      Expected_Close_Keyword : String := "") return Natural
   is
      Stack : Structure_Stack_Vectors.Vector;
      Root_Line : constant String := Code_Lower_Line (Lines, Start_Line);
   begin
      if Start_Line = 0 or else Lines.Is_Empty then
         return 0;
      end if;

      Stack.Append
        (Structure_Stack_Entry'
          (Needs_Body_Begin       =>
             Structure_Analysis.Form_Needs_Body_Begin (Form)
             and then Expected_Close_Keyword /= "package"
             and then Expected_Close_Keyword /= "protected",
          Pending_Header         => Declaration_Header_Starts_Construct (Root_Line),
          Expected_Close_Keyword => To_Unbounded_String (Expected_Close_Keyword),
          Expected_Name          => To_Unbounded_String (Expected_Lower_Name)));

      for L in Start_Line + 1 .. Natural (Lines.Length) loop
         declare
            Raw     : constant String := To_String (Lines (L - 1));
            Clean   : constant String := Editor.Ada_Syntax_Core.Strip_Comment_Safely (Raw);
            Code    : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Clean);
            Trimmed : constant String := Ada.Strings.Fixed.Trim (Code, Ada.Strings.Both);
            Lower   : constant String := Ada.Strings.Fixed.Translate
              (Trimmed, Ada.Strings.Maps.Constants.Lower_Case_Map);
            Structure_Lower : constant String := Normalize_Structure_Line (Lower);
            Block_Label     : constant String := Leading_Block_Label (Lower);
         begin
            if Structure_Lower'Length > 0 then
               if Structure_Analysis.Is_Code_Line_Close (Structure_Lower) then
                  if Natural (Stack.Length) = 1 then
                     if Structure_Analysis.Root_End_Matches
                       (Structure_Lower, Expected_Lower_Name, Expected_Close_Keyword)
                     then
                        return L;
                     end if;
                  else
                     if Structure_Analysis.Stack_End_Matches
                       (Structure_Lower,
                        To_String (Stack.Last_Element.Expected_Close_Keyword),
                        To_String (Stack.Last_Element.Expected_Name))
                     then
                        Stack.Delete_Last;
                     end if;
                  end if;
               elsif not Stack.Is_Empty
                 and then Stack.Last_Element.Pending_Header
                 and then Has_Token_Is (Structure_Lower)
               then
                  if Natural (Stack.Length) > 1
                    and then Has_Code_Character (Structure_Lower, ';')
                    and then (Has_Is_Followed_By (Structure_Lower, "separate")
                              or else Has_Is_Followed_By (Structure_Lower, "null")
                              or else Has_Is_Followed_By (Structure_Lower, "new"))
                  then
                     Stack.Delete_Last;
                  else
                     declare
                        Frame : Structure_Stack_Entry := Stack.Last_Element;
                     begin
                        Frame.Pending_Header := False;
                        Stack.Replace_Element (Stack.Last_Index, Frame);
                     end;
                  end if;
               elsif Starts_With_Word (Structure_Lower, "entry")
                 and then Is_Code_Line_Open (Structure_Lower)
               then
                  --  Protected entry bodies have their own named end.  Even
                  --  while an enclosing protected body is still conservatively
                  --  waiting for a begin, the entry frame must be tracked so
                  --  "end <entry>;" cannot close an enclosing construct that
                  --  happens to have the same name.
                  Stack.Append
                      (Structure_Stack_Entry'
          (Needs_Body_Begin       => Open_Line_Needs_Body_Begin (Structure_Lower),
                      Pending_Header         => False,
                      Expected_Close_Keyword =>
                        To_Unbounded_String
                          (Structure_Analysis.Structure_Close_Keyword_For_Open
                             (Structure_Lower)),
                      Expected_Name =>
                        To_Unbounded_String
                          (Structure_Analysis.Structure_Name_For_Open
                             (Structure_Lower))));
               elsif not Stack.Is_Empty
                 and then Stack.Last_Element.Needs_Body_Begin
                 and then Has_Token_Is (Structure_Lower)
                 and then not Is_Code_Line_Open (Structure_Lower)
               then
                  --  A multi-line body header can finish with a standalone
                  --  or continuation "is" line.  Keep waiting for the
                  --  associated begin instead of treating the line as a new
                  --  nested declaration.
                  null;
               elsif Natural (Stack.Length) > 1
                 and then Stack.Last_Element.Pending_Header
                 and then Has_Code_Character (Structure_Lower, ';')
               then
                  --  A split declaration that ends in ';' was a spec or
                  --  instantiation, not a body/range-bearing nested construct.
                  Stack.Delete_Last;
               elsif Is_Code_Line_Begin (Structure_Lower) then
                  if not Stack.Is_Empty
                    and then Stack.Last_Element.Needs_Body_Begin
                  then
                     declare
                        Frame : Structure_Stack_Entry := Stack.Last_Element;
                     begin
                        Frame.Needs_Body_Begin := False;
                        Frame.Pending_Header := False;
                        Stack.Replace_Element (Stack.Last_Index, Frame);
                     end;
                  elsif Natural (Stack.Length) = 1
                    and then Block_Label'Length = 0
                    and then To_String
                      (Stack.Last_Element.Expected_Close_Keyword) = "package"
                  then
                     --  A package body's optional elaboration-part begin is
                     --  part of the package frame, not a nested anonymous
                     --  block.  Labeled blocks inside that part are tracked
                     --  separately and must not close the package early.
                     null;
                  else
                     Stack.Append
                       (Structure_Stack_Entry'
          (Needs_Body_Begin       => False,
                         Pending_Header         => False,
                         Expected_Close_Keyword => Null_Unbounded_String,
                         Expected_Name          => To_Unbounded_String (Block_Label)));
                  end if;
               elsif Is_Code_Line_Inline_Balanced_Open (Structure_Lower) then
                  null;
               elsif Is_Code_Line_Open (Structure_Lower) then
                  Stack.Append
                      (Structure_Stack_Entry'
          (Needs_Body_Begin       => Open_Line_Needs_Body_Begin (Structure_Lower),
                      Pending_Header         => False,
                      Expected_Close_Keyword =>
                        To_Unbounded_String
                          (Structure_Analysis.Structure_Close_Keyword_For_Open
                             (Structure_Lower)),
                      Expected_Name =>
                        To_Unbounded_String
                          ((if Block_Label'Length > 0
                            then Block_Label
                            else Structure_Analysis.Structure_Name_For_Open
                              (Structure_Lower)))));
               elsif Declaration_Header_Starts_Construct (Structure_Lower) then
                  Stack.Append
                      (Structure_Stack_Entry'
          (Needs_Body_Begin       => Header_Start_Needs_Body_Begin (Structure_Lower),
                      Pending_Header         => True,
                      Expected_Close_Keyword =>
                        To_Unbounded_String
                          (Structure_Analysis.Structure_Close_Keyword_For_Open
                             (Structure_Lower)),
                      Expected_Name =>
                        To_Unbounded_String
                          ((if Block_Label'Length > 0
                            then Block_Label
                            else Structure_Analysis.Structure_Name_For_Open
                              (Structure_Lower)))));
               end if;
            end if;
         end;
      end loop;

      return 0;
   end Closing_Line_For;

   function Explicit_Root_End_Line_For
     (Lines                  : Line_Vectors.Vector;
      Start_Line             : Natural;
      Expected_Lower_Name    : String;
      Expected_Close_Keyword : String) return Natural
   is
   begin
      if Start_Line = 0 or else Lines.Is_Empty then
         return 0;
      end if;

      for L in Start_Line + 1 .. Natural (Lines.Length) loop
         declare
            Lower     : constant String := Code_Lower_Line (Lines, L);
            Name      : constant String := Structure_Analysis.Closing_Line_Name (Lower);
            Qualifier : constant String := Structure_Analysis.Closing_Line_Qualifier (Lower);
         begin
            if Starts_With_Word (Lower, "end") then
               if Expected_Lower_Name'Length > 0
                 and then Name = Expected_Lower_Name
               then
                  return L;
               elsif Expected_Close_Keyword'Length > 0
                 and then Name = Expected_Close_Keyword
                 and then (Qualifier'Length = 0
                           or else (Expected_Lower_Name'Length > 0
                                    and then Qualifier = Expected_Lower_Name))
               then
                  return L;
               end if;
            end if;
         end;
      end loop;

      return 0;
   end Explicit_Root_End_Line_For;

   procedure Annotate_Local_Structure_Ranges
     (Result : in out Extraction_Result;
      Text   : String)
   is
      Lines : Line_Vectors.Vector;
   begin
      Build_Line_Vector (Text, Lines);
      if Lines.Is_Empty or else Result.Items.Is_Empty then
         return;
      end if;

      Add_Missing_Generic_Formal_Subprograms (Result, Lines);
      Add_Missing_Generic_Formal_Types (Result, Lines);
      Add_Missing_Callable_Declarations (Result, Lines);
      Remove_Generic_Formal_Profile_Objects (Result, Lines);
      Remove_Generic_Formal_Object_Duplicates (Result);
      Normalize_Projected_Subprogram_Headers (Result, Lines);
      Remove_Redundant_Package_Aspect_Rows (Result);
      Remove_Redundant_Separate_Body_Rows (Result);
      Remove_Label_Block_Object_Rows (Result, Lines);
      Remove_Redundant_Entry_Barrier_Rows (Result);
      Remove_Redundant_Prefixed_Callable_Rows (Result);
      Supplement_Split_Enumeration_Literals (Result, Lines);
      Remove_Object_Field_Duplicates (Result);
      Remove_Duplicate_Body_Stubs (Result);
      Remove_Duplicate_Source_Rows (Result);
      Sort_Items_By_Source (Result);

      for Index in Result.Items.First_Index .. Result.Items.Last_Index loop
         declare
            Item       : Editor.Outline.Outline_Item := Result.Items.Element (Index);
            Start_Line : constant Natural := Detail_Start_Line (To_String (Item.Detail));
            End_Line   : Natural := 0;
            Form       : constant String := Primary_Detail_Form (To_String (Item.Detail));
         begin
            if Structure_Analysis.Item_May_Have_Structure_Range (Item)
              and then Start_Line > 0
              and then Start_Line <= Natural (Lines.Length)
              and then Form /= "declaration"
              and then not (Form = "body"
                            and then Is_Separate_Body_Stub (Lines, Start_Line))
            then
               End_Line := Closing_Line_For
                 (Lines, Start_Line, Form,
                  (if Form = "record" or else Form = "variant" then ""
                   else Structure_Analysis.Lowercase_Text
                     (Structure_Analysis.Last_Label_Word (To_String (Item.Label)))),
                  Structure_Analysis.Expected_End_Keyword (Item, Form));
               if End_Line > Start_Line then
                  declare
                     Range_Form : constant String :=
                       (if Form = "variant"
                        then "variant record variant-record"
                        else Form);
                  begin
                     Item.Detail := To_Unbounded_String
                       (End_Line_Detail (Start_Line, End_Line, Range_Form));
                  end;
                  Result.Items.Replace_Element (Index, Item);
               end if;
            end if;
         end;
      end loop;

      Normalize_Generic_Depths_From_Ranges (Result);
      Normalize_Ranged_Child_Depths (Result);
      Normalize_Depths_To_Nearest_Range (Result);
      Normalize_Same_Line_Enum_Literal_Depths (Result);
   end Annotate_Local_Structure_Ranges;


   procedure Append_Analysis_Result
     (Result   : in out Extraction_Result;
      Analysis : Editor.Ada_Language_Model.Analysis_Result)
   is
      function Has_Projected_Row
        (Kind  : Editor.Outline.Outline_Item_Kind;
         Label : String;
         Line  : Natural) return Boolean
      is
      begin
         for Existing of Result.Items loop
            if Existing.Kind = Kind
              and then Existing.Line = Line
              and then To_String (Existing.Label) = Label
            then
               return True;
            end if;
         end loop;

         return False;
      end Has_Projected_Row;
   begin
      for Index in 1 .. Editor.Ada_Language_Model.Symbol_Count (Analysis) loop
         declare
            Symbol : constant Editor.Ada_Language_Model.Symbol_Info :=
              Editor.Ada_Language_Model.Symbol_At (Analysis, Index);
            Kind : constant Editor.Outline.Outline_Item_Kind :=
              Outline_Kind_For_Symbol (Symbol.Kind);
            Label : constant String := Projected_Symbol_Label (Analysis, Symbol);
         begin
            if Include_Symbol_In_Outline (Analysis, Symbol)
              and then not Has_Projected_Row
                (Kind, Label, Symbol.Source_Span.Start_Line)
            then
               Result.Items.Append
                 (Editor.Outline.Outline_Item'
                    (Kind         => Kind,
                     Label        => To_Unbounded_String (Label),
                     Detail       => To_Unbounded_String (Symbol_Detail (Symbol)),
                     Depth        => Symbol.Depth,
                     Target_Kind  => Editor.Outline.Buffer_Position_Target,
                     Buffer_Token => Result.Result_Identity.Active_Buffer_Token,
                     Line         => Symbol.Source_Span.Start_Line,
                     Column       => Symbol.Source_Span.Start_Column));
            end if;
         end;
      end loop;
   end Append_Analysis_Result;

   function Extract
     (Snapshot : Buffer_Text_Snapshot) return Extraction_Result
   is
      Text        : constant String := To_String (Snapshot.Text);
      Result      : Extraction_Result :=
        (Result_Status   => Extraction_Ok,
         Failure_Kind    => No_Failure,
         Result_Identity => Snapshot.Snapshot_Identity,
         Items           => Outline_Item_Vectors.Empty_Vector);
   begin
      if Text'Length = 0 then
         return Result;
      end if;

      Append_Marker_Lines (Result, Text);
      if Item_Count (Result) > 0 then
         return Result;
      end if;

      if Looks_Like_Ada_Buffer (Text, To_String (Snapshot.Buffer_Label)) then
         declare
            Parser_Text : constant String := Tabs_As_Spaces (Text);
            Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
              Editor.Ada_Declaration_Parser.Parse
                (Parser_Text, To_String (Snapshot.Buffer_Label));
         begin
            if Editor.Ada_Language_Model.Symbol_Count (Analysis) > 0 then
               Append_Analysis_Result (Result, Analysis);
               Annotate_Local_Structure_Ranges (Result, Text);
               return Result;
            end if;
         end;
      end if;

      --  Parser produced no Ada symbols.  Preserve only explicit manual
      --  @outline rows; do not run the old declaration-leading Ada line scanner.
      return Result;
   exception
      when others =>
         return
           (Result_Status   => Extraction_Failed,
            Failure_Kind    => Extractor_Internal_Error,
            Result_Identity => Snapshot.Snapshot_Identity,
            Items           => Outline_Item_Vectors.Empty_Vector);
   end Extract;

   procedure Apply_To_Outline
     (Result  : Extraction_Result;
      Outline : in out Editor.Outline.Outline_State)
   is
   begin
      if not Editor.Outline.Snapshot_Is_Current
        (Outline, Result.Result_Identity)
      then
         Editor.Outline.Mark_Stale_Result (Outline);
         return;
      end if;

      if Result.Result_Status = Extraction_Failed then
         Editor.Outline.Mark_Extraction_Failed (Outline);
         return;
      elsif Result.Result_Status = Extraction_Unavailable then
         if Result.Result_Identity.Request_Token = 0 then
            return;
         end if;

         Editor.Outline.Mark_Unsupported (Outline);
         return;
      end if;

      if Item_Count (Result) = 0 then
         Editor.Outline.Mark_Unsupported
           (Outline, Editor.Outline.Message_Outline_No_Symbols);
      else
         declare
            Items : Editor.Outline.Outline_Item_Array (1 .. Item_Count (Result));
            J     : Positive := Items'First;
         begin
            for Item of Result.Items loop
               Items (J) := Item;
               J := J + 1;
            end loop;
            Editor.Outline.Replace_Items (Outline, Items);
         end;
      end if;
   end Apply_To_Outline;

end Editor.Outline_Extractor;
