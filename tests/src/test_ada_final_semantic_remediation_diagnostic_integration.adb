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
with Editor.Ada_Final_Semantic_Remediation_Closure_Legality;
with Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration;
with Editor.Ada_Semantic_Colour_Projection;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Final_Semantic_Remediation_Diagnostic_Integration is

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
   package Closure renames Editor.Ada_Final_Semantic_Remediation_Closure_Legality;
   use type Closure.Final_Blocker_Family;
   use type Closure.Final_Gate_Id;
   use type Closure.Final_Gate_Status;
   use type Closure.Final_Gate_Action;
   use type Closure.Final_Remediation_Closure_Id;
   use type Closure.Final_Remediation_Closure_Status;
   use type Closure.Final_Remediation_Closure_Row;
   use type Closure.Final_Remediation_Closure_Set;
   use type Closure.Final_Remediation_Closure_Model;
   package Remed_Diag renames Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration;
   use type Remed_Diag.Final_Blocker_Family;
   use type Remed_Diag.Final_Remediation_Closure_Id;
   use type Remed_Diag.Final_Remediation_Closure_Status;
   use type Remed_Diag.Final_Remediation_Diagnostic_Id;
   use type Remed_Diag.Final_Remediation_Diagnostic_Family;
   use type Remed_Diag.Final_Remediation_Diagnostic_Severity;
   use type Remed_Diag.Final_Remediation_Diagnostic_Status;
   use type Remed_Diag.Final_Remediation_Diagnostic_Row;
   use type Remed_Diag.Final_Remediation_Diagnostic_Set;
   use type Remed_Diag.Final_Remediation_Diagnostic_Model;
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
   use type Closure.Final_Remediation_Closure_Status;

   function Name (T : Test_Case) return Message_String is
      pragma Unreferenced (T);
   begin
      return Format ("Test_Ada_Final_Semantic_Remediation_Diagnostic_Integration");
   end Name;

   function Current_Guard return SG.Guarded_Semantic_Diagnostic_Model is
      Projection : SC.Semantic_Colour_Model;
      Key : constant SG.Diagnostic_Snapshot_Key :=
        SG.Make_Key ("final-remediation-closure.adb", 1201, 25, 35, 45, SC.Fingerprint (Projection));
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
      C.Source_Fingerprint := Natural (Id) * 1201;
      C.Expected_Source_Fingerprint := Natural (Id) * 1201;
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
           Editor.Ada_Syntax_Tree.Node_Id (120101));
      Cross : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (2,
           Final_Diag.Final_Diagnostic_Cross_Unit,
           Editor.Ada_Syntax_Tree.Node_Id (120102));
      Generic_Ctx : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (3,
           Final_Diag.Final_Diagnostic_Generic_Replay,
           Editor.Ada_Syntax_Tree.Node_Id (120103));
      Flow : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (4,
           Final_Diag.Final_Diagnostic_Flow_Contract,
           Editor.Ada_Syntax_Tree.Node_Id (120104));
      Multiple : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (5,
           Final_Diag.Final_Diagnostic_Multiple,
           Editor.Ada_Syntax_Tree.Node_Id (120105));
      Stale : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (6,
           Final_Diag.Final_Diagnostic_Tasking_Protected,
           Editor.Ada_Syntax_Tree.Node_Id (120106));
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

   function Closure_Model return Closure.Final_Remediation_Closure_Model is
   begin
      return Closure.Build (Gate_Model);
   end Closure_Model;


   function Remediation_Diagnostic_Model return Remed_Diag.Final_Remediation_Diagnostic_Model is
   begin
      return Remed_Diag.Build (Closure_Model);
   end Remediation_Diagnostic_Model;

   procedure Remediation_Closure_Becomes_Blocker_Family_Diagnostic_Feed
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Closure_Model_Value : constant Closure.Final_Remediation_Closure_Model := Closure_Model;
      Model : constant Remed_Diag.Final_Remediation_Diagnostic_Model :=
        Remediation_Diagnostic_Model;
      Feed_Model : constant SF.Semantic_Diagnostic_Feed_Model :=
        SF.Build_With_Final_Remediation_Diagnostics (Current_Guard, Model);
      Cross : constant Remed_Diag.Final_Remediation_Diagnostic_Set :=
        Remed_Diag.Query_Family
          (Model, Remed_Diag.Final_Remediation_Diagnostic_Cross_Unit);
      Generic_Ctx : constant Remed_Diag.Final_Remediation_Diagnostic_Set :=
        Remed_Diag.Query_Blocker (Model, Final_Prov.Final_Blocker_Generic_Replay);
      Flow : constant Remed_Diag.Final_Remediation_Diagnostic_Set :=
        Remed_Diag.Query_Blocker (Model, Final_Prov.Final_Blocker_Flow_Contract);
      Legal : constant Remed_Diag.Final_Remediation_Diagnostic_Set :=
        Remed_Diag.Query_Status
          (Model, Remed_Diag.Final_Remediation_Diagnostic_Withheld_Legal);
      Stale_Rejected : constant SF.Semantic_Diagnostic_Feed_Model :=
        SF.Build_With_Final_Remediation_Diagnostics
          (Current_Guard, Model, False, Remed_Diag.Row_Count (Model));
   begin
      Assert (Remed_Diag.Row_Count (Model) = Closure.Row_Count (Closure_Model_Value),
              "remediation diagnostics should preserve one row per closure row");
      Assert (Remed_Diag.Withheld_Legal_Count (Model) = Closure.Legal_Count (Closure_Model_Value),
              "legal closure rows should be withheld from diagnostic emission");
      Assert (Remed_Diag.Emitted_Count (Model) = Closure.Blocked_Count (Closure_Model_Value),
              "blocked closure rows should become emitted remediation diagnostics");
      Assert (Remed_Diag.Stale_Count (Model) = Closure.Stale_Blocker_Count (Closure_Model_Value),
              "stale remediation closure blockers should remain stale diagnostics");
      Assert (Remed_Diag.Count_Family
                (Model, Remed_Diag.Final_Remediation_Diagnostic_Cross_Unit) =
              Closure.Cross_Unit_Blocker_Count (Closure_Model_Value),
              "cross-unit prerequisite blockers should preserve diagnostic family");
      Assert (Remed_Diag.Count_Blocker (Model, Final_Prov.Final_Blocker_Generic_Replay) = 1,
              "generic replay blocker family should survive remediation diagnostic integration");
      Assert (Remed_Diag.Count_Blocker (Model, Final_Prov.Final_Blocker_Flow_Contract) = 1,
              "flow/contract blocker family should survive remediation diagnostic integration");
      Assert (Remed_Diag.Downstream_Blocked_Count (Model) =
              Closure.Downstream_Blocked_Count (Closure_Model_Value),
              "diagnostic rows should preserve downstream blocked pressure");
      Assert (Remed_Diag.Set_Count (Cross) = 1,
              "cross-unit family query should recover dependency prerequisite diagnostic");
      Assert (Remed_Diag.Set_At (Cross, 1).Status =
              Remed_Diag.Final_Remediation_Diagnostic_Cross_Unit_Prerequisite,
              "cross-unit closure blocker should map to cross-unit prerequisite diagnostic");
      Assert (Remed_Diag.Set_Count (Generic_Ctx) = 1,
              "generic blocker query should recover generic prerequisite diagnostic");
      Assert (Remed_Diag.Set_At (Generic_Ctx, 1).Family =
              Remed_Diag.Final_Remediation_Diagnostic_Generic_Replay,
              "generic diagnostic should retain generic replay family");
      Assert (Remed_Diag.Set_Count (Flow) = 1,
              "flow blocker query should recover flow prerequisite diagnostic");
      Assert (Remed_Diag.Set_At (Flow, 1).Family =
              Remed_Diag.Final_Remediation_Diagnostic_Flow_Contract,
              "flow diagnostic should retain flow/contract family");
      Assert (Remed_Diag.Set_Count (Legal) = Closure.Legal_Count (Closure_Model_Value),
              "accepted remediation closure should remain represented but withheld");
      Assert (SF.Entry_Count (Feed_Model) = Remed_Diag.Emitted_Count (Model),
              "feed integration should emit only blocker-family remediation rows");
      Assert (SF.Count_Source
                (Feed_Model, SC.Semantic_Colour_From_Cross_Unit) =
              Remed_Diag.Count_Family
                (Model, Remed_Diag.Final_Remediation_Diagnostic_Cross_Unit),
              "cross-unit remediation prerequisites should enter feed as cross-unit diagnostics");
      Assert (SF.Count_Source
                (Feed_Model, SC.Semantic_Colour_From_Generic_Contract) =
              Remed_Diag.Count_Family
                (Model, Remed_Diag.Final_Remediation_Diagnostic_Generic_Replay),
              "generic remediation prerequisites should enter feed as generic diagnostics");
      Assert (SF.Rejected_Stale (Stale_Rejected),
              "stale final remediation diagnostic input should reject feed rows");
      Assert (SF.Entry_Count (Stale_Rejected) = 0,
              "rejected final remediation diagnostics should not emit active rows");
      Assert (SF.Rejected_Entry_Count (Stale_Rejected) = Remed_Diag.Row_Count (Model),
              "rejected final remediation diagnostics should preserve rejected-row count");
      Assert (Remed_Diag.Fingerprint (Model) /= 0,
              "remediation diagnostic fingerprint should be stable and nonzero");
   end Remediation_Closure_Becomes_Blocker_Family_Diagnostic_Feed;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Remediation_Closure_Becomes_Blocker_Family_Diagnostic_Feed'Access,
         "final remediation closure diagnostics preserve blocker families and feed gating");
   end Register_Tests;

end Test_Ada_Final_Semantic_Remediation_Diagnostic_Integration;
