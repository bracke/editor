with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Ada_Language_Model;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.State;

package Editor.Executor.Semantic_Navigation_Commands is

   type Semantic_Symbol is record
      Available : Boolean := False;
      Name      : Unbounded_String := Null_Unbounded_String;
      Kind      : Editor.Ada_Language_Model.Symbol_Kind :=
        Editor.Ada_Language_Model.Symbol_Unknown;
      Profile   : Unbounded_String := Null_Unbounded_String;
   end record;

   function Semantic_Navigation_Command_Availability
     (S      : Editor.State.State_Type;
      Id     : Editor.Commands.Command_Id;
      Symbol : Semantic_Symbol)
      return Editor.Commands.Command_Availability;

   function Execute_Semantic_Navigation_Command
     (S      : in out Editor.State.State_Type;
      Id     : Editor.Commands.Command_Id;
      Symbol : Semantic_Symbol)
      return Editor.Command_Execution.Command_Execution_Result;

end Editor.Executor.Semantic_Navigation_Commands;
