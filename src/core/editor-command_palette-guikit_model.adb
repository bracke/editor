with Ada.Containers; use type Ada.Containers.Count_Type;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Guikit.Palette;
with Editor.Commands.Name_Metadata;
with Editor.Keybindings;

package body Editor.Command_Palette.Guikit_Model is

   function Search_Descriptors
     (Descriptors       : Editor.Commands.Descriptors.Command_Descriptor_Vectors.Vector;
      Query             : String;
      Show_Keybindings  : Boolean)
      return Editor.Commands.Descriptors.Command_Descriptor_Vectors.Vector
   is
      Search_Items   : Guikit.Palette.Item_Vectors.Vector;
      Search_Results : Guikit.Palette.Item_Vectors.Vector;
      Result         : Editor.Commands.Descriptors.Command_Descriptor_Vectors.Vector;
   begin
      if Descriptors.Length = 0 then
         return Result;
      end if;

      for I in Descriptors.First_Index .. Descriptors.Last_Index loop
         declare
            D : constant Editor.Commands.Descriptors.Command_Descriptor :=
              Descriptors.Element (I);
            Binding : constant Editor.Keybindings.Command_Keybinding_Info :=
              Editor.Keybindings.Primary_Binding_For_Command (D.Id);
         begin
            Search_Items.Append
              (Guikit.Palette.Item'
                (Id          => Natural (I),
                 Identifier  => To_Unbounded_String
                   (Editor.Commands.Name_Metadata.Stable_Command_Name (D.Id)),
                 Label       => D.Name,
                 Description => D.Description,
                 Shortcut    =>
                   (if Show_Keybindings
                    then Binding.Display
                    else Null_Unbounded_String),
                 Enabled     => True,
                 Score       => 0));
         end;
      end loop;

      Search_Results := Guikit.Palette.Search (Query, Search_Items);

      for Item of Search_Results loop
         if Item.Id in Descriptors.First_Index .. Descriptors.Last_Index then
            Result.Append (Descriptors.Element (Item.Id));
         end if;
      end loop;

      return Result;
   end Search_Descriptors;

end Editor.Command_Palette.Guikit_Model;
