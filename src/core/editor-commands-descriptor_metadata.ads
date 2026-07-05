package Editor.Commands.Descriptor_Metadata is

   function Make_Command_Descriptor
     (Id             : Command_Id;
      Stable_Name    : String;
      Label          : String;
      Description    : String;
      Category       : Command_Category;
      Visible        : Boolean;
      Bindable       : Boolean;
      Destructive    : Boolean := False;
      Lifecycle      : Boolean := False;
      Configuration  : Boolean := False)
      return Command_Descriptor;

   function Descriptor
     (Id : Command_Id) return Command_Descriptor;

end Editor.Commands.Descriptor_Metadata;
