with Editor.Commands;

package body Editor.Command_Execution is

   use type Editor.Commands.Command_Id;

   function Make_Result
     (Status  : Command_Execution_Status;
      Command : Editor.Commands.Command_Id)
      return Command_Execution_Result
   is
   begin
      return (Status => Status, Command => Command);
   end Make_Result;

   function Executed
     (Command : Editor.Commands.Command_Id)
      return Command_Execution_Result
   is
   begin
      if Command = Editor.Commands.No_Command then
         return No_Op (Command);
      end if;
      return Make_Result (Command_Executed, Command);
   end Executed;

   function Unavailable
     (Command : Editor.Commands.Command_Id)
      return Command_Execution_Result
   is
   begin
      return Make_Result (Command_Unavailable, Command);
   end Unavailable;

   function Failed
     (Command : Editor.Commands.Command_Id)
      return Command_Execution_Result
   is
   begin
      return Make_Result (Command_Failed, Command);
   end Failed;

   function Cancelled
     (Command : Editor.Commands.Command_Id)
      return Command_Execution_Result
   is
   begin
      return Make_Result (Command_Cancelled, Command);
   end Cancelled;

   function No_Op
     (Command : Editor.Commands.Command_Id)
      return Command_Execution_Result
   is
   begin
      return Make_Result (Command_No_Op, Command);
   end No_Op;

   function Is_Terminal
     (Result : Command_Execution_Result) return Boolean
   is
      pragma Unreferenced (Result);
   begin
      return True;
   end Is_Terminal;

   function Is_Success
     (Result : Command_Execution_Result) return Boolean
   is
   begin
      return Result.Status = Command_Executed;
   end Is_Success;

   function Is_User_Blocking
     (Result : Command_Execution_Result) return Boolean
   is
   begin
      return Result.Status = Command_Unavailable
        or else Result.Status = Command_Failed;
   end Is_User_Blocking;

   function Status_Name
     (Status : Command_Execution_Status) return String
   is
   begin
      case Status is
         when Command_Executed =>
            return "executed";
         when Command_Unavailable =>
            return "unavailable";
         when Command_Failed =>
            return "failed";
         when Command_Cancelled =>
            return "cancelled";
         when Command_No_Op =>
            return "no-op";
      end case;
   end Status_Name;

   function Summary
     (Result : Command_Execution_Result) return String
   is
   begin
      return Editor.Commands.Command_Id'Image (Result.Command)
        & ":" & Status_Name (Result.Status);
   end Summary;

end Editor.Command_Execution;
