with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Final_Semantic_Diagnostic_Provenance;
with Editor.Ada_Final_Semantic_Remediation_Worklist_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Final_Semantic_Recheck_Eligibility_Legality is

   --  Case 1205 final semantic recheck eligibility legality.
   --
   --  This package consumes the Case 1204 remediation worklist and converts
   --  dependency-ordered prerequisite work into bounded recheck eligibility
   --  rows.  It prevents downstream semantic consumers from treating a row as
   --  ready for re-analysis while stale evidence, parser/AST coverage gaps,
   --  cross-unit closure failures, view barriers, generic replay gaps,
   --  overload/type evidence, representation/freezing evidence, flow/contract
   --  proof, tasking/protected effects, elaboration evidence, accessibility
   --  evidence, or discriminant/variant evidence remain unresolved.

   package Worklist renames Editor.Ada_Final_Semantic_Remediation_Worklist_Legality;
   package Final_Prov renames Editor.Ada_Final_Semantic_Diagnostic_Provenance;

   subtype Final_Blocker_Family is Final_Prov.Final_Blocker_Family;
   subtype Final_Remediation_Work_Status is Worklist.Final_Remediation_Work_Status;
   subtype Final_Remediation_Work_Action is Worklist.Final_Remediation_Work_Action;
   subtype Final_Remediation_Work_Phase is Worklist.Final_Remediation_Work_Phase;

   type Final_Recheck_Eligibility_Id is new Natural;
   No_Final_Recheck_Eligibility : constant Final_Recheck_Eligibility_Id := 0;

   type Final_Recheck_Eligibility_Status is
     (Final_Recheck_Not_Checked,
      Final_Recheck_Not_Required,
      Final_Recheck_Eligible_Now,
      Final_Recheck_Blocked_By_Stale_Input,
      Final_Recheck_Blocked_By_AST_Coverage,
      Final_Recheck_Blocked_By_Cross_Unit,
      Final_Recheck_Blocked_By_View_Barrier,
      Final_Recheck_Blocked_By_Generic_Replay,
      Final_Recheck_Blocked_By_Overload_Type,
      Final_Recheck_Blocked_By_Representation_Freezing,
      Final_Recheck_Blocked_By_Flow_Contract,
      Final_Recheck_Blocked_By_Tasking_Protected,
      Final_Recheck_Blocked_By_Elaboration,
      Final_Recheck_Blocked_By_Accessibility,
      Final_Recheck_Blocked_By_Discriminant_Variant,
      Final_Recheck_Preserved_Semantic_Error,
      Final_Recheck_Multiple_Prerequisites,
      Final_Recheck_Indeterminate);

   type Final_Recheck_Action is
     (Final_Recheck_Action_None,
      Final_Recheck_Action_Run_Now,
      Final_Recheck_Action_Wait_For_Snapshot,
      Final_Recheck_Action_Wait_For_AST_Coverage,
      Final_Recheck_Action_Wait_For_Cross_Unit,
      Final_Recheck_Action_Wait_For_View_Repair,
      Final_Recheck_Action_Wait_For_Generic_Replay,
      Final_Recheck_Action_Wait_For_Overload_Type,
      Final_Recheck_Action_Wait_For_Representation,
      Final_Recheck_Action_Wait_For_Flow_Contract,
      Final_Recheck_Action_Wait_For_Tasking,
      Final_Recheck_Action_Wait_For_Elaboration,
      Final_Recheck_Action_Wait_For_Accessibility,
      Final_Recheck_Action_Wait_For_Discriminants,
      Final_Recheck_Action_Preserve_Error,
      Final_Recheck_Action_Split_Prerequisites,
      Final_Recheck_Action_Degrade);

   type Final_Recheck_Eligibility_Row is record
      Id                      : Final_Recheck_Eligibility_Id := No_Final_Recheck_Eligibility;
      Work_Id                 : Worklist.Final_Remediation_Work_Id := Worklist.No_Final_Remediation_Work;
      Work_Status             : Final_Remediation_Work_Status := Worklist.Final_Work_Not_Checked;
      Work_Action             : Final_Remediation_Work_Action := Worklist.Final_Work_Action_None;
      Work_Phase              : Final_Remediation_Work_Phase := Worklist.Final_Work_Phase_None;
      Status                  : Final_Recheck_Eligibility_Status := Final_Recheck_Not_Checked;
      Action                  : Final_Recheck_Action := Final_Recheck_Action_None;
      Blocker_Family          : Final_Blocker_Family := Final_Prov.Final_Blocker_None;
      Node                    : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Priority                : Natural := 0;
      Dependency_Depth        : Natural := 0;
      Prerequisite_Depth      : Natural := 0;
      Start_Line              : Positive := 1;
      Start_Column            : Positive := 1;
      End_Line                : Positive := 1;
      End_Column              : Positive := 1;
      Source_Fingerprint      : Natural := 0;
      Work_Fingerprint        : Natural := 0;
      Eligibility_Fingerprint : Natural := 0;
      Message                 : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Final_Recheck_Eligibility_Model is private;
   type Final_Recheck_Eligibility_Set is private;

   procedure Clear (Model : in out Final_Recheck_Eligibility_Model);

   function Build
     (Work : Worklist.Final_Remediation_Worklist_Model)
      return Final_Recheck_Eligibility_Model;

   function Row_Count (Model : Final_Recheck_Eligibility_Model) return Natural;
   function Row_At
     (Model : Final_Recheck_Eligibility_Model;
      Index : Positive) return Final_Recheck_Eligibility_Row;

   function Query_Count (Set : Final_Recheck_Eligibility_Set) return Natural;
   function Query_At
     (Set   : Final_Recheck_Eligibility_Set;
      Index : Positive) return Final_Recheck_Eligibility_Row;

   function Query_Status
     (Model  : Final_Recheck_Eligibility_Model;
      Status : Final_Recheck_Eligibility_Status) return Final_Recheck_Eligibility_Set;
   function Query_Action
     (Model  : Final_Recheck_Eligibility_Model;
      Action : Final_Recheck_Action) return Final_Recheck_Eligibility_Set;
   function Query_Blocker
     (Model   : Final_Recheck_Eligibility_Model;
      Blocker : Final_Blocker_Family) return Final_Recheck_Eligibility_Set;
   function Query_Node
     (Model : Final_Recheck_Eligibility_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_Recheck_Eligibility_Set;

   function Count_Status
     (Model  : Final_Recheck_Eligibility_Model;
      Status : Final_Recheck_Eligibility_Status) return Natural;
   function Count_Action
     (Model  : Final_Recheck_Eligibility_Model;
      Action : Final_Recheck_Action) return Natural;
   function Count_Blocker
     (Model   : Final_Recheck_Eligibility_Model;
      Blocker : Final_Blocker_Family) return Natural;

   function Eligible_Count (Model : Final_Recheck_Eligibility_Model) return Natural;
   function Blocked_Count (Model : Final_Recheck_Eligibility_Model) return Natural;
   function Stale_Blocked_Count (Model : Final_Recheck_Eligibility_Model) return Natural;
   function AST_Blocked_Count (Model : Final_Recheck_Eligibility_Model) return Natural;
   function Cross_Unit_Blocked_Count (Model : Final_Recheck_Eligibility_Model) return Natural;
   function Generic_Blocked_Count (Model : Final_Recheck_Eligibility_Model) return Natural;
   function Overload_Blocked_Count (Model : Final_Recheck_Eligibility_Model) return Natural;
   function Representation_Blocked_Count (Model : Final_Recheck_Eligibility_Model) return Natural;
   function Flow_Blocked_Count (Model : Final_Recheck_Eligibility_Model) return Natural;
   function Tasking_Blocked_Count (Model : Final_Recheck_Eligibility_Model) return Natural;
   function Elaboration_Blocked_Count (Model : Final_Recheck_Eligibility_Model) return Natural;
   function Accessibility_Blocked_Count (Model : Final_Recheck_Eligibility_Model) return Natural;
   function Discriminant_Blocked_Count (Model : Final_Recheck_Eligibility_Model) return Natural;
   function Multiple_Prerequisite_Count (Model : Final_Recheck_Eligibility_Model) return Natural;
   function Indeterminate_Count (Model : Final_Recheck_Eligibility_Model) return Natural;
   function Fingerprint (Model : Final_Recheck_Eligibility_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Final_Recheck_Eligibility_Row);

   type Final_Recheck_Eligibility_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Final_Recheck_Eligibility_Model is record
      Rows                         : Row_Vectors.Vector;
      Eligible_Total               : Natural := 0;
      Blocked_Total                : Natural := 0;
      Stale_Total                  : Natural := 0;
      AST_Total                    : Natural := 0;
      Cross_Unit_Total             : Natural := 0;
      Generic_Total                : Natural := 0;
      Overload_Total               : Natural := 0;
      Representation_Total         : Natural := 0;
      Flow_Total                   : Natural := 0;
      Tasking_Total                : Natural := 0;
      Elaboration_Total            : Natural := 0;
      Accessibility_Total          : Natural := 0;
      Discriminant_Total           : Natural := 0;
      Multiple_Prerequisite_Total  : Natural := 0;
      Indeterminate_Total          : Natural := 0;
      Fingerprint                  : Natural := 0;
   end record;

end Editor.Ada_Final_Semantic_Recheck_Eligibility_Legality;
