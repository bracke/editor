with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Syntax;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Language_Model is

   type Symbol_Kind is
     (Symbol_Package,
      Symbol_Package_Body,
      Symbol_Procedure,
      Symbol_Function,
      Symbol_Operator_Function,
      Symbol_Type,
      Symbol_Subtype,
      Symbol_Record_Type,
      Symbol_Record_Component,
      Symbol_Discriminant,
      Symbol_Enumeration_Literal,
      Symbol_Object,
      Symbol_Constant,
      Symbol_Exception,
      Symbol_Task,
      Symbol_Protected,
      Symbol_Entry,
      Symbol_Generic_Package,
      Symbol_Generic_Subprogram,
      Symbol_Generic_Formal_Type,
      Symbol_Generic_Formal_Object,
      Symbol_Generic_Formal_Subprogram,
      Symbol_Generic_Formal_Package,
      Symbol_Rename,
      Symbol_Instantiation,
      Symbol_Separate_Body,
      Symbol_Unknown);


   type Statement_Kind is
     (Statement_If,
      Statement_Case,
      Statement_Loop,
      Statement_While_Loop,
      Statement_For_Loop,
      Statement_For_In_Loop,
      Statement_For_Of_Loop,
      Statement_For_Reverse_Loop,
      Statement_Declare_Block,
      Statement_Declare_Action,
      Statement_Begin_Block,
      Statement_Begin_Action,
      Statement_Return,
      Statement_Return_With_Expression,
      Statement_Raise,
      Statement_Raise_Reraise,
      Statement_Raise_Exception_Name,
      Statement_Raise_With_Message,
      Statement_Goto,
      Statement_Goto_Label_Target,
      Statement_Exit,
      Statement_Exit_Named_Loop,
      Statement_Exit_When,
      Statement_Delay,
      Statement_Delay_Until,
      Statement_Delay_Relative,
      Statement_Delay_Alternative,
      Statement_Delay_Alternative_Until,
      Statement_Delay_Alternative_Relative,
      Statement_Select,
      Statement_Select_Entry_Call,
      Statement_Select_Else_Action,
      Statement_Select_Else_Null,
      Statement_Select_Else_Return,
      Statement_Select_Else_Raise,
      Statement_Select_Else_Assignment,
      Statement_Select_Else_Call,
      Statement_Select_Else_Code,
      Statement_Select_Else_Exit,
      Statement_Select_Else_Goto,
      Statement_Select_Else_Delay,
      Statement_Select_Else_Delay_Until,
      Statement_Select_Else_Delay_Relative,
      Statement_Select_Else_Requeue,
      Statement_Select_Else_Requeue_With_Abort,
      Statement_Select_Else_Abort,
      Statement_Select_Else_Pragma,
      Statement_Select_Else_Pragma_With_Arguments,
      Statement_Select_Delay_Fallback,
      Statement_Select_Delay_Fallback_Until,
      Statement_Select_Delay_Fallback_Relative,
      Statement_Select_Delay_Fallback_Action,
      Statement_Select_Delay_Fallback_Null,
      Statement_Select_Delay_Fallback_Call,
      Statement_Select_Delay_Fallback_Call_With_Arguments,
      Statement_Select_Delay_Fallback_Call_With_Named_Association,
      Statement_Select_Delay_Fallback_Call_Selected_Name,
      Statement_Select_Delay_Fallback_Call_Access_Dereference,
      Statement_Select_Delay_Fallback_Call_Entry_Family_Index,
      Statement_Select_Delay_Fallback_Assignment,
      Statement_Select_Delay_Fallback_Return,
      Statement_Select_Delay_Fallback_Raise,
      Statement_Select_Delay_Fallback_Code,
      Statement_Select_Delay_Fallback_Exit,
      Statement_Select_Delay_Fallback_Goto,
      Statement_Select_Delay_Fallback_Delay,
      Statement_Select_Delay_Fallback_Delay_Until,
      Statement_Select_Delay_Fallback_Delay_Relative,
      Statement_Select_Delay_Fallback_Requeue,
      Statement_Select_Delay_Fallback_Requeue_With_Abort,
      Statement_Select_Delay_Fallback_Abort,
      Statement_Select_Delay_Fallback_Pragma,
      Statement_Select_Delay_Fallback_Pragma_With_Arguments,
      Statement_Select_Then_Abort_Fallback,
      Statement_Select_Terminate_Fallback,
      Statement_Select_Abortable_Call,
      Statement_Accept,
      Statement_Accept_Alternative,
      Statement_Accept_Body,
      Statement_Accept_With_Profile,
      Statement_Accept_Entry_Family_Index,
      Statement_Requeue,
      Statement_Requeue_With_Abort,
      Statement_Requeue_Selected_Target,
      Statement_Requeue_With_Arguments,
      Statement_Abort,
      Statement_Abort_Selected_Target,
      Statement_Abort_Multiple_Targets,
      Statement_Null,
      Statement_Null_Alternative,
      Statement_Alternative_Raise,
      Statement_Alternative_Return,
      Statement_Alternative_Return_With_Expression,
      Statement_Alternative_Assignment,
      Statement_Alternative_Call,
      Statement_Alternative_Exit,
      Statement_Alternative_Goto,
      Statement_Alternative_Delay,
      Statement_Alternative_Requeue,
      Statement_Alternative_Abort,
      Statement_Alternative_Code,
      Statement_Assignment,
      Statement_Assignment_Selected_Target,
      Statement_Assignment_Indexed_Target,
      Statement_Assignment_Slice_Target,
      Statement_Assignment_Access_Dereference,
      Statement_Call,
      Statement_Call_With_Arguments,
      Statement_Call_With_Named_Association,
      Statement_Call_Selected_Name,
      Statement_Call_Access_Dereference,
      Statement_Call_Attribute_Name,
      Statement_Call_Entry_Family_Index,
      Statement_Code,
      Statement_Pragma,
      Statement_Pragma_With_Arguments,
      Statement_Alternative_Pragma,
      Statement_Compact_Sequence,
      Statement_Label,
      Statement_Named_Block,
      Statement_Named_Loop,
      Statement_Elsif,
      Statement_Else,
      Statement_When_Alternative,
      Statement_Exception_Handler,
      Statement_Or_Alternative,
      Statement_Then_Abort_Alternative,
      Statement_Then_Abort_Action,
      Statement_Loop_Action,
      Statement_Case_Alternative_Action,
      Statement_Exception_Handler_Action,
      Statement_Then_Action,
      Statement_Elsif_Action,
      Statement_Else_Action,
      Statement_Terminate_Alternative,
      Statement_Extended_Return,
      Statement_End_Return,
      Statement_End_Block,
      Statement_End_If,
      Statement_End_Case,
      Statement_End_Loop,
      Statement_End_Named_Loop,
      Statement_End_Select);

   type Symbol_Id is new Natural;
   type Scope_Id is new Natural;

   No_Symbol : constant Symbol_Id := 0;
   Root_Scope : constant Scope_Id := 0;

   type Source_Range is record
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
   end record;

   type Declaration_Flags is record
      Is_Private        : Boolean := False;
      Is_Abstract       : Boolean := False;
      Is_Overriding     : Boolean := False;
      Is_Not_Overriding : Boolean := False;
      Is_Generic        : Boolean := False;
      Is_Rename         : Boolean := False;
      Is_Instantiation  : Boolean := False;
      Is_Separate       : Boolean := False;
      Is_Body           : Boolean := False;
      Has_Representation_Clause : Boolean := False;
      Has_Aspect_Specification  : Boolean := False;
      Has_Pragma_Metadata       : Boolean := False;
      Has_Null_Exclusion        : Boolean := False;
      Has_Aliased_Metadata       : Boolean := False;
      Has_Limited_Metadata       : Boolean := False;
      Has_Tagged_Metadata        : Boolean := False;
      Has_Interface_Metadata     : Boolean := False;
      Has_Synchronized_Metadata  : Boolean := False;
      Has_Task_Interface_Metadata : Boolean := False;
      Has_Protected_Interface_Metadata : Boolean := False;
      Has_Task_Type_Metadata : Boolean := False;
      Has_Protected_Type_Metadata : Boolean := False;
      Has_Access_Metadata        : Boolean := False;
      Has_Access_All_Metadata    : Boolean := False;
      Has_Access_Constant_Metadata : Boolean := False;
      Has_Class_Wide_Metadata : Boolean := False;
      Has_Access_Subprogram_Metadata : Boolean := False;
      Has_Access_Protected_Metadata : Boolean := False;
      Has_Array_Metadata         : Boolean := False;
      Has_Derived_Metadata       : Boolean := False;
      Has_Range_Metadata         : Boolean := False;
      Has_Modular_Metadata       : Boolean := False;
      Has_Digits_Metadata        : Boolean := False;
      Has_Delta_Metadata         : Boolean := False;
      Has_Variant_Record_Metadata : Boolean := False;
      Has_Default_Expression_Metadata : Boolean := False;
      Has_Entry_Family_Metadata : Boolean := False;
      Has_Incomplete_Type_Metadata : Boolean := False;
      Has_Profile_Mode_Metadata : Boolean := False;
      Has_Entry_Barrier_Metadata : Boolean := False;
      Has_Box_Metadata : Boolean := False;
      Has_Private_Extension_Metadata : Boolean := False;
      Has_Named_Number_Metadata : Boolean := False;
      Has_Deferred_Constant_Metadata : Boolean := False;
      Has_Null_Subprogram_Metadata : Boolean := False;
      Has_Expression_Function_Metadata : Boolean := False;
      Has_Null_Record_Metadata : Boolean := False;
      Has_Discriminant_Part_Metadata : Boolean := False;
      Has_Body_Stub_Metadata : Boolean := False;
      Has_Constraint_Metadata : Boolean := False;
      Has_Child_Unit_Metadata : Boolean := False;
      Has_Generic_Actual_Part_Metadata : Boolean := False;
   end record;

   type Symbol_Info is record
      Id              : Symbol_Id := No_Symbol;
      Name            : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name : Ada.Strings.Unbounded.Unbounded_String;
      Kind            : Symbol_Kind := Symbol_Unknown;
      Source_Span           : Source_Range;
      Declaration_Line   : Positive := 1;
      Declaration_Column : Positive := 1;
      Enclosing_Scope : Scope_Id := Root_Scope;
      Parent_Symbol   : Symbol_Id := No_Symbol;
      Depth           : Natural := 0;
      Profile_Summary : Ada.Strings.Unbounded.Unbounded_String;
      Flags           : Declaration_Flags;
      Target_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint     : Natural := 0;
   end record;




   type Executable_Binding_Kind is
     (Binding_Any,
      Binding_Loop_Parameter,
      Binding_Declare_Object,
      Binding_Exception_Handler_Choice,
      Binding_Exception_Occurrence,
      Binding_Assignment_Target,
      Binding_Call_Target,
      Binding_Call_Selected_Prefix,
      Binding_Call_Selected_Operation,
      Binding_Call_Dispatching_Prefix,
      Binding_Call_Indexed_Prefix,
      Binding_Call_Entry_Family_Candidate,
      Binding_Named_Actual,
      Binding_Generic_Actual_Selector,
      Binding_Aggregate_Component_Selector,
      Binding_Selected_Component,
      Binding_Array_Index,
      Binding_Array_Slice,
      Binding_Range_Bound,
      Binding_Pragma_Argument,
      Binding_Aspect_Expression,
      Binding_Quantified_Parameter,
      Binding_Quantified_Source,
      Binding_Dereference,
      Binding_Allocator,
      Binding_Aggregate_Component,
      Binding_Qualified_Expression_Target,
      Binding_Type_Conversion_Target,
      Binding_Attribute_Prefix,
      Binding_Return_Target,
      Binding_Return_Object,
      Binding_Return_Object_Defining_Name,
      Binding_Delay_Target,
      Binding_Abort_Target,
      Binding_Condition_Target,
      Binding_Iteration_Source,
      Binding_Iteration_Filter,
      Binding_Select_Guard,
      Binding_Select_Entry_Call,
      Binding_Select_Delay_Target,
      Binding_Select_Terminate,
      Binding_Select_Abort,
      Binding_Entry_Barrier,
      Binding_Raise_Target,
      Binding_Raise_Expression_Target,
      Binding_Delta_Aggregate_Base,
      Binding_Delta_Aggregate_Component,
      Binding_Requeue_Target,
      Binding_Accept_Entry,
      Binding_Accept_Parameter,
      Binding_Entry_Family_Index,
      Binding_Exit_Target,
      Binding_Block_Label,
      Binding_Case_Choice,
      Binding_Case_Expression_Selector,
      Binding_Case_Expression_Choice,
      Binding_Conditional_Expression_Condition,
      Binding_Conditional_Expression_Branch,
      Binding_Label_Declaration,
      Binding_Goto_Target);

   type Executable_Binding_Info is record
      Kind : Executable_Binding_Kind := Binding_Call_Target;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name : Ada.Strings.Unbounded.Unbounded_String;
      Expression_Text : Ada.Strings.Unbounded.Unbounded_String;
      Scope : Scope_Id := Root_Scope;
      Target_Symbol : Symbol_Id := No_Symbol;
      Source_Span : Source_Range;
      Fingerprint : Natural := 0;
   end record;

   type Visibility_Clause_Kind is
     (Visibility_With_Clause,
      Visibility_Limited_With_Clause,
      Visibility_Private_With_Clause,
      Visibility_Use_Package_Clause,
      Visibility_Use_Type_Clause,
      Visibility_Use_All_Type_Clause);

   type Visibility_Clause_Info is record
      Kind : Visibility_Clause_Kind := Visibility_With_Clause;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name : Ada.Strings.Unbounded.Unbounded_String;
      Scope : Scope_Id := Root_Scope;
      Is_Context_Clause : Boolean := False;
      Has_Limited_Modifier : Boolean := False;
      Has_Private_Modifier : Boolean := False;
      Source_Span : Source_Range;
      Fingerprint : Natural := 0;
   end record;

   type Generic_Actual_Info is record
      Instance_Symbol : Symbol_Id := No_Symbol;
      Formal_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Formal_Name : Ada.Strings.Unbounded.Unbounded_String;
      Actual_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Actual_Name : Ada.Strings.Unbounded.Unbounded_String;
      Position        : Natural := 0;
      Source_Span           : Source_Range;
      Fingerprint     : Natural := 0;
   end record;

   type Profile_Parameter_Mode is
     (Profile_Parameter_Default_In,
      Profile_Parameter_In,
      Profile_Parameter_Out,
      Profile_Parameter_In_Out);

   type Profile_Parameter_Info is record
      Owner_Symbol : Symbol_Id := No_Symbol;
      Parameter_Symbol : Symbol_Id := No_Symbol;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name : Ada.Strings.Unbounded.Unbounded_String;
      Mode : Profile_Parameter_Mode := Profile_Parameter_Default_In;
      Type_Text : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Type_Text : Ada.Strings.Unbounded.Unbounded_String;
      Has_Aliased : Boolean := False;
      Has_Access_Definition : Boolean := False;
      Has_Access_Subprogram_Profile : Boolean := False;
      Has_Default_Expression : Boolean := False;
      Default_Text : Ada.Strings.Unbounded.Unbounded_String;
      Group_Index : Natural := 0;
      Group_Position : Natural := 0;
      Group_Name_Count : Natural := 0;
      Source_Span : Source_Range;
      Fingerprint : Natural := 0;
   end record;

   type Generic_Formal_Type_Family is
     (Generic_Formal_Type_Private,
      Generic_Formal_Type_Derived,
      Generic_Formal_Type_Discrete,
      Generic_Formal_Type_Signed_Integer,
      Generic_Formal_Type_Modular_Integer,
      Generic_Formal_Type_Floating_Point,
      Generic_Formal_Type_Ordinary_Fixed_Point,
      Generic_Formal_Type_Decimal_Fixed_Point,
      Generic_Formal_Type_Array,
      Generic_Formal_Type_Access_Object,
      Generic_Formal_Type_Access_Subprogram,
      Generic_Formal_Type_Interface,
      Generic_Formal_Type_Unknown);

   type Generic_Formal_Type_Info is record
      Formal_Symbol : Symbol_Id := No_Symbol;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name : Ada.Strings.Unbounded.Unbounded_String;
      Family : Generic_Formal_Type_Family := Generic_Formal_Type_Unknown;
      Target_Type_Text : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Target_Type_Text : Ada.Strings.Unbounded.Unbounded_String;
      Profile_Text : Ada.Strings.Unbounded.Unbounded_String;
      Has_Private : Boolean := False;
      Has_Limited : Boolean := False;
      Has_Tagged : Boolean := False;
      Has_Abstract : Boolean := False;
      Has_Synchronized : Boolean := False;
      Has_Interface : Boolean := False;
      Has_Box : Boolean := False;
      Has_Discriminant_Part : Boolean := False;
      Source_Span : Source_Range;
      Fingerprint : Natural := 0;
   end record;

   type Pragma_Placement_Kind is
     (Pragma_Placement_Configuration,
      Pragma_Placement_Declaration,
      Pragma_Placement_Statement,
      Pragma_Placement_Alternative);

   type Pragma_Info is record
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name : Ada.Strings.Unbounded.Unbounded_String;
      Placement : Pragma_Placement_Kind := Pragma_Placement_Declaration;
      Scope : Scope_Id := Root_Scope;
      Target_Name : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Target_Name : Ada.Strings.Unbounded.Unbounded_String;
      Argument_Count : Natural := 0;
      Named_Argument_Count : Natural := 0;
      Source_Span : Source_Range;
      Fingerprint : Natural := 0;
   end record;


   type Representation_Source_Form is
     (Representation_Source_Attribute_Definition,
      Representation_Source_Aspect,
      Representation_Source_Pragma,
      Representation_Source_Address_Clause,
      Representation_Source_Enumeration_Clause,
      Representation_Source_Record_Clause,
      Representation_Source_Record_Component_Clause);

   type Representation_Clause_Kind is
     (Representation_Record_Clause,
      Representation_Record_Mod_Clause,
      Representation_Enumeration_Clause,
      Representation_Size_Clause,
      Representation_Alignment_Clause,
      Representation_Bit_Order_Clause,
      Representation_Address_Clause,
      Representation_Storage_Size_Clause,
      Representation_Storage_Pool_Clause,
      Representation_Default_Storage_Pool_Clause,
      Representation_Component_Size_Clause,
      Representation_Object_Size_Clause,
      Representation_Value_Size_Clause,
      Representation_Scalar_Storage_Order_Clause,
      Representation_Small_Clause,
      Representation_Pack_Clause,
      Representation_Machine_Radix_Clause,
      Representation_Aft_Clause,
      Representation_Atomic_Clause,
      Representation_Volatile_Clause,
      Representation_Independent_Clause,
      Representation_Atomic_Components_Clause,
      Representation_Volatile_Components_Clause,
      Representation_Independent_Components_Clause,
      Representation_Unchecked_Union_Clause,
      Representation_Suppress_Initialization_Clause,
      Representation_Stream_Size_Clause,
      Representation_Read_Clause,
      Representation_Write_Clause,
      Representation_Input_Clause,
      Representation_Output_Clause,
      Representation_External_Tag_Clause,
      Representation_Put_Image_Clause,
      Representation_Default_Value_Clause,
      Representation_Default_Component_Value_Clause,
      Representation_Constant_Indexing_Clause,
      Representation_Variable_Indexing_Clause,
      Representation_Implicit_Dereference_Clause,
      Representation_Default_Iterator_Clause,
      Representation_Iterator_Element_Clause,
      Representation_Iterable_Clause,
      Representation_Aggregate_Clause,
      Representation_Max_Entry_Queue_Length_Clause,
      Representation_Priority_Clause,
      Representation_Interrupt_Priority_Clause,
      Representation_CPU_Clause,
      Representation_Dispatching_Domain_Clause,
      Representation_No_Controlled_Parts_Clause,
      Representation_Preelaborable_Initialization_Clause,
      Representation_No_Task_Parts_Clause,
      Representation_Exclusive_Functions_Clause,
      Representation_Simple_Storage_Pool_Type_Clause,
      Representation_Discard_Names_Clause,
      Representation_Volatile_Function_Clause,
      Representation_Interrupt_Handler_Clause,
      Representation_Attach_Handler_Clause,
      Representation_Async_Readers_Clause,
      Representation_Async_Writers_Clause,
      Representation_Effective_Reads_Clause,
      Representation_Effective_Writes_Clause,
      Representation_Integer_Literal_Clause,
      Representation_Real_Literal_Clause,
      Representation_String_Literal_Clause,
      Representation_Max_Size_In_Storage_Elements_Clause,
      Representation_Storage_Model_Type_Clause,
      Representation_Designated_Storage_Model_Clause,
      Representation_Stable_Properties_Clause,
      Representation_Stable_Properties_Class_Clause,
      Representation_Predicate_Clause,
      Representation_Static_Predicate_Clause,
      Representation_Dynamic_Predicate_Clause,
      Representation_Predicate_Failure_Clause,
      Representation_Invariant_Clause,
      Representation_Type_Invariant_Clause,
      Representation_Type_Invariant_Class_Clause,
      Representation_Initial_Condition_Clause,
      Representation_Default_Initial_Condition_Clause,
      Representation_Pre_Clause,
      Representation_Pre_Class_Clause,
      Representation_Precondition_Clause,
      Representation_Post_Clause,
      Representation_Post_Class_Clause,
      Representation_Postcondition_Clause,
      Representation_Refined_Post_Clause,
      Representation_Global_Clause,
      Representation_Depends_Clause,
      Representation_Refined_Global_Clause,
      Representation_Refined_Depends_Clause,
      Representation_Abstract_State_Clause,
      Representation_Refined_State_Clause,
      Representation_Initializes_Clause,
      Representation_Part_Of_Clause,
      Representation_Ghost_Clause,
      Representation_Relaxed_Initialization_Clause,
      Representation_Nonblocking_Clause,
      Representation_Nonblocking_Class_Clause,
      Representation_Always_Terminates_Clause,
      Representation_Inline_Clause,
      Representation_Inline_Always_Clause,
      Representation_No_Return_Clause,
      Representation_Elaborate_Body_Clause,
      Representation_Preelaborate_Clause,
      Representation_Pure_Clause,
      Representation_All_Calls_Remote_Clause,
      Representation_No_Tagged_Streams_Clause,
      Representation_Extensions_Visible_Clause,
      Representation_Remote_Access_Type_Clause,
      Representation_Remote_Types_Clause,
      Representation_Remote_Call_Interface_Clause,
      Representation_Shared_Passive_Clause,
      Representation_Relative_Deadline_Clause,
      Representation_Contract_Cases_Clause,
      Representation_Subprogram_Variant_Clause,
      Representation_Exceptional_Cases_Clause,
      Representation_SPARK_Mode_Clause,
      Representation_Side_Effects_Clause,
      Representation_No_Caching_Clause,
      Representation_Test_Case_Clause,
      Representation_Annotate_Clause,
      Representation_Warnings_Clause,
      Representation_Linker_Section_Clause,
      Representation_Machine_Attribute_Clause,
      Representation_Weak_External_Clause,
      Representation_Unreferenced_Clause,
      Representation_Unmodified_Clause,
      Representation_No_Elaboration_Code_Clause,
      Representation_Persistent_BSS_Clause,
      Representation_Universal_Aliasing_Clause,
      Representation_Volatile_Full_Access_Clause,
      Representation_Atomic_Always_Lock_Free_Clause,
      Representation_No_Inline_Clause,
      Representation_No_Strict_Aliasing_Clause,
      Representation_Obsolescent_Clause,
      Representation_Reviewable_Clause,
      Representation_Optimize_Clause,
      Representation_Suppress_Clause,
      Representation_Unsuppress_Clause,
      Representation_No_Heap_Finalization_Clause,
      Representation_Suppress_Debug_Info_Clause,
      Representation_Assertion_Policy_Clause,
      Representation_Check_Policy_Clause,
      Representation_Debug_Policy_Clause,
      Representation_Restrictions_Clause,
      Representation_Restriction_Warnings_Clause,
      Representation_Profile_Clause,
      Representation_Default_Scalar_Storage_Order_Clause,
      Representation_Dimension_System_Clause,
      Representation_Dimension_Clause,
      Representation_Convention_Clause,
      Representation_Import_Clause,
      Representation_Export_Clause,
      Representation_External_Name_Clause,
      Representation_Link_Name_Clause,
      Representation_Other_Clause);

   type Representation_Clause_Info is record
      Target_Symbol : Symbol_Id := No_Symbol;
      Target_Name : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Target_Name : Ada.Strings.Unbounded.Unbounded_String;
      Kind : Representation_Clause_Kind := Representation_Other_Clause;
      Attribute_Name : Ada.Strings.Unbounded.Unbounded_String;
      Item_Text : Ada.Strings.Unbounded.Unbounded_String;
      Source_Form : Representation_Source_Form :=
        Representation_Source_Attribute_Definition;
      Has_Static_Value : Boolean := False;
      Static_Value : Natural := 0;
      Source_Span : Source_Range;
      Fingerprint : Natural := 0;
   end record;

   type Enumeration_Representation_Literal_Info is record
      Target_Symbol : Symbol_Id := No_Symbol;
      Literal_Symbol : Symbol_Id := No_Symbol;
      Literal_Name : Ada.Strings.Unbounded.Unbounded_String;
      Value_Text : Ada.Strings.Unbounded.Unbounded_String;
      Has_Static_Value : Boolean := False;
      Static_Value : Natural := 0;
      Source_Span : Source_Range;
      Fingerprint : Natural := 0;
   end record;

   type Representation_Component_Info is record
      Target_Symbol : Symbol_Id := No_Symbol;
      Component_Symbol : Symbol_Id := No_Symbol;
      Component_Name : Ada.Strings.Unbounded.Unbounded_String;
      Storage_Unit_Text : Ada.Strings.Unbounded.Unbounded_String;
      First_Bit_Text : Ada.Strings.Unbounded.Unbounded_String;
      Last_Bit_Text : Ada.Strings.Unbounded.Unbounded_String;
      Source_Form : Representation_Source_Form :=
        Representation_Source_Record_Component_Clause;
      Has_Static_Storage_Unit : Boolean := False;
      Static_Storage_Unit : Natural := 0;
      Has_Static_First_Bit : Boolean := False;
      Static_First_Bit : Natural := 0;
      Has_Static_Last_Bit : Boolean := False;
      Static_Last_Bit : Natural := 0;
      Source_Span : Source_Range;
      Fingerprint : Natural := 0;
   end record;

   Max_Analysis_Symbols : constant Positive := 4096;
   Max_Visibility_Clauses : constant Positive := 1024;
   Max_Generic_Actuals : constant Positive := 2048;
   Max_Profile_Parameters : constant Positive := 4096;
   Max_Generic_Formal_Types : constant Positive := 2048;
   Max_Pragmas : constant Positive := 2048;
   Max_Representation_Clauses : constant Positive := 2048;
   Max_Enumeration_Representation_Literals : constant Positive := 4096;
   Max_Representation_Components : constant Positive := 4096;


   type Legality_Diagnostic_Severity is
     (Legality_Note,
      Legality_Warning,
      Legality_Error);

   type Legality_Diagnostic_Kind is
     (Legality_Duplicate_Declaration,
      Legality_Duplicate_Profile_Parameter,
      Legality_Duplicate_Record_Component_Name,
      Legality_Duplicate_Discriminant_Name,
      Legality_Duplicate_Enumeration_Literal_Name,
      Legality_Duplicate_Generic_Formal_Name,
      Legality_Duplicate_Representation_Clause,
      Legality_Representation_Target_Not_Found,
      Legality_Representation_Target_Incompatible,
      Legality_Representation_Static_Value_Required,
      Legality_Bit_Order_Invalid_Value,
      Legality_Enumeration_Representation_Missing_Literal,
      Legality_Enumeration_Representation_Literal_Not_Found,
      Legality_Enumeration_Representation_Target_Not_Enumeration,
      Legality_Enumeration_Representation_Order_Mismatch,
      Legality_Record_Component_Target_Not_Record,
      Legality_Record_Component_Not_Found,
      Legality_Duplicate_Enumeration_Representation_Value,
      Legality_Duplicate_Enumeration_Representation_Literal,
      Legality_Enumeration_Representation_Static_Value_Required,
      Legality_Record_Component_Static_Position_Required,
      Legality_Record_Component_Static_Bit_Range_Required,
      Legality_Record_Component_Invalid_Bit_Range,
      Legality_Record_Component_Bit_Out_Of_Storage_Unit,
      Legality_Record_Component_Overlap,
      Legality_Record_Component_Cross_Storage_Overlap,
      Legality_Record_Mod_Target_Not_Record,
      Legality_Record_Mod_Static_Value_Required,
      Legality_Record_Mod_Positive_Value_Required,
      Legality_Record_Component_Size_Too_Small,
      Legality_Duplicate_Record_Component_Representation,
      Legality_Duplicate_Generic_Actual_Formal,
      Legality_Positional_Generic_Actual_After_Named,
      Legality_Generic_Others_Actual_Not_Last,
      Legality_Generic_Others_Actual_Must_Be_Box,
      Legality_Renaming_Missing_Target,
      Legality_Renaming_Self_Target,
      Legality_Duplicate_Label,
      Legality_Duplicate_Block_Label,
      Legality_Goto_Missing_Target,
      Legality_Exit_Missing_Target,
      Legality_Duplicate_Visibility_Clause,
      Legality_Duplicate_Call_Named_Actual,
      Legality_Positional_Call_Actual_After_Named,
      Legality_Duplicate_Pragma_Named_Argument,
      Legality_Duplicate_Aspect_Association,
      Legality_Duplicate_Case_Choice,
      Legality_Duplicate_Variant_Choice,
      Legality_Duplicate_Exception_Choice,
      Legality_Duplicate_Aggregate_Component_Choice,
      Legality_Duplicate_Delta_Aggregate_Component,
      Legality_Operational_Attribute_Handler_Not_Found,
      Legality_Operational_Attribute_Handler_Incompatible,
      Legality_Storage_Pool_Target_Not_Access,
      Legality_Storage_Size_Target_Incompatible,
      Legality_Component_Size_Target_Not_Array,
      Legality_Object_Value_Size_Target_Incompatible,
      Legality_Scalar_Storage_Order_Target_Incompatible,
      Legality_Scalar_Storage_Order_Invalid_Value,
      Legality_Small_Target_Not_Fixed_Point,
      Legality_Pack_Boolean_Value_Required,
      Legality_Interfacing_Attribute_Target_Incompatible,
      Legality_Interfacing_Link_Name_Target_Incompatible,
      Legality_Interfacing_String_Value_Required,
      Legality_Convention_Identifier_Required,
      Legality_Import_Export_Boolean_Value_Required,
      Legality_Address_Target_Incompatible,
      Legality_Address_Value_Required,
      Legality_Address_Value_Incompatible,
      Legality_Address_Value_Not_Static_Address,
      Legality_Address_Value_Null_Not_Allowed,
      Legality_Machine_Radix_Target_Not_Floating_Point,
      Legality_Aft_Target_Not_Fixed_Point,
      Legality_Small_Static_Value_Required,
      Legality_Representation_Positive_Value_Required,
      Legality_Atomic_Volatile_Target_Incompatible,
      Legality_Atomic_Volatile_Boolean_Value_Required,
      Legality_Unchecked_Union_Target_Incompatible,
      Legality_Unchecked_Union_Boolean_Value_Required,
      Legality_Suppress_Initialization_Target_Incompatible,
      Legality_Suppress_Initialization_Boolean_Value_Required,
      Legality_Storage_Pool_Value_Incompatible,
      Legality_Convention_Identifier_Unknown,
      Legality_Interfacing_Import_Export_Conflict,
      Legality_Interfacing_Link_Name_Requires_Import_Export,
      Legality_Stream_Attribute_Profile_Incompatible,
      Legality_Stream_Attribute_Mode_Incompatible,
      Legality_Malformed_Pragma_Syntax,
      Legality_Malformed_Aspect_Association,
      Legality_Missing_Metadata_Terminator,
      Legality_Missing_Declaration_Terminator,
      Legality_Malformed_Handler_Alternative,
      Legality_Malformed_Variant_Alternative,
      Legality_Malformed_Case_Alternative,
      Legality_Representation_After_Freezing,
      Legality_Representation_Before_Completion);


   type Freezing_Point_Kind is
     (Freezing_First_Use,
      Freezing_Body_Completion,
      Freezing_Generic_Instance,
      Freezing_Generic_Formal_Use,
      Freezing_Generic_Formal_Instance);

   type Freezing_Point_Info is record
      Target_Symbol : Symbol_Id := No_Symbol;
      Trigger_Symbol : Symbol_Id;
      Kind : Freezing_Point_Kind := Freezing_First_Use;
      Reason : Ada.Strings.Unbounded.Unbounded_String;
      Source_Span : Source_Range;
      Fingerprint : Natural := 0;
   end record;

   type Legality_Diagnostic_Info is record
      Kind : Legality_Diagnostic_Kind := Legality_Duplicate_Declaration;
      Severity : Legality_Diagnostic_Severity := Legality_Error;
      Primary_Symbol : Symbol_Id := No_Symbol;
      Related_Symbol : Symbol_Id := No_Symbol;
      Target_Name : Ada.Strings.Unbounded.Unbounded_String;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Source_Span : Source_Range;
      Fingerprint : Natural := 0;
   end record;

   Max_Executable_Bindings : constant Positive := 8192;
   Max_Legality_Diagnostics : constant Positive := 2048;
   Max_Freezing_Points : constant Positive := 2048;

   subtype Diagnostic_Info is Legality_Diagnostic_Info;

   type Analysis_Result is private;

   procedure Clear (Analysis : in out Analysis_Result);

   function Add_Symbol
     (Analysis           : in out Analysis_Result;
      Name               : String;
      Kind               : Symbol_Kind;
      Source_Span              : Source_Range;
      Declaration_Column : Positive := 1;
      Enclosing_Scope    : Scope_Id := Root_Scope;
      Parent_Symbol      : Symbol_Id := No_Symbol;
      Depth              : Natural := 0;
      Profile_Summary    : String := "";
      Flags              : Declaration_Flags := (others => False);
      Target_Name        : String := "") return Symbol_Id;

   function Symbol_Count (Analysis : Analysis_Result) return Natural;

   procedure Set_Symbol_Kind
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id;
      Kind     : Symbol_Kind);

   procedure Set_Symbol_Target
     (Analysis    : in out Analysis_Result;
      Id          : Symbol_Id;
      Target_Name : String);

   procedure Set_Symbol_Profile
     (Analysis        : in out Analysis_Result;
      Id              : Symbol_Id;
      Profile_Summary : String);

   procedure Mark_Symbol_Instantiation
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id);

   procedure Mark_Symbol_Representation_Clause
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id);

   procedure Mark_Symbol_Pragma_Metadata
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id);

   procedure Mark_Symbol_Aspect_Specification
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id);

   procedure Mark_Symbol_Access_Subprogram_Metadata
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id);

   procedure Merge_Symbol_Flags
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id;
      Flags    : Declaration_Flags);

   procedure Mark_Symbol_Variant_Record_Metadata
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id);


   procedure Add_Generic_Actual
     (Analysis        : in out Analysis_Result;
      Instance_Symbol : Symbol_Id;
      Formal_Name     : String := "";
      Actual_Name     : String;
      Position        : Natural := 0;
      Source_Span           : Source_Range := (others => 1));

   function Generic_Actual_Count
     (Analysis        : Analysis_Result;
      Instance_Symbol : Symbol_Id := No_Symbol) return Natural;

   function Generic_Actual_At
     (Analysis        : Analysis_Result;
      Instance_Symbol : Symbol_Id;
      Index           : Positive) return Generic_Actual_Info;

   procedure Add_Profile_Parameter_Metadata
     (Analysis                      : in out Analysis_Result;
      Owner_Symbol                  : Symbol_Id;
      Parameter_Symbol              : Symbol_Id;
      Name                          : String;
      Mode                          : Profile_Parameter_Mode;
      Type_Text                     : String := "";
      Has_Aliased                   : Boolean := False;
      Has_Access_Definition         : Boolean := False;
      Has_Access_Subprogram_Profile : Boolean := False;
      Has_Default_Expression        : Boolean := False;
      Default_Text                  : String := "";
      Group_Index                   : Natural := 0;
      Group_Position                : Natural := 0;
      Group_Name_Count              : Natural := 0;
      Source_Span                         : Source_Range := (others => 1));

   function Profile_Parameter_Count
     (Analysis     : Analysis_Result;
      Owner_Symbol : Symbol_Id := No_Symbol) return Natural;

   function Profile_Parameter_At
     (Analysis     : Analysis_Result;
      Owner_Symbol : Symbol_Id;
      Index        : Positive) return Profile_Parameter_Info;

   procedure Add_Generic_Formal_Type_Metadata
     (Analysis                  : in out Analysis_Result;
      Formal_Symbol             : Symbol_Id;
      Name                      : String;
      Family                    : Generic_Formal_Type_Family;
      Target_Type_Text          : String := "";
      Profile_Text              : String := "";
      Has_Private               : Boolean := False;
      Has_Limited               : Boolean := False;
      Has_Tagged                : Boolean := False;
      Has_Abstract              : Boolean := False;
      Has_Synchronized          : Boolean := False;
      Has_Interface             : Boolean := False;
      Has_Box                   : Boolean := False;
      Has_Discriminant_Part     : Boolean := False;
      Source_Span                     : Source_Range := (others => 1));

   function Generic_Formal_Type_Metadata_Count
     (Analysis      : Analysis_Result;
      Formal_Symbol : Symbol_Id := No_Symbol) return Natural;

   function Generic_Formal_Type_Metadata_At
     (Analysis      : Analysis_Result;
      Formal_Symbol : Symbol_Id;
      Index         : Positive) return Generic_Formal_Type_Info;

   procedure Add_Pragma_Metadata
     (Analysis             : in out Analysis_Result;
      Name                 : String;
      Placement            : Pragma_Placement_Kind;
      Scope                : Scope_Id := Root_Scope;
      Target_Name          : String := "";
      Argument_Count       : Natural := 0;
      Named_Argument_Count : Natural := 0;
      Source_Span                : Source_Range := (others => 1));

   function Pragma_Metadata_Count
     (Analysis  : Analysis_Result;
      Placement : Pragma_Placement_Kind := Pragma_Placement_Declaration;
      Any_Placement : Boolean := True) return Natural;

   function Pragma_Metadata_At
     (Analysis  : Analysis_Result;
      Index     : Positive) return Pragma_Info;


   procedure Add_Representation_Clause
     (Analysis          : in out Analysis_Result;
      Target_Symbol     : Symbol_Id := No_Symbol;
      Target_Name       : String;
      Kind              : Representation_Clause_Kind;
      Attribute_Name    : String := "";
      Item_Text         : String;
      Source_Form       : Representation_Source_Form :=
        Representation_Source_Attribute_Definition;
      Has_Static_Value  : Boolean := False;
      Static_Value      : Natural := 0;
      Source_Span             : Source_Range);

   function Representation_Clause_Count
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id := No_Symbol) return Natural;

   function Representation_Clause_At
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id;
      Index         : Positive) return Representation_Clause_Info;

   procedure Add_Enumeration_Representation_Literal
     (Analysis         : in out Analysis_Result;
      Target_Symbol    : Symbol_Id;
      Literal_Symbol   : Symbol_Id := No_Symbol;
      Literal_Name     : String;
      Value_Text       : String;
      Has_Static_Value : Boolean := False;
      Static_Value     : Natural := 0;
      Source_Span            : Source_Range);

   function Enumeration_Representation_Literal_Count
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id := No_Symbol) return Natural;

   function Enumeration_Representation_Literal_At
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id;
      Index         : Positive) return Enumeration_Representation_Literal_Info;

   procedure Add_Record_Representation_Component
     (Analysis          : in out Analysis_Result;
      Target_Symbol     : Symbol_Id;
      Component_Symbol  : Symbol_Id := No_Symbol;
      Component_Name    : String;
      Storage_Unit_Text : String;
      First_Bit_Text    : String;
      Last_Bit_Text     : String;
      Source_Form       : Representation_Source_Form :=
        Representation_Source_Record_Component_Clause;
      Has_Static_Storage_Unit : Boolean := False;
      Static_Storage_Unit     : Natural := 0;
      Has_Static_First_Bit    : Boolean := False;
      Static_First_Bit        : Natural := 0;
      Has_Static_Last_Bit     : Boolean := False;
      Static_Last_Bit         : Natural := 0;
      Source_Span             : Source_Range);

   function Representation_Component_Count
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id := No_Symbol) return Natural;

   function Representation_Component_At
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id;
      Index         : Positive) return Representation_Component_Info;


   procedure Add_Legality_Diagnostic
     (Analysis       : in out Analysis_Result;
      Kind           : Legality_Diagnostic_Kind;
      Message        : String;
      Severity       : Legality_Diagnostic_Severity := Legality_Error;
      Primary_Symbol : Symbol_Id := No_Symbol;
      Related_Symbol : Symbol_Id := No_Symbol;
      Source_Span          : Source_Range := (others => 1));

   function Legality_Diagnostic_Count
     (Analysis : Analysis_Result;
      Severity : Legality_Diagnostic_Severity := Legality_Error) return Natural;

   function Legality_Diagnostic_At
     (Analysis : Analysis_Result;
      Index    : Positive) return Legality_Diagnostic_Info;

   function Has_Legality_Diagnostics
     (Analysis : Analysis_Result;
      Severity : Legality_Diagnostic_Severity := Legality_Error) return Boolean;

   function Diagnostic_Count
     (Analysis : Analysis_Result;
      Severity : Legality_Diagnostic_Severity := Legality_Error) return Natural;

   function Diagnostic_At
     (Analysis : Analysis_Result;
      Index    : Positive) return Diagnostic_Info;

   procedure Add_Freezing_Point
     (Analysis       : in out Analysis_Result;
      Target_Symbol  : Symbol_Id;
      Trigger_Symbol : Symbol_Id;
      Kind           : Freezing_Point_Kind;
      Reason         : String;
      Source_Span          : Source_Range);

   function Freezing_Point_Count
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id := No_Symbol) return Natural;

   function Freezing_Point_At
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id;
      Index         : Positive) return Freezing_Point_Info;



   procedure Add_Executable_Binding
     (Analysis        : in out Analysis_Result;
      Kind            : Executable_Binding_Kind;
      Name            : String;
      Expression_Text : String := "";
      Scope           : Scope_Id := Root_Scope;
      Target_Symbol   : Symbol_Id := No_Symbol;
      Source_Span           : Source_Range := (others => 1));

   function Executable_Binding_Count
     (Analysis : Analysis_Result;
      Kind     : Executable_Binding_Kind := Binding_Any)
      return Natural;

   function Executable_Binding_At
     (Analysis : Analysis_Result;
      Index    : Positive) return Executable_Binding_Info;

   function Has_Executable_Bindings (Analysis : Analysis_Result) return Boolean;

   function Symbol (Analysis : Analysis_Result; Id : Symbol_Id) return Symbol_Info;
   function Symbol_At (Analysis : Analysis_Result; Index : Positive) return Symbol_Info;

   function Child_Count
     (Analysis : Analysis_Result;
      Parent   : Symbol_Id) return Natural;

   function Child_At
     (Analysis : Analysis_Result;
      Parent   : Symbol_Id;
      Index    : Positive) return Symbol_Id;

   function Overload_Count
     (Analysis : Analysis_Result;
      Scope    : Scope_Id;
      Name     : String) return Natural;

   function Overload_At
     (Analysis : Analysis_Result;
      Scope    : Scope_Id;
      Name     : String;
      Index    : Positive) return Symbol_Id;

   procedure Mark_Generated_Source_Awareness (Analysis : in out Analysis_Result);
   procedure Mark_Conditional_Source_Awareness (Analysis : in out Analysis_Result);
   procedure Mark_With_Clause_Awareness (Analysis : in out Analysis_Result);
   procedure Mark_Use_Clause_Awareness (Analysis : in out Analysis_Result);

   procedure Add_Visibility_Clause
     (Analysis             : in out Analysis_Result;
      Kind                 : Visibility_Clause_Kind;
      Name                 : String;
      Scope                : Scope_Id := Root_Scope;
      Source_Span                : Source_Range := (others => 1);
      Is_Context_Clause    : Boolean := False;
      Has_Limited_Modifier : Boolean := False;
      Has_Private_Modifier : Boolean := False);

   function Visibility_Clause_Count
     (Analysis : Analysis_Result;
      Scope    : Scope_Id := Scope_Id'Last) return Natural;

   function Visibility_Clause_At
     (Analysis : Analysis_Result;
      Scope    : Scope_Id;
      Index    : Positive) return Visibility_Clause_Info;

   function Context_Clause_Count
     (Analysis : Analysis_Result) return Natural;

   function Context_Clause_At
     (Analysis : Analysis_Result;
      Index    : Positive) return Visibility_Clause_Info;

   function Use_Clause_Count
     (Analysis : Analysis_Result;
      Scope    : Scope_Id := Scope_Id'Last) return Natural;

   function Use_Clause_At
     (Analysis : Analysis_Result;
      Scope    : Scope_Id;
      Index    : Positive) return Visibility_Clause_Info;

   function Overflowed (Analysis : Analysis_Result) return Boolean;
   function Has_Generated_Source_Awareness (Analysis : Analysis_Result) return Boolean;
   function Has_Conditional_Source_Awareness (Analysis : Analysis_Result) return Boolean;
   function Has_With_Clause_Awareness (Analysis : Analysis_Result) return Boolean;
   function Has_Use_Clause_Awareness (Analysis : Analysis_Result) return Boolean;

   procedure Mark_Statement_Kind
     (Analysis : in out Analysis_Result;
      Kind     : Statement_Kind);

   function Statement_Count
     (Analysis : Analysis_Result;
      Kind     : Statement_Kind) return Natural;

   function Total_Statement_Count (Analysis : Analysis_Result) return Natural;
   function Has_Statement_Awareness (Analysis : Analysis_Result) return Boolean;

   procedure Set_Syntax_Tree
     (Analysis : in out Analysis_Result;
      Tree     : Editor.Ada_Syntax_Tree.Tree_Type);

   function Has_Syntax_Tree (Analysis : Analysis_Result) return Boolean;
   function Syntax_Tree_Node_Count (Analysis : Analysis_Result) return Natural;
   function Syntax_Tree_Root_Kind
     (Analysis : Analysis_Result) return Editor.Ada_Syntax_Tree.Node_Kind;
   function Syntax_Tree_Fingerprint (Analysis : Analysis_Result) return Natural;
   function Syntax_Tree
     (Analysis : Analysis_Result) return Editor.Ada_Syntax_Tree.Tree_Type;

   function Fingerprint (Analysis : Analysis_Result) return Natural;

   function Normalize_Name (Name : String) return String;
   function Kind_To_Syntax_Kind (Kind : Symbol_Kind) return Editor.Syntax.Token_Kind;
   function Is_Subprogram (Kind : Symbol_Kind) return Boolean;
   function Is_Type_Like (Kind : Symbol_Kind) return Boolean;
   function Is_Declaration_Owner (Kind : Symbol_Kind) return Boolean;
   function Is_Separate_Body_Parent_Target (Symbol : Symbol_Info) return Boolean;

   --  Conservative lexical-scope bridge for semantic colouring.  Returns the
   --  deepest declaration-owning symbol that starts before the requested
   --  source position and contains it when a retained range is available, or
   --  No_Symbol for root scope.  This is intentionally bounded by the retained
   --  analysis and degrades to root when ownership metadata is incomplete.
   function Scope_For_Position
     (Analysis : Analysis_Result;
      Line     : Positive;
      Column   : Positive) return Symbol_Id;

private
   type Statement_Count_Array is array (Statement_Kind) of Natural;

   package Symbol_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Symbol_Info);




   package Executable_Binding_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Executable_Binding_Info);

   package Visibility_Clause_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Visibility_Clause_Info);

   package Generic_Actual_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Generic_Actual_Info);

   package Profile_Parameter_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Profile_Parameter_Info);

   package Generic_Formal_Type_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Generic_Formal_Type_Info);

   package Pragma_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Pragma_Info);


   package Representation_Clause_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Representation_Clause_Info);

   package Enumeration_Representation_Literal_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Enumeration_Representation_Literal_Info);

   package Representation_Component_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Representation_Component_Info);

   package Freezing_Point_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Freezing_Point_Info);

   package Legality_Diagnostic_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Legality_Diagnostic_Info);

   type Analysis_Result is record
      Symbols         : Symbol_Vectors.Vector;
      Executable_Bindings : Executable_Binding_Vectors.Vector;
      Visibility_Clauses : Visibility_Clause_Vectors.Vector;
      Generic_Actuals : Generic_Actual_Vectors.Vector;
      Profile_Parameters : Profile_Parameter_Vectors.Vector;
      Generic_Formal_Types : Generic_Formal_Type_Vectors.Vector;
      Pragmas : Pragma_Vectors.Vector;

      Representation_Clauses : Representation_Clause_Vectors.Vector;
      Enumeration_Representation_Literals : Enumeration_Representation_Literal_Vectors.Vector;
      Representation_Components : Representation_Component_Vectors.Vector;
      Freezing_Points : Freezing_Point_Vectors.Vector;
      Legality_Diagnostics : Legality_Diagnostic_Vectors.Vector;
      Symbol_Overflow : Boolean := False;
      Generated_Source_Aware : Boolean := False;
      Conditional_Source_Aware : Boolean := False;
      With_Clause_Aware : Boolean := False;
      Use_Clause_Aware : Boolean := False;
      Statement_Aware : Boolean := False;
      Statement_Counts : Statement_Count_Array := (others => 0);
      Syntax_Tree_Value : Editor.Ada_Syntax_Tree.Tree_Type;
      Syntax_Tree_Aware : Boolean := False;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Language_Model;
