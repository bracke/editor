with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
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

end Editor.Ada_Declaration_Parser.Representation_Metadata;
