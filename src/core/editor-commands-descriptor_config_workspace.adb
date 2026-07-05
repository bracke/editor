with Editor.Commands.Descriptor_Factory;

package body Editor.Commands.Descriptor_Config_Workspace is

   function Make_Descriptor
     (Id          : Command_Id;
      Name        : String;
      Description : String;
      Category    : Command_Category;
      Visibility  : Command_Visibility) return Command_Descriptor
   is
      Effective_Description : constant String :=
        (if Id = No_Command then Description
         elsif Description'Length = 0 then "Execute " & Name & "."
         else Description);
   begin
      return Descriptor_Factory.Make_Command_Descriptor
        (Id            => Id,
         Stable_Name   => Stable_Command_Name (Id),
         Label         => Name,
         Description   => Effective_Description,
         Category      => Category,
         Visible       => Visibility = Palette_Command,
         Bindable      => Id /= No_Command
           and then not Is_Public_Build_Command (Id),
         Destructive   => Is_Destructive_Command (Id),
         Lifecycle     => Is_Lifecycle_Command (Id),
         Configuration => Is_Configuration_Command (Id));
   end Make_Descriptor;

   function Descriptor
     (Id : Command_Id) return Command_Descriptor
   is
   begin
      case Id is
         when Command_Reset_Settings_To_Defaults =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reset Settings to Defaults",
               Description => "Reset global editor preferences to built-in defaults.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Validate_Keybindings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Validate Keybindings",
               Description => "Validate active keybindings against known commands and conflicts.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Show =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Keybindings",
               Description => "Show the keybinding management surface.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Focus =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus Keybindings",
               Description => "Focus the keybinding management surface.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Assign_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Assign Selected Keybinding",
               Description => "Start explicit shortcut capture for the selected bindable command.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Remove_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Remove Selected Keybinding",
               Description => "Remove the selected user keybinding or selected chord.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Reset_To_Defaults =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reset Keybindings to Defaults",
               Description => "Request explicit reset of user keybinding overrides to defaults.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Filter_Conflicts =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Filter Keybinding Conflicts",
               Description => "Show keybindings with active/default conflicts.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Filter_Unbound =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Filter Unbound Commands",
               Description => "Show bindable commands that currently have no active shortcut.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Clear_Filter =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Keybinding Filter",
               Description => "Clear the keybinding filter text.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Cancel_Capture =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Cancel Keybinding Capture",
               Description => "Cancel pending keybinding capture or replacement confirmation.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Startup_Show_Summary =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Startup Summary",
               Description => "Show the startup and recovery summary without loading, saving, or repairing configuration.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Recover_Show =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Configuration Recovery",
               Description => "Show bounded configuration recovery status for settings, keybindings, workspace, and recent projects.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Audit =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Review Configuration",
               Description => "Review configuration and recovery readiness without changing settings.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Reset_Settings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reset Settings Domain",
               Description => "Reset settings to safe defaults without touching keybindings, workspace, or recent projects.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Reset_Keybindings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reset Keybindings Domain",
               Description => "Reset keybindings to safe defaults without touching settings, workspace, or recent projects.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Reset_Workspace =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reset Workspace Domain",
               Description => "Clear structural workspace state without touching settings, keybindings, or recent projects.",
               Category    => Workspace_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Reset_Recent_Projects =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reset Recent Projects Domain",
               Description => "Clear recent projects without touching settings, keybindings, or workspace state.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Reset_All =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reset All Configuration Domains",
               Description => "Request explicit confirmation before resetting settings, keybindings, workspace, and recent projects.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Reset_All_Confirm =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Confirm Reset All Configuration Domains",
               Description => "Confirm the pending reset-all request; project files and dirty buffers are not changed.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Reset_All_Cancel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Cancel Reset All Configuration Domains",
               Description => "Cancel the pending reset-all confirmation without changing configuration domains.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Save_Clean_Settings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save Clean Settings",
               Description => "Write supported settings fields only; does not write other configuration domains.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Save_Clean_Keybindings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save Clean Keybindings",
               Description => "Write normalized valid keybindings only; does not write settings or workspace state.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Save_Clean_Workspace =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save Clean Workspace",
               Description => "Write structural workspace fields only; does not write settings, keybindings, or recent projects.",
               Category    => Workspace_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Save_Clean_Recent_Projects =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save Clean Recent Projects",
               Description => "Write lightweight recent project entries only; does not write workspace or settings data.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Restore_Workspace_State =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Restore Workspace",
               Description => "Restore saved workspace/session state without saving or restoring unsaved text.",
               Category    => Workspace_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Workspace_State =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Workspace State",
               Description => "Delete the saved structural workspace/session state for the current project; does not delete project files.",
               Category    => Workspace_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Feature_Panel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Feature Panel",
               Description => "Show or hide the feature panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Show_Feature_Panel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Feature Panel",
               Description => "Show the feature panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Hide_Feature_Panel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Hide Feature Panel",
               Description => "Hide the feature panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Focus_Feature_Panel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus Feature Panel",
               Description => "Move focus to the feature panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Feature_Panel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Feature Panel",
               Description => "Clear feature panel rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Feature_Panel_Select_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Feature Panel Select Next",
               Description => "Select the next feature panel row.",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when Command_Feature_Panel_Select_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Feature Panel Select Previous",
               Description => "Select the previous feature panel row.",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when Command_Feature_Panel_Open_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Selected Feature Panel Row",
               Description => "Open the selected feature panel row.",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when others =>
            raise Program_Error with "command is not owned by Descriptor_Config_Workspace";
      end case;
   end Descriptor;

end Editor.Commands.Descriptor_Config_Workspace;
