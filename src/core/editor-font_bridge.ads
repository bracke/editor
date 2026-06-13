with Interfaces.C;
with System;

package Editor.Font_Bridge is

   function Atlas_Width return Interfaces.C.int;
   pragma Export (C, Atlas_Width, "editor_font_atlas_width");

   function Atlas_Height return Interfaces.C.int;
   pragma Export (C, Atlas_Height, "editor_font_atlas_height");

   function Atlas_Pixels return System.Address;
   pragma Export (C, Atlas_Pixels, "editor_font_atlas_pixels");

   function Atlas_Dirty return Interfaces.C.int;
   pragma Export (C, Atlas_Dirty, "editor_font_atlas_dirty");

   procedure Clear_Atlas_Dirty;
   pragma Export (C, Clear_Atlas_Dirty, "editor_font_clear_atlas_dirty");

end Editor.Font_Bridge;