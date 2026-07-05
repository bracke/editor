with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Expression_Construct_AST_Repair_Legality;
with Editor.Ada_Generic_Replay_Representation_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Overload_RM_Edge_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Overload_Type_Edge_Precision_Legality is

   --  Case 1179 compiler-grade overload/type edge precision legality.
   --
   --  This package deepens the Case 1126/1141 overload edge work with direct
   --  type-resolution evidence for the remaining Ada RM corner cases.  It is a
   --  snapshot-owned semantic consumer: access-to-subprogram overloads,
   --  universal fixed/root numeric preference, inherited primitive hiding,
   --  dispatching/nondispatching selection, generic formal subprograms, and
   --  nested named/defaulted actual ties cannot remain confidently legal when
   --  expression AST repair or generic replay representation contract/predicate
   --  dataflow evidence is missing, blocked, or indeterminate.

   package RM_Edge renames Editor.Ada_Overload_RM_Edge_Legality;
   package Expr_AST renames Editor.Ada_Expression_Construct_AST_Repair_Legality;
   package Replay_CPD renames Editor.Ada_Generic_Replay_Representation_Contract_Predicate_Dataflow_Consumer_Legality;

   type Overload_Type_Edge_Row_Id is new Natural;
   No_Overload_Type_Edge_Row : constant Overload_Type_Edge_Row_Id := 0;

   type Overload_Type_Edge_Context_Kind is
     (Overload_Type_Edge_Access_To_Subprogram,
      Overload_Type_Edge_Universal_Fixed,
      Overload_Type_Edge_Root_Numeric,
      Overload_Type_Edge_Inherited_Primitive,
      Overload_Type_Edge_Dispatching_Operation,
      Overload_Type_Edge_Generic_Formal_Subprogram,
      Overload_Type_Edge_Nested_Generic_Call,
      Overload_Type_Edge_Class_Wide_Controlling,
      Overload_Type_Edge_Unknown);

   type Overload_Type_Edge_Status is
     (Overload_Type_Edge_Not_Checked,
      Overload_Type_Edge_Legal_Access_Subprogram_Profile_Accepted,
      Overload_Type_Edge_Legal_Universal_Fixed_Preferred,
      Overload_Type_Edge_Legal_Root_Numeric_Preferred,
      Overload_Type_Edge_Legal_Inherited_Primitive_Selected,
      Overload_Type_Edge_Legal_Dispatching_Selected,
      Overload_Type_Edge_Legal_Nondispatching_Selected,
      Overload_Type_Edge_Legal_Generic_Formal_Subprogram_Accepted,
      Overload_Type_Edge_Legal_Nested_Generic_Selected,
      Overload_Type_Edge_Legal_Class_Wide_Controlling_Accepted,
      Overload_Type_Edge_Base_RM_Edge_Error,
      Overload_Type_Edge_RM_Edge_Ambiguous,
      Overload_Type_Edge_Access_Profile_Mismatch,
      Overload_Type_Edge_Access_Mode_Mismatch,
      Overload_Type_Edge_Access_Result_Mismatch,
      Overload_Type_Edge_Universal_Fixed_Ambiguous,
      Overload_Type_Edge_Root_Numeric_Ambiguous,
      Overload_Type_Edge_Inherited_Primitive_Hiding_Ambiguous,
      Overload_Type_Edge_Dispatching_Nondispatching_Ambiguous,
      Overload_Type_Edge_Generic_Formal_Subprogram_Ambiguous,
      Overload_Type_Edge_Nested_Defaulted_Formal_Ambiguous,
      Overload_Type_Edge_Nested_Named_Actual_Ambiguous,
      Overload_Type_Edge_Class_Wide_Controlling_Ambiguous,
      Overload_Type_Edge_Missing_Expression_AST_Repair,
      Overload_Type_Edge_Expression_AST_Repair_Blocker,
      Overload_Type_Edge_Missing_Generic_Replay_CPD_Row,
      Overload_Type_Edge_Generic_Replay_CPD_Blocker,
      Overload_Type_Edge_Generic_Replay_CPD_Indeterminate,
      Overload_Type_Edge_Multiple_Blockers,
      Overload_Type_Edge_Indeterminate);

   type Overload_Type_Edge_Context_Info is record
      Id                         : Overload_Type_Edge_Row_Id := No_Overload_Type_Edge_Row;
      Kind                       : Overload_Type_Edge_Context_Kind := Overload_Type_Edge_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Designator                 : Ada.Strings.Unbounded.Unbounded_String;
      Target_Type_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Expected_Type_Name         : Ada.Strings.Unbounded.Unbounded_String;
      RM_Edge_Row                : RM_Edge.RM_Edge_Legality_Id := RM_Edge.No_RM_Edge_Legality;
      RM_Edge_Status             : RM_Edge.RM_Edge_Legality_Status := RM_Edge.RM_Edge_Legality_Not_Checked;
      Expression_AST_Row         : Expr_AST.Expression_Construct_AST_Repair_Row_Id := Expr_AST.No_Expression_Construct_AST_Repair_Row;
      Expression_AST_Status      : Expr_AST.Expression_Construct_AST_Repair_Status := Expr_AST.Expression_Construct_AST_Not_Checked;
      Generic_Replay_CPD_Row     : Replay_CPD.Generic_Replay_Representation_Row_Id := Replay_CPD.No_Generic_Replay_Representation_Row;
      Generic_Replay_CPD_Status  : Replay_CPD.Generic_Replay_Representation_Status := Replay_CPD.Generic_Replay_Representation_Not_Checked;
      Candidate_Count            : Natural := 0;
      Selected_Candidate_Count   : Natural := 0;
      Ambiguous_Candidate_Count  : Natural := 0;
      Access_Profile_Mismatch_Count : Natural := 0;
      Access_Mode_Mismatch_Count : Natural := 0;
      Access_Result_Mismatch_Count : Natural := 0;
      Universal_Fixed_Count      : Natural := 0;
      Root_Numeric_Count         : Natural := 0;
      Inherited_Primitive_Count  : Natural := 0;
      Dispatching_Candidate_Count : Natural := 0;
      Nondispatching_Candidate_Count : Natural := 0;
      Generic_Formal_Subprogram_Count : Natural := 0;
      Defaulted_Formal_Tie_Count : Natural := 0;
      Named_Actual_Tie_Count     : Natural := 0;
      Class_Wide_Controlling_Count : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Source_Fingerprint         : Natural := 0;
   end record;

   type Overload_Type_Edge_Info is record
      Id                         : Overload_Type_Edge_Row_Id := No_Overload_Type_Edge_Row;
      Context                    : Overload_Type_Edge_Row_Id := No_Overload_Type_Edge_Row;
      Kind                       : Overload_Type_Edge_Context_Kind := Overload_Type_Edge_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status                     : Overload_Type_Edge_Status := Overload_Type_Edge_Not_Checked;
      Designator                 : Ada.Strings.Unbounded.Unbounded_String;
      Target_Type_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Expected_Type_Name         : Ada.Strings.Unbounded.Unbounded_String;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
      Detail                     : Ada.Strings.Unbounded.Unbounded_String;
      RM_Edge_Row                : RM_Edge.RM_Edge_Legality_Id := RM_Edge.No_RM_Edge_Legality;
      RM_Edge_Status             : RM_Edge.RM_Edge_Legality_Status := RM_Edge.RM_Edge_Legality_Not_Checked;
      Expression_AST_Row         : Expr_AST.Expression_Construct_AST_Repair_Row_Id := Expr_AST.No_Expression_Construct_AST_Repair_Row;
      Expression_AST_Status      : Expr_AST.Expression_Construct_AST_Repair_Status := Expr_AST.Expression_Construct_AST_Not_Checked;
      Generic_Replay_CPD_Row     : Replay_CPD.Generic_Replay_Representation_Row_Id := Replay_CPD.No_Generic_Replay_Representation_Row;
      Generic_Replay_CPD_Status  : Replay_CPD.Generic_Replay_Representation_Status := Replay_CPD.Generic_Replay_Representation_Not_Checked;
      Selected_Candidate_Count   : Natural := 0;
      Ambiguous_Candidate_Count  : Natural := 0;
      Blocker_Count              : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Source_Fingerprint         : Natural := 0;
      Fingerprint                : Natural := 0;
   end record;

   type Overload_Type_Edge_Context_Model is private;
   type Overload_Type_Edge_Result_Set is private;
   type Overload_Type_Edge_Model is private;

   procedure Clear (Model : in out Overload_Type_Edge_Context_Model);
   procedure Add_Context
     (Model : in out Overload_Type_Edge_Context_Model;
      Info  : Overload_Type_Edge_Context_Info);

   function Context_Count (Model : Overload_Type_Edge_Context_Model) return Natural;
   function Context_At
     (Model : Overload_Type_Edge_Context_Model;
      Index : Positive) return Overload_Type_Edge_Context_Info;
   function Fingerprint (Model : Overload_Type_Edge_Context_Model) return Natural;

   function Build (Contexts : Overload_Type_Edge_Context_Model) return Overload_Type_Edge_Model;

   function Row_Count (Model : Overload_Type_Edge_Model) return Natural;
   function Row_At
     (Model : Overload_Type_Edge_Model;
      Index : Positive) return Overload_Type_Edge_Info;
   function First_For_Node
     (Model : Overload_Type_Edge_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Overload_Type_Edge_Info;
   function Rows_For_Status
     (Model  : Overload_Type_Edge_Model;
      Status : Overload_Type_Edge_Status) return Overload_Type_Edge_Result_Set;
   function Rows_For_Kind
     (Model : Overload_Type_Edge_Model;
      Kind  : Overload_Type_Edge_Context_Kind) return Overload_Type_Edge_Result_Set;
   function Rows_For_Designator
     (Model      : Overload_Type_Edge_Model;
      Designator : String) return Overload_Type_Edge_Result_Set;

   function Result_Count (Results : Overload_Type_Edge_Result_Set) return Natural;
   function Result_At
     (Results : Overload_Type_Edge_Result_Set;
      Index   : Positive) return Overload_Type_Edge_Info;

   function Count_Status
     (Model  : Overload_Type_Edge_Model;
      Status : Overload_Type_Edge_Status) return Natural;
   function Count_Kind
     (Model : Overload_Type_Edge_Model;
      Kind  : Overload_Type_Edge_Context_Kind) return Natural;

   function Legal_Count (Model : Overload_Type_Edge_Model) return Natural;
   function Error_Count (Model : Overload_Type_Edge_Model) return Natural;
   function Ambiguous_Count (Model : Overload_Type_Edge_Model) return Natural;
   function AST_Blocker_Count (Model : Overload_Type_Edge_Model) return Natural;
   function Generic_Replay_Blocker_Count (Model : Overload_Type_Edge_Model) return Natural;
   function Multiple_Blocker_Count (Model : Overload_Type_Edge_Model) return Natural;
   function Indeterminate_Count (Model : Overload_Type_Edge_Model) return Natural;
   function Fingerprint (Model : Overload_Type_Edge_Model) return Natural;

   function Is_Legal (Status : Overload_Type_Edge_Status) return Boolean;
   function Is_Ambiguous (Status : Overload_Type_Edge_Status) return Boolean;
   function Has_Error (Info : Overload_Type_Edge_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Overload_Type_Edge_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Overload_Type_Edge_Info);

   type Overload_Type_Edge_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Overload_Type_Edge_Result_Set is record
      Items : Row_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Overload_Type_Edge_Model is record
      Items : Row_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Ambiguous_Total : Natural := 0;
      AST_Blocker_Total : Natural := 0;
      Generic_Replay_Blocker_Total : Natural := 0;
      Multiple_Blocker_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Overload_Type_Edge_Precision_Legality;
