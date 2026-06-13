with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Diagnostic_Provenance;
with Editor.Ada_Final_Semantic_Diagnostic_Integration;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Final_Semantic_Diagnostic_Provenance is

   --  Pass1196 final semantic diagnostic provenance.
   --
   --  This package preserves the semantic origin of final diagnostic rows after
   --  Pass1194/1195 diagnostic integration and unified feed/index insertion.
   --  It is not a projection/status layer: it keeps the final blocker family,
   --  original final semantic status, source node/span/fingerprints, optional
   --  feed/index/base-provenance links, and stale/withheld decisions so semantic
   --  debugging can distinguish cross-unit, overload/type, generic replay,
   --  representation/freezing, flow/contract, tasking/protected, elaboration,
   --  accessibility, discriminant/variant, AST repair, coverage-gate, multiple,
   --  and indeterminate blockers.  The model is deterministic, bounded, and
   --  snapshot-owned.  It performs no parsing, file IO, save/reload, dirty-state
   --  mutation, command/keybinding/workspace/render mutation, LSP use, compiler
   --  invocation, or external parser generation.

   package Final_Diag renames Editor.Ada_Final_Semantic_Diagnostic_Integration;
   package Base_Prov renames Editor.Ada_Diagnostic_Provenance;
   package Feed renames Editor.Ada_Semantic_Diagnostic_Feed;
   package Index renames Editor.Ada_Semantic_Diagnostic_Index;

   type Final_Provenance_Id is new Natural;
   No_Final_Provenance : constant Final_Provenance_Id := 0;

   type Final_Provenance_Status is
     (Final_Provenance_Not_Checked,
      Final_Provenance_Withheld_Legal,
      Final_Provenance_Emitted_Error,
      Final_Provenance_Emitted_Warning,
      Final_Provenance_View_Barrier,
      Final_Provenance_Stale_Rejected,
      Final_Provenance_Indeterminate,
      Final_Provenance_Multiple_Blockers);

   type Final_Provenance_Stage is
     (Final_Stage_None,
      Final_Stage_Final_Semantic_Integration,
      Final_Stage_Unified_Feed,
      Final_Stage_Index,
      Final_Stage_Base_Provenance,
      Final_Stage_Stale_Rejection,
      Final_Stage_Withheld_Legal);

   type Final_Blocker_Family is
     (Final_Blocker_None,
      Final_Blocker_Cross_Unit,
      Final_Blocker_Overload_Type,
      Final_Blocker_Generic_Replay,
      Final_Blocker_Representation_Freezing,
      Final_Blocker_Flow_Contract,
      Final_Blocker_Tasking_Protected,
      Final_Blocker_Elaboration,
      Final_Blocker_Accessibility_Lifetime,
      Final_Blocker_Discriminant_Variant,
      Final_Blocker_AST_Repair,
      Final_Blocker_Coverage_Gate,
      Final_Blocker_View_Barrier,
      Final_Blocker_Multiple,
      Final_Blocker_Unknown);

   type Final_Provenance_Info is record
      Id                : Final_Provenance_Id := No_Final_Provenance;
      Final_Diagnostic  : Final_Diag.Final_Diagnostic_Id := Final_Diag.No_Final_Diagnostic;
      Final_Status      : Final_Diag.Final_Diagnostic_Status := Final_Diag.Final_Diagnostic_Not_Checked;
      Final_Family      : Final_Diag.Final_Diagnostic_Source_Family := Final_Diag.Final_Diagnostic_Unknown;
      Blocker_Family    : Final_Blocker_Family := Final_Blocker_None;
      Status            : Final_Provenance_Status := Final_Provenance_Not_Checked;
      Stage             : Final_Provenance_Stage := Final_Stage_None;
      Severity          : Feed.Semantic_Diagnostic_Feed_Severity := Feed.Semantic_Diagnostic_Feed_Info;
      Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Feed_Entry        : Feed.Semantic_Diagnostic_Feed_Id := Feed.No_Semantic_Diagnostic_Feed_Entry;
      Index_Entry       : Index.Semantic_Diagnostic_Index_Id := Index.No_Semantic_Diagnostic_Index_Entry;
      Base_Provenance   : Base_Prov.Diagnostic_Provenance_Id := Base_Prov.No_Diagnostic_Provenance;
      Base_Stage        : Base_Prov.Diagnostic_Provenance_Stage := Base_Prov.Diagnostic_Provenance_No_Stage;
      Message           : Ada.Strings.Unbounded.Unbounded_String;
      Chain_Summary     : Ada.Strings.Unbounded.Unbounded_String;
      Start_Line        : Positive := 1;
      Start_Column      : Positive := 1;
      End_Line          : Positive := 1;
      End_Column        : Positive := 1;
      Source_Fingerprint : Natural := 0;
      Diagnostic_Fingerprint : Natural := 0;
      Feed_Fingerprint  : Natural := 0;
      Index_Fingerprint : Natural := 0;
      Base_Fingerprint  : Natural := 0;
      Fingerprint       : Natural := 0;
   end record;

   type Final_Provenance_Model is private;
   type Final_Provenance_Set is private;

   procedure Clear (Model : in out Final_Provenance_Model);

   function Build
     (Diagnostics : Final_Diag.Final_Diagnostic_Model)
      return Final_Provenance_Model;

   function Build_With_Feed_And_Index
     (Diagnostics : Final_Diag.Final_Diagnostic_Model;
      Feed_Model  : Feed.Semantic_Diagnostic_Feed_Model;
      Index_Model : Index.Semantic_Diagnostic_Index_Model)
      return Final_Provenance_Model;

   function Build_With_Base_Provenance
     (Diagnostics : Final_Diag.Final_Diagnostic_Model;
      Feed_Model  : Feed.Semantic_Diagnostic_Feed_Model;
      Index_Model : Index.Semantic_Diagnostic_Index_Model;
      Provenance  : Base_Prov.Diagnostic_Provenance_Model)
      return Final_Provenance_Model;

   function Row_Count (Model : Final_Provenance_Model) return Natural;
   function Row_At
     (Model : Final_Provenance_Model;
      Index : Positive) return Final_Provenance_Info;

   function Rows_For_Status
     (Model  : Final_Provenance_Model;
      Status : Final_Provenance_Status) return Final_Provenance_Set;
   function Rows_For_Blocker
     (Model   : Final_Provenance_Model;
      Blocker : Final_Blocker_Family) return Final_Provenance_Set;
   function Rows_For_Stage
     (Model : Final_Provenance_Model;
      Stage : Final_Provenance_Stage) return Final_Provenance_Set;
   function First_For_Node
     (Model : Final_Provenance_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_Provenance_Info;

   function Set_Count (Set : Final_Provenance_Set) return Natural;
   function Set_At
     (Set   : Final_Provenance_Set;
      Index : Positive) return Final_Provenance_Info;

   function Count_Status
     (Model  : Final_Provenance_Model;
      Status : Final_Provenance_Status) return Natural;
   function Count_Blocker
     (Model   : Final_Provenance_Model;
      Blocker : Final_Blocker_Family) return Natural;
   function Count_Stage
     (Model : Final_Provenance_Model;
      Stage : Final_Provenance_Stage) return Natural;

   function Withheld_Count (Model : Final_Provenance_Model) return Natural;
   function Error_Count (Model : Final_Provenance_Model) return Natural;
   function Warning_Count (Model : Final_Provenance_Model) return Natural;
   function View_Barrier_Count (Model : Final_Provenance_Model) return Natural;
   function Stale_Rejected_Count (Model : Final_Provenance_Model) return Natural;
   function Indeterminate_Count (Model : Final_Provenance_Model) return Natural;
   function Multiple_Blocker_Count (Model : Final_Provenance_Model) return Natural;
   function Feed_Link_Count (Model : Final_Provenance_Model) return Natural;
   function Index_Link_Count (Model : Final_Provenance_Model) return Natural;
   function Base_Link_Count (Model : Final_Provenance_Model) return Natural;
   function Fingerprint (Model : Final_Provenance_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Final_Provenance_Info);

   type Final_Provenance_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Final_Provenance_Model is record
      Rows                   : Row_Vectors.Vector;
      Withheld_Total         : Natural := 0;
      Error_Total            : Natural := 0;
      Warning_Total          : Natural := 0;
      View_Barrier_Total     : Natural := 0;
      Stale_Total            : Natural := 0;
      Indeterminate_Total    : Natural := 0;
      Multiple_Blocker_Total : Natural := 0;
      Feed_Link_Total        : Natural := 0;
      Index_Link_Total       : Natural := 0;
      Base_Link_Total        : Natural := 0;
      Fingerprint            : Natural := 0;
   end record;

end Editor.Ada_Final_Semantic_Diagnostic_Provenance;
