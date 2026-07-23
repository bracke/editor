with Editor.Commands;

package Editor.Commands.Classification is

   function Is_Navigation_Command
     (Id : Command_Id) return Boolean;

   function Is_Search_Command
     (Id : Command_Id) return Boolean;

   function Is_Panel_Focus_Command
     (Id : Command_Id) return Boolean;

   function Is_Text_Editing_Command
     (Id : Command_Id) return Boolean;

end Editor.Commands.Classification;
