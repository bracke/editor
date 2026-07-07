with Ada.Text_IO;

procedure Show_Developer_Tools is
begin
   Ada.Text_IO.Put_Line ("Editor developer tools:");
   Ada.Text_IO.Put_Line ("  alr exec -- gprbuild -P tools/editor_tools.gpr");
   Ada.Text_IO.Put_Line ("  tools/bin/release_check");
   Ada.Text_IO.Put_Line ("  tools/bin/editor_workflow_gate");
   Ada.Text_IO.Put_Line ("  tools/bin/editor_workflow_gate_selftest");
   Ada.Text_IO.Put_Line ("  tools/bin/check_repo_hygiene");
   Ada.Text_IO.Put_Line ("  tools/bin/source_status");
   Ada.Text_IO.Put_Line ("  tools/bin/source_status --only tools");
   Ada.Text_IO.Put_Line ("  tools/bin/product_smoke");
   Ada.Text_IO.Put_Line ("  tools/bin/product_smoke_quick_open_file_tree");
   Ada.Text_IO.Put_Line ("  tools/bin/product_smoke_edit_save");
   Ada.Text_IO.Put_Line ("  tools/bin/product_smoke_daily_editing");
   Ada.Text_IO.Put_Line ("  tools/bin/product_smoke_workspace_session");
   Ada.Text_IO.Put_Line ("  tools/bin/product_smoke_dirty_lifecycle_persistence");
   Ada.Text_IO.Put_Line ("  tools/bin/product_smoke_build_ui_interaction");
   Ada.Text_IO.Put_Line ("  tools/bin/product_smoke_command_palette_ranking");
   Ada.Text_IO.Put_Line ("  tools/bin/product_smoke_diagnostics_problems");
   Ada.Text_IO.Put_Line ("  tools/bin/product_smoke_diagnostic_quick_fix");
   Ada.Text_IO.Put_Line ("  tools/bin/product_smoke_build_diagnostics");
   Ada.Text_IO.Put_Line ("  tools/bin/product_smoke_render_packet");
   Ada.Text_IO.Put_Line ("  tools/bin/product_smoke_focus_selftest");
   Ada.Text_IO.Put_Line ("  tools/bin/real_build_runner_smoke");
   Ada.Text_IO.Put_Line ("  tools/bin/unit_tests_lock_selftest");
   Ada.Text_IO.Put_Line ("  tools/bin/unit_tests diagnostics-problems");
   Ada.Text_IO.Put_Line ("  tools/bin/runtime_compile_check");
   Ada.Text_IO.Put_Line ("  tools/bin/runtime_link_check");
   Ada.Text_IO.Put_Line ("  tools/bin/runtime_smoke");
   Ada.Text_IO.Put_Line ("  tools/bin/strict_runtime_validation_record");
end Show_Developer_Tools;
