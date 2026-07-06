with Editor.Focus_Management;
with Editor.Executor;
with Editor.Feature_Search_Results;
with Editor.Outline;
with Editor.Overlay_Focus;
with Editor.Render_Cache;

package body Editor.Input_Bridge.Command_Routing is

   use type Editor.Commands.Command_Id;

   function Handle_Pending_Confirmation_Gate
     (S      : Editor.State.State_Type;
      Id     : Editor.Commands.Command_Id;
      Report : not null access procedure (Message : String)) return Boolean
   is
   begin
      if Editor.Focus_Management.Pending_Confirmation_Owns_Focus (S)
        and then Editor.Focus_Management.Command_Is_Conflicting_While_Pending (Id)
      then
         Report ("Command unavailable while confirmation is pending");
         Editor.Render_Cache.Invalidate_All;
         return True;
      end if;

      return False;
   end Handle_Pending_Confirmation_Gate;

   function Handle_Current_Focus_Gate
     (S      : Editor.State.State_Type;
      Id     : Editor.Commands.Command_Id;
      Report : not null access procedure (Message : String)) return Boolean
   is
   begin
      if not Editor.Focus_Management.Command_May_Run_In_Current_Focus (S, Id) then
         Report ("Command unavailable for current focus");
         Editor.Render_Cache.Invalidate_All;
         return True;
      end if;

      return False;
   end Handle_Current_Focus_Gate;

   function Handle_Command_Availability_Gate
     (S      : Editor.State.State_Type;
      Id     : Editor.Commands.Command_Id;
      Report : not null access procedure (Message : String)) return Boolean
   is
      Availability : constant Editor.Commands.Command_Availability :=
        Editor.Executor.Command_Availability (S, Id);
   begin
      if not Editor.Commands.Is_Available (Availability) then
         Report (Editor.Commands.Unavailable_Reason (Availability));
         Editor.Render_Cache.Invalidate_All;
         return True;
      end if;

      return False;
   end Handle_Command_Availability_Gate;

   function Handle_Guided_Prompt_Start_Availability_Gate
     (S      : Editor.State.State_Type;
      Id     : Editor.Commands.Command_Id;
      Report : not null access procedure (Message : String)) return Boolean
   is
      Availability_Id : constant Editor.Commands.Command_Id :=
        (if Id = Editor.Commands.Command_Rename_Symbol_Apply
         then Editor.Commands.Command_Rename_Symbol_Preview
         else Id);
      Availability : constant Editor.Commands.Command_Availability :=
        Editor.Executor.Command_Availability (S, Availability_Id);
   begin
      if not Editor.Commands.Is_Available (Availability) then
         Report (Editor.Commands.Unavailable_Reason (Availability));
         Editor.Render_Cache.Invalidate_All;
         return True;
      end if;

      return False;
   end Handle_Guided_Prompt_Start_Availability_Gate;

   function Handle_Active_Overlay
     (S                         : in out Editor.State.State_Type;
      Cmd                       : Editor.Commands.Command;
      Handle_Command_Palette    : not null access function
        (Cmd : Editor.Commands.Command) return Boolean;
      Handle_Quick_Open         : not null access function
        (Cmd : Editor.Commands.Command) return Boolean;
      Handle_Buffer_Switcher    : not null access function
        (Cmd : Editor.Commands.Command) return Boolean;
      Handle_Project_Search_Bar : not null access function
        (Cmd : Editor.Commands.Command) return Boolean;
      Handle_Goto_Line          : not null access function
        (Cmd : Editor.Commands.Command) return Boolean;
      Handle_Active_Find_Input  : not null access function
        (Cmd : Editor.Commands.Command) return Boolean;
      Handle_File_Target_Prompt : not null access function
        (Cmd : Editor.Commands.Command) return Boolean)
      return Boolean
   is
      Handled : Boolean := False;
   begin
      if not Editor.Overlay_Focus.Has_Active_Overlay (S.Overlay_Focus) then
         return False;
      end if;

      case Editor.Overlay_Focus.Active_Overlay (S.Overlay_Focus) is
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

      if Handled then
         null;
      end if;
      return True;
   end Handle_Active_Overlay;

   function Handle_Focused_Panel_Input
     (S                           : in out Editor.State.State_Type;
      Cmd                         : Editor.Commands.Command;
      Handle_Search_Query_Input   : not null access function
        (Cmd : Editor.Commands.Command) return Boolean;
      Handle_Outline_Filter_Input : not null access function
        (Cmd : Editor.Commands.Command) return Boolean)
      return Boolean
   is
      Handled : Boolean := False;
   begin
      if Editor.Feature_Search_Results.Search_Input_Is_Active
        (S.Feature_Search_Results)
      then
         Handled := Handle_Search_Query_Input (Cmd);
         if Handled then
            null;
         end if;
         return True;
      end if;

      if Editor.Outline.Filter_Input_Is_Active (S.Outline) then
         Handled := Handle_Outline_Filter_Input (Cmd);
         if Handled then
            null;
         end if;
         return True;
      end if;

      return False;
   end Handle_Focused_Panel_Input;

end Editor.Input_Bridge.Command_Routing;
