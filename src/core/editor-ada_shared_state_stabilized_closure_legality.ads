with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Shared_State_Stabilization_Gate_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Shared_State_Stabilized_Closure_Legality is

   --  Pass1223 shared-state stabilized closure legality.
   --
   --  This package consumes Pass1222 shared-state stabilization-gate rows and
   --  turns stable shared-state conclusions into first-class closure rows.
   --  Stable accepted evidence is promoted as current semantic evidence;
   --  stable withheld evidence remains an explicit closure blocker preserving
   --  the original blocker family.  Recheck-required or indeterminate rows are
   --  not exposed as confident shared-state closure conclusions.

   package Gate renames Editor.Ada_Shared_State_Stabilization_Gate_Legality;

   subtype Shared_State_Recheck_Blocker_Family is Gate.Shared_State_Recheck_Blocker_Family;
   subtype Shared_State_Stabilization_Gate_Status is Gate.Shared_State_Stabilization_Gate_Status;
   subtype Shared_State_Stabilization_Gate_Action is Gate.Shared_State_Stabilization_Gate_Action;

   type Shared_State_Stabilized_Closure_Id is new Natural;
   No_Shared_State_Stabilized_Closure : constant Shared_State_Stabilized_Closure_Id := 0;

   type Shared_State_Stabilized_Closure_Status is
     (Shared_State_Stabilized_Closure_Not_Checked,
      Shared_State_Stabilized_Closure_Accepted_Current,
      Shared_State_Stabilized_Closure_Accepted_Not_Required,
      Shared_State_Stabilized_Closure_Blocker_Cross_Unit_Dependency,
      Shared_State_Stabilized_Closure_Blocker_View_Barrier,
      Shared_State_Stabilized_Closure_Blocker_Generic_Backmapping,
      Shared_State_Stabilized_Closure_Blocker_State_Visibility,
      Shared_State_Stabilized_Closure_Blocker_Abstract_State,
      Shared_State_Stabilized_Closure_Blocker_Volatile_Atomic,
      Shared_State_Stabilized_Closure_Blocker_Overload_Shared_State,
      Shared_State_Stabilized_Closure_Blocker_Representation_Freezing,
      Shared_State_Stabilized_Closure_Blocker_Tasking_Protected,
      Shared_State_Stabilized_Closure_Blocker_Source_Fingerprint,
      Shared_State_Stabilized_Closure_Blocker_Stale_Eligibility,
      Shared_State_Stabilized_Closure_Blocker_Multiple_Prerequisites,
      Shared_State_Stabilized_Closure_Indeterminate,
      Shared_State_Stabilized_Closure_Recheck_Required);

   type Shared_State_Stabilized_Closure_Action is
     (Shared_State_Stabilized_Closure_Action_None,
      Shared_State_Stabilized_Closure_Action_Accept,
      Shared_State_Stabilized_Closure_Action_Accept_Not_Required,
      Shared_State_Stabilized_Closure_Action_Block_Prerequisite,
      Shared_State_Stabilized_Closure_Action_Retain_Fingerprint_Blocker,
      Shared_State_Stabilized_Closure_Action_Retain_Stale_Blocker,
      Shared_State_Stabilized_Closure_Action_Split_Prerequisites,
      Shared_State_Stabilized_Closure_Action_Degrade,
      Shared_State_Stabilized_Closure_Action_Recheck);

   type Shared_State_Stabilized_Closure_Row is record
      Id                         : Shared_State_Stabilized_Closure_Id := No_Shared_State_Stabilized_Closure;
      Stabilization_Id           : Gate.Shared_State_Stabilization_Gate_Id := Gate.No_Shared_State_Stabilization_Gate;
      Stabilization_Status       : Shared_State_Stabilization_Gate_Status := Gate.Shared_State_Stabilization_Gate_Not_Checked;
      Stabilization_Action       : Shared_State_Stabilization_Gate_Action := Gate.Shared_State_Stabilization_Gate_Action_None;
      Status                     : Shared_State_Stabilized_Closure_Status := Shared_State_Stabilized_Closure_Not_Checked;
      Action                     : Shared_State_Stabilized_Closure_Action := Shared_State_Stabilized_Closure_Action_None;
      Blocker_Family             : Shared_State_Recheck_Blocker_Family := Gate.Conv.Apply.Stable.Shared_State_Stabilized_Diagnostic_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Dependency_Name            : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Accepted                   : Boolean := False;
      Current                    : Boolean := False;
      Blocked                    : Boolean := False;
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
      Closure_Fingerprint        : Natural := 0;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Shared_State_Stabilized_Closure_Model is private;
   type Shared_State_Stabilized_Closure_Set is private;

   procedure Clear (Model : in out Shared_State_Stabilized_Closure_Model);

   function Build
     (Stabilization : Gate.Shared_State_Stabilization_Gate_Model)
      return Shared_State_Stabilized_Closure_Model;

   function Count (Model : Shared_State_Stabilized_Closure_Model) return Natural;
   function Row_Count (Model : Shared_State_Stabilized_Closure_Model) return Natural renames Count;
   function Row_At
     (Model : Shared_State_Stabilized_Closure_Model;
      Index : Positive) return Shared_State_Stabilized_Closure_Row;

   function Query_Count (Set : Shared_State_Stabilized_Closure_Set) return Natural;
   function Query_At
     (Set   : Shared_State_Stabilized_Closure_Set;
      Index : Positive) return Shared_State_Stabilized_Closure_Row;

   function Query_Status
     (Model  : Shared_State_Stabilized_Closure_Model;
      Status : Shared_State_Stabilized_Closure_Status) return Shared_State_Stabilized_Closure_Set;
   function Query_Action
     (Model  : Shared_State_Stabilized_Closure_Model;
      Action : Shared_State_Stabilized_Closure_Action) return Shared_State_Stabilized_Closure_Set;
   function Query_Blocker_Family
     (Model  : Shared_State_Stabilized_Closure_Model;
      Family : Shared_State_Recheck_Blocker_Family) return Shared_State_Stabilized_Closure_Set;
   function Find_By_Node
     (Model : Shared_State_Stabilized_Closure_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Shared_State_Stabilized_Closure_Set;
   function Find_By_Source_Fingerprint
     (Model              : Shared_State_Stabilized_Closure_Model;
      Source_Fingerprint : Natural) return Shared_State_Stabilized_Closure_Set;

   function Count_By_Status
     (Model  : Shared_State_Stabilized_Closure_Model;
      Status : Shared_State_Stabilized_Closure_Status) return Natural;
   function Count_By_Blocker_Family
     (Model  : Shared_State_Stabilized_Closure_Model;
      Family : Shared_State_Recheck_Blocker_Family) return Natural;

   function Accepted_Count (Model : Shared_State_Stabilized_Closure_Model) return Natural;
   function Blocked_Count (Model : Shared_State_Stabilized_Closure_Model) return Natural;
   function Current_Count (Model : Shared_State_Stabilized_Closure_Model) return Natural;
   function Recheck_Required_Count (Model : Shared_State_Stabilized_Closure_Model) return Natural;
   function Indeterminate_Count (Model : Shared_State_Stabilized_Closure_Model) return Natural;
   function Stable_Fingerprint (Model : Shared_State_Stabilized_Closure_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Shared_State_Stabilized_Closure_Row);

   type Shared_State_Stabilized_Closure_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Shared_State_Stabilized_Closure_Model is record
      Rows                : Row_Vectors.Vector;
      Accepted_Total      : Natural := 0;
      Blocked_Total       : Natural := 0;
      Current_Total       : Natural := 0;
      Recheck_Total       : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

end Editor.Ada_Shared_State_Stabilized_Closure_Legality;
