with Editor.Command_Ids; use Editor.Command_Ids;

package Editor.Command_Integration_Checklist is

   procedure Assert_Ready_For_User_Command
     (Id : Editor.Command_Ids.Command_Id);

   procedure Assert_Ready_For_Bindable_Command
     (Id : Editor.Command_Ids.Command_Id);

   procedure Assert_Ready_For_Destructive_Command
     (Id : Editor.Command_Ids.Command_Id);

   procedure Assert_Ready_For_Configuration_Command
     (Id : Editor.Command_Ids.Command_Id);

   procedure Assert_Ready_For_Lifecycle_Command
     (Id : Editor.Command_Ids.Command_Id);

end Editor.Command_Integration_Checklist;
