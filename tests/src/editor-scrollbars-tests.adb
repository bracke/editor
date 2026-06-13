with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Interfaces.C;
with Editor.Commands;
with Editor.Input_Bridge;
with Editor.Layout;
with Editor.Minimap;
with Editor.Render_Layers;
with Editor.Render_Packet;
with Editor.State;
with Editor.View;

package body Editor.Scrollbars.Tests is

   use type Interfaces.C.int;

   overriding function Name
     (T : Scrollbars_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Scrollbars");
   end Name;

   function Rect_Count_On_Layer
     (Packet : Editor.Render_Packet.Render_Packet;
      Layer  : Editor.Render_Layers.Render_Layer) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 0 .. Natural (Packet.Rect_Count) - 1 loop
         if Packet.Rects (Natural (I)).Layer = Editor.Render_Layers.To_C (Layer) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Rect_Count_On_Layer;

   procedure Prepare_Lines
     (Count : Positive)
   is
      S    : Editor.State.State_Type;
      Text : Unbounded_String := Null_Unbounded_String;
   begin
      Editor.State.Init (S);
      for I in 1 .. Count loop
         Append (Text, "line");
         if I < Count then
            Append (Text, ASCII.LF);
         end if;
      end loop;
      Editor.State.Load_Text (S, To_String (Text));
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (800, 120);
      Editor.Scrollbars.Reset;
   end Prepare_Lines;

   function Vertical_Geometry_For_Current_View
     return Editor.Scrollbars.Scrollbar_Geometry
   is
      Layout        : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Config        : constant Editor.Scrollbars.Scrollbar_Config := Editor.Scrollbars.Current;
      Effective_H   : constant Natural :=
        Editor.Scrollbars.Effective_Viewport_Height
          (Editor.View.Viewport_Height, Config);
      Viewport_Rows : constant Natural :=
        Editor.Layout.Visible_Row_Count (Layout, Effective_H);
   begin
      return Editor.Scrollbars.Vertical_Geometry
        (Layout          => Layout,
         Viewport_Width  => Editor.View.Viewport_Width,
         Viewport_Height => Editor.View.Viewport_Height,
         Total_Rows      => 100,
         Visible_Rows    => Viewport_Rows,
         Scroll_Y        => Editor.View.Scroll_Y,
         Config          => Config);
   end Vertical_Geometry_For_Current_View;

   procedure Test_Vertical_Scrollbar_Emits_Rects
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Prepare_Lines (100);
      Editor.Input_Bridge.Build_Render_Packet (Packet);
      Assert
        (Rect_Count_On_Layer (Packet, Editor.Render_Layers.Scrollbar_Track_Layer) > 0,
         "Scrollable document must emit scrollbar track rects");
      Assert
        (Rect_Count_On_Layer (Packet, Editor.Render_Layers.Scrollbar_Thumb_Layer) > 0,
         "Scrollable document must emit scrollbar thumb rects");
   end Test_Vertical_Scrollbar_Emits_Rects;

   procedure Test_Disabled_Scrollbars_Emit_No_Rects
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Config : Editor.Scrollbars.Scrollbar_Config := Editor.Scrollbars.Current;
      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Prepare_Lines (100);
      Config.Enabled := False;
      Editor.Scrollbars.Set_Current (Config);
      Editor.Input_Bridge.Build_Render_Packet (Packet);
      Assert
        (Rect_Count_On_Layer (Packet, Editor.Render_Layers.Scrollbar_Track_Layer) = 0,
         "Disabled scrollbars must emit no track rects");
      Assert
        (Rect_Count_On_Layer (Packet, Editor.Render_Layers.Scrollbar_Thumb_Layer) = 0,
         "Disabled scrollbars must emit no thumb rects");
   end Test_Disabled_Scrollbars_Emit_No_Rects;

   procedure Test_Thumb_Size_Respects_Minimum
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Config : Editor.Scrollbars.Scrollbar_Config := Editor.Scrollbars.Current;
      Geometry : Editor.Scrollbars.Scrollbar_Geometry;
   begin
      Config.Min_Thumb_Size := 40;
      Geometry := Editor.Scrollbars.Vertical_Geometry
        (Layout          => Layout,
         Viewport_Width  => 800,
         Viewport_Height => 120,
         Total_Rows      => 1000,
         Visible_Rows    => 1,
         Scroll_Y        => 0,
         Config          => Config);
      Assert (Geometry.Visible, "Large document must produce visible geometry");
      Assert
        (Geometry.Thumb.H >= 40.0,
         "Scrollbar thumb height must respect configured minimum");
   end Test_Thumb_Size_Respects_Minimum;

   procedure Test_Thumb_Position_Clamps_Top_And_Bottom
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Config : constant Editor.Scrollbars.Scrollbar_Config := Editor.Scrollbars.Current;
      Top    : Editor.Scrollbars.Scrollbar_Geometry;
      Bottom : Editor.Scrollbars.Scrollbar_Geometry;
   begin
      Top := Editor.Scrollbars.Vertical_Geometry
        (Layout, 800, 120, 100, 10, 0, Config);
      Bottom := Editor.Scrollbars.Vertical_Geometry
        (Layout, 800, 120, 100, 10, 90, Config);
      Assert (Top.Visible and then Bottom.Visible,
              "Top and bottom scrollbar geometry must be visible");
      Assert (Top.Thumb.Y = Top.Track.Y,
              "Top scroll must place thumb at track top");
      Assert
        (Bottom.Thumb.Y + Bottom.Thumb.H <= Bottom.Track.Y + Bottom.Track.H,
         "Bottom scroll must clamp thumb inside track bottom");
   end Test_Thumb_Position_Clamps_Top_And_Bottom;

   procedure Test_Scrollbar_Layers_Are_Above_Content
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Render_Layers.Order (Editor.Render_Layers.Scrollbar_Track_Layer)
         > Editor.Render_Layers.Order (Editor.Render_Layers.Minimap_Viewport_Layer),
         "Scrollbar track layer must draw above minimap viewport");
      Assert
        (Editor.Render_Layers.Order (Editor.Render_Layers.Scrollbar_Thumb_Layer)
         > Editor.Render_Layers.Order (Editor.Render_Layers.Scrollbar_Track_Layer),
         "Scrollbar thumb layer must draw above scrollbar track");
      Assert
        (Editor.Render_Layers.Order (Editor.Render_Layers.Scrollbar_Thumb_Layer)
         < Editor.Render_Layers.Order (Editor.Render_Layers.Palette_Background_Layer),
         "Palette must remain above scrollbars");
   end Test_Scrollbar_Layers_Are_Above_Content;

   procedure Test_Scrollbar_Drag_Updates_Scroll_Y
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Geometry : Editor.Scrollbars.Scrollbar_Geometry;
      Cmd      : Editor.Commands.Command;
   begin
      Prepare_Lines (100);
      Geometry := Vertical_Geometry_For_Current_View;
      Assert (Geometry.Visible, "Vertical scrollbar must be visible before drag test");

      Cmd.Kind := Editor.Commands.Move_To_Point;
      Cmd.Click_X := Natural (Geometry.Thumb.X + 1.0);
      Cmd.Click_Y := Natural (Geometry.Thumb.Y + 1.0);
      Editor.Input_Bridge.Handle (Cmd);

      Cmd.Kind := Editor.Commands.Drag_To_Point;
      Cmd.Click_X := Natural (Geometry.Thumb.X + 1.0);
      Cmd.Click_Y := Natural (Geometry.Track.Y + Geometry.Track.H - 2.0);
      Editor.Input_Bridge.Handle (Cmd);

      Assert (Editor.View.Scroll_Y > 0,
              "Dragging vertical scrollbar thumb downward must increase Scroll_Y");
   end Test_Scrollbar_Drag_Updates_Scroll_Y;

   procedure Test_Scrollbar_Track_Click_Page_Scrolls
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Geometry : Editor.Scrollbars.Scrollbar_Geometry;
      Cmd      : Editor.Commands.Command;
   begin
      Prepare_Lines (100);
      Geometry := Vertical_Geometry_For_Current_View;
      Assert (Geometry.Visible, "Vertical scrollbar must be visible before track-click test");

      Cmd.Kind := Editor.Commands.Move_To_Point;
      Cmd.Click_X := Natural (Geometry.Track.X + 1.0);
      Cmd.Click_Y := Natural (Geometry.Thumb.Y + Geometry.Thumb.H + 2.0);
      Editor.Input_Bridge.Handle (Cmd);

      Assert (Editor.View.Scroll_Y > 0,
              "Clicking vertical track below thumb must page-scroll downward");
   end Test_Scrollbar_Track_Click_Page_Scrolls;

   procedure Test_Text_Viewport_Excludes_Scrollbar_Thickness
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Layout   : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Config   : constant Editor.Scrollbars.Scrollbar_Config := Editor.Scrollbars.Current;
      Full_W   : constant Natural :=
        Editor.Layout.Text_Viewport_Width (Layout, 100, 800);
      Reduced_W : constant Natural :=
        Editor.Layout.Text_Viewport_Width
          (Layout,
           100,
           Editor.Scrollbars.Effective_Viewport_Width (800, Config));
   begin
      Assert
        (Reduced_W + Config.Thickness = Full_W,
         "Scrollbar-aware text viewport must exclude vertical scrollbar thickness");
   end Test_Text_Viewport_Excludes_Scrollbar_Thickness;

   procedure Test_Minimap_Does_Not_Overlap_Vertical_Scrollbar
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Layout     : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Bars       : constant Editor.Scrollbars.Scrollbar_Config := Editor.Scrollbars.Current;
      Minimap    : constant Editor.Minimap.Minimap_Config := Editor.Minimap.Current;
      Effective_W : constant Natural :=
        Editor.Scrollbars.Effective_Viewport_Width (800, Bars);
      Right      : constant Float :=
        Editor.Minimap.Right_X (Layout, Effective_W, Minimap);
   begin
      Assert
        (Right <= Float (Layout.Origin_X + 800 - Bars.Thickness),
         "Minimap right edge must not overlap reserved vertical scrollbar area");
   end Test_Minimap_Does_Not_Overlap_Vertical_Scrollbar;

   overriding procedure Register_Tests
     (T : in out Scrollbars_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Vertical_Scrollbar_Emits_Rects'Access,
         "Vertical Scrollbar Emits Rects");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Disabled_Scrollbars_Emit_No_Rects'Access,
         "Disabled Scrollbars Emit No Rects");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Thumb_Size_Respects_Minimum'Access,
         "Thumb Size Respects Minimum");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Thumb_Position_Clamps_Top_And_Bottom'Access,
         "Thumb Position Clamps Top And Bottom");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Scrollbar_Layers_Are_Above_Content'Access,
         "Scrollbar Layers Are Above Content");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Scrollbar_Drag_Updates_Scroll_Y'Access,
         "Scrollbar Drag Updates Scroll Y");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Scrollbar_Track_Click_Page_Scrolls'Access,
         "Scrollbar Track Click Page Scrolls");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Text_Viewport_Excludes_Scrollbar_Thickness'Access,
         "Text Viewport Excludes Scrollbar Thickness");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Minimap_Does_Not_Overlap_Vertical_Scrollbar'Access,
         "Minimap Does Not Overlap Vertical Scrollbar");
   end Register_Tests;

end Editor.Scrollbars.Tests;
