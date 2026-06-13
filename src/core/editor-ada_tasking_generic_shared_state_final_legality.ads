with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Abstract_State_Refined_State_Consumer_Integration_Legality;
with Editor.Ada_Generic_Abstract_State_Replay_Legality;
with Editor.Ada_Overload_Generic_Shared_State_Final_Legality;
with Editor.Ada_Representation_Generic_Shared_State_Final_Legality;
with Editor.Ada_Shared_State_Stabilized_Closure_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Protected_Deep_Edge_Legality;
with Editor.Ada_Tasking_Shared_State_Final_Legality;

package Editor.Ada_Tasking_Generic_Shared_State_Final_Legality is

   --  Pass1230 tasking/generic/shared-state final legality.
   --
   --  This package consumes deep tasking/protected evidence, tasking
   --  shared-state final evidence, generic abstract-state replay,
   --  overload/generic shared-state evidence, representation/generic
   --  shared-state evidence, abstract-state consumer evidence, and stabilized
   --  shared-state closure.  It prevents protected actions, entry families,
   --  accept/requeue/select paths, task activation or termination, abort and
   --  finalization paths, and generic task/protected bodies from becoming
   --  confidently legal while generic replay, representation, overload,
   --  abstract-state, closure, or fingerprint prerequisites remain unresolved.

   package Abstract_Consumers renames Editor.Ada_Abstract_State_Refined_State_Consumer_Integration_Legality;
   package Generic_Replay renames Editor.Ada_Generic_Abstract_State_Replay_Legality;
   package Overload_Generic renames Editor.Ada_Overload_Generic_Shared_State_Final_Legality;
   package Rep_Generic renames Editor.Ada_Representation_Generic_Shared_State_Final_Legality;
   package Closure renames Editor.Ada_Shared_State_Stabilized_Closure_Legality;
   package Tasking_Deep renames Editor.Ada_Tasking_Protected_Deep_Edge_Legality;
   package Tasking_Shared renames Editor.Ada_Tasking_Shared_State_Final_Legality;

   type Tasking_Generic_Final_Row_Id is new Natural;
   No_Tasking_Generic_Final_Row : constant Tasking_Generic_Final_Row_Id := 0;

   type Tasking_Generic_Final_Kind is
     (Tasking_Generic_Final_Protected_Action,
      Tasking_Generic_Final_Entry_Family_Queue,
      Tasking_Generic_Final_Accept_Body_Effect,
      Tasking_Generic_Final_Requeue_Path,
      Tasking_Generic_Final_Select_Alternative,
      Tasking_Generic_Final_Task_Activation,
      Tasking_Generic_Final_Task_Termination,
      Tasking_Generic_Final_Abort_Finalization,
      Tasking_Generic_Final_Generic_Task_Body,
      Tasking_Generic_Final_Generic_Protected_Body,
      Tasking_Generic_Final_Abstract_State_Effect,
      Tasking_Generic_Final_Representation_Sensitive_Effect,
      Tasking_Generic_Final_Unknown);

   type Tasking_Generic_Final_Blocker_Family is
     (Tasking_Generic_Final_Blocker_None,
      Tasking_Generic_Final_Blocker_Deep_Tasking,
      Tasking_Generic_Final_Blocker_Tasking_Shared_State,
      Tasking_Generic_Final_Blocker_Generic_Abstract_Replay,
      Tasking_Generic_Final_Blocker_Overload_Generic_Shared_State,
      Tasking_Generic_Final_Blocker_Representation_Generic_Shared_State,
      Tasking_Generic_Final_Blocker_Abstract_State_Consumer,
      Tasking_Generic_Final_Blocker_Stabilized_Shared_State_Closure,
      Tasking_Generic_Final_Blocker_Protected_Action_Reentrancy,
      Tasking_Generic_Final_Blocker_Entry_Family_Queue,
      Tasking_Generic_Final_Blocker_Accept_Requeue_Select,
      Tasking_Generic_Final_Blocker_Task_Activation_Termination,
      Tasking_Generic_Final_Blocker_Abort_Finalization,
      Tasking_Generic_Final_Blocker_Generic_Body_Effect,
      Tasking_Generic_Final_Blocker_Representation_Sensitive_Tasking,
      Tasking_Generic_Final_Blocker_Source_Fingerprint,
      Tasking_Generic_Final_Blocker_Substitution_Fingerprint,
      Tasking_Generic_Final_Blocker_Multiple,
      Tasking_Generic_Final_Blocker_Indeterminate);

   type Tasking_Generic_Final_Status is
     (Tasking_Generic_Final_Not_Checked,
      Tasking_Generic_Final_Legal_Protected_Action_Accepted,
      Tasking_Generic_Final_Legal_Entry_Family_Queue_Accepted,
      Tasking_Generic_Final_Legal_Accept_Body_Effect_Accepted,
      Tasking_Generic_Final_Legal_Requeue_Path_Accepted,
      Tasking_Generic_Final_Legal_Select_Alternative_Accepted,
      Tasking_Generic_Final_Legal_Task_Activation_Accepted,
      Tasking_Generic_Final_Legal_Task_Termination_Accepted,
      Tasking_Generic_Final_Legal_Abort_Finalization_Accepted,
      Tasking_Generic_Final_Legal_Generic_Task_Body_Accepted,
      Tasking_Generic_Final_Legal_Generic_Protected_Body_Accepted,
      Tasking_Generic_Final_Legal_Abstract_State_Effect_Accepted,
      Tasking_Generic_Final_Legal_Representation_Sensitive_Effect_Accepted,
      Tasking_Generic_Final_Missing_Deep_Tasking_Row,
      Tasking_Generic_Final_Deep_Tasking_Blocker,
      Tasking_Generic_Final_Missing_Tasking_Shared_Row,
      Tasking_Generic_Final_Tasking_Shared_Blocker,
      Tasking_Generic_Final_Missing_Generic_Replay_Row,
      Tasking_Generic_Final_Generic_Replay_Blocker,
      Tasking_Generic_Final_Missing_Overload_Generic_Row,
      Tasking_Generic_Final_Overload_Generic_Blocker,
      Tasking_Generic_Final_Missing_Representation_Generic_Row,
      Tasking_Generic_Final_Representation_Generic_Blocker,
      Tasking_Generic_Final_Missing_Abstract_Consumer_Row,
      Tasking_Generic_Final_Abstract_Consumer_Blocker,
      Tasking_Generic_Final_Missing_Stabilized_Closure_Row,
      Tasking_Generic_Final_Stabilized_Closure_Blocker,
      Tasking_Generic_Final_Protected_Action_Reentrancy_Blocker,
      Tasking_Generic_Final_Entry_Family_Queue_Blocker,
      Tasking_Generic_Final_Accept_Requeue_Select_Blocker,
      Tasking_Generic_Final_Task_Activation_Termination_Blocker,
      Tasking_Generic_Final_Abort_Finalization_Blocker,
      Tasking_Generic_Final_Generic_Body_Effect_Blocker,
      Tasking_Generic_Final_Representation_Sensitive_Tasking_Blocker,
      Tasking_Generic_Final_Source_Fingerprint_Mismatch,
      Tasking_Generic_Final_Substitution_Fingerprint_Mismatch,
      Tasking_Generic_Final_Multiple_Blockers,
      Tasking_Generic_Final_Indeterminate);

   type Tasking_Generic_Final_Context is record
      Id                         : Tasking_Generic_Final_Row_Id := No_Tasking_Generic_Final_Row;
      Kind                       : Tasking_Generic_Final_Kind := Tasking_Generic_Final_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Operation_Name             : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Deep_Tasking_Row           : Tasking_Deep.Deep_Tasking_Row_Id := Tasking_Deep.No_Deep_Tasking_Row;
      Deep_Tasking_Status        : Tasking_Deep.Deep_Tasking_Status := Tasking_Deep.Deep_Tasking_Not_Checked;
      Tasking_Shared_Row         : Tasking_Shared.Tasking_Shared_State_Row_Id := Tasking_Shared.No_Tasking_Shared_State_Row;
      Tasking_Shared_Status      : Tasking_Shared.Tasking_Shared_State_Status := Tasking_Shared.Tasking_Shared_State_Not_Checked;
      Generic_Replay_Row         : Generic_Replay.Generic_Abstract_Replay_Row_Id := Generic_Replay.No_Generic_Abstract_Replay_Row;
      Generic_Replay_Status      : Generic_Replay.Generic_Abstract_Replay_Status := Generic_Replay.Generic_Abstract_Replay_Not_Checked;
      Overload_Generic_Row       : Overload_Generic.Overload_Generic_Final_Row_Id := Overload_Generic.No_Overload_Generic_Final_Row;
      Overload_Generic_Status    : Overload_Generic.Overload_Generic_Final_Status := Overload_Generic.Overload_Generic_Final_Not_Checked;
      Representation_Generic_Row : Rep_Generic.Representation_Generic_Final_Row_Id := Rep_Generic.No_Representation_Generic_Final_Row;
      Representation_Generic_Status : Rep_Generic.Representation_Generic_Final_Status := Rep_Generic.Representation_Generic_Final_Not_Checked;
      Abstract_Consumer_Row      : Abstract_Consumers.Abstract_State_Consumer_Row_Id := Abstract_Consumers.No_Abstract_State_Consumer_Row;
      Abstract_Consumer_Status   : Abstract_Consumers.Abstract_State_Consumer_Status := Abstract_Consumers.Abstract_State_Consumer_Not_Checked;
      Stabilized_Closure_Row     : Closure.Shared_State_Stabilized_Closure_Id := Closure.No_Shared_State_Stabilized_Closure;
      Stabilized_Closure_Status  : Closure.Shared_State_Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Not_Checked;
      Requires_Deep_Tasking      : Boolean := True;
      Requires_Tasking_Shared    : Boolean := True;
      Requires_Generic_Replay    : Boolean := False;
      Requires_Overload_Generic  : Boolean := False;
      Requires_Representation_Generic : Boolean := False;
      Requires_Abstract_Consumer : Boolean := False;
      Requires_Stabilized_Closure : Boolean := True;
      Protected_Action_Reentrancy_Blocker : Boolean := False;
      Entry_Family_Queue_Blocker : Boolean := False;
      Accept_Requeue_Select_Blocker : Boolean := False;
      Task_Activation_Termination_Blocker : Boolean := False;
      Abort_Finalization_Blocker : Boolean := False;
      Generic_Body_Effect_Blocker : Boolean := False;
      Representation_Sensitive_Tasking_Blocker : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Tasking_Generic_Final_Row is record
      Id                         : Tasking_Generic_Final_Row_Id := No_Tasking_Generic_Final_Row;
      Context                    : Tasking_Generic_Final_Row_Id := No_Tasking_Generic_Final_Row;
      Kind                       : Tasking_Generic_Final_Kind := Tasking_Generic_Final_Unknown;
      Status                     : Tasking_Generic_Final_Status := Tasking_Generic_Final_Not_Checked;
      Blocker_Family             : Tasking_Generic_Final_Blocker_Family := Tasking_Generic_Final_Blocker_None;
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
      Fingerprint                : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Tasking_Generic_Final_Context_Model is private;
   type Tasking_Generic_Final_Model is private;
   type Tasking_Generic_Final_Set is private;

   procedure Clear (Model : in out Tasking_Generic_Final_Context_Model);
   procedure Add_Context (Model : in out Tasking_Generic_Final_Context_Model; Info : Tasking_Generic_Final_Context);
   function Context_Count (Model : Tasking_Generic_Final_Context_Model) return Natural;
   function Context_At (Model : Tasking_Generic_Final_Context_Model; Index : Positive) return Tasking_Generic_Final_Context;
   function Fingerprint (Model : Tasking_Generic_Final_Context_Model) return Natural;

   function Build (Contexts : Tasking_Generic_Final_Context_Model) return Tasking_Generic_Final_Model;
   function Count (Model : Tasking_Generic_Final_Model) return Natural;
   function Row_Count (Model : Tasking_Generic_Final_Model) return Natural renames Count;
   function Row_At (Model : Tasking_Generic_Final_Model; Index : Positive) return Tasking_Generic_Final_Row;

   function Query_Count (Set : Tasking_Generic_Final_Set) return Natural;
   function Query_At (Set : Tasking_Generic_Final_Set; Index : Positive) return Tasking_Generic_Final_Row;
   function Query_Status (Model : Tasking_Generic_Final_Model; Status : Tasking_Generic_Final_Status) return Tasking_Generic_Final_Set;
   function Query_Blocker_Family (Model : Tasking_Generic_Final_Model; Family : Tasking_Generic_Final_Blocker_Family) return Tasking_Generic_Final_Set;
   function Find_By_Node (Model : Tasking_Generic_Final_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Tasking_Generic_Final_Set;
   function Find_By_Source_Fingerprint (Model : Tasking_Generic_Final_Model; Source_Fingerprint : Natural) return Tasking_Generic_Final_Set;

   function Count_By_Status (Model : Tasking_Generic_Final_Model; Status : Tasking_Generic_Final_Status) return Natural;
   function Count_By_Blocker_Family (Model : Tasking_Generic_Final_Model; Family : Tasking_Generic_Final_Blocker_Family) return Natural;
   function Accepted_Count (Model : Tasking_Generic_Final_Model) return Natural;
   function Blocked_Count (Model : Tasking_Generic_Final_Model) return Natural;
   function Indeterminate_Count (Model : Tasking_Generic_Final_Model) return Natural;
   function Stable_Fingerprint (Model : Tasking_Generic_Final_Model) return Natural;

   function Is_Accepted (Status : Tasking_Generic_Final_Status) return Boolean;
   function Is_Blocked (Status : Tasking_Generic_Final_Status) return Boolean;
   function Is_Indeterminate (Status : Tasking_Generic_Final_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Tasking_Generic_Final_Context);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Tasking_Generic_Final_Row);

   type Tasking_Generic_Final_Context_Model is record
      Items       : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Tasking_Generic_Final_Model is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Tasking_Generic_Final_Set is record
      Rows : Row_Vectors.Vector;
   end record;

end Editor.Ada_Tasking_Generic_Shared_State_Final_Legality;
