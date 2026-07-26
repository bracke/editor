with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Commands.Search_Terms;
with Editor.Commands.Stable_Names;

package body Editor.Commands.Name_Metadata is

   function Stable_Command_Name
     (Id : Command_Id) return String
   is
   begin
      return Editor.Commands.Stable_Names.Stable_Command_Name (Id);
   end Stable_Command_Name;

   function Command_Id_From_Stable_Name
     (Name  : String;
      Found : out Boolean) return Command_Id
   is
   begin
      return Editor.Commands.Search_Terms.Command_Id_From_Stable_Name
        (Name, Found);
   end Command_Id_From_Stable_Name;


end Editor.Commands.Name_Metadata;
