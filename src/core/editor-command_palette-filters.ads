with Editor.Commands.Descriptors;
with Editor.Commands.Palette_Model;

package Editor.Command_Palette.Filters is

   procedure Clear_Transient_Filters;

   function Transient_Filters_Clear return Boolean;

   procedure Set_Availability_Filter
     (Filter : Command_Palette_Availability_Filter);

   function Current_Availability_Filter
      return Command_Palette_Availability_Filter;

   procedure Set_Category_Filter_Label (Label : String);

   procedure Clear_Category_Filter;

   function Has_Category_Filter return Boolean;

   function Current_Category_Filter_Label return String;

   procedure Set_Destructive_Filter (Enabled : Boolean);

   function Destructive_Filter_Enabled return Boolean;

   procedure Set_Keybinding_Filter
     (Filter : Command_Palette_Keybinding_Filter);

   function Current_Keybinding_Filter return Command_Palette_Keybinding_Filter;

   function Candidate_Passes_Transient_Filters
     (Candidate : Editor.Commands.Palette_Model.Command_Palette_Candidate) return Boolean;

   function Descriptor_Passes_Transient_Metadata_Filters
     (Descriptor : Editor.Commands.Descriptors.Command_Descriptor) return Boolean;

end Editor.Command_Palette.Filters;
