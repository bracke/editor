with Editor.Events;
with Editor.State;

package Editor.Runtime is

   procedure Process_Event
     (S : in out Editor.State.State_Type;
      E : Editor.Events.Event);

end Editor.Runtime;