with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Provenance is

   --  Case 1282 provenance for stabilized direct RM-completion closure-consumer
   --  diagnostics.
   --
   --  This package links Case 1281 diagnostic rows back through the stabilized
   --  closure, stabilization gate, convergence, recheck application,
   --  eligibility, remediation worklist, and original direct-consumer diagnostic
   --  row.  It preserves blocker-family identity so cross-unit, elaboration,
   --  accessibility, exception/finalization, overload/type,
   --  representation/freezing, tasking/protected, dataflow, predicate,
   --  AST/coverage, generic-substitution, fingerprint, multiple-prerequisite,
   --  and indeterminate blockers can be traced without projection loss.

   package Diag renames Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration;

   type RM_Closure_Consumer_Stabilized_Provenance_Id is new Natural;
   No_RM_Closure_Consumer_Stabilized_Provenance : constant RM_Closure_Consumer_Stabilized_Provenance_Id := 0;

   subtype RM_Closure_Consumer_Stabilized_Diagnostic_Id is Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Id;
   subtype RM_Closure_Consumer_Stabilized_Diagnostic_Status is Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Status;
   subtype RM_Closure_Consumer_Stabilized_Diagnostic_Family is Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Family;
   subtype RM_Closure_Consumer_Closure_Family is Diag.RM_Closure_Consumer_Closure_Family;

   type RM_Closure_Consumer_Stabilized_Provenance_Status is
     (RM_Closure_Consumer_Stabilized_Provenance_Not_Checked,
      RM_Closure_Consumer_Stabilized_Provenance_Withheld_Current_Evidence,
      RM_Closure_Consumer_Stabilized_Provenance_Emitted_Error,
      RM_Closure_Consumer_Stabilized_Provenance_Emitted_Warning,
      RM_Closure_Consumer_Stabilized_Provenance_Recheck_Required,
      RM_Closure_Consumer_Stabilized_Provenance_Indeterminate,
      RM_Closure_Consumer_Stabilized_Provenance_Multiple_Prerequisites);

   type RM_Closure_Consumer_Stabilized_Provenance_Stage is
     (RM_Closure_Consumer_Stabilized_Stage_None,
      RM_Closure_Consumer_Stabilized_Stage_Original_Diagnostic,
      RM_Closure_Consumer_Stabilized_Stage_Remediation_Worklist,
      RM_Closure_Consumer_Stabilized_Stage_Recheck_Eligibility,
      RM_Closure_Consumer_Stabilized_Stage_Recheck_Application,
      RM_Closure_Consumer_Stabilized_Stage_Recheck_Convergence,
      RM_Closure_Consumer_Stabilized_Stage_Stabilization_Gate,
      RM_Closure_Consumer_Stabilized_Stage_Stabilized_Closure,
      RM_Closure_Consumer_Stabilized_Stage_Stabilized_Diagnostic);

   type RM_Closure_Consumer_Stabilized_Provenance_Blocker is
     (RM_Closure_Consumer_Stabilized_Blocker_None,
      RM_Closure_Consumer_Stabilized_Blocker_Stale_Or_Fingerprint,
      RM_Closure_Consumer_Stabilized_Blocker_AST_Or_Coverage,
      RM_Closure_Consumer_Stabilized_Blocker_Cross_Unit,
      RM_Closure_Consumer_Stabilized_Blocker_Generic_Substitution,
      RM_Closure_Consumer_Stabilized_Blocker_Dataflow,
      RM_Closure_Consumer_Stabilized_Blocker_Volatile_Atomic,
      RM_Closure_Consumer_Stabilized_Blocker_Overload_Type,
      RM_Closure_Consumer_Stabilized_Blocker_Representation,
      RM_Closure_Consumer_Stabilized_Blocker_Tasking_Protected,
      RM_Closure_Consumer_Stabilized_Blocker_Elaboration,
      RM_Closure_Consumer_Stabilized_Blocker_Accessibility,
      RM_Closure_Consumer_Stabilized_Blocker_Discriminant_Variant,
      RM_Closure_Consumer_Stabilized_Blocker_Exception_Finalization,
      RM_Closure_Consumer_Stabilized_Blocker_Renaming_Alias,
      RM_Closure_Consumer_Stabilized_Blocker_Predicate_Invariant,
      RM_Closure_Consumer_Stabilized_Blocker_Multiple,
      RM_Closure_Consumer_Stabilized_Blocker_Indeterminate,
      RM_Closure_Consumer_Stabilized_Blocker_Recheck_Required,
      RM_Closure_Consumer_Stabilized_Blocker_Unknown);

   type RM_Closure_Consumer_Stabilized_Provenance_Row is record
      Id                       : RM_Closure_Consumer_Stabilized_Provenance_Id := No_RM_Closure_Consumer_Stabilized_Provenance;
      Stabilized_Diagnostic    : Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Id := Diag.No_RM_Closure_Consumer_Stabilized_Diagnostic;
      Closure_Id               : Diag.RM_Closure_Consumer_Stabilized_Closure_Id := Diag.Closure.No_RM_Closure_Consumer_Stabilized_Closure;
      Stabilization_Id         : Diag.Closure.Gate.RM_Closure_Consumer_Stabilization_Gate_Id := Diag.Closure.Gate.No_RM_Closure_Consumer_Stabilization_Gate;
      Convergence_Id           : Diag.Closure.Gate.Conv.RM_Closure_Consumer_Convergence_Id := Diag.Closure.Gate.Conv.No_RM_Closure_Consumer_Convergence;
      Application_Id           : Diag.Closure.Gate.Conv.Apply.RM_Closure_Consumer_Application_Id := Diag.Closure.Gate.Conv.Apply.No_RM_Closure_Consumer_Application;
      Eligibility_Id           : Diag.Closure.Gate.Conv.Apply.Recheck.RM_Closure_Consumer_Recheck_Id := Diag.Closure.Gate.Conv.Apply.Recheck.No_RM_Closure_Consumer_Recheck;
      Worklist_Item            : Diag.Closure.Gate.Conv.Apply.Recheck.Worklist.RM_Closure_Consumer_Worklist_Id := Diag.Closure.Gate.Conv.Apply.Recheck.Worklist.No_RM_Closure_Consumer_Worklist_Item;
      Original_Diagnostic      : Diag.Closure.Gate.Conv.Apply.Recheck.Worklist.Diagnostics.RM_Closure_Consumer_Diagnostic_Id := Diag.Closure.Gate.Conv.Apply.Recheck.Worklist.Diagnostics.No_RM_Closure_Consumer_Diagnostic;
      Diagnostic_Status        : RM_Closure_Consumer_Stabilized_Diagnostic_Status := Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Not_Checked;
      Diagnostic_Family        : RM_Closure_Consumer_Stabilized_Diagnostic_Family := Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Unknown;
      Closure_Family           : RM_Closure_Consumer_Closure_Family := Diag.Closure.Gate.Conv.Apply.Recheck.Worklist.Diagnostics.RM_Closure_Consumer_Diagnostic_Unknown;
      Status                   : RM_Closure_Consumer_Stabilized_Provenance_Status := RM_Closure_Consumer_Stabilized_Provenance_Not_Checked;
      Stage                    : RM_Closure_Consumer_Stabilized_Provenance_Stage := RM_Closure_Consumer_Stabilized_Stage_None;
      Blocker                  : RM_Closure_Consumer_Stabilized_Provenance_Blocker := RM_Closure_Consumer_Stabilized_Blocker_Unknown;
      Node                     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Fingerprint       : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Semantic_Fingerprint     : Natural := 0;
      Diagnostic_Fingerprint   : Natural := 0;
      Closure_Fingerprint      : Natural := 0;
      Provenance_Fingerprint   : Natural := 0;
      Emitted                  : Boolean := False;
      Withheld_Current         : Boolean := False;
      Requires_Recheck         : Boolean := False;
      Blocks_Downstream        : Boolean := False;
      Start_Line               : Positive := 1;
      Start_Column             : Positive := 1;
      End_Line                 : Positive := 1;
      End_Column               : Positive := 1;
      Message                  : Ada.Strings.Unbounded.Unbounded_String;
      Chain_Summary            : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type RM_Closure_Consumer_Stabilized_Provenance_Model is private;
   type RM_Closure_Consumer_Stabilized_Provenance_Set is private;

   procedure Clear (Model : in out RM_Closure_Consumer_Stabilized_Provenance_Model);

   function Build
     (Diagnostics : Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Model)
      return RM_Closure_Consumer_Stabilized_Provenance_Model;

   function Row_Count (Model : RM_Closure_Consumer_Stabilized_Provenance_Model) return Natural;
   function Row_At
     (Model : RM_Closure_Consumer_Stabilized_Provenance_Model;
      Index : Positive) return RM_Closure_Consumer_Stabilized_Provenance_Row;

   function Query_Count (Set : RM_Closure_Consumer_Stabilized_Provenance_Set) return Natural;
   function Query_At
     (Set   : RM_Closure_Consumer_Stabilized_Provenance_Set;
      Index : Positive) return RM_Closure_Consumer_Stabilized_Provenance_Row;

   function Query_Status
     (Model  : RM_Closure_Consumer_Stabilized_Provenance_Model;
      Status : RM_Closure_Consumer_Stabilized_Provenance_Status)
      return RM_Closure_Consumer_Stabilized_Provenance_Set;
   function Query_Blocker
     (Model   : RM_Closure_Consumer_Stabilized_Provenance_Model;
      Blocker : RM_Closure_Consumer_Stabilized_Provenance_Blocker)
      return RM_Closure_Consumer_Stabilized_Provenance_Set;
   function Query_Stage
     (Model : RM_Closure_Consumer_Stabilized_Provenance_Model;
      Stage : RM_Closure_Consumer_Stabilized_Provenance_Stage)
      return RM_Closure_Consumer_Stabilized_Provenance_Set;
   function Query_Node
     (Model : RM_Closure_Consumer_Stabilized_Provenance_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return RM_Closure_Consumer_Stabilized_Provenance_Set;

   function Count_Status
     (Model  : RM_Closure_Consumer_Stabilized_Provenance_Model;
      Status : RM_Closure_Consumer_Stabilized_Provenance_Status) return Natural;
   function Count_Blocker
     (Model   : RM_Closure_Consumer_Stabilized_Provenance_Model;
      Blocker : RM_Closure_Consumer_Stabilized_Provenance_Blocker) return Natural;
   function Count_Stage
     (Model : RM_Closure_Consumer_Stabilized_Provenance_Model;
      Stage : RM_Closure_Consumer_Stabilized_Provenance_Stage) return Natural;

   function Withheld_Count (Model : RM_Closure_Consumer_Stabilized_Provenance_Model) return Natural;
   function Emitted_Count (Model : RM_Closure_Consumer_Stabilized_Provenance_Model) return Natural;
   function Error_Count (Model : RM_Closure_Consumer_Stabilized_Provenance_Model) return Natural;
   function Warning_Count (Model : RM_Closure_Consumer_Stabilized_Provenance_Model) return Natural;
   function Recheck_Count (Model : RM_Closure_Consumer_Stabilized_Provenance_Model) return Natural;
   function Indeterminate_Count (Model : RM_Closure_Consumer_Stabilized_Provenance_Model) return Natural;
   function Multiple_Count (Model : RM_Closure_Consumer_Stabilized_Provenance_Model) return Natural;
   function Full_Chain_Link_Count (Model : RM_Closure_Consumer_Stabilized_Provenance_Model) return Natural;
   function Fingerprint (Model : RM_Closure_Consumer_Stabilized_Provenance_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => RM_Closure_Consumer_Stabilized_Provenance_Row);

   type RM_Closure_Consumer_Stabilized_Provenance_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type RM_Closure_Consumer_Stabilized_Provenance_Model is record
      Rows                  : Row_Vectors.Vector;
      Withheld_Total        : Natural := 0;
      Emitted_Total         : Natural := 0;
      Error_Total           : Natural := 0;
      Warning_Total         : Natural := 0;
      Recheck_Total         : Natural := 0;
      Indeterminate_Total   : Natural := 0;
      Multiple_Total        : Natural := 0;
      Full_Chain_Link_Total : Natural := 0;
      Fingerprint           : Natural := 0;
   end record;

end Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Provenance;
