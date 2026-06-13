with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Generic_Shared_State_RM_Completion_Stabilization_Gate_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Generic_Shared_State_RM_Completion_Stabilized_Closure_Legality is

   --  Pass1263 generic/shared-state RM-completion stabilized closure legality.
   --
   --  This package consumes Pass1262 generic/shared-state RM-completion stabilization
   --  gate rows and promotes stable accepted conclusions into first-class
   --  semantic closure evidence.  Stable prerequisite blockers remain closure
   --  blockers with their original blocker-family identity.  Recheck-required
   --  and indeterminate rows are preserved as non-confident closure states so
   --  downstream Ada legality consumers cannot bypass unresolved generic,
   --  shared-state, representation, tasking, elaboration, accessibility,
   --  discriminant, exception/finalization, renaming, predicate, or dataflow
   --  evidence.

   package Gate renames Editor.Ada_Generic_Shared_State_RM_Completion_Stabilization_Gate_Legality;

   subtype RM_Completion_Stabilization_Status is Gate.RM_Completion_Stabilization_Gate_Status;
   subtype RM_Completion_Stabilization_Action is Gate.RM_Completion_Stabilization_Gate_Action;
   subtype RM_Completion_Closure_Family is Gate.RM_Completion_Stabilization_Family;

   type RM_Completion_Stabilized_Closure_Id is new Natural;
   No_RM_Completion_Stabilized_Closure : constant RM_Completion_Stabilized_Closure_Id := 0;

   type RM_Completion_Stabilized_Closure_Status is
     (RM_Completion_Stabilized_Closure_Not_Checked,
      RM_Completion_Stabilized_Closure_Accepted_Current,
      RM_Completion_Stabilized_Closure_Accepted_Not_Required,
      RM_Completion_Stabilized_Closure_Blocker_Stale_Or_Fingerprint,
      RM_Completion_Stabilized_Closure_Blocker_AST_Or_Coverage,
      RM_Completion_Stabilized_Closure_Blocker_Cross_Unit,
      RM_Completion_Stabilized_Closure_Blocker_Generic_Substitution,
      RM_Completion_Stabilized_Closure_Blocker_Prior_Dataflow,
      RM_Completion_Stabilized_Closure_Blocker_Volatile_Atomic,
      RM_Completion_Stabilized_Closure_Blocker_Overload_Type,
      RM_Completion_Stabilized_Closure_Blocker_Representation,
      RM_Completion_Stabilized_Closure_Blocker_Tasking_Protected,
      RM_Completion_Stabilized_Closure_Blocker_Elaboration,
      RM_Completion_Stabilized_Closure_Blocker_Accessibility,
      RM_Completion_Stabilized_Closure_Blocker_Discriminant_Variant,
      RM_Completion_Stabilized_Closure_Blocker_Exception_Finalization,
      RM_Completion_Stabilized_Closure_Blocker_Renaming_Alias,
      RM_Completion_Stabilized_Closure_Blocker_Predicate_Invariant,
      RM_Completion_Stabilized_Closure_Blocker_Dataflow,
      RM_Completion_Stabilized_Closure_Blocker_Multiple_Prerequisites,
      RM_Completion_Stabilized_Closure_Indeterminate,
      RM_Completion_Stabilized_Closure_Recheck_Required);

   type RM_Completion_Stabilized_Closure_Action is
     (RM_Completion_Stabilized_Closure_Action_None,
      RM_Completion_Stabilized_Closure_Action_Accept_Current,
      RM_Completion_Stabilized_Closure_Action_Accept_Not_Required,
      RM_Completion_Stabilized_Closure_Action_Block_Fingerprint,
      RM_Completion_Stabilized_Closure_Action_Block_AST,
      RM_Completion_Stabilized_Closure_Action_Block_Cross_Unit,
      RM_Completion_Stabilized_Closure_Action_Block_Generic_Substitution,
      RM_Completion_Stabilized_Closure_Action_Block_Prior_Dataflow,
      RM_Completion_Stabilized_Closure_Action_Block_Effects,
      RM_Completion_Stabilized_Closure_Action_Block_Type,
      RM_Completion_Stabilized_Closure_Action_Block_Representation,
      RM_Completion_Stabilized_Closure_Action_Block_Tasking,
      RM_Completion_Stabilized_Closure_Action_Block_Elaboration,
      RM_Completion_Stabilized_Closure_Action_Block_Accessibility,
      RM_Completion_Stabilized_Closure_Action_Block_Discriminant,
      RM_Completion_Stabilized_Closure_Action_Block_Exception,
      RM_Completion_Stabilized_Closure_Action_Block_Renaming,
      RM_Completion_Stabilized_Closure_Action_Block_Predicate,
      RM_Completion_Stabilized_Closure_Action_Block_Dataflow,
      RM_Completion_Stabilized_Closure_Action_Split_Prerequisites,
      RM_Completion_Stabilized_Closure_Action_Degrade,
      RM_Completion_Stabilized_Closure_Action_Recheck);

   type RM_Completion_Stabilized_Closure_Row is record
      Id                         : RM_Completion_Stabilized_Closure_Id := No_RM_Completion_Stabilized_Closure;
      Stabilization_Id           : Gate.RM_Completion_Stabilization_Gate_Id := Gate.No_RM_Completion_Stabilization_Gate;
      Convergence_Id             : Gate.Conv.RM_Completion_Convergence_Id := Gate.Conv.No_RM_Completion_Convergence;
      Application_Id             : Gate.Conv.Apply.RM_Completion_Application_Id := Gate.Conv.Apply.No_RM_Completion_Application;
      Eligibility_Id             : Gate.Conv.Apply.Recheck.RM_Completion_Recheck_Id := Gate.Conv.Apply.Recheck.No_RM_Completion_Recheck;
      Worklist_Item              : Gate.Conv.Apply.Recheck.Worklist.RM_Completion_Worklist_Id := Gate.Conv.Apply.Recheck.Worklist.No_RM_Completion_Worklist_Item;
      Diagnostic_Row             : Gate.Conv.Apply.Recheck.Worklist.Diagnostics.RM_Completion_Diagnostic_Id := Gate.Conv.Apply.Recheck.Worklist.Diagnostics.No_RM_Completion_Diagnostic;
      Stabilization_Status       : RM_Completion_Stabilization_Status := Gate.RM_Completion_Stabilization_Gate_Not_Checked;
      Stabilization_Action       : RM_Completion_Stabilization_Action := Gate.RM_Completion_Stabilization_Gate_Action_None;
      Status                     : RM_Completion_Stabilized_Closure_Status := RM_Completion_Stabilized_Closure_Not_Checked;
      Action                     : RM_Completion_Stabilized_Closure_Action := RM_Completion_Stabilized_Closure_Action_None;
      Family                     : RM_Completion_Closure_Family := Gate.Conv.Apply.Recheck.Worklist.Diagnostics.RM_Completion_Diagnostic_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Component_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Operation_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Accepted                   : Boolean := False;
      Current                    : Boolean := False;
      Blocked                    : Boolean := False;
      Stable                     : Boolean := False;
      Recheck_Required           : Boolean := False;
      Blocks_Downstream          : Boolean := False;
      Priority_Rank              : Natural := 0;
      Source_Fingerprint         : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Worklist_Fingerprint       : Natural := 0;
      Eligibility_Fingerprint    : Natural := 0;
      Application_Fingerprint    : Natural := 0;
      Convergence_Fingerprint    : Natural := 0;
      Stabilization_Fingerprint  : Natural := 0;
      Closure_Fingerprint        : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type RM_Completion_Stabilized_Closure_Model is private;
   type RM_Completion_Stabilized_Closure_Set is private;

   procedure Clear (Model : in out RM_Completion_Stabilized_Closure_Model);

   function Build
     (Stabilization : Gate.RM_Completion_Stabilization_Gate_Model)
      return RM_Completion_Stabilized_Closure_Model;

   function Count (Model : RM_Completion_Stabilized_Closure_Model) return Natural;
   function Row_Count (Model : RM_Completion_Stabilized_Closure_Model) return Natural renames Count;
   function Row_At
     (Model : RM_Completion_Stabilized_Closure_Model;
      Index : Positive) return RM_Completion_Stabilized_Closure_Row;

   function Query_Count (Set : RM_Completion_Stabilized_Closure_Set) return Natural;
   function Query_At
     (Set   : RM_Completion_Stabilized_Closure_Set;
      Index : Positive) return RM_Completion_Stabilized_Closure_Row;

   function Query_Status
     (Model  : RM_Completion_Stabilized_Closure_Model;
      Status : RM_Completion_Stabilized_Closure_Status) return RM_Completion_Stabilized_Closure_Set;
   function Query_Action
     (Model  : RM_Completion_Stabilized_Closure_Model;
      Action : RM_Completion_Stabilized_Closure_Action) return RM_Completion_Stabilized_Closure_Set;
   function Query_Family
     (Model  : RM_Completion_Stabilized_Closure_Model;
      Family : RM_Completion_Closure_Family) return RM_Completion_Stabilized_Closure_Set;
   function Find_By_Node
     (Model : RM_Completion_Stabilized_Closure_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return RM_Completion_Stabilized_Closure_Set;
   function Find_By_Source_Fingerprint
     (Model       : RM_Completion_Stabilized_Closure_Model;
      Fingerprint : Natural) return RM_Completion_Stabilized_Closure_Set;
   function Find_By_Substitution_Fingerprint
     (Model       : RM_Completion_Stabilized_Closure_Model;
      Fingerprint : Natural) return RM_Completion_Stabilized_Closure_Set;

   function Count_By_Status
     (Model  : RM_Completion_Stabilized_Closure_Model;
      Status : RM_Completion_Stabilized_Closure_Status) return Natural;
   function Count_By_Family
     (Model  : RM_Completion_Stabilized_Closure_Model;
      Family : RM_Completion_Closure_Family) return Natural;

   function Accepted_Count (Model : RM_Completion_Stabilized_Closure_Model) return Natural;
   function Blocked_Count (Model : RM_Completion_Stabilized_Closure_Model) return Natural;
   function Current_Count (Model : RM_Completion_Stabilized_Closure_Model) return Natural;
   function Recheck_Required_Count (Model : RM_Completion_Stabilized_Closure_Model) return Natural;
   function Indeterminate_Count (Model : RM_Completion_Stabilized_Closure_Model) return Natural;
   function Stable_Fingerprint (Model : RM_Completion_Stabilized_Closure_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => RM_Completion_Stabilized_Closure_Row);

   type RM_Completion_Stabilized_Closure_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type RM_Completion_Stabilized_Closure_Model is record
      Rows                : Row_Vectors.Vector;
      Accepted_Total      : Natural := 0;
      Blocked_Total       : Natural := 0;
      Current_Total       : Natural := 0;
      Recheck_Total       : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

end Editor.Ada_Generic_Shared_State_RM_Completion_Stabilized_Closure_Legality;
