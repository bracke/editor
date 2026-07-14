with Ada.Containers; use type Ada.Containers.Count_Type;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Buffers;
with Editor.File_Tree;
with Editor.Input_Field;
with Editor.Project;
with Editor.Quick_Open_Markers;
with Editor.Overlay_Focus;
with Editor.Render_Layers;
with Editor.Render_Packet.Guikit_Adapters;
with Guikit.List_Panel;
with Guikit.Widgets;

package body Editor.Quick_Open.Surface_Rendering is

   use Editor.Render_Packet.Guikit_Adapters;

   function Truncate_Right
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
   end Truncate_Right;

   function Empty_Text
     (Snapshot : Editor.Quick_Open.Quick_Open_Snapshot;
      S        : Editor.State.State_Type) return String
   is
   begin
      if Length (Snapshot.Empty_Message) > 0 then
         return To_String (Snapshot.Empty_Message);
      elsif not Editor.Project.Has_Project (S.Project) then
         return "No project open";
      elsif Editor.Project.Known_File_Count (S.Project) = 0 then
         return "No project files";
      elsif Length (Snapshot.Query) > 0
        or else Snapshot.File_Kind_Filter /= Editor.Quick_Open.All_Files
        or else Length (Snapshot.Path_Scope) > 0
      then
         return "No Quick Open matches.";
      else
         return "No project files";
      end if;
   end Empty_Text;

   function Marker_Text
     (Candidate : Editor.Quick_Open.Quick_Open_Candidate_Snapshot)
      return String
   is
      Result : Unbounded_String := Null_Unbounded_String;

      procedure Append_Marker (Text : String) is
      begin
         if Length (Result) > 0 then
            Append (Result, " ");
         end if;
         Append (Result, Text);
      end Append_Marker;
   begin
      if Candidate.Is_Open then
         Append_Marker ("open");
      end if;
      if Candidate.Is_Active then
         Append_Marker ("active");
      end if;
      if Candidate.Is_Dirty then
         Append_Marker ("dirty");
      end if;
      if Candidate.Is_Recent then
         Append_Marker ("recent");
      end if;
      return To_String (Result);
   end Marker_Text;

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
      Result_Rectangles     : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Caret_Rectangles      : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text           : out Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility  : out Guikit.Draw.Accessibility_Node_Vectors.Vector)
   is
      Config : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Message_Body : constant Editor.Layout.Rect :=
        Editor.Layout.Editor_Body_Rect
          (Layout_Config, Viewport_Width, Viewport_Height);
      G : constant Editor.Layout.Rect :=
        Editor.Quick_Open.Geometry (Message_Body, Config, Cell_W, Cell_H);
      Snapshot : constant Editor.Quick_Open.Quick_Open_Snapshot :=
        Editor.Quick_Open_Markers.Build_Snapshot
          (State    => State.Quick_Open,
           Tree     => State.File_Tree,
           Project  => State.Project,
           Registry => Editor.Buffers.Global_Registry_For_UI,
           Recent   => State.Recent_Buffers);
      Text_Cols : constant Natural :=
        (if G.Width / Cell_W > 2 then G.Width / Cell_W - 2 else 1);
      Field_Y : constant Float := Float (G.Y + Integer (Config.Header_Height_In_Rows * Cell_H));
      Rows_Y  : constant Float :=
        Float (G.Y + Integer ((Config.Header_Height_In_Rows + Config.Field_Height_In_Rows) * Cell_H));
      Text_X : constant Float := Float (G.X + Integer (Config.Result_Padding_Columns * Cell_W));
      Q_Snap : constant Editor.Input_Field.Field_Snapshot :=
        Editor.Quick_Open.Query_Snapshot (State.Quick_Open, Text_Cols);
      Active : constant Boolean :=
        Editor.Overlay_Focus.Is_Active
          (State.Overlay_Focus, Editor.Overlay_Focus.Quick_Open_Overlay);
      Rows_Height : constant Natural :=
        (if G.Height >
           (Config.Header_Height_In_Rows + Config.Field_Height_In_Rows) * Cell_H
         then G.Height -
           (Config.Header_Height_In_Rows + Config.Field_Height_In_Rows) * Cell_H
         else 0);
   begin
      Background_Rectangles.Clear;
      Field_Rectangles.Clear;
      Result_Rectangles.Clear;
      Caret_Rectangles.Clear;
      Text.Clear;
      Accessibility.Clear;
      Visible := Editor.Quick_Open.Is_Open (State.Quick_Open)
        and then G.Width > 0
        and then Viewport_Width > 0
        and then Viewport_Height > 0;
      if not Visible then
         return;
      end if;

      declare
         Panel_Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      begin
         Guikit.Widgets.Draw_Menu_Panel
           (Panel_Rectangles,
            Clip_Width   => Viewport_Width,
            Clip_Height  => Viewport_Height,
            X            => G.X,
            Y            => G.Y,
            Width        => G.Width,
            Height       => G.Height,
            Fill_Color   => Guikit.Draw.Pane_Color,
            Border_Color => Guikit.Draw.Border_Color);
         for R of Panel_Rectangles loop
            Background_Rectangles.Append (R);
         end loop;
      end;

        Text.Append
        (Guikit.Draw.Text_Command'
           (X => Natural (Float'Floor (Text_X)),
            Y => Natural (G.Y),
            Width => 0,
            Height => 0,
            Text => To_Unbounded_String
              ((if Length (Snapshot.Header_Text) > 0
                then "Quick Open  " & To_String (Snapshot.Header_Text)
                else "Quick Open")),
            Color => Guikit.Draw.Text_Color,
            others => <>));

      declare
         Input_Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Field_Width : constant Natural :=
           (if G.Width > 2 * Config.Result_Padding_Columns * Cell_W
            then G.Width - 2 * Config.Result_Padding_Columns * Cell_W
            else 0);
      begin
        Guikit.Widgets.Draw_Input_Field
           (Input_Rectangles,
            Clip_Width   => Viewport_Width,
            Clip_Height  => Viewport_Height,
            X            => Natural (Float'Floor (Text_X)),
            Y            => Natural (Float'Floor (Field_Y)),
            Width        => Field_Width,
            Height       => Cell_H,
            Fill_Color   => Guikit.Draw.Input_Color,
            Border_Color => Guikit.Draw.Border_Color);
         for R of Input_Rectangles loop
            Field_Rectangles.Append (R);
         end loop;
      end;

      Push_Field_Selection
        (Q_Snap, Cell_W, Cell_H, Text_X + Float (Cell_W), Field_Y, Field_Rectangles);
      Text.Append
        (Guikit.Draw.Text_Command'
           (X => Natural (Float'Floor (Text_X + Float (Cell_W))),
            Y => Natural (Float'Floor (Field_Y)),
            Width => 0,
            Height => 0,
            Text => Q_Snap.Visible_Text,
            Color => Guikit.Draw.Text_Color,
            others => <>));
      if Active then
         Caret_Rectangles.Append
           (Guikit.Draw.Rectangle_Command'
              (X      => Natural (Float'Floor (Text_X + Float ((Q_Snap.Cursor_Visible_Column + 1) * Cell_W))),
               Y      => Natural (Float'Floor (Field_Y + 2.0)),
               Width  => 2,
               Height => Natural (Cell_H - 4),
               Color  => Guikit.Draw.Text_Color));
      end if;

      if Rows_Height > 0 then
         declare
            Rows_Draw : Guikit.List_Panel.List_Panel_Row_Vectors.Vector;
            Config_Panel : constant Guikit.List_Panel.List_Panel_Configuration :=
              (Title               => Null_Unbounded_String,
               Empty_State         => To_Unbounded_String (Empty_Text (Snapshot, State)),
               Line_Height         => Cell_H,
               Text_Padding        => Cell_W,
               Show_Alternate_Rows => True);
            Rects : Guikit.Draw.Rectangle_Command_Vectors.Vector;
            Texts : Guikit.Draw.Text_Command_Vectors.Vector;
         begin
            if Natural (Snapshot.Candidates.Length) > 0 then
               for Row in 1 .. Config.Max_Visible_Results loop
                  declare
                     Index : constant Natural :=
                       Editor.Quick_Open.Top_Result_Index (State.Quick_Open) + Row - 1;
                  begin
                     exit when Index > Natural (Snapshot.Candidates.Length);
                     declare
                        Candidate : constant Editor.Quick_Open.Quick_Open_Candidate_Snapshot :=
                          Snapshot.Candidates (Index - 1);
                        Marker : constant String := Marker_Text (Candidate);
                     begin
                        Rows_Draw.Append
                          (Guikit.List_Panel.List_Panel_Row'
                             (Label            => Candidate.Display_Text,
                              Detail           =>
                                (if Marker'Length > 0
                                 then To_Unbounded_String (Marker)
                                 else Null_Unbounded_String),
                              Shortcut         => Null_Unbounded_String,
                              Selected         => Candidate.Is_Selected,
                              Enabled          => True,
                              Label_Color      => Guikit.Draw.Text_Color,
                              Has_Background   => Candidate.Is_Active and then not Candidate.Is_Selected,
                              Background_Color => Guikit.Draw.Hover_Color,
                              Accent_Color     =>
                                (if Candidate.Is_Active then Guikit.Draw.Label_Orange_Color
                                 else Guikit.Draw.Border_Color),
                              Shortcut_Color   => Guikit.Draw.Muted_Text_Color));
                     end;
                  end;
               end loop;
            end if;

            Guikit.List_Panel.Draw_Frame
              (Rectangles    => Rects,
               Text          => Texts,
               Accessibility => Accessibility,
               Clip_Width    => Viewport_Width,
               Clip_Height   => Viewport_Height,
               Region_X      => Natural (G.X),
               Region_Y      => Natural (Float'Floor (Rows_Y)),
               Region_Width  => Natural (G.Width),
               Region_Height => Rows_Height,
               Config        => Config_Panel,
               Rows          => Rows_Draw);

            for R of Rects loop
               Result_Rectangles.Append (R);
            end loop;
            for T of Texts loop
               Text.Append (T);
            end loop;
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
      Result        : Guikit.Draw.Rectangle_Command_Vectors.Vector;
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
         Result_Rectangles     => Result,
         Caret_Rectangles      => Caret,
         Text                  => Text,
         Accessibility         => Accessibility);

      if Visible then
         for R of Background loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Quick_Open_Background_Layer, R);
         end loop;
         for R of Field loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Quick_Open_Field_Layer, R);
         end loop;
         for R of Result loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Quick_Open_Selected_Result_Layer, R);
         end loop;
         for R of Caret loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Quick_Open_Caret_Layer, R);
         end loop;
         for T of Text loop
            Push_Guikit_Text (Packet, Editor.Render_Layers.Quick_Open_Text_Layer, T);
         end loop;
      end if;
   end Build_Packet;

end Editor.Quick_Open.Surface_Rendering;
