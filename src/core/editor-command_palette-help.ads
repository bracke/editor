with Editor.Commands;
with Editor.Commands.Palette_Model;

package Editor.Command_Palette.Help is

   function Build_Command_Help
     (Candidate : Editor.Commands.Palette_Model.Command_Palette_Candidate;
      Config    : Command_Palette_Config) return Command_Help_Snapshot;

   procedure Clear_Command_State_Contexts;

   procedure Set_Command_State_Context
     (Command : Editor.Commands.Command_Id;
      Text    : String);

   function Related_Command_Is_Activation_Safe
     (Item : Related_Command_Help_Item) return Boolean;

   function Related_Command_Is_Canonical_Descriptor_Projection
     (Item : Related_Command_Help_Item) return Boolean;

   function Assert_Related_Command_Help_Is_Coherent
     (Help : Command_Help_Snapshot) return Boolean;

end Editor.Command_Palette.Help;
