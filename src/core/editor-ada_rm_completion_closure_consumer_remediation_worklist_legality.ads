with Ada.Containers.Vectors;
with Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_RM_Completion_Closure_Consumer_Remediation_Worklist_Legality is

   --  Pass1274 remediation worklist for the direct RM-completion closure
   --  consumer chain.
   --
   --  This package consumes Pass1273 diagnostic-boundary rows and converts
   --  blocking direct-consumer diagnostics into prerequisite-ordered semantic
   --  re-analysis work.  Accepted rows remain current semantic evidence;
   --  blockers keep their original cross-unit, elaboration, accessibility,
   --  exception/finalization, overload/type, representation/freezing,
   --  tasking/protected, dataflow, predicate/invariant, AST/coverage,
   --  generic-substitution, fingerprint, multiple-blocker, and indeterminate
   --  families before later recheck/stabilization passes may trust them.

   package Diagnostics renames Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration;

   type RM_Closure_Consumer_Worklist_Id is new Natural;
   No_RM_Closure_Consumer_Worklist_Item : constant RM_Closure_Consumer_Worklist_Id := 0;

   subtype RM_Closure_Consumer_Worklist_Family is Diagnostics.RM_Closure_Consumer_Diagnostic_Family;
   subtype RM_Closure_Consumer_Worklist_Diagnostic_Status is Diagnostics.RM_Closure_Consumer_Diagnostic_Status;

   type RM_Closure_Consumer_Worklist_Action is
     (RM_Closure_Consumer_Worklist_No_Action,
      RM_Closure_Consumer_Worklist_Keep_Current_Evidence,
      RM_Closure_Consumer_Worklist_Resolve_Predicate_RM,
      RM_Closure_Consumer_Worklist_Resolve_Stabilized_Closure,
      RM_Closure_Consumer_Worklist_Recheck_Stale_Or_Fingerprint,
      RM_Closure_Consumer_Worklist_Repair_AST_Coverage,
      RM_Closure_Consumer_Worklist_Resolve_Cross_Unit,
      RM_Closure_Consumer_Worklist_Resolve_Generic_Substitution,
      RM_Closure_Consumer_Worklist_Resolve_Dataflow,
      RM_Closure_Consumer_Worklist_Resolve_Volatile_Atomic,
      RM_Closure_Consumer_Worklist_Resolve_Overload_Type,
      RM_Closure_Consumer_Worklist_Resolve_Representation,
      RM_Closure_Consumer_Worklist_Resolve_Tasking_Protected,
      RM_Closure_Consumer_Worklist_Resolve_Elaboration,
      RM_Closure_Consumer_Worklist_Resolve_Accessibility,
      RM_Closure_Consumer_Worklist_Resolve_Discriminant_Variant,
      RM_Closure_Consumer_Worklist_Resolve_Exception_Finalization,
      RM_Closure_Consumer_Worklist_Resolve_Renaming_Alias,
      RM_Closure_Consumer_Worklist_Resolve_Predicate_Invariant,
      RM_Closure_Consumer_Worklist_Recheck_Source_Fingerprint,
      RM_Closure_Consumer_Worklist_Recheck_Substitution_Fingerprint,
      RM_Closure_Consumer_Worklist_Split_Multiple_Blockers,
      RM_Closure_Consumer_Worklist_Recheck_Indeterminate);

   type RM_Closure_Consumer_Worklist_Priority is
     (RM_Closure_Consumer_Worklist_Priority_None,
      RM_Closure_Consumer_Worklist_Priority_Current_Evidence,
      RM_Closure_Consumer_Worklist_Priority_Stale_Or_Fingerprint,
      RM_Closure_Consumer_Worklist_Priority_AST_Or_Coverage,
      RM_Closure_Consumer_Worklist_Priority_Cross_Unit,
      RM_Closure_Consumer_Worklist_Priority_Generic_Substitution,
      RM_Closure_Consumer_Worklist_Priority_Dataflow,
      RM_Closure_Consumer_Worklist_Priority_Volatile_Atomic,
      RM_Closure_Consumer_Worklist_Priority_Overload_Type,
      RM_Closure_Consumer_Worklist_Priority_Representation,
      RM_Closure_Consumer_Worklist_Priority_Tasking_Protected,
      RM_Closure_Consumer_Worklist_Priority_Elaboration,
      RM_Closure_Consumer_Worklist_Priority_Accessibility,
      RM_Closure_Consumer_Worklist_Priority_Exception_Finalization,
      RM_Closure_Consumer_Worklist_Priority_Predicate_Invariant,
      RM_Closure_Consumer_Worklist_Priority_Discriminant_Variant,
      RM_Closure_Consumer_Worklist_Priority_Renaming_Alias,
      RM_Closure_Consumer_Worklist_Priority_Multiple,
      RM_Closure_Consumer_Worklist_Priority_Indeterminate);

   type RM_Closure_Consumer_Worklist_Item is record
      Id                         : RM_Closure_Consumer_Worklist_Id := No_RM_Closure_Consumer_Worklist_Item;
      Diagnostic_Row             : Diagnostics.RM_Closure_Consumer_Diagnostic_Id := Diagnostics.No_RM_Closure_Consumer_Diagnostic;
      Diagnostic_Status          : RM_Closure_Consumer_Worklist_Diagnostic_Status := Diagnostics.RM_Closure_Consumer_Diagnostic_Not_Checked;
      Family                     : RM_Closure_Consumer_Worklist_Family := Diagnostics.RM_Closure_Consumer_Diagnostic_Unknown;
      Action                     : RM_Closure_Consumer_Worklist_Action := RM_Closure_Consumer_Worklist_No_Action;
      Priority                   : RM_Closure_Consumer_Worklist_Priority := RM_Closure_Consumer_Worklist_Priority_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Current_Evidence           : Boolean := False;
      Ready_For_Recheck          : Boolean := False;
      Blocks_Downstream          : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Semantic_Fingerprint       : Natural := 0;
      Diagnostic_Fingerprint     : Natural := 0;
      Worklist_Fingerprint       : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type RM_Closure_Consumer_Worklist_Model is private;
   type RM_Closure_Consumer_Worklist_Set is private;

   procedure Clear (Model : in out RM_Closure_Consumer_Worklist_Model);

   function Build
     (Diagnostics_Model : Diagnostics.RM_Closure_Consumer_Diagnostic_Model)
      return RM_Closure_Consumer_Worklist_Model;

   function Count (Model : RM_Closure_Consumer_Worklist_Model) return Natural;
   function Row_At
     (Model : RM_Closure_Consumer_Worklist_Model;
      Index : Positive) return RM_Closure_Consumer_Worklist_Item;

   function Query_Count (Set : RM_Closure_Consumer_Worklist_Set) return Natural;
   function Query_At
     (Set   : RM_Closure_Consumer_Worklist_Set;
      Index : Positive) return RM_Closure_Consumer_Worklist_Item;

   function Query_Action
     (Model  : RM_Closure_Consumer_Worklist_Model;
      Action : RM_Closure_Consumer_Worklist_Action) return RM_Closure_Consumer_Worklist_Set;
   function Query_Family
     (Model  : RM_Closure_Consumer_Worklist_Model;
      Family : RM_Closure_Consumer_Worklist_Family) return RM_Closure_Consumer_Worklist_Set;
   function Query_Priority
     (Model    : RM_Closure_Consumer_Worklist_Model;
      Priority : RM_Closure_Consumer_Worklist_Priority) return RM_Closure_Consumer_Worklist_Set;
   function Query_Node
     (Model : RM_Closure_Consumer_Worklist_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return RM_Closure_Consumer_Worklist_Set;
   function Query_Source_Fingerprint
     (Model       : RM_Closure_Consumer_Worklist_Model;
      Fingerprint : Natural) return RM_Closure_Consumer_Worklist_Set;

   function Count_Action
     (Model  : RM_Closure_Consumer_Worklist_Model;
      Action : RM_Closure_Consumer_Worklist_Action) return Natural;
   function Count_Family
     (Model  : RM_Closure_Consumer_Worklist_Model;
      Family : RM_Closure_Consumer_Worklist_Family) return Natural;
   function Count_Priority
     (Model    : RM_Closure_Consumer_Worklist_Model;
      Priority : RM_Closure_Consumer_Worklist_Priority) return Natural;

   function Current_Evidence_Count (Model : RM_Closure_Consumer_Worklist_Model) return Natural;
   function Ready_For_Recheck_Count (Model : RM_Closure_Consumer_Worklist_Model) return Natural;
   function Blocked_Downstream_Count (Model : RM_Closure_Consumer_Worklist_Model) return Natural;
   function Fingerprint_Mismatch_Count (Model : RM_Closure_Consumer_Worklist_Model) return Natural;
   function Indeterminate_Count (Model : RM_Closure_Consumer_Worklist_Model) return Natural;
   function Stable_Fingerprint (Model : RM_Closure_Consumer_Worklist_Model) return Natural;

   function Is_Current_Evidence (Item : RM_Closure_Consumer_Worklist_Item) return Boolean;
   function Is_Ready_For_Recheck (Item : RM_Closure_Consumer_Worklist_Item) return Boolean;
   function Blocks_Downstream (Item : RM_Closure_Consumer_Worklist_Item) return Boolean;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => RM_Closure_Consumer_Worklist_Item);

   type RM_Closure_Consumer_Worklist_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type RM_Closure_Consumer_Worklist_Model is record
      Rows                       : Row_Vectors.Vector;
      Current_Evidence_Total     : Natural := 0;
      Ready_For_Recheck_Total    : Natural := 0;
      Blocked_Downstream_Total   : Natural := 0;
      Fingerprint_Mismatch_Total : Natural := 0;
      Indeterminate_Total        : Natural := 0;
      Stable_Fingerprint_Value   : Natural := 0;
   end record;

end Editor.Ada_RM_Completion_Closure_Consumer_Remediation_Worklist_Legality;
