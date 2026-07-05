with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Interfaces.C; use Interfaces.C;
with Editor.Commands;
with Editor.Cursors;
with Editor.Input_Bridge;
with Editor.Layout;
with Editor.Line_Numbers;
with Editor.Minimap;
with Editor.Render_Layers;
with Editor.Render_Model;
with Editor.Render_Packet;
with Editor.Scrollbars;
with Editor.State;
with Editor.View;

package body Editor.Status_Bar.Tests is

   Right : Unbounded_String;

   overriding function Name
     (T : Status_Bar_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Status_Bar");
   end Name;

   function Rect_Count_On_Layer
     (Packet : Editor.Render_Packet.Render_Packet;
      Layer  : Editor.Render_Layers.Render_Layer) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 0 .. Packet.Rect_Count - 1 loop
         if Packet.Rects (Natural (I)).Layer = Editor.Render_Layers.To_C (Layer) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Rect_Count_On_Layer;

   function Glyph_Count_On_Layer
     (Packet : Editor.Render_Packet.Render_Packet;
      Layer  : Editor.Render_Layers.Render_Layer) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 0 .. Packet.Glyph_Count - 1 loop
         if Packet.Glyphs (Natural (I)).Layer = Editor.Render_Layers.To_C (Layer) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Glyph_Count_On_Layer;

   function Occurrence_Count
     (Text    : String;
      Pattern : String) return Natural
   is
      Count : Natural := 0;
      From  : Positive := Text'First;
      At_Index    : Natural := 0;
   begin
      if Pattern'Length = 0 then
         return 0;
      end if;

      while From <= Text'Last loop
         At_Index := Index (Text, Pattern, From);
         exit when At_Index = 0;
         Count := Count + 1;
         From := At_Index + Pattern'Length;
      end loop;

      return Count;
   end Occurrence_Count;

   procedure Prepare_Text
   is
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & "beta" & ASCII.LF & "gamma");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String ("main.adb");
      S.File_Info.Display_Name := To_Unbounded_String ("main.adb");
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (800, 200);
      Editor.Scrollbars.Reset;
   end Prepare_Text;

   procedure Test_Status_Bar_Height_Follows_Config
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Enabled  : constant Status_Bar_Config := (Enabled => True);
      Disabled : constant Status_Bar_Config := (Enabled => False);
   begin
      Assert (Height_In_Rows (Enabled) = 1,
              "Enabled status bar must consume one row");
      Assert (Height_In_Rows (Disabled) = 0,
              "Disabled status bar must consume zero rows");
   end Test_Status_Bar_Height_Follows_Config;

   procedure Test_Layout_Reserves_Bottom_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Height : constant Natural := 200;
   begin
      Assert
        (Editor.Layout.Status_Bar_Height (Layout) = Editor.Layout.Cell_H,
         "Layout must reserve one cell-height row for the status bar");
      Assert
        (Editor.Layout.Status_Bar_Y (Layout, Height)
         = Integer (Layout.Origin_Y + Height - Editor.Layout.Cell_H),
         "Status bar Y must be the last cell row of the viewport");
      Assert
        (Editor.Layout.Text_Viewport_Height (Layout, Height)
         = Height - Editor.Layout.Tab_Bar_Height (Layout) - Editor.Layout.Cell_H,
         "Text viewport height must subtract tab-bar and status-bar height");
   end Test_Layout_Reserves_Bottom_Row;

   procedure Test_Disabled_Status_Bar_Reserves_No_Layout_Height
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Layout : Editor.Layout.Layout_Config := Editor.Layout.Current;
      Height : constant Natural := 200;
   begin
      Layout.Status_Bar.Enabled := False;

      Assert
        (Editor.Layout.Status_Bar_Height (Layout) = 0,
         "Disabled status bar must reserve no pixel height");
      Assert
        (Editor.Layout.Text_Viewport_Height (Layout, Height)
         = Height - Editor.Layout.Tab_Bar_Height (Layout),
         "Disabled status bar must not shrink the text viewport beyond the tab bar");
      Assert
        (not Editor.Layout.Is_In_Status_Bar
           (Config          => Layout,
            X               => Integer (Layout.Origin_X),
            Y               => Integer (Layout.Origin_Y + Height - 1),
            Viewport_Width  => 800,
            Viewport_Height => Height),
         "Disabled status bar must not consume pointer hits");
   end Test_Disabled_Status_Bar_Reserves_No_Layout_Height;

   procedure Test_Status_Bar_Does_Not_Change_X_Geometry
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Lines  : constant Natural := 100;
   begin
      Assert
        (Editor.Layout.Text_Origin_X (Layout, Lines)
         = Editor.Layout.Editor_Body_X (Layout)
           + Editor.Layout.Gutter_Width_For_Line_Count (Layout, Lines)
           + Layout.Text_Left_Padding,
         "Status bar must not change text origin X");
      Assert
        (Editor.Layout.Gutter_Marker_X (Layout)
         = Editor.Layout.Editor_Body_X (Layout)
           + Layout.Gutter_Left_Padding,
         "Status bar must not change marker zone X geometry");
   end Test_Status_Bar_Does_Not_Change_X_Geometry;

   procedure Test_Minimap_And_Scrollbars_Do_Not_Overlap_Status_Bar
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Layout     : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Scrollbars : constant Editor.Scrollbars.Scrollbar_Config :=
        Editor.Scrollbars.Current;
      Minimap    : constant Editor.Minimap.Minimap_Config :=
        Editor.Minimap.Current;
      View_W     : constant Natural := 800;
      View_H     : constant Natural := 200;
      Status_Top : constant Float :=
        Float (Editor.Layout.Status_Bar_Y (Layout, View_H));
      Effective_W : constant Natural :=
        Editor.Scrollbars.Effective_Viewport_Width (View_W, Scrollbars);
      Effective_H : constant Natural :=
        Editor.Scrollbars.Effective_Viewport_Height (View_H, Scrollbars);
      Text_H : constant Natural :=
        Editor.Layout.Text_Viewport_Height (Layout, Effective_H);
      Vertical : constant Editor.Scrollbars.Scrollbar_Geometry :=
        Editor.Scrollbars.Vertical_Geometry
          (Layout          => Layout,
           Viewport_Width  => View_W,
           Viewport_Height => Editor.Layout.Text_Viewport_Height (Layout, View_H),
           Total_Rows      => 200,
           Visible_Rows    => 10,
           Scroll_Y        => 0,
           Config          => Scrollbars);
      Horizontal : constant Editor.Scrollbars.Scrollbar_Geometry :=
        Editor.Scrollbars.Horizontal_Geometry
          (Layout          => Layout,
           Text_Left       => Editor.Layout.Text_Origin_X (Layout, 200),
           Text_Width      => 400,
           Viewport_Height => Editor.Layout.Text_Viewport_Height (Layout, View_H),
           Total_Cols      => 200,
           Visible_Cols    => 20,
           Scroll_X        => 0,
           Config          => Scrollbars);
      Minimap_Bottom : constant Float := Float (Editor.Layout.Text_Viewport_Y (Layout)) + Float (Text_H);
   begin
      Assert
        (Minimap_Bottom <= Status_Top,
         "Minimap bottom must not extend into the status bar");

      if Vertical.Visible then
         Assert
           (Vertical.Track.Y + Vertical.Track.H <= Status_Top,
            "Vertical scrollbar bottom must not extend into the status bar");
      end if;

      if Horizontal.Visible then
         Assert
           (Horizontal.Track.Y + Horizontal.Track.H <= Status_Top,
            "Horizontal scrollbar bottom must not extend into the status bar");
      end if;

      Assert
        (Editor.Minimap.Left_X (Layout, Effective_W, Minimap)
         <= Editor.Minimap.Right_X (Layout, Effective_W, Minimap),
         "Minimap horizontal geometry must remain well-formed");
   end Test_Minimap_And_Scrollbars_Do_Not_Overlap_Status_Bar;

   procedure Test_Format_Uses_One_Based_Display
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Status_Bar_Snapshot;
      Text     : Unbounded_String;
   begin
      Snapshot.File_Name := To_Unbounded_String ("main.adb");
      Snapshot.Is_Dirty := True;
      Snapshot.Cursor_Row := 41;
      Snapshot.Cursor_Column := 6;
      Snapshot.Caret_Count := 1;
      Snapshot.Selection_Count := 0;
      Snapshot.Line_Number_Mode := To_Unbounded_String ("hybrid lines");
      Snapshot.Find_Active_Match := 2;
      Snapshot.Active_Find_Match_Count := 3;
      Snapshot.Diagnostic_Count := 2;
      Text := To_Unbounded_String (Format_Right (Snapshot));
      Right := Text;

      Assert (Format_Left (Snapshot) = "main.adb *",
              "Dirty status must append a dirty marker");
      Assert (Index (Text, "Ln 42, Col 7") > 0,
              "Status bar row and column must be one-based");
      Assert (Index (Text, "hybrid lines") > 0,
              "Line-number mode must appear in formatted status text");
      Assert (Index (Text, "Find: 2 of 3") > 0,
              "Active find ordinal and match count must appear in formatted status text");
      Assert (Index (Text, "Diagnostics: 2 total") > 0,
              "Diagnostic count must appear in formatted status text");
   end Test_Format_Uses_One_Based_Display;

   procedure Test_Format_Left_Uses_Untitled_And_Dirty_Marker
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Status_Bar_Snapshot;
   begin
      Snapshot.File_Name := Null_Unbounded_String;
      Snapshot.Is_Dirty := False;
      Assert (Format_Left (Snapshot) = "Untitled",
              "Clean no-path status must show Untitled without dirty marker");

      Snapshot.Is_Dirty := True;
      Assert (Format_Left (Snapshot) = "Untitled *",
              "Dirty no-path status must show Untitled with dirty marker");
   end Test_Format_Left_Uses_Untitled_And_Dirty_Marker;


   procedure Test_Format_Includes_Project_Focus_Feature_And_Feedback
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Status_Bar_Snapshot;
      Text     : Unbounded_String;
   begin
      Snapshot.File_Name := To_Unbounded_String ("main.adb");
      Snapshot.Has_Project := True;
      Snapshot.Project_Label := To_Unbounded_String ("demo");
      Snapshot.Focus_Label := To_Unbounded_String ("Command Palette");
      Snapshot.Active_Feature_Label := To_Unbounded_String ("Outline");
      Snapshot.Has_Command_Feedback := True;
      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("ok");
      Snapshot.Command_Feedback := To_Unbounded_String ("Saved main.adb");
      Snapshot.Line_Number_Mode := To_Unbounded_String ("absolute lines");
      Text := To_Unbounded_String (Format_Right (Snapshot));
      Right := Text;

      Assert (Index (Text, "Project: demo") > 0,
              "Project label must appear in status text");
      Assert (Index (Text, "Command Palette") > 0,
              "Overlay or focus label must appear in status text");
      Assert (Index (Text, "Outline") > 0,
              "Active feature label must appear in status text");
      Assert (Index (Text, "success: Saved main.adb") > 0,
              "Latest command feedback summary must appear in status text");
   end Test_Format_Includes_Project_Focus_Feature_And_Feedback;

   procedure Test_Format_Uses_No_Project_Fallback
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Status_Bar_Snapshot;
      Text     : Unbounded_String;
   begin
      Snapshot.Has_Project := False;
      Snapshot.Focus_Label := Null_Unbounded_String;
      Snapshot.Line_Number_Mode := To_Unbounded_String ("absolute lines");
      Text := To_Unbounded_String (Format_Right (Snapshot));
      Right := Text;

      Assert (Index (Text, "No project open.") > 0,
              "No-project fallback must use the canonical wording");
      Assert (Index (Text, "Editor") > 0,
              "Empty focus label must fall back to editor focus");
      Assert (Index (Text, "No selection") > 0,
              "No active selection must be labeled explicitly");
   end Test_Format_Uses_No_Project_Fallback;


   procedure Test_Format_Shows_Find_Empty_And_No_Matches
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Status_Bar_Snapshot;
      Text     : Unbounded_String;
   begin
      Snapshot.Line_Number_Mode := To_Unbounded_String ("absolute lines");
      Snapshot.Find_Input_Open := True;
      Snapshot.Find_Query_Present := False;
      Text := To_Unbounded_String (Format_Right (Snapshot));
      Right := Text;
      Assert (Index (Text, "Find: No search query.") > 0,
              "Open find input with no query must show canonical search-query state");

      Snapshot.Find_Query_Present := True;
      Snapshot.Active_Find_Match_Count := 0;
      Text := To_Unbounded_String (Format_Right (Snapshot));
      Right := Text;
      Assert (Index (Text, "Find: No matches.") > 0,
              "Find query with zero matches must show canonical no-match state");
   end Test_Format_Shows_Find_Empty_And_No_Matches;



   procedure Test_Format_Shows_Wrapped_Find_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Status_Bar_Snapshot;
      Text     : Unbounded_String;
   begin
      Snapshot.Line_Number_Mode := To_Unbounded_String ("absolute lines");
      Snapshot.Find_Input_Open := True;
      Snapshot.Find_Query_Present := True;
      Snapshot.Find_Active_Match := 1;
      Snapshot.Active_Find_Match_Count := 5;
      Snapshot.Find_Wrapped := True;
      Text := To_Unbounded_String (Format_Right (Snapshot));
      Right := Text;
      Assert (Index (Text, "Find: 1 of 5 wrapped") > 0,
              "status bar must show concise wrapped find state");
   end Test_Format_Shows_Wrapped_Find_State;

   procedure Test_Render_Emits_Status_Bar_Layers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Prepare_Text;
      Editor.Input_Bridge.Build_Render_Packet (Packet);
      Assert
        (Rect_Count_On_Layer
           (Packet, Editor.Render_Layers.Status_Bar_Background_Layer) > 0,
         "Status bar background rect must be emitted");
      Assert
        (Glyph_Count_On_Layer
           (Packet, Editor.Render_Layers.Status_Bar_Text_Layer) > 0,
         "Status bar text glyphs must be emitted");
      Assert
        (Editor.Render_Layers.Order (Editor.Render_Layers.Status_Bar_Text_Layer)
         < Editor.Render_Layers.Order (Editor.Render_Layers.Palette_Background_Layer),
         "Command palette must remain above status bar text");
      Assert
        (Editor.Render_Layers.Order (Editor.Render_Layers.Status_Bar_Background_Layer)
         > Editor.Render_Layers.Order (Editor.Render_Layers.Caret_Layer),
         "Status bar background must draw above editor text and caret");
   end Test_Render_Emits_Status_Bar_Layers;

   procedure Test_Click_In_Status_Bar_Does_Not_Move_Caret
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Cmd    : Editor.Commands.Command;
      Before : Editor.Render_Model.Render_Snapshot;
      After  : Editor.Render_Model.Render_Snapshot;
   begin
      Prepare_Text;
      Editor.Input_Bridge.Get_Render_Snapshot (Before);

      Cmd.Kind := Editor.Commands.Move_To_Point;
      Cmd.Click_X := Layout.Origin_X + 10;
      Cmd.Click_Y := Natural (Editor.Layout.Status_Bar_Y
        (Layout, Editor.View.Viewport_Height)) + 1;
      Editor.Input_Bridge.Handle (Cmd);

      Editor.Input_Bridge.Get_Render_Snapshot (After);
      Assert
        (After.Primary_Caret_Row = Before.Primary_Caret_Row
         and then After.Primary_Caret_Col = Before.Primary_Caret_Col,
         "Click inside status bar must not move caret");
   end Test_Click_In_Status_Bar_Does_Not_Move_Caret;

   procedure Test_Narrow_Text_Viewport_Keeps_Caret_Visible
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Snap   : Editor.Render_Model.Render_Snapshot;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Width  : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ");
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
           (Pos                   => 40,
            Anchor                => 40,
            Virtual_Column        => 40,
            Anchor_Virtual_Column => 40));

      Editor.View.Reset_Scroll;
      Editor.Scrollbars.Reset;
      Width := Editor.Layout.Text_Origin_X (Layout, 1)
        + Editor.Layout.Cell_W
        + Editor.Scrollbars.Current.Thickness;
      Editor.View.Set_Viewport (Width, 10 * Editor.Layout.Cell_H);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Editor.View.Update_Scroll_For_Snapshot (Snap, Layout);

      Assert (Editor.View.Scroll_X > 0,
              "one-column text viewport must scroll horizontally to the caret");
      Assert (Editor.View.Scroll_X <= Snap.Primary_Caret_Col,
              "horizontal scroll must remain bounded by caret column");
      Assert (not Editor.State.Is_Dirty (S),
              "viewport scrolling must not dirty the buffer");
   end Test_Narrow_Text_Viewport_Keeps_Caret_Visible;

   procedure Test_Zero_Row_Text_Viewport_Emits_No_Text_Glyphs
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "visible text must be clipped");
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (80 * Editor.Layout.Cell_W, Editor.Layout.Cell_H);

      Editor.Render_Packet.Build_Render_Packet (Packet);

      Assert
        (Glyph_Count_On_Layer (Packet, Editor.Render_Layers.Text_Layer) = 0,
         "zero-row text viewport must not emit editor text glyphs");
      Assert
        (Glyph_Count_On_Layer (Packet, Editor.Render_Layers.Gutter_Text_Layer) = 0,
         "zero-row text viewport must not emit gutter glyphs");
   end Test_Zero_Row_Text_Viewport_Emits_No_Text_Glyphs;


   procedure Test_Format_Shows_Selection_Detail
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Status_Bar_Snapshot;
      Text     : Unbounded_String;
   begin
      Snapshot.Line_Number_Mode := To_Unbounded_String ("absolute lines");
      Snapshot.Selection_Count := 1;
      Snapshot.Selected_Character_Count := 7;
      Snapshot.Selected_Line_Count := 2;
      Text := To_Unbounded_String (Format_Right (Snapshot));
      Right := Text;
      Assert (Index (Text, "Selected: 7 chars, 2 lines") > 0,
              "selection status must show selected character and line counts");

      Snapshot.Selected_Character_Count := 0;
      Snapshot.Rectangular_Selection_Active := True;
      Text := To_Unbounded_String (Format_Right (Snapshot));
      Right := Text;
      Assert (Index (Text, "rect selection") > 0,
              "rectangular selection status must be explicit");
   end Test_Format_Shows_Selection_Detail;


   procedure Test_Format_Shows_File_State_And_Feature_Summaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Status_Bar_Snapshot;
      Left_Text : Unbounded_String;
      Right_Text : Unbounded_String;
   begin
      Snapshot.File_Label := To_Unbounded_String ("src/main.adb");
      Snapshot.Buffer_Kind_Label := To_Unbounded_String ("File-backed");
      Snapshot.File_State_Label := To_Unbounded_String ("Modified");
      Snapshot.Is_Dirty := True;
      Snapshot.Line_Number_Mode := To_Unbounded_String ("absolute lines");
      Snapshot.Undo_Redo_Label := To_Unbounded_String ("Undo available");
      Snapshot.Pending_Confirmation_Label :=
        To_Unbounded_String ("Confirmation required: Close dirty buffer?");
      Snapshot.Outline_Status_Label := To_Unbounded_String ("Outline: 3 symbols");
      Snapshot.Diagnostics_Status_Label :=
        To_Unbounded_String ("Diagnostics: 1 error, 2 warnings");
      Snapshot.Build_Status_Label :=
        To_Unbounded_String ("Build: succeeded, duration 4.3 s");
      Snapshot.Search_Status_Label := To_Unbounded_String ("Search: 4 results");

      Left_Text := To_Unbounded_String (Format_Left (Snapshot));
      Right_Text := To_Unbounded_String (Format_Right (Snapshot));
      Right := Right_Text;

      Assert (Index (Left_Text, "src/main.adb *") > 0,
              "status must display active file label and dirty marker");
      Assert (Index (Left_Text, "File-backed") > 0,
              "status must display file-backed/scratch kind");
      Assert (Index (Left_Text, "Modified") > 0,
              "status must display known file state");
      Assert (Index (Right_Text, "Undo available") > 0,
              "status must display undo/redo availability label");
      Assert (Index (Right_Text, "Confirmation required") > 0,
              "status must display pending confirmation state");
      Assert (Index (Right_Text, "Outline: 3 symbols") > 0,
              "status must display outline summary");
      Assert (Index (Right_Text, "Diagnostics: 1 error, 2 warnings") > 0,
              "status must display diagnostic severity summary");
      Assert (Index (Right_Text, "Build: succeeded, duration 4.3 s") > 0,
              "status must display build summary with duration");
      Assert (Index (Right_Text, "Search: 4 results") > 0,
              "status must display project-search summary");
   end Test_Format_Shows_File_State_And_Feature_Summaries;


   procedure Test_No_Buffer_And_Selection_Line_Fallback
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Status_Bar_Snapshot;
      Text     : Unbounded_String;
   begin
      Snapshot.Has_Active_Buffer := False;
      Snapshot.Buffer_Kind_Label := To_Unbounded_String ("No buffer");
      Snapshot.File_State_Label := To_Unbounded_String ("Unavailable");
      Assert (Index (To_Unbounded_String (Format_Left (Snapshot)),
                     "No active buffer.") > 0,
              "status must show an explicit no-active-buffer label");
      Assert (Index (To_Unbounded_String (Format_Right (Snapshot)),
                     "No caret") > 0,
              "status must not fabricate line/column for no active buffer");
      Assert (Status_Dirty_File_State_Segment (Snapshot) = "No active buffer.",
              "no-active-buffer dirty/state segment must be canonical at source");
      Assert (Assert_Status_Summarizes_Main_Context (Snapshot),
              "no-active-buffer status coherence must accept canonical text");

      Snapshot.Has_Active_Buffer := True;
      Snapshot.Line_Number_Mode := To_Unbounded_String ("absolute lines");
      Snapshot.Selected_Character_Count := 5;
      Snapshot.Selected_Line_Count := 0;
      Text := To_Unbounded_String (Format_Right (Snapshot));
      Right := Text;
      Assert (Index (Text, "Selected: 5 chars, 1 line") > 0,
              "selection status must not expose a zero-line selected-text summary");
   end Test_No_Buffer_And_Selection_Line_Fallback;

   procedure Test_Status_Coherence_Assertions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Status_Bar_Snapshot;
   begin
      Snapshot.File_Label := To_Unbounded_String ("src/main.adb");
      Snapshot.Is_Dirty := True;
      Snapshot.Cursor_Row := 0;
      Snapshot.Cursor_Column := 0;
      Snapshot.Selection_Count := 0;
      Snapshot.Line_Number_Mode := To_Unbounded_String ("absolute lines");
      Snapshot.Has_Command_Feedback := True;
      Snapshot.Command_Feedback := To_Unbounded_String ("Saved src/main.adb");
      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("ok");

      Assert (Assert_Status_Snapshot_Is_Observational (Snapshot),
              "status snapshot must be observational scalar display data");
      Assert (Assert_Status_Shows_Active_Buffer_And_Dirty_State (Snapshot),
              "status must show active buffer label and dirty state");
      Assert (Assert_Status_Shows_Caret_And_Selection (Snapshot),
              "status must show caret and selection context");
      Assert (Assert_Status_Shows_Command_Outcome (Snapshot),
              "status must show latest command outcome when present");
      Assert (Assert_Status_Does_Not_Copy_Feature_Rows (Snapshot),
              "status must not own copied feature rows");
      Assert (Assert_Status_Shows_Feature_Summaries (Snapshot),
              "status must show compact feature summaries");
      Assert (Assert_Status_State_Not_Persisted (Snapshot),
              "status contents must remain outside persistence domains");
      Assert (Assert_Editing_Status_And_Feedback_Coherent (Snapshot),
              "status milestone assertion must be coherent");
   end Test_Status_Coherence_Assertions;


   procedure Test_Project_State_Label_Overrides_Project_Fallback
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Status_Bar_Snapshot;
      Text     : Unbounded_String;
   begin
      Snapshot.Has_Project := True;
      Snapshot.Project_Label := To_Unbounded_String ("demo");
      Snapshot.Project_State_Label := To_Unbounded_String ("Project switch pending");
      Snapshot.Line_Number_Mode := To_Unbounded_String ("absolute lines");

      Text := To_Unbounded_String (Format_Right (Snapshot));
      Right := Text;

      Assert (Index (Text, "Project switch pending") > 0,
              "status must expose project switch pending state directly");
      Assert (Index (Text, "Project: demo") = 0,
              "project pending state must not be hidden behind ordinary project label");
   end Test_Project_State_Label_Overrides_Project_Fallback;


   procedure Test_Coherence_Rejects_Missing_Buffer_Label
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Status_Bar_Snapshot;
   begin
      Snapshot.Has_Active_Buffer := True;
      Snapshot.Line_Number_Mode := To_Unbounded_String ("absolute lines");

      Assert (not Assert_Editing_Status_And_Feedback_Coherent (Snapshot),
              "milestone guard must reject active-buffer status with no visible buffer label");

      Snapshot.File_Label := To_Unbounded_String ("src/main.adb");
      Assert (Assert_Editing_Status_And_Feedback_Coherent (Snapshot),
              "milestone guard must accept a visible active-buffer label");
   end Test_Coherence_Rejects_Missing_Buffer_Label;



   procedure Test_Format_Shows_Focus_Mode_And_Overlay_Marker
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Status_Bar_Snapshot;
   begin
      Snapshot.Has_Active_Buffer := True;
      Snapshot.File_Label := To_Unbounded_String ("src/main.adb");
      Snapshot.Line_Number_Mode := To_Unbounded_String ("absolute lines");
      Snapshot.Focus_Label := To_Unbounded_String ("Project Replace");
      Snapshot.Active_Panel_Label := To_Unbounded_String ("Project Search");
      Snapshot.Input_Mode_Label := To_Unbounded_String ("Overlay Text");
      Snapshot.Overlay_Query_Active := True;

      declare
         Text : constant String := Format_Right (Snapshot);
      begin
         Assert (Index (Text, "Project Replace") > 0,
                 "status should show the effective focus owner");
         Assert (Index (Text, "Panel: Project Search") > 0,
                 "status should show the active panel label");
         Assert (Index (Text, "Mode: Overlay Text") > 0,
                 "status should show the input mode label");
         Assert (Index (Text, "Overlay input") > 0,
                 "status should show active overlay/input ownership");
         Assert (Assert_Editing_Status_And_Feedback_Coherent (Snapshot),
                 "status coherence should accept focus/mode projection fields");
      end;
   end Test_Format_Shows_Focus_Mode_And_Overlay_Marker;



   procedure Test_Format_Shows_Main_Context_Summaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Status_Bar_Snapshot;
      Text     : Unbounded_String;
   begin
      Snapshot.Has_Active_Buffer := True;
      Snapshot.File_Label := To_Unbounded_String ("src/main.adb");
      Snapshot.Buffer_Kind_Label := To_Unbounded_String ("File-backed");
      Snapshot.File_State_Label := To_Unbounded_String ("Missing on disk");
      Snapshot.Is_Dirty := True;
      Snapshot.Cursor_Row := 11;
      Snapshot.Cursor_Column := 6;
      Snapshot.Selected_Character_Count := 12;
      Snapshot.Selected_Line_Count := 3;
      Snapshot.Has_Project := True;
      Snapshot.Project_Label := To_Unbounded_String ("demo");
      Snapshot.Focus_Label := To_Unbounded_String ("Quick Open");
      Snapshot.Active_Panel_Label := To_Unbounded_String ("File Tree");
      Snapshot.Pending_Confirmation_Label :=
        To_Unbounded_String ("Pending confirmation");
      Snapshot.Has_Command_Feedback := True;
      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("error");
      Snapshot.Command_Feedback := To_Unbounded_String ("Close cancelled");
      Snapshot.Build_Status_Label := To_Unbounded_String ("Build: failed");
      Snapshot.Diagnostics_Status_Label :=
        To_Unbounded_String ("Diagnostics: 3 errors, 2 warnings");
      Snapshot.Search_Status_Label := To_Unbounded_String ("Replace: preview 8 replacements");
      Snapshot.Quick_Open_Status_Label := To_Unbounded_String ("Quick Open: 8 matches");
      Snapshot.Outline_Status_Label := To_Unbounded_String ("Current: procedure Run");
      Snapshot.File_Tree_Status_Label := To_Unbounded_String ("File Tree: refresh required");
      Snapshot.Workspace_Status_Label := To_Unbounded_String ("Workspace: restore feedback");
      Snapshot.Recent_Projects_Status_Label :=
        To_Unbounded_String ("Recent Projects: 2 entries, 1 missing");
      Snapshot.Line_Number_Mode := To_Unbounded_String ("absolute lines");

      Text := To_Unbounded_String (Format_Right (Snapshot));
      Right := Text;

      Assert (Index (Format_Left (Snapshot), "src/main.adb *") > 0,
              "status must show active file and dirty marker");
      Assert (Index (Format_Left (Snapshot), "Missing on disk") > 0,
              "status must show known missing-file state");
      Assert (Index (Text, "Pending confirmation") > 0,
              "status must surface pending confirmation state");
      Assert (Index (Text, "failed: Close cancelled") > 0,
              "status must surface latest failed command outcome");
      Assert (Occurrence_Count (To_String (Text), "Pending confirmation") = 1,
              "status must not duplicate pending confirmation summaries");
      Assert (Occurrence_Count (To_String (Text), "failed: Close cancelled") = 1,
              "status must not duplicate latest command outcomes");
      Assert (Index (Text, "Project: demo") > 0,
              "status must show active project context");
      Assert (Index (Text, "Quick Open") > 0,
              "status must show focus owner or Quick Open summary");
      Assert (Index (Text, "Panel: File Tree") > 0,
              "status must show active panel context");
      Assert (Index (Text, "Ln 12, Col 7") > 0,
              "status must show one-based caret location");
      Assert (Index (Text, "Selected: 12 chars, 3 lines") > 0,
              "status must show selection summary");
      Assert (Index (Text, "Build: failed") > 0,
              "status must show Build summary");
      Assert (Index (Text, "Diagnostics: 3 errors, 2 warnings") > 0,
              "status must show Diagnostics summary counts");
      Assert (Index (Text, "Replace: preview 8 replacements") > 0,
              "status must show Project Search/replace summary");
      Assert (Index (Text, "Quick Open: 8 matches") > 0,
              "status must show Quick Open summary when relevant");
      Assert (Index (Text, "Current: procedure Run") > 0,
              "status must show Outline/current-symbol summary");
      Assert (Index (Text, "File Tree: refresh required") > 0,
              "status must show File Tree staleness/availability summary");
      Assert (Index (Text, "Workspace: restore feedback") > 0,
              "status may show latest workspace summary feedback");
      Assert (Index (Text, "Recent Projects: 2 entries, 1 missing") > 0,
              "status may show Recent Projects summary feedback");
      Assert (Assert_Status_Line_Context_Coherent (Snapshot),
              "milestone status line assertion must accept coherent context");
   end Test_Format_Shows_Main_Context_Summaries;

   procedure Test_Status_Truncates_Long_Labels_Deterministically
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Status_Bar_Snapshot;
      Long_Text : constant String :=
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-extra";
      Truncated : constant String := Status_Truncate_Label (Long_Text, 12);
   begin
      Assert (Truncated'Length = 12,
              "truncation helper must obey the requested bound");
      Assert (Truncated (Truncated'Last .. Truncated'Last) = ".",
              "truncation helper must mark truncated status labels");

      Snapshot.Has_Active_Buffer := True;
      Snapshot.File_Label := To_Unbounded_String (Long_Text);
      Snapshot.Line_Number_Mode := To_Unbounded_String ("absolute lines");
      Snapshot.Has_Command_Feedback := True;
      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("error");
      Snapshot.Command_Feedback := To_Unbounded_String (Long_Text);

      Assert (Index (Format_Left (Snapshot), "...") > 0,
              "left status must deterministically truncate long labels");
      Assert (Index (Format_Right (Snapshot), "...") > 0,
              "right status must deterministically truncate long labels");
   end Test_Status_Truncates_Long_Labels_Deterministically;



   procedure Test_Status_Coherence_Covers_Main_Context
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Status_Bar_Snapshot;
   begin
      Snapshot.Has_Active_Buffer := True;
      Snapshot.File_Label := To_Unbounded_String ("src/main.adb");
      Snapshot.File_State_Label := To_Unbounded_String ("Read-only");
      Snapshot.Has_Project := True;
      Snapshot.Project_Label := To_Unbounded_String ("demo");
      Snapshot.Focus_Label := To_Unbounded_String ("Diagnostics");
      Snapshot.Active_Panel_Label := To_Unbounded_String ("Diagnostics");
      Snapshot.Pending_Confirmation_Label :=
        To_Unbounded_String ("Pending confirmation");
      Snapshot.Has_Command_Feedback := True;
      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("unavailable");
      Snapshot.Command_Feedback := To_Unbounded_String ("No active target");
      Snapshot.Build_Status_Label := To_Unbounded_String ("Build: consent required");
      Snapshot.Diagnostics_Status_Label := To_Unbounded_String ("Diagnostics: stale targets");
      Snapshot.Search_Status_Label := To_Unbounded_String ("Search: limit reached");
      Snapshot.Quick_Open_Status_Label := To_Unbounded_String ("Quick Open: no matches");
      Snapshot.Outline_Status_Label := To_Unbounded_String ("Outline: stale");
      Snapshot.File_Tree_Status_Label := To_Unbounded_String ("File Tree: stale node");
      Snapshot.Line_Number_Mode := To_Unbounded_String ("absolute lines");

      Assert (Assert_Status_Summarizes_Main_Context (Snapshot),
              "main-context assertion must cover scalar subsystem summaries");
      Assert (Assert_Status_Does_Not_Duplicate_Priority_Segments (Snapshot),
              "priority status assertion must reject duplicated pending/outcome text");
      Assert (Assert_Status_Line_Context_Coherent (Snapshot),
              "coherent status assertion must accept a full scalar context snapshot");
   end Test_Status_Coherence_Covers_Main_Context;


   procedure Test_Dirty_State_Label_And_Compact_Bounds
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Status_Bar_Snapshot;
      Compact  : Unbounded_String;
   begin
      Snapshot.Has_Active_Buffer := True;
      Snapshot.File_Label := To_Unbounded_String ("src/very_long_status_target.adb");
      Snapshot.Is_Dirty := True;
      Snapshot.Dirty_State_Label := To_Unbounded_String ("Modified");
      Snapshot.Has_Project := True;
      Snapshot.Project_Label := To_Unbounded_String ("demo");
      Snapshot.Focus_Label := To_Unbounded_String ("Editor");
      Snapshot.Build_Status_Label := To_Unbounded_String ("Build: succeeded");
      Snapshot.Diagnostics_Status_Label := To_Unbounded_String ("Diagnostics: none");
      Snapshot.Search_Status_Label := To_Unbounded_String ("Search: no query");
      Snapshot.Outline_Status_Label := To_Unbounded_String ("Outline: not refreshed");
      Snapshot.Line_Number_Mode := To_Unbounded_String ("absolute lines");

      Compact := To_Unbounded_String (Status_Layout_Compact (Snapshot, 48));

      Assert (Index (Format_Left (Snapshot), "Modified") > 0,
              "status must be able to show explicit dirty-state label text");
      Assert (Length (Compact) <= 48,
              "compact status projection must honor the viewport column bound");
      Assert (Index (Compact, "...") > 0,
              "compact status projection must deterministically mark truncation");
      Assert (Assert_Status_Layout_Is_Bounded (Snapshot, 48),
              "bounded-layout assertion must accept compact status projection");
   end Test_Dirty_State_Label_And_Compact_Bounds;


   procedure Test_Status_Layout_Handles_Zero_Width
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Status_Bar_Snapshot;
   begin
      Snapshot.Has_Active_Buffer := True;
      Snapshot.File_Label := To_Unbounded_String ("src/main.adb");
      Snapshot.Line_Number_Mode := To_Unbounded_String ("absolute lines");

      Assert (Status_Layout_Compact (Snapshot, 0) = "",
              "compact status projection must tolerate zero-column layout");
      Assert (Assert_Status_Layout_Is_Bounded (Snapshot, 0),
              "bounded-layout assertion must accept zero-column layout");
   end Test_Status_Layout_Handles_Zero_Width;


   procedure Test_File_State_Marker_Assertion_Covers_Known_States
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Status_Bar_Snapshot;
      Left     : Unbounded_String;
   begin
      Snapshot.Has_Active_Buffer := True;
      Snapshot.File_Label := To_Unbounded_String ("../outside/main.adb");
      Snapshot.Buffer_Kind_Label :=
        To_Unbounded_String ("File-backed, outside project");
      Snapshot.File_State_Label := To_Unbounded_String ("Missing on disk");
      Snapshot.Dirty_State_Label := To_Unbounded_String ("Modified");
      Snapshot.Is_Dirty := True;

      Left := To_Unbounded_String (Format_Left (Snapshot));

      Assert (Index (To_String (Left), "File-backed, outside project") > 0,
              "status must show known outside-project/file-backed marker");
      Assert (Index (To_String (Left), "Missing on disk") > 0,
              "status must show known missing backing-file marker");
      Assert (Index (To_String (Left), "Modified") > 0,
              "status must show explicit dirty-state label when provided");
      Assert (Assert_Status_Shows_File_State_Markers (Snapshot),
              "marker assertion must cover scalar file-state labels");
   end Test_File_State_Marker_Assertion_Covers_Known_States;


   procedure Test_Non_Priority_Command_Outcome_Appears_Once
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Status_Bar_Snapshot;
      Text     : Unbounded_String;
   begin
      Snapshot.Has_Active_Buffer := True;
      Snapshot.File_Label := To_Unbounded_String ("src/main.adb");
      Snapshot.Line_Number_Mode := To_Unbounded_String ("absolute lines");
      Snapshot.Has_Command_Feedback := True;
      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("ok");
      Snapshot.Command_Feedback := To_Unbounded_String ("Saved src/main.adb");

      Text := To_Unbounded_String (Format_Right (Snapshot));
      Right := Text;

      Assert (Occurrence_Count (To_String (Text), "success: Saved src/main.adb") = 1,
              "non-priority command outcome must appear exactly once");
      Assert (Assert_Status_Does_Not_Duplicate_Priority_Segments (Snapshot),
              "duplicate guard must also cover ordinary latest outcomes");
   end Test_Non_Priority_Command_Outcome_Appears_Once;



   procedure Test_Segment_Builders_Are_Coherent_And_Scalar
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Status_Bar_Snapshot;
      Right    : Unbounded_String;
   begin
      Snapshot.Has_Active_Buffer := True;
      Snapshot.File_Label := To_Unbounded_String ("src/main.adb");
      Snapshot.Cursor_Row := 4;
      Snapshot.Cursor_Column := 8;
      Snapshot.Selection_Count := 1;
      Snapshot.Has_Project := True;
      Snapshot.Project_Label := To_Unbounded_String ("demo");
      Snapshot.Focus_Label := To_Unbounded_String ("Project Search");
      Snapshot.Active_Panel_Label := To_Unbounded_String ("Project Search");
      Snapshot.Build_Status_Label := To_Unbounded_String ("Build: output truncated");
      Snapshot.Diagnostic_Count := 5;
      Snapshot.Search_Status_Label := To_Unbounded_String ("Search: stale");
      Snapshot.Quick_Open_Status_Label := To_Unbounded_String ("Quick Open: stale result");
      Snapshot.Outline_Status_Label := To_Unbounded_String ("Outline: stale");
      Snapshot.File_Tree_Status_Label := To_Unbounded_String ("File Tree: refresh required");
      Snapshot.Workspace_Status_Label := To_Unbounded_String ("Workspace: restore partial");
      Snapshot.Recent_Projects_Status_Label := To_Unbounded_String ("Recent Projects: 3 entries");
      Snapshot.Has_Command_Feedback := True;
      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("cancelled");
      Snapshot.Command_Feedback := To_Unbounded_String ("Close cancelled");
      Snapshot.Line_Number_Mode := To_Unbounded_String ("absolute lines");

      Right := To_Unbounded_String (Format_Right (Snapshot));

      Assert (Status_Project_Segment (Snapshot) = "Project: demo",
              "project segment builder must be scalar and user-readable");
      Assert (Index (Status_Caret_Selection_Segment (Snapshot), "Ln 5, Col 9") > 0,
              "caret/selection segment builder must use one-based display");
      Assert (Status_Diagnostics_Segment (Snapshot) = "Diagnostics: 5 total",
              "diagnostics fallback must be a named total-count summary");
      Assert (Index (To_String (Right), Status_Build_Segment (Snapshot)) > 0,
              "Build segment builder must match the rendered status surface");
      Assert (Index (To_String (Right), Status_Search_Replace_Segment (Snapshot)) > 0,
              "Search segment builder must match the rendered status surface");
      Assert (Index (To_String (Right), Status_Quick_Open_Segment (Snapshot)) > 0,
              "Quick Open segment builder must match the rendered status surface");
      Assert (Index (To_String (Right), Status_Outline_Segment (Snapshot)) > 0,
              "Outline segment builder must match the rendered status surface");
      Assert (Index (To_String (Right), Status_File_Tree_Segment (Snapshot)) > 0,
              "File Tree segment builder must match the rendered status surface");
      Assert (Index (Status_Workspace_Recent_Segment (Snapshot), "Workspace: restore partial") > 0,
              "workspace/recent segment builder must keep summaries compact");
      Assert (Assert_Status_Segment_Builders_Are_Coherent (Snapshot),
              "segment-builder assertion must accept coherent scalar summaries");
      Assert (Assert_Status_Line_Context_Coherent (Snapshot),
              "milestone assertion must include segment-builder coherence");
   end Test_Segment_Builders_Are_Coherent_And_Scalar;


   procedure Test_Status_Is_Explicit_Focus_And_Single_Line
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Status_Bar_Snapshot;
      Left     : Unbounded_String;
      Right    : Unbounded_String;
   begin
      Snapshot.Has_Active_Buffer := True;
      Snapshot.File_Label := To_Unbounded_String ("src/main" & ASCII.LF & "adb");
      Snapshot.Has_Project := True;
      Snapshot.Project_Label := To_Unbounded_String ("demo" & ASCII.HT & "project");
      Snapshot.Focus_Label := To_Unbounded_String ("Diagnostics");
      Snapshot.Active_Panel_Label := To_Unbounded_String ("Diagnostics");
      Snapshot.Pending_Confirmation_Label :=
        To_Unbounded_String ("Pending" & ASCII.LF & "confirmation");
      Snapshot.Has_Command_Feedback := True;
      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("failed");
      Snapshot.Command_Feedback :=
        To_Unbounded_String ("Build" & ASCII.LF & "failed");
      Snapshot.Line_Number_Mode := To_Unbounded_String ("absolute lines");

      Left := To_Unbounded_String (Format_Left (Snapshot));
      Right := To_Unbounded_String (Format_Right (Snapshot));

      Assert (Index (To_String (Right), "Focus: Diagnostics") > 0,
              "status must label the focus owner explicitly");
      Assert (Index (To_String (Right), "Panel: Diagnostics") > 0,
              "status must keep the active panel visible even when it owns focus");
      Assert (Index (To_String (Left), String'(1 => ASCII.LF)) = 0,
              "left status must normalize embedded newlines");
      Assert (Index (To_String (Right), String'(1 => ASCII.LF)) = 0,
              "right status must normalize embedded newlines");
      Assert (Index (To_String (Right), String'(1 => ASCII.HT)) = 0,
              "right status must normalize embedded tabs");
      Assert (Assert_Status_Is_Single_Line (Snapshot),
              "status assertion must require a single-line status surface");
      Assert (Assert_Status_Line_Context_Coherent (Snapshot),
              "milestone assertion must include single-line status safety");
   end Test_Status_Is_Explicit_Focus_And_Single_Line;


   procedure Test_Command_Outcome_Uses_Public_Classes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Status_Bar_Snapshot;
      Text     : Unbounded_String;
   begin
      Snapshot.Has_Active_Buffer := True;
      Snapshot.File_Label := To_Unbounded_String ("src/main.adb");
      Snapshot.Has_Project := True;
      Snapshot.Project_Label := To_Unbounded_String ("demo");
      Snapshot.Line_Number_Mode := To_Unbounded_String ("absolute lines");
      Snapshot.Has_Command_Feedback := True;
      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("warn");
      Snapshot.Command_Feedback := To_Unbounded_String ("Command unavailable");

      Text := To_Unbounded_String (Format_Right (Snapshot));
      Right := Text;

      Assert (Status_Command_Outcome_Class (Snapshot) = "unavailable",
              "status must map internal warn severity to public unavailable class");
      Assert (Index (To_String (Text), "unavailable: Command unavailable") > 0,
              "status must render the public unavailable command outcome class");
      Assert (Index (To_String (Text), "warn:") = 0,
              "status must not expose internal warn severity spelling");
      Assert (Assert_Status_Command_Outcome_Uses_Public_Classes (Snapshot),
              "command outcome assertion must accept public status classes only");

      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("mystery-internal-severity");
      Snapshot.Command_Feedback := To_Unbounded_String ("Informational fallback");
      Text := To_Unbounded_String (Format_Right (Snapshot));
      Right := Text;

      Assert (Status_Command_Outcome_Class (Snapshot) = "info",
              "status must map unknown internal message classes to public info class");
      Assert (Index (To_String (Text), "info: Informational fallback") > 0,
              "status must render unknown internal classes as info");
      Assert (Assert_Status_Line_Context_Coherent (Snapshot),
              "milestone assertion must include public command-outcome classes");
   end Test_Command_Outcome_Uses_Public_Classes;


   procedure Test_Status_Config_And_Payload_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Status_Bar_Snapshot;
      Enabled_Config  : constant Status_Bar_Config := (Enabled => True);
      Disabled_Config : constant Status_Bar_Config := (Enabled => False);
   begin
      Snapshot.Has_Active_Buffer := True;
      Snapshot.File_Label := To_Unbounded_String ("src/main.adb");
      Snapshot.Has_Project := True;
      Snapshot.Project_Label := To_Unbounded_String ("demo");
      Snapshot.Line_Number_Mode := To_Unbounded_String ("absolute lines");
      Snapshot.Pending_Confirmation_Label :=
        To_Unbounded_String ("Pending confirmation");
      Snapshot.Has_Command_Feedback := True;
      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("pending");
      Snapshot.Command_Feedback := To_Unbounded_String ("Waiting for confirmation");

      Assert (Assert_Status_Config_Is_Display_Only (Enabled_Config),
              "enabled status config must be display-only");
      Assert (Assert_Status_Config_Is_Display_Only (Disabled_Config),
              "disabled status config must also be display-only");
      Assert (Assert_Status_Carries_No_Command_Payloads (Snapshot),
              "status snapshot must not carry command/keybinding/palette payloads");
      Assert (Assert_Status_Command_Outcome_Uses_Public_Classes (Snapshot),
              "pending status outcome must use a public class");
      Assert (Assert_Status_Line_Context_Coherent (Snapshot),
              "milestone assertion must include config/payload boundary coverage");
   end Test_Status_Config_And_Payload_Boundaries;


   procedure Test_Project_File_And_Row_Output_Boundary
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Status_Bar_Snapshot;
      Project_File : Unbounded_String;
      File_State   : Unbounded_String;
   begin
      Snapshot.Has_Active_Buffer := True;
      Snapshot.File_Label := To_Unbounded_String ("src/main.adb");
      Snapshot.Buffer_Kind_Label := To_Unbounded_String ("File-backed");
      Snapshot.File_State_Label := To_Unbounded_String ("Read-only");
      Snapshot.Is_Dirty := True;
      Snapshot.Dirty_State_Label := To_Unbounded_String ("Modified");
      Snapshot.Has_Project := True;
      Snapshot.Project_Label := To_Unbounded_String ("demo");
      Snapshot.Line_Number_Mode := To_Unbounded_String ("absolute lines");
      Snapshot.Diagnostics_Status_Label := To_Unbounded_String ("Diagnostics: 1 error, 0 warnings");
      Snapshot.Build_Status_Label := To_Unbounded_String ("Build: failed, output truncated");
      Snapshot.Search_Status_Label := To_Unbounded_String ("Search: 12 results");
      Snapshot.Outline_Status_Label := To_Unbounded_String ("Current: procedure Run");

      Project_File := To_Unbounded_String (Status_Project_File_Segment (Snapshot));
      File_State := To_Unbounded_String (Status_Dirty_File_State_Segment (Snapshot));

      Assert (Index (To_String (Project_File), "Project: demo") > 0,
              "project/file segment must include project context");
      Assert (Index (To_String (Project_File), "src/main.adb") > 0,
              "project/file segment must include active file context");
      Assert (Index (To_String (File_State), "File-backed") > 0,
              "file-state segment must include known backing kind");
      Assert (Index (To_String (File_State), "Read-only") > 0,
              "file-state segment must include known read-only marker");
      Assert (Index (To_String (File_State), "Modified") > 0,
              "file-state segment must include dirty marker text");
      Assert (Assert_Status_Does_Not_Copy_Rows_Or_Output (Snapshot),
              "status boundary must remain scalar and exclude rows/output bodies");
      Assert (Assert_Status_Line_Context_Coherent (Snapshot),
              "milestone assertion must include project/file and row-output boundaries");
   end Test_Project_File_And_Row_Output_Boundary;


   procedure Test_Compact_Layout_Preserves_Priority
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Status_Bar_Snapshot;
      Compact  : Unbounded_String;
   begin
      Snapshot.Has_Active_Buffer := True;
      Snapshot.File_Label :=
        To_Unbounded_String
          ("src/very/long/path/that/would/otherwise/eat/the/status/line/main.adb");
      Snapshot.Has_Project := True;
      Snapshot.Project_Label := To_Unbounded_String ("demo");
      Snapshot.Line_Number_Mode := To_Unbounded_String ("absolute lines");
      Snapshot.Pending_Confirmation_Label :=
        To_Unbounded_String ("Pending confirmation");
      Snapshot.Has_Command_Feedback := True;
      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("error");
      Snapshot.Command_Feedback := To_Unbounded_String ("Save blocked");
      Snapshot.Diagnostics_Status_Label :=
        To_Unbounded_String ("Diagnostics: 3 errors, 2 warnings");
      Snapshot.Build_Status_Label := To_Unbounded_String ("Build: failed");

      Compact := To_Unbounded_String (Status_Layout_Compact (Snapshot, 64));

      Assert (Index (To_String (Compact), "Pending confirmation") = 1,
              "compact layout must put pending confirmation first");
      Assert (Index (To_String (Compact), "failed: Save blocked") > 0,
              "compact layout must keep failed/unavailable outcomes early");
      Assert (Assert_Status_Layout_Preserves_Priority (Snapshot),
              "priority assertion must protect compact status ordering");
      Assert (Assert_Status_Line_Context_Coherent (Snapshot),
              "milestone assertion must include priority layout coverage");
   end Test_Compact_Layout_Preserves_Priority;


   procedure Test_Render_Compact_Policy_Uses_Priority_Context
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Status_Bar_Snapshot;
   begin
      Snapshot.Has_Active_Buffer := True;
      Snapshot.File_Label := To_Unbounded_String ("src/main.adb");
      Snapshot.Has_Project := True;
      Snapshot.Project_Label := To_Unbounded_String ("demo");

      Assert (Status_Layout_Should_Use_Compact (Snapshot, 40),
              "render policy must use compact projection for narrow status rows");
      Assert (not Status_Layout_Should_Use_Compact (Snapshot, 120),
              "render policy may keep left/right layout for wide non-priority rows");

      Snapshot.Pending_Confirmation_Label :=
        To_Unbounded_String ("Pending confirmation");
      Assert (Status_Layout_Should_Use_Compact (Snapshot, 120),
              "render policy must use compact projection when confirmation is pending");

      Snapshot.Pending_Confirmation_Label := Null_Unbounded_String;
      Snapshot.Has_Command_Feedback := True;
      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("warning");
      Snapshot.Command_Feedback := To_Unbounded_String ("Cannot close dirty buffer");
      Assert (Status_Layout_Should_Use_Compact (Snapshot, 120),
              "render policy must use compact projection for unavailable command feedback");

      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("success");
      Assert (not Status_Layout_Should_Use_Compact (Snapshot, 120),
              "render policy must not force compact layout for ordinary success feedback");
   end Test_Render_Compact_Policy_Uses_Priority_Context;



   procedure Test_Status_Line_Workflow_Coherence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Status_Bar_Snapshot;
      Left     : Unbounded_String;
      Right    : Unbounded_String;
      Compact  : Unbounded_String;
   begin
      Snapshot.Has_Active_Buffer := True;
      Snapshot.File_Label := To_Unbounded_String ("src/main.adb");
      Snapshot.Is_Dirty := True;
      Snapshot.Dirty_State_Label := To_Unbounded_String ("Modified");
      Snapshot.Project_State_Label := To_Unbounded_String ("No project");
      Snapshot.Focus_Label := To_Unbounded_String ("Search Results");
      Snapshot.Line_Number_Mode := To_Unbounded_String ("absolute lines");
      Snapshot.Pending_Confirmation_Label :=
        To_Unbounded_String ("Unsaved changes require confirmation");
      Snapshot.Has_Command_Feedback := True;
      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("error");
      Snapshot.Command_Feedback :=
        To_Unbounded_String ("Search result is stale; run Project Search again.");
      Snapshot.Search_Status_Label := To_Unbounded_String ("Search: stale");
      Snapshot.Outline_Status_Label := To_Unbounded_String ("Outline: stale");
      Snapshot.Diagnostics_Status_Label :=
        To_Unbounded_String ("Diagnostics: stale targets");
      Snapshot.Build_Status_Label := To_Unbounded_String ("Build: candidate stale");
      Snapshot.File_Tree_Status_Label := To_Unbounded_String ("File Tree: stale node");

      Right := To_Unbounded_String (Format_Right (Snapshot));
      Compact := To_Unbounded_String (Status_Layout_Compact (Snapshot, 220));

      Assert (Index (Right, "Unsaved changes require confirmation.") = 1,
              "status must prioritize pending confirmations before summaries");
      Assert (Index (Right, "failed: Target is stale; refresh required.") > 0,
              "status command outcome must use canonical stale wording");
      Assert (Index (Right, "No project open.") > 0,
              "status must normalize no-project wording");
      Assert (Index (Right, "Search: Target is stale; refresh required.") > 0,
              "status search stale label must match canonical stale wording");
      Assert (Index (Right, "Outline: Target is stale; refresh required.") > 0,
              "status outline stale label must match canonical stale wording");
      Assert (Index (Right, "Diagnostics: Target is stale; refresh required.") > 0,
              "status diagnostics stale label must match canonical stale wording");
      Assert (Index (Right, "Build: Target is stale; refresh required.") > 0,
              "status build stale label must match canonical stale wording");
      Assert (Index (Right, "File Tree: Target is stale; refresh required.") > 0,
              "status file-tree stale label must match canonical stale wording");
      Assert (Index (Compact, "Unsaved changes require confirmation.") = 1,
              "compact status must keep pending confirmation first");
      Assert (Assert_Status_Line_Context_Coherent (Snapshot),
              "status coherence assertion must accept normalized workflow status");
   end Test_Status_Line_Workflow_Coherence;

   procedure Test_Remaining_Status_Workflow_Cases
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Status_Bar_Snapshot;
      Left     : Unbounded_String;
      Right    : Unbounded_String;
      Compact  : Unbounded_String;
   begin
      --  Diagnostics: none used to bypass the canonical "No diagnostics."
      --  wording when it arrived from the render snapshot rather than the empty
      --  Diagnostics_Status_Label fallback.  The status segment path now
      --  normalizes both sources identically.
      Snapshot.Has_Active_Buffer := True;
      Snapshot.File_Label := To_Unbounded_String ("src/main.adb");
      Snapshot.Has_Project := True;
      Snapshot.Project_Label := To_Unbounded_String ("demo");
      Snapshot.Focus_Label := To_Unbounded_String ("Editor");
      Snapshot.Line_Number_Mode := To_Unbounded_String ("absolute lines");
      Snapshot.Diagnostics_Status_Label := To_Unbounded_String ("Diagnostics: none");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Status_Diagnostics_Segment (Snapshot) = "No diagnostics.",
              "diagnostics status must canonicalize render none state");
      Assert (Index (Right, "No diagnostics.") > 0,
              "formatted status must show canonical no-diagnostics text");
      Assert (Index (Right, "Diagnostics: none") = 0,
              "formatted status must not leak old diagnostics-none text");

      --  No-active-buffer workflow labels also arrive from real feature
      --  surfaces with panel-specific wording.  The integrated status surface
      --  should keep the surface prefix but use the canonical condition.
      Snapshot.Diagnostics_Status_Label := Null_Unbounded_String;
      Snapshot.Outline_Status_Label :=
        To_Unbounded_String ("Outline unavailable: no active buffer.");
      Snapshot.Search_Status_Label :=
        To_Unbounded_String ("Search Results: no active buffer");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Outline: No active buffer.") > 0,
              "status must canonicalize Outline no-active-buffer wording");
      Assert (Index (Right, "Search: No active buffer.") > 0,
              "status must canonicalize Search no-active-buffer wording");
      Assert (Index (Right, "Outline unavailable: no active buffer") = 0,
              "status must not leak old Outline no-active-buffer text");
      Snapshot.Outline_Status_Label := Null_Unbounded_String;
      Snapshot.Search_Status_Label := Null_Unbounded_String;

      --  Startup and empty-state helpers historically used natural-language
      --  unavailable labels instead of status-surface prefixes.  The status
      --  line should preserve the surface while canonicalizing the condition.
      Snapshot.File_Tree_Status_Label :=
        To_Unbounded_String ("File Tree unavailable: no project open.");
      Snapshot.Quick_Open_Status_Label :=
        To_Unbounded_String ("Quick Open unavailable: no project open.");
      Snapshot.Search_Status_Label :=
        To_Unbounded_String ("Project Search unavailable: no project open.");
      Snapshot.Build_Status_Label :=
        To_Unbounded_String ("Build unavailable: no project open or no build request ready.");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "File Tree: No project open.") > 0,
              "status must canonicalize File Tree startup no-project wording");
      Assert (Index (Right, "Quick Open: No project open.") > 0,
              "status must canonicalize Quick Open startup no-project wording");
      Assert (Index (Right, "Search: No project open.") > 0,
              "status must canonicalize Project Search startup no-project wording");
      Assert (Index (Right, "Build: No project open.") > 0,
              "status must canonicalize Build startup no-project wording");
      Assert (Index (Right, "unavailable: no project open") = 0,
              "status must not leak startup unavailable no-project text");
      Snapshot.File_Tree_Status_Label := Null_Unbounded_String;
      Snapshot.Quick_Open_Status_Label := Null_Unbounded_String;
      Snapshot.Search_Status_Label := Null_Unbounded_String;
      Snapshot.Build_Status_Label := Null_Unbounded_String;

      --  Build readiness/consent variants are emitted by Build request and
      --  consent workflows with several surface-specific prefixes.  The status
      --  line should keep the Build surface prefix while canonicalizing the
      --  actionable condition.
      Snapshot.Build_Status_Label :=
        To_Unbounded_String ("Build run unavailable: no build candidate selected");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Build: No build candidate selected.") > 0,
              "status must canonicalize Build missing-candidate wording");
      Snapshot.Build_Status_Label :=
        To_Unbounded_String ("No build candidates found.");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Build: No build candidates.") > 0,
              "status must canonicalize Build no-candidates wording");
      Snapshot.Build_Status_Label :=
        To_Unbounded_String ("Build run unavailable: review the request and acknowledge consent first");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Build: Consent required.") > 0,
              "status must canonicalize Build consent-required wording");
      Snapshot.Build_Status_Label :=
        To_Unbounded_String ("Build unavailable: consent required.");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Build: Consent required.") > 0,
              "status must canonicalize Build result/output consent wording");
      Snapshot.Build_Status_Label :=
        To_Unbounded_String ("Consent missing: review and acknowledge the build request");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Build: Consent required.") > 0,
              "status must canonicalize Build UI consent-missing detail");
      Snapshot.Build_Status_Label :=
        To_Unbounded_String ("Build candidate applied to transient request; Consent missing: review and acknowledge the build request");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Build: Consent required.") > 0,
              "status must canonicalize Build candidate consent detail");
      Snapshot.Build_Status_Label :=
        To_Unbounded_String ("Build run unavailable: choose a build tool first");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Build: No build tool selected.") > 0,
              "status must canonicalize Build missing-tool wording");
      Snapshot.Build_Status_Label :=
        To_Unbounded_String ("Build run unavailable: custom shell commands are not supported");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Build: No build request ready.") > 0,
              "status must canonicalize Build unsupported-request wording");
      Snapshot.Build_Status_Label :=
        To_Unbounded_String ("candidate request could not be formed");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Build: No build request ready.") > 0,
              "status must canonicalize Build candidate request-shape wording");
      Snapshot.Build_Status_Label :=
        To_Unbounded_String ("Build request is not ready.");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Build: No build request ready.") > 0,
              "status must canonicalize Build request readiness wording");
      Snapshot.Build_Status_Label :=
        To_Unbounded_String ("Build run unavailable: no project working context selected");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Build: No project open.") > 0,
              "status must canonicalize Build missing-working-context wording");
      Snapshot.Build_Status_Label :=
        To_Unbounded_String ("Build run unavailable: selected project working context is unavailable");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Build: Target no longer exists.") > 0,
              "status must canonicalize Build missing-working-context target wording");
      Snapshot.Build_Status_Label :=
        To_Unbounded_String ("Build run unavailable: working context must come from the current project/workspace");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Build: Target is outside the current project.") > 0,
              "status must canonicalize Build outside-working-context wording");
      Snapshot.Build_Status_Label :=
        To_Unbounded_String ("Build working context canonical path required");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Build: Target is outside the current project.") > 0,
              "status must canonicalize Build invalid canonical working-context wording");
      Snapshot.Build_Status_Label := To_Unbounded_String ("Build working directory is required.");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Build: No project open.") > 0,
              "status must canonicalize Build missing working-directory wording");
      Snapshot.Build_Status_Label := To_Unbounded_String ("No canonical project/workspace context");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Build: No project open.") > 0,
              "status must canonicalize Build missing canonical working-context wording");
      Snapshot.Build_Status_Label := To_Unbounded_String ("Build: output unavailable");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Build: No build output captured.") > 0,
              "status must canonicalize Build output empty state");
      Snapshot.Build_Status_Label :=
        To_Unbounded_String ("Build: No standard output captured");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Build: No stdout captured.") > 0,
              "status must canonicalize Build stdout empty state");
      Snapshot.Build_Status_Label :=
        To_Unbounded_String ("Build: No standard error captured");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Build: No stderr captured.") > 0,
              "status must canonicalize Build stderr empty state");
      Snapshot.Build_Status_Label := To_Unbounded_String ("Project root unavailable");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Build: Target no longer exists.") > 0,
              "status must canonicalize Project-root unavailable wording");
      Snapshot.Build_Status_Label := To_Unbounded_String ("Build working directory is unavailable.");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Build: Target no longer exists.") > 0,
              "status must canonicalize Build unavailable working-directory wording");
      Snapshot.Build_Status_Label := To_Unbounded_String ("candidate path missing or unavailable");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Build: Target no longer exists.") > 0,
              "status must canonicalize Build candidate missing-path wording");
      Snapshot.Build_Status_Label := To_Unbounded_String ("candidate path outside project root");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Build: Target is outside the current project.") > 0,
              "status must canonicalize Build candidate project-boundary wording");
      Snapshot.Build_Status_Label := To_Unbounded_String ("candidate must be refreshed");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Build: Target is stale; refresh required.") > 0,
              "status must canonicalize Build candidate refresh-required wording");
      Snapshot.Build_Status_Label :=
        To_Unbounded_String ("Build run unavailable: execution backend is disabled");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Build: Execution unavailable.") > 0,
              "status must canonicalize Build execution-backend wording");
      Snapshot.Build_Status_Label :=
        To_Unbounded_String ("Build unavailable: execution backend disabled.");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Build: Execution unavailable.") > 0,
              "status must canonicalize Build output-details execution-backend wording");
      Snapshot.Build_Status_Label :=
        To_Unbounded_String ("Consent stale: review the changed build request");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Build: Consent is stale.") > 0,
              "status must canonicalize Build stale-consent wording");
      Snapshot.Build_Status_Label := Null_Unbounded_String;

      Snapshot.Has_Command_Feedback := True;
      Snapshot.Command_Feedback := To_Unbounded_String ("Another prompt is active");
      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("unavailable");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "unavailable: Another prompt is active.") > 0,
              "status must canonicalize prompt-concurrency wording");
      Snapshot.Command_Feedback := To_Unbounded_String ("Prompt canceled");
      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("cancelled");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "cancelled: Prompt cancelled.") > 0,
              "status must canonicalize prompt-cancel spelling");
      Snapshot.Command_Feedback := To_Unbounded_String ("Conflict prompt is stale");
      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("unavailable");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "unavailable: Prompt is stale.") > 0,
              "status must canonicalize stale prompt wording");
      Snapshot.Command_Feedback := To_Unbounded_String ("No pending reset-all confirmation");
      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("info");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "info: No pending confirmation.") > 0,
              "status must canonicalize missing configuration confirmation wording");
      Snapshot.Command_Feedback := To_Unbounded_String ("Reset requires confirmation");
      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("unavailable");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "unavailable: Reset requires confirmation.") > 0,
              "status must canonicalize configuration reset confirmation wording");
      Snapshot.Command_Feedback := To_Unbounded_String ("Switch project canceled");
      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("cancelled");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "cancelled: Switch project cancelled.") > 0,
              "status must canonicalize project switch-cancel wording");
      Snapshot.Command_Feedback := To_Unbounded_String ("Reload canceled");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "cancelled: Reload cancelled.") > 0,
              "status must canonicalize file reload-cancel wording");
      Snapshot.Command_Feedback := To_Unbounded_String ("Opened diagnostic target");
      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("success");
      Snapshot.Search_Status_Label := To_Unbounded_String ("Search Results: no query");
      Snapshot.Quick_Open_Status_Label := To_Unbounded_String ("Quick Open: no matches");
      Snapshot.Outline_Status_Label := To_Unbounded_String ("Outline: not refreshed");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Search: No search query.") > 0,
              "status must canonicalize Search no-query wording");
      Assert (Index (Right, "Quick Open: No matches.") > 0,
              "status must canonicalize Quick Open no-matches wording");
      Assert (Status_Message_Kind_For
                (To_Unbounded_String ("Find: No search query.")) =
                Status_Message_Find_No_Query,
              "Find empty-query status must classify without raw-string callers");
      Assert (Status_Message_Kind_For
                (To_Unbounded_String ("Find: No matches.")) =
                Status_Message_Find_No_Matches,
              "Find no-match status must classify without raw-string callers");
      Assert (Status_Message_Kind_For (Snapshot.Quick_Open_Status_Label) =
                Status_Message_Quick_Open_No_Matches,
              "Quick Open no-matches status must classify without raw-string callers");
      Snapshot.Quick_Open_Status_Kind := Status_Message_Quick_Open_No_Matches;
      Assert (Status_Quick_Open_Message_Kind (Snapshot) =
                Status_Message_Quick_Open_No_Matches,
              "typed Quick Open status kind is readable from snapshot");
      Snapshot.Quick_Open_Status_Kind := Status_Message_Other;
      declare
         Surface : constant Quick_Open_Context_Surface :=
           Quick_Open_Context_Surface_For (Snapshot);
      begin
         Assert (Surface.Active,
                 "Quick Open surface must be active when context status is visible");
         Assert (Quick_Open_Context_Action_Count (Surface) = 3,
                 "Quick Open surface exposes typed action count");
         Assert (To_String (Surface.Open_Command) = "quick_open.open"
                 and then To_String (Surface.Clear_Scope_Command) =
                   "quick_open.scope.clear"
                 and then To_String (Surface.Clear_Filter_Command) =
                   "quick_open.kind.clear",
                 "Quick Open surface must expose open and clear context actions");
         Assert (Index (Quick_Open_Context_Action_Label (Surface),
                        "quick_open.open") > 0
                 and then Index (Status_Quick_Open_Segment (Snapshot),
                                  "quick_open.scope.clear") > 0,
                 "visible Quick Open status segment must include context actions");
      end;
      Assert (Index (Right, "Outline: Not refreshed.") > 0,
              "status must canonicalize Outline not-refreshed wording");
      Assert (Status_Outline_Message_Kind (Snapshot) =
                Status_Message_Outline_Not_Refreshed,
              "Outline not-refreshed status must classify through typed access");
      Snapshot.Outline_Status_Kind := Status_Message_Outline_Not_Refreshed;
      Assert (Status_Outline_Message_Kind (Snapshot) =
                Status_Message_Outline_Not_Refreshed,
              "typed Outline status kind overrides label fallback");
      declare
         Surface : constant Outline_Status_Surface :=
           Outline_Surface (Snapshot);
      begin
         Assert (Surface.Active,
                 "Outline surface must be active when status is visible");
         Assert (Outline_Surface_Action_Count (Surface) = 3,
                 "Outline surface exposes typed action count");
         Assert (To_String (Surface.Refresh_Command) = "outline.refresh"
                 and then To_String (Surface.Open_Selected_Command) =
                   "outline.open-selected"
                 and then To_String (Surface.Reveal_Current_Command) =
                   "outline.reveal-current-symbol",
                 "Outline surface must expose navigation actions");
         Assert (Index (Status_Outline_Segment (Snapshot),
                        "outline.open-selected") > 0,
                 "visible Outline status segment must include action labels");
      end;
      Snapshot.Outline_Status_Kind := Status_Message_Other;
      Snapshot.Search_Status_Label := To_Unbounded_String ("Project search completed: no matches.");
      Snapshot.Quick_Open_Status_Label := Null_Unbounded_String;
      Snapshot.Outline_Status_Label := Null_Unbounded_String;
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Search: No search results.") > 0,
              "status must canonicalize Search no-results wording");
      declare
         Surface : constant Search_Replace_Status_Surface :=
           Search_Replace_Surface (Snapshot);
      begin
         Assert (Surface.Active,
                 "Search surface must be active when status is visible");
         Assert (Search_Replace_Surface_Action_Count (Surface) = 3,
                 "Search surface exposes typed action count");
         Assert (To_String (Surface.Run_Command) = "project.search.run"
                 and then To_String (Surface.Open_Selected_Command) =
                   "project.search.open-selected"
                 and then To_String (Surface.Clear_Query_Command) =
                   "project.search.query.clear",
                 "Search surface must expose run/open/clear actions");
         Assert (Index (Status_Search_Replace_Segment (Snapshot),
                        "project.search.open-selected") > 0,
                 "visible Search status segment must include action labels");
      end;
      Snapshot.Search_Status_Label := To_Unbounded_String ("No replacement preview");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Replace: No replacement preview.") > 0,
              "status must canonicalize replace-preview empty wording");
      Snapshot.Search_Status_Label :=
        To_Unbounded_String ("Replace: Replacement target changed; rerun search");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Replace: Target is stale; refresh required.") > 0,
              "status must canonicalize Replace changed-target wording");
      Assert (Status_Message_Kind_For (Snapshot.Search_Status_Label) =
                Status_Message_Search_Target_Stale,
              "Replace stale-target status must classify without raw-string callers");
      Snapshot.Search_Status_Kind := Status_Message_Search_Target_Stale;
      Assert (Status_Search_Message_Kind (Snapshot) =
                Status_Message_Search_Target_Stale,
              "typed Search status kind is readable from snapshot");
      Snapshot.Search_Status_Kind := Status_Message_Other;
      Snapshot.Search_Status_Label :=
        To_Unbounded_String ("Replace: Replacement target is unavailable");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Replace: Target no longer exists.") > 0,
              "status must canonicalize Replace missing-target wording");
      Snapshot.Search_Status_Label :=
        To_Unbounded_String ("Replace: Replacement target is read-only");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Replace: File is not writable.") > 0,
              "status must canonicalize Replace read-only target wording");
      Snapshot.Search_Status_Label :=
        To_Unbounded_String ("Replace: Replacement target is not a regular file");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Replace: Target is not a file.") > 0,
              "status must canonicalize Replace non-file target wording");
      Snapshot.Search_Status_Label :=
        To_Unbounded_String ("Replace: Replacement target path is invalid");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Replace: Invalid file path.") > 0,
              "status must canonicalize Replace invalid-path wording");
      Snapshot.Search_Status_Label :=
        To_Unbounded_String ("Replace: Replacement text must be single-line");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Replace: Replacement text must be single-line.") > 0,
              "status must canonicalize Replace text validation wording");
      Snapshot.Search_Status_Label := Null_Unbounded_String;

      Snapshot.Build_Status_Label := Null_Unbounded_String;

      --  Build/Diagnostics loop coherence: a failed build and parsed diagnostic
      --  count must be simultaneously visible, scalar, and priority-safe.
      Snapshot.Diagnostics_Status_Label :=
        To_Unbounded_String ("Diagnostics: 0 errors, 1 warning");
      Snapshot.Build_Status_Label := To_Unbounded_String ("Build: failed");
      Snapshot.Has_Command_Feedback := True;
      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("success");
      Snapshot.Command_Feedback := To_Unbounded_String ("Opened diagnostic target");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Compact := To_Unbounded_String (Status_Layout_Compact (Snapshot, 220));
      Assert (Index (Right, "Build: failed") > 0,
              "status must retain Build result after build.run");
      Assert (Status_Message_Kind_For (Snapshot.Build_Status_Label) =
                Status_Message_Build_Failed,
              "Build failure status must classify without raw-string callers");
      Snapshot.Build_Status_Label := To_Unbounded_String ("Build: ready");
      Assert (Status_Message_Kind_For (Snapshot.Build_Status_Label) =
                Status_Message_Build_Ready,
              "Build ready status must classify without raw-string callers");
      Snapshot.Build_Status_Kind := Status_Message_Build_Failed;
      Assert (Status_Build_Message_Kind (Snapshot) = Status_Message_Build_Failed,
              "typed Build status kind overrides label fallback");
      Snapshot.Build_Status_Kind := Status_Message_Other;
      Snapshot.Build_Status_Label := To_Unbounded_String ("Build: failed");
      Assert (Index (Right, "Diagnostics: 0 errors, 1 warning") > 0,
              "status must retain Diagnostics count after parse");
      Assert (Index (Right, "success: Opened diagnostic target") > 0,
              "status must show diagnostic navigation outcome");
      Assert (Assert_Status_Line_Context_Coherent (Snapshot),
              "Build/Diagnostics status must remain coherent and scalar");
      Assert (Index (Compact, "Build: failed") > 0
                and then Index (Compact, "Diagnostics: 0 errors, 1 warning") > 0,
              "compact status must keep Build and Diagnostics summaries together");

      Snapshot.File_Tree_Status_Label := To_Unbounded_String ("File Tree: no project");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "File Tree: No project open.") > 0,
              "status must canonicalize File Tree no-project wording");
      Assert (Status_Message_Kind_For (Snapshot.File_Tree_Status_Label) =
                Status_Message_File_Tree_No_Project,
              "File Tree no-project status must classify without raw-string callers");
      declare
         Surface : constant File_Tree_Status_Surface :=
           File_Tree_Surface (Snapshot);
      begin
         Assert (Surface.Active,
                 "File Tree surface must be active when status is visible");
         Assert (File_Tree_Surface_Action_Count (Surface) = 3,
                 "File Tree surface exposes typed action count");
         Assert (To_String (Surface.Refresh_Command) = "file-tree.refresh"
                 and then To_String (Surface.Open_Selected_Command) =
                   "file-tree.open-selected"
                 and then To_String (Surface.Reveal_Active_Command) =
                   "file-tree.reveal-active-file",
                 "File Tree surface must expose refresh/open/reveal actions");
         Assert (Index (Status_File_Tree_Segment (Snapshot),
                        "file-tree.open-selected") > 0,
                 "visible File Tree status segment must include action labels");
      end;
      Snapshot.File_Tree_Status_Kind := Status_Message_File_Tree_No_Project;
      Assert (Status_File_Tree_Message_Kind (Snapshot) =
                Status_Message_File_Tree_No_Project,
              "typed File Tree status kind is readable from snapshot");
      Snapshot.File_Tree_Status_Kind := Status_Message_Other;
      Snapshot.File_Tree_Status_Label := Null_Unbounded_String;

      --  Workspace restore and startup recovery are workflow summaries, not
      --  persisted status payloads.  They must coexist with project/file state.
      Snapshot.Command_Feedback := To_Unbounded_String ("Workspace loaded");
      Snapshot.Workspace_Status_Label := To_Unbounded_String ("Workspace: restored");
      Snapshot.Workspace_Status_Kind := Status_Message_Workspace_Restored;
      declare
         Surface : constant Workspace_Status_Surface :=
           Workspace_Surface (Snapshot);
      begin
         Assert (Surface.Has_Restore_Details,
                 "workspace surface must mark restore details as available");
         Assert (Workspace_Surface_Action_Count (Surface) = 3,
                 "workspace surface exposes typed action count");
         Assert (Index (To_String (Surface.Restore_Details_Label), "Workspace") > 0,
                 "workspace surface must expose canonical restore details");
         Assert (To_String (Surface.Save_State_Command) =
                   "workspace.save"
                 and then To_String (Surface.Restore_State_Command) =
                   "workspace.restore"
                 and then To_String (Surface.Clear_State_Command) =
                   "workspace.clear",
                 "workspace surface must expose direct workspace actions");
         Assert (Index (Workspace_Surface_Action_Label (Surface),
                        "workspace.save") > 0
                 and then Index (Workspace_Surface_Action_Label (Surface),
                                  "workspace.clear") > 0,
                 "workspace action surface must render visible action labels");
      end;
      Snapshot.Recent_Projects_Status_Label :=
        To_Unbounded_String ("Recent Projects: 1 entries");
      Snapshot.Startup_Status_Label :=
        To_Unbounded_String ("Startup: recovered defaults");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Workspace: restored") > 0,
              "status must show workspace restore summary");
      Assert (Index (Status_Workspace_Recent_Segment (Snapshot),
                     "workspace.save") > 0,
              "visible workspace status segment must include workspace actions");
      Assert (Index (Right, "Recent Projects: 1 entries") > 0,
              "status must show recent-project summary without workspace mutation");
      declare
         Surface : constant Recent_Projects_Status_Surface :=
           Recent_Projects_Surface (Snapshot);
      begin
         Assert (Surface.Active,
                 "Recent Projects surface must be active when status is visible");
         Assert (Recent_Projects_Surface_Action_Count (Surface) = 3,
                 "Recent Projects surface exposes typed action count");
         Assert (To_String (Surface.Show_Command) = "recent-projects.show"
                 and then To_String (Surface.Open_Selected_Command) =
                   "recent-projects.open-selected"
                 and then To_String (Surface.Remove_Missing_Command) =
                   "recent-projects.remove-missing",
                 "Recent Projects surface must expose show/open/cleanup actions");
         Assert (Index (Status_Workspace_Recent_Segment (Snapshot),
                        "recent-projects.open-selected") > 0,
                 "visible Recent Projects segment must include action labels");
      end;
      Assert (Index (Right, "Startup: recovered defaults") > 0,
              "status must show startup recovery summary");
      Assert (Assert_Status_Line_Context_Coherent (Snapshot),
              "workspace/startup status must remain coherent");

      Snapshot.Workspace_Status_Label :=
        To_Unbounded_String ("Workspace restored.");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Workspace: Restored.") > 0,
              "status must canonicalize product workspace restore wording");
      Assert (Status_Message_Kind_For (Snapshot.Workspace_Status_Label) =
                Status_Message_Workspace_Restored,
              "workspace restored status must classify without raw-string callers");
      Assert (Status_Workspace_Message_Kind (Snapshot) =
                Status_Message_Workspace_Restored,
              "typed Workspace status kind is readable from snapshot");
      Snapshot.Workspace_Status_Kind := Status_Message_Other;

      --  Workspace, Recent Projects, and Startup recovery summaries should
      --  retain their source surface while using the same wording
      --  used by configuration recovery, first-run guidance, and command
      --  feedback.
      Snapshot.Workspace_Status_Label :=
        To_Unbounded_String ("Workspace loaded with stale or unsupported structural entries ignored.");
      Snapshot.Recent_Projects_Status_Label :=
        To_Unbounded_String ("Recent Projects loaded with invalid lightweight entries ignored.");
      Snapshot.Startup_Status_Label :=
        To_Unbounded_String ("Editor ready with configuration warnings.");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Workspace: Restored with missing entries skipped.") > 0,
              "status must canonicalize workspace partial-restore wording");
      Assert (Status_Message_Kind_For (Snapshot.Workspace_Status_Label) =
                Status_Message_Workspace_Partial_Restore,
              "workspace partial restore status must classify without raw-string callers");
      Assert (Index (Right, "Recent Projects: Invalid entries ignored.") > 0,
              "status must canonicalize recent-project partial-load wording");
      Assert (Index (Right, "Startup: Ready with configuration warnings.") > 0,
              "status must canonicalize startup warning wording");

      Snapshot.Workspace_Status_Label :=
        To_Unbounded_String ("Workspace session malformed; no session restored.");
      Snapshot.Recent_Projects_Status_Label :=
        To_Unbounded_String ("Recent Projects list empty.");
      Snapshot.Startup_Status_Label :=
        To_Unbounded_String ("Editor ready with workspace project unavailable.");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Workspace: No workspace restored.") > 0,
              "status must canonicalize workspace no-restore wording");
      Assert (Status_Message_Kind_For (Snapshot.Workspace_Status_Label) =
                Status_Message_Workspace_No_Restore,
              "workspace no-restore status must classify without raw-string callers");
      Assert (Index (Right, "Recent Projects: No recent projects.") > 0,
              "status must canonicalize no-recent-projects wording");
      Assert (Status_Recent_Projects_Message_Kind (Snapshot) =
                Status_Message_Recent_Projects_None,
              "typed Recent Projects status kind classifies empty state");
      Snapshot.Recent_Projects_Status_Kind := Status_Message_Recent_Projects_None;
      Assert (Status_Recent_Projects_Message_Kind (Snapshot) =
                Status_Message_Recent_Projects_None,
              "typed Recent Projects status kind overrides label fallback");
      Snapshot.Recent_Projects_Status_Kind := Status_Message_Other;
      Assert (Index (Right, "Startup: Ready with workspace project unavailable.") > 0,
              "status must canonicalize startup unavailable-project wording");
      Assert (Assert_Status_Line_Context_Coherent (Snapshot),
              "recovery status labels remain coherent");

      --  Settings, keybinding, and configuration recovery messages should be
      --  actionable and surface-labelled, not raw loader/audit diagnostics.
      Snapshot.Workspace_Status_Label :=
        To_Unbounded_String ("Settings: Settings file has an invalid format.");
      Snapshot.Recent_Projects_Status_Label :=
        To_Unbounded_String ("Keybindings: Keybindings loaded with ignored invalid entries.");
      Snapshot.Startup_Status_Label :=
        To_Unbounded_String ("Configuration: Reset all configuration requested. Run configuration.reset-all.confirm to confirm or configuration.reset-all.cancel to cancel; project files and dirty buffers will not be changed.");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Settings: File is invalid.") > 0,
              "status must canonicalize Settings invalid-file wording");
      Assert (Index (Right, "Keybindings: Rejected invalid bindings.") > 0,
              "status must canonicalize Keybindings rejected-entry wording");
      Assert (Index (Right, "Configuration: Reset all requires confirmation.") > 0,
              "status must canonicalize configuration reset-all confirmation wording");

      Snapshot.Workspace_Status_Label :=
        To_Unbounded_String ("Settings loaded with invalid values reset to defaults.");
      Snapshot.Recent_Projects_Status_Label :=
        To_Unbounded_String ("Keybindings file malformed; default keybindings active.");
      Snapshot.Startup_Status_Label :=
        To_Unbounded_String ("All configuration domains reset after explicit confirmation.");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Settings: Invalid values reset to defaults.") > 0,
              "status must canonicalize Settings invalid-value recovery wording");
      Assert (Index (Right, "Keybindings: Default keybindings active.") > 0,
              "status must canonicalize keybinding default-fallback wording");
      Assert (Index (Right, "Configuration: All domains reset.") > 0,
              "status must canonicalize configuration reset completion wording");
      --  Command Palette, Settings, and Keybindings management are part of
      --  the same dogfood command-discovery loop.  Their status text should
      --  be actionable and surface-labelled, not raw implementation wording.
      Snapshot.Workspace_Status_Label :=
        To_Unbounded_String ("Command Palette: No commands match ""zzzz-no-command""");
      Snapshot.Recent_Projects_Status_Label :=
        To_Unbounded_String ("Settings: Setting value is invalid");
      Snapshot.Startup_Status_Label :=
        To_Unbounded_String ("Keybindings: Keybinding conflict: shortcut already assigned");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Command Palette: No matching commands.") > 0,
              "status must canonicalize Command Palette no-match wording");

      Snapshot.Workspace_Status_Label :=
        To_Unbounded_String ("Command Palette: No available commands match ""build""");
      Snapshot.Recent_Projects_Status_Label :=
        To_Unbounded_String ("Command Palette: No available commands");
      Snapshot.Startup_Status_Label :=
        To_Unbounded_String ("Command Palette: No command selected");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Command Palette: No matching available commands.") > 0,
              "status must preserve available-only Command Palette no-match context");
      Assert (Index (Right, "Command Palette: No available commands.") > 0,
              "status must canonicalize available-only Command Palette empty state");
      Assert (Index (Right, "Command Palette: No command selected.") > 0,
              "status must canonicalize Command Palette selection wording");

      Snapshot.Workspace_Status_Label :=
        To_Unbounded_String ("Command Palette: No commands match ""zzzz-no-command""");
      Snapshot.Recent_Projects_Status_Label :=
        To_Unbounded_String ("Settings: Setting value is invalid");
      Snapshot.Startup_Status_Label :=
        To_Unbounded_String ("Keybindings: Keybinding conflict: shortcut already assigned");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Settings: Invalid setting value.") > 0,
              "status must canonicalize Settings invalid-value wording");
      Assert (Index (Right, "Keybindings: Shortcut is already assigned.") > 0,
              "status must canonicalize Keybinding conflict wording");

      Snapshot.Workspace_Status_Label :=
        To_Unbounded_String ("Command Palette: Command Palette is closed");
      Snapshot.Recent_Projects_Status_Label :=
        To_Unbounded_String ("Settings: Selected setting is not editable");
      Snapshot.Startup_Status_Label :=
        To_Unbounded_String ("Keybindings: Command is not bindable");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Command Palette: Closed.") > 0,
              "status must canonicalize Command Palette closed wording");
      Assert (Index (Right, "Settings: Selected setting is not editable.") > 0,
              "status must canonicalize Settings editability wording");
      Assert (Index (Right, "Keybindings: Selected command is not bindable.") > 0,
              "status must canonicalize Keybinding bindability wording");
      Assert (Assert_Status_Line_Context_Coherent (Snapshot),
              "command/settings/keybinding status labels remain coherent");

      --  Clipboard and selection command feedback should use the same concrete
      --  wording whether it comes from executor availability, command result
      --  reporting, or status projection.
      Snapshot.Workspace_Status_Label :=
        To_Unbounded_String ("Clipboard: No selection");
      Snapshot.Recent_Projects_Status_Label :=
        To_Unbounded_String ("Clipboard: No clipboard to clear");
      Snapshot.Startup_Status_Label :=
        To_Unbounded_String ("Clipboard: Invalid selection.");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Clipboard: No selected text.") > 0,
              "status must canonicalize Clipboard no-selection wording");
      Assert (Index (Right, "Clipboard: Empty.") > 0,
              "status must canonicalize Clipboard empty-state wording");
      Assert (Index (Right, "Clipboard: Invalid selection.") > 0,
              "status must canonicalize Clipboard invalid-selection wording");

      --  Command discovery/help unavailable blockers arrive as command feedback.
      --  The status line must use the same canonical reason as Executor and
      --  Command Palette, and priority compact layout must keep it early.
      Snapshot.Has_Project := False;
      Snapshot.Project_Label := Null_Unbounded_String;
      Snapshot.Project_State_Label := To_Unbounded_String ("No project");
      Snapshot.Has_Command_Feedback := True;
      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("unavailable");
      Snapshot.Command_Feedback := To_Unbounded_String ("No project open");
      Snapshot.Pending_Confirmation_Label := Null_Unbounded_String;
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Compact := To_Unbounded_String (Status_Layout_Compact (Snapshot, 160));
      Assert (Index (Right, "No project open.") > 0,
              "status must normalize no-project project state");
      Assert (Index (Right, "unavailable: No project open.") > 0,
              "status must match command discovery unavailable reason");
      Assert (Index (Compact, "unavailable: No project open.") = 1,
              "compact status must prioritize unavailable command help blockers");

      --  Adjacent project-scoped surfaces used to leak prefix-specific
      --  variants such as "Quick Open: no project" or
      --  "Build unavailable: no project open" into the status line.
      --  The integrated workflow should keep the surface context while using
      --  the same canonical blocker text everywhere.
      Snapshot.Has_Command_Feedback := False;
      Snapshot.Quick_Open_Status_Label := To_Unbounded_String ("Quick Open: no project");
      Snapshot.Search_Status_Label := To_Unbounded_String ("Project Search: no project");
      Snapshot.Build_Status_Label := To_Unbounded_String ("Build unavailable: no project open");
      Snapshot.Outline_Status_Label := To_Unbounded_String ("Outline: no project");
      Snapshot.Diagnostics_Status_Label := To_Unbounded_String ("Diagnostics: no project");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Quick Open: No project open.") > 0,
              "Quick Open status must use canonical no-project wording");
      Assert (Index (Right, "Search: No project open.") > 0,
              "Project Search status must use canonical no-project wording");
      Assert (Index (Right, "Build: No project open.") > 0,
              "Build status must use canonical no-project wording");
      Assert (Index (Right, "Outline: No project open.") > 0,
              "Outline status must use canonical no-project wording");
      Assert (Index (Right, "Diagnostics: No project open.") > 0,
              "Diagnostics status must use canonical no-project wording");
      Assert (Assert_Status_Line_Context_Coherent (Snapshot),
              "no-project surface status labels remain coherent");

      --  Missing-selection states should also keep their originating surface
      --  visible while sharing the same corrective wording.
      Snapshot.Quick_Open_Status_Label := To_Unbounded_String ("Quick Open: no result selected");
      Snapshot.Search_Status_Label := To_Unbounded_String ("Search Results: no selected result");
      Snapshot.Outline_Status_Label := To_Unbounded_String ("Outline: no item selected");
      Snapshot.Diagnostics_Status_Label := To_Unbounded_String ("Diagnostics: no diagnostic selected");
      Snapshot.File_Tree_Status_Label := To_Unbounded_String ("File Tree: no node selected");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Quick Open: No file selected.") > 0,
              "Quick Open missing-selection status must be canonical");
      Assert (Index (Right, "Search: No file selected.") > 0,
              "Search missing-selection status must be canonical");
      Assert (Index (Right, "Outline: No file selected.") > 0,
              "Outline missing-selection status must be canonical");
      Assert (Index (Right, "Diagnostics: No file selected.") > 0,
              "Diagnostics missing-selection status must be canonical");
      Assert (Index (Right, "File Tree: No file selected.") > 0,
              "File Tree missing-selection status must be canonical");
      Assert (Assert_Status_Line_Context_Coherent (Snapshot),
              "missing-selection surface status labels remain coherent");

      --  File Tree prompt cancellation should keep the user at the File Tree
      --  and report the cancellation without inventing stale/file payloads.
      Snapshot.Has_Project := True;
      Snapshot.Project_State_Label := Null_Unbounded_String;
      Snapshot.Project_Label := To_Unbounded_String ("demo");
      Snapshot.Focus_Label := To_Unbounded_String ("File Tree");
      Snapshot.File_Tree_Status_Label := To_Unbounded_String ("File Tree: ready");
      Snapshot.Has_Command_Feedback := True;
      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("cancelled");
      Snapshot.Command_Feedback := To_Unbounded_String ("File Tree rename cancelled");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Focus: File Tree") > 0,
              "File Tree prompt cancel must leave corrective focus visible");
      Assert (Index (Right, "cancelled: File Tree rename cancelled") > 0,
              "File Tree prompt cancel must be visible as command outcome");
      Assert (Assert_Status_Line_Context_Coherent (Snapshot),
              "File Tree prompt-cancel status must remain coherent");

      --  File lifecycle recovery messages are emitted from several command
      --  paths with slightly different wording.  The status line should show
      --  the same primary outcome the user sees in command discovery, dirty
      --  close review, and file lifecycle prompts.
      Snapshot.Focus_Label := To_Unbounded_String ("Editor");
      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("failed");
      Snapshot.Command_Feedback := To_Unbounded_String ("Parent directory unavailable");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "failed: Parent directory is unavailable.") > 0,
              "status must canonicalize parent-directory failures");
      Snapshot.Command_Feedback :=
        To_Unbounded_String ("Parent directory does not exist: src/panels/");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "failed: Parent directory is unavailable.") > 0,
              "status must hide path-specific parent-directory variants behind the shared label");
      Snapshot.Command_Feedback := To_Unbounded_String ("File is not writable");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "failed: File is not writable.") > 0,
              "status must canonicalize unwritable file failures");
      Snapshot.Command_Feedback := To_Unbounded_String ("File is not readable");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "failed: File is not readable.") > 0,
              "status must canonicalize unreadable file failures");
      Snapshot.Command_Feedback :=
        To_Unbounded_String ("Could not reload file; buffer unchanged");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "failed: Could not reload file.") > 0,
              "status must canonicalize reload failure details");
      Snapshot.Command_Feedback :=
        To_Unbounded_String ("Could not write file; buffer remains dirty");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "failed: Could not save file.") > 0,
              "status must canonicalize write failure details");
      Assert (Assert_Status_Line_Context_Coherent (Snapshot),
              "file lifecycle recovery status labels remain coherent");

      --  Missing-target and boundary failures also arrive with surface-specific
      --  wording.  Keep the surface context in status, but use the same
      --  corrective condition labels that command feedback and dogfood flows use.
      Snapshot.Command_Feedback :=
        To_Unbounded_String ("Diagnostic target file is unavailable.");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "failed: Target no longer exists.") > 0,
              "status must canonicalize Diagnostics missing-target feedback");
      Snapshot.Command_Feedback :=
        To_Unbounded_String ("Target file missing or unavailable");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "failed: Target no longer exists.") > 0,
              "status must canonicalize source-labelled Diagnostics missing-target feedback");
      Snapshot.Command_Feedback :=
        To_Unbounded_String ("Selected diagnostic has no source target");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "failed: Selected diagnostic has no source target.") > 0,
              "status must canonicalize source-less Diagnostics feedback");
      Snapshot.Command_Feedback :=
        To_Unbounded_String (Editor.Commands.Reason_Diagnostic_Target_Line_Unavailable);
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "failed: Target line is unavailable.") > 0,
              "status must canonicalize Diagnostics missing-line feedback");
      Snapshot.Command_Feedback :=
        To_Unbounded_String ("Target path is outside the project");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "failed: Target is outside the current project.") > 0,
              "status must canonicalize project-boundary failures");

      Snapshot.Command_Feedback := Null_Unbounded_String;
      Snapshot.Has_Command_Feedback := False;
      Snapshot.Search_Status_Label :=
        To_Unbounded_String ("Search: Search result target unavailable");
      Snapshot.Outline_Status_Label :=
        To_Unbounded_String ("Outline: Outline target unavailable");
      Snapshot.Diagnostics_Status_Label :=
        To_Unbounded_String ("Diagnostics: Diagnostic target file is unavailable");
      Snapshot.File_Tree_Status_Label :=
        To_Unbounded_String ("File Tree: Target path is outside the project");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Search: Target no longer exists.") > 0,
              "Search missing-target status must be canonical");
      Assert (Index (Right, "Outline: Target no longer exists.") > 0,
              "Outline missing-target status must be canonical");
      Assert (Index (Right, "Diagnostics: Target no longer exists.") > 0,
              "Diagnostics missing-target status must be canonical");
      Snapshot.Diagnostics_Status_Label :=
        To_Unbounded_String ("Diagnostics: Target file missing or unavailable");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Diagnostics: Target no longer exists.") > 0,
              "Diagnostics source-labelled missing-target status must be canonical");
      Snapshot.Diagnostics_Status_Label :=
        To_Unbounded_String ("Diagnostics: No source target");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Diagnostics: Selected diagnostic has no source target.") > 0,
              "Diagnostics source-less status must be canonical");
      Assert (Index (Right, "File Tree: Target is outside the current project.") > 0,
              "File Tree boundary status must be canonical");
      Assert (Assert_Status_Line_Context_Coherent (Snapshot),
              "missing-target and boundary status labels remain coherent");

      --  Dirty close and lifecycle-transition blockers should retain their
      --  originating surface while using the same confirmation wording the
      --  command surface and dogfood flows expose.
      Snapshot.Search_Status_Label := Null_Unbounded_String;
      Snapshot.Outline_Status_Label := Null_Unbounded_String;
      Snapshot.Diagnostics_Status_Label := Null_Unbounded_String;
      Snapshot.File_Tree_Status_Label := Null_Unbounded_String;
      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("unavailable");
      Snapshot.Has_Command_Feedback := True;
      Snapshot.Command_Feedback := To_Unbounded_String ("Dirty buffer cannot be closed");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "unavailable: Unsaved changes require confirmation.") > 0,
              "dirty-close command feedback must use canonical confirmation wording");
      Snapshot.Command_Feedback :=
        To_Unbounded_String ("Cannot restore workspace with unsaved changes");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "unavailable: Unsaved changes require confirmation.") > 0,
              "workspace dirty guard feedback must use canonical confirmation wording");
      Snapshot.Command_Feedback :=
        To_Unbounded_String ("Save failed; buffer remains open and dirty");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "unavailable: Save failed; buffer remains open.") > 0,
              "save-and-close failure feedback must use one primary outcome");
      Snapshot.Command_Feedback :=
        To_Unbounded_String ("Dirty buffer file cannot be renamed");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "unavailable: Dirty buffer preserved.") > 0,
              "File Tree dirty rename feedback must use canonical preserved-dirty wording");
      Snapshot.Command_Feedback := To_Unbounded_String ("No open buffers");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "unavailable: No buffers open.") > 0,
              "Buffer List empty feedback must use canonical open-buffer wording");
      Snapshot.Command_Feedback := To_Unbounded_String ("Only one buffer open");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "unavailable: No other buffer.") > 0,
              "single-buffer navigation feedback must use canonical other-buffer wording");
      Snapshot.Command_Feedback := To_Unbounded_String ("Selected row is not a buffer");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "unavailable: Selected row is not a buffer.") > 0,
              "Buffer List row-type feedback must be punctuated consistently");

      Snapshot.Command_Feedback := Null_Unbounded_String;
      Snapshot.Has_Command_Feedback := False;
      Snapshot.Workspace_Status_Label :=
        To_Unbounded_String ("Workspace: Cannot restore workspace with unsaved changes");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Workspace: Unsaved changes require confirmation.") > 0,
              "Workspace status must canonicalize dirty-restore blockers");
      Snapshot.Workspace_Status_Label := Null_Unbounded_String;
      Snapshot.File_Tree_Status_Label :=
        To_Unbounded_String ("File Tree: Dirty buffer file cannot be deleted");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "File Tree: Dirty buffer preserved.") > 0,
              "File Tree dirty delete status must report preserved dirty text");
      Snapshot.File_Tree_Status_Label := Null_Unbounded_String;
      Snapshot.Has_Command_Feedback := True;
      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("failed");
      Snapshot.Command_Feedback :=
        To_Unbounded_String ("File changed on disk; choose how to proceed.");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "failed: File conflict requires resolution.") > 0,
              "status must canonicalize external-change conflict prompts");
      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("unavailable");
      Snapshot.Command_Feedback :=
        To_Unbounded_String ("Reload will discard unsaved changes. Disk version has changed since file was opened.");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "unavailable: Reload will discard unsaved changes.") > 0,
              "status must canonicalize reload conflict warnings");
      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("info");
      Snapshot.Command_Feedback :=
        To_Unbounded_String ("Kept buffer changes; file remains conflicted");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "info: Kept buffer changes; file remains conflicted.") > 0,
              "status must canonicalize keep-buffer conflict outcomes");

      Snapshot.Command_Feedback := Null_Unbounded_String;
      Snapshot.Has_Command_Feedback := False;
      Snapshot.File_State_Label :=
        To_Unbounded_String ("File conflict requires resolution before save-and-close");
      Left := To_Unbounded_String (Format_Left (Snapshot));
      Assert (Index (Left, "File conflict requires resolution.") > 0,
              "status-left must canonicalize file conflict blockers");
      Snapshot.File_State_Label :=
        To_Unbounded_String ("Reload will discard unsaved changes. Backing file was replaced.");
      Left := To_Unbounded_String (Format_Left (Snapshot));
      Assert (Index (Left, "Reload will discard unsaved changes.") > 0,
              "status-left must canonicalize reload conflict warnings");

      Snapshot.File_State_Label := To_Unbounded_String ("Bookmarks: No bookmarks");
      Left := To_Unbounded_String (Format_Left (Snapshot));
      Assert (Index (Left, "Bookmarks: No bookmarks.") > 0,
              "status-left must canonicalize Bookmarks empty state");
      Snapshot.File_State_Label := To_Unbounded_String ("Bookmarks: Bookmark target unavailable");
      Left := To_Unbounded_String (Format_Left (Snapshot));
      Assert (Index (Left, "Bookmarks: Target no longer exists.") > 0,
              "status-left must canonicalize Bookmarks stale target state");

      Snapshot.File_State_Label := Null_Unbounded_String;
      Snapshot.Find_Input_Open := True;
      Snapshot.Find_Query_Present := False;
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Find: No search query.") > 0,
              "Find empty-query status must use canonical search-query wording");

      Snapshot.Find_Query_Present := True;
      Snapshot.Active_Find_Match_Count := 0;
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Find: No matches.") > 0,
              "Find no-match status must use canonical no-match wording");

      Snapshot.Find_Input_Open := False;
      Snapshot.Find_Query_Present := False;
      Snapshot.Active_Find_Match_Count := 0;
      Snapshot.Has_Command_Feedback := True;
      Snapshot.Command_Feedback_Severity := To_Unbounded_String ("unavailable");
      Snapshot.Command_Feedback :=
        To_Unbounded_String ("Navigation: No navigation history to clear");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "unavailable: Navigation: No navigation history.") > 0,
              "Navigation empty-history status must be canonical");
      Snapshot.Command_Feedback :=
        To_Unbounded_String ("Navigation: Navigation target unavailable");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "unavailable: Navigation: Target no longer exists.") > 0,
              "Navigation stale-target status must be canonical");
      Snapshot.Command_Feedback := Null_Unbounded_String;
      Snapshot.Has_Command_Feedback := False;

      --  Buffer List review modes expose several empty states from the same
      --  multi-buffer workflow.  The status line should keep the Buffer List
      --  surface context while normalizing filtered/marked/pending/dirty-prune
      --  wording and punctuation.
      Snapshot.Workspace_Status_Label :=
        To_Unbounded_String ("Buffer List: No matching buffers");
      Snapshot.Recent_Projects_Status_Label :=
        To_Unbounded_String ("Buffer List: No pending marked targets");
      Snapshot.Startup_Status_Label :=
        To_Unbounded_String ("Buffer List: No dirty-prune preview targets");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Buffer List: No matching open buffers.") > 0,
              "status must canonicalize Buffer List filtered empty wording");
      Assert (Index (Right, "Buffer List: No pending close targets.") > 0,
              "status must canonicalize Buffer List pending marked-close wording");
      Assert (Index (Right, "Buffer List: No dirty-prune preview targets.") > 0,
              "status must canonicalize Buffer List dirty-prune preview wording");

      Snapshot.Workspace_Status_Label :=
        To_Unbounded_String ("Buffer List: No marked buffers");
      Snapshot.Recent_Projects_Status_Label :=
        To_Unbounded_String ("Buffer List: No removed dirty-prune apply targets");
      Snapshot.Startup_Status_Label :=
        To_Unbounded_String ("Buffer List: No pruned pending close targets");
      Right := To_Unbounded_String (Format_Right (Snapshot));
      Assert (Index (Right, "Buffer List: No marked buffers.") > 0,
              "status must canonicalize Buffer List marked empty wording");
      Assert (Index (Right, "Buffer List: No removed dirty-prune apply targets.") > 0,
              "status must canonicalize Buffer List removed apply wording");
      Assert (Index (Right, "Buffer List: No pruned pending close targets.") > 0,
              "status must canonicalize Buffer List pruned pending-close wording");

      Assert (Assert_Status_Line_Context_Coherent (Snapshot),
              "dirty close, lifecycle, and file-conflict status labels remain coherent");
   end Test_Remaining_Status_Workflow_Cases;


   overriding procedure Register_Tests
     (T : in out Status_Bar_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Status_Bar_Height_Follows_Config'Access,
         "Status Bar Height Follows Config");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Layout_Reserves_Bottom_Row'Access,
         "Layout Reserves Bottom Row");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Status_Bar_Does_Not_Change_X_Geometry'Access,
         "Status Bar Does Not Change X Geometry");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Disabled_Status_Bar_Reserves_No_Layout_Height'Access,
         "Disabled Status Bar Reserves No Layout Height");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Minimap_And_Scrollbars_Do_Not_Overlap_Status_Bar'Access,
         "Minimap And Scrollbars Do Not Overlap Status Bar");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Format_Uses_One_Based_Display'Access,
         "Format Uses One Based Display");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Format_Left_Uses_Untitled_And_Dirty_Marker'Access,
         "Format Left Uses Untitled And Dirty Marker");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Format_Includes_Project_Focus_Feature_And_Feedback'Access,
         "Format Includes Project Focus Feature And Feedback");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Format_Shows_Find_Empty_And_No_Matches'Access,
         "Format Shows Find Empty And No Matches");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Format_Shows_Wrapped_Find_State'Access,
         "format shows wrapped find state");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Format_Uses_No_Project_Fallback'Access,
         "Format Uses No Project Fallback");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Format_Shows_Selection_Detail'Access,
         "format shows selection detail");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Format_Shows_File_State_And_Feature_Summaries'Access,
         "format shows file state and feature summaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_No_Buffer_And_Selection_Line_Fallback'Access,
         "no-buffer and selection fallback labels");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Status_Coherence_Assertions'Access,
         "status coherence assertions");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_State_Label_Overrides_Project_Fallback'Access,
         "project pending status overrides project fallback");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Coherence_Rejects_Missing_Buffer_Label'Access,
         "coherence rejects missing active-buffer label");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Format_Shows_Focus_Mode_And_Overlay_Marker'Access,
         "format shows focus mode and overlay marker");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Format_Shows_Main_Context_Summaries'Access,
         "format shows main context summaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Status_Truncates_Long_Labels_Deterministically'Access,
         "status truncates long labels deterministically");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Status_Coherence_Covers_Main_Context'Access,
         "status coherence covers main context");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dirty_State_Label_And_Compact_Bounds'Access,
         "dirty state label and compact bounds");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Status_Layout_Handles_Zero_Width'Access,
         "status layout handles zero width");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_State_Marker_Assertion_Covers_Known_States'Access,
         "file state marker assertion covers known states");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Non_Priority_Command_Outcome_Appears_Once'Access,
         "non-priority command outcome appears once");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Segment_Builders_Are_Coherent_And_Scalar'Access,
         "segment builders are coherent and scalar");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Status_Is_Explicit_Focus_And_Single_Line'Access,
         "status is explicit focus and single-line");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Outcome_Uses_Public_Classes'Access,
         "command outcome uses public classes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Status_Config_And_Payload_Boundaries'Access,
         "status config and payload boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_File_And_Row_Output_Boundary'Access,
         "project file and row output boundary");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Compact_Layout_Preserves_Priority'Access,
         "compact layout preserves priority");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Compact_Policy_Uses_Priority_Context'Access,
         "render compact policy uses priority context");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Status_Line_Workflow_Coherence'Access,
         "status line workflow coherence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Remaining_Status_Workflow_Cases'Access,
         "remaining status workflow cases");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Emits_Status_Bar_Layers'Access,
         "Render Emits Status Bar Layers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Click_In_Status_Bar_Does_Not_Move_Caret'Access,
         "Click In Status Bar Does Not Move Caret");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Narrow_Text_Viewport_Keeps_Caret_Visible'Access,
         "narrow text viewport keeps caret visible");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Zero_Row_Text_Viewport_Emits_No_Text_Glyphs'Access,
         "zero-row text viewport emits no text glyphs");
   end Register_Tests;

end Editor.Status_Bar.Tests;
