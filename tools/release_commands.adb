with Ada.Text_IO;
with Editor_Tool_Common; use Editor_Tool_Common;

procedure Release_Commands is
   Tool : constant String := "release_commands";

   Tool_Failed : Boolean := False;
begin
   Ada.Text_IO.Put_Line ("alr exec -- gprbuild -P tools/editor_tools.gpr");
   Ada.Text_IO.Put_Line ("tools/bin/outline_static_sanity");
   Ada.Text_IO.Put_Line ("tools/bin/ada_keyword_identifier_check");
   Ada.Text_IO.Put_Line ("tools/bin/runtime_compile_check");
   Ada.Text_IO.Put_Line ("tools/bin/runtime_link_check");
   Ada.Text_IO.Put_Line ("tools/bin/runtime_smoke");
   Ada.Text_IO.Put_Line ("tools/bin/runtime_missing_asset_check");
   Ada.Text_IO.Put_Line ("tools/bin/check_docs");
   Ada.Text_IO.Put_Line ("tools/bin/check_repo_hygiene");
   Ada.Text_IO.Put_Line ("tools/bin/shader_toolchain_manifest_check");
   Ada.Text_IO.Put_Line ("tools/bin/release_candidate_check");
   Ada.Text_IO.Put_Line ("tools/bin/strict_runtime_preflight");
   Ada.Text_IO.Put_Line ("tools/bin/shader_freshness_check");
   Ada.Text_IO.Put_Line ("tools/bin/unit_tests all");
   Ada.Text_IO.Put_Line ("tools/bin/language_validation_check");
   Ada.Text_IO.Put_Line ("tools/bin/product_smoke");
   Ada.Text_IO.Put_Line ("tools/bin/real_build_runner_smoke");
   Ada.Text_IO.Put_Line ("tools/bin/release_check");
   Ada.Text_IO.Put_Line
     ("EDITOR_REQUIRE_FINAL_RELEASE_VALIDATION=1 tools/bin/final_release_validation_check");
exception
   when Program_Error =>
      if Tool_Failed then
         null;
      else
         Unexpected_Program_Error (Tool);
      end if;
end Release_Commands;
