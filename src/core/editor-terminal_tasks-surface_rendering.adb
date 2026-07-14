with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Layout;
with Editor.Panels;
with Editor.Render_Layers;
with Editor.Render_Packet.Guikit_Adapters;
with Editor.Terminal_Tasks;
with Guikit.Draw;
with Guikit.List_Panel;
with Guikit.Widgets;

package body Editor.Terminal_Tasks.Surface_Rendering is

   use Editor.Render_Packet.Guikit_Adapters;

   function Truncate
     (Text    : String;
      Columns : Natural) return String
   is
   begin
      if Columns = 0 then
         return "";
      elsif Text'Length <= Columns then
         return Text;
      else
         return Ada.Strings.Fixed.Head (Text, Columns);
      end if;
   end Truncate;

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

   function Status_Color
     (Status : Editor.Terminal_Tasks.Terminal_Task_Status)
      return Guikit.Draw.Render_Color
   is
   begin
      case Status is
         when Editor.Terminal_Tasks.Task_Running =>
            return Guikit.Draw.Label_Blue_Color;
         when Editor.Terminal_Tasks.Task_Succeeded =>
            return Guikit.Draw.Label_Green_Color;
         when Editor.Terminal_Tasks.Task_Failed =>
            return Guikit.Draw.Error_Text_Color;
         when Editor.Terminal_Tasks.Task_Not_Available =>
            return Guikit.Draw.Disabled_Text_Color;
         when Editor.Terminal_Tasks.Task_Rejected =>
            return Guikit.Draw.Label_Orange_Color;
         when Editor.Terminal_Tasks.Task_Timed_Out =>
            return Guikit.Draw.Label_Orange_Color;
         when Editor.Terminal_Tasks.Task_Cancelled =>
            return Guikit.Draw.Muted_Text_Color;
         when Editor.Terminal_Tasks.Task_Not_Run =>
            return Guikit.Draw.Muted_Text_Color;
      end case;
   end Status_Color;

   procedure Build_Frame
     (State          : Editor.State.State_Type;
      Layout_Config  : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive;
      Visible        : out Boolean;
      Background_Rectangles : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Row_Rectangles : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text           : out Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility  : out Guikit.Draw.Accessibility_Node_Vectors.Vector)
   is
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
      Snapshot : constant Editor.Terminal_Tasks.Terminal_Task_Render_Snapshot :=
        Editor.Terminal_Tasks.Build_Render_Snapshot (State.Terminal_Tasks);
      Capacity_Rows : Natural := 0;
      Header_Rows : constant Natural := 1;
      Task_Rows : Natural := 0;
      Output_Rows : Natural := 0;
      Text_Columns : Natural := 0;
   begin
      Background_Rectangles.Clear;
      Row_Rectangles.Clear;
      Text.Clear;
      Accessibility.Clear;
      Visible := False;

      if Geometry.Width = 0 or else Geometry.Height = 0 then
         return;
      end if;

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

      Capacity_Rows := Geometry.Height / Cell_H;
      if Capacity_Rows = 0 then
         return;
      end if;

      if Geometry.Width > 2 * Cell_W then
         Text_Columns := (Geometry.Width / Cell_W) - 2;
      end if;

      Push_Text
        (Text,
         Truncate ("Terminal  " & To_String (Snapshot.Status_Label), Text_Columns),
         Float (Geometry.X + Cell_W),
         Float (Geometry.Y),
         Guikit.Draw.Text_Color);

      if Capacity_Rows <= Header_Rows then
         return;
      end if;

      Task_Rows :=
        Natural'Min
          (Snapshot.Row_Count,
           Natural'Min (3, Capacity_Rows - Header_Rows));
      Output_Rows := Capacity_Rows - Header_Rows - Task_Rows;

      if Task_Rows > 0 then
         declare
            Rows : Guikit.List_Panel.List_Panel_Row_Vectors.Vector;
            Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
            Texts : Guikit.Draw.Text_Command_Vectors.Vector;
            Config_Panel : constant Guikit.List_Panel.List_Panel_Configuration :=
              (Title               => Null_Unbounded_String,
               Empty_State         => Null_Unbounded_String,
               Line_Height         => Cell_H,
               Text_Padding        => Cell_W,
               Show_Alternate_Rows => True);
         begin
            for I in 1 .. Task_Rows loop
               declare
                  Row : constant Editor.Terminal_Tasks.Terminal_Task_Row :=
                    Snapshot.Rows (I);
                  Label_Text : constant String :=
                    Truncate
                      (To_String (Row.Label)
                       & (if Length (Row.Profile_Label) > 0
                          then " [" & To_String (Row.Profile_Label) & "]"
                          else ""),
                       Text_Columns);
                  Detail_Text : constant String := Truncate (To_String (Row.Program_Label), Text_Columns);
               begin
                  Rows.Append
                    (Guikit.List_Panel.List_Panel_Row'
                       (Label            => To_Unbounded_String (Label_Text),
                        Detail           =>
                          (if Detail_Text'Length > 0
                           then To_Unbounded_String (Detail_Text)
                           else Null_Unbounded_String),
                        Shortcut         => To_Unbounded_String (To_String (Row.Status_Label)),
                        Selected         => Row.Selected,
                        Enabled          => True,
                        Label_Color      => Guikit.Draw.Text_Color,
                        Has_Background   => False,
                        Background_Color => Guikit.Draw.Pane_Color,
                        Accent_Color     => Guikit.Draw.Border_Color,
                        Shortcut_Color   => Status_Color (Row.Status)));
               end;
            end loop;

            Guikit.List_Panel.Draw_Frame
              (Rectangles    => Rectangles,
               Text          => Texts,
               Accessibility => Accessibility,
               Clip_Width    => Viewport_Width,
               Clip_Height   => Viewport_Height,
               Region_X      => Natural (Geometry.X),
               Region_Y      => Natural (Geometry.Y + Header_Rows * Cell_H),
               Region_Width  => Geometry.Width,
               Region_Height => Task_Rows * Cell_H,
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

      if Snapshot.Row_Count = 0 and then Output_Rows > 0 then
         Push_Text
           (Text, Truncate (To_String (Snapshot.Empty_Message), Text_Columns),
            Float (Geometry.X + Cell_W),
            Float (Geometry.Y + (Header_Rows + Task_Rows) * Cell_H),
            Guikit.Draw.Muted_Text_Color);
      elsif Output_Rows > 0 and then Snapshot.Output_Row_Count > 0 then
         declare
            Lines_To_Show : constant Natural :=
              Natural'Min (Output_Rows, Snapshot.Output_Row_Count);
            First_Output_Index : constant Natural :=
              Snapshot.Output_Rows.Last_Index - Lines_To_Show + 1;
         begin
            for I in 0 .. Lines_To_Show - 1 loop
               declare
                  Source_Index : constant Natural := First_Output_Index + I;
                  Y : constant Float :=
                    Float (Geometry.Y + (Header_Rows + Task_Rows + I) * Cell_H);
               begin
                  Push_Text
                    (Text,
                     Truncate (To_String (Snapshot.Output_Rows (Source_Index)), Text_Columns),
                     Float (Geometry.X + Cell_W),
                     Y,
                     Guikit.Draw.Muted_Text_Color);
               end;
            end loop;
         end;
      end if;

      if Snapshot.Focused then
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
         Row_Rectangles        => Rows,
         Text                  => Text,
         Accessibility         => Accessibility);

      if Visible then
         for R of Background loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Problems_Background_Layer, R);
         end loop;
         for R of Rows loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Problems_Row_Layer, R);
         end loop;
         for T of Text loop
            Push_Guikit_Text (Packet, Editor.Render_Layers.Problems_Text_Layer, T);
         end loop;
      end if;
   end Build_Packet;

end Editor.Terminal_Tasks.Surface_Rendering;
