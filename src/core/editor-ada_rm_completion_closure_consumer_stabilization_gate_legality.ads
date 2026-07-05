with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Convergence_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_RM_Completion_Closure_Consumer_Stabilization_Gate_Legality is

   --  Case 1279 stabilization gate for direct RM-completion closure consumers.
   --
   --  This package consumes Case 1278 convergence rows and decides whether
   --  direct RM-completion closure consumer evidence may cross the stable
   --  closure/feed boundary.  Stable current and stable not-required rows are
   --  promoted as semantic evidence; stable withheld rows retain their exact
   --  blocker family; changed rows require another bounded recheck; and
   --  indeterminate rows remain degraded instead of becoming confident Ada RM
   --  legality evidence.

   package Conv renames Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Convergence_Legality;

   subtype RM_Closure_Consumer_Convergence_Status is Conv.RM_Closure_Consumer_Convergence_Status;
   subtype RM_Closure_Consumer_Convergence_Action is Conv.RM_Closure_Consumer_Convergence_Action;
   subtype RM_Closure_Consumer_Stabilization_Family is Conv.RM_Closure_Consumer_Convergence_Family;

   type RM_Closure_Consumer_Stabilization_Gate_Id is new Natural;
   No_RM_Closure_Consumer_Stabilization_Gate : constant RM_Closure_Consumer_Stabilization_Gate_Id := 0;

   type RM_Closure_Consumer_Stabilization_Gate_Status is
     (RM_Closure_Consumer_Stabilization_Gate_Not_Checked,
      RM_Closure_Consumer_Stabilization_Gate_Promoted_Current,
      RM_Closure_Consumer_Stabilization_Gate_Promoted_Not_Required,
      RM_Closure_Consumer_Stabilization_Gate_Withheld_Stale_Or_Fingerprint,
      RM_Closure_Consumer_Stabilization_Gate_Withheld_AST_Or_Coverage,
      RM_Closure_Consumer_Stabilization_Gate_Withheld_Cross_Unit,
      RM_Closure_Consumer_Stabilization_Gate_Withheld_Generic_Substitution,
      RM_Closure_Consumer_Stabilization_Gate_Withheld_Dataflow,
      RM_Closure_Consumer_Stabilization_Gate_Withheld_Volatile_Atomic,
      RM_Closure_Consumer_Stabilization_Gate_Withheld_Overload_Type,
      RM_Closure_Consumer_Stabilization_Gate_Withheld_Representation,
      RM_Closure_Consumer_Stabilization_Gate_Withheld_Tasking_Protected,
      RM_Closure_Consumer_Stabilization_Gate_Withheld_Elaboration,
      RM_Closure_Consumer_Stabilization_Gate_Withheld_Accessibility,
      RM_Closure_Consumer_Stabilization_Gate_Withheld_Discriminant_Variant,
      RM_Closure_Consumer_Stabilization_Gate_Withheld_Exception_Finalization,
      RM_Closure_Consumer_Stabilization_Gate_Withheld_Renaming_Alias,
      RM_Closure_Consumer_Stabilization_Gate_Withheld_Predicate_Invariant,
      RM_Closure_Consumer_Stabilization_Gate_Withheld_Source_Fingerprint,
      RM_Closure_Consumer_Stabilization_Gate_Withheld_Substitution_Fingerprint,
      RM_Closure_Consumer_Stabilization_Gate_Withheld_Multiple_Prerequisites,
      RM_Closure_Consumer_Stabilization_Gate_Degraded_Indeterminate,
      RM_Closure_Consumer_Stabilization_Gate_Recheck_Required);

   type RM_Closure_Consumer_Stabilization_Gate_Action is
     (RM_Closure_Consumer_Stabilization_Gate_Action_None,
      RM_Closure_Consumer_Stabilization_Gate_Action_Promote_Current,
      RM_Closure_Consumer_Stabilization_Gate_Action_Promote_Not_Required,
      RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Fingerprint_Blocker,
      RM_Closure_Consumer_Stabilization_Gate_Action_Retain_AST_Blocker,
      RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Cross_Unit_Blocker,
      RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Generic_Substitution_Blocker,
      RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Dataflow_Blocker,
      RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Effect_Blocker,
      RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Type_Blocker,
      RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Representation_Blocker,
      RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Tasking_Blocker,
      RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Elaboration_Blocker,
      RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Accessibility_Blocker,
      RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Discriminant_Blocker,
      RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Exception_Blocker,
      RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Renaming_Blocker,
      RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Predicate_Blocker,
      RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Source_Fingerprint_Blocker,
      RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Substitution_Fingerprint_Blocker,
      RM_Closure_Consumer_Stabilization_Gate_Action_Split_Prerequisites,
      RM_Closure_Consumer_Stabilization_Gate_Action_Degrade,
      RM_Closure_Consumer_Stabilization_Gate_Action_Recheck);

   type RM_Closure_Consumer_Stabilization_Gate_Row is record
      Id                        : RM_Closure_Consumer_Stabilization_Gate_Id := No_RM_Closure_Consumer_Stabilization_Gate;
      Convergence_Id            : Conv.RM_Closure_Consumer_Convergence_Id := Conv.No_RM_Closure_Consumer_Convergence;
      Application_Id            : Conv.Apply.RM_Closure_Consumer_Application_Id := Conv.Apply.No_RM_Closure_Consumer_Application;
      Eligibility_Id            : Conv.Apply.Recheck.RM_Closure_Consumer_Recheck_Id := Conv.Apply.Recheck.No_RM_Closure_Consumer_Recheck;
      Worklist_Item             : Conv.Apply.Recheck.Worklist.RM_Closure_Consumer_Worklist_Id := Conv.Apply.Recheck.Worklist.No_RM_Closure_Consumer_Worklist_Item;
      Diagnostic_Row            : Conv.Apply.Recheck.Worklist.Diagnostics.RM_Closure_Consumer_Diagnostic_Id := Conv.Apply.Recheck.Worklist.Diagnostics.No_RM_Closure_Consumer_Diagnostic;
      Convergence_Status        : RM_Closure_Consumer_Convergence_Status := Conv.RM_Closure_Consumer_Convergence_Not_Checked;
      Convergence_Action        : RM_Closure_Consumer_Convergence_Action := Conv.RM_Closure_Consumer_Convergence_Action_None;
      Status                    : RM_Closure_Consumer_Stabilization_Gate_Status := RM_Closure_Consumer_Stabilization_Gate_Not_Checked;
      Action                    : RM_Closure_Consumer_Stabilization_Gate_Action := RM_Closure_Consumer_Stabilization_Gate_Action_None;
      Family                    : RM_Closure_Consumer_Stabilization_Family := Conv.Apply.Recheck.Worklist.Diagnostics.RM_Closure_Consumer_Diagnostic_Unknown;
      Node                      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Promoted                  : Boolean := False;
      Current                   : Boolean := False;
      Withheld                  : Boolean := False;
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
      Start_Line                : Positive := 1;
      Start_Column              : Positive := 1;
      End_Line                  : Positive := 1;
      End_Column                : Positive := 1;
      Message                   : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type RM_Closure_Consumer_Stabilization_Gate_Model is private;
   type RM_Closure_Consumer_Stabilization_Gate_Set is private;

   procedure Clear (Model : in out RM_Closure_Consumer_Stabilization_Gate_Model);

   function Build
     (Convergence : Conv.RM_Closure_Consumer_Convergence_Model)
      return RM_Closure_Consumer_Stabilization_Gate_Model;

   function Count (Model : RM_Closure_Consumer_Stabilization_Gate_Model) return Natural;
   function Row_Count (Model : RM_Closure_Consumer_Stabilization_Gate_Model) return Natural renames Count;
   function Row_At
     (Model : RM_Closure_Consumer_Stabilization_Gate_Model;
      Index : Positive) return RM_Closure_Consumer_Stabilization_Gate_Row;

   function Query_Count (Set : RM_Closure_Consumer_Stabilization_Gate_Set) return Natural;
   function Query_At
     (Set   : RM_Closure_Consumer_Stabilization_Gate_Set;
      Index : Positive) return RM_Closure_Consumer_Stabilization_Gate_Row;

   function Query_Status
     (Model  : RM_Closure_Consumer_Stabilization_Gate_Model;
      Status : RM_Closure_Consumer_Stabilization_Gate_Status) return RM_Closure_Consumer_Stabilization_Gate_Set;
   function Query_Action
     (Model  : RM_Closure_Consumer_Stabilization_Gate_Model;
      Action : RM_Closure_Consumer_Stabilization_Gate_Action) return RM_Closure_Consumer_Stabilization_Gate_Set;
   function Query_Family
     (Model  : RM_Closure_Consumer_Stabilization_Gate_Model;
      Family : RM_Closure_Consumer_Stabilization_Family) return RM_Closure_Consumer_Stabilization_Gate_Set;
   function Find_By_Node
     (Model : RM_Closure_Consumer_Stabilization_Gate_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return RM_Closure_Consumer_Stabilization_Gate_Set;
   function Find_By_Source_Fingerprint
     (Model       : RM_Closure_Consumer_Stabilization_Gate_Model;
      Fingerprint : Natural) return RM_Closure_Consumer_Stabilization_Gate_Set;
   function Find_By_Substitution_Fingerprint
     (Model       : RM_Closure_Consumer_Stabilization_Gate_Model;
      Fingerprint : Natural) return RM_Closure_Consumer_Stabilization_Gate_Set;

   function Count_By_Status
     (Model  : RM_Closure_Consumer_Stabilization_Gate_Model;
      Status : RM_Closure_Consumer_Stabilization_Gate_Status) return Natural;
   function Count_By_Family
     (Model  : RM_Closure_Consumer_Stabilization_Gate_Model;
      Family : RM_Closure_Consumer_Stabilization_Family) return Natural;

   function Promoted_Count (Model : RM_Closure_Consumer_Stabilization_Gate_Model) return Natural;
   function Withheld_Count (Model : RM_Closure_Consumer_Stabilization_Gate_Model) return Natural;
   function Current_Count (Model : RM_Closure_Consumer_Stabilization_Gate_Model) return Natural;
   function Recheck_Required_Count (Model : RM_Closure_Consumer_Stabilization_Gate_Model) return Natural;
   function Indeterminate_Count (Model : RM_Closure_Consumer_Stabilization_Gate_Model) return Natural;
   function Stable_Fingerprint (Model : RM_Closure_Consumer_Stabilization_Gate_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => RM_Closure_Consumer_Stabilization_Gate_Row);

   type RM_Closure_Consumer_Stabilization_Gate_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type RM_Closure_Consumer_Stabilization_Gate_Model is record
      Rows                : Row_Vectors.Vector;
      Promoted_Total      : Natural := 0;
      Withheld_Total      : Natural := 0;
      Current_Total       : Natural := 0;
      Recheck_Total       : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

end Editor.Ada_RM_Completion_Closure_Consumer_Stabilization_Gate_Legality;
