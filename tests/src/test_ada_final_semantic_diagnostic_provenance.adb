with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit; use AUnit;
with Editor.Ada_Diagnostic_Provenance;
with Editor.Ada_Final_Semantic_Diagnostic_Integration;
with Editor.Ada_Final_Semantic_Diagnostic_Provenance;
with Editor.Ada_Semantic_Colour_Projection;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Final_Semantic_Diagnostic_Provenance is

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

   function Name (T : Test_Case) return Message_String is
      pragma Unreferenced (T);
   begin
      return Format ("Test_Ada_Final_Semantic_Diagnostic_Provenance");
   end Name;

   function Current_Guard return SG.Guarded_Semantic_Diagnostic_Model is
      Projection : SC.Semantic_Colour_Model;
      Key : constant SG.Diagnostic_Snapshot_Key :=
        SG.Make_Key ("final-provenance.adb", 1196, 21, 31, 41, SC.Fingerprint (Projection));
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
      C.Source_Fingerprint := Natural (Id) * 1196;
      C.Expected_Source_Fingerprint := Natural (Id) * 1196;
      C.Message := To_Unbounded_String ("final semantic provenance context");
      C.Start_Line := Positive (Natural (Id) + 20);
      C.Start_Column := 4;
      C.End_Line := Positive (Natural (Id) + 20);
      C.End_Column := 26;
      return C;
   end Base_Context;

   function Final_Model return Final_Diag.Final_Diagnostic_Model is
      Contexts : Final_Diag.Final_Diagnostic_Context_Model;
      Legal : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (1,
           Final_Diag.Final_Diagnostic_Overload_Type,
           Editor.Ada_Syntax_Tree.Node_Id (119601));
      Cross : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (2,
           Final_Diag.Final_Diagnostic_Cross_Unit,
           Editor.Ada_Syntax_Tree.Node_Id (119602));
      Generic_Ctx : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (3,
           Final_Diag.Final_Diagnostic_Generic_Replay,
           Editor.Ada_Syntax_Tree.Node_Id (119603));
      Representation : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (4,
           Final_Diag.Final_Diagnostic_Representation_Freezing,
           Editor.Ada_Syntax_Tree.Node_Id (119604));
      Multiple : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (5,
           Final_Diag.Final_Diagnostic_Multiple,
           Editor.Ada_Syntax_Tree.Node_Id (119605));
      Stale : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (6,
           Final_Diag.Final_Diagnostic_Tasking_Protected,
           Editor.Ada_Syntax_Tree.Node_Id (119606));
   begin
      Cross.Cross_Unit_Status := Cross_Final.Cross_Unit_Final_Missing_Dependency;
      Generic_Ctx.Generic_Status := Generic_Final.Nested_Generic_Recursive_Instantiation_Cycle;
      Representation.Representation_Status :=
        Representation_Final.Final_Representation_Generic_Formal_Freezing_Blocker;
      Multiple.Cross_Unit_Status := Cross_Final.Cross_Unit_Final_Missing_Dependency;
      Multiple.Tasking_Status := Tasking_Final.Deep_Tasking_Indirect_Reentrancy_Blocker;
      Multiple.Flow_Status := Flow_Final.Flow_Contract_Proof_Abstract_State_Missing;
      Stale.Input_Current := False;

      Final_Diag.Add_Context (Contexts, Legal);
      Final_Diag.Add_Context (Contexts, Cross);
      Final_Diag.Add_Context (Contexts, Generic_Ctx);
      Final_Diag.Add_Context (Contexts, Representation);
      Final_Diag.Add_Context (Contexts, Multiple);
      Final_Diag.Add_Context (Contexts, Stale);
      return Final_Diag.Build (Contexts);
   end Final_Model;

   procedure Provenance_Preserves_Final_Blocker_Families
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Final : constant Final_Diag.Final_Diagnostic_Model := Final_Model;
      Model : constant Final_Prov.Final_Provenance_Model := Final_Prov.Build (Final);
      Cross_Row : constant Final_Prov.Final_Provenance_Info :=
        Final_Prov.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (119602));
   begin
      Assert (Final_Prov.Row_Count (Model) = Final_Diag.Row_Count (Final),
              "final provenance should preserve one row per final diagnostic row");
      Assert (Final_Prov.Withheld_Count (Model) = Final_Diag.Withheld_Legal_Count (Final),
              "withheld legal final rows must remain traceable");
      Assert (Final_Prov.Count_Blocker (Model, Final_Prov.Final_Blocker_Cross_Unit) = 1,
              "cross-unit final blocker family must be preserved");
      Assert (Final_Prov.Count_Blocker (Model, Final_Prov.Final_Blocker_Generic_Replay) = 1,
              "generic replay final blocker family must be preserved");
      Assert (Final_Prov.Count_Blocker (Model, Final_Prov.Final_Blocker_Representation_Freezing) = 1,
              "representation/freezing final blocker family must be preserved");
      Assert (Final_Prov.Multiple_Blocker_Count (Model) = 1,
              "multiple final blockers must remain explicit");
      Assert (Final_Prov.Stale_Rejected_Count (Model) = 1,
              "stale final rows must remain rejected in provenance");
      Assert (Cross_Row.Blocker_Family = Final_Prov.Final_Blocker_Cross_Unit,
              "node lookup should recover the cross-unit final blocker provenance");
      Assert (Final_Prov.Fingerprint (Model) /= 0,
              "final provenance fingerprint should include all blocker-family rows");
   end Provenance_Preserves_Final_Blocker_Families;

   procedure Provenance_Links_Final_Feed_Index_And_Base_Chain
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Final : constant Final_Diag.Final_Diagnostic_Model := Final_Model;
      Feed_Model : constant SF.Semantic_Diagnostic_Feed_Model :=
        SF.Build_With_Final_Semantic_Diagnostics (Current_Guard, Final);
      Index_Model : constant SI.Semantic_Diagnostic_Index_Model := SI.Build (Feed_Model);
      Base_Model : constant Base_Prov.Diagnostic_Provenance_Model := Base_Prov.Build (Index_Model);
      Model : constant Final_Prov.Final_Provenance_Model :=
        Final_Prov.Build_With_Base_Provenance (Final, Feed_Model, Index_Model, Base_Model);
   begin
      Assert (Final_Prov.Feed_Link_Count (Model) = SF.Entry_Count (Feed_Model),
              "emitted final diagnostics should link back to feed entries");
      Assert (Final_Prov.Index_Link_Count (Model) = SI.Entry_Count (Index_Model),
              "emitted final diagnostics should link back to index entries");
      Assert (Final_Prov.Base_Link_Count (Model) = Base_Prov.Item_Count (Base_Model),
              "emitted final diagnostics should link back to base provenance items");
      Assert
        (Final_Prov.Count_Stage (Model, Final_Prov.Final_Stage_Base_Provenance) =
         Base_Prov.Item_Count (Base_Model),
         "base provenance stage should be preserved for linked final diagnostics");
      Assert
        (Final_Prov.Count_Stage (Model, Final_Prov.Final_Stage_Withheld_Legal) =
         Final_Diag.Withheld_Legal_Count (Final),
         "withheld legal rows should stay out of feed/index/base provenance");
      Assert (Final_Prov.Error_Count (Model) >= 4,
              "semantic blockers should remain error provenance rows");
   end Provenance_Links_Final_Feed_Index_And_Base_Chain;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Provenance_Preserves_Final_Blocker_Families'Access,
         "final semantic provenance preserves real blocker families");
      Register_Routine
        (T,
         Provenance_Links_Final_Feed_Index_And_Base_Chain'Access,
         "final semantic provenance links feed index and base provenance chain");
   end Register_Tests;

end Test_Ada_Final_Semantic_Diagnostic_Provenance;
