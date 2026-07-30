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
          (R            => Editor.Fonts.Backend.all,
           Path         => Editor.Font_Config.Font_Path,
           Pixel_Size   => Editor.Font_Config.Font_Size_Px,
           Cell_Width   => Editor.Font_Config.Cell_W,
           Cell_Height  => Editor.Font_Config.Cell_H,
           Atlas_Width  => Editor.Font_Config.Atlas_Width,
           Atlas_Height => Editor.Font_Config.Atlas_Height);

      pragma Assert
        (Status = Textrender.Success,
         "Failed to load editor font");

      --  Emoji last, and only if the host has one: the chain is resolved by
      --  asking each font whether it maps a codepoint and taking the first that
      --  says yes, and an emoji font maps far more than emoji.
      if Editor.Font_Config.Emoji_Font_Path /= "" then
         declare
            Fallback : constant Textrender.Status_Code :=
              Textrender.Add_Fallback_Font
                (Editor.Fonts.Backend.all, Editor.Font_Config.Emoji_Font_Path);
         begin
            --  A font that will not load is not worth failing to start over.
            pragma Unreferenced (Fallback);
         end;
      end if;

      Initialized := True;
   end Initialize;

   function Is_Initialized return Boolean is
   begin
      return Initialized;
   end Is_Initialized;

end Editor.Fonts.Init;