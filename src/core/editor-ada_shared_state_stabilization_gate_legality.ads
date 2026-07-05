with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Shared_State_Recheck_Convergence_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Shared_State_Stabilization_Gate_Legality is

   --  Case 1222 shared-state stabilization gate legality.
   --
   --  This package consumes Case 1221 shared-state recheck convergence rows and
   --  decides whether shared-state evidence may be promoted across the
   --  shared-state semantic closure boundary.  Promotion is allowed only for
   --  stable current/not-required convergence rows.  Stable blockers retain
   --  their original blocker family, changed rows require another bounded
   --  recheck, and indeterminate rows remain degraded instead of becoming
   --  confident legal conclusions.

   package Conv renames Editor.Ada_Shared_State_Recheck_Convergence_Legality;

   subtype Shared_State_Recheck_Convergence_Status is Conv.Shared_State_Recheck_Convergence_Status;
   subtype Shared_State_Recheck_Convergence_Action is Conv.Shared_State_Recheck_Convergence_Action;
   subtype Shared_State_Recheck_Blocker_Family is Conv.Shared_State_Recheck_Blocker_Family;

   type Shared_State_Stabilization_Gate_Id is new Natural;
   No_Shared_State_Stabilization_Gate : constant Shared_State_Stabilization_Gate_Id := 0;

   type Shared_State_Stabilization_Gate_Status is
     (Shared_State_Stabilization_Gate_Not_Checked,
      Shared_State_Stabilization_Gate_Promoted_Current,
      Shared_State_Stabilization_Gate_Promoted_Not_Required,
      Shared_State_Stabilization_Gate_Withheld_Cross_Unit_Dependency,
      Shared_State_Stabilization_Gate_Withheld_View_Barrier,
      Shared_State_Stabilization_Gate_Withheld_Generic_Backmapping,
      Shared_State_Stabilization_Gate_Withheld_State_Visibility,
      Shared_State_Stabilization_Gate_Withheld_Abstract_State,
      Shared_State_Stabilization_Gate_Withheld_Volatile_Atomic,
      Shared_State_Stabilization_Gate_Withheld_Overload_Shared_State,
      Shared_State_Stabilization_Gate_Withheld_Representation_Freezing,
      Shared_State_Stabilization_Gate_Withheld_Tasking_Protected,
      Shared_State_Stabilization_Gate_Withheld_Source_Fingerprint,
      Shared_State_Stabilization_Gate_Withheld_Stale_Eligibility,
      Shared_State_Stabilization_Gate_Withheld_Multiple_Prerequisites,
      Shared_State_Stabilization_Gate_Degraded_Indeterminate,
      Shared_State_Stabilization_Gate_Recheck_Required);

   type Shared_State_Stabilization_Gate_Action is
     (Shared_State_Stabilization_Gate_Action_None,
      Shared_State_Stabilization_Gate_Action_Promote_Current,
      Shared_State_Stabilization_Gate_Action_Promote_Not_Required,
      Shared_State_Stabilization_Gate_Action_Withhold_Prerequisite,
      Shared_State_Stabilization_Gate_Action_Retain_Fingerprint_Blocker,
      Shared_State_Stabilization_Gate_Action_Retain_Stale_Blocker,
      Shared_State_Stabilization_Gate_Action_Split_Prerequisites,
      Shared_State_Stabilization_Gate_Action_Degrade,
      Shared_State_Stabilization_Gate_Action_Recheck);

   type Shared_State_Stabilization_Gate_Row is record
      Id                         : Shared_State_Stabilization_Gate_Id := No_Shared_State_Stabilization_Gate;
      Convergence_Id             : Conv.Shared_State_Recheck_Convergence_Id :=
        Conv.No_Shared_State_Recheck_Convergence;
      Convergence_Status         : Shared_State_Recheck_Convergence_Status :=
        Conv.Shared_State_Recheck_Convergence_Not_Checked;
      Convergence_Action         : Shared_State_Recheck_Convergence_Action :=
        Conv.Shared_State_Recheck_Convergence_Action_None;
      Status                     : Shared_State_Stabilization_Gate_Status :=
        Shared_State_Stabilization_Gate_Not_Checked;
      Action                     : Shared_State_Stabilization_Gate_Action :=
        Shared_State_Stabilization_Gate_Action_None;
      Blocker_Family             : Shared_State_Recheck_Blocker_Family :=
        Conv.Apply.Stable.Shared_State_Stabilized_Diagnostic_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Dependency_Name            : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Promoted                   : Boolean := False;
      Current                    : Boolean := False;
      Withheld                   : Boolean := False;
      Stable                     : Boolean := False;
      Recheck_Required           : Boolean := False;
      Blocks_Downstream          : Boolean := False;
      Priority_Rank              : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Source_Fingerprint         : Natural := 0;
      Worklist_Fingerprint       : Natural := 0;
      Eligibility_Fingerprint    : Natural := 0;
      Application_Fingerprint    : Natural := 0;
      Convergence_Fingerprint    : Natural := 0;
      Stabilization_Fingerprint  : Natural := 0;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Shared_State_Stabilization_Gate_Model is private;
   type Shared_State_Stabilization_Gate_Set is private;

   procedure Clear (Model : in out Shared_State_Stabilization_Gate_Model);

   function Build
     (Convergence : Conv.Shared_State_Recheck_Convergence_Model)
      return Shared_State_Stabilization_Gate_Model;

   function Count (Model : Shared_State_Stabilization_Gate_Model) return Natural;
   function Row_Count (Model : Shared_State_Stabilization_Gate_Model) return Natural renames Count;
   function Row_At
     (Model : Shared_State_Stabilization_Gate_Model;
      Index : Positive) return Shared_State_Stabilization_Gate_Row;

   function Query_Count (Set : Shared_State_Stabilization_Gate_Set) return Natural;
   function Query_At
     (Set   : Shared_State_Stabilization_Gate_Set;
      Index : Positive) return Shared_State_Stabilization_Gate_Row;

   function Query_Status
     (Model  : Shared_State_Stabilization_Gate_Model;
      Status : Shared_State_Stabilization_Gate_Status) return Shared_State_Stabilization_Gate_Set;
   function Query_Action
     (Model  : Shared_State_Stabilization_Gate_Model;
      Action : Shared_State_Stabilization_Gate_Action) return Shared_State_Stabilization_Gate_Set;
   function Query_Blocker_Family
     (Model  : Shared_State_Stabilization_Gate_Model;
      Family : Shared_State_Recheck_Blocker_Family) return Shared_State_Stabilization_Gate_Set;
   function Find_By_Node
     (Model : Shared_State_Stabilization_Gate_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Shared_State_Stabilization_Gate_Set;
   function Find_By_Source_Fingerprint
     (Model              : Shared_State_Stabilization_Gate_Model;
      Source_Fingerprint : Natural) return Shared_State_Stabilization_Gate_Set;

   function Count_By_Status
     (Model  : Shared_State_Stabilization_Gate_Model;
      Status : Shared_State_Stabilization_Gate_Status) return Natural;
   function Count_By_Blocker_Family
     (Model  : Shared_State_Stabilization_Gate_Model;
      Family : Shared_State_Recheck_Blocker_Family) return Natural;

   function Promoted_Count (Model : Shared_State_Stabilization_Gate_Model) return Natural;
   function Withheld_Count (Model : Shared_State_Stabilization_Gate_Model) return Natural;
   function Current_Count (Model : Shared_State_Stabilization_Gate_Model) return Natural;
   function Recheck_Required_Count (Model : Shared_State_Stabilization_Gate_Model) return Natural;
   function Indeterminate_Count (Model : Shared_State_Stabilization_Gate_Model) return Natural;
   function Stable_Fingerprint (Model : Shared_State_Stabilization_Gate_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Shared_State_Stabilization_Gate_Row);

   type Shared_State_Stabilization_Gate_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Shared_State_Stabilization_Gate_Model is record
      Rows                : Row_Vectors.Vector;
      Promoted_Total      : Natural := 0;
      Withheld_Total      : Natural := 0;
      Current_Total       : Natural := 0;
      Recheck_Total       : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

end Editor.Ada_Shared_State_Stabilization_Gate_Legality;
