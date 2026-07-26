with Editor.Commands.Payloads;
with Editor.State;

package Editor.Executor.History is

   procedure Execute
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Payloads.Command);


   procedure Log_Edit
     (Before  : Editor.State.State_Type;
      After_S : Editor.State.State_Type;
      Forward : Editor.Commands.Payloads.Command);

 function Build_Inverse_Replace_Command
     (Before  : Editor.State.State_Type;
      Forward : Editor.Commands.Payloads.Command) return Editor.Commands.Payloads.Command;

   procedure Apply_Replace_Batch_Command
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Payloads.Command);

   function Is_Typing_Groupable
     (Before  : Editor.State.State_Type;
      After_S : Editor.State.State_Type;
      Forward : Editor.Commands.Payloads.Command) return Boolean;

   procedure Break_Group;

   function Last_Operation_Failed return Boolean;

   procedure Clear_Operation_Status;

end Editor.Executor.History;