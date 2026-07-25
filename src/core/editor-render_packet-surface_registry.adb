with Editor.Render_Cache;
with Editor.Render_Packet.Chrome_Surfaces;
with Editor.Render_Packet.Editor_Text_Surface;
with Editor.Render_Packet.Overlay_Surfaces;
with Editor.Render_Packet.Panel_Surfaces;
with Editor.Render_Packet.Render_Context;
with Editor.Settings;

package body Editor.Render_Packet.Surface_Registry is

   Last_Settings_Version : Natural := 0;

   procedure Build_Render_Packet
     (Out_Packet : out Render_Packet)
   is
      Context : Editor.Render_Packet.Render_Context.Context :=
        Editor.Render_Packet.Render_Context.Create;
   begin
      Out_Packet.Rect_Count := 0;
      Out_Packet.Glyph_Count := 0;

      if Last_Settings_Version /= Editor.Settings.Version then
         Editor.Render_Cache.Invalidate_All;
         Last_Settings_Version := Editor.Settings.Version;
      end if;

      Editor.Render_Packet.Render_Context.Refresh (Context);

      Editor.Render_Packet.Chrome_Surfaces.Render (Out_Packet, Context);
      Editor.Render_Packet.Editor_Text_Surface.Render (Out_Packet, Context);
      Editor.Render_Packet.Panel_Surfaces.Render (Out_Packet, Context);
      Editor.Render_Packet.Overlay_Surfaces.Render (Out_Packet, Context);
   end Build_Render_Packet;

end Editor.Render_Packet.Surface_Registry;
