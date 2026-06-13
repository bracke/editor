with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Expression_Types;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Overload_Ambiguity_Diagnostics is

   --  Deterministic overload-ambiguity explanation model over expression-type
   --  metadata.  This package does not perform overload resolution itself; it
   --  classifies the already snapshot-owned call/operator/universal-numeric
   --  inference statuses into stable diagnostic-cause records for IDE and
   --  diagnostics consumers.  It performs no parsing, file IO, editor mutation,
   --  command registration, workspace mutation, rendering work, or edit fixing.

   subtype Expression_Info is Editor.Ada_Expression_Types.Expression_Type_Info;

   type Overload_Ambiguity_Diagnostic_Id is new Natural;
   No_Overload_Ambiguity_Diagnostic : constant Overload_Ambiguity_Diagnostic_Id := 0;

   type Overload_Ambiguity_Severity is
     (Overload_Ambiguity_Info,
      Overload_Ambiguity_Warning,
      Overload_Ambiguity_Error);

   type Overload_Ambiguity_Kind is
     (Overload_Ambiguity_No_Kind,
      Overload_Ambiguity_Call_Unresolved,
      Overload_Ambiguity_Call_Ambiguous,
      Overload_Ambiguity_Call_Profile_Unavailable,
      Overload_Ambiguity_Call_Actual_Mismatch,
      Overload_Ambiguity_Call_Actual_Unknown,
      Overload_Ambiguity_Operator_Ambiguous,
      Overload_Ambiguity_Operator_Operand_Mismatch,
      Overload_Ambiguity_Operator_Operand_Unknown,
      Overload_Ambiguity_Operator_Result_Unknown,
      Overload_Ambiguity_Operator_Overload_Ambiguous,
      Overload_Ambiguity_Operator_Overload_Mismatch,
      Overload_Ambiguity_Operator_Overload_Unknown,
      Overload_Ambiguity_Universal_Numeric_Mismatch,
      Overload_Ambiguity_Universal_Numeric_Range_Error,
      Overload_Ambiguity_Universal_Numeric_Unknown);

   type Overload_Ambiguity_Diagnostic is record
      Id          : Overload_Ambiguity_Diagnostic_Id := No_Overload_Ambiguity_Diagnostic;
      Expression  : Editor.Ada_Expression_Types.Expression_Type_Id :=
        Editor.Ada_Expression_Types.No_Expression_Type;
      Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind        : Overload_Ambiguity_Kind := Overload_Ambiguity_No_Kind;
      Severity    : Overload_Ambiguity_Severity := Overload_Ambiguity_Warning;
      Message     : Ada.Strings.Unbounded.Unbounded_String;
      Detail      : Ada.Strings.Unbounded.Unbounded_String;
      Candidate_Count : Natural := 0;
      Selected_Count  : Natural := 0;
      Compatible_Count : Natural := 0;
      Mismatch_Count   : Natural := 0;
      Unknown_Count    : Natural := 0;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
      Source_Fingerprint : Natural := 0;
      Fingerprint  : Natural := 0;
   end record;

   type Overload_Ambiguity_Result_Set is private;
   type Overload_Ambiguity_Model is private;

   procedure Clear (Model : in out Overload_Ambiguity_Model);

   function Build
     (Expressions : Editor.Ada_Expression_Types.Expression_Type_Model)
      return Overload_Ambiguity_Model;

   function Diagnostic_Count (Model : Overload_Ambiguity_Model) return Natural;
   function Diagnostic_At
     (Model : Overload_Ambiguity_Model;
      Index : Positive) return Overload_Ambiguity_Diagnostic;

   function Error_Count (Model : Overload_Ambiguity_Model) return Natural;
   function Warning_Count (Model : Overload_Ambiguity_Model) return Natural;
   function Info_Count (Model : Overload_Ambiguity_Model) return Natural;

   function Call_Cause_Count (Model : Overload_Ambiguity_Model) return Natural;
   function Operator_Cause_Count (Model : Overload_Ambiguity_Model) return Natural;
   function Universal_Numeric_Cause_Count (Model : Overload_Ambiguity_Model) return Natural;
   function Candidate_Rejection_Count (Model : Overload_Ambiguity_Model) return Natural;
   function Ambiguous_Cause_Count (Model : Overload_Ambiguity_Model) return Natural;
   function Mismatch_Cause_Count (Model : Overload_Ambiguity_Model) return Natural;
   function Unknown_Cause_Count (Model : Overload_Ambiguity_Model) return Natural;

   function Count_Kind
     (Model : Overload_Ambiguity_Model;
      Kind  : Overload_Ambiguity_Kind) return Natural;

   function First_For_Node
     (Model : Overload_Ambiguity_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Overload_Ambiguity_Diagnostic;

   function Diagnostics_For_Node
     (Model : Overload_Ambiguity_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Overload_Ambiguity_Result_Set;

   function Result_Count (Results : Overload_Ambiguity_Result_Set) return Natural;
   function Result_At
     (Results : Overload_Ambiguity_Result_Set;
      Index   : Positive) return Overload_Ambiguity_Diagnostic;

   function Has_Diagnostic (Diagnostic : Overload_Ambiguity_Diagnostic) return Boolean;
   function Fingerprint (Model : Overload_Ambiguity_Model) return Natural;

private
   package Diagnostic_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Overload_Ambiguity_Diagnostic);

   type Overload_Ambiguity_Result_Set is record
      Diagnostics : Diagnostic_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Overload_Ambiguity_Model is record
      Diagnostics          : Diagnostic_Vectors.Vector;
      Error_Total          : Natural := 0;
      Warning_Total        : Natural := 0;
      Info_Total           : Natural := 0;
      Call_Total           : Natural := 0;
      Operator_Total       : Natural := 0;
      Universal_Total      : Natural := 0;
      Candidate_Rejection_Total : Natural := 0;
      Ambiguous_Total      : Natural := 0;
      Mismatch_Total       : Natural := 0;
      Unknown_Total        : Natural := 0;
      Result_Fingerprint   : Natural := 0;
   end record;

end Editor.Ada_Overload_Ambiguity_Diagnostics;
