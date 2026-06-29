with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Expected_Call_Filters;
with Editor.Ada_Overload_Ranking;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Wide_Semantic_Legality_Diagnostics;

package Editor.Ada_Overload_Resolution_Legality is

   --  Pass1109 compiler-grade overload/operator resolution legality layer.
   --  This package consumes the overload-ranking model plus the widened
   --  semantic-legality diagnostic bridge and classifies whether callable and
   --  operator choices are legally selected, rejected by Ada overload rules,
   --  blocked by visibility/view/dependency state, or still indeterminate.  It
   --  performs no parsing, file IO, buffer mutation, command/keybinding/workspace
   --  mutation, render-side work, compiler invocation, or edit application.

   type Overload_Context_Id is new Natural;
   No_Overload_Context : constant Overload_Context_Id := 0;

   type Overload_Legality_Id is new Natural;
   No_Overload_Legality : constant Overload_Legality_Id := 0;

   type Overload_Context_Kind is
     (Overload_Context_Call,
      Overload_Context_Operator,
      Overload_Context_Attribute_Call,
      Overload_Context_Dispatching_Call,
      Overload_Context_Generic_Actual_Subprogram,
      Overload_Context_Unknown);

   type Overload_Legality_Status is
     (Overload_Legality_Not_Checked,
      Overload_Legality_Legal_Exact,
      Overload_Legality_Legal_Expected_Type_Preferred,
      Overload_Legality_Legal_Universal_Integer_Preferred,
      Overload_Legality_Legal_Universal_Real_Preferred,
      Overload_Legality_Legal_Primitive_Operator_Preferred,
      Overload_Legality_Legal_Implicit_Numeric_Conversion,
      Overload_Legality_Legal_Class_Wide_Conversion,
      Overload_Legality_Legal_Access_Conversion,
      Overload_Legality_Legal_Named_Actual_Profile,
      Overload_Legality_Legal_Defaulted_Formal_Profile,
      Overload_Legality_Ambiguous_After_Preference,
      Overload_Legality_No_Visible_Candidate,
      Overload_Legality_Not_Visible,
      Overload_Legality_Profile_Mismatch,
      Overload_Legality_Actual_Type_Mismatch,
      Overload_Legality_Defaulted_Formal_Mismatch,
      Overload_Legality_Private_View_Barrier,
      Overload_Legality_Limited_View_Barrier,
      Overload_Legality_Cross_Unit_Unresolved,
      Overload_Legality_Linked_Semantic_Error,
      Overload_Legality_Unknown,
      Overload_Legality_Indeterminate);

   type Overload_Context_Info is record
      Id       : Overload_Context_Id := No_Overload_Context;
      Kind     : Overload_Context_Kind := Overload_Context_Unknown;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Designator : Ada.Strings.Unbounded.Unbounded_String;
      Expected_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Selected_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Candidate_Count : Natural := 0;
      Visible_Candidate_Count : Natural := 0;
      Exact_Match_Count : Natural := 0;
      Expected_Type_Match_Count : Natural := 0;
      Universal_Integer_Count : Natural := 0;
      Universal_Real_Count : Natural := 0;
      Primitive_Operator_Count : Natural := 0;
      Implicit_Numeric_Conversion_Count : Natural := 0;
      Class_Wide_Conversion_Count : Natural := 0;
      Access_Conversion_Count : Natural := 0;
      Named_Actual_Match_Count : Natural := 0;
      Defaulted_Formal_Count : Natural := 0;
      Profile_Mismatch_Count : Natural := 0;
      Actual_Type_Mismatch_Count : Natural := 0;
      Defaulted_Formal_Mismatch_Count : Natural := 0;
      Ambiguous_Candidate_Count : Natural := 0;
      Candidate_Not_Visible_Count : Natural := 0;
      Private_View_Barrier : Boolean := False;
      Limited_View_Barrier : Boolean := False;
      Cross_Unit_Unresolved : Boolean := False;
      Linked_Wide_Diagnostic : Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Id :=
        Editor.Ada_Wide_Semantic_Legality_Diagnostics.No_Wide_Semantic_Diagnostic;
      Ranking : Editor.Ada_Overload_Ranking.Overload_Ranking_Id :=
        Editor.Ada_Overload_Ranking.No_Overload_Ranking;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
      Source_Fingerprint : Natural := 0;
   end record;

   type Overload_Legality_Info is record
      Id       : Overload_Legality_Id := No_Overload_Legality;
      Context  : Overload_Context_Id := No_Overload_Context;
      Kind     : Overload_Context_Kind := Overload_Context_Unknown;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status   : Overload_Legality_Status := Overload_Legality_Not_Checked;
      Designator : Ada.Strings.Unbounded.Unbounded_String;
      Message  : Ada.Strings.Unbounded.Unbounded_String;
      Detail   : Ada.Strings.Unbounded.Unbounded_String;
      Ranking  : Editor.Ada_Overload_Ranking.Overload_Ranking_Id :=
        Editor.Ada_Overload_Ranking.No_Overload_Ranking;
      Ranking_Status : Editor.Ada_Overload_Ranking.Overload_Ranking_Status :=
        Editor.Ada_Overload_Ranking.Overload_Ranking_Not_Checked;
      Linked_Wide_Diagnostic : Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Id :=
        Editor.Ada_Wide_Semantic_Legality_Diagnostics.No_Wide_Semantic_Diagnostic;
      Candidate_Count : Natural := 0;
      Visible_Candidate_Count : Natural := 0;
      Selected_Count : Natural := 0;
      Rejected_Count : Natural := 0;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
      Source_Fingerprint : Natural := 0;
      Ranking_Fingerprint : Natural := 0;
      Wide_Diagnostic_Fingerprint : Natural := 0;
      Fingerprint : Natural := 0;
   end record;

   type Overload_Context_Model is private;
   type Overload_Legality_Result_Set is private;
   type Overload_Legality_Model is private;

   procedure Clear (Model : in out Overload_Context_Model);
   procedure Add_Context
     (Model : in out Overload_Context_Model;
      Info  : Overload_Context_Info);

   function Build_Contexts_From_Expected_Call_Filters
     (Filters : Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Model)
      return Overload_Context_Model;

   function Context_Count (Model : Overload_Context_Model) return Natural;
   function Context_At
     (Model : Overload_Context_Model;
      Index : Positive) return Overload_Context_Info;
   function Fingerprint (Model : Overload_Context_Model) return Natural;

   function Build
     (Contexts : Overload_Context_Model;
      Rankings : Editor.Ada_Overload_Ranking.Overload_Ranking_Model;
      Wide_Diagnostics : Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Model)
      return Overload_Legality_Model;

   function Legality_Count (Model : Overload_Legality_Model) return Natural;
   function Legality_At
     (Model : Overload_Legality_Model;
      Index : Positive) return Overload_Legality_Info;

   function First_For_Node
     (Model : Overload_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Overload_Legality_Info;
   function Rows_For_Status
     (Model  : Overload_Legality_Model;
      Status : Overload_Legality_Status) return Overload_Legality_Result_Set;
   function Rows_For_Kind
     (Model : Overload_Legality_Model;
      Kind  : Overload_Context_Kind) return Overload_Legality_Result_Set;
   function Rows_For_Designator
     (Model      : Overload_Legality_Model;
      Designator : String) return Overload_Legality_Result_Set;

   function Result_Count (Results : Overload_Legality_Result_Set) return Natural;
   function Result_At
     (Results : Overload_Legality_Result_Set;
      Index   : Positive) return Overload_Legality_Info;

   function Count_Status
     (Model  : Overload_Legality_Model;
      Status : Overload_Legality_Status) return Natural;
   function Count_Kind
     (Model : Overload_Legality_Model;
      Kind  : Overload_Context_Kind) return Natural;

   function Legal_Count (Model : Overload_Legality_Model) return Natural;
   function Error_Count (Model : Overload_Legality_Model) return Natural;
   function Ambiguous_Count (Model : Overload_Legality_Model) return Natural;
   function Visibility_Error_Count (Model : Overload_Legality_Model) return Natural;
   function View_Barrier_Count (Model : Overload_Legality_Model) return Natural;
   function Cross_Unit_Unresolved_Count (Model : Overload_Legality_Model) return Natural;
   function Linked_Semantic_Error_Count (Model : Overload_Legality_Model) return Natural;
   function Indeterminate_Count (Model : Overload_Legality_Model) return Natural;
   function Fingerprint (Model : Overload_Legality_Model) return Natural;

   function Has_Legality (Info : Overload_Legality_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Overload_Context_Info);
   package Legality_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Overload_Legality_Info);

   type Overload_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Overload_Legality_Result_Set is record
      Items : Legality_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Overload_Legality_Model is record
      Items : Legality_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Ambiguous_Total : Natural := 0;
      Visibility_Total : Natural := 0;
      View_Barrier_Total : Natural := 0;
      Cross_Unit_Total : Natural := 0;
      Linked_Error_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Overload_Resolution_Legality;
