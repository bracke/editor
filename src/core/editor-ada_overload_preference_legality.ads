with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Overload_Resolution_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Overload_Preference_Legality is

   --  Pass1126 Ada overload preference legality.
   --
   --  This package deepens overload resolution after the broad Pass1109
   --  legality layer by applying Ada-specific preference evidence in a
   --  deterministic, snapshot-owned model.  It does not parse, invoke a
   --  compiler, touch buffers, mutate editor state, or project UI state.  The
   --  model consumes already-built overload legality rows and optional
   --  preference-context evidence extracted by semantic consumers.

   type Preference_Context_Id is new Natural;
   No_Preference_Context : constant Preference_Context_Id := 0;

   type Preference_Legality_Id is new Natural;
   No_Preference_Legality : constant Preference_Legality_Id := 0;

   type Preference_Context_Kind is
     (Preference_Context_Call,
      Preference_Context_Operator,
      Preference_Context_Dispatching_Call,
      Preference_Context_Attribute_Call,
      Preference_Context_Generic_Actual_Subprogram,
      Preference_Context_Unknown);

   type Preference_Legality_Status is
     (Preference_Legality_Not_Checked,
      Preference_Legality_Legal_Exact_Profile,
      Preference_Legality_Legal_Direct_Visibility_Preferred,
      Preference_Legality_Legal_Use_Visibility_Preferred,
      Preference_Legality_Legal_Expected_Type_Profile_Preferred,
      Preference_Legality_Legal_Primitive_Operator_Preferred,
      Preference_Legality_Legal_Dispatching_Primitive_Preferred,
      Preference_Legality_Legal_Universal_Integer_Preferred,
      Preference_Legality_Legal_Universal_Real_Preferred,
      Preference_Legality_Legal_Implicit_Conversion_Preferred,
      Preference_Legality_Legal_Class_Wide_Preferred,
      Preference_Legality_Legal_Access_Conversion_Preferred,
      Preference_Legality_Legal_Named_Actual_Profile_Preferred,
      Preference_Legality_Legal_Defaulted_Formal_Profile_Preferred,
      Preference_Legality_Ambiguous_Homograph_Tie,
      Preference_Legality_Ambiguous_Visibility_Tie,
      Preference_Legality_Ambiguous_Profile_Tie,
      Preference_Legality_Ambiguous_Expected_Type_Tie,
      Preference_Legality_Ambiguous_Universal_Numeric_Tie,
      Preference_Legality_Ambiguous_Conversion_Tie,
      Preference_Legality_Ambiguous_After_RM_Preferences,
      Preference_Legality_No_Legal_Overload_Input,
      Preference_Legality_Linked_Overload_Legality_Error,
      Preference_Legality_Unknown,
      Preference_Legality_Indeterminate);

   type Preference_Context_Info is record
      Id       : Preference_Context_Id := No_Preference_Context;
      Kind     : Preference_Context_Kind := Preference_Context_Unknown;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Designator : Ada.Strings.Unbounded.Unbounded_String;
      Direct_Visibility_Count : Natural := 0;
      Use_Visibility_Count : Natural := 0;
      Selected_Profile_Count : Natural := 0;
      Exact_Profile_Count : Natural := 0;
      Expected_Type_Profile_Count : Natural := 0;
      Primitive_Operator_Count : Natural := 0;
      Dispatching_Primitive_Count : Natural := 0;
      Universal_Integer_Count : Natural := 0;
      Universal_Real_Count : Natural := 0;
      Implicit_Conversion_Count : Natural := 0;
      Class_Wide_Count : Natural := 0;
      Access_Conversion_Count : Natural := 0;
      Named_Actual_Count : Natural := 0;
      Defaulted_Formal_Count : Natural := 0;
      Homograph_Tie_Count : Natural := 0;
      Visibility_Tie_Count : Natural := 0;
      Profile_Tie_Count : Natural := 0;
      Expected_Type_Tie_Count : Natural := 0;
      Universal_Numeric_Tie_Count : Natural := 0;
      Conversion_Tie_Count : Natural := 0;
      Remaining_Ambiguous_Count : Natural := 0;
      Legal_Candidate_Count : Natural := 0;
      Rejected_Candidate_Count : Natural := 0;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
      Source_Fingerprint : Natural := 0;
   end record;

   type Preference_Legality_Info is record
      Id       : Preference_Legality_Id := No_Preference_Legality;
      Context  : Preference_Context_Id := No_Preference_Context;
      Kind     : Preference_Context_Kind := Preference_Context_Unknown;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status   : Preference_Legality_Status := Preference_Legality_Not_Checked;
      Designator : Ada.Strings.Unbounded.Unbounded_String;
      Message  : Ada.Strings.Unbounded.Unbounded_String;
      Detail   : Ada.Strings.Unbounded.Unbounded_String;
      Linked_Overload : Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Id :=
        Editor.Ada_Overload_Resolution_Legality.No_Overload_Legality;
      Linked_Overload_Status : Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Status :=
        Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Not_Checked;
      Legal_Candidate_Count : Natural := 0;
      Selected_Candidate_Count : Natural := 0;
      Rejected_Candidate_Count : Natural := 0;
      Ambiguous_Candidate_Count : Natural := 0;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
      Source_Fingerprint : Natural := 0;
      Overload_Fingerprint : Natural := 0;
      Fingerprint : Natural := 0;
   end record;

   type Preference_Context_Model is private;
   type Preference_Legality_Result_Set is private;
   type Preference_Legality_Model is private;

   procedure Clear (Model : in out Preference_Context_Model);
   procedure Add_Context
     (Model : in out Preference_Context_Model;
      Info  : Preference_Context_Info);

   function Context_Count (Model : Preference_Context_Model) return Natural;
   function Context_At
     (Model : Preference_Context_Model;
      Index : Positive) return Preference_Context_Info;
   function Fingerprint (Model : Preference_Context_Model) return Natural;

   function Build
     (Overloads : Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Model;
      Contexts  : Preference_Context_Model) return Preference_Legality_Model;

   function Build_Contexts_From_Overload_Legality
     (Overloads : Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Model)
      return Preference_Context_Model;

   function Legality_Count (Model : Preference_Legality_Model) return Natural;
   function Legality_At
     (Model : Preference_Legality_Model;
      Index : Positive) return Preference_Legality_Info;
   function First_For_Node
     (Model : Preference_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Preference_Legality_Info;
   function Rows_For_Status
     (Model  : Preference_Legality_Model;
      Status : Preference_Legality_Status) return Preference_Legality_Result_Set;
   function Rows_For_Kind
     (Model : Preference_Legality_Model;
      Kind  : Preference_Context_Kind) return Preference_Legality_Result_Set;
   function Rows_For_Designator
     (Model      : Preference_Legality_Model;
      Designator : String) return Preference_Legality_Result_Set;

   function Result_Count (Results : Preference_Legality_Result_Set) return Natural;
   function Result_At
     (Results : Preference_Legality_Result_Set;
      Index   : Positive) return Preference_Legality_Info;

   function Count_Status
     (Model  : Preference_Legality_Model;
      Status : Preference_Legality_Status) return Natural;
   function Count_Kind
     (Model : Preference_Legality_Model;
      Kind  : Preference_Context_Kind) return Natural;

   function Legal_Count (Model : Preference_Legality_Model) return Natural;
   function Ambiguous_Count (Model : Preference_Legality_Model) return Natural;
   function Linked_Overload_Error_Count (Model : Preference_Legality_Model) return Natural;
   function Indeterminate_Count (Model : Preference_Legality_Model) return Natural;
   function Fingerprint (Model : Preference_Legality_Model) return Natural;

   function Has_Legality (Info : Preference_Legality_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Preference_Context_Info);
   package Legality_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Preference_Legality_Info);

   type Preference_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Preference_Legality_Result_Set is record
      Items : Legality_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Preference_Legality_Model is record
      Items : Legality_Vectors.Vector;
      Legal_Total : Natural := 0;
      Ambiguous_Total : Natural := 0;
      Linked_Error_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Overload_Preference_Legality;
