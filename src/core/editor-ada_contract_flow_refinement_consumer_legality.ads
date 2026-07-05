with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Contract_Aspect_Legality;
with Editor.Ada_Flow_Refinement_Consumer_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Contract_Flow_Refinement_Consumer_Legality is

   --  Case 1156 compiler-grade contract/refined-flow consumer legality.
   --
   --  This layer connects repaired and refined flow-effect conclusions back
   --  into contract/aspect legality.  A Global, Depends, Refined_Global, or
   --  Refined_Depends contract aspect is not allowed to remain a confident
   --  legal flow aspect when the corresponding flow-refinement consumer row
   --  reports missing refinement, invalid modes, missing Depends edges,
   --  unpropagated call effects, coverage-feedback blockers, or unresolved
   --  refinement state.
   --
   --  The model is deterministic, bounded, snapshot-owned, and contains no
   --  rendering-side parsing, file IO, dirty-state mutation, command palette,
   --  keybinding, workspace, or render mutation.

   package Contracts renames Editor.Ada_Contract_Aspect_Legality;
   package Flow_Consumers renames Editor.Ada_Flow_Refinement_Consumer_Legality;

   type Contract_Flow_Row_Id is new Natural;
   No_Contract_Flow_Row : constant Contract_Flow_Row_Id := 0;

   type Contract_Flow_Context_Kind is
     (Contract_Flow_Global,
      Contract_Flow_Depends,
      Contract_Flow_Refined_Global,
      Contract_Flow_Refined_Depends,
      Contract_Flow_Call_Propagation,
      Contract_Flow_Generic_Instance,
      Contract_Flow_Task_Protected,
      Contract_Flow_Unknown);

   type Contract_Flow_Status is
     (Contract_Flow_Not_Checked,
      Contract_Flow_Legal_Global_Aspect_Accepted,
      Contract_Flow_Legal_Depends_Aspect_Accepted,
      Contract_Flow_Legal_Refined_Global_Accepted,
      Contract_Flow_Legal_Refined_Depends_Accepted,
      Contract_Flow_Legal_Call_Propagation_Accepted,
      Contract_Flow_Legal_Generic_Effect_Accepted,
      Contract_Flow_Legal_Task_Protected_Effect_Accepted,
      Contract_Flow_Base_Contract_Error,
      Contract_Flow_Missing_Consumer_Row,
      Contract_Flow_Refined_Global_Missing_Read,
      Contract_Flow_Refined_Global_Missing_Write,
      Contract_Flow_Refined_Global_Mode_Mismatch,
      Contract_Flow_Refined_Global_Extra_Item,
      Contract_Flow_Refined_Depends_Missing_Edge,
      Contract_Flow_Refined_Depends_Extra_Edge,
      Contract_Flow_Refined_Depends_Source_Mode_Error,
      Contract_Flow_Refined_Depends_Target_Mode_Error,
      Contract_Flow_Call_Effect_Not_Propagated,
      Contract_Flow_Coverage_Feedback_Blocker,
      Contract_Flow_Linked_Flow_Graph_Error,
      Contract_Flow_Multiple_Consumer_Blockers,
      Contract_Flow_Consumer_Indeterminate,
      Contract_Flow_Indeterminate);

   type Contract_Flow_Context_Info is record
      Id                : Contract_Flow_Row_Id := No_Contract_Flow_Row;
      Kind              : Contract_Flow_Context_Kind := Contract_Flow_Unknown;
      Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Subject_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Expression_Node   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Source_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Caller_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Callee_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Contract_Row      : Contracts.Contract_Legality_Id := Contracts.No_Contract_Legality;
      Contract_Status   : Contracts.Contract_Legality_Status := Contracts.Contract_Legality_Not_Checked;
      Contract_Flow_State : Contracts.Flow_Contract_State := Contracts.Flow_Contract_Not_Applicable;
      Consumer_Row      : Flow_Consumers.Consumer_Row_Id := Flow_Consumers.No_Consumer_Row;
      Consumer_Status   : Flow_Consumers.Consumer_Status := Flow_Consumers.Consumer_Not_Checked;
      Consumer_Matches  : Natural := 0;
      Start_Line        : Positive := 1;
      Start_Column      : Positive := 1;
      End_Line          : Positive := 1;
      End_Column        : Positive := 1;
      Source_Fingerprint : Natural := 0;
   end record;

   type Contract_Flow_Info is record
      Id                : Contract_Flow_Row_Id := No_Contract_Flow_Row;
      Context           : Contract_Flow_Row_Id := No_Contract_Flow_Row;
      Kind              : Contract_Flow_Context_Kind := Contract_Flow_Unknown;
      Status            : Contract_Flow_Status := Contract_Flow_Not_Checked;
      Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Subject_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Expression_Node   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Source_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Caller_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Callee_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Message           : Ada.Strings.Unbounded.Unbounded_String;
      Detail            : Ada.Strings.Unbounded.Unbounded_String;
      Contract_Row      : Contracts.Contract_Legality_Id := Contracts.No_Contract_Legality;
      Contract_Status   : Contracts.Contract_Legality_Status := Contracts.Contract_Legality_Not_Checked;
      Contract_Flow_State : Contracts.Flow_Contract_State := Contracts.Flow_Contract_Not_Applicable;
      Consumer_Row      : Flow_Consumers.Consumer_Row_Id := Flow_Consumers.No_Consumer_Row;
      Consumer_Status   : Flow_Consumers.Consumer_Status := Flow_Consumers.Consumer_Not_Checked;
      Consumer_Matches  : Natural := 0;
      Start_Line        : Positive := 1;
      Start_Column      : Positive := 1;
      End_Line          : Positive := 1;
      End_Column        : Positive := 1;
      Source_Fingerprint : Natural := 0;
      Fingerprint       : Natural := 0;
   end record;

   type Contract_Flow_Context_Model is private;
   type Contract_Flow_Set is private;
   type Contract_Flow_Model is private;

   procedure Clear (Model : in out Contract_Flow_Context_Model);
   procedure Add_Context (Model : in out Contract_Flow_Context_Model; Info : Contract_Flow_Context_Info);

   procedure Add_From_Contract_Row
     (Model     : in out Contract_Flow_Context_Model;
      Row       : Contracts.Contract_Legality_Info;
      Consumers : Flow_Consumers.Consumer_Model);

   function Context_Count (Model : Contract_Flow_Context_Model) return Natural;
   function Context_At (Model : Contract_Flow_Context_Model; Index : Positive) return Contract_Flow_Context_Info;
   function Fingerprint (Model : Contract_Flow_Context_Model) return Natural;

   function Build (Contexts : Contract_Flow_Context_Model) return Contract_Flow_Model;
   function Build_From_Contracts_And_Flow_Consumers
     (Contract_Model : Contracts.Contract_Legality_Model;
      Consumers      : Flow_Consumers.Consumer_Model) return Contract_Flow_Model;

   function Row_Count (Model : Contract_Flow_Model) return Natural;
   function Row_At (Model : Contract_Flow_Model; Index : Positive) return Contract_Flow_Info;
   function First_For_Node (Model : Contract_Flow_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Contract_Flow_Info;
   function Rows_For_Status (Model : Contract_Flow_Model; Status : Contract_Flow_Status) return Contract_Flow_Set;
   function Rows_For_Kind (Model : Contract_Flow_Model; Kind : Contract_Flow_Context_Kind) return Contract_Flow_Set;
   function Rows_For_Object (Model : Contract_Flow_Model; Name : String) return Contract_Flow_Set;

   function Set_Count (Set : Contract_Flow_Set) return Natural;
   function Set_At (Set : Contract_Flow_Set; Index : Positive) return Contract_Flow_Info;

   function Count_Status (Model : Contract_Flow_Model; Status : Contract_Flow_Status) return Natural;
   function Count_Kind (Model : Contract_Flow_Model; Kind : Contract_Flow_Context_Kind) return Natural;
   function Legal_Count (Model : Contract_Flow_Model) return Natural;
   function Error_Count (Model : Contract_Flow_Model) return Natural;
   function Global_Error_Count (Model : Contract_Flow_Model) return Natural;
   function Depends_Error_Count (Model : Contract_Flow_Model) return Natural;
   function Propagation_Error_Count (Model : Contract_Flow_Model) return Natural;
   function Coverage_Error_Count (Model : Contract_Flow_Model) return Natural;
   function Indeterminate_Count (Model : Contract_Flow_Model) return Natural;
   function Fingerprint (Model : Contract_Flow_Model) return Natural;

   function Is_Legal (Status : Contract_Flow_Status) return Boolean;
   function Is_Global_Error (Status : Contract_Flow_Status) return Boolean;
   function Is_Depends_Error (Status : Contract_Flow_Status) return Boolean;
   function Is_Propagation_Error (Status : Contract_Flow_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Contract_Flow_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Contract_Flow_Info);

   type Contract_Flow_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Contract_Flow_Set is record
      Items : Row_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Contract_Flow_Model is record
      Items : Row_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Global_Error_Total : Natural := 0;
      Depends_Error_Total : Natural := 0;
      Propagation_Error_Total : Natural := 0;
      Coverage_Error_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Contract_Flow_Refinement_Consumer_Legality;
