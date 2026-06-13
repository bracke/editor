with Ada.Containers.Vectors;
with Editor.Ada_Remaining_RM_Edge_Remediation_Worklist_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Remaining_RM_Edge_Recheck_Eligibility_Legality is

   --  Pass1287 bounded recheck eligibility for remaining Ada RM edge blockers.
   --
   --  This package consumes the Pass1286 remaining-edge remediation worklist
   --  and turns prerequisite work into bounded recheck eligibility rows.  A
   --  remaining RM edge result can be trusted by later consumers only when its
   --  prerequisite work is either current evidence or eligible for a bounded
   --  recheck.  Remaining-edge, stabilized-closure, fingerprint,
   --  multiple-prerequisite, recheck-required, and indeterminate blockers are
   --  preserved as distinct families.

   package Worklist renames Editor.Ada_Remaining_RM_Edge_Remediation_Worklist_Legality;
   package Diagnostics renames Worklist.Diagnostics;
   package Edge renames Worklist.Edge;

   subtype Remaining_RM_Edge_Recheck_Diagnostic_Status is Worklist.Remaining_RM_Edge_Worklist_Diagnostic_Status;
   subtype Remaining_RM_Edge_Recheck_Diagnostic_Family is Worklist.Remaining_RM_Edge_Worklist_Diagnostic_Family;
   subtype Remaining_RM_Edge_Recheck_Work_Action is Worklist.Remaining_RM_Edge_Worklist_Action;
   subtype Remaining_RM_Edge_Recheck_Work_Priority is Worklist.Remaining_RM_Edge_Worklist_Priority;
   subtype Remaining_RM_Edge_Kind is Worklist.Remaining_RM_Edge_Kind;
   subtype Remaining_RM_Edge_Blocker_Family is Worklist.Remaining_RM_Edge_Blocker_Family;

   type Remaining_RM_Edge_Recheck_Id is new Natural;
   No_Remaining_RM_Edge_Recheck : constant Remaining_RM_Edge_Recheck_Id := 0;

   type Remaining_RM_Edge_Recheck_Status is
     (Remaining_RM_Edge_Recheck_Not_Checked,
      Remaining_RM_Edge_Recheck_Not_Required_Current,
      Remaining_RM_Edge_Recheck_Eligible_Now,
      Remaining_RM_Edge_Recheck_Blocked_By_Remaining_Edge,
      Remaining_RM_Edge_Recheck_Blocked_By_Stabilized_Closure,
      Remaining_RM_Edge_Recheck_Blocked_By_Source_Fingerprint,
      Remaining_RM_Edge_Recheck_Blocked_By_Substitution_Fingerprint,
      Remaining_RM_Edge_Recheck_Multiple_Prerequisites,
      Remaining_RM_Edge_Recheck_Recheck_Required,
      Remaining_RM_Edge_Recheck_Indeterminate);

   type Remaining_RM_Edge_Recheck_Action is
     (Remaining_RM_Edge_Recheck_Action_None,
      Remaining_RM_Edge_Recheck_Action_Keep_Current,
      Remaining_RM_Edge_Recheck_Action_Run_Now,
      Remaining_RM_Edge_Recheck_Action_Wait_For_Remaining_Edge,
      Remaining_RM_Edge_Recheck_Action_Wait_For_Stabilized_Closure,
      Remaining_RM_Edge_Recheck_Action_Wait_For_Source_Fingerprint,
      Remaining_RM_Edge_Recheck_Action_Wait_For_Substitution_Fingerprint,
      Remaining_RM_Edge_Recheck_Action_Split_Prerequisites,
      Remaining_RM_Edge_Recheck_Action_Wait_For_Recheck_Gate,
      Remaining_RM_Edge_Recheck_Action_Degrade);

   type Remaining_RM_Edge_Recheck_Row is record
      Id                         : Remaining_RM_Edge_Recheck_Id := No_Remaining_RM_Edge_Recheck;
      Worklist_Item              : Worklist.Remaining_RM_Edge_Worklist_Id := Worklist.No_Remaining_RM_Edge_Worklist_Item;
      Diagnostic_Row             : Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Id := Diagnostics.No_Remaining_RM_Edge_Stabilized_Diagnostic;
      Diagnostic_Status          : Remaining_RM_Edge_Recheck_Diagnostic_Status := Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Not_Checked;
      Diagnostic_Family          : Remaining_RM_Edge_Recheck_Diagnostic_Family := Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Unknown;
      Remaining_Edge_Kind        : Remaining_RM_Edge_Kind := Edge.Remaining_RM_Edge_Unknown;
      Remaining_Edge_Blocker     : Remaining_RM_Edge_Blocker_Family := Edge.Remaining_RM_Edge_Blocker_None;
      Work_Action                : Remaining_RM_Edge_Recheck_Work_Action := Worklist.Remaining_RM_Edge_Worklist_No_Action;
      Work_Priority              : Remaining_RM_Edge_Recheck_Work_Priority := Worklist.Remaining_RM_Edge_Worklist_Priority_None;
      Status                     : Remaining_RM_Edge_Recheck_Status := Remaining_RM_Edge_Recheck_Not_Checked;
      Action                     : Remaining_RM_Edge_Recheck_Action := Remaining_RM_Edge_Recheck_Action_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Current_Evidence           : Boolean := False;
      Eligible_Now               : Boolean := False;
      Blocks_Downstream          : Boolean := False;
      Priority_Rank              : Natural := 0;
      Source_Fingerprint         : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Edge_Fingerprint           : Natural := 0;
      Closure_Fingerprint        : Natural := 0;
      Diagnostic_Fingerprint     : Natural := 0;
      Worklist_Fingerprint       : Natural := 0;
      Eligibility_Fingerprint    : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Remaining_RM_Edge_Recheck_Model is private;
   type Remaining_RM_Edge_Recheck_Set is private;

   procedure Clear (Model : in out Remaining_RM_Edge_Recheck_Model);

   function Build
     (Work : Worklist.Remaining_RM_Edge_Worklist_Model)
      return Remaining_RM_Edge_Recheck_Model;

   function Row_Count (Model : Remaining_RM_Edge_Recheck_Model) return Natural;
   function Row_At
     (Model : Remaining_RM_Edge_Recheck_Model;
      Index : Positive) return Remaining_RM_Edge_Recheck_Row;

   function Query_Count (Set : Remaining_RM_Edge_Recheck_Set) return Natural;
   function Query_At
     (Set   : Remaining_RM_Edge_Recheck_Set;
      Index : Positive) return Remaining_RM_Edge_Recheck_Row;

   function Query_Status
     (Model  : Remaining_RM_Edge_Recheck_Model;
      Status : Remaining_RM_Edge_Recheck_Status) return Remaining_RM_Edge_Recheck_Set;
   function Query_Action
     (Model  : Remaining_RM_Edge_Recheck_Model;
      Action : Remaining_RM_Edge_Recheck_Action) return Remaining_RM_Edge_Recheck_Set;
   function Query_Family
     (Model  : Remaining_RM_Edge_Recheck_Model;
      Family : Remaining_RM_Edge_Recheck_Diagnostic_Family) return Remaining_RM_Edge_Recheck_Set;
   function Query_Node
     (Model : Remaining_RM_Edge_Recheck_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Remaining_RM_Edge_Recheck_Set;
   function Query_Source_Fingerprint
     (Model       : Remaining_RM_Edge_Recheck_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Recheck_Set;

   function Count_Status
     (Model  : Remaining_RM_Edge_Recheck_Model;
      Status : Remaining_RM_Edge_Recheck_Status) return Natural;
   function Count_Action
     (Model  : Remaining_RM_Edge_Recheck_Model;
      Action : Remaining_RM_Edge_Recheck_Action) return Natural;
   function Count_Family
     (Model  : Remaining_RM_Edge_Recheck_Model;
      Family : Remaining_RM_Edge_Recheck_Diagnostic_Family) return Natural;

   function Current_Evidence_Count (Model : Remaining_RM_Edge_Recheck_Model) return Natural;
   function Eligible_Count (Model : Remaining_RM_Edge_Recheck_Model) return Natural;
   function Blocked_Count (Model : Remaining_RM_Edge_Recheck_Model) return Natural;
   function Remaining_Edge_Blocked_Count (Model : Remaining_RM_Edge_Recheck_Model) return Natural;
   function Stabilized_Closure_Blocked_Count (Model : Remaining_RM_Edge_Recheck_Model) return Natural;
   function Fingerprint_Blocked_Count (Model : Remaining_RM_Edge_Recheck_Model) return Natural;
   function Multiple_Prerequisite_Count (Model : Remaining_RM_Edge_Recheck_Model) return Natural;
   function Recheck_Required_Count (Model : Remaining_RM_Edge_Recheck_Model) return Natural;
   function Indeterminate_Count (Model : Remaining_RM_Edge_Recheck_Model) return Natural;
   function Stable_Fingerprint (Model : Remaining_RM_Edge_Recheck_Model) return Natural;

   function Is_Current_Evidence (Row : Remaining_RM_Edge_Recheck_Row) return Boolean;
   function Is_Eligible_Now (Row : Remaining_RM_Edge_Recheck_Row) return Boolean;
   function Blocks_Downstream (Row : Remaining_RM_Edge_Recheck_Row) return Boolean;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Remaining_RM_Edge_Recheck_Row);

   type Remaining_RM_Edge_Recheck_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Remaining_RM_Edge_Recheck_Model is record
      Rows                         : Row_Vectors.Vector;
      Current_Evidence_Total       : Natural := 0;
      Eligible_Total               : Natural := 0;
      Blocked_Total                : Natural := 0;
      Remaining_Edge_Blocked_Total : Natural := 0;
      Closure_Blocked_Total        : Natural := 0;
      Fingerprint_Blocked_Total    : Natural := 0;
      Multiple_Total               : Natural := 0;
      Recheck_Required_Total       : Natural := 0;
      Indeterminate_Total          : Natural := 0;
      Stable_Fingerprint_Value     : Natural := 0;
   end record;

end Editor.Ada_Remaining_RM_Edge_Recheck_Eligibility_Legality;
