with Ada.Containers.Vectors;
with Editor.Ada_Final_Semantic_Blocker_Trace_Closure;
with Editor.Ada_Final_Semantic_Diagnostic_Provenance;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Final_Semantic_Blocker_Remediation_Order is

   --  Pass1199 final semantic blocker remediation ordering.
   --
   --  This package consumes Pass1198 final semantic blocker trace closure and
   --  derives a deterministic remediation order for compiler-grade semantic
   --  debugging.  It is not a UI quick-fix/projection layer: it records which
   --  semantic evidence must be repaired first so downstream legality engines
   --  do not accept conclusions on incomplete inputs.  Ordering preserves
   --  blocker-family identity for stale snapshot evidence, AST/coverage repair,
   --  cross-unit dependency closure, view barriers, generic replay/backmapping,
   --  overload/type evidence, representation/freezing, flow/contract proof,
   --  tasking/protected effects, elaboration, accessibility/lifetime,
   --  discriminants/variants, multiple blockers, and indeterminate states.
   --  The model is deterministic, bounded, snapshot-owned, and performs no
   --  parsing, file IO, save/reload, dirty-state mutation, command/keybinding,
   --  workspace/render mutation, LSP use, compiler invocation, or external
   --  parser generation.

   package Trace renames Editor.Ada_Final_Semantic_Blocker_Trace_Closure;
   package Final_Prov renames Editor.Ada_Final_Semantic_Diagnostic_Provenance;

   subtype Final_Blocker_Family is Final_Prov.Final_Blocker_Family;
   subtype Final_Blocker_Trace_Id is Trace.Final_Blocker_Trace_Id;
   subtype Final_Blocker_Trace_Status is Trace.Final_Blocker_Trace_Status;
   subtype Final_Blocker_Trace_Root is Trace.Final_Blocker_Trace_Root;

   type Final_Remediation_Id is new Natural;
   No_Final_Remediation : constant Final_Remediation_Id := 0;

   type Final_Remediation_Status is
     (Final_Remediation_Not_Checked,
      Final_Remediation_No_Action_Legal,
      Final_Remediation_Reject_Stale_Input,
      Final_Remediation_Repair_AST_Coverage,
      Final_Remediation_Close_Cross_Unit_Dependency,
      Final_Remediation_Resolve_View_Barrier,
      Final_Remediation_Restore_Generic_Replay,
      Final_Remediation_Restore_Overload_Type_Evidence,
      Final_Remediation_Restore_Representation_Freezing,
      Final_Remediation_Restore_Flow_Contract_Proof,
      Final_Remediation_Restore_Tasking_Protected_Effects,
      Final_Remediation_Restore_Elaboration_Evidence,
      Final_Remediation_Restore_Accessibility_Lifetime,
      Final_Remediation_Restore_Discriminant_Variant,
      Final_Remediation_Split_Multiple_Blockers,
      Final_Remediation_Preserve_Error,
      Final_Remediation_Indeterminate);

   type Final_Remediation_Priority is
     (Final_Remediation_Priority_None,
      Final_Remediation_Priority_Snapshot,
      Final_Remediation_Priority_AST_Repair,
      Final_Remediation_Priority_Dependency,
      Final_Remediation_Priority_View,
      Final_Remediation_Priority_Generic_Replay,
      Final_Remediation_Priority_Core_Type,
      Final_Remediation_Priority_Representation,
      Final_Remediation_Priority_Object_State,
      Final_Remediation_Priority_Consumer_Chain,
      Final_Remediation_Priority_Multiple,
      Final_Remediation_Priority_Indeterminate);

   type Final_Remediation_Action is record
      Id                 : Final_Remediation_Id := No_Final_Remediation;
      Trace_Id           : Final_Blocker_Trace_Id := Trace.No_Final_Blocker_Trace;
      Status             : Final_Remediation_Status := Final_Remediation_Not_Checked;
      Priority           : Final_Remediation_Priority := Final_Remediation_Priority_None;
      Blocker_Family     : Final_Blocker_Family := Final_Prov.Final_Blocker_None;
      Trace_Status       : Final_Blocker_Trace_Status := Trace.Final_Trace_Not_Checked;
      Trace_Root         : Final_Blocker_Trace_Root := Trace.Final_Trace_Root_None;
      Node               : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Start_Line         : Positive := 1;
      Start_Column       : Positive := 1;
      End_Line           : Positive := 1;
      End_Column         : Positive := 1;
      Dependency_Order   : Natural := 0;
      Blocks_Downstream  : Boolean := False;
      Unlocks_Count      : Natural := 0;
      Source_Fingerprint : Natural := 0;
      Trace_Fingerprint  : Natural := 0;
      Fingerprint        : Natural := 0;
   end record;

   type Final_Remediation_Set is private;
   type Final_Remediation_Model is private;

   procedure Clear (Model : in out Final_Remediation_Model);

   function Build
     (Trace_Model : Trace.Final_Blocker_Trace_Model)
      return Final_Remediation_Model;

   function Action_Count (Model : Final_Remediation_Model) return Natural;
   function Action_At
     (Model : Final_Remediation_Model;
      Index : Positive) return Final_Remediation_Action;

   function Set_Count (Set : Final_Remediation_Set) return Natural;
   function Set_At
     (Set   : Final_Remediation_Set;
      Index : Positive) return Final_Remediation_Action;

   function Query_Status
     (Model  : Final_Remediation_Model;
      Status : Final_Remediation_Status) return Final_Remediation_Set;
   function Query_Priority
     (Model    : Final_Remediation_Model;
      Priority : Final_Remediation_Priority) return Final_Remediation_Set;
   function Query_Blocker
     (Model   : Final_Remediation_Model;
      Blocker : Final_Blocker_Family) return Final_Remediation_Set;
   function Query_Node
     (Model : Final_Remediation_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_Remediation_Set;
   function Query_Position
     (Model  : Final_Remediation_Model;
      Line   : Positive;
      Column : Positive) return Final_Remediation_Set;

   function First_Blocking_Action
     (Model : Final_Remediation_Model) return Final_Remediation_Action;
   function Count_Status
     (Model  : Final_Remediation_Model;
      Status : Final_Remediation_Status) return Natural;
   function Count_Priority
     (Model    : Final_Remediation_Model;
      Priority : Final_Remediation_Priority) return Natural;
   function Count_Blocker
     (Model   : Final_Remediation_Model;
      Blocker : Final_Blocker_Family) return Natural;

   function Legal_Action_Count (Model : Final_Remediation_Model) return Natural;
   function Stale_Action_Count (Model : Final_Remediation_Model) return Natural;
   function AST_Repair_Action_Count (Model : Final_Remediation_Model) return Natural;
   function Dependency_Action_Count (Model : Final_Remediation_Model) return Natural;
   function View_Barrier_Action_Count (Model : Final_Remediation_Model) return Natural;
   function Generic_Replay_Action_Count (Model : Final_Remediation_Model) return Natural;
   function Core_Type_Action_Count (Model : Final_Remediation_Model) return Natural;
   function Representation_Action_Count (Model : Final_Remediation_Model) return Natural;
   function Object_State_Action_Count (Model : Final_Remediation_Model) return Natural;
   function Consumer_Chain_Action_Count (Model : Final_Remediation_Model) return Natural;
   function Multiple_Blocker_Action_Count (Model : Final_Remediation_Model) return Natural;
   function Indeterminate_Action_Count (Model : Final_Remediation_Model) return Natural;
   function Blocking_Action_Count (Model : Final_Remediation_Model) return Natural;
   function Downstream_Unlock_Count (Model : Final_Remediation_Model) return Natural;
   function Fingerprint (Model : Final_Remediation_Model) return Natural;

private
   package Action_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Final_Remediation_Action);

   type Final_Remediation_Set is record
      Actions     : Action_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Final_Remediation_Model is record
      Actions                  : Action_Vectors.Vector;
      Legal_Total              : Natural := 0;
      Stale_Total              : Natural := 0;
      AST_Repair_Total         : Natural := 0;
      Dependency_Total         : Natural := 0;
      View_Barrier_Total       : Natural := 0;
      Generic_Replay_Total     : Natural := 0;
      Core_Type_Total          : Natural := 0;
      Representation_Total     : Natural := 0;
      Object_State_Total       : Natural := 0;
      Consumer_Chain_Total     : Natural := 0;
      Multiple_Blocker_Total   : Natural := 0;
      Indeterminate_Total      : Natural := 0;
      Blocking_Total           : Natural := 0;
      Downstream_Unlock_Total  : Natural := 0;
      Fingerprint              : Natural := 0;
   end record;

end Editor.Ada_Final_Semantic_Blocker_Remediation_Order;
