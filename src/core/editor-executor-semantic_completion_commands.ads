with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Commands.Availability_Metadata;
with Editor.State;

package Editor.Executor.Semantic_Completion_Commands is

   function Semantic_Popup_Is_Active
     (S : Editor.State.State_Type) return Boolean;

   function Semantic_Completion_Popup_Is_Active
     (S : Editor.State.State_Type) return Boolean;

   function Semantic_Completion_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Command_Ids.Command_Id)
      return Editor.Commands.Availability_Metadata.Command_Availability;

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
