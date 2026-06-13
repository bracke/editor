with Editor.Feature_Messages;

package Editor.Feature_Messages.Fixtures is

   --  Populate deterministic Messages feature rows for tests.  This keeps
   --  demo/scaffold message data out of the production Messages API while
   --  preserving concise fixtures for feature-panel projection tests.
   procedure Add_Test_Message
     (Messages     : in out Editor.Feature_Messages.Message_Feature_State;
      Label        : String;
      Detail       : String := "";
      Buffer_Token : Natural := 0);

   procedure Set_Test_Rows
     (Messages     : in out Editor.Feature_Messages.Message_Feature_State;
      Buffer_Token : Natural := 0);

end Editor.Feature_Messages.Fixtures;
