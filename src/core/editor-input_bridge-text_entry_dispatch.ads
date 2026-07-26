with Editor.Commands.Payloads;
with Editor.State;

package Editor.Input_Bridge.Text_Entry_Dispatch is

   function Handle_Guided_Prompt_Input
     (S                          : in out Editor.State.State_Type;
      Cmd                        : Editor.Commands.Payloads.Command;
      Accept_Guided_Prompt_Enter : not null access procedure;
      Report_Info                : not null access procedure (Text : String))
      return Boolean;

end Editor.Input_Bridge.Text_Entry_Dispatch;
