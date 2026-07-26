with Editor.Command_Ids; use Editor.Command_Ids;
package Editor.Commands.Search_Terms is

   function Command_Id_From_Stable_Name
     (Name  : String;
      Found : out Boolean) return Command_Id;

end Editor.Commands.Search_Terms;
