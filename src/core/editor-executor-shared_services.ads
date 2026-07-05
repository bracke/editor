with Editor.Commands;
with Editor.Messages;
with Editor.State;

package Editor.Executor.Shared_Services is

   function Command_Requires_Explicit_Target
     (Id : Editor.Commands.Command_Id) return Boolean;

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Report_Info_Raw
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Report_Success
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Report_Warning
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Report_Warning_Raw
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Report_Error
     (S    : in out Editor.State.State_Type;
      Text : String);

   function Current_Message_Time_Ms return Natural;

   function Default_Message_Config return Editor.Messages.Message_Config;

   procedure Report_Info_Append
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Report_Success_Append
     (S    : in out Editor.State.State_Type;
      Text : String);

   function Visible_Restore_Message_In_History
     (S : Editor.State.State_Type) return Boolean;

end Editor.Executor.Shared_Services;
