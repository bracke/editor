with Editor.State;

package Editor.Executor.Semantic_Completion_Commands is

   function Semantic_Completion_Popup_Is_Active
     (S : Editor.State.State_Type) return Boolean;

   procedure Clear_Semantic_Popup
     (S : in out Editor.State.State_Type);

   procedure Execute_Semantic_Completion_Select
     (S    : in out Editor.State.State_Type;
      Next : Boolean);

   procedure Execute_Semantic_Completion_Accept
     (S : in out Editor.State.State_Type);

end Editor.Executor.Semantic_Completion_Commands;
