with Editor.Commands;
with Editor.State;

package Editor.Input_Bridge.Text_Entry_Routing is

   function Is_Text_Entry_Workflow_Event
     (Cmd : Editor.Commands.Command) return Boolean;

   function Is_Text_Entry_Workflow_Command_Id
     (Id : Editor.Commands.Command_Id) return Boolean;

   function Resolve_Text_Entry_Focus_Target
     (State : Editor.State.State_Type) return Text_Entry_Focus_Target;

   function Preview_Text_Entry_Route
     (State : Editor.State.State_Type;
      Cmd   : Editor.Commands.Command) return Text_Entry_Route_Result;

   function Canonical_Text_Entry_Command
     (State : Editor.State.State_Type;
      Cmd   : Editor.Commands.Command) return Editor.Commands.Command;

   function Preview_Text_Entry_Command_Id
     (State : Editor.State.State_Type;
      Cmd   : Editor.Commands.Command) return Editor.Commands.Command_Id;

end Editor.Input_Bridge.Text_Entry_Routing;
