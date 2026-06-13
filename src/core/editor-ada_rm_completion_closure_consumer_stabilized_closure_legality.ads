with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_RM_Completion_Closure_Consumer_Stabilization_Gate_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Closure_Legality is

   --  Pass1280 stabilized closure for direct RM-completion closure consumers.
   --
   --  This package consumes Pass1279 stabilization-gate rows and turns stable
   --  direct-consumer results into first-class semantic closure evidence.  Rows
   --  promoted by the gate become accepted closure evidence; stable withheld
   --  rows become explicit closure blockers with their original prerequisite
   --  family preserved; changed rows remain recheck-required and are not allowed
   --  to enter the trusted closure boundary.

   package Gate renames Editor.Ada_RM_Completion_Closure_Consumer_Stabilization_Gate_Legality;

   subtype RM_Closure_Consumer_Stabilization_Status is Gate.RM_Closure_Consumer_Stabilization_Gate_Status;
   subtype RM_Closure_Consumer_Stabilization_Action is Gate.RM_Closure_Consumer_Stabilization_Gate_Action;
   subtype RM_Closure_Consumer_Closure_Family is Gate.RM_Closure_Consumer_Stabilization_Family;

   type RM_Closure_Consumer_Stabilized_Closure_Id is new Natural;
   No_RM_Closure_Consumer_Stabilized_Closure : constant RM_Closure_Consumer_Stabilized_Closure_Id := 0;

   type RM_Closure_Consumer_Stabilized_Closure_Status is
     (RM_Closure_Consumer_Stabilized_Closure_Not_Checked,
      RM_Closure_Consumer_Stabilized_Closure_Accepted_Current,
      RM_Closure_Consumer_Stabilized_Closure_Accepted_Not_Required,
      RM_Closure_Consumer_Stabilized_Closure_Blocker_Stale_Or_Fingerprint,
      RM_Closure_Consumer_Stabilized_Closure_Blocker_AST_Or_Coverage,
      RM_Closure_Consumer_Stabilized_Closure_Blocker_Cross_Unit,
      RM_Closure_Consumer_Stabilized_Closure_Blocker_Generic_Substitution,
      RM_Closure_Consumer_Stabilized_Closure_Blocker_Dataflow,
      RM_Closure_Consumer_Stabilized_Closure_Blocker_Volatile_Atomic,
      RM_Closure_Consumer_Stabilized_Closure_Blocker_Overload_Type,
      RM_Closure_Consumer_Stabilized_Closure_Blocker_Representation,
      RM_Closure_Consumer_Stabilized_Closure_Blocker_Tasking_Protected,
      RM_Closure_Consumer_Stabilized_Closure_Blocker_Elaboration,
      RM_Closure_Consumer_Stabilized_Closure_Blocker_Accessibility,
      RM_Closure_Consumer_Stabilized_Closure_Blocker_Discriminant_Variant,
      RM_Closure_Consumer_Stabilized_Closure_Blocker_Exception_Finalization,
      RM_Closure_Consumer_Stabilized_Closure_Blocker_Renaming_Alias,
      RM_Closure_Consumer_Stabilized_Closure_Blocker_Predicate_Invariant,
      RM_Closure_Consumer_Stabilized_Closure_Blocker_Source_Fingerprint,
      RM_Closure_Consumer_Stabilized_Closure_Blocker_Substitution_Fingerprint,
      RM_Closure_Consumer_Stabilized_Closure_Blocker_Multiple_Prerequisites,
      RM_Closure_Consumer_Stabilized_Closure_Indeterminate,
      RM_Closure_Consumer_Stabilized_Closure_Recheck_Required);

   type RM_Closure_Consumer_Stabilized_Closure_Action is
     (RM_Closure_Consumer_Stabilized_Closure_Action_None,
      RM_Closure_Consumer_Stabilized_Closure_Action_Accept_Current,
      RM_Closure_Consumer_Stabilized_Closure_Action_Accept_Not_Required,
      RM_Closure_Consumer_Stabilized_Closure_Action_Block_Fingerprint,
      RM_Closure_Consumer_Stabilized_Closure_Action_Block_AST,
      RM_Closure_Consumer_Stabilized_Closure_Action_Block_Cross_Unit,
      RM_Closure_Consumer_Stabilized_Closure_Action_Block_Generic_Substitution,
      RM_Closure_Consumer_Stabilized_Closure_Action_Block_Dataflow,
      RM_Closure_Consumer_Stabilized_Closure_Action_Block_Effects,
      RM_Closure_Consumer_Stabilized_Closure_Action_Block_Type,
      RM_Closure_Consumer_Stabilized_Closure_Action_Block_Representation,
      RM_Closure_Consumer_Stabilized_Closure_Action_Block_Tasking,
      RM_Closure_Consumer_Stabilized_Closure_Action_Block_Elaboration,
      RM_Closure_Consumer_Stabilized_Closure_Action_Block_Accessibility,
      RM_Closure_Consumer_Stabilized_Closure_Action_Block_Discriminant,
      RM_Closure_Consumer_Stabilized_Closure_Action_Block_Exception,
      RM_Closure_Consumer_Stabilized_Closure_Action_Block_Renaming,
      RM_Closure_Consumer_Stabilized_Closure_Action_Block_Predicate,
      RM_Closure_Consumer_Stabilized_Closure_Action_Block_Source_Fingerprint,
      RM_Closure_Consumer_Stabilized_Closure_Action_Block_Substitution_Fingerprint,
      RM_Closure_Consumer_Stabilized_Closure_Action_Split_Prerequisites,
      RM_Closure_Consumer_Stabilized_Closure_Action_Degrade,
      RM_Closure_Consumer_Stabilized_Closure_Action_Recheck);

   type RM_Closure_Consumer_Stabilized_Closure_Row is record
      Id                        : RM_Closure_Consumer_Stabilized_Closure_Id := No_RM_Closure_Consumer_Stabilized_Closure;
      Stabilization_Id          : Gate.RM_Closure_Consumer_Stabilization_Gate_Id := Gate.No_RM_Closure_Consumer_Stabilization_Gate;
      Convergence_Id            : Gate.Conv.RM_Closure_Consumer_Convergence_Id := Gate.Conv.No_RM_Closure_Consumer_Convergence;
      Application_Id            : Gate.Conv.Apply.RM_Closure_Consumer_Application_Id := Gate.Conv.Apply.No_RM_Closure_Consumer_Application;
      Eligibility_Id            : Gate.Conv.Apply.Recheck.RM_Closure_Consumer_Recheck_Id := Gate.Conv.Apply.Recheck.No_RM_Closure_Consumer_Recheck;
      Worklist_Item             : Gate.Conv.Apply.Recheck.Worklist.RM_Closure_Consumer_Worklist_Id := Gate.Conv.Apply.Recheck.Worklist.No_RM_Closure_Consumer_Worklist_Item;
      Diagnostic_Row            : Gate.Conv.Apply.Recheck.Worklist.Diagnostics.RM_Closure_Consumer_Diagnostic_Id := Gate.Conv.Apply.Recheck.Worklist.Diagnostics.No_RM_Closure_Consumer_Diagnostic;
      Stabilization_Status      : RM_Closure_Consumer_Stabilization_Status := Gate.RM_Closure_Consumer_Stabilization_Gate_Not_Checked;
      Stabilization_Action      : RM_Closure_Consumer_Stabilization_Action := Gate.RM_Closure_Consumer_Stabilization_Gate_Action_None;
      Status                    : RM_Closure_Consumer_Stabilized_Closure_Status := RM_Closure_Consumer_Stabilized_Closure_Not_Checked;
      Action                    : RM_Closure_Consumer_Stabilized_Closure_Action := RM_Closure_Consumer_Stabilized_Closure_Action_None;
      Family                    : RM_Closure_Consumer_Closure_Family := Gate.Conv.Apply.Recheck.Worklist.Diagnostics.RM_Closure_Consumer_Diagnostic_Unknown;
      Node                      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Accepted                  : Boolean := False;
      Current                   : Boolean := False;
      Blocked                   : Boolean := False;
      Stable                    : Boolean := False;
      Recheck_Required          : Boolean := False;
      Blocks_Downstream         : Boolean := False;
      Priority_Rank             : Natural := 0;
      Source_Fingerprint        : Natural := 0;
      Substitution_Fingerprint  : Natural := 0;
      Semantic_Fingerprint      : Natural := 0;
      Diagnostic_Fingerprint    : Natural := 0;
      Worklist_Fingerprint      : Natural := 0;
      Eligibility_Fingerprint   : Natural := 0;
      Application_Fingerprint   : Natural := 0;
      Convergence_Fingerprint   : Natural := 0;
      Stabilization_Fingerprint : Natural := 0;
      Closure_Fingerprint       : Natural := 0;
      Start_Line                : Positive := 1;
      Start_Column              : Positive := 1;
      End_Line                  : Positive := 1;
      End_Column                : Positive := 1;
      Message                   : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type RM_Closure_Consumer_Stabilized_Closure_Model is private;
   type RM_Closure_Consumer_Stabilized_Closure_Set is private;

   procedure Clear (Model : in out RM_Closure_Consumer_Stabilized_Closure_Model);

   function Build
     (Gates : Gate.RM_Closure_Consumer_Stabilization_Gate_Model)
      return RM_Closure_Consumer_Stabilized_Closure_Model;

   function Count (Model : RM_Closure_Consumer_Stabilized_Closure_Model) return Natural;
   function Row_Count (Model : RM_Closure_Consumer_Stabilized_Closure_Model) return Natural renames Count;
   function Row_At
     (Model : RM_Closure_Consumer_Stabilized_Closure_Model;
      Index : Positive) return RM_Closure_Consumer_Stabilized_Closure_Row;

   function Query_Count (Set : RM_Closure_Consumer_Stabilized_Closure_Set) return Natural;
   function Query_At
     (Set   : RM_Closure_Consumer_Stabilized_Closure_Set;
      Index : Positive) return RM_Closure_Consumer_Stabilized_Closure_Row;

   function Query_Status
     (Model  : RM_Closure_Consumer_Stabilized_Closure_Model;
      Status : RM_Closure_Consumer_Stabilized_Closure_Status) return RM_Closure_Consumer_Stabilized_Closure_Set;
   function Query_Action
     (Model  : RM_Closure_Consumer_Stabilized_Closure_Model;
      Action : RM_Closure_Consumer_Stabilized_Closure_Action) return RM_Closure_Consumer_Stabilized_Closure_Set;
   function Query_Family
     (Model  : RM_Closure_Consumer_Stabilized_Closure_Model;
      Family : RM_Closure_Consumer_Closure_Family) return RM_Closure_Consumer_Stabilized_Closure_Set;
   function Find_By_Node
     (Model : RM_Closure_Consumer_Stabilized_Closure_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return RM_Closure_Consumer_Stabilized_Closure_Set;
   function Find_By_Source_Fingerprint
     (Model       : RM_Closure_Consumer_Stabilized_Closure_Model;
      Fingerprint : Natural) return RM_Closure_Consumer_Stabilized_Closure_Set;
   function Find_By_Substitution_Fingerprint
     (Model       : RM_Closure_Consumer_Stabilized_Closure_Model;
      Fingerprint : Natural) return RM_Closure_Consumer_Stabilized_Closure_Set;

   function Count_By_Status
     (Model  : RM_Closure_Consumer_Stabilized_Closure_Model;
      Status : RM_Closure_Consumer_Stabilized_Closure_Status) return Natural;
   function Count_By_Family
     (Model  : RM_Closure_Consumer_Stabilized_Closure_Model;
      Family : RM_Closure_Consumer_Closure_Family) return Natural;
   function Accepted_Count (Model : RM_Closure_Consumer_Stabilized_Closure_Model) return Natural;
   function Blocked_Count (Model : RM_Closure_Consumer_Stabilized_Closure_Model) return Natural;
   function Current_Count (Model : RM_Closure_Consumer_Stabilized_Closure_Model) return Natural;
   function Recheck_Required_Count (Model : RM_Closure_Consumer_Stabilized_Closure_Model) return Natural;
   function Indeterminate_Count (Model : RM_Closure_Consumer_Stabilized_Closure_Model) return Natural;
   function Stable_Fingerprint (Model : RM_Closure_Consumer_Stabilized_Closure_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => RM_Closure_Consumer_Stabilized_Closure_Row);

   type RM_Closure_Consumer_Stabilized_Closure_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type RM_Closure_Consumer_Stabilized_Closure_Model is record
      Rows                : Row_Vectors.Vector;
      Accepted_Total      : Natural := 0;
      Blocked_Total       : Natural := 0;
      Current_Total       : Natural := 0;
      Recheck_Total       : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

end Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Closure_Legality;
