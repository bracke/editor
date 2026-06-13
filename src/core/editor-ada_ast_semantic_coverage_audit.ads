with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_AST_Semantic_Coverage_Audit is

   --  Pass1132 compiler-grade parser/AST-to-semantic coverage audit.
   --
   --  This package records whether Ada 2022 grammar constructs that feed the
   --  widened semantic legality layers have parser nodes, structural AST shape,
   --  resolver/type metadata, and an enabled semantic consumer.  It is intended
   --  to prevent legality packages from silently degrading because a construct
   --  was parsed only as tokens or outline text.  Inputs are snapshot-owned facts
   --  supplied by callers; this package performs no parsing, file IO, dirty-state
   --  mutation, command/keybinding/workspace/render mutation, or compiler
   --  invocation.

   type Coverage_Item_Id is new Natural;
   No_Coverage_Item : constant Coverage_Item_Id := 0;

   type Ada_Construct_Kind is
     (Construct_Aspect_Specification,
      Construct_Representation_Clause,
      Construct_Operational_Attribute_Clause,
      Construct_Pragma,
      Construct_Generic_Formal_Object,
      Construct_Generic_Formal_Type,
      Construct_Generic_Formal_Subprogram,
      Construct_Generic_Formal_Package,
      Construct_Generic_Instantiation,
      Construct_Generic_Renaming,
      Construct_Task_Type,
      Construct_Task_Body,
      Construct_Protected_Type,
      Construct_Protected_Body,
      Construct_Entry_Declaration,
      Construct_Entry_Body,
      Construct_Accept_Statement,
      Construct_Requeue_Statement,
      Construct_Select_Statement,
      Construct_Separate_Body,
      Construct_Body_Stub,
      Construct_Renaming_Declaration,
      Construct_Access_Definition,
      Construct_Allocator,
      Construct_Return_Statement,
      Construct_Extended_Return,
      Construct_Assignment,
      Construct_Call,
      Construct_Conversion,
      Construct_Qualified_Expression,
      Construct_Record_Aggregate,
      Construct_Extension_Aggregate,
      Construct_Array_Aggregate,
      Construct_Container_Aggregate,
      Construct_Delta_Aggregate,
      Construct_Reduction_Expression,
      Construct_Quantified_Expression,
      Construct_Membership_Test,
      Construct_Case_Expression,
      Construct_If_Expression,
      Construct_Declare_Expression,
      Construct_Target_Name,
      Construct_Discriminant_Specification,
      Construct_Variant_Part,
      Construct_Exception_Handler,
      Construct_Raise_Expression,
      Construct_Unknown);

   type Semantic_Consumer_Family is
     (Consumer_None,
      Consumer_Assignment,
      Consumer_Return,
      Consumer_Conversion_Access_Aggregate,
      Consumer_Control_Flow,
      Consumer_Tasking_Protected,
      Consumer_Tagged_Derived,
      Consumer_Generic_Contracts,
      Consumer_Cross_Unit_Closure,
      Consumer_Expression_Types,
      Consumer_Overload,
      Consumer_Staticness_Range_Predicate,
      Consumer_Accessibility_Lifetime,
      Consumer_Contract_Aspect,
      Consumer_Elaboration_Dependence,
      Consumer_Unit_Completion_Order,
      Consumer_Renaming_Alias_Visibility,
      Consumer_Exception_Finalization,
      Consumer_Representation_Layout_Stream,
      Consumer_Definite_Initialization,
      Consumer_Dataflow_Global_Depends,
      Consumer_Predicate_Invariant_Use_Site,
      Consumer_Generic_Instance_Body_Expansion,
      Consumer_Overload_Preference,
      Consumer_Record_Variant_Aggregate,
      Consumer_Accessibility_Precision,
      Consumer_Elaboration_Precision,
      Consumer_Tasking_Protected_Precision,
      Consumer_Representation_Freezing_Precision,
      Consumer_Integrated_Closure);

   type Coverage_Status is
     (Coverage_Not_Checked,
      Coverage_Complete,
      Coverage_Parser_Node_Missing,
      Coverage_AST_Shape_Missing,
      Coverage_Token_Only_Parse,
      Coverage_Span_Missing,
      Coverage_Name_Binding_Missing,
      Coverage_Type_Metadata_Missing,
      Coverage_Staticness_Metadata_Missing,
      Coverage_Contract_Metadata_Missing,
      Coverage_Flow_Metadata_Missing,
      Coverage_Representation_Metadata_Missing,
      Coverage_Cross_Unit_Metadata_Missing,
      Coverage_Consumer_Missing,
      Coverage_Consumer_Not_Integrated,
      Coverage_Graceful_Degradation_Only,
      Coverage_Indeterminate);

   type Coverage_Context_Info is record
      Id                         : Coverage_Item_Id := No_Coverage_Item;
      Construct                  : Ada_Construct_Kind := Construct_Unknown;
      Consumer                   : Semantic_Consumer_Family := Consumer_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Parent_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Construct_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Construct_Name  : Ada.Strings.Unbounded.Unbounded_String;
      Parser_Node_Present        : Boolean := True;
      Structural_AST_Present     : Boolean := True;
      Token_Only_Parse           : Boolean := False;
      Span_Present               : Boolean := True;
      Name_Binding_Present       : Boolean := True;
      Type_Metadata_Present      : Boolean := True;
      Staticness_Metadata_Present : Boolean := True;
      Contract_Metadata_Present  : Boolean := True;
      Flow_Metadata_Present      : Boolean := True;
      Representation_Metadata_Present : Boolean := True;
      Cross_Unit_Metadata_Present : Boolean := True;
      Consumer_Present           : Boolean := True;
      Consumer_Integrated        : Boolean := True;
      Graceful_Degradation_Only  : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Coverage_Info is record
      Id                         : Coverage_Item_Id := No_Coverage_Item;
      Construct                  : Ada_Construct_Kind := Construct_Unknown;
      Consumer                   : Semantic_Consumer_Family := Consumer_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Parent_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status                     : Coverage_Status := Coverage_Not_Checked;
      Construct_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Construct_Name  : Ada.Strings.Unbounded.Unbounded_String;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
      Detail                     : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint         : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Fingerprint                : Natural := 0;
   end record;

   type Coverage_Context_Model is private;
   type Coverage_Result_Set is private;
   type Coverage_Model is private;

   procedure Clear (Model : in out Coverage_Context_Model);
   procedure Add_Context
     (Model   : in out Coverage_Context_Model;
      Context : Coverage_Context_Info);

   function Context_Count (Model : Coverage_Context_Model) return Natural;
   function Context_At
     (Model : Coverage_Context_Model;
      Index : Positive) return Coverage_Context_Info;

   function Build (Contexts : Coverage_Context_Model) return Coverage_Model;

   function Coverage_Count (Model : Coverage_Model) return Natural;
   function Coverage_At
     (Model : Coverage_Model;
      Index : Positive) return Coverage_Info;

   function First_For_Node
     (Model : Coverage_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Coverage_Info;
   function Rows_For_Status
     (Model  : Coverage_Model;
      Status : Coverage_Status) return Coverage_Result_Set;
   function Rows_For_Construct
     (Model     : Coverage_Model;
      Construct : Ada_Construct_Kind) return Coverage_Result_Set;
   function Rows_For_Consumer
     (Model    : Coverage_Model;
      Consumer : Semantic_Consumer_Family) return Coverage_Result_Set;

   function Result_Count (Results : Coverage_Result_Set) return Natural;
   function Result_At
     (Results : Coverage_Result_Set;
      Index   : Positive) return Coverage_Info;

   function Count_Status
     (Model  : Coverage_Model;
      Status : Coverage_Status) return Natural;
   function Count_Construct
     (Model     : Coverage_Model;
      Construct : Ada_Construct_Kind) return Natural;
   function Count_Consumer
     (Model    : Coverage_Model;
      Consumer : Semantic_Consumer_Family) return Natural;

   function Complete_Count (Model : Coverage_Model) return Natural;
   function Missing_Parser_Count (Model : Coverage_Model) return Natural;
   function Missing_AST_Count (Model : Coverage_Model) return Natural;
   function Missing_Metadata_Count (Model : Coverage_Model) return Natural;
   function Missing_Consumer_Count (Model : Coverage_Model) return Natural;
   function Degradation_Count (Model : Coverage_Model) return Natural;
   function Error_Count (Model : Coverage_Model) return Natural;
   function Fingerprint (Model : Coverage_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Coverage_Context_Info);

   package Info_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Coverage_Info);

   type Coverage_Context_Model is record
      Items       : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Coverage_Result_Set is record
      Items : Info_Vectors.Vector;
   end record;

   type Coverage_Model is record
      Items       : Info_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

end Editor.Ada_AST_Semantic_Coverage_Audit;
