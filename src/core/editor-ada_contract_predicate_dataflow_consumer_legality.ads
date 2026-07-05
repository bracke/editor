with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Contract_Aspect_Legality;
with Editor.Ada_Predicate_Dataflow_Initialization_Consumer_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Contract_Predicate_Dataflow_Consumer_Legality is

   --  Case 1167 contract/aspect predicate-dataflow consumer legality.
   --
   --  This layer feeds Case 1166 predicate/invariant propagation plus
   --  dataflow/definite-initialization evidence back into contract and aspect
   --  legality.  Contract conclusions for Pre, Post, predicates, invariants,
   --  assertions, contract cases, Global/Depends, and refined flow aspects may
   --  remain confident only when the matching propagated predicate/invariant and
   --  initialized dataflow evidence is accepted.  Existing contract errors are
   --  preserved and repaired coverage / lifetime / discriminant /
   --  representation / flow blockers remain explicit semantic blockers.

   package Contract renames Editor.Ada_Contract_Aspect_Legality;
   package Pred_Flow renames Editor.Ada_Predicate_Dataflow_Initialization_Consumer_Legality;

   type Contract_Predicate_Row_Id is new Natural;
   No_Contract_Predicate_Row : constant Contract_Predicate_Row_Id := 0;

   type Contract_Predicate_Status is
     (Contract_Predicate_Not_Checked,
      Contract_Predicate_Legal_Precondition_Accepted,
      Contract_Predicate_Legal_Postcondition_Accepted,
      Contract_Predicate_Legal_Invariant_Accepted,
      Contract_Predicate_Legal_Static_Predicate_Accepted,
      Contract_Predicate_Legal_Dynamic_Predicate_Accepted,
      Contract_Predicate_Legal_Assertion_Accepted,
      Contract_Predicate_Legal_Contract_Case_Accepted,
      Contract_Predicate_Legal_Global_Aspect_Accepted,
      Contract_Predicate_Legal_Depends_Aspect_Accepted,
      Contract_Predicate_Legal_Refined_Global_Accepted,
      Contract_Predicate_Legal_Refined_Depends_Accepted,
      Contract_Predicate_Base_Contract_Error,
      Contract_Predicate_Missing_Predicate_Dataflow_Row,
      Contract_Predicate_Mismatched_Contract_Kind,
      Contract_Predicate_Base_Predicate_Propagation_Error,
      Contract_Predicate_Read_Before_Write_Blocker,
      Contract_Predicate_Component_Read_Before_Write_Blocker,
      Contract_Predicate_Partial_Component_Init_Blocker,
      Contract_Predicate_Out_Parameter_Not_Assigned_Blocker,
      Contract_Predicate_In_Out_Conditional_Assignment_Blocker,
      Contract_Predicate_Return_Object_Not_Initialized_Blocker,
      Contract_Predicate_Branch_Loop_Merge_Blocker,
      Contract_Predicate_Exception_Path_Loss_Blocker,
      Contract_Predicate_Finalization_Uses_Uninitialized_Blocker,
      Contract_Predicate_Use_After_Finalization_Blocker,
      Contract_Predicate_Lifetime_Blocker,
      Contract_Predicate_Discriminant_Representation_Blocker,
      Contract_Predicate_Coverage_Blocker,
      Contract_Predicate_Global_Blocker,
      Contract_Predicate_Depends_Blocker,
      Contract_Predicate_Call_Propagation_Blocker,
      Contract_Predicate_Generic_Effect_Blocker,
      Contract_Predicate_Tasking_Protected_Blocker,
      Contract_Predicate_Linked_Dataflow_Blocker,
      Contract_Predicate_Multiple_Blockers,
      Contract_Predicate_Indeterminate);

   type Contract_Predicate_Context_Info is record
      Id                         : Contract_Predicate_Row_Id := No_Contract_Predicate_Row;
      Kind                       : Contract.Contract_Context_Kind := Contract.Contract_Context_Unknown;
      Subject                    : Contract.Contract_Subject_Kind := Contract.Contract_Subject_Unknown;
      Placement                  : Contract.Aspect_Placement := Contract.Aspect_Placement_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Subject_Node               : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Expression_Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Contract_Row               : Contract.Contract_Legality_Id := Contract.No_Contract_Legality;
      Contract_Status            : Contract.Contract_Legality_Status := Contract.Contract_Legality_Not_Checked;
      Predicate_Dataflow_Row     : Pred_Flow.Predicate_Dataflow_Row_Id := Pred_Flow.No_Predicate_Dataflow_Row;
      Predicate_Dataflow_Status  : Pred_Flow.Predicate_Dataflow_Status := Pred_Flow.Predicate_Dataflow_Not_Checked;
      Predicate_Dataflow_Matches : Natural := 0;
      Requires_Predicate_Evidence : Boolean := False;
      Requires_Invariant_Evidence : Boolean := False;
      Requires_Flow_Evidence     : Boolean := False;
      Requires_Initialization_Evidence : Boolean := False;
      Name                       : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Source_Fingerprint         : Natural := 0;
      Contract_Fingerprint       : Natural := 0;
      Predicate_Dataflow_Fingerprint : Natural := 0;
   end record;

   type Contract_Predicate_Info is record
      Id                         : Contract_Predicate_Row_Id := No_Contract_Predicate_Row;
      Context                    : Contract_Predicate_Row_Id := No_Contract_Predicate_Row;
      Kind                       : Contract.Contract_Context_Kind := Contract.Contract_Context_Unknown;
      Subject                    : Contract.Contract_Subject_Kind := Contract.Contract_Subject_Unknown;
      Placement                  : Contract.Aspect_Placement := Contract.Aspect_Placement_Unknown;
      Status                     : Contract_Predicate_Status := Contract_Predicate_Not_Checked;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Subject_Node               : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Expression_Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
      Detail                     : Ada.Strings.Unbounded.Unbounded_String;
      Name                       : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Contract_Row               : Contract.Contract_Legality_Id := Contract.No_Contract_Legality;
      Contract_Status            : Contract.Contract_Legality_Status := Contract.Contract_Legality_Not_Checked;
      Predicate_Dataflow_Row     : Pred_Flow.Predicate_Dataflow_Row_Id := Pred_Flow.No_Predicate_Dataflow_Row;
      Predicate_Dataflow_Status  : Pred_Flow.Predicate_Dataflow_Status := Pred_Flow.Predicate_Dataflow_Not_Checked;
      Predicate_Dataflow_Matches : Natural := 0;
      Requires_Predicate_Evidence : Boolean := False;
      Requires_Invariant_Evidence : Boolean := False;
      Requires_Flow_Evidence     : Boolean := False;
      Requires_Initialization_Evidence : Boolean := False;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Source_Fingerprint         : Natural := 0;
      Contract_Fingerprint       : Natural := 0;
      Predicate_Dataflow_Fingerprint : Natural := 0;
      Fingerprint                : Natural := 0;
   end record;

   type Contract_Predicate_Context_Model is private;
   type Contract_Predicate_Set is private;
   type Contract_Predicate_Model is private;

   procedure Clear (Model : in out Contract_Predicate_Context_Model);
   procedure Add_Context
     (Model : in out Contract_Predicate_Context_Model;
      Info  : Contract_Predicate_Context_Info);

   function Context_Count (Model : Contract_Predicate_Context_Model) return Natural;
   function Context_At
     (Model : Contract_Predicate_Context_Model;
      Index : Positive) return Contract_Predicate_Context_Info;
   function Fingerprint (Model : Contract_Predicate_Context_Model) return Natural;

   function Build (Contexts : Contract_Predicate_Context_Model) return Contract_Predicate_Model;

   function Row_Count (Model : Contract_Predicate_Model) return Natural;
   function Row_At
     (Model : Contract_Predicate_Model;
      Index : Positive) return Contract_Predicate_Info;
   function First_For_Node
     (Model : Contract_Predicate_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Contract_Predicate_Info;
   function Rows_For_Status
     (Model  : Contract_Predicate_Model;
      Status : Contract_Predicate_Status) return Contract_Predicate_Set;
   function Rows_For_Kind
     (Model : Contract_Predicate_Model;
      Kind  : Contract.Contract_Context_Kind) return Contract_Predicate_Set;
   function Rows_For_Name
     (Model : Contract_Predicate_Model;
      Name  : String) return Contract_Predicate_Set;

   function Set_Count (Results : Contract_Predicate_Set) return Natural;
   function Set_At
     (Results : Contract_Predicate_Set;
      Index   : Positive) return Contract_Predicate_Info;

   function Count_Status
     (Model  : Contract_Predicate_Model;
      Status : Contract_Predicate_Status) return Natural;
   function Count_Kind
     (Model : Contract_Predicate_Model;
      Kind  : Contract.Contract_Context_Kind) return Natural;

   function Legal_Count (Model : Contract_Predicate_Model) return Natural;
   function Error_Count (Model : Contract_Predicate_Model) return Natural;
   function Predicate_Error_Count (Model : Contract_Predicate_Model) return Natural;
   function Initialization_Error_Count (Model : Contract_Predicate_Model) return Natural;
   function Dataflow_Error_Count (Model : Contract_Predicate_Model) return Natural;
   function Coverage_Error_Count (Model : Contract_Predicate_Model) return Natural;
   function Indeterminate_Count (Model : Contract_Predicate_Model) return Natural;
   function Fingerprint (Model : Contract_Predicate_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Contract_Predicate_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Contract_Predicate_Info);

   type Contract_Predicate_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Contract_Predicate_Set is record
      Items : Row_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Contract_Predicate_Model is record
      Rows : Row_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Contract_Predicate_Dataflow_Consumer_Legality;
