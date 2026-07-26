package Editor.Commands.Registry is

   function First_Command return Command_Id;

   function Last_Command return Command_Id;

   function Next_Command
     (Id    : Command_Id;
      Found : out Boolean) return Command_Id;

   function First_Concrete_Command return Command_Id;

   function Concrete_Command_Count return Natural;

   procedure For_Each_Command
     (Process : not null access procedure (Id : Command_Id));

   function Is_Valid_Command
     (Id : Command_Id) return Boolean;

   function Palette_Command_Count return Natural;

   function Palette_Command_At
     (Index : Positive) return Command_Id;

end Editor.Commands.Registry;
