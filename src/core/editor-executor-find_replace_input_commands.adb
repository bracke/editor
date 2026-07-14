with Editor.Executor.Find_Replace_Commands;
with Editor.Input_Field;
with Editor.Render_Cache;
with Editor.State;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Executor.Find_Replace_Input_Commands is

   procedure Execute_Active_Find_Input_Insert_Text
     (S    : in out Editor.State.State_Type;
      Text : String) is
   begin
      if not S.Active_Find_Prompt then
         return;
      end if;
      Editor.Input_Field.Insert_Text (S.Active_Find_Input, Text);
      Editor.Executor.Find_Replace_Commands.Set_Active_Find_Query_And_Report
        (S, Editor.Input_Field.Text (S.Active_Find_Input));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Active_Find_Input_Insert_Text;

   procedure Execute_Active_Find_Input_Backspace
     (S : in out Editor.State.State_Type) is
   begin
      if not S.Active_Find_Prompt then
         return;
      end if;
      Editor.Input_Field.Backspace (S.Active_Find_Input);
      Editor.Executor.Find_Replace_Commands.Set_Active_Find_Query_And_Report
        (S, Editor.Input_Field.Text (S.Active_Find_Input));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Active_Find_Input_Backspace;

   procedure Execute_Active_Find_Input_Delete_Forward
     (S : in out Editor.State.State_Type) is
   begin
      if not S.Active_Find_Prompt then
         return;
      end if;
      Editor.Input_Field.Delete_Forward (S.Active_Find_Input);
      Editor.Executor.Find_Replace_Commands.Set_Active_Find_Query_And_Report
        (S, Editor.Input_Field.Text (S.Active_Find_Input));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Active_Find_Input_Delete_Forward;

   procedure Execute_Active_Find_Input_Move_Cursor_Left
     (S : in out Editor.State.State_Type) is
   begin
      if S.Active_Find_Prompt then
         Editor.Input_Field.Set_Text
           (S.Active_Find_Input, To_String (S.Active_Find_Query));
         Editor.Input_Field.Move_Cursor_Left (S.Active_Find_Input);
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Execute_Active_Find_Input_Move_Cursor_Left;

   procedure Execute_Active_Find_Input_Move_Cursor_Right
     (S : in out Editor.State.State_Type) is
   begin
      if S.Active_Find_Prompt then
         Editor.Input_Field.Set_Text
           (S.Active_Find_Input, To_String (S.Active_Find_Query));
         Editor.Input_Field.Move_Cursor_Right (S.Active_Find_Input);
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Execute_Active_Find_Input_Move_Cursor_Right;

   procedure Execute_Active_Find_Input_Move_Cursor_Start
     (S : in out Editor.State.State_Type) is
   begin
      if S.Active_Find_Prompt then
         Editor.Input_Field.Set_Text
           (S.Active_Find_Input, To_String (S.Active_Find_Query));
         Editor.Input_Field.Move_Cursor_Start (S.Active_Find_Input);
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Execute_Active_Find_Input_Move_Cursor_Start;

   procedure Execute_Active_Find_Input_Move_Cursor_End
     (S : in out Editor.State.State_Type) is
   begin
      if S.Active_Find_Prompt then
         Editor.Input_Field.Set_Text
           (S.Active_Find_Input, To_String (S.Active_Find_Query));
         Editor.Input_Field.Move_Cursor_End (S.Active_Find_Input);
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Execute_Active_Find_Input_Move_Cursor_End;

end Editor.Executor.Find_Replace_Input_Commands;
