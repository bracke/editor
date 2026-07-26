with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Commands.Availability_Metadata;
with Editor.Commands.Descriptor_Metadata;
with Editor.Commands.Descriptors; use Editor.Commands.Descriptors;

package body Editor.Commands.Registry is

   function First_Command return Command_Id
   is
   begin
      return Command_Id'First;
   end First_Command;

   function Last_Command return Command_Id
   is
   begin
      return Command_Id'Last;
   end Last_Command;

   function Next_Command
     (Id    : Command_Id;
      Found : out Boolean) return Command_Id
   is
   begin
      if Id = Command_Id'Last then
         Found := False;
         return No_Command;
      end if;

      Found := True;
      return Command_Id'Succ (Id);
   end Next_Command;

   function First_Concrete_Command return Command_Id
   is
   begin
      return Command_Id'Succ (No_Command);
   end First_Concrete_Command;

   function Concrete_Command_Count return Natural
   is
   begin
      return Editor.Command_Ids.Command_Count - 1;
   end Concrete_Command_Count;

   procedure For_Each_Command
     (Process : not null access procedure (Id : Command_Id))
   is
   begin
      for Id in Command_Id loop
         if Editor.Commands.Availability_Metadata.Is_Concrete_Command (Id) then
            Process (Id);
         end if;
      end loop;
   end For_Each_Command;

   function Is_Valid_Command
     (Id : Command_Id) return Boolean
   is
      pragma Unreferenced (Id);
   begin
      return True;
   end Is_Valid_Command;

   function Palette_Command_Count return Natural
   is
      Count : Natural := 0;
   begin
      for I in 1 .. Editor.Command_Ids.Command_Count loop
         if Editor.Commands.Descriptor_Metadata.Descriptor
           (Editor.Command_Ids.Command_At (I)).Visibility = Palette_Command
         then
            Count := Count + 1;
         end if;
      end loop;

      return Count;
   end Palette_Command_Count;

   function Palette_Command_At
     (Index : Positive) return Command_Id
   is
      Count : Natural := 0;
      Id    : Command_Id;
   begin
      pragma Assert
        (Index <= Palette_Command_Count,
         "Editor.Commands.Registry.Palette_Command_At index out of range");

      for I in 1 .. Editor.Command_Ids.Command_Count loop
         Id := Editor.Command_Ids.Command_At (I);
         if Editor.Commands.Descriptor_Metadata.Descriptor (Id).Visibility =
           Palette_Command
         then
            Count := Count + 1;
            if Count = Index then
               return Id;
            end if;
         end if;
      end loop;

      return No_Command;
   end Palette_Command_At;

end Editor.Commands.Registry;
