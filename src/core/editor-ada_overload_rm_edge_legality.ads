with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Generic_Instance_Body_Semantic_Replay;
with Editor.Ada_Overload_Preference_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

package Editor.Ada_Overload_RM_Edge_Legality is

   --  Pass1141 RM-grade overload edge legality.
   --
   --  This package deepens overload resolution in the remaining Ada RM edge
   --  cases after the broad Pass1109 resolver and Pass1126 preference layer.
   --  It is snapshot-owned and deterministic: it consumes already-computed
   --  overload preference, generic replay, and coverage-gate evidence, and it
   --  never reparses, calls a compiler, or mutates editor/render/workspace state.

   type RM_Edge_Context_Id is new Natural;
   No_RM_Edge_Context : constant RM_Edge_Context_Id := 0;

   type RM_Edge_Legality_Id is new Natural;
   No_RM_Edge_Legality : constant RM_Edge_Legality_Id := 0;

   type RM_Edge_Context_Kind is
     (RM_Edge_Context_Universal_Numeric,
      RM_Edge_Context_Universal_Fixed,
      RM_Edge_Context_Root_Numeric,
      RM_Edge_Context_Inherited_Primitive,
      RM_Edge_Context_Homograph_Hiding,
      RM_Edge_Context_Dispatching_Call,
      RM_Edge_Context_Nondispatching_Call,
      RM_Edge_Context_Access_To_Subprogram,
      RM_Edge_Context_Generic_Formal_Subprogram,
      RM_Edge_Context_Nested_Generic_Call,
      RM_Edge_Context_Unknown);

   type RM_Edge_Legality_Status is
     (RM_Edge_Legality_Not_Checked,
      RM_Edge_Legality_Legal_Universal_Integer,
      RM_Edge_Legality_Legal_Universal_Real,
      RM_Edge_Legality_Legal_Universal_Fixed,
      RM_Edge_Legality_Legal_Root_Numeric_Preferred,
      RM_Edge_Legality_Legal_Inherited_Primitive_Visible,
      RM_Edge_Legality_Legal_Homograph_Hidden,
      RM_Edge_Legality_Legal_Dispatching_Selected,
      RM_Edge_Legality_Legal_Nondispatching_Selected,
      RM_Edge_Legality_Legal_Access_Subprogram_Profile,
      RM_Edge_Legality_Legal_Generic_Formal_Subprogram,
      RM_Edge_Legality_Legal_Nested_Generic_Selected,
      RM_Edge_Legality_Universal_Fixed_Ambiguous,
      RM_Edge_Legality_Root_Numeric_Ambiguous,
      RM_Edge_Legality_Inherited_Primitive_Hiding_Ambiguous,
      RM_Edge_Legality_Homograph_Hiding_Error,
      RM_Edge_Legality_Dispatching_Nondispatching_Ambiguous,
      RM_Edge_Legality_Access_Subprogram_Profile_Mismatch,
      RM_Edge_Legality_Access_Subprogram_Mode_Mismatch,
      RM_Edge_Legality_Access_Subprogram_Result_Mismatch,
      RM_Edge_Legality_Generic_Formal_Subprogram_Ambiguous,
      RM_Edge_Legality_Nested_Generic_Defaulted_Formal_Ambiguous,
      RM_Edge_Legality_Nested_Generic_Named_Actual_Ambiguous,
      RM_Edge_Legality_Linked_Preference_Error,
      RM_Edge_Legality_Linked_Generic_Replay_Error,
      RM_Edge_Legality_Coverage_Gate_Blocker,
      RM_Edge_Legality_Multiple_Blockers,
      RM_Edge_Legality_Unknown,
      RM_Edge_Legality_Indeterminate);

   type RM_Edge_Context_Info is record
      Id       : RM_Edge_Context_Id := No_RM_Edge_Context;
      Kind     : RM_Edge_Context_Kind := RM_Edge_Context_Unknown;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Designator : Ada.Strings.Unbounded.Unbounded_String;
      Universal_Integer_Count : Natural := 0;
      Universal_Real_Count : Natural := 0;
      Universal_Fixed_Count : Natural := 0;
      Root_Numeric_Count : Natural := 0;
      Inherited_Primitive_Count : Natural := 0;
      Hidden_Homograph_Count : Natural := 0;
      Visible_Homograph_Count : Natural := 0;
      Dispatching_Candidate_Count : Natural := 0;
      Nondispatching_Candidate_Count : Natural := 0;
      Access_Subprogram_Profile_Count : Natural := 0;
      Access_Subprogram_Mode_Mismatch_Count : Natural := 0;
      Access_Subprogram_Result_Mismatch_Count : Natural := 0;
      Generic_Formal_Subprogram_Count : Natural := 0;
      Nested_Generic_Defaulted_Formal_Tie_Count : Natural := 0;
      Nested_Generic_Named_Actual_Tie_Count : Natural := 0;
      Ambiguous_Candidate_Count : Natural := 0;
      Linked_Preference : Editor.Ada_Overload_Preference_Legality.Preference_Legality_Id :=
        Editor.Ada_Overload_Preference_Legality.No_Preference_Legality;
      Linked_Preference_Status : Editor.Ada_Overload_Preference_Legality.Preference_Legality_Status :=
        Editor.Ada_Overload_Preference_Legality.Preference_Legality_Not_Checked;
      Linked_Replay : Editor.Ada_Generic_Instance_Body_Semantic_Replay.Replay_Row_Id :=
        Editor.Ada_Generic_Instance_Body_Semantic_Replay.No_Replay_Row;
      Linked_Replay_Status : Editor.Ada_Generic_Instance_Body_Semantic_Replay.Replay_Status :=
        Editor.Ada_Generic_Instance_Body_Semantic_Replay.Replay_Not_Checked;
      Gate_Status : Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement.Enforcement_Status :=
        Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement.Enforcement_Not_Checked;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
      Source_Fingerprint : Natural := 0;
   end record;

   type RM_Edge_Legality_Info is record
      Id       : RM_Edge_Legality_Id := No_RM_Edge_Legality;
      Context  : RM_Edge_Context_Id := No_RM_Edge_Context;
      Kind     : RM_Edge_Context_Kind := RM_Edge_Context_Unknown;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status   : RM_Edge_Legality_Status := RM_Edge_Legality_Not_Checked;
      Designator : Ada.Strings.Unbounded.Unbounded_String;
      Message  : Ada.Strings.Unbounded.Unbounded_String;
      Detail   : Ada.Strings.Unbounded.Unbounded_String;
      Linked_Preference_Status : Editor.Ada_Overload_Preference_Legality.Preference_Legality_Status :=
        Editor.Ada_Overload_Preference_Legality.Preference_Legality_Not_Checked;
      Linked_Replay_Status : Editor.Ada_Generic_Instance_Body_Semantic_Replay.Replay_Status :=
        Editor.Ada_Generic_Instance_Body_Semantic_Replay.Replay_Not_Checked;
      Gate_Status : Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement.Enforcement_Status :=
        Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement.Enforcement_Not_Checked;
      Selected_Candidate_Count : Natural := 0;
      Ambiguous_Candidate_Count : Natural := 0;
      Blocker_Count : Natural := 0;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
      Source_Fingerprint : Natural := 0;
      Fingerprint : Natural := 0;
   end record;

   type RM_Edge_Context_Model is private;
   type RM_Edge_Result_Set is private;
   type RM_Edge_Legality_Model is private;

   procedure Clear (Model : in out RM_Edge_Context_Model);
   procedure Add_Context
     (Model : in out RM_Edge_Context_Model;
      Info  : RM_Edge_Context_Info);

   function Context_Count (Model : RM_Edge_Context_Model) return Natural;
   function Context_At
     (Model : RM_Edge_Context_Model;
      Index : Positive) return RM_Edge_Context_Info;
   function Fingerprint (Model : RM_Edge_Context_Model) return Natural;

   function Build (Contexts : RM_Edge_Context_Model) return RM_Edge_Legality_Model;

   function Row_Count (Model : RM_Edge_Legality_Model) return Natural;
   function Row_At
     (Model : RM_Edge_Legality_Model;
      Index : Positive) return RM_Edge_Legality_Info;
   function First_For_Node
     (Model : RM_Edge_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return RM_Edge_Legality_Info;
   function Rows_For_Status
     (Model  : RM_Edge_Legality_Model;
      Status : RM_Edge_Legality_Status) return RM_Edge_Result_Set;
   function Rows_For_Kind
     (Model : RM_Edge_Legality_Model;
      Kind  : RM_Edge_Context_Kind) return RM_Edge_Result_Set;
   function Rows_For_Designator
     (Model      : RM_Edge_Legality_Model;
      Designator : String) return RM_Edge_Result_Set;

   function Result_Count (Results : RM_Edge_Result_Set) return Natural;
   function Result_At
     (Results : RM_Edge_Result_Set;
      Index   : Positive) return RM_Edge_Legality_Info;

   function Count_Status
     (Model  : RM_Edge_Legality_Model;
      Status : RM_Edge_Legality_Status) return Natural;
   function Count_Kind
     (Model : RM_Edge_Legality_Model;
      Kind  : RM_Edge_Context_Kind) return Natural;

   function Legal_Count (Model : RM_Edge_Legality_Model) return Natural;
   function Ambiguous_Count (Model : RM_Edge_Legality_Model) return Natural;
   function Preference_Error_Count (Model : RM_Edge_Legality_Model) return Natural;
   function Generic_Replay_Error_Count (Model : RM_Edge_Legality_Model) return Natural;
   function Coverage_Gate_Error_Count (Model : RM_Edge_Legality_Model) return Natural;
   function Multiple_Blocker_Count (Model : RM_Edge_Legality_Model) return Natural;
   function Indeterminate_Count (Model : RM_Edge_Legality_Model) return Natural;
   function Fingerprint (Model : RM_Edge_Legality_Model) return Natural;

   function Has_Legality (Info : RM_Edge_Legality_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => RM_Edge_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => RM_Edge_Legality_Info);

   type RM_Edge_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type RM_Edge_Result_Set is record
      Items : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type RM_Edge_Legality_Model is record
      Items : Row_Vectors.Vector;
      Legal_Total : Natural := 0;
      Ambiguous_Total : Natural := 0;
      Preference_Error_Total : Natural := 0;
      Generic_Replay_Error_Total : Natural := 0;
      Coverage_Gate_Error_Total : Natural := 0;
      Multiple_Blocker_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Overload_RM_Edge_Legality;
