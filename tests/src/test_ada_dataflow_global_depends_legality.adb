with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Contract_Aspect_Legality;
with Editor.Ada_Dataflow_Global_Depends_Legality;
with Editor.Ada_Definite_Initialization_Flow_Legality;
with Editor.Ada_Diagnostic_Provenance;
with Editor.Ada_Integrated_Semantic_Closure;
with Editor.Ada_Integrated_Semantic_Closure.Dataflow;
with Editor.Ada_Semantic_Colour_Projection;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Dataflow_Global_Depends_Legality is

   package CA renames Editor.Ada_Contract_Aspect_Legality;
   use type CA.Assignment_Legality_Status;
   use type CA.Return_Legality_Status;
   use type CA.Static_Legality_Status;
   use type CA.Accessibility_Legality_Status;
   use type CA.Overload_Legality_Status;
   use type CA.Cross_Unit_Semantic_Status;
   use type CA.Contract_Context_Id;
   use type CA.Contract_Legality_Id;
   use type CA.Contract_Context_Kind;
   use type CA.Contract_Subject_Kind;
   use type CA.Boolean_Expression_State;
   use type CA.Aspect_Placement;
   use type CA.Flow_Contract_State;
   use type CA.Contract_Legality_Status;
   use type CA.Contract_Context_Info;
   use type CA.Contract_Legality_Info;
   use type CA.Contract_Context_Model;
   use type CA.Contract_Result_Set;
   use type CA.Contract_Legality_Model;
   package DGL renames Editor.Ada_Dataflow_Global_Depends_Legality;
   use type DGL.Contract_Legality_Status;
   use type DGL.Flow_Contract_State;
   use type DGL.Initialization_Legality_Status;
   use type DGL.Object_State;
   use type DGL.Dataflow_Context_Id;
   use type DGL.Dataflow_Legality_Id;
   use type DGL.Dataflow_Context_Kind;
   use type DGL.Dataflow_Effect_Kind;
   use type DGL.Global_Mode;
   use type DGL.Dependency_State;
   use type DGL.Dataflow_Legality_Status;
   use type DGL.Dataflow_Context_Info;
   use type DGL.Dataflow_Legality_Info;
   use type DGL.Dataflow_Context_Model;
   use type DGL.Dataflow_Result_Set;
   use type DGL.Dataflow_Legality_Model;
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
   package ICD renames Editor.Ada_Integrated_Semantic_Closure.Dataflow;
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
      return AUnit.Format ("Test_Ada_Dataflow_Global_Depends_Legality");
   end Name;

   function Current_Guard return SG.Guarded_Semantic_Diagnostic_Model is
      Projection : SC.Semantic_Colour_Model;
      Key : constant SG.Diagnostic_Snapshot_Key :=
        SG.Make_Key ("global_depends.adb", 1123, 21, 31, 41,
                     SC.Fingerprint (Projection));
   begin
      return SG.Build (Key, Key, Projection);
   end Current_Guard;

   function Dataflow_Model return DGL.Dataflow_Legality_Model is
      Contexts : DGL.Dataflow_Context_Model;
      C        : DGL.Dataflow_Context_Info;
   begin
      C.Id := 1;
      C.Kind := DGL.Dataflow_Context_Subprogram;
      C.Effect := DGL.Dataflow_Effect_Read;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112301);
      C.Object_Name := To_Unbounded_String ("Config");
      C.Declared_Global_Mode := DGL.Global_Mode_In;
      C.Reads_Object := True;
      C.Before_State := DIF.Object_State_Definitely_Initialized;
      C.Contract_Status := CA.Contract_Legality_Legal_Flow_Aspect;
      C.Flow_State := CA.Flow_Contract_Resolved;
      C.Initialization_Status := DIF.Initialization_Legality_Definitely_Initialized;
      C.Source_Fingerprint := 301;
      DGL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := DGL.Dataflow_Context_Subprogram;
      C.Effect := DGL.Dataflow_Effect_Write;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112302);
      C.Object_Name := To_Unbounded_String ("Config");
      C.Declared_Global_Mode := DGL.Global_Mode_In;
      C.Writes_Object := True;
      C.Contract_Status := CA.Contract_Legality_Legal_Flow_Aspect;
      C.Flow_State := CA.Flow_Contract_Resolved;
      C.Initialization_Status := DIF.Initialization_Legality_Definitely_Initialized;
      C.Source_Fingerprint := 302;
      DGL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := DGL.Dataflow_Context_Subprogram;
      C.Effect := DGL.Dataflow_Effect_Depends_Edge;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112303);
      C.Source_Node := Editor.Ada_Syntax_Tree.Node_Id (112331);
      C.Target_Node := Editor.Ada_Syntax_Tree.Node_Id (112332);
      C.Source_Name := To_Unbounded_String ("Input");
      C.Target_Name := To_Unbounded_String ("Output");
      C.Object_Name := To_Unbounded_String ("Output");
      C.Source_Global_Mode := DGL.Global_Mode_Out;
      C.Target_Global_Mode := DGL.Global_Mode_Out;
      C.Dependency := DGL.Dependency_State_Resolved;
      C.Contract_Status := CA.Contract_Legality_Legal_Flow_Aspect;
      C.Flow_State := CA.Flow_Contract_Resolved;
      C.Initialization_Status := DIF.Initialization_Legality_Definitely_Initialized;
      C.Source_Fingerprint := 303;
      DGL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := DGL.Dataflow_Context_Subprogram;
      C.Effect := DGL.Dataflow_Effect_Read;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112304);
      C.Object_Name := To_Unbounded_String ("Unwritten");
      C.Declared_Global_Mode := DGL.Global_Mode_In;
      C.Reads_Object := True;
      C.Before_State := DIF.Object_State_Uninitialized;
      C.Contract_Status := CA.Contract_Legality_Legal_Flow_Aspect;
      C.Flow_State := CA.Flow_Contract_Resolved;
      C.Initialization_Status := DIF.Initialization_Legality_Read_Before_Write;
      C.Source_Fingerprint := 304;
      DGL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := DGL.Dataflow_Context_Contract_Aspect;
      C.Effect := DGL.Dataflow_Effect_Read;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112305);
      C.Object_Name := To_Unbounded_String ("Hidden");
      C.Declared_Global_Mode := DGL.Global_Mode_Not_Declared;
      C.Reads_Object := True;
      C.Contract_Status := CA.Contract_Legality_Flow_Unknown_Global;
      C.Flow_State := CA.Flow_Contract_Unknown_Global;
      C.Initialization_Status := DIF.Initialization_Legality_Definitely_Initialized;
      C.Source_Fingerprint := 305;
      DGL.Add_Context (Contexts, C);

      return DGL.Build (Contexts);
   end Dataflow_Model;

   procedure Global_Depends_Consumes_Flow_And_Initialization
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : constant DGL.Dataflow_Legality_Model := Dataflow_Model;
      Legal_Read : constant DGL.Dataflow_Legality_Info :=
        DGL.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (112301));
      Illegal_Write : constant DGL.Dataflow_Legality_Info :=
        DGL.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (112302));
      Illegal_Depends : constant DGL.Dataflow_Legality_Info :=
        DGL.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (112303));
      Init_Error : constant DGL.Dataflow_Legality_Info :=
        DGL.First_For_Object (Model, "Unwritten");
   begin
      Assert (DGL.Row_Count (Model) = 5, "all dataflow contexts are classified");
      Assert (DGL.Legal_Count (Model) = 1, "legal Global read remains legal");
      Assert (Legal_Read.Status = DGL.Dataflow_Legality_Legal_Read,
              "Global in permits initialized reads");
      Assert (Illegal_Write.Status = DGL.Dataflow_Legality_Write_To_In_Global,
              "Global in does not permit writes");
      Assert (Illegal_Depends.Status = DGL.Dataflow_Legality_Depends_Source_Not_Input,
              "Depends source must be covered by an input mode");
      Assert (Init_Error.Status = DGL.Dataflow_Legality_Read_Before_Write,
              "definite-initialization state is consumed by dataflow legality");
      Assert (DGL.Global_Error_Count (Model) = 1,
              "Global mode errors are counted separately from linked contract errors");
      Assert (DGL.Depends_Error_Count (Model) = 1,
              "Depends mode errors are counted");
      Assert (DGL.Initialization_Error_Count (Model) = 1,
              "initialization-flow errors are counted");
      Assert (DGL.Linked_Error_Count (Model) = 1,
              "contract flow errors remain linked blockers");
      Assert (DGL.Fingerprint (Model) /= 0,
              "dataflow legality fingerprint is deterministic and nonzero");
   end Global_Depends_Consumes_Flow_And_Initialization;

   procedure Dataflow_Blockers_Enter_Integrated_Closure
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Base : ISC.Integrated_Closure_Context_Model;
      Dataflow : constant DGL.Dataflow_Legality_Model := Dataflow_Model;
      Closure : constant ISC.Integrated_Closure_Model :=
        ICD.Build_With_Dataflow (Base, Dataflow);
      Feed : constant SF.Semantic_Diagnostic_Feed_Model :=
        SF.Build_With_Integrated_Closure (Current_Guard, Closure);
      Index : constant SI.Semantic_Diagnostic_Index_Model := SI.Build (Feed);
      Provenance : constant DP.Diagnostic_Provenance_Model :=
        DP.Build_With_Integrated_Closure (Index, Closure);
   begin
      Assert (ISC.Closure_Count (Closure) = DGL.Row_Count (Dataflow),
              "all dataflow rows become integrated closure rows");
      Assert (ISC.Legal_Count (Closure) = 1,
              "legal dataflow row remains legal closure");
      Assert (ISC.Count_Blocker (Closure, ISC.Closure_Blocker_Dataflow) = 4,
              "dataflow failures are first-class closure blockers");
      Assert (ISC.Count_Status (Closure, ISC.Integrated_Closure_Dataflow_Blocker) = 4,
              "dataflow blockers have a distinct integrated closure status");
      Assert (SF.Entry_Count (Feed) = 4 and then SF.Error_Count (Feed) = 4,
              "dataflow blockers enter unified diagnostic feed as hard errors");
      Assert (SI.Query_Count (SI.Query_Node (Index, Editor.Ada_Syntax_Tree.Node_Id (112302))) = 1,
              "diagnostic index can locate Global write violations by node");
      Assert (DP.Integrated_Closure_Item_Count (Provenance) = SF.Entry_Count (Feed),
              "provenance links dataflow diagnostics to closure rows");
   end Dataflow_Blockers_Enter_Integrated_Closure;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Global_Depends_Consumes_Flow_And_Initialization'Access,
         "Global/Depends dataflow consumes flow and initialization facts");
      Register_Routine
        (T, Dataflow_Blockers_Enter_Integrated_Closure'Access,
         "Global/Depends dataflow blockers enter integrated closure diagnostics");
   end Register_Tests;

end Test_Ada_Dataflow_Global_Depends_Legality;
