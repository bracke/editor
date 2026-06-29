with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Environment_Variables;
with Ada.Strings.Fixed;
with Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Command_Domain;
with Editor.Command_Route_Audit;
with Editor.Commands;
with Editor.Executor;
with Editor.Keybinding_Config;
with Editor.Keybindings;
with Editor.Messages;
with Editor.Settings;
with Editor.State;

package body Editor.Feature_Integration.Tests is

   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Category;
   use type Editor.Feature_Integration.Feature_Integration_Status;
   use type Editor.Keybinding_Config.Keybinding_Config_Status;
   use type Editor.Keybindings.Binding_Result;

   function Contains (Text : String; Pattern : String) return Boolean is
   begin
      return Ada.Strings.Fixed.Index (Text, Pattern) > 0;
   end Contains;

   function Temp_Path (Name : String) return String is
   begin
      return "/tmp/editor_phase114_" & Name & ".keybindings";
   end Temp_Path;

   procedure Write_File (Path : String; Text : String) is
      File : Ada.Text_IO.File_Type;
   begin
      Ada.Text_IO.Create (File, Ada.Text_IO.Out_File, Path);
      Ada.Text_IO.Put (File, Text);
      Ada.Text_IO.Close (File);
   end Write_File;

   procedure Test_Fake_Feature_Command_Failures_Are_Actionable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result   : Feature_Integration_Result;
      Contract : Feature_Command_Contract :=
        (Command                  => Editor.Commands.Command_Open_Command_Palette,
         Kind                     => Feature_Destructive,
         Has_Descriptor           => False,
         Has_Stable_Name          => False,
         Stable_Name_Round_Trips  => False,
         Has_Availability         => False,
         Has_Executor_Handling    => False,
         Destructive_Classified   => False,
         Lifecycle_Classified     => False,
         Configuration_Classified => False,
         Bindable                 => True,
         Expected_Domains         => No_Feature_Domains);
      Text : Unbounded_String;
   begin
      Clear (Result);
      Validate_Command_Contract (Result, Contract);
      Text := To_Unbounded_String (Summary (Result));

      Assert (Status (Result) = Feature_Integration_Failed,
              "incomplete fake feature command must fail the integration audit");
      Assert (Failure_Count (Result) >= 5,
              "incomplete fake feature command must produce focused failures");
      Assert (Contains (To_String (Text), "COMMAND_OPEN_COMMAND_PALETTE"),
              "summary must name the fake command: " & To_String (Text));
      Assert (Contains (To_String (Text), "missing command descriptor"),
              "summary must include descriptor failure: " & To_String (Text));
      Assert (Contains (To_String (Text), "stable name"),
              "summary must include stable-name failure: " & To_String (Text));
      Assert (Contains (To_String (Text), "missing Executor handling"),
              "summary must include executor failure: " & To_String (Text));
      Assert (Contains (To_String (Text), "destructive classification"),
              "summary must include destructive-classification failure: " & To_String (Text));
   end Test_Fake_Feature_Command_Failures_Are_Actionable;

   procedure Test_Complete_Fake_Feature_Command_Contract_Passes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result   : Feature_Integration_Result;
      Domains  : Feature_Side_Effect_Domain_Set := No_Feature_Domains;
      Contract : Feature_Command_Contract;
   begin
      Domains (Domain_Feature_Runtime_State) := True;
      Domains (Domain_Feature_Panel_State) := True;
      Contract :=
        (Command                  => Editor.Commands.Command_Toggle_Problems_Panel,
         Kind                     => Feature_View_Toggle,
         Has_Descriptor           => True,
         Has_Stable_Name          => True,
         Stable_Name_Round_Trips  => True,
         Has_Availability         => True,
         Has_Executor_Handling    => True,
         Destructive_Classified   => False,
         Lifecycle_Classified     => False,
         Configuration_Classified => False,
         Bindable                 => True,
         Expected_Domains         => Domains);

      Clear (Result);
      Validate_Command_Contract (Result, Contract);
      Assert (Status (Result) = Feature_Integration_Ok,
              "complete fake feature command contract must pass: " & Summary (Result));
      Assert (Summary (Result) = "Feature integration audit ok",
              "passing feature summary must be deterministic");
   end Test_Complete_Fake_Feature_Command_Contract_Passes;

   procedure Test_Feature_Route_Contract_Catches_Bypass_And_Double_Dispatch
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result   : Feature_Integration_Result;
      Contract : constant Feature_Route_Contract :=
        (Source                  => Editor.Commands.Command_Toggle_Problems_Panel,
         Expected_Command        => Editor.Commands.Command_Toggle_Problems_Panel,
         Actual_Command          => Editor.Commands.Command_Toggle_Minimap,
         Reached_Executor        => True,
         Mutated_Before_Executor => True,
         Executor_Dispatch_Count => 2);
      Text : Unbounded_String;
   begin
      Clear (Result);
      Validate_Route_Contract (Result, Contract);
      Text := To_Unbounded_String (Summary (Result));
      Assert (Failure_Count (Result) = 3,
              "wrong command, pre-executor mutation, and double dispatch must fail");
      Assert (Contains (To_String (Text), "dispatched wrong Command_Id"),
              "route summary must explain wrong command id: " & To_String (Text));
      Assert (Contains (To_String (Text), "mutated state before Executor"),
              "route summary must explain pre-executor mutation: " & To_String (Text));
      Assert (Contains (To_String (Text), "more than once"),
              "route summary must explain duplicate executor dispatch: " & To_String (Text));
   end Test_Feature_Route_Contract_Catches_Bypass_And_Double_Dispatch;

   procedure Test_Route_Audit_Feature_Summary_Is_Grouped_And_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : Editor.Command_Route_Audit.Route_Audit_Result;
      Text   : Unbounded_String;
   begin
      Editor.Command_Route_Audit.Clear (Result);
      Editor.Command_Route_Audit.Record_Route_Failure
        (Result   => Result,
         Source   => Editor.Command_Route_Audit.Route_From_Feature_Panel,
         Kind     => Editor.Command_Route_Audit.Route_Bypassed_Executor,
         Expected => Editor.Commands.Command_Toggle_Problems_Panel,
         Actual   => Editor.Commands.Command_Toggle_Problems_Panel,
         Message  => "feature panel mutated selection before Executor");
      Editor.Command_Route_Audit.Record_Route_Failure
        (Result   => Result,
         Source   => Editor.Command_Route_Audit.Route_From_Keybinding,
         Kind     => Editor.Command_Route_Audit.Route_Dispatched_More_Than_Once,
         Expected => Editor.Commands.Command_Toggle_Problems_Panel,
         Actual   => Editor.Commands.Command_Toggle_Problems_Panel,
         Message  => "command reached Executor twice");
      Text := To_Unbounded_String (Editor.Command_Route_Audit.Summary (Result));

      Assert (Editor.Command_Route_Audit.Failure_Count (Result) = 2,
              "feature route audit must retain all failures");
      Assert (Contains (To_String (Text), "Feature route audit failed"),
              "feature route summary must have a failure heading: " & To_String (Text));
      Assert (Contains (To_String (Text), "ROUTE_FROM_FEATURE_PANEL"),
              "feature route summary must name feature panel route source: " & To_String (Text));
      Assert (Contains (To_String (Text), "ROUTE_FROM_KEYBINDING"),
              "feature route summary must name keybinding route source: " & To_String (Text));
      Assert (Contains (To_String (Text), "COMMAND_TOGGLE_PROBLEMS_PANEL"),
              "feature route summary must include expected command id: " & To_String (Text));
   end Test_Route_Audit_Feature_Summary_Is_Grouped_And_Deterministic;

   procedure Test_Feature_Render_Projection_Contract_Is_Read_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : Feature_Integration_Result;
   begin
      Clear (Result);
      Validate_Render_Projection
        (Result,
         (Has_Explicit_Layer            => True,
          Uses_Theme_Colours            => True,
          Mutates_Feature_State         => False,
          Mutates_Command_State         => False,
          Mutates_Configuration_State   => False,
          Mutates_Lifecycle_State       => False,
          Corrupts_Existing_Layer_Order => False));
      Assert (Status (Result) = Feature_Integration_Ok,
              "read-only feature render projection must pass");

      Validate_Render_Projection
        (Result,
         (Has_Explicit_Layer            => False,
          Uses_Theme_Colours            => False,
          Mutates_Feature_State         => True,
          Mutates_Command_State         => True,
          Mutates_Configuration_State   => True,
          Mutates_Lifecycle_State       => True,
          Corrupts_Existing_Layer_Order => True));
      Assert (Status (Result) = Feature_Integration_Failed,
              "mutating render projection must fail");
      Assert (Contains (Summary (Result), "mutates feature state"),
              "render projection summary must name feature-state mutation: " & Summary (Result));
      Assert (Contains (Summary (Result), "explicit render layer"),
              "render projection summary must require explicit layer: " & Summary (Result));
   end Test_Feature_Render_Projection_Contract_Is_Read_Only;

   procedure Test_Feature_Persistence_Contract_Prevents_Leakage
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : Feature_Integration_Result;
   begin
      Clear (Result);
      Validate_Persistence_Contract
        (Result,
         (Persists_To_Settings    => False,
          Persists_To_Keybindings => False,
          Persists_To_Workspace   => False,
          Persists_To_Recent      => False,
          Persists_Dirty_Text     => False,
          Persists_Pending_State  => False,
          Explicit_Scope_Declared => True));
      Assert (Status (Result) = Feature_Integration_Ok,
              "explicit no-persistence feature contract must pass");

      Validate_Persistence_Contract
        (Result,
         (Persists_To_Settings    => False,
          Persists_To_Keybindings => True,
          Persists_To_Workspace   => False,
          Persists_To_Recent      => False,
          Persists_Dirty_Text     => True,
          Persists_Pending_State  => True,
          Explicit_Scope_Declared => False));
      Assert (Status (Result) = Feature_Integration_Failed,
              "leaking feature persistence contract must fail");
      Assert (Contains (Summary (Result), "dirty text"),
              "persistence summary must reject dirty-text persistence: " & Summary (Result));
      Assert (Contains (Summary (Result), "pending transitions"),
              "persistence summary must reject pending-transition persistence: " & Summary (Result));
      Assert (Contains (Summary (Result), "keybinding config"),
              "persistence summary must reject keybinding leakage: " & Summary (Result));
   end Test_Feature_Persistence_Contract_Prevents_Leakage;


   procedure Test_Feature_Side_Effect_Domains_Are_Expressible
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Allowed : Editor.Command_Domain.Command_Side_Effect_Domain_Set :=
        Editor.Command_Domain.No_Domains;
   begin
      Allowed (Editor.Command_Domain.Domain_Feature_Runtime_State) := True;
      Allowed (Editor.Command_Domain.Domain_Feature_Project_State) := True;
      Allowed (Editor.Command_Domain.Domain_Feature_Workspace_State) := True;
      Allowed (Editor.Command_Domain.Domain_Feature_Settings) := True;
      Allowed (Editor.Command_Domain.Domain_Feature_Render_Projection) := True;
      Allowed (Editor.Command_Domain.Domain_Feature_Panel_State) := True;

      Assert (Allowed (Editor.Command_Domain.Domain_Feature_Runtime_State),
              "feature runtime state side-effect domain must be expressible");
      Assert
        (Editor.Command_Domain.Command_Side_Effect_Domain'Image
           (Editor.Command_Domain.Domain_Feature_Render_Projection) =
         "DOMAIN_FEATURE_RENDER_PROJECTION",
         "feature render projection domain must have deterministic audit name");
   end Test_Feature_Side_Effect_Domains_Are_Expressible;

   procedure Test_Feature_Keybinding_Unknown_Command_Is_Rejected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path   : constant String := Temp_Path ("unknown_feature_command");
      Config : Editor.Keybinding_Config.Keybinding_Config_Model;
      Status : Editor.Keybinding_Config.Keybinding_Config_Status;
      Actual : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      Write_File
        (Path,
         "editor-keybindings-version=1" & ASCII.LF &
         "[bindings]" & ASCII.LF &
         "future-feature-toggle=Ctrl+Alt+F" & ASCII.LF &
         "toggle-problems-panel=Ctrl+Alt+P" & ASCII.LF);

      Editor.Keybinding_Config.Load_From_File (Path, Config, Status);
      Assert (Status = Editor.Keybinding_Config.Keybinding_Config_Partial_Load,
              "unknown future feature command must be diagnosed as partial load");
      Editor.Keybinding_Config.Apply_To_Runtime (Config);
      Assert
        (Editor.Keybindings.Resolve
           ((Key => Editor.Keybindings.Key_F,
             Modifiers => (Ctrl => True, Alt => True, Shift => False, Meta => False)),
            Actual) = Editor.Keybindings.No_Binding,
         "unknown feature command must not create a runtime binding");
      Assert
        (Editor.Keybindings.Resolve
           ((Key => Editor.Keybindings.Key_P,
             Modifiers => (Ctrl => True, Alt => True, Shift => False, Meta => False)),
            Actual) = Editor.Keybindings.Bound_Command
         and then Actual = Editor.Commands.Command_Toggle_Problems_Panel,
         "known feature-like panel command must remain bindable");
      Editor.Keybindings.Reset_To_Defaults;
   end Test_Feature_Keybinding_Unknown_Command_Is_Rejected;

   procedure Test_Feature_Command_Palette_Projection_Uses_Generic_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Found      : Boolean := False;
      D          : Editor.Commands.Command_Descriptor;
   begin
      Editor.State.Init (S);
      Editor.Executor.Command_Palette_Candidates (S, Candidates);

      for C of Candidates loop
         if C.Id = Editor.Commands.Command_Toggle_Problems_Panel then
            Found := True;
            D := Editor.Commands.Descriptor (C.Id);
            Assert (To_String (C.Label) = To_String (D.Name),
                    "feature-like palette label must come from descriptor");
            Assert (To_String (C.Description) = To_String (D.Description),
                    "feature-like palette description must come from descriptor");
            Assert (C.Category = D.Category,
                    "feature-like palette category must come from descriptor");
         end if;
      end loop;
      Assert (Found,
              "feature-like panel command must appear through generic palette projection");
   end Test_Feature_Command_Palette_Projection_Uses_Generic_Metadata;

   procedure Test_Post_Baseline_Long_Run_Feature_Readiness_Scenario
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S               : Editor.State.State_Type;
      Metadata_Before : Natural;
      Metadata_After  : Natural;
      Key_Before      : Natural;
      Key_After       : Natural;
      Settings_Before : Natural;
      Settings_After  : Natural;
      Allowed         : Editor.Command_Domain.Command_Side_Effect_Domain_Set :=
        Editor.Command_Domain.No_Domains;
      Before          : Editor.State.State_Type;
      After           : Editor.State.State_Type;
   begin
      Ada.Environment_Variables.Clear ("EDITOR_KEYBINDINGS_PATH");
      Editor.Keybindings.Reset_To_Defaults;
      Editor.State.Init (S);
      Editor.Settings.Set_Command_Palette_Show_Keybindings (S.Settings, True);
      Editor.Keybindings.Reset_To_Defaults;
      Metadata_Before := Editor.Command_Domain.Command_Metadata_Fingerprint;
      Key_Before := Editor.Command_Domain.Active_Keybindings_Fingerprint;
      Settings_Before := Editor.Command_Domain.Settings_Fingerprint (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Open_Command_Palette);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Problems_Panel);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Search_Results_Move_Down);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Minimap);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Reload_Keybindings);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_All);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cancel_Pending_Transition);

      Metadata_After := Editor.Command_Domain.Command_Metadata_Fingerprint;
      Key_After := Editor.Command_Domain.Active_Keybindings_Fingerprint;
      Settings_After := Editor.Command_Domain.Settings_Fingerprint (S);

      Assert (Metadata_Before = Metadata_After,
              "long-run feature-readiness scenario must not mutate command metadata");
      Assert (Key_Before = Key_After,
              "long-run feature-readiness scenario must keep keybindings separated from feature-like commands");
      Assert (Settings_Before /= Settings_After,
              "configuration command stand-in must alter only settings/configuration state");
      Assert (Editor.Messages.Count (S.Messages) <= 3,
              "scenario should respect visible-message cap for primary outcomes");

      Before := S;
      After := S;
      Editor.Executor.Execute_Command (After, Editor.Commands.Command_Toggle_Problems_Panel);
      Allowed (Editor.Command_Domain.Domain_Panel_State) := True;
      Allowed (Editor.Command_Domain.Domain_Messages) := True;
      Editor.Command_Domain.Assert_Command_Mutates_Only
        (Before, After, Allowed, "feature-like panel command domain isolation");
   end Test_Post_Baseline_Long_Run_Feature_Readiness_Scenario;



   procedure Test_Phase_118_Reference_Feature_Panel_Audit_Passes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : Feature_Integration_Result;
   begin
      Clear (Result);
      Validate_Reference_Feature_Panel (Result);
      Assert (Status (Result) = Feature_Integration_Ok,
              "frozen Feature_Panel reference-module audit must pass: " &
              Summary (Result));
   end Test_Phase_118_Reference_Feature_Panel_Audit_Passes;



   procedure Test_Phase_119_Outline_Content_Foundation_Audit_Passes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : Feature_Integration_Result;
   begin
      Clear (Result);
      Validate_Outline_Content_Foundation (Result);
      Assert (Status (Result) = Feature_Integration_Ok,
              "outline content-foundation audit must pass: " & Summary (Result));
   end Test_Phase_119_Outline_Content_Foundation_Audit_Passes;


   procedure Test_Phase_118_Next_Feature_Readiness_Checklist_Is_Actionable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : Feature_Integration_Result;
   begin
      Clear (Result);
      Add_Failure
        (Result, Editor.Commands.Command_Focus_Feature_Panel,
         "Feature_Panel: missing disabled reason for Focus");
      Add_Failure
        (Result, Editor.Commands.Command_Feature_Panel_Open_Selected,
         "Feature_Panel: missing route test for Open Selected");
      Add_Failure
        (Result, Editor.Commands.Command_Save_Workspace_State,
         "Feature_Panel: missing persistence exclusion check");
      Assert (Status (Result) = Feature_Integration_Failed,
              "sample next-feature readiness failures must fail the audit");
      Assert (Contains (Summary (Result), "missing disabled reason for Focus"),
              "readiness summary must name missing Focus disabled reason");
      Assert (Contains (Summary (Result), "missing route test for Open Selected"),
              "readiness summary must name missing Open Selected route test");
      Assert (Contains (Summary (Result), "missing persistence exclusion check"),
              "readiness summary must name missing persistence exclusion check");
   end Test_Phase_118_Next_Feature_Readiness_Checklist_Is_Actionable;

   overriding function Name
     (T : Feature_Integration_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Feature_Integration.Tests");
   end Name;

   overriding procedure Register_Tests
     (T : in out Feature_Integration_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Fake_Feature_Command_Failures_Are_Actionable'Access,
         "Phase 114 Fake Feature Command Failures Are Actionable");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Complete_Fake_Feature_Command_Contract_Passes'Access,
         "Phase 114 Complete Fake Feature Command Contract Passes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Feature_Route_Contract_Catches_Bypass_And_Double_Dispatch'Access,
         "Phase 114 Feature Route Contract Catches Bypass And Double Dispatch");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Route_Audit_Feature_Summary_Is_Grouped_And_Deterministic'Access,
         "Phase 114 Route Audit Feature Summary Is Grouped And Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Feature_Render_Projection_Contract_Is_Read_Only'Access,
         "Phase 114 Feature Render Projection Contract Is Read Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Feature_Persistence_Contract_Prevents_Leakage'Access,
         "Phase 114 Feature Persistence Contract Prevents Leakage");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Feature_Side_Effect_Domains_Are_Expressible'Access,
         "Phase 114 Feature Side Effect Domains Are Expressible");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Feature_Keybinding_Unknown_Command_Is_Rejected'Access,
         "Phase 114 Feature Keybinding Unknown Command Is Rejected");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Feature_Command_Palette_Projection_Uses_Generic_Metadata'Access,
         "Phase 114 Feature Command Palette Projection Uses Generic Metadata");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Post_Baseline_Long_Run_Feature_Readiness_Scenario'Access,
         "Phase 114 Post Baseline Long Run Feature Readiness Scenario");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase_118_Reference_Feature_Panel_Audit_Passes'Access,
         "Phase 118 Reference Feature Panel Audit Passes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase_119_Outline_Content_Foundation_Audit_Passes'Access,
         "Phase 119 Outline Content Foundation Audit Passes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase_118_Next_Feature_Readiness_Checklist_Is_Actionable'Access,
         "Phase 118 Next Feature Readiness Checklist Is Actionable");
   end Register_Tests;

end Editor.Feature_Integration.Tests;
