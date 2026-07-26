with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands.Descriptors;

package body Editor.Commands.Display_Names is

   function Label
     (Id : Command_Id) return String
   is
   begin
      return To_String (Editor.Commands.Descriptors.Descriptor (Id).Name);
   end Label;

end Editor.Commands.Display_Names;
