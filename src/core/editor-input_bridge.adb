with Editor.Instance;
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
with Editor.Executor.Buffer_Close_Commands;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.Bookmark_Commands;
with Editor.Executor.Diagnostics_Commands;
with Editor.Executor.Buffer_Switcher_Surface_Commands;
with Editor.Executor.Command_Surface_Commands;
with Editor.Executor.File_Save_Commands;
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
   Minimap_Drag_Active : Boolean := False;

   type Gutter_Line_Selection_State is record
      Active     : Boolean := False;
      Anchor_Row : Natural := 0;
   end record;

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
      case Cmd.Kind is
         when Editor.Commands.Insert_Text_Input
            | Editor.Commands.Delete_Char
            | Editor.Commands.Forward_Delete_Char
            | Editor.Commands.Delete_Previous_Character
            | Editor.Commands.Delete_Next_Character
            | Editor.Commands.Delete_Previous_Word
            | Editor.Commands.Delete_Next_Word
            | Editor.Commands.Delete_Selection_Range
            | Editor.Commands.Split_Current_Line_At_Caret =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Text_Entry_Workflow_Event;

   function Is_Text_Entry_Workflow_Command_Id
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      case Id is
         when Editor.Commands.Command_Insert_Newline
            | Editor.Commands.Command_Selection_Delete
            | Editor.Commands.Command_Char_Delete_Previous
            | Editor.Commands.Command_Char_Delete_Next
            | Editor.Commands.Command_Word_Delete_Previous
            | Editor.Commands.Command_Word_Delete_Next
            | Editor.Commands.Command_Line_Split_At_Caret =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Text_Entry_Workflow_Command_Id;

   function Resolve_Text_Entry_Focus_Target
     return Text_Entry_Focus_Target
   is
   begin
      if Pending_Confirmation_Active then
         return Text_Entry_No_Target;
      elsif Editor.Guided_Prompts.Is_Active (The_Editor.State.Guided_Prompt) then
         return Text_Entry_Guided_Prompt;
      elsif Overlay_Or_Local_Text_Input_Active then
         return Text_Entry_Overlay_Input;
      elsif Editor.Focus_Management.Editor_Text_Can_Edit (The_Editor.State) then
         return Text_Entry_Editor_Buffer;
      else
         return Text_Entry_No_Target;
      end if;
   end Resolve_Text_Entry_Focus_Target;

   function Preview_Text_Entry_Route
     (Cmd : Editor.Commands.Command) return Text_Entry_Route_Result
   is
      Focus : constant Text_Entry_Focus_Target := Resolve_Text_Entry_Focus_Target;
   begin
      if not Is_Text_Entry_Workflow_Event (Cmd) then
         return Unsupported_Text_Entry_Event;
      end if;

      if Focus = Text_Entry_Overlay_Input then
         return Routed_To_Overlay_Input;
      elsif Focus = Text_Entry_Guided_Prompt then
         return Routed_To_Guided_Prompt;
      elsif Focus /= Text_Entry_Editor_Buffer then
         return No_Editor_Text_Focus;
      elsif Editor.Buffers.Global_Active_Buffer = Editor.Buffers.No_Buffer
        and then not Editor.State.Has_Active_Buffer (The_Editor.State)
      then
         return No_Active_Buffer;
      elsif The_Editor.State.Carets.Is_Empty then
         return No_Caret_Location;
      end if;

      case Cmd.Kind is
         when Editor.Commands.Insert_Text_Input =>
            --  Retained 416 policy: an Enter/newline payload is a
            --  canonical Text Insert payload. The explicit Line Split command
            --  remains separate and is never invoked for this text payload.
            return Routed_To_Text_Insert;
         when Editor.Commands.Delete_Selection_Range =>
            return Routed_To_Selection_Delete;
         when Editor.Commands.Delete_Char
            | Editor.Commands.Delete_Previous_Character =>
            return Routed_To_Delete_Previous_Character;
         when Editor.Commands.Forward_Delete_Char
            | Editor.Commands.Delete_Next_Character =>
            return Routed_To_Delete_Next_Character;
         when Editor.Commands.Delete_Previous_Word =>
            return Routed_To_Delete_Previous_Word;
         when Editor.Commands.Delete_Next_Word =>
            return Routed_To_Delete_Next_Word;
         when Editor.Commands.Split_Current_Line_At_Caret =>
            return Routed_To_Line_Split;
         when others =>
            return Unsupported_Text_Entry_Event;
      end case;
   end Preview_Text_Entry_Route;

   function Canonical_Text_Entry_Command
     (Cmd : Editor.Commands.Command) return Editor.Commands.Command
   is
      Result : constant Text_Entry_Route_Result := Preview_Text_Entry_Route (Cmd);
      Routed : Editor.Commands.Command := Cmd;
   begin
      case Result is
         when Routed_To_Text_Insert =>
            Routed.Kind := Editor.Commands.Insert_Text_Input;
            if not Routed.Has_Position
              and then not The_Editor.State.Carets.Is_Empty
            then
               Routed.Pos :=
                 The_Editor.State.Carets
                   (The_Editor.State.Carets.First_Index).Pos;
               Routed.Has_Position := True;
            end if;
            if Cmd.Code /= Wide_Wide_Character'Val (0)
              and then
                (Length (Routed.Text) = 0
                 or else To_String (Routed.Text) = String'(1 => ASCII.NUL))
            then
               Routed.Text :=
                 To_Unbounded_String (Editor.UTF8.Encode_UTF8 (Cmd.Code));
            elsif Length (Routed.Text) = 0 then
               if Cmd.Ch /= ASCII.NUL then
                  Routed.Text := To_Unbounded_String (String'(1 => Cmd.Ch));
               else
                  Routed.Text := Null_Unbounded_String;
               end if;
            end if;
         when Routed_To_Selection_Delete =>
            Routed.Kind := Editor.Commands.Delete_Selection_Range;
         when Routed_To_Delete_Previous_Character =>
            Routed.Kind := Editor.Commands.Delete_Previous_Character;
         when Routed_To_Delete_Next_Character =>
            Routed.Kind := Editor.Commands.Delete_Next_Character;
         when Routed_To_Delete_Previous_Word =>
            Routed.Kind := Editor.Commands.Delete_Previous_Word;
         when Routed_To_Delete_Next_Word =>
            Routed.Kind := Editor.Commands.Delete_Next_Word;
         when Routed_To_Line_Split =>
            Routed.Kind := Editor.Commands.Split_Current_Line_At_Caret;
         when others =>
            null;
      end case;
      return Routed;
   end Canonical_Text_Entry_Command;

   function Preview_Text_Entry_Command_Id
     (Cmd : Editor.Commands.Command) return Editor.Commands.Command_Id
   is
   begin
      case Preview_Text_Entry_Route (Cmd) is
         when Routed_To_Selection_Delete =>
            return Editor.Commands.Command_Selection_Delete;
         when Routed_To_Delete_Previous_Character =>
            return Editor.Commands.Command_Char_Delete_Previous;
         when Routed_To_Delete_Next_Character =>
            return Editor.Commands.Command_Char_Delete_Next;
         when Routed_To_Delete_Previous_Word =>
            return Editor.Commands.Command_Word_Delete_Previous;
         when Routed_To_Delete_Next_Word =>
            return Editor.Commands.Command_Word_Delete_Next;
         when Routed_To_Line_Split =>
            return Editor.Commands.Command_Line_Split_At_Caret;
         when others =>
            return Editor.Commands.No_Command;
      end case;
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

   Gutter_Line_Selection : Gutter_Line_Selection_State;

   type Scrollbar_Drag_State is record
      Active      : Boolean := False;
      Orientation : Editor.Scrollbars.Scrollbar_Orientation :=
        Editor.Scrollbars.Vertical_Scrollbar;
      Drag_Offset : Natural := 0;
   end record;

   Scrollbar_Drag : Scrollbar_Drag_State;

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

   procedure Start_Guided_Prompt_For_Command
     (Id : Editor.Commands.Command_Id) is
   begin
      case Id is
         when Editor.Commands.Command_Open_Project =>
            Editor.Guided_Prompts.Start
              (The_Editor.State.Guided_Prompt,
               Editor.Guided_Prompts.Project_Open_Prompt,
               Id,
               "Open Project",
               "Enter project path.",
               "Project",
               Previous_Focus => "editor",
               Confirm_Label => "Open",
               Lifecycle_Command => True);
            Report_Info ("Enter project path.");
         when Editor.Commands.Command_Switch_Project =>
            Editor.Guided_Prompts.Start
              (The_Editor.State.Guided_Prompt,
               Editor.Guided_Prompts.Project_Switch_Prompt,
               Id,
               "Switch Project",
               "Enter target project path.",
               "Project",
               Previous_Focus => "editor",
               Confirm_Label => "Switch",
               Lifecycle_Command => True);
            Report_Info ("Enter project path.");
         when Editor.Commands.Command_Restore_Workspace_State =>
            Editor.Guided_Prompts.Start
              (The_Editor.State.Guided_Prompt,
               Editor.Guided_Prompts.Workspace_Load_Prompt,
               Id,
               "Load Workspace",
               "Enter workspace path or reference.",
               "Workspace",
               Confirm_Label => "Load",
               Lifecycle_Command => True);
            Report_Info ("Enter workspace path.");
         when Editor.Commands.Command_Save_Workspace_State =>
            Editor.Guided_Prompts.Start
              (The_Editor.State.Guided_Prompt,
               Editor.Guided_Prompts.Workspace_Save_Prompt,
               Id,
               "Save Workspace",
               "Enter workspace path or confirm the default workspace target.",
               "Workspace",
               Confirm_Label => "Save");
            Report_Info ("Enter workspace path.");
         when Editor.Commands.Command_Run_Project_Search
            | Editor.Commands.Command_Run_Project_Search_From_Bar =>
            Editor.Guided_Prompts.Start
              (The_Editor.State.Guided_Prompt,
               Editor.Guided_Prompts.Search_Query_Prompt,
               Id,
               "Project Search",
               "Enter search text.",
               "Project Search",
               Confirm_Label => "Search");
            Report_Info ("Enter search text.");
         when Editor.Commands.Command_Project_Search_Replace_Preview =>
            Editor.Guided_Prompts.Start
              (The_Editor.State.Guided_Prompt,
               Editor.Guided_Prompts.Replace_Text_Prompt,
               Id,
               "Replacement Text",
               "Enter replacement text for the current project search.",
               "Project Search Replace",
               Confirm_Label => "Preview");
            Report_Info ("Enter replacement text.");
         when Editor.Commands.Command_Keybindings_Assign_Selected =>
            Editor.Guided_Prompts.Start
              (The_Editor.State.Guided_Prompt,
               Editor.Guided_Prompts.Keybinding_Capture_Prompt,
               Id,
               "Assign Keybinding",
               "Press one key chord to assign to the selected bindable command.",
               "Keybindings",
               Confirm_Label => "Assign");
            Report_Info ("Press keybinding chord.");
         when Editor.Commands.Command_File_Tree_Create_File =>
            Editor.Guided_Prompts.Start
              (The_Editor.State.Guided_Prompt,
               Editor.Guided_Prompts.File_Tree_Create_File_Prompt,
               Id,
               "Create File",
               "Enter a file name or project-relative path inside the active project.",
               "File Tree",
               Confirm_Label => "Create");
            Report_Info ("Enter file name.");
         when Editor.Commands.Command_File_Tree_Create_Directory =>
            Editor.Guided_Prompts.Start
              (The_Editor.State.Guided_Prompt,
               Editor.Guided_Prompts.File_Tree_Create_Directory_Prompt,
               Id,
               "Create Directory",
               "Enter a directory name or project-relative path inside the active project.",
               "File Tree",
               Confirm_Label => "Create");
            Report_Info ("Enter directory name.");
         when Editor.Commands.Command_File_Tree_Rename_Selected =>
            Editor.Guided_Prompts.Start
              (The_Editor.State.Guided_Prompt,
               Editor.Guided_Prompts.File_Tree_Rename_Prompt,
               Id,
               "Rename File or Directory",
               "Enter a new name for the selected file or directory.",
               "File Tree",
               Confirm_Label => "Rename");
            declare
               Selected_Row : constant Natural :=
                 Editor.File_Tree_View.Selected_Row_Index
                   (The_Editor.State.File_Tree_View);
               Found       : Boolean := False;
               Node_Id     : Editor.File_Tree.File_Tree_Node_Id :=
                 Editor.File_Tree.No_File_Tree_Node;
               Summary     : Editor.File_Tree.File_Tree_Node_Summary;
            begin
               --  completeness: rename is a prompt-driven workflow,
               --  but it should still present the current leaf name as the
               --  editable starting point when a real selected row is known.
               --  This remains transient prompt text; no path/name payload is
               --  persisted or attached to keybindings/Command Palette rows.
               if Selected_Row > 0 then
                  Node_Id := Editor.File_Tree_View.Node_For_Row
                    (The_Editor.State.File_Tree, Selected_Row, Found);
               end if;

               if Found and then Node_Id /= Editor.File_Tree.No_File_Tree_Node then
                  Summary := Editor.File_Tree.Node
                    (The_Editor.State.File_Tree, Node_Id);
                  Editor.Guided_Prompts.Update_Input
                    (The_Editor.State.Guided_Prompt, To_String (Summary.Name));
               end if;
            end;
            Report_Info ("Enter new name.");
         when Editor.Commands.Command_Rename_Symbol_Preview
            | Editor.Commands.Command_Rename_Symbol_Apply =>
            declare
               Symbol : constant String :=
                 Editor.Executor.Current_Semantic_Symbol_Name (The_Editor.State);
            begin
               Editor.Guided_Prompts.Start
                 (The_Editor.State.Guided_Prompt,
                  Editor.Guided_Prompts.Semantic_Rename_Prompt,
                  Id,
                  "Rename Symbol",
                  "Enter the new Ada identifier for the selected symbol.",
                  "Ada Semantics",
                  Confirm_Label =>
                    (if Id = Editor.Commands.Command_Rename_Symbol_Apply
                     then "Rename"
                     else "Preview"));
               if Symbol'Length > 0 then
                  Editor.Guided_Prompts.Update_Input
                    (The_Editor.State.Guided_Prompt, Symbol);
               end if;
            end;
            Report_Info ("Enter new symbol name.");
         when Editor.Commands.Command_File_Tree_Delete_Selected =>
            declare
               Selected_Row : constant Natural :=
                 Editor.File_Tree_View.Selected_Row_Index
                   (The_Editor.State.File_Tree_View);
               Found       : Boolean := False;
               Node_Id     : Editor.File_Tree.File_Tree_Node_Id :=
                 Editor.File_Tree.No_File_Tree_Node;
               Summary     : Editor.File_Tree.File_Tree_Node_Summary;
               Kind_Label  : Unbounded_String := To_Unbounded_String ("item");
               Path_Label  : Unbounded_String := To_Unbounded_String ("selected File Tree item");
               Impact      : Unbounded_String := Null_Unbounded_String;
            begin
               if Selected_Row > 0 then
                  Node_Id := Editor.File_Tree_View.Node_For_Row
                    (The_Editor.State.File_Tree, Selected_Row, Found);
               end if;

               if Found and then Node_Id /= Editor.File_Tree.No_File_Tree_Node then
                  Summary := Editor.File_Tree.Node
                    (The_Editor.State.File_Tree, Node_Id);
                  Kind_Label := To_Unbounded_String
                    (Editor.File_Tree.Kind_Label (Summary.Kind));
                  Path_Label := Summary.Absolute_Path;
                  if Editor.Buffers.Global_Has_Dirty_File_Under_Path
                    (To_String (Summary.Absolute_Path))
                  then
                     Impact := To_Unbounded_String
                       (" Dirty open buffer content will block deletion.");
                  elsif Editor.Buffers.Global_Has_File_Under_Path
                    (To_String (Summary.Absolute_Path))
                  then
                     Impact := To_Unbounded_String
                       (" Clean open buffers under this target will be closed after successful deletion.");
                  end if;
               end if;

               Editor.Guided_Prompts.Start
                 (The_Editor.State.Guided_Prompt,
                  Editor.Guided_Prompts.Confirmation_Prompt,
                  Id,
                  "Delete File or Directory",
                  "Confirm deletion of the selected " & To_String (Kind_Label) & ": " &
                    To_String (Path_Label) & "." &
                    To_String (Impact),
                  "File Tree",
                  Confirm_Label => "Delete",
                  Requires_Confirmation => True,
                  Destructive => True,
                  Affected_Count => 1);
               Report_Info ("Confirmation required.");
            end;
         when Editor.Commands.Command_Delete_Buffer_File
            | Editor.Commands.Command_Revert_Active_Buffer
            | Editor.Commands.Command_Project_Search_Replace_All_Included
            | Editor.Commands.Command_Reset_Settings_To_Defaults
            | Editor.Commands.Command_Configuration_Reset_Settings
            | Editor.Commands.Command_Configuration_Reset_Keybindings
            | Editor.Commands.Command_Configuration_Reset_Workspace
            | Editor.Commands.Command_Configuration_Reset_Recent_Projects
            | Editor.Commands.Command_Configuration_Reset_All
            | Editor.Commands.Command_Keybindings_Reset_To_Defaults
            | Editor.Commands.Command_Clear_Workspace_State
            | Editor.Commands.Command_Close_Project
            | Editor.Commands.Command_Clear_Project
            | Editor.Commands.Command_Clear_Recent_Projects
            | Editor.Commands.Command_Close_All_Buffers
            | Editor.Commands.Command_Close_All_Clean_Buffers
            | Editor.Commands.Command_Close_Other_Buffers
            | Editor.Commands.Command_Diagnostics_Clear =>
            Editor.Guided_Prompts.Start
              (The_Editor.State.Guided_Prompt,
               Editor.Guided_Prompts.Confirmation_Prompt,
               Id,
               "Confirm Action",
               "Confirm the pending action.",
               "Confirmation",
               Confirm_Label => "Confirm",
               Requires_Confirmation => True,
               Destructive => True,
               Lifecycle_Command => True,
               Affected_Count => 1);
            Report_Info ("Confirmation required.");
         when others =>
            null;
      end case;
      Editor.Render_Cache.Invalidate_All;
   end Start_Guided_Prompt_For_Command;

   function Command_Starts_Guided_Prompt
     (Id : Editor.Commands.Command_Id) return Boolean is
   begin
      case Id is
         when Editor.Commands.Command_Open_Project
            | Editor.Commands.Command_Switch_Project
            | Editor.Commands.Command_Restore_Workspace_State
            | Editor.Commands.Command_Save_Workspace_State
            | Editor.Commands.Command_Run_Project_Search
            | Editor.Commands.Command_Run_Project_Search_From_Bar
            | Editor.Commands.Command_Project_Search_Replace_Preview
            | Editor.Commands.Command_Keybindings_Assign_Selected
            | Editor.Commands.Command_File_Tree_Create_File
            | Editor.Commands.Command_File_Tree_Create_Directory
            | Editor.Commands.Command_File_Tree_Rename_Selected
            | Editor.Commands.Command_Rename_Symbol_Preview
            | Editor.Commands.Command_Rename_Symbol_Apply
            | Editor.Commands.Command_Delete_Buffer_File
            | Editor.Commands.Command_Revert_Active_Buffer
            | Editor.Commands.Command_File_Tree_Delete_Selected
            | Editor.Commands.Command_Project_Search_Replace_All_Included
            | Editor.Commands.Command_Reset_Settings_To_Defaults
            | Editor.Commands.Command_Configuration_Reset_Settings
            | Editor.Commands.Command_Configuration_Reset_Keybindings
            | Editor.Commands.Command_Configuration_Reset_Workspace
            | Editor.Commands.Command_Configuration_Reset_Recent_Projects
            | Editor.Commands.Command_Configuration_Reset_All
            | Editor.Commands.Command_Keybindings_Reset_To_Defaults
            | Editor.Commands.Command_Clear_Workspace_State
            | Editor.Commands.Command_Close_Project
            | Editor.Commands.Command_Clear_Project
            | Editor.Commands.Command_Clear_Recent_Projects
            | Editor.Commands.Command_Close_All_Buffers
            | Editor.Commands.Command_Close_All_Clean_Buffers
            | Editor.Commands.Command_Close_Other_Buffers
            | Editor.Commands.Command_Diagnostics_Clear =>
            return True;
         when others =>
            return False;
      end case;
   end Command_Starts_Guided_Prompt;

   function Command_Starts_Confirmation_Prompt
     (Id : Editor.Commands.Command_Id) return Boolean is
   begin
      case Id is
         when Editor.Commands.Command_Delete_Buffer_File
            | Editor.Commands.Command_Revert_Active_Buffer
            | Editor.Commands.Command_File_Tree_Delete_Selected
            | Editor.Commands.Command_Project_Search_Replace_All_Included
            | Editor.Commands.Command_Reset_Settings_To_Defaults
            | Editor.Commands.Command_Configuration_Reset_Settings
            | Editor.Commands.Command_Configuration_Reset_Keybindings
            | Editor.Commands.Command_Configuration_Reset_Workspace
            | Editor.Commands.Command_Configuration_Reset_Recent_Projects
            | Editor.Commands.Command_Configuration_Reset_All
            | Editor.Commands.Command_Keybindings_Reset_To_Defaults
            | Editor.Commands.Command_Clear_Workspace_State
            | Editor.Commands.Command_Close_Project
            | Editor.Commands.Command_Clear_Project
            | Editor.Commands.Command_Clear_Recent_Projects
            | Editor.Commands.Command_Close_Active_Buffer
            | Editor.Commands.Command_Close_All_Buffers
            | Editor.Commands.Command_Close_All_Clean_Buffers
            | Editor.Commands.Command_Close_Other_Buffers
            | Editor.Commands.Command_Diagnostics_Clear =>
            return True;
         when others =>
            return False;
      end case;
   end Command_Starts_Confirmation_Prompt;

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
      --  completeness pass: keybinding capture has its own typed
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
            --  completeness pass 5: a guided prompt is modal for
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
      elsif Command_Starts_Guided_Prompt (Id) then
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
         if Command_Starts_Confirmation_Prompt (Id)
           or else Id = Editor.Commands.Command_File_Tree_Create_File
           or else Id = Editor.Commands.Command_File_Tree_Create_Directory
           or else Id = Editor.Commands.Command_File_Tree_Rename_Selected
           or else Id = Editor.Commands.Command_Rename_Symbol_Preview
           or else Id = Editor.Commands.Command_Rename_Symbol_Apply
         then
            declare
               Availability : constant Editor.Commands.Command_Availability :=
                 Editor.Executor.Command_Availability
                   (The_Editor.State,
                    (if Id = Editor.Commands.Command_Rename_Symbol_Apply
                     then Editor.Commands.Command_Rename_Symbol_Preview
                     else Id));
            begin
               if not Editor.Commands.Is_Available (Availability) then
                  Report_Info (Editor.Commands.Unavailable_Reason (Availability));
                  Editor.Render_Cache.Invalidate_All;
                  return;
               end if;
            end;
         end if;
         Start_Guided_Prompt_For_Command (Id);
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

      if Pending_Confirmation_Active
        and then Editor.Focus_Management.Command_Is_Conflicting_While_Pending (Id)
      then
         Report_Info ("Command unavailable while confirmation is pending");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      if not Editor.Focus_Management.Command_May_Run_In_Current_Focus
        (The_Editor.State, Id)
      then
         Report_Info ("Command unavailable for current focus");
         Editor.Render_Cache.Invalidate_All;
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

      declare
         Availability : constant Editor.Commands.Command_Availability :=
           Editor.Executor.Command_Availability (The_Editor.State, Id);
      begin
         if not Editor.Commands.Is_Available (Availability) then
            Report_Info (Editor.Commands.Unavailable_Reason (Availability));
            Editor.Render_Cache.Invalidate_All;
            return;
         end if;
      end;

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

   function Handle_Command_Palette
     (Cmd : Editor.Commands.Command) return Boolean
   is
      procedure Accept_Selected_Palette_Command
      is
         Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
         Visible_Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
         Preferred  : constant Editor.Commands.Command_Id :=
           Editor.Command_Palette.Current.Selected_Command_Id;
         Still_Visible : Boolean := Preferred = Editor.Commands.No_Command;
      begin
         Editor.Executor.Command_Palette_Candidates
           (The_Editor.State, Candidates);
         Editor.Command_Palette.Visible_Candidates (Candidates, Visible_Candidates);

         if Preferred /= Editor.Commands.No_Command then
            for Candidate of Visible_Candidates loop
               if Candidate.Id = Preferred then
                  Still_Visible := True;
                  exit;
               end if;
            end loop;
         end if;

         if not Still_Visible then
            Report_Warning ("Selected command is no longer visible");
            Editor.Command_Palette.Reconcile_Selection (Visible_Candidates);
            Editor.Render_Cache.Invalidate_All;
            return;
         end if;

         Editor.Command_Palette.Reconcile_Selection (Visible_Candidates);

         declare
            Selected_Index : constant Natural :=
              Editor.Command_Palette.Current.Selected_Item;
         begin
            if Visible_Candidates.Length = 0
              or else Selected_Index >= Natural (Visible_Candidates.Length)
            then
               Report_Warning ("No command selected");
               Editor.Render_Cache.Invalidate_All;
               return;
            end if;

            declare
               Candidate : constant Editor.Commands.Command_Palette_Candidate :=
                 Visible_Candidates.Element (Selected_Index);
            begin
               if not Candidate.Available then
                  declare
                     Reason : constant String :=
                       (if Length (Candidate.Reason) > 0
                        then To_String (Candidate.Reason)
                        else "Command not available here");
                  begin
                     Report_Info (Reason);
                  end;
                  Editor.Render_Cache.Invalidate_All;
                  return;
               end if;

               if Candidate.Id = Editor.Commands.Command_Palette_Show_Command_Help then
                  Execute_Command_Id (Candidate.Id);
                  Editor.Executor.Command_Palette_Candidates
                    (The_Editor.State, Candidates);
                  Editor.Command_Palette.Visible_Candidates
                    (Candidates, Visible_Candidates);
                  Editor.Command_Palette.Reconcile_Selection
                    (Visible_Candidates, Preferred_Command => Candidate.Id);
                  Editor.Render_Cache.Invalidate_All;
               else
                  Editor.Executor.Dismiss_Active_Overlay
                    (The_Editor.State, Editor.Overlay_Focus.Dismiss_Accept);
                  Execute_Command_Id (Candidate.Id);
               end if;
            end;
         end;
      end Accept_Selected_Palette_Command;
   begin
      if Cmd.Kind = Editor.Commands.Open_Command_Palette then
         Execute_Command_Id (Editor.Commands.Command_Open_Command_Palette);
         return True;
      end if;

      if not Editor.Overlay_Focus.Is_Active
        (The_Editor.State.Overlay_Focus,
         Editor.Overlay_Focus.Command_Palette_Overlay)
      then
         return False;
      end if;

      case Cmd.Kind is
         when Editor.Commands.Insert_Text_Input =>
            if Cmd.Ctrl and then (Cmd.Ch = 'a' or else Cmd.Ch = 'A') then
               Editor.Command_Palette.Select_All;
            elsif Cmd.Ch = ASCII.LF or else Cmd.Ch = ASCII.CR then
               Accept_Selected_Palette_Command;
            elsif Length (Cmd.Text) > 0 then
               Editor.Command_Palette.Insert_Text (To_String (Cmd.Text));
            else
               Editor.Command_Palette.Append_Character (Cmd.Ch);
            end if;

         when Editor.Commands.Delete_Char
            | Editor.Commands.Delete_Previous_Character =>
            Editor.Command_Palette.Backspace;

         when Editor.Commands.Forward_Delete_Char
            | Editor.Commands.Delete_Next_Character =>
            Editor.Command_Palette.Delete_Forward;

         when Editor.Commands.Paste_Text =>
            Editor.Command_Palette.Insert_Text (To_String (Cmd.Text));

         when Editor.Commands.Paste_Clipboard =>
            Editor.Command_Palette.Insert_Text
              (To_String (Editor.Executor.Clipboard.Text_For_Local_Input));

         when Editor.Commands.Move_Left =>
            Editor.Command_Palette.Move_Cursor_Left;

         when Editor.Commands.Move_Right =>
            Editor.Command_Palette.Move_Cursor_Right;

         when Editor.Commands.Move_Home | Editor.Commands.Move_Line_Start =>
            Editor.Command_Palette.Move_Cursor_Start;

         when Editor.Commands.Move_End | Editor.Commands.Move_Line_End =>
            Editor.Command_Palette.Move_Cursor_End;

         when Editor.Commands.Move_Up =>
            declare
               Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
            begin
               Editor.Executor.Command_Palette_Candidates
                 (The_Editor.State, Candidates);
               Editor.Command_Palette.Move_Selection_By_Candidates
                 (Candidates, -1);
            end;

         when Editor.Commands.Move_Down =>
            declare
               Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
            begin
               Editor.Executor.Command_Palette_Candidates
                 (The_Editor.State, Candidates);
               Editor.Command_Palette.Move_Selection_By_Candidates
                 (Candidates, 1);
            end;

         when Editor.Commands.Palette_Accept =>
            Accept_Selected_Palette_Command;

         when Editor.Commands.Palette_Show_Command_Help =>
            Execute_Command_Id (Editor.Commands.Command_Palette_Show_Command_Help);

         when Editor.Commands.Palette_Cancel
            | Editor.Commands.Clear_Extra_Carets =>
            declare
               Owner_Before : constant Editor.Focus_Management.Focus_Owner :=
                 Editor.Focus_Management.Effective_Focus_Owner
                   (The_Editor.State);
            begin
               Editor.Executor.Dismiss_Active_Overlay
                 (The_Editor.State, Editor.Overlay_Focus.Dismiss_Escape);
               Editor.Focus_Management.Apply_Command_Focus_Result
                 (The_Editor.State, Editor.Commands.Command_Cancel, Owner_Before);
            end;

         when Editor.Commands.Move_To_Point =>
            declare
               Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
               Margin : constant Natural := Editor.Theme.Palette_Margin;
               Max_W  : constant Natural := Editor.Theme.Palette_Max_Width;
               Width  : Natural := Max_W;
               X      : Integer := 0;
               Y      : Integer := 0;
               Text_X : Integer := 0;
               Field_Cols : Natural := 1;
               Click_X : constant Integer := Integer (Cmd.Click_X);
               Click_Y : constant Integer := Integer (Cmd.Click_Y);
            begin
               if Editor.View.Viewport_Width <= Margin * 2 then
                  Width := Editor.View.Viewport_Width;
               else
                  Width := Natural'Min (Max_W, Editor.View.Viewport_Width - Margin * 2);
               end if;

               X := Layout.Origin_X
                 + Integer ((Editor.View.Viewport_Width - Width) / 2);
               Y := Layout.Origin_Y
                 + Integer
                     (Float'Max
                        (Editor.Theme.Palette_Top_Min_Offset,
                         Float (Editor.View.Viewport_Height)
                         * Editor.Theme.Palette_Top_Fraction));
               Text_X := X + Integer (Editor.Theme.Palette_Text_Padding_X);
               Field_Cols :=
                 (if Width > Natural (2.0 * Editor.Theme.Palette_Text_Padding_X)
                              + 2 * Editor.Layout.Cell_W
                  then (Width - Natural (2.0 * Editor.Theme.Palette_Text_Padding_X))
                       / Editor.Layout.Cell_W - 2
                  else 1);

               if Click_X >= Text_X + Integer (2 * Editor.Layout.Cell_W)
                 and then Click_X < X + Integer (Width)
                 and then Click_Y >= Y + Integer (Editor.Theme.Palette_Text_Padding_Y)
                 and then Click_Y < Y + Integer (Editor.Theme.Palette_Text_Padding_Y)
                                      + Integer (Editor.Layout.Cell_H)
               then
                  Editor.Command_Palette.Set_Cursor_From_Visible_Column
                    (Natural ((Click_X - Text_X
                               - Integer (2 * Editor.Layout.Cell_W))
                              / Integer (Editor.Layout.Cell_W)),
                     Field_Cols);
               else
                  Editor.Executor.Dismiss_Active_Overlay
                    (The_Editor.State, Editor.Overlay_Focus.Dismiss_Outside_Click);
               end if;
            end;

         when Editor.Commands.Pointer_Hover =>
            null;

         when others =>
            null;
      end case;

      Editor.Render_Cache.Invalidate_All;
      return True;
   end Handle_Command_Palette;


   function Handle_Quick_Open
     (Cmd : Editor.Commands.Command) return Boolean
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Message_Body   : constant Editor.Layout.Rect :=
        Editor.Layout.Editor_Body_Rect
          (Layout, Editor.View.Viewport_Width, Editor.View.Viewport_Height);
      Config : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Hit    : Editor.Quick_Open.Quick_Open_Hit_Result;
      Cmd2   : Editor.Commands.Command;
   begin
      if Cmd.Kind = Editor.Commands.Open_Quick_Open then
         Execute_Command_Id (Editor.Commands.Command_Open_Quick_Open);
         return True;
      elsif Cmd.Kind = Editor.Commands.Toggle_Quick_Open then
         Execute_Command_Id (Editor.Commands.Command_Toggle_Quick_Open);
         return True;
      end if;

      if not Editor.Overlay_Focus.Is_Active
        (The_Editor.State.Overlay_Focus,
         Editor.Overlay_Focus.Quick_Open_Overlay)
      then
         return False;
      end if;

      case Cmd.Kind is
         when Editor.Commands.Insert_Text_Input =>
            if Cmd.Ctrl and then (Cmd.Ch = 'a' or else Cmd.Ch = 'A') then
               Editor.Quick_Open.Select_All (The_Editor.State.Quick_Open);
               Editor.Render_Cache.Invalidate_All;
            elsif Cmd.Ch = ASCII.LF or else Cmd.Ch = ASCII.CR then
               Execute_Command_Id (Editor.Commands.Command_Accept_Quick_Open);
            elsif Cmd.Ch = ASCII.HT then
               if Cmd.Shift then
                  Execute_Command_Id (Editor.Commands.Command_Quick_Open_Previous_Result);
               else
                  Execute_Command_Id (Editor.Commands.Command_Quick_Open_Next_Result);
               end if;
            elsif Length (Cmd.Text) > 0 then
               Cmd2.Kind := Editor.Commands.Quick_Open_Insert_Text;
               Cmd2.Text := Cmd.Text;
               Editor.Instance.Execute (The_Editor, Cmd2);
            elsif Cmd.Ch /= ASCII.NUL then
               Cmd2.Kind := Editor.Commands.Quick_Open_Insert_Text;
               Cmd2.Text := To_Unbounded_String (String'(1 => Cmd.Ch));
               Editor.Instance.Execute (The_Editor, Cmd2);
            end if;
            return True;

         when Editor.Commands.Delete_Char
            | Editor.Commands.Delete_Previous_Character =>
            Cmd2.Kind := Editor.Commands.Quick_Open_Backspace;
            Editor.Instance.Execute (The_Editor, Cmd2);
            return True;

         when Editor.Commands.Forward_Delete_Char
            | Editor.Commands.Delete_Next_Character =>
            Cmd2.Kind := Editor.Commands.Quick_Open_Delete_Forward;
            Editor.Instance.Execute (The_Editor, Cmd2);
            return True;

         when Editor.Commands.Paste_Text =>
            Cmd2.Kind := Editor.Commands.Quick_Open_Insert_Text;
            Cmd2.Text := Cmd.Text;
            Editor.Instance.Execute (The_Editor, Cmd2);
            return True;

         when Editor.Commands.Paste_Clipboard =>
            Cmd2.Kind := Editor.Commands.Quick_Open_Insert_Text;
            Cmd2.Text :=
              Editor.Executor.Clipboard.Text_For_Local_Input;
            Editor.Instance.Execute (The_Editor, Cmd2);
            return True;

         when Editor.Commands.Move_Left =>
            Editor.Quick_Open.Move_Cursor_Left (The_Editor.State.Quick_Open);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_Right =>
            Editor.Quick_Open.Move_Cursor_Right (The_Editor.State.Quick_Open);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_Home | Editor.Commands.Move_Line_Start =>
            Editor.Quick_Open.Move_Cursor_Start (The_Editor.State.Quick_Open);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_End | Editor.Commands.Move_Line_End =>
            Editor.Quick_Open.Move_Cursor_End (The_Editor.State.Quick_Open);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_Down | Editor.Commands.Quick_Open_Next_Result =>
            Execute_Command_Id (Editor.Commands.Command_Quick_Open_Next_Result);
            return True;

         when Editor.Commands.Move_Up | Editor.Commands.Quick_Open_Previous_Result =>
            Execute_Command_Id (Editor.Commands.Command_Quick_Open_Previous_Result);
            return True;

         when Editor.Commands.Palette_Accept | Editor.Commands.Accept_Quick_Open =>
            Execute_Command_Id (Editor.Commands.Command_Accept_Quick_Open);
            return True;

         when Editor.Commands.Quick_Open_Query_Set =>
            Editor.Executor.Command_Surface_Commands.Execute_Quick_Open_Set_Query
              (The_Editor.State, To_String (Cmd.Text));
            return True;

         when Editor.Commands.Quick_Open_Query_Clear =>
            Execute_Command_Id (Editor.Commands.Command_Quick_Open_Query_Clear);
            return True;

         when Editor.Commands.Quick_Open_Kind_Next =>
            Execute_Command_Id (Editor.Commands.Command_Quick_Open_Kind_Next);
            return True;

         when Editor.Commands.Quick_Open_Kind_Previous =>
            Execute_Command_Id (Editor.Commands.Command_Quick_Open_Kind_Previous);
            return True;

         when Editor.Commands.Quick_Open_Kind_Clear =>
            Execute_Command_Id (Editor.Commands.Command_Quick_Open_Kind_Clear);
            return True;

         when Editor.Commands.Quick_Open_Scope_Set =>
            Editor.Executor.Command_Surface_Commands.Execute_Quick_Open_Scope_Set
              (The_Editor.State, To_String (Cmd.Text));
            return True;

         when Editor.Commands.Quick_Open_Scope_Clear =>
            Execute_Command_Id (Editor.Commands.Command_Quick_Open_Scope_Clear);
            return True;

         when Editor.Commands.Quick_Open_Scope_From_Selected =>
            Execute_Command_Id (Editor.Commands.Command_Quick_Open_Scope_From_Selected);
            return True;

         when Editor.Commands.Quick_Open_Scope_Parent =>
            Execute_Command_Id (Editor.Commands.Command_Quick_Open_Scope_Parent);
            return True;

         when Editor.Commands.Quick_Open_Reveal_Active =>
            Execute_Command_Id (Editor.Commands.Command_Quick_Open_Reveal_Active);
            return True;

         when Editor.Commands.Quick_Open_Scope_Active_Directory =>
            Execute_Command_Id (Editor.Commands.Command_Quick_Open_Scope_Active_Directory);
            return True;

         when Editor.Commands.Quick_Open_Create_From_Query =>
            Execute_Command_Id (Editor.Commands.Command_Quick_Open_Create_From_Query);
            return True;

         when Editor.Commands.Quick_Open_Create_With_Parents_From_Query =>
            Execute_Command_Id (Editor.Commands.Command_Quick_Open_Create_With_Parents_From_Query);
            return True;

         when Editor.Commands.Quick_Open_Priority_Toggle =>
            Execute_Command_Id (Editor.Commands.Command_Quick_Open_Priority_Toggle);
            return True;

         when Editor.Commands.Quick_Open_Priority_Clear =>
            Execute_Command_Id (Editor.Commands.Command_Quick_Open_Priority_Clear);
            return True;

         when Editor.Commands.First_Project_Search_Result =>
            Execute_Command_Id (Editor.Commands.Command_First_Project_Search_Result);
            return True;

         when Editor.Commands.Last_Project_Search_Result =>
            Execute_Command_Id (Editor.Commands.Command_Last_Project_Search_Result);
            return True;

         when Editor.Commands.Reveal_Active_Project_Search_Result =>
            Execute_Command_Id (Editor.Commands.Command_Reveal_Active_Project_Search_Result);
            return True;

         when Editor.Commands.Project_Search_Scope_Selected_Directory =>
            Execute_Command_Id (Editor.Commands.Command_Project_Search_Scope_Selected_Directory);
            return True;

         when Editor.Commands.Clear_Extra_Carets
            | Editor.Commands.Palette_Cancel
            | Editor.Commands.Close_Quick_Open =>
            Execute_Command_Id (Editor.Commands.Command_Close_Quick_Open);
            return True;

         when Editor.Commands.Move_To_Point =>
            Hit := Editor.Quick_Open.Hit_Test
              (Message_Body, Config, The_Editor.State.Quick_Open,
               Integer (Cmd.Click_X), Integer (Cmd.Click_Y),
               Editor.Layout.Cell_W, Editor.Layout.Cell_H);
            case Hit.Zone is
               when Editor.Quick_Open.Outside_Quick_Open =>
                  Execute_Command_Id (Editor.Commands.Command_Close_Quick_Open);
               when Editor.Quick_Open.Quick_Open_Query_Field_Zone =>
                  declare
                     G : constant Editor.Layout.Rect :=
                       Editor.Quick_Open.Geometry
                         (Message_Body, Config, Editor.Layout.Cell_W, Editor.Layout.Cell_H);
                     Text_Start : constant Integer :=
                       G.X + Integer ((Config.Result_Padding_Columns + 1)
                                      * Editor.Layout.Cell_W);
                     Text_Cols : constant Natural :=
                       (if G.Width / Editor.Layout.Cell_W > 2
                        then G.Width / Editor.Layout.Cell_W - 2 else 1);
                     Visible_Column : constant Natural :=
                       (if Integer (Cmd.Click_X) <= Text_Start then 0
                        else Natural ((Integer (Cmd.Click_X) - Text_Start)
                                      / Integer (Editor.Layout.Cell_W)));
                  begin
                     Editor.Quick_Open.Set_Cursor_From_Visible_Column
                       (The_Editor.State.Quick_Open, Visible_Column, Text_Cols);
                  end;
               when Editor.Quick_Open.Quick_Open_Result_Row_Zone =>
                  while Editor.Quick_Open.Selected_Result_Index (The_Editor.State.Quick_Open) /= Hit.Result_Index loop
                     Execute_Command_Id (Editor.Commands.Command_Quick_Open_Next_Result);
                     exit when Editor.Quick_Open.Result_Count (The_Editor.State.Quick_Open) = 0;
                  end loop;
               when others =>
                  null;
            end case;
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Pointer_Hover =>
            Hit := Editor.Quick_Open.Hit_Test
              (Message_Body, Config, The_Editor.State.Quick_Open,
               Integer (Cmd.Click_X), Integer (Cmd.Click_Y),
               Editor.Layout.Cell_W, Editor.Layout.Cell_H);
            return Hit.Zone /= Editor.Quick_Open.Outside_Quick_Open;

         when others =>
            return True;
      end case;
   end Handle_Quick_Open;



   function Handle_Buffer_Switcher
     (Cmd : Editor.Commands.Command) return Boolean
   is
      Cmd2 : Editor.Commands.Command;
   begin
      if Cmd.Kind = Editor.Commands.Open_Buffer_Switcher then
         Execute_Command_Id (Editor.Commands.Command_Open_Buffer_Switcher);
         return True;
      end if;

      if not Editor.Overlay_Focus.Is_Active
        (The_Editor.State.Overlay_Focus,
         Editor.Overlay_Focus.Buffer_Switcher_Overlay)
      then
         return False;
      end if;

      case Cmd.Kind is
         when Editor.Commands.Insert_Text_Input =>
            if Cmd.Ctrl and then (Cmd.Ch = 'a' or else Cmd.Ch = 'A') then
               Editor.Buffer_Switcher.Select_All (The_Editor.State.Buffer_Switcher);
               Editor.Render_Cache.Invalidate_All;
            elsif Cmd.Ch = ASCII.LF or else Cmd.Ch = ASCII.CR then
               Execute_Command_Id (Editor.Commands.Command_Accept_Buffer_Switcher);
            elsif Cmd.Ch = ASCII.HT then
               if Cmd.Shift then
                  Execute_Command_Id (Editor.Commands.Command_Buffer_Switcher_Previous_Result);
               else
                  Execute_Command_Id (Editor.Commands.Command_Buffer_Switcher_Next_Result);
               end if;
            elsif Length (Cmd.Text) > 0 then
               Cmd2.Kind := Editor.Commands.Buffer_Switcher_Insert_Text;
               Cmd2.Text := Cmd.Text;
               Editor.Instance.Execute (The_Editor, Cmd2);
            elsif Cmd.Ch /= ASCII.NUL then
               Cmd2.Kind := Editor.Commands.Buffer_Switcher_Insert_Text;
               Cmd2.Text := To_Unbounded_String (String'(1 => Cmd.Ch));
               Editor.Instance.Execute (The_Editor, Cmd2);
            end if;
            return True;

         when Editor.Commands.Delete_Char
            | Editor.Commands.Delete_Previous_Character =>
            Cmd2.Kind := Editor.Commands.Buffer_Switcher_Backspace;
            Editor.Instance.Execute (The_Editor, Cmd2);
            return True;

         when Editor.Commands.Forward_Delete_Char
            | Editor.Commands.Delete_Next_Character =>
            Cmd2.Kind := Editor.Commands.Buffer_Switcher_Delete_Forward;
            Editor.Instance.Execute (The_Editor, Cmd2);
            return True;

         when Editor.Commands.Paste_Text =>
            Cmd2.Kind := Editor.Commands.Buffer_Switcher_Insert_Text;
            Cmd2.Text := Cmd.Text;
            Editor.Instance.Execute (The_Editor, Cmd2);
            return True;

         when Editor.Commands.Paste_Clipboard =>
            Cmd2.Kind := Editor.Commands.Buffer_Switcher_Insert_Text;
            Cmd2.Text :=
              Editor.Executor.Clipboard.Text_For_Local_Input;
            Editor.Instance.Execute (The_Editor, Cmd2);
            return True;

         when Editor.Commands.Move_Up =>
            Execute_Command_Id (Editor.Commands.Command_Buffer_Switcher_Previous_Result);
            return True;

         when Editor.Commands.Move_Down =>
            Execute_Command_Id (Editor.Commands.Command_Buffer_Switcher_Next_Result);
            return True;

         when Editor.Commands.Move_Left =>
            Editor.Buffer_Switcher.Move_Cursor_Left (The_Editor.State.Buffer_Switcher);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_Right =>
            Editor.Buffer_Switcher.Move_Cursor_Right (The_Editor.State.Buffer_Switcher);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_Home | Editor.Commands.Move_Line_Start =>
            Editor.Buffer_Switcher.Move_Cursor_Start (The_Editor.State.Buffer_Switcher);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_End | Editor.Commands.Move_Line_End =>
            Editor.Buffer_Switcher.Move_Cursor_End (The_Editor.State.Buffer_Switcher);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Palette_Accept | Editor.Commands.Accept_Buffer_Switcher =>
            Execute_Command_Id (Editor.Commands.Command_Accept_Buffer_Switcher);
            return True;

         when Editor.Commands.Palette_Cancel | Editor.Commands.Close_Buffer_Switcher =>
            Execute_Command_Id (Editor.Commands.Command_Close_Buffer_Switcher);
            return True;

         when others =>
            null;
      end case;

      return True;
   end Handle_Buffer_Switcher;

   function Handle_Project_Search_Bar
     (Cmd : Editor.Commands.Command) return Boolean
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Message_Body   : constant Editor.Layout.Rect :=
        Editor.Layout.Editor_Body_Rect
          (Layout, Editor.View.Viewport_Width, Editor.View.Viewport_Height);
      Config : constant Editor.Project_Search_Bar.Project_Search_Bar_Config := (others => <>);
      Hit    : Editor.Project_Search_Bar.Project_Search_Bar_Hit_Result;
      Cmd2   : Editor.Commands.Command;
   begin
      if Cmd.Kind = Editor.Commands.Open_Project_Search_Bar then
         Execute_Command_Id (Editor.Commands.Command_Open_Project_Search_Bar);
         return True;
      end if;

      if not Editor.Overlay_Focus.Is_Active
        (The_Editor.State.Overlay_Focus,
         Editor.Overlay_Focus.Project_Search_Bar_Overlay)
      then
         return False;
      end if;

      case Cmd.Kind is
         when Editor.Commands.Insert_Text_Input =>
            if Cmd.Ctrl and then (Cmd.Ch = 'a' or else Cmd.Ch = 'A') then
               Editor.Project_Search_Bar.Select_All (The_Editor.State.Project_Search_Bar);
               Editor.Render_Cache.Invalidate_All;
            elsif Cmd.Ch = ASCII.LF or else Cmd.Ch = ASCII.CR then
               Execute_Command_Id (Editor.Commands.Command_Run_Project_Search_From_Bar);
            elsif Cmd.Ch = ASCII.HT then
               Editor.Project_Search_Bar.Toggle_Active_Field
                 (The_Editor.State.Project_Search_Bar);
               Sync_Project_Search_Replace_Mode_From_Bar;
               Editor.Render_Cache.Invalidate_All;
            elsif Length (Cmd.Text) > 0 then
               Cmd2.Kind := Editor.Commands.Project_Search_Bar_Insert_Text;
               Cmd2.Text := Cmd.Text;
               Editor.Instance.Execute (The_Editor, Cmd2);
            elsif Cmd.Ch /= ASCII.NUL then
               Cmd2.Kind := Editor.Commands.Project_Search_Bar_Insert_Text;
               Cmd2.Text := To_Unbounded_String (String'(1 => Cmd.Ch));
               Editor.Instance.Execute (The_Editor, Cmd2);
            end if;
            return True;

         when Editor.Commands.Delete_Char
            | Editor.Commands.Delete_Previous_Character =>
            Cmd2.Kind := Editor.Commands.Project_Search_Bar_Backspace;
            Editor.Instance.Execute (The_Editor, Cmd2);
            return True;

         when Editor.Commands.Forward_Delete_Char
            | Editor.Commands.Delete_Next_Character =>
            Cmd2.Kind := Editor.Commands.Project_Search_Bar_Delete_Forward;
            Editor.Instance.Execute (The_Editor, Cmd2);
            return True;

         when Editor.Commands.Paste_Text =>
            Cmd2.Kind := Editor.Commands.Project_Search_Bar_Insert_Text;
            Cmd2.Text := Cmd.Text;
            Editor.Instance.Execute (The_Editor, Cmd2);
            return True;

         when Editor.Commands.Paste_Clipboard =>
            Cmd2.Kind := Editor.Commands.Project_Search_Bar_Insert_Text;
            Cmd2.Text :=
              Editor.Executor.Clipboard.Text_For_Local_Input;
            Editor.Instance.Execute (The_Editor, Cmd2);
            return True;

         when Editor.Commands.Move_Left =>
            Editor.Project_Search_Bar.Move_Cursor_Left (The_Editor.State.Project_Search_Bar);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_Right =>
            Editor.Project_Search_Bar.Move_Cursor_Right (The_Editor.State.Project_Search_Bar);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_Home | Editor.Commands.Move_Line_Start =>
            Editor.Project_Search_Bar.Move_Cursor_Start (The_Editor.State.Project_Search_Bar);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_End | Editor.Commands.Move_Line_End =>
            Editor.Project_Search_Bar.Move_Cursor_End (The_Editor.State.Project_Search_Bar);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_Down
            | Editor.Commands.Move_Project_Search_Selection_Down =>
            Execute_Command_Id (Editor.Commands.Command_Move_Project_Search_Selection_Down);
            return True;

         when Editor.Commands.Move_Up
            | Editor.Commands.Move_Project_Search_Selection_Up =>
            Execute_Command_Id (Editor.Commands.Command_Move_Project_Search_Selection_Up);
            return True;

         when Editor.Commands.Next_Project_Search_Result =>
            Execute_Command_Id (Editor.Commands.Command_Next_Project_Search_Result);
            return True;

         when Editor.Commands.Previous_Project_Search_Result =>
            Execute_Command_Id (Editor.Commands.Command_Previous_Project_Search_Result);
            return True;

         when Editor.Commands.Project_Search_Kind_Next =>
            Execute_Command_Id (Editor.Commands.Command_Project_Search_Kind_Next);
            return True;

         when Editor.Commands.Project_Search_Kind_Previous =>
            Execute_Command_Id (Editor.Commands.Command_Project_Search_Kind_Previous);
            return True;

         when Editor.Commands.Project_Search_Kind_Clear =>
            Execute_Command_Id (Editor.Commands.Command_Project_Search_Kind_Clear);
            return True;

         when Editor.Commands.Project_Search_Scope_Clear =>
            Execute_Command_Id (Editor.Commands.Command_Project_Search_Scope_Clear);
            return True;

         when Editor.Commands.Project_Search_Case_Toggle =>
            Execute_Command_Id (Editor.Commands.Command_Project_Search_Case_Toggle);
            return True;

         when Editor.Commands.Project_Search_Case_Clear =>
            Execute_Command_Id (Editor.Commands.Command_Project_Search_Case_Clear);
            return True;

         when Editor.Commands.Project_Search_Whole_Word_Toggle =>
            Execute_Command_Id (Editor.Commands.Command_Project_Search_Whole_Word_Toggle);
            return True;

         when Editor.Commands.Project_Search_Whole_Word_Clear =>
            Execute_Command_Id (Editor.Commands.Command_Project_Search_Whole_Word_Clear);
            return True;

         when Editor.Commands.Project_Search_Regex_Toggle =>
            Execute_Command_Id (Editor.Commands.Command_Project_Search_Regex_Toggle);
            return True;

         when Editor.Commands.Project_Search_Regex_Clear =>
            Execute_Command_Id (Editor.Commands.Command_Project_Search_Regex_Clear);
            return True;

         when Editor.Commands.Project_Search_Include_Filter_Clear =>
            Execute_Command_Id (Editor.Commands.Command_Project_Search_Include_Filter_Clear);
            return True;

         when Editor.Commands.Project_Search_Exclude_Filter_Clear =>
            Execute_Command_Id (Editor.Commands.Command_Project_Search_Exclude_Filter_Clear);
            return True;

         when Editor.Commands.Palette_Accept | Editor.Commands.Run_Project_Search_From_Bar =>
            Execute_Command_Id (Editor.Commands.Command_Run_Project_Search_From_Bar);
            return True;

         when Editor.Commands.Open_Selected_Project_Search_Result =>
            Execute_Command_Id (Editor.Commands.Command_Open_Selected_Project_Search_Result);
            return True;

         when Editor.Commands.Clear_Project_Search =>
            Execute_Command_Id (Editor.Commands.Command_Clear_Project_Search);
            return True;

         when Editor.Commands.Clear_Extra_Carets
            | Editor.Commands.Palette_Cancel
            | Editor.Commands.Close_Project_Search_Bar =>
            Execute_Command_Id (Editor.Commands.Command_Close_Project_Search_Bar);
            return True;

         when Editor.Commands.Move_To_Point =>
            Hit := Editor.Project_Search_Bar.Hit_Test
              (Message_Body, Config, The_Editor.State.Project_Search_Bar,
               Integer (Cmd.Click_X), Integer (Cmd.Click_Y),
               Editor.Layout.Cell_W, Editor.Layout.Cell_H);
            case Hit.Zone is
               when Editor.Project_Search_Bar.Outside_Project_Search_Bar =>
                  Editor.Executor.Dismiss_Active_Overlay
                    (The_Editor.State, Editor.Overlay_Focus.Dismiss_Outside_Click);
                  return False;
               when Editor.Project_Search_Bar.Project_Search_Query_Field_Zone =>
                  Editor.Project_Search_Bar.Focus_Query_Field
                    (The_Editor.State.Project_Search_Bar);
                  declare
                     G : constant Editor.Layout.Rect :=
                       Editor.Project_Search_Bar.Geometry
                         (Message_Body, Config, Editor.Layout.Cell_W, Editor.Layout.Cell_H);
                     Total_Cols : constant Natural := G.Width / Editor.Layout.Cell_W;
                     Run_Start : constant Natural :=
                       (if Total_Cols > 22 then Total_Cols - 22 else 0);
                     Field_Cols : constant Natural :=
                       (if Run_Start > 18 then Run_Start - 18
                        else Natural'Max (1, Config.Query_Field_Min_Columns));
                     Text_Start : constant Integer :=
                       G.X + Integer (17 * Editor.Layout.Cell_W);
                     Visible_Column : constant Natural :=
                       (if Integer (Cmd.Click_X) <= Text_Start then 0
                        else Natural ((Integer (Cmd.Click_X) - Text_Start)
                                      / Integer (Editor.Layout.Cell_W)));
                  begin
                     Editor.Project_Search_Bar.Set_Cursor_From_Visible_Column
                       (The_Editor.State.Project_Search_Bar, Visible_Column, Field_Cols);
                  end;
               when Editor.Project_Search_Bar.Project_Search_Replace_Field_Zone =>
                  Editor.Project_Search_Bar.Focus_Replace_Field
                    (The_Editor.State.Project_Search_Bar);
                  Sync_Project_Search_Replace_Mode_From_Bar;
                  declare
                     G : constant Editor.Layout.Rect :=
                       Editor.Project_Search_Bar.Geometry
                         (Message_Body, Config, Editor.Layout.Cell_W, Editor.Layout.Cell_H);
                     Total_Cols : constant Natural := G.Width / Editor.Layout.Cell_W;
                     Run_Start : constant Natural :=
                       (if Total_Cols > 22 then Total_Cols - 22 else 0);
                     Field_Cols : constant Natural :=
                       (if Run_Start > 18 then Run_Start - 18
                        else Natural'Max (1, Config.Query_Field_Min_Columns));
                     Text_Start : constant Integer :=
                       G.X + Integer (17 * Editor.Layout.Cell_W);
                     Visible_Column : constant Natural :=
                       (if Integer (Cmd.Click_X) <= Text_Start then 0
                        else Natural ((Integer (Cmd.Click_X) - Text_Start)
                                      / Integer (Editor.Layout.Cell_W)));
                  begin
                     Editor.Project_Search_Bar.Set_Cursor_From_Visible_Column
                       (The_Editor.State.Project_Search_Bar, Visible_Column, Field_Cols);
                  end;
               when Editor.Project_Search_Bar.Project_Search_Run_Button_Zone =>
                  Execute_Command_Id (Editor.Commands.Command_Run_Project_Search_From_Bar);
               when Editor.Project_Search_Bar.Project_Search_Clear_Button_Zone =>
                  Execute_Command_Id (Editor.Commands.Command_Clear_Project_Search);
               when Editor.Project_Search_Bar.Project_Search_Close_Button_Zone =>
                  Execute_Command_Id (Editor.Commands.Command_Close_Project_Search_Bar);
               when others =>
                  null;
            end case;
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Pointer_Hover =>
            Hit := Editor.Project_Search_Bar.Hit_Test
              (Message_Body, Config, The_Editor.State.Project_Search_Bar,
               Integer (Cmd.Click_X), Integer (Cmd.Click_Y),
               Editor.Layout.Cell_W, Editor.Layout.Cell_H);
            return Hit.Zone /= Editor.Project_Search_Bar.Outside_Project_Search_Bar;

         when others =>
            return True;
      end case;
   end Handle_Project_Search_Bar;



   function Handle_Goto_Line
     (Cmd : Editor.Commands.Command) return Boolean
   is
      Cmd2 : Editor.Commands.Command;
   begin
      if Cmd.Kind = Editor.Commands.Open_Goto_Line then
         Execute_Command_Id (Editor.Commands.Command_Goto_Line);
         return True;
      elsif Cmd.Kind = Editor.Commands.Prefill_Goto_Line_Current then
         Execute_Command_Id (Editor.Commands.Command_Goto_Line_Prefill_Current);
         return True;
      end if;

      if not Editor.Overlay_Focus.Is_Active
        (The_Editor.State.Overlay_Focus,
         Editor.Overlay_Focus.Go_To_Line_Overlay)
      then
         return False;
      end if;

      case Cmd.Kind is
         when Editor.Commands.Insert_Text_Input =>
            if Cmd.Ctrl and then (Cmd.Ch = 'a' or else Cmd.Ch = 'A') then
               Editor.Go_To_Line.Select_All (The_Editor.State.Go_To_Line);
               Editor.Render_Cache.Invalidate_All;
            elsif Cmd.Ch = ASCII.LF or else Cmd.Ch = ASCII.CR then
               Execute_Command_Id (Editor.Commands.Command_Accept_Goto_Line);
            elsif Length (Cmd.Text) > 0 then
               Cmd2.Kind := Editor.Commands.Goto_Line_Insert_Text;
               Cmd2.Text := Cmd.Text;
               Editor.Instance.Execute (The_Editor, Cmd2);
            elsif Cmd.Ch /= ASCII.NUL and then Cmd.Ch /= ASCII.HT then
               Cmd2.Kind := Editor.Commands.Goto_Line_Insert_Text;
               Cmd2.Text := To_Unbounded_String (String'(1 => Cmd.Ch));
               Editor.Instance.Execute (The_Editor, Cmd2);
            end if;
            return True;

         when Editor.Commands.Delete_Char
            | Editor.Commands.Delete_Previous_Character =>
            Cmd2.Kind := Editor.Commands.Goto_Line_Backspace;
            Editor.Instance.Execute (The_Editor, Cmd2);
            return True;

         when Editor.Commands.Forward_Delete_Char
            | Editor.Commands.Delete_Next_Character =>
            Cmd2.Kind := Editor.Commands.Goto_Line_Delete_Forward;
            Editor.Instance.Execute (The_Editor, Cmd2);
            return True;

         when Editor.Commands.Paste_Text =>
            Cmd2.Kind := Editor.Commands.Goto_Line_Insert_Text;
            Cmd2.Text := Cmd.Text;
            Editor.Instance.Execute (The_Editor, Cmd2);
            return True;

         when Editor.Commands.Paste_Clipboard =>
            Cmd2.Kind := Editor.Commands.Goto_Line_Insert_Text;
            Cmd2.Text :=
              Editor.Executor.Clipboard.Text_For_Local_Input;
            Editor.Instance.Execute (The_Editor, Cmd2);
            return True;

         when Editor.Commands.Move_Left =>
            Editor.Go_To_Line.Move_Cursor_Left (The_Editor.State.Go_To_Line);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_Right =>
            Editor.Go_To_Line.Move_Cursor_Right (The_Editor.State.Go_To_Line);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_Line_Start =>
            Editor.Go_To_Line.Move_Cursor_Start (The_Editor.State.Go_To_Line);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_Line_End =>
            Editor.Go_To_Line.Move_Cursor_End (The_Editor.State.Go_To_Line);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Prefill_Goto_Line_Current =>
            Execute_Command_Id (Editor.Commands.Command_Goto_Line_Prefill_Current);
            return True;

         when Editor.Commands.Close_Goto_Line =>
            Execute_Command_Id (Editor.Commands.Command_Close_Goto_Line);
            return True;

         when Editor.Commands.Accept_Goto_Line =>
            Execute_Command_Id (Editor.Commands.Command_Accept_Goto_Line);
            return True;

         when Editor.Commands.Goto_Line_Query_Set =>
            Editor.Executor.Command_Surface_Commands.Execute_Goto_Line_Set_Query
              (The_Editor.State, To_String (Cmd.Text));
            return True;

         when Editor.Commands.Goto_Line_Query_Clear =>
            Editor.Executor.Command_Surface_Commands.Execute_Goto_Line_Clear_Query (The_Editor.State);
            return True;

         when others =>
            return False;
      end case;
   end Handle_Goto_Line;

   function Handle_Active_Find_Input
     (Cmd : Editor.Commands.Command) return Boolean
   is
      Cmd2 : Editor.Commands.Command;
   begin
      if not The_Editor.State.Active_Find_Prompt then
         return False;
      end if;

      if not Editor.Overlay_Focus.Is_Active
        (The_Editor.State.Overlay_Focus,
         Editor.Overlay_Focus.Active_Find_Prompt_Overlay)
      then
         return False;
      end if;

      case Cmd.Kind is
         when Editor.Commands.Insert_Text_Input =>
            if Cmd.Ctrl and then (Cmd.Ch = 'a' or else Cmd.Ch = 'A') then
               Editor.Input_Field.Select_All (The_Editor.State.Active_Find_Input);
               Editor.Render_Cache.Invalidate_All;
            elsif Cmd.Ch = ASCII.LF or else Cmd.Ch = ASCII.CR then
               Execute_Command_Id (Editor.Commands.Command_Active_Find_Next);
            elsif Cmd.Ch = ASCII.HT then
               null;
            elsif Length (Cmd.Text) > 0 then
               Cmd2.Kind := Editor.Commands.Active_Find_Input_Insert_Text;
               Cmd2.Text := Cmd.Text;
               Editor.Instance.Execute (The_Editor, Cmd2);
            elsif Cmd.Ch /= ASCII.NUL then
               Cmd2.Kind := Editor.Commands.Active_Find_Input_Insert_Text;
               Cmd2.Text := To_Unbounded_String (String'(1 => Cmd.Ch));
               Editor.Instance.Execute (The_Editor, Cmd2);
            end if;
            return True;

         when Editor.Commands.Delete_Char
            | Editor.Commands.Delete_Previous_Character =>
            Cmd2.Kind := Editor.Commands.Active_Find_Input_Backspace;
            Editor.Instance.Execute (The_Editor, Cmd2);
            return True;

         when Editor.Commands.Forward_Delete_Char
            | Editor.Commands.Delete_Next_Character =>
            Cmd2.Kind := Editor.Commands.Active_Find_Input_Delete_Forward;
            Editor.Instance.Execute (The_Editor, Cmd2);
            return True;

         when Editor.Commands.Paste_Text =>
            Cmd2.Kind := Editor.Commands.Active_Find_Input_Insert_Text;
            Cmd2.Text := Cmd.Text;
            Editor.Instance.Execute (The_Editor, Cmd2);
            return True;

         when Editor.Commands.Paste_Clipboard =>
            Cmd2.Kind := Editor.Commands.Active_Find_Input_Insert_Text;
            Cmd2.Text :=
              Editor.Executor.Clipboard.Text_For_Local_Input;
            Editor.Instance.Execute (The_Editor, Cmd2);
            return True;

         when Editor.Commands.Move_Left =>
            Editor.Executor.Find_Replace_Commands.Execute_Active_Find_Input_Move_Cursor_Left (The_Editor.State);
            return True;

         when Editor.Commands.Move_Right =>
            Editor.Executor.Find_Replace_Commands.Execute_Active_Find_Input_Move_Cursor_Right (The_Editor.State);
            return True;

         when Editor.Commands.Move_Home | Editor.Commands.Move_Line_Start =>
            Editor.Executor.Find_Replace_Commands.Execute_Active_Find_Input_Move_Cursor_Start (The_Editor.State);
            return True;

         when Editor.Commands.Move_End | Editor.Commands.Move_Line_End =>
            Editor.Executor.Find_Replace_Commands.Execute_Active_Find_Input_Move_Cursor_End (The_Editor.State);
            return True;

         when Editor.Commands.Active_Find_Next =>
            Execute_Command_Id (Editor.Commands.Command_Active_Find_Next);
            return True;

         when Editor.Commands.Active_Find_Previous =>
            Execute_Command_Id (Editor.Commands.Command_Active_Find_Previous);
            return True;

         when Editor.Commands.Active_Find_First =>
            Execute_Command_Id (Editor.Commands.Command_Find_First);
            return True;

         when Editor.Commands.Active_Find_Last =>
            Execute_Command_Id (Editor.Commands.Command_Find_Last);
            return True;

         when Editor.Commands.Active_Find_Reveal_Current =>
            Execute_Command_Id (Editor.Commands.Command_Find_Reveal_Current);
            return True;

         when Editor.Commands.Active_Find_Query_Clear =>
            Execute_Command_Id (Editor.Commands.Command_Find_Query_Clear);
            return True;

         when Editor.Commands.Active_Find_Case_Toggle =>
            Execute_Command_Id (Editor.Commands.Command_Find_Case_Toggle);
            return True;

         when Editor.Commands.Active_Find_Case_Clear =>
            Execute_Command_Id (Editor.Commands.Command_Find_Case_Clear);
            return True;

         when Editor.Commands.Active_Find_Whole_Word_Toggle =>
            Execute_Command_Id (Editor.Commands.Command_Find_Whole_Word_Toggle);
            return True;

         when Editor.Commands.Active_Find_Whole_Word_Clear =>
            Execute_Command_Id (Editor.Commands.Command_Find_Whole_Word_Clear);
            return True;

         when Editor.Commands.Clear_Extra_Carets
            | Editor.Commands.Palette_Cancel =>
            Execute_Command_Id (Editor.Commands.Command_Find_Hide);
            return True;

         when others =>
            return False;
      end case;
   end Handle_Active_Find_Input;

   function Handle_Outline_Filter_Input
     (Cmd : Editor.Commands.Command) return Boolean
   is
   begin
      if not Editor.Outline.Filter_Input_Is_Active (The_Editor.State.Outline) then
         return False;
      end if;

      case Cmd.Kind is
         when Editor.Commands.Insert_Text_Input =>
            if Cmd.Ch = ASCII.LF or else Cmd.Ch = ASCII.CR then
               Editor.Outline.Commit_Filter_To_History (The_Editor.State.Outline);
               if Editor.Feature_Panel.Has_Selection (The_Editor.State.Feature_Panel) then
                  Execute_Command_Id
                    (Editor.Commands.Command_Open_Selected_Outline_Item);
               end if;
            elsif Cmd.Ch = ASCII.HT then
               Editor.Outline.Deactivate_Filter_Input (The_Editor.State.Outline);
               Editor.Render_Cache.Invalidate_All;
            elsif Length (Cmd.Text) > 0 then
               Editor.Outline.Insert_Filter_Text
                 (The_Editor.State.Outline, To_String (Cmd.Text));
               Editor.Outline.Set_Rows_From_Outline
                 (The_Editor.State.Outline, The_Editor.State.Feature_Panel);
               if Editor.Outline.Selected_Index (The_Editor.State.Outline) /= 0 then
                  Editor.Feature_Panel.Request_Reveal_Row
                    (The_Editor.State.Feature_Panel,
                     Editor.Outline.Visible_Row_For_Outline_Row
                       (The_Editor.State.Outline,
                        Editor.Outline.Selected_Index (The_Editor.State.Outline)));
               end if;
               Editor.Render_Cache.Invalidate_All;
            elsif Cmd.Ch /= ASCII.NUL then
               Editor.Outline.Insert_Filter_Character
                 (The_Editor.State.Outline, Cmd.Ch);
               Editor.Outline.Set_Rows_From_Outline
                 (The_Editor.State.Outline, The_Editor.State.Feature_Panel);
               if Editor.Outline.Selected_Index (The_Editor.State.Outline) /= 0 then
                  Editor.Feature_Panel.Request_Reveal_Row
                    (The_Editor.State.Feature_Panel,
                     Editor.Outline.Visible_Row_For_Outline_Row
                       (The_Editor.State.Outline,
                        Editor.Outline.Selected_Index (The_Editor.State.Outline)));
               end if;
               Editor.Render_Cache.Invalidate_All;
            end if;
            return True;

         when Editor.Commands.Delete_Char
            | Editor.Commands.Delete_Previous_Character =>
            Editor.Outline.Delete_Filter_Character_Backward (The_Editor.State.Outline);
            Editor.Outline.Set_Rows_From_Outline
              (The_Editor.State.Outline, The_Editor.State.Feature_Panel);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Forward_Delete_Char
            | Editor.Commands.Delete_Next_Character =>
            Editor.Outline.Delete_Filter_Character_Forward (The_Editor.State.Outline);
            Editor.Outline.Set_Rows_From_Outline
              (The_Editor.State.Outline, The_Editor.State.Feature_Panel);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Paste_Text =>
            Editor.Outline.Insert_Filter_Text
              (The_Editor.State.Outline, To_String (Cmd.Text));
            Editor.Outline.Set_Rows_From_Outline
              (The_Editor.State.Outline, The_Editor.State.Feature_Panel);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Paste_Clipboard =>
            Editor.Outline.Insert_Filter_Text
              (The_Editor.State.Outline,
               To_String (Editor.Executor.Clipboard.Text_For_Local_Input));
            Editor.Outline.Set_Rows_From_Outline
              (The_Editor.State.Outline, The_Editor.State.Feature_Panel);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_Left =>
            Editor.Outline.Move_Filter_Caret_Left (The_Editor.State.Outline);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_Right =>
            Editor.Outline.Move_Filter_Caret_Right (The_Editor.State.Outline);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_Home | Editor.Commands.Move_Line_Start =>
            Editor.Outline.Move_Filter_Caret_Start (The_Editor.State.Outline);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_End | Editor.Commands.Move_Line_End =>
            Editor.Outline.Move_Filter_Caret_End (The_Editor.State.Outline);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_Down | Editor.Commands.Select_Next_Outline_Item =>
            Execute_Command_Id
              (Editor.Commands.Command_Select_Next_Outline_Item);
            return True;

         when Editor.Commands.Move_Up | Editor.Commands.Select_Previous_Outline_Item =>
            Execute_Command_Id
              (Editor.Commands.Command_Select_Previous_Outline_Item);
            return True;

         when Editor.Commands.Open_Selected_Outline_Item =>
            Execute_Command_Id
              (Editor.Commands.Command_Open_Selected_Outline_Item);
            return True;

         when Editor.Commands.Clear_Extra_Carets | Editor.Commands.Palette_Cancel =>
            if Editor.Outline.Filter_Text (The_Editor.State.Outline) /= "" then
               Editor.Outline.Clear_Filter_Text (The_Editor.State.Outline);
            else
               Editor.Outline.Deactivate_Filter_Input (The_Editor.State.Outline);
            end if;
            Editor.Outline.Set_Rows_From_Outline
              (The_Editor.State.Outline, The_Editor.State.Feature_Panel);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when others =>
            return True;
      end case;
   end Handle_Outline_Filter_Input;

   function Handle_File_Target_Prompt
     (Cmd : Editor.Commands.Command) return Boolean
   is
   begin
      if not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (The_Editor.State) then
         return False;
      end if;

      if not Editor.Overlay_Focus.Is_Active
        (The_Editor.State.Overlay_Focus,
         Editor.Overlay_Focus.File_Target_Prompt_Overlay)
      then
         return False;
      end if;

      case Cmd.Kind is
         when Editor.Commands.Insert_Text_Input =>
            if Cmd.Ctrl and then (Cmd.Ch = 'a' or else Cmd.Ch = 'A') then
               Editor.Executor.File_Target_Prompt_Commands.Select_All_File_Target_Prompt_Text
                 (The_Editor.State);
            elsif Cmd.Ch = ASCII.LF or else Cmd.Ch = ASCII.CR then
               Editor.Executor.File_Target_Prompt_Commands.Confirm_File_Target_Prompt (The_Editor.State);
               Editor.Focus_Management.Restore_Focus_To_Editor (The_Editor.State);
            elsif Cmd.Ch = ASCII.HT then
               null;
            elsif Length (Cmd.Text) > 0 then
               Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text
                 (The_Editor.State, To_String (Cmd.Text));
            elsif Cmd.Ch /= ASCII.NUL then
               Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text
                 (The_Editor.State, String'(1 => Cmd.Ch));
            end if;
            return True;

         when Editor.Commands.Delete_Char
            | Editor.Commands.Delete_Previous_Character =>
            Editor.Executor.File_Target_Prompt_Commands.Backspace_File_Target_Prompt (The_Editor.State);
            return True;

         when Editor.Commands.Forward_Delete_Char
            | Editor.Commands.Delete_Next_Character =>
            Editor.Executor.File_Target_Prompt_Commands.Delete_Forward_File_Target_Prompt (The_Editor.State);
            return True;

         when Editor.Commands.Paste_Text =>
            Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text
              (The_Editor.State, To_String (Cmd.Text));
            return True;

         when Editor.Commands.Paste_Clipboard =>
            Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text
              (The_Editor.State,
               To_String (Editor.Executor.Clipboard.Text_For_Local_Input));
            return True;

         when Editor.Commands.Move_Left =>
            Editor.Executor.File_Target_Prompt_Commands.Move_File_Target_Prompt_Cursor_Left (The_Editor.State);
            return True;

         when Editor.Commands.Move_Right =>
            Editor.Executor.File_Target_Prompt_Commands.Move_File_Target_Prompt_Cursor_Right (The_Editor.State);
            return True;

         when Editor.Commands.Move_Home | Editor.Commands.Move_Line_Start =>
            Editor.Executor.File_Target_Prompt_Commands.Move_File_Target_Prompt_Cursor_Start (The_Editor.State);
            return True;

         when Editor.Commands.Move_End | Editor.Commands.Move_Line_End =>
            Editor.Executor.File_Target_Prompt_Commands.Move_File_Target_Prompt_Cursor_End (The_Editor.State);
            return True;

         when Editor.Commands.Palette_Cancel =>
            Editor.Executor.File_Target_Prompt_Commands.Cancel_File_Target_Prompt (The_Editor.State);
            Editor.Focus_Management.Restore_Previous_Focus_Or_Editor (The_Editor.State);
            return True;

         when others =>
            return True;
      end case;
   end Handle_File_Target_Prompt;


   function Handle_Search_Query_Input
     (Cmd : Editor.Commands.Command) return Boolean
   is
   begin
      if not Editor.Feature_Search_Results.Search_Input_Is_Active
        (The_Editor.State.Feature_Search_Results)
      then
         return False;
      end if;

      case Cmd.Kind is
         when Editor.Commands.Insert_Text_Input =>
            if Cmd.Ch = ASCII.LF or else Cmd.Ch = ASCII.CR then
               Execute_Command_Id (Editor.Commands.Command_Search_Results_Search_Active_Buffer);
            elsif Length (Cmd.Text) > 0 then
               declare
                  Text : constant String := To_String (Cmd.Text);
               begin
                  for Ch of Text loop
                     if Ch /= ASCII.LF and then Ch /= ASCII.CR then
                        Editor.Feature_Search_Results.Insert_Search_Input_Character
                          (The_Editor.State.Feature_Search_Results, Ch);
                     end if;
                  end loop;
               end;
               Editor.Feature_Search_Results.Project_Rows
                 (The_Editor.State.Feature_Search_Results,
                  The_Editor.State.Feature_Panel);
               Editor.Render_Cache.Invalidate_All;
            elsif Cmd.Ch /= ASCII.NUL and then Cmd.Ch /= ASCII.HT then
               Editor.Feature_Search_Results.Insert_Search_Input_Character
                 (The_Editor.State.Feature_Search_Results, Cmd.Ch);
               Editor.Feature_Search_Results.Project_Rows
                 (The_Editor.State.Feature_Search_Results,
                  The_Editor.State.Feature_Panel);
               Editor.Render_Cache.Invalidate_All;
            end if;
            return True;

         when Editor.Commands.Delete_Char
            | Editor.Commands.Delete_Previous_Character =>
            Editor.Feature_Search_Results.Delete_Search_Input_Character_Backward
              (The_Editor.State.Feature_Search_Results);
            Editor.Feature_Search_Results.Project_Rows
              (The_Editor.State.Feature_Search_Results,
               The_Editor.State.Feature_Panel);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Forward_Delete_Char
            | Editor.Commands.Delete_Next_Character =>
            Editor.Feature_Search_Results.Delete_Search_Input_Character_Forward
              (The_Editor.State.Feature_Search_Results);
            Editor.Feature_Search_Results.Project_Rows
              (The_Editor.State.Feature_Search_Results,
               The_Editor.State.Feature_Panel);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Paste_Text =>
            declare
               Text : constant String := To_String (Cmd.Text);
            begin
               for Ch of Text loop
                  if Ch /= ASCII.LF and then Ch /= ASCII.CR then
                     Editor.Feature_Search_Results.Insert_Search_Input_Character
                       (The_Editor.State.Feature_Search_Results, Ch);
                  end if;
               end loop;
            end;
            Editor.Feature_Search_Results.Project_Rows
              (The_Editor.State.Feature_Search_Results,
               The_Editor.State.Feature_Panel);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Paste_Clipboard =>
            declare
               Text : constant String :=
                 To_String (Editor.Executor.Clipboard.Text_For_Local_Input);
            begin
               for Ch of Text loop
                  if Ch /= ASCII.LF and then Ch /= ASCII.CR then
                     Editor.Feature_Search_Results.Insert_Search_Input_Character
                       (The_Editor.State.Feature_Search_Results, Ch);
                  end if;
               end loop;
            end;
            Editor.Feature_Search_Results.Project_Rows
              (The_Editor.State.Feature_Search_Results,
               The_Editor.State.Feature_Panel);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_Up =>
            Execute_Command_Id (Editor.Commands.Command_Search_Results_Query_History_Previous);
            return True;

         when Editor.Commands.Move_Down =>
            Execute_Command_Id (Editor.Commands.Command_Search_Results_Query_History_Next);
            return True;

         when Editor.Commands.Clear_Extra_Carets | Editor.Commands.Palette_Cancel =>
            Editor.Feature_Search_Results.Deactivate_Search_Query_Input
              (The_Editor.State.Feature_Search_Results);
            Editor.Feature_Search_Results.Project_Rows
              (The_Editor.State.Feature_Search_Results,
               The_Editor.State.Feature_Panel);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when others =>
            return True;
      end case;
   end Handle_Search_Query_Input;



   function Is_Minimap_Pointer_Command
     (Kind : Editor.Commands.Command_Kind) return Boolean
   is
   begin
      case Kind is
         when Editor.Commands.Move_To_Point
            | Editor.Commands.Drag_To_Point
            | Editor.Commands.Start_Rectangle_Selection
            | Editor.Commands.Drag_Rectangle_To_Point
            | Editor.Commands.Add_Caret_At_Point
            | Editor.Commands.Select_Word_At_Point
            | Editor.Commands.Select_Line_At_Point =>
            return True;

         when others =>
            return False;
      end case;
   end Is_Minimap_Pointer_Command;

   function Is_Minimap_Drag_Command
     (Kind : Editor.Commands.Command_Kind) return Boolean
   is
   begin
      return Kind = Editor.Commands.Drag_To_Point
        or else Kind = Editor.Commands.Drag_Rectangle_To_Point;
   end Is_Minimap_Drag_Command;

   procedure Scroll_From_Minimap_Y
     (Y : Natural)
   is
      Layout        : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Config        : constant Editor.Minimap.Minimap_Config := Editor.Minimap.Current;
      Document_Rows : constant Natural :=
        Natural'Max (1, Editor.State.Line_Count (The_Editor.State));
      Row_Count     : constant Natural :=
        Natural'Max
          (1, Editor.Folding.Visible_Row_Count
                (The_Editor.State.Folding, Document_Rows));
      Scrollbars    : constant Editor.Scrollbars.Scrollbar_Config :=
        Editor.Scrollbars.Current;
      Raw_Effective_H : constant Natural :=
        Editor.Scrollbars.Effective_Viewport_Height
          (Editor.View.Viewport_Height, Scrollbars);
      Effective_H   : constant Natural :=
        (if Raw_Effective_H = 0 then Editor.View.Viewport_Height else Raw_Effective_H);
      Minimap_H     : constant Natural :=
        Natural'Max
          (Editor.Layout.Cell_H,
           Editor.Layout.Text_Viewport_Height (Layout, Effective_H));
      Viewport_Rows : constant Natural :=
        Natural'Max (1, Editor.Layout.Visible_Row_Count (Layout, Effective_H));
      Target_Document_Row : Natural :=
        Editor.Minimap.Row_For_Y
          (Y                => Y,
           Total_Line_Count => Document_Rows,
           Layout           => Layout,
           Viewport_Height  => Minimap_H,
           Config           => Config);
      Desired_Row   : Natural := 0;
      Found         : Boolean := False;
   begin
      if Target_Document_Row >= Document_Rows then
         Target_Document_Row := Document_Rows - 1;
      end if;

      if Editor.Folding.Is_Row_Hidden
           (The_Editor.State.Folding, Target_Document_Row)
      then
         Target_Document_Row :=
           Editor.Folding.Fold_Start_For_Hidden_Row
             (The_Editor.State.Folding, Target_Document_Row, Found);
      end if;

      Desired_Row :=
        Editor.Folding.Document_Row_To_Visible_Row
          (The_Editor.State.Folding, Target_Document_Row, Found);

      if not Found then
         Desired_Row := 0;
      end if;

      Editor.View.Set_Scroll_Y_Clamped
        (Row_Count      => Row_Count,
         Viewport_Rows  => Viewport_Rows,
         Desired_Scroll => Desired_Row);
      Editor.Render_Cache.Invalidate_All;
   end Scroll_From_Minimap_Y;

   function Handle_Minimap_Pointer
     (Cmd : Editor.Commands.Command) return Boolean
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Config : constant Editor.Minimap.Minimap_Config := Editor.Minimap.Current;
      Scrollbars : constant Editor.Scrollbars.Scrollbar_Config :=
        Editor.Scrollbars.Current;
      Effective_W : constant Natural :=
        Editor.Scrollbars.Effective_Viewport_Width
          (Editor.View.Viewport_Width, Scrollbars);
      Raw_Effective_H : constant Natural :=
        Editor.Scrollbars.Effective_Viewport_Height
          (Editor.View.Viewport_Height, Scrollbars);
      Effective_H : constant Natural :=
        Natural'Max
          (Editor.Layout.Cell_H,
           Editor.Layout.Text_Viewport_Height
             (Layout,
              (if Raw_Effective_H = 0 then Editor.View.Viewport_Height else Raw_Effective_H)));
   begin
      if not Is_Minimap_Pointer_Command (Cmd.Kind) then
         Minimap_Drag_Active := False;
         return False;
      end if;

      if not Config.Enabled or else not Editor.Settings.Show_Minimap then
         Minimap_Drag_Active := False;
         return False;
      end if;

      if Is_Minimap_Drag_Command (Cmd.Kind) and then Minimap_Drag_Active then
         Scroll_From_Minimap_Y (Cmd.Click_Y);
         return True;
      end if;

      Minimap_Drag_Active := False;

      if Editor.Minimap.Contains_Point
           (X               => Cmd.Click_X,
            Y               => Cmd.Click_Y,
            Layout          => Layout,
            Viewport_Width  => Effective_W,
            Viewport_Height => Effective_H,
            Config          => Config)
      then
         Minimap_Drag_Active := True;
         Scroll_From_Minimap_Y (Cmd.Click_Y);
         return True;
      end if;

      return False;
   end Handle_Minimap_Pointer;


   function Is_Scrollbar_Pointer_Command
     (Kind : Editor.Commands.Command_Kind) return Boolean
   is
   begin
      return Is_Minimap_Pointer_Command (Kind);
   end Is_Scrollbar_Pointer_Command;

   function Is_Scrollbar_Drag_Command
     (Kind : Editor.Commands.Command_Kind) return Boolean
   is
   begin
      return Is_Minimap_Drag_Command (Kind);
   end Is_Scrollbar_Drag_Command;

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

   procedure Scroll_From_Vertical_Thumb
     (Y : Natural)
   is
      Layout        : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Config        : constant Editor.Scrollbars.Scrollbar_Config := Editor.Scrollbars.Current;
      Row_Count     : constant Natural :=
        Natural'Max
          (1, Editor.Folding.Visible_Row_Count
                (The_Editor.State.Folding, Editor.State.Line_Count (The_Editor.State)));
      Effective_H   : constant Natural :=
        Editor.Scrollbars.Effective_Viewport_Height
          (Editor.View.Viewport_Height, Config);
      Viewport_Rows : constant Natural :=
        Editor.Layout.Visible_Row_Count (Layout, Effective_H);
      Geometry      : constant Editor.Scrollbars.Scrollbar_Geometry :=
        Editor.Scrollbars.Vertical_Geometry
          (Layout          => Layout,
           Viewport_Width  => Editor.View.Viewport_Width,
           Viewport_Height => Editor.Layout.Text_Viewport_Height
                                (Layout, Editor.View.Viewport_Height),
           Total_Rows      => Row_Count,
           Visible_Rows    => Viewport_Rows,
           Scroll_Y        => Editor.View.Scroll_Y,
           Config          => Config);
      Desired_Top   : Natural := 0;
      Desired_Row   : Natural := 0;
   begin
      if Y > Scrollbar_Drag.Drag_Offset then
         Desired_Top := Y - Scrollbar_Drag.Drag_Offset;
      else
         Desired_Top := 0;
      end if;

      Desired_Row :=
        Editor.Scrollbars.Scroll_Y_For_Thumb_Y
          (Geometry        => Geometry,
           Total_Rows      => Row_Count,
           Visible_Rows    => Viewport_Rows,
           Desired_Thumb_Y => Desired_Top);

      Editor.View.Set_Scroll_Y_Clamped
        (Row_Count      => Row_Count,
         Viewport_Rows  => Viewport_Rows,
         Desired_Scroll => Desired_Row);
      Editor.Render_Cache.Invalidate_All;
   end Scroll_From_Vertical_Thumb;

   procedure Scroll_From_Horizontal_Thumb
     (X : Natural)
   is
      Layout        : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Config        : constant Editor.Scrollbars.Scrollbar_Config := Editor.Scrollbars.Current;
      Minimap       : constant Editor.Minimap.Minimap_Config := Editor.Minimap.Current;
      Effective_W   : constant Natural :=
        Editor.Scrollbars.Effective_Viewport_Width
          (Editor.View.Viewport_Width, Config);
      Effective_Minimap_Enabled : constant Boolean :=
        Editor.Settings.Show_Minimap and then Minimap.Enabled;
      Line_Count    : constant Natural :=
        Natural'Max (1, Editor.State.Line_Count (The_Editor.State));
      Text_Left     : constant Natural :=
        Editor.Layout.Text_Origin_X (Layout, Line_Count);
      Text_W        : constant Natural :=
        (if Effective_Minimap_Enabled then
            Editor.Layout.Text_Viewport_Width
              (Layout, Line_Count, Effective_W,
               Minimap.Enabled, Minimap.Width,
               Minimap.Padding_Left, Minimap.Padding_Right)
         else
            Editor.Layout.Text_Viewport_Width (Layout, Line_Count, Effective_W));
      Visible_Cols  : constant Natural := Text_W / Editor.Layout.Cell_W;
      Total_Cols    : constant Natural := Max_Visible_Line_Length;
      Geometry      : constant Editor.Scrollbars.Scrollbar_Geometry :=
        Editor.Scrollbars.Horizontal_Geometry
          (Layout          => Layout,
           Text_Left       => Text_Left,
           Text_Width      => Text_W,
           Viewport_Height => Editor.Layout.Text_Viewport_Height
                                (Layout, Editor.View.Viewport_Height),
           Total_Cols      => Total_Cols,
           Visible_Cols    => Visible_Cols,
           Scroll_X        => Editor.View.Scroll_X,
           Config          => Config);
      Desired_Left : Natural := 0;
      Desired_Col  : Natural := 0;
   begin
      if X > Scrollbar_Drag.Drag_Offset then
         Desired_Left := X - Scrollbar_Drag.Drag_Offset;
      else
         Desired_Left := 0;
      end if;

      Desired_Col :=
        Editor.Scrollbars.Scroll_X_For_Thumb_X
          (Geometry        => Geometry,
           Total_Cols      => Total_Cols,
           Visible_Cols    => Visible_Cols,
           Desired_Thumb_X => Desired_Left);

      Editor.View.Set_Scroll_X_Clamped
        (Column_Count   => Total_Cols,
         Viewport_Cols  => Visible_Cols,
         Desired_Scroll => Desired_Col);
      Editor.Render_Cache.Invalidate_All;
   end Scroll_From_Horizontal_Thumb;

   function Handle_Scrollbar_Pointer
     (Cmd : Editor.Commands.Command) return Boolean
   is
      Layout      : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Config      : constant Editor.Scrollbars.Scrollbar_Config := Editor.Scrollbars.Current;
      Row_Count   : constant Natural :=
        Natural'Max
          (1, Editor.Folding.Visible_Row_Count
                (The_Editor.State.Folding, Editor.State.Line_Count (The_Editor.State)));
      Effective_H : constant Natural :=
        Editor.Scrollbars.Effective_Viewport_Height
          (Editor.View.Viewport_Height, Config);
      Viewport_Rows : constant Natural :=
        Editor.Layout.Visible_Row_Count (Layout, Effective_H);
      Vertical    : constant Editor.Scrollbars.Scrollbar_Geometry :=
        Editor.Scrollbars.Vertical_Geometry
          (Layout          => Layout,
           Viewport_Width  => Editor.View.Viewport_Width,
           Viewport_Height => Editor.Layout.Text_Viewport_Height
                                (Layout, Editor.View.Viewport_Height),
           Total_Rows      => Row_Count,
           Visible_Rows    => Viewport_Rows,
           Scroll_Y        => Editor.View.Scroll_Y,
           Config          => Config);
      Minimap     : constant Editor.Minimap.Minimap_Config := Editor.Minimap.Current;
      Effective_W : constant Natural :=
        Editor.Scrollbars.Effective_Viewport_Width
          (Editor.View.Viewport_Width, Config);
      Effective_Minimap_Enabled : constant Boolean :=
        Editor.Settings.Show_Minimap and then Minimap.Enabled;
      Line_Count  : constant Natural :=
        Natural'Max (1, Editor.State.Line_Count (The_Editor.State));
      Text_Left   : constant Natural := Editor.Layout.Text_Origin_X (Layout, Line_Count);
      Text_W      : constant Natural :=
        (if Effective_Minimap_Enabled then
            Editor.Layout.Text_Viewport_Width
              (Layout, Line_Count, Effective_W,
               Minimap.Enabled, Minimap.Width,
               Minimap.Padding_Left, Minimap.Padding_Right)
         else
            Editor.Layout.Text_Viewport_Width (Layout, Line_Count, Effective_W));
      Visible_Cols : constant Natural := Text_W / Editor.Layout.Cell_W;
      Total_Cols   : constant Natural := Max_Visible_Line_Length;
      Horizontal   : constant Editor.Scrollbars.Scrollbar_Geometry :=
        Editor.Scrollbars.Horizontal_Geometry
          (Layout          => Layout,
           Text_Left       => Text_Left,
           Text_Width      => Text_W,
           Viewport_Height => Editor.Layout.Text_Viewport_Height
                                (Layout, Editor.View.Viewport_Height),
           Total_Cols      => Total_Cols,
           Visible_Cols    => Visible_Cols,
           Scroll_X        => Editor.View.Scroll_X,
           Config          => Config);
      Hit : Editor.Scrollbars.Scrollbar_Hit;
   begin
      if not Is_Scrollbar_Pointer_Command (Cmd.Kind) then
         Scrollbar_Drag.Active := False;
         return False;
      end if;

      if not Config.Enabled then
         Scrollbar_Drag.Active := False;
         return False;
      end if;

      if Is_Scrollbar_Drag_Command (Cmd.Kind) and then Scrollbar_Drag.Active then
         case Scrollbar_Drag.Orientation is
            when Editor.Scrollbars.Vertical_Scrollbar =>
               Scroll_From_Vertical_Thumb (Cmd.Click_Y);
            when Editor.Scrollbars.Horizontal_Scrollbar =>
               Scroll_From_Horizontal_Thumb (Cmd.Click_X);
         end case;
         return True;
      end if;

      Scrollbar_Drag.Active := False;

      Hit := Editor.Scrollbars.Hit_Test (Vertical, Cmd.Click_X, Cmd.Click_Y);
      if Hit = Editor.Scrollbars.Scrollbar_Thumb_Hit then
         Scrollbar_Drag.Active := True;
         Scrollbar_Drag.Orientation := Editor.Scrollbars.Vertical_Scrollbar;
         if Cmd.Click_Y > Natural (Vertical.Thumb.Y) then
            Scrollbar_Drag.Drag_Offset := Cmd.Click_Y - Natural (Vertical.Thumb.Y);
         else
            Scrollbar_Drag.Drag_Offset := 0;
         end if;
         return True;
      elsif Hit = Editor.Scrollbars.Scrollbar_Track_Hit then
         if Float (Cmd.Click_Y) < Vertical.Thumb.Y then
            Editor.View.Set_Scroll_Y_Clamped
              (Row_Count, Viewport_Rows,
               (if Editor.View.Scroll_Y > Viewport_Rows
                then Editor.View.Scroll_Y - Viewport_Rows
                else 0));
         else
            Editor.View.Set_Scroll_Y_Clamped
              (Row_Count, Viewport_Rows,
               Editor.View.Scroll_Y + Viewport_Rows);
         end if;
         Editor.Render_Cache.Invalidate_All;
         return True;
      end if;

      Hit := Editor.Scrollbars.Hit_Test (Horizontal, Cmd.Click_X, Cmd.Click_Y);
      if Hit = Editor.Scrollbars.Scrollbar_Thumb_Hit then
         Scrollbar_Drag.Active := True;
         Scrollbar_Drag.Orientation := Editor.Scrollbars.Horizontal_Scrollbar;
         if Cmd.Click_X > Natural (Horizontal.Thumb.X) then
            Scrollbar_Drag.Drag_Offset := Cmd.Click_X - Natural (Horizontal.Thumb.X);
         else
            Scrollbar_Drag.Drag_Offset := 0;
         end if;
         return True;
      elsif Hit = Editor.Scrollbars.Scrollbar_Track_Hit then
         if Float (Cmd.Click_X) < Horizontal.Thumb.X then
            Editor.View.Set_Scroll_X_Clamped
              (Total_Cols, Visible_Cols,
               (if Editor.View.Scroll_X > Visible_Cols
                then Editor.View.Scroll_X - Visible_Cols
                else 0));
         else
            Editor.View.Set_Scroll_X_Clamped
              (Total_Cols, Visible_Cols,
               Editor.View.Scroll_X + Visible_Cols);
         end if;
         Editor.Render_Cache.Invalidate_All;
         return True;
      end if;

      return False;
   end Handle_Scrollbar_Pointer;



   function Is_Gutter_Pointer_Command
     (Kind : Editor.Commands.Command_Kind) return Boolean
   is
   begin
      return Kind = Editor.Commands.Move_To_Point
        or else Kind = Editor.Commands.Pointer_Hover
        or else Kind = Editor.Commands.Drag_To_Point
        or else Kind = Editor.Commands.Start_Rectangle_Selection
        or else Kind = Editor.Commands.Drag_Rectangle_To_Point
        or else Kind = Editor.Commands.Add_Caret_At_Point
        or else Kind = Editor.Commands.Select_Word_At_Point
        or else Kind = Editor.Commands.Select_Line_At_Point;
   end Is_Gutter_Pointer_Command;

   function Is_Gutter_Drag_Command
     (Kind : Editor.Commands.Command_Kind) return Boolean
   is
   begin
      return Kind = Editor.Commands.Drag_To_Point
        or else Kind = Editor.Commands.Drag_Rectangle_To_Point;
   end Is_Gutter_Drag_Command;

   procedure Select_Gutter_Line_Range
     (Anchor_Row : Natural;
      Target_Row : Natural)
   is
      New_Caret : Editor.Cursors.Cursor_Index := 0;
      New_Preferred_Column : Natural := 0;
   begin
      Editor.Executor.Navigation.Select_Line_Range
        (S                    => The_Editor.State,
         Anchor_Row           => Anchor_Row,
         Target_Row           => Target_Row,
         New_Caret            => New_Caret,
         New_Preferred_Column => New_Preferred_Column);
      The_Editor.State.Preferred_Column := New_Preferred_Column;
      Editor.Render_Cache.Invalidate_All;
   end Select_Gutter_Line_Range;

   procedure Execute_Gutter_Marker_Action
     (Row    : Natural;
      Action : Editor.Gutter_Markers.Gutter_Marker_Action)
   is
   begin
      case Action is
         when Editor.Gutter_Markers.No_Marker_Action =>
            null;

         when Editor.Gutter_Markers.Toggle_Bookmark_Action =>
            Editor.Executor.Bookmark_Commands.Execute_Toggle_Bookmark_At_Row
              (The_Editor.State, Row);

         when Editor.Gutter_Markers.Select_Diagnostic_Action =>
            Editor.Executor.Diagnostics_Commands.Execute_Jump_To_Diagnostic_On_Row
              (The_Editor.State, Row);

         when Editor.Gutter_Markers.Acknowledge_Dirty_Line_Action =>
            null;
      end case;
   end Execute_Gutter_Marker_Action;

   procedure Add_Effective_Dirty_Marker
     (Markers : in out Editor.Gutter_Markers.Gutter_Marker_State;
      Row     : Natural)
   is
   begin
      case Editor.Dirty_Lines.Kind_For_Row (The_Editor.State.Dirty_Lines, Row) is
         when Editor.Dirty_Lines.Added_Line =>
            Editor.Gutter_Markers.Add_Marker
              (Markers, Row, Editor.Gutter_Markers.Added_Line_Marker);
         when Editor.Dirty_Lines.Modified_Line =>
            Editor.Gutter_Markers.Add_Marker
              (Markers, Row, Editor.Gutter_Markers.Modified_Line_Marker);
         when Editor.Dirty_Lines.Clean_Line =>
            null;
      end case;
   end Add_Effective_Dirty_Marker;

   function Handle_Gutter_Pointer
     (Cmd : Editor.Commands.Command) return Boolean
   is
      Layout    : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Doc_Count : constant Natural := Editor.State.Line_Count (The_Editor.State);
      Hit       : Editor.Gutter.Gutter_Hit_Result;
      Zone      : Editor.Gutter.Gutter_Zone;
      Doc_Row   : Natural := 0;
      Found     : Boolean := False;
      Kind      : Editor.Gutter_Markers.Gutter_Marker_Kind;
      Action    : Editor.Gutter_Markers.Gutter_Marker_Action :=
        Editor.Gutter_Markers.No_Marker_Action;
   begin
      if not Is_Gutter_Pointer_Command (Cmd.Kind) then
         Gutter_Line_Selection.Active := False;
         Editor.State.Clear_Gutter_Marker_Hover (The_Editor.State);
         return False;
      end if;

      if Is_Gutter_Drag_Command (Cmd.Kind) and then Gutter_Line_Selection.Active then
         Doc_Row := Editor.Gutter.Document_Row_For_Y
           (Y             => Cmd.Click_Y,
            Layout        => Layout,
            Scroll_Y      => Editor.View.Scroll_Y,
            Folding       => The_Editor.State.Folding,
            Document_Rows => Doc_Count);
         Select_Gutter_Line_Range (Gutter_Line_Selection.Anchor_Row, Doc_Row);
         return True;
      end if;

      Gutter_Line_Selection.Active := False;

      Hit := Editor.Gutter.Hit_Test_Result
        (X               => Cmd.Click_X,
         Y               => Cmd.Click_Y,
         Layout          => Layout,
         Line_Count      => Doc_Count,
         Viewport_Height => Editor.View.Viewport_Height,
         Scroll_Y        => Editor.View.Scroll_Y,
         Folding         => The_Editor.State.Folding);
      Zone := Hit.Zone;
      Doc_Row := Hit.Row;

      if Zone = Editor.Gutter.Marker_Zone then

         declare
            Effective_Markers : Editor.Gutter_Markers.Gutter_Marker_State :=
              The_Editor.State.Gutter_Markers;
         begin
            Add_Effective_Dirty_Marker (Effective_Markers, Doc_Row);

            for D of The_Editor.State.Diagnostics loop
               if Editor.State.Row_For_Index (The_Editor.State, D.Start_Index) = Doc_Row then
                  case D.Severity is
                     when Editor.Diagnostics.Error =>
                        Editor.Gutter_Markers.Add_Marker
                          (Effective_Markers, Doc_Row,
                           Editor.Gutter_Markers.Diagnostic_Error_Marker);
                     when Editor.Diagnostics.Warning =>
                        Editor.Gutter_Markers.Add_Marker
                          (Effective_Markers, Doc_Row,
                           Editor.Gutter_Markers.Diagnostic_Warning_Marker);
                     when others =>
                        null;
                  end case;
               end if;
            end loop;

            Kind := Editor.Gutter_Markers.Dominant_Marker_For_Row
              (State => Effective_Markers,
               Row   => Doc_Row,
               Found => Found);
         end;

         if Found then
            Editor.State.Set_Gutter_Marker_Hover (The_Editor.State, Doc_Row, Kind);
         else
            Editor.State.Clear_Gutter_Marker_Hover (The_Editor.State);
         end if;

         if Cmd.Kind = Editor.Commands.Pointer_Hover then
            return True;
         end if;
      else
         Editor.State.Clear_Gutter_Marker_Hover (The_Editor.State);

         if Cmd.Kind = Editor.Commands.Pointer_Hover then
            return True;
         end if;
      end if;

      case Zone is
         when Editor.Gutter.Outside_Gutter =>
            return False;

         when Editor.Gutter.Marker_Zone =>
            if Cmd.Kind /= Editor.Commands.Move_To_Point then
               return True;
            end if;

            if Found then
               Action := Editor.Gutter_Markers.Action_For_Marker (Kind);
            else
               Action := Editor.Gutter_Markers.Toggle_Bookmark_Action;
            end if;

            Execute_Gutter_Marker_Action (Doc_Row, Action);

            declare
               Effective_Markers : Editor.Gutter_Markers.Gutter_Marker_State :=
                 The_Editor.State.Gutter_Markers;
               Still_Found : Boolean := False;
               Still_Kind  : Editor.Gutter_Markers.Gutter_Marker_Kind;
            begin
               Add_Effective_Dirty_Marker (Effective_Markers, Doc_Row);

               for D of The_Editor.State.Diagnostics loop
                  if Editor.State.Row_For_Index (The_Editor.State, D.Start_Index) = Doc_Row then
                     case D.Severity is
                        when Editor.Diagnostics.Error =>
                           Editor.Gutter_Markers.Add_Marker
                             (Effective_Markers, Doc_Row,
                              Editor.Gutter_Markers.Diagnostic_Error_Marker);
                        when Editor.Diagnostics.Warning =>
                           Editor.Gutter_Markers.Add_Marker
                             (Effective_Markers, Doc_Row,
                              Editor.Gutter_Markers.Diagnostic_Warning_Marker);
                        when others =>
                           null;
                     end case;
                  end if;
               end loop;

               Still_Kind := Editor.Gutter_Markers.Dominant_Marker_For_Row
                 (State => Effective_Markers,
                  Row   => Doc_Row,
                  Found => Still_Found);

               if Still_Found then
                  Editor.State.Set_Gutter_Marker_Hover
                    (The_Editor.State, Doc_Row, Still_Kind);
               else
                  Editor.State.Clear_Gutter_Marker_Hover (The_Editor.State);
               end if;
            end;

            Gutter_Line_Selection.Active := False;
            return True;

         when Editor.Gutter.Fold_Marker_Zone =>
            if Cmd.Kind = Editor.Commands.Move_To_Point
              and then Editor.Folding.Has_Fold_Start (The_Editor.State.Folding, Doc_Row)
            then
               Editor.Folding.Toggle_Fold_At_Row (The_Editor.State.Folding, Doc_Row);
               Editor.Render_Cache.Invalidate_All;
               return True;
            end if;

            --  Empty fold cells remain part of the selectable gutter so a
            --  line-number click is not lost merely because the row has no
            --  fold marker.
            if Cmd.Kind /= Editor.Commands.Move_To_Point then
               return True;
            end if;

            Gutter_Line_Selection.Active := True;
            Gutter_Line_Selection.Anchor_Row := Doc_Row;
            Select_Gutter_Line_Range (Doc_Row, Doc_Row);
            return True;

         when Editor.Gutter.Line_Number_Zone =>
            if Cmd.Kind /= Editor.Commands.Move_To_Point
              and then Cmd.Kind /= Editor.Commands.Select_Line_At_Point
            then
               return True;
            end if;

            Gutter_Line_Selection.Active := True;
            Gutter_Line_Selection.Anchor_Row := Doc_Row;
            Select_Gutter_Line_Range (Doc_Row, Doc_Row);
            return True;
      end case;
   end Handle_Gutter_Pointer;



   function Handle_Message_Overlay_Pointer
     (Cmd : Editor.Commands.Command) return Boolean
   is
      pragma Unreferenced (Cmd);
   begin
      --  transient messages are passive, non-modal feedback.
      --  They must not capture pointer input or disturb editor/panel/overlay
      --  focus.  Clicks route normally through lower-priority surfaces.
      return False;
   end Handle_Message_Overlay_Pointer;



   function Handle_Pending_Transition_Bar_Pointer
     (Cmd : Editor.Commands.Command) return Boolean
   is
      Layout_Config : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Config : constant Editor.Pending_Transition_Bar.Pending_Bar_Config := (others => <>);
      Snapshot : constant Editor.Pending_Transition_Bar.Pending_Bar_Snapshot :=
        Editor.Pending_Transition_Bar.Build_Snapshot
          (The_Editor.State.Pending_Transitions, Config);
      Status_Y : constant Integer :=
        Editor.Layout.Status_Bar_Y (Layout_Config, Editor.View.Viewport_Height);
      Bar_Y : constant Integer :=
        Integer'Max (Layout_Config.Origin_Y, Status_Y - Integer (Editor.Layout.Cell_H));
      Bar_Layout : Editor.Pending_Transition_Bar.Pending_Bar_Layout;
      Hit : Editor.Pending_Transition_Bar.Pending_Bar_Hit_Result;
   begin
      if Cmd.Kind /= Editor.Commands.Move_To_Point
        and then Cmd.Kind /= Editor.Commands.Pointer_Hover
      then
         return False;
      end if;

      if not Editor.Pending_Transition_Bar.Is_Visible (Snapshot) then
         return False;
      end if;

      Bar_Layout := Editor.Pending_Transition_Bar.Layout
        (Snapshot => Snapshot,
         Bounds_X => Layout_Config.Origin_X,
         Bounds_Y => Bar_Y,
         Bounds_W => Integer (Editor.View.Viewport_Width),
         Cell_W   => Editor.Layout.Cell_W,
         Cell_H   => Editor.Layout.Cell_H);

      Hit := Editor.Pending_Transition_Bar.Hit_Test
        (Snapshot, Bar_Layout, Integer (Cmd.Click_X), Integer (Cmd.Click_Y));

      case Hit.Zone is
         when Editor.Pending_Transition_Bar.Outside_Pending_Bar =>
            return False;

         when Editor.Pending_Transition_Bar.Pending_Bar_Background =>
            Minimap_Drag_Active := False;
            Scrollbar_Drag.Active := False;
            Gutter_Line_Selection.Active := False;
            Editor.State.Clear_Gutter_Marker_Hover (The_Editor.State);
            return True;

         when Editor.Pending_Transition_Bar.Pending_Bar_Action_Zone =>
            Minimap_Drag_Active := False;
            Scrollbar_Drag.Active := False;
            Gutter_Line_Selection.Active := False;
            Editor.State.Clear_Gutter_Marker_Hover (The_Editor.State);
            if Cmd.Kind = Editor.Commands.Move_To_Point then
               Execute_Command_Id
                 (Editor.Pending_Transition_Bar.Command_For_Action (Hit.Action));
               Editor.Render_Cache.Invalidate_All;
            end if;
            return True;
      end case;
   end Handle_Pending_Transition_Bar_Pointer;


   type Build_UI_Panel_Input_Projection is record
      Snapshot : Editor.Build_UI.Build_UI_Render_Snapshot;
      Action_Count : Natural := 0;
      Suppressed_Count : Natural := 0;
      Displayed_Suppressed_Count : Natural := 0;
      Suppressed_Top_Row : Natural := 1;
      Geometry : Editor.Build_UI_Panel_Layout.Build_UI_Panel_Geometry;
      Visible_Rows : Natural := 0;
      Visible_Action_Rows : Natural := 0;
      Action_Top_Row : Natural := 1;
   end record;

   function Current_Build_UI_Panel_Input_Projection
     return Build_UI_Panel_Input_Projection
   is
      Layout_Config : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Snapshot : constant Editor.Build_UI.Build_UI_Render_Snapshot :=
        Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (The_Editor.State);
      Action_Count : constant Natural := Natural (Snapshot.Actions.Length);
      Suppressed_Count : constant Natural :=
        Editor.Feature_Diagnostics.Suppressed_Diagnostic_Count
          (The_Editor.State.Feature_Diagnostics);
      Text_Viewport_Height : constant Natural :=
        Editor.Layout.Text_Viewport_Height
          (Layout_Config, Editor.View.Viewport_Height);
      Displayed_Suppressed_Count : constant Natural :=
        Editor.Build_UI_Panel_Layout.Displayed_Suppressed_Row_Count
          (Text_Viewport_Height => Text_Viewport_Height,
           Cell_H               => Editor.Layout.Cell_H,
           Action_Count         => Action_Count,
           Suppressed_Count     => Suppressed_Count);
      Suppressed_Top_Row : constant Natural :=
        Editor.Feature_Diagnostics.Suppressed_Top_Row
          (The_Editor.State.Feature_Diagnostics, Displayed_Suppressed_Count);
      Geometry : constant Editor.Build_UI_Panel_Layout.Build_UI_Panel_Geometry :=
        Editor.Build_UI_Panel_Layout.Layout
          (Viewport_Width       => Editor.View.Viewport_Width,
           Text_Viewport_Y      => Natural (Editor.Layout.Text_Viewport_Y (Layout_Config)),
           Text_Viewport_Height => Text_Viewport_Height,
           Cell_H               => Editor.Layout.Cell_H,
           Action_Count         => Action_Count,
           Suppressed_Count     => Displayed_Suppressed_Count);
      Visible_Rows : constant Natural :=
        Editor.Build_UI_Panel_Layout.Visible_Row_Count
          (Geometry, Editor.Layout.Cell_H);
      Visible_Action_Rows : constant Natural :=
        (if Visible_Rows > Geometry.Action_Start_Row
         then Natural'Min (Action_Count, Visible_Rows - Geometry.Action_Start_Row)
         else 0);
      Action_Top_Row : constant Natural :=
        Editor.Build_UI.Action_Top_Row
          (The_Editor.State.Build_UI, Action_Count, Visible_Action_Rows);
   begin
      return
        (Snapshot                   => Snapshot,
         Action_Count               => Action_Count,
         Suppressed_Count           => Suppressed_Count,
         Displayed_Suppressed_Count => Displayed_Suppressed_Count,
         Suppressed_Top_Row         => Suppressed_Top_Row,
         Geometry                   => Geometry,
         Visible_Rows               => Visible_Rows,
         Visible_Action_Rows        => Visible_Action_Rows,
         Action_Top_Row             => Action_Top_Row);
   end Current_Build_UI_Panel_Input_Projection;


   function Handle_Build_UI_Panel_Pointer
     (Cmd : Editor.Commands.Command) return Boolean
   is
      Projection : constant Build_UI_Panel_Input_Projection :=
        Current_Build_UI_Panel_Input_Projection;
      Hit : Editor.Build_UI_Panel_Layout.Build_UI_Panel_Hit;
   begin
      if Cmd.Kind /= Editor.Commands.Move_To_Point
        and then Cmd.Kind /= Editor.Commands.Pointer_Hover
      then
         return False;
      end if;

      if not Projection.Snapshot.Visible then
         return False;
      end if;

      Hit := Editor.Build_UI_Panel_Layout.Hit_Test
        (Projection.Geometry, Editor.Layout.Cell_H,
         Integer (Cmd.Click_X), Integer (Cmd.Click_Y));

      if Hit.Zone = Editor.Build_UI_Panel_Layout.Outside_Build_UI_Panel then
         return False;
      end if;

      Minimap_Drag_Active := False;
      Scrollbar_Drag.Active := False;
      Gutter_Line_Selection.Active := False;
      Editor.State.Clear_Gutter_Marker_Hover (The_Editor.State);

      if Cmd.Kind = Editor.Commands.Pointer_Hover then
         return True;
      end if;

      if Hit.Zone = Editor.Build_UI_Panel_Layout.Build_UI_Panel_Action_Row
        and then Hit.Row in 1 .. Projection.Visible_Action_Rows
      then
         declare
            Action_Row : constant Natural := Projection.Action_Top_Row + Hit.Row - 1;
            Action : constant Editor.Build_UI.Build_UI_Action_Row :=
              Projection.Snapshot.Actions.Element (Action_Row - 1);
            Found : Boolean := False;
            Id : Editor.Commands.Command_Id := Editor.Commands.No_Command;
            Reason : constant String := To_String (Action.Disabled_Reason);
         begin
            Editor.Build_UI.Set_Selected_Action_Row
              (The_Editor.State.Build_UI, Action_Row, Projection.Action_Count);

            if not Action.Enabled then
               if Reason'Length > 0 then
                  Report_Info (Reason);
               else
                  Report_Info ("Command unavailable");
               end if;
            else
               Id := Editor.Commands.Command_Id_From_Stable_Name
                 (To_String (Action.Command_Name), Found);
               if Found and then Id /= Editor.Commands.No_Command then
                  if Id = Editor.Commands.Command_Diagnostic_Apply_Quick_Fix
                    and then Action.Quick_Fix_Action_Index > 0
                  then
                     declare
                        Result : constant Editor.Command_Execution.Command_Execution_Result :=
                          Editor.Build_UI_Actions.Build_UI_Apply_Diagnostic_Quick_Fix
                            (The_Editor.State,
                             Action.Quick_Fix_Action_Index,
                             Action.Diagnostic_Index);
                        pragma Unreferenced (Result);
                     begin
                        null;
                     end;
                  else
                     Execute_Command_Id (Id);
                  end if;
               end if;
            end if;
            Editor.Render_Cache.Invalidate_All;
         end;
      elsif Hit.Zone = Editor.Build_UI_Panel_Layout.Build_UI_Panel_Suppressed_Row
        and then Hit.Row in 1 .. Projection.Displayed_Suppressed_Count
      then
         Editor.Feature_Diagnostics.Select_Suppressed_Diagnostic
           (The_Editor.State.Feature_Diagnostics,
            Projection.Suppressed_Top_Row + Hit.Row - 1);
         Editor.Feature_Diagnostics.Ensure_Selected_Suppressed_Diagnostic_Visible
           (The_Editor.State.Feature_Diagnostics,
            Projection.Displayed_Suppressed_Count);
         Editor.Render_Cache.Invalidate_All;
      end if;

      return True;
   end Handle_Build_UI_Panel_Pointer;


   function Handle_Tab_Bar_Pointer
     (Cmd : Editor.Commands.Command) return Boolean
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Hit : Editor.Tab_Bar.Tab_Hit_Result;
      Registry : Editor.Buffers.Buffer_Registry;
   begin
      if not Is_Minimap_Pointer_Command (Cmd.Kind)
        and then Cmd.Kind /= Editor.Commands.Pointer_Hover
      then
         return False;
      end if;

      if not Editor.Tab_Bar.Enabled (Layout.Tab_Bar)
        or else Integer (Cmd.Click_Y) < Integer (Editor.Layout.Tab_Bar_Y (Layout))
        or else Integer (Cmd.Click_Y) >=
          Integer (Editor.Layout.Tab_Bar_Y (Layout)
                   + Editor.Layout.Tab_Bar_Height (Layout))
      then
         return False;
      end if;

      Editor.Buffers.Ensure_Global_Registry (The_Editor.State);
      Registry := Editor.Buffers.Global_Registry_For_UI;

      declare
         Count : constant Natural := Editor.Buffers.Buffer_Count (Registry);
         Summaries : Editor.Tab_Bar.Tab_Buffer_Summary_Array (1 .. Count);
      begin
         for I in Summaries'Range loop
            Summaries (I) := Editor.Buffers.Summary_At (Registry, I);
         end loop;

         Hit := Editor.Tab_Bar.Hit_Test
        (Config         => Layout.Tab_Bar,
         Buffers        => Summaries,
         Viewport_Width => Editor.View.Viewport_Width,
         Cell_W         => Editor.Layout.Cell_W,
         Cell_H         => Editor.Layout.Cell_H,
         X              => Integer (Cmd.Click_X),
         Y              => Integer (Cmd.Click_Y),
         Origin_X       => Layout.Origin_X,
         Origin_Y       => Layout.Origin_Y);
      end;

      case Hit.Zone is
         when Editor.Tab_Bar.Outside_Tab_Bar =>
            return False;

         when Editor.Tab_Bar.Tab_Bar_Background_Zone
            | Editor.Tab_Bar.Tab_Overflow_Zone =>
            Minimap_Drag_Active := False;
            Scrollbar_Drag.Active := False;
            Gutter_Line_Selection.Active := False;
            Editor.State.Clear_Gutter_Marker_Hover (The_Editor.State);
            return True;

         when Editor.Tab_Bar.Tab_Body_Zone =>
            Minimap_Drag_Active := False;
            Scrollbar_Drag.Active := False;
            Gutter_Line_Selection.Active := False;
            Editor.State.Clear_Gutter_Marker_Hover (The_Editor.State);
            if Cmd.Kind = Editor.Commands.Move_To_Point
              and then Hit.Buffer_Id /= Editor.Buffers.No_Buffer
            then
               Editor.Executor.File_Open_Commands.Execute_Switch_Buffer
                 (The_Editor.State, Hit.Buffer_Id);
               Editor.Focus_Management.Restore_Focus_To_Editor
                 (The_Editor.State);
            end if;
            return True;

         when Editor.Tab_Bar.Tab_Close_Zone =>
            Minimap_Drag_Active := False;
            Scrollbar_Drag.Active := False;
            Gutter_Line_Selection.Active := False;
            Editor.State.Clear_Gutter_Marker_Hover (The_Editor.State);
            if Cmd.Kind = Editor.Commands.Move_To_Point
              and then Hit.Buffer_Id /= Editor.Buffers.No_Buffer
            then
               Editor.Executor.Buffer_Close_Commands.Execute_Close_Buffer
                 (The_Editor.State, Hit.Buffer_Id);
               Editor.Focus_Management.Restore_Focus_To_Editor
                 (The_Editor.State);
            end if;
            return True;
      end case;
   end Handle_Tab_Bar_Pointer;

   function Handle_Status_Bar_Pointer
     (Cmd : Editor.Commands.Command) return Boolean
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      if not Is_Minimap_Pointer_Command (Cmd.Kind)
        and then Cmd.Kind /= Editor.Commands.Pointer_Hover
      then
         return False;
      end if;

      if Editor.Layout.Is_In_Status_Bar
           (Config          => Layout,
            X               => Integer (Cmd.Click_X),
            Y               => Integer (Cmd.Click_Y),
            Viewport_Width  => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height)
      then
         Minimap_Drag_Active := False;
         Scrollbar_Drag.Active := False;
         Gutter_Line_Selection.Active := False;
         Editor.State.Clear_Gutter_Marker_Hover (The_Editor.State);
         return True;
      end if;

      return False;
   end Handle_Status_Bar_Pointer;



   function Handle_Panel_Splitter_Pointer
     (Cmd : Editor.Commands.Command) return Boolean
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;

      procedure Synchronize_File_Tree_Width is
      begin
         Editor.File_Tree_View.Set_Current_Width_In_Columns
           (Editor.Panels.Current_Size
              (The_Editor.State.Panels, Editor.Panels.File_Tree_Panel));
         Editor.Panels.Set_Current (The_Editor.State.Panels);
      end Synchronize_File_Tree_Width;
   begin
      if Editor.Panels.Resize_Active (The_Editor.State.Panels) then
         declare
            Resize : constant Editor.Panels.Panel_Resize_State :=
              Editor.Panels.Resize_State (The_Editor.State.Panels);
         begin
            if Cmd.Kind = Editor.Commands.Drag_To_Point
              or else Cmd.Kind = Editor.Commands.Drag_Rectangle_To_Point
            then
               Editor.Panels.Update_Resize
                 (Panels      => The_Editor.State.Panels,
                  Mouse_X     => Integer (Cmd.Click_X),
                  Mouse_Y     => Integer (Cmd.Click_Y),
                  Cell_Width  => Editor.Layout.Cell_W,
                  Cell_Height => Editor.Layout.Cell_H);
               if Resize.Panel = Editor.Panels.File_Tree_Panel then
                  Synchronize_File_Tree_Width;
               else
                  Editor.Panels.Set_Current (The_Editor.State.Panels);
               end if;
               Editor.Render_Cache.Invalidate_All;
               return True;
            elsif Cmd.Kind = Editor.Commands.Pointer_Hover then
               return True;
            else
               Editor.Panels.End_Resize (The_Editor.State.Panels);
               if Resize.Panel = Editor.Panels.File_Tree_Panel then
                  Synchronize_File_Tree_Width;
               else
                  Editor.Panels.Set_Current (The_Editor.State.Panels);
               end if;
               Editor.Render_Cache.Invalidate_All;
               return True;
            end if;
         end;
      end if;

      if Cmd.Kind /= Editor.Commands.Move_To_Point then
         return False;
      end if;

      for Id in Editor.Panels.Panel_Id loop
         if Editor.Layout.Is_In_Panel_Splitter
              (Config          => Layout,
               Id              => Id,
               X               => Integer (Cmd.Click_X),
               Y               => Integer (Cmd.Click_Y),
               Viewport_Width  => Editor.View.Viewport_Width,
               Viewport_Height => Editor.View.Viewport_Height)
         then
            Minimap_Drag_Active := False;
            Scrollbar_Drag.Active := False;
            Gutter_Line_Selection.Active := False;
            Editor.State.Clear_Gutter_Marker_Hover (The_Editor.State);
            Editor.Panels.Begin_Resize
              (Panels  => The_Editor.State.Panels,
               Id      => Id,
               Mouse_X => Integer (Cmd.Click_X),
               Mouse_Y => Integer (Cmd.Click_Y));
            Editor.Panels.Set_Current (The_Editor.State.Panels);
            Editor.Render_Cache.Invalidate_All;
            return True;
         end if;
      end loop;

      return False;
   end Handle_Panel_Splitter_Pointer;

   function Handle_File_Tree_Pointer
     (Cmd : Editor.Commands.Command) return Boolean
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Panel_Rect : constant Editor.Layout.Rect :=
        Editor.Layout.Panel_Rect
          (Layout,
           Editor.Panels.File_Tree_Panel,
           Editor.View.Viewport_Width,
           Editor.View.Viewport_Height);
      Geometry : constant Editor.File_Tree_View.File_Tree_Geometry :=
        (X      => Panel_Rect.X,
         Y      => Panel_Rect.Y,
         Width  => Panel_Rect.Width,
         Height => Panel_Rect.Height);
      Hit : Editor.File_Tree_View.File_Tree_Hit_Result;
   begin
      if not Is_Minimap_Pointer_Command (Cmd.Kind)
        and then Cmd.Kind /= Editor.Commands.Pointer_Hover
      then
         return False;
      end if;

      Hit := Editor.File_Tree_View.Hit_Test
        (Geometry => Geometry,
         Config   => Layout.File_Tree_View,
         Tree     => The_Editor.State.File_Tree,
         State    => The_Editor.State.File_Tree_View,
         X        => Integer (Cmd.Click_X),
         Y        => Integer (Cmd.Click_Y));

      if Hit.Zone /= Editor.File_Tree_View.Outside_File_Tree then
         Minimap_Drag_Active := False;
         Scrollbar_Drag.Active := False;
         Gutter_Line_Selection.Active := False;
         Editor.State.Clear_Gutter_Marker_Hover (The_Editor.State);

         if Cmd.Kind = Editor.Commands.Move_To_Point then
            declare
               Action : constant Editor.File_Tree_View.File_Tree_Action :=
                 Editor.File_Tree_View.Action_For_Hit
                   (The_Editor.State.File_Tree, Hit);
            begin
               Editor.Focus_Management.Set_Focus_Owner
                 (The_Editor.State, Editor.Focus_Management.Focus_File_Tree);
               Editor.Executor.File_Tree_Navigation_Commands.Execute_File_Tree_Action
                 (The_Editor.State, Hit);
               if Action = Editor.File_Tree_View.Open_File_Action then
                  Editor.Focus_Management.Restore_Focus_To_Editor
                    (The_Editor.State);
               end if;
            end;
            Editor.Render_Cache.Invalidate_All;
         end if;

         return True;
      end if;

      return False;
   end Handle_File_Tree_Pointer;

   function Handle_Search_Results_Panel_Pointer
     (Cmd : Editor.Commands.Command) return Boolean
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Config : constant Editor.Search_Results.Search_Results_View_Config := (others => <>);
      Panel  : constant Editor.Layout.Rect :=
        Editor.Layout.Panel_Rect
          (Layout,
           Editor.Panels.Bottom_Panel,
           Editor.View.Viewport_Width,
           Editor.View.Viewport_Height);
      Snapshot : Editor.Search_Results.Search_Results_Snapshot;
      Hit      : Editor.Search_Results.Search_Results_Hit_Result;
   begin
      if not Is_Minimap_Pointer_Command (Cmd.Kind)
        and then Cmd.Kind /= Editor.Commands.Pointer_Hover
      then
         return False;
      end if;

      if not Editor.Panels.Is_Visible (The_Editor.State.Panels, Editor.Panels.Bottom_Panel)
        or else Editor.Panels.Active_Bottom_Content (The_Editor.State.Panels)
          /= Editor.Panels.Search_Results_Content
      then
         return False;
      end if;

      Snapshot := Editor.Search_Results.Visible_Snapshot
        (Editor.Search_Results.Build_Snapshot
           (The_Editor.State.Project_Search, Config,
            Editor.Buffers.Global_Registry_For_UI),
         The_Editor.State.Search_Results_View,
         (if Editor.Layout.Cell_H = 0 then 0 else Panel.Height / Editor.Layout.Cell_H));
      Hit := Editor.Search_Results.Hit_Test
        (Panel_Rect  => Panel,
         Config      => Config,
         Snapshot    => Snapshot,
         Cell_Height => Editor.Layout.Cell_H,
         X           => Integer (Cmd.Click_X),
         Y           => Integer (Cmd.Click_Y));

      if Hit.Zone /= Editor.Search_Results.Outside_Search_Results then
         Minimap_Drag_Active := False;
         Scrollbar_Drag.Active := False;
         Gutter_Line_Selection.Active := False;
         Editor.State.Clear_Gutter_Marker_Hover (The_Editor.State);

         if Cmd.Kind = Editor.Commands.Move_To_Point then
            Editor.Focus_Management.Set_Focus_Owner
              (The_Editor.State,
               Editor.Focus_Management.Focus_Project_Search_Results);
            if Hit.Zone = Editor.Search_Results.Search_Results_Match_Row_Zone then
               Editor.Executor.Project_Search_Result_Commands.Execute_Open_Project_Search_Result
                 (The_Editor.State, Hit.Result_Index);
               Editor.Focus_Management.Restore_Focus_To_Editor
                 (The_Editor.State);
            elsif Hit.Zone = Editor.Search_Results.Search_Results_File_Row_Zone then
               declare
                  Found : Boolean := False;
                  First : constant Natural :=
                    Editor.Search_Results.First_Result_In_File_Group
                      (Snapshot, Hit.Row_Index, Found);
               begin
                  if Found then
                     Editor.Project_Search.Set_Selected_Result_Index
                       (The_Editor.State.Project_Search, First);
                     Editor.Render_Cache.Invalidate_All;
                  end if;
               end;
            end if;
         end if;

         return True;
      end if;

      return False;
   end Handle_Search_Results_Panel_Pointer;

   function Handle_Feature_Panel_Pointer
     (Cmd : Editor.Commands.Command) return Boolean
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Width  : constant Natural :=
        Natural'Min (280, Editor.View.Viewport_Width);
      X0     : constant Integer := Integer (Editor.View.Viewport_Width) - Integer (Width);
      Y0     : constant Integer := Editor.Layout.Text_Viewport_Y (Layout);
      Height : constant Natural :=
        Editor.Layout.Text_Viewport_Height
          (Layout, Editor.View.Viewport_Height);
      Row    : Natural := 0;
      Gen    : constant Natural :=
        Editor.Feature_Panel.Projection_Generation
          (The_Editor.State.Feature_Panel);
   begin
      if not Is_Minimap_Pointer_Command (Cmd.Kind)
        and then Cmd.Kind /= Editor.Commands.Pointer_Hover
      then
         return False;
      end if;

      if not Editor.Feature_Panel.Is_Visible (The_Editor.State.Feature_Panel) then
         return False;
      end if;

      if Integer (Cmd.Click_X) < X0
        or else Integer (Cmd.Click_X) >= X0 + Integer (Width)
        or else Integer (Cmd.Click_Y) < Y0
        or else Integer (Cmd.Click_Y) >= Y0 + Integer (Height)
      then
         return False;
      end if;

      Minimap_Drag_Active := False;
      Scrollbar_Drag.Active := False;
      Gutter_Line_Selection.Active := False;
      Editor.State.Clear_Gutter_Marker_Hover (The_Editor.State);

      if Cmd.Kind = Editor.Commands.Pointer_Hover then
         return True;
      end if;

      if Editor.Layout.Cell_H /= 0
        and then Integer (Cmd.Click_Y) >= Y0 + Integer (Editor.Layout.Cell_H)
      then
         Row := Editor.Feature_Panel.Visible_Row_To_Row_Index
           (The_Editor.State.Feature_Panel,
            Natural ((Integer (Cmd.Click_Y) - Y0) / Integer (Editor.Layout.Cell_H)));
      end if;

      if Cmd.Kind = Editor.Commands.Move_To_Point then
         Editor.Focus_Management.Clear_Transient_Focus_Owners (The_Editor.State);
         Editor.Feature_Panel.Set_Focused (The_Editor.State.Feature_Panel, True);
         case Editor.Feature_Panel.Active_Feature (The_Editor.State.Feature_Panel) is
            when Editor.Feature_Panel.Outline_Feature =>
               declare
                  Result : constant Editor.Executor.Command_Execution_Result :=
                    Editor.Executor.Outline_Commands.Execute_Outline_Row_Click
                      (The_Editor.State, Row, Gen);
                  pragma Unreferenced (Result);
               begin
                  null;
               end;

            when Editor.Feature_Panel.Messages_Feature =>
               declare
                  Result : constant Editor.Executor.Command_Execution_Result :=
                    Editor.Executor.Message_Commands.Execute_Message_Row_Click
                      (The_Editor.State, Row, Gen);
                  pragma Unreferenced (Result);
               begin
                  null;
               end;

            when Editor.Feature_Panel.Search_Results_Feature
               | Editor.Feature_Panel.Diagnostics_Feature =>
               if Row /= 0
                 and then Editor.Feature_Panel.Projection_Row_Index_Is_Valid
                   (The_Editor.State.Feature_Panel, Row)
                 and then Editor.Feature_Panel.Row_Is_Selectable
                   (The_Editor.State.Feature_Panel, Positive (Row))
               then
                  Editor.Feature_Panel.Select_Row
                    (The_Editor.State.Feature_Panel, Row);
                  Editor.Render_Cache.Invalidate_All;
               end if;

            when Editor.Feature_Panel.Unknown_Feature =>
               null;
         end case;
      elsif Cmd.Kind = Editor.Commands.Select_Word_At_Point
        or else Cmd.Kind = Editor.Commands.Select_Line_At_Point
      then
         case Editor.Feature_Panel.Active_Feature (The_Editor.State.Feature_Panel) is
            when Editor.Feature_Panel.Outline_Feature =>
               declare
                  Result : constant Editor.Executor.Command_Execution_Result :=
                    Editor.Executor.Outline_Commands.Execute_Outline_Row_Activation
                      (The_Editor.State, Row, Gen);
                  pragma Unreferenced (Result);
               begin
                  Editor.Focus_Management.Restore_Focus_To_Editor
                    (The_Editor.State);
               end;

            when Editor.Feature_Panel.Messages_Feature =>
               declare
                  Result : constant Editor.Executor.Command_Execution_Result :=
                    Editor.Executor.Message_Commands.Execute_Message_Row_Activation
                      (The_Editor.State, Row, Gen);
                  pragma Unreferenced (Result);
               begin
                  null;
               end;

            when Editor.Feature_Panel.Search_Results_Feature =>
               declare
                  Result : constant Editor.Executor.Command_Execution_Result :=
                    Editor.Executor.Search_Results_Commands
                      .Execute_Search_Result_Row_Activation
                      (The_Editor.State, Row, Gen);
                  pragma Unreferenced (Result);
               begin
                  Editor.Focus_Management.Restore_Focus_To_Editor
                    (The_Editor.State);
               end;

            when Editor.Feature_Panel.Diagnostics_Feature =>
               declare
                  Result : constant Editor.Executor.Command_Execution_Result :=
                    Editor.Executor.Diagnostics_Commands
                      .Execute_Diagnostic_Row_Activation
                        (The_Editor.State, Row, Gen);
                  pragma Unreferenced (Result);
               begin
                  Editor.Focus_Management.Restore_Focus_To_Editor
                    (The_Editor.State);
               end;

            when Editor.Feature_Panel.Unknown_Feature =>
               null;
         end case;
      end if;

      return True;
   end Handle_Feature_Panel_Pointer;

   function Handle_Problems_Panel_Pointer
     (Cmd : Editor.Commands.Command) return Boolean
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Config : constant Editor.Problems.Problems_View_Config :=
        (Enabled_By_Default      => False,
         Header_Height_In_Rows   => 1,
         Row_Height_In_Rows      => 1,
         Show_Header             => True,
         Show_File_Name          => False,
         Show_Severity           => True,
         Show_Row_Column         => True,
         Maximum_Message_Columns => 120);
      Panel  : constant Editor.Layout.Rect :=
        Editor.Layout.Panel_Rect
          (Layout,
           Editor.Panels.Bottom_Panel,
           Editor.View.Viewport_Width,
           Editor.View.Viewport_Height);
      Full_Snapshot    : Editor.Problems.Problems_Snapshot;
      Visible_Snapshot : Editor.Problems.Problems_Snapshot;
      Visible_Rows     : Natural := 0;
      Hit              : Editor.Problems.Problems_Hit_Result;
   begin
      if not Is_Minimap_Pointer_Command (Cmd.Kind)
        and then Cmd.Kind /= Editor.Commands.Pointer_Hover
      then
         return False;
      end if;

      if not Editor.Panels.Is_Visible (The_Editor.State.Panels, Editor.Panels.Bottom_Panel)
        or else Editor.Panels.Active_Bottom_Content (The_Editor.State.Panels)
          /= Editor.Panels.Problems_Content
      then
         return False;
      end if;

      Full_Snapshot := Editor.Problems.Build_Snapshot (The_Editor.State.Diagnostics);
      if Editor.Layout.Cell_H /= 0 then
         Visible_Rows := Panel.Height / Editor.Layout.Cell_H;
         if Visible_Rows > 1 then
            Visible_Rows := Visible_Rows - 1;
         end if;
      end if;
      Visible_Snapshot := Editor.Problems.Visible_Snapshot
        (Full_Snapshot, The_Editor.State.Problems_View, Visible_Rows);

      Hit := Editor.Problems.Hit_Test
        (Panel_Rect  => Panel,
         Config      => Config,
         Snapshot    => Visible_Snapshot,
         Cell_Height => Editor.Layout.Cell_H,
         X           => Integer (Cmd.Click_X),
         Y           => Integer (Cmd.Click_Y));

      if Hit.Zone /= Editor.Problems.Outside_Problems then
         Minimap_Drag_Active := False;
         Scrollbar_Drag.Active := False;
         Gutter_Line_Selection.Active := False;
         Editor.State.Clear_Gutter_Marker_Hover (The_Editor.State);

         if Cmd.Kind = Editor.Commands.Move_To_Point then
            Editor.Focus_Management.Set_Focus_Owner
              (The_Editor.State, Editor.Focus_Management.Focus_Diagnostics);
         end if;

         if Cmd.Kind = Editor.Commands.Move_To_Point
           and then Hit.Zone = Editor.Problems.Problems_Row_Zone
           and then Hit.Diagnostic_Index /= Editor.Diagnostics.No_Diagnostic
         then
            declare
               Found : Boolean := False;
               Row   : constant Natural :=
                 Editor.Problems.Row_For_Diagnostic
                   (Full_Snapshot, Hit.Diagnostic_Index, Found);
            begin
               if Found then
                  Editor.Problems.Set_Selected_Row_Index
                    (The_Editor.State.Problems_View, Row);
               end if;
            end;
            Editor.Executor.Diagnostics_Commands.Execute_Jump_To_Diagnostic
              (The_Editor.State, Hit.Diagnostic_Index);
            Editor.Focus_Management.Restore_Focus_To_Editor
              (The_Editor.State);
         elsif Cmd.Kind = Editor.Commands.Move_To_Point
           and then Hit.Zone = Editor.Problems.Problems_Header_Zone
         then
            declare
               Relative_X : constant Natural :=
                 Natural (Integer'Max (0, Integer (Cmd.Click_X) - Panel.X));
               Action : constant Editor.Problems.Problems_Header_Action :=
                 Editor.Problems.Header_Action_At_X (Panel.Width, Relative_X);
            begin
               case Action is
                  when Editor.Problems.Problems_Header_Filter_Action =>
                  if Editor.Problems.Severity_Filter
                       (The_Editor.State.Problems_View) =
                     Editor.Problems.Problems_Show_Errors
                  then
                     Editor.Executor.Execute_Command
                       (The_Editor.State,
                        Editor.Commands.Command_Problems_Filter_All);
                  else
                     Editor.Executor.Execute_Command
                       (The_Editor.State,
                        Editor.Commands.Command_Problems_Filter_Errors);
                  end if;

                  when Editor.Problems.Problems_Header_Sort_Action =>
                  case The_Editor.State.Problems_View.Sort_Mode is
                     when Editor.Problems.Problems_Sort_By_Location =>
                        Editor.Executor.Execute_Command
                          (The_Editor.State,
                           Editor.Commands.Command_Problems_Sort_By_Severity);
                     when Editor.Problems.Problems_Sort_By_Severity =>
                        Editor.Executor.Execute_Command
                          (The_Editor.State,
                           Editor.Commands.Command_Problems_Sort_By_Source);
                     when Editor.Problems.Problems_Sort_By_Source =>
                        Editor.Executor.Execute_Command
                          (The_Editor.State,
                           Editor.Commands.Command_Problems_Sort_By_Location);
                  end case;

                  when Editor.Problems.Problems_Header_Group_Action =>
                  case The_Editor.State.Problems_View.Group_Mode is
                     when Editor.Problems.Problems_Group_By_Severity =>
                        Editor.Executor.Execute_Command
                          (The_Editor.State,
                           Editor.Commands.Command_Problems_Group_By_Source);
                     when Editor.Problems.Problems_Group_By_Source =>
                        Editor.Executor.Execute_Command
                          (The_Editor.State,
                           Editor.Commands.Command_Problems_Group_By_Severity);
                  end case;
               end case;
            end;
         end if;

         return True;
      end if;

      return False;
   end Handle_Problems_Panel_Pointer;

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
      Minimap_Drag_Active := False;
      Gutter_Line_Selection.Active := False;
      Editor.State.Clear_Gutter_Marker_Hover (The_Editor.State);
      Scrollbar_Drag.Active := False;
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
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before handling key chords");

      if Editor.Guided_Prompts.Is_Active (The_Editor.State.Guided_Prompt) then
         case Chord.Key is
            when Editor.Keybindings.Key_Escape =>
               Editor.Guided_Prompts.Cancel (The_Editor.State.Guided_Prompt);
               Report_Info ("Prompt cancelled.");
            when Editor.Keybindings.Key_Enter =>
               Accept_Guided_Prompt_Enter;
            when Editor.Keybindings.Key_Up =>
               Editor.Guided_Prompts.Move_File_Picker_Selection
                 (The_Editor.State.Guided_Prompt, -1);
            when Editor.Keybindings.Key_Down =>
               Editor.Guided_Prompts.Move_File_Picker_Selection
                 (The_Editor.State.Guided_Prompt, 1);
            when Editor.Keybindings.Key_Right =>
               if Editor.Guided_Prompts.Apply_File_Picker_Selection
                 (The_Editor.State.Guided_Prompt)
               then
                  Report_Info ("Directory selected.");
               end if;
            when Editor.Keybindings.Key_Backspace =>
               Editor.Guided_Prompts.Backspace (The_Editor.State.Guided_Prompt);
            when Editor.Keybindings.Key_Delete =>
               Editor.Guided_Prompts.Delete_Forward (The_Editor.State.Guided_Prompt);
            when others =>
               if The_Editor.State.Guided_Prompt.Kind =
                 Editor.Guided_Prompts.Keybinding_Capture_Prompt
               then
                  Editor.Guided_Prompts.Capture_Chord
                    (The_Editor.State.Guided_Prompt, Chord);
                  Report_Info ("Keybinding chord captured");
               else
                  null;
               end if;
         end case;
         Editor.Render_Cache.Invalidate_All;
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Pending_Confirmation_Active then
         if Editor.Keybindings.Resolve (Chord, Id) /= Editor.Keybindings.Bound_Command then
            Id := Editor.Commands.No_Command;
         end if;

         case Chord.Key is
            when Editor.Keybindings.Key_Escape =>
               Execute_Command_Id (Editor.Commands.Command_Cancel_Pending_Transition);
            when Editor.Keybindings.Key_Enter =>
               Execute_Command_Id (Editor.Commands.Command_Retry_Pending_Transition);
            when others =>
               if Editor.Focus_Management.Command_Allowed_While_Pending (Id) then
                  Execute_Command_Id (Id, Shift => Chord.Modifiers.Shift);
               else
                  Report_Info ("Command unavailable while confirmation is pending");
                  Editor.Render_Cache.Invalidate_All;
               end if;
         end case;

         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      --  keybinding assignment capture owns the key chord before
      --  ordinary global resolution or editor text entry.  Captured chords are
      --  normalized by the keybinding model and stored only as
      --  chord -> stable command name mappings; this path never builds a
      --  command payload, file path, row id, or result id.
      if Editor.Keybinding_Management.Current_Capture_State
        /= Editor.Keybinding_Management.Capture_Inactive
      then
         declare
            Status : Editor.Keybinding_Management.Keybinding_Action_Status;
         begin
            if Chord.Key = Editor.Keybindings.Key_Escape then
               Editor.Keybinding_Management.Cancel_Capture (Status);
            elsif Editor.Keybinding_Management.Has_Pending_Conflict
              and then Chord.Key = Editor.Keybindings.Key_Enter
            then
               Editor.Keybinding_Management.Confirm_Pending_Assignment (Status);
            elsif Editor.Keybinding_Management.Has_Pending_Conflict then
               --  A replacement conflict is an explicit confirmation state.
               --  While it is pending, only Enter confirms and Escape cancels;
               --  any other chord is consumed and must not assign a different
               --  binding or execute through the ordinary resolver.
               Status := Editor.Keybinding_Management.Keybinding_Action_Confirmation_Pending;
            else
               Editor.Keybinding_Management.Assign_Selected
                 (Chord, Confirm_Conflict => False, Status => Status);
            end if;

            if Status = Editor.Keybinding_Management.Keybinding_Action_Ok then
               Report_Info (Editor.Keybinding_Management.Latest_Message);
            else
               Report_Info
                 (Editor.Keybinding_Management.Action_Status_Label (Status));
            end if;
         end;

         Editor.Render_Cache.Invalidate_All;
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      --  when the keybinding management surface owns focus,
      --  plain navigation keys are local to that surface and are consumed
      --  before global keybinding resolution. This prevents ordinary editor
      --  movement/editing commands from firing while the user is selecting
      --  a command row for assignment or removal. Modified chords still flow
      --  through the normal resolver unless capture mode is active above.
      if Editor.Keybinding_Management.Is_Focused
        and then Editor.Keybinding_Management.Is_Visible
        and then not Chord.Modifiers.Ctrl
        and then not Chord.Modifiers.Shift
        and then not Chord.Modifiers.Alt
        and then not Chord.Modifiers.Meta
      then
         declare
            Status : Editor.Keybinding_Management.Keybinding_Action_Status;
         begin
            case Chord.Key is
               when Editor.Keybindings.Key_Down =>
                  Editor.Keybinding_Management.Select_Next_Row;
                  Report_Info (Editor.Keybinding_Management.Latest_Message);
                  Editor.Render_Cache.Invalidate_All;
                  Editor.Cursor.Notify_Input
                    (Float (Editor.View.Current_Time_Seconds));
                  return;
               when Editor.Keybindings.Key_Up =>
                  Editor.Keybinding_Management.Select_Previous_Row;
                  Report_Info (Editor.Keybinding_Management.Latest_Message);
                  Editor.Render_Cache.Invalidate_All;
                  Editor.Cursor.Notify_Input
                    (Float (Editor.View.Current_Time_Seconds));
                  return;
               when Editor.Keybindings.Key_Enter =>
                  if Editor.Keybinding_Management.Has_Pending_Reset then
                     Editor.Keybinding_Management.Confirm_Reset_To_Defaults (Status);
                  else
                     Editor.Keybinding_Management.Begin_Assign_Selected (Status);
                  end if;

                  if Status = Editor.Keybinding_Management.Keybinding_Action_Ok then
                     Report_Info (Editor.Keybinding_Management.Latest_Message);
                  else
                     Report_Info
                       (Editor.Keybinding_Management.Action_Status_Label (Status));
                  end if;
                  Editor.Render_Cache.Invalidate_All;
                  Editor.Cursor.Notify_Input
                    (Float (Editor.View.Current_Time_Seconds));
                  return;
               when Editor.Keybindings.Key_Escape =>
                  if Editor.Keybinding_Management.Has_Pending_Reset then
                     Editor.Keybinding_Management.Cancel_Reset_To_Defaults (Status);
                     Report_Info (Editor.Keybinding_Management.Action_Status_Label (Status));
                  else
                     Editor.Keybinding_Management.Hide;
                     Report_Info ("Keybindings hidden.");
                  end if;
                  Editor.Render_Cache.Invalidate_All;
                  Editor.Cursor.Notify_Input
                    (Float (Editor.View.Current_Time_Seconds));
                  return;
               when others =>
                  null;
            end case;
         end;
      end if;

      if Editor.Settings_Management.Current_Settings_Surface_Focused
        and then Editor.Settings_Management.Current_Settings_Surface_Visible
        and then not Chord.Modifiers.Ctrl
        and then not Chord.Modifiers.Shift
        and then not Chord.Modifiers.Alt
        and then not Chord.Modifiers.Meta
      then
         declare
            UI     : Editor.Settings_Management.Settings_Editor_State :=
              Editor.Settings_Management.Current_Settings_Editor_State;
            Status : Editor.Settings_Management.Setting_Update_Status;
         begin
            case Chord.Key is
               when Editor.Keybindings.Key_Down =>
                  Editor.Settings_Management.Select_Next_Setting (UI);
                  Editor.Settings_Management.Set_Current_Settings_Editor_State (UI);
                  Report_Info ("Settings selection changed.");
                  Editor.Render_Cache.Invalidate_All;
                  Editor.Cursor.Notify_Input
                    (Float (Editor.View.Current_Time_Seconds));
                  return;
               when Editor.Keybindings.Key_Up =>
                  Editor.Settings_Management.Select_Previous_Setting (UI);
                  Editor.Settings_Management.Set_Current_Settings_Editor_State (UI);
                  Report_Info ("Settings selection changed.");
                  Editor.Render_Cache.Invalidate_All;
                  Editor.Cursor.Notify_Input
                    (Float (Editor.View.Current_Time_Seconds));
                  return;
               when Editor.Keybindings.Key_Enter =>
                  if Editor.Settings_Management.Has_Pending_Reset_All (UI) then
                     Editor.Settings_Management.Confirm_Reset_All_Settings
                       (The_Editor.State.Settings, UI, Status);
                  else
                     Editor.Settings_Management.Execute_Settings_Surface_Command
                       (Editor.Settings_Management.Settings_Action_Toggle_Selected,
                        The_Editor.State.Settings, UI, Status);
                  end if;
                  Editor.Settings_Management.Set_Current_Settings_Editor_State (UI);
                  Report_Info
                    (Editor.Settings_Management.Update_Status_Label (Status));
                  Editor.Render_Cache.Invalidate_All;
                  Editor.Cursor.Notify_Input
                    (Float (Editor.View.Current_Time_Seconds));
                  return;
               when Editor.Keybindings.Key_Delete =>
                  Editor.Settings_Management.Execute_Settings_Surface_Command
                    (Editor.Settings_Management.Settings_Action_Reset_Selected,
                     The_Editor.State.Settings, UI, Status);
                  Editor.Settings_Management.Set_Current_Settings_Editor_State (UI);
                  Report_Info
                    (Editor.Settings_Management.Update_Status_Label (Status));
                  Editor.Render_Cache.Invalidate_All;
                  Editor.Cursor.Notify_Input
                    (Float (Editor.View.Current_Time_Seconds));
                  return;
               when Editor.Keybindings.Key_Escape =>
                  if Editor.Settings_Management.Has_Pending_Reset_All (UI) then
                     Editor.Settings_Management.Cancel_Reset_All_Settings
                       (UI, Status);
                     Report_Info
                       (Editor.Settings_Management.Update_Status_Label (Status));
                  else
                     Editor.Settings_Management.Hide_Settings (UI);
                     Report_Info ("Settings hidden.");
                  end if;
                  Editor.Settings_Management.Set_Current_Settings_Editor_State (UI);
                  Editor.Render_Cache.Invalidate_All;
                  Editor.Cursor.Notify_Input
                    (Float (Editor.View.Current_Time_Seconds));
                  return;
               when others =>
                  null;
            end case;
         end;
      end if;

      if The_Editor.State.Active_Find_Prompt
        and then
          ((not Editor.Overlay_Focus.Has_Active_Overlay
              (The_Editor.State.Overlay_Focus))
           or else Editor.Overlay_Focus.Is_Active
             (The_Editor.State.Overlay_Focus,
              Editor.Overlay_Focus.Active_Find_Prompt_Overlay))
      then
         case Chord.Key is
            when Editor.Keybindings.Key_Enter =>
               if Chord.Modifiers.Shift then
                  Execute_Command_Id (Editor.Commands.Command_Active_Find_Previous);
                  Editor.Cursor.Notify_Input
                    (Float (Editor.View.Current_Time_Seconds));
                  return;
               end if;
            when Editor.Keybindings.Key_Escape =>
               Cmd.Kind := Editor.Commands.Active_Find_Hide;
               Editor.Instance.Execute (The_Editor, Cmd);
               Editor.Cursor.Notify_Input
                 (Float (Editor.View.Current_Time_Seconds));
               return;
            when others =>
               null;
         end case;
      end if;

      if The_Editor.State.Semantic_Popup.Active
        and then Chord.Key = Editor.Keybindings.Key_Escape
      then
         Execute_Command_Id (Editor.Commands.Command_Semantic_Popup_Dismiss);
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if The_Editor.State.Semantic_Popup.Active
        and then The_Editor.State.Semantic_Popup.Kind =
          Editor.State.Semantic_Completion_Popup
      then
         case Chord.Key is
            when Editor.Keybindings.Key_Enter =>
               Execute_Command_Id
                 (Editor.Commands.Command_Semantic_Completion_Accept);
               Editor.Cursor.Notify_Input
                 (Float (Editor.View.Current_Time_Seconds));
               return;
            when Editor.Keybindings.Key_Escape =>
               Execute_Command_Id
                 (Editor.Commands.Command_Semantic_Popup_Dismiss);
               Editor.Cursor.Notify_Input
                 (Float (Editor.View.Current_Time_Seconds));
               return;
            when Editor.Keybindings.Key_Down =>
               Execute_Command_Id
                 (Editor.Commands.Command_Semantic_Completion_Select_Next);
               Editor.Cursor.Notify_Input
                 (Float (Editor.View.Current_Time_Seconds));
               return;
            when Editor.Keybindings.Key_Up =>
               Execute_Command_Id
                 (Editor.Commands.Command_Semantic_Completion_Select_Previous);
               Editor.Cursor.Notify_Input
                 (Float (Editor.View.Current_Time_Seconds));
               return;
            when Editor.Keybindings.Key_Tab =>
               if Chord.Modifiers.Shift then
                  Execute_Command_Id
                    (Editor.Commands.Command_Semantic_Completion_Select_Previous);
               else
                  Execute_Command_Id
                    (Editor.Commands.Command_Semantic_Completion_Select_Next);
               end if;
               Editor.Cursor.Notify_Input
                 (Float (Editor.View.Current_Time_Seconds));
               return;
            when others =>
               null;
         end case;
      end if;

      if The_Editor.State.Build_UI.Build_UI_Focused
        and then Chord.Key = Editor.Keybindings.Key_Tab
      then
         declare
            Snapshot : constant Editor.Build_UI.Build_UI_Render_Snapshot :=
              Editor.Build_UI_Actions.Build_UI_Operability_Snapshot
                (The_Editor.State);
            Action_Count : constant Natural := Natural (Snapshot.Actions.Length);
            Layout_Config : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
            Suppressed_Count : constant Natural :=
              Editor.Feature_Diagnostics.Suppressed_Diagnostic_Count
                (The_Editor.State.Feature_Diagnostics);
            Text_Viewport_Height : constant Natural :=
              Editor.Layout.Text_Viewport_Height
                (Layout_Config, Editor.View.Viewport_Height);
            Displayed_Suppressed_Count : constant Natural :=
              Editor.Build_UI_Panel_Layout.Displayed_Suppressed_Row_Count
                (Text_Viewport_Height => Text_Viewport_Height,
                 Cell_H               => Editor.Layout.Cell_H,
                 Action_Count         => Action_Count,
                 Suppressed_Count     => Suppressed_Count);
            Geometry : constant Editor.Build_UI_Panel_Layout.Build_UI_Panel_Geometry :=
              Editor.Build_UI_Panel_Layout.Layout
                (Viewport_Width       => Editor.View.Viewport_Width,
                 Text_Viewport_Y      =>
                   Natural (Editor.Layout.Text_Viewport_Y (Layout_Config)),
                 Text_Viewport_Height => Text_Viewport_Height,
                 Cell_H               => Editor.Layout.Cell_H,
                 Action_Count         => Action_Count,
                 Suppressed_Count     => Displayed_Suppressed_Count);
            Visible_Rows : constant Natural :=
              Editor.Build_UI_Panel_Layout.Visible_Row_Count
                (Geometry, Editor.Layout.Cell_H);
            Visible_Action_Rows : constant Natural :=
              (if Visible_Rows > Geometry.Action_Start_Row
               then Natural'Min (Action_Count, Visible_Rows - Geometry.Action_Start_Row)
               else 0);
         begin
            if Chord.Modifiers.Shift then
               Editor.Build_UI.Select_Previous_Action_Row
                 (The_Editor.State.Build_UI, Action_Count);
            else
               Editor.Build_UI.Select_Next_Action_Row
                 (The_Editor.State.Build_UI, Action_Count);
            end if;
            Editor.Build_UI.Ensure_Selected_Action_Row_Visible
              (The_Editor.State.Build_UI, Action_Count, Visible_Action_Rows);
            Editor.Render_Cache.Invalidate_All;
            Editor.Cursor.Notify_Input
              (Float (Editor.View.Current_Time_Seconds));
            return;
         end;
      end if;

      if The_Editor.State.Build_UI.Build_UI_Focused
        and then Chord.Modifiers.Ctrl
      then
         declare
            Snapshot : constant Editor.Build_UI.Build_UI_Render_Snapshot :=
              Editor.Build_UI_Actions.Build_UI_Operability_Snapshot
                (The_Editor.State);
            Action_Count : constant Natural := Natural (Snapshot.Actions.Length);
            Layout_Config : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
            Suppressed_Count : constant Natural :=
              Editor.Feature_Diagnostics.Suppressed_Diagnostic_Count
                (The_Editor.State.Feature_Diagnostics);
            Text_Viewport_Height : constant Natural :=
              Editor.Layout.Text_Viewport_Height
                (Layout_Config, Editor.View.Viewport_Height);
            Displayed_Suppressed_Count : constant Natural :=
              Editor.Build_UI_Panel_Layout.Displayed_Suppressed_Row_Count
                (Text_Viewport_Height => Text_Viewport_Height,
                 Cell_H               => Editor.Layout.Cell_H,
                 Action_Count         => Action_Count,
                 Suppressed_Count     => Suppressed_Count);
         begin
         case Chord.Key is
            when Editor.Keybindings.Key_Down =>
               Editor.Feature_Diagnostics.Select_Next_Suppressed_Diagnostic
                 (The_Editor.State.Feature_Diagnostics);
               Editor.Feature_Diagnostics.Ensure_Selected_Suppressed_Diagnostic_Visible
                 (The_Editor.State.Feature_Diagnostics,
                  Displayed_Suppressed_Count);
               Editor.Render_Cache.Invalidate_All;
               Editor.Cursor.Notify_Input
                 (Float (Editor.View.Current_Time_Seconds));
               return;
            when Editor.Keybindings.Key_Up =>
               Editor.Feature_Diagnostics.Select_Previous_Suppressed_Diagnostic
                 (The_Editor.State.Feature_Diagnostics);
               Editor.Feature_Diagnostics.Ensure_Selected_Suppressed_Diagnostic_Visible
                 (The_Editor.State.Feature_Diagnostics,
                  Displayed_Suppressed_Count);
               Editor.Render_Cache.Invalidate_All;
               Editor.Cursor.Notify_Input
                 (Float (Editor.View.Current_Time_Seconds));
               return;
            when Editor.Keybindings.Key_Enter =>
               if Editor.Feature_Diagnostics.Restore_Selected_Suppressed_Diagnostic
                 (The_Editor.State.Feature_Diagnostics, The_Editor.State.Feature_Panel)
               then
                  Report_Info ("Selected suppressed diagnostic restored.");
               else
                  Report_Info ("No suppressed diagnostic selected.");
               end if;
               Editor.Render_Cache.Invalidate_All;
               Editor.Cursor.Notify_Input
                 (Float (Editor.View.Current_Time_Seconds));
               return;
            when Editor.Keybindings.Key_Delete =>
               declare
                  Cleared : constant Natural :=
                    Editor.Feature_Diagnostics.Clear_Suppressed_Diagnostics
                      (The_Editor.State.Feature_Diagnostics);
               begin
                  if Cleared = 0 then
                     Report_Info ("No suppressed diagnostics.");
                  else
                     Report_Info ("Suppressed diagnostics cleared.");
                  end if;
               end;
               Editor.Render_Cache.Invalidate_All;
               Editor.Cursor.Notify_Input
                 (Float (Editor.View.Current_Time_Seconds));
               return;
            when others =>
               null;
         end case;
         end;
      end if;

      if not Chord.Modifiers.Ctrl
        and then not Chord.Modifiers.Alt
        and then not Chord.Modifiers.Meta
      then
         if Editor.Panel_Focus.File_Tree_Has_Focus (The_Editor.State.Panel_Focus) then
            case Chord.Key is
               when Editor.Keybindings.Key_Up =>
                  Execute_Command_Id (Editor.Commands.Command_File_Tree_Move_Up);
               when Editor.Keybindings.Key_Down =>
                  Execute_Command_Id (Editor.Commands.Command_File_Tree_Move_Down);
               when Editor.Keybindings.Key_Page_Up =>
                  Execute_Command_Id (Editor.Commands.Command_File_Tree_Page_Up);
               when Editor.Keybindings.Key_Page_Down =>
                  Execute_Command_Id (Editor.Commands.Command_File_Tree_Page_Down);
               when Editor.Keybindings.Key_Left =>
                  Execute_Command_Id (Editor.Commands.Command_File_Tree_Collapse_Selected);
               when Editor.Keybindings.Key_Right =>
                  Execute_Command_Id (Editor.Commands.Command_File_Tree_Expand_Selected);
               when Editor.Keybindings.Key_Enter =>
                  Execute_Command_Id (Editor.Commands.Command_File_Tree_Open_Selected);
               when Editor.Keybindings.Key_Escape =>
                  Execute_Command_Id (Editor.Commands.Command_Focus_Editor_Text);
               when others =>
                  goto Focused_Surface_Not_Handled;
            end case;
            Editor.Cursor.Notify_Input
              (Float (Editor.View.Current_Time_Seconds));
            return;
         elsif The_Editor.State.Latest_Build_Result_Focused then
            case Chord.Key is
               when Editor.Keybindings.Key_Enter =>
                  Execute_Command_Id
                    (Editor.Commands.Command_Build_Output_Details_Focus);
               when Editor.Keybindings.Key_Escape =>
                  Execute_Command_Id (Editor.Commands.Command_Focus_Editor_Text);
               when others =>
                  goto Focused_Surface_Not_Handled;
            end case;
            Editor.Cursor.Notify_Input
              (Float (Editor.View.Current_Time_Seconds));
            return;
         elsif The_Editor.State.Latest_Build_Output_Details.Build_Output_Details_Focused then
            case Chord.Key is
               when Editor.Keybindings.Key_Left =>
                  Execute_Command_Id
                    (Editor.Commands.Command_Build_Output_Details_Select_Stdout);
               when Editor.Keybindings.Key_Right =>
                  Execute_Command_Id
                    (Editor.Commands.Command_Build_Output_Details_Select_Stderr);
               when Editor.Keybindings.Key_Up | Editor.Keybindings.Key_Down =>
                  Execute_Command_Id
                    (Editor.Commands.Command_Build_Output_Details_Select_Merged);
               when Editor.Keybindings.Key_Escape =>
                  Execute_Command_Id (Editor.Commands.Command_Focus_Editor_Text);
               when others =>
                  goto Focused_Surface_Not_Handled;
            end case;
            Editor.Cursor.Notify_Input
              (Float (Editor.View.Current_Time_Seconds));
            return;
         elsif Editor.Terminal_Tasks.Build_Render_Snapshot
             (The_Editor.State.Terminal_Tasks).Focused
         then
            case Chord.Key is
               when Editor.Keybindings.Key_Up =>
                  Execute_Command_Id
                    (Editor.Commands.Command_Terminal_Select_Previous_Task);
               when Editor.Keybindings.Key_Down =>
                  Execute_Command_Id
                    (Editor.Commands.Command_Terminal_Select_Next_Task);
               when Editor.Keybindings.Key_Enter =>
                  Execute_Command_Id
                    (Editor.Commands.Command_Terminal_Run_Selected_Task);
               when Editor.Keybindings.Key_Escape =>
                  Execute_Command_Id (Editor.Commands.Command_Focus_Editor_Text);
               when Editor.Keybindings.Key_Delete =>
                  Execute_Command_Id
                    (Editor.Commands.Command_Terminal_Clear_Output);
               when others =>
                  goto Focused_Surface_Not_Handled;
            end case;
            Editor.Cursor.Notify_Input
              (Float (Editor.View.Current_Time_Seconds));
            return;
         elsif The_Editor.State.Recent_Projects_Focused then
            case Chord.Key is
               when Editor.Keybindings.Key_Up =>
                  Execute_Command_Id
                    (Editor.Commands.Command_Select_Previous_Recent_Project);
               when Editor.Keybindings.Key_Down =>
                  Execute_Command_Id
                    (Editor.Commands.Command_Select_Next_Recent_Project);
               when Editor.Keybindings.Key_Enter =>
                  Execute_Command_Id
                    (Editor.Commands.Command_Open_Selected_Recent_Project);
               when Editor.Keybindings.Key_Escape =>
                  Execute_Command_Id (Editor.Commands.Command_Focus_Editor_Text);
               when Editor.Keybindings.Key_Delete =>
                  Execute_Command_Id
                    (Editor.Commands.Command_Remove_Selected_Recent_Project);
               when others =>
                  goto Focused_Surface_Not_Handled;
            end case;
            Editor.Cursor.Notify_Input
              (Float (Editor.View.Current_Time_Seconds));
            return;
         elsif Editor.Panel_Focus.Bottom_Panel_Has_Focus (The_Editor.State.Panel_Focus) then
            if Editor.Panel_Focus.Bottom_Content (The_Editor.State.Panel_Focus) =
              Editor.Panel_Focus.Search_Results_Focus
            then
               case Chord.Key is
                  when Editor.Keybindings.Key_Up =>
                     Execute_Command_Id (Editor.Commands.Command_Search_Results_Move_Up);
                  when Editor.Keybindings.Key_Down =>
                     Execute_Command_Id (Editor.Commands.Command_Search_Results_Move_Down);
                  when Editor.Keybindings.Key_Page_Up =>
                     Execute_Command_Id (Editor.Commands.Command_Search_Results_Page_Up);
                  when Editor.Keybindings.Key_Page_Down =>
                     Execute_Command_Id (Editor.Commands.Command_Search_Results_Page_Down);
                  when Editor.Keybindings.Key_Enter =>
                     Execute_Command_Id (Editor.Commands.Command_Search_Results_Open_Selected);
                  when Editor.Keybindings.Key_Escape =>
                     Execute_Command_Id (Editor.Commands.Command_Focus_Editor_Text);
                  when others =>
                     goto Focused_Surface_Not_Handled;
               end case;
               Editor.Cursor.Notify_Input
                 (Float (Editor.View.Current_Time_Seconds));
               return;
            elsif Editor.Panel_Focus.Bottom_Content (The_Editor.State.Panel_Focus) =
              Editor.Panel_Focus.Problems_Focus
            then
               case Chord.Key is
                  when Editor.Keybindings.Key_Up =>
                     Execute_Command_Id (Editor.Commands.Command_Problems_Move_Up);
                  when Editor.Keybindings.Key_Down =>
                     Execute_Command_Id (Editor.Commands.Command_Problems_Move_Down);
                  when Editor.Keybindings.Key_Page_Up =>
                     Execute_Command_Id (Editor.Commands.Command_Problems_Page_Up);
                  when Editor.Keybindings.Key_Page_Down =>
                     Execute_Command_Id (Editor.Commands.Command_Problems_Page_Down);
                  when Editor.Keybindings.Key_Enter =>
                     Execute_Command_Id (Editor.Commands.Command_Problems_Open_Selected);
                  when Editor.Keybindings.Key_Escape =>
                     Execute_Command_Id (Editor.Commands.Command_Problems_Focus_Editor);
                  when others =>
                     goto Focused_Surface_Not_Handled;
               end case;
               Editor.Cursor.Notify_Input
                 (Float (Editor.View.Current_Time_Seconds));
               return;
            end if;
         end if;
      end if;

      <<Focused_Surface_Not_Handled>>

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
         elsif Editor.Overlay_Focus.Is_Active
           (The_Editor.State.Overlay_Focus,
            Editor.Overlay_Focus.Quick_Open_Overlay)
         then
            case Chord.Key is
               when Editor.Keybindings.Key_Enter =>
                  Execute_Command_Id (Editor.Commands.Command_Accept_Quick_Open);
               when Editor.Keybindings.Key_Escape =>
                  Execute_Command_Id (Editor.Commands.Command_Close_Quick_Open);
               when Editor.Keybindings.Key_Tab =>
                  if Chord.Modifiers.Shift then
                     Execute_Command_Id (Editor.Commands.Command_Quick_Open_Previous_Result);
                  else
                     Execute_Command_Id (Editor.Commands.Command_Quick_Open_Next_Result);
                  end if;
               when Editor.Keybindings.Key_Backspace =>
                  Cmd.Kind := Editor.Commands.Quick_Open_Backspace;
                  Editor.Instance.Execute (The_Editor, Cmd);
               when Editor.Keybindings.Key_Delete =>
                  Cmd.Kind := Editor.Commands.Quick_Open_Delete_Forward;
                  Editor.Instance.Execute (The_Editor, Cmd);
               when Editor.Keybindings.Key_Left =>
                  Editor.Quick_Open.Move_Cursor_Left (The_Editor.State.Quick_Open);
                  Editor.Render_Cache.Invalidate_All;
               when Editor.Keybindings.Key_Right =>
                  Editor.Quick_Open.Move_Cursor_Right (The_Editor.State.Quick_Open);
                  Editor.Render_Cache.Invalidate_All;
               when Editor.Keybindings.Key_Home =>
                  Editor.Quick_Open.Move_Cursor_Start (The_Editor.State.Quick_Open);
                  Editor.Render_Cache.Invalidate_All;
               when Editor.Keybindings.Key_End =>
                  Editor.Quick_Open.Move_Cursor_End (The_Editor.State.Quick_Open);
                  Editor.Render_Cache.Invalidate_All;
               when Editor.Keybindings.Key_V =>
                  if Chord.Modifiers.Ctrl then
                     Cmd.Kind := Editor.Commands.Quick_Open_Insert_Text;
                     Cmd.Text :=
                       Editor.Executor.Clipboard.Text_For_Local_Input;
                     Editor.Instance.Execute (The_Editor, Cmd);
                  end if;
               when Editor.Keybindings.Key_Down =>
                  Execute_Command_Id (Editor.Commands.Command_Quick_Open_Next_Result);
               when Editor.Keybindings.Key_Up =>
                  Execute_Command_Id (Editor.Commands.Command_Quick_Open_Previous_Result);
               when others =>
                  null;
            end case;
            Editor.Cursor.Notify_Input
              (Float (Editor.View.Current_Time_Seconds));
         elsif Editor.Overlay_Focus.Is_Active
           (The_Editor.State.Overlay_Focus,
            Editor.Overlay_Focus.Buffer_Switcher_Overlay)
         then
            case Chord.Key is
               when Editor.Keybindings.Key_Enter =>
                  Execute_Command_Id (Editor.Commands.Command_Accept_Buffer_Switcher);
               when Editor.Keybindings.Key_Escape =>
                  Execute_Command_Id (Editor.Commands.Command_Close_Buffer_Switcher);
               when Editor.Keybindings.Key_Tab =>
                  if Chord.Modifiers.Shift then
                     Execute_Command_Id (Editor.Commands.Command_Buffer_Switcher_Previous_Result);
                  else
                     Execute_Command_Id (Editor.Commands.Command_Buffer_Switcher_Next_Result);
                  end if;
               when Editor.Keybindings.Key_Backspace =>
                  Cmd.Kind := Editor.Commands.Buffer_Switcher_Backspace;
                  Editor.Instance.Execute (The_Editor, Cmd);
               when Editor.Keybindings.Key_Delete =>
                  Cmd.Kind := Editor.Commands.Buffer_Switcher_Delete_Forward;
                  Editor.Instance.Execute (The_Editor, Cmd);
               when Editor.Keybindings.Key_Left =>
                  Editor.Buffer_Switcher.Move_Cursor_Left (The_Editor.State.Buffer_Switcher);
                  Editor.Render_Cache.Invalidate_All;
               when Editor.Keybindings.Key_Right =>
                  Editor.Buffer_Switcher.Move_Cursor_Right (The_Editor.State.Buffer_Switcher);
                  Editor.Render_Cache.Invalidate_All;
               when Editor.Keybindings.Key_Home =>
                  Editor.Buffer_Switcher.Move_Cursor_Start (The_Editor.State.Buffer_Switcher);
                  Editor.Render_Cache.Invalidate_All;
               when Editor.Keybindings.Key_End =>
                  Editor.Buffer_Switcher.Move_Cursor_End (The_Editor.State.Buffer_Switcher);
                  Editor.Render_Cache.Invalidate_All;
               when Editor.Keybindings.Key_V =>
                  if Chord.Modifiers.Ctrl then
                     Cmd.Kind := Editor.Commands.Buffer_Switcher_Insert_Text;
                     Cmd.Text :=
                       Editor.Executor.Clipboard.Text_For_Local_Input;
                     Editor.Instance.Execute (The_Editor, Cmd);
                  end if;
               when Editor.Keybindings.Key_Down =>
                  Execute_Command_Id (Editor.Commands.Command_Buffer_Switcher_Next_Result);
               when Editor.Keybindings.Key_Up =>
                  Execute_Command_Id (Editor.Commands.Command_Buffer_Switcher_Previous_Result);
               when others =>
                  null;
            end case;
            Editor.Cursor.Notify_Input
              (Float (Editor.View.Current_Time_Seconds));
         elsif Editor.Overlay_Focus.Is_Active
           (The_Editor.State.Overlay_Focus,
            Editor.Overlay_Focus.Project_Search_Bar_Overlay)
         then
            case Chord.Key is
               when Editor.Keybindings.Key_Enter =>
                  if Chord.Modifiers.Ctrl then
                     Execute_Command_Id (Editor.Commands.Command_Open_Selected_Project_Search_Result);
                  else
                     Execute_Command_Id (Editor.Commands.Command_Run_Project_Search_From_Bar);
                  end if;
               when Editor.Keybindings.Key_Tab =>
                  Editor.Project_Search_Bar.Toggle_Active_Field
                    (The_Editor.State.Project_Search_Bar);
                  Sync_Project_Search_Replace_Mode_From_Bar;
                  Editor.Render_Cache.Invalidate_All;
               when Editor.Keybindings.Key_Escape =>
                  Execute_Command_Id (Editor.Commands.Command_Close_Project_Search_Bar);
               when Editor.Keybindings.Key_Backspace =>
                  Cmd.Kind := Editor.Commands.Project_Search_Bar_Backspace;
                  Editor.Instance.Execute (The_Editor, Cmd);
               when Editor.Keybindings.Key_Delete =>
                  Cmd.Kind := Editor.Commands.Project_Search_Bar_Delete_Forward;
                  Editor.Instance.Execute (The_Editor, Cmd);
               when Editor.Keybindings.Key_Left =>
                  Editor.Project_Search_Bar.Move_Cursor_Left (The_Editor.State.Project_Search_Bar);
                  Editor.Render_Cache.Invalidate_All;
               when Editor.Keybindings.Key_Right =>
                  Editor.Project_Search_Bar.Move_Cursor_Right (The_Editor.State.Project_Search_Bar);
                  Editor.Render_Cache.Invalidate_All;
               when Editor.Keybindings.Key_Home =>
                  Editor.Project_Search_Bar.Move_Cursor_Start (The_Editor.State.Project_Search_Bar);
                  Editor.Render_Cache.Invalidate_All;
               when Editor.Keybindings.Key_End =>
                  Editor.Project_Search_Bar.Move_Cursor_End (The_Editor.State.Project_Search_Bar);
                  Editor.Render_Cache.Invalidate_All;
               when Editor.Keybindings.Key_V =>
                  if Chord.Modifiers.Ctrl then
                     Cmd.Kind := Editor.Commands.Project_Search_Bar_Insert_Text;
                     Cmd.Text :=
                       Editor.Executor.Clipboard.Text_For_Local_Input;
                     Editor.Instance.Execute (The_Editor, Cmd);
                  end if;
               when Editor.Keybindings.Key_Down =>
                  Execute_Command_Id (Editor.Commands.Command_Move_Project_Search_Selection_Down);
               when Editor.Keybindings.Key_Up =>
                  Execute_Command_Id (Editor.Commands.Command_Move_Project_Search_Selection_Up);
               when others =>
                  null;
            end case;
            Editor.Cursor.Notify_Input
              (Float (Editor.View.Current_Time_Seconds));
         elsif Editor.Overlay_Focus.Is_Active
           (The_Editor.State.Overlay_Focus,
            Editor.Overlay_Focus.File_Target_Prompt_Overlay)
         then
            case Chord.Key is
               when Editor.Keybindings.Key_Enter =>
                  Editor.Executor.File_Target_Prompt_Commands.Confirm_File_Target_Prompt (The_Editor.State);
                  Editor.Focus_Management.Restore_Focus_To_Editor (The_Editor.State);
               when Editor.Keybindings.Key_Escape =>
                  Editor.Executor.File_Target_Prompt_Commands.Cancel_File_Target_Prompt (The_Editor.State);
                  Editor.Focus_Management.Restore_Previous_Focus_Or_Editor (The_Editor.State);
               when Editor.Keybindings.Key_Backspace =>
                  Editor.Executor.File_Target_Prompt_Commands.Backspace_File_Target_Prompt (The_Editor.State);
               when Editor.Keybindings.Key_Delete =>
                  Editor.Executor.File_Target_Prompt_Commands.Delete_Forward_File_Target_Prompt (The_Editor.State);
               when Editor.Keybindings.Key_Left =>
                  Editor.Executor.File_Target_Prompt_Commands.Move_File_Target_Prompt_Cursor_Left (The_Editor.State);
               when Editor.Keybindings.Key_Right =>
                  Editor.Executor.File_Target_Prompt_Commands.Move_File_Target_Prompt_Cursor_Right (The_Editor.State);
               when Editor.Keybindings.Key_Home =>
                  Editor.Executor.File_Target_Prompt_Commands.Move_File_Target_Prompt_Cursor_Start (The_Editor.State);
               when Editor.Keybindings.Key_End =>
                  Editor.Executor.File_Target_Prompt_Commands.Move_File_Target_Prompt_Cursor_End (The_Editor.State);
               when Editor.Keybindings.Key_V =>
                  if Chord.Modifiers.Ctrl then
                     Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text
                       (The_Editor.State,
                        To_String (Editor.Executor.Clipboard.Text_For_Local_Input));
                  end if;
               when others =>
                  null;
            end case;
            Editor.Cursor.Notify_Input
              (Float (Editor.View.Current_Time_Seconds));
         elsif Editor.Overlay_Focus.Is_Active
           (The_Editor.State.Overlay_Focus,
            Editor.Overlay_Focus.Go_To_Line_Overlay)
         then
            case Chord.Key is
               when Editor.Keybindings.Key_Enter =>
                  Execute_Command_Id (Editor.Commands.Command_Accept_Goto_Line);
               when Editor.Keybindings.Key_Escape =>
                  Execute_Command_Id (Editor.Commands.Command_Close_Goto_Line);
               when Editor.Keybindings.Key_Backspace =>
                  Cmd.Kind := Editor.Commands.Goto_Line_Backspace;
                  Editor.Instance.Execute (The_Editor, Cmd);
               when Editor.Keybindings.Key_Delete =>
                  Cmd.Kind := Editor.Commands.Goto_Line_Delete_Forward;
                  Editor.Instance.Execute (The_Editor, Cmd);
               when Editor.Keybindings.Key_Left =>
                  Editor.Go_To_Line.Move_Cursor_Left (The_Editor.State.Go_To_Line);
                  Editor.Render_Cache.Invalidate_All;
               when Editor.Keybindings.Key_Right =>
                  Editor.Go_To_Line.Move_Cursor_Right (The_Editor.State.Go_To_Line);
                  Editor.Render_Cache.Invalidate_All;
               when Editor.Keybindings.Key_Home =>
                  Editor.Go_To_Line.Move_Cursor_Start (The_Editor.State.Go_To_Line);
                  Editor.Render_Cache.Invalidate_All;
               when Editor.Keybindings.Key_End =>
                  Editor.Go_To_Line.Move_Cursor_End (The_Editor.State.Go_To_Line);
                  Editor.Render_Cache.Invalidate_All;
               when Editor.Keybindings.Key_V =>
                  if Chord.Modifiers.Ctrl then
                     Cmd.Kind := Editor.Commands.Goto_Line_Insert_Text;
                     Cmd.Text :=
                       Editor.Executor.Clipboard.Text_For_Local_Input;
                     Editor.Instance.Execute (The_Editor, Cmd);
                  end if;
               when others =>
                  null;
            end case;
            Editor.Cursor.Notify_Input
              (Float (Editor.View.Current_Time_Seconds));
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
         elsif Editor.Feature_Panel.Is_Focused (The_Editor.State.Feature_Panel) then
            if not Editor.Feature_Panel.Is_Visible (The_Editor.State.Feature_Panel) then
               Execute_Command_Id (Editor.Commands.Command_Focus_Editor_Text);
            elsif Editor.Feature_Search_Results.Search_Input_Is_Active
              (The_Editor.State.Feature_Search_Results)
            then
               case Chord.Key is
                  when Editor.Keybindings.Key_Up =>
                     Execute_Command_Id
                       (Editor.Commands.Command_Search_Results_Query_History_Previous);
                  when Editor.Keybindings.Key_Down =>
                     Execute_Command_Id
                       (Editor.Commands.Command_Search_Results_Query_History_Next);
                  when Editor.Keybindings.Key_Enter =>
                     Execute_Command_Id
                       (Editor.Commands.Command_Search_Results_Search_Active_Buffer);
                  when Editor.Keybindings.Key_Escape =>
                     Editor.Feature_Search_Results.Deactivate_Search_Query_Input
                       (The_Editor.State.Feature_Search_Results);
                     Editor.Feature_Search_Results.Project_Rows
                       (The_Editor.State.Feature_Search_Results,
                        The_Editor.State.Feature_Panel);
                     Editor.Render_Cache.Invalidate_All;
                  when Editor.Keybindings.Key_Backspace =>
                     Editor.Feature_Search_Results.Delete_Search_Input_Character_Backward
                       (The_Editor.State.Feature_Search_Results);
                     Editor.Feature_Search_Results.Project_Rows
                       (The_Editor.State.Feature_Search_Results,
                        The_Editor.State.Feature_Panel);
                     Editor.Render_Cache.Invalidate_All;
                  when Editor.Keybindings.Key_Delete =>
                     Editor.Feature_Search_Results.Delete_Search_Input_Character_Forward
                       (The_Editor.State.Feature_Search_Results);
                     Editor.Feature_Search_Results.Project_Rows
                       (The_Editor.State.Feature_Search_Results,
                        The_Editor.State.Feature_Panel);
                     Editor.Render_Cache.Invalidate_All;
                  when others =>
                     null;
               end case;
            elsif Editor.Outline.Filter_Input_Is_Active (The_Editor.State.Outline) then
               case Chord.Key is
                  when Editor.Keybindings.Key_Up =>
                     if Chord.Modifiers.Ctrl or else Chord.Modifiers.Alt then
                        Execute_Command_Id
                          (Editor.Commands.Command_Outline_Filter_History_Previous);
                     else
                        Execute_Command_Id
                          (Editor.Commands.Command_Select_Previous_Outline_Item);
                     end if;
                  when Editor.Keybindings.Key_Down =>
                     if Chord.Modifiers.Ctrl or else Chord.Modifiers.Alt then
                        Execute_Command_Id
                          (Editor.Commands.Command_Outline_Filter_History_Next);
                     else
                        Execute_Command_Id
                          (Editor.Commands.Command_Select_Next_Outline_Item);
                     end if;
                  when Editor.Keybindings.Key_Enter =>
                     Editor.Outline.Commit_Filter_To_History (The_Editor.State.Outline);
                     Execute_Command_Id
                       (Editor.Commands.Command_Open_Selected_Outline_Item);
                  when Editor.Keybindings.Key_Escape =>
                     if Editor.Outline.Filter_Text (The_Editor.State.Outline) /= "" then
                        Editor.Outline.Clear_Filter_Text (The_Editor.State.Outline);
                     else
                        Editor.Outline.Deactivate_Filter_Input (The_Editor.State.Outline);
                     end if;
                     Editor.Outline.Set_Rows_From_Outline
                       (The_Editor.State.Outline, The_Editor.State.Feature_Panel);
                     Editor.Render_Cache.Invalidate_All;
                  when Editor.Keybindings.Key_Backspace =>
                     Editor.Outline.Delete_Filter_Character_Backward
                       (The_Editor.State.Outline);
                     Editor.Outline.Set_Rows_From_Outline
                       (The_Editor.State.Outline, The_Editor.State.Feature_Panel);
                     Editor.Render_Cache.Invalidate_All;
                  when Editor.Keybindings.Key_Delete =>
                     Editor.Outline.Delete_Filter_Character_Forward
                       (The_Editor.State.Outline);
                     Editor.Outline.Set_Rows_From_Outline
                       (The_Editor.State.Outline, The_Editor.State.Feature_Panel);
                     Editor.Render_Cache.Invalidate_All;
                  when Editor.Keybindings.Key_Left =>
                     Editor.Outline.Move_Filter_Caret_Left (The_Editor.State.Outline);
                     Editor.Render_Cache.Invalidate_All;
                  when Editor.Keybindings.Key_Right =>
                     Editor.Outline.Move_Filter_Caret_Right (The_Editor.State.Outline);
                     Editor.Render_Cache.Invalidate_All;
                  when Editor.Keybindings.Key_Home =>
                     Editor.Outline.Move_Filter_Caret_Start (The_Editor.State.Outline);
                     Editor.Render_Cache.Invalidate_All;
                  when Editor.Keybindings.Key_End =>
                     Editor.Outline.Move_Filter_Caret_End (The_Editor.State.Outline);
                     Editor.Render_Cache.Invalidate_All;
                  when others =>
                     null;
               end case;
            else
               case Chord.Key is
                  when Editor.Keybindings.Key_Up =>
                     Execute_Command_Id
                       (Editor.Commands.Command_Feature_Panel_Select_Previous);
                  when Editor.Keybindings.Key_Down =>
                     Execute_Command_Id
                       (Editor.Commands.Command_Feature_Panel_Select_Next);
                  when Editor.Keybindings.Key_Enter =>
                     if Editor.Feature_Panel.Selected_Row
                         (The_Editor.State.Feature_Panel) /= 0
                       and then Editor.Outline.Feature_Row_Maps_To_Item
                         (The_Editor.State.Outline,
                          The_Editor.State.Feature_Panel,
                          Editor.Feature_Panel.Selected_Row
                            (The_Editor.State.Feature_Panel))
                     then
                        Execute_Command_Id
                          (Editor.Commands.Command_Open_Selected_Outline_Item);
                     else
                        Execute_Command_Id
                          (Editor.Commands.Command_Feature_Panel_Open_Selected);
                     end if;
                  when Editor.Keybindings.Key_Escape =>
                     Execute_Command_Id (Editor.Commands.Command_Focus_Editor_Text);
                  when others =>
                     null;
               end case;
            end if;
            Editor.Cursor.Notify_Input
              (Float (Editor.View.Current_Time_Seconds));
         elsif Editor.Panel_Focus.File_Tree_Has_Focus (The_Editor.State.Panel_Focus) then
            if (not Editor.Project.Has_Project (The_Editor.State.Project))
              or else not Editor.Panels.Is_Visible
                (The_Editor.State.Panels, Editor.Panels.File_Tree_Panel)
            then
               Execute_Command_Id (Editor.Commands.Command_Focus_Editor_Text);
               Editor.Cursor.Notify_Input
                 (Float (Editor.View.Current_Time_Seconds));
               return;
            end if;

            case Chord.Key is
               when Editor.Keybindings.Key_Up =>
                  Execute_Command_Id (Editor.Commands.Command_File_Tree_Move_Up);
               when Editor.Keybindings.Key_Down =>
                  Execute_Command_Id (Editor.Commands.Command_File_Tree_Move_Down);
               when Editor.Keybindings.Key_Page_Up =>
                  Execute_Command_Id (Editor.Commands.Command_File_Tree_Page_Up);
               when Editor.Keybindings.Key_Page_Down =>
                  Execute_Command_Id (Editor.Commands.Command_File_Tree_Page_Down);
               when Editor.Keybindings.Key_Home =>
                  Editor.File_Tree_View.Select_First_Visible_Row
                    (The_Editor.State.File_Tree_View, The_Editor.State.File_Tree);
                  Editor.File_Tree_View.Set_Top_Row
                    (The_Editor.State.File_Tree_View, 1);
                  Editor.Render_Cache.Invalidate_All;
               when Editor.Keybindings.Key_End =>
                  declare
                     Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
                     Panel  : constant Editor.Layout.Rect :=
                       Editor.Layout.Panel_Rect
                         (Layout,
                          Editor.Panels.File_Tree_Panel,
                          Editor.View.Viewport_Width,
                          Editor.View.Viewport_Height);
                     Page_Rows : constant Natural :=
                       (if Editor.Layout.Cell_H = 0 then 1
                        else Natural'Max (1, Panel.Height / Editor.Layout.Cell_H));
                     Count : constant Natural :=
                       Editor.File_Tree.Visible_Row_Count (The_Editor.State.File_Tree);
                  begin
                     Editor.File_Tree_View.Select_Last_Visible_Row
                       (The_Editor.State.File_Tree_View, The_Editor.State.File_Tree);
                     if Count <= Page_Rows then
                        Editor.File_Tree_View.Set_Top_Row
                          (The_Editor.State.File_Tree_View, 1);
                     else
                        Editor.File_Tree_View.Set_Top_Row
                          (The_Editor.State.File_Tree_View, Count - Page_Rows + 1);
                     end if;
                  end;
                  Editor.Render_Cache.Invalidate_All;
               when Editor.Keybindings.Key_Left =>
                  Execute_Command_Id (Editor.Commands.Command_File_Tree_Collapse_Selected);
               when Editor.Keybindings.Key_Right =>
                  Execute_Command_Id (Editor.Commands.Command_File_Tree_Expand_Selected);
               when Editor.Keybindings.Key_Enter =>
                  Execute_Command_Id (Editor.Commands.Command_File_Tree_Open_Selected);
               when Editor.Keybindings.Key_Escape =>
                  Execute_Command_Id (Editor.Commands.Command_Focus_Editor_Text);
               when others =>
                  null;
            end case;
            Editor.Cursor.Notify_Input
              (Float (Editor.View.Current_Time_Seconds));
         elsif The_Editor.State.Build_UI.Build_UI_Focused then
            declare
               Projection : constant Build_UI_Panel_Input_Projection :=
                 Current_Build_UI_Panel_Input_Projection;

               procedure Activate_Selected_Action is
                  Selected : constant Natural :=
                    Editor.Build_UI.Selected_Action_Row
                      (The_Editor.State.Build_UI, Projection.Action_Count);
                  Found : Boolean := False;
                  Id : Editor.Commands.Command_Id := Editor.Commands.No_Command;
               begin
                  if Selected = 0 then
                     Execute_Command_Id (Editor.Commands.Command_Build_Run);
                     return;
                  end if;

                  declare
                     Row : constant Editor.Build_UI.Build_UI_Action_Row :=
                       Projection.Snapshot.Actions.Element (Selected - 1);
                     Reason : constant String := To_String (Row.Disabled_Reason);
                  begin
                     if not Row.Enabled then
                        if Reason'Length > 0 then
                           Report_Info (Reason);
                        else
                           Report_Info ("Command unavailable");
                        end if;
                        return;
                     end if;

                     Id := Editor.Commands.Command_Id_From_Stable_Name
                       (To_String (Row.Command_Name), Found);

                     if Found and then Id /= Editor.Commands.No_Command then
                        if Id = Editor.Commands.Command_Diagnostic_Apply_Quick_Fix
                          and then Row.Quick_Fix_Action_Index > 0
                        then
                           declare
                              Result : constant Editor.Command_Execution.Command_Execution_Result :=
                                Editor.Build_UI_Actions.Build_UI_Apply_Diagnostic_Quick_Fix
                                  (The_Editor.State,
                                   Row.Quick_Fix_Action_Index,
                                   Row.Diagnostic_Index);
                              pragma Unreferenced (Result);
                           begin
                              null;
                           end;
                        else
                           Execute_Command_Id (Id);
                        end if;
                     end if;
                  end;
               end Activate_Selected_Action;
            begin
               if Chord.Modifiers.Ctrl
                 and then Chord.Key = Editor.Keybindings.Key_Down
               then
                  Editor.Feature_Diagnostics.Select_Next_Suppressed_Diagnostic
                    (The_Editor.State.Feature_Diagnostics);
                  Editor.Feature_Diagnostics.Ensure_Selected_Suppressed_Diagnostic_Visible
                    (The_Editor.State.Feature_Diagnostics,
                     Projection.Displayed_Suppressed_Count);
                  Editor.Render_Cache.Invalidate_All;
               elsif Chord.Modifiers.Ctrl
                 and then Chord.Key = Editor.Keybindings.Key_Up
               then
                  Editor.Feature_Diagnostics.Select_Previous_Suppressed_Diagnostic
                    (The_Editor.State.Feature_Diagnostics);
                  Editor.Feature_Diagnostics.Ensure_Selected_Suppressed_Diagnostic_Visible
                    (The_Editor.State.Feature_Diagnostics,
                     Projection.Displayed_Suppressed_Count);
                  Editor.Render_Cache.Invalidate_All;
               elsif Chord.Modifiers.Ctrl
                 and then Chord.Key = Editor.Keybindings.Key_Enter
               then
                  Execute_Command_Id
                    (Editor.Commands.Command_Diagnostic_Restore_Selected_Suppressed);
               elsif Chord.Modifiers.Ctrl
                 and then Chord.Key = Editor.Keybindings.Key_Delete
               then
                  Execute_Command_Id
                    (Editor.Commands.Command_Diagnostic_Clear_Suppressed);
               else
               case Chord.Key is
                  when Editor.Keybindings.Key_Up =>
                     Execute_Command_Id
                       (Editor.Commands.Command_Build_Select_Previous_Candidate);
                  when Editor.Keybindings.Key_Down =>
                     Execute_Command_Id
                       (Editor.Commands.Command_Build_Select_Next_Candidate);
                  when Editor.Keybindings.Key_Tab =>
                     if Chord.Modifiers.Shift then
                        Editor.Build_UI.Select_Previous_Action_Row
                          (The_Editor.State.Build_UI, Projection.Action_Count);
                     else
                        Editor.Build_UI.Select_Next_Action_Row
                          (The_Editor.State.Build_UI, Projection.Action_Count);
                     end if;
                     Editor.Build_UI.Ensure_Selected_Action_Row_Visible
                       (The_Editor.State.Build_UI,
                        Projection.Action_Count,
                        Projection.Visible_Action_Rows);
                     Editor.Render_Cache.Invalidate_All;
                  when Editor.Keybindings.Key_Enter =>
                     Activate_Selected_Action;
                  when Editor.Keybindings.Key_Escape =>
                     Execute_Command_Id (Editor.Commands.Command_Focus_Editor_Text);
                  when Editor.Keybindings.Key_Delete =>
                     Execute_Command_Id
                       (Editor.Commands.Command_Build_Clear_Selected_Candidate);
                  when others =>
                     null;
               end case;
               end if;
            end;
            Editor.Cursor.Notify_Input
              (Float (Editor.View.Current_Time_Seconds));
         elsif The_Editor.State.Latest_Build_Result_Focused then
            case Chord.Key is
               when Editor.Keybindings.Key_Enter =>
                  Execute_Command_Id
                    (Editor.Commands.Command_Build_Output_Details_Focus);
               when Editor.Keybindings.Key_Escape =>
                  Execute_Command_Id (Editor.Commands.Command_Focus_Editor_Text);
               when others =>
                  null;
            end case;
            Editor.Cursor.Notify_Input
              (Float (Editor.View.Current_Time_Seconds));
         elsif The_Editor.State.Latest_Build_Output_Details.Build_Output_Details_Focused then
            case Chord.Key is
               when Editor.Keybindings.Key_Left =>
                  Execute_Command_Id
                    (Editor.Commands.Command_Build_Output_Details_Select_Stdout);
               when Editor.Keybindings.Key_Right =>
                  Execute_Command_Id
                    (Editor.Commands.Command_Build_Output_Details_Select_Stderr);
               when Editor.Keybindings.Key_Up | Editor.Keybindings.Key_Down =>
                  Execute_Command_Id
                    (Editor.Commands.Command_Build_Output_Details_Select_Merged);
               when Editor.Keybindings.Key_Escape =>
                  Execute_Command_Id (Editor.Commands.Command_Focus_Editor_Text);
               when others =>
                  null;
            end case;
            Editor.Cursor.Notify_Input
              (Float (Editor.View.Current_Time_Seconds));
         elsif Editor.Terminal_Tasks.Build_Render_Snapshot
             (The_Editor.State.Terminal_Tasks).Focused
         then
            case Chord.Key is
               when Editor.Keybindings.Key_Up =>
                  Execute_Command_Id
                    (Editor.Commands.Command_Terminal_Select_Previous_Task);
               when Editor.Keybindings.Key_Down =>
                  Execute_Command_Id
                    (Editor.Commands.Command_Terminal_Select_Next_Task);
               when Editor.Keybindings.Key_Enter =>
                  Execute_Command_Id
                    (Editor.Commands.Command_Terminal_Run_Selected_Task);
               when Editor.Keybindings.Key_Escape =>
                  Execute_Command_Id (Editor.Commands.Command_Focus_Editor_Text);
               when Editor.Keybindings.Key_Delete =>
                  Execute_Command_Id
                    (Editor.Commands.Command_Terminal_Clear_Output);
               when others =>
                  null;
            end case;
            Editor.Cursor.Notify_Input
              (Float (Editor.View.Current_Time_Seconds));
         elsif The_Editor.State.Recent_Projects_Focused then
            case Chord.Key is
               when Editor.Keybindings.Key_Up =>
                  Execute_Command_Id
                    (Editor.Commands.Command_Select_Previous_Recent_Project);
               when Editor.Keybindings.Key_Down =>
                  Execute_Command_Id
                    (Editor.Commands.Command_Select_Next_Recent_Project);
               when Editor.Keybindings.Key_Enter =>
                  Execute_Command_Id
                    (Editor.Commands.Command_Open_Selected_Recent_Project);
               when Editor.Keybindings.Key_Escape =>
                  Execute_Command_Id (Editor.Commands.Command_Focus_Editor_Text);
               when Editor.Keybindings.Key_Delete =>
                  Execute_Command_Id
                    (Editor.Commands.Command_Remove_Selected_Recent_Project);
               when others =>
                  null;
            end case;
            Editor.Cursor.Notify_Input
              (Float (Editor.View.Current_Time_Seconds));
         elsif Editor.Panel_Focus.Bottom_Panel_Has_Focus (The_Editor.State.Panel_Focus) then
            if Editor.Panel_Focus.Bottom_Content (The_Editor.State.Panel_Focus) =
              Editor.Panel_Focus.Search_Results_Focus
            then
               case Chord.Key is
                  when Editor.Keybindings.Key_Up =>
                     Execute_Command_Id (Editor.Commands.Command_Search_Results_Move_Up);
                  when Editor.Keybindings.Key_Down =>
                     Execute_Command_Id (Editor.Commands.Command_Search_Results_Move_Down);
                  when Editor.Keybindings.Key_Page_Up =>
                     Execute_Command_Id (Editor.Commands.Command_Search_Results_Page_Up);
                  when Editor.Keybindings.Key_Page_Down =>
                     Execute_Command_Id (Editor.Commands.Command_Search_Results_Page_Down);
                  when Editor.Keybindings.Key_Enter =>
                     Execute_Command_Id (Editor.Commands.Command_Search_Results_Open_Selected);
                  when Editor.Keybindings.Key_Escape =>
                     Execute_Command_Id (Editor.Commands.Command_Focus_Editor_Text);
                  when others =>
                     null;
               end case;
            elsif Editor.Panel_Focus.Bottom_Content (The_Editor.State.Panel_Focus) =
              Editor.Panel_Focus.Problems_Focus
            then
               case Chord.Key is
                  when Editor.Keybindings.Key_Up =>
                     Execute_Command_Id (Editor.Commands.Command_Problems_Move_Up);
                  when Editor.Keybindings.Key_Down =>
                     Execute_Command_Id (Editor.Commands.Command_Problems_Move_Down);
                  when Editor.Keybindings.Key_Page_Up =>
                     Execute_Command_Id (Editor.Commands.Command_Problems_Page_Up);
                  when Editor.Keybindings.Key_Page_Down =>
                     Execute_Command_Id (Editor.Commands.Command_Problems_Page_Down);
                  when Editor.Keybindings.Key_Enter =>
                     Execute_Command_Id (Editor.Commands.Command_Problems_Open_Selected);
                  when Editor.Keybindings.Key_Escape =>
                     Execute_Command_Id (Editor.Commands.Command_Problems_Focus_Editor);
                  when others =>
                     null;
               end case;
            end if;
            Editor.Cursor.Notify_Input
              (Float (Editor.View.Current_Time_Seconds));
         else
            Execute_Command_Id (Id, Shift => Chord.Modifiers.Shift);
            Editor.Cursor.Notify_Input
              (Float (Editor.View.Current_Time_Seconds));
         end if;
      end if;
   end Handle_Key_Chord;


   function Wheel_Row_Delta (Delta_Y : Integer) return Integer is
   begin
      if Delta_Y = 0 then
         return 0;
      elsif Delta_Y > 0 then
         return -3 * Delta_Y;
      else
         return -3 * Delta_Y;
      end if;
   end Wheel_Row_Delta;

   function Wheel_Column_Delta (Delta_X : Integer) return Integer is
   begin
      return 3 * Delta_X;
   end Wheel_Column_Delta;

   function Longest_Line_Column_Count return Natural is
      Count : constant Natural := Editor.State.Line_Count (The_Editor.State);
      Max   : Natural := 0;
   begin
      if Count = 0 then
         return 0;
      end if;

      for Row in 0 .. Count - 1 loop
         declare
            First : constant Editor.Cursors.Cursor_Index :=
              Editor.State.Line_Start (The_Editor.State, Row);
            Last  : constant Editor.Cursors.Cursor_Index :=
              Text_Buffer.Line_End_Index (The_Editor.State.Buffer, Row);
         begin
            if Last >= First then
               Max := Natural'Max (Max, Natural (Last - First));
            end if;
         end;
      end loop;
      return Max;
   end Longest_Line_Column_Count;

   procedure Scroll_Editor_By
     (Delta_X : Integer;
      Delta_Y : Integer)
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Rows   : constant Natural := Editor.State.Line_Count (The_Editor.State);
      View_H : constant Natural :=
        (if Editor.Layout.Cell_H = 0 then 1
         else Natural'Max
           (1,
            Editor.Layout.Text_Viewport_Height
              (Layout, Editor.View.Viewport_Height) / Editor.Layout.Cell_H));
      View_W : constant Natural :=
        Natural'Max
          (1,
           Editor.Layout.Text_Visible_Column_Count
             (Layout, Rows, Editor.View.Viewport_Width));
      New_Y  : Integer := Integer (Editor.View.Scroll_Y) + Wheel_Row_Delta (Delta_Y);
      New_X  : Integer := Integer (Editor.View.Scroll_X) + Wheel_Column_Delta (Delta_X);
   begin
      if New_Y < 0 then
         New_Y := 0;
      end if;
      if New_X < 0 then
         New_X := 0;
      end if;

      Editor.View.Set_Scroll_Y_Clamped
        (Row_Count      => Rows,
         Viewport_Rows  => View_H,
         Desired_Scroll => Natural (New_Y));
      Editor.View.Set_Scroll_X_Clamped
        (Column_Count   => Longest_Line_Column_Count,
         Viewport_Cols  => View_W,
         Desired_Scroll => Natural (New_X));
      Editor.Render_Cache.Invalidate_All;
   end Scroll_Editor_By;

   function Point_In_Rect
     (X : Natural;
      Y : Natural;
      R : Editor.Layout.Rect) return Boolean
   is
   begin
      return Integer (X) >= R.X
        and then Integer (Y) >= R.Y
        and then Integer (X) < R.X + Integer (R.Width)
        and then Integer (Y) < R.Y + Integer (R.Height);
   end Point_In_Rect;

   function Handle_Command_Palette_Wheel
     (X       : Natural;
      Y       : Natural;
      Delta_Y : Integer) return Boolean
   is
      Palette : constant Editor.Command_Palette.Palette_State :=
        Editor.Command_Palette.Current;
      Layout  : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Config : constant Editor.Command_Palette.Command_Palette_Config :=
        Editor.Command_Palette.Current_Config;
      Snapshot : Editor.Command_Palette.Command_Palette_Snapshot;
      Margin : constant Natural := Editor.Theme.Palette_Margin;
      Max_W  : constant Natural := Editor.Theme.Palette_Max_Width;
      Width  : Natural := Max_W;
      Top_Y  : Natural := 0;
      Visible_Count : Natural := 0;
      Height : Natural := 0;
      Rect   : Editor.Layout.Rect;
   begin
      if not Palette.Open then
         return False;
      end if;

      Editor.Executor.Command_Palette_Candidates (The_Editor.State, Candidates);
      Editor.Command_Palette.Reconcile_Selection (Candidates);
      Snapshot := Editor.Command_Palette.Build_Snapshot (Candidates, Config);

      if Editor.View.Viewport_Width <= Margin * 2 then
         Width := Editor.View.Viewport_Width;
      else
         Width := Natural'Min (Max_W, Editor.View.Viewport_Width - Margin * 2);
      end if;

      Top_Y := Natural'Min
        (Natural'Max
           (0,
            Natural
              (Float (Layout.Origin_Y)
               + Float'Max
                 (Editor.Theme.Palette_Top_Min_Offset,
                  Float (Editor.View.Viewport_Height)
                  * Editor.Theme.Palette_Top_Fraction))),
         Natural (Editor.Layout.Status_Bar_Y (Layout, Editor.View.Viewport_Height)));

      declare
         Status_Y : constant Natural :=
           Natural (Editor.Layout.Status_Bar_Y (Layout, Editor.View.Viewport_Height));
         Available_H : constant Natural :=
           (if Status_Y > Top_Y then Status_Y - Top_Y else 0);
         Base_H : constant Natural :=
           2 * Editor.Layout.Cell_H + Natural (Editor.Theme.Palette_Outer_Padding_Y);
         Space_For_Rows : constant Natural :=
           (if Editor.Layout.Cell_H /= 0 and then Available_H > Base_H
            then (Available_H - Base_H) / Editor.Layout.Cell_H
            else 0);
      begin
         Visible_Count := Natural'Min
           (Natural'Min (Config.Max_Visible_Rows, Space_For_Rows),
            Editor.Command_Palette.Row_Count (Snapshot));
      end;

      Height := (2 + Visible_Count) * Editor.Layout.Cell_H
        + Natural (Editor.Theme.Palette_Outer_Padding_Y);
      Rect :=
        (X      => Layout.Origin_X + Integer ((Editor.View.Viewport_Width - Width) / 2),
         Y      => Integer (Top_Y),
         Width  => Width,
         Height => Height);

      if not Point_In_Rect (X, Y, Rect) then
         return False;
      end if;

      Editor.Command_Palette.Scroll_By (Snapshot, Visible_Count, Wheel_Row_Delta (Delta_Y));
      Editor.Render_Cache.Invalidate_All;
      return True;
   end Handle_Command_Palette_Wheel;

   function Handle_Build_UI_Wheel
     (X       : Natural;
      Y       : Natural;
      Delta_Y : Integer) return Boolean
   is
      Projection : constant Build_UI_Panel_Input_Projection :=
        Current_Build_UI_Panel_Input_Projection;
      Rect : constant Editor.Layout.Rect :=
        (X      => Projection.Geometry.X,
         Y      => Projection.Geometry.Y,
         Width  => Projection.Geometry.W,
         Height => Projection.Geometry.H);
      Hit : Editor.Build_UI_Panel_Layout.Build_UI_Panel_Hit;
   begin
      if not Projection.Snapshot.Visible or else not Point_In_Rect (X, Y, Rect) then
         return False;
      end if;

      Hit := Editor.Build_UI_Panel_Layout.Hit_Test
        (Projection.Geometry, Editor.Layout.Cell_H, Integer (X), Integer (Y));

      if Hit.Zone = Editor.Build_UI_Panel_Layout.Build_UI_Panel_Suppressed_Row
        or else Hit.Zone = Editor.Build_UI_Panel_Layout.Build_UI_Panel_Suppressed_Header
      then
         Editor.Feature_Diagnostics.Scroll_Suppressed_Diagnostics
           (The_Editor.State.Feature_Diagnostics,
            Projection.Displayed_Suppressed_Count,
            Wheel_Row_Delta (Delta_Y));
      else
         Editor.Build_UI.Scroll_Action_Rows
           (The_Editor.State.Build_UI,
            Projection.Action_Count,
            Projection.Visible_Action_Rows,
            Wheel_Row_Delta (Delta_Y));
      end if;
      Editor.Render_Cache.Invalidate_All;
      return True;
   end Handle_Build_UI_Wheel;

   procedure Handle_Wheel
     (X       : Natural;
      Y       : Natural;
      Delta_X : Integer;
      Delta_Y : Integer)
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Bottom : constant Editor.Layout.Rect :=
        Editor.Layout.Panel_Rect
          (Layout,
           Editor.Panels.Bottom_Panel,
           Editor.View.Viewport_Width,
           Editor.View.Viewport_Height);
      File_Rect : constant Editor.Layout.Rect :=
        Editor.Layout.Panel_Rect
          (Layout,
           Editor.Panels.File_Tree_Panel,
           Editor.View.Viewport_Width,
           Editor.View.Viewport_Height);
      Feature_Width  : constant Natural :=
        Natural'Min (280, Editor.View.Viewport_Width);
      Feature_Rect : constant Editor.Layout.Rect :=
        (X      => Integer (Editor.View.Viewport_Width) - Integer (Feature_Width),
         Y      => Editor.Layout.Text_Viewport_Y (Layout),
         Width  => Feature_Width,
         Height => Editor.Layout.Text_Viewport_Height
                     (Layout, Editor.View.Viewport_Height));
      Text_Rect : constant Editor.Layout.Rect :=
        (X      => Integer (Editor.Layout.Text_Origin_X
                     (Layout, Editor.State.Line_Count (The_Editor.State))),
         Y      => Editor.Layout.Text_Viewport_Y (Layout),
         Width  => Editor.Layout.Text_Viewport_Width
                     (Layout,
                      Editor.State.Line_Count (The_Editor.State),
                      Editor.View.Viewport_Width),
         Height => Editor.Layout.Text_Viewport_Height
                     (Layout, Editor.View.Viewport_Height));
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before handling wheel input");

      if Delta_X = 0 and then Delta_Y = 0 then
         return;
      end if;

      if Handle_Command_Palette_Wheel (X, Y, Delta_Y) then
         return;
      end if;

      if Handle_Build_UI_Wheel (X, Y, Delta_Y) then
         return;
      end if;

      if Editor.Layout.Is_In_Status_Bar
           (Config          => Layout,
            X               => Integer (X),
            Y               => Integer (Y),
            Viewport_Width  => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height)
      then
         return;
      end if;

      if Point_In_Rect (X, Y, File_Rect)
        and then Editor.Panels.Is_Visible
          (The_Editor.State.Panels, Editor.Panels.File_Tree_Panel)
      then
         Editor.File_Tree_View.Scroll_By
           (The_Editor.State.File_Tree_View,
            The_Editor.State.File_Tree,
            (if Editor.Layout.Cell_H = 0 then 1
             else Natural'Max (1, File_Rect.Height / Editor.Layout.Cell_H)),
            Wheel_Row_Delta (Delta_Y));
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      if Point_In_Rect (X, Y, Feature_Rect)
        and then Editor.Feature_Panel.Is_Visible (The_Editor.State.Feature_Panel)
      then
         declare
            Rows : Natural :=
              (if Editor.Layout.Cell_H = 0 then 1
               else Natural'Max (1, Feature_Rect.Height / Editor.Layout.Cell_H));
         begin
            if Rows > 1 then
               Rows := Rows - 1;
            end if;
            Editor.Feature_Panel.Set_Visible_Row_Count
              (The_Editor.State.Feature_Panel, Rows);
         end;
         Editor.Feature_Panel.Scroll_By
           (The_Editor.State.Feature_Panel, Wheel_Row_Delta (Delta_Y));
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      if Point_In_Rect (X, Y, Bottom)
        and then Editor.Panels.Is_Visible
          (The_Editor.State.Panels, Editor.Panels.Bottom_Panel)
      then
         declare
            Rows : Natural :=
              (if Editor.Layout.Cell_H = 0 then 1
               else Natural'Max (1, Bottom.Height / Editor.Layout.Cell_H));
         begin
            if Rows > 1 then
               Rows := Rows - 1;
            end if;

            if Editor.Panels.Active_Bottom_Content (The_Editor.State.Panels) =
              Editor.Panels.Search_Results_Content
            then
               declare
                  Full : constant Editor.Search_Results.Search_Results_Snapshot :=
                    Editor.Search_Results.Build_Snapshot
                      (The_Editor.State.Project_Search, (others => <>),
                       Editor.Buffers.Global_Registry_For_UI);
               begin
                  Editor.Search_Results.Scroll_By
                    (The_Editor.State.Search_Results_View, Full, Rows,
                     Wheel_Row_Delta (Delta_Y));
               end;
               Editor.Render_Cache.Invalidate_All;
               return;
            elsif Editor.Panels.Active_Bottom_Content (The_Editor.State.Panels) =
              Editor.Panels.Problems_Content
            then
               declare
                  Full : constant Editor.Problems.Problems_Snapshot :=
                    Editor.Problems.Build_Snapshot (The_Editor.State.Diagnostics);
               begin
                  Editor.Problems.Scroll_By
                    (The_Editor.State.Problems_View, Full, Rows,
                     Wheel_Row_Delta (Delta_Y));
               end;
               Editor.Render_Cache.Invalidate_All;
               return;
            end if;
         end;
      end if;

      if Point_In_Rect (X, Y, Text_Rect) then
         Scroll_Editor_By (Delta_X, Delta_Y);
      end if;
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
        and then Handle_Panel_Splitter_Pointer (Cmd)
      then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Pending_Confirmation_Active then
         if Handle_Pending_Transition_Bar_Pointer (Cmd) then
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
      if Editor.Overlay_Focus.Has_Active_Overlay
        (The_Editor.State.Overlay_Focus)
      then
         declare
            Handled : Boolean := False;
         begin
            case Editor.Overlay_Focus.Active_Overlay
              (The_Editor.State.Overlay_Focus)
            is
               when Editor.Overlay_Focus.Command_Palette_Overlay =>
                  Handled := Handle_Command_Palette (Cmd);
               when Editor.Overlay_Focus.Quick_Open_Overlay =>
                  Handled := Handle_Quick_Open (Cmd);
               when Editor.Overlay_Focus.Buffer_Switcher_Overlay =>
                  Handled := Handle_Buffer_Switcher (Cmd);
               when Editor.Overlay_Focus.Project_Search_Bar_Overlay =>
                  Handled := Handle_Project_Search_Bar (Cmd);
               when Editor.Overlay_Focus.Go_To_Line_Overlay =>
                  Handled := Handle_Goto_Line (Cmd);
               when Editor.Overlay_Focus.Active_Find_Prompt_Overlay =>
                  Handled := Handle_Active_Find_Input (Cmd);
               when Editor.Overlay_Focus.File_Target_Prompt_Overlay =>
                  Handled := Handle_File_Target_Prompt (Cmd);
               when Editor.Overlay_Focus.No_Overlay =>
                  null;
            end case;

            pragma Unreferenced (Handled);
            Editor.Cursor.Notify_Input
              (Float (Editor.View.Current_Time_Seconds));
            return;
         end;
      end if;

      --  pass 30: Feature Search query input and Outline filter
      --  input are text-input focus owners even though they are embedded in
      --  the feature panel rather than represented by Overlay_Focus.  They
      --  therefore need the same high-priority dispatch isolation as modal
      --  overlays: route the event only to the owning text-field handler and
      --  consume it, so unrelated pointer/key events cannot activate File
      --  Tree rows, tab-bar items, search/problemlist rows, or editor text
      --  underneath a focused panel input field.
      if Editor.Feature_Search_Results.Search_Input_Is_Active
        (The_Editor.State.Feature_Search_Results)
      then
         declare
            Handled : constant Boolean := Handle_Search_Query_Input (Cmd);
         begin
            pragma Unreferenced (Handled);
            Editor.Cursor.Notify_Input
              (Float (Editor.View.Current_Time_Seconds));
            return;
         end;
      end if;

      if Editor.Outline.Filter_Input_Is_Active (The_Editor.State.Outline) then
         declare
            Handled : constant Boolean := Handle_Outline_Filter_Input (Cmd);
         begin
            pragma Unreferenced (Handled);
            Editor.Cursor.Notify_Input
              (Float (Editor.View.Current_Time_Seconds));
            return;
         end;
      end if;

      if Handle_Problems_Panel_Pointer (Cmd) then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Handle_Command_Palette (Cmd) then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Handle_Message_Overlay_Pointer (Cmd) then
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

      if Handle_Pending_Transition_Bar_Pointer (Cmd) then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Handle_Build_UI_Panel_Pointer (Cmd) then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Handle_Tab_Bar_Pointer (Cmd) then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Handle_Status_Bar_Pointer (Cmd) then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Handle_Panel_Splitter_Pointer (Cmd) then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Handle_File_Tree_Pointer (Cmd) then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Handle_Search_Results_Panel_Pointer (Cmd) then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Handle_Feature_Panel_Pointer (Cmd) then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      --  Minimap hit-testing owns the minimap region before scrollbars so a
      --  minimap click cannot be interpreted as a vertical scrollbar action.
      if Minimap_Drag_Active and then Handle_Minimap_Pointer (Cmd) then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Handle_Minimap_Pointer (Cmd) then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Handle_Scrollbar_Pointer (Cmd) then
         Editor.Cursor.Notify_Input
           (Float (Editor.View.Current_Time_Seconds));
         return;
      end if;

      if Handle_Gutter_Pointer (Cmd) then
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

      Editor.Buffers.Ensure_Global_Registry (The_Editor.State);
      Editor.Buffers.Sync_Global_Active_From_State (The_Editor.State);
      if Editor.Settings.Use_Syntax_Colouring then
         Editor.State.Prepare_Syntax_For_Visible_Range
           (The_Editor.State,
            0,
            (if Editor.State.Line_Count (The_Editor.State) = 0 then 0
             else Editor.State.Line_Count (The_Editor.State) - 1),
            Editor.Settings.Use_Semantic_Colouring);
      end if;
      Editor.Render_Model.Build_Render_Snapshot (The_Editor.State, Out_Snapshot);
   end Get_Render_Snapshot;

   procedure Get_File_Tree_For_Render
     (Out_Tree : out Editor.File_Tree.File_Tree_State)
   is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering file tree");

      Out_Tree := The_Editor.State.File_Tree;
   end Get_File_Tree_For_Render;

   procedure Get_Problems_For_Render
     (Out_Snapshot : out Editor.Problems.Problems_Snapshot)
   is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering problems");

      declare
         Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
         Panel  : constant Editor.Layout.Rect :=
           Editor.Layout.Panel_Rect
             (Layout,
              Editor.Panels.Bottom_Panel,
              Editor.View.Viewport_Width,
              Editor.View.Viewport_Height);
         Full   : constant Editor.Problems.Problems_Snapshot :=
           Editor.Problems.Build_Snapshot (The_Editor.State.Diagnostics);
         Rows   : Natural :=
           (if Editor.Layout.Cell_H = 0 then 0 else Panel.Height / Editor.Layout.Cell_H);
      begin
         if Rows > 1 then
            Rows := Rows - 1;
         end if;
         Out_Snapshot := Editor.Problems.Visible_Snapshot
           (Full, The_Editor.State.Problems_View, Rows);
      end;
   end Get_Problems_For_Render;

   function Problems_Total_Count_For_Render return Natural is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering problem count");
      return Editor.Problems.Row_Count
        (Editor.Problems.Build_Snapshot (The_Editor.State.Diagnostics));
   end Problems_Total_Count_For_Render;

   procedure Get_Search_Results_For_Render
     (Out_Snapshot : out Editor.Search_Results.Search_Results_Snapshot)
   is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering search results");

      declare
         Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
         Panel  : constant Editor.Layout.Rect :=
           Editor.Layout.Panel_Rect
             (Layout,
              Editor.Panels.Bottom_Panel,
              Editor.View.Viewport_Width,
              Editor.View.Viewport_Height);
         Full   : constant Editor.Search_Results.Search_Results_Snapshot :=
           Editor.Search_Results.Build_Snapshot
             (The_Editor.State.Project_Search, (others => <>),
              Editor.Buffers.Global_Registry_For_UI);
      begin
         Out_Snapshot := Editor.Search_Results.Visible_Snapshot
           (Full,
            The_Editor.State.Search_Results_View,
            (if Editor.Layout.Cell_H = 0 then 0 else Panel.Height / Editor.Layout.Cell_H));
      end;
   end Get_Search_Results_For_Render;

   function Search_Results_Focused_For_Render return Boolean is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering focus state");
      return Editor.Panel_Focus.Bottom_Panel_Has_Focus (The_Editor.State.Panel_Focus)
        and then Editor.Panel_Focus.Bottom_Content (The_Editor.State.Panel_Focus) =
          Editor.Panel_Focus.Search_Results_Focus;
   end Search_Results_Focused_For_Render;

   function Problems_Focused_For_Render return Boolean is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering focus state");
      return Editor.Panel_Focus.Bottom_Panel_Has_Focus (The_Editor.State.Panel_Focus)
        and then Editor.Panel_Focus.Bottom_Content (The_Editor.State.Panel_Focus) =
          Editor.Panel_Focus.Problems_Focus;
   end Problems_Focused_For_Render;

   function File_Tree_Focused_For_Render return Boolean is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering file tree focus state");
      return Editor.Panel_Focus.File_Tree_Has_Focus (The_Editor.State.Panel_Focus)
        and then Editor.Project.Has_Project (The_Editor.State.Project)
        and then Editor.Panels.Is_Visible
          (The_Editor.State.Panels, Editor.Panels.File_Tree_Panel);
   end File_Tree_Focused_For_Render;

   function Feature_Panel_For_Render return Editor.Feature_Panel.Feature_Panel_State is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering feature panel");
      return The_Editor.State.Feature_Panel;
   end Feature_Panel_For_Render;

   function Feature_Panel_Focused_For_Render return Boolean is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering feature panel focus state");
      return Editor.Feature_Panel.Is_Focused (The_Editor.State.Feature_Panel);
   end Feature_Panel_Focused_For_Render;

   function File_Tree_View_For_Render return Editor.File_Tree_View.File_Tree_View_State is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering file tree view state");
      return The_Editor.State.File_Tree_View;
   end File_Tree_View_For_Render;

   function Problems_View_For_Render return Editor.Problems.Problems_View_State is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering problems view state");
      return The_Editor.State.Problems_View;
   end Problems_View_For_Render;

   function Project_Search_For_Render
     return Editor.Project_Search.Project_Search_State
   is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering project search");
      return The_Editor.State.Project_Search;
   end Project_Search_For_Render;

   function Active_Diagnostic_For_Render return Editor.Diagnostics.Diagnostic_Index
   is
   begin
      if The_Editor.State.Active_Diagnostic.Has_Active then
         return The_Editor.State.Active_Diagnostic.Index;
      else
         return Editor.Diagnostics.No_Diagnostic;
      end if;
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
      Minimap_Drag_Active := False;
      Gutter_Line_Selection.Active := False;
      Editor.State.Clear_Gutter_Marker_Hover (The_Editor.State);
      Scrollbar_Drag.Active := False;
      Editor.Panels.End_Resize (The_Editor.State.Panels);
      Editor.Panels.Set_Current (The_Editor.State.Panels);
      Editor.Scrollbars.Reset;
      Editor.Render_Cache.Invalidate_All;
      Editor.View.Reset_Scroll;
      Initialized := True;
   end Set_State_For_Test;

end Editor.Input_Bridge;
