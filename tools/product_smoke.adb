with Editor_Tool_Common; use Editor_Tool_Common;

procedure Product_Smoke is
   Tool : constant String := "product_smoke";
   Tool_Failed : Boolean := False;

   procedure Fail (Tool : String; Message : String) is
   begin
      Tool_Failed := True;
      Editor_Tool_Common.Fail (Tool, Message);
   end Fail;

   Status : Integer;
begin
   Require_File (Tool, "tests/e2e_product_smoke.gpr");
   if not Command_Exists ("gprbuild") then
      if Strict ("EDITOR_REQUIRE_PRODUCT_SMOKE") then
         Fail (Tool, "gprbuild not found");
      else
         Info (Tool, "gprbuild not found; product smoke skipped");
         return;
      end if;
   end if;
   Status := Run2 ("gprbuild", "-P", "tests/e2e_product_smoke.gpr");
   if Status /= 0 then
      Fail (Tool, "product smoke build failed");
   end if;
   Status := Run0 ("tests/bin/editor_product_smoke");
   if Status /= 0 then
      Fail (Tool, "product smoke failed");
   end if;
   Info (Tool, "product smoke passed");
exception
   when Program_Error =>
      if Tool_Failed then
         null;
      else
         Unexpected_Program_Error (Tool);
      end if;
end Product_Smoke;
