with Editor.Instance;

package Editor.Input_Bridge.Async_Ticks is

   type Message_Reporter is not null access procedure (Message : String);

   procedure Tick_Async_Build_Jobs
     (Instance    : in out Editor.Instance.Editor_Instance;
      Initialized : Boolean;
      Report_Info : Message_Reporter);

   procedure Tick_Messages
     (Instance    : in out Editor.Instance.Editor_Instance;
      Initialized : Boolean);

end Editor.Input_Bridge.Async_Ticks;
