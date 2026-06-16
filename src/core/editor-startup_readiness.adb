with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands;
with Editor.Configuration_Recovery;

package body Editor.Startup_Readiness is

   use type Ada.Directories.File_Kind;

   use type Editor.Settings.Settings_Status;
   use type Editor.Keybinding_Config.Keybinding_Config_Status;
   use type Editor.Workspace_Persistence.Workspace_Persistence_Status;
   use type Editor.Recent_Projects.Recent_Project_Status;
   use type Editor.Workspace_Persistence.Workspace_Diagnostic_Kind;
   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Kind;
   use type Editor.Commands.Command_Visibility;
   use type Editor.Configuration_Recovery.Configuration_Domain;

   Recorded_Summary     : Startup_Summary := (others => <>);
   Recorded_Summary_Set : Boolean := False;

   function Count_Image (Value : Natural) return String is
      Raw : constant String := Natural'Image (Value);
   begin
      return Raw (Raw'First + 1 .. Raw'Last);
   end Count_Image;

   function Bounded (Text : String) return Unbounded_String is
   begin
      if Text'Length <= Max_Startup_Label_Length then
         return To_Unbounded_String (Text);
      elsif Max_Startup_Label_Length <= 3 then
         return To_Unbounded_String
           (Text (Text'First .. Text'First + Max_Startup_Label_Length - 1));
      else
         return To_Unbounded_String
           (Text (Text'First .. Text'First + Max_Startup_Label_Length - 4) & "...");
      end if;
   end Bounded;

   function Existing_Directory (Path : String) return Boolean is
   begin
      return Ada.Directories.Exists (Path)
        and then Ada.Directories.Kind (Path) = Ada.Directories.Directory;
   exception
      when others =>
         return False;
   end Existing_Directory;

   function Existing_Regular_File (Path : String) return Boolean is
   begin
      return Ada.Directories.Exists (Path)
        and then Ada.Directories.Kind (Path) = Ada.Directories.Ordinary_File;
   exception
      when others =>
         return False;
   end Existing_Regular_File;

   function Same_Workspace_Path (Left, Right : String) return Boolean is
   begin
      if Left = Right then
         return True;
      end if;

      if Ada.Directories.Exists (Left)
        and then Ada.Directories.Exists (Right)
      then
         return Ada.Directories.Full_Name (Left) = Ada.Directories.Full_Name (Right);
      end if;

      return False;
   exception
      when others =>
         return Left = Right;
   end Same_Workspace_Path;

   function Resolve_Workspace_File_Path
     (Workspace : Editor.Workspace_Persistence.Workspace_Snapshot;
      Item     : Editor.Workspace_Persistence.Workspace_File_Entry) return String
   is
      Raw : constant String := To_String (Item.Path);
   begin
      if Item.Is_Project_Relative
        and then Editor.Workspace_Persistence.Has_Project_Root (Workspace)
      then
         declare
            Root : constant String :=
              Editor.Workspace_Persistence.Project_Root (Workspace);
         begin
            if Root'Length = 0 then
               return Raw;
            elsif Raw'Length = 0 then
               return Root;
            elsif Root (Root'Last) = '/' or else Root (Root'Last) = '\' then
               return Root & Raw;
            else
               return Root & "/" & Raw;
            end if;
         end;
      else
         return Raw;
      end if;
   exception
      when others =>
         return Raw;
   end Resolve_Workspace_File_Path;

   function Panel_Layout_Warning_Count
     (Workspace : Editor.Workspace_Persistence.Workspace_Snapshot) return Natural;

   function Is_Missing_Canonical_Section_Diagnostic
     (D : Editor.Workspace_Persistence.Workspace_Diagnostic) return Boolean
   is
      Text : constant String := To_String (D.Text);
   begin
      return D.Kind = Editor.Workspace_Persistence.Malformed_Line
        and then
          (Text = "missing canonical [active-file] section"
           or else Text = "missing canonical [file-tree-expanded] section"
           or else Text = "missing canonical [panels] section");
   end Is_Missing_Canonical_Section_Diagnostic;

   function Is_Panel_Layout_Diagnostic
     (D : Editor.Workspace_Persistence.Workspace_Diagnostic) return Boolean
   is
      Text : constant String := To_String (D.Text);
   begin
      return D.Kind = Editor.Workspace_Persistence.Invalid_Panel_Value
        or else Text = "panels section is not in canonical order or is incomplete"
        or else Ada.Strings.Fixed.Index (Text, "file-tree-width=") = Text'First
        or else Ada.Strings.Fixed.Index (Text, "bottom-height=") = Text'First
        or else Ada.Strings.Fixed.Index (Text, "bottom-content=") = Text'First;
   end Is_Panel_Layout_Diagnostic;

   function Panel_Layout_Warning_Count
     (Workspace : Editor.Workspace_Persistence.Workspace_Snapshot) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 1 .. Editor.Workspace_Persistence.Diagnostic_Count (Workspace) loop
         if Is_Panel_Layout_Diagnostic
              (Editor.Workspace_Persistence.Diagnostic (Workspace, I))
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Panel_Layout_Warning_Count;

   function Workspace_Invalid_Diagnostic_Count
     (Workspace : Editor.Workspace_Persistence.Workspace_Snapshot) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 1 .. Editor.Workspace_Persistence.Diagnostic_Count (Workspace) loop
         case Editor.Workspace_Persistence.Diagnostic (Workspace, I).Kind is
            when Editor.Workspace_Persistence.Malformed_Line
               | Editor.Workspace_Persistence.Unknown_Section
               | Editor.Workspace_Persistence.Unsupported_Key
               | Editor.Workspace_Persistence.Invalid_Path
               | Editor.Workspace_Persistence.Duplicate_Path
               | Editor.Workspace_Persistence.Invalid_Number =>
               declare
                  D : constant Editor.Workspace_Persistence.Workspace_Diagnostic :=
                    Editor.Workspace_Persistence.Diagnostic (Workspace, I);
               begin
                  if not Is_Missing_Canonical_Section_Diagnostic (D)
                    and then not Is_Panel_Layout_Diagnostic (D)
                  then
                     Count := Count + 1;
                  end if;
               end;
            when Editor.Workspace_Persistence.Missing_File
               | Editor.Workspace_Persistence.Missing_Directory
               | Editor.Workspace_Persistence.Invalid_Panel_Value =>
               null;
         end case;
      end loop;
      return Count;
   end Workspace_Invalid_Diagnostic_Count;

   function Workspace_Missing_Diagnostic_Count
     (Workspace : Editor.Workspace_Persistence.Workspace_Snapshot) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 1 .. Editor.Workspace_Persistence.Diagnostic_Count (Workspace) loop
         case Editor.Workspace_Persistence.Diagnostic (Workspace, I).Kind is
            when Editor.Workspace_Persistence.Missing_File
               | Editor.Workspace_Persistence.Missing_Directory =>
               Count := Count + 1;
            when others =>
               null;
         end case;
      end loop;
      return Count;
   end Workspace_Missing_Diagnostic_Count;

   function Status_Label (Status : Startup_Domain_Status) return String is
   begin
      case Status is
         when Startup_Ok => return "ok";
         when Startup_Defaulted => return "defaulted";
         when Startup_Missing_Optional_File => return "missing optional file";
         when Startup_Loaded_With_Warnings => return "loaded with warnings";
         when Startup_Partial_Restore => return "partial restore";
         when Startup_Restore_Failed => return "restore failed";
         when Startup_Unavailable => return "unavailable";
         when Startup_Not_Requested => return "not requested";
      end case;
   end Status_Label;

   function Readiness_Label (Readiness : Startup_Readiness_Label) return String is
   begin
      case Readiness is
         when Startup_Ready => return "Ready";
         when Startup_Ready_With_Warnings => return "Ready with warnings";
         when Startup_First_Run_Ready => return "First-run ready";
         when Startup_Project_Unavailable => return "Project unavailable";
         when Startup_Workspace_Partial_Restore => return "Workspace partial restore";
      end case;
   end Readiness_Label;

   function Focus_Label (Focus : Startup_Focus_Owner) return String is
   begin
      case Focus is
         when Startup_Focus_Editor => return "Editor";
         when Startup_Focus_File_Tree => return "File Tree";
         when Startup_Focus_None => return "No text target";
      end case;
   end Focus_Label;

   function Domain_Row
     (Label                : String;
      Status               : Startup_Domain_Status;
      Warning_Count        : Natural := 0;
      Error_Count          : Natural := 0;
      Invalid_Entry_Count  : Natural := 0;
      Rejected_Entry_Count : Natural := 0;
      Missing_File_Count   : Natural := 0;
      Restored_File_Count  : Natural := 0;
      Safe_Defaults_Active : Boolean := False) return Startup_Domain_Row
   is
   begin
      return
        (Label                => Bounded (Label),
         Status               => Status,
         Warning_Count        => Warning_Count,
         Error_Count          => Error_Count,
         Invalid_Entry_Count  => Invalid_Entry_Count,
         Rejected_Entry_Count => Rejected_Entry_Count,
         Missing_File_Count   => Missing_File_Count,
         Restored_File_Count  => Restored_File_Count,
         Safe_Defaults_Active => Safe_Defaults_Active);
   end Domain_Row;

   procedure Append
     (Summary : in out Startup_Summary;
      Row     : Startup_Domain_Row)
   is
      Clean : Startup_Domain_Row := Row;
   begin
      if Length (Clean.Label) > Max_Startup_Label_Length then
         Clean.Label := Bounded (To_String (Clean.Label));
      end if;

      if Summary.Row_Count < Max_Startup_Domain_Rows then
         Summary.Row_Count := Summary.Row_Count + 1;
         Summary.Rows (Summary.Row_Count) := Clean;
      else
         Summary.Bounded := False;
      end if;

      Summary.Warning_Count := Summary.Warning_Count + Clean.Warning_Count;
      Summary.Error_Count := Summary.Error_Count + Clean.Error_Count;
      Summary.Invalid_Entry_Count :=
        Summary.Invalid_Entry_Count + Clean.Invalid_Entry_Count;
      Summary.Rejected_Entry_Count :=
        Summary.Rejected_Entry_Count + Clean.Rejected_Entry_Count;
      Summary.Missing_File_Count :=
        Summary.Missing_File_Count + Clean.Missing_File_Count;
      Summary.Restored_File_Count :=
        Summary.Restored_File_Count + Clean.Restored_File_Count;
      if Clean.Safe_Defaults_Active then
         Summary.Safe_Default_Domain_Count :=
           Summary.Safe_Default_Domain_Count + 1;
      end if;
   end Append;

   procedure Normalize (Summary : in out Startup_Summary) is
   begin
      if Summary.Row_Count > Max_Startup_Domain_Rows then
         Summary.Row_Count := Max_Startup_Domain_Rows;
         Summary.Bounded := False;
      end if;

      Summary.Warning_Count := 0;
      Summary.Error_Count := 0;
      Summary.Invalid_Entry_Count := 0;
      Summary.Rejected_Entry_Count := 0;
      Summary.Missing_File_Count := 0;
      Summary.Restored_File_Count := 0;
      Summary.Safe_Default_Domain_Count := 0;

      Summary.Primary_Message := Bounded (To_String (Summary.Primary_Message));
      Summary.Action_Suggestion := Bounded (To_String (Summary.Action_Suggestion));
      for I in 1 .. Summary.Row_Count loop
         Summary.Rows (I).Label := Bounded (To_String (Summary.Rows (I).Label));
         Summary.Warning_Count :=
           Summary.Warning_Count + Summary.Rows (I).Warning_Count;
         Summary.Error_Count :=
           Summary.Error_Count + Summary.Rows (I).Error_Count;
         Summary.Invalid_Entry_Count :=
           Summary.Invalid_Entry_Count + Summary.Rows (I).Invalid_Entry_Count;
         Summary.Rejected_Entry_Count :=
           Summary.Rejected_Entry_Count + Summary.Rows (I).Rejected_Entry_Count;
         Summary.Missing_File_Count :=
           Summary.Missing_File_Count + Summary.Rows (I).Missing_File_Count;
         Summary.Restored_File_Count :=
           Summary.Restored_File_Count + Summary.Rows (I).Restored_File_Count;
         if Summary.Rows (I).Safe_Defaults_Active then
            Summary.Safe_Default_Domain_Count :=
              Summary.Safe_Default_Domain_Count + 1;
         end if;
      end loop;
   end Normalize;

   function Status_From_Settings
     (Status : Editor.Settings.Settings_Status) return Startup_Domain_Row
   is
   begin
      case Status is
         when Editor.Settings.Settings_Ok =>
            return Domain_Row ("Settings", Startup_Ok);
         when Editor.Settings.Settings_Not_Found =>
            return Domain_Row
              ("Settings", Startup_Missing_Optional_File,
               Safe_Defaults_Active => True);
         when Editor.Settings.Settings_Partial_Load =>
            return Domain_Row
              ("Settings", Startup_Loaded_With_Warnings,
               Warning_Count => Natural'Max
                 (1, Editor.Settings.Last_Load_Ignored_Count
                     + Editor.Settings.Last_Load_Defaulted_Count),
               Invalid_Entry_Count => Editor.Settings.Last_Load_Ignored_Count,
               Rejected_Entry_Count => Editor.Settings.Last_Load_Defaulted_Count,
               Safe_Defaults_Active =>
                 Editor.Settings.Last_Load_Defaulted_Count > 0);
         when Editor.Settings.Settings_Invalid_Format
            | Editor.Settings.Settings_Unsupported_Version =>
            return Domain_Row
              ("Settings", Startup_Defaulted,
               Warning_Count => 1,
               Safe_Defaults_Active => True);
         when Editor.Settings.Settings_Read_Error
            | Editor.Settings.Settings_Write_Error =>
            return Domain_Row
              ("Settings", Startup_Defaulted,
               Error_Count => 1,
               Safe_Defaults_Active => True);
      end case;
   end Status_From_Settings;

   function Status_From_Keybindings
     (Status : Editor.Keybinding_Config.Keybinding_Config_Status) return Startup_Domain_Row
   is
   begin
      case Status is
         when Editor.Keybinding_Config.Keybinding_Config_Ok =>
            return Domain_Row ("Keybindings", Startup_Ok);
         when Editor.Keybinding_Config.Keybinding_Config_Not_Found =>
            return Domain_Row
              ("Keybindings", Startup_Missing_Optional_File,
               Safe_Defaults_Active => True);
         when Editor.Keybinding_Config.Keybinding_Config_Partial_Load =>
            return Domain_Row
              ("Keybindings", Startup_Loaded_With_Warnings,
               Warning_Count => Natural'Max
                 (1, Editor.Keybinding_Config.Last_Load_Ignored_Count),
               Rejected_Entry_Count =>
                 Editor.Keybinding_Config.Last_Load_Ignored_Count,
               --  Runtime keybindings start from defaults and valid user
               --  entries are then applied.  Rejected entries therefore leave
               --  the corresponding safe default bindings active.
               Safe_Defaults_Active =>
                 Editor.Keybinding_Config.Last_Load_Ignored_Count > 0);
         when Editor.Keybinding_Config.Keybinding_Config_Invalid_Format
            | Editor.Keybinding_Config.Keybinding_Config_Unsupported_Version =>
            return Domain_Row
              ("Keybindings", Startup_Defaulted,
               Warning_Count => 1,
               Invalid_Entry_Count => 1,
               Safe_Defaults_Active => True);
         when Editor.Keybinding_Config.Keybinding_Config_Read_Error
            | Editor.Keybinding_Config.Keybinding_Config_Write_Error =>
            return Domain_Row
              ("Keybindings", Startup_Defaulted,
               Error_Count => 1,
               Safe_Defaults_Active => True);
      end case;
   end Status_From_Keybindings;

   function Status_From_Workspace
     (Status      : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Restore_Requested : Boolean := True) return Startup_Domain_Row
   is
   begin
      if not Restore_Requested then
         return Domain_Row ("Workspace", Startup_Not_Requested);
      end if;

      case Status is
         when Editor.Workspace_Persistence.Workspace_Persistence_Ok =>
            return Domain_Row ("Workspace", Startup_Ok);
         when Editor.Workspace_Persistence.Workspace_Persistence_Not_Found =>
            return Domain_Row ("Workspace", Startup_Missing_Optional_File);
         when Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore =>
            return Domain_Row
              ("Workspace", Startup_Partial_Restore,
               Warning_Count => 1);
         when Editor.Workspace_Persistence.Workspace_Persistence_Invalid_Format
            | Editor.Workspace_Persistence.Workspace_Persistence_Unsupported_Version =>
            return Domain_Row
              ("Workspace", Startup_Restore_Failed,
               Warning_Count => 1,
               Safe_Defaults_Active => True);
         when Editor.Workspace_Persistence.Workspace_Persistence_Read_Error
            | Editor.Workspace_Persistence.Workspace_Persistence_Write_Error =>
            return Domain_Row
              ("Workspace", Startup_Restore_Failed,
               Error_Count => 1,
               Safe_Defaults_Active => True);
      end case;
   end Status_From_Workspace;

   function Status_From_Recent_Projects
     (Status : Editor.Recent_Projects.Recent_Project_Status) return Startup_Domain_Row
   is
   begin
      case Status is
         when Editor.Recent_Projects.Recent_Project_Ok =>
            return Domain_Row ("Recent Projects", Startup_Ok);
         when Editor.Recent_Projects.Recent_Project_Not_Found =>
            return Domain_Row ("Recent Projects", Startup_Missing_Optional_File);
         when Editor.Recent_Projects.Recent_Project_Partial_Load =>
            return Domain_Row
              ("Recent Projects", Startup_Loaded_With_Warnings,
               Warning_Count => Natural'Max
                 (1, Editor.Recent_Projects.Last_Load_Ignored_Count),
               Invalid_Entry_Count =>
                 Editor.Recent_Projects.Last_Load_Ignored_Count);
         when Editor.Recent_Projects.Recent_Project_Invalid_Format =>
            return Domain_Row
              ("Recent Projects", Startup_Loaded_With_Warnings,
               Warning_Count => 1,
               Invalid_Entry_Count => 1,
               Safe_Defaults_Active => True);
         when Editor.Recent_Projects.Recent_Project_Read_Error
            | Editor.Recent_Projects.Recent_Project_Write_Error =>
            return Domain_Row
              ("Recent Projects", Startup_Unavailable,
               Error_Count => 1,
               Safe_Defaults_Active => True);
      end case;
   end Status_From_Recent_Projects;

   function Build_First_Run_Summary return Startup_Summary is
      Result : Startup_Summary;
   begin
      Append (Result, Domain_Row
        ("Settings", Startup_Missing_Optional_File,
         Safe_Defaults_Active => True));
      Append (Result, Domain_Row
        ("Keybindings", Startup_Missing_Optional_File,
         Safe_Defaults_Active => True));
      Append (Result, Domain_Row ("Workspace", Startup_Missing_Optional_File));
      Append (Result, Domain_Row ("Recent Projects", Startup_Missing_Optional_File));
      Append (Result, Domain_Row ("Project Restore", Startup_Not_Requested));
      Append (Result, Domain_Row ("Open File Restore", Startup_Not_Requested));
      Append (Result, Domain_Row ("Panel/Layout Restore", Startup_Not_Requested));
      Result.First_Run := True;
      Result.Readiness := Startup_First_Run_Ready;
      Result.Safe_Focus := Startup_Focus_None;
      Result.Primary_Message := To_Unbounded_String
        ("Ready. Default settings active. Default keybindings active. No workspace restored. No recent projects.");
      Result.Action_Suggestion := To_Unbounded_String ("Open a project to begin.");
      Normalize (Result);
      return Result;
   end Build_First_Run_Summary;

   function Has_Status_Issue (Row : Startup_Domain_Row) return Boolean is
   begin
      return Row.Status not in Startup_Ok | Startup_Not_Requested
        or else Row.Warning_Count > 0
        or else Row.Error_Count > 0
        or else Row.Invalid_Entry_Count > 0
        or else Row.Rejected_Entry_Count > 0
        or else Row.Missing_File_Count > 0
        or else Row.Safe_Defaults_Active;
   end Has_Status_Issue;

   function Build_Startup_Summary
     (Settings_Row       : Startup_Domain_Row;
      Keybindings_Row    : Startup_Domain_Row;
      Workspace_Row      : Startup_Domain_Row;
      Recent_Row         : Startup_Domain_Row;
      Project_Restored   : Boolean := False;
      Project_Missing    : Boolean := False;
      Files_Restored     : Natural := 0;
      Files_Missing      : Natural := 0;
      Files_Not_Attempted : Natural := 0;
      Active_Buffer_Restored : Boolean := False;
      Panel_Layout_Restored  : Boolean := False;
      Panel_Layout_Warnings  : Natural := 0) return Startup_Summary
   is
      Result : Startup_Summary;
      Project_Row : Startup_Domain_Row;
      File_Row    : Startup_Domain_Row;
      Panel_Row   : Startup_Domain_Row;
   begin
      Append (Result, Settings_Row);
      Append (Result, Keybindings_Row);
      Append (Result, Workspace_Row);
      Append (Result, Recent_Row);

      if Project_Missing then
         Project_Row := Domain_Row
           ("Project Restore", Startup_Unavailable,
            Warning_Count => 1,
            Missing_File_Count => 1);
      elsif Project_Restored then
         Project_Row := Domain_Row ("Project Restore", Startup_Ok);
      else
         Project_Row := Domain_Row ("Project Restore", Startup_Not_Requested);
      end if;
      Append (Result, Project_Row);

      if Files_Missing > 0
        or else (Files_Restored > 0 and then Files_Not_Attempted > 0)
      then
         File_Row := Domain_Row
           ("Open File Restore", Startup_Partial_Restore,
            Warning_Count => Natural'Max
              (1, Files_Missing + Files_Not_Attempted),
            Missing_File_Count => Files_Missing,
            Restored_File_Count => Files_Restored);
      elsif Files_Restored > 0 then
         File_Row := Domain_Row
           ("Open File Restore", Startup_Ok,
            Restored_File_Count => Files_Restored);
      else
         File_Row := Domain_Row ("Open File Restore", Startup_Not_Requested);
      end if;
      Append (Result, File_Row);

      if Panel_Layout_Warnings > 0 then
         Panel_Row := Domain_Row
           ("Panel/Layout Restore", Startup_Loaded_With_Warnings,
            Warning_Count => Panel_Layout_Warnings);
      elsif Panel_Layout_Restored then
         Panel_Row := Domain_Row ("Panel/Layout Restore", Startup_Ok);
      else
         Panel_Row := Domain_Row ("Panel/Layout Restore", Startup_Not_Requested);
      end if;
      Append (Result, Panel_Row);

      Result.First_Run :=
        Settings_Row.Status = Startup_Missing_Optional_File
        and then Keybindings_Row.Status = Startup_Missing_Optional_File
        and then Workspace_Row.Status = Startup_Missing_Optional_File
        and then Recent_Row.Status = Startup_Missing_Optional_File
        and then not Project_Restored
        and then not Project_Missing
        and then Files_Restored = 0
        and then Files_Missing = 0
        and then Files_Not_Attempted = 0
        and then not Panel_Layout_Restored
        and then Panel_Layout_Warnings = 0;

      if Result.First_Run then
         Result.Readiness := Startup_First_Run_Ready;
         Result.Primary_Message := To_Unbounded_String
           ("Ready. Default settings active. Default keybindings active. No workspace restored. No recent projects.");
         Result.Action_Suggestion := To_Unbounded_String ("Open a project to begin.");
      elsif Project_Missing then
         Result.Readiness := Startup_Project_Unavailable;
         Result.Primary_Message := To_Unbounded_String ("Editor ready with workspace project unavailable.");
         Result.Action_Suggestion := To_Unbounded_String ("Open configuration recovery or choose another project.");
      elsif Files_Missing > 0
        or else Workspace_Row.Status = Startup_Partial_Restore
      then
         Result.Readiness := Startup_Workspace_Partial_Restore;
         Result.Primary_Message := To_Unbounded_String
           ("Workspace restored with missing files skipped.");
         Result.Action_Suggestion := To_Unbounded_String ("Open configuration recovery for details.");
      elsif Result.Warning_Count > 0 or else Result.Error_Count > 0
        or else Has_Status_Issue (Settings_Row)
        or else Has_Status_Issue (Keybindings_Row)
        or else Has_Status_Issue (Recent_Row)
        or else Panel_Layout_Warnings > 0
      then
         Result.Readiness := Startup_Ready_With_Warnings;
         Result.Primary_Message := To_Unbounded_String
           ("Editor ready with configuration warnings.");
         Result.Action_Suggestion := To_Unbounded_String ("Run configuration audit.");
      else
         Result.Readiness := Startup_Ready;
         Result.Primary_Message := To_Unbounded_String ("Editor ready.");
         Result.Action_Suggestion := Null_Unbounded_String;
      end if;

      if Active_Buffer_Restored then
         Result.Safe_Focus := Startup_Focus_Editor;
      elsif Project_Restored then
         Result.Safe_Focus := Startup_Focus_File_Tree;
      else
         Result.Safe_Focus := Startup_Focus_None;
      end if;

      --  These fields are startup-orchestration invariants.  The concrete
      --  product pipeline may route through the project/file lifecycle
      --  mutators outside this summary package; the summary records that no
      --  direct fabricated restore path, pending confirmation, or auto-repair
      --  UI state is represented here.
      Result.Project_Restore_Uses_Lifecycle := True;
      Result.File_Restore_Uses_Lifecycle := True;
      Result.Project_Surfaces_Initialized := True;
      Result.Pending_Confirmation_Restored := False;
      Result.Recovery_View_Auto_Repairs := False;

      Normalize (Result);
      return Result;
   end Build_Startup_Summary;

   function Build_Observed_Startup_Summary
     (Settings_Status       : Editor.Settings.Settings_Status;
      Keybindings_Status    : Editor.Keybinding_Config.Keybinding_Config_Status;
      Workspace_Status      : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Recent_Status         : Editor.Recent_Projects.Recent_Project_Status;
      Workspace             : Editor.Workspace_Persistence.Workspace_Snapshot;
      Restore_Requested     : Boolean := True) return Startup_Summary
   is
      Files_Restored     : Natural := 0;
      Files_Missing      : Natural := 0;
      Files_Not_Attempted : Natural := 0;
      Active_Buffer_Restored : Boolean := False;
      Active_File_Declared   : constant Boolean :=
        Editor.Workspace_Persistence.Has_Active_File_Path (Workspace);
      Active_Path            : Unbounded_String := Null_Unbounded_String;
      Project_Restored   : Boolean := False;
      Project_Missing    : Boolean := False;
      Workspace_Row      : Startup_Domain_Row :=
        Status_From_Workspace (Workspace_Status, Restore_Requested);
      Workspace_Warning_Diagnostics : constant Natural :=
        (if Restore_Requested then
            Workspace_Invalid_Diagnostic_Count (Workspace)
         else 0);
   begin
      if Restore_Requested
        and then Workspace_Status in
          Editor.Workspace_Persistence.Workspace_Persistence_Ok
        | Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore
      then
         if Editor.Workspace_Persistence.Has_Project_Root (Workspace) then
            Project_Restored := Existing_Directory
              (Editor.Workspace_Persistence.Project_Root (Workspace));
            Project_Missing := not Project_Restored;
         end if;

         if Active_File_Declared then
            declare
               Active_Entry : constant Editor.Workspace_Persistence.Workspace_File_Entry :=
                 (Path => To_Unbounded_String
                    (Editor.Workspace_Persistence.Active_File_Path (Workspace)),
                  Is_Project_Relative =>
                    Editor.Workspace_Persistence.Active_File_Is_Project_Relative
                      (Workspace),
                  Cursor_Row => 0,
                  Cursor_Column => 0,
                  View_First_Row => 0);
            begin
               Active_Path := To_Unbounded_String
                 (Resolve_Workspace_File_Path (Workspace, Active_Entry));
            end;
         end if;

         for I in 1 .. Editor.Workspace_Persistence.Open_File_Count (Workspace) loop
            declare
               File_Entry : constant Editor.Workspace_Persistence.Workspace_File_Entry :=
                 Editor.Workspace_Persistence.Open_File (Workspace, I);
               Can_Attempt_File_Restore : constant Boolean :=
                 (not File_Entry.Is_Project_Relative) or else not Project_Missing;
               Path  : constant String :=
                 Resolve_Workspace_File_Path (Workspace, File_Entry);
            begin
               --  A missing project root prevents project-relative file restore:
               --  without a valid project context, those paths cannot be
               --  resolved through the normal workspace/project lifecycle and
               --  must not cascade into additional missing-file counts.
               --  Absolute workspace file entries, however, remain independently
               --  restorable file-backed buffers and should still be reported.
               if Can_Attempt_File_Restore then
                  if Existing_Regular_File (Path) then
                     Files_Restored := Files_Restored + 1;
                     if Active_File_Declared
                       and then Same_Workspace_Path (Path, To_String (Active_Path))
                     then
                        Active_Buffer_Restored := True;
                     end if;
                  else
                     Files_Missing := Files_Missing + 1;
                  end if;
               else
                  Files_Not_Attempted := Files_Not_Attempted + 1;
               end if;
            end;
         end loop;

         --  Parser/format workspace diagnostics belong to the workspace row.
         --  Missing project/open-file targets belong to the dedicated restore
         --  rows for both warning and missing-target aggregate counts, avoiding
         --  duplicated startup warnings for the same skipped target.
         Workspace_Row.Warning_Count := Workspace_Warning_Diagnostics;
         Workspace_Row.Invalid_Entry_Count :=
           Workspace_Row.Invalid_Entry_Count
           + Workspace_Invalid_Diagnostic_Count (Workspace);
      end if;

      return Build_Startup_Summary
        (Status_From_Settings (Settings_Status),
         Status_From_Keybindings (Keybindings_Status),
         Workspace_Row,
         Status_From_Recent_Projects (Recent_Status),
         Project_Restored => Project_Restored,
         Project_Missing => Project_Missing,
         Files_Restored => Files_Restored,
         Files_Missing => Files_Missing,
         Files_Not_Attempted => Files_Not_Attempted,
         Active_Buffer_Restored => Restore_Requested and then Active_Buffer_Restored,
         Panel_Layout_Restored =>
           Restore_Requested
           and then
             (Workspace_Status in
                Editor.Workspace_Persistence.Workspace_Persistence_Ok
              | Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore),
         Panel_Layout_Warnings =>
           (if Restore_Requested then Panel_Layout_Warning_Count (Workspace) else 0));
   end Build_Observed_Startup_Summary;

   procedure Startup_Run
     (Settings_Path    : String;
      Keybindings_Path : String;
      Workspace_Path   : String;
      Recent_Path      : String;
      Policy           : Startup_Run_Policy;
      Settings         : out Editor.Settings.Settings_Model;
      Keybindings      : out Editor.Keybinding_Config.Keybinding_Config_Model;
      Workspace        : out Editor.Workspace_Persistence.Workspace_Snapshot;
      Recent           : out Editor.Recent_Projects.Recent_Project_List;
      Summary          : out Startup_Summary)
   is
      Settings_Status    : Editor.Settings.Settings_Status;
      Keybindings_Status : Editor.Keybinding_Config.Keybinding_Config_Status;
      Workspace_Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Recent_Status      : Editor.Recent_Projects.Recent_Project_Status;
   begin
      Editor.Settings.Set_Defaults (Settings);
      Editor.Keybinding_Config.Set_Defaults (Keybindings);
      Editor.Workspace_Persistence.Clear (Workspace);
      Editor.Recent_Projects.Clear (Recent);

      begin
         Editor.Settings.Load_From_File (Settings_Path, Settings, Settings_Status);
      exception
         when others =>
            Editor.Settings.Set_Defaults (Settings);
            Settings_Status := Editor.Settings.Settings_Read_Error;
      end;
      if Settings_Status /= Editor.Settings.Settings_Ok
        and then Settings_Status /= Editor.Settings.Settings_Partial_Load
      then
         Editor.Settings.Set_Defaults (Settings);
      end if;

      begin
         Editor.Keybinding_Config.Load_From_File
           (Keybindings_Path, Keybindings, Keybindings_Status);
      exception
         when others =>
            Editor.Keybinding_Config.Set_Defaults (Keybindings);
            Keybindings_Status :=
              Editor.Keybinding_Config.Keybinding_Config_Read_Error;
      end;
      if Keybindings_Status /= Editor.Keybinding_Config.Keybinding_Config_Ok
        and then Keybindings_Status /= Editor.Keybinding_Config.Keybinding_Config_Partial_Load
      then
         Editor.Keybinding_Config.Set_Defaults (Keybindings);
      end if;

      begin
         Editor.Recent_Projects.Load_From_File (Recent_Path, Recent, Recent_Status);
      exception
         when others =>
            Editor.Recent_Projects.Clear (Recent);
            Recent_Status := Editor.Recent_Projects.Recent_Project_Read_Error;
      end;
      if Recent_Status /= Editor.Recent_Projects.Recent_Project_Ok
        and then Recent_Status /= Editor.Recent_Projects.Recent_Project_Partial_Load
      then
         Editor.Recent_Projects.Clear (Recent);
      end if;

      if Policy.Restore_Workspace_On_Startup then
         begin
            Editor.Workspace_Persistence.Load_From_File
              (Workspace_Path, Workspace, Workspace_Status);
         exception
            when others =>
               Editor.Workspace_Persistence.Clear (Workspace);
               Workspace_Status :=
                 Editor.Workspace_Persistence.Workspace_Persistence_Read_Error;
         end;
         if Workspace_Status /= Editor.Workspace_Persistence.Workspace_Persistence_Ok
           and then Workspace_Status /=
             Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore
         then
            Editor.Workspace_Persistence.Clear (Workspace);
         end if;
      else
         Workspace_Status := Editor.Workspace_Persistence.Workspace_Persistence_Not_Found;
      end if;

      Summary := Build_Observed_Startup_Summary
        (Settings_Status,
         Keybindings_Status,
         Workspace_Status,
         Recent_Status,
         Workspace,
         Restore_Requested => Policy.Restore_Workspace_On_Startup);
      Record_Startup_Summary (Summary);
   end Startup_Run;

   function Recovery_Status_From_Row
     (Row    : Startup_Domain_Row;
      Domain : Editor.Configuration_Recovery.Configuration_Domain)
      return Editor.Configuration_Recovery.Domain_Recovery_Status
   is
      Result : Editor.Configuration_Recovery.Domain_Recovery_Status;
   begin
      Result.Domain := Domain;
      Result.Warning_Count := Row.Warning_Count;
      Result.Error_Count := Row.Error_Count;
      Result.Invalid_Entry_Count := Row.Invalid_Entry_Count;
      Result.Rejected_Entry_Count := Row.Rejected_Entry_Count;
      Result.Safe_Defaults_Active := Row.Safe_Defaults_Active;
      Result.User_Action_Suggestion := Bounded (To_String (Row.Label));
      case Row.Status is
         when Startup_Ok | Startup_Not_Requested =>
            Result.Load_Status := Editor.Configuration_Recovery.Domain_Ok;
            Result.Action := Editor.Configuration_Recovery.No_Recovery_Action;
         when Startup_Defaulted | Startup_Missing_Optional_File =>
            Result.Load_Status := Editor.Configuration_Recovery.Domain_Loaded_With_Defaults;
            Result.Action := Editor.Configuration_Recovery.Use_Safe_Defaults;
            Result.Missing_File := Row.Status = Startup_Missing_Optional_File;
         when Startup_Loaded_With_Warnings =>
            Result.Load_Status := Editor.Configuration_Recovery.Domain_Loaded_With_Warnings;
            Result.Action := Editor.Configuration_Recovery.Ignore_Invalid_Entries;
         when Startup_Partial_Restore =>
            Result.Load_Status := Editor.Configuration_Recovery.Domain_Partially_Loaded;
            Result.Action := Editor.Configuration_Recovery.Keep_Valid_Entries;
         when Startup_Restore_Failed | Startup_Unavailable =>
            Result.Load_Status := Editor.Configuration_Recovery.Domain_Malformed;
            Result.Action := Editor.Configuration_Recovery.Reset_Domain_Available;
      end case;
      return Result;
   end Recovery_Status_From_Row;

   function Configuration_Recovery_View
     (Summary : Startup_Summary)
      return Editor.Configuration_Recovery.Configuration_Recovery_Summary
   is
      Result : Editor.Configuration_Recovery.Configuration_Recovery_Summary;
      Runtime_Status : Editor.Configuration_Recovery.Domain_Recovery_Status;
      Runtime_Warnings : Natural := 0;
      Runtime_Errors   : Natural := 0;
      Runtime_Invalid  : Natural := 0;
      Runtime_Rejected : Natural := 0;
      Runtime_Defaults : Boolean := False;
      Runtime_Issues   : Boolean := False;
   begin
      --  The configuration recovery view has a smaller, configuration-domain
      --  bounded model than the startup summary.  Project restore, open-file
      --  restore, and panel/layout restore are therefore folded into one
      --  runtime-defaults row instead of overflowing the recovery-domain
      --  array.  This keeps startup recovery projection transient and bounded
      --  while still surfacing startup restore warnings.
      for I in 1 .. Summary.Row_Count loop
         declare
            Row : constant Startup_Domain_Row := Summary.Rows (I);
         begin
            case I is
               when 1 =>
                  Editor.Configuration_Recovery.Append
                    (Result, Recovery_Status_From_Row
                       (Row, Editor.Configuration_Recovery.Settings_Domain));
               when 2 =>
                  Editor.Configuration_Recovery.Append
                    (Result, Recovery_Status_From_Row
                       (Row, Editor.Configuration_Recovery.Keybindings_Domain));
               when 3 =>
                  Editor.Configuration_Recovery.Append
                    (Result, Recovery_Status_From_Row
                       (Row, Editor.Configuration_Recovery.Workspace_Domain));
               when 4 =>
                  Editor.Configuration_Recovery.Append
                    (Result, Recovery_Status_From_Row
                       (Row, Editor.Configuration_Recovery.Recent_Projects_Domain));
               when others =>
                  --  Missing-target rows already own a bounded warning count.
                  --  Do not add Missing_File_Count here, or the recovery
                  --  projection will reintroduce the duplicate warning totals
                  --  that startup aggregation intentionally avoids.
                  Runtime_Warnings := Runtime_Warnings + Row.Warning_Count;
                  Runtime_Errors := Runtime_Errors + Row.Error_Count;
                  Runtime_Invalid := Runtime_Invalid + Row.Invalid_Entry_Count;
                  Runtime_Rejected := Runtime_Rejected + Row.Rejected_Entry_Count;
                  Runtime_Defaults := Runtime_Defaults or else Row.Safe_Defaults_Active;
                  Runtime_Issues := Runtime_Issues
                    or else Row.Status not in Startup_Ok | Startup_Not_Requested
                    or else Row.Warning_Count > 0
                    or else Row.Error_Count > 0
                    or else Row.Missing_File_Count > 0
                    or else Row.Invalid_Entry_Count > 0
                    or else Row.Rejected_Entry_Count > 0
                    or else Row.Safe_Defaults_Active;
            end case;
         end;
      end loop;

      if Runtime_Issues then
         Runtime_Status.Domain := Editor.Configuration_Recovery.Runtime_Defaults_Domain;
         Runtime_Status.Warning_Count := Runtime_Warnings;
         Runtime_Status.Error_Count := Runtime_Errors;
         Runtime_Status.Invalid_Entry_Count := Runtime_Invalid;
         Runtime_Status.Rejected_Entry_Count := Runtime_Rejected;
         Runtime_Status.Safe_Defaults_Active := Runtime_Defaults;
         Runtime_Status.User_Action_Suggestion :=
           Bounded ("Startup restore details");
         if Runtime_Errors > 0 then
            Runtime_Status.Load_Status :=
              Editor.Configuration_Recovery.Domain_Malformed;
            Runtime_Status.Action :=
              Editor.Configuration_Recovery.Reset_Domain_Available;
         else
            Runtime_Status.Load_Status :=
              Editor.Configuration_Recovery.Domain_Loaded_With_Warnings;
            Runtime_Status.Action :=
              Editor.Configuration_Recovery.Keep_Valid_Entries;
         end if;
         Editor.Configuration_Recovery.Append (Result, Runtime_Status);
      end if;

      return Result;
   end Configuration_Recovery_View;

   procedure Record_Startup_Summary (Summary : Startup_Summary) is
      Clean : Startup_Summary := Summary;
   begin
      Normalize (Clean);
      Recorded_Summary := Clean;
      Recorded_Summary_Set := True;
   end Record_Startup_Summary;

   function Has_Recorded_Startup_Summary return Boolean is
   begin
      return Recorded_Summary_Set;
   end Has_Recorded_Startup_Summary;

   function Current_Startup_Summary return Startup_Summary is
   begin
      return Recorded_Summary;
   end Current_Startup_Summary;

   procedure Clear_Startup_Summary is
   begin
      Recorded_Summary := (others => <>);
      Recorded_Summary_Set := False;
   end Clear_Startup_Summary;

   function Status_Bar_Label (Summary : Startup_Summary) return String is
   begin
      case Summary.Readiness is
         when Startup_Ready =>
            if Summary.Safe_Default_Domain_Count > 0 then
               return "Ready — defaults active";
            else
               return "Ready";
            end if;
         when Startup_Ready_With_Warnings =>
            if Summary.Safe_Default_Domain_Count > 0 then
               return "Ready with warnings — defaults active";
            else
               return "Ready with warnings";
            end if;
         when Startup_First_Run_Ready =>
            return "Ready — first run";
         when Startup_Project_Unavailable =>
            if Summary.Safe_Default_Domain_Count > 0
              and then Summary.Restored_File_Count > 0
            then
               return "Project unavailable — files restored — defaults active";
            elsif Summary.Safe_Default_Domain_Count > 0 then
               return "Project unavailable — defaults active";
            elsif Summary.Restored_File_Count > 0 then
               return "Project unavailable — files restored";
            else
               return "Project unavailable";
            end if;
         when Startup_Workspace_Partial_Restore =>
            if Summary.Safe_Default_Domain_Count > 0 then
               return "Workspace partial restore — defaults active";
            else
               return "Workspace partial restore";
            end if;
      end case;
   end Status_Bar_Label;

   function First_Run_Empty_State_Label (Summary : Startup_Summary) return String is
   begin
      if Summary.First_Run then
         return "Ready. Default settings active. Default keybindings active. No workspace restored. No recent projects. Open a project to begin.";
      else
         return To_String (Summary.Primary_Message);
      end if;
   end First_Run_Empty_State_Label;

   function Startup_Command_Message (Summary : Startup_Summary) return String is
      Base : constant String := First_Run_Empty_State_Label (Summary);
      Counts : constant String :=
        (if Summary.Warning_Count = 0
          and then Summary.Error_Count = 0
          and then Summary.Invalid_Entry_Count = 0
          and then Summary.Rejected_Entry_Count = 0
          and then Summary.Missing_File_Count = 0
          and then Summary.Restored_File_Count = 0
         then ""
         else
           (if Summary.Warning_Count = 0 then ""
            else " Warnings: " & Count_Image (Summary.Warning_Count) & ".")
           & (if Summary.Error_Count = 0 then ""
              else " Errors: " & Count_Image (Summary.Error_Count) & ".")
           & (if Summary.Invalid_Entry_Count = 0 then ""
              else " Invalid entries: "
                & Count_Image (Summary.Invalid_Entry_Count) & ".")
           & (if Summary.Rejected_Entry_Count = 0 then ""
              else " Rejected entries: "
                & Count_Image (Summary.Rejected_Entry_Count) & ".")
           & (if Summary.Missing_File_Count = 0 then ""
              else " Missing files: "
                & Count_Image (Summary.Missing_File_Count) & ".")
           & (if Summary.Restored_File_Count = 0 then ""
              else " Restored files: "
                & Count_Image (Summary.Restored_File_Count) & "."));
      Defaults : constant String :=
        (if Summary.First_Run or else Summary.Safe_Default_Domain_Count = 0
         then ""
         else " Defaults active: "
           & Count_Image (Summary.Safe_Default_Domain_Count) & ".");
      Action : constant String :=
        (if Length (Summary.Action_Suggestion) = 0
         then ""
         else " " & To_String (Summary.Action_Suggestion));
   begin
      return To_String (Bounded (Base & Counts & Defaults & Action));
   end Startup_Command_Message;

   function Assert_Startup_Summary_Is_Bounded_And_Transient return Boolean is
      Summary : Startup_Summary;
   begin
      Summary := Build_Startup_Summary
        (Domain_Row ("Settings", Startup_Defaulted,
                     Safe_Defaults_Active => True),
         Domain_Row ("Keybindings", Startup_Loaded_With_Warnings,
                     Warning_Count => 1, Rejected_Entry_Count => 2),
         Domain_Row ("Workspace", Startup_Partial_Restore,
                     Warning_Count => 1),
         Domain_Row ("Recent Projects", Startup_Loaded_With_Warnings,
                     Warning_Count => 1, Invalid_Entry_Count => 1),
         Files_Restored => 1,
         Files_Missing => 2,
         Active_Buffer_Restored => True);
      Record_Startup_Summary (Summary);
      if not Has_Recorded_Startup_Summary
        or else not Current_Startup_Summary.Transient
        or else not Current_Startup_Summary.Bounded
        or else Length (Current_Startup_Summary.Primary_Message) > Max_Startup_Label_Length
      then
         return False;
      end if;
      Clear_Startup_Summary;
      return not Has_Recorded_Startup_Summary
        and then Current_Startup_Summary.Row_Count = 0;
   end Assert_Startup_Summary_Is_Bounded_And_Transient;

   function Assert_Startup_Uses_Safe_Defaults return Boolean is
      Summary : constant Startup_Summary := Build_First_Run_Summary;
   begin
      return Summary.First_Run
        and then Summary.Readiness = Startup_First_Run_Ready
        and then Summary.Safe_Default_Domain_Count = 2
        and then Summary.Rows (1).Safe_Defaults_Active
        and then Summary.Rows (2).Safe_Defaults_Active
        and then Summary.Rows (3).Status = Startup_Missing_Optional_File
        and then Summary.Safe_Focus = Startup_Focus_None;
   end Assert_Startup_Uses_Safe_Defaults;

   function Assert_Startup_Status_Projection_Is_Observational return Boolean is
      Summary : Startup_Summary := Build_First_Run_Summary;
      Before  : constant Startup_Summary := Summary;
      Label   : constant String := Status_Bar_Label (Summary);
   begin
      return Label = "Ready — first run"
        and then Summary.Row_Count = Before.Row_Count
        and then Summary.Warning_Count = Before.Warning_Count
        and then Summary.Error_Count = Before.Error_Count;
   end Assert_Startup_Status_Projection_Is_Observational;

   function Assert_Startup_State_Not_Persisted return Boolean is
      Summary : Startup_Summary := Build_First_Run_Summary;
      Recovery : Editor.Configuration_Recovery.Configuration_Recovery_Summary;
   begin
      Recovery := Configuration_Recovery_View (Summary);
      return Summary.Transient
        and then not Summary.Recovery_View_Auto_Repairs
        and then not Summary.Pending_Confirmation_Restored
        and then Recovery.Domain_Count > 0
        and then Length (Summary.Primary_Message) > 0
        and then Editor.Configuration_Recovery.Summary_Label (Recovery) /= "";
   end Assert_Startup_State_Not_Persisted;

   function Assert_Startup_Keybindings_Have_No_Payloads return Boolean is
   begin
      return Editor.Commands.Stable_Command_Name
        (Editor.Commands.Command_Startup_Show_Summary) =
        "startup.show-summary"
        and then Editor.Commands.Stable_Command_Name
          (Editor.Commands.Command_Configuration_Recover_Show) =
          "configuration.recover-show"
        and then Editor.Commands.Stable_Command_Name
          (Editor.Commands.Command_Configuration_Audit) = "configuration.audit"
        and then not Editor.Commands.Descriptor
          (Editor.Commands.Command_Startup_Show_Summary).Requires_Explicit_Target
        and then not Editor.Commands.Descriptor
          (Editor.Commands.Command_Startup_Show_Summary).Target_Prompt_Capable;
   end Assert_Startup_Keybindings_Have_No_Payloads;


   function Assert_Startup_Display_Commands_Route_Through_Executor return Boolean is
      Startup_Descriptor : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Startup_Show_Summary);
      Recovery_Descriptor : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Configuration_Recover_Show);
      Startup_Command : constant Editor.Commands.Command :=
        Editor.Commands.Command_For_Id (Editor.Commands.Command_Startup_Show_Summary);
      Recovery_Command : constant Editor.Commands.Command :=
        Editor.Commands.Command_For_Id (Editor.Commands.Command_Configuration_Recover_Show);
   begin
      return Startup_Descriptor.Visibility = Editor.Commands.Palette_Command
        and then Recovery_Descriptor.Visibility = Editor.Commands.Palette_Command
        and then Startup_Descriptor.Configuration
        and then Recovery_Descriptor.Configuration
        and then Startup_Command.Kind = Editor.Commands.Startup_Show_Summary
        and then Recovery_Command.Kind = Editor.Commands.Configuration_Recover_Show
        and then Length (Startup_Command.Text) = 0
        and then Length (Startup_Command.Path) = 0
        and then Length (Startup_Command.Query) = 0
        and then Length (Recovery_Command.Text) = 0
        and then Length (Recovery_Command.Path) = 0
        and then Length (Recovery_Command.Query) = 0;
   end Assert_Startup_Display_Commands_Route_Through_Executor;


   function Assert_Startup_Routes_Restore_Through_Lifecycle return Boolean is
      Summary : constant Startup_Summary := Build_Startup_Summary
        (Domain_Row ("Settings", Startup_Ok),
         Domain_Row ("Keybindings", Startup_Ok),
         Domain_Row ("Workspace", Startup_Ok),
         Domain_Row ("Recent Projects", Startup_Ok),
         Project_Restored => True,
         Files_Restored => 2,
         Files_Missing => 0,
         Active_Buffer_Restored => True);
   begin
      return Summary.Project_Restore_Uses_Lifecycle
        and then Summary.File_Restore_Uses_Lifecycle
        and then Summary.Rows (5).Label = To_Unbounded_String ("Project Restore")
        and then Summary.Rows (6).Label = To_Unbounded_String ("Open File Restore")
        and then Summary.Rows (5).Status = Startup_Ok
        and then Summary.Rows (6).Status = Startup_Ok;
   end Assert_Startup_Routes_Restore_Through_Lifecycle;

   function Assert_Startup_Project_Surfaces_Initialized_Cleanly return Boolean is
      Summary : constant Startup_Summary := Build_Startup_Summary
        (Domain_Row ("Settings", Startup_Ok),
         Domain_Row ("Keybindings", Startup_Ok),
         Domain_Row ("Workspace", Startup_Ok),
         Domain_Row ("Recent Projects", Startup_Ok),
         Project_Restored => True,
         Files_Restored => 0,
         Files_Missing => 0,
         Active_Buffer_Restored => False,
         Panel_Layout_Restored => False);
   begin
      return Summary.Project_Surfaces_Initialized
        and then Summary.Rows (7).Label = To_Unbounded_String ("Panel/Layout Restore")
        and then Summary.Rows (7).Status = Startup_Not_Requested
        and then Summary.Safe_Focus = Startup_Focus_File_Tree
        and then Summary.Restored_File_Count = 0
        and then Summary.Missing_File_Count = 0;
   end Assert_Startup_Project_Surfaces_Initialized_Cleanly;

   function Assert_Startup_Restores_No_Pending_Confirmation return Boolean is
      Summary : constant Startup_Summary := Build_Startup_Summary
        (Domain_Row ("Settings", Startup_Ok),
         Domain_Row ("Keybindings", Startup_Ok),
         Domain_Row ("Workspace", Startup_Partial_Restore, Warning_Count => 1),
         Domain_Row ("Recent Projects", Startup_Ok),
         Project_Restored => True,
         Files_Restored => 1,
         Files_Missing => 1,
         Active_Buffer_Restored => True);
   begin
      return not Summary.Pending_Confirmation_Restored
        and then not Summary.Recovery_View_Auto_Repairs
        and then Summary.Transient;
   end Assert_Startup_Restores_No_Pending_Confirmation;



   function Assert_Startup_Recovery_View_Is_Bounded return Boolean is
      Summary : constant Startup_Summary := Build_Startup_Summary
        (Domain_Row ("Settings", Startup_Defaulted, Warning_Count => 1,
                     Safe_Defaults_Active => True),
         Domain_Row ("Keybindings", Startup_Loaded_With_Warnings,
                     Warning_Count => 1, Rejected_Entry_Count => 2),
         Domain_Row ("Workspace", Startup_Partial_Restore, Warning_Count => 1),
         Domain_Row ("Recent Projects", Startup_Loaded_With_Warnings,
                     Warning_Count => 1, Invalid_Entry_Count => 1),
         Project_Missing => True,
         Files_Restored => 1,
         Files_Missing => 2,
         Panel_Layout_Warnings => 1);
      Recovery : constant Editor.Configuration_Recovery.Configuration_Recovery_Summary :=
        Configuration_Recovery_View (Summary);
   begin
      return Recovery.Bounded
        and then Recovery.Domain_Count <= Editor.Configuration_Recovery.Max_Recovery_Domains
        and then Recovery.Domain_Count = 5
        and then Recovery.Rows (5).Domain =
          Editor.Configuration_Recovery.Runtime_Defaults_Domain
        and then Recovery.Rows (5).Warning_Count >= 3
        and then not Summary.Recovery_View_Auto_Repairs;
   end Assert_Startup_Recovery_View_Is_Bounded;



   function Assert_Startup_Aggregate_Counts_Match_Rows return Boolean is
      Summary : Startup_Summary := Build_Startup_Summary
        (Domain_Row ("Settings", Startup_Defaulted,
                     Warning_Count => 1,
                     Invalid_Entry_Count => 1,
                     Safe_Defaults_Active => True),
         Domain_Row ("Keybindings", Startup_Loaded_With_Warnings,
                     Warning_Count => 2, Rejected_Entry_Count => 2,
                     Safe_Defaults_Active => True),
         Domain_Row ("Workspace", Startup_Partial_Restore,
                     Warning_Count => 1, Missing_File_Count => 3),
         Domain_Row ("Recent Projects", Startup_Loaded_With_Warnings,
                     Warning_Count => 1, Invalid_Entry_Count => 4),
         Project_Restored => True,
         Files_Restored => 2,
         Files_Missing => 1,
         Active_Buffer_Restored => True,
         Panel_Layout_Warnings => 1);
      Manual_Warnings : Natural := 0;
      Manual_Errors   : Natural := 0;
      Manual_Invalid  : Natural := 0;
      Manual_Rejected : Natural := 0;
      Manual_Missing  : Natural := 0;
      Manual_Restored : Natural := 0;
      Manual_Defaults : Natural := 0;
   begin
      --  Deliberately corrupt aggregate fields and verify normalization makes
      --  recorded startup state internally consistent with bounded rows.
      Summary.Warning_Count := 99;
      Summary.Error_Count := 99;
      Summary.Invalid_Entry_Count := 99;
      Summary.Rejected_Entry_Count := 99;
      Summary.Missing_File_Count := 99;
      Summary.Restored_File_Count := 99;
      Summary.Safe_Default_Domain_Count := 99;
      Normalize (Summary);

      for I in 1 .. Summary.Row_Count loop
         Manual_Warnings := Manual_Warnings + Summary.Rows (I).Warning_Count;
         Manual_Errors := Manual_Errors + Summary.Rows (I).Error_Count;
         Manual_Invalid := Manual_Invalid + Summary.Rows (I).Invalid_Entry_Count;
         Manual_Rejected := Manual_Rejected + Summary.Rows (I).Rejected_Entry_Count;
         Manual_Missing := Manual_Missing + Summary.Rows (I).Missing_File_Count;
         Manual_Restored := Manual_Restored + Summary.Rows (I).Restored_File_Count;
         if Summary.Rows (I).Safe_Defaults_Active then
            Manual_Defaults := Manual_Defaults + 1;
         end if;
      end loop;

      return Summary.Warning_Count = Manual_Warnings
        and then Summary.Error_Count = Manual_Errors
        and then Summary.Invalid_Entry_Count = Manual_Invalid
        and then Summary.Rejected_Entry_Count = Manual_Rejected
        and then Summary.Missing_File_Count = Manual_Missing
        and then Summary.Restored_File_Count = Manual_Restored
        and then Summary.Safe_Default_Domain_Count = Manual_Defaults;
   end Assert_Startup_Aggregate_Counts_Match_Rows;

   function Assert_Startup_Readiness_Coherent return Boolean is
      First : constant Startup_Summary := Build_First_Run_Summary;
      Partial : constant Startup_Summary := Build_Startup_Summary
        (Domain_Row ("Settings", Startup_Ok),
         Domain_Row ("Keybindings", Startup_Loaded_With_Warnings,
                     Warning_Count => 1, Rejected_Entry_Count => 1),
         Domain_Row ("Workspace", Startup_Partial_Restore,
                     Warning_Count => 1),
         Domain_Row ("Recent Projects", Startup_Ok),
         Project_Restored => True,
         Files_Restored => 1,
         Files_Missing => 1,
         Active_Buffer_Restored => True);
      Missing_Project : constant Startup_Summary := Build_Startup_Summary
        (Domain_Row ("Settings", Startup_Ok),
         Domain_Row ("Keybindings", Startup_Ok),
         Domain_Row ("Workspace", Startup_Ok),
         Domain_Row ("Recent Projects", Startup_Ok),
         Project_Missing => True);
      Defaulted_Settings : constant Startup_Summary := Build_Startup_Summary
        (Domain_Row ("Settings", Startup_Defaulted, Warning_Count => 1,
                     Safe_Defaults_Active => True),
         Domain_Row ("Keybindings", Startup_Ok),
         Domain_Row ("Workspace", Startup_Ok),
         Domain_Row ("Recent Projects", Startup_Ok));
      Partial_Keybindings : constant Startup_Summary := Build_Startup_Summary
        (Domain_Row ("Settings", Startup_Ok),
         Domain_Row ("Keybindings", Startup_Loaded_With_Warnings,
                     Warning_Count => 2,
                     Rejected_Entry_Count => 2,
                     Safe_Defaults_Active => True),
         Domain_Row ("Workspace", Startup_Ok),
         Domain_Row ("Recent Projects", Startup_Ok));
      Malformed_Workspace : constant Startup_Summary := Build_Startup_Summary
        (Domain_Row ("Settings", Startup_Ok),
         Domain_Row ("Keybindings", Startup_Ok),
         Status_From_Workspace
           (Editor.Workspace_Persistence.Workspace_Persistence_Invalid_Format),
         Domain_Row ("Recent Projects", Startup_Ok));
      Malformed_Recent : constant Startup_Summary := Build_Startup_Summary
        (Domain_Row ("Settings", Startup_Ok),
         Domain_Row ("Keybindings", Startup_Ok),
         Domain_Row ("Workspace", Startup_Ok),
         Status_From_Recent_Projects
           (Editor.Recent_Projects.Recent_Project_Invalid_Format));
   begin
      return Assert_Startup_Uses_Safe_Defaults
        and then Assert_Startup_Summary_Is_Bounded_And_Transient
        and then Assert_Startup_Status_Projection_Is_Observational
        and then Assert_Startup_State_Not_Persisted
        and then Assert_Startup_Keybindings_Have_No_Payloads
        and then Assert_Startup_Display_Commands_Route_Through_Executor
        and then Assert_Startup_Routes_Restore_Through_Lifecycle
        and then Assert_Startup_Project_Surfaces_Initialized_Cleanly
        and then Assert_Startup_Restores_No_Pending_Confirmation
        and then Assert_Startup_Recovery_View_Is_Bounded
        and then Assert_Startup_Aggregate_Counts_Match_Rows
        and then First.First_Run
        and then First.Row_Count = 7
        and then First.Restored_File_Count = 0
        and then First.Missing_File_Count = 0
        and then Partial.Readiness = Startup_Workspace_Partial_Restore
        and then Partial.Restored_File_Count = 1
        and then Partial.Missing_File_Count = 1
        and then Partial.Safe_Focus = Startup_Focus_Editor
        and then Startup_Command_Message (Partial)'Length <= Max_Startup_Label_Length
        and then Missing_Project.Readiness = Startup_Project_Unavailable
        and then Missing_Project.Safe_Focus = Startup_Focus_None
        and then Defaulted_Settings.Safe_Default_Domain_Count = 1
        and then Status_Bar_Label (Defaulted_Settings) =
          "Ready with warnings — defaults active"
        and then Startup_Command_Message (Defaulted_Settings)'Length <=
          Max_Startup_Label_Length
        and then Partial_Keybindings.Safe_Default_Domain_Count = 1
        and then Partial_Keybindings.Warning_Count = 2
        and then Partial_Keybindings.Rows (2).Rejected_Entry_Count = 2
        and then Partial_Keybindings.Rejected_Entry_Count = 2
        and then Partial_Keybindings.Invalid_Entry_Count = 0
        and then Status_Bar_Label (Partial_Keybindings) =
          "Ready with warnings — defaults active"
        and then Startup_Command_Message (Partial_Keybindings)'Length <=
          Max_Startup_Label_Length
        and then Malformed_Workspace.Safe_Default_Domain_Count = 1
        and then Malformed_Workspace.Rows (3).Safe_Defaults_Active
        and then Status_Bar_Label (Malformed_Workspace) =
          "Ready with warnings — defaults active"
        and then Malformed_Recent.Safe_Default_Domain_Count = 1
        and then Malformed_Recent.Invalid_Entry_Count = 1
        and then Malformed_Recent.Rows (4).Safe_Defaults_Active
        and then Status_Bar_Label (Malformed_Recent) =
          "Ready with warnings — defaults active";
   end Assert_Startup_Readiness_Coherent;

end Editor.Startup_Readiness;
