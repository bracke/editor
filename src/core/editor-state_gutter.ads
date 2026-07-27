with Editor.Dirty_Lines;
with Editor.Gutter_Markers;

package Editor.State_Gutter is

   type Gutter_Runtime_State is record
      Markers    : Editor.Gutter_Markers.Gutter_Marker_State;
      Dirty_Lines : Editor.Dirty_Lines.Dirty_Line_State;
      Marker_Hover : Editor.Gutter_Markers.Gutter_Marker_Hover_State;
   end record;

end Editor.State_Gutter;
