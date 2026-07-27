with Editor.Outline;

package Editor.State_Outline is

   type Outline_Cursor_Sync_State is record
      Key_Valid    : Boolean := False;
      Buffer_Token : Natural := 0;
      Line         : Natural := 0;
      Column       : Natural := 0;
   end record;

   type Outline_Runtime_State is record
      Outline : Editor.Outline.Outline_State;
      Cursor  : Outline_Cursor_Sync_State;
   end record;

end Editor.State_Outline;
