with Editor.Build_Output_Details;

package Editor.Build_Process_Control is

   --  Transient process-control handle for an active public build job.
   --  The handle is runtime-only state: it is never persisted, never exposed
   --  through keybindings, and never treated as a rerun payload.
   type Build_Process_Handle is private;

   type Build_Process_Cancel_Result is
     (Build_Process_Cancel_Sent,
      Build_Process_Cancel_Not_Active,
      Build_Process_Cancel_Not_Cancellable,
      Build_Process_Cancel_Failed);

   function No_Process_Handle return Build_Process_Handle;

   function From_System_Process_Id
     (System_Process_Id : Integer) return Build_Process_Handle;

   function Test_Cancellable_Handle return Build_Process_Handle;

   function Is_Active
     (Handle : Build_Process_Handle) return Boolean;

   function Is_Cancellable
     (Handle : Build_Process_Handle) return Boolean;

   procedure Publish_Active_Process
     (Handle : Build_Process_Handle);

   procedure Clear_Active_Process;

   function Active_Process_Handle return Build_Process_Handle;

   procedure Publish_Active_Output_Stream
     (Stream : Editor.Build_Output_Details.Build_Output_Stream_State);

   procedure Active_Output_Stream
     (Stream : out Editor.Build_Output_Details.Build_Output_Stream_State;
      Available : out Boolean);

   function Active_Cancel_Requested return Boolean;

   function Request_Active_Cancel return Build_Process_Cancel_Result;

   function Request_Cancel
     (Handle : in out Build_Process_Handle) return Build_Process_Cancel_Result;

private
   type Build_Process_Handle is record
      Active            : Boolean := False;
      Cancellable       : Boolean := False;
      System_Process_Id : Integer := 0;
      Test_Handle       : Boolean := False;
      Cancel_Requested  : Boolean := False;
   end record;

end Editor.Build_Process_Control;
