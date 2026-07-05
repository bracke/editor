with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Shared_State_Recheck_Eligibility_Legality;
with Editor.Ada_Shared_State_Stabilized_Diagnostic_Integration;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Shared_State_Recheck_Application_Legality is

   --  Case 1220 shared-state recheck application legality.
   --
   --  This package consumes Case 1219 shared-state recheck eligibility rows and
   --  applies them back into the shared-state final closure / stabilized
   --  diagnostic boundary.  A shared-state semantic conclusion is current only
   --  when its prerequisite recheck chain is eligible now, source fingerprints
   --  still match, and cross-unit, abstract/refined-state, volatile/atomic,
   --  overload/type, representation/freezing, and tasking/protected evidence
   --  can be trusted together.  Blocker-family identity is preserved so later
   --  convergence and stabilization passes cannot flatten prerequisite causes.

   package Recheck renames Editor.Ada_Shared_State_Recheck_Eligibility_Legality;
   package Stable renames Editor.Ada_Shared_State_Stabilized_Diagnostic_Integration;

   subtype Shared_State_Recheck_Eligibility_Status is Recheck.Shared_State_Recheck_Status;
   subtype Shared_State_Recheck_Eligibility_Action is Recheck.Shared_State_Recheck_Action;
   subtype Shared_State_Recheck_Blocker_Family is Recheck.Shared_State_Recheck_Family;

   type Shared_State_Recheck_Application_Id is new Natural;
   No_Shared_State_Recheck_Application : constant Shared_State_Recheck_Application_Id := 0;

   type Shared_State_Recheck_Application_Status is
     (Shared_State_Recheck_Application_Not_Checked,
      Shared_State_Recheck_Application_Current_Accepted,
      Shared_State_Recheck_Application_Current_Non_Diagnostic_Evidence,
      Shared_State_Recheck_Application_Not_Required,
      Shared_State_Recheck_Application_Withheld_Cross_Unit_Dependency,
      Shared_State_Recheck_Application_Withheld_View_Barrier,
      Shared_State_Recheck_Application_Withheld_Generic_Backmapping,
      Shared_State_Recheck_Application_Withheld_State_Visibility,
      Shared_State_Recheck_Application_Withheld_Abstract_State,
      Shared_State_Recheck_Application_Withheld_Volatile_Atomic,
      Shared_State_Recheck_Application_Withheld_Overload_Shared_State,
      Shared_State_Recheck_Application_Withheld_Representation_Freezing,
      Shared_State_Recheck_Application_Withheld_Tasking_Protected,
      Shared_State_Recheck_Application_Withheld_Source_Fingerprint,
      Shared_State_Recheck_Application_Withheld_Stale_Eligibility,
      Shared_State_Recheck_Application_Withheld_Multiple_Prerequisites,
      Shared_State_Recheck_Application_Indeterminate);

   type Shared_State_Recheck_Application_Action is
     (Shared_State_Recheck_Application_Action_None,
      Shared_State_Recheck_Application_Action_Expose_Current,
      Shared_State_Recheck_Application_Action_Keep_Non_Diagnostic_Evidence,
      Shared_State_Recheck_Application_Action_Skip_Not_Required,
      Shared_State_Recheck_Application_Action_Withhold_For_Cross_Unit,
      Shared_State_Recheck_Application_Action_Withhold_For_View_Barrier,
      Shared_State_Recheck_Application_Action_Withhold_For_Generic_Backmapping,
      Shared_State_Recheck_Application_Action_Withhold_For_State_Visibility,
      Shared_State_Recheck_Application_Action_Withhold_For_Abstract_State,
      Shared_State_Recheck_Application_Action_Withhold_For_Volatile_Atomic,
      Shared_State_Recheck_Application_Action_Withhold_For_Overload_Type,
      Shared_State_Recheck_Application_Action_Withhold_For_Representation,
      Shared_State_Recheck_Application_Action_Withhold_For_Tasking,
      Shared_State_Recheck_Application_Action_Withhold_For_Source_Fingerprint,
      Shared_State_Recheck_Application_Action_Withhold_For_Stale_Eligibility,
      Shared_State_Recheck_Application_Action_Split_Prerequisites,
      Shared_State_Recheck_Application_Action_Degrade);

   type Shared_State_Recheck_Application_Row is record
      Id                         : Shared_State_Recheck_Application_Id := No_Shared_State_Recheck_Application;
      Eligibility_Id             : Recheck.Shared_State_Recheck_Id := Recheck.No_Shared_State_Recheck;
      Eligibility_Status         : Shared_State_Recheck_Eligibility_Status := Recheck.Shared_State_Recheck_Not_Checked;
      Eligibility_Action         : Shared_State_Recheck_Eligibility_Action := Recheck.Shared_State_Recheck_Action_None;
      Status                     : Shared_State_Recheck_Application_Status :=
        Shared_State_Recheck_Application_Not_Checked;
      Action                     : Shared_State_Recheck_Application_Action :=
        Shared_State_Recheck_Application_Action_None;
      Blocker_Family             : Shared_State_Recheck_Blocker_Family :=
        Stable.Shared_State_Stabilized_Diagnostic_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Dependency_Name            : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Current                    : Boolean := False;
      Accepted                   : Boolean := False;
      Withheld                   : Boolean := False;
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
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Shared_State_Recheck_Application_Model is private;
   type Shared_State_Recheck_Application_Set is private;

   procedure Clear (Model : in out Shared_State_Recheck_Application_Model);

   function Build
     (Eligibility : Recheck.Shared_State_Recheck_Model)
      return Shared_State_Recheck_Application_Model;

   function Count (Model : Shared_State_Recheck_Application_Model) return Natural;
   function Row_Count (Model : Shared_State_Recheck_Application_Model) return Natural renames Count;
   function Row_At
     (Model : Shared_State_Recheck_Application_Model;
      Index : Positive) return Shared_State_Recheck_Application_Row;

   function Query_Count (Set : Shared_State_Recheck_Application_Set) return Natural;
   function Query_At
     (Set   : Shared_State_Recheck_Application_Set;
      Index : Positive) return Shared_State_Recheck_Application_Row;

   function Query_Status
     (Model  : Shared_State_Recheck_Application_Model;
      Status : Shared_State_Recheck_Application_Status) return Shared_State_Recheck_Application_Set;
   function Query_Action
     (Model  : Shared_State_Recheck_Application_Model;
      Action : Shared_State_Recheck_Application_Action) return Shared_State_Recheck_Application_Set;
   function Query_Blocker_Family
     (Model  : Shared_State_Recheck_Application_Model;
      Family : Shared_State_Recheck_Blocker_Family) return Shared_State_Recheck_Application_Set;
   function Find_By_Node
     (Model : Shared_State_Recheck_Application_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Shared_State_Recheck_Application_Set;
   function Find_By_Source_Fingerprint
     (Model              : Shared_State_Recheck_Application_Model;
      Source_Fingerprint : Natural) return Shared_State_Recheck_Application_Set;

   function Count_By_Status
     (Model  : Shared_State_Recheck_Application_Model;
      Status : Shared_State_Recheck_Application_Status) return Natural;
   function Count_By_Blocker_Family
     (Model  : Shared_State_Recheck_Application_Model;
      Family : Shared_State_Recheck_Blocker_Family) return Natural;

   function Accepted_Count (Model : Shared_State_Recheck_Application_Model) return Natural;
   function Withheld_Count (Model : Shared_State_Recheck_Application_Model) return Natural;
   function Current_Count (Model : Shared_State_Recheck_Application_Model) return Natural;
   function Indeterminate_Count (Model : Shared_State_Recheck_Application_Model) return Natural;
   function Stable_Fingerprint (Model : Shared_State_Recheck_Application_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Shared_State_Recheck_Application_Row);

   type Shared_State_Recheck_Application_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Shared_State_Recheck_Application_Model is record
      Rows                : Row_Vectors.Vector;
      Accepted_Total      : Natural := 0;
      Withheld_Total      : Natural := 0;
      Current_Total       : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

end Editor.Ada_Shared_State_Recheck_Application_Legality;
