with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Shared_State_Recheck_Application_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Shared_State_Recheck_Convergence_Legality is

   --  Pass1221 shared-state recheck convergence legality.
   --
   --  This package consumes Pass1220 shared-state recheck application rows and
   --  classifies whether shared-state recheck evidence has converged as
   --  current, converged as not required, stayed stably withheld by a preserved
   --  prerequisite blocker, stayed indeterminate, or changed relative to a
   --  caller supplied prior application fingerprint.  It prevents repeated
   --  shared-state rechecks from cycling on unchanged abstract/refined-state,
   --  volatile/atomic/shared-variable, overload/type, representation/freezing,
   --  tasking/protected, and cross-unit evidence while still forcing recheck
   --  when the relevant application fingerprint changes.

   package Apply renames Editor.Ada_Shared_State_Recheck_Application_Legality;

   subtype Shared_State_Recheck_Application_Status is Apply.Shared_State_Recheck_Application_Status;
   subtype Shared_State_Recheck_Application_Action is Apply.Shared_State_Recheck_Application_Action;
   subtype Shared_State_Recheck_Blocker_Family is Apply.Shared_State_Recheck_Blocker_Family;

   type Shared_State_Recheck_Convergence_Id is new Natural;
   No_Shared_State_Recheck_Convergence : constant Shared_State_Recheck_Convergence_Id := 0;

   type Shared_State_Recheck_Convergence_Status is
     (Shared_State_Recheck_Convergence_Not_Checked,
      Shared_State_Recheck_Converged_Current,
      Shared_State_Recheck_Converged_Not_Required,
      Shared_State_Recheck_Stable_Withheld_Cross_Unit_Dependency,
      Shared_State_Recheck_Stable_Withheld_View_Barrier,
      Shared_State_Recheck_Stable_Withheld_Generic_Backmapping,
      Shared_State_Recheck_Stable_Withheld_State_Visibility,
      Shared_State_Recheck_Stable_Withheld_Abstract_State,
      Shared_State_Recheck_Stable_Withheld_Volatile_Atomic,
      Shared_State_Recheck_Stable_Withheld_Overload_Shared_State,
      Shared_State_Recheck_Stable_Withheld_Representation_Freezing,
      Shared_State_Recheck_Stable_Withheld_Tasking_Protected,
      Shared_State_Recheck_Stable_Withheld_Source_Fingerprint,
      Shared_State_Recheck_Stable_Withheld_Stale_Eligibility,
      Shared_State_Recheck_Stable_Multiple_Prerequisites,
      Shared_State_Recheck_Stable_Indeterminate,
      Shared_State_Recheck_Changed_Since_Previous);

   type Shared_State_Recheck_Convergence_Action is
     (Shared_State_Recheck_Convergence_Action_None,
      Shared_State_Recheck_Convergence_Action_Accept_Current,
      Shared_State_Recheck_Convergence_Action_Skip_Not_Required,
      Shared_State_Recheck_Convergence_Action_Retain_Stable_Withheld,
      Shared_State_Recheck_Convergence_Action_Retain_Stable_Fingerprint_Blocker,
      Shared_State_Recheck_Convergence_Action_Retain_Stable_Stale_Blocker,
      Shared_State_Recheck_Convergence_Action_Split_Prerequisites,
      Shared_State_Recheck_Convergence_Action_Degrade,
      Shared_State_Recheck_Convergence_Action_Recheck_Again);

   type Shared_State_Recheck_Convergence_Row is record
      Id                         : Shared_State_Recheck_Convergence_Id := No_Shared_State_Recheck_Convergence;
      Application_Id             : Apply.Shared_State_Recheck_Application_Id :=
        Apply.No_Shared_State_Recheck_Application;
      Application_Status         : Shared_State_Recheck_Application_Status :=
        Apply.Shared_State_Recheck_Application_Not_Checked;
      Application_Action         : Shared_State_Recheck_Application_Action :=
        Apply.Shared_State_Recheck_Application_Action_None;
      Status                     : Shared_State_Recheck_Convergence_Status :=
        Shared_State_Recheck_Convergence_Not_Checked;
      Action                     : Shared_State_Recheck_Convergence_Action :=
        Shared_State_Recheck_Convergence_Action_None;
      Blocker_Family             : Shared_State_Recheck_Blocker_Family :=
        Apply.Stable.Shared_State_Stabilized_Diagnostic_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Dependency_Name            : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Current                    : Boolean := False;
      Stable                     : Boolean := False;
      Withheld                   : Boolean := False;
      Changed                    : Boolean := False;
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
      Previous_Model_Fingerprint : Natural := 0;
      Current_Model_Fingerprint  : Natural := 0;
      Convergence_Fingerprint    : Natural := 0;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Shared_State_Recheck_Convergence_Model is private;
   type Shared_State_Recheck_Convergence_Set is private;

   procedure Clear (Model : in out Shared_State_Recheck_Convergence_Model);

   function Build
     (Applications               : Apply.Shared_State_Recheck_Application_Model;
      Previous_Model_Fingerprint : Natural := 0)
      return Shared_State_Recheck_Convergence_Model;

   function Count (Model : Shared_State_Recheck_Convergence_Model) return Natural;
   function Row_Count (Model : Shared_State_Recheck_Convergence_Model) return Natural renames Count;
   function Row_At
     (Model : Shared_State_Recheck_Convergence_Model;
      Index : Positive) return Shared_State_Recheck_Convergence_Row;

   function Query_Count (Set : Shared_State_Recheck_Convergence_Set) return Natural;
   function Query_At
     (Set   : Shared_State_Recheck_Convergence_Set;
      Index : Positive) return Shared_State_Recheck_Convergence_Row;

   function Query_Status
     (Model  : Shared_State_Recheck_Convergence_Model;
      Status : Shared_State_Recheck_Convergence_Status) return Shared_State_Recheck_Convergence_Set;
   function Query_Action
     (Model  : Shared_State_Recheck_Convergence_Model;
      Action : Shared_State_Recheck_Convergence_Action) return Shared_State_Recheck_Convergence_Set;
   function Query_Blocker_Family
     (Model  : Shared_State_Recheck_Convergence_Model;
      Family : Shared_State_Recheck_Blocker_Family) return Shared_State_Recheck_Convergence_Set;
   function Find_By_Node
     (Model : Shared_State_Recheck_Convergence_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Shared_State_Recheck_Convergence_Set;
   function Find_By_Source_Fingerprint
     (Model              : Shared_State_Recheck_Convergence_Model;
      Source_Fingerprint : Natural) return Shared_State_Recheck_Convergence_Set;

   function Count_By_Status
     (Model  : Shared_State_Recheck_Convergence_Model;
      Status : Shared_State_Recheck_Convergence_Status) return Natural;
   function Count_By_Blocker_Family
     (Model  : Shared_State_Recheck_Convergence_Model;
      Family : Shared_State_Recheck_Blocker_Family) return Natural;

   function Converged_Count (Model : Shared_State_Recheck_Convergence_Model) return Natural;
   function Stable_Withheld_Count (Model : Shared_State_Recheck_Convergence_Model) return Natural;
   function Current_Count (Model : Shared_State_Recheck_Convergence_Model) return Natural;
   function Changed_Count (Model : Shared_State_Recheck_Convergence_Model) return Natural;
   function Indeterminate_Count (Model : Shared_State_Recheck_Convergence_Model) return Natural;
   function Stable_Fingerprint (Model : Shared_State_Recheck_Convergence_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Shared_State_Recheck_Convergence_Row);

   type Shared_State_Recheck_Convergence_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Shared_State_Recheck_Convergence_Model is record
      Rows                  : Row_Vectors.Vector;
      Converged_Total       : Natural := 0;
      Stable_Withheld_Total : Natural := 0;
      Current_Total         : Natural := 0;
      Changed_Total         : Natural := 0;
      Indeterminate_Total   : Natural := 0;
      Fingerprint           : Natural := 0;
   end record;

end Editor.Ada_Shared_State_Recheck_Convergence_Legality;
