with Editor.Command_Ids; use Editor.Command_Ids;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands.Descriptors; use Editor.Commands.Descriptors;
with Editor.Commands.Classification;
with Editor.Commands.Descriptor_Factory;
with Editor.Commands.Descriptor_Table;


package body Editor.Commands.Descriptor_Metadata is

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
      return Descriptor_Table.Descriptor (Id);
   end Descriptor;

   function Trimmed
     (Text : String) return String
   is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trimmed;

   function Is_Placeholder_Label
     (Text : String) return Boolean
   is
      T : constant String := Trimmed (Text);
   begin
      return T = "TODO"
        or else T = "Command"
        or else T = "Unnamed";
   end Is_Placeholder_Label;

   function Has_Descriptor
     (Id : Command_Id) return Boolean
   is
      D : constant Command_Descriptor := Descriptor (Id);
   begin
      return D.Id = Id;
   end Has_Descriptor;

   function Has_Stable_User_Label
     (Id : Command_Id) return Boolean
   is
      D : constant Command_Descriptor := Descriptor (Id);
      L : constant String := To_String (D.Name);
   begin
      return Id /= No_Command
        and then D.Id = Id
        and then L'Length > 0
        and then Trimmed (L) = L
        and then not Is_Placeholder_Label (L);
   end Has_Stable_User_Label;

end Editor.Commands.Descriptor_Metadata;
