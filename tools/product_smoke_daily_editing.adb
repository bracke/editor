with Editor_Tool_Common; use Editor_Tool_Common;
with Unit_Test_Build_Lock;

procedure Product_Smoke_Daily_Editing is
   Tool : constant String := "product_smoke_daily_editing";
   Report : constant String := "/tmp/editor_product_smoke_report.txt";
   Status : Integer;
begin
   if not Unit_Test_Build_Lock.Acquire then
      Fail (Tool, "could not acquire product smoke lock");
   end if;
   Status := Run1 ("tools/bin/product_smoke", "daily_editing");
   Unit_Test_Build_Lock.Release;
   if Status /= 0 then
      Fail (Tool, "product smoke failed");
   end if;
   Require_File (Tool, Report);
   if not File_Contains (Report, "daily_editing_workflow=confirmed") then
      Fail (Tool, "daily editing marker missing");
   end if;
   if File_Contains (Report, "workspace_save_restore_clear=confirmed")
     or else File_Contains (Report, "quick_open_file_tree_navigation=confirmed")
     or else File_Contains (Report, "editing_save_conflict_free=confirmed")
     or else File_Contains (Report, "workspace_persistence_roundtrip=confirmed")
     or else File_Contains (Report, "dirty_lifecycle_persistence=confirmed")
     or else File_Contains (Report, "build_diagnostics_navigation=confirmed")
     or else File_Contains (Report, "render_packet_nonempty=confirmed")
   then
      Fail (Tool, "daily editing smoke must not rely on combined scenario markers");
   end if;
   Info (Tool, "daily editing smoke passed");
exception
   when others =>
      Unit_Test_Build_Lock.Release;
      raise;
end Product_Smoke_Daily_Editing;
