with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Remaining_RM_Edge_Stabilization_Gate_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Legality is

   --  Pass1291 stabilized closure for remaining Ada RM edge evidence.
   --
   --  This package consumes Pass1290 remaining RM edge stabilization-gate rows
   --  and turns stable remaining-edge results into first-class semantic closure
   --  evidence.  Stable promoted rows become accepted closure evidence; stable
   --  withheld rows become explicit closure blockers with their original blocker
   --  family preserved; changed or recheck-required rows stay outside trusted
   --  downstream closure.

   package Gate renames Editor.Ada_Remaining_RM_Edge_Stabilization_Gate_Legality;
   package Diagnostics renames Gate.Diagnostics;
   package Edge renames Gate.Edge;

   subtype Remaining_RM_Edge_Stabilized_Closure_Stabilization_Status is Gate.Remaining_RM_Edge_Stabilization_Gate_Status;
   subtype Remaining_RM_Edge_Stabilized_Closure_Stabilization_Action is Gate.Remaining_RM_Edge_Stabilization_Gate_Action;
   subtype Remaining_RM_Edge_Stabilized_Closure_Family is Gate.Remaining_RM_Edge_Stabilization_Family;
   subtype Remaining_RM_Edge_Kind is Gate.Remaining_RM_Edge_Kind;
   subtype Remaining_RM_Edge_Blocker_Family is Gate.Remaining_RM_Edge_Blocker_Family;

   type Remaining_RM_Edge_Stabilized_Closure_Id is new Natural;
   No_Remaining_RM_Edge_Stabilized_Closure : constant Remaining_RM_Edge_Stabilized_Closure_Id := 0;

   type Remaining_RM_Edge_Stabilized_Closure_Status is
     (Remaining_RM_Edge_Stabilized_Closure_Not_Checked,
      Remaining_RM_Edge_Stabilized_Closure_Accepted_Current,
      Remaining_RM_Edge_Stabilized_Closure_Accepted_Not_Required,
      Remaining_RM_Edge_Stabilized_Closure_Blocker_Remaining_Edge,
      Remaining_RM_Edge_Stabilized_Closure_Blocker_Stabilized_Closure,
      Remaining_RM_Edge_Stabilized_Closure_Blocker_Source_Fingerprint,
      Remaining_RM_Edge_Stabilized_Closure_Blocker_Substitution_Fingerprint,
      Remaining_RM_Edge_Stabilized_Closure_Blocker_Multiple_Prerequisites,
      Remaining_RM_Edge_Stabilized_Closure_Indeterminate,
      Remaining_RM_Edge_Stabilized_Closure_Recheck_Required);

   type Remaining_RM_Edge_Stabilized_Closure_Action is
     (Remaining_RM_Edge_Stabilized_Closure_Action_None,
      Remaining_RM_Edge_Stabilized_Closure_Action_Accept_Current,
      Remaining_RM_Edge_Stabilized_Closure_Action_Accept_Not_Required,
      Remaining_RM_Edge_Stabilized_Closure_Action_Block_Remaining_Edge,
      Remaining_RM_Edge_Stabilized_Closure_Action_Block_Stabilized_Closure,
      Remaining_RM_Edge_Stabilized_Closure_Action_Block_Source_Fingerprint,
      Remaining_RM_Edge_Stabilized_Closure_Action_Block_Substitution_Fingerprint,
      Remaining_RM_Edge_Stabilized_Closure_Action_Split_Prerequisites,
      Remaining_RM_Edge_Stabilized_Closure_Action_Degrade,
      Remaining_RM_Edge_Stabilized_Closure_Action_Recheck);

   type Remaining_RM_Edge_Stabilized_Closure_Row is record
      Id                        : Remaining_RM_Edge_Stabilized_Closure_Id := No_Remaining_RM_Edge_Stabilized_Closure;
      Stabilization_Id          : Gate.Remaining_RM_Edge_Stabilization_Gate_Id := Gate.No_Remaining_RM_Edge_Stabilization_Gate;
      Convergence_Id            : Gate.Conv.Remaining_RM_Edge_Convergence_Id := Gate.Conv.No_Remaining_RM_Edge_Convergence;
      Application_Id            : Gate.Conv.Apply.Remaining_RM_Edge_Application_Id := Gate.Conv.Apply.No_Remaining_RM_Edge_Application;
      Eligibility_Id            : Gate.Conv.Apply.Recheck.Remaining_RM_Edge_Recheck_Id := Gate.Conv.Apply.Recheck.No_Remaining_RM_Edge_Recheck;
      Worklist_Item             : Gate.Conv.Apply.Recheck.Worklist.Remaining_RM_Edge_Worklist_Id := Gate.Conv.Apply.Recheck.Worklist.No_Remaining_RM_Edge_Worklist_Item;
      Diagnostic_Row            : Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Id := Diagnostics.No_Remaining_RM_Edge_Stabilized_Diagnostic;
      Stabilization_Status      : Remaining_RM_Edge_Stabilized_Closure_Stabilization_Status := Gate.Remaining_RM_Edge_Stabilization_Gate_Not_Checked;
      Stabilization_Action      : Remaining_RM_Edge_Stabilized_Closure_Stabilization_Action := Gate.Remaining_RM_Edge_Stabilization_Gate_Action_None;
      Status                    : Remaining_RM_Edge_Stabilized_Closure_Status := Remaining_RM_Edge_Stabilized_Closure_Not_Checked;
      Action                    : Remaining_RM_Edge_Stabilized_Closure_Action := Remaining_RM_Edge_Stabilized_Closure_Action_None;
      Family                    : Remaining_RM_Edge_Stabilized_Closure_Family := Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Unknown;
      Remaining_Edge_Kind       : Remaining_RM_Edge_Kind := Edge.Remaining_RM_Edge_Unknown;
      Remaining_Edge_Blocker    : Remaining_RM_Edge_Blocker_Family := Edge.Remaining_RM_Edge_Blocker_None;
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
      Edge_Fingerprint          : Natural := 0;
      Consumer_Closure_Fingerprint : Natural := 0;
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

   type Remaining_RM_Edge_Stabilized_Closure_Model is private;
   type Remaining_RM_Edge_Stabilized_Closure_Set is private;

   procedure Clear (Model : in out Remaining_RM_Edge_Stabilized_Closure_Model);

   function Build
     (Gates : Gate.Remaining_RM_Edge_Stabilization_Gate_Model)
      return Remaining_RM_Edge_Stabilized_Closure_Model;

   function Count (Model : Remaining_RM_Edge_Stabilized_Closure_Model) return Natural;
   function Row_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Model) return Natural renames Count;
   function Row_At
     (Model : Remaining_RM_Edge_Stabilized_Closure_Model;
      Index : Positive) return Remaining_RM_Edge_Stabilized_Closure_Row;

   function Query_Count (Set : Remaining_RM_Edge_Stabilized_Closure_Set) return Natural;
   function Query_At
     (Set   : Remaining_RM_Edge_Stabilized_Closure_Set;
      Index : Positive) return Remaining_RM_Edge_Stabilized_Closure_Row;

   function Query_Status
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Model;
      Status : Remaining_RM_Edge_Stabilized_Closure_Status) return Remaining_RM_Edge_Stabilized_Closure_Set;
   function Query_Action
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Model;
      Action : Remaining_RM_Edge_Stabilized_Closure_Action) return Remaining_RM_Edge_Stabilized_Closure_Set;
   function Query_Family
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Model;
      Family : Remaining_RM_Edge_Stabilized_Closure_Family) return Remaining_RM_Edge_Stabilized_Closure_Set;
   function Find_By_Node
     (Model : Remaining_RM_Edge_Stabilized_Closure_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Remaining_RM_Edge_Stabilized_Closure_Set;
   function Find_By_Source_Fingerprint
     (Model       : Remaining_RM_Edge_Stabilized_Closure_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Stabilized_Closure_Set;
   function Find_By_Substitution_Fingerprint
     (Model       : Remaining_RM_Edge_Stabilized_Closure_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Stabilized_Closure_Set;

   function Count_By_Status
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Model;
      Status : Remaining_RM_Edge_Stabilized_Closure_Status) return Natural;
   function Count_By_Family
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Model;
      Family : Remaining_RM_Edge_Stabilized_Closure_Family) return Natural;
   function Accepted_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Model) return Natural;
   function Blocked_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Model) return Natural;
   function Current_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Model) return Natural;
   function Recheck_Required_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Model) return Natural;
   function Indeterminate_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Model) return Natural;
   function Stable_Fingerprint (Model : Remaining_RM_Edge_Stabilized_Closure_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Remaining_RM_Edge_Stabilized_Closure_Row);

   type Remaining_RM_Edge_Stabilized_Closure_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Remaining_RM_Edge_Stabilized_Closure_Model is record
      Rows                : Row_Vectors.Vector;
      Accepted_Total      : Natural := 0;
      Blocked_Total       : Natural := 0;
      Current_Total       : Natural := 0;
      Recheck_Total       : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

end Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Legality;
