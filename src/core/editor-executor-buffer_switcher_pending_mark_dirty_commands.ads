with Editor.Commands;
with Editor.State;

package Editor.Executor.Buffer_Switcher_Pending_Mark_Dirty_Commands is

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind);

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Summary
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Next
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Previous
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Next
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Toggle
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Cancel
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Summary
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Next
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Previous
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Stale_Summary
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed
     (S : in out Editor.State.State_Type);

end Editor.Executor.Buffer_Switcher_Pending_Mark_Dirty_Commands;
