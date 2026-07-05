with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Eligibility_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Application_Legality is

   --  Case 1276 recheck application for the direct RM-completion closure
   --  consumer chain.
   --
   --  This package consumes Case 1275 bounded recheck eligibility rows and
   --  applies them back into the direct RM-completion closure consumer
   --  diagnostic/closure boundary.  A direct consumer conclusion is current
   --  only when the prerequisite recheck chain is eligible now or the row is
   --  already accepted non-diagnostic semantic evidence.  Rows blocked by
   --  cross-unit, elaboration, accessibility, exception/finalization,
   --  overload/type, representation/freezing, tasking/protected,
   --  dataflow/initialization, predicate/invariant, AST/coverage, generic
   --  substitution, fingerprint, multiple-prerequisite, or indeterminate
   --  evidence remain withheld with their original blocker family intact.

   package Recheck renames Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Eligibility_Legality;

   subtype RM_Closure_Consumer_Application_Family is Recheck.RM_Closure_Consumer_Recheck_Family;
   subtype RM_Closure_Consumer_Eligibility_Status is Recheck.RM_Closure_Consumer_Recheck_Status;
   subtype RM_Closure_Consumer_Eligibility_Action is Recheck.RM_Closure_Consumer_Recheck_Action;

   type RM_Closure_Consumer_Application_Id is new Natural;
   No_RM_Closure_Consumer_Application : constant RM_Closure_Consumer_Application_Id := 0;

   type RM_Closure_Consumer_Application_Status is
     (RM_Closure_Consumer_Application_Not_Checked,
      RM_Closure_Consumer_Application_Current_Accepted,
      RM_Closure_Consumer_Application_Current_Non_Diagnostic_Evidence,
      RM_Closure_Consumer_Application_Not_Required,
      RM_Closure_Consumer_Application_Withheld_Stale_Or_Fingerprint,
      RM_Closure_Consumer_Application_Withheld_AST_Or_Coverage,
      RM_Closure_Consumer_Application_Withheld_Cross_Unit,
      RM_Closure_Consumer_Application_Withheld_Generic_Substitution,
      RM_Closure_Consumer_Application_Withheld_Dataflow,
      RM_Closure_Consumer_Application_Withheld_Volatile_Atomic,
      RM_Closure_Consumer_Application_Withheld_Overload_Type,
      RM_Closure_Consumer_Application_Withheld_Representation,
      RM_Closure_Consumer_Application_Withheld_Tasking_Protected,
      RM_Closure_Consumer_Application_Withheld_Elaboration,
      RM_Closure_Consumer_Application_Withheld_Accessibility,
      RM_Closure_Consumer_Application_Withheld_Discriminant_Variant,
      RM_Closure_Consumer_Application_Withheld_Exception_Finalization,
      RM_Closure_Consumer_Application_Withheld_Renaming_Alias,
      RM_Closure_Consumer_Application_Withheld_Predicate_Invariant,
      RM_Closure_Consumer_Application_Withheld_Source_Fingerprint,
      RM_Closure_Consumer_Application_Withheld_Substitution_Fingerprint,
      RM_Closure_Consumer_Application_Withheld_Multiple_Prerequisites,
      RM_Closure_Consumer_Application_Indeterminate);

   type RM_Closure_Consumer_Application_Action is
     (RM_Closure_Consumer_Application_Action_None,
      RM_Closure_Consumer_Application_Action_Expose_Current,
      RM_Closure_Consumer_Application_Action_Keep_Non_Diagnostic_Evidence,
      RM_Closure_Consumer_Application_Action_Skip_Not_Required,
      RM_Closure_Consumer_Application_Action_Withhold_For_Fingerprint,
      RM_Closure_Consumer_Application_Action_Withhold_For_AST_Repair,
      RM_Closure_Consumer_Application_Action_Withhold_For_Cross_Unit,
      RM_Closure_Consumer_Application_Action_Withhold_For_Generic_Substitution,
      RM_Closure_Consumer_Application_Action_Withhold_For_Dataflow,
      RM_Closure_Consumer_Application_Action_Withhold_For_Volatile_Atomic,
      RM_Closure_Consumer_Application_Action_Withhold_For_Overload_Type,
      RM_Closure_Consumer_Application_Action_Withhold_For_Representation,
      RM_Closure_Consumer_Application_Action_Withhold_For_Tasking_Protected,
      RM_Closure_Consumer_Application_Action_Withhold_For_Elaboration,
      RM_Closure_Consumer_Application_Action_Withhold_For_Accessibility,
      RM_Closure_Consumer_Application_Action_Withhold_For_Discriminants,
      RM_Closure_Consumer_Application_Action_Withhold_For_Exception_Finalization,
      RM_Closure_Consumer_Application_Action_Withhold_For_Renaming,
      RM_Closure_Consumer_Application_Action_Withhold_For_Predicate,
      RM_Closure_Consumer_Application_Action_Withhold_For_Source_Fingerprint,
      RM_Closure_Consumer_Application_Action_Withhold_For_Substitution_Fingerprint,
      RM_Closure_Consumer_Application_Action_Split_Prerequisites,
      RM_Closure_Consumer_Application_Action_Degrade);

   type RM_Closure_Consumer_Application_Row is record
      Id                       : RM_Closure_Consumer_Application_Id := No_RM_Closure_Consumer_Application;
      Eligibility_Id           : Recheck.RM_Closure_Consumer_Recheck_Id := Recheck.No_RM_Closure_Consumer_Recheck;
      Worklist_Item            : Recheck.Worklist.RM_Closure_Consumer_Worklist_Id := Recheck.Worklist.No_RM_Closure_Consumer_Worklist_Item;
      Diagnostic_Row           : Recheck.Worklist.Diagnostics.RM_Closure_Consumer_Diagnostic_Id := Recheck.Worklist.Diagnostics.No_RM_Closure_Consumer_Diagnostic;
      Eligibility_Status       : RM_Closure_Consumer_Eligibility_Status := Recheck.RM_Closure_Consumer_Recheck_Not_Checked;
      Eligibility_Action       : RM_Closure_Consumer_Eligibility_Action := Recheck.RM_Closure_Consumer_Recheck_Action_None;
      Status                   : RM_Closure_Consumer_Application_Status := RM_Closure_Consumer_Application_Not_Checked;
      Action                   : RM_Closure_Consumer_Application_Action := RM_Closure_Consumer_Application_Action_None;
      Family                   : RM_Closure_Consumer_Application_Family := Recheck.Worklist.Diagnostics.RM_Closure_Consumer_Diagnostic_Unknown;
      Node                     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Current                  : Boolean := False;
      Accepted                 : Boolean := False;
      Withheld                 : Boolean := False;
      Blocks_Downstream        : Boolean := False;
      Priority_Rank            : Natural := 0;
      Source_Fingerprint       : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Semantic_Fingerprint     : Natural := 0;
      Diagnostic_Fingerprint   : Natural := 0;
      Worklist_Fingerprint     : Natural := 0;
      Eligibility_Fingerprint  : Natural := 0;
      Application_Fingerprint  : Natural := 0;
      Start_Line               : Positive := 1;
      Start_Column             : Positive := 1;
      End_Line                 : Positive := 1;
      End_Column               : Positive := 1;
      Message                  : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type RM_Closure_Consumer_Application_Model is private;
   type RM_Closure_Consumer_Application_Set is private;

   procedure Clear (Model : in out RM_Closure_Consumer_Application_Model);

   function Build
     (Eligibility : Recheck.RM_Closure_Consumer_Recheck_Model)
      return RM_Closure_Consumer_Application_Model;

   function Count (Model : RM_Closure_Consumer_Application_Model) return Natural;
   function Row_Count (Model : RM_Closure_Consumer_Application_Model) return Natural renames Count;
   function Row_At
     (Model : RM_Closure_Consumer_Application_Model;
      Index : Positive) return RM_Closure_Consumer_Application_Row;

   function Query_Count (Set : RM_Closure_Consumer_Application_Set) return Natural;
   function Query_At
     (Set   : RM_Closure_Consumer_Application_Set;
      Index : Positive) return RM_Closure_Consumer_Application_Row;

   function Query_Status
     (Model  : RM_Closure_Consumer_Application_Model;
      Status : RM_Closure_Consumer_Application_Status)
      return RM_Closure_Consumer_Application_Set;
   function Query_Action
     (Model  : RM_Closure_Consumer_Application_Model;
      Action : RM_Closure_Consumer_Application_Action)
      return RM_Closure_Consumer_Application_Set;
   function Query_Family
     (Model  : RM_Closure_Consumer_Application_Model;
      Family : RM_Closure_Consumer_Application_Family)
      return RM_Closure_Consumer_Application_Set;
   function Query_Node
     (Model : RM_Closure_Consumer_Application_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return RM_Closure_Consumer_Application_Set;
   function Query_Source_Fingerprint
     (Model       : RM_Closure_Consumer_Application_Model;
      Fingerprint : Natural)
      return RM_Closure_Consumer_Application_Set;
   function Query_Substitution_Fingerprint
     (Model       : RM_Closure_Consumer_Application_Model;
      Fingerprint : Natural)
      return RM_Closure_Consumer_Application_Set;

   function Count_Status
     (Model  : RM_Closure_Consumer_Application_Model;
      Status : RM_Closure_Consumer_Application_Status) return Natural;
   function Count_Action
     (Model  : RM_Closure_Consumer_Application_Model;
      Action : RM_Closure_Consumer_Application_Action) return Natural;
   function Count_Family
     (Model  : RM_Closure_Consumer_Application_Model;
      Family : RM_Closure_Consumer_Application_Family) return Natural;

   function Accepted_Count (Model : RM_Closure_Consumer_Application_Model) return Natural;
   function Withheld_Count (Model : RM_Closure_Consumer_Application_Model) return Natural;
   function Current_Count (Model : RM_Closure_Consumer_Application_Model) return Natural;
   function Indeterminate_Count (Model : RM_Closure_Consumer_Application_Model) return Natural;
   function Stable_Fingerprint (Model : RM_Closure_Consumer_Application_Model) return Natural;

   function Is_Current (Row : RM_Closure_Consumer_Application_Row) return Boolean;
   function Is_Accepted (Row : RM_Closure_Consumer_Application_Row) return Boolean;
   function Is_Withheld (Row : RM_Closure_Consumer_Application_Row) return Boolean;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => RM_Closure_Consumer_Application_Row);

   type RM_Closure_Consumer_Application_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type RM_Closure_Consumer_Application_Model is record
      Rows                : Row_Vectors.Vector;
      Accepted_Total      : Natural := 0;
      Withheld_Total      : Natural := 0;
      Current_Total       : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

end Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Application_Legality;
