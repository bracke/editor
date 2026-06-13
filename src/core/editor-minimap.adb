package body Editor.Minimap is

   Current_Config_Value : Minimap_Config :=
     (Enabled       => True,
      Width         => 96,
      Padding_Left  => 8,
      Padding_Right => 8);

   function Current return Minimap_Config is
   begin
      return Current_Config_Value;
   end Current;

   procedure Set_Current
     (Config : Minimap_Config)
   is
   begin
      Current_Config_Value := Config;
   end Set_Current;

   procedure Set_Enabled
     (Enabled : Boolean)
   is
   begin
      Current_Config_Value.Enabled := Enabled;
   end Set_Enabled;

   function Enabled return Boolean is
   begin
      return Current_Config_Value.Enabled;
   end Enabled;

   function Reserved_Width
     (Config : Minimap_Config) return Natural
   is
   begin
      if Config.Enabled then
         return Config.Padding_Left + Config.Width + Config.Padding_Right;
      else
         return 0;
      end if;
   end Reserved_Width;

   function Left_X
     (Layout         : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Config         : Minimap_Config) return Float
   is
      Right : constant Natural :=
        Layout.Origin_X + Viewport_Width;
   begin
      if not Config.Enabled
        or else Viewport_Width <= Config.Width + Config.Padding_Right
      then
         return Float (Right);
      end if;

      return Float (Right - Config.Padding_Right - Config.Width);
   end Left_X;

   function Right_X
     (Layout         : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Config         : Minimap_Config) return Float
   is
      Right : constant Natural := Layout.Origin_X + Viewport_Width;
   begin
      if not Config.Enabled
        or else Viewport_Width <= Config.Width + Config.Padding_Right
      then
         return Float (Right);
      end if;

      return Float (Right - Config.Padding_Right);
   end Right_X;

   function Contains_Point
     (X, Y            : Natural;
      Layout          : Editor.Layout.Layout_Config;
      Viewport_Width  : Natural;
      Viewport_Height : Natural;
      Config          : Minimap_Config) return Boolean
   is
      Left   : constant Float := Left_X (Layout, Viewport_Width, Config);
      Right  : constant Float := Right_X (Layout, Viewport_Width, Config);
      Top    : constant Natural := Natural (Editor.Layout.Text_Viewport_Y (Layout));
      Bottom : constant Natural := Top + Viewport_Height;
   begin
      if not Config.Enabled
        or else Viewport_Width = 0
        or else Viewport_Height = 0
        or else Right <= Left
      then
         return False;
      end if;

      return Float (X) >= Left
        and then Float (X) < Right
        and then Y >= Top
        and then Y < Bottom;
   end Contains_Point;

   function Row_For_Y
     (Y                : Natural;
      Total_Line_Count : Natural;
      Layout           : Editor.Layout.Layout_Config;
      Viewport_Height  : Natural;
      Config           : Minimap_Config) return Natural
   is
      Safe_Line_Count : constant Natural := Natural'Max (1, Total_Line_Count);
      Rel_Y           : Natural := 0;
   begin
      if not Config.Enabled or else Viewport_Height = 0 then
         return 0;
      end if;

      declare
         Top : constant Natural := Natural (Editor.Layout.Text_Viewport_Y (Layout));
      begin
         if Y <= Top then
            Rel_Y := 0;
         elsif Y >= Top + Viewport_Height then
            Rel_Y := Viewport_Height - 1;
         else
            Rel_Y := Y - Top;
         end if;
      end;

      return Sample_Row
        (Pixel_Y        => Rel_Y,
         Line_Count     => Safe_Line_Count,
         Minimap_Height => Viewport_Height);
   end Row_For_Y;

   function Row_Y
     (Document_Row : Natural;
      Line_Count   : Natural;
      Viewport_H   : Natural) return Float
   is
      Safe_Line_Count : constant Natural := Natural'Max (1, Line_Count);
   begin
      if Viewport_H = 0 then
         return 0.0;
      end if;

      return Float (Document_Row) * Float (Viewport_H) / Float (Safe_Line_Count);
   end Row_Y;

   function Sample_Row
     (Pixel_Y        : Natural;
      Line_Count     : Natural;
      Minimap_Height : Natural) return Natural
   is
      Safe_Line_Count : constant Natural := Natural'Max (1, Line_Count);
      Row             : Natural := 0;
   begin
      if Minimap_Height = 0 then
         return 0;
      end if;

      Row := Pixel_Y * Safe_Line_Count / Minimap_Height;
      return Natural'Min (Row, Safe_Line_Count - 1);
   end Sample_Row;

   function Viewport_Marker_Y
     (Visible_First_Row : Natural;
      Line_Count        : Natural;
      Viewport_H        : Natural) return Float
   is
   begin
      return Row_Y (Visible_First_Row, Line_Count, Viewport_H);
   end Viewport_Marker_Y;

   function Viewport_Marker_Height
     (Visible_Row_Count : Natural;
      Line_Count        : Natural;
      Viewport_H        : Natural) return Float
   is
      Safe_Line_Count : constant Natural := Natural'Max (1, Line_Count);
      Raw             : Float := 0.0;
      Minimum         : constant Float :=
        (if Viewport_H >= 2 then 2.0 else Float (Viewport_H));
   begin
      if Viewport_H = 0 then
         return 0.0;
      end if;

      Raw := Float (Visible_Row_Count) * Float (Viewport_H) / Float (Safe_Line_Count);
      return Float'Min (Float (Viewport_H), Float'Max (Minimum, Raw));
   end Viewport_Marker_Height;

end Editor.Minimap;
