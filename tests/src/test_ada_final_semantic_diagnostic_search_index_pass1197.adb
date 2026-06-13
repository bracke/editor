with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit; use AUnit;
with Editor.Ada_Diagnostic_Provenance;
with Editor.Ada_Final_Semantic_Diagnostic_Integration;
with Editor.Ada_Final_Semantic_Diagnostic_Provenance;
with Editor.Ada_Final_Semantic_Diagnostic_Search_Index;
with Editor.Ada_Semantic_Colour_Projection;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Final_Semantic_Diagnostic_Search_Index_Pass1197 is

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
   use type Final_Prov.Final_Provenance_Stage;
   use type SF.Semantic_Diagnostic_Feed_Id;
   use type SI.Semantic_Diagnostic_Index_Id;

   function Name (T : Test_Case) return Message_String is
      pragma Unreferenced (T);
   begin
      return Format ("Test_Ada_Final_Semantic_Diagnostic_Search_Index_Pass1197");
   end Name;

   function Current_Guard return SG.Guarded_Semantic_Diagnostic_Model is
      Projection : SC.Semantic_Colour_Model;
      Key : constant SG.Diagnostic_Snapshot_Key :=
        SG.Make_Key ("final-search-index.adb", 1197, 22, 32, 42, SC.Fingerprint (Projection));
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
      C.Source_Fingerprint := Natural (Id) * 1197;
      C.Expected_Source_Fingerprint := Natural (Id) * 1197;
      C.Message := To_Unbounded_String ("final semantic search index context");
      C.Start_Line := Positive (Natural (Id) + 30);
      C.Start_Column := 5;
      C.End_Line := Positive (Natural (Id) + 30);
      C.End_Column := 31;
      return C;
   end Base_Context;

   function Final_Model return Final_Diag.Final_Diagnostic_Model is
      Contexts : Final_Diag.Final_Diagnostic_Context_Model;
      Legal : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (1,
           Final_Diag.Final_Diagnostic_Overload_Type,
           Editor.Ada_Syntax_Tree.Node_Id (119701));
      Cross : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (2,
           Final_Diag.Final_Diagnostic_Cross_Unit,
           Editor.Ada_Syntax_Tree.Node_Id (119702));
      Generic_Ctx : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (3,
           Final_Diag.Final_Diagnostic_Generic_Replay,
           Editor.Ada_Syntax_Tree.Node_Id (119703));
      Flow : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (4,
           Final_Diag.Final_Diagnostic_Flow_Contract,
           Editor.Ada_Syntax_Tree.Node_Id (119704));
      Multiple : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (5,
           Final_Diag.Final_Diagnostic_Multiple,
           Editor.Ada_Syntax_Tree.Node_Id (119705));
      Stale : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (6,
           Final_Diag.Final_Diagnostic_Tasking_Protected,
           Editor.Ada_Syntax_Tree.Node_Id (119706));
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

   function Search_Model return Final_Index.Final_Search_Index_Model is
      Final : constant Final_Diag.Final_Diagnostic_Model := Final_Model;
      Feed_Model : constant SF.Semantic_Diagnostic_Feed_Model :=
        SF.Build_With_Final_Semantic_Diagnostics (Current_Guard, Final);
      Index_Model : constant SI.Semantic_Diagnostic_Index_Model := SI.Build (Feed_Model);
      Base_Model : constant Base_Prov.Diagnostic_Provenance_Model := Base_Prov.Build (Index_Model);
      Provenance : constant Final_Prov.Final_Provenance_Model :=
        Final_Prov.Build_With_Base_Provenance (Final, Feed_Model, Index_Model, Base_Model);
   begin
      return Final_Index.Build (Provenance);
   end Search_Model;

   procedure Search_Index_Preserves_Blocker_Family_Queries
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Final_Index.Final_Search_Index_Model := Search_Model;
      Cross_Hits : constant Final_Index.Final_Search_Result_Set :=
        Final_Index.Query_Blocker (Model, Final_Prov.Final_Blocker_Cross_Unit);
      Generic_Hits : constant Final_Index.Final_Search_Result_Set :=
        Final_Index.Query_Blocker (Model, Final_Prov.Final_Blocker_Generic_Replay);
      Flow_Hits : constant Final_Index.Final_Search_Result_Set :=
        Final_Index.Query_Blocker (Model, Final_Prov.Final_Blocker_Flow_Contract);
      Node_Hits : constant Final_Index.Final_Search_Result_Set :=
        Final_Index.Query_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (119702));
   begin
      Assert (Final_Index.Current (Model),
              "final semantic search index should be current for current provenance");
      Assert (Final_Index.Entry_Count (Model) = Final_Diag.Row_Count (Final_Model),
              "search index should preserve one row per final provenance row");
      Assert (Final_Index.Query_Count (Cross_Hits) = 1,
              "cross-unit blocker should be queryable by blocker family");
      Assert (Final_Index.Query_Count (Generic_Hits) = 1,
              "generic replay blocker should be queryable by blocker family");
      Assert (Final_Index.Query_Count (Flow_Hits) = 1,
              "flow/contract blocker should be queryable by blocker family");
      Assert (Final_Index.Multiple_Blocker_Count (Model) = 1,
              "multiple blocker rows should remain explicit in the search index");
      Assert (Final_Index.Stale_Rejected_Count (Model) = 1,
              "stale final rows should stay searchable as rejected provenance rows");
      Assert (Final_Index.Query_Count (Node_Hits) = 1,
              "node query should recover the cross-unit blocker row");
      Assert
        (Final_Index.Query_At (Node_Hits, 1).Feed_Item.Blocker_Family =
         Final_Prov.Final_Blocker_Cross_Unit,
         "node query should preserve final blocker family");
      Assert (Final_Index.Fingerprint (Model) /= 0,
              "search index fingerprint should include blocker family and provenance rows");
   end Search_Index_Preserves_Blocker_Family_Queries;

   procedure Search_Index_Supports_Span_Fingerprint_And_Link_Queries
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Final_Index.Final_Search_Index_Model := Search_Model;
      Range_Hits : constant Final_Index.Final_Search_Result_Set :=
        Final_Index.Query_Range (Model, 31, 36);
      Pos_Hits : constant Final_Index.Final_Search_Result_Set :=
        Final_Index.Query_Position (Model, 32, 6);
      Fingerprint_Hits : constant Final_Index.Final_Search_Result_Set :=
        Final_Index.Query_Source_Fingerprint (Model, 2 * 1197);
      First_Emitted : Final_Index.Final_Search_Entry := (others => <>);
   begin
      Assert (Final_Index.Query_Count (Range_Hits) = Final_Index.Entry_Count (Model),
              "range query should find all seeded final semantic rows");
      Assert (Final_Index.Query_Count (Pos_Hits) = 1,
              "position query should find only the row covering that span");
      Assert (Final_Index.Query_Count (Fingerprint_Hits) = 1,
              "source fingerprint query should find the exact final semantic row");
      Assert
        (Final_Index.Has_Blocker_At
           (Model, 32, 6, Final_Prov.Final_Blocker_Cross_Unit),
         "combined position/blocker lookup should identify cross-unit blockers");
      Assert
        (Final_Index.Count_Stage (Model, Final_Prov.Final_Stage_Base_Provenance) >= 4,
         "feed/index/base provenance linked rows should retain base-provenance stage");

      for I in 1 .. Final_Index.Entry_Count (Model) loop
         declare
            Feed_Item : constant Final_Index.Final_Search_Entry := Final_Index.Entry_At (Model, I);
         begin
            if Feed_Item.Feed_Entry /= SF.No_Semantic_Diagnostic_Feed_Entry then
               First_Emitted := Feed_Item;
               exit;
            end if;
         end;
      end loop;

      Assert (First_Emitted.Feed_Entry /= SF.No_Semantic_Diagnostic_Feed_Entry,
              "test fixture should contain at least one emitted final diagnostic");
      Assert
        (Final_Index.Query_Count
           (Final_Index.Query_Feed_Link (Model, First_Emitted.Feed_Entry)) = 1,
         "feed-link query should recover the final semantic row");
      Assert
        (Final_Index.Query_Count
           (Final_Index.Query_Index_Link (Model, First_Emitted.Index_Entry)) = 1,
         "index-link query should recover the final semantic row");
      Assert (Final_Index.Feed_Link_Count (Model) >= 4,
              "emitted blocker rows should have feed links");
      Assert (Final_Index.Index_Link_Count (Model) >= 4,
              "emitted blocker rows should have index links");
   end Search_Index_Supports_Span_Fingerprint_And_Link_Queries;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Search_Index_Preserves_Blocker_Family_Queries'Access,
         "final semantic search index preserves blocker-family queries");
      Register_Routine
        (T,
         Search_Index_Supports_Span_Fingerprint_And_Link_Queries'Access,
         "final semantic search index supports span fingerprint and link queries");
   end Register_Tests;

end Test_Ada_Final_Semantic_Diagnostic_Search_Index_Pass1197;
