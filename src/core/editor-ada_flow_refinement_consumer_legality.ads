with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Dataflow_Global_Depends_Legality;
with Editor.Ada_Flow_Effect_Graph_Legality;
with Editor.Ada_Refined_Global_Depends_Conformance_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Flow_Refinement_Consumer_Legality is

   --  Pass1155 compiler-grade flow/refinement consumer legality.
   --
   --  This package connects Refined_Global / Refined_Depends conformance back
   --  into flow-effect graph consumers.  A flow edge is not allowed to become a
   --  confident body/call/generic/task effect merely because the local flow
   --  graph edge was well formed; the matching refined body/spec conformance
   --  row must also permit the consumer.  This prevents missing Refined_Global
   --  items, missing Refined_Depends edges, invalid modes, unpropagated call
   --  effects, repaired-coverage blockers, and indeterminate refinements from
   --  being treated as legal flow facts by downstream semantic layers.
   --
   --  The model is deterministic, bounded, snapshot-owned, and contains no
   --  rendering-side parsing, file IO, dirty-state mutation, command palette,
   --  keybinding, workspace, or render mutation.

   package DGL renames Editor.Ada_Dataflow_Global_Depends_Legality;
   package Flow renames Editor.Ada_Flow_Effect_Graph_Legality;
   package Refined renames Editor.Ada_Refined_Global_Depends_Conformance_Legality;

   type Consumer_Row_Id is new Natural;
   No_Consumer_Row : constant Consumer_Row_Id := 0;

   type Consumer_Kind is
     (Consumer_Assignment,
      Consumer_Return,
      Consumer_Call,
      Consumer_Generic_Instance,
      Consumer_Task_Protected,
      Consumer_Elaboration,
      Consumer_Representation,
      Consumer_Integrated_Closure,
      Consumer_Unknown);

   type Consumer_Effect_Kind is
     (Consumer_Effect_Read,
      Consumer_Effect_Write,
      Consumer_Effect_Read_Write,
      Consumer_Effect_Depends,
      Consumer_Effect_Call_Propagation,
      Consumer_Effect_Generic_Substitution,
      Consumer_Effect_Protected_State,
      Consumer_Effect_Task_Activation,
      Consumer_Effect_Null,
      Consumer_Effect_Unknown);

   type Consumer_Status is
     (Consumer_Not_Checked,
      Consumer_Legal_Flow_Edge_Accepted,
      Consumer_Legal_Depends_Edge_Accepted,
      Consumer_Legal_Call_Propagation_Accepted,
      Consumer_Legal_Generic_Effect_Accepted,
      Consumer_Legal_Task_Protected_Effect_Accepted,
      Consumer_Legal_Null_Effect_Accepted,
      Consumer_Flow_Graph_Error,
      Consumer_Missing_Refinement_Row,
      Consumer_Refined_Global_Missing_Read,
      Consumer_Refined_Global_Missing_Write,
      Consumer_Refined_Global_Mode_Mismatch,
      Consumer_Refined_Global_Extra_Item,
      Consumer_Refined_Depends_Missing_Edge,
      Consumer_Refined_Depends_Extra_Edge,
      Consumer_Refined_Depends_Source_Mode_Error,
      Consumer_Refined_Depends_Target_Mode_Error,
      Consumer_Call_Effect_Not_Propagated,
      Consumer_Coverage_Feedback_Blocker,
      Consumer_Refinement_Linked_Flow_Error,
      Consumer_Refinement_Indeterminate,
      Consumer_Multiple_Refinement_Blockers,
      Consumer_Indeterminate);

   type Consumer_Context_Info is record
      Id                 : Consumer_Row_Id := No_Consumer_Row;
      Consumer           : Consumer_Kind := Consumer_Unknown;
      Effect             : Consumer_Effect_Kind := Consumer_Effect_Unknown;
      Node               : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Source_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Caller_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Callee_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Flow_Row           : Flow.Flow_Edge_Id := Flow.No_Flow_Edge;
      Flow_Status        : Flow.Flow_Effect_Graph_Status := Flow.Flow_Graph_Not_Checked;
      Refined_Row        : Refined.Refined_Conformance_Id := Refined.No_Refined_Conformance;
      Refined_Status     : Refined.Refined_Conformance_Status := Refined.Refined_Conformance_Not_Checked;
      Refined_Match_Count : Natural := 0;
      Spec_Global_Mode   : DGL.Global_Mode := DGL.Global_Mode_Not_Declared;
      Body_Global_Mode   : DGL.Global_Mode := DGL.Global_Mode_Not_Declared;
      Refined_Global_Mode : DGL.Global_Mode := DGL.Global_Mode_Not_Declared;
      Source_Global_Mode : DGL.Global_Mode := DGL.Global_Mode_Not_Declared;
      Target_Global_Mode : DGL.Global_Mode := DGL.Global_Mode_Not_Declared;
      Start_Line         : Positive := 1;
      Start_Column       : Positive := 1;
      End_Line           : Positive := 1;
      End_Column         : Positive := 1;
      Source_Fingerprint : Natural := 0;
   end record;

   type Consumer_Info is record
      Id                 : Consumer_Row_Id := No_Consumer_Row;
      Context            : Consumer_Row_Id := No_Consumer_Row;
      Consumer           : Consumer_Kind := Consumer_Unknown;
      Effect             : Consumer_Effect_Kind := Consumer_Effect_Unknown;
      Status             : Consumer_Status := Consumer_Not_Checked;
      Node               : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Source_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Caller_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Callee_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Message            : Ada.Strings.Unbounded.Unbounded_String;
      Detail             : Ada.Strings.Unbounded.Unbounded_String;
      Flow_Row           : Flow.Flow_Edge_Id := Flow.No_Flow_Edge;
      Flow_Status        : Flow.Flow_Effect_Graph_Status := Flow.Flow_Graph_Not_Checked;
      Refined_Row        : Refined.Refined_Conformance_Id := Refined.No_Refined_Conformance;
      Refined_Status     : Refined.Refined_Conformance_Status := Refined.Refined_Conformance_Not_Checked;
      Refined_Match_Count : Natural := 0;
      Spec_Global_Mode   : DGL.Global_Mode := DGL.Global_Mode_Not_Declared;
      Body_Global_Mode   : DGL.Global_Mode := DGL.Global_Mode_Not_Declared;
      Refined_Global_Mode : DGL.Global_Mode := DGL.Global_Mode_Not_Declared;
      Source_Global_Mode : DGL.Global_Mode := DGL.Global_Mode_Not_Declared;
      Target_Global_Mode : DGL.Global_Mode := DGL.Global_Mode_Not_Declared;
      Start_Line         : Positive := 1;
      Start_Column       : Positive := 1;
      End_Line           : Positive := 1;
      End_Column         : Positive := 1;
      Source_Fingerprint : Natural := 0;
      Fingerprint        : Natural := 0;
   end record;

   type Consumer_Context_Model is private;
   type Consumer_Set is private;
   type Consumer_Model is private;

   procedure Clear (Model : in out Consumer_Context_Model);
   procedure Add_Context (Model : in out Consumer_Context_Model; Info : Consumer_Context_Info);

   procedure Add_From_Flow_Row
     (Model   : in out Consumer_Context_Model;
      Row     : Flow.Flow_Effect_Info;
      Refined : Editor.Ada_Refined_Global_Depends_Conformance_Legality.Refined_Conformance_Model);

   function Context_Count (Model : Consumer_Context_Model) return Natural;
   function Context_At (Model : Consumer_Context_Model; Index : Positive) return Consumer_Context_Info;
   function Fingerprint (Model : Consumer_Context_Model) return Natural;

   function Build (Contexts : Consumer_Context_Model) return Consumer_Model;
   function Build_From_Flow_And_Refinement
     (Graph   : Flow.Flow_Effect_Graph_Model;
      Refined : Editor.Ada_Refined_Global_Depends_Conformance_Legality.Refined_Conformance_Model)
      return Consumer_Model;

   function Row_Count (Model : Consumer_Model) return Natural;
   function Row_At (Model : Consumer_Model; Index : Positive) return Consumer_Info;
   function First_For_Node (Model : Consumer_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Consumer_Info;
   function Rows_For_Status (Model : Consumer_Model; Status : Consumer_Status) return Consumer_Set;
   function Rows_For_Consumer (Model : Consumer_Model; Consumer : Consumer_Kind) return Consumer_Set;
   function Rows_For_Object (Model : Consumer_Model; Name : String) return Consumer_Set;

   function Set_Count (Set : Consumer_Set) return Natural;
   function Set_At (Set : Consumer_Set; Index : Positive) return Consumer_Info;

   function Count_Status (Model : Consumer_Model; Status : Consumer_Status) return Natural;
   function Count_Consumer (Model : Consumer_Model; Consumer : Consumer_Kind) return Natural;
   function Legal_Count (Model : Consumer_Model) return Natural;
   function Error_Count (Model : Consumer_Model) return Natural;
   function Global_Error_Count (Model : Consumer_Model) return Natural;
   function Depends_Error_Count (Model : Consumer_Model) return Natural;
   function Propagation_Error_Count (Model : Consumer_Model) return Natural;
   function Coverage_Error_Count (Model : Consumer_Model) return Natural;
   function Indeterminate_Count (Model : Consumer_Model) return Natural;
   function Fingerprint (Model : Consumer_Model) return Natural;

   function Is_Legal (Status : Consumer_Status) return Boolean;
   function Is_Global_Error (Status : Consumer_Status) return Boolean;
   function Is_Depends_Error (Status : Consumer_Status) return Boolean;
   function Is_Propagation_Error (Status : Consumer_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Consumer_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Consumer_Info);

   type Consumer_Context_Model is record
      Items       : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Consumer_Set is record
      Items : Row_Vectors.Vector;
   end record;

   type Consumer_Model is record
      Items                   : Row_Vectors.Vector;
      Legal_Total             : Natural := 0;
      Error_Total             : Natural := 0;
      Global_Error_Total      : Natural := 0;
      Depends_Error_Total     : Natural := 0;
      Propagation_Error_Total : Natural := 0;
      Coverage_Error_Total    : Natural := 0;
      Indeterminate_Total     : Natural := 0;
      Fingerprint             : Natural := 0;
   end record;

end Editor.Ada_Flow_Refinement_Consumer_Legality;
