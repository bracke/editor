with Editor.Commands;
with Editor.Keybindings;
with Editor.Render_Model;
with Editor.State;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.Render_Packet;
with Editor.Unicode;
with Editor.Problems;
with Editor.Search_Results;
with Editor.Project_Search;
with Editor.Diagnostics;
with Editor.Feature_Panel;

--  Input_Bridge owns the active editor instance used by the runtime.
--
--  Runtime and render integration should enter through this package:
--     Reset                -> full editor initialization
--     Handle               -> command dispatch
--     Get_Render_Snapshot  -> render snapshot source
--     Set_State_For_Test   -> test-only state injection
--
--  Render_Packet must not initialize editor state directly.
package Editor.Input_Bridge is

   procedure Reset;

   procedure Open_Project_Path
     (Path : String);

   procedure Handle
     (Cmd : Editor.Commands.Command);

   type Text_Entry_Focus_Target is
     (Text_Entry_Overlay_Input,
      Text_Entry_Guided_Prompt,
      Text_Entry_Editor_Buffer,
      Text_Entry_No_Target);

   type Text_Entry_Route_Result is
     (Routed_To_Text_Insert,
      Routed_To_Selection_Delete,
      Routed_To_Delete_Previous_Character,
      Routed_To_Delete_Next_Character,
      Routed_To_Delete_Previous_Word,
      Routed_To_Delete_Next_Word,
      Routed_To_Line_Split,
      Routed_To_Overlay_Input,
      Routed_To_Guided_Prompt,
      No_Active_Buffer,
      No_Caret_Location,
      No_Editor_Text_Focus,
      Unsupported_Text_Entry_Event);

   --  Side-effect-free route classification for editor text-entry workflow
   --  inputs. It does not execute commands, mutate focus, normalize selection,
   --  touch Undo/Redo, dirty state, Find/Replace, Clipboard, Navigation
   --  History, render state, settings, workspace, or recent-project state.
   function Resolve_Text_Entry_Focus_Target
     return Text_Entry_Focus_Target;

   function Preview_Text_Entry_Route
     (Cmd : Editor.Commands.Command) return Text_Entry_Route_Result;

   --  Side-effect-free canonical command-id projection for text-entry
   --  workflow route audits. Ordinary text payloads intentionally return
   --  No_Command because they are not exposed as public command ids.
   function Preview_Text_Entry_Command_Id
     (Cmd : Editor.Commands.Command) return Editor.Commands.Command_Id;

   --  Route mouse-wheel input by the current hit-tested surface. Positive
   --  Delta_Y scrolls up; negative Delta_Y scrolls down. Positive Delta_X
   --  scrolls right; negative Delta_X scrolls left. Wheel routing mutates only
   --  viewport state for the intended surface.
   procedure Handle_Wheel
     (X       : Natural;
      Y       : Natural;
      Delta_X : Integer;
      Delta_Y : Integer);

   procedure Handle_Key_Chord
     (Chord : Editor.Keybindings.Key_Chord);

   procedure Execute_Command_Id
     (Id    : Editor.Commands.Command_Id;
      Shift : Boolean := False);

   procedure Get_Render_Snapshot
     (Out_Snapshot : out Editor.Render_Model.Render_Snapshot);

   procedure Get_File_Tree_For_Render
     (Out_Tree : out Editor.File_Tree.File_Tree_State);

   procedure Get_Problems_For_Render
     (Out_Snapshot : out Editor.Problems.Problems_Snapshot);

   function Problems_Total_Count_For_Render return Natural;

   procedure Get_Search_Results_For_Render
     (Out_Snapshot : out Editor.Search_Results.Search_Results_Snapshot);

   function Search_Results_Focused_For_Render return Boolean;

   function Problems_Focused_For_Render return Boolean;

   function File_Tree_Focused_For_Render return Boolean;

   function Feature_Panel_For_Render return Editor.Feature_Panel.Feature_Panel_State;

   function Feature_Panel_Focused_For_Render return Boolean;

   function File_Tree_View_For_Render return Editor.File_Tree_View.File_Tree_View_State;

   function Problems_View_For_Render return Editor.Problems.Problems_View_State;

   function Project_Search_For_Render
     return Editor.Project_Search.Project_Search_State;

   function Active_Diagnostic_For_Render return Editor.Diagnostics.Diagnostic_Index;

   procedure Build_Render_Packet
      (Packet : out Editor.Render_Packet.Render_Packet);

   procedure Tick_Async_Build_Jobs;

   procedure Tick_Messages;

   procedure Set_State_For_Test (S : Editor.State.State_Type);

   --  Test-only accessor for assertions after routed input.
   --  Runtime code must continue to use render snapshots and executor APIs.
   function Get_State_For_Test return Editor.State.State_Type;

   procedure For_Each_Text_Char_Range
   (Start : Natural;
      Stop  : Natural;
      Fn    : not null access procedure (Ch : Character));

   procedure For_Each_Text_Code_Point_Range
   (Start : Natural;
      Stop  : Natural;
      Fn    : not null access procedure
        (Index : Natural;
         Code  : Editor.Unicode.Code_Point));

end Editor.Input_Bridge;
