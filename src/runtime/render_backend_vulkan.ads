with Interfaces.C;
with System;

package Render_Backend_Vulkan is
   package C renames Interfaces.C;

   function Create (Window : System.Address) return System.Address;
   pragma Export (C, Create, "render_backend_create");

   function Begin_Frame
     (Backend : System.Address;
      Width   : C.int;
      Height  : C.int) return C.int;
   pragma Export (C, Begin_Frame, "render_backend_begin_frame");

   function Draw_Editor (Backend : System.Address) return C.int;
   pragma Export (C, Draw_Editor, "render_backend_draw_editor");

   function End_Frame (Backend : System.Address) return C.int;
   pragma Export (C, End_Frame, "render_backend_end_frame");

   procedure Request_Swapchain_Recreate (Backend : System.Address);
   pragma Export
     (C, Request_Swapchain_Recreate,
      "render_backend_request_swapchain_recreate");

   function Frame_Was_Rendered (Backend : System.Address) return C.int;
   pragma Export
     (C, Frame_Was_Rendered, "render_backend_frame_was_rendered");

   function Swapchain_Recreate_Count
     (Backend : System.Address) return C.unsigned;
   pragma Export
     (C, Swapchain_Recreate_Count,
      "render_backend_swapchain_recreate_count");

   function Font_Atlas_Upload_Count
     (Backend : System.Address) return C.unsigned;
   pragma Export
     (C, Font_Atlas_Upload_Count,
      "render_backend_font_atlas_upload_count");

   function Font_Atlas_Last_Upload_Width
     (Backend : System.Address) return C.unsigned;
   pragma Export
     (C, Font_Atlas_Last_Upload_Width,
      "render_backend_font_atlas_last_upload_width");

   function Font_Atlas_Last_Upload_Height
     (Backend : System.Address) return C.unsigned;
   pragma Export
     (C, Font_Atlas_Last_Upload_Height,
      "render_backend_font_atlas_last_upload_height");

   function Font_Atlas_Last_Upload_Nonzero_Bytes
     (Backend : System.Address) return C.unsigned;
   pragma Export
     (C, Font_Atlas_Last_Upload_Nonzero_Bytes,
      "render_backend_font_atlas_last_upload_nonzero_bytes");

   function Font_Atlas_Last_Upload_Checksum
     (Backend : System.Address) return C.unsigned;
   pragma Export
     (C, Font_Atlas_Last_Upload_Checksum,
      "render_backend_font_atlas_last_upload_checksum");

   function Font_Atlas_Dirty (Backend : System.Address) return C.int;
   pragma Export
     (C, Font_Atlas_Dirty, "render_backend_font_atlas_dirty");

   function Last_Visual_Rect_Count
     (Backend : System.Address) return C.unsigned;
   pragma Export
     (C, Last_Visual_Rect_Count,
      "render_backend_last_visual_rect_count");

   function Last_Visual_Glyph_Count
     (Backend : System.Address) return C.unsigned;
   pragma Export
     (C, Last_Visual_Glyph_Count,
      "render_backend_last_visual_glyph_count");

   function Last_Visual_Geometry_Checksum
     (Backend : System.Address) return C.unsigned;
   pragma Export
     (C, Last_Visual_Geometry_Checksum,
      "render_backend_last_visual_geometry_checksum");

   function Last_Visual_Color_Checksum
     (Backend : System.Address) return C.unsigned;
   pragma Export
     (C, Last_Visual_Color_Checksum,
      "render_backend_last_visual_color_checksum");

   function Validate_Required_Shader_Assets return C.int;
   pragma Export
     (C, Validate_Required_Shader_Assets,
      "render_backend_validate_required_shader_assets");

   procedure Destroy (Backend : System.Address);
   pragma Export (C, Destroy, "render_backend_destroy");
end Render_Backend_Vulkan;
