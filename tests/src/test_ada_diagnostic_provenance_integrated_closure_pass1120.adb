with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Diagnostic_Provenance;
with Editor.Ada_Integrated_Semantic_Closure;
with Editor.Ada_Semantic_Colour_Projection;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Diagnostic_Provenance_Integrated_Closure_Pass1120 is

   package DP renames Editor.Ada_Diagnostic_Provenance;
   use type DP.Feed_Entry;
   use type DP.Feed_Severity;
   use type DP.Feed_Source;
   use type DP.Index_Entry;
   use type DP.Diagnostic_Provenance_Id;
   use type DP.Diagnostic_Provenance_Status;
   use type DP.Diagnostic_Provenance_Stage;
   use type DP.Diagnostic_Provenance_Item;
   use type DP.Diagnostic_Provenance_Result_Set;
   use type DP.Diagnostic_Provenance_Model;
   package ISC renames Editor.Ada_Integrated_Semantic_Closure;
   use type ISC.Wide_Diagnostic_Status;
   use type ISC.Overload_Status;
   use type ISC.Static_Status;
   use type ISC.Accessibility_Status;
   use type ISC.Contract_Status;
   use type ISC.Elaboration_Status;
   use type ISC.Completion_Status;
   use type ISC.Renaming_Status;
   use type ISC.Exception_Status;
   use type ISC.Representation_Status;
   use type ISC.Refined_Global_Depends_Status;
   use type ISC.Integrated_Closure_Context_Id;
   use type ISC.Integrated_Closure_Id;
   use type ISC.Integrated_Closure_Context_Kind;
   use type ISC.Closure_Dependency_State;
   use type ISC.Closure_Blocker_Family;
   use type ISC.Integrated_Closure_Status;
   use type ISC.Integrated_Closure_Context_Info;
   use type ISC.Integrated_Closure_Info;
   use type ISC.Integrated_Closure_Context_Model;
   use type ISC.Integrated_Closure_Result_Set;
   use type ISC.Integrated_Closure_Model;
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

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Diagnostic_Provenance_Integrated_Closure_Pass1120");
   end Name;

   function Current_Guard return SG.Guarded_Semantic_Diagnostic_Model is
      Projection : SC.Semantic_Colour_Model;
      Key : constant SG.Diagnostic_Snapshot_Key :=
        SG.Make_Key ("provenance_integrated.adb", 1120, 20, 30, 40, SC.Fingerprint (Projection));
   begin
      return SG.Build (Key, Key, Projection);
   end Current_Guard;

   function Rejected_Guard return SG.Guarded_Semantic_Diagnostic_Model is
      Projection : SC.Semantic_Colour_Model;
      Produced : constant SG.Diagnostic_Snapshot_Key :=
        SG.Make_Key ("provenance_integrated.adb", 1120, 20, 30, 40, SC.Fingerprint (Projection));
      Current : constant SG.Diagnostic_Snapshot_Key :=
        SG.Make_Key ("provenance_integrated.adb", 1121, 20, 30, 40, SC.Fingerprint (Projection));
   begin
      return SG.Build (Produced, Current, Projection);
   end Rejected_Guard;

   function Closure_Model return ISC.Integrated_Closure_Model is
      Contexts : ISC.Integrated_Closure_Context_Model;
      C        : ISC.Integrated_Closure_Context_Info;
   begin
      C.Id := 1;
      C.Kind := ISC.Closure_Context_Expression;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112001);
      C.Dependency := ISC.Dependency_Closed;
      C.Overload_Error := True;
      C.Start_Line := 11;
      C.Start_Column := 3;
      C.End_Line := 11;
      C.End_Column := 18;
      ISC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := ISC.Closure_Context_Generic_Instance;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112002);
      C.Dependency := ISC.Dependency_Missing;
      C.Dependency_Name := To_Unbounded_String ("Missing.Unit");
      C.Normalized_Dependency := To_Unbounded_String ("missing.unit");
      C.Start_Line := 21;
      C.Start_Column := 1;
      C.End_Line := 21;
      C.End_Column := 23;
      ISC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := ISC.Closure_Context_Representation_Item;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112003);
      C.Dependency := ISC.Dependency_Closed;
      C.Representation_Error := True;
      C.Start_Line := 31;
      C.Start_Column := 2;
      C.End_Line := 31;
      C.End_Column := 30;
      ISC.Add_Context (Contexts, C);

      return ISC.Build (Contexts);
   end Closure_Model;

   procedure Integrated_Closure_Provenance_Links_Index_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Closure : constant ISC.Integrated_Closure_Model := Closure_Model;
      Feed    : constant SF.Semantic_Diagnostic_Feed_Model :=
        SF.Build_With_Integrated_Closure (Current_Guard, Closure);
      Index   : constant SI.Semantic_Diagnostic_Index_Model := SI.Build (Feed);
      Provenance : constant DP.Diagnostic_Provenance_Model :=
        DP.Build_With_Integrated_Closure (Index, Closure);
      First : constant DP.Diagnostic_Provenance_Item :=
        DP.First_For_Diagnostic
          (Provenance,
           SI.Entry_At (Index, 1).Id);
      Rows : constant DP.Diagnostic_Provenance_Result_Set :=
        DP.Items_For_Diagnostic (Provenance, SI.Entry_At (Index, 1).Id);
   begin
      Assert (DP.Current (Provenance),
              "integrated closure provenance should remain current for a current index");
      Assert (DP.Integrated_Closure_Item_Count (Provenance) = SF.Entry_Count (Feed),
              "each integrated closure feed diagnostic should receive closure provenance");
      Assert (DP.Count_Stage (Provenance, DP.Diagnostic_Provenance_Integrated_Closure) =
                DP.Integrated_Closure_Item_Count (Provenance),
              "integrated closure stage counter should track linked closure provenance");
      Assert (DP.Has_Item (First),
              "diagnostic provenance lookup should return the base diagnostic item");
      Assert (DP.Result_Count (Rows) >= 2,
              "diagnostic lookup should include base and integrated-closure provenance rows");
      Assert (DP.Item_Count (Provenance) >= SF.Entry_Count (Feed) * 2,
              "provenance model should preserve base rows and add closure explain rows");
      Assert (DP.Fingerprint (Provenance) /= 0,
              "integrated closure provenance should contribute to deterministic fingerprinting");
   end Integrated_Closure_Provenance_Links_Index_Diagnostics;

   procedure Rejected_Index_Withholds_Integrated_Closure_Provenance
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Closure : constant ISC.Integrated_Closure_Model := Closure_Model;
      Feed    : constant SF.Semantic_Diagnostic_Feed_Model :=
        SF.Build_With_Integrated_Closure
          (Rejected_Guard, Closure,
           Closure_Rejected_Count => ISC.Closure_Count (Closure));
      Index   : constant SI.Semantic_Diagnostic_Index_Model := SI.Build (Feed);
      Provenance : constant DP.Diagnostic_Provenance_Model :=
        DP.Build_With_Integrated_Closure (Index, Closure);
   begin
      Assert (DP.Rejected_Stale (Provenance),
              "rejected index should reject integrated closure provenance");
      Assert (DP.Item_Count (Provenance) = 0,
              "rejected index should expose no active provenance rows");
      Assert (DP.Integrated_Closure_Item_Count (Provenance) = 0,
              "rejected index should not add integrated closure provenance rows");
      Assert (DP.Rejected_Item_Count (Provenance) >= ISC.Closure_Count (Closure),
              "rejected provenance should preserve stale integrated closure accounting");
   end Rejected_Index_Withholds_Integrated_Closure_Provenance;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Integrated_Closure_Provenance_Links_Index_Diagnostics'Access,
         "integrated closure provenance links consolidated semantic diagnostics");
      Register_Routine
        (T, Rejected_Index_Withholds_Integrated_Closure_Provenance'Access,
         "rejected indexes withhold integrated closure provenance rows");
   end Register_Tests;

end Test_Ada_Diagnostic_Provenance_Integrated_Closure_Pass1120;
