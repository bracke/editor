with Ada.Characters.Handling;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Strings.Fixed;
with Ada.Text_IO;
with Editor.Cursor;
with Editor.Line_Numbers;
with Editor.Minimap;
with Editor.Scrollbars;
with Editor.Command_Palette;
with Editor.Theme;

package body Editor.Settings is

   use Ada.Strings.Unbounded;

   Default_Settings : constant Settings_State := (others => <>);
   State : Settings_State := Default_Settings;
   Current_Version : Natural := 0;
   Last_Ignored_Load_Entries : Natural := 0;
   Last_Defaulted_Load_Values : Natural := 0;

   procedure Bump_Version is
   begin
      if Current_Version = Natural'Last then
         Current_Version := 0;
      else
         Current_Version := Current_Version + 1;
      end if;
   end Bump_Version;

   function Trimmed (S : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (S, Ada.Strings.Both);
   end Trimmed;

   function Lower (S : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (S);
   end Lower;

   function Valid_Boolean (S : String; Value : out Boolean) return Boolean is
      V : constant String := Lower (Trimmed (S));
   begin
      if V = "true" then
         Value := True;
         return True;
      elsif V = "false" then
         Value := False;
         return True;
      end if;
      Value := False;
      return False;
   end Valid_Boolean;

   function Valid_Line_Number_Mode (Name : String) return Boolean is
      Found : Boolean := False;
      Mode  : Editor.Line_Numbers.Line_Number_Mode;
      pragma Unreferenced (Mode);
   begin
      Mode := Editor.Line_Numbers.Line_Number_Mode_From_Name (Name, Found);
      return Found;
   end Valid_Line_Number_Mode;

   function Valid_Cursor_Style (Name : String) return Boolean is
      V : constant String := Lower (Trimmed (Name));
   begin
      return V = "bar" or else V = "block" or else V = "underline";
   end Valid_Cursor_Style;

   procedure Apply_Side_Effects is
   begin
      Editor.Cursor.Set_Blink_Enabled (State.Cursor_Blink_Enabled);
   end Apply_Side_Effects;

   function Current return Settings_State is
   begin
      return State;
   end Current;

   procedure Set_Current (Settings : Settings_State) is
   begin
      if State /= Settings then
         State := Settings;
         Apply_Side_Effects;
         Bump_Version;
      end if;
   end Set_Current;

   procedure Reset is
   begin
      State := Default_Settings;
      Apply_Side_Effects;
      Bump_Version;
   end Reset;

   function Version return Natural is
   begin
      return Current_Version;
   end Version;

   function Show_Minimap return Boolean is (State.Show_Minimap);
   procedure Set_Show_Minimap (Enabled : Boolean) is
   begin
      if State.Show_Minimap /= Enabled then
         State.Show_Minimap := Enabled;
         Bump_Version;
      end if;
   end Set_Show_Minimap;

   function Show_Line_Numbers return Boolean is (State.Show_Line_Numbers);
   procedure Set_Show_Line_Numbers (Enabled : Boolean) is
   begin
      if State.Show_Line_Numbers /= Enabled then
         State.Show_Line_Numbers := Enabled;
         Bump_Version;
      end if;
   end Set_Show_Line_Numbers;

   function Highlight_Current_Line return Boolean is (State.Highlight_Current_Line);
   procedure Set_Highlight_Current_Line (Enabled : Boolean) is
   begin
      if State.Highlight_Current_Line /= Enabled then
         State.Highlight_Current_Line := Enabled;
         Bump_Version;
      end if;
   end Set_Highlight_Current_Line;

   function Highlight_Current_Gutter return Boolean is (State.Highlight_Current_Gutter);
   procedure Set_Highlight_Current_Gutter (Enabled : Boolean) is
   begin
      if State.Highlight_Current_Gutter /= Enabled then
         State.Highlight_Current_Gutter := Enabled;
         Bump_Version;
      end if;
   end Set_Highlight_Current_Gutter;

   function Cursor_Blink_Enabled return Boolean is (State.Cursor_Blink_Enabled);
   procedure Set_Cursor_Blink_Enabled (Enabled : Boolean) is
   begin
      if State.Cursor_Blink_Enabled /= Enabled then
         State.Cursor_Blink_Enabled := Enabled;
         Editor.Cursor.Set_Blink_Enabled (Enabled);
         Bump_Version;
      end if;
   end Set_Cursor_Blink_Enabled;

   function Use_Syntax_Colouring return Boolean is (State.Use_Syntax_Colouring);
   procedure Set_Use_Syntax_Colouring (Enabled : Boolean) is
   begin
      if State.Use_Syntax_Colouring /= Enabled then
         State.Use_Syntax_Colouring := Enabled;
         Bump_Version;
      end if;
   end Set_Use_Syntax_Colouring;

   function Use_Semantic_Colouring return Boolean is (State.Use_Semantic_Colouring);
   procedure Set_Use_Semantic_Colouring (Enabled : Boolean) is
   begin
      if State.Use_Semantic_Colouring /= Enabled then
         State.Use_Semantic_Colouring := Enabled;
         Bump_Version;
      end if;
   end Set_Use_Semantic_Colouring;

   function Use_Diagnostic_Overlays return Boolean is (State.Use_Diagnostic_Overlays);
   procedure Set_Use_Diagnostic_Overlays (Enabled : Boolean) is
   begin
      if State.Use_Diagnostic_Overlays /= Enabled then
         State.Use_Diagnostic_Overlays := Enabled;
         Bump_Version;
      end if;
   end Set_Use_Diagnostic_Overlays;

   function Use_Search_Overlays return Boolean is (State.Use_Search_Overlays);
   procedure Set_Use_Search_Overlays (Enabled : Boolean) is
   begin
      if State.Use_Search_Overlays /= Enabled then
         State.Use_Search_Overlays := Enabled;
         Bump_Version;
      end if;
   end Set_Use_Search_Overlays;

   function Show_Diagnostics return Boolean is (State.Show_Diagnostics);
   procedure Set_Show_Diagnostics (Enabled : Boolean) is
   begin
      if State.Show_Diagnostics /= Enabled then
         State.Show_Diagnostics := Enabled;
         Bump_Version;
      end if;
   end Set_Show_Diagnostics;

   function Format_On_Save return Boolean is (State.Format_On_Save);
   procedure Set_Format_On_Save (Enabled : Boolean) is
   begin
      if State.Format_On_Save /= Enabled then
         State.Format_On_Save := Enabled;
         Bump_Version;
      end if;
   end Set_Format_On_Save;

   procedure Toggle_Show_Minimap is begin Set_Show_Minimap (not State.Show_Minimap); end Toggle_Show_Minimap;
   procedure Toggle_Show_Line_Numbers is begin Set_Show_Line_Numbers (not State.Show_Line_Numbers); end Toggle_Show_Line_Numbers;
   procedure Toggle_Highlight_Current_Line is begin Set_Highlight_Current_Line (not State.Highlight_Current_Line); end Toggle_Highlight_Current_Line;
   procedure Toggle_Highlight_Current_Gutter is begin Set_Highlight_Current_Gutter (not State.Highlight_Current_Gutter); end Toggle_Highlight_Current_Gutter;
   procedure Toggle_Cursor_Blink_Enabled is begin Set_Cursor_Blink_Enabled (not State.Cursor_Blink_Enabled); end Toggle_Cursor_Blink_Enabled;
   procedure Toggle_Use_Syntax_Colouring is begin Set_Use_Syntax_Colouring (not State.Use_Syntax_Colouring); end Toggle_Use_Syntax_Colouring;
   procedure Toggle_Use_Semantic_Colouring is begin Set_Use_Semantic_Colouring (not State.Use_Semantic_Colouring); end Toggle_Use_Semantic_Colouring;
   procedure Toggle_Use_Diagnostic_Overlays is begin Set_Use_Diagnostic_Overlays (not State.Use_Diagnostic_Overlays); end Toggle_Use_Diagnostic_Overlays;
   procedure Toggle_Use_Search_Overlays is begin Set_Use_Search_Overlays (not State.Use_Search_Overlays); end Toggle_Use_Search_Overlays;
   procedure Toggle_Show_Diagnostics is begin Set_Show_Diagnostics (not State.Show_Diagnostics); end Toggle_Show_Diagnostics;
   procedure Toggle_Format_On_Save is begin Set_Format_On_Save (not State.Format_On_Save); end Toggle_Format_On_Save;

   function Setting_Name_Theme return String is ("theme");
   function Setting_Name_Line_Numbers return String is ("line-numbers");
   function Setting_Name_Cursor_Style return String is ("cursor-style");
   function Setting_Name_Cursor_Blink return String is ("cursor-blink");
   function Setting_Name_Minimap_Visible return String is ("minimap-visible");
   function Setting_Name_Scrollbars_Visible return String is ("scrollbars-visible");
   function Setting_Name_Command_Palette_Show_Unavailable return String is ("show-unavailable");
   function Setting_Name_Command_Palette_Show_Keybindings return String is ("show-keybindings");
   function Setting_Name_Command_Palette_Show_Selected_Description return String is ("show-selected-description");
   function Setting_Name_Format_On_Save return String is ("format-on-save");

   function Settings_Status_Label (Status : Settings_Status) return String is
   begin
      case Status is
         when Settings_Ok =>
            return "Settings loaded.";
         when Settings_Not_Found =>
            return "Settings file not found.";
         when Settings_Invalid_Format =>
            return "Settings file has an invalid format.";
         when Settings_Unsupported_Version =>
            return "Settings file version is not supported.";
         when Settings_Read_Error =>
            return "Settings file could not be read.";
         when Settings_Write_Error =>
            return "Settings file could not be written.";
         when Settings_Partial_Load =>
            return "Settings loaded with ignored invalid entries.";
      end case;
   end Settings_Status_Label;

   function Settings_Display_Label (Setting_Name : String) return String is
      Key : constant String := Lower (Setting_Name);
   begin
      if Key = Setting_Name_Theme then
         return "Theme";
      elsif Key = Setting_Name_Line_Numbers then
         return "Line numbers";
      elsif Key = Setting_Name_Cursor_Style then
         return "Cursor style";
      elsif Key = Setting_Name_Cursor_Blink then
         return "Cursor blink";
      elsif Key = Setting_Name_Minimap_Visible then
         return "Minimap";
      elsif Key = Setting_Name_Scrollbars_Visible then
         return "Scrollbars";
      elsif Key = Setting_Name_Command_Palette_Show_Unavailable then
         return "Show unavailable commands";
      elsif Key = Setting_Name_Command_Palette_Show_Keybindings then
         return "Show keybindings";
      elsif Key = Setting_Name_Command_Palette_Show_Selected_Description then
         return "Show selected command details";
      elsif Key = Setting_Name_Format_On_Save then
         return "Format on save";
      else
         return "Unknown setting";
      end if;
   end Settings_Display_Label;

   function Last_Load_Ignored_Count return Natural is
   begin
      return Last_Ignored_Load_Entries;
   end Last_Load_Ignored_Count;

   function Last_Load_Defaulted_Count return Natural is
   begin
      return Last_Defaulted_Load_Values;
   end Last_Load_Defaulted_Count;

   function Settings_Validation_Message
     (Setting_Name : String;
      Value        : String) return String
   is
      Key : constant String := Lower (Setting_Name);
      Bool_Value : Boolean := False;
   begin
      if Settings_Display_Label (Key) = "Unknown setting" then
         return "Unknown setting.";
      elsif Key = Setting_Name_Theme then
         if Trimmed (Value)'Length = 0
           or else Editor.Theme.Is_Valid_Theme_Id (Lower (Trimmed (Value)))
         then
            return "Setting is valid.";
         else
            return "Theme is not available.";
         end if;
      elsif Key = Setting_Name_Line_Numbers then
         if Valid_Line_Number_Mode (Lower (Trimmed (Value))) then
            return "Setting is valid.";
         else
            return "Line number mode is not supported.";
         end if;
      elsif Key = Setting_Name_Cursor_Style then
         if Valid_Cursor_Style (Lower (Trimmed (Value))) then
            return "Setting is valid.";
         else
            return "Cursor style is not supported.";
         end if;
      elsif Key = Setting_Name_Cursor_Blink
        or else Key = Setting_Name_Minimap_Visible
        or else Key = Setting_Name_Scrollbars_Visible
        or else Key = Setting_Name_Command_Palette_Show_Unavailable
        or else Key = Setting_Name_Command_Palette_Show_Keybindings
        or else Key = Setting_Name_Command_Palette_Show_Selected_Description
        or else Key = Setting_Name_Format_On_Save
      then
         if Valid_Boolean (Value, Bool_Value) then
            return "Setting is valid.";
         else
            return "Setting value must be true or false.";
         end if;
      else
         return "Unknown setting.";
      end if;
   end Settings_Validation_Message;

   procedure Clear (Settings : in out Settings_Model) is
   begin
      Set_Defaults (Settings);
   end Clear;

   procedure Set_Defaults (Settings : in out Settings_Model) is
   begin
      Settings := (others => <>);
   end Set_Defaults;

   function Version (Settings : Settings_Model) return Natural is
   begin
      return Settings.Format_Version;
   end Version;

   function Theme_Mode (Settings : Settings_Model) return Theme_Setting_Kind is
   begin
      return Settings.Theme_Mode_Value;
   end Theme_Mode;

   function Theme_Id (Settings : Settings_Model) return String is
   begin
      return To_String (Settings.Theme_Id_Value);
   end Theme_Id;

   procedure Set_Theme_Id (Settings : in out Settings_Model; Id : String) is
   begin
      if Trimmed (Id)'Length = 0 then
         Settings.Theme_Mode_Value := Use_Default_Theme;
         Settings.Theme_Id_Value := To_Unbounded_String ("dark");
      else
         Settings.Theme_Mode_Value := Use_Named_Theme;
         Settings.Theme_Id_Value := To_Unbounded_String (Lower (Trimmed (Id)));
      end if;
   end Set_Theme_Id;

   function Has_Line_Number_Mode (Settings : Settings_Model) return Boolean is
   begin
      return Settings.Has_Line_Number_Mode_Value;
   end Has_Line_Number_Mode;

   function Line_Number_Mode_Name (Settings : Settings_Model) return String is
   begin
      return To_String (Settings.Line_Number_Mode_Value);
   end Line_Number_Mode_Name;

   procedure Set_Line_Number_Mode_Name
     (Settings : in out Settings_Model;
      Name     : String) is
   begin
      Settings.Has_Line_Number_Mode_Value := Trimmed (Name)'Length > 0;
      Settings.Line_Number_Mode_Value := To_Unbounded_String (Lower (Trimmed (Name)));
   end Set_Line_Number_Mode_Name;

   function Cursor_Style_Name (Settings : Settings_Model) return String is
   begin
      return To_String (Settings.Cursor_Style_Value);
   end Cursor_Style_Name;

   procedure Set_Cursor_Style_Name
     (Settings : in out Settings_Model;
      Name     : String) is
   begin
      Settings.Cursor_Style_Value := To_Unbounded_String (Lower (Trimmed (Name)));
   end Set_Cursor_Style_Name;

   function Cursor_Blink (Settings : Settings_Model) return Boolean is
   begin
      return Settings.Cursor_Blink_Value;
   end Cursor_Blink;

   procedure Set_Cursor_Blink
     (Settings : in out Settings_Model;
      Enabled  : Boolean) is
   begin
      Settings.Cursor_Blink_Value := Enabled;
   end Set_Cursor_Blink;

   function Minimap_Visible (Settings : Settings_Model) return Boolean is
   begin
      return Settings.Minimap_Visible_Value;
   end Minimap_Visible;

   procedure Set_Minimap_Visible
     (Settings : in out Settings_Model;
      Visible  : Boolean) is
   begin
      Settings.Minimap_Visible_Value := Visible;
   end Set_Minimap_Visible;

   function Scrollbars_Visible (Settings : Settings_Model) return Boolean is
   begin
      return Settings.Scrollbars_Visible_Value;
   end Scrollbars_Visible;

   procedure Set_Scrollbars_Visible
     (Settings : in out Settings_Model;
      Visible  : Boolean) is
   begin
      Settings.Scrollbars_Visible_Value := Visible;
   end Set_Scrollbars_Visible;

   function Command_Palette_Show_Unavailable
     (Settings : Settings_Model) return Boolean is
   begin
      return Settings.Command_Palette_Show_Unavailable;
   end Command_Palette_Show_Unavailable;

   procedure Set_Command_Palette_Show_Unavailable
     (Settings : in out Settings_Model;
      Visible  : Boolean) is
   begin
      Settings.Command_Palette_Show_Unavailable := Visible;
   end Set_Command_Palette_Show_Unavailable;

   function Command_Palette_Show_Keybindings
     (Settings : Settings_Model) return Boolean is
   begin
      return Settings.Command_Palette_Show_Keybindings;
   end Command_Palette_Show_Keybindings;

   procedure Set_Command_Palette_Show_Keybindings
     (Settings : in out Settings_Model;
      Visible  : Boolean) is
   begin
      Settings.Command_Palette_Show_Keybindings := Visible;
   end Set_Command_Palette_Show_Keybindings;

   function Command_Palette_Show_Selected_Description
     (Settings : Settings_Model) return Boolean is
   begin
      return Settings.Command_Palette_Show_Selected_Description;
   end Command_Palette_Show_Selected_Description;

   procedure Set_Command_Palette_Show_Selected_Description
     (Settings : in out Settings_Model;
      Visible  : Boolean) is
   begin
      Settings.Command_Palette_Show_Selected_Description := Visible;
   end Set_Command_Palette_Show_Selected_Description;

   function Format_On_Save (Settings : Settings_Model) return Boolean is
   begin
      return Settings.Format_On_Save_Value;
   end Format_On_Save;

   procedure Set_Format_On_Save
     (Settings : in out Settings_Model;
      Enabled  : Boolean) is
   begin
      Settings.Format_On_Save_Value := Enabled;
   end Set_Format_On_Save;

   procedure Normalize (Settings : in out Settings_Model) is
   begin
      Settings.Format_Version := 1;
      if Settings.Theme_Mode_Value = Use_Named_Theme
        and then not Editor.Theme.Is_Valid_Theme_Id (Theme_Id (Settings))
      then
         Set_Theme_Id (Settings, "dark");
      end if;
      if not Settings.Has_Line_Number_Mode_Value
        or else not Valid_Line_Number_Mode (Line_Number_Mode_Name (Settings))
      then
         Settings.Has_Line_Number_Mode_Value := True;
         Settings.Line_Number_Mode_Value := To_Unbounded_String ("absolute");
      end if;
      if not Valid_Cursor_Style (Cursor_Style_Name (Settings)) then
         Settings.Cursor_Style_Value := To_Unbounded_String ("bar");
      end if;
   end Normalize;

   function Equivalent (Left, Right : Settings_Model) return Boolean is
      L : Settings_Model := Left;
      R : Settings_Model := Right;
   begin
      Normalize (L);
      Normalize (R);
      return L.Format_Version = R.Format_Version
        and then L.Theme_Mode_Value = R.Theme_Mode_Value
        and then To_String (L.Theme_Id_Value) = To_String (R.Theme_Id_Value)
        and then L.Has_Line_Number_Mode_Value = R.Has_Line_Number_Mode_Value
        and then To_String (L.Line_Number_Mode_Value) = To_String (R.Line_Number_Mode_Value)
        and then To_String (L.Cursor_Style_Value) = To_String (R.Cursor_Style_Value)
        and then L.Cursor_Blink_Value = R.Cursor_Blink_Value
        and then L.Minimap_Visible_Value = R.Minimap_Visible_Value
        and then L.Scrollbars_Visible_Value = R.Scrollbars_Visible_Value
        and then L.Format_On_Save_Value = R.Format_On_Save_Value
        and then L.Command_Palette_Show_Unavailable = R.Command_Palette_Show_Unavailable
        and then L.Command_Palette_Show_Keybindings = R.Command_Palette_Show_Keybindings
        and then L.Command_Palette_Show_Selected_Description =
                 R.Command_Palette_Show_Selected_Description;
   end Equivalent;

   function Build_From_Current return Settings_Model is
      Result : Settings_Model;
      Cursor : constant Editor.Cursor.Cursor_Config := Editor.Cursor.Current;
      Palette : constant Editor.Command_Palette.Command_Palette_Config :=
        Editor.Command_Palette.Current_Config;
   begin
      Set_Defaults (Result);
      Set_Theme_Id (Result, Editor.Theme.Active_Theme_Id);
      Set_Line_Number_Mode_Name
        (Result,
         Editor.Line_Numbers.Line_Number_Mode_Name
           (Editor.Line_Numbers.Current.Mode));
      case Cursor.Style is
         when Editor.Cursor.Bar_Cursor => Set_Cursor_Style_Name (Result, "bar");
         when Editor.Cursor.Block_Cursor => Set_Cursor_Style_Name (Result, "block");
         when Editor.Cursor.Underline_Cursor => Set_Cursor_Style_Name (Result, "underline");
      end case;
      Set_Cursor_Blink (Result, Editor.Cursor.Current_Blink.Blink_Enabled);
      Set_Minimap_Visible (Result, Editor.Minimap.Enabled);
      Set_Scrollbars_Visible (Result, Editor.Scrollbars.Enabled);
      Set_Format_On_Save (Result, Editor.Settings.Format_On_Save);
      Set_Command_Palette_Show_Unavailable
        (Result, Palette.Show_Unavailable_Commands);
      Set_Command_Palette_Show_Keybindings
        (Result, Palette.Show_Keybindings);
      Set_Command_Palette_Show_Selected_Description
        (Result, Palette.Show_Selected_Description);
      return Result;
   end Build_From_Current;

   procedure Apply
     (Settings : Settings_Model;
      Summary  : out Settings_Apply_Summary)
   is
      Normalized : Settings_Model := Settings;
      Found      : Boolean := False;
      Line_Mode  : Editor.Line_Numbers.Line_Number_Mode;
      Cursor     : Editor.Cursor.Cursor_Config := Editor.Cursor.Current;
      Minimap    : Editor.Minimap.Minimap_Config := Editor.Minimap.Current;
      Scrollbars : Editor.Scrollbars.Scrollbar_Config := Editor.Scrollbars.Current;
      Palette    : Editor.Command_Palette.Command_Palette_Config :=
        Editor.Command_Palette.Current_Config;
   begin
      Summary := (others => <>);
      Normalize (Normalized);

      if Theme_Mode (Normalized) = Use_Named_Theme then
         Editor.Theme.Set_Theme_By_Id (Theme_Id (Normalized), Found);
         if Found then
            Summary.Theme_Applied := True;
         else
            Editor.Theme.Set_Theme_By_Id ("dark", Found);
            Summary.Theme_Fallback := True;
            Summary.Status := Settings_Apply_Partial;
         end if;
      end if;

      Line_Mode := Editor.Line_Numbers.Line_Number_Mode_From_Name
        (Line_Number_Mode_Name (Normalized), Found);
      if Found then
         Editor.Line_Numbers.Set_Current ((Mode => Line_Mode));
         Summary.Line_Numbers_Applied := True;
      else
         Editor.Line_Numbers.Set_Current
           ((Mode => Editor.Line_Numbers.Absolute_Line_Numbers));
         Summary.Line_Numbers_Fallback := True;
         Summary.Status := Settings_Apply_Partial;
      end if;

      declare
         Style_Name : constant String := Lower (Cursor_Style_Name (Normalized));
      begin
         if Style_Name = "bar" then
            Cursor.Style := Editor.Cursor.Bar_Cursor;
         elsif Style_Name = "block" then
            Cursor.Style := Editor.Cursor.Block_Cursor;
         elsif Style_Name = "underline" then
            Cursor.Style := Editor.Cursor.Underline_Cursor;
         else
            Cursor.Style := Editor.Cursor.Bar_Cursor;
            Summary.Cursor_Fallback := True;
            Summary.Status := Settings_Apply_Partial;
         end if;
      end;
      Editor.Cursor.Set_Current (Cursor);
      Editor.Cursor.Set_Blink_Enabled (Cursor_Blink (Normalized));
      State.Cursor_Blink_Enabled := Cursor_Blink (Normalized);
      State.Format_On_Save := Format_On_Save (Normalized);
      Summary.Cursor_Applied := True;

      Minimap.Enabled := Minimap_Visible (Normalized);
      Editor.Minimap.Set_Current (Minimap);
      State.Show_Minimap := Minimap.Enabled;
      Summary.Minimap_Applied := True;

      Scrollbars.Enabled := Scrollbars_Visible (Normalized);
      Editor.Scrollbars.Set_Current (Scrollbars);
      Summary.Scrollbars_Applied := True;

      Palette.Show_Unavailable_Commands :=
        Command_Palette_Show_Unavailable (Normalized);
      Palette.Show_Keybindings :=
        Command_Palette_Show_Keybindings (Normalized);
      Palette.Show_Selected_Description :=
        Command_Palette_Show_Selected_Description (Normalized);
      --  selected-command help/details is transient palette state,
      --  not a setting. Loading or applying settings must not carry a stale
      --  help row forward through the display-preference config record.
      Palette.Show_Help_Row := False;
      Editor.Command_Palette.Set_Current_Config (Palette);
      Summary.Command_Palette_Applied := True;

      Bump_Version;
   exception
      when others =>
         Summary.Status := Settings_Apply_Failed;
   end Apply;

   procedure Apply (Settings : Settings_Model) is
      Summary : Settings_Apply_Summary;
   begin
      Apply (Settings, Summary);
   end Apply;

   function Settings_File_Path return String is
   begin
      if Ada.Environment_Variables.Exists ("EDITOR_SETTINGS_PATH") then
         return Ada.Environment_Variables.Value ("EDITOR_SETTINGS_PATH");
      elsif Ada.Environment_Variables.Exists ("XDG_CONFIG_HOME") then
         return Ada.Environment_Variables.Value ("XDG_CONFIG_HOME") & "/editor/settings";
      elsif Ada.Environment_Variables.Exists ("HOME") then
         return Ada.Environment_Variables.Value ("HOME") & "/.config/editor/settings";
      else
         return "editor-settings";
      end if;
   end Settings_File_Path;

   function Parent_Directory (Path : String) return String is
      Last_Slash : Natural := 0;
   begin
      for I in Path'Range loop
         if Path (I) = '/' or else Path (I) = '\' then
            Last_Slash := I;
         end if;
      end loop;
      if Last_Slash = 0 then
         return "";
      elsif Last_Slash = Path'First then
         return Path (Path'First .. Last_Slash);
      else
         return Path (Path'First .. Last_Slash - 1);
      end if;
   end Parent_Directory;

   procedure Ensure_Directory (Dir : String) is
      Parent : constant String := Parent_Directory (Dir);
   begin
      if Dir'Length = 0 or else Ada.Directories.Exists (Dir) then
         return;
      end if;
      if Parent'Length > 0 and then Parent /= Dir then
         Ensure_Directory (Parent);
      end if;
      Ada.Directories.Create_Directory (Dir);
   exception
      when others => null;
   end Ensure_Directory;

   function Bool_Image (Value : Boolean) return String is
   begin
      return (if Value then "true" else "false");
   end Bool_Image;

   procedure Write_Settings (File : in out Ada.Text_IO.File_Type; Settings : Settings_Model) is
      S : Settings_Model := Settings;
   begin
      Normalize (S);
      Ada.Text_IO.Put_Line (File, "editor-settings-version=1");
      Ada.Text_IO.Put_Line (File, "[appearance]");
      Ada.Text_IO.Put_Line (File, "theme=" & Theme_Id (S));
      Ada.Text_IO.Put_Line (File, "[editor]");
      Ada.Text_IO.Put_Line (File, "line-numbers=" & Line_Number_Mode_Name (S));
      Ada.Text_IO.Put_Line (File, "cursor-style=" & Cursor_Style_Name (S));
      Ada.Text_IO.Put_Line (File, "cursor-blink=" & Bool_Image (Cursor_Blink (S)));
      Ada.Text_IO.Put_Line (File, "format-on-save=" & Bool_Image (Format_On_Save (S)));
      Ada.Text_IO.Put_Line (File, "[view]");
      Ada.Text_IO.Put_Line (File, "minimap-visible=" & Bool_Image (Minimap_Visible (S)));
      Ada.Text_IO.Put_Line (File, "scrollbars-visible=" & Bool_Image (Scrollbars_Visible (S)));
      Ada.Text_IO.Put_Line (File, "[command-palette]");
      Ada.Text_IO.Put_Line (File, "show-unavailable=" & Bool_Image (Command_Palette_Show_Unavailable (S)));
      Ada.Text_IO.Put_Line (File, "show-keybindings=" & Bool_Image (Command_Palette_Show_Keybindings (S)));
      Ada.Text_IO.Put_Line (File, "show-selected-description=" & Bool_Image (Command_Palette_Show_Selected_Description (S)));
   end Write_Settings;

   procedure Save_To_File
     (Settings : Settings_Model;
      Path     : String;
      Status   : out Settings_Status) is
      File : Ada.Text_IO.File_Type;
      Temp : constant String := Path & ".tmp";
      Backup : constant String := Path & ".bak";
      Dir  : constant String := Parent_Directory (Path);
      Had_Previous : Boolean := False;
   begin
      Status := Settings_Write_Error;
      if Dir'Length > 0 then
         Ensure_Directory (Dir);
      end if;

      if Ada.Directories.Exists (Temp) then
         Ada.Directories.Delete_File (Temp);
      end if;
      if Ada.Directories.Exists (Backup) then
         Ada.Directories.Delete_File (Backup);
      end if;

      Ada.Text_IO.Create (File, Ada.Text_IO.Out_File, Temp);
      Write_Settings (File, Settings);
      Ada.Text_IO.Close (File);

      Had_Previous := Ada.Directories.Exists (Path);
      if Had_Previous then
         Ada.Directories.Rename (Path, Backup);
      end if;

      begin
         Ada.Directories.Rename (Temp, Path);
      exception
         when others =>
            if Had_Previous and then Ada.Directories.Exists (Backup)
              and then not Ada.Directories.Exists (Path)
            then
               Ada.Directories.Rename (Backup, Path);
            end if;
            raise;
      end;

      if Ada.Directories.Exists (Backup) then
         Ada.Directories.Delete_File (Backup);
      end if;
      Status := Settings_Ok;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         begin
            if Ada.Directories.Exists (Temp) then
               Ada.Directories.Delete_File (Temp);
            end if;
            if Ada.Directories.Exists (Backup) then
               if not Ada.Directories.Exists (Path) then
                  Ada.Directories.Rename (Backup, Path);
               else
                  Ada.Directories.Delete_File (Backup);
               end if;
            end if;
         exception
            when others => null;
         end;
         Status := Settings_Write_Error;
   end Save_To_File;

   procedure Mark_Partial (Status : in out Settings_Status) is
   begin
      if Status = Settings_Ok then
         Status := Settings_Partial_Load;
      end if;
   end Mark_Partial;

   procedure Note_Unsupported_Field (Status : in out Settings_Status) is
   begin
      Mark_Partial (Status);
      if Last_Ignored_Load_Entries < Natural'Last then
         Last_Ignored_Load_Entries := Last_Ignored_Load_Entries + 1;
      end if;
   end Note_Unsupported_Field;

   procedure Note_Defaulted_Value (Status : in out Settings_Status) is
   begin
      Mark_Partial (Status);
      if Last_Defaulted_Load_Values < Natural'Last then
         Last_Defaulted_Load_Values := Last_Defaulted_Load_Values + 1;
      end if;
   end Note_Defaulted_Value;

   procedure Load_From_File
     (Path     : String;
      Settings : out Settings_Model;
      Status   : out Settings_Status) is
      File    : Ada.Text_IO.File_Type;
      Section : Unbounded_String := Null_Unbounded_String;
      Line_No : Natural := 0;
      Seen_Header : Boolean := False;
      Value_B : Boolean := False;
   begin
      Last_Ignored_Load_Entries := 0;
      Last_Defaulted_Load_Values := 0;
      Set_Defaults (Settings);
      if not Ada.Directories.Exists (Path) then
         Status := Settings_Not_Found;
         return;
      end if;

      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      Status := Settings_Ok;
      while not Ada.Text_IO.End_Of_File (File) loop
         declare
            Raw : constant String := Ada.Text_IO.Get_Line (File);
            L   : constant String := Trimmed (Raw);
            Eq  : Natural := 0;
         begin
            Line_No := Line_No + 1;
            if L'Length = 0 or else L (L'First) = '#' then
               null;
            elsif not Seen_Header then
               if L'Length <= 24
                 or else L (L'First .. L'First + 23) /= "editor-settings-version="
               then
                  Ada.Text_IO.Close (File);
                  Status := Settings_Invalid_Format;
                  Set_Defaults (Settings);
                  return;
               end if;
               declare
                  Version_Text : constant String := L (L'First + 24 .. L'Last);
                  Parsed       : Natural;
               begin
                  Parsed := Natural'Value (Version_Text);
                  if Parsed /= 1 then
                     Ada.Text_IO.Close (File);
                     Status := Settings_Unsupported_Version;
                     Set_Defaults (Settings);
                     return;
                  end if;
                  Settings.Format_Version := Parsed;
                  Seen_Header := True;
               exception
                  when others =>
                     Ada.Text_IO.Close (File);
                     Status := Settings_Invalid_Format;
                     Set_Defaults (Settings);
                     return;
               end;
            elsif not Seen_Header then
               Ada.Text_IO.Close (File);
               Status := Settings_Invalid_Format;
               Set_Defaults (Settings);
               return;
            elsif L (L'First) = '[' and then L (L'Last) = ']' then
               Section := To_Unbounded_String (Lower (Trimmed (L (L'First + 1 .. L'Last - 1))));
            else
               for I in L'Range loop
                  if L (I) = '=' then
                     Eq := I;
                     exit;
                  end if;
               end loop;
               if Eq = 0 then
                  Note_Unsupported_Field (Status);
               else
                  declare
                     Key : constant String := Lower (Trimmed (L (L'First .. Eq - 1)));
                     Val : constant String := Trimmed (L (Eq + 1 .. L'Last));
                     Sec : constant String := To_String (Section);
                  begin
                     if Sec = "appearance" and then Key = "theme" then
                        Set_Theme_Id (Settings, Val);
                        if not Editor.Theme.Is_Valid_Theme_Id (Val) then
                           Set_Theme_Id (Settings, "dark");
                           Note_Defaulted_Value (Status);
                        end if;
                     elsif Sec = "editor" and then Key = "line-numbers" then
                        if Valid_Line_Number_Mode (Val) then
                           Set_Line_Number_Mode_Name (Settings, Val);
                        else
                           Set_Line_Number_Mode_Name (Settings, "absolute");
                           Note_Defaulted_Value (Status);
                        end if;
                     elsif Sec = "editor" and then Key = "cursor-style" then
                        if Valid_Cursor_Style (Val) then
                           Set_Cursor_Style_Name (Settings, Val);
                        else
                           Set_Cursor_Style_Name (Settings, "bar");
                           Note_Defaulted_Value (Status);
                        end if;
                     elsif Sec = "editor" and then Key = "cursor-blink" then
                        if Valid_Boolean (Val, Value_B) then
                           Set_Cursor_Blink (Settings, Value_B);
                        else
                           Set_Cursor_Blink (Settings, True);
                           Note_Defaulted_Value (Status);
                        end if;
                     elsif Sec = "editor" and then Key = "format-on-save" then
                        if Valid_Boolean (Val, Value_B) then
                           Set_Format_On_Save (Settings, Value_B);
                        else
                           Set_Format_On_Save (Settings, False);
                           Note_Defaulted_Value (Status);
                        end if;
                     elsif Sec = "view" and then Key = "minimap-visible" then
                        if Valid_Boolean (Val, Value_B) then
                           Set_Minimap_Visible (Settings, Value_B);
                        else
                           Set_Minimap_Visible (Settings, True);
                           Note_Defaulted_Value (Status);
                        end if;
                     elsif Sec = "view" and then Key = "scrollbars-visible" then
                        if Valid_Boolean (Val, Value_B) then
                           Set_Scrollbars_Visible (Settings, Value_B);
                        else
                           Set_Scrollbars_Visible (Settings, True);
                           Note_Defaulted_Value (Status);
                        end if;
                     elsif Sec = "command-palette" and then Key = "show-unavailable" then
                        if Valid_Boolean (Val, Value_B) then
                           Set_Command_Palette_Show_Unavailable (Settings, Value_B);
                        else
                           Set_Command_Palette_Show_Unavailable (Settings, True);
                           Note_Defaulted_Value (Status);
                        end if;
                     elsif Sec = "command-palette" and then Key = "show-keybindings" then
                        if Valid_Boolean (Val, Value_B) then
                           Set_Command_Palette_Show_Keybindings (Settings, Value_B);
                        else
                           Set_Command_Palette_Show_Keybindings (Settings, True);
                           Note_Defaulted_Value (Status);
                        end if;
                     elsif Sec = "command-palette" and then Key = "show-selected-description" then
                        if Valid_Boolean (Val, Value_B) then
                           Set_Command_Palette_Show_Selected_Description (Settings, Value_B);
                        else
                           Set_Command_Palette_Show_Selected_Description (Settings, True);
                           Note_Defaulted_Value (Status);
                        end if;
                     else
                        Note_Unsupported_Field (Status);
                     end if;
                  end;
               end if;
            end if;
         end;
      end loop;
      Ada.Text_IO.Close (File);
      if not Seen_Header then
         Set_Defaults (Settings);
         Status := Settings_Invalid_Format;
         return;
      end if;
      Normalize (Settings);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         Set_Defaults (Settings);
         Status := Settings_Read_Error;
   end Load_From_File;

end Editor.Settings;
