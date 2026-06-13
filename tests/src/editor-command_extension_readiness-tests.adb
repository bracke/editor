with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Containers;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;
with Editor.Command_Domain;
with Editor.Command_Integration_Checklist;
with Editor.Command_Palette;
with Editor.Command_Route_Audit;
with Editor.Commands;
with Editor.Executor;
with Editor.Keybinding_Config;
with Editor.Keybindings;
with Editor.Messages;
with Editor.Recent_Projects;
with Editor.Settings;
with Editor.State;

package body Editor.Command_Extension_Readiness.Tests is

   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Visibility;
   use type Editor.Commands.Command_Category;
   use type Editor.Keybinding_Config.Keybinding_Config_Status;
   use type Editor.Keybindings.Binding_Result;
   use type Ada.Containers.Count_Type;

   function Contains (Text : String; Pattern : String) return Boolean is
   begin
      return Ada.Strings.Fixed.Index (Text, Pattern) > 0;
   end Contains;

   function Temp_Path (Name : String) return String is
   begin
      return "/tmp/editor_phase113_" & Name & ".keybindings";
   end Temp_Path;

   procedure Write_File (Path : String; Text : String) is
      File : Ada.Text_IO.File_Type;
   begin
      Ada.Text_IO.Create (File, Ada.Text_IO.Out_File, Path);
      Ada.Text_IO.Put (File, Text);
      Ada.Text_IO.Close (File);
   end Write_File;

   procedure Test_Checklist_Accepts_Current_Registry
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : Editor.Commands.Command_Descriptor;
   begin
      for I in 1 .. Editor.Commands.Command_Count loop
         declare
            Id : constant Editor.Commands.Command_Id := Editor.Commands.Command_At (I);
         begin
            if Editor.Commands.Is_Concrete_Command (Id) then
               Editor.Command_Integration_Checklist.Assert_Ready_For_User_Command (Id);
               if Editor.Commands.Is_Bindable_Command (Id) then
                  Editor.Command_Integration_Checklist.Assert_Ready_For_Bindable_Command (Id);
               end if;

               D := Editor.Commands.Descriptor (Id);
               if D.Destructive then
                  Editor.Command_Integration_Checklist.Assert_Ready_For_Destructive_Command (Id);
               end if;
               if D.Configuration then
                  Editor.Command_Integration_Checklist.Assert_Ready_For_Configuration_Command (Id);
               end if;
               if D.Lifecycle then
                  Editor.Command_Integration_Checklist.Assert_Ready_For_Lifecycle_Command (Id);
               end if;
            end if;
         end;
      end loop;
   end Test_Checklist_Accepts_Current_Registry;

   procedure Test_Audit_Summary_Groups_Future_Command_Failures
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Failures : Editor.Commands.Command_Audit_Failure_Vectors.Vector;
      Summary  : Unbounded_String;
   begin
      Failures.Append
        (Editor.Commands.Command_Audit_Failure'
           (Kind => Editor.Commands.Missing_Stable_Name,
          Command => Editor.Commands.Command_Save_Keybindings));
      Failures.Append
        (Editor.Commands.Command_Audit_Failure'
           (Kind => Editor.Commands.Missing_Classification,
          Command => Editor.Commands.Command_Reset_Settings_To_Defaults));
      Failures.Append
        (Editor.Commands.Command_Audit_Failure'
           (Kind => Editor.Commands.Route_Bypasses_Executor,
          Command => Editor.Commands.Command_Open_Project));

      Summary := To_Unbounded_String (Editor.Commands.Command_Audit_Summary (Failures));
      Assert (Contains (To_String (Summary), "Command audit failed"),
              "summary must explain that the command audit failed");
      Assert (Contains (To_String (Summary), "COMMAND_SAVE_KEYBINDINGS"),
              "summary must identify command id with missing stable name");
      Assert (Contains (To_String (Summary), "missing stable command name"),
              "summary must include actionable stable-name wording");
      Assert (Contains (To_String (Summary), "destructive command missing destructive classification")
              or else Contains (To_String (Summary), "missing classification"),
              "summary must include actionable classification wording");
      Assert (Contains (To_String (Summary), "route bypasses Executor"),
              "summary must include route bypass wording");
   end Test_Audit_Summary_Groups_Future_Command_Failures;

   procedure Test_Domain_Fingerprints_Are_Stable_For_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Metadata_Before : Natural;
      Metadata_After  : Natural;
      Settings_Before : Natural;
      Settings_After  : Natural;
   begin
      Editor.State.Init (S);
      Editor.Settings.Set_Minimap_Visible (S.Settings, False);
      Metadata_Before := Editor.Command_Domain.Command_Metadata_Fingerprint;
      Settings_Before := Editor.Command_Domain.Settings_Fingerprint (S);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Reset_Settings_To_Defaults);
      Metadata_After := Editor.Command_Domain.Command_Metadata_Fingerprint;
      Settings_After := Editor.Command_Domain.Settings_Fingerprint (S);

      Assert (Metadata_Before = Metadata_After,
              "command metadata fingerprint must not change after settings command");
      Assert (Settings_Before /= Settings_After,
              "settings fingerprint must change after a settings command");
   end Test_Domain_Fingerprints_Are_Stable_For_Metadata;

   procedure Test_Side_Effect_Domain_Helper_Allows_Focused_Settings_Mutation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Before  : Editor.State.State_Type;
      After   : Editor.State.State_Type;
      Allowed : Editor.Command_Domain.Command_Side_Effect_Domain_Set :=
        Editor.Command_Domain.No_Domains;
   begin
      Editor.State.Init (Before);
      Editor.Settings.Set_Minimap_Visible (Before.Settings, False);
      After := Before;
      Editor.Executor.Execute_Command
        (After, Editor.Commands.Command_Reset_Settings_To_Defaults);
      Allowed (Editor.Command_Domain.Domain_Settings_Runtime) := True;
      Allowed (Editor.Command_Domain.Domain_Messages) := True;
      Editor.Command_Domain.Assert_Command_Mutates_Only
        (Before, After, Allowed, "reset settings domain isolation");
   end Test_Side_Effect_Domain_Helper_Allows_Focused_Settings_Mutation;

   procedure Test_Phase559_Domain_Helper_Captures_Recent_Project_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Before  : Editor.State.State_Type;
      After   : Editor.State.State_Type;
      B        : Editor.Command_Domain.Command_Domain_Summary;
      A        : Editor.Command_Domain.Command_Domain_Summary;
      Allowed  : Editor.Command_Domain.Command_Side_Effect_Domain_Set :=
        Editor.Command_Domain.No_Domains;
   begin
      Editor.State.Init (Before);
      Editor.Recent_Projects.Add_Or_Promote
        (Before.Recent_Projects, "/tmp/phase559-domain-a", "domain-a", 1);
      Editor.Recent_Projects.Add_Or_Promote
        (Before.Recent_Projects, "/tmp/phase559-domain-b", "domain-b", 2);
      Before.Recent_Project_Selected_Index := 0;
      After := Before;

      Editor.Executor.Execute_Command
        (After, Editor.Commands.Command_Select_Next_Recent_Project);

      B := Editor.Command_Domain.Summary (Before);
      A := Editor.Command_Domain.Summary (After);
      Assert (B.Recent_Project_Count = A.Recent_Project_Count,
              "recent selection must not change the entry count");
      Assert (B.Recent_Project_Selection /= A.Recent_Project_Selection,
              "domain summary must track transient Recent Projects selection");

      Allowed (Editor.Command_Domain.Domain_Recent_Projects) := True;
      Allowed (Editor.Command_Domain.Domain_Messages) := True;
      Editor.Command_Domain.Assert_Command_Mutates_Only
        (Before, After, Allowed,
         "recent project selection domain isolation");
   end Test_Phase559_Domain_Helper_Captures_Recent_Project_Selection;

   procedure Test_Palette_Metadata_Comes_From_Descriptor
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
         if C.Id = Editor.Commands.Command_Save_File then
            Found := True;
            D := Editor.Commands.Descriptor (C.Id);
            Assert (To_String (C.Label) = To_String (D.Name),
                    "palette row label must come from descriptor");
            Assert (To_String (C.Description) = To_String (D.Description),
                    "palette row description must come from descriptor");
            Assert (C.Category = D.Category,
                    "palette row category must come from descriptor");
         end if;
      end loop;
      Assert (Found, "save command must appear as a descriptor-driven palette row");
   end Test_Palette_Metadata_Comes_From_Descriptor;

   procedure Test_Future_Keybinding_Config_Is_Forward_Tolerant
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path   : constant String := Temp_Path ("future_commands");
      Config : Editor.Keybinding_Config.Keybinding_Config_Model;
      Status : Editor.Keybinding_Config.Keybinding_Config_Status;
      Actual : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      Write_File
        (Path,
         "editor-keybindings-version=1" & ASCII.LF &
         "[bindings]" & ASCII.LF &
         "unknown-command=Ctrl+Alt+W" & ASCII.LF &
         "future-command=Ctrl+Alt+F" & ASCII.LF &
         "no-command=Ctrl+Alt+N" & ASCII.LF &
         "file.save=Ctrl+Alt+S" & ASCII.LF);

      Editor.Keybinding_Config.Load_From_File (Path, Config, Status);
      Assert (Status = Editor.Keybinding_Config.Keybinding_Config_Partial_Load,
              "unknown/future/non-bindable entries must produce partial load");
      Editor.Keybinding_Config.Apply_To_Runtime (Config);
      Assert
        (Editor.Keybindings.Resolve
           ((Key => Editor.Keybindings.Key_S,
             Modifiers => (Ctrl => True, Alt => True, Shift => False, Meta => False)),
            Actual) = Editor.Keybindings.Bound_Command
         and then Actual = Editor.Commands.Command_Save_File,
         "partial keybinding load must preserve valid commands");
      Assert
        (Editor.Keybindings.Resolve
           ((Key => Editor.Keybindings.Key_F,
             Modifiers => (Ctrl => True, Alt => True, Shift => False, Meta => False)),
            Actual) = Editor.Keybindings.No_Binding,
         "unknown future command must not create placeholder runtime bindings");
      Editor.Keybindings.Reset_To_Defaults;
   end Test_Future_Keybinding_Config_Is_Forward_Tolerant;

   procedure Test_Route_Audit_Catches_Future_Bypass
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : Editor.Command_Route_Audit.Route_Audit_Result;
      Text   : Unbounded_String;
   begin
      Editor.Command_Route_Audit.Clear (Result);
      Editor.Command_Route_Audit.Record_Route_Failure
        (Result   => Result,
         Source   => Editor.Command_Route_Audit.Route_From_Command_Palette,
         Kind     => Editor.Command_Route_Audit.Route_Bypassed_Executor,
         Expected => Editor.Commands.Command_Open_Project,
         Actual   => Editor.Commands.Command_Open_Project,
         Message  => "future route mutated state before Executor");
      Text := To_Unbounded_String (Editor.Command_Route_Audit.Summary (Result));
      Assert (Editor.Command_Route_Audit.Failure_Count (Result) = 1,
              "route audit must record bypass failures");
      Assert (Contains (To_String (Text), "Route_Bypassed_Executor")
              or else Contains (To_String (Text), "ROUTE_BYPASSED_EXECUTOR"),
              "route summary must name executor bypass failure");
   end Test_Route_Audit_Catches_Future_Bypass;

   procedure Test_Hidden_Command_Policy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Insert_Newline);
   begin
      Assert (D.Visibility = Editor.Commands.Hidden_Command,
              "hidden command fixture must remain hidden");
      Assert (D.Bindable,
              "hidden does not imply non-bindable");
      Assert (Editor.Commands.Is_Bindable_Command
                (Editor.Commands.Command_Insert_Newline),
              "hidden bindable command must be accepted by bindability policy");
      Assert (not Editor.Commands.Is_Bindable_Command (Editor.Commands.No_Command),
              "No_Command must never be bindable");
      Assert (not Editor.Commands.Is_Concrete_Command (Editor.Commands.No_Command),
              "No_Command must never be executable as a normal command");
   end Test_Hidden_Command_Policy;

   overriding function Name
     (T : Command_Extension_Readiness_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Command_Extension_Readiness.Tests");
   end Name;

   overriding procedure Register_Tests
     (T : in out Command_Extension_Readiness_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Checklist_Accepts_Current_Registry'Access,
         "Phase 113 Checklist Accepts Current Registry");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Audit_Summary_Groups_Future_Command_Failures'Access,
         "Phase 113 Audit Summary Groups Future Command Failures");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Domain_Fingerprints_Are_Stable_For_Metadata'Access,
         "Phase 113 Domain Fingerprints Are Stable For Metadata");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Side_Effect_Domain_Helper_Allows_Focused_Settings_Mutation'Access,
         "Phase 113 Side Effect Domain Helper Allows Focused Settings Mutation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase559_Domain_Helper_Captures_Recent_Project_Selection'Access,
         "Phase 559 domain helper captures Recent Projects selection");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Palette_Metadata_Comes_From_Descriptor'Access,
         "Phase 113 Palette Metadata Comes From Descriptor");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Future_Keybinding_Config_Is_Forward_Tolerant'Access,
         "Phase 113 Future Keybinding Config Is Forward Tolerant");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Route_Audit_Catches_Future_Bypass'Access,
         "Phase 113 Route Audit Catches Future Bypass");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Hidden_Command_Policy'Access,
         "Phase 113 Hidden Command Policy");
   end Register_Tests;

end Editor.Command_Extension_Readiness.Tests;
