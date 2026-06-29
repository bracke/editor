with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Integrated_Semantic_Closure;
with Editor.Ada_Semantic_Colour_Projection;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Integrated_Semantic_Diagnostic_Feed is

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
      return AUnit.Format ("Test_Ada_Integrated_Semantic_Diagnostic_Feed");
   end Name;

   function Current_Guard return SG.Guarded_Semantic_Diagnostic_Model is
      Projection : SC.Semantic_Colour_Model;
      Key : constant SG.Diagnostic_Snapshot_Key :=
        SG.Make_Key ("integrated.adb", 1119, 20, 30, 40, SC.Fingerprint (Projection));
   begin
      return SG.Build (Key, Key, Projection);
   end Current_Guard;

   function Rejected_Guard return SG.Guarded_Semantic_Diagnostic_Model is
      Projection : SC.Semantic_Colour_Model;
      Produced : constant SG.Diagnostic_Snapshot_Key :=
        SG.Make_Key ("integrated.adb", 1119, 20, 30, 40, SC.Fingerprint (Projection));
      Current : constant SG.Diagnostic_Snapshot_Key :=
        SG.Make_Key ("integrated.adb", 1120, 20, 30, 40, SC.Fingerprint (Projection));
   begin
      return SG.Build (Produced, Current, Projection);
   end Rejected_Guard;

   function Closure_Model return ISC.Integrated_Closure_Model is
      Contexts : ISC.Integrated_Closure_Context_Model;
      C        : ISC.Integrated_Closure_Context_Info;
   begin
      C.Id := 1;
      C.Kind := ISC.Closure_Context_Package_Spec;
      C.Unit_Name := To_Unbounded_String ("Root");
      C.Normalized_Unit_Name := To_Unbounded_String ("root");
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111901);
      C.Dependency := ISC.Dependency_Local_Only;
      C.Start_Line := 1;
      C.Start_Column := 1;
      C.End_Line := 1;
      C.End_Column := 10;
      ISC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := ISC.Closure_Context_Expression;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111902);
      C.Dependency := ISC.Dependency_Closed;
      C.Overload_Error := True;
      C.Start_Line := 12;
      C.Start_Column := 4;
      C.End_Line := 12;
      C.End_Column := 20;
      ISC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := ISC.Closure_Context_Generic_Instance;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111903);
      C.Dependency := ISC.Dependency_Missing;
      C.Dependency_Name := To_Unbounded_String ("Missing.Unit");
      C.Normalized_Dependency := To_Unbounded_String ("missing.unit");
      C.Start_Line := 18;
      C.Start_Column := 1;
      C.End_Line := 18;
      C.End_Column := 24;
      ISC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := ISC.Closure_Context_Representation_Item;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111904);
      C.Dependency := ISC.Dependency_Closed;
      C.Representation_Error := True;
      C.Start_Line := 24;
      C.Start_Column := 1;
      C.End_Line := 24;
      C.End_Column := 32;
      ISC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := ISC.Closure_Context_Private_Part;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111905);
      C.Dependency := ISC.Dependency_Private_View;
      C.Start_Line := 30;
      C.Start_Column := 7;
      C.End_Line := 30;
      C.End_Column := 17;
      ISC.Add_Context (Contexts, C);

      return ISC.Build (Contexts);
   end Closure_Model;

   procedure Integrated_Closure_Diagnostics_Are_Fed_And_Indexed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Closure : constant ISC.Integrated_Closure_Model := Closure_Model;
      Feed    : constant SF.Semantic_Diagnostic_Feed_Model :=
        SF.Build_With_Integrated_Closure (Current_Guard, Closure);
      Index   : constant SI.Semantic_Diagnostic_Index_Model := SI.Build (Feed);
      Overload_Rows : constant SI.Semantic_Diagnostic_Query_Set :=
        SI.Query_Node (Index, Editor.Ada_Syntax_Tree.Node_Id (111902));
      Position_Rows : constant SI.Semantic_Diagnostic_Query_Set :=
        SI.Query_Position (Index, 24, 12);
   begin
      Assert (SF.Current (Feed),
              "current integrated closure input should keep the diagnostic feed current");
      Assert (SF.Entry_Count (Feed) = ISC.Closure_Count (Closure) - ISC.Legal_Count (Closure),
              "only non-legal integrated closure rows should become active diagnostics");
      Assert (SF.Error_Count (Feed) >= 3,
              "overload, dependency, and representation blockers should be errors");
      Assert (SF.Warning_Count (Feed) >= 1,
              "private view closure barriers should be warnings");
      Assert (SF.Count_Source (Feed, SC.Semantic_Colour_From_Expression) >= 1,
              "expression semantic closure blockers should map to expression diagnostics");
      Assert (SF.Count_Source (Feed, SC.Semantic_Colour_From_Cross_Unit) >= 1,
              "dependency closure blockers should map to cross-unit diagnostics");
      Assert (SF.Count_Source (Feed, SC.Semantic_Colour_From_Representation) >= 1,
              "representation closure blockers should map to representation diagnostics");
      Assert (SI.Entry_Count (Index) = SF.Entry_Count (Feed),
              "the existing diagnostic index should consume integrated closure diagnostics");
      Assert (SI.Query_Count (Overload_Rows) = 1,
              "node lookup should find the integrated overload closure diagnostic");
      Assert (SI.Query_Count (Position_Rows) = 1,
              "position lookup should find the integrated representation closure diagnostic");
      Assert (SF.Fingerprint (Feed) /= 0 and then SI.Fingerprint (Index) /= 0,
              "feed and index fingerprints should include integrated semantic closure rows");
   end Integrated_Closure_Diagnostics_Are_Fed_And_Indexed;

   procedure Stale_Integrated_Closure_Input_Withholds_Active_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Closure : constant ISC.Integrated_Closure_Model := Closure_Model;
      Feed    : constant SF.Semantic_Diagnostic_Feed_Model :=
        SF.Build_With_Integrated_Closure
          (Current_Guard, Closure,
           Closure_Input_Current => False,
           Closure_Rejected_Count => ISC.Closure_Count (Closure));
   begin
      Assert (SF.Rejected_Stale (Feed),
              "stale integrated closure input should reject the unified feed");
      Assert (SF.Entry_Count (Feed) = 0,
              "stale integrated closure input should expose no active feed entries");
      Assert (SF.Rejected_Entry_Count (Feed) = ISC.Closure_Count (Closure),
              "stale integrated closure input should preserve rejected totals");
   end Stale_Integrated_Closure_Input_Withholds_Active_Rows;

   procedure Stale_Base_Guard_Withholds_Integrated_Closure_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Closure : constant ISC.Integrated_Closure_Model := Closure_Model;
      Feed    : constant SF.Semantic_Diagnostic_Feed_Model :=
        SF.Build_With_Integrated_Closure
          (Rejected_Guard, Closure,
           Closure_Rejected_Count => ISC.Closure_Count (Closure));
   begin
      Assert (SF.Rejected_Stale (Feed),
              "rejected base snapshot guard should reject the integrated closure feed");
      Assert (SF.Entry_Count (Feed) = 0,
              "rejected base snapshot guard should withhold integrated closure diagnostics");
      Assert (SF.Rejected_Entry_Count (Feed) >= ISC.Closure_Count (Closure),
              "rejected base snapshot guard should preserve integrated closure rejected accounting");
   end Stale_Base_Guard_Withholds_Integrated_Closure_Rows;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Integrated_Closure_Diagnostics_Are_Fed_And_Indexed'Access,
         "integrated semantic closure diagnostics enter unified feed and index");
      Register_Routine
        (T, Stale_Integrated_Closure_Input_Withholds_Active_Rows'Access,
         "stale integrated closure input is withheld from active feed rows");
      Register_Routine
        (T, Stale_Base_Guard_Withholds_Integrated_Closure_Rows'Access,
         "rejected base semantic guards withhold integrated closure feed entries");
   end Register_Tests;

end Test_Ada_Integrated_Semantic_Diagnostic_Feed;
