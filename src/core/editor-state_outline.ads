package Editor.State_Outline is

   type Outline_Cursor_Sync_State is record
      Key_Valid    : Boolean := False;
      Buffer_Token : Natural := 0;
      Line         : Natural := 0;
      Column       : Natural := 0;
   end record;

end Editor.State_Outline;
