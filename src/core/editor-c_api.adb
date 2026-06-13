with Editor.Input_Bridge;
with Editor.Bridge;
with Editor.View;
with Editor.Render_Packet;
with Interfaces.C;

package body Editor.C_API is

   Should_Quit : Boolean := False;
   Have_Last_Tick_Time : Boolean := False;
   Last_Tick_Time : Duration := 0.0;

   procedure Editor_Init is
   begin
      Editor.Input_Bridge.Reset;
      Editor.View.Reset;
      Should_Quit := False;
      Have_Last_Tick_Time := False;
      Last_Tick_Time := 0.0;
   end Editor_Init;

   procedure Editor_Handle_Platform_Event
     (Ev : Editor.Bridge.Platform_Event) is
   begin
      Editor.Bridge.Editor_Handle_Event (Ev);
   end Editor_Handle_Platform_Event;

   function Editor_Should_Quit return Interfaces.C.int is
   begin
      if Should_Quit then
         return 1;
      else
         return 0;
      end if;
   end Editor_Should_Quit;

   procedure Editor_Set_Viewport_Size
     (W, H : Interfaces.C.int) is
   begin
      Editor.View.Set_Viewport
        (Width  => Natural (W),
         Height => Natural (H));
   end Editor_Set_Viewport_Size;

   procedure Editor_Set_Time_Seconds
     (T : Interfaces.C.double) is
   begin
      Editor.View.Set_Time_Seconds (Duration (T));
   end Editor_Set_Time_Seconds;

   procedure Editor_Tick is
      Now : constant Duration := Editor.View.Current_Time_Seconds;
      Step_Delta : Duration := 0.0;
   begin
      if Have_Last_Tick_Time then
         if Now > Last_Tick_Time then
            Step_Delta := Now - Last_Tick_Time;
         else
            Step_Delta := 0.0;
         end if;
      else
         Step_Delta := 0.0;
         Have_Last_Tick_Time := True;
      end if;

      Last_Tick_Time := Now;
      Editor.View.Tick (Float (Step_Delta));
      Editor.Input_Bridge.Tick_Async_Build_Jobs;
      Editor.Input_Bridge.Tick_Messages;
   end Editor_Tick;

   procedure Editor_Get_Render_Packet
     (Packet : out Editor.Render_Packet.Render_Packet) is
   begin
      Editor.Input_Bridge.Build_Render_Packet (Packet);
   end Editor_Get_Render_Packet;

end Editor.C_API;