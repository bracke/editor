with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Generic_Shared_State_Final_Remediation_Worklist_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Generic_Shared_State_Final_Recheck_Eligibility_Legality is

   --  Pass1241 generic/shared-state final recheck eligibility legality.
   --
   --  This package consumes the Pass1240 generic/shared-state final
   --  remediation worklist and turns ordered prerequisite work into bounded
   --  recheck eligibility rows.  It prevents downstream generic/shared-state
   --  final consumers from trusting conclusions while prerequisite blockers
   --  remain unresolved, including generic replay, stabilized shared-state
   --  closure, volatile/atomic representation, representation/freezing,
   --  tasking/protected, accessibility/lifetime, discriminants/variants,
   --  exception/finalization, renaming/aliasing, predicates/invariants,
   --  dataflow, source/substitution fingerprints, multiple blockers, and
   --  indeterminate evidence.

   package Worklist renames Editor.Ada_Generic_Shared_State_Final_Remediation_Worklist_Legality;

   subtype Generic_Shared_State_Final_Recheck_Family is
     Worklist.Generic_Shared_State_Final_Worklist_Family;
   subtype Generic_Shared_State_Final_Recheck_Work_Action is
     Worklist.Generic_Shared_State_Final_Worklist_Action;
   subtype Generic_Shared_State_Final_Recheck_Work_Priority is
     Worklist.Generic_Shared_State_Final_Worklist_Priority;

   type Generic_Shared_State_Final_Recheck_Id is new Natural;
   No_Generic_Shared_State_Final_Recheck : constant Generic_Shared_State_Final_Recheck_Id := 0;

   type Generic_Shared_State_Final_Recheck_Status is
     (Generic_Shared_State_Final_Recheck_Not_Checked,
      Generic_Shared_State_Final_Recheck_Not_Required_Current,
      Generic_Shared_State_Final_Recheck_Eligible_Now,
      Generic_Shared_State_Final_Recheck_Blocked_By_Stale_Or_Fingerprint,
      Generic_Shared_State_Final_Recheck_Blocked_By_AST_Or_Coverage,
      Generic_Shared_State_Final_Recheck_Blocked_By_Cross_Unit,
      Generic_Shared_State_Final_Recheck_Blocked_By_Generic_Replay,
      Generic_Shared_State_Final_Recheck_Blocked_By_Abstract_Or_Shared_State,
      Generic_Shared_State_Final_Recheck_Blocked_By_Volatile_Atomic,
      Generic_Shared_State_Final_Recheck_Blocked_By_Overload_Type,
      Generic_Shared_State_Final_Recheck_Blocked_By_Representation,
      Generic_Shared_State_Final_Recheck_Blocked_By_Tasking_Protected,
      Generic_Shared_State_Final_Recheck_Blocked_By_Elaboration,
      Generic_Shared_State_Final_Recheck_Blocked_By_Accessibility,
      Generic_Shared_State_Final_Recheck_Blocked_By_Discriminant_Variant,
      Generic_Shared_State_Final_Recheck_Blocked_By_Exception_Finalization,
      Generic_Shared_State_Final_Recheck_Blocked_By_Renaming_Alias,
      Generic_Shared_State_Final_Recheck_Blocked_By_Predicate_Invariant,
      Generic_Shared_State_Final_Recheck_Blocked_By_Dataflow,
      Generic_Shared_State_Final_Recheck_Multiple_Prerequisites,
      Generic_Shared_State_Final_Recheck_Indeterminate);

   type Generic_Shared_State_Final_Recheck_Action is
     (Generic_Shared_State_Final_Recheck_Action_None,
      Generic_Shared_State_Final_Recheck_Action_Keep_Current,
      Generic_Shared_State_Final_Recheck_Action_Run_Now,
      Generic_Shared_State_Final_Recheck_Action_Wait_For_Fingerprint,
      Generic_Shared_State_Final_Recheck_Action_Wait_For_AST_Repair,
      Generic_Shared_State_Final_Recheck_Action_Wait_For_Cross_Unit,
      Generic_Shared_State_Final_Recheck_Action_Wait_For_Generic_Replay,
      Generic_Shared_State_Final_Recheck_Action_Wait_For_Shared_State,
      Generic_Shared_State_Final_Recheck_Action_Wait_For_Volatile_Atomic,
      Generic_Shared_State_Final_Recheck_Action_Wait_For_Overload_Type,
      Generic_Shared_State_Final_Recheck_Action_Wait_For_Representation,
      Generic_Shared_State_Final_Recheck_Action_Wait_For_Tasking_Protected,
      Generic_Shared_State_Final_Recheck_Action_Wait_For_Elaboration,
      Generic_Shared_State_Final_Recheck_Action_Wait_For_Accessibility,
      Generic_Shared_State_Final_Recheck_Action_Wait_For_Discriminants,
      Generic_Shared_State_Final_Recheck_Action_Wait_For_Exception_Finalization,
      Generic_Shared_State_Final_Recheck_Action_Wait_For_Renaming,
      Generic_Shared_State_Final_Recheck_Action_Wait_For_Predicate,
      Generic_Shared_State_Final_Recheck_Action_Wait_For_Dataflow,
      Generic_Shared_State_Final_Recheck_Action_Split_Prerequisites,
      Generic_Shared_State_Final_Recheck_Action_Degrade);

   type Generic_Shared_State_Final_Recheck_Row is record
      Id                         : Generic_Shared_State_Final_Recheck_Id := No_Generic_Shared_State_Final_Recheck;
      Worklist_Item              : Worklist.Generic_Shared_State_Final_Worklist_Id := Worklist.No_Generic_Shared_State_Final_Worklist_Item;
      Diagnostic_Row             : Worklist.Diagnostics.Generic_Shared_State_Final_Diagnostic_Id := Worklist.Diagnostics.No_Generic_Shared_State_Final_Diagnostic;
      Work_Action                : Generic_Shared_State_Final_Recheck_Work_Action := Worklist.Generic_Shared_State_Final_Worklist_No_Action;
      Work_Priority              : Generic_Shared_State_Final_Recheck_Work_Priority := Worklist.Generic_Shared_State_Final_Worklist_Priority_None;
      Status                     : Generic_Shared_State_Final_Recheck_Status := Generic_Shared_State_Final_Recheck_Not_Checked;
      Action                     : Generic_Shared_State_Final_Recheck_Action := Generic_Shared_State_Final_Recheck_Action_None;
      Family                     : Generic_Shared_State_Final_Recheck_Family := Worklist.Diagnostics.Generic_Shared_State_Final_Diagnostic_Unknown;
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

   type Generic_Shared_State_Final_Recheck_Model is private;
   type Generic_Shared_State_Final_Recheck_Set is private;

   procedure Clear (Model : in out Generic_Shared_State_Final_Recheck_Model);

   function Build
     (Work : Worklist.Generic_Shared_State_Final_Worklist_Model)
      return Generic_Shared_State_Final_Recheck_Model;

   function Row_Count (Model : Generic_Shared_State_Final_Recheck_Model) return Natural;
   function Row_At
     (Model : Generic_Shared_State_Final_Recheck_Model;
      Index : Positive) return Generic_Shared_State_Final_Recheck_Row;

   function Query_Count (Set : Generic_Shared_State_Final_Recheck_Set) return Natural;
   function Query_At
     (Set   : Generic_Shared_State_Final_Recheck_Set;
      Index : Positive) return Generic_Shared_State_Final_Recheck_Row;

   function Query_Status
     (Model  : Generic_Shared_State_Final_Recheck_Model;
      Status : Generic_Shared_State_Final_Recheck_Status)
      return Generic_Shared_State_Final_Recheck_Set;
   function Query_Action
     (Model  : Generic_Shared_State_Final_Recheck_Model;
      Action : Generic_Shared_State_Final_Recheck_Action)
      return Generic_Shared_State_Final_Recheck_Set;
   function Query_Family
     (Model  : Generic_Shared_State_Final_Recheck_Model;
      Family : Generic_Shared_State_Final_Recheck_Family)
      return Generic_Shared_State_Final_Recheck_Set;
   function Query_Node
     (Model : Generic_Shared_State_Final_Recheck_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return Generic_Shared_State_Final_Recheck_Set;
   function Query_Source_Fingerprint
     (Model       : Generic_Shared_State_Final_Recheck_Model;
      Fingerprint : Natural)
      return Generic_Shared_State_Final_Recheck_Set;

   function Count_Status
     (Model  : Generic_Shared_State_Final_Recheck_Model;
      Status : Generic_Shared_State_Final_Recheck_Status) return Natural;
   function Count_Action
     (Model  : Generic_Shared_State_Final_Recheck_Model;
      Action : Generic_Shared_State_Final_Recheck_Action) return Natural;
   function Count_Family
     (Model  : Generic_Shared_State_Final_Recheck_Model;
      Family : Generic_Shared_State_Final_Recheck_Family) return Natural;

   function Current_Evidence_Count (Model : Generic_Shared_State_Final_Recheck_Model) return Natural;
   function Eligible_Count (Model : Generic_Shared_State_Final_Recheck_Model) return Natural;
   function Blocked_Count (Model : Generic_Shared_State_Final_Recheck_Model) return Natural;
   function Fingerprint_Blocked_Count (Model : Generic_Shared_State_Final_Recheck_Model) return Natural;
   function Generic_Replay_Blocked_Count (Model : Generic_Shared_State_Final_Recheck_Model) return Natural;
   function Shared_State_Blocked_Count (Model : Generic_Shared_State_Final_Recheck_Model) return Natural;
   function Volatile_Atomic_Blocked_Count (Model : Generic_Shared_State_Final_Recheck_Model) return Natural;
   function Representation_Blocked_Count (Model : Generic_Shared_State_Final_Recheck_Model) return Natural;
   function Tasking_Blocked_Count (Model : Generic_Shared_State_Final_Recheck_Model) return Natural;
   function Accessibility_Blocked_Count (Model : Generic_Shared_State_Final_Recheck_Model) return Natural;
   function Discriminant_Blocked_Count (Model : Generic_Shared_State_Final_Recheck_Model) return Natural;
   function Exception_Blocked_Count (Model : Generic_Shared_State_Final_Recheck_Model) return Natural;
   function Renaming_Blocked_Count (Model : Generic_Shared_State_Final_Recheck_Model) return Natural;
   function Predicate_Blocked_Count (Model : Generic_Shared_State_Final_Recheck_Model) return Natural;
   function Dataflow_Blocked_Count (Model : Generic_Shared_State_Final_Recheck_Model) return Natural;
   function Multiple_Prerequisite_Count (Model : Generic_Shared_State_Final_Recheck_Model) return Natural;
   function Indeterminate_Count (Model : Generic_Shared_State_Final_Recheck_Model) return Natural;
   function Fingerprint (Model : Generic_Shared_State_Final_Recheck_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Generic_Shared_State_Final_Recheck_Row);

   type Generic_Shared_State_Final_Recheck_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Generic_Shared_State_Final_Recheck_Model is record
      Rows                   : Row_Vectors.Vector;
      Current_Evidence_Total : Natural := 0;
      Eligible_Total         : Natural := 0;
      Blocked_Total          : Natural := 0;
      Fingerprint_Total      : Natural := 0;
      Generic_Replay_Total   : Natural := 0;
      Shared_State_Total     : Natural := 0;
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

end Editor.Ada_Generic_Shared_State_Final_Recheck_Eligibility_Legality;
