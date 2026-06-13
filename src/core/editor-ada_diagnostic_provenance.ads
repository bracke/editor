with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Semantic_Colour_Projection;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.Ada_Overload_Ranking_Provenance;
with Editor.Ada_Integrated_Semantic_Closure;
with Editor.Ada_Syntax_Tree;
with Editor.Syntax;

package Editor.Ada_Diagnostic_Provenance is

   --  Projection-only diagnostic provenance model over the snapshot-guarded
   --  Ada semantic diagnostic index.  This package explains which semantic
   --  diagnostic family produced an indexed diagnostic and preserves the
   --  accepted source chain for IDE "explain diagnostic" consumers.  It does
   --  not parse, perform file IO, mutate buffers, register commands, touch
   --  workspace state, apply edits, or perform rendering work.

   subtype Feed_Entry is
     Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Entry;
   subtype Feed_Severity is
     Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Severity;
   subtype Feed_Source is
     Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Source;
   subtype Index_Entry is
     Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Entry;

   type Diagnostic_Provenance_Id is new Natural;
   No_Diagnostic_Provenance : constant Diagnostic_Provenance_Id := 0;

   type Diagnostic_Provenance_Status is
     (Diagnostic_Provenance_Current,
      Diagnostic_Provenance_Rejected_Stale);

   type Diagnostic_Provenance_Stage is
     (Diagnostic_Provenance_No_Stage,
      Diagnostic_Provenance_Semantic_Source,
      Diagnostic_Provenance_Diagnostic_Projection,
      Diagnostic_Provenance_Colour_Projection,
      Diagnostic_Provenance_Snapshot_Guard,
      Diagnostic_Provenance_Unified_Feed,
      Diagnostic_Provenance_Index,
      Diagnostic_Provenance_Overload_Ranking,
      Diagnostic_Provenance_Integrated_Closure);

   type Diagnostic_Provenance_Item is record
      Id          : Diagnostic_Provenance_Id := No_Diagnostic_Provenance;
      Index_Id    : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id :=
        Editor.Ada_Semantic_Diagnostic_Index.No_Semantic_Diagnostic_Index_Entry;
      Feed_Index  : Natural := 0;
      Diagnostic  : Feed_Entry;
      Severity    : Feed_Severity :=
        Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Info;
      Source      : Feed_Source :=
        Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression;
      Token       : Editor.Syntax.Token_Kind := Editor.Syntax.Identifier;
      Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Root_Stage  : Diagnostic_Provenance_Stage := Diagnostic_Provenance_No_Stage;
      Source_Label : Ada.Strings.Unbounded.Unbounded_String;
      Explanation  : Ada.Strings.Unbounded.Unbounded_String;
      Chain_Summary : Ada.Strings.Unbounded.Unbounded_String;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
      Source_Fingerprint : Natural := 0;
      Diagnostic_Fingerprint : Natural := 0;
      Ranking_Provenance : Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Provenance_Id :=
        Editor.Ada_Overload_Ranking_Provenance.No_Overload_Ranking_Provenance;
      Ranking_Outcome : Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Provenance_Outcome :=
        Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Outcome_Unlinked;
      Ranking_Candidate_Count : Natural := 0;
      Ranking_Selected_Count  : Natural := 0;
      Ranking_Rejected_Count  : Natural := 0;
      Ranking_Unknown_Count   : Natural := 0;
      Ranking_Fingerprint     : Natural := 0;
      Integrated_Closure : Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Id :=
        Editor.Ada_Integrated_Semantic_Closure.No_Integrated_Closure;
      Integrated_Closure_Status : Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Status :=
        Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Not_Checked;
      Integrated_Closure_Blocker : Editor.Ada_Integrated_Semantic_Closure.Closure_Blocker_Family :=
        Editor.Ada_Integrated_Semantic_Closure.Closure_Blocker_None;
      Integrated_Closure_Dependency : Editor.Ada_Integrated_Semantic_Closure.Closure_Dependency_State :=
        Editor.Ada_Integrated_Semantic_Closure.Dependency_Unknown;
      Integrated_Closure_Fingerprint : Natural := 0;
      Fingerprint  : Natural := 0;
   end record;

   type Diagnostic_Provenance_Result_Set is private;
   type Diagnostic_Provenance_Model is private;

   procedure Clear (Model : in out Diagnostic_Provenance_Model);

   function Build
     (Index : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model)
      return Diagnostic_Provenance_Model;

   function Build_With_Overload_Ranking
     (Index : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model;
      Ranking_Provenance :
        Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Provenance_Model)
      return Diagnostic_Provenance_Model;

   function Build_With_Integrated_Closure
     (Index : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model;
      Closure : Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Model)
      return Diagnostic_Provenance_Model;

   function Status (Model : Diagnostic_Provenance_Model) return Diagnostic_Provenance_Status;
   function Current (Model : Diagnostic_Provenance_Model) return Boolean;
   function Rejected_Stale (Model : Diagnostic_Provenance_Model) return Boolean;

   function Item_Count (Model : Diagnostic_Provenance_Model) return Natural;
   function Item_At
     (Model : Diagnostic_Provenance_Model;
      Index : Positive) return Diagnostic_Provenance_Item;

   function Error_Item_Count (Model : Diagnostic_Provenance_Model) return Natural;
   function Warning_Item_Count (Model : Diagnostic_Provenance_Model) return Natural;
   function Info_Item_Count (Model : Diagnostic_Provenance_Model) return Natural;
   function Rejected_Item_Count (Model : Diagnostic_Provenance_Model) return Natural;
   function Overload_Ranking_Item_Count (Model : Diagnostic_Provenance_Model) return Natural;
   function Integrated_Closure_Item_Count (Model : Diagnostic_Provenance_Model) return Natural;

   function Count_Source
     (Model  : Diagnostic_Provenance_Model;
      Source : Feed_Source) return Natural;

   function Count_Stage
     (Model : Diagnostic_Provenance_Model;
      Stage : Diagnostic_Provenance_Stage) return Natural;

   function First_For_Diagnostic
     (Model    : Diagnostic_Provenance_Model;
      Index_Id : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id)
      return Diagnostic_Provenance_Item;

   function Items_For_Diagnostic
     (Model    : Diagnostic_Provenance_Model;
      Index_Id : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id)
      return Diagnostic_Provenance_Result_Set;

   function Result_Count (Results : Diagnostic_Provenance_Result_Set) return Natural;
   function Result_At
     (Results : Diagnostic_Provenance_Result_Set;
      Index   : Positive) return Diagnostic_Provenance_Item;

   function Has_Item (Item : Diagnostic_Provenance_Item) return Boolean;
   function Fingerprint (Model : Diagnostic_Provenance_Model) return Natural;

private
   package Item_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Diagnostic_Provenance_Item);

   type Diagnostic_Provenance_Result_Set is record
      Items       : Item_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Diagnostic_Provenance_Model is record
      Model_Status         : Diagnostic_Provenance_Status := Diagnostic_Provenance_Current;
      Items                : Item_Vectors.Vector;
      Error_Total          : Natural := 0;
      Warning_Total        : Natural := 0;
      Info_Total           : Natural := 0;
      Rejected_Total       : Natural := 0;
      Expression_Total     : Natural := 0;
      Generic_Total        : Natural := 0;
      Cross_Unit_Total     : Natural := 0;
      Representation_Total : Natural := 0;
      Source_Stage_Total   : Natural := 0;
      Projection_Stage_Total : Natural := 0;
      Colour_Stage_Total   : Natural := 0;
      Guard_Stage_Total    : Natural := 0;
      Feed_Stage_Total     : Natural := 0;
      Index_Stage_Total    : Natural := 0;
      Overload_Ranking_Stage_Total : Natural := 0;
      Integrated_Closure_Stage_Total : Natural := 0;
      Result_Fingerprint   : Natural := 0;
   end record;

end Editor.Ada_Diagnostic_Provenance;
