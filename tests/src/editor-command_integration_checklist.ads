with Editor.Commands;

package Editor.Command_Integration_Checklist is

   procedure Assert_Ready_For_User_Command
     (Id : Editor.Commands.Command_Id);

   procedure Assert_Ready_For_Bindable_Command
     (Id : Editor.Commands.Command_Id);

   procedure Assert_Ready_For_Destructive_Command
     (Id : Editor.Commands.Command_Id);

   procedure Assert_Ready_For_Configuration_Command
     (Id : Editor.Commands.Command_Id);

   procedure Assert_Ready_For_Lifecycle_Command
     (Id : Editor.Commands.Command_Id);

end Editor.Command_Integration_Checklist;
