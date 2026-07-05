package Editor.Commands.Availability_Metadata is

   function Available return Command_Availability;
   function Is_Available
     (Availability : Command_Availability) return Boolean;

end Editor.Commands.Availability_Metadata;
