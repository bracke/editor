with Interfaces.C;
with Textrender;
with Editor.Fonts;

package body Editor.Font_Bridge is

   function Atlas_Width return Interfaces.C.int is
   begin
      return Interfaces.C.int (Textrender.Atlas_Width (Editor.Fonts.Backend.all));
   end Atlas_Width;

   function Atlas_Height return Interfaces.C.int is
   begin
      return Interfaces.C.int (Textrender.Atlas_Height (Editor.Fonts.Backend.all));
   end Atlas_Height;

   function Atlas_Pixels return System.Address is
   begin
      return Textrender.Atlas_Pixels (Editor.Fonts.Backend.all).all'Address;
   end Atlas_Pixels;

   function Atlas_Dirty return Interfaces.C.int is
   begin
      if Textrender.Atlas_Dirty (Editor.Fonts.Backend.all) then
         return 1;
      else
         return 0;
      end if;
   end Atlas_Dirty;

   procedure Clear_Atlas_Dirty is
   begin
      Textrender.Clear_Atlas_Dirty (Editor.Fonts.Backend.all);
   end Clear_Atlas_Dirty;

end Editor.Font_Bridge;