with Ada.Strings.Fixed;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Metadata_Helpers;
with Editor.Ada_Declaration_Parser.Name_Profile_Helpers;
with Editor.Ada_Declaration_Parser.Target_Helpers;
with Editor.Ada_Syntax_Core;

package body Editor.Ada_Declaration_Parser.Same_Line_Emitters is

   use Editor.Ada_Declaration_Parser.Lexical_Helpers;
   use Editor.Ada_Declaration_Parser.Metadata_Helpers;
   use Editor.Ada_Declaration_Parser.Name_Profile_Helpers;
   use Editor.Ada_Declaration_Parser.Target_Helpers;

   procedure Add_Same_Line_Subtype_Groups
     (Analysis        : in out Analysis_Result;
      Raw_Line        : String;
      Line_Number     : Positive;
      Depth           : Natural;
      Parent          : Symbol_Id;
      Parent_Is_Private : Boolean)
   is
      Code          : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
      Segment_Start : Natural := Raw_Line'First;

      procedure Add_Segment
        (First : Natural;
         Last  : Natural)
      is
      begin
         if First > Last then
            return;
         end if;

         declare
            Segment       : constant String := Trim (Raw_Line (First .. Last));
            Segment_Lower : constant String := Lower (Segment);
         begin
            if not Starts_With_Word (Segment_Lower, "subtype") then
               return;
            end if;

            declare
               Segment_Name : constant String :=
                 Read_Name (Segment, Segment'First + 7, True);
               Name_Pos     : constant Natural :=
                 Ada.Strings.Fixed.Index (Raw_Line (First .. Last), Segment_Name);
               Col          : constant Positive :=
                 (if Name_Pos = 0
                  then First_Non_Blank_Column (Raw_Line)
                  else Positive (Name_Pos));
               Segment_Flags : constant Declaration_Flags :=
                 (Is_Private => Parent_Is_Private, others => False);
            begin
               if Segment_Name'Length /= 0 then
                  declare
                     Ignored : constant Symbol_Id := Add_Symbol
                       (Analysis, Segment_Name, Symbol_Subtype,
                        (Line_Number, Col, Line_Number,
                         Positive'Max (Col, Col + Segment_Name'Length - 1)),
                        Col, Enclosing_Scope => Scope_Id (Natural (Parent)),
                        Parent_Symbol => Parent, Depth => Depth,
                        Flags => Segment_Flags,
                        Target_Name => Subtype_Target_After_Is (Segment));
                  begin
                     null;
                  end;
               end if;
            end;
         end;
      end Add_Segment;
   begin
      for I in Code'Range loop
         if Code (I) = ';' then
            Add_Segment (Segment_Start, I - 1);
            Segment_Start := I + 1;
         end if;
      end loop;

      if Segment_Start <= Raw_Line'Last then
         Add_Segment (Segment_Start, Raw_Line'Last);
      end if;
   end Add_Same_Line_Subtype_Groups;

   procedure Add_Enumeration_Literals_From_Segment
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      First       : Natural;
      Last        : Natural;
      Owner       : Symbol_Id)
   is
      Code : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
      Open : Natural := 0;
      I    : Natural;
   begin
      for P in First .. Last loop
         if Code (P) = '(' then
            Open := P;
            exit;
         elsif Code (P) = ';' then
            return;
         end if;
      end loop;

      if Open = 0 then
         return;
      end if;

      I := Open + 1;
      while I <= Last loop
         if Code (I) = ')' or else Code (I) = ';' then
            return;
         elsif (Raw_Line (I) >= 'A' and then Raw_Line (I) <= 'Z')
           or else (Raw_Line (I) >= 'a' and then Raw_Line (I) <= 'z')
         then
            declare
               J : Natural := I;
            begin
               while J <= Last and then Is_Word_Char (Raw_Line (J)) loop
                  J := J + 1;
               end loop;

               declare
                  Ignored : constant Symbol_Id := Add_Symbol
                    (Analysis, Raw_Line (I .. J - 1), Symbol_Enumeration_Literal,
                     (Line_Number, Positive (I - Raw_Line'First + 1), Line_Number,
                      Positive (J - Raw_Line'First)),
                     Positive (I - Raw_Line'First + 1),
                     Enclosing_Scope => Scope_Id (Natural (Owner)),
                     Parent_Symbol => Owner, Depth => Depth + 1);
               begin
                  null;
               end;

               I := J;
            end;
         elsif Raw_Line (I) = Character'Val (16#27#)
           and then Editor.Ada_Syntax_Core.Looks_Like_Simple_Character_Literal
             (Raw_Line, I)
         then
            declare
               Char_Last : constant Natural :=
                 I + Editor.Ada_Syntax_Core.Simple_Character_Literal_Length
                   (Raw_Line, I) - 1;
            begin
               if Char_Last <= Last then
                  declare
                     Ignored : constant Symbol_Id := Add_Symbol
                       (Analysis, Raw_Line (I .. Char_Last),
                        Symbol_Enumeration_Literal,
                        (Line_Number, Positive (I - Raw_Line'First + 1),
                         Line_Number,
                         Positive (Char_Last - Raw_Line'First + 1)),
                        Positive (I - Raw_Line'First + 1),
                        Enclosing_Scope => Scope_Id (Natural (Owner)),
                        Parent_Symbol => Owner, Depth => Depth + 1);
                  begin
                     null;
                  end;
               end if;
               I := Char_Last + 1;
            end;
         else
            I := I + 1;
         end if;
      end loop;
   end Add_Enumeration_Literals_From_Segment;

   procedure Add_Same_Line_Type_Groups
     (Analysis        : in out Analysis_Result;
      Raw_Line        : String;
      Line_Number     : Positive;
      Depth           : Natural;
      Parent          : Symbol_Id;
      Parent_Is_Private : Boolean;
      Pending_Generic : Boolean)
   is
      Code          : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
      Segment_Start : Natural := Raw_Line'First;
      Nesting       : Natural := 0;

      procedure Add_Segment
        (First : Natural;
         Last  : Natural)
      is
      begin
         if First > Last then
            return;
         end if;

         declare
            Segment       : constant String := Trim (Raw_Line (First .. Last));
            Segment_Lower : constant String := Lower (Segment);
         begin
            if not Starts_With_Word (Segment_Lower, "type") then
               return;
            end if;

            declare
               Segment_Name  : constant String :=
                 Read_Name (Segment, Segment'First + 4, True);
               Name_Pos      : constant Natural :=
                 Ada.Strings.Fixed.Index (Raw_Line (First .. Last), Segment_Name);
               Col           : constant Positive :=
                 (if Name_Pos = 0 then First_Non_Blank_Column (Raw_Line)
                  else Positive (Name_Pos - Raw_Line'First + 1));
               Segment_Kind  : constant Symbol_Kind :=
                 (if Pending_Generic then
                    Symbol_Generic_Formal_Type
                  elsif Has_Token (Segment_Lower, "record") then
                    Symbol_Record_Type
                  else
                    Symbol_Type);
               Segment_Flags : constant Declaration_Flags :=
                 (Is_Private => Parent_Is_Private
                    or else Has_Token (Segment_Lower, "private"),
                  Is_Generic => Pending_Generic,
                  Has_Limited_Metadata => Has_Token (Segment_Lower, "limited"),
                  Has_Tagged_Metadata => Has_Token (Segment_Lower, "tagged"),
                  Has_Interface_Metadata => Has_Token (Segment_Lower, "interface"),
                  Has_Synchronized_Metadata => Has_Token (Segment_Lower, "synchronized"),
                  Has_Task_Interface_Metadata =>
                    Has_Token_Pair (Segment_Lower, "task", "interface"),
                  Has_Protected_Interface_Metadata =>
                    Has_Token_Pair (Segment_Lower, "protected", "interface"),
                  Has_Task_Type_Metadata =>
                    Has_Token_Pair (Segment_Lower, "task", "type"),
                  Has_Protected_Type_Metadata =>
                    Has_Token_Pair (Segment_Lower, "protected", "type"),
                  Has_Access_Metadata => Has_Token (Segment_Lower, "access"),
                  Has_Access_All_Metadata =>
                    Has_Token_Pair (Segment_Lower, "access", "all"),
                  Has_Access_Constant_Metadata =>
                    Has_Token_Pair (Segment_Lower, "access", "constant"),
                  Has_Class_Wide_Metadata => Has_Class_Wide_Metadata (Segment),
                  Has_Access_Subprogram_Metadata =>
                    Has_Token (Segment_Lower, "access")
                    and then Has_Access_Subprogram_Metadata (Segment),
                  Has_Access_Protected_Metadata =>
                    Has_Token (Segment_Lower, "access")
                    and then Has_Token (Segment_Lower, "protected")
                    and then (Has_Token (Segment_Lower, "procedure")
                              or else Has_Token (Segment_Lower, "function")),
                  Has_Array_Metadata => Has_Token (Segment_Lower, "array"),
                  Has_Derived_Metadata =>
                    Has_Token (Segment_Lower, "new")
                    and then not Has_Token (Segment_Lower, "access"),
                  Has_Private_Extension_Metadata =>
                    Has_Token_Pair (Segment_Lower, "with", "private"),
                  Has_Range_Metadata => Has_Token (Segment_Lower, "range"),
                  Has_Modular_Metadata => Has_Token (Segment_Lower, "mod"),
                  Has_Digits_Metadata => Has_Token (Segment_Lower, "digits"),
                  Has_Delta_Metadata => Has_Token (Segment_Lower, "delta"),
                  Has_Variant_Record_Metadata =>
                    Has_Token (Segment_Lower, "record")
                    and then Has_Token (Segment_Lower, "case"),
                  Has_Default_Expression_Metadata =>
                    Ada.Strings.Fixed.Index
                      (Editor.Ada_Syntax_Core.Sanitize_Line (Segment), ":=") /= 0,
                  Has_Constraint_Metadata =>
                    Ada.Strings.Fixed.Index
                      (Editor.Ada_Syntax_Core.Sanitize_Line (Segment), "(") /= 0,
                  others => False);
               Target_Value  : String (1 .. 256) := (others => ' ');
               Target_Len    : Natural := 0;
               Profile_Value : String (1 .. 256) := (others => ' ');
               Profile_Len   : Natural := 0;
               New_Id        : Symbol_Id := No_Symbol;

               procedure Set_Local_Target (Value : String) is
                  Len : constant Natural := Natural'Min (Value'Length, Target_Value'Length);
               begin
                  Target_Len := Len;
                  if Len > 0 then
                     Target_Value (1 .. Len) :=
                       Value (Value'First .. Value'First + Len - 1);
                  end if;
               end Set_Local_Target;

               procedure Set_Local_Profile (Value : String) is
                  Len : constant Natural := Natural'Min (Value'Length, Profile_Value'Length);
               begin
                  Profile_Len := Len;
                  if Len > 0 then
                     Profile_Value (1 .. Len) :=
                       Value (Value'First .. Value'First + Len - 1);
                  end if;
               end Set_Local_Profile;
            begin
               if Segment_Name'Length = 0 then
                  return;
               end if;

               if Has_Token (Segment_Lower, "new")
                 and then not Has_Token (Segment_Lower, "access")
               then
                  Set_Local_Target (Target_After (Segment, "new"));
               elsif Has_Token (Segment_Lower, "array") then
                  Set_Local_Target (Array_Element_Target (Segment));
               elsif Has_Token (Segment_Lower, "access") then
                  Set_Local_Target (Access_Object_Target (Segment));
                  Set_Local_Profile (Access_Subprogram_Profile (Segment));
               elsif Has_Token (Segment_Lower, "interface") then
                  Set_Local_Target (Interface_Parent_Target (Segment));
               end if;

               New_Id := Add_Symbol
                 (Analysis, Segment_Name, Segment_Kind,
                  (Line_Number, Col, Line_Number,
                   Positive'Max (Col, Col + Segment_Name'Length - 1)),
                  Col, Enclosing_Scope => Scope_Id (Natural (Parent)),
                  Parent_Symbol => Parent, Depth => Depth,
                  Profile_Summary =>
                    (if Profile_Len = 0 then "" else Profile_Value (1 .. Profile_Len)),
                  Flags => Segment_Flags,
                  Target_Name =>
                    (if Target_Len = 0 then "" else Target_Value (1 .. Target_Len)));

               if New_Id /= No_Symbol
                 and then Segment_Kind = Symbol_Generic_Formal_Type
               then
                  Add_Generic_Formal_Type_Metadata
                    (Analysis, New_Id, Segment_Name,
                     Generic_Formal_Type_Family_From_Line (Segment),
                     Target_Type_Text =>
                       (if Target_Len = 0 then "" else Target_Value (1 .. Target_Len)),
                     Profile_Text =>
                       (if Profile_Len = 0 then "" else Profile_Value (1 .. Profile_Len)),
                     Has_Private => Has_Token (Segment_Lower, "private"),
                     Has_Limited => Segment_Flags.Has_Limited_Metadata,
                     Has_Tagged => Segment_Flags.Has_Tagged_Metadata,
                     Has_Abstract => Segment_Flags.Is_Abstract,
                     Has_Synchronized => Segment_Flags.Has_Synchronized_Metadata,
                     Has_Interface => Segment_Flags.Has_Interface_Metadata,
                     Has_Box => Ada.Strings.Fixed.Index (Segment_Lower, "<>") /= 0,
                     Has_Discriminant_Part =>
                       Ada.Strings.Fixed.Index (Segment_Lower, "(") /= 0
                       and then Ada.Strings.Fixed.Index (Segment_Lower, ":") /= 0,
                     Source_Span => (Line_Number, Col, Line_Number,
                               Positive'Max (Col, Col + Segment_Name'Length - 1)));
               end if;

               if New_Id /= No_Symbol
                 and then Segment_Kind = Symbol_Type
                 and then not Pending_Generic
                 and then Ada.Strings.Fixed.Index (Segment_Lower, "(") /= 0
                 and then not Has_Token (Segment_Lower, "record")
                 and then not Has_Token (Segment_Lower, "array")
                 and then not Has_Token (Segment_Lower, "range")
                 and then not Has_Token (Segment_Lower, "access")
               then
                  Add_Enumeration_Literals_From_Segment
                    (Analysis, Raw_Line, Line_Number, Depth, First, Last, New_Id);
               end if;
            end;
         end;
      end Add_Segment;
   begin
      for I in Code'Range loop
         if Code (I) = '(' then
            Nesting := Nesting + 1;
         elsif Code (I) = ')' then
            if Nesting > 0 then
               Nesting := Nesting - 1;
            end if;
         elsif Code (I) = ';' and then Nesting = 0 then
            Add_Segment (Segment_Start, I - 1);
            Segment_Start := I + 1;
         end if;
      end loop;

      if Segment_Start <= Raw_Line'Last then
         Add_Segment (Segment_Start, Raw_Line'Last);
      end if;
   end Add_Same_Line_Type_Groups;

end Editor.Ada_Declaration_Parser.Same_Line_Emitters;
