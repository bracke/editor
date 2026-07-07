with Editor.State;
with Editor.Commands;

package Editor.Executor.Semantic_Completion_Commands is

   function Semantic_Popup_Is_Active
     (S : Editor.State.State_Type) return Boolean;

   function Semantic_Completion_Popup_Is_Active
     (S : Editor.State.State_Type) return Boolean;

   function Semantic_Completion_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   procedure Execute_Semantic_Completion_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind);

   procedure Clear_Semantic_Popup
     (S : in out Editor.State.State_Type);

   procedure Execute_Semantic_Popup_Dismiss
     (S : in out Editor.State.State_Type);

   procedure Execute_Semantic_Completion_Select
     (S    : in out Editor.State.State_Type;
      Next : Boolean);

   procedure Execute_Semantic_Completion_Accept
     (S : in out Editor.State.State_Type);

end Editor.Executor.Semantic_Completion_Commands;
