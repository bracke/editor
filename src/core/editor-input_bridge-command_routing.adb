with Editor.Focus_Management;
with Editor.Executor;
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

end Editor.Input_Bridge.Command_Routing;
