with Ada.Text_IO;

procedure Show_Developer_Tools is
begin
   Ada.Text_IO.Put_Line ("Editor developer tools:");
   Ada.Text_IO.Put_Line ("  gprbuild -P tools/editor_tools.gpr");
   Ada.Text_IO.Put_Line ("  tools/bin/release_check");
   Ada.Text_IO.Put_Line ("  tools/bin/product_smoke");
   Ada.Text_IO.Put_Line ("  tools/bin/real_build_runner_smoke");
   Ada.Text_IO.Put_Line ("  tools/bin/runtime_compile_check");
   Ada.Text_IO.Put_Line ("  tools/bin/runtime_link_check");
   Ada.Text_IO.Put_Line ("  tools/bin/runtime_smoke");
   Ada.Text_IO.Put_Line ("  tools/bin/strict_runtime_validation_record");
end Show_Developer_Tools;
