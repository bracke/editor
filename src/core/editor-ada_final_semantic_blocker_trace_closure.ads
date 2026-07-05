with Ada.Containers.Vectors;
with Editor.Ada_Final_Semantic_Diagnostic_Provenance;
with Editor.Ada_Final_Semantic_Diagnostic_Search_Index;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Final_Semantic_Blocker_Trace_Closure is

   --  Case 1198 final semantic blocker trace closure.
   --
   --  This package groups final semantic diagnostic provenance/search-index rows
   --  into deterministic trace chains.  It is a semantic debugging model, not a
   --  projection layer: each chain preserves blocker family, final provenance
   --  state, source node/span, source and trace fingerprints, feed/index links,
   --  stale/withheld decisions, and whether the failure is local, cross-unit,
   --  generic-replay, representation/freezing, flow/contract, tasking,
   --  accessibility, discriminant/variant, AST-repair, coverage-gate, view, or
   --  multiple-blocker rooted.  The model is bounded and snapshot-owned and
   --  performs no parsing, file IO, save/reload, dirty-state mutation,
   --  command/keybinding/workspace/render mutation, LSP use, compiler
   --  invocation, or external parser generation.

   package Final_Prov renames Editor.Ada_Final_Semantic_Diagnostic_Provenance;
   package Final_Index renames Editor.Ada_Final_Semantic_Diagnostic_Search_Index;
   package Feed renames Editor.Ada_Semantic_Diagnostic_Feed;
   package Base_Index renames Editor.Ada_Semantic_Diagnostic_Index;

   subtype Final_Blocker_Family is Final_Prov.Final_Blocker_Family;
   subtype Final_Provenance_Status is Final_Prov.Final_Provenance_Status;
   subtype Final_Provenance_Stage is Final_Prov.Final_Provenance_Stage;

   type Final_Blocker_Trace_Id is new Natural;
   No_Final_Blocker_Trace : constant Final_Blocker_Trace_Id := 0;

   type Final_Blocker_Trace_Status is
     (Final_Trace_Accepted_Legal,
      Final_Trace_Emitted_Error,
      Final_Trace_Emitted_Warning,
      Final_Trace_View_Barrier,
      Final_Trace_Stale_Rejected,
      Final_Trace_Indeterminate,
      Final_Trace_Multiple_Blockers,
      Final_Trace_Missing_Search_Index,
      Final_Trace_Not_Checked);

   type Final_Blocker_Trace_Root is
     (Final_Trace_Root_None,
      Final_Trace_Root_Local,
      Final_Trace_Root_Cross_Unit,
      Final_Trace_Root_Generic_Replay,
      Final_Trace_Root_Representation_Freezing,
      Final_Trace_Root_Flow_Contract,
      Final_Trace_Root_Tasking_Protected,
      Final_Trace_Root_Elaboration,
      Final_Trace_Root_Accessibility_Lifetime,
      Final_Trace_Root_Discriminant_Variant,
      Final_Trace_Root_AST_Repair,
      Final_Trace_Root_Coverage_Gate,
      Final_Trace_Root_View_Barrier,
      Final_Trace_Root_Multiple,
      Final_Trace_Root_Unknown);

   type Final_Blocker_Trace_Link is record
      Search_Index_Row : Natural := 0;
      Provenance_Index : Natural := 0;
      Feed_Entry       : Feed.Semantic_Diagnostic_Feed_Id := Feed.No_Semantic_Diagnostic_Feed_Entry;
      Index_Entry      : Base_Index.Semantic_Diagnostic_Index_Id := Base_Index.No_Semantic_Diagnostic_Index_Entry;
      Fingerprint      : Natural := 0;
   end record;

   type Final_Blocker_Trace is record
      Id                 : Final_Blocker_Trace_Id := No_Final_Blocker_Trace;
      Status             : Final_Blocker_Trace_Status := Final_Trace_Not_Checked;
      Root               : Final_Blocker_Trace_Root := Final_Trace_Root_None;
      Blocker_Family     : Final_Blocker_Family := Final_Prov.Final_Blocker_None;
      Provenance_Status  : Final_Provenance_Status := Final_Prov.Final_Provenance_Not_Checked;
      Stage              : Final_Provenance_Stage := Final_Prov.Final_Stage_None;
      Node               : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Start_Line         : Positive := 1;
      Start_Column       : Positive := 1;
      End_Line           : Positive := 1;
      End_Column         : Positive := 1;
      Source_Fingerprint : Natural := 0;
      Search_Link        : Final_Blocker_Trace_Link;
      Related_Count      : Natural := 0;
      Has_Feed_Link      : Boolean := False;
      Has_Index_Link     : Boolean := False;
      Fingerprint        : Natural := 0;
   end record;

   type Final_Blocker_Trace_Set is private;
   type Final_Blocker_Trace_Model is private;

   procedure Clear (Model : in out Final_Blocker_Trace_Model);

   function Build
     (Search_Index : Final_Index.Final_Search_Index_Model)
      return Final_Blocker_Trace_Model;

   function Build_With_Provenance
     (Search_Index : Final_Index.Final_Search_Index_Model;
      Provenance   : Final_Prov.Final_Provenance_Model)
      return Final_Blocker_Trace_Model;

   function Trace_Count (Model : Final_Blocker_Trace_Model) return Natural;
   function Trace_At
     (Model : Final_Blocker_Trace_Model;
      Index : Positive) return Final_Blocker_Trace;

   function Set_Count (Set : Final_Blocker_Trace_Set) return Natural;
   function Set_At
     (Set   : Final_Blocker_Trace_Set;
      Index : Positive) return Final_Blocker_Trace;

   function Query_Blocker
     (Model   : Final_Blocker_Trace_Model;
      Blocker : Final_Blocker_Family) return Final_Blocker_Trace_Set;
   function Query_Status
     (Model  : Final_Blocker_Trace_Model;
      Status : Final_Blocker_Trace_Status) return Final_Blocker_Trace_Set;
   function Query_Root
     (Model : Final_Blocker_Trace_Model;
      Root  : Final_Blocker_Trace_Root) return Final_Blocker_Trace_Set;
   function Query_Node
     (Model : Final_Blocker_Trace_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_Blocker_Trace_Set;
   function Query_Position
     (Model  : Final_Blocker_Trace_Model;
      Line   : Positive;
      Column : Positive) return Final_Blocker_Trace_Set;
   function Query_Source_Fingerprint
     (Model       : Final_Blocker_Trace_Model;
      Fingerprint : Natural) return Final_Blocker_Trace_Set;

   function Count_Blocker
     (Model   : Final_Blocker_Trace_Model;
      Blocker : Final_Blocker_Family) return Natural;
   function Count_Status
     (Model  : Final_Blocker_Trace_Model;
      Status : Final_Blocker_Trace_Status) return Natural;
   function Count_Root
     (Model : Final_Blocker_Trace_Model;
      Root  : Final_Blocker_Trace_Root) return Natural;

   function Legal_Trace_Count (Model : Final_Blocker_Trace_Model) return Natural;
   function Error_Trace_Count (Model : Final_Blocker_Trace_Model) return Natural;
   function Warning_Trace_Count (Model : Final_Blocker_Trace_Model) return Natural;
   function View_Barrier_Trace_Count (Model : Final_Blocker_Trace_Model) return Natural;
   function Stale_Trace_Count (Model : Final_Blocker_Trace_Model) return Natural;
   function Indeterminate_Trace_Count (Model : Final_Blocker_Trace_Model) return Natural;
   function Multiple_Blocker_Trace_Count (Model : Final_Blocker_Trace_Model) return Natural;
   function Feed_Link_Trace_Count (Model : Final_Blocker_Trace_Model) return Natural;
   function Index_Link_Trace_Count (Model : Final_Blocker_Trace_Model) return Natural;
   function Missing_Search_Index_Count (Model : Final_Blocker_Trace_Model) return Natural;
   function Fingerprint (Model : Final_Blocker_Trace_Model) return Natural;

private
   package Trace_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Final_Blocker_Trace);

   type Final_Blocker_Trace_Set is record
      Traces      : Trace_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Final_Blocker_Trace_Model is record
      Traces                     : Trace_Vectors.Vector;
      Legal_Total                : Natural := 0;
      Error_Total                : Natural := 0;
      Warning_Total              : Natural := 0;
      View_Barrier_Total         : Natural := 0;
      Stale_Total                : Natural := 0;
      Indeterminate_Total        : Natural := 0;
      Multiple_Blocker_Total     : Natural := 0;
      Feed_Link_Total            : Natural := 0;
      Index_Link_Total           : Natural := 0;
      Missing_Search_Index_Total : Natural := 0;
      Fingerprint                : Natural := 0;
   end record;

end Editor.Ada_Final_Semantic_Blocker_Trace_Closure;
