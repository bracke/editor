with Editor.State;
with Editor.Commands;

package Editor.Executor.History is

   procedure Execute
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command);


   procedure Log_Edit
     (Before  : Editor.State.State_Type;
      After_S : Editor.State.State_Type;
      Forward : Editor.Commands.Command);

 function Build_Inverse_Replace_Command
     (Before  : Editor.State.State_Type;
      Forward : Editor.Commands.Command) return Editor.Commands.Command;

   procedure Apply_Replace_Batch_Command
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command);

   function Is_Typing_Groupable
     (Before  : Editor.State.State_Type;
      After_S : Editor.State.State_Type;
      Forward : Editor.Commands.Command) return Boolean;

   procedure Break_Group;

   function Last_Operation_Failed return Boolean;

   procedure Clear_Operation_Status;

end Editor.Executor.History;