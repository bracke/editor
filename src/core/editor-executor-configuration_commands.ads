with Editor.Command_Execution;
with Editor.Commands;
with Editor.State;

package Editor.Executor.Configuration_Commands is

   function Configuration_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   procedure Execute_Startup_Show_Summary
     (S : in out Editor.State.State_Type);

   procedure Execute_Configuration_Recover_Show
     (S : in out Editor.State.State_Type);

   procedure Execute_Configuration_Audit
     (S : in out Editor.State.State_Type);

   procedure Execute_Configuration_Reset_Settings
     (S : in out Editor.State.State_Type);

   procedure Execute_Configuration_Reset_Keybindings
     (S : in out Editor.State.State_Type);

   procedure Execute_Configuration_Reset_Workspace
     (S : in out Editor.State.State_Type);

   procedure Execute_Configuration_Reset_Recent_Projects
     (S : in out Editor.State.State_Type);

   procedure Execute_Configuration_Reset_All
     (S : in out Editor.State.State_Type);

   procedure Execute_Configuration_Reset_All_Confirm
     (S : in out Editor.State.State_Type);

   procedure Execute_Configuration_Reset_All_Cancel
     (S : in out Editor.State.State_Type);

   procedure Execute_Configuration_Save_Clean_Settings
     (S : in out Editor.State.State_Type);

   procedure Execute_Configuration_Save_Clean_Keybindings
     (S : in out Editor.State.State_Type);

   procedure Execute_Configuration_Save_Clean_Workspace
     (S : in out Editor.State.State_Type);

   procedure Execute_Configuration_Save_Clean_Recent_Projects
     (S : in out Editor.State.State_Type);

   procedure Execute_Save_Settings
     (S : in out Editor.State.State_Type);

   procedure Execute_Reload_Settings
     (S : in out Editor.State.State_Type);

   procedure Execute_Reset_Settings_To_Defaults
     (S : in out Editor.State.State_Type);

   procedure Execute_Save_Keybindings
     (S : in out Editor.State.State_Type);

   procedure Execute_Reload_Keybindings
     (S : in out Editor.State.State_Type);

   procedure Execute_Validate_Keybindings
     (S : in out Editor.State.State_Type);

   procedure Execute_Keybinding_UI_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id);

   function Execute_Configuration_Result_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result;

   procedure Execute_Configuration_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind);

end Editor.Executor.Configuration_Commands;
