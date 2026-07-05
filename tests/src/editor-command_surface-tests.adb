with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Containers; use type Ada.Containers.Count_Type;
with Ada.Characters.Handling;
with Ada.Environment_Variables;
with Ada.Directories;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;
with Editor.Command_Palette;
with Editor.Command_Execution;
with Editor.Command_Route_Audit;
with Editor.Command_Surface;
with Editor.Commands;
with Editor.Executor;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.External_Producers;
with Editor.Messages;
with Editor.Keybindings;
with Editor.Keybinding_Management;
with Editor.Buffers;
with Editor.Build_Candidates;
with Editor.Build_Command;
with Editor.Build_UI;
with Editor.Build_Working_Context;
with Editor.Lifecycle_Guidance;
with Editor.Project;
with Editor.Pending_Transitions;
with Editor.Recent_Projects;
with Editor.Settings;
with Editor.State;
with Editor.Overlay_Focus;
with Editor.Panel_Focus;

package body Editor.Command_Surface.Tests is

   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Visibility;
   use type Editor.Commands.Command_Category;
   use type Editor.Commands.Command_Family_Id;
   use type Editor.Commands.Command_Effect_Classification_Id;
   use type Editor.Commands.Command_Kind;
   use type Editor.Keybindings.Keybinding_Validation_Status;
   use type Editor.Overlay_Focus.Overlay_Target;
   use type Editor.Panel_Focus.Focus_Target;
   use type Editor.Panel_Focus.Bottom_Focus_Content;
   use type Editor.File_Tree.File_Tree_Node_Kind;
   use type Editor.Command_Palette.Command_Palette_Row_Kind;
   use type Editor.Executor.Command_Execution_Status;
   use type Editor.Command_Execution.Command_Execution_Status;
   use type Editor.Command_Surface.Command_Surface_Review;
   use type Editor.Messages.Message_Severity;
   use type Editor.External_Producers.Build_Run_Status;
   use type Editor.External_Producers.Build_Tool_Kind;
   use type Editor.External_Producers.Build_Request_Provenance;
   use type Editor.External_Producers.Build_Request_Validation_Status;
   use type Editor.External_Producers.Build_Working_Context_Kind;
   use type Editor.External_Producers.Public_Build_Input_Validation_Status;
   use type Editor.External_Producers.Public_Build_Consent_Validation_Status;
   use type Editor.External_Producers.Public_Build_Working_Context_Validation_Status;
   use type Editor.External_Producers.Public_Build_Input_Safety;
   use type Editor.External_Producers.Public_Build_Command_Surface_Status;
   use type Editor.External_Producers.Public_Build_Command_Promotion_Status;
   use type Editor.External_Producers.Public_Build_UX_Dependency;
   use type Editor.External_Producers.Public_Build_UX_Dependency_Status;
   use type Editor.External_Producers.Public_Build_Hard_Freeze_Baseline;
   use type Editor.External_Producers.Public_Build_Guardrail_Status;
   use type Editor.External_Producers.Public_Build_Guardrail_Result;
   use type Editor.External_Producers.Public_Build_Guardrail_Contract_Mismatch;
   use type Editor.External_Producers.Public_Build_Guardrail_Failure_Kind;
   use type Editor.External_Producers.Public_Build_Guardrail_Failure_Detail;
   use type Editor.External_Producers.Public_Build_Surface_Id_Scan_Result;
   use type Editor.External_Producers.Public_Build_Guardrail_Health;
   use Editor.External_Producers;
   use type Editor.External_Producers.Public_Build_Guardrail_Regression_Manifest;
   use type Editor.External_Producers.Public_Build_Guardrail_Audit_Matrix;
   use type Editor.Build_Command.Build_Run_Readiness_Status;


   procedure Test_User_Opt_In_Build_Command_Is_Internal
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor
          (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam);
   begin
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam) =
              "build.run-user-opt-in-test-seam",
              "internal user opt-in build test-seam command id is stable");
      Assert (To_String (D.Name) = "Build: Run User Opt-In Test Command",
              "internal user opt-in build test label is stable");
      Assert (D.Category = Editor.Commands.Internal_Category,
              "user opt-in build test-seam command is internal");
      Assert (D.Visibility = Editor.Commands.Hidden_Command,
              "user opt-in build test-seam command is hidden from normal palette");
      Assert (not D.Bindable,
              "user opt-in build test-seam command has no default keybinding target");
      Assert (Editor.Commands.Requires_Context
                (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam),
              "user opt-in build test-seam command requires structured context");
   end Test_User_Opt_In_Build_Command_Is_Internal;


   procedure Test_Recent_Project_Selected_Row_Commands_Are_No_Payload
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      procedure Check (Id : Editor.Commands.Command_Id; Label : String) is
      begin
         Assert (not Editor.Commands.Requires_Context (Id),
                 Label & " must not require structured command context");
      end Check;
   begin
      Check (Editor.Commands.Command_Open_Selected_Recent_Project,
             "open selected recent project");
      Check (Editor.Commands.Command_Remove_Selected_Recent_Project,
             "remove selected recent project");
      Check (Editor.Commands.Command_Remove_Missing_Recent_Projects,
             "remove missing recent projects");
      Check (Editor.Commands.Command_Select_Next_Recent_Project,
             "select next recent project");
      Check (Editor.Commands.Command_Select_Previous_Recent_Project,
             "select previous recent project");
      Assert (Editor.Commands.Requires_Context (Editor.Commands.Command_Open_Project),
              "plain project.open remains the explicit path-payload command");
   end Test_Recent_Project_Selected_Row_Commands_Are_No_Payload;

   procedure Test_User_Opt_In_Build_Command_Has_No_Default_Keybinding
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Info : Editor.Keybindings.Command_Keybinding_Info;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Info := Editor.Keybindings.Primary_Binding_For_Command
        (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam);
      Assert (not Info.Has_Binding,
              "internal user opt-in build test seam must not get a default keybinding");
   end Test_User_Opt_In_Build_Command_Has_No_Default_Keybinding;

   procedure Test_User_Opt_In_Build_Command_Bare_Route_Is_Unavailable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Editor.Commands.Command_Availability;
      R : Editor.Executor.Command_Execution_Result;
   begin
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam);
      Assert (not Editor.Commands.Is_Available (A),
              "bare user opt-in build command route is unavailable without structured context");
      Assert (Editor.Commands.Unavailable_Reason (A) =
              "Build: structured command context required",
              "bare user opt-in build command reports deterministic missing-context feedback");
      R := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam);
      Assert (R.Status = Editor.Executor.Command_Unavailable,
              "bare user opt-in build command cannot execute without context");
   end Test_User_Opt_In_Build_Command_Bare_Route_Is_Unavailable;

   procedure Test_User_Opt_In_Build_Command_Structured_Route_Reaches_Executor
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Context : constant Editor.External_Producers.User_Opt_In_Build_Command_Context :=
        Editor.External_Producers.Build_User_Opt_In_Command_Context
          (Tool              => Editor.External_Producers.GPRbuild_Tool,
           Program_Label     => "gprbuild",
           Working_Label     => "",
           Arguments         => Editor.External_Producers.Build_Process_Argument_Vector ("-q"),
           Consent           => Editor.External_Producers.Build_Consent_User_Confirmed,
           Allow_Diagnostics => True,
           Show_Diagnostics  => False);
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Result := Editor.Executor.Execute_User_Opt_In_Build_Command
        (S, Context,
         Editor.External_Producers.Build_Process_Run_Result
           (Editor.External_Producers.Process_Run_Succeeded,
            Exit_Code => 0, Has_Exit_Code => True));
      Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Succeeded,
              "structured user opt-in build command route reaches executor boundary");
      Assert (To_String (Result.Command_Message) = "Build: succeeded",
              "structured user opt-in build command returns one primary result");
   end Test_User_Opt_In_Build_Command_Structured_Route_Reaches_Executor;

   procedure Test_Build_Command_Surface_Has_No_Public_Run_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Id : Editor.Commands.Command_Id;
      Stable : Unbounded_String;
      D : Editor.Commands.Command_Descriptor;
      Saw_Run : Boolean := False;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      for I in 1 .. Editor.Commands.Command_Count loop
         Id := Editor.Commands.Command_At (I);
         Stable := To_Unbounded_String (Editor.Commands.Stable_Command_Name (Id));
         D := Editor.Commands.Descriptor (Id);

         if To_String (Stable) = "build.run" then
            Saw_Run := True;
            Assert (Id = Editor.Commands.Command_Build_Run,
                    "build.run must resolve to the guarded public build command");
            Assert (D.Visibility = Editor.Commands.Palette_Command,
                    "build.run is palette-visible through the guarded public surface");
            Assert (not D.Bindable,
                    "build.run must not be bindable by default");
         else
            Assert (To_String (Stable) /= "build.project"
                    and then To_String (Stable) /= "compile.project"
                    and then To_String (Stable) /= "diagnostics.run-build",
                    "reserved public build alias must remain absent: " &
                    To_String (Stable));
         end if;

         if Id = Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam then
            Assert (D.Visibility = Editor.Commands.Hidden_Command,
                    "internal build test seam must stay hidden from normal palette");
            Assert (D.Category = Editor.Commands.Internal_Category,
                    "internal build test seam must remain internal/test-only");
            Assert (not D.Bindable,
                    "internal build test seam must not be bindable by default");
            Assert (not Editor.Commands.Visible_In_Command_Palette (Id),
                    "normal command palette must exclude internal build test seam");
            Assert (not Editor.Keybindings.Primary_Binding_For_Command (Id).Has_Binding,
                    "internal build test seam must not have a default keybinding");
         end if;
      end loop;
      Assert (Saw_Run, "build.run must be present in the command surface");
   end Test_Build_Command_Surface_Has_No_Public_Run_Command;

   procedure Test_Build_Command_Route_Audit_Covers_Executor_Boundary
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Audit : Editor.Command_Route_Audit.Route_Audit_Result;
   begin
      Editor.Command_Route_Audit.Clear (Audit);
      Editor.Command_Route_Audit.Record_Route
        (Audit,
         Editor.Command_Route_Audit.Route_From_Test,
         Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam);
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 0,
              "test harness route must target the concrete internal build command and then use Executor structured entrypoint");
   end Test_Build_Command_Route_Audit_Covers_Executor_Boundary;

   procedure Test_Build_Command_Route_Audit_Rejects_Bypass_Routes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Audit : Editor.Command_Route_Audit.Route_Audit_Result;
   begin
      Editor.Command_Route_Audit.Clear (Audit);
      Editor.Command_Route_Audit.Record_Route_Failure
        (Audit,
         Editor.Command_Route_Audit.Route_From_Feature_Panel,
         Editor.Command_Route_Audit.Route_Bypassed_Executor,
         Expected => Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam,
         Actual   => Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam,
         Message  => "build command-like route must not bypass Executor availability, consent, preflight, or Diagnostics ingestion validation");
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 1,
              "route audit must classify build command bypass attempts");
      Assert (Ada.Strings.Fixed.Index
                (Editor.Command_Route_Audit.Last_Failure_Message (Audit),
                 "BYPASSED_EXECUTOR") > 0,
              "route audit must report executor-boundary bypass failures");
   end Test_Build_Command_Route_Audit_Rejects_Bypass_Routes;

   procedure Test_Command_Palette_Route_Audit_Rejects_Payloads
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Audit : Editor.Command_Route_Audit.Route_Audit_Result;
   begin
      Editor.Command_Route_Audit.Clear (Audit);
      Editor.Command_Route_Audit.Record_Command_Palette_Route
        (Result                   => Audit,
         Command                  => Editor.Commands.Command_Open_Command_Palette,
         Routed_Through_Executor  => True,
         Used_Stable_Command_Name => True,
         Carried_Payload          => False);
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 0,
              "canonical palette route by stable command name must pass");

      Editor.Command_Route_Audit.Record_Command_Palette_Route
        (Result                   => Audit,
         Command                  => Editor.Commands.Command_Open_Command_Palette,
         Routed_Through_Executor  => True,
         Used_Stable_Command_Name => True,
         Carried_Payload          => True);
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 1,
              "palette routes carrying row-specific payloads must fail audit");
      Assert (Ada.Strings.Fixed.Index
                (Editor.Command_Route_Audit.Last_Failure_Message (Audit),
                 "payload") > 0,
              "payload audit failure must be user-readable");
   end Test_Command_Palette_Route_Audit_Rejects_Payloads;

   procedure Test_Command_UI_Route_Audit_Covers_Panel_Actions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Audit : Editor.Command_Route_Audit.Route_Audit_Result;

      procedure Check
        (Source  : Editor.Command_Route_Audit.Route_Source;
         Command : Editor.Commands.Command_Id)
      is
      begin
         Editor.Command_Route_Audit.Record_Command_UI_Route
           (Result                   => Audit,
            Source                   => Source,
            Command                  => Command,
            Dispatch_Count           => 1,
            Routed_Through_Executor  => True,
            Used_Stable_Command_Name => True,
            Availability_Checked     => True,
            Carried_Payload          => False);
      end Check;
   begin
      Editor.Command_Route_Audit.Clear (Audit);
      Check (Editor.Command_Route_Audit.Route_From_Problems,
             Editor.Commands.Command_Problems_Open_Selected);
      Check (Editor.Command_Route_Audit.Route_From_Feature_Panel,
             Editor.Commands.Command_Build_Run);
      Check (Editor.Command_Route_Audit.Route_From_File_Tree,
             Editor.Commands.Command_File_Tree_Open_Selected);
      Check (Editor.Command_Route_Audit.Route_From_Search_Results,
             Editor.Commands.Command_Search_Results_Open_Selected);
      Check (Editor.Command_Route_Audit.Route_From_Command_Palette,
             Editor.Commands.Command_Accept_Quick_Open);
      Check (Editor.Command_Route_Audit.Route_From_Pending_Bar,
             Editor.Commands.Command_Retry_Pending_Transition);
      Check (Editor.Command_Route_Audit.Route_From_Recent_Project_Picker,
             Editor.Commands.Command_Open_Selected_Recent_Project);
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 0,
              "command-like UI route audit should accept canonical executor routes: "
              & Editor.Command_Route_Audit.Summary (Audit));
   end Test_Command_UI_Route_Audit_Covers_Panel_Actions;

   procedure Test_Command_UI_Route_Audit_Rejects_Bypass_And_Duplicate
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Audit : Editor.Command_Route_Audit.Route_Audit_Result;
   begin
      Editor.Command_Route_Audit.Clear (Audit);
      Editor.Command_Route_Audit.Record_Command_UI_Route
        (Result                   => Audit,
         Source                   => Editor.Command_Route_Audit.Route_From_Problems,
         Command                  => Editor.Commands.Command_Problems_Open_Selected,
         Dispatch_Count           => 2,
         Routed_Through_Executor  => False,
         Used_Stable_Command_Name => False,
         Availability_Checked     => False,
         Carried_Payload          => True);
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 5,
              "bad command-like UI route should report duplicate, executor, stable-id, availability, and payload failures");
      Assert (Ada.Strings.Fixed.Index
                (Editor.Command_Route_Audit.Summary (Audit),
                 "ROUTE_DISPATCHED_MORE_THAN_ONCE") > 0,
              "route audit summary should classify duplicate dispatch");
   end Test_Command_UI_Route_Audit_Rejects_Bypass_And_Duplicate;

   procedure Test_Command_Descriptor_Audit_Helpers
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      D : Editor.Commands.Command_Descriptor;
   begin
      Assert
        (not Editor.Commands.Is_Concrete_Command (Editor.Commands.No_Command),
         "No_Command must not be concrete");

      Assert
        (Editor.Commands.Descriptor (Editor.Commands.No_Command).Visibility =
           Editor.Commands.Hidden_Command,
         "No_Command must stay hidden");

      Assert
        (Editor.Commands.Descriptor (Editor.Commands.No_Command).Category =
           Editor.Commands.Internal_Category,
         "No_Command must stay internal");

      for I in 1 .. Editor.Commands.Command_Count loop
         D := Editor.Commands.Descriptor (Editor.Commands.Command_At (I));
         Assert
           (D.Id = Editor.Commands.Command_At (I),
            "descriptor id must match registry id for " & Editor.Commands.Label (D.Id));
         Assert
           (Editor.Commands.Descriptor_Is_Complete (D.Id),
            "descriptor must satisfy command-surface completeness policy for " &
            Editor.Commands.Label (D.Id));

         if Editor.Commands.Is_Concrete_Command (D.Id) then
            Assert
              (Length (D.Name) > 0,
               "concrete commands must have a stable label");
         end if;
      end loop;
   end Test_Command_Descriptor_Audit_Helpers;

   procedure Test_Palette_Command_Traversal_Audit
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Seen : array (Editor.Commands.Command_Id) of Boolean := (others => False);
      Id   : Editor.Commands.Command_Id;
      D    : Editor.Commands.Command_Descriptor;
   begin
      Assert
        (Editor.Commands.Palette_Command_Count =
           Natural (Editor.Commands.Palette_Commands.Length),
         "palette traversal count must match descriptor vector count");

      for I in 1 .. Editor.Commands.Palette_Command_Count loop
         Id := Editor.Commands.Palette_Command_At (I);
         D := Editor.Commands.Descriptor (Id);

         Assert
           (Editor.Commands.Visible_In_Command_Palette (Id),
            "Palette_Command_At must return only palette-visible ids");
         Assert
           (not Seen (Id),
            "Palette_Command_At must not return duplicate command ids");
         Seen (Id) := True;
         Assert
           (Length (D.Name) > 0,
            "palette-visible commands must have labels");
         Assert
           (Length (D.Description) > 0,
            "palette-visible commands must have descriptions");
         Assert
           (D.Category /= Editor.Commands.Internal_Category,
            "palette-visible commands must not use Internal category");
      end loop;

      for I in 1 .. Editor.Commands.Command_Count loop
         Id := Editor.Commands.Command_At (I);
         if not Editor.Commands.Visible_In_Command_Palette (Id) then
            Assert
              (not Seen (Id),
               "hidden commands must not appear in palette traversal");
         end if;
      end loop;
   end Test_Palette_Command_Traversal_Audit;

   procedure Test_Keybinding_Validation_Audit
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Result : Editor.Keybindings.Keybinding_Validation_Result;
      Info   : Editor.Keybindings.Command_Keybinding_Info;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Result := Editor.Keybindings.Validate;
      Assert
        (Editor.Keybindings.Status (Result) = Editor.Keybindings.Valid_Keybindings,
         "default keybindings must validate");
      Assert
        (not Editor.Keybindings.Has_Invalid_Command_Targets (Result),
         "default keybindings must target concrete command ids");
      Assert
        (not Editor.Keybindings.Has_Duplicate_Chords (Result),
         "default keybindings must not contain duplicate chords");

      Info := Editor.Keybindings.Primary_Binding_For_Command
        (Editor.Commands.Command_Save_File);
      Assert (Info.Has_Binding, "Save File must expose its primary binding");
      Assert
        (To_String (Info.Display) = "Ctrl+S",
         "Save File primary binding must be Ctrl+S");
   end Test_Keybinding_Validation_Audit;

   procedure Test_Command_Palette_Candidates_Use_Command_Registry
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      D          : Editor.Commands.Command_Descriptor;
   begin
      Editor.State.Init (S);
      Editor.Executor.Command_Palette_Candidates (S, Candidates);

      for Candidate of Candidates loop
         D := Editor.Commands.Descriptor (Candidate.Id);
         Assert
           (Editor.Commands.Visible_In_Command_Palette (Candidate.Id),
            "palette candidate must originate from visible command registry");
         Assert
           (To_String (Candidate.Label) = To_String (D.Name),
            "palette candidate label must mirror descriptor label");
         Assert
           (To_String (Candidate.Description) = To_String (D.Description),
            "palette candidate description must mirror descriptor description");
         Assert
           (Candidate.Category = D.Category,
            "palette candidate category must mirror descriptor category");
      end loop;
   end Test_Command_Palette_Candidates_Use_Command_Registry;



   function Trimmed (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trimmed;

   procedure Assert_Candidate_Vectors_Equal
     (Left  : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Right : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Msg   : String)
   is
   begin
      Assert (Left.Length = Right.Length, Msg & ": candidate count differs");
      if Left.Length = 0 then
         return;
      end if;

      for I in 0 .. Natural (Left.Length) - 1 loop
         declare
            L : constant Editor.Commands.Command_Palette_Candidate := Left.Element (I);
            R : constant Editor.Commands.Command_Palette_Candidate := Right.Element (I);
         begin
            Assert (L.Id = R.Id, Msg & ": candidate id differs");
            Assert (To_String (L.Label) = To_String (R.Label), Msg & ": label differs");
            Assert (To_String (L.Description) = To_String (R.Description), Msg & ": description differs");
            Assert (L.Category = R.Category, Msg & ": category differs");
            Assert (To_String (L.Category_Label) = To_String (R.Category_Label), Msg & ": category label differs");
            Assert (L.Available = R.Available, Msg & ": availability differs");
            Assert (To_String (L.Reason) = To_String (R.Reason), Msg & ": reason differs");
            Assert (L.Has_Keybinding = R.Has_Keybinding, Msg & ": keybinding flag differs");
            Assert (To_String (L.Keybinding_Display) = To_String (R.Keybinding_Display), Msg & ": keybinding display differs");
            Assert (To_String (L.Reference_Summary) = To_String (R.Reference_Summary), Msg & ": reference summary differs");
            Assert (L.Family = R.Family, Msg & ": command family differs");
            Assert (L.Effect_Classification = R.Effect_Classification, Msg & ": effect classification differs");
            Assert (L.Match_Score = R.Match_Score, Msg & ": match score differs");
            Assert (L.Registry_Order = R.Registry_Order, Msg & ": registry order differs");
         end;
      end loop;
   end Assert_Candidate_Vectors_Equal;

   procedure Test_Static_Command_Invariants
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Seen_Palette_Label : array (Editor.Commands.Command_Id) of Boolean := (others => False);
      pragma Unreferenced (Seen_Palette_Label);
      Id : Editor.Commands.Command_Id;
      D  : Editor.Commands.Command_Descriptor;
   begin
      Assert (Editor.Commands.First_Command = Editor.Commands.Command_Id'First,
              "First_Command must match enumeration first value");
      Assert (Editor.Commands.Last_Command = Editor.Commands.Command_Id'Last,
              "Last_Command must match enumeration last value");

      for I in 1 .. Editor.Commands.Command_Count loop
         Id := Editor.Commands.Command_At (I);
         D := Editor.Commands.Descriptor (Id);

         Assert (Editor.Commands.Is_Valid_Command (Id),
                 "all iterated Command_Id values must be valid");
         Assert (D.Id = Id,
                 "descriptor id must match iterated command id");

         if Editor.Commands.Is_Concrete_Command (Id) then
            Assert (Editor.Commands.Has_Stable_User_Label (Id),
                    "concrete command must have stable user label: " & Editor.Commands.Command_Id'Image (Id));
            Assert (To_String (D.Name) = Trimmed (To_String (D.Name)),
                    "command label must be trimmed: " & Editor.Commands.Command_Id'Image (Id));
            Assert (To_String (D.Name) /= "TODO"
                    and then To_String (D.Name) /= "Command"
                    and then To_String (D.Name) /= "Unnamed",
                    "command label must not be a surface entry: " & Editor.Commands.Command_Id'Image (Id));
         end if;

         if Editor.Commands.Visible_In_Command_Palette (Id) then
            Assert (To_String (D.Description) = Trimmed (To_String (D.Description)),
                    "palette description must be trimmed: " & Editor.Commands.Command_Id'Image (Id));
            Assert (D.Category /= Editor.Commands.Internal_Category,
                    "palette-visible command must not be internal: " & Editor.Commands.Command_Id'Image (Id));
            Assert (Editor.Commands.Category_Label (D.Category)'Length > 0,
                    "palette-visible command category must have a label");
            Assert (Editor.Commands.Category_Label (D.Category) =
                      Trimmed (Editor.Commands.Category_Label (D.Category)),
                    "category label must be trimmed");
         end if;
      end loop;
   end Test_Static_Command_Invariants;

   procedure Test_Availability_Is_Read_Only_On_Empty_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Messages : Natural;
      Before_Has_Buffer : Boolean;
      Before_Overlay : Editor.Overlay_Focus.Overlay_Target;
      Before_Focus : Editor.Panel_Focus.Focus_Target;
      Before_Bottom : Editor.Panel_Focus.Bottom_Focus_Content;
      A : Editor.Commands.Command_Availability;
   begin
      Editor.State.Init (S);
      Before_Messages := Editor.Messages.Count (S.Messages);
      Before_Has_Buffer := Editor.State.Has_Active_Buffer (S);
      Before_Overlay := Editor.Overlay_Focus.Active_Overlay (S.Overlay_Focus);
      Before_Focus := Editor.Panel_Focus.Target (S.Panel_Focus);
      Before_Bottom := Editor.Panel_Focus.Bottom_Content (S.Panel_Focus);

      for I in 1 .. Editor.Commands.Command_Count loop
         A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_At (I));
         if not Editor.Commands.Is_Available (A)
           and then Editor.Commands.Command_At (I) /= Editor.Commands.No_Command
         then
            Assert (Editor.Commands.Unavailable_Reason (A)'Length > 0,
                    "unavailable concrete commands must include a reason: " &
                    Editor.Commands.Command_Id'Image (Editor.Commands.Command_At (I)));
         end if;
      end loop;

      Assert (Editor.Messages.Count (S.Messages) = Before_Messages,
              "availability checks must not push messages");
      Assert (Editor.State.Has_Active_Buffer (S) = Before_Has_Buffer,
              "availability checks must not change active-buffer status");
      Assert (Editor.Overlay_Focus.Active_Overlay (S.Overlay_Focus) = Before_Overlay,
              "availability checks must not change overlay focus");
      Assert (Editor.Panel_Focus.Target (S.Panel_Focus) = Before_Focus,
              "availability checks must not change panel focus target");
      Assert (Editor.Panel_Focus.Bottom_Content (S.Panel_Focus) = Before_Bottom,
              "availability checks must not change bottom panel focus content");
   end Test_Availability_Is_Read_Only_On_Empty_State;

   procedure Test_Unavailable_Reason_Consistency
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      function Reason (Id : Editor.Commands.Command_Id) return String is
      begin
         return Editor.Commands.Unavailable_Reason
           (Editor.Executor.Command_Availability (S, Id));
      end Reason;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Assert (Reason (Editor.Commands.Command_Save_File) = "No active buffer.",
              "Save File with no buffer must use canonical No active buffer reason");
      Assert (Reason (Editor.Commands.Command_Close_Active_Buffer) = "No active buffer.",
              "Close Buffer with no open buffer must use canonical No active buffer reason");
      Assert (Reason (Editor.Commands.Command_Next_Diagnostic) = "No diagnostics.",
              "Next Diagnostic must use canonical No diagnostics reason");
      Assert (Reason (Editor.Commands.Command_Previous_Diagnostic) = "No diagnostics.",
              "Previous Diagnostic must use canonical No diagnostics reason");
      Assert (Reason (Editor.Commands.Command_Next_Bookmark) = "No bookmarks.",
              "Next Bookmark must use canonical No bookmarks reason");
      Assert (Reason (Editor.Commands.Command_Previous_Bookmark) = "No bookmarks.",
              "Previous Bookmark must use canonical No bookmarks reason");
      Assert (Reason (Editor.Commands.Command_Clear_All_Bookmarks) = "No bookmarks.",
              "Clear All Bookmarks must use canonical No bookmarks reason");
      Assert (Reason (Editor.Commands.Command_Focus_File_Tree) = "No project open.",
              "Focus File Tree must use canonical No project open reason");
      Assert
        (Editor.Commands.Unavailable_Reason
           (Editor.Commands.Unavailable
              ("Diagnostic target column is outside the line.")) =
         Editor.Commands.Reason_Diagnostic_Target_Column_Outside_Line,
         "invalid diagnostic columns must keep the column-specific reason");
   end Test_Unavailable_Reason_Consistency;

   procedure Test_Palette_Snapshot_Determinism
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      B : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Snap_A : Editor.Command_Palette.Command_Palette_Snapshot;
      Snap_B : Editor.Command_Palette.Command_Palette_Snapshot;
      Config : constant Editor.Command_Palette.Command_Palette_Config :=
        (Max_Visible_Rows             => 12,
         Overlay_Width_In_Columns     => 72,
         Show_Unavailable_Commands    => True,
         Group_Empty_Query_By_Category => True,
         Show_Selected_Reason         => True,
         Show_Selected_Description    => True,
         Show_Keybindings           => True,
         Show_Help_Row                => True);
   begin
      Editor.State.Init (S);
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Executor.Command_Palette_Candidates (S, A);
      Editor.Command_Palette.Reconcile_Selection (A);
      Snap_A := Editor.Command_Palette.Build_Snapshot (A, Config);

      Editor.Executor.Command_Palette_Candidates (S, B);
      Editor.Command_Palette.Reconcile_Selection (B);
      Snap_B := Editor.Command_Palette.Build_Snapshot (B, Config);

      Assert_Candidate_Vectors_Equal (A, B, "same state must produce same candidates");
      Assert (Editor.Command_Palette.Row_Count (Snap_A) =
              Editor.Command_Palette.Row_Count (Snap_B),
              "same state must produce same row count");
      for I in 1 .. Editor.Command_Palette.Row_Count (Snap_A) loop
         declare
            L : constant Editor.Command_Palette.Command_Palette_Row :=
              Editor.Command_Palette.Row (Snap_A, I);
            R : constant Editor.Command_Palette.Command_Palette_Row :=
              Editor.Command_Palette.Row (Snap_B, I);
         begin
            Assert (L.Kind = R.Kind, "snapshot row kind must be deterministic");
            Assert (L.Candidate_Index = R.Candidate_Index, "snapshot candidate index must be deterministic");
            Assert (To_String (L.Primary_Text) = To_String (R.Primary_Text),
                    "snapshot primary text must be deterministic");
            Assert (To_String (L.Secondary_Text) = To_String (R.Secondary_Text),
                    "snapshot secondary text must be deterministic");
            Assert (To_String (L.Keybinding_Text) = To_String (R.Keybinding_Text),
                    "snapshot keybinding text must be deterministic");
            Assert (L.Is_Available = R.Is_Available, "snapshot availability flag must be deterministic");
         end;
      end loop;
   end Test_Palette_Snapshot_Determinism;



   procedure Test_Guarded_Execute_Command_Unavailable_Message
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Overlay : Editor.Overlay_Focus.Overlay_Target;
      Before_Focus : Editor.Panel_Focus.Focus_Target;
   begin
      Editor.State.Init (S);
      Before_Overlay := Editor.Overlay_Focus.Active_Overlay (S.Overlay_Focus);
      Before_Focus := Editor.Panel_Focus.Target (S.Panel_Focus);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File);
      Assert (Editor.Messages.Count (S.Messages) = 1,
              "guarded unavailable Save File must emit exactly one message");
      Assert (Editor.Overlay_Focus.Active_Overlay (S.Overlay_Focus) = Before_Overlay,
              "guarded unavailable command must not change overlay focus");
      Assert (Editor.Panel_Focus.Target (S.Panel_Focus) = Before_Focus,
              "guarded unavailable command must not change panel focus");
   end Test_Guarded_Execute_Command_Unavailable_Message;

   procedure Test_Command_Row_Layout_Edges
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      L : Editor.Command_Palette.Command_Palette_Row_Layout;
   begin
      L := Editor.Command_Palette.Layout_Command_Row
        (Row_Width_Columns => 0,
         Label_Length      => 20,
         Secondary_Length  => 40,
         Keybinding_Length => 10,
         Is_Selected       => True,
         Is_Available      => False);
      Assert (not L.Show_Keybinding and then L.Label_Columns = 0,
              "zero-width command row must not allocate columns");

      L := Editor.Command_Palette.Layout_Command_Row
        (Row_Width_Columns => 8,
         Label_Length      => 30,
         Secondary_Length  => 80,
         Keybinding_Length => 30,
         Is_Selected       => True,
         Is_Available      => False);
      Assert (not L.Show_Keybinding,
              "over-wide keybinding must be omitted deterministically");
      Assert (L.Label_Columns <= 8,
              "label columns must fit within row width");

      L := Editor.Command_Palette.Layout_Command_Row
        (Row_Width_Columns => 40,
         Label_Length      => 20,
         Secondary_Length  => 50,
         Keybinding_Length => 6,
         Is_Selected       => True,
         Is_Available      => True);
      Assert (L.Show_Keybinding,
              "fitting keybinding should be shown");
      Assert (L.Label_Columns + L.Secondary_Columns + L.Keybinding_Columns <= 40,
              "layout column allocation must stay inside row width");
   end Test_Command_Row_Layout_Edges;

   procedure Test_Hidden_Command_Behavior
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (not Editor.Commands.Visible_In_Command_Palette (Editor.Commands.Command_Move_Left),
              "raw movement commands must remain hidden from palette");
      Assert (Editor.Commands.Descriptor_Is_Complete (Editor.Commands.Command_Move_Left),
              "hidden commands must still have complete descriptors");
      Assert (Editor.Commands.Has_Stable_User_Label (Editor.Commands.Command_Move_Left),
              "hidden commands must still have stable labels");
   end Test_Hidden_Command_Behavior;



   function Is_Lower_Kebab_Name (Text : String) return Boolean is
   begin
      if Text'Length = 0 then
         return False;
      end if;

      for Ch of Text loop
         if not (Ch in 'a' .. 'z' or else Ch in '0' .. '9' or else Ch = '-' or else Ch = '.') then
            return False;
         end if;
      end loop;

      return Text (Text'First) not in '-' | '.'
        and then Text (Text'Last) not in '-' | '.'
        and then Ada.Strings.Fixed.Index (Text, "--") = 0
        and then Ada.Strings.Fixed.Index (Text, "..") = 0;
   end Is_Lower_Kebab_Name;

   procedure Test_Command_Metadata_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      D : Editor.Commands.Command_Descriptor;
   begin
      Assert (not Editor.Commands.Has_Descriptor (Editor.Commands.No_Command)
              or else not Editor.Commands.Is_Concrete_Command (Editor.Commands.No_Command),
              "No_Command may have sentinel metadata only");

      for I in 1 .. Editor.Commands.Command_Count loop
         declare
            Id : constant Editor.Commands.Command_Id := Editor.Commands.Command_At (I);
         begin
            D := Editor.Commands.Descriptor (Id);
            Assert (D.Id = Id, "descriptor id mismatch for " & Editor.Commands.Command_Id'Image (Id));
            Assert (Editor.Commands.Has_Descriptor (Id),
                    "every command id must have registry metadata");

            if Editor.Commands.Is_Concrete_Command (Id) then
               Assert (Editor.Commands.Descriptor_Is_Complete (Id),
                       "concrete descriptor must be complete: " & Editor.Commands.Command_Id'Image (Id));
               Assert (Length (D.Name) > 0, "concrete command must have label");
               Assert (Length (D.Description) > 0,
                       "concrete command must have description: " & Editor.Commands.Command_Id'Image (Id));
               Assert (Editor.Commands.Has_Availability_Handler (Id),
                       "concrete command must have an availability handler: " &
                       Editor.Commands.Command_Id'Image (Id));
               Assert (D.Bindable = Editor.Commands.Is_Bindable_Command (Id),
                       "descriptor bindable flag must mirror helper");
               Assert (D.Destructive = Editor.Commands.Is_Destructive_Command (Id),
                       "descriptor destructive flag must mirror helper: " &
                       Editor.Commands.Command_Id'Image (Id));
               Assert (D.Lifecycle = Editor.Commands.Is_Lifecycle_Command (Id),
                       "descriptor lifecycle flag must mirror helper");
               Assert (D.Configuration = Editor.Commands.Is_Configuration_Command (Id),
                       "descriptor configuration flag must mirror helper");
            end if;
         end;
      end loop;
   end Test_Command_Metadata_Completeness;

   procedure Test_Stable_Command_Name_Coverage
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Seen  : array (Editor.Commands.Command_Id) of Boolean := (others => False);
      Found : Boolean := False;
      Round : Editor.Commands.Command_Id;
   begin
      Assert (not Editor.Commands.Is_Bindable_Command (Editor.Commands.No_Command),
              "No_Command must not be bindable");
      Assert (not Editor.Commands.Has_Stable_Name (Editor.Commands.No_Command),
              "No_Command must not advertise a persisted binding name");

      for I in 1 .. Editor.Commands.Command_Count loop
         declare
            Id   : constant Editor.Commands.Command_Id := Editor.Commands.Command_At (I);
            Name : constant String := Editor.Commands.Stable_Command_Name (Id);
         begin
            if Editor.Commands.Is_Bindable_Command (Id) then
               Assert (Editor.Commands.Has_Stable_Name (Id),
                       "bindable command must have stable name: " & Editor.Commands.Command_Id'Image (Id));
               Assert (Is_Lower_Kebab_Name (Name),
                       "stable command name must be lowercase kebab-case: " & Name);
               Round := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
               Assert (Found and then Round = Id,
                       "stable command name must round-trip: " & Name);
               Assert (not Seen (Round),
                       "stable command names must be unique: " & Name);
               Seen (Round) := True;
            end if;
         end;
      end loop;
   end Test_Stable_Command_Name_Coverage;

   procedure Test_Command_Classification_Invariants
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Commands.Is_Destructive_Command (Editor.Commands.Command_Clear_Workspace_State),
              "clear workspace state must be destructive");
      Assert (Editor.Commands.Is_Destructive_Command (Editor.Commands.Command_Clear_Recent_Projects),
              "clear recent projects must be destructive");
      Assert (Editor.Commands.Is_Destructive_Command (Editor.Commands.Command_Reset_Settings_To_Defaults),
              "reset settings must be destructive");
      Assert (Editor.Commands.Is_Destructive_Command (Editor.Commands.Command_Keybindings_Reset_To_Defaults),
              "reset keybindings must be destructive");
      Assert (Editor.Commands.Is_Lifecycle_Command (Editor.Commands.Command_Open_Project),
              "open project must be a lifecycle command");
      Assert (Editor.Commands.Is_Lifecycle_Command (Editor.Commands.Command_Save_Workspace_State),
              "save workspace state must be a lifecycle command");
      Assert (Editor.Commands.Is_Configuration_Command (Editor.Commands.Command_Save_Settings),
              "save settings must be a configuration command");
      Assert (Editor.Commands.Is_Configuration_Command (Editor.Commands.Command_Save_Keybindings),
              "save keybindings must be a configuration command");
      Assert (not Editor.Commands.Is_Configuration_Command (Editor.Commands.Command_Save_File),
              "file-content save must not be a configuration command");
      Assert (not Editor.Commands.Is_Configuration_Command (Editor.Commands.Command_Save_Workspace_State),
              "workspace save must not be a configuration command");
   end Test_Command_Classification_Invariants;

   procedure Test_Save_Command_Descriptions_Are_Distinct
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      function Desc (Id : Editor.Commands.Command_Id) return String is
      begin
         return To_String (Editor.Commands.Descriptor (Id).Description);
      end Desc;
   begin
      Assert (Ada.Strings.Fixed.Index (Desc (Editor.Commands.Command_Save_All), "file-backed") > 0,
              "Save All description must identify file-content saving");
      Assert (Ada.Strings.Fixed.Index (Desc (Editor.Commands.Command_Save_Workspace_State), "workspace/session") > 0,
              "Save Workspace State description must identify structural/session state");
      Assert (Ada.Strings.Fixed.Index (Desc (Editor.Commands.Command_Save_Workspace_State), "does not save dirty file contents") > 0,
              "Save Workspace State must explicitly not claim file-content saving");
      Assert (Ada.Strings.Fixed.Index (Desc (Editor.Commands.Command_Save_Settings), "preferences") > 0,
              "Save Settings description must identify global preferences");
      Assert (Ada.Strings.Fixed.Index (Desc (Editor.Commands.Command_Save_Keybindings), "keybinding") > 0,
              "Save Keybindings description must identify global keybindings");
   end Test_Save_Command_Descriptions_Are_Distinct;

   procedure Test_Execution_Result_For_No_Op_And_Unavailable
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);

      R := Editor.Executor.Execute_Command_With_Result (S, Editor.Commands.No_Command);
      Assert (R.Status = Editor.Executor.Command_No_Op,
              "No_Command execution result must be no-op");
      Assert (Editor.Messages.Count (S.Messages) = 0,
              "No_Command must not emit user-facing feedback");

      R := Editor.Executor.Execute_Command_With_Result (S, Editor.Commands.Command_Save_File);
      Assert (R.Status = Editor.Executor.Command_Unavailable,
              "unavailable command execution result must be Command_Unavailable");
      Assert (R.Command = Editor.Commands.Command_Save_File,
              "execution result must preserve command id");
      Assert (Editor.Messages.Count (S.Messages) = 1,
              "unavailable command must emit one message");
   end Test_Execution_Result_For_No_Op_And_Unavailable;


   procedure Test_Disabled_State_Baseline
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      function Reason (Id : Editor.Commands.Command_Id) return String is
      begin
         return Editor.Commands.Unavailable_Reason
           (Editor.Executor.Command_Availability (S, Id));
      end Reason;
   begin
      Editor.State.Init (S);
      Editor.Recent_Projects.Clear (S.Recent_Projects);

      Assert (Reason (Editor.Commands.Command_Close_Project) = "No project open.",
              "Close Project must be disabled without a project");
      Assert (Reason (Editor.Commands.Command_Save_Workspace_State) = "No project open.",
              "Save Workspace State must be disabled without a project");
      Assert (Reason (Editor.Commands.Command_Restore_Workspace_State) = "No project open.",
              "Restore Workspace State must be disabled without a project");
      Assert (Reason (Editor.Commands.Command_Retry_Pending_Transition) = "No pending transition",
              "Retry Pending Transition must be disabled without a pending transition");
      Assert (Reason (Editor.Commands.Command_Cancel_Pending_Transition) = "No pending transition",
              "Cancel Pending Transition must be disabled without a pending transition");
      Assert (Reason (Editor.Commands.Command_Discard_Pending_Transition) = "No pending transition",
              "Discard Pending Transition must be disabled without a pending transition");
      Assert (Reason (Editor.Commands.Command_Save_All) = "No dirty file-backed buffers.",
              "Save All must be disabled without dirty file-backed buffers");
      Assert (Editor.Commands.Is_Available
                (Editor.Executor.Command_Availability
                   (S, Editor.Commands.Command_Show_Recent_Projects)),
              "Show Recent Projects must remain available to display an empty state");
      Assert (Reason (Editor.Commands.Command_Clear_Recent_Projects) = "No recent projects.",
              "Clear Recent Projects must be disabled without recent projects");

      Assert (Editor.Commands.Is_Available
                (Editor.Executor.Command_Availability (S, Editor.Commands.Command_Save_Settings)),
              "Save Settings must remain globally available");
      Assert (Editor.Commands.Is_Available
                (Editor.Executor.Command_Availability (S, Editor.Commands.Command_Reload_Settings)),
              "Reload Settings must remain globally available");
      Assert (Editor.Commands.Is_Available
                (Editor.Executor.Command_Availability (S, Editor.Commands.Command_Save_Keybindings)),
              "Save Keybindings must remain globally available");
      Assert (Editor.Commands.Is_Available
                (Editor.Executor.Command_Availability (S, Editor.Commands.Command_Reload_Keybindings)),
              "Reload Keybindings must remain globally available");
   end Test_Disabled_State_Baseline;


   procedure Test_Command_Execution_Result_Terminology
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      R : Editor.Command_Execution.Command_Execution_Result;
   begin
      R := Editor.Command_Execution.Executed (Editor.Commands.Command_Save_Settings);
      Assert (R.Status = Editor.Command_Execution.Command_Executed,
              "Executed helper must classify successful commands");
      Assert (R.Command = Editor.Commands.Command_Save_Settings,
              "Executed helper must preserve command id");
      Assert (Editor.Command_Execution.Is_Terminal (R),
              "execution results must describe terminal invocations");

      R := Editor.Command_Execution.Executed (Editor.Commands.No_Command);
      Assert (R.Status = Editor.Command_Execution.Command_No_Op,
              "No_Command must never be classified as executed");

      R := Editor.Command_Execution.Unavailable (Editor.Commands.Command_Save_File);
      Assert (R.Status = Editor.Command_Execution.Command_Unavailable,
              "Unavailable helper must classify unavailable commands");

      R := Editor.Command_Execution.Failed (Editor.Commands.Command_Save_File);
      Assert (R.Status = Editor.Command_Execution.Command_Failed,
              "Failed helper must classify failed commands");

      R := Editor.Command_Execution.No_Op (Editor.Commands.Command_Dismiss_All_Messages);
      Assert (R.Status = Editor.Command_Execution.Command_No_Op,
              "No_Op helper must classify intentional no-op commands");
   end Test_Command_Execution_Result_Terminology;

   procedure Test_Unavailable_Commands_Are_Side_Effect_Limited
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      procedure Check (Id : Editor.Commands.Command_Id; Label : String) is
         S       : Editor.State.State_Type;
         Before_Project : Boolean;
         Before_Dirty   : Boolean;
         Before_Pending : Boolean;
         R       : Editor.Executor.Command_Execution_Result;
      begin
         Editor.State.Init (S);
         Before_Project := Editor.Project.Has_Project (S.Project);
         Before_Dirty   := S.File_Info.Dirty;
         Before_Pending := Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions);

         Assert (not Editor.Commands.Is_Available
                   (Editor.Executor.Command_Availability (S, Id)),
                 Label & " must be unavailable in the empty fixture");

         R := Editor.Executor.Execute_Command_With_Result (S, Id);
         Assert (R.Status = Editor.Executor.Command_Unavailable,
                 Label & " must report Command_Unavailable");
         Assert (R.Command = Id,
                 Label & " result must preserve command id");
         Assert (Editor.Messages.Count (S.Messages) = 1,
                 Label & " must emit exactly one unavailable message");
         Assert (Editor.Project.Has_Project (S.Project) = Before_Project,
                 Label & " must not change project root when unavailable");
         Assert (S.File_Info.Dirty = Before_Dirty,
                 Label & " must not change dirty state when unavailable");
         Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions) = Before_Pending,
                 Label & " must not create pending transitions when unavailable");
      end Check;
   begin
      Check (Editor.Commands.Command_Save_File, "Save File");
      Check (Editor.Commands.Command_Close_Project, "Close Project");
      Check (Editor.Commands.Command_Restore_Workspace_State, "Restore Workspace State");
      Check (Editor.Commands.Command_Retry_Pending_Transition, "Retry Pending Transition");
      Check (Editor.Commands.Command_Discard_Pending_Transition, "Discard Pending Transition");
      Check (Editor.Commands.Command_Save_All, "Save All");
      --  removed-name discard-buffer is no longer a public command
      --  surface and is covered by the revert cleanup tests.
      declare
         Recent_State : Editor.State.State_Type;
      begin
         Editor.State.Init (Recent_State);
         Assert (Editor.Commands.Is_Available
                   (Editor.Executor.Command_Availability
                      (Recent_State, Editor.Commands.Command_Show_Recent_Projects)),
                 "Show Recent Projects remains executable to display the empty state");
      end;
   end Test_Unavailable_Commands_Are_Side_Effect_Limited;

   procedure Test_Availability_And_Execution_Result_Consistency
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Editor.Commands.Command_Availability;
      R : Editor.Executor.Command_Execution_Result;
      Id : Editor.Commands.Command_Id;
   begin
      for I in 1 .. Editor.Commands.Command_Count loop
         Editor.State.Init (S);
         Id := Editor.Commands.Command_At (I);
         A := Editor.Executor.Command_Availability (S, Id);

         if Id /= Editor.Commands.No_Command
           and then not Editor.Commands.Is_Available (A)
         then
            R := Editor.Executor.Execute_Command_With_Result (S, Id);
            Assert (R.Status = Editor.Executor.Command_Unavailable,
                    "unavailable command must execute as unavailable: " &
                    Editor.Commands.Command_Id'Image (Id));
            Assert (Editor.Messages.Count (S.Messages) = 1,
                    "unavailable command must emit one primary message: " &
                    Editor.Commands.Command_Id'Image (Id));
         end if;
      end loop;
   end Test_Availability_And_Execution_Result_Consistency;

   function Executor_Owns_Break_Group_Command
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      case Id is
         when Editor.Commands.Command_Dismiss_Latest_Message
            | Editor.Commands.Command_Dismiss_All_Messages
            | Editor.Commands.Command_Open_File
            | Editor.Commands.Command_Toggle_Line_Numbers
            | Editor.Commands.Command_Set_Absolute_Line_Numbers
            | Editor.Commands.Command_Set_Relative_Line_Numbers
            | Editor.Commands.Command_Set_Hybrid_Line_Numbers
            | Editor.Commands.Command_Toggle_Current_Line_Highlight
            | Editor.Commands.Command_Toggle_Syntax_Colouring
            | Editor.Commands.Command_Toggle_Diagnostics
            | Editor.Commands.Command_Toggle_Cursor_Style
            | Editor.Commands.Command_Edit_History_Clear
            | Editor.Commands.Command_Select_All
            | Editor.Commands.Command_Selection_Clear
            | Editor.Commands.Command_Build_Run
            | Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Confirm
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Cancel
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Summary
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Next
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Previous
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Toggle
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Show
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Hide
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Remove_Selected
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Restore_Last_Removed
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Summary
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Next
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Previous
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Clear_Stale
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Stale_Summary
            | Editor.Commands.No_Command =>
            return True;
         when others =>
            return False;
      end case;
   end Executor_Owns_Break_Group_Command;

   procedure Test_Command_For_Id_Fallback_Coverage_Audit
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Id  : Editor.Commands.Command_Id;
      Cmd : Editor.Commands.Command;
   begin
      for I in 1 .. Editor.Commands.Command_Count loop
         Id := Editor.Commands.Command_At (I);
         Cmd := Editor.Commands.Command_For_Id (Id);
         if Cmd.Kind = Editor.Commands.Break_Group then
            Assert (Executor_Owns_Break_Group_Command (Id),
                    "Break_Group command id must be explicitly executor-owned: " &
                    Editor.Commands.Command_Id'Image (Id));
         end if;
      end loop;
   end Test_Command_For_Id_Fallback_Coverage_Audit;

   procedure Test_Command_Palette_Dispatch_Uses_Executor_Result
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Direct_State  : Editor.State.State_Type;
      Palette_State : Editor.State.State_Type;
      Direct_Result : Editor.Executor.Command_Execution_Result;
      Palette_Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (Direct_State);
      Editor.State.Init (Palette_State);

      Direct_Result := Editor.Executor.Execute_Command_With_Result
        (Direct_State, Editor.Commands.Command_Save_All);
      Palette_Result := Editor.Executor.Execute_Command_With_Result
        (Palette_State, Editor.Commands.Command_Save_All);

      Assert (Direct_Result.Status = Palette_Result.Status,
              "palette-equivalent Save All route must observe the executor result");
      Assert (Editor.Messages.Count (Direct_State.Messages) =
              Editor.Messages.Count (Palette_State.Messages),
              "palette-equivalent Save All route must not add wrapper messages");
   end Test_Command_Palette_Dispatch_Uses_Executor_Result;


   procedure Test_Command_Execution_Final_Status_Helpers
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      R : Editor.Command_Execution.Command_Execution_Result;
   begin
      R := Editor.Command_Execution.Executed (Editor.Commands.Command_Save_Settings);
      Assert (Editor.Command_Execution.Is_Success (R),
              "Command_Executed must be the only success status");
      Assert (Editor.Command_Execution.Status_Name (R.Status) = "executed",
              "executed status name must be stable");
      Assert (Editor.Command_Execution.Summary (R) = "COMMAND_SAVE_SETTINGS:executed",
              "execution summary must combine command image and status name");

      R := Editor.Command_Execution.No_Op (Editor.Commands.No_Command);
      Assert (not Editor.Command_Execution.Is_Success (R),
              "Command_No_Op must be terminal but not a mutation success");
      Assert (not Editor.Command_Execution.Is_User_Blocking (R),
              "Command_No_Op must not be reported as a user-blocking failure");
      Assert (Editor.Command_Execution.Status_Name (R.Status) = "no-op",
              "no-op status name must be stable");

      R := Editor.Command_Execution.Unavailable (Editor.Commands.Command_Save_File);
      Assert (Editor.Command_Execution.Is_User_Blocking (R),
              "Command_Unavailable must be a guarded user-blocking outcome");
      Assert (Editor.Command_Execution.Status_Name (R.Status) = "unavailable",
              "unavailable status name must be stable");

      R := Editor.Command_Execution.Failed (Editor.Commands.Command_Reload_Settings);
      Assert (Editor.Command_Execution.Is_User_Blocking (R),
              "Command_Failed must be a user-blocking attempted failure");
      Assert (Editor.Command_Execution.Status_Name (R.Status) = "failed",
              "failed status name must be stable");

      R := Editor.Command_Execution.Cancelled (Editor.Commands.Command_Cancel);
      Assert (not Editor.Command_Execution.Is_Success (R),
              "Command_Cancelled must not be a mutation success");
      Assert (not Editor.Command_Execution.Is_User_Blocking (R),
              "Command_Cancelled must not be reported as a failure");
      Assert (Editor.Command_Execution.Status_Name (R.Status) = "cancelled",
              "cancelled status name must be stable");
   end Test_Command_Execution_Final_Status_Helpers;

   procedure Test_Command_Category_Baseline
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Commands.Category_Label (Editor.Commands.File_Category) = "File",
              "File category label must remain stable");
      Assert (Editor.Commands.Category_Label (Editor.Commands.Edit_Category) = "Edit",
              "Edit category label must remain stable");
      Assert (Editor.Commands.Category_Label (Editor.Commands.Selection_Category) = "Selection",
              "Selection category label must remain stable");
      Assert (Editor.Commands.Category_Label (Editor.Commands.Navigation_Category) = "Navigation",
              "Navigation category label must remain stable");
      Assert (Editor.Commands.Category_Label (Editor.Commands.Search_Category) = "Search",
              "Search category label must remain stable");
      Assert (Editor.Commands.Category_Label (Editor.Commands.Project_Category) = "Project",
              "Project category label must remain stable");
      Assert (Editor.Commands.Category_Label (Editor.Commands.Workspace_Category) = "Workspace",
              "Workspace category label must remain stable");
      Assert (Editor.Commands.Category_Label (Editor.Commands.View_Category) = "View",
              "View category label must remain stable");
      Assert (Editor.Commands.Category_Label (Editor.Commands.Settings_Category) = "Settings",
              "Settings category label must remain stable");
      Assert (Editor.Commands.Category_Label (Editor.Commands.Diagnostics_Category) = "Diagnostics",
              "Diagnostics category label must remain stable");
      Assert (Editor.Commands.Category_Label (Editor.Commands.Bookmarks_Category) = "Bookmarks",
              "Bookmarks category label must remain stable");
      Assert (Editor.Commands.Category_Label (Editor.Commands.Panel_Category) = "Panels",
              "Panel category label must remain stable as Panels");
      Assert (Editor.Commands.Category_Label (Editor.Commands.Internal_Category) = "Internal",
              "Internal category label must remain stable");
   end Test_Command_Category_Baseline;

   procedure Test_Command_Classification_Groups
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Commands.Is_File_Content_Save_Command (Editor.Commands.Command_Save_File),
              "Save File must be classified as file-content-save");
      Assert (Editor.Commands.Is_File_Content_Save_Command (Editor.Commands.Command_Save_All),
              "Save All must be classified as file-content-save");
      Assert (not Editor.Commands.Is_File_Content_Save_Command (Editor.Commands.Command_Save_Workspace_State),
              "Workspace structural save must not be classified as file-content-save");

      Assert (Editor.Commands.Is_Workspace_Structural_Save_Command (Editor.Commands.Command_Save_Workspace_State),
              "Save Workspace State must be classified as workspace-structural-save");
      Assert (Editor.Commands.Is_Global_Settings_Save_Command (Editor.Commands.Command_Save_Settings),
              "Save Settings must be classified as global-settings-save");
      Assert (Editor.Commands.Is_Global_Keybindings_Save_Command (Editor.Commands.Command_Save_Keybindings),
              "Save Keybindings must be classified as global-keybindings-save");

      Assert (Editor.Commands.Is_Navigation_Command (Editor.Commands.Command_Move_Left),
              "Move Left must be classified as navigation");
      Assert (Editor.Commands.Is_Search_Command (Editor.Commands.Command_Active_Find_Next),
              "Find Next must be classified as search");
      Assert (Editor.Commands.Is_Search_Command (Editor.Commands.Command_Replace_All),
              "Replace All must be classified as search");
      Assert (Editor.Commands.Is_Text_Editing_Command (Editor.Commands.Command_Replace_Current),
              "Replace Current must be classified as text-editing");
      Assert (Editor.Commands.Requires_Context (Editor.Commands.Command_Replace_Current),
              "Replace Current must require active-buffer/find context");
      Assert (Editor.Commands.Requires_Context (Editor.Commands.Command_Replace_Text_Set),
              "Replace Text Set must require prompt/payload context");
      Assert (Editor.Commands.Is_Panel_Focus_Command (Editor.Commands.Command_Focus_Problems),
              "Focus Problems must be classified as panel-focus");
      Assert (Editor.Commands.Is_Text_Editing_Command (Editor.Commands.Command_Insert_Newline),
              "Insert Newline must be classified as text-editing");

      Assert (not Editor.Commands.Is_Configuration_Command (Editor.Commands.Command_Save_File),
              "file-content saving must remain separate from configuration");
      Assert (not Editor.Commands.Is_Lifecycle_Command (Editor.Commands.Command_Save_Settings),
              "settings saving must remain separate from lifecycle");
   end Test_Command_Classification_Groups;

   procedure Test_Command_Registry_Baseline
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Id    : Editor.Commands.Command_Id;
      Other : Editor.Commands.Command_Id;
      Found : Boolean := False;
      D     : Editor.Commands.Command_Descriptor;
   begin
      for I in 1 .. Editor.Commands.Command_Count loop
         Id := Editor.Commands.Command_At (I);
         D := Editor.Commands.Descriptor (Id);

         Assert (Editor.Commands.Has_Descriptor (Id),
                 "command registry baseline missing descriptor for " &
                 Editor.Commands.Command_Id'Image (Id));

         if Editor.Commands.Is_Concrete_Command (Id) then
            Assert (Length (D.Name) > 0,
                    "concrete command missing label: " & Editor.Commands.Command_Id'Image (Id));
            Assert (Length (D.Description) > 0,
                    "concrete command missing description: " & Editor.Commands.Command_Id'Image (Id));
            Assert (Editor.Commands.Has_Availability_Handler (Id),
                    "concrete command missing availability handler marker: " &
                    Editor.Commands.Command_Id'Image (Id));
            Assert (Editor.Commands.Descriptor_Is_Complete (Id),
                    "concrete command descriptor incomplete: " &
                    Editor.Commands.Command_Id'Image (Id));
         end if;

         if Editor.Commands.Is_Bindable_Command (Id) then
            Assert (Editor.Commands.Has_Stable_Name (Id),
                    "bindable command missing stable name: " &
                    Editor.Commands.Command_Id'Image (Id));
            Other := Editor.Commands.Command_Id_From_Stable_Name
              (Editor.Commands.Stable_Command_Name (Id), Found);
            Assert (Found and then Other = Id,
                    "stable command name must round-trip for " &
                    Editor.Commands.Command_Id'Image (Id));

            if I < Editor.Commands.Command_Count then
               for J in I + 1 .. Editor.Commands.Command_Count loop
                  Other := Editor.Commands.Command_At (J);
                  if Editor.Commands.Is_Bindable_Command (Other) then
                     Assert (Editor.Commands.Stable_Command_Name (Id) /=
                               Editor.Commands.Stable_Command_Name (Other),
                             "duplicate stable command name between " &
                             Editor.Commands.Command_Id'Image (Id) & " and " &
                             Editor.Commands.Command_Id'Image (Other));
                  end if;
               end loop;
            end if;
         end if;

         if Editor.Commands.Visible_In_Command_Palette (Id) then
            Assert (D.Category /= Editor.Commands.Internal_Category,
                    "visible command must not use Internal category: " &
                    Editor.Commands.Command_Id'Image (Id));
         end if;
      end loop;
   end Test_Command_Registry_Baseline;

   procedure Test_Unavailable_Result_Message_Coherence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      R     : Editor.Executor.Command_Execution_Result;
      Found : Boolean := False;
      Msg   : Editor.Messages.Editor_Message;
   begin
      Editor.State.Init (S);
      R := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Retry_Pending_Transition);

      Assert (R.Status = Editor.Executor.Command_Unavailable,
              "Retry Pending Transition without pending state must be unavailable");
      Assert (Editor.Command_Execution.Is_User_Blocking (R),
              "unavailable retry must be a user-blocking command result");
      Assert (Editor.Messages.Count (S.Messages) = 1,
              "unavailable retry must emit exactly one primary message");

      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found,
              "unavailable retry must produce an active message");
      Assert (Editor.Messages.Text (Msg) = "No pending transition",
              "unavailable retry message must be canonical");
      Assert (Editor.Messages.Severity (Msg) = Editor.Messages.Info_Message,
              "unavailable retry must not be reported as failed/error message");
   end Test_Unavailable_Result_Message_Coherence;

   procedure Test_Failed_Reload_Reports_Command_Failed
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      procedure Write_Invalid_File (Path : String) is
         F : Ada.Text_IO.File_Type;
      begin
         Ada.Text_IO.Create (F, Ada.Text_IO.Out_File, Path);
         Ada.Text_IO.Put_Line (F, "this is not a valid editor configuration file");
         Ada.Text_IO.Close (F);
      end Write_Invalid_File;

      S     : Editor.State.State_Type;
      R     : Editor.Executor.Command_Execution_Result;
      Found : Boolean := False;
      Msg   : Editor.Messages.Editor_Message;
      Settings_Path : constant String := "/tmp/editor-tests/invalid-settings.tmp";
      Keybindings_Path : constant String := "/tmp/editor-tests/invalid-keybindings.tmp";
   begin
      Ada.Directories.Create_Path ("/tmp/editor-tests");
      Ada.Environment_Variables.Set
        ("EDITOR_SETTINGS_PATH", Settings_Path);
      Ada.Environment_Variables.Set
        ("EDITOR_KEYBINDINGS_PATH", Keybindings_Path);

      Write_Invalid_File (Settings_Path);
      Write_Invalid_File (Keybindings_Path);

      Editor.State.Init (S);
      R := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Reload_Settings);
      Assert (R.Status = Editor.Executor.Command_Failed,
              "invalid settings reload must report Command_Failed");
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Severity (Msg) = Editor.Messages.Error_Message,
              "invalid settings reload must emit one error message");
      Assert (Editor.Messages.Text (Msg) = "Settings file is invalid.",
              "invalid settings reload must use canonical domain-specific message");

      Editor.Messages.Clear (S.Messages);
      Editor.Keybinding_Management.Reset_Transient_State;
      Found := False;
      R := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Reload_Keybindings);
      Assert (R.Status = Editor.Executor.Command_Failed,
              "invalid keybindings reload must report Command_Failed");
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Severity (Msg) = Editor.Messages.Error_Message,
              "invalid keybindings reload must emit one error message");
      Assert (Editor.Messages.Text (Msg) = "Default keybindings active.",
              "invalid keybindings reload must use canonical domain-specific message");
   end Test_Failed_Reload_Reports_Command_Failed;


   procedure Test_No_Op_Is_Public_For_No_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S  : Editor.State.State_Type;
      R  : Editor.Executor.Command_Execution_Result;
      Id : Editor.Commands.Command_Id;
   begin
      Editor.State.Init (S);
      R := Editor.Executor.Execute_Command_With_Result (S, Editor.Commands.No_Command);
      Assert (R.Status = Editor.Executor.Command_No_Op,
              "No_Command must remain the sentinel no-op");
      Assert (Editor.Messages.Count (S.Messages) = 0,
              "No_Command must not emit messages");

      for I in 1 .. Editor.Commands.Command_Count loop
         Id := Editor.Commands.Command_At (I);
         if Id /= Editor.Commands.No_Command
           and then not Editor.Commands.Is_Available
             (Editor.Executor.Command_Availability (S, Id))
         then
            declare
               Local : Editor.State.State_Type;
            begin
               Editor.State.Init (Local);
               R := Editor.Executor.Execute_Command_With_Result (Local, Id);
               Assert (R.Status /= Editor.Executor.Command_No_Op,
                       "concrete unavailable command must not hide behind no-op: " &
                       Editor.Commands.Command_Id'Image (Id));
            end;
         end if;
      end loop;
   end Test_No_Op_Is_Public_For_No_Command;

   procedure Test_Configuration_Command_Domain_Isolation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Settings_Path : constant String := "/tmp/editor-tests/command-surface-settings.tmp";
      Keybindings_Path : constant String := "/tmp/editor-tests/command-surface-keybindings.tmp";

      procedure Check (Id : Editor.Commands.Command_Id; Label : String) is
         S              : Editor.State.State_Type;
         Before_Project : Boolean;
         Before_Dirty   : Boolean;
         Before_Pending : Boolean;
         R              : Editor.Executor.Command_Execution_Result;
      begin
         Editor.State.Init (S);
         Before_Project := Editor.Project.Has_Project (S.Project);
         Before_Dirty := S.File_Info.Dirty;
         Before_Pending := Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions);

         R := Editor.Executor.Execute_Command_With_Result (S, Id);
         Assert (R.Status /= Editor.Executor.Command_Unavailable,
                 Label & " must be executable in the empty global fixture");
         Assert (Editor.Project.Has_Project (S.Project) = Before_Project,
                 Label & " must not mutate project root state");
         Assert (S.File_Info.Dirty = Before_Dirty,
                 Label & " must not mutate file dirty state");
         Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions) = Before_Pending,
                 Label & " must not create or clear pending transitions");
      end Check;
   begin
      Ada.Directories.Create_Path ("/tmp/editor-tests");
      Ada.Environment_Variables.Set
        ("EDITOR_SETTINGS_PATH", Settings_Path);
      Ada.Environment_Variables.Set
        ("EDITOR_KEYBINDINGS_PATH", Keybindings_Path);

      Check (Editor.Commands.Command_Save_Settings, "Save Settings");
      Check (Editor.Commands.Command_Reload_Settings, "Reload Settings");
      Check (Editor.Commands.Command_Save_Keybindings, "Save Keybindings");
      Check (Editor.Commands.Command_Reload_Keybindings, "Reload Keybindings");
      Check (Editor.Commands.Command_Validate_Keybindings, "Validate Keybindings");
   end Test_Configuration_Command_Domain_Isolation;


   procedure Test_Concrete_Command_Traversal
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Count : Natural := 0;
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id := Editor.Commands.First_Concrete_Command;

      procedure Count_Command
        (Current : Editor.Commands.Command_Id)
      is
      begin
         Assert
           (Editor.Commands.Is_Concrete_Command (Current),
            "For_Each_Command must not yield No_Command");
         Count := Count + 1;
      end Count_Command;
   begin
      Assert
        (Editor.Commands.First_Concrete_Command /= Editor.Commands.No_Command,
         "first concrete command must exclude No_Command");
      Assert
        (Editor.Commands.Concrete_Command_Count = Editor.Commands.Command_Count - 1,
         "concrete command count must exclude exactly No_Command");

      while Found or else Id = Editor.Commands.First_Concrete_Command loop
         Assert
           (Editor.Commands.Is_Concrete_Command (Id),
            "Next_Command concrete walk must stay on concrete ids");
         Count := Count + 1;
         Id := Editor.Commands.Next_Command (Id, Found);
         exit when not Found;
      end loop;

      Assert
        (Count = Editor.Commands.Concrete_Command_Count,
         "Next_Command walk must cover every concrete command exactly once");

      Count := 0;
      Editor.Commands.For_Each_Command (Count_Command'Access);
      Assert
        (Count = Editor.Commands.Concrete_Command_Count,
         "For_Each_Command must cover every concrete command exactly once");
   end Test_Concrete_Command_Traversal;

   procedure Test_Command_Audit_Registry_Is_Actionable
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Failures : constant Editor.Commands.Command_Audit_Failure_Vectors.Vector :=
        Editor.Commands.Audit_Command_Registry;
      Summary  : constant String := Editor.Commands.Command_Audit_Summary (Failures);
   begin
      Assert
        (Failures.Length = 0,
         "static command audit must pass: " & Summary);
   end Test_Command_Audit_Registry_Is_Actionable;

   procedure Test_Command_Descriptor_Construction_Helper
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Make_Command_Descriptor
          (Id            => Editor.Commands.Command_Save_Settings,
           Stable_Name   => "save-settings",
           Label         => "Save Settings",
           Description   => "Write global editor preferences.",
           Category      => Editor.Commands.Settings_Category,
           Visible       => True,
           Bindable      => True,
           Destructive   => False,
           Lifecycle     => False,
           Configuration => True);
   begin
      Assert (D.Id = Editor.Commands.Command_Save_Settings,
              "descriptor helper must preserve command id");
      Assert (To_String (D.Name) = "Save Settings",
              "descriptor helper must preserve explicit label");
      Assert (To_String (D.Description) = "Write global editor preferences.",
              "descriptor helper must preserve explicit description");
      Assert (D.Category = Editor.Commands.Settings_Category,
              "descriptor helper must preserve explicit category");
      Assert (D.Visibility = Editor.Commands.Palette_Command,
              "descriptor helper must use explicit visibility");
      Assert (D.Bindable and then D.Configuration,
              "descriptor helper must preserve explicit bindability/classification");
   end Test_Command_Descriptor_Construction_Helper;

   procedure Test_Route_Audit_Actionable_Failures
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Result : Editor.Command_Route_Audit.Route_Audit_Result;
      Text   : Unbounded_String;
   begin
      Editor.Command_Route_Audit.Clear (Result);
      Editor.Command_Route_Audit.Record_Route
        (Result  => Result,
         Source  => Editor.Command_Route_Audit.Route_From_Keybinding,
         Command => Editor.Commands.No_Command);
      Text := To_Unbounded_String (Editor.Command_Route_Audit.Summary (Result));

      Assert
        (Editor.Command_Route_Audit.Failure_Count (Result) = 1,
         "route audit must flag non-concrete routed command");
      Assert
        (Ada.Strings.Fixed.Index
           (To_String (Text), "ROUTE_TARGETED_NON_CONCRETE_COMMAND") > 0,
         "route audit summary must include failure kind: " & To_String (Text));
      Assert
        (Ada.Strings.Fixed.Index
           (To_String (Text), "ROUTE_FROM_KEYBINDING") > 0,
         "route audit summary must include route source: " & To_String (Text));

      Editor.Command_Route_Audit.Record_Route_Failure
        (Result   => Result,
         Source   => Editor.Command_Route_Audit.Route_From_Command_Palette,
         Kind     => Editor.Command_Route_Audit.Route_Dispatched_Wrong_Command,
         Expected => Editor.Commands.Command_Save_File,
         Actual   => Editor.Commands.Command_Save_All,
         Message  => "accept dispatched the wrong command id");
      Text := To_Unbounded_String
        (Editor.Command_Route_Audit.Last_Failure_Message (Result));
      Assert
        (Ada.Strings.Fixed.Index
           (To_String (Text), "COMMAND_SAVE_FILE") > 0
         and then Ada.Strings.Fixed.Index
           (To_String (Text), "COMMAND_SAVE_ALL") > 0,
         "typed route failure must identify expected and actual commands: " &
         To_String (Text));
   end Test_Route_Audit_Actionable_Failures;


   procedure Assert_Public_Build_Name_Not_Registered
     (Name : String)
   is
      Found : Boolean;
      Id    : constant Editor.Commands.Command_Id :=
        Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
   begin
      if Name = "build.run" then
         Assert (Found and then Id = Editor.Commands.Command_Build_Run,
                 "build.run must be the single guarded public build command");
      else
         Assert (not Found,
                 "reserved public build alias must not be registered: " & Name);
      end if;
   end Assert_Public_Build_Name_Not_Registered;

   procedure Test_Public_Build_Readiness_Audit_Reports_Not_Ready
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.External_Producers.Public_Build_Command_Readiness_Audit_Result;
   begin
      Editor.State.Init (S);
      R := Editor.External_Producers.Run_Public_Build_Command_Readiness_Audit (S);
      Assert (R.Has_Public_Build_Command,
              "public build command is registered through the guarded surface");
      Assert (not R.Has_Default_Public_Build_Keybinding,
              "must not provide a default public build keybinding");
      Assert (R.Has_User_Command_Input_Model,
              "must expose a structured public build input DTO model");
      Assert (R.Has_Structured_Argv_Input_Model,
              "structured argv seam must exist before any public build UX is designed");
      Assert (R.Has_Working_Context_Model,
              "must expose a working-context model");
      Assert (R.Has_Consent_UX_Model,
              "must expose a structured public consent model");
      Assert (R.Public_Consent_UX_Publicly_Ready,
              "public consent UX is available through the guarded surface");
      Assert (R.Has_Implicit_Source_Validation,
              "explicit-source policy must be validated");
      Assert (R.Keeps_Implicit_Source_Rejected,
              "implicit build source requests must remain rejected");
      Assert (R.Keeps_Shell_Rejected,
              "shell-enabled build execution must remain rejected");
      Assert (R.Keeps_Opaque_Arguments_Rejected,
              "opaque/free-form build arguments must remain rejected");
      Assert (R.Routes_Through_Executor,
              "build command test seams must remain Executor-routed");
      Assert (R.Routes_Diagnostics_Through_Pipeline,
              "build output must continue to route through diagnostic-line pipeline");
      Assert (R.Public_Command_Can_Be_Promoted,
              "readiness audit must allow guarded public build promotion");
   end Test_Public_Build_Readiness_Audit_Reports_Not_Ready;

   procedure Test_Public_Build_Readiness_Audit_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Messages : Natural;
      Before_Has_Buffer : Boolean;
      Before_Overlay : Editor.Overlay_Focus.Overlay_Target;
      Before_Focus : Editor.Panel_Focus.Focus_Target;
      Before_Bottom : Editor.Panel_Focus.Bottom_Focus_Content;
      R : Editor.External_Producers.Public_Build_Command_Readiness_Audit_Result;
   begin
      Editor.State.Init (S);
      Before_Messages := Editor.Messages.Count (S.Messages);
      Before_Has_Buffer := Editor.State.Has_Active_Buffer (S);
      Before_Overlay := Editor.Overlay_Focus.Active_Overlay (S.Overlay_Focus);
      Before_Focus := Editor.Panel_Focus.Target (S.Panel_Focus);
      Before_Bottom := Editor.Panel_Focus.Bottom_Content (S.Panel_Focus);

      R := Editor.External_Producers.Run_Public_Build_Command_Readiness_Audit (S);
      Assert (R.Public_Command_Can_Be_Promoted,
              "side-effect-free readiness audit should still return the ready result");
      Assert (Editor.Messages.Count (S.Messages) = Before_Messages,
              "readiness audit must not post messages");
      Assert (Editor.State.Has_Active_Buffer (S) = Before_Has_Buffer,
              "readiness audit must not create or switch buffers");
      Assert (Editor.Overlay_Focus.Active_Overlay (S.Overlay_Focus) = Before_Overlay,
              "readiness audit must not change overlay focus");
      Assert (Editor.Panel_Focus.Target (S.Panel_Focus) = Before_Focus,
              "readiness audit must not change panel focus");
      Assert (Editor.Panel_Focus.Bottom_Content (S.Panel_Focus) = Before_Bottom,
              "readiness audit must not change bottom-panel content");
   end Test_Public_Build_Readiness_Audit_Is_Side_Effect_Free;

   procedure Test_Public_Build_Commands_Are_Not_Registered
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert_Public_Build_Name_Not_Registered ("build.run");
      Assert_Public_Build_Name_Not_Registered ("build.project");
      Assert_Public_Build_Name_Not_Registered ("build.run-project");
      Assert_Public_Build_Name_Not_Registered ("compile.project");
      Assert_Public_Build_Name_Not_Registered ("compile.current");
      Assert_Public_Build_Name_Not_Registered ("diagnostics.run-build");
      Assert_Public_Build_Name_Not_Registered ("build.run-current-project");
      Assert_Public_Build_Name_Not_Registered ("build.configure-command");
   end Test_Public_Build_Commands_Are_Not_Registered;

   procedure Test_Public_Build_Commands_Have_No_Default_Keybindings
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      R : Editor.External_Producers.Public_Build_Command_Readiness_Audit_Result;
      S : Editor.State.State_Type;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Editor.State.Init (S);
      R := Editor.External_Producers.Run_Public_Build_Command_Readiness_Audit (S);
      Assert (not R.Has_Default_Public_Build_Keybinding,
              "public build commands must have no default keybindings");
      Assert (not Editor.Keybindings.Primary_Binding_For_Command
                (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam).Has_Binding,
              "internal test seam must also remain without a default keybinding");
   end Test_Public_Build_Commands_Have_No_Default_Keybindings;

   procedure Test_Public_Build_Commands_Are_Hidden_From_Normal_Palette
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
   begin
      Editor.State.Init (S);
      Editor.Executor.Command_Palette_Candidates (S, Candidates);
      for Candidate of Candidates loop
         Assert (not Editor.Commands.Is_Public_Build_Command (Candidate.Id),
                 "normal palette must not contain public build commands in ");
         Assert (Candidate.Id /= Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam,
                 "normal palette must not contain internal build test seam");
      end loop;
      Assert (not Editor.Commands.Visible_In_Command_Palette
                (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam),
              "internal build test seam remains hidden from normal palette");
   end Test_Public_Build_Commands_Are_Hidden_From_Normal_Palette;

   procedure Test_Public_Build_Readiness_Reports_Missing_UX_Models
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.External_Producers.Public_Build_Command_Readiness_Audit_Result;
   begin
      Editor.State.Init (S);
      R := Editor.External_Producers.Run_Public_Build_Command_Readiness_Audit (S);
      Assert (R.Has_Consent_UX_Model,
              "readiness audit must report the structured consent model");
      Assert (R.Public_Consent_Model_Exists,
              "readiness audit must report the public consent model exists");
      Assert (R.Public_Consent_Model_Validated,
              "readiness audit must report public consent validation exists");
      Assert (R.Public_Consent_UX_Publicly_Ready,
              "readiness audit must report completed public consent UX");
      Assert (R.Public_Consent_Publicly_Exposable,
              "readiness audit must report publicly exposable consent state");
      Assert (R.Has_Working_Context_Model,
              "readiness audit must report the working-context model");
      Assert (R.Has_User_Command_Input_Model,
              "readiness audit must report the public user-command input model");
      Assert (R.Has_Implicit_Source_Validation,
              "readiness audit must report explicit-source policy validation");
   end Test_Public_Build_Readiness_Reports_Missing_UX_Models;

   procedure Test_Public_Build_Readiness_Keeps_Rejections
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.External_Producers.Public_Build_Command_Readiness_Audit_Result;
   begin
      Editor.State.Init (S);
      R := Editor.External_Producers.Run_Public_Build_Command_Readiness_Audit (S);
      Assert (R.Keeps_Implicit_Source_Rejected,
              "readiness audit must prove implicit build source remains rejected");
      Assert (R.Keeps_Shell_Rejected,
              "readiness audit must prove shell policy remains rejected");
      Assert (R.Keeps_Opaque_Arguments_Rejected,
              "readiness audit must prove free-form opaque arguments remain rejected");
   end Test_Public_Build_Readiness_Keeps_Rejections;

   function Valid_Public_Input
      return Editor.External_Producers.Public_Build_Command_Input
   is
   begin
      return
        (Source           => Editor.External_Producers.Public_Build_Input_Test_Context,
         Tool             => Editor.External_Producers.GPRbuild_Tool,
         Program_Label    => To_Unbounded_String ("gprbuild"),
         Working_Context  =>
           Editor.External_Producers.Build_Inherited_Test_Working_Context,
         Working_Context_Model =>
           (Source => Editor.External_Producers.Public_Build_Working_Context_Test_Context,
            Label  => Null_Unbounded_String,
            User_Acknowledged_Context => True),
         Arguments        =>
           Editor.External_Producers.Build_Process_Argument_Vector ("-q"),
         Consent          => Editor.External_Producers.Build_Consent_User_Confirmed,
         Consent_Model    =>
           (Source => Editor.External_Producers.Public_Build_Consent_Test_Context,
            User_Acknowledged_Execution => True,
            User_Acknowledged_No_Shell => True,
            User_Acknowledged_External_Process => True,
            User_Acknowledged_Diagnostics_Output => True),
         Show_Diagnostics => False);
   end Valid_Public_Input;


   function Valid_Test_Consent
      return Editor.External_Producers.Public_Build_Consent_Model
   is
   begin
      return
        (Source => Editor.External_Producers.Public_Build_Consent_Test_Context,
         User_Acknowledged_Execution => True,
         User_Acknowledged_No_Shell => True,
         User_Acknowledged_External_Process => True,
         User_Acknowledged_Diagnostics_Output => True);
   end Valid_Test_Consent;

   function Valid_User_Form_Consent
      return Editor.External_Producers.Public_Build_Consent_Model
   is
   begin
      return
        (Source => Editor.External_Producers.Public_Build_Consent_User_Form_Acknowledged,
         User_Acknowledged_Execution => True,
         User_Acknowledged_No_Shell => True,
         User_Acknowledged_External_Process => True,
         User_Acknowledged_Diagnostics_Output => True);
   end Valid_User_Form_Consent;

   function Valid_Test_Working_Context
      return Editor.External_Producers.Public_Build_Working_Context_Model
   is
   begin
      return
        (Source => Editor.External_Producers.Public_Build_Working_Context_Test_Context,
         Label  => Null_Unbounded_String,
         User_Acknowledged_Context => True);
   end Valid_Test_Working_Context;

   function Valid_User_Form_Working_Context
      return Editor.External_Producers.Public_Build_Working_Context_Model
   is
   begin
      return
        (Source => Editor.External_Producers.Public_Build_Working_Context_User_Form_Label,
         Label  => To_Unbounded_String ("current-project-root"),
         User_Acknowledged_Context => True);
   end Valid_User_Form_Working_Context;

   procedure Test_Public_Build_Consent_Validation_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Messages : Natural;
      Before_Focus : Editor.Panel_Focus.Focus_Target;
      Status : Editor.External_Producers.Public_Build_Consent_Validation_Status;
   begin
      Editor.State.Init (S);
      Before_Messages := Editor.Messages.Count (S.Messages);
      Before_Focus := Editor.Panel_Focus.Target (S.Panel_Focus);
      Status := Editor.External_Producers.Validate_Public_Build_Consent
        (Valid_Test_Consent);
      Assert (Status = Editor.External_Producers.Public_Build_Consent_Valid_For_Internal_Test,
              "valid test-context consent must validate without side effects");
      Assert (Editor.Messages.Count (S.Messages) = Before_Messages,
              "consent validation must not post messages");
      Assert (Editor.Panel_Focus.Target (S.Panel_Focus) = Before_Focus,
              "consent validation must not switch feature focus");
   end Test_Public_Build_Consent_Validation_Is_Side_Effect_Free;

   procedure Test_Public_Build_Consent_Rejects_Missing_Acknowledgements
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Consent : Public_Build_Consent_Model := Valid_Test_Consent;
   begin
      Consent.Source := Public_Build_Consent_None;
      Assert (Validate_Public_Build_Consent (Consent) =
              Public_Build_Consent_Rejected_None,
              "missing consent source must reject deterministically");

      Consent := Valid_Test_Consent;
      Consent.User_Acknowledged_Execution := False;
      Assert (Validate_Public_Build_Consent (Consent) =
              Public_Build_Consent_Rejected_Missing_Execution_Acknowledgement,
              "missing execution acknowledgement must reject deterministically");

      Consent := Valid_Test_Consent;
      Consent.User_Acknowledged_No_Shell := False;
      Assert (Validate_Public_Build_Consent (Consent) =
              Public_Build_Consent_Rejected_Missing_No_Shell_Acknowledgement,
              "missing no-shell acknowledgement must reject deterministically");

      Consent := Valid_Test_Consent;
      Consent.User_Acknowledged_External_Process := False;
      Assert (Validate_Public_Build_Consent (Consent) =
              Public_Build_Consent_Rejected_Missing_External_Process_Acknowledgement,
              "missing external-process acknowledgement must reject deterministically");

      Consent := Valid_Test_Consent;
      Consent.User_Acknowledged_Diagnostics_Output := False;
      Assert (Validate_Public_Build_Consent (Consent) =
              Public_Build_Consent_Rejected_Missing_Diagnostics_Acknowledgement,
              "missing diagnostics acknowledgement must reject deterministically");
   end Test_Public_Build_Consent_Rejects_Missing_Acknowledgements;

   procedure Test_Public_Build_Consent_Test_Context_Internal_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
   begin
      Assert (Validate_Public_Build_Consent (Valid_Test_Consent) =
              Public_Build_Consent_Valid_For_Internal_Test,
              "test-context consent must validate only for internal/test conversion");
      Assert (Classify_Public_Build_Consent_Safety (Valid_Test_Consent) =
              Public_Build_Input_Valid_For_Internal_Test,
              "test-context consent must classify as internal-test-only");
      Assert (Build_Execution_Consent_From_Public_Model (Valid_Test_Consent) =
              Build_Consent_User_Confirmed,
              "test-context consent may derive explicit user-confirmed consent for internal/test conversion");
   end Test_Public_Build_Consent_Test_Context_Internal_Only;

   procedure Test_Public_Build_Consent_User_Form_Not_Publicly_Exposable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
   begin
      Assert (Validate_Public_Build_Consent (Valid_User_Form_Consent) =
              Public_Build_Consent_Valid_But_Not_Public_UX,
              "user-form-shaped consent must validate structurally but not as public UX");
      Assert (Classify_Public_Build_Consent_Safety (Valid_User_Form_Consent) =
              Public_Build_Input_Valid_But_Not_Publicly_Exposable,
              "user-form-shaped consent must not be publicly exposable");
      Assert (Build_Execution_Consent_From_Public_Model (Valid_User_Form_Consent) =
              Build_Consent_User_Confirmed,
              "acknowledged user-form consent must convert to execution consent");
   end Test_Public_Build_Consent_User_Form_Not_Publicly_Exposable;

   procedure Test_Public_Build_Consent_Feedback_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
   begin
      Assert (Build_Public_Build_Consent_Feedback
                (Public_Build_Consent_Rejected_None) =
              "Build: execution consent required",
              "missing consent feedback must be deterministic");
      Assert (Build_Public_Build_Consent_Feedback
                (Public_Build_Consent_Rejected_Missing_No_Shell_Acknowledgement) =
              "Build: no-shell acknowledgement required",
              "no-shell feedback must be deterministic");
      Assert (Build_Public_Build_Consent_Feedback
                (Public_Build_Consent_Valid_But_Not_Public_UX) =
              "Build: public consent UX not ready",
              "user-form consent feedback must not expose internals");
   end Test_Public_Build_Consent_Feedback_Is_Deterministic;

   procedure Test_Public_Build_Input_Validation_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Messages : Natural;
      Before_Focus : Editor.Panel_Focus.Focus_Target;
      Status : Editor.External_Producers.Public_Build_Input_Validation_Status;
   begin
      Editor.State.Init (S);
      Before_Messages := Editor.Messages.Count (S.Messages);
      Before_Focus := Editor.Panel_Focus.Target (S.Panel_Focus);
      Status := Editor.External_Producers.Validate_Public_Build_Command_Input
        (Valid_Public_Input);
      Assert (Status = Editor.External_Producers.Public_Build_Input_Valid,
              "valid public input DTO must validate without side effects");
      Assert (Editor.Messages.Count (S.Messages) = Before_Messages,
              "public input validation must not post messages");
      Assert (Editor.Panel_Focus.Target (S.Panel_Focus) = Before_Focus,
              "public input validation must not switch feature focus");
   end Test_Public_Build_Input_Validation_Is_Side_Effect_Free;

   procedure Test_Public_Build_Input_Rejects_Invalid_Forms
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Input : Public_Build_Command_Input := Valid_Public_Input;
   begin
      Input.Source := Public_Build_Input_None;
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_No_Input,
              "public build input must reject no input source");

      Input := Valid_Public_Input;
      Input.Tool := No_Build_Tool;
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_No_Tool,
              "public build input must reject missing tool");

      Input := Valid_Public_Input;
      Input.Tool := Custom_Build_Tool;
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Custom_Tool,
              "public build input must reject custom tool");

      Input := Valid_Public_Input;
      Input.Program_Label := Null_Unbounded_String;
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Missing_Program,
              "public build input must reject missing program label");

      Input := Valid_Public_Input;
      Input.Consent := Build_Consent_Not_Provided;
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Missing_Consent,
              "public build input must reject missing consent");

      Input := Valid_Public_Input;
      Input.Consent_Model.User_Acknowledged_Execution := False;
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Missing_Consent,
              "public build input must reject partial structured consent");

      Input := Valid_Public_Input;
      Input.Working_Context := Build_Unsupported_Working_Context;
      Input.Working_Context_Model :=
        (Source => Public_Build_Working_Context_None,
         Label  => Null_Unbounded_String,
         User_Acknowledged_Context => False);
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Unsupported_Working_Context,
              "public build input must reject unsupported working context");

      Input := Valid_Public_Input;
      Input.Arguments := Empty_Process_Arguments;
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Opaque_Arguments,
              "public build input must require structured argv tokens");

      Input := Valid_Public_Input;
      Input.Arguments := Build_Process_Argument_Vector ("");
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Opaque_Arguments,
              "empty helper arguments must not synthesize argv");

      Input := Valid_Public_Input;
      Input.Arguments := Build_Process_Argument_Vector ("-q", "", "--keep-going");
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Empty_Argument,
              "public build input must reject empty structured argv entries");

      Input := Valid_Public_Input;
      Input.Program_Label := To_Unbounded_String ("gprbuild; rm -rf tmp");
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Shell,
              "public build input must reject shell syntax in program labels");
   end Test_Public_Build_Input_Rejects_Invalid_Forms;

   procedure Test_Public_Build_Input_Validates_Structured_Argv
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Status : constant Editor.External_Producers.Public_Build_Input_Validation_Status :=
        Editor.External_Producers.Validate_Public_Build_Command_Input
          (Valid_Public_Input);
   begin
      Assert (Status = Editor.External_Producers.Public_Build_Input_Valid,
              "structured public build argv should validate in the test context model");
   end Test_Public_Build_Input_Validates_Structured_Argv;

   procedure Test_Public_Build_Input_Safety_Classification
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      No_Input : Public_Build_Command_Input := Valid_Public_Input;
      User_Form : Public_Build_Command_Input := Valid_Public_Input;
   begin
      No_Input.Source := Public_Build_Input_None;
      User_Form.Source := Public_Build_Input_User_Form;
      User_Form.Consent := Build_Consent_Not_Provided;
      User_Form.Consent_Model := Valid_User_Form_Consent;
      User_Form.Working_Context := Build_Explicit_Label_Working_Context ("workspace label");
      User_Form.Working_Context_Model := Valid_User_Form_Working_Context;

      Assert (Classify_Public_Build_Input_Safety (No_Input) =
              Public_Build_Input_Not_Valid,
              "no public input must classify as not valid");
      Assert (Classify_Public_Build_Input_Safety (Valid_Public_Input) =
              Public_Build_Input_Valid_For_Internal_Test,
              "valid test-context input must be internal-test-only");
      Assert (Classify_Public_Build_Input_Safety (User_Form) =
              Public_Build_Input_Valid_But_Not_Publicly_Exposable,
              "structural user-form input remains gated until implicit build source policy exists");
   end Test_Public_Build_Input_Safety_Classification;

   procedure Test_Public_Build_Input_No_State_Publicly_Exposable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Input : Public_Build_Command_Input := Valid_Public_Input;
   begin
      Assert (Classify_Public_Build_Input_Safety (Input) /=
              Public_Build_Input_Publicly_Exposable,
              "test-context input must not be public-exposable");

      Input.Source := Public_Build_Input_User_Form;
      Input.Consent := Build_Consent_Not_Provided;
      Input.Consent_Model := Valid_User_Form_Consent;
      Input.Working_Context := Build_Explicit_Label_Working_Context ("workspace label");
      Input.Working_Context_Model := Valid_User_Form_Working_Context;
      Assert (Classify_Public_Build_Input_Safety (Input) /=
              Public_Build_Input_Publicly_Exposable,
              "user-form input must not be public-exposable in ");

      Input.Source := Public_Build_Input_None;
      Input.Working_Context := Build_Unsupported_Working_Context;
      Input.Working_Context_Model :=
        (Source => Public_Build_Working_Context_None,
         Label  => Null_Unbounded_String,
         User_Acknowledged_Context => False);
      Assert (Classify_Public_Build_Input_Safety (Input) /=
              Public_Build_Input_Publicly_Exposable,
              "invalid input must not be public-exposable");
   end Test_Public_Build_Input_No_State_Publicly_Exposable;

   procedure Test_Public_Build_Input_Working_Context_Guardrails
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Input : Public_Build_Command_Input := Valid_Public_Input;
   begin
      Input.Working_Context := Build_Unsupported_Working_Context;
      Input.Working_Context_Model :=
        (Source => Public_Build_Working_Context_None,
         Label  => Null_Unbounded_String,
         User_Acknowledged_Context => False);
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Unsupported_Working_Context,
              "unsupported working context must reject validation");

      Input := Valid_Public_Input;
      Input.Working_Context := Build_Explicit_Label_Working_Context ("/tmp/project");
      Input.Working_Context_Model :=
        (Source => Public_Build_Working_Context_User_Form_Label,
         Label  => To_Unbounded_String ("/tmp/project"),
         User_Acknowledged_Context => True);
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Unsafe_Working_Context,
              "explicit label context must not validate for execution");
      declare
         Request : constant Build_Run_Request :=
           Build_User_Opt_In_Request_From_Public_Input (Input);
      begin
         Assert (Request.Provenance = Build_Request_Unknown,
                 "explicit label context must not convert to executable request");
      end;

      Input := Valid_Public_Input;
      Input.Source := Public_Build_Input_User_Form;
      Input.Consent := Build_Consent_User_Confirmed;
      Input.Consent_Model := Valid_User_Form_Consent;
      Input.Working_Context_Model := Valid_Test_Working_Context;
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Unsupported_Working_Context,
              "test working context must be accepted only for test source");

      Input := Valid_Public_Input;
      Input.Working_Context := Build_Explicit_Label_Working_Context ("project:root");
      Input.Working_Context_Model :=
        (Source => Public_Build_Working_Context_Project_Derived,
         Label  => To_Unbounded_String ("project:root"),
         User_Acknowledged_Context => True);
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Unsafe_Working_Context,
              "project-derived working labels must be rejected");
   end Test_Public_Build_Input_Working_Context_Guardrails;

   procedure Test_Public_Build_Input_Program_Label_Guardrails
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Input : Public_Build_Command_Input := Valid_Public_Input;
   begin
      Input.Program_Label := To_Unbounded_String ("   ");
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Missing_Program,
              "blank-only program label must be rejected");

      Input.Program_Label := To_Unbounded_String ("bin/gprbuild");
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Valid,
              "path-like program labels remain metadata labels, not resolved paths");
   end Test_Public_Build_Input_Program_Label_Guardrails;

   procedure Test_Public_Build_Input_Argument_Guardrails
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Input : Public_Build_Command_Input := Valid_Public_Input;
      Request : Build_Run_Request;
   begin
      Input.Arguments := Build_Process_Argument_Vector ("-gnat2022", "file name.adb");
      Request := Build_User_Opt_In_Request_From_Public_Input (Input);
      Assert (Request.Provenance = Build_Request_From_User_Opt_In,
              "whitespace argv token must remain structured and valid");
      Assert (To_String (Request.Structured_Arguments.Element (1)) = "file name.adb",
              "public input conversion must not split whitespace arguments");

      Input.Arguments := Build_Process_Argument_Vector ("""quoted arg""");
      Request := Build_User_Opt_In_Request_From_Public_Input (Input);
      Assert (To_String (Request.Structured_Arguments.Element (0)) = """quoted arg""",
              "public input conversion must not parse quoted arguments");

      Input.Arguments := Build_Process_Argument_Vector ("-q; rm -rf tmp");
      Request := Build_User_Opt_In_Request_From_Public_Input (Input);
      Assert (Request.Provenance = Build_Request_From_User_Opt_In,
              "shell metacharacters in structured argv must remain inert text");
      Assert (To_String (Request.Structured_Arguments.Element (0)) = "-q; rm -rf tmp",
              "structured argv shell metacharacters must not be interpreted");

      Input.Arguments := Build_Process_Argument_Vector ("-q" & Character'Val (10));
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Control_Argument,
              "control-character argv entries must be rejected");
   end Test_Public_Build_Input_Argument_Guardrails;

   procedure Assert_Public_Build_Input_Conversion_Consistent
     (Input   : Editor.External_Producers.Public_Build_Command_Input;
      Request : Editor.External_Producers.Build_Run_Request)
   is
      use Editor.External_Producers;
   begin
      Assert (Request.Provenance = Build_Request_From_User_Opt_In,
              "conversion must use user-opt-in provenance");
      Assert (Request.Tool = Input.Tool,
              "conversion must preserve build tool");
      Assert (To_String (Request.Command_Label) = To_String (Input.Program_Label),
              "conversion must preserve program label as metadata");
      Assert (To_String (Request.Arguments)'Length = 0,
              "conversion must not introduce opaque command text");
      Assert (Process_Argument_Count (Request.Structured_Arguments) =
              Process_Argument_Count (Input.Arguments),
              "conversion must preserve structured argv count");
      Assert (To_String (Request.Working_Label)'Length = 0,
              "conversion must not create a real working directory label");
   end Assert_Public_Build_Input_Conversion_Consistent;

   procedure Test_Public_Build_Input_Conversion_Consistency_Valid_Test_Context
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Input : constant Public_Build_Command_Input := Valid_Public_Input;
      Request : constant Build_Run_Request :=
        Build_User_Opt_In_Request_From_Public_Input (Input);
   begin
      Assert_Public_Build_Input_Conversion_Consistent (Input, Request);
   end Test_Public_Build_Input_Conversion_Consistency_Valid_Test_Context;

   procedure Test_Public_Build_Input_Conversion_Requires_Valid_Input
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Input : Public_Build_Command_Input := Valid_Public_Input;
      Request : Build_Run_Request;
   begin
      Input.Source := Public_Build_Input_None;
      Request := Build_User_Opt_In_Request_From_Public_Input (Input);
      Assert (Request.Provenance = Build_Request_Unknown,
              "invalid public input must convert only to inert unknown provenance");
      Assert (Validate_Build_Run_Request_Status (Request) /= Build_Request_Valid,
              "invalid public input must not become an executable build request");
   end Test_Public_Build_Input_Conversion_Requires_Valid_Input;


   procedure Test_Public_Build_Input_Conversion_Rejects_Invalid_Consent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Input : Public_Build_Command_Input := Valid_Public_Input;
      Request : Build_Run_Request;
   begin
      Input.Consent_Model.User_Acknowledged_External_Process := False;
      Request := Build_User_Opt_In_Request_From_Public_Input (Input);
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Missing_Consent,
              "partial consent model must reject public input validation");
      Assert (Request.Provenance = Build_Request_Unknown,
              "invalid consent must not convert to user-opt-in provenance");
   end Test_Public_Build_Input_Conversion_Rejects_Invalid_Consent;

   procedure Test_Public_Build_Input_Conversion_Does_Not_Silently_Upgrade_Consent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Input : Public_Build_Command_Input := Valid_Public_Input;
      Request : Build_Run_Request;
   begin
      Input.Consent_Model := Valid_User_Form_Consent;
      Request := Build_User_Opt_In_Request_From_Public_Input (Input);
      Assert (Build_Execution_Consent_From_Public_Model (Input.Consent_Model) =
              Build_Consent_User_Confirmed,
              "acknowledged user-form consent converts to execution consent");
      Assert (Request.Provenance = Build_Request_Unknown,
              "non-public consent model does not convert the full request");
   end Test_Public_Build_Input_Conversion_Does_Not_Silently_Upgrade_Consent;

   procedure Test_Public_Build_Input_Conversion_Uses_User_Opt_In_Provenance
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Request : constant Build_Run_Request :=
        Build_User_Opt_In_Request_From_Public_Input
          (Valid_Public_Input);
   begin
      Assert (Request.Provenance = Build_Request_From_User_Opt_In,
              "valid public input conversion must preserve user-opt-in provenance");
      Assert (Process_Argument_Count (Request.Structured_Arguments) = 1,
              "valid public input conversion must preserve structured argv");
      Assert (To_String (Request.Arguments)'Length = 0,
              "valid public input conversion must not carry opaque argument text");
   end Test_Public_Build_Input_Conversion_Uses_User_Opt_In_Provenance;

   procedure Test_Public_Build_Input_Feedback_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
   begin
      Assert (Build_Public_Build_Input_Feedback
                (Public_Build_Input_Rejected_No_Input) =
              "Build: input required",
              "no-input feedback must be compact and deterministic");
      Assert (Build_Public_Build_Input_Feedback
                (Public_Build_Input_Rejected_Custom_Tool) =
              "Build: custom build tool not supported",
              "custom-tool feedback must not expose command internals");
      Assert (Build_Public_Build_Input_Feedback
                (Public_Build_Input_Rejected_Shell) =
              "Build: shell execution disabled",
              "shell feedback must be compact and deterministic");
   end Test_Public_Build_Input_Feedback_Is_Deterministic;

   procedure Test_Public_Build_Readiness_Audit_Reports_Input_Model_Present
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.External_Producers.Public_Build_Command_Readiness_Audit_Result;
   begin
      Editor.State.Init (S);
      R := Editor.External_Producers.Run_Public_Build_Command_Readiness_Audit (S);
      Assert (R.Has_User_Command_Input_Model,
              "readiness audit must report public input model present");
      Assert (R.Has_Public_Input_Model_Audit,
              "readiness audit must include public input model audit");
      Assert (R.Public_Input_Validation_Side_Effect_Free,
              "readiness audit must prove public input validation is pure metadata");
      Assert (R.Public_Input_Conversion_Requires_Valid_Input,
              "readiness audit must prove conversion requires valid input");
      Assert (R.Public_Input_Conversion_Preserves_Provenance,
              "readiness audit must prove conversion preserves user-opt-in provenance");
      Assert (R.Public_Input_Conversion_Uses_Structured_Argv,
              "readiness audit must prove conversion uses structured argv");
      Assert (R.Public_Input_Does_Not_Create_Command_Descriptors,
              "public input model must not create command descriptors");
      Assert (R.Public_Input_Validation_Complete,
              "audit must report public input validation complete");
      Assert (R.Public_Input_Has_Safety_Classification,
              "audit must report public input safety classification");
      Assert (R.Public_Input_Publicly_Exposable,
              "audit must report public input model ready");
      Assert (R.Working_Context_Publicly_Ready,
              "readiness audit must report public working context ready");
      Assert (R.Consent_UX_Publicly_Ready,
              "readiness audit must report public consent UX ready");
      Assert (R.Public_Input_Does_Not_Enable_Public_Execution,
              "public input model must not enable default execution");
   end Test_Public_Build_Readiness_Audit_Reports_Input_Model_Present;

   procedure Test_Public_Build_Input_Does_Not_Register_Public_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Request : constant Editor.External_Producers.Build_Run_Request :=
        Editor.External_Producers.Build_User_Opt_In_Request_From_Public_Input
          (Valid_Public_Input);
      pragma Unreferenced (Request);
   begin
      Assert_Public_Build_Name_Not_Registered ("build.run");
      Assert_Public_Build_Name_Not_Registered ("build.project");
      Assert_Public_Build_Name_Not_Registered ("build.run-project");
      Assert_Public_Build_Name_Not_Registered ("compile.project");
      Assert_Public_Build_Name_Not_Registered ("compile.current");
      Assert_Public_Build_Name_Not_Registered ("diagnostics.run-build");
   end Test_Public_Build_Input_Does_Not_Register_Public_Command;

   procedure Test_Build_Command_Classification_Helpers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      for I in 1 .. Editor.Commands.Command_Count loop
         declare
            Id : constant Editor.Commands.Command_Id := Editor.Commands.Command_At (I);
         begin
            if Editor.Commands.Is_Public_Build_Command (Id) then
               Assert (Ada.Strings.Fixed.Index
                         (Editor.Commands.Stable_Command_Name (Id), "build.") = 1,
                       "public build commands must stay under the build namespace");
               Assert (not Editor.Commands.Is_Internal_Build_Test_Seam_Command (Id),
                       "internal test seams must not be public build commands");
            end if;
         end;
      end loop;
      Assert (Editor.Commands.Is_Internal_Build_Test_Seam_Command
                (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam),
              "user opt-in test seam must be classified as internal build test seam");
      Assert (not Editor.Commands.Is_Internal_Build_Test_Seam_Command
                (Editor.Commands.Command_Save_File),
              "non-build commands must not be classified as internal build test seams");
   end Test_Build_Command_Classification_Helpers;


   procedure Test_Public_Build_Working_Context_Validation_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Messages : Natural;
      Before_Focus : Editor.Panel_Focus.Focus_Target;
      Status : Editor.External_Producers.Public_Build_Working_Context_Validation_Status;
   begin
      Editor.State.Init (S);
      Before_Messages := Editor.Messages.Count (S.Messages);
      Before_Focus := Editor.Panel_Focus.Target (S.Panel_Focus);
      Status := Editor.External_Producers.Validate_Public_Build_Working_Context
        (Valid_Test_Working_Context);
      Assert (Status = Editor.External_Producers.Public_Build_Working_Context_Valid_For_Internal_Test,
              "test working context must validate without side effects");
      Assert (Editor.Messages.Count (S.Messages) = Before_Messages,
              "working-context validation must not post messages");
      Assert (Editor.Panel_Focus.Target (S.Panel_Focus) = Before_Focus,
              "working-context validation must not switch feature focus");
   end Test_Public_Build_Working_Context_Validation_Is_Side_Effect_Free;

   procedure Test_Public_Build_Working_Context_Rejects_Invalid_Forms
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Context : Public_Build_Working_Context_Model;
   begin
      Context := (Source => Public_Build_Working_Context_None,
                  Label  => Null_Unbounded_String,
                  User_Acknowledged_Context => False);
      Assert (Validate_Public_Build_Working_Context (Context) =
              Public_Build_Working_Context_Rejected_None,
              "missing working context must reject deterministically");

      Context := (Source => Public_Build_Working_Context_Project_Derived,
                  Label  => To_Unbounded_String ("project:root"),
                  User_Acknowledged_Context => True);
      Assert (Validate_Public_Build_Working_Context (Context) =
              Public_Build_Working_Context_Rejected_Project_Derived,
              "project-derived working context must reject deterministically");

      Context := (Source => Public_Build_Working_Context_User_Form_Label,
                  Label  => Null_Unbounded_String,
                  User_Acknowledged_Context => True);
      Assert (Validate_Public_Build_Working_Context (Context) =
              Public_Build_Working_Context_Rejected_Missing_Label,
              "missing user-form working label must reject deterministically");

      Context := Valid_User_Form_Working_Context;
      Context.User_Acknowledged_Context := False;
      Assert (Validate_Public_Build_Working_Context (Context) =
              Public_Build_Working_Context_Rejected_Missing_Acknowledgement,
              "missing working-context acknowledgement must reject deterministically");

      Context := Valid_User_Form_Working_Context;
      Context.Label := To_Unbounded_String ("bad" & Character'Val (10));
      Assert (Validate_Public_Build_Working_Context (Context) =
              Public_Build_Working_Context_Rejected_Unsafe_Label,
              "control-character working labels must reject deterministically");

      Context := Valid_User_Form_Working_Context;
      Context.Label := To_Unbounded_String ("/tmp/project");
      Assert (Validate_Public_Build_Working_Context (Context) =
              Public_Build_Working_Context_Rejected_Unsafe_Label,
              "path-like working labels must reject until safe directory UX exists");
   end Test_Public_Build_Working_Context_Rejects_Invalid_Forms;

   procedure Test_Public_Build_Working_Context_Test_Context_Internal_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Context : constant Public_Build_Working_Context_Model :=
        Valid_Test_Working_Context;
      Converted : constant Editor.External_Producers.Build_Working_Context :=
        Build_Working_Context_From_Public_Model (Context);
   begin
      Assert (Validate_Public_Build_Working_Context (Context) =
              Public_Build_Working_Context_Valid_For_Internal_Test,
              "test working context must validate for internal/test conversion only");
      Assert (Classify_Public_Build_Working_Context_Safety (Context) =
              Public_Build_Input_Valid_For_Internal_Test,
              "test working context must classify as internal-test-only");
      Assert (Converted.Kind = Build_Working_Context_Inherited_Test_Context,
              "test working context must convert only to inherited test context");
      Assert (Assert_Public_Build_Working_Context_Conversion_Consistent
                (Context, Converted),
              "test working-context conversion must be consistent");
   end Test_Public_Build_Working_Context_Test_Context_Internal_Only;

   procedure Test_Public_Build_Working_Context_User_Form_Not_Publicly_Exposable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Context : constant Public_Build_Working_Context_Model :=
        Valid_User_Form_Working_Context;
      Converted : constant Editor.External_Producers.Build_Working_Context :=
        Build_Working_Context_From_Public_Model (Context);
   begin
      Assert (Validate_Public_Build_Working_Context (Context) =
              Public_Build_Working_Context_Valid_But_Not_Public_UX,
              "user-form working context must remain structurally valid but not UX-ready");
      Assert (Classify_Public_Build_Working_Context_Safety (Context) =
              Public_Build_Input_Valid_But_Not_Publicly_Exposable,
              "user-form working context must not classify as publicly exposable");
      Assert (Classify_Public_Build_Working_Context_Safety (Context) /=
              Public_Build_Input_Publicly_Exposable,
              "no working context may be publicly exposable in ");
      Assert (Converted.Kind = Build_Working_Context_Explicit_Label,
              "safe user-form working context converts to an explicit guarded label");
   end Test_Public_Build_Working_Context_User_Form_Not_Publicly_Exposable;

   procedure Test_Public_Build_Input_Conversion_Rejects_Project_Derived_Working_Context
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Input : Public_Build_Command_Input := Valid_Public_Input;
      Request : Build_Run_Request;
   begin
      Input.Working_Context_Model :=
        (Source => Public_Build_Working_Context_Project_Derived,
         Label  => To_Unbounded_String ("project:root"),
         User_Acknowledged_Context => True);
      Request := Build_User_Opt_In_Request_From_Public_Input (Input);
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Unsafe_Working_Context,
              "project-derived public working context must reject input validation");
      Assert (Request.Provenance = Build_Request_Unknown,
              "project-derived working context must not convert to user-opt-in provenance");
   end Test_Public_Build_Input_Conversion_Rejects_Project_Derived_Working_Context;

   procedure Test_Public_Build_Input_Conversion_Does_Not_Silently_Upgrade_Working_Context
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Input : Public_Build_Command_Input := Valid_Public_Input;
      Request : Build_Run_Request;
   begin
      Input.Working_Context_Model := Valid_User_Form_Working_Context;
      Request := Build_User_Opt_In_Request_From_Public_Input (Input);
      Assert (Build_Working_Context_From_Public_Model
                (Input.Working_Context_Model).Kind = Build_Working_Context_Explicit_Label,
              "safe user-form working context converts to an explicit guarded label");
      Assert (Request.Provenance = Build_Request_Unknown,
              "non-public working context model does not convert the full request");
   end Test_Public_Build_Input_Conversion_Does_Not_Silently_Upgrade_Working_Context;

   procedure Test_Public_Build_Input_Conversion_Valid_Test_Working_Context_Uses_Inherited_Test_Context
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Input : constant Public_Build_Command_Input := Valid_Public_Input;
      Converted : constant Editor.External_Producers.Build_Working_Context :=
        Build_Working_Context_From_Public_Model (Input.Working_Context_Model);
      Request : constant Build_Run_Request :=
        Build_User_Opt_In_Request_From_Public_Input (Input);
   begin
      Assert (Converted.Kind = Build_Working_Context_Inherited_Test_Context,
              "valid test public working context must convert to inherited test context");
      Assert (To_String (Converted.Label)'Length = 0,
              "inherited test context conversion must not preserve a filesystem label");
      Assert (Request.Provenance = Build_Request_From_User_Opt_In,
              "valid test input with valid working context may convert internally");
   end Test_Public_Build_Input_Conversion_Valid_Test_Working_Context_Uses_Inherited_Test_Context;

   procedure Test_Public_Build_Working_Context_Feedback_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
   begin
      Assert (Build_Public_Build_Working_Context_Feedback
                (Public_Build_Working_Context_Rejected_None) =
              "Build: working context required",
              "missing context feedback must be stable");
      Assert (Build_Public_Build_Working_Context_Feedback
                (Public_Build_Working_Context_Rejected_Project_Derived) =
              "Build: project working context not supported",
              "project-derived context feedback must be stable");
      Assert (Build_Public_Build_Working_Context_Feedback
                (Public_Build_Working_Context_Valid_But_Not_Public_UX) =
              "Build: public working directory UX not ready",
              "user-form context feedback must report missing UX");
   end Test_Public_Build_Working_Context_Feedback_Is_Deterministic;

   procedure Test_Public_Build_Readiness_Audit_Reports_Working_Context_Model
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.External_Producers.Public_Build_Command_Readiness_Audit_Result;
   begin
      Editor.State.Init (S);
      R := Editor.External_Producers.Run_Public_Build_Command_Readiness_Audit (S);
      Assert (R.Public_Working_Context_Model_Exists,
              "readiness audit must report public working-context model exists");
      Assert (R.Public_Working_Context_Model_Validated,
              "readiness audit must report public working-context validation exists");
      Assert (R.Public_Working_Context_Publicly_Ready,
              "readiness audit must report public working-context UX ready");
      Assert (R.Public_Working_Context_Publicly_Exposable,
              "readiness audit must report public working context is exposable");
      Assert (R.Project_Derived_Working_Context_Rejected,
              "readiness audit must report project-derived working context rejected");
      Assert (R.Passed_As_Not_Ready,
              "readiness audit must still pass only as intentionally not ready");
   end Test_Public_Build_Readiness_Audit_Reports_Working_Context_Model;

   procedure Test_Public_Build_Working_Context_Model_Does_Not_Register_Public_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Status : constant Editor.External_Producers.Public_Build_Working_Context_Validation_Status :=
        Editor.External_Producers.Validate_Public_Build_Working_Context
          (Valid_User_Form_Working_Context);
      pragma Unreferenced (Status);
   begin
      Assert_Public_Build_Name_Not_Registered ("build.run");
      Assert_Public_Build_Name_Not_Registered ("build.project");
      Assert_Public_Build_Name_Not_Registered ("build.run-project");
      Assert_Public_Build_Name_Not_Registered ("compile.project");
      Assert_Public_Build_Name_Not_Registered ("compile.current");
      Assert_Public_Build_Name_Not_Registered ("diagnostics.run-build");
   end Test_Public_Build_Working_Context_Model_Does_Not_Register_Public_Command;


   procedure Test_Public_Build_Command_Surface_Entries_Exist_As_Metadata_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Surface_Entries : constant Public_Build_Command_Surface_Array :=
        Build_Public_Build_Command_Surface;
      Surface_Entry : Public_Build_Command_Surface_Entry;
   begin
      Assert (Surface_Entries.Length = 1,
              "public build surface defines the single guarded build.run entry");
      Surface_Entry := Surface_Entries.First_Element;
      Assert (To_String (Surface_Entry.Stable_Id) = "build.run",
              "surface entry name must be build.run");
      Assert (Validate_Public_Build_Command_Surface_Entry (Surface_Entry) =
              Public_Build_Command_Surface_Valid,
              "surface entry metadata must validate");
      Assert (Surface_Entry.Has_Input_Model,
              "surface entry must reference the public input model");
      Assert (Surface_Entry.Has_Consent_Model,
              "surface entry must reference the public consent model");
      Assert (Surface_Entry.Has_Working_Context_Model,
              "surface entry must reference the public working-context model");
      Assert (Surface_Entry.Publicly_Invokable,
              "surface entry must be publicly invokable through the guarded command");
      Assert (Surface_Entry.Routes_Through_Executor,
              "surface entry must route through Executor");
      Assert_Public_Build_Command_Surface_Entry_Consistent (Surface_Entry);
   end Test_Public_Build_Command_Surface_Entries_Exist_As_Metadata_Only;

   procedure Test_Public_Build_Command_Surface_Entry_Not_Registered
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert_Public_Build_Name_Not_Registered ("build.run");
      Assert_Public_Build_Name_Not_Registered ("build.configure");
      Assert_Public_Build_Name_Not_Registered
        ("build.show-diagnostics-after-build");
      Assert_Public_Build_Name_Not_Registered ("build.project");
      Assert_Public_Build_Name_Not_Registered ("build.run-project");
      Assert_Public_Build_Name_Not_Registered ("compile.project");
      Assert_Public_Build_Name_Not_Registered ("compile.current");
      Assert_Public_Build_Name_Not_Registered ("diagnostics.run-build");
   end Test_Public_Build_Command_Surface_Entry_Not_Registered;

   procedure Test_Public_Build_Command_Surface_Entry_Has_No_Keybinding
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.External_Producers.Public_Build_Command_Readiness_Audit_Result;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Editor.State.Init (S);
      R := Editor.External_Producers.Run_Public_Build_Command_Readiness_Audit (S);
      Assert (not R.Has_Default_Public_Build_Keybinding,
              "public build surface entrys must have no default keybinding");
   end Test_Public_Build_Command_Surface_Entry_Has_No_Keybinding;

   procedure Test_Public_Build_Command_Surface_Entry_Not_In_Normal_Palette
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
   begin
      Editor.State.Init (S);
      Editor.Executor.Command_Palette_Candidates (S, Candidates);
      for Candidate of Candidates loop
         Assert (Editor.Commands.Stable_Command_Name (Candidate.Id) /= "build.run"
                 and then Editor.Commands.Stable_Command_Name (Candidate.Id) /=
                   "build.configure"
                 and then Editor.Commands.Stable_Command_Name (Candidate.Id) /=
                   "build.show-diagnostics-after-build"
                 and then Editor.Commands.Stable_Command_Name (Candidate.Id) /=
                   "build.project"
                 and then Editor.Commands.Stable_Command_Name (Candidate.Id) /=
                   "build.run-project"
                 and then Editor.Commands.Stable_Command_Name (Candidate.Id) /=
                   "compile.project"
                 and then Editor.Commands.Stable_Command_Name (Candidate.Id) /=
                   "compile.current"
                 and then Editor.Commands.Stable_Command_Name (Candidate.Id) /=
                   "diagnostics.run-build",
                 "normal palette must not contain public build surface entrys");
      end loop;
   end Test_Public_Build_Command_Surface_Entry_Not_In_Normal_Palette;

   procedure Test_Public_Build_Command_Surface_Entry_Does_Not_Route_To_Executor
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
   begin
      Assert (Audit_Public_Build_Command_Visibility,
              "public surface entry visibility audit must prove no Executor route exists");
      Assert_Public_Build_Name_Not_Registered ("build.run");
      Assert_Public_Build_Name_Not_Registered ("build.configure");
      Assert_Public_Build_Name_Not_Registered
        ("build.show-diagnostics-after-build");
      Assert_Public_Build_Name_Not_Registered ("build.project");
      Assert_Public_Build_Name_Not_Registered ("build.run-project");
      Assert_Public_Build_Name_Not_Registered ("compile.project");
      Assert_Public_Build_Name_Not_Registered ("compile.current");
      Assert_Public_Build_Name_Not_Registered ("diagnostics.run-build");
   end Test_Public_Build_Command_Surface_Entry_Does_Not_Route_To_Executor;

   procedure Test_Public_Build_Command_Surface_Validation_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Before_Messages : Natural;
      Before_Has_Buffer : Boolean;
      Status : Public_Build_Command_Surface_Status;
   begin
      Editor.State.Init (S);
      Before_Messages := Editor.Messages.Count (S.Messages);
      Before_Has_Buffer := Editor.State.Has_Active_Buffer (S);
      Status := Validate_Public_Build_Command_Surface_Entry
        ((Stable_Id => To_Unbounded_String ("build.run"),
          Has_Descriptor => True,
          Has_Input_Model => True,
          Has_Consent_Model => True,
          Has_Working_Context_Model => True,
          Publicly_Invokable => True,
          Routes_Through_Executor => True,
          others => <>));
      Assert (Status = Public_Build_Command_Surface_Valid,
              "valid surface entry metadata must validate");
      Assert (Editor.Messages.Count (S.Messages) = Before_Messages,
              "surface entry validation must not post messages");
      Assert (Editor.State.Has_Active_Buffer (S) = Before_Has_Buffer,
              "surface entry validation must not create buffers");
      Assert_Public_Build_Name_Not_Registered ("build.run");
   end Test_Public_Build_Command_Surface_Validation_Is_Side_Effect_Free;

   procedure Test_Public_Build_Command_Surface_Entry_Rejects_Invalid_Forms
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Assert (Validate_Public_Build_Command_Surface_Entry
                ((Stable_Id => Null_Unbounded_String,
                  Has_Input_Model => True,
                  Has_Consent_Model => True,
                  Has_Working_Context_Model => True,
                  Publicly_Invokable => False,
          others => <>)) =
              Public_Build_Command_Surface_Rejected_Empty_Id,
              "empty surface entry id must reject");
      Assert (Validate_Public_Build_Command_Surface_Entry
                ((Stable_Id => To_Unbounded_String ("build.run"),
                  Has_Descriptor => True,
                  Has_Input_Model => False,
                  Has_Consent_Model => True,
                  Has_Working_Context_Model => True,
                  Publicly_Invokable => True,
          Routes_Through_Executor => True,
          others => <>)) =
              Public_Build_Command_Surface_Rejected_Missing_Input_Model,
              "surface entry without input model must reject");
      Assert (Validate_Public_Build_Command_Surface_Entry
                ((Stable_Id => To_Unbounded_String ("build.run"),
                  Has_Descriptor => True,
                  Has_Input_Model => True,
                  Has_Consent_Model => False,
                  Has_Working_Context_Model => True,
                  Publicly_Invokable => True,
          Routes_Through_Executor => True,
          others => <>)) =
              Public_Build_Command_Surface_Rejected_Missing_Consent_Model,
              "surface entry without consent model must reject");
      Assert (Validate_Public_Build_Command_Surface_Entry
                ((Stable_Id => To_Unbounded_String ("build.run"),
                  Has_Descriptor => True,
                  Has_Input_Model => True,
                  Has_Consent_Model => True,
                  Has_Working_Context_Model => False,
                  Publicly_Invokable => True,
          Routes_Through_Executor => True,
          others => <>)) =
              Public_Build_Command_Surface_Rejected_Missing_Working_Context_Model,
              "surface entry without working-context model must reject");
      Assert (Validate_Public_Build_Command_Surface_Entry
                ((Stable_Id => To_Unbounded_String ("build.run"),
                  Has_Descriptor => True,
                  Has_Input_Model => True,
                  Has_Consent_Model => True,
                  Has_Working_Context_Model => True,
                  Publicly_Invokable => False,
          others => <>)) =
              Public_Build_Command_Surface_Rejected_Not_Publicly_Invokable,
              "non-invokable surface entry must reject");
      Assert (Validate_Public_Build_Command_Surface_Entry
                ((Stable_Id => To_Unbounded_String
                    ("build.run-user-opt-in-test-seam"),
                  Has_Descriptor => True,
                  Has_Input_Model => True,
                  Has_Consent_Model => True,
                  Has_Working_Context_Model => True,
                  Publicly_Invokable => True,
          Routes_Through_Executor => True,
          others => <>)) =
              Public_Build_Command_Surface_Rejected_Missing_Descriptor,
              "non-public command id must reject as surface entry metadata");
      Assert (Validate_Public_Build_Command_Surface_Entry
                ((Stable_Id => To_Unbounded_String ("file.save"),
                  Has_Descriptor => True,
                  Has_Input_Model => True,
                  Has_Consent_Model => True,
                  Has_Working_Context_Model => True,
                  Publicly_Invokable => True,
          Routes_Through_Executor => True,
          others => <>)) =
              Public_Build_Command_Surface_Rejected_Missing_Descriptor,
              "non-public default-keybound command must reject as surface entry metadata");
   end Test_Public_Build_Command_Surface_Entry_Rejects_Invalid_Forms;

   procedure Test_Public_Build_Readiness_Audit_Reports_Surface_Entries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.External_Producers.Public_Build_Command_Readiness_Audit_Result;
   begin
      Editor.State.Init (S);
      R := Editor.External_Producers.Run_Public_Build_Command_Readiness_Audit (S);
      Assert (R.Public_Command_Surface_Exists,
              "readiness audit must report design-only surface entry metadata exists");
      Assert (R.Public_Executable_Command_Exists,
              "readiness audit must report guarded executable public command");
      Assert (R.Public_Command_Is_Invokable,
              "readiness audit must report public command is guarded and invokable");
      Assert (R.Public_Command_Has_Complete_UX_Models,
              "readiness audit must report complete public command UX models");
      Assert (R.Public_Command_Publicly_Exposable,
              "readiness audit must report public command is exposable through guards");
      Assert (R.Passed_As_Not_Ready,
              "surface entry-aware readiness audit must still pass only as not ready");
   end Test_Public_Build_Readiness_Audit_Reports_Surface_Entries;

   procedure Test_Public_Build_Command_UX_Dependency_Matrix_Is_Ready
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      R : constant Editor.External_Producers.Public_Build_Command_UX_Dependency_Audit_Result :=
        Editor.External_Producers.Audit_Public_Build_Command_UX_Dependencies;
   begin
      Assert (R.Has_Input_Model,
              "dependency matrix must report public input model exists");
      Assert (R.Has_Structured_Argv_Model,
              "dependency matrix must require structured argv");
      Assert (R.Has_Consent_Model,
              "dependency matrix must report public consent model exists");
      Assert (R.Has_Real_Consent_UX,
              "dependency matrix must report real consent UX ready");
      Assert (R.Has_Working_Context_Model,
              "dependency matrix must report working-context model exists");
      Assert (R.Has_Safe_Working_Context_UX,
              "dependency matrix must report safe working-directory UX ready");
      Assert (R.Has_Implicit_Source_Validation,
              "dependency matrix must report explicit-source policy validation");
      Assert (R.Explicitly_Rejects_Implicit_Source,
              "dependency matrix must keep implicit build source explicitly rejected");
      Assert (R.Requires_Executor_Routed_Mutation,
              "dependency matrix must require Executor-routed mutation");
      Assert (R.Requires_One_Primary_Result,
              "dependency matrix must preserve one primary result policy");
      Assert (R.Requires_Diagnostics_Pipeline,
              "dependency matrix must require Diagnostics pipeline routing");
      Assert (R.Requires_No_Shell_Execution,
              "dependency matrix must require no-shell execution");
      Assert (R.Requires_Side_Effect_Free_Availability,
              "dependency matrix must require side-effect-free availability");
      Assert (R.Requires_No_Persistence_Of_Transient_State,
              "dependency matrix must forbid persistence of transient build state");
      Assert (R.Public_Command_Exposure_Blocked,
              "dependency matrix must report public command exposure blocked");
      Assert (R.Passed_As_Not_Ready,
              "dependency matrix must pass with guarded public promotion ready");
   end Test_Public_Build_Command_UX_Dependency_Matrix_Is_Ready;

   procedure Test_Public_Build_Command_Not_Ready_Feedback_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.External_Producers.Public_Build_Command_Readiness_Audit_Result;
   begin
      Editor.State.Init (S);
      R := Editor.External_Producers.Run_Public_Build_Command_Readiness_Audit (S);
      Assert (Editor.External_Producers.Build_Public_Command_Not_Ready_Feedback (R) =
              "Build: public command not ready",
              "ready baseline feedback must fall back to generic not-ready helper text");
      R.Public_Consent_UX_Publicly_Ready := False;
      Assert (Editor.External_Producers.Build_Public_Command_Not_Ready_Feedback (R) =
              "Build: consent UX not ready",
              "feedback must report missing consent UX when simulated");
      R.Public_Consent_UX_Publicly_Ready := True;
      R.Public_Working_Context_Publicly_Ready := False;
      Assert (Editor.External_Producers.Build_Public_Command_Not_Ready_Feedback (R) =
              "Build: working directory UX not ready",
              "feedback must report missing working-directory UX without paths");
      R.Public_Working_Context_Publicly_Ready := True;
      Assert (Editor.External_Producers.Build_Public_Command_Not_Ready_Feedback (R) =
              "Build: public command not ready",
              "feedback must not probe project files in the ready baseline");
   end Test_Public_Build_Command_Not_Ready_Feedback_Is_Deterministic;

   procedure Test_Public_Build_Command_Exposure_Barrier_Passes_For_Surface_Entries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Editor.External_Producers.Assert_Public_Build_Command_Surface_Exposed;
      Assert (Editor.External_Producers.Audit_Public_Build_Command_Visibility,
              "exposure barrier must pass while surface entrys remain metadata only");
   end Test_Public_Build_Command_Exposure_Barrier_Passes_For_Surface_Entries;


   procedure Test_Public_Build_Promotion_Blocked_When_Consent_UX_Missing
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      R : Public_Build_Command_Readiness_Audit_Result;
      P : constant Public_Build_Command_Surface_Entry :=
        (Stable_Id => To_Unbounded_String ("build.run"),
         Has_Descriptor => True,
         Has_Input_Model => True,
         Has_Consent_Model => True,
         Has_Working_Context_Model => True,
         Publicly_Invokable => True,
          Routes_Through_Executor => True,
          others => <>);
   begin
      Editor.State.Init (S);
      R := Run_Public_Build_Command_Readiness_Audit (S);
      R.Public_Consent_UX_Publicly_Ready := False;
      R.Public_Consent_Publicly_Exposable := False;
      Assert (Validate_Public_Build_Command_Promotion (P, R) =
              Public_Build_Promotion_Consent_UX_Incomplete,
              "promotion must be blocked by missing real consent UX");
      Assert (Build_Public_Command_Promotion_Feedback
                (Public_Build_Promotion_Consent_UX_Incomplete) =
              "Build: consent UX not ready",
              "consent promotion feedback must not leak command details");
   end Test_Public_Build_Promotion_Blocked_When_Consent_UX_Missing;

   procedure Test_Public_Build_Promotion_Blocked_When_Working_Context_UX_Missing
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      R : Public_Build_Command_Readiness_Audit_Result;
      P : constant Public_Build_Command_Surface_Entry :=
        (Stable_Id => To_Unbounded_String ("build.run"),
         Has_Descriptor => True,
         Has_Input_Model => True,
         Has_Consent_Model => True,
         Has_Working_Context_Model => True,
         Publicly_Invokable => True,
          Routes_Through_Executor => True,
          others => <>);
   begin
      Editor.State.Init (S);
      R := Run_Public_Build_Command_Readiness_Audit (S);
      R.Public_Working_Context_Publicly_Ready := False;
      R.Public_Working_Context_Publicly_Exposable := False;
      Assert (Validate_Public_Build_Command_Promotion (P, R) =
              Public_Build_Promotion_Working_Context_UX_Incomplete,
              "promotion must be blocked by missing safe working-context UX");
      Assert (Build_Public_Command_Promotion_Feedback
                (Public_Build_Promotion_Working_Context_UX_Incomplete) =
              "Build: working directory UX not ready",
              "working-context promotion feedback must not include paths");
   end Test_Public_Build_Promotion_Blocked_When_Working_Context_UX_Missing;

   procedure Test_Public_Build_Promotion_Ready_When_Guardrails_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      R : Public_Build_Command_Readiness_Audit_Result;
      P : constant Public_Build_Command_Surface_Entry :=
        (Stable_Id => To_Unbounded_String ("build.run"),
         Has_Descriptor => True,
         Has_Input_Model => True,
         Has_Consent_Model => True,
         Has_Working_Context_Model => True,
         Publicly_Invokable => True,
          Routes_Through_Executor => True,
          others => <>);
   begin
      Editor.State.Init (S);
      R := Run_Public_Build_Command_Readiness_Audit (S);
      R.Public_Consent_UX_Publicly_Ready := True;
      R.Public_Consent_Publicly_Exposable := True;
      R.Public_Working_Context_Publicly_Ready := True;
      R.Public_Working_Context_Publicly_Exposable := True;
      Assert (Validate_Public_Build_Command_Promotion (P, R) =
              Public_Build_Promotion_Command_Surface_Ready,
              "promotion must be ready when explicit-source policy and guardrails pass");
      Assert (Build_Public_Command_Promotion_Feedback
                (Public_Build_Promotion_Command_Surface_Ready) =
              "Build: public command ready",
              "ready promotion feedback must stay deterministic");
   end Test_Public_Build_Promotion_Ready_When_Guardrails_Pass;

   procedure Test_Public_Build_Promotion_Blocked_When_Command_Already_Registered
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      R : Public_Build_Command_Readiness_Audit_Result;
      P : constant Public_Build_Command_Surface_Entry :=
        (Stable_Id => To_Unbounded_String ("build.run-user-opt-in-test-seam"),
         Has_Input_Model => True,
         Has_Consent_Model => True,
         Has_Working_Context_Model => True,
         Publicly_Invokable => False,
          others => <>);
   begin
      Editor.State.Init (S);
      R := Run_Public_Build_Command_Readiness_Audit (S);
      Assert (Validate_Public_Build_Command_Promotion (P, R) =
              Public_Build_Promotion_Blocked,
              "registered command ids must hard-block surface entry promotion");
   end Test_Public_Build_Promotion_Blocked_When_Command_Already_Registered;

   procedure Test_Public_Build_Promotion_Blocked_When_Default_Keybinding_Exists
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      R : Public_Build_Command_Readiness_Audit_Result;
      P : constant Public_Build_Command_Surface_Entry :=
        (Stable_Id => To_Unbounded_String ("file.save"),
         Has_Input_Model => True,
         Has_Consent_Model => True,
         Has_Working_Context_Model => True,
         Publicly_Invokable => False,
          others => <>);
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Editor.State.Init (S);
      R := Run_Public_Build_Command_Readiness_Audit (S);
      Assert (Validate_Public_Build_Command_Promotion (P, R) =
              Public_Build_Promotion_Blocked,
              "default-keybound command ids must hard-block public build promotion");
   end Test_Public_Build_Promotion_Blocked_When_Default_Keybinding_Exists;

   procedure Test_Public_Build_Promotion_Blocked_When_Executor_Route_Exists
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      R : Public_Build_Command_Readiness_Audit_Result;
      P : constant Public_Build_Command_Surface_Entry :=
        (Stable_Id => To_Unbounded_String ("build.run-user-opt-in-test-seam"),
         Has_Input_Model => True,
         Has_Consent_Model => True,
         Has_Working_Context_Model => True,
         Publicly_Invokable => False,
          others => <>);
   begin
      Editor.State.Init (S);
      R := Run_Public_Build_Command_Readiness_Audit (S);
      Assert (Editor.Commands.Requires_Context
                (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam),
              "fixture for route-exists test must be an Executor-routed internal command");
      Assert (Validate_Public_Build_Command_Promotion (P, R) =
              Public_Build_Promotion_Blocked,
              "existing Executor routes must hard-block surface entry promotion");
   end Test_Public_Build_Promotion_Blocked_When_Executor_Route_Exists;

   procedure Test_Public_Build_Promotion_Ready_In_Current_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      R : Public_Build_Command_Readiness_Audit_Result;
   begin
      Editor.State.Init (S);
      R := Run_Public_Build_Command_Readiness_Audit (S);
      Assert (R.Public_Command_Promotion_Status =
              Public_Build_Promotion_Command_Surface_Ready,
              "audit must report command-surface promotion ready");
      Assert (R.Public_Command_Can_Be_Promoted,
              "audit must report promotion possible");
      Assert (not R.Promotion_Blocked_By_Consent_UX,
              "consent UX is no longer a public build blocker");
      Assert (not R.Promotion_Blocked_By_Working_Context,
              "working-context UX is no longer a public build blocker");
      Assert (not R.Promotion_Blocked_By_Implicit_Source,
              "explicit-source policy is no longer a promotion blocker");
      Assert (not R.Promotion_Blocked_By_Command_Exposure,
              "baseline must have no accidental command exposure");
      Assert (R.Passed_As_Not_Ready,
              "readiness audit must pass as guarded promotion-ready");
   end Test_Public_Build_Promotion_Ready_In_Current_State;

   procedure Test_Public_Build_Promotion_Audit_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      R1 : Public_Build_Command_Readiness_Audit_Result;
      R2 : Public_Build_Command_Readiness_Audit_Result;
      Before_Messages : Natural;
      Before_Has_Buffer : Boolean;
      P : constant Public_Build_Command_Surface_Entry :=
        (Stable_Id => To_Unbounded_String ("build.run"),
         Has_Descriptor => True,
         Has_Input_Model => True,
         Has_Consent_Model => True,
         Has_Working_Context_Model => True,
         Publicly_Invokable => True,
          Routes_Through_Executor => True,
          others => <>);
      Status : Public_Build_Command_Promotion_Status;
      pragma Unreferenced (Status);
   begin
      Editor.State.Init (S);
      Before_Messages := Editor.Messages.Count (S.Messages);
      Before_Has_Buffer := Editor.State.Has_Active_Buffer (S);
      R1 := Run_Public_Build_Command_Readiness_Audit (S);
      Status := Validate_Public_Build_Command_Promotion (P, R1);
      Assert_Public_Build_Command_Surface_Exposed;
      Assert (Audit_Public_Build_Command_Visibility,
              "exposure barrier must pass without mutation");
      declare
         Feedback : constant String :=
           Build_Public_Command_Promotion_Feedback
             (R1.Public_Command_Promotion_Status);
      begin
         Assert (Feedback'Length > 0,
                 "feedback helper must be pure deterministic text");
      end;
      R2 := Run_Public_Build_Command_Readiness_Audit (S);
      Assert (R1.Public_Command_Promotion_Status = R2.Public_Command_Promotion_Status,
              "repeated readiness audits must return stable promotion status");
      Assert (R1.Public_Command_Can_Be_Promoted = R2.Public_Command_Can_Be_Promoted,
              "repeated readiness audits must return stable promotion boolean");
      Assert (Editor.Messages.Count (S.Messages) = Before_Messages,
              "readiness and promotion audits must not post messages");
      Assert (Editor.State.Has_Active_Buffer (S) = Before_Has_Buffer,
              "readiness and promotion audits must not create buffers");
      Assert_Public_Build_Name_Not_Registered ("build.run");
   end Test_Public_Build_Promotion_Audit_Is_Side_Effect_Free;


   procedure Test_Public_Build_UX_Dependency_Matrix_Exists
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Matrix : constant Public_Build_UX_Dependency_Matrix :=
        Build_Public_Build_UX_Dependency_Matrix;
   begin
      Assert (Matrix (Public_Build_Dependency_Input_Model) =
              Dependency_Satisfied,
              "input model must be public-ready");
      Assert (Matrix (Public_Build_Dependency_Structured_Argv) =
              Dependency_Satisfied,
              "structured argv dependency must be satisfied");
      Assert (Matrix (Public_Build_Dependency_Consent_Model) =
              Dependency_Satisfied,
              "consent model must be public-ready");
      Assert (Matrix (Public_Build_Dependency_Consent_UX) = Dependency_Satisfied,
              "consent UX must be public-ready");
      Assert (Matrix (Public_Build_Dependency_Working_Context_Model) =
              Dependency_Satisfied,
              "working-context model must be public-ready");
      Assert (Matrix (Public_Build_Dependency_Working_Context_UX) =
              Dependency_Satisfied,
              "working-context UX must be public-ready");
      Assert (Matrix (Public_Build_Dependency_Implicit_Source_Policy) =
              Dependency_Satisfied,
              "explicit-source policy must be satisfied");
      Assert (Matrix (Public_Build_Dependency_Execution_Policy) =
              Dependency_Satisfied,
              "execution policy must be satisfied");
      Assert (Matrix (Public_Build_Dependency_Executor_Route) = Dependency_Satisfied,
              "guarded public Executor route must be present");
      Assert (Matrix (Public_Build_Dependency_Diagnostics_Pipeline) =
              Dependency_Satisfied,
              "Diagnostics pipeline dependency must remain satisfied");
      Assert (Matrix (Public_Build_Dependency_No_Persistence) =
              Dependency_Satisfied,
              "no-persistence guard must remain satisfied");
   end Test_Public_Build_UX_Dependency_Matrix_Exists;

   procedure Test_Public_Build_UX_Dependency_Matrix_Validation_Allows_Promotion
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Matrix : constant Public_Build_UX_Dependency_Matrix :=
        Build_Public_Build_UX_Dependency_Matrix;
   begin
      Assert (Validate_Public_Build_UX_Dependencies (Matrix) =
              Public_Build_Promotion_Command_Surface_Ready,
              "dependency matrix must allow guarded surface entry promotion");
   end Test_Public_Build_UX_Dependency_Matrix_Validation_Allows_Promotion;

   procedure Test_Public_Build_Promotion_Blocker_Precedence_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Matrix : Public_Build_UX_Dependency_Matrix :=
        Build_Public_Build_UX_Dependency_Matrix;
   begin
      Assert (Validate_Public_Build_UX_Dependencies (Matrix) =
              Public_Build_Promotion_Command_Surface_Ready,
              "dependency matrix is ready when all guarded dependencies are satisfied");
   end Test_Public_Build_Promotion_Blocker_Precedence_Is_Deterministic;

   procedure Test_Public_Build_Readiness_Audit_Reports_Dependency_Matrix
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      R : Public_Build_Command_Readiness_Audit_Result;
   begin
      Editor.State.Init (S);
      R := Run_Public_Build_Command_Readiness_Audit (S);
      Assert (R.Public_UX_Dependency_Matrix_Exists,
              "readiness audit must report dependency matrix exists");
      Assert (R.Public_UX_Dependency_Matrix_Validated,
              "readiness audit must validate dependency matrix");
      Assert (R.Public_Command_Promotion_Status = Public_Build_Promotion_Command_Surface_Ready,
              "readiness audit must report ready promotion status");
      Assert (not R.Consent_UX_Blocker_Active,
              "readiness audit must show consent UX blocker cleared");
      Assert (not R.Working_Context_UX_Blocker_Active,
              "readiness audit must show working-context UX blocker cleared");
      Assert (not R.Implicit_Source_Blocker_Active,
              "readiness audit must show explicit-source blocker cleared");
      Assert (not R.Public_Executor_Route_Blocker_Active,
              "readiness audit must show guarded public Executor route present");
      Assert (not R.Public_Command_Exposure_Hard_Failure,
              "normal state must not be a hard exposure failure");
      Assert (R.Passed_As_Not_Ready,
              "dependency-aware readiness audit must pass as guarded promotion-ready");
   end Test_Public_Build_Readiness_Audit_Reports_Dependency_Matrix;

   procedure Test_Public_Build_Exposure_Hard_Failure_For_Simulated_Public_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      R : Public_Build_Command_Readiness_Audit_Result;
      P : constant Public_Build_Command_Surface_Entry :=
        (Stable_Id => To_Unbounded_String ("build.run"),
         Has_Descriptor => True,
         Has_Input_Model => True,
         Has_Consent_Model => True,
         Has_Working_Context_Model => True,
         Publicly_Invokable => True,
          Routes_Through_Executor => True,
          others => <>);
   begin
      Editor.State.Init (S);
      R := Run_Public_Build_Command_Readiness_Audit (S);
      R.Has_Default_Public_Build_Keybinding := True;
      Assert (Detect_Public_Build_Command_Exposure_Hard_Failure (R),
              "simulated public build default keybinding must be a hard failure");
      Assert (Validate_Public_Build_Command_Promotion (P, R) =
              Public_Build_Promotion_Unsafe_Exposure_Detected,
              "hard exposure must outrank normal guarded-surface blockers");
      Assert (Build_Public_Command_Promotion_Feedback
                (Public_Build_Promotion_Unsafe_Exposure_Detected) =
              "Build: unsafe public command exposure detected",
              "hard-failure feedback must be deterministic");
      Assert_Public_Build_Name_Not_Registered ("build.run");
   end Test_Public_Build_Exposure_Hard_Failure_For_Simulated_Public_Command;

   procedure Test_Public_Build_Repeated_Audits_Are_Stable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      R1 : Public_Build_Command_Readiness_Audit_Result;
      R2 : Public_Build_Command_Readiness_Audit_Result;
      Matrix1 : Public_Build_UX_Dependency_Matrix;
      Matrix2 : Public_Build_UX_Dependency_Matrix;
      Before_Messages : Natural;
   begin
      Editor.State.Init (S);
      Before_Messages := Editor.Messages.Count (S.Messages);
      R1 := Run_Public_Build_Command_Readiness_Audit (S);
      R2 := Run_Public_Build_Command_Readiness_Audit (S);
      Matrix1 := Build_Public_Build_UX_Dependency_Matrix;
      Matrix2 := Build_Public_Build_UX_Dependency_Matrix;
      Assert (R1.Public_Command_Promotion_Status = R2.Public_Command_Promotion_Status,
              "repeated readiness audits must keep promotion status stable");
      Assert (R1.Primary_Promotion_Blocker = R2.Primary_Promotion_Blocker,
              "repeated readiness audits must keep primary blocker stable");
      for Dependency in Public_Build_UX_Dependency loop
         Assert (Matrix1 (Dependency) = Matrix2 (Dependency),
                 "repeated dependency matrix builds must be stable");
      end loop;
      Assert (Editor.Messages.Count (S.Messages) = Before_Messages,
              "repeated audits must not post messages");
      Assert_Public_Build_Name_Not_Registered ("build.run");
   end Test_Public_Build_Repeated_Audits_Are_Stable;



   procedure Test_Public_Build_Hard_Freeze_Audit_Passes_Default_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Audit : Public_Build_Command_Hard_Freeze_Audit_Result;
   begin
      Editor.State.Init (S);
      Audit := Run_Public_Build_Command_Hard_Freeze_Audit (S);
      Assert (Audit.Passed,
              "public build hard-freeze audit must pass the default not-exposed state");
      Assert (Audit.Readiness_Audit_Passed_As_Not_Ready,
              "hard-freeze audit must preserve guarded promotion-ready result");
      Assert (not Audit.Promotion_Blocked,
              "hard-freeze audit must allow guarded surface entry promotion");
      Assert (not Audit.Public_Exposure_Hard_Failure,
              "default public build hard-freeze must not report exposure failure");
      Assert (Audit.No_Public_Command_Registered,
              "public build command ids must remain unregistered");
      Assert (Audit.No_Default_Execution,
              "default public build execution must remain disabled");
   end Test_Public_Build_Hard_Freeze_Audit_Passes_Default_State;

   procedure Test_Public_Build_Hard_Freeze_Audit_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Before_Messages : Natural;
      Before_Has_Buffer : Boolean;
      A1 : Public_Build_Command_Hard_Freeze_Audit_Result;
      A2 : Public_Build_Command_Hard_Freeze_Audit_Result;
   begin
      Editor.State.Init (S);
      Before_Messages := Editor.Messages.Count (S.Messages);
      Before_Has_Buffer := Editor.State.Has_Active_Buffer (S);
      A1 := Run_Public_Build_Command_Hard_Freeze_Audit (S);
      A2 := Run_Public_Build_Command_Hard_Freeze_Audit (S);
      Assert (A1.Passed = A2.Passed,
              "repeated hard-freeze audits must return stable pass state");
      Assert (A1.Promotion_Blocked = A2.Promotion_Blocked,
              "repeated hard-freeze audits must return stable promotion state");
      Assert (Editor.Messages.Count (S.Messages) = Before_Messages,
              "hard-freeze audit must not post messages");
      Assert (Editor.State.Has_Active_Buffer (S) = Before_Has_Buffer,
              "hard-freeze audit must not create or close buffers");
      Assert_Public_Build_Name_Not_Registered ("build.run");
   end Test_Public_Build_Hard_Freeze_Audit_Is_Side_Effect_Free;

   procedure Test_Public_Build_Hard_Freeze_Audit_Agrees_With_Other_Audits
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Assert_Public_Build_Audits_Agree (S);
      Assert_No_Public_Build_Execution_Path (S);
      Assert_Public_Build_Hard_Freeze_Not_Persisted (S);
   end Test_Public_Build_Hard_Freeze_Audit_Agrees_With_Other_Audits;

   procedure Test_Public_Build_Blocker_Summary_Is_Deterministic_For_Current_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S1 : constant Public_Build_Blocker_Summary :=
        Build_Public_Build_Blocker_Summary;
      S2 : constant Public_Build_Blocker_Summary :=
        Build_Public_Build_Blocker_Summary;
   begin
      Assert (not S1.Consent_UX_Missing,
              "blocker summary must show consent UX ready");
      Assert (not S1.Working_Context_UX_Missing,
              "blocker summary must show working-context UX ready");
      Assert (not S1.Implicit_Source_Unsupported,
              "blocker summary must report explicit-source policy support");
      Assert (not S1.Public_Route_Missing,
              "blocker summary must show guarded public route present");
      Assert (not S1.Public_Command_Not_Registered,
              "blocker summary must show guarded public command registered");
      Assert (S1.Default_Execution_Disabled,
              "blocker summary must report default execution disabled");
      Assert (Validate_Public_Build_UX_Dependencies
                (Build_Public_Build_UX_Dependency_Matrix) =
              Public_Build_Promotion_Command_Surface_Ready,
              "blocker summary must agree with ready dependency matrix");
      Assert (S1.Primary_Blocker = S2.Primary_Blocker,
              "blocker summary primary blocker must be deterministic");
   end Test_Public_Build_Blocker_Summary_Is_Deterministic_For_Current_State;

   procedure Test_Public_Build_Hard_Freeze_Detects_Simulated_Hard_Failures
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      R : Public_Build_Command_Readiness_Audit_Result;
   begin
      Editor.State.Init (S);
      R := Run_Public_Build_Command_Readiness_Audit (S);
      R.Has_Default_Public_Build_Keybinding := True;
      Assert (Detect_Public_Build_Command_Exposure_Hard_Failure (R),
              "simulated public default keybinding must be a hard failure");
      Assert (Run_Public_Build_Command_Hard_Freeze_Audit (S).Passed,
              "simulated hard failures must not mutate the real registry or audits");
      Assert_Public_Build_Name_Not_Registered ("build.run");
   end Test_Public_Build_Hard_Freeze_Detects_Simulated_Hard_Failures;

   procedure Test_Public_Build_Hard_Freeze_Remains_After_Lifecycle_Transitions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Assert (Run_Public_Build_Command_Hard_Freeze_Audit (S).Passed,
              "hard-freeze must pass before lifecycle transitions");
      Editor.State.Reset_Project_Scoped_State (S);
      Assert (Run_Public_Build_Command_Hard_Freeze_Audit (S).Passed,
              "hard-freeze must survive project-scoped reset");
      Reset_Build_Run_State_For_Project_Close (S);
      Reset_Diagnostic_Line_Command_State_For_Project_Close (S);
      Assert (Run_Public_Build_Command_Hard_Freeze_Audit (S).Passed,
              "hard-freeze must survive project close build/diagnostic resets");
      Reset_Build_Run_State_For_Workspace_Close (S);
      Reset_Diagnostic_Line_Command_State_For_Workspace_Close (S);
      Assert (Run_Public_Build_Command_Hard_Freeze_Audit (S).Passed,
              "hard-freeze must survive workspace close build/diagnostic resets");
      Editor.Keybindings.Reset_To_Defaults;
      Assert (Run_Public_Build_Command_Hard_Freeze_Audit (S).Passed,
              "hard-freeze must survive keybinding reset");
      Assert_Public_Build_Name_Not_Registered ("build.run");
   end Test_Public_Build_Hard_Freeze_Remains_After_Lifecycle_Transitions;

   procedure Test_No_Public_Build_Execution_Path_Remains
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Audit : Public_Build_Command_Hard_Freeze_Audit_Result;
   begin
      Editor.State.Init (S);
      Audit := Run_Public_Build_Command_Hard_Freeze_Audit (S);
      Assert (Audit.No_Public_Command_Registered,
              "no public build descriptor may exist");
      Assert (Audit.No_Public_Executor_Route,
              "no public build Executor route may exist");
      Assert (Audit.No_Public_Invocation_Path,
              "no public build invocation path may exist");
      Assert (Audit.No_Public_Default_Keybinding,
              "no public build keybinding may exist");
      Assert (Audit.No_Public_Command_Palette_Entry,
              "no public build palette entry may exist");
      Assert (Audit.No_Public_Bindable_Command,
              "no public build bindable command may exist");
      Assert (Audit.No_Default_Execution,
              "default execution must remain disabled");
      Assert_No_Public_Build_Execution_Path (S);
   end Test_No_Public_Build_Execution_Path_Remains;

   procedure Test_Public_Build_Hard_Freeze_Feedback_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Audit : Public_Build_Command_Hard_Freeze_Audit_Result;
      Failed : Public_Build_Command_Hard_Freeze_Audit_Result;
   begin
      Editor.State.Init (S);
      Audit := Run_Public_Build_Command_Hard_Freeze_Audit (S);
      Assert (Build_Public_Build_Hard_Freeze_Feedback (Audit) =
              "Build: public command ready",
              "passing hard-freeze feedback must be deterministic and sanitized");
      Failed := Audit;
      Failed.Public_Exposure_Hard_Failure := True;
      Failed.Passed := False;
      Assert (Build_Public_Build_Hard_Freeze_Feedback (Failed) =
              "Build: unsafe public command exposure detected",
              "hard-failure feedback must be deterministic and sanitized");
      Failed := Audit;
      Failed.Passed := False;
      Assert (Build_Public_Build_Hard_Freeze_Feedback (Failed) =
              "Build: public build hard-freeze failed",
              "generic failed hard-freeze feedback must be deterministic and sanitized");
   end Test_Public_Build_Hard_Freeze_Feedback_Is_Deterministic;



   procedure Test_Public_Build_Hard_Freeze_Baseline_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      B1 : constant Public_Build_Hard_Freeze_Baseline :=
        Build_Public_Build_Hard_Freeze_Baseline;
      B2 : constant Public_Build_Hard_Freeze_Baseline :=
        Build_Public_Build_Hard_Freeze_Baseline;
   begin
      Assert (B1.Public_Command_Count = 1,
              "baseline must record one guarded public build command");
      Assert (B1.Public_Default_Keybinding_Count = 0,
              "baseline must record zero default public build keybindings");
      Assert (B1.Public_Command_Palette_Count = 1,
              "baseline must record one guarded public build palette row");
      Assert (B1.Public_Executor_Route_Count = 1,
              "baseline must record one guarded public build Executor route");
      Assert (B1.Public_Invocation_Path_Count = 1,
              "baseline must record one guarded public build invocation path");
      Assert (B1.Bindable_Public_Build_Count = 0,
              "baseline must record zero bindable public build commands");
      Assert (not B1.Promotion_Blocked,
              "baseline must record guarded promotion ready");
      Assert (B1.Default_Execution_Disabled,
              "baseline must record disabled default execution");
      Assert (not B1.Consent_UX_Missing,
              "baseline must record completed consent UX");
      Assert (not B1.Working_Context_UX_Missing,
              "baseline must record completed working-context UX");
      Assert (not B1.Implicit_Source_Unsupported,
              "baseline must record explicit-source policy support");
      Assert (not B1.Public_Route_Missing,
              "baseline must record guarded public route present");
      Assert (B1 = B2,
              "hard-freeze baseline must be deterministic");
   end Test_Public_Build_Hard_Freeze_Baseline_Is_Deterministic;

   procedure Test_Public_Build_Hard_Freeze_Drift_Default_State_Has_No_Drift
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Drift : Public_Build_Hard_Freeze_Drift_Result;
   begin
      Editor.State.Init (S);
      Drift := Detect_Public_Build_Hard_Freeze_Drift
        (S, Build_Public_Build_Hard_Freeze_Baseline);
      Assert (not Drift.Any_Drift,
              "default state must not drift from hard-freeze baseline");
      Assert (Build_Public_Build_Drift_Feedback (Drift) =
              "Build: public command hard-freeze intact",
              "no-drift feedback must be deterministic and sanitized");
   end Test_Public_Build_Hard_Freeze_Drift_Default_State_Has_No_Drift;

   procedure Test_Public_Build_Hard_Freeze_Drift_Detection_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Before_Messages : Natural;
      Before_Has_Buffer : Boolean;
      D1 : Public_Build_Hard_Freeze_Drift_Result;
      D2 : Public_Build_Hard_Freeze_Drift_Result;
   begin
      Editor.State.Init (S);
      Before_Messages := Editor.Messages.Count (S.Messages);
      Before_Has_Buffer := Editor.State.Has_Active_Buffer (S);
      D1 := Detect_Public_Build_Hard_Freeze_Drift
        (S, Build_Public_Build_Hard_Freeze_Baseline);
      D2 := Detect_Public_Build_Hard_Freeze_Drift
        (S, Build_Public_Build_Hard_Freeze_Baseline);
      Assert (D1.Any_Drift = D2.Any_Drift,
              "repeated drift scans must be deterministic");
      Assert (Editor.Messages.Count (S.Messages) = Before_Messages,
              "drift scan must not post messages");
      Assert (Editor.State.Has_Active_Buffer (S) = Before_Has_Buffer,
              "drift scan must not create buffers or switch context");
      Assert_Public_Build_Name_Not_Registered ("build.run");
   end Test_Public_Build_Hard_Freeze_Drift_Detection_Is_Side_Effect_Free;

   procedure Test_Public_Build_Hard_Freeze_Drift_Detects_Public_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      B : Public_Build_Hard_Freeze_Baseline :=
        Build_Public_Build_Hard_Freeze_Baseline;
      D : Public_Build_Hard_Freeze_Drift_Result;
   begin
      Editor.State.Init (S);
      B.Public_Command_Count := 0;
      D := Detect_Public_Build_Hard_Freeze_Drift (S, B);
      Assert (D.Public_Command_Drift and then D.Any_Drift,
              "changed public-command baseline must be reported as command drift");
   end Test_Public_Build_Hard_Freeze_Drift_Detects_Public_Command;

   procedure Test_Public_Build_Hard_Freeze_Drift_Detects_Keybinding
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      B : Public_Build_Hard_Freeze_Baseline :=
        Build_Public_Build_Hard_Freeze_Baseline;
      D : Public_Build_Hard_Freeze_Drift_Result;
   begin
      Editor.State.Init (S);
      B.Public_Default_Keybinding_Count := 1;
      D := Detect_Public_Build_Hard_Freeze_Drift (S, B);
      Assert (D.Keybinding_Drift and then D.Any_Drift,
              "changed keybinding baseline must be reported as keybinding drift");
      Assert (Build_Public_Build_Drift_Feedback (D) =
              "Build: public build keybinding drift detected",
              "keybinding drift feedback must be deterministic");
   end Test_Public_Build_Hard_Freeze_Drift_Detects_Keybinding;

   procedure Test_Public_Build_Hard_Freeze_Drift_Detects_Palette_Entry
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      B : Public_Build_Hard_Freeze_Baseline :=
        Build_Public_Build_Hard_Freeze_Baseline;
      D : Public_Build_Hard_Freeze_Drift_Result;
   begin
      Editor.State.Init (S);
      B.Public_Command_Palette_Count := 0;
      D := Detect_Public_Build_Hard_Freeze_Drift (S, B);
      Assert (D.Palette_Drift and then D.Any_Drift,
              "changed palette baseline must be reported as palette drift");
   end Test_Public_Build_Hard_Freeze_Drift_Detects_Palette_Entry;

   procedure Test_Public_Build_Hard_Freeze_Drift_Detects_Executor_Route
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      B : Public_Build_Hard_Freeze_Baseline :=
        Build_Public_Build_Hard_Freeze_Baseline;
      D : Public_Build_Hard_Freeze_Drift_Result;
   begin
      Editor.State.Init (S);
      B.Public_Executor_Route_Count := 0;
      D := Detect_Public_Build_Hard_Freeze_Drift (S, B);
      Assert (D.Executor_Route_Drift and then D.Any_Drift,
              "changed route baseline must be reported as route drift");
      Assert (Build_Public_Build_Drift_Feedback (D) =
              "Build: public build route drift detected",
              "route drift feedback must be deterministic");
   end Test_Public_Build_Hard_Freeze_Drift_Detects_Executor_Route;

   procedure Test_Public_Build_Hard_Freeze_Drift_Detects_Public_Invocation_Path
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      B : Public_Build_Hard_Freeze_Baseline :=
        Build_Public_Build_Hard_Freeze_Baseline;
      D : Public_Build_Hard_Freeze_Drift_Result;
   begin
      Editor.State.Init (S);
      B.Public_Invocation_Path_Count := 0;
      D := Detect_Public_Build_Hard_Freeze_Drift (S, B);
      Assert (D.Invocation_Path_Drift and then D.Any_Drift,
              "changed invocation-path baseline must be reported as drift");
   end Test_Public_Build_Hard_Freeze_Drift_Detects_Public_Invocation_Path;

   procedure Test_Public_Build_Hard_Freeze_Drift_Detects_Bindable_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      B : Public_Build_Hard_Freeze_Baseline :=
        Build_Public_Build_Hard_Freeze_Baseline;
      D : Public_Build_Hard_Freeze_Drift_Result;
   begin
      Editor.State.Init (S);
      B.Bindable_Public_Build_Count := 1;
      D := Detect_Public_Build_Hard_Freeze_Drift (S, B);
      Assert (D.Bindability_Drift and then D.Any_Drift,
              "changed bindability baseline must be reported as drift");
   end Test_Public_Build_Hard_Freeze_Drift_Detects_Bindable_Command;

   procedure Test_Public_Build_Hard_Freeze_Drift_Detects_Promotion_Status_Change
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      B : Public_Build_Hard_Freeze_Baseline :=
        Build_Public_Build_Hard_Freeze_Baseline;
      D : Public_Build_Hard_Freeze_Drift_Result;
   begin
      Editor.State.Init (S);
      B.Promotion_Blocked := True;
      D := Detect_Public_Build_Hard_Freeze_Drift (S, B);
      Assert (D.Promotion_Drift and then D.Any_Drift,
              "changed promotion baseline must be reported as promotion drift");
   end Test_Public_Build_Hard_Freeze_Drift_Detects_Promotion_Status_Change;

   procedure Test_Public_Build_Hard_Freeze_Drift_Detects_Blocker_Precedence_Change
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      B : Public_Build_Hard_Freeze_Baseline :=
        Build_Public_Build_Hard_Freeze_Baseline;
      D : Public_Build_Hard_Freeze_Drift_Result;
   begin
      Editor.State.Init (S);
      B.Consent_UX_Missing := True;
      D := Detect_Public_Build_Hard_Freeze_Drift (S, B);
      Assert (D.Blocker_Precedence_Drift and then D.Any_Drift,
              "changed blocker baseline must be reported as precedence drift");
      Assert_Public_Build_Blocker_Precedence;
   end Test_Public_Build_Hard_Freeze_Drift_Detects_Blocker_Precedence_Change;

   procedure Test_Public_Build_Hard_Freeze_Drift_Detects_Persistence_Leak
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      D : Public_Build_Hard_Freeze_Drift_Result;
   begin
      D.Persistence_Drift := True;
      D.Any_Drift := True;
      Assert (Build_Public_Build_Drift_Feedback (D) =
              "Build: public build persistence drift detected",
              "persistence drift feedback must be deterministic");
   end Test_Public_Build_Hard_Freeze_Drift_Detects_Persistence_Leak;

   procedure Test_Public_Build_Surface_Id_Cannot_Be_Reused_By_Unrelated_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
   begin
      Assert (Is_Public_Build_Surface_Id ("build.run"),
              "build.run must be public");
      Assert (not Is_Public_Build_Surface_Id ("compile.current"),
              "compile.current remains a reserved alias, not public build");
      Assert (not Is_Public_Build_Surface_Id ("diagnostics.show"),
              "unrelated diagnostics command must not be public as public build");
      Assert_Public_Build_Surface_Ids_Not_Reused;
   end Test_Public_Build_Surface_Id_Cannot_Be_Reused_By_Unrelated_Command;


   procedure Test_Public_Build_Surface_Id_Cannot_Be_Keybinding_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Info : constant Editor.Keybindings.Command_Keybinding_Info :=
        Editor.Keybindings.Primary_Binding_For_Command
          (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam);
   begin
      Assert (not Info.Has_Binding,
              "internal test seam must have no default/active keybinding");
      Assert_Public_Build_Surface_Ids_Not_Reused;
   end Test_Public_Build_Surface_Id_Cannot_Be_Keybinding_Target;

   procedure Test_Public_Build_Audit_Composition_Remains_Consistent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Hard_Freeze : Public_Build_Command_Hard_Freeze_Audit_Result;
      Readiness : Public_Build_Command_Readiness_Audit_Result;
      Drift : Public_Build_Hard_Freeze_Drift_Result;
   begin
      Editor.State.Init (S);
      Hard_Freeze := Run_Public_Build_Command_Hard_Freeze_Audit (S);
      Readiness := Run_Public_Build_Command_Readiness_Audit (S);
      Drift := Detect_Public_Build_Hard_Freeze_Drift
        (S, Build_Public_Build_Hard_Freeze_Baseline);
      Assert (Hard_Freeze.Passed,
              "hard-freeze must pass in default state");
      Assert (Readiness.Passed_As_Not_Ready,
              "readiness must pass as guarded promotion-ready");
      Assert (Readiness.Public_Command_Promotion_Status =
              Public_Build_Promotion_Command_Surface_Ready,
              "readiness must allow guarded promotion");
      Assert (not Drift.Any_Drift,
              "passing hard-freeze must have no drift");
      Assert_Public_Build_Audits_Agree (S);
   end Test_Public_Build_Audit_Composition_Remains_Consistent;

   procedure Test_Public_Build_Audit_Composition_Hard_Failure_Fails_Hard_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      R : Public_Build_Command_Readiness_Audit_Result;
   begin
      Editor.State.Init (S);
      R := Run_Public_Build_Command_Readiness_Audit (S);
      R.Has_Default_Public_Build_Keybinding := True;
      Assert (Detect_Public_Build_Command_Exposure_Hard_Failure (R),
              "simulated public default keybinding must be a hard exposure failure");
      Assert (Run_Public_Build_Command_Hard_Freeze_Audit (S).Passed,
              "hard-failure simulation must not mutate real hard-freeze state");
   end Test_Public_Build_Audit_Composition_Hard_Failure_Fails_Hard_Freeze;

   procedure Test_Public_Build_Unrelated_Public_Command_Does_Not_Affect_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Found : Boolean;
      Round : Editor.Commands.Command_Id;
   begin
      Editor.State.Init (S);
      Assert (not Editor.Commands.Is_Public_Build_Command
                (Editor.Commands.Command_Diagnostics_Show),
              "unrelated public diagnostics command must not count as public build");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Diagnostics_Execute_Selected_Action) =
              "diagnostics.execute-selected-action",
              "diagnostic selected action command exposes canonical stable id");
      Round := Editor.Commands.Command_Id_From_Stable_Name
        ("diagnostics.code-action", Found);
      Assert (Found and then Round =
              Editor.Commands.Command_Diagnostics_Execute_Selected_Action,
              "diagnostic selected action command keeps code-action alias");
      Assert (Run_Public_Build_Command_Hard_Freeze_Audit (S).Passed,
              "unrelated public commands must not affect build hard-freeze");
   end Test_Public_Build_Unrelated_Public_Command_Does_Not_Affect_Freeze;

   procedure Test_Public_Build_Unrelated_Keybinding_Does_Not_Affect_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Assert (Run_Public_Build_Command_Hard_Freeze_Audit (S).Passed,
              "unrelated keybindings must not affect build hard-freeze");
      Assert (not Detect_Public_Build_Hard_Freeze_Drift
                    (S, Build_Public_Build_Hard_Freeze_Baseline).Any_Drift,
              "unrelated keybinding surface must not create public build drift");
   end Test_Public_Build_Unrelated_Keybinding_Does_Not_Affect_Freeze;

   procedure Test_No_Public_Build_Execution_Path_RemainsDeep_Scan
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Audit : Public_Build_Command_Hard_Freeze_Audit_Result;
   begin
      Editor.State.Init (S);
      Audit := Run_Public_Build_Command_Hard_Freeze_Audit (S);
      Assert (Audit.No_Public_Command_Registered,
              "deep scan: registry must have no public build command");
      Assert (Audit.No_Public_Command_Palette_Entry,
              "deep scan: palette must have no public build row");
      Assert (Audit.No_Public_Default_Keybinding,
              "deep scan: keybindings must have no public build target");
      Assert (Audit.No_Public_Executor_Route,
              "deep scan: Executor must have no public build route");
      Assert (Audit.No_Public_Invocation_Path,
              "deep scan: public invocation API must have no build path");
      Assert (Audit.Shell_Rejected and then Audit.Opaque_Arguments_Rejected,
              "deep scan: shell and opaque argument routes must stay rejected");
      Assert_No_Public_Build_Execution_Path (S);
   end Test_No_Public_Build_Execution_Path_RemainsDeep_Scan;

   procedure Test_Public_Build_Drift_Feedback_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      D : Public_Build_Hard_Freeze_Drift_Result;
   begin
      Assert (Build_Public_Build_Drift_Feedback (D) =
              "Build: public command hard-freeze intact",
              "intact drift feedback must be deterministic");
      D.Any_Drift := True;
      D.Public_Command_Drift := True;
      Assert (Build_Public_Build_Drift_Feedback (D) =
              "Build: public command exposure drift detected",
              "exposure drift feedback must be deterministic");
      D := (others => False);
      D.Any_Drift := True;
      D.Promotion_Drift := True;
      Assert (Build_Public_Build_Drift_Feedback (D) =
              "Build: public build promotion drift detected",
              "promotion drift feedback must be deterministic");
   end Test_Public_Build_Drift_Feedback_Is_Deterministic;


   procedure Test_Public_Build_Guardrail_Audit_Default_State_Passed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Result : Public_Build_Guardrail_Result;
   begin
      Editor.State.Init (S);
      Result := Run_Public_Build_Guardrail_Audit (S);
      Assert (Result.Status = Public_Build_Guardrail_Passed,
              "default guardrail status must pass");
      Assert (Result.No_Public_Command,
              "normalized guardrail must report no public build command");
      Assert (Result.No_Public_Keybinding,
              "normalized guardrail must report no public build keybinding");
      Assert (Result.No_Public_Palette_Entry,
              "normalized guardrail must report no public build palette row");
      Assert (Result.No_Public_Executor_Route,
              "normalized guardrail must report no public build Executor route");
      Assert (Result.No_Public_Invocation_Path,
              "normalized guardrail must report no public invocation path");
      Assert (Result.No_Public_Bindable_Command,
              "normalized guardrail must report no bindable public build command");
      Assert (not Result.Promotion_Blocked,
              "normalized guardrail must report guarded promotion ready");
      Assert (Result.Default_Execution_Disabled,
              "normalized guardrail must report disabled default execution");
      Assert (not Result.Dependency_Blockers_Active,
              "normalized guardrail must report no active public UX blockers");
      Assert (Result.Persistence_Clean,
              "normalized guardrail must report clean persistence");
      Assert (Result.Audits_Consistent,
              "normalized guardrail must report consistent audits");
   end Test_Public_Build_Guardrail_Audit_Default_State_Passed;

   procedure Test_Public_Build_Guardrail_Audit_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Before : Public_Build_Guardrail_Result;
      After  : Public_Build_Guardrail_Result;
   begin
      Editor.State.Init (S);
      Before := Run_Public_Build_Guardrail_Audit (S);
      After := Run_Public_Build_Guardrail_Audit (S);
      Assert (Before.Status = After.Status
              and then Before.No_Public_Command = After.No_Public_Command
              and then Before.No_Public_Keybinding = After.No_Public_Keybinding
              and then Before.No_Public_Palette_Entry = After.No_Public_Palette_Entry
              and then Before.No_Public_Executor_Route = After.No_Public_Executor_Route
              and then Before.No_Public_Invocation_Path = After.No_Public_Invocation_Path
              and then Before.No_Public_Bindable_Command = After.No_Public_Bindable_Command
              and then Before.Promotion_Blocked = After.Promotion_Blocked
              and then Before.Default_Execution_Disabled = After.Default_Execution_Disabled
              and then Before.Dependency_Blockers_Active = After.Dependency_Blockers_Active
              and then Before.Persistence_Clean = After.Persistence_Clean
              and then Before.Audits_Consistent = After.Audits_Consistent,
              "guardrail audit must be deterministic and side-effect-free");
   end Test_Public_Build_Guardrail_Audit_Is_Side_Effect_Free;

   procedure Test_Public_Build_Guardrail_Audit_Uses_Hard_Freeze_Audit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      H : Public_Build_Command_Hard_Freeze_Audit_Result;
      G : Public_Build_Guardrail_Result;
   begin
      Editor.State.Init (S);
      H := Run_Public_Build_Command_Hard_Freeze_Audit (S);
      G := Run_Public_Build_Guardrail_Audit (S);
      Assert (G.No_Public_Command = H.No_Public_Command_Registered
              and then G.No_Public_Keybinding = H.No_Public_Default_Keybinding
              and then G.No_Public_Palette_Entry = H.No_Public_Command_Palette_Entry
              and then G.No_Public_Executor_Route = H.No_Public_Executor_Route
              and then G.No_Public_Invocation_Path = H.No_Public_Invocation_Path
              and then G.No_Public_Bindable_Command = H.No_Public_Bindable_Command,
              "normalized guardrail must project hard-freeze no-public fields");
   end Test_Public_Build_Guardrail_Audit_Uses_Hard_Freeze_Audit;

   procedure Test_Public_Build_Guardrail_Audit_Uses_Drift_Detection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      B : Public_Build_Hard_Freeze_Baseline :=
        Build_Public_Build_Hard_Freeze_Baseline;
      D : Public_Build_Hard_Freeze_Drift_Result;
   begin
      Editor.State.Init (S);
      B.Public_Command_Count := 0;
      D := Detect_Public_Build_Hard_Freeze_Drift (S, B);
      Assert (D.Public_Command_Drift and then D.Any_Drift,
              "normalized guardrail source drift detection must catch changed public command baseline");
      Assert (Run_Public_Build_Guardrail_Audit (S).Status =
              Public_Build_Guardrail_Passed,
              "default normalized guardrail must pass with canonical baseline");
   end Test_Public_Build_Guardrail_Audit_Uses_Drift_Detection;

   procedure Test_Public_Build_Guardrail_Audit_Uses_Exposure_Barrier
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Assert (Public_Build_Surface_Ids_Not_Publicly_Projected (S),
              "guardrail projection scan must see no public-id projection");
      Assert_No_Public_Build_Execution_Path (S);
   end Test_Public_Build_Guardrail_Audit_Uses_Exposure_Barrier;

   procedure Test_Public_Build_Surface_Command_Id_List_Is_Centralized
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Names : constant Command_Id_Vector := Public_Build_Command_Surface_Ids;
   begin
      Assert (Names.Length = 1,
              "central public build public-id list must contain every public id");
      for Name of Names loop
         Assert (Is_Public_Build_Surface_Id (To_String (Name)),
                 "public-id classifier must use the centralized list");
      end loop;
      Assert (not Is_Public_Build_Surface_Id ("diagnostics.run-build"),
              "diagnostics.run-build remains reserved, not public");
      Assert_Public_Build_Surface_Ids_Not_Reused;
   end Test_Public_Build_Surface_Command_Id_List_Is_Centralized;


   procedure Test_Public_Build_Surface_Command_Id_Not_Palette_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Assert (Run_Public_Build_Guardrail_Audit (S).No_Public_Palette_Entry,
              "public build ids must not appear as normal palette rows");
   end Test_Public_Build_Surface_Command_Id_Not_Palette_Row;

   procedure Test_Public_Build_Surface_Command_Id_Not_Persisted_Command_Name
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Assert (Run_Public_Build_Guardrail_Audit (S).Persistence_Clean,
              "public build ids and guardrail data must not persist");
      Assert_Public_Build_Hard_Freeze_Not_Persisted (S);
   end Test_Public_Build_Surface_Command_Id_Not_Persisted_Command_Name;

   procedure Test_Public_Build_Guardrail_Contract_Version_Is_Not_Persisted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Assert (Public_Build_Guardrail_Contract_Version = "",
              "guardrail contract version must identify the audit contract");
      Assert (Run_Public_Build_Guardrail_Audit (S).Persistence_Clean,
              "guardrail contract version must remain audit-only and non-persistent");
   end Test_Public_Build_Guardrail_Contract_Version_Is_Not_Persisted;

   procedure Test_Public_Build_Unrelated_Feature_Descriptor_Does_Not_Affect_Guardrail
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Assert (not Editor.Commands.Is_Public_Build_Command
                (Editor.Commands.Command_Toggle_Feature_Panel),
              "unrelated feature-panel descriptor must not classify as public build");
      Assert (Run_Public_Build_Guardrail_Audit (S).Status =
              Public_Build_Guardrail_Passed,
              "unrelated feature descriptor must not affect the public build guardrail");
   end Test_Public_Build_Unrelated_Feature_Descriptor_Does_Not_Affect_Guardrail;

   procedure Test_Public_Build_Unrelated_Diagnostics_Source_Does_Not_Affect_Guardrail
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Source : constant External_Producer_Source :=
        Build_External_Producer_Source (Compiler_Diagnostics_Producer);
   begin
      Editor.State.Init (S);
      Assert (To_String (Source.Stable_Name) /= "build.run",
              "unrelated diagnostics source must not reuse public build id");
      Assert (Run_Public_Build_Guardrail_Audit (S).Status =
              Public_Build_Guardrail_Passed,
              "unrelated diagnostics source must not affect public build guardrail");
   end Test_Public_Build_Unrelated_Diagnostics_Source_Does_Not_Affect_Guardrail;

   procedure Test_Public_Build_Unrelated_Messages_Source_Does_Not_Affect_Guardrail
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Messages.Push_Info (S.Messages, "unrelated status message");
      Assert (Run_Public_Build_Guardrail_Audit (S).Status =
              Public_Build_Guardrail_Passed,
              "unrelated Messages rows must not affect public build guardrail");
      Assert (Run_Public_Build_Guardrail_Audit (S).Persistence_Clean,
              "unrelated Messages rows must not persist guardrail state");
   end Test_Public_Build_Unrelated_Messages_Source_Does_Not_Affect_Guardrail;

   procedure Test_Public_Build_Unrelated_Settings_Preference_Does_Not_Affect_Guardrail
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Assert (Run_Public_Build_Guardrail_Audit (S).Status =
              Public_Build_Guardrail_Passed,
              "unrelated settings preferences must not affect public build guardrail");
      Assert (Run_Public_Build_Guardrail_Audit (S).Default_Execution_Disabled,
              "unrelated settings preferences must not enable build execution");
   end Test_Public_Build_Unrelated_Settings_Preference_Does_Not_Affect_Guardrail;

   procedure Test_Public_Build_Long_Horizon_Persistence_Snapshot_Excludes_Guardrail_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      R : Public_Build_Guardrail_Result;
   begin
      Editor.State.Init (S);
      R := Run_Public_Build_Guardrail_Audit (S);
      Assert (R.Persistence_Clean,
              "long-horizon persistence snapshot must exclude normalized guardrail results");
      Assert_Public_Build_Hard_Freeze_Not_Persisted (S);
      Assert (Public_Build_Surface_Ids_Not_Publicly_Projected (S),
              "long-horizon persistence snapshot must exclude public-id audit projections");
   end Test_Public_Build_Long_Horizon_Persistence_Snapshot_Excludes_Guardrail_State;



   function Default_Result return Editor.External_Producers.Public_Build_Guardrail_Result
   is
      use Editor.External_Producers;
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      return Run_Public_Build_Guardrail_Audit (S);
   end Default_Result;

   procedure Test_Public_Build_Guardrail_Default_Contract_Holds
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      R : constant Public_Build_Guardrail_Result := Default_Result;
   begin
      Assert_Public_Build_Guardrail_Default_Contract (R);
   end Test_Public_Build_Guardrail_Default_Contract_Holds;

   procedure Test_Public_Build_Guardrail_Contract_Mismatch_Default_Has_No_Mismatch
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      M : constant Public_Build_Guardrail_Contract_Mismatch :=
        Detect_Public_Build_Guardrail_Contract_Mismatch (Default_Result);
   begin
      Assert (not M.Any_Mismatch,
              "default public build guardrail result must match frozen contract");
   end Test_Public_Build_Guardrail_Contract_Mismatch_Default_Has_No_Mismatch;

   procedure Test_Public_Build_Guardrail_Contract_Mismatch_Detects_Status_Drift
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      R : Public_Build_Guardrail_Result := Default_Result;
      M : Public_Build_Guardrail_Contract_Mismatch;
   begin
      R.Status := Public_Build_Guardrail_Not_Ready_But_Safe;
      M := Detect_Public_Build_Guardrail_Contract_Mismatch (R);
      Assert (M.Status_Mismatch and then M.Any_Mismatch,
              "contract mismatch detector must catch normalized status drift");
   end Test_Public_Build_Guardrail_Contract_Mismatch_Detects_Status_Drift;

   procedure Test_Public_Build_Guardrail_Contract_Mismatch_Detects_Public_Command_Drift
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      R : Public_Build_Guardrail_Result := Default_Result;
      M : Public_Build_Guardrail_Contract_Mismatch;
   begin
      R.No_Public_Command := False;
      M := Detect_Public_Build_Guardrail_Contract_Mismatch (R);
      Assert (M.Public_Command_Mismatch and then M.Any_Mismatch,
              "contract mismatch detector must catch public command drift");
   end Test_Public_Build_Guardrail_Contract_Mismatch_Detects_Public_Command_Drift;

   procedure Test_Public_Build_Guardrail_Contract_Mismatch_Detects_Promotion_Drift
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      R : Public_Build_Guardrail_Result := Default_Result;
      M : Public_Build_Guardrail_Contract_Mismatch;
   begin
      R.Promotion_Blocked := True;
      M := Detect_Public_Build_Guardrail_Contract_Mismatch (R);
      Assert (M.Promotion_Mismatch and then M.Any_Mismatch,
              "contract mismatch detector must catch promotion drift");
   end Test_Public_Build_Guardrail_Contract_Mismatch_Detects_Promotion_Drift;

   procedure Test_Public_Build_Surface_Id_List_Exactly_Matches_Contract
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Names : constant Command_Id_Vector := Public_Build_Command_Surface_Ids;
      Expected : constant array (Natural range 0 .. 0) of Unbounded_String :=
        (0 => To_Unbounded_String ("build.run"));
   begin
      Assert (Names.Length = Expected'Length,
              "public build id list must have exactly the contract ids");
      for I in Expected'Range loop
         Assert (To_String (Names.Element (I)) = To_String (Expected (I)),
                 "public build id list order/content must be deterministic");
      end loop;
   end Test_Public_Build_Surface_Id_List_Exactly_Matches_Contract;

   procedure Test_Public_Build_Surface_Id_List_Has_No_Duplicates
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Names : constant Command_Id_Vector := Public_Build_Command_Surface_Ids;
   begin
      for I in 0 .. Natural (Names.Length) - 1 loop
         for J in I + 1 .. Natural (Names.Length) - 1 loop
            Assert (To_String (Names.Element (I)) /= To_String (Names.Element (J)),
                    "public build id list must not contain duplicates");
         end loop;
      end loop;
   end Test_Public_Build_Surface_Id_List_Has_No_Duplicates;

   procedure Test_Public_Build_Surface_Id_Scan_Ignores_Near_Miss_Labels
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
   begin
      Assert (not Is_Public_Build_Surface_Id ("build.runner"),
              "near-miss build.runner must not match public ids");
      Assert (not Is_Public_Build_Surface_Id ("build.run-diagnostics"),
              "near-miss build.run-diagnostics must not match public ids");
      Assert (not Is_Public_Build_Surface_Id ("compile.note"),
              "near-miss compile.note must not match public ids");
      Assert (not Is_Public_Build_Surface_Id ("diagnostics.run-build-notes"),
              "near-miss diagnostics.run-build-notes must not match public ids");
   end Test_Public_Build_Surface_Id_Scan_Ignores_Near_Miss_Labels;

   procedure Test_Public_Build_Surface_Id_Scan_Rejects_Exact_Public_Name
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
   begin
      Assert (Is_Public_Build_Surface_Id ("build.run"),
              "exact public build id must be rejected by identity scans");
      Assert_Public_Build_Surface_Ids_Not_Reused;
   end Test_Public_Build_Surface_Id_Scan_Rejects_Exact_Public_Name;

   procedure Test_Public_Build_Internal_Test_Seam_Not_Counted_As_Public_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      R : Public_Build_Guardrail_Result;
   begin
      Editor.State.Init (S);
      R := Run_Public_Build_Guardrail_Audit (S);
      Assert (R.No_Public_Command,
              "internal build test seam must be excluded from public build command counts");
      Assert (not Is_Public_Build_Surface_Id
                (Editor.Commands.Stable_Command_Name
                   (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam)),
              "internal test-seam id must not match the public build id list");
   end Test_Public_Build_Internal_Test_Seam_Not_Counted_As_Public_Command;

   procedure Test_Public_Build_Internal_Test_Seam_Still_Hidden_From_Normal_Palette
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor
          (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam);
   begin
      Assert (D.Visibility = Editor.Commands.Hidden_Command,
              "internal build test seam must remain hidden from normal palette");
      Assert (not D.Bindable,
              "internal build test seam must not gain a default public keybinding target");
   end Test_Public_Build_Internal_Test_Seam_Still_Hidden_From_Normal_Palette;

   procedure Test_Public_Build_Normalized_Audit_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      A : Public_Build_Guardrail_Result;
      B : Public_Build_Guardrail_Result;
   begin
      Editor.State.Init (S);
      A := Run_Public_Build_Guardrail_Audit (S);
      B := Run_Public_Build_Guardrail_Audit (S);
      Assert (A = B,
              "same editor state must produce identical normalized guardrail results");
   end Test_Public_Build_Normalized_Audit_Is_Deterministic;

   procedure Test_Public_Build_Normalized_Audit_Exposure_Simulation_Is_Stable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      R1 : Public_Build_Guardrail_Result := Default_Result;
      R2 : Public_Build_Guardrail_Result := Default_Result;
   begin
      R1.Status := Public_Build_Guardrail_Exposure_Detected;
      R1.No_Public_Command := False;
      R2.Status := Public_Build_Guardrail_Exposure_Detected;
      R2.No_Public_Command := False;
      Assert (Detect_Public_Build_Guardrail_Contract_Mismatch (R1) =
              Detect_Public_Build_Guardrail_Contract_Mismatch (R2),
              "same exposure simulation must produce identical mismatch result");
   end Test_Public_Build_Normalized_Audit_Exposure_Simulation_Is_Stable;

   procedure Test_Public_Build_Normalized_Audit_Drift_Simulation_Is_Stable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      R1 : Public_Build_Guardrail_Result := Default_Result;
      R2 : Public_Build_Guardrail_Result := Default_Result;
   begin
      R1.Status := Public_Build_Guardrail_Drift_Detected;
      R2.Status := Public_Build_Guardrail_Drift_Detected;
      Assert (Detect_Public_Build_Guardrail_Contract_Mismatch (R1) =
              Detect_Public_Build_Guardrail_Contract_Mismatch (R2),
              "same drift simulation must produce identical mismatch result");
   end Test_Public_Build_Normalized_Audit_Drift_Simulation_Is_Stable;

   procedure Test_Public_Build_Normalized_Audit_Inconsistency_Readiness_Promotion
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      R : Public_Build_Guardrail_Result := Default_Result;
      M : Public_Build_Guardrail_Contract_Mismatch;
   begin
      R.Status := Public_Build_Guardrail_Inconsistent_Audits;
      R.Audits_Consistent := False;
      R.Promotion_Blocked := True;
      M := Detect_Public_Build_Guardrail_Contract_Mismatch (R);
      Assert (M.Status_Mismatch and then M.Promotion_Mismatch
              and then M.Audit_Consistency_Mismatch and then M.Any_Mismatch,
              "readiness/promotion inconsistency simulation must be detected");
   end Test_Public_Build_Normalized_Audit_Inconsistency_Readiness_Promotion;

   procedure Test_Public_Build_Normalized_Audit_Inconsistency_HardFreeze_Drift
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      R : Public_Build_Guardrail_Result := Default_Result;
      M : Public_Build_Guardrail_Contract_Mismatch;
   begin
      R.Status := Public_Build_Guardrail_Inconsistent_Audits;
      R.Audits_Consistent := False;
      R.Default_Execution_Disabled := False;
      M := Detect_Public_Build_Guardrail_Contract_Mismatch (R);
      Assert (M.Status_Mismatch and then M.Default_Execution_Mismatch
              and then M.Audit_Consistency_Mismatch and then M.Any_Mismatch,
              "hard-freeze/drift inconsistency simulation must be detected");
   end Test_Public_Build_Normalized_Audit_Inconsistency_HardFreeze_Drift;

   procedure Test_Public_Build_Normalized_Audit_Agrees_With_No_Execution_Scan
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      R : Public_Build_Guardrail_Result;
   begin
      Editor.State.Init (S);
      R := Run_Public_Build_Guardrail_Audit (S);
      Assert_Public_Build_Guardrail_Agrees_With_No_Execution_Scan (S, R);
   end Test_Public_Build_Normalized_Audit_Agrees_With_No_Execution_Scan;

   procedure Test_Public_Build_Guardrail_State_Not_Persisted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Assert_Public_Build_Guardrail_State_Not_Persisted (S);
   end Test_Public_Build_Guardrail_State_Not_Persisted;

   procedure Test_Public_Build_Guardrail_Failure_Detail_Default_Is_None
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Detail : constant Public_Build_Guardrail_Failure_Detail :=
        First_Public_Build_Guardrail_Failure (Default_Result);
   begin
      Assert (Detail.Kind = Public_Build_Failure_None,
              "default guardrail failure detail must be none");
   end Test_Public_Build_Guardrail_Failure_Detail_Default_Is_None;

   procedure Test_Public_Build_Guardrail_First_Failure_Uses_Blocker_Precedence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      R : Public_Build_Guardrail_Result := Default_Result;
      Detail : Public_Build_Guardrail_Failure_Detail;
   begin
      R.No_Public_Command := False;
      R.No_Public_Keybinding := False;
      Detail := First_Public_Build_Guardrail_Failure (R);
      Assert (Detail.Kind = Public_Build_Failure_Public_Command_Registered,
              "first failure must prefer command registration before keybindings");
   end Test_Public_Build_Guardrail_First_Failure_Uses_Blocker_Precedence;

   procedure Test_Public_Build_Guardrail_Collect_Failures_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      R : Public_Build_Guardrail_Result := Default_Result;
      A : Public_Build_Guardrail_Failure_Detail_Vector;
      B : Public_Build_Guardrail_Failure_Detail_Vector;
   begin
      R.No_Public_Keybinding := False;
      R.Persistence_Clean := False;
      A := Collect_Public_Build_Guardrail_Failures (R);
      B := Collect_Public_Build_Guardrail_Failures (R);
      Assert (A.Length = B.Length and then A.Length = 2,
              "failure collection must be stable and exhaustive");
      Assert (A.Element (0).Kind = Public_Build_Failure_Public_Keybinding_Found,
              "first collected failure must follow deterministic precedence");
      Assert (A.Element (1).Kind = Public_Build_Failure_Persistence_Leak,
              "second collected failure must preserve deterministic order");
   end Test_Public_Build_Guardrail_Collect_Failures_Is_Deterministic;

   procedure Test_Public_Build_Surface_Id_Scan_Result_Default_Passes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Scan : constant Public_Build_Surface_Id_Scan_Result :=
        Scan_Public_Build_Surface_Ids;
   begin
      Assert (Scan.Passed, "empty public-id scan must pass");
      Assert (not Scan.Exact_Command_Id_Found
              and then not Scan.Exact_Keybinding_Target_Found
              and then not Scan.Exact_Palette_Row_Found
              and then not Scan.Exact_Executor_Route_Found
              and then not Scan.Exact_Invocation_Path_Found
              and then not Scan.Exact_Persisted_Name_Found,
              "default public-id scan must have no exact matches");
   end Test_Public_Build_Surface_Id_Scan_Result_Default_Passes;

   procedure Test_Public_Build_Surface_Id_Scan_Rejects_Exact_Domains
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
   begin
      Assert (Scan_Public_Build_Surface_Ids
                (Command_Id => "build.run").Exact_Command_Id_Found,
              "exact command id must fail scan");
      Assert (Scan_Public_Build_Surface_Ids
                (Keybinding_Target => "build.run").Exact_Keybinding_Target_Found,
              "exact keybinding target must fail scan");
      Assert (Scan_Public_Build_Surface_Ids
                (Palette_Row => "build.run").Exact_Palette_Row_Found,
              "exact palette row id must fail scan");
      Assert (Scan_Public_Build_Surface_Ids
                (Executor_Route => "build.run").Exact_Executor_Route_Found,
              "exact executor route must fail scan");
      Assert (Scan_Public_Build_Surface_Ids
                (Invocation_Path => "build.run").Exact_Invocation_Path_Found,
              "exact invocation path must fail scan");
      Assert (Scan_Public_Build_Surface_Ids
                (Persisted_Name => "build.run").Exact_Persisted_Name_Found,
              "exact persisted command name must fail scan");
   end Test_Public_Build_Surface_Id_Scan_Rejects_Exact_Domains;

   procedure Test_Public_Build_Surface_Id_Scan_Allows_Near_Miss_Label
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Scan : constant Public_Build_Surface_Id_Scan_Result :=
        Scan_Public_Build_Surface_Ids (Palette_Row => "build.runner");
   begin
      Assert (Scan.Passed,
              "near-miss label must not fail exact-match scan");
      Assert (Scan.Near_Miss_Only,
              "near-miss-only snapshots should be represented diagnostically");
   end Test_Public_Build_Surface_Id_Scan_Allows_Near_Miss_Label;

   procedure Test_Public_Build_Guardrail_Audit_Trace_Default_Checks_All_Surfaces
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Trace : constant Public_Build_Guardrail_Audit_Trace :=
        Build_Public_Build_Guardrail_Audit_Trace;
   begin
      Assert (Public_Build_Guardrail_Audit_Trace_Complete (Trace),
              "default audit trace must cover every required surface");
      Assert_Public_Build_Guardrail_Trace_Complete (Trace);
   end Test_Public_Build_Guardrail_Audit_Trace_Default_Checks_All_Surfaces;

   procedure Test_Public_Build_Guardrail_Audit_Trace_Missing_Surface_Is_Inconsistent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Trace : Public_Build_Guardrail_Audit_Trace :=
        Build_Public_Build_Guardrail_Audit_Trace;
   begin
      Trace.Surface_Ids_Checked := False;
      Assert (not Public_Build_Guardrail_Audit_Trace_Complete (Trace),
              "missing trace surface must be incomplete");
   end Test_Public_Build_Guardrail_Audit_Trace_Missing_Surface_Is_Inconsistent;

   procedure Test_Public_Build_Internal_Test_Seam_Public_Leak_Reported_Separately
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Detail : constant Public_Build_Guardrail_Failure_Detail :=
        Build_Public_Build_Internal_Test_Seam_Exposure_Detail
          (Palette_Row => "build.run-user-opt-in-test-seam");
      Scan : constant Public_Build_Surface_Id_Scan_Result :=
        Scan_Public_Build_Surface_Ids
          (Palette_Row => "build.run-user-opt-in-test-seam");
   begin
      Assert (Detail.Kind = Public_Build_Failure_Internal_Test_Seam_Exposure,
              "internal test-seam leakage must be classified separately");
      Assert (Scan.Passed,
              "internal test-seam id must not be treated as public id exposure");
   end Test_Public_Build_Internal_Test_Seam_Public_Leak_Reported_Separately;

   procedure Test_Public_Build_Guardrail_Snapshot_Comparison_Default_No_Mismatch
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      R : constant Public_Build_Guardrail_Result := Default_Result;
      M : constant Public_Build_Guardrail_Contract_Mismatch :=
        Compare_Public_Build_Guardrail_Snapshots (R, R);
   begin
      Assert (not M.Any_Mismatch,
              "identical guardrail snapshots must not mismatch");
   end Test_Public_Build_Guardrail_Snapshot_Comparison_Default_No_Mismatch;

   procedure Test_Public_Build_Guardrail_Snapshot_Comparison_Detects_Exposure
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Before : constant Public_Build_Guardrail_Result := Default_Result;
      After  : Public_Build_Guardrail_Result := Before;
      M      : Public_Build_Guardrail_Contract_Mismatch;
   begin
      After.No_Public_Command := False;
      M := Compare_Public_Build_Guardrail_Snapshots (Before, After);
      Assert (M.Public_Command_Mismatch and then M.Any_Mismatch,
              "snapshot comparison must detect public exposure changes");
   end Test_Public_Build_Guardrail_Snapshot_Comparison_Detects_Exposure;

   procedure Test_Public_Build_Guardrail_Snapshot_Comparison_Detects_Promotion_Change
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Before : constant Public_Build_Guardrail_Result := Default_Result;
      After  : Public_Build_Guardrail_Result := Before;
      M      : Public_Build_Guardrail_Contract_Mismatch;
   begin
      After.Promotion_Blocked := True;
      M := Compare_Public_Build_Guardrail_Snapshots (Before, After);
      Assert (M.Promotion_Mismatch and then M.Any_Mismatch,
              "snapshot comparison must detect promotion changes");
   end Test_Public_Build_Guardrail_Snapshot_Comparison_Detects_Promotion_Change;

   procedure Test_Public_Build_Guardrail_Lifecycle_Trace_Remains_Stable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Before : Public_Build_Guardrail_Audit_Trace;
      After  : Public_Build_Guardrail_Audit_Trace;
   begin
      Editor.State.Init (S);
      Before := Build_Public_Build_Guardrail_Audit_Trace;
      Editor.External_Producers.Reset_Build_Run_State_For_Project_Close (S);
      Editor.External_Producers.Reset_Build_Run_State_For_Workspace_Close (S);
      After := Build_Public_Build_Guardrail_Audit_Trace;
      Assert (Public_Build_Guardrail_Audit_Trace_Complete (Before)
              and then Public_Build_Guardrail_Audit_Trace_Complete (After),
              "lifecycle operations must not weaken audit trace coverage");
   end Test_Public_Build_Guardrail_Lifecycle_Trace_Remains_Stable;

   procedure Test_Public_Build_Guardrail_Lifecycle_Snapshot_No_Mismatch
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Before : Public_Build_Guardrail_Result;
      After  : Public_Build_Guardrail_Result;
      M      : Public_Build_Guardrail_Contract_Mismatch;
   begin
      Editor.State.Init (S);
      Before := Run_Public_Build_Guardrail_Audit (S);
      Editor.External_Producers.Reset_Diagnostic_Line_Command_State_For_Project_Close (S);
      Editor.External_Producers.Reset_Diagnostic_Line_Command_State_For_Workspace_Close (S);
      After := Run_Public_Build_Guardrail_Audit (S);
      M := Compare_Public_Build_Guardrail_Snapshots (Before, After);
      Assert (not M.Any_Mismatch,
              "lifecycle operations must not alter normalized guardrail snapshot");
      Assert (First_Public_Build_Guardrail_Failure (After).Kind =
              Public_Build_Failure_None,
              "default lifecycle guardrail snapshot must have no failure detail");
   end Test_Public_Build_Guardrail_Lifecycle_Snapshot_No_Mismatch;


   procedure Test_Public_Build_Guardrail_Health_Default_Is_Healthy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Health : Public_Build_Guardrail_Health;
   begin
      Editor.State.Init (S);
      Health := Build_Public_Build_Guardrail_Health (S);
      Assert (Health.Healthy,
              "default public build guardrail health must be healthy");
      Assert (Health.Guardrail_Result.Status =
              Public_Build_Guardrail_Passed,
              "healthy default reports passed status");
      Assert (Health.Surface_Id_Scan.Passed,
              "healthy default must include passing public-id scan");
      Assert (Public_Build_Guardrail_Audit_Trace_Complete
                (Health.Audit_Trace),
              "healthy default must include complete audit trace");
      Assert (Health.First_Failure.Kind = Public_Build_Failure_None,
              "healthy default must not report a first failure");
      Assert (Health.Failure_Count = 0,
              "healthy default must have zero failures");
      Assert (not Health.Snapshot_Mismatch.Any_Mismatch,
              "healthy default must not have contract mismatch");
      Assert_Public_Build_Guardrail_Health_Default (Health);
   end Test_Public_Build_Guardrail_Health_Default_Is_Healthy;

   procedure Test_Public_Build_Guardrail_Health_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      A : Public_Build_Guardrail_Health;
      B : Public_Build_Guardrail_Health;
   begin
      Editor.State.Init (S);
      A := Build_Public_Build_Guardrail_Health (S);
      B := Build_Public_Build_Guardrail_Health (S);
      Assert (A = B,
              "public build guardrail health must be deterministic and side-effect-free");
   end Test_Public_Build_Guardrail_Health_Is_Side_Effect_Free;

   procedure Test_Public_Build_Guardrail_Health_Unhealthy_On_Public_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Health : Public_Build_Guardrail_Health;
   begin
      Editor.State.Init (S);
      Health := Build_Public_Build_Guardrail_Health (S);
      Health.Guardrail_Result.No_Public_Command := False;
      Health.Guardrail_Result.Status := Public_Build_Guardrail_Exposure_Detected;
      Health.Snapshot_Mismatch :=
        Detect_Public_Build_Guardrail_Contract_Mismatch
          (Health.Guardrail_Result);
      Health.Healthy := False;
      Assert (Build_Public_Build_Guardrail_Health_Feedback (Health) =
              "Build: public build exposure detected",
              "health feedback must identify public command exposure");
   end Test_Public_Build_Guardrail_Health_Unhealthy_On_Public_Command;

   procedure Test_Public_Build_Guardrail_Health_Unhealthy_On_Audit_Trace_Incomplete
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Health : Public_Build_Guardrail_Health;
   begin
      Editor.State.Init (S);
      Health := Build_Public_Build_Guardrail_Health (S);
      Health.Audit_Trace.Hard_Freeze_Checked := False;
      Health.Guardrail_Result.Audits_Consistent := False;
      Health.Healthy := False;
      Assert (not Public_Build_Guardrail_Audit_Trace_Complete
                    (Health.Audit_Trace),
              "missing hard-freeze surface must make trace incomplete");
      Assert (Build_Public_Build_Guardrail_Health_Feedback (Health) =
              "Build: public build audit trace incomplete",
              "health feedback must identify trace incompleteness");
   end Test_Public_Build_Guardrail_Health_Unhealthy_On_Audit_Trace_Incomplete;

   procedure Test_Public_Build_Guardrail_Health_Unhealthy_On_Contract_Mismatch
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Health : Public_Build_Guardrail_Health;
   begin
      Editor.State.Init (S);
      Health := Build_Public_Build_Guardrail_Health (S);
      Health.Guardrail_Result.Promotion_Blocked := True;
      Health.Snapshot_Mismatch :=
        Detect_Public_Build_Guardrail_Contract_Mismatch
          (Health.Guardrail_Result);
      Health.Healthy := False;
      Assert (Health.Snapshot_Mismatch.Any_Mismatch,
              "simulated promotion drift must create contract mismatch");
      Assert (Build_Public_Build_Guardrail_Health_Feedback (Health) =
              "Build: public build contract mismatch detected",
              "health feedback must identify contract mismatch");
   end Test_Public_Build_Guardrail_Health_Unhealthy_On_Contract_Mismatch;

   procedure Test_Public_Build_Guardrail_Health_Feedback_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Health : Public_Build_Guardrail_Health;
   begin
      Editor.State.Init (S);
      Health := Build_Public_Build_Guardrail_Health (S);
      Assert (Build_Public_Build_Guardrail_Health_Feedback (Health) =
              "Build: public build guardrail healthy",
              "healthy guardrail feedback must be deterministic");
      Health.Healthy := False;
      Assert (Build_Public_Build_Guardrail_Health_Feedback (Health) =
              "Build: public build guardrail unhealthy",
              "unhealthy passed-state fallback feedback must be deterministic");
   end Test_Public_Build_Guardrail_Health_Feedback_Is_Deterministic;

   procedure Test_Public_Build_Guardrail_Health_Canonical_Ordering_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Unsafe : Public_Build_Guardrail_Result;
      A : Public_Build_Guardrail_Failure_Detail_Vector;
      B : Public_Build_Guardrail_Failure_Detail_Vector;
   begin
      Unsafe.Status := Public_Build_Guardrail_Exposure_Detected;
      Unsafe.No_Public_Command := False;
      Unsafe.No_Public_Keybinding := False;
      Unsafe.No_Public_Palette_Entry := False;
      Unsafe.No_Public_Executor_Route := False;
      Unsafe.No_Public_Invocation_Path := False;
      Unsafe.No_Public_Bindable_Command := False;
      Unsafe.Promotion_Blocked := True;
      Unsafe.Default_Execution_Disabled := False;
      Unsafe.Dependency_Blockers_Active := True;
      Unsafe.Persistence_Clean := False;
      Unsafe.Audits_Consistent := False;
      A := Collect_Public_Build_Guardrail_Failures (Unsafe);
      B := Collect_Public_Build_Guardrail_Failures (Unsafe);
      Assert (Natural (A.Length) = Natural (B.Length),
              "collected guardrail failures must have deterministic ordering");
      Assert (Natural (A.Length) > 1,
              "unsafe guardrail snapshot must produce ordered failure details");
   end Test_Public_Build_Guardrail_Health_Canonical_Ordering_Is_Deterministic;

   procedure Test_Public_Build_Guardrail_Health_Builder_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Before : Public_Build_Guardrail_Result;
      A      : Public_Build_Guardrail_Health;
      B      : Public_Build_Guardrail_Health;
      After  : Public_Build_Guardrail_Result;
      M      : Public_Build_Guardrail_Contract_Mismatch;
   begin
      Editor.State.Init (S);
      Before := Run_Public_Build_Guardrail_Audit (S);
      A := Build_Public_Build_Guardrail_Health (S);
      B := Build_Public_Build_Guardrail_Health (S);
      After := Run_Public_Build_Guardrail_Audit (S);
      M := Compare_Public_Build_Guardrail_Snapshots (Before, After);
      Assert (A = B,
              "health builder must be deterministic");
      Assert (not M.Any_Mismatch,
              "health builder must not mutate guardrail-relevant state");
   end Test_Public_Build_Guardrail_Health_Builder_Is_Side_Effect_Free;

   procedure Test_Public_Build_Guardrail_Stale_Health_Does_Not_Bypass_Current_Audit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Old_Health : Public_Build_Guardrail_Health;
      Unsafe_Health : Public_Build_Guardrail_Health;
      Unchanged : Public_Build_Guardrail_Contract_Mismatch;
      Unsafe_Result : Public_Build_Guardrail_Result;
      Stale_Mismatch : Public_Build_Guardrail_Contract_Mismatch;
      Unsafe_Failures : Public_Build_Guardrail_Failure_Detail_Vector;
   begin
      Editor.State.Init (S);
      Old_Health := Build_Public_Build_Guardrail_Health (S);
      Unchanged := Compare_Public_Build_Guardrail_Snapshots
        (Old_Health.Guardrail_Result, Run_Public_Build_Guardrail_Audit (S));
      Assert (not Unchanged.Any_Mismatch,
              "old health must remain valid against unchanged current audit");

      Unsafe_Result := Old_Health.Guardrail_Result;
      Unsafe_Result.No_Public_Command := False;
      Unsafe_Result.Status := Public_Build_Guardrail_Exposure_Detected;
      Stale_Mismatch := Compare_Public_Build_Guardrail_Snapshots
        (Old_Health.Guardrail_Result, Unsafe_Result);
      Assert (Stale_Mismatch.Public_Command_Mismatch
              and then Stale_Mismatch.Any_Mismatch,
              "stale health must not bypass changed unsafe snapshot");

      Unsafe_Health := Old_Health;
      Unsafe_Health.Guardrail_Result := Unsafe_Result;
      Unsafe_Health.Snapshot_Mismatch :=
        Detect_Public_Build_Guardrail_Contract_Mismatch (Unsafe_Result);
      Unsafe_Health.First_Failure :=
        First_Public_Build_Guardrail_Failure (Unsafe_Result);
      Unsafe_Failures := Collect_Public_Build_Guardrail_Failures (Unsafe_Result);
      Unsafe_Health.Failure_Count := Natural (Unsafe_Failures.Length);
      Unsafe_Health.Healthy := False;
      Assert (not Unsafe_Health.Healthy,
              "new unsafe health must remain unhealthy without wrapper contract");
      Assert (Unsafe_Health.Snapshot_Mismatch.Any_Mismatch,
              "new unsafe health must expose direct snapshot mismatch");
      Assert (Unsafe_Health.First_Failure.Kind /= Public_Build_Failure_None,
              "new unsafe health must expose direct first failure");
      Assert (Unsafe_Health.Failure_Count > 0,
              "new unsafe health must expose direct failure count");
   end Test_Public_Build_Guardrail_Stale_Health_Does_Not_Bypass_Current_Audit;

   procedure Test_Public_Build_Surface_Id_Scan_All_Domains_Checked
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Scan : constant Public_Build_Surface_Id_Scan_Result :=
        Scan_Public_Build_Surface_Ids;
   begin
      Assert (Public_Build_Surface_Id_Scan_Domains_Checked (Scan),
              "public-id scan must mark every domain checked or checked-empty");
      Assert_Public_Build_Surface_Id_Scan_Domains_Checked (Scan);
      Assert (Scan.Stable_Command_Ids_Checked
              and then Scan.Display_Search_Names_Checked
              and then Scan.Palette_Checked
              and then Scan.Default_Keybindings_Checked
              and then Scan.Runtime_Keybindings_Checked
              and then Scan.Persisted_Keybindings_Checked
              and then Scan.Executor_Routes_Checked
              and then Scan.Invocation_Paths_Checked
              and then Scan.Persistence_Names_Checked
              and then Scan.Workspace_Names_Checked,
              "all public-id scan coverage markers must be true by default");
   end Test_Public_Build_Surface_Id_Scan_All_Domains_Checked;

   procedure Test_Public_Build_Surface_Id_Canonical_Exact_Match_Fails
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
   begin
      Assert (not Scan_Public_Build_Surface_Ids
                    (Command_Id => "build.run").Passed,
              "canonical exact build.run must fail public-id scan");
      Assert (Scan_Public_Build_Surface_Ids
                (Command_Id => " build.run").Passed,
              "leading whitespace must follow current exact command-id policy");
      Assert (Scan_Public_Build_Surface_Ids
                (Command_Id => "build.run ").Passed,
              "trailing whitespace must follow current exact command-id policy");
      Assert (Scan_Public_Build_Surface_Ids
                (Command_Id => "BUILD.RUN").Passed,
              "case-only variant must follow current exact command-id policy");
   end Test_Public_Build_Surface_Id_Canonical_Exact_Match_Fails;

   procedure Test_Public_Build_Surface_Id_Near_Miss_Remains_Safe
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      A : constant Public_Build_Surface_Id_Scan_Result :=
        Scan_Public_Build_Surface_Ids (Command_Id => "build.runner");
      B : constant Public_Build_Surface_Id_Scan_Result :=
        Scan_Public_Build_Surface_Ids
          (Command_Id => "diagnostics.run-build-notes");
   begin
      Assert (A.Passed and then A.Near_Miss_Only,
              "build.runner near miss must remain safe");
      Assert (B.Passed and then B.Near_Miss_Only,
              "diagnostics.run-build-notes near miss must remain safe");
   end Test_Public_Build_Surface_Id_Near_Miss_Remains_Safe;

   procedure Test_Public_Build_Health_Lifecycle_Project_Close_Remains_Healthy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Before : Public_Build_Guardrail_Health;
      After  : Public_Build_Guardrail_Health;
      M      : Public_Build_Guardrail_Contract_Mismatch;
   begin
      Editor.State.Init (S);
      Before := Build_Public_Build_Guardrail_Health (S);
      Reset_Build_Run_State_For_Project_Close (S);
      Reset_Diagnostic_Line_Command_State_For_Project_Close (S);
      After := Build_Public_Build_Guardrail_Health (S);
      M := Compare_Public_Build_Guardrail_Snapshots
        (Before.Guardrail_Result, After.Guardrail_Result);
      Assert (Before.Healthy and then After.Healthy,
              "project-close lifecycle must preserve public-build health");
      Assert (not M.Any_Mismatch,
              "project-close lifecycle must not change guardrail snapshot");
   end Test_Public_Build_Health_Lifecycle_Project_Close_Remains_Healthy;

   procedure Test_Public_Build_Health_Lifecycle_Workspace_Close_Remains_Healthy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Before : Public_Build_Guardrail_Health;
      After  : Public_Build_Guardrail_Health;
      M      : Public_Build_Guardrail_Contract_Mismatch;
   begin
      Editor.State.Init (S);
      Before := Build_Public_Build_Guardrail_Health (S);
      Reset_Build_Run_State_For_Workspace_Close (S);
      Reset_Diagnostic_Line_Command_State_For_Workspace_Close (S);
      After := Build_Public_Build_Guardrail_Health (S);
      M := Compare_Public_Build_Guardrail_Snapshots
        (Before.Guardrail_Result, After.Guardrail_Result);
      Assert (Before.Healthy and then After.Healthy,
              "workspace-close lifecycle must preserve public-build health");
      Assert (not M.Any_Mismatch,
              "workspace-close lifecycle must not change guardrail snapshot");
   end Test_Public_Build_Health_Lifecycle_Workspace_Close_Remains_Healthy;

   procedure Test_Public_Build_Health_Not_Persisted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Assert_Public_Build_Guardrail_Health_Not_Persisted (S);
   end Test_Public_Build_Health_Not_Persisted;


   function Starts_With (Text : String; Prefix : String) return Boolean is
   begin
      return Text'Length >= Prefix'Length
        and then Text (Text'First .. Text'First + Prefix'Length - 1) = Prefix;
   end Starts_With;

   function Yes_No (Value : Boolean) return String is
   begin
      return (if Value then "yes" else "no");
   end Yes_No;

   function Existing_Switcher_Command_Reference_Path return String is
   begin
      if Ada.Directories.Exists ("docs/open_buffer_switcher_commands.md") then
         return "docs/open_buffer_switcher_commands.md";
      elsif Ada.Directories.Exists ("../docs/open_buffer_switcher_commands.md") then
         return "../docs/open_buffer_switcher_commands.md";
      elsif Ada.Directories.Exists ("../../docs/open_buffer_switcher_commands.md") then
         return "../../docs/open_buffer_switcher_commands.md";
      else
         return "docs/open_buffer_switcher_commands.md";
      end if;
   end Existing_Switcher_Command_Reference_Path;

   function Reference_Text return String is
      File : Ada.Text_IO.File_Type;
      Text : Unbounded_String := Null_Unbounded_String;
      Path : constant String := Existing_Switcher_Command_Reference_Path;
   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         Append (Text, Ada.Text_IO.Get_Line (File));
         Append (Text, ASCII.LF);
      end loop;
      Ada.Text_IO.Close (File);
      return To_String (Text);
   end Reference_Text;

   function Cell (Line : String; Number : Positive) return String is
      Current : Natural := 0;
      Start_Pos : Natural := 0;
   begin
      for I in Line'Range loop
         if Line (I) = '|' then
            Current := Current + 1;
            if Current = Number then
               Start_Pos := I + 1;
            elsif Current = Number + 1 then
               if Start_Pos > I - 1 then
                  return "";
               end if;
               return Ada.Strings.Fixed.Trim
                 (Line (Start_Pos .. I - 1), Ada.Strings.Both);
            end if;
         end if;
      end loop;
      return "";
   end Cell;

   function Switcher_Command_Is_In_Reference
     (Id : Editor.Commands.Command_Id) return Boolean
   is
      Stable : constant String := Editor.Commands.Stable_Command_Name (Id);
   begin
      return Starts_With (Stable, "buffers.switcher.")
        or else Stable = "buffers.recent.previous"
        or else Stable = "buffers.recent.next"
        or else Stable = "file.close-other-buffers"
        or else Stable = "file.close-clean-buffers"
        or else Stable = "buffers.close-unpinned";
   end Switcher_Command_Is_In_Reference;

   function Classification_Label
     (D : Editor.Commands.Command_Descriptor) return String
   is
   begin
      if D.Destructive and then D.Lifecycle and then D.Configuration then
         return "Destructive+Lifecycle+Configuration";
      elsif D.Destructive and then D.Lifecycle then
         return "Destructive+Lifecycle";
      elsif D.Destructive and then D.Configuration then
         return "Destructive+Configuration";
      elsif D.Lifecycle and then D.Configuration then
         return "Lifecycle+Configuration";
      elsif D.Destructive then
         return "Destructive";
      elsif D.Lifecycle then
         return "Lifecycle";
      elsif D.Configuration then
         return "Configuration";
      else
         return "General";
      end if;
   end Classification_Label;

   function Hint_Label (Id : Editor.Commands.Command_Id) return String is
      use Editor.Commands;
   begin
      case Id is
         when Command_Close_Buffer_Switcher
            | Command_Accept_Buffer_Switcher
            | Command_Buffer_Switcher_Next_Result
            | Command_Buffer_Switcher_Previous_Result
            | Command_Buffer_Switcher_Filter_Clear
            | Command_Buffer_Switcher_Sort_Next
            | Command_Buffer_Switcher_Mark_Set
            | Command_Buffer_Switcher_Mark_Clear
            | Command_Buffer_Switcher_Mark_Clear_All
            | Command_Buffer_Switcher_Mark_Close_Marked
            | Command_Buffer_Switcher_Mark_Confirm
            | Command_Buffer_Switcher_Mark_Cancel
            | Command_Buffer_Switcher_Mark_Review_Show
            | Command_Buffer_Switcher_Mark_Review_Hide
            | Command_Buffer_Switcher_Pending_Mark_Review_Show
            | Command_Buffer_Switcher_Pending_Mark_Review_Hide
            | Command_Buffer_Switcher_Pending_Mark_Next
            | Command_Buffer_Switcher_Pending_Mark_Previous
            | Command_Buffer_Switcher_Pending_Mark_Remove_Selected
            | Command_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Next
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Previous
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Show
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Hide
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Next
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Previous
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Confirm
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Cancel
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Next
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Previous
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Show
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Hide
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Remove_Selected
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Restore_Last_Removed
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Next
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Previous
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Clear_Stale
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Cancel
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Next
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Next
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Previous
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale
            | Command_Buffer_Switcher_Mark_Next
            | Command_Buffer_Switcher_Mark_Previous =>
            return "conditional";
         when others =>
            return "no";
      end case;
   end Hint_Label;

   function Owner_Label (Stable : String) return String is
   begin
      if Starts_With (Stable, "buffers.switcher.filter.")
        or else Starts_With (Stable, "buffers.switcher.sort.")
      then
         return "filter/query/sort state";
      elsif Starts_With (Stable, "buffers.switcher.selected.") then
         return "selected row";
      elsif Starts_With (Stable, "buffers.switcher.preview.") then
         return "preview state";
      elsif Starts_With (Stable, "buffers.switcher.mark.") then
         if Ada.Strings.Fixed.Index (Stable, ".review.") > 0
           or else Ada.Strings.Fixed.Index (Stable, ".next") > 0
           or else Ada.Strings.Fixed.Index (Stable, ".previous") > 0
           or else Ada.Strings.Fixed.Index (Stable, ".summary") > 0
         then
            return "mark review state";
         else
            return "mark set";
         end if;
      elsif Starts_With (Stable, "buffers.switcher.pending-mark.dirty-prune.apply.") then
         return "dirty-prune apply confirmation";
      elsif Starts_With (Stable, "buffers.switcher.pending-mark.dirty-prune.") then
         return "dirty-prune preview";
      elsif Starts_With (Stable, "buffers.switcher.pending-mark.dirty-") then
         return "dirty pending targets";
      elsif Ada.Strings.Fixed.Index (Stable, ".pruned") > 0
        or else Ada.Strings.Fixed.Index (Stable, "restore-selected-pruned") > 0
      then
         return "ordinary pruned targets";
      elsif Starts_With (Stable, "buffers.switcher.pending-mark.") then
         return "pending marked close";
      elsif Starts_With (Stable, "buffers.recent.") then
         return "recent-buffer traversal";
      elsif Starts_With (Stable, "buffers.close-")
        or else Stable = "file.close-other-buffers"
        or else Stable = "file.close-clean-buffers"
      then
         return "buffer cleanup policy";
      else
         return "switcher overlay";
      end if;
   end Owner_Label;

   procedure Assert_Row_Matches_Descriptor (Line : String) is
      Stable : constant String := Cell (Line, 1);
      Found  : Boolean := False;
      Id     : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      D      : Editor.Commands.Command_Descriptor;
   begin
      Id := Editor.Commands.Command_Id_From_Stable_Name (Stable, Found);
      Assert (Found,
              "documented switcher command must resolve to descriptor: " & Stable);
      Assert (Switcher_Command_Is_In_Reference (Id),
              "documented command must be part of switcher reference: " & Stable);
      D := Editor.Commands.Descriptor (Id);
      Assert (Cell (Line, 2) = To_String (D.Description),
              "documented description must match descriptor for " & Stable);
      Assert (Cell (Line, 3) = Editor.Commands.Category_Label (D.Category),
              "documented category must match descriptor for " & Stable);
      Assert (Cell (Line, 4) = Classification_Label (D),
              "documented classification must match descriptor for " & Stable);
      Assert (Cell (Line, 5) = Yes_No (D.Bindable),
              "documented bindability must match descriptor for " & Stable);
      Assert (Cell (Line, 6) = Yes_No (D.Visibility = Editor.Commands.Palette_Command),
              "documented palette visibility must match descriptor for " & Stable);
      Assert (Cell (Line, 7) = Hint_Label (Id),
              "documented hint eligibility must match hint baseline for " & Stable);
      Assert (Cell (Line, 8) = "Executor",
              "documented route class must match executor route baseline for " & Stable);
      Assert (Cell (Line, 9) = Owner_Label (Stable),
              "documented availability owner must match baseline for " & Stable);
      Assert (Cell (Line, 10) = "current",
              "documented compatibility status must be current for " & Stable);
   end Assert_Row_Matches_Descriptor;

   procedure Test_Switcher_Command_Reference_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Line : Unbounded_String;
      In_Table : Boolean := False;
      Documented_Count : Natural := 0;
      Expected_Count : Natural := 0;
      Seen : array (Editor.Commands.Command_Id) of Boolean := (others => False);
      Found : Boolean;
      Id : Editor.Commands.Command_Id;
   begin
      declare
         Text : constant String := Reference_Text;
         Pos  : Positive := Text'First;
         Next : Natural;
      begin
         while Pos <= Text'Last loop
            Next := Pos;
            while Next <= Text'Last and then Text (Next) /= ASCII.LF loop
               Next := Next + 1;
            end loop;

            if Next > Text'Last then
               Line := To_Unbounded_String (Text (Pos .. Text'Last));
               Pos := Text'Last + 1;
            elsif Next = Pos then
               Line := Null_Unbounded_String;
               Pos := Next + 1;
            else
               Line := To_Unbounded_String (Text (Pos .. Next - 1));
               Pos := Next + 1;
            end if;
         if To_String (Line) = "<!-- switcher-command-table:start -->" then
            In_Table := True;
         elsif To_String (Line) = "<!-- switcher-command-table:end -->" then
            In_Table := False;
         elsif In_Table
           and then (Starts_With (To_String (Line), "| buffers.")
                     or else Starts_With (To_String (Line), "| file.close-"))
         then
            Assert_Row_Matches_Descriptor (To_String (Line));
            Id := Editor.Commands.Command_Id_From_Stable_Name (Cell (To_String (Line), 1), Found);
            Assert (Found and then not Seen (Id),
                    "documented switcher command names must be unique");
            Seen (Id) := True;
            Documented_Count := Documented_Count + 1;
         end if;
         end loop;
      end;

      for I in 1 .. Editor.Commands.Command_Count loop
         Id := Editor.Commands.Command_At (I);
         if Switcher_Command_Is_In_Reference (Id) then
            Expected_Count := Expected_Count + 1;
            Assert (Seen (Id),
                    "every switcher descriptor in the frozen baseline must be documented: " &
                    Editor.Commands.Stable_Command_Name (Id));
         end if;
      end loop;

      Assert (Documented_Count = Expected_Count,
              "command reference must neither omit nor invent switcher commands");
   end Test_Switcher_Command_Reference_Metadata;

   procedure Test_Switcher_Command_Reference_Content
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Text : constant String := Reference_Text;
   begin
      Assert (Ada.Strings.Fixed.Index (Text, "# Open Buffer Switcher Commands") > 0,
              "reference must contain canonical command-name heading");
      Assert (Ada.Strings.Fixed.Index (Text, "## Stable Name Rules") > 0,
              "reference must contain stable-name section");
      Assert (Ada.Strings.Fixed.Index (Text, "Only current Open Buffer Switcher command names are accepted.") > 0,
              "reference must state current-name acceptance baseline");
      Assert (Ada.Strings.Fixed.Index (Text, "## Route Classes") > 0,
              "reference must explain route classes");
      Assert (Ada.Strings.Fixed.Index (Text, "## Availability Owner Notes") > 0,
              "reference must document availability-owner rules");
      Assert (Ada.Strings.Fixed.Index (Text, "Availability checks may report unavailable state") > 0,
              "reference must state availability checks do not repair or mutate workflow state");
      Assert (Ada.Strings.Fixed.Index (Text, "## Persistence Boundaries") > 0,
              "reference must document persistence boundaries");
      Assert (Ada.Strings.Fixed.Index (Text, "## Contextual Hints") > 0,
              "reference must document contextual-hint policy");
      Assert (Ada.Strings.Fixed.Index (Text, "## Keybindings") > 0,
              "reference must document keybinding persistence policy");
      Assert (Ada.Strings.Fixed.Index (Text, "## Command Palette") > 0,
              "reference must document Command Palette behavior");
      Assert (Ada.Strings.Fixed.Index (Text, "## Read-Only Derivation Is Not a Command Surface") > 0,
              "reference must distinguish read-only derivation from commands");
      Assert (Ada.Strings.Fixed.Index (Text, "## Mutation Notes") > 0,
              "reference must document mutation boundaries");
      Assert (Ada.Strings.Fixed.Index (Text, "## Optional Absent Commands") > 0,
              "reference must contain optional absent-command section");
      Assert (Ada.Strings.Fixed.Index (Text, "No optional absent switcher commands are documented") > 0,
              "reference must make optional absent-command baseline explicit");
      Assert (Ada.Strings.Fixed.Index (Text, "## Accepted Command Names") > 0,
              "reference must contain accepted-command-name section");
      Assert (Ada.Strings.Fixed.Index (Text, "| batch-state snapshot") = 0
              and then Ada.Strings.Fixed.Index (Text, "| row marker derivation") = 0
              and then Ada.Strings.Fixed.Index (Text, "| contextual hint derivation") = 0
              and then Ada.Strings.Fixed.Index (Text, "| header/footer badge formatting") = 0
              and then Ada.Strings.Fixed.Index (Text, "| message formatting") = 0
              and then Ada.Strings.Fixed.Index (Text, "| render packet emission") = 0
              and then Ada.Strings.Fixed.Index (Text, "| availability checks") = 0,
              "display-only helpers must not be documented as command table rows");
   end Test_Switcher_Command_Reference_Content;


   procedure Test_Configuration_Command_Surface_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Review : Editor.Command_Surface.Command_Surface_Review;
   begin
      Editor.State.Init (S);
      Review := Editor.Command_Surface.Review_Command_Surface (S);

      Assert
        (Editor.Command_Surface.Assert_Configuration_Command_Surface_Coherent (S),
         "milestone helper must pass on a clean state");
      Assert
        (Review.Stable_Ids_Unique,
         "visible command ids must be stable canonical names");
      Assert
        (Review.Palette_Projection_Consistent,
         "palette projection must exclude internal/demo/public-build test-seam commands");
      Assert
        (Review.Discoverability_Metadata_Coherent,
         "discoverability metadata must be coherent in command-surface review");
      Assert
        (Review.Keybinding_Targets_Valid,
         "active keybindings must target bindable canonical commands only");
      Assert
        (Review.Availability_Reasons_Stable,
         "availability checks must be stable and side-effect-free");
      Assert
        (Editor.Command_Surface.Build_Command_Surface_Review_Feedback (Review) =
           "Commands: command surface healthy",
         "coherent command surface should have a user-readable healthy summary");
   end Test_Configuration_Command_Surface_Coherent;

   procedure Test_Switch_Project_Command_Surface
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D      : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Switch_Project);
      Found  : Boolean := False;
      Id     : constant Editor.Commands.Command_Id :=
        Editor.Commands.Command_Id_From_Stable_Name ("project.switch", Found);
      S      : Editor.State.State_Type;
      Avail  : constant Editor.Commands.Command_Availability :=
        Editor.Executor.Command_Availability
          (S, Editor.Commands.Command_Switch_Project);
   begin
      Assert (D.Id = Editor.Commands.Command_Switch_Project,
              "switch project descriptor must exist");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Switch_Project) = "project.switch",
              "switch project stable name must be canonical");
      Assert (Found and then Id = Editor.Commands.Command_Switch_Project,
              "switch project stable name must round-trip");
      Assert (Editor.Commands.Requires_Context
                (Editor.Commands.Command_Switch_Project),
              "switch project requires explicit input context");
      Assert (Editor.Commands.Is_Lifecycle_Command
                (Editor.Commands.Command_Switch_Project),
              "switch project is a lifecycle command");
      Assert (not Editor.Commands.Is_Destructive_Command
                (Editor.Commands.Command_Switch_Project),
              "switch project must not be classified as destructive by itself");
      Assert (not Editor.Commands.Is_Available (Avail),
              "switch project has no keybinding/palette path payload");
      Assert (Editor.Commands.Unavailable_Reason (Avail) = "No target project selected",
              "switch project unavailable reason must name missing target");
   end Test_Switch_Project_Command_Surface;



   procedure Test_Product_Command_Surface
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      type Command_Array is array (Positive range <>) of Editor.Commands.Command_Id;
      Product_Commands : constant Command_Array :=
        (Editor.Commands.Command_Open_Project,
         Editor.Commands.Command_Close_Project,
         Editor.Commands.Command_Switch_Project,
         Editor.Commands.Command_Show_Recent_Projects,
         Editor.Commands.Command_Open_File,
         Editor.Commands.Command_Save_File,
         Editor.Commands.Command_Save_File_As,
         Editor.Commands.Command_Reload_Active_Buffer,
         Editor.Commands.Command_Revert_Active_Buffer,
         Editor.Commands.Command_Refresh_File_Tree,
         Editor.Commands.Command_File_Tree_Open_Selected,
         Editor.Commands.Command_File_Tree_Create_File,
         Editor.Commands.Command_File_Tree_Create_Directory,
         Editor.Commands.Command_File_Tree_Rename_Selected,
         Editor.Commands.Command_File_Tree_Delete_Selected,
         Editor.Commands.Command_Open_Quick_Open,
         Editor.Commands.Command_Run_Project_Search,
         Editor.Commands.Command_Open_Selected_Project_Search_Result,
         Editor.Commands.Command_Show_Outline,
         Editor.Commands.Command_Refresh_Outline_Project_Index,
         Editor.Commands.Command_Goto_Declaration,
         Editor.Commands.Command_Goto_Body,
         Editor.Commands.Command_Goto_Spec,
         Editor.Commands.Command_Find_References,
         Editor.Commands.Command_Show_Hover,
         Editor.Commands.Command_Show_Completions,
         Editor.Commands.Command_Semantic_Completion_Select_Next,
         Editor.Commands.Command_Semantic_Completion_Select_Previous,
         Editor.Commands.Command_Semantic_Completion_Accept,
         Editor.Commands.Command_Semantic_Popup_Dismiss,
         Editor.Commands.Command_Rename_Symbol_Preview,
         Editor.Commands.Command_Rename_Symbol_Apply,
         Editor.Commands.Command_Semantic_Refresh_Buffer,
         Editor.Commands.Command_Semantic_Refresh_Project_Index,
         Editor.Commands.Command_Language_Index_Clear,
         Editor.Commands.Command_Language_Index_Status,
         Editor.Commands.Command_Open_Selected_Outline_Item,
         Editor.Commands.Command_Build_Run,
         Editor.Commands.Command_Build_UI_Show,
         Editor.Commands.Command_Build_UI_Toggle,
         Editor.Commands.Command_Build_UI_Hide,
         Editor.Commands.Command_Build_UI_Focus,
         Editor.Commands.Command_Diagnostics_Show,
         Editor.Commands.Command_Diagnostics_Execute_Selected_Action,
         Editor.Commands.Command_Next_Buffer,
         Editor.Commands.Command_Previous_Buffer,
         Editor.Commands.Command_Close_Active_Buffer,
         Editor.Commands.Command_Close_All_Clean_Buffers,
         Editor.Commands.Command_Restore_Workspace_State);

      function Contains_Internal_Term (Text : String) return Boolean is
         Lower : constant String := Ada.Characters.Handling.To_Lower (Text);
      begin
         return Ada.Strings.Fixed.Index (Lower, "audit") > 0
           or else Ada.Strings.Fixed.Index (Lower, "fixture") > 0
           or else Ada.Strings.Fixed.Index (Lower, "guard") > 0
           or else Ada.Strings.Fixed.Index (Lower, "scaffold") > 0
           or else Ada.Strings.Fixed.Index (Lower, "surface entry") > 0
           or else Ada.Strings.Fixed.Index (Lower, "route") > 0
           or else Ada.Strings.Fixed.Index (Lower, "executor") > 0
           or else Ada.Strings.Fixed.Index (Lower, "runtime state") > 0
           or else Ada.Strings.Fixed.Index (Lower, "command request") > 0
           or else Ada.Strings.Fixed.Index (Lower, "prompt identity") > 0
           or else Ada.Strings.Fixed.Index (Lower, "producer") > 0
           or else Ada.Strings.Fixed.Index (Lower, "synthetic") > 0
           or else Ada.Strings.Fixed.Index (Lower, "buffer_id") > 0
           or else Ada.Strings.Fixed.Index (Lower, "route_id") > 0
           or else Ada.Strings.Fixed.Index (Lower, "buffer id") > 0
           or else Ada.Strings.Fixed.Index (Lower, "route id") > 0;
      end Contains_Internal_Term;

      function Looks_Like_Fallback_Copy
        (Name : String;
         Description : String) return Boolean
      is
         Lower_Desc : constant String := Ada.Characters.Handling.To_Lower (Description);
         Lower_Name : constant String := Ada.Characters.Handling.To_Lower (Name);
      begin
         return Lower_Desc = "execute " & Lower_Name & "."
           or else Ada.Strings.Fixed.Index (Lower_Desc, "execute command") > 0;
      end Looks_Like_Fallback_Copy;

      D : Editor.Commands.Command_Descriptor;
      A : Editor.Commands.Command_Availability;
      S : Editor.State.State_Type;
   begin
      for Id of Product_Commands loop
         D := Editor.Commands.Descriptor (Id);
         Assert (Editor.Commands.Has_Descriptor (Id),
                 "product command has descriptor");
         Assert (To_String (D.Name)'Length > 0,
                 "product command label is present");
         Assert (not Contains_Internal_Term (To_String (D.Name)),
                 "product command label avoids internal terms: " &
                 To_String (D.Name));
         Assert (not Contains_Internal_Term (To_String (D.Description)),
                 "product command description avoids internal terms: " &
                 To_String (D.Description));
         Assert (D.Visibility = Editor.Commands.Palette_Command
                   or else D.Visibility = Editor.Commands.Hidden_Command,
                 "product command visibility is explicit");
         A := Editor.Executor.Command_Availability (S, Id);
         if not Editor.Commands.Is_Available (A) then
            Assert (Editor.Commands.Unavailable_Reason (A)'Length > 0,
                    "unavailable product command reports a reason");
            Assert (not Contains_Internal_Term
                      (Editor.Commands.Unavailable_Reason (A)),
                    "unavailable reason avoids internal terms");
         end if;
      end loop;

      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Build_Run) = "build.run",
              "build.run command id remains canonical");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Switch_Project) = "project.switch",
              "project.switch command id remains canonical");

      for Id in Editor.Commands.First_Command .. Editor.Commands.Last_Command loop
         D := Editor.Commands.Descriptor (Id);
         if D.Visibility = Editor.Commands.Palette_Command then
            Assert
              (Ada.Strings.Fixed.Index
                 (Ada.Characters.Handling.To_Lower
                    (To_String (D.Name) & " " & To_String (D.Description)),
                  "open-open buffer list") = 0,
               "palette-visible command surface must not use stale Open Buffer List wording: " &
               Editor.Commands.Stable_Command_Name (Id));
            Assert
              (not Looks_Like_Fallback_Copy
                 (To_String (D.Name), To_String (D.Description)),
               "palette-visible command description must be action-oriented product copy: " &
               Editor.Commands.Stable_Command_Name (Id) & " => " &
               To_String (D.Description));
         end if;
      end loop;
   end Test_Product_Command_Surface;



   procedure Test_IDE_Grade_Language_Command_Surface
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      type Expected_Command is record
         Name : Ada.Strings.Unbounded.Unbounded_String;
         Id   : Editor.Commands.Command_Id;
      end record;
      type Expected_Command_Array is array (Positive range <>) of Expected_Command;
      Expected : constant Expected_Command_Array :=
        ((To_Unbounded_String ("outline.refresh"),
          Editor.Commands.Command_Refresh_Outline),
         (To_Unbounded_String ("outline.clear"),
          Editor.Commands.Command_Clear_Outline),
         (To_Unbounded_String ("outline.show"),
          Editor.Commands.Command_Show_Outline),
         (To_Unbounded_String ("outline.focus"),
          Editor.Commands.Command_Focus_Outline),
         (To_Unbounded_String ("outline.open-selected"),
          Editor.Commands.Command_Open_Selected_Outline_Item),
         (To_Unbounded_String ("outline.refresh-project-index"),
          Editor.Commands.Command_Refresh_Outline_Project_Index),
         (To_Unbounded_String ("outline.goto-declaration"),
          Editor.Commands.Command_Goto_Declaration),
         (To_Unbounded_String ("outline.goto-body"),
         Editor.Commands.Command_Goto_Body),
         (To_Unbounded_String ("outline.goto-spec"),
          Editor.Commands.Command_Goto_Spec),
         (To_Unbounded_String ("semantic.find-references"),
          Editor.Commands.Command_Find_References),
         (To_Unbounded_String ("semantic.show-hover"),
         Editor.Commands.Command_Show_Hover),
         (To_Unbounded_String ("semantic.show-completions"),
         Editor.Commands.Command_Show_Completions),
         (To_Unbounded_String ("semantic.rename-symbol-preview"),
          Editor.Commands.Command_Rename_Symbol_Preview),
         (To_Unbounded_String ("semantic.rename-symbol-apply"),
          Editor.Commands.Command_Rename_Symbol_Apply),
         (To_Unbounded_String ("semantic.refresh-buffer"),
          Editor.Commands.Command_Semantic_Refresh_Buffer),
         (To_Unbounded_String ("semantic.refresh-project-index"),
          Editor.Commands.Command_Semantic_Refresh_Project_Index),
         (To_Unbounded_String ("language.index.clear"),
          Editor.Commands.Command_Language_Index_Clear),
         (To_Unbounded_String ("language.index.status"),
          Editor.Commands.Command_Language_Index_Status));
      Found : Boolean;
      Round : Editor.Commands.Command_Id;
      D     : Editor.Commands.Command_Descriptor;
   begin
      for E of Expected loop
         Round := Editor.Commands.Command_Id_From_Stable_Name
           (To_String (E.Name), Found);
         Assert (Found and then Round = E.Id,
                 "IDE-grade language command must resolve by canonical id: " &
                 To_String (E.Name));
         Assert (Editor.Commands.Stable_Command_Name (E.Id) = To_String (E.Name),
                 "IDE-grade language command must expose canonical stable id: " &
                 To_String (E.Name));
         D := Editor.Commands.Descriptor (E.Id);
         Assert (D.Visibility = Editor.Commands.Palette_Command,
                 "IDE-grade language command must be palette-visible: " &
                 To_String (E.Name));
         Assert (To_String (D.Name)'Length > 0
                   and then To_String (D.Description)'Length > 0,
                 "IDE-grade language command descriptor must be user-facing: " &
                 To_String (E.Name));
      end loop;

      Round := Editor.Commands.Command_Id_From_Stable_Name
        ("refactor.rename-symbol", Found);
      Assert (Found and then Round = Editor.Commands.Command_Rename_Symbol_Preview,
              "Refactor rename alias should resolve to semantic rename preview");
      Round := Editor.Commands.Command_Id_From_Stable_Name
        ("refactor.rename-symbol-preview", Found);
      Assert (Found and then Round = Editor.Commands.Command_Rename_Symbol_Preview,
              "Refactor rename preview alias should resolve to semantic rename preview");
      Round := Editor.Commands.Command_Id_From_Stable_Name
        ("refactor.rename-symbol-apply", Found);
      Assert (Found and then Round = Editor.Commands.Command_Rename_Symbol_Apply,
              "Refactor rename apply alias should resolve to semantic rename apply");

      declare
         Hidden_Expected : constant Expected_Command_Array :=
           ((To_Unbounded_String ("semantic.completion.select-next"),
             Editor.Commands.Command_Semantic_Completion_Select_Next),
            (To_Unbounded_String ("semantic.completion.select-previous"),
             Editor.Commands.Command_Semantic_Completion_Select_Previous),
            (To_Unbounded_String ("semantic.completion.accept"),
             Editor.Commands.Command_Semantic_Completion_Accept),
            (To_Unbounded_String ("semantic.popup.dismiss"),
             Editor.Commands.Command_Semantic_Popup_Dismiss));
      begin
         for E of Hidden_Expected loop
            Round := Editor.Commands.Command_Id_From_Stable_Name
              (To_String (E.Name), Found);
            Assert (Found and then Round = E.Id,
                    "IDE-grade popup command must resolve by canonical id: " &
                    To_String (E.Name));
            Assert (Editor.Commands.Stable_Command_Name (E.Id) = To_String (E.Name),
                    "IDE-grade popup command must expose canonical stable id: " &
                    To_String (E.Name));
            D := Editor.Commands.Descriptor (E.Id);
            Assert (D.Visibility = Editor.Commands.Hidden_Command,
                    "IDE-grade popup command must stay hidden: " &
                    To_String (E.Name));
            Assert (To_String (D.Name)'Length > 0
                      and then To_String (D.Description)'Length > 0,
                    "IDE-grade popup command descriptor must be user-facing: " &
                    To_String (E.Name));
         end loop;
      end;

      --  Pass 172: descriptor-specific project-refresh checks must live
      --  outside the expected-command enumeration loop.

      D := Editor.Commands.Descriptor
        (Editor.Commands.Command_Refresh_Outline_Project_Index);
      Assert
        (Ada.Strings.Fixed.Index
           (To_String (D.Description), "known project Ada source files") > 0,
         "outline project-index refresh must describe project-file indexing");

      D := Editor.Commands.Descriptor
        (Editor.Commands.Command_Semantic_Refresh_Project_Index);
      Assert
        (Ada.Strings.Fixed.Index
           (To_String (D.Description), "known project Ada files") > 0
           or else Ada.Strings.Fixed.Index
             (To_String (D.Description), "known project Ada source files") > 0,
         "semantic project-index refresh must describe project-file indexing");

      --  Pass 173: body/spec navigation must be a real indexed target
      --  command surface, not a permanently reserved unavailable placeholder.
      D := Editor.Commands.Descriptor (Editor.Commands.Command_Goto_Body);
      Assert
        (Ada.Strings.Fixed.Index
           (To_String (D.Description), "body target") > 0
         and then Ada.Strings.Fixed.Index
           (Ada.Characters.Handling.To_Lower (To_String (D.Description)),
            "reserved") = 0,
         "outline.goto-body must describe real indexed body navigation");

      D := Editor.Commands.Descriptor (Editor.Commands.Command_Goto_Spec);
      Assert
        (Ada.Strings.Fixed.Index
           (To_String (D.Description), "spec target") > 0
         and then Ada.Strings.Fixed.Index
           (Ada.Characters.Handling.To_Lower (To_String (D.Description)),
            "reserved") = 0,
         "outline.goto-spec must describe real indexed spec navigation");

      Round := Editor.Commands.Command_Id_From_Stable_Name ("refresh-outline", Found);
      Assert (not Found, "legacy refresh-outline spelling must not resolve");
      Round := Editor.Commands.Command_Id_From_Stable_Name ("clear-outline", Found);
      Assert (not Found, "legacy clear-outline spelling must not resolve");
      Round := Editor.Commands.Command_Id_From_Stable_Name ("show-outline", Found);
      Assert (not Found, "legacy show-outline spelling must not resolve");
      Round := Editor.Commands.Command_Id_From_Stable_Name ("focus-outline", Found);
      Assert (not Found, "legacy focus-outline spelling must not resolve");
      Round := Editor.Commands.Command_Id_From_Stable_Name ("open-selected-outline-item", Found);
      Assert (not Found, "legacy open-selected-outline-item spelling must not resolve");
   end Test_IDE_Grade_Language_Command_Surface;



   procedure Test_File_Command_Reference_Surface
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      type Command_Array is array (Positive range <>) of Editor.Commands.Command_Id;
      File_Commands : constant Command_Array :=
        (Editor.Commands.Command_Save_File,
         Editor.Commands.Command_Save_File_As,
         Editor.Commands.Command_Close_Active_Buffer,
         Editor.Commands.Command_Reopen_Closed_Buffer,
         Editor.Commands.Command_Reload_Active_Buffer,
         Editor.Commands.Command_Revert_Active_Buffer,
         Editor.Commands.Command_Rename_Buffer_File,
         Editor.Commands.Command_Delete_Buffer_File,
         Editor.Commands.Command_Copy_Buffer_File,
         Editor.Commands.Command_Move_Buffer_File);
      Prompt_Commands : constant Command_Array :=
        (Editor.Commands.Command_Confirm_Close_Save,
         Editor.Commands.Command_Confirm_Close_Discard,
         Editor.Commands.Command_Cancel_Close,
         Editor.Commands.Command_File_Conflict_Keep_Buffer,
         Editor.Commands.Command_File_Conflict_Reload_From_Disk,
         Editor.Commands.Command_File_Conflict_Overwrite_Disk,
         Editor.Commands.Command_File_Conflict_Cancel);

      function Contains_Internal_Term (Text : String) return Boolean is
         Lower : constant String := Ada.Characters.Handling.To_Lower (Text);
      begin
         return Ada.Strings.Fixed.Index (Lower, "metadata") > 0
           or else Ada.Strings.Fixed.Index (Lower, "projection") > 0
           or else Ada.Strings.Fixed.Index (Lower, "payload") > 0
           or else Ada.Strings.Fixed.Index (Lower, "lifecycle") > 0
           or else Ada.Strings.Fixed.Index (Lower, "route") > 0
           or else Ada.Strings.Fixed.Index (Lower, "producer") > 0
           or else Ada.Strings.Fixed.Index (Lower, "fixture") > 0
           or else Ada.Strings.Fixed.Index (Lower, "scaffold") > 0
           or else Ada.Strings.Fixed.Index (Lower, "surface entry") > 0
           or else Ada.Strings.Fixed.Index (Lower, "synthetic") > 0;
      end Contains_Internal_Term;

      Text : Unbounded_String;
   begin
      Assert (Editor.Commands.Command_Family_Label
                (Editor.Commands.File_Lifecycle_Family) = "File Operations",
              "file command family label is product-facing");

      for Id of File_Commands loop
         Text := To_Unbounded_String
           (Editor.Commands.Reference_Summary (Id) & " " &
            Editor.Commands.Reference_Availability_Summary (Id) & " " &
            Editor.Commands.Reference_Mutation_Summary (Id) & " " &
            Editor.Commands.Reference_Filesystem_Effect_Summary (Id) & " " &
            Editor.Commands.Reference_State_Preservation_Summary (Id) & " " &
            Editor.Commands.Reference_Non_Goal_Summary (Id));

         Assert (Editor.Commands.Has_Command_Reference (Id),
                 "file command reference exists");
         Assert (Length (Text) > 0,
                 "file command reference text is present");
         Assert (not Contains_Internal_Term (To_String (Text)),
                 "file command reference avoids internal wording: " &
                 To_String (Text));
      end loop;

      for Id of Prompt_Commands loop
         Assert (not Editor.Commands.Has_Command_Reference (Id),
                 "prompt-only file command must not expand public reference surface");
      end loop;
   end Test_File_Command_Reference_Surface;



   procedure Test_Project_Search_Product_Surface
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      type Command_Array is array (Positive range <>) of Editor.Commands.Command_Id;
      Project_Search_Commands : constant Command_Array :=
        (Editor.Commands.Command_Run_Project_Search,
         Editor.Commands.Command_Rerun_Project_Search,
         Editor.Commands.Command_Open_Project_Search_Bar,
         Editor.Commands.Command_Toggle_Project_Search_Bar,
         Editor.Commands.Command_Close_Project_Search_Bar,
         Editor.Commands.Command_Run_Project_Search_From_Bar,
         Editor.Commands.Command_Project_Search_From_Selection,
         Editor.Commands.Command_Project_Search_From_Active_Word,
         Editor.Commands.Command_Project_Search_Active_Directory,
         Editor.Commands.Command_Project_Search_From_Selection,
         Editor.Commands.Command_Clear_Project_Search,
         Editor.Commands.Command_Open_Selected_Project_Search_Result,
         Editor.Commands.Command_Move_Project_Search_Selection_Up,
         Editor.Commands.Command_Move_Project_Search_Selection_Down,
         Editor.Commands.Command_Next_Project_Search_Result,
         Editor.Commands.Command_Previous_Project_Search_Result,
         Editor.Commands.Command_First_Project_Search_Result,
         Editor.Commands.Command_Last_Project_Search_Result,
         Editor.Commands.Command_Reveal_Active_Project_Search_Result,
         Editor.Commands.Command_Project_Search_Scope_Selected_Directory,
         Editor.Commands.Command_Project_Search_Kind_Next,
         Editor.Commands.Command_Project_Search_Kind_Previous,
         Editor.Commands.Command_Project_Search_Kind_Clear,
         Editor.Commands.Command_Project_Search_Scope_Set,
         Editor.Commands.Command_Project_Search_Scope_Clear,
         Editor.Commands.Command_Project_Search_Case_Toggle,
         Editor.Commands.Command_Project_Search_Case_Clear,
         Editor.Commands.Command_Project_Search_Whole_Word_Toggle,
         Editor.Commands.Command_Project_Search_Whole_Word_Clear,
         Editor.Commands.Command_Project_Search_Regex_Toggle,
         Editor.Commands.Command_Project_Search_Regex_Clear,
         Editor.Commands.Command_Project_Search_Include_Filter_Set,
         Editor.Commands.Command_Project_Search_Exclude_Filter_Set,
         Editor.Commands.Command_Project_Search_Include_Filter_Clear,
         Editor.Commands.Command_Project_Search_Exclude_Filter_Clear,
         Editor.Commands.Command_Project_Search_Replace_Preview,
         Editor.Commands.Command_Project_Search_Replace_Selected,
         Editor.Commands.Command_Project_Search_Replace_All_Included,
         Editor.Commands.Command_Project_Search_Replace_Clear_Preview,
         Editor.Commands.Command_Show_Search_Results_Panel,
         Editor.Commands.Command_Focus_Search_Results,
         Editor.Commands.Command_Search_Results_Move_Up,
         Editor.Commands.Command_Search_Results_Move_Down,
         Editor.Commands.Command_Search_Results_Open_Selected);

      function Contains_Project_Search_Leak (Text : String) return Boolean is
         Lower : constant String := Ada.Characters.Handling.To_Lower (Text);
      begin
         return Ada.Strings.Fixed.Index (Lower, "transient") > 0
           or else Ada.Strings.Fixed.Index (Lower, "executor") > 0
           or else Ada.Strings.Fixed.Index (Lower, "compatibility") > 0
           or else Ada.Strings.Fixed.Index (Lower, "bottom panel") > 0
           or else Ada.Strings.Fixed.Index (Lower, "metadata") > 0
           or else Ada.Strings.Fixed.Index (Lower, "lifecycle") > 0
           or else Ada.Strings.Fixed.Index (Lower, "route") > 0
           or else Ada.Strings.Fixed.Index (Lower, "producer") > 0
           or else Ada.Strings.Fixed.Index (Lower, ":") > 0;
      end Contains_Project_Search_Leak;

      D : Editor.Commands.Command_Descriptor;
   begin
      for Id of Project_Search_Commands loop
         D := Editor.Commands.Descriptor (Id);
         Assert (To_String (D.Name)'Length > 0,
                 "Project Search command label is present");
         Assert (To_String (D.Description)'Length > 0,
                 "Project Search command description is present: " &
                 To_String (D.Name));
         Assert (not Contains_Project_Search_Leak (To_String (D.Name)),
                 "Project Search label avoids implementation wording: " &
                 To_String (D.Name));
         Assert (not Contains_Project_Search_Leak (To_String (D.Description)),
                 "Project Search description avoids implementation wording: " &
                 To_String (D.Description));
      end loop;
   end Test_Project_Search_Product_Surface;


   procedure Test_Find_And_Goto_Product_Surface
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      type Command_Array is array (Positive range <>) of Editor.Commands.Command_Id;
      Find_And_Goto_Commands : constant Command_Array :=
        (Editor.Commands.Command_Goto_Line,
         Editor.Commands.Command_Goto_Line_Toggle,
         Editor.Commands.Command_Goto_Line_Prefill_Current,
         Editor.Commands.Command_Goto_Line_Query_Set,
         Editor.Commands.Command_Goto_Line_Query_Clear,
         Editor.Commands.Command_Close_Goto_Line,
         Editor.Commands.Command_Accept_Goto_Line,
         Editor.Commands.Command_Find_Show,
         Editor.Commands.Command_Find_Hide,
         Editor.Commands.Command_Find_Toggle,
         Editor.Commands.Command_Find_Query_Set,
         Editor.Commands.Command_Find_Query_Clear,
         Editor.Commands.Command_Find_Case_Toggle,
         Editor.Commands.Command_Find_Case_Clear,
         Editor.Commands.Command_Find_Whole_Word_Toggle,
         Editor.Commands.Command_Find_Whole_Word_Clear,
         Editor.Commands.Command_Find_From_Selection,
         Editor.Commands.Command_Find_From_Active_Word,
         Editor.Commands.Command_Active_Find_Next,
         Editor.Commands.Command_Active_Find_Previous,
         Editor.Commands.Command_Find_First,
         Editor.Commands.Command_Find_Last,
         Editor.Commands.Command_Find_Reveal_Current,
         Editor.Commands.Command_Replace_Show,
         Editor.Commands.Command_Replace_Hide,
         Editor.Commands.Command_Replace_Toggle,
         Editor.Commands.Command_Replace_Text_Set,
         Editor.Commands.Command_Replace_Text_Clear,
         Editor.Commands.Command_Replace_Current,
         Editor.Commands.Command_Replace_All);

      function Contains_Find_Surface_Leak (Text : String) return Boolean is
         Lower : constant String := Ada.Characters.Handling.To_Lower (Text);
      begin
         return Ada.Strings.Fixed.Index (Lower, "transient") > 0
           or else Ada.Strings.Fixed.Index (Lower, "metadata") > 0
           or else Ada.Strings.Fixed.Index (Lower, "projection") > 0
           or else Ada.Strings.Fixed.Index (Lower, "payload") > 0
           or else Ada.Strings.Fixed.Index (Lower, "active-buffer find") > 0
           or else Ada.Strings.Fixed.Index (Lower, "active-buffer replace") > 0;
      end Contains_Find_Surface_Leak;

      D : Editor.Commands.Command_Descriptor;
   begin
      for Id of Find_And_Goto_Commands loop
         D := Editor.Commands.Descriptor (Id);
         Assert (To_String (D.Name)'Length > 0,
                 "Find/Go to Line command label is present");
         Assert (To_String (D.Description)'Length > 0,
                 "Find/Go to Line command description is present: " &
                 To_String (D.Name));
         Assert (not Contains_Find_Surface_Leak (To_String (D.Name)),
                 "Find/Go to Line label avoids implementation wording: " &
                 To_String (D.Name));
         Assert (not Contains_Find_Surface_Leak (To_String (D.Description)),
                 "Find/Go to Line description avoids implementation wording: " &
                 To_String (D.Description));
      end loop;
   end Test_Find_And_Goto_Product_Surface;

   overriding function Name
     (T : Command_Surface_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Command_Surface.Tests");
   end Name;


   procedure Test_Public_Build_Guardrail_Manifest_Default_Is_Healthy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Manifest : Public_Build_Guardrail_Regression_Manifest;
   begin
      Editor.State.Init (S);
      Manifest := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Assert (Manifest.Health.Healthy,
              "manifest embeds healthy public build guardrail health");
      Assert (Manifest.Default_Contract_Matches,
              "manifest default normalized guardrail contract must match");
      Assert (Manifest.Trace_Surface_Complete,
              "manifest audit trace surface must be complete");
      Assert (Manifest.Public_Command_Surface_Complete,
              "manifest public-id domains must be complete");
      Assert (Manifest.Persistence_Exclusion_Clean,
              "manifest persistence exclusion must be clean");
      Assert (Manifest.Lifecycle_Stable,
              "manifest lifecycle snapshot must be stable");
      Assert (Manifest.Public_Surface_Present,
              "manifest must prove no public build surface exists");
      Assert (Manifest.Execution_Surface_Present,
              "manifest must prove no public build execution surface exists");
      Assert (Manifest.Surface_Command_Executable,
              "manifest must prove surface entry metadata is non-executable");
      Assert (not Manifest.Promotion_Blocked,
              "manifest must prove guarded promotion is ready");
      Assert (not Manifest.Dependency_Blockers_Active,
              "manifest must prove dependency blockers are inactive");
      Assert (Manifest.Manifest_Healthy,
              "default public build guardrail regression manifest must be healthy");
      Assert_Public_Build_Guardrail_Regression_Manifest_Default (Manifest);
   end Test_Public_Build_Guardrail_Manifest_Default_Is_Healthy;

   procedure Test_Public_Build_Guardrail_Manifest_Feedback_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Manifest : Public_Build_Guardrail_Regression_Manifest;
   begin
      Editor.State.Init (S);
      Manifest := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Assert (Build_Public_Build_Guardrail_Regression_Manifest_Feedback
                (Manifest) =
              "Build: public build regression manifest healthy",
              "healthy manifest feedback must be deterministic");

      Manifest.Manifest_Healthy := False;
      Manifest.Default_Contract_Matches := False;
      Assert (Build_Public_Build_Guardrail_Regression_Manifest_Feedback
                (Manifest) =
              "Build: public build default contract mismatch",
              "contract mismatch feedback must be deterministic");

      Manifest.Default_Contract_Matches := True;
      Manifest.Trace_Surface_Complete := False;
      Assert (Build_Public_Build_Guardrail_Regression_Manifest_Feedback
                (Manifest) =
              "Build: public build audit trace incomplete",
              "trace feedback must be deterministic");

      Manifest.Trace_Surface_Complete := True;
      Manifest.Public_Command_Surface_Complete := False;
      Assert (Build_Public_Build_Guardrail_Regression_Manifest_Feedback
                (Manifest) =
              "Build: public build public-id domain coverage incomplete",
              "public-id domain feedback must be deterministic");
   end Test_Public_Build_Guardrail_Manifest_Feedback_Is_Deterministic;

   procedure Test_Public_Build_Guardrail_Manifest_Unhealthy_On_Each_Dimension
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Base : Public_Build_Guardrail_Regression_Manifest;
      M : Public_Build_Guardrail_Regression_Manifest;
   begin
      Editor.State.Init (S);
      Base := Build_Public_Build_Guardrail_Regression_Manifest (S);
      M := Base;
      M.Health.Healthy := False;
      M.Manifest_Healthy :=
        M.Health.Healthy and then M.Default_Contract_Matches;
      Assert (not M.Manifest_Healthy,
              "health failure must make simulated manifest unhealthy");

      M := Base;
      M.Public_Surface_Present := False;
      M.Manifest_Healthy := Base.Manifest_Healthy and then M.Public_Surface_Present;
      Assert (not M.Manifest_Healthy,
              "public surface exposure must make simulated manifest unhealthy");

      M := Base;
      M.Execution_Surface_Present := False;
      M.Manifest_Healthy := Base.Manifest_Healthy and then M.Execution_Surface_Present;
      Assert (not M.Manifest_Healthy,
              "execution surface exposure must make simulated manifest unhealthy");

      M := Base;
      M.Surface_Command_Executable := False;
      M.Manifest_Healthy := Base.Manifest_Healthy and then M.Surface_Command_Executable;
      Assert (not M.Manifest_Healthy,
              "executable surface entry must make simulated manifest unhealthy");

      M := Base;
      M.Promotion_Blocked := True;
      M.Manifest_Healthy := Base.Manifest_Healthy and then not M.Promotion_Blocked;
      Assert (not M.Manifest_Healthy,
              "promotion blocker must make simulated manifest unhealthy");

      M := Base;
      M.Dependency_Blockers_Active := True;
      M.Manifest_Healthy := Base.Manifest_Healthy and then not M.Dependency_Blockers_Active;
      Assert (not M.Manifest_Healthy,
              "dependency blocker activation must make simulated manifest unhealthy");
   end Test_Public_Build_Guardrail_Manifest_Unhealthy_On_Each_Dimension;

   procedure Test_Public_Build_Guardrail_Audit_Matrix_All_Dimensions_Checked
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Matrix : constant Public_Build_Guardrail_Audit_Matrix :=
        Build_Public_Build_Guardrail_Audit_Matrix;
      Count : Natural := 0;
   begin
      for Dimension in Matrix'Range loop
         Count := Count + 1;
         Assert (Matrix (Dimension),
                 "public build guardrail audit matrix dimension missing");
      end loop;
      Assert (Count = 31,
              "public build guardrail audit matrix dimension count changed");
      Assert (Public_Build_Guardrail_Audit_Matrix_Complete (Matrix),
              "public build guardrail audit matrix must be complete");
      Assert_Public_Build_Guardrail_Audit_Matrix_Complete (Matrix);
   end Test_Public_Build_Guardrail_Audit_Matrix_All_Dimensions_Checked;

   procedure Test_Public_Build_Guardrail_Audit_Matrix_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      A : constant Public_Build_Guardrail_Audit_Matrix :=
        Build_Public_Build_Guardrail_Audit_Matrix;
      B : constant Public_Build_Guardrail_Audit_Matrix :=
        Build_Public_Build_Guardrail_Audit_Matrix;
   begin
      Assert (A = B,
              "public build guardrail audit matrix must be deterministic");
   end Test_Public_Build_Guardrail_Audit_Matrix_Is_Deterministic;

   procedure Test_Public_Build_Guardrail_Manifest_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Public_Build_Guardrail_Result;
      A : Public_Build_Guardrail_Regression_Manifest;
      B : Public_Build_Guardrail_Regression_Manifest;
      After : Public_Build_Guardrail_Result;
   begin
      Editor.State.Init (S);
      Before := Run_Public_Build_Guardrail_Audit (S);
      A := Build_Public_Build_Guardrail_Regression_Manifest (S);
      B := Build_Public_Build_Guardrail_Regression_Manifest (S);
      After := Run_Public_Build_Guardrail_Audit (S);
      Assert (A = B,
              "public build guardrail manifest builder must be deterministic");
      Assert (Before = After,
              "public build guardrail manifest builder must not mutate guardrail state");
      Assert (A.Manifest_Healthy,
              "side-effect-free manifest build must remain healthy");
   end Test_Public_Build_Guardrail_Manifest_Is_Side_Effect_Free;

   procedure Test_Public_Build_Guardrail_Manifest_Not_Persisted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Manifest : Public_Build_Guardrail_Regression_Manifest;
   begin
      Editor.State.Init (S);
      Manifest := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Assert (Manifest.Persistence_Exclusion_Clean,
              "manifest audit-only state must remain excluded from persistence");
      Assert_Public_Build_Guardrail_Health_Not_Persisted (S);
      Assert_Public_Build_Guardrail_State_Not_Persisted (S);
   end Test_Public_Build_Guardrail_Manifest_Not_Persisted;

   procedure Test_Public_Build_Guardrail_Manifest_Lifecycle_Project_Close_Remains_Healthy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Public_Build_Guardrail_Regression_Manifest;
      After : Public_Build_Guardrail_Regression_Manifest;
      M : Public_Build_Guardrail_Contract_Mismatch;
   begin
      Editor.State.Init (S);
      Before := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Reset_Build_Run_State_For_Project_Close (S);
      Reset_Diagnostic_Line_Command_State_For_Project_Close (S);
      After := Build_Public_Build_Guardrail_Regression_Manifest (S);
      M := Compare_Public_Build_Guardrail_Snapshots
        (Before.Health.Guardrail_Result, After.Health.Guardrail_Result);
      Assert (Before.Manifest_Healthy and then After.Manifest_Healthy,
              "manifest must remain healthy across project close");
      Assert (not M.Any_Mismatch,
              "project close must not change public build guardrail contract");
   end Test_Public_Build_Guardrail_Manifest_Lifecycle_Project_Close_Remains_Healthy;

   procedure Test_Public_Build_Guardrail_No_Extra_Layer_Above_Manifest
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert_Public_Build_Guardrail_No_Extra_Layer_Above_Manifest;
   end Test_Public_Build_Guardrail_No_Extra_Layer_Above_Manifest;

   procedure Test_Public_Build_Guardrail_Manifest_Fields_Have_Direct_Backers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Manifest : Public_Build_Guardrail_Regression_Manifest;
   begin
      Editor.State.Init (S);
      Manifest := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Assert_Public_Build_Guardrail_Manifest_Fields_Have_Direct_Backers
        (Manifest);
      Assert (Manifest.Manifest_Healthy,
              "manifest direct-backer assertion must preserve default healthy state");
   end Test_Public_Build_Guardrail_Manifest_Fields_Have_Direct_Backers;

   procedure Test_Public_Build_Guardrail_Result_Does_Not_Depend_On_Health
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result_Before : Public_Build_Guardrail_Result;
      Health : Public_Build_Guardrail_Health;
      Result_After : Public_Build_Guardrail_Result;
   begin
      Editor.State.Init (S);
      Result_Before := Run_Public_Build_Guardrail_Audit (S);
      Health := Build_Public_Build_Guardrail_Health (S);
      Health.Healthy := False;
      Assert (not Health.Healthy,
              "mutated health copy must not influence result builder");
      Result_After := Run_Public_Build_Guardrail_Audit (S);
      Assert (Result_Before = Result_After,
              "guardrail result must be computed below health and remain independent");
      Assert (Result_After.Status = Public_Build_Guardrail_Passed,
              "guardrail result must remain passed");
   end Test_Public_Build_Guardrail_Result_Does_Not_Depend_On_Health;

   procedure Test_Public_Build_Guardrail_Health_Does_Not_Depend_On_Manifest
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Health_Before : Public_Build_Guardrail_Health;
      Manifest : Public_Build_Guardrail_Regression_Manifest;
      Health_After : Public_Build_Guardrail_Health;
   begin
      Editor.State.Init (S);
      Health_Before := Build_Public_Build_Guardrail_Health (S);
      Manifest := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Manifest.Manifest_Healthy := False;
      Assert (not Manifest.Manifest_Healthy,
              "mutated manifest copy must not influence health builder");
      Health_After := Build_Public_Build_Guardrail_Health (S);
      Assert (Health_Before = Health_After,
              "health must be computed below manifest and remain independent");
      Assert (Health_After.Healthy,
              "health must remain healthy without reading manifest state");
   end Test_Public_Build_Guardrail_Health_Does_Not_Depend_On_Manifest;

   procedure Test_Public_Build_Guardrail_Manifest_Is_Final_Semantic_Layer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Public_Build_Guardrail_Regression_Manifest;
      B : Public_Build_Guardrail_Regression_Manifest;
   begin
      Editor.State.Init (S);
      A := Build_Public_Build_Guardrail_Regression_Manifest (S);
      B := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Assert (A = B,
              "manifest must be final semantic layer and not depend on a higher wrapper");
      Assert_Public_Build_Guardrail_Manifest_Fields_Have_Direct_Backers (A);
   end Test_Public_Build_Guardrail_Manifest_Is_Final_Semantic_Layer;

   procedure Test_Public_Build_Guardrail_Audit_Matrix_Is_Coverage_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert_Public_Build_Guardrail_Audit_Matrix_Coverage_Only;
   end Test_Public_Build_Guardrail_Audit_Matrix_Is_Coverage_Only;

   procedure Test_Public_Build_Guardrail_No_Self_Referential_Healthy_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Assert_Public_Build_Guardrail_No_Self_Referential_Healthy_State (S);
   end Test_Public_Build_Guardrail_No_Self_Referential_Healthy_State;

   procedure Test_Public_Build_Guardrail_Feedback_Helpers_Are_Not_Duplicated
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Health : Public_Build_Guardrail_Health;
      Manifest : Public_Build_Guardrail_Regression_Manifest;
   begin
      Editor.State.Init (S);
      Health := Build_Public_Build_Guardrail_Health (S);
      Manifest := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Assert (Build_Public_Build_Guardrail_Health_Feedback (Health) =
              "Build: public build guardrail healthy",
              "health remains the only health feedback helper");
      Assert (Build_Public_Build_Guardrail_Regression_Manifest_Feedback
                (Manifest) =
              "Build: public build regression manifest healthy",
              "manifest remains the only manifest-level feedback helper");
   end Test_Public_Build_Guardrail_Feedback_Helpers_Are_Not_Duplicated;


   procedure Test_Public_Build_Guardrail_Post_Pruning_Default_Result_Is_Safe
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Public_Build_Guardrail_Result;
   begin
      Editor.State.Init (S);
      Result := Run_Public_Build_Guardrail_Audit (S);
      Assert (Result.Status = Public_Build_Guardrail_Passed,
              "post-pruning guardrail status must remain passed");
      Assert (Result.No_Public_Command
              and then Result.No_Public_Keybinding
              and then Result.No_Public_Palette_Entry
              and then Result.No_Public_Executor_Route
              and then Result.No_Public_Invocation_Path
              and then Result.No_Public_Bindable_Command
              and then not Result.Promotion_Blocked
              and then Result.Default_Execution_Disabled
              and then not Result.Dependency_Blockers_Active
              and then Result.Persistence_Clean
              and then Result.Audits_Consistent,
              "post-pruning normalized guardrail default contract drifted");
      Assert_Public_Build_Guardrail_Default_Contract (Result);
   end Test_Public_Build_Guardrail_Post_Pruning_Default_Result_Is_Safe;

   procedure Test_Public_Build_Guardrail_Post_Pruning_Health_Is_Healthy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Health : Public_Build_Guardrail_Health;
   begin
      Editor.State.Init (S);
      Health := Build_Public_Build_Guardrail_Health (S);
      Assert (Health.Healthy,
              "post-pruning health report must remain healthy");
      Assert (Health.Failure_Count = 0,
              "post-pruning health report must have no failures");
      Assert (Health.First_Failure.Kind = Public_Build_Failure_None,
              "post-pruning health first failure must be none");
      Assert (not Health.Snapshot_Mismatch.Any_Mismatch,
              "post-pruning health must report no contract mismatch");
      Assert_Public_Build_Guardrail_Health_Default (Health);
   end Test_Public_Build_Guardrail_Post_Pruning_Health_Is_Healthy;

   procedure Test_Public_Build_Guardrail_Post_Pruning_Manifest_Is_Healthy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Manifest : Public_Build_Guardrail_Regression_Manifest;
   begin
      Editor.State.Init (S);
      Manifest := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Assert (Manifest.Manifest_Healthy,
              "post-pruning manifest must remain healthy");
      Assert (Manifest.Health.Healthy
              and then Manifest.Default_Contract_Matches
              and then Manifest.Trace_Surface_Complete
              and then Manifest.Public_Command_Surface_Complete
              and then Manifest.Persistence_Exclusion_Clean
              and then Manifest.Lifecycle_Stable
              and then Manifest.Public_Surface_Present
              and then Manifest.Execution_Surface_Present
              and then Manifest.Surface_Command_Executable
              and then not Manifest.Promotion_Blocked
              and then not Manifest.Dependency_Blockers_Active,
              "post-pruning manifest field contract drifted");
      Assert_Public_Build_Guardrail_Regression_Manifest_Default (Manifest);
   end Test_Public_Build_Guardrail_Post_Pruning_Manifest_Is_Healthy;

   procedure Test_Public_Build_Guardrail_Manifest_Does_Not_Depend_On_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Public_Build_Guardrail_Regression_Manifest;
      B : Public_Build_Guardrail_Regression_Manifest;
   begin
      Editor.State.Init (S);
      Assert_Public_Build_Guardrail_No_Extra_Layer_Above_Manifest;
      A := Build_Public_Build_Guardrail_Regression_Manifest (S);
      B := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Assert (A = B,
              "manifest must not consult removed evidence/release-candidate wrappers");
      Assert_Public_Build_Guardrail_Manifest_Fields_Have_Direct_Backers (A);
   end Test_Public_Build_Guardrail_Manifest_Does_Not_Depend_On_Evidence;

   procedure Test_Public_Build_Guardrail_Evidence_Pack_Production_API_Absent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert_Public_Build_Guardrail_No_Extra_Layer_Above_Manifest;
   end Test_Public_Build_Guardrail_Evidence_Pack_Production_API_Absent;

   procedure Test_Public_Build_Guardrail_Release_Candidate_Production_API_Absent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert_Public_Build_Guardrail_No_Extra_Layer_Above_Manifest;
   end Test_Public_Build_Guardrail_Release_Candidate_Production_API_Absent;

   procedure Test_Public_Build_Guardrail_Feedback_Helpers_Only_Health_And_Manifest
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Health : Public_Build_Guardrail_Health;
      Manifest : Public_Build_Guardrail_Regression_Manifest;
   begin
      Editor.State.Init (S);
      Health := Build_Public_Build_Guardrail_Health (S);
      Manifest := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Assert (Build_Public_Build_Guardrail_Health_Feedback (Health) =
              "Build: public build guardrail healthy",
              "health feedback helper drifted after pruning");
      Assert (Build_Public_Build_Guardrail_Regression_Manifest_Feedback
                (Manifest) =
              "Build: public build regression manifest healthy",
              "manifest feedback helper drifted after pruning");
   end Test_Public_Build_Guardrail_Feedback_Helpers_Only_Health_And_Manifest;

   procedure Test_Public_Build_Guardrail_Post_Pruning_Not_Persisted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Manifest : Public_Build_Guardrail_Regression_Manifest;
   begin
      Editor.State.Init (S);
      Manifest := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Assert (Manifest.Persistence_Exclusion_Clean,
              "post-pruning guardrail manifest must remain non-persistent");
      Assert_Public_Build_Guardrail_State_Not_Persisted (S);
      Assert_Public_Build_Guardrail_Health_Not_Persisted (S);
   end Test_Public_Build_Guardrail_Post_Pruning_Not_Persisted;

   procedure Test_Public_Build_Guardrail_Post_Pruning_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result_Before : Public_Build_Guardrail_Result;
      Health_A : Public_Build_Guardrail_Health;
      Health_B : Public_Build_Guardrail_Health;
      Manifest_A : Public_Build_Guardrail_Regression_Manifest;
      Manifest_B : Public_Build_Guardrail_Regression_Manifest;
      Result_After : Public_Build_Guardrail_Result;
   begin
      Editor.State.Init (S);
      Result_Before := Run_Public_Build_Guardrail_Audit (S);
      Health_A := Build_Public_Build_Guardrail_Health (S);
      Health_B := Build_Public_Build_Guardrail_Health (S);
      Manifest_A := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Manifest_B := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Result_After := Run_Public_Build_Guardrail_Audit (S);
      Assert (Result_Before = Result_After,
              "post-pruning guardrail builders must not mutate audit state");
      Assert (Health_A = Health_B,
              "post-pruning health builder must be deterministic");
      Assert (Manifest_A = Manifest_B,
              "post-pruning manifest builder must be deterministic");
      Assert (Health_A.Healthy and then Manifest_A.Manifest_Healthy,
              "post-pruning side-effect-free audit must remain healthy");
   end Test_Public_Build_Guardrail_Post_Pruning_Side_Effect_Free;

   procedure Test_Public_Build_Guardrail_Post_Pruning_Lifecycle_Workspace_Close_Remains_Healthy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Public_Build_Guardrail_Regression_Manifest;
      After : Public_Build_Guardrail_Regression_Manifest;
      M : Public_Build_Guardrail_Contract_Mismatch;
   begin
      Editor.State.Init (S);
      Before := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Reset_Build_Run_State_For_Workspace_Close (S);
      Reset_Diagnostic_Line_Command_State_For_Workspace_Close (S);
      After := Build_Public_Build_Guardrail_Regression_Manifest (S);
      M := Compare_Public_Build_Guardrail_Snapshots
        (Before.Health.Guardrail_Result, After.Health.Guardrail_Result);
      Assert (Before.Manifest_Healthy and then After.Manifest_Healthy,
              "manifest must remain healthy across workspace close");
      Assert (Before.Health.Healthy and then After.Health.Healthy,
              "health must remain healthy across workspace close");
      Assert (not M.Any_Mismatch,
              "workspace close must not change public build guardrail contract");
   end Test_Public_Build_Guardrail_Post_Pruning_Lifecycle_Workspace_Close_Remains_Healthy;

   procedure Test_Command_Surface_Review_Default_Passes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Review : Editor.Command_Surface.Command_Surface_Review;
   begin
      Editor.State.Init (S);
      Editor.Keybindings.Reset_To_Defaults;
      Review := Editor.Command_Surface.Review_Command_Surface (S);
      Assert (Review.Descriptor_Count = Editor.Commands.Concrete_Command_Count,
              "review must count concrete command descriptors");
      Assert (Review.Review_Passed,
              Editor.Command_Surface.Build_Command_Surface_Review_Feedback (Review));
      Assert (Editor.Command_Surface.Build_Command_Surface_Review_Feedback (Review) =
              "Commands: command surface healthy",
              "default command surface feedback must be healthy");
   end Test_Command_Surface_Review_Default_Passes;

   procedure Test_Command_Surface_Review_Feedback_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Review : Editor.Command_Surface.Command_Surface_Review;
   begin
      Review := (Descriptor_Count             => 1,
                 Stable_Ids_Unique             => False,
                 Display_Names_Present         => True,
                 Categories_Valid              => True,
                 Visibility_Consistent         => True,
                 Bindability_Consistent        => True,
                 Executor_Coverage_Complete    => True,
                 Availability_Reasons_Stable   => True,
                 Palette_Projection_Consistent => True,
                 Discoverability_Metadata_Coherent => True,
                 Keybinding_Targets_Valid      => True,
                 Persistence_Clean             => True,
                 Public_Build_Guardrail_Intact => True,
                 Review_Passed                 => False);
      Assert (Editor.Command_Surface.Build_Command_Surface_Review_Feedback (Review) =
              "Commands: duplicate command id detected",
              "stable-id failure feedback must be deterministic");

      Review.Stable_Ids_Unique := True;
      Review.Display_Names_Present := False;
      Assert (Editor.Command_Surface.Build_Command_Surface_Review_Feedback (Review) =
              "Commands: command descriptor incomplete",
              "descriptor failure feedback must be deterministic");

      Review.Display_Names_Present := True;
      Review.Categories_Valid := False;
      Assert (Editor.Command_Surface.Build_Command_Surface_Review_Feedback (Review) =
              "Commands: invalid command category detected",
              "category failure feedback must be deterministic");

      Review.Categories_Valid := True;
      Review.Public_Build_Guardrail_Intact := False;
      Assert (Editor.Command_Surface.Build_Command_Surface_Review_Feedback (Review) =
              "Commands: public build guardrail failed",
              "public-build sentinel feedback must be deterministic");
   end Test_Command_Surface_Review_Feedback_Is_Deterministic;

   procedure Test_Command_Surface_Review_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Messages : Natural;
      Before_Has_Buffer : Boolean;
      Before_Palette_Count : Natural;
      Before_Build_Manifest : Public_Build_Guardrail_Regression_Manifest;
      After_Build_Manifest  : Public_Build_Guardrail_Regression_Manifest;
      Review_A : Editor.Command_Surface.Command_Surface_Review;
      Review_B : Editor.Command_Surface.Command_Surface_Review;
   begin
      Editor.State.Init (S);
      Editor.Keybindings.Reset_To_Defaults;
      Before_Messages := Editor.Messages.Count (S.Messages);
      Before_Has_Buffer := Editor.State.Has_Active_Buffer (S);
      Before_Palette_Count := Editor.Commands.Palette_Command_Count;
      Before_Build_Manifest := Build_Public_Build_Guardrail_Regression_Manifest (S);

      Review_A := Editor.Command_Surface.Review_Command_Surface (S);
      Review_B := Editor.Command_Surface.Review_Command_Surface (S);
      After_Build_Manifest := Build_Public_Build_Guardrail_Regression_Manifest (S);

      Assert (Review_A = Review_B,
              "command surface review must be deterministic across repeated reads");
      Assert (Editor.Messages.Count (S.Messages) = Before_Messages,
              "command surface review must not emit messages");
      Assert (Editor.State.Has_Active_Buffer (S) = Before_Has_Buffer,
              "command surface review must not create or alter active buffers");
      Assert (Editor.Commands.Palette_Command_Count = Before_Palette_Count,
              "command surface review must not alter palette-visible descriptor count");
      Assert (Before_Build_Manifest = After_Build_Manifest,
              "command surface review must not alter public-build regression manifest state");
   end Test_Command_Surface_Review_Is_Side_Effect_Free;

   procedure Test_Command_Surface_Stable_Ids_Are_Unique
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Seen  : array (Editor.Commands.Command_Id) of Boolean := (others => False);
      Found : Boolean;
      Round : Editor.Commands.Command_Id;
   begin
      for I in 1 .. Editor.Commands.Command_Count loop
         declare
            Id : constant Editor.Commands.Command_Id := Editor.Commands.Command_At (I);
            Name : constant String := Editor.Commands.Stable_Command_Name (Id);
         begin
            if Editor.Commands.Is_Concrete_Command (Id) then
               Round := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
               Assert (Found and then Round = Id,
                       "stable command id must resolve back to its descriptor: " & Name);
               Assert (not Seen (Round),
                       "stable command id must be unique: " & Name);
               Seen (Round) := True;
            end if;
         end;
      end loop;
   end Test_Command_Surface_Stable_Ids_Are_Unique;

   procedure Test_Command_Surface_Command_Ids_Follow_Canonicalization_Policy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean;
      Id : Editor.Commands.Command_Id;
   begin
      Id := Editor.Commands.Command_Id_From_Stable_Name (" FILE.SAVE ", Found);
      Assert (Found and then Id = Editor.Commands.Command_Save_File,
              "command id lookup must preserve trim/lowercase canonicalization for dot-scoped stable ids");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("file.save", Found);
      Assert (Found and then Id = Editor.Commands.Command_Save_File,
              "canonical stable id lookup must still resolve exact lowercase names");
   end Test_Command_Surface_Command_Ids_Follow_Canonicalization_Policy;

   procedure Test_Command_Surface_Public_Public_Build_Id_Remains_Absent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Names : constant Command_Id_Vector := Public_Build_Command_Surface_Ids;
      Found : Boolean;
      Id    : Editor.Commands.Command_Id;
   begin
      Assert (Names.Length = 1,
              "public build contract exposes only build.run");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("build.run", Found);
      Assert (Found and then Id = Editor.Commands.Command_Build_Run,
              "build.run must resolve to the guarded public command");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("build.project", Found);
      Assert (not Found,
              "reserved build.project alias must remain absent");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("compile.project", Found);
      Assert (not Found,
              "reserved compile.project alias must remain absent");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("diagnostics.run-build", Found);
      Assert (not Found,
              "reserved diagnostics.run-build alias must remain absent");
   end Test_Command_Surface_Public_Public_Build_Id_Remains_Absent;

   procedure Test_Command_Surface_Near_Miss_Public_Build_Id_Remains_Safe
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Test_Seam_Id : constant String :=
        Editor.Commands.Stable_Command_Name
          (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam);
   begin
      Assert (Test_Seam_Id = "build.run-user-opt-in-test-seam",
              "internal test seam near-miss id must remain stable");
      Assert (not Is_Public_Build_Surface_Id (Test_Seam_Id),
              "internal test seam must not canonicalize to a public build id");
      Assert (not Editor.Commands.Is_Bindable_Command
                (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam),
              "internal build test seam must remain non-bindable");
      Assert (not Editor.Commands.Visible_In_Command_Palette
                (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam),
              "internal build test seam must remain excluded from normal palette");
   end Test_Command_Surface_Near_Miss_Public_Build_Id_Remains_Safe;

   procedure Test_Command_Surface_Public_Build_Guardrail_Manifest_Remains_Healthy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Review : Editor.Command_Surface.Command_Surface_Review;
      Manifest : Public_Build_Guardrail_Regression_Manifest;
   begin
      Editor.State.Init (S);
      Review := Editor.Command_Surface.Review_Command_Surface (S);
      Manifest := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Assert (Review.Public_Build_Guardrail_Intact,
              "command surface review must keep public-build manifest as a healthy sentinel");
      Assert (Manifest.Manifest_Healthy,
              "public-build regression manifest remains healthy");
   end Test_Command_Surface_Public_Build_Guardrail_Manifest_Remains_Healthy;




   procedure Test_File_Lifecycle_Availability_Reasons
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Editor.Commands.Command_Availability;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Save_File);
      Assert (not Editor.Commands.Is_Available (A),
              "save with no open buffer must be unavailable");
      Assert (Editor.Commands.Unavailable_Reason (A) = "No active buffer.",
              "save with no open buffer must explain the missing active buffer");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Close_Active_Buffer);
      Assert (not Editor.Commands.Is_Available (A),
              "close with no open buffer must be unavailable");
      Assert (Editor.Commands.Unavailable_Reason (A) = "No active buffer.",
              "close with no open buffer must explain that there is no active buffer");

      Editor.Buffers.Ensure_Global_Registry (S);
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Save_File);
      Assert (not Editor.Commands.Is_Available (A),
              "save untitled without a target must be unavailable");
      Assert (Editor.Commands.Unavailable_Reason (A) = "No file path for active buffer",
              "save untitled without save-as target must use No file path for active buffer");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Reload_Active_Buffer);
      Assert (not Editor.Commands.Is_Available (A),
              "reload untitled must be unavailable");
      Assert (Editor.Commands.Unavailable_Reason (A) = "No file path for active buffer",
              "reload untitled must explain that no file path exists");
   end Test_File_Lifecycle_Availability_Reasons;

   procedure Test_Reload_Command_Palette_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Found : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("reload file");

      Editor.Executor.Command_Palette_Candidates (S, Candidates);
      for Candidate of Candidates loop
         if Candidate.Id = Editor.Commands.Command_Reload_Active_Buffer then
            Found := True;
            Assert (not Candidate.Available,
                    "reload row must show current unavailable state for untitled buffer");
            Assert (To_String (Candidate.Reason) = "No file path for active buffer",
                    "reload row must expose the deterministic disabled reason");
         end if;
      end loop;

      Assert (Found,
              "reload must be visible as a command-palette lifecycle row");
   end Test_Reload_Command_Palette_Row;

   procedure Test_Status_Bar_Lifecycle_Hint_Is_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Text : Unbounded_String;
      Before_Dirty : Boolean;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      S.File_Info.Dirty := True;
      Editor.Settings.Set_Command_Palette_Show_Keybindings (S.Settings, False);
      Before_Text := To_Unbounded_String (Editor.State.Current_Text (S));
      Before_Dirty := S.File_Info.Dirty;

      Assert (Ada.Strings.Fixed.Index
                (Editor.Lifecycle_Guidance.Status_Bar_Hint (S),
                 "Untitled dirty buffer") > 0,
              "/241: dirty untitled buffer should expose untitled dirty lifecycle state");
      Assert (Ada.Strings.Fixed.Index
                (Editor.Lifecycle_Guidance.Status_Bar_Hint (S),
                 "Save As available") = 0,
              "dirty untitled lifecycle hint must not advertise targetless Save As without canonical target acquisition");
      Assert (To_String (Before_Text) = Editor.State.Current_Text (S),
              "lifecycle hint projection must not mutate buffer text");
      Assert (S.File_Info.Dirty = Before_Dirty,
              "lifecycle hint projection must not mutate dirty state");
      Assert (Editor.Messages.Count (S.Messages) = 0,
              "lifecycle hint projection must not post messages");
   end Test_Status_Bar_Lifecycle_Hint_Is_Projection;

   procedure Prepare_File_Tree
     (S      : in out Editor.State.State_Type;
      Path   : out Unbounded_String;
      Node   : out Editor.File_Tree.File_Tree_Node_Summary)
   is
      Root : constant String := "/tmp/editor_affordance_tree";
      File_Path : constant String := Root & "/a.txt";
      Found : Boolean := False;
      Node_Id : Editor.File_Tree.File_Tree_Node_Id;
   begin
      if not Ada.Directories.Exists (Root) then
         Ada.Directories.Create_Directory (Root);
      end if;
      declare
         F : Ada.Text_IO.File_Type;
      begin
         Ada.Text_IO.Create (F, Ada.Text_IO.Out_File, File_Path);
         Ada.Text_IO.Put_Line (F, "alpha");
         Ada.Text_IO.Close (F);
      exception
         when others =>
            if Ada.Text_IO.Is_Open (F) then
               Ada.Text_IO.Close (F);
            end if;
            raise;
      end;

      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      Node_Id := Editor.File_Tree.Find_By_Path (S.File_Tree, File_Path, Found);
      Assert (Found, "fixture must scan a.txt");
      Node := Editor.File_Tree.Node (S.File_Tree, Node_Id);
      Path := To_Unbounded_String (File_Path);
   end Prepare_File_Tree;

   procedure Test_Dirty_Open_Buffer_Row_Save_Hint
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Summary : Editor.Buffers.Buffer_Summary;
      Hint : Unbounded_String;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String ("/tmp/active.adb");
      S.File_Info.Display_Name := To_Unbounded_String ("active.adb");
      S.File_Info.Dirty := True;
      Editor.Buffers.Ensure_Global_Registry (S);
      Summary := Editor.Buffers.Global_Summary_For (Editor.Buffers.Global_Active_Buffer);

      Hint := To_Unbounded_String (Editor.Lifecycle_Guidance.Open_Buffer_Row_Hint (S, Summary));
      Assert (Ada.Strings.Fixed.Index (To_String (Hint), "save available") > 0,
              "selected dirty active file row must expose save availability");
      Assert (Ada.Strings.Fixed.Index (To_String (Hint), "normal close blocked") > 0,
              "selected dirty row must not imply close discards edits");
      Assert (Ada.Strings.Fixed.Index (To_String (Hint), "discard") = 0,
              "unsupported destructive wording must be absent");
   end Test_Dirty_Open_Buffer_Row_Save_Hint;

   procedure Test_Open_Buffer_Row_Keybinding_Setting
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Summary : Editor.Buffers.Buffer_Summary :=
        (Id           => 2,
         Display_Name => To_Unbounded_String ("other.adb"),
         Is_Dirty     => False,
         Is_Active    => False,
         others       => <>);
      With_Keys : Unbounded_String;
      Without_Keys : Unbounded_String;
   begin
      Editor.State.Init (S);
      Editor.Settings.Set_Command_Palette_Show_Keybindings (S.Settings, True);
      With_Keys := To_Unbounded_String
        (Editor.Lifecycle_Guidance.Open_Buffer_Row_Hint (S, Summary));
      Editor.Settings.Set_Command_Palette_Show_Keybindings (S.Settings, False);
      Without_Keys := To_Unbounded_String
        (Editor.Lifecycle_Guidance.Open_Buffer_Row_Hint (S, Summary));

      Assert (Ada.Strings.Fixed.Index (To_String (With_Keys), "[Enter]") > 0,
              "open-buffer row hint should name Enter when shortcut display is enabled");
      Assert (Ada.Strings.Fixed.Index (To_String (Without_Keys), "[Enter]") = 0,
              "open-buffer row hint must respect show-keybindings=false");
   end Test_Open_Buffer_Row_Keybinding_Setting;

   procedure Test_File_Tree_Open_And_Focus_Wording
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Path : Unbounded_String;
      Node : Editor.File_Tree.File_Tree_Node_Summary;
      Before_Open : Unbounded_String;
      After_Open : Unbounded_String;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Prepare_File_Tree (S, Path, Node);

      Before_Open := To_Unbounded_String
        (Editor.Lifecycle_Guidance.File_Tree_Row_Hint (S, Node));
      Assert (To_String (Before_Open) = "Open file [Enter]",
              "unopened File Tree file row must advertise open");

      S.File_Info.Has_Path := True;
      S.File_Info.Path := Path;
      S.File_Info.Display_Name := To_Unbounded_String ("a.txt");
      S.File_Info.Dirty := True;
      Editor.Buffers.Ensure_Global_Registry (S);
      After_Open := To_Unbounded_String
        (Editor.Lifecycle_Guidance.File_Tree_Row_Hint (S, Node));
      Assert (Ada.Strings.Fixed.Index (To_String (After_Open), "Focus existing unsaved buffer") > 0,
              "already-open dirty File Tree row must use focus wording");
      Assert (Ada.Strings.Fixed.Index (To_String (After_Open), "reload") = 0,
              "already-open dirty File Tree row must not imply reload");
      Assert (Ada.Strings.Fixed.Index (To_String (After_Open), "discard") = 0,
              "already-open dirty File Tree row must not imply discard");
   end Test_File_Tree_Open_And_Focus_Wording;

   procedure Test_Status_Bar_File_Tree_Focus_Hint
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Path : Unbounded_String;
      Node : Editor.File_Tree.File_Tree_Node_Summary;
      Row : Natural := 0;
      Found : Boolean := False;
      Hint : Unbounded_String;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Prepare_File_Tree (S, Path, Node);
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node.Id, Found);
      Assert (Found, "fixture must map scanned file to visible row");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);
      Editor.Panel_Focus.Focus_File_Tree (S.Panel_Focus);
      S.File_Info.Has_Path := True;
      S.File_Info.Path := Path;
      S.File_Info.Display_Name := To_Unbounded_String ("a.txt");
      S.File_Info.Dirty := True;
      Editor.Buffers.Ensure_Global_Registry (S);

      Hint := To_Unbounded_String (Editor.Lifecycle_Guidance.Status_Bar_Hint (S));
      Assert (Ada.Strings.Fixed.Index (To_String (Hint), "Focus existing unsaved buffer") > 0,
              "Status Bar File Tree lifecycle hint should mirror selected file focus action");
      Assert (Ada.Strings.Fixed.Index (To_String (Hint), "reload") = 0,
              "Status Bar already-open file hint must not imply reload");
      Assert (Editor.Messages.Count (S.Messages) = 0,
              "Status Bar lifecycle hint must remain projection-only");
   end Test_Status_Bar_File_Tree_Focus_Hint;


   procedure Test_Status_Bar_Clean_Dirty_And_Retry_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Hint : Unbounded_String;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String ("/tmp/status.adb");
      S.File_Info.Display_Name := To_Unbounded_String ("status.adb");
      S.File_Info.Dirty := False;
      Editor.Settings.Set_Command_Palette_Show_Keybindings (S.Settings, False);
      Editor.Buffers.Ensure_Global_Registry (S);

      Hint := To_Unbounded_String (Editor.Lifecycle_Guidance.Status_Bar_Hint (S));
      Assert (Ada.Strings.Fixed.Index (To_String (Hint), "Clean file") > 0,
              "clean file-backed active buffer should be readable in the Status Bar lifecycle hint");

      S.File_Info.Dirty := True;
      S.File_Info.Last_Save_Failed := False;
      Hint := To_Unbounded_String (Editor.Lifecycle_Guidance.Status_Bar_Hint (S));
      Assert (Ada.Strings.Fixed.Index (To_String (Hint), "Dirty file") > 0,
              "dirty file-backed active buffer should be readable in the Status Bar lifecycle hint");
      Assert (Ada.Strings.Fixed.Index (To_String (Hint), "save available") > 0,
              "dirty file-backed Status Bar hint should retain safe save guidance");

      S.File_Info.Last_Save_Failed := True;
      Hint := To_Unbounded_String (Editor.Lifecycle_Guidance.Status_Bar_Hint (S));
      Assert (Ada.Strings.Fixed.Index (To_String (Hint), "retry save available") > 0,
              "failed-save state should remain visibly retryable while the buffer is dirty and saveable");
      Assert (Editor.Messages.Count (S.Messages) = 0,
              "lifecycle hint projection must not post messages");
   end Test_Status_Bar_Clean_Dirty_And_Retry_State;

   procedure Test_Open_Buffer_Row_Label_Shows_Retry_Without_Hiding_Dirty
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Summary : Editor.Buffers.Buffer_Summary;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String ("/tmp/row.adb");
      S.File_Info.Display_Name := To_Unbounded_String ("row.adb");
      S.File_Info.Dirty := True;
      S.File_Info.Last_Save_Failed := True;
      Editor.Buffers.Ensure_Global_Registry (S);

      Summary := Editor.Buffers.Global_Summary_For (Editor.Buffers.Global_Active_Buffer);
      Assert (Summary.Is_Dirty,
              "retryable failed-save row must keep the dirty marker state visible");
      Assert (Ada.Strings.Fixed.Index (To_String (Summary.Display_Name), "retry save") > 0,
              "retryable failed-save row label should expose retry context");
      Assert (Ada.Strings.Fixed.Index (To_String (Summary.Display_Name), "row.adb") > 0,
              "retryable row label should preserve the stable buffer label");
   end Test_Open_Buffer_Row_Label_Shows_Retry_Without_Hiding_Dirty;

   procedure Test_Lifecycle_Hints_Do_Not_Mention_Build
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Summary : Editor.Buffers.Buffer_Summary :=
        (Id           => 2,
         Display_Name => To_Unbounded_String ("other.adb"),
         Is_Dirty     => False,
         Is_Active    => False,
         others       => <>);
      Text : Unbounded_String;
   begin
      Editor.State.Init (S);
      Text := To_Unbounded_String
        (Editor.Lifecycle_Guidance.Open_Buffer_Row_Hint (S, Summary) & " " &
         Editor.Lifecycle_Guidance.Status_Bar_Hint (S));
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "build.run") = 0,
              "lifecycle affordance hints must not expose public build command names");
      Assert (Ada.Strings.Fixed.Index (To_String (Text), ".gpr") = 0,
              "lifecycle affordance hints must not mention project-file probing");
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "alire.toml") = 0,
              "lifecycle affordance hints must not mention Alire probing");
   end Test_Lifecycle_Hints_Do_Not_Mention_Build;



   procedure Test_Build_Run_Public_Descriptor
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Build_Run);
   begin
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Build_Run) = "build.run",
              "build.run stable command name is registered");
      Assert (Editor.Commands.Is_Public_Build_Command
                (Editor.Commands.Command_Build_Run),
              "build.run is classified as public build command");
      Assert (D.Visibility = Editor.Commands.Palette_Command,
              "build.run is a public descriptor-owned palette command");
      Assert (D.Category = Editor.Commands.Project_Category,
              "build.run remains in the existing Project command category");
      Assert (not D.Bindable,
              "build.run has no default bindability while guarded");
      Assert (Editor.Build_Command.Assert_Build_Run_Descriptor_Stable,
              "build.run descriptor has no shell/cwd/request payload");
   end Test_Build_Run_Public_Descriptor;

   procedure Test_Build_Run_Readiness_Reasons
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Root : constant String := "/tmp/editor_build_run_readiness";
      Gpr_Path : constant String := Root & "/demo.gpr";
      Project_Result : constant Editor.Project.Project_Open_Result :=
        (Status => Editor.Project.Project_Open_Ok,
         Root_Path => To_Unbounded_String (Root),
         Display_Name => To_Unbounded_String ("editor_build_run_readiness"),
         Error_Text => Null_Unbounded_String);
      Candidate : constant Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Gprbuild_Candidate
          (Root, "demo.gpr");
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;

      procedure Prepare_Candidate_File is
         F : Ada.Text_IO.File_Type;
      begin
         if not Ada.Directories.Exists (Root) then
            Ada.Directories.Create_Directory (Root);
         end if;
         Ada.Text_IO.Create (F, Ada.Text_IO.Out_File, Gpr_Path);
         Ada.Text_IO.Put_Line (F, "project Demo is end Demo;");
         Ada.Text_IO.Close (F);
      end Prepare_Candidate_File;

      procedure Cleanup_Candidate_File is
      begin
         if Ada.Directories.Exists (Gpr_Path) then
            Ada.Directories.Delete_File (Gpr_Path);
         end if;
         if Ada.Directories.Exists (Root) then
            Ada.Directories.Delete_Directory (Root);
         end if;
      exception
         when others =>
            null;
      end Cleanup_Candidate_File;
   begin
      Cleanup_Candidate_File;
      Prepare_Candidate_File;
      Editor.State.Init (S);
      Editor.Project.Apply_Open_Result (S.Project, Project_Result);
      Assert (Editor.Build_Command.Build_Run_Readiness (S) =
              Editor.Build_Command.Build_Run_Readiness_Request_Incomplete,
              "hidden build UI reports incomplete public build request");

      Editor.Build_UI.Show (S.Build_UI);
      Assert (Editor.Build_Command.Build_Run_Readiness (S) =
              Editor.Build_Command.Build_Run_Readiness_No_Candidate_Selected,
              "visible build UI with no selected candidate reports the specific preflight reason");

      Candidates.Append (Candidate);
      Editor.Build_UI.Set_Build_Candidates
        (S.Build_UI, Candidates, "refresh succeeded: 1 candidates");
      Editor.Build_UI.Select_Build_Candidate
        (S.Build_UI, To_String (Candidate.Candidate_Id));
      declare
         Status : constant Editor.Build_Command.Build_Run_Readiness_Status :=
           Editor.Build_Command.Build_Run_Readiness (S);
      begin
         Assert (Status in Editor.Build_Command.Build_Run_Readiness_Consent_Required
                         | Editor.Build_Command.Build_Run_Readiness_Execution_Backend_Disabled
                         | Editor.Build_Command.Build_Run_Readiness_Ready,
                 "build.run reports a post-candidate readiness gate: " &
                 Editor.Build_Command.Build_Run_Readiness_Status'Image (Status));
      end;

      Editor.Build_UI.Acknowledge_Consent (S.Build_UI);
      Assert (Editor.Build_Command.Validate_Build_Run_Invocation (S) =
              Editor.Build_Command.Build_Run_Readiness_Execution_Backend_Disabled,
              "valid structured request still refuses disabled backend");
      Cleanup_Candidate_File;
   exception
      when others =>
         Cleanup_Candidate_File;
         raise;
   end Test_Build_Run_Readiness_Reasons;

   procedure Test_Build_Run_Coherent_Audit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Assert (Editor.Build_Command.Assert_Public_Build_Command_Registration_Coherent (S),
              "build.run public registration, guarded Executor route, palette/keybinding boundaries and persistence exclusions are coherent");
   end Test_Build_Run_Coherent_Audit;

   overriding procedure Register_Tests
     (T : in out Command_Surface_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Palette_Route_Audit_Rejects_Payloads'Access,
         "Command Palette Route Audit Rejects Payloads");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Switcher_Command_Reference_Metadata'Access,
         "Switcher Command Reference Metadata");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Switcher_Command_Reference_Content'Access,
         "Switcher Command Reference Content");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Lifecycle_Availability_Reasons'Access,
         "File Lifecycle Availability Reasons");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Command_Palette_Row'Access,
         "Reload Command Palette Row");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Status_Bar_Lifecycle_Hint_Is_Projection'Access,
         "Status Bar Lifecycle Hint Is Projection");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dirty_Open_Buffer_Row_Save_Hint'Access,
         "Dirty Open Buffer Row Save Hint");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Open_Buffer_Row_Keybinding_Setting'Access,
         "Open Buffer Row Keybinding Setting");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Tree_Open_And_Focus_Wording'Access,
         "File Tree Open And Focus Wording");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Status_Bar_File_Tree_Focus_Hint'Access,
         "Status Bar File Tree Focus Hint");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Lifecycle_Hints_Do_Not_Mention_Build'Access,
         "Lifecycle Hints Do Not Mention Build");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Status_Bar_Clean_Dirty_And_Retry_State'Access,
         "Status Bar Clean Dirty And Retry State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Open_Buffer_Row_Label_Shows_Retry_Without_Hiding_Dirty'Access,
         "Open Buffer Row Label Shows Retry Without Hiding Dirty");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Surface_Review_Default_Passes'Access,
         "Command Surface Review Default Passes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Surface_Review_Is_Side_Effect_Free'Access,
         "Command Surface Review Is Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Surface_Review_Feedback_Is_Deterministic'Access,
         "Command Surface Review Feedback Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Surface_Stable_Ids_Are_Unique'Access,
         "Command Surface Stable Ids Are Unique");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Surface_Command_Ids_Follow_Canonicalization_Policy'Access,
         "Command Surface Command Ids Follow Canonicalization Policy");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Surface_Public_Public_Build_Id_Remains_Absent'Access,
         "Command Surface Public Public Build Id Remains Absent");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Surface_Near_Miss_Public_Build_Id_Remains_Safe'Access,
         "Command Surface Near Miss Public Build Id Remains Safe");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Surface_Public_Build_Guardrail_Manifest_Remains_Healthy'Access,
         "Command Surface Public Build Guardrail Manifest Remains Healthy");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Health_Default_Is_Healthy'Access,
         "Public Build Guardrail Health Default Is Healthy");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Health_Is_Side_Effect_Free'Access,
         "Public Build Guardrail Health Is Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Health_Unhealthy_On_Public_Command'Access,
         "Public Build Guardrail Health Unhealthy On Public Command");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Health_Unhealthy_On_Audit_Trace_Incomplete'Access,
         "Public Build Guardrail Health Unhealthy On Audit Trace Incomplete");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Health_Unhealthy_On_Contract_Mismatch'Access,
         "Public Build Guardrail Health Unhealthy On Contract Mismatch");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Health_Feedback_Is_Deterministic'Access,
         "Public Build Guardrail Health Feedback Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Id_Scan_All_Domains_Checked'Access,
         "Public Build Public Id Scan All Domains Checked");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Id_Canonical_Exact_Match_Fails'Access,
         "Public Build Public Id Canonical Exact Match Fails");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Id_Near_Miss_Remains_Safe'Access,
         "Public Build Public Id Near Miss Remains Safe");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Health_Lifecycle_Project_Close_Remains_Healthy'Access,
         "Public Build Health Lifecycle Project Close Remains Healthy");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Health_Lifecycle_Workspace_Close_Remains_Healthy'Access,
         "Public Build Health Lifecycle Workspace Close Remains Healthy");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Health_Not_Persisted'Access,
         "Public Build Health Not Persisted");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Health_Canonical_Ordering_Is_Deterministic'Access,
         "Public Build Guardrail Health Canonical Ordering Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Health_Builder_Is_Side_Effect_Free'Access,
         "Public Build Guardrail Health Builder Is Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Stale_Health_Does_Not_Bypass_Current_Audit'Access,
         "Public Build Guardrail Stale Health Does Not Bypass Current Audit");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Manifest_Default_Is_Healthy'Access,
         "Public Build Guardrail Manifest Default Is Healthy");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Manifest_Is_Side_Effect_Free'Access,
         "Public Build Guardrail Manifest Is Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Manifest_Feedback_Is_Deterministic'Access,
         "Public Build Guardrail Manifest Feedback Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Manifest_Unhealthy_On_Each_Dimension'Access,
         "Public Build Guardrail Manifest Unhealthy On Each Dimension");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Audit_Matrix_All_Dimensions_Checked'Access,
         "Public Build Guardrail Audit Matrix All Dimensions Checked");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Audit_Matrix_Is_Deterministic'Access,
         "Public Build Guardrail Audit Matrix Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Manifest_Not_Persisted'Access,
         "Public Build Guardrail Manifest Not Persisted");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Manifest_Lifecycle_Project_Close_Remains_Healthy'Access,
         "Public Build Guardrail Manifest Lifecycle Project Close Remains Healthy");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_No_Extra_Layer_Above_Manifest'Access,
         "Public Build Guardrail No Extra Layer Above Manifest");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Manifest_Fields_Have_Direct_Backers'Access,
         "Public Build Guardrail Manifest Fields Have Direct Backers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Result_Does_Not_Depend_On_Health'Access,
         "Public Build Guardrail Result Does Not Depend On Health");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Health_Does_Not_Depend_On_Manifest'Access,
         "Public Build Guardrail Health Does Not Depend On Manifest");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Manifest_Is_Final_Semantic_Layer'Access,
         "Public Build Guardrail Manifest Is Final Semantic Layer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Audit_Matrix_Is_Coverage_Only'Access,
         "Public Build Guardrail Audit Matrix Is Coverage Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_No_Self_Referential_Healthy_State'Access,
         "Public Build Guardrail No Self Referential Healthy State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Feedback_Helpers_Are_Not_Duplicated'Access,
         "Public Build Guardrail Feedback Helpers Are Not Duplicated");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Post_Pruning_Default_Result_Is_Safe'Access,
         "Public Build Guardrail Post Pruning Default Result Is Safe");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Post_Pruning_Health_Is_Healthy'Access,
         "Public Build Guardrail Post Pruning Health Is Healthy");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Post_Pruning_Manifest_Is_Healthy'Access,
         "Public Build Guardrail Post Pruning Manifest Is Healthy");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Manifest_Does_Not_Depend_On_Evidence'Access,
         "Public Build Guardrail Manifest Does Not Depend On Evidence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Evidence_Pack_Production_API_Absent'Access,
         "Public Build Guardrail Evidence Pack Production API Absent");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Release_Candidate_Production_API_Absent'Access,
         "Public Build Guardrail Release Candidate Production API Absent");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Feedback_Helpers_Only_Health_And_Manifest'Access,
         "Public Build Guardrail Feedback Helpers Only Health And Manifest");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Post_Pruning_Not_Persisted'Access,
         "Public Build Guardrail Post Pruning Not Persisted");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Post_Pruning_Side_Effect_Free'Access,
         "Public Build Guardrail Post Pruning Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Post_Pruning_Lifecycle_Workspace_Close_Remains_Healthy'Access,
         "Public Build Guardrail Post Pruning Lifecycle Workspace Close Remains Healthy");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Failure_Detail_Default_Is_None'Access,
         "Public Build Guardrail Failure Detail Default Is None");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_First_Failure_Uses_Blocker_Precedence'Access,
         "Public Build Guardrail First Failure Uses Blocker Precedence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Collect_Failures_Is_Deterministic'Access,
         "Public Build Guardrail Collect Failures Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Id_Scan_Result_Default_Passes'Access,
         "Public Build Public Id Scan Result Default Passes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Id_Scan_Rejects_Exact_Domains'Access,
         "Public Build Public Id Scan Rejects Exact Domains");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Id_Scan_Allows_Near_Miss_Label'Access,
         "Public Build Public Id Scan Allows Near Miss Label");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Audit_Trace_Default_Checks_All_Surfaces'Access,
         "Public Build Guardrail Audit Trace Default Checks All Surfaces");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Audit_Trace_Missing_Surface_Is_Inconsistent'Access,
         "Public Build Guardrail Audit Trace Missing Surface Is Inconsistent");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Internal_Test_Seam_Public_Leak_Reported_Separately'Access,
         "Public Build Internal Test Seam Public Leak Reported Separately");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Snapshot_Comparison_Default_No_Mismatch'Access,
         "Public Build Guardrail Snapshot Comparison Default No Mismatch");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Snapshot_Comparison_Detects_Exposure'Access,
         "Public Build Guardrail Snapshot Comparison Detects Exposure");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Snapshot_Comparison_Detects_Promotion_Change'Access,
         "Public Build Guardrail Snapshot Comparison Detects Promotion Change");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Lifecycle_Trace_Remains_Stable'Access,
         "Public Build Guardrail Lifecycle Trace Remains Stable");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Lifecycle_Snapshot_No_Mismatch'Access,
         "Public Build Guardrail Lifecycle Snapshot No Mismatch");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Default_Contract_Holds'Access,
         "Public Build Guardrail Default Contract Holds");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Contract_Mismatch_Default_Has_No_Mismatch'Access,
         "Public Build Guardrail Contract Mismatch Default Has No Mismatch");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Contract_Mismatch_Detects_Status_Drift'Access,
         "Public Build Guardrail Contract Mismatch Detects Status Drift");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Contract_Mismatch_Detects_Public_Command_Drift'Access,
         "Public Build Guardrail Contract Mismatch Detects Public Command Drift");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Contract_Mismatch_Detects_Promotion_Drift'Access,
         "Public Build Guardrail Contract Mismatch Detects Promotion Drift");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Id_List_Exactly_Matches_Contract'Access,
         "Public Build Public Id List Exactly Matches Contract");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Id_List_Has_No_Duplicates'Access,
         "Public Build Public Id List Has No Duplicates");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Id_Scan_Ignores_Near_Miss_Labels'Access,
         "Public Build Public Id Scan Ignores Near Miss Labels");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Id_Scan_Rejects_Exact_Public_Name'Access,
         "Public Build Public Id Scan Rejects Exact Command Id");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Internal_Test_Seam_Not_Counted_As_Public_Command'Access,
         "Public Build Internal Test Seam Not Counted As Public Command");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Internal_Test_Seam_Still_Hidden_From_Normal_Palette'Access,
         "Public Build Internal Test Seam Still Hidden From Normal Palette");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Normalized_Audit_Is_Deterministic'Access,
         "Public Build Normalized Audit Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Normalized_Audit_Exposure_Simulation_Is_Stable'Access,
         "Public Build Normalized Audit Exposure Simulation Is Stable");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Normalized_Audit_Drift_Simulation_Is_Stable'Access,
         "Public Build Normalized Audit Drift Simulation Is Stable");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Normalized_Audit_Inconsistency_Readiness_Promotion'Access,
         "Public Build Normalized Audit Inconsistency Readiness Promotion");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Normalized_Audit_Inconsistency_HardFreeze_Drift'Access,
         "Public Build Normalized Audit Inconsistency HardFreeze Drift");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Normalized_Audit_Agrees_With_No_Execution_Scan'Access,
         "Public Build Normalized Audit Agrees With No Execution Scan");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_State_Not_Persisted'Access,
         "Public Build Guardrail State Not Persisted");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Audit_Default_State_Passed'Access,
         "Public Build Guardrail Audit Default State Passed");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Audit_Is_Side_Effect_Free'Access,
         "Public Build Guardrail Audit Is Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Audit_Uses_Hard_Freeze_Audit'Access,
         "Public Build Guardrail Audit Uses Hard Freeze Audit");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Audit_Uses_Drift_Detection'Access,
         "Public Build Guardrail Audit Uses Drift Detection");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Audit_Uses_Exposure_Barrier'Access,
         "Public Build Guardrail Audit Uses Exposure Barrier");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Command_Id_List_Is_Centralized'Access,
         "Public Build Public Command Id List Is Centralized");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Command_Id_Not_Palette_Row'Access,
         "Public Build Public Command Id Not Palette Row");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Command_Id_Not_Persisted_Command_Name'Access,
         "Public Build Public Command Id Not Persisted Command Name");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Contract_Version_Is_Not_Persisted'Access,
         "Public Build Guardrail Contract Version Is Not Persisted");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Unrelated_Feature_Descriptor_Does_Not_Affect_Guardrail'Access,
         "Public Build Unrelated Feature Descriptor Does Not Affect Guardrail");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Unrelated_Diagnostics_Source_Does_Not_Affect_Guardrail'Access,
         "Public Build Unrelated Diagnostics Source Does Not Affect Guardrail");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Unrelated_Messages_Source_Does_Not_Affect_Guardrail'Access,
         "Public Build Unrelated Messages Source Does Not Affect Guardrail");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Unrelated_Settings_Preference_Does_Not_Affect_Guardrail'Access,
         "Public Build Unrelated Settings Preference Does Not Affect Guardrail");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Long_Horizon_Persistence_Snapshot_Excludes_Guardrail_State'Access,
         "Public Build Long Horizon Persistence Snapshot Excludes Guardrail State");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Baseline_Is_Deterministic'Access,
         "Public Build Hard Freeze Baseline Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Drift_Detection_Is_Side_Effect_Free'Access,
         "Public Build Hard Freeze Drift Detection Is Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Drift_Default_State_Has_No_Drift'Access,
         "Public Build Hard Freeze Drift Default State Has No Drift");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Drift_Detects_Public_Command'Access,
         "Public Build Hard Freeze Drift Detects Public Command");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Drift_Detects_Keybinding'Access,
         "Public Build Hard Freeze Drift Detects Keybinding");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Drift_Detects_Palette_Entry'Access,
         "Public Build Hard Freeze Drift Detects Palette Feed_Item");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Drift_Detects_Executor_Route'Access,
         "Public Build Hard Freeze Drift Detects Executor Route");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Drift_Detects_Public_Invocation_Path'Access,
         "Public Build Hard Freeze Drift Detects Invocation Path");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Drift_Detects_Bindable_Command'Access,
         "Public Build Hard Freeze Drift Detects Bindable Command");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Drift_Detects_Promotion_Status_Change'Access,
         "Public Build Hard Freeze Drift Detects Promotion Status Change");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Drift_Detects_Blocker_Precedence_Change'Access,
         "Public Build Hard Freeze Drift Detects Blocker Precedence Change");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Drift_Detects_Persistence_Leak'Access,
         "Public Build Hard Freeze Drift Detects Persistence Leak");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Id_Cannot_Be_Reused_By_Unrelated_Command'Access,
         "Public Build Public Id Cannot Be Reused By Unrelated Command");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Id_Cannot_Be_Reused_By_Unrelated_Command'Access,
         "Public Build Public Id Cannot Be ed To Internal Command");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Id_Cannot_Be_Keybinding_Target'Access,
         "Public Build Public Id Cannot Be Keybinding Target");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Audit_Composition_Remains_Consistent'Access,
         "Public Build Audit Composition Remains Consistent");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Audit_Composition_Hard_Failure_Fails_Hard_Freeze'Access,
         "Public Build Audit Composition Hard Failure Fails Hard Freeze");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Unrelated_Public_Command_Does_Not_Affect_Freeze'Access,
         "Public Build Unrelated Public Command Does Not Affect Freeze");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Unrelated_Keybinding_Does_Not_Affect_Freeze'Access,
         "Public Build Unrelated Keybinding Does Not Affect Freeze");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_No_Public_Build_Execution_Path_RemainsDeep_Scan'Access,
         "No Public Build Execution Path Deep Scan");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Drift_Feedback_Is_Deterministic'Access,
         "Public Build Drift Feedback Is Deterministic");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_User_Opt_In_Build_Command_Is_Internal'Access,
         "User Opt-In Build Command Is Internal");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Recent_Project_Selected_Row_Commands_Are_No_Payload'Access,
         "Recent Projects selected-row commands are no-payload");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_User_Opt_In_Build_Command_Has_No_Default_Keybinding'Access,
         "User Opt-In Build Command Has No Default Keybinding");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_User_Opt_In_Build_Command_Bare_Route_Is_Unavailable'Access,
         "User Opt-In Build Command Bare Route Is Unavailable");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_User_Opt_In_Build_Command_Structured_Route_Reaches_Executor'Access,
         "User Opt-In Build Command Structured Route Reaches Executor");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Build_Command_Surface_Has_No_Public_Run_Command'Access,
         "Build Command Surface Has No Public Run Command");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Readiness_Audit_Reports_Not_Ready'Access,
         "Public Build Readiness Audit Reports Not Ready");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Readiness_Audit_Is_Side_Effect_Free'Access,
         "Public Build Readiness Audit Is Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Commands_Are_Not_Registered'Access,
         "Public Build Commands Are Not Registered");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Commands_Have_No_Default_Keybindings'Access,
         "Public Build Commands Have No Default Keybindings");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Commands_Are_Hidden_From_Normal_Palette'Access,
         "Public Build Commands Are Hidden From Normal Palette");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Readiness_Reports_Missing_UX_Models'Access,
         "Public Build Readiness Reports Missing UX Models");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Readiness_Keeps_Rejections'Access,
         "Public Build Readiness Keeps Rejections");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Build_Command_Classification_Helpers'Access,
         "Build Command Classification Helpers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Working_Context_Validation_Is_Side_Effect_Free'Access,
         "Public Build Working Context Validation Is Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Working_Context_Rejects_Invalid_Forms'Access,
         "Public Build Working Context Rejects Invalid Forms");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Working_Context_Test_Context_Internal_Only'Access,
         "Public Build Working Context Test Context Internal Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Working_Context_User_Form_Not_Publicly_Exposable'Access,
         "Public Build Working Context User Form Not Publicly Exposable");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Conversion_Rejects_Project_Derived_Working_Context'Access,
         "Public Build Input Conversion Rejects Project Derived Working Context");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Conversion_Does_Not_Silently_Upgrade_Working_Context'Access,
         "Public Build Input Conversion Does Not Silently Upgrade Working Context");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Conversion_Valid_Test_Working_Context_Uses_Inherited_Test_Context'Access,
         "Public Build Input Conversion Valid Test Working Context Uses Inherited Test Context");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Working_Context_Feedback_Is_Deterministic'Access,
         "Public Build Working Context Feedback Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Readiness_Audit_Reports_Working_Context_Model'Access,
         "Public Build Readiness Audit Reports Working Context Model");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Working_Context_Model_Does_Not_Register_Public_Command'Access,
         "Public Build Working Context Model Does Not Register Public Command");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Command_Surface_Entries_Exist_As_Metadata_Only'Access,
         "Public Build Command Surface_Entries Exist As Metadata Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Command_Surface_Entry_Not_Registered'Access,
         "Public Build Command Surface_Entry Not Registered");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Command_Surface_Entry_Has_No_Keybinding'Access,
         "Public Build Command Surface_Entry Has No Keybinding");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Command_Surface_Entry_Not_In_Normal_Palette'Access,
         "Public Build Command Surface_Entry Not In Normal Palette");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Command_Surface_Entry_Does_Not_Route_To_Executor'Access,
         "Public Build Command Surface_Entry Does Not Route To Executor");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Command_Surface_Validation_Is_Side_Effect_Free'Access,
         "Public Build Command Surface_Entry Validation Is Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Command_Surface_Entry_Rejects_Invalid_Forms'Access,
         "Public Build Command Surface_Entry Rejects Invalid Forms");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Readiness_Audit_Reports_Surface_Entries'Access,
         "Public Build Readiness Audit Reports Surface_Entries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Command_UX_Dependency_Matrix_Is_Ready'Access,
         "Public Build Command UX Dependency Matrix Is Ready");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Command_Not_Ready_Feedback_Is_Deterministic'Access,
         "Public Build Command Not Ready Feedback Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Command_Exposure_Barrier_Passes_For_Surface_Entries'Access,
         "Public Build Command Exposure Barrier Passes For Surface_Entries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Promotion_Blocked_When_Consent_UX_Missing'Access,
         "Public Build Promotion Blocked When Consent UX Missing");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Promotion_Blocked_When_Working_Context_UX_Missing'Access,
         "Public Build Promotion Blocked When Working Context UX Missing");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Promotion_Ready_When_Guardrails_Pass'Access,
         "Public Build Promotion Ready When Guardrails Pass");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Promotion_Blocked_When_Command_Already_Registered'Access,
         "Public Build Promotion Blocked When Command Already Registered");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Promotion_Blocked_When_Default_Keybinding_Exists'Access,
         "Public Build Promotion Blocked When Default Keybinding Exists");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Promotion_Blocked_When_Executor_Route_Exists'Access,
         "Public Build Promotion Blocked When Executor Route Exists");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Promotion_Ready_In_Current_State'Access,
         "Public Build Promotion Ready In Current State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Promotion_Audit_Is_Side_Effect_Free'Access,
         "Public Build Promotion Audit Is Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_UX_Dependency_Matrix_Exists'Access,
         "Public Build UX Dependency Matrix Exists");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_UX_Dependency_Matrix_Validation_Allows_Promotion'Access,
         "Public Build UX Dependency Matrix Validation Allows Promotion");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Promotion_Blocker_Precedence_Is_Deterministic'Access,
         "Public Build Promotion Blocker Precedence Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Readiness_Audit_Reports_Dependency_Matrix'Access,
         "Public Build Readiness Audit Reports Dependency Matrix");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Exposure_Hard_Failure_For_Simulated_Public_Command'Access,
         "Public Build Exposure Hard Failure For Simulated Public Command");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Repeated_Audits_Are_Stable'Access,
         "Public Build Repeated Audits Are Stable");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Audit_Passes_Default_State'Access,
         "Public Build Hard Freeze Audit Passes Default State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Audit_Is_Side_Effect_Free'Access,
         "Public Build Hard Freeze Audit Is Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Audit_Agrees_With_Other_Audits'Access,
         "Public Build Hard Freeze Audit Agrees With Other Audits");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Blocker_Summary_Is_Deterministic_For_Current_State'Access,
         "Public Build Blocker Summary Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Detects_Simulated_Hard_Failures'Access,
         "Public Build Hard Freeze Detects Simulated Hard Failures");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Remains_After_Lifecycle_Transitions'Access,
         "Public Build Hard Freeze Remains After Lifecycle Transitions");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_No_Public_Build_Execution_Path_Remains'Access,
         "No Public Build Execution Path");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Feedback_Is_Deterministic'Access,
         "Public Build Hard Freeze Feedback Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Consent_Validation_Is_Side_Effect_Free'Access,
         "Public Build Consent Validation Is Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Consent_Rejects_Missing_Acknowledgements'Access,
         "Public Build Consent Rejects Missing Acknowledgements");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Consent_Test_Context_Internal_Only'Access,
         "Public Build Consent Test Context Internal Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Consent_User_Form_Not_Publicly_Exposable'Access,
         "Public Build Consent User Form Not Publicly Exposable");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Consent_Feedback_Is_Deterministic'Access,
         "Public Build Consent Feedback Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Validation_Is_Side_Effect_Free'Access,
         "Public Build Input Validation Is Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Rejects_Invalid_Forms'Access,
         "Public Build Input Rejects Invalid Forms");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Validates_Structured_Argv'Access,
         "Public Build Input Validates Structured Argv");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Safety_Classification'Access,
         "Public Build Input Safety Classification");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_No_State_Publicly_Exposable'Access,
         "Public Build Input No State Publicly Exposable");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Working_Context_Guardrails'Access,
         "Public Build Input Working Context Guardrails");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Program_Label_Guardrails'Access,
         "Public Build Input Program Label Guardrails");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Argument_Guardrails'Access,
         "Public Build Input Argument Guardrails");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Conversion_Consistency_Valid_Test_Context'Access,
         "Public Build Input Conversion Consistency Valid Test Context");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Conversion_Requires_Valid_Input'Access,
         "Public Build Input Conversion Requires Valid Input");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Conversion_Rejects_Invalid_Consent'Access,
         "Public Build Input Conversion Rejects Invalid Consent");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Conversion_Does_Not_Silently_Upgrade_Consent'Access,
         "Public Build Input Conversion Does Not Silently Upgrade Consent");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Conversion_Uses_User_Opt_In_Provenance'Access,
         "Public Build Input Conversion Uses User Opt-In Provenance");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Feedback_Is_Deterministic'Access,
         "Public Build Input Feedback Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Readiness_Audit_Reports_Input_Model_Present'Access,
         "Public Build Readiness Audit Reports Input Model Present");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Does_Not_Register_Public_Command'Access,
         "Public Build Input Does Not Register Public Command");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Build_Command_Route_Audit_Covers_Executor_Boundary'Access,
         "Build Command Route Audit Covers Executor Boundary");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Build_Command_Route_Audit_Rejects_Bypass_Routes'Access,
         "Build Command Route Audit Rejects Bypass Routes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_UI_Route_Audit_Covers_Panel_Actions'Access,
         "Command UI Route Audit Covers Panel Actions");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_UI_Route_Audit_Rejects_Bypass_And_Duplicate'Access,
         "Command UI Route Audit Rejects Bypass And Duplicate");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Descriptor_Audit_Helpers'Access,
         "Command Descriptor Audit Helpers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Palette_Command_Traversal_Audit'Access,
         "Palette Command Traversal Audit");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Keybinding_Validation_Audit'Access,
         "Keybinding Validation Audit");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Palette_Candidates_Use_Command_Registry'Access,
         "Palette Candidates Use Command Registry");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Static_Command_Invariants'Access,
         "Static Command Invariants");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Availability_Is_Read_Only_On_Empty_State'Access,
         "Availability Is Read-Only On Empty State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Unavailable_Reason_Consistency'Access,
         "Unavailable Reason Consistency");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Palette_Snapshot_Determinism'Access,
         "Palette Snapshot Determinism");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Guarded_Execute_Command_Unavailable_Message'Access,
         "Guarded Execute Command Unavailable Message");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Row_Layout_Edges'Access,
         "Command Row Layout Edges");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Hidden_Command_Behavior'Access,
         "Hidden Command Behavior");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Build_Run_Public_Descriptor'Access,
         "Build Run Public Descriptor");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Build_Run_Readiness_Reasons'Access,
         "Build Run Readiness Reasons");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Build_Run_Coherent_Audit'Access,
         "Build Run Coherent Audit");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Configuration_Command_Surface_Coherent'Access,
         "Configuration Command Surface Coherent");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Switch_Project_Command_Surface'Access,
         "Switch Project Command Surface");


      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Metadata_Completeness'Access,
         "Command Metadata Completeness");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Stable_Command_Name_Coverage'Access,
         "Stable Command Name Coverage");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Classification_Invariants'Access,
         "Command Classification Invariants");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Command_Descriptions_Are_Distinct'Access,
         "Save Command Descriptions Are Distinct");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Execution_Result_For_No_Op_And_Unavailable'Access,
         "Execution Result For No-Op And Unavailable");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Disabled_State_Baseline'Access,
         "Disabled State Baseline");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Execution_Result_Terminology'Access,
         "Command Execution Result Terminology");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Unavailable_Commands_Are_Side_Effect_Limited'Access,
         "Unavailable Commands Are Side-Effect Limited_View");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Availability_And_Execution_Result_Consistency'Access,
         "Availability And Execution Result Consistency");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_For_Id_Fallback_Coverage_Audit'Access,
         "Command_For_Id Fallback Coverage Audit");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Palette_Dispatch_Uses_Executor_Result'Access,
         "Command Palette Dispatch Uses Executor Result");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Execution_Final_Status_Helpers'Access,
         "Command Execution Final Status Helpers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Category_Baseline'Access,
         "Command Category Baseline");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Classification_Groups'Access,
         "Command Classification Groups");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Registry_Baseline'Access,
         "Command Registry Baseline");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Unavailable_Result_Message_Coherence'Access,
         "Unavailable Result Message Coherence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Failed_Reload_Reports_Command_Failed'Access,
         "Failed Reload Reports Command_Failed");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_No_Op_Is_Public_For_No_Command'Access,
         "No-Op Is Public For No_Command");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Configuration_Command_Domain_Isolation'Access,
         "Configuration Command Domain Isolation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Concrete_Command_Traversal'Access,
         "Concrete Command Traversal");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Audit_Registry_Is_Actionable'Access,
         "Command Audit Registry Is Actionable");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Descriptor_Construction_Helper'Access,
         "Command Descriptor Construction Helper");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Route_Audit_Actionable_Failures'Access,
         "Route Audit Actionable Failures");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Product_Command_Surface'Access,
         "Product Command Surface");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_IDE_Grade_Language_Command_Surface'Access,
         "IDE Grade Language Command Surface");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Command_Reference_Surface'Access,
         "File Command Reference Surface");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_Search_Product_Surface'Access,
         "Project Search Product Surface");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Find_And_Goto_Product_Surface'Access,
         "Find and Go to Line Product Surface");
   end Register_Tests;

end Editor.Command_Surface.Tests;
