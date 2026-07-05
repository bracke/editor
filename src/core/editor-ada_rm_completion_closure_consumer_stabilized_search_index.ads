with Ada.Containers.Vectors;
with Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Provenance;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Search_Index is

   --  Case 1283 blocker-family-aware search index for stabilized direct
   --  RM-completion closure-consumer diagnostics.
   --
   --  This package indexes Case 1282 provenance rows without changing their
   --  semantic meaning.  It is deliberately a semantic lookup structure, not a
   --  UI projection layer: blocker family, provenance status/stage, diagnostic
   --  family/status, source span, syntax node, all chain ids, and fingerprints
   --  remain available so downstream compiler-grade consumers can find the
   --  exact stabilized direct-consumer blocker that prevents trusted closure.

   package Prov renames Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Provenance;

   subtype RM_Closure_Consumer_Stabilized_Provenance_Id is Prov.RM_Closure_Consumer_Stabilized_Provenance_Id;
   subtype RM_Closure_Consumer_Stabilized_Provenance_Status is Prov.RM_Closure_Consumer_Stabilized_Provenance_Status;
   subtype RM_Closure_Consumer_Stabilized_Provenance_Stage is Prov.RM_Closure_Consumer_Stabilized_Provenance_Stage;
   subtype RM_Closure_Consumer_Stabilized_Provenance_Blocker is Prov.RM_Closure_Consumer_Stabilized_Provenance_Blocker;
   subtype RM_Closure_Consumer_Stabilized_Diagnostic_Status is Prov.RM_Closure_Consumer_Stabilized_Diagnostic_Status;
   subtype RM_Closure_Consumer_Stabilized_Diagnostic_Family is Prov.RM_Closure_Consumer_Stabilized_Diagnostic_Family;
   subtype RM_Closure_Consumer_Closure_Family is Prov.RM_Closure_Consumer_Closure_Family;

   type RM_Closure_Consumer_Stabilized_Search_Index_Id is new Natural;
   No_RM_Closure_Consumer_Stabilized_Search_Entry : constant RM_Closure_Consumer_Stabilized_Search_Index_Id := 0;

   type RM_Closure_Consumer_Stabilized_Search_Entry is record
      Id                       : RM_Closure_Consumer_Stabilized_Search_Index_Id := No_RM_Closure_Consumer_Stabilized_Search_Entry;
      Provenance_Index         : Natural := 0;
      Provenance               : Prov.RM_Closure_Consumer_Stabilized_Provenance_Row;
      Provenance_Id            : RM_Closure_Consumer_Stabilized_Provenance_Id := Prov.No_RM_Closure_Consumer_Stabilized_Provenance;
      Status                   : RM_Closure_Consumer_Stabilized_Provenance_Status := Prov.RM_Closure_Consumer_Stabilized_Provenance_Not_Checked;
      Stage                    : RM_Closure_Consumer_Stabilized_Provenance_Stage := Prov.RM_Closure_Consumer_Stabilized_Stage_None;
      Blocker                  : RM_Closure_Consumer_Stabilized_Provenance_Blocker := Prov.RM_Closure_Consumer_Stabilized_Blocker_Unknown;
      Diagnostic_Status        : RM_Closure_Consumer_Stabilized_Diagnostic_Status := Prov.Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Not_Checked;
      Diagnostic_Family        : RM_Closure_Consumer_Stabilized_Diagnostic_Family := Prov.Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Unknown;
      Closure_Family           : RM_Closure_Consumer_Closure_Family := Prov.Diag.Closure.Gate.Conv.Apply.Recheck.Worklist.Diagnostics.RM_Closure_Consumer_Diagnostic_Unknown;
      Node                     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Fingerprint       : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Semantic_Fingerprint     : Natural := 0;
      Diagnostic_Fingerprint   : Natural := 0;
      Closure_Fingerprint      : Natural := 0;
      Provenance_Fingerprint   : Natural := 0;
      Fingerprint              : Natural := 0;
      Emitted                  : Boolean := False;
      Withheld_Current         : Boolean := False;
      Requires_Recheck         : Boolean := False;
      Blocks_Downstream        : Boolean := False;
      Full_Chain_Linked        : Boolean := False;
      Start_Line               : Positive := 1;
      Start_Column             : Positive := 1;
      End_Line                 : Positive := 1;
      End_Column               : Positive := 1;
   end record;

   type RM_Closure_Consumer_Stabilized_Search_Result is record
      Index_Row        : Natural := 0;
      Provenance_Index : Natural := 0;
      Feed_Item            : RM_Closure_Consumer_Stabilized_Search_Entry;
   end record;

   type RM_Closure_Consumer_Stabilized_Search_Result_Set is private;
   type RM_Closure_Consumer_Stabilized_Search_Index_Model is private;

   procedure Clear (Model : in out RM_Closure_Consumer_Stabilized_Search_Index_Model);

   function Build
     (Provenance : Prov.RM_Closure_Consumer_Stabilized_Provenance_Model)
      return RM_Closure_Consumer_Stabilized_Search_Index_Model;

   function Entry_Count (Model : RM_Closure_Consumer_Stabilized_Search_Index_Model) return Natural;
   function Entry_At
     (Model : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Index : Positive) return RM_Closure_Consumer_Stabilized_Search_Entry;

   function Query_Count (Results : RM_Closure_Consumer_Stabilized_Search_Result_Set) return Natural;
   function Query_At
     (Results : RM_Closure_Consumer_Stabilized_Search_Result_Set;
      Index   : Positive) return RM_Closure_Consumer_Stabilized_Search_Result;

   function Query_Blocker
     (Model   : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Blocker : RM_Closure_Consumer_Stabilized_Provenance_Blocker)
      return RM_Closure_Consumer_Stabilized_Search_Result_Set;
   function Query_Status
     (Model  : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Status : RM_Closure_Consumer_Stabilized_Provenance_Status)
      return RM_Closure_Consumer_Stabilized_Search_Result_Set;
   function Query_Diagnostic_Status
     (Model  : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Status : RM_Closure_Consumer_Stabilized_Diagnostic_Status)
      return RM_Closure_Consumer_Stabilized_Search_Result_Set;
   function Query_Diagnostic_Family
     (Model  : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Family : RM_Closure_Consumer_Stabilized_Diagnostic_Family)
      return RM_Closure_Consumer_Stabilized_Search_Result_Set;
   function Query_Closure_Family
     (Model  : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Family : RM_Closure_Consumer_Closure_Family)
      return RM_Closure_Consumer_Stabilized_Search_Result_Set;
   function Query_Stage
     (Model : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Stage : RM_Closure_Consumer_Stabilized_Provenance_Stage)
      return RM_Closure_Consumer_Stabilized_Search_Result_Set;
   function Query_Node
     (Model : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return RM_Closure_Consumer_Stabilized_Search_Result_Set;
   function Query_Range
     (Model      : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Start_Line : Positive;
      End_Line   : Positive) return RM_Closure_Consumer_Stabilized_Search_Result_Set;
   function Query_Position
     (Model  : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Line   : Positive;
      Column : Positive) return RM_Closure_Consumer_Stabilized_Search_Result_Set;
   function Query_Source_Fingerprint
     (Model       : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Fingerprint : Natural) return RM_Closure_Consumer_Stabilized_Search_Result_Set;
   function Query_Substitution_Fingerprint
     (Model       : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Fingerprint : Natural) return RM_Closure_Consumer_Stabilized_Search_Result_Set;
   function Query_Provenance_Fingerprint
     (Model       : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Fingerprint : Natural) return RM_Closure_Consumer_Stabilized_Search_Result_Set;

   function Has_Blocker_At
     (Model   : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Line    : Positive;
      Column  : Positive;
      Blocker : RM_Closure_Consumer_Stabilized_Provenance_Blocker) return Boolean;

   function Count_Blocker
     (Model   : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Blocker : RM_Closure_Consumer_Stabilized_Provenance_Blocker) return Natural;
   function Count_Status
     (Model  : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Status : RM_Closure_Consumer_Stabilized_Provenance_Status) return Natural;
   function Count_Diagnostic_Status
     (Model  : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Status : RM_Closure_Consumer_Stabilized_Diagnostic_Status) return Natural;
   function Count_Diagnostic_Family
     (Model  : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Family : RM_Closure_Consumer_Stabilized_Diagnostic_Family) return Natural;
   function Count_Stage
     (Model : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Stage : RM_Closure_Consumer_Stabilized_Provenance_Stage) return Natural;

   function Withheld_Count (Model : RM_Closure_Consumer_Stabilized_Search_Index_Model) return Natural;
   function Emitted_Count (Model : RM_Closure_Consumer_Stabilized_Search_Index_Model) return Natural;
   function Error_Count (Model : RM_Closure_Consumer_Stabilized_Search_Index_Model) return Natural;
   function Warning_Count (Model : RM_Closure_Consumer_Stabilized_Search_Index_Model) return Natural;
   function Recheck_Count (Model : RM_Closure_Consumer_Stabilized_Search_Index_Model) return Natural;
   function Indeterminate_Count (Model : RM_Closure_Consumer_Stabilized_Search_Index_Model) return Natural;
   function Multiple_Count (Model : RM_Closure_Consumer_Stabilized_Search_Index_Model) return Natural;
   function Full_Chain_Link_Count (Model : RM_Closure_Consumer_Stabilized_Search_Index_Model) return Natural;
   function Fingerprint (Model : RM_Closure_Consumer_Stabilized_Search_Index_Model) return Natural;

private
   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => RM_Closure_Consumer_Stabilized_Search_Entry);

   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => RM_Closure_Consumer_Stabilized_Search_Result);

   type RM_Closure_Consumer_Stabilized_Search_Result_Set is record
      Results     : Result_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type RM_Closure_Consumer_Stabilized_Search_Index_Model is record
      Entries               : Entry_Vectors.Vector;
      Withheld_Total        : Natural := 0;
      Emitted_Total         : Natural := 0;
      Error_Total           : Natural := 0;
      Warning_Total         : Natural := 0;
      Recheck_Total         : Natural := 0;
      Indeterminate_Total   : Natural := 0;
      Multiple_Total        : Natural := 0;
      Full_Chain_Link_Total : Natural := 0;
      Result_Fingerprint    : Natural := 0;
   end record;

end Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Search_Index;
