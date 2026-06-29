with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Assignment_Legality;
with Editor.Ada_Accessibility_Lifetime_Legality;
with Editor.Ada_Expression_Types;
with Editor.Ada_Overload_Preference_Legality;
with Editor.Ada_Overload_Ranking;
with Editor.Ada_Overload_Resolution_Legality;
with Editor.Ada_Semantic_Colour_Projection;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Wide_Semantic_Legality_Diagnostics;
with Editor.Ada_Wide_Semantic_Legality_Diagnostics.Accessibility;
with Editor.Ada_Return_Legality;
with Editor.Ada_Conversion_Access_Aggregate_Legality;
with Editor.Ada_Control_Flow_Legality;
with Editor.Ada_Tasking_Protected_Legality;
with Editor.Ada_Tagged_Derived_Legality;
with Editor.Ada_Generic_Instance_Freezing_Representation_Legality;
with Editor.Ada_Cross_Unit_Semantic_Closure;

package body Test_Ada_Wide_Semantic_Diagnostic_Feed_Integration is

   package AL renames Editor.Ada_Assignment_Legality;
   use type AL.Expression_Type_Id;
   use type AL.Assignment_Context_Id;
   use type AL.Assignment_Legality_Id;
   use type AL.Assignment_Context_Kind;
   use type AL.Assignment_Target_Mode;
   use type AL.Assignment_Legality_Status;
   use type AL.Assignment_Context_Info;
   use type AL.Assignment_Legality_Info;
   use type AL.Assignment_Context_Model;
   use type AL.Assignment_Legality_Result_Set;
   use type AL.Assignment_Legality_Model;
   package ET renames Editor.Ada_Expression_Types;
   use type ET.Expected_Type_Propagation_Status;
   use type ET.Operator_Type_Inference_Status;
   use type ET.Concatenation_Type_Inference_Status;
   use type ET.Aggregate_Type_Inference_Status;
   use type ET.Conversion_Type_Inference_Status;
   use type ET.Conditional_Type_Inference_Status;
   use type ET.Membership_Range_Inference_Status;
   use type ET.Target_Name_Inference_Status;
   use type ET.Indexed_Slice_Inference_Status;
   use type ET.Boolean_Context_Inference_Status;
   use type ET.Raise_No_Return_Inference_Status;
   use type ET.Allocator_Type_Inference_Status;
   use type ET.Universal_Numeric_Resolution_Status;
   use type ET.Dispatching_Call_Inference_Status;
   use type ET.Call_Actual_Type_Resolution_Status;
   use type ET.Parameter_Association_Inference_Status;
   use type ET.Dereference_Access_Inference_Status;
   use type ET.Attribute_Type_Inference_Status;
   use type ET.Expression_Type_Status;
   use type ET.Expression_Type_Id;
   use type ET.Expression_Type_Info;
   use type ET.Expression_Type_Model;
   package SG renames Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
   use type SG.Diagnostic_Snapshot_Key;
   use type SG.Diagnostic_Snapshot_Status;
   use type SG.Guarded_Semantic_Diagnostic_Model;
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
   package WD renames Editor.Ada_Wide_Semantic_Legality_Diagnostics;
   use type WD.Wide_Semantic_Diagnostic_Id;
   use type WD.Wide_Semantic_Diagnostic_Family;
   use type WD.Wide_Semantic_Diagnostic_Severity;
   use type WD.Wide_Semantic_Diagnostic_Kind;
   use type WD.Wide_Semantic_Diagnostic_Info;
   use type WD.Wide_Semantic_Diagnostic_Result_Set;
   use type WD.Wide_Semantic_Diagnostic_Model;
   package AX renames Editor.Ada_Accessibility_Lifetime_Legality;
   use type AX.Accessibility_Context_Id;
   use type AX.Accessibility_Legality_Id;
   use type AX.Access_Context_Kind;
   use type AX.Access_Target_Kind;
   use type AX.Accessibility_Level;
   use type AX.Accessibility_Legality_Status;
   use type AX.Accessibility_Context_Info;
   use type AX.Accessibility_Legality_Model;
   package OP renames Editor.Ada_Overload_Preference_Legality;
   use type OP.Preference_Legality_Status;
   use type OP.Preference_Legality_Model;
   package ORL renames Editor.Ada_Overload_Resolution_Legality;
   use type ORL.Overload_Context_Kind;
   use type ORL.Overload_Legality_Model;
   package RK renames Editor.Ada_Overload_Ranking;
   use type RK.Overload_Ranking_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Wide_Semantic_Diagnostic_Feed_Integration");
   end Name;

   function Current_Guard return SG.Guarded_Semantic_Diagnostic_Model is
      Projection : SC.Semantic_Colour_Model;
      Key : constant SG.Diagnostic_Snapshot_Key :=
        SG.Make_Key ("wide.adb", 10, 20, 30, 40, SC.Fingerprint (Projection));
   begin
      return SG.Build (Key, Key, Projection);
   end Current_Guard;

   function Rejected_Guard return SG.Guarded_Semantic_Diagnostic_Model is
      Projection : SC.Semantic_Colour_Model;
      Produced : constant SG.Diagnostic_Snapshot_Key :=
        SG.Make_Key ("wide.adb", 10, 20, 30, 40, SC.Fingerprint (Projection));
      Current : constant SG.Diagnostic_Snapshot_Key :=
        SG.Make_Key ("wide.adb", 11, 20, 30, 40, SC.Fingerprint (Projection));
   begin
      return SG.Build (Produced, Current, Projection);
   end Rejected_Guard;

   function Wide_Model return WD.Wide_Semantic_Diagnostic_Model is
      Expression_Types : ET.Expression_Type_Model;
      Assignment_Contexts : AL.Assignment_Context_Model;
      Assignment_Context  : AL.Assignment_Context_Info;
      Assignments         : AL.Assignment_Legality_Model;
      Returns     : Editor.Ada_Return_Legality.Return_Legality_Model;
      Expressions : Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Model;
      Flow        : Editor.Ada_Control_Flow_Legality.Flow_Legality_Model;
      Tasking     : Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Model;
      Tagged_Model      : Editor.Ada_Tagged_Derived_Legality.Tagged_Legality_Model;
      Instances   : Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Model;
      Cross_Unit  : Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Model;
   begin
      Assignment_Context.Id := 1;
      Assignment_Context.Kind := AL.Assignment_Context_Assignment_Statement;
      Assignment_Context.Target_Node := Editor.Ada_Syntax_Tree.Node_Id (1_108);
      Assignment_Context.Source_Node := Editor.Ada_Syntax_Tree.Node_Id (1_109);
      Assignment_Context.Target_Mode := AL.Assignment_Target_Constant;
      Assignment_Context.Target_Subtype := To_Unbounded_String ("Integer");
      Assignment_Context.Source_Subtype := To_Unbounded_String ("Integer");
      Assignment_Context.Start_Line := 12;
      Assignment_Context.Start_Column := 3;
      Assignment_Context.End_Line := 12;
      Assignment_Context.End_Column := 17;
      AL.Add_Context (Assignment_Contexts, Assignment_Context);
      Assignments := AL.Build (Assignment_Contexts, Expression_Types);
      return WD.Build
        (Assignments, Returns, Expressions, Flow, Tasking, Tagged_Model,
         Instances, Cross_Unit);
   end Wide_Model;

   procedure Wide_Diagnostics_Are_Fed_And_Indexed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Wide  : constant WD.Wide_Semantic_Diagnostic_Model := Wide_Model;
      Feed  : constant SF.Semantic_Diagnostic_Feed_Model :=
        SF.Build_With_Wide_Legality (Current_Guard, Wide);
      Index : constant SI.Semantic_Diagnostic_Index_Model := SI.Build (Feed);
      Node_Rows : constant SI.Semantic_Diagnostic_Query_Set :=
        SI.Query_Node (Index, Editor.Ada_Syntax_Tree.Node_Id (1_109));
      Position_Rows : constant SI.Semantic_Diagnostic_Query_Set :=
        SI.Query_Position (Index, 12, 5);
   begin
      Assert (SF.Current (Feed),
              "wide diagnostic feed integration should remain current for current guards");
      Assert (SF.Entry_Count (Feed) = WD.Diagnostic_Count (Wide),
              "wide diagnostics should be appended to the unified semantic feed");
      Assert (SF.Error_Count (Feed) >= 1,
              "wide legality failures should preserve error severity in the feed");
      Assert (SF.Count_Source
                (Feed, SC.Semantic_Colour_From_Expression) >= 1,
              "assignment/object legality should map to the expression semantic source family");
      Assert (SI.Entry_Count (Index) = SF.Entry_Count (Feed),
              "the existing diagnostic index should consume the integrated feed");
      Assert (SI.Query_Count (Node_Rows) = 1,
              "node lookup should find the wide semantic diagnostic through the index");
      Assert (SI.Query_Count (Position_Rows) = 1,
              "position lookup should find the wide semantic diagnostic span");
      Assert (SF.Fingerprint (Feed) /= 0 and then SI.Fingerprint (Index) /= 0,
              "feed and index fingerprints should include wide semantic diagnostics");
   end Wide_Diagnostics_Are_Fed_And_Indexed;

   procedure Stale_Wide_Input_Withholds_Active_Feed_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Wide : constant WD.Wide_Semantic_Diagnostic_Model := Wide_Model;
      Feed : constant SF.Semantic_Diagnostic_Feed_Model :=
        SF.Build_With_Wide_Legality
          (Current_Guard, Wide, Wide_Input_Current => False,
           Wide_Rejected_Count => WD.Diagnostic_Count (Wide));
   begin
      Assert (SF.Rejected_Stale (Feed),
              "stale wide legality input should reject the integrated feed");
      Assert (SF.Entry_Count (Feed) = 0,
              "stale wide legality input should expose no active feed entries");
      Assert (SF.Rejected_Entry_Count (Feed) = WD.Diagnostic_Count (Wide),
              "stale wide legality input should preserve rejected totals");
   end Stale_Wide_Input_Withholds_Active_Feed_Rows;

   procedure Stale_Base_Guard_Withholds_Wide_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Wide : constant WD.Wide_Semantic_Diagnostic_Model := Wide_Model;
      Feed : constant SF.Semantic_Diagnostic_Feed_Model :=
        SF.Build_With_Wide_Legality
          (Rejected_Guard, Wide, Wide_Rejected_Count => WD.Diagnostic_Count (Wide));
   begin
      Assert (SF.Rejected_Stale (Feed),
              "rejected base snapshot guard should reject the integrated feed");
      Assert (SF.Entry_Count (Feed) = 0,
              "rejected base snapshot guard should withhold wide diagnostics");
      Assert (SF.Rejected_Entry_Count (Feed) >= WD.Diagnostic_Count (Wide),
              "rejected base snapshot guard should retain rejected accounting");
   end Stale_Base_Guard_Withholds_Wide_Rows;

   procedure Accessibility_Lifetime_Diagnostics_Enter_Wide_Feed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Assignments : AL.Assignment_Legality_Model;
      Returns     : Editor.Ada_Return_Legality.Return_Legality_Model;
      Expressions : Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Model;
      Flow        : Editor.Ada_Control_Flow_Legality.Flow_Legality_Model;
      Tasking     : Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Model;
      Tagged_Model : Editor.Ada_Tagged_Derived_Legality.Tagged_Legality_Model;
      Instances   : Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Model;
      Cross_Unit  : Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Model;
      Accessibility_Contexts : AX.Accessibility_Context_Model;
      Accessibility_Context  : AX.Accessibility_Context_Info;
   begin
      Accessibility_Context.Id := 1;
      Accessibility_Context.Kind := AX.Access_Context_Anonymous_Access_Parameter;
      Accessibility_Context.Node := Editor.Ada_Syntax_Tree.Node_Id (1_901);
      Accessibility_Context.Source_Level := AX.Accessibility_Level_Unknown;
      Accessibility_Context.Target_Level := AX.Accessibility_Level_Unknown;
      Accessibility_Context.Start_Line := 31;
      Accessibility_Context.End_Line := 31;
      AX.Add_Context (Accessibility_Contexts, Accessibility_Context);

      declare
         Accessibility : constant AX.Accessibility_Legality_Model :=
           AX.Build (Accessibility_Contexts);
         Wide : constant WD.Wide_Semantic_Diagnostic_Model :=
           Editor.Ada_Wide_Semantic_Legality_Diagnostics.Accessibility.Build_With_Accessibility
             (Assignments, Returns, Expressions, Flow, Tasking, Tagged_Model,
              Instances, Cross_Unit, Accessibility);
         Feed : constant SF.Semantic_Diagnostic_Feed_Model :=
           SF.Build_With_Wide_Legality (Current_Guard, Wide);
      begin
         Assert (WD.Count_Family
                   (Wide, WD.Wide_Semantic_Diagnostic_Accessibility_Lifetime) = 1,
                 "accessibility lifetime rows should enter wide diagnostics");
         Assert (WD.Count_Kind
                   (Wide, WD.Wide_Semantic_Diagnostic_Unresolved_Semantic_State) = 1,
                 "unknown accessibility levels should be unresolved diagnostics");
         Assert (SF.Entry_Count (Feed) = 1
                 and then SF.Error_Count (Feed) = 0
                 and then SF.Warning_Count (Feed) = 1,
                 "accessibility lifetime diagnostics should enter the feed as warnings when unresolved");
         Assert (SF.Count_Source (Feed, SC.Semantic_Colour_From_Expression) = 1,
                 "accessibility diagnostics should map to expression source for IDE display");
      end;
   end Accessibility_Lifetime_Diagnostics_Enter_Wide_Feed;

   procedure Overload_Preference_Diagnostics_Enter_Feed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Overload_Contexts : ORL.Overload_Context_Model;
      Overload_Context  : ORL.Overload_Context_Info;
      Rankings          : RK.Overload_Ranking_Model;
      Wide              : WD.Wide_Semantic_Diagnostic_Model;
   begin
      Overload_Context.Id := 1;
      Overload_Context.Kind := ORL.Overload_Context_Call;
      Overload_Context.Node := Editor.Ada_Syntax_Tree.Node_Id (1_926);
      Overload_Context.Designator := To_Unbounded_String ("Ambiguous");
      Overload_Context.Candidate_Count := 2;
      Overload_Context.Visible_Candidate_Count := 2;
      Overload_Context.Ambiguous_Candidate_Count := 2;
      Overload_Context.Start_Line := 44;
      Overload_Context.Start_Column := 7;
      Overload_Context.End_Line := 44;
      Overload_Context.End_Column := 23;
      ORL.Add_Context (Overload_Contexts, Overload_Context);

      declare
         Overloads : constant ORL.Overload_Legality_Model :=
           ORL.Build (Overload_Contexts, Rankings, Wide);
         Preference_Contexts : constant OP.Preference_Context_Model :=
           OP.Build_Contexts_From_Overload_Legality (Overloads);
         Preference : constant OP.Preference_Legality_Model :=
           OP.Build (Overloads, Preference_Contexts);
         Feed : constant SF.Semantic_Diagnostic_Feed_Model :=
           SF.Build_With_Wide_Legality_And_Overload_Preference
             (Current_Guard, Wide, Preference);
         Index : constant SI.Semantic_Diagnostic_Index_Model := SI.Build (Feed);
         Node_Rows : constant SI.Semantic_Diagnostic_Query_Set :=
           SI.Query_Node (Index, Editor.Ada_Syntax_Tree.Node_Id (1_926));
         Position_Rows : constant SI.Semantic_Diagnostic_Query_Set :=
           SI.Query_Position (Index, 44, 10);
      begin
         Assert (OP.Ambiguous_Count (Preference) = 1,
                 "preference model should preserve overload ambiguity");
         Assert (SF.Entry_Count (Feed) = 1
                 and then SF.Warning_Count (Feed) = 1
                 and then SF.Error_Count (Feed) = 0,
                 "preference ambiguity should enter the feed as a warning");
         Assert (SF.Count_Source (Feed, SC.Semantic_Colour_From_Expression) = 1,
                 "overload preference diagnostics should map to expression source");
         Assert (SI.Query_Count (Node_Rows) = 1,
                 "preference diagnostic should be indexed by overload node");
         Assert (SI.Query_Count (Position_Rows) = 1,
                 "preference diagnostic should be indexed by source span");
      end;
   end Overload_Preference_Diagnostics_Enter_Feed;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Wide_Diagnostics_Are_Fed_And_Indexed'Access,
         "wide semantic legality diagnostics enter unified feed and index");
      Register_Routine
        (T, Stale_Wide_Input_Withholds_Active_Feed_Rows'Access,
         "stale wide legality inputs are withheld from active feed rows");
      Register_Routine
        (T, Stale_Base_Guard_Withholds_Wide_Rows'Access,
         "rejected base semantic guards withhold wide legality feed entries");
      Register_Routine
        (T, Accessibility_Lifetime_Diagnostics_Enter_Wide_Feed'Access,
         "accessibility lifetime diagnostics enter wide semantic feed");
      Register_Routine
        (T, Overload_Preference_Diagnostics_Enter_Feed'Access,
         "overload preference diagnostics enter unified semantic feed");
   end Register_Tests;

end Test_Ada_Wide_Semantic_Diagnostic_Feed_Integration;
