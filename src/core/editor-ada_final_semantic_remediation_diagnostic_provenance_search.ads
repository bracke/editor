with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Diagnostic_Provenance;
with Editor.Ada_Final_Semantic_Diagnostic_Provenance;
with Editor.Ada_Final_Semantic_Remediation_Closure_Legality;
with Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration;
with Editor.Ada_Final_Semantic_Remediation_Gate_Legality;
with Editor.Ada_Final_Semantic_Blocker_Trace_Closure;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Final_Semantic_Remediation_Diagnostic_Provenance_Search is

   --  Case 1203 final semantic remediation diagnostic provenance/search.
   --
   --  This package links Case 1202 remediation diagnostic rows back to their
   --  remediation closure rows, remediation gate rows, blocker trace roots,
   --  final semantic blocker families, and unified feed/index entries.  It is
   --  not a UI projection layer: it preserves the prerequisite blocker family
   --  that prevented a downstream legality conclusion from remaining confident.
   --  The model is deterministic, bounded, snapshot-owned, and side-effect-free.

   package Remed_Diag renames Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration;
   package Closure renames Editor.Ada_Final_Semantic_Remediation_Closure_Legality;
   package Gate renames Editor.Ada_Final_Semantic_Remediation_Gate_Legality;
   package Trace renames Editor.Ada_Final_Semantic_Blocker_Trace_Closure;
   package Final_Prov renames Editor.Ada_Final_Semantic_Diagnostic_Provenance;
   package Feed renames Editor.Ada_Semantic_Diagnostic_Feed;
   package Index renames Editor.Ada_Semantic_Diagnostic_Index;
   package Base_Prov renames Editor.Ada_Diagnostic_Provenance;

   subtype Final_Blocker_Family is Final_Prov.Final_Blocker_Family;
   subtype Final_Remediation_Diagnostic_Status is Remed_Diag.Final_Remediation_Diagnostic_Status;
   subtype Final_Remediation_Diagnostic_Family is Remed_Diag.Final_Remediation_Diagnostic_Family;
   subtype Final_Remediation_Closure_Status is Closure.Final_Remediation_Closure_Status;
   subtype Final_Gate_Status is Gate.Final_Gate_Status;
   subtype Final_Gate_Action is Gate.Final_Gate_Action;
   subtype Final_Trace_Root is Trace.Final_Blocker_Trace_Root;

   type Final_Remediation_Provenance_Id is new Natural;
   No_Final_Remediation_Provenance : constant Final_Remediation_Provenance_Id := 0;

   type Final_Remediation_Provenance_Status is
     (Final_Remediation_Provenance_Not_Checked,
      Final_Remediation_Provenance_Withheld_Legal,
      Final_Remediation_Provenance_Emitted_Error,
      Final_Remediation_Provenance_Emitted_Warning,
      Final_Remediation_Provenance_Stale_Rejected,
      Final_Remediation_Provenance_Preserved_Semantic_Error,
      Final_Remediation_Provenance_Indeterminate,
      Final_Remediation_Provenance_Multiple_Blockers);

   type Final_Remediation_Provenance_Stage is
     (Final_Remediation_Stage_None,
      Final_Remediation_Stage_Diagnostic_Integration,
      Final_Remediation_Stage_Unified_Feed,
      Final_Remediation_Stage_Index,
      Final_Remediation_Stage_Base_Provenance,
      Final_Remediation_Stage_Closure,
      Final_Remediation_Stage_Gate,
      Final_Remediation_Stage_Trace,
      Final_Remediation_Stage_Withheld_Legal,
      Final_Remediation_Stage_Stale_Rejection);

   type Final_Remediation_Provenance_Info is record
      Id                    : Final_Remediation_Provenance_Id := No_Final_Remediation_Provenance;
      Diagnostic_Id         : Remed_Diag.Final_Remediation_Diagnostic_Id := Remed_Diag.No_Final_Remediation_Diagnostic;
      Diagnostic_Status     : Final_Remediation_Diagnostic_Status := Remed_Diag.Final_Remediation_Diagnostic_Not_Checked;
      Diagnostic_Family     : Final_Remediation_Diagnostic_Family := Remed_Diag.Final_Remediation_Diagnostic_Unknown;
      Closure_Id            : Closure.Final_Remediation_Closure_Id := Closure.No_Final_Remediation_Closure;
      Closure_Status        : Final_Remediation_Closure_Status := Closure.Final_Remediation_Closure_Not_Checked;
      Gate_Id               : Gate.Final_Gate_Id := Gate.No_Final_Gate;
      Gate_Status           : Final_Gate_Status := Gate.Final_Gate_Not_Checked;
      Gate_Action           : Final_Gate_Action := Gate.Final_Gate_Action_None;
      Trace_Id              : Trace.Final_Blocker_Trace_Id := Trace.No_Final_Blocker_Trace;
      Trace_Root            : Final_Trace_Root := Trace.Final_Trace_Root_None;
      Status                : Final_Remediation_Provenance_Status := Final_Remediation_Provenance_Not_Checked;
      Stage                 : Final_Remediation_Provenance_Stage := Final_Remediation_Stage_None;
      Blocker_Family        : Final_Blocker_Family := Final_Prov.Final_Blocker_None;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Feed_Entry            : Feed.Semantic_Diagnostic_Feed_Id := Feed.No_Semantic_Diagnostic_Feed_Entry;
      Index_Entry           : Index.Semantic_Diagnostic_Index_Id := Index.No_Semantic_Diagnostic_Index_Entry;
      Base_Provenance       : Base_Prov.Diagnostic_Provenance_Id := Base_Prov.No_Diagnostic_Provenance;
      Message               : Ada.Strings.Unbounded.Unbounded_String;
      Chain_Summary         : Ada.Strings.Unbounded.Unbounded_String;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
      Diagnostic_Fingerprint : Natural := 0;
      Closure_Fingerprint   : Natural := 0;
      Gate_Fingerprint      : Natural := 0;
      Trace_Fingerprint     : Natural := 0;
      Feed_Fingerprint      : Natural := 0;
      Index_Fingerprint     : Natural := 0;
      Base_Fingerprint      : Natural := 0;
      Fingerprint           : Natural := 0;
   end record;

   type Final_Remediation_Provenance_Model is private;
   type Final_Remediation_Provenance_Set is private;

   procedure Clear (Model : in out Final_Remediation_Provenance_Model);

   function Build
     (Diagnostics : Remed_Diag.Final_Remediation_Diagnostic_Model)
      return Final_Remediation_Provenance_Model;

   function Build_With_Closure_Gate_Trace
     (Diagnostics : Remed_Diag.Final_Remediation_Diagnostic_Model;
      Closures    : Closure.Final_Remediation_Closure_Model;
      Gates       : Gate.Final_Gated_Model;
      Traces      : Trace.Final_Blocker_Trace_Model)
      return Final_Remediation_Provenance_Model;

   function Build_With_Feed_Index_And_Base
     (Diagnostics : Remed_Diag.Final_Remediation_Diagnostic_Model;
      Closures    : Closure.Final_Remediation_Closure_Model;
      Gates       : Gate.Final_Gated_Model;
      Traces      : Trace.Final_Blocker_Trace_Model;
      Feed_Model  : Feed.Semantic_Diagnostic_Feed_Model;
      Index_Model : Index.Semantic_Diagnostic_Index_Model;
      Provenance  : Base_Prov.Diagnostic_Provenance_Model)
      return Final_Remediation_Provenance_Model;

   function Row_Count (Model : Final_Remediation_Provenance_Model) return Natural;
   function Row_At
     (Model : Final_Remediation_Provenance_Model;
      Index : Positive) return Final_Remediation_Provenance_Info;

   function Query_Count (Set : Final_Remediation_Provenance_Set) return Natural;
   function Query_At
     (Set   : Final_Remediation_Provenance_Set;
      Index : Positive) return Final_Remediation_Provenance_Info;

   function Query_Status
     (Model  : Final_Remediation_Provenance_Model;
      Status : Final_Remediation_Provenance_Status) return Final_Remediation_Provenance_Set;
   function Query_Stage
     (Model : Final_Remediation_Provenance_Model;
      Stage : Final_Remediation_Provenance_Stage) return Final_Remediation_Provenance_Set;
   function Query_Blocker
     (Model   : Final_Remediation_Provenance_Model;
      Blocker : Final_Blocker_Family) return Final_Remediation_Provenance_Set;
   function Query_Node
     (Model : Final_Remediation_Provenance_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_Remediation_Provenance_Set;
   function Query_Position
     (Model  : Final_Remediation_Provenance_Model;
      Line   : Positive;
      Column : Positive) return Final_Remediation_Provenance_Set;
   function Query_Feed_Link
     (Model : Final_Remediation_Provenance_Model;
      Link  : Feed.Semantic_Diagnostic_Feed_Id) return Final_Remediation_Provenance_Set;
   function Query_Index_Link
     (Model : Final_Remediation_Provenance_Model;
      Link  : Index.Semantic_Diagnostic_Index_Id) return Final_Remediation_Provenance_Set;

   function Count_Status
     (Model  : Final_Remediation_Provenance_Model;
      Status : Final_Remediation_Provenance_Status) return Natural;
   function Count_Stage
     (Model : Final_Remediation_Provenance_Model;
      Stage : Final_Remediation_Provenance_Stage) return Natural;
   function Count_Blocker
     (Model   : Final_Remediation_Provenance_Model;
      Blocker : Final_Blocker_Family) return Natural;

   function Withheld_Count (Model : Final_Remediation_Provenance_Model) return Natural;
   function Error_Count (Model : Final_Remediation_Provenance_Model) return Natural;
   function Warning_Count (Model : Final_Remediation_Provenance_Model) return Natural;
   function Stale_Rejected_Count (Model : Final_Remediation_Provenance_Model) return Natural;
   function Preserved_Error_Count (Model : Final_Remediation_Provenance_Model) return Natural;
   function Indeterminate_Count (Model : Final_Remediation_Provenance_Model) return Natural;
   function Multiple_Blocker_Count (Model : Final_Remediation_Provenance_Model) return Natural;
   function Feed_Link_Count (Model : Final_Remediation_Provenance_Model) return Natural;
   function Index_Link_Count (Model : Final_Remediation_Provenance_Model) return Natural;
   function Base_Link_Count (Model : Final_Remediation_Provenance_Model) return Natural;
   function Closure_Link_Count (Model : Final_Remediation_Provenance_Model) return Natural;
   function Gate_Link_Count (Model : Final_Remediation_Provenance_Model) return Natural;
   function Trace_Link_Count (Model : Final_Remediation_Provenance_Model) return Natural;
   function Fingerprint (Model : Final_Remediation_Provenance_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Final_Remediation_Provenance_Info);

   type Final_Remediation_Provenance_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Final_Remediation_Provenance_Model is record
      Rows                   : Row_Vectors.Vector;
      Withheld_Total         : Natural := 0;
      Error_Total            : Natural := 0;
      Warning_Total          : Natural := 0;
      Stale_Total            : Natural := 0;
      Preserved_Error_Total  : Natural := 0;
      Indeterminate_Total    : Natural := 0;
      Multiple_Blocker_Total : Natural := 0;
      Feed_Link_Total        : Natural := 0;
      Index_Link_Total       : Natural := 0;
      Base_Link_Total        : Natural := 0;
      Closure_Link_Total     : Natural := 0;
      Gate_Link_Total        : Natural := 0;
      Trace_Link_Total       : Natural := 0;
      Fingerprint            : Natural := 0;
   end record;

end Editor.Ada_Final_Semantic_Remediation_Diagnostic_Provenance_Search;
