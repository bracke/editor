with Editor.External_Producers;
with Editor.State;

package Editor.Build_Command.Execution is

   function Start_Public_Build_Run_Asynchronously
     (State : in out Editor.State.State_Type)
      return Editor.External_Producers.Build_Command_Result;

   function Poll_Public_Build_Run_Completion
     (State : in out Editor.State.State_Type;
      Result : out Editor.External_Producers.Build_Command_Result) return Boolean;

   function Execute_Public_Build_Run
     (State : in out Editor.State.State_Type)
      return Editor.External_Producers.Build_Command_Result;

   function Execute_Public_Build_Run_With_Supplied_Result
     (State           : in out Editor.State.State_Type;
      Supplied_Result : Editor.External_Producers.Process_Run_Result)
      return Editor.External_Producers.Build_Command_Result;

end Editor.Build_Command.Execution;
