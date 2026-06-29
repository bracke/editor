with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit; use AUnit;
with Editor.Ada_Diagnostic_Provenance;
with Editor.Ada_Final_Semantic_Blocker_Remediation_Order;
with Editor.Ada_Final_Semantic_Blocker_Trace_Closure;
with Editor.Ada_Final_Semantic_Diagnostic_Integration;
with Editor.Ada_Final_Semantic_Diagnostic_Provenance;
with Editor.Ada_Final_Semantic_Diagnostic_Search_Index;
with Editor.Ada_Final_Semantic_Remediation_Gate_Legality;
with Editor.Ada_Semantic_Colour_Projection;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Final_Semantic_Remediation_Gate_Legality is

   package Final_Diag renames Editor.Ada_Final_Semantic_Diagnostic_Integration;
   use type Final_Diag.Final_Diagnostic_Id;
   use type Final_Diag.Final_Diagnostic_Source_Family;
   use type Final_Diag.Final_Diagnostic_Severity;
   use type Final_Diag.Final_Diagnostic_Status;
   use type Final_Diag.Final_Diagnostic_Context_Info;
   use type Final_Diag.Final_Diagnostic_Info;
   use type Final_Diag.Final_Diagnostic_Context_Model;
   use type Final_Diag.Final_Diagnostic_Model;
   use type Final_Diag.Final_Diagnostic_Set;
   package Final_Prov renames Editor.Ada_Final_Semantic_Diagnostic_Provenance;
   use type Final_Prov.Final_Provenance_Id;
   use type Final_Prov.Final_Provenance_Status;
   use type Final_Prov.Final_Provenance_Stage;
   use type Final_Prov.Final_Blocker_Family;
   use type Final_Prov.Final_Provenance_Info;
   use type Final_Prov.Final_Provenance_Model;
   use type Final_Prov.Final_Provenance_Set;
   package Final_Index renames Editor.Ada_Final_Semantic_Diagnostic_Search_Index;
   use type Final_Index.Final_Blocker_Family;
   use type Final_Index.Final_Provenance_Status;
   use type Final_Index.Final_Provenance_Stage;
   use type Final_Index.Final_Diagnostic_Status;
   use type Final_Index.Final_Search_Index_Id;
   use type Final_Index.Final_Search_Index_Status;
   use type Final_Index.Final_Search_Entry;
   use type Final_Index.Final_Search_Result;
   use type Final_Index.Final_Search_Result_Set;
   use type Final_Index.Final_Search_Index_Model;
   package Trace renames Editor.Ada_Final_Semantic_Blocker_Trace_Closure;
   use type Trace.Final_Blocker_Family;
   use type Trace.Final_Provenance_Status;
   use type Trace.Final_Provenance_Stage;
   use type Trace.Final_Blocker_Trace_Id;
   use type Trace.Final_Blocker_Trace_Status;
   use type Trace.Final_Blocker_Trace_Root;
   use type Trace.Final_Blocker_Trace_Link;
   use type Trace.Final_Blocker_Trace;
   use type Trace.Final_Blocker_Trace_Set;
   use type Trace.Final_Blocker_Trace_Model;
   package Remediate renames Editor.Ada_Final_Semantic_Blocker_Remediation_Order;
   use type Remediate.Final_Blocker_Family;
   use type Remediate.Final_Blocker_Trace_Id;
   use type Remediate.Final_Blocker_Trace_Status;
   use type Remediate.Final_Blocker_Trace_Root;
   use type Remediate.Final_Remediation_Id;
   use type Remediate.Final_Remediation_Status;
   use type Remediate.Final_Remediation_Priority;
   use type Remediate.Final_Remediation_Action;
   use type Remediate.Final_Remediation_Set;
   use type Remediate.Final_Remediation_Model;
   package Gate renames Editor.Ada_Final_Semantic_Remediation_Gate_Legality;
   use type Gate.Final_Blocker_Family;
   use type Gate.Final_Remediation_Id;
   use type Gate.Final_Remediation_Status;
   use type Gate.Final_Remediation_Priority;
   use type Gate.Final_Gate_Id;
   use type Gate.Final_Gate_Status;
   use type Gate.Final_Gate_Action;
   use type Gate.Final_Gated_Result;
   use type Gate.Final_Gated_Result_Set;
   use type Gate.Final_Gated_Model;
   package Access_Final renames Final_Diag.Access_Final;
   package Cross_Final renames Final_Diag.Cross_Final;
   package Discriminant_Final renames Final_Diag.Discriminant_Final;
   package Elaboration_Final renames Final_Diag.Elaboration_Final;
   package Flow_Final renames Final_Diag.Flow_Final;
   package Generic_Final renames Final_Diag.Generic_Final;
   package Overload_Final renames Final_Diag.Overload_Final;
   package Representation_Final renames Final_Diag.Representation_Final;
   package Tasking_Final renames Final_Diag.Tasking_Final;
   package Base_Prov renames Editor.Ada_Diagnostic_Provenance;
   use type Base_Prov.Feed_Entry;
   use type Base_Prov.Feed_Severity;
   use type Base_Prov.Feed_Source;
   use type Base_Prov.Index_Entry;
   use type Base_Prov.Diagnostic_Provenance_Id;
   use type Base_Prov.Diagnostic_Provenance_Status;
   use type Base_Prov.Diagnostic_Provenance_Stage;
   use type Base_Prov.Diagnostic_Provenance_Item;
   use type Base_Prov.Diagnostic_Provenance_Result_Set;
   use type Base_Prov.Diagnostic_Provenance_Model;
   package SC renames Editor.Ada_Semantic_Colour_Projection;
   use type SC.Semantic_Colour_Entry_Id;
   use type SC.Semantic_Colour_Source;
   use type SC.Semantic_Colour_Severity;
   use type SC.Semantic_Colour_Entry;
   use type SC.Semantic_Colour_Model;
   package SF renames Editor.Ada_Semantic_Diagnostic_Feed;
   use type SF.Semantic_Diagnostic_Feed_Id;
   use type SF.Semantic_Diagnostic_Feed_Status;
   use type SF.Semantic_Diagnostic_Feed_Severity;
   use type SF.Semantic_Diagnostic_Feed_Source;
   use type SF.Semantic_Diagnostic_Feed_Entry;
   use type SF.Semantic_Diagnostic_Feed_Model;
   package SI renames Editor.Ada_Semantic_Diagnostic_Index;
   use type SI.Feed_Entry;
   use type SI.Feed_Severity;
   use type SI.Feed_Source;
   use type SI.Semantic_Diagnostic_Index_Id;
   use type SI.Semantic_Diagnostic_Index_Status;
   use type SI.Semantic_Diagnostic_Index_Entry;
   use type SI.Semantic_Diagnostic_Query_Result;
   use type SI.Semantic_Diagnostic_Query_Set;
   use type SI.Semantic_Diagnostic_Index_Model;
   package SG renames Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
   use type SG.Diagnostic_Snapshot_Key;
   use type SG.Diagnostic_Snapshot_Status;
   use type SG.Guarded_Semantic_Diagnostic_Model;

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Final_Prov.Final_Blocker_Family;
   use type Gate.Final_Gate_Status;
   use type Gate.Final_Gate_Action;

   function Name (T : Test_Case) return Message_String is
      pragma Unreferenced (T);
   begin
      return Format ("Test_Ada_Final_Semantic_Remediation_Gate_Legality");
   end Name;

   function Current_Guard return SG.Guarded_Semantic_Diagnostic_Model is
      Projection : SC.Semantic_Colour_Model;
      Key : constant SG.Diagnostic_Snapshot_Key :=
        SG.Make_Key ("final-remediation-gate.adb", 1200, 25, 35, 45, SC.Fingerprint (Projection));
   begin
      return SG.Build (Key, Key, Projection);
   end Current_Guard;

   function Base_Context
     (Id     : Final_Diag.Final_Diagnostic_Id;
      Family : Final_Diag.Final_Diagnostic_Source_Family;
      Node   : Editor.Ada_Syntax_Tree.Node_Id)
      return Final_Diag.Final_Diagnostic_Context_Info is
      C : Final_Diag.Final_Diagnostic_Context_Info;
   begin
      C.Id := Id;
      C.Family := Family;
      C.Node := Node;
      C.Cross_Unit_Status := Cross_Final.Cross_Unit_Final_Accepted;
      C.Overload_Status := Overload_Final.Final_RM_Legal_Prefixed_Call_Primitive_Selected;
      C.Generic_Status := Generic_Final.Nested_Generic_Legal_Nested_Instance_Closed;
      C.Representation_Status := Representation_Final.Final_Representation_Legal_Implicit_Freezing_Order_Accepted;
      C.Flow_Status := Flow_Final.Flow_Contract_Proof_Legal_Transitive_Depends_Accepted;
      C.Tasking_Status := Tasking_Final.Deep_Tasking_Legal_Entry_Family_Queue_Accepted;
      C.Elaboration_Status := Elaboration_Final.Final_Elaboration_Legal_Generic_Instance_Accepted;
      C.Accessibility_Status := Access_Final.Master_Scope_Final_Legal_Return_Access_Accepted;
      C.Discriminant_Status := Discriminant_Final.Discriminant_Consumer_Legal_Record_Aggregate_Accepted;
      C.Source_Fingerprint := Natural (Id) * 1200;
      C.Expected_Source_Fingerprint := Natural (Id) * 1200;
      C.Message := To_Unbounded_String ("final semantic remediation gate context");
      C.Start_Line := Positive (Natural (Id) + 60);
      C.Start_Column := 11;
      C.End_Line := Positive (Natural (Id) + 60);
      C.End_Column := 41;
      return C;
   end Base_Context;

   function Final_Model return Final_Diag.Final_Diagnostic_Model is
      Contexts : Final_Diag.Final_Diagnostic_Context_Model;
      Legal : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (1,
           Final_Diag.Final_Diagnostic_Overload_Type,
           Editor.Ada_Syntax_Tree.Node_Id (120001));
      Cross : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (2,
           Final_Diag.Final_Diagnostic_Cross_Unit,
           Editor.Ada_Syntax_Tree.Node_Id (120002));
      Generic_Ctx : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (3,
           Final_Diag.Final_Diagnostic_Generic_Replay,
           Editor.Ada_Syntax_Tree.Node_Id (120003));
      Flow : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (4,
           Final_Diag.Final_Diagnostic_Flow_Contract,
           Editor.Ada_Syntax_Tree.Node_Id (120004));
      Multiple : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (5,
           Final_Diag.Final_Diagnostic_Multiple,
           Editor.Ada_Syntax_Tree.Node_Id (120005));
      Stale : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (6,
           Final_Diag.Final_Diagnostic_Tasking_Protected,
           Editor.Ada_Syntax_Tree.Node_Id (120006));
   begin
      Cross.Cross_Unit_Status := Cross_Final.Cross_Unit_Final_Missing_Dependency;
      Generic_Ctx.Generic_Status := Generic_Final.Nested_Generic_Recursive_Instantiation_Cycle;
      Flow.Flow_Status := Flow_Final.Flow_Contract_Proof_Transitive_Depends_Cycle;
      Multiple.Cross_Unit_Status := Cross_Final.Cross_Unit_Final_Missing_Dependency;
      Multiple.Tasking_Status := Tasking_Final.Deep_Tasking_Indirect_Reentrancy_Blocker;
      Multiple.Flow_Status := Flow_Final.Flow_Contract_Proof_Abstract_State_Missing;
      Stale.Input_Current := False;

      Final_Diag.Add_Context (Contexts, Legal);
      Final_Diag.Add_Context (Contexts, Cross);
      Final_Diag.Add_Context (Contexts, Generic_Ctx);
      Final_Diag.Add_Context (Contexts, Flow);
      Final_Diag.Add_Context (Contexts, Multiple);
      Final_Diag.Add_Context (Contexts, Stale);
      return Final_Diag.Build (Contexts);
   end Final_Model;

   function Trace_Model return Trace.Final_Blocker_Trace_Model is
      Final : constant Final_Diag.Final_Diagnostic_Model := Final_Model;
      Feed_Model : constant SF.Semantic_Diagnostic_Feed_Model :=
        SF.Build_With_Final_Semantic_Diagnostics (Current_Guard, Final);
      Index_Model : constant SI.Semantic_Diagnostic_Index_Model := SI.Build (Feed_Model);
      Base_Model : constant Base_Prov.Diagnostic_Provenance_Model := Base_Prov.Build (Index_Model);
      Provenance : constant Final_Prov.Final_Provenance_Model :=
        Final_Prov.Build_With_Base_Provenance (Final, Feed_Model, Index_Model, Base_Model);
      Search : constant Final_Index.Final_Search_Index_Model := Final_Index.Build (Provenance);
   begin
      return Trace.Build_With_Provenance (Search, Provenance);
   end Trace_Model;

   function Remediation_Model return Remediate.Final_Remediation_Model is
   begin
      return Remediate.Build (Trace_Model);
   end Remediation_Model;

   function Gate_Model return Gate.Final_Gated_Model is
   begin
      return Gate.Build (Remediation_Model);
   end Gate_Model;

   procedure Remediation_Gates_Withhold_Unresolved_Prerequisites
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Gate.Final_Gated_Model := Gate_Model;
      First : constant Gate.Final_Gated_Result := Gate.First_Prerequisite_Blocker (Model);
      Dependency : constant Gate.Final_Gated_Result_Set :=
        Gate.Query_Status (Model, Gate.Final_Gate_Withheld_Cross_Unit_Dependency);
      Generic_Ctx : constant Gate.Final_Gated_Result_Set :=
        Gate.Query_Blocker (Model, Final_Prov.Final_Blocker_Generic_Replay);
      Flow : constant Gate.Final_Gated_Result_Set :=
        Gate.Query_Blocker (Model, Final_Prov.Final_Blocker_Flow_Contract);
   begin
      Assert (Gate.Row_Count (Model) = Remediate.Action_Count (Remediation_Model),
              "remediation gate should preserve one gate row per remediation action");
      Assert (Gate.Confident_Legal_Count (Model) = 1,
              "legal remediation action should remain a confident legal gate row");
      Assert (Gate.Withheld_Count (Model) >= 4,
              "unresolved semantic prerequisites should withhold downstream confident results");
      Assert (Gate.Prerequisite_Blocking_Count (Model) >= 5,
              "stale, dependency, generic, flow, and multiple blockers should block prerequisites");
      Assert (Gate.Legal_Result_Withheld_Count (Model) >= Gate.Withheld_Count (Model),
              "withheld prerequisites should suppress downstream legal conclusions");
      Assert (First.Status = Gate.Final_Gate_Withheld_Stale_Input
                or else First.Status = Gate.Final_Gate_Withheld_Cross_Unit_Dependency,
              "first prerequisite should be stale evidence or cross-unit dependency closure");
      Assert (Gate.Set_Count (Dependency) = 1,
              "cross-unit remediation should become a dependency gate");
      Assert
        (Gate.Set_At (Dependency, 1).Action = Gate.Final_Gate_Action_Require_Prerequisite_Remediation,
         "dependency gate should require prerequisite remediation");
      Assert (Gate.Set_Count (Generic_Ctx) = 1,
              "generic replay gate should retain generic blocker identity");
      Assert
        (Gate.Set_At (Generic_Ctx, 1).Status = Gate.Final_Gate_Withheld_Generic_Replay,
         "generic replay remediation should withhold generic replay consumers");
      Assert (Gate.Set_Count (Flow) = 1,
              "flow/contract gate should retain flow blocker identity");
      Assert
        (Gate.Set_At (Flow, 1).Status = Gate.Final_Gate_Withheld_Flow_Contract,
         "flow remediation should withhold flow/contract proof consumers");
      Assert (Gate.Downstream_Blocked_Count (Model) > Gate.Prerequisite_Blocking_Count (Model),
              "gate model should preserve downstream blocked pressure");
      Assert (Gate.Fingerprint (Model) /= 0,
              "gate fingerprint should include remediation and blocker data");
   end Remediation_Gates_Withhold_Unresolved_Prerequisites;

   procedure Remediation_Gates_Support_Source_And_Action_Queries
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Gate.Final_Gated_Model := Gate_Model;
      Suppressed : constant Gate.Final_Gated_Result_Set :=
        Gate.Query_Action (Model, Gate.Final_Gate_Action_Require_Prerequisite_Remediation);
      Legal : constant Gate.Final_Gated_Result_Set :=
        Gate.Query_Action (Model, Gate.Final_Gate_Action_Allow_Confident_Result);
      Node_Hits : constant Gate.Final_Gated_Result_Set :=
        Gate.Query_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (120002));
      Pos_Hits : constant Gate.Final_Gated_Result_Set :=
        Gate.Query_Position (Model, 62, 12);
   begin
      Assert (Gate.Dependency_Withheld_Count (Model) = 1,
              "dependency gate count should preserve cross-unit remediation");
      Assert (Gate.Stale_Withheld_Count (Model) = 1,
              "stale input should force snapshot gate withholding");
      Assert (Gate.Generic_Replay_Withheld_Count (Model) = 1,
              "generic replay withholding should be counted separately");
      Assert (Gate.Object_State_Withheld_Count (Model) = 1,
              "flow/contract proof should be counted as object-state withholding");
      Assert (Gate.Multiple_Blocker_Withheld_Count (Model) = 1,
              "multiple blockers should remain split-gated");
      Assert (Gate.Set_Count (Suppressed) >= 4,
              "prerequisite-remediation query should recover unresolved semantic gates");
      Assert (Gate.Set_Count (Legal) = 1,
              "confident legal action query should recover legal row");
      Assert (Gate.Set_Count (Node_Hits) = 1,
              "node query should recover the cross-unit gate row");
      Assert
        (Gate.Set_At (Node_Hits, 1).Blocker_Family = Final_Prov.Final_Blocker_Cross_Unit,
         "node query should preserve cross-unit blocker family");
      Assert (Gate.Set_Count (Pos_Hits) = 1,
              "position query should resolve the same gate span");
   end Remediation_Gates_Support_Source_And_Action_Queries;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Remediation_Gates_Withhold_Unresolved_Prerequisites'Access,
         "final semantic remediation gates withhold unresolved prerequisites");
      Register_Routine
        (T,
         Remediation_Gates_Support_Source_And_Action_Queries'Access,
         "final semantic remediation gates support source/action queries");
   end Register_Tests;

end Test_Ada_Final_Semantic_Remediation_Gate_Legality;
