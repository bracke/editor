with Editor.Command_Ids; use Editor.Command_Ids;
package Editor.Commands.Stable_Names is

   function Stable_Command_Name
     (Id : Command_Id) return String;

   function Has_Stable_Name
     (Id : Command_Id) return Boolean;

end Editor.Commands.Stable_Names;
