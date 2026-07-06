with Editor.Instance;
with Editor.Input_Bridge.Active_Find_Handlers;
with Editor.Input_Bridge.Buffer_Switcher_Handlers;
with Editor.Input_Bridge.Command_Palette_Handlers;
with Editor.Input_Bridge.Command_Routing;
with Editor.Input_Bridge.Command_Prompt_Routing;
with Editor.Input_Bridge.Feature_Panel_Key_Handlers;
with Editor.Input_Bridge.File_Target_Key_Handlers;
with Editor.Input_Bridge.File_Target_Handlers;
with Editor.Input_Bridge.File_Tree_Key_Handlers;
with Editor.Input_Bridge.Goto_Line_Key_Handlers;
with Editor.Input_Bridge.Goto_Line_Handlers;
with Editor.Input_Bridge.Gutter_Pointer_Handlers;
with Editor.Input_Bridge.Build_UI_Pointer_Handlers;
with Editor.Input_Bridge.Build_UI_Key_Handlers;
with Editor.Input_Bridge.Buffer_Switcher_Key_Handlers;
with Editor.Input_Bridge.Key_Chord_Routing;
with Editor.Input_Bridge.Panel_Bars_Pointer_Handlers;
with Editor.Input_Bridge.Panel_Feature_Problems_Pointer_Handlers;
with Editor.Input_Bridge.Panel_Focus_Key_Handlers;
with Editor.Input_Bridge.Panel_Tree_Search_Pointer_Handlers;
with Editor.Input_Bridge.Project_Search_Key_Handlers;
with Editor.Input_Bridge.Project_Search_Bar_Handlers;
with Editor.Input_Bridge.Pointer_Scroll_Handlers;
with Editor.Input_Bridge.Pointer_Surface_Handlers;
with Editor.Input_Bridge.Pointer_State;
with Editor.Input_Bridge.Quick_Open_Key_Handlers;
with Editor.Input_Bridge.Quick_Open_Handlers;
with Editor.Input_Bridge.Render_Access;
with Editor.Input_Bridge.Outline_Filter_Handlers;
with Editor.Input_Bridge.Search_Query_Handlers;
with Editor.Input_Bridge.Text_Entry_Routing;
with Editor.Input_Bridge.Wheel_Handlers;
with Editor.Commands;
with Editor.Command_Execution;
with Editor.Render_Model;
with Editor.View;
with Text_Buffer;
with Editor.Render_Packet;
with Editor.Render_Cache;
with Editor.Cursor;
with Editor.Cursors;
with Ada.Text_IO;
with Ada.Containers; use type Ada.Containers.Count_Type;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Unicode;
with Editor.UTF8;
with Editor.Layout;
with Editor.Line_Numbers;
with Editor.Minimap;
with Editor.Command_Palette;
with Editor.Settings;
with Editor.Settings_Management;
with Editor.Keybindings;
with Editor.Keybinding_Config;
with Editor.Keybinding_Management;
with Editor.Scrollbars;
with Editor.Folding;
with Editor.Diagnostics;
with Editor.Feature_Diagnostics;
with Editor.Feature_Panel;
with Editor.Feature_Search_Results;
with Editor.Outline;
with Editor.Pending_Transition_Bar;
with Editor.Pending_Transitions;
with Editor.Dirty_Lines;
with Editor.Gutter;
with Editor.Gutter_Markers;
with Editor.Messages;
with Editor.Project;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.Panels;
with Editor.Buffers;
with Editor.Tab_Bar;
with Editor.Executor;
with Editor.Executor.Command_Palette_Projection;
with Editor.Executor.Buffer_Close_Commands;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.Bookmark_Commands;
with Editor.Executor.Diagnostics_Commands;
with Editor.Executor.Buffer_Switcher_Surface_Commands;
with Editor.Executor.Command_Surface_Commands;
with Editor.Executor.File_Target_Prompt_Commands;
with Editor.Executor.File_Tree_Navigation_Commands;
with Editor.Executor.File_Tree_Commands;
with Editor.Executor.Find_Replace_Commands;
with Editor.Executor.Message_Commands;
with Editor.Executor.Outline_Commands;
with Editor.Executor.Project_Lifecycle_Commands;
with Editor.Executor.Project_Search_Result_Commands;
with Editor.Executor.Project_Search_Surface_Commands;
with Editor.Executor.Search_Commands;
with Editor.Executor.Search_Results_Commands;
with Editor.Executor.Clipboard;
with Editor.Executor.Diagnostics_Commands;
with Editor.Executor.Navigation;
with Editor.Build_UI;
with Editor.Build_UI_Actions;
with Editor.Build_UI_Panel_Layout;
with Editor.Selection;
with Editor.Wrap;
with Editor.Problems;
with Editor.Search_Results;
with Editor.Project_Search;
with Editor.Project_Search_Bar;
with Editor.Panel_Focus;
with Editor.Overlay_Focus;
with Editor.Quick_Open;
with Editor.Buffer_Switcher;
with Editor.Go_To_Line;
with Editor.Input_Field;
with Editor.Theme;
with Editor.Focus_Management;
with Editor.Guided_Prompts;
with Editor.Build_Command;
with Editor.External_Producers;
with Editor.Terminal_Tasks;

use type Editor.Problems.Problems_Severity_Filter;
use type Editor.Build_UI_Panel_Layout.Build_UI_Panel_Zone;

--  Render Pipeline Contract:
--
--  1. Runtime calls Build_Render_Packet (via C bridge).
--  2. Build_Render_Packet may call Editor.Fonts.Get_Glyph.
--  3. Get_Glyph may cause Textrender to rasterize and pack glyphs,
--     setting Atlas_Dirty = True.
--  4. After packet construction, the renderer must:
--       if Atlas_Dirty then
--          upload atlas to GPU
--          call Clear_Atlas_Dirty
--  5. Only then may draw commands be executed.
--
--  Invariant:
--  All glyphs referenced by the render packet must exist in the GPU atlas
--  before rendering.
package body Editor.Input_Bridge is

   use Editor.State;
use type Editor.Commands.Command_Id;
use type Editor.State.Semantic_Popup_Kind;
use type Editor.Command_Execution.Command_Execution_Status;
use type Editor.Commands.Command_Kind;
use type Editor.File_Tree_View.File_Tree_View_Zone;
use type Editor.File_Tree.File_Tree_Node_Id;
use type Editor.Scrollbars.Scrollbar_Hit;
use type Editor.Panels.Panel_Id;
use type Editor.Panels.Bottom_Panel_Content;
use type Editor.Search_Results.Search_Results_Zone;
use type Editor.Problems.Problems_Zone;
use type Editor.Keybinding_Config.Keybinding_Config_Status;
use type Editor.Keybindings.Binding_Result;
use type Editor.Selection.Selection_Validation_Status;
use type Editor.File_Tree_View.File_Tree_Action;
use type Editor.Gutter.Gutter_Zone;
use type Editor.Tab_Bar.Tab_Bar_Zone;
use type Editor.Buffers.Buffer_Id;
use type Editor.Diagnostics.Diagnostic_Index;
use type Editor.Quick_Open.Quick_Open_Zone;
use type Editor.Project_Search_Bar.Project_Search_Bar_Zone;
use type Editor.Project_Search_Bar.Project_Search_Bar_Field;
use type Editor.Panel_Focus.Bottom_Focus_Content;
use type Editor.Overlay_Focus.Overlay_Target;
use type Editor.Keybindings.Key_Code;
use type Editor.Keybinding_Management.Keybinding_Capture_State;
use type Editor.Keybinding_Management.Keybinding_Action_Status;
use type Editor.Guided_Prompts.Prompt_Kind;
   The_Editor : Editor.Instance.Editor_Instance;
   Initialized : Boolean := False;
   function Overlay_Or_Local_Text_Input_Active return Boolean is
   begin
      return Editor.Focus_Management.Overlay_Input_Owns_Text (The_Editor.State);
   end Overlay_Or_Local_Text_Input_Active;

   function Pending_Confirmation_Active return Boolean is
   begin
      return Editor.Focus_Management.Pending_Confirmation_Owns_Focus
        (The_Editor.State);
   end Pending_Confirmation_Active;


   procedure Sync_Project_Search_Replace_Mode_From_Bar is
   begin
      if Editor.Project_Search_Bar.Active_Field
        (The_Editor.State.Project_Search_Bar)
        = Editor.Project_Search_Bar.Project_Search_Replace_Field
      then
         --  Focusing the replacement field is explicit replace-input
         --  intent, even when the field remains empty for delete-matches.
         --  Keep the transient Project Search replace-mode bit coherent for
         --  render/status before a preview is generated.
         Editor.Project_Search.Set_Replace_Mode_Active
         (The_Editor.State.Project_Search, True);
      end if;
   end Sync_Project_Search_Replace_Mode_From_Bar;

   procedure Clear_Semantic_Popup is
   begin
      The_Editor.State.Semantic_Popup :=
        (Active => False,
         Kind => Editor.State.No_Semantic_Popup,
         Anchor_Row => 0,
         Anchor_Column => 0,
         Title => Null_Unbounded_String,
         Detail => Null_Unbounded_String,
         Item_Count => 0,
         Selected_Item => 0,
         Items => (others => (others => <>)));
      Editor.Render_Cache.Invalidate_All;
   end Clear_Semantic_Popup;

   procedure Refresh_Or_Clear_Semantic_Completion_Popup is
      Result : Editor.Executor.Command_Execution_Result;
   begin
      if The_Editor.State.Semantic_Popup.Active
        and then The_Editor.State.Semantic_Popup.Kind =
          Editor.State.Semantic_Completion_Popup
      then
         Result := Editor.Executor.Execute_Command_With_Result
           (The_Editor.State, Editor.Commands.Command_Show_Completions);
         if Result.Status /= Editor.Executor.Command_Executed then
            Clear_Semantic_Popup;
         end if;
      elsif The_Editor.State.Semantic_Popup.Active then
         Clear_Semantic_Popup;
      end if;
   end Refresh_Or_Clear_Semantic_Completion_Popup;

   function Is_Text_Entry_Workflow_Event
     (Cmd : Editor.Commands.Command) return Boolean
   is
   begin
      return Text_Entry_Routing.Is_Text_Entry_Workflow_Event (Cmd);
   end Is_Text_Entry_Workflow_Event;

   function Is_Text_Entry_Workflow_Command_Id
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      return Text_Entry_Routing.Is_Text_Entry_Workflow_Command_Id (Id);
   end Is_Text_Entry_Workflow_Command_Id;

   function Resolve_Text_Entry_Focus_Target
     return Text_Entry_Focus_Target
   is
   begin
      return Text_Entry_Routing.Resolve_Text_Entry_Focus_Target
        (The_Editor.State);
   end Resolve_Text_Entry_Focus_Target;

   function Preview_Text_Entry_Route
     (Cmd : Editor.Commands.Command) return Text_Entry_Route_Result
   is
   begin
      return Text_Entry_Routing.Preview_Text_Entry_Route
        (The_Editor.State, Cmd);
   end Preview_Text_Entry_Route;

   function Canonical_Text_Entry_Command
     (Cmd : Editor.Commands.Command) return Editor.Commands.Command
   is
   begin
      return Text_Entry_Routing.Canonical_Text_Entry_Command
        (The_Editor.State, Cmd);
   end Canonical_Text_Entry_Command;

   function Preview_Text_Entry_Command_Id
     (Cmd : Editor.Commands.Command) return Editor.Commands.Command_Id
   is
   begin
      return Text_Entry_Routing.Preview_Text_Entry_Command_Id
        (The_Editor.State, Cmd);
   end Preview_Text_Entry_Command_Id;

   procedure Confirm_Guided_Prompt;
   procedure Accept_Guided_Prompt_Enter;

   procedure Execute_Text_Entry_Command_Id
     (Id    : Editor.Commands.Command_Id;
      Shift : Boolean := False)
   is
      Cmd   : constant Editor.Commands.Command :=
        Editor.Commands.Command_For_Id (Id, Shift);
      Route : constant Text_Entry_Route_Result := Preview_Text_Entry_Route (Cmd);
   begin
      case Route is
         when Routed_To_Text_Insert
            | Routed_To_Selection_Delete
            | Routed_To_Delete_Previous_Character
            | Routed_To_Delete_Next_Character
            | Routed_To_Delete_Previous_Word
            | Routed_To_Delete_Next_Word
            | Routed_To_Line_Split =>
            Editor.Executor.Execute_Command (The_Editor.State, Id, Shift);
            if The_Editor.State.Semantic_Popup.Active then
               Refresh_Or_Clear_Semantic_Completion_Popup;
            end if;
            Editor.Render_Cache.Invalidate_All;
         when Routed_To_Guided_Prompt =>
            case Id is
               when Editor.Commands.Command_Char_Delete_Previous =>
                  Editor.Guided_Prompts.Backspace (The_Editor.State.Guided_Prompt);
               when Editor.Commands.Command_Char_Delete_Next =>
                  Editor.Guided_Prompts.Delete_Forward (The_Editor.State.Guided_Prompt);
               when Editor.Commands.Command_Insert_Newline
                  | Editor.Commands.Command_Line_Split_At_Caret =>
                  Accept_Guided_Prompt_Enter;
               when others =>
                  null;
            end case;
            Editor.Render_Cache.Invalidate_All;
         when others =>
            null;
      end case;
   end Execute_Text_Entry_Command_Id;

   procedure For_Each_Text_Char_Range
   (Start : Natural;
      Stop  : Natural;
      Fn    : not null access procedure (Ch : Character)) is
   begin
      Text_Buffer.For_Each_Char_Range
      (The_Editor.State.Buffer,
         Start,
         Stop,
         Fn);
   end For_Each_Text_Char_Range;


   procedure For_Each_Text_Code_Point_Range
   (Start : Natural;
      Stop  : Natural;
      Fn    : not null access procedure
        (Index : Natural;
         Code  : Editor.Unicode.Code_Point)) is
   begin
      Text_Buffer.For_Each_Code_Point_Range
      (The_Editor.State.Buffer,
         Start,
         Stop,
         Fn);
   end For_Each_Text_Code_Point_Range;



   function Current_Message_Time_Ms return Natural
   is
      Now : constant Duration := Editor.View.Current_Time_Seconds;
   begin
      if Now <= 0.0 then
         return 0;
      elsif Now >= Duration (Natural'Last / 1000) then
         return Natural'Last;
      else
         return Natural (Float (Now) * 1000.0);
      end if;
   end Current_Message_Time_Ms;

   function Default_Message_Config return Editor.Messages.Message_Config
   is
   begin
      return (Default_Lifetime_Ms   => 3_000,
              Error_Lifetime_Ms     => 5_000,
              Max_Visible_Messages  => 3,
              Max_Text_Columns      => 96,
              Replace_Same_Category => True);
   end Default_Message_Config;

   procedure Report_Info (Text : String)
   is
   begin
      Editor.Messages.Push_Info
        (The_Editor.State.Messages, Text, Current_Message_Time_Ms, Default_Message_Config);
   end Report_Info;

   procedure Report_Warning (Text : String)
   is
   begin
      Editor.Messages.Push_Warning
        (The_Editor.State.Messages, Text, Current_Message_Time_Ms, Default_Message_Config);
   end Report_Warning;

   function Guided_Prompt_Cancel_Message
     (Prompt : Editor.Guided_Prompts.Prompt_State) return String
   is
   begin
      --  completeness: File Tree mutation workflows expose
      --  operation-specific cancellation outcomes.  Cancelling a prompt still
      --  clears only transient prompt state and never carries a path/name
      --  payload into Executor, but the user-visible message should identify
      --  the cancelled filesystem workflow instead of reporting a generic
      --  prompt cancellation.
      case Prompt.Kind is
         when Editor.Guided_Prompts.File_Tree_Create_File_Prompt =>
            return "Create file cancelled.";
         when Editor.Guided_Prompts.File_Tree_Create_Directory_Prompt =>
            return "Create directory cancelled.";
         when Editor.Guided_Prompts.File_Tree_Rename_Prompt =>
            return "Rename cancelled.";
         when Editor.Guided_Prompts.Confirmation_Prompt =>
            if Prompt.Owning_Command =
              Editor.Commands.Command_File_Tree_Delete_Selected
            then
               return "Delete cancelled.";
            end if;
            return "Prompt cancelled.";
         when others =>
            return "Prompt cancelled.";
      end case;
   end Guided_Prompt_Cancel_Message;

   procedure Restore_Focus_After_Guided_Prompt_Cancel
     (Prompt : Editor.Guided_Prompts.Prompt_State)
   is
   begin
      --  product workflow: prompt cancellation must restore the
      --  surface that started the workflow when that surface is known.  This is
      --  intentionally narrow and does not turn prompts into a new focus stack;
      --  it only prevents File Tree create/rename/delete cancellation from
      --  leaving users on an unrelated correction surface.
      case Prompt.Kind is
         when Editor.Guided_Prompts.File_Tree_Create_File_Prompt
            | Editor.Guided_Prompts.File_Tree_Create_Directory_Prompt
            | Editor.Guided_Prompts.File_Tree_Rename_Prompt =>
            Editor.Focus_Management.Set_Focus_Owner
              (The_Editor.State, Editor.Focus_Management.Focus_File_Tree);
         when Editor.Guided_Prompts.Confirmation_Prompt =>
            if Prompt.Owning_Command =
              Editor.Commands.Command_File_Tree_Delete_Selected
            then
               Editor.Focus_Management.Set_Focus_Owner
                 (The_Editor.State, Editor.Focus_Management.Focus_File_Tree);
            end if;
         when others =>
            null;
      end case;
   end Restore_Focus_After_Guided_Prompt_Cancel;

   procedure Confirm_Guided_Prompt is
      Prompt_Id : constant Editor.Commands.Command_Id :=
        The_Editor.State.Guided_Prompt.Owning_Command;
      Selected_Found : Boolean := False;
      Selected_Path  : constant String :=
        Editor.Guided_Prompts.Selected_File_Picker_Path
          (The_Editor.State.Guided_Prompt, Selected_Found);
      Input_Text : constant String :=
        (if The_Editor.State.Guided_Prompt.Kind =
              Editor.Guided_Prompts.Project_Open_Prompt
            and then Selected_Found
         then Selected_Path
         else Editor.Guided_Prompts.Input_Text (The_Editor.State.Guided_Prompt));
   begin
      if not Editor.Guided_Prompts.Is_Active (The_Editor.State.Guided_Prompt) then
         return;
      end if;

      Editor.Guided_Prompts.Validate (The_Editor.State.Guided_Prompt);
      if not Editor.Guided_Prompts.Ready (The_Editor.State.Guided_Prompt) then
         Report_Info (To_String (The_Editor.State.Guided_Prompt.Validation_Message));
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Editor.Guided_Prompts.Mark_Confirmed (The_Editor.State.Guided_Prompt);
      --  keybinding capture has its own typed
      --  transient chord and must not re-execute the prompt-start command.  It
      --  completes through Keybinding_Management, which stores only normalized
      --  chord -> stable command-name mappings after explicit success and keeps
      --  conflicts pending instead of silently replacing them.
      if The_Editor.State.Guided_Prompt.Kind =
        Editor.Guided_Prompts.Keybinding_Capture_Prompt
      then
         declare
            Status : Editor.Keybinding_Management.Keybinding_Action_Status;
            Chord  : constant Editor.Keybindings.Key_Chord :=
              Editor.Guided_Prompts.Captured_Key_Chord
                (The_Editor.State.Guided_Prompt);
         begin
            Editor.Guided_Prompts.Clear (The_Editor.State.Guided_Prompt);
            Editor.Keybinding_Management.Assign_Selected
              (Chord, Confirm_Conflict => False, Status => Status);
            Report_Info
              (Editor.Keybinding_Management.Action_Status_Label (Status));
         end;
      else
         --  Completion re-enters Executor through the original stable command
         --  id. Prompt input remains transient; it is copied only into the one
         --  immediate command object for existing subsystem APIs that already
         --  expect text/path/query data, and is cleared before execution.
         declare
            Cmd : Editor.Commands.Command := Editor.Commands.Command_For_Id (Prompt_Id);
         begin
            case The_Editor.State.Guided_Prompt.Kind is
               when Editor.Guided_Prompts.Project_Open_Prompt
                  | Editor.Guided_Prompts.Project_Switch_Prompt
                  | Editor.Guided_Prompts.Workspace_Load_Prompt
                  | Editor.Guided_Prompts.Workspace_Save_Prompt =>
                  Cmd.Path := To_Unbounded_String (Input_Text);
               when Editor.Guided_Prompts.Search_Query_Prompt =>
                  Cmd.Query := To_Unbounded_String (Input_Text);
               when Editor.Guided_Prompts.Replace_Text_Prompt =>
                  --  Empty replacement text is a valid delete-matches
                  --  workflow.  Command.Text cannot distinguish absent text
                  --  from intentionally-empty text, so commit the transient
                  --  prompt input to the existing Project Search replace-input
                  --  state before routing preview generation through Executor.
                  Editor.Project_Search.Set_Replace_Text
                    (The_Editor.State.Project_Search, Input_Text);
               when Editor.Guided_Prompts.Settings_Value_Prompt
                  | Editor.Guided_Prompts.File_Tree_Create_File_Prompt
                  | Editor.Guided_Prompts.File_Tree_Create_Directory_Prompt
                  | Editor.Guided_Prompts.File_Tree_Rename_Prompt
                  | Editor.Guided_Prompts.Semantic_Rename_Prompt =>
                  Cmd.Text := To_Unbounded_String (Input_Text);
               when Editor.Guided_Prompts.Confirmation_Prompt =>
                  --  Confirmation prompts do not expose a reusable path/name
                  --  payload.  They contribute only the immediate confirmation
                  --  token needed by existing Executor handlers; File Tree
                  --  delete still revalidates the selected snapshot target and
                  --  project-root boundary before mutating the filesystem.
                  Cmd.Text := To_Unbounded_String ("confirm");
               when others =>
                  null;
            end case;
            Editor.Guided_Prompts.Clear (The_Editor.State.Guided_Prompt);
            Editor.Executor.Execute_No_Log (The_Editor.State, Cmd);
         end;
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Confirm_Guided_Prompt;

   function Guided_Prompt_Selected_File_Picker_Label return String is
      Prompt : constant Editor.Guided_Prompts.Prompt_State :=
        The_Editor.State.Guided_Prompt;
   begin
      if Prompt.Active
        and then Prompt.File_Picker_Active
        and then Natural (Prompt.File_Picker_Rows.Length) > 0
        and then Prompt.File_Picker_Selected_Index >= Prompt.File_Picker_Rows.First_Index
        and then Prompt.File_Picker_Selected_Index <= Prompt.File_Picker_Rows.Last_Index
      then
         return To_String
           (Prompt.File_Picker_Rows.Element
              (Prompt.File_Picker_Selected_Index).Label);
      end if;

      return "";
   end Guided_Prompt_Selected_File_Picker_Label;

   procedure Accept_Guided_Prompt_Enter is
   begin
      if The_Editor.State.Guided_Prompt.Kind =
           Editor.Guided_Prompts.Project_Open_Prompt
        and then Guided_Prompt_Selected_File_Picker_Label /= ""
        and then Guided_Prompt_Selected_File_Picker_Label /= "./"
        and then Editor.Guided_Prompts.Apply_File_Picker_Selection
          (The_Editor.State.Guided_Prompt)
      then
         Report_Info ("Directory selected.");
         Editor.Render_Cache.Invalidate_All;
      else
         Confirm_Guided_Prompt;
      end if;
   end Accept_Guided_Prompt_Enter;

   procedure Execute_Command_Id
     (Id    : Editor.Commands.Command_Id;
      Shift : Boolean := False)
   is
      Cmd : Editor.Commands.Command;
      Cursor_Config : Editor.Cursor.Cursor_Config;
      Owner_Before : Editor.Focus_Management.Focus_Owner;
   begin
      if Id = Editor.Commands.No_Command then
         return;
      end if;

      if Editor.Guided_Prompts.Is_Active (The_Editor.State.Guided_Prompt) then
         if Id = Editor.Commands.Command_Cancel then
            declare
               Cancel_Message : constant String :=
                 Guided_Prompt_Cancel_Message (The_Editor.State.Guided_Prompt);
            begin
               Restore_Focus_After_Guided_Prompt_Cancel
                 (The_Editor.State.Guided_Prompt);
               Editor.Guided_Prompts.Cancel (The_Editor.State.Guided_Prompt);
               Report_Info (Cancel_Message);
            end;
            Editor.Render_Cache.Invalidate_All;
            return;
         elsif Is_Text_Entry_Workflow_Command_Id (Id) then
            Execute_Text_Entry_Command_Id (Id, Shift);
            Editor.Cursor.Notify_Input (Float (Editor.View.Current_Time_Seconds));
            return;
         else
            --  a guided prompt is modal for
            --  command dispatch.  Besides Cancel and prompt-local text editing,
            --  ordinary global keybindings and palette executions must not leak
            --  through to editor/file/project mutations while prompt input is
            --  active.
            if Editor.Guided_Prompts.Is_Confirmation (The_Editor.State.Guided_Prompt) then
               Report_Info ("Command unavailable while confirmation is pending");
            else
               Report_Info ("Another prompt is active");
            end if;
            Editor.Render_Cache.Invalidate_All;
            return;
         end if;
      elsif Editor.Input_Bridge.Command_Prompt_Routing
        .Command_Starts_Guided_Prompt (Id)
      then
         --  Input-collection prompt starts deliberately precede ordinary
         --  availability because the missing value is the point of the
         --  workflow. Confirmation prompts are different: they wrap an already
         --  available destructive/lifecycle/configuration command, so they must
         --  not mask a normal unavailable reason such as no selected target.
         --
         --  completeness: File Tree create/rename prompts are also
         --  target/project-bound workflows.  They may need later prompt text,
         --  but they must not open a mutation prompt when the active project or
         --  selected rename target is already unavailable.  This check remains
         --  side-effect-free and uses the same Executor availability surface as
         --  palette/keybinding execution.
         if Editor.Input_Bridge.Command_Prompt_Routing
              .Command_Starts_Confirmation_Prompt (Id)
           or else Id = Editor.Commands.Command_File_Tree_Create_File
           or else Id = Editor.Commands.Command_File_Tree_Create_Directory
           or else Id = Editor.Commands.Command_File_Tree_Rename_Selected
           or else Id = Editor.Commands.Command_Rename_Symbol_Preview
           or else Id = Editor.Commands.Command_Rename_Symbol_Apply
         then
            if Editor.Input_Bridge.Command_Routing
              .Handle_Guided_Prompt_Start_Availability_Gate
                (The_Editor.State, Id, Report_Info'Access)
            then
               return;
            end if;
         end if;
         Editor.Input_Bridge.Command_Prompt_Routing
           .Start_Guided_Prompt_For_Command
             (The_Editor.State, Id, Report_Info'Access);
         Editor.Cursor.Notify_Input (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      Owner_Before := Editor.Focus_Management.Effective_Focus_Owner
        (The_Editor.State);

      --  canonicalization: text-entry command ids are not a
      --  second editor mutation path.  They are converted to ordinary
      --  text-entry events and pass through the same focus resolver,
      --  overlay/input priority gate, canonical command projection, and
      --  mutation-owner dispatch used by direct Input_Bridge text events.
      --  This intentionally happens before generic command availability so
      --  overlay/input focus cannot leak into active-buffer availability,
      --  messages, Undo/Redo, dirty state, Find/Replace, Clipboard, or
      --  Navigation History through an alternate command-id route.
      if Is_Text_Entry_Workflow_Command_Id (Id) then
         Execute_Text_Entry_Command_Id (Id, Shift);
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Editor.Input_Bridge.Command_Routing.Handle_Pending_Confirmation_Gate
        (The_Editor.State, Id, Report_Info'Access)
      then
         return;
      end if;

      if Editor.Input_Bridge.Command_Routing.Handle_Current_Focus_Gate
        (The_Editor.State, Id, Report_Info'Access)
      then
         return;
      end if;

      if Id = Editor.Commands.Command_Open_Quick_Open then
         Editor.Executor.Command_Surface_Commands.Execute_Open_Quick_Open (The_Editor.State);
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Id = Editor.Commands.Command_Toggle_Quick_Open then
         Editor.Executor.Command_Surface_Commands.Execute_Toggle_Quick_Open (The_Editor.State);
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      if Editor.Input_Bridge.Command_Routing.Handle_Command_Availability_Gate
        (The_Editor.State, Id, Report_Info'Access)
      then
         return;
      end if;

      if Editor.Commands.Is_Text_Editing_Command (Id) then
         if Id = Editor.Commands.Command_Comment_Line
           or else Id = Editor.Commands.Command_Uncomment_Line
           or else Id = Editor.Commands.Command_Toggle_Line_Comment
         then
            declare
               Selection_Range : Editor.Selection.Active_Selection_Range;
               Status          : constant Editor.Selection.Selection_Validation_Status :=
                 Editor.Selection.Validate_Active_Selection_Range
                   (The_Editor.State, Selection_Range);
            begin
               if Status = Editor.Selection.Selection_Ok
                 and then not The_Editor.State.Rect_Select_Active
                 and then Natural (The_Editor.State.Carets.Length) = 1
               then
                  declare
                     C : Editor.Cursors.Caret_State :=
                       The_Editor.State.Carets
                         (The_Editor.State.Carets.First_Index);
                  begin
                     C.Pos := Selection_Range.Low;
                     C.Anchor := Selection_Range.Low;
                     The_Editor.State.Carets.Replace_Element
                       (The_Editor.State.Carets.First_Index, C);
                  end;
               end if;
            end;
         end if;

         Editor.Executor.Execute_Command (The_Editor.State, Id, Shift);
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      case Id is
         when Editor.Commands.No_Command =>
            null;

         when Editor.Commands.Command_Open_File =>
            Report_Info ("Open File requires a path");
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Open_Project =>
            Report_Info ("Open Project requires a path");
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Switch_Project =>
            Report_Info ("Switch Project requires a target project");
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Close_Project
            | Editor.Commands.Command_Clear_Project =>
            declare
               Cmd_Clear : Editor.Commands.Command;
            begin
               Cmd_Clear.Kind := Editor.Commands.Close_Project;
               Editor.Instance.Execute (The_Editor, Cmd_Clear);
            end;
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Refresh_File_Tree =>
            Editor.Executor.Execute_Command
              (The_Editor.State, Editor.Commands.Command_Refresh_File_Tree);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Refresh_Project_Files =>
            Editor.Executor.Execute_Command
              (The_Editor.State, Editor.Commands.Command_Refresh_Project_Files);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Project_Files_Summary =>
            Editor.Executor.Execute_Command
              (The_Editor.State, Editor.Commands.Command_Project_Files_Summary);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Open_Command_Palette =>
            Editor.Executor.Command_Surface_Commands.Execute_Open_Command_Palette (The_Editor.State);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Palette_Show_Command_Help =>
            --  even palette-local help display is a discoverable
            --  command and must use the canonical Executor boundary.  The
            --  Executor handles availability, the one outcome message, and the
            --  display-only transient help toggle; this input bridge must not
            --  mutate Command_Palette state directly.
            Editor.Executor.Execute_Command (The_Editor.State, Id);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Open_Quick_Open =>
            Editor.Executor.Command_Surface_Commands.Execute_Open_Quick_Open (The_Editor.State);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Toggle_Quick_Open =>
            Editor.Executor.Command_Surface_Commands.Execute_Toggle_Quick_Open (The_Editor.State);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Open_Project_Search_Bar =>
            Editor.Executor.Project_Search_Surface_Commands.Execute_Open_Project_Search_Bar
              (The_Editor.State);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Toggle_Project_Search_Bar =>
            Editor.Executor.Project_Search_Surface_Commands.Execute_Toggle_Project_Search_Bar
              (The_Editor.State);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Close_Project_Search_Bar =>
            Editor.Executor.Project_Search_Surface_Commands.Execute_Close_Project_Search_Bar
              (The_Editor.State);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Run_Project_Search_From_Bar =>
            Editor.Executor.Project_Search_Surface_Commands.Execute_Run_Project_Search_From_Bar
              (The_Editor.State);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Close_Quick_Open =>
            Editor.Executor.Command_Surface_Commands.Execute_Close_Quick_Open (The_Editor.State);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Accept_Quick_Open =>
            Editor.Executor.Command_Surface_Commands.Execute_Accept_Quick_Open (The_Editor.State);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Quick_Open_Next_Result =>
            Editor.Executor.Command_Surface_Commands.Execute_Quick_Open_Next_Result (The_Editor.State);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Quick_Open_Previous_Result =>
            Editor.Executor.Command_Surface_Commands.Execute_Quick_Open_Previous_Result (The_Editor.State);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Quick_Open_Query_Clear =>
            Editor.Executor.Command_Surface_Commands.Execute_Quick_Open_Clear_Query (The_Editor.State);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Quick_Open_Kind_Next =>
            Editor.Executor.Command_Surface_Commands.Execute_Quick_Open_Kind_Next (The_Editor.State);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Quick_Open_Kind_Previous =>
            Editor.Executor.Command_Surface_Commands.Execute_Quick_Open_Kind_Previous (The_Editor.State);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Quick_Open_Kind_Clear =>
            Editor.Executor.Command_Surface_Commands.Execute_Quick_Open_Kind_Clear (The_Editor.State);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Quick_Open_Scope_Clear =>
            Editor.Executor.Command_Surface_Commands.Execute_Quick_Open_Scope_Clear (The_Editor.State);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Quick_Open_Scope_From_Selected =>
            Editor.Executor.Command_Surface_Commands.Execute_Quick_Open_Scope_From_Selected (The_Editor.State);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Quick_Open_Scope_Parent =>
            Editor.Executor.Command_Surface_Commands.Execute_Quick_Open_Scope_Parent (The_Editor.State);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Quick_Open_Reveal_Active =>
            Editor.Executor.Command_Surface_Commands.Execute_Quick_Open_Reveal_Active (The_Editor.State);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Quick_Open_Scope_Active_Directory =>
            Editor.Executor.Command_Surface_Commands.Execute_Quick_Open_Scope_Active_Directory (The_Editor.State);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Quick_Open_Create_From_Query =>
            Editor.Executor.Command_Surface_Commands.Execute_Quick_Open_Create_From_Query (The_Editor.State);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Quick_Open_Create_With_Parents_From_Query =>
            Editor.Executor.Command_Surface_Commands.Execute_Quick_Open_Create_With_Parents_From_Query (The_Editor.State);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Quick_Open_Priority_Toggle =>
            Editor.Executor.Command_Surface_Commands.Execute_Quick_Open_Priority_Toggle (The_Editor.State);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Quick_Open_Priority_Clear =>
            Editor.Executor.Command_Surface_Commands.Execute_Quick_Open_Priority_Clear (The_Editor.State);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Open_Buffer_Switcher =>
            Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (The_Editor.State);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Close_Buffer_Switcher =>
            Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Close_Buffer_Switcher (The_Editor.State);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Accept_Buffer_Switcher =>
            Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Accept_Buffer_Switcher (The_Editor.State);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Buffer_Switcher_Next_Result =>
            Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Buffer_Switcher_Next_Result (The_Editor.State);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Buffer_Switcher_Previous_Result =>
            Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Buffer_Switcher_Previous_Result (The_Editor.State);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Cancel =>
            if Pending_Confirmation_Active then
               Editor.Executor.Execute_Command
                 (The_Editor.State, Editor.Commands.Command_Cancel_Pending_Transition);
            elsif Editor.Overlay_Focus.Has_Active_Overlay
              (The_Editor.State.Overlay_Focus)
            then
               Editor.Executor.Dismiss_Active_Overlay
                 (The_Editor.State, Editor.Overlay_Focus.Dismiss_Escape);
            else
               Cmd := Editor.Commands.Command_For_Id (Id, Shift);
               Editor.Instance.Execute (The_Editor, Cmd);
            end if;

         when Editor.Commands.Command_Undo
            | Editor.Commands.Command_Redo
            | Editor.Commands.Command_Edit_History_Clear =>
            Editor.Executor.Execute_Command (The_Editor.State, Id, Shift);

         when Editor.Commands.Command_Save_File
            | Editor.Commands.Command_Reload_Active_Buffer
            | Editor.Commands.Command_Revert_Active_Buffer
            | Editor.Commands.Command_Delete_Buffer_File
            | Editor.Commands.Command_New_Buffer
            | Editor.Commands.Command_Close_Active_Buffer
            | Editor.Commands.Command_Close_Other_Buffers
            | Editor.Commands.Command_Close_All_Clean_Buffers
            | Editor.Commands.Command_Pin_Buffer
            | Editor.Commands.Command_Unpin_Buffer
            | Editor.Commands.Command_Toggle_Buffer_Pin
            | Editor.Commands.Command_Set_Buffer_Label
            | Editor.Commands.Command_Clear_Buffer_Label
            | Editor.Commands.Command_Edit_Buffer_Label
            | Editor.Commands.Command_Show_Buffer_Label
            | Editor.Commands.Command_Set_Buffer_Note
            | Editor.Commands.Command_Clear_Buffer_Note
            | Editor.Commands.Command_Edit_Buffer_Note
            | Editor.Commands.Command_Show_Buffer_Note
            | Editor.Commands.Command_Assign_Buffer_Group
            | Editor.Commands.Command_Clear_Buffer_Group
            | Editor.Commands.Command_Switch_Buffer_Group
            | Editor.Commands.Command_Next_Buffer_Group
            | Editor.Commands.Command_Previous_Buffer_Group
            | Editor.Commands.Command_Show_All_Buffer_Groups
            | Editor.Commands.Command_Next_Buffer
            | Editor.Commands.Command_Previous_Buffer
            | Editor.Commands.Command_Previous_Recent_Buffer
            | Editor.Commands.Command_Next_Recent_Buffer
            | Editor.Commands.Command_Switch_Buffer
            | Editor.Commands.Command_Toggle_Problems_Panel
            | Editor.Commands.Command_Run_Project_Search
            | Editor.Commands.Command_Rerun_Project_Search
            | Editor.Commands.Command_Project_Search_From_Selection
            | Editor.Commands.Command_Project_Search_From_Active_Word
            | Editor.Commands.Command_Project_Search_Active_Directory
            | Editor.Commands.Command_Clear_Project_Search
            | Editor.Commands.Command_Open_Selected_Project_Search_Result
            | Editor.Commands.Command_Move_Project_Search_Selection_Up
            | Editor.Commands.Command_Move_Project_Search_Selection_Down
            | Editor.Commands.Command_Next_Project_Search_Result
            | Editor.Commands.Command_Previous_Project_Search_Result
            | Editor.Commands.Command_First_Project_Search_Result
            | Editor.Commands.Command_Last_Project_Search_Result
            | Editor.Commands.Command_Reveal_Active_Project_Search_Result
            | Editor.Commands.Command_Project_Search_Scope_Selected_Directory
            | Editor.Commands.Command_Project_Search_Kind_Next
            | Editor.Commands.Command_Project_Search_Kind_Previous
            | Editor.Commands.Command_Project_Search_Kind_Clear
            | Editor.Commands.Command_Project_Search_Scope_Clear
            | Editor.Commands.Command_Project_Search_Case_Toggle
            | Editor.Commands.Command_Project_Search_Case_Clear
            | Editor.Commands.Command_Project_Search_Whole_Word_Toggle
            | Editor.Commands.Command_Project_Search_Whole_Word_Clear
            | Editor.Commands.Command_Project_Search_Regex_Toggle
            | Editor.Commands.Command_Project_Search_Regex_Clear
            | Editor.Commands.Command_Project_Search_Include_Filter_Clear
            | Editor.Commands.Command_Project_Search_Exclude_Filter_Clear
            | Editor.Commands.Command_Show_Search_Results_Panel
            | Editor.Commands.Command_Focus_Editor_Text
            | Editor.Commands.Command_Focus_Search_Results
            | Editor.Commands.Command_Focus_Problems
            | Editor.Commands.Command_Toggle_Bottom_Panel_Focus
            | Editor.Commands.Command_Search_Results_Move_Up
            | Editor.Commands.Command_Search_Results_Move_Down
            | Editor.Commands.Command_Search_Results_Page_Up
            | Editor.Commands.Command_Search_Results_Page_Down
            | Editor.Commands.Command_Search_Results_Open_Selected
            | Editor.Commands.Command_Focus_File_Tree
            | Editor.Commands.Command_File_Tree_Move_Up
            | Editor.Commands.Command_File_Tree_Move_Down
            | Editor.Commands.Command_File_Tree_Page_Up
            | Editor.Commands.Command_File_Tree_Page_Down
            | Editor.Commands.Command_File_Tree_Open_Selected
            | Editor.Commands.Command_File_Tree_Expand_Selected
            | Editor.Commands.Command_File_Tree_Collapse_Selected
            | Editor.Commands.Command_File_Tree_Toggle_Selected
            | Editor.Commands.Command_Next_Diagnostic
            | Editor.Commands.Command_Previous_Diagnostic
            | Editor.Commands.Command_Toggle_Bookmark
            | Editor.Commands.Command_Next_Bookmark
            | Editor.Commands.Command_Previous_Bookmark
            | Editor.Commands.Command_Clear_Bookmarks
            | Editor.Commands.Command_Clear_All_Bookmarks
            | Editor.Commands.Command_Bookmark_Toggle_Current_Location
            | Editor.Commands.Command_Bookmark_Clear_All
            | Editor.Commands.Command_Bookmark_Next
            | Editor.Commands.Command_Bookmark_Previous
            | Editor.Commands.Command_Bookmark_Goto_Next
            | Editor.Commands.Command_Bookmark_Goto_Previous
            | Editor.Commands.Command_Bookmark_Open_Selected
            | Editor.Commands.Command_Bookmark_Reveal_Current
            | Editor.Commands.Command_Bookmark_Remove_Selected
            | Editor.Commands.Command_Bookmark_Show
            | Editor.Commands.Command_Bookmark_Hide
            | Editor.Commands.Command_Bookmark_Toggle
            | Editor.Commands.Command_Copy
            | Editor.Commands.Command_Cut
            | Editor.Commands.Command_Paste
            | Editor.Commands.Command_Clipboard_Clear
            | Editor.Commands.Command_Select_All
            | Editor.Commands.Command_Selection_Clear
            | Editor.Commands.Command_Select_Word
            | Editor.Commands.Command_Selection_Delete
            | Editor.Commands.Command_Line_Delete
            | Editor.Commands.Command_Line_Duplicate
            | Editor.Commands.Command_Line_Move_Up
            | Editor.Commands.Command_Line_Move_Down
            | Editor.Commands.Command_Indent_Increase
            | Editor.Commands.Command_Indent_Decrease
            | Editor.Commands.Command_Comment_Line
            | Editor.Commands.Command_Uncomment_Line
            | Editor.Commands.Command_Toggle_Line_Comment
            | Editor.Commands.Command_Line_Join_Next
            | Editor.Commands.Command_Line_Split_At_Caret
            | Editor.Commands.Command_Trim_Trailing_Whitespace
            | Editor.Commands.Command_Format_Buffer
            | Editor.Commands.Command_Format_Selected_Text
            | Editor.Commands.Command_Char_Delete_Previous
            | Editor.Commands.Command_Char_Delete_Next
            | Editor.Commands.Command_Word_Delete_Previous
            | Editor.Commands.Command_Word_Delete_Next
            | Editor.Commands.Command_Select_Left
            | Editor.Commands.Command_Select_Right
            | Editor.Commands.Command_Select_Up
            | Editor.Commands.Command_Select_Down
            | Editor.Commands.Command_Select_Line
            | Editor.Commands.Command_Start_Rectangular_Selection
            | Editor.Commands.Command_Clear_Rectangular_Selection
            | Editor.Commands.Command_Extend_Selection_Line_Up
            | Editor.Commands.Command_Extend_Selection_Line_Down
            | Editor.Commands.Command_Select_Word_Left
            | Editor.Commands.Command_Select_Word_Right
            | Editor.Commands.Command_Select_Line_Start
            | Editor.Commands.Command_Select_Line_End
            | Editor.Commands.Command_Select_Document_Start
            | Editor.Commands.Command_Select_Document_End
            | Editor.Commands.Command_Select_Page_Up
            | Editor.Commands.Command_Select_Page_Down
            | Editor.Commands.Command_Move_Left
            | Editor.Commands.Command_Move_Right
            | Editor.Commands.Command_Move_Up
            | Editor.Commands.Command_Move_Down
            | Editor.Commands.Command_Move_Line_Start
            | Editor.Commands.Command_Move_Line_End
            | Editor.Commands.Command_Move_Document_Start
            | Editor.Commands.Command_Move_Document_End
            | Editor.Commands.Command_Move_Word_Left
            | Editor.Commands.Command_Move_Word_Right
            | Editor.Commands.Command_Page_Up
            | Editor.Commands.Command_Page_Down
            | Editor.Commands.Command_Insert_Newline
            | Editor.Commands.Command_Goto_Start
            | Editor.Commands.Command_Goto_End
            | Editor.Commands.Command_Find_Show
            | Editor.Commands.Command_Find_Hide
            | Editor.Commands.Command_Find_Toggle
            | Editor.Commands.Command_Find_From_Selection
            | Editor.Commands.Command_Find_From_Active_Word
            | Editor.Commands.Command_Active_Find_Next
            | Editor.Commands.Command_Active_Find_Previous
            | Editor.Commands.Command_Find_First
            | Editor.Commands.Command_Find_Last
            | Editor.Commands.Command_Find_Reveal_Current
            | Editor.Commands.Command_Find_Query_Clear
            | Editor.Commands.Command_Find_Case_Toggle
            | Editor.Commands.Command_Find_Case_Clear
            | Editor.Commands.Command_Find_Whole_Word_Toggle
            | Editor.Commands.Command_Find_Whole_Word_Clear
            | Editor.Commands.Command_Replace_Show
            | Editor.Commands.Command_Replace_Hide
            | Editor.Commands.Command_Replace_Toggle
            | Editor.Commands.Command_Replace_Text_Clear
            | Editor.Commands.Command_Replace_Current
            | Editor.Commands.Command_Replace_All
            | Editor.Commands.Command_Refresh_Outline
            | Editor.Commands.Command_Clear_Outline
            | Editor.Commands.Command_Show_Outline
            | Editor.Commands.Command_Focus_Outline
            | Editor.Commands.Command_Open_Selected_Outline_Item
            | Editor.Commands.Command_Select_Current_Outline_Symbol
            | Editor.Commands.Command_Reveal_Current_Outline_Symbol
            | Editor.Commands.Command_Select_Next_Outline_Item
            | Editor.Commands.Command_Select_Previous_Outline_Item
            | Editor.Commands.Command_Focus_Outline_Filter
            | Editor.Commands.Command_Filter_Outline
            | Editor.Commands.Command_Clear_Outline_Filter
            | Editor.Commands.Command_Toggle_Outline_Filter
            | Editor.Commands.Command_Outline_Filter_History_Previous
            | Editor.Commands.Command_Outline_Filter_History_Next
            | Editor.Commands.Command_Clear_Outline_Filter_History
            | Editor.Commands.Command_Show_Messages
            | Editor.Commands.Command_Clear_Messages
            | Editor.Commands.Command_Clear_Selected_Message
            | Editor.Commands.Command_Copy_Selected_Message_Text
            | Editor.Commands.Command_Clear_Info_Messages
            | Editor.Commands.Command_Clear_Warning_Messages
            | Editor.Commands.Command_Clear_Error_Messages
            | Editor.Commands.Command_Toggle_Message_Info
            | Editor.Commands.Command_Toggle_Message_Warnings
            | Editor.Commands.Command_Toggle_Message_Errors
            | Editor.Commands.Command_Show_All_Messages
            | Editor.Commands.Command_Clear_Message_Filter
            | Editor.Commands.Command_Goto_Line
            | Editor.Commands.Command_Goto_Line_Toggle
            | Editor.Commands.Command_Goto_Line_Prefill_Current
            | Editor.Commands.Command_Goto_Line_Query_Set
            | Editor.Commands.Command_Goto_Line_Query_Clear
            | Editor.Commands.Command_Close_Goto_Line
            | Editor.Commands.Command_Accept_Goto_Line
            | Editor.Commands.Command_Diagnostics_Show
            | Editor.Commands.Command_Diagnostics_Clear
            | Editor.Commands.Command_Diagnostics_Toggle_Info
            | Editor.Commands.Command_Diagnostics_Toggle_Warnings
            | Editor.Commands.Command_Diagnostics_Toggle_Errors
            | Editor.Commands.Command_Diagnostics_Show_All
            | Editor.Commands.Command_Diagnostics_Clear_Filter
            | Editor.Commands.Command_Diagnostics_Filter_Errors
            | Editor.Commands.Command_Diagnostics_Filter_Warnings
            | Editor.Commands.Command_Diagnostics_Filter_Info_Notes
            | Editor.Commands.Command_Diagnostics_Filter_Source
            | Editor.Commands.Command_Diagnostics_Filter_Build
            | Editor.Commands.Command_Diagnostics_Clear_Build
            | Editor.Commands.Command_Diagnostics_Open_Selected
            | Editor.Commands.Command_Diagnostics_Execute_Selected_Action
            | Editor.Commands.Command_Diagnostics_Select_Next
            | Editor.Commands.Command_Diagnostics_Select_Previous
            | Editor.Commands.Command_Diagnostics_Clear_Selected
            | Editor.Commands.Command_Diagnostics_Copy_Selected_Text
            | Editor.Commands.Command_Diagnostics_Clear_Info
            | Editor.Commands.Command_Diagnostics_Clear_Warnings
            | Editor.Commands.Command_Diagnostics_Clear_Errors
            | Editor.Commands.Command_Diagnostics_Toggle_Editor_Source
            | Editor.Commands.Command_Diagnostics_Toggle_File_Source
            | Editor.Commands.Command_Diagnostics_Toggle_Project_Source
            | Editor.Commands.Command_Diagnostics_Toggle_External_Source
            | Editor.Commands.Command_Diagnostics_Toggle_Unknown_Source
            | Editor.Commands.Command_Quick_Open_Query_Set
            | Editor.Commands.Command_Quick_Open_Scope_Set =>
            Cmd := Editor.Commands.Command_For_Id (Id, Shift);
            Editor.Instance.Execute (The_Editor, Cmd);

         when Editor.Commands.Command_Save_Settings
            | Editor.Commands.Command_Reload_Settings
            | Editor.Commands.Command_Reset_Settings_To_Defaults
            | Editor.Commands.Command_Set_Theme_Light
            | Editor.Commands.Command_Set_Theme_Dark
            | Editor.Commands.Command_Toggle_Minimap
            | Editor.Commands.Command_Toggle_Scrollbars
            | Editor.Commands.Command_Toggle_Line_Number_Mode
            | Editor.Commands.Command_Toggle_Cursor_Blink =>
            Cmd := Editor.Commands.Command_For_Id (Id, Shift);
            Editor.Instance.Execute (The_Editor, Cmd);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Dismiss_Latest_Message =>
            Editor.Messages.Dismiss_Latest (The_Editor.State.Messages);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Dismiss_All_Messages =>
            Editor.Messages.Dismiss_All (The_Editor.State.Messages);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Toggle_Theme =>
            Cmd := Editor.Commands.Command_For_Id (Id, Shift);
            Editor.Instance.Execute (The_Editor, Cmd);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Toggle_Line_Numbers =>
            Editor.Settings.Toggle_Show_Line_Numbers;
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Set_Absolute_Line_Numbers =>
            Editor.Line_Numbers.Set_Current
              ((Mode => Editor.Line_Numbers.Absolute_Line_Numbers));
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Set_Relative_Line_Numbers =>
            Editor.Line_Numbers.Set_Current
              ((Mode => Editor.Line_Numbers.Relative_Line_Numbers));
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Set_Hybrid_Line_Numbers =>
            Editor.Line_Numbers.Set_Current
              ((Mode => Editor.Line_Numbers.Hybrid_Line_Numbers));
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Toggle_Current_Line_Highlight =>
            Editor.Settings.Toggle_Highlight_Current_Line;
            Editor.Settings.Set_Highlight_Current_Gutter
              (Editor.Settings.Highlight_Current_Line);
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Toggle_Syntax_Colouring =>
            Editor.Settings.Toggle_Use_Syntax_Colouring;
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Toggle_Diagnostics =>
            Editor.Settings.Toggle_Show_Diagnostics;
            Editor.Render_Cache.Invalidate_All;

         when Editor.Commands.Command_Toggle_Cursor_Style =>
            Cursor_Config := Editor.Cursor.Current;
            case Cursor_Config.Style is
               when Editor.Cursor.Bar_Cursor =>
                  Cursor_Config.Style := Editor.Cursor.Block_Cursor;
               when Editor.Cursor.Block_Cursor =>
                  Cursor_Config.Style := Editor.Cursor.Underline_Cursor;
               when Editor.Cursor.Underline_Cursor =>
                  Cursor_Config.Style := Editor.Cursor.Bar_Cursor;
            end case;
            Editor.Cursor.Set_Current (Cursor_Config);
            Editor.Render_Cache.Invalidate_All;

         when others =>
            Editor.Executor.Execute_Command (The_Editor.State, Id, Shift);
            Editor.Render_Cache.Invalidate_All;
      end case;

      --  focus return/dismissal is command-result policy, not
      --  per-surface accident.  Apply it after the canonical command path has
      --  run so stale row activations cannot leave their old surface focused,
      --  while overlay close/cancel restores a still-valid previous focus or
      --  falls back to editor.
      Editor.Focus_Management.Apply_Command_Focus_Result
        (The_Editor.State, Id, Owner_Before);
   end Execute_Command_Id;

   procedure Execute_Command_Id_No_Shift
     (Id : Editor.Commands.Command_Id)
   is
   begin
      Execute_Command_Id (Id);
   end Execute_Command_Id_No_Shift;

   procedure Execute_Instance_Command
     (Command : Editor.Commands.Command)
   is
   begin
      Editor.Instance.Execute (The_Editor, Command);
   end Execute_Instance_Command;

   function Handle_Command_Palette
     (Cmd : Editor.Commands.Command) return Boolean
   is
   begin
      return Editor.Input_Bridge.Command_Palette_Handlers.Handle_Command_Palette
        (The_Editor.State, Cmd, Execute_Command_Id_No_Shift'Access,
         Report_Info'Access, Report_Warning'Access);
   end Handle_Command_Palette;


   function Handle_Quick_Open
     (Cmd : Editor.Commands.Command) return Boolean
   is
   begin
      return Editor.Input_Bridge.Quick_Open_Handlers.Handle_Quick_Open
        (The_Editor.State, Cmd, Execute_Command_Id_No_Shift'Access,
         Execute_Instance_Command'Access);
   end Handle_Quick_Open;



   function Handle_Buffer_Switcher
     (Cmd : Editor.Commands.Command) return Boolean
   is
   begin
      return Editor.Input_Bridge.Buffer_Switcher_Handlers.Handle_Buffer_Switcher
        (The_Editor.State, Cmd, Execute_Command_Id_No_Shift'Access,
         Execute_Instance_Command'Access);
   end Handle_Buffer_Switcher;

   function Handle_Project_Search_Bar
     (Cmd : Editor.Commands.Command) return Boolean
   is
   begin
      return Editor.Input_Bridge.Project_Search_Bar_Handlers
        .Handle_Project_Search_Bar
          (The_Editor.State, Cmd, Execute_Command_Id_No_Shift'Access,
           Execute_Instance_Command'Access,
           Sync_Project_Search_Replace_Mode_From_Bar'Access);
   end Handle_Project_Search_Bar;



   function Handle_Goto_Line
     (Cmd : Editor.Commands.Command) return Boolean
   is
   begin
      return Editor.Input_Bridge.Goto_Line_Handlers.Handle_Goto_Line
        (The_Editor.State, Cmd, Execute_Command_Id_No_Shift'Access,
         Execute_Instance_Command'Access);
   end Handle_Goto_Line;

   function Handle_Active_Find_Input
     (Cmd : Editor.Commands.Command) return Boolean
   is
   begin
      return Editor.Input_Bridge.Active_Find_Handlers.Handle_Active_Find_Input
        (The_Editor.State, Cmd, Execute_Command_Id_No_Shift'Access,
         Execute_Instance_Command'Access);
   end Handle_Active_Find_Input;

   function Handle_Outline_Filter_Input
     (Cmd : Editor.Commands.Command) return Boolean
   is
   begin
      return Editor.Input_Bridge.Outline_Filter_Handlers
        .Handle_Outline_Filter_Input
          (The_Editor.State, Cmd, Execute_Command_Id_No_Shift'Access);
   end Handle_Outline_Filter_Input;

   function Handle_File_Target_Prompt
     (Cmd : Editor.Commands.Command) return Boolean
   is
   begin
      return Editor.Input_Bridge.File_Target_Handlers.Handle_File_Target_Prompt
        (The_Editor.State, Cmd);
   end Handle_File_Target_Prompt;


   function Handle_Search_Query_Input
     (Cmd : Editor.Commands.Command) return Boolean
   is
   begin
      return Editor.Input_Bridge.Search_Query_Handlers.Handle_Search_Query_Input
        (The_Editor.State, Cmd, Execute_Command_Id_No_Shift'Access);
   end Handle_Search_Query_Input;



   function Max_Visible_Line_Length return Natural
   is
      Snap : Editor.Render_Model.Render_Snapshot;
      Max_Col : Natural := 0;
   begin
      Get_Render_Snapshot (Snap);

      for I in 1 .. Snap.Visible_Visual_Count loop
         declare
            Seg : constant Editor.Wrap.Visual_Row_Info :=
              Snap.Visible_Visual_Rows (I);
         begin
            if not Editor.Folding.Is_Row_Hidden (Snap.Folding, Seg.Logical_Row)
              and then Seg.End_Col >= Seg.Start_Col
            then
               Max_Col := Natural'Max (Max_Col, Seg.End_Col);
            end if;
         end;
      end loop;

      return Max_Col;
   end Max_Visible_Line_Length;



   procedure Execute_Pending_Bar_Command
     (Id : Editor.Commands.Command_Id)
   is
   begin
      Execute_Command_Id (Id);
   end Execute_Pending_Bar_Command;

   procedure Execute_Problems_Header_Command
     (Id : Editor.Commands.Command_Id)
   is
   begin
      Editor.Executor.Execute_Command (The_Editor.State, Id);
   end Execute_Problems_Header_Command;

   procedure Report_Build_UI_Info
     (Message : String)
   is
   begin
      Report_Info (Message);
   end Report_Build_UI_Info;

   ------------------------------------------------------------------
   -- Lifecycle
   ------------------------------------------------------------------

   procedure Reset is
   begin
      Editor.Instance.Init (The_Editor);
      Editor.Settings.Reset;
      Editor.Line_Numbers.Reset;
      Editor.Command_Palette.Reset;
      Editor.File_Tree_View.Reset;
      Editor.Panels.Initialize_Defaults (The_Editor.State.Panels);
      Editor.Panels.Set_Current (The_Editor.State.Panels);
      Pointer_State.Reset_All;
      Editor.State.Clear_Gutter_Marker_Hover (The_Editor.State);
      Editor.Panels.End_Resize (The_Editor.State.Panels);
      Editor.Panels.Set_Current (The_Editor.State.Panels);
      Editor.Scrollbars.Reset;
      declare
         Loaded_Keybindings : Editor.Keybinding_Config.Keybinding_Config_Model;
         Keybinding_Status  : Editor.Keybinding_Config.Keybinding_Config_Status;
      begin
         Editor.Keybindings.Reset_To_Defaults;
         Editor.Keybinding_Config.Load_From_File
           (Editor.Keybinding_Config.Keybindings_File_Path,
            Loaded_Keybindings,
            Keybinding_Status);
         if Keybinding_Status = Editor.Keybinding_Config.Keybinding_Config_Ok
           or else Keybinding_Status = Editor.Keybinding_Config.Keybinding_Config_Partial_Load
         then
            Editor.Keybinding_Config.Apply_To_Runtime (Loaded_Keybindings);
         end if;
      end;
      --  keybinding-management UI state is transient. Runtime
      --  keybindings are reloaded above, but query/filter/selection/capture/
      --  reset confirmation state must not survive Input_Bridge reset.
      Editor.Keybinding_Management.Reset_Transient_State;
      --  guided prompts are transient input/focus state and must
      --  not survive an Input_Bridge reset or become an implicit persistence
      --  domain.
      Editor.Guided_Prompts.Clear (The_Editor.State.Guided_Prompt);
      Initialized := True;
   end Reset;

   procedure Open_Project_Path
     (Path : String)
   is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before opening a project path");

      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (The_Editor.State, Path);
      Editor.Render_Cache.Invalidate_All;
   end Open_Project_Path;

   ------------------------------------------------------------------
   -- Command dispatch
   ------------------------------------------------------------------

   procedure Handle_Key_Chord
     (Chord : Editor.Keybindings.Key_Chord)
   is
      Id  : Editor.Commands.Command_Id;
      Cmd : Editor.Commands.Command;

      procedure Execute_Command_Id_Default
        (Command_Id : Editor.Commands.Command_Id)
      is
      begin
         Execute_Command_Id (Command_Id);
      end Execute_Command_Id_Default;

      procedure Execute_Instance_Command_Default
        (Command : Editor.Commands.Command)
      is
      begin
         Editor.Instance.Execute (The_Editor, Command);
      end Execute_Instance_Command_Default;

      procedure Execute_Command_Id_With_Shift
        (Command_Id : Editor.Commands.Command_Id;
         Shift      : Boolean)
      is
      begin
         Execute_Command_Id (Command_Id, Shift);
      end Execute_Command_Id_With_Shift;

      procedure Execute_Active_Find_Previous_Default is
      begin
         Execute_Command_Id (Editor.Commands.Command_Active_Find_Previous);
      end Execute_Active_Find_Previous_Default;

      procedure Hide_Active_Find_Default is
      begin
         Cmd.Kind := Editor.Commands.Active_Find_Hide;
         Editor.Instance.Execute (The_Editor, Cmd);
      end Hide_Active_Find_Default;
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before handling key chords");

      if Key_Chord_Routing.Handle_Pre_Bound_Chord
        (The_Editor.State,
         Chord,
         Accept_Guided_Prompt_Enter'Access,
         Report_Info'Access,
         Execute_Command_Id_With_Shift'Access,
         Execute_Command_Id_Default'Access,
         Execute_Active_Find_Previous_Default'Access,
         Hide_Active_Find_Default'Access)
      then
         return;
      end if;

      if Key_Chord_Routing.Handle_Focused_Surface_Pre_Bound_Chord
        (The_Editor.State, Chord, Execute_Command_Id_Default'Access)
      then
         return;
      end if;

      if Editor.Keybindings.Resolve (Chord, Id) = Editor.Keybindings.Bound_Command then
         Cmd := Editor.Commands.Command_For_Id (Id, Chord.Modifiers.Shift);

         if Editor.Overlay_Focus.Is_Active
           (The_Editor.State.Overlay_Focus,
            Editor.Overlay_Focus.Command_Palette_Overlay)
         then
            if Handle_Command_Palette (Cmd) then
               Editor.Cursor.Notify_Input
                 (Float (Editor.View.Current_Time_Seconds));
            end if;
         elsif Editor.Input_Bridge.Quick_Open_Key_Handlers
           .Handle_Quick_Open_Key
             (The_Editor.State, Chord,
              Execute_Command_Id_Default'Access,
              Execute_Instance_Command_Default'Access)
         then
            null;
         elsif Editor.Input_Bridge.Buffer_Switcher_Key_Handlers
           .Handle_Buffer_Switcher_Key
             (The_Editor.State, Chord,
              Execute_Command_Id_Default'Access,
              Execute_Instance_Command_Default'Access)
         then
            null;
         elsif Editor.Input_Bridge.Project_Search_Key_Handlers
           .Handle_Project_Search_Bar_Key
             (The_Editor.State, Chord,
              Execute_Command_Id_Default'Access,
              Execute_Instance_Command_Default'Access)
         then
            null;
         elsif Editor.Input_Bridge.File_Target_Key_Handlers
           .Handle_File_Target_Key (The_Editor.State, Chord)
         then
            null;
         elsif Editor.Input_Bridge.Goto_Line_Key_Handlers
           .Handle_Goto_Line_Key
             (The_Editor.State, Chord,
              Execute_Command_Id_Default'Access,
              Execute_Instance_Command_Default'Access)
         then
            null;
         elsif Editor.Overlay_Focus.Is_Active
           (The_Editor.State.Overlay_Focus,
            Editor.Overlay_Focus.Active_Find_Prompt_Overlay)
           and then (Id = Editor.Commands.Command_Active_Find_Next
                     or else Id = Editor.Commands.Command_Active_Find_Previous
                     or else Id = Editor.Commands.Command_Find_First
                     or else Id = Editor.Commands.Command_Find_Last
                     or else Id = Editor.Commands.Command_Find_Reveal_Current
                     or else Id = Editor.Commands.Command_Find_From_Selection
                     or else Id = Editor.Commands.Command_Find_From_Active_Word
                     or else Id = Editor.Commands.Command_Find_Query_Clear
                     or else Id = Editor.Commands.Command_Find_Case_Toggle
                     or else Id = Editor.Commands.Command_Find_Case_Clear
                     or else Id = Editor.Commands.Command_Find_Whole_Word_Toggle
                     or else Id = Editor.Commands.Command_Find_Whole_Word_Clear
                     or else Id = Editor.Commands.Command_Replace_Show
                     or else Id = Editor.Commands.Command_Replace_Hide
                     or else Id = Editor.Commands.Command_Replace_Toggle
                     or else Id = Editor.Commands.Command_Replace_Text_Clear
                     or else Id = Editor.Commands.Command_Replace_Current
                     or else Id = Editor.Commands.Command_Replace_All)
         then
            Execute_Command_Id (Id, Shift => Chord.Modifiers.Shift);
            Editor.Cursor.Notify_Input
              (Float (Editor.View.Current_Time_Seconds));
         elsif The_Editor.State.Active_Find_Prompt
           and then Editor.Overlay_Focus.Is_Active
             (The_Editor.State.Overlay_Focus,
              Editor.Overlay_Focus.Active_Find_Prompt_Overlay)
         then
            case Chord.Key is
               when Editor.Keybindings.Key_Enter =>
                  if Chord.Modifiers.Shift then
                     Execute_Command_Id (Editor.Commands.Command_Active_Find_Previous);
                  else
                     Execute_Command_Id (Editor.Commands.Command_Active_Find_Next);
                  end if;
               when Editor.Keybindings.Key_Escape =>
                  Execute_Command_Id (Editor.Commands.Command_Find_Hide);
               when Editor.Keybindings.Key_Tab =>
                  null;
               when Editor.Keybindings.Key_Backspace =>
                  Cmd.Kind := Editor.Commands.Active_Find_Input_Backspace;
                  Editor.Instance.Execute (The_Editor, Cmd);
               when Editor.Keybindings.Key_Delete =>
                  Cmd.Kind := Editor.Commands.Active_Find_Input_Delete_Forward;
                  Editor.Instance.Execute (The_Editor, Cmd);
               when Editor.Keybindings.Key_Left =>
                  Editor.Executor.Find_Replace_Commands.Execute_Active_Find_Input_Move_Cursor_Left
                    (The_Editor.State);
               when Editor.Keybindings.Key_Right =>
                  Editor.Executor.Find_Replace_Commands.Execute_Active_Find_Input_Move_Cursor_Right
                    (The_Editor.State);
               when Editor.Keybindings.Key_Home =>
                  Editor.Executor.Find_Replace_Commands.Execute_Active_Find_Input_Move_Cursor_Start
                    (The_Editor.State);
               when Editor.Keybindings.Key_End =>
                  Editor.Executor.Find_Replace_Commands.Execute_Active_Find_Input_Move_Cursor_End
                    (The_Editor.State);
               when Editor.Keybindings.Key_V =>
                  if Chord.Modifiers.Ctrl then
                     Cmd.Kind := Editor.Commands.Active_Find_Input_Insert_Text;
                     Cmd.Text :=
                       Editor.Executor.Clipboard.Text_For_Local_Input;
                     Editor.Instance.Execute (The_Editor, Cmd);
                  end if;
               when others =>
                  null;
            end case;
            Editor.Cursor.Notify_Input
              (Float (Editor.View.Current_Time_Seconds));
         elsif Editor.Input_Bridge.Feature_Panel_Key_Handlers
           .Handle_Feature_Panel_Key
             (The_Editor.State, Chord, Execute_Command_Id_Default'Access)
         then
            null;
         elsif Editor.Input_Bridge.File_Tree_Key_Handlers.Handle_File_Tree_Key
           (The_Editor.State, Chord, Execute_Command_Id_Default'Access)
         then
            null;
         elsif Editor.Input_Bridge.Build_UI_Key_Handlers.Handle_Build_UI_Key
           (The_Editor.State, Chord,
            Execute_Command_Id_Default'Access,
            Report_Info'Access)
         then
            null;
         elsif Editor.Input_Bridge.Panel_Focus_Key_Handlers
           .Handle_Focused_Surface_Key
             (The_Editor.State, Chord, Execute_Command_Id_Default'Access)
         then
            null;
         else
            Execute_Command_Id (Id, Shift => Chord.Modifiers.Shift);
            Editor.Cursor.Notify_Input
              (Float (Editor.View.Current_Time_Seconds));
         end if;
      end if;
   end Handle_Key_Chord;


   procedure Handle_Wheel
     (X       : Natural;
      Y       : Natural;
      Delta_X : Integer;
      Delta_Y : Integer)
   is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before handling wheel input");

      Wheel_Handlers.Handle_Wheel
        (The_Editor.State, X, Y, Delta_X, Delta_Y);
   end Handle_Wheel;

   procedure Handle
     (Cmd : Editor.Commands.Command) is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before handling commands");

      --  Active splitter resize owns pointer capture until release/cancel.
      --  It is checked before modal/chrome routing so drag/release events cannot
      --  leak into text, gutter, file-tree rows, minimap, or scrollbars.
      if Editor.Panels.Resize_Active (The_Editor.State.Panels)
        and then Pointer_Surface_Handlers.Handle_Panel_Splitter_Pointer
          (The_Editor.State, Cmd)
      then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Pending_Confirmation_Active then
         if Pointer_Surface_Handlers.Handle_Pending_Transition_Bar_Pointer
           (The_Editor.State, Cmd, Execute_Pending_Bar_Command'Access)
         then
            Editor.Cursor.Notify_Input
              (Float (Editor.View.Current_Time_Seconds));
            return;
         end if;

         case Cmd.Kind is
            when Editor.Commands.Cancel_Pending_Transition
               | Editor.Commands.Retry_Pending_Transition
               | Editor.Commands.Discard_Pending_Transition =>
               null;
            when others =>
               Editor.Cursor.Notify_Input
                 (Float (Editor.View.Current_Time_Seconds));
               return;
         end case;
      end if;

      if Editor.Guided_Prompts.Is_Active (The_Editor.State.Guided_Prompt) then
         case Cmd.Kind is
            when Editor.Commands.Insert_Text_Input =>
               if The_Editor.State.Guided_Prompt.Kind =
                 Editor.Guided_Prompts.Keybinding_Capture_Prompt
               then
                  --  Keybinding capture owns keyboard chords, not text input.
                  --  Character text events must not become prompt payload or edit
                  --  the active buffer while capture is active.
                  null;
               elsif Cmd.Ch = ASCII.LF or else Cmd.Ch = ASCII.CR then
                  Accept_Guided_Prompt_Enter;
               elsif Cmd.Ch = ASCII.ESC then
                  Editor.Guided_Prompts.Cancel (The_Editor.State.Guided_Prompt);
                  Report_Info ("Prompt cancelled.");
               elsif Length (Cmd.Text) > 0 then
                  Editor.Guided_Prompts.Insert_Text
                    (The_Editor.State.Guided_Prompt, To_String (Cmd.Text));
               elsif Cmd.Ch /= ASCII.NUL then
                  Editor.Guided_Prompts.Insert_Text
                    (The_Editor.State.Guided_Prompt, String'(1 => Cmd.Ch));
               end if;
            when Editor.Commands.Delete_Char
               | Editor.Commands.Delete_Previous_Character =>
               Editor.Guided_Prompts.Backspace (The_Editor.State.Guided_Prompt);
            when Editor.Commands.Forward_Delete_Char
               | Editor.Commands.Delete_Next_Character =>
               Editor.Guided_Prompts.Delete_Forward (The_Editor.State.Guided_Prompt);
            when Editor.Commands.Split_Current_Line_At_Caret =>
               Accept_Guided_Prompt_Enter;
            when others =>
               null;
         end case;
         Editor.Render_Cache.Invalidate_All;
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      --  completeness: when an overlay owns focus, generic input
      --  dispatch must not continue into lower-priority surfaces merely
      --  because the active overlay did not understand a pointer/command
      --  event.  Route the event only to the owning overlay handler and then
      --  consume it.  This prevents prompt/overlay focus leaks such as a
      --  Go-To-Line prompt allowing an underlying File Tree, tab, gutter, or
      --  editor-text click to activate while the prompt still owns input.
      if Editor.Input_Bridge.Command_Routing.Handle_Active_Overlay
        (The_Editor.State,
         Cmd,
         Handle_Command_Palette'Access,
         Handle_Quick_Open'Access,
         Handle_Buffer_Switcher'Access,
         Handle_Project_Search_Bar'Access,
         Handle_Goto_Line'Access,
         Handle_Active_Find_Input'Access,
         Handle_File_Target_Prompt'Access)
      then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      --  Feature Search query input and Outline filter
      --  input are text-input focus owners even though they are embedded in
      --  the feature panel rather than represented by Overlay_Focus.  They
      --  therefore need the same high-priority dispatch isolation as modal
      --  overlays: route the event only to the owning text-field handler and
      --  consume it, so unrelated pointer/key events cannot activate File
      --  Tree rows, tab-bar items, search/problemlist rows, or editor text
      --  underneath a focused panel input field.
      if Editor.Input_Bridge.Command_Routing.Handle_Focused_Panel_Input
        (The_Editor.State,
         Cmd,
         Handle_Search_Query_Input'Access,
         Handle_Outline_Filter_Input'Access)
      then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Pointer_Surface_Handlers.Handle_Problems_Panel_Pointer
        (The_Editor.State, Cmd, Execute_Problems_Header_Command'Access)
      then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Handle_Command_Palette (Cmd) then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Pointer_Surface_Handlers.Handle_Message_Overlay_Pointer (Cmd) then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Handle_Quick_Open (Cmd) then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Handle_Buffer_Switcher (Cmd) then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Handle_Project_Search_Bar (Cmd) then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Handle_Goto_Line (Cmd) then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Handle_Active_Find_Input (Cmd) then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Handle_File_Target_Prompt (Cmd) then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Handle_Search_Query_Input (Cmd) then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Handle_Outline_Filter_Input (Cmd) then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Pointer_Surface_Handlers.Handle_Pending_Transition_Bar_Pointer
        (The_Editor.State, Cmd, Execute_Pending_Bar_Command'Access)
      then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Pointer_Surface_Handlers.Handle_Build_UI_Panel_Pointer
        (The_Editor.State, Cmd, Execute_Pending_Bar_Command'Access,
         Report_Build_UI_Info'Access)
      then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Pointer_Surface_Handlers.Handle_Tab_Bar_Pointer
        (The_Editor.State, Cmd)
      then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Pointer_Surface_Handlers.Handle_Status_Bar_Pointer
        (The_Editor.State, Cmd)
      then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Pointer_Surface_Handlers.Handle_Panel_Splitter_Pointer
        (The_Editor.State, Cmd)
      then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Pointer_Surface_Handlers.Handle_File_Tree_Pointer
        (The_Editor.State, Cmd)
      then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Pointer_Surface_Handlers.Handle_Search_Results_Panel_Pointer
        (The_Editor.State, Cmd)
      then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Pointer_Surface_Handlers.Handle_Feature_Panel_Pointer
        (The_Editor.State, Cmd)
      then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      --  Minimap hit-testing owns the minimap region before scrollbars so a
      --  minimap click cannot be interpreted as a vertical scrollbar action.
      if Pointer_State.Minimap_Drag_Active
        and then Pointer_Surface_Handlers.Handle_Minimap_Pointer
          (The_Editor.State, Cmd)
      then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Pointer_Surface_Handlers.Handle_Minimap_Pointer
        (The_Editor.State, Cmd)
      then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Pointer_Surface_Handlers.Handle_Scrollbar_Pointer
        (The_Editor.State, Cmd, Max_Visible_Line_Length)
      then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Pointer_Surface_Handlers.Handle_Gutter_Pointer
        (The_Editor.State, Cmd)
      then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      --  Any non-minimap/scrollbar/fold-marker command returns to normal caret-following scroll
      --  semantics.  This prevents a stale minimap/manual-scroll override
      --  from suppressing auto-scroll after keyboard navigation, editing, or
      --  ordinary text mouse input.
      Editor.View.Clear_User_Scroll_Override;

      if Cmd.Kind = Editor.Commands.Move_To_Point
        or else Cmd.Kind = Editor.Commands.Drag_To_Point
        or else Cmd.Kind = Editor.Commands.Select_Word_At_Point
        or else Cmd.Kind = Editor.Commands.Select_Line_At_Point
      then
         --  completeness: pointer focus into editor text must clear
         --  retained overlay/panel transient owners, not only set the
         --  structural Panel_Focus fallback.  Otherwise stale Build/Recent or
         --  embedded text-input focus markers can continue to win effective
         --  focus after a user clicks the editor.
         Editor.Focus_Management.Restore_Focus_To_Editor (The_Editor.State);
      end if;

      case Cmd.Kind is
         when Editor.Commands.Undo =>
            Execute_Command_Id (Editor.Commands.Command_Undo);

         when Editor.Commands.Redo =>
            Execute_Command_Id (Editor.Commands.Command_Redo);

         when Editor.Commands.Insert_Text_Input
            | Editor.Commands.Delete_Char
            | Editor.Commands.Forward_Delete_Char
            | Editor.Commands.Delete_Previous_Character
            | Editor.Commands.Delete_Next_Character
            | Editor.Commands.Delete_Previous_Word
            | Editor.Commands.Delete_Next_Word
            | Editor.Commands.Delete_Selection_Range
            | Editor.Commands.Split_Current_Line_At_Caret =>
            declare
               Route : constant Text_Entry_Route_Result :=
                 Preview_Text_Entry_Route (Cmd);
            begin
               case Route is
                  when Routed_To_Text_Insert
                     | Routed_To_Selection_Delete
                     | Routed_To_Delete_Previous_Character
                     | Routed_To_Delete_Next_Character
                     | Routed_To_Delete_Previous_Word
                     | Routed_To_Delete_Next_Word
                     | Routed_To_Line_Split =>
                     Editor.Instance.Execute
                       (The_Editor, Canonical_Text_Entry_Command (Cmd));
                     if The_Editor.State.Semantic_Popup.Active then
                        Refresh_Or_Clear_Semantic_Completion_Popup;
                     end if;
                  when others =>
                     null;
               end case;
            end;

         when others =>
            Editor.Instance.Execute (The_Editor, Cmd);
      end case;

      Editor.Cursor.Notify_Input
        (Float (Editor.View.Current_Time_Seconds));
   end Handle;

   ------------------------------------------------------------------
   -- Render snapshot
   ------------------------------------------------------------------

   procedure Build_Render_Packet
   (Packet : out Editor.Render_Packet.Render_Packet) is
   begin
      pragma Assert (Initialized,
       "Input_Bridge must be initialized before rendering");

      Editor.Render_Packet.Build_Render_Packet (Packet);
   end Build_Render_Packet;

   procedure Get_Render_Snapshot
     (Out_Snapshot : out Editor.Render_Model.Render_Snapshot) is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering");

      Editor.Input_Bridge.Render_Access.Get_Render_Snapshot
        (The_Editor.State, Out_Snapshot);
   end Get_Render_Snapshot;

   procedure Get_File_Tree_For_Render
     (Out_Tree : out Editor.File_Tree.File_Tree_State)
   is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering file tree");

      Out_Tree := Editor.Input_Bridge.Render_Access.File_Tree_For_Render
        (The_Editor.State);
   end Get_File_Tree_For_Render;

   procedure Get_Problems_For_Render
     (Out_Snapshot : out Editor.Problems.Problems_Snapshot)
   is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering problems");

      Out_Snapshot := Editor.Input_Bridge.Render_Access.Problems_For_Render
        (The_Editor.State);
   end Get_Problems_For_Render;

   function Problems_Total_Count_For_Render return Natural is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering problem count");
      return Editor.Input_Bridge.Render_Access.Problems_Total_Count_For_Render
        (The_Editor.State);
   end Problems_Total_Count_For_Render;

   procedure Get_Search_Results_For_Render
     (Out_Snapshot : out Editor.Search_Results.Search_Results_Snapshot)
   is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering search results");

      Out_Snapshot := Editor.Input_Bridge.Render_Access.Search_Results_For_Render
        (The_Editor.State);
   end Get_Search_Results_For_Render;

   function Search_Results_Focused_For_Render return Boolean is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering focus state");
      return Editor.Input_Bridge.Render_Access.Search_Results_Focused_For_Render
        (The_Editor.State);
   end Search_Results_Focused_For_Render;

   function Problems_Focused_For_Render return Boolean is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering focus state");
      return Editor.Input_Bridge.Render_Access.Problems_Focused_For_Render
        (The_Editor.State);
   end Problems_Focused_For_Render;

   function File_Tree_Focused_For_Render return Boolean is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering file tree focus state");
      return Editor.Input_Bridge.Render_Access.File_Tree_Focused_For_Render
        (The_Editor.State);
   end File_Tree_Focused_For_Render;

   function Feature_Panel_For_Render return Editor.Feature_Panel.Feature_Panel_State is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering feature panel");
      return Editor.Input_Bridge.Render_Access.Feature_Panel_For_Render
        (The_Editor.State);
   end Feature_Panel_For_Render;

   function Feature_Panel_Focused_For_Render return Boolean is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering feature panel focus state");
      return Editor.Input_Bridge.Render_Access.Feature_Panel_Focused_For_Render
        (The_Editor.State);
   end Feature_Panel_Focused_For_Render;

   function File_Tree_View_For_Render return Editor.File_Tree_View.File_Tree_View_State is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering file tree view state");
      return Editor.Input_Bridge.Render_Access.File_Tree_View_For_Render
        (The_Editor.State);
   end File_Tree_View_For_Render;

   function Problems_View_For_Render return Editor.Problems.Problems_View_State is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering problems view state");
      return Editor.Input_Bridge.Render_Access.Problems_View_For_Render
        (The_Editor.State);
   end Problems_View_For_Render;

   function Project_Search_For_Render
     return Editor.Project_Search.Project_Search_State
   is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering project search");
      return Editor.Input_Bridge.Render_Access.Project_Search_For_Render
        (The_Editor.State);
   end Project_Search_For_Render;

   function Active_Diagnostic_For_Render return Editor.Diagnostics.Diagnostic_Index
   is
   begin
      return Editor.Input_Bridge.Render_Access.Active_Diagnostic_For_Render
        (The_Editor.State);
   end Active_Diagnostic_For_Render;

   procedure Tick_Async_Build_Jobs is
      Result    : Editor.External_Producers.Build_Command_Result;
      Completed : Boolean := False;
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before ticking async build jobs");

      if Editor.Build_Command.Has_Queued_Public_Build_Job (The_Editor.State) then
         Completed := Editor.Build_Command.Poll_Public_Build_Run_Completion
           (The_Editor.State, Result);

         if Completed then
            Report_Info (To_String (Result.Command_Message));
         end if;

         --  Even a non-completing poll can import stdout/stderr stream snapshots
         --  from the worker-owned process handoff.  Invalidate unconditionally
         --  while a public build job is queued so idle frames can show partial
         --  output without waiting for another user command.
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Tick_Async_Build_Jobs;


   procedure Tick_Messages is
      Had_Messages : Boolean := False;
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before ticking messages");

      Had_Messages := not Editor.Messages.Is_Empty (The_Editor.State.Messages);
      Editor.Messages.Tick
        (The_Editor.State.Messages,
         (if Editor.View.Current_Time_Seconds <= 0.0 then 0
          elsif Editor.View.Current_Time_Seconds >= Duration (Natural'Last / 1000) then Natural'Last
          else Natural (Float (Editor.View.Current_Time_Seconds) * 1000.0)));
      if Had_Messages then
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Tick_Messages;

   function Get_State_For_Test return Editor.State.State_Type is
   begin
      if not Initialized then
         Editor.Instance.Init (The_Editor);
         Initialized := True;
      end if;

      return The_Editor.State;
   end Get_State_For_Test;

   procedure Set_State_For_Test (S : Editor.State.State_Type) is
   begin
      The_Editor.State := S;
      Editor.Settings.Reset;
      Editor.Line_Numbers.Reset;
      Editor.Command_Palette.Reset;
      Editor.File_Tree_View.Reset;
      Editor.Panels.Set_Current (The_Editor.State.Panels);
      Pointer_State.Reset_All;
      Editor.State.Clear_Gutter_Marker_Hover (The_Editor.State);
      Editor.Panels.End_Resize (The_Editor.State.Panels);
      Editor.Panels.Set_Current (The_Editor.State.Panels);
      Editor.Scrollbars.Reset;
      Editor.Render_Cache.Invalidate_All;
      Editor.View.Reset_Scroll;
      Initialized := True;
   end Set_State_For_Test;

end Editor.Input_Bridge;
