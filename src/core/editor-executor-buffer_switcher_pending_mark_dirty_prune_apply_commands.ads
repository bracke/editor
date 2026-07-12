with Editor.State;

package Editor.Executor.Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Commands is

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Confirm
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Cancel
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Summary
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Next
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Previous
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Remove_Selected
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Restore_Last_Removed
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Clear_Stale
     (S : in out Editor.State.State_Type);

end Editor.Executor.Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Commands;
