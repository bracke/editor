with Ada.Characters.Handling;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;
with Editor.Theme;
with Editor.Commands;

package body Editor.Settings_Management is

   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Category;
   use type Editor.Settings.Settings_Status;

   type Setting_Descriptor is record
      Key          : Unbounded_String;
      Category     : Setting_Category;
      Kind         : Setting_Value_Kind;
      Default      : Unbounded_String;
      Description  : Unbounded_String;
   end record;

   Descriptors : constant array (Positive range 1 .. 10) of Setting_Descriptor :=
     ((To_Unbounded_String (Editor.Settings.Setting_Name_Theme),
       Appearance_Setting,
       Setting_Enum,
       To_Unbounded_String ("dark"),
       To_Unbounded_String ("Global editor theme identifier; unsupported themes fall back to the default.")),
      (To_Unbounded_String (Editor.Settings.Setting_Name_Line_Numbers),
       Editor_Setting,
       Setting_Enum,
       To_Unbounded_String ("absolute"),
       To_Unbounded_String ("Line-number display mode: absolute, relative, hybrid, or off.")),
      (To_Unbounded_String (Editor.Settings.Setting_Name_Cursor_Style),
       Editor_Setting,
       Setting_Enum,
       To_Unbounded_String ("bar"),
       To_Unbounded_String ("Cursor shape: bar, block, or underline.")),
      (To_Unbounded_String (Editor.Settings.Setting_Name_Cursor_Blink),
       Editor_Setting,
       Setting_Boolean,
       To_Unbounded_String ("true"),
       To_Unbounded_String ("Enable or disable cursor blinking.")),
      (To_Unbounded_String (Editor.Settings.Setting_Name_Format_On_Save),
       Editor_Setting,
       Setting_Boolean,
       To_Unbounded_String ("false"),
       To_Unbounded_String ("Format the active buffer automatically before file saves.")),
      (To_Unbounded_String (Editor.Settings.Setting_Name_Minimap_Visible),
       View_Setting,
       Setting_Boolean,
       To_Unbounded_String ("true"),
       To_Unbounded_String ("Show or hide the minimap view.")),
      (To_Unbounded_String (Editor.Settings.Setting_Name_Scrollbars_Visible),
       View_Setting,
       Setting_Boolean,
       To_Unbounded_String ("true"),
       To_Unbounded_String ("Show or hide editor scrollbars.")),
      (To_Unbounded_String (Editor.Settings.Setting_Name_Command_Palette_Show_Unavailable),
       Command_Palette_Setting,
       Setting_Boolean,
       To_Unbounded_String ("true"),
       To_Unbounded_String ("Show unavailable commands in the Command Palette as disabled rows.")),
      (To_Unbounded_String (Editor.Settings.Setting_Name_Command_Palette_Show_Keybindings),
       Command_Palette_Setting,
       Setting_Boolean,
       To_Unbounded_String ("true"),
       To_Unbounded_String ("Show active keybinding labels in Command Palette rows; this does not store keybindings.")),
      (To_Unbounded_String (Editor.Settings.Setting_Name_Command_Palette_Show_Selected_Description),
       Command_Palette_Setting,
       Setting_Boolean,
       To_Unbounded_String ("true"),
       To_Unbounded_String ("Show the selected command description/help text in the Command Palette details surface.")));

   Current_UI : Settings_Editor_State;

   function Lower (Text : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (Text);
   end Lower;

   function Trimmed (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trimmed;

   function Bool_Image (Value : Boolean) return String is
   begin
      return (if Value then "true" else "false");
   end Bool_Image;

   function Count_Image (Value : Natural) return String is
      Raw : constant String := Natural'Image (Value);
   begin
      return Raw (Raw'First + 1 .. Raw'Last);
   end Count_Image;


   function Clamped_Query (Query : String) return String is
   begin
      if Query'Length <= Max_Settings_Query_Length then
         return Query;
      else
         return Query (Query'First .. Query'First + Max_Settings_Query_Length - 1);
      end if;
   end Clamped_Query;

   procedure Ensure_Selected (UI : in out Settings_Editor_State) is
   begin
      if UI.Selected_Index = 0 and then Setting_Count > 0 then
         UI.Selected_Index := 1;
      elsif UI.Selected_Index > Setting_Count then
         UI.Selected_Index := Setting_Count;
      end if;
   end Ensure_Selected;

   procedure Show_Settings (UI : in out Settings_Editor_State) is
   begin
      UI.Visible := True;
      Ensure_Selected (UI);
   end Show_Settings;

   procedure Hide_Settings (UI : in out Settings_Editor_State) is
   begin
      UI.Visible := False;
      UI.Focused := False;
   end Hide_Settings;

   procedure Focus_Settings (UI : in out Settings_Editor_State) is
   begin
      UI.Visible := True;
      UI.Focused := True;
      Ensure_Selected (UI);
   end Focus_Settings;

   procedure Select_Next_Setting (UI : in out Settings_Editor_State) is
   begin
      Ensure_Selected (UI);
      if Setting_Count = 0 then
         UI.Selected_Index := 0;
      elsif UI.Selected_Index >= Setting_Count then
         UI.Selected_Index := 1;
      else
         UI.Selected_Index := UI.Selected_Index + 1;
      end if;
   end Select_Next_Setting;

   procedure Select_Previous_Setting (UI : in out Settings_Editor_State) is
   begin
      Ensure_Selected (UI);
      if Setting_Count = 0 then
         UI.Selected_Index := 0;
      elsif UI.Selected_Index <= 1 then
         UI.Selected_Index := Setting_Count;
      else
         UI.Selected_Index := UI.Selected_Index - 1;
      end if;
   end Select_Previous_Setting;

   procedure Set_Search_Query (UI : in out Settings_Editor_State; Query : String) is
   begin
      UI.Query := To_Unbounded_String (Clamped_Query (Query));
   end Set_Search_Query;

   procedure Clear_Search_Query (UI : in out Settings_Editor_State) is
   begin
      UI.Query := Null_Unbounded_String;
   end Clear_Search_Query;

   procedure Set_Filter (UI : in out Settings_Editor_State; Filter : Settings_Filter) is
   begin
      UI.Filter := Filter;
   end Set_Filter;

   procedure Clear_Filter (UI : in out Settings_Editor_State) is
   begin
      UI.Filter := Filter_All_Settings;
   end Clear_Filter;

   procedure Request_Reset_All_Settings (UI : in out Settings_Editor_State) is
   begin
      UI.Pending_Reset_All := True;
   end Request_Reset_All_Settings;

   procedure Confirm_Reset_All_Settings
     (Settings : in out Editor.Settings.Settings_Model;
      UI       : in out Settings_Editor_State;
      Status   : out Setting_Update_Status)
   is
   begin
      if not UI.Pending_Reset_All then
         Status := Setting_Update_No_Selection;
         return;
      end if;
      Reset_All_Settings (Settings);
      UI.Pending_Reset_All := False;
      Status := Setting_Update_Ok;
   end Confirm_Reset_All_Settings;

   procedure Cancel_Reset_All_Settings
     (UI     : in out Settings_Editor_State;
      Status : out Setting_Update_Status)
   is
   begin
      if not UI.Pending_Reset_All then
         Status := Setting_Update_No_Selection;
      else
         UI.Pending_Reset_All := False;
         Status := Setting_Update_Confirmation_Cancelled;
      end if;
   end Cancel_Reset_All_Settings;

   function Has_Pending_Reset_All (UI : Settings_Editor_State) return Boolean is
   begin
      return UI.Pending_Reset_All;
   end Has_Pending_Reset_All;

   function Selected_Key (UI : Settings_Editor_State) return String is
   begin
      if UI.Selected_Index = 0 or else UI.Selected_Index > Setting_Count then
         return "";
      else
         return To_String (Descriptors (UI.Selected_Index).Key);
      end if;
   end Selected_Key;

   function Valid_Boolean (Text : String; Value : out Boolean) return Boolean is
      L : constant String := Lower (Trimmed (Text));
   begin
      if L = "true" then
         Value := True;
         return True;
      elsif L = "false" then
         Value := False;
         return True;
      else
         Value := False;
         return False;
      end if;
   end Valid_Boolean;

   function Is_Valid_Line_Mode (Text : String) return Boolean is
      L : constant String := Lower (Trimmed (Text));
   begin
      return L = "absolute" or else L = "relative" or else L = "hybrid" or else L = "off";
   end Is_Valid_Line_Mode;

   function Is_Valid_Cursor_Style (Text : String) return Boolean is
      L : constant String := Lower (Trimmed (Text));
   begin
      return L = "bar" or else L = "block" or else L = "underline";
   end Is_Valid_Cursor_Style;

   procedure Reset_Transient_State is
   begin
      Current_UI := (others => <>);
   end Reset_Transient_State;

   function Current_Settings_Editor_State return Settings_Editor_State is
   begin
      return Current_UI;
   end Current_Settings_Editor_State;

   procedure Set_Current_Settings_Editor_State (UI : Settings_Editor_State) is
   begin
      Current_UI := UI;
      Ensure_Selected (Current_UI);
   end Set_Current_Settings_Editor_State;

   function Current_Settings_Surface_Visible return Boolean is
   begin
      return Current_UI.Visible;
   end Current_Settings_Surface_Visible;

   function Current_Settings_Surface_Focused return Boolean is
   begin
      return Current_UI.Focused;
   end Current_Settings_Surface_Focused;

   function Setting_Count return Natural is
   begin
      return Descriptors'Length;
   end Setting_Count;

   function Category_Label (Category : Setting_Category) return String is
   begin
      case Category is
         when Appearance_Setting => return "Appearance";
         when Editor_Setting => return "Editor";
         when View_Setting => return "View";
         when Command_Palette_Setting => return "Command Palette";
      end case;
   end Category_Label;

   function Value_Kind_Label (Kind : Setting_Value_Kind) return String is
   begin
      case Kind is
         when Setting_Boolean => return "boolean";
         when Setting_Enum => return "enum";
         when Setting_Text => return "text";
      end case;
   end Value_Kind_Label;

   function Current_Value
     (Settings : Editor.Settings.Settings_Model;
      Key      : String) return String
   is
      K : constant String := Lower (Key);
   begin
      if K = Editor.Settings.Setting_Name_Theme then
         return Editor.Settings.Theme_Id (Settings);
      elsif K = Editor.Settings.Setting_Name_Line_Numbers then
         return Editor.Settings.Line_Number_Mode_Name (Settings);
      elsif K = Editor.Settings.Setting_Name_Cursor_Style then
         return Editor.Settings.Cursor_Style_Name (Settings);
      elsif K = Editor.Settings.Setting_Name_Cursor_Blink then
         return Bool_Image (Editor.Settings.Cursor_Blink (Settings));
      elsif K = Editor.Settings.Setting_Name_Format_On_Save then
         return Bool_Image (Editor.Settings.Format_On_Save (Settings));
      elsif K = Editor.Settings.Setting_Name_Minimap_Visible then
         return Bool_Image (Editor.Settings.Minimap_Visible (Settings));
      elsif K = Editor.Settings.Setting_Name_Scrollbars_Visible then
         return Bool_Image (Editor.Settings.Scrollbars_Visible (Settings));
      elsif K = Editor.Settings.Setting_Name_Command_Palette_Show_Unavailable then
         return Bool_Image (Editor.Settings.Command_Palette_Show_Unavailable (Settings));
      elsif K = Editor.Settings.Setting_Name_Command_Palette_Show_Keybindings then
         return Bool_Image (Editor.Settings.Command_Palette_Show_Keybindings (Settings));
      elsif K = Editor.Settings.Setting_Name_Command_Palette_Show_Selected_Description then
         return Bool_Image (Editor.Settings.Command_Palette_Show_Selected_Description (Settings));
      else
         return "";
      end if;
   end Current_Value;

   function Index_For_Key (Key : String) return Natural is
      K : constant String := Lower (Trimmed (Key));
   begin
      for I in Descriptors'Range loop
         if To_String (Descriptors (I).Key) = K then
            return I;
         end if;
      end loop;
      return 0;
   end Index_For_Key;

   function Valid_Message (Key, Value : String) return String is
   begin
      return Editor.Settings.Settings_Validation_Message (Key, Value);
   end Valid_Message;

   function Row_At
     (Settings : Editor.Settings.Settings_Model;
      Index    : Positive) return Setting_Row
   is
      Desc : constant Setting_Descriptor := Descriptors (Index);
      Key  : constant String := To_String (Desc.Key);
      Val  : constant String := Current_Value (Settings, Key);
      Msg  : constant String := Valid_Message (Key, Val);
   begin
      return
        (Key                => Desc.Key,
         Display_Name       => To_Unbounded_String (Editor.Settings.Settings_Display_Label (Key)),
         Category_Name      => To_Unbounded_String (Category_Label (Desc.Category)),
         Current_Value      => To_Unbounded_String (Val),
         Default_Value      => Desc.Default,
         Description        => Desc.Description,
         Source_Label       => To_Unbounded_String (if Val = To_String (Desc.Default) then "default" else "user"),
         Validation_Message => To_Unbounded_String (Msg),
         Kind               => Desc.Kind,
         Category           => Desc.Category,
         Editable           => True,
         Toggleable         => Desc.Kind = Setting_Boolean,
         Modified           => Val /= To_String (Desc.Default),
         Valid              => Msg = "Setting is valid.",
         Selected           => False);
   end Row_At;

   function Contains (Haystack, Needle : String) return Boolean is
      H : constant String := Lower (Haystack);
      N : constant String := Lower (Needle);
   begin
      if Trimmed (N)'Length = 0 then
         return True;
      end if;
      return Ada.Strings.Fixed.Index (H, N) > 0;
   end Contains;

   function Matches_Search
     (Row   : Setting_Row;
      Query : String) return Boolean
   is
   begin
      return Contains (To_String (Row.Key), Query)
        or else Contains (To_String (Row.Display_Name), Query)
        or else Contains (To_String (Row.Category_Name), Query)
        or else Contains (To_String (Row.Current_Value), Query)
        or else Contains (To_String (Row.Default_Value), Query)
        or else Contains (To_String (Row.Description), Query);
   end Matches_Search;

   function Matches_Filter
     (Row    : Setting_Row;
      Filter : Settings_Filter) return Boolean
   is
   begin
      case Filter is
         when Filter_All_Settings => return True;
         when Filter_Modified_Settings => return Row.Modified;
         when Filter_Invalid_Settings => return not Row.Valid;
         when Filter_Appearance_Settings => return Row.Category = Appearance_Setting;
         when Filter_Editor_Settings => return Row.Category = Editor_Setting;
         when Filter_View_Settings => return Row.Category = View_Setting;
         when Filter_Command_Palette_Settings => return Row.Category = Command_Palette_Setting;
      end case;
   end Matches_Filter;

   function Update_Status_Label (Status : Setting_Update_Status) return String is
   begin
      case Status is
         when Setting_Update_Ok => return "Setting updated.";
         when Setting_Update_Unknown => return "Unknown setting.";
         when Setting_Update_Not_Toggleable => return "Selected setting is not toggleable.";
         when Setting_Update_Invalid_Value => return "Invalid setting value.";
         when Setting_Update_Already_Default => return "Selected setting is already default.";
         when Setting_Update_No_Selection => return "No setting selected.";
         when Setting_Update_Confirmation_Required => return "Confirm reset all settings.";
         when Setting_Update_Confirmation_Cancelled => return "Settings reset cancelled.";
         when Setting_Update_Blocked_By_Confirmation => return "Command unavailable while confirmation is pending.";
      end case;
   end Update_Status_Label;


   function Setting_Outcome_Message
     (Key    : String;
      Status : Setting_Update_Status) return String
   is
      Label : constant String := Editor.Settings.Settings_Display_Label (Key);
   begin
      case Status is
         when Setting_Update_Ok =>
            if Label = "Unknown setting" then
               return "Setting updated.";
            else
               return Label & " setting updated.";
            end if;
         when others =>
            return Update_Status_Label (Status);
      end case;
   end Setting_Outcome_Message;

   procedure Set_Boolean
     (Settings : in out Editor.Settings.Settings_Model;
      Key      : String;
      Value    : Boolean)
   is
      K : constant String := Lower (Trimmed (Key));
   begin
      if K = Editor.Settings.Setting_Name_Cursor_Blink then
         Editor.Settings.Set_Cursor_Blink (Settings, Value);
      elsif K = Editor.Settings.Setting_Name_Format_On_Save then
         Editor.Settings.Set_Format_On_Save (Settings, Value);
      elsif K = Editor.Settings.Setting_Name_Minimap_Visible then
         Editor.Settings.Set_Minimap_Visible (Settings, Value);
      elsif K = Editor.Settings.Setting_Name_Scrollbars_Visible then
         Editor.Settings.Set_Scrollbars_Visible (Settings, Value);
      elsif K = Editor.Settings.Setting_Name_Command_Palette_Show_Unavailable then
         Editor.Settings.Set_Command_Palette_Show_Unavailable (Settings, Value);
      elsif K = Editor.Settings.Setting_Name_Command_Palette_Show_Keybindings then
         Editor.Settings.Set_Command_Palette_Show_Keybindings (Settings, Value);
      elsif K = Editor.Settings.Setting_Name_Command_Palette_Show_Selected_Description then
         Editor.Settings.Set_Command_Palette_Show_Selected_Description (Settings, Value);
      end if;
   end Set_Boolean;

   procedure Toggle_Setting
     (Settings : in out Editor.Settings.Settings_Model;
      Key      : String;
      Status   : out Setting_Update_Status)
   is
      Index : constant Natural := Index_For_Key (Key);
      Value : Boolean := False;
   begin
      if Index = 0 then
         Status := Setting_Update_Unknown;
         return;
      end if;
      declare
         Row : constant Setting_Row := Row_At (Settings, Index);
      begin
      if not Row.Toggleable then
         Status := Setting_Update_Not_Toggleable;
         return;
      end if;
      if not Valid_Boolean (To_String (Row.Current_Value), Value) then
         Status := Setting_Update_Invalid_Value;
         return;
      end if;
      Set_Boolean (Settings, Key, not Value);
      Status := Setting_Update_Ok;
      end;
   end Toggle_Setting;

   procedure Cycle_Setting
     (Settings : in out Editor.Settings.Settings_Model;
      Key      : String;
      Status   : out Setting_Update_Status)
   is
      K : constant String := Lower (Trimmed (Key));
      Cur : constant String := Lower (Current_Value (Settings, K));
   begin
      if Index_For_Key (K) = 0 then
         Status := Setting_Update_Unknown;
      elsif K = Editor.Settings.Setting_Name_Line_Numbers then
         if Cur = "absolute" then
            Editor.Settings.Set_Line_Number_Mode_Name (Settings, "relative");
         elsif Cur = "relative" then
            Editor.Settings.Set_Line_Number_Mode_Name (Settings, "hybrid");
         elsif Cur = "hybrid" then
            Editor.Settings.Set_Line_Number_Mode_Name (Settings, "off");
         else
            Editor.Settings.Set_Line_Number_Mode_Name (Settings, "absolute");
         end if;
         Status := Setting_Update_Ok;
      elsif K = Editor.Settings.Setting_Name_Cursor_Style then
         if Cur = "bar" then
            Editor.Settings.Set_Cursor_Style_Name (Settings, "block");
         elsif Cur = "block" then
            Editor.Settings.Set_Cursor_Style_Name (Settings, "underline");
         else
            Editor.Settings.Set_Cursor_Style_Name (Settings, "bar");
         end if;
         Status := Setting_Update_Ok;
      elsif K = Editor.Settings.Setting_Name_Theme then
         if Cur = "dark" then
            Editor.Settings.Set_Theme_Id (Settings, "light");
         else
            Editor.Settings.Set_Theme_Id (Settings, "dark");
         end if;
         Status := Setting_Update_Ok;
      else
         Toggle_Setting (Settings, K, Status);
      end if;
   end Cycle_Setting;

   procedure Set_Setting_Value
     (Settings : in out Editor.Settings.Settings_Model;
      Key      : String;
      Value    : String;
      Status   : out Setting_Update_Status)
   is
      K : constant String := Lower (Trimmed (Key));
      V : constant String := Lower (Trimmed (Value));
      B : Boolean := False;
   begin
      if Index_For_Key (K) = 0 then
         Status := Setting_Update_Unknown;
      elsif K = Editor.Settings.Setting_Name_Theme then
         if V'Length = 0 or else Editor.Theme.Is_Valid_Theme_Id (V) then
            Editor.Settings.Set_Theme_Id (Settings, (if V'Length = 0 then "dark" else V));
            Status := Setting_Update_Ok;
         else
            Status := Setting_Update_Invalid_Value;
         end if;
      elsif K = Editor.Settings.Setting_Name_Line_Numbers then
         if Is_Valid_Line_Mode (V) then
            Editor.Settings.Set_Line_Number_Mode_Name (Settings, V);
            Status := Setting_Update_Ok;
         else
            Status := Setting_Update_Invalid_Value;
         end if;
      elsif K = Editor.Settings.Setting_Name_Cursor_Style then
         if Is_Valid_Cursor_Style (V) then
            Editor.Settings.Set_Cursor_Style_Name (Settings, V);
            Status := Setting_Update_Ok;
         else
            Status := Setting_Update_Invalid_Value;
         end if;
      elsif Valid_Boolean (V, B) then
         Set_Boolean (Settings, K, B);
         Status := Setting_Update_Ok;
      else
         Status := Setting_Update_Invalid_Value;
      end if;
   end Set_Setting_Value;

   procedure Reset_Setting
     (Settings : in out Editor.Settings.Settings_Model;
      Key      : String;
      Status   : out Setting_Update_Status)
   is
      Index : constant Natural := Index_For_Key (Key);
   begin
      if Index = 0 then
         Status := Setting_Update_Unknown;
         return;
      end if;
      declare
         Row : constant Setting_Row := Row_At (Settings, Index);
      begin
      if not Row.Modified then
         Status := Setting_Update_Already_Default;
         return;
      end if;
      Set_Setting_Value (Settings, Key, To_String (Row.Default_Value), Status);
      end;
   end Reset_Setting;

   procedure Reset_All_Settings
     (Settings : in out Editor.Settings.Settings_Model) is
   begin
      Editor.Settings.Set_Defaults (Settings);
   end Reset_All_Settings;


   procedure Toggle_Selected_Setting
     (Settings : in out Editor.Settings.Settings_Model;
      UI       : Settings_Editor_State;
      Status   : out Setting_Update_Status)
   is
      Key : constant String := Selected_Key (UI);
   begin
      if Key'Length = 0 then
         Status := Setting_Update_No_Selection;
      else
         Toggle_Setting (Settings, Key, Status);
      end if;
   end Toggle_Selected_Setting;

   procedure Cycle_Selected_Setting
     (Settings : in out Editor.Settings.Settings_Model;
      UI       : Settings_Editor_State;
      Status   : out Setting_Update_Status)
   is
      Key : constant String := Selected_Key (UI);
   begin
      if Key'Length = 0 then
         Status := Setting_Update_No_Selection;
      else
         Cycle_Setting (Settings, Key, Status);
      end if;
   end Cycle_Selected_Setting;

   procedure Set_Selected_Setting_Value
     (Settings : in out Editor.Settings.Settings_Model;
      UI       : Settings_Editor_State;
      Value    : String;
      Status   : out Setting_Update_Status)
   is
      Key : constant String := Selected_Key (UI);
   begin
      if Key'Length = 0 then
         Status := Setting_Update_No_Selection;
      else
         Set_Setting_Value (Settings, Key, Value, Status);
      end if;
   end Set_Selected_Setting_Value;

   procedure Reset_Selected_Setting
     (Settings : in out Editor.Settings.Settings_Model;
      UI       : Settings_Editor_State;
      Status   : out Setting_Update_Status)
   is
      Key : constant String := Selected_Key (UI);
   begin
      if Key'Length = 0 then
         Status := Setting_Update_No_Selection;
      else
         Reset_Setting (Settings, Key, Status);
      end if;
   end Reset_Selected_Setting;


   function Forbidden_Runtime_Section (Section : String) return Boolean is
      S : constant String := Lower (Trimmed (Section));
   begin
      return S = "settings-editor"
        or else S = "configuration-audit"
        or else S = "settings-ui"
        or else S = "pending-confirmation";
   end Forbidden_Runtime_Section;

   function Known_Field (Section, Key : String) return Boolean is
      S : constant String := Lower (Trimmed (Section));
      K : constant String := Lower (Trimmed (Key));
   begin
      return (S = "appearance" and then K = "theme")
        or else (S = "editor" and then
                   (K = "line-numbers" or else K = "cursor-style"
                    or else K = "cursor-blink" or else K = "format-on-save"))
        or else (S = "view" and then (K = "minimap-visible" or else K = "scrollbars-visible"))
        or else (S = "command-palette" and then
                   (K = "show-unavailable" or else K = "show-keybindings" or else K = "show-selected-description"));
   end Known_Field;

   function Field_Valid (Section, Key, Value : String) return Boolean is
      S : constant String := Lower (Trimmed (Section));
      K : constant String := Lower (Trimmed (Key));
      V : constant String := Lower (Trimmed (Value));
      B : Boolean := False;
   begin
      if S = "appearance" and then K = "theme" then
         return V'Length = 0 or else Editor.Theme.Is_Valid_Theme_Id (V);
      elsif S = "editor" and then K = "line-numbers" then
         return Is_Valid_Line_Mode (V);
      elsif S = "editor" and then K = "cursor-style" then
         return Is_Valid_Cursor_Style (V);
      elsif K = "cursor-blink" or else K = "minimap-visible" or else K = "scrollbars-visible"
        or else K = "show-unavailable" or else K = "show-keybindings"
        or else K = "show-selected-description"
        or else K = "format-on-save"
      then
         return Valid_Boolean (V, B);
      else
         return False;
      end if;
   end Field_Valid;

   procedure Audit_Domain_Separation_Text
     (Text   : String;
      Result : out Domain_Separation_Audit)
   is
      L : constant String := Lower (Text);
      function Contains (Pattern : String) return Boolean is
      begin
         return Ada.Strings.Fixed.Index (L, Pattern) > 0;
      end Contains;
      function Starts_With (Pattern : String) return Boolean is
      begin
         return L'Length >= Pattern'Length
           and then L (L'First .. L'First + Pattern'Length - 1) = Pattern;
      end Starts_With;
      procedure Mark (Condition : Boolean; Flag : in out Boolean) is
      begin
         if Condition and then not Flag then
            Flag := True;
            Result.Forbidden_Field_Count := Result.Forbidden_Field_Count + 1;
         end if;
      end Mark;
   begin
      Result := (others => <>);
      Mark (Contains ("[keybindings]")
            or else Starts_With ("keybinding.")
            or else Starts_With ("keybindings=")
            or else Starts_With ("keybinding=")
            or else Starts_With ("chord="),
            Result.Settings_Contains_Keybindings);
      Mark (Contains ("workspace") or else Contains ("open-file")
            or else Contains ("active-file") or else Contains ("project-root"),
            Result.Settings_Contains_Workspace);
      Mark (Contains ("recent-project"),
            Result.Settings_Contains_Recent);
      Mark (Contains ("build-result") or else Contains ("search-query")
            or else Contains ("outline-row") or else Contains ("diagnostic-row")
            or else Contains ("command-payload") or else Contains ("dirty-state")
            or else Contains ("settings-query") or else Contains ("settings-selection")
            or else Contains ("settings-filter") or else Contains ("configuration-audit-result")
            or else Contains ("pending-settings-reset-confirmation"),
            Result.Settings_Contains_Runtime);
   end Audit_Domain_Separation_Text;

   procedure Audit_Settings_File
     (Path   : String;
      Result : out Settings_File_Audit)
   is
      File    : Ada.Text_IO.File_Type;
      Section : Unbounded_String := Null_Unbounded_String;
      Seen_Header : Boolean := False;
      Domain : Domain_Separation_Audit;
   begin
      Result := (others => <>);
      if not Ada.Directories.Exists (Path) then
         Result.Load_Status := Editor.Settings.Settings_Not_Found;
         return;
      end if;

      declare
         Loaded : Editor.Settings.Settings_Model;
      begin
         Editor.Settings.Load_From_File (Path, Loaded, Result.Load_Status);
      end;

      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         declare
            Raw : constant String := Ada.Text_IO.Get_Line (File);
            L   : constant String := Trimmed (Raw);
            Eq  : Natural := 0;
         begin
            Audit_Domain_Separation_Text (L, Domain);
            Result.Forbidden_Domain_Count := Result.Forbidden_Domain_Count + Domain.Forbidden_Field_Count;

            if L'Length = 0 or else L (L'First) = '#' then
               null;
            elsif not Seen_Header then
               if L'Length > 24 and then L (L'First .. L'First + 23) = "editor-settings-version=" then
                  Seen_Header := True;
               else
                  Result.Malformed_Line_Count := Result.Malformed_Line_Count + 1;
               end if;
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
                  Result.Malformed_Line_Count := Result.Malformed_Line_Count + 1;
               else
                  declare
                     Key : constant String := Lower (Trimmed (L (L'First .. Eq - 1)));
                     Val : constant String := Trimmed (L (Eq + 1 .. L'Last));
                     Sec : constant String := To_String (Section);
                  begin
                     if Known_Field (Sec, Key) then
                        Result.Supported_Field_Count := Result.Supported_Field_Count + 1;
                        if not Field_Valid (Sec, Key, Val) then
                           Result.Invalid_Value_Count := Result.Invalid_Value_Count + 1;
                        end if;
                     else
                        Result.Unknown_Field_Count := Result.Unknown_Field_Count + 1;
                        if Forbidden_Runtime_Section (Sec) then
                           Result.Forbidden_Domain_Count := Result.Forbidden_Domain_Count + 1;
                        end if;
                     end if;
                  end;
               end if;
            end if;
         end;
      end loop;
      Ada.Text_IO.Close (File);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         Result.Load_Status := Editor.Settings.Settings_Read_Error;
   end Audit_Settings_File;



   procedure From_File_Audit
     (Audit   : Settings_File_Audit;
      Summary : out Settings_Persistence_Summary)
   is
   begin
      Summary :=
        (Status                => Audit.Load_Status,
         Supported_Field_Count => Audit.Supported_Field_Count,
         Unknown_Field_Count   => Audit.Unknown_Field_Count,
         Invalid_Value_Count   => Audit.Invalid_Value_Count,
         Forbidden_Field_Count => Audit.Forbidden_Domain_Count,
         Malformed_Line_Count  => Audit.Malformed_Line_Count);
   end From_File_Audit;

   procedure Save_User_Config
     (Settings : Editor.Settings.Settings_Model;
      Path     : String;
      Summary  : out Settings_Persistence_Summary)
   is
      Status : Editor.Settings.Settings_Status;
      Audit  : Settings_File_Audit;
   begin
      Summary := (others => <>);
      Editor.Settings.Save_To_File (Settings, Path, Status);
      if Status /= Editor.Settings.Settings_Ok then
         Summary.Status := Status;
         return;
      end if;

      Audit_Settings_File (Path, Audit);
      From_File_Audit (Audit, Summary);
      if Summary.Status = Editor.Settings.Settings_Ok
        and then (Summary.Unknown_Field_Count /= 0
                  or else Summary.Invalid_Value_Count /= 0
                  or else Summary.Forbidden_Field_Count /= 0
                  or else Summary.Malformed_Line_Count /= 0)
      then
         Summary.Status := Editor.Settings.Settings_Partial_Load;
      end if;
   end Save_User_Config;

   procedure Load_User_Config
     (Path     : String;
      Settings : out Editor.Settings.Settings_Model;
      Summary  : out Settings_Persistence_Summary)
   is
      Audit : Settings_File_Audit;
   begin
      Summary := (others => <>);
      Editor.Settings.Load_From_File (Path, Settings, Summary.Status);
      Audit_Settings_File (Path, Audit);
      if Audit.Load_Status = Editor.Settings.Settings_Not_Found then
         Summary.Status := Editor.Settings.Settings_Not_Found;
      else
         Summary.Supported_Field_Count := Audit.Supported_Field_Count;
         Summary.Unknown_Field_Count := Audit.Unknown_Field_Count;
         Summary.Invalid_Value_Count := Audit.Invalid_Value_Count;
         Summary.Forbidden_Field_Count := Audit.Forbidden_Domain_Count;
         Summary.Malformed_Line_Count := Audit.Malformed_Line_Count;
         if Summary.Status = Editor.Settings.Settings_Ok
           and then (Summary.Unknown_Field_Count /= 0
                     or else Summary.Invalid_Value_Count /= 0
                     or else Summary.Forbidden_Field_Count /= 0
                     or else Summary.Malformed_Line_Count /= 0)
         then
            Summary.Status := Editor.Settings.Settings_Partial_Load;
         end if;
      end if;
   end Load_User_Config;

   function Persistence_Summary_Message
     (Operation : String;
      Summary   : Settings_Persistence_Summary) return String
   is
      Op : constant String := Lower (Trimmed (Operation));
      Prefix : constant String := (if Op = "save" or else Op = "saved" then "Settings saved" else "Settings loaded");
      Detail : constant String :=
        Count_Image (Summary.Unknown_Field_Count) & " unsupported, "
        & Count_Image (Summary.Invalid_Value_Count) & " invalid, "
        & Count_Image (Summary.Forbidden_Field_Count) & " forbidden-domain, "
        & Count_Image (Summary.Malformed_Line_Count) & " malformed";
   begin
      case Summary.Status is
         when Editor.Settings.Settings_Ok =>
            if Summary.Unknown_Field_Count = 0
              and then Summary.Invalid_Value_Count = 0
              and then Summary.Forbidden_Field_Count = 0
              and then Summary.Malformed_Line_Count = 0
            then
               return Prefix & ".";
            else
               return Prefix & "; " & Detail & ".";
            end if;
         when Editor.Settings.Settings_Not_Found =>
            return "Settings file unavailable.";
         when Editor.Settings.Settings_Write_Error =>
            return "Settings file could not be written.";
         when Editor.Settings.Settings_Read_Error =>
            return "Settings file could not be read.";
         when Editor.Settings.Settings_Invalid_Format =>
            return "Settings file has an invalid format.";
         when Editor.Settings.Settings_Unsupported_Version =>
            return "Settings file version is not supported.";
         when Editor.Settings.Settings_Partial_Load =>
            return Prefix & "; " & Detail & ".";
      end case;
   end Persistence_Summary_Message;

   function Assert_Settings_Save_Writes_Global_Preferences_Only return Boolean is
      Path     : constant String := "/tmp/editor_phase566_save_only_settings.txt";
      Settings : Editor.Settings.Settings_Model;
      Summary  : Settings_Persistence_Summary;
      Update   : Setting_Update_Status;
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_File (Path);
      end if;
      Editor.Settings.Set_Defaults (Settings);
      Set_Setting_Value
        (Settings, Editor.Settings.Setting_Name_Command_Palette_Show_Keybindings,
         "false", Update);
      if Update /= Setting_Update_Ok then
         return False;
      end if;
      Summary := (others => <>);
      Save_User_Config (Settings, Path, Summary);
      if Summary.Status /= Editor.Settings.Settings_Ok
        or else Summary.Supported_Field_Count /= Setting_Count
        or else Summary.Unknown_Field_Count /= 0
        or else Summary.Invalid_Value_Count /= 0
        or else Summary.Forbidden_Field_Count /= 0
        or else Summary.Malformed_Line_Count /= 0
      then
         return False;
      end if;
      declare
         File : Ada.Text_IO.File_Type;
         Text : Unbounded_String := Null_Unbounded_String;
      begin
         Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
         while not Ada.Text_IO.End_Of_File (File) loop
            Append (Text, Ada.Text_IO.Get_Line (File));
            Append (Text, ASCII.LF);
         end loop;
         Ada.Text_IO.Close (File);
         declare
            Domain : Domain_Separation_Audit;
         begin
            Audit_Domain_Separation_Text (To_String (Text), Domain);
            return Domain.Forbidden_Field_Count = 0;
         end;
      end;
   exception
      when others =>
         return False;
   end Assert_Settings_Save_Writes_Global_Preferences_Only;

   function Assert_Settings_Load_Does_Not_Cross_Domains return Boolean is
      Path     : constant String := "/tmp/editor_phase566_load_cross_domain.txt";
      File     : Ada.Text_IO.File_Type;
      Settings : Editor.Settings.Settings_Model;
      Summary  : Settings_Persistence_Summary;
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_File (Path);
      end if;
      Ada.Text_IO.Create (File, Ada.Text_IO.Out_File, Path);
      Ada.Text_IO.Put_Line (File, "editor-settings-version=1");
      Ada.Text_IO.Put_Line (File, "[command-palette]");
      Ada.Text_IO.Put_Line (File, "show-keybindings=false");
      Ada.Text_IO.Put_Line (File, "[workspace]");
      Ada.Text_IO.Put_Line (File, "open-file=src/main.adb");
      Ada.Text_IO.Put_Line (File, "[keybindings]");
      Ada.Text_IO.Put_Line (File, "chord=Ctrl+S");
      Ada.Text_IO.Close (File);

      Load_User_Config (Path, Settings, Summary);
      return Summary.Status = Editor.Settings.Settings_Partial_Load
        and then Summary.Forbidden_Field_Count >= 2
        and then not Editor.Settings.Command_Palette_Show_Keybindings (Settings);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         return False;
   end Assert_Settings_Load_Does_Not_Cross_Domains;

   function File_Audit_Summary (Result : Settings_File_Audit) return String is
   begin
      if Result.Load_Status = Editor.Settings.Settings_Ok
        and then Result.Unknown_Field_Count = 0
        and then Result.Invalid_Value_Count = 0
        and then Result.Forbidden_Domain_Count = 0
        and then Result.Malformed_Line_Count = 0
      then
         return "Settings audit ok: " & Count_Image (Result.Supported_Field_Count) & " supported fields.";
      else
         return "Settings audit: "
           & Count_Image (Result.Unknown_Field_Count) & " unknown, "
           & Count_Image (Result.Invalid_Value_Count) & " invalid, "
           & Count_Image (Result.Forbidden_Domain_Count) & " forbidden-domain, "
           & Count_Image (Result.Malformed_Line_Count) & " malformed.";
      end if;
   end File_Audit_Summary;

   function Domain_Audit_Summary (Result : Domain_Separation_Audit) return String is
   begin
      if Result.Forbidden_Field_Count = 0 then
         return "Settings domain separation ok.";
      else
         return "Settings domain separation warning: " & Count_Image (Result.Forbidden_Field_Count) & " forbidden field groups.";
      end if;
   end Domain_Audit_Summary;


   function Build_Surface_Snapshot
     (Settings : Editor.Settings.Settings_Model;
      UI       : Settings_Editor_State) return Settings_Surface_Snapshot
   is
      Result : Settings_Surface_Snapshot;
      Domain : Domain_Separation_Audit;
      Query  : constant String := To_String (UI.Query);
   begin
      Result.Visible := UI.Visible;
      Result.Focused := UI.Focused;
      Result.Pending_Reset_All := UI.Pending_Reset_All;
      if UI.Pending_Reset_All then
         Result.Confirmation_Message := To_Unbounded_String
           ("Confirm reset all settings to defaults. Keybindings, workspace, recent projects, and buffers will not be changed.");
      end if;
      Result.Row_Count := Setting_Count;
      Result.Audit_Summary := To_Unbounded_String
        ("Settings surface: " & Count_Image (Setting_Count) & " supported global preferences.");
      Audit_Domain_Separation_Text
        ("theme=" & Editor.Settings.Theme_Id (Settings) & ASCII.LF &
         "line-numbers=" & Editor.Settings.Line_Number_Mode_Name (Settings) & ASCII.LF &
         "cursor-style=" & Editor.Settings.Cursor_Style_Name (Settings) & ASCII.LF &
         "format-on-save=" & Bool_Image (Editor.Settings.Format_On_Save (Settings)) & ASCII.LF &
         "show-keybindings=" & Bool_Image (Editor.Settings.Command_Palette_Show_Keybindings (Settings)),
         Domain);
      Result.Domain_Summary := To_Unbounded_String (Domain_Audit_Summary (Domain));

      for I in 1 .. Setting_Count loop
         declare
            Row : Setting_Row := Row_At (Settings, I);
         begin
            Row.Selected := I = UI.Selected_Index;
            if Row.Modified then
               Result.Modified_Count := Result.Modified_Count + 1;
            end if;
            if not Row.Valid then
               Result.Invalid_Count := Result.Invalid_Count + 1;
            end if;
            if Matches_Search (Row, Query)
              and then Matches_Filter (Row, UI.Filter)
              and then Result.Display_Row_Count < Max_Settings_Surface_Rows
            then
               Result.Display_Row_Count := Result.Display_Row_Count + 1;
               Result.Display_Rows (Result.Display_Row_Count) := Row;
            end if;
         end;
      end loop;
      return Result;
   end Build_Surface_Snapshot;

   function Build_Surface_Snapshot
     (Settings : Editor.Settings.Settings_Model) return Settings_Surface_Snapshot
   is
      UI : Settings_Editor_State;
   begin
      UI.Visible := True;
      UI.Focused := False;
      UI.Selected_Index := (if Setting_Count > 0 then 1 else 0);
      return Build_Surface_Snapshot (Settings, UI);
   end Build_Surface_Snapshot;

   function Build_Current_Surface_Snapshot
     (Settings : Editor.Settings.Settings_Model) return Settings_Surface_Snapshot
   is
   begin
      return Build_Surface_Snapshot (Settings, Current_UI);
   end Build_Current_Surface_Snapshot;




   function Conflicts_With_Pending_Reset
     (Action : Settings_Command_Action) return Boolean
   is
   begin
      case Action is
         when Settings_Action_Toggle_Selected
            | Settings_Action_Cycle_Selected
            | Settings_Action_Set_Selected_Value
            | Settings_Action_Reset_Selected
            | Settings_Action_Reset_All
            | Settings_Action_Save
            | Settings_Action_Load =>
            return True;
         when others =>
            return False;
      end case;
   end Conflicts_With_Pending_Reset;

   function Availability_Message
     (Availability : Settings_Command_Availability) return String
   is
   begin
      if Availability.Available then
         return "Available.";
      elsif To_String (Availability.Reason)'Length = 0 then
         return "Command unavailable.";
      else
         return To_String (Availability.Reason);
      end if;
   end Availability_Message;

   function Availability_For
     (Action   : Settings_Command_Action;
      Settings : Editor.Settings.Settings_Model;
      UI       : Settings_Editor_State;
      Value    : String := "") return Settings_Command_Availability
   is
      Result : Settings_Command_Availability := (Available => True, Reason => Null_Unbounded_String);
      Key    : constant String := Selected_Key (UI);
      Status : Setting_Update_Status;
      Scratch : Editor.Settings.Settings_Model := Settings;
   begin
      if UI.Pending_Reset_All and then Conflicts_With_Pending_Reset (Action) then
         return
           (Available => False,
            Reason    => To_Unbounded_String
              ("Command unavailable while confirmation is pending."));
      end if;

      case Action is
         when Settings_Action_Show
            | Settings_Action_Focus
            | Settings_Action_Save
            | Settings_Action_Load
            | Settings_Action_Show_Audit =>
            return Result;

         when Settings_Action_Toggle_Selected =>
            if Key'Length = 0 then
               return (Available => False, Reason => To_Unbounded_String ("No setting selected."));
            end if;
            declare
               Row : constant Setting_Row := Row_At (Settings, UI.Selected_Index);
            begin
               if not Row.Editable then
                  return (Available => False, Reason => To_Unbounded_String ("Selected setting is not editable."));
               elsif not Row.Toggleable then
                  return (Available => False, Reason => To_Unbounded_String ("Selected setting is not toggleable."));
               end if;
            end;
            return Result;

         when Settings_Action_Cycle_Selected =>
            if Key'Length = 0 then
               return (Available => False, Reason => To_Unbounded_String ("No setting selected."));
            end if;
            return Result;

         when Settings_Action_Set_Selected_Value =>
            if Key'Length = 0 then
               return (Available => False, Reason => To_Unbounded_String ("No setting selected."));
            end if;
            Scratch := Settings;
            Set_Setting_Value (Scratch, Key, Value, Status);
            if Status /= Setting_Update_Ok then
               return (Available => False, Reason => To_Unbounded_String (Update_Status_Label (Status)));
            end if;
            return Result;

         when Settings_Action_Reset_Selected =>
            if Key'Length = 0 then
               return (Available => False, Reason => To_Unbounded_String ("No setting selected."));
            end if;
            declare
               Row : constant Setting_Row := Row_At (Settings, UI.Selected_Index);
            begin
               if not Row.Editable then
                  return (Available => False, Reason => To_Unbounded_String ("Selected setting is not editable."));
               elsif not Row.Modified then
                  return (Available => False, Reason => To_Unbounded_String ("Selected setting is already default."));
               end if;
            end;
            return Result;

         when Settings_Action_Reset_All =>
            declare
               Snapshot : constant Settings_Surface_Snapshot := Build_Surface_Snapshot (Settings, UI);
            begin
               if Snapshot.Modified_Count = 0 then
                  return (Available => False, Reason => To_Unbounded_String ("Selected setting is already default."));
               end if;
            end;
            return Result;

         when Settings_Action_Confirm_Reset_All =>
            if not UI.Pending_Reset_All then
               return (Available => False, Reason => To_Unbounded_String ("No pending settings reset confirmation."));
            end if;
            return Result;

         when Settings_Action_Cancel_Reset_All =>
            if not UI.Pending_Reset_All then
               return (Available => False, Reason => To_Unbounded_String ("No pending settings reset confirmation."));
            end if;
            return Result;
      end case;
   end Availability_For;

   procedure Execute_Settings_Surface_Command
     (Action   : Settings_Command_Action;
      Settings : in out Editor.Settings.Settings_Model;
      UI       : in out Settings_Editor_State;
      Status   : out Setting_Update_Status;
      Value    : String := "")
   is
      Availability : constant Settings_Command_Availability :=
        Availability_For (Action, Settings, UI, Value);
   begin
      if not Availability.Available then
         if UI.Pending_Reset_All and then Conflicts_With_Pending_Reset (Action) then
            Status := Setting_Update_Blocked_By_Confirmation;
            return;
         end if;

         case Action is
            when Settings_Action_Toggle_Selected =>
               if Selected_Key (UI)'Length = 0 then
                  Status := Setting_Update_No_Selection;
               else
                  Status := Setting_Update_Not_Toggleable;
               end if;
            when Settings_Action_Set_Selected_Value =>
               if Selected_Key (UI)'Length = 0 then
                  Status := Setting_Update_No_Selection;
               else
                  Status := Setting_Update_Invalid_Value;
               end if;
            when Settings_Action_Reset_Selected =>
               if Selected_Key (UI)'Length = 0 then
                  Status := Setting_Update_No_Selection;
               else
                  Status := Setting_Update_Already_Default;
               end if;
            when Settings_Action_Reset_All =>
               Status := Setting_Update_Already_Default;
            when Settings_Action_Confirm_Reset_All | Settings_Action_Cancel_Reset_All =>
               Status := Setting_Update_No_Selection;
            when others => Status := Setting_Update_No_Selection;
         end case;
         return;
      end if;

      case Action is
         when Settings_Action_Show =>
            Show_Settings (UI);
            Status := Setting_Update_Ok;
         when Settings_Action_Focus =>
            Focus_Settings (UI);
            Status := Setting_Update_Ok;
         when Settings_Action_Toggle_Selected =>
            Toggle_Selected_Setting (Settings, UI, Status);
         when Settings_Action_Cycle_Selected =>
            Cycle_Selected_Setting (Settings, UI, Status);
         when Settings_Action_Set_Selected_Value =>
            Set_Selected_Setting_Value (Settings, UI, Value, Status);
         when Settings_Action_Reset_Selected =>
            Reset_Selected_Setting (Settings, UI, Status);
         when Settings_Action_Reset_All =>
            Request_Reset_All_Settings (UI);
            Status := Setting_Update_Confirmation_Required;
         when Settings_Action_Confirm_Reset_All =>
            Confirm_Reset_All_Settings (Settings, UI, Status);
         when Settings_Action_Cancel_Reset_All =>
            Cancel_Reset_All_Settings (UI, Status);
         when Settings_Action_Save
            | Settings_Action_Load
            | Settings_Action_Show_Audit =>
            --  Persistence and audit display commands are executed by the
            --  canonical Executor using Save_User_Config/Load_User_Config and
            --  the audit summary helpers.  This surface bridge deliberately
            --  carries no paths, key/value payloads, command payloads, or
            --  cross-domain state.
            Status := Setting_Update_Ok;
      end case;
   end Execute_Settings_Surface_Command;

   procedure Execute_Settings_Surface_Command
     (Action   : Settings_Command_Action;
      Settings : in out Editor.Settings.Settings_Model;
      Status   : out Setting_Update_Status;
      Value    : String := "")
   is
   begin
      Execute_Settings_Surface_Command
        (Action   => Action,
         Settings => Settings,
         UI       => Current_UI,
         Status   => Status,
         Value    => Value);
   end Execute_Settings_Surface_Command;

   function Assert_Settings_Command_Availability_Is_Side_Effect_Free return Boolean is
      Settings : Editor.Settings.Settings_Model;
      UI       : Settings_Editor_State;
      Before   : Settings_Surface_Snapshot;
      After    : Settings_Surface_Snapshot;
      Avail    : Settings_Command_Availability;
   begin
      Editor.Settings.Set_Defaults (Settings);
      Focus_Settings (UI);
      UI.Selected_Index := Index_For_Key (Editor.Settings.Setting_Name_Command_Palette_Show_Keybindings);
      Before := Build_Surface_Snapshot (Settings, UI);
      Avail := Availability_For (Settings_Action_Toggle_Selected, Settings, UI, "");
      if not Avail.Available then
         return False;
      end if;
      Avail := Availability_For
        (Settings_Action_Set_Selected_Value, Settings, UI, "false");
      if not Avail.Available then
         return False;
      end if;
      After := Build_Surface_Snapshot (Settings, UI);
      return Before.Modified_Count = After.Modified_Count
        and then Before.Display_Row_Count = After.Display_Row_Count
        and then Editor.Settings.Command_Palette_Show_Keybindings (Settings);
   end Assert_Settings_Command_Availability_Is_Side_Effect_Free;

   function Assert_Reset_All_Settings_Does_Not_Cross_Domains return Boolean is
      Settings : Editor.Settings.Settings_Model;
      Status   : Setting_Update_Status;
      Domain   : Domain_Separation_Audit;
   begin
      Editor.Settings.Set_Defaults (Settings);
      Set_Setting_Value
        (Settings,
         Editor.Settings.Setting_Name_Command_Palette_Show_Keybindings,
         "false",
         Status);
      if Status /= Setting_Update_Ok then
         return False;
      end if;
      Reset_All_Settings (Settings);
      if not Editor.Settings.Command_Palette_Show_Keybindings (Settings) then
         return False;
      end if;
      Audit_Domain_Separation_Text
        ("theme=" & Editor.Settings.Theme_Id (Settings) & ASCII.LF &
         "show-keybindings=" & Bool_Image (Editor.Settings.Command_Palette_Show_Keybindings (Settings)),
         Domain);
      return Domain.Forbidden_Field_Count = 0;
   end Assert_Reset_All_Settings_Does_Not_Cross_Domains;


   function Assert_Reset_All_Settings_Command_Requires_Confirmation return Boolean is
      Settings : Editor.Settings.Settings_Model;
      UI       : Settings_Editor_State;
      Status   : Setting_Update_Status;
   begin
      Editor.Settings.Set_Defaults (Settings);
      Set_Setting_Value
        (Settings,
         Editor.Settings.Setting_Name_Command_Palette_Show_Keybindings,
         "false",
         Status);
      if Status /= Setting_Update_Ok then
         return False;
      end if;
      Execute_Settings_Surface_Command
        (Settings_Action_Reset_All, Settings, UI, Status);
      if Status /= Setting_Update_Confirmation_Required
        or else not UI.Pending_Reset_All
        or else Editor.Settings.Command_Palette_Show_Keybindings (Settings)
      then
         return False;
      end if;
      Execute_Settings_Surface_Command
        (Settings_Action_Toggle_Selected, Settings, UI, Status);
      if Status /= Setting_Update_Blocked_By_Confirmation
        or else Editor.Settings.Command_Palette_Show_Keybindings (Settings)
      then
         return False;
      end if;
      Execute_Settings_Surface_Command
        (Settings_Action_Confirm_Reset_All, Settings, UI, Status);
      return Status = Setting_Update_Ok
        and then not UI.Pending_Reset_All
        and then Editor.Settings.Command_Palette_Show_Keybindings (Settings);
   end Assert_Reset_All_Settings_Command_Requires_Confirmation;



   function Catalog_Row
     (Stable_Name           : String;
      Display_Name          : String;
      Availability_Hint     : String;
      Action                : Settings_Command_Action;
      Has_Executor_Command  : Boolean;
      Surface_Only          : Boolean;
      Requires_Selection    : Boolean;
      Requires_Value        : Boolean;
      Requires_Confirmation : Boolean) return Settings_Command_Catalog_Row
   is
   begin
      return
        (Stable_Name       => To_Unbounded_String (Stable_Name),
         Display_Name      => To_Unbounded_String (Display_Name),
         Availability_Hint => To_Unbounded_String (Availability_Hint),
         Action            => Action,
         Has_Executor_Command => Has_Executor_Command,
         Surface_Only      => Surface_Only,
         Requires_Selection => Requires_Selection,
         Requires_Value    => Requires_Value,
         Requires_Confirmation => Requires_Confirmation,
         No_Payload        => True,
         Configuration     => True);
   end Catalog_Row;

   function Build_Settings_Command_Catalog
     return Settings_Command_Catalog_Snapshot
   is
      Result : Settings_Command_Catalog_Snapshot;

      procedure Append (Row : Settings_Command_Catalog_Row) is
      begin
         Result.Row_Count := Result.Row_Count + 1;
         if Result.Display_Count < Max_Settings_Command_Catalog_Rows then
            Result.Display_Count := Result.Display_Count + 1;
            Result.Rows (Result.Display_Count) := Row;
         end if;
         if Row.Has_Executor_Command then
            Result.Executor_Command_Count := Result.Executor_Command_Count + 1;
         end if;
         if Row.Surface_Only then
            Result.Surface_Command_Count := Result.Surface_Command_Count + 1;
         end if;
         if not Row.No_Payload then
            Result.Payload_Command_Count := Result.Payload_Command_Count + 1;
         end if;
      end Append;
   begin
      --  This catalog is the settings command UX contract.  Rows backed by
      --  existing Editor.Commands descriptors route through the canonical
      --  Executor.  Surface-only rows are intentionally typed bridge actions:
      --  they carry no key/value payload from keybindings or Command Palette
      --  and operate only on the transient selected settings row.
      Append (Catalog_Row
        (Editor.Commands.Stable_Command_Name (Editor.Commands.Command_Save_Settings),
         "Save Settings",
         "Saves supported global preferences only.",
         Settings_Action_Save,
         True, False, False, False, False));
      Append (Catalog_Row
        (Editor.Commands.Stable_Command_Name (Editor.Commands.Command_Reload_Settings),
         "Load Settings",
         "Loads supported global preferences with validation.",
         Settings_Action_Load,
         True, False, False, False, False));
      Append (Catalog_Row
        (Editor.Commands.Stable_Command_Name (Editor.Commands.Command_Reset_Settings_To_Defaults),
         "Reset All Settings",
         "Requests confirmation before resetting global preferences to defaults.",
         Settings_Action_Reset_All,
         True, False, False, False, True));
      Append (Catalog_Row
        ("settings.show",
         "Show Settings",
         "Shows the transient settings list surface.",
         Settings_Action_Show,
         False, True, False, False, False));
      Append (Catalog_Row
        ("settings.focus",
         "Focus Settings",
         "Focuses the transient settings list surface.",
         Settings_Action_Focus,
         False, True, False, False, False));
      Append (Catalog_Row
        ("settings.toggle-selected",
         "Toggle Selected Setting",
         "Requires a selected boolean setting.",
         Settings_Action_Toggle_Selected,
         False, True, True, False, False));
      Append (Catalog_Row
        ("settings.cycle-selected",
         "Cycle Selected Setting",
         "Requires a selected enum setting.",
         Settings_Action_Cycle_Selected,
         False, True, True, False, False));
      Append (Catalog_Row
        ("settings.set-selected-value",
         "Set Selected Setting Value",
         "Accepts only a typed value supplied by the settings surface, never by keybinding payload.",
         Settings_Action_Set_Selected_Value,
         False, True, True, True, False));
      Append (Catalog_Row
        ("settings.reset-selected",
         "Reset Selected Setting",
         "Requires a selected setting modified from its default.",
         Settings_Action_Reset_Selected,
         False, True, True, False, False));
      Append (Catalog_Row
        ("settings.reset-all.confirm",
         "Confirm Reset All Settings",
         "Confirms a pending transient settings reset-all request.",
         Settings_Action_Confirm_Reset_All,
         False, True, False, False, True));
      Append (Catalog_Row
        ("settings.reset-all.cancel",
         "Cancel Reset All Settings",
         "Cancels a pending transient settings reset-all request.",
         Settings_Action_Cancel_Reset_All,
         False, True, False, False, True));
      Append (Catalog_Row
        ("configuration.review",
         "Review Configuration",
         "Shows the bounded transient configuration review surface.",
         Settings_Action_Show_Audit,
         False, True, False, False, False));

      return Result;
   end Build_Settings_Command_Catalog;

   function Build_Current_Settings_Command_Catalog
     return Settings_Command_Catalog_Snapshot
   is
   begin
      return Build_Settings_Command_Catalog;
   end Build_Current_Settings_Command_Catalog;

   function Build_Current_Configuration_Audit_Surface
     (Settings : Editor.Settings.Settings_Model)
      return Configuration_Audit_Surface_Snapshot
   is
      File_Audit    : Settings_File_Audit;
      Domain_Audit  : Domain_Separation_Audit;
      Command_Audit : Settings_Command_Surface_Audit;
   begin
      File_Audit.Load_Status := Editor.Settings.Settings_Ok;
      File_Audit.Supported_Field_Count := Setting_Count;
      Audit_Domain_Separation_Text
        ("theme=" & Editor.Settings.Theme_Id (Settings) & ASCII.LF &
         "line-numbers=" & Editor.Settings.Line_Number_Mode_Name (Settings) & ASCII.LF &
         "cursor-style=" & Editor.Settings.Cursor_Style_Name (Settings) & ASCII.LF &
         "format-on-save=" & Bool_Image (Editor.Settings.Format_On_Save (Settings)) & ASCII.LF &
         "show-keybindings=" &
           Bool_Image (Editor.Settings.Command_Palette_Show_Keybindings (Settings)),
         Domain_Audit);
      Audit_Settings_Command_Surface (Command_Audit);
      return Build_Configuration_Audit_Surface
        (File_Audit    => File_Audit,
         Domain_Audit  => Domain_Audit,
         Command_Audit => Command_Audit);
   end Build_Current_Configuration_Audit_Surface;



   function Route_Row
     (Stable_Name            : String;
      Action                 : Settings_Command_Action;
      Executor_Command       : Editor.Commands.Command_Id;
      Executor_Backend       : Boolean;
      Typed_Surface          : Boolean;
      Palette_Addressable    : Boolean;
      Keybinding_Addressable : Boolean;
      Requires_Value         : Boolean) return Settings_Command_Route_Row
   is
   begin
      return
        (Stable_Name        => To_Unbounded_String (Stable_Name),
         Action             => Action,
         Executor_Command   => Executor_Command,
         Executor_Backend   => Executor_Backend,
         Typed_Surface      => Typed_Surface,
         Palette_Addressable => Palette_Addressable,
         Keybinding_Addressable => Keybinding_Addressable,
         Requires_Value     => Requires_Value,
         No_Payload         => True);
   end Route_Row;

   function Build_Settings_Command_Routes
     return Settings_Command_Route_Snapshot
   is
      Result : Settings_Command_Route_Snapshot;

      procedure Append (Row : Settings_Command_Route_Row) is
      begin
         Result.Row_Count := Result.Row_Count + 1;
         if Result.Row_Count <= Max_Settings_Command_Route_Rows then
            Result.Rows (Result.Row_Count) := Row;
         end if;
         if Row.Executor_Backend then
            Result.Executor_Route_Count := Result.Executor_Route_Count + 1;
         end if;
         if Row.Typed_Surface then
            Result.Typed_Surface_Count := Result.Typed_Surface_Count + 1;
         end if;
         if Row.Palette_Addressable then
            Result.Palette_Route_Count := Result.Palette_Route_Count + 1;
         end if;
         if Row.Keybinding_Addressable then
            Result.Keybinding_Route_Count := Result.Keybinding_Route_Count + 1;
         end if;
         if not Row.No_Payload then
            Result.Payload_Route_Count := Result.Payload_Route_Count + 1;
         end if;
      end Append;
   begin
      Append (Route_Row
        (Editor.Commands.Stable_Command_Name (Editor.Commands.Command_Save_Settings),
         Settings_Action_Save,
         Editor.Commands.Command_Save_Settings,
         True, False, True, True, False));
      Append (Route_Row
        (Editor.Commands.Stable_Command_Name (Editor.Commands.Command_Reload_Settings),
         Settings_Action_Load,
         Editor.Commands.Command_Reload_Settings,
         True, False, True, True, False));
      Append (Route_Row
        (Editor.Commands.Stable_Command_Name (Editor.Commands.Command_Reset_Settings_To_Defaults),
         Settings_Action_Reset_All,
         Editor.Commands.Command_Reset_Settings_To_Defaults,
         True, False, True, True, False));

      Append (Route_Row
        ("settings.show", Settings_Action_Show,
         Editor.Commands.No_Command, False, True, False, False, False));
      Append (Route_Row
        ("settings.focus", Settings_Action_Focus,
         Editor.Commands.No_Command, False, True, False, False, False));
      Append (Route_Row
        ("settings.toggle-selected", Settings_Action_Toggle_Selected,
         Editor.Commands.No_Command, False, True, False, False, False));
      Append (Route_Row
        ("settings.cycle-selected", Settings_Action_Cycle_Selected,
         Editor.Commands.No_Command, False, True, False, False, False));
      Append (Route_Row
        ("settings.set-selected-value", Settings_Action_Set_Selected_Value,
         Editor.Commands.No_Command, False, True, False, False, True));
      Append (Route_Row
        ("settings.reset-selected", Settings_Action_Reset_Selected,
         Editor.Commands.No_Command, False, True, False, False, False));
      Append (Route_Row
        ("settings.reset-all.confirm", Settings_Action_Confirm_Reset_All,
         Editor.Commands.No_Command, False, True, False, False, False));
      Append (Route_Row
        ("settings.reset-all.cancel", Settings_Action_Cancel_Reset_All,
         Editor.Commands.No_Command, False, True, False, False, False));
      Append (Route_Row
        ("configuration.show-audit", Settings_Action_Show_Audit,
         Editor.Commands.No_Command, False, True, False, False, False));

      return Result;
   end Build_Settings_Command_Routes;

   function Assert_Settings_Command_Routes_Are_Executor_Or_Typed_Surface_Only
     return Boolean
   is
      Routes : constant Settings_Command_Route_Snapshot :=
        Build_Settings_Command_Routes;
      Seen_Save   : Boolean := False;
      Seen_Set    : Boolean := False;
      Seen_Audit  : Boolean := False;
   begin
      if Routes.Row_Count /= 12
        or else Routes.Executor_Route_Count /= 3
        or else Routes.Typed_Surface_Count /= 9
        or else Routes.Palette_Route_Count /= 3
        or else Routes.Keybinding_Route_Count /= 3
        or else Routes.Payload_Route_Count /= 0
      then
         return False;
      end if;

      for I in 1 .. Routes.Row_Count loop
         declare
            Row : constant Settings_Command_Route_Row := Routes.Rows (I);
         begin
            if To_String (Row.Stable_Name)'Length = 0
              or else not Row.No_Payload
              or else (Row.Executor_Backend = Row.Typed_Surface)
            then
               return False;
            end if;

            if Row.Executor_Backend then
               if Row.Executor_Command = Editor.Commands.No_Command
                 or else not Row.Palette_Addressable
                 or else not Row.Keybinding_Addressable
               then
                  return False;
               end if;
            else
               if Row.Executor_Command /= Editor.Commands.No_Command
                 or else Row.Palette_Addressable
                 or else Row.Keybinding_Addressable
               then
                  return False;
               end if;
            end if;

            if Row.Action = Settings_Action_Save then
               Seen_Save := Row.Executor_Backend;
            elsif Row.Action = Settings_Action_Set_Selected_Value then
               Seen_Set := Row.Typed_Surface and then Row.Requires_Value;
            elsif Row.Action = Settings_Action_Show_Audit then
               Seen_Audit := Row.Typed_Surface and then not Row.Requires_Value;
            end if;
         end;
      end loop;

      return Seen_Save and then Seen_Set and then Seen_Audit;
   end Assert_Settings_Command_Routes_Are_Executor_Or_Typed_Surface_Only;


   function Assert_Settings_Command_Catalog_Is_Bounded_And_Payload_Free
     return Boolean
   is
      Catalog : constant Settings_Command_Catalog_Snapshot :=
        Build_Settings_Command_Catalog;
      Seen_Selected_Action : Boolean := False;
      Seen_Confirmation    : Boolean := False;
   begin
      if Catalog.Row_Count /= 12
        or else Catalog.Display_Count > Max_Settings_Command_Catalog_Rows
        or else Catalog.Executor_Command_Count /= 3
        or else Catalog.Surface_Command_Count /= 9
        or else Catalog.Payload_Command_Count /= 0
      then
         return False;
      end if;

      for I in 1 .. Catalog.Display_Count loop
         declare
            Row : constant Settings_Command_Catalog_Row := Catalog.Rows (I);
         begin
            if To_String (Row.Stable_Name)'Length = 0
              or else To_String (Row.Display_Name)'Length = 0
              or else To_String (Row.Availability_Hint)'Length = 0
              or else not Row.No_Payload
              or else not Row.Configuration
            then
               return False;
            end if;
            if Row.Requires_Selection then
               Seen_Selected_Action := True;
            end if;
            if Row.Requires_Confirmation then
               Seen_Confirmation := True;
            end if;
         end;
      end loop;

      return Seen_Selected_Action and then Seen_Confirmation;
   end Assert_Settings_Command_Catalog_Is_Bounded_And_Payload_Free;


   function Assert_Settings_Surface_Render_Is_Observational return Boolean is
      Settings : Editor.Settings.Settings_Model;
      Before   : Settings_Surface_Snapshot;
      After    : Settings_Surface_Snapshot;
      Status   : Setting_Update_Status;
   begin
      Editor.Settings.Set_Defaults (Settings);
      Before := Build_Surface_Snapshot (Settings);
      After := Build_Surface_Snapshot (Settings);
      if Before.Row_Count /= After.Row_Count
        or else Before.Display_Row_Count /= After.Display_Row_Count
        or else Before.Modified_Count /= After.Modified_Count
        or else Before.Invalid_Count /= After.Invalid_Count
      then
         return False;
      end if;
      Toggle_Setting
        (Settings,
         Editor.Settings.Setting_Name_Command_Palette_Show_Keybindings,
         Status);
      if Status /= Setting_Update_Ok then
         return False;
      end if;
      After := Build_Surface_Snapshot (Settings);
      return After.Modified_Count = Before.Modified_Count + 1
        and then Editor.Settings.Command_Palette_Show_Keybindings (Settings) = False;
   end Assert_Settings_Surface_Render_Is_Observational;

   function Assert_Settings_Editor_State_Not_Persisted return Boolean is
      Audit : Domain_Separation_Audit;
   begin
      Audit_Domain_Separation_Text
        ("settings-query=theme" & ASCII.LF &
         "settings-selection=theme" & ASCII.LF &
         "settings-filter=modified" & ASCII.LF &
         "configuration-audit-result=ok" & ASCII.LF &
         "pending-settings-reset-confirmation=true",
         Audit);
      return Audit.Settings_Contains_Runtime
        and then Audit.Forbidden_Field_Count = 1;
   end Assert_Settings_Editor_State_Not_Persisted;


   function Is_Settings_Management_Command
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      return Id in Editor.Commands.Command_Save_Settings
                 | Editor.Commands.Command_Reload_Settings
                 | Editor.Commands.Command_Reset_Settings_To_Defaults;
   end Is_Settings_Management_Command;

   procedure Audit_Settings_Command_Surface
     (Result : out Settings_Command_Surface_Audit)
   is
   begin
      Result := (others => <>);
      for Id in Editor.Commands.Command_Id loop
         if Is_Settings_Management_Command (Id) then
            Result.Settings_Command_Count := Result.Settings_Command_Count + 1;
            declare
               D : constant Editor.Commands.Command_Descriptor := Editor.Commands.Descriptor (Id);
            begin
               if D.Id /= Id or else To_String (D.Name)'Length = 0
                 or else To_String (D.Description)'Length = 0
               then
                  Result.Missing_Descriptor_Count := Result.Missing_Descriptor_Count + 1;
               end if;
               if D.Category /= Editor.Commands.Settings_Category then
                  Result.Wrong_Category_Count := Result.Wrong_Category_Count + 1;
               end if;
               if not Editor.Commands.Is_Configuration_Command (Id) then
                  Result.Non_Configuration_Count := Result.Non_Configuration_Count + 1;
               end if;
               if D.Requires_Explicit_Target or else D.Target_Prompt_Capable
                 or else To_String (D.Target_Prompt_Label)'Length /= 0
               then
                  Result.Payload_Capable_Count := Result.Payload_Capable_Count + 1;
               end if;
               if not Editor.Commands.Visible_In_Command_Palette (Id) then
                  Result.Hidden_Command_Count := Result.Hidden_Command_Count + 1;
               end if;
            end;
         end if;
      end loop;
   end Audit_Settings_Command_Surface;

   function Command_Surface_Audit_Summary
     (Result : Settings_Command_Surface_Audit) return String
   is
   begin
      if Result.Settings_Command_Count = 3
        and then Result.Missing_Descriptor_Count = 0
        and then Result.Wrong_Category_Count = 0
        and then Result.Non_Configuration_Count = 0
        and then Result.Payload_Capable_Count = 0
        and then Result.Hidden_Command_Count = 0
      then
         return "Settings command surface ok: save/load/reset commands are visible, described, configuration-classified, and payload-free.";
      else
         return "Settings command surface warning: "
           & Count_Image (Result.Missing_Descriptor_Count) & " descriptor, "
           & Count_Image (Result.Wrong_Category_Count) & " category, "
           & Count_Image (Result.Non_Configuration_Count) & " configuration, "
           & Count_Image (Result.Payload_Capable_Count) & " payload, "
           & Count_Image (Result.Hidden_Command_Count) & " visibility.";
      end if;
   end Command_Surface_Audit_Summary;



   procedure Append_Audit_Row
     (Snapshot : in out Configuration_Audit_Surface_Snapshot;
      Category : String;
      Message  : String;
      Warning  : Boolean)
   is
   begin
      Snapshot.Row_Count := Snapshot.Row_Count + 1;
      if Warning then
         Snapshot.Warning_Count := Snapshot.Warning_Count + 1;
      end if;
      if Snapshot.Display_Count < Max_Configuration_Audit_Rows then
         Snapshot.Display_Count := Snapshot.Display_Count + 1;
         Snapshot.Rows (Snapshot.Display_Count) :=
           (Category => To_Unbounded_String (Category),
            Message  => To_Unbounded_String (Message),
            Warning  => Warning);
      else
         Snapshot.Bounded := True;
      end if;
   end Append_Audit_Row;

   function Build_Configuration_Audit_Surface
     (File_Audit    : Settings_File_Audit;
      Domain_Audit  : Domain_Separation_Audit;
      Command_Audit : Settings_Command_Surface_Audit)
      return Configuration_Audit_Surface_Snapshot
   is
      Result : Configuration_Audit_Surface_Snapshot;
   begin
      Append_Audit_Row
        (Result, "settings-schema", File_Audit_Summary (File_Audit),
         File_Audit.Load_Status /= Editor.Settings.Settings_Ok
           or else File_Audit.Unknown_Field_Count /= 0
           or else File_Audit.Invalid_Value_Count /= 0
           or else File_Audit.Forbidden_Domain_Count /= 0
           or else File_Audit.Malformed_Line_Count /= 0);

      Append_Audit_Row
        (Result, "domain-separation", Domain_Audit_Summary (Domain_Audit),
         Domain_Audit.Forbidden_Field_Count /= 0);

      Append_Audit_Row
        (Result, "command-surface", Command_Surface_Audit_Summary (Command_Audit),
         Command_Audit.Missing_Descriptor_Count /= 0
           or else Command_Audit.Wrong_Category_Count /= 0
           or else Command_Audit.Non_Configuration_Count /= 0
           or else Command_Audit.Payload_Capable_Count /= 0
           or else Command_Audit.Hidden_Command_Count /= 0);

      Append_Audit_Row
        (Result, "settings-keybindings", "Settings persistence contains no keybinding maps or command payloads.",
         Domain_Audit.Settings_Contains_Keybindings);
      Append_Audit_Row
        (Result, "settings-workspace", "Settings persistence contains no workspace session state.",
         Domain_Audit.Settings_Contains_Workspace);
      Append_Audit_Row
        (Result, "settings-recent-projects", "Settings persistence contains no recent project entries.",
         Domain_Audit.Settings_Contains_Recent);
      Append_Audit_Row
        (Result, "settings-runtime", "Settings persistence contains no transient UI, audit, focus, pending-confirmation, or result state.",
         Domain_Audit.Settings_Contains_Runtime);

      if Result.Warning_Count = 0 then
         Result.Summary := To_Unbounded_String
           ("Configuration audit ok: settings, keybindings, workspace, recent projects, commands, and transient state are separated.");
      else
         Result.Summary := To_Unbounded_String
           ("Configuration audit warnings: " & Count_Image (Result.Warning_Count)
            & " warning rows across settings configuration domains.");
      end if;
      return Result;
   end Build_Configuration_Audit_Surface;

   function Assert_Configuration_Audit_Surface_Is_Bounded_And_Transient return Boolean is
      File_Audit    : Settings_File_Audit;
      Domain_Audit  : Domain_Separation_Audit;
      Command_Audit : Settings_Command_Surface_Audit;
      Surface       : Configuration_Audit_Surface_Snapshot;
   begin
      File_Audit :=
        (Load_Status            => Editor.Settings.Settings_Ok,
         Supported_Field_Count  => Setting_Count,
         Unknown_Field_Count    => 0,
         Invalid_Value_Count    => 0,
         Forbidden_Domain_Count => 0,
         Malformed_Line_Count   => 0);
      Audit_Domain_Separation_Text
        ("settings-query=theme" & ASCII.LF &
         "configuration-audit-result=stale" & ASCII.LF &
         "pending-settings-reset-confirmation=true",
         Domain_Audit);
      Audit_Settings_Command_Surface (Command_Audit);
      Surface := Build_Configuration_Audit_Surface
        (File_Audit, Domain_Audit, Command_Audit);
      return Surface.Display_Count <= Max_Configuration_Audit_Rows
        and then Surface.Row_Count >= 7
        and then Surface.Warning_Count >= 1
        and then To_String (Surface.Summary)'Length > 0;
   end Assert_Configuration_Audit_Surface_Is_Bounded_And_Transient;

   function Assert_Settings_Command_Surface_Coherent return Boolean is
      Audit : Settings_Command_Surface_Audit;
   begin
      Audit_Settings_Command_Surface (Audit);
      return Audit.Settings_Command_Count = 3
        and then Audit.Missing_Descriptor_Count = 0
        and then Audit.Wrong_Category_Count = 0
        and then Audit.Non_Configuration_Count = 0
        and then Audit.Payload_Capable_Count = 0
        and then Audit.Hidden_Command_Count = 0;
   end Assert_Settings_Command_Surface_Coherent;

   function Assert_Settings_Keybindings_And_Palette_Carry_No_Payloads return Boolean is
   begin
      for Id in Editor.Commands.Command_Id loop
         if Is_Settings_Management_Command (Id) then
            declare
               D : constant Editor.Commands.Command_Descriptor := Editor.Commands.Descriptor (Id);
            begin
               if D.Requires_Explicit_Target
                 or else D.Target_Prompt_Capable
                 or else To_String (D.Target_Prompt_Label)'Length /= 0
                 or else not Editor.Commands.Visible_In_Command_Palette (Id)
               then
                  return False;
               end if;
            end;
         end if;
      end loop;
      return True;
   end Assert_Settings_Keybindings_And_Palette_Carry_No_Payloads;

   function Assert_Settings_Configuration_Management_Coherent return Boolean is
      Settings : Editor.Settings.Settings_Model;
      Status   : Setting_Update_Status;
   begin
      Editor.Settings.Set_Defaults (Settings);
      if Setting_Count /= 10 then
         return False;
      end if;
      if not Assert_Settings_Surface_Render_Is_Observational then
         return False;
      end if;
      if not Assert_Settings_Editor_State_Not_Persisted then
         return False;
      end if;
      if not Assert_Settings_Save_Writes_Global_Preferences_Only then
         return False;
      end if;
      if not Assert_Settings_Load_Does_Not_Cross_Domains then
         return False;
      end if;
      if not Assert_Settings_Command_Surface_Coherent then
         return False;
      end if;
      if not Assert_Settings_Command_Catalog_Is_Bounded_And_Payload_Free then
         return False;
      end if;
      if not Assert_Settings_Command_Routes_Are_Executor_Or_Typed_Surface_Only then
         return False;
      end if;
      if not Assert_Settings_Keybindings_And_Palette_Carry_No_Payloads then
         return False;
      end if;
      if not Assert_Settings_Command_Availability_Is_Side_Effect_Free then
         return False;
      end if;
      if not Assert_Configuration_Audit_Surface_Is_Bounded_And_Transient then
         return False;
      end if;
      if not Assert_Reset_All_Settings_Does_Not_Cross_Domains then
         return False;
      end if;
      if not Assert_Reset_All_Settings_Command_Requires_Confirmation then
         return False;
      end if;
      for I in 1 .. Setting_Count loop
         declare
            Row : constant Setting_Row := Row_At (Settings, I);
         begin
         if To_String (Row.Key)'Length = 0
           or else To_String (Row.Display_Name)'Length = 0
           or else To_String (Row.Default_Value)'Length = 0
           or else To_String (Row.Description)'Length = 0
           or else not Row.Valid
         then
            return False;
         end if;
         end;
      end loop;
      Toggle_Setting (Settings, Editor.Settings.Setting_Name_Command_Palette_Show_Keybindings, Status);
      if Status /= Setting_Update_Ok then
         return False;
      end if;
      Reset_Setting (Settings, Editor.Settings.Setting_Name_Command_Palette_Show_Keybindings, Status);
      if Status /= Setting_Update_Ok then
         return False;
      end if;
      declare
         UI : Settings_Editor_State;
      begin
         Focus_Settings (UI);
         if Selected_Key (UI)'Length = 0 then
            return False;
         end if;
         Cycle_Selected_Setting (Settings, UI, Status);
         if Status /= Setting_Update_Ok then
            return False;
         end if;
      end;
      return True;
   end Assert_Settings_Configuration_Management_Coherent;

end Editor.Settings_Management;
