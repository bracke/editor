with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Build_Candidate_Audit;
with Editor.Build_Candidate_Discovery;
with Editor.Build_Candidate_Refresh;
with Editor.Build_Candidate_Refresh_Audit;
with Editor.Build_Candidate_Selection;
with Editor.Build_Candidate_Selection_Audit;
with Editor.Build_Candidates;
with Editor.Build_Public_Request;
with Editor.Build_Result_Summary;
with Editor.Build_Output_Details;
with Editor.Build_UI;
with Editor.Build_Working_Context;
with Editor.External_Producers;

use type Editor.Build_Candidates.Build_Candidate_Kind;
use type Editor.Build_Candidates.Build_Candidate_Source;
use type Editor.Build_Candidates.Build_Candidate_Validation_Status;
use type Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Status;
use type Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Status;
use type Editor.Build_UI.Public_Build_UI_Validation_Status;
use type Editor.Build_UI.Public_Build_Tool_Selection;
use type Editor.Build_Working_Context.Build_Working_Context_Kind;
use type Editor.External_Producers.Build_Tool_Kind;
use type Editor.External_Producers.Build_Request_Provenance;

package body Editor.Build_Candidates.Tests is

   overriding function Name
     (T : Build_Candidates_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Build_Candidates");
   end Name;

   function Fixture_Root return String is
   begin
      Ada.Directories.Create_Path ("/tmp/editor-tests");
      return "/tmp/editor-tests/candidate_fixture";
   end Fixture_Root;

   procedure Write_File (Path : String; Text : String := "") is
      F : Ada.Text_IO.File_Type;
   begin
      Ada.Text_IO.Create (F, Ada.Text_IO.Out_File, Path);
      Ada.Text_IO.Put_Line (F, Text);
      Ada.Text_IO.Close (F);
   end Write_File;

   procedure Reset_Fixture is
      Root : constant String := Fixture_Root;
   begin
      if Ada.Directories.Exists (Root) then
         Ada.Directories.Delete_Tree (Root);
      end if;
      Ada.Directories.Create_Path (Root);
   end Reset_Fixture;

   procedure Test_Candidate_Model_Is_Structured_Transient
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      C : Editor.Build_Candidates.Build_Candidate_Record;
   begin
      Reset_Fixture;
      Write_File (Root & "/alire.toml", "name = ""demo""");
      C := Editor.Build_Candidates.Alire_Candidate (Root);
      Assert (C.Candidate_Kind = Editor.Build_Candidates.Build_Candidate_Alire_Project,
              "alire candidate uses explicit kind");
      Assert (C.Discovery_Source = Editor.Build_Candidates.Build_Candidate_Source_Alire_Toml,
              "alire candidate records bounded source");
      Assert (C.Tool_Kind = Editor.External_Producers.Alire_Build_Tool,
              "alire candidate maps to public build tool kind");
      Assert (Editor.Build_Candidates.Argument_Count (C) = 1,
              "alire candidate uses structured argv tokens");
      Assert (not Editor.Build_Candidates.Has_Raw_Shell_Command_Field (C),
              "candidate has no raw shell command field");
      Assert (not Editor.Build_Candidates.Has_Remembered_Consent_Field (C),
              "candidate carries no remembered consent");
      Assert (not Editor.Build_Candidates.Has_Process_State_Field (C),
              "candidate carries no process state");
      Assert (Editor.Build_Candidates.Assert_Build_Candidate_Is_Structured (C),
              "candidate model is structured");
      Assert (Editor.Build_Candidates.Assert_Build_Candidate_Is_Transient (C),
              "candidate model is transient");

      C := Editor.Build_Candidates.Manual_Request_Candidate;
      Assert (Editor.Build_Candidates.Validate_Candidate (C) =
                Editor.Build_Candidates.Build_Candidate_Rejected_Unstructured,
              "rejects removed manual request candidates at the candidate model boundary");
      Assert (not Editor.Build_Candidates.Assert_Build_Candidate_Is_Structured (C),
              "manual request candidates cannot satisfy structured discovered-candidate assertions");
   end Test_Candidate_Model_Is_Structured_Transient;

   procedure Test_Discovery_Finds_Alire_And_Root_Gpr_Deterministically
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Context : Editor.Build_Working_Context.Build_Working_Context_Record;
      R : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result;
   begin
      Reset_Fixture;
      Write_File (Root & "/zeta.gpr", "project Zeta is end Zeta;");
      Write_File (Root & "/alpha.gpr", "project Alpha is end Alpha;");
      Write_File (Root & "/alire.toml", "name = ""demo""");
      Ada.Directories.Create_Path (Root & "/nested");
      Write_File (Root & "/nested/ignored.gpr", "project Ignored is end Ignored;");

      Context := Editor.Build_Working_Context.Current_Project_Root (Root);
      R := Editor.Build_Candidate_Discovery.Discover_Build_Candidates (Context);

      Assert (R.Status = Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Complete,
              "bounded discovery completes for canonical project root");
      Assert (Natural (R.Candidates.Length) = 4,
              "discovery finds alire.toml plus root and bounded nested gpr files");
      Assert (R.Candidates.Element (0).Candidate_Kind =
                Editor.Build_Candidates.Build_Candidate_Alire_Project,
              "alire candidate is ordered first");
      Assert (To_String (R.Candidates.Element (1).Candidate_Id) <
                To_String (R.Candidates.Element (2).Candidate_Id),
              "gpr candidates are deterministically ordered");
      Assert (Editor.Build_Candidate_Discovery.Assert_Build_Candidate_Discovery_Bounded (R),
              "discovery output is bounded and structured");
      Assert (Editor.Build_Candidate_Discovery.Assert_Build_Candidate_Discovery_Does_Not_Execute (R),
              "discovery does not execute tools");
      Assert (Editor.Build_Candidate_Discovery.Assert_Build_Candidate_Discovery_Does_Not_Use_Shell (R),
              "discovery does not use shell");
      Assert (Editor.Build_Candidate_Discovery.Assert_Build_Candidate_Discovery_Does_Not_Scan_Outside_Project_Root (R),
              "discovery candidates remain under project root");
   end Test_Discovery_Finds_Alire_And_Root_Gpr_Deterministically;

   procedure Test_Discovery_Rejects_Missing_Or_Unsafe_Context
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      None_Context : constant Editor.Build_Working_Context.Build_Working_Context_Record :=
        Editor.Build_Working_Context.None;
      Unsafe_Context : constant Editor.Build_Working_Context.Build_Working_Context_Record :=
        Editor.Build_Working_Context.Unsafe_Context
          (Editor.Build_Working_Context.Build_Working_Context_Current_Project_Root,
           "../outside", Editor.Build_Working_Context.Working_Context_Source_Raw_Text,
           "../outside");
      R1 : constant Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result :=
        Editor.Build_Candidate_Discovery.Discover_Build_Candidates (None_Context);
      R2 : constant Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result :=
        Editor.Build_Candidate_Discovery.Discover_Build_Candidates (Unsafe_Context);
   begin
      Assert (R1.Status = Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_No_Project_Context,
              "missing project root yields no candidates");
      Assert (R2.Status = Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Rejected_Context,
              "unsafe context is rejected before discovery");
      Assert (R1.Candidates.Is_Empty and then R2.Candidates.Is_Empty,
              "rejected discovery returns no candidate list");
   end Test_Discovery_Rejects_Missing_Or_Unsafe_Context;

   procedure Test_Candidate_Selection_Populates_UI_And_Invalidates_Consent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Context : Editor.Build_Working_Context.Build_Working_Context_Record;
      R : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result;
      S : Editor.Build_UI.Public_Build_UI_State;
      Conversion : Editor.Build_Public_Request.Public_Build_Request_Conversion_Result;
   begin
      Reset_Fixture;
      Write_File (Root & "/demo.gpr", "project Demo is end Demo;");
      Context := Editor.Build_Working_Context.Current_Project_Root (Root);
      R := Editor.Build_Candidate_Discovery.Discover_Build_Candidates (Context);

      Editor.Build_UI.Show (S);
      Editor.Build_UI.Set_Build_Candidates (S, R.Candidates, "discovered");
      Assert (Editor.Build_UI.Candidate_Count (S) = 1,
              "candidate list is visible as transient UI snapshot");
      Assert (To_String (S.Selected_Build_Candidate_Id)'Length = 0,
              "candidate discovery does not auto-select");

      Editor.Build_UI.Select_Build_Candidate
        (S, To_String (R.Candidates.Element (0).Candidate_Id));
      Assert (S.Selected_Build_Tool = Editor.Build_UI.Build_UI_GPRbuild,
              "candidate selection populates tool kind");
      Assert (Editor.Build_UI.Argument_Count (S.Structured_Arguments) = 2,
              "candidate selection populates structured arguments");
      Assert (not S.Consent_Acknowledged,
              "candidate selection invalidates prior consent and does not auto-consent");
      Assert (Editor.Build_UI.Validate_Build_UI_State (S) =
                Editor.Build_UI.Build_UI_Rejected_Missing_Consent,
              "selected candidate still requires explicit consent");

      Editor.Build_UI.Acknowledge_Consent (S);
      Conversion := Editor.Build_Public_Request.Build_Public_Request_From_UI_State (S);
      Assert (Conversion.Status = Editor.Build_UI.Build_UI_Valid,
              "selected candidate converts after explicit consent");
      Assert (Conversion.Request.Provenance =
                Editor.External_Producers.Build_Request_From_User_Opt_In,
              "candidate conversion remains user opt-in provenance");
      Assert (Conversion.Request.Tool = Editor.External_Producers.GPRbuild_Tool,
              "candidate conversion maps public build tool kind");
   end Test_Candidate_Selection_Populates_UI_And_Invalidates_Consent;


   procedure Test_Alire_Candidate_Selection_Request_Preview
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Context : Editor.Build_Working_Context.Build_Working_Context_Record;
      R : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result;
      S : Editor.Build_UI.Public_Build_UI_State;
      Conversion : Editor.Build_Public_Request.Public_Build_Request_Conversion_Result;
   begin
      Reset_Fixture;
      Write_File (Root & "/alire.toml", "name = ""demo""");
      Context := Editor.Build_Working_Context.Current_Project_Root (Root);
      R := Editor.Build_Candidate_Discovery.Discover_Build_Candidates (Context);

      Editor.Build_UI.Show (S);
      Editor.Build_UI.Set_Build_Candidates (S, R.Candidates, "discovered");
      Assert (To_String (S.Selected_Build_Candidate_Id)'Length = 0,
              "candidate discovery does not auto-select the only candidate");

      Editor.Build_Candidate_Selection.Select_Build_Candidate
        (S, To_String (R.Candidates.Element (0).Candidate_Id));
      Assert (S.Candidate_Applied_To_Request,
              "explicit selection marks request as candidate-derived");
      Assert (S.Selected_Build_Tool = Editor.Build_UI.Build_UI_Alire,
              "Alire candidate populates Build_UI_Alire");
      Assert (Editor.Build_UI.Argument_Count (S.Structured_Arguments) = 1,
              "Alire candidate populates structured argv tokens");
      Assert (To_String (S.Structured_Arguments.Element (0)) = "build",
              "Alire argv is tokenized as build");
      Assert (S.Selected_Working_Context.Kind =
                Editor.Build_Working_Context.Build_Working_Context_Current_Project_Root,
              "Alire candidate populates project-root working context");
      Assert (To_String (S.Candidate_Request_Preview)'Length > 0,
              "candidate-derived structured preview is populated");
      Assert (Ada.Strings.Fixed.Index
                (To_String (S.Candidate_Request_Preview), "&&") = 0,
              "candidate preview does not create shell command text");
      Assert (not S.Consent_Acknowledged,
              "candidate selection does not imply consent");
      Assert (Editor.Build_UI.Validate_Build_UI_State (S) =
                Editor.Build_UI.Build_UI_Rejected_Missing_Consent,
              "candidate-derived request requires renewed consent");

      Editor.Build_UI.Acknowledge_Consent (S);
      Conversion := Editor.Build_Public_Request.Build_Public_Request_From_UI_State (S);
      Assert (Conversion.Status = Editor.Build_UI.Build_UI_Valid,
              "candidate-derived request converts only after renewed consent");
      Assert (Conversion.Request.Tool = Editor.External_Producers.Alire_Build_Tool,
              "candidate-derived conversion keeps bounded Alire tool kind");
      Assert (To_String (Conversion.Request.Arguments)'Length = 0,
              "candidate-derived conversion does not emit opaque shell arguments");
   end Test_Alire_Candidate_Selection_Request_Preview;

   procedure Test_Gpr_Candidate_Selection_And_Manual_Mode
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Context : Editor.Build_Working_Context.Build_Working_Context_Record;
      R : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result;
      S : Editor.Build_UI.Public_Build_UI_State;
      Args : Editor.Build_UI.Build_UI_Argument_Vector :=
        Editor.Build_UI.Empty_Arguments;
   begin
      Reset_Fixture;
      Write_File (Root & "/demo.gpr", "project Demo is end Demo;");
      Context := Editor.Build_Working_Context.Current_Project_Root (Root);
      R := Editor.Build_Candidate_Discovery.Discover_Build_Candidates (Context);

      Editor.Build_UI.Show (S);
      Editor.Build_UI.Set_Build_Candidates (S, R.Candidates, "discovered");
      Editor.Build_Candidate_Selection.Select_Build_Candidate
        (S, To_String (R.Candidates.Element (0).Candidate_Id));
      Assert (S.Selected_Build_Tool = Editor.Build_UI.Build_UI_GPRbuild,
              "GPR candidate populates Build_UI_GPRbuild");
      Assert (Editor.Build_UI.Argument_Count (S.Structured_Arguments) = 2,
              "GPR candidate populates -P and project file argv tokens");
      Assert (To_String (S.Structured_Arguments.Element (0)) = "-P",
              "GPR first argv token is -P");
      Assert (To_String (S.Structured_Arguments.Element (1)) = "demo.gpr",
              "GPR project file remains a structured argv token");
      Assert (Ada.Strings.Fixed.Index
                (To_String (S.Candidate_Request_Preview), Root & "/demo.gpr") = 0,
              "candidate source path remains metadata and is not command text");

      Editor.Build_Candidate_Selection.Clear_Selected_Build_Candidate (S);
      Assert (not S.Candidate_Applied_To_Request,
              "clearing selected candidate leaves no configured request");
      Assert (To_String (S.Selected_Build_Candidate_Id)'Length = 0,
              "cleared request has no selected candidate id");
      Assert (not S.Consent_Acknowledged,
              "clearing selected candidate invalidates consent");
      Assert (Editor.Build_UI.Validate_Build_UI_State (S) =
                Editor.Build_UI.Build_UI_Rejected_No_Candidate_Selected,
              "requires selecting a candidate before build.run can be consented");

      Editor.Build_UI.Select_Tool (S, Editor.Build_UI.Build_UI_GPRbuild);
      Editor.Build_UI.Append_Argument (Args, "-q");
      Editor.Build_UI.Set_Structured_Arguments (S, Args);
      Editor.Build_UI.Set_Working_Context_Label (S, Root);
      Assert (To_String (S.Selected_Build_Candidate_Id)'Length = 0,
              "manual request editing does not recreate candidate selection");
      Assert (not S.Candidate_Applied_To_Request,
              "manual request path remains invalid until a candidate is selected");
      Assert (Editor.Build_UI.Validate_Build_UI_State (S) =
                Editor.Build_UI.Build_UI_Rejected_No_Candidate_Selected,
              "manual request path cannot bypass candidate-specific configuration");
   end Test_Gpr_Candidate_Selection_And_Manual_Mode;

   procedure Test_Candidate_Selection_Audit_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Context : Editor.Build_Working_Context.Build_Working_Context_Record;
      R : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result;
      S : Editor.Build_UI.Public_Build_UI_State;
   begin
      Reset_Fixture;
      Write_File (Root & "/alire.toml", "name = ""demo""");
      Context := Editor.Build_Working_Context.Current_Project_Root (Root);
      R := Editor.Build_Candidate_Discovery.Discover_Build_Candidates (Context);
      Editor.Build_UI.Show (S);
      Editor.Build_UI.Set_Build_Candidates (S, R.Candidates, "discovered");
      Editor.Build_Candidate_Selection.Select_Build_Candidate
        (S, To_String (R.Candidates.Element (0).Candidate_Id));

      Assert (Editor.Build_Candidate_Selection_Audit.Assert_Build_Candidate_Selection_Is_Explicit (S),
              "audit sees explicit selected candidate state");
      Assert (Editor.Build_Candidate_Selection_Audit.Assert_Build_Candidate_Selection_Does_Not_Consent (S),
              "audit sees candidate selection without consent");
      Assert (Editor.Build_Candidate_Selection_Audit.Assert_Build_Candidate_Selection_Does_Not_Execute (S),
              "audit sees no candidate execution field");
      Assert (Editor.Build_Candidate_Selection_Audit.Assert_Public_Build_Candidate_Selection_Foundation_Coherent (S),
              "candidate selection foundation is coherent");
   end Test_Candidate_Selection_Audit_Coherent;

   procedure Test_Audit_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Context : Editor.Build_Working_Context.Build_Working_Context_Record;
      R : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result;
      S : Editor.Build_UI.Public_Build_UI_State;
   begin
      Reset_Fixture;
      Write_File (Root & "/alire.toml", "name = ""demo""");
      Context := Editor.Build_Working_Context.Current_Project_Root (Root);
      R := Editor.Build_Candidate_Discovery.Discover_Build_Candidates (Context);
      Editor.Build_UI.Show (S);
      Editor.Build_UI.Set_Build_Candidates (S, R.Candidates, "discovered");
      Editor.Build_UI.Select_Build_Candidate
        (S, To_String (R.Candidates.Element (0).Candidate_Id));
      Assert (Editor.Build_Candidate_Audit.Assert_Public_Build_Candidate_Discovery_Foundation_Coherent
                (S, R),
              "candidate discovery foundation is coherent");
   end Test_Audit_Coherent;



   procedure Test_Explicit_Refresh_Updates_Transient_Candidates
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Context : Editor.Build_Working_Context.Build_Working_Context_Record;
      S : Editor.Build_UI.Public_Build_UI_State;
      R : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
   begin
      Reset_Fixture;
      Write_File (Root & "/alire.toml", "name = ""demo""");
      Write_File (Root & "/demo.gpr", "project Demo is end Demo;");
      Context := Editor.Build_Working_Context.Current_Project_Root (Root);
      Editor.Build_UI.Show (S);

      R := Editor.Build_Candidate_Refresh.Refresh_Build_Candidates (S, Context);

      Assert (R.Status = Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Succeeded,
              "explicit refresh succeeds over canonical project context");
      Assert (R.Candidate_Count = 2,
              "refresh discovers only bounded alire/root-gpr candidates");
      Assert (Editor.Build_UI.Candidate_Count (S) = 2,
              "refresh updates transient candidate UI state");
      Assert (S.Candidate_Refresh_Status = Editor.Build_UI.Build_Candidate_Refresh_Succeeded,
              "Build UI snapshots refresh status");
      Assert (To_String (S.Selected_Build_Candidate_Id)'Length = 0,
              "refresh does not auto-select a candidate");
      Assert (not S.Consent_Acknowledged,
              "refresh does not auto-consent");
      Assert (Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Bounded (R),
              "refresh is bounded to canonical project context");
      Assert (Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Does_Not_Execute (R),
              "refresh does not execute tools or shell");
   end Test_Explicit_Refresh_Updates_Transient_Candidates;

   procedure Test_Refresh_No_Context_And_No_Candidates_Status
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      S : Editor.Build_UI.Public_Build_UI_State;
      No_Context : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
      No_Candidates : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
   begin
      Reset_Fixture;
      Editor.Build_UI.Show (S);
      No_Context := Editor.Build_Candidate_Refresh.Refresh_Build_Candidates
        (S, Editor.Build_Working_Context.None);
      Assert (No_Context.Status =
                Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_No_Project_Context,
              "refresh without canonical project context is deterministic");
      Assert (Editor.Build_UI.Candidate_Count (S) = 0,
              "no-context refresh leaves no candidates");

      No_Candidates := Editor.Build_Candidate_Refresh.Refresh_Build_Candidates
        (S, Editor.Build_Working_Context.Current_Project_Root (Root));
      Assert (No_Candidates.Status =
                Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_No_Candidates,
              "empty bounded project root yields no-candidates status");
      Assert (S.Candidate_Refresh_Status = Editor.Build_UI.Build_Candidate_Refresh_No_Candidates,
              "Build UI snapshots no-candidates refresh status");
   end Test_Refresh_No_Context_And_No_Candidates_Status;

   procedure Test_Refresh_Preserves_Valid_Selected_Candidate_And_Consent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Context : Editor.Build_Working_Context.Build_Working_Context_Record;
      S : Editor.Build_UI.Public_Build_UI_State;
      Before : Editor.Build_UI.Public_Build_UI_State;
      R : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
      D : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result;
   begin
      Reset_Fixture;
      Write_File (Root & "/demo.gpr", "project Demo is end Demo;");
      Context := Editor.Build_Working_Context.Current_Project_Root (Root);
      D := Editor.Build_Candidate_Discovery.Discover_Build_Candidates (Context);
      Editor.Build_UI.Show (S);
      Editor.Build_UI.Set_Build_Candidates (S, D.Candidates, "discovered");
      Editor.Build_UI.Select_Build_Candidate
        (S, To_String (D.Candidates.Element (0).Candidate_Id));
      Editor.Build_UI.Acknowledge_Consent (S);
      Before := S;

      R := Editor.Build_Candidate_Refresh.Refresh_Build_Candidates (S, Context);

      Assert (R.Selected_Candidate_Preserved,
              "matching refreshed candidate preserves selection");
      Assert (not R.Selected_Candidate_Cleared,
              "matching refreshed candidate is not stale-cleared");
      Assert (S.Consent_Acknowledged,
              "unchanged selected request preserves consent identity");
      Assert (To_String (S.Selected_Build_Candidate_Id) =
                To_String (Before.Selected_Build_Candidate_Id),
              "selected candidate identity remains stable");
   end Test_Refresh_Preserves_Valid_Selected_Candidate_And_Consent;

   procedure Test_Refresh_Clears_Stale_Selected_Candidate_And_Consent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Context : Editor.Build_Working_Context.Build_Working_Context_Record;
      S : Editor.Build_UI.Public_Build_UI_State;
      R : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
      D : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result;
   begin
      Reset_Fixture;
      Write_File (Root & "/demo.gpr", "project Demo is end Demo;");
      Context := Editor.Build_Working_Context.Current_Project_Root (Root);
      D := Editor.Build_Candidate_Discovery.Discover_Build_Candidates (Context);
      Editor.Build_UI.Show (S);
      Editor.Build_UI.Set_Build_Candidates (S, D.Candidates, "discovered");
      Editor.Build_UI.Select_Build_Candidate
        (S, To_String (D.Candidates.Element (0).Candidate_Id));
      Editor.Build_UI.Acknowledge_Consent (S);
      Ada.Directories.Delete_File (Root & "/demo.gpr");

      R := Editor.Build_Candidate_Refresh.Refresh_Build_Candidates (S, Context);

      Assert (R.Status = Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_No_Candidates,
              "refresh reflects disappeared candidate source");
      Assert (R.Selected_Candidate_Cleared,
              "disappeared selected candidate is cleared as stale");
      Assert (R.Consent_Invalidated,
              "clearing stale selected candidate invalidates consent");
      Assert (not S.Consent_Acknowledged,
              "stale candidate is not converted into consented manual request");
      Assert (To_String (S.Selected_Build_Candidate_Id)'Length = 0,
              "stale selected candidate id is removed");
      Assert (S.Selected_Candidate_Stale,
              "Build UI snapshots stale selected candidate warning");
   end Test_Refresh_Clears_Stale_Selected_Candidate_And_Consent;

   procedure Test_Refresh_Clears_Materially_Changed_Selected_Candidate
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      S : Editor.Build_UI.Public_Build_UI_State;
      Old_List : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
      New_List : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
      Old_C : Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Gprbuild_Candidate (Root, "demo.gpr");
      New_C : Editor.Build_Candidates.Build_Candidate_Record := Old_C;
      R : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
      Before : Editor.Build_UI.Public_Build_UI_State;
   begin
      Reset_Fixture;
      Write_File (Root & "/demo.gpr", "project Demo is end Demo;");
      New_C.Structured_Arguments.Clear;
      New_C.Structured_Arguments.Append (To_Unbounded_String ("-P"));
      New_C.Structured_Arguments.Append (To_Unbounded_String ("changed.gpr"));
      Old_List.Append (Old_C);
      New_List.Append (New_C);
      Editor.Build_UI.Show (S);
      Editor.Build_UI.Set_Build_Candidates (S, Old_List, "discovered");
      Editor.Build_UI.Select_Build_Candidate (S, To_String (Old_C.Candidate_Id));
      Editor.Build_UI.Acknowledge_Consent (S);
      Before := S;
      R.Status := Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Succeeded;
      R.Message := To_Unbounded_String ("refreshed");
      R.Candidate_Count := 1;

      Editor.Build_Candidate_Refresh.Reconcile_Selected_Build_Candidate_After_Refresh
        (S, Before, New_List, R);

      Assert (R.Selected_Candidate_Cleared,
              "material change clears selected candidate under explicit stale policy");
      Assert (R.Consent_Invalidated,
              "material change invalidates consent");
      Assert (not S.Consent_Acknowledged,
              "materially changed candidate cannot retain consent");
   end Test_Refresh_Clears_Materially_Changed_Selected_Candidate;

   procedure Test_Refresh_Clears_Unselected_Request_Path
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      S : Editor.Build_UI.Public_Build_UI_State;
      Args : Editor.Build_UI.Build_UI_Argument_Vector := Editor.Build_UI.Empty_Arguments;
      R : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
   begin
      Reset_Fixture;
      Editor.Build_UI.Show (S);
      Editor.Build_UI.Select_Tool (S, Editor.Build_UI.Build_UI_GPRbuild);
      Editor.Build_UI.Append_Argument (Args, "-Pmanual.gpr");
      Editor.Build_UI.Set_Structured_Arguments (S, Args);
      Editor.Build_UI.Select_Working_Context
        (S, Editor.Build_Working_Context.Current_Project_Root (Root));

      R := Editor.Build_Candidate_Refresh.Refresh_Build_Candidates
        (S, Editor.Build_Working_Context.Current_Project_Root (Root));

      Assert (not R.Manual_Request_Preserved,
              "refresh does not preserve a runnable manual request path without a selected candidate");
      Assert (To_String (S.Selected_Build_Candidate_Id)'Length = 0,
              "refresh does not select first candidate");
      Assert (S.Selected_Build_Tool = Editor.Build_UI.Build_UI_No_Tool,
              "refresh clears unselected request tool state");
      Assert (Editor.Build_UI.Argument_Count (S.Structured_Arguments) = 0,
              "refresh clears unselected request argv tokens");
      Assert (Editor.Build_UI.Validate_Build_UI_State (S) =
                Editor.Build_UI.Build_UI_Rejected_No_Candidate_Selected,
              "keeps unselected manual request state invalid for build.run");
   end Test_Refresh_Clears_Unselected_Request_Path;

   procedure Test_Candidate_Refresh_Audit_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      S : Editor.Build_UI.Public_Build_UI_State;
      Before : Editor.Build_UI.Public_Build_UI_State;
      R : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
   begin
      Reset_Fixture;
      Write_File (Root & "/alire.toml", "name = ""demo""");
      Editor.Build_UI.Show (S);
      Before := S;
      R := Editor.Build_Candidate_Refresh.Refresh_Build_Candidates
        (S, Editor.Build_Working_Context.Current_Project_Root (Root));
      Assert (Editor.Build_Candidate_Refresh_Audit.Assert_Public_Build_Candidate_Refresh_Foundation_Coherent
                (Before, S, R),
              "candidate refresh foundation is coherent");
   end Test_Candidate_Refresh_Audit_Coherent;


   procedure Test_Repeated_Refresh_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Context : Editor.Build_Working_Context.Build_Working_Context_Record;
      S1 : Editor.Build_UI.Public_Build_UI_State;
      S2 : Editor.Build_UI.Public_Build_UI_State;
      R1 : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
      R2 : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
   begin
      Reset_Fixture;
      Write_File (Root & "/zeta.gpr", "project Zeta is end Zeta;");
      Write_File (Root & "/alpha.gpr", "project Alpha is end Alpha;");
      Write_File (Root & "/alire.toml", "name = ""demo""");
      Context := Editor.Build_Working_Context.Current_Project_Root (Root);
      Editor.Build_UI.Show (S1);
      Editor.Build_UI.Show (S2);

      R1 := Editor.Build_Candidate_Refresh.Refresh_Build_Candidates (S1, Context);
      R2 := Editor.Build_Candidate_Refresh.Refresh_Build_Candidates (S2, Context);

      Assert (Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Deterministic (R1, R2),
              "repeated refreshes over the same project state are deterministic");
      Assert (Editor.Build_Candidates.Assert_Build_Candidate_List_Is_Deterministic (S1.Build_Candidates),
              "visible candidate order is stable after refresh");
      Assert (To_String (S1.Build_Candidates.Element (0).Candidate_Id) =
                To_String (S2.Build_Candidates.Element (0).Candidate_Id),
              "candidate identities are stable across refreshes");
   end Test_Repeated_Refresh_Is_Deterministic;

   procedure Test_No_Candidate_Refresh_Does_Not_Reuse_Cache
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Context : Editor.Build_Working_Context.Build_Working_Context_Record;
      S : Editor.Build_UI.Public_Build_UI_State;
      R : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
   begin
      Reset_Fixture;
      Write_File (Root & "/demo.gpr", "project Demo is end Demo;");
      Context := Editor.Build_Working_Context.Current_Project_Root (Root);
      Editor.Build_UI.Show (S);
      R := Editor.Build_Candidate_Refresh.Refresh_Build_Candidates (S, Context);
      Assert (R.Candidate_Count = 1, "precondition: initial candidate exists");

      Ada.Directories.Delete_File (Root & "/demo.gpr");
      Write_File (Root & "/Makefile", "all:");
      Write_File (Root & "/package.json", "{}");
      R := Editor.Build_Candidate_Refresh.Refresh_Build_Candidates (S, Context);

      Assert (R.Status = Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_No_Candidates,
              "unsupported metadata yields canonical no-candidates status");
      Assert (Editor.Build_UI.Candidate_Count (S) = 0,
              "no-candidate refresh does not reuse previous candidate cache");
      Assert (To_String (S.Selected_Build_Candidate_Id)'Length = 0,
              "no-candidate refresh does not fabricate selection");
   end Test_No_Candidate_Refresh_Does_Not_Reuse_Cache;

   procedure Test_Unselected_Request_Consent_Does_Not_Survive_Refresh
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      S : Editor.Build_UI.Public_Build_UI_State;
      Args : Editor.Build_UI.Build_UI_Argument_Vector := Editor.Build_UI.Empty_Arguments;
      R : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
      Before_Identity : Unbounded_String;
   begin
      Reset_Fixture;
      Write_File (Root & "/demo.gpr", "project Demo is end Demo;");
      Editor.Build_UI.Show (S);
      Editor.Build_UI.Select_Tool (S, Editor.Build_UI.Build_UI_GPRbuild);
      Editor.Build_UI.Append_Argument (Args, "-P");
      Editor.Build_UI.Append_Argument (Args, "manual.gpr");
      Editor.Build_UI.Set_Structured_Arguments (S, Args);
      Editor.Build_UI.Select_Working_Context
        (S, Editor.Build_Working_Context.Current_Project_Root (Root));
      Editor.Build_UI.Acknowledge_Consent (S);
      Before_Identity := S.Consent_Request_Identity;

      R := Editor.Build_Candidate_Refresh.Refresh_Build_Candidates
        (S, Editor.Build_Working_Context.Current_Project_Root (Root));

      Assert (not R.Manual_Request_Preserved,
              "refresh records no preserved manual request without candidate selection");
      Assert (not S.Consent_Acknowledged,
              "does not preserve consent for an unselected request");
      Assert (To_String (S.Consent_Request_Identity)'Length = 0,
              "clears consent identity without a selected candidate");
      Assert (To_String (S.Selected_Build_Candidate_Id)'Length = 0,
              "refresh does not auto-convert an unselected request to candidate mode");
   end Test_Unselected_Request_Consent_Does_Not_Survive_Refresh;

   procedure Test_Identity_Collision_Clears_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      S : Editor.Build_UI.Public_Build_UI_State;
      Old_List : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
      New_List : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
      C : Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Gprbuild_Candidate (Root, "demo.gpr");
      R : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
      Before : Editor.Build_UI.Public_Build_UI_State;
   begin
      Old_List.Append (C);
      New_List.Append (C);
      New_List.Append (C);
      Editor.Build_UI.Show (S);
      Editor.Build_UI.Set_Build_Candidates (S, Old_List, "discovered");
      Editor.Build_UI.Select_Build_Candidate (S, To_String (C.Candidate_Id));
      Editor.Build_UI.Acknowledge_Consent (S);
      Before := S;
      R.Status := Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Succeeded;
      R.Message := To_Unbounded_String ("refreshed");
      R.Candidate_Count := 2;

      Editor.Build_Candidate_Refresh.Reconcile_Selected_Build_Candidate_After_Refresh
        (S, Before, New_List, R);

      Assert (R.Selected_Candidate_Cleared,
              "duplicate refreshed candidate identity clears stale selection deterministically");
      Assert (R.Consent_Invalidated and then not S.Consent_Acknowledged,
              "identity collision invalidates stale consent");
   end Test_Identity_Collision_Clears_Selection;

   procedure Test_Display_Label_Change_Uses_Request_Identity_Policy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      S : Editor.Build_UI.Public_Build_UI_State;
      Old_List : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
      New_List : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
      Old_C : Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Gprbuild_Candidate (Root, "demo.gpr");
      New_C : Editor.Build_Candidates.Build_Candidate_Record := Old_C;
      R : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
      Before : Editor.Build_UI.Public_Build_UI_State;
   begin
      New_C.Display_Label := To_Unbounded_String ("Renamed display-only label");
      Old_List.Append (Old_C);
      New_List.Append (New_C);
      Editor.Build_UI.Show (S);
      Editor.Build_UI.Set_Build_Candidates (S, Old_List, "discovered");
      Editor.Build_UI.Select_Build_Candidate (S, To_String (Old_C.Candidate_Id));
      Editor.Build_UI.Acknowledge_Consent (S);
      Before := S;
      R.Status := Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Succeeded;
      R.Message := To_Unbounded_String ("refreshed");
      R.Candidate_Count := 1;

      Editor.Build_Candidate_Refresh.Reconcile_Selected_Build_Candidate_After_Refresh
        (S, Before, New_List, R);

      Assert (R.Selected_Candidate_Preserved,
              "display-only label change preserves material candidate selection");
      Assert (S.Consent_Acknowledged,
              "display-only label policy preserves unchanged request consent");
      Assert (To_String (S.Build_Target_Label) = To_String (Before.Build_Target_Label),
              "request label stays stable when consent identity includes it");
   end Test_Display_Label_Change_Uses_Request_Identity_Policy;


   procedure Test_Canonical_Refresh_Audit_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      S : Editor.Build_UI.Public_Build_UI_State;
      Before : Editor.Build_UI.Public_Build_UI_State;
      R : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
   begin
      Reset_Fixture;
      Write_File (Root & "/alire.toml", "name = ""demo""");
      Write_File (Root & "/demo.gpr", "project Demo is end Demo;");
      Editor.Build_UI.Show (S);
      Before := S;

      R := Editor.Build_Candidate_Refresh.Refresh_Build_Candidates
        (S, Editor.Build_Working_Context.Current_Project_Root (Root));

      Assert (Editor.Build_Candidate_Refresh_Audit.Assert_Public_Build_Candidate_Refresh_Canonical_Coherent
                (Before, S, R),
              "canonical refresh ownership audit is coherent");
      Assert (Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Canonical_Path
                (Before, S, R),
              "explicit refresh uses the canonical bounded refresh path");
      Assert (not S.Candidate_Applied_To_Request
                and then To_String (S.Selected_Build_Candidate_Id)'Length = 0,
              "refresh does not auto-select or apply a candidate");
   end Test_Canonical_Refresh_Audit_Coherent;

   procedure Test_Candidate_Material_Identity_Is_Canonical
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Base : Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Gprbuild_Candidate (Root, "demo.gpr");
      Display_Only : Editor.Build_Candidates.Build_Candidate_Record := Base;
      Materially_Changed : Editor.Build_Candidates.Build_Candidate_Record := Base;
      Base_Material : constant String :=
        Editor.Build_Candidate_Refresh.Build_Candidate_Material_Identity (Base);
   begin
      Display_Only.Display_Label := To_Unbounded_String ("Display-only rename");
      Display_Only.Validation_Message := To_Unbounded_String ("Display-only status text");
      Materially_Changed.Structured_Arguments.Clear;
      Materially_Changed.Structured_Arguments.Append (To_Unbounded_String ("-P"));
      Materially_Changed.Structured_Arguments.Append
        (To_Unbounded_String ("changed.gpr"));

      Assert (Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Identity_Canonical
                (Base),
              "candidate identity helper is canonical");
      Assert (Base_Material =
                Editor.Build_Candidate_Refresh.Build_Candidate_Material_Identity
                  (Display_Only),
              "display-only fields are not material identity");
      Assert (Editor.Build_Candidate_Refresh.Candidate_Material_Matches
                (Base, Display_Only),
              "material comparison ignores display-only drift");
      Assert (not Editor.Build_Candidate_Refresh.Candidate_Material_Matches
                (Base, Materially_Changed),
              "material comparison catches structured request drift");
   end Test_Candidate_Material_Identity_Is_Canonical;

   procedure Test_Failed_Refresh_Is_Status_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      S : Editor.Build_UI.Public_Build_UI_State;
      Before : Editor.Build_UI.Public_Build_UI_State;
      R : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
      D : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result;
   begin
      Reset_Fixture;
      Write_File (Root & "/demo.gpr", "project Demo is end Demo;");
      D := Editor.Build_Candidate_Discovery.Discover_Build_Candidates
        (Editor.Build_Working_Context.Current_Project_Root (Root));
      Editor.Build_UI.Show (S);
      Editor.Build_UI.Set_Build_Candidates (S, D.Candidates, "discovered");
      Editor.Build_UI.Select_Build_Candidate
        (S, To_String (D.Candidates.Element (0).Candidate_Id));
      Before := S;

      R := Editor.Build_Candidate_Refresh.Refresh_Build_Candidates
        (S, Editor.Build_Working_Context.Unsafe_Context
              (Editor.Build_Working_Context.Build_Working_Context_Current_Project_Root,
               "../outside",
               Editor.Build_Working_Context.Working_Context_Source_Raw_Text,
               "../outside"));

      Assert (R.Status = Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Failed,
              "rejected refresh context is reported as failed refresh");
      Assert (Editor.Build_UI.Candidate_Count (S) = Editor.Build_UI.Candidate_Count (Before),
              "failed refresh does not replace candidate list");
      Assert (To_String (S.Selected_Build_Candidate_Id) =
                To_String (Before.Selected_Build_Candidate_Id),
              "failed refresh does not repair or clear selection");
      Assert (Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Canonical_Path
                (Before, S, R),
              "failed refresh remains a canonical status-only path");
   end Test_Failed_Refresh_Is_Status_Only;

   procedure Test_Frontdoor_And_Build_Run_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      S : Editor.Build_UI.Public_Build_UI_State;
      Before : Editor.Build_UI.Public_Build_UI_State;
      R : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
   begin
      Reset_Fixture;
      Write_File (Root & "/demo.gpr", "project Demo is end Demo;");
      Editor.Build_UI.Show (S);
      Before := S;
      R := Editor.Build_Candidate_Refresh.Refresh_Build_Candidates
        (S, Editor.Build_Working_Context.Current_Project_Root (Root));

      Assert (Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Not_Frontdoor_Payload
                (S),
              "palette/keybinding frontdoors carry no candidate payload");
      Assert (Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Not_Build_Run_Side_Effect
                (Before, S, R),
              "refresh does not become a hidden build.run side effect");
      Assert (not S.Pending_Public_Build_Request,
              "refresh does not enqueue or auto-run a build request");
   end Test_Frontdoor_And_Build_Run_Boundaries;


   procedure Test_Final_Freeze_Canonical_Path_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      S : Editor.Build_UI.Public_Build_UI_State;
      Before : Editor.Build_UI.Public_Build_UI_State;
      R : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
   begin
      Reset_Fixture;
      Write_File (Root & "/alire.toml", "name = ""demo""");
      Write_File (Root & "/demo.gpr", "project Demo is end Demo;");
      Ada.Directories.Create_Path (Root & "/nested");
      Write_File (Root & "/nested/ignored.gpr", "project Ignored is end Ignored;");

      Editor.Build_UI.Show (S);
      Before := S;
      R := Editor.Build_Candidate_Refresh.Refresh_Build_Candidates
        (S, Editor.Build_Working_Context.Current_Project_Root (Root));

      Assert (R.Status = Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Succeeded,
              "final freeze refresh succeeds through canonical path");
      Assert (R.Candidate_Count = 3,
              "final freeze keeps bounded discovery including nested GPR files");
      Assert (Editor.Build_Candidate_Refresh_Audit.Assert_Public_Build_Candidate_Refresh_Final_Freeze_Coherent
                (Before, S, R),
              "final candidate refresh freeze is coherent");
      Assert (Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Final_No_Auto_Select
                (Before, S, R),
              "final freeze forbids refresh auto-selection");
      Assert (Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Final_No_Auto_Consent
                (Before, S),
              "final freeze forbids refresh auto-consent");
      Assert (Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Final_No_Auto_Run
                (Before, S, R),
              "final freeze forbids refresh auto-run");
      Assert (Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Final_Not_Frontdoor_Payload
                (S),
              "final freeze forbids palette/keybinding candidate payloads");
      Assert (not S.Pending_Public_Build_Request,
              "final freeze does not create a build.run request");
      Assert (S.Candidate_Refresh_Status = Editor.Build_UI.Build_Candidate_Refresh_Succeeded,
              "final freeze snapshots refresh status only");
   end Test_Final_Freeze_Canonical_Path_Coherent;

   procedure Test_Final_Freeze_Identity_Stale_And_Consent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      S : Editor.Build_UI.Public_Build_UI_State;
      Before : Editor.Build_UI.Public_Build_UI_State;
      Old_List : Editor.Build_Candidates.Build_Candidate_Vector;
      Same_List : Editor.Build_Candidates.Build_Candidate_Vector;
      Changed_List : Editor.Build_Candidates.Build_Candidate_Vector;
      Old_C : Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Gprbuild_Candidate (Root, "demo.gpr");
      Same_C : Editor.Build_Candidates.Build_Candidate_Record := Old_C;
      Changed_C : Editor.Build_Candidates.Build_Candidate_Record := Old_C;
      R : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
   begin
      Same_C.Display_Label := To_Unbounded_String ("Display only changed");
      Changed_C.Structured_Arguments.Clear;
      Changed_C.Structured_Arguments.Append (To_Unbounded_String ("-P"));
      Changed_C.Structured_Arguments.Append (To_Unbounded_String ("changed.gpr"));

      Old_List.Append (Old_C);
      Same_List.Append (Same_C);
      Changed_List.Append (Changed_C);

      Editor.Build_UI.Show (S);
      Editor.Build_UI.Set_Build_Candidates (S, Old_List, "discovered");
      Editor.Build_UI.Select_Build_Candidate (S, To_String (Old_C.Candidate_Id));
      Editor.Build_UI.Acknowledge_Consent (S);
      Before := S;

      R.Status := Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Succeeded;
      R.Message := To_Unbounded_String ("refreshed");
      R.Candidate_Count := 1;
      R.Discovery.Candidates := Same_List;
      Editor.Build_Candidate_Refresh.Reconcile_Selected_Build_Candidate_After_Refresh
        (S, Before, Same_List, R);

      Assert (Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Identity_Final_Canonical
                (Old_C),
              "final freeze keeps candidate identity centralized");
      Assert (Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Material_Identity_Final_Canonical
                (Old_C),
              "final freeze keeps material identity centralized");
      Assert (Editor.Build_Candidate_Refresh.Candidate_Material_Matches (Old_C, Same_C),
              "final freeze ignores display-only material drift");
      Assert (R.Selected_Candidate_Preserved and then S.Consent_Acknowledged,
              "final freeze preserves consent only for unchanged request identity");
      Assert (Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Stale_Reconciliation_Final_Canonical
                (Before, S, R),
              "final freeze preserves unchanged selection through canonical reconciliation");

      Before := S;
      R.Status := Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Succeeded;
      R.Message := To_Unbounded_String ("refreshed");
      R.Candidate_Count := 1;
      R.Selected_Candidate_Preserved := False;
      R.Selected_Candidate_Cleared := False;
      R.Consent_Invalidated := False;
      R.Manual_Request_Preserved := False;
      R.Discovery.Candidates := Changed_List;
      Editor.Build_Candidate_Refresh.Reconcile_Selected_Build_Candidate_After_Refresh
        (S, Before, Changed_List, R);

      Assert (not Editor.Build_Candidate_Refresh.Candidate_Material_Matches
                (Old_C, Changed_C),
              "final freeze treats argv drift as material");
      Assert (R.Selected_Candidate_Cleared,
              "final freeze clears materially stale selected candidate");
      Assert (R.Consent_Invalidated and then not S.Consent_Acknowledged,
              "final freeze invalidates consent after material identity change");
      Assert (To_String (S.Selected_Build_Candidate_Id)'Length = 0,
              "final freeze leaves no executable stale candidate id");
   end Test_Final_Freeze_Identity_Stale_And_Consent;

   procedure Test_Final_Freeze_Manual_Request_Independent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      S : Editor.Build_UI.Public_Build_UI_State;
      Before : Editor.Build_UI.Public_Build_UI_State;
      Args : Editor.Build_UI.Build_UI_Argument_Vector :=
        Editor.Build_UI.Empty_Arguments;
      R : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
   begin
      Reset_Fixture;
      Editor.Build_UI.Show (S);
      Editor.Build_UI.Select_Tool (S, Editor.Build_UI.Build_UI_GPRbuild);
      Editor.Build_UI.Append_Argument (Args, "-P");
      Editor.Build_UI.Append_Argument (Args, "manual.gpr");
      Editor.Build_UI.Set_Structured_Arguments (S, Args);
      Editor.Build_UI.Set_Working_Context_Label (S, Root);
      Editor.Build_UI.Acknowledge_Consent (S);
      Before := S;

      R := Editor.Build_Candidate_Refresh.Refresh_Build_Candidates
        (S, Editor.Build_Working_Context.Current_Project_Root (Root));

      Assert (R.Status = Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_No_Candidates,
              "final freeze reports no-candidates without replacing manual request");
      Assert (not R.Manual_Request_Preserved,
              "final freeze does not preserve manual request mode during refresh");
      Assert (S.Selected_Build_Tool = Editor.Build_UI.Build_UI_No_Tool,
              "final freeze clears unselected request tool selection");
      Assert (Editor.Build_UI.Argument_Count (S.Structured_Arguments) = 0,
              "final freeze clears unselected request argv tokens");
      Assert (To_String (S.Selected_Build_Candidate_Id)'Length = 0,
              "final freeze does not convert manual mode to candidate mode");
      Assert (not S.Consent_Acknowledged,
              "final freeze clears consent without selected candidate identity");
      Assert (Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Final_Canonical_Path
                (Before, S, R),
              "final freeze manual refresh remains canonical");
   end Test_Final_Freeze_Manual_Request_Independent;

   procedure Test_Final_Freeze_Failed_And_Persistence_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      S : Editor.Build_UI.Public_Build_UI_State;
      Before : Editor.Build_UI.Public_Build_UI_State;
      R : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
      D : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result;
   begin
      Reset_Fixture;
      Write_File (Root & "/demo.gpr", "project Demo is end Demo;");
      D := Editor.Build_Candidate_Discovery.Discover_Build_Candidates
        (Editor.Build_Working_Context.Current_Project_Root (Root));
      Editor.Build_UI.Show (S);
      Editor.Build_UI.Set_Build_Candidates (S, D.Candidates, "discovered");
      Editor.Build_UI.Select_Build_Candidate
        (S, To_String (D.Candidates.Element (0).Candidate_Id));
      Before := S;

      R := Editor.Build_Candidate_Refresh.Refresh_Build_Candidates
        (S, Editor.Build_Working_Context.Unsafe_Context
              (Editor.Build_Working_Context.Build_Working_Context_Current_Project_Root,
               "../outside",
               Editor.Build_Working_Context.Working_Context_Source_Raw_Text,
               "../outside"));

      Assert (R.Status = Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Failed,
              "final freeze failed refresh remains status-only");
      Assert (Editor.Build_UI.Candidate_Count (S) = Editor.Build_UI.Candidate_Count (Before),
              "final freeze failed refresh does not replace candidates");
      Assert (To_String (S.Selected_Build_Candidate_Id) =
                To_String (Before.Selected_Build_Candidate_Id),
              "final freeze failed refresh does not repair stale selection");
      Assert (Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Final_Not_Build_Run_Side_Effect
                (Before, S, R),
              "final freeze failed refresh is not hidden build.run refresh");
      Assert (Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Final_Not_Render_Owned
                (Before, S, R),
              "final freeze keeps render as snapshot-only consumer");
      Assert (Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Final_Not_Diagnostics_Result_Output_Mutation
                (Before, S, R),
              "final freeze does not mutate diagnostics/result/output surfaces");
      Assert (Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Final_Persistence_Excluded
                (S),
              "final freeze excludes refresh state from persistence domains");
   end Test_Final_Freeze_Failed_And_Persistence_Boundaries;



   function Lifecycle_Root (Suffix : String) return String is
   begin
      Ada.Directories.Create_Path ("/tmp/editor-tests");
      return "/tmp/editor-tests/lifecycle_" & Suffix;
   end Lifecycle_Root;

   procedure Reset_Lifecycle_Root (Suffix : String) is
      Root : constant String := Lifecycle_Root (Suffix);
   begin
      if Ada.Directories.Exists (Root) then
         Ada.Directories.Delete_Tree (Root);
      end if;
      Ada.Directories.Create_Path (Root);
   end Reset_Lifecycle_Root;

   procedure Test_Project_Open_Refreshes_Through_Canonical_Path
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Lifecycle_Root ("open");
      S : Editor.Build_UI.Public_Build_UI_State;
      Before : Editor.Build_UI.Public_Build_UI_State;
      R : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
   begin
      Reset_Lifecycle_Root ("open");
      Write_File (Root & "/demo.gpr", "project Demo is end Demo;");
      Editor.Build_UI.Show (S);
      Before := S;

      R := Editor.Build_Candidate_Refresh.Refresh_Build_Candidates_After_Project_Open
        (S, Editor.Build_Working_Context.Current_Project_Root (Root), True);

      Assert (R.Status = Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Succeeded,
              "project open refresh succeeds through canonical path");
      Assert (Editor.Build_UI.Candidate_Count (S) = 1,
              "project open installs opened-project candidates");
      Assert (To_String (S.Selected_Build_Candidate_Id)'Length = 0,
              "project open does not auto-select a candidate");
      Assert (not S.Consent_Acknowledged,
              "project open does not auto-consent");
      Assert (not S.Pending_Public_Build_Request,
              "project open does not auto-run build");
      Assert (Editor.Build_Candidate_Refresh.Assert_Project_Lifecycle_Build_Candidate_Integration_Coherent
                (Before, S, R),
              "project open lifecycle integration remains coherent");
   end Test_Project_Open_Refreshes_Through_Canonical_Path;

   procedure Test_Project_Switch_Reconciles_Selection_And_Consent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root_A : constant String := Lifecycle_Root ("switch_a");
      Root_B : constant String := Lifecycle_Root ("switch_b");
      S : Editor.Build_UI.Public_Build_UI_State;
      R : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
      Before_Switch : Editor.Build_UI.Public_Build_UI_State;
   begin
      Reset_Lifecycle_Root ("switch_a");
      Reset_Lifecycle_Root ("switch_b");
      Write_File (Root_A & "/alpha.gpr", "project Alpha is end Alpha;");
      Write_File (Root_B & "/beta.gpr", "project Beta is end Beta;");

      Editor.Build_UI.Show (S);
      R := Editor.Build_Candidate_Refresh.Refresh_Build_Candidates_After_Project_Open
        (S, Editor.Build_Working_Context.Current_Project_Root (Root_A), True);
      Assert (R.Status = Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Succeeded,
              "setup open refresh succeeds");
      Editor.Build_UI.Select_Build_Candidate
        (S, To_String (S.Build_Candidates.Element (0).Candidate_Id));
      Editor.Build_UI.Acknowledge_Consent (S);
      Assert (S.Consent_Acknowledged, "setup starts with candidate consent");

      Before_Switch := S;
      R := Editor.Build_Candidate_Refresh.Refresh_Build_Candidates_After_Project_Switch
        (S, Editor.Build_Working_Context.Current_Project_Root (Root_B), True);

      Assert (R.Status = Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Succeeded,
              "project switch refresh succeeds");
      Assert (Editor.Build_UI.Candidate_Count (S) = 1,
              "project switch replaces candidate list");
      Assert (To_String (S.Selected_Build_Candidate_Id)'Length = 0,
              "project switch clears stale selected candidate");
      Assert (not S.Consent_Acknowledged,
              "project switch invalidates stale candidate consent");
      Assert (R.Selected_Candidate_Cleared,
              "project switch records stale selection clear");
      Assert (R.Consent_Invalidated,
              "project switch records consent invalidation");
      Assert (Editor.Build_Candidate_Refresh.Assert_Project_Lifecycle_Build_Candidate_Integration_Coherent
                (Before_Switch, S, R),
              "project switch lifecycle integration remains coherent");
   end Test_Project_Switch_Reconciles_Selection_And_Consent;

   procedure Test_Project_Close_Clears_Executable_Candidates
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Lifecycle_Root ("close");
      S : Editor.Build_UI.Public_Build_UI_State;
      R : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
      Before_Close : Editor.Build_UI.Public_Build_UI_State;
   begin
      Reset_Lifecycle_Root ("close");
      Write_File (Root & "/demo.gpr", "project Demo is end Demo;");
      Editor.Build_UI.Show (S);
      R := Editor.Build_Candidate_Refresh.Refresh_Build_Candidates_After_Project_Open
        (S, Editor.Build_Working_Context.Current_Project_Root (Root), True);
      Editor.Build_UI.Select_Build_Candidate
        (S, To_String (S.Build_Candidates.Element (0).Candidate_Id));
      Editor.Build_UI.Acknowledge_Consent (S);
      Before_Close := S;

      R := Editor.Build_Candidate_Refresh.Clear_Build_Candidates_After_Project_Close (S);

      Assert (Editor.Build_UI.Candidate_Count (S) = 0,
              "project close clears candidate list");
      Assert (To_String (S.Selected_Build_Candidate_Id)'Length = 0,
              "project close clears selected candidate");
      Assert (not S.Consent_Acknowledged,
              "project close invalidates candidate consent");
      Assert (Editor.Build_UI.Validate_Build_UI_State (S) /= Editor.Build_UI.Build_UI_Valid,
              "project close leaves build.run unavailable");
      Assert (Editor.Build_Candidate_Refresh.Assert_Project_Close_Clears_Build_Candidates
                (Before_Close, S, R),
              "project close clear policy is coherent");
      Assert (Editor.Build_Candidate_Refresh.Assert_Project_Lifecycle_Build_Candidate_Integration_Coherent
                (Before_Close, S, R),
              "project close lifecycle integration remains coherent");
   end Test_Project_Close_Clears_Executable_Candidates;

   procedure Test_Failed_Project_Transition_Does_Not_Fabricate
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Lifecycle_Root ("failed");
      Failed_Root : constant String := Lifecycle_Root ("failed_missing");
      S : Editor.Build_UI.Public_Build_UI_State;
      R : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
      Before_Failed : Editor.Build_UI.Public_Build_UI_State;
   begin
      Reset_Lifecycle_Root ("failed");
      if Ada.Directories.Exists (Failed_Root) then
         Ada.Directories.Delete_Tree (Failed_Root);
      end if;
      Write_File (Root & "/demo.gpr", "project Demo is end Demo;");
      Editor.Build_UI.Show (S);
      R := Editor.Build_Candidate_Refresh.Refresh_Build_Candidates_After_Project_Open
        (S, Editor.Build_Working_Context.Current_Project_Root (Root), True);
      Editor.Build_UI.Select_Build_Candidate
        (S, To_String (S.Build_Candidates.Element (0).Candidate_Id));
      Editor.Build_UI.Acknowledge_Consent (S);
      Before_Failed := S;

      R := Editor.Build_Candidate_Refresh.Refresh_Build_Candidates_After_Project_Switch
        (S, Editor.Build_Working_Context.Current_Project_Root (Failed_Root), False);

      Assert (R.Status = Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Failed,
              "failed project switch is status-only");
      Assert (Editor.Build_UI.Candidate_Count (S) = Editor.Build_UI.Candidate_Count (Before_Failed),
              "failed project switch preserves prior candidate state");
      Assert (S.Consent_Acknowledged = Before_Failed.Consent_Acknowledged,
              "failed project switch does not restore or clear consent");
      Assert (Editor.Build_Candidate_Refresh.Assert_Failed_Project_Transition_Does_Not_Fabricate_Candidates
                (Before_Failed, S, R),
              "failed transition does not fabricate candidates");
      Assert (Editor.Build_Candidate_Refresh.Assert_Project_Lifecycle_Build_Candidate_Integration_Coherent
                (Before_Failed, S, R),
              "failed transition lifecycle integration remains coherent");
   end Test_Failed_Project_Transition_Does_Not_Fabricate;

   procedure Test_Project_Reset_And_Manual_Request_Boundary
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Lifecycle_Root ("reset");
      S : Editor.Build_UI.Public_Build_UI_State;
      Args : Editor.Build_UI.Build_UI_Argument_Vector := Editor.Build_UI.Empty_Arguments;
      Before_Reset : Editor.Build_UI.Public_Build_UI_State;
      R : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
   begin
      Reset_Lifecycle_Root ("reset");
      Write_File (Root & "/alire.toml", "name = ""demo""");
      Editor.Build_UI.Show (S);
      Editor.Build_UI.Select_Tool (S, Editor.Build_UI.Build_UI_Alire);
      Editor.Build_UI.Append_Argument (Args, "build");
      Editor.Build_UI.Set_Structured_Arguments (S, Args);
      Editor.Build_UI.Select_Working_Context
        (S, Editor.Build_Working_Context.Current_Project_Root (Root));
      Before_Reset := S;

      R := Editor.Build_Candidate_Refresh.Refresh_Build_Candidates_After_Project_Reset
        (S, Editor.Build_Working_Context.Current_Project_Root (Root), True);

      Assert (R.Status = Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Succeeded,
              "project reset refreshes retained project context");
      Assert (Editor.Build_UI.Candidate_Count (S) = 1,
              "project reset updates candidates");
      Assert (To_String (S.Selected_Build_Candidate_Id)'Length = 0,
              "project reset does not auto-convert manual request to candidate request");
      Assert (S.Selected_Build_Tool = Editor.Build_UI.Build_UI_No_Tool,
              "project reset clears unselected request tool");
      Assert (Editor.Build_UI.Argument_Count (S.Structured_Arguments) = 0,
              "project reset clears unselected structured argv");
      Assert (not R.Manual_Request_Preserved,
              "project reset records no manual request preservation");
      Assert (Editor.Build_Candidate_Refresh.Assert_Project_Lifecycle_Build_Candidate_Integration_Coherent
                (Before_Reset, S, R),
              "project reset lifecycle integration remains coherent");
   end Test_Project_Reset_And_Manual_Request_Boundary;


   procedure Test_Project_Close_Clears_Unselected_Request_Shape
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Lifecycle_Root ("close_manual");
      S : Editor.Build_UI.Public_Build_UI_State;
      Args : Editor.Build_UI.Build_UI_Argument_Vector := Editor.Build_UI.Empty_Arguments;
      Before_Close : Editor.Build_UI.Public_Build_UI_State;
      R : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
   begin
      Reset_Lifecycle_Root ("close_manual");
      Write_File (Root & "/alire.toml", "name = ""demo""");
      Editor.Build_UI.Show (S);
      Editor.Build_UI.Select_Tool (S, Editor.Build_UI.Build_UI_Alire);
      Editor.Build_UI.Append_Argument (Args, "build");
      Editor.Build_UI.Set_Structured_Arguments (S, Args);
      Editor.Build_UI.Select_Working_Context
        (S, Editor.Build_Working_Context.Current_Project_Root (Root));
      Editor.Build_UI.Acknowledge_Consent (S);
      Before_Close := S;

      R := Editor.Build_Candidate_Refresh.Clear_Build_Candidates_After_Project_Close (S);

      Assert (not R.Manual_Request_Preserved,
              "project close records no manual request preservation");
      Assert (S.Selected_Build_Tool = Editor.Build_UI.Build_UI_No_Tool,
              "project close clears unselected request tool selection");
      Assert (Editor.Build_UI.Argument_Count (S.Structured_Arguments) = 0,
              "project close clears unselected request structured argv");
      Assert (S.Selected_Working_Context.Kind =
                Editor.Build_Working_Context.Build_Working_Context_Unavailable,
              "project close invalidates working context after clearing request shape");
      Assert (not S.Consent_Acknowledged,
              "project close invalidates consent because request context changed");
      Assert (Editor.Build_UI.Validate_Build_UI_State (S) /= Editor.Build_UI.Build_UI_Valid,
              "project close keeps build.run unavailable after request clear");
      Assert (Editor.Build_Candidate_Refresh.Assert_Project_Lifecycle_Build_Candidate_Integration_Coherent
                (Before_Close, S, R),
              "project close clearing remains coherent");
   end Test_Project_Close_Clears_Unselected_Request_Shape;

   procedure Test_Project_Open_No_Candidates_Is_Lifecycle_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Lifecycle_Root ("open_empty");
      S : Editor.Build_UI.Public_Build_UI_State;
      Before : Editor.Build_UI.Public_Build_UI_State;
      R : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
   begin
      Reset_Lifecycle_Root ("open_empty");
      Editor.Build_UI.Show (S);
      Before := S;

      R := Editor.Build_Candidate_Refresh.Refresh_Build_Candidates_After_Project_Open
        (S, Editor.Build_Working_Context.Current_Project_Root (Root), True);

      Assert (R.Status = Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_No_Candidates,
              "project open reports no-candidates lifecycle state");
      Assert (Editor.Build_UI.Candidate_Count (S) = 0,
              "project open with no build metadata leaves no candidates");
      Assert (S.Candidate_Refresh_Status = Editor.Build_UI.Build_Candidate_Refresh_No_Candidates,
              "Build UI snapshot state records no candidates");
      Assert (To_String (S.Selected_Build_Candidate_Id)'Length = 0,
              "no-candidates lifecycle state does not auto-select");
      Assert (not S.Consent_Acknowledged,
              "no-candidates lifecycle state does not auto-consent");
      Assert (Editor.Build_Candidate_Refresh.Assert_Project_Lifecycle_Build_Candidate_Integration_Coherent
                (Before, S, R),
              "no-candidates lifecycle integration remains coherent");
   end Test_Project_Open_No_Candidates_Is_Lifecycle_State;



   procedure Test_Bounded_Nested_Gpr_Discovery_And_Ignores
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Context : Editor.Build_Working_Context.Build_Working_Context_Record;
      R : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result;
      Saw_App : Boolean := False;
      Saw_Tests : Boolean := False;
      Saw_Obj : Boolean := False;
      Saw_Bin : Boolean := False;
      Saw_Alire_Build : Boolean := False;
   begin
      Reset_Fixture;
      Write_File (Root & "/alire.toml", "name = ""demo""");
      Write_File (Root & "/demo.gpr", "project Demo is end Demo;");
      Ada.Directories.Create_Path (Root & "/src/tools");
      Ada.Directories.Create_Path (Root & "/tests");
      Ada.Directories.Create_Path (Root & "/obj");
      Ada.Directories.Create_Path (Root & "/bin");
      Ada.Directories.Create_Path (Root & "/alire/build");
      Write_File (Root & "/src/tools/tools.gpr", "project Tools is end Tools;");
      Write_File (Root & "/tests/tests.gpr", "project Tests is end Tests;");
      Write_File (Root & "/obj/generated.gpr", "project Generated is end Generated;");
      Write_File (Root & "/bin/generated.gpr", "project Generated is end Generated;");
      Write_File (Root & "/alire/build/generated.gpr", "project Generated is end Generated;");

      Context := Editor.Build_Working_Context.Current_Project_Root (Root);
      R := Editor.Build_Candidate_Discovery.Discover_Build_Candidates (Context);

      Assert (R.Status = Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Complete,
              "nested discovery completes under project root");
      Assert (R.Alire_Candidate_Count = 1,
              "tracks Alire candidate count");
      Assert (R.Gpr_Candidate_Count = 3,
              "discovers root and bounded nested GPR candidates only");
      Assert (R.Skipped_Directory_Count >= 3,
              "reports ignored generated directories");

      for Candidate of R.Candidates loop
         declare
            Label : constant String := To_String (Candidate.Display_Label);
         begin
            if Ada.Strings.Fixed.Index (Label, "src/tools/tools.gpr") > 0 then
               Saw_App := True;
            elsif Ada.Strings.Fixed.Index (Label, "tests/tests.gpr") > 0 then
               Saw_Tests := True;
            elsif Ada.Strings.Fixed.Index (Label, "obj/generated.gpr") > 0 then
               Saw_Obj := True;
            elsif Ada.Strings.Fixed.Index (Label, "bin/generated.gpr") > 0 then
               Saw_Bin := True;
            elsif Ada.Strings.Fixed.Index (Label, "alire/build/generated.gpr") > 0 then
               Saw_Alire_Build := True;
            end if;
         end;
      end loop;

      Assert (Saw_App and then Saw_Tests,
              "labels bounded nested GPR candidates by project-relative path");
      Assert (not Saw_Obj and then not Saw_Bin and then not Saw_Alire_Build,
              "ignores generated build-output directories");
      Assert (Editor.Build_Candidate_Discovery.Assert_Build_Candidate_Discovery_Depth_Coherent (R),
              "discovery depth audit is coherent");
   end Test_Bounded_Nested_Gpr_Discovery_And_Ignores;

   procedure Test_Ranking_Labels_And_Summary
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Context : Editor.Build_Working_Context.Build_Working_Context_Record;
      R : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result;
   begin
      Reset_Fixture;
      Write_File (Root & "/alire.toml", "name = ""demo""");
      Write_File (Root & "/candidate_fixture.gpr", "project Demo is end Demo;");
      Write_File (Root & "/zzz.gpr", "project Zzz is end Zzz;");
      Ada.Directories.Create_Path (Root & "/examples");
      Ada.Directories.Create_Path (Root & "/tests");
      Write_File (Root & "/examples/example.gpr", "project Example is end Example;");
      Write_File (Root & "/tests/tests.gpr", "project Tests is end Tests;");

      Context := Editor.Build_Working_Context.Current_Project_Root (Root);
      R := Editor.Build_Candidate_Discovery.Discover_Build_Candidates (Context);

      Assert (Natural (R.Candidates.Length) = 5,
              "ranking test discovers every supported source");
      Assert (R.Candidates.Element (0).Candidate_Kind =
                Editor.Build_Candidates.Build_Candidate_Alire_Project,
              "ranks root Alire manifest first");
      Assert (To_String (R.Candidates.Element (1).Display_Label) =
                "GPR: candidate_fixture.gpr",
              "ranks root GPR matching root directory before other GPR files");
      Assert (Ada.Strings.Fixed.Index (To_String (R.Message), "Alire") > 0
                and then Ada.Strings.Fixed.Index (To_String (R.Message), "GPR") > 0,
              "summary reports source-kind counts");
      Assert (Editor.Build_Candidates.Build_Candidate_Source_Kind_Label
                (R.Candidates.Element (0).Discovery_Source) = "Alire",
              "exposes candidate source labels");
      Assert (Editor.Build_Candidates.Build_Candidate_Project_Relative_Label
                (R.Candidates.Element (1)) = "candidate_fixture.gpr",
              "exposes project-relative candidate label");
   end Test_Ranking_Labels_And_Summary;



   procedure Test_Limits_Count_Alire_And_Gpr_Together
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Context : Editor.Build_Working_Context.Build_Working_Context_Record;
      R : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result;
   begin
      Reset_Fixture;
      Write_File (Root & "/alire.toml", "name = ""demo""");
      Ada.Directories.Create_Path (Root & "/many");
      for I in 1 .. 80 loop
         Write_File
           (Root & "/many/project_" & Ada.Strings.Fixed.Trim (Natural'Image (I), Ada.Strings.Both) & ".gpr",
            "project Many is end Many;");
      end loop;

      Context := Editor.Build_Working_Context.Current_Project_Root (Root);
      R := Editor.Build_Candidate_Discovery.Discover_Build_Candidates (Context);

      Assert (Natural (R.Candidates.Length) <= 64,
              "candidate limit counts Alire and GPR candidates together");
      Assert (R.Limit_Reached,
              "reports limit reached when extra GPR candidates are dropped");
      Assert (Editor.Build_Candidate_Discovery.Assert_Build_Candidate_Discovery_Bounded (R),
              "bounded audit remains true at the candidate limit");
   end Test_Limits_Count_Alire_And_Gpr_Together;

   procedure Test_Gpr_Staging_Uses_Candidate_Bound_And_File_Accounting
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Context : Editor.Build_Working_Context.Build_Working_Context_Record;
      R : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result;
      Saw_Primary : Boolean := False;
   begin
      Reset_Fixture;
      for I in 1 .. 96 loop
         Write_File
           (Root & "/aaa_bulk_" & Ada.Strings.Fixed.Trim (Natural'Image (I), Ada.Strings.Both) & ".gpr",
            "project Bulk is end Bulk;");
      end loop;
      Write_File
        (Root & "/candidate_fixture.gpr",
         "project Candidate_Fixture is end Candidate_Fixture;");

      Context := Editor.Build_Working_Context.Current_Project_Root (Root);
      R := Editor.Build_Candidate_Discovery.Discover_Build_Candidates (Context);

      for Candidate of R.Candidates loop
         if To_String (Candidate.Display_Label) = "GPR: candidate_fixture.gpr" then
            Saw_Primary := True;
         end if;
      end loop;

      Assert (Natural (R.Candidates.Length) <= 64,
              "GPR staging is capped by the candidate-count budget");
      Assert (R.Files_Inspected >= 97,
              "file accounting reflects observed GPR entries, not only retained candidates");
      Assert (R.Limit_Reached,
              "reports candidate staging overflow as a discovery limit");
      Assert (Saw_Primary,
              "bounded staging retains the deterministic primary root GPR candidate");
   end Test_Gpr_Staging_Uses_Candidate_Bound_And_File_Accounting;


   procedure Test_Unsafe_Relative_Candidate_Is_Disabled
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      C : Editor.Build_Candidates.Build_Candidate_Record;
   begin
      Reset_Fixture;
      C := Editor.Build_Candidates.Gprbuild_Candidate (Root, "../outside.gpr");

      Assert (Editor.Build_Candidates.Validate_Candidate (C) =
                Editor.Build_Candidates.Build_Candidate_Rejected_Unsafe_Source,
              "rejects GPR candidate paths that would escape the project root");
      Assert (Editor.Build_Candidates.Build_Candidate_Disabled_Reason (C) =
                "candidate path outside project root",
              "exposes a user-readable disabled reason for unsafe candidate paths");
   end Test_Unsafe_Relative_Candidate_Is_Disabled;


   procedure Test_Missing_Candidate_Source_Is_Unavailable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      C : Editor.Build_Candidates.Build_Candidate_Record;
   begin
      Reset_Fixture;
      C := Editor.Build_Candidates.Gprbuild_Candidate (Root, "missing.gpr");

      Assert (Editor.Build_Candidates.Validate_Candidate (C) =
                Editor.Build_Candidates.Build_Candidate_Unavailable,
              "reports missing discovered candidate sources as unavailable");
      Assert (Editor.Build_Candidates.Build_Candidate_Disabled_Reason (C) =
                "candidate path missing or unavailable",
              "exposes a user-readable missing-source disabled reason");
   end Test_Missing_Candidate_Source_Is_Unavailable;

   procedure Test_Discovery_Summary_Is_User_Readable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Context : Editor.Build_Working_Context.Build_Working_Context_Record;
      R : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result;
   begin
      Reset_Fixture;
      Write_File (Root & "/alire.toml", "name = ""demo""");
      Write_File (Root & "/demo.gpr", "project Demo is end Demo;");

      Context := Editor.Build_Working_Context.Current_Project_Root (Root);
      R := Editor.Build_Candidate_Discovery.Discover_Build_Candidates (Context);

      Assert (To_String (R.Message) = "Found 2 build candidates: 1 Alire, 1 GPR.",
              "discovery summary avoids Ada Image leading spaces and internal enum names; got: "
              & To_String (R.Message));
   end Test_Discovery_Summary_Is_User_Readable;


   procedure Test_No_Candidate_Limit_Summary_Is_Not_Silent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      R : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result;
   begin
      R.Status := Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_No_Candidates;
      R.Limit_Reached := True;
      R.Skipped_Directory_Count := 2;
      R.Message := To_Unbounded_String
        (Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Summary (R));

      Assert (To_String (R.Message) =
                "No build candidates found. Build candidate discovery limit reached. Skipped 2 directories.",
              "no-candidate summaries must still report discovery limits and skipped paths");
   end Test_No_Candidate_Limit_Summary_Is_Not_Silent;


   procedure Test_Limit_Truncation_Retains_Primary_Ranked_Candidate
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Context : Editor.Build_Working_Context.Build_Working_Context_Record;
      R : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result;
      Saw_Primary : Boolean := False;
   begin
      Reset_Fixture;
      for I in 1 .. 80 loop
         Write_File
           (Root & "/aaa_extra_" & Ada.Strings.Fixed.Trim (Natural'Image (I), Ada.Strings.Both) & ".gpr",
            "project Extra is end Extra;");
      end loop;
      Write_File
        (Root & "/candidate_fixture.gpr",
         "project Candidate_Fixture is end Candidate_Fixture;");

      Context := Editor.Build_Working_Context.Current_Project_Root (Root);
      R := Editor.Build_Candidate_Discovery.Discover_Build_Candidates (Context);

      for Candidate of R.Candidates loop
         if To_String (Candidate.Display_Label) = "GPR: candidate_fixture.gpr" then
            Saw_Primary := True;
         end if;
      end loop;

      Assert (R.Limit_Reached,
              "reports limit reached before dropping lower-ranked candidates");
      Assert (Saw_Primary,
              "applies deterministic ranking before candidate-limit truncation");
      Assert (Natural (R.Candidates.Length) <= 64,
              "limit truncation still enforces maximum retained candidates");
   end Test_Limit_Truncation_Retains_Primary_Ranked_Candidate;

   procedure Test_Root_Gpr_Not_Starved_By_Directory_Limit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Context : Editor.Build_Working_Context.Build_Working_Context_Record;
      R : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result;
      Saw_Primary : Boolean := False;
   begin
      Reset_Fixture;
      for I in 1 .. 160 loop
         Ada.Directories.Create_Path
           (Root & "/aaa_nested_" & Ada.Strings.Fixed.Trim (Natural'Image (I), Ada.Strings.Both));
      end loop;
      Write_File
        (Root & "/candidate_fixture.gpr",
         "project Candidate_Fixture is end Candidate_Fixture;");

      Context := Editor.Build_Working_Context.Current_Project_Root (Root);
      R := Editor.Build_Candidate_Discovery.Discover_Build_Candidates (Context);

      for Candidate of R.Candidates loop
         if To_String (Candidate.Display_Label) = "GPR: candidate_fixture.gpr" then
            Saw_Primary := True;
         end if;
      end loop;

      Assert (Saw_Primary,
              "inspects root candidate files before nested directories can consume scan limits");
      Assert (R.Limit_Reached,
              "still reports the directory limit after preserving root candidates");
   end Test_Root_Gpr_Not_Starved_By_Directory_Limit;

   procedure Test_Gpr_Not_Starved_By_Non_Candidate_File_Limit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Context : Editor.Build_Working_Context.Build_Working_Context_Record;
      R : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result;
      Saw_Gpr : Boolean := False;
   begin
      Reset_Fixture;
      for I in 1 .. 2100 loop
         Write_File
           (Root & "/aaa_non_candidate_" & Ada.Strings.Fixed.Trim (Natural'Image (I), Ada.Strings.Both) & ".txt",
            "not a project file");
      end loop;
      Write_File (Root & "/zzz_project.gpr", "project Zzz_Project is end Zzz_Project;");

      Context := Editor.Build_Working_Context.Current_Project_Root (Root);
      R := Editor.Build_Candidate_Discovery.Discover_Build_Candidates (Context);

      for Candidate of R.Candidates loop
         if To_String (Candidate.Display_Label) = "GPR: zzz_project.gpr" then
            Saw_Gpr := True;
         end if;
      end loop;

      Assert (Saw_Gpr,
              "prioritizes .gpr files before non-candidate files consume the file limit");
      Assert (R.Limit_Reached,
              "still reports the file limit after preserving candidate-bearing files");
   end Test_Gpr_Not_Starved_By_Non_Candidate_File_Limit;


   procedure Test_File_Limit_Blocks_Nested_Traversal
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Context : Editor.Build_Working_Context.Build_Working_Context_Record;
      R : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result;
      Saw_Root_Gpr : Boolean := False;
      Saw_Nested_Gpr : Boolean := False;
   begin
      Reset_Fixture;
      Ada.Directories.Create_Path (Root & "/nested");
      for I in 1 .. 2100 loop
         Write_File
           (Root & "/ordinary_" & Ada.Strings.Fixed.Trim (Natural'Image (I), Ada.Strings.Both) & ".txt",
            "ordinary source file");
      end loop;
      Write_File (Root & "/root_project.gpr", "project Root_Project is end Root_Project;");
      Write_File (Root & "/nested/nested_project.gpr", "project Nested_Project is end Nested_Project;");

      Context := Editor.Build_Working_Context.Current_Project_Root (Root);
      R := Editor.Build_Candidate_Discovery.Discover_Build_Candidates (Context);

      for Candidate of R.Candidates loop
         if To_String (Candidate.Display_Label) = "GPR: root_project.gpr" then
            Saw_Root_Gpr := True;
         elsif To_String (Candidate.Display_Label) = "GPR: nested/nested_project.gpr" then
            Saw_Nested_Gpr := True;
         end if;
      end loop;

      Assert (Saw_Root_Gpr,
              "keeps current-directory .gpr candidates before ordinary files exhaust the file budget");
      Assert (not Saw_Nested_Gpr,
              "does not descend into nested directories after the parent consumes the file-inspection budget");
      Assert (R.Files_Inspected <= 2048,
              "keeps the reported file-inspection count within the fixed bound");
      Assert (R.Limit_Reached,
              "reports the file limit when nested traversal is stopped");
   end Test_File_Limit_Blocks_Nested_Traversal;


   procedure Test_Entry_Scan_Window_Reports_Limit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Context : Editor.Build_Working_Context.Build_Working_Context_Record;
      R : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result;
   begin
      Reset_Fixture;
      Write_File (Root & "/root_project.gpr", "project Root_Project is end Root_Project;");
      for I in 1 .. 2200 loop
         Write_File
           (Root & "/ordinary_overflow_" & Ada.Strings.Fixed.Trim (Natural'Image (I), Ada.Strings.Both) & ".txt",
            "ordinary source file");
      end loop;

      Context := Editor.Build_Working_Context.Current_Project_Root (Root);
      R := Editor.Build_Candidate_Discovery.Discover_Build_Candidates (Context);

      Assert (Natural (R.Candidates.Length) >= 1,
              "still preserves candidate discovery before the entry scan window is exhausted");
      Assert (R.Limit_Reached,
              "reports limit reached when a directory has entries beyond the bounded scan window");
      Assert (Ada.Strings.Fixed.Index (To_String (R.Message), "limit reached") > 0,
              "user summary exposes bounded entry-scan truncation");
   end Test_Entry_Scan_Window_Reports_Limit;


   procedure Test_Directory_Queue_Is_Bounded_Deterministically
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Context : Editor.Build_Working_Context.Build_Working_Context_Record;
      R : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result;
      Saw_Root_Gpr : Boolean := False;
   begin
      Reset_Fixture;
      for I in 1 .. 180 loop
         Ada.Directories.Create_Path
           (Root & "/child_" & Ada.Strings.Fixed.Trim (Natural'Image (I), Ada.Strings.Both));
      end loop;
      Write_File (Root & "/root_project.gpr", "project Root_Project is end Root_Project;");

      Context := Editor.Build_Working_Context.Current_Project_Root (Root);
      R := Editor.Build_Candidate_Discovery.Discover_Build_Candidates (Context);

      for Candidate of R.Candidates loop
         if To_String (Candidate.Display_Label) = "GPR: root_project.gpr" then
            Saw_Root_Gpr := True;
         end if;
      end loop;

      Assert (Saw_Root_Gpr,
              "directory queue bounding does not starve current-directory GPR candidates");
      Assert (R.Directories_Visited <= 128,
              "retains the fixed directory visit bound even with many child directories");
      Assert (R.Skipped_Directory_Count > 0,
              "reports child directories skipped by the bounded queue");
      Assert (R.Limit_Reached,
              "reports directory queue overflow as a discovery limit");
   end Test_Directory_Queue_Is_Bounded_Deterministically;


   procedure Test_Project_Root_Shell_Characters_Are_Not_Rejected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := "/tmp/editor-tests/$safe;root";
      Context : Editor.Build_Working_Context.Build_Working_Context_Record;
      R : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result;
   begin
      Ada.Directories.Create_Path ("/tmp/editor-tests");
      if Ada.Directories.Exists (Root) then
         Ada.Directories.Delete_Tree (Root);
      end if;
      Ada.Directories.Create_Path (Root);
      Write_File (Root & "/alire.toml", "name = ""demo""");
      Write_File (Root & "/demo.gpr", "project Demo is end Demo;");

      Context := Editor.Build_Working_Context.Current_Project_Root (Root);
      R := Editor.Build_Candidate_Discovery.Discover_Build_Candidates (Context);

      Assert (R.Status = Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Complete,
              "does not reject filesystem-safe project roots merely because they contain shell metacharacters");
      Assert (Natural (R.Candidates.Length) = 2,
              "discovers Alire and GPR candidates under such project roots without shell interpretation");
      Assert (Editor.Build_Candidate_Discovery.Assert_Build_Candidate_Discovery_Does_Not_Use_Shell (R),
              "still keeps discovery shell-free for roots with shell-looking characters");
      Assert (Editor.Build_Candidate_Discovery.Assert_Build_Candidate_Discovery_Does_Not_Scan_Outside_Project_Root (R),
              "keeps containment checks active for roots with shell-looking characters");
   end Test_Project_Root_Shell_Characters_Are_Not_Rejected;


   procedure Test_Structured_Gpr_Path_Shell_Characters_Are_Not_Rejected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Context : Editor.Build_Working_Context.Build_Working_Context_Record;
      R : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result;
      Saw_Structured_Path : Boolean := False;
   begin
      Reset_Fixture;
      Ada.Directories.Create_Path (Root & "/safe;$dir");
      Write_File
        (Root & "/safe;$dir/demo;$app.gpr",
         "project Demo_App is end Demo_App;");

      Context := Editor.Build_Working_Context.Current_Project_Root (Root);
      R := Editor.Build_Candidate_Discovery.Discover_Build_Candidates (Context);

      for Candidate of R.Candidates loop
         if To_String (Candidate.Display_Label) = "GPR: safe;$dir/demo;$app.gpr" then
            Saw_Structured_Path := True;
            Assert
              (Editor.Build_Candidates.Validate_Candidate (Candidate) =
                 Editor.Build_Candidates.Build_Candidate_Valid,
               "accepts shell-looking characters inside structured argv path tokens");
         end if;
      end loop;

      Assert (Saw_Structured_Path,
              "discovers filesystem-safe GPR paths containing shell-looking characters");
      Assert (Editor.Build_Candidate_Discovery.Assert_Build_Candidate_Discovery_Does_Not_Use_Shell (R),
              "remains shell-free because the path is represented only as structured argv");
   end Test_Structured_Gpr_Path_Shell_Characters_Are_Not_Rejected;


   procedure Test_Unreadable_Or_Non_File_Source_Is_Unavailable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      C : Editor.Build_Candidates.Build_Candidate_Record;
   begin
      Reset_Fixture;
      Ada.Directories.Create_Path (Root & "/as_directory.gpr");

      C := Editor.Build_Candidates.Gprbuild_Candidate (Root, "as_directory.gpr");

      Assert
        (Editor.Build_Candidates.Validate_Candidate (C) =
           Editor.Build_Candidates.Build_Candidate_Unavailable,
         "rejects represented candidate sources that are not readable ordinary files");
      Assert
        (Editor.Build_Candidates.Build_Candidate_Disabled_Reason (C) =
           "candidate path missing or unavailable",
         "reports unreadable or non-file candidate sources as unavailable");
   end Test_Unreadable_Or_Non_File_Source_Is_Unavailable;


   procedure Test_Discovery_Audit_Allows_Safe_Unavailable_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      R : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result;
      C : Editor.Build_Candidates.Build_Candidate_Record;
   begin
      Reset_Fixture;
      C := Editor.Build_Candidates.Gprbuild_Candidate (Root, "missing.gpr");

      R.Status := Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Complete;
      R.Checked_Project_Root := To_Unbounded_String (Root);
      R.Gpr_Candidate_Count := 1;
      R.Message := To_Unbounded_String ("Found 1 build candidate: 0 Alire, 1 GPR.");
      Editor.Build_Candidates.Append_Unique_Candidate (R.Candidates, C);

      Assert
        (Editor.Build_Candidates.Validate_Candidate (C) =
           Editor.Build_Candidates.Build_Candidate_Unavailable,
         "fixture row is unavailable but still structured and safe");
      Assert
        (Editor.Build_Candidate_Discovery.Assert_Build_Candidate_Discovery_Bounded (R),
         "discovery audit allows safe unavailable rows with disabled reasons");
      Assert
        (Editor.Build_Candidate_Discovery.Assert_Build_Candidate_Discovery_Depth_Coherent (R),
         "depth audit does not require every displayed candidate row to be runnable");
   end Test_Discovery_Audit_Allows_Safe_Unavailable_Rows;


   procedure Test_Render_Uses_Snapshot_Labels_And_Reasons
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Context : Editor.Build_Working_Context.Build_Working_Context_Record;
      R : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result;
      S : Editor.Build_UI.Public_Build_UI_State;
      Snapshot : Editor.Build_UI.Build_UI_Render_Snapshot;
      Summary : Editor.Build_Result_Summary.Latest_Build_Result_Summary;
      Details : Editor.Build_Output_Details.Latest_Build_Output_Details;
   begin
      Reset_Fixture;
      Write_File (Root & "/demo.gpr", "project Demo is end Demo;");
      Context := Editor.Build_Working_Context.Current_Project_Root (Root);
      R := Editor.Build_Candidate_Discovery.Discover_Build_Candidates (Context);

      Editor.Build_UI.Show (S);
      Editor.Build_UI.Set_Build_Candidates (S, R.Candidates, To_String (R.Message));
      S.Candidate_Refresh_Status := Editor.Build_UI.Build_Candidate_Refresh_Succeeded;
      S.Candidate_Refresh_Message := R.Message;
      Snapshot := Editor.Build_UI.Build_Render_Snapshot (S, Summary, Details);

      Assert (Snapshot.Candidate_Count = 1,
              "render snapshot exposes candidate count only from state");
      Assert (To_String (Snapshot.Candidate_Count_Label)'Length > 0,
              "render snapshot exposes the candidate-count panel row");
      Assert (To_String (Snapshot.Candidate_Refresh_Action_Label)'Length > 0,
              "render snapshot exposes the candidate-refresh panel row");
      Assert (To_String (Snapshot.Request_Status_Label)'Length > 0,
              "render snapshot exposes the request-status panel row");
      Assert (To_String (Snapshot.Run_Command_Status_Label)'Length > 0,
              "render snapshot exposes the run-command panel row");
      Assert (To_String (Snapshot.Run_Recovery_Hint)'Length > 0,
              "render snapshot exposes the run-recovery panel row");
      Assert (Ada.Strings.Fixed.Index
                (To_String (Snapshot.Candidates.Element (0).Source_Label), "GPR") > 0,
              "render snapshot displays candidate source kind");
      Assert (Ada.Strings.Fixed.Index
                (To_String (Snapshot.Candidates.Element (0).Source_Label), "demo.gpr") > 0,
              "render snapshot displays project-relative candidate path");
      Assert (To_String (Snapshot.Refresh_Message) = To_String (R.Message),
              "render snapshot displays transient discovery summary");
      Assert (Editor.Build_UI.Assert_Build_UI_State_Is_Transient (S),
              "Build UI candidate state remains transient");
   end Test_Render_Uses_Snapshot_Labels_And_Reasons;


   overriding procedure Register_Tests
     (T : in out Build_Candidates_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Candidate_Model_Is_Structured_Transient'Access,
         "build candidate model is structured and transient");
      Register_Routine
        (T, Test_Discovery_Finds_Alire_And_Root_Gpr_Deterministically'Access,
         "discovery finds alire and root gpr candidates deterministically");
      Register_Routine
        (T, Test_Discovery_Rejects_Missing_Or_Unsafe_Context'Access,
         "discovery rejects missing or unsafe context");
      Register_Routine
        (T, Test_Candidate_Selection_Populates_UI_And_Invalidates_Consent'Access,
         "candidate selection populates UI and invalidates consent");
      Register_Routine
        (T, Test_Alire_Candidate_Selection_Request_Preview'Access,
         "Alire candidate selection populates preview and request");
      Register_Routine
        (T, Test_Gpr_Candidate_Selection_And_Manual_Mode'Access,
         "GPR candidate selection preserves manual mode");
      Register_Routine
        (T, Test_Candidate_Selection_Audit_Coherent'Access,
         "candidate selection audit coherent");
      Register_Routine
        (T, Test_Audit_Coherent'Access,
         "candidate discovery foundation coherent");
      Register_Routine
        (T, Test_Explicit_Refresh_Updates_Transient_Candidates'Access,
         "explicit refresh updates transient candidates");
      Register_Routine
        (T, Test_Refresh_No_Context_And_No_Candidates_Status'Access,
         "refresh has deterministic no-context/no-candidates statuses");
      Register_Routine
        (T, Test_Refresh_Preserves_Valid_Selected_Candidate_And_Consent'Access,
         "refresh preserves valid selected candidate and consent");
      Register_Routine
        (T, Test_Refresh_Clears_Stale_Selected_Candidate_And_Consent'Access,
         "refresh clears stale selected candidate and consent");
      Register_Routine
        (T, Test_Refresh_Clears_Materially_Changed_Selected_Candidate'Access,
         "refresh clears materially changed selected candidate");
      Register_Routine
        (T, Test_Refresh_Clears_Unselected_Request_Path'Access,
         "refresh clears unselected request path");
      Register_Routine
        (T, Test_Candidate_Refresh_Audit_Coherent'Access,
         "candidate refresh audit coherent");
      Register_Routine
        (T, Test_Repeated_Refresh_Is_Deterministic'Access,
         "repeated candidate refresh is deterministic");
      Register_Routine
        (T, Test_No_Candidate_Refresh_Does_Not_Reuse_Cache'Access,
         "no-candidate refresh does not reuse cache");
      Register_Routine
        (T, Test_Unselected_Request_Consent_Does_Not_Survive_Refresh'Access,
         "unselected request is not preserved across refresh");
      Register_Routine
        (T, Test_Identity_Collision_Clears_Selection'Access,
         "identity collision clears candidate selection");
      Register_Routine
        (T, Test_Display_Label_Change_Uses_Request_Identity_Policy'Access,
         "display label change follows request identity policy");
      Register_Routine
        (T, Test_Canonical_Refresh_Audit_Coherent'Access,
         "canonical candidate refresh audit coherent");
      Register_Routine
        (T, Test_Candidate_Material_Identity_Is_Canonical'Access,
         "candidate material identity is canonical");
      Register_Routine
        (T, Test_Failed_Refresh_Is_Status_Only'Access,
         "failed refresh is status only");
      Register_Routine
        (T, Test_Frontdoor_And_Build_Run_Boundaries'Access,
         "frontdoor and build.run boundaries are clean");
      Register_Routine
        (T, Test_Final_Freeze_Canonical_Path_Coherent'Access,
         "final freeze canonical path coherent");
      Register_Routine
        (T, Test_Final_Freeze_Identity_Stale_And_Consent'Access,
         "final freeze identity stale and consent boundaries");
      Register_Routine
        (T, Test_Final_Freeze_Manual_Request_Independent'Access,
         "final freeze clears unselected request");
      Register_Routine
        (T, Test_Final_Freeze_Failed_And_Persistence_Boundaries'Access,
         "final freeze failed and persistence boundaries");
      Register_Routine
        (T, Test_Project_Open_Refreshes_Through_Canonical_Path'Access,
         "project open refreshes candidates through canonical path");
      Register_Routine
        (T, Test_Project_Switch_Reconciles_Selection_And_Consent'Access,
         "project switch reconciles selection and consent");
      Register_Routine
        (T, Test_Project_Close_Clears_Executable_Candidates'Access,
         "project close clears executable candidates");
      Register_Routine
        (T, Test_Failed_Project_Transition_Does_Not_Fabricate'Access,
         "failed project transition does not fabricate candidates");
      Register_Routine
        (T, Test_Project_Reset_And_Manual_Request_Boundary'Access,
         "project reset clears unselected request boundary");
      Register_Routine
        (T, Test_Project_Close_Clears_Unselected_Request_Shape'Access,
         "project close clears unselected request shape");
      Register_Routine
        (T, Test_Project_Open_No_Candidates_Is_Lifecycle_State'Access,
         "project open no-candidates lifecycle state");
      Register_Routine
        (T, Test_Bounded_Nested_Gpr_Discovery_And_Ignores'Access,
         "bounded nested GPR discovery and ignored directories");
      Register_Routine
        (T, Test_Ranking_Labels_And_Summary'Access,
         "ranking labels and discovery summary");
      Register_Routine
        (T, Test_Limits_Count_Alire_And_Gpr_Together'Access,
         "candidate limits count Alire and GPR together");
      Register_Routine
        (T, Test_Gpr_Staging_Uses_Candidate_Bound_And_File_Accounting'Access,
         "GPR staging uses candidate bound and file accounting");
      Register_Routine
        (T, Test_Unsafe_Relative_Candidate_Is_Disabled'Access,
         "unsafe relative candidate is disabled");
      Register_Routine
        (T, Test_Discovery_Summary_Is_User_Readable'Access,
         "discovery summary is user readable");
      Register_Routine
        (T, Test_No_Candidate_Limit_Summary_Is_Not_Silent'Access,
         "no-candidate limit summary is not silent");
      Register_Routine
        (T, Test_Missing_Candidate_Source_Is_Unavailable'Access,
         "missing candidate source is unavailable");
      Register_Routine
        (T, Test_Unreadable_Or_Non_File_Source_Is_Unavailable'Access,
         "unreadable or non-file candidate source is unavailable");
      Register_Routine
        (T, Test_Discovery_Audit_Allows_Safe_Unavailable_Rows'Access,
         "discovery audit allows safe unavailable rows");
      Register_Routine
        (T, Test_Limit_Truncation_Retains_Primary_Ranked_Candidate'Access,
         "limit truncation retains primary ranked candidate");
      Register_Routine
        (T, Test_Directory_Queue_Is_Bounded_Deterministically'Access,
         "directory queue is bounded deterministically");
      Register_Routine
        (T, Test_Project_Root_Shell_Characters_Are_Not_Rejected'Access,
         "project root shell characters are not rejected");
      Register_Routine
        (T, Test_Structured_Gpr_Path_Shell_Characters_Are_Not_Rejected'Access,
         "structured gpr path shell characters are not rejected");
      Register_Routine
        (T, Test_Render_Uses_Snapshot_Labels_And_Reasons'Access,
         "render snapshot labels and reasons");
      Register_Routine
        (T, Test_Root_Gpr_Not_Starved_By_Directory_Limit'Access,
         "root gpr is not starved by directory scan limits");
      Register_Routine
        (T, Test_Gpr_Not_Starved_By_Non_Candidate_File_Limit'Access,
         "gpr files are not starved by non-candidate file limits");
      Register_Routine
        (T, Test_File_Limit_Blocks_Nested_Traversal'Access,
         "file limits block nested traversal after parent accounting");
      Register_Routine
        (T, Test_Entry_Scan_Window_Reports_Limit'Access,
         "entry scan window reports discovery limit");
   end Register_Tests;

end Editor.Build_Candidates.Tests;
