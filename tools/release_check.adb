with Ada.Command_Line;
with Ada.Directories;
with Editor_Tool_Common; use Editor_Tool_Common;

procedure Release_Check is
   use type Ada.Directories.File_Kind;

   Tool : constant String := "release_check";

   Tools_Build_Attempted : Boolean := False;
   Tools_Build_Ok        : Boolean := False;
   Release_Check_Failed  : Boolean := False;

   procedure Fail (Tool : String; Message : String) is
   begin
      Release_Check_Failed := True;
      Editor_Tool_Common.Fail (Tool, Message);
   end Fail;

   function Tool_Path (Name : String) return String is
   begin
      return "tools/bin/" & Name;
   end Tool_Path;

   procedure Check_No_Glob (Dir : String) is
      Search         : Ada.Directories.Search_Type;
      Search_Started : Boolean := False;
      Ent            : Ada.Directories.Directory_Entry_Type;
   begin
      if not Ada.Directories.Exists (Dir) then
         return;
      end if;

      Ada.Directories.Start_Search
        (Search,
         Dir,
         "*",
         (Ada.Directories.Ordinary_File => True,
          Ada.Directories.Directory      => True,
          others                         => False));
      Search_Started := True;

      while Ada.Directories.More_Entries (Search) loop
         Ada.Directories.Get_Next_Entry (Search, Ent);
         declare
            Full : constant String := Ada.Directories.Full_Name (Ent);
            Base : constant String := Ada.Directories.Simple_Name (Ent);
         begin
            if Base = "." or else Base = ".." then
               null;
            elsif Ada.Directories.Kind (Ent) = Ada.Directories.Directory then
               if Base = "__" & "pycache__" then
                  Fail (Tool, "Python cache directory must not be shipped: " & Full);
               elsif Base = "phase-notes" then
                  Fail (Tool, "release archive must not ship docs/history/phase-notes");
               else
                  Check_No_Glob (Full);
               end if;
            else
               if Base'Length >= 3 and then Base (Base'Last - 2 .. Base'Last) = "." & "py" then
                  Fail (Tool, "Python tooling must not be shipped: " & Full);
               elsif Base'Length >= 4 and then Base (Base'Last - 3 .. Base'Last) = "." & "pyc" then
                  Fail (Tool, "Python bytecode must not be shipped: " & Full);
               elsif Base'Length >= 3 and then Base (Base'Last - 2 .. Base'Last) = "." & "sh" then
                  Fail (Tool, "shell scripts must not be shipped after Ada tool replacement: " & Full);
               end if;
            end if;
         end;
      end loop;

      Ada.Directories.End_Search (Search);
   exception
      when Program_Error =>
         if Search_Started then
            Ada.Directories.End_Search (Search);
         end if;
         raise;
      when others =>
         if Search_Started then
            Ada.Directories.End_Search (Search);
         end if;
         Fail (Tool, "unable to complete forbidden tooling scan under " & Dir);
   end Check_No_Glob;

   procedure Check_No_Generated_Ada_Build_Artifacts
     (Dir : String; Root_Only : Boolean)
   is
      Search         : Ada.Directories.Search_Type;
      Search_Started : Boolean := False;
      Ent            : Ada.Directories.Directory_Entry_Type;
   begin
      if not Ada.Directories.Exists (Dir) then
         return;
      end if;

      Ada.Directories.Start_Search
        (Search,
         Dir,
         "*",
         (Ada.Directories.Ordinary_File => True,
          Ada.Directories.Directory      => True,
          others                         => False));
      Search_Started := True;

      while Ada.Directories.More_Entries (Search) loop
         Ada.Directories.Get_Next_Entry (Search, Ent);
         declare
            Full : constant String := Ada.Directories.Full_Name (Ent);
            Base : constant String := Ada.Directories.Simple_Name (Ent);
         begin
            if Base = "." or else Base = ".." then
               null;
            elsif Ada.Directories.Kind (Ent) = Ada.Directories.Directory then
               if not Root_Only
                 and then Base /= ".git"
                 and then Base /= "obj"
                 and then Base /= "bin"
                 and then Base /= "tools"
                 and then Base /= "tests"
               then
                  Check_No_Generated_Ada_Build_Artifacts (Full, False);
               end if;
            elsif (Base'Length >= 4 and then Base (Base'Last - 3 .. Base'Last) = ".ali")
              or else (Base'Length >= 2 and then Base (Base'Last - 1 .. Base'Last) = ".o")
              or else (Base'Length >= 2 and then Base (Base'Last - 1 .. Base'Last) = ".a")
            then
               Fail (Tool, "generated Ada build artifact must not be tracked at source root/lib: " & Full);
            end if;
         end;
      end loop;

      Ada.Directories.End_Search (Search);
   exception
      when Program_Error =>
         if Search_Started then
            Ada.Directories.End_Search (Search);
         end if;
         raise;
      when others =>
         if Search_Started then
            Ada.Directories.End_Search (Search);
         end if;
         Fail (Tool, "unable to complete generated artifact scan under " & Dir);
   end Check_No_Generated_Ada_Build_Artifacts;

   procedure Try_Build_Tools is
      Status : Integer;
   begin
      if Tools_Build_Attempted then
         return;
      end if;

      Tools_Build_Attempted := True;
      if not Command_Exists ("gprbuild") then
         Info (Tool, "gprbuild not found; Ada tool execution gates that require built tool binaries are skipped");
         return;
      end if;

      Info (Tool, "building Ada release tool suite");
      Status := Run3 ("gprbuild", "-q", "-P", "tools/editor_tools.gpr");
      if Status = 0 then
         Tools_Build_Ok := True;
      else
         Fail (Tool, "failed to build Ada release tool suite");
      end if;
   end Try_Build_Tools;

   procedure Require_Program_Error_Guard (Path : String) is
   begin
      if File_Contains (Path, "when Program_Error => null")
        or else not File_Contains (Path, "Tool_Failed : Boolean")
        or else not File_Contains (Path, "Unexpected_Program_Error (Tool)")
      then
         Fail (Tool, Path & " must distinguish intentional Fail exits from unexpected Program_Error");
      end if;
   end Require_Program_Error_Guard;


   procedure Require_Not_Contains (Path : String; Needle : String; Message : String) is
   begin
      if File_Contains (Path, Needle) then
         Fail (Tool, Message);
      end if;
   end Require_Not_Contains;

   procedure Run_Tool_Gate (Name : String; Description : String) is
      Path   : constant String := Tool_Path (Name);
      Status : Integer;
   begin
      if not Ada.Directories.Exists (Path) then
         Try_Build_Tools;
      end if;

      if not Ada.Directories.Exists (Path) then
         Info (Tool, Description & " skipped; " & Path & " is not built");
         return;
      end if;

      Info (Tool, "running " & Description);
      Status := Run0 (Path);
      if Status /= 0 then
         Fail (Tool, Description & " failed");
      end if;
   end Run_Tool_Gate;

   procedure Run_Tool_Gate
     (Name : String; Description : String; Argument : String)
   is
      Path   : constant String := Tool_Path (Name);
      Status : Integer;
   begin
      if not Ada.Directories.Exists (Path) then
         Try_Build_Tools;
      end if;

      if not Ada.Directories.Exists (Path) then
         Info (Tool, Description & " skipped; " & Path & " is not built");
         return;
      end if;

      Info (Tool, "running " & Description);
      Status := Run1 (Path, Argument);
      if Status /= 0 then
         Fail (Tool, Description & " failed");
      end if;
   end Run_Tool_Gate;

begin
   Require_File (Tool, "alire.toml");
   Require_File (Tool, "editor.gpr");
   Require_File (Tool, "editor_core.gpr");
   Require_File (Tool, "README.md");
   Require_File (Tool, "docs/release/RELEASE_CHECKLIST.md");
   if not File_Contains ("docs/release/RELEASE_CHECKLIST.md", "EDITOR_REQUIRE_LANGUAGE_VALIDATION=1")
     or else not File_Contains ("docs/release/RELEASE_CHECKLIST.md", "tools/bin/language_validation_check")
   then
      Fail (Tool, "release checklist must document the strict GNAT/AUnit validation gate");
   end if;
   Require_File (Tool, "docs/release/RUNTIME_SMOKE.md");
   Require_File (Tool, "docs/release/BUILD_PROCESS_PLATFORM_SUPPORT.md");
   Require_File (Tool, "docs/release/CI_RUNTIME_VALIDATION.md");
   Require_File (Tool, "docs/release/STRICT_RUNTIME_VALIDATION_RECORD.md");
   Require_File (Tool, "docs/release/SHADER_TOOLCHAIN.md");
   Require_File (Tool, "docs/release/SHADER_TOOLCHAIN_VERSION.txt");
   Require_File (Tool, "docs/release/RELEASE_STATE.txt");
   Require_File (Tool, "docs/release/RELEASE_CANDIDATE_POLICY.md");
   Require_File (Tool, "tests/tests.gpr");
   Require_File (Tool, "tests/e2e_product_smoke.gpr");
   Require_File (Tool, "tests/e2e_real_build_runner_smoke.gpr");
   Require_Dir  (Tool, "src/core");
   Require_File (Tool, "src/core/editor-ada_language_model.ads");
   Require_File (Tool, "src/core/editor-ada_language_model.adb");
   Require_File (Tool, "src/core/editor-ada_declaration_parser.ads");
   Require_File (Tool, "src/core/editor-ada_declaration_parser.adb");
   Require_File (Tool, "src/core/editor-ada_token_cursor.ads");
   Require_File (Tool, "src/core/editor-ada_token_cursor.adb");
   Require_File (Tool, "src/core/editor-ada_symbol_resolver.ads");
   Require_File (Tool, "src/core/editor-ada_symbol_resolver.adb");
   Require_File (Tool, "src/core/editor-ada_project_index.ads");
   Require_File (Tool, "src/core/editor-ada_project_index.adb");
   Require_Dir  (Tool, "src/runtime");
   Require_Dir  (Tool, "src/runtime/shaders");

   Require_File (Tool, "tools/editor_tools.gpr");
   Require_File (Tool, "tools/release_check.adb");
   Require_File (Tool, "tools/release_check_record.adb");
   Require_File (Tool, "tools/final_release_validation_check.adb");
   Require_File (Tool, "tools/release_candidate_check.adb");
   Require_File (Tool, "tools/runtime_compile_check.adb");
   Require_File (Tool, "tools/runtime_link_check.adb");
   Require_File (Tool, "tools/runtime_smoke.adb");
   Require_File (Tool, "tools/runtime_missing_asset_check.adb");
   Require_File (Tool, "tools/shader_toolchain_manifest_check.adb");
   Require_File (Tool, "tools/shader_freshness_check.adb");
   Require_File (Tool, "tools/strict_runtime_preflight.adb");
   Require_File (Tool, "tools/strict_runtime_validation.adb");
   Require_File (Tool, "tools/strict_runtime_validation_record.adb");
   Require_File (Tool, "tools/compile_shaders.adb");
   Require_File (Tool, "tools/record_shader_toolchain_manifest.adb");
   Require_File (Tool, "tools/product_smoke.adb");
   Require_File (Tool, "tools/real_build_runner_smoke.adb");
   Require_File (Tool, "tools/unit_tests.adb");
   Require_File (Tool, "tools/language_validation_check.adb");
   Require_File (Tool, "tools/outline_static_sanity.adb");
   Require_File (Tool, "tools/outline_static_sanity.gpr");
   Require_File (Tool, "tools/ada_keyword_identifier_check.adb");

   Require_File (Tool, "src/runtime/shaders/rect.vert");
   Require_File (Tool, "src/runtime/shaders/rect.frag");
   Require_File (Tool, "src/runtime/shaders/text.vert");
   Require_File (Tool, "src/runtime/shaders/text.frag");
   Require_File (Tool, "src/runtime/shaders/rect.vert.spv");
   Require_File (Tool, "src/runtime/shaders/rect.frag.spv");
   Require_File (Tool, "src/runtime/shaders/text.vert.spv");
   Require_File (Tool, "src/runtime/shaders/text.frag.spv");

   Check_No_Glob (".");
   Check_No_Generated_Ada_Build_Artifacts (".", True);
   Check_No_Generated_Ada_Build_Artifacts ("lib", False);

   if Ada.Directories.Exists ("editor_app.gpr") then
      Fail (Tool, "old editor_app.gpr must not reappear");
   end if;

   if not File_Contains ("editor.gpr", "for Main use (""main.c"")") then
      Fail (Tool, "editor.gpr must build the runtime main.c entry point");
   end if;

   if not File_Contains ("tests/tests.gpr", "../editor_core.gpr") then
      Fail (Tool, "unit tests must depend on editor_core.gpr rather than runtime app project");
   end if;

   if File_Contains ("src/core/editor-render_packet.adb", "Editor.Syntax.Classify_Range") then
      Fail (Tool, "render packet must consume cached syntax spans, not call Classify_Range directly");
   end if;

   --  language-intelligence architecture is intentionally checked
   --  by tools/language_validation_check.adb.  Keep release_check
   --  as the orchestrator instead of duplicating hundreds of brittle
   --  source-string guards here.
   if not File_Contains ("tools/editor_tools.gpr", "language_validation_check.adb")
     or else not File_Contains ("tools/release_check.adb", "Run_Tool_Gate (""language_validation_check""")
   then
      Fail
        (Tool,
         "release_check must delegate language validation to the dedicated Ada gate");
   end if;

   if not File_Contains ("tools/editor_tools.gpr", "release_check.adb")
     or else not File_Contains ("tools/editor_tools.gpr", "release_commands.adb")
     or else not File_Contains ("tools/editor_tools.gpr", "release_check_record.adb")
     or else not File_Contains ("tools/editor_tools.gpr", "final_release_validation_check.adb")
     or else not File_Contains ("tools/editor_tools.gpr", "release_candidate_check.adb")
   then
      Fail
        (Tool,
         "Ada tool project must include release_check, release_check_record, "
         & "release_commands, final_release_validation_check, and release_candidate_check");
   end if;

   if not File_Contains ("tools/editor_tools.gpr", "runtime_compile_check.adb")
     or else not File_Contains ("tools/editor_tools.gpr", "runtime_link_check.adb")
     or else not File_Contains ("tools/editor_tools.gpr", "runtime_smoke.adb")
     or else not File_Contains ("tools/editor_tools.gpr", "runtime_missing_asset_check.adb")
     or else not File_Contains ("tools/editor_tools.gpr", "shader_toolchain_manifest_check.adb")
     or else not File_Contains ("tools/editor_tools.gpr", "shader_freshness_check.adb")
     or else not File_Contains ("tools/editor_tools.gpr", "strict_runtime_preflight.adb")
     or else not File_Contains ("tools/editor_tools.gpr", "product_smoke.adb")
     or else not File_Contains ("tools/editor_tools.gpr", "product_smoke_focus_selftest.adb")
     or else not File_Contains ("tools/editor_tools.gpr", "real_build_runner_smoke.adb")
     or else not File_Contains ("tools/editor_tools.gpr", "unit_tests.adb")
     or else not File_Contains ("tools/editor_tools.gpr", "release_commands.adb")
     or else not File_Contains ("tools/editor_tools.gpr", "test_slice_for.adb")
     or else not File_Contains ("tools/editor_tools.gpr", "test_commands_for.adb")
     or else not File_Contains ("tools/editor_tools.gpr", "check_docs.adb")
     or else not File_Contains ("tools/editor_tools.gpr", "outline_static_sanity.adb")
     or else not File_Contains ("tools/editor_tools.gpr", "record_shader_toolchain_manifest.adb")
     or else not File_Contains ("tools/editor_tools.gpr", "ada_keyword_identifier_check.adb")
     or else not File_Contains ("tools/editor_tools.gpr", "language_validation_check.adb")
   then
      Fail (Tool, "Ada tool project must include all release and test-selection gate tools");
   end if;

   if not File_Contains ("README.md", "docs/testing.md")
     or else not File_Contains ("README.md", "docs/archive/")
     or else not File_Contains ("docs/archive/README.md", "source of truth")
     or else not File_Contains ("docs/testing.md", "Run slice builds serially")
     or else not File_Contains ("docs/testing.md", "Release-Gate Slice Rule")
     or else not File_Contains ("docs/testing.md", "tools/bin/release_commands")
     or else not File_Contains ("docs/testing.md", "tools/bin/test_commands_for")
     or else not File_Contains ("docs/testing.md", "tools/bin/unit_tests all")
     or else not File_Contains ("docs/editor_workflow_contracts.md", "Focused Smoke")
   then
      Fail (Tool, "testing and archive policy must point current workflow away from archived pass logs");
   end if;

   if not File_Contains ("tools/release_commands.adb", "tools/bin/outline_static_sanity")
     or else not File_Contains ("tools/release_commands.adb", "tools/bin/ada_keyword_identifier_check")
     or else not File_Contains ("tools/release_commands.adb", "tools/bin/runtime_compile_check")
     or else not File_Contains ("tools/release_commands.adb", "tools/bin/runtime_link_check")
     or else not File_Contains ("tools/release_commands.adb", "tools/bin/runtime_smoke")
     or else not File_Contains ("tools/release_commands.adb", "tools/bin/runtime_missing_asset_check")
     or else not File_Contains ("tools/release_commands.adb", "tools/bin/shader_toolchain_manifest_check")
     or else not File_Contains ("tools/release_commands.adb", "tools/bin/release_candidate_check")
     or else not File_Contains ("tools/release_commands.adb", "tools/bin/strict_runtime_preflight")
     or else not File_Contains ("tools/release_commands.adb", "tools/bin/shader_freshness_check")
     or else not File_Contains ("tools/release_commands.adb", "tools/bin/unit_tests all")
     or else not File_Contains ("tools/release_commands.adb", "tools/bin/language_validation_check")
     or else not File_Contains ("tools/release_commands.adb", "tools/bin/product_smoke")
     or else not File_Contains ("tools/release_commands.adb", "tools/bin/real_build_runner_smoke")
     or else not File_Contains ("tools/release_commands.adb", "tools/bin/release_check")
     or else not File_Contains ("tools/release_commands.adb", "tools/bin/final_release_validation_check")
   then
      Fail (Tool, "release_commands must print the full release-check gate surface");
   end if;

   if not File_Contains ("README.md", "Ada release tools") then
      Fail (Tool, "README must document Ada release tools replacing shell/Python scripts");
   end if;
   if Ada.Directories.Exists ("tools/define_" & "ali" & "ases.adb") then
      Fail (Tool, "removed developer-tool previous file name must not reappear");
   end if;

   if not File_Contains ("tools/editor_tools.gpr", "show_developer_tools.adb") then
      Fail (Tool, "Ada tool project must include the current developer-tool listing command");
   end if;


   if File_Contains ("docs/release/RELEASE_CHECKLIST.md", "normal POSIX shell tool") then
      Fail (Tool, "release checklist must describe compile_shaders as an Ada tool, not a shell script");
   end if;


   Require_Not_Contains
     ("src/core/editor-font_config.ads", "Removed font alternate names",
      "font configuration must expose only current font/grid names");
   Require_Not_Contains
     ("src/core/editor-font_config.ads", "Pixel_Size  : constant",
      "font configuration must not retain Pixel_Size removed name");
   Require_Not_Contains
     ("src/core/editor-minimap.ads", "Current_Config return Minimap_Config",
      "minimap API must not retain Current_Config removed name");
   Require_Not_Contains
     ("src/core/editor-minimap.ads", "Set_Config (Config : Minimap_Config)",
      "minimap API must not retain Set_Config removed name");
   Require_Not_Contains
     ("src/core/editor-theme.ads", "subtype RGB_Color",
      "theme API must not retain RGB_Color removed spelling");
   Require_Not_Contains
     ("src/core/editor-instance.ads", "procedure Rebuild",
      "editor instance API must not retain removed Rebuild no-op");
   Require_Not_Contains
     ("src/core/editor-command_palette.ads", "Primary_Text for new rows",
      "command palette rows must not retain Text removed field");
   Require_Not_Contains
     ("src/core/editor-outline.ads", "Populate_Feature_Panel",
      "outline API must not retain Populate_Feature_Panel projection removed-name");
   Require_Not_Contains
     ("src/core/editor-file_tree_view.ads", "Removed field",
      "file tree view config must not retain removed width field");

   Require_Not_Contains
     ("src/core/editor-build_result_summary.ads", "Replace_Latest_Summary",
      "build result summary API must not retain removed Replace_Latest_Summary name");
   Require_Not_Contains
     ("src/core/editor-command_palette.ads", "Main_Text",
      "command palette row layout must not retain removed Main_Text projection name");
   Require_Not_Contains
     ("docs/open_buffer_switcher_commands.md", "## Com" & "patibility Rules",
      "Open Buffer Switcher reference must use current stable-name wording, not removed-name wording");
   Require_Not_Contains
     ("docs/open_buffer_switcher_commands.md", "## Aliases and Retired Names",
      "Open Buffer Switcher reference must not retain removed-name section");

   Require_Not_Contains
     ("src/core/editor-external_producers.ads", "Public_Build_Command_Alternate_Names_Are_Empty",
      "public build guardrail must not retain alternate-name absence API");
   Require_Not_Contains
     ("src/core/editor-external_producers.ads", "Exact_Alternate_Name_Found",
      "public build scan result must not retain alternate-name fields");
   Require_Not_Contains
     ("src/core/editor-external_producers.ads", "Alternate_Name",
      "public build scan API must not retain alternate-name parameter");
   Require_Not_Contains
     ("src/core/editor-settings_management.ads", "Stable_Name_Alias_Count",
      "settings command audit must not retain stable-name alias counter");
   Require_Not_Contains
     ("src/core/editor-core_editing_workflow.adb", "Alias_Resolves",
      "core editing workflow audit must not retain command-alias helper");
   Require_Not_Contains
     ("src/core/editor-projection_surface_file_lifecycle_audit.ads", "Has_Prompted_Local_Alias",
      "projection surface lifecycle audit must not retain prompted local alias field");


   declare
      Removed_Audit_Stem : constant String := "tests/src/editor-removed" & "_command_audit";
      Old_Name_Marker    : constant String := "leg" & "acy.";
   begin
      if Ada.Directories.Exists (Removed_Audit_Stem & "-tests.adb")
        or else Ada.Directories.Exists (Removed_Audit_Stem & "-tests.ads")
        or else Ada.Directories.Exists (Removed_Audit_Stem & ".ads")
      then
         Fail (Tool, "obsolete command-name audit files must not be shipped");
      end if;

      Require_Not_Contains ("tests/src/all_suites.adb", "Removed" & "_Command_Audit",
        "obsolete command-name audit suite must not be registered");
      Require_Not_Contains ("tests/src/editor-buffers-tests.adb", Old_Name_Marker,
        "obsolete command-name literals must not remain in buffer tests");
      Require_Not_Contains ("tests/src/editor-files-tests.adb", Old_Name_Marker,
        "obsolete command-name literals must not remain in file tests");
      Require_Not_Contains ("tests/src/editor-line_edit-tests.adb", Old_Name_Marker,
        "obsolete command-name literals must not remain in line-edit tests");
   end;

   Require_Not_Contains
     ("src/core/editor-commands.adb", "command_palette.show_command_help",
      "product command resolver must not retain command-palette spelling-only name");
   Require_Not_Contains
     ("src/core/editor-commands.adb", "project.reopen_recent",
      "product command resolver must not retain project reopen spelling-only name");
   Require_Not_Contains
     ("src/core/editor-commands.adb", "file.save_as",
      "product command resolver must not retain save-as spelling-only name");
   Require_Not_Contains
     ("src/core/editor-commands.adb", "file_tree.",
      "product command resolver must not retain file_tree spelling-only names");
   Require_Not_Contains
     ("src/core/editor-commands.adb", "quick_open.",
      "product command resolver must not retain quick_open spelling-only names");
   Require_Not_Contains
     ("src/core/editor-commands.adb", "search.open_selected",
      "product command resolver must not retain search open-selected spelling-only name");
   Require_Not_Contains
     ("src/core/editor-commands.adb", "outline.goto-selected",
      "outline command resolver must not retain removed goto-selected name");
   Require_Not_Contains
     ("src/core/editor-commands.adb", "outline.open_selected",
      "outline command resolver must not retain spelling-only selected names");
   Require_Not_Contains
     ("src/core/editor-commands.adb", "buffer.switch_next",
      "buffer command resolver must not retain switch-next spelling-only name");
   Require_Not_Contains
     ("src/core/editor-commands.adb", "buffer.switch_previous",
      "buffer command resolver must not retain switch-previous spelling-only name");
   Require_Not_Contains
     ("src/core/editor-commands.adb", "buffer.close_all_clean",
      "buffer command resolver must not retain close-all-clean spelling-only name");
   Require_Not_Contains
     ("src/core/editor-commands.adb", "edit.selection.delete",
      "selection command resolver must not retain removed delete spelling");

   if File_Contains ("tools/compile_shaders.adb", "RECORDED_BY_ADA_TOOL")
     or else File_Contains ("tools/compile_shaders.adb", "run glslangValidator --version for full details")
   then
      Fail (Tool, "compile_shaders must record the actual glslangValidator --version first line, not a placeholder");
   end if;

   if not File_Contains ("tools/compile_shaders.adb", "Capture_First_Line")
     or else not File_Contains ("tools/compile_shaders.adb", "GLSLANG_VALIDATOR_VERSION_FIRST_LINE=")
   then
      Fail (Tool, "compile_shaders must capture and write the actual shader toolchain version line");
   end if;

   if not File_Contains
       ("tools/record_shader_toolchain_manifest.adb",
        "GLSLANG_VALIDATOR_VERSION_FIRST_LINE=")
     or else not File_Contains
       ("tools/record_shader_toolchain_manifest.adb",
        "refusing to record invalid shader toolchain version line")
     or else not File_Contains
       ("tools/record_shader_toolchain_manifest.adb", "--version-file")
   then
      Fail
        (Tool,
         "record_shader_toolchain_manifest must record a real release glslangValidator first line "
         & "and refuse placeholders");
   end if;

   if not File_Contains ("tools/shader_freshness_check.adb", "Recorded_Glslang_First_Line")
     or else not File_Contains ("tools/shader_freshness_check.adb", "glslangValidator toolchain mismatch")
     or else not File_Contains ("tools/shader_freshness_check.adb", "Current_Version")
   then
      Fail (Tool, "shader freshness check must compare the current glslangValidator first line to the manifest");
   end if;

   if not File_Contains ("tools/shader_toolchain_manifest_check.adb", "SHADER_TOOLCHAIN_MANIFEST_STATE")
     or else not File_Contains ("tools/shader_toolchain_manifest_check.adb", "EDITOR_REQUIRE_SHADER_TOOLCHAIN_MANIFEST")
     or else not File_Contains ("tools/shader_toolchain_manifest_check.adb", "UNRECORDED")
     or else not File_Contains ("tools/shader_toolchain_manifest_check.adb", "strict release validation will fail")
   then
      Fail (Tool, "shader_toolchain_manifest_check must enforce recorded/unrecorded manifest state before final release");
   end if;

   if not File_Contains ("tools/strict_runtime_preflight.adb", "EDITOR_REQUIRE_STRICT_RUNTIME_PREFLIGHT")
     or else not File_Contains ("tools/strict_runtime_preflight.adb", "Require_One_Build_Tool")
     or else not File_Contains ("tools/strict_runtime_preflight.adb", "Require_Display")
     or else not File_Contains ("tools/strict_runtime_preflight.adb", "glslangValidator")
     or else not File_Contains ("tools/strict_runtime_validation.adb", "strict runtime preflight")
     or else not File_Contains ("tools/strict_runtime_validation_record.adb", "gate-strict-runtime-preflight")
   then
      Fail (Tool, "strict runtime validation must include the Ada preflight gate before runtime compile/link/smoke execution");
   end if;

   if not File_Contains ("tools/strict_runtime_validation.adb", "shader toolchain manifest check")
     or else not File_Contains ("tools/strict_runtime_validation_record.adb", "gate-shader-toolchain-manifest")
   then
      Fail (Tool, "strict runtime validation must run shader toolchain manifest gate before shader freshness");
   end if;

   if not File_Contains ("docs/release/SHADER_TOOLCHAIN_VERSION.txt", "SHADER_TOOLCHAIN_MANIFEST_STATE=UNRECORDED")
     and then not File_Contains ("docs/release/SHADER_TOOLCHAIN_VERSION.txt", "SHADER_TOOLCHAIN_MANIFEST_STATE=RECORDED")
   then
      Fail (Tool, "shader toolchain manifest must declare SHADER_TOOLCHAIN_MANIFEST_STATE");
   end if;

   if not File_Contains ("tools/editor_tool_common.ads", "Captured_Command_Output")
     or else not File_Contains ("tools/editor_tool_common.ads", "Run_Capture_Bounded")
     or else not File_Contains ("tools/editor_tool_common.ads", "Read_Text_Bounded")
     or else not File_Contains ("tools/editor_tool_common.ads", "Output_Contains")
     or else not File_Contains ("tools/editor_tool_common.adb", "Default_Max_Captured_Output")
   then
      Fail (Tool, "Editor_Tool_Common must provide bounded command-output capture helpers for Ada release gates");
   end if;

   if not File_Contains ("tools/editor_tool_common.ads", "Captured_Output_Merged")
     or else not File_Contains ("tools/editor_tool_common.ads", "merged-output capture")
     or else not File_Contains ("tools/editor_tool_common.adb", "Result.Provenance := Captured_Output_Merged")
     or else not File_Contains ("docs/release/ADA_RELEASE_TOOLING.md", "merged stdout/stderr")
     or else not File_Contains ("README.md", "merged stdout/stderr capture")
     or else not File_Contains ("docs/release/RELEASE_CHECKLIST.md", "merged stdout/stderr")
     or else not File_Contains ("tools/strict_runtime_validation_record.adb", "Output provenance: merged stdout/stderr")
     or else not File_Contains ("tools/release_check_record.adb", "Output provenance: merged stdout/stderr")
   then
      Fail (Tool, "Ada release-tool bounded capture must be documented and reported as merged stdout/stderr capture");
   end if;

   if not File_Contains ("tools/runtime_missing_asset_check.adb", "Run_Capture_Bounded")
     or else not File_Contains ("tools/runtime_missing_asset_check.adb", "runtime asset error")
     or else not File_Contains ("tools/runtime_missing_asset_check.adb", "EDITOR_SHADER_DIR_ONLY")
     or else not File_Contains ("tools/runtime_missing_asset_check.adb", "Output_Contains")
   then
      Fail (Tool, "runtime missing-asset gate must capture and verify the expected diagnostic text");
   end if;

   if not File_Contains ("tools/runtime_smoke.adb", "EDITOR_RUNTIME_SMOKE_TIMEOUT_SECONDS")
     or else not File_Contains ("tools/runtime_smoke.adb", "--runtime-smoke-max-seconds=")
     or else not File_Contains ("src/runtime/main.c", "--runtime-smoke-max-seconds=")
     or else not File_Contains ("src/runtime/runtime_glfw.adb", "exceeded internal smoke timeout")
     or else File_Contains ("tools/runtime_smoke.adb", "Command_Exists (""timeout"")")
     or else File_Contains ("tools/runtime_smoke.adb", "--kill-after=")
     or else not File_Contains ("docs/release/RUNTIME_SMOKE.md", "--runtime-smoke-max-seconds")
     or else not File_Contains ("README.md", "--runtime-smoke-max-seconds")
   then
      Fail (Tool, "runtime smoke must use the runtime's internal bounded smoke timeout, not an external timeout utility");
   end if;



   if not File_Contains ("tools/release_check_record.adb", "Run_Capture_Bounded")
     or else not File_Contains ("tools/release_check_record.adb", "release-check-validation.md")
     or else not File_Contains ("tools/release_check_record.adb", "tools/bin/release_check")
     or else not File_Contains ("tools/release_check_record.adb", "Captured output:")
   then
      Fail (Tool, "release_check_record must capture tools/bin/release_check output into a release evidence report");
   end if;

   if not File_Contains ("tools/final_release_validation_check.adb", "PASS: release_check completed successfully.")
     or else not File_Contains ("tools/final_release_validation_check.adb", "PASS: strict runtime validation completed successfully.")
     or else not File_Contains ("tools/final_release_validation_check.adb", "SHADER_TOOLCHAIN_MANIFEST_STATE=RECORDED")
     or else not File_Contains ("tools/final_release_validation_check.adb", "Result: TOOL NOT FOUND")
     or else not File_Contains ("tools/final_release_validation_check.adb", "Unexpected_Program_Error (Tool)")
   then
      Fail (Tool, "final_release_validation_check must require recorded release-check and strict-runtime evidence reports");
   end if;

   if not File_Contains ("tools/release_candidate_check.adb", "RELEASE_STATE=RELEASE_CANDIDATE")
     or else not File_Contains ("tools/release_candidate_check.adb", "EDITOR_REQUIRE_RELEASE_CANDIDATE")
     or else not File_Contains ("tools/release_candidate_check.adb", "SHADER_TOOLCHAIN_MANIFEST_STATE=RECORDED")
     or else not File_Contains
       ("tools/release_candidate_check.adb",
        "PASS: strict runtime validation completed successfully.")
     or else not File_Contains ("docs/release/RELEASE_STATE.txt", "RELEASE_STATE=DEVELOPMENT_SNAPSHOT")
     or else not File_Contains ("docs/release/RELEASE_CANDIDATE_POLICY.md", "RELEASE_STATE=RELEASE_CANDIDATE")
   then
      Fail (Tool, "release_candidate_check must prevent release-candidate claims without final validation evidence");
   end if;

   if not File_Contains ("tools/strict_runtime_validation_record.adb", "Run_Capture_Bounded")
     or else not File_Contains ("tools/strict_runtime_validation_record.adb", "Put_Output_Block")
     or else not File_Contains ("tools/strict_runtime_validation_record.adb", "Captured output:")
     or else not File_Contains ("tools/strict_runtime_validation_record.adb", "gate-runtime-smoke.out")
     or else not File_Contains ("tools/strict_runtime_validation_record.adb", "toolchain-glslangvalidator.out")
   then
      Fail (Tool, "strict runtime validation record must capture bounded per-gate and toolchain output into the report");
   end if;


   if File_Contains ("tools/product_smoke.adb", "Run3 (""gprbuild"", ""-P""")
     or else File_Contains ("tools/real_build_runner_smoke.adb", "Run3 (""gprbuild"", ""-P""")
     or else File_Contains ("tools/runtime_link_check.adb", "Run3 (""gprbuild"", ""-P""")
     or else File_Contains ("tools/unit_tests.adb", "Run3 (""gprbuild"", ""-P""")
   then
      Fail (Tool, "Ada release tools must use Run2 for gprbuild -P <project> calls");
   end if;

   if not File_Contains ("tools/editor_tool_common.adb", "Last > 0")
     or else not File_Contains ("tools/editor_tool_common.adb", "File_Contains")
   then
      Fail (Tool, "Editor_Tool_Common.File_Contains must handle empty lines safely");
   end if;

   if not File_Contains ("tools/release_check.adb", "Release_Check_Failed")
     or else not File_Contains ("tools/release_check.adb", "unexpected Program_Error during release check")
     or else not File_Contains ("tools/release_check.adb", "unexpected exception during release check")
   then
      Fail (Tool, "release_check must distinguish intentional Fail exits from unexpected exceptions");
   end if;

   if not File_Contains ("tools/editor_tool_common.ads", "Unexpected_Program_Error")
     or else not File_Contains ("tools/editor_tool_common.adb", "unexpected Program_Error outside intentional Fail path")
   then
      Fail (Tool, "Editor_Tool_Common must expose a shared unexpected Program_Error handler");
   end if;


   if not File_Contains ("src/core/editor-external_producers.adb", "C_Fork")
     or else not File_Contains ("src/core/editor-external_producers.adb", "C_Waitpid")
     or else not File_Contains ("src/core/editor-external_producers.adb", "C_Kill")
     or else not File_Contains ("src/core/editor-external_producers.adb", "Execute_With_Native_Process_Supervisor")
     or else File_Contains ("src/core/editor-external_producers.adb", "/usr/bin/timeout")
     or else File_Contains ("tests/e2e/editor_real_build_runner_smoke.adb", "/usr/bin/timeout")
     or else File_Contains ("README.md", "/usr/bin/timeout")
     or else File_Contains ("docs/release/BUILD_RUNNER_PROCESS_MANAGEMENT.md", "/usr/bin/timeout")
   then
      Fail (Tool, "build runner timeouts must use the native process supervisor, not /usr/bin/timeout");
   end if;


   if not File_Contains ("src/core/editor-external_producers.ads", "Native_Process_Control_Backend")
     or else not File_Contains ("src/core/editor-external_producers.ads", "Native_Process_Control_POSIX")
     or else not File_Contains ("src/core/editor-external_producers.ads", "Current_Native_Process_Control_Backend")
     or else not File_Contains ("src/core/editor-external_producers.ads", "Native_Process_Control_Platform_Audit_Passes")
     or else not File_Contains ("src/core/editor-external_producers.adb", "POSIX/fork-exec-waitpid-kill")
     or else not File_Contains ("tests/src/editor-build_execution_workflow-tests.adb", "Test_Native_Process_Control_Backend_Is_Explicitly_POSIX")
     or else not File_Contains ("docs/release/BUILD_PROCESS_PLATFORM_SUPPORT.md", "POSIX/fork-exec-waitpid-kill")
     or else not File_Contains ("docs/release/BUILD_PROCESS_PLATFORM_SUPPORT.md", "CreateProcess")
     or else not File_Contains ("docs/release/RELEASE_CHECKLIST.md", "Native_Process_Control_POSIX")
     or else not File_Contains ("README.md", "BUILD_PROCESS_PLATFORM_SUPPORT.md")
   then
      Fail (Tool, "build process-control platform support must be explicit and POSIX-scoped until another backend is implemented");
   end if;


   if not File_Contains ("src/core/editor-build_process_control.ads", "Build_Process_Handle")
     or else not File_Contains ("src/core/editor-build_process_control.adb", "External_Name => ""kill""")
     or else not File_Contains ("src/core/editor-build_command.adb", "Request_Cancel")
     or else not File_Contains ("src/core/editor-build_command.ads", "Register_Public_Build_Process")
     or else not File_Contains ("src/core/editor-state.ads", "Public_Build_Process_Handle")
     or else not File_Contains ("src/core/editor-external_producers.adb", "Register_Active_Build_Process")
     or else not File_Contains ("src/core/editor-external_producers.adb", "From_System_Process_Id")
     or else not File_Contains ("src/core/editor-external_producers.adb", "Clear_Active_Build_Process")
     or else not File_Contains ("src/core/editor-external_producers.adb", "Execute_Process_Request_Gated_With_State")
     or else not File_Contains ("src/core/editor-external_producers.adb", "Process_Run_Cancelled")
   then
      Fail (Tool, "build.cancel must signal the live real-runner child process handle instead of only a test/manual handle");
   end if;

   if not File_Contains ("src/core/editor-external_producers.adb", "Stdout_Capture_File")
     or else not File_Contains ("src/core/editor-external_producers.adb", "Stderr_Capture_File")
     or else not File_Contains ("src/core/editor-external_producers.adb", "C_Dup2 (Out_Fd, 1)")
     or else not File_Contains ("src/core/editor-external_producers.adb", "C_Dup2 (Err_Fd, 2)")
     or else not File_Contains ("src/core/editor-external_producers.adb", "Output_Capture_Mode => Process_Output_Capture_Separated")
     or else not File_Contains ("src/core/editor-external_producers.adb", "return Process_Output_Capture_Separated")
     or else File_Contains ("src/core/editor-external_producers.adb", "Err_To_Out")
     or else File_Contains ("docs/release/BUILD_RUNNER_PROCESS_MANAGEMENT.md", "separated stdout/stderr capture remains a later")
     or else File_Contains ("README.md", "real runner uses an explicit no-loss merged")
   then
      Fail (Tool, "real build runner must capture stdout and stderr as separated bounded streams");
   end if;


   if File_Contains ("README.md", "currently reports cancellation unsupported")
     or else File_Contains ("docs/release/BUILD_RUNNER_PROCESS_MANAGEMENT.md", "currently reports cancellation unsupported")
     or else File_Contains ("src/core/editor-build_command.adb", "does not own a live OS process handle")
   then
      Fail (Tool, "build cancellation documentation/source must not describe cancellation as permanently unsupported");
   end if;

   if not File_Contains ("src/core/editor-build_command.ads", "Start_Public_Build_Run_Asynchronously")
     or else not File_Contains ("src/core/editor-build_command.ads", "Poll_Public_Build_Run_Completion")
     or else not File_Contains ("src/core/editor-state.ads", "Public_Build_Async_Slot_Id")
     or else not File_Contains ("src/core/editor-state.ads", "Public_Build_Async_Job_Queued")
     or else not File_Contains ("src/core/editor-executor.adb", "Start_Public_Build_Run_Asynchronously")
     or else not File_Contains ("src/core/editor-executor.adb", "Poll_Public_Build_Run_Completion")
     or else not File_Contains ("src/core/editor-input_bridge.ads", "Tick_Async_Build_Jobs")
     or else not File_Contains ("src/core/editor-input_bridge.adb", "Tick_Async_Build_Jobs")
     or else not File_Contains ("src/core/editor-input_bridge.adb", "Poll_Public_Build_Run_Completion")
     or else not File_Contains ("src/core/editor-c_api.adb", "Tick_Async_Build_Jobs")
     or else not File_Contains ("tests/src/editor-input_bridge-tests.adb", "Test_Async_Build_Idle_Tick_Hook_Is_Callable")
     or else not File_Contains ("src/core/editor-build_command.adb", "task type Public_Build_Worker")
     or else not File_Contains ("src/core/editor-build_command.adb", "Max_Public_Build_Async_Slots")
     or else not File_Contains ("src/core/editor-build_command.adb", "Public_Build_Slot_Allocator")
     or else not File_Contains ("src/core/editor-build_command.adb", "type Public_Build_Worker_Array")
     or else not File_Contains ("src/core/editor-build_command.adb", "Public_Build_Workers : Public_Build_Worker_Array")
     or else not File_Contains ("src/core/editor-build_command.adb", "Slot_Index_For")
     or else not File_Contains ("src/core/editor-build_command.adb", "Slot_Available_For")
     or else not File_Contains ("src/core/editor-build_command.adb", "async build slot pool exhausted")
     or else not File_Contains ("src/core/editor-build_command.adb", "protected type Public_Build_Job_Registry")
     or else not File_Contains ("src/core/editor-build_command.adb", "Public_Build_Jobs.Store_Queued")
     or else not File_Contains ("src/core/editor-build_command.adb", "Public_Build_Jobs.Final_Result")
     or else not File_Contains ("src/core/editor-build_command.ads", "Assert_Async_Build_Cancel_Handoff_Behavior")
     or else not File_Contains ("src/core/editor-build_command.ads", "Assert_Async_Build_Output_Snapshot_Handoff_Behavior")
     or else not File_Contains ("src/core/editor-build_command.ads", "Assert_Async_Build_Partial_Stdout_Stderr_Before_Completion")
     or else not File_Contains ("src/core/editor-build_command.ads", "Assert_Async_Build_Real_Process_Cancel_Integration")
     or else not File_Contains ("src/core/editor-build_command.ads", "Request_Public_Build_Lifecycle_Shutdown")
     or else not File_Contains ("src/core/editor-build_command.ads", "Assert_Async_Build_Lifecycle_Shutdown_Handoff_Behavior")
     or else not File_Contains ("src/core/editor-build_command.ads", "Drain_Public_Build_Worker_For_Shutdown")
     or else not File_Contains ("src/core/editor-build_command.ads", "Assert_Async_Build_Worker_Shutdown_Drain_Behavior")
     or else not File_Contains ("src/core/editor-build_command.ads", "Assert_Async_Build_State_Slots_Are_Isolated")
     or else not File_Contains ("src/core/editor-build_command.ads", "Assert_Async_Build_Slot_Id_Is_Stable_Per_State")
     or else not File_Contains ("src/core/editor-build_command.ads", "Assert_Async_Build_Slot_Pool_Exhaustion_Is_Rejected")
     or else not File_Contains ("src/core/editor-build_command.adb", "Public_Build_Async_Slot_Id is deliberately stable")
     or else not File_Contains ("src/core/editor-build_command.adb", "entry Drain")
     or else not File_Contains ("src/core/editor-build_command.adb", "entry Stop")
     or else not File_Contains ("src/core/editor-build_command.adb", "Public_Build_Worker_Lifecycle")
     or else not File_Contains ("src/core/editor-build_command.adb", "Stop_Public_Build_Workers_For_Application_Exit")
     or else not File_Contains ("src/core/editor-build_command.adb", "Build unavailable: async build worker pool is stopping")
     or else not File_Contains ("src/core/editor-build_command.adb", "Assert_Async_Build_Worker_Stop_Terminates_Pool_Behavior")
     or else not File_Contains ("src/core/editor-build_command.adb", "Drain_Public_Build_Worker_For_Shutdown")
     or else not File_Contains ("src/core/editor-executor.adb", "Request_Build_Shutdown_For_Lifecycle")
     or else not File_Contains ("tests/src/editor-build_execution_workflow-tests.adb", "Test_Async_Build_Cancel_Handoff_State_Machine")
     or else not File_Contains ("tests/src/editor-build_execution_workflow-tests.adb", "Test_Async_Build_Output_Snapshot_Handoff_State_Machine")
     or else not File_Contains ("tests/src/editor-build_execution_workflow-tests.adb", "Test_Async_Build_Partial_Stdout_Stderr_Before_Completion")
     or else not File_Contains ("tests/src/editor-build_execution_workflow-tests.adb", "Test_Async_Build_Real_Process_Cancel_Integration")
     or else not File_Contains ("tests/src/editor-build_execution_workflow-tests.adb", "Test_Async_Build_Lifecycle_Shutdown_Handoff")
     or else not File_Contains ("tests/src/editor-build_execution_workflow-tests.adb", "Test_Async_Build_Worker_Shutdown_Drain")
     or else not File_Contains ("tests/src/editor-build_execution_workflow-tests.adb", "Test_Async_Build_State_Slots_Are_Isolated")
     or else not File_Contains ("tests/src/editor-build_execution_workflow-tests.adb", "Test_Async_Build_Slot_Id_Is_Stable_Per_State")
     or else not File_Contains ("tests/src/editor-build_execution_workflow-tests.adb", "Test_Async_Build_Slot_Pool_Exhaustion_Is_Rejected")
     or else not File_Contains ("tests/src/editor-build_execution_workflow-tests.adb", "Test_Async_Build_Worker_Stop_Terminates_Pool")
     or else not File_Contains ("docs/release/BUILD_RUNNER_PROCESS_MANAGEMENT.md", "ninth simultaneous occupied slot is rejected")
     or else not File_Contains ("docs/release/BUILD_RUNNER_PROCESS_MANAGEMENT.md", "worker stop/termination")
     or else not File_Contains ("src/core/editor-build_command.adb", "Build still running")
     or else not File_Contains ("src/core/editor-build_command.adb", "return False;")
     or else File_Contains ("src/core/editor-build_command.adb", "the actual process still starts and waits inside the poll function")
     or else File_Contains ("src/core/editor-build_command.adb", "Pending_Public_Build_Request :")
     or else File_Contains ("src/core/editor-build_command.adb", "Pending_Public_Build_Runner_Gate :")
     or else File_Contains ("src/core/editor-build_command.adb", "Pending_Public_Build_Result_Gate :")
     or else File_Contains ("src/core/editor-build_command.adb", "Async_Worker_State :")
     or else File_Contains ("src/core/editor-build_command.adb", "Async_Worker_Result :")
     or else File_Contains ("src/core/editor-build_command.adb", "Async_Worker_Running :")
     or else File_Contains ("src/core/editor-build_command.adb", "Async_Worker_Result_Ready :")
     or else File_Contains ("src/core/editor-build_command.adb", "Public_Build_Job : Public_Build_Job_Handoff")
     or else File_Contains ("src/core/editor-build_command.adb", "Public_Build_Job : Public_Build_Job_Registry")
     or else File_Contains ("src/core/editor-build_command.adb", "Public_Build_Worker_Task : Public_Build_Worker;")
     or else File_Contains ("src/core/editor-build_command.adb", "Public_Build_Worker_For_Slot")
     or else not File_Contains ("docs/release/BUILD_RUNNER_PROCESS_MANAGEMENT.md", "Async worker shutdown/drain")
   then
      Fail (Tool, "public build.run must use a worker-backed asynchronous build-job lifecycle instead of deferred blocking poll execution");
   end if;

   if not File_Contains ("src/core/editor-build_process_control.ads", "Publish_Active_Process")
     or else not File_Contains ("src/core/editor-build_process_control.ads", "Active_Process_Handle")
     or else not File_Contains ("src/core/editor-build_process_control.ads", "Request_Active_Cancel")
     or else not File_Contains ("src/core/editor-build_process_control.ads", "Publish_Active_Output_Stream")
     or else not File_Contains ("src/core/editor-build_process_control.ads", "Active_Output_Stream")
     or else not File_Contains ("src/core/editor-build_process_control.ads", "Active_Cancel_Requested")
     or else not File_Contains ("src/core/editor-build_command.adb", "stdout-before-completion")
     or else not File_Contains ("src/core/editor-build_command.adb", "stderr-before-completion")
     or else not File_Contains ("src/core/editor-build_process_control.adb", "protected type Active_Build_Process_State")
     or else not File_Contains ("src/core/editor-external_producers.adb", "Publish_Active_Process")
     or else not File_Contains ("src/core/editor-external_producers.adb", "Publish_Active_Output_Stream")
     or else not File_Contains ("src/core/editor-external_producers.adb", "Active_Cancel_Requested")
     or else not File_Contains ("src/core/editor-build_command.adb", "Active_Process_Handle")
     or else not File_Contains ("src/core/editor-build_command.adb", "Active_Output_Stream")
     or else not File_Contains ("src/core/editor-build_command.adb", "/bin/sleep")
     or else not File_Contains ("src/core/editor-build_command.adb", "Execute_Process_Request_Gated_With_State")
   then
      Fail (Tool, "asynchronous build cancellation/output must use synchronized active process state for build.cancel and live stream snapshots");
   end if;

   if not File_Contains ("src/core/editor-external_producers.adb", "Stream_Capture_Deltas")
     or else not File_Contains ("src/core/editor-external_producers.adb", "Append_Build_Output_Stream_Chunk")
     or else File_Contains ("README.md", "final bounded chunk only")
     or else File_Contains ("README.md", "live separate stdout/stderr capture")
     or else File_Contains ("docs/dogfood_scenario.md", "represented unavailable result")
     or else File_Contains ("docs/FEATURE_INTEGRATION.md", "intentionally")
     or else File_Contains ("docs/FEATURE_INTEGRATION.md", "placeholder/test rows")
   then
      Fail (Tool, "build output streaming and feature/dogfood docs must describe current behavior, not stale incomplete-feature claims");
   end if;


   if not File_Contains ("tools/ada_keyword_identifier_check.adb", "Is_Ada_Keyword")
     or else not File_Contains ("tools/ada_keyword_identifier_check.adb", "Source_Line")
     or else not File_Contains ("tools/ada_keyword_identifier_check.adb", "Check_Header_Identifiers")
     or else not File_Contains ("tools/ada_keyword_identifier_check.adb", "Check_Colon_Declaration")
     or else not File_Contains ("tools/ada_keyword_identifier_check.adb", "Ada keyword used as")
   then
      Fail
        (Tool,
         "Ada keyword identifier gate must scan declarations case-insensitively and ignore comments/strings");
   end if;

   Require_Program_Error_Guard ("tools/compile_shaders.adb");
   Require_Program_Error_Guard ("tools/release_commands.adb");
   Require_Program_Error_Guard ("tools/final_release_validation_check.adb");
   Require_Program_Error_Guard ("tools/release_candidate_check.adb");
   Require_Program_Error_Guard ("tools/product_smoke.adb");
   Require_Program_Error_Guard ("tools/real_build_runner_smoke.adb");
   Require_Program_Error_Guard ("tools/record_shader_toolchain_manifest.adb");
   Require_Program_Error_Guard ("tools/release_check_record.adb");
   Require_Program_Error_Guard ("tools/runtime_compile_check.adb");
   Require_Program_Error_Guard ("tools/runtime_link_check.adb");
   Require_Program_Error_Guard ("tools/runtime_missing_asset_check.adb");
   Require_Program_Error_Guard ("tools/runtime_smoke.adb");
   Require_Program_Error_Guard ("tools/shader_freshness_check.adb");
   Require_Program_Error_Guard ("tools/shader_toolchain_manifest_check.adb");
   Require_Program_Error_Guard ("tools/strict_runtime_preflight.adb");
   Require_Program_Error_Guard ("tools/strict_runtime_validation.adb");
   Require_Program_Error_Guard ("tools/strict_runtime_validation_record.adb");
   Require_Program_Error_Guard ("tools/unit_tests.adb");
   Require_Program_Error_Guard ("tools/language_validation_check.adb");
   Require_Program_Error_Guard ("tools/ada_keyword_identifier_check.adb");

   --  Run the dependency-aware Ada gate tools.  Each gate preserves the old
   --  release-check behavior: it runs when its dependencies are available,
   --  reports an explicit skip in non-strict mode when they are unavailable,
   --  and fails when its own strict environment variable requires execution.
   Run_Tool_Gate ("outline_static_sanity", "Outline static sanity gate");
   Run_Tool_Gate ("ada_keyword_identifier_check", "Ada keyword identifier gate");
   Run_Tool_Gate
     ("runtime_compile_check", "runtime C entrypoint/Ada backend gate");
   Run_Tool_Gate ("runtime_link_check", "runtime link/build gate");
   Run_Tool_Gate ("runtime_smoke", "runtime graphical smoke gate");
   Run_Tool_Gate ("runtime_missing_asset_check", "runtime missing-shader negative gate");
   Run_Tool_Gate ("check_docs", "documentation/tooling contract gate");
   Run_Tool_Gate ("check_repo_hygiene", "repository hygiene gate");
   Run_Tool_Gate ("shader_toolchain_manifest_check", "shader toolchain manifest gate");
   Run_Tool_Gate ("release_candidate_check", "release-candidate state/evidence gate");
   Run_Tool_Gate ("strict_runtime_preflight", "strict runtime validation preflight gate");
   Run_Tool_Gate ("shader_freshness_check", "shader freshness gate");
   Run_Tool_Gate ("unit_tests", "release All_Suites AUnit gate", "all");
   Run_Tool_Gate ("language_validation_check", "language-model GNAT/AUnit validation gate");
   Run_Tool_Gate ("product_smoke", "product workflow smoke gate");
   Run_Tool_Gate ("real_build_runner_smoke", "real build-runner smoke gate");

   if Strict ("EDITOR_REQUIRE_FINAL_RELEASE_VALIDATION") then
      Run_Tool_Gate ("final_release_validation_check", "final release validation evidence gate");
   else
      Info
        (Tool,
         "final release validation evidence gate skipped; set EDITOR_REQUIRE_FINAL_RELEASE_VALIDATION=1 after recording release and strict runtime reports");
   end if;

   Info (Tool, "completed");
exception
   when Program_Error =>
      if Release_Check_Failed then
         null;
      else
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
         Info (Tool, "unexpected Program_Error during release check");
      end if;
   when others =>
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      Info (Tool, "unexpected exception during release check");
end Release_Check;

--  token-cursor release guard: Production_Task_Definition Production_Entry_Family_Definition Production_Limited_With_Clause Production_Private_With_Clause Production_Attribute_Definition_Clause Production_Enumeration_Representation_Clause Production_Address_Clause Production_Slice Production_Explicit_Dereference Production_Discrete_Choice_List Production_Discrete_Choice Production_Range_Expression
--  syntax-tree projection release guard: Project_Syntax_Tree_Into_Model Merge_Symbol_Flags Syntax_Node_Symbol_Kind Target_Name_Matches Find_Metadata_Target Test_Language_Model_Syntax_Tree_Projection_Feeds_Symbols Test_Language_Model_Syntax_Tree_Selected_Metadata_Targets Test_Resolver_Scoped_Selected_Name_Does_Not_Leaf_Fallback

--  Pass 351 release guard tokens: Representation_Component_Info Add_Record_Representation_Component Representation_Component_Count Representation_Component_At record representation component layout metadata
--  Pass 352 release guard tokens: Max_Representation_Components Test_Language_Model_Record_Representation_Static_Literals_Are_Parsed based representation literals overflow fingerprint
--  Pass 353 release guard tokens: Visibility_Clause_Info Add_Visibility_Clause Visibility_Clause_Count Test_Resolver_Use_Package_Clause_Exposes_Package_Children use-clause visibility resolver
--  Pass 354 release guard tokens: Test_Resolver_Use_Type_Clause_Exposes_Primitive_Operators_Only Append_Primitive_Operator_Matches use-type operator visibility no record component flattening
--  Pass 355 release guard tokens: Test_Resolver_Use_Selected_Nested_Package_Clause selected nested package use-clause Package_Target prefix ownership

--  Pass 356 release guard tokens: Resolve_Call_In_Scope Test_Resolver_Call_Overload_Resolution_Uses_Profile_Actuals conservative call overload selection named actual expected result type
--  Pass 357 release guard tokens: Test_Resolver_Call_Overload_Resolution_Uses_Defaulted_Formals Has_Default omitted defaulted formals
--  Pass 358 release guard tokens: Infer_Expression_Type_In_Scope Resolve_Call_Expression_In_Scope Test_Resolver_Expression_Aware_Overload_Resolution expression-aware overload selection unknown actuals non-wildcard
--  Pass 359 release guard tokens: Test_Resolver_Expression_Aware_Operator_Expressions parenthesized signed operator expressions unknown operator operands non-wildcard comparison expressions Boolean
--  Pass 360 release guard tokens: Test_Resolver_Expression_Aware_Unary_And_Membership unary not unary abs membership expressions not in exponentiation unknown unary operands non-wildcard
--  Pass 361 release guard tokens: Test_Resolver_Expression_Aware_Conditional_Expressions conditional expressions Boolean condition incompatible branches non-wildcard
--  Pass 362 release guard tokens: Indexed_Unit_Role Resolve_Unit Resolve_Related_Unit_Target Resolve_Separate_Parent_Target Test_Project_Index_Cross_File_Unit_Relationship_Table cross-file Ada unit relationship indexing

--  Pass 363 release guard tokens: Resolve_Parent_Unit_Target Test_Project_Index_Child_Unit_Parent_Relationship_Target child-unit parent relationship lookup
--  Pass 364 release guard tokens: Resolve_Child_Units Test_Project_Index_Parent_Lists_Direct_Child_Units direct child-unit listing
--  Pass 365 release guard tokens: Resolve_Unit_Family Test_Project_Index_Unit_Family_Lists_Validated_Targets validated unit-family target listing

--  Pass 366 release guard tokens: Is_Library_Unit_Symbol Test_Project_Index_Unit_Table_Excludes_Nested_Declarations library-unit-only unit table rows
--  Pass 367 release guard tokens: Generic_Actual_Info Add_Generic_Actual Generic_Actual_Count Generic_Target_Symbol Substitute_Generic_Actual_Type Test_Resolver_Generic_Instance_Expansion_Uses_Actuals generic instance semantic expansion
--  Pass 368 release guard tokens: Effective_Inferred_Type_From_Symbol Test_Resolver_Generic_Instance_Expression_Inference_Substitutes_Actuals generic instance expression inference substituted actual types
--  Pass 369 release guard tokens: Navigation_Candidate_Result Resolve_Navigation_Candidates Resolve_Related_Unit_Candidates ambiguous navigation candidates

--  Pass 370 release guard tokens: Navigation_Candidate_Display_Label Navigation_Candidate_Detail_Label Test_Project_Index_Navigation_Candidate_Labels_Are_Presentable ambiguity chooser labels

--  Pass 371 release guard tokens: Representation_Clause_Info Enumeration_Representation_Literal_Info Add_Representation_Clause Add_Enumeration_Representation_Literal Test_Language_Model_Representation_Clauses_Beyond_Record_Layout enum size alignment bit_order address representation metadata
--  Pass 372 release guard tokens: Test_Language_Model_Representation_Static_Expressions_Are_Evaluated Parse_Expression bounded static representation expressions mod rem exponentiation
--  Pass 373 release guard tokens: Test_Language_Model_Representation_Based_Exponent_Expressions based literal exponent representation expressions Exponent_Base
--  Pass 374 guard note: release checks should preserve named-number backed
--  representation static-expression regression coverage.
--  Pass 375 guard: release checks should retain executable-statement semantic
--  binding APIs (Add_Executable_Binding / Executable_Binding_Count) so the
--  language model does not regress to declaration-only semantic colouring.

--  Pass 376 guard: executable expression calls must remain parser-owned
--  bindings.  Keep Test_Language_Model_Executable_Expression_Call_Bindings
--  and Add_Call_Targets_In_Expression so conditions, assignment RHS calls,
--  and nested actual calls do not regress to standalone-call-only metadata.

--  Pass 377 guard: executable selected component uses must remain parser-owned
--  bindings. Keep Test_Language_Model_Executable_Selected_Component_Uses and
--  Add_Selected_Components_In_Expression so conditions, actual expressions,
--  assignment RHS expressions, and assignment targets retain component-use
--  metadata without rendering-side parsing.

--  Pass 378 guard: executable case alternatives must remain distinct from
--  exception handler choices. Keep Binding_Case_Choice and
--  Test_Language_Model_Executable_Case_Choices_Are_Distinct so `when` lines
--  in case statements do not regress to exception-choice metadata.

-- Pass 379 guard: release checks should preserve executable expression binding kinds including Binding_Array_Index, Binding_Array_Slice, Binding_Dereference, Binding_Allocator, Binding_Aggregate_Component, and Binding_Qualified_Expression_Target.

--  Pass 380 guard: executable attribute prefixes must remain parser-owned
--  bindings. Keep Binding_Attribute_Prefix and
--  Test_Language_Model_Executable_Attribute_Prefix_Bindings so Obj'Length,
--  X'Size, and T'Image (...) do not regress to unbound attribute text or
--  qualified-expression confusion.
--  Pass 381 guard: executable raise/requeue/accept targets must remain parser-owned bindings.
--  Pass 382 guard: executable block labels and exit targets must remain parser-owned bindings.
--  Keep Binding_Block_Label, Binding_Exit_Target, and
--  Test_Language_Model_Executable_Block_And_Exit_Targets so named loops/blocks
--  and exit targets do not regress to unstructured text.

--  Pass 383 guard: executable return bindings must remain parser-owned
--  metadata.  Keep Binding_Return_Target, Binding_Return_Object, and
--  Test_Language_Model_Executable_Return_Bindings coverage.
--  Pass 384 guard: executable delay/abort targets must remain parser-owned bindings.
--  Required binding names: Binding_Delay_Target, Binding_Abort_Target.
--  Pass 385 guard: executable condition/selector and iteration-source targets must remain parser-owned bindings.
--  Required binding names: Binding_Condition_Target, Binding_Iteration_Source.
--  Pass 386 guard: executable select-statement bindings must remain parser-owned.
--  Keep Binding_Select_Guard, Binding_Select_Entry_Call, and
--  Test_Language_Model_Executable_Select_Bindings so select guards are not
--  misclassified as case alternatives and select/or keywords are not treated as calls.

--  Pass 387 guard: timed select alternatives must remain parser-owned.
--  Keep Binding_Select_Delay_Target and Test_Language_Model_Executable_Select_Bindings
--  so `or delay until ...` is not lost or misclassified as an entry call.

--  Pass 388 guard note: keep Binding_Select_Terminate and select terminate
--  coverage in Test_Language_Model_Executable_Select_Bindings.

--  Pass 389 guard note: keep Binding_Entry_Barrier and
--  Test_Language_Model_Executable_Entry_Barrier_Bindings so protected entry
--  barrier expression names remain executable metadata distinct from select
--  guards and declaration outline rows.

--  Pass 390 guard note: keep Binding_Range_Bound and
--  Test_Language_Model_Executable_Range_Bound_Bindings so executable loop/slice
--  range endpoints remain parser-owned semantic metadata, distinct from array
--  slice and iteration-source bindings.

--  Pass 391 guard note: keep Binding_Pragma_Argument and the associated
--  executable pragma argument regression test so pragma-led lines do not
--  regress to bogus fallback call targets.

--  Pass 392 guard note: keep Binding_Quantified_Parameter, Binding_Quantified_Source,
--  and Test_Language_Model_Executable_Quantified_Expression_Bindings so
--  executable quantified-expression bindings do not regress.

--  Pass 393 guard note: keep Binding_Named_Actual and
--  Test_Language_Model_Executable_Named_Actual_Bindings so call
--  parameter associations stay distinct from aggregate component metadata.

--  Pass 394 guard note: keep Binding_Case_Expression_Selector,
--  Binding_Case_Expression_Choice, and
--  Test_Language_Model_Executable_Case_Expression_Bindings so executable
--  case-expression metadata remains distinct from statement case alternatives.

--  Pass 395 guard note: keep Binding_Conditional_Expression_Condition,
--  Binding_Conditional_Expression_Branch, and
--  Test_Language_Model_Executable_Conditional_Expression_Bindings so
--  executable conditional-expression metadata remains distinct from statement
--  condition bindings.

--  Pass 396 guard note: keep Binding_Raise_Expression_Target and
--  Test_Language_Model_Executable_Raise_Expression_Bindings so raise
--  expressions remain distinct from statement-level raise targets.

--  Pass 397 guard: executable delta aggregate bindings must remain parser-owned
--  metadata.  Keep Binding_Delta_Aggregate_Base,
--  Binding_Delta_Aggregate_Component, and
--  Test_Language_Model_Executable_Delta_Aggregate_Bindings so Ada 2022
--  with-delta expressions do not regress to named actual or aggregate-only
--  metadata.
--  Pass 398 guard: keep Binding_Type_Conversion_Target and Test_Language_Model_Executable_Type_Conversion_Bindings so explicit type conversions stay distinct from calls and indexing.
--  Pass 399 guard: keep Binding_Aspect_Expression and Test_Language_Model_Executable_Aspect_Expression_Bindings so contract aspect expressions remain parser-owned executable semantic metadata.
--  Pass 400 guard: keep Binding_Accept_Parameter and the extended
--  Test_Language_Model_Executable_Transfer_And_Tasking_Targets coverage so
--  accept statement formals remain executable local semantic bindings distinct
--  from Binding_Accept_Entry.

--  Pass 401 guard: keep Binding_Exception_Occurrence and the
--  regression test for exception occurrence identifiers distinct from
--  exception-handler choices.

--  Pass 402 guard: keep Binding_Iteration_Filter and
--  Test_Language_Model_Executable_Iterator_Filter_Bindings so Ada filtered
--  loops retain filter-expression metadata distinct from iteration sources and
--  range bounds.
--  Pass 403 guard note: keep Binding_Select_Abort and select abort coverage
--  in Test_Language_Model_Executable_Select_Bindings.

--  Pass 404 guard: keep Binding_Entry_Family_Index and
--  Test_Language_Model_Executable_Entry_Family_Index_Bindings so
--  entry-family calls do not regress to array-index metadata.

--  Pass 407 release guard tokens: Parse_Discrete_Choice_List Test_Language_Model_Token_Cursor_Discrete_Choice_Grammar_Completeness case expression choice lists range choices others alternatives

--  Pass 408 release guard tokens: Is_Statement_Starter_After_Label Test_Language_Model_Token_Cursor_Statement_Identifier_Grammar_Completeness Named_Loop Named_Block Named_If ordinary object declarations with identifier subtypes

--  Case 409 guard marker: Production_Iterator_Specification must remain covered
--  by Test_Language_Model_Token_Cursor_Iterator_Loop_Grammar_Completeness so
--  generalized Ada iterator loops do not regress to representation-clause skips.

--  Case 410 release guard tokens: quantified expression loop schemes must keep
--  Test_Language_Model_Token_Cursor_Quantified_Expression_Grammar_Completeness
--  and retain Production_Quantified_Expression together with
--  Production_Loop_Parameter_Specification / Production_Iterator_Specification.

--  Case 411 release guard tokens: Ada 2022 declare expressions must retain
--  Test_Language_Model_Token_Cursor_Declare_Expression_Grammar_Completeness
--  and Production_Declare_Expression so declaration-containing expression
--  primaries do not regress to opaque parenthesized aggregates or blocks.


--  Case 412 release guard tokens: task/protected type headers must retain
--  Test_Language_Model_Token_Cursor_Task_Protected_Type_Header_Grammar_Completeness
--  together with Production_Task_Type_Declaration and
--  Production_Protected_Type_Declaration so discriminated concurrent type
--  declarations do not regress to opaque single-task/protected headers.

--  Case 413 release guard tokens: aggregate iterated component associations
--  must keep Test_Language_Model_Token_Cursor_Aggregate_Iterator_Grammar_Completeness
--  and Production_Iterated_Component_Association so ``(for I in ... => ...)``
--  and ``(for Element of ... => ...)`` aggregates do not regress to
--  Production_Quantified_Expression.

--  Case 414 guard: unconstrained array index subtype definitions such as
--  ``array (Positive range <>) of T`` must remain distinguished from ordinary
--  constrained index constraints by Production_Index_Subtype_Definition and
--  Test_Language_Model_Token_Cursor_Array_Index_Subtype_Grammar_Completeness.

--  Case 415 guard: Ada null exclusions before access definitions and
--  anonymous access subtypes, such as "not null access all T" and formal
--  "not null access procedure", must retain Production_Null_Exclusion and
--  Test_Language_Model_Token_Cursor_Null_Exclusion_Access_Grammar_Completeness.


--  Case 416 guard: Ada membership choices must retain range grammar for
--  explicit ranges and subtype ranges, including "Value in 1 .. 10" and
--  "Natural range 20 .. 30", through Production_Membership_Choice,
--  Production_Range_Expression, and
--  Test_Language_Model_Token_Cursor_Membership_Range_Grammar_Completeness.

--  Case 417 grammar guard: Ada 2022 target-name expressions such as
--  "Value := @ + Next;" must remain represented by Production_Target_Name
--  and Test_Language_Model_Token_Cursor_Target_Name_Grammar_Completeness.

--  Case 418 grammar guard: profile items must stay structurally parsed.
--  Test_Language_Model_Token_Cursor_Profile_Item_Grammar_Completeness covers
--  aliased parameters, in/out modes, null-exclusion anonymous access profile
--  items, discriminant defaults, and Production_Default_Expression.


--  Case 419 grammar guard: modified type definitions must stay structural.
--  Test_Language_Model_Token_Cursor_Type_Modifier_Grammar_Completeness and
--  Production_Type_Modifier cover Ada forms such as "abstract tagged limited
--  record", "tagged private", "synchronized interface", and abstract
--  derived private extensions without falling through subtype recovery.


--  Case 420 grammar guard: delay statements must keep Ada's two grammar
--  alternatives distinct.  Test_Language_Model_Token_Cursor_Delay_Statement_Grammar_Completeness
--  and the Production_Delay_Until_Statement / Production_Delay_Relative_Statement
--  markers cover both ``delay until`` and relative ``delay`` statements.

--  Case 421 guard: extended return statement grammar must retain the
--  return-object declaration, optional aliased/constant markers, subtype
--  indication, and initializer via Production_Return_Object_Declaration,
--  Production_Extended_Return_Initializer, and
--  Test_Language_Model_Token_Cursor_Extended_Return_Grammar_Completeness.

--  Case 422 guard: requeue statement grammar must retain structured entry-name
--  targets and the optional with-abort marker via Production_Requeue_Target,
--  Production_Requeue_With_Abort, and
--  Test_Language_Model_Token_Cursor_Requeue_Grammar_Completeness.

--  Case 423 guard: abort statement grammar must retain task-name target lists
--  structurally via Production_Abort_Target and
--  Test_Language_Model_Token_Cursor_Abort_Statement_Grammar_Completeness;
--  abort Worker, Pool.Tasks (Index), Controller.Current.all; must not regress
--  to opaque semicolon skipping.

--  Case 424 guard: exception-handler grammar must retain optional choice
--  parameters and exception choice lists via Production_Exception_Choice_Parameter,
--  Production_Exception_Choice_List, Production_Exception_Choice, and
--  Test_Language_Model_Token_Cursor_Exception_Handler_Grammar_Completeness;
--  when Failure : Constraint_Error | Program_Error => must not regress to
--  opaque alternative parsing.

--  case 425 guard: raise statements must not regress to opaque
--  semicolon skipping.  The token-cursor grammar is expected to retain bare
--  reraises via Production_Reraise_Statement and message raises via
--  Production_Raise_With_Message, with AUnit coverage for both forms.

--  case 426 guard: transfer statements must not regress to opaque
--  semicolon skipping.  Exit statements retain optional loop-name targets via
--  Production_Exit_Target and optional when conditions via
--  Production_Exit_When_Condition; goto statements retain Production_Goto_Target
--  with Test_Language_Model_Token_Cursor_Exit_Goto_Grammar_Completeness.


--  case 427 guard: select alternatives must not regress to generic
--  case/discrete-choice handling.  The token-cursor grammar retains guarded
--  alternatives via Production_Select_Guard, conditional else alternatives via
--  Production_Select_Else_Part, terminate alternatives via
--  Production_Terminate_Alternative, and asynchronous then-abort parts via
--  Production_Abortable_Part with
--  Test_Language_Model_Token_Cursor_Select_Alternative_Grammar_Completeness.

--  case 428 guard: attribute references with argument parts must not
--  regress to ordinary indexed-component suffixes.  The token-cursor grammar
--  retains Production_Attribute_Reference together with
--  Production_Attribute_Argument_Part for forms such as Values'First (1),
--  Integer'Image (Value), and Values'Reduce ("+", 0), with
--  Test_Language_Model_Token_Cursor_Attribute_Argument_Grammar_Completeness.

--  Pass 429 parser-completeness guard: Ada box expressions are retained as
--  Production_Box_Expression for forms such as (others => <>) and generic
--  actual associations Element => <>, guarded by
--  Test_Language_Model_Token_Cursor_Box_Expression_Grammar_Completeness.

--  Pass 430 parser-completeness guard: incomplete type declarations must not
--  regress to opaque semicolon recovery.  The token-cursor grammar retains
--  Production_Incomplete_Type_Declaration for plain incomplete declarations
--  and Production_Tagged_Incomplete_Type_Declaration for forms such as
--  type Root is tagged;, guarded by
--  Test_Language_Model_Token_Cursor_Incomplete_Type_Grammar_Completeness.


--  Pass 431 parser-completeness guard: object declarations with Ada object
--  qualifiers must not regress to subtype parsing that treats ``aliased`` as
--  a subtype mark.  The token-cursor grammar retains
--  Production_Object_Qualifier plus Production_Aliased_Part for forms such as
--  Obj : aliased constant T := ... and Handle : aliased not null access T,
--  guarded by Test_Language_Model_Token_Cursor_Object_Qualifier_Grammar_Completeness.


--  Pass 432 parser-completeness guard: Ada unknown discriminant parts must
--  not regress to malformed discriminant-specification recovery.  The
--  token-cursor grammar retains Production_Unknown_Discriminant_Part for
--  forms such as type T (<>) is private; and type Deferred (<>);,
--  guarded by Test_Language_Model_Token_Cursor_Unknown_Discriminant_Grammar_Completeness.


--  Pass 433 parser-completeness guard: numeric subtype indications must not
--  regress to opaque expression recovery after the subtype mark.  The
--  token-cursor grammar retains Production_Digits_Constraint and
--  Production_Delta_Constraint for forms such as subtype Short is Float
--  digits 6 range ... and subtype Small is Money delta 0.01 digits 8 range
--  ..., guarded by Test_Language_Model_Token_Cursor_Subtype_Constraint_Grammar_Completeness.


--  Pass 434 parser-completeness guard: record component definitions must not
--  regress to opaque semicolon skipping.  The token-cursor grammar retains
--  Production_Component_Definition with defining-name lists, aliased parts,
--  not-null access definitions, subtype indications, and default expressions,
--  guarded by Test_Language_Model_Token_Cursor_Component_Definition_Grammar_Completeness.


--  Pass 444 parser-completeness guard: named discriminant constraints and
--  selector-name lists must remain structurally parsed through
--  Production_Discriminant_Constraint, Production_Discriminant_Association,
--  and Production_Discriminant_Selector_Name with
--  Test_Language_Model_Token_Cursor_Discriminant_Constraint_Grammar_Completeness.
--  Do not collapse Bounds (Low | High => 1) back into generic
--  expression, index-constraint, or association-list recovery.


--  Pass 436 parser-completeness guard: aspect specifications must retain
--  aspect marks explicitly through Production_Aspect_Mark and class-wide
--  marks such as Type_Invariant'Class through
--  Production_Classwide_Aspect_Mark.  Do not collapse aspect marks back into
--  ordinary expression/attribute-reference recovery or require nullary aspects
--  such as Preelaborate to have synthetic values.


--  Pass 437 parser-completeness guard: record representation clauses must
--  retain optional mod clauses explicitly through Production_Mod_Clause.
--  Do not collapse `at mod <expression>;` back into opaque record
--  representation skipping, and do not let it suppress following
--  representation component clauses.


--  Pass 438 parser-completeness guard: generic formal object declarations
--  must retain modes and defaults explicitly through
--  Production_Formal_Object_Mode and Production_Formal_Object_Default.
--  Do not collapse `X : in out T := <>;` or default expressions back into
--  opaque generic-formal semicolon skipping.


--  Pass 439 parser-completeness guard: generic formal subprogram defaults
--  must retain their concrete default alternatives explicitly through
--  Production_Formal_Subprogram_Default_Box,
--  Production_Formal_Subprogram_Default_Null,
--  Production_Formal_Subprogram_Default_Abstract, and
--  Production_Formal_Subprogram_Default_Name.  Do not collapse
--  `is <>`, `is null`, `is abstract`, or `is Some.Name` back into
--  opaque semicolon skipping.


--  Pass 440 parser-completeness guard: generic actual associations must
--  retain named formal selectors and box actual defaults explicitly through
--  Production_Generic_Actual_Formal_Selector and Production_Generic_Actual_Box.
--  Do not flatten `Formal => Actual` or `Formal => <>` back into generic
--  expression-only actual parsing.


--  Pass 441 parser-completeness guard: pragma argument associations must
--  retain optional pragma_argument_identifier selectors explicitly through
--  Production_Pragma_Argument_Identifier.  Do not parse `Identifier => Value`
--  as a standalone expression followed by a late arrow recovery path.


--  Pass 442 parser-completeness guard: aggregate component associations must
--  retain choice lists explicitly through Production_Component_Association,
--  Production_Discrete_Choice_List, and Production_Discrete_Choice.  Do not
--  flatten `A | B => X`, `1 .. 10 => X`, or `others => <>` back into
--  expression-only aggregate parsing.

--  Case 946 guard: selected-name resolution foundation must remain parser-owned,
--  deterministic, snapshot-derived, and free of renderer-side parsing, file
--  reloads, dirty-state mutation, compiler invocation, LSP integration, external
--  parser generators, Python, and shell-script project hooks.

--  Case 947 guard: use-type primitive visibility foundation is covered by
--  Editor.Ada_Use_Type_Operators and
--  Test_Ada_Use_Type_Operator_Visibility_Foundation_Case 947.  This remains
--  snapshot-owned compiler-grade semantic metadata, not full overload/type
--  legality.

--  Case 948 guard: call-candidate overload foundation is covered by
--  Editor.Ada_Call_Candidates and
--  Test_Ada_Call_Candidate_Foundation_Case 948.  This remains a deterministic
--  compiler-grade semantic building block before expected-type/profile
--  filtering; it must not introduce compiler invocation, LSP, renderer-side
--  parsing, file IO, background scans, or dirty-state mutation.
