with Editor.Focus_Management;
with Editor.Render_Cache;

package body Editor.Input_Bridge.Command_Routing is

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

end Editor.Input_Bridge.Command_Routing;
