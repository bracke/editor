with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Input_Field;
with Editor.Overlay_Focus;
with Editor.Project_Search;
with Editor.Project_Search_Bar;
with Editor.Render_Layers;
with Editor.Render_Packet.Guikit_Adapters;
with Editor.State;
with Editor.Theme;
with Guikit.Draw;
with Guikit.Widgets;

package body Editor.Project_Search_Bar.Surface_Rendering is

   use Editor.Render_Packet.Guikit_Adapters;

   function Truncate_To_Columns
     (Text    : String;
      Columns : Natural) return String
   is
   begin
      if Text'Length <= Columns then
         return Text;
      elsif Columns <= 3 then
         return Text (Text'First .. Text'First + Columns - 1);
      else
         return Text (Text'First .. Text'First + Columns - 4) & "...";
      end if;
   end Truncate_To_Columns;

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

   procedure Push_Field_Selection
     (Snap   : Editor.Input_Field.Field_Snapshot;
      Cell_W : Natural;
      Cell_H : Positive;
      X      : Float;
      Y      : Float;
      Rectangles : in out Guikit.Draw.Rectangle_Command_Vectors.Vector)
   is
      Visible_Count : constant Natural := Length (Snap.Visible_Text);
      Visible_First : constant Natural := Snap.First_Visible_Column;
      Visible_Last  : constant Natural := Visible_First + Visible_Count;
      A : Natural := Snap.Selection_Start;
      B : Natural := Snap.Selection_End;
   begin
      if not Snap.Has_Selection or else Visible_Count = 0 then
         return;
      end if;

      if A < Visible_First then
         A := Visible_First;
      end if;
      if B > Visible_Last then
         B := Visible_Last;
      end if;

      if B > A then
         Rectangles.Append
           (Guikit.Draw.Rectangle_Command'
              (X      => Natural (Float'Floor (X + Float ((A - Visible_First) * Cell_W))),
               Y      => Natural (Float'Floor (Y)),
               Width  => Natural ((B - A) * Cell_W),
               Height => Natural (Cell_H),
               Color  => Guikit.Draw.Selection_Color));
      end if;
   end Push_Field_Selection;

   function Status_Text
     (S : Editor.State.State_Type) return String
   is
      Count : constant Natural := Editor.Project_Search.Result_Count (S.Project_Search);
      Files : constant Natural := Editor.Project_Search.File_Group_Count (S.Project_Search);
   begin
      if Editor.Project_Search_Bar.Is_Open (S.Project_Search_Bar)
        and then Editor.Project_Search_Bar.Query_Text (S.Project_Search_Bar)
          /= Editor.Project_Search.Last_Run_Query (S.Project_Search)
      then
         return "Query changed - press Enter to search";
      elsif Editor.Project_Search.Is_Stale (S.Project_Search) then
         return "Results may be stale";
      elsif Editor.Project_Search.Was_Truncated (S.Project_Search) then
         return "Results truncated";
      end if;

      case Editor.Project_Search.Status (S.Project_Search) is
         when Editor.Project_Search.Project_Search_No_Project =>
            return "No project open";
         when Editor.Project_Search.Project_Search_No_Files =>
            return "No project files";
         when Editor.Project_Search.Project_Search_Empty_Query =>
            return "Project search query is empty";
         when Editor.Project_Search.Project_Search_Ok =>
            if Count = 0 then
               return "No matches";
            else
               return Natural'Image (Count) & " matches in" & Natural'Image (Files) & " files";
            end if;
         when Editor.Project_Search.Project_Search_Read_Error =>
            return "Project search read error";
         when Editor.Project_Search.Project_Search_Invalid_Regex =>
            return "Invalid regex";
         when others =>
            return "Idle";
      end case;
   end Status_Text;

   procedure Build_Frame
     (State          : Editor.State.State_Type;
      Layout_Config  : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive;
      Visible        : out Boolean;
      Background_Rectangles : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Field_Rectangles      : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Caret_Rectangles      : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text           : out Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility  : out Guikit.Draw.Accessibility_Node_Vectors.Vector)
   is
      Config : constant Editor.Project_Search_Bar.Project_Search_Bar_Config := (others => <>);
      Message_Body : constant Editor.Layout.Rect :=
        Editor.Layout.Editor_Body_Rect
          (Layout_Config, Viewport_Width, Viewport_Height);
      G : constant Editor.Layout.Rect :=
        Editor.Project_Search_Bar.Geometry (Message_Body, Config, Cell_W, Cell_H);
      Text_X : constant Float := Float (G.X + Integer (Cell_W));
      Field_X : constant Float := Float (G.X + Integer (16 * Cell_W));
      Total_Cols : constant Natural := (G.Width / Cell_W);
      Run_Start : constant Natural := (if Total_Cols > 22 then Total_Cols - 22 else 0);
      Field_Cols : constant Natural :=
        (if Run_Start > 18 then Run_Start - 18 else Natural'Max (1, Config.Query_Field_Min_Columns));
      Y : constant Float := Float (G.Y);
      Replace_Y : constant Float := Y + Float (Cell_H);
      Status : constant String := Status_Text (State);
      Active : constant Boolean :=
        Editor.Overlay_Focus.Is_Active
          (State.Overlay_Focus, Editor.Overlay_Focus.Project_Search_Bar_Overlay);
      Active_Field : constant Editor.Project_Search_Bar.Project_Search_Bar_Field :=
        Editor.Project_Search_Bar.Active_Field (State.Project_Search_Bar);
      Q_Snap : constant Editor.Input_Field.Field_Snapshot :=
        Editor.Project_Search_Bar.Query_Snapshot (State.Project_Search_Bar, Field_Cols);
      R_Snap : constant Editor.Input_Field.Field_Snapshot :=
        Editor.Project_Search_Bar.Replace_Snapshot (State.Project_Search_Bar, Field_Cols);
   begin
      Background_Rectangles.Clear;
      Field_Rectangles.Clear;
      Caret_Rectangles.Clear;
      Text.Clear;
      Accessibility.Clear;
      Visible := False;

      if not Editor.Project_Search_Bar.Is_Open (State.Project_Search_Bar) or else G.Width = 0 then
         return;
      end if;

      Visible := True;

      declare
         Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      begin
         Guikit.Widgets.Draw_Menu_Panel
           (Rectangles,
            Clip_Width   => Viewport_Width,
            Clip_Height  => Viewport_Height,
            X            => G.X,
            Y            => G.Y,
            Width        => G.Width,
            Height       => G.Height,
            Fill_Color   => Guikit.Draw.Pane_Color,
            Border_Color => Guikit.Draw.Border_Color);
         for R of Rectangles loop
            Background_Rectangles.Append (R);
         end loop;
      end;

      Push_Text
        (Text, "Search Project", Text_X, Y, Guikit.Draw.Text_Color);

      declare
         Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      begin
         Guikit.Widgets.Draw_Input_Field
           (Rectangles,
            Clip_Width   => Viewport_Width,
            Clip_Height  => Viewport_Height,
            X            => Natural (Field_X),
            Y            => G.Y,
            Width        => Field_Cols * Cell_W,
            Height       => Cell_H,
            Fill_Color   => Guikit.Draw.Input_Color,
            Border_Color => Guikit.Draw.Border_Color);
         for R of Rectangles loop
            Field_Rectangles.Append (R);
         end loop;
      end;

      Push_Field_Selection
        (Q_Snap, Cell_W, Cell_H, Field_X + Float (Cell_W), Y, Field_Rectangles);
      Push_Text
        (Text, To_String (Q_Snap.Visible_Text), Field_X + Float (Cell_W), Y,
         Guikit.Draw.Text_Color);
      Push_Text
        (Text, "Replace", Text_X, Replace_Y,
         Guikit.Draw.Text_Color);

      declare
         Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      begin
         Guikit.Widgets.Draw_Input_Field
           (Rectangles,
            Clip_Width   => Viewport_Width,
            Clip_Height  => Viewport_Height,
            X            => Natural (Field_X),
            Y            => Natural (Replace_Y),
            Width        => Field_Cols * Cell_W,
            Height       => Cell_H,
            Fill_Color   => Guikit.Draw.Input_Color,
            Border_Color => Guikit.Draw.Border_Color);
         for R of Rectangles loop
            Field_Rectangles.Append (R);
         end loop;
      end;

      Push_Field_Selection
        (R_Snap, Cell_W, Cell_H, Field_X + Float (Cell_W), Replace_Y, Field_Rectangles);
      Push_Text
        (Text, To_String (R_Snap.Visible_Text), Field_X + Float (Cell_W), Replace_Y,
         Guikit.Draw.Text_Color);

      if Active then
         declare
            C : constant Natural :=
              (if Active_Field = Editor.Project_Search_Bar.Project_Search_Query_Field
               then Q_Snap.Cursor_Visible_Column
               else R_Snap.Cursor_Visible_Column);
            Caret_Y : constant Float :=
              (if Active_Field = Editor.Project_Search_Bar.Project_Search_Query_Field
               then Y + 2.0
               else Replace_Y + 2.0);
         begin
            Caret_Rectangles.Append
              (Guikit.Draw.Rectangle_Command'
                 (X      => Natural (Float'Floor (Field_X + Float ((C + 1) * Cell_W))),
                  Y      => Natural (Float'Floor (Caret_Y)),
                  Width  => 2,
                  Height => Natural (Cell_H - 4),
                  Color  => Guikit.Draw.Selection_Color));
         end;
      end if;

      if Total_Cols > 24 then
         Push_Text
           (Text, "Run", Float (G.X + Integer ((Total_Cols - 22) * Cell_W)), Y,
            Guikit.Draw.Text_Color);
         Push_Text
           (Text, "Clear", Float (G.X + Integer ((Total_Cols - 15) * Cell_W)), Y,
            Guikit.Draw.Text_Color);
         Push_Text
           (Text, "Close", Float (G.X + Integer ((Total_Cols - 7) * Cell_W)), Y,
            Guikit.Draw.Text_Color);
      end if;

      if Config.Show_Status_Text and then G.Height >= Cell_H then
         declare
            Status_Cols : constant Natural := (if Total_Cols > 2 then Total_Cols - 2 else 1);
            Status_Text : constant String := Truncate_To_Columns (Status, Status_Cols);
         begin
            Push_Text
              (Text, Status_Text, Text_X, Y + Float (Cell_H),
               Guikit.Draw.Muted_Text_Color);
         end;
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
      Field         : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Caret         : Guikit.Draw.Rectangle_Command_Vectors.Vector;
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
         Field_Rectangles      => Field,
         Caret_Rectangles      => Caret,
         Text                  => Text,
         Accessibility         => Accessibility);

      if Visible then
         for R of Background loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Project_Search_Bar_Background_Layer, R);
         end loop;
         for R of Field loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Project_Search_Bar_Field_Layer, R);
         end loop;
         for R of Caret loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Project_Search_Bar_Caret_Layer, R);
         end loop;
         for T of Text loop
            Push_Guikit_Text (Packet, Editor.Render_Layers.Project_Search_Bar_Text_Layer, T);
         end loop;
      end if;
   end Build_Packet;

end Editor.Project_Search_Bar.Surface_Rendering;
