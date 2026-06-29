with Ada.Strings.Unbounded;

package Editor.Settings is

   type Settings_Status is
     (Settings_Ok,
      Settings_Not_Found,
      Settings_Invalid_Format,
      Settings_Unsupported_Version,
      Settings_Read_Error,
      Settings_Write_Error,
      Settings_Partial_Load);

   type Theme_Setting_Kind is
     (Use_Default_Theme,
      Use_Named_Theme);

   type Settings_Apply_Status is
     (Settings_Apply_Ok,
      Settings_Apply_Partial,
      Settings_Apply_Failed);

   type Settings_Apply_Summary is record
      Status                  : Settings_Apply_Status := Settings_Apply_Ok;
      Theme_Applied           : Boolean := False;
      Theme_Fallback          : Boolean := False;
      Line_Numbers_Applied    : Boolean := False;
      Line_Numbers_Fallback   : Boolean := False;
      Cursor_Applied          : Boolean := False;
      Cursor_Fallback         : Boolean := False;
      Minimap_Applied         : Boolean := False;
      Scrollbars_Applied      : Boolean := False;
      Command_Palette_Applied : Boolean := False;
   end record;

   type Settings_Config is record
      Format_Version : Natural := 1;
   end record;

   type Settings_Model is private;

   --  User-visible editor options currently consumed by the renderer/input
   --  paths.  This process-wide projection remains process-wide while the
   --  persisted Settings_Model below owns the durable global configuration.
   type Settings_State is record
      Show_Minimap             : Boolean := True;
      Show_Line_Numbers        : Boolean := True;
      Highlight_Current_Line   : Boolean := True;
      Highlight_Current_Gutter : Boolean := True;
      Cursor_Blink_Enabled     : Boolean := True;
      Use_Syntax_Colouring     : Boolean := True;
      Use_Semantic_Colouring   : Boolean := True;
      Use_Diagnostic_Overlays  : Boolean := True;
      Use_Search_Overlays      : Boolean := True;
      Show_Diagnostics         : Boolean := True;
      Format_On_Save           : Boolean := False;
   end record;

   function Current return Settings_State;
   procedure Set_Current (Settings : Settings_State);
   procedure Reset;
   function Version return Natural;

   function Show_Minimap return Boolean;
   procedure Set_Show_Minimap (Enabled : Boolean);
   function Show_Line_Numbers return Boolean;
   procedure Set_Show_Line_Numbers (Enabled : Boolean);
   function Highlight_Current_Line return Boolean;
   procedure Set_Highlight_Current_Line (Enabled : Boolean);
   function Highlight_Current_Gutter return Boolean;
   procedure Set_Highlight_Current_Gutter (Enabled : Boolean);
   function Cursor_Blink_Enabled return Boolean;
   procedure Set_Cursor_Blink_Enabled (Enabled : Boolean);
   function Use_Syntax_Colouring return Boolean;
   procedure Set_Use_Syntax_Colouring (Enabled : Boolean);
   function Use_Semantic_Colouring return Boolean;
   procedure Set_Use_Semantic_Colouring (Enabled : Boolean);
   function Use_Diagnostic_Overlays return Boolean;
   procedure Set_Use_Diagnostic_Overlays (Enabled : Boolean);
   function Use_Search_Overlays return Boolean;
   procedure Set_Use_Search_Overlays (Enabled : Boolean);
   function Show_Diagnostics return Boolean;
   procedure Set_Show_Diagnostics (Enabled : Boolean);
   function Format_On_Save return Boolean;
   procedure Set_Format_On_Save (Enabled : Boolean);

   procedure Toggle_Show_Minimap;
   procedure Toggle_Show_Line_Numbers;
   procedure Toggle_Highlight_Current_Line;
   procedure Toggle_Highlight_Current_Gutter;
   procedure Toggle_Cursor_Blink_Enabled;
   procedure Toggle_Use_Syntax_Colouring;
   procedure Toggle_Use_Semantic_Colouring;
   procedure Toggle_Use_Diagnostic_Overlays;
   procedure Toggle_Use_Search_Overlays;
   procedure Toggle_Show_Diagnostics;
   procedure Toggle_Format_On_Save;

   --  Stable persisted setting identifiers.  These are file-format keys, not
   --  user-facing command labels.
   function Setting_Name_Theme return String;
   function Setting_Name_Line_Numbers return String;
   function Setting_Name_Cursor_Style return String;
   function Setting_Name_Cursor_Blink return String;
   function Setting_Name_Minimap_Visible return String;
   function Setting_Name_Scrollbars_Visible return String;
   function Setting_Name_Command_Palette_Show_Unavailable return String;
   function Setting_Name_Command_Palette_Show_Keybindings return String;
   function Setting_Name_Command_Palette_Show_Selected_Description return String;
   function Setting_Name_Format_On_Save return String;

   --  Return stable user-facing labels for persisted settings and load/save
   --  statuses. These helpers are display-only and never mutate settings.
   function Settings_Status_Label (Status : Settings_Status) return String;
   function Settings_Display_Label (Setting_Name : String) return String;

   --  Return a stable user-readable validation message for a proposed
   --  persisted setting value. This helper is display-only and never applies,
   --  saves, repairs, or normalizes settings.
   function Settings_Validation_Message
     (Setting_Name : String;
      Value        : String) return String;

   --  Return bounded diagnostics from the most recent settings load. These
   --  counters are transient recovery/audit observations only and are never
   --  persisted with settings.
   function Last_Load_Ignored_Count return Natural;
   function Last_Load_Defaulted_Count return Natural;

   --  Restore Settings to the built-in global preference defaults.
   --  @param Settings settings model to reset
   procedure Clear (Settings : in out Settings_Model);

   --  Restore Settings to the built-in global preference defaults.
   --  @param Settings settings model to reset
   procedure Set_Defaults (Settings : in out Settings_Model);

   --  Return the persisted settings file format version.
   --  @param Settings settings model to inspect
   --  @return file format version
   function Version (Settings : Settings_Model) return Natural;

   function Theme_Mode (Settings : Settings_Model) return Theme_Setting_Kind;
   function Theme_Id (Settings : Settings_Model) return String;
   procedure Set_Theme_Id (Settings : in out Settings_Model; Id : String);

   function Has_Line_Number_Mode (Settings : Settings_Model) return Boolean;
   function Line_Number_Mode_Name (Settings : Settings_Model) return String;
   procedure Set_Line_Number_Mode_Name
     (Settings : in out Settings_Model;
      Name     : String);

   function Cursor_Style_Name (Settings : Settings_Model) return String;
   procedure Set_Cursor_Style_Name
     (Settings : in out Settings_Model;
      Name     : String);

   function Cursor_Blink (Settings : Settings_Model) return Boolean;
   procedure Set_Cursor_Blink
     (Settings : in out Settings_Model;
      Enabled  : Boolean);

   function Minimap_Visible (Settings : Settings_Model) return Boolean;
   procedure Set_Minimap_Visible
     (Settings : in out Settings_Model;
      Visible  : Boolean);

   function Scrollbars_Visible (Settings : Settings_Model) return Boolean;
   procedure Set_Scrollbars_Visible
     (Settings : in out Settings_Model;
      Visible  : Boolean);

   function Command_Palette_Show_Unavailable
     (Settings : Settings_Model) return Boolean;
   procedure Set_Command_Palette_Show_Unavailable
     (Settings : in out Settings_Model;
      Visible  : Boolean);

   function Command_Palette_Show_Keybindings
     (Settings : Settings_Model) return Boolean;
   procedure Set_Command_Palette_Show_Keybindings
     (Settings : in out Settings_Model;
      Visible  : Boolean);

   function Command_Palette_Show_Selected_Description
     (Settings : Settings_Model) return Boolean;
   procedure Set_Command_Palette_Show_Selected_Description
     (Settings : in out Settings_Model;
      Visible  : Boolean);

   function Format_On_Save (Settings : Settings_Model) return Boolean;
   procedure Set_Format_On_Save
     (Settings : in out Settings_Model;
      Enabled  : Boolean);

   --  Normalize unsupported optional values to built-in defaults.
   --  @param Settings settings model to normalize
   procedure Normalize (Settings : in out Settings_Model);

   --  Semantic settings equality ignoring representation-only differences.
   function Equivalent (Left, Right : Settings_Model) return Boolean;

   --  Build a persisted settings model from current process-wide editor
   --  preference state. This does not save workspace/session/file contents.
   function Build_From_Current return Settings_Model;

   --  Apply a persisted settings model to process-wide editor preference
   --  state. This does not open files, restore workspaces, or mutate buffers.
   procedure Apply (Settings : Settings_Model);

   --  Apply settings and return a compact subsystem-level summary.
   --  The summary is reporting-only; it does not own diagnostics text.
   procedure Apply
     (Settings : Settings_Model;
      Summary  : out Settings_Apply_Summary);

   --  Return the global editor settings path.  EDITOR_SETTINGS_PATH overrides
   --  the default for tests; otherwise $XDG_CONFIG_HOME/editor/settings or
   --  $HOME/.config/editor/settings is used.
   function Settings_File_Path return String;

   --  Save global editor settings to Path using deterministic serialization
   --  and best-effort atomic temp-file replacement.
   procedure Save_To_File
     (Settings : Settings_Model;
      Path     : String;
      Status   : out Settings_Status);

   --  Load global editor settings from Path. Missing files are reported as
   --  Settings_Not_Found and should normally cause callers to use defaults.
   --  This procedure does not mutate live editor state directly.
   procedure Load_From_File
     (Path     : String;
      Settings : out Settings_Model;
      Status   : out Settings_Status);

private
   use Ada.Strings.Unbounded;

   type Settings_Model is record
      Format_Version                    : Natural := 1;
      Theme_Mode_Value                  : Theme_Setting_Kind := Use_Named_Theme;
      Theme_Id_Value                    : Unbounded_String := To_Unbounded_String ("dark");
      Has_Line_Number_Mode_Value        : Boolean := True;
      Line_Number_Mode_Value            : Unbounded_String := To_Unbounded_String ("absolute");
      Cursor_Style_Value                : Unbounded_String := To_Unbounded_String ("bar");
      Cursor_Blink_Value                : Boolean := True;
      Minimap_Visible_Value             : Boolean := True;
      Scrollbars_Visible_Value          : Boolean := True;
      Format_On_Save_Value              : Boolean := False;
      Command_Palette_Show_Unavailable  : Boolean := True;
      Command_Palette_Show_Keybindings  : Boolean := True;
      Command_Palette_Show_Selected_Description : Boolean := True;
   end record;

end Editor.Settings;
