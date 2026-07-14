with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Buffers;
with Editor.Buffer_Switcher_Contextual_Hints;
with Editor.Layout;
with Guikit.Draw;

package body Editor.Buffer_Switcher.Surface_Projection is

   function Truncate_Right (Text : String; Columns : Natural) return String is
   begin
      if Columns = 0 then
         return "";
      elsif Text'Length <= Columns then
         return Text;
      elsif Columns = 1 then
         return "~";
      else
         return Text (Text'First .. Text'First + Columns - 2) & "~";
      end if;
   end Truncate_Right;

   function Line_Count_Of (Text : String) return Natural is
      Count : Natural := 1;
   begin
      if Text'Length = 0 then
         return 0;
      end if;
      for Ch of Text loop
         if Ch = ASCII.LF then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Line_Count_Of;

   function Line_Text (Text : String; Line : Positive) return String is
      Current : Positive := 1;
      Start   : Positive := Text'First;
   begin
      if Text'Length = 0 then
         return "";
      end if;

      for I in Text'Range loop
         if Text (I) = ASCII.LF then
            if Current = Line then
               if I = Start then
                  return "";
               else
                  return Text (Start .. I - 1);
               end if;
            end if;
            Current := Current + 1;
            if I < Text'Last then
               Start := I + 1;
            end if;
         end if;
      end loop;

      if Current = Line and then Start <= Text'Last then
         return Text (Start .. Text'Last);
      elsif Current = Line then
         return "";
      else
         return "";
      end if;
   end Line_Text;

   function Image_No_Leading (Value : Natural) return String is
      Raw : constant String := Natural'Image (Value);
   begin
      if Raw'Length > 0 and then Raw (Raw'First) = ' ' then
         return Raw (Raw'First + 1 .. Raw'Last);
      else
         return Raw;
      end if;
   end Image_No_Leading;

   function Project
     (S               : Editor.State.State_Type;
      Viewport_Width   : Natural;
      Viewport_Height  : Natural;
      Layout_Origin_X  : Natural;
      Layout_Origin_Y  : Natural;
      Cell_W           : Natural;
      Cell_H           : Positive)
      return Buffer_Switcher_Render_Projection
   is
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Message_Body : constant Editor.Layout.Rect :=
        Editor.Layout.Editor_Body_Rect
          (Editor.Layout.Current, Viewport_Width, Viewport_Height);
      G : constant Editor.Layout.Rect :=
        Editor.Buffer_Switcher.Geometry (Message_Body, Config, Cell_W, Cell_H);
      Result : Buffer_Switcher_Render_Projection;
      Count : constant Natural := Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher);
      Q_Snap : constant Editor.Input_Field.Field_Snapshot :=
        Editor.Buffer_Switcher.Query_Snapshot (S.Buffer_Switcher,
          (if G.Width / Cell_W > 2 then G.Width / Cell_W - 2 else 1));
      Header_Badge_Text : constant String :=
        Editor.Buffer_Switcher.Header_Badge_Text
          (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI);
      Header_Text : constant String :=
        (if Header_Badge_Text'Length > 0
         then "Open Buffers - " & Header_Badge_Text
         else "Open Buffers");
      Hint_Text : constant String :=
        Editor.Buffer_Switcher_Contextual_Hints.Contextual_Hint_Text (S);
      Preview_Target : constant Editor.Buffers.Buffer_Id :=
        Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher);
      Registry : constant Editor.Buffers.Buffer_Registry :=
        Editor.Buffers.Global_Registry_For_UI;
      First_Line : Natural := 1;
      Text : Unbounded_String := Null_Unbounded_String;
      Display_Name : Unbounded_String := Null_Unbounded_String;
      Total_Lines : Natural := 0;
      Rows : Guikit.List_Panel.List_Panel_Row_Vectors.Vector;
      Row_Height : constant Natural :=
        Config.Max_Visible_Results * Config.Row_Height_In_Rows * Cell_H;
   begin
      Result.Visible := Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher)
        and then G.Width > 0
        and then Viewport_Width > 0
        and then Viewport_Height > 0;
      Result.Panel := G;
      Result.Text_Columns := (if G.Width / Cell_W > 2 then G.Width / Cell_W - 2 else 1);
      Result.Header_Text := To_Unbounded_String (Header_Text);
      Result.Hint_Text := To_Unbounded_String (Hint_Text);
      Result.Query_Snapshot := Q_Snap;
      Result.Field_Y := Natural (G.Y + Integer (Config.Header_Height_In_Rows * Cell_H));
      Result.Rows_Y :=
        Natural (G.Y + Integer ((Config.Header_Height_In_Rows + Config.Field_Height_In_Rows) * Cell_H));
      Result.Footer_Y := Natural (G.Y + G.Height - Cell_H);
      Result.Row_Height := Row_Height;

      if not Result.Visible then
         return Result;
      end if;

      for Row in 1 .. Config.Max_Visible_Results loop
         declare
            Index : constant Natural :=
              Editor.Buffer_Switcher.Top_Row_Index (S.Buffer_Switcher) + Row - 1;
         begin
            exit when Index > Count;
            declare
               R : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
                 Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, Index);
               Markers : constant String := Editor.Buffer_Switcher.Buffer_Row_State_Markers (R);
               Marker_Text : constant String :=
                 (if Markers'Length = 0 then "" else "[" & Markers & "]");
               Metadata_Label : constant String :=
                 Editor.Buffer_Switcher.Buffer_Row_Metadata_Render_Label (R);
               Prefix : constant String :=
                 (if R.Is_Active then "> " else "  ");
               Mark : constant String :=
                 (if R.Is_Marked then "[*] "
                  else "    ");
               Dirty : constant String :=
                 (if R.Is_Dirty then " *" else "");
               Label_Text : constant String :=
                 Prefix & Mark & To_String (R.Display_Label) & Dirty;
               Detail_Text : constant String :=
                 (if Marker_Text'Length = 0 then "" else Marker_Text)
                 & (if Marker_Text'Length > 0 and then Metadata_Label'Length > 0 then " " else "")
                 & (if Metadata_Label'Length = 0 then "" else "{" & Metadata_Label & "}");
            begin
               Rows.Append
                 (Guikit.List_Panel.List_Panel_Row'
                    (Label            => To_Unbounded_String (Label_Text),
                     Detail           =>
                       (if Detail_Text'Length > 0
                        then To_Unbounded_String (Detail_Text)
                        else Null_Unbounded_String),
                     Shortcut         => Null_Unbounded_String,
                     Selected         => Index = Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher),
                     Enabled          => True,
                     Label_Color      => Guikit.Draw.Text_Color,
                     Has_Background   => False,
                     Background_Color => Guikit.Draw.Pane_Color,
                     Accent_Color     => Guikit.Draw.Border_Color,
                     Shortcut_Color   => Guikit.Draw.Muted_Text_Color));
            end;
         end;
      end loop;
      Result.Rows := Rows;

      if Editor.Buffer_Switcher.Has_Preview (S.Buffer_Switcher) then
         if Preview_Target /= Editor.Buffers.No_Buffer
           and then Editor.Buffers.Contains (Registry, Preview_Target)
         then
            declare
               B : constant Editor.State.State_Type := Editor.Buffers.Buffer (Registry, Preview_Target);
            begin
               Text := To_Unbounded_String (Editor.State.Current_Text (B));
               Display_Name := To_Unbounded_String (Editor.Buffers.Display_Name (Registry, Preview_Target));
            end;

            Result.Preview_Visible := True;
            Result.Preview_Header :=
              To_Unbounded_String
                (Truncate_Right ("Preview: " & To_String (Display_Name), Result.Text_Columns));

            if Length (Text) = 0 then
               Result.Preview_Empty := To_Unbounded_String ("  <empty buffer>");
            else
               Total_Lines := Line_Count_Of (To_String (Text));
               First_Line :=
                 Editor.Buffer_Switcher.Preview_Anchor_Line (S.Buffer_Switcher)
                 + Editor.Buffer_Switcher.Preview_Scroll_Offset (S.Buffer_Switcher);
               if First_Line = 0 then
                  First_Line := 1;
               elsif First_Line > Total_Lines then
                  First_Line := Total_Lines;
               end if;

               for I in 0 .. Natural'Max (1, Config.Preview_Max_Lines) - 1 loop
                  declare
                     Line_No : constant Natural := First_Line + I;
                  begin
                     exit when Line_No > Total_Lines;
                     Result.Preview_Lines.Append
                       (To_Unbounded_String
                          (Truncate_Right
                             ("  " & Image_No_Leading (Line_No) & " | " &
                              Line_Text (To_String (Text), Positive (Line_No)),
                              Result.Text_Columns)));
                  end;
               end loop;
            end if;
         else
            Result.Preview_Visible := True;
            Result.Preview_Empty := To_Unbounded_String ("Preview: no selected buffer");
         end if;
      end if;

      return Result;
   end Project;

end Editor.Buffer_Switcher.Surface_Projection;
