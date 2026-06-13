with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Application_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Convergence_Legality is

   --  Pass1261 generic/shared-state RM-completion recheck convergence legality.
   --
   --  This package consumes Pass1260 generic/shared-state RM-completion recheck
   --  application rows and classifies whether the combined generic/shared-state
   --  final chain has converged as current evidence, converged as not required,
   --  stayed stably withheld by its preserved prerequisite blocker, stayed
   --  indeterminate, or changed relative to a caller supplied prior application
   --  fingerprint.  The convergence result prevents repeated rechecks from
   --  cycling on unchanged generic replay, abstract/refined state,
   --  volatile/atomic/shared-state, overload/type, representation/freezing,
   --  tasking/protected, elaboration, accessibility, discriminant/variant,
   --  exception/finalization, renaming/alias, predicate/invariant, dataflow,
   --  cross-unit, and AST/coverage evidence.

   package Apply renames Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Application_Legality;

   subtype RM_Completion_Application_Status is Apply.RM_Completion_Application_Status;
   subtype RM_Completion_Application_Action is Apply.RM_Completion_Application_Action;
   subtype RM_Completion_Convergence_Family is Apply.RM_Completion_Application_Family;

   type RM_Completion_Convergence_Id is new Natural;
   No_RM_Completion_Convergence : constant RM_Completion_Convergence_Id := 0;

   type RM_Completion_Convergence_Status is
     (RM_Completion_Convergence_Not_Checked,
      RM_Completion_Converged_Current,
      RM_Completion_Converged_Not_Required,
      RM_Completion_Stable_Withheld_Stale_Or_Fingerprint,
      RM_Completion_Stable_Withheld_AST_Or_Coverage,
      RM_Completion_Stable_Withheld_Cross_Unit,
      RM_Completion_Stable_Withheld_Generic_Substitution,
      RM_Completion_Stable_Withheld_Prior_Dataflow,
      RM_Completion_Stable_Withheld_Volatile_Atomic,
      RM_Completion_Stable_Withheld_Overload_Type,
      RM_Completion_Stable_Withheld_Representation,
      RM_Completion_Stable_Withheld_Tasking_Protected,
      RM_Completion_Stable_Withheld_Elaboration,
      RM_Completion_Stable_Withheld_Accessibility,
      RM_Completion_Stable_Withheld_Discriminant_Variant,
      RM_Completion_Stable_Withheld_Exception_Finalization,
      RM_Completion_Stable_Withheld_Renaming_Alias,
      RM_Completion_Stable_Withheld_Predicate_Invariant,
      RM_Completion_Stable_Withheld_Dataflow,
      RM_Completion_Stable_Multiple_Prerequisites,
      RM_Completion_Stable_Indeterminate,
      RM_Completion_Changed_Since_Previous);

   type RM_Completion_Convergence_Action is
     (RM_Completion_Convergence_Action_None,
      RM_Completion_Convergence_Action_Accept_Current,
      RM_Completion_Convergence_Action_Skip_Not_Required,
      RM_Completion_Convergence_Action_Retain_Stable_Withheld,
      RM_Completion_Convergence_Action_Retain_Stable_Fingerprint_Blocker,
      RM_Completion_Convergence_Action_Retain_Stable_AST_Blocker,
      RM_Completion_Convergence_Action_Retain_Stable_Cross_Unit_Blocker,
      RM_Completion_Convergence_Action_Retain_Stable_Generic_Substitution_Blocker,
      RM_Completion_Convergence_Action_Retain_Stable_Prior_Dataflow_Blocker,
      RM_Completion_Convergence_Action_Retain_Stable_Effect_Blocker,
      RM_Completion_Convergence_Action_Retain_Stable_Type_Blocker,
      RM_Completion_Convergence_Action_Retain_Stable_Representation_Blocker,
      RM_Completion_Convergence_Action_Retain_Stable_Tasking_Blocker,
      RM_Completion_Convergence_Action_Retain_Stable_Elaboration_Blocker,
      RM_Completion_Convergence_Action_Retain_Stable_Accessibility_Blocker,
      RM_Completion_Convergence_Action_Retain_Stable_Discriminant_Blocker,
      RM_Completion_Convergence_Action_Retain_Stable_Exception_Blocker,
      RM_Completion_Convergence_Action_Retain_Stable_Renaming_Blocker,
      RM_Completion_Convergence_Action_Retain_Stable_Predicate_Blocker,
      RM_Completion_Convergence_Action_Retain_Stable_Dataflow_Blocker,
      RM_Completion_Convergence_Action_Split_Prerequisites,
      RM_Completion_Convergence_Action_Degrade,
      RM_Completion_Convergence_Action_Recheck_Again);

   type RM_Completion_Convergence_Row is record
      Id                         : RM_Completion_Convergence_Id := No_RM_Completion_Convergence;
      Application_Id             : Apply.RM_Completion_Application_Id := Apply.No_RM_Completion_Application;
      Eligibility_Id             : Apply.Recheck.RM_Completion_Recheck_Id := Apply.Recheck.No_RM_Completion_Recheck;
      Worklist_Item              : Apply.Recheck.Worklist.RM_Completion_Worklist_Id := Apply.Recheck.Worklist.No_RM_Completion_Worklist_Item;
      Diagnostic_Row             : Apply.Recheck.Worklist.Diagnostics.RM_Completion_Diagnostic_Id := Apply.Recheck.Worklist.Diagnostics.No_RM_Completion_Diagnostic;
      Application_Status         : RM_Completion_Application_Status := Apply.RM_Completion_Application_Not_Checked;
      Application_Action         : RM_Completion_Application_Action := Apply.RM_Completion_Application_Action_None;
      Status                     : RM_Completion_Convergence_Status := RM_Completion_Convergence_Not_Checked;
      Action                     : RM_Completion_Convergence_Action := RM_Completion_Convergence_Action_None;
      Family                     : RM_Completion_Convergence_Family := Apply.Recheck.Worklist.Diagnostics.RM_Completion_Diagnostic_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Component_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Operation_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Current                    : Boolean := False;
      Stable                     : Boolean := False;
      Withheld                   : Boolean := False;
      Changed                    : Boolean := False;
      Blocks_Downstream          : Boolean := False;
      Priority_Rank              : Natural := 0;
      Source_Fingerprint         : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
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

   type RM_Completion_Convergence_Model is private;
   type RM_Completion_Convergence_Set is private;

   procedure Clear (Model : in out RM_Completion_Convergence_Model);

   function Build
     (Applications               : Apply.RM_Completion_Application_Model;
      Previous_Model_Fingerprint : Natural := 0)
      return RM_Completion_Convergence_Model;

   function Count (Model : RM_Completion_Convergence_Model) return Natural;
   function Row_Count (Model : RM_Completion_Convergence_Model) return Natural renames Count;
   function Row_At
     (Model : RM_Completion_Convergence_Model;
      Index : Positive) return RM_Completion_Convergence_Row;

   function Query_Count (Set : RM_Completion_Convergence_Set) return Natural;
   function Query_At
     (Set   : RM_Completion_Convergence_Set;
      Index : Positive) return RM_Completion_Convergence_Row;

   function Query_Status
     (Model  : RM_Completion_Convergence_Model;
      Status : RM_Completion_Convergence_Status) return RM_Completion_Convergence_Set;
   function Query_Action
     (Model  : RM_Completion_Convergence_Model;
      Action : RM_Completion_Convergence_Action) return RM_Completion_Convergence_Set;
   function Query_Family
     (Model  : RM_Completion_Convergence_Model;
      Family : RM_Completion_Convergence_Family) return RM_Completion_Convergence_Set;
   function Find_By_Node
     (Model : RM_Completion_Convergence_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return RM_Completion_Convergence_Set;
   function Find_By_Source_Fingerprint
     (Model       : RM_Completion_Convergence_Model;
      Fingerprint : Natural) return RM_Completion_Convergence_Set;
   function Find_By_Substitution_Fingerprint
     (Model       : RM_Completion_Convergence_Model;
      Fingerprint : Natural) return RM_Completion_Convergence_Set;

   function Count_By_Status
     (Model  : RM_Completion_Convergence_Model;
      Status : RM_Completion_Convergence_Status) return Natural;
   function Count_By_Family
     (Model  : RM_Completion_Convergence_Model;
      Family : RM_Completion_Convergence_Family) return Natural;

   function Converged_Count (Model : RM_Completion_Convergence_Model) return Natural;
   function Stable_Withheld_Count (Model : RM_Completion_Convergence_Model) return Natural;
   function Current_Count (Model : RM_Completion_Convergence_Model) return Natural;
   function Changed_Count (Model : RM_Completion_Convergence_Model) return Natural;
   function Indeterminate_Count (Model : RM_Completion_Convergence_Model) return Natural;
   function Stable_Fingerprint (Model : RM_Completion_Convergence_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => RM_Completion_Convergence_Row);

   type RM_Completion_Convergence_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type RM_Completion_Convergence_Model is record
      Rows                  : Row_Vectors.Vector;
      Converged_Total       : Natural := 0;
      Stable_Withheld_Total : Natural := 0;
      Current_Total         : Natural := 0;
      Changed_Total         : Natural := 0;
      Indeterminate_Total   : Natural := 0;
      Fingerprint           : Natural := 0;
   end record;

end Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Convergence_Legality;
