with Ada.Directories;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with AUnit.Assertions; use AUnit.Assertions;
with Editor.Commands.Workflow_Messages;
with Editor.Missing_Stale_Recovery;
with Editor.Test_Temp;

package body Editor.Missing_Stale_Recovery.Target_Validation_Tests is

   use type Editor.Missing_Stale_Recovery.Target_Availability_State;
   use type Editor.Missing_Stale_Recovery.Target_Surface;

   function Fixture_Root return String is
   begin
      Ada.Directories.Create_Path (Editor.Test_Temp.Path ("editor-tests"));
      return Editor.Test_Temp.Path ("editor-tests/missing_stale_fixture");
   end Fixture_Root;

   procedure Write_File (Path : String; Text : String := "demo") is
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
      Ada.Directories.Create_Path (Root & "/src");
      Write_File (Root & "/src/main.adb", "procedure Main is begin null; end Main;");
      Write_File (Root & "/demo.gpr", "project Demo is end Demo;");
   end Reset_Fixture;

   procedure Test_User_Readable_Labels_Are_Stable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Missing_Stale_Recovery.Label
                (Editor.Missing_Stale_Recovery.Target_Missing) = "target missing",
              "missing label is user-readable and not an enum name");
      Assert (Editor.Missing_Stale_Recovery.Availability_Reason
                (Editor.Missing_Stale_Recovery.Target_Outside_Project) =
                "Target is outside the current project.",
              "outside-project reason is distinct from missing");
      Assert (Editor.Missing_Stale_Recovery.Availability_Reason
                (Editor.Missing_Stale_Recovery.Target_Unreadable) =
                "File is not readable.",
              "unreadable reason is distinct");
      Assert (Editor.Missing_Stale_Recovery.Availability_Reason
                (Editor.Missing_Stale_Recovery.Target_Unwritable) =
                "File is not writable.",
              "unwritable reason is distinct");
      Assert (Editor.Missing_Stale_Recovery.Availability_Reason
                (Editor.Missing_Stale_Recovery.Target_Stale) =
                Editor.Commands.Workflow_Messages.Reason_Target_Stale,
              "stale target reason uses the canonical wording");
      Assert (Editor.Missing_Stale_Recovery.Outcome_Label
                ((State   => Editor.Missing_Stale_Recovery.Target_Stale,
                  Surface => Editor.Missing_Stale_Recovery.Project_Search_Surface,
                  Path    => Ada.Strings.Unbounded.To_Unbounded_String (""),
                  Line    => 0,
                  Column  => 0)) =
                "Project Search: Target is stale; refresh required.",
              "generic stale outcome cannot bypass canonical wording");
   end Test_User_Readable_Labels_Are_Stable;

   procedure Test_Workspace_And_Recent_Recovery_Messages
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Missing : constant String := Root & "/missing-project";
      Summary : constant Editor.Missing_Stale_Recovery.Workspace_Recovery_Summary :=
        (Project_Missing        => False,
         Missing_Open_Files     => 2,
         Active_File_Missing    => True,
         Ignored_Expanded_Paths => 1,
         Invalid_Caret_Targets  => 1,
         Fabricated_Project     => False,
         Fabricated_Buffer      => False);
   begin
      Reset_Fixture;
      Assert (Editor.Missing_Stale_Recovery.Validate_Workspace_Project_Target (Missing).State =
                Editor.Missing_Stale_Recovery.Target_Missing,
              "missing workspace project is unavailable");
      Assert (Editor.Missing_Stale_Recovery.Workspace_Recovery_Message (Summary) =
                "Some workspace files could not be reopened; active file could not be restored.",
              "workspace load emits one primary missing-reference summary");
      Assert (Editor.Missing_Stale_Recovery.Recent_Project_Recovery_Message (1, 0) =
                "Recent project path no longer exists.",
              "recent project open failure is explicit");
      Assert (Editor.Missing_Stale_Recovery.Recent_Project_Recovery_Message (1, 1) =
                "Removed unavailable recent project.",
              "recent project removal message is explicit");
      Assert (Editor.Missing_Stale_Recovery.Recent_Project_Recovery_Message (0, 0) =
                "No unavailable recent projects.",
              "no-op recent missing removal is explicit");
      Assert (Editor.Missing_Stale_Recovery.Validate_Recent_Project_Target (Missing).Surface =
                Editor.Missing_Stale_Recovery.Recent_Project_Surface,
              "recent project missing marker is surface-specific");
   end Test_Workspace_And_Recent_Recovery_Messages;

   procedure Test_File_Lifecycle_Missing_Backing_File_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Source : constant String := Root & "/src/main.adb";
      Missing : constant String := Root & "/src/deleted.adb";
      Missing_Parent : constant String := Root & "/gone/new.adb";
   begin
      Reset_Fixture;
      Ada.Directories.Delete_File (Source);
      Assert (Editor.Missing_Stale_Recovery.Validate_Buffer_Backing_File_Target
                (Source, Dirty => True).State = Editor.Missing_Stale_Recovery.Target_Missing,
              "deleted dirty backing file is missing without clearing buffer text");
      Assert (Editor.Missing_Stale_Recovery.Dirty_Buffer_Text_Preserved_On
                (Editor.Missing_Stale_Recovery.Target_Missing),
              "dirty buffer text is preserved on missing backing file");
      Assert (Editor.Missing_Stale_Recovery.Validate_Save_Target (Missing).State =
                Editor.Missing_Stale_Recovery.Target_Available,
              "save to existing parent remains an explicit create/write operation");
      Assert (Editor.Missing_Stale_Recovery.Validate_Save_Target (Missing_Parent).State =
                Editor.Missing_Stale_Recovery.Target_Parent_Directory_Missing,
              "save target with missing parent reports the parent-directory recovery label");
      Assert (Editor.Missing_Stale_Recovery.Validate_Reveal_Target (Missing, Root).Surface =
                Editor.Missing_Stale_Recovery.File_Tree_Surface,
              "reveal validates through the File Tree surface");
   end Test_File_Lifecycle_Missing_Backing_File_Recovery;

   procedure Test_File_Project_And_Project_Boundary_Validation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Existing : constant String := Root & "/src/main.adb";
      Missing  : constant String := Root & "/src/missing.adb";
      Outside  : constant String := Editor.Test_Temp.Path ("editor-tests/outside.adb");
   begin
      Reset_Fixture;
      Write_File (Outside, "outside");
      Assert (Editor.Missing_Stale_Recovery.Validate_Project_Target (Root).State =
                Editor.Missing_Stale_Recovery.Target_Available,
              "existing project root is available");
      Assert (Editor.Missing_Stale_Recovery.Validate_Project_Target (Root & "/gone").State =
                Editor.Missing_Stale_Recovery.Target_Missing,
              "missing workspace project is reported as missing");
      Assert (Editor.Missing_Stale_Recovery.Validate_Project_File_Target
                (Root, Existing).State = Editor.Missing_Stale_Recovery.Target_Available,
              "existing in-project file is available");
      Assert (Editor.Missing_Stale_Recovery.Validate_Project_File_Target
                (Root, Missing).State = Editor.Missing_Stale_Recovery.Target_Missing,
              "missing in-project file is missing, not fabricated");
      Assert (Editor.Missing_Stale_Recovery.Validate_Project_File_Target
                (Root, Outside).State = Editor.Missing_Stale_Recovery.Target_Outside_Project,
              "outside-project file is rejected before open/navigation");
      Ada.Directories.Delete_File (Outside);
   end Test_File_Project_And_Project_Boundary_Validation;

   procedure Test_Surface_Specific_Stale_Target_Validation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Existing : constant String := Root & "/src/main.adb";
      Missing  : constant String := Root & "/src/gone.adb";
   begin
      Reset_Fixture;
      Assert (Editor.Missing_Stale_Recovery.Validate_File_Tree_Node_Target
                (Missing, Root).State = Editor.Missing_Stale_Recovery.Target_Missing,
              "stale File Tree node validates to missing");
      Assert (Editor.Missing_Stale_Recovery.Validate_Quick_Open_Result_Target
                (Missing, Root).State = Editor.Missing_Stale_Recovery.Target_Stale,
              "stale Quick Open match validates to stale");
      Assert (Editor.Missing_Stale_Recovery.Validate_Search_Result_Target
                (Existing, 3, 1).State = Editor.Missing_Stale_Recovery.Target_Line_Out_Of_Range,
              "Project Search line out of range is rejected");
      Assert (Editor.Missing_Stale_Recovery.Validate_Search_Result_Target
                (Existing, 1, 1, Stale => True).State = Editor.Missing_Stale_Recovery.Target_Stale,
              "stale Project Search row requires rerun before activation");
      Assert (Editor.Missing_Stale_Recovery.Validate_Replace_Preview_Target
                (Existing, 1, 1, Stale => True).State = Editor.Missing_Stale_Recovery.Target_Preview_Stale,
              "stale replace preview is rejected before apply");
   end Test_Surface_Specific_Stale_Target_Validation;

   procedure Test_Outline_Diagnostics_And_Build_Validation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Source : constant String := Root & "/src/main.adb";
      Candidate : constant String := Root & "/demo.gpr";
   begin
      Reset_Fixture;
      Assert (Editor.Missing_Stale_Recovery.Validate_Outline_Target
                (Active_Buffer_Matches => False,
                 Stale => False,
                 Line => 1,
                 Column => 1,
                 Last_Line => 1,
                 Last_Line_Column => 20).State =
                Editor.Missing_Stale_Recovery.Target_Stale,
              "Outline for another buffer is rejected");
      Assert (Editor.Missing_Stale_Recovery.Validate_Outline_Target
                (Active_Buffer_Matches => True,
                 Stale => True,
                 Line => 1,
                 Column => 1,
                 Last_Line => 1,
                 Last_Line_Column => 20).State =
                Editor.Missing_Stale_Recovery.Target_Refresh_Required,
              "stale Outline requires explicit refresh");
      Assert (Editor.Missing_Stale_Recovery.Validate_Diagnostic_Target
                (Source, False, 1, 1, 1, 20).State =
                Editor.Missing_Stale_Recovery.Target_Source_Less,
              "source-less diagnostic is non-navigable");
      Assert (Editor.Missing_Stale_Recovery.Validate_Diagnostic_Target
                (Source, True, 2, 1, 1, 20).State =
                Editor.Missing_Stale_Recovery.Target_Line_Out_Of_Range,
              "diagnostic line out of range is rejected");
      Assert (Editor.Missing_Stale_Recovery.Validate_Build_Candidate_Target
                (Candidate, Root, Stale => True).State =
                Editor.Missing_Stale_Recovery.Target_Candidate_Stale,
              "stale build candidate blocks build.run preflight");
      Ada.Directories.Delete_File (Candidate);
      Assert (Editor.Missing_Stale_Recovery.Validate_Build_Candidate_Target
                (Candidate, Root).State = Editor.Missing_Stale_Recovery.Target_Missing,
              "deleted build candidate blocks build.run preflight");
   end Test_Outline_Diagnostics_And_Build_Validation;

end Editor.Missing_Stale_Recovery.Target_Validation_Tests;
