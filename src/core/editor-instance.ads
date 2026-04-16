with Ada.Containers.Vectors;
with Editor.Commands;
with Editor.State;

package Editor.Instance is

   package Command_Vector is
      new Ada.Containers.Vectors
        (Index_Type   => Natural,
         Element_Type => Editor.Commands.Command,
         "="          => Editor.Commands."=");

   type Editor_Instance is record
      Log      : Command_Vector.Vector;
      Position : Natural := 0;
      State    : Editor.State.State_Type;
   end record;

   procedure Init (E : in out Editor_Instance);

   procedure Execute
     (E   : in out Editor_Instance;
      Cmd : Editor.Commands.Command);

   procedure Undo (E : in out Editor_Instance);

   procedure Redo (E : in out Editor_Instance);

   procedure Rebuild (E : in out Editor_Instance);

end Editor.Instance;