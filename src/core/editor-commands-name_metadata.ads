package Editor.Commands.Name_Metadata is

   function Stable_Command_Name
     (Id : Command_Id) return String;

   function Command_Id_From_Stable_Name
     (Name  : String;
      Found : out Boolean) return Command_Id;

end Editor.Commands.Name_Metadata;
