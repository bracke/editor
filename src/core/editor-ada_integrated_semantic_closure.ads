with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Lifetime_Legality;
with Editor.Ada_Contract_Aspect_Legality;
with Editor.Ada_Elaboration_Dependence_Legality;
with Editor.Ada_Exception_Finalization_Legality;
with Editor.Ada_Overload_Resolution_Legality;
with Editor.Ada_Renaming_Alias_Visibility_Legality;
with Editor.Ada_Representation_Layout_Stream_Integration_Legality;
with Editor.Ada_Staticness_Range_Predicate_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Unit_Completion_Order_Legality;
with Editor.Ada_Wide_Semantic_Legality_Diagnostics;

package Editor.Ada_Integrated_Semantic_Closure is

   --  Pass1118 compiler-grade semantic closure layer.  This package folds the
   --  wide legality diagnostics and the newer overload, staticness,
   --  accessibility, contract, elaboration, completion, renaming, exception,
   --  and representation-integration legality layers into one bounded,
   --  snapshot-owned closure result.  It performs no parsing, file IO,
   --  save/reload, dirty-state mutation, command/keybinding/workspace/render
   --  mutation, or compiler invocation.

   subtype Wide_Diagnostic_Status is
     Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Kind;
   subtype Overload_Status is
     Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Status;
   subtype Static_Status is
     Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Status;
   subtype Accessibility_Status is
     Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Status;
   subtype Contract_Status is
     Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Status;
   subtype Elaboration_Status is
     Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Status;
   subtype Completion_Status is
     Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Status;
   subtype Renaming_Status is
     Editor.Ada_Renaming_Alias_Visibility_Legality.Renaming_Legality_Status;
   subtype Exception_Status is
     Editor.Ada_Exception_Finalization_Legality.Exception_Legality_Status;
   subtype Representation_Status is
     Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Status;
   type Refined_Global_Depends_Status is
     (Refined_Conformance_Not_Checked,
      Refined_Conformance_Legal_Global_Refinement,
      Refined_Conformance_Legal_Depends_Refinement,
      Refined_Conformance_Legal_Null_Refinement,
      Refined_Conformance_Legal_Call_Effect_Propagation,
      Refined_Conformance_Body_Read_Missing_From_Spec_Global,
      Refined_Conformance_Body_Write_Missing_From_Spec_Global,
      Refined_Conformance_Body_Read_Missing_From_Refined_Global,
      Refined_Conformance_Body_Write_Missing_From_Refined_Global,
      Refined_Conformance_Refined_Global_Extra_Item,
      Refined_Conformance_Refined_Global_Mode_Mismatch,
      Refined_Conformance_Refined_Depends_Missing_Edge,
      Refined_Conformance_Refined_Depends_Extra_Edge,
      Refined_Conformance_Refined_Depends_Source_Not_Spec_Input,
      Refined_Conformance_Refined_Depends_Target_Not_Spec_Output,
      Refined_Conformance_Body_Depends_Not_Refined,
      Refined_Conformance_Call_Effect_Not_Propagated,
      Refined_Conformance_Linked_Flow_Graph_Error,
      Refined_Conformance_Coverage_Feedback_Blocker,
      Refined_Conformance_Indeterminate);

   type Integrated_Closure_Context_Id is new Natural;
   No_Integrated_Closure_Context : constant Integrated_Closure_Context_Id := 0;

   type Integrated_Closure_Id is new Natural;
   No_Integrated_Closure : constant Integrated_Closure_Id := 0;

   type Integrated_Closure_Context_Kind is
     (Closure_Context_Compilation_Unit,
      Closure_Context_Package_Spec,
      Closure_Context_Package_Body,
      Closure_Context_Subprogram_Spec,
      Closure_Context_Subprogram_Body,
      Closure_Context_Generic_Declaration,
      Closure_Context_Generic_Instance,
      Closure_Context_Task_Protected_Unit,
      Closure_Context_Private_Part,
      Closure_Context_Representation_Item,
      Closure_Context_Expression,
      Closure_Context_Statement,
      Closure_Context_Unknown);

   type Closure_Dependency_State is
     (Dependency_None,
      Dependency_Local_Only,
      Dependency_Closed,
      Dependency_With_Visible,
      Dependency_Use_Visible,
      Dependency_Limited_View,
      Dependency_Private_View,
      Dependency_Missing,
      Dependency_Ambiguous,
      Dependency_Overflow,
      Dependency_Stale,
      Dependency_Rejected,
      Dependency_Unknown);

   type Closure_Blocker_Family is
     (Closure_Blocker_None,
      Closure_Blocker_Wide_Legality,
      Closure_Blocker_Overload,
      Closure_Blocker_Staticness,
      Closure_Blocker_Accessibility,
      Closure_Blocker_Contract,
      Closure_Blocker_Elaboration,
      Closure_Blocker_Completion,
      Closure_Blocker_Renaming,
      Closure_Blocker_Exception_Finalization,
      Closure_Blocker_Representation,
      Closure_Blocker_Definite_Initialization,
      Closure_Blocker_Dataflow,
      Closure_Blocker_Refined_Global_Depends,
      Closure_Blocker_AST_Coverage,
      Closure_Blocker_Coverage_Gate,
      Closure_Blocker_Dependency,
      Closure_Blocker_Multiple,
      Closure_Blocker_Indeterminate);

   type Integrated_Closure_Status is
     (Integrated_Closure_Not_Checked,
      Integrated_Closure_Legal_Local,
      Integrated_Closure_Legal_Cross_Unit,
      Integrated_Closure_Legal_With_Use_Closure,
      Integrated_Closure_Limited_View_Barrier,
      Integrated_Closure_Private_View_Barrier,
      Integrated_Closure_Missing_Dependency,
      Integrated_Closure_Ambiguous_Dependency,
      Integrated_Closure_Dependency_Overflow,
      Integrated_Closure_Stale_Dependency,
      Integrated_Closure_Rejected_Stale_Input,
      Integrated_Closure_Wide_Legality_Blocker,
      Integrated_Closure_Overload_Blocker,
      Integrated_Closure_Staticness_Blocker,
      Integrated_Closure_Accessibility_Blocker,
      Integrated_Closure_Contract_Blocker,
      Integrated_Closure_Elaboration_Blocker,
      Integrated_Closure_Completion_Blocker,
      Integrated_Closure_Renaming_Blocker,
      Integrated_Closure_Exception_Finalization_Blocker,
      Integrated_Closure_Representation_Blocker,
      Integrated_Closure_Definite_Initialization_Blocker,
      Integrated_Closure_Dataflow_Blocker,
      Integrated_Closure_Refined_Global_Depends_Blocker,
      Integrated_Closure_AST_Coverage_Blocker,
      Integrated_Closure_Coverage_Gate_Blocker,
      Integrated_Closure_Multiple_Blockers,
      Integrated_Closure_Indeterminate);

   type Integrated_Closure_Context_Info is record
      Id                    : Integrated_Closure_Context_Id := No_Integrated_Closure_Context;
      Kind                  : Integrated_Closure_Context_Kind := Closure_Context_Unknown;
      Unit_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Unit_Name  : Ada.Strings.Unbounded.Unbounded_String;
      Dependency_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Dependency : Ada.Strings.Unbounded.Unbounded_String;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Dependency_Node       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Dependency            : Closure_Dependency_State := Dependency_Unknown;
      Primary_Blocker       : Closure_Blocker_Family := Closure_Blocker_None;
      Wide_Legality_Error   : Boolean := False;
      Overload_Error        : Boolean := False;
      Staticness_Error      : Boolean := False;
      Accessibility_Error   : Boolean := False;
      Contract_Error        : Boolean := False;
      Elaboration_Error     : Boolean := False;
      Completion_Error      : Boolean := False;
      Renaming_Error        : Boolean := False;
      Exception_Error       : Boolean := False;
      Representation_Error  : Boolean := False;
      Initialization_Error  : Boolean := False;
      Dataflow_Error        : Boolean := False;
      Refined_Global_Depends_Error : Boolean := False;
      AST_Coverage_Error    : Boolean := False;
      Coverage_Gate_Error   : Boolean := False;
      Indeterminate         : Boolean := False;
      Wide_Diagnostic       : Wide_Diagnostic_Status :=
        Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Assignment_Legality_Error;
      Overload              : Overload_Status :=
        Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Not_Checked;
      Staticness            : Static_Status :=
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Not_Checked;
      Accessibility         : Accessibility_Status :=
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Not_Checked;
      Contract              : Contract_Status :=
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Not_Checked;
      Elaboration           : Elaboration_Status :=
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Not_Checked;
      Completion            : Completion_Status :=
        Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Not_Checked;
      Renaming              : Renaming_Status :=
        Editor.Ada_Renaming_Alias_Visibility_Legality.Renaming_Legality_Not_Checked;
      Exception_Finalization : Exception_Status :=
        Editor.Ada_Exception_Finalization_Legality.Exception_Legality_Not_Checked;
      Representation        : Representation_Status :=
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Not_Checked;
      Refined_Global_Depends : Refined_Global_Depends_Status :=
        Refined_Conformance_Not_Checked;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
   end record;

   type Integrated_Closure_Info is record
      Id                    : Integrated_Closure_Id := No_Integrated_Closure;
      Context               : Integrated_Closure_Context_Id := No_Integrated_Closure_Context;
      Kind                  : Integrated_Closure_Context_Kind := Closure_Context_Unknown;
      Status                : Integrated_Closure_Status := Integrated_Closure_Not_Checked;
      Blocker               : Closure_Blocker_Family := Closure_Blocker_None;
      Unit_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Unit_Name  : Ada.Strings.Unbounded.Unbounded_String;
      Dependency_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Dependency : Ada.Strings.Unbounded.Unbounded_String;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Dependency_Node       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Dependency            : Closure_Dependency_State := Dependency_Unknown;
      Message               : Ada.Strings.Unbounded.Unbounded_String;
      Detail                : Ada.Strings.Unbounded.Unbounded_String;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
      Fingerprint           : Natural := 0;
   end record;

   type Integrated_Closure_Context_Model is private;
   type Integrated_Closure_Result_Set is private;
   type Integrated_Closure_Model is private;

   procedure Clear (Model : in out Integrated_Closure_Context_Model);
   procedure Add_Context
     (Model : in out Integrated_Closure_Context_Model;
      Info  : Integrated_Closure_Context_Info);

   function Context_Count (Model : Integrated_Closure_Context_Model) return Natural;
   function Context_At
     (Model : Integrated_Closure_Context_Model;
      Index : Positive) return Integrated_Closure_Context_Info;
   function Fingerprint (Model : Integrated_Closure_Context_Model) return Natural;

   function Build
     (Contexts : Integrated_Closure_Context_Model) return Integrated_Closure_Model;

   function Closure_Count (Model : Integrated_Closure_Model) return Natural;
   function Closure_At
     (Model : Integrated_Closure_Model;
      Index : Positive) return Integrated_Closure_Info;

   function First_For_Node
     (Model : Integrated_Closure_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Integrated_Closure_Info;
   function First_For_Unit
     (Model : Integrated_Closure_Model;
      Unit  : Ada.Strings.Unbounded.Unbounded_String) return Integrated_Closure_Info;
   function Rows_For_Status
     (Model  : Integrated_Closure_Model;
      Status : Integrated_Closure_Status) return Integrated_Closure_Result_Set;
   function Rows_For_Kind
     (Model : Integrated_Closure_Model;
      Kind  : Integrated_Closure_Context_Kind) return Integrated_Closure_Result_Set;
   function Rows_For_Dependency
     (Model : Integrated_Closure_Model;
      State : Closure_Dependency_State) return Integrated_Closure_Result_Set;
   function Rows_For_Blocker
     (Model   : Integrated_Closure_Model;
      Blocker : Closure_Blocker_Family) return Integrated_Closure_Result_Set;

   function Result_Count (Set : Integrated_Closure_Result_Set) return Natural;
   function Result_At
     (Set   : Integrated_Closure_Result_Set;
      Index : Positive) return Integrated_Closure_Info;

   function Legal_Count (Model : Integrated_Closure_Model) return Natural;
   function Blocker_Count (Model : Integrated_Closure_Model) return Natural;
   function Dependency_Error_Count (Model : Integrated_Closure_Model) return Natural;
   function View_Barrier_Count (Model : Integrated_Closure_Model) return Natural;
   function Stale_Rejected_Count (Model : Integrated_Closure_Model) return Natural;
   function Indeterminate_Count (Model : Integrated_Closure_Model) return Natural;
   function Count_Status
     (Model  : Integrated_Closure_Model;
      Status : Integrated_Closure_Status) return Natural;
   function Count_Kind
     (Model : Integrated_Closure_Model;
      Kind  : Integrated_Closure_Context_Kind) return Natural;
   function Count_Dependency
     (Model : Integrated_Closure_Model;
      State : Closure_Dependency_State) return Natural;
   function Count_Blocker
     (Model   : Integrated_Closure_Model;
      Blocker : Closure_Blocker_Family) return Natural;
   function Fingerprint (Model : Integrated_Closure_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Integrated_Closure_Context_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Integrated_Closure_Info);

   type Integrated_Closure_Context_Model is record
      Contexts    : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Integrated_Closure_Result_Set is record
      Results : Result_Vectors.Vector;
   end record;

   type Integrated_Closure_Model is record
      Rows        : Result_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Integrated_Semantic_Closure;
