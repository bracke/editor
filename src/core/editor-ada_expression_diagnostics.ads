with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Expression_Types;
with Editor.Ada_Overload_Ambiguity_Diagnostics;
with Editor.Ada_View_Aware_Compatibility;
with Editor.Ada_Dispatching_Call_Legality;
with Editor.Ada_Overload_Ranking;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Expression_Diagnostics is

   --  Snapshot-owned diagnostics projection for expression-type metadata.  This
   --  package consumes an already-built expression type model and emits bounded,
   --  deterministic diagnostics with stable source spans.  It performs no
   --  parsing, file IO, editor mutation, command registration, or rendering work.

   type Expression_Diagnostic_Id is new Natural;
   No_Expression_Diagnostic : constant Expression_Diagnostic_Id := 0;

   type Expression_Diagnostic_Severity is
     (Expression_Diagnostic_Severity_Info,
      Expression_Diagnostic_Warning,
      Expression_Diagnostic_Error);

   type Expression_Diagnostic_Kind is
     (Expression_Diagnostic_Expected_Type_Mismatch,
      Expression_Diagnostic_Operator_Operand_Mismatch,
      Expression_Diagnostic_Operator_Ambiguous,
      Expression_Diagnostic_Call_Actual_Mismatch,
      Expression_Diagnostic_Call_Ambiguous,
      Expression_Diagnostic_Aggregate_Mismatch,
      Expression_Diagnostic_Conversion_Mismatch,
      Expression_Diagnostic_Membership_Mismatch,
      Expression_Diagnostic_Range_Mismatch,
      Expression_Diagnostic_Dereference_Target_Error,
      Expression_Diagnostic_Allocator_Target_Error,
      Expression_Diagnostic_Boolean_Context_Mismatch,
      Expression_Diagnostic_Universal_Numeric_Range_Error,
      Expression_Diagnostic_Concatenation_Mismatch,
      Expression_Diagnostic_Unresolved_Expression,
      Expression_Diagnostic_Unknown_Expression);

   type Expression_Diagnostic_Info is record
      Id       : Expression_Diagnostic_Id := No_Expression_Diagnostic;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Expression_Diagnostic_Kind := Expression_Diagnostic_Unknown_Expression;
      Severity : Expression_Diagnostic_Severity := Expression_Diagnostic_Warning;
      Message  : Ada.Strings.Unbounded.Unbounded_String;
      Detail   : Ada.Strings.Unbounded.Unbounded_String;
      From_Overload_Cause : Boolean := False;
      From_View_Compatibility : Boolean := False;
      From_Dispatching_Legality : Boolean := False;
      From_Overload_Ranking : Boolean := False;
      View_Compatibility : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Id :=
        Editor.Ada_View_Aware_Compatibility.No_View_Compatibility;
      View_Status : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Status :=
        Editor.Ada_View_Aware_Compatibility.View_Compatibility_Not_Checked;
      Dispatching_Legality : Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Id :=
        Editor.Ada_Dispatching_Call_Legality.No_Dispatching_Legality;
      Dispatching_Status : Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Status :=
        Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Not_Checked;
      Overload_Ranking : Editor.Ada_Overload_Ranking.Overload_Ranking_Id :=
        Editor.Ada_Overload_Ranking.No_Overload_Ranking;
      Overload_Ranking_Status : Editor.Ada_Overload_Ranking.Overload_Ranking_Status :=
        Editor.Ada_Overload_Ranking.Overload_Ranking_Not_Checked;
      Candidate_Count  : Natural := 0;
      Selected_Count   : Natural := 0;
      Compatible_Count : Natural := 0;
      Mismatch_Count   : Natural := 0;
      Unknown_Count    : Natural := 0;
      Cause_Fingerprint : Natural := 0;
      View_Fingerprint  : Natural := 0;
      Dispatching_Fingerprint : Natural := 0;
      Overload_Ranking_Fingerprint : Natural := 0;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
      Fingerprint  : Natural := 0;
   end record;

   type Expression_Diagnostic_Model is private;

   procedure Clear (Model : in out Expression_Diagnostic_Model);

   function Build
     (Expressions : Editor.Ada_Expression_Types.Expression_Type_Model)
      return Expression_Diagnostic_Model;

   function Build_With_Overload_Causes
     (Expressions : Editor.Ada_Expression_Types.Expression_Type_Model;
      Causes      : Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Model)
      return Expression_Diagnostic_Model;

   function Build_With_View_Compatibility
     (Expressions : Editor.Ada_Expression_Types.Expression_Type_Model;
      Views       : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Model)
      return Expression_Diagnostic_Model;

   function Build_With_Overload_Causes_And_View_Compatibility
     (Expressions : Editor.Ada_Expression_Types.Expression_Type_Model;
      Causes      : Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Model;
      Views       : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Model)
      return Expression_Diagnostic_Model;

   function Build_With_Overload_Ranking
     (Expressions : Editor.Ada_Expression_Types.Expression_Type_Model;
      Ranking     : Editor.Ada_Overload_Ranking.Overload_Ranking_Model)
      return Expression_Diagnostic_Model;

   function Build_With_Dispatching_Legality
     (Expressions  : Editor.Ada_Expression_Types.Expression_Type_Model;
      Dispatching : Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Model)
      return Expression_Diagnostic_Model;

   function Build_With_All_Semantic_Causes
     (Expressions  : Editor.Ada_Expression_Types.Expression_Type_Model;
      Causes       : Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Model;
      Views        : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Model;
      Dispatching  : Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Model)
      return Expression_Diagnostic_Model;

   function Build_With_All_Semantic_Causes_And_Ranking
     (Expressions  : Editor.Ada_Expression_Types.Expression_Type_Model;
      Causes       : Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Model;
      Views        : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Model;
      Dispatching  : Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Model;
      Ranking      : Editor.Ada_Overload_Ranking.Overload_Ranking_Model)
      return Expression_Diagnostic_Model;

   function Has_Diagnostics (Model : Expression_Diagnostic_Model) return Boolean;
   function Diagnostic_Count (Model : Expression_Diagnostic_Model) return Natural;
   function Diagnostic_At
     (Model : Expression_Diagnostic_Model;
      Index : Positive) return Expression_Diagnostic_Info;
   function Diagnostic_For_Node
     (Model : Expression_Diagnostic_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Expression_Diagnostic_Info;

   function Error_Count (Model : Expression_Diagnostic_Model) return Natural;
   function Warning_Count (Model : Expression_Diagnostic_Model) return Natural;
   function Info_Count (Model : Expression_Diagnostic_Model) return Natural;
   function Count_Kind
     (Model : Expression_Diagnostic_Model;
      Kind  : Expression_Diagnostic_Kind) return Natural;
   function Overload_Cause_Diagnostic_Count
     (Model : Expression_Diagnostic_Model) return Natural;
   function Candidate_Rejection_Count
     (Model : Expression_Diagnostic_Model) return Natural;
   function View_Compatibility_Diagnostic_Count
     (Model : Expression_Diagnostic_Model) return Natural;
   function Private_View_Diagnostic_Count
     (Model : Expression_Diagnostic_Model) return Natural;
   function Limited_View_Diagnostic_Count
     (Model : Expression_Diagnostic_Model) return Natural;
   function View_Unresolved_Diagnostic_Count
     (Model : Expression_Diagnostic_Model) return Natural;
   function Dispatching_Legality_Diagnostic_Count
     (Model : Expression_Diagnostic_Model) return Natural;
   function Dispatching_Dynamic_Diagnostic_Count
     (Model : Expression_Diagnostic_Model) return Natural;
   function Dispatching_Static_Diagnostic_Count
     (Model : Expression_Diagnostic_Model) return Natural;
   function Dispatching_Unresolved_Diagnostic_Count
     (Model : Expression_Diagnostic_Model) return Natural;
   function Overload_Ranking_Diagnostic_Count
     (Model : Expression_Diagnostic_Model) return Natural;
   function Overload_Ranking_Ambiguous_Diagnostic_Count
     (Model : Expression_Diagnostic_Model) return Natural;
   function Overload_Ranking_Rejection_Diagnostic_Count
     (Model : Expression_Diagnostic_Model) return Natural;
   function Fingerprint (Model : Expression_Diagnostic_Model) return Natural;

private
   package Diagnostic_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Expression_Diagnostic_Info);

   type Expression_Diagnostic_Model is record
      Diagnostics        : Diagnostic_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Expression_Diagnostics;
