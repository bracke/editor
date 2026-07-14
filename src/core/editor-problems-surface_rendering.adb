with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Diagnostics;
with Editor.Input_Bridge;
with Editor.Layout;
with Editor.Problems;
with Editor.Panels;
with Editor.Render_Layers;
with Editor.Render_Packet.Guikit_Adapters;
with Guikit.Draw;
with Guikit.List_Panel;

package body Editor.Problems.Surface_Rendering is

   use Editor.Render_Packet.Guikit_Adapters;

   procedure Push_Text
     (Texts  : in out Guikit.Draw.Text_Command_Vectors.Vector;
      Text   : String;
      X      : Float;
      Y      : Float;
      Color  : Guikit.Draw.Render_Color)
   is
   begin
      Texts.Append
        (Guikit.Draw.Text_Command'
           (X => Natural (Float'Floor (X)),
            Y => Natural (Float'Floor (Y)),
            Width => 0,
            Height => 0,
            Text => To_Unbounded_String (Text),
            Color => Color,
            others => <>));
   end Push_Text;

   function Severity_Color
     (Severity : Editor.Problems.Problem_Row_Severity)
      return Guikit.Draw.Render_Color
   is
   begin
      case Severity is
         when Editor.Problems.Problem_Error =>
            return Guikit.Draw.Error_Text_Color;
         when Editor.Problems.Problem_Warning =>
            return Guikit.Draw.Label_Orange_Color;
         when Editor.Problems.Problem_Info =>
            return Guikit.Draw.Label_Blue_Color;
         when Editor.Problems.Problem_Hint =>
            return Guikit.Draw.Label_Gray_Color;
      end case;
   end Severity_Color;

   procedure Build_Frame
     (State          : Editor.State.State_Type;
      Layout_Config  : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive;
      Visible        : out Boolean;
      Background_Rectangles : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Header_Rectangles : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Row_Rectangles : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text           : out Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility  : out Guikit.Draw.Accessibility_Node_Vectors.Vector)
   is
      Config : constant Editor.Problems.Problems_View_Config :=
        (Enabled_By_Default      => False,
         Header_Height_In_Rows   => 1,
         Row_Height_In_Rows      => 1,
         Show_Header             => True,
         Show_File_Name          => False,
         Show_Severity           => True,
         Show_Row_Column         => True,
         Maximum_Message_Columns => 120);
      Geometry : constant Editor.Layout.Rect :=
        Editor.Layout.Panel_Rect
          (Layout_Config,
           Editor.Panels.Bottom_Panel,
           Viewport_Width,
           Viewport_Height);
      Splitter : constant Editor.Layout.Rect :=
        Editor.Layout.Panel_Splitter_Rect
          (Layout_Config,
           Editor.Panels.Bottom_Panel,
           Viewport_Width,
           Viewport_Height);
      Snapshot : Editor.Problems.Problems_Snapshot;
      Capacity_Rows : Natural := 0;
      Header_Rows   : Natural := 0;
      First_Row_Y   : Float := 0.0;
      Text_Columns  : Natural := 0;
      Focused       : constant Boolean :=
        Editor.Input_Bridge.Problems_Focused_For_Render;
      View          : constant Editor.Problems.Problems_View_State :=
        Editor.Input_Bridge.Problems_View_For_Render;
      use type Editor.Problems.Problem_Row_Severity;
      use type Editor.Diagnostics.Diagnostic_Index;
   begin
      pragma Unreferenced (State);
      Background_Rectangles.Clear;
      Header_Rectangles.Clear;
      Row_Rectangles.Clear;
      Text.Clear;
      Accessibility.Clear;
      Visible := False;

      if Geometry.Width = 0 or else Geometry.Height = 0 then
         return;
      end if;

      Editor.Input_Bridge.Get_Problems_For_Render (Snapshot);
      Visible := True;

      Background_Rectangles.Append
        (Guikit.Draw.Rectangle_Command'
           (X      => Natural (Geometry.X),
            Y      => Natural (Geometry.Y),
            Width  => Geometry.Width,
            Height => Geometry.Height,
            Color  => Guikit.Draw.Pane_Color));

      if Splitter.Width > 0 and then Splitter.Height > 0 then
         Background_Rectangles.Append
           (Guikit.Draw.Rectangle_Command'
              (X      => Natural (Splitter.X),
               Y      => Natural (Splitter.Y),
               Width  => Splitter.Width,
               Height => Splitter.Height,
               Color  => Guikit.Draw.Border_Color));
      end if;

      Text_Columns :=
        (if Geometry.Width > 2 * Cell_W then (Geometry.Width / Cell_W) - 2 else 0);
      Capacity_Rows := Geometry.Height / Cell_H;
      if Capacity_Rows = 0 then
         return;
      end if;

      if Config.Show_Header then
         Header_Rows := Natural'Min (Config.Header_Height_In_Rows, Capacity_Rows);
         Header_Rectangles.Append
           (Guikit.Draw.Rectangle_Command'
              (X      => Natural (Geometry.X),
               Y      => Natural (Geometry.Y),
               Width  => Geometry.Width,
               Height => Header_Rows * Cell_H,
               Color  => Guikit.Draw.Input_Color));
         Push_Text
           (Text,
            Editor.Problems.Format_Header
              (Config,
               Editor.Input_Bridge.Problems_Total_Count_For_Render,
               Editor.Problems.Severity_Filter (View))
            & " | filter: "
            & Editor.Problems.Severity_Filter_Label
                (Editor.Problems.Severity_Filter (View))
            & " | sort: " & Editor.Problems.Sort_Mode_Label (View.Sort_Mode)
            & " | group: " & Editor.Problems.Group_Mode_Label (View.Group_Mode)
            & " | " & Editor.Problems.Header_Action_Hint (View),
            Float (Geometry.X + Cell_W),
            Float (Geometry.Y),
            Guikit.Draw.Text_Color);
      end if;

      if Capacity_Rows <= Header_Rows then
         return;
      end if;

      First_Row_Y := Float (Geometry.Y + Header_Rows * Cell_H);

      declare
         Max_Rows : constant Natural := Capacity_Rows - Header_Rows;
         Emitted  : Natural := 0;
      begin
         if Editor.Problems.Row_Count (Snapshot) = 0 and then Max_Rows > 0 then
            Push_Text
              (Text,
               Editor.Problems.Truncate_Text
                 (Editor.Problems.Empty_State_Message
                    (Visible_Count => Editor.Problems.Row_Count (Snapshot),
                     Total_Count   =>
                       Editor.Input_Bridge.Problems_Total_Count_For_Render),
                  Text_Columns),
               Float (Geometry.X + Cell_W),
               First_Row_Y,
               Guikit.Draw.Muted_Text_Color);
            Emitted := 1;
         else
            declare
               Rows : Guikit.List_Panel.List_Panel_Row_Vectors.Vector;
               Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
               Texts      : Guikit.Draw.Text_Command_Vectors.Vector;
               Config_Panel : constant Guikit.List_Panel.List_Panel_Configuration :=
                 (Title               => Null_Unbounded_String,
                  Empty_State         => Null_Unbounded_String,
                  Line_Height         => Cell_H,
                  Text_Padding        => 2 * Cell_W,
                  Show_Alternate_Rows => True);
            begin
               for I in 1 .. Editor.Problems.Row_Count (Snapshot) loop
                  exit when Emitted >= Max_Rows;
                  declare
                     Problem : constant Editor.Problems.Problem_Row :=
                       Editor.Problems.Row (Snapshot, I);
                     Text_Row : constant String :=
                       Editor.Problems.Format_Row (Config, Problem, Text_Columns);
                     Logical_Row : constant Natural :=
                       Editor.Problems.Top_Row (View) + I - 1;
                     Is_Selected : constant Boolean :=
                       Logical_Row = Editor.Problems.Selected_Row_Index (View)
                       and then Problem.Diagnostic_Index /= Editor.Diagnostics.No_Diagnostic;
                     Is_Active : constant Boolean :=
                       Editor.Input_Bridge.Active_Diagnostic_For_Render = Problem.Diagnostic_Index;
                  begin
                     Rows.Append
                       (Guikit.List_Panel.List_Panel_Row'
                          (Label            => To_Unbounded_String (Text_Row),
                           Detail           => Null_Unbounded_String,
                           Shortcut         => Null_Unbounded_String,
                           Selected         => Is_Selected,
                           Enabled          => True,
                           Label_Color      => Guikit.Draw.Text_Color,
                           Has_Background   => Is_Active and then not Is_Selected,
                           Background_Color =>
                             (if Is_Selected then Guikit.Draw.Selection_Color
                              else Guikit.Draw.Hover_Color),
                           Accent_Color     => Severity_Color (Problem.Severity),
                           Shortcut_Color   => Guikit.Draw.Muted_Text_Color));
                     Emitted := Emitted + 1;
                  end;
               end loop;

               Guikit.List_Panel.Draw_Frame
                 (Rectangles    => Rectangles,
                  Text          => Texts,
                  Accessibility => Accessibility,
                  Clip_Width    => Viewport_Width,
                  Clip_Height   => Viewport_Height,
                  Region_X      => Geometry.X,
                  Region_Y      => Natural (Float'Floor (First_Row_Y)),
                  Region_Width  => Geometry.Width,
                  Region_Height => Emitted * Cell_H,
                  Config        => Config_Panel,
                  Rows          => Rows,
                  Draw_Chrome   => False);

               for R of Rectangles loop
                  Row_Rectangles.Append (R);
               end loop;
               for T of Texts loop
                  Text.Append (T);
               end loop;
            end;
         end if;
      end;

      if Focused then
         Row_Rectangles.Append
           (Guikit.Draw.Rectangle_Command'
              (X      => Natural (Geometry.X),
               Y      => Natural (Geometry.Y),
               Width  => Geometry.Width,
               Height => 1,
               Color  => Guikit.Draw.Border_Color));
      end if;
   end Build_Frame;

   procedure Build_Packet
     (Packet         : in out Editor.Render_Packet.Render_Packet;
      State          : Editor.State.State_Type;
      Layout_Config  : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive)
   is
      Visible       : Boolean;
      Background    : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Header        : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Rows          : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text          : Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility : Guikit.Draw.Accessibility_Node_Vectors.Vector;
   begin
      Build_Frame
        (State                 => State,
         Layout_Config         => Layout_Config,
         Viewport_Width        => Viewport_Width,
         Viewport_Height       => Viewport_Height,
         Cell_W                => Cell_W,
         Cell_H                => Cell_H,
         Visible               => Visible,
         Background_Rectangles => Background,
         Header_Rectangles     => Header,
         Row_Rectangles        => Rows,
         Text                  => Text,
         Accessibility         => Accessibility);

      if Visible then
         for R of Background loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Problems_Background_Layer, R);
         end loop;
         for R of Header loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Problems_Header_Layer, R);
         end loop;
         for R of Rows loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Problems_Row_Layer, R);
         end loop;
         for T of Text loop
            Push_Guikit_Text (Packet, Editor.Render_Layers.Problems_Text_Layer, T);
         end loop;
      end if;
   end Build_Packet;

end Editor.Problems.Surface_Rendering;
