with Editor.Events;
with Editor.Input;

package Editor.Input_Bridge is

   function To_Input
     (E : Editor.Events.Event)
      return Editor.Input.Input_Event;

end Editor.Input_Bridge;