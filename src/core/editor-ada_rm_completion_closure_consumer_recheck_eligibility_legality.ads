with Ada.Containers.Vectors;
with Editor.Ada_RM_Completion_Closure_Consumer_Remediation_Worklist_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Eligibility_Legality is

   --  Pass1275 recheck eligibility for the direct RM-completion closure
   --  consumer chain.
   --
   --  This package consumes the Pass1274 remediation worklist and turns
   --  ordered prerequisite work into bounded recheck eligibility rows.  A
   --  direct RM-completion closure consumer result may be rechecked only when
   --  the corresponding prerequisite family is eligible now; accepted current
   --  evidence remains non-recheck evidence, and unresolved blockers continue
   --  to block downstream semantic trust with their original family identity.

   package Worklist renames Editor.Ada_RM_Completion_Closure_Consumer_Remediation_Worklist_Legality;

   subtype RM_Closure_Consumer_Recheck_Family is Worklist.RM_Closure_Consumer_Worklist_Family;
   subtype RM_Closure_Consumer_Recheck_Work_Action is Worklist.RM_Closure_Consumer_Worklist_Action;
   subtype RM_Closure_Consumer_Recheck_Work_Priority is Worklist.RM_Closure_Consumer_Worklist_Priority;

   type RM_Closure_Consumer_Recheck_Id is new Natural;
   No_RM_Closure_Consumer_Recheck : constant RM_Closure_Consumer_Recheck_Id := 0;

   type RM_Closure_Consumer_Recheck_Status is
     (RM_Closure_Consumer_Recheck_Not_Checked,
      RM_Closure_Consumer_Recheck_Not_Required_Current,
      RM_Closure_Consumer_Recheck_Eligible_Now,
      RM_Closure_Consumer_Recheck_Blocked_By_Stale_Or_Fingerprint,
      RM_Closure_Consumer_Recheck_Blocked_By_AST_Or_Coverage,
      RM_Closure_Consumer_Recheck_Blocked_By_Cross_Unit,
      RM_Closure_Consumer_Recheck_Blocked_By_Generic_Substitution,
      RM_Closure_Consumer_Recheck_Blocked_By_Dataflow,
      RM_Closure_Consumer_Recheck_Blocked_By_Volatile_Atomic,
      RM_Closure_Consumer_Recheck_Blocked_By_Overload_Type,
      RM_Closure_Consumer_Recheck_Blocked_By_Representation,
      RM_Closure_Consumer_Recheck_Blocked_By_Tasking_Protected,
      RM_Closure_Consumer_Recheck_Blocked_By_Elaboration,
      RM_Closure_Consumer_Recheck_Blocked_By_Accessibility,
      RM_Closure_Consumer_Recheck_Blocked_By_Discriminant_Variant,
      RM_Closure_Consumer_Recheck_Blocked_By_Exception_Finalization,
      RM_Closure_Consumer_Recheck_Blocked_By_Renaming_Alias,
      RM_Closure_Consumer_Recheck_Blocked_By_Predicate_Invariant,
      RM_Closure_Consumer_Recheck_Blocked_By_Source_Fingerprint,
      RM_Closure_Consumer_Recheck_Blocked_By_Substitution_Fingerprint,
      RM_Closure_Consumer_Recheck_Multiple_Prerequisites,
      RM_Closure_Consumer_Recheck_Indeterminate);

   type RM_Closure_Consumer_Recheck_Action is
     (RM_Closure_Consumer_Recheck_Action_None,
      RM_Closure_Consumer_Recheck_Action_Keep_Current,
      RM_Closure_Consumer_Recheck_Action_Run_Now,
      RM_Closure_Consumer_Recheck_Action_Wait_For_Fingerprint,
      RM_Closure_Consumer_Recheck_Action_Wait_For_AST_Repair,
      RM_Closure_Consumer_Recheck_Action_Wait_For_Cross_Unit,
      RM_Closure_Consumer_Recheck_Action_Wait_For_Generic_Substitution,
      RM_Closure_Consumer_Recheck_Action_Wait_For_Dataflow,
      RM_Closure_Consumer_Recheck_Action_Wait_For_Volatile_Atomic,
      RM_Closure_Consumer_Recheck_Action_Wait_For_Overload_Type,
      RM_Closure_Consumer_Recheck_Action_Wait_For_Representation,
      RM_Closure_Consumer_Recheck_Action_Wait_For_Tasking_Protected,
      RM_Closure_Consumer_Recheck_Action_Wait_For_Elaboration,
      RM_Closure_Consumer_Recheck_Action_Wait_For_Accessibility,
      RM_Closure_Consumer_Recheck_Action_Wait_For_Discriminants,
      RM_Closure_Consumer_Recheck_Action_Wait_For_Exception_Finalization,
      RM_Closure_Consumer_Recheck_Action_Wait_For_Renaming,
      RM_Closure_Consumer_Recheck_Action_Wait_For_Predicate,
      RM_Closure_Consumer_Recheck_Action_Wait_For_Source_Fingerprint,
      RM_Closure_Consumer_Recheck_Action_Wait_For_Substitution_Fingerprint,
      RM_Closure_Consumer_Recheck_Action_Split_Prerequisites,
      RM_Closure_Consumer_Recheck_Action_Degrade);

   type RM_Closure_Consumer_Recheck_Row is record
      Id                         : RM_Closure_Consumer_Recheck_Id := No_RM_Closure_Consumer_Recheck;
      Worklist_Item              : Worklist.RM_Closure_Consumer_Worklist_Id := Worklist.No_RM_Closure_Consumer_Worklist_Item;
      Diagnostic_Row             : Worklist.Diagnostics.RM_Closure_Consumer_Diagnostic_Id := Worklist.Diagnostics.No_RM_Closure_Consumer_Diagnostic;
      Work_Action                : RM_Closure_Consumer_Recheck_Work_Action := Worklist.RM_Closure_Consumer_Worklist_No_Action;
      Work_Priority              : RM_Closure_Consumer_Recheck_Work_Priority := Worklist.RM_Closure_Consumer_Worklist_Priority_None;
      Status                     : RM_Closure_Consumer_Recheck_Status := RM_Closure_Consumer_Recheck_Not_Checked;
      Action                     : RM_Closure_Consumer_Recheck_Action := RM_Closure_Consumer_Recheck_Action_None;
      Family                     : RM_Closure_Consumer_Recheck_Family := Worklist.Diagnostics.RM_Closure_Consumer_Diagnostic_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Current_Evidence           : Boolean := False;
      Ready_For_Recheck          : Boolean := False;
      Blocks_Downstream          : Boolean := False;
      Priority_Rank              : Natural := 0;
      Source_Fingerprint         : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Semantic_Fingerprint       : Natural := 0;
      Diagnostic_Fingerprint     : Natural := 0;
      Worklist_Fingerprint       : Natural := 0;
      Eligibility_Fingerprint    : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type RM_Closure_Consumer_Recheck_Model is private;
   type RM_Closure_Consumer_Recheck_Set is private;

   procedure Clear (Model : in out RM_Closure_Consumer_Recheck_Model);

   function Build
     (Work : Worklist.RM_Closure_Consumer_Worklist_Model)
      return RM_Closure_Consumer_Recheck_Model;

   function Row_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural;
   function Row_At
     (Model : RM_Closure_Consumer_Recheck_Model;
      Index : Positive) return RM_Closure_Consumer_Recheck_Row;

   function Query_Count (Set : RM_Closure_Consumer_Recheck_Set) return Natural;
   function Query_At
     (Set   : RM_Closure_Consumer_Recheck_Set;
      Index : Positive) return RM_Closure_Consumer_Recheck_Row;

   function Query_Status
     (Model  : RM_Closure_Consumer_Recheck_Model;
      Status : RM_Closure_Consumer_Recheck_Status)
      return RM_Closure_Consumer_Recheck_Set;
   function Query_Action
     (Model  : RM_Closure_Consumer_Recheck_Model;
      Action : RM_Closure_Consumer_Recheck_Action)
      return RM_Closure_Consumer_Recheck_Set;
   function Query_Family
     (Model  : RM_Closure_Consumer_Recheck_Model;
      Family : RM_Closure_Consumer_Recheck_Family)
      return RM_Closure_Consumer_Recheck_Set;
   function Query_Node
     (Model : RM_Closure_Consumer_Recheck_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return RM_Closure_Consumer_Recheck_Set;
   function Query_Source_Fingerprint
     (Model       : RM_Closure_Consumer_Recheck_Model;
      Fingerprint : Natural)
      return RM_Closure_Consumer_Recheck_Set;

   function Count_Status
     (Model  : RM_Closure_Consumer_Recheck_Model;
      Status : RM_Closure_Consumer_Recheck_Status) return Natural;
   function Count_Action
     (Model  : RM_Closure_Consumer_Recheck_Model;
      Action : RM_Closure_Consumer_Recheck_Action) return Natural;
   function Count_Family
     (Model  : RM_Closure_Consumer_Recheck_Model;
      Family : RM_Closure_Consumer_Recheck_Family) return Natural;

   function Current_Evidence_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural;
   function Eligible_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural;
   function Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural;
   function Fingerprint_Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural;
   function AST_Coverage_Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural;
   function Cross_Unit_Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural;
   function Generic_Substitution_Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural;
   function Dataflow_Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural;
   function Volatile_Atomic_Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural;
   function Overload_Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural;
   function Representation_Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural;
   function Tasking_Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural;
   function Elaboration_Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural;
   function Accessibility_Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural;
   function Discriminant_Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural;
   function Exception_Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural;
   function Renaming_Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural;
   function Predicate_Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural;
   function Multiple_Prerequisite_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural;
   function Indeterminate_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural;
   function Stable_Fingerprint (Model : RM_Closure_Consumer_Recheck_Model) return Natural;

   function Is_Current (Row : RM_Closure_Consumer_Recheck_Row) return Boolean;
   function Is_Eligible (Row : RM_Closure_Consumer_Recheck_Row) return Boolean;
   function Is_Blocked (Status : RM_Closure_Consumer_Recheck_Status) return Boolean;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => RM_Closure_Consumer_Recheck_Row);

   type RM_Closure_Consumer_Recheck_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type RM_Closure_Consumer_Recheck_Model is record
      Rows                          : Row_Vectors.Vector;
      Current_Evidence_Total        : Natural := 0;
      Eligible_Total                : Natural := 0;
      Blocked_Total                 : Natural := 0;
      Fingerprint_Blocked_Total     : Natural := 0;
      AST_Coverage_Blocked_Total    : Natural := 0;
      Cross_Unit_Blocked_Total      : Natural := 0;
      Generic_Substitution_Total    : Natural := 0;
      Dataflow_Blocked_Total        : Natural := 0;
      Volatile_Atomic_Blocked_Total : Natural := 0;
      Overload_Blocked_Total        : Natural := 0;
      Representation_Blocked_Total  : Natural := 0;
      Tasking_Blocked_Total         : Natural := 0;
      Elaboration_Blocked_Total     : Natural := 0;
      Accessibility_Blocked_Total   : Natural := 0;
      Discriminant_Blocked_Total    : Natural := 0;
      Exception_Blocked_Total       : Natural := 0;
      Renaming_Blocked_Total        : Natural := 0;
      Predicate_Blocked_Total       : Natural := 0;
      Multiple_Total                : Natural := 0;
      Indeterminate_Total           : Natural := 0;
      Stable_Fingerprint_Value      : Natural := 0;
   end record;

end Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Eligibility_Legality;
