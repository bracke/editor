with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Commands;
with Editor.Executor.Command_Palette_Projection;
with Editor.Overlay_Focus;
with Editor.Render_Layers;
with Editor.Render_Packet.Guikit_Adapters;
with Editor.Theme;
with Guikit.Command_Palette;

package body Editor.Command_Palette.Surface_Rendering is

   use Editor.Render_Packet.Guikit_Adapters;
   use type Guikit.Draw.Render_Color;

   use type Editor.Commands.Command_Id;

   procedure Build_Frame
     (Palette        : Editor.Command_Palette.Palette_State;
      State          : Editor.State.State_Type;
      Config         : Editor.Command_Palette.Command_Palette_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Layout_Origin_X : Natural;
      Layout_Origin_Y : Natural;
      Status_Bar_Y   : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive;
      Visible        : out Boolean;
      Rectangles     : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text           : out Guikit.Draw.Text_Command_Vectors.Vector;
      Icons          : out Guikit.Draw.Icon_Command_Vectors.Vector;
      Accessibility  : out Guikit.Draw.Accessibility_Node_Vectors.Vector)
   is
      Guikit_Palette : Guikit.Command_Palette.Palette;
      Guikit_Config  : Guikit.Command_Palette.Configuration;
      Commands       : Guikit.Command_Palette.Command_Vectors.Vector;
      Margin : constant Natural := Editor.Theme.Palette_Margin;
      Max_W : constant Natural := Editor.Theme.Palette_Max_Width;
      Width : Natural := Max_W;
      X : Float := 0.0;
      Y : Float := 0.0;
      Height : Float := 0.0;
      Visible_Count : Natural := 0;
   begin
      Rectangles.Clear;
      Text.Clear;
      Icons.Clear;
      Accessibility.Clear;
      Visible := Palette.Open
        and then Viewport_Width > 0
        and then Viewport_Height > 0;
      if not Visible then
         return;
      end if;

      if Viewport_Width <= Margin * 2 then
         Width := Viewport_Width;
      else
         Width := Natural'Min (Max_W, Viewport_Width - Margin * 2);
      end if;

      X := Float (Layout_Origin_X + (Viewport_Width - Width) / 2);
      Y := Float (Layout_Origin_Y)
        + Float'Max
          (Editor.Theme.Palette_Top_Min_Offset,
           Float (Viewport_Height) * Editor.Theme.Palette_Top_Fraction);

      Guikit_Config :=
        (Line_Height    => Cell_H,
         Show_Icons     => False,
         Show_Shortcuts => Config.Show_Keybindings,
         Overlay        => True,
         Wrap_Selection => False,
         Placeholder    =>
           To_Unbounded_String
             (if Config.Show_Help_Row and then Length (Palette.Query) = 0
              then "Type to search commands"
              else ""),
         Empty_State    => To_Unbounded_String ("No matching commands"),
         Title          => Null_Unbounded_String);
      Editor.Executor.Command_Palette_Projection.Project_Guikit_Commands
        (State, Commands);

      Guikit.Command_Palette.Set_Configuration (Guikit_Palette, Guikit_Config);
      Guikit.Command_Palette.Set_Commands (Guikit_Palette, Commands);
      Guikit.Command_Palette.Set_Query (Guikit_Palette, To_String (Palette.Query));
      declare
         Top_Y : constant Natural := Natural'Min
           (Natural'Max (0, Natural (Y)), Status_Bar_Y);
         Available_H : constant Natural :=
           (if Status_Bar_Y > Top_Y then Status_Bar_Y - Top_Y else 0);
         Base_H : constant Natural :=
           2 * Cell_H + Editor.Theme.Palette_Outer_Padding_Y;
         Space_For_Rows : constant Natural :=
           (if Available_H > Base_H then (Available_H - Base_H) / Cell_H else 0);
      begin
         Visible_Count := Natural'Min
           (Natural'Min (Config.Max_Visible_Rows, Space_For_Rows),
            Guikit.Command_Palette.Result_Count (Guikit_Palette));
      end;

      Height := Float
        ((2 + Visible_Count) * Cell_H
         + Editor.Theme.Palette_Outer_Padding_Y);

      if Palette.Selected_Command_Id /= Editor.Commands.No_Command
        and then Guikit.Command_Palette.Result_Count (Guikit_Palette) > 0
      then
         declare
            Results : constant Guikit.Command_Palette.Command_Vectors.Vector :=
              Guikit.Command_Palette.Results (Guikit_Palette);
            Target : constant Natural :=
              Editor.Commands.Command_Id'Pos (Palette.Selected_Command_Id);
         begin
            for I in Results.First_Index .. Results.Last_Index loop
               if Results.Element (I).Id = Target then
                  if Guikit.Command_Palette.Selected_Index (Guikit_Palette) = 0 then
                     Guikit.Command_Palette.Select_First (Guikit_Palette);
                  end if;
                  if I > Guikit.Command_Palette.Selected_Index (Guikit_Palette) then
                     Guikit.Command_Palette.Move_Selection
                       (Guikit_Palette,
                        Integer (I - Guikit.Command_Palette.Selected_Index (Guikit_Palette)));
                  elsif I < Guikit.Command_Palette.Selected_Index (Guikit_Palette) then
                     Guikit.Command_Palette.Move_Selection
                       (Guikit_Palette,
                        -Integer (Guikit.Command_Palette.Selected_Index (Guikit_Palette) - I));
                  end if;
                  exit;
               end if;
            end loop;
         end;
      end if;

      Guikit.Command_Palette.Build_Frame
        (Guikit_Palette,
         Region_X      => Natural (X),
         Region_Y      => Natural (Y),
         Region_Width  => Width,
         Region_Height => Natural (Height),
         Clip_Width    => Viewport_Width,
         Clip_Height   => Viewport_Height,
         Focused       =>
           Editor.Overlay_Focus.Is_Active
             (State.Overlay_Focus, Editor.Overlay_Focus.Command_Palette_Overlay),
         Hover_X       => -1,
         Hover_Y       => -1,
         Rectangles    => Rectangles,
         Text          => Text,
         Icons         => Icons,
         Accessibility => Accessibility);
   end Build_Frame;

   procedure Build_Packet
     (Packet         : in out Editor.Render_Packet.Render_Packet;
      Palette        : Editor.Command_Palette.Palette_State;
      State          : Editor.State.State_Type;
      Config         : Editor.Command_Palette.Command_Palette_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Layout_Origin_X : Natural;
      Layout_Origin_Y : Natural;
      Status_Bar_Y   : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive)
   is
      Visible       : Boolean;
      Rectangles    : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text          : Guikit.Draw.Text_Command_Vectors.Vector;
      Icons         : Guikit.Draw.Icon_Command_Vectors.Vector;
      Accessibility : Guikit.Draw.Accessibility_Node_Vectors.Vector;
   begin
      Build_Frame
        (Palette         => Palette,
         State           => State,
         Config          => Config,
         Viewport_Width  => Viewport_Width,
         Viewport_Height => Viewport_Height,
         Layout_Origin_X => Layout_Origin_X,
         Layout_Origin_Y => Layout_Origin_Y,
         Status_Bar_Y    => Status_Bar_Y,
         Cell_W          => Cell_W,
         Cell_H          => Cell_H,
         Visible         => Visible,
         Rectangles      => Rectangles,
         Text            => Text,
         Icons           => Icons,
         Accessibility   => Accessibility);

      if Visible then
         for R of Rectangles loop
            if R.Color = Guikit.Draw.Selection_Color then
               Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Palette_Selection_Layer, R);
            else
               Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Palette_Background_Layer, R);
            end if;
         end loop;
         for T of Text loop
            Push_Guikit_Text (Packet, Editor.Render_Layers.Palette_Text_Layer, T);
         end loop;
      end if;
   end Build_Packet;

end Editor.Command_Palette.Surface_Rendering;
