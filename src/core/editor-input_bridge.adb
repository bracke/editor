package body Editor.Input_Bridge is

   function To_Input
     (E : Editor.Events.Event)
      return Editor.Input.Input_Event is

      R : Editor.Input.Input_Event;
   begin

      case E.Kind is
         when Editor.Events.Key_Press =>
            R.Key := Editor.Input.Key_Char;
            R.Ch  := E.Key;
      end case;

      return R;
   end To_Input;

end Editor.Input_Bridge;