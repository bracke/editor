with Interfaces.C;
with Editor.Render_Layers; use Editor.Render_Layers;

package Editor.Render_Packet is

   subtype C_Float is Interfaces.C.C_float;
   subtype C_Int   is Interfaces.C.int;

   Max_Rectangles : constant := 8192;
   Max_Glyphs     : constant := 8192;

   type Rect_Command is record
      Layer : Interfaces.C.int;
      X : C_Float := 0.0;
      Y : C_Float := 0.0;
      W : C_Float := 0.0;
      H : C_Float := 0.0;
      R : C_Float := 0.0;
      G : C_Float := 0.0;
      B : C_Float := 0.0;
   end record;
   pragma Convention (C_Pass_By_Copy, Rect_Command);

   type Glyph_Command is record
      Layer : Interfaces.C.int;
      X  : C_Float := 0.0;
      Y  : C_Float := 0.0;
      W  : C_Float := 0.0;
      H  : C_Float := 0.0;
      U0 : C_Float := 0.0;
      V0 : C_Float := 0.0;
      U1 : C_Float := 0.0;
      V1 : C_Float := 0.0;
      R  : C_Float := 0.0;
      G  : C_Float := 0.0;
      B  : C_Float := 0.0;
   end record;
   pragma Convention (C_Pass_By_Copy, Glyph_Command);

   type Rect_Array is array (0 .. Max_Rectangles - 1) of Rect_Command;
   pragma Convention (C, Rect_Array);

   type Glyph_Array is array (0 .. Max_Glyphs - 1) of Glyph_Command;
   pragma Convention (C, Glyph_Array);

   type Render_Packet is record
      Rect_Count  : C_Int := 0;
      Glyph_Count : C_Int := 0;
      Rects       : Rect_Array;
      Glyphs      : Glyph_Array;
   end record;
   pragma Convention (C_Pass_By_Copy, Render_Packet);

   --  Phase 577 buffer metadata render-boundary contract.  The render packet
   --  may display already-computed buffer metadata snapshots, but it must not
   --  use rendering as a lifecycle/mutation boundary.  This audit is a static
   --  contract surface for configuration tests: it is intentionally independent
   --  of live editor state and does not build a packet, execute commands, or
   --  inspect the filesystem.
   type Buffer_Metadata_Render_Boundary_Audit is record
      Uses_Metadata_Snapshots_Only        : Boolean := True;
      Does_Not_Switch_Buffers            : Boolean := True;
      Does_Not_Close_Buffers             : Boolean := True;
      Does_Not_Save_Reload_Revert        : Boolean := True;
      Does_Not_Probe_Filesystem          : Boolean := True;
      Does_Not_Classify_By_Mutation      : Boolean := True;
      Does_Not_Expose_Runtime_Buffer_Ids : Boolean := True;
      Buffer_List_Metadata_Projection_Only : Boolean := True;
      Active_Buffer_Metadata_Projection_Only : Boolean := True;
      Side_Effect_Free                   : Boolean := True;
      Boundary_Safe                      : Boolean := True;
   end record;

   function Audit_Buffer_Metadata_Render_Boundary
     return Buffer_Metadata_Render_Boundary_Audit;

   function Assert_Buffer_Metadata_Render_Boundary_Safe return Boolean;

   --  Internal render-packet builder.
   --  Runtime-facing code must call Editor.Input_Bridge.Build_Render_Packet
   --  instead, so initialization and active-instance checks are enforced.
   procedure Build_Render_Packet
     (Out_Packet : out Render_Packet);

end Editor.Render_Packet;