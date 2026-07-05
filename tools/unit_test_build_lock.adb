with Ada.Directories;

package body Unit_Test_Build_Lock is
   Path : constant String := "/tmp/editor_unit_tests_build.lock";
   Is_Held : Boolean := False;

   function Lock_Path return String is
   begin
      return Path;
   end Lock_Path;

   function Held return Boolean is
   begin
      return Is_Held;
   end Held;

   function Acquire (Max_Attempts : Positive := 300) return Boolean is
   begin
      for Attempt in 1 .. Max_Attempts loop
         begin
            Ada.Directories.Create_Directory (Path);
            Is_Held := True;
            return True;
         exception
            when Ada.Directories.Use_Error | Ada.Directories.Name_Error =>
               if Attempt = Max_Attempts then
                  return False;
               end if;
               delay 1.0;
         end;
      end loop;
      return False;
   end Acquire;

   procedure Release is
   begin
      if Is_Held then
         begin
            Ada.Directories.Delete_Directory (Path);
         exception
            when others =>
               null;
         end;
         Is_Held := False;
      end if;
   end Release;
end Unit_Test_Build_Lock;
