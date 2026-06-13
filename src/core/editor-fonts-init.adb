with Textrender; use Textrender;
with Editor.Font_Config;

package body Editor.Fonts.Init is

   Initialized : Boolean := False;

   procedure Initialize is
      Status : Textrender.Status_Code;
   begin
      if Initialized then
         return;
      end if;

      Status :=
        Textrender.Load_Font
          (Path         => Editor.Font_Config.Font_Path,
           Pixel_Size   => Editor.Font_Config.Font_Size_Px,
           Cell_Width   => Editor.Font_Config.Cell_W,
           Cell_Height  => Editor.Font_Config.Cell_H,
           Atlas_Width  => Editor.Font_Config.Atlas_Width,
           Atlas_Height => Editor.Font_Config.Atlas_Height);

      pragma Assert
        (Status = Textrender.Success,
         "Failed to load editor font");

      Initialized := True;
   end Initialize;

   function Is_Initialized return Boolean is
   begin
      return Initialized;
   end Is_Initialized;

end Editor.Fonts.Init;