package body Editor.Overlay_Focus is

   function Current_Panel_Focus_Target
     (Focus : Editor.Panel_Focus.Panel_Focus_State) return Previous_Focus_Target
   is
   begin
      case Editor.Panel_Focus.Target (Focus) is
         when Editor.Panel_Focus.Editor_Text_Focus =>
            return Previous_Editor_Text;
         when Editor.Panel_Focus.File_Tree_Focus =>
            return Previous_File_Tree;
         when Editor.Panel_Focus.Bottom_Panel_Focus =>
            case Editor.Panel_Focus.Bottom_Content (Focus) is
               when Editor.Panel_Focus.Search_Results_Focus =>
                  return Previous_Search_Results;
               when Editor.Panel_Focus.Problems_Focus =>
                  return Previous_Problems;
               when Editor.Panel_Focus.No_Bottom_Focus =>
                  return Previous_None;
            end case;
      end case;
   end Current_Panel_Focus_Target;

   procedure Clear
     (State : in out Overlay_Focus_State) is
   begin
      State.Active := No_Overlay;
      State.Previous := Previous_None;
      State.Last_Reason := Dismiss_Command;
   end Clear;

   function Active_Overlay
     (State : Overlay_Focus_State) return Overlay_Target is
   begin
      return State.Active;
   end Active_Overlay;

   function Has_Active_Overlay
     (State : Overlay_Focus_State) return Boolean is
   begin
      return State.Active /= No_Overlay;
   end Has_Active_Overlay;

   function Is_Active
     (State   : Overlay_Focus_State;
      Overlay : Overlay_Target) return Boolean is
   begin
      return State.Active = Overlay and then Overlay /= No_Overlay;
   end Is_Active;

   procedure Activate
     (State          : in out Overlay_Focus_State;
      Overlay        : Overlay_Target;
      Previous_Focus : Editor.Panel_Focus.Panel_Focus_State) is
   begin
      Activate_With_Previous
        (State,
         Overlay,
         Current_Panel_Focus_Target (Previous_Focus));
   end Activate;

   procedure Activate_With_Previous
     (State          : in out Overlay_Focus_State;
      Overlay        : Overlay_Target;
      Previous_Focus : Previous_Focus_Target) is
   begin
      if Overlay = No_Overlay then
         State.Active := No_Overlay;
         return;
      end if;

      if State.Active = No_Overlay then
         State.Previous := Previous_Focus;
      end if;

      State.Active := Overlay;
   end Activate_With_Previous;

   procedure Dismiss
     (State  : in out Overlay_Focus_State;
      Reason : Overlay_Dismissal_Reason) is
   begin
      State.Active := No_Overlay;
      State.Last_Reason := Reason;
   end Dismiss;

   function Has_Previous_Focus
     (State : Overlay_Focus_State) return Boolean is
   begin
      return State.Previous /= Previous_None;
   end Has_Previous_Focus;

   function Previous_Focus
     (State : Overlay_Focus_State) return Previous_Focus_Target is
   begin
      return State.Previous;
   end Previous_Focus;

   function Last_Dismissal_Reason
     (State : Overlay_Focus_State) return Overlay_Dismissal_Reason is
   begin
      return State.Last_Reason;
   end Last_Dismissal_Reason;

end Editor.Overlay_Focus;
