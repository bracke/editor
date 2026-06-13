with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Remaining_RM_Edge_Recheck_Convergence_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Remaining_RM_Edge_Stabilization_Gate_Legality is

   --  Pass1290 stabilization gate for remaining Ada RM edge evidence.
   --
   --  This package consumes Pass1289 remaining RM edge convergence rows and
   --  decides whether the remaining hard RM edge evidence may cross the stable
   --  semantic closure/feed boundary.  Stable current and stable not-required
   --  rows are promoted as semantic evidence; stable withheld rows retain their
   --  exact blocker family; changed rows require another bounded recheck; and
   --  indeterminate rows remain degraded rather than becoming confident Ada RM
   --  legality evidence.

   package Conv renames Editor.Ada_Remaining_RM_Edge_Recheck_Convergence_Legality;
   package Diagnostics renames Conv.Diagnostics;
   package Edge renames Conv.Edge;

   subtype Remaining_RM_Edge_Stabilization_Convergence_Status is Conv.Remaining_RM_Edge_Convergence_Status;
   subtype Remaining_RM_Edge_Stabilization_Convergence_Action is Conv.Remaining_RM_Edge_Convergence_Action;
   subtype Remaining_RM_Edge_Stabilization_Family is Conv.Remaining_RM_Edge_Convergence_Family;
   subtype Remaining_RM_Edge_Kind is Conv.Remaining_RM_Edge_Kind;
   subtype Remaining_RM_Edge_Blocker_Family is Conv.Remaining_RM_Edge_Blocker_Family;

   type Remaining_RM_Edge_Stabilization_Gate_Id is new Natural;
   No_Remaining_RM_Edge_Stabilization_Gate : constant Remaining_RM_Edge_Stabilization_Gate_Id := 0;

   type Remaining_RM_Edge_Stabilization_Gate_Status is
     (Remaining_RM_Edge_Stabilization_Gate_Not_Checked,
      Remaining_RM_Edge_Stabilization_Gate_Promoted_Current,
      Remaining_RM_Edge_Stabilization_Gate_Promoted_Not_Required,
      Remaining_RM_Edge_Stabilization_Gate_Withheld_Remaining_Edge,
      Remaining_RM_Edge_Stabilization_Gate_Withheld_Stabilized_Closure,
      Remaining_RM_Edge_Stabilization_Gate_Withheld_Source_Fingerprint,
      Remaining_RM_Edge_Stabilization_Gate_Withheld_Substitution_Fingerprint,
      Remaining_RM_Edge_Stabilization_Gate_Withheld_Multiple_Prerequisites,
      Remaining_RM_Edge_Stabilization_Gate_Withheld_Recheck_Required,
      Remaining_RM_Edge_Stabilization_Gate_Degraded_Indeterminate,
      Remaining_RM_Edge_Stabilization_Gate_Recheck_Required);

   type Remaining_RM_Edge_Stabilization_Gate_Action is
     (Remaining_RM_Edge_Stabilization_Gate_Action_None,
      Remaining_RM_Edge_Stabilization_Gate_Action_Promote_Current,
      Remaining_RM_Edge_Stabilization_Gate_Action_Promote_Not_Required,
      Remaining_RM_Edge_Stabilization_Gate_Action_Retain_Remaining_Edge_Blocker,
      Remaining_RM_Edge_Stabilization_Gate_Action_Retain_Stabilized_Closure_Blocker,
      Remaining_RM_Edge_Stabilization_Gate_Action_Retain_Source_Fingerprint_Blocker,
      Remaining_RM_Edge_Stabilization_Gate_Action_Retain_Substitution_Fingerprint_Blocker,
      Remaining_RM_Edge_Stabilization_Gate_Action_Split_Prerequisites,
      Remaining_RM_Edge_Stabilization_Gate_Action_Wait_For_Recheck_Gate,
      Remaining_RM_Edge_Stabilization_Gate_Action_Degrade,
      Remaining_RM_Edge_Stabilization_Gate_Action_Recheck);

   type Remaining_RM_Edge_Stabilization_Gate_Row is record
      Id                        : Remaining_RM_Edge_Stabilization_Gate_Id := No_Remaining_RM_Edge_Stabilization_Gate;
      Convergence_Id            : Conv.Remaining_RM_Edge_Convergence_Id := Conv.No_Remaining_RM_Edge_Convergence;
      Application_Id            : Conv.Apply.Remaining_RM_Edge_Application_Id := Conv.Apply.No_Remaining_RM_Edge_Application;
      Eligibility_Id            : Conv.Apply.Recheck.Remaining_RM_Edge_Recheck_Id := Conv.Apply.Recheck.No_Remaining_RM_Edge_Recheck;
      Worklist_Item             : Conv.Apply.Recheck.Worklist.Remaining_RM_Edge_Worklist_Id := Conv.Apply.Recheck.Worklist.No_Remaining_RM_Edge_Worklist_Item;
      Diagnostic_Row            : Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Id := Diagnostics.No_Remaining_RM_Edge_Stabilized_Diagnostic;
      Convergence_Status        : Remaining_RM_Edge_Stabilization_Convergence_Status := Conv.Remaining_RM_Edge_Convergence_Not_Checked;
      Convergence_Action        : Remaining_RM_Edge_Stabilization_Convergence_Action := Conv.Remaining_RM_Edge_Convergence_Action_None;
      Status                    : Remaining_RM_Edge_Stabilization_Gate_Status := Remaining_RM_Edge_Stabilization_Gate_Not_Checked;
      Action                    : Remaining_RM_Edge_Stabilization_Gate_Action := Remaining_RM_Edge_Stabilization_Gate_Action_None;
      Family                    : Remaining_RM_Edge_Stabilization_Family := Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Unknown;
      Remaining_Edge_Kind       : Remaining_RM_Edge_Kind := Edge.Remaining_RM_Edge_Unknown;
      Remaining_Edge_Blocker    : Remaining_RM_Edge_Blocker_Family := Edge.Remaining_RM_Edge_Blocker_None;
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
      Edge_Fingerprint          : Natural := 0;
      Closure_Fingerprint       : Natural := 0;
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

   type Remaining_RM_Edge_Stabilization_Gate_Model is private;
   type Remaining_RM_Edge_Stabilization_Gate_Set is private;

   procedure Clear (Model : in out Remaining_RM_Edge_Stabilization_Gate_Model);

   function Build
     (Convergence : Conv.Remaining_RM_Edge_Convergence_Model)
      return Remaining_RM_Edge_Stabilization_Gate_Model;

   function Count (Model : Remaining_RM_Edge_Stabilization_Gate_Model) return Natural;
   function Row_Count (Model : Remaining_RM_Edge_Stabilization_Gate_Model) return Natural renames Count;
   function Row_At
     (Model : Remaining_RM_Edge_Stabilization_Gate_Model;
      Index : Positive) return Remaining_RM_Edge_Stabilization_Gate_Row;

   function Query_Count (Set : Remaining_RM_Edge_Stabilization_Gate_Set) return Natural;
   function Query_At
     (Set   : Remaining_RM_Edge_Stabilization_Gate_Set;
      Index : Positive) return Remaining_RM_Edge_Stabilization_Gate_Row;

   function Query_Status
     (Model  : Remaining_RM_Edge_Stabilization_Gate_Model;
      Status : Remaining_RM_Edge_Stabilization_Gate_Status) return Remaining_RM_Edge_Stabilization_Gate_Set;
   function Query_Action
     (Model  : Remaining_RM_Edge_Stabilization_Gate_Model;
      Action : Remaining_RM_Edge_Stabilization_Gate_Action) return Remaining_RM_Edge_Stabilization_Gate_Set;
   function Query_Family
     (Model  : Remaining_RM_Edge_Stabilization_Gate_Model;
      Family : Remaining_RM_Edge_Stabilization_Family) return Remaining_RM_Edge_Stabilization_Gate_Set;
   function Query_Node
     (Model : Remaining_RM_Edge_Stabilization_Gate_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Remaining_RM_Edge_Stabilization_Gate_Set;
   function Query_Source_Fingerprint
     (Model       : Remaining_RM_Edge_Stabilization_Gate_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Stabilization_Gate_Set;
   function Query_Substitution_Fingerprint
     (Model       : Remaining_RM_Edge_Stabilization_Gate_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Stabilization_Gate_Set;

   function Count_Status
     (Model  : Remaining_RM_Edge_Stabilization_Gate_Model;
      Status : Remaining_RM_Edge_Stabilization_Gate_Status) return Natural;
   function Count_Action
     (Model  : Remaining_RM_Edge_Stabilization_Gate_Model;
      Action : Remaining_RM_Edge_Stabilization_Gate_Action) return Natural;
   function Count_Family
     (Model  : Remaining_RM_Edge_Stabilization_Gate_Model;
      Family : Remaining_RM_Edge_Stabilization_Family) return Natural;

   function Promoted_Count (Model : Remaining_RM_Edge_Stabilization_Gate_Model) return Natural;
   function Withheld_Count (Model : Remaining_RM_Edge_Stabilization_Gate_Model) return Natural;
   function Current_Count (Model : Remaining_RM_Edge_Stabilization_Gate_Model) return Natural;
   function Recheck_Required_Count (Model : Remaining_RM_Edge_Stabilization_Gate_Model) return Natural;
   function Indeterminate_Count (Model : Remaining_RM_Edge_Stabilization_Gate_Model) return Natural;
   function Stable_Fingerprint (Model : Remaining_RM_Edge_Stabilization_Gate_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Remaining_RM_Edge_Stabilization_Gate_Row);

   type Remaining_RM_Edge_Stabilization_Gate_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Remaining_RM_Edge_Stabilization_Gate_Model is record
      Rows                : Row_Vectors.Vector;
      Promoted_Total      : Natural := 0;
      Withheld_Total      : Natural := 0;
      Current_Total       : Natural := 0;
      Recheck_Total       : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

end Editor.Ada_Remaining_RM_Edge_Stabilization_Gate_Legality;
