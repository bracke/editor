with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Integration;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Provenance is

   --  Pass1293 provenance for stabilized remaining RM edge closure diagnostics.
   --
   --  This package links Pass1292 stabilized remaining-edge closure diagnostic
   --  rows back through the stabilized closure, stabilization gate,
   --  convergence, recheck application, eligibility, remediation worklist,
   --  earlier remaining-edge diagnostic row, and the original remaining-edge
   --  precision evidence.  It preserves blocker-family identity for
   --  remaining-edge, stabilized-closure, source/substitution fingerprint,
   --  multiple-prerequisite, recheck-required, and indeterminate blockers.

   package Diagnostics renames Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Integration;
   package Closure renames Diagnostics.Closure;
   package Edge renames Diagnostics.Edge;

   subtype Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Id is Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Id;
   subtype Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status is Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status;
   subtype Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Family is Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Family;
   subtype Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Severity is Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Severity;
   subtype Remaining_RM_Edge_Stabilized_Closure_Family is Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Family;
   subtype Remaining_RM_Edge_Kind is Diagnostics.Remaining_RM_Edge_Kind;
   subtype Remaining_RM_Edge_Blocker_Family is Diagnostics.Remaining_RM_Edge_Blocker_Family;

   type Remaining_RM_Edge_Stabilized_Closure_Provenance_Id is new Natural;
   No_Remaining_RM_Edge_Stabilized_Closure_Provenance : constant Remaining_RM_Edge_Stabilized_Closure_Provenance_Id := 0;

   type Remaining_RM_Edge_Stabilized_Closure_Provenance_Status is
     (Remaining_RM_Edge_Stabilized_Closure_Provenance_Not_Checked,
      Remaining_RM_Edge_Stabilized_Closure_Provenance_Withheld_Current_Evidence,
      Remaining_RM_Edge_Stabilized_Closure_Provenance_Emitted_Error,
      Remaining_RM_Edge_Stabilized_Closure_Provenance_Emitted_Warning,
      Remaining_RM_Edge_Stabilized_Closure_Provenance_Recheck_Required,
      Remaining_RM_Edge_Stabilized_Closure_Provenance_Indeterminate,
      Remaining_RM_Edge_Stabilized_Closure_Provenance_Multiple_Prerequisites);

   type Remaining_RM_Edge_Stabilized_Closure_Provenance_Stage is
     (Remaining_RM_Edge_Stabilized_Closure_Stage_None,
      Remaining_RM_Edge_Stabilized_Closure_Stage_Original_Remaining_Edge,
      Remaining_RM_Edge_Stabilized_Closure_Stage_Stabilized_Diagnostic,
      Remaining_RM_Edge_Stabilized_Closure_Stage_Remediation_Worklist,
      Remaining_RM_Edge_Stabilized_Closure_Stage_Recheck_Eligibility,
      Remaining_RM_Edge_Stabilized_Closure_Stage_Recheck_Application,
      Remaining_RM_Edge_Stabilized_Closure_Stage_Recheck_Convergence,
      Remaining_RM_Edge_Stabilized_Closure_Stage_Stabilization_Gate,
      Remaining_RM_Edge_Stabilized_Closure_Stage_Stabilized_Closure,
      Remaining_RM_Edge_Stabilized_Closure_Stage_Stabilized_Closure_Diagnostic);

   type Remaining_RM_Edge_Stabilized_Closure_Provenance_Blocker is
     (Remaining_RM_Edge_Stabilized_Closure_Blocker_None,
      Remaining_RM_Edge_Stabilized_Closure_Blocker_Remaining_Edge,
      Remaining_RM_Edge_Stabilized_Closure_Blocker_Stabilized_Closure,
      Remaining_RM_Edge_Stabilized_Closure_Blocker_Source_Fingerprint,
      Remaining_RM_Edge_Stabilized_Closure_Blocker_Substitution_Fingerprint,
      Remaining_RM_Edge_Stabilized_Closure_Blocker_Multiple,
      Remaining_RM_Edge_Stabilized_Closure_Blocker_Recheck_Required,
      Remaining_RM_Edge_Stabilized_Closure_Blocker_Indeterminate,
      Remaining_RM_Edge_Stabilized_Closure_Blocker_Unknown);

   type Remaining_RM_Edge_Stabilized_Closure_Provenance_Row is record
      Id                         : Remaining_RM_Edge_Stabilized_Closure_Provenance_Id := No_Remaining_RM_Edge_Stabilized_Closure_Provenance;
      Stabilized_Diagnostic      : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Id := Diagnostics.No_Remaining_RM_Edge_Stabilized_Closure_Diagnostic;
      Closure_Row                : Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Id := Closure.No_Remaining_RM_Edge_Stabilized_Closure;
      Stabilization_Id           : Closure.Gate.Remaining_RM_Edge_Stabilization_Gate_Id := Closure.Gate.No_Remaining_RM_Edge_Stabilization_Gate;
      Convergence_Id             : Closure.Gate.Conv.Remaining_RM_Edge_Convergence_Id := Closure.Gate.Conv.No_Remaining_RM_Edge_Convergence;
      Application_Id             : Closure.Gate.Conv.Apply.Remaining_RM_Edge_Application_Id := Closure.Gate.Conv.Apply.No_Remaining_RM_Edge_Application;
      Eligibility_Id             : Closure.Gate.Conv.Apply.Recheck.Remaining_RM_Edge_Recheck_Id := Closure.Gate.Conv.Apply.Recheck.No_Remaining_RM_Edge_Recheck;
      Worklist_Item              : Closure.Gate.Conv.Apply.Recheck.Worklist.Remaining_RM_Edge_Worklist_Id := Closure.Gate.Conv.Apply.Recheck.Worklist.No_Remaining_RM_Edge_Worklist_Item;
      Prior_Diagnostic_Row       : Closure.Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Id := Closure.Diagnostics.No_Remaining_RM_Edge_Stabilized_Diagnostic;
      Closure_Status             : Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Status := Closure.Remaining_RM_Edge_Stabilized_Closure_Not_Checked;
      Diagnostic_Status          : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status := Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Not_Checked;
      Diagnostic_Family          : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Family := Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Unknown;
      Diagnostic_Severity        : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Severity := Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Warning;
      Closure_Family             : Remaining_RM_Edge_Stabilized_Closure_Family := Closure.Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Unknown;
      Status                     : Remaining_RM_Edge_Stabilized_Closure_Provenance_Status := Remaining_RM_Edge_Stabilized_Closure_Provenance_Not_Checked;
      Stage                      : Remaining_RM_Edge_Stabilized_Closure_Provenance_Stage := Remaining_RM_Edge_Stabilized_Closure_Stage_None;
      Blocker                    : Remaining_RM_Edge_Stabilized_Closure_Provenance_Blocker := Remaining_RM_Edge_Stabilized_Closure_Blocker_Unknown;
      Remaining_Edge_Kind        : Remaining_RM_Edge_Kind := Edge.Remaining_RM_Edge_Unknown;
      Remaining_Edge_Blocker     : Remaining_RM_Edge_Blocker_Family := Edge.Remaining_RM_Edge_Blocker_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Fingerprint         : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Edge_Fingerprint           : Natural := 0;
      Consumer_Closure_Fingerprint : Natural := 0;
      Prior_Diagnostic_Fingerprint : Natural := 0;
      Worklist_Fingerprint       : Natural := 0;
      Eligibility_Fingerprint    : Natural := 0;
      Application_Fingerprint    : Natural := 0;
      Convergence_Fingerprint    : Natural := 0;
      Stabilization_Fingerprint  : Natural := 0;
      Closure_Fingerprint        : Natural := 0;
      Diagnostic_Fingerprint     : Natural := 0;
      Provenance_Fingerprint     : Natural := 0;
      Emitted                    : Boolean := False;
      Withheld_Current           : Boolean := False;
      Requires_Recheck           : Boolean := False;
      Blocks_Downstream          : Boolean := False;
      Full_Chain_Linked          : Boolean := False;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
      Chain_Summary              : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Remaining_RM_Edge_Stabilized_Closure_Provenance_Model is private;
   type Remaining_RM_Edge_Stabilized_Closure_Provenance_Set is private;

   procedure Clear (Model : in out Remaining_RM_Edge_Stabilized_Closure_Provenance_Model);

   function Build
     (Diagnostic_Model : Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model)
      return Remaining_RM_Edge_Stabilized_Closure_Provenance_Model;

   function Row_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model) return Natural;
   function Row_At
     (Model : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model;
      Index : Positive) return Remaining_RM_Edge_Stabilized_Closure_Provenance_Row;

   function Query_Count (Set : Remaining_RM_Edge_Stabilized_Closure_Provenance_Set) return Natural;
   function Query_At
     (Set   : Remaining_RM_Edge_Stabilized_Closure_Provenance_Set;
      Index : Positive) return Remaining_RM_Edge_Stabilized_Closure_Provenance_Row;

   function Query_Status
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model;
      Status : Remaining_RM_Edge_Stabilized_Closure_Provenance_Status)
      return Remaining_RM_Edge_Stabilized_Closure_Provenance_Set;
   function Query_Blocker
     (Model   : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model;
      Blocker : Remaining_RM_Edge_Stabilized_Closure_Provenance_Blocker)
      return Remaining_RM_Edge_Stabilized_Closure_Provenance_Set;
   function Query_Stage
     (Model : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model;
      Stage : Remaining_RM_Edge_Stabilized_Closure_Provenance_Stage)
      return Remaining_RM_Edge_Stabilized_Closure_Provenance_Set;
   function Query_Node
     (Model : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return Remaining_RM_Edge_Stabilized_Closure_Provenance_Set;
   function Query_Source_Fingerprint
     (Model       : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Stabilized_Closure_Provenance_Set;

   function Count_Status
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model;
      Status : Remaining_RM_Edge_Stabilized_Closure_Provenance_Status) return Natural;
   function Count_Blocker
     (Model   : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model;
      Blocker : Remaining_RM_Edge_Stabilized_Closure_Provenance_Blocker) return Natural;
   function Count_Stage
     (Model : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model;
      Stage : Remaining_RM_Edge_Stabilized_Closure_Provenance_Stage) return Natural;

   function Withheld_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model) return Natural;
   function Emitted_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model) return Natural;
   function Error_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model) return Natural;
   function Warning_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model) return Natural;
   function Recheck_Required_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model) return Natural;
   function Indeterminate_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model) return Natural;
   function Multiple_Prerequisite_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model) return Natural;
   function Full_Chain_Link_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model) return Natural;
   function Fingerprint (Model : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Remaining_RM_Edge_Stabilized_Closure_Provenance_Row);

   type Remaining_RM_Edge_Stabilized_Closure_Provenance_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Remaining_RM_Edge_Stabilized_Closure_Provenance_Model is record
      Rows                   : Row_Vectors.Vector;
      Withheld_Total         : Natural := 0;
      Emitted_Total          : Natural := 0;
      Error_Total            : Natural := 0;
      Warning_Total          : Natural := 0;
      Recheck_Total          : Natural := 0;
      Indeterminate_Total    : Natural := 0;
      Multiple_Total         : Natural := 0;
      Full_Chain_Total       : Natural := 0;
      Fingerprint            : Natural := 0;
   end record;

end Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Provenance;
