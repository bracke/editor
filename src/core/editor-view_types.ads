with Editor.Wrap;

package Editor.View_Types is

   type View_State is record
      Scroll_X        : Natural := 0;
      Scroll_Y        : Natural := 0;
      Visual_Scroll_X : Float := 0.0;
      Visual_Scroll_Y : Float := 0.0;
      User_Scroll_Y_Override : Boolean := False;
      Wrap_Mode       : Editor.Wrap.Wrap_Mode := Editor.Wrap.Wrap_None;
   end record;

end Editor.View_Types;
