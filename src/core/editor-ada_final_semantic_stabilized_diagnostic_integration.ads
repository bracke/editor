with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Final_Semantic_Diagnostic_Provenance;
with Editor.Ada_Final_Semantic_Stabilized_Closure_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration is

   --  Case 1210 final semantic stabilized diagnostic integration.
   --
   --  This package consumes Case 1209 stabilized semantic closure rows and
   --  creates diagnostic/feed-boundary rows only for stabilized closure state.
   --  Stable accepted rows are withheld as non-diagnostic current closure;
   --  stable blocker rows are emitted with their original blocker family;
   --  recheck-required and indeterminate rows remain warnings rather than
   --  confident legal conclusions.  The model is deterministic,
   --  snapshot-owned, bounded, and side-effect-free.

   package Closure renames Editor.Ada_Final_Semantic_Stabilized_Closure_Legality;
   package Final_Prov renames Editor.Ada_Final_Semantic_Diagnostic_Provenance;

   subtype Final_Blocker_Family is Final_Prov.Final_Blocker_Family;
   subtype Final_Stabilized_Closure_Id is Closure.Final_Stabilized_Closure_Id;
   subtype Final_Stabilized_Closure_Status is Closure.Final_Stabilized_Closure_Status;
   subtype Final_Stabilized_Closure_Action is Closure.Final_Stabilized_Closure_Action;

   type Final_Stabilized_Diagnostic_Id is new Natural;
   No_Final_Stabilized_Diagnostic : constant Final_Stabilized_Diagnostic_Id := 0;

   type Final_Stabilized_Diagnostic_Family is
     (Final_Stabilized_Diagnostic_Cross_Unit,
      Final_Stabilized_Diagnostic_Overload_Type,
      Final_Stabilized_Diagnostic_Generic_Replay,
      Final_Stabilized_Diagnostic_Representation_Freezing,
      Final_Stabilized_Diagnostic_Flow_Contract,
      Final_Stabilized_Diagnostic_Tasking_Protected,
      Final_Stabilized_Diagnostic_Elaboration,
      Final_Stabilized_Diagnostic_Accessibility_Lifetime,
      Final_Stabilized_Diagnostic_Discriminant_Variant,
      Final_Stabilized_Diagnostic_AST_Coverage,
      Final_Stabilized_Diagnostic_View_Barrier,
      Final_Stabilized_Diagnostic_Stale_Input,
      Final_Stabilized_Diagnostic_Preserved_Error,
      Final_Stabilized_Diagnostic_Multiple,
      Final_Stabilized_Diagnostic_Indeterminate,
      Final_Stabilized_Diagnostic_Unknown);

   type Final_Stabilized_Diagnostic_Severity is
     (Final_Stabilized_Diagnostic_Info,
      Final_Stabilized_Diagnostic_Warning,
      Final_Stabilized_Diagnostic_Error);

   type Final_Stabilized_Diagnostic_Status is
     (Final_Stabilized_Diagnostic_Not_Checked,
      Final_Stabilized_Diagnostic_Withheld_Accepted_Current,
      Final_Stabilized_Diagnostic_Withheld_Accepted_Not_Required,
      Final_Stabilized_Diagnostic_Stale_Blocker,
      Final_Stabilized_Diagnostic_AST_Coverage_Blocker,
      Final_Stabilized_Diagnostic_Cross_Unit_Blocker,
      Final_Stabilized_Diagnostic_View_Barrier,
      Final_Stabilized_Diagnostic_Generic_Replay_Blocker,
      Final_Stabilized_Diagnostic_Overload_Type_Blocker,
      Final_Stabilized_Diagnostic_Representation_Freezing_Blocker,
      Final_Stabilized_Diagnostic_Flow_Contract_Blocker,
      Final_Stabilized_Diagnostic_Tasking_Protected_Blocker,
      Final_Stabilized_Diagnostic_Elaboration_Blocker,
      Final_Stabilized_Diagnostic_Accessibility_Lifetime_Blocker,
      Final_Stabilized_Diagnostic_Discriminant_Variant_Blocker,
      Final_Stabilized_Diagnostic_Preserved_Semantic_Error,
      Final_Stabilized_Diagnostic_Multiple_Prerequisites,
      Final_Stabilized_Diagnostic_Indeterminate,
      Final_Stabilized_Diagnostic_Recheck_Required);

   type Final_Stabilized_Diagnostic_Row is record
      Id                      : Final_Stabilized_Diagnostic_Id := No_Final_Stabilized_Diagnostic;
      Closure_Id              : Final_Stabilized_Closure_Id := Closure.No_Final_Stabilized_Closure;
      Closure_Status          : Final_Stabilized_Closure_Status := Closure.Final_Stabilized_Closure_Not_Checked;
      Closure_Action          : Final_Stabilized_Closure_Action := Closure.Final_Stabilized_Closure_Action_None;
      Status                  : Final_Stabilized_Diagnostic_Status := Final_Stabilized_Diagnostic_Not_Checked;
      Family                  : Final_Stabilized_Diagnostic_Family := Final_Stabilized_Diagnostic_Unknown;
      Severity                : Final_Stabilized_Diagnostic_Severity := Final_Stabilized_Diagnostic_Warning;
      Blocker_Family          : Final_Blocker_Family := Final_Prov.Final_Blocker_None;
      Node                    : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Start_Line              : Positive := 1;
      Start_Column            : Positive := 1;
      End_Line                : Positive := 1;
      End_Column              : Positive := 1;
      Priority                : Natural := 0;
      Dependency_Depth        : Natural := 0;
      Prerequisite_Depth      : Natural := 0;
      Emitted                 : Boolean := False;
      Withheld_Current        : Boolean := False;
      Requires_Recheck        : Boolean := False;
      Message                 : Ada.Strings.Unbounded.Unbounded_String;
      Detail                  : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint      : Natural := 0;
      Closure_Fingerprint     : Natural := 0;
      Diagnostic_Fingerprint  : Natural := 0;
   end record;

   type Final_Stabilized_Diagnostic_Set is private;
   type Final_Stabilized_Diagnostic_Model is private;

   procedure Clear (Model : in out Final_Stabilized_Diagnostic_Model);

   function Build
     (Closure_Model : Closure.Final_Stabilized_Closure_Model)
      return Final_Stabilized_Diagnostic_Model;

   function Row_Count (Model : Final_Stabilized_Diagnostic_Model) return Natural;
   function Row_At
     (Model : Final_Stabilized_Diagnostic_Model;
      Index : Positive) return Final_Stabilized_Diagnostic_Row;

   function Query_Count (Set : Final_Stabilized_Diagnostic_Set) return Natural;
   function Query_At
     (Set   : Final_Stabilized_Diagnostic_Set;
      Index : Positive) return Final_Stabilized_Diagnostic_Row;

   function Query_Status
     (Model  : Final_Stabilized_Diagnostic_Model;
      Status : Final_Stabilized_Diagnostic_Status) return Final_Stabilized_Diagnostic_Set;
   function Query_Family
     (Model  : Final_Stabilized_Diagnostic_Model;
      Family : Final_Stabilized_Diagnostic_Family) return Final_Stabilized_Diagnostic_Set;
   function Query_Blocker
     (Model   : Final_Stabilized_Diagnostic_Model;
      Blocker : Final_Blocker_Family) return Final_Stabilized_Diagnostic_Set;
   function Query_Node
     (Model : Final_Stabilized_Diagnostic_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_Stabilized_Diagnostic_Set;

   function Count_Status
     (Model  : Final_Stabilized_Diagnostic_Model;
      Status : Final_Stabilized_Diagnostic_Status) return Natural;
   function Count_Family
     (Model  : Final_Stabilized_Diagnostic_Model;
      Family : Final_Stabilized_Diagnostic_Family) return Natural;
   function Count_Blocker
     (Model   : Final_Stabilized_Diagnostic_Model;
      Blocker : Final_Blocker_Family) return Natural;

   function Error_Count (Model : Final_Stabilized_Diagnostic_Model) return Natural;
   function Warning_Count (Model : Final_Stabilized_Diagnostic_Model) return Natural;
   function Info_Count (Model : Final_Stabilized_Diagnostic_Model) return Natural;
   function Emitted_Count (Model : Final_Stabilized_Diagnostic_Model) return Natural;
   function Withheld_Current_Count (Model : Final_Stabilized_Diagnostic_Model) return Natural;
   function Recheck_Required_Count (Model : Final_Stabilized_Diagnostic_Model) return Natural;
   function Preserved_Error_Count (Model : Final_Stabilized_Diagnostic_Model) return Natural;
   function Indeterminate_Count (Model : Final_Stabilized_Diagnostic_Model) return Natural;
   function Fingerprint (Model : Final_Stabilized_Diagnostic_Model) return Natural;

   function Is_Emitted (Status : Final_Stabilized_Diagnostic_Status) return Boolean;
   function Is_Withheld_Current (Status : Final_Stabilized_Diagnostic_Status) return Boolean;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Final_Stabilized_Diagnostic_Row);

   type Final_Stabilized_Diagnostic_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Final_Stabilized_Diagnostic_Model is record
      Rows                   : Row_Vectors.Vector;
      Error_Total            : Natural := 0;
      Warning_Total          : Natural := 0;
      Info_Total             : Natural := 0;
      Emitted_Total          : Natural := 0;
      Withheld_Current_Total : Natural := 0;
      Recheck_Total          : Natural := 0;
      Preserved_Error_Total  : Natural := 0;
      Indeterminate_Total    : Natural := 0;
      Fingerprint            : Natural := 0;
   end record;

end Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration;
