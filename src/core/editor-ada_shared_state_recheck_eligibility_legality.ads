with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Shared_State_Remediation_Worklist_Legality;
with Editor.Ada_Shared_State_Stabilized_Diagnostic_Integration;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Shared_State_Recheck_Eligibility_Legality is

   --  Pass1219 shared-state recheck eligibility legality.
   --
   --  This package consumes the Pass1218 shared-state remediation worklist and
   --  converts ordered shared-state prerequisite work into bounded recheck
   --  eligibility rows.  It prevents downstream semantic consumers from
   --  accepting abstract/refined-state, volatile/atomic, overload/type,
   --  representation/freezing, tasking/protected, cross-unit, view, generic,
   --  state-visibility, fingerprint, multiple-blocker, or indeterminate
   --  conclusions while the matching prerequisite remains unresolved.

   package Worklist renames Editor.Ada_Shared_State_Remediation_Worklist_Legality;
   package Stable renames Editor.Ada_Shared_State_Stabilized_Diagnostic_Integration;

   subtype Shared_State_Recheck_Family is Worklist.Shared_State_Worklist_Family;
   subtype Shared_State_Recheck_Work_Action is Worklist.Shared_State_Worklist_Action;
   subtype Shared_State_Recheck_Work_Priority is Worklist.Shared_State_Worklist_Priority;

   type Shared_State_Recheck_Id is new Natural;
   No_Shared_State_Recheck : constant Shared_State_Recheck_Id := 0;

   type Shared_State_Recheck_Status is
     (Shared_State_Recheck_Not_Checked,
      Shared_State_Recheck_Not_Required_Current,
      Shared_State_Recheck_Eligible_Now,
      Shared_State_Recheck_Blocked_By_Cross_Unit,
      Shared_State_Recheck_Blocked_By_View_Barrier,
      Shared_State_Recheck_Blocked_By_Generic_Backmapping,
      Shared_State_Recheck_Blocked_By_State_Visibility,
      Shared_State_Recheck_Blocked_By_Abstract_State,
      Shared_State_Recheck_Blocked_By_Volatile_Atomic,
      Shared_State_Recheck_Blocked_By_Overload_Type,
      Shared_State_Recheck_Blocked_By_Representation,
      Shared_State_Recheck_Blocked_By_Tasking_Protected,
      Shared_State_Recheck_Blocked_By_Fingerprint,
      Shared_State_Recheck_Multiple_Prerequisites,
      Shared_State_Recheck_Indeterminate);

   type Shared_State_Recheck_Action is
     (Shared_State_Recheck_Action_None,
      Shared_State_Recheck_Action_Keep_Current,
      Shared_State_Recheck_Action_Run_Now,
      Shared_State_Recheck_Action_Wait_For_Cross_Unit,
      Shared_State_Recheck_Action_Wait_For_View_Repair,
      Shared_State_Recheck_Action_Wait_For_Generic_Backmapping,
      Shared_State_Recheck_Action_Wait_For_State_Visibility,
      Shared_State_Recheck_Action_Wait_For_Abstract_State,
      Shared_State_Recheck_Action_Wait_For_Volatile_Atomic,
      Shared_State_Recheck_Action_Wait_For_Overload_Type,
      Shared_State_Recheck_Action_Wait_For_Representation,
      Shared_State_Recheck_Action_Wait_For_Tasking_Protected,
      Shared_State_Recheck_Action_Wait_For_Source_Fingerprint,
      Shared_State_Recheck_Action_Split_Prerequisites,
      Shared_State_Recheck_Action_Degrade);

   type Shared_State_Recheck_Row is record
      Id                      : Shared_State_Recheck_Id := No_Shared_State_Recheck;
      Worklist_Item           : Worklist.Shared_State_Worklist_Id := Worklist.No_Shared_State_Worklist_Item;
      Work_Action             : Shared_State_Recheck_Work_Action := Worklist.Shared_State_Worklist_No_Action;
      Work_Priority           : Shared_State_Recheck_Work_Priority := Worklist.Shared_State_Worklist_Priority_None;
      Status                  : Shared_State_Recheck_Status := Shared_State_Recheck_Not_Checked;
      Action                  : Shared_State_Recheck_Action := Shared_State_Recheck_Action_None;
      Family                  : Shared_State_Recheck_Family := Stable.Shared_State_Stabilized_Diagnostic_Unknown;
      Node                    : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Name               : Ada.Strings.Unbounded.Unbounded_String;
      Dependency_Name         : Ada.Strings.Unbounded.Unbounded_String;
      State_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Ready_For_Recheck       : Boolean := False;
      Blocks_Downstream       : Boolean := False;
      Current_Evidence        : Boolean := False;
      Priority_Rank           : Natural := 0;
      Source_Fingerprint      : Natural := 0;
      Worklist_Fingerprint    : Natural := 0;
      Eligibility_Fingerprint : Natural := 0;
      Start_Line              : Positive := 1;
      Start_Column            : Positive := 1;
      End_Line                : Positive := 1;
      End_Column              : Positive := 1;
      Message                 : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Shared_State_Recheck_Model is private;
   type Shared_State_Recheck_Set is private;

   procedure Clear (Model : in out Shared_State_Recheck_Model);

   function Build
     (Work : Worklist.Shared_State_Worklist_Model)
      return Shared_State_Recheck_Model;

   function Row_Count (Model : Shared_State_Recheck_Model) return Natural;
   function Row_At
     (Model : Shared_State_Recheck_Model;
      Index : Positive) return Shared_State_Recheck_Row;

   function Query_Count (Set : Shared_State_Recheck_Set) return Natural;
   function Query_At
     (Set   : Shared_State_Recheck_Set;
      Index : Positive) return Shared_State_Recheck_Row;

   function Query_Status
     (Model  : Shared_State_Recheck_Model;
      Status : Shared_State_Recheck_Status) return Shared_State_Recheck_Set;
   function Query_Action
     (Model  : Shared_State_Recheck_Model;
      Action : Shared_State_Recheck_Action) return Shared_State_Recheck_Set;
   function Query_Family
     (Model  : Shared_State_Recheck_Model;
      Family : Shared_State_Recheck_Family) return Shared_State_Recheck_Set;
   function Query_Node
     (Model : Shared_State_Recheck_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Shared_State_Recheck_Set;

   function Count_Status
     (Model  : Shared_State_Recheck_Model;
      Status : Shared_State_Recheck_Status) return Natural;
   function Count_Action
     (Model  : Shared_State_Recheck_Model;
      Action : Shared_State_Recheck_Action) return Natural;
   function Count_Family
     (Model  : Shared_State_Recheck_Model;
      Family : Shared_State_Recheck_Family) return Natural;

   function Current_Evidence_Count (Model : Shared_State_Recheck_Model) return Natural;
   function Eligible_Count (Model : Shared_State_Recheck_Model) return Natural;
   function Blocked_Count (Model : Shared_State_Recheck_Model) return Natural;
   function Cross_Unit_Blocked_Count (Model : Shared_State_Recheck_Model) return Natural;
   function View_Blocked_Count (Model : Shared_State_Recheck_Model) return Natural;
   function Generic_Blocked_Count (Model : Shared_State_Recheck_Model) return Natural;
   function State_Visibility_Blocked_Count (Model : Shared_State_Recheck_Model) return Natural;
   function Abstract_State_Blocked_Count (Model : Shared_State_Recheck_Model) return Natural;
   function Volatile_Atomic_Blocked_Count (Model : Shared_State_Recheck_Model) return Natural;
   function Overload_Blocked_Count (Model : Shared_State_Recheck_Model) return Natural;
   function Representation_Blocked_Count (Model : Shared_State_Recheck_Model) return Natural;
   function Tasking_Blocked_Count (Model : Shared_State_Recheck_Model) return Natural;
   function Fingerprint_Blocked_Count (Model : Shared_State_Recheck_Model) return Natural;
   function Multiple_Prerequisite_Count (Model : Shared_State_Recheck_Model) return Natural;
   function Indeterminate_Count (Model : Shared_State_Recheck_Model) return Natural;
   function Fingerprint (Model : Shared_State_Recheck_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Shared_State_Recheck_Row);

   type Shared_State_Recheck_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Shared_State_Recheck_Model is record
      Rows                   : Row_Vectors.Vector;
      Current_Evidence_Total : Natural := 0;
      Eligible_Total         : Natural := 0;
      Blocked_Total          : Natural := 0;
      Cross_Unit_Total       : Natural := 0;
      View_Total             : Natural := 0;
      Generic_Total          : Natural := 0;
      State_Visibility_Total : Natural := 0;
      Abstract_State_Total   : Natural := 0;
      Volatile_Atomic_Total  : Natural := 0;
      Overload_Total         : Natural := 0;
      Representation_Total   : Natural := 0;
      Tasking_Total          : Natural := 0;
      Fingerprint_Total      : Natural := 0;
      Multiple_Total         : Natural := 0;
      Indeterminate_Total    : Natural := 0;
      Fingerprint            : Natural := 0;
   end record;

end Editor.Ada_Shared_State_Recheck_Eligibility_Legality;
