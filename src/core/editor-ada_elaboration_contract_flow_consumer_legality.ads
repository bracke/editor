with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Contract_Flow_Refinement_Consumer_Legality;
with Editor.Ada_Elaboration_Graph_Closure_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Elaboration_Contract_Flow_Consumer_Legality is

   --  Pass1157 compiler-grade elaboration/contract-flow consumer legality.
   --
   --  This layer connects refined Global/Depends contract-flow conclusions
   --  into elaboration graph closure.  Elaboration-time calls, aspect
   --  expressions, default expressions, representation items, generic
   --  instances, task activation edges, and policy-sensitive elaboration
   --  edges are not allowed to remain confidently legal when the matching
   --  Global/Depends or Refined_Global/Refined_Depends contract-flow result
   --  reports missing reads/writes, invalid modes, missing Depends edges,
   --  unpropagated call effects, repaired coverage blockers, or an
   --  indeterminate refined-flow state.

   package Contract_Flow renames Editor.Ada_Contract_Flow_Refinement_Consumer_Legality;
   package Elab_Graph renames Editor.Ada_Elaboration_Graph_Closure_Legality;

   type Elaboration_Contract_Flow_Row_Id is new Natural;
   No_Elaboration_Contract_Flow_Row : constant Elaboration_Contract_Flow_Row_Id := 0;

   type Elaboration_Contract_Flow_Context_Kind is
     (Elaboration_Contract_Flow_Direct_Call,
      Elaboration_Contract_Flow_Indirect_Call,
      Elaboration_Contract_Flow_Dispatching_Call,
      Elaboration_Contract_Flow_Default_Expression,
      Elaboration_Contract_Flow_Aspect_Expression,
      Elaboration_Contract_Flow_Representation_Item,
      Elaboration_Contract_Flow_Generic_Instance,
      Elaboration_Contract_Flow_Task_Activation,
      Elaboration_Contract_Flow_Preelaboration_Policy,
      Elaboration_Contract_Flow_Pure_Policy,
      Elaboration_Contract_Flow_Remote_Types_Policy,
      Elaboration_Contract_Flow_Shared_Passive_Policy,
      Elaboration_Contract_Flow_Unknown);

   type Elaboration_Contract_Flow_Status is
     (Elaboration_Contract_Flow_Not_Checked,
      Elaboration_Contract_Flow_Legal_Call_Accepted,
      Elaboration_Contract_Flow_Legal_Default_Expression_Accepted,
      Elaboration_Contract_Flow_Legal_Aspect_Expression_Accepted,
      Elaboration_Contract_Flow_Legal_Representation_Item_Accepted,
      Elaboration_Contract_Flow_Legal_Generic_Instance_Accepted,
      Elaboration_Contract_Flow_Legal_Task_Activation_Accepted,
      Elaboration_Contract_Flow_Legal_Preelaboration_Policy_Accepted,
      Elaboration_Contract_Flow_Legal_Pure_Policy_Accepted,
      Elaboration_Contract_Flow_Legal_Remote_Types_Policy_Accepted,
      Elaboration_Contract_Flow_Legal_Shared_Passive_Policy_Accepted,
      Elaboration_Contract_Flow_Base_Elaboration_Error,
      Elaboration_Contract_Flow_Missing_Contract_Flow_Row,
      Elaboration_Contract_Flow_Refined_Global_Missing_Read,
      Elaboration_Contract_Flow_Refined_Global_Missing_Write,
      Elaboration_Contract_Flow_Refined_Global_Mode_Mismatch,
      Elaboration_Contract_Flow_Refined_Global_Extra_Item,
      Elaboration_Contract_Flow_Refined_Depends_Missing_Edge,
      Elaboration_Contract_Flow_Refined_Depends_Extra_Edge,
      Elaboration_Contract_Flow_Refined_Depends_Source_Mode_Error,
      Elaboration_Contract_Flow_Refined_Depends_Target_Mode_Error,
      Elaboration_Contract_Flow_Call_Effect_Not_Propagated,
      Elaboration_Contract_Flow_Coverage_Feedback_Blocker,
      Elaboration_Contract_Flow_Linked_Flow_Graph_Error,
      Elaboration_Contract_Flow_Contract_Base_Error,
      Elaboration_Contract_Flow_Multiple_Contract_Flow_Blockers,
      Elaboration_Contract_Flow_Contract_Flow_Indeterminate,
      Elaboration_Contract_Flow_Indeterminate);

   type Elaboration_Contract_Flow_Context_Info is record
      Id                  : Elaboration_Contract_Flow_Row_Id := No_Elaboration_Contract_Flow_Row;
      Kind                : Elaboration_Contract_Flow_Context_Kind := Elaboration_Contract_Flow_Unknown;
      Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Unit_Node    : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Unit_Node    : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Call_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Body_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Instance_Node       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Unit_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Target_Unit_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name         : Ada.Strings.Unbounded.Unbounded_String;
      Source_Name         : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name         : Ada.Strings.Unbounded.Unbounded_String;
      Caller_Name         : Ada.Strings.Unbounded.Unbounded_String;
      Callee_Name         : Ada.Strings.Unbounded.Unbounded_String;
      Graph_Row           : Elab_Graph.Elaboration_Graph_Edge_Id := Elab_Graph.No_Elaboration_Graph_Edge;
      Graph_Status        : Elab_Graph.Elaboration_Graph_Closure_Status := Elab_Graph.Graph_Closure_Not_Checked;
      Contract_Flow_Row   : Contract_Flow.Contract_Flow_Row_Id := Contract_Flow.No_Contract_Flow_Row;
      Contract_Flow_Status : Contract_Flow.Contract_Flow_Status := Contract_Flow.Contract_Flow_Not_Checked;
      Contract_Flow_Matches : Natural := 0;
      Start_Line          : Positive := 1;
      Start_Column        : Positive := 1;
      End_Line            : Positive := 1;
      End_Column          : Positive := 1;
      Source_Fingerprint  : Natural := 0;
   end record;

   type Elaboration_Contract_Flow_Info is record
      Id                  : Elaboration_Contract_Flow_Row_Id := No_Elaboration_Contract_Flow_Row;
      Context             : Elaboration_Contract_Flow_Row_Id := No_Elaboration_Contract_Flow_Row;
      Kind                : Elaboration_Contract_Flow_Context_Kind := Elaboration_Contract_Flow_Unknown;
      Status              : Elaboration_Contract_Flow_Status := Elaboration_Contract_Flow_Not_Checked;
      Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Unit_Node    : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Unit_Node    : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Call_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Body_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Instance_Node       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Unit_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Target_Unit_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name         : Ada.Strings.Unbounded.Unbounded_String;
      Source_Name         : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name         : Ada.Strings.Unbounded.Unbounded_String;
      Caller_Name         : Ada.Strings.Unbounded.Unbounded_String;
      Callee_Name         : Ada.Strings.Unbounded.Unbounded_String;
      Message             : Ada.Strings.Unbounded.Unbounded_String;
      Detail              : Ada.Strings.Unbounded.Unbounded_String;
      Graph_Row           : Elab_Graph.Elaboration_Graph_Edge_Id := Elab_Graph.No_Elaboration_Graph_Edge;
      Graph_Status        : Elab_Graph.Elaboration_Graph_Closure_Status := Elab_Graph.Graph_Closure_Not_Checked;
      Contract_Flow_Row   : Contract_Flow.Contract_Flow_Row_Id := Contract_Flow.No_Contract_Flow_Row;
      Contract_Flow_Status : Contract_Flow.Contract_Flow_Status := Contract_Flow.Contract_Flow_Not_Checked;
      Contract_Flow_Matches : Natural := 0;
      Start_Line          : Positive := 1;
      Start_Column        : Positive := 1;
      End_Line            : Positive := 1;
      End_Column          : Positive := 1;
      Source_Fingerprint  : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

   type Elaboration_Contract_Flow_Context_Model is private;
   type Elaboration_Contract_Flow_Set is private;
   type Elaboration_Contract_Flow_Model is private;

   procedure Clear (Model : in out Elaboration_Contract_Flow_Context_Model);
   procedure Add_Context
     (Model : in out Elaboration_Contract_Flow_Context_Model;
      Info  : Elaboration_Contract_Flow_Context_Info);

   procedure Add_From_Graph_Row
     (Model          : in out Elaboration_Contract_Flow_Context_Model;
      Row            : Elab_Graph.Elaboration_Graph_Closure_Info;
      Contract_Flows : Contract_Flow.Contract_Flow_Model);

   function Context_Count (Model : Elaboration_Contract_Flow_Context_Model) return Natural;
   function Context_At
     (Model : Elaboration_Contract_Flow_Context_Model;
      Index : Positive) return Elaboration_Contract_Flow_Context_Info;
   function Fingerprint (Model : Elaboration_Contract_Flow_Context_Model) return Natural;

   function Build
     (Contexts : Elaboration_Contract_Flow_Context_Model) return Elaboration_Contract_Flow_Model;

   function Build_From_Elaboration_And_Contract_Flow
     (Graph_Model    : Elab_Graph.Elaboration_Graph_Closure_Model;
      Contract_Flows : Contract_Flow.Contract_Flow_Model) return Elaboration_Contract_Flow_Model;

   function Row_Count (Model : Elaboration_Contract_Flow_Model) return Natural;
   function Row_At
     (Model : Elaboration_Contract_Flow_Model;
      Index : Positive) return Elaboration_Contract_Flow_Info;
   function First_For_Node
     (Model : Elaboration_Contract_Flow_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Elaboration_Contract_Flow_Info;
   function Rows_For_Status
     (Model  : Elaboration_Contract_Flow_Model;
      Status : Elaboration_Contract_Flow_Status) return Elaboration_Contract_Flow_Set;
   function Rows_For_Kind
     (Model : Elaboration_Contract_Flow_Model;
      Kind  : Elaboration_Contract_Flow_Context_Kind) return Elaboration_Contract_Flow_Set;
   function Rows_For_Unit
     (Model : Elaboration_Contract_Flow_Model;
      Name  : String) return Elaboration_Contract_Flow_Set;

   function Set_Count (Set : Elaboration_Contract_Flow_Set) return Natural;
   function Set_At
     (Set   : Elaboration_Contract_Flow_Set;
      Index : Positive) return Elaboration_Contract_Flow_Info;

   function Count_Status
     (Model  : Elaboration_Contract_Flow_Model;
      Status : Elaboration_Contract_Flow_Status) return Natural;
   function Count_Kind
     (Model : Elaboration_Contract_Flow_Model;
      Kind  : Elaboration_Contract_Flow_Context_Kind) return Natural;

   function Legal_Count (Model : Elaboration_Contract_Flow_Model) return Natural;
   function Error_Count (Model : Elaboration_Contract_Flow_Model) return Natural;
   function Global_Error_Count (Model : Elaboration_Contract_Flow_Model) return Natural;
   function Depends_Error_Count (Model : Elaboration_Contract_Flow_Model) return Natural;
   function Propagation_Error_Count (Model : Elaboration_Contract_Flow_Model) return Natural;
   function Coverage_Error_Count (Model : Elaboration_Contract_Flow_Model) return Natural;
   function Policy_Error_Count (Model : Elaboration_Contract_Flow_Model) return Natural;
   function Indeterminate_Count (Model : Elaboration_Contract_Flow_Model) return Natural;
   function Fingerprint (Model : Elaboration_Contract_Flow_Model) return Natural;

   function Is_Legal (Status : Elaboration_Contract_Flow_Status) return Boolean;
   function Is_Global_Error (Status : Elaboration_Contract_Flow_Status) return Boolean;
   function Is_Depends_Error (Status : Elaboration_Contract_Flow_Status) return Boolean;
   function Is_Propagation_Error (Status : Elaboration_Contract_Flow_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Elaboration_Contract_Flow_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Elaboration_Contract_Flow_Info);

   type Elaboration_Contract_Flow_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Elaboration_Contract_Flow_Set is record
      Items : Row_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Elaboration_Contract_Flow_Model is record
      Items : Row_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Global_Error_Total : Natural := 0;
      Depends_Error_Total : Natural := 0;
      Propagation_Error_Total : Natural := 0;
      Coverage_Error_Total : Natural := 0;
      Policy_Error_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Elaboration_Contract_Flow_Consumer_Legality;
