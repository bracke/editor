with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Dataflow_Definite_Initialization_Consumer_Legality;
with Editor.Ada_Predicate_Invariant_Propagation_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Predicate_Dataflow_Initialization_Consumer_Legality is

   --  Case 1166 predicate/invariant dataflow-initialization consumer legality.
   --
   --  This layer feeds Case 1165 Global/Depends plus definite-initialization
   --  evidence back into predicate and invariant propagation.  It prevents a
   --  predicate or invariant obligation from remaining confidently preserved
   --  when the object state, read/write flow, refined-flow evidence, or exact
   --  lifetime/discriminant/representation evidence used to prove that
   --  obligation is missing, blocked, or indeterminate.

   package Prop renames Editor.Ada_Predicate_Invariant_Propagation_Legality;
   package Flow_Init renames Editor.Ada_Dataflow_Definite_Initialization_Consumer_Legality;

   type Predicate_Dataflow_Row_Id is new Natural;
   No_Predicate_Dataflow_Row : constant Predicate_Dataflow_Row_Id := 0;

   type Predicate_Dataflow_Status is
     (Predicate_Dataflow_Not_Checked,
      Predicate_Dataflow_Legal_Static_Predicate_Accepted,
      Predicate_Dataflow_Legal_Dynamic_Predicate_Accepted,
      Predicate_Dataflow_Legal_Invariant_Accepted,
      Predicate_Dataflow_Legal_Dynamic_Invariant_Accepted,
      Predicate_Dataflow_Legal_Generic_Substitution_Accepted,
      Predicate_Dataflow_Legal_Derived_Invariant_Accepted,
      Predicate_Dataflow_Legal_Private_Full_View_Accepted,
      Predicate_Dataflow_Legal_Flow_Effect_Accepted,
      Predicate_Dataflow_Base_Predicate_Propagation_Error,
      Predicate_Dataflow_Missing_Dataflow_Init_Row,
      Predicate_Dataflow_Mismatched_Object,
      Predicate_Dataflow_Read_Before_Write_Blocker,
      Predicate_Dataflow_Component_Read_Before_Write_Blocker,
      Predicate_Dataflow_Partial_Component_Init_Blocker,
      Predicate_Dataflow_Out_Parameter_Not_Assigned_Blocker,
      Predicate_Dataflow_In_Out_Conditional_Assignment_Blocker,
      Predicate_Dataflow_Return_Object_Not_Initialized_Blocker,
      Predicate_Dataflow_Branch_Loop_Merge_Blocker,
      Predicate_Dataflow_Exception_Path_Loss_Blocker,
      Predicate_Dataflow_Finalization_Uses_Uninitialized_Blocker,
      Predicate_Dataflow_Use_After_Finalization_Blocker,
      Predicate_Dataflow_Lifetime_Blocker,
      Predicate_Dataflow_Discriminant_Representation_Blocker,
      Predicate_Dataflow_Coverage_Blocker,
      Predicate_Dataflow_Global_Blocker,
      Predicate_Dataflow_Depends_Blocker,
      Predicate_Dataflow_Call_Propagation_Blocker,
      Predicate_Dataflow_Generic_Effect_Blocker,
      Predicate_Dataflow_Tasking_Protected_Blocker,
      Predicate_Dataflow_Linked_Dataflow_Blocker,
      Predicate_Dataflow_Multiple_Blockers,
      Predicate_Dataflow_Indeterminate);

   type Predicate_Dataflow_Context_Info is record
      Id                       : Predicate_Dataflow_Row_Id := No_Predicate_Dataflow_Row;
      Kind                     : Prop.Propagation_Context_Kind := Prop.Propagation_Context_Unknown;
      Obligation               : Prop.Propagation_Obligation_Kind := Prop.Obligation_Unknown;
      Node                     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Subtype_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Caller_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Callee_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Propagation_Row          : Prop.Propagation_Row_Id := Prop.No_Propagation_Row;
      Propagation_Status       : Prop.Propagation_Status := Prop.Propagation_Not_Checked;
      Dataflow_Init_Row        : Flow_Init.Dataflow_Init_Row_Id := Flow_Init.No_Dataflow_Init_Row;
      Dataflow_Init_Status     : Flow_Init.Dataflow_Init_Status := Flow_Init.Dataflow_Init_Not_Checked;
      Dataflow_Init_Matches    : Natural := 0;
      Requires_Dataflow_State  : Boolean := False;
      State_Was_Updated        : Boolean := False;
      Dynamic_Check            : Boolean := False;
      Generic_Obligation       : Boolean := False;
      Derived_Obligation       : Boolean := False;
      Private_View_Obligation  : Boolean := False;
      Flow_Effect_Obligation   : Boolean := False;
      Start_Line               : Positive := 1;
      Start_Column             : Positive := 1;
      End_Line                 : Positive := 1;
      End_Column               : Positive := 1;
      Source_Fingerprint       : Natural := 0;
      Propagation_Fingerprint  : Natural := 0;
      Dataflow_Init_Fingerprint : Natural := 0;
   end record;

   type Predicate_Dataflow_Info is record
      Id                       : Predicate_Dataflow_Row_Id := No_Predicate_Dataflow_Row;
      Context                  : Predicate_Dataflow_Row_Id := No_Predicate_Dataflow_Row;
      Kind                     : Prop.Propagation_Context_Kind := Prop.Propagation_Context_Unknown;
      Obligation               : Prop.Propagation_Obligation_Kind := Prop.Obligation_Unknown;
      Status                   : Predicate_Dataflow_Status := Predicate_Dataflow_Not_Checked;
      Node                     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Subtype_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Caller_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Callee_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Message                  : Ada.Strings.Unbounded.Unbounded_String;
      Detail                   : Ada.Strings.Unbounded.Unbounded_String;
      Propagation_Row          : Prop.Propagation_Row_Id := Prop.No_Propagation_Row;
      Propagation_Status       : Prop.Propagation_Status := Prop.Propagation_Not_Checked;
      Dataflow_Init_Row        : Flow_Init.Dataflow_Init_Row_Id := Flow_Init.No_Dataflow_Init_Row;
      Dataflow_Init_Status     : Flow_Init.Dataflow_Init_Status := Flow_Init.Dataflow_Init_Not_Checked;
      Dataflow_Init_Matches    : Natural := 0;
      Requires_Dataflow_State  : Boolean := False;
      State_Was_Updated        : Boolean := False;
      Dynamic_Check            : Boolean := False;
      Start_Line               : Positive := 1;
      Start_Column             : Positive := 1;
      End_Line                 : Positive := 1;
      End_Column               : Positive := 1;
      Source_Fingerprint       : Natural := 0;
      Propagation_Fingerprint  : Natural := 0;
      Dataflow_Init_Fingerprint : Natural := 0;
      Fingerprint              : Natural := 0;
   end record;

   type Predicate_Dataflow_Context_Model is private;
   type Predicate_Dataflow_Set is private;
   type Predicate_Dataflow_Model is private;

   procedure Clear (Model : in out Predicate_Dataflow_Context_Model);
   procedure Add_Context
     (Model : in out Predicate_Dataflow_Context_Model;
      Info  : Predicate_Dataflow_Context_Info);

   function Context_Count (Model : Predicate_Dataflow_Context_Model) return Natural;
   function Context_At
     (Model : Predicate_Dataflow_Context_Model;
      Index : Positive) return Predicate_Dataflow_Context_Info;
   function Fingerprint (Model : Predicate_Dataflow_Context_Model) return Natural;

   function Build (Contexts : Predicate_Dataflow_Context_Model) return Predicate_Dataflow_Model;

   function Row_Count (Model : Predicate_Dataflow_Model) return Natural;
   function Row_At
     (Model : Predicate_Dataflow_Model;
      Index : Positive) return Predicate_Dataflow_Info;
   function First_For_Node
     (Model : Predicate_Dataflow_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Predicate_Dataflow_Info;
   function Rows_For_Status
     (Model  : Predicate_Dataflow_Model;
      Status : Predicate_Dataflow_Status) return Predicate_Dataflow_Set;
   function Rows_For_Kind
     (Model : Predicate_Dataflow_Model;
      Kind  : Prop.Propagation_Context_Kind) return Predicate_Dataflow_Set;
   function Rows_For_Object
     (Model : Predicate_Dataflow_Model;
      Name  : String) return Predicate_Dataflow_Set;

   function Set_Count (Results : Predicate_Dataflow_Set) return Natural;
   function Set_At
     (Results : Predicate_Dataflow_Set;
      Index   : Positive) return Predicate_Dataflow_Info;

   function Count_Status
     (Model  : Predicate_Dataflow_Model;
      Status : Predicate_Dataflow_Status) return Natural;
   function Count_Kind
     (Model : Predicate_Dataflow_Model;
      Kind  : Prop.Propagation_Context_Kind) return Natural;

   function Legal_Count (Model : Predicate_Dataflow_Model) return Natural;
   function Error_Count (Model : Predicate_Dataflow_Model) return Natural;
   function Predicate_Error_Count (Model : Predicate_Dataflow_Model) return Natural;
   function Invariant_Error_Count (Model : Predicate_Dataflow_Model) return Natural;
   function Dataflow_Error_Count (Model : Predicate_Dataflow_Model) return Natural;
   function Initialization_Error_Count (Model : Predicate_Dataflow_Model) return Natural;
   function Coverage_Error_Count (Model : Predicate_Dataflow_Model) return Natural;
   function Indeterminate_Count (Model : Predicate_Dataflow_Model) return Natural;
   function Fingerprint (Model : Predicate_Dataflow_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Predicate_Dataflow_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Predicate_Dataflow_Info);

   type Predicate_Dataflow_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Predicate_Dataflow_Set is record
      Items : Row_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Predicate_Dataflow_Model is record
      Rows : Row_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Predicate_Dataflow_Initialization_Consumer_Legality;
