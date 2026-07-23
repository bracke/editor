with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;

package body Editor.Outline_Extractor.Symbols is

   use type Editor.Ada_Language_Model.Symbol_Kind;

   function Lowercase_Text (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Translate
        (Text, Ada.Strings.Maps.Constants.Lower_Case_Map);
   end Lowercase_Text;

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
            --  separate bodies are navigable callable Outline rows.
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
        or else (Profile'Length >= 7
                 and then Profile (Profile'First .. Profile'First + 6) = "return ");
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

end Editor.Outline_Extractor.Symbols;
