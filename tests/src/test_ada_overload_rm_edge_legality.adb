with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Generic_Instance_Body_Semantic_Replay;
with Editor.Ada_Overload_Preference_Legality;
with Editor.Ada_Overload_RM_Edge_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

package body Test_Ada_Overload_RM_Edge_Legality is

   package RM_Edges renames Editor.Ada_Overload_RM_Edge_Legality;
   use type RM_Edges.RM_Edge_Context_Id;
   use type RM_Edges.RM_Edge_Legality_Id;
   use type RM_Edges.RM_Edge_Context_Kind;
   use type RM_Edges.RM_Edge_Legality_Status;
   use type RM_Edges.RM_Edge_Context_Info;
   use type RM_Edges.RM_Edge_Legality_Info;
   use type RM_Edges.RM_Edge_Context_Model;
   use type RM_Edges.RM_Edge_Result_Set;
   use type RM_Edges.RM_Edge_Legality_Model;
   package Preference renames Editor.Ada_Overload_Preference_Legality;
   use type Preference.Preference_Context_Id;
   use type Preference.Preference_Legality_Id;
   use type Preference.Preference_Context_Kind;
   use type Preference.Preference_Legality_Status;
   use type Preference.Preference_Context_Info;
   use type Preference.Preference_Legality_Info;
   use type Preference.Preference_Context_Model;
   use type Preference.Preference_Legality_Result_Set;
   use type Preference.Preference_Legality_Model;
   package Replay renames Editor.Ada_Generic_Instance_Body_Semantic_Replay;
   use type Replay.Replay_Context_Id;
   use type Replay.Replay_Row_Id;
   use type Replay.Replay_Context_Kind;
   use type Replay.Replay_Status;
   use type Replay.Replay_Context_Info;
   use type Replay.Replay_Info;
   use type Replay.Replay_Context_Model;
   use type Replay.Replay_Result_Set;
   use type Replay.Replay_Model;
   package Gates renames Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;
   use type Gates.Enforcement_Row_Id;
   use type Gates.Widened_Legality_Engine;
   use type Gates.Enforcement_Status;
   use type Gates.Enforcement_Context_Info;
   use type Gates.Enforcement_Info;
   use type Gates.Enforcement_Context_Model;
   use type Gates.Enforcement_Set;
   use type Gates.Enforcement_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Overload_RM_Edge_Legality");
   end Name;

   function Sample_Contexts return RM_Edges.RM_Edge_Context_Model is
      Contexts : RM_Edges.RM_Edge_Context_Model;
      C        : RM_Edges.RM_Edge_Context_Info;
   begin
      C.Id := 1;
      C.Kind := RM_Edges.RM_Edge_Context_Universal_Numeric;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114101);
      C.Designator := To_Unbounded_String ("+");
      C.Universal_Integer_Count := 1;
      C.Linked_Preference_Status := Preference.Preference_Legality_Legal_Universal_Integer_Preferred;
      C.Source_Fingerprint := 1_141;
      RM_Edges.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := RM_Edges.RM_Edge_Context_Universal_Fixed;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114102);
      C.Designator := To_Unbounded_String ("Scale");
      C.Universal_Fixed_Count := 2;
      C.Ambiguous_Candidate_Count := 2;
      C.Linked_Preference_Status := Preference.Preference_Legality_Legal_Exact_Profile;
      C.Source_Fingerprint := 1_142;
      RM_Edges.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := RM_Edges.RM_Edge_Context_Root_Numeric;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114103);
      C.Designator := To_Unbounded_String ("Root_Op");
      C.Root_Numeric_Count := 1;
      C.Linked_Preference_Status := Preference.Preference_Legality_Legal_Expected_Type_Profile_Preferred;
      C.Source_Fingerprint := 1_143;
      RM_Edges.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := RM_Edges.RM_Edge_Context_Inherited_Primitive;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114104);
      C.Designator := To_Unbounded_String ("Prim");
      C.Inherited_Primitive_Count := 1;
      C.Visible_Homograph_Count := 1;
      C.Ambiguous_Candidate_Count := 2;
      C.Source_Fingerprint := 1_144;
      RM_Edges.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := RM_Edges.RM_Edge_Context_Homograph_Hiding;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114105);
      C.Designator := To_Unbounded_String ("Hidden_Prim");
      C.Hidden_Homograph_Count := 1;
      C.Source_Fingerprint := 1_145;
      RM_Edges.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := RM_Edges.RM_Edge_Context_Dispatching_Call;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114106);
      C.Designator := To_Unbounded_String ("Dispatch");
      C.Dispatching_Candidate_Count := 1;
      C.Linked_Preference_Status := Preference.Preference_Legality_Legal_Dispatching_Primitive_Preferred;
      C.Source_Fingerprint := 1_146;
      RM_Edges.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := RM_Edges.RM_Edge_Context_Dispatching_Call;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114107);
      C.Designator := To_Unbounded_String ("Dispatch_Tie");
      C.Dispatching_Candidate_Count := 1;
      C.Nondispatching_Candidate_Count := 1;
      C.Ambiguous_Candidate_Count := 2;
      C.Source_Fingerprint := 1_147;
      RM_Edges.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := RM_Edges.RM_Edge_Context_Access_To_Subprogram;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114108);
      C.Designator := To_Unbounded_String ("Access_Call");
      C.Access_Subprogram_Profile_Count := 1;
      C.Source_Fingerprint := 1_148;
      RM_Edges.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 9;
      C.Kind := RM_Edges.RM_Edge_Context_Access_To_Subprogram;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114109);
      C.Designator := To_Unbounded_String ("Access_Mode");
      C.Access_Subprogram_Profile_Count := 1;
      C.Access_Subprogram_Mode_Mismatch_Count := 1;
      C.Source_Fingerprint := 1_149;
      RM_Edges.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 10;
      C.Kind := RM_Edges.RM_Edge_Context_Nested_Generic_Call;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114110);
      C.Designator := To_Unbounded_String ("Nested");
      C.Nested_Generic_Defaulted_Formal_Tie_Count := 1;
      C.Source_Fingerprint := 1_150;
      RM_Edges.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 11;
      C.Kind := RM_Edges.RM_Edge_Context_Generic_Formal_Subprogram;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114111);
      C.Designator := To_Unbounded_String ("Formal_Op");
      C.Generic_Formal_Subprogram_Count := 1;
      C.Linked_Replay_Status := Replay.Replay_Legal_Call;
      C.Source_Fingerprint := 1_151;
      RM_Edges.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 12;
      C.Kind := RM_Edges.RM_Edge_Context_Nested_Generic_Call;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114112);
      C.Designator := To_Unbounded_String ("Generic_Error");
      C.Generic_Formal_Subprogram_Count := 1;
      C.Linked_Replay_Status := Replay.Replay_Overload_Preference_Error;
      C.Source_Fingerprint := 1_152;
      RM_Edges.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 13;
      C.Kind := RM_Edges.RM_Edge_Context_Universal_Numeric;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114113);
      C.Designator := To_Unbounded_String ("Gate_Error");
      C.Universal_Real_Count := 1;
      C.Gate_Status := Gates.Enforcement_Parser_AST_Blocker;
      C.Source_Fingerprint := 1_153;
      RM_Edges.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 14;
      C.Kind := RM_Edges.RM_Edge_Context_Universal_Numeric;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114114);
      C.Designator := To_Unbounded_String ("Multi_Error");
      C.Universal_Integer_Count := 1;
      C.Linked_Preference_Status := Preference.Preference_Legality_Ambiguous_After_RM_Preferences;
      C.Gate_Status := Gates.Enforcement_Metadata_Blocker;
      C.Source_Fingerprint := 1_154;
      RM_Edges.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Contexts;

   procedure Edge_Cases_Are_Classified_With_Blockers_Preserved
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : constant RM_Edges.RM_Edge_Legality_Model :=
        RM_Edges.Build (Sample_Contexts);
      Universal_Int : constant RM_Edges.RM_Edge_Legality_Info :=
        RM_Edges.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114101));
      Fixed_Tie : constant RM_Edges.RM_Edge_Legality_Info :=
        RM_Edges.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114102));
      Root_Num : constant RM_Edges.RM_Edge_Legality_Info :=
        RM_Edges.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114103));
      Hidden_Tie : constant RM_Edges.RM_Edge_Legality_Info :=
        RM_Edges.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114104));
      Hidden_Legal : constant RM_Edges.RM_Edge_Legality_Info :=
        RM_Edges.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114105));
      Dispatch_Legal : constant RM_Edges.RM_Edge_Legality_Info :=
        RM_Edges.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114106));
      Dispatch_Tie : constant RM_Edges.RM_Edge_Legality_Info :=
        RM_Edges.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114107));
      Access_Legal : constant RM_Edges.RM_Edge_Legality_Info :=
        RM_Edges.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114108));
      Access_Mode : constant RM_Edges.RM_Edge_Legality_Info :=
        RM_Edges.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114109));
      Nested_Default : constant RM_Edges.RM_Edge_Legality_Info :=
        RM_Edges.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114110));
      Formal_Legal : constant RM_Edges.RM_Edge_Legality_Info :=
        RM_Edges.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114111));
      Replay_Error : constant RM_Edges.RM_Edge_Legality_Info :=
        RM_Edges.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114112));
      Gate_Error : constant RM_Edges.RM_Edge_Legality_Info :=
        RM_Edges.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114113));
      Multi_Error : constant RM_Edges.RM_Edge_Legality_Info :=
        RM_Edges.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114114));
   begin
      Assert (RM_Edges.Row_Count (Model) = 14,
              "all RM overload edge contexts should be analyzed");
      Assert (Universal_Int.Status = RM_Edges.RM_Edge_Legality_Legal_Universal_Integer,
              "universal integer edge should be legal");
      Assert (Fixed_Tie.Status = RM_Edges.RM_Edge_Legality_Universal_Fixed_Ambiguous,
              "universal fixed tie should remain explicit");
      Assert (Root_Num.Status = RM_Edges.RM_Edge_Legality_Legal_Root_Numeric_Preferred,
              "root numeric preference should be legal when unique");
      Assert (Hidden_Tie.Status = RM_Edges.RM_Edge_Legality_Inherited_Primitive_Hiding_Ambiguous,
              "inherited primitive hiding ambiguity should be preserved");
      Assert (Hidden_Legal.Status = RM_Edges.RM_Edge_Legality_Legal_Homograph_Hidden,
              "hidden homographs should be excluded before selection");
      Assert (Dispatch_Legal.Status = RM_Edges.RM_Edge_Legality_Legal_Dispatching_Selected,
              "single dispatching candidate should be selected");
      Assert (Dispatch_Tie.Status = RM_Edges.RM_Edge_Legality_Dispatching_Nondispatching_Ambiguous,
              "dispatching and nondispatching ties should remain blockers");
      Assert (Access_Legal.Status = RM_Edges.RM_Edge_Legality_Legal_Access_Subprogram_Profile,
              "access-to-subprogram profile should be checked");
      Assert (Access_Mode.Status = RM_Edges.RM_Edge_Legality_Access_Subprogram_Mode_Mismatch,
              "access-to-subprogram mode mismatch should block selection");
      Assert (Nested_Default.Status = RM_Edges.RM_Edge_Legality_Nested_Generic_Defaulted_Formal_Ambiguous,
              "nested generic defaulted formal ambiguity should be explicit");
      Assert (Formal_Legal.Status = RM_Edges.RM_Edge_Legality_Legal_Generic_Formal_Subprogram,
              "generic formal subprogram edge should be legal when unique");
      Assert (Replay_Error.Status = RM_Edges.RM_Edge_Legality_Linked_Generic_Replay_Error,
              "generic replay errors should block overload edge refinement");
      Assert (Gate_Error.Status = RM_Edges.RM_Edge_Legality_Coverage_Gate_Blocker,
              "coverage gates should block confident overload edge legality");
      Assert (Multi_Error.Status = RM_Edges.RM_Edge_Legality_Multiple_Blockers,
              "multiple blockers should not be collapsed");
      Assert (RM_Edges.Legal_Count (Model) = 6,
              "six rows should remain legal");
      Assert (RM_Edges.Ambiguous_Count (Model) = 4,
              "four overload edge ambiguities should be counted");
      Assert (RM_Edges.Generic_Replay_Error_Count (Model) = 1,
              "generic replay blocker should be counted");
      Assert (RM_Edges.Coverage_Gate_Error_Count (Model) = 1,
              "coverage blocker should be counted");
      Assert (RM_Edges.Multiple_Blocker_Count (Model) = 1,
              "multiple blocker should be counted");
      Assert (RM_Edges.Result_Count (RM_Edges.Rows_For_Designator (Model, "access_call")) = 1,
              "designator lookup should be case-insensitive");
      Assert (RM_Edges.Fingerprint (Model) /= 0,
              "RM overload edge model should have a deterministic fingerprint");
   end Edge_Cases_Are_Classified_With_Blockers_Preserved;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Edge_Cases_Are_Classified_With_Blockers_Preserved'Access,
         "RM overload edge legality classifies universal, dispatching, access, generic, and gate cases");
   end Register_Tests;

end Test_Ada_Overload_RM_Edge_Legality;
