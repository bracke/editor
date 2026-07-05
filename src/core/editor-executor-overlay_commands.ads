with Editor.Overlay_Focus;
with Editor.State;

package Editor.Executor.Overlay_Commands is

   function Is_Focus_Target_Still_Valid
     (S      : Editor.State.State_Type;
      Target : Editor.Overlay_Focus.Previous_Focus_Target) return Boolean;

   procedure Restore_Previous_Overlay_Focus
     (S      : in out Editor.State.State_Type;
      Target : Editor.Overlay_Focus.Previous_Focus_Target);

   procedure Activate_Overlay
     (S       : in out Editor.State.State_Type;
      Overlay : Editor.Overlay_Focus.Overlay_Target);

   procedure Dismiss_Active_Overlay
     (S      : in out Editor.State.State_Type;
      Reason : Editor.Overlay_Focus.Overlay_Dismissal_Reason);

   procedure Deactivate_Active_Overlay_Only
     (S      : in out Editor.State.State_Type;
      Reason : Editor.Overlay_Focus.Overlay_Dismissal_Reason);

end Editor.Executor.Overlay_Commands;
