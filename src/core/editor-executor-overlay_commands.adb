with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Buffer_Switcher;
with Editor.Command_Palette;
with Editor.Executor.File_Target_Prompt_Commands;
with Editor.Feature_Panel;
with Editor.Feature_Search_Results;
with Editor.Focus_Management;
with Editor.Go_To_Line;
with Editor.Input_Field;
with Editor.Outline;
with Editor.Panels;
with Editor.Project;
with Editor.Project_Search_Bar;
with Editor.Quick_Open;
with Editor.Render_Cache;
with Editor.Search;

package body Editor.Executor.Overlay_Commands is

   use type Editor.Overlay_Focus.Overlay_Target;
   use type Editor.Panels.Bottom_Panel_Content;

   function Is_Focus_Target_Still_Valid
     (S      : Editor.State.State_Type;
      Target : Editor.Overlay_Focus.Previous_Focus_Target) return Boolean
   is
   begin
      case Target is
         when Editor.Overlay_Focus.Previous_Editor_Text =>
            return True;
         when Editor.Overlay_Focus.Previous_File_Tree =>
            return Editor.Project.Has_Project (S.Project)
              and then Editor.Panels.Is_Visible
                (S.Panels, Editor.Panels.File_Tree_Panel);
         when Editor.Overlay_Focus.Previous_Search_Results =>
            return Editor.Panels.Is_Visible
                (S.Panels, Editor.Panels.Bottom_Panel)
              and then Editor.Panels.Active_Bottom_Content (S.Panels) =
                Editor.Panels.Search_Results_Content;
         when Editor.Overlay_Focus.Previous_Problems =>
            return Editor.Panels.Is_Visible
                (S.Panels, Editor.Panels.Bottom_Panel)
              and then Editor.Panels.Active_Bottom_Content (S.Panels) =
                Editor.Panels.Problems_Content;
         when Editor.Overlay_Focus.Previous_None =>
            return False;
      end case;
   end Is_Focus_Target_Still_Valid;
   procedure Restore_Previous_Overlay_Focus
     (S      : in out Editor.State.State_Type;
      Target : Editor.Overlay_Focus.Previous_Focus_Target)
   is
      pragma Unreferenced (Target);
   begin
      --  overlay dismissal must restore focus through the unified
      --  focus-management path.  The older direct Panel_Focus restore left
      --  stale transient owners (Build UI/result/output, Recent Projects,
      --  embedded inputs) alive, so a dismissed overlay could visually return
      --  to File Tree/Search/Problems while Effective_Focus_Owner still chose
      --  an unrelated higher-priority transient owner.
      Editor.Focus_Management.Restore_Previous_Focus_Or_Editor (S);
   end Restore_Previous_Overlay_Focus;
   procedure Close_Overlay_Surface
     (S       : in out Editor.State.State_Type;
      Overlay : Editor.Overlay_Focus.Overlay_Target)
   is
   begin
      case Overlay is
         when Editor.Overlay_Focus.Command_Palette_Overlay =>
            Editor.Command_Palette.Close;
         when Editor.Overlay_Focus.Quick_Open_Overlay =>
            Editor.Quick_Open.Close (S.Quick_Open);
         when Editor.Overlay_Focus.Buffer_Switcher_Overlay =>
            Editor.Buffer_Switcher.Close (S.Buffer_Switcher);
         when Editor.Overlay_Focus.Project_Search_Bar_Overlay =>
            Editor.Project_Search_Bar.Close (S.Project_Search_Bar);
         when Editor.Overlay_Focus.Active_Find_Prompt_Overlay =>
            Editor.Input_Field.Clear (S.Active_Find_Input);
            if S.Active_Find_Prompt then
               Editor.Input_Field.Set_Text (S.Active_Find_Input, "");
               S.Active_Find_Query := Null_Unbounded_String;
               S.Active_Find_Matches.Clear;
               S.Active_Find_Match := Editor.Search.No_Match;
               S.Active_Find_Stale := False;
               S.Active_Find_Wrapped := False;
               S.Active_Find_Case_Sensitive := False;
               S.Active_Find_Whole_Word := False;
               S.Active_Find_Source_Buffer_Token := 0;
               S.Active_Find_Prompt := False;
               S.Active_Replace_Text := Null_Unbounded_String;
               S.Active_Replace_Error_Message := Null_Unbounded_String;
               S.Active_Replace_Prompt := False;
            end if;
         when Editor.Overlay_Focus.Go_To_Line_Overlay =>
            Editor.Go_To_Line.Clear (S.Go_To_Line);
         when Editor.Overlay_Focus.File_Target_Prompt_Overlay =>
            Editor.Executor.File_Target_Prompt_Commands.Clear_File_Target_Prompt (S);
         when Editor.Overlay_Focus.No_Overlay =>
            null;
      end case;
   end Close_Overlay_Surface;
   procedure Clear_Lower_Priority_Focus_For_Overlay
     (S : in out Editor.State.State_Type)
   is
   begin
      --  Opening an overlay makes that overlay the single transient input
      --  owner.  Retain only structural Panel_Focus as previous-focus
      --  context; clear lower-priority explicit owners that would otherwise
      --  coexist with the overlay and fail coherence checks.
      Editor.Feature_Panel.Set_Focused (S.Feature_Panel, False);
      S.Build_UI.Build_UI_Focused := False;
      S.Latest_Build_Result_Focused := False;
      S.Latest_Build_Output_Details.Build_Output_Details_Focused := False;
      S.Recent_Projects_Focused := False;

      if Editor.Feature_Search_Results.Search_Input_Is_Active
        (S.Feature_Search_Results)
      then
         Editor.Feature_Search_Results.Deactivate_Search_Query_Input
           (S.Feature_Search_Results);
      end if;

      if Editor.Outline.Filter_Input_Is_Active (S.Outline) then
         Editor.Outline.Deactivate_Filter_Input (S.Outline);
      end if;
   end Clear_Lower_Priority_Focus_For_Overlay;

   procedure Activate_Overlay
     (S       : in out Editor.State.State_Type;
      Overlay : Editor.Overlay_Focus.Overlay_Target)
   is
      Current  : constant Editor.Overlay_Focus.Overlay_Target :=
        Editor.Overlay_Focus.Active_Overlay (S.Overlay_Focus);
      Previous : constant Editor.Overlay_Focus.Previous_Focus_Target :=
        (if Editor.Overlay_Focus.Has_Active_Overlay (S.Overlay_Focus)
         then Editor.Overlay_Focus.Previous_Focus (S.Overlay_Focus)
         else Editor.Overlay_Focus.Current_Panel_Focus_Target (S.Panel_Focus));
   begin
      if Overlay = Editor.Overlay_Focus.No_Overlay then
         return;
      end if;

      Clear_Lower_Priority_Focus_For_Overlay (S);

      if Current /= Editor.Overlay_Focus.No_Overlay and then Current /= Overlay then
         --  A visible active Find prompt, and Quick Open behind a file-target
         --  prompt, may remain open but inactive while another overlay owns
         --  keyboard input.
         if Current /= Editor.Overlay_Focus.Active_Find_Prompt_Overlay
           and then not
             (Current = Editor.Overlay_Focus.Quick_Open_Overlay
              and then Overlay = Editor.Overlay_Focus.File_Target_Prompt_Overlay)
         then
            Close_Overlay_Surface (S, Current);
         end if;
         Editor.Overlay_Focus.Dismiss
           (S.Overlay_Focus,
            Editor.Overlay_Focus.Dismiss_Replaced_By_Other_Overlay);
      end if;

      Editor.Overlay_Focus.Activate_With_Previous
        (S.Overlay_Focus, Overlay, Previous);

      case Overlay is
         when Editor.Overlay_Focus.Command_Palette_Overlay =>
            Editor.Quick_Open.Close (S.Quick_Open);
            Editor.Buffer_Switcher.Close (S.Buffer_Switcher);
            Editor.Project_Search_Bar.Close (S.Project_Search_Bar);
            Editor.Go_To_Line.Clear (S.Go_To_Line);
            Editor.Command_Palette.Open;
         when Editor.Overlay_Focus.Quick_Open_Overlay =>
            Editor.Command_Palette.Close;
            Editor.Buffer_Switcher.Close (S.Buffer_Switcher);
            Editor.Project_Search_Bar.Close (S.Project_Search_Bar);
            Editor.Go_To_Line.Clear (S.Go_To_Line);
            Editor.Quick_Open.Open (S.Quick_Open);
         when Editor.Overlay_Focus.Buffer_Switcher_Overlay =>
            Editor.Command_Palette.Close;
            Editor.Quick_Open.Close (S.Quick_Open);
            Editor.Project_Search_Bar.Close (S.Project_Search_Bar);
            Editor.Go_To_Line.Clear (S.Go_To_Line);
            Editor.Buffer_Switcher.Open (S.Buffer_Switcher);
         when Editor.Overlay_Focus.Project_Search_Bar_Overlay =>
            Editor.Command_Palette.Close;
            Editor.Quick_Open.Close (S.Quick_Open);
            Editor.Buffer_Switcher.Close (S.Buffer_Switcher);
            Editor.Go_To_Line.Clear (S.Go_To_Line);
            Editor.Project_Search_Bar.Open (S.Project_Search_Bar);
         when Editor.Overlay_Focus.Active_Find_Prompt_Overlay =>
            if not S.Active_Find_Prompt then
               Editor.Input_Field.Set_Text (S.Active_Find_Input, To_String (S.Active_Find_Query));
            end if;
         when Editor.Overlay_Focus.Go_To_Line_Overlay =>
            Editor.Command_Palette.Close;
            Editor.Quick_Open.Close (S.Quick_Open);
            Editor.Buffer_Switcher.Close (S.Buffer_Switcher);
            Editor.Project_Search_Bar.Close (S.Project_Search_Bar);
            Editor.Executor.File_Target_Prompt_Commands.Clear_File_Target_Prompt (S);
            Editor.Go_To_Line.Open (S.Go_To_Line);
         when Editor.Overlay_Focus.File_Target_Prompt_Overlay =>
            Editor.Command_Palette.Close;
            Editor.Buffer_Switcher.Close (S.Buffer_Switcher);
            Editor.Project_Search_Bar.Close (S.Project_Search_Bar);
            Editor.Go_To_Line.Clear (S.Go_To_Line);
         when Editor.Overlay_Focus.No_Overlay =>
            null;
      end case;

      Editor.Render_Cache.Invalidate_All;
   end Activate_Overlay;

   procedure Deactivate_Active_Overlay_Only
     (S      : in out Editor.State.State_Type;
      Reason : Editor.Overlay_Focus.Overlay_Dismissal_Reason)
   is
      Current  : constant Editor.Overlay_Focus.Overlay_Target :=
        Editor.Overlay_Focus.Active_Overlay (S.Overlay_Focus);
      Previous : constant Editor.Overlay_Focus.Previous_Focus_Target :=
        Editor.Overlay_Focus.Previous_Focus (S.Overlay_Focus);
   begin
      if Current = Editor.Overlay_Focus.No_Overlay then
         return;
      end if;

      Restore_Previous_Overlay_Focus (S, Previous);
      Editor.Overlay_Focus.Dismiss (S.Overlay_Focus, Reason);
      Editor.Render_Cache.Invalidate_All;
   end Deactivate_Active_Overlay_Only;
   procedure Dismiss_Active_Overlay
     (S      : in out Editor.State.State_Type;
      Reason : Editor.Overlay_Focus.Overlay_Dismissal_Reason)
   is
      Current  : constant Editor.Overlay_Focus.Overlay_Target :=
        Editor.Overlay_Focus.Active_Overlay (S.Overlay_Focus);
      Previous : constant Editor.Overlay_Focus.Previous_Focus_Target :=
        Editor.Overlay_Focus.Previous_Focus (S.Overlay_Focus);
   begin
      if Current = Editor.Overlay_Focus.No_Overlay then
         return;
      end if;

      Close_Overlay_Surface (S, Current);
      Restore_Previous_Overlay_Focus (S, Previous);
      Editor.Overlay_Focus.Dismiss (S.Overlay_Focus, Reason);
      Editor.Render_Cache.Invalidate_All;
   end Dismiss_Active_Overlay;

   ------------------------------------------------------------------------
   --  Primary caret helpers
   ------------------------------------------------------------------------

end Editor.Executor.Overlay_Commands;
