with Ada.Characters.Latin_1;
with Ada.Strings.Fixed;
with Editor.Text_Helpers;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Metadata_Helpers;

package body Editor.Ada_Declaration_Parser.Line_Metadata is
   use Editor.Text_Helpers;

   function Has_Token (Line, Token : String) return Boolean
      renames Editor.Ada_Declaration_Parser.Lexical_Helpers.Has_Token;

   function Has_Token_Pair
     (Line, First_Token, Second_Token : String) return Boolean
      renames Editor.Ada_Declaration_Parser.Lexical_Helpers.Has_Token_Pair;

   function Has_Code_Char (Line : String; C : Character) return Boolean
     renames Editor.Ada_Declaration_Parser.Lexical_Helpers.Has_Code_Char;

   function Starts_With_Subprogram_Keyword (Text : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Lexical_Helpers.Starts_With_Subprogram_Keyword;

   function Has_Default_Expression_Metadata (Line : String) return Boolean is
      Code : constant String := Normalized_Line (Line);
      I    : Natural := Code'First;
   begin
      while I < Code'Last loop
         if Code (I) = ':' and then Code (I + 1) = '=' then
            return True;
         end if;
         I := I + 1;
      end loop;
      return False;
   end Has_Default_Expression_Metadata;

   function Has_Entry_Family_Metadata
     (Line : String) return Boolean
   is
   begin
      return Metadata_Helpers.Has_Entry_Family_Metadata (Line);
   end Has_Entry_Family_Metadata;

   function Has_Profile_Mode_Metadata
     (Line : String) return Boolean
   is
      Code      : constant String := Normalized_Line (Line);
      Open_Pos  : constant Natural := Ada.Strings.Fixed.Index (Code, "(");
      Close_Pos : constant Natural := Ada.Strings.Fixed.Index (Code, ")");
   begin
      if Open_Pos = 0 or else Close_Pos = 0 or else Close_Pos <= Open_Pos then
         return False;
      end if;

      declare
         Profile_Text : constant String := Code (Open_Pos + 1 .. Close_Pos - 1);
      begin
         return Has_Token (Profile_Text, "out")
           or else Has_Token (Profile_Text, "access");
      end;
   end Has_Profile_Mode_Metadata;

   function Has_Entry_Barrier_Metadata
     (Line : String) return Boolean
   is
      Code : constant String := Normalized_Line (Line);
      Decl : constant String := Trim (Code);
   begin
      return Starts_With_Word (Decl, "entry")
        and then Has_Token (Decl, "when");
   end Has_Entry_Barrier_Metadata;

   function Has_Class_Wide_Metadata
     (Line : String) return Boolean
   is
   begin
      return Metadata_Helpers.Has_Class_Wide_Metadata (Line);
   end Has_Class_Wide_Metadata;

   function Has_Named_Number_Metadata
     (Line : String) return Boolean
   is
      Code      : constant String := Normalized_Line (Line);
      Colon_Pos : constant Natural := Ada.Strings.Fixed.Index (Code, ":");
   begin
      if Colon_Pos = 0 or else Colon_Pos >= Code'Last then
         return False;
      end if;

      declare
         Tail       : constant String := Code (Colon_Pos + 1 .. Code'Last);
         Const_Pos  : constant Natural := Ada.Strings.Fixed.Index (Tail, "constant");
         Assign_Pos : Natural := 0;
      begin
         if Const_Pos = 0 then
            return False;
         end if;

         declare
            After_Constant_First : constant Natural := Const_Pos + 8;
         begin
            if After_Constant_First <= Tail'Last then
               Assign_Pos := Ada.Strings.Fixed.Index (Tail, ":=", After_Constant_First);
            end if;
         end;

         if Assign_Pos = 0 then
            return False;
         end if;

         declare
            Between : constant String := Trim (Tail (Const_Pos + 8 .. Assign_Pos - 1));
         begin
            return Between'Length = 0;
         end;
      end;
   end Has_Named_Number_Metadata;

   function Has_Deferred_Constant_Metadata
     (Line : String) return Boolean
   is
      Code      : constant String := Normalized_Line (Line);
      Colon_Pos : constant Natural := Ada.Strings.Fixed.Index (Code, ":");
   begin
      if Colon_Pos = 0 or else Colon_Pos >= Code'Last then
         return False;
      end if;

      declare
         Tail      : constant String := Code (Colon_Pos + 1 .. Code'Last);
         Const_Pos : constant Natural := Ada.Strings.Fixed.Index (Tail, "constant");
      begin
         return Const_Pos /= 0
           and then Ada.Strings.Fixed.Index (Tail, ":=") = 0
           and then Ada.Strings.Fixed.Index (Tail, ";") /= 0;
      end;
   end Has_Deferred_Constant_Metadata;

   function Has_Null_Subprogram_Metadata
     (Line : String) return Boolean
   is
      Code : constant String := Normalized_Line (Line);
      Decl : constant String := Trim (Code);
   begin
      return (Starts_With_Subprogram_Keyword (Decl)
              or else Starts_With (Decl, "overriding procedure")
              or else Starts_With (Decl, "not overriding procedure"))
        and then Has_Token (Decl, "is")
        and then Has_Token (Decl, "null");
   end Has_Null_Subprogram_Metadata;

   function Has_Expression_Function_Metadata
     (Line : String) return Boolean
   is
      Code : constant String := Normalized_Line (Line);
      Decl : constant String := Trim (Code);
      Is_Pos : constant Natural := Ada.Strings.Fixed.Index (Decl, " is ");
   begin
      if not (Starts_With_Subprogram_Keyword (Decl)
              or else Starts_With (Decl, "overriding function")
              or else Starts_With (Decl, "not overriding function")) then
         return False;
      end if;

      if Is_Pos = 0 or else Is_Pos + 4 > Decl'Last then
         return False;
      end if;

      declare
         Tail : constant String := Decl (Is_Pos + 4 .. Decl'Last);
      begin
         return Ada.Strings.Fixed.Index (Tail, "(") /= 0
           and then Has_Code_Char (Tail, ';');
      end;
   end Has_Expression_Function_Metadata;

   function Has_Null_Record_Metadata
     (Line : String) return Boolean
   is
      Code : constant String := Normalized_Line (Line);
   begin
      return Has_Token_Pair (Code, "null", "record");
   end Has_Null_Record_Metadata;

   function Has_Discriminant_Part_Metadata
     (Line : String) return Boolean
   is
      Code : constant String := Normalized_Line (Line);
      Decl : constant String := Trim (Code);
      Is_Pos : constant Natural := Ada.Strings.Fixed.Index (Decl, " is ");
      Open_Pos : constant Natural := Ada.Strings.Fixed.Index (Decl, "(");
      Close_Pos : constant Natural := Ada.Strings.Fixed.Index (Decl, ")");
   begin
      return Starts_With_Word (Decl, "type")
        and then Open_Pos /= 0
        and then Close_Pos /= 0
        and then Open_Pos < Close_Pos
        and then (Is_Pos = 0 or else Close_Pos < Is_Pos);
   end Has_Discriminant_Part_Metadata;

   function Has_Body_Stub_Metadata
     (Line : String) return Boolean
   is
      Code : constant String := Normalized_Line (Line);
      Decl : constant String := Trim (Code);
   begin
      if Starts_With_Word (Decl, "separate") then
         return False;
      end if;

      return Has_Token_Pair (Decl, "is", "separate")
        and then Has_Code_Char (Decl, ';')
        and then (Starts_With_Word (Decl, "package")
                  or else Starts_With_Subprogram_Keyword (Decl)
                  or else Starts_With_Word (Decl, "task")
                  or else Starts_With_Word (Decl, "protected")
                  or else Starts_With (Decl, "overriding procedure")
                  or else Starts_With (Decl, "overriding function")
                  or else Starts_With (Decl, "not overriding procedure")
                  or else Starts_With (Decl, "not overriding function"));
   end Has_Body_Stub_Metadata;

   function Has_Constraint_Metadata
     (Line : String) return Boolean
   is
      Code      : constant String := Normalized_Line (Line);
      Decl      : constant String := Trim (Code);
      Open_Pos  : constant Natural := Ada.Strings.Fixed.Index (Code, "(");
      Close_Pos : constant Natural := Ada.Strings.Fixed.Index (Code, ")");
      Colon_Pos : constant Natural := Ada.Strings.Fixed.Index (Code, ":");
   begin
      if Open_Pos = 0 or else Close_Pos = 0 or else Close_Pos < Open_Pos then
         return False;
      end if;

      if Starts_With_Subprogram_Keyword (Decl)
        or else Starts_With_Word (Decl, "entry")
        or else Starts_With_Word (Decl, "package")
        or else Starts_With (Decl, "overriding procedure")
        or else Starts_With (Decl, "overriding function")
        or else Starts_With (Decl, "not overriding procedure")
        or else Starts_With (Decl, "not overriding function")
      then
         return False;
      end if;

      if Starts_With_Word (Decl, "subtype") then
         return True;
      end if;

      if Starts_With_Word (Decl, "type") then
         return Has_Token (Code, "array") or else Has_Token (Code, "record");
      end if;

      return Colon_Pos /= 0 and then Colon_Pos < Open_Pos;
   end Has_Constraint_Metadata;

   function Has_Child_Unit_Metadata
     (Line : String) return Boolean
   is
      Code : constant String := Normalized_Line (Line);
      Decl : constant String := Trim (Code);
      Start_Pos : Natural := Decl'First;
      Name_Start : Natural := 0;
      Name_End   : Natural := 0;
   begin
      if Starts_With_Word (Decl, "private") then
         Start_Pos := Decl'First + 7;
         while Start_Pos <= Decl'Last
           and then (Decl (Start_Pos) = ' '
                     or else Decl (Start_Pos) = Ada.Characters.Latin_1.HT)
         loop
            Start_Pos := Start_Pos + 1;
         end loop;
      end if;

      if Start_Pos > Decl'Last then
         return False;
      end if;

      if Start_Pos + 6 <= Decl'Last
        and then Starts_With_Word (Decl (Start_Pos .. Decl'Last), "package")
      then
         Name_Start := Start_Pos + 7;
         while Name_Start <= Decl'Last
           and then (Decl (Name_Start) = ' '
                     or else Decl (Name_Start) = Ada.Characters.Latin_1.HT)
         loop
            Name_Start := Name_Start + 1;
         end loop;
         if Name_Start + 3 <= Decl'Last
           and then Starts_With_Word (Decl (Name_Start .. Decl'Last), "body")
         then
            Name_Start := Name_Start + 4;
         end if;
      elsif Start_Pos + 8 <= Decl'Last
        and then Starts_With_Subprogram_Keyword (Decl (Start_Pos .. Decl'Last))
      then
         Name_Start := Start_Pos + 9;
      elsif Start_Pos + 7 <= Decl'Last
        and then Starts_With_Subprogram_Keyword (Decl (Start_Pos .. Decl'Last))
      then
         Name_Start := Start_Pos + 8;
      else
         return False;
      end if;

      while Name_Start <= Decl'Last
        and then (Decl (Name_Start) = ' '
                  or else Decl (Name_Start) = Ada.Characters.Latin_1.HT)
      loop
         Name_Start := Name_Start + 1;
      end loop;

      if Name_Start > Decl'Last then
         return False;
      end if;

      Name_End := Name_Start;
      while Name_End <= Decl'Last
        and then (Is_Word_Char (Decl (Name_End)) or else Decl (Name_End) = '.')
      loop
         Name_End := Name_End + 1;
      end loop;

      if Name_End <= Name_Start then
         return False;
      end if;

      declare
         Defining_Name : constant String := Decl (Name_Start .. Name_End - 1);
      begin
         return Ada.Strings.Fixed.Index (Defining_Name, ".") /= 0;
      end;
   end Has_Child_Unit_Metadata;

   function Has_Generic_Actual_Part_Metadata
     (Line : String) return Boolean
   is
      Code    : constant String := Normalized_Line (Line);
      New_Pos : constant Natural := Ada.Strings.Fixed.Index (Code, "new");
   begin
      return New_Pos /= 0
        and then Ada.Strings.Fixed.Index (Code, "(", New_Pos + 3) /= 0;
   end Has_Generic_Actual_Part_Metadata;

end Editor.Ada_Declaration_Parser.Line_Metadata;
