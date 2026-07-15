with Editor.Test_Temp;
with AUnit.Assertions; use AUnit.Assertions;
with Ada.Directories;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Interfaces.C;
with Editor.Buffers;
with Editor.Commands;
with Editor.Executor;
with Editor.Executor.Find_Replace_Commands;
with Editor.Gutter_Markers;
with Editor.Input_Bridge;
with Editor.Layout;
with Editor.Messages;
with Editor.Render_Layers;
with Editor.Render_Model;
with Editor.Render_Packet;
with Editor.Scrollbars;
with Editor.State;
with Editor.View;

use type Editor.Messages.Message_Id;
use type Editor.Messages.Message_Severity;
use type Interfaces.C.int;

package body Editor.Messages.Tests is

   overriding function Name
     (T : Messages_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Messages");
   end Name;

   function Rect_Count_On_Layer
     (Packet : Editor.Render_Packet.Render_Packet;
      Layer  : Editor.Render_Layers.Render_Layer) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 0 .. Natural (Packet.Rect_Count) - 1 loop
         if Packet.Rects (Natural (I)).Layer = Editor.Render_Layers.To_C (Layer) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Rect_Count_On_Layer;

   function Glyph_Count_On_Layer
     (Packet : Editor.Render_Packet.Render_Packet;
      Layer  : Editor.Render_Layers.Render_Layer) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 0 .. Natural (Packet.Glyph_Count) - 1 loop
         if Packet.Glyphs (Natural (I)).Layer = Editor.Render_Layers.To_C (Layer) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Glyph_Count_On_Layer;

   procedure Prepare_State_With_Message
     (S : out Editor.State.State_Type)
   is
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & "beta" & ASCII.LF & "gamma");
      Editor.Messages.Push_Info (S.Messages, "hello");
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (800, 200);
      Editor.Scrollbars.Reset;
   end Prepare_State_With_Message;


   function To_Message_Layout
     (Layout          : Editor.Layout.Layout_Config;
      Viewport_Height : Natural) return Editor.Messages.Message_Layout
   is
   begin
      return
        (Origin_X     => Layout.Origin_X,
         Origin_Y     => Layout.Origin_Y,
         Cell_W       => Editor.Layout.Cell_W,
         Cell_H       => Editor.Layout.Cell_H,
         Status_Bar_Y => Editor.Layout.Status_Bar_Y (Layout, Viewport_Height));
   end To_Message_Layout;

   procedure Remove_If_Exists
     (Path : String)
   is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_File (Path);
      end if;
   end Remove_If_Exists;

   function Temp_Path
     (Name : String) return String
   is
   begin
      Ada.Directories.Create_Path (Editor.Test_Temp.Base & "/editor-tests");
      return Ada.Directories.Compose
        (Editor.Test_Temp.Base & "/editor-tests", "" & Name);
   end Temp_Path;

   procedure Test_Push_Message_Makes_State_Non_Empty
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Messages.Message_State;
   begin
      Assert (Editor.Messages.Is_Empty (State),
              "New message state must be empty");
      Editor.Messages.Push_Info (State, "Saved file.adb");
      Assert (not Editor.Messages.Is_Empty (State),
              "Pushing a message must make state non-empty");
      Assert (Editor.Messages.Count (State) = 1,
              "Pushing one message must produce count 1");
   end Test_Push_Message_Makes_State_Non_Empty;

   procedure Test_Active_Message_Is_Newest_Non_Expired
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Messages.Message_State;
      Found : Boolean := False;
      M : Editor.Messages.Editor_Message;
   begin
      Editor.Messages.Push (State, Editor.Messages.Info_Message, "old", Ticks => 1);
      Editor.Messages.Push_Warning (State, "new");
      M := Editor.Messages.Active_Message (State, Found);
      Assert (Found, "Active_Message must find a live message");
      Assert (To_String (M.Text) = "new",
              "Active_Message must return the newest non-expired message");
      Assert (M.Severity = Editor.Messages.Warning_Message,
              "Push_Warning must preserve warning severity");
   end Test_Active_Message_Is_Newest_Non_Expired;

   procedure Test_Tick_Expires_Non_Sticky_Message
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Messages.Message_State;
   begin
      Editor.Messages.Push (State, Editor.Messages.Info_Message, "soon", Ticks => 1);
      Editor.Messages.Tick (State);
      Assert (Editor.Messages.Is_Empty (State),
              "Tick must expire and prune non-sticky messages at zero lifetime");
   end Test_Tick_Expires_Non_Sticky_Message;

   procedure Test_Sticky_Message_Does_Not_Expire
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Messages.Message_State;
   begin
      Editor.Messages.Push (State, Editor.Messages.Error_Message, "error", Ticks => 1, Sticky => True);
      for I in 1 .. 10 loop
         Editor.Messages.Tick (State);
      end loop;
      Assert (not Editor.Messages.Is_Empty (State),
              "Sticky messages must remain live across ticks");
   end Test_Sticky_Message_Does_Not_Expire;

   procedure Test_Clear_Removes_All_Messages
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Messages.Message_State;
   begin
      Editor.Messages.Push_Info (State, "one");
      Editor.Messages.Push_Error (State, "two");
      Editor.Messages.Clear (State);
      Assert (Editor.Messages.Is_Empty (State),
              "Clear must remove all messages");
      Assert (Editor.Messages.Count (State) = 0,
              "Clear must reset visible queue count to zero");
   end Test_Clear_Removes_All_Messages;

   procedure Test_Message_Ids_Increase_Monotonically
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Messages.Message_State;
      Found : Boolean := False;
      First : Editor.Messages.Editor_Message;
      Second : Editor.Messages.Editor_Message;
   begin
      Editor.Messages.Push_Info (State, "one");
      First := Editor.Messages.Active_Message (State, Found);
      Assert (Found, "First active message must be present");
      Editor.Messages.Push_Info (State, "two");
      Second := Editor.Messages.Active_Message (State, Found);
      Assert (Second.Id > First.Id,
              "Message ids must increase monotonically");
   end Test_Message_Ids_Increase_Monotonically;

   procedure Test_Push_Helpers_Preserve_Severity
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Messages.Message_State;
      Found : Boolean := False;
      M : Editor.Messages.Editor_Message;
   begin
      Editor.Messages.Push_Success (State, "ok");
      M := Editor.Messages.Active_Message (State, Found);
      Assert (M.Severity = Editor.Messages.Success_Message,
              "Push_Success must preserve success severity");

      Editor.Messages.Push_Error (State, "bad");
      M := Editor.Messages.Active_Message (State, Found);
      Assert (M.Severity = Editor.Messages.Error_Message,
              "Push_Error must preserve error severity");
   end Test_Push_Helpers_Preserve_Severity;

   procedure Test_Display_Text_Truncates_Deterministically
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Messages.Message_State;
      Found : Boolean := False;
      M : Editor.Messages.Editor_Message;
   begin
      Editor.Messages.Push_Info (State, "abcdef");
      M := Editor.Messages.Active_Message (State, Found);
      Assert (Editor.Messages.Display_Text (M, 4) = "a...",
              "Long message text must truncate deterministically with ellipsis");
   end Test_Display_Text_Truncates_Deterministically;

   procedure Test_Render_Emits_Nothing_When_No_Active_Message
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha");
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (800, 200);
      Editor.Input_Bridge.Build_Render_Packet (Packet);
      Assert (Rect_Count_On_Layer (Packet, Editor.Render_Layers.Message_Background_Layer) = 0,
              "No active message must emit no message background");
      Assert (Glyph_Count_On_Layer (Packet, Editor.Render_Layers.Message_Text_Layer) = 0,
              "No active message must emit no message text");
   end Test_Render_Emits_Nothing_When_No_Active_Message;

   procedure Test_Render_Emits_Active_Message
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Prepare_State_With_Message (S);
      Editor.Input_Bridge.Build_Render_Packet (Packet);
      Assert (Rect_Count_On_Layer (Packet, Editor.Render_Layers.Message_Background_Layer) > 0,
              "Active message must emit a message background rect");
      Assert (Glyph_Count_On_Layer (Packet, Editor.Render_Layers.Message_Text_Layer) > 0,
              "Active message must emit text on message text layer");
   end Test_Render_Emits_Active_Message;

   procedure Test_Message_Layer_Order
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Render_Layers.Order (Editor.Render_Layers.Status_Bar_Text_Layer)
         < Editor.Render_Layers.Order (Editor.Render_Layers.Message_Background_Layer),
         "Message background must draw above status bar text");
      Assert
        (Editor.Render_Layers.Order (Editor.Render_Layers.Message_Text_Layer)
         < Editor.Render_Layers.Order (Editor.Render_Layers.Palette_Background_Layer),
         "Palette must draw above message text");
   end Test_Message_Layer_Order;

   procedure Test_Message_Input_Hit_Is_Handled_No_Op
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Rect : Editor.Messages.Message_Rect;
      Cmd : Editor.Commands.Command;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Prepare_State_With_Message (S);
      Rect := Editor.Messages.Overlay_Rect
        (Layout          => To_Message_Layout (Layout, Editor.View.Viewport_Height),
         Viewport_Width  => Editor.View.Viewport_Width,
         Viewport_Height => Editor.View.Viewport_Height,
         State           => S.Messages);
      Assert (Rect.Visible, "Prepared active message must have visible overlay rect");

      Cmd.Kind := Editor.Commands.Move_To_Point;
      Cmd.Click_X := Rect.X + Rect.W / 2;
      Cmd.Click_Y := Rect.Y + Rect.H / 2;
      Editor.Input_Bridge.Handle (Cmd);

      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert (Snap.Primary_Caret_Logical_Row = 0,
              "Clicking message overlay must not move caret into text");
      Assert (Snap.Selection_Count = 0,
              "Clicking message overlay must not start a selection");
   end Test_Message_Input_Hit_Is_Handled_No_Op;


   procedure Test_Message_Click_Does_Not_Toggle_Bookmark
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Rect : Editor.Messages.Message_Rect;
      Cmd : Editor.Commands.Command;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Prepare_State_With_Message (S);
      Rect := Editor.Messages.Overlay_Rect
        (Layout          => To_Message_Layout (Editor.Layout.Current, Editor.View.Viewport_Height),
         Viewport_Width  => Editor.View.Viewport_Width,
         Viewport_Height => Editor.View.Viewport_Height,
         State           => S.Messages);
      Assert (Rect.Visible, "Prepared active message must have visible overlay rect");

      Cmd.Kind := Editor.Commands.Move_To_Point;
      Cmd.Click_X := Rect.X + Rect.W / 2;
      Cmd.Click_Y := Rect.Y + Rect.H / 2;
      Editor.Input_Bridge.Handle (Cmd);

      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert
        (not Editor.Gutter_Markers.Has_Marker
          (Snap.Gutter_Markers, 0, Editor.Gutter_Markers.Bookmark_Marker),
         "Clicking message overlay must not toggle a bookmark marker");
   end Test_Message_Click_Does_Not_Toggle_Bookmark;

   procedure Test_Message_Click_Does_Not_Start_Scrollbar_Drag
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Rect : Editor.Messages.Message_Rect;
      Cmd : Editor.Commands.Command;
   begin
      Prepare_State_With_Message (S);
      Rect := Editor.Messages.Overlay_Rect
        (Layout          => To_Message_Layout (Editor.Layout.Current, Editor.View.Viewport_Height),
         Viewport_Width  => Editor.View.Viewport_Width,
         Viewport_Height => Editor.View.Viewport_Height,
         State           => S.Messages);
      Assert (Rect.Visible, "Prepared active message must have visible overlay rect");

      Cmd.Kind := Editor.Commands.Move_To_Point;
      Cmd.Click_X := Rect.X + Rect.W / 2;
      Cmd.Click_Y := Rect.Y + Rect.H / 2;
      Editor.Input_Bridge.Handle (Cmd);

      Cmd.Kind := Editor.Commands.Drag_To_Point;
      Cmd.Click_X := Rect.X + Rect.W / 2;
      Cmd.Click_Y := Editor.View.Viewport_Height - 1;
      Editor.Input_Bridge.Handle (Cmd);

      Assert (Editor.View.Scroll_Y = 0,
              "Message overlay click must not start a scrollbar/minimap drag path");
   end Test_Message_Click_Does_Not_Start_Scrollbar_Drag;

   procedure Test_Save_Success_Pushes_Success_Message
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
      Found : Boolean := False;
      M : Editor.Messages.Editor_Message;
      Path : constant String := Temp_Path ("save_success.txt");
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_If_Exists (Path);
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "hello");

      Cmd.Kind := Editor.Commands.Save_File_As;
      Cmd.Path := To_Unbounded_String (Path);
      Editor.Executor.Execute_No_Log (S, Cmd);

      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found, "Save_File_As success must publish a message");
      Assert (M.Severity = Editor.Messages.Success_Message,
              "Save_File_As success must publish success severity");
      Assert (To_String (M.Text) = "Saved file as",
              "Save_File_As success message must use normalized lifecycle text");
      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Save_Success_Pushes_Success_Message;

   procedure Test_Save_Failure_Pushes_Error_Message
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
      Found : Boolean := False;
      M : Editor.Messages.Editor_Message;
      Seed_Path : constant String := Temp_Path ("save_failure_seed.txt");
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_If_Exists (Seed_Path);
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "hello");

      Cmd.Kind := Editor.Commands.Save_File_As;
      Cmd.Path := To_Unbounded_String (Seed_Path);
      Editor.Executor.Execute_No_Log (S, Cmd);

      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Editor.Test_Temp.Base & "");
      S.File_Info.Display_Name := To_Unbounded_String ("tmp");
      S.File_Info.Dirty := True;
      S.File_Info.File_Token_Known := False;
      S.File_Info.File_Token_Label := Null_Unbounded_String;
      S.File_Info.External_Change_Surfaced := False;
      Cmd.Kind := Editor.Commands.Save_File;
      Editor.Executor.Execute_No_Log (S, Cmd);

      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found, "Save_File failure must publish a message");
      Assert (M.Severity = Editor.Messages.Error_Message,
              "Save_File failure must publish error severity");
      Assert (To_String (M.Text) = "Could not save file.",
              "Save_File failure message must use the canonical save failure text");
      Remove_If_Exists (Seed_Path);
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Save_Failure_Pushes_Error_Message;

   procedure Test_Search_No_Match_Pushes_Info_Message
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Found : Boolean := False;
      M : Editor.Messages.Editor_Message;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha beta");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "zzz");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Next (S);

      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found, "No-match search must publish a message");
      Assert (M.Severity = Editor.Messages.Info_Message,
              "No-match search must publish info severity");
      Assert (To_String (M.Text) = "No matches",
              "No-match search must publish the expected text");
   end Test_Search_No_Match_Pushes_Info_Message;

   procedure Test_Message_Does_Not_Change_Status_Bar_Geometry
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Height : constant Natural := 200;
      Before_Text_H : constant Natural := Editor.Layout.Text_Viewport_Height (Layout, Height);
      Before_Status_Y : constant Integer := Editor.Layout.Status_Bar_Y (Layout, Height);
      S : Editor.State.State_Type;
      Rect : Editor.Messages.Message_Rect;
   begin
      Prepare_State_With_Message (S);
      Rect := Editor.Messages.Overlay_Rect
        (Layout          => To_Message_Layout (Layout, Height),
         Viewport_Width  => 800,
         Viewport_Height => Height,
         State           => S.Messages);
      Assert (Rect.Visible, "Active message overlay must be visible");
      Assert (Editor.Layout.Text_Viewport_Height (Layout, Height) = Before_Text_H,
              "Message overlay must not change text viewport height");
      Assert (Editor.Layout.Status_Bar_Y (Layout, Height) = Before_Status_Y,
              "Message overlay must not change status bar Y");
   end Test_Message_Does_Not_Change_Status_Bar_Geometry;


   procedure Test_Deterministic_Visible_Projection_Stacks_Newest_First
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State  : Editor.Messages.Message_State;
      Config : constant Editor.Messages.Message_Config :=
        (Default_Lifetime_Ms   => 100,
         Error_Lifetime_Ms     => 200,
         Max_Visible_Messages  => 3,
         Max_Text_Columns      => 96,
         Replace_Same_Category => True);
      M : Editor.Messages.Message_Record;
   begin
      Editor.Messages.Push_Info (State, "one", 10, Config);
      Editor.Messages.Push_Warning (State, "two", 20, Config);
      Assert (Editor.Messages.Visible_Count (State, 20, Config) = 2,
              "Visible_Count must include both live messages");
      M := Editor.Messages.Visible_Message (State, 1, 20, Config);
      Assert (Editor.Messages.Text (M) = "two",
              "Visible_Message index 1 must return newest visible message");
      M := Editor.Messages.Visible_Message (State, 2, 20, Config);
      Assert (Editor.Messages.Text (M) = "one",
              "Visible_Message index 2 must return the older visible message");
   end Test_Deterministic_Visible_Projection_Stacks_Newest_First;

   procedure Test_Duplicate_Message_Refreshes_Instead_Of_Duplicating
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State  : Editor.Messages.Message_State;
      Config : constant Editor.Messages.Message_Config :=
        (Default_Lifetime_Ms   => 100,
         Error_Lifetime_Ms     => 200,
         Max_Visible_Messages  => 3,
         Max_Text_Columns      => 96,
         Replace_Same_Category => True);
   begin
      Editor.Messages.Push_Info (State, "No matches", 0, Config);
      Editor.Messages.Push_Info (State, "No matches", 90, Config);
      Assert (Editor.Messages.Visible_Count (State, 90, Config) = 1,
              "Duplicate exact messages must refresh instead of duplicating");
      Assert (Editor.Messages.Visible_Count (State, 150, Config) = 1,
              "Refreshed duplicate must use the latest timestamp");
      Editor.Messages.Tick (State, 191);
      Assert (Editor.Messages.Visible_Count (State, 191, Config) = 0,
              "Refreshed duplicate must expire deterministically after refreshed lifetime");
   end Test_Duplicate_Message_Refreshes_Instead_Of_Duplicating;

   procedure Test_Normalize_Text_Replaces_Line_Breaks
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Messages.Normalize_Text ("a" & ASCII.LF & "b" & ASCII.CR & "c", 20) = "a b c",
              "Normalize_Text must make message text single-line");
   end Test_Normalize_Text_Replaces_Line_Breaks;

   procedure Test_Dismiss_Latest_And_All
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State  : Editor.Messages.Message_State;
      Config : constant Editor.Messages.Message_Config :=
        (Default_Lifetime_Ms   => 100,
         Error_Lifetime_Ms     => 200,
         Max_Visible_Messages  => 3,
         Max_Text_Columns      => 96,
         Replace_Same_Category => True);
   begin
      Editor.Messages.Push_Info (State, "one", 0, Config);
      Editor.Messages.Push_Info (State, "two", 0, Config);
      Editor.Messages.Dismiss_Latest (State);
      Assert (Editor.Messages.Visible_Count (State, 0, Config) = 1,
              "Dismiss_Latest must remove one visible message");
      Editor.Messages.Dismiss_All (State);
      Assert (Editor.Messages.Visible_Count (State, 0, Config) = 0,
              "Dismiss_All must clear all visible messages");
   end Test_Dismiss_Latest_And_All;

   overriding procedure Register_Tests
     (T : in out Messages_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Push_Message_Makes_State_Non_Empty'Access,
         "Push Message Makes State Non Empty");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Active_Message_Is_Newest_Non_Expired'Access,
         "Active Message Is Newest Non Expired");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Tick_Expires_Non_Sticky_Message'Access,
         "Tick Expires Non Sticky Message");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Sticky_Message_Does_Not_Expire'Access,
         "Sticky Message Does Not Expire");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Clear_Removes_All_Messages'Access,
         "Clear Removes All Messages");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Message_Ids_Increase_Monotonically'Access,
         "Message Ids Increase Monotonically");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Push_Helpers_Preserve_Severity'Access,
         "Push Helpers Preserve Severity");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Display_Text_Truncates_Deterministically'Access,
         "Display Text Truncates Deterministically");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Emits_Nothing_When_No_Active_Message'Access,
         "Render Emits Nothing Without Active Message");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Emits_Active_Message'Access,
         "Render Emits Active Message");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Message_Layer_Order'Access,
         "Message Layer Order");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Message_Input_Hit_Is_Handled_No_Op'Access,
         "Message Input Hit Is Handled No Op");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Message_Click_Does_Not_Toggle_Bookmark'Access,
         "Message Click Does Not Toggle Bookmark");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Message_Click_Does_Not_Start_Scrollbar_Drag'Access,
         "Message Click Does Not Start Scrollbar Drag");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Success_Pushes_Success_Message'Access,
         "Save Success Pushes Success Message");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Failure_Pushes_Error_Message'Access,
         "Save Failure Pushes Error Message");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Search_No_Match_Pushes_Info_Message'Access,
         "Search No Match Pushes Info Message");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Message_Does_Not_Change_Status_Bar_Geometry'Access,
         "Message Does Not Change Status Bar Geometry");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Deterministic_Visible_Projection_Stacks_Newest_First'Access,
         "Deterministic Visible Projection Stacks Newest First");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Duplicate_Message_Refreshes_Instead_Of_Duplicating'Access,
         "Duplicate Message Refreshes Instead Of Duplicating");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Normalize_Text_Replaces_Line_Breaks'Access,
         "Normalize Text Replaces Line Breaks");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dismiss_Latest_And_All'Access,
         "Dismiss Latest And All");
   end Register_Tests;

end Editor.Messages.Tests;
