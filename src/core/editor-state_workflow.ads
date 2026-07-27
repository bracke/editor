with Editor.Guided_Prompts;
with Editor.Pending_Transitions;

package Editor.State_Workflow is

   type Workflow_Runtime_State is record
      Pending_Transitions : Editor.Pending_Transitions.Pending_Transition_State;
      Guided_Prompt       : Editor.Guided_Prompts.Prompt_State;
   end record;

end Editor.State_Workflow;
