with Ada.Environment_Variables;
with Editor_Tool_Common; use Editor_Tool_Common;

procedure Strict_Runtime_Validation is
   Tool : constant String := "strict_runtime_validation";
   Tool_Failed : Boolean := False;

   procedure Fail (Tool : String; Message : String) is
   begin
      Tool_Failed := True;
      Editor_Tool_Common.Fail (Tool, Message);
   end Fail;

   Status : Integer;

   procedure Require_Step (Name, Program : String) is
   begin
      Info (Tool, "running " & Name);
      Status := Run0 (Program);
      if Status /= 0 then
         Fail (Tool, Name & " failed");
      end if;
   end Require_Step;

begin
   Ada.Environment_Variables.Set ("EDITOR_REQUIRE_RUNTIME_COMPILE", "1");
   Ada.Environment_Variables.Set ("EDITOR_REQUIRE_RUNTIME_LINK", "1");
   Ada.Environment_Variables.Set ("EDITOR_REQUIRE_RUNTIME_EXE", "1");
   Ada.Environment_Variables.Set ("EDITOR_REQUIRE_SHADER_FRESHNESS", "1");
   Ada.Environment_Variables.Set ("EDITOR_REQUIRE_SHADER_TOOLCHAIN_MANIFEST", "1");
   Ada.Environment_Variables.Set ("EDITOR_REQUIRE_RUNTIME_SMOKE", "1");
   Ada.Environment_Variables.Set ("EDITOR_REQUIRE_RUNTIME_MISSING_ASSET", "1");
   Ada.Environment_Variables.Set ("EDITOR_REQUIRE_STRICT_RUNTIME_PREFLIGHT", "1");

   Require_Step ("strict runtime preflight", "tools/bin/strict_runtime_preflight");
   Require_Step ("runtime compile check", "tools/bin/runtime_compile_check");
   Require_Step ("runtime link check", "tools/bin/runtime_link_check");
   Require_Step ("shader toolchain manifest check", "tools/bin/shader_toolchain_manifest_check");
   Require_Step ("shader freshness check", "tools/bin/shader_freshness_check");
   Require_Step ("runtime smoke", "tools/bin/runtime_smoke");
   Require_Step ("missing shader negative check", "tools/bin/runtime_missing_asset_check");
   Info (Tool, "strict runtime validation passed");
exception
   when Program_Error =>
      if Tool_Failed then
         null;
      else
         Unexpected_Program_Error (Tool);
      end if;
end Strict_Runtime_Validation;
