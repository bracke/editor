with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands.Category_Metadata;
with Editor.Commands.Descriptor_Factory;
with Editor.Commands.Descriptor_Metadata;
with Editor.Commands.Display_Names;

package body Editor.Commands.Descriptors is

   function Make_Command_Descriptor
     (Id             : Command_Id;
      Stable_Name    : String;
      Label          : String;
      Description    : String;
      Category       : Command_Category;
      Visible        : Boolean;
      Bindable       : Boolean;
      Destructive    : Boolean := False;
      Lifecycle      : Boolean := False;
      Configuration  : Boolean := False)
      return Command_Descriptor
   is
   begin
      return Descriptor_Factory.Make_Command_Descriptor
        (Id            => Id,
         Stable_Name   => Stable_Name,
         Label         => Label,
         Description   => Description,
         Category      => Category,
         Visible       => Visible,
         Bindable      => Bindable,
         Destructive   => Destructive,
         Lifecycle     => Lifecycle,
         Configuration => Configuration);
   end Make_Command_Descriptor;

   function Descriptor
     (Id : Command_Id) return Command_Descriptor
   is
   begin
      return Descriptor_Metadata.Descriptor (Id);
   end Descriptor;

   function Label
     (Id : Command_Id) return String
   is
   begin
      return Display_Names.Label (Id);
   end Label;

   function Category
     (Id : Command_Id) return Command_Category
   is
   begin
      return Category_Metadata.Category (Id);
   end Category;

   function Category_Label
     (Category : Command_Category) return String
   is
   begin
      return Category_Metadata.Category_Label (Category);
   end Category_Label;

   function Discoverability_Category_Label
     (Id : Command_Id) return String
   is
   begin
      return Category_Metadata.Discoverability_Category_Label (Id);
   end Discoverability_Category_Label;

   function Classification_Label
     (Id : Command_Id) return String
   is
   begin
      return Category_Metadata.Classification_Label (Id);
   end Classification_Label;

   function Surface_Relevance_Label
     (Id : Command_Id) return String
   is
   begin
      return Category_Metadata.Surface_Relevance_Label (Id);
   end Surface_Relevance_Label;

   function Guard_Label
     (Id : Command_Id) return String
   is
   begin
      return Category_Metadata.Guard_Label (Id);
   end Guard_Label;

   function Palette_Commands return Command_Descriptor_Vectors.Vector is
      Result : Command_Descriptor_Vectors.Vector;
      D      : Command_Descriptor;
   begin
      for I in 1 .. Command_Count loop
         D := Descriptor (Command_At (I));
         if D.Visibility = Palette_Command then
            Result.Append (D);
         end if;
      end loop;

      return Result;
   end Palette_Commands;

end Editor.Commands.Descriptors;
