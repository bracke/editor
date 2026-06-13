with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Expression_Types;
with Editor.Ada_Overload_Ambiguity_Diagnostics;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Overload_Ranking is

   --  Deterministic overload-ranking staging layer.  This package consumes the
   --  snapshot-owned expression type model and overload-cause metadata and
   --  classifies whether available call/operator/universal-numeric evidence is
   --  already exact, requires implicit-conversion ranking, is resolved by a
   --  universal-numeric tie-break, or remains rejected/ambiguous/unknown.  It
   --  performs no parsing, file IO, editor mutation, command registration,
   --  workspace mutation, rendering work, or edit application.

   type Overload_Ranking_Id is new Natural;
   No_Overload_Ranking : constant Overload_Ranking_Id := 0;

   type Overload_Ranking_Status is
     (Overload_Ranking_Not_Checked,
      Overload_Ranking_Not_Overload,
      Overload_Ranking_Exact_Match,
      Overload_Ranking_Implicit_Conversion,
      Overload_Ranking_Universal_Numeric_Tie_Break,
      Overload_Ranking_Ambiguous_After_Ranking,
      Overload_Ranking_No_Ranked_Candidate,
      Overload_Ranking_Unknown);

   type Overload_Ranking_Info is record
      Id          : Overload_Ranking_Id := No_Overload_Ranking;
      Expression  : Editor.Ada_Expression_Types.Expression_Type_Id :=
        Editor.Ada_Expression_Types.No_Expression_Type;
      Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Cause : Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Diagnostic_Id :=
        Editor.Ada_Overload_Ambiguity_Diagnostics.No_Overload_Ambiguity_Diagnostic;
      Status      : Overload_Ranking_Status := Overload_Ranking_Not_Checked;
      Message     : Ada.Strings.Unbounded.Unbounded_String;
      Detail      : Ada.Strings.Unbounded.Unbounded_String;
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
      Source_Fingerprint : Natural := 0;
      Cause_Fingerprint  : Natural := 0;
      Fingerprint  : Natural := 0;
   end record;

   type Overload_Ranking_Result_Set is private;
   type Overload_Ranking_Model is private;

   procedure Clear (Model : in out Overload_Ranking_Model);

   function Build
     (Expressions : Editor.Ada_Expression_Types.Expression_Type_Model;
      Causes      : Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Model)
      return Overload_Ranking_Model;

   function Ranking_Count (Model : Overload_Ranking_Model) return Natural;
   function Ranking_At
     (Model : Overload_Ranking_Model;
      Index : Positive) return Overload_Ranking_Info;

   function Count_Status
     (Model  : Overload_Ranking_Model;
      Status : Overload_Ranking_Status) return Natural;

   function Exact_Match_Count (Model : Overload_Ranking_Model) return Natural;
   function Implicit_Conversion_Count (Model : Overload_Ranking_Model) return Natural;
   function Universal_Numeric_Tie_Break_Count (Model : Overload_Ranking_Model) return Natural;
   function Ambiguous_After_Ranking_Count (Model : Overload_Ranking_Model) return Natural;
   function No_Ranked_Candidate_Count (Model : Overload_Ranking_Model) return Natural;
   function Unknown_Ranking_Count (Model : Overload_Ranking_Model) return Natural;
   function Candidate_Rejection_Count (Model : Overload_Ranking_Model) return Natural;

   function First_For_Node
     (Model : Overload_Ranking_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Overload_Ranking_Info;

   function Rankings_For_Node
     (Model : Overload_Ranking_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Overload_Ranking_Result_Set;

   function Result_Count (Results : Overload_Ranking_Result_Set) return Natural;
   function Result_At
     (Results : Overload_Ranking_Result_Set;
      Index   : Positive) return Overload_Ranking_Info;

   function Has_Ranking (Info : Overload_Ranking_Info) return Boolean;
   function Fingerprint (Model : Overload_Ranking_Model) return Natural;

private
   package Ranking_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Overload_Ranking_Info);

   type Overload_Ranking_Result_Set is record
      Rankings    : Ranking_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Overload_Ranking_Model is record
      Rankings        : Ranking_Vectors.Vector;
      Exact_Total     : Natural := 0;
      Implicit_Total  : Natural := 0;
      Universal_Total : Natural := 0;
      Ambiguous_Total : Natural := 0;
      No_Candidate_Total : Natural := 0;
      Unknown_Total   : Natural := 0;
      Rejection_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Overload_Ranking;
