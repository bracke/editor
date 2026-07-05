with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Generic_Shared_State_Final_Recheck_Convergence_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Generic_Shared_State_Final_Stabilization_Gate_Legality is

   --  Case 1244 generic/shared-state final stabilization gate legality.
   --
   --  This package consumes Case 1243 generic/shared-state final recheck
   --  convergence rows and decides whether the combined generic/shared-state
   --  final semantic chain may cross the stable closure/feed boundary.
   --  Promotion is allowed only for stable current/not-required convergence
   --  rows.  Stable prerequisite blockers retain their original semantic
   --  family, changed rows require another bounded recheck, and indeterminate
   --  rows remain degraded instead of becoming confident legality evidence.

   package Conv renames Editor.Ada_Generic_Shared_State_Final_Recheck_Convergence_Legality;

   subtype Generic_Shared_State_Final_Convergence_Status is Conv.Generic_Shared_State_Final_Convergence_Status;
   subtype Generic_Shared_State_Final_Convergence_Action is Conv.Generic_Shared_State_Final_Convergence_Action;
   subtype Generic_Shared_State_Final_Stabilization_Family is Conv.Generic_Shared_State_Final_Convergence_Family;

   type Generic_Shared_State_Final_Stabilization_Gate_Id is new Natural;
   No_Generic_Shared_State_Final_Stabilization_Gate : constant Generic_Shared_State_Final_Stabilization_Gate_Id := 0;

   type Generic_Shared_State_Final_Stabilization_Gate_Status is
     (Generic_Shared_State_Final_Stabilization_Gate_Not_Checked,
      Generic_Shared_State_Final_Stabilization_Gate_Promoted_Current,
      Generic_Shared_State_Final_Stabilization_Gate_Promoted_Not_Required,
      Generic_Shared_State_Final_Stabilization_Gate_Withheld_Stale_Or_Fingerprint,
      Generic_Shared_State_Final_Stabilization_Gate_Withheld_AST_Or_Coverage,
      Generic_Shared_State_Final_Stabilization_Gate_Withheld_Cross_Unit,
      Generic_Shared_State_Final_Stabilization_Gate_Withheld_Generic_Replay,
      Generic_Shared_State_Final_Stabilization_Gate_Withheld_Abstract_Or_Shared_State,
      Generic_Shared_State_Final_Stabilization_Gate_Withheld_Volatile_Atomic,
      Generic_Shared_State_Final_Stabilization_Gate_Withheld_Overload_Type,
      Generic_Shared_State_Final_Stabilization_Gate_Withheld_Representation,
      Generic_Shared_State_Final_Stabilization_Gate_Withheld_Tasking_Protected,
      Generic_Shared_State_Final_Stabilization_Gate_Withheld_Elaboration,
      Generic_Shared_State_Final_Stabilization_Gate_Withheld_Accessibility,
      Generic_Shared_State_Final_Stabilization_Gate_Withheld_Discriminant_Variant,
      Generic_Shared_State_Final_Stabilization_Gate_Withheld_Exception_Finalization,
      Generic_Shared_State_Final_Stabilization_Gate_Withheld_Renaming_Alias,
      Generic_Shared_State_Final_Stabilization_Gate_Withheld_Predicate_Invariant,
      Generic_Shared_State_Final_Stabilization_Gate_Withheld_Dataflow,
      Generic_Shared_State_Final_Stabilization_Gate_Withheld_Multiple_Prerequisites,
      Generic_Shared_State_Final_Stabilization_Gate_Degraded_Indeterminate,
      Generic_Shared_State_Final_Stabilization_Gate_Recheck_Required);

   type Generic_Shared_State_Final_Stabilization_Gate_Action is
     (Generic_Shared_State_Final_Stabilization_Gate_Action_None,
      Generic_Shared_State_Final_Stabilization_Gate_Action_Promote_Current,
      Generic_Shared_State_Final_Stabilization_Gate_Action_Promote_Not_Required,
      Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_Fingerprint_Blocker,
      Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_AST_Blocker,
      Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_Cross_Unit_Blocker,
      Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_Generic_Blocker,
      Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_Shared_State_Blocker,
      Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_Effect_Blocker,
      Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_Type_Blocker,
      Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_Representation_Blocker,
      Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_Tasking_Blocker,
      Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_Elaboration_Blocker,
      Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_Accessibility_Blocker,
      Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_Discriminant_Blocker,
      Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_Exception_Blocker,
      Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_Renaming_Blocker,
      Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_Predicate_Blocker,
      Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_Dataflow_Blocker,
      Generic_Shared_State_Final_Stabilization_Gate_Action_Split_Prerequisites,
      Generic_Shared_State_Final_Stabilization_Gate_Action_Degrade,
      Generic_Shared_State_Final_Stabilization_Gate_Action_Recheck);

   type Generic_Shared_State_Final_Stabilization_Gate_Row is record
      Id                         : Generic_Shared_State_Final_Stabilization_Gate_Id := No_Generic_Shared_State_Final_Stabilization_Gate;
      Convergence_Id             : Conv.Generic_Shared_State_Final_Convergence_Id := Conv.No_Generic_Shared_State_Final_Convergence;
      Application_Id             : Conv.Apply.Generic_Shared_State_Final_Application_Id := Conv.Apply.No_Generic_Shared_State_Final_Application;
      Eligibility_Id             : Conv.Apply.Recheck.Generic_Shared_State_Final_Recheck_Id := Conv.Apply.Recheck.No_Generic_Shared_State_Final_Recheck;
      Worklist_Item              : Conv.Apply.Recheck.Worklist.Generic_Shared_State_Final_Worklist_Id := Conv.Apply.Recheck.Worklist.No_Generic_Shared_State_Final_Worklist_Item;
      Diagnostic_Row             : Conv.Apply.Recheck.Worklist.Diagnostics.Generic_Shared_State_Final_Diagnostic_Id := Conv.Apply.Recheck.Worklist.Diagnostics.No_Generic_Shared_State_Final_Diagnostic;
      Convergence_Status         : Generic_Shared_State_Final_Convergence_Status := Conv.Generic_Shared_State_Final_Convergence_Not_Checked;
      Convergence_Action         : Generic_Shared_State_Final_Convergence_Action := Conv.Generic_Shared_State_Final_Convergence_Action_None;
      Status                     : Generic_Shared_State_Final_Stabilization_Gate_Status := Generic_Shared_State_Final_Stabilization_Gate_Not_Checked;
      Action                     : Generic_Shared_State_Final_Stabilization_Gate_Action := Generic_Shared_State_Final_Stabilization_Gate_Action_None;
      Family                     : Generic_Shared_State_Final_Stabilization_Family := Conv.Apply.Recheck.Worklist.Diagnostics.Generic_Shared_State_Final_Diagnostic_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Component_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Operation_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Promoted                   : Boolean := False;
      Current                    : Boolean := False;
      Withheld                   : Boolean := False;
      Stable                     : Boolean := False;
      Recheck_Required           : Boolean := False;
      Blocks_Downstream          : Boolean := False;
      Priority_Rank              : Natural := 0;
      Source_Fingerprint         : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Worklist_Fingerprint       : Natural := 0;
      Eligibility_Fingerprint    : Natural := 0;
      Application_Fingerprint    : Natural := 0;
      Convergence_Fingerprint    : Natural := 0;
      Stabilization_Fingerprint  : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Generic_Shared_State_Final_Stabilization_Gate_Model is private;
   type Generic_Shared_State_Final_Stabilization_Gate_Set is private;

   procedure Clear (Model : in out Generic_Shared_State_Final_Stabilization_Gate_Model);

   function Build
     (Convergence : Conv.Generic_Shared_State_Final_Convergence_Model)
      return Generic_Shared_State_Final_Stabilization_Gate_Model;

   function Count (Model : Generic_Shared_State_Final_Stabilization_Gate_Model) return Natural;
   function Row_Count (Model : Generic_Shared_State_Final_Stabilization_Gate_Model) return Natural renames Count;
   function Row_At
     (Model : Generic_Shared_State_Final_Stabilization_Gate_Model;
      Index : Positive) return Generic_Shared_State_Final_Stabilization_Gate_Row;

   function Query_Count (Set : Generic_Shared_State_Final_Stabilization_Gate_Set) return Natural;
   function Query_At
     (Set   : Generic_Shared_State_Final_Stabilization_Gate_Set;
      Index : Positive) return Generic_Shared_State_Final_Stabilization_Gate_Row;

   function Query_Status
     (Model  : Generic_Shared_State_Final_Stabilization_Gate_Model;
      Status : Generic_Shared_State_Final_Stabilization_Gate_Status) return Generic_Shared_State_Final_Stabilization_Gate_Set;
   function Query_Action
     (Model  : Generic_Shared_State_Final_Stabilization_Gate_Model;
      Action : Generic_Shared_State_Final_Stabilization_Gate_Action) return Generic_Shared_State_Final_Stabilization_Gate_Set;
   function Query_Family
     (Model  : Generic_Shared_State_Final_Stabilization_Gate_Model;
      Family : Generic_Shared_State_Final_Stabilization_Family) return Generic_Shared_State_Final_Stabilization_Gate_Set;
   function Find_By_Node
     (Model : Generic_Shared_State_Final_Stabilization_Gate_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Generic_Shared_State_Final_Stabilization_Gate_Set;
   function Find_By_Source_Fingerprint
     (Model       : Generic_Shared_State_Final_Stabilization_Gate_Model;
      Fingerprint : Natural) return Generic_Shared_State_Final_Stabilization_Gate_Set;
   function Find_By_Substitution_Fingerprint
     (Model       : Generic_Shared_State_Final_Stabilization_Gate_Model;
      Fingerprint : Natural) return Generic_Shared_State_Final_Stabilization_Gate_Set;

   function Count_By_Status
     (Model  : Generic_Shared_State_Final_Stabilization_Gate_Model;
      Status : Generic_Shared_State_Final_Stabilization_Gate_Status) return Natural;
   function Count_By_Family
     (Model  : Generic_Shared_State_Final_Stabilization_Gate_Model;
      Family : Generic_Shared_State_Final_Stabilization_Family) return Natural;

   function Promoted_Count (Model : Generic_Shared_State_Final_Stabilization_Gate_Model) return Natural;
   function Withheld_Count (Model : Generic_Shared_State_Final_Stabilization_Gate_Model) return Natural;
   function Current_Count (Model : Generic_Shared_State_Final_Stabilization_Gate_Model) return Natural;
   function Recheck_Required_Count (Model : Generic_Shared_State_Final_Stabilization_Gate_Model) return Natural;
   function Indeterminate_Count (Model : Generic_Shared_State_Final_Stabilization_Gate_Model) return Natural;
   function Stable_Fingerprint (Model : Generic_Shared_State_Final_Stabilization_Gate_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Generic_Shared_State_Final_Stabilization_Gate_Row);

   type Generic_Shared_State_Final_Stabilization_Gate_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Generic_Shared_State_Final_Stabilization_Gate_Model is record
      Rows                : Row_Vectors.Vector;
      Promoted_Total      : Natural := 0;
      Withheld_Total      : Natural := 0;
      Current_Total       : Natural := 0;
      Recheck_Total       : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

end Editor.Ada_Generic_Shared_State_Final_Stabilization_Gate_Legality;
