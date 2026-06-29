with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Diagnostic_Navigation;
with Editor.Ada_Diagnostic_Panel_Projection;
with Editor.Ada_Diagnostic_Provenance;
with Editor.Ada_Diagnostic_Quick_Fix_Skeleton;
with Editor.Ada_Diagnostic_Status_Line;
with Editor.Ada_Semantic_Colour_Projection;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.Ada_Syntax_Tree;
with Editor.Syntax;

package Editor.Ada_Diagnostic_Action_Router is

   --  Projection-only diagnostic action routing over already-built Ada
   --  diagnostic IDE models.  This package does not apply edits, mutate
   --  buffers, parse, perform file IO, register commands, touch workspace
   --  state, or perform rendering work.  It joins quick-fix skeleton actions
   --  and any producer-owned edit hints to navigation, panel, status-line, and
   --  provenance metadata for deterministic IDE presentation.

   subtype Feed_Entry is
     Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Entry;
   subtype Feed_Severity is
     Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Severity;
   subtype Feed_Source is
     Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Source;

   type Diagnostic_Action_Route_Id is new Natural;
   No_Diagnostic_Action_Route : constant Diagnostic_Action_Route_Id := 0;

   type Diagnostic_Action_Router_Status is
     (Diagnostic_Action_Router_Current,
      Diagnostic_Action_Router_Rejected_Stale);

   type Diagnostic_Action_Route_Kind is
     (Diagnostic_Action_Route_None,
      Diagnostic_Action_Route_Navigate,
      Diagnostic_Action_Route_Explain,
      Diagnostic_Action_Route_Review_Expression,
      Diagnostic_Action_Route_Review_Overload_Ranking,
      Diagnostic_Action_Route_Review_Generic,
      Diagnostic_Action_Route_Review_Cross_Unit,
      Diagnostic_Action_Route_Review_Representation);

   type Diagnostic_Action_Route_Target_Status is
     (Diagnostic_Action_Route_Target_Complete,
      Diagnostic_Action_Route_Target_No_Navigation,
      Diagnostic_Action_Route_Target_No_Panel_Row,
      Diagnostic_Action_Route_Target_No_Provenance,
      Diagnostic_Action_Route_Target_Status_Only,
      Diagnostic_Action_Route_Target_Incomplete);

   type Diagnostic_Action_Route is record
      Id          : Diagnostic_Action_Route_Id := No_Diagnostic_Action_Route;
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
      Quick_Fix_Id :
        Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Candidate_Id :=
          Editor.Ada_Diagnostic_Quick_Fix_Skeleton.No_Diagnostic_Quick_Fix_Candidate;
      Quick_Fix_Action :
        Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Action_Kind :=
          Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_No_Action;
      Route_Kind  : Diagnostic_Action_Route_Kind := Diagnostic_Action_Route_None;
      Target_Status : Diagnostic_Action_Route_Target_Status :=
        Diagnostic_Action_Route_Target_Incomplete;
      Navigation_Target :
        Editor.Ada_Diagnostic_Navigation.Diagnostic_Navigation_Target_Id :=
          Editor.Ada_Diagnostic_Navigation.No_Diagnostic_Navigation_Target;
      Panel_Row : Editor.Ada_Diagnostic_Panel_Projection.Diagnostic_Panel_Row_Id :=
        Editor.Ada_Diagnostic_Panel_Projection.No_Diagnostic_Panel_Row;
      Provenance_Item : Editor.Ada_Diagnostic_Provenance.Diagnostic_Provenance_Id :=
        Editor.Ada_Diagnostic_Provenance.No_Diagnostic_Provenance;
      Status_Target_Available : Boolean := False;
      Has_Edit : Boolean := False;
      Edit_Start_Line   : Positive := 1;
      Edit_Start_Column : Positive := 1;
      Edit_End_Line     : Positive := 1;
      Edit_End_Column   : Positive := 1;
      Replacement_Text  : Ada.Strings.Unbounded.Unbounded_String;
      Label    : Ada.Strings.Unbounded.Unbounded_String;
      Detail   : Ada.Strings.Unbounded.Unbounded_String;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
      Quick_Fix_Fingerprint : Natural := 0;
      Navigation_Fingerprint : Natural := 0;
      Panel_Fingerprint : Natural := 0;
      Provenance_Fingerprint : Natural := 0;
      Status_Fingerprint : Natural := 0;
      Fingerprint : Natural := 0;
   end record;

   type Diagnostic_Action_Route_Set is private;
   type Diagnostic_Action_Router_Model is private;

   procedure Clear (Model : in out Diagnostic_Action_Router_Model);

   function Build
     (Quick_Fixes : Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Model;
      Navigation  : Editor.Ada_Diagnostic_Navigation.Diagnostic_Navigation_Model;
      Panel       : Editor.Ada_Diagnostic_Panel_Projection.Diagnostic_Panel_Model;
      Provenance  : Editor.Ada_Diagnostic_Provenance.Diagnostic_Provenance_Model;
      Status_Line : Editor.Ada_Diagnostic_Status_Line.Diagnostic_Status_Line_Model)
      return Diagnostic_Action_Router_Model;

   function Status
     (Model : Diagnostic_Action_Router_Model) return Diagnostic_Action_Router_Status;
   function Current (Model : Diagnostic_Action_Router_Model) return Boolean;
   function Rejected_Stale (Model : Diagnostic_Action_Router_Model) return Boolean;

   function Route_Count (Model : Diagnostic_Action_Router_Model) return Natural;
   function Route_At
     (Model : Diagnostic_Action_Router_Model;
      Index : Positive) return Diagnostic_Action_Route;

   function Complete_Route_Count (Model : Diagnostic_Action_Router_Model) return Natural;
   function Navigate_Route_Count (Model : Diagnostic_Action_Router_Model) return Natural;
   function Explain_Route_Count (Model : Diagnostic_Action_Router_Model) return Natural;
   function Overload_Ranking_Route_Count
     (Model : Diagnostic_Action_Router_Model) return Natural;
   function Rejected_Route_Count (Model : Diagnostic_Action_Router_Model) return Natural;
   function Editable_Route_Count (Model : Diagnostic_Action_Router_Model) return Natural;

   function Count_Kind
     (Model : Diagnostic_Action_Router_Model;
      Kind  : Diagnostic_Action_Route_Kind) return Natural;

   function Count_Target_Status
     (Model  : Diagnostic_Action_Router_Model;
      Status : Diagnostic_Action_Route_Target_Status) return Natural;

   function First_For_Diagnostic
     (Model    : Diagnostic_Action_Router_Model;
      Index_Id : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id)
      return Diagnostic_Action_Route;

   function Routes_For_Diagnostic
     (Model    : Diagnostic_Action_Router_Model;
      Index_Id : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id)
      return Diagnostic_Action_Route_Set;

   function Route_Set_Count (Routes : Diagnostic_Action_Route_Set) return Natural;
   function Route_Set_At
     (Routes : Diagnostic_Action_Route_Set;
      Index  : Positive) return Diagnostic_Action_Route;

   function Has_Route (Route : Diagnostic_Action_Route) return Boolean;
   function Fingerprint (Model : Diagnostic_Action_Router_Model) return Natural;

private
   package Route_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Diagnostic_Action_Route);

   type Diagnostic_Action_Route_Set is record
      Routes      : Route_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Diagnostic_Action_Router_Model is record
      Router_Status        : Diagnostic_Action_Router_Status := Diagnostic_Action_Router_Current;
      Routes               : Route_Vectors.Vector;
      Complete_Total       : Natural := 0;
      Rejected_Total       : Natural := 0;
      Editable_Total       : Natural := 0;
      Navigate_Total       : Natural := 0;
      Explain_Total        : Natural := 0;
      Expression_Total     : Natural := 0;
      Overload_Ranking_Total : Natural := 0;
      Generic_Total        : Natural := 0;
      Cross_Unit_Total     : Natural := 0;
      Representation_Total : Natural := 0;
      No_Navigation_Total  : Natural := 0;
      No_Panel_Total       : Natural := 0;
      No_Provenance_Total  : Natural := 0;
      Status_Only_Total    : Natural := 0;
      Incomplete_Total     : Natural := 0;
      Result_Fingerprint   : Natural := 0;
   end record;

end Editor.Ada_Diagnostic_Action_Router;
