with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Scope_Graph_Legality;
with Editor.Ada_Elaboration_Graph_Closure_Legality;
with Editor.Ada_Exception_Finalization_Legality;
with Editor.Ada_Flow_Effect_Graph_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Protected_Precision_Legality;
with Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

package Editor.Ada_Tasking_Protected_Effects_Legality is

   --  Pass1145 compiler-grade tasking/protected effects legality.
   --
   --  This package deepens tasking/protected semantic effects beyond the
   --  precision classifier by modelling entry queue state, accept/requeue/select
   --  effects, protected-object read/write effects, task activation/finalization
   --  effects, and their interaction with flow-effect graphs, elaboration graph
   --  closure, accessibility scope graphs, exception/finalization legality, and
   --  coverage-gated semantic results.  Callers supply snapshot-owned facts; the
   --  package performs no parsing, file IO, dirty-state mutation, command,
   --  keybinding, workspace, render, compiler, parser-generator, Python, or
   --  shell-script work.

   package Precision renames Editor.Ada_Tasking_Protected_Precision_Legality;
   package Flow renames Editor.Ada_Flow_Effect_Graph_Legality;
   package Elab renames Editor.Ada_Elaboration_Graph_Closure_Legality;
   package Scope renames Editor.Ada_Accessibility_Scope_Graph_Legality;
   package Finalization renames Editor.Ada_Exception_Finalization_Legality;
   package Gates renames Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

   type Tasking_Effect_Id is new Natural;
   No_Tasking_Effect : constant Tasking_Effect_Id := 0;

   type Tasking_Effect_Context_Kind is
     (Tasking_Effect_Context_Task_Activation,
      Tasking_Effect_Context_Task_Termination,
      Tasking_Effect_Context_Protected_Read,
      Tasking_Effect_Context_Protected_Write,
      Tasking_Effect_Context_Protected_Function_Call,
      Tasking_Effect_Context_Protected_Procedure_Call,
      Tasking_Effect_Context_Protected_Entry_Call,
      Tasking_Effect_Context_Entry_Queue,
      Tasking_Effect_Context_Entry_Barrier,
      Tasking_Effect_Context_Accept_Body,
      Tasking_Effect_Context_Requeue,
      Tasking_Effect_Context_Select_Guard,
      Tasking_Effect_Context_Select_Alternative,
      Tasking_Effect_Context_Abortable_Part,
      Tasking_Effect_Context_Delay_Alternative,
      Tasking_Effect_Context_Terminate_Alternative,
      Tasking_Effect_Context_Unknown);

   type Tasking_Effect_Status is
     (Tasking_Effect_Not_Checked,
      Tasking_Effect_Legal_Task_Activation,
      Tasking_Effect_Legal_Task_Termination,
      Tasking_Effect_Legal_Protected_Read,
      Tasking_Effect_Legal_Protected_Write,
      Tasking_Effect_Legal_Protected_Function_Call,
      Tasking_Effect_Legal_Protected_Procedure_Call,
      Tasking_Effect_Legal_Protected_Entry_Call,
      Tasking_Effect_Legal_Entry_Queue,
      Tasking_Effect_Legal_Entry_Barrier,
      Tasking_Effect_Legal_Accept_Body,
      Tasking_Effect_Legal_Requeue,
      Tasking_Effect_Legal_Select_Guard,
      Tasking_Effect_Legal_Select_Alternative,
      Tasking_Effect_Legal_Delay_Alternative,
      Tasking_Effect_Legal_Terminate_Alternative,
      Tasking_Effect_Task_Activation_Missing_Elaboration,
      Tasking_Effect_Task_Termination_Finalization_Error,
      Tasking_Effect_Protected_Read_Not_In_Global,
      Tasking_Effect_Protected_Write_Not_In_Global,
      Tasking_Effect_Protected_Function_Writes_State,
      Tasking_Effect_Protected_Function_Calls_Entry,
      Tasking_Effect_Protected_Procedure_Barrier_Error,
      Tasking_Effect_Protected_Entry_Barrier_Error,
      Tasking_Effect_Entry_Queue_Target_Unresolved,
      Tasking_Effect_Entry_Queue_Accessibility_Error,
      Tasking_Effect_Entry_Queue_Finalized_Object,
      Tasking_Effect_Accept_Body_State_Effect_Mismatch,
      Tasking_Effect_Accept_Body_Not_Elaborated,
      Tasking_Effect_Requeue_Target_Unresolved,
      Tasking_Effect_Requeue_Target_Not_Open,
      Tasking_Effect_Requeue_With_Abort_Unsafe,
      Tasking_Effect_Select_Guard_Not_Boolean,
      Tasking_Effect_Select_Guard_Effect_Mismatch,
      Tasking_Effect_Select_Alternative_Unreachable,
      Tasking_Effect_Select_Terminate_With_Delay,
      Tasking_Effect_Abortable_Part_Finalization_Unsafe,
      Tasking_Effect_Delay_Alternative_Non_Static_Time,
      Tasking_Effect_Terminate_Alternative_Not_Allowed,
      Tasking_Effect_Linked_Precision_Error,
      Tasking_Effect_Linked_Flow_Error,
      Tasking_Effect_Linked_Elaboration_Error,
      Tasking_Effect_Linked_Accessibility_Error,
      Tasking_Effect_Linked_Finalization_Error,
      Tasking_Effect_Coverage_Gate_Blocker,
      Tasking_Effect_Multiple_Blockers,
      Tasking_Effect_Indeterminate);

   type Tasking_Effect_Context_Info is record
      Id                    : Tasking_Effect_Id := No_Tasking_Effect;
      Kind                  : Tasking_Effect_Context_Kind := Tasking_Effect_Context_Unknown;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Task_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Protected_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Entry_Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Queue_Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Barrier_Node          : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Select_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Entry_Name            : Ada.Strings.Unbounded.Unbounded_String;
      Queue_Name            : Ada.Strings.Unbounded.Unbounded_String;
      Reads_Protected_State : Boolean := False;
      Writes_Protected_State : Boolean := False;
      Calls_Protected_Entry : Boolean := False;
      Queue_Target_Resolved : Boolean := True;
      Queue_Target_Open     : Boolean := True;
      Queue_Object_Finalized : Boolean := False;
      Accept_State_Effect_Matches : Boolean := True;
      Requeue_Target_Resolved : Boolean := True;
      Requeue_Target_Open   : Boolean := True;
      Requeue_With_Abort    : Boolean := False;
      Requeue_Abort_Safe    : Boolean := True;
      Select_Guard_Boolean  : Boolean := True;
      Select_Guard_Effect_Matches : Boolean := True;
      Select_Alternative_Reachable : Boolean := True;
      Select_Terminate_With_Delay : Boolean := False;
      Abortable_Finalization_Safe : Boolean := True;
      Delay_Time_Static     : Boolean := True;
      Terminate_Allowed     : Boolean := True;
      Task_Body_Elaborated  : Boolean := True;
      Task_Finalization_Safe : Boolean := True;
      Precision_Status      : Precision.Tasking_Precision_Status := Precision.Tasking_Precision_Not_Checked;
      Flow_Status           : Flow.Flow_Effect_Graph_Status := Flow.Flow_Graph_Not_Checked;
      Elaboration_Status    : Elab.Elaboration_Graph_Closure_Status := Elab.Graph_Closure_Not_Checked;
      Scope_Status          : Scope.Scope_Legality_Status := Scope.Scope_Legality_Not_Checked;
      Finalization_Status   : Finalization.Exception_Legality_Status := Finalization.Exception_Legality_Not_Checked;
      Gate_Status           : Gates.Enforcement_Status := Gates.Enforcement_Not_Checked;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
   end record;

   type Tasking_Effect_Info is record
      Id                    : Tasking_Effect_Id := No_Tasking_Effect;
      Kind                  : Tasking_Effect_Context_Kind := Tasking_Effect_Context_Unknown;
      Status                : Tasking_Effect_Status := Tasking_Effect_Not_Checked;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Task_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Protected_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Entry_Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Entry_Name            : Ada.Strings.Unbounded.Unbounded_String;
      Queue_Name            : Ada.Strings.Unbounded.Unbounded_String;
      Message               : Ada.Strings.Unbounded.Unbounded_String;
      Detail                : Ada.Strings.Unbounded.Unbounded_String;
      Precision_Status      : Precision.Tasking_Precision_Status := Precision.Tasking_Precision_Not_Checked;
      Flow_Status           : Flow.Flow_Effect_Graph_Status := Flow.Flow_Graph_Not_Checked;
      Elaboration_Status    : Elab.Elaboration_Graph_Closure_Status := Elab.Graph_Closure_Not_Checked;
      Scope_Status          : Scope.Scope_Legality_Status := Scope.Scope_Legality_Not_Checked;
      Finalization_Status   : Finalization.Exception_Legality_Status := Finalization.Exception_Legality_Not_Checked;
      Gate_Status           : Gates.Enforcement_Status := Gates.Enforcement_Not_Checked;
      Blocker_Count         : Natural := 0;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
      Fingerprint           : Natural := 0;
   end record;

   type Tasking_Effect_Context_Model is private;
   type Tasking_Effect_Set is private;
   type Tasking_Effect_Model is private;

   procedure Clear (Model : in out Tasking_Effect_Context_Model);
   procedure Add_Context
     (Model   : in out Tasking_Effect_Context_Model;
      Context : Tasking_Effect_Context_Info);
   function Context_Count (Model : Tasking_Effect_Context_Model) return Natural;
   function Context_At
     (Model : Tasking_Effect_Context_Model;
      Index : Positive) return Tasking_Effect_Context_Info;
   function Fingerprint (Model : Tasking_Effect_Context_Model) return Natural;

   function Build
     (Contexts : Tasking_Effect_Context_Model) return Tasking_Effect_Model;

   function Row_Count (Model : Tasking_Effect_Model) return Natural;
   function Row_At
     (Model : Tasking_Effect_Model;
      Index : Positive) return Tasking_Effect_Info;
   function First_For_Node
     (Model : Tasking_Effect_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Tasking_Effect_Info;
   function Rows_For_Status
     (Model  : Tasking_Effect_Model;
      Status : Tasking_Effect_Status) return Tasking_Effect_Set;
   function Rows_For_Kind
     (Model : Tasking_Effect_Model;
      Kind  : Tasking_Effect_Context_Kind) return Tasking_Effect_Set;
   function Rows_For_Object
     (Model : Tasking_Effect_Model;
      Name  : String) return Tasking_Effect_Set;
   function Rows_For_Entry
     (Model : Tasking_Effect_Model;
      Name  : String) return Tasking_Effect_Set;

   function Result_Count (Results : Tasking_Effect_Set) return Natural;
   function Result_At
     (Results : Tasking_Effect_Set;
      Index   : Positive) return Tasking_Effect_Info;

   function Count_Status
     (Model  : Tasking_Effect_Model;
      Status : Tasking_Effect_Status) return Natural;
   function Count_Kind
     (Model : Tasking_Effect_Model;
      Kind  : Tasking_Effect_Context_Kind) return Natural;

   function Legal_Count (Model : Tasking_Effect_Model) return Natural;
   function Error_Count (Model : Tasking_Effect_Model) return Natural;
   function Queue_Error_Count (Model : Tasking_Effect_Model) return Natural;
   function Select_Error_Count (Model : Tasking_Effect_Model) return Natural;
   function Protected_State_Error_Count (Model : Tasking_Effect_Model) return Natural;
   function Requeue_Error_Count (Model : Tasking_Effect_Model) return Natural;
   function Finalization_Error_Count (Model : Tasking_Effect_Model) return Natural;
   function Linked_Error_Count (Model : Tasking_Effect_Model) return Natural;
   function Coverage_Gate_Error_Count (Model : Tasking_Effect_Model) return Natural;
   function Indeterminate_Count (Model : Tasking_Effect_Model) return Natural;
   function Fingerprint (Model : Tasking_Effect_Model) return Natural;

   function Has_Error (Info : Tasking_Effect_Info) return Boolean;
   function Is_Legal (Status : Tasking_Effect_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Tasking_Effect_Context_Info);
   package Effect_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Tasking_Effect_Info);

   type Tasking_Effect_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Tasking_Effect_Set is record
      Items : Effect_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Tasking_Effect_Model is record
      Items : Effect_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Queue_Error_Total : Natural := 0;
      Select_Error_Total : Natural := 0;
      Protected_State_Error_Total : Natural := 0;
      Requeue_Error_Total : Natural := 0;
      Finalization_Error_Total : Natural := 0;
      Linked_Error_Total : Natural := 0;
      Coverage_Gate_Error_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Tasking_Protected_Effects_Legality;
