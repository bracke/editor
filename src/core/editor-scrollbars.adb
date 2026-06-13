package body Editor.Scrollbars is

   Current_Config_Value : Scrollbar_Config :=
     (Enabled        => True,
      Thickness      => 12,
      Min_Thumb_Size => 24);

   function Current return Scrollbar_Config is
   begin
      return Current_Config_Value;
   end Current;

   procedure Set_Current
     (Config : Scrollbar_Config)
   is
   begin
      Current_Config_Value := Config;
   end Set_Current;

   procedure Reset is
   begin
      Current_Config_Value :=
        (Enabled        => True,
         Thickness      => 12,
         Min_Thumb_Size => 24);
   end Reset;

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

   function Reserved_Right
     (Config : Scrollbar_Config) return Natural
   is
   begin
      if Config.Enabled then
         return Config.Thickness;
      else
         return 0;
      end if;
   end Reserved_Right;

   function Reserved_Bottom
     (Config : Scrollbar_Config) return Natural
   is
   begin
      if Config.Enabled then
         return Config.Thickness;
      else
         return 0;
      end if;
   end Reserved_Bottom;

   function Effective_Viewport_Width
     (Viewport_Width : Natural;
      Config         : Scrollbar_Config) return Natural
   is
      Reserved : constant Natural := Reserved_Right (Config);
   begin
      if Viewport_Width <= Reserved then
         return 0;
      else
         return Viewport_Width - Reserved;
      end if;
   end Effective_Viewport_Width;

   function Effective_Viewport_Height
     (Viewport_Height : Natural;
      Config          : Scrollbar_Config) return Natural
   is
      Reserved : constant Natural := Reserved_Bottom (Config);
   begin
      if Viewport_Height <= Reserved then
         return 0;
      else
         return Viewport_Height - Reserved;
      end if;
   end Effective_Viewport_Height;

   function Clamp_Thumb_Size
     (Track_Size     : Natural;
      Visible_Amount : Natural;
      Total_Amount   : Natural;
      Config         : Scrollbar_Config) return Natural
   is
      Raw_Size : Natural := 0;
   begin
      if Track_Size = 0 or else Total_Amount = 0 then
         return 0;
      end if;

      Raw_Size := Natural'Max
        (1,
         Natural
           (Float (Track_Size)
            * Float (Visible_Amount)
            / Float (Total_Amount)));

      return Natural'Min
        (Track_Size,
         Natural'Max (Config.Min_Thumb_Size, Raw_Size));
   end Clamp_Thumb_Size;

   function Vertical_Geometry
     (Layout          : Editor.Layout.Layout_Config;
      Viewport_Width  : Natural;
      Viewport_Height : Natural;
      Total_Rows      : Natural;
      Visible_Rows    : Natural;
      Scroll_Y        : Natural;
      Config          : Scrollbar_Config) return Scrollbar_Geometry
   is
      Result      : Scrollbar_Geometry;
      Track_H     : Natural := 0;
      Thumb_H     : Natural := 0;
      Max_Scroll  : Natural := 0;
      Travel      : Natural := 0;
      Thumb_Offset : Natural := 0;
   begin
      if not Config.Enabled
        or else Viewport_Width <= Config.Thickness
        or else Viewport_Height <= Config.Thickness
        or else Visible_Rows = 0
        or else Total_Rows <= Visible_Rows
      then
         return Result;
      end if;

      Track_H := Viewport_Height - Config.Thickness;
      if Track_H = 0 then
         return Result;
      end if;

      Thumb_H := Clamp_Thumb_Size (Track_H, Visible_Rows, Total_Rows, Config);
      Max_Scroll := Total_Rows - Visible_Rows;
      Travel := Track_H - Thumb_H;

      if Max_Scroll > 0 and then Travel > 0 then
         Thumb_Offset := Natural
           (Float (Travel)
            * Float (Natural'Min (Scroll_Y, Max_Scroll))
            / Float (Max_Scroll));
      end if;

      Result.Visible := True;
      Result.Track :=
        (X => Float (Layout.Origin_X + Viewport_Width - Config.Thickness),
         Y => Float (Editor.Layout.Text_Viewport_Y (Layout)),
         W => Float (Config.Thickness),
         H => Float (Track_H));
      Result.Thumb :=
        (X => Result.Track.X,
         Y => Result.Track.Y + Float (Thumb_Offset),
         W => Result.Track.W,
         H => Float (Thumb_H));
      return Result;
   end Vertical_Geometry;

   function Horizontal_Geometry
     (Layout          : Editor.Layout.Layout_Config;
      Text_Left       : Natural;
      Text_Width      : Natural;
      Viewport_Height : Natural;
      Total_Cols      : Natural;
      Visible_Cols    : Natural;
      Scroll_X        : Natural;
      Config          : Scrollbar_Config) return Scrollbar_Geometry
   is
      Result       : Scrollbar_Geometry;
      Track_W      : Natural := 0;
      Thumb_W      : Natural := 0;
      Max_Scroll   : Natural := 0;
      Travel       : Natural := 0;
      Thumb_Offset : Natural := 0;
   begin
      if not Config.Enabled
        or else Viewport_Height <= Config.Thickness
        or else Text_Width = 0
        or else Visible_Cols = 0
        or else Total_Cols <= Visible_Cols
      then
         return Result;
      end if;

      Track_W := Text_Width;
      Thumb_W := Clamp_Thumb_Size (Track_W, Visible_Cols, Total_Cols, Config);
      Max_Scroll := Total_Cols - Visible_Cols;
      Travel := Track_W - Thumb_W;

      if Max_Scroll > 0 and then Travel > 0 then
         Thumb_Offset := Natural
           (Float (Travel)
            * Float (Natural'Min (Scroll_X, Max_Scroll))
            / Float (Max_Scroll));
      end if;

      Result.Visible := True;
      Result.Track :=
        (X => Float (Text_Left),
         Y => Float (Editor.Layout.Text_Viewport_Y (Layout) + Integer (Viewport_Height - Config.Thickness)),
         W => Float (Track_W),
         H => Float (Config.Thickness));
      Result.Thumb :=
        (X => Result.Track.X + Float (Thumb_Offset),
         Y => Result.Track.Y,
         W => Float (Thumb_W),
         H => Result.Track.H);
      return Result;
   end Horizontal_Geometry;

   function Contains
     (Rect : Scrollbar_Rect;
      X    : Natural;
      Y    : Natural) return Boolean
   is
   begin
      return Float (X) >= Rect.X
        and then Float (X) < Rect.X + Rect.W
        and then Float (Y) >= Rect.Y
        and then Float (Y) < Rect.Y + Rect.H;
   end Contains;

   function Hit_Test
     (Geometry : Scrollbar_Geometry;
      X        : Natural;
      Y        : Natural) return Scrollbar_Hit
   is
   begin
      if not Geometry.Visible then
         return No_Scrollbar_Hit;
      elsif Contains (Geometry.Thumb, X, Y) then
         return Scrollbar_Thumb_Hit;
      elsif Contains (Geometry.Track, X, Y) then
         return Scrollbar_Track_Hit;
      else
         return No_Scrollbar_Hit;
      end if;
   end Hit_Test;

   function Scroll_Y_For_Thumb_Y
     (Geometry        : Scrollbar_Geometry;
      Total_Rows      : Natural;
      Visible_Rows    : Natural;
      Desired_Thumb_Y : Natural) return Natural
   is
      Track_Top  : constant Float := Geometry.Track.Y;
      Track_H    : constant Float := Geometry.Track.H;
      Thumb_H    : constant Float := Geometry.Thumb.H;
      Max_Scroll : Natural := 0;
      Travel     : Float := 0.0;
      Offset     : Float := 0.0;
   begin
      if not Geometry.Visible or else Total_Rows <= Visible_Rows then
         return 0;
      end if;

      Max_Scroll := Total_Rows - Visible_Rows;
      Travel := Float'Max (0.0, Track_H - Thumb_H);
      if Travel <= 0.0 then
         return 0;
      end if;

      Offset := Float (Desired_Thumb_Y) - Track_Top;
      Offset := Float'Max (0.0, Float'Min (Travel, Offset));
      return Natural'Min
        (Max_Scroll,
         Natural (Offset * Float (Max_Scroll) / Travel));
   end Scroll_Y_For_Thumb_Y;

   function Scroll_X_For_Thumb_X
     (Geometry        : Scrollbar_Geometry;
      Total_Cols      : Natural;
      Visible_Cols    : Natural;
      Desired_Thumb_X : Natural) return Natural
   is
      Track_Left : constant Float := Geometry.Track.X;
      Track_W    : constant Float := Geometry.Track.W;
      Thumb_W    : constant Float := Geometry.Thumb.W;
      Max_Scroll : Natural := 0;
      Travel     : Float := 0.0;
      Offset     : Float := 0.0;
   begin
      if not Geometry.Visible or else Total_Cols <= Visible_Cols then
         return 0;
      end if;

      Max_Scroll := Total_Cols - Visible_Cols;
      Travel := Float'Max (0.0, Track_W - Thumb_W);
      if Travel <= 0.0 then
         return 0;
      end if;

      Offset := Float (Desired_Thumb_X) - Track_Left;
      Offset := Float'Max (0.0, Float'Min (Travel, Offset));
      return Natural'Min
        (Max_Scroll,
         Natural (Offset * Float (Max_Scroll) / Travel));
   end Scroll_X_For_Thumb_X;

end Editor.Scrollbars;
