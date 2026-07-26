with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Command_Kinds;

package Editor.Commands is
   package Command_Ids renames Editor.Command_Ids;
   package Command_Kinds renames Editor.Command_Kinds;

   subtype Command_Id is Command_Ids.Command_Id;

   --  Return the number of stable command ids in registry order.
   --  @return Count of Command_Id values including No_Command.
   function Command_Count return Natural;

   --  Return the command id at a one-based registry index.
   --  @param Index One-based command registry index.
   --  @return Command identifier at Index.
   function Command_At
     (Index : Positive) return Command_Id;
   subtype Command_Kind is Command_Kinds.Command_Kind;


end Editor.Commands;
