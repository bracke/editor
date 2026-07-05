with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Application_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Convergence_Legality is

   --  Case 1278 convergence for the direct RM-completion closure consumer
   --  recheck chain.
   --
   --  This package consumes Case 1276 application rows and classifies whether
   --  each direct RM-completion closure consumer result has converged as
   --  current evidence, converged as not-required non-diagnostic evidence,
   --  stayed stably withheld by the same prerequisite blocker, preserved a
   --  real semantic blocking state, remained indeterminate, or changed relative
   --  to a caller supplied prior application fingerprint.  The convergence
   --  row preserves the original direct-consumer blocker family for cross-unit,
   --  elaboration, accessibility/lifetime, exception/finalization,
   --  overload/type, representation/freezing, tasking/protected,
   --  dataflow/initialization, predicate/invariant, AST/coverage, generic
   --  substitution, source/substitution fingerprints, multiple prerequisites,
   --  and indeterminate closure state.

   package Apply renames Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Application_Legality;

   subtype RM_Closure_Consumer_Application_Status is Apply.RM_Closure_Consumer_Application_Status;
   subtype RM_Closure_Consumer_Application_Action is Apply.RM_Closure_Consumer_Application_Action;
   subtype RM_Closure_Consumer_Convergence_Family is Apply.RM_Closure_Consumer_Application_Family;

   type RM_Closure_Consumer_Convergence_Id is new Natural;
   No_RM_Closure_Consumer_Convergence : constant RM_Closure_Consumer_Convergence_Id := 0;

   type RM_Closure_Consumer_Convergence_Status is
     (RM_Closure_Consumer_Convergence_Not_Checked,
      RM_Closure_Consumer_Converged_Current,
      RM_Closure_Consumer_Converged_Not_Required,
      RM_Closure_Consumer_Stable_Withheld_Stale_Or_Fingerprint,
      RM_Closure_Consumer_Stable_Withheld_AST_Or_Coverage,
      RM_Closure_Consumer_Stable_Withheld_Cross_Unit,
      RM_Closure_Consumer_Stable_Withheld_Generic_Substitution,
      RM_Closure_Consumer_Stable_Withheld_Dataflow,
      RM_Closure_Consumer_Stable_Withheld_Volatile_Atomic,
      RM_Closure_Consumer_Stable_Withheld_Overload_Type,
      RM_Closure_Consumer_Stable_Withheld_Representation,
      RM_Closure_Consumer_Stable_Withheld_Tasking_Protected,
      RM_Closure_Consumer_Stable_Withheld_Elaboration,
      RM_Closure_Consumer_Stable_Withheld_Accessibility,
      RM_Closure_Consumer_Stable_Withheld_Discriminant_Variant,
      RM_Closure_Consumer_Stable_Withheld_Exception_Finalization,
      RM_Closure_Consumer_Stable_Withheld_Renaming_Alias,
      RM_Closure_Consumer_Stable_Withheld_Predicate_Invariant,
      RM_Closure_Consumer_Stable_Withheld_Source_Fingerprint,
      RM_Closure_Consumer_Stable_Withheld_Substitution_Fingerprint,
      RM_Closure_Consumer_Stable_Multiple_Prerequisites,
      RM_Closure_Consumer_Stable_Indeterminate,
      RM_Closure_Consumer_Changed_Since_Previous);

   type RM_Closure_Consumer_Convergence_Action is
     (RM_Closure_Consumer_Convergence_Action_None,
      RM_Closure_Consumer_Convergence_Action_Accept_Current,
      RM_Closure_Consumer_Convergence_Action_Skip_Not_Required,
      RM_Closure_Consumer_Convergence_Action_Retain_Stable_Withheld,
      RM_Closure_Consumer_Convergence_Action_Retain_Stable_Fingerprint_Blocker,
      RM_Closure_Consumer_Convergence_Action_Retain_Stable_AST_Blocker,
      RM_Closure_Consumer_Convergence_Action_Retain_Stable_Cross_Unit_Blocker,
      RM_Closure_Consumer_Convergence_Action_Retain_Stable_Generic_Substitution_Blocker,
      RM_Closure_Consumer_Convergence_Action_Retain_Stable_Dataflow_Blocker,
      RM_Closure_Consumer_Convergence_Action_Retain_Stable_Effect_Blocker,
      RM_Closure_Consumer_Convergence_Action_Retain_Stable_Type_Blocker,
      RM_Closure_Consumer_Convergence_Action_Retain_Stable_Representation_Blocker,
      RM_Closure_Consumer_Convergence_Action_Retain_Stable_Tasking_Blocker,
      RM_Closure_Consumer_Convergence_Action_Retain_Stable_Elaboration_Blocker,
      RM_Closure_Consumer_Convergence_Action_Retain_Stable_Accessibility_Blocker,
      RM_Closure_Consumer_Convergence_Action_Retain_Stable_Discriminant_Blocker,
      RM_Closure_Consumer_Convergence_Action_Retain_Stable_Exception_Blocker,
      RM_Closure_Consumer_Convergence_Action_Retain_Stable_Renaming_Blocker,
      RM_Closure_Consumer_Convergence_Action_Retain_Stable_Predicate_Blocker,
      RM_Closure_Consumer_Convergence_Action_Retain_Stable_Source_Fingerprint_Blocker,
      RM_Closure_Consumer_Convergence_Action_Retain_Stable_Substitution_Fingerprint_Blocker,
      RM_Closure_Consumer_Convergence_Action_Split_Prerequisites,
      RM_Closure_Consumer_Convergence_Action_Degrade,
      RM_Closure_Consumer_Convergence_Action_Recheck_Again);

   type RM_Closure_Consumer_Convergence_Row is record
      Id                         : RM_Closure_Consumer_Convergence_Id := No_RM_Closure_Consumer_Convergence;
      Application_Id             : Apply.RM_Closure_Consumer_Application_Id := Apply.No_RM_Closure_Consumer_Application;
      Eligibility_Id             : Apply.Recheck.RM_Closure_Consumer_Recheck_Id := Apply.Recheck.No_RM_Closure_Consumer_Recheck;
      Worklist_Item              : Apply.Recheck.Worklist.RM_Closure_Consumer_Worklist_Id := Apply.Recheck.Worklist.No_RM_Closure_Consumer_Worklist_Item;
      Diagnostic_Row             : Apply.Recheck.Worklist.Diagnostics.RM_Closure_Consumer_Diagnostic_Id := Apply.Recheck.Worklist.Diagnostics.No_RM_Closure_Consumer_Diagnostic;
      Application_Status         : RM_Closure_Consumer_Application_Status := Apply.RM_Closure_Consumer_Application_Not_Checked;
      Application_Action         : RM_Closure_Consumer_Application_Action := Apply.RM_Closure_Consumer_Application_Action_None;
      Status                     : RM_Closure_Consumer_Convergence_Status := RM_Closure_Consumer_Convergence_Not_Checked;
      Action                     : RM_Closure_Consumer_Convergence_Action := RM_Closure_Consumer_Convergence_Action_None;
      Family                     : RM_Closure_Consumer_Convergence_Family := Apply.Recheck.Worklist.Diagnostics.RM_Closure_Consumer_Diagnostic_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Current                    : Boolean := False;
      Stable                     : Boolean := False;
      Withheld                   : Boolean := False;
      Changed                    : Boolean := False;
      Blocks_Downstream          : Boolean := False;
      Priority_Rank              : Natural := 0;
      Source_Fingerprint         : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Semantic_Fingerprint       : Natural := 0;
      Diagnostic_Fingerprint     : Natural := 0;
      Worklist_Fingerprint       : Natural := 0;
      Eligibility_Fingerprint    : Natural := 0;
      Application_Fingerprint    : Natural := 0;
      Previous_Model_Fingerprint : Natural := 0;
      Current_Model_Fingerprint  : Natural := 0;
      Convergence_Fingerprint    : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type RM_Closure_Consumer_Convergence_Model is private;
   type RM_Closure_Consumer_Convergence_Set is private;

   procedure Clear (Model : in out RM_Closure_Consumer_Convergence_Model);

   function Build
     (Applications               : Apply.RM_Closure_Consumer_Application_Model;
      Previous_Model_Fingerprint : Natural := 0)
      return RM_Closure_Consumer_Convergence_Model;

   function Count (Model : RM_Closure_Consumer_Convergence_Model) return Natural;
   function Row_Count (Model : RM_Closure_Consumer_Convergence_Model) return Natural renames Count;
   function Row_At
     (Model : RM_Closure_Consumer_Convergence_Model;
      Index : Positive) return RM_Closure_Consumer_Convergence_Row;

   function Query_Count (Set : RM_Closure_Consumer_Convergence_Set) return Natural;
   function Query_At
     (Set   : RM_Closure_Consumer_Convergence_Set;
      Index : Positive) return RM_Closure_Consumer_Convergence_Row;

   function Query_Status
     (Model  : RM_Closure_Consumer_Convergence_Model;
      Status : RM_Closure_Consumer_Convergence_Status) return RM_Closure_Consumer_Convergence_Set;
   function Query_Action
     (Model  : RM_Closure_Consumer_Convergence_Model;
      Action : RM_Closure_Consumer_Convergence_Action) return RM_Closure_Consumer_Convergence_Set;
   function Query_Family
     (Model  : RM_Closure_Consumer_Convergence_Model;
      Family : RM_Closure_Consumer_Convergence_Family) return RM_Closure_Consumer_Convergence_Set;
   function Find_By_Node
     (Model : RM_Closure_Consumer_Convergence_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return RM_Closure_Consumer_Convergence_Set;
   function Find_By_Source_Fingerprint
     (Model       : RM_Closure_Consumer_Convergence_Model;
      Fingerprint : Natural) return RM_Closure_Consumer_Convergence_Set;
   function Find_By_Substitution_Fingerprint
     (Model       : RM_Closure_Consumer_Convergence_Model;
      Fingerprint : Natural) return RM_Closure_Consumer_Convergence_Set;

   function Count_By_Status
     (Model  : RM_Closure_Consumer_Convergence_Model;
      Status : RM_Closure_Consumer_Convergence_Status) return Natural;
   function Count_By_Family
     (Model  : RM_Closure_Consumer_Convergence_Model;
      Family : RM_Closure_Consumer_Convergence_Family) return Natural;

   function Converged_Count (Model : RM_Closure_Consumer_Convergence_Model) return Natural;
   function Stable_Withheld_Count (Model : RM_Closure_Consumer_Convergence_Model) return Natural;
   function Current_Count (Model : RM_Closure_Consumer_Convergence_Model) return Natural;
   function Changed_Count (Model : RM_Closure_Consumer_Convergence_Model) return Natural;
   function Indeterminate_Count (Model : RM_Closure_Consumer_Convergence_Model) return Natural;
   function Stable_Fingerprint (Model : RM_Closure_Consumer_Convergence_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => RM_Closure_Consumer_Convergence_Row);

   type RM_Closure_Consumer_Convergence_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type RM_Closure_Consumer_Convergence_Model is record
      Rows                  : Row_Vectors.Vector;
      Converged_Total       : Natural := 0;
      Stable_Withheld_Total : Natural := 0;
      Current_Total         : Natural := 0;
      Changed_Total         : Natural := 0;
      Indeterminate_Total   : Natural := 0;
      Fingerprint           : Natural := 0;
   end record;

end Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Convergence_Legality;
