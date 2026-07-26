with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.State;

package Editor.Input_Bridge.Command_Prompt_Routing is

   function Command_Starts_Guided_Prompt
     (Id : Editor.Command_Ids.Command_Id) return Boolean;

   function Command_Starts_Confirmation_Prompt
     (Id : Editor.Command_Ids.Command_Id) return Boolean;

   procedure Start_Guided_Prompt_For_Command
     (S           : in out Editor.State.State_Type;
      Id          : Editor.Command_Ids.Command_Id;
      Report_Info : not null access procedure (Text : String));

end Editor.Input_Bridge.Command_Prompt_Routing;
