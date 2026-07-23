with Ada.Strings.Fixed;
with Editor.Text_Helpers;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;

package body Editor.Ada_Declaration_Parser.Representation_Target_Helpers is

   use Editor.Text_Helpers;
   use Editor.Ada_Language_Model;

   function Is_Type_Like_Target
     (Kind : Symbol_Kind) return Boolean is
   begin
      return Kind in Symbol_Type | Symbol_Subtype | Symbol_Record_Type |
        Symbol_Generic_Formal_Type;
   end Is_Type_Like_Target;

   function Is_Object_Like_Target
     (Kind : Symbol_Kind) return Boolean is
   begin
      return Kind in Symbol_Object | Symbol_Constant | Symbol_Record_Component |
        Symbol_Discriminant | Symbol_Generic_Formal_Object;
   end Is_Object_Like_Target;

   function Is_Subprogram_Like_Target
     (Kind : Symbol_Kind) return Boolean is
   begin
      return Kind in Symbol_Procedure | Symbol_Function | Symbol_Operator_Function |
        Symbol_Entry | Symbol_Generic_Formal_Subprogram;
   end Is_Subprogram_Like_Target;

   function Is_Access_Type_Target
     (Info : Symbol_Info) return Boolean is
   begin
      return Is_Type_Like_Target (Info.Kind)
        and then Info.Flags.Has_Access_Metadata;
   end Is_Access_Type_Target;

   function Is_Storage_Size_Target
     (Info : Symbol_Info) return Boolean is
   begin
      return Is_Access_Type_Target (Info)
        or else Info.Kind = Symbol_Task
        or else Info.Flags.Has_Task_Type_Metadata;
   end Is_Storage_Size_Target;

   function Is_Array_Type_Target
     (Info : Symbol_Info) return Boolean is
   begin
      return Is_Type_Like_Target (Info.Kind)
        and then Info.Flags.Has_Array_Metadata;
   end Is_Array_Type_Target;

   function Is_Fixed_Point_Type_Target
     (Info : Symbol_Info) return Boolean is
   begin
      return Is_Type_Like_Target (Info.Kind)
        and then Info.Flags.Has_Delta_Metadata;
   end Is_Fixed_Point_Type_Target;

   function Is_Floating_Point_Type_Target
     (Info : Symbol_Info) return Boolean is
   begin
      return Is_Type_Like_Target (Info.Kind)
        and then Info.Flags.Has_Digits_Metadata
        and then not Info.Flags.Has_Delta_Metadata;
   end Is_Floating_Point_Type_Target;

   function Is_Atomic_Volatile_Target
     (Info : Symbol_Info) return Boolean is
   begin
      return Is_Type_Like_Target (Info.Kind)
        or else Is_Object_Like_Target (Info.Kind);
   end Is_Atomic_Volatile_Target;

   function Is_Suppress_Initialization_Target
     (Info : Symbol_Info) return Boolean is
   begin
      return Is_Type_Like_Target (Info.Kind)
        or else Is_Object_Like_Target (Info.Kind);
   end Is_Suppress_Initialization_Target;

   function Is_Unchecked_Union_Target
     (Info : Symbol_Info) return Boolean is
   begin
      return Info.Kind = Symbol_Record_Type;
   end Is_Unchecked_Union_Target;

   function Is_Address_Clause_Target
     (Kind : Symbol_Kind) return Boolean is
   begin
      return Is_Object_Like_Target (Kind)
        or else Is_Subprogram_Like_Target (Kind);
   end Is_Address_Clause_Target;

   function Representation_Target_Is_Compatible
     (Clause : Representation_Clause_Info;
      Kind   : Symbol_Kind) return Boolean
   is
   begin
      case Clause.Kind is
         when Representation_Discard_Names_Clause =>
            return Is_Type_Like_Target (Kind) or else Kind = Symbol_Exception;
         when Representation_Record_Clause |
              Representation_Record_Mod_Clause |
              Representation_Enumeration_Clause |
              Representation_Bit_Order_Clause |
              Representation_Storage_Size_Clause |
              Representation_Storage_Pool_Clause |
              Representation_Default_Storage_Pool_Clause |
              Representation_Component_Size_Clause |
              Representation_Scalar_Storage_Order_Clause |
              Representation_Dimension_System_Clause |
              Representation_Dimension_Clause |
              Representation_Small_Clause |
              Representation_Pack_Clause |
              Representation_Atomic_Components_Clause |
              Representation_Volatile_Components_Clause |
              Representation_Independent_Components_Clause |
              Representation_Unchecked_Union_Clause |
              Representation_Stream_Size_Clause |
              Representation_Read_Clause |
              Representation_Write_Clause |
              Representation_Input_Clause |
              Representation_Output_Clause |
              Representation_External_Tag_Clause |
              Representation_Put_Image_Clause |
              Representation_Default_Value_Clause |
              Representation_Default_Component_Value_Clause |
              Representation_Constant_Indexing_Clause |
              Representation_Variable_Indexing_Clause |
              Representation_Implicit_Dereference_Clause |
              Representation_Default_Iterator_Clause |
              Representation_Iterator_Element_Clause |
              Representation_Iterable_Clause |
              Representation_Aggregate_Clause |
              Representation_Max_Entry_Queue_Length_Clause |
              Representation_Integer_Literal_Clause |
              Representation_Real_Literal_Clause |
              Representation_String_Literal_Clause |
              Representation_Max_Size_In_Storage_Elements_Clause |
              Representation_Storage_Model_Type_Clause |
              Representation_Designated_Storage_Model_Clause |
              Representation_Stable_Properties_Clause |
              Representation_Stable_Properties_Class_Clause |
              Representation_Predicate_Clause |
              Representation_Static_Predicate_Clause |
              Representation_Dynamic_Predicate_Clause |
              Representation_Predicate_Failure_Clause |
              Representation_Invariant_Clause |
              Representation_Type_Invariant_Clause |
              Representation_Type_Invariant_Class_Clause |
              Representation_Default_Initial_Condition_Clause |
              Representation_Contract_Cases_Clause |
              Representation_No_Controlled_Parts_Clause |
              Representation_Preelaborable_Initialization_Clause |
              Representation_No_Task_Parts_Clause |
              Representation_Simple_Storage_Pool_Type_Clause |
              Representation_Machine_Radix_Clause |
              Representation_Aft_Clause =>
            return Is_Type_Like_Target (Kind);
         when Representation_Atomic_Clause |
              Representation_Volatile_Clause |
              Representation_Independent_Clause |
              Representation_Suppress_Initialization_Clause |
              Representation_Part_Of_Clause |
              Representation_Ghost_Clause |
              Representation_Relaxed_Initialization_Clause |
              Representation_Async_Readers_Clause |
              Representation_Async_Writers_Clause |
              Representation_Effective_Reads_Clause |
              Representation_Effective_Writes_Clause =>
            return Is_Type_Like_Target (Kind) or else Is_Object_Like_Target (Kind);
         when Representation_Exclusive_Functions_Clause =>
            return Kind = Symbol_Protected;
         when Representation_Priority_Clause |
              Representation_Interrupt_Priority_Clause =>
            return Kind in Symbol_Task | Symbol_Protected;
         when Representation_CPU_Clause |
              Representation_Dispatching_Domain_Clause |
              Representation_Relative_Deadline_Clause =>
            return Kind = Symbol_Task;
         when Representation_Initial_Condition_Clause |
              Representation_Global_Clause |
              Representation_Depends_Clause |
              Representation_Refined_Global_Clause |
              Representation_Refined_Depends_Clause |
              Representation_Abstract_State_Clause |
              Representation_Refined_State_Clause |
              Representation_Initializes_Clause |
              Representation_SPARK_Mode_Clause |
              Representation_Test_Case_Clause |
              Representation_Annotate_Clause |
              Representation_Warnings_Clause =>
            return Kind in Symbol_Package | Symbol_Generic_Package |
              Symbol_Procedure | Symbol_Function | Symbol_Operator_Function |
              Symbol_Generic_Subprogram;
         when Representation_Linker_Section_Clause |
              Representation_Machine_Attribute_Clause =>
            return Is_Type_Like_Target (Kind) or else Is_Object_Like_Target (Kind)
              or else Is_Subprogram_Like_Target (Kind);
         when Representation_Weak_External_Clause |
              Representation_Unreferenced_Clause |
              Representation_Unmodified_Clause =>
            return Is_Object_Like_Target (Kind) or else Is_Subprogram_Like_Target (Kind);
         when Representation_Persistent_BSS_Clause =>
            return Is_Object_Like_Target (Kind);
         when Representation_Universal_Aliasing_Clause |
              Representation_Volatile_Full_Access_Clause |
              Representation_Atomic_Always_Lock_Free_Clause =>
            return Is_Type_Like_Target (Kind) or else Is_Object_Like_Target (Kind);
         when Representation_Pre_Clause |
              Representation_Pre_Class_Clause |
              Representation_Precondition_Clause |
              Representation_Post_Clause |
              Representation_Post_Class_Clause |
              Representation_Postcondition_Clause |
              Representation_Refined_Post_Clause |
              Representation_Subprogram_Variant_Clause |
              Representation_Exceptional_Cases_Clause |
              Representation_Nonblocking_Clause |
              Representation_Nonblocking_Class_Clause |
              Representation_Always_Terminates_Clause |
              Representation_Inline_Clause |
              Representation_Inline_Always_Clause |
              Representation_No_Return_Clause |
              Representation_Volatile_Function_Clause |
              Representation_Interrupt_Handler_Clause |
              Representation_Attach_Handler_Clause |
              Representation_Side_Effects_Clause |
              Representation_No_Caching_Clause |
              Representation_No_Inline_Clause =>
            return Is_Subprogram_Like_Target (Kind);
         when Representation_No_Strict_Aliasing_Clause =>
            return Is_Type_Like_Target (Kind);
         when Representation_Obsolescent_Clause |
              Representation_Suppress_Clause |
              Representation_Unsuppress_Clause =>
            return Kind /= Symbol_Unknown;
         when Representation_Reviewable_Clause |
              Representation_Optimize_Clause =>
            return Kind in Symbol_Package | Symbol_Generic_Package |
              Symbol_Procedure | Symbol_Function | Symbol_Operator_Function |
              Symbol_Generic_Subprogram;
         when Representation_Elaborate_Body_Clause |
              Representation_Preelaborate_Clause |
              Representation_Pure_Clause |
              Representation_Remote_Types_Clause |
              Representation_Remote_Call_Interface_Clause |
              Representation_All_Calls_Remote_Clause |
              Representation_No_Tagged_Streams_Clause |
              Representation_Extensions_Visible_Clause |
              Representation_Remote_Access_Type_Clause |
              Representation_Shared_Passive_Clause |
              Representation_No_Elaboration_Code_Clause |
              Representation_No_Heap_Finalization_Clause |
              Representation_Suppress_Debug_Info_Clause |
              Representation_Assertion_Policy_Clause |
              Representation_Check_Policy_Clause |
              Representation_Debug_Policy_Clause |
              Representation_Restrictions_Clause |
              Representation_Restriction_Warnings_Clause |
              Representation_Profile_Clause |
              Representation_Default_Scalar_Storage_Order_Clause =>
            return Kind in Symbol_Package | Symbol_Generic_Package;
         when Representation_Size_Clause |
              Representation_Alignment_Clause |
              Representation_Object_Size_Clause |
              Representation_Value_Size_Clause =>
            return Is_Type_Like_Target (Kind) or else Is_Object_Like_Target (Kind);
         when Representation_Address_Clause =>
            return Is_Address_Clause_Target (Kind);
         when Representation_Convention_Clause |
              Representation_Import_Clause |
              Representation_Export_Clause |
              Representation_External_Name_Clause |
              Representation_Link_Name_Clause =>
            return True;
         when Representation_Other_Clause =>
            return True;
      end case;
   end Representation_Target_Is_Compatible;

   function Requires_Static_Natural_Value
     (Kind : Representation_Clause_Kind) return Boolean
   is
   begin
      return Kind in Representation_Size_Clause |
        Representation_Alignment_Clause |
        Representation_Record_Mod_Clause |
        Representation_Storage_Size_Clause |
        Representation_Stream_Size_Clause |
        Representation_Max_Entry_Queue_Length_Clause |
        Representation_Priority_Clause |
        Representation_Interrupt_Priority_Clause |
        Representation_CPU_Clause |
        Representation_Max_Size_In_Storage_Elements_Clause |
        Representation_Component_Size_Clause |
        Representation_Object_Size_Clause |
        Representation_Value_Size_Clause |
        Representation_Machine_Radix_Clause |
        Representation_Aft_Clause;
   end Requires_Static_Natural_Value;

   function Is_Valid_Bit_Order_Value (Text : String) return Boolean is
      T : constant String := Lower (Trim (Text));
   begin
      return T = "system.low_order_first" or else T = "low_order_first"
        or else T = "system.high_order_first" or else T = "high_order_first";
   end Is_Valid_Bit_Order_Value;

   function Is_Valid_Scalar_Storage_Order_Value (Text : String) return Boolean is
   begin
      return Is_Valid_Bit_Order_Value (Text);
   end Is_Valid_Scalar_Storage_Order_Value;

   function Is_Representation_Item_Subject_To_Freezing
     (Kind : Representation_Clause_Kind) return Boolean
   is
   begin
      return Kind not in Representation_Preelaborate_Clause |
        Representation_Pure_Clause |
        Representation_Remote_Types_Clause |
        Representation_Remote_Call_Interface_Clause |
        Representation_All_Calls_Remote_Clause |
        Representation_Shared_Passive_Clause |
        Representation_No_Elaboration_Code_Clause |
        Representation_Elaborate_Body_Clause;
   end Is_Representation_Item_Subject_To_Freezing;

end Editor.Ada_Declaration_Parser.Representation_Target_Helpers;
