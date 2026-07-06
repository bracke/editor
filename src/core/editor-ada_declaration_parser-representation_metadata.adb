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

end Editor.Ada_Declaration_Parser.Representation_Metadata;
