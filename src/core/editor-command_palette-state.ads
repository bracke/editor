with Editor.Input_Field;

package Editor.Command_Palette.State is

   type Palette_State_Access is access all Palette_State;
   type Command_Palette_Config_Access is access all Command_Palette_Config;
   type Input_Field_State_Access is access all Editor.Input_Field.Input_Field_State;

   function Mutable_Palette_State return Palette_State_Access;

   function Mutable_Config return Command_Palette_Config_Access;

   function Mutable_Filter_Field return Input_Field_State_Access;

end Editor.Command_Palette.State;
