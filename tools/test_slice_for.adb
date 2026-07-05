with Ada.Command_Line;
with Ada.Text_IO;
with Test_Slice_Rules;

procedure Test_Slice_For is
begin
   if Ada.Command_Line.Argument_Count = 0 then
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "usage: tools/bin/test_slice_for <changed-path> [<changed-path> ...]");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      return;
   end if;

   for I in 1 .. Ada.Command_Line.Argument_Count loop
      declare
         Path : constant String := Ada.Command_Line.Argument (I);
      begin
         Ada.Text_IO.Put_Line (Path & ": " & Test_Slice_Rules.Slice_For (Path));
      end;
   end loop;
end Test_Slice_For;
