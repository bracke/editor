with Editor.Feature_Messages;

package body Editor.Feature_Messages.Fixtures is

   procedure Add_Test_Message
     (Messages     : in out Editor.Feature_Messages.Message_Feature_State;
      Label        : String;
      Detail       : String := "";
      Buffer_Token : Natural := 0)
   is
   begin
      Editor.Feature_Messages.Add_Message
        (Messages   => Messages,
         Severity   => Editor.Feature_Messages.Info_Message,
         Text       => Label,
         Source     => Detail,
         Has_Target => Buffer_Token /= 0,
         Buffer     => Buffer_Token,
         Line       => (if Buffer_Token = 0 then 0 else 1),
         Column     => (if Buffer_Token = 0 then 0 else 1));
   end Add_Test_Message;

   procedure Set_Test_Rows
     (Messages     : in out Editor.Feature_Messages.Message_Feature_State;
      Buffer_Token : Natural := 0)
   is
   begin
      Editor.Feature_Messages.Clear_Messages (Messages);
      Add_Test_Message
        (Messages, "Messages test row ready",
         "deterministic messages fixture", Buffer_Token);
   end Set_Test_Rows;

end Editor.Feature_Messages.Fixtures;
