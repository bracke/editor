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
with Editor.Ada_Final_Semantic_Remediation_Diagnostic_Provenance_Search;
with Editor.Ada_Semantic_Colour_Projection;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Final_Semantic_Remediation_Diagnostic_Provenance_Search_Pass1203 is

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
   package Remed_Prov renames Editor.Ada_Final_Semantic_Remediation_Diagnostic_Provenance_Search;
   use type Remed_Prov.Final_Blocker_Family;
   use type Remed_Prov.Final_Remediation_Diagnostic_Status;
   use type Remed_Prov.Final_Remediation_Diagnostic_Family;
   use type Remed_Prov.Final_Remediation_Closure_Status;
   use type Remed_Prov.Final_Gate_Status;
   use type Remed_Prov.Final_Gate_Action;
   use type Remed_Prov.Final_Trace_Root;
   use type Remed_Prov.Final_Remediation_Provenance_Id;
   use type Remed_Prov.Final_Remediation_Provenance_Status;
   use type Remed_Prov.Final_Remediation_Provenance_Stage;
   use type Remed_Prov.Final_Remediation_Provenance_Info;
   use type Remed_Prov.Final_Remediation_Provenance_Model;
   use type Remed_Prov.Final_Remediation_Provenance_Set;
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
   use type SF.Semantic_Diagnostic_Feed_Id;
   use type SI.Semantic_Diagnostic_Index_Id;

   function Name (T : Test_Case) return Message_String is
      pragma Unreferenced (T);
   begin
      return Format ("Test_Ada_Final_Semantic_Remediation_Diagnostic_Provenance_Search_Pass1203");
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

   procedure Remediation_Diagnostics_Get_Provenance_And_Search_Links
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Closure_Model_Value : constant Closure.Final_Remediation_Closure_Model := Closure_Model;
      Gate_Model_Value : constant Gate.Final_Gated_Model := Gate_Model;
      Trace_Model_Value : constant Trace.Final_Blocker_Trace_Model := Trace_Model;
      Model : constant Remed_Diag.Final_Remediation_Diagnostic_Model :=
        Remediation_Diagnostic_Model;
      Feed_Model : constant SF.Semantic_Diagnostic_Feed_Model :=
        SF.Build_With_Final_Remediation_Diagnostics (Current_Guard, Model);
      Index_Model : constant SI.Semantic_Diagnostic_Index_Model := SI.Build (Feed_Model);
      Base_Model : constant Base_Prov.Diagnostic_Provenance_Model := Base_Prov.Build (Index_Model);
      Provenance : constant Remed_Prov.Final_Remediation_Provenance_Model :=
        Remed_Prov.Build_With_Feed_Index_And_Base
          (Model,
           Closure_Model_Value,
           Gate_Model_Value,
           Trace_Model_Value,
           Feed_Model,
           Index_Model,
           Base_Model);
      Cross : constant Remed_Prov.Final_Remediation_Provenance_Set :=
        Remed_Prov.Query_Blocker (Provenance, Final_Prov.Final_Blocker_Cross_Unit);
      Generic_Ctx : constant Remed_Prov.Final_Remediation_Provenance_Set :=
        Remed_Prov.Query_Blocker (Provenance, Final_Prov.Final_Blocker_Generic_Replay);
      Legal : constant Remed_Prov.Final_Remediation_Provenance_Set :=
        Remed_Prov.Query_Status
          (Provenance, Remed_Prov.Final_Remediation_Provenance_Withheld_Legal);
      Trace_Linked : constant Remed_Prov.Final_Remediation_Provenance_Set :=
        Remed_Prov.Query_Stage (Provenance, Remed_Prov.Final_Remediation_Stage_Base_Provenance);
      Cross_Row : Remed_Prov.Final_Remediation_Provenance_Info;
   begin
      Assert (Remed_Prov.Row_Count (Provenance) = Remed_Diag.Row_Count (Model),
              "remediation provenance should preserve one row per remediation diagnostic row");
      Assert (Remed_Prov.Withheld_Count (Provenance) = Remed_Diag.Withheld_Legal_Count (Model),
              "withheld remediation diagnostics should stay represented as provenance");
      Assert (Remed_Prov.Stale_Rejected_Count (Provenance) = Remed_Diag.Stale_Count (Model),
              "stale remediation diagnostics should remain stale provenance rows");
      Assert (Remed_Prov.Count_Blocker (Provenance, Final_Prov.Final_Blocker_Generic_Replay) =
              Remed_Diag.Count_Blocker (Model, Final_Prov.Final_Blocker_Generic_Replay),
              "generic replay prerequisite blocker should survive provenance/search");
      Assert (Remed_Prov.Count_Blocker (Provenance, Final_Prov.Final_Blocker_Flow_Contract) =
              Remed_Diag.Count_Blocker (Model, Final_Prov.Final_Blocker_Flow_Contract),
              "flow/contract prerequisite blocker should survive provenance/search");
      Assert (Remed_Prov.Feed_Link_Count (Provenance) = SF.Entry_Count (Feed_Model),
              "emitted remediation diagnostics should link to feed entries");
      Assert (Remed_Prov.Index_Link_Count (Provenance) = SI.Entry_Count (Index_Model),
              "emitted remediation diagnostics should link to diagnostic index entries");
      Assert (Remed_Prov.Base_Link_Count (Provenance) = Base_Prov.Item_Count (Base_Model),
              "emitted remediation diagnostics should link to base diagnostic provenance");
      Assert (Remed_Prov.Closure_Link_Count (Provenance) = Remed_Prov.Row_Count (Provenance),
              "all remediation provenance rows should link back to closure rows");
      Assert (Remed_Prov.Gate_Link_Count (Provenance) = Remed_Prov.Row_Count (Provenance),
              "all remediation provenance rows should link back to gate rows");
      Assert (Remed_Prov.Trace_Link_Count (Provenance) >= Remed_Diag.Emitted_Count (Model),
              "remediation blocker provenance should retain trace closure evidence");
      Assert (Remed_Prov.Query_Count (Cross) = Remed_Diag.Count_Blocker (Model, Final_Prov.Final_Blocker_Cross_Unit),
              "cross-unit blocker query should recover cross-unit remediation provenance");
      Assert (Remed_Prov.Query_Count (Generic_Ctx) = 1,
              "generic blocker query should recover generic remediation provenance");
      Assert (Remed_Prov.Query_Count (Legal) = Remed_Diag.Withheld_Legal_Count (Model),
              "withheld legal query should recover accepted remediation closure rows");
      Assert (Remed_Prov.Query_Count (Trace_Linked) >= Remed_Diag.Emitted_Count (Model),
              "base-provenance-stage query should recover linked emitted rows");
      Cross_Row := Remed_Prov.Query_At (Cross, 1);
      Assert (Remed_Prov.Query_Count (Remed_Prov.Query_Node (Provenance, Cross_Row.Node)) >= 1,
              "node query should recover remediation provenance row");
      Assert (Remed_Prov.Query_Count
                (Remed_Prov.Query_Position
                   (Provenance, Cross_Row.Start_Line, Cross_Row.Start_Column)) >= 1,
              "source-position query should recover remediation provenance row");
      if Cross_Row.Feed_Entry /= SF.No_Semantic_Diagnostic_Feed_Entry then
         Assert (Remed_Prov.Query_Count
                   (Remed_Prov.Query_Feed_Link (Provenance, Cross_Row.Feed_Entry)) = 1,
                 "feed-link query should recover exact remediation provenance row");
      end if;
      if Cross_Row.Index_Entry /= SI.No_Semantic_Diagnostic_Index_Entry then
         Assert (Remed_Prov.Query_Count
                   (Remed_Prov.Query_Index_Link (Provenance, Cross_Row.Index_Entry)) = 1,
                 "index-link query should recover exact remediation provenance row");
      end if;
      Assert (Remed_Prov.Fingerprint (Provenance) /= 0,
              "remediation provenance/search fingerprint should be stable and nonzero");
   end Remediation_Diagnostics_Get_Provenance_And_Search_Links;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Remediation_Diagnostics_Get_Provenance_And_Search_Links'Access,
         "final remediation closure diagnostics preserve blocker families and feed gating");
   end Register_Tests;

end Test_Ada_Final_Semantic_Remediation_Diagnostic_Provenance_Search_Pass1203;
