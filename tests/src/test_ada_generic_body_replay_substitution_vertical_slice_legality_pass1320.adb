with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Generic_Body_Replay_Substitution_Vertical_Slice_Legality;

package body Test_Ada_Generic_Body_Replay_Substitution_Vertical_Slice_Legality_Pass1320 is

   package GR renames Editor.Ada_Generic_Body_Replay_Substitution_Vertical_Slice_Legality;
   use type GR.Instance_Id;
   use type GR.Event_Id;
   use type GR.Result_Id;
   use type GR.Replay_Event_Kind;
   use type GR.View_Kind;
   use type GR.Legality_Status;
   use type GR.Replay_Context_Info;
   use type GR.Replay_Event_Info;
   use type GR.Result_Info;
   use type GR.Context_Model;
   use type GR.Event_Model;
   use type GR.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Generic_Body_Replay_Substitution_Vertical_Slice_Legality_Pass1320");
   end Name;

   procedure Add_Context
     (Model : in out GR.Context_Model;
      Id : Natural;
      Generic_Name : String;
      Instance_Name : String;
      Has_Body : Boolean := True;
      Has_Bindings : Boolean := True;
      Has_Backmapping : Boolean := True;
      View : GR.View_Kind := GR.View_Full;
      Allows_Private : Boolean := True;
      Allows_Limited : Boolean := True;
      Nested_Depth : Natural := 0;
      Max_Depth : Natural := 32;
      Cycle : Boolean := False;
      Source_FP : Natural := 132000;
      Subst_FP : Natural := 232000;
      Backmap_FP : Natural := 332000;
      Expected_Source_FP : Natural := 0;
      Expected_Subst_FP : Natural := 0;
      Expected_Backmap_FP : Natural := 0)
   is
      C : GR.Replay_Context_Info;
   begin
      C.Instance := GR.Instance_Id (Id);
      C.Generic_Name := To_Unbounded_String (Generic_Name);
      C.Instance_Name := To_Unbounded_String (Instance_Name);
      C.Body_Node := Editor.Ada_Syntax_Tree.Node_Id (132000 + Id);
      C.Has_Generic_Body := Has_Body;
      C.Has_Formal_Actual_Bindings := Has_Bindings;
      C.Has_Source_Backmapping := Has_Backmapping;
      C.View := View;
      C.Allows_Private_View := Allows_Private;
      C.Allows_Limited_View := Allows_Limited;
      C.Nested_Depth := Nested_Depth;
      C.Max_Nested_Depth := Max_Depth;
      C.Nested_Cycle := Cycle;
      C.Source_Fingerprint := Source_FP + Id;
      C.Substitution_Fingerprint := Subst_FP + Id;
      C.Backmapping_Fingerprint := Backmap_FP + Id;
      C.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      C.Expected_Substitution_Fingerprint :=
        (if Expected_Subst_FP = 0 then Subst_FP + Id else Expected_Subst_FP);
      C.Expected_Backmapping_Fingerprint :=
        (if Expected_Backmap_FP = 0 then Backmap_FP + Id else Expected_Backmap_FP);
      GR.Add_Context (Model, C);
   end Add_Context;

   procedure Add_Event
     (Model : in out GR.Event_Model;
      Id : Natural;
      Instance : Natural;
      Kind : GR.Replay_Event_Kind;
      Text : String;
      Formal_Profile : String := "";
      Actual_Profile : String := "";
      Formal_Type : String := "";
      Actual_Type : String := "";
      Runtime_Check : Boolean := False;
      Overload_OK : Boolean := True;
      Type_OK : Boolean := True;
      Visibility_OK : Boolean := True;
      Freezing_OK : Boolean := True;
      Representation_OK : Boolean := True;
      Accessibility_OK : Boolean := True;
      Predicate_OK : Boolean := True;
      Dataflow_OK : Boolean := True;
      Shared_State_OK : Boolean := True;
      Source_FP : Natural := 432000;
      Subst_FP : Natural := 532000;
      Backmap_FP : Natural := 632000;
      Expected_Source_FP : Natural := 0;
      Expected_Subst_FP : Natural := 0;
      Expected_Backmap_FP : Natural := 0)
   is
      E : GR.Replay_Event_Info;
   begin
      E.Id := GR.Event_Id (Id);
      E.Instance := GR.Instance_Id (Instance);
      E.Node := Editor.Ada_Syntax_Tree.Node_Id (232000 + Id);
      E.Kind := Kind;
      E.Source_Text := To_Unbounded_String (Text);
      E.Formal_Profile := To_Unbounded_String (Formal_Profile);
      E.Actual_Profile := To_Unbounded_String (Actual_Profile);
      E.Formal_Type := To_Unbounded_String (Formal_Type);
      E.Actual_Type := To_Unbounded_String (Actual_Type);
      E.Requires_Runtime_Check := Runtime_Check;
      E.Overload_Resolved := Overload_OK;
      E.Type_Substitution_Valid := Type_OK;
      E.Visibility_Valid := Visibility_OK;
      E.Freezing_Valid := Freezing_OK;
      E.Representation_Valid := Representation_OK;
      E.Accessibility_Valid := Accessibility_OK;
      E.Predicate_Valid := Predicate_OK;
      E.Dataflow_Valid := Dataflow_OK;
      E.Shared_State_Valid := Shared_State_OK;
      E.Source_Fingerprint := Source_FP + Id;
      E.Substitution_Fingerprint := Subst_FP + Id;
      E.Backmapping_Fingerprint := Backmap_FP + Id;
      E.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      E.Expected_Substitution_Fingerprint :=
        (if Expected_Subst_FP = 0 then Subst_FP + Id else Expected_Subst_FP);
      E.Expected_Backmapping_Fingerprint :=
        (if Expected_Backmap_FP = 0 then Backmap_FP + Id else Expected_Backmap_FP);
      GR.Add_Event (Model, E);
   end Add_Event;

   procedure Replays_Source_Shaped_Generic_Body_Events
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : GR.Context_Model;
      Events : GR.Event_Model;
      Results : GR.Result_Model;
   begin
      Add_Context (Contexts, 1, "Generic_Stack", "Int_Stack");
      Add_Event (Events, 1, 1, GR.Event_Call, "Push (S, X)",
                 Formal_Profile => "procedure(Stack; Element)",
                 Actual_Profile => "procedure(Stack; Element)");
      Add_Event (Events, 2, 1, GR.Event_Object_Declaration, "Tmp : Element := X",
                 Formal_Type => "Element", Actual_Type => "Element");
      Add_Event (Events, 3, 1, GR.Event_Nested_Instantiation, "package Inner is new Helper (Element)",
                 Formal_Type => "Element", Actual_Type => "Element");
      Add_Event (Events, 4, 1, GR.Event_Predicate_Aspect, "Predicate => Is_Valid (X)",
                 Formal_Type => "Boolean", Actual_Type => "Boolean", Runtime_Check => True);

      Results := GR.Build (Contexts, Events);
      Assert (GR.Result_Count (Results) = 4, "four replay events expected");
      Assert (GR.Legal_Count (Results) = 4, "all replay events should be legal");
      Assert (GR.Count_Status (Results, GR.Legality_Legal_Nested_Replay) = 1,
              "nested generic instantiation should replay when fresh and acyclic");
      Assert (GR.Count_Status (Results, GR.Legality_Legal_Runtime_Check) = 1,
              "runtime predicate checks remain legal replay evidence");
   end Replays_Source_Shaped_Generic_Body_Events;

   procedure Rejects_Missing_Body_Backmapping_And_View_Barriers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : GR.Context_Model;
      Events : GR.Event_Model;
      Results : GR.Result_Model;
   begin
      Add_Context (Contexts, 1, "Missing_Body", "I1", Has_Body => False);
      Add_Event (Events, 1, 1, GR.Event_Call, "P (X)");

      Add_Context (Contexts, 2, "No_Map", "I2", Has_Backmapping => False);
      Add_Event (Events, 2, 2, GR.Event_Call, "Q (Y)");

      Add_Context (Contexts, 3, "Private_View", "I3", View => GR.View_Private,
                   Allows_Private => False);
      Add_Event (Events, 3, 3, GR.Event_Type_Declaration, "T'Class use in body");

      Add_Context (Contexts, 4, "Limited_View", "I4", View => GR.View_Limited,
                   Allows_Limited => False);
      Add_Event (Events, 4, 4, GR.Event_Renaming, "Obj renames Actual.Obj");

      Results := GR.Build (Contexts, Events);
      Assert (GR.Count_Status (Results, GR.Legality_Missing_Generic_Body) = 1,
              "missing generic body must block replay");
      Assert (GR.Count_Status (Results, GR.Legality_Missing_Source_Backmapping) = 1,
              "missing source-to-instance backmapping must block replay");
      Assert (GR.Count_Status (Results, GR.Legality_Private_View_Barrier) = 1,
              "private view barrier must be preserved");
      Assert (GR.Count_Status (Results, GR.Legality_Limited_View_Barrier) = 1,
              "limited view barrier must be preserved");
   end Rejects_Missing_Body_Backmapping_And_View_Barriers;

   procedure Rejects_Replayed_Body_Semantic_Mismatches
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : GR.Context_Model;
      Events : GR.Event_Model;
      Results : GR.Result_Model;
   begin
      Add_Context (Contexts, 1, "Generic_Calls", "I1");
      Add_Event (Events, 1, 1, GR.Event_Call, "F (X)", Overload_OK => False);
      Add_Event (Events, 2, 1, GR.Event_Object_Declaration, "Y : Element := X",
                 Formal_Type => "Element", Actual_Type => "Other_Element");
      Add_Event (Events, 3, 1, GR.Event_Representation_Clause, "for T'Size use N",
                 Freezing_OK => False, Representation_OK => False);
      Add_Event (Events, 4, 1, GR.Event_Dataflow_Use, "Global => (In_Out => State)",
                 Dataflow_OK => False, Shared_State_OK => False);

      Results := GR.Build (Contexts, Events);
      Assert (GR.Count_Status (Results, GR.Legality_Overload_Blocker) = 1,
              "unresolved replayed call must remain an overload blocker");
      Assert (GR.Count_Status (Results, GR.Legality_Type_Substitution_Mismatch) = 1,
              "formal/actual type mismatch must block body replay");
      Assert (GR.Count_Status (Results, GR.Legality_Multiple_Blockers) >= 2,
              "representation/freezing and dataflow/shared-state blockers should be preserved as multiple blockers");
   end Rejects_Replayed_Body_Semantic_Mismatches;

   procedure Rejects_Nested_Cycles_Depth_And_Stale_Fingerprints
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : GR.Context_Model;
      Events : GR.Event_Model;
      Results : GR.Result_Model;
   begin
      Add_Context (Contexts, 1, "Cycle", "I1", Cycle => True);
      Add_Event (Events, 1, 1, GR.Event_Nested_Instantiation, "new Cycle (T)");

      Add_Context (Contexts, 2, "Deep", "I2", Nested_Depth => 9, Max_Depth => 3);
      Add_Event (Events, 2, 2, GR.Event_Nested_Instantiation, "new Deep (T)");

      Add_Context (Contexts, 3, "Stale_Substitution", "I3", Expected_Subst_FP => 99);
      Add_Event (Events, 3, 3, GR.Event_Call, "P (X)");

      Add_Context (Contexts, 4, "Stale_Backmap", "I4", Expected_Backmap_FP => 77);
      Add_Event (Events, 4, 4, GR.Event_Call, "Q (X)");

      Results := GR.Build (Contexts, Events);
      Assert (GR.Count_Status (Results, GR.Legality_Nested_Instance_Cycle) = 1,
              "nested instantiation cycle must be rejected");
      Assert (GR.Count_Status (Results, GR.Legality_Dependency_Depth_Overflow) = 1,
              "bounded replay depth overflow must be rejected");
      Assert (GR.Count_Status (Results, GR.Legality_Substitution_Fingerprint_Mismatch) = 1,
              "stale substitution fingerprint must block replay");
      Assert (GR.Count_Status (Results, GR.Legality_Backmapping_Fingerprint_Mismatch) = 1,
              "stale source-to-instance backmapping must block replay");
   end Rejects_Nested_Cycles_Depth_And_Stale_Fingerprints;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Replays_Source_Shaped_Generic_Body_Events'Access,
                        "replays source-shaped generic body events under actual substitution");
      Register_Routine (T, Rejects_Missing_Body_Backmapping_And_View_Barriers'Access,
                        "rejects missing body/backmapping and private/limited view barriers");
      Register_Routine (T, Rejects_Replayed_Body_Semantic_Mismatches'Access,
                        "rejects overload, type, representation, dataflow, and shared-state mismatches");
      Register_Routine (T, Rejects_Nested_Cycles_Depth_And_Stale_Fingerprints'Access,
                        "rejects nested replay cycles, depth overflow, and stale fingerprints");
   end Register_Tests;

end Test_Ada_Generic_Body_Replay_Substitution_Vertical_Slice_Legality_Pass1320;
