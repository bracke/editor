with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Commands.Availability_Metadata is

   function Available return Command_Availability is
   begin
      return (Status => Command_Available, Reason => Null_Unbounded_String);
   end Available;

   function Is_Available
     (Availability : Command_Availability) return Boolean
   is
   begin
      return Availability.Status = Command_Available;
   end Is_Available;

end Editor.Commands.Availability_Metadata;
