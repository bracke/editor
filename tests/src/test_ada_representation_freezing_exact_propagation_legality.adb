with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Accessibility_Scope_Graph_Legality;
with Editor.Ada_Discriminant_Dependent_Legality;
with Editor.Ada_Elaboration_Graph_Closure_Legality;
with Editor.Ada_Flow_Effect_Graph_Legality;
with Editor.Ada_Generic_Instance_Body_Semantic_Replay;
with Editor.Ada_Predicate_Invariant_Propagation_Legality;
with Editor.Ada_Representation_Freezing_Exact_Propagation_Legality;
with Editor.Ada_Representation_Freezing_Precision_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Protected_Effects_Legality;
with Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

package body Test_Ada_Representation_Freezing_Exact_Propagation_Legality is

   package E renames Editor.Ada_Representation_Freezing_Exact_Propagation_Legality;
   use type E.Freezing_Propagation_Id;
   use type E.Freezing_Propagation_Context_Kind;
   use type E.Freezing_Propagation_Status;
   use type E.Freezing_Propagation_Context_Info;
   use type E.Freezing_Propagation_Info;
   use type E.Freezing_Propagation_Context_Model;
   use type E.Freezing_Propagation_Model;
   use type E.Freezing_Propagation_Set;
   package Precision renames Editor.Ada_Representation_Freezing_Precision_Legality;
   use type Precision.Freezing_Status;
   use type Precision.Representation_Status;
   use type Precision.Representation_Integration_Status;
   use type Precision.Generic_Instance_Status;
   use type Precision.Elaboration_Precision_Status;
   use type Precision.Tasking_Precision_Status;
   use type Precision.Representation_Freezing_Precision_Context_Id;
   use type Precision.Representation_Freezing_Precision_Id;
   use type Precision.Representation_Freezing_Precision_Context_Kind;
   use type Precision.Freezing_Cause_Kind;
   use type Precision.Representation_Freezing_Precision_Status;
   use type Precision.Representation_Freezing_Precision_Context_Info;
   use type Precision.Representation_Freezing_Precision_Info;
   use type Precision.Representation_Freezing_Precision_Context_Model;
   use type Precision.Representation_Freezing_Precision_Result_Set;
   use type Precision.Representation_Freezing_Precision_Model;
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
   package Disc renames Editor.Ada_Discriminant_Dependent_Legality;
   use type Disc.Discriminant_Context_Id;
   use type Disc.Discriminant_Legality_Id;
   use type Disc.Discriminant_Context_Kind;
   use type Disc.Discriminant_Legality_Status;
   use type Disc.Discriminant_Context_Info;
   use type Disc.Discriminant_Legality_Info;
   use type Disc.Discriminant_Context_Model;
   use type Disc.Discriminant_Result_Set;
   use type Disc.Discriminant_Legality_Model;
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
   package Pred renames Editor.Ada_Predicate_Invariant_Propagation_Legality;
   use type Pred.Propagation_Row_Id;
   use type Pred.Propagation_Context_Kind;
   use type Pred.Propagation_Obligation_Kind;
   use type Pred.Propagation_Status;
   use type Pred.Propagation_Context_Info;
   use type Pred.Propagation_Info;
   use type Pred.Propagation_Context_Model;
   use type Pred.Propagation_Set;
   use type Pred.Propagation_Model;
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
   package Elab renames Editor.Ada_Elaboration_Graph_Closure_Legality;
   use type Elab.Elaboration_Graph_Edge_Id;
   use type Elab.Elaboration_Graph_Context_Kind;
   use type Elab.Elaboration_Graph_Closure_Status;
   use type Elab.Elaboration_Graph_Context_Info;
   use type Elab.Elaboration_Graph_Closure_Info;
   use type Elab.Elaboration_Graph_Context_Model;
   use type Elab.Elaboration_Graph_Result_Set;
   use type Elab.Elaboration_Graph_Closure_Model;
   package Tasking renames Editor.Ada_Tasking_Protected_Effects_Legality;
   use type Tasking.Tasking_Effect_Id;
   use type Tasking.Tasking_Effect_Context_Kind;
   use type Tasking.Tasking_Effect_Status;
   use type Tasking.Tasking_Effect_Context_Info;
   use type Tasking.Tasking_Effect_Info;
   use type Tasking.Tasking_Effect_Context_Model;
   use type Tasking.Tasking_Effect_Set;
   use type Tasking.Tasking_Effect_Model;
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
      return AUnit.Format ("Test_Ada_Representation_Freezing_Exact_Propagation_Legality");
   end Name;

   function Sample_Contexts return E.Freezing_Propagation_Context_Model is
      Contexts : E.Freezing_Propagation_Context_Model;
      C        : E.Freezing_Propagation_Context_Info;
   begin
      C.Id := 1;
      C.Kind := E.Freezing_Propagation_Context_Expression_Use;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114601);
      C.Target_Name := To_Unbounded_String ("T");
      C.Implicit_Use_Freezes := True;
      C.Source_Fingerprint := 1_146_001;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := E.Freezing_Propagation_Context_Representation_Clause;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114602);
      C.Target_Name := To_Unbounded_String ("T");
      C.Representation_Item := True;
      C.Source_Fingerprint := 1_146_002;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := E.Freezing_Propagation_Context_Representation_Clause;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114603);
      C.Target_Name := To_Unbounded_String ("T");
      C.Representation_After_Implicit_Use := True;
      C.Source_Fingerprint := 1_146_003;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := E.Freezing_Propagation_Context_Generic_Instance;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114604);
      C.Target_Name := To_Unbounded_String ("G.T");
      C.Representation_After_Generic_Instance := True;
      C.Source_Fingerprint := 1_146_004;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := E.Freezing_Propagation_Context_Generic_Body_Replay;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114605);
      C.Target_Name := To_Unbounded_String ("Inst.T");
      C.Representation_After_Generic_Body_Replay := True;
      C.Source_Fingerprint := 1_146_005;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := E.Freezing_Propagation_Context_Discriminant_Constraint;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114606);
      C.Target_Name := To_Unbounded_String ("Rec");
      C.Component_Name := To_Unbounded_String ("D");
      C.Discriminant_Representation := True;
      C.Discriminant_Status := Disc.Discriminant_Legality_Missing_Discriminant_Constraint;
      C.Source_Fingerprint := 1_146_006;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := E.Freezing_Propagation_Context_Variant_Representation;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114607);
      C.Target_Name := To_Unbounded_String ("Rec");
      C.Variant_Representation := True;
      C.Discriminant_Status := Disc.Discriminant_Legality_Variant_Choice_Overlap;
      C.Source_Fingerprint := 1_146_007;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := E.Freezing_Propagation_Context_Finalization_Effect;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114608);
      C.Target_Name := To_Unbounded_String ("Ctrl");
      C.Operational_Finalization_Effect := True;
      C.Tasking_Status := Tasking.Tasking_Effect_Task_Termination_Finalization_Error;
      C.Source_Fingerprint := 1_146_008;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 9;
      C.Kind := E.Freezing_Propagation_Context_Stream_Attribute;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114609);
      C.Target_Name := To_Unbounded_String ("Streamed");
      C.Stream_Effect := True;
      C.Precision_Status := Precision.Representation_Freezing_Precision_Stream_Profile_Error;
      C.Source_Fingerprint := 1_146_009;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 10;
      C.Kind := E.Freezing_Propagation_Context_Private_Full_View;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114610);
      C.Target_Name := To_Unbounded_String ("P.T");
      C.Private_Full_View_Mismatch := True;
      C.Source_Fingerprint := 1_146_010;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 11;
      C.Kind := E.Freezing_Propagation_Context_Call_Use;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114611);
      C.Target_Name := To_Unbounded_String ("P.Op");
      C.Implicit_Freezing_Order_Error := True;
      C.Source_Fingerprint := 1_146_011;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 12;
      C.Kind := E.Freezing_Propagation_Context_Expression_Use;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114612);
      C.Target_Name := To_Unbounded_String ("State");
      C.Flow_Status := Flow.Flow_Graph_Write_Not_In_Global;
      C.Source_Fingerprint := 1_146_012;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 13;
      C.Kind := E.Freezing_Propagation_Context_Expression_Use;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114613);
      C.Target_Name := To_Unbounded_String ("Checked_T");
      C.Predicate_Status := Pred.Propagation_Invariant_Lost;
      C.Source_Fingerprint := 1_146_013;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 14;
      C.Kind := E.Freezing_Propagation_Context_Object_Declaration;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114614);
      C.Target_Name := To_Unbounded_String ("Ptr");
      C.Scope_Status := Scope.Scope_Legality_Master_Too_Short;
      C.Source_Fingerprint := 1_146_014;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 15;
      C.Kind := E.Freezing_Propagation_Context_Elaboration_Edge;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114615);
      C.Target_Name := To_Unbounded_String ("Pkg");
      C.Elaboration_Status := Elab.Graph_Closure_Direct_Call_Before_Body;
      C.Source_Fingerprint := 1_146_015;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 16;
      C.Kind := E.Freezing_Propagation_Context_Tasking_Effect;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114616);
      C.Target_Name := To_Unbounded_String ("PO");
      C.Tasking_Status := Tasking.Tasking_Effect_Protected_Function_Writes_State;
      C.Source_Fingerprint := 1_146_016;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 17;
      C.Kind := E.Freezing_Propagation_Context_Record_Layout;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114617);
      C.Target_Name := To_Unbounded_String ("Layout_T");
      C.Gate_Status := Gates.Enforcement_Metadata_Blocker;
      C.Source_Fingerprint := 1_146_017;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 18;
      C.Kind := E.Freezing_Propagation_Context_Object_Declaration;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114618);
      C.Target_Name := To_Unbounded_String ("Multi");
      C.Flow_Status := Flow.Flow_Graph_Read_Not_In_Global;
      C.Scope_Status := Scope.Scope_Legality_Return_Object_Master_Too_Short;
      C.Source_Fingerprint := 1_146_018;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 19;
      C.Kind := E.Freezing_Propagation_Context_Unknown;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114619);
      C.Target_Name := To_Unbounded_String ("Unknown");
      C.Source_Fingerprint := 1_146_019;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 20;
      C.Kind := E.Freezing_Propagation_Context_Private_Full_View;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114620);
      C.Target_Name := To_Unbounded_String ("P.Full_T");
      C.Source_Fingerprint := 1_146_020;
      E.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Contexts;

   procedure Test_Statuses (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : constant E.Freezing_Propagation_Context_Model := Sample_Contexts;
      Model    : constant E.Freezing_Propagation_Model := E.Build (Contexts);
   begin
      Assert (E.Context_Count (Contexts) = 20, "all freezing propagation contexts are recorded");
      Assert (E.Row_Count (Model) = 20, "all freezing propagation contexts produce rows");
      Assert (E.Count_Status (Model, E.Freezing_Propagation_Legal_Implicit_Freezing) = 1,
              "implicit semantic-use freezing is legal when representation precedes it");
      Assert (E.Count_Status (Model, E.Freezing_Propagation_Legal_Explicit_Representation_Before_Freezing) = 1,
              "explicit representation before freezing remains legal");
      Assert (E.Count_Status (Model, E.Freezing_Propagation_Legal_Private_Full_View_Freezing) = 1,
              "private/full-view freezing can be legal");
      Assert (E.Count_Status (Model, E.Freezing_Propagation_Representation_After_Implicit_Use) = 1,
              "representation after implicit use is rejected");
      Assert (E.Count_Status (Model, E.Freezing_Propagation_Representation_After_Generic_Instance) = 1,
              "generic instance freezing is propagated");
      Assert (E.Count_Status (Model, E.Freezing_Propagation_Representation_After_Generic_Body_Replay) = 1,
              "generic body replay freezing is propagated");
      Assert (E.Count_Status (Model, E.Freezing_Propagation_Discriminant_Representation_Error) = 1,
              "discriminant representation errors participate in freezing");
      Assert (E.Count_Status (Model, E.Freezing_Propagation_Variant_Representation_Error) = 1,
              "variant representation errors participate in freezing");
      Assert (E.Count_Status (Model, E.Freezing_Propagation_Operational_Finalization_Error) = 1,
              "operational/finalization effects are checked");
      Assert (E.Count_Status (Model, E.Freezing_Propagation_Stream_Effect_Error) = 1,
              "stream effect errors are checked");
      Assert (E.Count_Status (Model, E.Freezing_Propagation_Private_Full_View_Mismatch) = 1,
              "private/full view mismatches are checked");
      Assert (E.Count_Status (Model, E.Freezing_Propagation_Implicit_Freezing_Order_Error) = 1,
              "implicit freezing order errors are preserved");
      Assert (E.Count_Status (Model, E.Freezing_Propagation_Linked_Flow_Effect_Error) = 1,
              "flow-effect blockers are linked");
      Assert (E.Count_Status (Model, E.Freezing_Propagation_Linked_Predicate_Invariant_Error) = 1,
              "predicate/invariant blockers are linked");
      Assert (E.Count_Status (Model, E.Freezing_Propagation_Linked_Accessibility_Scope_Error) = 1,
              "accessibility-scope blockers are linked");
      Assert (E.Count_Status (Model, E.Freezing_Propagation_Linked_Elaboration_Graph_Error) = 1,
              "elaboration-graph blockers are linked");
      Assert (E.Count_Status (Model, E.Freezing_Propagation_Linked_Tasking_Effect_Error) = 1,
              "tasking-effect blockers are linked");
      Assert (E.Count_Status (Model, E.Freezing_Propagation_Coverage_Gate_Blocker) = 1,
              "coverage gates block unsafe freezing conclusions");
      Assert (E.Count_Status (Model, E.Freezing_Propagation_Multiple_Blockers) = 1,
              "multiple freezing blockers are preserved");
      Assert (E.Count_Status (Model, E.Freezing_Propagation_Indeterminate) = 1,
              "unknown freezing contexts degrade to indeterminate");
      Assert (E.Legal_Count (Model) = 3, "three legal freezing propagation rows are preserved");
      Assert (E.Error_Count (Model) = 16, "sixteen freezing propagation rows are errors");
      Assert (E.Indeterminate_Count (Model) = 1, "one row is indeterminate");
      Assert (E.Freezing_Order_Error_Count (Model) = 4, "freezing-order errors are counted");
      Assert (E.Discriminant_Error_Count (Model) = 2, "discriminant/variant representation errors are counted");
      Assert (E.Operational_Stream_Error_Count (Model) = 2, "operational and stream effect errors are counted");
      Assert (E.Linked_Error_Count (Model) = 6, "linked semantic blockers are counted");
      Assert (E.Coverage_Gate_Error_Count (Model) = 1, "coverage gate blockers are counted");
      Assert (E.Fingerprint (Model) /= 0, "model fingerprint is stable and non-zero");
   end Test_Statuses;

   procedure Test_Lookups (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant E.Freezing_Propagation_Model := E.Build (Sample_Contexts);
      Row   : constant E.Freezing_Propagation_Info :=
        E.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114605));
      Target_Rows : constant E.Freezing_Propagation_Set :=
        E.Rows_For_Target (Model, "T");
      Clause_Rows : constant E.Freezing_Propagation_Set :=
        E.Rows_For_Kind (Model, E.Freezing_Propagation_Context_Representation_Clause);
   begin
      Assert (Row.Status = E.Freezing_Propagation_Representation_After_Generic_Body_Replay,
              "node lookup returns generic-body replay freezing row");
      Assert (E.Has_Error (Row), "generic-body replay row is an error");
      Assert (E.Result_Count (Target_Rows) = 3, "target lookup returns all rows for T");
      Assert (E.Result_Count (Clause_Rows) = 2, "kind lookup returns representation clauses");
      Assert (E.Result_At (Clause_Rows, 1).Fingerprint /= 0, "result fingerprints are preserved");
   end Test_Lookups;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Statuses'Access, "representation/freezing exact propagation statuses");
      Register_Routine
        (T, Test_Lookups'Access, "representation/freezing exact propagation lookups");
   end Register_Tests;

end Test_Ada_Representation_Freezing_Exact_Propagation_Legality;
