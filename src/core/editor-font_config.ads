package Editor.Font_Config is

   --  The monospace font to render with.
   --
   --  This was one hardcoded path into /usr/share/fonts, so on macOS and Windows there
   --  was no font at all: the editor would come up unable to draw a character. It is a
   --  probe now, over the places each host actually keeps its fonts, and it returns the
   --  first that exists.
   --
   --  EDITOR_FONT_PATH overrides it, which is how a test or a packager names a font
   --  directly rather than hoping one of these is installed.
   function Font_Path return String;

   Font_Size_Px : constant Positive := 16;

   Cell_W : constant Positive := 10;
   Cell_H : constant Positive := 18;

   Atlas_Width  : constant Positive := 512;
   Atlas_Height : constant Positive := 512;

end Editor.Font_Config;
