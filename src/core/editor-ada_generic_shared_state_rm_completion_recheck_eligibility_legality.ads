with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Generic_Shared_State_RM_Completion_Remediation_Worklist_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Eligibility_Legality is

   --  Case 1259 RM-completed generic/shared-state recheck eligibility legality.
   --
   --  This package consumes the Case 1257 RM-completed generic/shared-state
   --  remediation worklist and turns ordered prerequisite work into bounded
   --  recheck eligibility rows.  It prevents downstream generic/shared-state
   --  final consumers from trusting conclusions while prerequisite blockers
   --  remain unresolved, including generic substitution, prior dataflow, volatile/atomic effects,
   --  representation/freezing,
   --  tasking/protected, accessibility/lifetime, discriminants/variants,
   --  exception/finalization, renaming/aliasing, predicates/invariants,
   --  dataflow, source/substitution fingerprints, multiple blockers, and
   --  indeterminate evidence.

   package Worklist renames Editor.Ada_Generic_Shared_State_RM_Completion_Remediation_Worklist_Legality;

   subtype RM_Completion_Recheck_Family is
     Worklist.RM_Completion_Worklist_Family;
   subtype RM_Completion_Recheck_Work_Action is
     Worklist.RM_Completion_Worklist_Action;
   subtype RM_Completion_Recheck_Work_Priority is
     Worklist.RM_Completion_Worklist_Priority;

   type RM_Completion_Recheck_Id is new Natural;
   No_RM_Completion_Recheck : constant RM_Completion_Recheck_Id := 0;

   type RM_Completion_Recheck_Status is
     (RM_Completion_Recheck_Not_Checked,
      RM_Completion_Recheck_Not_Required_Current,
      RM_Completion_Recheck_Eligible_Now,
      RM_Completion_Recheck_Blocked_By_Stale_Or_Fingerprint,
      RM_Completion_Recheck_Blocked_By_AST_Or_Coverage,
      RM_Completion_Recheck_Blocked_By_Cross_Unit,
      RM_Completion_Recheck_Blocked_By_Generic_Substitution,
      RM_Completion_Recheck_Blocked_By_Prior_Dataflow,
      RM_Completion_Recheck_Blocked_By_Volatile_Atomic,
      RM_Completion_Recheck_Blocked_By_Overload_Type,
      RM_Completion_Recheck_Blocked_By_Representation,
      RM_Completion_Recheck_Blocked_By_Tasking_Protected,
      RM_Completion_Recheck_Blocked_By_Elaboration,
      RM_Completion_Recheck_Blocked_By_Accessibility,
      RM_Completion_Recheck_Blocked_By_Discriminant_Variant,
      RM_Completion_Recheck_Blocked_By_Exception_Finalization,
      RM_Completion_Recheck_Blocked_By_Renaming_Alias,
      RM_Completion_Recheck_Blocked_By_Predicate_Invariant,
      RM_Completion_Recheck_Blocked_By_Dataflow,
      RM_Completion_Recheck_Multiple_Prerequisites,
      RM_Completion_Recheck_Indeterminate);

   type RM_Completion_Recheck_Action is
     (RM_Completion_Recheck_Action_None,
      RM_Completion_Recheck_Action_Keep_Current,
      RM_Completion_Recheck_Action_Run_Now,
      RM_Completion_Recheck_Action_Wait_For_Fingerprint,
      RM_Completion_Recheck_Action_Wait_For_AST_Repair,
      RM_Completion_Recheck_Action_Wait_For_Cross_Unit,
      RM_Completion_Recheck_Action_Wait_For_Generic_Substitution,
      RM_Completion_Recheck_Action_Wait_For_Prior_Dataflow,
      RM_Completion_Recheck_Action_Wait_For_Volatile_Atomic,
      RM_Completion_Recheck_Action_Wait_For_Overload_Type,
      RM_Completion_Recheck_Action_Wait_For_Representation,
      RM_Completion_Recheck_Action_Wait_For_Tasking_Protected,
      RM_Completion_Recheck_Action_Wait_For_Elaboration,
      RM_Completion_Recheck_Action_Wait_For_Accessibility,
      RM_Completion_Recheck_Action_Wait_For_Discriminants,
      RM_Completion_Recheck_Action_Wait_For_Exception_Finalization,
      RM_Completion_Recheck_Action_Wait_For_Renaming,
      RM_Completion_Recheck_Action_Wait_For_Predicate,
      RM_Completion_Recheck_Action_Wait_For_Dataflow,
      RM_Completion_Recheck_Action_Split_Prerequisites,
      RM_Completion_Recheck_Action_Degrade);

   type RM_Completion_Recheck_Row is record
      Id                         : RM_Completion_Recheck_Id := No_RM_Completion_Recheck;
      Worklist_Item              : Worklist.RM_Completion_Worklist_Id := Worklist.No_RM_Completion_Worklist_Item;
      Diagnostic_Row             : Worklist.Diagnostics.RM_Completion_Diagnostic_Id := Worklist.Diagnostics.No_RM_Completion_Diagnostic;
      Work_Action                : RM_Completion_Recheck_Work_Action := Worklist.RM_Completion_Worklist_No_Action;
      Work_Priority              : RM_Completion_Recheck_Work_Priority := Worklist.RM_Completion_Worklist_Priority_None;
      Status                     : RM_Completion_Recheck_Status := RM_Completion_Recheck_Not_Checked;
      Action                     : RM_Completion_Recheck_Action := RM_Completion_Recheck_Action_None;
      Family                     : RM_Completion_Recheck_Family := Worklist.Diagnostics.RM_Completion_Diagnostic_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Component_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Operation_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Current_Evidence           : Boolean := False;
      Ready_For_Recheck          : Boolean := False;
      Blocks_Downstream          : Boolean := False;
      Priority_Rank              : Natural := 0;
      Source_Fingerprint         : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Worklist_Fingerprint       : Natural := 0;
      Eligibility_Fingerprint    : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type RM_Completion_Recheck_Model is private;
   type RM_Completion_Recheck_Set is private;

   procedure Clear (Model : in out RM_Completion_Recheck_Model);

   function Build
     (Work : Worklist.RM_Completion_Worklist_Model)
      return RM_Completion_Recheck_Model;

   function Row_Count (Model : RM_Completion_Recheck_Model) return Natural;
   function Row_At
     (Model : RM_Completion_Recheck_Model;
      Index : Positive) return RM_Completion_Recheck_Row;

   function Query_Count (Set : RM_Completion_Recheck_Set) return Natural;
   function Query_At
     (Set   : RM_Completion_Recheck_Set;
      Index : Positive) return RM_Completion_Recheck_Row;

   function Query_Status
     (Model  : RM_Completion_Recheck_Model;
      Status : RM_Completion_Recheck_Status)
      return RM_Completion_Recheck_Set;
   function Query_Action
     (Model  : RM_Completion_Recheck_Model;
      Action : RM_Completion_Recheck_Action)
      return RM_Completion_Recheck_Set;
   function Query_Family
     (Model  : RM_Completion_Recheck_Model;
      Family : RM_Completion_Recheck_Family)
      return RM_Completion_Recheck_Set;
   function Query_Node
     (Model : RM_Completion_Recheck_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return RM_Completion_Recheck_Set;
   function Query_Source_Fingerprint
     (Model       : RM_Completion_Recheck_Model;
      Fingerprint : Natural)
      return RM_Completion_Recheck_Set;

   function Count_Status
     (Model  : RM_Completion_Recheck_Model;
      Status : RM_Completion_Recheck_Status) return Natural;
   function Count_Action
     (Model  : RM_Completion_Recheck_Model;
      Action : RM_Completion_Recheck_Action) return Natural;
   function Count_Family
     (Model  : RM_Completion_Recheck_Model;
      Family : RM_Completion_Recheck_Family) return Natural;

   function Current_Evidence_Count (Model : RM_Completion_Recheck_Model) return Natural;
   function Eligible_Count (Model : RM_Completion_Recheck_Model) return Natural;
   function Blocked_Count (Model : RM_Completion_Recheck_Model) return Natural;
   function Fingerprint_Blocked_Count (Model : RM_Completion_Recheck_Model) return Natural;
   function Generic_Substitution_Blocked_Count (Model : RM_Completion_Recheck_Model) return Natural;
   function Prior_Dataflow_Blocked_Count (Model : RM_Completion_Recheck_Model) return Natural;
   function Volatile_Atomic_Blocked_Count (Model : RM_Completion_Recheck_Model) return Natural;
   function Representation_Blocked_Count (Model : RM_Completion_Recheck_Model) return Natural;
   function Tasking_Blocked_Count (Model : RM_Completion_Recheck_Model) return Natural;
   function Accessibility_Blocked_Count (Model : RM_Completion_Recheck_Model) return Natural;
   function Discriminant_Blocked_Count (Model : RM_Completion_Recheck_Model) return Natural;
   function Exception_Blocked_Count (Model : RM_Completion_Recheck_Model) return Natural;
   function Renaming_Blocked_Count (Model : RM_Completion_Recheck_Model) return Natural;
   function Predicate_Blocked_Count (Model : RM_Completion_Recheck_Model) return Natural;
   function Dataflow_Blocked_Count (Model : RM_Completion_Recheck_Model) return Natural;
   function Multiple_Prerequisite_Count (Model : RM_Completion_Recheck_Model) return Natural;
   function Indeterminate_Count (Model : RM_Completion_Recheck_Model) return Natural;
   function Fingerprint (Model : RM_Completion_Recheck_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => RM_Completion_Recheck_Row);

   type RM_Completion_Recheck_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type RM_Completion_Recheck_Model is record
      Rows                   : Row_Vectors.Vector;
      Current_Evidence_Total : Natural := 0;
      Eligible_Total         : Natural := 0;
      Blocked_Total          : Natural := 0;
      Fingerprint_Total      : Natural := 0;
      Generic_Substitution_Total   : Natural := 0;
      Prior_Dataflow_Total     : Natural := 0;
      Volatile_Atomic_Total  : Natural := 0;
      Representation_Total   : Natural := 0;
      Tasking_Total          : Natural := 0;
      Accessibility_Total    : Natural := 0;
      Discriminant_Total     : Natural := 0;
      Exception_Total        : Natural := 0;
      Renaming_Total         : Natural := 0;
      Predicate_Total        : Natural := 0;
      Dataflow_Total         : Natural := 0;
      Multiple_Total         : Natural := 0;
      Indeterminate_Total    : Natural := 0;
      Fingerprint            : Natural := 0;
   end record;

end Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Eligibility_Legality;
