with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Direct_Visibility;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Call_And_Operator_Overload_Resolution_Legality is

   --  Case 1297 concrete vertical-slice overload resolution for call and
   --  operator contexts.  Unlike the earlier closure/projection layers, this
   --  package performs direct Ada overload mechanics over concrete candidate
   --  rows: designator matching, visibility filtering, arity/defaulted-formal
   --  checks, actual/formal type compatibility, expected result filtering,
   --  universal numeric handling, primitive operator preference,
   --  access-to-subprogram profile selection, generic formal subprogram
   --  calls, ambiguity detection, and deterministic no-candidate diagnostics.
   --  The model is snapshot-owned and does not parse in the renderer, perform
   --  file IO, invoke a compiler, or mutate editor state.

   type Overload_Context_Id is new Natural;
   No_Overload_Context : constant Overload_Context_Id := 0;

   type Candidate_Id is new Natural;
   No_Candidate : constant Candidate_Id := 0;

   type Resolution_Id is new Natural;
   No_Resolution : constant Resolution_Id := 0;

   type Context_Kind is
     (Context_Call,
      Context_Operator,
      Context_Generic_Actual_Subprogram,
      Context_Access_To_Subprogram_Call,
      Context_Dispatching_Call,
      Context_Unknown);

   type Resolution_Status is
     (Resolution_Not_Checked,
      Resolution_Legal_Exact,
      Resolution_Legal_Expected_Result,
      Resolution_Legal_Universal_Integer,
      Resolution_Legal_Universal_Real,
      Resolution_Legal_Primitive_Operator,
      Resolution_Legal_Implicit_Numeric,
      Resolution_Legal_Access_Profile,
      Resolution_Legal_Class_Wide_Result,
      Resolution_Legal_Generic_Formal_Subprogram,
      Resolution_No_Candidate,
      Resolution_No_Visible_Candidate,
      Resolution_Arity_Mismatch,
      Resolution_Actual_Type_Mismatch,
      Resolution_Ambiguous,
      Resolution_Private_View_Barrier,
      Resolution_Limited_View_Barrier,
      Resolution_Cross_Unit_Blocker,
      Resolution_Indeterminate);

   type Context_Info is record
      Id       : Overload_Context_Id := No_Overload_Context;
      Kind     : Context_Kind := Context_Unknown;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Designator : Ada.Strings.Unbounded.Unbounded_String;
      --  Pipe-separated actual expression types, for example
      --  "Integer|universal_integer".  Empty means no actuals.
      Actual_Profile : Ada.Strings.Unbounded.Unbounded_String;
      Expected_Result_Type : Ada.Strings.Unbounded.Unbounded_String;
      Region_Source_Fingerprint : Natural := 0;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
      Source_Fingerprint : Natural := 0;
   end record;

   type Candidate_Info is record
      Id       : Candidate_Id := No_Candidate;
      Context  : Overload_Context_Id := No_Overload_Context;
      Declaration : Editor.Ada_Direct_Visibility.Declaration_Id :=
        Editor.Ada_Direct_Visibility.No_Declaration;
      Designator : Ada.Strings.Unbounded.Unbounded_String;
      --  Pipe-separated formal profile.  Empty means null profile.
      Formal_Profile : Ada.Strings.Unbounded.Unbounded_String;
      Result_Type    : Ada.Strings.Unbounded.Unbounded_String;
      Required_Actual_Count : Natural := 0;
      Formal_Count : Natural := 0;
      Is_Visible : Boolean := True;
      Is_Primitive_Operator : Boolean := False;
      Is_Use_Type_Primitive : Boolean := False;
      Is_Generic_Formal_Subprogram : Boolean := False;
      Is_Access_To_Subprogram : Boolean := False;
      Has_Class_Wide_Result : Boolean := False;
      Private_View_Barrier : Boolean := False;
      Limited_View_Barrier : Boolean := False;
      Cross_Unit_Blocker : Boolean := False;
      Candidate_Fingerprint : Natural := 0;
   end record;

   type Resolution_Info is record
      Id       : Resolution_Id := No_Resolution;
      Context  : Overload_Context_Id := No_Overload_Context;
      Kind     : Context_Kind := Context_Unknown;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status   : Resolution_Status := Resolution_Not_Checked;
      Selected_Candidate : Candidate_Id := No_Candidate;
      Selected_Declaration : Editor.Ada_Direct_Visibility.Declaration_Id :=
        Editor.Ada_Direct_Visibility.No_Declaration;
      Candidate_Count : Natural := 0;
      Visible_Candidate_Count : Natural := 0;
      Arity_Compatible_Count : Natural := 0;
      Type_Compatible_Count : Natural := 0;
      Expected_Result_Match_Count : Natural := 0;
      Universal_Integer_Match_Count : Natural := 0;
      Universal_Real_Match_Count : Natural := 0;
      Primitive_Operator_Count : Natural := 0;
      Access_Profile_Count : Natural := 0;
      Generic_Formal_Subprogram_Count : Natural := 0;
      Rejected_Count : Natural := 0;
      Best_Score : Natural := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Detail  : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint : Natural := 0;
      Candidate_Fingerprint : Natural := 0;
      Fingerprint : Natural := 0;
   end record;

   type Context_Model is private;
   type Candidate_Model is private;
   type Resolution_Model is private;

   procedure Clear (Model : in out Context_Model);
   procedure Clear (Model : in out Candidate_Model);

   procedure Add_Context
     (Model : in out Context_Model;
      Info  : Context_Info);

   procedure Add_Candidate
     (Model : in out Candidate_Model;
      Info  : Candidate_Info);

   function Build
     (Contexts   : Context_Model;
      Candidates : Candidate_Model) return Resolution_Model;

   function Context_Count (Model : Context_Model) return Natural;
   function Candidate_Count (Model : Candidate_Model) return Natural;
   function Resolution_Count (Model : Resolution_Model) return Natural;

   function Resolution_At
     (Model : Resolution_Model;
      Index : Positive) return Resolution_Info;

   function First_For_Node
     (Model : Resolution_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Resolution_Info;

   function Count_Status
     (Model  : Resolution_Model;
      Status : Resolution_Status) return Natural;

   function Legal_Count (Model : Resolution_Model) return Natural;
   function Error_Count (Model : Resolution_Model) return Natural;
   function Ambiguous_Count (Model : Resolution_Model) return Natural;
   function Fingerprint (Model : Resolution_Model) return Natural;

   function Has_Resolution (Info : Resolution_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Context_Info);
   package Candidate_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Candidate_Info);
   package Resolution_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Resolution_Info);

   type Context_Model is record
      Items : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Candidate_Model is record
      Items : Candidate_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Resolution_Model is record
      Items : Resolution_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Ambiguous_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Call_And_Operator_Overload_Resolution_Legality;
