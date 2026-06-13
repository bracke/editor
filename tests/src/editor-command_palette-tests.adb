with AUnit.Assertions; use AUnit.Assertions;
with Ada.Containers; use type Ada.Containers.Count_Type;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with Ada.Characters.Handling;
with Interfaces.C;
with Editor.Command_Palette;
with Editor.Executor;
with Editor.Commands;
use type Editor.Commands.Command_Id;
use type Editor.Commands.Command_Category;
use type Editor.Commands.Command_Visibility;
use type Editor.Commands.Command_Availability_Status;
use type Editor.Command_Palette.Command_Palette_Row_Kind;
use type Editor.Command_Palette.Command_Palette_Availability_Filter;
use type Editor.Command_Palette.Command_Palette_Keybinding_Filter;
use type Interfaces.C.int;
with Editor.Buffers;
with Editor.Messages;
with Editor.Input_Bridge;
with Editor.Input_Field;
with Editor.Keybindings;
with Editor.Render_Model;
with Editor.Render_Packet;
with Editor.Render_Layers;
with Editor.State;
with Editor.Empty_State_Guidance;
with Editor.Overlay_Focus;
with Editor.Gutter_Markers;
with Editor.View;
with Text_Buffer;

use type Editor.Buffers.Buffer_Id;
use type Editor.Keybindings.Keybinding_Change_Status;

package body Editor.Command_Palette.Tests is



   function Descriptor_Exists
     (Id : Editor.Commands.Command_Id) return Boolean
   is
      Descriptors : constant Editor.Commands.Command_Descriptor_Vectors.Vector :=
        Editor.Commands.Palette_Commands;
   begin
      for Descriptor of Descriptors loop
         if Descriptor.Id = Id then
            return True;
         end if;
      end loop;

      return False;
   end Descriptor_Exists;

   function Has_Rect_On_Layer
     (Packet : Editor.Render_Packet.Render_Packet;
      Layer  : Editor.Render_Layers.Render_Layer) return Boolean
   is
   begin
      for I in 0 .. Natural (Packet.Rect_Count) - 1 loop
         if Packet.Rects (I).Layer = Editor.Render_Layers.To_C (Layer) then
            return True;
         end if;
      end loop;
      return False;
   end Has_Rect_On_Layer;

   function Has_Glyph_On_Layer
     (Packet : Editor.Render_Packet.Render_Packet;
      Layer  : Editor.Render_Layers.Render_Layer) return Boolean
   is
   begin
      for I in 0 .. Natural (Packet.Glyph_Count) - 1 loop
         if Packet.Glyphs (I).Layer = Editor.Render_Layers.To_C (Layer) then
            return True;
         end if;
      end loop;
      return False;
   end Has_Glyph_On_Layer;


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

   procedure Test_Open_Close
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Editor.Command_Palette.Reset;
      Assert (not Editor.Command_Palette.Is_Open,
              "Palette reset must leave palette closed");
      Editor.Command_Palette.Open;
      Assert (Editor.Command_Palette.Is_Open,
              "Open must mark palette open");
      Editor.Command_Palette.Close;
      Assert (not Editor.Command_Palette.Is_Open,
              "Close must mark palette closed");
   end Test_Open_Close;

   procedure Test_Typing_Backspace_Filtering
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Filtered : Editor.Commands.Command_Descriptor_Vectors.Vector;
   begin
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Append_Character ('s');
      Editor.Command_Palette.Append_Character ('a');
      Editor.Command_Palette.Filtered_Commands (Filtered);
      Assert (Filtered.Length > 0,
              "Query 'sa' must match Save File");
      Assert (Filtered.Element (0).Id = Editor.Commands.Command_Save_File,
              "Save File should be the first descriptor matched by 'sa'");
      Assert (To_String (Editor.Command_Palette.Current.Query) = "sa",
              "Typing must append printable characters to query");
      Editor.Command_Palette.Backspace;
      Assert (To_String (Editor.Command_Palette.Current.Query) = "s",
              "Backspace must remove the final query character");
   end Test_Typing_Backspace_Filtering;

   procedure Test_Selection_Moves
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Move_Selection_Down;
      Assert (Editor.Command_Palette.Current.Selected_Item = 1,
              "Down must move selection to the next filtered item");
      Editor.Command_Palette.Move_Selection_Up;
      Assert (Editor.Command_Palette.Current.Selected_Item = 0,
              "Up must move selection back toward the first filtered item");
   end Test_Selection_Moves;

   procedure Test_Enter_Executes_Selected_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Cmd : Editor.Commands.Command;
      S   : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc");
      Editor.Input_Bridge.Set_State_For_Test (S);

      Cmd.Kind := Editor.Commands.Open_Command_Palette;
      Editor.Input_Bridge.Handle (Cmd);
      declare
         Query : constant String := "goto end";
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

      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert (Snap.Caret_Count > 0 and then Natural (Snap.Caret_Pos (1)) = 3,
              "Executing Goto End from palette must move caret to document end");
      Assert (not Editor.Command_Palette.Is_Open,
              "Accepting a command must close the palette");
   end Test_Enter_Executes_Selected_Command;

   procedure Test_Palette_Input_Does_Not_Edit_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Cmd : Editor.Commands.Command;
      S   : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.Input_Bridge.Set_State_For_Test (S);

      Cmd.Kind := Editor.Commands.Open_Command_Palette;
      Editor.Input_Bridge.Handle (Cmd);
      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'x';
      Cmd.Text := To_Unbounded_String (String'(1 => 'x'));
      Editor.Input_Bridge.Handle (Cmd);
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);

      Assert (Snap.Length = 0,
              "Typing while palette is open must update query, not edit buffer");
      Assert (To_String (Editor.Command_Palette.Current.Query) = "x",
              "Typed character must be stored in palette query");
   end Test_Palette_Input_Does_Not_Edit_Buffer;

   procedure Test_Render_Layers_When_Open_And_Closed
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Cmd : Editor.Commands.Command;
      S   : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Editor.State.Init (S);
      Editor.Input_Bridge.Reset;
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (800, 600);

      Editor.Input_Bridge.Build_Render_Packet (Packet);
      Assert (not Has_Rect_On_Layer (Packet, Editor.Render_Layers.Palette_Background_Layer),
              "Closed palette must emit no palette background rect");
      Assert (not Has_Rect_On_Layer (Packet, Editor.Render_Layers.Palette_Selection_Layer),
              "Closed palette must emit no palette selection rect");
      Assert (not Has_Glyph_On_Layer (Packet, Editor.Render_Layers.Palette_Text_Layer),
              "Closed palette must emit no palette text glyphs");

      Cmd.Kind := Editor.Commands.Open_Command_Palette;
      Editor.Input_Bridge.Handle (Cmd);
      Editor.Input_Bridge.Build_Render_Packet (Packet);
      Assert (Has_Rect_On_Layer (Packet, Editor.Render_Layers.Palette_Background_Layer),
              "Open palette must emit a palette background rect");
      Assert (Has_Rect_On_Layer (Packet, Editor.Render_Layers.Palette_Selection_Layer),
              "Open palette must emit a palette selected-row rect");
      Assert (Has_Glyph_On_Layer (Packet, Editor.Render_Layers.Palette_Text_Layer),
              "Open palette must emit palette text glyphs");
   end Test_Render_Layers_When_Open_And_Closed;

   function Palette_Contains
     (Id : Editor.Commands.Command_Id) return Boolean
   is
      Descriptors : constant Editor.Commands.Command_Descriptor_Vectors.Vector :=
        Editor.Commands.Palette_Commands;
   begin
      for Descriptor of Descriptors loop
         if Descriptor.Id = Id then
            return True;
         end if;
      end loop;

      return False;
   end Palette_Contains;

   procedure Test_Command_Descriptor_Registry_Coverage
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Seen : array (Editor.Commands.Command_Id) of Boolean := (others => False);
      D    : Editor.Commands.Command_Descriptor;
   begin
      Assert (Editor.Commands.Command_Count =
                Editor.Commands.Command_Id'Pos (Editor.Commands.Command_Id'Last) -
                Editor.Commands.Command_Id'Pos (Editor.Commands.Command_Id'First) + 1,
              "Command_Count must cover every Command_Id value");

      for I in 1 .. Editor.Commands.Command_Count loop
         declare
            Id : constant Editor.Commands.Command_Id := Editor.Commands.Command_At (I);
         begin
            Assert (not Seen (Id),
                    "Command_At must not return duplicate command ids");
            Seen (Id) := True;

            D := Editor.Commands.Descriptor (Id);
            Assert (D.Id = Id,
                    "Descriptor must preserve the requested command id");
            Assert (Length (D.Name) > 0,
                    "Every command descriptor must have a stable label");

            if Id = Editor.Commands.No_Command then
               Assert (D.Visibility = Editor.Commands.Hidden_Command,
                       "No_Command must be hidden");
            elsif D.Visibility = Editor.Commands.Palette_Command then
               Assert (Length (D.Description) > 0,
                       "Palette-visible commands must have descriptions");
               Assert (D.Category /= Editor.Commands.Internal_Category,
                       "Palette-visible commands must not use Internal category");
            end if;
         end;
      end loop;

      for Id in Editor.Commands.Command_Id loop
         Assert (Seen (Id),
                 "Command_At must cover every Command_Id exactly once");
      end loop;
   end Test_Command_Descriptor_Registry_Coverage;

   procedure Test_Palette_Uses_Descriptor_Visibility
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Commands.Visible_In_Command_Palette
                (Editor.Commands.Command_Save_File),
              "Save File should be palette-visible through descriptor metadata");
      Assert (Palette_Contains (Editor.Commands.Command_Save_File),
              "Palette candidates must include palette-visible Save File");
      Assert (not Editor.Commands.Visible_In_Command_Palette
                (Editor.Commands.Command_Move_Left),
              "Raw movement commands should be hidden from the palette");
      Assert (not Palette_Contains (Editor.Commands.Command_Move_Left),
              "Palette candidates must exclude hidden raw movement commands");
      Assert (Editor.Commands.Label (Editor.Commands.Command_Save_File) =
                To_String (Editor.Commands.Descriptor
                  (Editor.Commands.Command_Save_File).Name),
              "Label helper must read from the centralized descriptor");
   end Test_Palette_Uses_Descriptor_Visibility;

   procedure Test_Buffer_Command_Descriptors_Exist
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Descriptor_Exists (Editor.Commands.Command_New_Buffer),
              "New Buffer descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Close_Active_Buffer),
              "Close Buffer descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Next_Buffer),
              "Next Buffer descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Previous_Buffer),
              "Previous Buffer descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Previous_Recent_Buffer),
              "Previous Recent Buffer descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Next_Recent_Buffer),
              "Next Recent Buffer descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Save_File),
              "Save descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Save_File_As),
              "Phase 469: Save As descriptor must be projected after target acquisition is canonical");
      Assert (Editor.Commands.Descriptor (Editor.Commands.Command_Save_File_As).Visibility =
                Editor.Commands.Palette_Command,
              "Phase 469: canonical Save As descriptor is palette-visible through the target prompt route");
      Assert (Descriptor_Exists (Editor.Commands.Command_Toggle_Problems_Panel),
              "Toggle Problems descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Focus_Problems),
              "Focus Problems descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Problems_Open_Selected),
              "Open Selected Problem descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Problems_Move_Up),
              "Move Problem Selection Up descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Problems_Move_Down),
              "Move Problem Selection Down descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Filter_Clear),
              "Clear Buffer Switcher Filter descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Filter_Pinned),
              "Pinned Buffer Switcher Filter descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Filter_Group),
              "Group Buffer Switcher Filter descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Filter_Label),
              "Label Buffer Switcher Filter descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Filter_Noted),
              "Noted Buffer Switcher Filter descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Sort_Default),
              "Default Buffer Switcher Sort descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Sort_Recent),
              "Recent Buffer Switcher Sort descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Sort_Name),
              "Name Buffer Switcher Sort descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Sort_Pinned),
              "Pinned Buffer Switcher Sort descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Sort_Group),
              "Group Buffer Switcher Sort descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Sort_Label),
              "Label Buffer Switcher Sort descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Sort_Next),
              "Next Buffer Switcher Sort descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Sort_Previous),
              "Previous Buffer Switcher Sort descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Selected_Close),
              "Selected Buffer Switcher Close descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Selected_Pin),
              "Selected Buffer Switcher Pin descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Selected_Unpin),
              "Selected Buffer Switcher Unpin descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Selected_Toggle_Pin),
              "Selected Buffer Switcher Toggle Pin descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Selected_Group_Assign),
              "Selected Buffer Switcher Assign Group descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Selected_Group_Clear),
              "Selected Buffer Switcher Clear Group descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Selected_Label_Set),
              "Selected Buffer Switcher Set Label descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Selected_Label_Clear),
              "Selected Buffer Switcher Clear Label descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Selected_Note_Set),
              "Selected Buffer Switcher Set Note descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Selected_Note_Clear),
              "Selected Buffer Switcher Clear Note descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Preview_Toggle),
              "Buffer Switcher Preview Toggle descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Preview_Show),
              "Buffer Switcher Preview Show descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Preview_Hide),
              "Buffer Switcher Preview Hide descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Preview_Next_Line),
              "Buffer Switcher Preview Next Line descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Preview_Previous_Line),
              "Buffer Switcher Preview Previous Line descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Preview_Center_Cursor),
              "Buffer Switcher Preview Center Cursor descriptor must exist");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Filter_Clear) =
              "buffers.switcher.filter.clear",
              "clear switcher filter stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Filter_Pinned) =
              "buffers.switcher.filter.pinned",
              "pinned switcher filter stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Filter_Group) =
              "buffers.switcher.filter.group",
              "group switcher filter stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Filter_Label) =
              "buffers.switcher.filter.label",
              "label switcher filter stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Filter_Noted) =
              "buffers.switcher.filter.noted",
              "noted switcher filter stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Sort_Default) =
              "buffers.switcher.sort.default",
              "default switcher sort stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Sort_Recent) =
              "buffers.switcher.sort.recent",
              "recent switcher sort stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Sort_Name) =
              "buffers.switcher.sort.name",
              "name switcher sort stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Sort_Pinned) =
              "buffers.switcher.sort.pinned",
              "pinned switcher sort stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Sort_Group) =
              "buffers.switcher.sort.group",
              "group switcher sort stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Sort_Label) =
              "buffers.switcher.sort.label",
              "label switcher sort stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Sort_Next) =
              "buffers.switcher.sort.next",
              "next switcher sort stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Sort_Previous) =
              "buffers.switcher.sort.previous",
              "previous switcher sort stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Selected_Close) =
              "buffers.switcher.selected.close",
              "selected switcher close stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Selected_Pin) =
              "buffers.switcher.selected.pin",
              "selected switcher pin stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Selected_Unpin) =
              "buffers.switcher.selected.unpin",
              "selected switcher unpin stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Selected_Toggle_Pin) =
              "buffers.switcher.selected.toggle-pin",
              "selected switcher toggle pin stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Selected_Group_Assign) =
              "buffers.switcher.selected.group.assign",
              "selected switcher assign group stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Selected_Group_Clear) =
              "buffers.switcher.selected.group.clear",
              "selected switcher clear group stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Selected_Label_Set) =
              "buffers.switcher.selected.label.set",
              "selected switcher set label stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Selected_Label_Clear) =
              "buffers.switcher.selected.label.clear",
              "selected switcher clear label stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Selected_Note_Set) =
              "buffers.switcher.selected.note.set",
              "selected switcher set note stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Selected_Note_Clear) =
              "buffers.switcher.selected.note.clear",
              "selected switcher clear note stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Preview_Toggle) =
              "buffers.switcher.preview.toggle",
              "switcher preview toggle stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Preview_Show) =
              "buffers.switcher.preview.show",
              "switcher preview show stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Preview_Hide) =
              "buffers.switcher.preview.hide",
              "switcher preview hide stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Preview_Next_Line) =
              "buffers.switcher.preview.next-line",
              "switcher preview next line stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Preview_Previous_Line) =
              "buffers.switcher.preview.previous-line",
              "switcher preview previous line stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Preview_Center_Cursor) =
              "buffers.switcher.preview.center-cursor",
              "switcher preview center cursor stable name must be persisted-command safe");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Mark_Visible),
              "Phase 280 mark visible descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Mark_Clear_Visible),
              "Phase 280 clear visible marks descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Mark_Pinned),
              "Phase 280 mark pinned descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Mark_Group),
              "Phase 280 mark group descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Mark_Label),
              "Phase 280 mark label descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Mark_Noted),
              "Phase 280 mark noted descriptor must exist");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Mark_Visible) =
              "buffers.switcher.mark.visible",
              "Phase 280 mark visible stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Mark_Clear_Visible) =
              "buffers.switcher.mark.clear-visible",
              "Phase 280 clear visible stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Mark_Pinned) =
              "buffers.switcher.mark.pinned",
              "Phase 280 mark pinned stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Mark_Group) =
              "buffers.switcher.mark.group",
              "Phase 280 mark group stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Mark_Label) =
              "buffers.switcher.mark.label",
              "Phase 280 mark label stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Mark_Noted) =
              "buffers.switcher.mark.noted",
              "Phase 280 mark noted stable name must be persisted-command safe");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Mark_Group_Assign),
              "Phase 279 marked group assign descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Mark_Group_Clear),
              "Phase 279 marked group clear descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Mark_Label_Set),
              "Phase 279 marked label set descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Mark_Label_Clear),
              "Phase 279 marked label clear descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Mark_Note_Set),
              "Phase 279 marked note set descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Mark_Note_Clear),
              "Phase 279 marked note clear descriptor must exist");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Mark_Group_Assign) =
              "buffers.switcher.mark.group.assign",
              "Phase 279 marked group assign stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Mark_Group_Clear) =
              "buffers.switcher.mark.group.clear",
              "Phase 279 marked group clear stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Mark_Label_Set) =
              "buffers.switcher.mark.label.set",
              "Phase 279 marked label set stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Mark_Label_Clear) =
              "buffers.switcher.mark.label.clear",
              "Phase 279 marked label clear stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Mark_Note_Set) =
              "buffers.switcher.mark.note.set",
              "Phase 279 marked note set stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Mark_Note_Clear) =
              "buffers.switcher.mark.note.clear",
              "Phase 279 marked note clear stable name must be persisted-command safe");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Mark_Confirm),
              "Phase 282 marked confirm descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Mark_Cancel),
              "Phase 282 marked cancel descriptor must exist");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Mark_Confirm) =
              "buffers.switcher.mark.confirm",
              "Phase 282 marked confirm stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Mark_Cancel) =
              "buffers.switcher.mark.cancel",
              "Phase 282 marked cancel stable name must be persisted-command safe");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Mark_Review_Toggle),
              "Phase 281 marked review toggle descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Mark_Review_Show),
              "Phase 281 marked review show descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Mark_Review_Hide),
              "Phase 281 marked review hide descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Mark_Next),
              "Phase 281 marked next descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Mark_Previous),
              "Phase 281 marked previous descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Mark_Summary),
              "Phase 281 marked summary descriptor must exist");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Mark_Review_Toggle) =
              "buffers.switcher.mark.review.toggle",
              "Phase 281 marked review toggle stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Mark_Review_Show) =
              "buffers.switcher.mark.review.show",
              "Phase 281 marked review show stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Mark_Review_Hide) =
              "buffers.switcher.mark.review.hide",
              "Phase 281 marked review hide stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Mark_Next) =
              "buffers.switcher.mark.next",
              "Phase 281 marked next stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Mark_Previous) =
              "buffers.switcher.mark.previous",
              "Phase 281 marked previous stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Mark_Summary) =
              "buffers.switcher.mark.summary",
              "Phase 281 marked summary stable name must be persisted-command safe");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Review_Toggle),
              "Phase 283 pending marked review toggle descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Review_Show),
              "Phase 283 pending marked review show descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Review_Hide),
              "Phase 283 pending marked review hide descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Next),
              "Phase 283 pending marked next descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Previous),
              "Phase 283 pending marked previous descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Summary),
              "Phase 283 pending marked summary descriptor must exist");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Review_Toggle) =
              "buffers.switcher.pending-mark.review.toggle",
              "Phase 283 pending marked review toggle stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Review_Show) =
              "buffers.switcher.pending-mark.review.show",
              "Phase 283 pending marked review show stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Review_Hide) =
              "buffers.switcher.pending-mark.review.hide",
              "Phase 283 pending marked review hide stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Next) =
              "buffers.switcher.pending-mark.next",
              "Phase 283 pending marked next stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Previous) =
              "buffers.switcher.pending-mark.previous",
              "Phase 283 pending marked previous stable name must be persisted-command safe");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Summary) =
              "buffers.switcher.pending-mark.summary",
              "Phase 283 pending marked summary stable name must be persisted-command safe");
   end Test_Buffer_Command_Descriptors_Exist;

   procedure Test_Buffer_Command_Id_Dispatch
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      First  : Editor.Buffers.Buffer_Id;
      Second : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      First := Editor.Buffers.Global_Active_Buffer;

      Editor.Input_Bridge.Execute_Command_Id (Editor.Commands.Command_New_Buffer);
      Second := Editor.Buffers.Global_Active_Buffer;
      Assert (Editor.Buffers.Global_Count = 2,
              "New Buffer command id should create a buffer through dispatch");
      Assert (Second /= First,
              "New Buffer command id should activate the new buffer");

      Editor.Input_Bridge.Execute_Command_Id (Editor.Commands.Command_Previous_Buffer);
      Assert (Editor.Buffers.Global_Active_Buffer = First,
              "Previous Buffer command id should dispatch to executor switching");

      Editor.Input_Bridge.Execute_Command_Id (Editor.Commands.Command_Next_Buffer);
      Assert (Editor.Buffers.Global_Active_Buffer = Second,
              "Next Buffer command id should dispatch to executor switching");

      Editor.Input_Bridge.Execute_Command_Id (Editor.Commands.Command_Close_Active_Buffer);
      Assert (Editor.Buffers.Global_Count = 1,
              "Close Buffer command id should close the active clean buffer");
   end Test_Buffer_Command_Id_Dispatch;

   procedure Test_Save_As_Descriptor_Requires_Path
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Snap  : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "save as requires explicit path");
      S.File_Info.Dirty := True;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Input_Bridge.Set_State_For_Test (S);

      Editor.Input_Bridge.Execute_Command_Id (Editor.Commands.Command_Save_File_As);
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);

      Assert (Snap.File_Target_Prompt_Visible
        and then To_String (Snap.File_Target_Prompt_Label) = "Save As target",
        "Save As descriptor dispatch should open deterministic target prompt");
      Assert (Editor.Messages.Count (Snap.Messages) = 0,
        "Save As prompt opening should not publish underlying command feedback");
   end Test_Save_As_Descriptor_Requires_Path;


   procedure Test_Message_Command_Descriptors_And_Dispatch
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Snap  : Editor.Render_Model.Render_Snapshot;
      Found : Boolean := False;
      M     : Editor.Messages.Editor_Message;
   begin
      Assert (Palette_Contains (Editor.Commands.Command_Dismiss_All_Messages),
              "Dismiss All Messages must be palette-visible");
      Assert (not Palette_Contains (Editor.Commands.Command_Dismiss_Latest_Message),
              "Dismiss Latest Message must remain hidden from palette candidates");

      Editor.State.Init (S);
      Editor.Messages.Push_Info (S.Messages, "one");
      Editor.Messages.Push_Warning (S.Messages, "two");
      Editor.Input_Bridge.Set_State_For_Test (S);

      Editor.Input_Bridge.Execute_Command_Id
        (Editor.Commands.Command_Dismiss_Latest_Message);
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      M := Editor.Messages.Active_Message (Snap.Messages, Found);
      Assert (Found and then To_String (M.Text) = "one",
              "Dismiss Latest Message must remove only the newest transient message");

      Editor.Input_Bridge.Execute_Command_Id
        (Editor.Commands.Command_Dismiss_All_Messages);
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert (not Editor.Messages.Has_Messages (Snap.Messages),
              "Dismiss All Messages must clear transient message state");
   end Test_Message_Command_Descriptors_And_Dispatch;


   procedure Test_Bookmark_Command_Descriptors_Exist
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Descriptor_Exists (Editor.Commands.Command_Toggle_Bookmark),
              "Toggle Bookmark descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Next_Bookmark),
              "Next Bookmark descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Previous_Bookmark),
              "Previous Bookmark descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Clear_Bookmarks),
              "Clear Buffer Bookmarks descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Clear_All_Bookmarks),
              "Clear All Bookmarks descriptor must exist");
   end Test_Bookmark_Command_Descriptors_Exist;

   procedure Test_Bookmark_Command_Id_Dispatch
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "b" & ASCII.LF & "c");
      Editor.Input_Bridge.Set_State_For_Test (S);

      Editor.Input_Bridge.Execute_Command_Id (Editor.Commands.Command_Toggle_Bookmark);
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert (Editor.Gutter_Markers.Has_Marker
        (Snap.Gutter_Markers, 0, Editor.Gutter_Markers.Bookmark_Marker),
        "Toggle Bookmark command id should dispatch through executor");

      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 0, Editor.Gutter_Markers.Bookmark_Marker);
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 2, Editor.Gutter_Markers.Bookmark_Marker);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Execute_Command_Id (Editor.Commands.Command_Next_Bookmark);
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert (Snap.Caret_Count > 0 and then Natural (Snap.Caret_Pos (1)) = 4,
              "Next Bookmark command id should move to the next bookmark");

      Editor.Input_Bridge.Execute_Command_Id (Editor.Commands.Command_Previous_Bookmark);
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert (Snap.Caret_Count > 0 and then Natural (Snap.Caret_Pos (1)) = 0,
              "Previous Bookmark command id should move to the previous bookmark");

      Editor.Input_Bridge.Execute_Command_Id (Editor.Commands.Command_Clear_Bookmarks);
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert (not Editor.Gutter_Markers.Has_Bookmarks (Snap.Gutter_Markers),
              "Clear Buffer Bookmarks command id should remove active-buffer bookmarks");

      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 1, Editor.Gutter_Markers.Bookmark_Marker);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Execute_Command_Id (Editor.Commands.Command_Clear_All_Bookmarks);
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert (not Editor.Gutter_Markers.Has_Bookmarks (Snap.Gutter_Markers),
              "Clear All Bookmarks command id should remove active-buffer bookmarks");
   end Test_Bookmark_Command_Id_Dispatch;




   procedure Test_Command_Availability_Result_Model
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      A : constant Editor.Commands.Command_Availability :=
        Editor.Commands.Available;
      U : constant Editor.Commands.Command_Availability :=
        Editor.Commands.Unavailable ("No project open.");
   begin
      Assert (A.Status = Editor.Commands.Command_Available,
              "Available must use Command_Available status");
      Assert (Editor.Commands.Is_Available (A),
              "Is_Available must return True for Available");
      Assert (Editor.Commands.Unavailable_Reason (A) = "",
              "Available must have an empty reason");

      Assert (U.Status = Editor.Commands.Command_Unavailable,
              "Unavailable must use Command_Unavailable status");
      Assert (not Editor.Commands.Is_Available (U),
              "Is_Available must return False for Unavailable");
      Assert (Editor.Commands.Unavailable_Reason (U) = "No project open.",
              "Unavailable_Reason must return the exact stable reason");
   end Test_Command_Availability_Result_Model;

   procedure Test_Palette_Candidate_Includes_Unavailable_Reason
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Found : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("quick open");

      Editor.Executor.Command_Palette_Candidates (S, Candidates);

      for Candidate of Candidates loop
         if Candidate.Id = Editor.Commands.Command_Open_Quick_Open then
            Found := True;
            Assert (not Candidate.Available,
                    "Quick Open must be disabled without an open project");
            Assert (To_String (Candidate.Reason) = "No project open.",
                    "Unavailable palette candidate must carry the reason");
         end if;
      end loop;

      Assert (Found,
              "Palette candidates must still include unavailable visible commands");
   end Test_Palette_Candidate_Includes_Unavailable_Reason;

   procedure Test_Hidden_Command_Availability_Reasons
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Editor.Commands.Command_Availability;
   begin
      Editor.State.Init (S);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Accept_Quick_Open);
      Assert (not Editor.Commands.Is_Available (A),
              "Accept Quick Open must be unavailable without active overlay");
      Assert (Editor.Commands.Unavailable_Reason (A) = "No active overlay",
              "Accept Quick Open must report stable inactive-overlay reason");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_File_Tree_Expand_Selected);
      Assert (not Editor.Commands.Is_Available (A),
              "File Tree Expand Selected must be unavailable without project");
      Assert (Editor.Commands.Unavailable_Reason (A) = "No project open.",
              "File Tree Expand Selected must report stable no-project reason");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Dismiss_Latest_Message);
      Assert (not Editor.Commands.Is_Available (A),
              "Dismiss Latest Message must be unavailable without messages");
      Assert (Editor.Commands.Unavailable_Reason (A) = "No messages",
              "Dismiss Latest Message must report stable empty-message reason");
   end Test_Hidden_Command_Availability_Reasons;

   procedure Test_Enter_Unavailable_Command_Keeps_Palette_Open
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Cmd : Editor.Commands.Command;
      S   : Editor.State.State_Type;
      After : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Input_Bridge.Reset;
      Editor.Input_Bridge.Set_State_For_Test (S);

      Cmd.Kind := Editor.Commands.Open_Command_Palette;
      Editor.Input_Bridge.Handle (Cmd);
      declare
         Query : constant String := "quick open";
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
      After := Editor.Input_Bridge.Get_State_For_Test;

      Assert (Editor.Command_Palette.Is_Open,
              "Accepting an unavailable command must keep the palette open");
      Assert (Editor.Messages.Count (After.Messages) > 0,
              "Accepting an unavailable command must push feedback");
   end Test_Enter_Unavailable_Command_Keeps_Palette_Open;


   procedure Test_Phase84_Category_Labels
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Commands.Category_Label (Editor.Commands.File_Category) = "File",
              "File category must have centralized palette label");
      Assert (Editor.Commands.Category_Label (Editor.Commands.Panel_Category) = "Panels",
              "Panel category must use user-facing plural label");
      Assert (Editor.Commands.Category_Label (Editor.Commands.Internal_Category) = "Internal",
              "Internal category must have a centralized debug label");
   end Test_Phase84_Category_Labels;

   procedure Test_Phase84_Match_Score_Order
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Exact     : constant Natural := Editor.Command_Palette.Match_Score
        ("Save File", "File", "Save the active buffer", "save file");
      Prefix    : constant Natural := Editor.Command_Palette.Match_Score
        ("Save File", "File", "Save the active buffer", "sav");
      Substring : constant Natural := Editor.Command_Palette.Match_Score
        ("Clear Search", "Search", "Clear feature search results", "search");
      Category  : constant Natural := Editor.Command_Palette.Match_Score
        ("Find Next", "Search", "Move to next match", "search");
      Reason    : constant Natural := Editor.Command_Palette.Match_Score
        ("Find Next", "Search", "Move to next match", "No active buffer.");
   begin
      Assert (Exact > Prefix,
              "Exact label match must rank above prefix match");
      Assert (Prefix > Substring,
              "Prefix label match must rank above substring match");
      Assert (Substring > Category,
              "Label substring match must rank above category match");
      Assert (Reason = 0,
              "Unavailable reasons must not be searched as command identity");
   end Test_Phase84_Match_Score_Order;

   procedure Test_Phase84_Grouped_Snapshot_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Config     : constant Editor.Command_Palette.Command_Palette_Config := (others => <>);
      Snapshot   : Editor.Command_Palette.Command_Palette_Snapshot;
      Found      : Boolean := False;
      Index      : Natural := 0;
   begin
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Candidates.Append
        (Editor.Commands.Command_Palette_Candidate'
           (Id             => Editor.Commands.Command_Save_File,
          Label          => To_Unbounded_String ("Save File"),
          Description    => To_Unbounded_String ("Save the active buffer"),
          Category       => Editor.Commands.File_Category,
          Category_Label => To_Unbounded_String ("File"),
          Available      => True,
          Reason         => Null_Unbounded_String,
          Has_Keybinding => False,
          Keybinding_Display => Null_Unbounded_String,
          Reference_Summary => Null_Unbounded_String,
          Family => Editor.Commands.No_Command_Family,
          Effect_Classification => Editor.Commands.No_Command_Effect,
          Match_Score    => 1,
          Registry_Order => 1));
      Candidates.Append
        (Editor.Commands.Command_Palette_Candidate'
           (Id             => Editor.Commands.Command_Active_Find_Next,
          Label          => To_Unbounded_String ("Find Next"),
          Description    => To_Unbounded_String ("Move to next match"),
          Category       => Editor.Commands.Search_Category,
          Category_Label => To_Unbounded_String ("Search"),
          Available      => False,
          Reason         => To_Unbounded_String ("No active Find matches"),
          Has_Keybinding => False,
          Keybinding_Display => Null_Unbounded_String,
          Reference_Summary => Null_Unbounded_String,
          Family => Editor.Commands.No_Command_Family,
          Effect_Classification => Editor.Commands.No_Command_Effect,
          Match_Score    => 1,
          Registry_Order => 2));

      Snapshot := Editor.Command_Palette.Build_Snapshot (Candidates, Config);
      Assert (Editor.Command_Palette.Row_Count (Snapshot) = 4,
              "Grouped empty-query snapshot must include headers and command rows");
      Assert (Editor.Command_Palette.Row (Snapshot, 1).Kind =
                Editor.Command_Palette.Command_Palette_Header_Row,
              "First grouped row must be a category header");
      Assert (Editor.Command_Palette.Row (Snapshot, 2).Kind =
                Editor.Command_Palette.Command_Palette_Command_Row,
              "Second grouped row must be a command row");
      Index := Editor.Command_Palette.Candidate_For_Row (Snapshot, 1, Found);
      Assert ((not Found) and then Index = 0,
              "Header rows must not map to executable candidates");
      Index := Editor.Command_Palette.Candidate_For_Row (Snapshot, 2, Found);
      Assert (Found and then Index = 0,
              "Command rows must map to candidate indexes");
      Index := Editor.Command_Palette.Row_For_Candidate (Snapshot, 1, Found);
      Assert (Found and then Index = 4,
              "Candidate-to-row mapping must account for category headers");
   end Test_Phase84_Grouped_Snapshot_Rows;

   procedure Test_Phase84_Empty_Query_Sort_Keeps_Category_Runs
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Config     : constant Editor.Command_Palette.Command_Palette_Config := (others => <>);
      Snapshot   : Editor.Command_Palette.Command_Palette_Snapshot;
   begin
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Candidates.Append
        (Editor.Commands.Command_Palette_Candidate'
           (Id             => Editor.Commands.Command_Active_Find_Next,
          Label          => To_Unbounded_String ("Find Next"),
          Description    => To_Unbounded_String ("Move to next match"),
          Category       => Editor.Commands.Search_Category,
          Category_Label => To_Unbounded_String ("Search"),
          Available      => True,
          Reason         => Null_Unbounded_String,
          Has_Keybinding => False,
          Keybinding_Display => Null_Unbounded_String,
          Reference_Summary => Null_Unbounded_String,
          Family => Editor.Commands.No_Command_Family,
          Effect_Classification => Editor.Commands.No_Command_Effect,
          Match_Score    => 1,
          Registry_Order => 20));
      Candidates.Append
        (Editor.Commands.Command_Palette_Candidate'
           (Id             => Editor.Commands.Command_Save_File,
          Label          => To_Unbounded_String ("Save File"),
          Description    => To_Unbounded_String ("Save the active buffer"),
          Category       => Editor.Commands.File_Category,
          Category_Label => To_Unbounded_String ("File"),
          Available      => False,
          Reason         => To_Unbounded_String ("No active buffer."),
          Has_Keybinding => False,
          Keybinding_Display => Null_Unbounded_String,
          Reference_Summary => Null_Unbounded_String,
          Family => Editor.Commands.No_Command_Family,
          Effect_Classification => Editor.Commands.No_Command_Effect,
          Match_Score    => 1,
          Registry_Order => 10));
      Candidates.Append
        (Editor.Commands.Command_Palette_Candidate'
           (Id             => Editor.Commands.Command_Save_File_As,
          Label          => To_Unbounded_String ("Save As"),
          Description    => To_Unbounded_String ("Save the active buffer to a path"),
          Category       => Editor.Commands.File_Category,
          Category_Label => To_Unbounded_String ("File"),
          Available      => True,
          Reason         => Null_Unbounded_String,
          Has_Keybinding => False,
          Keybinding_Display => Null_Unbounded_String,
          Reference_Summary => Null_Unbounded_String,
          Family => Editor.Commands.No_Command_Family,
          Effect_Classification => Editor.Commands.No_Command_Effect,
          Match_Score    => 1,
          Registry_Order => 11));

      Editor.Command_Palette.Sort_Candidates (Candidates);
      Snapshot := Editor.Command_Palette.Build_Snapshot (Candidates, Config);

      Assert (Editor.Command_Palette.Row_Count (Snapshot) = 5,
              "Grouped snapshot must not duplicate a category header for split availability runs");
      Assert (Editor.Command_Palette.Row (Snapshot, 1).Primary_Text = To_Unbounded_String ("File"),
              "File header must be first in category order for an empty query");
      Assert (Editor.Command_Palette.Row (Snapshot, 2).Kind =
                Editor.Command_Palette.Command_Palette_Command_Row,
              "First File command row must directly follow the File header");
      Assert (Editor.Command_Palette.Candidate (Snapshot,
                Editor.Command_Palette.Row (Snapshot, 2).Candidate_Index).Available,
              "Available command should lead unavailable command inside the same category");
      Assert (Editor.Command_Palette.Row (Snapshot, 4).Primary_Text = To_Unbounded_String ("Search"),
              "Search header must appear once after the contiguous File group");
   end Test_Phase84_Empty_Query_Sort_Keeps_Category_Runs;

   procedure Test_Phase84_Nonempty_Query_Builds_Flat_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Config     : constant Editor.Command_Palette.Command_Palette_Config := (others => <>);
      Snapshot   : Editor.Command_Palette.Command_Palette_Snapshot;
   begin
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("save");
      Candidates.Append
        (Editor.Commands.Command_Palette_Candidate'
           (Id             => Editor.Commands.Command_Save_File,
          Label          => To_Unbounded_String ("Save File"),
          Description    => To_Unbounded_String ("Save the active buffer"),
          Category       => Editor.Commands.File_Category,
          Category_Label => To_Unbounded_String ("File"),
          Available      => True,
          Reason         => Null_Unbounded_String,
          Has_Keybinding => False,
          Keybinding_Display => Null_Unbounded_String,
          Reference_Summary => Null_Unbounded_String,
          Family => Editor.Commands.No_Command_Family,
          Effect_Classification => Editor.Commands.No_Command_Effect,
          Match_Score    => 500,
          Registry_Order => 10));
      Candidates.Append
        (Editor.Commands.Command_Palette_Candidate'
           (Id             => Editor.Commands.Command_Save_File_As,
          Label          => To_Unbounded_String ("Save As"),
          Description    => To_Unbounded_String ("Save the active buffer to a path"),
          Category       => Editor.Commands.File_Category,
          Category_Label => To_Unbounded_String ("File"),
          Available      => True,
          Reason         => Null_Unbounded_String,
          Has_Keybinding => False,
          Keybinding_Display => Null_Unbounded_String,
          Reference_Summary => Null_Unbounded_String,
          Family => Editor.Commands.No_Command_Family,
          Effect_Classification => Editor.Commands.No_Command_Effect,
          Match_Score    => 500,
          Registry_Order => 11));

      Snapshot := Editor.Command_Palette.Build_Snapshot (Candidates, Config);
      Assert (Editor.Command_Palette.Row_Count (Snapshot) = 2,
              "Non-empty query should produce a flat ranked command list");
      Assert (Editor.Command_Palette.Row (Snapshot, 1).Kind =
                Editor.Command_Palette.Command_Palette_Command_Row,
              "Filtered row 1 must be a command row, not a category header");
      Assert (Editor.Command_Palette.Row (Snapshot, 2).Kind =
                Editor.Command_Palette.Command_Palette_Command_Row,
              "Filtered row 2 must be a command row, not a category header");
   end Test_Phase84_Nonempty_Query_Builds_Flat_Rows;

   procedure Test_Phase84_Ensure_Selected_Row_Visible
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Config     : constant Editor.Command_Palette.Command_Palette_Config := (others => <>);
      Snapshot   : Editor.Command_Palette.Command_Palette_Snapshot;
   begin
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Candidates.Append
        (Editor.Commands.Command_Palette_Candidate'
           (Id             => Editor.Commands.Command_Save_File,
          Label          => To_Unbounded_String ("Save File"),
          Description    => To_Unbounded_String ("Save the active buffer"),
          Category       => Editor.Commands.File_Category,
          Category_Label => To_Unbounded_String ("File"),
          Available      => True,
          Reason         => Null_Unbounded_String,
          Has_Keybinding => False,
          Keybinding_Display => Null_Unbounded_String,
          Reference_Summary => Null_Unbounded_String,
          Family => Editor.Commands.No_Command_Family,
          Effect_Classification => Editor.Commands.No_Command_Effect,
          Match_Score    => 1,
          Registry_Order => 10));
      Candidates.Append
        (Editor.Commands.Command_Palette_Candidate'
           (Id             => Editor.Commands.Command_Active_Find_Next,
          Label          => To_Unbounded_String ("Find Next"),
          Description    => To_Unbounded_String ("Move to next match"),
          Category       => Editor.Commands.Search_Category,
          Category_Label => To_Unbounded_String ("Search"),
          Available      => True,
          Reason         => Null_Unbounded_String,
          Has_Keybinding => False,
          Keybinding_Display => Null_Unbounded_String,
          Reference_Summary => Null_Unbounded_String,
          Family => Editor.Commands.No_Command_Family,
          Effect_Classification => Editor.Commands.No_Command_Effect,
          Match_Score    => 1,
          Registry_Order => 20));

      Editor.Command_Palette.Reconcile_Selection
        (Candidates, Editor.Commands.Command_Active_Find_Next);
      Snapshot := Editor.Command_Palette.Build_Snapshot (Candidates, Config);
      Editor.Command_Palette.Ensure_Selected_Row_Visible (Snapshot, 2);

      Assert (Editor.Command_Palette.Current.Selected_Candidate_Index = 1,
              "Reconcile_Selection must preserve the selected command id when present");
      Assert (Editor.Command_Palette.Current.Top_Row = 3,
              "Selected row below the visible window must advance Top_Row");
   end Test_Phase84_Ensure_Selected_Row_Visible;

   procedure Test_Phase84_Reconcile_Selects_Only_Unavailable_Match
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
   begin
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Candidates.Append
        (Editor.Commands.Command_Palette_Candidate'
           (Id             => Editor.Commands.Command_Save_File,
          Label          => To_Unbounded_String ("Save File"),
          Description    => To_Unbounded_String ("Save the active buffer"),
          Category       => Editor.Commands.File_Category,
          Category_Label => To_Unbounded_String ("File"),
          Available      => False,
          Reason         => To_Unbounded_String ("No active buffer."),
          Has_Keybinding => False,
          Keybinding_Display => Null_Unbounded_String,
          Reference_Summary => Null_Unbounded_String,
          Family => Editor.Commands.No_Command_Family,
          Effect_Classification => Editor.Commands.No_Command_Effect,
          Match_Score    => 500,
          Registry_Order => 10));

      Editor.Command_Palette.Reconcile_Selection (Candidates);
      Assert (Editor.Command_Palette.Current.Selected_Candidate_Index = 0,
              "Unavailable-only result sets must still select the only command candidate");
   end Test_Phase84_Reconcile_Selects_Only_Unavailable_Match;



   procedure Test_Phase85_Candidate_Includes_Keybinding
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Found : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("save file");

      Editor.Executor.Command_Palette_Candidates (S, Candidates);

      for Candidate of Candidates loop
         if Candidate.Id = Editor.Commands.Command_Save_File then
            Found := True;
            Assert (Candidate.Has_Keybinding,
                    "Save File candidate must carry keybinding metadata");
            Assert (To_String (Candidate.Keybinding_Display) = "Ctrl+S",
                    "Save File candidate must display Ctrl+S");
         end if;
      end loop;

      Assert (Found, "Save File candidate must be present");
   end Test_Phase85_Candidate_Includes_Keybinding;

   procedure Test_Phase85_Unbound_Candidate_Has_No_Keybinding
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Found : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("open file");

      Editor.Executor.Command_Palette_Candidates (S, Candidates);

      for Candidate of Candidates loop
         if Candidate.Id = Editor.Commands.Command_Open_File then
            Found := True;
            Assert (not Candidate.Has_Keybinding,
                    "Unbound command candidate must not report a keybinding");
            Assert (Length (Candidate.Keybinding_Display) = 0,
                    "Unbound command candidate must not have display text");
         end if;
      end loop;

      Assert (Found, "Open File candidate must be present");
   end Test_Phase85_Unbound_Candidate_Has_No_Keybinding;

   procedure Test_Phase85_Unavailable_Candidate_Still_Shows_Keybinding
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Found : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("quick open");

      Editor.Executor.Command_Palette_Candidates (S, Candidates);

      for Candidate of Candidates loop
         if Candidate.Id = Editor.Commands.Command_Open_Quick_Open then
            Found := True;
            Assert (not Candidate.Available,
                    "Quick Open must be unavailable without project");
            Assert (Candidate.Has_Keybinding,
                    "Unavailable bound commands must still show keybindings");
            Assert (To_String (Candidate.Keybinding_Display) = "Ctrl+P",
                    "Quick Open candidate must display Ctrl+P even when unavailable");
         end if;
      end loop;

      Assert (Found, "Quick Open candidate must be present");
   end Test_Phase85_Unavailable_Candidate_Still_Shows_Keybinding;

   procedure Test_Phase564_Filter_Matches_Keybinding_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
   begin
      Editor.State.Init (S);
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("ctrl+s");

      Editor.Executor.Command_Palette_Candidates (S, Candidates);
      declare
         Found : Boolean := False;
      begin
         for Candidate of Candidates loop
            if Candidate.Id = Editor.Commands.Command_Save_File then
               Found := True;
               Assert (To_String (Candidate.Keybinding_Display) = "Ctrl+S",
                       "Keybinding match must carry active keybinding display");
            end if;
         end loop;

         Assert (Found,
                 "Phase 564 command search must match active keybinding display text");
      end;
   end Test_Phase564_Filter_Matches_Keybinding_Text;

   procedure Test_Phase564_Keybinding_Search_Obeys_Display_Setting
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Results : Editor.Commands.Command_Descriptor_Vectors.Vector;
      Found_Save : Boolean := False;
      Config : Editor.Command_Palette.Command_Palette_Config;
   begin
      Editor.State.Init (S);
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Command_Palette.Reset;
      Config := Editor.Command_Palette.Current_Config;
      Config.Show_Keybindings := False;
      Editor.Command_Palette.Set_Current_Config (Config);
      Editor.Command_Palette.Open;
      Config := Editor.Command_Palette.Current_Config;
      Config.Show_Keybindings := False;
      Editor.Command_Palette.Set_Current_Config (Config);
      Editor.Command_Palette.Insert_Text ("ctrl+s");

      Editor.Executor.Command_Palette_Candidates (S, Candidates);
      for Candidate of Candidates loop
         if Candidate.Id = Editor.Commands.Command_Save_File then
            Found_Save := True;
         end if;
      end loop;
      Assert (not Found_Save,
              "Phase 564 keybinding-text search must obey hidden keybinding display setting in Executor projection");

      Found_Save := False;
      Editor.Command_Palette.Filtered_Commands (Results);
      for D of Results loop
         if D.Id = Editor.Commands.Command_Save_File then
            Found_Save := True;
         end if;
      end loop;
      Assert (not Found_Save,
              "Phase 564 removed-name descriptor filtering must also ignore keybinding text when display is disabled");

      Editor.Command_Palette.Reset;
      Editor.Keybindings.Reset_To_Defaults;
   end Test_Phase564_Keybinding_Search_Obeys_Display_Setting;

   function Phase85_Layout_Candidate
     (Label       : String;
      Binding     : String;
      Available   : Boolean := True;
      Description : String := "Save the active buffer";
      Reason      : String := "No active buffer.")
      return Editor.Commands.Command_Palette_Candidate
   is
   begin
      return
        (Id                 => Editor.Commands.Command_Save_File,
         Label              => To_Unbounded_String (Label),
         Description        => To_Unbounded_String (Description),
         Category           => Editor.Commands.File_Category,
         Category_Label     => To_Unbounded_String ("File"),
         Available          => Available,
         Reason             => To_Unbounded_String (Reason),
         Has_Keybinding     => Binding'Length > 0,
         Keybinding_Display => To_Unbounded_String (Binding),
         Reference_Summary  => Null_Unbounded_String,
         Family             => Editor.Commands.No_Command_Family,
         Effect_Classification => Editor.Commands.No_Command_Effect,
         Match_Score        => 1,
         Registry_Order     => 1);
   end Phase85_Layout_Candidate;

   procedure Test_Phase85_Row_Layout_Right_Aligns_Keybinding
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      L : constant Editor.Command_Palette.Command_Palette_Row_Layout :=
        Editor.Command_Palette.Project_Command_Row_Layout
          (Phase85_Layout_Candidate ("Save File", "Ctrl+S"),
           Is_Selected => False,
           Row_Columns => 30);
   begin
      Assert (To_String (L.Visible_Text) = "Save File",
              "Fitting label must not be altered");
      Assert (L.Show_Keybinding,
              "Fitting keybinding must be displayed");
      Assert (To_String (L.Keybinding_Text) = "Ctrl+S",
              "Displayed keybinding text must be preserved");
      Assert (L.Keybinding_Column = 24,
              "Keybinding column must right-align within row columns");
   end Test_Phase85_Row_Layout_Right_Aligns_Keybinding;

   procedure Test_Phase85_Row_Layout_Truncates_Label_Before_Keybinding
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      L : constant Editor.Command_Palette.Command_Palette_Row_Layout :=
        Editor.Command_Palette.Project_Command_Row_Layout
          (Phase85_Layout_Candidate
             ("Save File With A Very Long Label", "Ctrl+S"),
           Is_Selected => False,
           Row_Columns => 18);
   begin
      Assert (L.Show_Keybinding,
              "Keybinding must remain visible when label is truncated");
      Assert (L.Keybinding_Column = 12,
              "Keybinding column must remain right-aligned after truncation");
      Assert (Length (L.Visible_Text) <= 10,
              "Main text must be truncated before the reserved keybinding area");
      Assert (To_String (L.Keybinding_Text) = "Ctrl+S",
              "Truncation must not alter the keybinding text");
   end Test_Phase85_Row_Layout_Truncates_Label_Before_Keybinding;

   procedure Test_Phase85_Row_Layout_Omits_Keybinding_When_Narrow
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      L : constant Editor.Command_Palette.Command_Palette_Row_Layout :=
        Editor.Command_Palette.Project_Command_Row_Layout
          (Phase85_Layout_Candidate ("Save File", "Ctrl+S"),
           Is_Selected => False,
           Row_Columns => 8);
   begin
      Assert (not L.Show_Keybinding,
              "Very narrow rows must omit keybinding display deterministically");
      Assert (Length (L.Keybinding_Text) = 0,
              "Omitted keybinding must not emit keybinding text");
      Assert (Length (L.Visible_Text) <= 8,
              "Main text must still fit inside the narrow row");
   end Test_Phase85_Row_Layout_Omits_Keybinding_When_Narrow;

   procedure Test_Phase85_Row_Layout_Selected_Reason_Truncates_Before_Keybinding
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      L : constant Editor.Command_Palette.Command_Palette_Row_Layout :=
        Editor.Command_Palette.Project_Command_Row_Layout
          (Phase85_Layout_Candidate
             (Label     => "Save File",
              Binding   => "Ctrl+S",
              Available => False,
              Reason    => "No active buffer available for saving"),
           Is_Selected => True,
           Row_Columns => 24);
   begin
      Assert (L.Show_Keybinding,
              "Unavailable selected row must keep keybinding when it fits");
      Assert (L.Keybinding_Column = 18,
              "Unavailable row keybinding must stay right-aligned");
      Assert (Length (L.Visible_Text) <= 16,
              "Unavailable reason must truncate before keybinding text");
      Assert (To_String (L.Keybinding_Text) = "Ctrl+S",
              "Unavailable row keybinding text must be preserved");
   end Test_Phase85_Row_Layout_Selected_Reason_Truncates_Before_Keybinding;

   procedure Test_Phase86_Truncate_With_Ellipsis_Edges
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Command_Palette.Truncate_With_Ellipsis ("abcdef", 0) = "",
              "Max_Columns = 0 must truncate to an empty string");
      Assert (Editor.Command_Palette.Truncate_With_Ellipsis ("abcdef", 1) = "~",
              "Max_Columns = 1 must use deterministic one-column truncation");
      Assert (Editor.Command_Palette.Truncate_With_Ellipsis ("abc", 3) = "abc",
              "Fitting text must remain unchanged");
      Assert (Editor.Command_Palette.Truncate_With_Ellipsis ("abcdef", 4) = "abc~",
              "Long text must truncate with the editor ellipsis marker");
   end Test_Phase86_Truncate_With_Ellipsis_Edges;

   procedure Test_Phase86_Command_Row_Layout_Ranges_Do_Not_Overlap
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      L : constant Editor.Command_Palette.Command_Palette_Row_Layout :=
        Editor.Command_Palette.Layout_Command_Row
          (Row_Width_Columns => 18,
           Label_Length      => 20,
           Secondary_Length  => 15,
           Keybinding_Length => 6,
           Is_Selected       => True,
           Is_Available      => False);
   begin
      Assert (L.Show_Keybinding,
              "A fitting keybinding must remain visible in the reserved segment");
      Assert (L.Keybinding_Start_Column + L.Keybinding_Columns <= 18,
              "Keybinding range must fit inside the row");
      Assert (not L.Show_Secondary
              or else L.Secondary_Start_Column + L.Secondary_Columns <= L.Keybinding_Start_Column - 2,
              "Secondary range must not overlap the keybinding gap");
      Assert (L.Label_Start_Column + L.Label_Columns <=
                (if L.Show_Secondary then L.Secondary_Start_Column - 3
                 else L.Keybinding_Start_Column - 2),
              "Label range must not overlap secondary or keybinding text");
   end Test_Phase86_Command_Row_Layout_Ranges_Do_Not_Overlap;

   procedure Test_Phase86_Command_Row_Layout_Omits_Too_Wide_Keybinding
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      L : constant Editor.Command_Palette.Command_Palette_Row_Layout :=
        Editor.Command_Palette.Layout_Command_Row
          (Row_Width_Columns => 8,
           Label_Length      => 9,
           Secondary_Length  => 0,
           Keybinding_Length => 7,
           Is_Selected       => False,
           Is_Available      => True);
   begin
      Assert (not L.Show_Keybinding,
              "A too-wide keybinding must be omitted deterministically");
      Assert (L.Label_Columns <= 8,
              "Label columns must remain inside the row when keybinding is omitted");
   end Test_Phase86_Command_Row_Layout_Omits_Too_Wide_Keybinding;

   procedure Test_Phase86_Selected_Available_Row_Includes_Description
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Config     : constant Editor.Command_Palette.Command_Palette_Config := (others => <>);
      Snapshot   : Editor.Command_Palette.Command_Palette_Snapshot;
   begin
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Candidates.Append
        (Phase85_Layout_Candidate
           (Label       => "Save File",
            Binding     => "Ctrl+S",
            Available   => True,
            Description => "Save the active buffer"));
      Editor.Command_Palette.Reconcile_Selection (Candidates);
      Snapshot := Editor.Command_Palette.Build_Snapshot (Candidates, Config);

      Assert (Editor.Command_Palette.Row (Snapshot, 1).Primary_Text =
                To_Unbounded_String ("Save File"),
              "Command row primary text must contain the command label");
      Assert (Editor.Command_Palette.Row (Snapshot, 1).Secondary_Text =
                To_Unbounded_String ("Save the active buffer"),
              "Selected available command row must expose the description");
      Assert (Editor.Command_Palette.Row (Snapshot, 1).Has_Keybinding,
              "Selected bound command row must expose keybinding metadata");
      Assert (Editor.Command_Palette.Row (Snapshot, 1).Keybinding_Text =
                To_Unbounded_String ("Ctrl+S"),
              "Selected command row must carry the formatted keybinding");
   end Test_Phase86_Selected_Available_Row_Includes_Description;

   procedure Test_Phase86_Selected_Unavailable_Row_Includes_Reason
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Config     : constant Editor.Command_Palette.Command_Palette_Config := (others => <>);
      Snapshot   : Editor.Command_Palette.Command_Palette_Snapshot;
   begin
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Candidates.Append
        (Phase85_Layout_Candidate
           (Label     => "Save File",
            Binding   => "Ctrl+S",
            Available => False,
            Reason    => "No active buffer."));
      Editor.Command_Palette.Reconcile_Selection (Candidates);
      Snapshot := Editor.Command_Palette.Build_Snapshot (Candidates, Config);

      Assert (Editor.Command_Palette.Row (Snapshot, 1).Secondary_Text =
                To_Unbounded_String ("No active buffer."),
              "Selected unavailable command row must expose the unavailable reason");
      Assert (not Editor.Command_Palette.Row (Snapshot, 1).Is_Available,
              "Unavailable row metadata must mark the command unavailable");
      Assert (Editor.Command_Palette.Row (Snapshot, 1).Has_Keybinding,
              "Unavailable bound command row must still expose keybinding metadata");
   end Test_Phase86_Selected_Unavailable_Row_Includes_Reason;

   procedure Test_Phase86_Unselected_Row_Omits_Secondary
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Config     : constant Editor.Command_Palette.Command_Palette_Config := (others => <>);
      Snapshot   : Editor.Command_Palette.Command_Palette_Snapshot;
   begin
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Candidates.Append
        (Phase85_Layout_Candidate ("Save File", "Ctrl+S"));
      Candidates.Append
        (Phase85_Layout_Candidate
           (Label       => "Save As",
            Binding     => "",
            Description => "Save to a path"));
      Editor.Command_Palette.Reconcile_Selection
        (Candidates, Editor.Commands.Command_Save_File);
      Snapshot := Editor.Command_Palette.Build_Snapshot (Candidates, Config);

      Assert (Length (Editor.Command_Palette.Row (Snapshot, 2).Secondary_Text) = 0,
              "Unselected command rows must omit selected-row detail text");
      Assert (not Editor.Command_Palette.Row (Snapshot, 2).Has_Keybinding,
              "Unbound command row must not claim a keybinding");
   end Test_Phase86_Unselected_Row_Omits_Secondary;

   procedure Test_Phase86_Header_Empty_And_Help_Rows_Are_Non_Keybinding
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Config     : constant Editor.Command_Palette.Command_Palette_Config :=
        (Max_Visible_Rows              => 12,
         Overlay_Width_In_Columns      => 72,
         Show_Unavailable_Commands     => True,
         Group_Empty_Query_By_Category => True,
         Show_Selected_Reason          => True,
         Show_Selected_Description     => True,
         Show_Keybindings            => True,
         Show_Help_Row                 => True);
      Empty_Config : constant Editor.Command_Palette.Command_Palette_Config := (others => <>);
      Snapshot   : Editor.Command_Palette.Command_Palette_Snapshot;
      Empty_Snap : Editor.Command_Palette.Command_Palette_Snapshot;
   begin
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Candidates.Append (Phase85_Layout_Candidate ("Save File", "Ctrl+S"));
      Snapshot := Editor.Command_Palette.Build_Snapshot (Candidates, Config);

      Assert (Editor.Command_Palette.Row (Snapshot, 1).Kind =
                Editor.Command_Palette.Command_Palette_Help_Row,
              "Help row should be projected when explicitly configured");
      Assert (not Editor.Command_Palette.Row (Snapshot, 1).Has_Keybinding,
              "Help row must not expose keybinding metadata");
      Assert (Editor.Command_Palette.Row (Snapshot, 2).Kind =
                Editor.Command_Palette.Command_Palette_Header_Row,
              "Grouped empty query should project a category header after help");
      Assert (not Editor.Command_Palette.Row (Snapshot, 2).Has_Keybinding,
              "Category header row must not expose keybinding metadata");

      Candidates.Clear;
      Empty_Snap := Editor.Command_Palette.Build_Snapshot (Candidates, Empty_Config);
      Assert (Editor.Command_Palette.Row (Empty_Snap, 1).Kind =
                Editor.Command_Palette.Command_Palette_Empty_Row,
              "Empty snapshot must project an empty row");
      Assert (not Editor.Command_Palette.Row (Empty_Snap, 1).Has_Keybinding,
              "Empty row must not expose keybinding metadata");
   end Test_Phase86_Header_Empty_And_Help_Rows_Are_Non_Keybinding;

   procedure Test_Input_Field_Delete_Forward_And_Snapshot
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Snap : Editor.Input_Field.Field_Snapshot;
   begin
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("abcdef");
      Editor.Command_Palette.Move_Cursor_Start;
      Editor.Command_Palette.Delete_Forward;
      Assert (To_String (Editor.Command_Palette.Current.Query) = "bcdef",
              "Command palette Delete_Forward must edit the filter field");
      Editor.Command_Palette.Move_Cursor_End;
      Snap := Editor.Command_Palette.Query_Snapshot (3);
      Assert (To_String (Snap.Visible_Text)'Length <= 3,
              "Command palette query snapshot must clip long filter text");
      Assert (Snap.Cursor_Visible_Column <= 3,
              "Command palette query snapshot must keep the cursor visible");
   end Test_Input_Field_Delete_Forward_And_Snapshot;



   procedure Test_Phase214_Stable_Command_Id_Filtering
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Filtered : Editor.Commands.Command_Descriptor_Vectors.Vector;
      S        : Editor.State.State_Type;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Found_In_Executor : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("file.save");

      Editor.Command_Palette.Filtered_Commands (Filtered);
      Assert (Filtered.Length > 0,
              "Stable command id query must produce palette descriptors");
      Assert (Filtered.Element (0).Id = Editor.Commands.Command_Save_File,
              "Stable command id query should match Save File");

      Editor.Executor.Command_Palette_Candidates (S, Candidates);
      for Candidate of Candidates loop
         if Candidate.Id = Editor.Commands.Command_Save_File then
            Found_In_Executor := True;
         end if;
      end loop;
      Assert (Found_In_Executor,
              "Executor palette candidates must also match stable command ids");
   end Test_Phase214_Stable_Command_Id_Filtering;

   procedure Test_Phase214_Query_Change_Preserves_Visible_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Initial_Selected : Editor.Commands.Command_Id;
   begin
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("save");
      Initial_Selected := Editor.Command_Palette.Current.Selected_Command_Id;
      Assert (Initial_Selected = Editor.Commands.Command_Save_File,
              "Initial save query should select Save File");

      Editor.Command_Palette.Insert_Text ("-file");
      Assert (Editor.Command_Palette.Current.Selected_Command_Id = Initial_Selected,
              "Refining a query must preserve the selected command while it remains visible");
   end Test_Phase214_Query_Change_Preserves_Visible_Command;

   procedure Test_Phase214_Hidden_Unavailable_Rows_Produce_Empty_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Config     : constant Editor.Command_Palette.Command_Palette_Config :=
        (Max_Visible_Rows              => 12,
         Overlay_Width_In_Columns      => 72,
         Show_Unavailable_Commands     => False,
         Group_Empty_Query_By_Category => True,
         Show_Selected_Reason          => True,
         Show_Selected_Description     => True,
         Show_Keybindings              => True,
         Show_Help_Row                 => False);
      Snapshot   : Editor.Command_Palette.Command_Palette_Snapshot;
   begin
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Candidates.Append
        (Editor.Commands.Command_Palette_Candidate'
           (Id                 => Editor.Commands.Command_Save_File,
          Label              => To_Unbounded_String ("Save File"),
          Description        => To_Unbounded_String ("Save the active buffer"),
          Category           => Editor.Commands.File_Category,
          Category_Label     => To_Unbounded_String ("File"),
          Available          => False,
          Reason             => To_Unbounded_String ("No active buffer."),
          Has_Keybinding     => True,
          Keybinding_Display => To_Unbounded_String ("Ctrl+S"),
          Reference_Summary  => Null_Unbounded_String,
          Family             => Editor.Commands.No_Command_Family,
          Effect_Classification => Editor.Commands.No_Command_Effect,
          Match_Score        => 1,
          Registry_Order     => 10));

      Snapshot := Editor.Command_Palette.Build_Snapshot (Candidates, Config);
      Assert (Editor.Command_Palette.Row_Count (Snapshot) = 1,
              "Hiding all unavailable candidates must still produce a deterministic empty row");
      Assert (Editor.Command_Palette.Row (Snapshot, 1).Kind =
                Editor.Command_Palette.Command_Palette_Empty_Row,
              "All-hidden unavailable candidates must project as an empty row");
      Assert (To_String (Editor.Command_Palette.Row (Snapshot, 1).Primary_Text) =
                "No available commands",
              "All-hidden unavailable candidates must explain that no command is available");
   end Test_Phase214_Hidden_Unavailable_Rows_Produce_Empty_State;

   procedure Test_Phase214_Palette_Query_Does_Not_Expose_Public_Build
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Filtered : Editor.Commands.Command_Descriptor_Vectors.Vector;
      S        : Editor.State.State_Type;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
   begin
      Editor.State.Init (S);
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("build.run");

      Editor.Command_Palette.Filtered_Commands (Filtered);
      for Descriptor of Filtered loop
         Assert (Descriptor.Id /= Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam,
                 "Build test-seam command must not be exposed by descriptor filtering");
         Assert (Editor.Commands.Stable_Command_Name (Descriptor.Id) /= "build.run",
                 "Reserved public build id must not be exposed by descriptor filtering");
      end loop;

      Editor.Executor.Command_Palette_Candidates (S, Candidates);
      for Candidate of Candidates loop
         Assert (Candidate.Id /= Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam,
                 "Build test-seam command must not be exposed by executor palette candidates");
         Assert (Editor.Commands.Stable_Command_Name (Candidate.Id) /= "build.run",
                 "Reserved public build id must not be exposed by executor palette candidates");
      end loop;
   end Test_Phase214_Palette_Query_Does_Not_Expose_Public_Build;



   procedure Test_Phase225_No_Match_Row_Carries_Clear_Query_Hint
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Config     : constant Editor.Command_Palette.Command_Palette_Config := (others => <>);
      Snapshot   : Editor.Command_Palette.Command_Palette_Snapshot;
   begin
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("zzzz-no-command");

      Snapshot := Editor.Command_Palette.Build_Snapshot (Candidates, Config);

      Assert (Editor.Command_Palette.Row_Count (Snapshot) = 1,
              "No-match projection must emit exactly one deterministic row");
      Assert (Editor.Command_Palette.Row (Snapshot, 1).Kind =
                Editor.Command_Palette.Command_Palette_Empty_Row,
              "No-match projection must use an empty-state row");
      Assert (To_String (Editor.Command_Palette.Row (Snapshot, 1).Primary_Text) =
                "No commands match ""zzzz-no-command""",
              "No-match primary text must remain deterministic");
      Assert (To_String (Editor.Command_Palette.Row (Snapshot, 1).Secondary_Text) =
                "Clear the query to show available commands.",
              "No-match empty state should guide the user without creating a command route");
      Assert (not Editor.Command_Palette.Row (Snapshot, 1).Has_Keybinding,
              "No-match hint row must not expose a shortcut");
   end Test_Phase225_No_Match_Row_Carries_Clear_Query_Hint;

   procedure Test_Phase225_Hiding_Keybindings_Removes_Row_Shortcut
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Config     : constant Editor.Command_Palette.Command_Palette_Config :=
        (Max_Visible_Rows              => 12,
         Overlay_Width_In_Columns      => 72,
         Show_Unavailable_Commands     => True,
         Group_Empty_Query_By_Category => False,
         Show_Selected_Reason          => True,
         Show_Selected_Description     => True,
         Show_Keybindings              => False,
         Show_Help_Row                 => False);
      Snapshot   : Editor.Command_Palette.Command_Palette_Snapshot;
   begin
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Candidates.Append
        (Phase85_Layout_Candidate
           (Label       => "Save File",
            Binding     => "Ctrl+S",
            Available   => True,
            Description => "Save the active buffer"));
      Editor.Command_Palette.Reconcile_Selection (Candidates);

      Snapshot := Editor.Command_Palette.Build_Snapshot (Candidates, Config);

      Assert (not Editor.Command_Palette.Row (Snapshot, 1).Has_Keybinding,
              "Palette row must hide active shortcut metadata when display setting is disabled");
      Assert (Length (Editor.Command_Palette.Row (Snapshot, 1).Keybinding_Text) = 0,
              "Palette row must not carry shortcut display text when setting is disabled");
   end Test_Phase225_Hiding_Keybindings_Removes_Row_Shortcut;

   procedure Test_Phase564_Help_Row_Hides_Keybinding_When_Display_Disabled
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Config     : constant Editor.Command_Palette.Command_Palette_Config :=
        (Max_Visible_Rows              => 12,
         Overlay_Width_In_Columns      => 72,
         Show_Unavailable_Commands     => True,
         Group_Empty_Query_By_Category => False,
         Show_Selected_Reason          => True,
         Show_Selected_Description     => True,
         Show_Keybindings              => False,
         Show_Help_Row                 => True);
      Snapshot   : Editor.Command_Palette.Command_Palette_Snapshot;
      Found_Help : Boolean := False;
   begin
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Candidates.Append
        (Phase85_Layout_Candidate
           (Label       => "Save File",
            Binding     => "Ctrl+S",
            Available   => True,
            Description => "Save the active buffer"));
      Editor.Command_Palette.Reconcile_Selection (Candidates);

      Snapshot := Editor.Command_Palette.Build_Snapshot (Candidates, Config);

      for I in 1 .. Editor.Command_Palette.Row_Count (Snapshot) loop
         declare
            R : constant Editor.Command_Palette.Command_Palette_Row :=
              Editor.Command_Palette.Row (Snapshot, I);
         begin
            if R.Kind = Editor.Command_Palette.Command_Palette_Help_Row
              and then R.Is_Detail_For_Selected
            then
               Found_Help := True;
               Assert (Ada.Strings.Fixed.Index
                         (To_String (R.Primary_Text), "Ctrl+S") = 0,
                       "Phase 564 command help row must not display active keybinding when setting hides keybindings");
               Assert (Ada.Strings.Fixed.Index
                         (To_String (R.Primary_Text), "Keybindings hidden") > 0,
                       "Phase 564 command help row must show a bounded hidden-keybindings marker");
            end if;
         end;
      end loop;

      Assert (Found_Help,
              "Phase 564 selected command help row must still render when keybindings are hidden");
   end Test_Phase564_Help_Row_Hides_Keybinding_When_Display_Disabled;


   procedure Test_Phase564_Build_Command_Help_Obeys_Keybinding_Display_Setting
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Candidate : Editor.Commands.Command_Palette_Candidate :=
        Phase85_Layout_Candidate
          (Label       => "Save File",
           Binding     => "Ctrl+S",
           Available   => True,
           Description => "Save the active buffer");
      Config : Editor.Command_Palette.Command_Palette_Config;
      Help   : Editor.Command_Palette.Command_Help_Snapshot;
   begin
      Editor.Command_Palette.Reset;
      Candidate.Id := Editor.Commands.Command_Save_File;
      Candidate.Has_Keybinding := True;
      Candidate.Keybinding_Display := To_Unbounded_String ("Ctrl+S");

      Config := Editor.Command_Palette.Current_Config;
      Config.Show_Keybindings := False;
      Config.Show_Help_Row := True;
      Editor.Command_Palette.Set_Current_Config (Config);

      Assert (not Editor.Command_Palette.Current_Config.Show_Help_Row,
              "Set_Current_Config must not import transient command help state");

      Help := Editor.Command_Palette.Build_Command_Help (Candidate);
      Assert (To_String (Help.Keybinding_Label) = "Keybindings hidden",
              "Build_Command_Help must not expose shortcut text when keybinding display is disabled");

      Editor.Command_Palette.Set_Show_Help_Row (True);
      Assert (Editor.Command_Palette.Current_Config.Show_Help_Row,
              "transient help state must still be controlled by the runtime help toggle");

      Editor.Command_Palette.Reset;
   end Test_Phase564_Build_Command_Help_Obeys_Keybinding_Display_Setting;

   procedure Test_Phase225_Long_Selected_Description_Truncates_Safely
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      L : constant Editor.Command_Palette.Command_Palette_Row_Layout :=
        Editor.Command_Palette.Project_Command_Row_Layout
          (Phase85_Layout_Candidate
             (Label       => "Save File",
              Binding     => "Ctrl+S",
              Available   => True,
              Description => "Save the active buffer using a deliberately long explanatory command description"),
           Is_Selected => True,
           Row_Columns => 28);
   begin
      Assert (L.Show_Keybinding,
              "Long selected descriptions must not displace a fitting shortcut");
      Assert (L.Show_Secondary,
              "Selected available rows should show description text when present");
      Assert (Length (L.Visible_Text) <= 20,
              "Projected selected row text must be truncated before the shortcut area");
      Assert (To_String (L.Keybinding_Text) = "Ctrl+S",
              "Shortcut text must remain intact while long descriptions truncate");
   end Test_Phase225_Long_Selected_Description_Truncates_Safely;

   procedure Test_Phase225_Assign_Remove_Reset_Update_Shortcut_Display
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Status : Editor.Keybindings.Keybinding_Change_Status;

      function Save_Binding return String is
      begin
         Candidates.Clear;
         Editor.Executor.Command_Palette_Candidates (S, Candidates);
         for Candidate of Candidates loop
            if Candidate.Id = Editor.Commands.Command_Save_File then
               if Candidate.Has_Keybinding then
                  return To_String (Candidate.Keybinding_Display);
               else
                  return "";
               end if;
            end if;
         end loop;
         return "<missing>";
      end Save_Binding;
   begin
      Editor.State.Init (S);
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("save file");

      Editor.Keybindings.Reset_To_Defaults;
      Assert (Save_Binding = "Ctrl+S",
              "Default Save File shortcut should be visible in palette candidates");

      Editor.Keybindings.Assign
        (Chord (Editor.Keybindings.Key_S, Ctrl => True, Alt => True),
         Editor.Commands.Command_Save_File,
         Status);
      Assert (Status = Editor.Keybindings.Keybinding_Change_Ok,
              "Assigning a replacement Save File shortcut must succeed");
      Assert (Save_Binding = "Ctrl+Alt+S",
              "Assigned shortcut should immediately appear in palette candidates");

      Editor.Keybindings.Unbind_Command (Editor.Commands.Command_Save_File);
      Assert (Save_Binding = "",
              "Removing a command shortcut should remove palette shortcut display");

      Editor.Keybindings.Reset_To_Defaults;
      Assert (Save_Binding = "Ctrl+S",
              "Resetting keybindings should restore default shortcut display");
   end Test_Phase225_Assign_Remove_Reset_Update_Shortcut_Display;


   procedure Test_Phase564_Discoverability_Category_Refinements
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Commands.Discoverability_Category_Label
                (Editor.Commands.Command_Build_Run) = "Build",
              "Build commands must present a Build discoverability category");
      Assert (Editor.Commands.Discoverability_Category_Label
                (Editor.Commands.Command_Show_Recent_Projects) = "Recent Projects",
              "Recent Project commands must present a Recent Projects category");
      Assert (Editor.Commands.Discoverability_Category_Label
                (Editor.Commands.Command_Open_Command_Palette) = "Command Palette",
              "Command palette commands must present a Command Palette category");
   end Test_Phase564_Discoverability_Category_Refinements;

   procedure Test_Phase564_Build_Search_Uses_Refined_Category
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Found_Build_Run : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("build");
      Editor.Executor.Command_Palette_Candidates (S, Candidates);

      for Candidate of Candidates loop
         if Candidate.Id = Editor.Commands.Command_Build_Run then
            Found_Build_Run := True;
            Assert (To_String (Candidate.Category_Label) = "Build",
                    "Build Run candidate must display the refined Build category label");
            Assert (not Candidate.Available,
                    "Build Run should still be unavailable without a valid consented request");
         end if;
      end loop;

      Assert (Found_Build_Run,
              "Searching by refined Build category must find build.run");
   end Test_Phase564_Build_Search_Uses_Refined_Category;

   procedure Test_Phase564_Command_Help_Is_Metadata_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Candidate : Editor.Commands.Command_Palette_Candidate :=
        Phase85_Layout_Candidate
          (Label       => "Run Build",
           Binding     => "",
           Available   => False,
           Description => "Submit the transient structured build request",
           Reason      => "Consent required");
      Help : Editor.Command_Palette.Command_Help_Snapshot;
   begin
      Candidate.Id := Editor.Commands.Command_Build_Run;
      Candidate.Category_Label := To_Unbounded_String ("Build");
      Candidate.Has_Keybinding := False;

      Help := Editor.Command_Palette.Build_Command_Help (Candidate);

      Assert (To_String (Help.Stable_Name) = "build.run",
              "Help must show the stable command name");
      Assert (To_String (Help.Category_Label) = "Build",
              "Help must show refined command category");
      Assert (To_String (Help.Keybinding_Label) = "Non-bindable",
              "Help must expose non-bindable commands without making them bindable");
      Assert (To_String (Help.Availability_Label) = "Unavailable",
              "Help must reuse the availability snapshot");
      Assert (To_String (Help.Unavailable_Reason) = "Consent required",
              "Help must show unavailable reason from the candidate snapshot");
      Assert (Ada.Strings.Fixed.Index
                (To_String (Help.Classification_Label), "non-bindable") /= 0,
              "Help classification must include non-bindable marker");
   end Test_Phase564_Command_Help_Is_Metadata_Only;

   procedure Test_Phase570_Related_Command_Help_Is_Bounded_And_Payload_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Candidate : Editor.Commands.Command_Palette_Candidate :=
        Phase85_Layout_Candidate
          (Label       => "Run Build",
           Binding     => "",
           Available   => False,
           Description => "Submit the transient structured build request",
           Reason      => "Consent required");
      Help : Editor.Command_Palette.Command_Help_Snapshot;
   begin
      Candidate.Id := Editor.Commands.Command_Build_Run;
      Candidate.Category_Label := To_Unbounded_String ("Build");
      Help := Editor.Command_Palette.Build_Command_Help (Candidate);

      Assert (Help.Related_Command_Count > 0,
              "build.run help should expose descriptor-backed related commands");
      Assert (Help.Related_Command_Count <=
                Editor.Command_Palette.Max_Related_Command_Help_Items,
              "related commands must remain bounded");

      for I in 1 .. Help.Related_Command_Count loop
         Assert (Editor.Command_Palette.Related_Command_Is_Activation_Safe
                   (Help.Related_Commands (I)),
                 "related command must be visible, descriptor-backed, and stable-name routed");
         Assert (not Help.Related_Commands (I).Carries_Payload,
                 "related command help must not carry payloads");
      end loop;
   end Test_Phase570_Related_Command_Help_Is_Bounded_And_Payload_Free;

   procedure Test_Phase570_Related_Command_Help_Rejects_Target_Like_Names
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Item : Editor.Command_Palette.Related_Command_Help_Item :=
        (Command         => Editor.Commands.Command_Open_Project,
         Stable_Name     => To_Unbounded_String ("project.open:/tmp/project"),
         Title           => Editor.Commands.Descriptor
                              (Editor.Commands.Command_Open_Project).Name,
         Visible         => True,
         Carries_Payload => False);
   begin
      Assert (not Editor.Command_Palette.Related_Command_Is_Activation_Safe (Item),
              "related command activation safety must reject target-like stable names");
      Item.Stable_Name := To_Unbounded_String ("project.open");
      Item.Carries_Payload := True;
      Assert (not Editor.Command_Palette.Related_Command_Is_Activation_Safe (Item),
              "related command activation safety must reject explicit payload flags");
   end Test_Phase570_Related_Command_Help_Rejects_Target_Like_Names;

   procedure Test_Phase570_Related_Command_Help_Uses_Canonical_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Candidate : Editor.Commands.Command_Palette_Candidate :=
        Phase85_Layout_Candidate
          (Label       => "Project: Open",
           Binding     => "",
           Available   => True,
           Description => "Open a project",
           Reason      => "");
      Help : Editor.Command_Palette.Command_Help_Snapshot;
   begin
      Candidate.Id := Editor.Commands.Command_Open_Project;
      Candidate.Category_Label := To_Unbounded_String ("Project");
      Help := Editor.Command_Palette.Build_Command_Help (Candidate);

      Assert (Editor.Command_Palette.Assert_Related_Command_Help_Is_Phase570_Coherent (Help),
              "related commands must be canonical descriptor projections with clean tail state");

      Help.Related_Commands (1).Title := To_Unbounded_String ("Copied stale title");
      Assert (not Editor.Command_Palette.Assert_Related_Command_Help_Is_Phase570_Coherent (Help),
              "stale copied related-command metadata must be rejected");
   end Test_Phase570_Related_Command_Help_Uses_Canonical_Projection;

   procedure Test_Phase570_Related_Command_Help_Rejects_Duplicates_And_Tail_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Candidate : Editor.Commands.Command_Palette_Candidate :=
        Phase85_Layout_Candidate
          (Label       => "Run Build",
           Binding     => "",
           Available   => False,
           Description => "Submit the transient structured build request",
           Reason      => "Consent required");
      Help : Editor.Command_Palette.Command_Help_Snapshot;
   begin
      Candidate.Id := Editor.Commands.Command_Build_Run;
      Candidate.Category_Label := To_Unbounded_String ("Build");
      Help := Editor.Command_Palette.Build_Command_Help (Candidate);

      Assert (Editor.Command_Palette.Assert_Related_Command_Help_Is_Phase570_Coherent (Help),
              "initial related-command help must be coherent");

      if Help.Related_Command_Count >= 2 then
         Help.Related_Commands (2) := Help.Related_Commands (1);
         Assert (not Editor.Command_Palette.Assert_Related_Command_Help_Is_Phase570_Coherent (Help),
                 "duplicate related commands must be rejected");
      end if;

      Help := Editor.Command_Palette.Build_Command_Help (Candidate);
      if Help.Related_Command_Count < Editor.Command_Palette.Max_Related_Command_Help_Items then
         Help.Related_Commands (Help.Related_Command_Count + 1).Stable_Name :=
           To_Unbounded_String ("build.run");
         Assert (not Editor.Command_Palette.Assert_Related_Command_Help_Is_Phase570_Coherent (Help),
                 "related-command tail state must remain clean and transient");
      end if;
   end Test_Phase570_Related_Command_Help_Rejects_Duplicates_And_Tail_State;

   procedure Test_Phase564_Selected_Help_Row_Is_Display_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Config : Editor.Command_Palette.Command_Palette_Config := (others => <>);
      Snapshot : Editor.Command_Palette.Command_Palette_Snapshot;
      Found_Help : Boolean := False;
      Candidate : Editor.Commands.Command_Palette_Candidate :=
        Phase85_Layout_Candidate
          (Label       => "Run Build",
           Binding     => "",
           Available   => False,
           Description => "Submit the transient structured build request",
           Reason      => "Consent required");
   begin
      Candidate.Id := Editor.Commands.Command_Build_Run;
      Candidate.Category_Label := To_Unbounded_String ("Build");
      Candidate.Has_Keybinding := False;
      Candidates.Append (Candidate);

      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Config.Show_Help_Row := True;
      Snapshot := Editor.Command_Palette.Build_Snapshot (Candidates, Config);

      for I in 1 .. Editor.Command_Palette.Row_Count (Snapshot) loop
         declare
            R : constant Editor.Command_Palette.Command_Palette_Row :=
              Editor.Command_Palette.Row (Snapshot, I);
         begin
            if R.Kind = Editor.Command_Palette.Command_Palette_Help_Row then
               Found_Help := True;
               Assert (R.Is_Detail_For_Selected,
                       "Selected command help row must be marked as details");
               Assert (Ada.Strings.Fixed.Index
                         (To_String (R.Primary_Text), "build.run") /= 0,
                       "Selected help row must include the stable command name");
               Assert (Ada.Strings.Fixed.Index
                         (To_String (R.Primary_Text), "Build") /= 0,
                       "Selected help row must include category metadata");
               Assert (Ada.Strings.Fixed.Index
                         (To_String (R.Secondary_Text), "Consent required") /= 0,
                       "Selected help row must include unavailable reason");
            end if;
         end;
      end loop;

      Assert (Found_Help,
              "Show_Help_Row must add display-only selected command help");
   end Test_Phase564_Selected_Help_Row_Is_Display_Only;


   procedure Test_Phase564_Discoverability_Metadata_Audit
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Commands.Command_Discoverability_Coherent,
              "Phase 564 command discoverability metadata must be coherent");
      Assert (Editor.Commands.Has_Discoverability_Metadata
                (Editor.Commands.Command_Build_Run),
              "Build Run must have complete discoverability metadata");
      Assert (not Editor.Commands.Visible_In_Command_Palette
                (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam),
              "Internal build test-seam commands must stay hidden from normal palette discovery");
   end Test_Phase564_Discoverability_Metadata_Audit;

   procedure Test_Phase564_Filter_Recomputes_Keybinding_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Status : Editor.Keybindings.Keybinding_Change_Status;
      Results : Editor.Commands.Command_Descriptor_Vectors.Vector;
      Found_Save : Boolean := False;
   begin
      Editor.Command_Palette.Reset;
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("Ctrl+Alt+S");
      Editor.Command_Palette.Filtered_Commands (Results);
      for D of Results loop
         if D.Id = Editor.Commands.Command_Save_File then
            Found_Save := True;
         end if;
      end loop;
      Assert (not Found_Save,
              "Save File should not initially match Ctrl+Alt+S");
      Found_Save := False;

      Editor.Keybindings.Assign
        (Chord (Editor.Keybindings.Key_S, Ctrl => True, Alt => True),
         Editor.Commands.Command_Save_File,
         Status);
      Assert (Status = Editor.Keybindings.Keybinding_Change_Ok,
              "Rebinding Save File to Ctrl+Alt+S must succeed");

      Editor.Command_Palette.Filtered_Commands (Results);
      for D of Results loop
         if D.Id = Editor.Commands.Command_Save_File then
            Found_Save := True;
         end if;
      end loop;

      Assert (Found_Save,
              "Palette metadata search must recompute keybinding matches for the same query after rebinding");
      Editor.Keybindings.Reset_To_Defaults;
   end Test_Phase564_Filter_Recomputes_Keybinding_Metadata;

   procedure Test_Phase564_Help_Row_Display_Config_Is_Transient
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Config : Editor.Command_Palette.Command_Palette_Config;
   begin
      Editor.Command_Palette.Reset;
      Config := Editor.Command_Palette.Current_Config;
      Assert (not Config.Show_Help_Row,
              "Command help row display should be off by default");

      Editor.Command_Palette.Set_Show_Help_Row (True);
      Config := Editor.Command_Palette.Current_Config;
      Assert (Config.Show_Help_Row,
              "Command help row display setting should be adjustable at runtime");

      Editor.Command_Palette.Toggle_Show_Help_Row;
      Config := Editor.Command_Palette.Current_Config;
      Assert (not Config.Show_Help_Row,
              "Command help row display toggle should affect only transient palette configuration");

      Editor.Command_Palette.Set_Show_Help_Row (True);
      Editor.Command_Palette.Reset;
      Config := Editor.Command_Palette.Current_Config;
      Assert (not Config.Show_Help_Row,
              "Reset must not preserve transient command help row state");
   end Test_Phase564_Help_Row_Display_Config_Is_Transient;

   procedure Test_Phase564_Close_Clears_Command_Palette_Transient_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("build");
      Editor.Command_Palette.Set_Show_Help_Row (True);
      Editor.Command_Palette.Set_Availability_Filter
        (Editor.Command_Palette.Palette_Available_Only);
      Editor.Command_Palette.Set_Category_Filter_Label ("Build");
      Editor.Command_Palette.Set_Destructive_Filter (True);
      Editor.Command_Palette.Set_Keybinding_Filter
        (Editor.Command_Palette.Palette_Bound_Commands_Only);

      Editor.Command_Palette.Close;

      Assert (Editor.Command_Palette.Transient_State_Clear,
              "Closing the palette must clear query, selection, help, and transient filters");
      Assert (not Editor.Command_Palette.Current_Config.Show_Help_Row,
              "Selected-command help/details state must not survive palette close");
      Assert (Editor.Command_Palette.Current_Availability_Filter =
              Editor.Command_Palette.Palette_All_Commands,
              "availability filter must return to transient baseline on close");
      Assert (not Editor.Command_Palette.Has_Category_Filter,
              "category filter must return to transient baseline on close");
      Assert (not Editor.Command_Palette.Destructive_Filter_Enabled,
              "destructive filter must return to transient baseline on close");
      Assert (Editor.Command_Palette.Current_Keybinding_Filter =
              Editor.Command_Palette.Palette_All_Keybinding_States,
              "keybinding filter must return to transient baseline on close");
   end Test_Phase564_Close_Clears_Command_Palette_Transient_State;

   procedure Test_Phase564_Show_Command_Help_Command_Is_Discoverable_And_Transient
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Found : Boolean := False;
      Before : Editor.Command_Palette.Command_Palette_Config;
      After : Editor.Command_Palette.Command_Palette_Config;
   begin
      Editor.State.Init (S);
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("command-palette.show-command-help");
      Editor.Executor.Command_Palette_Candidates (S, Candidates);

      for Candidate of Candidates loop
         if Candidate.Id = Editor.Commands.Command_Palette_Show_Command_Help then
            Found := True;
            Assert (To_String (Candidate.Category_Label) = "Command Palette",
                    "Help command must use the Command Palette discoverability category");
            Assert (Candidate.Available,
                    "Help command must be available as a palette-local display toggle");
         end if;
      end loop;

      Assert (Found,
              "Stable command name search must find command-palette.show-command-help");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Palette_Show_Command_Help) =
              "command-palette.show-command-help",
              "Help command must have the requested stable command name");

      Before := Editor.Command_Palette.Current_Config;
      Assert (not Before.Show_Help_Row,
              "Help rows start disabled before executing the help command");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Palette_Show_Command_Help);
      After := Editor.Command_Palette.Current_Config;
      Assert (After.Show_Help_Row,
              "Executing the help command must toggle only transient help display state");
      Editor.Command_Palette.Reset;
   end Test_Phase564_Show_Command_Help_Command_Is_Discoverable_And_Transient;


   procedure Test_Phase564_Show_Command_Help_Requires_Open_Palette
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Availability : Editor.Commands.Command_Availability;
      Before : Editor.Command_Palette.Command_Palette_Config;
      After : Editor.Command_Palette.Command_Palette_Config;
   begin
      Editor.State.Init (S);
      Editor.Command_Palette.Reset;
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Palette_Show_Command_Help);
      Assert (not Editor.Commands.Is_Available (Availability),
              "Command help display is palette-local and must be unavailable while the palette is closed");
      Assert (Editor.Commands.Unavailable_Reason (Availability) = "Command Palette closed",
              "Closed-palette help command must report a user-readable unavailable reason");

      Before := Editor.Command_Palette.Current_Config;
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Palette_Show_Command_Help);
      After := Editor.Command_Palette.Current_Config;
      Assert (Before.Show_Help_Row = After.Show_Help_Row,
              "Executing unavailable command help must not mutate transient help state");

      Editor.Command_Palette.Open;
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Palette_Show_Command_Help);
      Assert (Editor.Commands.Is_Available (Availability),
              "Command help display should become available when the palette is open");
      Editor.Command_Palette.Reset;
   end Test_Phase564_Show_Command_Help_Requires_Open_Palette;


   procedure Test_Phase564_Keyboard_Selection_Uses_Visible_Candidates
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Hidden_Unavailable : Editor.Commands.Command_Palette_Candidate :=
        Phase85_Layout_Candidate
          (Label       => "Save File",
           Binding     => "Ctrl+S",
           Available   => False,
           Description => "Save the active buffer",
           Reason      => "No active buffer.");
      First_Visible : Editor.Commands.Command_Palette_Candidate :=
        Phase85_Layout_Candidate
          (Label       => "Open Command Palette",
           Binding     => "Ctrl+Shift+P",
           Available   => True,
           Description => "Open the Command Palette",
           Reason      => "");
      Second_Visible : Editor.Commands.Command_Palette_Candidate :=
        Phase85_Layout_Candidate
          (Label       => "Show Command Help",
           Binding     => "F1",
           Available   => True,
           Description => "Toggle help for the selected command",
           Reason      => "");
   begin
      Hidden_Unavailable.Id := Editor.Commands.Command_Save_File;
      First_Visible.Id := Editor.Commands.Command_Open_Command_Palette;
      Second_Visible.Id := Editor.Commands.Command_Palette_Show_Command_Help;

      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Set_Show_Unavailable_Commands (False);
      Candidates.Append (Hidden_Unavailable);
      Candidates.Append (First_Visible);
      Candidates.Append (Second_Visible);

      Editor.Command_Palette.Reconcile_Selection (Candidates);
      Assert (Editor.Command_Palette.Current.Selected_Command_Id =
                Editor.Commands.Command_Open_Command_Palette,
              "Selection should start on the first rendered visible command");

      Editor.Command_Palette.Move_Selection_By_Candidates (Candidates, 1);
      Assert (Editor.Command_Palette.Current.Selected_Command_Id =
                Editor.Commands.Command_Palette_Show_Command_Help,
              "Keyboard selection must move through rendered visible candidates and skip hidden unavailable commands");
      Editor.Command_Palette.Reset;
   end Test_Phase564_Keyboard_Selection_Uses_Visible_Candidates;

   procedure Test_Phase564_Surface_And_Guard_Help_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Candidate : Editor.Commands.Command_Palette_Candidate :=
        Phase85_Layout_Candidate
          (Label       => "Delete Selected File Tree Feed_Item",
           Binding     => "",
           Available   => False,
           Description => "Delete the selected file tree entry after confirmation.",
           Reason      => "No file tree selection");
      Help : Editor.Command_Palette.Command_Help_Snapshot;
   begin
      Candidate.Id := Editor.Commands.Command_File_Tree_Delete_Selected;
      Candidate.Category_Label := To_Unbounded_String ("File Tree");
      Candidate.Has_Keybinding := False;

      Help := Editor.Command_Palette.Build_Command_Help (Candidate);

      Assert (To_String (Help.Surface_Relevance_Label) = "File Tree",
              "Help must expose panel/surface relevance without a row payload");
      Assert (Ada.Strings.Fixed.Index
                (To_String (Help.Guard_Label), "confirmation") /= 0,
              "Help must describe retained destructive/dirty file protection");
      Assert (Ada.Strings.Fixed.Index
                (Ada.Characters.Handling.To_Lower (To_String (Help.Guard_Label)),
                 "guard") = 0,
              "Help must not expose guard terminology in product-facing text");
      Assert (Ada.Strings.Fixed.Index
                (Ada.Characters.Handling.To_Lower (To_String (Help.Guard_Label)),
                 "lifecycle") = 0,
              "Help must not expose lifecycle terminology in product-facing text");
      Assert (Ada.Strings.Fixed.Index
                (To_String (Help.Classification_Label), "destructive") /= 0,
              "Help must mark destructive commands");
      Assert (Ada.Strings.Fixed.Index
                (Ada.Characters.Handling.To_Lower
                   (To_String (Help.Classification_Label)),
                 "lifecycle") = 0,
              "Help classification must use product-facing safety wording");
      Assert (Ada.Strings.Fixed.Index
                (To_String (Help.Classification_Label), "project/file safety") /= 0,
              "Help classification names project/file safety in product terms");
   end Test_Phase564_Surface_And_Guard_Help_Metadata;


   procedure Test_Phase564_Visibility_Filter_Controls_Selection_And_Snapshot
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Visible : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Config : Editor.Command_Palette.Command_Palette_Config := (others => <>);
      Snapshot : Editor.Command_Palette.Command_Palette_Snapshot;
      Available_Candidate : Editor.Commands.Command_Palette_Candidate :=
        Phase85_Layout_Candidate
          (Label       => "Save File",
           Binding     => "Ctrl+S",
           Available   => True,
           Description => "Save the active file.",
           Reason      => "");
      Unavailable_Candidate : Editor.Commands.Command_Palette_Candidate :=
        Phase85_Layout_Candidate
          (Label       => "Run Build",
           Binding     => "",
           Available   => False,
           Description => "Run the configured build request.",
           Reason      => "Consent required");
   begin
      Available_Candidate.Id := Editor.Commands.Command_Save_File;
      Available_Candidate.Category_Label := To_Unbounded_String ("File");
      Available_Candidate.Has_Keybinding := True;
      Unavailable_Candidate.Id := Editor.Commands.Command_Build_Run;
      Unavailable_Candidate.Category_Label := To_Unbounded_String ("Build");
      Unavailable_Candidate.Has_Keybinding := False;
      Candidates.Append (Unavailable_Candidate);
      Candidates.Append (Available_Candidate);

      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Set_Show_Unavailable_Commands (False);
      Editor.Command_Palette.Visible_Candidates (Candidates, Visible);

      Assert (Natural (Visible.Length) = 1,
              "Visible candidate projection must honor hidden unavailable commands");
      Assert (Visible.Element (0).Id = Editor.Commands.Command_Save_File,
              "Filtered visible candidate sequence must match rendered rows");

      Editor.Command_Palette.Reconcile_Selection (Candidates);
      Assert (Editor.Command_Palette.Current.Selected_Command_Id =
                Editor.Commands.Command_Save_File,
              "Selection reconciliation must not keep a hidden unavailable command selected");

      Config.Show_Unavailable_Commands := False;
      Snapshot := Editor.Command_Palette.Build_Snapshot (Candidates, Config);
      Assert (Editor.Command_Palette.Candidate_Count (Snapshot) = 1,
              "Snapshot candidates must match visible rendered candidate sequence");
      Assert (Editor.Command_Palette.Candidate (Snapshot, 0).Id =
                Editor.Commands.Command_Save_File,
              "Snapshot must expose the same command that input can execute");
      Editor.Command_Palette.Reset;
   end Test_Phase564_Visibility_Filter_Controls_Selection_And_Snapshot;


   procedure Test_Phase564_Snapshot_Selection_Clamps_To_Visible_Candidates
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Config : Editor.Command_Palette.Command_Palette_Config := (others => <>);
      Snapshot : Editor.Command_Palette.Command_Palette_Snapshot;
      Save_Candidate : Editor.Commands.Command_Palette_Candidate :=
        Phase85_Layout_Candidate
          (Label       => "Save File",
           Binding     => "Ctrl+S",
           Available   => True,
           Description => "Save the active file.",
           Reason      => "");
      Build_Candidate : Editor.Commands.Command_Palette_Candidate :=
        Phase85_Layout_Candidate
          (Label       => "Run Build",
           Binding     => "",
           Available   => False,
           Description => "Run the configured build request.",
           Reason      => "Consent required");
      Found_Selected_Save : Boolean := False;
   begin
      Save_Candidate.Id := Editor.Commands.Command_Save_File;
      Save_Candidate.Category_Label := To_Unbounded_String ("File");
      Save_Candidate.Has_Keybinding := True;
      Build_Candidate.Id := Editor.Commands.Command_Build_Run;
      Build_Candidate.Category_Label := To_Unbounded_String ("Build");
      Build_Candidate.Has_Keybinding := False;

      Candidates.Append (Save_Candidate);
      Candidates.Append (Build_Candidate);

      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Set_Show_Unavailable_Commands (True);
      Editor.Command_Palette.Reconcile_Selection
        (Candidates,
         Preferred_Command      => Editor.Commands.Command_Build_Run,
         Prefer_First_Available => False);

      Assert (Editor.Command_Palette.Current.Selected_Command_Id =
                Editor.Commands.Command_Build_Run,
              "Test setup must select the second, later-hidden command");

      Config.Show_Unavailable_Commands := False;
      Snapshot := Editor.Command_Palette.Build_Snapshot (Candidates, Config);

      for I in 1 .. Editor.Command_Palette.Row_Count (Snapshot) loop
         declare
            R : constant Editor.Command_Palette.Command_Palette_Row :=
              Editor.Command_Palette.Row (Snapshot, I);
         begin
            if R.Kind = Editor.Command_Palette.Command_Palette_Command_Row
              and then R.Is_Selected
              and then To_String (R.Primary_Text) = "Save File"
            then
               Found_Selected_Save := True;
            elsif R.Kind = Editor.Command_Palette.Command_Palette_Command_Row then
               Assert (not R.Is_Selected or else To_String (R.Primary_Text) = "Save File",
                       "Snapshot must not leave selection on a hidden or out-of-range candidate");
            end if;
         end;
      end loop;

      Assert (Found_Selected_Save,
              "Snapshot projection must clamp stale hidden selection to a rendered visible command");
      Editor.Command_Palette.Reset;
   end Test_Phase564_Snapshot_Selection_Clamps_To_Visible_Candidates;


   procedure Test_Phase564_Surface_Relevance_Ranking_Uses_Previous_Focus
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
   begin
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Overlay_Focus.Activate_With_Previous
        (S.Overlay_Focus,
         Editor.Overlay_Focus.Command_Palette_Overlay,
         Editor.Overlay_Focus.Previous_File_Tree);

      Editor.Executor.Command_Palette_Candidates (S, Candidates);

      Assert (Candidates.Length > 0,
              "Command Palette must project candidates for relevance ranking");
      Assert (Ada.Strings.Fixed.Index
                (Editor.Commands.Stable_Command_Name (Candidates.Element (0).Id),
                 "file-tree.") = 1,
              "File Tree previous focus must rank File Tree commands first without hiding other commands");
      Editor.Command_Palette.Reset;
   end Test_Phase564_Surface_Relevance_Ranking_Uses_Previous_Focus;

   procedure Test_Phase564_Hidden_Minimal_Descriptors_Do_Not_Break_Discovery_Audit
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Commands.Has_Discoverability_Metadata
                (Editor.Commands.Command_Open_Command_Palette),
              "Hidden command descriptors may be minimal but must retain stable audit identity");
      Assert (not Editor.Commands.Visible_In_Command_Palette
                (Editor.Commands.Command_Open_Command_Palette),
              "Hidden command descriptors must not leak into normal palette discovery");
      Assert (Editor.Commands.Command_Discoverability_Coherent,
              "Discovery coherence must validate visible metadata and hidden exclusion together");
   end Test_Phase564_Hidden_Minimal_Descriptors_Do_Not_Break_Discovery_Audit;


   procedure Test_Phase564_Command_Kind_Help_Uses_Guarded_Command_Id_Path
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Editor.Command_Palette.Reset;
      Cmd.Kind := Editor.Commands.Palette_Show_Command_Help;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (not Editor.Command_Palette.Current_Config.Show_Help_Row,
              "Direct command-kind help route must not toggle help while palette is closed");
      Assert (Editor.Messages.Count (S.Messages) > 0,
              "Guarded command id route must report unavailable help when palette is closed");

      Editor.Command_Palette.Open;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Command_Palette.Current_Config.Show_Help_Row,
              "Command-kind help route must still toggle through guarded command id path when available");
      Editor.Command_Palette.Reset;
   end Test_Phase564_Command_Kind_Help_Uses_Guarded_Command_Id_Path;

   procedure Test_Phase578_Common_User_Terms_Discover_Core_Commands
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      function Result_Contains
        (Results : Editor.Commands.Command_Descriptor_Vectors.Vector;
         Id      : Editor.Commands.Command_Id) return Boolean
      is
      begin
         for D of Results loop
            if D.Id = Id then
               return True;
            end if;
         end loop;
         return False;
      end Result_Contains;

      procedure Assert_Query_Finds
        (Query : String;
         Id    : Editor.Commands.Command_Id;
         Label : String)
      is
         Results : Editor.Commands.Command_Descriptor_Vectors.Vector;
      begin
         Editor.Command_Palette.Reset;
         Editor.Command_Palette.Open;
         Editor.Command_Palette.Insert_Text (Query);
         Editor.Command_Palette.Filtered_Commands (Results);
         Assert (Result_Contains (Results, Id),
                 "Phase 578 command discovery term '" & Query &
                 "' must find " & Label);
         Editor.Command_Palette.Reset;
      end Assert_Query_Finds;
   begin
      Assert_Query_Finds
        ("open", Editor.Commands.Command_Open_Project, "Open Project");
      Assert_Query_Finds
        ("save", Editor.Commands.Command_Save_File, "Save File");
      Assert_Query_Finds
        ("build", Editor.Commands.Command_Build_Run, "Run Build");
      Assert_Query_Finds
        ("search", Editor.Commands.Command_Open_Project_Search_Bar,
         "Show Project Search");
      Assert_Query_Finds
        ("outline", Editor.Commands.Command_Refresh_Outline,
         "Refresh Outline");
      Assert_Query_Finds
        ("diagnostics", Editor.Commands.Command_Diagnostics_Show,
         "Show Diagnostics");
      Assert_Query_Finds
        ("buffer", Editor.Commands.Command_Open_Buffer_Switcher,
         "Show Open Buffer List");
      Assert_Query_Finds
        ("settings", Editor.Commands.Command_Reset_Settings_To_Defaults,
         "Reset Settings to Defaults");
   end Test_Phase578_Common_User_Terms_Discover_Core_Commands;


   procedure Test_Phase578_Command_Help_Uses_Real_Availability_And_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Availability : Editor.Commands.Command_Availability;
      Help : Editor.Command_Palette.Command_Help_Snapshot;
      Found : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("save");
      Editor.Executor.Command_Palette_Candidates (S, Candidates);
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Save_File);

      for C of Candidates loop
         if C.Id = Editor.Commands.Command_Save_File then
            Found := True;
            Help := Editor.Command_Palette.Build_Command_Help (C);

            Assert (To_String (Help.Title) =
                      To_String (Editor.Commands.Descriptor
                        (Editor.Commands.Command_Save_File).Name),
                    "Command help title must come from descriptor metadata");
            Assert (To_String (Help.Stable_Name) = "file.save",
                    "Command help must show the stable command name");
            Assert (To_String (Help.Category_Label) =
                      Editor.Commands.Discoverability_Category_Label
                        (Editor.Commands.Command_Save_File),
                    "Command help must show the same discoverability category as palette rows");
            Assert (To_String (Help.Description) =
                      To_String (Editor.Commands.Descriptor
                        (Editor.Commands.Command_Save_File).Description),
                    "Command help must show descriptor description metadata");
            Assert (Length (Help.Keybinding_Label) > 0,
                    "Command help must always show keybinding state, even when unbound");
            Assert (To_String (Help.Availability_Label) = "Unavailable",
                    "Command help must show candidate availability");
            Assert (To_String (Help.Unavailable_Reason) =
                      Editor.Commands.Unavailable_Reason (Availability),
                    "Command help unavailable reason must match the real Executor blocker");
         end if;
      end loop;

      Assert (Found,
              "Test setup must project Save File through the real command palette candidate path");
      Editor.Command_Palette.Reset;
   end Test_Phase578_Command_Help_Uses_Real_Availability_And_Metadata;


   procedure Test_Phase578_Command_Discovery_Hides_Internal_Commands
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Results : Editor.Commands.Command_Descriptor_Vectors.Vector;
   begin
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("dismiss");
      Editor.Command_Palette.Filtered_Commands (Results);

      for D of Results loop
         Assert (D.Visibility = Editor.Commands.Palette_Command,
                 "Command discovery must only project visible palette commands");
         Assert (D.Id /= Editor.Commands.Command_Dismiss_Latest_Message
                   and then D.Id /= Editor.Commands.Command_Dismiss_All_Messages,
                 "Hidden/internal message-dismiss commands must not leak into palette discovery");
      end loop;
      Editor.Command_Palette.Reset;
   end Test_Phase578_Command_Discovery_Hides_Internal_Commands;


   procedure Test_Phase578_Suggested_Action_Labels_Match_Command_Palette_Titles
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Suggestion : Editor.Empty_State_Guidance.Empty_State_Suggested_Command;
      Availability : Editor.Commands.Command_Availability;
   begin
      Editor.State.Init (S);

      Suggestion := Editor.Empty_State_Guidance.Command_Suggestion_From_Descriptor
        (S, Editor.Commands.Command_Save_File);
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Save_File);

      Assert (Suggestion.Visible,
              "Visible descriptor-backed commands must be available to guided suggestions");
      Assert (not Suggestion.Carries_Payload,
              "Guided suggestions must remain stable-command-name only");
      Assert (To_String (Suggestion.Title) =
                To_String (Editor.Commands.Descriptor
                  (Editor.Commands.Command_Save_File).Name),
              "Suggested action label must match the Command Palette title");
      Assert (To_String (Suggestion.Stable_Name) = "file.save",
              "Suggested action must carry only the stable command name");
      Assert (To_String (Suggestion.Unavailable_Reason) =
                Editor.Commands.Unavailable_Reason (Availability),
              "Suggested action unavailable reason must match the real Executor blocker");
      Assert (Editor.Empty_State_Guidance.Suggestion_Is_Activation_Safe
                (Suggestion),
              "Guided suggestion must be descriptor-consistent and payload-free");
   end Test_Phase578_Suggested_Action_Labels_Match_Command_Palette_Titles;


   overriding function Name
     (T : Command_Palette_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Command_Palette.Tests");
   end Name;

   overriding procedure Register_Tests
     (T : in out Command_Palette_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Open_Close'Access, "Palette Opens And Closes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Typing_Backspace_Filtering'Access,
         "Typing Backspace And Filtering");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selection_Moves'Access, "Selection Moves");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Enter_Executes_Selected_Command'Access,
         "Enter Executes Selected Command");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Palette_Input_Does_Not_Edit_Buffer'Access,
         "Palette Input Does Not Edit Buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Layers_When_Open_And_Closed'Access,
         "Palette Render Layers Open And Closed");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Input_Field_Delete_Forward_And_Snapshot'Access,
         "Palette Input Field Delete Forward And Snapshot");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase214_Stable_Command_Id_Filtering'Access,
         "Phase 214 stable command id filtering");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase214_Query_Change_Preserves_Visible_Command'Access,
         "Phase 214 query preserves visible command");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase214_Hidden_Unavailable_Rows_Produce_Empty_State'Access,
         "Phase 214 hidden unavailable rows produce empty state");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase214_Palette_Query_Does_Not_Expose_Public_Build'Access,
         "Phase 214 palette query does not expose public build");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase84_Category_Labels'Access,
         "Phase 84 category labels");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase84_Match_Score_Order'Access,
         "Phase 84 match score order");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase84_Grouped_Snapshot_Rows'Access,
         "Phase 84 grouped snapshot rows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase84_Empty_Query_Sort_Keeps_Category_Runs'Access,
         "Phase 84 empty query category sort");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase84_Nonempty_Query_Builds_Flat_Rows'Access,
         "Phase 84 nonempty query flat rows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase84_Ensure_Selected_Row_Visible'Access,
         "Phase 84 selected row visibility");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase84_Reconcile_Selects_Only_Unavailable_Match'Access,
         "Phase 84 unavailable-only selection");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase85_Candidate_Includes_Keybinding'Access,
         "Phase 85 candidate includes keybinding");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase85_Unbound_Candidate_Has_No_Keybinding'Access,
         "Phase 85 unbound candidate has no keybinding");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase85_Unavailable_Candidate_Still_Shows_Keybinding'Access,
         "Phase 85 unavailable candidate still shows keybinding");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase564_Filter_Matches_Keybinding_Text'Access,
         "Phase 564 filter matches keybinding text");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase564_Keybinding_Search_Obeys_Display_Setting'Access,
         "Phase 564 keybinding search obeys display setting");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase85_Row_Layout_Right_Aligns_Keybinding'Access,
         "Phase 85 row layout right-aligns keybinding");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase85_Row_Layout_Truncates_Label_Before_Keybinding'Access,
         "Phase 85 row layout truncates label before keybinding");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase85_Row_Layout_Omits_Keybinding_When_Narrow'Access,
         "Phase 85 row layout omits keybinding when narrow");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase85_Row_Layout_Selected_Reason_Truncates_Before_Keybinding'Access,
         "Phase 85 row layout truncates reason before keybinding");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase86_Truncate_With_Ellipsis_Edges'Access,
         "Phase 86 truncation helper edges");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase86_Command_Row_Layout_Ranges_Do_Not_Overlap'Access,
         "Phase 86 row layout ranges do not overlap");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase86_Command_Row_Layout_Omits_Too_Wide_Keybinding'Access,
         "Phase 86 row layout omits too-wide keybinding");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase86_Selected_Available_Row_Includes_Description'Access,
         "Phase 86 selected available row includes description");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase86_Selected_Unavailable_Row_Includes_Reason'Access,
         "Phase 86 selected unavailable row includes reason");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase86_Unselected_Row_Omits_Secondary'Access,
         "Phase 86 unselected row omits secondary");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase86_Header_Empty_And_Help_Rows_Are_Non_Keybinding'Access,
         "Phase 86 non-command rows have no keybindings");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Availability_Result_Model'Access,
         "Phase 83 command availability result model");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Palette_Candidate_Includes_Unavailable_Reason'Access,
         "Phase 83 palette candidate includes unavailable reason");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Hidden_Command_Availability_Reasons'Access,
         "Phase 83 hidden command availability reasons");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Enter_Unavailable_Command_Keeps_Palette_Open'Access,
         "Phase 83 unavailable palette accept keeps palette open");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase225_No_Match_Row_Carries_Clear_Query_Hint'Access,
         "Phase 225 no-match row carries clear-query hint");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase225_Hiding_Keybindings_Removes_Row_Shortcut'Access,
         "Phase 225 hiding keybindings removes row shortcut");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase564_Help_Row_Hides_Keybinding_When_Display_Disabled'Access,
         "Phase 564 help row hides keybinding display setting");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase564_Build_Command_Help_Obeys_Keybinding_Display_Setting'Access,
         "Phase 564 command help snapshot obeys keybinding display setting");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase225_Long_Selected_Description_Truncates_Safely'Access,
         "Phase 225 long selected description truncates safely");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase225_Assign_Remove_Reset_Update_Shortcut_Display'Access,
         "Phase 225 shortcut display follows keybinding changes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase564_Discoverability_Category_Refinements'Access,
         "Phase 564 discoverability category refinements");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase564_Build_Search_Uses_Refined_Category'Access,
         "Phase 564 build search uses refined category");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase564_Command_Help_Is_Metadata_Only'Access,
         "Phase 564 command help is metadata only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase570_Related_Command_Help_Is_Bounded_And_Payload_Free'Access,
         "Phase 570 related command help is bounded and payload-free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase570_Related_Command_Help_Rejects_Target_Like_Names'Access,
         "Phase 570 related command help rejects target-like names");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase570_Related_Command_Help_Uses_Canonical_Projection'Access,
         "Phase 570 related command help uses canonical projection");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase570_Related_Command_Help_Rejects_Duplicates_And_Tail_State'Access,
         "Phase 570 related command help rejects duplicates and tail state");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase564_Selected_Help_Row_Is_Display_Only'Access,
         "Phase 564 selected help row is display only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase564_Discoverability_Metadata_Audit'Access,
         "Phase 564 discoverability metadata audit");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase564_Filter_Recomputes_Keybinding_Metadata'Access,
         "Phase 564 filter recomputes keybinding metadata");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase564_Help_Row_Display_Config_Is_Transient'Access,
         "Phase 564 help row display config is transient");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase564_Close_Clears_Command_Palette_Transient_State'Access,
         "Phase 564 close clears command palette transient state");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase564_Show_Command_Help_Command_Is_Discoverable_And_Transient'Access,
         "Phase 564 show command help command is discoverable and transient");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase564_Show_Command_Help_Requires_Open_Palette'Access,
         "Phase 564 show command help requires open palette");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase564_Keyboard_Selection_Uses_Visible_Candidates'Access,
         "Phase 564 keyboard selection uses visible candidates");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase564_Surface_And_Guard_Help_Metadata'Access,
         "Phase 564 help exposes surface and guard metadata");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase564_Visibility_Filter_Controls_Selection_And_Snapshot'Access,
         "Phase 564 visible candidates drive selection and snapshot");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase564_Snapshot_Selection_Clamps_To_Visible_Candidates'Access,
         "Phase 564 snapshot selection clamps to visible candidates");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase564_Surface_Relevance_Ranking_Uses_Previous_Focus'Access,
         "Phase 564 surface relevance ranks previous focus commands");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase564_Hidden_Minimal_Descriptors_Do_Not_Break_Discovery_Audit'Access,
         "Phase 564 hidden minimal descriptors keep discovery audit coherent");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase564_Command_Kind_Help_Uses_Guarded_Command_Id_Path'Access,
         "Phase 564 command-kind help route uses guarded command id path");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase578_Common_User_Terms_Discover_Core_Commands'Access,
         "Phase 578 common user terms discover core commands");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase578_Command_Help_Uses_Real_Availability_And_Metadata'Access,
         "Phase 578 command help uses real availability and metadata");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase578_Command_Discovery_Hides_Internal_Commands'Access,
         "Phase 578 command discovery hides internal commands");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase578_Suggested_Action_Labels_Match_Command_Palette_Titles'Access,
         "Phase 578 suggested action labels match palette titles");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Descriptor_Registry_Coverage'Access,
         "Command Descriptor Registry Coverage");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Palette_Uses_Descriptor_Visibility'Access,
         "Palette Uses Descriptor Visibility");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Buffer_Command_Descriptors_Exist'Access,
         "Buffer Command Descriptors Exist");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Buffer_Command_Id_Dispatch'Access,
         "Buffer Command Id Dispatch");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_As_Descriptor_Requires_Path'Access,
         "Save As Descriptor Requires Path");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Message_Command_Descriptors_And_Dispatch'Access,
         "Message Command Descriptors And Dispatch");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Bookmark_Command_Descriptors_Exist'Access,
         "Phase 62 Bookmark Command Descriptors Exist");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Bookmark_Command_Id_Dispatch'Access,
         "Phase 62 Bookmark Command Id Dispatch");
   end Register_Tests;

end Editor.Command_Palette.Tests;
