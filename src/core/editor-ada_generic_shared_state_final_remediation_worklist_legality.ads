with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Generic_Shared_State_Final_Remediation_Worklist_Legality is

   --  Case 1240 generic/shared-state final remediation worklist legality.
   --
   --  This package consumes the Case 1239 generic/shared-state final diagnostic
   --  boundary and converts accepted/blocking semantic evidence into a
   --  deterministic remediation worklist.  The worklist is a semantic
   --  prerequisite model, not a UI projection: it preserves blocker-family
   --  identity for stale/fingerprint evidence, definite initialization,
   --  dataflow, predicates, generic replay, stabilized shared-state closure,
   --  volatile/atomic representation, representation/freezing,
   --  tasking/protected, accessibility, discriminants/variants,
   --  exception/finalization, renaming/aliasing, multiple blockers, and
   --  indeterminate states before bounded re-analysis may trust downstream
   --  generic/shared-state conclusions.

   package Diagnostics renames Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration;

   type Generic_Shared_State_Final_Worklist_Id is new Natural;
   No_Generic_Shared_State_Final_Worklist_Item : constant Generic_Shared_State_Final_Worklist_Id := 0;

   subtype Generic_Shared_State_Final_Worklist_Family is
     Diagnostics.Generic_Shared_State_Final_Diagnostic_Family;
   subtype Generic_Shared_State_Final_Worklist_Diagnostic_Status is
     Diagnostics.Generic_Shared_State_Final_Diagnostic_Status;

   type Generic_Shared_State_Final_Worklist_Action is
     (Generic_Shared_State_Final_Worklist_No_Action,
      Generic_Shared_State_Final_Worklist_Keep_Current_Evidence,
      Generic_Shared_State_Final_Worklist_Resolve_Definite_Initialization,
      Generic_Shared_State_Final_Worklist_Resolve_Dataflow_Initialization,
      Generic_Shared_State_Final_Worklist_Resolve_Predicate_Dataflow,
      Generic_Shared_State_Final_Worklist_Resolve_Predicate_Generic_Shared_State,
      Generic_Shared_State_Final_Worklist_Replay_Generic_Abstract_State,
      Generic_Shared_State_Final_Worklist_Stabilize_Shared_State_Closure,
      Generic_Shared_State_Final_Worklist_Resolve_Representation_Generic_Shared_State,
      Generic_Shared_State_Final_Worklist_Resolve_Tasking_Generic_Shared_State,
      Generic_Shared_State_Final_Worklist_Resolve_Accessibility_Generic_Shared_State,
      Generic_Shared_State_Final_Worklist_Resolve_Discriminant_Generic_Shared_State,
      Generic_Shared_State_Final_Worklist_Resolve_Exception_Finalization_Generic_Shared_State,
      Generic_Shared_State_Final_Worklist_Resolve_Renaming_Generic_Shared_State,
      Generic_Shared_State_Final_Worklist_Resolve_Volatile_Atomic_Representation,
      Generic_Shared_State_Final_Worklist_Resolve_Local_Dataflow_RM,
      Generic_Shared_State_Final_Worklist_Recheck_Fingerprint,
      Generic_Shared_State_Final_Worklist_Split_Multiple_Blockers,
      Generic_Shared_State_Final_Worklist_Recheck_Indeterminate);

   type Generic_Shared_State_Final_Worklist_Priority is
     (Generic_Shared_State_Final_Worklist_Priority_None,
      Generic_Shared_State_Final_Worklist_Priority_Current_Evidence,
      Generic_Shared_State_Final_Worklist_Priority_Stale_Or_Fingerprint,
      Generic_Shared_State_Final_Worklist_Priority_AST_Or_Coverage,
      Generic_Shared_State_Final_Worklist_Priority_Cross_Unit_Closure,
      Generic_Shared_State_Final_Worklist_Priority_Generic_Replay,
      Generic_Shared_State_Final_Worklist_Priority_Abstract_Or_Shared_State,
      Generic_Shared_State_Final_Worklist_Priority_Volatile_Atomic,
      Generic_Shared_State_Final_Worklist_Priority_Overload_Or_Type,
      Generic_Shared_State_Final_Worklist_Priority_Representation,
      Generic_Shared_State_Final_Worklist_Priority_Tasking_Protected,
      Generic_Shared_State_Final_Worklist_Priority_Elaboration,
      Generic_Shared_State_Final_Worklist_Priority_Accessibility,
      Generic_Shared_State_Final_Worklist_Priority_Discriminant_Variant,
      Generic_Shared_State_Final_Worklist_Priority_Exception_Finalization,
      Generic_Shared_State_Final_Worklist_Priority_Renaming_Alias,
      Generic_Shared_State_Final_Worklist_Priority_Predicate_Invariant,
      Generic_Shared_State_Final_Worklist_Priority_Dataflow,
      Generic_Shared_State_Final_Worklist_Priority_Multiple,
      Generic_Shared_State_Final_Worklist_Priority_Indeterminate);

   type Generic_Shared_State_Final_Worklist_Item is record
      Id                       : Generic_Shared_State_Final_Worklist_Id := No_Generic_Shared_State_Final_Worklist_Item;
      Diagnostic_Row           : Diagnostics.Generic_Shared_State_Final_Diagnostic_Id := Diagnostics.No_Generic_Shared_State_Final_Diagnostic;
      Diagnostic_Status        : Generic_Shared_State_Final_Worklist_Diagnostic_Status := Diagnostics.Generic_Shared_State_Final_Diagnostic_Not_Checked;
      Family                   : Generic_Shared_State_Final_Worklist_Family := Diagnostics.Generic_Shared_State_Final_Diagnostic_Unknown;
      Action                   : Generic_Shared_State_Final_Worklist_Action := Generic_Shared_State_Final_Worklist_No_Action;
      Priority                 : Generic_Shared_State_Final_Worklist_Priority := Generic_Shared_State_Final_Worklist_Priority_None;
      Node                     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Component_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Operation_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name            : Ada.Strings.Unbounded.Unbounded_String;
      State_Name               : Ada.Strings.Unbounded.Unbounded_String;
      Current_Evidence         : Boolean := False;
      Ready_For_Recheck        : Boolean := False;
      Blocks_Downstream        : Boolean := False;
      Message                  : Ada.Strings.Unbounded.Unbounded_String;
      Detail                   : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint       : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Diagnostic_Fingerprint   : Natural := 0;
      Worklist_Fingerprint     : Natural := 0;
      Start_Line               : Positive := 1;
      Start_Column             : Positive := 1;
      End_Line                 : Positive := 1;
      End_Column               : Positive := 1;
   end record;

   type Generic_Shared_State_Final_Worklist_Model is private;
   type Generic_Shared_State_Final_Worklist_Set is private;

   procedure Clear (Model : in out Generic_Shared_State_Final_Worklist_Model);

   function Build
     (Diagnostics_Model : Diagnostics.Generic_Shared_State_Final_Diagnostic_Model)
      return Generic_Shared_State_Final_Worklist_Model;

   function Count (Model : Generic_Shared_State_Final_Worklist_Model) return Natural;
   function Row_At
     (Model : Generic_Shared_State_Final_Worklist_Model;
      Index : Positive) return Generic_Shared_State_Final_Worklist_Item;

   function Query_Count (Set : Generic_Shared_State_Final_Worklist_Set) return Natural;
   function Query_At
     (Set   : Generic_Shared_State_Final_Worklist_Set;
      Index : Positive) return Generic_Shared_State_Final_Worklist_Item;

   function Query_Action
     (Model  : Generic_Shared_State_Final_Worklist_Model;
      Action : Generic_Shared_State_Final_Worklist_Action)
      return Generic_Shared_State_Final_Worklist_Set;
   function Query_Family
     (Model  : Generic_Shared_State_Final_Worklist_Model;
      Family : Generic_Shared_State_Final_Worklist_Family)
      return Generic_Shared_State_Final_Worklist_Set;
   function Query_Priority
     (Model    : Generic_Shared_State_Final_Worklist_Model;
      Priority : Generic_Shared_State_Final_Worklist_Priority)
      return Generic_Shared_State_Final_Worklist_Set;
   function Query_Node
     (Model : Generic_Shared_State_Final_Worklist_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return Generic_Shared_State_Final_Worklist_Set;
   function Query_Source_Fingerprint
     (Model       : Generic_Shared_State_Final_Worklist_Model;
      Fingerprint : Natural) return Generic_Shared_State_Final_Worklist_Set;

   function Count_Action
     (Model  : Generic_Shared_State_Final_Worklist_Model;
      Action : Generic_Shared_State_Final_Worklist_Action) return Natural;
   function Count_Family
     (Model  : Generic_Shared_State_Final_Worklist_Model;
      Family : Generic_Shared_State_Final_Worklist_Family) return Natural;
   function Count_Priority
     (Model    : Generic_Shared_State_Final_Worklist_Model;
      Priority : Generic_Shared_State_Final_Worklist_Priority) return Natural;

   function Current_Evidence_Count (Model : Generic_Shared_State_Final_Worklist_Model) return Natural;
   function Ready_For_Recheck_Count (Model : Generic_Shared_State_Final_Worklist_Model) return Natural;
   function Blocked_Downstream_Count (Model : Generic_Shared_State_Final_Worklist_Model) return Natural;
   function Fingerprint_Mismatch_Count (Model : Generic_Shared_State_Final_Worklist_Model) return Natural;
   function Indeterminate_Count (Model : Generic_Shared_State_Final_Worklist_Model) return Natural;
   function Stable_Fingerprint (Model : Generic_Shared_State_Final_Worklist_Model) return Natural;

   function Is_Current_Evidence (Item : Generic_Shared_State_Final_Worklist_Item) return Boolean;
   function Is_Ready_For_Recheck (Item : Generic_Shared_State_Final_Worklist_Item) return Boolean;
   function Blocks_Downstream (Item : Generic_Shared_State_Final_Worklist_Item) return Boolean;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Generic_Shared_State_Final_Worklist_Item);

   type Generic_Shared_State_Final_Worklist_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Generic_Shared_State_Final_Worklist_Model is record
      Rows                       : Row_Vectors.Vector;
      Current_Evidence_Total     : Natural := 0;
      Ready_For_Recheck_Total    : Natural := 0;
      Blocked_Downstream_Total   : Natural := 0;
      Fingerprint_Mismatch_Total : Natural := 0;
      Indeterminate_Total        : Natural := 0;
      Stable_Fingerprint_Value   : Natural := 0;
   end record;

end Editor.Ada_Generic_Shared_State_Final_Remediation_Worklist_Legality;
