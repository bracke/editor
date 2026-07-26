package body Editor.Command_Ids is

   function Command_Count return Natural
   is
   begin
      return Command_Id'Pos (Command_Id'Last) - Command_Id'Pos (Command_Id'First) + 1;
   end Command_Count;

   function Command_At
     (Index : Positive) return Command_Id
   is
   begin
      pragma Assert (Index <= Command_Count, "Editor.Command_Ids.Command_At index out of range");
      return Command_Id'Val (Command_Id'Pos (Command_Id'First) + Index - 1);
   end Command_At;

end Editor.Command_Ids;
