with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Accessibility_Precision_Legality;
with Editor.Ada_Accessibility_Scope_Graph_Legality;
with Editor.Ada_Discriminant_Dependent_Legality;
with Editor.Ada_Generic_Instance_Body_Semantic_Replay;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

package body Test_Ada_Accessibility_Scope_Graph_Legality is

   package S renames Editor.Ada_Accessibility_Scope_Graph_Legality;
   use type S.Scope_Context_Id;
   use type S.Scope_Legality_Id;
   use type S.Scope_Level;
   use type S.Scope_Context_Kind;
   use type S.Scope_Legality_Status;
   use type S.Scope_Context_Info;
   use type S.Scope_Legality_Info;
   use type S.Scope_Context_Model;
   use type S.Scope_Result_Set;
   use type S.Scope_Legality_Model;
   package Precision renames Editor.Ada_Accessibility_Precision_Legality;
   use type Precision.Accessibility_Legality_Status;
   use type Precision.Accessibility_Level;
   use type Precision.Access_Context_Kind;
   use type Precision.Record_Aggregate_Legality_Status;
   use type Precision.Generic_Body_Expansion_Status;
   use type Precision.Accessibility_Precision_Context_Id;
   use type Precision.Accessibility_Precision_Legality_Id;
   use type Precision.Accessibility_Precision_Context_Kind;
   use type Precision.Accessibility_Precision_Status;
   use type Precision.Accessibility_Precision_Context_Info;
   use type Precision.Accessibility_Precision_Legality_Info;
   use type Precision.Accessibility_Precision_Context_Model;
   use type Precision.Accessibility_Precision_Result_Set;
   use type Precision.Accessibility_Precision_Legality_Model;
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
   package Discriminants renames Editor.Ada_Discriminant_Dependent_Legality;
   use type Discriminants.Discriminant_Context_Id;
   use type Discriminants.Discriminant_Legality_Id;
   use type Discriminants.Discriminant_Context_Kind;
   use type Discriminants.Discriminant_Legality_Status;
   use type Discriminants.Discriminant_Context_Info;
   use type Discriminants.Discriminant_Legality_Info;
   use type Discriminants.Discriminant_Context_Model;
   use type Discriminants.Discriminant_Result_Set;
   use type Discriminants.Discriminant_Legality_Model;
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
      return AUnit.Format ("Test_Ada_Accessibility_Scope_Graph_Legality");
   end Name;

   function Sample_Contexts return S.Scope_Context_Model is
      Contexts : S.Scope_Context_Model;
      C        : S.Scope_Context_Info;
   begin
      C.Id := 1;
      C.Kind := S.Scope_Context_Master;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114301);
      C.Scope_Name := To_Unbounded_String ("Library");
      C.Has_Master := True;
      C.Master_Level := 1;
      C.Parent_Master_Level := 1;
      C.Source_Fingerprint := 1_143_001;
      S.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := S.Scope_Context_Anonymous_Access_Parameter;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114302);
      C.Object_Name := To_Unbounded_String ("P");
      C.Has_Master := True;
      C.Requires_Static_Level := True;
      C.Anonymous_Access_Parameter := True;
      C.Source_Level := 5;
      C.Target_Level := 2;
      C.Master_Level := 5;
      C.Required_Master_Level := 2;
      C.Source_Fingerprint := 1_143_002;
      S.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := S.Scope_Context_Access_Parameter_Escape;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114303);
      C.Object_Name := To_Unbounded_String ("Escaping_Param");
      C.Has_Master := True;
      C.Access_Parameter_Escapes := True;
      C.Source_Fingerprint := 1_143_003;
      S.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := S.Scope_Context_Allocator;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114304);
      C.Object_Name := To_Unbounded_String ("Heap_Item");
      C.Has_Master := True;
      C.Allocator_Context := True;
      C.Requires_Static_Level := True;
      C.Source_Level := 4;
      C.Target_Level := 2;
      C.Allocator_Master_Level := 4;
      C.Source_Fingerprint := 1_143_004;
      S.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := S.Scope_Context_Return_Object;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114305);
      C.Object_Name := To_Unbounded_String ("Result_Obj");
      C.Has_Master := True;
      C.Return_Context := True;
      C.Requires_Static_Level := True;
      C.Source_Level := 6;
      C.Target_Level := 2;
      C.Return_Master_Level := 6;
      C.Source_Fingerprint := 1_143_005;
      S.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := S.Scope_Context_Access_Discriminant;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114306);
      C.Object_Name := To_Unbounded_String ("D.Ref");
      C.Has_Master := True;
      C.Access_Discriminant_Context := True;
      C.Requires_Static_Level := True;
      C.Source_Level := 4;
      C.Target_Level := 1;
      C.Required_Master_Level := 1;
      C.Discriminant_Status := Discriminants.Discriminant_Legality_Legal_Aggregate_Discriminants;
      C.Source_Fingerprint := 1_143_006;
      S.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := S.Scope_Context_Generic_Substitution;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114307);
      C.Object_Name := To_Unbounded_String ("Actual_Access");
      C.Has_Master := True;
      C.Generic_Substitution_Context := True;
      C.Requires_Static_Level := True;
      C.Source_Level := 7;
      C.Target_Level := 3;
      C.Replay_Status := Replay.Replay_Legal_Accessibility;
      C.Source_Fingerprint := 1_143_007;
      S.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := S.Scope_Context_Discriminant_Aggregate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114308);
      C.Object_Name := To_Unbounded_String ("Aggregate.Ref");
      C.Has_Master := True;
      C.Discriminant_Aggregate_Context := True;
      C.Precision_Status := Precision.Accessibility_Precision_Aggregate_Discriminant_Lifetime_Error;
      C.Source_Fingerprint := 1_143_008;
      S.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 9;
      C.Kind := S.Scope_Context_Return_Access;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114309);
      C.Object_Name := To_Unbounded_String ("Access_Result");
      C.Has_Master := True;
      C.Return_Context := True;
      C.Requires_Static_Level := True;
      C.Source_Level := 1;
      C.Target_Level := 3;
      C.Return_Master_Level := 1;
      C.Source_Fingerprint := 1_143_009;
      S.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 10;
      C.Kind := S.Scope_Context_Allocator;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114310);
      C.Object_Name := To_Unbounded_String ("Blocked_Alloc");
      C.Has_Master := True;
      C.Allocator_Context := True;
      C.Gate_Status := Gates.Enforcement_Metadata_Blocker;
      C.Source_Fingerprint := 1_143_010;
      S.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 11;
      C.Kind := S.Scope_Context_Finalization_Master;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114311);
      C.Object_Name := To_Unbounded_String ("Controlled_Obj");
      C.Has_Master := True;
      C.Finalization_Context := True;
      C.Master_Level := 2;
      C.Finalization_Uses_Expired_Master := True;
      C.Source_Fingerprint := 1_143_011;
      S.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Contexts;

   procedure Test_Scope_Graph_Statuses (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : constant S.Scope_Context_Model := Sample_Contexts;
      Model    : constant S.Scope_Legality_Model := S.Build (Contexts);
   begin
      Assert (S.Context_Count (Contexts) = 11, "all scope contexts were recorded");
      Assert (S.Row_Count (Model) = 11, "all scope contexts produced rows");
      Assert (S.Count_Status (Model, S.Scope_Legality_Legal_Master_Hierarchy) = 1,
              "master hierarchy legal row is preserved");
      Assert (S.Count_Status (Model, S.Scope_Legality_Anonymous_Access_Level_Too_Deep) = 1,
              "anonymous access too-deep level is detected");
      Assert (S.Count_Status (Model, S.Scope_Legality_Access_Parameter_Escapes) = 1,
              "access parameter escape is detected");
      Assert (S.Count_Status (Model, S.Scope_Legality_Allocator_Master_Too_Short) = 1,
              "allocator master too-short condition is detected");
      Assert (S.Count_Status (Model, S.Scope_Legality_Return_Object_Master_Too_Short) = 1,
              "return object master too-short condition is detected");
      Assert (S.Count_Status (Model, S.Scope_Legality_Access_Discriminant_Master_Too_Short) = 1,
              "access discriminant master condition is detected");
      Assert (S.Count_Status (Model, S.Scope_Legality_Generic_Substitution_Master_Mismatch) = 1,
              "generic substitution master mismatch is detected");
      Assert (S.Count_Status (Model, S.Scope_Legality_Linked_Accessibility_Precision_Error) = 1,
              "linked accessibility precision blockers are preserved");
      Assert (S.Count_Status (Model, S.Scope_Legality_Legal_Return_Access_Master) = 1,
              "compatible return access master remains legal");
      Assert (S.Count_Status (Model, S.Scope_Legality_Coverage_Gate_Blocker) = 1,
              "coverage gates block unsafe scope conclusions");
      Assert (S.Count_Status (Model, S.Scope_Legality_Finalization_Uses_Expired_Master) = 1,
              "expired finalization master is detected");
   end Test_Scope_Graph_Statuses;

   procedure Test_Lookups_And_Counters (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant S.Scope_Legality_Model := S.Build (Sample_Contexts);
      Row   : constant S.Scope_Legality_Info :=
        S.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114302));
      Objects : constant S.Scope_Result_Set := S.Rows_For_Object (Model, "heap_item");
   begin
      Assert (S.Has_Legality (Row), "node lookup returns scope legality");
      Assert (Row.Status = S.Scope_Legality_Anonymous_Access_Level_Too_Deep,
              "node lookup preserves row status");
      Assert (S.Result_Count (Objects) = 1, "case-insensitive object lookup works");
      Assert (S.Master_Error_Count (Model) >= 1, "master errors are counted");
      Assert (S.Return_Error_Count (Model) = 1, "return errors are counted");
      Assert (S.Allocator_Error_Count (Model) = 1, "allocator errors are counted");
      Assert (S.Access_Discriminant_Error_Count (Model) = 1, "access discriminant errors are counted");
      Assert (S.Generic_Error_Count (Model) = 1, "generic substitution errors are counted");
      Assert (S.Linked_Error_Count (Model) = 1, "linked errors are counted");
      Assert (S.Coverage_Gate_Error_Count (Model) = 1, "coverage-gate errors are counted");
      Assert (S.Fingerprint (Model) /= 0, "model fingerprint is deterministic and non-zero");
   end Test_Lookups_And_Counters;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Scope_Graph_Statuses'Access, "scope graph classifies lifetime contexts");
      Register_Routine (T, Test_Lookups_And_Counters'Access, "scope graph exposes deterministic lookups and counters");
   end Register_Tests;

end Test_Ada_Accessibility_Scope_Graph_Legality;
