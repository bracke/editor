with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Commands;
with Editor.Executor;
with Editor.Feature_Diagnostics;
with Editor.Feature_Messages;
with Editor.Feature_Panel; use Editor.Feature_Panel;
with Editor.Feature_Panel_Controller;
with Editor.Feature_Panel.Fixtures; use Editor.Feature_Panel.Fixtures;
with Editor.Feature_Search_Results;
with Editor.State;

package body Editor.Feature_Panel_Audit.Tests is

   use type Editor.Commands.Command_Id;
   use type Editor.Executor.Command_Execution_Status;
   use type Editor.Feature_Panel.Feature_Id;

   function Name
     (T : Feature_Panel_Audit_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Feature_Panel_Audit.Tests");
   end Name;

   procedure Assert_Audit_Passed (Context : String) is
      Result : constant Feature_Panel_Audit_Result := Run_Feature_Panel_Audit;
   begin
      Assert (Result.Passed, Context & ": " & Summary (Result));
      Assert (Result.Descriptor_Count = 4,
              Context & ": Phase 158 freezes the four-feature set");
   end Assert_Audit_Passed;

   procedure Test_Feature_Audit_Passes_For_Four_Features
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Feature_Panel_Audit_Result := Run_Feature_Panel_Audit;
   begin
      Assert (Result.Passed, Summary (Result));
      Assert (not Result.Has_Missing_Descriptor, "descriptors complete");
      Assert (not Result.Has_Duplicate_Stable_Name, "stable names unique");
      Assert (not Result.Has_Duplicate_Display_Label, "display labels unique");
      Assert (not Result.Has_Missing_Projection_Handler, "projection dispatch covered");
      Assert (not Result.Has_Missing_Clear_Handler, "clear dispatch covered");
      Assert (not Result.Has_Missing_Open_Handler, "open dispatch covered");
      Assert (not Result.Has_Missing_Row_Action_Handler, "row action dispatch covered");
      Assert (not Result.Has_Missing_Lifecycle_Handler, "lifecycle dispatch covered");
      Assert (not Result.Has_Command_Registration_Gap, "command surface covered");
   end Test_Feature_Audit_Passes_For_Four_Features;

   procedure Test_Feature_Audit_Descriptor_Table_Covers_All_Features
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Seen_Outline  : Boolean := False;
      Seen_Messages : Boolean := False;
      Seen_Search   : Boolean := False;
      Seen_Diagnostics : Boolean := False;
      F             : Feature_Id;
   begin
      for I in 1 .. Feature_Descriptor_Count loop
         F := Descriptor_Id (I);
         Assert (Is_Known_Feature (F), "descriptor names a known feature");
         Assert (Feature_Stable_Name (F)'Length > 0, "stable name is non-empty");
         Assert (Feature_Display_Label (F)'Length > 0, "display label is non-empty");
         case F is
            when Outline_Feature => Seen_Outline := True;
            when Messages_Feature => Seen_Messages := True;
            when Search_Results_Feature => Seen_Search := True;
            when Diagnostics_Feature => Seen_Diagnostics := True;
            when Unknown_Feature => Assert (False, "unknown feature not registered");
         end case;
      end loop;
      Assert (Seen_Outline and then Seen_Messages and then Seen_Search and then Seen_Diagnostics,
              "descriptor table covers Outline, Messages, Search Results, and Diagnostics");
      Assert (Feature_Descriptor_Count = 4,
              "Phase 158 freezes exactly four feature-panel features");
      Assert (Descriptor_Id (1) = Outline_Feature,
              "descriptor order keeps Outline first");
      Assert (Descriptor_Id (2) = Messages_Feature,
              "descriptor order keeps Messages second");
      Assert (Descriptor_Id (3) = Search_Results_Feature,
              "descriptor order keeps Search Results third");
      Assert (Descriptor_Id (4) = Diagnostics_Feature,
              "descriptor order keeps Diagnostics fourth");
      Assert (Feature_Stable_Name (Unknown_Feature) = "",
              "unknown feature stable name is rejected safely");
      Assert (Feature_Display_Label (Unknown_Feature) = "",
              "unknown feature display label is rejected safely");
      Assert (not Is_Known_Feature (Unknown_Feature),
              "unknown feature is not a known registered feature");
   end Test_Feature_Audit_Descriptor_Table_Covers_All_Features;

   procedure Test_Feature_Audit_Dispatch_Covers_All_Features
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      F : Feature_Id;
   begin
      Assert (Editor.Feature_Panel_Controller.Feature_Dispatch_Covers_All_Features,
              "combined dispatch coverage must pass");
      for I in 1 .. Feature_Descriptor_Count loop
         F := Descriptor_Id (I);
         Assert (Editor.Feature_Panel_Controller.Has_Projection_Dispatch (F),
                 "projection dispatch covered for " & Feature_Stable_Name (F));
         Assert (Editor.Feature_Panel_Controller.Has_Clear_Dispatch (F),
                 "clear dispatch covered for " & Feature_Stable_Name (F));
         Assert (Editor.Feature_Panel_Controller.Has_Open_Dispatch (F),
                 "open dispatch covered for " & Feature_Stable_Name (F));
         Assert (Editor.Feature_Panel_Controller.Has_Row_Action_Dispatch (F),
                 "row action dispatch covered for " & Feature_Stable_Name (F));
         Assert (Editor.Feature_Panel_Controller.Has_Lifecycle_Dispatch (F),
                 "lifecycle dispatch covered for " & Feature_Stable_Name (F));
      end loop;
      Assert (not Editor.Feature_Panel_Controller.Has_Projection_Dispatch (Unknown_Feature),
              "unknown feature has no projection dispatch");
      Assert (not Editor.Feature_Panel_Controller.Has_Clear_Dispatch (Unknown_Feature),
              "unknown feature has no clear dispatch");
      Assert (not Editor.Feature_Panel_Controller.Has_Open_Dispatch (Unknown_Feature),
              "unknown feature has no open dispatch");
      Assert (not Editor.Feature_Panel_Controller.Has_Row_Action_Dispatch (Unknown_Feature),
              "unknown feature has no row action dispatch");
      Assert (not Editor.Feature_Panel_Controller.Has_Lifecycle_Dispatch (Unknown_Feature),
              "unknown feature has no lifecycle dispatch");
   end Test_Feature_Audit_Dispatch_Covers_All_Features;

   procedure Test_Feature_Audit_Command_Surface_Covers_All_Features
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Feature_Command_Surface_Covers_All_Features,
              "feature command surface audit must cover all registered features");
      Assert (Feature_Command_Surface_Covers (Outline_Feature),
              "Outline command surface covered");
      Assert (Feature_Command_Surface_Covers (Messages_Feature),
              "Messages command surface covered");
      Assert (Feature_Command_Surface_Covers (Search_Results_Feature),
              "Search Results command surface covered");
      Assert (Feature_Command_Surface_Covers (Diagnostics_Feature),
              "Diagnostics command surface covered");
      Assert (not Feature_Command_Surface_Covers (Unknown_Feature),
              "unknown feature has no command surface");
   end Test_Feature_Audit_Command_Surface_Covers_All_Features;

   procedure Test_Feature_Audit_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Panel : Feature_Panel_Fingerprint;
      After_Panel  : Feature_Panel_Fingerprint;
      Before_Feature : Feature_Id;
      Before_Gen     : Natural;
      Result         : Feature_Panel_Audit_Result;
   begin
      Editor.State.Init (S);
      Assert (Set_Active_Feature (S.Feature_Panel, Messages_Feature),
              "test can activate Messages");
      Set_Visible (S.Feature_Panel, True);
      Set_Focused (S.Feature_Panel, True);
      Set_Placeholder_Rows (S.Feature_Panel);
      Select_First (S.Feature_Panel);
      Request_Reveal_Row (S.Feature_Panel, 2);
      Before_Panel := Fingerprint (S.Feature_Panel);
      Before_Feature := Active_Feature (S.Feature_Panel);
      Before_Gen := Projection_Generation (S.Feature_Panel);

      Result := Run_Feature_Panel_Audit;
      Assert (Result.Passed, Summary (Result));

      After_Panel := Fingerprint (S.Feature_Panel);
      Assert (Before_Feature = Active_Feature (S.Feature_Panel),
              "audit must not change active feature");
      Assert (Before_Gen = Projection_Generation (S.Feature_Panel),
              "audit must not bump projection generation");
      Assert (Before_Panel = After_Panel,
              "audit must not mutate visibility, focus, rows, or selection");
      Assert (Requested_Reveal_Row (S.Feature_Panel) = 2,
              "audit must not clear pending reveal request");
   end Test_Feature_Audit_Is_Side_Effect_Free;

   procedure Test_Generic_Commands_Delegate_For_Feature
     (Feature : Feature_Id;
      Show_Command : Editor.Commands.Command_Id)
   is
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Result := Editor.Executor.Execute_Command_With_Result (S, Show_Command);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "feature show command executes");
      Assert (Active_Feature (S.Feature_Panel) = Feature,
              "feature-specific show command selects expected active feature");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Feature_Panel_Select_Next);
      Assert (Result.Status = Editor.Executor.Command_Executed
                or else Result.Status = Editor.Executor.Command_Unavailable,
              "generic select-next delegates safely");
      Assert (Active_Feature (S.Feature_Panel) = Feature,
              "generic select-next preserves active feature");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Feature_Panel_Open_Selected);
      Assert (Result.Status = Editor.Executor.Command_Executed
                or else Result.Status = Editor.Executor.Command_Unavailable,
              "generic open-selected delegates safely");
      Assert (Active_Feature (S.Feature_Panel) = Feature,
              "generic open-selected preserves active feature");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Clear_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Executed
                or else Result.Status = Editor.Executor.Command_Unavailable,
              "generic clear-active-feature delegates safely");
      Assert (Active_Feature (S.Feature_Panel) = Feature,
              "generic clear preserves active feature");
      Assert (Editor.Feature_Panel_Controller.Assert_Feature_Panel_State_Consistent (S),
              "state remains consistent after generic delegation");
   end Test_Generic_Commands_Delegate_For_Feature;

   procedure Test_Feature_Generic_Commands_Delegate_Matrix
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Test_Generic_Commands_Delegate_For_Feature
        (Outline_Feature, Editor.Commands.Command_Show_Outline);
      Test_Generic_Commands_Delegate_For_Feature
        (Messages_Feature, Editor.Commands.Command_Show_Messages);
      Test_Generic_Commands_Delegate_For_Feature
        (Search_Results_Feature, Editor.Commands.Command_Show_Search_Results_Feature);
      Test_Generic_Commands_Delegate_For_Feature
        (Diagnostics_Feature, Editor.Commands.Command_Diagnostics_Show);

      Editor.State.Init (S);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Feature_Panel_Open_Selected);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "generic open-selected is deterministic with no active rows");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Hide_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "hide is unavailable while panel is hidden");
   end Test_Feature_Generic_Commands_Delegate_Matrix;

   procedure Assert_Stale_Token_Rejected
     (From_Feature : Feature_Id;
      To_Feature   : Feature_Id;
      Context      : String)
   is
      Panel  : Feature_Panel_State;
      Token  : Feature_Projection_Token;
      Before : Feature_Panel_Fingerprint;
   begin
      Assert (Set_Active_Feature (Panel, From_Feature), Context & " setup from feature");
      Set_Placeholder_Rows (Panel);
      Token := Build_Feature_Projection_Token (Panel);
      Assert (Validate_Feature_Projection_Token (Panel, Token),
              Context & " fresh token valid before switch");
      Assert (Set_Active_Feature (Panel, To_Feature), Context & " switch feature");
      Before := Fingerprint (Panel);
      Request_Reveal_Row (Panel, Token, 2);
      Assert (not Validate_Feature_Projection_Token (Panel, Token),
              Context & " cross-feature token rejected");
      Assert (Requested_Reveal_Row (Panel) = 0,
              Context & " stale reveal request rejected");
      Assert (Fingerprint (Panel) = Before,
              Context & " rejected token does not mutate rows or selection");
   end Assert_Stale_Token_Rejected;

   procedure Test_Feature_Cross_Token_Matrix_Rejected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert_Stale_Token_Rejected (Outline_Feature, Messages_Feature,
                                   "Outline token while Messages active");
      Assert_Stale_Token_Rejected (Outline_Feature, Search_Results_Feature,
                                   "Outline token while Search active");
      Assert_Stale_Token_Rejected (Outline_Feature, Diagnostics_Feature,
                                   "Outline token while Diagnostics active");
      Assert_Stale_Token_Rejected (Messages_Feature, Outline_Feature,
                                   "Messages token while Outline active");
      Assert_Stale_Token_Rejected (Messages_Feature, Search_Results_Feature,
                                   "Messages token while Search active");
      Assert_Stale_Token_Rejected (Messages_Feature, Diagnostics_Feature,
                                   "Messages token while Diagnostics active");
      Assert_Stale_Token_Rejected (Search_Results_Feature, Outline_Feature,
                                   "Search token while Outline active");
      Assert_Stale_Token_Rejected (Search_Results_Feature, Messages_Feature,
                                   "Search token while Messages active");
      Assert_Stale_Token_Rejected (Search_Results_Feature, Diagnostics_Feature,
                                   "Search token while Diagnostics active");
      Assert_Stale_Token_Rejected (Diagnostics_Feature, Outline_Feature,
                                   "Diagnostics token while Outline active");
      Assert_Stale_Token_Rejected (Diagnostics_Feature, Messages_Feature,
                                   "Diagnostics token while Messages active");
      Assert_Stale_Token_Rejected (Diagnostics_Feature, Search_Results_Feature,
                                   "Diagnostics token while Search active");
   end Test_Feature_Cross_Token_Matrix_Rejected;

   procedure Test_Feature_Old_Token_Rejected_After_Rebuild_And_Clear
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Panel : Feature_Panel_State;
      Token : Feature_Projection_Token;
   begin
      Assert (Set_Active_Feature (Panel, Outline_Feature), "activate outline");
      Set_Placeholder_Rows (Panel);
      Token := Build_Feature_Projection_Token (Panel);
      Append_Row (Panel, Feature_Row_Item, "new row", "projection rebuild");
      Assert (not Validate_Feature_Projection_Token (Panel, Token),
              "old token rejected after projection rebuild");
      Request_Reveal_Row (Panel, Token, 1);
      Assert (Requested_Reveal_Row (Panel) = 0,
              "stale token cannot request reveal after rebuild");

      Token := Build_Feature_Projection_Token (Panel);
      Clear_Rows (Panel);
      Assert (not Validate_Feature_Projection_Token (Panel, Token),
              "old token rejected after feature clear");
      Request_Reveal_Row (Panel, Token, 1);
      Assert (Requested_Reveal_Row (Panel) = 0,
              "stale token cannot request reveal after clear");
   end Test_Feature_Old_Token_Rejected_After_Rebuild_And_Clear;

   procedure Test_Feature_Old_Token_Rejected_After_Lifecycle_Close
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Token : Feature_Projection_Token;
   begin
      Editor.State.Init (S);
      Assert (Set_Active_Feature (S.Feature_Panel, Search_Results_Feature),
              "activate search results");
      Set_Placeholder_Rows (S.Feature_Panel);
      Token := Build_Feature_Projection_Token (S.Feature_Panel);
      Editor.Feature_Panel_Controller.Reset_All_Features_For_Buffer_Close (S, 1);
      Assert (not Validate_Feature_Projection_Token (S.Feature_Panel, Token),
              "old token rejected after buffer close");

      Set_Placeholder_Rows (S.Feature_Panel);
      Token := Build_Feature_Projection_Token (S.Feature_Panel);
      Editor.Feature_Panel_Controller.Reset_All_Features_For_Project_Close (S);
      Assert (not Validate_Feature_Projection_Token (S.Feature_Panel, Token),
              "old token rejected after project close");

      Set_Placeholder_Rows (S.Feature_Panel);
      Token := Build_Feature_Projection_Token (S.Feature_Panel);
      Editor.Feature_Panel_Controller.Reset_All_Features_For_Workspace_Close (S);
      Assert (not Validate_Feature_Projection_Token (S.Feature_Panel, Token),
              "old token rejected after workspace close");
   end Test_Feature_Old_Token_Rejected_After_Lifecycle_Close;

   procedure Test_Feature_Long_Session_Audit_Does_Not_Change_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      for I in 1 .. 5 loop
         Assert_Audit_Passed ("long-session audit pass" & Natural'Image (I));
         Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Outline_Feature),
                 "show outline");
         Assert_Audit_Passed ("after outline" & Natural'Image (I));
         Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Messages_Feature),
                 "show messages");
         Assert_Audit_Passed ("after messages" & Natural'Image (I));
         Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Search_Results_Feature),
                 "show search results");
         Assert_Audit_Passed ("after search" & Natural'Image (I));
         Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Diagnostics_Feature),
                 "show diagnostics");
         Assert_Audit_Passed ("after diagnostics" & Natural'Image (I));
         Assert (Editor.Feature_Panel_Controller.Assert_Feature_Panel_State_Consistent (S),
                 "mixed feature state remains consistent");
      end loop;
   end Test_Feature_Long_Session_Audit_Does_Not_Change_State;


   procedure Test_Four_Feature_Clear_Active_Only_Clears_Active_Feature
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Info_Message,
         "message survives inactive clear");
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics, Editor.Feature_Diagnostics.Diagnostic_Warning,
         "diagnostic cleared when active", Source_Label => "phase158");
      Editor.Feature_Search_Results.Run_Active_Buffer_Search
        (S.Feature_Search_Results, Query => "alpha",
         Snapshot_Text => "alpha beta alpha", Source_Label => "buffer",
         Target_Buffer => 1);

      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) > 0,
              "Messages setup has rows");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) > 0,
              "Diagnostics setup has rows");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) > 0,
              "Search Results setup has rows");

      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Diagnostics_Feature),
              "activate Diagnostics before clear");
      Assert (Editor.Feature_Panel_Controller.Dispatch_Active_Feature_Clear (S),
              "clear active Diagnostics feature");

      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "active Diagnostics rows are cleared");
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) > 0,
              "inactive Messages rows survive active clear");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) > 0,
              "inactive Search Results rows survive active clear");
      Assert_Audit_Passed ("after active-only clear");
   end Test_Four_Feature_Clear_Active_Only_Clears_Active_Feature;

   procedure Test_Four_Feature_Workspace_Close_Preserves_Command_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Generic : constant String :=
        Editor.Commands.Stable_Command_Name
          (Editor.Commands.Command_Feature_Panel_Open_Selected);
      Before_Diagnostics : constant String :=
        Editor.Commands.Stable_Command_Name
          (Editor.Commands.Command_Diagnostics_Show);
   begin
      Editor.State.Init (S);
      Assert_Audit_Passed ("before workspace close metadata check");
      Editor.Feature_Panel_Controller.Reset_All_Features_For_Workspace_Close (S);
      Assert (Editor.Commands.Has_Descriptor
                (Editor.Commands.Command_Feature_Panel_Open_Selected),
              "workspace close preserves generic command descriptor");
      Assert (Editor.Commands.Has_Descriptor
                (Editor.Commands.Command_Diagnostics_Show),
              "workspace close preserves Diagnostics command descriptor");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Feature_Panel_Open_Selected) = Before_Generic,
              "workspace close preserves generic stable command name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Diagnostics_Show) = Before_Diagnostics,
              "workspace close preserves Diagnostics stable command name");
      Assert_Audit_Passed ("after workspace close metadata check");
   end Test_Four_Feature_Workspace_Close_Preserves_Command_Metadata;


   procedure Test_Phase203_Feature_Panel_Contract_Review_Default_Passes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Review : Feature_Panel_Contract_Review;
   begin
      Editor.State.Init (S);
      Review := Review_Feature_Panel_Contract (S);
      Assert (Review.Review_Passed,
              Build_Feature_Panel_Contract_Review_Feedback (Review));
      Assert (Review.Generic_State_Bounded,
              "Phase 203 generic Feature Panel state remains bounded");
      Assert (Review.Active_Feature_Valid,
              "Phase 203 active feature remains known");
      Assert (Review.Rows_Transient,
              "Phase 203 rows remain transient");
      Assert (Review.Command_Surface_Intact,
              "Phase 203 preserves Phase 202 command surface review");
      Assert (Review.Public_Build_Guardrail_Intact,
              "Phase 203 preserves public-build regression manifest");
   end Test_Phase203_Feature_Panel_Contract_Review_Default_Passes;

   procedure Test_Phase203_Feature_Panel_Contract_Review_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Panel : Feature_Panel_Fingerprint;
      After_Panel  : Feature_Panel_Fingerprint;
      Before_Feature : Feature_Id;
      Before_Gen     : Natural;
      Before_Reveal  : Natural;
      Review         : Feature_Panel_Contract_Review;
   begin
      Editor.State.Init (S);
      Assert (Set_Active_Feature (S.Feature_Panel, Messages_Feature),
              "test can activate Messages");
      Set_Visible (S.Feature_Panel, True);
      Set_Focused (S.Feature_Panel, True);
      Set_Placeholder_Rows (S.Feature_Panel);
      Select_First (S.Feature_Panel);
      Request_Reveal_Row (S.Feature_Panel, 2);
      Before_Panel := Fingerprint (S.Feature_Panel);
      Before_Feature := Active_Feature (S.Feature_Panel);
      Before_Gen := Projection_Generation (S.Feature_Panel);
      Before_Reveal := Requested_Reveal_Row (S.Feature_Panel);

      Review := Review_Feature_Panel_Contract (S);
      Assert (Review.Review_Passed,
              Build_Feature_Panel_Contract_Review_Feedback (Review));

      After_Panel := Fingerprint (S.Feature_Panel);
      Assert (Before_Panel = After_Panel,
              "Phase 203 contract review must not mutate panel fingerprint");
      Assert (Before_Feature = Active_Feature (S.Feature_Panel),
              "Phase 203 contract review must not change active feature");
      Assert (Before_Gen = Projection_Generation (S.Feature_Panel),
              "Phase 203 contract review must not bump projection generation");
      Assert (Before_Reveal = Requested_Reveal_Row (S.Feature_Panel),
              "Phase 203 contract review must not clear reveal request");
   end Test_Phase203_Feature_Panel_Contract_Review_Is_Side_Effect_Free;

   procedure Test_Phase203_Feature_Panel_Contract_Review_Feedback_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Review : Feature_Panel_Contract_Review;
   begin
      Review.Review_Passed := True;
      Assert (Build_Feature_Panel_Contract_Review_Feedback (Review) =
                "Feature Panel: contract healthy",
              "healthy feedback is canonical");

      Review := (others => True);
      Review.Review_Passed := False;
      Review.Active_Feature_Valid := False;
      Assert (Build_Feature_Panel_Contract_Review_Feedback (Review) =
                "Feature Panel: invalid active feature",
              "invalid active feature feedback is canonical");

      Review := (others => True);
      Review.Review_Passed := False;
      Review.Selection_Valid := False;
      Assert (Build_Feature_Panel_Contract_Review_Feedback (Review) =
                "Feature Panel: invalid selection detected",
              "invalid selection feedback is canonical");

      Review := (others => True);
      Review.Review_Passed := False;
      Review.Command_Surface_Intact := False;
      Assert (Build_Feature_Panel_Contract_Review_Feedback (Review) =
                "Feature Panel: command surface review failed",
              "command surface sentinel feedback is canonical");

      Review := (others => True);
      Review.Review_Passed := False;
      Review.Public_Build_Guardrail_Intact := False;
      Assert (Build_Feature_Panel_Contract_Review_Feedback (Review) =
                "Feature Panel: public build guardrail failed",
              "public-build sentinel feedback is canonical");
   end Test_Phase203_Feature_Panel_Contract_Review_Feedback_Is_Deterministic;

   procedure Test_Phase203_Feature_Panel_Row_Replacement_Selection_Stable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Panel : Feature_Panel_State;
      Token : Feature_Projection_Token;
   begin
      Append_Row (Panel, Feature_Row_Item, "one", Activatable => True,
                  Has_Target => True, Action_Id => 1);
      Append_Row (Panel, Feature_Row_Item, "two", Activatable => True,
                  Has_Target => True, Action_Id => 2);
      Select_Row (Panel, 2);
      Token := Build_Feature_Projection_Token (Panel);
      Assert (Selected_Row (Panel) = 2,
              "test starts with selected second row");

      Clear_Rows (Panel);
      Assert (Row_Count (Panel) = 0,
              "empty row replacement clears rows");
      Assert (Selected_Row (Panel) = 0,
              "empty row replacement clears selection");
      Assert (not Validate_Feature_Projection_Token (Panel, Token),
              "empty row replacement rejects stale target token");

      Append_Row (Panel, Feature_Row_Item, "replacement", Activatable => True,
                  Has_Target => True, Action_Id => 3);
      Assert (Row_Count (Panel) = 1,
              "non-empty replacement can append new transient row");
      Assert (Selected_Row (Panel) = 0,
              "replacement does not invent selection");
      Select_Row (Panel, 99);
      Assert (Selected_Row (Panel) = 0,
              "invalid replacement selection clears deterministically");
      Select_First (Panel);
      Select_Next (Panel);
      Assert (Selected_Row (Panel) = 1,
              "selection down at last row clamps deterministically");
      Select_Previous (Panel);
      Assert (Selected_Row (Panel) = 1,
              "selection up at first row clamps deterministically");
      Assert (Invariant_Holds (Panel),
              "row replacement and selection mechanics preserve invariant");
   end Test_Phase203_Feature_Panel_Row_Replacement_Selection_Stable;

   procedure Test_Phase203_Feature_Switches_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Features : constant array (Positive range 1 .. 4) of Feature_Id :=
        (Outline_Feature,
         Search_Results_Feature,
         Diagnostics_Feature,
         Messages_Feature);
   begin
      Editor.State.Init (S);
      for F of Features loop
         Assert (Editor.Feature_Panel_Controller.Show_Feature (S, F),
                 "Phase 203 feature switch succeeds deterministically");
         Assert (Active_Feature (S.Feature_Panel) = F,
                 "Phase 203 feature switch selects requested feature");
         Assert (Invariant_Holds (S.Feature_Panel),
                 "Phase 203 feature switch leaves panel invariant intact");
         Assert (Review_Feature_Panel_Contract (S).Review_Passed,
                 "Phase 203 feature switch preserves contract review");
      end loop;
   end Test_Phase203_Feature_Switches_Are_Deterministic;

   overriding procedure Register_Tests
     (T : in out Feature_Panel_Audit_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Feature_Audit_Passes_For_Four_Features'Access,
                        "Feature audit passes for four onboarded features");
      Register_Routine (T, Test_Feature_Audit_Descriptor_Table_Covers_All_Features'Access,
                        "Descriptor table covers all known features");
      Register_Routine (T, Test_Feature_Audit_Dispatch_Covers_All_Features'Access,
                        "Dispatch coverage covers all known features");
      Register_Routine (T, Test_Feature_Audit_Command_Surface_Covers_All_Features'Access,
                        "Feature command surface covers all known features");
      Register_Routine (T, Test_Feature_Audit_Is_Side_Effect_Free'Access,
                        "Feature architecture audit is side-effect-free");
      Register_Routine (T, Test_Feature_Generic_Commands_Delegate_Matrix'Access,
                        "Generic active-feature commands delegate across features");
      Register_Routine (T, Test_Feature_Cross_Token_Matrix_Rejected'Access,
                        "Cross-feature projection tokens are rejected");
      Register_Routine (T, Test_Feature_Old_Token_Rejected_After_Rebuild_And_Clear'Access,
                        "Old tokens are rejected after rebuild and clear");
      Register_Routine (T, Test_Feature_Old_Token_Rejected_After_Lifecycle_Close'Access,
                        "Old tokens are rejected after lifecycle close");
      Register_Routine (T, Test_Feature_Long_Session_Audit_Does_Not_Change_State'Access,
                        "Long-session audits do not change state");
      Register_Routine (T, Test_Four_Feature_Clear_Active_Only_Clears_Active_Feature'Access,
                        "Four-feature clear active clears only active feature");
      Register_Routine (T, Test_Four_Feature_Workspace_Close_Preserves_Command_Metadata'Access,
                        "Four-feature workspace close preserves command metadata");
      Register_Routine
        (T, Test_Phase203_Feature_Panel_Contract_Review_Default_Passes'Access,
         "Phase 203 Feature Panel contract review default passes");
      Register_Routine
        (T, Test_Phase203_Feature_Panel_Contract_Review_Is_Side_Effect_Free'Access,
         "Phase 203 Feature Panel contract review is side-effect-free");
      Register_Routine
        (T, Test_Phase203_Feature_Panel_Contract_Review_Feedback_Is_Deterministic'Access,
         "Phase 203 Feature Panel contract feedback is deterministic");
      Register_Routine
        (T, Test_Phase203_Feature_Panel_Row_Replacement_Selection_Stable'Access,
         "Phase 203 Feature Panel row replacement selection stable");
      Register_Routine
        (T, Test_Phase203_Feature_Switches_Are_Deterministic'Access,
         "Phase 203 Feature Panel switches are deterministic");
   end Register_Tests;

end Editor.Feature_Panel_Audit.Tests;
