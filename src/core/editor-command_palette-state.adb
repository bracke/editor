with Editor.Input_Field;

package body Editor.Command_Palette.State is

   Palette : aliased Palette_State;
   Config  : aliased Command_Palette_Config;
   Field   : aliased Editor.Input_Field.Input_Field_State;

   function Mutable_Palette_State return Palette_State_Access is
   begin
      return Palette'Access;
   end Mutable_Palette_State;

   function Mutable_Config return Command_Palette_Config_Access is
   begin
      return Config'Access;
   end Mutable_Config;

   function Mutable_Filter_Field return Input_Field_State_Access is
   begin
      return Field'Access;
   end Mutable_Filter_Field;

end Editor.Command_Palette.State;
