with Editor.Build_Process_Control;
with Editor.External_Producers;
with Editor.External_Producers.Build_Types;
with Editor.External_Producers.Build_Requests;
with Editor.Build_Runner_Policy;
with Editor.State;

package body Editor.Build_Command.Registry is

   function Slot_Index_For (Slot_Id : Natural) return Public_Build_Async_Slot_Index is
   begin
      if Slot_Id = 0 then
         return Public_Build_Async_Slot_Index'First;
      end if;
      return Public_Build_Async_Slot_Index
        (((Slot_Id - 1) mod Max_Public_Build_Async_Slots) + 1);
   end Slot_Index_For;

   protected body Public_Build_Slot_Allocator is
      procedure Allocate (Slot_Id : out Natural) is
      begin
         if Next_Slot_Id = Natural'Last then
            Next_Slot_Id := 1;
         else
            Next_Slot_Id := Next_Slot_Id + 1;
         end if;
         Slot_Id := Next_Slot_Id;
      end Allocate;
   end Public_Build_Slot_Allocator;

   protected body Public_Build_Worker_Lifecycle is
      procedure Request_Stop is
      begin
         Stop_Requested_Flag := True;
      end Request_Stop;

      procedure Mark_Stopped is
      begin
         Stop_Requested_Flag := True;
         Stopped_Flag := True;
      end Mark_Stopped;

      function Stop_Requested return Boolean is
      begin
         return Stop_Requested_Flag;
      end Stop_Requested;

      function Stopped return Boolean is
      begin
         return Stopped_Flag;
      end Stopped;
   end Public_Build_Worker_Lifecycle;

   protected body Public_Build_Job_Registry is
      procedure Store_Queued
        (Slot_Id        : Natural;
         State_Snapshot : Editor.State.State_Type;
         Request        : Editor.External_Producers.Build_Types.Build_Run_Request;
         Runner_Gate    : Editor.External_Producers.Build_Types.Build_Execution_Gate;
         Result_Gate    : Editor.External_Producers.Build_Types.Build_Execution_Gate;
         Job_Id         : Natural)
      is
         Index : constant Public_Build_Async_Slot_Index := Slot_Index_For (Slot_Id);
      begin
         if Occupied (Index) and then Stored_Slot_Id (Index) /= Slot_Id then
            return;
         end if;

         Stored_Slot_Id (Index) := Slot_Id;
         Stored_State (Index) := State_Snapshot;
         Stored_Request (Index) := Request;
         Stored_Runner_Gate (Index) := Runner_Gate;
         Stored_Result_Gate (Index) := Result_Gate;
         Stored_Job_Id (Index) := Job_Id;
         Occupied (Index) := True;
         Running (Index) := False;
         Ready (Index) := False;
      end Store_Queued;

      procedure Worker_Input
        (Slot_Id        : Natural;
         State_Snapshot : out Editor.State.State_Type;
         Request        : out Editor.External_Producers.Build_Types.Build_Run_Request;
         Runner_Gate    : out Editor.External_Producers.Build_Types.Build_Execution_Gate)
      is
         Index : constant Public_Build_Async_Slot_Index := Slot_Index_For (Slot_Id);
      begin
         State_Snapshot := Stored_State (Index);
         Request := Stored_Request (Index);
         Runner_Gate := Stored_Runner_Gate (Index);
      end Worker_Input;

      procedure Store_Worker_Result
        (Slot_Id        : Natural;
         State_Snapshot : Editor.State.State_Type;
         Result         : Editor.External_Producers.Build_Requests.Build_Command_Result)
      is
         Index : constant Public_Build_Async_Slot_Index := Slot_Index_For (Slot_Id);
      begin
         if Slot_Id = Stored_Slot_Id (Index) then
            Stored_State (Index) := State_Snapshot;
            Stored_Result (Index) := Result;
            Running (Index) := False;
            Ready (Index) := True;
         end if;
      end Store_Worker_Result;

      procedure Mark_Worker_Running (Slot_Id : Natural) is
         Index : constant Public_Build_Async_Slot_Index := Slot_Index_For (Slot_Id);
      begin
         if Slot_Id = Stored_Slot_Id (Index) then
            Running (Index) := True;
            Ready (Index) := False;
         end if;
      end Mark_Worker_Running;

      procedure Mark_Cancellation_Requested (Slot_Id : Natural) is
         Index : constant Public_Build_Async_Slot_Index := Slot_Index_For (Slot_Id);
      begin
         if Slot_Id = Stored_Slot_Id (Index) then
            Stored_State (Index).Build.Public_Job_Cancellation :=
           Editor.Build_Runner_Policy.Cancellation_Requested;
         end if;
      end Mark_Cancellation_Requested;

      procedure Clear (Slot_Id : Natural) is
         Index : constant Public_Build_Async_Slot_Index := Slot_Index_For (Slot_Id);
      begin
         if Slot_Id = Stored_Slot_Id (Index) then
            Occupied (Index) := False;
            Running (Index) := False;
            Ready (Index) := False;
            Stored_Slot_Id (Index) := 0;
            Stored_Job_Id (Index) := 0;
         end if;
      end Clear;

      function Has_Job (Slot_Id : Natural; Job_Id : Natural) return Boolean is
         Index : constant Public_Build_Async_Slot_Index := Slot_Index_For (Slot_Id);
      begin
         return Occupied (Index)
           and then Stored_Slot_Id (Index) = Slot_Id
           and then Stored_Job_Id (Index) = Job_Id;
      end Has_Job;

      function Result_Ready (Slot_Id : Natural) return Boolean is
         Index : constant Public_Build_Async_Slot_Index := Slot_Index_For (Slot_Id);
      begin
         return Ready (Index) and then Slot_Id = Stored_Slot_Id (Index);
      end Result_Ready;

      function Worker_Running (Slot_Id : Natural) return Boolean is
         Index : constant Public_Build_Async_Slot_Index := Slot_Index_For (Slot_Id);
      begin
         return Running (Index) and then Slot_Id = Stored_Slot_Id (Index);
      end Worker_Running;

      function Slot_Available_For (Slot_Id : Natural) return Boolean is
         Index : constant Public_Build_Async_Slot_Index := Slot_Index_For (Slot_Id);
      begin
         return Slot_Id /= 0
           and then (not Occupied (Index) or else Stored_Slot_Id (Index) = Slot_Id);
      end Slot_Available_For;

      procedure Snapshot_While_Running
        (Slot_Id        : Natural;
         State_Snapshot : out Editor.State.State_Type)
      is
         Index : constant Public_Build_Async_Slot_Index := Slot_Index_For (Slot_Id);
      begin
         if Slot_Id = Stored_Slot_Id (Index) then
            State_Snapshot := Stored_State (Index);
         end if;
      end Snapshot_While_Running;

      procedure Final_Result
        (Slot_Id        : Natural;
         State_Snapshot : out Editor.State.State_Type;
         Request        : out Editor.External_Producers.Build_Types.Build_Run_Request;
         Result_Gate    : out Editor.External_Producers.Build_Types.Build_Execution_Gate;
         Result         : out Editor.External_Producers.Build_Requests.Build_Command_Result)
      is
         Index : constant Public_Build_Async_Slot_Index := Slot_Index_For (Slot_Id);
      begin
         if Slot_Id = Stored_Slot_Id (Index) then
            State_Snapshot := Stored_State (Index);
            Request := Stored_Request (Index);
            Result_Gate := Stored_Result_Gate (Index);
            Result := Stored_Result (Index);
         end if;
      end Final_Result;
   end Public_Build_Job_Registry;

   task body Public_Build_Worker is
      Worker_State : Editor.State.State_Type;
      Worker_Request : Editor.External_Producers.Build_Types.Build_Run_Request;
      Worker_Runner_Gate : Editor.External_Producers.Build_Types.Build_Execution_Gate;
      Worker_Result : Editor.External_Producers.Build_Requests.Build_Command_Result;
      Worker_Slot_Id : Natural := 0;
   begin
      loop
         select
            accept Start (Slot_Id : Natural) do
               Worker_Slot_Id := Slot_Id;
            end Start;
            Public_Build_Jobs.Worker_Input
              (Worker_Slot_Id, Worker_State, Worker_Request, Worker_Runner_Gate);
            Public_Build_Jobs.Mark_Worker_Running (Worker_Slot_Id);
            Worker_Result :=
              Editor.External_Producers.Build_Requests.Run_Build_Command_With_Gate
                (Worker_State, Worker_Request, Worker_Runner_Gate);
            Public_Build_Jobs.Store_Worker_Result
              (Worker_Slot_Id, Worker_State, Worker_Result);
         or
            --  Application/lifecycle shutdown drain.  The accept completes only
            --  when this slot's worker is idle, so callers can deterministically
            --  wait for a previously requested cancellation to be observed and
            --  finalized.
            accept Drain (Slot_Id : Natural) do
               Worker_Slot_Id := Slot_Id;
            end Drain;
         or
            --  Final application shutdown.  Unlike Drain, Stop terminates the
            --  app-lifetime worker task after any current Start body has
            --  completed.  New build starts are rejected once the worker
            --  lifecycle stop flag is set.
            accept Stop;
            exit;
         or
            terminate;
         end select;
      end loop;
   end Public_Build_Worker;

end Editor.Build_Command.Registry;
