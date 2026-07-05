with Ada.Command_Line;
with Ada.Directories;
with Ada.Text_IO;

with Editor_Tool_Common; use Editor_Tool_Common;
with Unit_Test_Build_Lock;

procedure Unit_Tests_Lock_Selftest is
   Tool : constant String := "unit_tests_lock_selftest";
begin
   if Ada.Command_Line.Argument_Count = 1
     and then Ada.Command_Line.Argument (1) = "--probe-lock-blocked"
   then
      if Unit_Test_Build_Lock.Acquire (1) then
         Unit_Test_Build_Lock.Release;
         Fail (Tool, "probe unexpectedly acquired a held lock");
      end if;
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
      return;
   elsif Ada.Command_Line.Argument_Count /= 0 then
      Fail (Tool, "unknown argument");
   end if;

   Unit_Test_Build_Lock.Release;

   if Ada.Directories.Exists (Unit_Test_Build_Lock.Lock_Path) then
      Ada.Directories.Delete_Directory (Unit_Test_Build_Lock.Lock_Path);
   end if;

   if not Unit_Test_Build_Lock.Acquire (1) then
      Fail (Tool, "could not acquire unit test build lock");
   end if;

   if not Unit_Test_Build_Lock.Held
     or else not Ada.Directories.Exists (Unit_Test_Build_Lock.Lock_Path)
   then
      Fail (Tool, "unit test build lock did not create held lock directory");
   end if;

   if Unit_Test_Build_Lock.Acquire (1) then
      Fail (Tool, "unit test build lock allowed reentrant acquisition");
   end if;

   if Run1 ("tools/bin/unit_tests_lock_selftest", "--probe-lock-blocked") /= 0 then
      Fail (Tool, "unit test build lock contention probe failed");
   end if;

   Unit_Test_Build_Lock.Release;

   if Unit_Test_Build_Lock.Held
     or else Ada.Directories.Exists (Unit_Test_Build_Lock.Lock_Path)
   then
      Fail (Tool, "unit test build lock did not release cleanly");
   end if;

   Info (Tool, "unit test build lock audit passed");
   Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
exception
   when Program_Error =>
      Unit_Test_Build_Lock.Release;
      null;
   when others =>
      Unit_Test_Build_Lock.Release;
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         Tool & ": unexpected failure while auditing unit_tests build lock");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
end Unit_Tests_Lock_Selftest;
