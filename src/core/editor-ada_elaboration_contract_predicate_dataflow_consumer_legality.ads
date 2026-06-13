with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Elaboration_Graph_Closure_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Elaboration_Contract_Predicate_Dataflow_Consumer_Legality is

   --  Pass1168 compiler-grade elaboration consumer legality.
   --
   --  This layer feeds Pass1167 contract predicate/dataflow results into
   --  elaboration graph closure.  Elaboration-time calls, default
   --  expressions, aspect expressions, representation items, generic
   --  instances, task activation, and policy-sensitive library-unit contexts
   --  may remain confident only when their contract predicate/dataflow evidence
   --  also proves predicate/invariant propagation, initialized object state,
   --  refined Global/Depends flow, lifetime, discriminant, representation, and
   --  repaired coverage conditions.

   package Contract_Pred renames Editor.Ada_Contract_Predicate_Dataflow_Consumer_Legality;
   package Elab_Graph renames Editor.Ada_Elaboration_Graph_Closure_Legality;

   type Elaboration_Contract_Predicate_Row_Id is new Natural;
   No_Elaboration_Contract_Predicate_Row : constant Elaboration_Contract_Predicate_Row_Id := 0;

   type Elaboration_Contract_Predicate_Context_Kind is
     (Elaboration_Contract_Predicate_Direct_Call,
      Elaboration_Contract_Predicate_Indirect_Call,
      Elaboration_Contract_Predicate_Dispatching_Call,
      Elaboration_Contract_Predicate_Default_Expression,
      Elaboration_Contract_Predicate_Aspect_Expression,
      Elaboration_Contract_Predicate_Representation_Item,
      Elaboration_Contract_Predicate_Generic_Instance,
      Elaboration_Contract_Predicate_Task_Activation,
      Elaboration_Contract_Predicate_Preelaboration_Policy,
      Elaboration_Contract_Predicate_Pure_Policy,
      Elaboration_Contract_Predicate_Remote_Types_Policy,
      Elaboration_Contract_Predicate_Shared_Passive_Policy,
      Elaboration_Contract_Predicate_Unknown);

   type Elaboration_Contract_Predicate_Status is
     (Elaboration_Contract_Predicate_Not_Checked,
      Elaboration_Contract_Predicate_Legal_Call_Accepted,
      Elaboration_Contract_Predicate_Legal_Default_Expression_Accepted,
      Elaboration_Contract_Predicate_Legal_Aspect_Expression_Accepted,
      Elaboration_Contract_Predicate_Legal_Representation_Item_Accepted,
      Elaboration_Contract_Predicate_Legal_Generic_Instance_Accepted,
      Elaboration_Contract_Predicate_Legal_Task_Activation_Accepted,
      Elaboration_Contract_Predicate_Legal_Preelaboration_Policy_Accepted,
      Elaboration_Contract_Predicate_Legal_Pure_Policy_Accepted,
      Elaboration_Contract_Predicate_Legal_Remote_Types_Policy_Accepted,
      Elaboration_Contract_Predicate_Legal_Shared_Passive_Policy_Accepted,
      Elaboration_Contract_Predicate_Base_Elaboration_Error,
      Elaboration_Contract_Predicate_Missing_Contract_Predicate_Row,
      Elaboration_Contract_Predicate_Multiple_Contract_Predicate_Blockers,
      Elaboration_Contract_Predicate_Base_Contract_Error,
      Elaboration_Contract_Predicate_Base_Predicate_Propagation_Error,
      Elaboration_Contract_Predicate_Read_Before_Write_Blocker,
      Elaboration_Contract_Predicate_Component_Read_Before_Write_Blocker,
      Elaboration_Contract_Predicate_Partial_Component_Init_Blocker,
      Elaboration_Contract_Predicate_Out_Parameter_Not_Assigned_Blocker,
      Elaboration_Contract_Predicate_In_Out_Conditional_Assignment_Blocker,
      Elaboration_Contract_Predicate_Return_Object_Not_Initialized_Blocker,
      Elaboration_Contract_Predicate_Branch_Loop_Merge_Blocker,
      Elaboration_Contract_Predicate_Exception_Path_Loss_Blocker,
      Elaboration_Contract_Predicate_Finalization_Uses_Uninitialized_Blocker,
      Elaboration_Contract_Predicate_Use_After_Finalization_Blocker,
      Elaboration_Contract_Predicate_Lifetime_Blocker,
      Elaboration_Contract_Predicate_Discriminant_Representation_Blocker,
      Elaboration_Contract_Predicate_Coverage_Blocker,
      Elaboration_Contract_Predicate_Global_Blocker,
      Elaboration_Contract_Predicate_Depends_Blocker,
      Elaboration_Contract_Predicate_Call_Propagation_Blocker,
      Elaboration_Contract_Predicate_Generic_Effect_Blocker,
      Elaboration_Contract_Predicate_Tasking_Protected_Blocker,
      Elaboration_Contract_Predicate_Linked_Dataflow_Blocker,
      Elaboration_Contract_Predicate_Contract_Predicate_Indeterminate,
      Elaboration_Contract_Predicate_Indeterminate);

   type Elaboration_Contract_Predicate_Context_Info is record
      Id                    : Elaboration_Contract_Predicate_Row_Id := No_Elaboration_Contract_Predicate_Row;
      Kind                  : Elaboration_Contract_Predicate_Context_Kind := Elaboration_Contract_Predicate_Unknown;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Unit_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Unit_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Call_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Body_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Instance_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Unit_Name      : Ada.Strings.Unbounded.Unbounded_String;
      Target_Unit_Name      : Ada.Strings.Unbounded.Unbounded_String;
      Contract_Name         : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Caller_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Callee_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Graph_Row             : Elab_Graph.Elaboration_Graph_Edge_Id := Elab_Graph.No_Elaboration_Graph_Edge;
      Graph_Status          : Elab_Graph.Elaboration_Graph_Closure_Status := Elab_Graph.Graph_Closure_Not_Checked;
      Contract_Predicate_Row : Contract_Pred.Contract_Predicate_Row_Id := Contract_Pred.No_Contract_Predicate_Row;
      Contract_Predicate_Status : Contract_Pred.Contract_Predicate_Status := Contract_Pred.Contract_Predicate_Not_Checked;
      Contract_Predicate_Matches : Natural := 0;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
   end record;

   type Elaboration_Contract_Predicate_Info is record
      Id                    : Elaboration_Contract_Predicate_Row_Id := No_Elaboration_Contract_Predicate_Row;
      Context               : Elaboration_Contract_Predicate_Row_Id := No_Elaboration_Contract_Predicate_Row;
      Kind                  : Elaboration_Contract_Predicate_Context_Kind := Elaboration_Contract_Predicate_Unknown;
      Status                : Elaboration_Contract_Predicate_Status := Elaboration_Contract_Predicate_Not_Checked;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Unit_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Unit_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Call_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Body_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Instance_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Unit_Name      : Ada.Strings.Unbounded.Unbounded_String;
      Target_Unit_Name      : Ada.Strings.Unbounded.Unbounded_String;
      Contract_Name         : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Caller_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Callee_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Message               : Ada.Strings.Unbounded.Unbounded_String;
      Detail                : Ada.Strings.Unbounded.Unbounded_String;
      Graph_Row             : Elab_Graph.Elaboration_Graph_Edge_Id := Elab_Graph.No_Elaboration_Graph_Edge;
      Graph_Status          : Elab_Graph.Elaboration_Graph_Closure_Status := Elab_Graph.Graph_Closure_Not_Checked;
      Contract_Predicate_Row : Contract_Pred.Contract_Predicate_Row_Id := Contract_Pred.No_Contract_Predicate_Row;
      Contract_Predicate_Status : Contract_Pred.Contract_Predicate_Status := Contract_Pred.Contract_Predicate_Not_Checked;
      Contract_Predicate_Matches : Natural := 0;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
      Fingerprint           : Natural := 0;
   end record;

   type Elaboration_Contract_Predicate_Context_Model is private;
   type Elaboration_Contract_Predicate_Set is private;
   type Elaboration_Contract_Predicate_Model is private;

   procedure Clear (Model : in out Elaboration_Contract_Predicate_Context_Model);
   procedure Add_Context
     (Model : in out Elaboration_Contract_Predicate_Context_Model;
      Info  : Elaboration_Contract_Predicate_Context_Info);

   procedure Add_From_Graph_Row
     (Model               : in out Elaboration_Contract_Predicate_Context_Model;
      Row                 : Elab_Graph.Elaboration_Graph_Closure_Info;
      Contract_Predicates : Contract_Pred.Contract_Predicate_Model);

   function Context_Count (Model : Elaboration_Contract_Predicate_Context_Model) return Natural;
   function Context_At
     (Model : Elaboration_Contract_Predicate_Context_Model;
      Index : Positive) return Elaboration_Contract_Predicate_Context_Info;
   function Fingerprint (Model : Elaboration_Contract_Predicate_Context_Model) return Natural;

   function Build
     (Contexts : Elaboration_Contract_Predicate_Context_Model) return Elaboration_Contract_Predicate_Model;

   function Build_From_Elaboration_And_Contract_Predicate
     (Graph_Model         : Elab_Graph.Elaboration_Graph_Closure_Model;
      Contract_Predicates : Contract_Pred.Contract_Predicate_Model) return Elaboration_Contract_Predicate_Model;

   function Row_Count (Model : Elaboration_Contract_Predicate_Model) return Natural;
   function Row_At
     (Model : Elaboration_Contract_Predicate_Model;
      Index : Positive) return Elaboration_Contract_Predicate_Info;
   function First_For_Node
     (Model : Elaboration_Contract_Predicate_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Elaboration_Contract_Predicate_Info;
   function Rows_For_Status
     (Model  : Elaboration_Contract_Predicate_Model;
      Status : Elaboration_Contract_Predicate_Status) return Elaboration_Contract_Predicate_Set;
   function Rows_For_Kind
     (Model : Elaboration_Contract_Predicate_Model;
      Kind  : Elaboration_Contract_Predicate_Context_Kind) return Elaboration_Contract_Predicate_Set;
   function Rows_For_Unit
     (Model : Elaboration_Contract_Predicate_Model;
      Name  : String) return Elaboration_Contract_Predicate_Set;

   function Set_Count (Set : Elaboration_Contract_Predicate_Set) return Natural;
   function Set_At
     (Set   : Elaboration_Contract_Predicate_Set;
      Index : Positive) return Elaboration_Contract_Predicate_Info;

   function Count_Status
     (Model  : Elaboration_Contract_Predicate_Model;
      Status : Elaboration_Contract_Predicate_Status) return Natural;
   function Count_Kind
     (Model : Elaboration_Contract_Predicate_Model;
      Kind  : Elaboration_Contract_Predicate_Context_Kind) return Natural;

   function Legal_Count (Model : Elaboration_Contract_Predicate_Model) return Natural;
   function Error_Count (Model : Elaboration_Contract_Predicate_Model) return Natural;
   function Initialization_Error_Count (Model : Elaboration_Contract_Predicate_Model) return Natural;
   function Predicate_Error_Count (Model : Elaboration_Contract_Predicate_Model) return Natural;
   function Dataflow_Error_Count (Model : Elaboration_Contract_Predicate_Model) return Natural;
   function Coverage_Error_Count (Model : Elaboration_Contract_Predicate_Model) return Natural;
   function Policy_Error_Count (Model : Elaboration_Contract_Predicate_Model) return Natural;
   function Indeterminate_Count (Model : Elaboration_Contract_Predicate_Model) return Natural;
   function Fingerprint (Model : Elaboration_Contract_Predicate_Model) return Natural;

   function Is_Legal (Status : Elaboration_Contract_Predicate_Status) return Boolean;
   function Is_Initialization_Error (Status : Elaboration_Contract_Predicate_Status) return Boolean;
   function Is_Predicate_Error (Status : Elaboration_Contract_Predicate_Status) return Boolean;
   function Is_Dataflow_Error (Status : Elaboration_Contract_Predicate_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Elaboration_Contract_Predicate_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Elaboration_Contract_Predicate_Info);

   type Elaboration_Contract_Predicate_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Elaboration_Contract_Predicate_Set is record
      Items : Row_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Elaboration_Contract_Predicate_Model is record
      Items : Row_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Initialization_Error_Total : Natural := 0;
      Predicate_Error_Total : Natural := 0;
      Dataflow_Error_Total : Natural := 0;
      Coverage_Error_Total : Natural := 0;
      Policy_Error_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Elaboration_Contract_Predicate_Dataflow_Consumer_Legality;
