with Ada.Strings;
with Ada.Strings.Fixed;
with Editor.Commands;
with Editor.Messages;
with Editor.State;
with Editor.View;

package body Editor.Executor.Shared_Services is

   function Current_Message_Time_Ms return Natural
   is
      Now : constant Duration := Editor.View.Current_Time_Seconds;
   begin
      if Now <= 0.0 then
         return 0;
      elsif Now >= Duration (Natural'Last / 1000) then
         return Natural'Last;
      else
         return Natural (Float (Now) * 1000.0);
      end if;
   end Current_Message_Time_Ms;

   function Default_Message_Config return Editor.Messages.Message_Config
   is
   begin
      return (Default_Lifetime_Ms   => 3_000,
              Error_Lifetime_Ms     => 5_000,
              Max_Visible_Messages  => 3,
              Max_Text_Columns      => 220,
              Replace_Same_Category => True);
   end Default_Message_Config;


   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      Editor.Messages.Push_Info
        (S.Messages, Editor.Commands.Normalize_Workflow_Message (Text),
         Current_Message_Time_Ms, Default_Message_Config);
   end Report_Info;

   procedure Report_Info_Raw
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      Editor.Messages.Push_Info
        (S.Messages, Text, Current_Message_Time_Ms, Default_Message_Config);
   end Report_Info_Raw;

   function Append_Message_Config return Editor.Messages.Message_Config
   is
      Config : Editor.Messages.Message_Config := Default_Message_Config;
   begin
      Config.Max_Visible_Messages := Natural'Last / 2;
      Config.Replace_Same_Category := False;
      return Config;
   end Append_Message_Config;

   procedure Report_Info_Append
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      Editor.Messages.Push_Info
        (S.Messages, Editor.Commands.Normalize_Workflow_Message (Text),
         Current_Message_Time_Ms, Append_Message_Config);
   end Report_Info_Append;

   procedure Report_Success_Append
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      Editor.Messages.Push_Success
        (S.Messages, Text, Current_Message_Time_Ms, Append_Message_Config);
   end Report_Success_Append;

   function Visible_Restore_Message_In_History
     (S : Editor.State.State_Type) return Boolean
   is
      Now    : constant Natural := Current_Message_Time_Ms;
      Config : constant Editor.Messages.Message_Config := Default_Message_Config;
      Count  : constant Natural :=
        Editor.Messages.Visible_Count (S.Messages, Now, Config);
   begin
      for I in 1 .. Count loop
         declare
            Text : constant String :=
              Editor.Messages.Text
                (Editor.Messages.Visible_Message (S.Messages, I, Now, Config));
         begin
            if Text = "Workspace restored."
              or else Ada.Strings.Fixed.Index
                (Text, "Workspace restored. restore details:") = Text'First
              or else Text = "Workspace restored with missing entries skipped."
              or else Ada.Strings.Fixed.Index
                (Text, "Workspace restored with missing entries skipped. restore details:") =
                  Text'First
            then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Visible_Restore_Message_In_History;

   procedure Report_Warning_Raw
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      Editor.Messages.Push_Warning
        (S.Messages, Text, Current_Message_Time_Ms, Default_Message_Config);
   end Report_Warning_Raw;


   function Command_Requires_Explicit_Target
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      return Editor.Commands.Command_Requires_Explicit_Target (Id);
   end Command_Requires_Explicit_Target;

   procedure Report_Success
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      Editor.Messages.Push_Success
        (S.Messages, Text, Current_Message_Time_Ms, Default_Message_Config);
   end Report_Success;

   procedure Report_Warning
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      Editor.Messages.Push_Warning
        (S.Messages, Editor.Commands.Normalize_Workflow_Message (Text),
         Current_Message_Time_Ms, Default_Message_Config);
   end Report_Warning;


   procedure Report_Error
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      Editor.Messages.Push_Error
        (S.Messages, Editor.Commands.Normalize_Workflow_Message (Text),
         Current_Message_Time_Ms, Default_Message_Config);
   end Report_Error;


end Editor.Executor.Shared_Services;
