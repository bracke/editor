with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_AST_Semantic_Coverage_Audit;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Semantic_Coverage_Gates is

   --  Pass1134 semantic coverage gates.
   --
   --  This package turns parser/AST semantic coverage audit facts into
   --  legality-safety gates.  Downstream semantic packages can use the gate
   --  result before emitting a confident legality conclusion for a construct.
   --  Missing parser nodes, token-only parses, structural AST gaps, metadata
   --  gaps, missing consumers, non-integrated consumers, graceful-degradation
   --  paths, and cross-unit coverage gaps are classified as gates that require
   --  a semantic result to be suppressed, degraded to indeterminate, or routed
   --  through cross-unit closure instead of reported as legal.
   --
   --  The model is snapshot-owned and deterministic.  It performs no parsing,
   --  no file IO, no dirty-state mutation, no rendering-side parsing, no
   --  command/keybinding/workspace/render mutation, and no compiler invocation.

   package Audit renames Editor.Ada_AST_Semantic_Coverage_Audit;

   type Gate_Item_Id is new Natural;
   No_Gate_Item : constant Gate_Item_Id := 0;

   type Semantic_Conclusion_Kind is
     (Conclusion_Assignment,
      Conclusion_Return,
      Conclusion_Conversion,
      Conclusion_Aggregate,
      Conclusion_Call,
      Conclusion_Overload,
      Conclusion_Staticness,
      Conclusion_Accessibility,
      Conclusion_Contract,
      Conclusion_Dataflow,
      Conclusion_Generic_Instance,
      Conclusion_Record_Variant,
      Conclusion_Elaboration,
      Conclusion_Tasking_Protected,
      Conclusion_Representation,
      Conclusion_Exception_Finalization,
      Conclusion_Integrated_Closure,
      Conclusion_Unknown);

   type Gate_Action is
     (Gate_Allow_Confident_Result,
      Gate_Degrade_To_Indeterminate,
      Gate_Suppress_Legal_Result,
      Gate_Suppress_Derived_Result,
      Gate_Require_Cross_Unit_Closure,
      Gate_Require_Parser_AST_Repair,
      Gate_Require_Metadata_Repair,
      Gate_Require_Consumer_Integration,
      Gate_Block_Unsafe_Result);

   type Gate_Status is
     (Gate_Not_Checked,
      Gate_Open,
      Gate_Parser_Node_Missing,
      Gate_Token_Only_Parse,
      Gate_AST_Shape_Missing,
      Gate_Source_Span_Missing,
      Gate_Name_Binding_Missing,
      Gate_Type_Metadata_Missing,
      Gate_Staticness_Metadata_Missing,
      Gate_Contract_Metadata_Missing,
      Gate_Flow_Metadata_Missing,
      Gate_Representation_Metadata_Missing,
      Gate_Cross_Unit_Metadata_Missing,
      Gate_Consumer_Missing,
      Gate_Consumer_Not_Integrated,
      Gate_Graceful_Degradation_Only,
      Gate_Construct_Indeterminate,
      Gate_Unknown);

   type Gate_Context_Info is record
      Id                    : Gate_Item_Id := No_Gate_Item;
      Conclusion            : Semantic_Conclusion_Kind := Conclusion_Unknown;
      Construct             : Audit.Ada_Construct_Kind := Audit.Construct_Unknown;
      Consumer              : Audit.Semantic_Consumer_Family := Audit.Consumer_None;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Parent_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Construct_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Coverage              : Audit.Coverage_Status := Audit.Coverage_Not_Checked;
      Source_Fingerprint    : Natural := 0;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
   end record;

   type Gate_Info is record
      Id                    : Gate_Item_Id := No_Gate_Item;
      Conclusion            : Semantic_Conclusion_Kind := Conclusion_Unknown;
      Construct             : Audit.Ada_Construct_Kind := Audit.Construct_Unknown;
      Consumer              : Audit.Semantic_Consumer_Family := Audit.Consumer_None;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Parent_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status                : Gate_Status := Gate_Not_Checked;
      Action                : Gate_Action := Gate_Block_Unsafe_Result;
      Construct_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Message               : Ada.Strings.Unbounded.Unbounded_String;
      Detail                : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint    : Natural := 0;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Fingerprint           : Natural := 0;
   end record;

   type Gate_Context_Model is private;
   type Gate_Result_Set is private;
   type Gate_Model is private;

   procedure Clear (Model : in out Gate_Context_Model);
   procedure Add_Context
     (Model   : in out Gate_Context_Model;
      Context : Gate_Context_Info);

   procedure Add_From_Coverage
     (Model      : in out Gate_Context_Model;
      Coverage   : Audit.Coverage_Info;
      Conclusion : Semantic_Conclusion_Kind := Conclusion_Unknown);

   function Build (Contexts : Gate_Context_Model) return Gate_Model;
   function Build_From_Coverage
     (Coverage   : Audit.Coverage_Model;
      Conclusion : Semantic_Conclusion_Kind := Conclusion_Unknown) return Gate_Model;

   function Gate_Count (Model : Gate_Model) return Natural;
   function Gate_At
     (Model : Gate_Model;
      Index : Positive) return Gate_Info;

   function First_For_Node
     (Model : Gate_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Gate_Info;
   function Rows_For_Status
     (Model  : Gate_Model;
      Status : Gate_Status) return Gate_Result_Set;
   function Rows_For_Action
     (Model  : Gate_Model;
      Action : Gate_Action) return Gate_Result_Set;
   function Rows_For_Conclusion
     (Model      : Gate_Model;
      Conclusion : Semantic_Conclusion_Kind) return Gate_Result_Set;

   function Result_Count (Set : Gate_Result_Set) return Natural;
   function Result_At
     (Set   : Gate_Result_Set;
      Index : Positive) return Gate_Info;

   function Count_Status
     (Model  : Gate_Model;
      Status : Gate_Status) return Natural;
   function Count_Action
     (Model  : Gate_Model;
      Action : Gate_Action) return Natural;
   function Count_Conclusion
     (Model      : Gate_Model;
      Conclusion : Semantic_Conclusion_Kind) return Natural;

   function Open_Count (Model : Gate_Model) return Natural;
   function Suppressed_Count (Model : Gate_Model) return Natural;
   function Degraded_Count (Model : Gate_Model) return Natural;
   function Repair_Required_Count (Model : Gate_Model) return Natural;
   function Cross_Unit_Required_Count (Model : Gate_Model) return Natural;
   function Unsafe_Blocker_Count (Model : Gate_Model) return Natural;
   function Fingerprint (Model : Gate_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Gate_Context_Info);
   package Info_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Gate_Info);

   type Gate_Context_Model is record
      Items       : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Gate_Result_Set is record
      Items : Info_Vectors.Vector;
   end record;

   type Gate_Model is record
      Items       : Info_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Semantic_Coverage_Gates;
