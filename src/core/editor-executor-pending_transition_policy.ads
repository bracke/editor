with Editor.Buffers;
with Editor.Dirty_Guards;
with Editor.Pending_Transitions;
with Editor.State;

package Editor.Executor.Pending_Transition_Policy is

   function Check_Dirty_Transition
     (State : Editor.State.State_Type;
      Kind  : Editor.Dirty_Guards.Dirty_Transition_Kind)
      return Editor.Dirty_Guards.Dirty_Transition_Result;

   function Pending_Target_For
     (Kind      : Editor.Pending_Transitions.Pending_Transition_Kind;
      Path      : String := "";
      Display   : String := "";
      Buffer_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer)
      return Editor.Pending_Transitions.Pending_Transition_Target;

   procedure Set_Pending_Dirty_Transition
     (S      : in out Editor.State.State_Type;
      Target : Editor.Pending_Transitions.Pending_Transition_Target;
      Guard  : Editor.Dirty_Guards.Dirty_Transition_Result);

   function Pending_Target_Is_Valid
     (S      : Editor.State.State_Type;
      Target : Editor.Pending_Transitions.Pending_Transition_Target) return Boolean;

   function Pending_Transition_Is_Still_Valid
     (State : Editor.State.State_Type) return Boolean;

   function Pending_Project_Open_Command_Matches
     (S                   : Editor.State.State_Type;
      Path                : String;
      Recent_Project_Open : Boolean;
      Explicit_Switch     : Boolean) return Boolean;

   function Pending_Project_Close_Command_Matches
     (S : Editor.State.State_Type) return Boolean;

   procedure Invalidate_Pending_Transition_If_Stale
     (State : in out Editor.State.State_Type);

   function Check_Pending_Transition
     (S      : Editor.State.State_Type;
      Target : Editor.Pending_Transitions.Pending_Transition_Target)
      return Editor.Dirty_Guards.Dirty_Transition_Result;

end Editor.Executor.Pending_Transition_Policy;
