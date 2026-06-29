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
with Editor.Ada_Semantic_Colour_Projection;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Final_Semantic_Blocker_Remediation_Order is

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
   use type Remediate.Final_Remediation_Status;
   use type Remediate.Final_Remediation_Priority;

   function Name (T : Test_Case) return Message_String is
      pragma Unreferenced (T);
   begin
      return Format ("Test_Ada_Final_Semantic_Blocker_Remediation_Order");
   end Name;

   function Current_Guard return SG.Guarded_Semantic_Diagnostic_Model is
      Projection : SC.Semantic_Colour_Model;
      Key : constant SG.Diagnostic_Snapshot_Key :=
        SG.Make_Key ("final-remediation-order.adb", 1199, 24, 34, 44, SC.Fingerprint (Projection));
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
      C.Source_Fingerprint := Natural (Id) * 1199;
      C.Expected_Source_Fingerprint := Natural (Id) * 1199;
      C.Message := To_Unbounded_String ("final semantic remediation order context");
      C.Start_Line := Positive (Natural (Id) + 50);
      C.Start_Column := 9;
      C.End_Line := Positive (Natural (Id) + 50);
      C.End_Column := 39;
      return C;
   end Base_Context;

   function Final_Model return Final_Diag.Final_Diagnostic_Model is
      Contexts : Final_Diag.Final_Diagnostic_Context_Model;
      Legal : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (1,
           Final_Diag.Final_Diagnostic_Overload_Type,
           Editor.Ada_Syntax_Tree.Node_Id (119901));
      Cross : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (2,
           Final_Diag.Final_Diagnostic_Cross_Unit,
           Editor.Ada_Syntax_Tree.Node_Id (119902));
      Generic_Ctx : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (3,
           Final_Diag.Final_Diagnostic_Generic_Replay,
           Editor.Ada_Syntax_Tree.Node_Id (119903));
      Flow : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (4,
           Final_Diag.Final_Diagnostic_Flow_Contract,
           Editor.Ada_Syntax_Tree.Node_Id (119904));
      Multiple : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (5,
           Final_Diag.Final_Diagnostic_Multiple,
           Editor.Ada_Syntax_Tree.Node_Id (119905));
      Stale : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (6,
           Final_Diag.Final_Diagnostic_Tasking_Protected,
           Editor.Ada_Syntax_Tree.Node_Id (119906));
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

   procedure Remediation_Order_Prioritizes_Unlocking_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Remediate.Final_Remediation_Model := Remediation_Model;
      First : constant Remediate.Final_Remediation_Action := Remediate.First_Blocking_Action (Model);
      Cross : constant Remediate.Final_Remediation_Set :=
        Remediate.Query_Blocker (Model, Final_Prov.Final_Blocker_Cross_Unit);
      Generic_Ctx : constant Remediate.Final_Remediation_Set :=
        Remediate.Query_Blocker (Model, Final_Prov.Final_Blocker_Generic_Replay);
      Flow : constant Remediate.Final_Remediation_Set :=
        Remediate.Query_Blocker (Model, Final_Prov.Final_Blocker_Flow_Contract);
   begin
      Assert (Remediate.Action_Count (Model) = Final_Diag.Row_Count (Final_Model),
              "remediation ordering should preserve one action per final trace");
      Assert (Remediate.Blocking_Action_Count (Model) >= 5,
              "semantic blockers should become downstream-blocking remediation actions");
      Assert (First.Status = Remediate.Final_Remediation_Reject_Stale_Input
                or else First.Status = Remediate.Final_Remediation_Close_Cross_Unit_Dependency,
              "first remediation should repair stale snapshot evidence or cross-unit dependency closure");
      Assert (Remediate.Set_Count (Cross) = 1,
              "cross-unit blocker should be remediable by dependency closure");
      Assert
        (Remediate.Set_At (Cross, 1).Status = Remediate.Final_Remediation_Close_Cross_Unit_Dependency,
         "cross-unit final blocker should map to dependency closure remediation");
      Assert (Remediate.Set_Count (Generic_Ctx) = 1,
              "generic replay blocker should stay separately remediable");
      Assert
        (Remediate.Set_At (Generic_Ctx, 1).Priority = Remediate.Final_Remediation_Priority_Generic_Replay,
         "generic replay blockers should retain generic-replay priority");
      Assert (Remediate.Set_Count (Flow) = 1,
              "flow/contract blocker should stay separately remediable");
      Assert
        (Remediate.Set_At (Flow, 1).Status = Remediate.Final_Remediation_Restore_Flow_Contract_Proof,
         "flow blocker should map to flow-contract proof remediation");
      Assert (Remediate.Downstream_Unlock_Count (Model) > Remediate.Blocking_Action_Count (Model),
              "remediation model should record downstream unlock pressure");
      Assert (Remediate.Fingerprint (Model) /= 0,
              "remediation order fingerprint should include trace and blocker data");
   end Remediation_Order_Prioritizes_Unlocking_Blockers;

   procedure Remediation_Order_Supports_Status_Priority_And_Source_Queries
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Remediate.Final_Remediation_Model := Remediation_Model;
      Dependency : constant Remediate.Final_Remediation_Set :=
        Remediate.Query_Priority (Model, Remediate.Final_Remediation_Priority_Dependency);
      Stale : constant Remediate.Final_Remediation_Set :=
        Remediate.Query_Status (Model, Remediate.Final_Remediation_Reject_Stale_Input);
      Node_Hits : constant Remediate.Final_Remediation_Set :=
        Remediate.Query_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (119902));
      Pos_Hits : constant Remediate.Final_Remediation_Set :=
        Remediate.Query_Position (Model, 52, 10);
   begin
      Assert (Remediate.Dependency_Action_Count (Model) = 1,
              "dependency action count should preserve cross-unit remediation");
      Assert (Remediate.Set_Count (Dependency) = 1,
              "priority query should recover cross-unit dependency remediation");
      Assert (Remediate.Stale_Action_Count (Model) = 1,
              "stale final row should force snapshot rejection remediation");
      Assert (Remediate.Set_Count (Stale) = 1,
              "status query should recover stale-remediation action");
      Assert (Remediate.Generic_Replay_Action_Count (Model) = 1,
              "generic replay action should be counted separately");
      Assert (Remediate.Object_State_Action_Count (Model) = 1,
              "flow/contract proof should be counted as object-state remediation");
      Assert (Remediate.Multiple_Blocker_Action_Count (Model) = 1,
              "multiple blockers should require split remediation");
      Assert (Remediate.Legal_Action_Count (Model) = 1,
              "withheld legal final row should remain no-action legal evidence");
      Assert (Remediate.Set_Count (Node_Hits) = 1,
              "node query should recover the cross-unit remediation action");
      Assert
        (Remediate.Set_At (Node_Hits, 1).Blocker_Family = Final_Prov.Final_Blocker_Cross_Unit,
         "node query should preserve final blocker family");
      Assert (Remediate.Set_Count (Pos_Hits) = 1,
              "position query should resolve the same remediation span");
   end Remediation_Order_Supports_Status_Priority_And_Source_Queries;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Remediation_Order_Prioritizes_Unlocking_Blockers'Access,
         "final semantic blocker remediation order prioritizes unlocking blockers");
      Register_Routine
        (T,
         Remediation_Order_Supports_Status_Priority_And_Source_Queries'Access,
         "final semantic blocker remediation order supports status/priority/source queries");
   end Register_Tests;

end Test_Ada_Final_Semantic_Blocker_Remediation_Order;
