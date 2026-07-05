with Editor_Tool_Common; use Editor_Tool_Common;
with Unit_Test_Build_Lock;

procedure Product_Smoke_Build_UI_Interaction is
   Tool : constant String := "product_smoke_build_ui_interaction";
   Report : constant String := "/tmp/editor_product_smoke_report.txt";
   Status : Integer;
begin
   if not Unit_Test_Build_Lock.Acquire then
      Fail (Tool, "could not acquire product smoke lock");
   end if;
   Status := Run1 ("tools/bin/product_smoke", "build_ui_interaction");
   Unit_Test_Build_Lock.Release;
   if Status /= 0 then
      Fail (Tool, "product smoke failed");
   end if;
   Require_File (Tool, Report);
   if not File_Contains (Report, "build_ui_interaction=confirmed") then
      Fail (Tool, "build UI interaction marker missing");
   end if;
   Info (Tool, "build UI interaction smoke passed");
exception
   when others =>
      Unit_Test_Build_Lock.Release;
      raise;
end Product_Smoke_Build_UI_Interaction;
