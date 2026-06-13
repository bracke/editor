with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Final_Semantic_Diagnostic_Provenance;
with Editor.Ada_Final_Semantic_Remediation_Diagnostic_Provenance_Search;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Final_Semantic_Remediation_Worklist_Legality is

   --  Pass1204 final semantic remediation worklist legality.
   --
   --  This package consumes Pass1203 remediation diagnostic provenance/search
   --  rows and turns prerequisite blocker evidence into a deterministic,
   --  bounded semantic re-analysis worklist.  It is not a UI hint layer: the
   --  worklist orders compiler-grade prerequisite repairs so downstream
   --  legality consumers cannot be revisited before stale evidence, coverage
   --  gaps, cross-unit closure, view barriers, generic replay, overload/type,
   --  representation/freezing, flow/contract, tasking/protected, elaboration,
   --  accessibility, and discriminant/variant evidence are available.

   package Remed_Prov renames Editor.Ada_Final_Semantic_Remediation_Diagnostic_Provenance_Search;
   package Final_Prov renames Editor.Ada_Final_Semantic_Diagnostic_Provenance;

   subtype Final_Blocker_Family is Final_Prov.Final_Blocker_Family;
   subtype Final_Remediation_Provenance_Status is Remed_Prov.Final_Remediation_Provenance_Status;
   subtype Final_Remediation_Provenance_Stage is Remed_Prov.Final_Remediation_Provenance_Stage;

   type Final_Remediation_Work_Id is new Natural;
   No_Final_Remediation_Work : constant Final_Remediation_Work_Id := 0;

   type Final_Remediation_Work_Status is
     (Final_Work_Not_Checked,
      Final_Work_Accepted_No_Action,
      Final_Work_Stale_Reanalysis_Required,
      Final_Work_AST_Repair_Required,
      Final_Work_Cross_Unit_Closure_Required,
      Final_Work_View_Barrier_Repair_Required,
      Final_Work_Generic_Replay_Required,
      Final_Work_Overload_Type_Required,
      Final_Work_Representation_Freezing_Required,
      Final_Work_Flow_Contract_Proof_Required,
      Final_Work_Tasking_Protected_Effects_Required,
      Final_Work_Elaboration_Closure_Required,
      Final_Work_Accessibility_Lifetime_Required,
      Final_Work_Discriminant_Variant_Required,
      Final_Work_Preserved_Semantic_Error,
      Final_Work_Multiple_Blockers_To_Split,
      Final_Work_Indeterminate_Degraded);

   type Final_Remediation_Work_Action is
     (Final_Work_Action_None,
      Final_Work_Action_Recompute_Snapshot,
      Final_Work_Action_Repair_AST_Coverage,
      Final_Work_Action_Resolve_Cross_Unit,
      Final_Work_Action_Resolve_View_Barrier,
      Final_Work_Action_Replay_Generic,
      Final_Work_Action_Resolve_Overload_Type,
      Final_Work_Action_Recheck_Representation_Freezing,
      Final_Work_Action_Prove_Flow_Contract,
      Final_Work_Action_Recheck_Tasking_Protected,
      Final_Work_Action_Recheck_Elaboration,
      Final_Work_Action_Recheck_Accessibility,
      Final_Work_Action_Recheck_Discriminants,
      Final_Work_Action_Preserve_Semantic_Error,
      Final_Work_Action_Split_Multiple_Blockers,
      Final_Work_Action_Degrade_Indeterminate);

   type Final_Remediation_Work_Phase is
     (Final_Work_Phase_None,
      Final_Work_Phase_Stale_Input,
      Final_Work_Phase_AST_And_Coverage,
      Final_Work_Phase_Cross_Unit_And_View,
      Final_Work_Phase_Generic_And_Type,
      Final_Work_Phase_Representation_And_Flow,
      Final_Work_Phase_Task_Elaboration_Access,
      Final_Work_Phase_Discriminant_And_Final,
      Final_Work_Phase_Preserved_Error,
      Final_Work_Phase_Indeterminate);

   type Final_Remediation_Work_Row is record
      Id                    : Final_Remediation_Work_Id := No_Final_Remediation_Work;
      Provenance_Id         : Remed_Prov.Final_Remediation_Provenance_Id := Remed_Prov.No_Final_Remediation_Provenance;
      Provenance_Status     : Final_Remediation_Provenance_Status := Remed_Prov.Final_Remediation_Provenance_Not_Checked;
      Provenance_Stage      : Final_Remediation_Provenance_Stage := Remed_Prov.Final_Remediation_Stage_None;
      Status                : Final_Remediation_Work_Status := Final_Work_Not_Checked;
      Action                : Final_Remediation_Work_Action := Final_Work_Action_None;
      Phase                 : Final_Remediation_Work_Phase := Final_Work_Phase_None;
      Blocker_Family        : Final_Blocker_Family := Final_Prov.Final_Blocker_None;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Priority              : Natural := 0;
      Dependency_Depth      : Natural := 0;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
      Provenance_Fingerprint : Natural := 0;
      Work_Fingerprint      : Natural := 0;
      Message               : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Final_Remediation_Worklist_Model is private;
   type Final_Remediation_Worklist_Set is private;

   procedure Clear (Model : in out Final_Remediation_Worklist_Model);

   function Build
     (Provenance : Remed_Prov.Final_Remediation_Provenance_Model)
      return Final_Remediation_Worklist_Model;

   function Row_Count (Model : Final_Remediation_Worklist_Model) return Natural;
   function Row_At
     (Model : Final_Remediation_Worklist_Model;
      Index : Positive) return Final_Remediation_Work_Row;

   function Query_Count (Set : Final_Remediation_Worklist_Set) return Natural;
   function Query_At
     (Set   : Final_Remediation_Worklist_Set;
      Index : Positive) return Final_Remediation_Work_Row;

   function Query_Status
     (Model  : Final_Remediation_Worklist_Model;
      Status : Final_Remediation_Work_Status) return Final_Remediation_Worklist_Set;
   function Query_Action
     (Model  : Final_Remediation_Worklist_Model;
      Action : Final_Remediation_Work_Action) return Final_Remediation_Worklist_Set;
   function Query_Phase
     (Model : Final_Remediation_Worklist_Model;
      Phase : Final_Remediation_Work_Phase) return Final_Remediation_Worklist_Set;
   function Query_Blocker
     (Model   : Final_Remediation_Worklist_Model;
      Blocker : Final_Blocker_Family) return Final_Remediation_Worklist_Set;
   function Query_Node
     (Model : Final_Remediation_Worklist_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_Remediation_Worklist_Set;

   function Count_Status
     (Model  : Final_Remediation_Worklist_Model;
      Status : Final_Remediation_Work_Status) return Natural;
   function Count_Action
     (Model  : Final_Remediation_Worklist_Model;
      Action : Final_Remediation_Work_Action) return Natural;
   function Count_Phase
     (Model : Final_Remediation_Worklist_Model;
      Phase : Final_Remediation_Work_Phase) return Natural;
   function Count_Blocker
     (Model   : Final_Remediation_Worklist_Model;
      Blocker : Final_Blocker_Family) return Natural;

   function Stale_Work_Count (Model : Final_Remediation_Worklist_Model) return Natural;
   function AST_Work_Count (Model : Final_Remediation_Worklist_Model) return Natural;
   function Cross_Unit_Work_Count (Model : Final_Remediation_Worklist_Model) return Natural;
   function Generic_Work_Count (Model : Final_Remediation_Worklist_Model) return Natural;
   function Overload_Work_Count (Model : Final_Remediation_Worklist_Model) return Natural;
   function Representation_Work_Count (Model : Final_Remediation_Worklist_Model) return Natural;
   function Flow_Work_Count (Model : Final_Remediation_Worklist_Model) return Natural;
   function Tasking_Work_Count (Model : Final_Remediation_Worklist_Model) return Natural;
   function Elaboration_Work_Count (Model : Final_Remediation_Worklist_Model) return Natural;
   function Accessibility_Work_Count (Model : Final_Remediation_Worklist_Model) return Natural;
   function Discriminant_Work_Count (Model : Final_Remediation_Worklist_Model) return Natural;
   function Preserved_Error_Count (Model : Final_Remediation_Worklist_Model) return Natural;
   function Multiple_Blocker_Count (Model : Final_Remediation_Worklist_Model) return Natural;
   function Indeterminate_Count (Model : Final_Remediation_Worklist_Model) return Natural;
   function Fingerprint (Model : Final_Remediation_Worklist_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Final_Remediation_Work_Row);

   type Final_Remediation_Worklist_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Final_Remediation_Worklist_Model is record
      Rows                   : Row_Vectors.Vector;
      Stale_Total            : Natural := 0;
      AST_Total              : Natural := 0;
      Cross_Unit_Total       : Natural := 0;
      Generic_Total          : Natural := 0;
      Overload_Total         : Natural := 0;
      Representation_Total   : Natural := 0;
      Flow_Total             : Natural := 0;
      Tasking_Total          : Natural := 0;
      Elaboration_Total      : Natural := 0;
      Accessibility_Total    : Natural := 0;
      Discriminant_Total     : Natural := 0;
      Preserved_Error_Total  : Natural := 0;
      Multiple_Blocker_Total : Natural := 0;
      Indeterminate_Total    : Natural := 0;
      Fingerprint            : Natural := 0;
   end record;

end Editor.Ada_Final_Semantic_Remediation_Worklist_Legality;
