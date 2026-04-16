with Ada.Containers; use Ada.Containers;
with Ada.Containers.Vectors;
with Editor.State;

package Editor.History is

   package State_Vector is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Editor.State.State_Type,
      "="          => Editor.State."=");

   Undo_Stack : State_Vector.Vector;
   Redo_Stack : State_Vector.Vector;

end Editor.History;