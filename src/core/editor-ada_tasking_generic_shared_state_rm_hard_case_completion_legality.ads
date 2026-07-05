with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Generic_Shared_State_Final_Stabilized_Closure_Legality;
with Editor.Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality;
with Editor.Ada_Representation_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Generic_Shared_State_Final_Legality;

package Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality is

   --  Case 1248 tasking/protected RM hard-case completion legality.
   --
   --  This package consumes the stabilized generic/shared-state final closure
   --  from Case 1245, overload RM edge completion from Case 1246,
   --  representation/freezing hard-case completion from Case 1247, and the
   --  tasking/generic/shared-state final evidence from Case 1230. It closes
   --  remaining tasking/protected RM hard cases where protected actions,
   --  callbacks, entry-family queues, requeue/select paths, accept-body
   --  effects, abort/deferred-finalization, task termination, protected
   --  shared-state access, abstract-state-backed task effects, and generic
   --  task/protected bodies must agree before downstream consumers may trust
   --  the tasking conclusion.

   package Previous renames Editor.Ada_Tasking_Generic_Shared_State_Final_Legality;
   package Representation_Hard_Cases renames Editor.Ada_Representation_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
   package Overload_Edges renames Editor.Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality;
   package Closure renames Editor.Ada_Generic_Shared_State_Final_Stabilized_Closure_Legality;

   type Tasking_Generic_RM_Hard_Case_Id is new Natural;
   No_Tasking_Generic_RM_Hard_Case : constant Tasking_Generic_RM_Hard_Case_Id := 0;

   type Tasking_Generic_RM_Hard_Case_Kind is
     (Tasking_Generic_RM_Hard_Case_Protected_Action_Reentrancy,
      Tasking_Generic_RM_Hard_Case_Callback_Reentrancy,
      Tasking_Generic_RM_Hard_Case_Entry_Family_Queue,
      Tasking_Generic_RM_Hard_Case_Requeue_Select_Path,
      Tasking_Generic_RM_Hard_Case_Accept_Body_Effect,
      Tasking_Generic_RM_Hard_Case_Abort_Finalization_Ordering,
      Tasking_Generic_RM_Hard_Case_Task_Termination_Ordering,
      Tasking_Generic_RM_Hard_Case_Protected_Shared_State_Access,
      Tasking_Generic_RM_Hard_Case_Abstract_State_Backed_Task_Effect,
      Tasking_Generic_RM_Hard_Case_Generic_Task_Protected_Body_Effect,
      Tasking_Generic_RM_Hard_Case_Unknown);

   type Tasking_Generic_RM_Hard_Case_Blocker_Family is
     (Tasking_Generic_RM_Hard_Case_Blocker_None,
      Tasking_Generic_RM_Hard_Case_Blocker_Previous_Tasking,
      Tasking_Generic_RM_Hard_Case_Blocker_Representation_RM_Hard_Case,
      Tasking_Generic_RM_Hard_Case_Blocker_Overload_RM_Edge,
      Tasking_Generic_RM_Hard_Case_Blocker_Stabilized_Closure,
      Tasking_Generic_RM_Hard_Case_Blocker_Protected_Action_Reentrancy,
      Tasking_Generic_RM_Hard_Case_Blocker_Callback_Reentrancy,
      Tasking_Generic_RM_Hard_Case_Blocker_Entry_Family_Queue,
      Tasking_Generic_RM_Hard_Case_Blocker_Requeue_Select_Path,
      Tasking_Generic_RM_Hard_Case_Blocker_Accept_Body_Effect,
      Tasking_Generic_RM_Hard_Case_Blocker_Abort_Finalization_Ordering,
      Tasking_Generic_RM_Hard_Case_Blocker_Task_Termination_Ordering,
      Tasking_Generic_RM_Hard_Case_Blocker_Protected_Shared_State_Access,
      Tasking_Generic_RM_Hard_Case_Blocker_Abstract_State_Backed_Task_Effect,
      Tasking_Generic_RM_Hard_Case_Blocker_Generic_Task_Protected_Body_Effect,
      Tasking_Generic_RM_Hard_Case_Blocker_Source_Fingerprint,
      Tasking_Generic_RM_Hard_Case_Blocker_Substitution_Fingerprint,
      Tasking_Generic_RM_Hard_Case_Blocker_Multiple,
      Tasking_Generic_RM_Hard_Case_Blocker_Indeterminate);

   type Tasking_Generic_RM_Hard_Case_Status is
     (Tasking_Generic_RM_Hard_Case_Not_Checked,
      Tasking_Generic_RM_Hard_Case_Legal_Protected_Action_Reentrancy_Accepted,
      Tasking_Generic_RM_Hard_Case_Legal_Callback_Reentrancy_Accepted,
      Tasking_Generic_RM_Hard_Case_Legal_Entry_Family_Queue_Accepted,
      Tasking_Generic_RM_Hard_Case_Legal_Requeue_Select_Path_Accepted,
      Tasking_Generic_RM_Hard_Case_Legal_Accept_Body_Effect_Accepted,
      Tasking_Generic_RM_Hard_Case_Legal_Abort_Finalization_Ordering_Accepted,
      Tasking_Generic_RM_Hard_Case_Legal_Task_Termination_Ordering_Accepted,
      Tasking_Generic_RM_Hard_Case_Legal_Protected_Shared_State_Access_Accepted,
      Tasking_Generic_RM_Hard_Case_Legal_Abstract_State_Backed_Task_Effect_Accepted,
      Tasking_Generic_RM_Hard_Case_Legal_Generic_Task_Protected_Body_Effect_Accepted,
      Tasking_Generic_RM_Hard_Case_Missing_Previous_Tasking_Row,
      Tasking_Generic_RM_Hard_Case_Previous_Tasking_Blocker,
      Tasking_Generic_RM_Hard_Case_Missing_Representation_RM_Hard_Case_Row,
      Tasking_Generic_RM_Hard_Case_Representation_RM_Hard_Case_Blocker,
      Tasking_Generic_RM_Hard_Case_Missing_Overload_RM_Edge_Row,
      Tasking_Generic_RM_Hard_Case_Overload_RM_Edge_Blocker,
      Tasking_Generic_RM_Hard_Case_Missing_Stabilized_Closure_Row,
      Tasking_Generic_RM_Hard_Case_Stabilized_Closure_Blocker,
      Tasking_Generic_RM_Hard_Case_Protected_Action_Reentrancy_Blocker,
      Tasking_Generic_RM_Hard_Case_Callback_Reentrancy_Blocker,
      Tasking_Generic_RM_Hard_Case_Entry_Family_Queue_Blocker,
      Tasking_Generic_RM_Hard_Case_Requeue_Select_Path_Blocker,
      Tasking_Generic_RM_Hard_Case_Accept_Body_Effect_Blocker,
      Tasking_Generic_RM_Hard_Case_Abort_Finalization_Ordering_Blocker,
      Tasking_Generic_RM_Hard_Case_Task_Termination_Ordering_Blocker,
      Tasking_Generic_RM_Hard_Case_Protected_Shared_State_Access_Blocker,
      Tasking_Generic_RM_Hard_Case_Abstract_State_Backed_Task_Effect_Blocker,
      Tasking_Generic_RM_Hard_Case_Generic_Task_Protected_Body_Effect_Blocker,
      Tasking_Generic_RM_Hard_Case_Source_Fingerprint_Mismatch,
      Tasking_Generic_RM_Hard_Case_Substitution_Fingerprint_Mismatch,
      Tasking_Generic_RM_Hard_Case_Multiple_Blockers,
      Tasking_Generic_RM_Hard_Case_Indeterminate);

   type Tasking_Generic_RM_Hard_Case_Context is record
      Id                         : Tasking_Generic_RM_Hard_Case_Id := No_Tasking_Generic_RM_Hard_Case;
      Kind                       : Tasking_Generic_RM_Hard_Case_Kind := Tasking_Generic_RM_Hard_Case_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Operation_Name             : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Previous_Tasking_Row       : Previous.Tasking_Generic_Final_Row_Id := Previous.No_Tasking_Generic_Final_Row;
      Previous_Tasking_Status    : Previous.Tasking_Generic_Final_Status := Previous.Tasking_Generic_Final_Not_Checked;
      Representation_RM_Hard_Case_Row : Representation_Hard_Cases.Representation_Generic_RM_Hard_Case_Id := Representation_Hard_Cases.No_Representation_Generic_RM_Hard_Case;
      Representation_RM_Hard_Case_Status : Representation_Hard_Cases.Representation_Generic_RM_Hard_Case_Status := Representation_Hard_Cases.Representation_Generic_RM_Hard_Case_Not_Checked;
      Overload_RM_Edge_Row       : Overload_Edges.Overload_Generic_RM_Edge_Completion_Id := Overload_Edges.No_Overload_Generic_RM_Edge_Completion;
      Overload_RM_Edge_Status    : Overload_Edges.Overload_Generic_RM_Edge_Status := Overload_Edges.Overload_Generic_RM_Edge_Not_Checked;
      Stabilized_Closure_Row     : Closure.Generic_Shared_State_Final_Stabilized_Closure_Id := Closure.No_Generic_Shared_State_Final_Stabilized_Closure;
      Stabilized_Closure_Status  : Closure.Generic_Shared_State_Final_Stabilized_Closure_Status := Closure.Generic_Shared_State_Final_Stabilized_Closure_Not_Checked;
      Requires_Previous_Tasking  : Boolean := True;
      Requires_Representation_RM_Hard_Case : Boolean := True;
      Requires_Overload_RM_Edge  : Boolean := True;
      Requires_Stabilized_Closure : Boolean := True;
      Protected_Action_Reentrancy_Blocker : Boolean := False;
      Callback_Reentrancy_Blocker : Boolean := False;
      Entry_Family_Queue_Blocker : Boolean := False;
      Requeue_Select_Path_Blocker : Boolean := False;
      Accept_Body_Effect_Blocker : Boolean := False;
      Abort_Finalization_Ordering_Blocker : Boolean := False;
      Task_Termination_Ordering_Blocker : Boolean := False;
      Protected_Shared_State_Access_Blocker : Boolean := False;
      Abstract_State_Backed_Task_Effect_Blocker : Boolean := False;
      Generic_Task_Protected_Body_Effect_Blocker : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Tasking_Generic_RM_Hard_Case_Row is record
      Id                         : Tasking_Generic_RM_Hard_Case_Id := No_Tasking_Generic_RM_Hard_Case;
      Context                    : Tasking_Generic_RM_Hard_Case_Id := No_Tasking_Generic_RM_Hard_Case;
      Kind                       : Tasking_Generic_RM_Hard_Case_Kind := Tasking_Generic_RM_Hard_Case_Unknown;
      Status                     : Tasking_Generic_RM_Hard_Case_Status := Tasking_Generic_RM_Hard_Case_Not_Checked;
      Blocker_Family             : Tasking_Generic_RM_Hard_Case_Blocker_Family := Tasking_Generic_RM_Hard_Case_Blocker_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Operation_Name             : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Accepted                   : Boolean := False;
      Blocked                    : Boolean := False;
      Blocks_Downstream          : Boolean := False;
      Blocker_Count              : Natural := 0;
      Source_Fingerprint         : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Row_Fingerprint            : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Tasking_Generic_RM_Hard_Case_Context_Model is private;
   type Tasking_Generic_RM_Hard_Case_Model is private;
   type Tasking_Generic_RM_Hard_Case_Set is private;

   procedure Clear (Model : in out Tasking_Generic_RM_Hard_Case_Context_Model);
   procedure Add_Context (Model : in out Tasking_Generic_RM_Hard_Case_Context_Model; Context : Tasking_Generic_RM_Hard_Case_Context);
   function Context_Count (Model : Tasking_Generic_RM_Hard_Case_Context_Model) return Natural;
   function Context_At (Model : Tasking_Generic_RM_Hard_Case_Context_Model; Index : Positive) return Tasking_Generic_RM_Hard_Case_Context;
   function Context_Fingerprint (Model : Tasking_Generic_RM_Hard_Case_Context_Model) return Natural;

   function Build (Contexts : Tasking_Generic_RM_Hard_Case_Context_Model) return Tasking_Generic_RM_Hard_Case_Model;
   function Count (Model : Tasking_Generic_RM_Hard_Case_Model) return Natural;
   function Row_Count (Model : Tasking_Generic_RM_Hard_Case_Model) return Natural renames Count;
   function Row_At (Model : Tasking_Generic_RM_Hard_Case_Model; Index : Positive) return Tasking_Generic_RM_Hard_Case_Row;

   function Query_Count (Set : Tasking_Generic_RM_Hard_Case_Set) return Natural;
   function Query_At (Set : Tasking_Generic_RM_Hard_Case_Set; Index : Positive) return Tasking_Generic_RM_Hard_Case_Row;
   function Query_Status (Model : Tasking_Generic_RM_Hard_Case_Model; Status : Tasking_Generic_RM_Hard_Case_Status) return Tasking_Generic_RM_Hard_Case_Set;
   function Query_Blocker_Family (Model : Tasking_Generic_RM_Hard_Case_Model; Family : Tasking_Generic_RM_Hard_Case_Blocker_Family) return Tasking_Generic_RM_Hard_Case_Set;
   function Find_By_Node (Model : Tasking_Generic_RM_Hard_Case_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Tasking_Generic_RM_Hard_Case_Set;
   function Find_By_Source_Fingerprint (Model : Tasking_Generic_RM_Hard_Case_Model; Source_Fingerprint : Natural) return Tasking_Generic_RM_Hard_Case_Set;

   function Count_By_Status (Model : Tasking_Generic_RM_Hard_Case_Model; Status : Tasking_Generic_RM_Hard_Case_Status) return Natural;
   function Count_By_Blocker_Family (Model : Tasking_Generic_RM_Hard_Case_Model; Family : Tasking_Generic_RM_Hard_Case_Blocker_Family) return Natural;
   function Accepted_Count (Model : Tasking_Generic_RM_Hard_Case_Model) return Natural;
   function Blocked_Count (Model : Tasking_Generic_RM_Hard_Case_Model) return Natural;
   function Indeterminate_Count (Model : Tasking_Generic_RM_Hard_Case_Model) return Natural;
   function Stable_Fingerprint (Model : Tasking_Generic_RM_Hard_Case_Model) return Natural;

   function Is_Accepted (Status : Tasking_Generic_RM_Hard_Case_Status) return Boolean;
   function Is_Blocked (Status : Tasking_Generic_RM_Hard_Case_Status) return Boolean;
   function Is_Indeterminate (Status : Tasking_Generic_RM_Hard_Case_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors (Index_Type => Positive, Element_Type => Tasking_Generic_RM_Hard_Case_Context);
   package Row_Vectors is new Ada.Containers.Vectors (Index_Type => Positive, Element_Type => Tasking_Generic_RM_Hard_Case_Row);
   type Tasking_Generic_RM_Hard_Case_Context_Model is record
      Items       : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;
   type Tasking_Generic_RM_Hard_Case_Model is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;
   type Tasking_Generic_RM_Hard_Case_Set is record
      Rows : Row_Vectors.Vector;
   end record;
end Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
