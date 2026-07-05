with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Dataflow_Generic_Shared_State_RM_Completion_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration is

   --  Case 1256 diagnostic integration for the RM-completed
   --  generic/shared-state semantic chain.
   --
   --  This package consumes Case 1255 dataflow/initialization RM-completion
   --  rows and exposes diagnostic-boundary rows only for blocking semantic
   --  conclusions.  Accepted RM-completed rows are retained as current
   --  non-diagnostic evidence, while blockers keep their original family:
   --  cross-unit closure, elaboration, accessibility, exception/finalization,
   --  predicate/invariant, dataflow, overload/type, representation/freezing,
   --  tasking/protected, AST repair, stale fingerprint, view barrier,
   --  multiple blockers, and indeterminate state.

   package Dataflow_RM renames Editor.Ada_Dataflow_Generic_Shared_State_RM_Completion_Legality;

   type RM_Completion_Diagnostic_Id is new Natural;
   No_RM_Completion_Diagnostic : constant RM_Completion_Diagnostic_Id := 0;

   type RM_Completion_Diagnostic_Family is
     (RM_Completion_Diagnostic_Accepted,
      RM_Completion_Diagnostic_Prior_Dataflow,
      RM_Completion_Diagnostic_Cross_Unit_RM_Completion,
      RM_Completion_Diagnostic_Elaboration_RM_Completion,
      RM_Completion_Diagnostic_Accessibility_RM_Completion,
      RM_Completion_Diagnostic_Exception_Finalization_RM_Completion,
      RM_Completion_Diagnostic_Predicate_RM_Completion,
      RM_Completion_Diagnostic_Overload_RM_Completion,
      RM_Completion_Diagnostic_Representation_RM_Completion,
      RM_Completion_Diagnostic_Tasking_RM_Completion,
      RM_Completion_Diagnostic_AST_Repair,
      RM_Completion_Diagnostic_Dataflow_Read_Before_Write,
      RM_Completion_Diagnostic_Dataflow_Component_Init,
      RM_Completion_Diagnostic_Dataflow_Out_Parameter,
      RM_Completion_Diagnostic_Dataflow_Return_Object,
      RM_Completion_Diagnostic_Dataflow_Branch_Loop_Merge,
      RM_Completion_Diagnostic_Exception_Path,
      RM_Completion_Diagnostic_Finalization,
      RM_Completion_Diagnostic_Access_Escape,
      RM_Completion_Diagnostic_Variant_Component,
      RM_Completion_Diagnostic_Volatile_Atomic_Effect,
      RM_Completion_Diagnostic_Generic_Substitution,
      RM_Completion_Diagnostic_Dispatching_Effect,
      RM_Completion_Diagnostic_View_Barrier,
      RM_Completion_Diagnostic_Source_Fingerprint,
      RM_Completion_Diagnostic_Substitution_Fingerprint,
      RM_Completion_Diagnostic_Multiple,
      RM_Completion_Diagnostic_Indeterminate,
      RM_Completion_Diagnostic_Unknown);

   type RM_Completion_Diagnostic_Severity is
     (RM_Completion_Diagnostic_Info,
      RM_Completion_Diagnostic_Warning,
      RM_Completion_Diagnostic_Error);

   type RM_Completion_Diagnostic_Status is
     (RM_Completion_Diagnostic_Not_Checked,
      RM_Completion_Diagnostic_Withheld_Accepted_Current,
      RM_Completion_Diagnostic_Prior_Dataflow_Blocker,
      RM_Completion_Diagnostic_Cross_Unit_RM_Blocker,
      RM_Completion_Diagnostic_Elaboration_RM_Blocker,
      RM_Completion_Diagnostic_Accessibility_RM_Blocker,
      RM_Completion_Diagnostic_Exception_Finalization_RM_Blocker,
      RM_Completion_Diagnostic_Predicate_RM_Blocker,
      RM_Completion_Diagnostic_Overload_RM_Blocker,
      RM_Completion_Diagnostic_Representation_RM_Blocker,
      RM_Completion_Diagnostic_Tasking_RM_Blocker,
      RM_Completion_Diagnostic_AST_Repair_Blocker,
      RM_Completion_Diagnostic_Dataflow_Read_Before_Write_Blocker,
      RM_Completion_Diagnostic_Dataflow_Component_Init_Blocker,
      RM_Completion_Diagnostic_Dataflow_Out_Parameter_Blocker,
      RM_Completion_Diagnostic_Dataflow_Return_Object_Blocker,
      RM_Completion_Diagnostic_Dataflow_Branch_Loop_Merge_Blocker,
      RM_Completion_Diagnostic_Exception_Path_Blocker,
      RM_Completion_Diagnostic_Finalization_Blocker,
      RM_Completion_Diagnostic_Access_Escape_Blocker,
      RM_Completion_Diagnostic_Variant_Component_Blocker,
      RM_Completion_Diagnostic_Volatile_Atomic_Effect_Blocker,
      RM_Completion_Diagnostic_Generic_Substitution_Blocker,
      RM_Completion_Diagnostic_Dispatching_Effect_Blocker,
      RM_Completion_Diagnostic_View_Barrier,
      RM_Completion_Diagnostic_Source_Fingerprint_Mismatch,
      RM_Completion_Diagnostic_Substitution_Fingerprint_Mismatch,
      RM_Completion_Diagnostic_Multiple_Blockers,
      RM_Completion_Diagnostic_Indeterminate);

   type RM_Completion_Diagnostic_Row is record
      Id                    : RM_Completion_Diagnostic_Id := No_RM_Completion_Diagnostic;
      Dataflow_Row          : Dataflow_RM.Dataflow_RM_Completion_Row_Id := Dataflow_RM.No_Dataflow_RM_Completion_Row;
      Dataflow_Status       : Dataflow_RM.Dataflow_RM_Completion_Status := Dataflow_RM.Dataflow_RM_Completion_Not_Checked;
      Status                : RM_Completion_Diagnostic_Status := RM_Completion_Diagnostic_Not_Checked;
      Family                : RM_Completion_Diagnostic_Family := RM_Completion_Diagnostic_Unknown;
      Severity              : RM_Completion_Diagnostic_Severity := RM_Completion_Diagnostic_Warning;
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

   type RM_Completion_Diagnostic_Set is private;
   type RM_Completion_Diagnostic_Model is private;

   procedure Clear (Model : in out RM_Completion_Diagnostic_Model);

   function Build
     (Dataflow_Model : Dataflow_RM.Dataflow_RM_Completion_Model)
      return RM_Completion_Diagnostic_Model;

   function Row_Count (Model : RM_Completion_Diagnostic_Model) return Natural;
   function Row_At
     (Model : RM_Completion_Diagnostic_Model;
      Index : Positive) return RM_Completion_Diagnostic_Row;

   function Query_Count (Set : RM_Completion_Diagnostic_Set) return Natural;
   function Query_At
     (Set   : RM_Completion_Diagnostic_Set;
      Index : Positive) return RM_Completion_Diagnostic_Row;

   function Query_Status
     (Model  : RM_Completion_Diagnostic_Model;
      Status : RM_Completion_Diagnostic_Status)
      return RM_Completion_Diagnostic_Set;
   function Query_Family
     (Model  : RM_Completion_Diagnostic_Model;
      Family : RM_Completion_Diagnostic_Family)
      return RM_Completion_Diagnostic_Set;
   function Query_Node
     (Model : RM_Completion_Diagnostic_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return RM_Completion_Diagnostic_Set;
   function Query_Source_Fingerprint
     (Model       : RM_Completion_Diagnostic_Model;
      Fingerprint : Natural) return RM_Completion_Diagnostic_Set;

   function Count_Status
     (Model  : RM_Completion_Diagnostic_Model;
      Status : RM_Completion_Diagnostic_Status) return Natural;
   function Count_Family
     (Model  : RM_Completion_Diagnostic_Model;
      Family : RM_Completion_Diagnostic_Family) return Natural;

   function Error_Count (Model : RM_Completion_Diagnostic_Model) return Natural;
   function Warning_Count (Model : RM_Completion_Diagnostic_Model) return Natural;
   function Info_Count (Model : RM_Completion_Diagnostic_Model) return Natural;
   function Emitted_Count (Model : RM_Completion_Diagnostic_Model) return Natural;
   function Withheld_Current_Count (Model : RM_Completion_Diagnostic_Model) return Natural;
   function Indeterminate_Count (Model : RM_Completion_Diagnostic_Model) return Natural;
   function Fingerprint (Model : RM_Completion_Diagnostic_Model) return Natural;

   function Is_Emitted (Status : RM_Completion_Diagnostic_Status) return Boolean;
   function Is_Withheld_Current (Status : RM_Completion_Diagnostic_Status) return Boolean;
   function Has_Error (Row : RM_Completion_Diagnostic_Row) return Boolean;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => RM_Completion_Diagnostic_Row);

   type RM_Completion_Diagnostic_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type RM_Completion_Diagnostic_Model is record
      Rows                   : Row_Vectors.Vector;
      Error_Total            : Natural := 0;
      Warning_Total          : Natural := 0;
      Info_Total             : Natural := 0;
      Emitted_Total          : Natural := 0;
      Withheld_Current_Total : Natural := 0;
      Indeterminate_Total    : Natural := 0;
      Fingerprint            : Natural := 0;
   end record;

end Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration;
