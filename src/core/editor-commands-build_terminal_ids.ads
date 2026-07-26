with Editor.Command_Kinds;
with Editor.Commands;

package Editor.Commands.Build_Terminal_Ids is

   function Is_Public_Build_Command
     (Id : Command_Id) return Boolean;

   function Is_Internal_Build_Test_Seam_Command
     (Id : Command_Id) return Boolean;

   function Is_Build_Or_Terminal_Command
     (Id : Command_Id) return Boolean;

end Editor.Commands.Build_Terminal_Ids;
