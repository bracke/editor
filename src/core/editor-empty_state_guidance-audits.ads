with Editor.Commands;
with Editor.Executor;
with Editor.State;

package Editor.Empty_State_Guidance.Audits is

   function Assert_Guided_Action_Routing_Coherent
     (S : Editor.State.State_Type) return Boolean;

   function Assert_Render_Empty_State_Construction_Is_Observational
     (Before : Editor.State.State_Type;
      After  : Editor.State.State_Type) return Boolean;

   function Assert_Empty_State_Not_Persisted
     (Before : Editor.State.State_Type;
      After  : Editor.State.State_Type) return Boolean;

   function Assert_Empty_State_Activation_Uses_Executor
     (Before : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Command : Editor.Commands.Command_Id) return Boolean;

   function Assert_Major_Empty_State_Surface_Coverage
     (S : Editor.State.State_Type) return Boolean;

   function Assert_First_Use_Empty_State_Guidance_Coherent return Boolean;

end Editor.Empty_State_Guidance.Audits;
