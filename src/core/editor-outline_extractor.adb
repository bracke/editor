with Ada.Characters.Latin_1;
with Ada.Containers.Vectors;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Core;
with Editor.Ada_Declaration_Parser;
with Editor.Ada_Language_Model;

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
   is
   begin
      return
        (Text              => To_Unbounded_String (Text),
         Buffer_Label      => To_Unbounded_String (""),
         Snapshot_Identity =>
           (Active_Buffer_Token  => 0,
            Buffer_Revision      => 0,
            Lifecycle_Generation => 0,
            Text_Length          => Text'Length,
            Request_Token        => 0));
   end Make_Snapshot;

   function Make_Snapshot
     (Text         : String;
      Buffer_Label : String) return Buffer_Text_Snapshot
   is
   begin
      return
        (Text              => To_Unbounded_String (Text),
         Buffer_Label      => To_Unbounded_String (Buffer_Label),
         Snapshot_Identity =>
           (Active_Buffer_Token  => 0,
            Buffer_Revision      => 0,
            Lifecycle_Generation => 0,
            Text_Length          => Text'Length,
            Request_Token        => 0));
   end Make_Snapshot;

   function Make_Snapshot
     (Text                 : String;
      Active_Buffer_Token  : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Request_Token        : Natural) return Buffer_Text_Snapshot
   is
   begin
      return
        (Text              => To_Unbounded_String (Text),
         Buffer_Label      => To_Unbounded_String (""),
         Snapshot_Identity =>
           (Active_Buffer_Token  => Active_Buffer_Token,
            Buffer_Revision      => Buffer_Revision,
            Lifecycle_Generation => Lifecycle_Generation,
            Text_Length          => Text'Length,
            Request_Token        => Request_Token));
   end Make_Snapshot;

   function Make_Snapshot
     (Text                 : String;
      Buffer_Label         : String;
      Active_Buffer_Token  : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Request_Token        : Natural) return Buffer_Text_Snapshot
   is
   begin
      return
        (Text              => To_Unbounded_String (Text),
         Buffer_Label      => To_Unbounded_String (Buffer_Label),
         Snapshot_Identity =>
           (Active_Buffer_Token  => Active_Buffer_Token,
            Buffer_Revision      => Buffer_Revision,
            Lifecycle_Generation => Lifecycle_Generation,
            Text_Length          => Text'Length,
            Request_Token        => Request_Token));
   end Make_Snapshot;

   function Identity
     (Snapshot : Buffer_Text_Snapshot) return Editor.Outline.Outline_Snapshot_Identity
   is
   begin
      return Snapshot.Snapshot_Identity;
   end Identity;

   function Status
     (Result : Extraction_Result) return Extraction_Status
   is
   begin
      return Result.Result_Status;
   end Status;

   function Failure
     (Result : Extraction_Result) return Extraction_Failure_Kind
   is
   begin
      return Result.Failure_Kind;
   end Failure;

   function Item_Count
     (Result : Extraction_Result) return Natural
   is
   begin
      return Natural (Result.Items.Length);
   end Item_Count;

   function Identity
     (Result : Extraction_Result) return Editor.Outline.Outline_Snapshot_Identity
   is
   begin
      return Result.Result_Identity;
   end Identity;

   function Is_Success
     (Result : Extraction_Result) return Boolean
   is
   begin
      return Result.Result_Status = Extraction_Ok;
   end Is_Success;

   Fingerprint_Modulus : constant Long_Long_Integer := 2_147_483_647;

   function Hash_Mix
     (Seed       : Natural;
      Addend     : Long_Long_Integer;
      Multiplier : Long_Long_Integer := 131) return Natural
   is
   begin
      return Natural
        ((Long_Long_Integer (Seed) * Multiplier + Addend) mod Fingerprint_Modulus);
   end Hash_Mix;

   function Hash_String
     (Seed : Natural;
      Text : String) return Natural
   is
      H : Natural := Seed;
   begin
      for C of Text loop
         H := Hash_Mix (H, Long_Long_Integer (Character'Pos (C)) + 1);
      end loop;
      return H;
   end Hash_String;

   function Fingerprint
     (Result : Extraction_Result) return Natural
   is
      H : Natural :=
        (Natural (Extraction_Status'Pos (Result.Result_Status)) + 17) * 31
        + Natural (Extraction_Failure_Kind'Pos (Result.Failure_Kind)) + 1;
   begin
      H := H mod 2_147_483_647;
      H := Hash_Mix (H, Long_Long_Integer (Item_Count (Result)) + 1);
      for Item of Result.Items loop
         H := Hash_Mix
           (H,
            Long_Long_Integer
              (Natural (Editor.Outline.Outline_Item_Kind'Pos (Item.Kind))) + 1);
         H := Hash_String (H, To_String (Item.Label));
         H := Hash_String (H, To_String (Item.Detail));
         H := Hash_Mix (H, Long_Long_Integer (Item.Depth) + 1);
         H := Hash_Mix
           (H,
            Long_Long_Integer
              (Natural (Editor.Outline.Outline_Target_Kind'Pos (Item.Target_Kind))) + 1);
         H := Hash_Mix (H, Long_Long_Integer (Item.Buffer_Token) + 1);
         H := Hash_Mix (H, Long_Long_Integer (Item.Line) + 1);
         H := Hash_Mix (H, Long_Long_Integer (Item.Column) + 1);
      end loop;
      return H;
   end Fingerprint;

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

   procedure Remember_Declaration_Line
     (State : in out Scan_State;
      Lower : String)
   is
      Existing : constant String := To_String (State.Pending_Declaration);
   begin
      if Existing'Length = 0 then
         State.Pending_Declaration := To_Unbounded_String (Lower);
      elsif Existing'Length + Lower'Length + 1 <= 2_000 then
         State.Pending_Declaration := To_Unbounded_String
           (Existing & " " & Lower);
      end if;
   end Remember_Declaration_Line;




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

   function Has_Token
     (Lower_Line : String;
      Token      : String) return Boolean;

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
      --  Ada permits abstract subprogram declarations as:
      --     abstract procedure P;
      --     abstract function F return T;
      --  Treat the abstraction marker like overriding/private/separate
      --  prefixes for outline extraction: it classifies the subprogram, not
      --  the declaration target itself.
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
      --  Ada private child unit specs are written as
      --     private package Parent.Child is
      --  Treat the visibility prefix like overriding/separate prefixes for
      --  extraction: it should not hide the package declaration or move the
      --  navigation target away from the package keyword.
      if Starts_With_Phrase (Line, "private package ")
        and then Line'Length > 8
      then
         return Line (Line'First + 8 .. Line'Last);
      else
         return Line;
      end if;
   end Strip_Private_Package_Prefix;

   function Leading_Block_Label (Line : String) return String
   is
      Trimmed : constant String := Trim_Code_Whitespace (Line);
      I       : Natural := Trimmed'First;
      Name    : constant String := Read_Name (Trimmed, Trimmed'First, False);
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

      --  Only treat labels on local statement/block forms as structure labels.
      --  Do not strip ordinary declarations with colons, such as object
      --  declarations, because those are not Ada block labels.
      declare
         Rest : constant String := Trimmed (I .. Trimmed'Last);
      begin
         if Starts_With_Word (Rest, "begin")
           or else Starts_With_Word (Rest, "declare")
           or else Starts_With_Word (Rest, "loop")
           or else Starts_With_Word (Rest, "select")
           or else Starts_With_Word (Rest, "for")
           or else Starts_With_Word (Rest, "while")
         then
            return Name;
         else
            return "";
         end if;
      end;
   end Leading_Block_Label;

   function Strip_Leading_Block_Label (Line : String) return String
   is
      Trimmed : constant String := Trim_Code_Whitespace (Line);
      I       : Natural := Trimmed'First;
      Name    : constant String := Read_Name (Trimmed, Trimmed'First, False);
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
        (Strip_Private_Package_Prefix
           (Strip_Abstract_Prefix
              (Strip_Overriding_Prefix
                 (Editor.Ada_Syntax_Core.Strip_Separate_Prefix (Trimmed)))));
   begin
      --  range matching is deliberately lexical, but       --  requires every structure-normalization entry point to see only code.
      --  The current caller already supplies sanitized text, but sanitizing
      --  again here keeps this helper safe if future local structure code calls
      --  it directly with a raw lower-case line.  This remains transient and
      --  preserves columns because the same Ada lexical sanitizer is used.
      return Trim_Code_Whitespace (Stripped);
   end Normalize_Structure_Line;

   function Declaration_Form
     (Lower_Line : String;
      Kind       : Editor.Outline.Outline_Item_Kind) return String
   is
   begin
      if Has_Renames (Lower_Line) then
         return "renames";
      elsif Kind = Editor.Outline.Outline_Package_Body then
         return "body";
      elsif Kind = Editor.Outline.Outline_Package then
         if Has_Is_Followed_By (Lower_Line, "new") then
            return "instantiation";
         else
            return "spec";
         end if;
      elsif Kind = Editor.Outline.Outline_Procedure
        or else Kind = Editor.Outline.Outline_Function
        or else Kind = Editor.Outline.Outline_Subprogram
      then
         if Kind = Editor.Outline.Outline_Function
           and then Looks_Like_Expression_Function (Lower_Line)
         then
            return "expression";
         elsif Has_Is_Followed_By (Lower_Line, "new") then
            return "instantiation";
         elsif Kind = Editor.Outline.Outline_Procedure
           and then Has_Token_Is (Lower_Line)
           and then (Has_Is_Followed_By (Lower_Line, "null")
                     or else Has_Is_Followed_By (Lower_Line, "separate"))
         then
            return "body";
         elsif Kind = Editor.Outline.Outline_Function
           and then Has_Token_Is (Lower_Line)
           and then Has_Is_Followed_By (Lower_Line, "separate")
         then
            return "body";
         elsif Kind = Editor.Outline.Outline_Subprogram then
            return "declaration";
         elsif Declaration_Opens_Block (Lower_Line) then
            return "body";
         elsif Declaration_Header_Ends (Lower_Line) then
            return "declaration";
         else
            return "pending";
         end if;
      elsif Kind = Editor.Outline.Outline_Task then
         if Starts_With_Phrase (Lower_Line, "task body ") then
            return "body";
         elsif Starts_With_Phrase (Lower_Line, "task type ") then
            return "type";
         else
            return "task";
         end if;
      elsif Kind = Editor.Outline.Outline_Protected then
         if Starts_With_Phrase (Lower_Line, "protected body ") then
            return "body";
         elsif Starts_With_Phrase (Lower_Line, "protected type ") then
            return "type";
         else
            return "protected";
         end if;
      elsif Kind = Editor.Outline.Outline_Exception then
         return "exception";
      elsif Kind = Editor.Outline.Outline_Object then
         if Has_Token (Lower_Line, "constant") then
            return "constant";
         elsif Has_Renames (Lower_Line) then
            return "renames";
         else
            return "object";
         end if;
      elsif Kind = Editor.Outline.Outline_Discriminant then
         return "discriminant";
      elsif Kind = Editor.Outline.Outline_Enum_Literal then
         return "enumeration";
      elsif Kind = Editor.Outline.Outline_Generic_Formal then
         if Starts_With_Word (Lower_Line, "type") then
            return "generic formal type";
         elsif Starts_With_Phrase (Lower_Line, "with package ") then
            return "generic formal package";
         elsif Starts_With_Phrase (Lower_Line, "with procedure ") then
            return "generic formal procedure";
         elsif Starts_With_Phrase (Lower_Line, "with function ") then
            return "generic formal function";
         else
            return "generic formal object";
         end if;
      elsif Kind = Editor.Outline.Outline_Type then
         if Starts_With_Word (Lower_Line, "subtype") then
            return "subtype";
         elsif Has_Token (Lower_Line, "limited")
           and then Has_Token (Lower_Line, "private")
         then
            return "limited private";
         elsif Has_Token (Lower_Line, "private") then
            return "private";
         elsif Has_Token (Lower_Line, "record") then
            return "record";
         elsif Looks_Like_Enumeration_Type_Line (Lower_Line) then
            return "enumeration";
         elsif Has_Token (Lower_Line, "array") then
            return "array";
         elsif Has_Token (Lower_Line, "access") then
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
      if not Starts_With_Word (Lower_Line, "end") then
         return False;
      end if;

      return Lower_Line = "end;"
        or else Starts_With_Keyword (Lower_Line, "end package")
        or else Starts_With_Keyword (Lower_Line, "end procedure")
        or else Starts_With_Keyword (Lower_Line, "end function")
        or else Starts_With_Keyword (Lower_Line, "end task")
        or else Starts_With_Keyword (Lower_Line, "end protected")
        or else (Has_Code_Character (Lower_Line, ';')
                 and then not Starts_With_Keyword (Lower_Line, "end if")
                 and then not Starts_With_Keyword (Lower_Line, "end loop")
                 and then not Starts_With_Keyword (Lower_Line, "end case")
                 and then not Starts_With_Keyword (Lower_Line, "end record")
                 and then not Starts_With_Keyword (Lower_Line, "end select"));
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
     (Result      : in out Extraction_Result;
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
          Depth        => Depth,
          Target_Kind  => Editor.Outline.Buffer_Position_Target,
          Buffer_Token => Result.Result_Identity.Active_Buffer_Token,
          Line         => Line_Number,
          Column       => Declaration_Target_Column (Raw_Line)));
   end Append_Item;

   procedure Update_Item_Form
     (Result : in out Extraction_Result;
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
         if Form = "body" and then Starts_With (Current, "generic procedure ") then
            Item.Label := To_Unbounded_String
              ("generic procedure body " &
               Current (Current'First + 18 .. Current'Last));
         elsif Form = "body" and then Starts_With (Current, "procedure ") then
            Item.Label := To_Unbounded_String
              ("procedure body " & Current (Current'First + 10 .. Current'Last));
         elsif Form = "body" and then Starts_With (Current, "generic function ") then
            Item.Label := To_Unbounded_String
              ("generic function body " &
               Current (Current'First + 17 .. Current'Last));
         elsif Form = "body" and then Starts_With (Current, "function ") then
            Item.Label := To_Unbounded_String
              ("function body " & Current (Current'First + 9 .. Current'Last));
         elsif Form = "expression" and then Starts_With (Current, "generic function ") then
            Item.Label := To_Unbounded_String
              ("generic expression function " &
               Current (Current'First + 17 .. Current'Last));
         elsif Form = "expression" and then Starts_With (Current, "function ") then
            Item.Label := To_Unbounded_String
              ("expression function " & Current (Current'First + 9 .. Current'Last));
         elsif Form = "renames" then
            Item.Label := To_Unbounded_String (Current & " renames");
         elsif Form = "record" and then Starts_With (Current, "type ") then
            Item.Label := To_Unbounded_String
              ("record type " & Current (Current'First + 5 .. Current'Last));
         elsif Form = "enumeration" and then Starts_With (Current, "type ") then
            Item.Label := To_Unbounded_String
              ("enum type " & Current (Current'First + 5 .. Current'Last));
         elsif Form = "array" and then Starts_With (Current, "type ") then
            Item.Label := To_Unbounded_String
              ("array type " & Current (Current'First + 5 .. Current'Last));
         elsif Form = "access" and then Starts_With (Current, "type ") then
            Item.Label := To_Unbounded_String
              ("access type " & Current (Current'First + 5 .. Current'Last));
         elsif (Form = "private" or else Form = "limited private")
           and then Starts_With (Current, "type ")
         then
            Item.Label := To_Unbounded_String
              ("private type " & Current (Current'First + 5 .. Current'Last));
         elsif Form = "instantiation" and then Starts_With (Current, "generic procedure body ") then
            Item.Label := To_Unbounded_String
              ("generic procedure " & Current (Current'First + 23 .. Current'Last));
         elsif Form = "instantiation" and then Starts_With (Current, "procedure body ") then
            Item.Label := To_Unbounded_String
              ("procedure " & Current (Current'First + 15 .. Current'Last));
         elsif Form = "instantiation" and then Starts_With (Current, "generic function body ") then
            Item.Label := To_Unbounded_String
              ("generic function " & Current (Current'First + 22 .. Current'Last));
         elsif Form = "instantiation" and then Starts_With (Current, "function body ") then
            Item.Label := To_Unbounded_String
              ("function " & Current (Current'First + 14 .. Current'Last));
         elsif Form = "subtype" then
            null;
         end if;
      end;
      Result.Items.Replace_Element (Index, Item);
   end Update_Item_Form;

   function Append_Marker_Line
     (Result      : in out Extraction_Result;
      Raw_Line    : String;
      Line_Number : Positive) return Boolean
   is
      Trimmed : constant String := Ada.Strings.Fixed.Trim (Raw_Line, Ada.Strings.Both);
   begin
      if Starts_With (Trimmed, Marker) then
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
          (Kind        => Kind_For_Label (Label),
                Label       => To_Unbounded_String (Label),
                Detail      => To_Unbounded_String (Detail),
                Depth        => 0,
                Target_Kind  => Editor.Outline.Buffer_Position_Target,
                Buffer_Token => Result.Result_Identity.Active_Buffer_Token,
                Line         => Line_Number,
                Column       => Declaration_Target_Column (Raw_Line)));
            return True;
         end;
      end if;

      return False;
   end Append_Marker_Line;

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
        or else Starts_With_Word (Lower_Line, "procedure")
        or else Starts_With_Word (Lower_Line, "function")
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

   procedure Append_Record_Field_Line
     (Result      : in out Extraction_Result;
      State       : Scan_State;
      Raw_Line    : String;
      Line_Number : Positive;
      Lower_Line  : String;
      Trimmed     : String)
   is
      Name : constant String := Record_Field_Name (Trimmed);
   begin
      if State.In_Record_Type
        and then Looks_Like_Record_Field_Line (Lower_Line)
        and then Name'Length > 0
      then
         Append_Item
           (Result, Editor.Outline.Outline_Field, "field", Name,
            Raw_Line, Line_Number, State.Depth + 1, "component");
      end if;
   end Append_Record_Field_Line;

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

   procedure Append_Generic_Formal_Line
     (Result      : in out Extraction_Result;
      State       : Scan_State;
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
         Raw_Line, Line_Number, State.Depth + 1,
         Declaration_Form (Lower_Line, Editor.Outline.Outline_Generic_Formal));
   end Append_Generic_Formal_Line;


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
        or else Starts_With_Word (Lower_Line, "procedure")
        or else Starts_With_Word (Lower_Line, "function")
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
        or else Starts_With_Word (Lower_Line, "procedure")
        or else Starts_With_Word (Lower_Line, "function")
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

   procedure Append_Discriminants_From_Type_Line
     (Result      : in out Extraction_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural)
   is
      Code       : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
      Open_Paren : Natural := 0;
      Close_Paren : Natural := 0;
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

   --  Normal Ada declaration extraction is parser-owned.  The only
   --  non-parser fallback retained here is explicit @outline marker handling.

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


   function Numeric_Suffix (Text : String; Start : Positive) return Natural
   is
      Value : Natural := 0;
      I     : Natural := Start;
   begin
      while I <= Text'Last
        and then Text (I) >= '0'
        and then Text (I) <= '9'
      loop
         Value := Value * 10 + Character'Pos (Text (I)) - Character'Pos ('0');
         I := I + 1;
      end loop;
      return Value;
   end Numeric_Suffix;

   function Detail_Start_Line (Detail : String) return Natural
   is
   begin
      if Starts_With (Detail, "line ") then
         return Numeric_Suffix (Detail, Detail'First + 5);
      elsif Starts_With (Detail, "lines ") then
         return Numeric_Suffix (Detail, Detail'First + 6);
      else
         return 0;
      end if;
   end Detail_Start_Line;

   function Detail_End_Line (Detail : String) return Natural
   is
      Start_Line : constant Natural := Detail_Start_Line (Detail);
      Dash       : Natural := 0;
   begin
      if not Starts_With (Detail, "lines ") then
         return Start_Line;
      end if;

      for I in Detail'Range loop
         if Detail (I) = '-' then
            Dash := I;
            exit;
         end if;
      end loop;

      if Dash = 0 or else Dash >= Detail'Last then
         return Start_Line;
      end if;

      return Numeric_Suffix (Detail, Dash + 1);
   end Detail_End_Line;

   function End_Line_Detail
     (Start_Line : Natural;
      End_Line   : Natural;
      Form       : String) return String
   is
      Start_Text : constant String := Ada.Strings.Fixed.Trim
        (Natural'Image (Start_Line), Ada.Strings.Both);
      End_Text   : constant String := Ada.Strings.Fixed.Trim
        (Natural'Image (End_Line), Ada.Strings.Both);
      Prefix : constant String :=
        (if End_Line > Start_Line
         then "lines " & Start_Text & "-" & End_Text
         else "line " & Start_Text);
   begin
      if Form'Length = 0 then
         return Prefix;
      else
         return Prefix & " " & Form;
      end if;
   end End_Line_Detail;

   function Detail_Form (Detail : String) return String
   is
      I : Natural := Detail'First;
   begin
      if Starts_With (Detail, "line ") then
         I := Detail'First + 5;
      elsif Starts_With (Detail, "lines ") then
         I := Detail'First + 6;
      else
         return "";
      end if;

      while I <= Detail'Last
        and then ((Detail (I) >= '0' and then Detail (I) <= '9')
                  or else Detail (I) = '-')
      loop
         I := I + 1;
      end loop;

      while I <= Detail'Last
        and then (Detail (I) = ' ' or else Detail (I) = Ada.Characters.Latin_1.HT)
      loop
         I := I + 1;
      end loop;

      if I <= Detail'Last then
         return Detail (I .. Detail'Last);
      else
         return "";
      end if;
   end Detail_Form;

   function Primary_Detail_Form (Detail : String) return String
   is
      Form : constant String := Detail_Form (Detail);
   begin
      for I in Form'Range loop
         if Form (I) = ' ' or else Form (I) = Ada.Characters.Latin_1.HT then
            if I = Form'First then
               return "";
            else
               return Form (Form'First .. I - 1);
            end if;
         end if;
      end loop;

      return Form;
   end Primary_Detail_Form;

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

   procedure Normalize_Generic_Depths_From_Ranges
     (Result : in out Extraction_Result)
   is
   begin
      if Result.Items.Is_Empty then
         return;
      end if;

      for I in Result.Items.First_Index .. Result.Items.Last_Index loop
         declare
            Item  : Editor.Outline.Outline_Item := Result.Items.Element (I);
            Label : constant String := To_String (Item.Label);
         begin
            if Starts_With (Label, "formal ") and then Item.Depth /= 0 then
               Item.Depth := 0;
               Result.Items.Replace_Element (I, Item);
            end if;
         end;
      end loop;

      for I in Result.Items.First_Index .. Result.Items.Last_Index loop
         declare
            Item       : Editor.Outline.Outline_Item := Result.Items.Element (I);
            Label      : constant String := To_String (Item.Label);
            Old_Depth  : constant Natural := Item.Depth;
            Start_Line : constant Natural := Detail_Start_Line (To_String (Item.Detail));
            End_Line   : constant Natural := Detail_End_Line (To_String (Item.Detail));
         begin
            if Starts_With (Label, "generic ")
              and then Old_Depth > 0
            then
               Item.Depth := 0;
               Result.Items.Replace_Element (I, Item);

               if End_Line > Start_Line then
                  for J in Result.Items.First_Index .. Result.Items.Last_Index loop
                     if J /= I then
                        declare
                           Child : Editor.Outline.Outline_Item :=
                             Result.Items.Element (J);
                        begin
                           if Child.Line > Start_Line
                             and then Child.Line <= End_Line
                             and then Child.Depth >= Old_Depth
                           then
                              Child.Depth := Child.Depth - Old_Depth;
                              Result.Items.Replace_Element (J, Child);
                           end if;
                        end;
                     end if;
                  end loop;
               end if;
            end if;
         end;
      end loop;
   end Normalize_Generic_Depths_From_Ranges;

   procedure Normalize_Ranged_Child_Depths
     (Result : in out Extraction_Result)
   is
   begin
      if Result.Items.Is_Empty then
         return;
      end if;

      for I in Result.Items.First_Index .. Result.Items.Last_Index loop
         declare
            Parent     : constant Editor.Outline.Outline_Item :=
              Result.Items.Element (I);
            Start_Line : constant Natural :=
              Detail_Start_Line (To_String (Parent.Detail));
            End_Line   : constant Natural :=
              Detail_End_Line (To_String (Parent.Detail));
            Form       : constant String :=
              Primary_Detail_Form (To_String (Parent.Detail));
            Has_Range  : constant Boolean :=
              Parent.Kind in Editor.Outline.Outline_Package_Body
                 | Editor.Outline.Outline_Task
                 | Editor.Outline.Outline_Protected
              or else (Parent.Kind = Editor.Outline.Outline_Package
                       and then Form = "spec")
              or else ((Parent.Kind = Editor.Outline.Outline_Procedure
                        or else Parent.Kind = Editor.Outline.Outline_Function)
                       and then Form = "body")
              or else (Parent.Kind = Editor.Outline.Outline_Type
                       and then (Form = "record" or else Form = "variant"));
         begin
            if End_Line > Start_Line and then Has_Range then
               for J in Result.Items.First_Index .. Result.Items.Last_Index loop
                  if J /= I then
                     declare
                        Child : Editor.Outline.Outline_Item :=
                          Result.Items.Element (J);
                     begin
                        if Child.Line > Start_Line
                          and then Child.Line < End_Line
                          and then Child.Depth <= Parent.Depth
                        then
                           Child.Depth := Parent.Depth + 1;
                           Result.Items.Replace_Element (J, Child);
                        end if;
                     end;
                  end if;
               end loop;
            end if;
         end;
      end loop;
   end Normalize_Ranged_Child_Depths;

   procedure Normalize_Depths_To_Nearest_Range
     (Result : in out Extraction_Result)
   is
      function Has_Structure_Range
        (Item : Editor.Outline.Outline_Item) return Boolean
      is
         Form : constant String := Primary_Detail_Form (To_String (Item.Detail));
      begin
         return Item.Kind in Editor.Outline.Outline_Package_Body
              | Editor.Outline.Outline_Task
              | Editor.Outline.Outline_Protected
           or else (Item.Kind = Editor.Outline.Outline_Package
                    and then Form = "spec")
           or else ((Item.Kind = Editor.Outline.Outline_Procedure
                     or else Item.Kind = Editor.Outline.Outline_Function)
                    and then Form = "body")
           or else (Item.Kind = Editor.Outline.Outline_Type
                    and then (Form = "record" or else Form = "variant"));
      end Has_Structure_Range;
   begin
      if Result.Items.Is_Empty then
         return;
      end if;

      for I in Result.Items.First_Index .. Result.Items.Last_Index loop
         declare
            Child          : Editor.Outline.Outline_Item := Result.Items.Element (I);
            Best_Parent    : Natural := Result.Items.First_Index;
            Best_Span      : Natural := Natural'Last;
            Has_Parent     : Boolean := False;
         begin
            for J in Result.Items.First_Index .. Result.Items.Last_Index loop
               if J /= I then
                  declare
                     Parent     : constant Editor.Outline.Outline_Item :=
                       Result.Items.Element (J);
                     Start_Line : constant Natural :=
                       Detail_Start_Line (To_String (Parent.Detail));
                     End_Line   : constant Natural :=
                       Detail_End_Line (To_String (Parent.Detail));
                     Span       : constant Natural :=
                       (if End_Line > Start_Line then End_Line - Start_Line else 0);
                  begin
                     if Has_Structure_Range (Parent)
                       and then (Start_Line < Child.Line
                                 or else (Start_Line = Child.Line
                                          and then Child.Kind in
                                            Editor.Outline.Outline_Discriminant
                                              | Editor.Outline.Outline_Enum_Literal))
                       and then Child.Line < End_Line
                       and then Span > 0
                       and then Span < Best_Span
                     then
                        Best_Parent := J;
                        Best_Span := Span;
                        Has_Parent := True;
                     end if;
                  end;
               end if;
            end loop;

            if Has_Parent then
               declare
                  Parent : constant Editor.Outline.Outline_Item :=
                    Result.Items.Element (Best_Parent);
                  Desired : constant Natural := Parent.Depth + 1;
               begin
                  if Child.Depth /= Desired then
                     Child.Depth := Desired;
                     Result.Items.Replace_Element (I, Child);
                  end if;
               end;
            end if;
         end;
      end loop;
   end Normalize_Depths_To_Nearest_Range;

   procedure Normalize_Same_Line_Enum_Literal_Depths
     (Result : in out Extraction_Result)
   is
   begin
      if Result.Items.Is_Empty then
         return;
      end if;

      for I in Result.Items.First_Index .. Result.Items.Last_Index loop
         declare
            Item : Editor.Outline.Outline_Item := Result.Items.Element (I);
         begin
            if Item.Kind = Editor.Outline.Outline_Enum_Literal then
               for J in reverse Result.Items.First_Index .. I loop
                  declare
                     Parent : constant Editor.Outline.Outline_Item :=
                       Result.Items.Element (J);
                  begin
                     if Parent.Kind = Editor.Outline.Outline_Type
                       and then Parent.Line = Item.Line
                       and then Starts_With (To_String (Parent.Label), "enum type ")
                     then
                        Item.Depth := Parent.Depth + 1;
                        Result.Items.Replace_Element (I, Item);
                        exit;
                     end if;
                  end;
               end loop;
            end if;
         end;
      end loop;
   end Normalize_Same_Line_Enum_Literal_Depths;

   function Has_Field_Row_For_Object
     (Result : Extraction_Result;
      Object : Editor.Outline.Outline_Item) return Boolean
   is
      Label : constant String := To_String (Object.Label);
      Name  : constant String :=
        (if Starts_With (Label, "object ")
         then Label (Label'First + 7 .. Label'Last)
         else "");
   begin
      if Name'Length = 0 then
         return False;
      end if;

      for Existing of Result.Items loop
         if Existing.Kind = Editor.Outline.Outline_Field
           and then Existing.Line = Object.Line
           and then To_String (Existing.Label) = "field " & Name
         then
            return True;
         end if;
      end loop;

      return False;
   end Has_Field_Row_For_Object;

   procedure Remove_Object_Field_Duplicates
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
         begin
            if Item.Kind = Editor.Outline.Outline_Object
              and then Has_Field_Row_For_Object (Result, Item)
            then
               Result.Items.Delete (I);
            end if;
         end;
      end loop;
   end Remove_Object_Field_Duplicates;

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

   function Is_Code_Line_Open
     (Lower_Line : String) return Boolean
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

   function Is_Code_Line_Begin (Lower_Line : String) return Boolean
   is
   begin
      return Starts_With_Word (Lower_Line, "begin");
   end Is_Code_Line_Begin;

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
        or else Starts_With_Word (Lower_Line, "procedure")
        or else Starts_With_Word (Lower_Line, "function")
        or else Starts_With_Word (Lower_Line, "task")
        or else Starts_With_Word (Lower_Line, "protected")
        or else Starts_With_Word (Lower_Line, "declare")
        or else Starts_With_Word (Lower_Line, "entry");
   end Declaration_Header_Starts_Construct;

   function Header_Start_Needs_Body_Begin
     (Lower_Line : String) return Boolean
   is
   begin
      return Starts_With_Phrase (Lower_Line, "package body ")
        or else Starts_With_Word (Lower_Line, "procedure")
        or else Starts_With_Word (Lower_Line, "function")
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

      --  Common one-line Ada constructs such as
      --     if Ready then null; end if;
      --  are lexically balanced on the same physical line.  Treat them as
      --  local noise for enclosing range matching so their opening keyword
      --  cannot consume the later end of the enclosing declaration/body.
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
      if not Starts_With_Word (Lower_Line, "end") then
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
      if not Starts_With_Word (Lower_Line, "end") then
         return "";
      end if;

      I := Lower_Line'First + 3;
      while I <= Lower_Line'Last
        and then (Lower_Line (I) = ' ' or else Lower_Line (I) = Ada.Characters.Latin_1.HT)
      loop
         I := I + 1;
      end loop;

      --  Skip the first word after "end".  For keyword closures such as
      --  "end loop Name;" or "end record Name;", the optional second word
      --  is the label/name qualifier that should be checked when a stack
      --  frame is label-bound.
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
      --  A plain "end;" is valid for the root construct and remains a
      --  safe best-effort close once nested constructs have been popped.
      if Name'Length = 0 then
         return True;
      end if;

      --  Named endings are only accepted when they match the declaration name.
      if Expected_Lowercase'Length > 0 and then Name = Expected_Lowercase then
         return True;
      end if;

      --  also treats keyword endings such as "end package;",
      --  "end protected;", and "end record;" as safe lexical closures
      --  for the matching construct kind without weakening the named-end guard.
      --  If a keyword ending also carries a trailing qualifier, require the
      --  qualifier to match the declaration name when one is known.
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
      if Starts_With_Word (Lower_Line, "if") then
         return "if";
      elsif Starts_With_Word (Lower_Line, "case") then
         return "case";
      elsif Starts_With_Word (Lower_Line, "loop")
        or else Starts_With_Word (Lower_Line, "for")
        or else Starts_With_Word (Lower_Line, "while")
      then
         return "loop";
      elsif Starts_With_Word (Lower_Line, "type")
        and then Has_Token (Lower_Line, "record")
      then
         return "record";
      elsif Starts_With_Word (Lower_Line, "select") then
         return "select";
      elsif Starts_With_Word (Lower_Line, "package") then
         return "package";
      elsif Starts_With_Word (Lower_Line, "procedure") then
         return "procedure";
      elsif Starts_With_Word (Lower_Line, "function") then
         return "function";
      elsif Starts_With_Word (Lower_Line, "task") then
         return "task";
      elsif Starts_With_Word (Lower_Line, "protected") then
         return "protected";
      elsif Starts_With_Word (Lower_Line, "entry") then
         return "entry";
      elsif Starts_With_Word (Lower_Line, "accept")
        or else Starts_With_Word (Lower_Line, "entry")
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
      if Starts_With_Word (Lower_Line, "accept") then
         return Read_Name (Lower_Line, Lower_Line'First + 6, True);
      elsif Starts_With_Word (Lower_Line, "entry") then
         return Read_Name (Lower_Line, Lower_Line'First + 5, True);
      elsif Keyword = ""
        or else Keyword = "if"
        or else Keyword = "case"
        or else Keyword = "loop"
        or else Keyword = "record"
      then
         if Starts_With_Word (Lower_Line, "type") then
            Start := Lower_Line'First + 4;
            return Read_Name (Lower_Line, Start, True);
         end if;

         return "";
      end if;

      Start := Lower_Line'First + Keyword'Length;
      if Keyword = "package"
        and then Starts_With_Phrase (Lower_Line, "package body ")
      then
         Start := Lower_Line'First + 12;
      elsif Keyword = "task" then
         if Starts_With_Phrase (Lower_Line, "task body ") then
            Start := Lower_Line'First + 10;
         elsif Starts_With_Phrase (Lower_Line, "task type ") then
            Start := Lower_Line'First + 10;
         end if;
      elsif Keyword = "protected" then
         if Starts_With_Phrase (Lower_Line, "protected body ") then
            Start := Lower_Line'First + 15;
         elsif Starts_With_Phrase (Lower_Line, "protected type ") then
            Start := Lower_Line'First + 15;
         end if;
      end if;

      if Keyword = "function" then
         return Read_Function_Name (Lower_Line, Start, True);
      else
         return Read_Name (Lower_Line, Start, True);
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

      --  Anonymous begin blocks close only on plain "end;".  A named or
      --  keyword end belongs to some enclosing/nested construct and must not
      --  silently consume an anonymous frame.
      if Expected_Close_Keyword'Length = 0
        and then Expected_Name'Length = 0
      then
         return Name'Length = 0;
      end if;

      --  Bodies, package/task/protected declarations, and local subprograms
      --  may close with plain "end;", their construct keyword, or their own
      --  declaration name.  A different named end must not close the frame.
      if Name'Length = 0 or else Name = Expected_Close_Keyword then
         return True;
      elsif Expected_Name'Length > 0 then
         return Name = Expected_Name;
      else
         return not Is_Structure_End_Keyword (Name);
      end if;
   end Stack_End_Matches;


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

   function Is_Code_Line_Close (Lower_Line : String) return Boolean
   is
   begin
      if not Starts_With_Word (Lower_Line, "end") then
         return False;
      end if;

      return Has_Code_Character (Lower_Line, ';');
   end Is_Code_Line_Close;

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
             Form_Needs_Body_Begin (Form)
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
               if Is_Code_Line_Close (Structure_Lower) then
                  if Natural (Stack.Length) = 1 then
                     if Root_End_Matches
                       (Structure_Lower, Expected_Lower_Name, Expected_Close_Keyword)
                     then
                        return L;
                     end if;
                  else
                     if Stack_End_Matches
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
                          (Structure_Close_Keyword_For_Open (Structure_Lower)),
                      Expected_Name =>
                        To_Unbounded_String (Structure_Name_For_Open (Structure_Lower))));
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
                          (Structure_Close_Keyword_For_Open (Structure_Lower)),
                      Expected_Name =>
                        To_Unbounded_String
                          ((if Block_Label'Length > 0
                            then Block_Label
                            else Structure_Name_For_Open (Structure_Lower)))));
               elsif Declaration_Header_Starts_Construct (Structure_Lower) then
                  Stack.Append
                    (Structure_Stack_Entry'
          (Needs_Body_Begin       => Header_Start_Needs_Body_Begin (Structure_Lower),
                      Pending_Header         => True,
                      Expected_Close_Keyword =>
                        To_Unbounded_String
                          (Structure_Close_Keyword_For_Open (Structure_Lower)),
                      Expected_Name =>
                        To_Unbounded_String
                          ((if Block_Label'Length > 0
                            then Block_Label
                            else Structure_Name_For_Open (Structure_Lower)))));
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
            Name      : constant String := Closing_Line_Name (Lower);
            Qualifier : constant String := Closing_Line_Qualifier (Lower);
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

   function Item_May_Have_Structure_Range
     (Item : Editor.Outline.Outline_Item) return Boolean
   is
      Detail : constant String := To_String (Item.Detail);
      Form   : constant String := Primary_Detail_Form (Detail);
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
            if Item_May_Have_Structure_Range (Item)
              and then Start_Line > 0
              and then Start_Line <= Natural (Lines.Length)
              and then Form /= "declaration"
              and then not (Form = "body"
                            and then Is_Separate_Body_Stub (Lines, Start_Line))
            then
               End_Line := Closing_Line_For
                 (Lines, Start_Line, Form,
                  (if Form = "record" or else Form = "variant" then ""
                   else Lowercase_Text (Last_Label_Word (To_String (Item.Label)))),
                  Expected_End_Keyword (Item, Form));
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


   function Outline_Kind_For_Symbol
     (Kind : Editor.Ada_Language_Model.Symbol_Kind)
      return Editor.Outline.Outline_Item_Kind
   is
      use Editor.Ada_Language_Model;
   begin
      case Kind is
         when Symbol_Package | Symbol_Generic_Package | Symbol_Rename | Symbol_Instantiation =>
            return Editor.Outline.Outline_Package;
         when Symbol_Package_Body =>
            return Editor.Outline.Outline_Package_Body;
         when Symbol_Procedure | Symbol_Generic_Subprogram =>
            return Editor.Outline.Outline_Procedure;
         when Symbol_Function | Symbol_Operator_Function =>
            return Editor.Outline.Outline_Function;
         when Symbol_Type | Symbol_Subtype | Symbol_Record_Type =>
            return Editor.Outline.Outline_Type;
         when Symbol_Task =>
            return Editor.Outline.Outline_Task;
         when Symbol_Protected =>
            return Editor.Outline.Outline_Protected;
         when Symbol_Entry | Symbol_Separate_Body =>
            --  Pass 177: separate bodies are navigable callable Outline rows.
            --  They keep their explicit label and Target_Name metadata in the
            --  language model, while the Outline kind must not degrade to
            --  Unknown or goto-spec cannot use the indexed parent target.
            return Editor.Outline.Outline_Subprogram;
         when Symbol_Record_Component =>
            return Editor.Outline.Outline_Field;
         when Symbol_Discriminant =>
            return Editor.Outline.Outline_Discriminant;
         when Symbol_Enumeration_Literal =>
            return Editor.Outline.Outline_Enum_Literal;
         when Symbol_Exception =>
            return Editor.Outline.Outline_Exception;
         when Symbol_Object | Symbol_Constant =>
            return Editor.Outline.Outline_Object;
         when Symbol_Generic_Formal_Type | Symbol_Generic_Formal_Object
            | Symbol_Generic_Formal_Subprogram | Symbol_Generic_Formal_Package =>
            return Editor.Outline.Outline_Generic_Formal;
         when others =>
            return Editor.Outline.Outline_Unknown;
      end case;
   end Outline_Kind_For_Symbol;


   function Type_Label_Prefix
     (Symbol : Editor.Ada_Language_Model.Symbol_Info) return String
   is
   begin
      if Symbol.Flags.Has_Variant_Record_Metadata then
         return "variant record type ";
      elsif Symbol.Flags.Has_Private_Extension_Metadata then
         return "private extension type ";
      elsif Symbol.Flags.Is_Private
        or else Symbol.Flags.Has_Limited_Metadata
      then
         return "private type ";
      elsif Symbol.Flags.Has_Array_Metadata then
         return "array type ";
      elsif Symbol.Flags.Has_Access_Subprogram_Metadata then
         return "access subprogram type ";
      elsif Symbol.Flags.Has_Access_Metadata then
         return "access type ";
      elsif Symbol.Flags.Has_Derived_Metadata
        and then Symbol.Flags.Has_Null_Record_Metadata
      then
         return "null extension type ";
      elsif Symbol.Flags.Has_Derived_Metadata then
         return "derived type ";
      elsif Symbol.Flags.Has_Interface_Metadata
        or else Symbol.Flags.Has_Task_Interface_Metadata
        or else Symbol.Flags.Has_Protected_Interface_Metadata
      then
         return "interface type ";
      elsif Symbol.Flags.Has_Tagged_Metadata then
         return "tagged type ";
      else
         return "type ";
      end if;
   end Type_Label_Prefix;

   function Formal_Type_Label_Prefix
     (Symbol : Editor.Ada_Language_Model.Symbol_Info) return String
   is
   begin
      if Symbol.Flags.Has_Array_Metadata then
         return "formal array type ";
      elsif Symbol.Flags.Has_Access_Subprogram_Metadata then
         return "formal access subprogram type ";
      elsif Symbol.Flags.Has_Access_Metadata then
         return "formal access type ";
      elsif Symbol.Flags.Has_Private_Extension_Metadata then
         return "formal private extension type ";
      elsif Symbol.Flags.Has_Derived_Metadata then
         return "formal derived type ";
      elsif Symbol.Flags.Has_Interface_Metadata
        or else Symbol.Flags.Has_Task_Interface_Metadata
        or else Symbol.Flags.Has_Protected_Interface_Metadata
      then
         return "formal interface type ";
      else
         return "formal type ";
      end if;
   end Formal_Type_Label_Prefix;

   function Has_Return_Profile
     (Symbol : Editor.Ada_Language_Model.Symbol_Info) return Boolean
   is
      Profile : constant String := Lowercase_Text (To_String (Symbol.Profile_Summary));
   begin
      return Ada.Strings.Fixed.Index (Profile, " return ") /= 0
        or else Starts_With (Profile, "return ");
   end Has_Return_Profile;

   function Callable_Display_Name
     (Symbol : Editor.Ada_Language_Model.Symbol_Info) return String
   is
      Name : constant String := To_String (Symbol.Name);
      Lower_Name : constant String := Lowercase_Text (Name);
      Return_Pos : constant Natural :=
        Ada.Strings.Fixed.Index (Lower_Name, " return ");
   begin
      if Return_Pos > Name'First then
         return Ada.Strings.Fixed.Trim
           (Name (Name'First .. Return_Pos - 1), Ada.Strings.Both);
      end if;

      return Name;
   end Callable_Display_Name;

   function Formal_Subprogram_Label_Prefix
     (Symbol : Editor.Ada_Language_Model.Symbol_Info) return String
   is
      Name : constant String := To_String (Symbol.Name);
   begin
      if Has_Return_Profile (Symbol)
        or else (Name'Length > 0 and then Name (Name'First) = '"')
      then
         return "formal function ";
      else
         return "formal procedure ";
      end if;
   end Formal_Subprogram_Label_Prefix;

   function Generic_Subprogram_Label_Prefix
     (Symbol : Editor.Ada_Language_Model.Symbol_Info) return String
   is
   begin
      if Has_Return_Profile (Symbol) then
         return "generic function ";
      else
         return "generic procedure ";
      end if;
   end Generic_Subprogram_Label_Prefix;

   function Symbol_Label
     (Symbol : Editor.Ada_Language_Model.Symbol_Info) return String
   is
      use Editor.Ada_Language_Model;
      Name : constant String := Callable_Display_Name (Symbol);
      Rename_Suffix : constant String := (if Symbol.Flags.Is_Rename then " renames" else "");
   begin
      case Symbol.Kind is
         when Symbol_Generic_Package =>
            return "generic package " & Name & Rename_Suffix;
         when Symbol_Package =>
            return "package " & Name & Rename_Suffix;
         when Symbol_Package_Body =>
            return "package body " & Name & Rename_Suffix;
         when Symbol_Procedure =>
            if Symbol.Flags.Is_Body then
               return "procedure body " & Name;
            else
               return "procedure " & Name & Rename_Suffix;
            end if;
         when Symbol_Function =>
            if Symbol.Flags.Has_Expression_Function_Metadata then
               return "expression function " & Name;
            elsif Symbol.Flags.Is_Body then
               return "function body " & Name;
            else
               return "function " & Name & Rename_Suffix;
            end if;
         when Symbol_Operator_Function =>
            if Symbol.Flags.Has_Expression_Function_Metadata then
               return "expression function " & Name;
            elsif Symbol.Flags.Is_Body then
               return "function body " & Name;
            else
               return "function " & Name & Rename_Suffix;
            end if;
         when Symbol_Generic_Subprogram =>
            declare
               Prefix : constant String := Generic_Subprogram_Label_Prefix (Symbol);
            begin
            if Symbol.Flags.Is_Body then
                  return Prefix & "body " & Name;
            else
                  return Prefix & Name;
            end if;
            end;
         when Symbol_Record_Type =>
            if Symbol.Flags.Has_Variant_Record_Metadata then
               return "variant record type " & Name;
            elsif Symbol.Flags.Has_Private_Extension_Metadata then
               return "private extension type " & Name;
            elsif Symbol.Flags.Has_Derived_Metadata
              and then Symbol.Flags.Has_Null_Record_Metadata
            then
               return "null extension type " & Name;
            elsif Symbol.Flags.Has_Derived_Metadata then
               return "record extension type " & Name;
            else
               return "record type " & Name;
            end if;
         when Symbol_Subtype =>
            return "subtype " & Name;
         when Symbol_Type =>
            return Type_Label_Prefix (Symbol) & Name;
         when Symbol_Record_Component =>
            return "field " & Name;
         when Symbol_Discriminant =>
            return "discriminant " & Name;
         when Symbol_Enumeration_Literal =>
            return "literal " & Name;
         when Symbol_Object =>
            return "object " & Name & Rename_Suffix;
         when Symbol_Constant =>
            return "constant " & Name & Rename_Suffix;
         when Symbol_Exception =>
            return "exception " & Name;
         when Symbol_Task =>
            if Symbol.Flags.Is_Body then
               return "task body " & Name;
            elsif Symbol.Flags.Has_Task_Type_Metadata then
               return "task type " & Name;
            else
               return "task " & Name;
            end if;
         when Symbol_Protected =>
            if Symbol.Flags.Is_Body then
               return "protected body " & Name;
            elsif Symbol.Flags.Has_Protected_Type_Metadata then
               return "protected type " & Name;
            else
               return "protected " & Name;
            end if;
         when Symbol_Entry =>
            if Symbol.Flags.Has_Entry_Family_Metadata then
               return "entry family " & Name;
            else
               return "entry " & Name;
            end if;
         when Symbol_Generic_Formal_Type =>
            return Formal_Type_Label_Prefix (Symbol) & Name;
         when Symbol_Generic_Formal_Object =>
            return "formal object " & Name;
         when Symbol_Generic_Formal_Subprogram =>
            return Formal_Subprogram_Label_Prefix (Symbol) & Name;
         when Symbol_Generic_Formal_Package =>
            return "formal package " & Name;
         when Symbol_Rename =>
            return "package " & Name & " renames";
         when Symbol_Instantiation =>
            return "package " & Name & " instantiation";
         when Symbol_Separate_Body =>
            return "separate body " & Name;
         when others =>
            return Name;
      end case;
   end Symbol_Label;

   function Symbol_Has_Child_Kind
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Parent   : Editor.Ada_Language_Model.Symbol_Id;
      Kind     : Editor.Ada_Language_Model.Symbol_Kind) return Boolean
   is
      use Editor.Ada_Language_Model;
   begin
      if Parent = No_Symbol then
         return False;
      end if;

      for Index in 1 .. Symbol_Count (Analysis) loop
         declare
            Child : constant Symbol_Info := Symbol_At (Analysis, Index);
         begin
            if Child.Parent_Symbol = Parent and then Child.Kind = Kind then
               return True;
            end if;
         end;
      end loop;

      return False;
   end Symbol_Has_Child_Kind;

   function Projected_Symbol_Label
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Symbol   : Editor.Ada_Language_Model.Symbol_Info) return String
   is
      use Editor.Ada_Language_Model;
      Name : constant String := Callable_Display_Name (Symbol);
   begin
      if Symbol.Kind = Symbol_Type
        and then Symbol_Has_Child_Kind
          (Analysis, Symbol.Id, Symbol_Enumeration_Literal)
      then
         return "enum type " & Name;
      end if;

      return Symbol_Label (Symbol);
   end Projected_Symbol_Label;

   function Symbol_Detail
     (Symbol : Editor.Ada_Language_Model.Symbol_Info) return String
   is
      use Editor.Ada_Language_Model;
      Line_Text : constant String := Ada.Strings.Fixed.Trim
        (Natural'Image (Symbol.Source_Span.Start_Line), Ada.Strings.Both);
      Profile : constant String := To_String (Symbol.Profile_Summary);
      Base_Form : constant String :=
        (case Symbol.Kind is
            when Symbol_Package => " spec",
            when Symbol_Record_Type =>
              (if Symbol.Flags.Has_Variant_Record_Metadata then " variant record" else " record"),
            when Symbol_Subtype => " subtype",
            when Symbol_Package_Body => " body",
            when Symbol_Procedure =>
              (if Symbol.Flags.Is_Body
                 or else Symbol.Flags.Has_Null_Subprogram_Metadata
                 or else Symbol.Flags.Has_Body_Stub_Metadata
               then " body"
               elsif Symbol.Flags.Is_Instantiation then " instantiation"
               else " declaration"),
            when Symbol_Function | Symbol_Operator_Function =>
              (if Symbol.Flags.Has_Expression_Function_Metadata then " expression"
               elsif Symbol.Flags.Is_Body
                 or else Symbol.Flags.Has_Body_Stub_Metadata
               then " body"
               elsif Symbol.Flags.Is_Instantiation then " instantiation"
               else " declaration"),
            when Symbol_Rename => " renames",
            when Symbol_Instantiation => " instantiation",
            when Symbol_Generic_Package => " spec",
            when Symbol_Generic_Subprogram =>
              (if Symbol.Flags.Is_Body
                 or else Symbol.Flags.Has_Body_Stub_Metadata
               then " body"
               elsif Symbol.Flags.Has_Expression_Function_Metadata then " expression"
               else " declaration"),
            when Symbol_Task =>
              (if Symbol.Flags.Is_Body then " body"
               elsif Symbol.Flags.Has_Task_Type_Metadata then " type"
               else " task"),
            when Symbol_Protected =>
              (if Symbol.Flags.Is_Body then " body"
               elsif Symbol.Flags.Has_Protected_Type_Metadata then " type"
               else " protected"),
            when Symbol_Entry => " declaration",
            when Symbol_Generic_Formal_Package =>
              (if Symbol.Flags.Has_Generic_Actual_Part_Metadata then
                  " generic formal package actuals"
               elsif Symbol.Flags.Has_Box_Metadata then
                  " generic formal package box"
               else
                  " generic formal package"),
            when Symbol_Generic_Formal_Subprogram =>
              (if Has_Return_Profile (Symbol) then
                  " generic formal function"
               else
                  " generic formal procedure"),
            when Symbol_Generic_Formal_Type => " generic formal type",
            when Symbol_Generic_Formal_Object => " generic formal object",
            when Symbol_Record_Component => " component",
            when Symbol_Discriminant => " discriminant",
            when Symbol_Enumeration_Literal => " enumeration",
            when Symbol_Object => " object",
            when Symbol_Constant => " constant",
            when Symbol_Exception => " exception",
            when others => "");
      Form : constant String :=
        (if Symbol.Flags.Is_Rename then " renames" else Base_Form);
      Abstract_Metadata : constant String :=
        (if Symbol.Flags.Is_Abstract then " abstract" else "");
      Overriding_Metadata : constant String :=
        (if Symbol.Flags.Is_Not_Overriding then " not-overriding"
         elsif Symbol.Flags.Is_Overriding then " overriding"
         else "");
      Representation : constant String :=
        (if Symbol.Flags.Has_Representation_Clause then " representation" else "");
      Aspect : constant String :=
        (if Symbol.Flags.Has_Aspect_Specification then " aspect" else "");
      Pragma_Metadata : constant String :=
        (if Symbol.Flags.Has_Pragma_Metadata then " pragma" else "");
      Null_Exclusion : constant String :=
        (if Symbol.Flags.Has_Null_Exclusion then " not-null" else "");
      Aliased_Metadata : constant String :=
        (if Symbol.Flags.Has_Aliased_Metadata then " aliased" else "");
      Limited_Metadata : constant String :=
        (if Symbol.Flags.Has_Limited_Metadata then " limited" else "");
      Tagged_Metadata : constant String :=
        (if Symbol.Flags.Has_Tagged_Metadata then " tagged" else "");
      Interface_Metadata : constant String :=
        (if Symbol.Flags.Has_Interface_Metadata then " interface" else "");
      Synchronized_Metadata : constant String :=
        (if Symbol.Flags.Has_Synchronized_Metadata then " synchronized" else "");
      Task_Interface_Metadata : constant String :=
        (if Symbol.Flags.Has_Task_Interface_Metadata then " task-interface" else "");
      Protected_Interface_Metadata : constant String :=
        (if Symbol.Flags.Has_Protected_Interface_Metadata then " protected-interface" else "");
      Task_Type_Metadata : constant String :=
        (if Symbol.Flags.Has_Task_Type_Metadata then " task-type" else "");
      Protected_Type_Metadata : constant String :=
        (if Symbol.Flags.Has_Protected_Type_Metadata then " protected-type" else "");
      Access_Metadata : constant String :=
        (if Symbol.Flags.Has_Access_Metadata then " access" else "");
      Access_All_Metadata : constant String :=
        (if Symbol.Flags.Has_Access_All_Metadata then " access-all" else "");
      Access_Constant_Metadata : constant String :=
        (if Symbol.Flags.Has_Access_Constant_Metadata then " access-constant" else "");
      Class_Wide_Metadata : constant String :=
        (if Symbol.Flags.Has_Class_Wide_Metadata then " class-wide" else "");
      Access_Subprogram_Metadata : constant String :=
        (if Symbol.Flags.Has_Access_Subprogram_Metadata then " access-subprogram" else "");
      Access_Protected_Metadata : constant String :=
        (if Symbol.Flags.Has_Access_Protected_Metadata then " access-protected" else "");
      Array_Metadata : constant String :=
        (if Symbol.Flags.Has_Array_Metadata then " array" else "");
      Derived_Metadata : constant String :=
        (if Symbol.Flags.Has_Derived_Metadata then " derived" else "");
      Range_Metadata : constant String :=
        (if Symbol.Flags.Has_Range_Metadata then " range" else "");
      Modular_Metadata : constant String :=
        (if Symbol.Flags.Has_Modular_Metadata then " mod" else "");
      Digits_Metadata : constant String :=
        (if Symbol.Flags.Has_Digits_Metadata then " digits" else "");
      Delta_Metadata : constant String :=
        (if Symbol.Flags.Has_Delta_Metadata then " delta" else "");
      Variant_Record_Metadata : constant String :=
        (if Symbol.Flags.Has_Variant_Record_Metadata then " variant-record" else "");
      Default_Expression_Metadata : constant String :=
        (if Symbol.Flags.Has_Default_Expression_Metadata then " default-expression" else "");
      Entry_Family_Metadata : constant String :=
        (if Symbol.Flags.Has_Entry_Family_Metadata then " entry-family" else "");
      Incomplete_Type_Metadata : constant String :=
        (if Symbol.Flags.Has_Incomplete_Type_Metadata then " incomplete-type" else "");
      Profile_Mode_Metadata : constant String :=
        (if Symbol.Flags.Has_Profile_Mode_Metadata then " profile-mode" else "");
      Entry_Barrier_Metadata : constant String :=
        (if Symbol.Flags.Has_Entry_Barrier_Metadata then " entry-barrier" else "");
      Box_Metadata : constant String :=
        (if Symbol.Flags.Has_Box_Metadata then " box" else "") &
        (if Symbol.Flags.Has_Private_Extension_Metadata then " private-extension" else "") &
        (if Symbol.Flags.Has_Named_Number_Metadata then " named-number" else "") &
        (if Symbol.Flags.Has_Deferred_Constant_Metadata then " deferred-constant" else "") &
        (if Symbol.Flags.Has_Null_Subprogram_Metadata then " null-subprogram" else "") &
        (if Symbol.Flags.Has_Expression_Function_Metadata then " expression-function" else "") &
        (if Symbol.Flags.Has_Null_Record_Metadata then " null-record" else "");
      Discriminant_Part_Metadata : constant String :=
        (if Symbol.Flags.Has_Discriminant_Part_Metadata then " discriminant-part" else "");
      Body_Stub_Metadata : constant String :=
        (if Symbol.Flags.Has_Body_Stub_Metadata then " body-stub" else "");
      Constraint_Metadata : constant String :=
        (if Symbol.Flags.Has_Constraint_Metadata then " constraint" else "") &
        (if Symbol.Flags.Has_Child_Unit_Metadata then " child-unit" else "") &
        (if Symbol.Flags.Has_Generic_Actual_Part_Metadata then " generic-actuals" else "");
   begin
      if Profile'Length > 0 then
         return "line " & Line_Text & Form & Abstract_Metadata & Overriding_Metadata & Representation & Aspect & Pragma_Metadata & Null_Exclusion & Aliased_Metadata & Limited_Metadata & Tagged_Metadata & Interface_Metadata & Synchronized_Metadata & Task_Interface_Metadata & Protected_Interface_Metadata & Task_Type_Metadata & Protected_Type_Metadata & Access_Metadata & Access_All_Metadata & Access_Constant_Metadata & Class_Wide_Metadata & Access_Subprogram_Metadata & Access_Protected_Metadata & Array_Metadata & Derived_Metadata & Range_Metadata & Modular_Metadata & Digits_Metadata & Delta_Metadata & Variant_Record_Metadata & Default_Expression_Metadata & Entry_Family_Metadata & Incomplete_Type_Metadata & Profile_Mode_Metadata & Entry_Barrier_Metadata & Box_Metadata & Discriminant_Part_Metadata & Body_Stub_Metadata & Constraint_Metadata & " " & Profile;
      end if;
      return "line " & Line_Text & Form & Abstract_Metadata & Overriding_Metadata & Representation & Aspect & Pragma_Metadata & Null_Exclusion & Aliased_Metadata & Limited_Metadata & Tagged_Metadata & Interface_Metadata & Synchronized_Metadata & Task_Interface_Metadata & Protected_Interface_Metadata & Task_Type_Metadata & Protected_Type_Metadata & Access_Metadata & Access_All_Metadata & Access_Constant_Metadata & Class_Wide_Metadata & Access_Subprogram_Metadata & Access_Protected_Metadata & Array_Metadata & Derived_Metadata & Range_Metadata & Modular_Metadata & Digits_Metadata & Delta_Metadata & Variant_Record_Metadata & Default_Expression_Metadata & Entry_Family_Metadata & Incomplete_Type_Metadata & Profile_Mode_Metadata & Entry_Barrier_Metadata & Box_Metadata & Discriminant_Part_Metadata & Body_Stub_Metadata & Constraint_Metadata;
   end Symbol_Detail;

   function Include_Symbol_In_Outline
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Info     : Editor.Ada_Language_Model.Symbol_Info) return Boolean
   is
      use Editor.Ada_Language_Model;

      function Parent_Is_Callable return Boolean is
         Parent : constant Symbol_Info := Symbol (Analysis, Info.Parent_Symbol);
      begin
         return Parent.Kind in Symbol_Procedure
           | Symbol_Function
           | Symbol_Operator_Function
           | Symbol_Generic_Subprogram
           | Symbol_Generic_Formal_Subprogram
           | Symbol_Entry
           | Symbol_Separate_Body;
      end Parent_Is_Callable;

      function Parent_Is_Record_Type return Boolean is
         Parent : constant Symbol_Info := Symbol (Analysis, Info.Parent_Symbol);
      begin
         return Parent.Kind = Symbol_Record_Type;
      end Parent_Is_Record_Type;
   begin
      if Info.Kind in Symbol_Object | Symbol_Constant | Symbol_Exception
        and then Parent_Is_Callable
      then
         return False;
      end if;

      if Info.Kind in Symbol_Object | Symbol_Constant
        and then Parent_Is_Record_Type
      then
         return False;
      end if;

      return True;
   end Include_Symbol_In_Outline;

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
