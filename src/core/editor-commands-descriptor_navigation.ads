with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Commands.Descriptors; use Editor.Commands.Descriptors;
package Editor.Commands.Descriptor_Navigation is

   function Descriptor
     (Id : Command_Id) return Command_Descriptor;

end Editor.Commands.Descriptor_Navigation;
