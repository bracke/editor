with Ada.Characters.Handling;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Strings.Fixed;
with Ada.Text_IO;

package body Editor.Keybinding_Config is

   use type Editor.Commands.Command_Id;
   use type Editor.Keybindings.Binding_Result;
   use type Editor.Keybindings.Key_Code;

   type Diagnostic_Counts is array (Keybinding_Config_Diagnostic_Kind) of Natural;

   Last_Load_Diagnostics : Diagnostic_Counts := (others => 0);

   procedure Reset_Load_Diagnostics is
   begin
      Last_Load_Diagnostics := (others => 0);
   end Reset_Load_Diagnostics;

   procedure Record_Load_Diagnostic
     (Kind   : Keybinding_Config_Diagnostic_Kind;
      Status : in out Keybinding_Config_Status)
   is
   begin
      Last_Load_Diagnostics (Kind) := Last_Load_Diagnostics (Kind) + 1;
      if Status = Keybinding_Config_Ok then
         Status := Keybinding_Config_Partial_Load;
      end if;
   end Record_Load_Diagnostic;

   function Last_Load_Ignored_Count return Natural is
      Count : Natural := 0;
   begin
      for Kind in Keybinding_Config_Diagnostic_Kind loop
         Count := Count + Last_Load_Diagnostics (Kind);
      end loop;
      return Count;
   end Last_Load_Ignored_Count;

   function Last_Load_Diagnostic_Count
     (Kind : Keybinding_Config_Diagnostic_Kind) return Natural
   is
   begin
      return Last_Load_Diagnostics (Kind);
   end Last_Load_Diagnostic_Count;

   function Trimmed (S : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (S, Ada.Strings.Both);
   end Trimmed;

   function Lower (S : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (Trimmed (S));
   end Lower;


   function Status_Label
     (Status : Keybinding_Config_Status) return String
   is
   begin
      case Status is
         when Keybinding_Config_Ok =>
            return "Keybindings loaded.";
         when Keybinding_Config_Not_Found =>
            return "Keybindings file not found.";
         when Keybinding_Config_Invalid_Format =>
            return "Keybindings file has an invalid format.";
         when Keybinding_Config_Unsupported_Version =>
            return "Keybindings file version is not supported.";
         when Keybinding_Config_Read_Error =>
            return "Keybindings file could not be read.";
         when Keybinding_Config_Write_Error =>
            return "Keybindings file could not be written.";
         when Keybinding_Config_Partial_Load =>
            return "Keybindings loaded with ignored invalid entries.";
      end case;
   end Status_Label;

   function Diagnostic_Label
     (Kind : Keybinding_Config_Diagnostic_Kind) return String
   is
   begin
      case Kind is
         when Malformed_Line =>
            return "Keybinding entry is malformed.";
         when Unknown_Section =>
            return "Keybinding section is not supported.";
         when Unknown_Command =>
            return "Unknown command.";
         when Invalid_Command_Name =>
            return "Command is not bindable.";
         when Invalid_Chord =>
            return "Chord is invalid.";
         when Unsupported_Payload =>
            return "Keybinding entry contains unsupported payload.";
         when Duplicate_Command =>
            return "Command has more than one persisted binding.";
         when Duplicate_Chord =>
            return "Chord conflicts with existing binding.";
         when Unsupported_Version =>
            return "Keybindings file version is not supported.";
      end case;
   end Diagnostic_Label;

   function Contains_Unsupported_Payload (Value : String) return Boolean is
      V : constant String := Trimmed (Value);
   begin
      for Ch of V loop
         if Ch = '{' or else Ch = '}' or else Ch = '[' or else Ch = ']'
           or else Ch = ';' or else Ch = ',' or else Ch = ':'
         then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Unsupported_Payload;

   function Keybinding_Value_Has_Unsupported_Payload
     (Value : String) return Boolean
   is
   begin
      return Contains_Unsupported_Payload (Value);
   end Keybinding_Value_Has_Unsupported_Payload;

   function Same_Chord
     (L : Editor.Keybindings.Key_Chord;
      R : Editor.Keybindings.Key_Chord) return Boolean
   is
   begin
      return L.Key = R.Key
        and then L.Modifiers.Ctrl = R.Modifiers.Ctrl
        and then L.Modifiers.Alt = R.Modifiers.Alt
        and then L.Modifiers.Shift = R.Modifiers.Shift
        and then L.Modifiers.Meta = R.Modifiers.Meta;
   end Same_Chord;


   function Chord
     (Key   : Editor.Keybindings.Key_Code;
      Ctrl  : Boolean := False;
      Shift : Boolean := False;
      Alt   : Boolean := False;
      Meta  : Boolean := False) return Editor.Keybindings.Key_Chord
   is
   begin
      return
        (Key       => Key,
         Modifiers => (Ctrl => Ctrl, Shift => Shift, Alt => Alt, Meta => Meta));
   end Chord;

   procedure Add_Default
     (Config  : in out Keybinding_Config_Model;
      Key     : Editor.Keybindings.Key_Code;
      Command : Editor.Commands.Command_Id;
      Ctrl    : Boolean := False;
      Shift   : Boolean := False;
      Alt     : Boolean := False;
      Meta    : Boolean := False)
   is
   begin
      Bind (Config, Command, Chord (Key, Ctrl => Ctrl, Shift => Shift, Alt => Alt, Meta => Meta));
   end Add_Default;

   procedure Populate_Built_In_Defaults
     (Config : in out Keybinding_Config_Model)
   is
   begin
      Clear (Config);

      Add_Default (Config, Editor.Keybindings.Key_S, Editor.Commands.Command_Save_File, Ctrl => True);
      Add_Default (Config, Editor.Keybindings.Key_S, Editor.Commands.Command_Save_File_As, Ctrl => True, Shift => True);
      Add_Default (Config, Editor.Keybindings.Key_F, Editor.Commands.Command_Find_Show, Ctrl => True);
      Add_Default (Config, Editor.Keybindings.Key_G, Editor.Commands.Command_Goto_Line, Ctrl => True);
      Add_Default (Config, Editor.Keybindings.Key_F, Editor.Commands.Command_Open_Project_Search_Bar, Ctrl => True, Shift => True);
      Add_Default (Config, Editor.Keybindings.Key_P, Editor.Commands.Command_Open_Quick_Open, Ctrl => True);
      Add_Default (Config, Editor.Keybindings.Key_P, Editor.Commands.Command_Open_Command_Palette, Ctrl => True, Shift => True);
      Add_Default (Config, Editor.Keybindings.Key_N, Editor.Commands.Command_New_Buffer, Ctrl => True);
      Add_Default (Config, Editor.Keybindings.Key_W, Editor.Commands.Command_Close_Active_Buffer, Ctrl => True);
      Add_Default (Config, Editor.Keybindings.Key_M, Editor.Commands.Command_Toggle_Problems_Panel, Ctrl => True, Shift => True);
      Add_Default (Config, Editor.Keybindings.Key_L, Editor.Commands.Command_Select_Line, Ctrl => True);
      Add_Default (Config, Editor.Keybindings.Key_A, Editor.Commands.Command_Select_All, Ctrl => True);
      Add_Default (Config, Editor.Keybindings.Key_C, Editor.Commands.Command_Copy, Ctrl => True);
      Add_Default (Config, Editor.Keybindings.Key_X, Editor.Commands.Command_Cut, Ctrl => True);
      Add_Default (Config, Editor.Keybindings.Key_V, Editor.Commands.Command_Paste, Ctrl => True);

      Add_Default (Config, Editor.Keybindings.Key_F1, Editor.Commands.Command_Palette_Show_Command_Help);
      Add_Default (Config, Editor.Keybindings.Key_O, Editor.Commands.Command_Open_File, Ctrl => True);
      Add_Default (Config, Editor.Keybindings.Key_O, Editor.Commands.Command_Open_Project, Ctrl => True, Alt => True);
      Add_Default (Config, Editor.Keybindings.Key_M, Editor.Commands.Command_Diagnostics_Show, Ctrl => True, Alt => True);

      Add_Default (Config, Editor.Keybindings.Key_F2, Editor.Commands.Command_Next_Bookmark);
      Add_Default (Config, Editor.Keybindings.Key_F2, Editor.Commands.Command_Previous_Bookmark, Shift => True);
      Add_Default (Config, Editor.Keybindings.Key_F2, Editor.Commands.Command_Toggle_Bookmark, Ctrl => True);
      Add_Default (Config, Editor.Keybindings.Key_F2, Editor.Commands.Command_Clear_Bookmarks, Ctrl => True, Shift => True);
      Add_Default (Config, Editor.Keybindings.Key_F3, Editor.Commands.Command_Active_Find_Next);
      Add_Default (Config, Editor.Keybindings.Key_F3, Editor.Commands.Command_Active_Find_Previous, Shift => True);

      Add_Default (Config, Editor.Keybindings.Key_Tab, Editor.Commands.Command_Previous_Recent_Buffer, Ctrl => True);
      Add_Default (Config, Editor.Keybindings.Key_Tab, Editor.Commands.Command_Next_Recent_Buffer, Ctrl => True, Shift => True);
      Add_Default (Config, Editor.Keybindings.Key_Z, Editor.Commands.Command_Undo, Ctrl => True);
      Add_Default (Config, Editor.Keybindings.Key_Y, Editor.Commands.Command_Redo, Ctrl => True);
      Add_Default (Config, Editor.Keybindings.Key_Z, Editor.Commands.Command_Redo, Ctrl => True, Shift => True);
      Add_Default (Config, Editor.Keybindings.Key_Left, Editor.Commands.Command_Navigation_Back, Alt => True);
      Add_Default (Config, Editor.Keybindings.Key_Right, Editor.Commands.Command_Navigation_Forward, Alt => True);

      Add_Default (Config, Editor.Keybindings.Key_Left, Editor.Commands.Command_Move_Left);
      Add_Default (Config, Editor.Keybindings.Key_Right, Editor.Commands.Command_Move_Right);
      Add_Default (Config, Editor.Keybindings.Key_Up, Editor.Commands.Command_Move_Up);
      Add_Default (Config, Editor.Keybindings.Key_Down, Editor.Commands.Command_Move_Down);
      Add_Default (Config, Editor.Keybindings.Key_Home, Editor.Commands.Command_Move_Line_Start);
      Add_Default (Config, Editor.Keybindings.Key_End, Editor.Commands.Command_Move_Line_End);
      Add_Default (Config, Editor.Keybindings.Key_Home, Editor.Commands.Command_Move_Document_Start, Ctrl => True);
      Add_Default (Config, Editor.Keybindings.Key_End, Editor.Commands.Command_Move_Document_End, Ctrl => True);
      Add_Default (Config, Editor.Keybindings.Key_Left, Editor.Commands.Command_Move_Word_Left, Ctrl => True);
      Add_Default (Config, Editor.Keybindings.Key_Right, Editor.Commands.Command_Move_Word_Right, Ctrl => True);
      Add_Default (Config, Editor.Keybindings.Key_Backspace, Editor.Commands.Command_Word_Delete_Previous, Ctrl => True);
      Add_Default (Config, Editor.Keybindings.Key_Delete, Editor.Commands.Command_Word_Delete_Next, Ctrl => True);
      Add_Default (Config, Editor.Keybindings.Key_Page_Up, Editor.Commands.Command_Page_Up);
      Add_Default (Config, Editor.Keybindings.Key_Page_Down, Editor.Commands.Command_Page_Down);
      Add_Default (Config, Editor.Keybindings.Key_Page_Up, Editor.Commands.Command_Select_Page_Up, Shift => True);
      Add_Default (Config, Editor.Keybindings.Key_Page_Down, Editor.Commands.Command_Select_Page_Down, Shift => True);
      Add_Default (Config, Editor.Keybindings.Key_Backspace, Editor.Commands.Command_Char_Delete_Previous);
      Add_Default (Config, Editor.Keybindings.Key_Delete, Editor.Commands.Command_Char_Delete_Next);
      Add_Default (Config, Editor.Keybindings.Key_Enter, Editor.Commands.Command_Insert_Newline);
      Add_Default (Config, Editor.Keybindings.Key_Escape, Editor.Commands.Command_Cancel);
      Add_Default (Config, Editor.Keybindings.Key_Left, Editor.Commands.Command_Select_Left, Shift => True);
      Add_Default (Config, Editor.Keybindings.Key_Right, Editor.Commands.Command_Select_Right, Shift => True);
      Add_Default (Config, Editor.Keybindings.Key_Up, Editor.Commands.Command_Select_Up, Shift => True);
      Add_Default (Config, Editor.Keybindings.Key_Down, Editor.Commands.Command_Select_Down, Shift => True);
      Add_Default (Config, Editor.Keybindings.Key_Home, Editor.Commands.Command_Select_Line_Start, Shift => True);
      Add_Default (Config, Editor.Keybindings.Key_End, Editor.Commands.Command_Select_Line_End, Shift => True);
      Add_Default (Config, Editor.Keybindings.Key_Home, Editor.Commands.Command_Select_Document_Start, Ctrl => True, Shift => True);
      Add_Default (Config, Editor.Keybindings.Key_End, Editor.Commands.Command_Select_Document_End, Ctrl => True, Shift => True);
      Add_Default (Config, Editor.Keybindings.Key_Left, Editor.Commands.Command_Select_Word_Left, Ctrl => True, Shift => True);
      Add_Default (Config, Editor.Keybindings.Key_Right, Editor.Commands.Command_Select_Word_Right, Ctrl => True, Shift => True);

      Add_Default (Config, Editor.Keybindings.Key_F12, Editor.Commands.Command_Refresh_Outline, Ctrl => True);
      Add_Default (Config, Editor.Keybindings.Key_Enter, Editor.Commands.Command_Open_Selected_Outline_Item, Alt => True);
      Add_Default (Config, Editor.Keybindings.Key_F3, Editor.Commands.Command_Select_Next_Outline_Item, Alt => True);
      Add_Default (Config, Editor.Keybindings.Key_F3, Editor.Commands.Command_Select_Previous_Outline_Item, Alt => True, Shift => True);
      Add_Default (Config, Editor.Keybindings.Key_F12, Editor.Commands.Command_Select_Current_Outline_Symbol, Alt => True);
      Add_Default (Config, Editor.Keybindings.Key_F12, Editor.Commands.Command_Reveal_Current_Outline_Symbol, Alt => True, Shift => True);

      Normalize (Config);
   end Populate_Built_In_Defaults;

   procedure Clear
     (Config : in out Keybinding_Config_Model)
   is
   begin
      Config.Format_Version := 1;
      for Id in Editor.Commands.Command_Id loop
         Config.Entries (Id).State := Entry_Absent;
      end loop;
   end Clear;

   procedure Set_Defaults
     (Config : in out Keybinding_Config_Model)
   is
   begin
      --  completeness: default projection is now constructed from
      --  the built-in table directly. It never installs defaults into the
      --  process-wide runtime resolver, so keybinding-list rendering, command
      --  help, audits, save/load comparison, and tests can inspect defaults
      --  without losing active user bindings or secondary runtime bindings.
      Populate_Built_In_Defaults (Config);
   end Set_Defaults;

   function Version
     (Config : Keybinding_Config_Model) return Natural
   is
   begin
      return Config.Format_Version;
   end Version;

   procedure Remove_Chord_Owner
     (Config  : in out Keybinding_Config_Model;
      Chord   : Editor.Keybindings.Key_Chord;
      Except  : Editor.Commands.Command_Id)
   is
   begin
      for Id in Editor.Commands.Command_Id loop
         if Id /= Except
           and then Config.Entries (Id).State = Entry_Bound
           and then Same_Chord (Config.Entries (Id).Chord, Chord)
         then
            Config.Entries (Id).State := Entry_Absent;
         end if;
      end loop;
   end Remove_Chord_Owner;

   procedure Bind
     (Config  : in out Keybinding_Config_Model;
      Command : Editor.Commands.Command_Id;
      Chord   : Editor.Keybindings.Key_Chord)
   is
   begin
      if not Editor.Keybindings.Is_Normal_Assignable_Command (Command) then
         return;
      end if;
      Remove_Chord_Owner (Config, Chord, Command);
      Config.Entries (Command).State := Entry_Bound;
      Config.Entries (Command).Chord := Chord;
   end Bind;

   procedure Unbind
     (Config  : in out Keybinding_Config_Model;
      Command : Editor.Commands.Command_Id)
   is
   begin
      if Editor.Keybindings.Is_Normal_Assignable_Command (Command) then
         Config.Entries (Command).State := Entry_Unbound;
      end if;
   end Unbind;


   function Name_Less (Left, Right : Editor.Commands.Command_Id) return Boolean is
   begin
      return Editor.Commands.Stable_Command_Name (Left)
        < Editor.Commands.Stable_Command_Name (Right);
   end Name_Less;

   function Sorted_Command_At
     (Config : Keybinding_Config_Model;
      Index  : Positive;
      Include_Unbound : Boolean := False) return Editor.Commands.Command_Id
   is
      Best       : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Best_Set   : Boolean;
      Seen       : array (Editor.Commands.Command_Id) of Boolean := (others => False);
      Wanted     : Natural := 0;
   begin
      loop
         Best_Set := False;
         for Id in Editor.Commands.Command_Id loop
            if Id /= Editor.Commands.No_Command
              and then not Seen (Id)
              and then (Config.Entries (Id).State = Entry_Bound
                        or else (Include_Unbound and then Config.Entries (Id).State = Entry_Unbound))
              and then (not Best_Set or else Name_Less (Id, Best))
            then
               Best := Id;
               Best_Set := True;
            end if;
         end loop;
         exit when not Best_Set;
         Seen (Best) := True;
         Wanted := Wanted + 1;
         if Wanted = Index then
            return Best;
         end if;
      end loop;
      pragma Assert (False, "Editor.Keybinding_Config sorted command index out of range");
      return Editor.Commands.No_Command;
   end Sorted_Command_At;

   function Binding_Count
     (Config : Keybinding_Config_Model) return Natural
   is
      Count : Natural := 0;
   begin
      for Id in Editor.Commands.Command_Id loop
         if Config.Entries (Id).State = Entry_Bound then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Binding_Count;

   function Command_At
     (Config : Keybinding_Config_Model;
      Index  : Positive) return Editor.Commands.Command_Id
   is
   begin
      return Sorted_Command_At (Config, Index);
   end Command_At;

   function Chord_For
     (Config  : Keybinding_Config_Model;
      Command : Editor.Commands.Command_Id;
      Found   : out Boolean) return Editor.Keybindings.Key_Chord
   is
   begin
      Found := Config.Entries (Command).State = Entry_Bound;
      return Config.Entries (Command).Chord;
   end Chord_For;

   procedure Normalize
     (Config : in out Keybinding_Config_Model)
   is
   begin
      Config.Format_Version := 1;
      for Id in Editor.Commands.Command_Id loop
         if Id = Editor.Commands.No_Command
           or else (Config.Entries (Id).State /= Entry_Absent
                    and then not Editor.Keybindings.Is_Normal_Assignable_Command (Id))
         then
            Config.Entries (Id).State := Entry_Absent;
         elsif Config.Entries (Id).State = Entry_Bound then
            Remove_Chord_Owner (Config, Config.Entries (Id).Chord, Id);
         end if;
      end loop;
   end Normalize;

   function Equivalent
     (Left  : Keybinding_Config_Model;
      Right : Keybinding_Config_Model) return Boolean
   is
      L : Keybinding_Config_Model := Left;
      R : Keybinding_Config_Model := Right;
   begin
      Normalize (L);
      Normalize (R);
      if L.Format_Version /= R.Format_Version then
         return False;
      end if;
      for Id in Editor.Commands.Command_Id loop
         if L.Entries (Id).State /= R.Entries (Id).State then
            return False;
         elsif L.Entries (Id).State = Entry_Bound
           and then not Same_Chord (L.Entries (Id).Chord, R.Entries (Id).Chord)
         then
            return False;
         end if;
      end loop;
      return True;
   end Equivalent;

   procedure Capture_Runtime
     (Config : out Keybinding_Config_Model)
   is
   begin
      Clear (Config);
      for Id in Editor.Commands.Command_Id loop
         if Editor.Keybindings.Is_Normal_Assignable_Command (Id)
           and then Editor.Keybindings.Binding_Count_For_Command (Id) > 0
         then
            Bind (Config, Id, Editor.Keybindings.Binding_For_Command (Id, 1));
         end if;
      end loop;
      Normalize (Config);
   end Capture_Runtime;

   procedure Build_From_Runtime
     (Config : out Keybinding_Config_Model)
   is
      Active   : Keybinding_Config_Model;
      Defaults : Keybinding_Config_Model;
   begin
      --  Preserve the active runtime table exactly. Defaults are projected
      --  from the built-in table directly, not by temporarily resetting the
      --  global resolver. This avoids the old fixed-size save/restore path
      --  that could silently drop bindings when the runtime table grew.
      Capture_Runtime (Active);
      Populate_Built_In_Defaults (Defaults);

      Config := Active;
      for Id in Editor.Commands.Command_Id loop
         if Editor.Keybindings.Is_Normal_Assignable_Command (Id)
           and then Defaults.Entries (Id).State = Entry_Bound
           and then Active.Entries (Id).State = Entry_Absent
         then
            Config.Entries (Id).State := Entry_Unbound;
         end if;
      end loop;
      Normalize (Config);
   end Build_From_Runtime;

   procedure Apply_To_Runtime
     (Config : Keybinding_Config_Model)
   is
      C : Keybinding_Config_Model := Config;
   begin
      Normalize (C);
      Editor.Keybindings.Reset_To_Defaults;
      for Id in Editor.Commands.Command_Id loop
         case C.Entries (Id).State is
            when Entry_Absent =>
               null;
            when Entry_Unbound =>
               Editor.Keybindings.Unbind_Command (Id);
            when Entry_Bound =>
               Editor.Keybindings.Unbind_Command (Id);
               Editor.Keybindings.Bind (C.Entries (Id).Chord, Id);
         end case;
      end loop;
   end Apply_To_Runtime;

   function Parent_Directory (Path : String) return String is
   begin
      for I in reverse Path'Range loop
         if Path (I) = '/' then
            if I = Path'First then
               return "/";
            end if;
            return Path (Path'First .. I - 1);
         end if;
      end loop;
      return "";
   end Parent_Directory;

   procedure Ensure_Directory (Dir : String) is
   begin
      if Dir'Length = 0 or else Ada.Directories.Exists (Dir) then
         return;
      end if;
      declare
         Parent : constant String := Parent_Directory (Dir);
      begin
         if Parent'Length > 0 and then not Ada.Directories.Exists (Parent) then
            Ensure_Directory (Parent);
         end if;
      end;
      Ada.Directories.Create_Directory (Dir);
   exception
      when others => null;
   end Ensure_Directory;

   function Keybindings_File_Path return String is
   begin
      if Ada.Environment_Variables.Exists ("EDITOR_KEYBINDINGS_PATH") then
         return Ada.Environment_Variables.Value ("EDITOR_KEYBINDINGS_PATH");
      elsif Ada.Environment_Variables.Exists ("XDG_CONFIG_HOME") then
         return Ada.Environment_Variables.Value ("XDG_CONFIG_HOME") & "/editor/keybindings";
      elsif Ada.Environment_Variables.Exists ("HOME") then
         return Ada.Environment_Variables.Value ("HOME") & "/.config/editor/keybindings";
      else
         return "editor/keybindings";
      end if;
   end Keybindings_File_Path;

   procedure Write_Config
     (File   : in out Ada.Text_IO.File_Type;
      Config : Keybinding_Config_Model)
   is
      C : Keybinding_Config_Model := Config;
   begin
      Normalize (C);
      Ada.Text_IO.Put_Line (File, "editor-keybindings-version=1");
      Ada.Text_IO.Put_Line (File, "[bindings]");
      declare
         Count : Natural := 0;
      begin
         for Id in Editor.Commands.Command_Id loop
            if Id /= Editor.Commands.No_Command
              and then C.Entries (Id).State /= Entry_Absent
            then
               Count := Count + 1;
            end if;
         end loop;
         for N in 1 .. Count loop
            declare
               Id : constant Editor.Commands.Command_Id :=
                 Sorted_Command_At (C, N, Include_Unbound => True);
            begin
               Ada.Text_IO.Put
                 (File, Editor.Commands.Stable_Command_Name (Id) & "=");
               if C.Entries (Id).State = Entry_Unbound then
                  Ada.Text_IO.Put_Line (File, "none");
               else
                  Ada.Text_IO.Put_Line
                    (File, Editor.Keybindings.Format_Chord (C.Entries (Id).Chord));
               end if;
            end;
         end loop;
      end;
   end Write_Config;

   procedure Save_To_File
     (Config : Keybinding_Config_Model;
      Path   : String;
      Status : out Keybinding_Config_Status)
   is
      File : Ada.Text_IO.File_Type;
      Temp : constant String := Path & ".tmp";
      Backup : constant String := Path & ".bak";
      Dir  : constant String := Parent_Directory (Path);
      Had_Previous : Boolean := False;
   begin
      Status := Keybinding_Config_Write_Error;
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
      Write_Config (File, Config);
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
      Status := Keybinding_Config_Ok;
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
         Status := Keybinding_Config_Write_Error;
   end Save_To_File;

   procedure Mark_Partial
     (Status : in out Keybinding_Config_Status;
      Kind   : Keybinding_Config_Diagnostic_Kind)
   is
   begin
      Record_Load_Diagnostic (Kind, Status);
   end Mark_Partial;

   procedure Load_From_File
     (Path   : String;
      Config : out Keybinding_Config_Model;
      Status : out Keybinding_Config_Status)
   is
      File    : Ada.Text_IO.File_Type;
      In_Bindings : Boolean := False;
      Seen_Header : Boolean := False;
   begin
      Reset_Load_Diagnostics;
      Clear (Config);
      if not Ada.Directories.Exists (Path) then
         Status := Keybinding_Config_Not_Found;
         return;
      end if;

      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      Status := Keybinding_Config_Ok;
      while not Ada.Text_IO.End_Of_File (File) loop
         declare
            Raw : constant String := Ada.Text_IO.Get_Line (File);
            L   : constant String := Trimmed (Raw);
            Eq  : Natural := 0;
         begin
            if L'Length = 0 or else L (L'First) = '#' then
               null;
            elsif not Seen_Header then
               if L'Length <= 27
                 or else L (L'First .. L'First + 26) /= "editor-keybindings-version="
               then
                  Ada.Text_IO.Close (File);
                  Clear (Config);
                  Status := Keybinding_Config_Invalid_Format;
                  return;
               end if;
               declare
                  Parsed : Natural := Natural'Value (L (L'First + 27 .. L'Last));
               begin
                  if Parsed /= 1 then
                     Ada.Text_IO.Close (File);
                     Clear (Config);
                     Status := Keybinding_Config_Unsupported_Version;
                     return;
                  end if;
                  Config.Format_Version := Parsed;
                  Seen_Header := True;
               exception
                  when others =>
                     Ada.Text_IO.Close (File);
                     Clear (Config);
                     Status := Keybinding_Config_Invalid_Format;
                     return;
               end;
            elsif L (L'First) = '[' and then L (L'Last) = ']' then
               declare
                  Sec : constant String := Lower (L (L'First + 1 .. L'Last - 1));
               begin
                  if Sec = "bindings" then
                     In_Bindings := True;
                  else
                     In_Bindings := False;
                     Mark_Partial (Status, Unknown_Section);
                  end if;
               end;
            else
               for I in L'Range loop
                  if L (I) = '=' then Eq := I; exit; end if;
               end loop;
               if Eq = 0 or else not In_Bindings then
                  Mark_Partial (Status, Malformed_Line);
               else
                  declare
                     Key : constant String := Lower (L (L'First .. Eq - 1));
                     Val : constant String := Trimmed (L (Eq + 1 .. L'Last));
                     Found_Command : Boolean := False;
                     Found_Chord   : Boolean := False;
                     Id : constant Editor.Commands.Command_Id :=
                       Editor.Commands.Command_Id_From_Stable_Name
                         (Key, Found_Command);
                     Chord : Editor.Keybindings.Key_Chord;
                  begin
                     if not Found_Command then
                        Mark_Partial (Status, Unknown_Command);
                     elsif not Editor.Keybindings.Is_Normal_Assignable_Command (Id) then
                        Mark_Partial (Status, Invalid_Command_Name);
                     elsif Lower (Val) = "none" then
                        Unbind (Config, Id);
                     elsif Keybinding_Value_Has_Unsupported_Payload (Val) then
                        --  persisted keybindings are chords mapped to
                        --  canonical command names only. Payload-bearing values are
                        --  ignored rather than normalized into executable state.
                        Mark_Partial (Status, Unsupported_Payload);
                     else
                        Chord := Editor.Keybindings.Parse_Chord (Val, Found_Chord);
                        if Found_Chord then
                           if Config.Entries (Id).State /= Entry_Absent then
                              Mark_Partial (Status, Duplicate_Command);
                           end if;
                           for Other in Editor.Commands.Command_Id loop
                              if Other /= Id
                                and then Config.Entries (Other).State = Entry_Bound
                                and then Same_Chord (Config.Entries (Other).Chord, Chord)
                              then
                                 Mark_Partial (Status, Duplicate_Chord);
                              end if;
                           end loop;
                           Bind (Config, Id, Chord);
                        else
                           Mark_Partial (Status, Invalid_Chord);
                        end if;
                     end if;
                  end;
               end if;
            end if;
         end;
      end loop;
      Ada.Text_IO.Close (File);
      if not Seen_Header then
         Clear (Config);
         Status := Keybinding_Config_Invalid_Format;
         return;
      end if;
      Normalize (Config);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         Clear (Config);
         Status := Keybinding_Config_Read_Error;
   end Load_From_File;

end Editor.Keybinding_Config;
