with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Command_Kinds; use Editor.Command_Kinds;
with Editor.Commands.Payloads;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Executor.Command_Surface_Commands;
with Editor.Executor.Find_Replace_Commands;
with Editor.Executor.Find_Replace_Input_Commands;
with Editor.Executor.Navigation_Commands;
with Editor.Executor.Shared_Services;
with Editor.Go_To_Line;
with Editor.Render_Cache;
with Editor.State;

package body Editor.Executor.Command_Kind_Input_Commands is

   function Try_Execute_Input_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Payloads.Command) return Boolean
   is
   begin
      case Cmd.Kind is
         when Open_Goto_Line
            | Prefill_Goto_Line_Current
            | Toggle_Goto_Line
            | Close_Goto_Line
            | Accept_Goto_Line
            | Goto_Line_Query_Set
            | Goto_Line_Query_Clear
            | Goto_Line_Insert_Text
            | Goto_Line_Backspace
            | Goto_Line_Delete_Forward
            | Goto_Line_Move_Cursor_Left
            | Goto_Line_Move_Cursor_Right =>
            case Cmd.Kind is
               when Open_Goto_Line =>
                  Editor.Executor.Navigation_Commands.Execute_Open_Goto_Line (S);
               when Prefill_Goto_Line_Current =>
                  Editor.Executor.Navigation_Commands
                    .Execute_Prefill_Goto_Line_Current (S);
               when Toggle_Goto_Line =>
                  Editor.Executor.Navigation_Commands.Execute_Toggle_Goto_Line (S);
               when Close_Goto_Line =>
                  Editor.Executor.Navigation_Commands.Execute_Close_Goto_Line (S);
               when Accept_Goto_Line =>
                  Editor.Executor.Navigation_Commands.Execute_Accept_Goto_Line (S);
               when Goto_Line_Query_Set =>
                  Editor.Executor.Navigation_Commands.Execute_Goto_Line_Set_Query
                    (S, To_String (Cmd.Text));
               when Goto_Line_Query_Clear =>
                  Editor.Executor.Navigation_Commands.Execute_Goto_Line_Clear_Query
                    (S);
               when Goto_Line_Insert_Text =>
                  Editor.Executor.Navigation_Commands.Execute_Goto_Line_Insert_Text
                    (S, To_String (Cmd.Text));
               when Goto_Line_Backspace =>
                  Editor.Executor.Navigation_Commands.Execute_Goto_Line_Backspace
                    (S);
               when Goto_Line_Delete_Forward =>
                  Editor.Executor.Navigation_Commands
                    .Execute_Goto_Line_Delete_Forward (S);
               when Goto_Line_Move_Cursor_Left =>
                  Editor.Go_To_Line.Move_Cursor_Left (S.Go_To_Line);
                  Editor.Render_Cache.Invalidate_All;
               when Goto_Line_Move_Cursor_Right =>
                  Editor.Go_To_Line.Move_Cursor_Right (S.Go_To_Line);
                  Editor.Render_Cache.Invalidate_All;
               when others =>
                  null;
            end case;
            return True;

         when Open_Quick_Open
            | Close_Quick_Open
            | Toggle_Quick_Open
            | Accept_Quick_Open
            | Quick_Open_Next_Result
            | Quick_Open_Previous_Result
            | Quick_Open_Query_Set
            | Quick_Open_Query_Clear
            | Quick_Open_Kind_Next
            | Quick_Open_Kind_Previous
            | Quick_Open_Kind_Clear
            | Quick_Open_Scope_Set
            | Quick_Open_Scope_Clear
            | Quick_Open_Scope_From_Selected
            | Quick_Open_Scope_Parent
            | Quick_Open_Reveal_Active
            | Quick_Open_Scope_Active_Directory
            | Quick_Open_Create_From_Query
            | Quick_Open_Create_With_Parents_From_Query
            | Quick_Open_Priority_Toggle
            | Quick_Open_Priority_Clear
            | Quick_Open_Insert_Text
            | Quick_Open_Backspace
            | Quick_Open_Delete_Forward
            | Quick_Open_Move_Cursor_Left
            | Quick_Open_Move_Cursor_Right
            | Open_Command_Palette
            | Palette_Show_Command_Help =>
            Editor.Executor.Command_Surface_Commands.Execute_Command_Surface_Kind
              (S, Cmd.Kind, To_String (Cmd.Text));
            return True;

         when Active_Find_Show
            | Active_Find_Hide
            | Active_Find_Toggle
            | Active_Find_Query_Set
            | Active_Find_Query_Clear
            | Active_Find_Case_Toggle
            | Active_Find_Case_Clear
            | Active_Find_Whole_Word_Toggle
            | Active_Find_Whole_Word_Clear
            | Active_Find_From_Selection
            | Active_Find_From_Active_Word
            | Active_Find_Next
            | Active_Find_Previous
            | Active_Find_First
            | Active_Find_Last
            | Active_Find_Reveal_Current
            | Active_Replace_Show
            | Active_Replace_Hide
            | Active_Replace_Toggle
            | Active_Replace_Text_Set
            | Active_Replace_Text_Clear
            | Active_Replace_Current
            | Active_Replace_All
            | Active_Find_Input_Insert_Text
            | Active_Find_Input_Backspace
            | Active_Find_Input_Delete_Forward
            | Active_Find_Input_Move_Cursor_Left
            | Active_Find_Input_Move_Cursor_Right =>
            case Cmd.Kind is
               when Active_Find_Show =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
               when Active_Find_Hide =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_Hide (S);
               when Active_Find_Toggle =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_Toggle (S);
               when Active_Find_Query_Set =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query
                    (S, To_String (Cmd.Text));
               when Active_Find_Query_Clear =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_Clear_Query (S);
               when Active_Find_Case_Toggle =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_Case_Toggle (S);
               when Active_Find_Case_Clear =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_Case_Clear (S);
               when Active_Find_Whole_Word_Toggle =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_Whole_Word_Toggle (S);
               when Active_Find_Whole_Word_Clear =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_Whole_Word_Clear (S);
               when Active_Find_From_Selection =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_From_Selection (S);
               when Active_Find_From_Active_Word =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_From_Active_Word (S);
               when Active_Find_Next =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_Next (S);
               when Active_Find_Previous =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_Previous (S);
               when Active_Find_First =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_First (S);
               when Active_Find_Last =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_Last (S);
               when Active_Find_Reveal_Current =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_Reveal_Current (S);
               when Active_Replace_Show =>
                  Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
               when Active_Replace_Hide =>
                  Editor.Executor.Find_Replace_Commands.Execute_Replace_Hide (S);
               when Active_Replace_Toggle =>
                  Editor.Executor.Find_Replace_Commands.Execute_Replace_Toggle (S);
               when Active_Replace_Text_Set =>
                  Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text
                    (S, To_String (Cmd.Text));
               when Active_Replace_Text_Clear =>
                  Editor.Executor.Find_Replace_Commands.Execute_Replace_Clear_Text (S);
               when Active_Replace_Current =>
                  Editor.Executor.Find_Replace_Commands.Execute_Replace_Current (S);
               when Active_Replace_All =>
                  Editor.Executor.Find_Replace_Commands.Execute_Replace_All (S);
               when Active_Find_Input_Insert_Text =>
                  Editor.Executor.Find_Replace_Input_Commands
                    .Execute_Active_Find_Input_Insert_Text (S, To_String (Cmd.Text));
               when Active_Find_Input_Backspace =>
                  Editor.Executor.Find_Replace_Input_Commands
                    .Execute_Active_Find_Input_Backspace (S);
               when Active_Find_Input_Delete_Forward =>
                  Editor.Executor.Find_Replace_Input_Commands
                    .Execute_Active_Find_Input_Delete_Forward (S);
               when Active_Find_Input_Move_Cursor_Left =>
                  Editor.Executor.Find_Replace_Input_Commands
                    .Execute_Active_Find_Input_Move_Cursor_Left (S);
               when Active_Find_Input_Move_Cursor_Right =>
                  Editor.Executor.Find_Replace_Input_Commands
                    .Execute_Active_Find_Input_Move_Cursor_Right (S);
               when others =>
                  null;
            end case;
            return True;

         when others =>
            return False;
      end case;
   end Try_Execute_Input_Kind;

end Editor.Executor.Command_Kind_Input_Commands;
