package Editor.Commands.Availability_Metadata is

   function Available return Command_Availability;
   function Is_Available
     (Availability : Command_Availability) return Boolean;
   function Is_Concrete_Command
     (Id : Command_Id) return Boolean;

   function Requires_Context
     (Id : Command_Id) return Boolean;

   function Has_Availability_Handler
     (Id : Command_Id) return Boolean;

end Editor.Commands.Availability_Metadata;
