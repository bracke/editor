with Editor_Tool_Common; use Editor_Tool_Common;
with Unit_Test_Build_Lock;

procedure Product_Smoke_Command_Palette_Ranking is
   Tool : constant String := "product_smoke_command_palette_ranking";
   Report : constant String := "/tmp/editor_product_smoke_report.txt";
   Status : Integer;
begin
   if not Unit_Test_Build_Lock.Acquire then
      Fail (Tool, "could not acquire product smoke lock");
   end if;
   Status := Run1 ("tools/bin/product_smoke", "command_palette_ranking");
   Unit_Test_Build_Lock.Release;
   if Status /= 0 then
      Fail (Tool, "product smoke failed");
   end if;
   Require_File (Tool, Report);
   if not File_Contains (Report, "command_palette_ranking=confirmed") then
      Fail (Tool, "command palette ranking marker missing");
   end if;
   if not File_Contains (Report, "command_palette_execution=confirmed") then
      Fail (Tool, "command palette execution marker missing");
   end if;
   Info (Tool, "command palette ranking and execution smoke passed");
exception
   when others =>
      Unit_Test_Build_Lock.Release;
      raise;
end Product_Smoke_Command_Palette_Ranking;
