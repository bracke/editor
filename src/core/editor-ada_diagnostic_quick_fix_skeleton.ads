with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Semantic_Colour_Projection;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.Ada_Overload_Ranking_Provenance;
with Editor.Ada_Syntax_Tree;
with Editor.Syntax;

package Editor.Ada_Diagnostic_Quick_Fix_Skeleton is

   --  Projection-only quick-fix candidate model over the snapshot-guarded Ada
   --  semantic diagnostic index.  This package does not synthesize or apply
   --  edits, mutate buffers, parse, save, reload, register commands, touch
   --  workspace state, or perform rendering work.  It can carry explicit
   --  producer-owned edit hints as metadata for executor-owned application.

   subtype Feed_Entry is
     Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Entry;
   subtype Feed_Severity is
     Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Severity;
   subtype Feed_Source is
     Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Source;
   subtype Index_Entry is
     Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Entry;

   type Diagnostic_Quick_Fix_Candidate_Id is new Natural;
   No_Diagnostic_Quick_Fix_Candidate : constant Diagnostic_Quick_Fix_Candidate_Id := 0;

   type Diagnostic_Quick_Fix_Status is
     (Diagnostic_Quick_Fix_Current,
      Diagnostic_Quick_Fix_Rejected_Stale);

   type Diagnostic_Quick_Fix_Action_Kind is
     (Diagnostic_Quick_Fix_No_Action,
      Diagnostic_Quick_Fix_Navigate_To_Diagnostic,
      Diagnostic_Quick_Fix_Show_Explanation,
      Diagnostic_Quick_Fix_Review_Expression_Type,
      Diagnostic_Quick_Fix_Review_Overload_Ranking,
      Diagnostic_Quick_Fix_Review_Generic_Actual,
      Diagnostic_Quick_Fix_Review_Cross_Unit_Dependency,
      Diagnostic_Quick_Fix_Review_Representation_Item);

   type Diagnostic_Quick_Fix_Confidence is
     (Diagnostic_Quick_Fix_No_Confidence,
      Diagnostic_Quick_Fix_Low_Confidence,
      Diagnostic_Quick_Fix_Medium_Confidence,
      Diagnostic_Quick_Fix_High_Confidence);

   type Diagnostic_Quick_Fix_Candidate is record
      Id          : Diagnostic_Quick_Fix_Candidate_Id := No_Diagnostic_Quick_Fix_Candidate;
      Index_Id    : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id :=
        Editor.Ada_Semantic_Diagnostic_Index.No_Semantic_Diagnostic_Index_Entry;
      Feed_Index  : Natural := 0;
      Diagnostic  : Feed_Entry;
      Action      : Diagnostic_Quick_Fix_Action_Kind := Diagnostic_Quick_Fix_No_Action;
      Confidence  : Diagnostic_Quick_Fix_Confidence := Diagnostic_Quick_Fix_No_Confidence;
      Severity    : Feed_Severity :=
        Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Info;
      Source      : Feed_Source :=
        Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression;
      Token       : Editor.Syntax.Token_Kind := Editor.Syntax.Identifier;
      Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Label       : Ada.Strings.Unbounded.Unbounded_String;
      Detail      : Ada.Strings.Unbounded.Unbounded_String;
      Has_Edit    : Boolean := False;
      Edit_Start_Line   : Positive := 1;
      Edit_Start_Column : Positive := 1;
      Edit_End_Line     : Positive := 1;
      Edit_End_Column   : Positive := 1;
      Replacement_Text  : Ada.Strings.Unbounded.Unbounded_String;
      Ranking_Provenance :
        Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Provenance_Id :=
          Editor.Ada_Overload_Ranking_Provenance.No_Overload_Ranking_Provenance;
      Ranking_Outcome :
        Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Provenance_Outcome :=
          Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Outcome_Unlinked;
      Ranking_Candidate_Count : Natural := 0;
      Ranking_Selected_Count  : Natural := 0;
      Ranking_Rejected_Count  : Natural := 0;
      Ranking_Unknown_Count   : Natural := 0;
      Ranking_Fingerprint     : Natural := 0;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
      Fingerprint  : Natural := 0;
   end record;

   type Diagnostic_Quick_Fix_Result_Set is private;
   type Diagnostic_Quick_Fix_Model is private;

   procedure Clear (Model : in out Diagnostic_Quick_Fix_Model);

   function Build
     (Index : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model)
      return Diagnostic_Quick_Fix_Model;

   function Build_With_Overload_Ranking
     (Index : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model;
      Ranking_Provenance :
        Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Provenance_Model)
      return Diagnostic_Quick_Fix_Model;

   function Status (Model : Diagnostic_Quick_Fix_Model) return Diagnostic_Quick_Fix_Status;
   function Current (Model : Diagnostic_Quick_Fix_Model) return Boolean;
   function Rejected_Stale (Model : Diagnostic_Quick_Fix_Model) return Boolean;

   function Candidate_Count (Model : Diagnostic_Quick_Fix_Model) return Natural;
   function Candidate_At
     (Model : Diagnostic_Quick_Fix_Model;
      Index : Positive) return Diagnostic_Quick_Fix_Candidate;

   function Error_Candidate_Count (Model : Diagnostic_Quick_Fix_Model) return Natural;
   function Warning_Candidate_Count (Model : Diagnostic_Quick_Fix_Model) return Natural;
   function Info_Candidate_Count (Model : Diagnostic_Quick_Fix_Model) return Natural;
   function Rejected_Candidate_Count (Model : Diagnostic_Quick_Fix_Model) return Natural;
   function Editable_Candidate_Count (Model : Diagnostic_Quick_Fix_Model) return Natural;
   function Overload_Ranking_Candidate_Count
     (Model : Diagnostic_Quick_Fix_Model) return Natural;

   function Count_Action
     (Model  : Diagnostic_Quick_Fix_Model;
      Action : Diagnostic_Quick_Fix_Action_Kind) return Natural;

   function Count_Source
     (Model  : Diagnostic_Quick_Fix_Model;
      Source : Feed_Source) return Natural;

   function First_For_Diagnostic
     (Model    : Diagnostic_Quick_Fix_Model;
      Index_Id : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id)
      return Diagnostic_Quick_Fix_Candidate;

   function Candidates_For_Diagnostic
     (Model    : Diagnostic_Quick_Fix_Model;
      Index_Id : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id)
      return Diagnostic_Quick_Fix_Result_Set;

   function Result_Count (Results : Diagnostic_Quick_Fix_Result_Set) return Natural;
   function Result_At
     (Results : Diagnostic_Quick_Fix_Result_Set;
      Index   : Positive) return Diagnostic_Quick_Fix_Candidate;

   function Has_Candidate (Candidate : Diagnostic_Quick_Fix_Candidate) return Boolean;
   function Fingerprint (Model : Diagnostic_Quick_Fix_Model) return Natural;

private
   package Candidate_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Diagnostic_Quick_Fix_Candidate);

   type Diagnostic_Quick_Fix_Result_Set is record
      Candidates  : Candidate_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Diagnostic_Quick_Fix_Model is record
      Model_Status          : Diagnostic_Quick_Fix_Status := Diagnostic_Quick_Fix_Current;
      Candidates            : Candidate_Vectors.Vector;
      Error_Total           : Natural := 0;
      Warning_Total         : Natural := 0;
      Info_Total            : Natural := 0;
      Rejected_Total        : Natural := 0;
      Editable_Total        : Natural := 0;
      Navigate_Total        : Natural := 0;
      Explanation_Total     : Natural := 0;
      Expression_Total      : Natural := 0;
      Overload_Ranking_Total : Natural := 0;
      Generic_Total         : Natural := 0;
      Cross_Unit_Total      : Natural := 0;
      Representation_Total  : Natural := 0;
      Result_Fingerprint    : Natural := 0;
   end record;

end Editor.Ada_Diagnostic_Quick_Fix_Skeleton;
