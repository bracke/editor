with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Scope_Graph_Legality;
with Editor.Ada_Discriminant_Dependent_Legality;
with Editor.Ada_Elaboration_Graph_Closure_Legality;
with Editor.Ada_Flow_Effect_Graph_Legality;
with Editor.Ada_Generic_Instance_Body_Semantic_Replay;
with Editor.Ada_Predicate_Invariant_Propagation_Legality;
with Editor.Ada_Representation_Freezing_Precision_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Protected_Effects_Legality;
with Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

package Editor.Ada_Representation_Freezing_Exact_Propagation_Legality is

   --  Case 1146 compiler-grade representation/freezing exact propagation.
   --
   --  This package deepens representation/freezing legality from precision
   --  classification into explicit propagation of implicit freezing caused by
   --  semantic uses.  It connects generic body replay, discriminant/variant
   --  constraints, flow effects, predicate/invariant propagation, accessibility
   --  scope graphs, elaboration closure, tasking/protected effects, operational
   --  streaming/finalization effects, and coverage-gated semantic results.  All
   --  inputs are caller-supplied snapshot facts; this package performs no
   --  parsing, file IO, compiler invocation, dirty-state mutation, UI mutation,
   --  external parser generation, Python, or shell-script work.

   package Precision renames Editor.Ada_Representation_Freezing_Precision_Legality;
   package Replay renames Editor.Ada_Generic_Instance_Body_Semantic_Replay;
   package Discriminants renames Editor.Ada_Discriminant_Dependent_Legality;
   package Flow renames Editor.Ada_Flow_Effect_Graph_Legality;
   package Predicates renames Editor.Ada_Predicate_Invariant_Propagation_Legality;
   package Scope renames Editor.Ada_Accessibility_Scope_Graph_Legality;
   package Elab renames Editor.Ada_Elaboration_Graph_Closure_Legality;
   package Tasking renames Editor.Ada_Tasking_Protected_Effects_Legality;
   package Gates renames Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

   type Freezing_Propagation_Id is new Natural;
   No_Freezing_Propagation : constant Freezing_Propagation_Id := 0;

   type Freezing_Propagation_Context_Kind is
     (Freezing_Propagation_Context_Object_Declaration,
      Freezing_Propagation_Context_Subprogram_Body,
      Freezing_Propagation_Context_Expression_Use,
      Freezing_Propagation_Context_Call_Use,
      Freezing_Propagation_Context_Generic_Instance,
      Freezing_Propagation_Context_Generic_Body_Replay,
      Freezing_Propagation_Context_Private_Full_View,
      Freezing_Propagation_Context_Discriminant_Constraint,
      Freezing_Propagation_Context_Variant_Representation,
      Freezing_Propagation_Context_Record_Layout,
      Freezing_Propagation_Context_Representation_Clause,
      Freezing_Propagation_Context_Operational_Attribute,
      Freezing_Propagation_Context_Stream_Attribute,
      Freezing_Propagation_Context_Finalization_Effect,
      Freezing_Propagation_Context_Elaboration_Edge,
      Freezing_Propagation_Context_Tasking_Effect,
      Freezing_Propagation_Context_Unknown);

   type Freezing_Propagation_Status is
     (Freezing_Propagation_Not_Checked,
      Freezing_Propagation_Legal_No_Freezing,
      Freezing_Propagation_Legal_Implicit_Freezing,
      Freezing_Propagation_Legal_Explicit_Representation_Before_Freezing,
      Freezing_Propagation_Legal_Generic_Instance_Freezing,
      Freezing_Propagation_Legal_Private_Full_View_Freezing,
      Freezing_Propagation_Legal_Discriminant_Representation,
      Freezing_Propagation_Legal_Operational_Effect,
      Freezing_Propagation_Legal_Stream_Effect,
      Freezing_Propagation_Legal_Finalization_Effect,
      Freezing_Propagation_Target_Unresolved,
      Freezing_Propagation_Target_Ambiguous,
      Freezing_Propagation_Target_Not_Freezable,
      Freezing_Propagation_Representation_After_Implicit_Use,
      Freezing_Propagation_Representation_After_Generic_Instance,
      Freezing_Propagation_Representation_After_Generic_Body_Replay,
      Freezing_Propagation_Representation_After_Private_View,
      Freezing_Propagation_Representation_After_Full_View_Completion,
      Freezing_Propagation_Representation_At_Freezing_Point,
      Freezing_Propagation_Discriminant_Representation_Error,
      Freezing_Propagation_Variant_Representation_Error,
      Freezing_Propagation_Operational_Finalization_Error,
      Freezing_Propagation_Stream_Effect_Error,
      Freezing_Propagation_Private_Full_View_Mismatch,
      Freezing_Propagation_Implicit_Freezing_Order_Error,
      Freezing_Propagation_Linked_Precision_Error,
      Freezing_Propagation_Linked_Generic_Replay_Error,
      Freezing_Propagation_Linked_Discriminant_Error,
      Freezing_Propagation_Linked_Flow_Effect_Error,
      Freezing_Propagation_Linked_Predicate_Invariant_Error,
      Freezing_Propagation_Linked_Accessibility_Scope_Error,
      Freezing_Propagation_Linked_Elaboration_Graph_Error,
      Freezing_Propagation_Linked_Tasking_Effect_Error,
      Freezing_Propagation_Coverage_Gate_Blocker,
      Freezing_Propagation_Multiple_Blockers,
      Freezing_Propagation_Indeterminate);

   type Freezing_Propagation_Context_Info is record
      Id                    : Freezing_Propagation_Id := No_Freezing_Propagation;
      Kind                  : Freezing_Propagation_Context_Kind :=
        Freezing_Propagation_Context_Unknown;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Freezing_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Representation_Node   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Unit_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Component_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Freezing_Line         : Positive := 1;
      Representation_Line   : Positive := 1;
      Target_Resolved       : Boolean := True;
      Target_Ambiguous      : Boolean := False;
      Target_Freezable      : Boolean := True;
      Implicit_Use_Freezes  : Boolean := False;
      Representation_Item   : Boolean := False;
      Representation_After_Implicit_Use : Boolean := False;
      Representation_After_Generic_Instance : Boolean := False;
      Representation_After_Generic_Body_Replay : Boolean := False;
      Representation_After_Private_View : Boolean := False;
      Representation_After_Full_View_Completion : Boolean := False;
      Representation_At_Freezing_Point : Boolean := False;
      Discriminant_Representation : Boolean := False;
      Variant_Representation : Boolean := False;
      Operational_Finalization_Effect : Boolean := False;
      Stream_Effect          : Boolean := False;
      Private_Full_View_Mismatch : Boolean := False;
      Implicit_Freezing_Order_Error : Boolean := False;
      Precision_Status       : Precision.Representation_Freezing_Precision_Status :=
        Precision.Representation_Freezing_Precision_Not_Checked;
      Replay_Status          : Replay.Replay_Status := Replay.Replay_Not_Checked;
      Discriminant_Status    : Discriminants.Discriminant_Legality_Status :=
        Discriminants.Discriminant_Legality_Not_Checked;
      Flow_Status            : Flow.Flow_Effect_Graph_Status := Flow.Flow_Graph_Not_Checked;
      Predicate_Status       : Predicates.Propagation_Status :=
        Predicates.Propagation_Not_Checked;
      Scope_Status           : Scope.Scope_Legality_Status := Scope.Scope_Legality_Not_Checked;
      Elaboration_Status     : Elab.Elaboration_Graph_Closure_Status := Elab.Graph_Closure_Not_Checked;
      Tasking_Status         : Tasking.Tasking_Effect_Status := Tasking.Tasking_Effect_Not_Checked;
      Gate_Status            : Gates.Enforcement_Status := Gates.Enforcement_Not_Checked;
      Source_Fingerprint     : Natural := 0;
      Start_Line             : Positive := 1;
      Start_Column           : Positive := 1;
      End_Line               : Positive := 1;
      End_Column             : Positive := 1;
   end record;

   type Freezing_Propagation_Info is record
      Id                    : Freezing_Propagation_Id := No_Freezing_Propagation;
      Kind                  : Freezing_Propagation_Context_Kind :=
        Freezing_Propagation_Context_Unknown;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Freezing_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Representation_Node   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status                : Freezing_Propagation_Status := Freezing_Propagation_Not_Checked;
      Target_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Unit_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Component_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Message               : Ada.Strings.Unbounded.Unbounded_String;
      Detail                : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint    : Natural := 0;
      Fingerprint           : Natural := 0;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
   end record;

   type Freezing_Propagation_Context_Model is private;
   type Freezing_Propagation_Model is private;
   type Freezing_Propagation_Set is private;

   procedure Add_Context
     (Model : in out Freezing_Propagation_Context_Model;
      Info  : Freezing_Propagation_Context_Info);

   function Build
     (Contexts : Freezing_Propagation_Context_Model) return Freezing_Propagation_Model;

   function Context_Count (Model : Freezing_Propagation_Context_Model) return Natural;
   function Row_Count (Model : Freezing_Propagation_Model) return Natural;
   function Row_At
     (Model : Freezing_Propagation_Model;
      Index : Positive) return Freezing_Propagation_Info;

   function First_For_Node
     (Model : Freezing_Propagation_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Freezing_Propagation_Info;
   function Rows_For_Target
     (Model : Freezing_Propagation_Model;
      Name  : String) return Freezing_Propagation_Set;
   function Rows_For_Kind
     (Model : Freezing_Propagation_Model;
      Kind  : Freezing_Propagation_Context_Kind) return Freezing_Propagation_Set;
   function Result_Count (Set : Freezing_Propagation_Set) return Natural;
   function Result_At
     (Set   : Freezing_Propagation_Set;
      Index : Positive) return Freezing_Propagation_Info;

   function Count_Status
     (Model  : Freezing_Propagation_Model;
      Status : Freezing_Propagation_Status) return Natural;
   function Count_Kind
     (Model : Freezing_Propagation_Model;
      Kind  : Freezing_Propagation_Context_Kind) return Natural;

   function Legal_Count (Model : Freezing_Propagation_Model) return Natural;
   function Error_Count (Model : Freezing_Propagation_Model) return Natural;
   function Freezing_Order_Error_Count (Model : Freezing_Propagation_Model) return Natural;
   function Representation_Error_Count (Model : Freezing_Propagation_Model) return Natural;
   function Discriminant_Error_Count (Model : Freezing_Propagation_Model) return Natural;
   function Operational_Stream_Error_Count (Model : Freezing_Propagation_Model) return Natural;
   function Linked_Error_Count (Model : Freezing_Propagation_Model) return Natural;
   function Coverage_Gate_Error_Count (Model : Freezing_Propagation_Model) return Natural;
   function Indeterminate_Count (Model : Freezing_Propagation_Model) return Natural;
   function Fingerprint (Model : Freezing_Propagation_Model) return Natural;

   function Is_Legal (Status : Freezing_Propagation_Status) return Boolean;
   function Has_Error (Info : Freezing_Propagation_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Freezing_Propagation_Context_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Freezing_Propagation_Info);

   type Freezing_Propagation_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Freezing_Propagation_Set is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Freezing_Propagation_Model is record
      Items : Result_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Freezing_Order_Error_Total : Natural := 0;
      Representation_Error_Total : Natural := 0;
      Discriminant_Error_Total : Natural := 0;
      Operational_Stream_Error_Total : Natural := 0;
      Linked_Error_Total : Natural := 0;
      Coverage_Gate_Error_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Representation_Freezing_Exact_Propagation_Legality;
