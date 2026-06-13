with Editor.Build_Output_Details;
with Interfaces.C;

package body Editor.Build_Process_Control is

   use type Interfaces.C.int;

   SIGTERM : constant Interfaces.C.int := 15;

   protected type Active_Build_Process_State is
      procedure Publish_Process (Handle : Build_Process_Handle);
      procedure Clear_Process;
      function Process_Handle return Build_Process_Handle;

      procedure Publish_Output_Stream
        (Stream : Editor.Build_Output_Details.Build_Output_Stream_State);
      procedure Output_Stream
        (Stream : out Editor.Build_Output_Details.Build_Output_Stream_State;
         Available : out Boolean);

      function Cancel_Requested return Boolean;
      procedure Mark_Cancel_Requested;
      procedure Update_Process_Handle (Handle : Build_Process_Handle);
   private
      Published_Active_Handle : Build_Process_Handle :=
        (Active            => False,
         Cancellable       => False,
         System_Process_Id => 0,
         Test_Handle       => False,
         Cancel_Requested  => False);
      Published_Output_Stream : Editor.Build_Output_Details.Build_Output_Stream_State;
      Has_Published_Output_Stream : Boolean := False;
      Published_Cancel_Requested : Boolean := False;
   end Active_Build_Process_State;

   protected body Active_Build_Process_State is
      procedure Publish_Process (Handle : Build_Process_Handle) is
      begin
         Published_Active_Handle := Handle;
         Published_Cancel_Requested := False;
         Has_Published_Output_Stream := False;
      end Publish_Process;

      procedure Clear_Process is
      begin
         Published_Active_Handle := No_Process_Handle;
         Published_Cancel_Requested := False;
         Has_Published_Output_Stream := False;
      end Clear_Process;

      function Process_Handle return Build_Process_Handle is
      begin
         return Published_Active_Handle;
      end Process_Handle;

      procedure Publish_Output_Stream
        (Stream : Editor.Build_Output_Details.Build_Output_Stream_State)
      is
      begin
         Published_Output_Stream := Stream;
         Has_Published_Output_Stream := True;
      end Publish_Output_Stream;

      procedure Output_Stream
        (Stream : out Editor.Build_Output_Details.Build_Output_Stream_State;
         Available : out Boolean)
      is
      begin
         Stream := Published_Output_Stream;
         Available := Has_Published_Output_Stream;
      end Output_Stream;

      function Cancel_Requested return Boolean is
      begin
         return Published_Cancel_Requested
           or else Published_Active_Handle.Cancel_Requested;
      end Cancel_Requested;

      procedure Mark_Cancel_Requested is
      begin
         Published_Cancel_Requested := True;
         Published_Active_Handle.Cancel_Requested := True;
      end Mark_Cancel_Requested;

      procedure Update_Process_Handle (Handle : Build_Process_Handle) is
      begin
         Published_Active_Handle := Handle;
         if Handle.Cancel_Requested then
            Published_Cancel_Requested := True;
         end if;
      end Update_Process_Handle;
   end Active_Build_Process_State;

   Active_Process_State : Active_Build_Process_State;

   function C_Kill
     (Pid    : Interfaces.C.int;
      Signal : Interfaces.C.int) return Interfaces.C.int
   with Import, Convention => C, External_Name => "kill";

   function No_Process_Handle return Build_Process_Handle is
   begin
      return (others => <>);
   end No_Process_Handle;

   function From_System_Process_Id
     (System_Process_Id : Integer) return Build_Process_Handle
   is
   begin
      if System_Process_Id <= 0 then
         return No_Process_Handle;
      end if;

      return
        (Active            => True,
         Cancellable       => True,
         System_Process_Id => System_Process_Id,
         Test_Handle       => False,
         Cancel_Requested  => False);
   end From_System_Process_Id;

   function Test_Cancellable_Handle return Build_Process_Handle is
   begin
      return
        (Active            => True,
         Cancellable       => True,
         System_Process_Id => 0,
         Test_Handle       => True,
         Cancel_Requested  => False);
   end Test_Cancellable_Handle;

   function Is_Active
     (Handle : Build_Process_Handle) return Boolean
   is
   begin
      return Handle.Active;
   end Is_Active;

   function Is_Cancellable
     (Handle : Build_Process_Handle) return Boolean
   is
   begin
      return Handle.Active and then Handle.Cancellable;
   end Is_Cancellable;

   procedure Publish_Active_Process
     (Handle : Build_Process_Handle)
   is
   begin
      Active_Process_State.Publish_Process (Handle);
   end Publish_Active_Process;

   procedure Clear_Active_Process is
   begin
      Active_Process_State.Clear_Process;
   end Clear_Active_Process;

   function Active_Process_Handle return Build_Process_Handle is
   begin
      return Active_Process_State.Process_Handle;
   end Active_Process_Handle;

   procedure Publish_Active_Output_Stream
     (Stream : Editor.Build_Output_Details.Build_Output_Stream_State)
   is
   begin
      Active_Process_State.Publish_Output_Stream (Stream);
   end Publish_Active_Output_Stream;

   procedure Active_Output_Stream
     (Stream : out Editor.Build_Output_Details.Build_Output_Stream_State;
      Available : out Boolean)
   is
   begin
      Active_Process_State.Output_Stream (Stream, Available);
   end Active_Output_Stream;

   function Active_Cancel_Requested return Boolean is
   begin
      return Active_Process_State.Cancel_Requested;
   end Active_Cancel_Requested;

   function Request_Active_Cancel return Build_Process_Cancel_Result is
      Handle : Build_Process_Handle := Active_Process_State.Process_Handle;
      Result : Build_Process_Cancel_Result;
   begin
      Result := Request_Cancel (Handle);
      if Result = Build_Process_Cancel_Sent then
         Active_Process_State.Mark_Cancel_Requested;
      else
         Active_Process_State.Update_Process_Handle (Handle);
      end if;
      return Result;
   end Request_Active_Cancel;

   function Request_Cancel
     (Handle : in out Build_Process_Handle) return Build_Process_Cancel_Result
   is
      RC : Interfaces.C.int;
   begin
      if not Handle.Active then
         return Build_Process_Cancel_Not_Active;
      elsif not Handle.Cancellable then
         return Build_Process_Cancel_Not_Cancellable;
      elsif Handle.Cancel_Requested then
         return Build_Process_Cancel_Sent;
      elsif Handle.Test_Handle then
         Handle.Cancel_Requested := True;
         return Build_Process_Cancel_Sent;
      elsif Handle.System_Process_Id <= 0 then
         return Build_Process_Cancel_Not_Cancellable;
      end if;

      RC := C_Kill (Interfaces.C.int (Handle.System_Process_Id), SIGTERM);
      if RC = 0 then
         Handle.Cancel_Requested := True;
         return Build_Process_Cancel_Sent;
      else
         return Build_Process_Cancel_Failed;
      end if;
   exception
      when others =>
         return Build_Process_Cancel_Failed;
   end Request_Cancel;

end Editor.Build_Process_Control;
