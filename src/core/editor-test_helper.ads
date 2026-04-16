with Editor.Commands; use Editor.Commands;

package Editor.Test_Helper is

   function Insert (Pos : Natural; Ch : Character) return Command;
   function Delete (Pos : Natural) return Command;

   function Undo return Command;
   function Redo return Command;

   function Move_Left  (Shift : Boolean := False) return Command;
   function Move_Right (Shift : Boolean := False) return Command;

end Editor.Test_Helper;