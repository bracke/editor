with Editor.Command_Ids; use Editor.Command_Ids;

package Editor.Commands.Classification is

   function Is_Navigation_Command
     (Id : Command_Id) return Boolean;

   function Is_Search_Command
     (Id : Command_Id) return Boolean;

   function Is_Panel_Focus_Command
     (Id : Command_Id) return Boolean;

   function Is_Text_Editing_Command
     (Id : Command_Id) return Boolean;

   function Is_Test_Only_Command
     (Id : Command_Id) return Boolean;

   function Is_Destructive_Command
     (Id : Command_Id) return Boolean;

   function Is_Lifecycle_Command
     (Id : Command_Id) return Boolean;

   function Is_Configuration_Command
     (Id : Command_Id) return Boolean;

   function Is_Global_Settings_Save_Command
     (Id : Command_Id) return Boolean;

   function Is_Global_Keybindings_Save_Command
     (Id : Command_Id) return Boolean;

   function Is_Bindable_Command
     (Id : Command_Id) return Boolean;

   function Is_Internal_Command
     (Id : Command_Id) return Boolean;

   function Is_Visible_In_Palette
     (Id : Command_Id) return Boolean;

   function Visible_In_Command_Palette
     (Id : Command_Id) return Boolean;

end Editor.Commands.Classification;
