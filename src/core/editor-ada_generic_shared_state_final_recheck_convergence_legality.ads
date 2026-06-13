with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Generic_Shared_State_Final_Recheck_Application_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Generic_Shared_State_Final_Recheck_Convergence_Legality is

   --  Pass1243 generic/shared-state final recheck convergence legality.
   --
   --  This package consumes Pass1242 generic/shared-state final recheck
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

   package Apply renames Editor.Ada_Generic_Shared_State_Final_Recheck_Application_Legality;

   subtype Generic_Shared_State_Final_Application_Status is Apply.Generic_Shared_State_Final_Application_Status;
   subtype Generic_Shared_State_Final_Application_Action is Apply.Generic_Shared_State_Final_Application_Action;
   subtype Generic_Shared_State_Final_Convergence_Family is Apply.Generic_Shared_State_Final_Application_Family;

   type Generic_Shared_State_Final_Convergence_Id is new Natural;
   No_Generic_Shared_State_Final_Convergence : constant Generic_Shared_State_Final_Convergence_Id := 0;

   type Generic_Shared_State_Final_Convergence_Status is
     (Generic_Shared_State_Final_Convergence_Not_Checked,
      Generic_Shared_State_Final_Converged_Current,
      Generic_Shared_State_Final_Converged_Not_Required,
      Generic_Shared_State_Final_Stable_Withheld_Stale_Or_Fingerprint,
      Generic_Shared_State_Final_Stable_Withheld_AST_Or_Coverage,
      Generic_Shared_State_Final_Stable_Withheld_Cross_Unit,
      Generic_Shared_State_Final_Stable_Withheld_Generic_Replay,
      Generic_Shared_State_Final_Stable_Withheld_Abstract_Or_Shared_State,
      Generic_Shared_State_Final_Stable_Withheld_Volatile_Atomic,
      Generic_Shared_State_Final_Stable_Withheld_Overload_Type,
      Generic_Shared_State_Final_Stable_Withheld_Representation,
      Generic_Shared_State_Final_Stable_Withheld_Tasking_Protected,
      Generic_Shared_State_Final_Stable_Withheld_Elaboration,
      Generic_Shared_State_Final_Stable_Withheld_Accessibility,
      Generic_Shared_State_Final_Stable_Withheld_Discriminant_Variant,
      Generic_Shared_State_Final_Stable_Withheld_Exception_Finalization,
      Generic_Shared_State_Final_Stable_Withheld_Renaming_Alias,
      Generic_Shared_State_Final_Stable_Withheld_Predicate_Invariant,
      Generic_Shared_State_Final_Stable_Withheld_Dataflow,
      Generic_Shared_State_Final_Stable_Multiple_Prerequisites,
      Generic_Shared_State_Final_Stable_Indeterminate,
      Generic_Shared_State_Final_Changed_Since_Previous);

   type Generic_Shared_State_Final_Convergence_Action is
     (Generic_Shared_State_Final_Convergence_Action_None,
      Generic_Shared_State_Final_Convergence_Action_Accept_Current,
      Generic_Shared_State_Final_Convergence_Action_Skip_Not_Required,
      Generic_Shared_State_Final_Convergence_Action_Retain_Stable_Withheld,
      Generic_Shared_State_Final_Convergence_Action_Retain_Stable_Fingerprint_Blocker,
      Generic_Shared_State_Final_Convergence_Action_Retain_Stable_AST_Blocker,
      Generic_Shared_State_Final_Convergence_Action_Retain_Stable_Cross_Unit_Blocker,
      Generic_Shared_State_Final_Convergence_Action_Retain_Stable_Generic_Blocker,
      Generic_Shared_State_Final_Convergence_Action_Retain_Stable_Shared_State_Blocker,
      Generic_Shared_State_Final_Convergence_Action_Retain_Stable_Effect_Blocker,
      Generic_Shared_State_Final_Convergence_Action_Retain_Stable_Type_Blocker,
      Generic_Shared_State_Final_Convergence_Action_Retain_Stable_Representation_Blocker,
      Generic_Shared_State_Final_Convergence_Action_Retain_Stable_Tasking_Blocker,
      Generic_Shared_State_Final_Convergence_Action_Retain_Stable_Elaboration_Blocker,
      Generic_Shared_State_Final_Convergence_Action_Retain_Stable_Accessibility_Blocker,
      Generic_Shared_State_Final_Convergence_Action_Retain_Stable_Discriminant_Blocker,
      Generic_Shared_State_Final_Convergence_Action_Retain_Stable_Exception_Blocker,
      Generic_Shared_State_Final_Convergence_Action_Retain_Stable_Renaming_Blocker,
      Generic_Shared_State_Final_Convergence_Action_Retain_Stable_Predicate_Blocker,
      Generic_Shared_State_Final_Convergence_Action_Retain_Stable_Dataflow_Blocker,
      Generic_Shared_State_Final_Convergence_Action_Split_Prerequisites,
      Generic_Shared_State_Final_Convergence_Action_Degrade,
      Generic_Shared_State_Final_Convergence_Action_Recheck_Again);

   type Generic_Shared_State_Final_Convergence_Row is record
      Id                         : Generic_Shared_State_Final_Convergence_Id := No_Generic_Shared_State_Final_Convergence;
      Application_Id             : Apply.Generic_Shared_State_Final_Application_Id := Apply.No_Generic_Shared_State_Final_Application;
      Eligibility_Id             : Apply.Recheck.Generic_Shared_State_Final_Recheck_Id := Apply.Recheck.No_Generic_Shared_State_Final_Recheck;
      Worklist_Item              : Apply.Recheck.Worklist.Generic_Shared_State_Final_Worklist_Id := Apply.Recheck.Worklist.No_Generic_Shared_State_Final_Worklist_Item;
      Diagnostic_Row             : Apply.Recheck.Worklist.Diagnostics.Generic_Shared_State_Final_Diagnostic_Id := Apply.Recheck.Worklist.Diagnostics.No_Generic_Shared_State_Final_Diagnostic;
      Application_Status         : Generic_Shared_State_Final_Application_Status := Apply.Generic_Shared_State_Final_Application_Not_Checked;
      Application_Action         : Generic_Shared_State_Final_Application_Action := Apply.Generic_Shared_State_Final_Application_Action_None;
      Status                     : Generic_Shared_State_Final_Convergence_Status := Generic_Shared_State_Final_Convergence_Not_Checked;
      Action                     : Generic_Shared_State_Final_Convergence_Action := Generic_Shared_State_Final_Convergence_Action_None;
      Family                     : Generic_Shared_State_Final_Convergence_Family := Apply.Recheck.Worklist.Diagnostics.Generic_Shared_State_Final_Diagnostic_Unknown;
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

   type Generic_Shared_State_Final_Convergence_Model is private;
   type Generic_Shared_State_Final_Convergence_Set is private;

   procedure Clear (Model : in out Generic_Shared_State_Final_Convergence_Model);

   function Build
     (Applications               : Apply.Generic_Shared_State_Final_Application_Model;
      Previous_Model_Fingerprint : Natural := 0)
      return Generic_Shared_State_Final_Convergence_Model;

   function Count (Model : Generic_Shared_State_Final_Convergence_Model) return Natural;
   function Row_Count (Model : Generic_Shared_State_Final_Convergence_Model) return Natural renames Count;
   function Row_At
     (Model : Generic_Shared_State_Final_Convergence_Model;
      Index : Positive) return Generic_Shared_State_Final_Convergence_Row;

   function Query_Count (Set : Generic_Shared_State_Final_Convergence_Set) return Natural;
   function Query_At
     (Set   : Generic_Shared_State_Final_Convergence_Set;
      Index : Positive) return Generic_Shared_State_Final_Convergence_Row;

   function Query_Status
     (Model  : Generic_Shared_State_Final_Convergence_Model;
      Status : Generic_Shared_State_Final_Convergence_Status) return Generic_Shared_State_Final_Convergence_Set;
   function Query_Action
     (Model  : Generic_Shared_State_Final_Convergence_Model;
      Action : Generic_Shared_State_Final_Convergence_Action) return Generic_Shared_State_Final_Convergence_Set;
   function Query_Family
     (Model  : Generic_Shared_State_Final_Convergence_Model;
      Family : Generic_Shared_State_Final_Convergence_Family) return Generic_Shared_State_Final_Convergence_Set;
   function Find_By_Node
     (Model : Generic_Shared_State_Final_Convergence_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Generic_Shared_State_Final_Convergence_Set;
   function Find_By_Source_Fingerprint
     (Model       : Generic_Shared_State_Final_Convergence_Model;
      Fingerprint : Natural) return Generic_Shared_State_Final_Convergence_Set;
   function Find_By_Substitution_Fingerprint
     (Model       : Generic_Shared_State_Final_Convergence_Model;
      Fingerprint : Natural) return Generic_Shared_State_Final_Convergence_Set;

   function Count_By_Status
     (Model  : Generic_Shared_State_Final_Convergence_Model;
      Status : Generic_Shared_State_Final_Convergence_Status) return Natural;
   function Count_By_Family
     (Model  : Generic_Shared_State_Final_Convergence_Model;
      Family : Generic_Shared_State_Final_Convergence_Family) return Natural;

   function Converged_Count (Model : Generic_Shared_State_Final_Convergence_Model) return Natural;
   function Stable_Withheld_Count (Model : Generic_Shared_State_Final_Convergence_Model) return Natural;
   function Current_Count (Model : Generic_Shared_State_Final_Convergence_Model) return Natural;
   function Changed_Count (Model : Generic_Shared_State_Final_Convergence_Model) return Natural;
   function Indeterminate_Count (Model : Generic_Shared_State_Final_Convergence_Model) return Natural;
   function Stable_Fingerprint (Model : Generic_Shared_State_Final_Convergence_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Generic_Shared_State_Final_Convergence_Row);

   type Generic_Shared_State_Final_Convergence_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Generic_Shared_State_Final_Convergence_Model is record
      Rows                  : Row_Vectors.Vector;
      Converged_Total       : Natural := 0;
      Stable_Withheld_Total : Natural := 0;
      Current_Total         : Natural := 0;
      Changed_Total         : Natural := 0;
      Indeterminate_Total   : Natural := 0;
      Fingerprint           : Natural := 0;
   end record;

end Editor.Ada_Generic_Shared_State_Final_Recheck_Convergence_Legality;
