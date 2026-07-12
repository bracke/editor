with Editor.State;

package Editor.Executor.Buffer_Switcher_Pending_Mark_Review_Commands is

   procedure Execute_Buffer_Switcher_Pending_Mark_Review_Show
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Review_Hide
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Review_Toggle
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Pruned_Summary
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Pruned_Next
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Pruned_Previous
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Pruned_Review_Show
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Pruned_Review_Hide
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Pruned_Review_Toggle
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Summary
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Next
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Previous
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Remove_Selected
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Restore_Selected_Pruned
     (S : in out Editor.State.State_Type);

end Editor.Executor.Buffer_Switcher_Pending_Mark_Review_Commands;
