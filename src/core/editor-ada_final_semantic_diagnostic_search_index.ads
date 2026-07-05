with Ada.Containers.Vectors;
with Editor.Ada_Final_Semantic_Diagnostic_Integration;
with Editor.Ada_Final_Semantic_Diagnostic_Provenance;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Final_Semantic_Diagnostic_Search_Index is

   --  Case 1197 blocker-family-aware final semantic diagnostic search index.
   --
   --  This package indexes Case 1196 final semantic diagnostic provenance for
   --  semantic debugging.  It is deliberately not a UI projection layer: it
   --  preserves final blocker family, final semantic status, provenance stage,
   --  source span, syntax node, feed/index links, stale/withheld decisions, and
   --  stable fingerprints so consumers can locate the exact semantic legality
   --  family responsible for a diagnostic.  The model is deterministic,
   --  bounded, snapshot-owned, and performs no parsing, file IO, save/reload,
   --  dirty-state mutation, command/keybinding/workspace/render mutation, LSP
   --  use, compiler invocation, or external parser generation.

   package Final_Diag renames Editor.Ada_Final_Semantic_Diagnostic_Integration;
   package Final_Prov renames Editor.Ada_Final_Semantic_Diagnostic_Provenance;
   package Feed renames Editor.Ada_Semantic_Diagnostic_Feed;
   package Base_Index renames Editor.Ada_Semantic_Diagnostic_Index;

   subtype Final_Blocker_Family is Final_Prov.Final_Blocker_Family;
   subtype Final_Provenance_Status is Final_Prov.Final_Provenance_Status;
   subtype Final_Provenance_Stage is Final_Prov.Final_Provenance_Stage;
   subtype Final_Diagnostic_Status is Final_Diag.Final_Diagnostic_Status;

   type Final_Search_Index_Id is new Natural;
   No_Final_Search_Index_Entry : constant Final_Search_Index_Id := 0;

   type Final_Search_Index_Status is
     (Final_Search_Index_Current,
      Final_Search_Index_Rejected_Stale);

   type Final_Search_Entry is record
      Id                 : Final_Search_Index_Id := No_Final_Search_Index_Entry;
      Provenance_Index   : Natural := 0;
      Provenance         : Final_Prov.Final_Provenance_Info;
      Blocker_Family     : Final_Blocker_Family := Final_Prov.Final_Blocker_None;
      Provenance_Status  : Final_Provenance_Status := Final_Prov.Final_Provenance_Not_Checked;
      Provenance_Stage   : Final_Provenance_Stage := Final_Prov.Final_Stage_None;
      Final_Status       : Final_Diagnostic_Status := Final_Diag.Final_Diagnostic_Not_Checked;
      Node               : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Feed_Entry         : Feed.Semantic_Diagnostic_Feed_Id := Feed.No_Semantic_Diagnostic_Feed_Entry;
      Index_Entry        : Base_Index.Semantic_Diagnostic_Index_Id := Base_Index.No_Semantic_Diagnostic_Index_Entry;
      Start_Line         : Positive := 1;
      Start_Column       : Positive := 1;
      End_Line           : Positive := 1;
      End_Column         : Positive := 1;
      Source_Fingerprint : Natural := 0;
      Fingerprint        : Natural := 0;
   end record;

   type Final_Search_Result is record
      Index_Row        : Natural := 0;
      Provenance_Index : Natural := 0;
      Feed_Item            : Final_Search_Entry;
   end record;

   type Final_Search_Result_Set is private;
   type Final_Search_Index_Model is private;

   procedure Clear (Model : in out Final_Search_Index_Model);

   function Build
     (Provenance : Final_Prov.Final_Provenance_Model)
      return Final_Search_Index_Model;

   function Status (Model : Final_Search_Index_Model) return Final_Search_Index_Status;
   function Current (Model : Final_Search_Index_Model) return Boolean;
   function Rejected_Stale (Model : Final_Search_Index_Model) return Boolean;

   function Entry_Count (Model : Final_Search_Index_Model) return Natural;
   function Entry_At
     (Model : Final_Search_Index_Model;
      Index : Positive) return Final_Search_Entry;

   function Query_Count (Results : Final_Search_Result_Set) return Natural;
   function Query_At
     (Results : Final_Search_Result_Set;
      Index   : Positive) return Final_Search_Result;

   function Query_Blocker
     (Model   : Final_Search_Index_Model;
      Blocker : Final_Blocker_Family) return Final_Search_Result_Set;

   function Query_Provenance_Status
     (Model  : Final_Search_Index_Model;
      Status : Final_Provenance_Status) return Final_Search_Result_Set;

   function Query_Final_Status
     (Model  : Final_Search_Index_Model;
      Status : Final_Diagnostic_Status) return Final_Search_Result_Set;

   function Query_Stage
     (Model : Final_Search_Index_Model;
      Stage : Final_Provenance_Stage) return Final_Search_Result_Set;

   function Query_Node
     (Model : Final_Search_Index_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_Search_Result_Set;

   function Query_Range
     (Model      : Final_Search_Index_Model;
      Start_Line : Positive;
      End_Line   : Positive) return Final_Search_Result_Set;

   function Query_Position
     (Model  : Final_Search_Index_Model;
      Line   : Positive;
      Column : Positive) return Final_Search_Result_Set;

   function Query_Source_Fingerprint
     (Model       : Final_Search_Index_Model;
      Fingerprint : Natural) return Final_Search_Result_Set;

   function Query_Feed_Link
     (Model : Final_Search_Index_Model;
      Link  : Feed.Semantic_Diagnostic_Feed_Id) return Final_Search_Result_Set;

   function Query_Index_Link
     (Model : Final_Search_Index_Model;
      Link  : Base_Index.Semantic_Diagnostic_Index_Id) return Final_Search_Result_Set;

   function Has_Blocker_At
     (Model   : Final_Search_Index_Model;
      Line    : Positive;
      Column  : Positive;
      Blocker : Final_Blocker_Family) return Boolean;

   function Count_Blocker
     (Model   : Final_Search_Index_Model;
      Blocker : Final_Blocker_Family) return Natural;
   function Count_Provenance_Status
     (Model  : Final_Search_Index_Model;
      Status : Final_Provenance_Status) return Natural;
   function Count_Final_Status
     (Model  : Final_Search_Index_Model;
      Status : Final_Diagnostic_Status) return Natural;
   function Count_Stage
     (Model : Final_Search_Index_Model;
      Stage : Final_Provenance_Stage) return Natural;

   function Withheld_Count (Model : Final_Search_Index_Model) return Natural;
   function Emitted_Error_Count (Model : Final_Search_Index_Model) return Natural;
   function Emitted_Warning_Count (Model : Final_Search_Index_Model) return Natural;
   function Stale_Rejected_Count (Model : Final_Search_Index_Model) return Natural;
   function Indeterminate_Count (Model : Final_Search_Index_Model) return Natural;
   function Multiple_Blocker_Count (Model : Final_Search_Index_Model) return Natural;
   function Feed_Link_Count (Model : Final_Search_Index_Model) return Natural;
   function Index_Link_Count (Model : Final_Search_Index_Model) return Natural;
   function Fingerprint (Model : Final_Search_Index_Model) return Natural;

private
   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Final_Search_Entry);

   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Final_Search_Result);

   type Final_Search_Result_Set is record
      Results     : Result_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Final_Search_Index_Model is record
      Index_Status           : Final_Search_Index_Status := Final_Search_Index_Current;
      Entries                : Entry_Vectors.Vector;
      Withheld_Total         : Natural := 0;
      Error_Total            : Natural := 0;
      Warning_Total          : Natural := 0;
      Stale_Total            : Natural := 0;
      Indeterminate_Total    : Natural := 0;
      Multiple_Blocker_Total : Natural := 0;
      Feed_Link_Total        : Natural := 0;
      Index_Link_Total       : Natural := 0;
      Result_Fingerprint     : Natural := 0;
   end record;

end Editor.Ada_Final_Semantic_Diagnostic_Search_Index;
