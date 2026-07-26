with Editor.Commands.Descriptors;

package Editor.Command_Palette.Guikit_Model is

   function Search_Descriptors
     (Descriptors       : Editor.Commands.Descriptors.Command_Descriptor_Vectors.Vector;
      Query             : String;
      Show_Keybindings  : Boolean)
      return Editor.Commands.Descriptors.Command_Descriptor_Vectors.Vector;

end Editor.Command_Palette.Guikit_Model;
