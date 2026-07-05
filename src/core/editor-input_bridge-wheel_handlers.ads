with Editor.State;

package Editor.Input_Bridge.Wheel_Handlers is

   procedure Handle_Wheel
     (S       : in out Editor.State.State_Type;
      X       : Natural;
      Y       : Natural;
      Delta_X : Integer;
      Delta_Y : Integer);

end Editor.Input_Bridge.Wheel_Handlers;
