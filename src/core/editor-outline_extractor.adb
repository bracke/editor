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

   function Hash_String
     (Seed : Natural;
      Text : String) return Natural
   is
      H : Natural := Seed;
   begin
      for C of Text loop
         H := (H * 131 + Character'Pos (C) + 1) mod 2_147_483_647;
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
      H := (H * 131 + Item_Count (Result) + 1) mod 2_147_483_647;
      for Item of Result.Items loop
         H := (H * 131 + Natural (Editor.Outline.Outline_Item_Kind'Pos (Item.Kind)) + 1)
           mod 2_147_483_647;
         H := Hash_String (H, To_String (Item.Label));
         H := Hash_String (H, To_String (Item.Detail));
         H := (H * 131 + Item.Depth + 1) mod 2_147_483_647;
         H := (H * 131 + Natural (Editor.Outline.Outline_Target_Kind'Pos (Item.Target_Kind)) + 1)
           mod 2_147_483_647;
         H := (H * 131 + Item.Buffer_Token + 1) mod 2_147_483_647;
         H := (H * 131 + Item.Line + 1) mod 2_147_483_647;
         H := (H * 131 + Item.Column + 1) mod 2_147_483_647;
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
      Lower        : constant String := Ada.Strings.Fixed.Translate
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
            if I < Text'Last then
               Line_Start := I + 1;
            end if;
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
      Trimmed : constant String := Ada.Strings.Fixed.Trim (Line, Ada.Strings.Both);
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
      Trimmed : constant String := Ada.Strings.Fixed.Trim (Line, Ada.Strings.Both);
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
      --  Phase 551 range matching is deliberately lexical, but Phase 552
      --  requires every structure-normalization entry point to see only code.
      --  The current caller already supplies sanitized text, but sanitizing
      --  again here keeps this helper safe if future local structure code calls
      --  it directly with a raw lower-case line.  This remains transient and
      --  preserves columns because the same Ada lexical sanitizer is used.
      return Ada.Strings.Fixed.Trim (Stripped, Ada.Strings.Both);
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
            if I < Text'Last then
               Line_Start := I + 1;
            end if;
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

      --  Phase 551 also treats keyword endings such as "end package;",
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
      if Form = "record" then
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
   begin
      if Start_Line = 0 or else Lines.Is_Empty then
         return 0;
      end if;

      Stack.Append
        (Structure_Stack_Entry'
          (Needs_Body_Begin       => Form_Needs_Body_Begin (Form),
          Pending_Header         => False,
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
                  declare
                     Frame : Structure_Stack_Entry := Stack.Last_Element;
                  begin
                     Frame.Pending_Header := False;
                     Stack.Replace_Element (Stack.Last_Index, Frame);
                  end;
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

   function Item_May_Have_Structure_Range
     (Item : Editor.Outline.Outline_Item) return Boolean
   is
      Detail : constant String := To_String (Item.Detail);
      Form   : constant String := Detail_Form (Detail);
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
         return Form = "record";
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

      for Index in Result.Items.First_Index .. Result.Items.Last_Index loop
         declare
            Item       : Editor.Outline.Outline_Item := Result.Items.Element (Index);
            Start_Line : constant Natural := Detail_Start_Line (To_String (Item.Detail));
            End_Line   : Natural := 0;
            Form       : constant String := Detail_Form (To_String (Item.Detail));
         begin
            if Item_May_Have_Structure_Range (Item)
              and then Start_Line > 0
              and then Start_Line <= Natural (Lines.Length)
              and then not (Form = "body"
                            and then Is_Separate_Body_Stub (Lines, Start_Line))
            then
               End_Line := Closing_Line_For
                 (Lines, Start_Line, Form,
                  (if Form = "record" then ""
                   else Lowercase_Text (Last_Label_Word (To_String (Item.Label)))),
                  Expected_End_Keyword (Item, Form));
               if End_Line > Start_Line then
                  Item.Detail := To_Unbounded_String
                    (End_Line_Detail (Start_Line, End_Line, Form));
                  Result.Items.Replace_Element (Index, Item);
               end if;
            end if;
         end;
      end loop;
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
      elsif Symbol.Flags.Has_Array_Metadata then
         return "array type ";
      elsif Symbol.Flags.Has_Access_Subprogram_Metadata then
         return "access subprogram type ";
      elsif Symbol.Flags.Has_Access_Metadata then
         return "access type ";
      elsif Symbol.Flags.Has_Private_Extension_Metadata then
         return "private extension type ";
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

   function Symbol_Label
     (Symbol : Editor.Ada_Language_Model.Symbol_Info) return String
   is
      use Editor.Ada_Language_Model;
      Name : constant String := To_String (Symbol.Name);
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
            if Symbol.Flags.Is_Body then
               return "function body " & Name;
            else
               return "function " & Name & Rename_Suffix;
            end if;
         when Symbol_Operator_Function =>
            if Symbol.Flags.Is_Body then
               return "function body " & Name;
            else
               return "function " & Name & Rename_Suffix;
            end if;
         when Symbol_Generic_Subprogram =>
            if Symbol.Flags.Is_Body then
               return "generic subprogram body " & Name;
            else
               return "generic subprogram " & Name;
            end if;
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
            return "object " & Name;
         when Symbol_Constant =>
            return "constant " & Name;
         when Symbol_Exception =>
            return "exception " & Name;
         when Symbol_Task =>
            return "task " & Name;
         when Symbol_Protected =>
            return "protected " & Name;
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
            return "formal subprogram " & Name;
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

   function Symbol_Detail
     (Symbol : Editor.Ada_Language_Model.Symbol_Info) return String
   is
      use Editor.Ada_Language_Model;
      Line_Text : constant String := Ada.Strings.Fixed.Trim
        (Natural'Image (Symbol.Source_Span.Start_Line), Ada.Strings.Both);
      Profile : constant String := To_String (Symbol.Profile_Summary);
      Base_Form : constant String :=
        (case Symbol.Kind is
            when Symbol_Record_Type =>
              (if Symbol.Flags.Has_Variant_Record_Metadata then " variant record" else " record"),
            when Symbol_Subtype => " subtype",
            when Symbol_Package_Body => " body",
            when Symbol_Rename => " renames",
            when Symbol_Instantiation => " instantiation",
            when Symbol_Generic_Package | Symbol_Generic_Subprogram => " generic",
            when Symbol_Generic_Formal_Package =>
              (if Symbol.Flags.Has_Generic_Actual_Part_Metadata then
                  " generic formal package actuals"
               elsif Symbol.Flags.Has_Box_Metadata then
                  " generic formal package box"
               else
                  " generic formal package"),
            when Symbol_Generic_Formal_Subprogram => " generic formal subprogram",
            when Symbol_Generic_Formal_Type => " generic formal type",
            when Symbol_Generic_Formal_Object => " generic formal object",
            when Symbol_Record_Component => " component",
            when Symbol_Discriminant => " discriminant",
            when Symbol_Enumeration_Literal => " enumeration",
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

   procedure Append_Analysis_Result
     (Result   : in out Extraction_Result;
      Analysis : Editor.Ada_Language_Model.Analysis_Result)
   is
   begin
      for Index in 1 .. Editor.Ada_Language_Model.Symbol_Count (Analysis) loop
         declare
            Symbol : constant Editor.Ada_Language_Model.Symbol_Info :=
              Editor.Ada_Language_Model.Symbol_At (Analysis, Index);
         begin
            Result.Items.Append
              (Editor.Outline.Outline_Item'
          (Kind         => Outline_Kind_For_Symbol (Symbol.Kind),
                Label        => To_Unbounded_String (Symbol_Label (Symbol)),
                Detail       => To_Unbounded_String (Symbol_Detail (Symbol)),
                Depth        => Symbol.Depth,
                Target_Kind  => Editor.Outline.Buffer_Position_Target,
                Buffer_Token => Result.Result_Identity.Active_Buffer_Token,
                Line         => Symbol.Source_Span.Start_Line,
                Column       => Symbol.Source_Span.Start_Column));
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
      Line_Start  : Positive := Text'First;
      Line_Number : Positive := 1;
   begin
      if Text'Length = 0 then
         return Result;
      end if;

      declare
         Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
           Editor.Ada_Declaration_Parser.Parse
             (Text, To_String (Snapshot.Buffer_Label));
      begin
         if Editor.Ada_Language_Model.Symbol_Count (Analysis) > 0 then
            Append_Analysis_Result (Result, Analysis);
            Annotate_Local_Structure_Ranges (Result, Text);
            return Result;
         end if;
      end;

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
            if I < Text'Last then
               Line_Start := I + 1;
            end if;
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
