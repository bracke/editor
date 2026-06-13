with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Accessibility_Scope_Graph_Legality;
with Editor.Ada_Elaboration_Dependence_Legality;
with Editor.Ada_Elaboration_Graph_Closure_Legality;
with Editor.Ada_Elaboration_Precision_Legality;
with Editor.Ada_Flow_Effect_Graph_Legality;
with Editor.Ada_Generic_Instance_Body_Semantic_Replay;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

package body Test_Ada_Elaboration_Graph_Closure_Legality_Pass1144 is

   package G renames Editor.Ada_Elaboration_Graph_Closure_Legality;
   use type G.Elaboration_Graph_Edge_Id;
   use type G.Elaboration_Graph_Context_Kind;
   use type G.Elaboration_Graph_Closure_Status;
   use type G.Elaboration_Graph_Context_Info;
   use type G.Elaboration_Graph_Closure_Info;
   use type G.Elaboration_Graph_Context_Model;
   use type G.Elaboration_Graph_Result_Set;
   use type G.Elaboration_Graph_Closure_Model;
   package Base renames Editor.Ada_Elaboration_Dependence_Legality;
   use type Base.Cross_Unit_Semantic_Status;
   use type Base.Contract_Legality_Status;
   use type Base.Overload_Legality_Status;
   use type Base.Elaboration_Context_Id;
   use type Base.Elaboration_Legality_Id;
   use type Base.Elaboration_Context_Kind;
   use type Base.Elaboration_Dependence_Kind;
   use type Base.Elaboration_Pragma_State;
   use type Base.Elaboration_Order_State;
   use type Base.Elaboration_Policy_State;
   use type Base.Elaboration_Legality_Status;
   use type Base.Elaboration_Context_Info;
   use type Base.Elaboration_Legality_Info;
   use type Base.Elaboration_Context_Model;
   use type Base.Elaboration_Result_Set;
   use type Base.Elaboration_Legality_Model;
   package Precision renames Editor.Ada_Elaboration_Precision_Legality;
   use type Precision.Elaboration_Legality_Status;
   use type Precision.Elaboration_Order_State;
   use type Precision.Elaboration_Policy_State;
   use type Precision.Dataflow_Legality_Status;
   use type Precision.Generic_Body_Expansion_Status;
   use type Precision.Preference_Legality_Status;
   use type Precision.Accessibility_Precision_Status;
   use type Precision.Elaboration_Precision_Context_Id;
   use type Precision.Elaboration_Precision_Legality_Id;
   use type Precision.Elaboration_Precision_Context_Kind;
   use type Precision.Elaboration_Precision_Status;
   use type Precision.Elaboration_Precision_Context_Info;
   use type Precision.Elaboration_Precision_Legality_Info;
   use type Precision.Elaboration_Precision_Context_Model;
   use type Precision.Elaboration_Precision_Result_Set;
   use type Precision.Elaboration_Precision_Legality_Model;
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
   package Flow renames Editor.Ada_Flow_Effect_Graph_Legality;
   use type Flow.Flow_Edge_Id;
   use type Flow.Flow_Graph_Context_Kind;
   use type Flow.Flow_Edge_Kind;
   use type Flow.Flow_Effect_Graph_Status;
   use type Flow.Flow_Effect_Context_Info;
   use type Flow.Flow_Effect_Info;
   use type Flow.Flow_Effect_Context_Model;
   use type Flow.Flow_Effect_Set;
   use type Flow.Flow_Effect_Graph_Model;
   package Scope renames Editor.Ada_Accessibility_Scope_Graph_Legality;
   use type Scope.Scope_Context_Id;
   use type Scope.Scope_Legality_Id;
   use type Scope.Scope_Level;
   use type Scope.Scope_Context_Kind;
   use type Scope.Scope_Legality_Status;
   use type Scope.Scope_Context_Info;
   use type Scope.Scope_Legality_Info;
   use type Scope.Scope_Context_Model;
   use type Scope.Scope_Result_Set;
   use type Scope.Scope_Legality_Model;
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
      return AUnit.Format ("Test_Ada_Elaboration_Graph_Closure_Legality_Pass1144");
   end Name;

   function Sample_Contexts return G.Elaboration_Graph_Context_Model is
      Contexts : G.Elaboration_Graph_Context_Model;
      C        : G.Elaboration_Graph_Context_Info;
   begin
      C.Id := 1;
      C.Kind := G.Graph_Context_Library_With_Edge;
      C.Dependence := Base.Elaboration_Dependence_With;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114401);
      C.Source_Unit_Name := To_Unbounded_String ("App.Main");
      C.Target_Unit_Name := To_Unbounded_String ("Pkg.Spec");
      C.Order_State := Base.Elaboration_Order_Known_Before;
      C.Requires_Elaborate_All := True;
      C.Has_Transitive_Elaborate_All := True;
      C.Edge_Depth := 2;
      C.Source_Fingerprint := 1_144_001;
      G.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := G.Graph_Context_Indirect_Call_Edge;
      C.Dependence := Base.Elaboration_Dependence_Subprogram_Call;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114402);
      C.Source_Unit_Name := To_Unbounded_String ("App.Main");
      C.Target_Unit_Name := To_Unbounded_String ("Pkg.Body_Info");
      C.Order_State := Base.Elaboration_Order_Known_Before;
      C.Indirect_Call := True;
      C.Body_Elaborated_Before_Use := True;
      C.Source_Fingerprint := 1_144_002;
      G.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := G.Graph_Context_Direct_Call_Edge;
      C.Dependence := Base.Elaboration_Dependence_Subprogram_Call;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114403);
      C.Source_Unit_Name := To_Unbounded_String ("App.Main");
      C.Target_Unit_Name := To_Unbounded_String ("Late.Body_Info");
      C.Order_State := Base.Elaboration_Order_Known_Before;
      C.Direct_Call := True;
      C.Body_Elaborated_Before_Use := False;
      C.Source_Fingerprint := 1_144_003;
      G.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := G.Graph_Context_Library_With_Edge;
      C.Dependence := Base.Elaboration_Dependence_With;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114404);
      C.Source_Unit_Name := To_Unbounded_String ("App.Main");
      C.Target_Unit_Name := To_Unbounded_String ("Transitive.Missing");
      C.Order_State := Base.Elaboration_Order_Known_Before;
      C.Requires_Elaborate_All := True;
      C.Has_Transitive_Elaborate_All := False;
      C.Source_Fingerprint := 1_144_004;
      G.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := G.Graph_Context_Cycle_Path;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114405);
      C.Source_Unit_Name := To_Unbounded_String ("Cycle.A");
      C.Target_Unit_Name := To_Unbounded_String ("Cycle.B");
      C.Path_Text := To_Unbounded_String ("Cycle.A -> Cycle.B -> Cycle.A");
      C.Cycle_Detected := True;
      C.Order_State := Base.Elaboration_Order_Known_Before;
      C.Source_Fingerprint := 1_144_005;
      G.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := G.Graph_Context_Generic_Instance_Edge;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114406);
      C.Source_Unit_Name := To_Unbounded_String ("Inst.User");
      C.Target_Unit_Name := To_Unbounded_String ("Generic.Body_Info");
      C.Order_State := Base.Elaboration_Order_Known_Before;
      C.Generic_Instance := True;
      C.Generic_Body_Elaborated := False;
      C.Formal_Body_Resolved := True;
      C.Source_Fingerprint := 1_144_006;
      G.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := G.Graph_Context_Preelaborated_Unit;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114407);
      C.Source_Unit_Name := To_Unbounded_String ("Pre.Unit");
      C.Order_State := Base.Elaboration_Order_Known_Before;
      C.Policy_State := Base.Elaboration_Policy_Preelaborated;
      C.Illegal_Preelaborate_Effect := True;
      C.Source_Fingerprint := 1_144_007;
      G.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := G.Graph_Context_Default_Expression_Edge;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114408);
      C.Source_Unit_Name := To_Unbounded_String ("Default.User");
      C.Target_Unit_Name := To_Unbounded_String ("Default.Target");
      C.Order_State := Base.Elaboration_Order_Known_Before;
      C.Default_Expression_Edge := True;
      C.Flow_Status := Flow.Flow_Graph_Read_Not_In_Global;
      C.Source_Fingerprint := 1_144_008;
      G.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 9;
      C.Kind := G.Graph_Context_Access_Edge;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114409);
      C.Source_Unit_Name := To_Unbounded_String ("Access.User");
      C.Target_Unit_Name := To_Unbounded_String ("Access.Target");
      C.Order_State := Base.Elaboration_Order_Known_Before;
      C.Access_During_Elaboration := True;
      C.Scope_Status := Scope.Scope_Legality_Return_Access_Master_Too_Short;
      C.Source_Fingerprint := 1_144_009;
      G.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 10;
      C.Kind := G.Graph_Context_Generic_Instance_Edge;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114410);
      C.Source_Unit_Name := To_Unbounded_String ("Replay.User");
      C.Target_Unit_Name := To_Unbounded_String ("Replay.Target");
      C.Order_State := Base.Elaboration_Order_Known_Before;
      C.Generic_Instance := True;
      C.Replay_Status := Replay.Replay_Formal_Actual_Mapping_Missing;
      C.Source_Fingerprint := 1_144_010;
      G.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 11;
      C.Kind := G.Graph_Context_Aspect_Expression_Edge;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114411);
      C.Source_Unit_Name := To_Unbounded_String ("Aspect.User");
      C.Target_Unit_Name := To_Unbounded_String ("Aspect.Target");
      C.Order_State := Base.Elaboration_Order_Known_Before;
      C.Aspect_Expression_Edge := True;
      C.Precision_Status := Precision.Elaboration_Precision_Missing_Elaborate_All;
      C.Source_Fingerprint := 1_144_011;
      G.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 12;
      C.Kind := G.Graph_Context_Representation_Item_Edge;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114412);
      C.Source_Unit_Name := To_Unbounded_String ("Rep.User");
      C.Target_Unit_Name := To_Unbounded_String ("Rep.Target");
      C.Order_State := Base.Elaboration_Order_Known_Before;
      C.Representation_Item_Edge := True;
      C.Gate_Status := Gates.Enforcement_Metadata_Blocker;
      C.Source_Fingerprint := 1_144_012;
      G.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 13;
      C.Kind := G.Graph_Context_Use_Edge;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114413);
      C.Source_Unit_Name := To_Unbounded_String ("Unknown.User");
      C.Target_Unit_Name := To_Unbounded_String ("Unknown.Target");
      C.Order_State := Base.Elaboration_Order_Unknown;
      C.Source_Fingerprint := 1_144_013;
      G.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Contexts;

   procedure Test_Graph_Statuses (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : constant G.Elaboration_Graph_Context_Model := Sample_Contexts;
      Model    : constant G.Elaboration_Graph_Closure_Model := G.Build (Contexts);
   begin
      Assert (G.Context_Count (Contexts) = 13, "all elaboration graph contexts are recorded");
      Assert (G.Row_Count (Model) = 13, "all graph contexts produce closure rows");
      Assert (G.Count_Status (Model, G.Graph_Closure_Legal_Transitive_Elaborate_All) = 1,
              "transitive Elaborate_All success is preserved");
      Assert (G.Count_Status (Model, G.Graph_Closure_Legal_Indirect_Call_Order) = 1,
              "legal indirect call order is preserved");
      Assert (G.Count_Status (Model, G.Graph_Closure_Direct_Call_Before_Body) = 1,
              "direct call before body is detected");
      Assert (G.Count_Status (Model, G.Graph_Closure_Missing_Transitive_Elaborate_All) = 1,
              "missing transitive Elaborate_All is detected");
      Assert (G.Count_Status (Model, G.Graph_Closure_Circular_Library_Elaboration) = 1,
              "cycle path is preserved as circular elaboration");
      Assert (G.Count_Status (Model, G.Graph_Closure_Generic_Instance_Body_Not_Elaborated) = 1,
              "generic instance body elaboration error is detected");
      Assert (G.Count_Status (Model, G.Graph_Closure_Preelaboration_Illegal_Effect) = 1,
              "preelaboration illegal effect is detected");
      Assert (G.Count_Status (Model, G.Graph_Closure_Flow_Effect_Blocker) = 1,
              "flow-effect blockers participate in elaboration graph closure");
      Assert (G.Count_Status (Model, G.Graph_Closure_Accessibility_Scope_Blocker) = 1,
              "accessibility scope blockers participate in elaboration graph closure");
      Assert (G.Count_Status (Model, G.Graph_Closure_Linked_Generic_Replay_Error) = 1,
              "generic replay blockers participate in elaboration graph closure");
      Assert (G.Count_Status (Model, G.Graph_Closure_Linked_Precision_Error) = 1,
              "precision blockers participate in graph closure");
      Assert (G.Count_Status (Model, G.Graph_Closure_Coverage_Gate_Blocker) = 1,
              "coverage gates block unsafe graph closure");
      Assert (G.Count_Status (Model, G.Graph_Closure_Indeterminate) = 1,
              "unknown elaboration order remains indeterminate");
   end Test_Graph_Statuses;

   procedure Test_Lookups_And_Counters (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant G.Elaboration_Graph_Closure_Model := G.Build (Sample_Contexts);
      Row   : constant G.Elaboration_Graph_Closure_Info :=
        G.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114403));
      Unit_Rows : constant G.Elaboration_Graph_Result_Set := G.Rows_For_Unit (Model, "app.main");
   begin
      Assert (G.Has_Legality (Row), "node lookup returns elaboration graph row");
      Assert (Row.Status = G.Graph_Closure_Direct_Call_Before_Body,
              "node lookup preserves graph status");
      Assert (G.Result_Count (Unit_Rows) >= 3, "case-insensitive unit lookup finds source rows");
      Assert (G.Transitive_Error_Count (Model) = 1, "transitive closure errors are counted");
      Assert (G.Body_Before_Use_Error_Count (Model) = 1, "body-before-use errors are counted");
      Assert (G.Call_Order_Error_Count (Model) = 1, "call order errors are counted");
      Assert (G.Generic_Error_Count (Model) = 2, "generic errors are counted");
      Assert (G.Cycle_Error_Count (Model) = 1, "cycle errors are counted");
      Assert (G.Policy_Error_Count (Model) = 1, "policy errors are counted");
      Assert (G.Linked_Error_Count (Model) = 4, "linked blockers are counted");
      Assert (G.Coverage_Gate_Error_Count (Model) = 1, "coverage gate blockers are counted");
      Assert (G.Indeterminate_Count (Model) = 1, "indeterminate rows are counted");
      Assert (G.Fingerprint (Model) /= 0, "model fingerprint is deterministic and non-zero");
   end Test_Lookups_And_Counters;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Graph_Statuses'Access,
                        "elaboration graph closure classifies transitive and linked blockers");
      Register_Routine (T, Test_Lookups_And_Counters'Access,
                        "elaboration graph closure exposes deterministic lookups and counters");
   end Register_Tests;

end Test_Ada_Elaboration_Graph_Closure_Legality_Pass1144;
