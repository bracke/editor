with Ada.Strings.Unbounded;

package Editor.Commands.Availability_Metadata is
   use Ada.Strings.Unbounded;

   type Command_Availability_Status is
     (Command_Available,
      Command_Unavailable);

   type Command_Availability is record
      Status : Command_Availability_Status := Command_Available;
      Reason : Unbounded_String := Null_Unbounded_String;
   end record;

   function Available return Command_Availability;
   function Unavailable
     (Reason : String) return Command_Availability;
   function Is_Available
     (Availability : Command_Availability) return Boolean;
   function Unavailable_Reason
     (Availability : Command_Availability) return String;

   function Is_Concrete_Command
     (Id : Command_Id) return Boolean;

   function Requires_Context
     (Id : Command_Id) return Boolean;

   function Has_Availability_Handler
     (Id : Command_Id) return Boolean;

end Editor.Commands.Availability_Metadata;
