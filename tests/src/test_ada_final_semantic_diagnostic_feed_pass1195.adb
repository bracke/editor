with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit; use AUnit;
with Editor.Ada_Final_Semantic_Diagnostic_Integration;
with Editor.Ada_Semantic_Colour_Projection;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Final_Semantic_Diagnostic_Feed_Pass1195 is

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
   package Access_Final renames Final_Diag.Access_Final;
   package Cross_Final renames Final_Diag.Cross_Final;
   package Discriminant_Final renames Final_Diag.Discriminant_Final;
   package Elaboration_Final renames Final_Diag.Elaboration_Final;
   package Flow_Final renames Final_Diag.Flow_Final;
   package Generic_Final renames Final_Diag.Generic_Final;
   package Overload_Final renames Final_Diag.Overload_Final;
   package Representation_Final renames Final_Diag.Representation_Final;
   package Tasking_Final renames Final_Diag.Tasking_Final;
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
      return Format ("Test_Ada_Final_Semantic_Diagnostic_Feed_Pass1195");
   end Name;

   function Current_Guard return SG.Guarded_Semantic_Diagnostic_Model is
      Projection : SC.Semantic_Colour_Model;
      Key : constant SG.Diagnostic_Snapshot_Key :=
        SG.Make_Key ("final-feed.adb", 1195, 20, 30, 40, SC.Fingerprint (Projection));
   begin
      return SG.Build (Key, Key, Projection);
   end Current_Guard;

   function Rejected_Guard return SG.Guarded_Semantic_Diagnostic_Model is
      Projection : SC.Semantic_Colour_Model;
      Produced : constant SG.Diagnostic_Snapshot_Key :=
        SG.Make_Key ("final-feed.adb", 1195, 20, 30, 40, SC.Fingerprint (Projection));
      Current : constant SG.Diagnostic_Snapshot_Key :=
        SG.Make_Key ("final-feed.adb", 1196, 20, 30, 40, SC.Fingerprint (Projection));
   begin
      return SG.Build (Produced, Current, Projection);
   end Rejected_Guard;

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
      C.Source_Fingerprint := Natural (Id) * 1195;
      C.Expected_Source_Fingerprint := Natural (Id) * 1195;
      C.Message := To_Unbounded_String ("final semantic feed context");
      C.Start_Line := Positive (Natural (Id) + 10);
      C.Start_Column := 3;
      C.End_Line := Positive (Natural (Id) + 10);
      C.End_Column := 21;
      return C;
   end Base_Context;

   function Final_Model return Final_Diag.Final_Diagnostic_Model is
      Contexts : Final_Diag.Final_Diagnostic_Context_Model;
      Legal : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (1,
           Final_Diag.Final_Diagnostic_Overload_Type,
           Editor.Ada_Syntax_Tree.Node_Id (119501));
      Cross : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (2,
           Final_Diag.Final_Diagnostic_Cross_Unit,
           Editor.Ada_Syntax_Tree.Node_Id (119502));
      Representation : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (3,
           Final_Diag.Final_Diagnostic_Representation_Freezing,
           Editor.Ada_Syntax_Tree.Node_Id (119503));
      Generic_Ctx : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (4,
           Final_Diag.Final_Diagnostic_Generic_Replay,
           Editor.Ada_Syntax_Tree.Node_Id (119504));
      Tasking : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (5,
           Final_Diag.Final_Diagnostic_Tasking_Protected,
           Editor.Ada_Syntax_Tree.Node_Id (119505));
   begin
      Cross.Cross_Unit_Status := Cross_Final.Cross_Unit_Final_Missing_Dependency;
      Representation.Representation_Status :=
        Representation_Final.Final_Representation_Generic_Formal_Freezing_Blocker;
      Generic_Ctx.Generic_Status := Generic_Final.Nested_Generic_Recursive_Instantiation_Cycle;
      Tasking.Tasking_Status := Tasking_Final.Deep_Tasking_Terminate_Dependency_Cycle;

      Final_Diag.Add_Context (Contexts, Legal);
      Final_Diag.Add_Context (Contexts, Cross);
      Final_Diag.Add_Context (Contexts, Representation);
      Final_Diag.Add_Context (Contexts, Generic_Ctx);
      Final_Diag.Add_Context (Contexts, Tasking);
      return Final_Diag.Build (Contexts);
   end Final_Model;

   procedure Final_Diagnostics_Enter_Feed_And_Index
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Final : constant Final_Diag.Final_Diagnostic_Model := Final_Model;
      Feed : constant SF.Semantic_Diagnostic_Feed_Model :=
        SF.Build_With_Final_Semantic_Diagnostics (Current_Guard, Final);
      Index : constant SI.Semantic_Diagnostic_Index_Model := SI.Build (Feed);
      Cross_Rows : constant SI.Semantic_Diagnostic_Query_Set :=
        SI.Query_Node (Index, Editor.Ada_Syntax_Tree.Node_Id (119502));
      Representation_Rows : constant SI.Semantic_Diagnostic_Query_Set :=
        SI.Query_Position (Index, 13, 10);
   begin
      Assert (SF.Current (Feed), "current final diagnostic input should keep the feed current");
      Assert
        (SF.Entry_Count (Feed) = Final_Diag.Row_Count (Final) - Final_Diag.Withheld_Legal_Count (Final),
         "withheld legal final rows must not become active feed entries");
      Assert (SF.Error_Count (Feed) >= 4, "final blockers should be emitted as errors");
      Assert
        (SF.Count_Source (Feed, SC.Semantic_Colour_From_Cross_Unit) = 1,
         "cross-unit final blockers must preserve cross-unit source family");
      Assert
        (SF.Count_Source (Feed, SC.Semantic_Colour_From_Representation) = 1,
         "representation/freezing final blockers must preserve representation source family");
      Assert
        (SF.Count_Source (Feed, SC.Semantic_Colour_From_Generic_Contract) = 1,
         "generic replay final blockers must preserve generic source family");
      Assert (SI.Entry_Count (Index) = SF.Entry_Count (Feed),
              "existing semantic diagnostic index should consume final feed rows");
      Assert (SI.Query_Count (Cross_Rows) = 1,
              "node lookup should find the final cross-unit diagnostic");
      Assert (SI.Query_Count (Representation_Rows) = 1,
              "position lookup should find the final representation diagnostic");
      Assert (SF.Fingerprint (Feed) /= 0 and then SI.Fingerprint (Index) /= 0,
              "feed and index fingerprints should include final semantic rows");
   end Final_Diagnostics_Enter_Feed_And_Index;

   procedure Stale_Final_Input_Withholds_Active_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Final : constant Final_Diag.Final_Diagnostic_Model := Final_Model;
      Feed : constant SF.Semantic_Diagnostic_Feed_Model :=
        SF.Build_With_Final_Semantic_Diagnostics
          (Current_Guard,
           Final,
           Final_Input_Current => False,
           Final_Rejected_Count => Final_Diag.Row_Count (Final));
   begin
      Assert (SF.Rejected_Stale (Feed),
              "stale final semantic diagnostic input should reject the unified feed");
      Assert (SF.Entry_Count (Feed) = 0,
              "stale final semantic diagnostic input should expose no active feed entries");
      Assert (SF.Rejected_Entry_Count (Feed) = Final_Diag.Row_Count (Final),
              "stale final semantic input should preserve rejected row accounting");
   end Stale_Final_Input_Withholds_Active_Rows;

   procedure Stale_Base_Guard_Withholds_Final_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Final : constant Final_Diag.Final_Diagnostic_Model := Final_Model;
      Feed : constant SF.Semantic_Diagnostic_Feed_Model :=
        SF.Build_With_Final_Semantic_Diagnostics
          (Rejected_Guard,
           Final,
           Final_Rejected_Count => Final_Diag.Row_Count (Final));
   begin
      Assert (SF.Rejected_Stale (Feed),
              "rejected base snapshot guard should reject the final semantic feed");
      Assert (SF.Entry_Count (Feed) = 0,
              "rejected base snapshot guard should withhold final semantic feed entries");
      Assert (SF.Rejected_Entry_Count (Feed) >= Final_Diag.Row_Count (Final),
              "rejected base guard should preserve final rejected accounting");
   end Stale_Base_Guard_Withholds_Final_Rows;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Final_Diagnostics_Enter_Feed_And_Index'Access,
         "final semantic diagnostics enter unified feed and index");
      Register_Routine
        (T,
         Stale_Final_Input_Withholds_Active_Rows'Access,
         "stale final semantic input is withheld from active feed rows");
      Register_Routine
        (T,
         Stale_Base_Guard_Withholds_Final_Rows'Access,
         "rejected base semantic guards withhold final semantic feed entries");
   end Register_Tests;

end Test_Ada_Final_Semantic_Diagnostic_Feed_Pass1195;
