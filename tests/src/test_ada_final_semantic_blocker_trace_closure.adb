with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit; use AUnit;
with Editor.Ada_Diagnostic_Provenance;
with Editor.Ada_Final_Semantic_Blocker_Trace_Closure;
with Editor.Ada_Final_Semantic_Diagnostic_Integration;
with Editor.Ada_Final_Semantic_Diagnostic_Provenance;
with Editor.Ada_Final_Semantic_Diagnostic_Search_Index;
with Editor.Ada_Semantic_Colour_Projection;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Final_Semantic_Blocker_Trace_Closure is

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
   use type Trace.Final_Blocker_Trace_Root;
   use type Trace.Final_Blocker_Trace_Status;
   use type SF.Semantic_Diagnostic_Feed_Id;
   use type SI.Semantic_Diagnostic_Index_Id;

   function Name (T : Test_Case) return Message_String is
      pragma Unreferenced (T);
   begin
      return Format ("Test_Ada_Final_Semantic_Blocker_Trace_Closure");
   end Name;

   function Current_Guard return SG.Guarded_Semantic_Diagnostic_Model is
      Projection : SC.Semantic_Colour_Model;
      Key : constant SG.Diagnostic_Snapshot_Key :=
        SG.Make_Key ("final-blocker-trace.adb", 1198, 23, 33, 43, SC.Fingerprint (Projection));
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
      C.Source_Fingerprint := Natural (Id) * 1198;
      C.Expected_Source_Fingerprint := Natural (Id) * 1198;
      C.Message := To_Unbounded_String ("final semantic blocker trace context");
      C.Start_Line := Positive (Natural (Id) + 40);
      C.Start_Column := 7;
      C.End_Line := Positive (Natural (Id) + 40);
      C.End_Column := 35;
      return C;
   end Base_Context;

   function Final_Model return Final_Diag.Final_Diagnostic_Model is
      Contexts : Final_Diag.Final_Diagnostic_Context_Model;
      Legal : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (1,
           Final_Diag.Final_Diagnostic_Overload_Type,
           Editor.Ada_Syntax_Tree.Node_Id (119801));
      Cross : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (2,
           Final_Diag.Final_Diagnostic_Cross_Unit,
           Editor.Ada_Syntax_Tree.Node_Id (119802));
      Generic_Ctx : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (3,
           Final_Diag.Final_Diagnostic_Generic_Replay,
           Editor.Ada_Syntax_Tree.Node_Id (119803));
      Flow : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (4,
           Final_Diag.Final_Diagnostic_Flow_Contract,
           Editor.Ada_Syntax_Tree.Node_Id (119804));
      Multiple : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (5,
           Final_Diag.Final_Diagnostic_Multiple,
           Editor.Ada_Syntax_Tree.Node_Id (119805));
      Stale : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (6,
           Final_Diag.Final_Diagnostic_Tasking_Protected,
           Editor.Ada_Syntax_Tree.Node_Id (119806));
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

   procedure Build_Models
     (Search    : out Final_Index.Final_Search_Index_Model;
      Provenance : out Final_Prov.Final_Provenance_Model) is
      Final : constant Final_Diag.Final_Diagnostic_Model := Final_Model;
      Feed_Model : constant SF.Semantic_Diagnostic_Feed_Model :=
        SF.Build_With_Final_Semantic_Diagnostics (Current_Guard, Final);
      Index_Model : constant SI.Semantic_Diagnostic_Index_Model := SI.Build (Feed_Model);
      Base_Model : constant Base_Prov.Diagnostic_Provenance_Model := Base_Prov.Build (Index_Model);
   begin
      Provenance := Final_Prov.Build_With_Base_Provenance (Final, Feed_Model, Index_Model, Base_Model);
      Search := Final_Index.Build (Provenance);
   end Build_Models;

   function Trace_Model return Trace.Final_Blocker_Trace_Model is
      Search : Final_Index.Final_Search_Index_Model;
      Provenance : Final_Prov.Final_Provenance_Model;
   begin
      Build_Models (Search, Provenance);
      return Trace.Build_With_Provenance (Search, Provenance);
   end Trace_Model;

   procedure Trace_Closure_Preserves_Blocker_Family_Roots
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Trace.Final_Blocker_Trace_Model := Trace_Model;
      Cross : constant Trace.Final_Blocker_Trace_Set :=
        Trace.Query_Blocker (Model, Final_Prov.Final_Blocker_Cross_Unit);
      Generic_Ctx : constant Trace.Final_Blocker_Trace_Set :=
        Trace.Query_Blocker (Model, Final_Prov.Final_Blocker_Generic_Replay);
      Flow : constant Trace.Final_Blocker_Trace_Set :=
        Trace.Query_Root (Model, Trace.Final_Trace_Root_Flow_Contract);
   begin
      Assert (Trace.Trace_Count (Model) = Final_Diag.Row_Count (Final_Model),
              "trace closure should preserve one trace per final semantic provenance row");
      Assert (Trace.Set_Count (Cross) = 1,
              "cross-unit final blocker should remain traceable by blocker family");
      Assert (Trace.Set_At (Cross, 1).Root = Trace.Final_Trace_Root_Cross_Unit,
              "cross-unit blocker should map to a cross-unit trace root");
      Assert (Trace.Set_Count (Generic_Ctx) = 1,
              "generic replay blocker should remain traceable");
      Assert (Trace.Set_At (Generic_Ctx, 1).Root = Trace.Final_Trace_Root_Generic_Replay,
              "generic replay blocker should map to a generic trace root");
      Assert (Trace.Set_Count (Flow) = 1,
              "flow/contract root query should recover the flow blocker");
      Assert (Trace.Multiple_Blocker_Trace_Count (Model) = 1,
              "multiple final blockers should remain explicit trace roots");
      Assert (Trace.Stale_Trace_Count (Model) = 1,
              "stale final rows should remain traceable as stale rows");
      Assert (Trace.Fingerprint (Model) /= 0,
              "trace closure fingerprint should include final blocker chains");
   end Trace_Closure_Preserves_Blocker_Family_Roots;

   procedure Trace_Closure_Supports_Node_Position_And_Link_Chains
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Trace.Final_Blocker_Trace_Model := Trace_Model;
      Node_Hits : constant Trace.Final_Blocker_Trace_Set :=
        Trace.Query_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (119802));
      Pos_Hits : constant Trace.Final_Blocker_Trace_Set :=
        Trace.Query_Position (Model, 42, 8);
      Fingerprint_Hits : constant Trace.Final_Blocker_Trace_Set :=
        Trace.Query_Source_Fingerprint (Model, 2 * 1198);
   begin
      Assert (Trace.Set_Count (Node_Hits) = 1,
              "node query should recover one cross-unit trace");
      Assert
        (Trace.Set_At (Node_Hits, 1).Blocker_Family = Final_Prov.Final_Blocker_Cross_Unit,
         "node trace should preserve final blocker family");
      Assert (Trace.Set_Count (Pos_Hits) = 1,
              "position query should identify exactly one trace span");
      Assert (Trace.Set_Count (Fingerprint_Hits) = 1,
              "source fingerprint should recover the matching trace chain");
      Assert (Trace.Set_At (Fingerprint_Hits, 1).Search_Link.Search_Index_Row /= 0,
              "trace should retain search-index row link");
      Assert (Trace.Feed_Link_Trace_Count (Model) >= 4,
              "emitted semantic blocker traces should retain feed links");
      Assert (Trace.Index_Link_Trace_Count (Model) >= 4,
              "emitted semantic blocker traces should retain diagnostic-index links");
      Assert (Trace.Count_Status (Model, Trace.Final_Trace_Emitted_Error) >= 3,
              "hard final semantic blockers should remain error traces");
   end Trace_Closure_Supports_Node_Position_And_Link_Chains;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Trace_Closure_Preserves_Blocker_Family_Roots'Access,
         "final semantic blocker trace closure preserves blocker roots");
      Register_Routine
        (T,
         Trace_Closure_Supports_Node_Position_And_Link_Chains'Access,
         "final semantic blocker trace closure supports node/span/link chains");
   end Register_Tests;

end Test_Ada_Final_Semantic_Blocker_Trace_Closure;
