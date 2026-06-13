with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Remaining_RM_Edge_Recheck_Application_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Remaining_RM_Edge_Recheck_Convergence_Legality is

   --  Pass1289 convergence for remaining Ada RM edge rechecks.
   --
   --  This package consumes Pass1288 remaining-edge recheck application rows
   --  and classifies whether each remaining RM edge result has converged as
   --  current evidence, converged as not-required non-diagnostic evidence,
   --  stayed stably withheld by the same prerequisite blocker, remained
   --  indeterminate, or changed relative to a caller supplied prior
   --  application fingerprint.  The original blocker family is preserved for
   --  remaining-edge hard cases, stabilized-closure blockers, source and
   --  substitution fingerprint blockers, multiple prerequisites, explicit
   --  recheck gates, and indeterminate states.

   package Apply renames Editor.Ada_Remaining_RM_Edge_Recheck_Application_Legality;
   package Diagnostics renames Apply.Diagnostics;
   package Edge renames Apply.Edge;

   subtype Remaining_RM_Edge_Convergence_Application_Status is Apply.Remaining_RM_Edge_Application_Status;
   subtype Remaining_RM_Edge_Convergence_Application_Action is Apply.Remaining_RM_Edge_Application_Action;
   subtype Remaining_RM_Edge_Convergence_Family is Apply.Remaining_RM_Edge_Application_Diagnostic_Family;
   subtype Remaining_RM_Edge_Kind is Apply.Remaining_RM_Edge_Kind;
   subtype Remaining_RM_Edge_Blocker_Family is Apply.Remaining_RM_Edge_Blocker_Family;

   type Remaining_RM_Edge_Convergence_Id is new Natural;
   No_Remaining_RM_Edge_Convergence : constant Remaining_RM_Edge_Convergence_Id := 0;

   type Remaining_RM_Edge_Convergence_Status is
     (Remaining_RM_Edge_Convergence_Not_Checked,
      Remaining_RM_Edge_Converged_Current,
      Remaining_RM_Edge_Converged_Not_Required,
      Remaining_RM_Edge_Stable_Withheld_Remaining_Edge,
      Remaining_RM_Edge_Stable_Withheld_Stabilized_Closure,
      Remaining_RM_Edge_Stable_Withheld_Source_Fingerprint,
      Remaining_RM_Edge_Stable_Withheld_Substitution_Fingerprint,
      Remaining_RM_Edge_Stable_Multiple_Prerequisites,
      Remaining_RM_Edge_Stable_Recheck_Required,
      Remaining_RM_Edge_Stable_Indeterminate,
      Remaining_RM_Edge_Changed_Since_Previous);

   type Remaining_RM_Edge_Convergence_Action is
     (Remaining_RM_Edge_Convergence_Action_None,
      Remaining_RM_Edge_Convergence_Action_Accept_Current,
      Remaining_RM_Edge_Convergence_Action_Skip_Not_Required,
      Remaining_RM_Edge_Convergence_Action_Retain_Remaining_Edge_Blocker,
      Remaining_RM_Edge_Convergence_Action_Retain_Stabilized_Closure_Blocker,
      Remaining_RM_Edge_Convergence_Action_Retain_Source_Fingerprint_Blocker,
      Remaining_RM_Edge_Convergence_Action_Retain_Substitution_Fingerprint_Blocker,
      Remaining_RM_Edge_Convergence_Action_Split_Prerequisites,
      Remaining_RM_Edge_Convergence_Action_Wait_For_Recheck_Gate,
      Remaining_RM_Edge_Convergence_Action_Degrade,
      Remaining_RM_Edge_Convergence_Action_Recheck_Again);

   type Remaining_RM_Edge_Convergence_Row is record
      Id                         : Remaining_RM_Edge_Convergence_Id := No_Remaining_RM_Edge_Convergence;
      Application_Id             : Apply.Remaining_RM_Edge_Application_Id := Apply.No_Remaining_RM_Edge_Application;
      Eligibility_Id             : Apply.Recheck.Remaining_RM_Edge_Recheck_Id := Apply.Recheck.No_Remaining_RM_Edge_Recheck;
      Worklist_Item              : Apply.Recheck.Worklist.Remaining_RM_Edge_Worklist_Id := Apply.Recheck.Worklist.No_Remaining_RM_Edge_Worklist_Item;
      Diagnostic_Row             : Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Id := Diagnostics.No_Remaining_RM_Edge_Stabilized_Diagnostic;
      Application_Status         : Remaining_RM_Edge_Convergence_Application_Status := Apply.Remaining_RM_Edge_Application_Not_Checked;
      Application_Action         : Remaining_RM_Edge_Convergence_Application_Action := Apply.Remaining_RM_Edge_Application_Action_None;
      Status                     : Remaining_RM_Edge_Convergence_Status := Remaining_RM_Edge_Convergence_Not_Checked;
      Action                     : Remaining_RM_Edge_Convergence_Action := Remaining_RM_Edge_Convergence_Action_None;
      Family                     : Remaining_RM_Edge_Convergence_Family := Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Unknown;
      Remaining_Edge_Kind        : Remaining_RM_Edge_Kind := Edge.Remaining_RM_Edge_Unknown;
      Remaining_Edge_Blocker     : Remaining_RM_Edge_Blocker_Family := Edge.Remaining_RM_Edge_Blocker_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Current                    : Boolean := False;
      Stable                     : Boolean := False;
      Withheld                   : Boolean := False;
      Changed                    : Boolean := False;
      Blocks_Downstream          : Boolean := False;
      Priority_Rank              : Natural := 0;
      Source_Fingerprint         : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Edge_Fingerprint           : Natural := 0;
      Closure_Fingerprint        : Natural := 0;
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

   type Remaining_RM_Edge_Convergence_Model is private;
   type Remaining_RM_Edge_Convergence_Set is private;

   procedure Clear (Model : in out Remaining_RM_Edge_Convergence_Model);

   function Build
     (Applications               : Apply.Remaining_RM_Edge_Application_Model;
      Previous_Model_Fingerprint : Natural := 0)
      return Remaining_RM_Edge_Convergence_Model;

   function Count (Model : Remaining_RM_Edge_Convergence_Model) return Natural;
   function Row_Count (Model : Remaining_RM_Edge_Convergence_Model) return Natural renames Count;
   function Row_At
     (Model : Remaining_RM_Edge_Convergence_Model;
      Index : Positive) return Remaining_RM_Edge_Convergence_Row;

   function Query_Count (Set : Remaining_RM_Edge_Convergence_Set) return Natural;
   function Query_At
     (Set   : Remaining_RM_Edge_Convergence_Set;
      Index : Positive) return Remaining_RM_Edge_Convergence_Row;

   function Query_Status
     (Model  : Remaining_RM_Edge_Convergence_Model;
      Status : Remaining_RM_Edge_Convergence_Status) return Remaining_RM_Edge_Convergence_Set;
   function Query_Action
     (Model  : Remaining_RM_Edge_Convergence_Model;
      Action : Remaining_RM_Edge_Convergence_Action) return Remaining_RM_Edge_Convergence_Set;
   function Query_Family
     (Model  : Remaining_RM_Edge_Convergence_Model;
      Family : Remaining_RM_Edge_Convergence_Family) return Remaining_RM_Edge_Convergence_Set;
   function Query_Node
     (Model : Remaining_RM_Edge_Convergence_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Remaining_RM_Edge_Convergence_Set;
   function Query_Source_Fingerprint
     (Model       : Remaining_RM_Edge_Convergence_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Convergence_Set;
   function Query_Substitution_Fingerprint
     (Model       : Remaining_RM_Edge_Convergence_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Convergence_Set;

   function Count_Status
     (Model  : Remaining_RM_Edge_Convergence_Model;
      Status : Remaining_RM_Edge_Convergence_Status) return Natural;
   function Count_Action
     (Model  : Remaining_RM_Edge_Convergence_Model;
      Action : Remaining_RM_Edge_Convergence_Action) return Natural;
   function Count_Family
     (Model  : Remaining_RM_Edge_Convergence_Model;
      Family : Remaining_RM_Edge_Convergence_Family) return Natural;

   function Converged_Count (Model : Remaining_RM_Edge_Convergence_Model) return Natural;
   function Stable_Withheld_Count (Model : Remaining_RM_Edge_Convergence_Model) return Natural;
   function Current_Count (Model : Remaining_RM_Edge_Convergence_Model) return Natural;
   function Changed_Count (Model : Remaining_RM_Edge_Convergence_Model) return Natural;
   function Indeterminate_Count (Model : Remaining_RM_Edge_Convergence_Model) return Natural;
   function Stable_Fingerprint (Model : Remaining_RM_Edge_Convergence_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Remaining_RM_Edge_Convergence_Row);

   type Remaining_RM_Edge_Convergence_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Remaining_RM_Edge_Convergence_Model is record
      Rows                  : Row_Vectors.Vector;
      Converged_Total       : Natural := 0;
      Stable_Withheld_Total : Natural := 0;
      Current_Total         : Natural := 0;
      Changed_Total         : Natural := 0;
      Indeterminate_Total   : Natural := 0;
      Fingerprint           : Natural := 0;
   end record;

end Editor.Ada_Remaining_RM_Edge_Recheck_Convergence_Legality;
