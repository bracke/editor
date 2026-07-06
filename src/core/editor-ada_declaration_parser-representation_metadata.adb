with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with Ada.Characters.Latin_1;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Metadata_Helpers;
with Editor.Ada_Declaration_Parser.Pragma_Helpers;

package body Editor.Ada_Declaration_Parser.Representation_Metadata is

   use Editor.Ada_Language_Model;
   use Editor.Ada_Declaration_Parser.Lexical_Helpers;

   procedure Mark_Representation_Clause_Target
     (Analysis : in out Analysis_Result;
      Line     : String)
   is
      Target : constant String :=
        Metadata_Helpers.Representation_Clause_Target (Line);
      Wanted : constant String := Normalize_Name (Target);
   begin
      if Target'Length = 0 then
         return;
      end if;

      for I in reverse 1 .. Symbol_Count (Analysis) loop
         declare
            Info : constant Symbol_Info := Symbol_At (Analysis, I);
         begin
            if To_String (Info.Normalized_Name) = Wanted then
               Mark_Symbol_Representation_Clause (Analysis, Info.Id);
               return;
            end if;
         end;
      end loop;
   end Mark_Representation_Clause_Target;

   function Interfacing_Representation_Kind
     (Attribute_Name : String) return Representation_Clause_Kind
   is
      A : constant String := Lower (Attribute_Name);
   begin
      if A = "convention" then
         return Representation_Convention_Clause;
      elsif A = "import" then
         return Representation_Import_Clause;
      elsif A = "export" then
         return Representation_Export_Clause;
      elsif A = "external_name" then
         return Representation_External_Name_Clause;
      elsif A = "link_name" then
         return Representation_Link_Name_Clause;
      else
         return Representation_Other_Clause;
      end if;
   end Interfacing_Representation_Kind;

   procedure Add_Interfacing_Pragma_Representation
     (Analysis      : in out Analysis_Result;
      Target_Symbol : Symbol_Id;
      Target_Name   : String;
      Line          : String;
      Source_Span   : Source_Range)
   is
      P : constant String := Pragma_Helpers.Pragma_Name_Of (Line);
      Convention_Value : constant String :=
        (if P = "external" then ""
         else Pragma_Helpers.Interfacing_Pragma_Value
           (Line, "convention", 1));
      External_Value : constant String :=
        (if P = "external" then
            Pragma_Helpers.Interfacing_Pragma_Value
              (Line, "external_name", 2)
         elsif P = "import" or else P = "export" or else P = "interface" then
            Pragma_Helpers.Interfacing_Pragma_Value
              (Line, "external_name", 3)
         else "");
      Link_Value : constant String :=
        (if P = "import" or else P = "export" then
            Pragma_Helpers.Interfacing_Pragma_Value (Line, "link_name", 4)
         else "");
   begin
      if Target_Name = "" or else Target_Symbol = No_Symbol then
         return;
      end if;

      if P = "convention" or else P = "import" or else P = "export" or else P = "interface" then
         Add_Representation_Clause
           (Analysis,
            Target_Symbol => Target_Symbol,
            Target_Name => Target_Name,
            Kind => Interfacing_Representation_Kind ("Convention"),
            Attribute_Name => "Convention",
            Item_Text => Convention_Value,
            Source_Form => Representation_Source_Pragma,
            Source_Span => Source_Span);
      end if;

      if P = "import" or else P = "interface" then
         Add_Representation_Clause
           (Analysis,
            Target_Symbol => Target_Symbol,
            Target_Name => Target_Name,
            Kind => Interfacing_Representation_Kind ("Import"),
            Attribute_Name => "Import",
            Item_Text => "True",
            Source_Form => Representation_Source_Pragma,
            Source_Span => Source_Span);
      elsif P = "export" then
         Add_Representation_Clause
           (Analysis,
            Target_Symbol => Target_Symbol,
            Target_Name => Target_Name,
            Kind => Interfacing_Representation_Kind ("Export"),
            Attribute_Name => "Export",
            Item_Text => "True",
            Source_Form => Representation_Source_Pragma,
            Source_Span => Source_Span);
      end if;

      if External_Value /= "" then
         Add_Representation_Clause
           (Analysis,
            Target_Symbol => Target_Symbol,
            Target_Name => Target_Name,
            Kind => Interfacing_Representation_Kind ("External_Name"),
            Attribute_Name => "External_Name",
            Item_Text => External_Value,
            Source_Form => Representation_Source_Pragma,
            Source_Span => Source_Span);
      end if;

      if Link_Value /= "" then
         Add_Representation_Clause
           (Analysis,
            Target_Symbol => Target_Symbol,
            Target_Name => Target_Name,
            Kind => Interfacing_Representation_Kind ("Link_Name"),
            Attribute_Name => "Link_Name",
            Item_Text => Link_Value,
            Source_Form => Representation_Source_Pragma,
            Source_Span => Source_Span);
      end if;
   end Add_Interfacing_Pragma_Representation;

   procedure Parse_Static_Natural
     (Text  : String;
      Valid : out Boolean;
      Value : out Natural)
   is
      T     : constant String := Trim (Text);
      Acc   : Natural := 0;
      Digit : Natural;
   begin
      Valid := T'Length > 0;
      Value := 0;
      if not Valid then
         return;
      end if;

      for C of T loop
         if C < '0' or else C > '9' then
            Valid := False;
            Value := 0;
            return;
         end if;

         Digit := Character'Pos (C) - Character'Pos ('0');
         if Acc > (Natural'Last - Digit) / 10 then
            Valid := False;
            Value := 0;
            return;
         end if;
         Acc := Acc * 10 + Digit;
      end loop;

      Value := Acc;
   end Parse_Static_Natural;

   function Attribute_Base_Name (Target_Text : String) return String is
      T : constant String := Trim (Target_Text);
      Apostrophe_Pos : Natural := 0;
   begin
      for I in T'Range loop
         if T (I) = Character'Val (39) then
            Apostrophe_Pos := I;
            exit;
         end if;
      end loop;

      if Apostrophe_Pos = 0 then
         return T;
      elsif Apostrophe_Pos <= T'First then
         return "";
      else
         return Trim (T (T'First .. Apostrophe_Pos - 1));
      end if;
   end Attribute_Base_Name;

   procedure Add_Representation_Pragma_Representation
     (Analysis      : in out Analysis_Result;
      Target_Symbol : Symbol_Id;
      Target_Name   : String;
      Line          : String;
      Source_Span   : Source_Range)
   is
      P : constant String := Pragma_Helpers.Pragma_Name_Of (Line);

      function Display_Pragma_Property_Name (Name : String) return String is
         Result : Unbounded_String := Null_Unbounded_String;
         Start_Word : Boolean := True;

         function Upper (C : Character) return Character is
         begin
            if C >= 'a' and then C <= 'z' then
               return Character'Val
                 (Character'Pos (C) - Character'Pos ('a') + Character'Pos ('A'));
            else
               return C;
            end if;
         end Upper;
      begin
         --  Keep user-facing/source-facing attribute spelling stable while
         --  deriving the semantic kind from the canonical shared resolver.
         --  Most property names are title-cased underscore-separated words;
         --  preserve the few all-uppercase Ada/GNAT spellings explicitly.
         if Name = "cpu" then
            return "CPU";
         elsif Name = "spark_mode" then
            return "SPARK_Mode";
         end if;

         for C of Name loop
            if C = '_' then
               Append (Result, C);
               Start_Word := True;
            elsif Start_Word then
               Append (Result, Upper (C));
               Start_Word := False;
            else
               Append (Result, C);
            end if;
         end loop;

         return To_String (Result);
      end Display_Pragma_Property_Name;

      Attribute : constant String := Display_Pragma_Property_Name (P);
      Value_Text : constant String :=
        (if P = "attach_handler" then
            Pragma_Helpers.Interfacing_Pragma_Value
              (Line, "interrupt", 2)
         elsif P = "priority" or else P = "interrupt_priority" or else P = "cpu"
           or else P = "dispatching_domain" or else P = "relative_deadline"
           or else P = "max_entry_queue_length"
         then
            --  Value-only pragmas such as ``pragma Priority (10)`` bind to
            --  the current enclosing task/protected declaration.  Their first
            --  positional argument is the retained representation value; using
            --  positional fallback 2 was appropriate only for entity,value
            --  pragma shapes and silently dropped ordinary Ada spellings.
            Pragma_Helpers.Interfacing_Pragma_Value (Line, "value", 1)
         elsif P = "linker_section" then
            (if Pragma_Helpers.Named_Pragma_Argument (Line, "section") /= "" then
                Pragma_Helpers.Named_Pragma_Argument (Line, "section")
             elsif Pragma_Helpers.Named_Pragma_Argument
                (Line, "section_name") /= ""
             then
                Pragma_Helpers.Named_Pragma_Argument (Line, "section_name")
             else
                Pragma_Helpers.Interfacing_Pragma_Value (Line, "value", 2))
         elsif P = "machine_attribute" then
            (if Pragma_Helpers.Named_Pragma_Argument
               (Line, "attribute_name") /= ""
             then
                Pragma_Helpers.Named_Pragma_Argument (Line, "attribute_name")
             elsif Pragma_Helpers.Named_Pragma_Argument
                (Line, "attribute") /= ""
             then
                Pragma_Helpers.Named_Pragma_Argument (Line, "attribute")
             else
                Pragma_Helpers.Interfacing_Pragma_Value (Line, "value", 2))
         elsif P = "optimize" or else P = "spark_mode" then
            Pragma_Helpers.Interfacing_Pragma_Value (Line, "", 1)
         elsif P = "suppress" or else P = "unsuppress" then
            (if Pragma_Helpers.Named_Pragma_Argument (Line, "check_name") /= "" then
                Pragma_Helpers.Named_Pragma_Argument (Line, "check_name")
             else
                Pragma_Helpers.Interfacing_Pragma_Value (Line, "check", 1))
         elsif P = "assertion_policy" or else P = "check_policy"
           or else P = "debug_policy" or else P = "restrictions"
           or else P = "restriction_warnings" or else P = "profile"
         then
            Pragma_Helpers.Interfacing_Pragma_Value (Line, "", 1)
         else "True");
      Kind : constant Representation_Clause_Kind :=
        Representation_Kind_For ("Target'" & Attribute, Value_Text);
      Has_Value : Boolean := False;
      Static_Value : Natural := 0;
   begin
      if P = "convention"
        or else P = "import"
        or else P = "export"
        or else P = "interface"
        or else P = "external"
      then
         --  These are lowered by Add_Interfacing_Pragma_Representation, where
         --  convention/entity/external-name/link-name arguments have
         --  pragma-specific positions.  Do not also add a generic resolver
         --  item with a Boolean placeholder value.
         return;
      end if;

      Parse_Static_Natural (Value_Text, Has_Value, Static_Value);
      if Target_Name = ""
        or else Target_Symbol = No_Symbol
        or else Kind = Representation_Other_Clause
      then
         return;
      end if;

      --  Representation pragmas are source aliases for the corresponding
      --  representation aspects/attribute-definition clauses in the bounded
      --  editor model.  Resolve the pragma property through the same shared
      --  catalog used for aspects and attribute-definition clauses so new
      --  explicit properties cannot drift into pragma-only special cases.
      Add_Representation_Clause
        (Analysis,
         Target_Symbol => Target_Symbol,
         Target_Name => Target_Name,
         Kind => Kind,
         Attribute_Name => Attribute,
         Item_Text => Value_Text,
         Source_Form => Representation_Source_Pragma,
         Has_Static_Value => Has_Value,
         Static_Value => Static_Value,
         Source_Span => Source_Span);
   end Add_Representation_Pragma_Representation;

   function Attribute_Name (Target_Text : String) return String is
      T : constant String := Trim (Target_Text);
      Apostrophe_Pos : Natural := 0;
   begin
      for I in T'Range loop
         if T (I) = Character'Val (39) then
            Apostrophe_Pos := I;
            exit;
         end if;
      end loop;
      if Apostrophe_Pos = 0 or else Apostrophe_Pos >= T'Last then
         return "";
      else
         return Trim (T (Apostrophe_Pos + 1 .. T'Last));
      end if;
   end Attribute_Name;

   function Canonical_Property_Name (Name : String) return String is
      Raw : constant String := Lower (Trim (Name));
      Buf : String (1 .. Raw'Length) := (others => ' ');
      Len : Natural := 0;
      I   : Natural := Raw'First;
   begin
      --  Attribute-definition clauses and aspect marks are tokenized by
      --  different grammar paths.  In particular class-wide marks may be
      --  retained as ``Pre'Class`` by one path and ``Pre 'Class`` or
      --  ``Pre' Class`` by another.  Canonicalize only whitespace around
      --  the attribute tick so the shared property table remains the
      --  single source of truth for both source forms.
      while I <= Raw'Last loop
         if Raw (I) = ' ' or else Raw (I) = Ada.Characters.Latin_1.HT then
            if I < Raw'Last and then Raw (I + 1) = Character'Val (39) then
               null;
            elsif I > Raw'First and then Raw (I - 1) = Character'Val (39) then
               null;
            else
               Len := Len + 1;
               Buf (Len) := Raw (I);
            end if;
         else
            Len := Len + 1;
            Buf (Len) := Raw (I);
         end if;
         I := I + 1;
      end loop;

      if Len = 0 then
         return "";
      end if;
      return Buf (1 .. Len);
   end Canonical_Property_Name;

   function Attribute_Representation_Kind_For
     (Target_Text : String;
      Item_Text   : String;
      Clause_Text : String := "") return Representation_Clause_Kind
   is
      Attr : constant String := Canonical_Property_Name (Attribute_Name (Target_Text));
      Item : constant String := Trim (Item_Text);
      Clause : constant String := Lower (Clause_Text);
   begin
      if Ada.Strings.Fixed.Index (Clause, " at ") /= 0 then
         return Representation_Address_Clause;
      elsif Attr = "address" then
         return Representation_Address_Clause;
      elsif Attr = "size" then
         return Representation_Size_Clause;
      elsif Attr = "alignment" then
         return Representation_Alignment_Clause;
      elsif Attr = "bit_order" then
         return Representation_Bit_Order_Clause;
      elsif Attr = "storage_size" then
         return Representation_Storage_Size_Clause;
      elsif Attr = "storage_pool" then
         return Representation_Storage_Pool_Clause;
      elsif Attr = "default_storage_pool" then
         return Representation_Default_Storage_Pool_Clause;
      elsif Attr = "component_size" then
         return Representation_Component_Size_Clause;
      elsif Attr = "object_size" then
         return Representation_Object_Size_Clause;
      elsif Attr = "value_size" then
         return Representation_Value_Size_Clause;
      elsif Attr = "scalar_storage_order" then
         return Representation_Scalar_Storage_Order_Clause;
      elsif Attr = "default_scalar_storage_order" then
         return Representation_Default_Scalar_Storage_Order_Clause;
      elsif Attr = "small" then
         return Representation_Small_Clause;
      elsif Attr = "pack" then
         return Representation_Pack_Clause;
      elsif Attr = "machine_radix" then
         return Representation_Machine_Radix_Clause;
      elsif Attr = "aft" then
         return Representation_Aft_Clause;
      elsif Attr = "atomic" then
         return Representation_Atomic_Clause;
      elsif Attr = "volatile" then
         return Representation_Volatile_Clause;
      elsif Attr = "independent" then
         return Representation_Independent_Clause;
      elsif Attr = "atomic_components" then
         return Representation_Atomic_Components_Clause;
      elsif Attr = "volatile_components" then
         return Representation_Volatile_Components_Clause;
      elsif Attr = "independent_components" then
         return Representation_Independent_Components_Clause;
      elsif Attr = "unchecked_union" then
         return Representation_Unchecked_Union_Clause;
      elsif Attr = "suppress_initialization" then
         return Representation_Suppress_Initialization_Clause;
      elsif Attr = "stream_size" then
         return Representation_Stream_Size_Clause;
      elsif Attr = "read" then
         return Representation_Read_Clause;
      elsif Attr = "write" then
         return Representation_Write_Clause;
      elsif Attr = "input" then
         return Representation_Input_Clause;
      elsif Attr = "output" then
         return Representation_Output_Clause;
      elsif Attr = "external_tag" then
         return Representation_External_Tag_Clause;
      elsif Attr = "put_image" then
         return Representation_Put_Image_Clause;
      elsif Attr = "default_value" then
         return Representation_Default_Value_Clause;
      elsif Attr = "default_component_value" then
         return Representation_Default_Component_Value_Clause;
      elsif Attr = "constant_indexing" then
         return Representation_Constant_Indexing_Clause;
      elsif Attr = "variable_indexing" then
         return Representation_Variable_Indexing_Clause;
      elsif Attr = "implicit_dereference" then
         return Representation_Implicit_Dereference_Clause;
      elsif Attr = "default_iterator" then
         return Representation_Default_Iterator_Clause;
      elsif Attr = "iterator_element" then
         return Representation_Iterator_Element_Clause;
      elsif Attr = "iterable" then
         return Representation_Iterable_Clause;
      elsif Attr = "aggregate" then
         return Representation_Aggregate_Clause;
      elsif Attr = "max_entry_queue_length" then
         return Representation_Max_Entry_Queue_Length_Clause;
      elsif Attr = "priority" then
         return Representation_Priority_Clause;
      elsif Attr = "interrupt_priority" then
         return Representation_Interrupt_Priority_Clause;
      elsif Attr = "cpu" then
         return Representation_CPU_Clause;
      elsif Attr = "dispatching_domain" then
         return Representation_Dispatching_Domain_Clause;
      elsif Attr = "no_controlled_parts" then
         return Representation_No_Controlled_Parts_Clause;
      elsif Attr = "preelaborable_initialization" then
         return Representation_Preelaborable_Initialization_Clause;
      elsif Attr = "no_task_parts" then
         return Representation_No_Task_Parts_Clause;
      elsif Attr = "exclusive_functions" then
         return Representation_Exclusive_Functions_Clause;
      elsif Attr = "simple_storage_pool_type" then
         return Representation_Simple_Storage_Pool_Type_Clause;
      elsif Attr = "discard_names" then
         return Representation_Discard_Names_Clause;
      elsif Attr = "volatile_function" then
         return Representation_Volatile_Function_Clause;
      elsif Attr = "interrupt_handler" then
         return Representation_Interrupt_Handler_Clause;
      elsif Attr = "attach_handler" then
         return Representation_Attach_Handler_Clause;
      elsif Attr = "async_readers" then
         return Representation_Async_Readers_Clause;
      elsif Attr = "async_writers" then
         return Representation_Async_Writers_Clause;
      elsif Attr = "effective_reads" then
         return Representation_Effective_Reads_Clause;
      elsif Attr = "effective_writes" then
         return Representation_Effective_Writes_Clause;
      elsif Attr = "integer_literal" then
         return Representation_Integer_Literal_Clause;
      elsif Attr = "real_literal" then
         return Representation_Real_Literal_Clause;
      elsif Attr = "string_literal" then
         return Representation_String_Literal_Clause;
      elsif Attr = "max_size_in_storage_elements" then
         return Representation_Max_Size_In_Storage_Elements_Clause;
      elsif Attr = "storage_model_type" then
         return Representation_Storage_Model_Type_Clause;
      elsif Attr = "designated_storage_model" then
         return Representation_Designated_Storage_Model_Clause;
      elsif Attr = "stable_properties" then
         return Representation_Stable_Properties_Clause;
      elsif Attr = "stable_properties'class" then
         return Representation_Stable_Properties_Class_Clause;
      elsif Attr = "predicate" then
         return Representation_Predicate_Clause;
      elsif Attr = "static_predicate" then
         return Representation_Static_Predicate_Clause;
      elsif Attr = "dynamic_predicate" then
         return Representation_Dynamic_Predicate_Clause;
      elsif Attr = "predicate_failure" then
         return Representation_Predicate_Failure_Clause;
      elsif Attr = "invariant" then
         return Representation_Invariant_Clause;
      elsif Attr = "type_invariant" then
         return Representation_Type_Invariant_Clause;
      elsif Attr = "type_invariant'class" then
         return Representation_Type_Invariant_Class_Clause;
      elsif Attr = "initial_condition" then
         return Representation_Initial_Condition_Clause;
      elsif Attr = "default_initial_condition" then
         return Representation_Default_Initial_Condition_Clause;
      elsif Attr = "pre" then
         return Representation_Pre_Clause;
      elsif Attr = "pre'class" then
         return Representation_Pre_Class_Clause;
      elsif Attr = "precondition" then
         return Representation_Precondition_Clause;
      elsif Attr = "post" then
         return Representation_Post_Clause;
      elsif Attr = "post'class" then
         return Representation_Post_Class_Clause;
      elsif Attr = "postcondition" then
         return Representation_Postcondition_Clause;
      elsif Attr = "refined_post" then
         return Representation_Refined_Post_Clause;
      elsif Attr = "global" then
         return Representation_Global_Clause;
      elsif Attr = "depends" then
         return Representation_Depends_Clause;
      elsif Attr = "refined_global" then
         return Representation_Refined_Global_Clause;
      elsif Attr = "refined_depends" then
         return Representation_Refined_Depends_Clause;
      elsif Attr = "abstract_state" then
         return Representation_Abstract_State_Clause;
      elsif Attr = "refined_state" then
         return Representation_Refined_State_Clause;
      elsif Attr = "initializes" then
         return Representation_Initializes_Clause;
      elsif Attr = "part_of" then
         return Representation_Part_Of_Clause;
      elsif Attr = "ghost" then
         return Representation_Ghost_Clause;
      elsif Attr = "relaxed_initialization" then
         return Representation_Relaxed_Initialization_Clause;
      elsif Attr = "nonblocking" then
         return Representation_Nonblocking_Clause;
      elsif Attr = "nonblocking'class" then
         return Representation_Nonblocking_Class_Clause;
      elsif Attr = "always_terminates" then
         return Representation_Always_Terminates_Clause;
      elsif Attr = "inline" then
         return Representation_Inline_Clause;
      elsif Attr = "inline_always" then
         return Representation_Inline_Always_Clause;
      elsif Attr = "no_return" then
         return Representation_No_Return_Clause;
      elsif Attr = "elaborate_body" then
         return Representation_Elaborate_Body_Clause;
      elsif Attr = "preelaborate" then
         return Representation_Preelaborate_Clause;
      elsif Attr = "pure" then
         return Representation_Pure_Clause;
      elsif Attr = "remote_types" then
         return Representation_Remote_Types_Clause;
      elsif Attr = "remote_call_interface" then
         return Representation_Remote_Call_Interface_Clause;
      elsif Attr = "all_calls_remote" then
         return Representation_All_Calls_Remote_Clause;
      elsif Attr = "no_tagged_streams" then
         return Representation_No_Tagged_Streams_Clause;
      elsif Attr = "extensions_visible" then
         return Representation_Extensions_Visible_Clause;
      elsif Attr = "remote_access_type" then
         return Representation_Remote_Access_Type_Clause;
      elsif Attr = "shared_passive" then
         return Representation_Shared_Passive_Clause;
      elsif Attr = "relative_deadline" then
         return Representation_Relative_Deadline_Clause;
      elsif Attr = "contract_cases" then
         return Representation_Contract_Cases_Clause;
      elsif Attr = "subprogram_variant" then
         return Representation_Subprogram_Variant_Clause;
      elsif Attr = "exceptional_cases" then
         return Representation_Exceptional_Cases_Clause;
      elsif Attr = "spark_mode" then
         return Representation_SPARK_Mode_Clause;
      elsif Attr = "side_effects" then
         return Representation_Side_Effects_Clause;
      elsif Attr = "no_caching" then
         return Representation_No_Caching_Clause;
      elsif Attr = "test_case" then
         return Representation_Test_Case_Clause;
      elsif Attr = "annotate" then
         return Representation_Annotate_Clause;
      elsif Attr = "warnings" then
         return Representation_Warnings_Clause;
      elsif Attr = "linker_section" then
         return Representation_Linker_Section_Clause;
      elsif Attr = "machine_attribute" then
         return Representation_Machine_Attribute_Clause;
      elsif Attr = "weak_external" then
         return Representation_Weak_External_Clause;
      elsif Attr = "unreferenced" then
         return Representation_Unreferenced_Clause;
      elsif Attr = "unmodified" then
         return Representation_Unmodified_Clause;
      elsif Attr = "no_elaboration_code" then
         return Representation_No_Elaboration_Code_Clause;
      elsif Attr = "persistent_bss" then
         return Representation_Persistent_BSS_Clause;
      elsif Attr = "universal_aliasing" then
         return Representation_Universal_Aliasing_Clause;
      elsif Attr = "volatile_full_access" then
         return Representation_Volatile_Full_Access_Clause;
      elsif Attr = "atomic_always_lock_free" then
         return Representation_Atomic_Always_Lock_Free_Clause;
      elsif Attr = "no_inline" then
         return Representation_No_Inline_Clause;
      elsif Attr = "no_strict_aliasing" then
         return Representation_No_Strict_Aliasing_Clause;
      elsif Attr = "obsolescent" then
         return Representation_Obsolescent_Clause;
      elsif Attr = "reviewable" then
         return Representation_Reviewable_Clause;
      elsif Attr = "optimize" then
         return Representation_Optimize_Clause;
      elsif Attr = "suppress" then
         return Representation_Suppress_Clause;
      elsif Attr = "unsuppress" then
         return Representation_Unsuppress_Clause;
      elsif Attr = "no_heap_finalization" then
         return Representation_No_Heap_Finalization_Clause;
      elsif Attr = "suppress_debug_info" then
         return Representation_Suppress_Debug_Info_Clause;
      elsif Attr = "assertion_policy" then
         return Representation_Assertion_Policy_Clause;
      elsif Attr = "check_policy" then
         return Representation_Check_Policy_Clause;
      elsif Attr = "debug_policy" then
         return Representation_Debug_Policy_Clause;
      elsif Attr = "restrictions" then
         return Representation_Restrictions_Clause;
      elsif Attr = "restriction_warnings" then
         return Representation_Restriction_Warnings_Clause;
      elsif Attr = "profile" then
         return Representation_Profile_Clause;
      elsif Attr = "dimension_system" then
         return Representation_Dimension_System_Clause;
      elsif Attr = "dimension" then
         return Representation_Dimension_Clause;
      elsif Attr = "convention" then
         return Representation_Convention_Clause;
      elsif Attr = "import" then
         return Representation_Import_Clause;
      elsif Attr = "export" then
         return Representation_Export_Clause;
      elsif Attr = "external_name" then
         return Representation_External_Name_Clause;
      elsif Attr = "link_name" then
         return Representation_Link_Name_Clause;
      elsif Starts_With_Word (Lower (Item), "record") then
         return Representation_Record_Clause;
      elsif Item'Length > 0 and then Item (Item'First) = '(' then
         return Representation_Enumeration_Clause;
      elsif Target_Text /= "" and then Attr = "" then
         return Representation_Other_Clause;
      else
         return Representation_Other_Clause;
      end if;
   end Attribute_Representation_Kind_For;

   function Is_Attribute_Definition_Aspect_Name
     (Name : String) return Boolean
   is
      Kind : constant Representation_Clause_Kind :=
        Attribute_Representation_Kind_For ("Target'" & Trim (Name), "");
   begin
      return Kind /= Representation_Other_Clause;
   end Is_Attribute_Definition_Aspect_Name;

   function Aspect_Default_Value
     (Name  : String;
      Value : String) return String
   is
      Raw_V : constant String := Trim (Value);
      V : constant String :=
        (if Ends_With (Lower (Raw_V), " is") and then Raw_V'Length > 3
         then Trim (Raw_V (Raw_V'First .. Raw_V'Last - 3))
         else Raw_V);
      Kind : constant Representation_Clause_Kind :=
        Attribute_Representation_Kind_For ("Target'" & Trim (Name), V);
   begin
      if Representation_Property_Is_Boolean (Kind)
        and then (V = "" or else Normalize_Name (V) = Normalize_Name (Name))
      then
         return "True";
      elsif V /= "" then
         return V;
      else
         return V;
      end if;
   end Aspect_Default_Value;

   function Representation_Kind_For
     (Target_Text : String;
      Item_Text   : String;
      Clause_Text : String := "") return Representation_Clause_Kind
   is
      pragma Unreferenced (Item_Text);
      T : constant String := Lower (Target_Text);
      C : constant String := Lower (Clause_Text);
   begin
      if Ada.Strings.Fixed.Index (C, " at ") /= 0
        or else Ada.Strings.Fixed.Index (T, "'address") /= 0
      then
         return Representation_Address_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'size") /= 0 then
         return Representation_Size_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'alignment") /= 0 then
         return Representation_Alignment_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'bit_order") /= 0 then
         return Representation_Bit_Order_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'storage_size") /= 0 then
         return Representation_Storage_Size_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'storage_pool") /= 0 then
         return Representation_Storage_Pool_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'default_storage_pool") /= 0 then
         return Representation_Default_Storage_Pool_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'component_size") /= 0 then
         return Representation_Component_Size_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'small") /= 0 then
         return Representation_Small_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'pack") /= 0 then
         return Representation_Pack_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'atomic_components") /= 0 then
         return Representation_Atomic_Components_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'volatile_components") /= 0 then
         return Representation_Volatile_Components_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'independent_components") /= 0 then
         return Representation_Independent_Components_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'atomic") /= 0 then
         return Representation_Atomic_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'volatile_function") /= 0 then
         return Representation_Volatile_Function_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'volatile") /= 0 then
         return Representation_Volatile_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'independent") /= 0 then
         return Representation_Independent_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'suppress_initialization") /= 0 then
         return Representation_Suppress_Initialization_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'priority") /= 0 then
         return Representation_Priority_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'interrupt_priority") /= 0 then
         return Representation_Interrupt_Priority_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'cpu") /= 0 then
         return Representation_CPU_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'dispatching_domain") /= 0 then
         return Representation_Dispatching_Domain_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'relative_deadline") /= 0 then
         return Representation_Relative_Deadline_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'max_entry_queue_length") /= 0 then
         return Representation_Max_Entry_Queue_Length_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'pre") /= 0 then
         if Ada.Strings.Fixed.Index (T, "'pre'class") /= 0 then
            return Representation_Pre_Class_Clause;
         else
            return Representation_Pre_Clause;
         end if;
      elsif Ada.Strings.Fixed.Index (T, "'post") /= 0 then
         if Ada.Strings.Fixed.Index (T, "'post'class") /= 0 then
            return Representation_Post_Class_Clause;
         else
            return Representation_Post_Clause;
         end if;
      elsif Ada.Strings.Fixed.Index (T, "'global") /= 0 then
         return Representation_Global_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'depends") /= 0 then
         return Representation_Depends_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'nonblocking") /= 0 then
         return Representation_Nonblocking_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'always_terminates") /= 0 then
         return Representation_Always_Terminates_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'inline_always") /= 0 then
         return Representation_Inline_Always_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'inline") /= 0 then
         return Representation_Inline_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'no_inline") /= 0 then
         return Representation_No_Inline_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'no_return") /= 0 then
         return Representation_No_Return_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'discard_names") /= 0 then
         return Representation_Discard_Names_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'volatile_function") /= 0 then
         return Representation_Volatile_Function_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'attach_handler") /= 0 then
         return Representation_Attach_Handler_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'elaborate_body") /= 0 then
         return Representation_Elaborate_Body_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'remote_access_type") /= 0 then
         return Representation_Remote_Access_Type_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'exclusive_functions") /= 0 then
         return Representation_Exclusive_Functions_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'side_effects") /= 0 then
         return Representation_Side_Effects_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'no_caching") /= 0 then
         return Representation_No_Caching_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'spark_mode") /= 0 then
         return Representation_SPARK_Mode_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'no_elaboration_code") /= 0 then
         return Representation_No_Elaboration_Code_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'linker_section") /= 0 then
         return Representation_Linker_Section_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'machine_attribute") /= 0 then
         return Representation_Machine_Attribute_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'reviewable") /= 0 then
         return Representation_Reviewable_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'suppress_debug_info") /= 0 then
         return Representation_Suppress_Debug_Info_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'suppress") /= 0 then
         return Representation_Suppress_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'unsuppress") /= 0 then
         return Representation_Unsuppress_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'assertion_policy") /= 0 then
         return Representation_Assertion_Policy_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'check_policy") /= 0 then
         return Representation_Check_Policy_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'debug_policy") /= 0 then
         return Representation_Debug_Policy_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'restrictions") /= 0 then
         return Representation_Restrictions_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'restriction_warnings") /= 0 then
         return Representation_Restriction_Warnings_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'profile") /= 0 then
         return Representation_Profile_Clause;
      elsif Ada.Strings.Fixed.Index (T, "'dimension_system") /= 0 then
         return Representation_Dimension_System_Clause;
      else
         return Representation_Record_Clause;
      end if;
   end Representation_Kind_For;

   function Representation_Property_Is_Boolean
     (Kind : Representation_Clause_Kind) return Boolean
   is
   begin
      return Kind in Representation_Import_Clause |
           Representation_Export_Clause |
           Representation_Pack_Clause |
           Representation_Atomic_Clause |
           Representation_Volatile_Clause |
           Representation_Independent_Clause |
           Representation_Atomic_Components_Clause |
           Representation_Volatile_Components_Clause |
           Representation_Independent_Components_Clause |
           Representation_Unchecked_Union_Clause |
           Representation_Suppress_Initialization_Clause |
           Representation_No_Controlled_Parts_Clause |
           Representation_Preelaborable_Initialization_Clause |
           Representation_No_Task_Parts_Clause |
           Representation_Exclusive_Functions_Clause |
           Representation_Simple_Storage_Pool_Type_Clause |
           Representation_Discard_Names_Clause |
           Representation_Volatile_Function_Clause |
           Representation_Interrupt_Handler_Clause |
           Representation_Async_Readers_Clause |
           Representation_Async_Writers_Clause |
           Representation_Effective_Reads_Clause |
           Representation_Effective_Writes_Clause |
           Representation_Ghost_Clause |
           Representation_Relaxed_Initialization_Clause |
           Representation_Nonblocking_Clause |
           Representation_Nonblocking_Class_Clause |
           Representation_Always_Terminates_Clause |
           Representation_Inline_Clause |
           Representation_Inline_Always_Clause |
           Representation_No_Return_Clause |
           Representation_Elaborate_Body_Clause |
           Representation_Preelaborate_Clause |
           Representation_Pure_Clause |
           Representation_Remote_Types_Clause |
           Representation_Remote_Call_Interface_Clause |
           Representation_All_Calls_Remote_Clause |
           Representation_No_Tagged_Streams_Clause |
           Representation_Extensions_Visible_Clause |
           Representation_Remote_Access_Type_Clause |
           Representation_Shared_Passive_Clause |
           Representation_Side_Effects_Clause |
           Representation_No_Caching_Clause |
           Representation_Warnings_Clause |
           Representation_Weak_External_Clause |
           Representation_Unreferenced_Clause |
           Representation_Unmodified_Clause |
           Representation_No_Elaboration_Code_Clause |
           Representation_Persistent_BSS_Clause |
           Representation_Universal_Aliasing_Clause |
           Representation_Volatile_Full_Access_Clause |
           Representation_Atomic_Always_Lock_Free_Clause |
           Representation_No_Inline_Clause |
           Representation_No_Strict_Aliasing_Clause |
           Representation_Obsolescent_Clause |
           Representation_Reviewable_Clause |
           Representation_No_Heap_Finalization_Clause |
           Representation_Suppress_Debug_Info_Clause;
   end Representation_Property_Is_Boolean;

   function Representation_Source_Form_For
     (Kind : Representation_Clause_Kind) return Representation_Source_Form
   is
   begin
      if Kind = Representation_Address_Clause then
         return Representation_Source_Address_Clause;
      elsif Kind = Representation_Enumeration_Clause then
         return Representation_Source_Enumeration_Clause;
      elsif Kind = Representation_Record_Clause then
         return Representation_Source_Record_Clause;
      else
         return Representation_Source_Attribute_Definition;
      end if;
   end Representation_Source_Form_For;

   function Representation_Property_Has_Static_Natural_Value
     (Kind  : Representation_Clause_Kind;
      Value : String) return Boolean
   is
      Valid : Boolean := False;
      N : Natural := 0;
   begin
      if Kind in Representation_Size_Clause |
           Representation_Alignment_Clause |
           Representation_Record_Mod_Clause |
           Representation_Component_Size_Clause |
           Representation_Object_Size_Clause |
           Representation_Value_Size_Clause |
           Representation_Storage_Size_Clause |
           Representation_Stream_Size_Clause |
           Representation_Max_Entry_Queue_Length_Clause |
           Representation_Priority_Clause |
           Representation_Interrupt_Priority_Clause |
           Representation_CPU_Clause |
           Representation_Max_Size_In_Storage_Elements_Clause |
           Representation_Machine_Radix_Clause |
           Representation_Aft_Clause
      then
         Parse_Static_Natural (Value, Valid, N);
         return Valid;
      else
         return False;
      end if;
   end Representation_Property_Has_Static_Natural_Value;

   function Representation_Property_Static_Natural_Value
     (Kind  : Representation_Clause_Kind;
      Value : String) return Natural
   is
      Valid : Boolean := False;
      N : Natural := 0;
   begin
      if Representation_Property_Has_Static_Natural_Value (Kind, Value) then
         Parse_Static_Natural (Value, Valid, N);
         return N;
      end if;
      return 0;
   end Representation_Property_Static_Natural_Value;

   procedure Parse_Bit_Range
     (Range_Text : String;
      First_Text : out Unbounded_String;
      Last_Text  : out Unbounded_String)
   is
      T : constant String := Trim (Range_Text);
      Match_Pos : constant Natural := Ada.Strings.Fixed.Index (T, "..");
   begin
      if Match_Pos = 0 then
         First_Text := To_Unbounded_String (T);
         Last_Text := To_Unbounded_String (T);
      else
         if Match_Pos > T'First then
            First_Text := To_Unbounded_String
              (Trim (T (T'First .. Match_Pos - 1)));
         else
            First_Text := Null_Unbounded_String;
         end if;
         if Match_Pos + 2 <= T'Last then
            Last_Text := To_Unbounded_String
              (Trim (T (Match_Pos + 2 .. T'Last)));
         else
            Last_Text := Null_Unbounded_String;
         end if;
      end if;
   end Parse_Bit_Range;

end Editor.Ada_Declaration_Parser.Representation_Metadata;
