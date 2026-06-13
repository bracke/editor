with Ada.Containers.Vectors;
with Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Generic_Shared_State_RM_Completion_Remediation_Worklist_Legality is

   --  Pass1257 remediation worklist for the RM-completed generic/shared-state
   --  semantic chain.
   --
   --  The package consumes Pass1256 diagnostic-boundary rows and converts them
   --  into prerequisite-ordered semantic re-analysis work.  It is part of the
   --  bounded remediation/recheck/stabilization loop for completed RM evidence:
   --  current accepted rows remain non-diagnostic evidence, while blockers keep
   --  their original cross-unit, elaboration, accessibility,
   --  exception/finalization, predicate/invariant, overload/type,
   --  representation/freezing, tasking/protected, AST repair, dataflow,
   --  view-barrier, fingerprint, multiple-blocker, and indeterminate families.

   package Diagnostics renames Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration;

   type RM_Completion_Worklist_Id is new Natural;
   No_RM_Completion_Worklist_Item : constant RM_Completion_Worklist_Id := 0;

   subtype RM_Completion_Worklist_Family is Diagnostics.RM_Completion_Diagnostic_Family;
   subtype RM_Completion_Worklist_Diagnostic_Status is Diagnostics.RM_Completion_Diagnostic_Status;

   type RM_Completion_Worklist_Action is
     (RM_Completion_Worklist_No_Action,
      RM_Completion_Worklist_Keep_Current_Evidence,
      RM_Completion_Worklist_Resolve_Prior_Dataflow,
      RM_Completion_Worklist_Resolve_Cross_Unit_RM_Completion,
      RM_Completion_Worklist_Resolve_Elaboration_RM_Completion,
      RM_Completion_Worklist_Resolve_Accessibility_RM_Completion,
      RM_Completion_Worklist_Resolve_Exception_Finalization_RM_Completion,
      RM_Completion_Worklist_Resolve_Predicate_RM_Completion,
      RM_Completion_Worklist_Resolve_Overload_RM_Completion,
      RM_Completion_Worklist_Resolve_Representation_RM_Completion,
      RM_Completion_Worklist_Resolve_Tasking_RM_Completion,
      RM_Completion_Worklist_Repair_AST_Coverage,
      RM_Completion_Worklist_Resolve_Read_Before_Write,
      RM_Completion_Worklist_Resolve_Component_Initialization,
      RM_Completion_Worklist_Resolve_Out_Parameter_Flow,
      RM_Completion_Worklist_Resolve_Return_Object_Flow,
      RM_Completion_Worklist_Resolve_Branch_Loop_Merge,
      RM_Completion_Worklist_Resolve_Exception_Path,
      RM_Completion_Worklist_Resolve_Finalization_Path,
      RM_Completion_Worklist_Resolve_Access_Escape,
      RM_Completion_Worklist_Resolve_Variant_Component,
      RM_Completion_Worklist_Resolve_Volatile_Atomic_Effect,
      RM_Completion_Worklist_Resolve_Generic_Substitution,
      RM_Completion_Worklist_Resolve_Dispatching_Effect,
      RM_Completion_Worklist_Resolve_View_Barrier,
      RM_Completion_Worklist_Recheck_Fingerprint,
      RM_Completion_Worklist_Split_Multiple_Blockers,
      RM_Completion_Worklist_Recheck_Indeterminate);

   type RM_Completion_Worklist_Priority is
     (RM_Completion_Worklist_Priority_None,
      RM_Completion_Worklist_Priority_Current_Evidence,
      RM_Completion_Worklist_Priority_Stale_Or_Fingerprint,
      RM_Completion_Worklist_Priority_AST_Or_Coverage,
      RM_Completion_Worklist_Priority_Cross_Unit_Closure,
      RM_Completion_Worklist_Priority_Elaboration,
      RM_Completion_Worklist_Priority_Accessibility,
      RM_Completion_Worklist_Priority_Exception_Finalization,
      RM_Completion_Worklist_Priority_Predicate_Invariant,
      RM_Completion_Worklist_Priority_Overload_Or_Type,
      RM_Completion_Worklist_Priority_Representation,
      RM_Completion_Worklist_Priority_Tasking_Protected,
      RM_Completion_Worklist_Priority_Dataflow,
      RM_Completion_Worklist_Priority_Access_Escape,
      RM_Completion_Worklist_Priority_Discriminant_Variant,
      RM_Completion_Worklist_Priority_Volatile_Atomic,
      RM_Completion_Worklist_Priority_Generic_Replay,
      RM_Completion_Worklist_Priority_Dispatching,
      RM_Completion_Worklist_Priority_View_Barrier,
      RM_Completion_Worklist_Priority_Multiple,
      RM_Completion_Worklist_Priority_Indeterminate);

   type RM_Completion_Worklist_Item is record
      Id                       : RM_Completion_Worklist_Id := No_RM_Completion_Worklist_Item;
      Diagnostic_Row           : Diagnostics.RM_Completion_Diagnostic_Id := Diagnostics.No_RM_Completion_Diagnostic;
      Diagnostic_Status        : RM_Completion_Worklist_Diagnostic_Status := Diagnostics.RM_Completion_Diagnostic_Not_Checked;
      Family                   : RM_Completion_Worklist_Family := Diagnostics.RM_Completion_Diagnostic_Unknown;
      Action                   : RM_Completion_Worklist_Action := RM_Completion_Worklist_No_Action;
      Priority                 : RM_Completion_Worklist_Priority := RM_Completion_Worklist_Priority_None;
      Node                     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Current_Evidence         : Boolean := False;
      Ready_For_Recheck        : Boolean := False;
      Blocks_Downstream        : Boolean := False;
      Source_Fingerprint       : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Semantic_Fingerprint     : Natural := 0;
      Diagnostic_Fingerprint   : Natural := 0;
      Worklist_Fingerprint     : Natural := 0;
      Start_Line               : Positive := 1;
      Start_Column             : Positive := 1;
      End_Line                 : Positive := 1;
      End_Column               : Positive := 1;
   end record;

   type RM_Completion_Worklist_Model is private;
   type RM_Completion_Worklist_Set is private;

   procedure Clear (Model : in out RM_Completion_Worklist_Model);

   function Build
     (Diagnostics_Model : Diagnostics.RM_Completion_Diagnostic_Model)
      return RM_Completion_Worklist_Model;

   function Count (Model : RM_Completion_Worklist_Model) return Natural;
   function Row_At
     (Model : RM_Completion_Worklist_Model;
      Index : Positive) return RM_Completion_Worklist_Item;

   function Query_Count (Set : RM_Completion_Worklist_Set) return Natural;
   function Query_At
     (Set   : RM_Completion_Worklist_Set;
      Index : Positive) return RM_Completion_Worklist_Item;

   function Query_Action
     (Model  : RM_Completion_Worklist_Model;
      Action : RM_Completion_Worklist_Action) return RM_Completion_Worklist_Set;
   function Query_Family
     (Model  : RM_Completion_Worklist_Model;
      Family : RM_Completion_Worklist_Family) return RM_Completion_Worklist_Set;
   function Query_Priority
     (Model    : RM_Completion_Worklist_Model;
      Priority : RM_Completion_Worklist_Priority) return RM_Completion_Worklist_Set;
   function Query_Node
     (Model : RM_Completion_Worklist_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return RM_Completion_Worklist_Set;
   function Query_Source_Fingerprint
     (Model       : RM_Completion_Worklist_Model;
      Fingerprint : Natural) return RM_Completion_Worklist_Set;

   function Count_Action
     (Model  : RM_Completion_Worklist_Model;
      Action : RM_Completion_Worklist_Action) return Natural;
   function Count_Family
     (Model  : RM_Completion_Worklist_Model;
      Family : RM_Completion_Worklist_Family) return Natural;
   function Count_Priority
     (Model    : RM_Completion_Worklist_Model;
      Priority : RM_Completion_Worklist_Priority) return Natural;

   function Current_Evidence_Count (Model : RM_Completion_Worklist_Model) return Natural;
   function Ready_For_Recheck_Count (Model : RM_Completion_Worklist_Model) return Natural;
   function Blocked_Downstream_Count (Model : RM_Completion_Worklist_Model) return Natural;
   function Fingerprint_Mismatch_Count (Model : RM_Completion_Worklist_Model) return Natural;
   function Indeterminate_Count (Model : RM_Completion_Worklist_Model) return Natural;
   function Stable_Fingerprint (Model : RM_Completion_Worklist_Model) return Natural;

   function Is_Current_Evidence (Item : RM_Completion_Worklist_Item) return Boolean;
   function Is_Ready_For_Recheck (Item : RM_Completion_Worklist_Item) return Boolean;
   function Blocks_Downstream (Item : RM_Completion_Worklist_Item) return Boolean;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => RM_Completion_Worklist_Item);

   type RM_Completion_Worklist_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type RM_Completion_Worklist_Model is record
      Rows                       : Row_Vectors.Vector;
      Current_Evidence_Total     : Natural := 0;
      Ready_For_Recheck_Total    : Natural := 0;
      Blocked_Downstream_Total   : Natural := 0;
      Fingerprint_Mismatch_Total : Natural := 0;
      Indeterminate_Total        : Natural := 0;
      Stable_Fingerprint_Value   : Natural := 0;
   end record;

end Editor.Ada_Generic_Shared_State_RM_Completion_Remediation_Worklist_Legality;
