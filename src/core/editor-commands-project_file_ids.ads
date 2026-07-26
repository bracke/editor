with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Command_Kinds;

package Editor.Commands.Project_File_Ids is

   function Is_Project_File_Command
     (Id : Command_Id) return Boolean;

   function Is_File_Content_Save_Command
     (Id : Command_Id) return Boolean;

   function Is_Workspace_Structural_Save_Command
     (Id : Command_Id) return Boolean;

end Editor.Commands.Project_File_Ids;
