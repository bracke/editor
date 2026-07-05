with Ada.Containers.Vectors;
with Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Provenance;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Search_Index is

   --  Case 1294 blocker-family-aware search index for stabilized remaining
   --  RM edge closure diagnostics.
   --
   --  This package indexes Case 1293 provenance rows without changing their
   --  semantic meaning.  It is a deterministic semantic lookup structure used
   --  by downstream compiler-grade consumers to find the exact remaining RM
   --  edge blocker, stabilized direct-consumer closure blocker, fingerprint
   --  blocker, or recheck/indeterminate state that prevents trusted closure.

   package Prov renames Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Provenance;

   subtype Remaining_RM_Edge_Stabilized_Closure_Provenance_Id is Prov.Remaining_RM_Edge_Stabilized_Closure_Provenance_Id;
   subtype Remaining_RM_Edge_Stabilized_Closure_Provenance_Status is Prov.Remaining_RM_Edge_Stabilized_Closure_Provenance_Status;
   subtype Remaining_RM_Edge_Stabilized_Closure_Provenance_Stage is Prov.Remaining_RM_Edge_Stabilized_Closure_Provenance_Stage;
   subtype Remaining_RM_Edge_Stabilized_Closure_Provenance_Blocker is Prov.Remaining_RM_Edge_Stabilized_Closure_Provenance_Blocker;
   subtype Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status is Prov.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status;
   subtype Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Family is Prov.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Family;
   subtype Remaining_RM_Edge_Stabilized_Closure_Family is Prov.Remaining_RM_Edge_Stabilized_Closure_Family;
   subtype Remaining_RM_Edge_Kind is Prov.Remaining_RM_Edge_Kind;
   subtype Remaining_RM_Edge_Blocker_Family is Prov.Remaining_RM_Edge_Blocker_Family;

   type Remaining_RM_Edge_Stabilized_Closure_Search_Index_Id is new Natural;
   No_Remaining_RM_Edge_Stabilized_Closure_Search_Entry : constant Remaining_RM_Edge_Stabilized_Closure_Search_Index_Id := 0;

   type Remaining_RM_Edge_Stabilized_Closure_Search_Entry is record
      Id                         : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Id := No_Remaining_RM_Edge_Stabilized_Closure_Search_Entry;
      Provenance_Index           : Natural := 0;
      Provenance                 : Prov.Remaining_RM_Edge_Stabilized_Closure_Provenance_Row;
      Provenance_Id              : Remaining_RM_Edge_Stabilized_Closure_Provenance_Id := Prov.No_Remaining_RM_Edge_Stabilized_Closure_Provenance;
      Status                     : Remaining_RM_Edge_Stabilized_Closure_Provenance_Status := Prov.Remaining_RM_Edge_Stabilized_Closure_Provenance_Not_Checked;
      Stage                      : Remaining_RM_Edge_Stabilized_Closure_Provenance_Stage := Prov.Remaining_RM_Edge_Stabilized_Closure_Stage_None;
      Blocker                    : Remaining_RM_Edge_Stabilized_Closure_Provenance_Blocker := Prov.Remaining_RM_Edge_Stabilized_Closure_Blocker_Unknown;
      Diagnostic_Status          : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status := Prov.Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Not_Checked;
      Diagnostic_Family          : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Family := Prov.Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Unknown;
      Closure_Family             : Remaining_RM_Edge_Stabilized_Closure_Family := Prov.Closure.Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Unknown;
      Remaining_Edge_Kind        : Remaining_RM_Edge_Kind := Prov.Edge.Remaining_RM_Edge_Unknown;
      Remaining_Edge_Blocker     : Remaining_RM_Edge_Blocker_Family := Prov.Edge.Remaining_RM_Edge_Blocker_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Fingerprint         : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Edge_Fingerprint           : Natural := 0;
      Consumer_Closure_Fingerprint : Natural := 0;
      Diagnostic_Fingerprint     : Natural := 0;
      Closure_Fingerprint        : Natural := 0;
      Provenance_Fingerprint     : Natural := 0;
      Fingerprint                : Natural := 0;
      Emitted                    : Boolean := False;
      Withheld_Current           : Boolean := False;
      Requires_Recheck           : Boolean := False;
      Blocks_Downstream          : Boolean := False;
      Full_Chain_Linked          : Boolean := False;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Remaining_RM_Edge_Stabilized_Closure_Search_Result is record
      Index_Row        : Natural := 0;
      Provenance_Index : Natural := 0;
      Search_Entry      : Remaining_RM_Edge_Stabilized_Closure_Search_Entry;
   end record;

   type Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set is private;
   type Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model is private;

   procedure Clear (Model : in out Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model);

   function Build
     (Provenance : Prov.Remaining_RM_Edge_Stabilized_Closure_Provenance_Model)
      return Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;

   function Entry_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model) return Natural;
   function Entry_At
     (Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Index : Positive) return Remaining_RM_Edge_Stabilized_Closure_Search_Entry;

   function Query_Count (Results : Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set) return Natural;
   function Query_At
     (Results : Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
      Index   : Positive) return Remaining_RM_Edge_Stabilized_Closure_Search_Result;

   function Query_Blocker
     (Model   : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Blocker : Remaining_RM_Edge_Stabilized_Closure_Provenance_Blocker)
      return Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
   function Query_Status
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Status : Remaining_RM_Edge_Stabilized_Closure_Provenance_Status)
      return Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
   function Query_Diagnostic_Status
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Status : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status)
      return Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
   function Query_Diagnostic_Family
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Family : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Family)
      return Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
   function Query_Closure_Family
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Family : Remaining_RM_Edge_Stabilized_Closure_Family)
      return Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
   function Query_Remaining_Edge_Kind
     (Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Kind  : Remaining_RM_Edge_Kind)
      return Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
   function Query_Remaining_Edge_Blocker
     (Model   : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Blocker : Remaining_RM_Edge_Blocker_Family)
      return Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
   function Query_Stage
     (Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Stage : Remaining_RM_Edge_Stabilized_Closure_Provenance_Stage)
      return Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
   function Query_Node
     (Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
   function Query_Range
     (Model      : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Start_Line : Positive;
      End_Line   : Positive) return Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
   function Query_Position
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Line   : Positive;
      Column : Positive) return Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
   function Query_Source_Fingerprint
     (Model       : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
   function Query_Substitution_Fingerprint
     (Model       : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
   function Query_Provenance_Fingerprint
     (Model       : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;

   function Has_Blocker_At
     (Model   : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Line    : Positive;
      Column  : Positive;
      Blocker : Remaining_RM_Edge_Stabilized_Closure_Provenance_Blocker) return Boolean;

   function Count_Blocker
     (Model   : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Blocker : Remaining_RM_Edge_Stabilized_Closure_Provenance_Blocker) return Natural;
   function Count_Status
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Status : Remaining_RM_Edge_Stabilized_Closure_Provenance_Status) return Natural;
   function Count_Diagnostic_Status
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Status : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status) return Natural;
   function Count_Diagnostic_Family
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Family : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Family) return Natural;
   function Count_Stage
     (Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Stage : Remaining_RM_Edge_Stabilized_Closure_Provenance_Stage) return Natural;

   function Withheld_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model) return Natural;
   function Emitted_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model) return Natural;
   function Error_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model) return Natural;
   function Warning_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model) return Natural;
   function Recheck_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model) return Natural;
   function Indeterminate_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model) return Natural;
   function Multiple_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model) return Natural;
   function Full_Chain_Link_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model) return Natural;
   function Fingerprint (Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model) return Natural;

private
   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Remaining_RM_Edge_Stabilized_Closure_Search_Entry);

   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Remaining_RM_Edge_Stabilized_Closure_Search_Result);

   type Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set is record
      Results     : Result_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model is record
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

end Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Search_Index;
