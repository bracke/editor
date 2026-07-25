with Editor.Build_Process_Control;
with Editor.External_Producers;
with Editor.External_Producers.Build_Types;
with Editor.External_Producers.Build_Requests;
with Editor.State;

package Editor.Build_Command.Registry is

   Max_Public_Build_Async_Slots : constant Positive := 8;
   subtype Public_Build_Async_Slot_Index is Positive range 1 .. Max_Public_Build_Async_Slots;

   function Slot_Index_For (Slot_Id : Natural) return Public_Build_Async_Slot_Index;

   type Boolean_By_Public_Build_Slot is array (Public_Build_Async_Slot_Index) of Boolean;
   type Natural_By_Public_Build_Slot is array (Public_Build_Async_Slot_Index) of Natural;
   type State_By_Public_Build_Slot is array (Public_Build_Async_Slot_Index) of Editor.State.State_Type;
   type Build_Request_By_Public_Build_Slot is array (Public_Build_Async_Slot_Index) of Editor.External_Producers.Build_Types.Build_Run_Request;
   type Build_Gate_By_Public_Build_Slot is array (Public_Build_Async_Slot_Index) of Editor.External_Producers.Build_Types.Build_Execution_Gate;
   type Build_Result_By_Public_Build_Slot is array (Public_Build_Async_Slot_Index) of Editor.External_Producers.Build_Requests.Build_Command_Result;

   protected Public_Build_Slot_Allocator is
      procedure Allocate (Slot_Id : out Natural);
   private
      Next_Slot_Id : Natural := 0;
   end Public_Build_Slot_Allocator;

   protected Public_Build_Worker_Lifecycle is
      procedure Request_Stop;
      procedure Mark_Stopped;
      function Stop_Requested return Boolean;
      function Stopped return Boolean;
   private
      Stop_Requested_Flag : Boolean := False;
      Stopped_Flag        : Boolean := False;
   end Public_Build_Worker_Lifecycle;

   protected type Public_Build_Job_Registry is
      procedure Store_Queued
        (Slot_Id        : Natural;
         State_Snapshot : Editor.State.State_Type;
         Request        : Editor.External_Producers.Build_Types.Build_Run_Request;
         Runner_Gate    : Editor.External_Producers.Build_Types.Build_Execution_Gate;
         Result_Gate    : Editor.External_Producers.Build_Types.Build_Execution_Gate;
         Job_Id         : Natural);

      procedure Worker_Input
        (Slot_Id        : Natural;
         State_Snapshot : out Editor.State.State_Type;
         Request        : out Editor.External_Producers.Build_Types.Build_Run_Request;
         Runner_Gate    : out Editor.External_Producers.Build_Types.Build_Execution_Gate);

      procedure Store_Worker_Result
        (Slot_Id        : Natural;
         State_Snapshot : Editor.State.State_Type;
         Result         : Editor.External_Producers.Build_Requests.Build_Command_Result);

      procedure Mark_Worker_Running (Slot_Id : Natural);
      procedure Mark_Cancellation_Requested (Slot_Id : Natural);
      procedure Clear (Slot_Id : Natural);

      function Has_Job (Slot_Id : Natural; Job_Id : Natural) return Boolean;
      function Result_Ready (Slot_Id : Natural) return Boolean;
      function Worker_Running (Slot_Id : Natural) return Boolean;
      function Slot_Available_For (Slot_Id : Natural) return Boolean;

      procedure Snapshot_While_Running
        (Slot_Id        : Natural;
         State_Snapshot : out Editor.State.State_Type);

      procedure Final_Result
        (Slot_Id        : Natural;
         State_Snapshot : out Editor.State.State_Type;
         Request        : out Editor.External_Producers.Build_Types.Build_Run_Request;
         Result_Gate    : out Editor.External_Producers.Build_Types.Build_Execution_Gate;
         Result         : out Editor.External_Producers.Build_Requests.Build_Command_Result);
   private
      Occupied      : Boolean_By_Public_Build_Slot := (others => False);
      Running       : Boolean_By_Public_Build_Slot := (others => False);
      Ready         : Boolean_By_Public_Build_Slot := (others => False);
      Stored_Slot_Id : Natural_By_Public_Build_Slot := (others => 0);
      Stored_Job_Id : Natural_By_Public_Build_Slot := (others => 0);
      Stored_State  : State_By_Public_Build_Slot;
      Stored_Request : Build_Request_By_Public_Build_Slot;
      Stored_Runner_Gate : Build_Gate_By_Public_Build_Slot;
      Stored_Result_Gate : Build_Gate_By_Public_Build_Slot;
      Stored_Result : Build_Result_By_Public_Build_Slot;
   end Public_Build_Job_Registry;

   Public_Build_Jobs : Public_Build_Job_Registry;

   task type Public_Build_Worker is
      entry Start (Slot_Id : Natural);
      entry Drain (Slot_Id : Natural);
      entry Stop;
   end Public_Build_Worker;

   type Public_Build_Worker_Array is array (Public_Build_Async_Slot_Index) of Public_Build_Worker;
   Public_Build_Workers : Public_Build_Worker_Array;

end Editor.Build_Command.Registry;
