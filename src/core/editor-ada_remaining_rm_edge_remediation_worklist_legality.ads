with Ada.Containers.Vectors;
with Editor.Ada_Remaining_RM_Edge_Stabilized_Diagnostic_Integration;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Remaining_RM_Edge_Remediation_Worklist_Legality is

   --  Case 1286 remediation worklist for remaining Ada RM edge blockers.
   --
   --  This package consumes Case 1285 remaining RM edge stabilized diagnostics
   --  and converts each blocker into deterministic prerequisite work before a
   --  later bounded recheck may trust the result.  Accepted rows remain current
   --  semantic evidence.  Remaining-edge, stabilized-closure, fingerprint,
   --  multiple-blocker, recheck-required, and indeterminate families are kept
   --  distinct so downstream consumers cannot flatten hard Ada RM edge blockers.

   package Diagnostics renames Editor.Ada_Remaining_RM_Edge_Stabilized_Diagnostic_Integration;
   package Edge renames Diagnostics.Edge;

   subtype Remaining_RM_Edge_Worklist_Diagnostic_Status is Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Status;
   subtype Remaining_RM_Edge_Worklist_Diagnostic_Family is Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Family;
   subtype Remaining_RM_Edge_Kind is Diagnostics.Remaining_RM_Edge_Kind;
   subtype Remaining_RM_Edge_Blocker_Family is Diagnostics.Remaining_RM_Edge_Blocker_Family;

   type Remaining_RM_Edge_Worklist_Id is new Natural;
   No_Remaining_RM_Edge_Worklist_Item : constant Remaining_RM_Edge_Worklist_Id := 0;

   type Remaining_RM_Edge_Worklist_Action is
     (Remaining_RM_Edge_Worklist_No_Action,
      Remaining_RM_Edge_Worklist_Keep_Current_Evidence,
      Remaining_RM_Edge_Worklist_Resolve_Remaining_Edge,
      Remaining_RM_Edge_Worklist_Resolve_Stabilized_Closure,
      Remaining_RM_Edge_Worklist_Recheck_Source_Fingerprint,
      Remaining_RM_Edge_Worklist_Recheck_Substitution_Fingerprint,
      Remaining_RM_Edge_Worklist_Split_Multiple_Blockers,
      Remaining_RM_Edge_Worklist_Recheck_Required,
      Remaining_RM_Edge_Worklist_Recheck_Indeterminate);

   type Remaining_RM_Edge_Worklist_Priority is
     (Remaining_RM_Edge_Worklist_Priority_None,
      Remaining_RM_Edge_Worklist_Priority_Current_Evidence,
      Remaining_RM_Edge_Worklist_Priority_Remaining_Edge,
      Remaining_RM_Edge_Worklist_Priority_Stabilized_Closure,
      Remaining_RM_Edge_Worklist_Priority_Fingerprint,
      Remaining_RM_Edge_Worklist_Priority_Multiple,
      Remaining_RM_Edge_Worklist_Priority_Recheck,
      Remaining_RM_Edge_Worklist_Priority_Indeterminate);

   type Remaining_RM_Edge_Worklist_Item is record
      Id                         : Remaining_RM_Edge_Worklist_Id := No_Remaining_RM_Edge_Worklist_Item;
      Diagnostic_Row             : Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Id := Diagnostics.No_Remaining_RM_Edge_Stabilized_Diagnostic;
      Diagnostic_Status          : Remaining_RM_Edge_Worklist_Diagnostic_Status := Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Not_Checked;
      Diagnostic_Family          : Remaining_RM_Edge_Worklist_Diagnostic_Family := Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Unknown;
      Remaining_Edge_Kind        : Remaining_RM_Edge_Kind := Edge.Remaining_RM_Edge_Unknown;
      Remaining_Edge_Blocker     : Remaining_RM_Edge_Blocker_Family := Edge.Remaining_RM_Edge_Blocker_None;
      Action                     : Remaining_RM_Edge_Worklist_Action := Remaining_RM_Edge_Worklist_No_Action;
      Priority                   : Remaining_RM_Edge_Worklist_Priority := Remaining_RM_Edge_Worklist_Priority_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Current_Evidence           : Boolean := False;
      Ready_For_Recheck          : Boolean := False;
      Blocks_Downstream          : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Edge_Fingerprint           : Natural := 0;
      Closure_Fingerprint        : Natural := 0;
      Diagnostic_Fingerprint     : Natural := 0;
      Worklist_Fingerprint       : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Remaining_RM_Edge_Worklist_Model is private;
   type Remaining_RM_Edge_Worklist_Set is private;

   procedure Clear (Model : in out Remaining_RM_Edge_Worklist_Model);

   function Build
     (Diagnostics_Model : Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Model)
      return Remaining_RM_Edge_Worklist_Model;

   function Count (Model : Remaining_RM_Edge_Worklist_Model) return Natural;
   function Row_At
     (Model : Remaining_RM_Edge_Worklist_Model;
      Index : Positive) return Remaining_RM_Edge_Worklist_Item;

   function Query_Count (Set : Remaining_RM_Edge_Worklist_Set) return Natural;
   function Query_At
     (Set   : Remaining_RM_Edge_Worklist_Set;
      Index : Positive) return Remaining_RM_Edge_Worklist_Item;

   function Query_Action
     (Model  : Remaining_RM_Edge_Worklist_Model;
      Action : Remaining_RM_Edge_Worklist_Action) return Remaining_RM_Edge_Worklist_Set;
   function Query_Family
     (Model  : Remaining_RM_Edge_Worklist_Model;
      Family : Remaining_RM_Edge_Worklist_Diagnostic_Family) return Remaining_RM_Edge_Worklist_Set;
   function Query_Priority
     (Model    : Remaining_RM_Edge_Worklist_Model;
      Priority : Remaining_RM_Edge_Worklist_Priority) return Remaining_RM_Edge_Worklist_Set;
   function Query_Edge_Blocker
     (Model   : Remaining_RM_Edge_Worklist_Model;
      Blocker : Remaining_RM_Edge_Blocker_Family) return Remaining_RM_Edge_Worklist_Set;
   function Query_Node
     (Model : Remaining_RM_Edge_Worklist_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Remaining_RM_Edge_Worklist_Set;
   function Query_Source_Fingerprint
     (Model       : Remaining_RM_Edge_Worklist_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Worklist_Set;

   function Count_Action
     (Model  : Remaining_RM_Edge_Worklist_Model;
      Action : Remaining_RM_Edge_Worklist_Action) return Natural;
   function Count_Family
     (Model  : Remaining_RM_Edge_Worklist_Model;
      Family : Remaining_RM_Edge_Worklist_Diagnostic_Family) return Natural;
   function Count_Priority
     (Model    : Remaining_RM_Edge_Worklist_Model;
      Priority : Remaining_RM_Edge_Worklist_Priority) return Natural;

   function Current_Evidence_Count (Model : Remaining_RM_Edge_Worklist_Model) return Natural;
   function Ready_For_Recheck_Count (Model : Remaining_RM_Edge_Worklist_Model) return Natural;
   function Blocked_Downstream_Count (Model : Remaining_RM_Edge_Worklist_Model) return Natural;
   function Fingerprint_Mismatch_Count (Model : Remaining_RM_Edge_Worklist_Model) return Natural;
   function Indeterminate_Count (Model : Remaining_RM_Edge_Worklist_Model) return Natural;
   function Stable_Fingerprint (Model : Remaining_RM_Edge_Worklist_Model) return Natural;

   function Is_Current_Evidence (Item : Remaining_RM_Edge_Worklist_Item) return Boolean;
   function Is_Ready_For_Recheck (Item : Remaining_RM_Edge_Worklist_Item) return Boolean;
   function Blocks_Downstream (Item : Remaining_RM_Edge_Worklist_Item) return Boolean;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Remaining_RM_Edge_Worklist_Item);

   type Remaining_RM_Edge_Worklist_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Remaining_RM_Edge_Worklist_Model is record
      Rows                       : Row_Vectors.Vector;
      Current_Evidence_Total     : Natural := 0;
      Ready_For_Recheck_Total    : Natural := 0;
      Blocked_Downstream_Total   : Natural := 0;
      Fingerprint_Mismatch_Total : Natural := 0;
      Indeterminate_Total        : Natural := 0;
      Stable_Fingerprint_Value   : Natural := 0;
   end record;

end Editor.Ada_Remaining_RM_Edge_Remediation_Worklist_Legality;
