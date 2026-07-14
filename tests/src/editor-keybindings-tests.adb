with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Characters.Handling;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands;
with Editor.Command_Route_Audit;
with Editor.Command_Palette;
with Editor.Cursors;
with Editor.Executor;
with Editor.Executor.Command_Palette_Projection;
with Editor.Gutter_Markers;
with Editor.Guided_Prompts;
with Editor.Input_Bridge;
with Editor.Input_Bridge.Keybinding_Handlers;
with Editor.Keybindings;
with Editor.Keybinding_Config;
with Editor.Keybinding_Management;
with Editor.Render_Model;
with Editor.State;
with Guikit.Draw;
use type Editor.Commands.Command_Id;
use type Editor.Commands.Command_Availability_Status;
use type Editor.Keybindings.Binding_Result;
use type Editor.Keybindings.Keybinding_Validation_Status;
use type Editor.Keybindings.Keybinding_Change_Status;
use type Editor.Keybinding_Config.Keybinding_Config_Status;
use type Editor.Keybinding_Management.Keybinding_Action_Status;
use type Editor.Keybinding_Management.Keybinding_Capture_State;
use type Editor.Keybinding_Management.Keybinding_Filter;

package body Editor.Keybindings.Tests is


   function Temp_Path (Name : String) return String is
   begin
      return "/tmp/editor_" & Name & ".keybindings";
   end Temp_Path;

   procedure Write_File (Path : String; Text : String) is
      F : Ada.Text_IO.File_Type;
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_File (Path);
      end if;
      Ada.Text_IO.Create (F, Ada.Text_IO.Out_File, Path);
      Ada.Text_IO.Put (F, Text);
      Ada.Text_IO.Close (F);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (F) then
            Ada.Text_IO.Close (F);
         end if;
         raise;
   end Write_File;

   function File_Contents (Path : String) return String is
      F : Ada.Text_IO.File_Type;
      R : Unbounded_String := Null_Unbounded_String;
   begin
      Ada.Text_IO.Open (F, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (F) loop
         Append (R, Ada.Text_IO.Get_Line (F));
         if not Ada.Text_IO.End_Of_File (F) then
            Append (R, ASCII.LF);
         end if;
      end loop;
      Ada.Text_IO.Close (F);
      return To_String (R);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (F) then
            Ada.Text_IO.Close (F);
         end if;
         raise;
   end File_Contents;

   function Chord
     (Key   : Editor.Keybindings.Key_Code;
      Ctrl  : Boolean := False;
      Shift : Boolean := False;
      Alt   : Boolean := False) return Editor.Keybindings.Key_Chord
   is
   begin
      return
        (Key       => Key,
         Modifiers => (Ctrl => Ctrl, Shift => Shift, Alt => Alt, Meta => False));
   end Chord;

   procedure Assert_Resolves
     (Chord : Editor.Keybindings.Key_Chord;
      Id    : Editor.Commands.Command_Id;
      Msg   : String)
   is
      Actual : Editor.Commands.Command_Id;
   begin
      Assert
        (Editor.Keybindings.Resolve (Chord, Actual) = Editor.Keybindings.Bound_Command,
         Msg & " must resolve to a command");
      Assert (Actual = Id, Msg);
   end Assert_Resolves;

   procedure Prepare_Text
     (Text : String)
   is
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Text);
      Editor.Input_Bridge.Set_State_For_Test (S);
   end Prepare_Text;

   procedure Test_Default_Shortcuts_Resolve
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Assert_Resolves
        (Chord (Editor.Keybindings.Key_S, Ctrl => True),
         Editor.Commands.Command_Save_File,
         "Ctrl+S");
      Assert_Resolves
        (Chord (Editor.Keybindings.Key_F1),
         Editor.Commands.Command_Palette_Show_Command_Help,
         "F1 command help");
      Assert_Resolves
        (Chord (Editor.Keybindings.Key_O, Ctrl => True),
         Editor.Commands.Command_Open_File,
         "Ctrl+O open file");
      Assert_Resolves
        (Chord (Editor.Keybindings.Key_O, Ctrl => True, Alt => True),
         Editor.Commands.Command_Open_Project,
         "Ctrl+Alt+O open project");
      Assert_Resolves
        (Chord (Editor.Keybindings.Key_M, Ctrl => True, Alt => True),
         Editor.Commands.Command_Diagnostics_Show,
         "Ctrl+Alt+M diagnostics");
      declare
         Actual : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      begin
         Assert
           (Editor.Keybindings.Resolve
              (Chord (Editor.Keybindings.Key_S, Ctrl => True, Shift => True), Actual) =
            Editor.Keybindings.Bound_Command,
            "Ctrl+Shift+S should resolve through canonical Save As target-prompt command");
         Assert (Actual = Editor.Commands.Command_Save_File_As,
            "Save As chord must carry the canonical command target");
      end;
      Assert_Resolves
        (Chord (Editor.Keybindings.Key_F, Ctrl => True),
         Editor.Commands.Command_Find_Show,
         "Ctrl+F active-buffer Find");
      Assert_Resolves
        (Chord (Editor.Keybindings.Key_P, Ctrl => True),
         Editor.Commands.Command_Open_Quick_Open,
         "Ctrl+P");
      Assert_Resolves
        (Chord (Editor.Keybindings.Key_P, Ctrl => True, Shift => True),
         Editor.Commands.Command_Open_Command_Palette,
         "Ctrl+Shift+P");
      Assert_Resolves
        (Chord (Editor.Keybindings.Key_N, Ctrl => True),
         Editor.Commands.Command_New_Buffer,
         "Ctrl+N");
      Assert_Resolves
        (Chord (Editor.Keybindings.Key_W, Ctrl => True),
         Editor.Commands.Command_Close_Active_Buffer,
         "Ctrl+W");
      Assert_Resolves
        (Chord (Editor.Keybindings.Key_Tab, Ctrl => True),
         Editor.Commands.Command_Previous_Recent_Buffer,
         "Ctrl+Tab");
      Assert_Resolves
        (Chord (Editor.Keybindings.Key_Tab, Ctrl => True, Shift => True),
         Editor.Commands.Command_Next_Recent_Buffer,
         "Ctrl+Shift+Tab");
      Assert_Resolves
        (Chord (Editor.Keybindings.Key_M, Ctrl => True, Shift => True),
         Editor.Commands.Command_Toggle_Problems_Panel,
         "Ctrl+Shift+M");
      Assert_Resolves
        (Chord (Editor.Keybindings.Key_F2),
         Editor.Commands.Command_Next_Bookmark,
         "F2");
      Assert_Resolves
        (Chord (Editor.Keybindings.Key_F2, Shift => True),
         Editor.Commands.Command_Previous_Bookmark,
         "Shift+F2");
      Assert_Resolves
        (Chord (Editor.Keybindings.Key_F2, Ctrl => True),
         Editor.Commands.Command_Toggle_Bookmark,
         "Ctrl+F2");
      Assert_Resolves
        (Chord (Editor.Keybindings.Key_F2, Ctrl => True, Shift => True),
         Editor.Commands.Command_Clear_Bookmarks,
         "Ctrl+Shift+F2");
      Assert_Resolves
        (Chord (Editor.Keybindings.Key_Z, Ctrl => True),
         Editor.Commands.Command_Undo,
         "Ctrl+Z");
   end Test_Default_Shortcuts_Resolve;

   procedure Test_Unknown_Chord_Has_No_Binding
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Actual : Editor.Commands.Command_Id;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Assert
        (Editor.Keybindings.Resolve
           (Chord (Editor.Keybindings.Key_F), Actual) = Editor.Keybindings.No_Binding,
         "Plain F must not resolve to a command binding");
      Assert
        (Actual = Editor.Commands.No_Command,
         "Unbound chords must return No_Command as their target");
   end Test_Unknown_Chord_Has_No_Binding;

   procedure Test_Custom_Bind_And_Unbind
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Actual : Editor.Commands.Command_Id;
      C      : constant Editor.Keybindings.Key_Chord :=
        Chord (Editor.Keybindings.Key_F, Alt => True);
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Keybindings.Bind (C, Editor.Commands.Command_Find_Show);
      Assert
        (Editor.Keybindings.Resolve (C, Actual) = Editor.Keybindings.Bound_Command
         and then Actual = Editor.Commands.Command_Find_Show,
         "Custom Bind must add a resolvable chord");

      Editor.Keybindings.Unbind (C);
      Assert
        (Editor.Keybindings.Resolve (C, Actual) = Editor.Keybindings.No_Binding,
         "Unbind must remove the custom chord");
   end Test_Custom_Bind_And_Unbind;

   procedure Test_Plain_Printable_Still_Inserts_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Cmd  : Editor.Commands.Command;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Prepare_Text ("");
      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'x';
      Cmd.Text := To_Unbounded_String (String'(1 => 'x'));
      Cmd.Code := Wide_Wide_Character'Val (Character'Pos ('x'));
      Editor.Input_Bridge.Handle (Cmd);
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert (Snap.Length = 1, "Plain printable character must insert buffer text");
   end Test_Plain_Printable_Still_Inserts_Text;

   procedure Test_Palette_Key_Input_Does_Not_Edit_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Cmd  : Editor.Commands.Command;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Prepare_Text ("");
      Editor.Input_Bridge.Handle_Key_Chord
        (Chord (Editor.Keybindings.Key_P, Ctrl => True, Shift => True));
      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'x';
      Cmd.Text := To_Unbounded_String (String'(1 => 'x'));
      Cmd.Code := Wide_Wide_Character'Val (Character'Pos ('x'));
      Editor.Input_Bridge.Handle (Cmd);
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert (Snap.Length = 0, "Palette input must not edit buffer text");
      Assert
        (To_String (Editor.Command_Palette.Current.Query) = "x",
         "Palette input must update the query");
   end Test_Palette_Key_Input_Does_Not_Edit_Buffer;

   procedure Test_Shift_Left_Extends_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Cmd  : Editor.Commands.Command;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Prepare_Text ("abc");
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Goto_End);
      Editor.Input_Bridge.Handle (Cmd);
      Editor.Input_Bridge.Handle_Key_Chord
        (Chord (Editor.Keybindings.Key_Left, Shift => True));
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert (Snap.Caret_Count > 0, "Snapshot must contain a caret");
      Assert
        (Snap.Selection_Count > 0,
         "Shift+Left must extend selection instead of collapsing the anchor");
   end Test_Shift_Left_Extends_Selection;

   procedure Test_Navigation_Key_Moves_Caret
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Cmd  : Editor.Commands.Command;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Prepare_Text ("abc");
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Goto_End);
      Editor.Input_Bridge.Handle (Cmd);
      Editor.Input_Bridge.Handle_Key_Chord
        (Chord (Editor.Keybindings.Key_Left));
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert
        (Snap.Caret_Count > 0 and then Natural (Snap.Caret_Pos (1)) = 2,
         "Left key must move the caret left through keybinding dispatch");
   end Test_Navigation_Key_Moves_Caret;

   procedure Test_Escape_Clears_Extra_Carets_When_No_Palette
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abcdef");
      S.Carets.Append
        (Editor.Cursors.Caret_State'
           (Pos                   => 3,
            Anchor                => 3,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));
      Editor.State.Normalize_Carets (S);
      Editor.Input_Bridge.Set_State_For_Test (S);

      Editor.Input_Bridge.Handle_Key_Chord
        (Chord (Editor.Keybindings.Key_Escape));
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);

      Assert
        (Snap.Caret_Count = 1,
         "Escape must preserve existing no-overlay cancel semantics by clearing extra carets");
   end Test_Escape_Clears_Extra_Carets_When_No_Palette;

   procedure Test_Palette_And_Keybindings_Share_Command_Id
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Bound : Editor.Commands.Command_Id;
      Seen  : Boolean := False;
      Descs : Editor.Commands.Command_Descriptor_Vectors.Vector :=
        Editor.Commands.Palette_Commands;
   begin
      Assert
        (Editor.Keybindings.Resolve
           (Chord (Editor.Keybindings.Key_S, Ctrl => True), Bound)
         = Editor.Keybindings.Bound_Command,
         "Ctrl+S must resolve");

      for Desc of Descs loop
         if Desc.Id = Bound then
            Seen := True;
         end if;
      end loop;

      Assert
        (Seen and then Bound = Editor.Commands.Command_Save_File,
         "Palette descriptors and keybindings must share the Save command ID");

      Seen := False;
      Bound := Editor.Commands.Command_Move_Left;
      Assert
        (Editor.Keybindings.Resolve
           (Chord (Editor.Keybindings.Key_S, Ctrl => True, Shift => True), Bound)
         = Editor.Keybindings.Bound_Command,
         "Ctrl+Shift+S should invoke Save As after target acquisition is canonical");
      Assert
        (Bound = Editor.Commands.Command_Save_File_As,
         "Save As chord must carry the canonical command target");

      for Desc of Descs loop
         if Desc.Id = Editor.Commands.Command_Save_File_As then
            Seen := True;
         end if;
      end loop;

      Assert
        (Seen,
         "Palette should project canonical Save As after target acquisition is canonical");
      Assert
        (Editor.Commands.Is_Bindable_Command (Editor.Commands.Command_Save_File_As),
         "Save As should be bindable after target acquisition is canonical");
   end Test_Palette_And_Keybindings_Share_Command_Id;

   procedure Test_Bookmark_Keybindings_Dispatch_Through_Executor
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "0" & ASCII.LF & "1" & ASCII.LF & "2");
      Editor.Input_Bridge.Set_State_For_Test (S);

      Editor.Input_Bridge.Handle_Key_Chord
        (Chord (Editor.Keybindings.Key_F2, Ctrl => True));
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert
        (Editor.Gutter_Markers.Has_Marker
           (Snap.Gutter_Markers, 0, Editor.Gutter_Markers.Bookmark_Marker),
         "Ctrl+F2 must dispatch Toggle Bookmark through the executor path");

      Editor.Input_Bridge.Handle_Key_Chord
        (Chord (Editor.Keybindings.Key_Down));
      Editor.Input_Bridge.Handle_Key_Chord
        (Chord (Editor.Keybindings.Key_Down));
      Editor.Input_Bridge.Handle_Key_Chord
        (Chord (Editor.Keybindings.Key_F2, Ctrl => True));
      Editor.Input_Bridge.Handle_Key_Chord
        (Chord (Editor.Keybindings.Key_Up));

      Editor.Input_Bridge.Handle_Key_Chord
        (Chord (Editor.Keybindings.Key_F2));
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert
        (Snap.Caret_Count > 0 and then Natural (Snap.Caret_Pos (1)) = 4,
         "F2 must dispatch Next Bookmark through the executor path");

      Editor.Input_Bridge.Handle_Key_Chord
        (Chord (Editor.Keybindings.Key_F2, Shift => True));
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert
        (Snap.Caret_Count > 0 and then Natural (Snap.Caret_Pos (1)) = 0,
         "Shift+F2 must dispatch Previous Bookmark through the executor path");

      Editor.Input_Bridge.Handle_Key_Chord
        (Chord (Editor.Keybindings.Key_F2, Ctrl => True, Shift => True));
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert
        (not Editor.Gutter_Markers.Has_Bookmarks (Snap.Gutter_Markers),
         "Ctrl+Shift+F2 must dispatch Clear Bookmarks through the executor path");
   end Test_Bookmark_Keybindings_Dispatch_Through_Executor;



   procedure Test_Format_Chord
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Keybindings.Format_Chord
           (Chord (Editor.Keybindings.Key_S, Ctrl => True)) = "Ctrl+S",
         "Format_Chord must format Ctrl+S");
      Assert
        (Editor.Keybindings.Format_Chord
           (Chord (Editor.Keybindings.Key_F, Ctrl => True, Shift => True)) =
           "Ctrl+Shift+F",
         "Format_Chord must format Ctrl+Shift+F");
      Assert
        (Editor.Keybindings.Format_Chord
           (Chord (Editor.Keybindings.Key_F3, Shift => True)) = "Shift+F3",
         "Format_Chord must format Shift+F3");
      Assert
        (Editor.Keybindings.Format_Chord
           (Chord (Editor.Keybindings.Key_Escape)) = "Escape",
         "Format_Chord must format Escape");
      Assert
        (Editor.Keybindings.Format_Chord
           (Chord (Editor.Keybindings.Key_Enter)) = "Enter",
         "Format_Chord must format Enter");
      Assert
        (Editor.Keybindings.Format_Chord
           (Chord (Editor.Keybindings.Key_Left, Alt => True)) = "Alt+Left",
         "Format_Chord must format arrow keys with modifiers");
   end Test_Format_Chord;

   procedure Test_Primary_Binding_For_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Info : Editor.Keybindings.Command_Keybinding_Info;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Info := Editor.Keybindings.Primary_Binding_For_Command
        (Editor.Commands.Command_Save_File);
      Assert (Info.Has_Binding,
              "Save File must have a primary keybinding");
      Assert (To_String (Info.Display) = "Ctrl+S",
              "Save File primary binding must be Ctrl+S");

      Info := Editor.Keybindings.Primary_Binding_For_Command
        (Editor.Commands.Command_Build_Run);
      Assert (not Info.Has_Binding,
              "Unbound visible commands must report no primary binding");
      Assert (Length (Info.Display) = 0,
              "Unbound commands must not carry stale display text");
   end Test_Primary_Binding_For_Command;

   procedure Test_Binding_Count_And_Order
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      First  : Editor.Keybindings.Key_Chord;
      Second : Editor.Keybindings.Key_Chord;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Assert
        (Editor.Keybindings.Binding_Count_For_Command
           (Editor.Commands.Command_Redo) = 2,
         "Redo must expose both default bindings");

      First := Editor.Keybindings.Binding_For_Command
        (Editor.Commands.Command_Redo, 1);
      Second := Editor.Keybindings.Binding_For_Command
        (Editor.Commands.Command_Redo, 2);

      Assert (Editor.Keybindings.Format_Chord (First) = "Ctrl+Y",
              "Binding_For_Command must preserve registry order");
      Assert (Editor.Keybindings.Format_Chord (Second) = "Ctrl+Shift+Z",
              "Binding_For_Command must preserve second binding order");
   end Test_Binding_Count_And_Order;

   procedure Test_Reverse_Lookup_Does_Not_Mutate
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Actual : Editor.Commands.Command_Id;
      Info   : Editor.Keybindings.Command_Keybinding_Info;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Assert
        (Editor.Keybindings.Resolve
           (Chord (Editor.Keybindings.Key_S, Ctrl => True), Actual)
         = Editor.Keybindings.Bound_Command
         and then Actual = Editor.Commands.Command_Save_File,
         "Ctrl+S must resolve before reverse lookup");

      Info := Editor.Keybindings.Primary_Binding_For_Command
        (Editor.Commands.Command_Save_File);
      Assert (Info.Has_Binding, "Reverse lookup must find Save File");

      Assert
        (Editor.Keybindings.Resolve
           (Chord (Editor.Keybindings.Key_S, Ctrl => True), Actual)
         = Editor.Keybindings.Bound_Command
         and then Actual = Editor.Commands.Command_Save_File,
         "Ctrl+S must resolve after reverse lookup without mutation");
   end Test_Reverse_Lookup_Does_Not_Mutate;


   procedure Test_Parse_Format_Chord
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Found  : Boolean := False;
      Parsed : Editor.Keybindings.Key_Chord;
   begin
      Parsed := Editor.Keybindings.Parse_Chord ("Ctrl+Alt+Shift+S", Found);
      Assert (Found, "chord parser must accept canonical modifiers");
      Assert
        (Editor.Keybindings.Format_Chord (Parsed) = "Ctrl+Alt+Shift+S",
         "chord formatter must be byte-stable");

      Parsed := Editor.Keybindings.Parse_Chord ("", Found);
      pragma Unreferenced (Parsed);
      Assert (not Found, "chord parser must reject empty chords");
   end Test_Parse_Format_Chord;

   procedure Test_Config_Apply_Override_And_Unbind
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Config : Editor.Keybinding_Config.Keybinding_Config_Model;
      Actual : Editor.Commands.Command_Id;
   begin
      Editor.Keybinding_Config.Clear (Config);
      Editor.Keybinding_Config.Bind
        (Config,
         Editor.Commands.Command_Save_File,
         Chord (Editor.Keybindings.Key_S, Ctrl => True, Alt => True));
      Editor.Keybinding_Config.Apply_To_Runtime (Config);

      Assert
        (Editor.Keybindings.Resolve
           (Chord (Editor.Keybindings.Key_S, Ctrl => True, Alt => True), Actual)
         = Editor.Keybindings.Bound_Command
         and then Actual = Editor.Commands.Command_Save_File,
         "applied override must route the new chord");
      Assert
        (Editor.Keybindings.Resolve
           (Chord (Editor.Keybindings.Key_S, Ctrl => True), Actual)
         = Editor.Keybindings.No_Binding,
         "moved command must remove its old default chord");

      Editor.Keybinding_Config.Unbind (Config, Editor.Commands.Command_Save_File);
      Editor.Keybinding_Config.Apply_To_Runtime (Config);
      Assert
        (Editor.Keybindings.Resolve
           (Chord (Editor.Keybindings.Key_S, Ctrl => True), Actual)
         = Editor.Keybindings.No_Binding,
         "explicit unbind must suppress the default chord");

      Editor.Keybindings.Reset_To_Defaults;
   end Test_Config_Apply_Override_And_Unbind;

   procedure Test_Stable_Command_Name_Roundtrip
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id;
   begin
      Assert
        (Editor.Commands.Stable_Command_Name (Editor.Commands.Command_Save_File)
         = "file.save",
         "stable command name must not be the user-facing label");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("file.save", Found);
      Assert
        (Found and then Id = Editor.Commands.Command_Save_File,
         "stable command name must resolve to its command id");
      Assert
        (Editor.Commands.Stable_Command_Name (Editor.Commands.Command_Open_File)
         = "file.open",
         "open-file command exports canonical stable name");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("open-file", Found);
      Assert
        (Found and then Id = Editor.Commands.Command_Open_File,
         "legacy open-file keybinding name remains loadable");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Diagnostics_Show) = "diagnostics.show",
         "diagnostics command exports canonical stable name");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("diagnostics-show", Found);
      Assert
        (Found and then Id = Editor.Commands.Command_Diagnostics_Show,
         "legacy diagnostics-show keybinding name remains loadable");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Open_Quick_Open) = "quick-open.show",
         "quick-open command exports canonical stable name");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("project.quick-open.show", Found);
      Assert
        (Found and then Id = Editor.Commands.Command_Open_Quick_Open,
         "legacy project.quick-open.show keybinding name remains loadable");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Accept_Quick_Open) = "quick-open.open-selected",
         "quick-open accept command exports canonical stable name");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("project.quick-open.open-selected", Found);
      Assert
        (Found and then Id = Editor.Commands.Command_Accept_Quick_Open,
         "legacy project.quick-open.open-selected keybinding name remains loadable");
      Assert
        (Editor.Commands.Is_Bindable_Command (Editor.Commands.Command_Save_Keybindings),
         "keybinding commands must be bindable concrete commands");
      Assert
        (not Editor.Commands.Is_Bindable_Command (Editor.Commands.No_Command),
         "No_Command must not be bindable");
   end Test_Stable_Command_Name_Roundtrip;


   procedure Test_Command_Name_Audit
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Found : Boolean := False;
      Round : Editor.Commands.Command_Id;
   begin
      Assert
        (not Editor.Commands.Is_Bindable_Command (Editor.Commands.No_Command),
         "No_Command must remain unbindable");

      for Id in Editor.Commands.Command_Id loop
         if Editor.Commands.Is_Bindable_Command (Id) then
            declare
               Name : constant String := Editor.Commands.Stable_Command_Name (Id);
            begin
               Assert (Name'Length > 0, "Bindable command must have a stable name");
               Assert
                 (Name = Ada.Characters.Handling.To_Lower (Name),
                  "Stable command names must be lowercase: " & Name);
               for C of Name loop
                  Assert
                    (C /= ' ' and then C /= ASCII.HT,
                     "Stable command names must not contain whitespace: " & Name);
               end loop;

               Round := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
               Assert
                 (Found and then Round = Id,
                  "Stable command names must round-trip: " & Name);

               for Other in Editor.Commands.Command_Id loop
                  if Other /= Id and then Editor.Commands.Is_Bindable_Command (Other) then
                     Assert
                       (Editor.Commands.Stable_Command_Name (Other) /= Name,
                        "Stable command names must be unique: " & Name);
                  end if;
               end loop;
            end;
         end if;
      end loop;
   end Test_Command_Name_Audit;

   procedure Test_Parse_Chord_Hardening
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Found  : Boolean := False;
      Parsed : Editor.Keybindings.Key_Chord;
   begin
      Parsed := Editor.Keybindings.Parse_Chord ("Shift+Ctrl+S", Found);
      Assert (Found, "Equivalent modifier order should parse");
      Assert
        (Editor.Keybindings.Format_Chord (Parsed) = "Ctrl+Shift+S",
         "Equivalent modifier order must normalize on format");

      Parsed := Editor.Keybindings.Parse_Chord ("Ctrl+Ctrl+S", Found);
      Assert (not Found, "Duplicate modifiers must be rejected");
      Parsed := Editor.Keybindings.Parse_Chord ("Ctrl++S", Found);
      Assert (not Found, "Malformed separators must be rejected");
      Parsed := Editor.Keybindings.Parse_Chord ("Hyper+S", Found);
      Assert (not Found, "Unknown modifiers must be rejected");
      Parsed := Editor.Keybindings.Parse_Chord ("Ctrl+Bogus", Found);
      Assert (not Found, "Unknown keys must be rejected");
      Parsed := Editor.Keybindings.Parse_Chord ("S", Found);
      Assert (not Found, "Bare text keys must not become persisted shortcuts");
      Parsed := Editor.Keybindings.Parse_Chord ("Escape", Found);
      Assert (Found, "Non-text command keys may be unmodified chords");
   end Test_Parse_Chord_Hardening;

   procedure Test_Runtime_Validation_Summary
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Result : Editor.Keybindings.Keybinding_Validation_Result;
      Sum    : Editor.Keybindings.Keybinding_Validation_Summary;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Result := Editor.Keybindings.Validate;
      Sum := Editor.Keybindings.Summary (Result);
      Assert
        (Editor.Keybindings.Status (Result) = Editor.Keybindings.Valid_Keybindings,
         "Default runtime keybindings must validate");
      Assert
        (Sum.Bound_Command_Count > 0,
         "Validation summary must count bound commands");
      Assert
        (Sum.Conflict_Count = 0 and then Sum.Invalid_Count = 0,
         "Default runtime keybindings must not have conflicts or invalid targets");
   end Test_Runtime_Validation_Summary;

   procedure Test_Config_Load_Conflict_Last_Wins
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Path   : constant String := Temp_Path ("conflict_last_wins");
      Config : Editor.Keybinding_Config.Keybinding_Config_Model;
      Status : Editor.Keybinding_Config.Keybinding_Config_Status;
      Actual : Editor.Commands.Command_Id;
      Found  : Boolean := False;
      C      : Editor.Keybindings.Key_Chord;
   begin
      Write_File
        (Path,
         "editor-keybindings-version=1" & ASCII.LF &
         "[bindings]" & ASCII.LF &
         "file.save=Ctrl+P" & ASCII.LF &
         "quick-open.show=Ctrl+P" & ASCII.LF);

      Editor.Keybinding_Config.Load_From_File (Path, Config, Status);
      Assert
        (Status = Editor.Keybinding_Config.Keybinding_Config_Partial_Load,
         "Duplicate chord load must be partial");
      Editor.Keybinding_Config.Apply_To_Runtime (Config);
      Assert
        (Editor.Keybindings.Resolve
           (Chord (Editor.Keybindings.Key_P, Ctrl => True), Actual)
         = Editor.Keybindings.Bound_Command
         and then Actual = Editor.Commands.Command_Open_Quick_Open,
         "Last valid duplicate chord owner must win");
      C := Editor.Keybinding_Config.Chord_For
        (Config, Editor.Commands.Command_Save_File, Found);
      pragma Unreferenced (C);
      Assert (not Found, "Displaced command must have no explicit conflicting chord");
      Editor.Keybindings.Reset_To_Defaults;
   end Test_Config_Load_Conflict_Last_Wins;

   procedure Test_Config_Unbind_Load_And_Reset
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Path   : constant String := Temp_Path ("unbind");
      Config : Editor.Keybinding_Config.Keybinding_Config_Model;
      Status : Editor.Keybinding_Config.Keybinding_Config_Status;
      Actual : Editor.Commands.Command_Id;
   begin
      Write_File
        (Path,
         "editor-keybindings-version=1" & ASCII.LF &
         "[bindings]" & ASCII.LF &
         "file.save=none" & ASCII.LF);
      Editor.Keybinding_Config.Load_From_File (Path, Config, Status);
      Assert
        (Status = Editor.Keybinding_Config.Keybinding_Config_Ok,
         "Explicit unbind must load cleanly");
      Editor.Keybinding_Config.Apply_To_Runtime (Config);
      Assert
        (Editor.Keybindings.Resolve
           (Chord (Editor.Keybindings.Key_S, Ctrl => True), Actual)
         = Editor.Keybindings.No_Binding,
         "Explicit unbind must remove the default chord at runtime");
      Editor.Keybindings.Reset_To_Defaults;
      Assert
        (Editor.Keybindings.Resolve
           (Chord (Editor.Keybindings.Key_S, Ctrl => True), Actual)
         = Editor.Keybindings.Bound_Command
         and then Actual = Editor.Commands.Command_Save_File,
         "Reset must restore the built-in default chord");
   end Test_Config_Unbind_Load_And_Reset;

   procedure Test_Invalid_And_Partial_Load_Statuses
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Path   : constant String := Temp_Path ("invalid_status");
      Config : Editor.Keybinding_Config.Keybinding_Config_Model;
      Status : Editor.Keybinding_Config.Keybinding_Config_Status;
      Found  : Boolean := False;
      C      : Editor.Keybindings.Key_Chord;
   begin
      Write_File (Path, "[bindings]" & ASCII.LF & "file.save=Ctrl+S" & ASCII.LF);
      Editor.Keybinding_Config.Load_From_File (Path, Config, Status);
      Assert
        (Status = Editor.Keybinding_Config.Keybinding_Config_Invalid_Format,
         "Missing required header must be hard invalid");

      Write_File (Path, "editor-keybindings-version=99" & ASCII.LF & "[bindings]" & ASCII.LF);
      Editor.Keybinding_Config.Load_From_File (Path, Config, Status);
      Assert
        (Status = Editor.Keybinding_Config.Keybinding_Config_Unsupported_Version,
         "Unsupported keybinding version must be a hard failure");

      Write_File
        (Path,
         "editor-keybindings-version=1" & ASCII.LF &
         "[bindings]" & ASCII.LF &
         "file.save=Ctrl+Alt+S" & ASCII.LF &
         "unknown-command=Ctrl+W" & ASCII.LF &
         "open-active-find-prompt=S" & ASCII.LF);
      Editor.Keybinding_Config.Load_From_File (Path, Config, Status);
      Assert
        (Status = Editor.Keybinding_Config.Keybinding_Config_Partial_Load,
         "Mixed valid and invalid bindings must be partial");
      C := Editor.Keybinding_Config.Chord_For
        (Config, Editor.Commands.Command_Save_File, Found);
      Assert
        (Found and then Editor.Keybindings.Format_Chord (C) = "Ctrl+Alt+S",
         "Partial load must preserve valid normalized bindings");
   end Test_Invalid_And_Partial_Load_Statuses;

   procedure Test_Serialization_Stable_And_Drops_Invalid
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Path   : constant String := Temp_Path ("serialization");
      Config : Editor.Keybinding_Config.Keybinding_Config_Model;
      Status : Editor.Keybinding_Config.Keybinding_Config_Status;
      Text   : Unbounded_String;
      Actual : Editor.Commands.Command_Id;
   begin
      Editor.Keybinding_Config.Clear (Config);
      Editor.Keybinding_Config.Bind
        (Config,
         Editor.Commands.Command_Save_File,
         Chord (Editor.Keybindings.Key_S, Ctrl => True, Alt => True));
      Editor.Keybinding_Config.Unbind
        (Config, Editor.Commands.Command_Open_Quick_Open);
      Editor.Keybinding_Config.Apply_To_Runtime (Config);
      Editor.Keybinding_Config.Build_From_Runtime (Config);
      Assert
        (Editor.Keybindings.Resolve
           (Chord (Editor.Keybindings.Key_Z, Ctrl => True, Shift => True), Actual)
         = Editor.Keybindings.Bound_Command
         and then Actual = Editor.Commands.Command_Redo,
         "Build_From_Runtime must not drop secondary active runtime bindings");
      Editor.Keybinding_Config.Save_To_File (Config, Path, Status);
      Assert
        (Status = Editor.Keybinding_Config.Keybinding_Config_Ok,
         "Serialized keybindings must save rebuilt runtime state successfully");
      Text := To_Unbounded_String (File_Contents (Path));
      Assert
        (Ada.Strings.Fixed.Index (To_String (Text), "editor-keybindings-version=1") > 0,
         "Serialized keybindings must include version header");
      Assert
        (Ada.Strings.Fixed.Index (To_String (Text), "project.quick-open.show=none") = 0,
         "Explicit quick-open unbind must not serialize legacy command name");
      Assert
        (Ada.Strings.Fixed.Index (To_String (Text), "quick-open.show=none") > 0,
         "Explicit quick-open unbind must be serialized with canonical command name");
      Assert
        (Ada.Strings.Fixed.Index (To_String (Text), "file.save=Ctrl+Alt+S") > 0,
         "Custom chord must be serialized canonically");
      Editor.Keybindings.Reset_To_Defaults;
   end Test_Serialization_Stable_And_Drops_Invalid;

   procedure Test_Command_Palette_Uses_Active_Bindings
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Config     : Editor.Keybinding_Config.Keybinding_Config_Model;
      Seen       : Boolean := False;
   begin
      Editor.Command_Palette.Reset;
      Editor.State.Init (S);
      Editor.Keybinding_Config.Clear (Config);
      Editor.Keybinding_Config.Bind
        (Config,
         Editor.Commands.Command_Save_File,
         Chord (Editor.Keybindings.Key_S, Ctrl => True, Alt => True));
      Editor.Keybinding_Config.Apply_To_Runtime (Config);
      Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, Candidates);
      for Candidate of Candidates loop
         if Candidate.Id = Editor.Commands.Command_Save_File then
            Seen := True;
            Assert
              (Candidate.Has_Keybinding,
               "Save File candidate must show active remapped binding");
            Assert
              (To_String (Candidate.Keybinding_Display) = "Ctrl+Alt+S",
               "Command palette must display active runtime binding");
         end if;
      end loop;
      Assert (Seen, "Save File command must be present in palette candidates");
      Editor.Keybindings.Reset_To_Defaults;
   end Test_Command_Palette_Uses_Active_Bindings;


   procedure Test_Chord_Syntax_Finalization
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Found  : Boolean := False;
      Parsed : Editor.Keybindings.Key_Chord;

      procedure Expect_Valid (Text : String; Canonical : String) is
      begin
         Parsed := Editor.Keybindings.Parse_Chord (Text, Found);
         Assert (Found, "valid chord rejected: " & Text);
         Assert
           (Editor.Keybindings.Format_Chord (Parsed) = Canonical,
            "chord did not format canonically: " & Text);
      end Expect_Valid;

      procedure Expect_Invalid (Text : String) is
      begin
         Parsed := Editor.Keybindings.Parse_Chord (Text, Found);
         Assert (not Found, "invalid chord accepted: " & Text);
      end Expect_Invalid;
   begin
      Expect_Valid ("Ctrl+S", "Ctrl+S");
      Expect_Valid ("Ctrl+Shift+S", "Ctrl+Shift+S");
      Expect_Valid ("Ctrl+Alt+P", "Ctrl+Alt+P");
      Expect_Valid ("Ctrl+Alt+Shift+P", "Ctrl+Alt+Shift+P");
      Expect_Valid ("Meta+P", "Meta+P");
      Expect_Valid ("Shift+F3", "Shift+F3");
      Expect_Valid ("F1", "F1");
      Expect_Valid ("F12", "F12");
      Expect_Valid ("Escape", "Escape");
      Expect_Valid ("Enter", "Enter");
      Expect_Valid ("Tab", "Tab");
      Expect_Valid ("Backspace", "Backspace");
      Expect_Valid ("Delete", "Delete");
      Expect_Valid ("Left", "Left");
      Expect_Valid ("Right", "Right");
      Expect_Valid ("Up", "Up");
      Expect_Valid ("Down", "Down");
      Expect_Valid ("Home", "Home");
      Expect_Valid ("End", "End");
      Expect_Valid ("PageUp", "PageUp");
      Expect_Valid ("PageDown", "PageDown");

      Expect_Invalid ("");
      Expect_Invalid ("Ctrl+");
      Expect_Invalid ("+S");
      Expect_Invalid ("Ctrl++S");
      Expect_Invalid ("Ctrl+Ctrl+S");
      Expect_Invalid ("Hyper+S");
      Expect_Invalid ("Ctrl+UnknownKey");
      Expect_Invalid ("Ctrl+none");
      Expect_Invalid ("none+Ctrl");
      Expect_Invalid ("Ctrl+Shift+");
      Expect_Invalid ("Ctrl Shift S");
   end Test_Chord_Syntax_Finalization;

   procedure Test_Hard_Failed_Reload_Preservation_Model
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Path   : constant String := Temp_Path ("invalid_preserve");
      Config : Editor.Keybinding_Config.Keybinding_Config_Model;
      Status : Editor.Keybinding_Config.Keybinding_Config_Status;
      Actual : Editor.Commands.Command_Id;
   begin
      Editor.Keybinding_Config.Clear (Config);
      Editor.Keybinding_Config.Bind
        (Config,
         Editor.Commands.Command_Save_File,
         Chord (Editor.Keybindings.Key_S, Ctrl => True, Alt => True));
      Editor.Keybinding_Config.Apply_To_Runtime (Config);

      Write_File
        (Path,
         "not-a-keybinding-file" & ASCII.LF &
         "file.save=Ctrl+S" & ASCII.LF);
      Editor.Keybinding_Config.Load_From_File (Path, Config, Status);
      Assert
        (Status = Editor.Keybinding_Config.Keybinding_Config_Invalid_Format,
         "Invalid keybinding headers must be hard failures");

      Assert
        (Editor.Keybindings.Resolve
           (Chord (Editor.Keybindings.Key_S, Ctrl => True, Alt => True), Actual)
         = Editor.Keybindings.Bound_Command
         and then Actual = Editor.Commands.Command_Save_File,
         "Hard-failed loads must not mutate active runtime keybindings unless applied");
      Assert
        (Editor.Keybindings.Resolve
           (Chord (Editor.Keybindings.Key_S, Ctrl => True), Actual)
         /= Editor.Keybindings.Bound_Command
         or else Actual /= Editor.Commands.Command_Save_File,
         "Hard-failed loads must not restore stale default routing");
      Editor.Keybindings.Reset_To_Defaults;
   end Test_Hard_Failed_Reload_Preservation_Model;

   procedure Test_Command_Route_Audit_Helper
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Audit : Editor.Command_Route_Audit.Route_Audit_Result;
   begin
      Editor.Command_Route_Audit.Clear (Audit);
      Editor.Command_Route_Audit.Record_Route
        (Audit,
         Editor.Command_Route_Audit.Route_From_Keybinding,
         Editor.Commands.Command_Save_File);
      Editor.Command_Route_Audit.Record_Route
        (Audit,
         Editor.Command_Route_Audit.Route_From_Command_Palette,
         Editor.Commands.Command_Open_Command_Palette);
      Assert
        (Editor.Command_Route_Audit.Failure_Count (Audit) = 0,
         "Concrete command-id routes must audit cleanly: " &
         Editor.Command_Route_Audit.Summary (Audit));

      Editor.Command_Route_Audit.Record_Route
        (Audit,
         Editor.Command_Route_Audit.Route_From_Test,
         Editor.Commands.No_Command);
      Assert
        (Editor.Command_Route_Audit.Failure_Count (Audit) = 1,
         "No_Command must be reported as an invalid command route");
   end Test_Command_Route_Audit_Helper;

   procedure Test_Bindability_And_Default_Table_Audit
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Result : Editor.Keybindings.Keybinding_Validation_Result;
      Name   : Unbounded_String;
   begin
      Assert
        (not Editor.Commands.Is_Bindable_Command (Editor.Commands.No_Command),
         "No_Command must never be bindable");

      for Id in Editor.Commands.Command_Id loop
         if Editor.Commands.Is_Bindable_Command (Id) then
            Name := To_Unbounded_String (Editor.Commands.Stable_Command_Name (Id));
            Assert (Length (Name) > 0, "Bindable command lacks stable name");
            Assert
              (To_String (Name) /= Editor.Commands.Label (Id),
               "Stable command names must not be derived from labels at runtime: " &
               To_String (Name));
         end if;
      end loop;

      Editor.Keybindings.Reset_To_Defaults;
      Result := Editor.Keybindings.Validate;
      Assert
        (Editor.Keybindings.Status (Result) = Editor.Keybindings.Valid_Keybindings,
         "Default keybinding table must be conflict-free and bind only bindable commands");
   end Test_Bindability_And_Default_Table_Audit;


   procedure Test_Outline_Keybindings_Register_Defaults
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Result : Editor.Keybindings.Default_Keybinding_Registration_Result;
   begin
      Editor.Keybindings.Clear;
      Result := Editor.Keybindings.Register_Outline_Keybindings;
      Assert (Result.Requested_Count = 6,
              "outline default registration should consider six conservative chords");
      Assert (Result.Registered_Count = 6 and then Result.Conflict_Count = 0,
              "outline defaults should register into an empty keybinding table");
      Assert_Resolves
        (Chord (Editor.Keybindings.Key_F12, Ctrl => True),
         Editor.Commands.Command_Refresh_Outline,
         "Ctrl+F12 refresh outline");
      Assert_Resolves
        (Chord (Editor.Keybindings.Key_Enter, Alt => True),
         Editor.Commands.Command_Open_Selected_Outline_Item,
         "Alt+Enter open selected outline item");
      Assert_Resolves
        (Chord (Editor.Keybindings.Key_F3, Alt => True),
         Editor.Commands.Command_Select_Next_Outline_Item,
         "Alt+F3 select next outline item");
      Assert_Resolves
        (Chord (Editor.Keybindings.Key_F3, Alt => True, Shift => True),
         Editor.Commands.Command_Select_Previous_Outline_Item,
         "Alt+Shift+F3 select previous outline item");
      Assert_Resolves
        (Chord (Editor.Keybindings.Key_F12, Alt => True),
         Editor.Commands.Command_Select_Current_Outline_Symbol,
         "Alt+F12 select current outline symbol");
      Assert_Resolves
        (Chord (Editor.Keybindings.Key_F12, Alt => True, Shift => True),
         Editor.Commands.Command_Reveal_Current_Outline_Symbol,
         "Alt+Shift+F12 reveal current outline symbol");
   end Test_Outline_Keybindings_Register_Defaults;

   procedure Test_Daily_Workflow_Keybindings_Register_Defaults
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Result : Editor.Keybindings.Default_Keybinding_Registration_Result;
   begin
      Editor.Keybindings.Clear;
      Result := Editor.Keybindings.Register_Daily_Workflow_Keybindings;
      Assert (Result.Requested_Count = 4,
              "daily workflow defaults should consider four conservative chords");
      Assert (Result.Registered_Count = 4 and then Result.Conflict_Count = 0,
              "daily workflow defaults should register into an empty keybinding table");
      Assert_Resolves
        (Chord (Editor.Keybindings.Key_F1),
         Editor.Commands.Command_Palette_Show_Command_Help,
         "F1 command help");
      Assert_Resolves
        (Chord (Editor.Keybindings.Key_O, Ctrl => True),
         Editor.Commands.Command_Open_File,
         "Ctrl+O open file");
      Assert_Resolves
        (Chord (Editor.Keybindings.Key_O, Ctrl => True, Alt => True),
         Editor.Commands.Command_Open_Project,
         "Ctrl+Alt+O open project");
      Assert_Resolves
        (Chord (Editor.Keybindings.Key_M, Ctrl => True, Alt => True),
         Editor.Commands.Command_Diagnostics_Show,
         "Ctrl+Alt+M diagnostics");
   end Test_Daily_Workflow_Keybindings_Register_Defaults;

   procedure Test_Daily_Workflow_Keybindings_Do_Not_Overwrite_User_Bindings
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Result : Editor.Keybindings.Default_Keybinding_Registration_Result;
      User_Chord : constant Editor.Keybindings.Key_Chord :=
        Chord (Editor.Keybindings.Key_O, Ctrl => True);
   begin
      Editor.Keybindings.Clear;
      Editor.Keybindings.Bind
        (User_Chord, Editor.Commands.Command_Open_Quick_Open);
      Result := Editor.Keybindings.Register_Daily_Workflow_Keybindings;
      Assert (Result.Requested_Count = 4,
              "daily workflow defaults should report every candidate chord");
      Assert (Result.Registered_Count = 3 and then Result.Conflict_Count = 1,
              "daily workflow defaults should count the occupied chord as a conflict");
      Assert_Resolves
        (User_Chord, Editor.Commands.Command_Open_Quick_Open,
         "daily workflow defaults must not overwrite user Ctrl+O binding");
   end Test_Daily_Workflow_Keybindings_Do_Not_Overwrite_User_Bindings;

   procedure Test_Daily_Workflow_Keybinding_Config_Defaults
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Config : Editor.Keybinding_Config.Keybinding_Config_Model;
      Found  : Boolean := False;
      Bound  : Editor.Keybindings.Key_Chord;
   begin
      Editor.Keybinding_Config.Set_Defaults (Config);

      Bound := Editor.Keybinding_Config.Chord_For
        (Config, Editor.Commands.Command_Palette_Show_Command_Help, Found);
      Assert
        (Found and then Editor.Keybindings.Format_Chord (Bound) = "F1",
         "daily workflow config defaults must expose F1 command help");

      Bound := Editor.Keybinding_Config.Chord_For
        (Config, Editor.Commands.Command_Open_File, Found);
      Assert
        (Found and then Editor.Keybindings.Format_Chord (Bound) = "Ctrl+O",
         "daily workflow config defaults must expose Ctrl+O open file");

      Bound := Editor.Keybinding_Config.Chord_For
        (Config, Editor.Commands.Command_Open_Project, Found);
      Assert
        (Found and then Editor.Keybindings.Format_Chord (Bound) = "Ctrl+Alt+O",
         "daily workflow config defaults must expose Ctrl+Alt+O open project");

      Bound := Editor.Keybinding_Config.Chord_For
        (Config, Editor.Commands.Command_Diagnostics_Show, Found);
      Assert
        (Found and then Editor.Keybindings.Format_Chord (Bound) = "Ctrl+Alt+M",
         "daily workflow config defaults must expose Ctrl+Alt+M diagnostics");
   end Test_Daily_Workflow_Keybinding_Config_Defaults;

   procedure Test_Outline_Keybindings_Do_Not_Overwrite_User_Bindings
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Result : Editor.Keybindings.Default_Keybinding_Registration_Result;
      User_Chord : constant Editor.Keybindings.Key_Chord :=
        Chord (Editor.Keybindings.Key_F3, Alt => True);
   begin
      Editor.Keybindings.Clear;
      Editor.Keybindings.Bind
        (User_Chord, Editor.Commands.Command_Active_Find_Next);
      Result := Editor.Keybindings.Register_Outline_Keybindings;
      Assert (Result.Requested_Count = 6,
              "outline keybinding registration should report all candidates");
      Assert (Result.Registered_Count = 5 and then Result.Conflict_Count = 1,
              "outline keybinding registration should skip one occupied chord");
      Assert_Resolves
        (User_Chord, Editor.Commands.Command_Active_Find_Next,
         "outline defaults must not overwrite an existing user chord");
   end Test_Outline_Keybindings_Do_Not_Overwrite_User_Bindings;

   procedure Test_Outline_Keybindings_Report_Conflicts_Deterministically
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      First  : Editor.Keybindings.Default_Keybinding_Registration_Result;
      Second : Editor.Keybindings.Default_Keybinding_Registration_Result;
   begin
      Editor.Keybindings.Clear;
      First := Editor.Keybindings.Register_Outline_Keybindings;
      Second := Editor.Keybindings.Register_Outline_Keybindings;
      Assert (First.Registered_Count = 6 and then First.Conflict_Count = 0,
              "first outline registration should populate every free candidate");
      Assert (Second.Requested_Count = 6
              and then Second.Registered_Count = 0
              and then Second.Conflict_Count = 6,
              "second outline registration should deterministically report all candidates as conflicts");
   end Test_Outline_Keybindings_Report_Conflicts_Deterministically;


   procedure Test_Display_List_Is_Deterministic_And_Scoped
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Previous_Name : Unbounded_String := Null_Unbounded_String;
      Current_Name  : Unbounded_String := Null_Unbounded_String;
      Id            : Editor.Commands.Command_Id;
      Info          : Editor.Keybindings.Command_Keybinding_Info;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Assert
        (Editor.Keybindings.Bound_Command_Count > 0,
         "display list must expose active bound commands");

      for I in 1 .. Editor.Keybindings.Bound_Command_Count loop
         Id := Editor.Keybindings.Bound_Command_At (I);
         Assert
           (Editor.Commands.Is_Bindable_Command (Id),
            "bound display must only list bindable commands");
         Assert
           (not Editor.Commands.Is_Public_Build_Command (Id),
            "bound display must not list public build commands");
         Assert
           (not Editor.Commands.Is_Internal_Build_Test_Seam_Command (Id),
            "bound display must not list internal build test seams");
         Info := Editor.Keybindings.Primary_Binding_For_Command (Id);
         Assert
           (Info.Has_Binding and then Length (Info.Display) > 0,
            "bound display rows must carry user-facing chord text");
         Current_Name := To_Unbounded_String (Editor.Commands.Stable_Command_Name (Id));
         if I > 1 then
            Assert
              (To_String (Previous_Name) < To_String (Current_Name),
               "bound display rows must be stable-name sorted");
         end if;
         Previous_Name := Current_Name;
      end loop;

      Assert
        (not Editor.Keybindings.Is_Normal_Assignable_Command
           (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam),
         "internal build test seam must be absent from assignable keybinding UI");
   end Test_Display_List_Is_Deterministic_And_Scoped;

   procedure Test_Assign_Validates_Targets_And_Replaces_Deterministically
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Status : Editor.Keybindings.Keybinding_Change_Status;
      Actual : Editor.Commands.Command_Id;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Keybindings.Assign
        (Chord (Editor.Keybindings.Key_S, Ctrl => True, Alt => True),
         Editor.Commands.Command_Save_File,
         Status);
      Assert
        (Status = Editor.Keybindings.Keybinding_Change_Ok,
         "valid assignment must succeed");
      Assert
        (Editor.Keybindings.Resolve
           (Chord (Editor.Keybindings.Key_S, Ctrl => True, Alt => True), Actual)
         = Editor.Keybindings.Bound_Command
         and then Actual = Editor.Commands.Command_Save_File,
         "assignment must resolve through active runtime table");
      Assert
        (Editor.Keybindings.Resolve
           (Chord (Editor.Keybindings.Key_S, Ctrl => True), Actual)
         = Editor.Keybindings.No_Binding,
         "assignment must replace the command's previous chord");

      Editor.Keybindings.Assign
        (Chord (Editor.Keybindings.Key_S, Ctrl => True, Alt => True),
         Editor.Commands.Command_Open_Quick_Open,
         Status);
      Assert
        (Status = Editor.Keybindings.Keybinding_Change_Ok,
         "duplicate chord replacement must be explicit and successful");
      Assert
        (Editor.Keybindings.Resolve
           (Chord (Editor.Keybindings.Key_S, Ctrl => True, Alt => True), Actual)
         = Editor.Keybindings.Bound_Command
         and then Actual = Editor.Commands.Command_Open_Quick_Open,
         "duplicate chord policy must be last-assignment-wins");
      Assert
        (Editor.Keybindings.Binding_Count_For_Command
           (Editor.Commands.Command_Save_File) = 0,
         "displaced command must not retain the conflicting user chord");
      Editor.Keybindings.Reset_To_Defaults;
   end Test_Assign_Validates_Targets_And_Replaces_Deterministically;

   procedure Test_Assign_Rejections_Are_Non_Mutating
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Status : Editor.Keybindings.Keybinding_Change_Status;
      Actual : Editor.Commands.Command_Id;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Assert
        (Editor.Keybindings.Resolve
           (Chord (Editor.Keybindings.Key_S, Ctrl => True), Actual)
         = Editor.Keybindings.Bound_Command
         and then Actual = Editor.Commands.Command_Save_File,
         "baseline save binding must exist before rejected assignment");

      Editor.Keybindings.Assign
        (Chord (Editor.Keybindings.Key_S, Ctrl => True, Alt => True),
         Editor.Commands.No_Command,
         Status);
      Assert
        (Status = Editor.Keybindings.Keybinding_Change_Invalid_Target,
         "No_Command assignment must be rejected as invalid");
      Assert
        (Editor.Keybindings.Resolve
           (Chord (Editor.Keybindings.Key_S, Ctrl => True), Actual)
         = Editor.Keybindings.Bound_Command
         and then Actual = Editor.Commands.Command_Save_File,
         "invalid assignment must leave existing bindings unchanged");

      Editor.Keybindings.Assign
        (Chord (Editor.Keybindings.Key_S, Ctrl => True, Alt => True),
         Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam,
         Status);
      Assert
        (Status = Editor.Keybindings.Keybinding_Change_Internal_Target
         or else Status = Editor.Keybindings.Keybinding_Change_Non_Bindable_Target,
         "internal build test seam assignment must be rejected");
      Assert
        (Editor.Keybindings.Resolve
           (Chord (Editor.Keybindings.Key_S, Ctrl => True), Actual)
         = Editor.Keybindings.Bound_Command
         and then Actual = Editor.Commands.Command_Save_File,
         "rejected internal target must leave existing bindings unchanged");
      Assert
        (Editor.Keybindings.Resolve
           (Chord (Editor.Keybindings.Key_S, Ctrl => True, Alt => True), Actual)
         = Editor.Keybindings.No_Binding,
         "rejected assignment must not create the requested chord");
      Editor.Keybindings.Reset_To_Defaults;
   end Test_Assign_Rejections_Are_Non_Mutating;

   procedure Test_Load_Rejects_Internal_Target_Without_Runtime_Mutation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Path   : constant String := Temp_Path ("internal_target");
      Config : Editor.Keybinding_Config.Keybinding_Config_Model;
      Status : Editor.Keybinding_Config.Keybinding_Config_Status;
      Actual : Editor.Commands.Command_Id;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Write_File
        (Path,
         "editor-keybindings-version=1" & ASCII.LF &
         "[bindings]" & ASCII.LF &
         "build.run-user-opt-in-test-seam=Ctrl+Alt+P" & ASCII.LF);
      Editor.Keybinding_Config.Load_From_File (Path, Config, Status);
      Assert
        (Status = Editor.Keybinding_Config.Keybinding_Config_Partial_Load,
         "internal build target in keybindings file must be rejected as partial");
      Editor.Keybinding_Config.Apply_To_Runtime (Config);
      Assert
        (Editor.Keybindings.Resolve
           (Chord (Editor.Keybindings.Key_P, Ctrl => True, Alt => True), Actual)
         = Editor.Keybindings.No_Binding,
         "rejected internal target must not become a runtime binding");
      Assert
        (Editor.Keybindings.Resolve
           (Chord (Editor.Keybindings.Key_S, Ctrl => True), Actual)
         = Editor.Keybindings.Bound_Command
         and then Actual = Editor.Commands.Command_Save_File,
         "partial load with no valid entries must keep defaults after apply");
      Editor.Keybindings.Reset_To_Defaults;
   end Test_Load_Rejects_Internal_Target_Without_Runtime_Mutation;


   procedure Test_Keybinding_User_Readable_Errors_And_No_Payloads
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Path : constant String := Temp_Path ("payload_rejection");
      Config : Editor.Keybinding_Config.Keybinding_Config_Model;
      Status : Editor.Keybinding_Config.Keybinding_Config_Status;
      Found  : Boolean := False;
   begin
      Write_File
        (Path,
         "editor-keybindings-version=1" & ASCII.LF
         & "[bindings]" & ASCII.LF
         & "file.save=Ctrl+S;candidate=123" & ASCII.LF
         & "edit.undo=Ctrl+Z" & ASCII.LF);

      Editor.Keybinding_Config.Load_From_File (Path, Config, Status);

      Assert
        (Status = Editor.Keybinding_Config.Keybinding_Config_Partial_Load,
         "payload-bearing keybinding entries must be ignored as partial load");
      Assert
        (Editor.Keybinding_Config.Status_Label (Status) =
           "Keybindings loaded with ignored invalid entries.",
         "partial load status must have a user-readable label");
      Assert
        (Editor.Keybinding_Config.Diagnostic_Label
           (Editor.Keybinding_Config.Unknown_Command) = "Unknown command.",
         "unknown command diagnostic must be user-readable");
      Assert
        (Editor.Keybinding_Config.Diagnostic_Label
           (Editor.Keybinding_Config.Invalid_Command_Name) =
             "Command is not bindable.",
         "non-bindable command diagnostic must be user-readable");
      Assert
        (Editor.Keybinding_Config.Diagnostic_Label
           (Editor.Keybinding_Config.Invalid_Chord) = "Chord is invalid.",
         "invalid chord diagnostic must be user-readable");
      Assert
        (Editor.Keybinding_Config.Diagnostic_Label
           (Editor.Keybinding_Config.Duplicate_Chord) =
             "Chord conflicts with existing binding.",
         "chord conflict diagnostic must be user-readable");
      Assert
        (Editor.Keybinding_Config.Diagnostic_Label
           (Editor.Keybinding_Config.Unsupported_Payload) =
             "Keybinding entry contains unsupported payload.",
         "payload diagnostic must be user-readable");
      Assert
        (Editor.Keybinding_Config.Keybinding_Value_Has_Unsupported_Payload
           ("Ctrl+S;candidate=123"),
         "payload detector must flag persisted executable arguments");
      Assert
        (not Editor.Keybinding_Config.Keybinding_Value_Has_Unsupported_Payload
           ("Ctrl+S"),
         "payload detector must allow plain chords");

      declare
         Ignored : constant Editor.Keybindings.Key_Chord :=
           Editor.Keybinding_Config.Chord_For
             (Config, Editor.Commands.Command_Save_File, Found);
         pragma Unreferenced (Ignored);
      begin
         Assert
           (not Found,
            "payload-bearing binding must not enter persisted config model");
      end;
   end Test_Keybinding_User_Readable_Errors_And_No_Payloads;



   procedure Test_Keybinding_List_Search_And_Filter
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Summary : Editor.Keybinding_Management.Keybinding_List_Summary;
      Row     : Editor.Keybinding_Management.Keybinding_Row_Snapshot;
      Found_Build : Boolean := False;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Keybinding_Management.Show;
      Editor.Keybinding_Management.Clear_Query;
      Editor.Keybinding_Management.Clear_Filter;
      Summary := Editor.Keybinding_Management.Summary;
      Assert (Summary.Row_Count > 0,
              "keybinding list must project command rows");
      Assert (Summary.Bound_Command_Count > 0,
              "keybinding list must expose active chords");
      Assert (Summary.Chord_Row_Count > 0,
              "keybinding list must expose active bindings by chord");
      declare
         Chord_Row : constant Editor.Keybinding_Management.Keybinding_Chord_Row_Snapshot :=
           Editor.Keybinding_Management.Chord_Row_At (1);
      begin
         Assert (Length (Chord_Row.Chord_Label) > 0,
                 "chord rows must expose normalized chord labels");
         Assert (Length (Chord_Row.Stable_Command_Name) > 0,
                 "chord rows must expose stable command names only");
      end;
      Editor.Keybinding_Management.Set_Query ("build");
      for I in 1 .. Editor.Keybinding_Management.Row_Count loop
         Row := Editor.Keybinding_Management.Row_At (I);
         if Ada.Strings.Fixed.Index
              (To_String (Row.Stable_Command_Name), "build") /= 0
         then
            Found_Build := True;
         end if;
      end loop;
      Assert (Found_Build,
              "search must match stable command names/descriptions");

      Editor.Keybinding_Management.Clear_Query;
      Editor.Keybinding_Management.Set_Filter
        (Editor.Keybinding_Management.Filter_Unbound);
      Summary := Editor.Keybinding_Management.Summary;
      Assert (Summary.Row_Count = Summary.Unbound_Bindable_Count,
              "unbound filter must only show unbound bindable commands");

      Editor.Keybinding_Management.Set_Filter
        (Editor.Keybinding_Management.Filter_Non_Bindable);
      Summary := Editor.Keybinding_Management.Summary;
      Assert (Summary.Row_Count = Summary.Non_Bindable_Command_Count,
              "non-bindable filter must only show non-bindable markers");
      Editor.Keybinding_Management.Clear_Filter;
   end Test_Keybinding_List_Search_And_Filter;

   procedure Test_Filter_Changes_Clear_Stale_Selections
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Status : Editor.Keybinding_Management.Keybinding_Action_Status;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Keybinding_Management.Show;
      Editor.Keybinding_Management.Focus;
      Editor.Keybinding_Management.Clear_Query;
      Editor.Keybinding_Management.Clear_Filter;

      Editor.Keybinding_Management.Select_Command
        (Editor.Commands.Command_Save_File);
      Assert
        (Editor.Keybinding_Management.Selected_Command =
         Editor.Commands.Command_Save_File,
         "selection setup must select a command");
      Editor.Keybinding_Management.Set_Query ("theme");
      Assert
        (Editor.Keybinding_Management.Selected_Command =
         Editor.Commands.No_Command,
         "query changes must clear command selections hidden by the new row projection");
      Editor.Keybinding_Management.Begin_Assign_Selected (Status);
      Assert
        (Status = Editor.Keybinding_Management.Keybinding_Action_No_Command_Selected,
         "assign must not operate on a stale command hidden by the current filter/query");

      Editor.Keybinding_Management.Clear_Query;
      Editor.Keybinding_Management.Select_Chord ("Ctrl+S", Status);
      Assert
        (Status = Editor.Keybinding_Management.Keybinding_Action_Ok
         and then Editor.Keybinding_Management.Has_Selected_Chord,
         "chord selection setup must select a visible chord row");
      Editor.Keybinding_Management.Set_Query ("build");
      Assert
        (not Editor.Keybinding_Management.Has_Selected_Chord,
         "query changes must clear selected chord rows hidden by the new projection");
      Editor.Keybinding_Management.Remove_Selected (Status);
      Assert
        (Status = Editor.Keybinding_Management.Keybinding_Action_No_Command_Selected,
         "remove must not operate on stale chord rows hidden by the current filter/query");

      Editor.Keybinding_Management.Clear_Query;
      Editor.Keybinding_Management.Clear_Filter;
   end Test_Filter_Changes_Clear_Stale_Selections;

   procedure Test_Assign_Conflict_Cancel_Remove_Reset
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Status : Editor.Keybinding_Management.Keybinding_Action_Status;
      Actual : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      New_Chord : constant Editor.Keybindings.Key_Chord :=
        Chord (Editor.Keybindings.Key_P, Ctrl => True, Alt => True);
      Conflicting_Chord : constant Editor.Keybindings.Key_Chord :=
        Chord (Editor.Keybindings.Key_S, Ctrl => True);
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Keybindings.Unbind_Command (Editor.Commands.Command_Find_Show);
      declare
         Before_Count : constant Natural :=
           Editor.Keybindings.Binding_Count_For_Command
             (Editor.Commands.Command_Find_Show);
         Projection : Editor.Keybinding_Management.Keybinding_List_Summary;
         Defaults   : Editor.Keybinding_Config.Keybinding_Config_Model;
         Snapshot   : Editor.Keybinding_Config.Keybinding_Config_Model;
      begin
         Projection := Editor.Keybinding_Management.Summary;
         Assert
           (Projection.Row_Count > 0
            and then Editor.Keybindings.Binding_Count_For_Command
              (Editor.Commands.Command_Find_Show) = Before_Count,
            "default chord projection must not mutate runtime keybindings");
         Editor.Keybinding_Config.Set_Defaults (Defaults);
         Assert
           (Editor.Keybindings.Binding_Count_For_Command
              (Editor.Commands.Command_Find_Show) = Before_Count,
            "default model construction must not install defaults into runtime bindings");
         Editor.Keybinding_Config.Build_From_Runtime (Snapshot);
         Assert
           (Editor.Keybindings.Binding_Count_For_Command
              (Editor.Commands.Command_Find_Show) = Before_Count,
            "keybinding save snapshot construction must not mutate runtime bindings");
      end;
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Keybinding_Management.Select_Command
        (Editor.Commands.Command_Find_Show);
      Editor.Keybinding_Management.Begin_Assign_Selected (Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Ok,
              "assign must enter explicit capture mode for selected bindable command");
      declare
         S : constant Editor.Keybinding_Management.Keybinding_List_Summary :=
           Editor.Keybinding_Management.Summary;
      begin
         Assert (S.Capture = Editor.Keybinding_Management.Capture_Active,
                 "capture state must be visible in the snapshot summary");
      end;
      Editor.Keybinding_Management.Cancel_Capture (Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Cancelled,
              "cancel must leave bindings unchanged");

      Editor.Keybinding_Management.Begin_Assign_Selected (Status);
      Editor.Keybinding_Management.Assign_Selected
        (Conflicting_Chord, Confirm_Conflict => False, Status => Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Shortcut_Already_Assigned,
              "conflicting chord must require explicit replacement confirmation");
      Assert (Editor.Keybinding_Management.Has_Pending_Conflict,
              "conflict must expose an explicit pending conflict state");
      Assert (Editor.Keybinding_Management.Pending_Conflict_Command =
                Editor.Commands.Command_Save_File,
              "pending conflict must identify the existing command");
      Assert (Editor.Keybinding_Management.Pending_Conflict_Chord = "Ctrl+S",
              "pending conflict must expose normalized chord label");
      Editor.Keybinding_Management.Confirm_Pending_Assignment (Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Ok,
              "explicit conflict confirmation must apply replacement");
      Assert (Editor.Keybindings.Resolve (Conflicting_Chord, Actual) =
                Editor.Keybindings.Bound_Command
              and then Actual = Editor.Commands.Command_Find_Show,
              "confirmed conflict must deterministically replace chord owner");
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Keybinding_Management.Select_Command
        (Editor.Commands.Command_Find_Show);

      Editor.Keybinding_Management.Begin_Assign_Selected (Status);
      Editor.Keybinding_Management.Assign_Selected
        (Conflicting_Chord, Confirm_Conflict => False, Status => Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Shortcut_Already_Assigned,
              "repeated conflict must again require explicit confirmation");
      Assert (Editor.Keybindings.Resolve (Conflicting_Chord, Actual) =
                Editor.Keybindings.Bound_Command
              and then Actual = Editor.Commands.Command_Save_File,
              "unconfirmed conflict must not displace existing binding");

      Editor.Keybinding_Management.Assign_Selected
        (New_Chord, Confirm_Conflict => False, Status => Status);
      Assert
        (Status = Editor.Keybinding_Management.Keybinding_Action_Confirmation_Pending,
         "pending conflict must block assigning a different shortcut");
      Assert
        (Editor.Keybindings.Resolve (New_Chord, Actual) = Editor.Keybindings.No_Binding,
         "blocked assignment must not mutate runtime lookup");

      Editor.Keybinding_Management.Cancel_Capture (Status);
      Editor.Keybinding_Management.Begin_Assign_Selected (Status);
      Editor.Keybinding_Management.Assign_Selected
        (New_Chord, Confirm_Conflict => False, Status => Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Ok,
              "non-conflicting assignment must succeed after pending conflict is cancelled");
      Assert (Editor.Keybindings.Resolve (New_Chord, Actual) =
                Editor.Keybindings.Bound_Command
              and then Actual = Editor.Commands.Command_Find_Show,
              "assignment must update runtime lookup to stable command id");
      Assert (Editor.Keybinding_Management.Latest_Message = "Keybinding assigned.",
              "assign workflow must expose a precise outcome message");

      Editor.Keybinding_Management.Select_Chord ("Alt+Ctrl+P", Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Ok
              and then Editor.Keybinding_Management.Has_Selected_Chord
              and then Editor.Keybinding_Management.Selected_Chord_Label = "Ctrl+Alt+P",
              "chord selection must normalize and select an active binding by chord");
      Editor.Keybinding_Management.Remove_Selected (Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Ok,
              "remove selected chord must remove the selected chord binding");
      Assert (Editor.Keybindings.Resolve (New_Chord, Actual) = Editor.Keybindings.No_Binding,
              "remove by chord must update runtime lookup");
      Assert (Editor.Keybinding_Management.Latest_Message = "Keybinding removed.",
              "remove workflow must expose a precise outcome message");

      Editor.Keybinding_Management.Select_Command
        (Editor.Commands.Command_Find_Show);
      Editor.Keybinding_Management.Assign_Selected
        (New_Chord, Confirm_Conflict => False, Status => Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Ok,
              "command removal setup must restore a command binding");

      Editor.Keybinding_Management.Remove_Selected (Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Ok,
              "remove selected must remove the selected command binding");
      Assert (Editor.Keybindings.Resolve (New_Chord, Actual) = Editor.Keybindings.No_Binding,
              "remove must update runtime lookup");

      Editor.Keybinding_Management.Reset_To_Defaults (Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Ok,
              "reset must complete explicitly");
      Assert (Editor.Keybinding_Management.Latest_Message = "Keybindings reset to defaults.",
              "reset workflow must expose a precise outcome message");
      Assert (Editor.Keybindings.Resolve
                (Chord (Editor.Keybindings.Key_P, Ctrl => True, Shift => True), Actual) =
                Editor.Keybindings.Bound_Command
              and then Actual = Editor.Commands.Command_Open_Command_Palette,
              "reset must restore default keybindings only");
   end Test_Assign_Conflict_Cancel_Remove_Reset;
   procedure Test_Input_Bridge_Capture_Consumes_And_Assigns
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Status : Editor.Keybinding_Management.Keybinding_Action_Status;
      Actual : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Captured : constant Editor.Keybindings.Key_Chord :=
        Chord (Editor.Keybindings.Key_F, Ctrl => True, Alt => True);
   begin
      Editor.Input_Bridge.Reset;
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Keybindings.Unbind (Captured);
      Editor.Keybindings.Unbind_Command (Editor.Commands.Command_Find_Show);
      Editor.Keybinding_Management.Show;
      Editor.Keybinding_Management.Focus;
      Editor.Keybinding_Management.Select_Command
        (Editor.Commands.Command_Find_Show);
      Editor.Keybinding_Management.Begin_Assign_Selected (Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Ok,
              "input bridge capture setup must enter capture mode");

      Editor.Input_Bridge.Handle_Key_Chord (Captured);

      Assert
        (Editor.Keybinding_Management.Current_Capture_State =
           Editor.Keybinding_Management.Capture_Inactive,
         "captured chord must close capture mode");
      Assert
        (Editor.Keybindings.Resolve (Captured, Actual) =
           Editor.Keybindings.Bound_Command
         and then Actual = Editor.Commands.Command_Find_Show,
         "Input_Bridge capture must assign through keybinding management "
         & "instead of typing or global dispatch");
      Assert
        (Editor.Keybinding_Management.Latest_Message = "Keybinding assigned.",
         "Input_Bridge capture must report the assignment outcome");
   end Test_Input_Bridge_Capture_Consumes_And_Assigns;

   procedure Test_Keybinding_Prompt_Handlers_Capture_And_Confirm
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Prompt  : Editor.Guided_Prompts.Prompt_State;
      Status  : Editor.Keybinding_Management.Keybinding_Action_Status;
      Actual  : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Report  : Unbounded_String := Null_Unbounded_String;
      Custom  : constant Editor.Keybindings.Key_Chord :=
        Chord (Editor.Keybindings.Key_F, Ctrl => True, Alt => True);

      procedure Capture_Report (Text : String) is
      begin
         Report := To_Unbounded_String (Text);
      end Capture_Report;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Keybinding_Management.Reset_Transient_State;
      Editor.Keybinding_Management.Show;
      Editor.Keybinding_Management.Focus;
      Editor.Keybinding_Management.Select_Command (Editor.Commands.Command_Find_Show);
      Editor.Keybinding_Management.Begin_Assign_Selected (Status);
      Assert
        (Status = Editor.Keybinding_Management.Keybinding_Action_Ok,
         "keybinding prompt handler test must enter capture mode");

      Editor.Guided_Prompts.Start
        (Prompt,
         Editor.Guided_Prompts.Keybinding_Capture_Prompt,
         Editor.Commands.Command_Keybindings_Assign_Selected,
         "Assign Keybinding",
         "Press keybinding chord.",
         "Keybindings");
      Assert
        (Editor.Input_Bridge.Keybinding_Handlers.Is_Keybinding_Capture_Prompt (Prompt),
         "keybinding prompt helper must recognize capture prompts");
      Assert
        (Editor.Input_Bridge.Keybinding_Handlers.Consume_Keybinding_Text_Input
           (Prompt,
            Editor.Commands.Command'
              (Kind => Editor.Commands.Insert_Text_Input,
               Text => To_Unbounded_String ("x"),
               others => <>)),
         "keybinding prompt helper must consume text input events");

      Editor.Guided_Prompts.Capture_Chord (Prompt, Custom);
      Assert
        (Editor.Input_Bridge.Keybinding_Handlers.Handle_Keybinding_Prompt_Key
           (Prompt, Chord (Editor.Keybindings.Key_Escape), Capture_Report'Access),
         "Escape must cancel a keybinding prompt through the helper");
      Assert
        (To_String (Report) = "Prompt cancelled.",
         "Escape must cancel a keybinding prompt through the helper");

      Editor.Guided_Prompts.Start
        (Prompt,
         Editor.Guided_Prompts.Keybinding_Capture_Prompt,
         Editor.Commands.Command_Keybindings_Assign_Selected,
         "Assign Keybinding",
         "Press keybinding chord.",
         "Keybindings");
      Editor.Guided_Prompts.Capture_Chord (Prompt, Custom);
      Report := Null_Unbounded_String;
      Editor.Input_Bridge.Keybinding_Handlers.Confirm_Keybinding_Capture
        (Prompt, Capture_Report'Access);
      Assert
        (To_String (Report) = "Keybinding operation completed.",
         "confirm helper must report the assignment outcome");
      Assert
        (not Editor.Guided_Prompts.Is_Active (Prompt),
         "confirm helper must clear the guided prompt");
      Assert
        (Editor.Keybindings.Resolve (Custom, Actual) = Editor.Keybindings.Bound_Command
         and then Actual = Editor.Commands.Command_Find_Show,
         "confirm helper must assign the captured chord through keybinding management");
   end Test_Keybinding_Prompt_Handlers_Capture_And_Confirm;

   procedure Test_Input_Bridge_Focused_Surface_Consumes_Local_Navigation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Editor.Input_Bridge.Reset;
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Keybinding_Management.Show;
      Editor.Keybinding_Management.Focus;
      Editor.Keybinding_Management.Set_Query ("Save File");
      Editor.Keybinding_Management.Clear_Selection;

      Editor.Input_Bridge.Handle_Key_Chord
        (Chord (Editor.Keybindings.Key_Down));
      Assert
        (Editor.Keybinding_Management.Selected_Command =
           Editor.Commands.Command_Save_File,
         "focused keybinding surface must consume Down for row selection");

      Editor.Input_Bridge.Handle_Key_Chord
        (Chord (Editor.Keybindings.Key_Enter));
      Assert
        (Editor.Keybinding_Management.Current_Capture_State =
           Editor.Keybinding_Management.Capture_Active,
         "focused keybinding surface Enter must start explicit capture");

      Editor.Input_Bridge.Handle_Key_Chord
        (Chord (Editor.Keybindings.Key_Escape));
      Assert
        (Editor.Keybinding_Management.Current_Capture_State =
           Editor.Keybinding_Management.Capture_Inactive,
         "first Escape must cancel capture while surface stays visible");
      Assert
        (Editor.Keybinding_Management.Is_Visible,
         "capture cancellation must not hide the keybinding surface");

      Editor.Input_Bridge.Handle_Key_Chord
        (Chord (Editor.Keybindings.Key_Escape));
      Assert
        (not Editor.Keybinding_Management.Is_Visible,
         "focused keybinding surface must consume Escape to hide itself");

      Editor.Keybindings.Reset_To_Defaults;
   end Test_Input_Bridge_Focused_Surface_Consumes_Local_Navigation;

   procedure Test_Input_Bridge_Focused_Surface_Reset_Confirmation_Keys
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Status : Editor.Keybindings.Keybinding_Change_Status;
      Action : Editor.Keybinding_Management.Keybinding_Action_Status;
      Actual : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Custom : constant Editor.Keybindings.Key_Chord :=
        Chord (Editor.Keybindings.Key_F, Alt => True);
   begin
      Editor.Input_Bridge.Reset;
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Keybindings.Assign
        (Custom, Editor.Commands.Command_Find_Show, Status);
      Assert (Status = Editor.Keybindings.Keybinding_Change_Ok,
              "reset key confirmation test must create a custom binding");

      Editor.Keybinding_Management.Show;
      Editor.Keybinding_Management.Focus;
      Editor.Keybinding_Management.Request_Reset_To_Defaults (Action);
      Assert (Editor.Keybinding_Management.Has_Pending_Reset,
              "focused surface reset must be pending before Escape");

      Editor.Input_Bridge.Handle_Key_Chord
        (Chord (Editor.Keybindings.Key_Escape));
      Assert (not Editor.Keybinding_Management.Has_Pending_Reset,
              "focused surface Escape must cancel pending reset first");
      Assert (Editor.Keybinding_Management.Is_Visible,
              "reset cancellation must keep keybinding surface visible");
      Assert (Editor.Keybindings.Resolve (Custom, Actual) =
                Editor.Keybindings.Bound_Command
              and then Actual = Editor.Commands.Command_Find_Show,
              "reset cancellation must not mutate bindings");

      Editor.Keybinding_Management.Request_Reset_To_Defaults (Action);
      Assert (Editor.Keybinding_Management.Has_Pending_Reset,
              "focused surface reset must be pending before Enter");
      Editor.Input_Bridge.Handle_Key_Chord
        (Chord (Editor.Keybindings.Key_Enter));
      Assert (not Editor.Keybinding_Management.Has_Pending_Reset,
              "focused surface Enter must confirm pending reset");
      Assert (Editor.Keybindings.Resolve (Custom, Actual) =
                Editor.Keybindings.No_Binding,
              "confirmed reset key must restore defaults and clear custom binding");

      Editor.Keybindings.Reset_To_Defaults;
   end Test_Input_Bridge_Focused_Surface_Reset_Confirmation_Keys;

   procedure Test_Input_Bridge_Capture_Conflict_Requires_Enter
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Status : Editor.Keybinding_Management.Keybinding_Action_Status;
      Actual : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Conflicting : constant Editor.Keybindings.Key_Chord :=
        Chord (Editor.Keybindings.Key_S, Ctrl => True);
   begin
      Editor.Input_Bridge.Reset;
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Keybinding_Management.Show;
      Editor.Keybinding_Management.Focus;
      Editor.Keybinding_Management.Select_Command
        (Editor.Commands.Command_Find_Show);
      Editor.Keybinding_Management.Begin_Assign_Selected (Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Ok,
              "conflict capture setup must enter capture mode");

      Editor.Input_Bridge.Handle_Key_Chord (Conflicting);
      Assert
        (Editor.Keybinding_Management.Has_Pending_Conflict,
         "Input_Bridge capture must expose conflict instead of replacing silently");
      Assert
        (Editor.Keybindings.Resolve (Conflicting, Actual) =
           Editor.Keybindings.Bound_Command
         and then Actual = Editor.Commands.Command_Save_File,
         "unconfirmed Input_Bridge conflict must preserve existing owner");

      Editor.Input_Bridge.Handle_Key_Chord
        (Chord (Editor.Keybindings.Key_P, Ctrl => True, Alt => True));
      Assert
        (Editor.Keybinding_Management.Has_Pending_Conflict,
         "non-confirming chord must leave conflict confirmation pending");
      Assert
        (Editor.Keybindings.Resolve
           (Chord (Editor.Keybindings.Key_P, Ctrl => True, Alt => True), Actual) =
             Editor.Keybindings.No_Binding,
         "non-confirming chord during conflict must not assign a new binding");
      Assert
        (Editor.Keybindings.Resolve (Conflicting, Actual) =
           Editor.Keybindings.Bound_Command
         and then Actual = Editor.Commands.Command_Save_File,
         "non-confirming chord during conflict must not replace existing owner");

      Editor.Input_Bridge.Handle_Key_Chord
        (Chord (Editor.Keybindings.Key_Enter));
      Assert
        (Editor.Keybindings.Resolve (Conflicting, Actual) =
           Editor.Keybindings.Bound_Command
         and then Actual = Editor.Commands.Command_Find_Show,
         "Enter must explicitly confirm pending keybinding replacement");
      Assert
        (not Editor.Keybinding_Management.Has_Pending_Conflict,
         "confirmed conflict must clear pending conflict state");
   end Test_Input_Bridge_Capture_Conflict_Requires_Enter;

   procedure Test_Conflict_Confirmation_Uses_Captured_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Status : Editor.Keybinding_Management.Keybinding_Action_Status;
      Actual : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Conflicting : constant Editor.Keybindings.Key_Chord :=
        Chord (Editor.Keybindings.Key_S, Ctrl => True);
   begin
      Editor.Input_Bridge.Reset;
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Keybinding_Management.Show;
      Editor.Keybinding_Management.Focus;
      Editor.Keybinding_Management.Select_Command
        (Editor.Commands.Command_Find_Show);
      Editor.Keybinding_Management.Begin_Assign_Selected (Status);
      Editor.Keybinding_Management.Assign_Selected
        (Conflicting, Confirm_Conflict => False, Status => Status);
      Assert
        (Status = Editor.Keybinding_Management.Keybinding_Action_Shortcut_Already_Assigned
         and then Editor.Keybinding_Management.Has_Pending_Conflict,
         "setup must leave a pending conflict confirmation");

      --  A transient filter/query change may hide and clear the selected row,
      --  but it must not invalidate the explicit captured target/chord pair.
      Editor.Keybinding_Management.Set_Query ("definitely no matching command");
      Assert
        (Editor.Keybinding_Management.Selected_Command = Editor.Commands.No_Command,
         "filter change must clear the stale visible row selection");

      Editor.Keybinding_Management.Confirm_Pending_Assignment (Status);
      Assert
        (Status = Editor.Keybinding_Management.Keybinding_Action_Ok,
         "conflict confirmation must use captured target, not live row selection");
      Assert
        (Editor.Keybindings.Resolve (Conflicting, Actual) =
           Editor.Keybindings.Bound_Command
         and then Actual = Editor.Commands.Command_Find_Show,
         "confirmed replacement must still update runtime lookup");
      Assert
        (not Editor.Keybinding_Management.Has_Pending_Conflict,
         "confirmed replacement must clear pending conflict state");

      Editor.Keybinding_Management.Clear_Query;
      Editor.Keybindings.Reset_To_Defaults;
   end Test_Conflict_Confirmation_Uses_Captured_Target;


   procedure Test_Save_Load_No_Payload_And_Coherence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Path   : constant String := Temp_Path ("save_load");
      Status : Editor.Keybinding_Management.Keybinding_Action_Status;
      Text   : Unbounded_String := Null_Unbounded_String;
      Actual : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Ch     : constant Editor.Keybindings.Key_Chord :=
        Chord (Editor.Keybindings.Key_L, Ctrl => True, Alt => True);
      Audit  : Editor.Command_Route_Audit.Route_Audit_Result;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Keybinding_Management.Select_Command (Editor.Commands.Command_Find_Show);
      Editor.Keybinding_Management.Assign_Selected
        (Ch, Confirm_Conflict => False, Status => Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Ok,
              "setup assignment must succeed");

      Editor.Keybinding_Management.Save (Path, Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Ok,
              "save must write keybinding domain only");
      Text := To_Unbounded_String (File_Contents (Path));
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "edit.find.show") /= 0,
              "save must contain stable command names");
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "candidate") = 0
              and then Ada.Strings.Fixed.Index (To_String (Text), "workspace") = 0
              and then Ada.Strings.Fixed.Index (To_String (Text), "[recent-projects]") = 0
              and then Ada.Strings.Fixed.Index (To_String (Text), "recent-project=") = 0,
              "save must exclude payloads, workspace, and recent projects");

      Editor.Keybindings.Reset_To_Defaults;
      Assert (Editor.Keybindings.Resolve (Ch, Actual) = Editor.Keybindings.No_Binding,
              "custom chord should be absent after reset before reload");
      Editor.Keybinding_Management.Load (Path, Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Ok,
              "load must apply stable chord-to-command mappings without executing commands");
      Assert (Editor.Keybindings.Resolve (Ch, Actual) = Editor.Keybindings.Bound_Command
              and then Actual = Editor.Commands.Command_Find_Show,
              "load must restore normalized runtime lookup");
      Editor.Command_Route_Audit.Clear (Audit);
      Editor.Command_Route_Audit.Record_Keybinding_Management_Route
        (Audit, Editor.Commands.Command_Find_Show,
         Routed_Through_Executor => True,
         Used_Stable_Command_Name => True,
         Carried_Payload => False);
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 0,
              "keybinding management route audit must accept Executor/stable/no-payload routes");
      Editor.Command_Route_Audit.Record_Keybinding_Management_Route
        (Audit, Editor.Commands.Command_Find_Show,
         Routed_Through_Executor => True,
         Used_Stable_Command_Name => True,
         Carried_Payload => True);
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 1,
              "keybinding management route audit must reject payload-bearing routes");
      Assert (Editor.Keybinding_Management.Assert_Keybinding_Management_Coherent,
              "milestone coherence helper must pass");
   end Test_Save_Load_No_Payload_And_Coherence;

   procedure Test_Reset_Confirmation_And_Surface_Guards
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Status : Editor.Keybinding_Management.Keybinding_Action_Status;
      Snapshot : Editor.Keybinding_Management.Keybinding_Surface_Snapshot;
      Actual : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Custom : constant Editor.Keybindings.Key_Chord :=
        Chord (Editor.Keybindings.Key_S, Ctrl => True, Alt => True);
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Keybinding_Management.Reset_Transient_State;
      Editor.Keybinding_Management.Clear_Selection;
      Editor.Keybinding_Management.Select_Command (Editor.Commands.Command_Find_Show);
      Editor.Keybinding_Management.Assign_Selected
        (Custom, Confirm_Conflict => False, Status => Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Ok,
              "reset-confirmation setup must bind a custom chord");

      Editor.Keybinding_Management.Request_Reset_To_Defaults (Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Reset_Confirmation_Pending
              and then Editor.Keybinding_Management.Has_Pending_Reset,
              "reset request must create explicit pending confirmation");
      Snapshot := Editor.Keybinding_Management.Build_Surface_Snapshot;
      Assert (Snapshot.Has_Pending_Reset,
              "render snapshot must expose pending reset state");
      Assert (Editor.Keybindings.Resolve (Custom, Actual) = Editor.Keybindings.Bound_Command
              and then Actual = Editor.Commands.Command_Find_Show,
              "reset request must not mutate runtime keybindings");

      Editor.Keybinding_Management.Cancel_Reset_To_Defaults (Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Cancelled
              and then not Editor.Keybinding_Management.Has_Pending_Reset,
              "reset cancel must clear pending confirmation");
      Assert (Editor.Keybindings.Resolve (Custom, Actual) = Editor.Keybindings.Bound_Command
              and then Actual = Editor.Commands.Command_Find_Show,
              "reset cancel must leave bindings unchanged");

      Editor.Keybinding_Management.Request_Reset_To_Defaults (Status);
      Editor.Keybinding_Management.Confirm_Reset_To_Defaults (Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Ok
              and then not Editor.Keybinding_Management.Has_Pending_Reset,
              "reset confirmation must apply and clear pending state");
      Assert (Editor.Keybindings.Resolve (Custom, Actual) = Editor.Keybindings.No_Binding,
              "confirmed reset must remove user overrides");

      Assert (Editor.Keybinding_Management.Assert_Keybinding_Surface_Render_Is_Observational,
              "surface snapshot must be render-observational");
      Assert (Editor.Keybinding_Management.Assert_Keybinding_Editor_State_Not_Persisted,
              "keybinding editor query/selection/capture state must remain non-persisted");
   end Test_Reset_Confirmation_And_Surface_Guards;


   procedure Test_Reset_Transient_State_Clears_UI_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Status : Editor.Keybinding_Management.Keybinding_Action_Status;
      Actual : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Custom : constant Editor.Keybindings.Key_Chord :=
        Chord (Editor.Keybindings.Key_S, Ctrl => True, Alt => True);
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Keybinding_Management.Reset_Transient_State;
      Editor.Keybinding_Management.Show;
      Editor.Keybinding_Management.Focus;
      Editor.Keybinding_Management.Select_Command (Editor.Commands.Command_Save_File);
      Editor.Keybinding_Management.Assign_Selected
        (Custom, Confirm_Conflict => False, Status => Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Ok,
              "reset transient setup must create a custom binding");
      Editor.Keybinding_Management.Set_Query ("build");
      Editor.Keybinding_Management.Set_Filter
        (Editor.Keybinding_Management.Filter_Unbound);
      Editor.Keybinding_Management.Request_Reset_To_Defaults (Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Reset_Confirmation_Pending,
              "reset transient setup must create pending reset state");

      Editor.Keybinding_Management.Reset_Transient_State;

      Assert (not Editor.Keybinding_Management.Is_Visible
              and then not Editor.Keybinding_Management.Is_Focused,
              "transient reset must hide and unfocus the keybinding surface");
      Assert (Editor.Keybinding_Management.Query = "",
              "transient reset must clear keybinding query state");
      Assert (Editor.Keybinding_Management.Current_Filter =
              Editor.Keybinding_Management.Filter_All,
              "transient reset must clear keybinding filter state");
      Assert (Editor.Keybinding_Management.Selected_Command =
              Editor.Commands.No_Command,
              "transient reset must clear selected command state");
      Assert (not Editor.Keybinding_Management.Has_Selected_Chord,
              "transient reset must clear selected chord state");
      Assert (Editor.Keybinding_Management.Current_Capture_State =
              Editor.Keybinding_Management.Capture_Inactive,
              "transient reset must clear capture state");
      Assert (not Editor.Keybinding_Management.Has_Pending_Reset
              and then not Editor.Keybinding_Management.Has_Pending_Conflict,
              "transient reset must clear pending confirmation state");
      Assert (Editor.Keybinding_Management.Latest_Message = "",
              "transient reset must clear local latest-message state");
      Assert (Editor.Keybindings.Resolve (Custom, Actual) =
              Editor.Keybindings.Bound_Command
              and then Actual = Editor.Commands.Command_Save_File,
              "transient reset must not reset or mutate runtime keybindings");
   end Test_Reset_Transient_State_Clears_UI_Only;

   procedure Test_Pending_Confirmations_Block_Keybinding_Mutations
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Status : Editor.Keybinding_Management.Keybinding_Action_Status;
      Availability : Editor.Commands.Command_Availability;
      Custom : constant Editor.Keybindings.Key_Chord :=
        Chord (Editor.Keybindings.Key_S, Ctrl => True, Alt => True);
      Actual : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      Editor.State.Init (S);
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Keybinding_Management.Reset_Transient_State;
      Editor.Keybinding_Management.Hide;
      Editor.Keybinding_Management.Show;
      Editor.Keybinding_Management.Focus;
      Editor.Keybinding_Management.Select_Command (Editor.Commands.Command_Find_Show);

      Editor.Keybinding_Management.Assign_Selected
        (Custom, Confirm_Conflict => False, Status => Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Ok,
              "pending-confirmation setup must create custom binding");

      Editor.Keybinding_Management.Request_Reset_To_Defaults (Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Reset_Confirmation_Pending,
              "reset request must enter pending confirmation state");

      Editor.Keybinding_Management.Begin_Assign_Selected (Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Confirmation_Pending,
              "assign must be blocked while reset confirmation is pending");

      Editor.Keybinding_Management.Remove_Selected (Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Confirmation_Pending,
              "remove must be blocked while reset confirmation is pending");

      Editor.Keybinding_Management.Save (Temp_Path ("pending_block"), Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Confirmation_Pending,
              "save must be blocked while confirmation is pending");

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Keybindings_Assign_Selected);
      Assert (Availability.Status = Editor.Commands.Command_Unavailable,
              "Executor availability must block assign during pending confirmation");

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Keybindings_Remove_Selected);
      Assert (Availability.Status = Editor.Commands.Command_Unavailable,
              "Executor availability must block remove during pending confirmation");

      Assert (Editor.Keybindings.Resolve (Custom, Actual) = Editor.Keybindings.Bound_Command
              and then Actual = Editor.Commands.Command_Find_Show,
              "blocked operations must not mutate the existing binding");

      Editor.Keybinding_Management.Cancel_Reset_To_Defaults (Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Cancelled,
              "pending confirmation cancel must remain available");
   end Test_Pending_Confirmations_Block_Keybinding_Mutations;


   procedure Test_Reset_Commands_Require_Confirmation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Status : Editor.Keybinding_Management.Keybinding_Action_Status;
      Availability : Editor.Commands.Command_Availability;
      Custom : constant Editor.Keybindings.Key_Chord :=
        Chord (Editor.Keybindings.Key_S, Ctrl => True, Alt => True);
      Actual : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      Editor.State.Init (S);
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Keybinding_Management.Reset_Transient_State;
      Editor.Keybinding_Management.Hide;
      Editor.Keybinding_Management.Show;
      Editor.Keybinding_Management.Focus;
      Editor.Keybinding_Management.Select_Command (Editor.Commands.Command_Find_Show);

      Editor.Keybinding_Management.Assign_Selected
        (Custom, Confirm_Conflict => False, Status => Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Ok,
              "reset-command setup must create custom binding");

      Editor.Keybinding_Management.Begin_Assign_Selected (Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Ok,
              "reset-command setup must enter capture mode");

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Keybindings_Reset_To_Defaults);
      Assert (Availability.Status = Editor.Commands.Command_Unavailable,
              "keybinding reset must be unavailable while capture is active");

      Editor.Keybinding_Management.Request_Reset_To_Defaults (Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Confirmation_Pending,
              "direct reset request must not overwrite capture confirmation state");

      Editor.Keybinding_Management.Cancel_Capture (Status);
      Assert (Status = Editor.Keybinding_Management.Keybinding_Action_Cancelled,
              "reset-command setup must cancel capture");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Keybindings_Reset_To_Defaults);
      Assert (Editor.Keybinding_Management.Has_Pending_Reset,
              "reset command must request confirmation first");
      Assert (Editor.Keybindings.Resolve (Custom, Actual) = Editor.Keybindings.Bound_Command
              and then Actual = Editor.Commands.Command_Find_Show,
              "first reset invocation must not reset runtime bindings");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Keybindings_Reset_To_Defaults);
      Assert (not Editor.Keybinding_Management.Has_Pending_Reset,
              "second reset invocation must clear confirmation");
      Assert (Editor.Keybindings.Resolve (Custom, Actual) = Editor.Keybindings.No_Binding,
              "confirmed reset command must restore defaults");
   end Test_Reset_Commands_Require_Confirmation;


   procedure Test_Command_Descriptors_And_Executor_Routes
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Availability : Editor.Commands.Command_Availability;
   begin
      Editor.State.Init (S);
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Keybinding_Management.Reset_Transient_State;

      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Save_Keybindings) = "keybindings.save",
         "save command must have keybindings.save stable name");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Reload_Keybindings) = "keybindings.load",
         "load command must have keybindings.load stable name");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Keybindings_Show) = "keybindings.show",
         "show command must have stable name");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Keybindings_Assign_Selected) =
         "keybindings.assign-selected",
         "assign command must have stable name");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Keybindings_Remove_Selected) =
         "keybindings.remove-selected",
         "remove command must have stable name");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Keybindings_Reset_To_Defaults) =
         "keybindings.reset-to-defaults",
         "reset command must have stable name");
      Assert
        (Editor.Commands.Discoverability_Category_Label
           (Editor.Commands.Command_Keybindings_Show) = "Keybindings",
         "commands must group under Keybindings discoverability");
      Assert
        (Editor.Commands.Discoverability_Category_Label
           (Editor.Commands.Command_Save_Keybindings) = "Keybindings",
         "save/load keybinding commands must group under Keybindings discoverability");

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Keybindings_Assign_Selected);
      Assert
        (not Editor.Commands.Is_Available (Availability)
         and then Editor.Commands.Unavailable_Reason (Availability) =
           "Keybindings view is not open",
         "assign availability must be precise when view is closed");

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Keybindings_Cancel_Capture);
      Assert
        (not Editor.Commands.Is_Available (Availability)
         and then Editor.Commands.Unavailable_Reason (Availability) =
           "Shortcut capture is not active",
         "cancel-capture availability must be precise when idle");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Keybindings_Show);
      Assert
        (Editor.Keybinding_Management.Is_Visible,
         "keybindings.show must route through Executor");
      Editor.Keybinding_Management.Clear_Selection;

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Keybindings_Assign_Selected);
      Assert
        (not Editor.Commands.Is_Available (Availability)
         and then Editor.Commands.Unavailable_Reason (Availability) =
           "No command selected.",
         "assign availability must require a selected command");

      Editor.Keybinding_Management.Select_Command (Editor.Commands.Command_Find_Show);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Keybindings_Assign_Selected);
      Assert
        (Editor.Keybinding_Management.Current_Capture_State =
         Editor.Keybinding_Management.Capture_Active,
         "assign selected must enter capture through Executor");

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Keybindings_Cancel_Capture);
      Assert
        (Editor.Commands.Is_Available (Availability),
         "cancel-capture must become available during capture");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Keybindings_Cancel_Capture);
      Assert
        (Editor.Keybinding_Management.Current_Capture_State =
         Editor.Keybinding_Management.Capture_Inactive,
         "cancel capture must clear capture through Executor");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Keybindings_Filter_Unbound);
      Assert
        (Editor.Keybinding_Management.Current_Filter =
         Editor.Keybinding_Management.Filter_Unbound,
         "filter-unbound command must update transient filter state only");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Keybindings_Clear_Filter);
      Assert
        (Editor.Keybinding_Management.Current_Filter =
         Editor.Keybinding_Management.Filter_All,
         "clear-filter command must restore all filter");

      declare
         Audit : Editor.Command_Route_Audit.Route_Audit_Result;
      begin
         Editor.Command_Route_Audit.Record_Keybinding_Management_Route
           (Audit,
            Editor.Commands.Command_Keybindings_Assign_Selected,
            Routed_Through_Executor  => True,
            Used_Stable_Command_Name => True,
            Carried_Payload          => False);
         Editor.Command_Route_Audit.Record_Keybinding_Management_Route
           (Audit,
            Editor.Commands.Command_Save_Keybindings,
            Routed_Through_Executor  => True,
            Used_Stable_Command_Name => True,
            Carried_Payload          => False);
         Editor.Command_Route_Audit.Record_Keybinding_Management_Route
           (Audit,
            Editor.Commands.Command_Reload_Keybindings,
            Routed_Through_Executor  => True,
            Used_Stable_Command_Name => True,
            Carried_Payload          => False);
         Assert
           (Editor.Command_Route_Audit.Failure_Count (Audit) = 0,
            "keybinding management routes must be Executor-routed and no-payload");
      end;
      Editor.Keybindings.Reset_To_Defaults;
   end Test_Command_Descriptors_And_Executor_Routes;


   procedure Test_Load_Diagnostics_Surface_Invalid_Entries
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Path   : constant String := Temp_Path ("load_diagnostics");
      Status : Editor.Keybinding_Management.Keybinding_Action_Status;
      Sum    : Editor.Keybinding_Management.Keybinding_List_Summary;
      Surf   : Editor.Keybinding_Management.Keybinding_Surface_Snapshot;
      Actual : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Valid  : constant Editor.Keybindings.Key_Chord :=
        Chord (Editor.Keybindings.Key_L, Ctrl => True, Alt => True);
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Write_File
        (Path,
         "editor-keybindings-version=1" & ASCII.LF &
         "[bindings]" & ASCII.LF &
         "edit.find.show=Ctrl+Alt+L" & ASCII.LF &
         "unknown.command=Ctrl+Alt+U" & ASCII.LF &
         "file.save=Ctrl+Alt+S" & ASCII.LF &
         "file.save-as=Ctrl+Alt+S" & ASCII.LF &
         "edit.find.hide=DefinitelyNotAChord" & ASCII.LF &
         "edit.find.toggle=Ctrl+Alt+T;row=7" & ASCII.LF);

      Editor.Keybinding_Management.Load (Path, Status);
      Assert
        (Status = Editor.Keybinding_Management.Keybinding_Action_Ok,
         "partial load must still apply valid mappings");
      Sum := Editor.Keybinding_Management.Summary;
      Assert
        (Sum.Last_Load_Ignored_Count >= 4,
         "keybinding surface must expose ignored invalid load entries");
      Assert
        (Sum.Last_Load_Unknown_Commands = 1,
         "load diagnostics must count unknown command bindings");
      Assert
        (Sum.Last_Load_Invalid_Chords = 1,
         "load diagnostics must count invalid chord bindings");
      Assert
        (Sum.Last_Load_Payloads = 1,
         "load diagnostics must count payload-bearing bindings");
      Assert
        (Sum.Last_Load_Duplicate_Chords = 1,
         "load diagnostics must count duplicate chord conflicts");
      Surf := Editor.Keybinding_Management.Build_Surface_Snapshot;
      Assert
        (Surf.Last_Load_Ignored_Count = Sum.Last_Load_Ignored_Count,
         "render-facing surface must expose load diagnostic summary only");
      Assert
        (Ada.Strings.Fixed.Index
           (To_String (Surf.Last_Load_Diagnostic_Label), "unknown commands:") /= 0
         and then Ada.Strings.Fixed.Index
           (To_String (Surf.Last_Load_Diagnostic_Label), "payloads:") /= 0,
         "render-facing surface must expose load diagnostic categories");
      declare
         Message : constant String := Editor.Keybinding_Management.Latest_Message;
      begin
         Assert
           (Message'Length > 0
            and then Ada.Strings.Fixed.Index
              (Message, "ignored invalid entries") /= 0,
            "management load message must report partial invalid-entry load");
      end;
      Assert
        (Editor.Keybindings.Resolve (Valid, Actual) = Editor.Keybindings.Bound_Command,
         "partial load must install at least one valid normalized binding");

      declare
         Candidate : Editor.Commands.Command_Palette_Candidate :=
           (Id                  => Editor.Commands.Command_Find_Show,
            Label               => To_Unbounded_String ("Show Find"),
            Description         => To_Unbounded_String ("Show find input."),
            Category            => Editor.Commands.Search_Category,
            Category_Label      => To_Unbounded_String ("Search"),
            Available           => True,
            Reason              => Null_Unbounded_String,
            Has_Keybinding      => True,
            Keybinding_Display  => To_Unbounded_String ("Ctrl+Alt+L"),
            Reference_Summary   => Null_Unbounded_String,
            Family              => Editor.Commands.No_Command_Family,
            Effect_Classification => Editor.Commands.No_Command_Effect,
            Match_Score         => 0,
            Registry_Order      => 0);
         Help : Editor.Command_Palette.Command_Help_Snapshot;
      begin
         Help := Editor.Command_Palette.Build_Command_Help (Candidate);
         Assert
           (Help.Has_Active_Keybinding
            and then Help.Active_Keybinding_Count >= 1
            and then Ada.Strings.Fixed.Index
              (To_String (Help.Keybinding_Label), "Ctrl+Alt+L") /= 0,
            "command help must expose active keybinding state from runtime bindings");
      end;
   end Test_Load_Diagnostics_Surface_Invalid_Entries;


   procedure Test_Render_Model_Includes_Keybinding_Surface
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Snap   : Editor.Render_Model.Render_Snapshot;
      Status : Editor.Keybinding_Management.Keybinding_Action_Status;
   begin
      Editor.State.Init (S);
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Keybinding_Management.Show;
      Editor.Keybinding_Management.Focus;
      Editor.Keybinding_Management.Set_Query ("theme");
      Editor.Keybinding_Management.Set_Filter
        (Editor.Keybinding_Management.Filter_Unbound);
      Editor.Keybinding_Management.Select_Command (Editor.Commands.Command_Toggle_Theme);
      Editor.Keybinding_Management.Begin_Assign_Selected (Status);

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Assert
        (Snap.Keybindings_UI.Visible
         and then Snap.Keybindings_UI.Focused
         and then Snap.Keybindings_UI.Query_Present
         and then Snap.Keybindings_UI.Filter =
           Editor.Keybinding_Management.Filter_Unbound
         and then Snap.Keybindings_UI.Capture =
           Editor.Keybinding_Management.Capture_Active
         and then Snap.Keybindings_UI.Selected_Command =
           Editor.Commands.Command_Toggle_Theme,
         "render model must expose keybinding surface snapshot");

      Editor.Keybinding_Management.Cancel_Capture (Status);
      Editor.Keybinding_Management.Hide;
   end Test_Render_Model_Includes_Keybinding_Surface;


   procedure Test_Render_Surface_Rows_Are_Snapshot_Owned
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Snap    : Editor.Render_Model.Render_Snapshot;
      Before  : Unbounded_String;
   begin
      Editor.State.Init (S);
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Keybinding_Management.Show;
      Editor.Keybinding_Management.Focus;
      Editor.Keybinding_Management.Clear_Query;
      Editor.Keybinding_Management.Clear_Filter;

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (Snap.Keybindings_UI.Display_Row_Count > 0,
         "keybinding render snapshot must carry bounded display rows");
      Before := Snap.Keybindings_UI.Display_Rows (1).Stable_Command_Name;

      --  Mutate live transient editor state after snapshot capture. Render packet
      --  code must be able to consume Snap.Keybindings_UI.Display_Rows without
      --  consulting the live keybinding management surface again.
      Editor.Keybinding_Management.Set_Query ("definitely-no-such-command");
      Editor.Keybinding_Management.Set_Filter
        (Editor.Keybinding_Management.Filter_Conflicts);

      Assert
        (Snap.Keybindings_UI.Display_Row_Count > 0
         and then Snap.Keybindings_UI.Display_Rows (1).Stable_Command_Name = Before,
         "render-facing keybinding rows must be immutable snapshot data");

      Editor.Keybinding_Management.Hide;
   end Test_Render_Surface_Rows_Are_Snapshot_Owned;


   procedure Test_Render_Surface_Chord_Rows_Are_Snapshot_Owned
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Snap    : Editor.Render_Model.Render_Snapshot;
      Status  : Editor.Keybinding_Management.Keybinding_Action_Status;
      Before  : Unbounded_String;
   begin
      Editor.State.Init (S);
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Keybinding_Management.Show;
      Editor.Keybinding_Management.Focus;
      Editor.Keybinding_Management.Clear_Query;
      Editor.Keybinding_Management.Clear_Filter;
      Editor.Keybinding_Management.Select_Chord ("Ctrl+S", Status);
      Assert
        (Status = Editor.Keybinding_Management.Keybinding_Action_Ok,
         "chord selection fixture must select a default chord");

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (Snap.Keybindings_UI.Display_Chord_Row_Count > 0,
         "keybinding render snapshot must carry bounded chord rows");
      Before := Snap.Keybindings_UI.Display_Chord_Rows (1).Chord_Label;

      Editor.Keybinding_Management.Set_Query ("definitely-no-such-chord");
      Editor.Keybinding_Management.Set_Filter
        (Editor.Keybinding_Management.Filter_Conflicts);
      Editor.Keybinding_Management.Clear_Chord_Selection;

      Assert
        (Snap.Keybindings_UI.Display_Chord_Row_Count > 0
         and then Snap.Keybindings_UI.Display_Chord_Rows (1).Chord_Label = Before,
         "render-facing chord rows must be immutable snapshot data");

      Editor.Keybinding_Management.Hide;
   end Test_Render_Surface_Chord_Rows_Are_Snapshot_Owned;


   overriding function Name
     (T : Keybindings_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Keybindings.Tests");
   end Name;

   overriding procedure Register_Tests
     (T : in out Keybindings_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Default_Shortcuts_Resolve'Access,
         "Default Shortcuts Resolve");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Unknown_Chord_Has_No_Binding'Access,
         "Unknown Chord Has No Binding");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Custom_Bind_And_Unbind'Access,
         "Custom Bind And Unbind");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Plain_Printable_Still_Inserts_Text'Access,
         "Plain Printable Still Inserts Text");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Palette_Key_Input_Does_Not_Edit_Buffer'Access,
         "Palette Key Input Does Not Edit Buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Shift_Left_Extends_Selection'Access,
         "Shift Left Extends Selection");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Navigation_Key_Moves_Caret'Access,
         "Navigation Key Moves Caret");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Escape_Clears_Extra_Carets_When_No_Palette'Access,
         "Escape Clears Extra Carets When No Palette");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Palette_And_Keybindings_Share_Command_Id'Access,
         "Palette And Keybindings Share Command Id");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Bookmark_Keybindings_Dispatch_Through_Executor'Access,
         "Bookmark Keybindings Dispatch Through Executor");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Format_Chord'Access,
         "Format Chord");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Primary_Binding_For_Command'Access,
         "Primary Binding For Command");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Binding_Count_And_Order'Access,
         "Binding Count And Order");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reverse_Lookup_Does_Not_Mutate'Access,
         "Reverse Lookup Does Not Mutate");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Parse_Format_Chord'Access,
         "Parse Format Chord");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Config_Apply_Override_And_Unbind'Access,
         "Config Apply Override And Unbind");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Stable_Command_Name_Roundtrip'Access,
         "Stable Command Name Roundtrip");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Name_Audit'Access,
         "Command Name Audit");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Parse_Chord_Hardening'Access,
         "Parse Chord Hardening");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Runtime_Validation_Summary'Access,
         "Runtime Validation Summary");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Config_Load_Conflict_Last_Wins'Access,
         "Config Load Conflict Last Wins");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Config_Unbind_Load_And_Reset'Access,
         "Config Unbind Load And Reset");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Invalid_And_Partial_Load_Statuses'Access,
         "Invalid And Partial Load Statuses");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Serialization_Stable_And_Drops_Invalid'Access,
         "Serialization Stable And Drops Invalid");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Palette_Uses_Active_Bindings'Access,
         "Command Palette Uses Active Bindings");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Chord_Syntax_Finalization'Access,
         "Chord Syntax Finalization");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Hard_Failed_Reload_Preservation_Model'Access,
         "Hard Failed Reload Preservation Model");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Route_Audit_Helper'Access,
         "Command Route Audit Helper");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Bindability_And_Default_Table_Audit'Access,
         "Bindability And Default Table Audit");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Display_List_Is_Deterministic_And_Scoped'Access,
         "display list is deterministic and scoped");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Assign_Validates_Targets_And_Replaces_Deterministically'Access,
         "assign validates targets and replaces deterministically");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Assign_Rejections_Are_Non_Mutating'Access,
         "assign rejections are non mutating");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Load_Rejects_Internal_Target_Without_Runtime_Mutation'Access,
         "load rejects internal target without runtime mutation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Outline_Keybindings_Register_Defaults'Access,
         "outline keybindings register defaults");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Daily_Workflow_Keybindings_Register_Defaults'Access,
         "Daily workflow keybindings register defaults");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Daily_Workflow_Keybindings_Do_Not_Overwrite_User_Bindings'Access,
         "Daily workflow keybindings do not overwrite user bindings");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Daily_Workflow_Keybinding_Config_Defaults'Access,
         "Daily workflow keybinding config defaults match runtime defaults");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Outline_Keybindings_Do_Not_Overwrite_User_Bindings'Access,
         "outline keybindings do not overwrite user bindings");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Outline_Keybindings_Report_Conflicts_Deterministically'Access,
         "outline keybindings report conflicts deterministically");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Keybinding_User_Readable_Errors_And_No_Payloads'Access,
         "keybinding readable errors and no payloads");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Keybinding_List_Search_And_Filter'Access,
         "keybinding list search and filter");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Filter_Changes_Clear_Stale_Selections'Access,
         "filter changes clear stale selections");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Assign_Conflict_Cancel_Remove_Reset'Access,
         "assign conflict cancel remove reset");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Input_Bridge_Capture_Consumes_And_Assigns'Access,
         "Input_Bridge capture consumes and assigns");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Keybinding_Prompt_Handlers_Capture_And_Confirm'Access,
         "keybinding prompt handlers capture and confirm");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Input_Bridge_Capture_Conflict_Requires_Enter'Access,
         "Input_Bridge capture conflict requires Enter");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Conflict_Confirmation_Uses_Captured_Target'Access,
         "conflict confirmation uses captured target");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Input_Bridge_Focused_Surface_Consumes_Local_Navigation'Access,
         "Input_Bridge focused surface consumes local navigation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Input_Bridge_Focused_Surface_Reset_Confirmation_Keys'Access,
         "Input_Bridge focused surface reset confirmation keys");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Load_No_Payload_And_Coherence'Access,
         "save load no payload and coherence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reset_Confirmation_And_Surface_Guards'Access,
         "reset confirmation and surface guards");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reset_Transient_State_Clears_UI_Only'Access,
         "reset transient state clears UI only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Pending_Confirmations_Block_Keybinding_Mutations'Access,
         "pending confirmations block keybinding mutations");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reset_Commands_Require_Confirmation'Access,
         "reset commands require confirmation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Descriptors_And_Executor_Routes'Access,
         "command descriptors and Executor routes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Load_Diagnostics_Surface_Invalid_Entries'Access,
         "load diagnostics surface invalid entries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Model_Includes_Keybinding_Surface'Access,
         "render model includes keybinding surface");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Surface_Rows_Are_Snapshot_Owned'Access,
         "render surface rows are snapshot owned");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Surface_Chord_Rows_Are_Snapshot_Owned'Access,
         "render surface chord rows are snapshot owned");
   end Register_Tests;

end Editor.Keybindings.Tests;
