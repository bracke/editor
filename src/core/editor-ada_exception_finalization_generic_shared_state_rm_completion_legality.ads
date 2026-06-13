with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Generic_Shared_State_RM_Completion_Legality;
with Editor.Ada_Coverage_Proven_Generic_Shared_State_AST_Repair_Legality;
with Editor.Ada_Cross_Unit_Generic_Shared_State_RM_Completion_Closure_Legality;
with Editor.Ada_Elaboration_Generic_Shared_State_RM_Completion_Legality;
with Editor.Ada_Exception_Finalization_Generic_Shared_State_Final_Legality;
with Editor.Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality;
with Editor.Ada_Representation_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality;

package Editor.Ada_Exception_Finalization_Generic_Shared_State_RM_Completion_Legality is

   --  Pass1253 exception/finalization legality over the completed
   --  generic/shared-state RM chain.
   --
   --  This package consumes completed cross-unit RM closure, the prior
   --  exception/finalization generic/shared-state final chain, completed
   --  elaboration, completed accessibility/lifetime, overload/type RM,
   --  representation/freezing RM, tasking/protected RM, and coverage-proven
   --  AST repair evidence.  Raise statements, raise expressions, handlers,
   --  exception propagation, controlled initialization/adjust/finalize,
   --  master finalization, cleanup actions, abort-deferred finalization,
   --  task termination, no-return paths, generic replay finalization,
   --  cross-unit finalization, dispatching exception effects, renamed handler
   --  sources, predicate finalization checks, dataflow cleanup edges, and
   --  accessibility master finalization are accepted only when the completed
   --  RM evidence agrees and fingerprints still match.

   package Cross_RM renames Editor.Ada_Cross_Unit_Generic_Shared_State_RM_Completion_Closure_Legality;
   package Prior_Exception renames Editor.Ada_Exception_Finalization_Generic_Shared_State_Final_Legality;
   package Elaboration_RM renames Editor.Ada_Elaboration_Generic_Shared_State_RM_Completion_Legality;
   package Accessibility_RM renames Editor.Ada_Accessibility_Generic_Shared_State_RM_Completion_Legality;
   package Overload_RM renames Editor.Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality;
   package Representation_RM renames Editor.Ada_Representation_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
   package Tasking_RM renames Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
   package AST_Repair renames Editor.Ada_Coverage_Proven_Generic_Shared_State_AST_Repair_Legality;

   type Exception_RM_Completion_Row_Id is new Natural;
   No_Exception_RM_Completion_Row : constant Exception_RM_Completion_Row_Id := 0;

   type Exception_RM_Completion_Kind is
     (      Exception_RM_Completion_Raise_Statement,
      Exception_RM_Completion_Raise_Expression,
      Exception_RM_Completion_Reraise,
      Exception_RM_Completion_Handler_Choice,
      Exception_RM_Completion_Exception_Propagation,
      Exception_RM_Completion_Controlled_Initialize,
      Exception_RM_Completion_Controlled_Adjust,
      Exception_RM_Completion_Controlled_Finalize,
      Exception_RM_Completion_Master_Finalization,
      Exception_RM_Completion_Cleanup_Action,
      Exception_RM_Completion_Abort_Deferred_Finalization,
      Exception_RM_Completion_Task_Termination,
      Exception_RM_Completion_No_Return_Path,
      Exception_RM_Completion_Generic_Replay_Finalization,
      Exception_RM_Completion_Cross_Unit_Finalization,
      Exception_RM_Completion_Dispatching_Exception_Effect,
      Exception_RM_Completion_Renamed_Handler_Source,
      Exception_RM_Completion_Predicate_Check_Finalization,
      Exception_RM_Completion_Dataflow_Cleanup_Edge,
      Exception_RM_Completion_Accessibility_Master_Finalization,
      Exception_RM_Completion_Unknown);

   type Exception_RM_Completion_Blocker_Family is
     (Exception_RM_Completion_Blocker_None,
      Exception_RM_Completion_Blocker_Cross_Unit_RM_Completion,
      Exception_RM_Completion_Blocker_Prior_Exception_Finalization,
      Exception_RM_Completion_Blocker_Elaboration_RM_Completion,
      Exception_RM_Completion_Blocker_Accessibility_RM_Completion,
      Exception_RM_Completion_Blocker_Overload_RM_Completion,
      Exception_RM_Completion_Blocker_Representation_RM_Completion,
      Exception_RM_Completion_Blocker_Tasking_RM_Completion,
      Exception_RM_Completion_Blocker_AST_Repair,
      Exception_RM_Completion_Blocker_Exception_Propagation,
      Exception_RM_Completion_Blocker_Handler_Resolution,
      Exception_RM_Completion_Blocker_Finalize_Order,
      Exception_RM_Completion_Blocker_Controlled_Operation,
      Exception_RM_Completion_Blocker_Abort_Deferred_Finalization,
      Exception_RM_Completion_Blocker_Task_Termination,
      Exception_RM_Completion_Blocker_No_Return,
      Exception_RM_Completion_Blocker_Cleanup_Path,
      Exception_RM_Completion_Blocker_Generic_Body,
      Exception_RM_Completion_Blocker_View_Barrier,
      Exception_RM_Completion_Blocker_Source_Fingerprint,
      Exception_RM_Completion_Blocker_Substitution_Fingerprint,
      Exception_RM_Completion_Blocker_Multiple,
      Exception_RM_Completion_Blocker_Indeterminate);

   type Exception_RM_Completion_Status is
     (Exception_RM_Completion_Not_Checked,
      Exception_RM_Completion_Legal_Raise_Statement_Accepted,
      Exception_RM_Completion_Legal_Raise_Expression_Accepted,
      Exception_RM_Completion_Legal_Reraise_Accepted,
      Exception_RM_Completion_Legal_Handler_Choice_Accepted,
      Exception_RM_Completion_Legal_Exception_Propagation_Accepted,
      Exception_RM_Completion_Legal_Controlled_Initialize_Accepted,
      Exception_RM_Completion_Legal_Controlled_Adjust_Accepted,
      Exception_RM_Completion_Legal_Controlled_Finalize_Accepted,
      Exception_RM_Completion_Legal_Master_Finalization_Accepted,
      Exception_RM_Completion_Legal_Cleanup_Action_Accepted,
      Exception_RM_Completion_Legal_Abort_Deferred_Finalization_Accepted,
      Exception_RM_Completion_Legal_Task_Termination_Accepted,
      Exception_RM_Completion_Legal_No_Return_Path_Accepted,
      Exception_RM_Completion_Legal_Generic_Replay_Finalization_Accepted,
      Exception_RM_Completion_Legal_Cross_Unit_Finalization_Accepted,
      Exception_RM_Completion_Legal_Dispatching_Exception_Effect_Accepted,
      Exception_RM_Completion_Legal_Renamed_Handler_Source_Accepted,
      Exception_RM_Completion_Legal_Predicate_Check_Finalization_Accepted,
      Exception_RM_Completion_Legal_Dataflow_Cleanup_Edge_Accepted,
      Exception_RM_Completion_Legal_Accessibility_Master_Finalization_Accepted,
      Exception_RM_Completion_Missing_Cross_Unit_RM_Row,
      Exception_RM_Completion_Cross_Unit_RM_Blocker,
      Exception_RM_Completion_Missing_Prior_Exception_Row,
      Exception_RM_Completion_Prior_Exception_Blocker,
      Exception_RM_Completion_Missing_Elaboration_RM_Row,
      Exception_RM_Completion_Elaboration_RM_Blocker,
      Exception_RM_Completion_Missing_Accessibility_RM_Row,
      Exception_RM_Completion_Accessibility_RM_Blocker,
      Exception_RM_Completion_Missing_Overload_RM_Row,
      Exception_RM_Completion_Overload_RM_Blocker,
      Exception_RM_Completion_Missing_Representation_RM_Row,
      Exception_RM_Completion_Representation_RM_Blocker,
      Exception_RM_Completion_Missing_Tasking_RM_Row,
      Exception_RM_Completion_Tasking_RM_Blocker,
      Exception_RM_Completion_Missing_AST_Repair_Row,
      Exception_RM_Completion_AST_Repair_Blocker,
      Exception_RM_Completion_Exception_Propagation_Blocker,
      Exception_RM_Completion_Handler_Resolution_Blocker,
      Exception_RM_Completion_Finalize_Order_Blocker,
      Exception_RM_Completion_Controlled_Operation_Blocker,
      Exception_RM_Completion_Abort_Deferred_Finalization_Blocker,
      Exception_RM_Completion_Task_Termination_Blocker,
      Exception_RM_Completion_No_Return_Blocker,
      Exception_RM_Completion_Cleanup_Path_Blocker,
      Exception_RM_Completion_Generic_Body_Unavailable,
      Exception_RM_Completion_View_Barrier,
      Exception_RM_Completion_Source_Fingerprint_Mismatch,
      Exception_RM_Completion_Substitution_Fingerprint_Mismatch,
      Exception_RM_Completion_Multiple_Blockers,
      Exception_RM_Completion_Indeterminate);

   type Exception_RM_Completion_Context is record
      Id                         : Exception_RM_Completion_Row_Id := No_Exception_RM_Completion_Row;
      Kind                       : Exception_RM_Completion_Kind := Exception_RM_Completion_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Exception_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Exception_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Cross_RM_Row               : Cross_RM.Cross_Unit_RM_Completion_Closure_Id := Cross_RM.No_Cross_Unit_RM_Completion_Closure;
      Cross_RM_Status            : Cross_RM.Cross_Unit_RM_Completion_Status := Cross_RM.Cross_Unit_RM_Completion_Not_Checked;
      Prior_Exception_Row        : Prior_Exception.Exception_Generic_Final_Row_Id := Prior_Exception.No_Exception_Generic_Final_Row;
      Prior_Exception_Status     : Prior_Exception.Exception_Generic_Final_Status := Prior_Exception.Exception_Generic_Final_Not_Checked;
      Elaboration_RM_Row         : Elaboration_RM.Elaboration_RM_Completion_Row_Id := Elaboration_RM.No_Elaboration_RM_Completion_Row;
      Elaboration_RM_Status      : Elaboration_RM.Elaboration_RM_Completion_Status := Elaboration_RM.Elaboration_RM_Completion_Not_Checked;
      Accessibility_RM_Row       : Accessibility_RM.Accessibility_RM_Completion_Row_Id := Accessibility_RM.No_Accessibility_RM_Completion_Row;
      Accessibility_RM_Status    : Accessibility_RM.Accessibility_RM_Completion_Status := Accessibility_RM.Accessibility_RM_Completion_Not_Checked;
      Overload_RM_Row            : Overload_RM.Overload_Generic_RM_Edge_Completion_Id := Overload_RM.No_Overload_Generic_RM_Edge_Completion;
      Overload_RM_Status         : Overload_RM.Overload_Generic_RM_Edge_Status := Overload_RM.Overload_Generic_RM_Edge_Not_Checked;
      Representation_RM_Row      : Representation_RM.Representation_Generic_RM_Hard_Case_Id := Representation_RM.No_Representation_Generic_RM_Hard_Case;
      Representation_RM_Status   : Representation_RM.Representation_Generic_RM_Hard_Case_Status := Representation_RM.Representation_Generic_RM_Hard_Case_Not_Checked;
      Tasking_RM_Row             : Tasking_RM.Tasking_Generic_RM_Hard_Case_Id := Tasking_RM.No_Tasking_Generic_RM_Hard_Case;
      Tasking_RM_Status          : Tasking_RM.Tasking_Generic_RM_Hard_Case_Status := Tasking_RM.Tasking_Generic_RM_Hard_Case_Not_Checked;
      AST_Repair_Row             : AST_Repair.Coverage_Proven_AST_Repair_Id := AST_Repair.No_Coverage_Proven_AST_Repair;
      AST_Repair_Status          : AST_Repair.Coverage_Proven_AST_Repair_Status := AST_Repair.Coverage_Proven_AST_Repair_Not_Checked;
      Requires_Cross_RM          : Boolean := True;
      Requires_Prior_Exception   : Boolean := True;
      Requires_Elaboration_RM    : Boolean := True;
      Requires_Accessibility_RM  : Boolean := True;
      Requires_Overload_RM       : Boolean := True;
      Requires_Representation_RM : Boolean := True;
      Requires_Tasking_RM        : Boolean := True;
      Requires_AST_Repair        : Boolean := False;
      Exception_Propagation_Error          : Boolean := False;
      Handler_Resolution_Error             : Boolean := False;
      Finalize_Order_Error                 : Boolean := False;
      Controlled_Operation_Error           : Boolean := False;
      Abort_Deferred_Finalization_Error    : Boolean := False;
      Task_Termination_Error               : Boolean := False;
      No_Return_Error                      : Boolean := False;
      Cleanup_Path_Error                   : Boolean := False;
      Generic_Body_Unavailable             : Boolean := False;
      View_Barrier                         : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Exception_RM_Completion_Row is record
      Id                         : Exception_RM_Completion_Row_Id := No_Exception_RM_Completion_Row;
      Context                    : Exception_RM_Completion_Row_Id := No_Exception_RM_Completion_Row;
      Kind                       : Exception_RM_Completion_Kind := Exception_RM_Completion_Unknown;
      Status                     : Exception_RM_Completion_Status := Exception_RM_Completion_Not_Checked;
      Blocker_Family             : Exception_RM_Completion_Blocker_Family := Exception_RM_Completion_Blocker_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Exception_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
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

   type Exception_RM_Completion_Context_Model is private;
   type Exception_RM_Completion_Model is private;
   type Exception_RM_Completion_Set is private;

   procedure Clear (Model : in out Exception_RM_Completion_Context_Model);
   procedure Add_Context (Model : in out Exception_RM_Completion_Context_Model; Info : Exception_RM_Completion_Context);
   function Context_Count (Model : Exception_RM_Completion_Context_Model) return Natural;
   function Context_At (Model : Exception_RM_Completion_Context_Model; Index : Positive) return Exception_RM_Completion_Context;
   function Context_Fingerprint (Model : Exception_RM_Completion_Context_Model) return Natural;

   function Build (Contexts : Exception_RM_Completion_Context_Model) return Exception_RM_Completion_Model;
   function Count (Model : Exception_RM_Completion_Model) return Natural;
   function Row_Count (Model : Exception_RM_Completion_Model) return Natural renames Count;
   function Row_At (Model : Exception_RM_Completion_Model; Index : Positive) return Exception_RM_Completion_Row;
   function Query_Count (Set : Exception_RM_Completion_Set) return Natural;
   function Query_At (Set : Exception_RM_Completion_Set; Index : Positive) return Exception_RM_Completion_Row;
   function Query_Status (Model : Exception_RM_Completion_Model; Status : Exception_RM_Completion_Status) return Exception_RM_Completion_Set;
   function Query_Blocker_Family (Model : Exception_RM_Completion_Model; Family : Exception_RM_Completion_Blocker_Family) return Exception_RM_Completion_Set;
   function Find_By_Node (Model : Exception_RM_Completion_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Exception_RM_Completion_Set;
   function Find_By_Source_Fingerprint (Model : Exception_RM_Completion_Model; Source_Fingerprint : Natural) return Exception_RM_Completion_Set;
   function Count_By_Status (Model : Exception_RM_Completion_Model; Status : Exception_RM_Completion_Status) return Natural;
   function Count_By_Blocker_Family (Model : Exception_RM_Completion_Model; Family : Exception_RM_Completion_Blocker_Family) return Natural;
   function Accepted_Count (Model : Exception_RM_Completion_Model) return Natural;
   function Blocked_Count (Model : Exception_RM_Completion_Model) return Natural;
   function Indeterminate_Count (Model : Exception_RM_Completion_Model) return Natural;
   function Stable_Fingerprint (Model : Exception_RM_Completion_Model) return Natural;

   function Is_Accepted (Status : Exception_RM_Completion_Status) return Boolean;
   function Is_Blocked (Status : Exception_RM_Completion_Status) return Boolean;
   function Is_Indeterminate (Status : Exception_RM_Completion_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Exception_RM_Completion_Context);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Exception_RM_Completion_Row);

   type Exception_RM_Completion_Context_Model is record
      Items : Context_Vectors.Vector;
      Stable_Fingerprint : Natural := 0;
   end record;

   type Exception_RM_Completion_Model is record
      Rows : Row_Vectors.Vector;
      Stable_Fingerprint : Natural := 0;
   end record;

   type Exception_RM_Completion_Set is record
      Rows : Row_Vectors.Vector;
   end record;
end Editor.Ada_Exception_Finalization_Generic_Shared_State_RM_Completion_Legality;
