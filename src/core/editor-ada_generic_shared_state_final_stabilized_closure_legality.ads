with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Generic_Shared_State_Final_Stabilization_Gate_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Generic_Shared_State_Final_Stabilized_Closure_Legality is

   --  Pass1245 generic/shared-state final stabilized closure legality.
   --
   --  This package consumes Pass1244 generic/shared-state final stabilization
   --  gate rows and promotes stable accepted conclusions into first-class
   --  semantic closure evidence.  Stable prerequisite blockers remain closure
   --  blockers with their original blocker-family identity.  Recheck-required
   --  and indeterminate rows are preserved as non-confident closure states so
   --  downstream Ada legality consumers cannot bypass unresolved generic,
   --  shared-state, representation, tasking, elaboration, accessibility,
   --  discriminant, exception/finalization, renaming, predicate, or dataflow
   --  evidence.

   package Gate renames Editor.Ada_Generic_Shared_State_Final_Stabilization_Gate_Legality;

   subtype Generic_Shared_State_Final_Stabilization_Status is Gate.Generic_Shared_State_Final_Stabilization_Gate_Status;
   subtype Generic_Shared_State_Final_Stabilization_Action is Gate.Generic_Shared_State_Final_Stabilization_Gate_Action;
   subtype Generic_Shared_State_Final_Closure_Family is Gate.Generic_Shared_State_Final_Stabilization_Family;

   type Generic_Shared_State_Final_Stabilized_Closure_Id is new Natural;
   No_Generic_Shared_State_Final_Stabilized_Closure : constant Generic_Shared_State_Final_Stabilized_Closure_Id := 0;

   type Generic_Shared_State_Final_Stabilized_Closure_Status is
     (Generic_Shared_State_Final_Stabilized_Closure_Not_Checked,
      Generic_Shared_State_Final_Stabilized_Closure_Accepted_Current,
      Generic_Shared_State_Final_Stabilized_Closure_Accepted_Not_Required,
      Generic_Shared_State_Final_Stabilized_Closure_Blocker_Stale_Or_Fingerprint,
      Generic_Shared_State_Final_Stabilized_Closure_Blocker_AST_Or_Coverage,
      Generic_Shared_State_Final_Stabilized_Closure_Blocker_Cross_Unit,
      Generic_Shared_State_Final_Stabilized_Closure_Blocker_Generic_Replay,
      Generic_Shared_State_Final_Stabilized_Closure_Blocker_Abstract_Or_Shared_State,
      Generic_Shared_State_Final_Stabilized_Closure_Blocker_Volatile_Atomic,
      Generic_Shared_State_Final_Stabilized_Closure_Blocker_Overload_Type,
      Generic_Shared_State_Final_Stabilized_Closure_Blocker_Representation,
      Generic_Shared_State_Final_Stabilized_Closure_Blocker_Tasking_Protected,
      Generic_Shared_State_Final_Stabilized_Closure_Blocker_Elaboration,
      Generic_Shared_State_Final_Stabilized_Closure_Blocker_Accessibility,
      Generic_Shared_State_Final_Stabilized_Closure_Blocker_Discriminant_Variant,
      Generic_Shared_State_Final_Stabilized_Closure_Blocker_Exception_Finalization,
      Generic_Shared_State_Final_Stabilized_Closure_Blocker_Renaming_Alias,
      Generic_Shared_State_Final_Stabilized_Closure_Blocker_Predicate_Invariant,
      Generic_Shared_State_Final_Stabilized_Closure_Blocker_Dataflow,
      Generic_Shared_State_Final_Stabilized_Closure_Blocker_Multiple_Prerequisites,
      Generic_Shared_State_Final_Stabilized_Closure_Indeterminate,
      Generic_Shared_State_Final_Stabilized_Closure_Recheck_Required);

   type Generic_Shared_State_Final_Stabilized_Closure_Action is
     (Generic_Shared_State_Final_Stabilized_Closure_Action_None,
      Generic_Shared_State_Final_Stabilized_Closure_Action_Accept_Current,
      Generic_Shared_State_Final_Stabilized_Closure_Action_Accept_Not_Required,
      Generic_Shared_State_Final_Stabilized_Closure_Action_Block_Fingerprint,
      Generic_Shared_State_Final_Stabilized_Closure_Action_Block_AST,
      Generic_Shared_State_Final_Stabilized_Closure_Action_Block_Cross_Unit,
      Generic_Shared_State_Final_Stabilized_Closure_Action_Block_Generic,
      Generic_Shared_State_Final_Stabilized_Closure_Action_Block_Shared_State,
      Generic_Shared_State_Final_Stabilized_Closure_Action_Block_Effects,
      Generic_Shared_State_Final_Stabilized_Closure_Action_Block_Type,
      Generic_Shared_State_Final_Stabilized_Closure_Action_Block_Representation,
      Generic_Shared_State_Final_Stabilized_Closure_Action_Block_Tasking,
      Generic_Shared_State_Final_Stabilized_Closure_Action_Block_Elaboration,
      Generic_Shared_State_Final_Stabilized_Closure_Action_Block_Accessibility,
      Generic_Shared_State_Final_Stabilized_Closure_Action_Block_Discriminant,
      Generic_Shared_State_Final_Stabilized_Closure_Action_Block_Exception,
      Generic_Shared_State_Final_Stabilized_Closure_Action_Block_Renaming,
      Generic_Shared_State_Final_Stabilized_Closure_Action_Block_Predicate,
      Generic_Shared_State_Final_Stabilized_Closure_Action_Block_Dataflow,
      Generic_Shared_State_Final_Stabilized_Closure_Action_Split_Prerequisites,
      Generic_Shared_State_Final_Stabilized_Closure_Action_Degrade,
      Generic_Shared_State_Final_Stabilized_Closure_Action_Recheck);

   type Generic_Shared_State_Final_Stabilized_Closure_Row is record
      Id                         : Generic_Shared_State_Final_Stabilized_Closure_Id := No_Generic_Shared_State_Final_Stabilized_Closure;
      Stabilization_Id           : Gate.Generic_Shared_State_Final_Stabilization_Gate_Id := Gate.No_Generic_Shared_State_Final_Stabilization_Gate;
      Convergence_Id             : Gate.Conv.Generic_Shared_State_Final_Convergence_Id := Gate.Conv.No_Generic_Shared_State_Final_Convergence;
      Application_Id             : Gate.Conv.Apply.Generic_Shared_State_Final_Application_Id := Gate.Conv.Apply.No_Generic_Shared_State_Final_Application;
      Eligibility_Id             : Gate.Conv.Apply.Recheck.Generic_Shared_State_Final_Recheck_Id := Gate.Conv.Apply.Recheck.No_Generic_Shared_State_Final_Recheck;
      Worklist_Item              : Gate.Conv.Apply.Recheck.Worklist.Generic_Shared_State_Final_Worklist_Id := Gate.Conv.Apply.Recheck.Worklist.No_Generic_Shared_State_Final_Worklist_Item;
      Diagnostic_Row             : Gate.Conv.Apply.Recheck.Worklist.Diagnostics.Generic_Shared_State_Final_Diagnostic_Id := Gate.Conv.Apply.Recheck.Worklist.Diagnostics.No_Generic_Shared_State_Final_Diagnostic;
      Stabilization_Status       : Generic_Shared_State_Final_Stabilization_Status := Gate.Generic_Shared_State_Final_Stabilization_Gate_Not_Checked;
      Stabilization_Action       : Generic_Shared_State_Final_Stabilization_Action := Gate.Generic_Shared_State_Final_Stabilization_Gate_Action_None;
      Status                     : Generic_Shared_State_Final_Stabilized_Closure_Status := Generic_Shared_State_Final_Stabilized_Closure_Not_Checked;
      Action                     : Generic_Shared_State_Final_Stabilized_Closure_Action := Generic_Shared_State_Final_Stabilized_Closure_Action_None;
      Family                     : Generic_Shared_State_Final_Closure_Family := Gate.Conv.Apply.Recheck.Worklist.Diagnostics.Generic_Shared_State_Final_Diagnostic_Unknown;
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

   type Generic_Shared_State_Final_Stabilized_Closure_Model is private;
   type Generic_Shared_State_Final_Stabilized_Closure_Set is private;

   procedure Clear (Model : in out Generic_Shared_State_Final_Stabilized_Closure_Model);

   function Build
     (Stabilization : Gate.Generic_Shared_State_Final_Stabilization_Gate_Model)
      return Generic_Shared_State_Final_Stabilized_Closure_Model;

   function Count (Model : Generic_Shared_State_Final_Stabilized_Closure_Model) return Natural;
   function Row_Count (Model : Generic_Shared_State_Final_Stabilized_Closure_Model) return Natural renames Count;
   function Row_At
     (Model : Generic_Shared_State_Final_Stabilized_Closure_Model;
      Index : Positive) return Generic_Shared_State_Final_Stabilized_Closure_Row;

   function Query_Count (Set : Generic_Shared_State_Final_Stabilized_Closure_Set) return Natural;
   function Query_At
     (Set   : Generic_Shared_State_Final_Stabilized_Closure_Set;
      Index : Positive) return Generic_Shared_State_Final_Stabilized_Closure_Row;

   function Query_Status
     (Model  : Generic_Shared_State_Final_Stabilized_Closure_Model;
      Status : Generic_Shared_State_Final_Stabilized_Closure_Status) return Generic_Shared_State_Final_Stabilized_Closure_Set;
   function Query_Action
     (Model  : Generic_Shared_State_Final_Stabilized_Closure_Model;
      Action : Generic_Shared_State_Final_Stabilized_Closure_Action) return Generic_Shared_State_Final_Stabilized_Closure_Set;
   function Query_Family
     (Model  : Generic_Shared_State_Final_Stabilized_Closure_Model;
      Family : Generic_Shared_State_Final_Closure_Family) return Generic_Shared_State_Final_Stabilized_Closure_Set;
   function Find_By_Node
     (Model : Generic_Shared_State_Final_Stabilized_Closure_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Generic_Shared_State_Final_Stabilized_Closure_Set;
   function Find_By_Source_Fingerprint
     (Model       : Generic_Shared_State_Final_Stabilized_Closure_Model;
      Fingerprint : Natural) return Generic_Shared_State_Final_Stabilized_Closure_Set;
   function Find_By_Substitution_Fingerprint
     (Model       : Generic_Shared_State_Final_Stabilized_Closure_Model;
      Fingerprint : Natural) return Generic_Shared_State_Final_Stabilized_Closure_Set;

   function Count_By_Status
     (Model  : Generic_Shared_State_Final_Stabilized_Closure_Model;
      Status : Generic_Shared_State_Final_Stabilized_Closure_Status) return Natural;
   function Count_By_Family
     (Model  : Generic_Shared_State_Final_Stabilized_Closure_Model;
      Family : Generic_Shared_State_Final_Closure_Family) return Natural;

   function Accepted_Count (Model : Generic_Shared_State_Final_Stabilized_Closure_Model) return Natural;
   function Blocked_Count (Model : Generic_Shared_State_Final_Stabilized_Closure_Model) return Natural;
   function Current_Count (Model : Generic_Shared_State_Final_Stabilized_Closure_Model) return Natural;
   function Recheck_Required_Count (Model : Generic_Shared_State_Final_Stabilized_Closure_Model) return Natural;
   function Indeterminate_Count (Model : Generic_Shared_State_Final_Stabilized_Closure_Model) return Natural;
   function Is_Accepted
     (Status : Generic_Shared_State_Final_Stabilized_Closure_Status) return Boolean;
   function Stable_Fingerprint (Model : Generic_Shared_State_Final_Stabilized_Closure_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Generic_Shared_State_Final_Stabilized_Closure_Row);

   type Generic_Shared_State_Final_Stabilized_Closure_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Generic_Shared_State_Final_Stabilized_Closure_Model is record
      Rows                : Row_Vectors.Vector;
      Accepted_Total      : Natural := 0;
      Blocked_Total       : Natural := 0;
      Current_Total       : Natural := 0;
      Recheck_Total       : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

end Editor.Ada_Generic_Shared_State_Final_Stabilized_Closure_Legality;
