with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Commands;
with Editor.Executor.Project_Search_Result_Commands;
with Editor.Executor.Search_Commands;
with Editor.Overlay_Focus;
with Editor.Project_Search;
with Editor.Project_Search_Bar;
with Editor.Render_Cache;
with Editor.State;

package body Editor.Executor.Project_Search_Surface_Commands is

   use type Editor.Project_Search_Bar.Project_Search_Bar_Field;

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Info;

   procedure Activate_Overlay
     (S       : in out Editor.State.State_Type;
      Overlay : Editor.Overlay_Focus.Overlay_Target)
      renames Editor.Executor.Activate_Overlay;

   procedure Dismiss_Active_Overlay
     (S      : in out Editor.State.State_Type;
      Reason : Editor.Overlay_Focus.Overlay_Dismissal_Reason)
      renames Editor.Executor.Dismiss_Active_Overlay;

   procedure Execute_Open_Project_Search_Bar
     (S : in out Editor.State.State_Type)
   is
   begin
      Activate_Overlay (S, Editor.Overlay_Focus.Project_Search_Bar_Overlay);
      Editor.Project_Search_Bar.Set_Query_Text
        (S.Project_Search_Bar, Editor.Project_Search.Query (S.Project_Search));
      Editor.Project_Search_Bar.Set_Replace_Text
        (S.Project_Search_Bar, Editor.Project_Search.Replace_Text (S.Project_Search));
      Editor.Project_Search_Bar.Open (S.Project_Search_Bar);
      Editor.Render_Cache.Invalidate_All;
      Report_Info (S, "Project Search shown.");
   end Execute_Open_Project_Search_Bar;

   procedure Execute_Close_Project_Search_Bar
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Project_Search_Bar_Overlay)
      then
         Dismiss_Active_Overlay
           (S, Editor.Overlay_Focus.Dismiss_Command);
      else
         Editor.Project_Search_Bar.Close (S.Project_Search_Bar);
         Editor.Render_Cache.Invalidate_All;
      end if;
      Report_Info (S, "Project Search hidden.");
   end Execute_Close_Project_Search_Bar;

   procedure Execute_Toggle_Project_Search_Bar
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Project_Search_Bar.Is_Open (S.Project_Search_Bar)
        and then Editor.Overlay_Focus.Is_Active
          (S.Overlay_Focus, Editor.Overlay_Focus.Project_Search_Bar_Overlay)
      then
         Execute_Close_Project_Search_Bar (S);
      else
         Execute_Open_Project_Search_Bar (S);
      end if;
   end Execute_Toggle_Project_Search_Bar;

   procedure Execute_Run_Project_Search_From_Bar
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Project_Search.Set_Replace_Text
        (S.Project_Search, Editor.Project_Search_Bar.Replace_Text (S.Project_Search_Bar));
      Editor.Executor.Project_Search_Result_Commands.Execute_Run_Project_Search
        (S, Editor.Project_Search_Bar.Query_Text (S.Project_Search_Bar));
      Editor.Project_Search_Bar.Open (S.Project_Search_Bar);
   end Execute_Run_Project_Search_From_Bar;

   procedure Sync_Project_Search_Bar_Input
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Project_Search.Set_Query
        (S.Project_Search, Editor.Project_Search_Bar.Query_Text (S.Project_Search_Bar));
      Editor.Project_Search.Set_Replace_Text
        (S.Project_Search, Editor.Project_Search_Bar.Replace_Text (S.Project_Search_Bar));
      if Editor.Project_Search_Bar.Active_Field (S.Project_Search_Bar)
        = Editor.Project_Search_Bar.Project_Search_Replace_Field
      then
         Editor.Project_Search.Set_Replace_Mode_Active (S.Project_Search, True);
      end if;
   end Sync_Project_Search_Bar_Input;

   procedure Execute_Project_Search_Bar_Insert_Text
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      if Editor.Project_Search_Bar.Is_Open (S.Project_Search_Bar) then
         Editor.Project_Search_Bar.Insert_Text (S.Project_Search_Bar, Text);
         Sync_Project_Search_Bar_Input (S);
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Execute_Project_Search_Bar_Insert_Text;

   procedure Execute_Project_Search_Bar_Backspace
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Project_Search_Bar.Is_Open (S.Project_Search_Bar) then
         Editor.Project_Search_Bar.Backspace (S.Project_Search_Bar);
         Sync_Project_Search_Bar_Input (S);
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Execute_Project_Search_Bar_Backspace;

   procedure Execute_Project_Search_Bar_Delete_Forward
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Project_Search_Bar.Is_Open (S.Project_Search_Bar) then
         Editor.Project_Search_Bar.Delete_Forward (S.Project_Search_Bar);
         Sync_Project_Search_Bar_Input (S);
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Execute_Project_Search_Bar_Delete_Forward;

   procedure Execute_Project_Search_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command)
      renames Editor.Executor.Search_Commands.Execute_Project_Search_Kind;

end Editor.Executor.Project_Search_Surface_Commands;
