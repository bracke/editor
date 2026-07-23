with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Text_Helpers;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Range_Structure_Helpers;
with Editor.Ada_Declaration_Parser.Representation_Static_Values;
with Editor.Ada_Declaration_Parser.Representation_Target_Helpers;

package body Editor.Ada_Declaration_Parser.Attribute_Value_Helpers is

   use Editor.Text_Helpers;
   use Editor.Ada_Declaration_Parser.Lexical_Helpers;
   use Editor.Ada_Language_Model;
   use Editor.Ada_Declaration_Parser.Range_Structure_Helpers;
   use Editor.Ada_Declaration_Parser.Representation_Static_Values;
   use Editor.Ada_Declaration_Parser.Representation_Target_Helpers;

   function Is_Stream_Operational_Attribute
     (Name : Unbounded_String) return Boolean is
      A : constant String := Lower (To_String (Name));
   begin
      return A = "read" or else A = "write"
        or else A = "input" or else A = "output";
   end Is_Stream_Operational_Attribute;

   function Is_Stream_Input_Attribute
     (Name : Unbounded_String) return Boolean is
   begin
      return Lower (To_String (Name)) = "input";
   end Is_Stream_Input_Attribute;

   function Is_Operational_Attribute
     (Name : Unbounded_String) return Boolean is
      A : constant String := Lower (To_String (Name));
   begin
      return Is_Stream_Operational_Attribute (Name)
        or else A = "put_image"
        or else A = "constant_indexing"
        or else A = "variable_indexing"
        or else A = "implicit_dereference"
        or else A = "default_iterator"
        or else A = "iterator_element"
        or else A = "iterable"
        or else A = "aggregate"
        or else A = "predicate"
        or else A = "static_predicate"
        or else A = "dynamic_predicate"
        or else A = "predicate_failure"
        or else A = "invariant"
        or else A = "type_invariant"
        or else A = "type_invariant'class"
        or else A = "pre"
        or else A = "pre'class"
        or else A = "precondition"
        or else A = "post"
        or else A = "post'class"
        or else A = "postcondition"
        or else A = "refined_post"
        or else A = "global"
        or else A = "depends"
        or else A = "refined_global"
        or else A = "refined_depends"
        or else A = "abstract_state"
        or else A = "refined_state"
        or else A = "initializes"
        or else A = "part_of"
        or else A = "ghost"
        or else A = "relaxed_initialization"
        or else A = "nonblocking"
        or else A = "nonblocking'class"
        or else A = "always_terminates"
        or else A = "inline"
        or else A = "inline_always"
        or else A = "no_return"
        or else A = "elaborate_body"
        or else A = "preelaborate"
        or else A = "pure"
        or else A = "remote_types"
        or else A = "remote_call_interface"
        or else A = "all_calls_remote"
        or else A = "no_tagged_streams"
        or else A = "extensions_visible"
        or else A = "remote_access_type"
        or else A = "shared_passive"
        or else A = "relative_deadline"
        or else A = "contract_cases"
        or else A = "subprogram_variant"
        or else A = "exceptional_cases"
        or else A = "no_strict_aliasing"
        or else A = "obsolescent"
        or else A = "reviewable"
        or else A = "optimize"
        or else A = "suppress"
        or else A = "unsuppress";
   end Is_Operational_Attribute;

   function Is_Interfacing_Attribute
     (Name : Unbounded_String) return Boolean is
      A : constant String := Lower (To_String (Name));
   begin
      return A = "convention" or else A = "import" or else A = "export"
        or else A = "external_name" or else A = "link_name";
   end Is_Interfacing_Attribute;

   function Is_Link_Name_Attribute
     (Name : Unbounded_String) return Boolean is
      A : constant String := Lower (To_String (Name));
   begin
      return A = "external_name" or else A = "link_name";
   end Is_Link_Name_Attribute;

   function Is_Import_Export_Attribute
     (Name : Unbounded_String) return Boolean is
      A : constant String := Lower (To_String (Name));
   begin
      return A = "import" or else A = "export";
   end Is_Import_Export_Attribute;

   function Is_Convention_Attribute
     (Name : Unbounded_String) return Boolean is
   begin
      return Lower (To_String (Name)) = "convention";
   end Is_Convention_Attribute;

   function Is_Convention_Identifier (Text : String) return Boolean is
      T : constant String := Trim (Text);
   begin
      if T'Length > 0 and then T (T'Last) = ';' then
         if T'Last = T'First then
            return False;
         else
            return Is_Convention_Identifier (T (T'First .. T'Last - 1));
         end if;
      end if;

      if T = "" then
         return False;
      end if;

      if not Is_Local_Name_Start (T (T'First)) then
         return False;
      end if;

      for I in T'First + 1 .. T'Last loop
         if not Is_Local_Name_Char (T (I)) then
            return False;
         end if;
      end loop;

      return True;
   end Is_Convention_Identifier;

   function Is_Static_Boolean_Value (Text : String) return Boolean is
      T : constant String := Lower (Trim (Text));
   begin
      return T = "true" or else T = "false"
        or else T = "standard.true" or else T = "standard.false";
   end Is_Static_Boolean_Value;

   function Is_Static_True_Value (Text : String) return Boolean is
      T : constant String := Lower (Trim (Text));
   begin
      return T = "true" or else T = "standard.true";
   end Is_Static_True_Value;

   function Is_Static_False_Value (Text : String) return Boolean is
      T : constant String := Lower (Trim (Text));
   begin
      return T = "false" or else T = "standard.false";
   end Is_Static_False_Value;

   function Is_Known_Convention_Identifier (Text : String) return Boolean is
      T : constant String := Lower (Trim (Text));
   begin
      if T'Length > 0 and then T (T'Last) = ';' then
         if T'Last = T'First then
            return False;
         else
            return Is_Known_Convention_Identifier
              (T (T'First .. T'Last - 1));
         end if;
      end if;

      return T = "ada"
        or else T = "intrinsic"
        or else T = "c"
        or else T = "cobol"
        or else T = "fortran"
        or else T = "stdcall"
        or else T = "cpp"
        or else T = "c_pass_by_copy";
   end Is_Known_Convention_Identifier;

   function Has_Static_Numeric_Tokens
     (Text                  : String;
      Is_Known_Numeric_Name : not null Numeric_Name_Predicate) return Boolean
   is
      T : constant String := Trim (Text);
      L : constant String := Lower (T);
      Seen_Digit : Boolean := False;
      I          : Natural := T'First;
   begin
      if T = "" then
         return False;
      elsif (Ada.Strings.Fixed.Index (L, " mod ") /= 0
             or else Ada.Strings.Fixed.Index (L, " rem ") /= 0)
        and then (Ada.Strings.Fixed.Index (L, ".") /= 0
                  or else Ada.Strings.Fixed.Index (L, "real_") /= 0)
      then
         return False;
      end if;

      while I <= T'Last loop
         case T (I) is
            when '0' .. '9' =>
               Seen_Digit := True;
               I := I + 1;
            when '_' =>
               if not Seen_Digit then
                  return False;
               end if;
               I := I + 1;
            when '.' =>
               I := I + 1;
            when '+' | '-' =>
               I := I + 1;
            when '*' | '/' | '(' | ')' | ',' | Character'Val (39) =>
               I := I + 1;
            when 'A' .. 'Z' | 'a' .. 'z' =>
               declare
                  Start : constant Natural := I;
               begin
                  while I <= T'Last
                    and then (T (I) in 'A' .. 'Z'
                              or else T (I) in 'a' .. 'z'
                              or else T (I) in '0' .. '9'
                              or else T (I) = '_'
                              or else T (I) = '.')
                  loop
                     I := I + 1;
                  end loop;

                  if not Is_Known_Numeric_Name.all (T (Start .. I - 1)) then
                     return False;
                  end if;
                  Seen_Digit := True;
               end;
            when ' ' | ASCII.HT =>
               I := I + 1;
            when others =>
               return False;
         end case;
      end loop;

      return Seen_Digit;
   end Has_Static_Numeric_Tokens;

   function Is_Static_String_Literal (Text : String) return Boolean is
      T : constant String := Trim (Text);
   begin
      return T'Length >= 2
        and then T (T'First) = '"'
        and then T (T'Last) = '"';
   end Is_Static_String_Literal;

   function Is_Raw_Numeric_Literal (Text : String) return Boolean is
      T : constant String := Trim (Text);
   begin
      if T = "" then
         return False;
      end if;

      return T (T'First) in '0' .. '9';
   end Is_Raw_Numeric_Literal;

   function Is_Static_Numeric_Value (Text : String) return Boolean is
      function Looks_Static_Numeric_Name (Name : String) return Boolean is
         N : constant String := Lower (Trim (Name));
      begin
         return N /= ""
           and then Ada.Strings.Fixed.Index (N, "runtime") = 0
           and then Ada.Strings.Fixed.Index (N, "dynamic") = 0;
      end Looks_Static_Numeric_Name;
   begin
      return Has_Static_Numeric_Tokens
        (Text,
         Looks_Static_Numeric_Name'Unrestricted_Access);
   end Is_Static_Numeric_Value;

   function Is_Positive_Static_Natural_Value (Text : String) return Boolean is
      Valid : Boolean := False;
      Value : Natural := 0;
   begin
      Parse_Static_Natural (Text, Valid, Value);
      return Valid and then Value > 0;
   end Is_Positive_Static_Natural_Value;

   function Is_Storage_Pool_Value (Text : String) return Boolean is
      T : constant String := Trim (Text);
   begin
      if T = "" then
         return False;
      end if;

      return not Is_Static_String_Literal (T)
        and then not Is_Static_Boolean_Value (T)
        and then not Is_Raw_Numeric_Literal (T)
        and then Is_Local_Name_Start (T (T'First));
   end Is_Storage_Pool_Value;

   function Is_Address_Null_Value (Text : String) return Boolean is
      T : constant String := Lower (Trim (Text));
   begin
      return T = "null";
   end Is_Address_Null_Value;

   function Is_Address_Attribute_Reference (Text : String) return Boolean is
      L : constant String := Lower (Trim (Text));
   begin
      return Contains (L, "'address")
        and then not Contains (L, "'addressable");
   end Is_Address_Attribute_Reference;

   function Is_Address_Conversion_Call (Text : String) return Boolean is
      L : constant String := Lower (Trim (Text));
   begin
      return Starts_With (L, "system'to_address")
        or else Starts_With (L, "system.storage_elements.to_address")
        or else Starts_With (L, "to_address")
        or else Starts_With (L, "system.address'")
        or else Starts_With (L, "standard.system.address'");
   end Is_Address_Conversion_Call;

   function Is_Address_Name_Reference (Text : String) return Boolean is
      T : constant String := Trim (Text);
      L : constant String := Lower (T);
   begin
      if T = "" then
         return False;
      elsif not Is_Local_Name_Start (T (T'First)) then
         return False;
      end if;

      return Ends_With (L, "address")
        or else Ends_With (L, "_address")
        or else Ends_With (L, ".address")
        or else L = "null_address"
        or else L = "system.null_address";
   end Is_Address_Name_Reference;

   function Is_Address_Compatible_Expression (Text : String) return Boolean is
      T : constant String := Trim (Text);
   begin
      if T = "" then
         return False;
      end if;

      if Is_Static_String_Literal (T)
        or else Is_Static_Boolean_Value (T)
        or else Is_Raw_Numeric_Literal (T)
        or else Is_Address_Null_Value (T)
      then
         return False;
      end if;

      return Is_Address_Attribute_Reference (T)
        or else Is_Address_Conversion_Call (T)
        or else Is_Address_Name_Reference (T);
   end Is_Address_Compatible_Expression;

   function Is_Interfacing_Attribute_Target
     (Attribute_Name : Unbounded_String;
      Kind           : Symbol_Kind) return Boolean
   is
      A : constant String := Lower (To_String (Attribute_Name));
   begin
      if A = "convention" then
         return Is_Type_Like_Target (Kind)
           or else Is_Object_Like_Target (Kind)
           or else Is_Subprogram_Like_Target (Kind)
           or else Kind in Symbol_Task | Symbol_Protected | Symbol_Exception;
      elsif A = "import" or else A = "export" then
         return Is_Object_Like_Target (Kind)
           or else Is_Subprogram_Like_Target (Kind);
      elsif A = "external_name" or else A = "link_name" then
         return Is_Object_Like_Target (Kind)
           or else Is_Subprogram_Like_Target (Kind);
      else
         return True;
      end if;
   end Is_Interfacing_Attribute_Target;

   function Operational_Handler_Name (Text : String) return String is
      Work  : constant String := Trim (Text);
      Start : Natural := Work'First;
      Stop  : Natural;
   begin
      if Work = "" then
         return "";
      end if;

      while Start <= Work'Last
        and then not Is_Local_Name_Start (Work (Start))
        and then Work (Start) /= '"'
      loop
         Start := Start + 1;
      end loop;

      if Start > Work'Last then
         return "";
      end if;

      if Work (Start) = '"' then
         Stop := Start + 1;
         while Stop <= Work'Last and then Work (Stop) /= '"' loop
            Stop := Stop + 1;
         end loop;
         if Stop <= Work'Last then
            return Work (Start .. Stop);
         else
            return "";
         end if;
      end if;

      Stop := Start;
      while Stop <= Work'Last
        and then (Is_Local_Name_Char (Work (Stop)) or else Work (Stop) = '.')
      loop
         Stop := Stop + 1;
      end loop;

      return Work (Start .. Stop - 1);
   end Operational_Handler_Name;

   function Operational_Handler_Is_Compatible
     (Attribute_Name : Unbounded_String;
      Handler_Kind   : Symbol_Kind) return Boolean
   is
   begin
      if Is_Stream_Input_Attribute (Attribute_Name) then
         return Handler_Kind in Symbol_Function | Symbol_Operator_Function;
      else
         return Handler_Kind = Symbol_Procedure;
      end if;
   end Operational_Handler_Is_Compatible;

end Editor.Ada_Declaration_Parser.Attribute_Value_Helpers;
