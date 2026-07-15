with Editor.Test_Temp;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Interfaces.C;
with Editor.Commands;
with Editor.Buffers;
with Editor.Buffer_Switcher;
with Editor.Command_Palette;
with Editor.Cursor;
with Editor.Diagnostics;
with Editor.Executor;
with Editor.Input_Bridge;
with Editor.Layout;
with Editor.Lifecycle_Audit;
with Editor.Line_Numbers;
with Editor.Messages;
with Editor.Pending_Transitions;
with Editor.Project;
with Editor.Recent_Projects;
with Editor.Dirty_Guards;
with Editor.Minimap;
with Editor.Scrollbars;
with Editor.Render_Layers;
with Editor.Render_Model;
with Editor.Render_Packet;
with Editor.Settings;
with Editor.Settings_Management;
with Editor.State;
with Editor.Theme;
with Editor.View;

package body Editor.Settings.Tests is

   use type Editor.Settings.Settings_Status;
   use type Editor.Line_Numbers.Line_Number_Mode;
   use type Editor.Cursor.Cursor_Style;
   use type Editor.Commands.Command_Category;
   use type Editor.Settings.Settings_Apply_Status;
   use type Editor.Messages.Message_Severity;
   use type Interfaces.C.int;
   use type Editor.Lifecycle_Audit.Lifecycle_Audit_Status;



   function Read_All (Path : String) return String is
      File   : Ada.Text_IO.File_Type;
      Result : Unbounded_String := Null_Unbounded_String;
   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         Append (Result, Ada.Text_IO.Get_Line (File));
         Append (Result, ASCII.LF);
      end loop;
      Ada.Text_IO.Close (File);
      return To_String (Result);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         return "";
   end Read_All;

   procedure Delete_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_File (Path);
      end if;
   exception
      when others => null;
   end Delete_If_Exists;

   function Temp_Path (Name : String) return String is
   begin
      return Editor.Test_Temp.Base & "/editor_" & Name;
   end Temp_Path;

   procedure Remove_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_File (Path);
      end if;
   exception
      when others => null;
   end Remove_If_Exists;

   procedure Write_Text (Path : String; Text : String) is
      File : Ada.Text_IO.File_Type;
   begin
      Ada.Text_IO.Create (File, Ada.Text_IO.Out_File, Path);
      Ada.Text_IO.Put (File, Text);
      Ada.Text_IO.Close (File);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         raise;
   end Write_Text;

   function Has_Rect_On_Layer
     (Packet : Editor.Render_Packet.Render_Packet;
      Layer  : Editor.Render_Layers.Render_Layer) return Boolean
   is
   begin
      for I in 0 .. Integer (Packet.Rect_Count) - 1 loop
         if Packet.Rects (Natural (I)).Layer = Editor.Render_Layers.To_C (Layer) then
            return True;
         end if;
      end loop;
      return False;
   end Has_Rect_On_Layer;

   function Glyph_Count_On_Layer
     (Packet : Editor.Render_Packet.Render_Packet;
      Layer  : Editor.Render_Layers.Render_Layer) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 0 .. Integer (Packet.Glyph_Count) - 1 loop
         if Packet.Glyphs (Natural (I)).Layer = Editor.Render_Layers.To_C (Layer) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Glyph_Count_On_Layer;

   function Rect_Count_On_Layer
     (Packet : Editor.Render_Packet.Render_Packet;
      Layer  : Editor.Render_Layers.Render_Layer) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 0 .. Integer (Packet.Rect_Count) - 1 loop
         if Packet.Rects (Natural (I)).Layer = Editor.Render_Layers.To_C (Layer) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Rect_Count_On_Layer;

   function Same_Color
     (G     : Editor.Render_Packet.Glyph_Command;
      Color : Editor.Theme.Color_RGB) return Boolean
   is
      Epsilon : constant Float := 0.0001;
   begin
      return abs (Float (G.R) - Color.R) <= Epsilon
        and then abs (Float (G.G) - Color.G) <= Epsilon
        and then abs (Float (G.B) - Color.B) <= Epsilon;
   end Same_Color;

   procedure Prepare_Text
     (Text : String)
   is
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Text);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (800, 600);
   end Prepare_Text;

   procedure Test_Default_Settings_Enable_Features
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Settings : Editor.Settings.Settings_State := Editor.Settings.Current;
   begin
      Editor.Settings.Reset;
      Settings := Editor.Settings.Current;
      Assert (Settings.Show_Minimap, "Default settings must show minimap");
      Assert (Settings.Show_Line_Numbers, "Default settings must show line numbers");
      Assert (Settings.Highlight_Current_Line,
              "Default settings must highlight current text line");
      Assert (Settings.Highlight_Current_Gutter,
              "Default settings must highlight current gutter row");
      Assert (Settings.Cursor_Blink_Enabled,
              "Default settings must enable cursor blinking");
      Assert (Settings.Use_Syntax_Colouring,
              "Default settings must enable syntax colouring");
      Assert (Settings.Show_Diagnostics,
              "Default settings must show diagnostics");
   end Test_Default_Settings_Enable_Features;

   procedure Test_Disabling_Line_Numbers_Removes_Gutter_Glyphs
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Prepare_Text ("abc" & ASCII.LF & "def");
      Editor.Input_Bridge.Build_Render_Packet (Packet);
      Assert (Glyph_Count_On_Layer (Packet, Editor.Render_Layers.Gutter_Text_Layer) > 0,
              "Default rendering must emit gutter line-number glyphs");

      Editor.Settings.Set_Show_Line_Numbers (False);
      Editor.Input_Bridge.Build_Render_Packet (Packet);
      Assert (Glyph_Count_On_Layer (Packet, Editor.Render_Layers.Gutter_Text_Layer) = 0,
              "Disabling line numbers must remove gutter line-number glyphs");
   end Test_Disabling_Line_Numbers_Removes_Gutter_Glyphs;

   procedure Test_Disabling_Current_Line_Highlight_Removes_Text_Rect
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Prepare_Text ("abc");
      Editor.Settings.Set_Highlight_Current_Line (False);
      Editor.Settings.Set_Highlight_Current_Gutter (False);
      Editor.Input_Bridge.Build_Render_Packet (Packet);
      Assert (not Has_Rect_On_Layer (Packet, Editor.Render_Layers.Current_Line_Layer),
              "Disabling current-line and current-gutter highlights must emit no current-line rects");
   end Test_Disabling_Current_Line_Highlight_Removes_Text_Rect;

   procedure Test_Disabling_Minimap_Removes_Rects
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Prepare_Text ("abc" & ASCII.LF & "def");
      Editor.Settings.Set_Show_Minimap (False);
      Editor.Input_Bridge.Build_Render_Packet (Packet);
      Assert (Rect_Count_On_Layer (Packet, Editor.Render_Layers.Minimap_Background_Layer) = 0,
              "Disabling minimap setting must remove minimap background rects");
      Assert (Rect_Count_On_Layer (Packet, Editor.Render_Layers.Minimap_Content_Layer) = 0,
              "Disabling minimap setting must remove minimap content rects");
      Assert (Rect_Count_On_Layer (Packet, Editor.Render_Layers.Minimap_Viewport_Layer) = 0,
              "Disabling minimap setting must remove minimap viewport rects");
   end Test_Disabling_Minimap_Removes_Rects;



   procedure Test_Disabling_Minimap_Expands_Text_Snapshot
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Text : Unbounded_String := Null_Unbounded_String;
      With_Minimap    : Editor.Render_Model.Render_Snapshot;
      Without_Minimap : Editor.Render_Model.Render_Snapshot;
   begin
      for I in 1 .. 200 loop
         Append (Text, 'x');
      end loop;

      Prepare_Text (To_String (Text));
      Editor.View.Set_Viewport (800, 120);

      Editor.Settings.Set_Show_Minimap (True);
      Editor.Input_Bridge.Get_Render_Snapshot (With_Minimap);

      Editor.Settings.Set_Show_Minimap (False);
      Editor.Input_Bridge.Get_Render_Snapshot (Without_Minimap);

      Assert (With_Minimap.Visible_Visual_Count > 0
              and then Without_Minimap.Visible_Visual_Count > 0,
              "Snapshots must contain at least one visible visual row");
      Assert (Without_Minimap.Visible_Visual_Rows (1).End_Col
              > With_Minimap.Visible_Visual_Rows (1).End_Col,
              "Disabling minimap must expand the text snapshot viewport width");
      Assert (Without_Minimap.Minimap_Sample_Count = 0,
              "Disabled minimap setting must suppress minimap snapshot samples");
   end Test_Disabling_Minimap_Expands_Text_Snapshot;

   procedure Test_Disabling_Minimap_Disables_Input_Routing
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Cmd : Editor.Commands.Command;
      Text : Unbounded_String := Null_Unbounded_String;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Config : constant Editor.Minimap.Minimap_Config := Editor.Minimap.Current;
      X : Natural := 0;
      Y : Natural := 0;
   begin
      for I in 1 .. 80 loop
         Append (Text, "line");
         Append (Text, ASCII.LF);
      end loop;

      Prepare_Text (To_String (Text));
      Editor.View.Set_Viewport (800, 80);
      Editor.Settings.Set_Show_Minimap (False);

      X := Natural (Editor.Minimap.Left_X (Layout, 800, Config)) + 1;
      Y := 70;
      Cmd.Kind := Editor.Commands.Move_To_Point;
      Cmd.Click_X := X;
      Cmd.Click_Y := Y;
      Editor.Input_Bridge.Handle (Cmd);

      Assert (Editor.View.Scroll_Y = 0,
              "Disabled minimap setting must prevent minimap hit-routing from changing vertical scroll");
   end Test_Disabling_Minimap_Disables_Input_Routing;

   procedure Test_Disabling_Syntax_Uses_Default_Text_Color
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Packet : Editor.Render_Packet.Render_Packet;
      Default_Color : constant Editor.Theme.Color_RGB := Editor.Theme.Text_Default;
   begin
      Prepare_Text ("procedure X is begin null; end X;");
      Editor.Settings.Set_Use_Syntax_Colouring (False);
      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Assert (Glyph_Count_On_Layer (Packet, Editor.Render_Layers.Text_Layer) > 0,
              "Rendering text must emit text glyphs");
      for I in 0 .. Integer (Packet.Glyph_Count) - 1 loop
         if Packet.Glyphs (Natural (I)).Layer = Editor.Render_Layers.To_C (Editor.Render_Layers.Text_Layer) then
            Assert (Same_Color (Packet.Glyphs (Natural (I)), Default_Color),
                    "Disabled syntax colouring must emit every text glyph with Theme.Text_Default");
         end if;
      end loop;
   end Test_Disabling_Syntax_Uses_Default_Text_Color;

   procedure Test_Disabling_Diagnostics_Removes_Diagnostic_Rects
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abcdef");
      Editor.State.Add_Diagnostic (S, 1, 4, Editor.Diagnostics.Error);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (800, 600);
      Editor.Settings.Set_Show_Diagnostics (False);
      Editor.Input_Bridge.Build_Render_Packet (Packet);
      Assert (Rect_Count_On_Layer (Packet, Editor.Render_Layers.Diagnostic_Layer) = 0,
              "Disabling diagnostics must emit no diagnostic decoration rects");
   end Test_Disabling_Diagnostics_Removes_Diagnostic_Rects;

   procedure Test_Command_Palette_Toggle_Changes_Setting
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Cmd : Editor.Commands.Command;
   begin
      Prepare_Text ("abc");
      Assert (Editor.Settings.Show_Diagnostics,
              "Diagnostics setting must start enabled for palette toggle test");

      Cmd.Kind := Editor.Commands.Open_Command_Palette;
      Editor.Input_Bridge.Handle (Cmd);
      declare
         Query : constant String := "toggle diagnostics";
      begin
         for Ch of Query loop
         Cmd.Kind := Editor.Commands.Insert_Text_Input;
         Cmd.Ch := Ch;
         Cmd.Text := To_Unbounded_String (String'(1 => Ch));
         Editor.Input_Bridge.Handle (Cmd);
         end loop;
      end;
      Cmd.Kind := Editor.Commands.Palette_Accept;
      Editor.Input_Bridge.Handle (Cmd);

      Assert (not Editor.Settings.Show_Diagnostics,
              "Executing Toggle Diagnostics from the palette must mutate Editor.Settings");
      Assert (not Editor.Command_Palette.Is_Open,
              "Accepting a setting toggle command must close the palette");
   end Test_Command_Palette_Toggle_Changes_Setting;



   procedure Test_Settings_Model_Round_Trip_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Path    : constant String := Editor.Test_Temp.Base & "/editor_settings_roundtrip.txt";
      Path_2  : constant String := Editor.Test_Temp.Base & "/editor_settings_roundtrip_2.txt";
      Model   : Editor.Settings.Settings_Model;
      Loaded  : Editor.Settings.Settings_Model;
      Status  : Editor.Settings.Settings_Status;
      Status2 : Editor.Settings.Settings_Status;
   begin
      Delete_If_Exists (Path);
      Delete_If_Exists (Path_2);
      Editor.Settings.Set_Defaults (Model);
      Editor.Settings.Set_Theme_Id (Model, "dark");
      Editor.Settings.Set_Line_Number_Mode_Name (Model, "relative");
      Editor.Settings.Set_Cursor_Style_Name (Model, "bar");
      Editor.Settings.Set_Cursor_Blink (Model, True);
      Editor.Settings.Set_Minimap_Visible (Model, True);
      Editor.Settings.Set_Scrollbars_Visible (Model, True);

      Editor.Settings.Save_To_File (Model, Path, Status);
      Assert (Status = Editor.Settings.Settings_Ok,
              "Save_To_File must report Settings_Ok for writable temp file");
      Editor.Settings.Load_From_File (Path, Loaded, Status);
      Assert (Status = Editor.Settings.Settings_Ok,
              "Load_From_File must round-trip deterministic settings");
      Assert (Editor.Settings.Equivalent (Model, Loaded),
              "Loaded settings must be semantically equivalent to saved settings");

      Editor.Settings.Save_To_File (Loaded, Path_2, Status2);
      Assert (Status2 = Editor.Settings.Settings_Ok,
              "Second Save_To_File must report Settings_Ok");
      Assert (Read_All (Path) = Read_All (Path_2),
              "Saving equivalent settings twice must produce identical bytes");
   end Test_Settings_Model_Round_Trip_Deterministic;

   procedure Test_Settings_Load_Statuses
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Missing : constant String := Editor.Test_Temp.Base & "/editor_settings_missing.txt";
      Invalid : constant String := Editor.Test_Temp.Base & "/editor_settings_invalid.txt";
      Future  : constant String := Editor.Test_Temp.Base & "/editor_settings_future.txt";
      Model   : Editor.Settings.Settings_Model;
      Status  : Editor.Settings.Settings_Status;
   begin
      Delete_If_Exists (Missing);
      Editor.Settings.Load_From_File (Missing, Model, Status);
      Assert (Status = Editor.Settings.Settings_Not_Found,
              "Missing settings file must be a normal Settings_Not_Found result");

      Write_Text (Invalid, "not-a-settings-file" & ASCII.LF);
      Editor.Settings.Load_From_File (Invalid, Model, Status);
      Assert (Status = Editor.Settings.Settings_Invalid_Format,
              "Invalid settings header must be rejected");

      Write_Text (Future, "editor-settings-version=999" & ASCII.LF);
      Editor.Settings.Load_From_File (Future, Model, Status);
      Assert (Status = Editor.Settings.Settings_Unsupported_Version,
              "Future settings versions must be a hard load failure");
   end Test_Settings_Load_Statuses;

   procedure Test_Settings_Partial_Load_Defaults_Invalid_Optional_Value
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Path   : constant String := Editor.Test_Temp.Base & "/editor_settings_partial.txt";
      Model  : Editor.Settings.Settings_Model;
      Status : Editor.Settings.Settings_Status;
   begin
      Write_Text
        (Path,
         "editor-settings-version=1" & ASCII.LF
         & "[appearance]" & ASCII.LF
         & "theme=dark" & ASCII.LF
         & "[editor]" & ASCII.LF
         & "line-numbers=invalid" & ASCII.LF
         & "cursor-style=also-invalid" & ASCII.LF
         & "cursor-blink=maybe" & ASCII.LF);

      Editor.Settings.Load_From_File (Path, Model, Status);
      Assert (Status = Editor.Settings.Settings_Partial_Load,
              "Invalid optional settings values must produce partial load status");
      Assert (Editor.Settings.Line_Number_Mode_Name (Model) = "absolute",
              "Invalid line-number mode must fall back to default");
      Assert (Editor.Settings.Cursor_Style_Name (Model) = "bar",
              "Invalid cursor style must fall back to default");
      Assert (Editor.Settings.Cursor_Blink (Model),
              "Invalid cursor blink value must fall back to default true");
   end Test_Settings_Partial_Load_Defaults_Invalid_Optional_Value;

   procedure Test_Apply_Settings_Changes_Line_Number_And_Cursor_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Model  : Editor.Settings.Settings_Model;
   begin
      Editor.State.Init (S);
      Editor.State.Set_Dirty (S, True);
      Editor.Settings.Set_Defaults (Model);
      Editor.Settings.Set_Line_Number_Mode_Name (Model, "relative");
      Editor.Settings.Set_Cursor_Style_Name (Model, "block");
      Editor.Settings.Set_Cursor_Blink (Model, False);
      Editor.Settings.Set_Minimap_Visible (Model, False);

      Editor.State.Apply_Settings (S, Model);

      Assert (Editor.Line_Numbers.Current.Mode = Editor.Line_Numbers.Relative_Line_Numbers,
              "Apply_Settings must apply valid persisted line-number mode");
      Assert (Editor.Cursor.Current.Style = Editor.Cursor.Block_Cursor,
              "Apply_Settings must apply valid persisted cursor style");
      Assert (not Editor.Cursor.Current_Blink.Blink_Enabled,
              "Apply_Settings must apply cursor blink setting");
      Assert (not Editor.Settings.Show_Minimap,
              "Apply_Settings must apply minimap visibility default");
      Assert (Editor.State.Is_Dirty (S),
              "Apply_Settings must not clear dirty buffer state");
   end Test_Apply_Settings_Changes_Line_Number_And_Cursor_Only;

   procedure Test_Settings_Command_Descriptors
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Commands.Label (Editor.Commands.Command_Save_Settings) = "Save Settings",
              "Save Settings descriptor must exist");
      Assert (Editor.Commands.Label (Editor.Commands.Command_Reload_Settings) = "Reload Settings",
              "Reload Settings descriptor must exist");
      Assert (Editor.Commands.Label (Editor.Commands.Command_Reset_Settings_To_Defaults) =
              "Reset Settings to Defaults",
              "Reset Settings to Defaults descriptor must exist");
      Assert (Editor.Commands.Category (Editor.Commands.Command_Save_Settings) =
              Editor.Commands.Settings_Category,
              "Settings commands must use the Settings category");
      Assert (Editor.Commands.Descriptor_Is_Complete
                (Editor.Commands.Command_Save_Settings),
              "Settings command descriptors must satisfy command audit completeness");
   end Test_Settings_Command_Descriptors;



   procedure Test_Setting_Identifiers_Are_Stable_Format_Keys
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Settings.Setting_Name_Theme = "theme",
              "Theme setting key must be stable and independent of command labels");
      Assert (Editor.Settings.Setting_Name_Line_Numbers = "line-numbers",
              "Line-number setting key must be stable");
      Assert (Editor.Settings.Setting_Name_Cursor_Style = "cursor-style",
              "Cursor style setting key must be stable");
      Assert (Editor.Settings.Setting_Name_Cursor_Blink = "cursor-blink",
              "Cursor blink setting key must be stable");
      Assert (Editor.Settings.Setting_Name_Format_On_Save = "format-on-save",
              "Format-on-save setting key must be stable");
      Assert (Editor.Settings.Setting_Name_Minimap_Visible = "minimap-visible",
              "Minimap visibility setting key must be stable");
      Assert (Editor.Settings.Setting_Name_Scrollbars_Visible = "scrollbars-visible",
              "Scrollbar visibility setting key must be stable");
      Assert (Editor.Settings.Setting_Name_Command_Palette_Show_Unavailable =
              "show-unavailable",
              "Palette unavailable-row setting key must be stable");
      Assert (Editor.Settings.Setting_Name_Command_Palette_Show_Keybindings =
              "show-keybindings",
              "Palette keybinding-display setting key must be stable");
      Assert (Editor.Settings.Setting_Name_Command_Palette_Show_Selected_Description =
              "show-selected-description",
              "Palette selected-description setting key must be stable");
   end Test_Setting_Identifiers_Are_Stable_Format_Keys;

   procedure Test_Apply_Settings_Returns_Subsystem_Summary
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Model   : Editor.Settings.Settings_Model;
      Summary : Editor.Settings.Settings_Apply_Summary;
   begin
      Editor.State.Init (S);
      Editor.Settings.Set_Defaults (Model);
      Editor.Settings.Set_Line_Number_Mode_Name (Model, "hybrid");
      Editor.Settings.Set_Cursor_Blink (Model, False);
      Editor.Settings.Set_Minimap_Visible (Model, False);
      Editor.Settings.Set_Scrollbars_Visible (Model, False);
      Editor.State.Apply_Settings (S, Model, Summary);

      Assert (Summary.Status = Editor.Settings.Settings_Apply_Ok,
              "Valid settings apply must report an OK summary");
      Assert (Summary.Theme_Applied,
              "Apply summary must note theme application");
      Assert (Summary.Line_Numbers_Applied,
              "Apply summary must note line-number application");
      Assert (Summary.Cursor_Applied,
              "Apply summary must note cursor application");
      Assert (Summary.Minimap_Applied,
              "Apply summary must note minimap application");
      Assert (Summary.Scrollbars_Applied,
              "Apply summary must note scrollbar application");
      Assert (Summary.Command_Palette_Applied,
              "Apply summary must note command-palette application");
      Assert (not Editor.Minimap.Enabled,
              "Apply_Settings must route minimap visibility through Minimap API");
      Assert (not Editor.Scrollbars.Enabled,
              "Apply_Settings must route scrollbar visibility through Scrollbars API");
   end Test_Apply_Settings_Returns_Subsystem_Summary;

   procedure Test_Command_Palette_Display_Settings_Are_Applied
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Model  : Editor.Settings.Settings_Model;
      Config : Editor.Command_Palette.Command_Palette_Config;
   begin
      Editor.State.Init (S);
      Editor.Settings.Set_Defaults (Model);
      Editor.Settings.Set_Command_Palette_Show_Unavailable (Model, False);
      Editor.Settings.Set_Command_Palette_Show_Keybindings (Model, False);
      Editor.State.Apply_Settings (S, Model);
      Config := Editor.Command_Palette.Current_Config;
      Assert (not Config.Show_Unavailable_Commands,
              "Settings must apply command-palette unavailable-row preference");
      Assert (not Config.Show_Keybindings,
              "Settings must apply command-palette keybinding display preference");
   end Test_Command_Palette_Display_Settings_Are_Applied;

   procedure Test_Build_From_Current_Captures_View_And_Palette_Preferences
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Palette : Editor.Command_Palette.Command_Palette_Config :=
        Editor.Command_Palette.Current_Config;
      Model   : Editor.Settings.Settings_Model;
   begin
      Editor.Minimap.Set_Enabled (False);
      Editor.Scrollbars.Set_Enabled (False);
      Palette.Show_Unavailable_Commands := False;
      Palette.Show_Keybindings := False;
      Editor.Command_Palette.Set_Current_Config (Palette);

      Model := Editor.Settings.Build_From_Current;
      Assert (not Editor.Settings.Minimap_Visible (Model),
              "Build_From_Current must persist live minimap visibility");
      Assert (not Editor.Settings.Scrollbars_Visible (Model),
              "Build_From_Current must persist live scrollbar visibility");
      Assert (not Editor.Settings.Command_Palette_Show_Unavailable (Model),
              "Build_From_Current must persist palette unavailable-row display flag");
      Assert (not Editor.Settings.Command_Palette_Show_Keybindings (Model),
              "Build_From_Current must persist palette keybinding display flag");
   end Test_Build_From_Current_Captures_View_And_Palette_Preferences;

   procedure Test_Settings_Toggle_Commands_Are_Settings_Category
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Commands.Category (Editor.Commands.Command_Toggle_Line_Number_Mode) =
              Editor.Commands.Settings_Category,
              "Toggle Line Number Mode must be discoverable as a Settings command");
      Assert (Editor.Commands.Category (Editor.Commands.Command_Toggle_Minimap) =
              Editor.Commands.Settings_Category,
              "Toggle Minimap must be discoverable as a Settings command");
      Assert (Editor.Commands.Category (Editor.Commands.Command_Toggle_Scrollbars) =
              Editor.Commands.Settings_Category,
              "Toggle Scrollbars must be discoverable as a Settings command");
      Assert (Editor.Commands.Category (Editor.Commands.Command_Toggle_Cursor_Blink) =
              Editor.Commands.Settings_Category,
              "Toggle Cursor Blink must be discoverable as a Settings command");
      Assert (Editor.Commands.Descriptor_Is_Complete
                (Editor.Commands.Command_Toggle_Scrollbars),
              "Toggle Scrollbars descriptor must satisfy command audit completeness");
   end Test_Settings_Toggle_Commands_Are_Settings_Category;

   procedure Test_Cursor_Blink_Setting_Controls_Cursor
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Editor.Settings.Reset;
      Editor.Settings.Set_Cursor_Blink_Enabled (False);
      Assert (not Editor.Cursor.Current_Blink.Blink_Enabled,
              "Disabling cursor blink in settings must update Editor.Cursor blink policy");
      Assert (Editor.Cursor.Visible (100.0),
              "Cursor must remain visible when blinking is disabled");
   end Test_Cursor_Blink_Setting_Controls_Cursor;

   procedure Test_Settings_Toggle_Commands_Emit_Canonical_Messages
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Found : Boolean := False;
      M     : Editor.Messages.Editor_Message;
   begin
      Editor.State.Init (S);

      Editor.Minimap.Set_Enabled (True);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Minimap);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found, "Toggle Minimap must emit one canonical outcome message");
      Assert (To_String (M.Text) = "Minimap hidden",
              "Toggle Minimap off message must be canonical");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Minimap);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (To_String (M.Text) = "Minimap shown",
              "Toggle Minimap on message must be canonical");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Toggle_Line_Number_Mode);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (To_String (M.Text) = "Line number mode changed",
              "Line-number mode toggle message must be canonical");

      Editor.Settings.Set_Cursor_Blink_Enabled (True);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Cursor_Blink);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (To_String (M.Text) = "Cursor blink disabled",
              "Cursor blink off message must be canonical");
   end Test_Settings_Toggle_Commands_Emit_Canonical_Messages;

   procedure Test_Save_Settings_Persists_Selected_Description_Preference
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model  : Editor.Settings.Settings_Model;
      Loaded : Editor.Settings.Settings_Model;
      Status : Editor.Settings.Settings_Status;
      Path   : constant String := Temp_Path ("selected_description.settings");
      Text   : Unbounded_String;
   begin
      Remove_If_Exists (Path);
      Editor.Settings.Set_Defaults (Model);
      Editor.Settings.Set_Command_Palette_Show_Selected_Description
        (Model, False);
      Editor.Settings.Save_To_File (Model, Path, Status);
      Assert (Status = Editor.Settings.Settings_Ok,
              "Saving settings with selected-description preference must succeed");
      Text := To_Unbounded_String (Read_All (Path));
      Assert (Index (Text, "show-selected-description=false") > 0,
              "Normalized settings must persist command-palette selected-description preference");
      Editor.Settings.Load_From_File (Path, Loaded, Status);
      Assert (Status = Editor.Settings.Settings_Ok,
              "Loading normalized selected-description settings must succeed");
      Assert (not Editor.Settings.Command_Palette_Show_Selected_Description (Loaded),
              "Loaded settings must preserve selected-description preference");
      Remove_If_Exists (Path);
   end Test_Save_Settings_Persists_Selected_Description_Preference;

   procedure Test_Set_Theme_Commands_Are_Settings_Commands
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Found : Boolean := False;
      M     : Editor.Messages.Editor_Message;
   begin
      Assert (Editor.Commands.Category (Editor.Commands.Command_Set_Theme_Light) =
              Editor.Commands.Settings_Category,
              "Set Theme Light must be a Settings command");
      Assert (Editor.Commands.Category (Editor.Commands.Command_Set_Theme_Dark) =
              Editor.Commands.Settings_Category,
              "Set Theme Dark must be a Settings command");
      Assert (Editor.Commands.Descriptor_Is_Complete
                (Editor.Commands.Command_Set_Theme_Light),
              "Set Theme Light descriptor must satisfy command audit completeness");

      Editor.State.Init (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Set_Theme_Light);
      Assert (Editor.Theme.Active_Theme_Id = "light",
              "Set Theme Light must mutate the live theme preference");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Theme changed",
              "Set Theme Light must emit the canonical theme message");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Set_Theme_Dark);
      Assert (Editor.Theme.Active_Theme_Id = "dark",
              "Set Theme Dark must mutate the live theme preference");
   end Test_Set_Theme_Commands_Are_Settings_Commands;





   procedure Test_Save_Output_Is_Settings_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path   : constant String := Editor.Test_Temp.Base & "/editor_settings_only.txt";
      Model  : Editor.Settings.Settings_Model;
      Status : Editor.Settings.Settings_Status;
      Text   : Unbounded_String;
   begin
      Delete_If_Exists (Path);
      Editor.Settings.Set_Defaults (Model);
      Editor.Settings.Save_To_File (Model, Path, Status);
      Assert (Status = Editor.Settings.Settings_Ok,
              "settings-only fixture save must succeed");
      Text := To_Unbounded_String (Read_All (Path));

      Assert (Index (Text, "editor-settings-version=1") > 0,
              "settings save must include the settings format header");
      Assert (Index (Text, "theme=") > 0,
              "settings save must include approved appearance preference");
      Assert (Index (Text, "line-numbers=") > 0,
              "settings save must include approved editor preference");
      Assert (Index (Text, "show-keybindings=") > 0,
              "settings save may include command-palette keybinding-display preference");

      Assert (Index (Text, "workspace") = 0,
              "settings save must not serialize workspace/session state");
      Assert (Index (Text, "recent-project") = 0,
              "settings save must not serialize recent-project entries");
      Assert (Index (Text, "message-row") = 0,
              "settings save must not serialize Messages rows");
      Assert (Index (Text, "diagnostic-row") = 0,
              "settings save must not serialize Diagnostics rows");
      Assert (Index (Text, "search-result") = 0,
              "settings save must not serialize Search Results rows");
      Assert (Index (Text, "outline-item") = 0,
              "settings save must not serialize Outline content");
      Assert (Index (Text, "current-symbol") = 0,
              "settings save must not serialize current-symbol state");
      Assert (Index (Text, "outline-filter") = 0,
              "settings save must not serialize Outline filter text");
      Assert (Index (Text, "filtered-outline") = 0,
              "settings save must not serialize filtered Outline rows");
      Assert (Index (Text, "last-navigated-symbol") = 0,
              "settings save must not serialize symbol navigation history");
      Assert (Index (Text, "feature-row") = 0,
              "settings save must not serialize Feature Panel rows");
      Assert (Index (Text, "buffer-content") = 0,
              "settings save must not serialize buffer content");
      Assert (Index (Text, "clipboard") = 0,
              "settings save must not serialize clipboard content");
      Assert (Index (Text, "undo") = 0,
              "settings save must not serialize undo history");
      Assert (Index (Text, "build-command") = 0,
              "settings save must not serialize public-build state");
      Assert (Index (Text, "Ctrl+") = 0,
              "settings save must not serialize concrete keybinding mappings");
      Delete_If_Exists (Path);
   end Test_Save_Output_Is_Settings_Only;


   procedure Test_Settings_Save_Excludes_Buffer_List_Runtime_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path   : constant String := Editor.Test_Temp.Base & "/editor_settings_excludes_buffer_list.txt";
      S      : Editor.State.State_Type;
      Status : Editor.Settings.Settings_Status;
      Text   : Unbounded_String;
   begin
      Delete_If_Exists (Path);
      Editor.State.Init (S);

      --  seed representative Buffer List runtime-only UI state
      --  before saving Settings.  Settings persistence owns only global
      --  preferences and must not observe or serialize this transient panel
      --  state.
      Editor.Buffer_Switcher.Open (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Set_Filter_Text
        (S.Buffer_Switcher, "buffer-list-query-must-not-persist");
      Editor.Buffer_Switcher.Set_Dirty_Filter (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Set_Sort_Mode
        (S.Buffer_Switcher, Editor.Buffer_Switcher.Name_Sort);
      Editor.Buffer_Switcher.Show_Marked_Review (S.Buffer_Switcher);

      Editor.Settings.Save_To_File (S.Settings, Path, Status);
      Assert (Status = Editor.Settings.Settings_Ok,
              "settings save should succeed with Buffer List runtime state present");

      Text := To_Unbounded_String (Read_All (Path));
      Assert (Index (Text, "editor-settings-version=1") > 0,
              "settings save must still write the settings header");
      Assert (Index (Text, "buffer-list-query-must-not-persist") = 0,
              "settings save must exclude Buffer List query/filter text");
      Assert (Index (Text, "buffer-list") = 0,
              "settings save must exclude Buffer List runtime fields");
      Assert (Index (Text, "buffer-switcher") = 0,
              "settings save must exclude removed Buffer Switcher runtime fields");
      Assert (Index (Text, "selected-row") = 0,
              "settings save must exclude Buffer List selection state");
      Assert (Index (Text, "runtime-buffer") = 0,
              "settings save must exclude runtime buffer identifiers");
      Assert (Index (Text, "dirty-filter") = 0,
              "settings save must exclude Buffer List state-filter selection");
      Assert (Index (Text, "name-sort") = 0,
              "settings save must exclude Buffer List sort mode");
      Assert (Index (Text, "marked-review") = 0,
              "settings save must exclude Buffer List review/mark state");

      Delete_If_Exists (Path);
   end Test_Settings_Save_Excludes_Buffer_List_Runtime_State;

   procedure Test_Load_Missing_Fields_Uses_Defaults
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path   : constant String := Editor.Test_Temp.Base & "/editor_missing_fields.txt";
      Model  : Editor.Settings.Settings_Model;
      Status : Editor.Settings.Settings_Status;
   begin
      Delete_If_Exists (Path);
      Write_Text
        (Path,
         "editor-settings-version=1" & ASCII.LF &
         "[appearance]" & ASCII.LF &
         "theme=light" & ASCII.LF);

      Editor.Settings.Load_From_File (Path, Model, Status);
      Assert (Status = Editor.Settings.Settings_Ok,
              "settings load with omitted optional fields must succeed using defaults");
      Assert (Editor.Settings.Theme_Id (Model) = "light",
              "loaded explicit setting must be applied");
      Assert (Editor.Settings.Line_Number_Mode_Name (Model) = "absolute",
              "missing line-number setting must remain defaulted");
      Assert (Editor.Settings.Cursor_Style_Name (Model) = "bar",
              "missing cursor style must remain defaulted");
      Assert (Editor.Settings.Cursor_Blink (Model),
              "missing cursor blink must remain defaulted");
      Assert (Editor.Settings.Minimap_Visible (Model),
              "missing minimap visibility must remain defaulted");
      Assert (Editor.Settings.Command_Palette_Show_Keybindings (Model),
              "missing palette keybinding-display setting must remain defaulted");
      Delete_If_Exists (Path);
   end Test_Load_Missing_Fields_Uses_Defaults;

   procedure Test_Save_Failure_Does_Not_Update_State_Settings
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Blocker : constant String := Editor.Test_Temp.Base & "/editor_settings_blocker";
      Path    : constant String := Blocker & "/settings";
      S       : Editor.State.State_Type;
      Found   : Boolean := False;
      M       : Editor.Messages.Editor_Message;
   begin
      Delete_If_Exists (Blocker);
      Write_Text (Blocker, "not a directory" & ASCII.LF);
      Ada.Environment_Variables.Set ("EDITOR_SETTINGS_PATH", Path);

      Editor.State.Init (S);
      Editor.Settings_Management.Reset_Transient_State;
      Assert (Editor.Settings.Minimap_Visible (S.Settings),
              "state fixture must start with default minimap setting");
      Editor.Minimap.Set_Enabled (False);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_Settings);

      Assert (Editor.Settings.Minimap_Visible (S.Settings),
              "failed Save Settings must not replace in-memory state settings snapshot");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Settings file could not be written.",
              "failed Save Settings must emit deterministic failure outcome");
      Editor.Minimap.Set_Enabled (True);
      Delete_If_Exists (Blocker);
   end Test_Save_Failure_Does_Not_Update_State_Settings;

   procedure Test_Reload_Malformed_Does_Not_Mutate_Settings
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path   : constant String := Editor.Test_Temp.Base & "/editor_malformed_reload.txt";
      S      : Editor.State.State_Type;
      Model  : Editor.Settings.Settings_Model;
      Found  : Boolean := False;
      M      : Editor.Messages.Editor_Message;
   begin
      Delete_If_Exists (Path);
      Write_Text (Path, "not settings" & ASCII.LF);
      Ada.Environment_Variables.Set ("EDITOR_SETTINGS_PATH", Path);

      Editor.State.Init (S);
      Editor.Settings_Management.Reset_Transient_State;
      Editor.Settings.Set_Defaults (Model);
      Editor.Settings.Set_Minimap_Visible (Model, False);
      Editor.State.Apply_Settings (S, Model);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Reload_Settings);

      Assert (not Editor.Settings.Minimap_Visible (S.Settings),
              "malformed settings reload must not partially replace state settings");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Settings file is invalid.",
              "malformed settings reload must emit deterministic failure outcome");
      Editor.Minimap.Set_Enabled (True);
      Editor.Settings.Set_Show_Minimap (True);
      Delete_If_Exists (Path);
   end Test_Reload_Malformed_Does_Not_Mutate_Settings;

   procedure Install_Project_For_Settings
     (S    : in out Editor.State.State_Type;
      Root : String;
      Name : String)
   is
      Result : constant Editor.Project.Project_Open_Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String (Root),
         Display_Name => To_Unbounded_String (Name),
         Error_Text   => Null_Unbounded_String);
   begin
      Editor.Project.Apply_Open_Result (S.Project, Result);
   end Install_Project_For_Settings;

   procedure Test_Empty_Settings_File_Is_Hard_Invalid
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path   : constant String := Editor.Test_Temp.Base & "/editor_empty_settings.txt";
      Model  : Editor.Settings.Settings_Model;
      Status : Editor.Settings.Settings_Status;
   begin
      Delete_If_Exists (Path);
      Write_Text (Path, "");

      Editor.Settings.Load_From_File (Path, Model, Status);

      Assert (Status = Editor.Settings.Settings_Invalid_Format,
              "empty settings file must be hard-invalid, not silently defaulted");
      Assert (Editor.Settings.Theme_Id (Model) = "dark",
              "hard-invalid settings load must leave built-in defaults");
      Delete_If_Exists (Path);
   end Test_Empty_Settings_File_Is_Hard_Invalid;

   procedure Test_Normalized_Save_Is_Byte_Stable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path_A : constant String := Editor.Test_Temp.Base & "/editor_settings_a.txt";
      Path_B : constant String := Editor.Test_Temp.Base & "/editor_settings_b.txt";
      Model  : Editor.Settings.Settings_Model;
      Loaded : Editor.Settings.Settings_Model;
      Status : Editor.Settings.Settings_Status;
      First  : Unbounded_String;
      Second : Unbounded_String;
   begin
      Delete_If_Exists (Path_A);
      Delete_If_Exists (Path_B);
      Write_Text
        (Path_A,
         "editor-settings-version=1" & ASCII.LF &
         "[unknown]" & ASCII.LF &
         "ignored=true" & ASCII.LF &
         "[appearance]" & ASCII.LF &
         "theme= light " & ASCII.LF &
         "[editor]" & ASCII.LF &
         "line-numbers=relative" & ASCII.LF &
         "cursor-style=block" & ASCII.LF &
         "cursor-blink=false" & ASCII.LF &
         "cursor-blink=true" & ASCII.LF &
         "[view]" & ASCII.LF &
         "minimap-visible=false" & ASCII.LF &
         "scrollbars-visible=true" & ASCII.LF &
         "[command-palette]" & ASCII.LF &
         "show-unavailable=true" & ASCII.LF &
         "show-keybindings=false" & ASCII.LF &
         "show-selected-description=true" & ASCII.LF);

      Editor.Settings.Load_From_File (Path_A, Loaded, Status);
      Assert (Status = Editor.Settings.Settings_Partial_Load,
              "unknown sections/keys should diagnose as partial load");
      Editor.Settings.Save_To_File (Loaded, Path_B, Status);
      Assert (Status = Editor.Settings.Settings_Ok,
              "normalized partial settings must save successfully");
      First := To_Unbounded_String (Read_All (Path_B));

      Editor.Settings.Load_From_File (Path_B, Model, Status);
      Assert (Status = Editor.Settings.Settings_Ok,
              "normalized settings file must reload cleanly");
      Editor.Settings.Save_To_File (Model, Path_A, Status);
      Assert (Status = Editor.Settings.Settings_Ok,
              "second normalized settings save must succeed");
      Second := To_Unbounded_String (Read_All (Path_A));

      Assert (To_String (First) = To_String (Second),
              "load-normalize-save settings serialization must be byte-stable");
      Assert (Read_All (Path_A)'Length > 0
              and then Read_All (Path_A) = To_String (First),
              "normalized output must be deterministic and non-empty");
      Assert (Editor.Settings.Cursor_Blink (Model),
              "duplicate keys must follow documented last-value-wins policy");
      Delete_If_Exists (Path_A);
      Delete_If_Exists (Path_B);
   end Test_Normalized_Save_Is_Byte_Stable;

   procedure Test_Settings_Commands_Preserve_Lifecycle_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Settings_Path : constant String := Editor.Test_Temp.Base & "/editor_command_settings.txt";
      Before : Editor.Lifecycle_Audit.Lifecycle_State_Summary;
      After  : Editor.Lifecycle_Audit.Lifecycle_State_Summary;
      Result : Editor.Lifecycle_Audit.Lifecycle_Audit_Result;
      Target : constant Editor.Pending_Transitions.Pending_Transition_Target :=
        (Kind       => Editor.Pending_Transitions.Pending_Open_Project,
         Path       => To_Unbounded_String (Editor.Test_Temp.Base & "/editor-b"),
         Display    => To_Unbounded_String ("editor-b"),
         Buffer_Id  => 0,
         Has_Buffer => False,
         Has_Path   => True,
         others     => <>);
      Dirty : constant Editor.Dirty_Guards.Dirty_Buffer_Summary :=
        (Dirty_Count => 1, Untitled_Count => 0, File_Backed_Count => 1);
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Delete_If_Exists (Settings_Path);
      Ada.Environment_Variables.Set ("EDITOR_SETTINGS_PATH", Settings_Path);
      Editor.State.Init (S);
      Install_Project_For_Settings (S, Editor.Test_Temp.Base & "/editor-a", "editor-a");
      Editor.State.Load_Text (S, "dirty text");
      S.File_Info :=
        (Has_Path     => True,
         Path         => To_Unbounded_String (Editor.Test_Temp.Base & "/editor-a/main.adb"),
         Display_Name => To_Unbounded_String ("main.adb"),
         Dirty        => True,
         others       => <>);
      Editor.Pending_Transitions.Set_Pending
        (S.Pending_Transitions, Target, Dirty);
      Editor.Recent_Projects.Add_Or_Promote
        (S.Recent_Projects, Editor.Test_Temp.Base & "/editor-a", "editor-a", 104);

      Before := Editor.Lifecycle_Audit.State_Summary (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_Settings);
      After := Editor.Lifecycle_Audit.State_Summary (S);
      Editor.Lifecycle_Audit.Expect_No_Core_Lifecycle_Mutation
        (Result, Before, After, "save settings");
      Assert (Editor.Lifecycle_Audit.Status (Result) =
                Editor.Lifecycle_Audit.Lifecycle_Audit_Ok,
              Editor.Lifecycle_Audit.Summary (Result));
      Assert (Editor.State.Current_Text (S) = "dirty text",
              "Save Settings must not save or rewrite dirty file contents");
      Assert (S.File_Info.Dirty,
              "Save Settings must not clear dirty buffer state");
      Assert (Editor.Messages.Count (S.Messages) = 1,
              "Save Settings must emit exactly one outcome message");

      Before := Editor.Lifecycle_Audit.State_Summary (S);
      Editor.Lifecycle_Audit.Clear (Result);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Reset_Settings_To_Defaults);
      After := Editor.Lifecycle_Audit.State_Summary (S);
      Editor.Lifecycle_Audit.Expect_No_Core_Lifecycle_Mutation
        (Result, Before, After, "reset settings");
      Assert (Editor.Lifecycle_Audit.Status (Result) =
                Editor.Lifecycle_Audit.Lifecycle_Audit_Ok,
              Editor.Lifecycle_Audit.Summary (Result));
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "Reset Settings must not clear pending transitions");
      Editor.Settings_Management.Reset_Transient_State;
      Delete_If_Exists (Settings_Path);
   end Test_Settings_Commands_Preserve_Lifecycle_State;

   procedure Test_Preference_Toggle_Persists_Only_After_Save
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path   : constant String := Editor.Test_Temp.Base & "/editor_toggle_persistence.txt";
      S      : Editor.State.State_Type;
      Loaded : Editor.Settings.Settings_Model;
      Status : Editor.Settings.Settings_Status;
      Default_Text : Unbounded_String;
      Saved_Text   : Unbounded_String;
   begin
      Delete_If_Exists (Path);
      declare
         Defaults : Editor.Settings.Settings_Model;
      begin
         Editor.Settings.Set_Defaults (Defaults);
         Editor.Settings.Save_To_File (Defaults, Path, Status);
      end;
      Assert (Status = Editor.Settings.Settings_Ok,
              "test fixture default settings save must succeed");
      Default_Text := To_Unbounded_String (Read_All (Path));

      Ada.Environment_Variables.Set ("EDITOR_SETTINGS_PATH", Path);
      Editor.State.Init (S);
      Editor.Settings_Management.Reset_Transient_State;
      Editor.Settings.Load_From_File (Path, Loaded, Status);
      Assert (Status = Editor.Settings.Settings_Ok,
              "default settings fixture must load");
      Editor.State.Apply_Settings (S, Loaded);
      Assert (Editor.Settings.Minimap_Visible (S.Settings),
              "default fixture starts with minimap visible");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Minimap);
      Assert (not Editor.Minimap.Enabled,
              "Toggle Minimap must change live minimap state");
      Assert (Read_All (Path) = To_String (Default_Text),
              "preference toggles must not auto-save settings files");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_Settings);
      Saved_Text := To_Unbounded_String (Read_All (Path));
      Assert (To_String (Saved_Text) /= To_String (Default_Text),
              "Save Settings after a toggle must persist changed live preference state");
      Editor.Settings.Load_From_File (Path, Loaded, Status);
      Assert (Status = Editor.Settings.Settings_Ok,
              "saved toggled settings must reload cleanly");
      Assert (not Editor.Settings.Minimap_Visible (Loaded),
              "saved settings must persist minimap visibility toggle");
      Delete_If_Exists (Path);
   end Test_Preference_Toggle_Persists_Only_After_Save;


   procedure Test_Settings_User_Readable_Labels
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Settings.Settings_Status_Label
           (Editor.Settings.Settings_Partial_Load) =
             "Settings loaded with ignored invalid entries.",
         "partial settings loads must have user-readable labels");
      Assert
        (Editor.Settings.Settings_Status_Label
           (Editor.Settings.Settings_Invalid_Format) =
             "Settings file has an invalid format.",
         "invalid settings format must be user-readable");
      Assert
        (Editor.Settings.Settings_Display_Label
           (Editor.Settings.Setting_Name_Command_Palette_Show_Keybindings) =
             "Show keybindings",
         "command-palette keybinding setting must have a display label");
      Assert
        (Editor.Settings.Settings_Display_Label
           (Editor.Settings.Setting_Name_Command_Palette_Show_Unavailable) =
             "Show unavailable commands",
         "unavailable-command display setting must have a display label");
      Assert
        (Editor.Settings.Settings_Display_Label ("build-candidates") =
           "Unknown setting",
         "transient build state must not become a recognized setting label");
      Assert
        (Editor.Settings.Settings_Validation_Message
           (Editor.Settings.Setting_Name_Command_Palette_Show_Keybindings, "maybe") =
             "Setting value must be true or false.",
         "invalid boolean settings must have a user-readable validation message");
      Assert
        (Editor.Settings.Settings_Validation_Message
           (Editor.Settings.Setting_Name_Line_Numbers, "sideways") =
             "Line number mode is not supported.",
         "invalid line-number settings must have a user-readable validation message");
      Assert
        (Editor.Settings.Settings_Validation_Message ("build-candidates", "1") =
           "Unknown setting.",
         "transient build fields must not validate as settings");
   end Test_Settings_User_Readable_Labels;

   overriding function Name
     (T : Settings_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Settings.Tests");
   end Name;

   overriding procedure Register_Tests
     (T : in out Settings_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Default_Settings_Enable_Features'Access,
         "Default Settings Enable Features");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Disabling_Line_Numbers_Removes_Gutter_Glyphs'Access,
         "Disabling Line Numbers Removes Gutter Glyphs");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Disabling_Current_Line_Highlight_Removes_Text_Rect'Access,
         "Disabling Current Line Highlight Removes Rect");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Disabling_Minimap_Removes_Rects'Access,
         "Disabling Minimap Removes Rects");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Disabling_Minimap_Expands_Text_Snapshot'Access,
         "Disabling Minimap Expands Text Snapshot");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Disabling_Minimap_Disables_Input_Routing'Access,
         "Disabling Minimap Disables Input Routing");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Disabling_Syntax_Uses_Default_Text_Color'Access,
         "Disabling Syntax Uses Default Text Color");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Disabling_Diagnostics_Removes_Diagnostic_Rects'Access,
         "Disabling Diagnostics Removes Diagnostic Rects");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Palette_Toggle_Changes_Setting'Access,
         "Command Palette Toggle Changes Setting");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Settings_Model_Round_Trip_Deterministic'Access,
         "Settings Model Round Trip Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Settings_Load_Statuses'Access,
         "Settings Load Statuses");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Settings_Partial_Load_Defaults_Invalid_Optional_Value'Access,
         "Settings Partial Load Defaults Invalid Optional Value");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Apply_Settings_Changes_Line_Number_And_Cursor_Only'Access,
         "Apply Settings Changes Line Number And Cursor Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Settings_Command_Descriptors'Access,
         "Settings Command Descriptors");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Setting_Identifiers_Are_Stable_Format_Keys'Access,
         "Setting Identifiers Are Stable Format Keys");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Apply_Settings_Returns_Subsystem_Summary'Access,
         "Apply Settings Returns Subsystem Summary");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Palette_Display_Settings_Are_Applied'Access,
         "Command Palette Display Settings Are Applied");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Build_From_Current_Captures_View_And_Palette_Preferences'Access,
         "Build From Current Captures View And Palette Preferences");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Settings_Toggle_Commands_Are_Settings_Category'Access,
         "Settings Toggle Commands Are Settings Category");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Cursor_Blink_Setting_Controls_Cursor'Access,
         "Cursor Blink Setting Controls Cursor");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Settings_Toggle_Commands_Emit_Canonical_Messages'Access,
         "Settings Toggle Commands Emit Canonical Messages");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Settings_Persists_Selected_Description_Preference'Access,
         "Save Settings Persists Selected Description Preference");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Empty_Settings_File_Is_Hard_Invalid'Access,
         "Empty Settings File Is Hard Invalid");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Normalized_Save_Is_Byte_Stable'Access,
         "Normalized Save Is Byte Stable");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Settings_Commands_Preserve_Lifecycle_State'Access,
         "Settings Commands Preserve Lifecycle State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Preference_Toggle_Persists_Only_After_Save'Access,
         "Preference Toggle Persists Only After Save");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Output_Is_Settings_Only'Access,
         "Save Output Is Settings Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Settings_Save_Excludes_Buffer_List_Runtime_State'Access,
         "Settings Save Excludes Buffer List Runtime State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Load_Missing_Fields_Uses_Defaults'Access,
         "Load Missing Fields Uses Defaults");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Failure_Does_Not_Update_State_Settings'Access,
         "Save Failure Does Not Update State Settings");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Malformed_Does_Not_Mutate_Settings'Access,
         "Reload Malformed Does Not Mutate Settings");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Settings_User_Readable_Labels'Access,
         "Settings User Readable Labels");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Set_Theme_Commands_Are_Settings_Commands'Access,
         "Set Theme Commands Are Settings Commands");
   end Register_Tests;

end Editor.Settings.Tests;
