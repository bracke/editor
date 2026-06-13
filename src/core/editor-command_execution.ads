with Editor.Commands;

package Editor.Command_Execution is

   type Command_Execution_Status is
     (Command_Executed,
      Command_Unavailable,
      Command_Failed,
      Command_Cancelled,
      Command_No_Op);

   type Command_Execution_Result is record
      Status  : Command_Execution_Status := Command_No_Op;
      Command : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   end record;

   --  Build a successful execution result for Command.
   --  @param Command stable command id associated with the invocation
   --  @return structured executed result
   function Executed
     (Command : Editor.Commands.Command_Id)
      return Command_Execution_Result;

   --  Build an unavailable execution result for Command.
   --  @param Command stable command id associated with the invocation
   --  @return structured unavailable result
   function Unavailable
     (Command : Editor.Commands.Command_Id)
      return Command_Execution_Result;

   --  Build a failed execution result for Command.
   --  @param Command stable command id associated with the invocation
   --  @return structured failed result
   function Failed
     (Command : Editor.Commands.Command_Id)
      return Command_Execution_Result;

   --  Build a cancelled execution result for Command.
   --  @param Command stable command id associated with the invocation
   --  @return structured cancelled result
   function Cancelled
     (Command : Editor.Commands.Command_Id)
      return Command_Execution_Result;

   --  Build an intentional no-op execution result for Command.
   --  @param Command stable command id associated with the invocation
   --  @return structured no-op result
   function No_Op
     (Command : Editor.Commands.Command_Id)
      return Command_Execution_Result;

   --  Return whether Result represents a completed command-invocation
   --  classification.  All current statuses are terminal: the result model
   --  describes an already-resolved invocation and never schedules work.
   --  @param Result execution result to inspect
   --  @return True for all resolved execution statuses
   function Is_Terminal
     (Result : Command_Execution_Result) return Boolean;

   --  Return True for statuses that are successful command outcomes.
   --  Command_No_Op is intentional and terminal, but not a mutation success.
   --  @param Result execution result to inspect
   --  @return True only for Command_Executed.
   function Is_Success
     (Result : Command_Execution_Result) return Boolean;

   --  Return True for outcomes that represent user-visible execution failure.
   --  Unavailable is a guarded non-attempt; failed means attempted and failed.
   --  @param Result execution result to inspect
   --  @return True for Command_Unavailable and Command_Failed.
   function Is_User_Blocking
     (Result : Command_Execution_Result) return Boolean;

   --  Return a stable lowercase status name for assertions and diagnostics.
   --  @param Status execution status to describe
   --  @return Stable status label.
   function Status_Name
     (Status : Command_Execution_Status) return String;

   --  Return a compact deterministic summary for audit failure messages.
   --  @param Result execution result to describe
   --  @return Summary containing command image and status name.
   function Summary
     (Result : Command_Execution_Result) return String;

end Editor.Command_Execution;
