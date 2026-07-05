with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Predicate_RM_Completion_Closure_Consumer_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration is

   --  Case 1273 diagnostic integration for the direct RM-completion closure
   --  consumers.
   --
   --  This package consumes the Case 1272 predicate/invariant direct consumer,
   --  which itself requires the stabilized RM-completion closure plus direct
   --  cross-unit, elaboration, accessibility, exception/finalization,
   --  overload/type, representation/freezing, tasking/protected, and dataflow
   --  RM-completion closure consumers.  Accepted rows are withheld as current
   --  semantic evidence.  Blocking rows are emitted while preserving their
   --  prerequisite family so diagnostics do not collapse cross-unit,
   --  elaboration, accessibility, exception/finalization, overload,
   --  representation, tasking, dataflow, predicate, stale/fingerprint,
   --  multiple, or indeterminate blockers into a generic expression bucket.

   package Predicate renames Editor.Ada_Predicate_RM_Completion_Closure_Consumer_Legality;

   type RM_Closure_Consumer_Diagnostic_Id is new Natural;
   No_RM_Closure_Consumer_Diagnostic : constant RM_Closure_Consumer_Diagnostic_Id := 0;

   type RM_Closure_Consumer_Diagnostic_Family is
     (RM_Closure_Consumer_Diagnostic_Accepted,
      RM_Closure_Consumer_Diagnostic_Predicate_RM,
      RM_Closure_Consumer_Diagnostic_Stabilized_Closure,
      RM_Closure_Consumer_Diagnostic_Stale_Or_Fingerprint,
      RM_Closure_Consumer_Diagnostic_AST_Or_Coverage,
      RM_Closure_Consumer_Diagnostic_Cross_Unit,
      RM_Closure_Consumer_Diagnostic_Generic_Substitution,
      RM_Closure_Consumer_Diagnostic_Dataflow,
      RM_Closure_Consumer_Diagnostic_Volatile_Atomic,
      RM_Closure_Consumer_Diagnostic_Overload_Type,
      RM_Closure_Consumer_Diagnostic_Representation,
      RM_Closure_Consumer_Diagnostic_Tasking_Protected,
      RM_Closure_Consumer_Diagnostic_Elaboration,
      RM_Closure_Consumer_Diagnostic_Accessibility,
      RM_Closure_Consumer_Diagnostic_Discriminant_Variant,
      RM_Closure_Consumer_Diagnostic_Exception_Finalization,
      RM_Closure_Consumer_Diagnostic_Renaming_Alias,
      RM_Closure_Consumer_Diagnostic_Predicate_Invariant,
      RM_Closure_Consumer_Diagnostic_Source_Fingerprint,
      RM_Closure_Consumer_Diagnostic_Substitution_Fingerprint,
      RM_Closure_Consumer_Diagnostic_Multiple,
      RM_Closure_Consumer_Diagnostic_Indeterminate,
      RM_Closure_Consumer_Diagnostic_Unknown);

   type RM_Closure_Consumer_Diagnostic_Severity is
     (RM_Closure_Consumer_Diagnostic_Info,
      RM_Closure_Consumer_Diagnostic_Warning,
      RM_Closure_Consumer_Diagnostic_Error);

   type RM_Closure_Consumer_Diagnostic_Status is
     (RM_Closure_Consumer_Diagnostic_Not_Checked,
      RM_Closure_Consumer_Diagnostic_Withheld_Accepted_Current,
      RM_Closure_Consumer_Diagnostic_Predicate_RM_Blocker,
      RM_Closure_Consumer_Diagnostic_Stabilized_Closure_Blocker,
      RM_Closure_Consumer_Diagnostic_Stale_Or_Fingerprint_Blocker,
      RM_Closure_Consumer_Diagnostic_AST_Or_Coverage_Blocker,
      RM_Closure_Consumer_Diagnostic_Cross_Unit_Blocker,
      RM_Closure_Consumer_Diagnostic_Generic_Substitution_Blocker,
      RM_Closure_Consumer_Diagnostic_Dataflow_Blocker,
      RM_Closure_Consumer_Diagnostic_Volatile_Atomic_Blocker,
      RM_Closure_Consumer_Diagnostic_Overload_Type_Blocker,
      RM_Closure_Consumer_Diagnostic_Representation_Blocker,
      RM_Closure_Consumer_Diagnostic_Tasking_Protected_Blocker,
      RM_Closure_Consumer_Diagnostic_Elaboration_Blocker,
      RM_Closure_Consumer_Diagnostic_Accessibility_Blocker,
      RM_Closure_Consumer_Diagnostic_Discriminant_Variant_Blocker,
      RM_Closure_Consumer_Diagnostic_Exception_Finalization_Blocker,
      RM_Closure_Consumer_Diagnostic_Renaming_Alias_Blocker,
      RM_Closure_Consumer_Diagnostic_Predicate_Invariant_Blocker,
      RM_Closure_Consumer_Diagnostic_Source_Fingerprint_Mismatch,
      RM_Closure_Consumer_Diagnostic_Substitution_Fingerprint_Mismatch,
      RM_Closure_Consumer_Diagnostic_Multiple_Blockers,
      RM_Closure_Consumer_Diagnostic_Indeterminate);

   type RM_Closure_Consumer_Diagnostic_Row is record
      Id                    : RM_Closure_Consumer_Diagnostic_Id := No_RM_Closure_Consumer_Diagnostic;
      Predicate_Row         : Predicate.Predicate_RM_Closure_Consumer_Id := Predicate.No_Predicate_RM_Closure_Consumer;
      Predicate_Status      : Predicate.Predicate_RM_Closure_Consumer_Status := Predicate.Predicate_RM_Closure_Consumer_Not_Checked;
      Predicate_Family      : Predicate.Predicate_RM_Closure_Consumer_Family := Predicate.Predicate_RM_Closure_Consumer_Family_None;
      Status                : RM_Closure_Consumer_Diagnostic_Status := RM_Closure_Consumer_Diagnostic_Not_Checked;
      Family                : RM_Closure_Consumer_Diagnostic_Family := RM_Closure_Consumer_Diagnostic_Unknown;
      Severity              : RM_Closure_Consumer_Diagnostic_Severity := RM_Closure_Consumer_Diagnostic_Warning;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Message               : Ada.Strings.Unbounded.Unbounded_String;
      Detail                : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint    : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Semantic_Fingerprint  : Natural := 0;
      Diagnostic_Fingerprint : Natural := 0;
      Emitted               : Boolean := False;
      Withheld_Current      : Boolean := False;
      Blocks_Downstream     : Boolean := False;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
   end record;

   type RM_Closure_Consumer_Diagnostic_Set is private;
   type RM_Closure_Consumer_Diagnostic_Model is private;

   procedure Clear (Model : in out RM_Closure_Consumer_Diagnostic_Model);

   function Build
     (Predicate_Model : Predicate.Predicate_RM_Closure_Consumer_Model)
      return RM_Closure_Consumer_Diagnostic_Model;

   function Row_Count (Model : RM_Closure_Consumer_Diagnostic_Model) return Natural;
   function Row_At
     (Model : RM_Closure_Consumer_Diagnostic_Model;
      Index : Positive) return RM_Closure_Consumer_Diagnostic_Row;

   function Query_Count (Set : RM_Closure_Consumer_Diagnostic_Set) return Natural;
   function Query_At
     (Set   : RM_Closure_Consumer_Diagnostic_Set;
      Index : Positive) return RM_Closure_Consumer_Diagnostic_Row;

   function Query_Status
     (Model  : RM_Closure_Consumer_Diagnostic_Model;
      Status : RM_Closure_Consumer_Diagnostic_Status)
      return RM_Closure_Consumer_Diagnostic_Set;
   function Query_Family
     (Model  : RM_Closure_Consumer_Diagnostic_Model;
      Family : RM_Closure_Consumer_Diagnostic_Family)
      return RM_Closure_Consumer_Diagnostic_Set;
   function Query_Node
     (Model : RM_Closure_Consumer_Diagnostic_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return RM_Closure_Consumer_Diagnostic_Set;
   function Query_Source_Fingerprint
     (Model       : RM_Closure_Consumer_Diagnostic_Model;
      Fingerprint : Natural) return RM_Closure_Consumer_Diagnostic_Set;

   function Count_Status
     (Model  : RM_Closure_Consumer_Diagnostic_Model;
      Status : RM_Closure_Consumer_Diagnostic_Status) return Natural;
   function Count_Family
     (Model  : RM_Closure_Consumer_Diagnostic_Model;
      Family : RM_Closure_Consumer_Diagnostic_Family) return Natural;

   function Error_Count (Model : RM_Closure_Consumer_Diagnostic_Model) return Natural;
   function Warning_Count (Model : RM_Closure_Consumer_Diagnostic_Model) return Natural;
   function Info_Count (Model : RM_Closure_Consumer_Diagnostic_Model) return Natural;
   function Emitted_Count (Model : RM_Closure_Consumer_Diagnostic_Model) return Natural;
   function Withheld_Current_Count (Model : RM_Closure_Consumer_Diagnostic_Model) return Natural;
   function Indeterminate_Count (Model : RM_Closure_Consumer_Diagnostic_Model) return Natural;
   function Fingerprint (Model : RM_Closure_Consumer_Diagnostic_Model) return Natural;

   function Is_Emitted (Status : RM_Closure_Consumer_Diagnostic_Status) return Boolean;
   function Is_Withheld_Current (Status : RM_Closure_Consumer_Diagnostic_Status) return Boolean;
   function Has_Error (Row : RM_Closure_Consumer_Diagnostic_Row) return Boolean;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => RM_Closure_Consumer_Diagnostic_Row);

   type RM_Closure_Consumer_Diagnostic_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type RM_Closure_Consumer_Diagnostic_Model is record
      Rows                   : Row_Vectors.Vector;
      Error_Total            : Natural := 0;
      Warning_Total          : Natural := 0;
      Info_Total             : Natural := 0;
      Emitted_Total          : Natural := 0;
      Withheld_Current_Total : Natural := 0;
      Indeterminate_Total    : Natural := 0;
      Fingerprint            : Natural := 0;
   end record;

end Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration;
