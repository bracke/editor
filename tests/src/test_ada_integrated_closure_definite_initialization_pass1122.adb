with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Definite_Initialization_Flow_Legality;
with Editor.Ada_Integrated_Semantic_Closure;
with Editor.Ada_Integrated_Semantic_Closure.Definite_Initialization;
with Editor.Ada_Semantic_Colour_Projection;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
with Editor.Ada_Diagnostic_Provenance;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Integrated_Closure_Definite_Initialization_Pass1122 is

   package DIF renames Editor.Ada_Definite_Initialization_Flow_Legality;
   use type DIF.Assignment_Legality_Id;
   use type DIF.Assignment_Legality_Status;
   use type DIF.Return_Legality_Id;
   use type DIF.Return_Legality_Status;
   use type DIF.Control_Flow_Legality_Id;
   use type DIF.Control_Flow_Legality_Status;
   use type DIF.Exception_Finalization_Legality_Id;
   use type DIF.Exception_Finalization_Legality_Status;
   use type DIF.Integrated_Closure_Id;
   use type DIF.Integrated_Closure_Status;
   use type DIF.Initialization_Context_Id;
   use type DIF.Initialization_Legality_Id;
   use type DIF.Initialization_Context_Kind;
   use type DIF.Object_State;
   use type DIF.Flow_State;
   use type DIF.Initialization_Legality_Status;
   use type DIF.Initialization_Context_Info;
   use type DIF.Initialization_Legality_Info;
   use type DIF.Initialization_Context_Model;
   use type DIF.Initialization_Legality_Model;
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
   package ICD renames Editor.Ada_Integrated_Semantic_Closure.Definite_Initialization;
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

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Integrated_Closure_Definite_Initialization_Pass1122");
   end Name;

   function Current_Guard return SG.Guarded_Semantic_Diagnostic_Model is
      Projection : SC.Semantic_Colour_Model;
      Key : constant SG.Diagnostic_Snapshot_Key :=
        SG.Make_Key ("definite_initialization.adb", 1122, 20, 30, 40,
                     SC.Fingerprint (Projection));
   begin
      return SG.Build (Key, Key, Projection);
   end Current_Guard;

   function Initialization_Model return DIF.Initialization_Legality_Model is
      Contexts : DIF.Initialization_Context_Model;
      C        : DIF.Initialization_Context_Info;
   begin
      C.Id := 1;
      C.Kind := DIF.Initialization_Context_Object_Declaration;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112201);
      C.Object_Name := To_Unbounded_String ("Ready");
      C.Has_Explicit_Init := True;
      C.After_State := DIF.Object_State_Definitely_Initialized;
      C.Start_Line := 3;
      C.Start_Column := 4;
      C.End_Line := 3;
      C.End_Column := 20;
      DIF.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := DIF.Initialization_Context_Read;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112202);
      C.Object_Node := Editor.Ada_Syntax_Tree.Node_Id (112220);
      C.Object_Name := To_Unbounded_String ("Unwritten");
      C.Reads_Object := True;
      C.Requires_Definite_Init := True;
      C.Before_State := DIF.Object_State_Uninitialized;
      C.Start_Line := 7;
      C.Start_Column := 10;
      C.End_Line := 7;
      C.End_Column := 25;
      DIF.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := DIF.Initialization_Context_Parameter_Out;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112203);
      C.Object_Name := To_Unbounded_String ("Out_Value");
      C.Must_Assign_Out := True;
      C.Writes_Object := False;
      C.Start_Line := 11;
      C.Start_Column := 5;
      C.End_Line := 11;
      C.End_Column := 19;
      DIF.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := DIF.Initialization_Context_Loop_Merge;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112204);
      C.Object_Name := To_Unbounded_String ("Maybe");
      C.Flow := DIF.Flow_State_Loop_Carried;
      C.After_State := DIF.Object_State_Conditionally_Initialized;
      C.Start_Line := 15;
      C.Start_Column := 1;
      C.End_Line := 15;
      C.End_Column := 30;
      DIF.Add_Context (Contexts, C);

      return DIF.Build (Contexts);
   end Initialization_Model;

   procedure Initialization_Flow_Enters_Closure_Feed_Index_And_Provenance
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Base_Contexts : ISC.Integrated_Closure_Context_Model;
      Initialization : constant DIF.Initialization_Legality_Model := Initialization_Model;
      Closure : constant ISC.Integrated_Closure_Model :=
        ICD.Build_With_Definite_Initialization (Base_Contexts, Initialization);
      Feed : constant SF.Semantic_Diagnostic_Feed_Model :=
        SF.Build_With_Integrated_Closure (Current_Guard, Closure);
      Index : constant SI.Semantic_Diagnostic_Index_Model := SI.Build (Feed);
      Provenance : constant DP.Diagnostic_Provenance_Model :=
        DP.Build_With_Integrated_Closure (Index, Closure);
      Read_Row : constant ISC.Integrated_Closure_Info :=
        ISC.First_For_Node (Closure, Editor.Ada_Syntax_Tree.Node_Id (112202));
      Read_Index_Rows : constant SI.Semantic_Diagnostic_Query_Set :=
        SI.Query_Node (Index, Editor.Ada_Syntax_Tree.Node_Id (112202));
   begin
      Assert (ISC.Closure_Count (Closure) = DIF.Row_Count (Initialization),
              "all initialization rows are added to integrated closure");
      Assert (ISC.Legal_Count (Closure) = 1,
              "legal initialization proof remains a legal closure row");
      Assert (ISC.Count_Blocker (Closure, ISC.Closure_Blocker_Definite_Initialization) = 3,
              "failing initialization rows are first-class closure blockers");
      Assert (ISC.Count_Status (Closure, ISC.Integrated_Closure_Definite_Initialization_Blocker) = 3,
              "initialization blockers receive their own closure status");
      Assert (Read_Row.Status = ISC.Integrated_Closure_Definite_Initialization_Blocker,
              "read-before-write maps to an initialization closure blocker");
      Assert (SF.Entry_Count (Feed) = 3,
              "only failing initialization closure rows enter the feed");
      Assert (SF.Error_Count (Feed) = 3,
              "initialization flow blockers are hard semantic diagnostics");
      Assert (SI.Query_Count (Read_Index_Rows) = 1,
              "diagnostic index can find initialization blockers by node");
      Assert (DP.Integrated_Closure_Item_Count (Provenance) = SF.Entry_Count (Feed),
              "provenance links initialization diagnostics to closure rows");
      Assert (ISC.Fingerprint (Closure) /= 0 and then SF.Fingerprint (Feed) /= 0
                and then DP.Fingerprint (Provenance) /= 0,
              "closure, feed, and provenance fingerprints include initialization flow rows");
   end Initialization_Flow_Enters_Closure_Feed_Index_And_Provenance;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Initialization_Flow_Enters_Closure_Feed_Index_And_Provenance'Access,
         "definite initialization flow enters integrated closure diagnostics");
   end Register_Tests;

end Test_Ada_Integrated_Closure_Definite_Initialization_Pass1122;
