with Ada.Characters.Latin_1;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Text_Helpers;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Line_Metadata;
with Editor.Ada_Declaration_Parser.Pragma_Helpers;
with Editor.Ada_Declaration_Parser.Representation_Metadata;
with Editor.Ada_Syntax_Core;

package body Editor.Ada_Declaration_Parser.Metadata_Helpers is

   use Editor.Text_Helpers;
   use Editor.Ada_Declaration_Parser.Lexical_Helpers;
   use Editor.Ada_Declaration_Parser.Line_Metadata;
   use Editor.Ada_Declaration_Parser.Pragma_Helpers;
   use Editor.Ada_Declaration_Parser.Representation_Metadata;
   use Editor.Ada_Language_Model;

   function Has_Access_Subprogram_Metadata (Line : String) return Boolean is
      L : constant String := Lower (Line);
   begin
      return Ada.Strings.Fixed.Index (L, " access procedure") /= 0
        or else Ada.Strings.Fixed.Index (L, " access function") /= 0
        or else Ada.Strings.Fixed.Index (L, " access protected procedure") /= 0
        or else Ada.Strings.Fixed.Index (L, " access protected function") /= 0
        or else Starts_With_Subprogram_Keyword (Trim (L))
        or else Starts_With_Word (Trim (L), "protected procedure")
        or else Starts_With_Word (Trim (L), "protected function");
   end Has_Access_Subprogram_Metadata;

   function Has_Access_Protected_Metadata (Line : String) return Boolean is
      Code : constant String := Normalized_Line (Line);
   begin
      return Has_Token (Code, "access")
        and then Has_Token (Code, "protected")
        and then (Has_Token (Code, "procedure")
                  or else Has_Token (Code, "function"));
   end Has_Access_Protected_Metadata;

   function Has_Aliased_Metadata (Line : String) return Boolean is
      Code : constant String := Normalized_Line (Line);
   begin
      return Has_Token (Code, "aliased");
   end Has_Aliased_Metadata;

   function Has_Incomplete_Type_Metadata (Line : String) return Boolean is
      Code : constant String := Normalized_Line (Line);
      Decl : constant String := Trim (Code);
   begin
      --  Ada incomplete type declarations are declaration metadata.
      --  Retain the form on the owning type symbol without opening a
      --  language-model scope or learning following identifiers from a
      --  later completion declaration.  This covers both ordinary
      --  incomplete types and tagged incomplete types:
      --     type Node;
      --     type Root is tagged;
      if not Starts_With_Word (Decl, "type") then
         return False;
      end if;

      if not Has_Code_Char (Decl, ';') then
         return False;
      end if;

      if not Has_Token (Decl, "is") then
         return True;
      end if;

      return Has_Token (Decl, "tagged")
        and then not Has_Token (Decl, "record")
        and then not Has_Token (Decl, "private")
        and then not Has_Token (Decl, "interface")
        and then not Has_Token (Decl, "access")
        and then not Has_Token (Decl, "array")
        and then not Has_Token (Decl, "range")
        and then not Has_Token (Decl, "mod")
        and then not Has_Token (Decl, "digits")
        and then not Has_Token (Decl, "delta")
        and then not Has_Token (Decl, "new");
   end Has_Incomplete_Type_Metadata;

   function Has_Entry_Family_Metadata (Line : String) return Boolean is
      Code       : constant String := Normalized_Line (Line);
      Entry_Pos  : Natural := Ada.Strings.Fixed.Index (Code, "entry");
      Open_Pos   : Natural := 0;
      Close_Pos  : Natural := 0;
      Nesting    : Natural := 0;
   begin
      --  Ada entry families have an index subtype/discrete subtype part
      --  before the parameter profile.  Retain only bounded shape metadata on
      --  the entry declaration; the family index choices are not declarations.
      if Entry_Pos = 0
        or else not Starts_With_Word (Trim (Code), "entry")
      then
         return False;
      end if;

      Open_Pos := Ada.Strings.Fixed.Index (Code, "(", Entry_Pos + 5);
      if Open_Pos = 0 then
         return False;
      end if;

      for I in Open_Pos .. Code'Last loop
         if Code (I) = '(' then
            Nesting := Nesting + 1;
         elsif Code (I) = ')' then
            if Nesting = 1 then
               Close_Pos := I;
               exit;
            elsif Nesting > 0 then
               Nesting := Nesting - 1;
            end if;
         end if;
      end loop;

      if Close_Pos = 0 or else Close_Pos <= Open_Pos + 1 then
         return False;
      end if;

      declare
         Family_Index : constant String := Code (Open_Pos + 1 .. Close_Pos - 1);
         After_Group  : constant String :=
           (if Close_Pos < Code'Last then Code (Close_Pos + 1 .. Code'Last) else "");
      begin
         return Ada.Strings.Fixed.Index (Family_Index, ":") = 0
           and then (Ada.Strings.Fixed.Index (After_Group, "(") /= 0
                     or else Has_Token (Family_Index, "range")
                     or else Ada.Strings.Fixed.Index (Family_Index, "<>") /= 0);
      end;
   end Has_Entry_Family_Metadata;

   function Has_Class_Wide_Metadata (Line : String) return Boolean is
      Code : constant String := Normalized_Line (Line);
   begin
      return Ada.Strings.Fixed.Index (Code, "'class") /= 0
        or else Ada.Strings.Fixed.Index (Code, " class") /= 0;
   end Has_Class_Wide_Metadata;

   function Has_Aspect_Specification (Line : String) return Boolean is
      Code    : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      Lowered : constant String := Lower (Code);
      Nesting : Natural := 0;

      function Following_Word (Start : Natural) return String is
         I : Natural := Start;
         J : Natural;
      begin
         while I <= Code'Last
           and then (Code (I) = ' ' or else Code (I) = Ada.Characters.Latin_1.HT)
         loop
            I := I + 1;
         end loop;

         if I > Code'Last
           or else not ((Code (I) >= 'A' and then Code (I) <= 'Z')
                        or else (Code (I) >= 'a' and then Code (I) <= 'z'))
         then
            return "";
         end if;

         J := I;
         while J <= Code'Last and then Is_Word_Char (Code (J)) loop
            J := J + 1;
         end loop;

         return Lower (Code (I .. J - 1));
      end Following_Word;
   begin
      for I in Lowered'Range loop
         if Lowered (I) = '(' then
            Nesting := Nesting + 1;
         elsif Lowered (I) = ')' then
            if Nesting > 0 then
               Nesting := Nesting - 1;
            end if;
         elsif Nesting = 0 and then Lexical_Helpers.Starts_At_Word (Lowered, I, "with") then
            declare
               Next : constant String := Following_Word (I + 4);
            begin
               if I = Lowered'First
                 or else Next = "record"
                 or else Next = "private"
                 or else Next = "package"
                 or else Next = "procedure"
                 or else Next = "function"
                 or else Next = "type"
               then
                  null;
               else
                  return True;
               end if;
            end;
         elsif Lowered (I) = ';' then
            return False;
         end if;
      end loop;

      return False;
   end Has_Aspect_Specification;

   function Representation_Clause_Target (Line : String) return String is
      Code     : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      Lowered  : constant String := Lower (Code);
      Trimmed  : constant String := Trim (Lowered);
      For_Pos  : Natural := 0;
      Use_Pos  : Natural := 0;
      Stop     : Natural := 0;
   begin
      if not Starts_With_Word (Trimmed, "for") then
         return "";
      end if;

      For_Pos := Ada.Strings.Fixed.Index (Lowered, "for");
      Use_Pos := Ada.Strings.Fixed.Index (Lowered, " use " );
      if For_Pos = 0 or else Use_Pos = 0 or else Use_Pos <= For_Pos + 3 then
         return "";
      end if;

      declare
         Raw_Start  : constant Natural :=
           Code'First + (For_Pos - Lowered'First) + 3;
         Raw_Stop   : constant Natural :=
           Code'First + (Use_Pos - Lowered'First) - 1;
         Raw_Target : constant String := Trim (Code (Raw_Start .. Raw_Stop));
      begin
         if Raw_Target'Length = 0 then
            return "";
         end if;

         Stop := Raw_Target'Last;
         for I in Raw_Target'Range loop
            if Raw_Target (I) = Character'Val (39)
              or else Raw_Target (I) = ' '
              or else Raw_Target (I) = Ada.Characters.Latin_1.HT
            then
               Stop := I - 1;
               exit;
            end if;
         end loop;

         if Stop < Raw_Target'First then
            return "";
         end if;

         return Raw_Target (Raw_Target'First .. Stop);
      end;
   end Representation_Clause_Target;

   function Clean_Metadata_Name (Name : String) return String is
      T : constant String := Trim (Name);
   begin
      if T'Length > 0 and then T (T'Last) = ';' then
         if T'Last = T'First then
            return "";
         else
            return Trim (T (T'First .. T'Last - 1));
         end if;
      else
         return T;
      end if;
   end Clean_Metadata_Name;

   procedure Mark_Declaration_Form_Metadata
     (Flags : in out Declaration_Flags;
      Line  : String)
   is
      Code : constant String := Normalized_Line (Line);
   begin
      Flags.Has_Access_Metadata := Has_Token (Code, "access");
      Flags.Has_Access_All_Metadata := Has_Token_Pair (Code, "access", "all");
      Flags.Has_Access_Constant_Metadata := Has_Token_Pair (Code, "access", "constant");
      Flags.Has_Class_Wide_Metadata := Has_Class_Wide_Metadata (Code);
      Flags.Has_Access_Subprogram_Metadata :=
        Has_Token (Code, "access") and then Has_Access_Subprogram_Metadata (Code);
      Flags.Has_Access_Protected_Metadata := Has_Access_Protected_Metadata (Code);
      Flags.Has_Array_Metadata := Has_Token (Code, "array");
      Flags.Has_Range_Metadata := Has_Token (Code, "range");
      Flags.Has_Modular_Metadata := Has_Token (Code, "mod");
      Flags.Has_Digits_Metadata := Has_Token (Code, "digits");
      Flags.Has_Delta_Metadata := Has_Token (Code, "delta");
      Flags.Has_Variant_Record_Metadata := Has_Token (Code, "record") and then Has_Token (Code, "case");
      Flags.Has_Default_Expression_Metadata := Has_Default_Expression_Metadata (Code);
      Flags.Has_Entry_Family_Metadata := Has_Entry_Family_Metadata (Code);
      Flags.Has_Profile_Mode_Metadata := Has_Profile_Mode_Metadata (Code);
      Flags.Has_Entry_Barrier_Metadata := Has_Entry_Barrier_Metadata (Code);
      Flags.Has_Box_Metadata := Ada.Strings.Fixed.Index (Code, "<>") /= 0;
      Flags.Has_Named_Number_Metadata := Has_Named_Number_Metadata (Code);
      Flags.Has_Null_Subprogram_Metadata := Has_Null_Subprogram_Metadata (Code);
      Flags.Has_Expression_Function_Metadata := Has_Expression_Function_Metadata (Code);
      Flags.Has_Null_Record_Metadata := Has_Null_Record_Metadata (Code);
      Flags.Has_Discriminant_Part_Metadata := Has_Discriminant_Part_Metadata (Code);
      Flags.Has_Body_Stub_Metadata := Has_Body_Stub_Metadata (Code);
      Flags.Has_Constraint_Metadata := Has_Constraint_Metadata (Code);
      Flags.Has_Child_Unit_Metadata := Has_Child_Unit_Metadata (Code);
      Flags.Has_Task_Type_Metadata := Has_Token_Pair (Code, "task", "type");
      Flags.Has_Protected_Type_Metadata := Has_Token_Pair (Code, "protected", "type");
   end Mark_Declaration_Form_Metadata;

   procedure Mark_Type_Qualifier_Metadata
     (Flags : in out Declaration_Flags;
      Line  : String)
   is
      Code : constant String := Normalized_Line (Line);
   begin
      Flags.Has_Limited_Metadata := Has_Token (Code, "limited");
      Flags.Has_Tagged_Metadata := Has_Token (Code, "tagged");
      Flags.Has_Interface_Metadata := Has_Token (Code, "interface");
      Flags.Has_Synchronized_Metadata := Has_Token (Code, "synchronized");
      Flags.Has_Task_Interface_Metadata :=
        Has_Token_Pair (Code, "task", "interface");
      Flags.Has_Protected_Interface_Metadata :=
        Has_Token_Pair (Code, "protected", "interface");
      Flags.Has_Task_Type_Metadata := Has_Token_Pair (Code, "task", "type");
      Flags.Has_Protected_Type_Metadata := Has_Token_Pair (Code, "protected", "type");
      Flags.Has_Incomplete_Type_Metadata := Has_Incomplete_Type_Metadata (Line);
      Flags.Has_Private_Extension_Metadata := Has_Token_Pair (Code, "with", "private");
   end Mark_Type_Qualifier_Metadata;

   procedure Mark_Pragma_Target
     (Analysis      : in out Analysis_Result;
      Line          : String;
      Current_Scope : Symbol_Id := No_Symbol)
   is
      P : constant String := Pragma_Name_Of (Line);

      function Is_Current_Scope_Pragma (Name : String) return Boolean is
      begin
         return Name = "priority"
           or else Name = "interrupt_priority"
           or else Name = "cpu"
           or else Name = "dispatching_domain"
           or else Name = "relative_deadline"
           or else Name = "max_entry_queue_length"
           or else Name = "spark_mode"
           or else Name = "assertion_policy"
           or else Name = "check_policy"
           or else Name = "debug_policy"
           or else Name = "restrictions"
           or else Name = "restriction_warnings"
           or else Name = "profile";
      end Is_Current_Scope_Pragma;

      function Is_Multi_Entity_Pragma (Name : String) return Boolean is
      begin
         return Name = "inline"
           or else Name = "inline_always"
           or else Name = "no_inline"
           or else Name = "no_return"
           or else Name = "unreferenced"
           or else Name = "unmodified"
           or else Name = "weak_external"
           or else Name = "volatile"
           or else Name = "atomic"
           or else Name = "independent"
           or else Name = "discard_names";
      end Is_Multi_Entity_Pragma;

      procedure Apply_To_Target (Target : String) is
         Clean  : constant String := Trim (Pragma_Argument_Value (Target));
         Wanted : constant String := Normalize_Name (Clean);
      begin
         if Clean'Length = 0 then
            return;
         end if;

         for I in reverse 1 .. Symbol_Count (Analysis) loop
            declare
               Info : constant Symbol_Info := Symbol_At (Analysis, I);
            begin
               if To_String (Info.Normalized_Name) = Wanted then
                  Mark_Symbol_Pragma_Metadata (Analysis, Info.Id);
                  Add_Interfacing_Pragma_Representation
                    (Analysis,
                     Target_Symbol => Info.Id,
                     Target_Name => To_String (Info.Name),
                     Line => Line,
                     Source_Span => (1, 1, 1, 1));
                  Add_Representation_Pragma_Representation
                    (Analysis,
                     Target_Symbol => Info.Id,
                     Target_Name => To_String (Info.Name),
                     Line => Line,
                     Source_Span => (1, 1, 1, 1));
                  return;
               end if;
            end;
         end loop;
      end Apply_To_Target;

      Target : constant String := Pragma_Target (Line);
   begin
      if Is_Current_Scope_Pragma (P) then
         if Current_Scope /= No_Symbol then
            declare
               Info : constant Symbol_Info := Symbol (Analysis, Current_Scope);
            begin
               Mark_Symbol_Pragma_Metadata (Analysis, Current_Scope);
               Add_Representation_Pragma_Representation
                 (Analysis,
                  Target_Symbol => Current_Scope,
                  Target_Name => To_String (Info.Name),
                  Line => Line,
                  Source_Span => (1, 1, 1, 1));
            end;
         end if;
         return;
      end if;

      if Is_Multi_Entity_Pragma (P) then
         for A in 1 .. Pragma_Argument_Count (Line) loop
            declare
               Arg  : constant String := Pragma_Argument (Line, A);
               Name : constant String := Pragma_Argument_Name (Arg);
            begin
               if Name = "" then
                  Apply_To_Target (Arg);
               else
                  Apply_To_Target (Pragma_Argument_Value (Arg));
               end if;
            end;
         end loop;
         return;
      end if;

      if Target'Length = 0 then
         return;
      end if;

      Apply_To_Target (Target);
   end Mark_Pragma_Target;

   function Generic_Formal_Type_Family_From_Line
     (Line : String) return Generic_Formal_Type_Family
   is
      Code : constant String := Normalized_Line (Line);
   begin
      if Has_Token (Code, "new") and then not Has_Token (Code, "access") then
         return Generic_Formal_Type_Derived;
      elsif Has_Token (Code, "array") then
         return Generic_Formal_Type_Array;
      elsif Has_Token (Code, "access")
        and then Has_Access_Subprogram_Metadata (Line)
      then
         return Generic_Formal_Type_Access_Subprogram;
      elsif Has_Token (Code, "access") then
         return Generic_Formal_Type_Access_Object;
      elsif Has_Token (Code, "interface") then
         return Generic_Formal_Type_Interface;
      elsif Has_Token (Code, "mod") then
         return Generic_Formal_Type_Modular_Integer;
      elsif Has_Token (Code, "digits")
        and then not Has_Token (Code, "delta")
      then
         return Generic_Formal_Type_Floating_Point;
      elsif Has_Token (Code, "delta")
        and then Has_Token (Code, "digits")
      then
         return Generic_Formal_Type_Decimal_Fixed_Point;
      elsif Has_Token (Code, "delta") then
         return Generic_Formal_Type_Ordinary_Fixed_Point;
      elsif Has_Token (Code, "range") then
         return Generic_Formal_Type_Signed_Integer;
      elsif Ada.Strings.Fixed.Index (Code, "(<>)") /= 0
        or else Ada.Strings.Fixed.Index (Code, "( <> )") /= 0
        or else Ada.Strings.Fixed.Index (Code, "(< >)") /= 0
      then
         return Generic_Formal_Type_Discrete;
      elsif Has_Token (Code, "private") then
         return Generic_Formal_Type_Private;
      else
         return Generic_Formal_Type_Unknown;
      end if;
   end Generic_Formal_Type_Family_From_Line;

   function Is_Scope_End (Lower_Line : String) return Boolean is
   begin
      if not Starts_With_Word (Lower_Line, "end") then
         return False;
      end if;
      if Starts_With (Lower_Line, "end if")
        or else Starts_With (Lower_Line, "end loop")
        or else Starts_With (Lower_Line, "end case")
        or else Starts_With (Lower_Line, "end select")
      then
         return False;
      end if;
      return True;
   end Is_Scope_End;

   function First_Non_Blank_Column (Line : String) return Positive is
   begin
      for I in Line'Range loop
         if Line (I) /= ' ' and then Line (I) /= Ada.Characters.Latin_1.HT then
            return Positive (I - Line'First + 1);
         end if;
      end loop;
      return 1;
   end First_Non_Blank_Column;

end Editor.Ada_Declaration_Parser.Metadata_Helpers;
