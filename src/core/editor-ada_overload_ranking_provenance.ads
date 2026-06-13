with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Expression_Diagnostics;
with Editor.Ada_Overload_Ranking;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Overload_Ranking_Provenance is

   --  Projection-only provenance model for overload-ranking decisions.  This
   --  package links ranked overload metadata to expression diagnostics so IDE
   --  explain/provenance consumers can show whether a ranked result came from
   --  an exact match, implicit conversion evidence, universal numeric
   --  tie-breaking, or a remaining ambiguous/rejected/unknown state.  It does
   --  not parse, perform file IO, mutate buffers, register commands, touch
   --  workspace state, apply edits, or perform rendering work.

   subtype Ranking_Info is Editor.Ada_Overload_Ranking.Overload_Ranking_Info;
   subtype Ranking_Status is Editor.Ada_Overload_Ranking.Overload_Ranking_Status;
   subtype Expression_Diagnostic is
     Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Info;
   subtype Expression_Diagnostic_Severity is
     Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Severity;

   type Overload_Ranking_Provenance_Id is new Natural;
   No_Overload_Ranking_Provenance : constant Overload_Ranking_Provenance_Id := 0;

   type Overload_Ranking_Provenance_Status is
     (Overload_Ranking_Provenance_Current,
      Overload_Ranking_Provenance_Unlinked_Diagnostic,
      Overload_Ranking_Provenance_Unlinked_Ranking);

   type Overload_Ranking_Provenance_Outcome is
     (Overload_Ranking_Outcome_Exact,
      Overload_Ranking_Outcome_Implicit_Conversion,
      Overload_Ranking_Outcome_Universal_Numeric,
      Overload_Ranking_Outcome_Ambiguous,
      Overload_Ranking_Outcome_No_Candidate,
      Overload_Ranking_Outcome_Unknown,
      Overload_Ranking_Outcome_Not_Overload,
      Overload_Ranking_Outcome_Unlinked);

   type Overload_Ranking_Provenance_Stage is
     (Overload_Ranking_Stage_None,
      Overload_Ranking_Stage_Expression_Evidence,
      Overload_Ranking_Stage_Overload_Cause,
      Overload_Ranking_Stage_Ranking_Decision,
      Overload_Ranking_Stage_Diagnostic_Projection);

   type Overload_Ranking_Provenance_Item is record
      Id       : Overload_Ranking_Provenance_Id := No_Overload_Ranking_Provenance;
      Status   : Overload_Ranking_Provenance_Status := Overload_Ranking_Provenance_Current;
      Outcome  : Overload_Ranking_Provenance_Outcome := Overload_Ranking_Outcome_Unlinked;
      Stage    : Overload_Ranking_Provenance_Stage := Overload_Ranking_Stage_None;
      Ranking  : Editor.Ada_Overload_Ranking.Overload_Ranking_Id :=
        Editor.Ada_Overload_Ranking.No_Overload_Ranking;
      Ranking_Status : Editor.Ada_Overload_Ranking.Overload_Ranking_Status :=
        Editor.Ada_Overload_Ranking.Overload_Ranking_Not_Checked;
      Expression_Diagnostic : Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Id :=
        Editor.Ada_Expression_Diagnostics.No_Expression_Diagnostic;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Severity : Expression_Diagnostic_Severity :=
        Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Severity_Info;
      Message  : Ada.Strings.Unbounded.Unbounded_String;
      Detail   : Ada.Strings.Unbounded.Unbounded_String;
      Explanation : Ada.Strings.Unbounded.Unbounded_String;
      Candidate_Count : Natural := 0;
      Exact_Match_Count : Natural := 0;
      Implicit_Conversion_Count : Natural := 0;
      Universal_Numeric_Count : Natural := 0;
      Rejected_Count : Natural := 0;
      Unknown_Count  : Natural := 0;
      Selected_Count : Natural := 0;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
      Ranking_Fingerprint : Natural := 0;
      Diagnostic_Fingerprint : Natural := 0;
      Fingerprint : Natural := 0;
   end record;

   type Overload_Ranking_Provenance_Result_Set is private;
   type Overload_Ranking_Provenance_Model is private;

   procedure Clear (Model : in out Overload_Ranking_Provenance_Model);

   function Build
     (Diagnostics : Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Model;
      Rankings    : Editor.Ada_Overload_Ranking.Overload_Ranking_Model)
      return Overload_Ranking_Provenance_Model;

   function Item_Count (Model : Overload_Ranking_Provenance_Model) return Natural;
   function Item_At
     (Model : Overload_Ranking_Provenance_Model;
      Index : Positive) return Overload_Ranking_Provenance_Item;

   function Count_Outcome
     (Model   : Overload_Ranking_Provenance_Model;
      Outcome : Overload_Ranking_Provenance_Outcome) return Natural;

   function Count_Stage
     (Model : Overload_Ranking_Provenance_Model;
      Stage : Overload_Ranking_Provenance_Stage) return Natural;

   function Exact_Outcome_Count (Model : Overload_Ranking_Provenance_Model) return Natural;
   function Implicit_Conversion_Outcome_Count (Model : Overload_Ranking_Provenance_Model) return Natural;
   function Universal_Numeric_Outcome_Count (Model : Overload_Ranking_Provenance_Model) return Natural;
   function Ambiguous_Outcome_Count (Model : Overload_Ranking_Provenance_Model) return Natural;
   function Rejected_Outcome_Count (Model : Overload_Ranking_Provenance_Model) return Natural;
   function Unknown_Outcome_Count (Model : Overload_Ranking_Provenance_Model) return Natural;
   function Unlinked_Diagnostic_Count (Model : Overload_Ranking_Provenance_Model) return Natural;
   function Unlinked_Ranking_Count (Model : Overload_Ranking_Provenance_Model) return Natural;

   function First_For_Ranking
     (Model   : Overload_Ranking_Provenance_Model;
      Ranking : Editor.Ada_Overload_Ranking.Overload_Ranking_Id)
      return Overload_Ranking_Provenance_Item;

   function Items_For_Ranking
     (Model   : Overload_Ranking_Provenance_Model;
      Ranking : Editor.Ada_Overload_Ranking.Overload_Ranking_Id)
      return Overload_Ranking_Provenance_Result_Set;

   function First_For_Diagnostic
     (Model      : Overload_Ranking_Provenance_Model;
      Diagnostic : Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Id)
      return Overload_Ranking_Provenance_Item;

   function Result_Count (Results : Overload_Ranking_Provenance_Result_Set) return Natural;
   function Result_At
     (Results : Overload_Ranking_Provenance_Result_Set;
      Index   : Positive) return Overload_Ranking_Provenance_Item;

   function Has_Item (Item : Overload_Ranking_Provenance_Item) return Boolean;
   function Fingerprint (Model : Overload_Ranking_Provenance_Model) return Natural;

private
   package Item_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Overload_Ranking_Provenance_Item);

   type Overload_Ranking_Provenance_Result_Set is record
      Items       : Item_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Overload_Ranking_Provenance_Model is record
      Items             : Item_Vectors.Vector;
      Exact_Total       : Natural := 0;
      Implicit_Total    : Natural := 0;
      Universal_Total   : Natural := 0;
      Ambiguous_Total   : Natural := 0;
      Rejected_Total    : Natural := 0;
      Unknown_Total     : Natural := 0;
      Not_Overload_Total : Natural := 0;
      Unlinked_Diagnostic_Total : Natural := 0;
      Unlinked_Ranking_Total    : Natural := 0;
      Evidence_Stage_Total      : Natural := 0;
      Cause_Stage_Total         : Natural := 0;
      Ranking_Stage_Total       : Natural := 0;
      Diagnostic_Stage_Total    : Natural := 0;
      Result_Fingerprint        : Natural := 0;
   end record;

end Editor.Ada_Overload_Ranking_Provenance;
