with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Executor.Quick_Open_Commands;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Overlay_Focus;
with Editor.Project;
with Editor.Quick_Open;
use type Editor.Quick_Open.Quick_Open_Priority_Mode;
with Editor.Render_Cache;
with Editor.State;

package body Editor.Executor.Quick_Open_Context_Commands is

   function Quick_Open_Reveal_Query_For_Path (Path : String) return String is
      Result : Unbounded_String := Null_Unbounded_String;
      Last   : Natural := Path'Last;
      First  : Positive := Path'First;
   begin
      if Path'Length = 0 then
         return "";
      end if;

      while Last > Path'First and then Path (Last) = '/' loop
         Last := Last - 1;
      end loop;

      if Last < First then
         return "";
      end if;

      for I in First .. Last loop
         if Path (I) = '/' then
            Result := To_Unbounded_String (To_String (Result) & "/");
         else
            Result := To_Unbounded_String (To_String (Result) & Path (I));
         end if;
      end loop;

      return To_String (Result);
   end Quick_Open_Reveal_Query_For_Path;

   procedure Execute_Quick_Open_Reveal_Active
     (S : in out Editor.State.State_Type)
   is
      Found_Path : Boolean := False;
      Path       : constant String := Editor.Executor.Active_Buffer_Known_Project_File (S, Found_Path);
      Query      : constant String := Quick_Open_Reveal_Query_For_Path (Path);
      Selected   : Boolean := False;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Shared_Services.Report_Info (S, "No project open");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif not Editor.State.Has_Active_Buffer (S) then
         Editor.Executor.Shared_Services.Report_Info (S, "No active buffer.");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif not Found_Path then
         Editor.Executor.Shared_Services.Report_Info (S, "Active buffer is not a known project file");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      if not Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Quick_Open_Overlay)
      then
         Editor.Executor.Quick_Open_Commands.Execute_Open_Quick_Open (S);
      end if;
      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, Query);
      Editor.Executor.Quick_Open_Commands.Recompute_Quick_Open (S);
      Editor.Quick_Open.Select_Path (S.Quick_Open, Path, Selected);

      if Selected then
         Editor.Executor.Shared_Services.Report_Info (S, "Quick Open selected active file: " & Path);
      else
         Editor.Executor.Shared_Services.Report_Info (S, "Active buffer is not a known project file");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Quick_Open_Reveal_Active;

   procedure Execute_Quick_Open_Scope_Active_Directory
     (S : in out Editor.State.State_Type)
   is
      Found_Path : Boolean := False;
      Selected   : Boolean := False;
      Keep_Open_Recent_Priority : constant Boolean :=
        Editor.Quick_Open.Priority_Mode (S.Quick_Open) =
        Editor.Quick_Open.Open_Recent;
      Path       : constant String := Editor.Executor.Active_Buffer_Known_Project_File (S, Found_Path);
      Scope      : constant String := Editor.Quick_Open.Directory_Scope_Of_Path (Path);
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Shared_Services.Report_Info (S, "No project open");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif not Editor.State.Has_Active_Buffer (S) then
         Editor.Executor.Shared_Services.Report_Info (S, "No active buffer.");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif not Found_Path then
         Editor.Executor.Shared_Services.Report_Info (S, "Active buffer is not a known project file");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Editor.Executor.Activate_Overlay (S, Editor.Overlay_Focus.Quick_Open_Overlay);
      if Keep_Open_Recent_Priority
        and then Editor.Quick_Open.Priority_Mode (S.Quick_Open) =
          Editor.Quick_Open.Path
      then
         Editor.Quick_Open.Toggle_Priority_Mode (S.Quick_Open);
      end if;
      Editor.Quick_Open.Set_Query_Text
        (S.Quick_Open, Quick_Open_Reveal_Query_For_Path (Path));
      Editor.Quick_Open.Clear_File_Kind_Filter (S.Quick_Open);
      Editor.Quick_Open.Set_Path_Scope (S.Quick_Open, Scope);
      Editor.Executor.Quick_Open_Commands.Recompute_Quick_Open (S);
      Editor.Quick_Open.Select_Path (S.Quick_Open, Path, Selected);

      if not Selected then
         Editor.Executor.Shared_Services.Report_Info (S, "Active buffer is not a known project file");
      elsif Scope'Length = 0 then
         Editor.Executor.Shared_Services.Report_Info (S, "Quick Open scope cleared");
      else
         Editor.Executor.Shared_Services.Report_Info (S, "Quick Open scope: " & Scope);
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Quick_Open_Scope_Active_Directory;

end Editor.Executor.Quick_Open_Context_Commands;
