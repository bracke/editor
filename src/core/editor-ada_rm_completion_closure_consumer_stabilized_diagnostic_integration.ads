with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Closure_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration is

   --  Case 1281 diagnostic integration for stabilized direct RM-completion
   --  closure-consumer results.
   --
   --  This package consumes Case 1280 stabilized closure rows.  Accepted stable
   --  rows are withheld as current semantic evidence; stable blocker rows are
   --  emitted with their original blocker family; recheck-required rows remain
   --  warnings and are not promoted as confident conclusions.  The model is
   --  deterministic, bounded, snapshot-owned, and side-effect-free.

   package Closure renames Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Closure_Legality;

   subtype RM_Closure_Consumer_Stabilized_Closure_Id is Closure.RM_Closure_Consumer_Stabilized_Closure_Id;
   subtype RM_Closure_Consumer_Stabilized_Closure_Status is Closure.RM_Closure_Consumer_Stabilized_Closure_Status;
   subtype RM_Closure_Consumer_Stabilized_Closure_Action is Closure.RM_Closure_Consumer_Stabilized_Closure_Action;
   subtype RM_Closure_Consumer_Closure_Family is Closure.RM_Closure_Consumer_Closure_Family;

   type RM_Closure_Consumer_Stabilized_Diagnostic_Id is new Natural;
   No_RM_Closure_Consumer_Stabilized_Diagnostic : constant RM_Closure_Consumer_Stabilized_Diagnostic_Id := 0;

   type RM_Closure_Consumer_Stabilized_Diagnostic_Family is
     (RM_Closure_Consumer_Stabilized_Diagnostic_Accepted,
      RM_Closure_Consumer_Stabilized_Diagnostic_Stale_Or_Fingerprint,
      RM_Closure_Consumer_Stabilized_Diagnostic_AST_Or_Coverage,
      RM_Closure_Consumer_Stabilized_Diagnostic_Cross_Unit,
      RM_Closure_Consumer_Stabilized_Diagnostic_Generic_Substitution,
      RM_Closure_Consumer_Stabilized_Diagnostic_Dataflow,
      RM_Closure_Consumer_Stabilized_Diagnostic_Volatile_Atomic,
      RM_Closure_Consumer_Stabilized_Diagnostic_Overload_Type,
      RM_Closure_Consumer_Stabilized_Diagnostic_Representation,
      RM_Closure_Consumer_Stabilized_Diagnostic_Tasking_Protected,
      RM_Closure_Consumer_Stabilized_Diagnostic_Elaboration,
      RM_Closure_Consumer_Stabilized_Diagnostic_Accessibility,
      RM_Closure_Consumer_Stabilized_Diagnostic_Discriminant_Variant,
      RM_Closure_Consumer_Stabilized_Diagnostic_Exception_Finalization,
      RM_Closure_Consumer_Stabilized_Diagnostic_Renaming_Alias,
      RM_Closure_Consumer_Stabilized_Diagnostic_Predicate_Invariant,
      RM_Closure_Consumer_Stabilized_Diagnostic_Source_Fingerprint,
      RM_Closure_Consumer_Stabilized_Diagnostic_Substitution_Fingerprint,
      RM_Closure_Consumer_Stabilized_Diagnostic_Multiple,
      RM_Closure_Consumer_Stabilized_Diagnostic_Indeterminate,
      RM_Closure_Consumer_Stabilized_Diagnostic_Recheck_Required,
      RM_Closure_Consumer_Stabilized_Diagnostic_Unknown);

   type RM_Closure_Consumer_Stabilized_Diagnostic_Severity is
     (RM_Closure_Consumer_Stabilized_Diagnostic_Info,
      RM_Closure_Consumer_Stabilized_Diagnostic_Warning,
      RM_Closure_Consumer_Stabilized_Diagnostic_Error);

   type RM_Closure_Consumer_Stabilized_Diagnostic_Status is
     (RM_Closure_Consumer_Stabilized_Diagnostic_Not_Checked,
      RM_Closure_Consumer_Stabilized_Diagnostic_Withheld_Accepted_Current,
      RM_Closure_Consumer_Stabilized_Diagnostic_Withheld_Accepted_Not_Required,
      RM_Closure_Consumer_Stabilized_Diagnostic_Stale_Or_Fingerprint_Blocker,
      RM_Closure_Consumer_Stabilized_Diagnostic_AST_Or_Coverage_Blocker,
      RM_Closure_Consumer_Stabilized_Diagnostic_Cross_Unit_Blocker,
      RM_Closure_Consumer_Stabilized_Diagnostic_Generic_Substitution_Blocker,
      RM_Closure_Consumer_Stabilized_Diagnostic_Dataflow_Blocker,
      RM_Closure_Consumer_Stabilized_Diagnostic_Volatile_Atomic_Blocker,
      RM_Closure_Consumer_Stabilized_Diagnostic_Overload_Type_Blocker,
      RM_Closure_Consumer_Stabilized_Diagnostic_Representation_Blocker,
      RM_Closure_Consumer_Stabilized_Diagnostic_Tasking_Protected_Blocker,
      RM_Closure_Consumer_Stabilized_Diagnostic_Elaboration_Blocker,
      RM_Closure_Consumer_Stabilized_Diagnostic_Accessibility_Blocker,
      RM_Closure_Consumer_Stabilized_Diagnostic_Discriminant_Variant_Blocker,
      RM_Closure_Consumer_Stabilized_Diagnostic_Exception_Finalization_Blocker,
      RM_Closure_Consumer_Stabilized_Diagnostic_Renaming_Alias_Blocker,
      RM_Closure_Consumer_Stabilized_Diagnostic_Predicate_Invariant_Blocker,
      RM_Closure_Consumer_Stabilized_Diagnostic_Source_Fingerprint_Mismatch,
      RM_Closure_Consumer_Stabilized_Diagnostic_Substitution_Fingerprint_Mismatch,
      RM_Closure_Consumer_Stabilized_Diagnostic_Multiple_Prerequisites,
      RM_Closure_Consumer_Stabilized_Diagnostic_Indeterminate,
      RM_Closure_Consumer_Stabilized_Diagnostic_Recheck_Required);

   type RM_Closure_Consumer_Stabilized_Diagnostic_Row is record
      Id                        : RM_Closure_Consumer_Stabilized_Diagnostic_Id := No_RM_Closure_Consumer_Stabilized_Diagnostic;
      Closure_Id                : RM_Closure_Consumer_Stabilized_Closure_Id := Closure.No_RM_Closure_Consumer_Stabilized_Closure;
      Stabilization_Id          : Closure.Gate.RM_Closure_Consumer_Stabilization_Gate_Id := Closure.Gate.No_RM_Closure_Consumer_Stabilization_Gate;
      Convergence_Id            : Closure.Gate.Conv.RM_Closure_Consumer_Convergence_Id := Closure.Gate.Conv.No_RM_Closure_Consumer_Convergence;
      Application_Id            : Closure.Gate.Conv.Apply.RM_Closure_Consumer_Application_Id := Closure.Gate.Conv.Apply.No_RM_Closure_Consumer_Application;
      Eligibility_Id            : Closure.Gate.Conv.Apply.Recheck.RM_Closure_Consumer_Recheck_Id := Closure.Gate.Conv.Apply.Recheck.No_RM_Closure_Consumer_Recheck;
      Worklist_Item             : Closure.Gate.Conv.Apply.Recheck.Worklist.RM_Closure_Consumer_Worklist_Id := Closure.Gate.Conv.Apply.Recheck.Worklist.No_RM_Closure_Consumer_Worklist_Item;
      Diagnostic_Row            : Closure.Gate.Conv.Apply.Recheck.Worklist.Diagnostics.RM_Closure_Consumer_Diagnostic_Id := Closure.Gate.Conv.Apply.Recheck.Worklist.Diagnostics.No_RM_Closure_Consumer_Diagnostic;
      Closure_Status            : RM_Closure_Consumer_Stabilized_Closure_Status := Closure.RM_Closure_Consumer_Stabilized_Closure_Not_Checked;
      Closure_Action            : RM_Closure_Consumer_Stabilized_Closure_Action := Closure.RM_Closure_Consumer_Stabilized_Closure_Action_None;
      Status                    : RM_Closure_Consumer_Stabilized_Diagnostic_Status := RM_Closure_Consumer_Stabilized_Diagnostic_Not_Checked;
      Family                    : RM_Closure_Consumer_Stabilized_Diagnostic_Family := RM_Closure_Consumer_Stabilized_Diagnostic_Unknown;
      Closure_Family            : RM_Closure_Consumer_Closure_Family := Closure.Gate.Conv.Apply.Recheck.Worklist.Diagnostics.RM_Closure_Consumer_Diagnostic_Unknown;
      Severity                  : RM_Closure_Consumer_Stabilized_Diagnostic_Severity := RM_Closure_Consumer_Stabilized_Diagnostic_Warning;
      Node                      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Message                   : Ada.Strings.Unbounded.Unbounded_String;
      Detail                    : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint        : Natural := 0;
      Substitution_Fingerprint  : Natural := 0;
      Semantic_Fingerprint      : Natural := 0;
      Diagnostic_Fingerprint    : Natural := 0;
      Closure_Fingerprint       : Natural := 0;
      Stabilized_Diagnostic_Fingerprint : Natural := 0;
      Emitted                   : Boolean := False;
      Withheld_Current          : Boolean := False;
      Requires_Recheck          : Boolean := False;
      Blocks_Downstream         : Boolean := False;
      Start_Line                : Positive := 1;
      Start_Column              : Positive := 1;
      End_Line                  : Positive := 1;
      End_Column                : Positive := 1;
   end record;

   type RM_Closure_Consumer_Stabilized_Diagnostic_Set is private;
   type RM_Closure_Consumer_Stabilized_Diagnostic_Model is private;

   procedure Clear (Model : in out RM_Closure_Consumer_Stabilized_Diagnostic_Model);

   function Build
     (Closure_Model : Closure.RM_Closure_Consumer_Stabilized_Closure_Model)
      return RM_Closure_Consumer_Stabilized_Diagnostic_Model;

   function Row_Count (Model : RM_Closure_Consumer_Stabilized_Diagnostic_Model) return Natural;
   function Row_At
     (Model : RM_Closure_Consumer_Stabilized_Diagnostic_Model;
      Index : Positive) return RM_Closure_Consumer_Stabilized_Diagnostic_Row;

   function Query_Count (Set : RM_Closure_Consumer_Stabilized_Diagnostic_Set) return Natural;
   function Query_At
     (Set   : RM_Closure_Consumer_Stabilized_Diagnostic_Set;
      Index : Positive) return RM_Closure_Consumer_Stabilized_Diagnostic_Row;

   function Query_Status
     (Model  : RM_Closure_Consumer_Stabilized_Diagnostic_Model;
      Status : RM_Closure_Consumer_Stabilized_Diagnostic_Status)
      return RM_Closure_Consumer_Stabilized_Diagnostic_Set;
   function Query_Family
     (Model  : RM_Closure_Consumer_Stabilized_Diagnostic_Model;
      Family : RM_Closure_Consumer_Stabilized_Diagnostic_Family)
      return RM_Closure_Consumer_Stabilized_Diagnostic_Set;
   function Query_Closure_Family
     (Model  : RM_Closure_Consumer_Stabilized_Diagnostic_Model;
      Family : RM_Closure_Consumer_Closure_Family)
      return RM_Closure_Consumer_Stabilized_Diagnostic_Set;
   function Query_Node
     (Model : RM_Closure_Consumer_Stabilized_Diagnostic_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return RM_Closure_Consumer_Stabilized_Diagnostic_Set;
   function Query_Source_Fingerprint
     (Model       : RM_Closure_Consumer_Stabilized_Diagnostic_Model;
      Fingerprint : Natural) return RM_Closure_Consumer_Stabilized_Diagnostic_Set;

   function Count_Status
     (Model  : RM_Closure_Consumer_Stabilized_Diagnostic_Model;
      Status : RM_Closure_Consumer_Stabilized_Diagnostic_Status) return Natural;
   function Count_Family
     (Model  : RM_Closure_Consumer_Stabilized_Diagnostic_Model;
      Family : RM_Closure_Consumer_Stabilized_Diagnostic_Family) return Natural;
   function Count_Closure_Family
     (Model  : RM_Closure_Consumer_Stabilized_Diagnostic_Model;
      Family : RM_Closure_Consumer_Closure_Family) return Natural;

   function Error_Count (Model : RM_Closure_Consumer_Stabilized_Diagnostic_Model) return Natural;
   function Warning_Count (Model : RM_Closure_Consumer_Stabilized_Diagnostic_Model) return Natural;
   function Info_Count (Model : RM_Closure_Consumer_Stabilized_Diagnostic_Model) return Natural;
   function Emitted_Count (Model : RM_Closure_Consumer_Stabilized_Diagnostic_Model) return Natural;
   function Withheld_Current_Count (Model : RM_Closure_Consumer_Stabilized_Diagnostic_Model) return Natural;
   function Recheck_Required_Count (Model : RM_Closure_Consumer_Stabilized_Diagnostic_Model) return Natural;
   function Indeterminate_Count (Model : RM_Closure_Consumer_Stabilized_Diagnostic_Model) return Natural;
   function Fingerprint (Model : RM_Closure_Consumer_Stabilized_Diagnostic_Model) return Natural;

   function Is_Emitted (Status : RM_Closure_Consumer_Stabilized_Diagnostic_Status) return Boolean;
   function Is_Withheld_Current (Status : RM_Closure_Consumer_Stabilized_Diagnostic_Status) return Boolean;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => RM_Closure_Consumer_Stabilized_Diagnostic_Row);

   type RM_Closure_Consumer_Stabilized_Diagnostic_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type RM_Closure_Consumer_Stabilized_Diagnostic_Model is record
      Rows                   : Row_Vectors.Vector;
      Error_Total            : Natural := 0;
      Warning_Total          : Natural := 0;
      Info_Total             : Natural := 0;
      Emitted_Total          : Natural := 0;
      Withheld_Current_Total : Natural := 0;
      Recheck_Total          : Natural := 0;
      Indeterminate_Total    : Natural := 0;
      Fingerprint            : Natural := 0;
   end record;

end Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration;
