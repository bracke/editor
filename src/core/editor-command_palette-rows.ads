with Editor.Commands.Palette_Model;

package Editor.Command_Palette.Rows is

   function Truncate_With_Ellipsis
     (Text        : String;
      Max_Columns : Natural) return String;

   function Layout_Command_Row
     (Row_Width_Columns : Natural;
      Label_Length      : Natural;
      Secondary_Length  : Natural;
      Keybinding_Length : Natural;
      Is_Selected       : Boolean;
      Is_Available      : Boolean) return Command_Palette_Row_Layout;

   function Project_Command_Row_Layout
     (Candidate   : Editor.Commands.Palette_Model.Command_Palette_Candidate;
      Is_Selected : Boolean;
      Row_Columns : Natural) return Command_Palette_Row_Layout;

end Editor.Command_Palette.Rows;
