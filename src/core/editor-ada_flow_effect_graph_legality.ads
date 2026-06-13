with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Dataflow_Global_Depends_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

package Editor.Ada_Flow_Effect_Graph_Legality is

   --  Pass1138 compiler-grade flow-effect graph legality layer.
   --
   --  This package deepens Global/Depends beyond row classification by making
   --  object reads, writes, call effects, generic formal/actual substitutions,
   --  protected/task effects, and body/spec refinements explicit graph edges.
   --  It consumes Pass1123 Global/Depends legality and Pass1137 coverage-gate
   --  enforcement so incomplete AST or semantic metadata cannot produce a
   --  confident flow conclusion.
   --
   --  The model is deterministic, bounded, snapshot-owned, and contains no
   --  parsing, file IO, dirty-state mutation, command/keybinding/workspace or
   --  render mutation, compiler invocation, external parser generator, Python,
   --  or shell-script dependency.

   package DGL renames Editor.Ada_Dataflow_Global_Depends_Legality;
   package Gate_Enforcement renames Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

   type Flow_Edge_Id is new Natural;
   No_Flow_Edge : constant Flow_Edge_Id := 0;

   type Flow_Graph_Context_Kind is
     (Flow_Context_Subprogram_Spec,
      Flow_Context_Subprogram_Body,
      Flow_Context_Call,
      Flow_Context_Generic_Formal_Actual,
      Flow_Context_Protected_Function,
      Flow_Context_Protected_Procedure,
      Flow_Context_Protected_Entry,
      Flow_Context_Task_Body,
      Flow_Context_Package_Elaboration,
      Flow_Context_Refined_Global,
      Flow_Context_Refined_Depends,
      Flow_Context_Unknown);

   type Flow_Edge_Kind is
     (Flow_Edge_Object_Read,
      Flow_Edge_Object_Write,
      Flow_Edge_Object_Read_Write,
      Flow_Edge_Initialization,
      Flow_Edge_Finalization,
      Flow_Edge_Depends,
      Flow_Edge_Call_Propagation,
      Flow_Edge_Generic_Substitution,
      Flow_Edge_Protected_State,
      Flow_Edge_Task_Activation,
      Flow_Edge_Refined_Global,
      Flow_Edge_Refined_Depends,
      Flow_Edge_Null,
      Flow_Edge_Unknown);

   type Flow_Effect_Graph_Status is
     (Flow_Graph_Not_Checked,
      Flow_Graph_Legal_Read_Edge,
      Flow_Graph_Legal_Write_Edge,
      Flow_Graph_Legal_Read_Write_Edge,
      Flow_Graph_Legal_Depends_Edge,
      Flow_Graph_Legal_Call_Propagation,
      Flow_Graph_Legal_Generic_Substitution,
      Flow_Graph_Legal_Protected_State_Effect,
      Flow_Graph_Legal_Task_Activation_Effect,
      Flow_Graph_Legal_Refined_Global,
      Flow_Graph_Legal_Refined_Depends,
      Flow_Graph_Legal_Null_Effect,
      Flow_Graph_Read_Not_In_Global,
      Flow_Graph_Write_Not_In_Global,
      Flow_Graph_Write_To_In_Global,
      Flow_Graph_Read_From_Out_Global,
      Flow_Graph_Null_Global_Violated,
      Flow_Graph_Body_Spec_Global_Mismatch,
      Flow_Graph_Body_Spec_Depends_Mismatch,
      Flow_Graph_Refined_Global_Missing_Item,
      Flow_Graph_Refined_Global_Extra_Item,
      Flow_Graph_Refined_Depends_Missing_Source,
      Flow_Graph_Refined_Depends_Target_Not_Output,
      Flow_Graph_Refined_Depends_Source_Not_Input,
      Flow_Graph_Call_Effect_Not_Propagated,
      Flow_Graph_Generic_Actual_Missing_Effect,
      Flow_Graph_Generic_Actual_Mode_Mismatch,
      Flow_Graph_Protected_Function_Writes_State,
      Flow_Graph_Protected_Barrier_Reads_Uncovered_State,
      Flow_Graph_Task_Activation_Effect_Missing_Global,
      Flow_Graph_Duplicate_Edge,
      Flow_Graph_Dependency_Cycle,
      Flow_Graph_Linked_Dataflow_Error,
      Flow_Graph_Coverage_Gate_Blocker,
      Flow_Graph_Indeterminate);

   type Flow_Effect_Context_Info is record
      Id                    : Flow_Edge_Id := No_Flow_Edge;
      Kind                  : Flow_Graph_Context_Kind := Flow_Context_Unknown;
      Edge                  : Flow_Edge_Kind := Flow_Edge_Unknown;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Source_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Caller_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Callee_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Formal_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Actual_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Spec_Global_Mode      : DGL.Global_Mode := DGL.Global_Mode_Not_Declared;
      Body_Global_Mode      : DGL.Global_Mode := DGL.Global_Mode_Not_Declared;
      Source_Global_Mode    : DGL.Global_Mode := DGL.Global_Mode_Not_Declared;
      Target_Global_Mode    : DGL.Global_Mode := DGL.Global_Mode_Not_Declared;
      Reads_Object          : Boolean := False;
      Writes_Object         : Boolean := False;
      Effect_Propagated     : Boolean := True;
      Refined_Global_Present : Boolean := True;
      Refined_Depends_Present : Boolean := True;
      Duplicate_Edge        : Boolean := False;
      Dependency_Cycle      : Boolean := False;
      Protected_Function    : Boolean := False;
      Protected_Barrier     : Boolean := False;
      Task_Activation       : Boolean := False;
      Base_Dataflow_Status  : DGL.Dataflow_Legality_Status := DGL.Dataflow_Legality_Not_Checked;
      Gate_Status           : Gate_Enforcement.Enforcement_Status :=
        Gate_Enforcement.Enforcement_Not_Checked;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
   end record;

   type Flow_Effect_Info is record
      Id                    : Flow_Edge_Id := No_Flow_Edge;
      Kind                  : Flow_Graph_Context_Kind := Flow_Context_Unknown;
      Edge                  : Flow_Edge_Kind := Flow_Edge_Unknown;
      Status                : Flow_Effect_Graph_Status := Flow_Graph_Not_Checked;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Source_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Caller_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Callee_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Formal_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Actual_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Message               : Ada.Strings.Unbounded.Unbounded_String;
      Detail                : Ada.Strings.Unbounded.Unbounded_String;
      Spec_Global_Mode      : DGL.Global_Mode := DGL.Global_Mode_Not_Declared;
      Body_Global_Mode      : DGL.Global_Mode := DGL.Global_Mode_Not_Declared;
      Source_Global_Mode    : DGL.Global_Mode := DGL.Global_Mode_Not_Declared;
      Target_Global_Mode    : DGL.Global_Mode := DGL.Global_Mode_Not_Declared;
      Base_Dataflow_Status  : DGL.Dataflow_Legality_Status := DGL.Dataflow_Legality_Not_Checked;
      Gate_Status           : Gate_Enforcement.Enforcement_Status :=
        Gate_Enforcement.Enforcement_Not_Checked;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
      Fingerprint           : Natural := 0;
   end record;

   type Flow_Effect_Context_Model is private;
   type Flow_Effect_Set is private;
   type Flow_Effect_Graph_Model is private;

   procedure Clear (Model : in out Flow_Effect_Context_Model);
   procedure Add_Context
     (Model : in out Flow_Effect_Context_Model;
      Info  : Flow_Effect_Context_Info);

   procedure Add_From_Dataflow_Row
     (Model : in out Flow_Effect_Context_Model;
      Row   : DGL.Dataflow_Legality_Info);

   function Context_Count (Model : Flow_Effect_Context_Model) return Natural;
   function Context_At
     (Model : Flow_Effect_Context_Model;
      Index : Positive) return Flow_Effect_Context_Info;
   function Fingerprint (Model : Flow_Effect_Context_Model) return Natural;

   function Build (Contexts : Flow_Effect_Context_Model) return Flow_Effect_Graph_Model;
   function Build_From_Dataflow
     (Dataflow : DGL.Dataflow_Legality_Model) return Flow_Effect_Graph_Model;

   function Row_Count (Model : Flow_Effect_Graph_Model) return Natural;
   function Row_At
     (Model : Flow_Effect_Graph_Model;
      Index : Positive) return Flow_Effect_Info;
   function First_For_Node
     (Model : Flow_Effect_Graph_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Flow_Effect_Info;

   function Rows_For_Status
     (Model  : Flow_Effect_Graph_Model;
      Status : Flow_Effect_Graph_Status) return Flow_Effect_Set;
   function Rows_For_Kind
     (Model : Flow_Effect_Graph_Model;
      Kind  : Flow_Graph_Context_Kind) return Flow_Effect_Set;
   function Rows_For_Edge
     (Model : Flow_Effect_Graph_Model;
      Edge  : Flow_Edge_Kind) return Flow_Effect_Set;
   function Rows_For_Object
     (Model : Flow_Effect_Graph_Model;
      Name  : String) return Flow_Effect_Set;

   function Set_Count (Set : Flow_Effect_Set) return Natural;
   function Set_At
     (Set   : Flow_Effect_Set;
      Index : Positive) return Flow_Effect_Info;

   function Count_Status
     (Model  : Flow_Effect_Graph_Model;
      Status : Flow_Effect_Graph_Status) return Natural;
   function Count_Kind
     (Model : Flow_Effect_Graph_Model;
      Kind  : Flow_Graph_Context_Kind) return Natural;
   function Count_Edge
     (Model : Flow_Effect_Graph_Model;
      Edge  : Flow_Edge_Kind) return Natural;

   function Legal_Count (Model : Flow_Effect_Graph_Model) return Natural;
   function Error_Count (Model : Flow_Effect_Graph_Model) return Natural;
   function Global_Error_Count (Model : Flow_Effect_Graph_Model) return Natural;
   function Depends_Error_Count (Model : Flow_Effect_Graph_Model) return Natural;
   function Propagation_Error_Count (Model : Flow_Effect_Graph_Model) return Natural;
   function Generic_Error_Count (Model : Flow_Effect_Graph_Model) return Natural;
   function Tasking_Protected_Error_Count (Model : Flow_Effect_Graph_Model) return Natural;
   function Linked_Error_Count (Model : Flow_Effect_Graph_Model) return Natural;
   function Coverage_Gate_Error_Count (Model : Flow_Effect_Graph_Model) return Natural;
   function Indeterminate_Count (Model : Flow_Effect_Graph_Model) return Natural;
   function Fingerprint (Model : Flow_Effect_Graph_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Flow_Effect_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Flow_Effect_Info);

   type Flow_Effect_Context_Model is record
      Items       : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Flow_Effect_Set is record
      Items : Row_Vectors.Vector;
   end record;

   type Flow_Effect_Graph_Model is record
      Items                         : Row_Vectors.Vector;
      Legal_Total                   : Natural := 0;
      Error_Total                   : Natural := 0;
      Global_Error_Total            : Natural := 0;
      Depends_Error_Total           : Natural := 0;
      Propagation_Error_Total       : Natural := 0;
      Generic_Error_Total           : Natural := 0;
      Tasking_Protected_Error_Total : Natural := 0;
      Linked_Error_Total            : Natural := 0;
      Coverage_Gate_Error_Total     : Natural := 0;
      Indeterminate_Total           : Natural := 0;
      Fingerprint                   : Natural := 0;
   end record;

end Editor.Ada_Flow_Effect_Graph_Legality;
