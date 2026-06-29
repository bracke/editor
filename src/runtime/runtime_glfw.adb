with Ada.Text_IO;
with Interfaces.C;
with Interfaces.C.Strings;
with System;

with Editor.Bridge;
with Editor.C_API;
with Glfw;
with Glfw.Errors;
with Glfw.Input;
with Glfw.Input.Keys;
with Glfw.Input.Mouse;
with Glfw.Windows;
with Glfw.Windows.Hints;
with Glfw.Windows.Native;

package body Runtime_GLFW is
   package C renames Interfaces.C;
   package C_Strings renames Interfaces.C.Strings;

   use type C.int;
   use type C.unsigned;
   use type C_Strings.chars_ptr;
   use type Glfw.Input.Button_State;
   use type Glfw.Input.Keys.Action;
   use type Glfw.Input.Keys.Key;
   use type Glfw.Input.Mouse.Button;
   use type Glfw.Seconds;
   use type System.Address;

   function Render_Backend_Create
     (Window : System.Address) return System.Address;
   pragma Import (C, Render_Backend_Create, "render_backend_create");

   function Render_Backend_Begin_Frame
     (Backend : System.Address;
      Width   : C.int;
      Height  : C.int) return C.int;
   pragma Import (C, Render_Backend_Begin_Frame, "render_backend_begin_frame");

   function Render_Backend_Draw_Editor
     (Backend : System.Address) return C.int;
   pragma Import (C, Render_Backend_Draw_Editor, "render_backend_draw_editor");

   function Render_Backend_End_Frame
     (Backend : System.Address) return C.int;
   pragma Import (C, Render_Backend_End_Frame, "render_backend_end_frame");

   procedure Render_Backend_Request_Swapchain_Recreate
     (Backend : System.Address);
   pragma Import
     (C, Render_Backend_Request_Swapchain_Recreate,
      "render_backend_request_swapchain_recreate");

   function Render_Backend_Frame_Was_Rendered
     (Backend : System.Address) return C.int;
   pragma Import
     (C, Render_Backend_Frame_Was_Rendered,
      "render_backend_frame_was_rendered");

   function Render_Backend_Swapchain_Recreate_Count
     (Backend : System.Address) return C.unsigned;
   pragma Import
     (C, Render_Backend_Swapchain_Recreate_Count,
      "render_backend_swapchain_recreate_count");

   function Render_Backend_Font_Atlas_Upload_Count
     (Backend : System.Address) return C.unsigned;
   pragma Import
     (C, Render_Backend_Font_Atlas_Upload_Count,
      "render_backend_font_atlas_upload_count");

   function Render_Backend_Font_Atlas_Last_Upload_Width
     (Backend : System.Address) return C.unsigned;
   pragma Import
     (C, Render_Backend_Font_Atlas_Last_Upload_Width,
      "render_backend_font_atlas_last_upload_width");

   function Render_Backend_Font_Atlas_Last_Upload_Height
     (Backend : System.Address) return C.unsigned;
   pragma Import
     (C, Render_Backend_Font_Atlas_Last_Upload_Height,
      "render_backend_font_atlas_last_upload_height");

   function Render_Backend_Font_Atlas_Last_Upload_Nonzero_Bytes
     (Backend : System.Address) return C.unsigned;
   pragma Import
     (C, Render_Backend_Font_Atlas_Last_Upload_Nonzero_Bytes,
      "render_backend_font_atlas_last_upload_nonzero_bytes");

   function Render_Backend_Font_Atlas_Last_Upload_Checksum
     (Backend : System.Address) return C.unsigned;
   pragma Import
     (C, Render_Backend_Font_Atlas_Last_Upload_Checksum,
      "render_backend_font_atlas_last_upload_checksum");

   function Render_Backend_Font_Atlas_Dirty
     (Backend : System.Address) return C.int;
   pragma Import
     (C, Render_Backend_Font_Atlas_Dirty,
      "render_backend_font_atlas_dirty");

   function Render_Backend_Last_Visual_Rect_Count
     (Backend : System.Address) return C.unsigned;
   pragma Import
     (C, Render_Backend_Last_Visual_Rect_Count,
      "render_backend_last_visual_rect_count");

   function Render_Backend_Last_Visual_Glyph_Count
     (Backend : System.Address) return C.unsigned;
   pragma Import
     (C, Render_Backend_Last_Visual_Glyph_Count,
      "render_backend_last_visual_glyph_count");

   function Render_Backend_Last_Visual_Geometry_Checksum
     (Backend : System.Address) return C.unsigned;
   pragma Import
     (C, Render_Backend_Last_Visual_Geometry_Checksum,
      "render_backend_last_visual_geometry_checksum");

   function Render_Backend_Last_Visual_Color_Checksum
     (Backend : System.Address) return C.unsigned;
   pragma Import
     (C, Render_Backend_Last_Visual_Color_Checksum,
      "render_backend_last_visual_color_checksum");

   procedure Render_Backend_Destroy (Backend : System.Address);
   pragma Import (C, Render_Backend_Destroy, "render_backend_destroy");

   type Editor_Window is new Glfw.Windows.Window with record
      Backend         : System.Address := System.Null_Address;
      Left_Mouse_Down : Boolean := False;
      Drag_Shift      : Boolean := False;
      Drag_Ctrl       : Boolean := False;
      Drag_Alt        : Boolean := False;
      Last_Click_Time : Glfw.Seconds := -1.0;
      Last_Click_X    : C.int := 0;
      Last_Click_Y    : C.int := 0;
      Click_Count     : Natural := 0;
   end record;

   overriding procedure Framebuffer_Size_Changed
     (Object : not null access Editor_Window;
      Width, Height : Natural);

   overriding procedure Mouse_Position_Changed
     (Object : not null access Editor_Window;
      X, Y   : Glfw.Input.Mouse.Coordinate);

   overriding procedure Mouse_Button_Changed
     (Object : not null access Editor_Window;
      Button : Glfw.Input.Mouse.Button;
      State  : Glfw.Input.Button_State;
      Mods   : Glfw.Input.Keys.Modifiers);

   overriding procedure Mouse_Scrolled
     (Object : not null access Editor_Window;
      X, Y   : Glfw.Input.Mouse.Scroll_Offset);

   overriding procedure Key_Changed
     (Object   : not null access Editor_Window;
      Key      : Glfw.Input.Keys.Key;
      Scancode : Glfw.Input.Keys.Scancode;
      Action   : Glfw.Input.Keys.Action;
      Mods     : Glfw.Input.Keys.Modifiers);

   overriding procedure Character_Entered
     (Object : not null access Editor_Window;
      Char   : Wide_Wide_Character);

   function To_C_Int (Value : Boolean) return C.int is
     (if Value then 1 else 0);

   procedure Put_Error (Message : String) is
   begin
      Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error, Message);
   end Put_Error;

   procedure GLFW_Error (Error : Glfw.Errors.Kind; Description : String) is
   begin
      Put_Error
        ("runtime GLFW error:"
         & Glfw.Errors.Kind'Image (Error)
         & ": "
         & Description);
   end GLFW_Error;

   procedure Send_Event (Ev : Editor.Bridge.Platform_Event) is
   begin
      Editor.C_API.Editor_Handle_Platform_Event (Ev);
   end Send_Event;

   procedure Prime_Smoke_Text is
      Smoke_Text : constant String :=
        "procedure Smoke is begin null; end; -- runtime smoke";
   begin
      for Ch of Smoke_Text loop
         Send_Event
           ((Kind    => Editor.Bridge.Char_Input,
             Ch      => C.unsigned (Character'Pos (Ch)),
             Shift   => 0,
             Ctrl    => 0,
             Alt     => 0,
             X       => 0,
             Y       => 0,
             Wheel_X => 0,
             Wheel_Y => 0));
      end loop;
   end Prime_Smoke_Text;

   overriding procedure Framebuffer_Size_Changed
     (Object : not null access Editor_Window;
      Width, Height : Natural)
   is
      pragma Unreferenced (Width, Height);
   begin
      if Object.Backend /= System.Null_Address then
         Render_Backend_Request_Swapchain_Recreate (Object.Backend);
      end if;
   end Framebuffer_Size_Changed;

   overriding procedure Mouse_Position_Changed
     (Object : not null access Editor_Window;
      X, Y   : Glfw.Input.Mouse.Coordinate)
   is
      Kind : constant Editor.Bridge.Event_Kind :=
        (if Object.Left_Mouse_Down
         then Editor.Bridge.Mouse_Drag
         else Editor.Bridge.Mouse_Move);
   begin
      Send_Event
        ((Kind    => Kind,
          Ch      => 0,
          Shift   => (if Object.Left_Mouse_Down then To_C_Int (Object.Drag_Shift) else 0),
          Ctrl    => (if Object.Left_Mouse_Down then To_C_Int (Object.Drag_Ctrl) else 0),
          Alt     => (if Object.Left_Mouse_Down then To_C_Int (Object.Drag_Alt) else 0),
          X       => C.int (X),
          Y       => C.int (Y),
          Wheel_X => 0,
          Wheel_Y => 0));
   end Mouse_Position_Changed;

   overriding procedure Mouse_Button_Changed
     (Object : not null access Editor_Window;
      Button : Glfw.Input.Mouse.Button;
      State  : Glfw.Input.Button_State;
      Mods   : Glfw.Input.Keys.Modifiers)
   is
      X : Glfw.Input.Mouse.Coordinate := 0.0;
      Y : Glfw.Input.Mouse.Coordinate := 0.0;
   begin
      if Button /= Glfw.Input.Mouse.Button (Glfw.Input.Mouse.Left_Button) then
         return;
      end if;

      Object.Get_Cursor_Pos (X, Y);

      if State = Glfw.Input.Pressed then
         declare
            IX : constant C.int := C.int (X);
            IY : constant C.int := C.int (Y);
            Now : constant Glfw.Seconds := Glfw.Time;
            Close_To_Last : constant Boolean :=
              abs (Integer (IX - Object.Last_Click_X)) <= 3
              and then abs (Integer (IY - Object.Last_Click_Y)) <= 3;
            Kind : Editor.Bridge.Event_Kind := Editor.Bridge.Mouse_Down;
         begin
            Object.Left_Mouse_Down := True;
            Object.Drag_Shift := Mods.Shift;
            Object.Drag_Ctrl := Mods.Control;
            Object.Drag_Alt := Mods.Alt;

            if Object.Last_Click_Time >= 0.0
              and then Now - Object.Last_Click_Time <= 0.50
              and then Close_To_Last
            then
               Object.Click_Count := Object.Click_Count + 1;
            else
               Object.Click_Count := 1;
            end if;

            Object.Last_Click_Time := Now;
            Object.Last_Click_X := IX;
            Object.Last_Click_Y := IY;

            if Mods.Alt and then not Mods.Shift then
               Kind := Editor.Bridge.Add_Caret;
            elsif not Mods.Shift and then Object.Click_Count >= 3 then
               Kind := Editor.Bridge.Select_Line;
               Object.Click_Count := 0;
            elsif not Mods.Shift and then Object.Click_Count = 2 then
               Kind := Editor.Bridge.Select_Word;
            end if;

            Send_Event
              ((Kind    => Kind,
                Ch      => 0,
                Shift   => To_C_Int (Mods.Shift),
                Ctrl    => To_C_Int (Mods.Control),
                Alt     => To_C_Int (Mods.Alt),
                X       => IX,
                Y       => IY,
                Wheel_X => 0,
                Wheel_Y => 0));
         end;
      elsif State = Glfw.Input.Released then
         Object.Left_Mouse_Down := False;
         Object.Drag_Shift := False;
         Object.Drag_Ctrl := False;
         Object.Drag_Alt := False;
      end if;
   end Mouse_Button_Changed;

   overriding procedure Mouse_Scrolled
     (Object : not null access Editor_Window;
      X, Y   : Glfw.Input.Mouse.Scroll_Offset)
   is
      Cursor_X : Glfw.Input.Mouse.Coordinate := 0.0;
      Cursor_Y : Glfw.Input.Mouse.Coordinate := 0.0;
   begin
      Object.Get_Cursor_Pos (Cursor_X, Cursor_Y);
      Send_Event
        ((Kind    => Editor.Bridge.Mouse_Wheel,
          Ch      => 0,
          Shift   => 0,
          Ctrl    => 0,
          Alt     => 0,
          X       => C.int (Cursor_X),
          Y       => C.int (Cursor_Y),
          Wheel_X => C.int (X),
          Wheel_Y => C.int (Y)));
   end Mouse_Scrolled;

   overriding procedure Key_Changed
     (Object   : not null access Editor_Window;
      Key      : Glfw.Input.Keys.Key;
      Scancode : Glfw.Input.Keys.Scancode;
      Action   : Glfw.Input.Keys.Action;
      Mods     : Glfw.Input.Keys.Modifiers)
   is
      pragma Unreferenced (Object, Scancode);
      Ev : Editor.Bridge.Platform_Event :=
        (Kind    => Editor.Bridge.Char_Input,
         Ch      => 0,
         Shift   => To_C_Int (Mods.Shift),
         Ctrl    => To_C_Int (Mods.Control),
         Alt     => To_C_Int (Mods.Alt),
         X       => 0,
         Y       => 0,
         Wheel_X => 0,
         Wheel_Y => 0);
   begin
      if Action /= Glfw.Input.Keys.Press
        and then Action /= Glfw.Input.Keys.Repeat
      then
         return;
      end if;

      case Key is
         when Glfw.Input.Keys.Enter | Glfw.Input.Keys.Numpad_Enter =>
            Ev.Kind := Editor.Bridge.Char_Input;
            Ev.Ch := C.unsigned (Character'Pos (ASCII.LF));
         when Glfw.Input.Keys.Left =>
            Ev.Kind := Editor.Bridge.Key_Left;
         when Glfw.Input.Keys.Right =>
            Ev.Kind := Editor.Bridge.Key_Right;
         when Glfw.Input.Keys.Up =>
            Ev.Kind := Editor.Bridge.Key_Up;
         when Glfw.Input.Keys.Down =>
            Ev.Kind := Editor.Bridge.Key_Down;
         when Glfw.Input.Keys.Home =>
            Ev.Kind := Editor.Bridge.Key_Home;
         when Glfw.Input.Keys.Key_End =>
            Ev.Kind := Editor.Bridge.Key_End;
         when Glfw.Input.Keys.Page_Up =>
            Ev.Kind := Editor.Bridge.Key_Page_Up;
         when Glfw.Input.Keys.Page_Down =>
            Ev.Kind := Editor.Bridge.Key_Page_Down;
         when Glfw.Input.Keys.Backspace =>
            Ev.Kind := Editor.Bridge.Key_Backspace;
         when Glfw.Input.Keys.Tab =>
            if Mods.Control then
               Ev.Kind := Editor.Bridge.Key_Tab;
            else
               return;
            end if;
         when Glfw.Input.Keys.Delete =>
            Ev.Kind := Editor.Bridge.Key_Delete;
         when Glfw.Input.Keys.F2 =>
            Ev.Kind := Editor.Bridge.Key_F2;
         when Glfw.Input.Keys.F3 =>
            Ev.Kind := Editor.Bridge.Key_F3;
         when Glfw.Input.Keys.Z =>
            if Mods.Control then
               Ev.Kind :=
                 (if Mods.Shift
                  then Editor.Bridge.Key_Redo
                  else Editor.Bridge.Key_Undo);
            else
               return;
            end if;
         when Glfw.Input.Keys.Y =>
            if Mods.Control then
               Ev.Kind := Editor.Bridge.Key_Redo;
            else
               return;
            end if;
         when Glfw.Input.Keys.S =>
            if Mods.Control then
               Ev.Kind := Editor.Bridge.Key_Save;
            else
               return;
            end if;
         when Glfw.Input.Keys.F =>
            if Mods.Control then
               Ev.Kind := Editor.Bridge.Char_Input;
               Ev.Ch := C.unsigned (Character'Pos ('f'));
            else
               return;
            end if;
         when Glfw.Input.Keys.H =>
            if Mods.Control then
               Ev.Kind := Editor.Bridge.Char_Input;
               Ev.Ch := C.unsigned (Character'Pos ('h'));
            else
               return;
            end if;
         when Glfw.Input.Keys.P =>
            if Mods.Control then
               Ev.Kind := Editor.Bridge.Open_Command_Palette;
            else
               return;
            end if;
         when Glfw.Input.Keys.Escape =>
            Ev.Kind := Editor.Bridge.Clear_Extra_Carets;
         when others =>
            return;
      end case;

      Send_Event (Ev);
   end Key_Changed;

   overriding procedure Character_Entered
     (Object : not null access Editor_Window;
      Char   : Wide_Wide_Character)
   is
      pragma Unreferenced (Object);
   begin
      if Wide_Wide_Character'Pos (Char) <= 16#10FFFF# then
         Send_Event
           ((Kind    => Editor.Bridge.Char_Input,
             Ch      => C.unsigned (Wide_Wide_Character'Pos (Char)),
             Shift   => 0,
             Ctrl    => 0,
             Alt     => 0,
             X       => 0,
             Y       => 0,
             Wheel_X => 0,
             Wheel_Y => 0));
      end if;
   end Character_Entered;

   function Runtime_Glfw_Run return C.int is
   begin
      return Runtime_Glfw_Run_With_Options (null);
   end Runtime_Glfw_Run;

   function Runtime_Glfw_Run_With_Options
     (Options : Runtime_Glfw_Options_Access) return C.int
   is
      Smoke_Mode : constant Boolean :=
        Options /= null and then Options.Smoke_Mode /= 0;
      Smoke_Max_Frames : C.int :=
        (if Options /= null then Options.Smoke_Max_Frames else 0);
      Smoke_Resize : constant Boolean :=
        Options /= null and then Options.Smoke_Resize /= 0;
      Smoke_Zero_Framebuffer : constant Boolean :=
        Options /= null and then Options.Smoke_Zero_Framebuffer /= 0;
      Smoke_Visual_Contract : constant Boolean :=
        Options /= null and then Options.Smoke_Visual_Contract /= 0;
      Smoke_Max_Seconds : constant C.int :=
        (if Options /= null and then Options.Smoke_Max_Seconds > 0
         then Options.Smoke_Max_Seconds
         else 30);
      Smoke_Visual_Min_Rects : constant C.unsigned :=
        (if Options /= null and then Options.Smoke_Visual_Min_Rects > 0
         then Options.Smoke_Visual_Min_Rects
         else 1);
      Smoke_Visual_Min_Glyphs : constant C.unsigned :=
        (if Options /= null and then Options.Smoke_Visual_Min_Glyphs > 0
         then Options.Smoke_Visual_Min_Glyphs
         else 1);
      Smoke_Resize_Count : C.int :=
        (if Options /= null and then Options.Smoke_Resize_Count > 0
         then Options.Smoke_Resize_Count
         elsif Smoke_Resize
         then 1
         else 0);
      Smoke_Atlas_Min_Nonzero_Bytes : constant C.unsigned :=
        (if Options /= null
            and then Options.Smoke_Atlas_Min_Nonzero_Bytes > 0
         then Options.Smoke_Atlas_Min_Nonzero_Bytes
         else 32);
      Smoke_Visual_First_Rect_Count : C.unsigned := 0;
      Smoke_Visual_First_Glyph_Count : C.unsigned := 0;
      Smoke_Visual_First_Geometry_Checksum : C.unsigned := 0;
      Smoke_Visual_First_Color_Checksum : C.unsigned := 0;
      Smoke_Visual_Contract_Observed : Boolean := False;
      Smoke_Resize_Requests : C.int := 0;
      Smoke_Zero_Framebuffer_Checked : Boolean := False;
      Smoke_Zero_Framebuffer_Recreate_Baseline : C.unsigned := 0;
      Smoke_Recreate_Baseline : C.unsigned := 0;
      Smoke_Atlas_Upload_Baseline : C.unsigned := 0;
      Smoke_First_Atlas_Upload_Count : C.unsigned := 0;
      Smoke_Frames_After_First_Atlas_Upload : C.int := 0;
      Smoke_First_Atlas_Width : C.unsigned := 0;
      Smoke_First_Atlas_Height : C.unsigned := 0;
      Smoke_First_Atlas_Nonzero_Bytes : C.unsigned := 0;
      Smoke_First_Atlas_Checksum : C.unsigned := 0;
      Smoke_Atlas_Metadata_Changed_After_Cache_Hit : Boolean := False;
      Rendered_Frames : C.int := 0;
      Loop_Iterations : C.int := 0;
      Max_Iterations : C.int := 0;
      Smoke_Start_Time : Glfw.Seconds := 0.0;
      Window : aliased Editor_Window;

      procedure Cleanup is
      begin
         if Window.Backend /= System.Null_Address then
            Render_Backend_Destroy (Window.Backend);
            Window.Backend := System.Null_Address;
         end if;

         if Window.Initialized then
            Window.Destroy;
         end if;

         Glfw.Shutdown;
      end Cleanup;

      function Fail (Message : String) return C.int is
      begin
         Put_Error (Message);
         Cleanup;
         return 1;
      end Fail;
   begin
      if Smoke_Mode and then Smoke_Resize and then Smoke_Resize_Count <= 0 then
         Smoke_Resize_Count := 1;
      end if;

      if Smoke_Mode and then Smoke_Max_Frames <= 0 then
         Smoke_Max_Frames :=
           (if Smoke_Resize then Smoke_Resize_Count + 3 else 3);
      end if;

      if Smoke_Mode
        and then Smoke_Resize
        and then Smoke_Max_Frames <= Smoke_Resize_Count + 1
      then
         Smoke_Max_Frames := Smoke_Resize_Count + 3;
      end if;

      if Smoke_Mode
        and then Smoke_Zero_Framebuffer
        and then Smoke_Max_Frames <= Smoke_Resize_Count + 3
      then
         Smoke_Max_Frames := Smoke_Resize_Count + 5;
      end if;

      if Smoke_Mode
        and then Smoke_Visual_Contract
        and then Smoke_Max_Frames < 5
      then
         Smoke_Max_Frames := 5;
      end if;

      Max_Iterations :=
        (if Smoke_Mode then Smoke_Max_Frames * 20 + 60 else 0);

      Glfw.Errors.Set_Callback (GLFW_Error'Access);

      begin
         Glfw.Init;
      exception
         when Glfw.Initialization_Exception =>
            Put_Error ("runtime error: GLFW init failed");
            return 1;
      end;

      Glfw.Windows.Hints.Reset_To_Defaults;
      Glfw.Windows.Native.Set_Client_API_No_API;
      if Smoke_Mode then
         Glfw.Windows.Hints.Set_Visible (False);
      end if;

      begin
         Glfw.Windows.Native.Init_No_API
           (Window'Access, 800, 600, "Editor");
      exception
         when Glfw.Windows.Creation_Error =>
            Put_Error ("runtime error: GLFW window creation failed");
            Glfw.Shutdown;
            return 1;
      end;

      Window.Enable_Callback (Glfw.Windows.Callbacks.Key);
      Window.Enable_Callback (Glfw.Windows.Callbacks.Char);
      Window.Enable_Callback (Glfw.Windows.Callbacks.Mouse_Button);
      Window.Enable_Callback (Glfw.Windows.Callbacks.Mouse_Position);
      Window.Enable_Callback (Glfw.Windows.Callbacks.Mouse_Scroll);
      Window.Enable_Callback (Glfw.Windows.Callbacks.Framebuffer_Size);

      Editor.C_API.Editor_Init;
      if Options /= null
        and then Options.Project_Path /= C_Strings.Null_Ptr
        and then String'(C_Strings.Value (Options.Project_Path))'Length > 0
      then
         Editor.C_API.Editor_Open_Project_Path (Options.Project_Path);
      end if;

      if Smoke_Mode then
         Prime_Smoke_Text;
      end if;

      Window.Backend :=
        Render_Backend_Create
          (Glfw.Windows.Native.Raw_Handle (Window'Access));

      if Window.Backend = System.Null_Address then
         return Fail
           ("runtime error: Vulkan render backend creation failed");
      end if;

      Smoke_Recreate_Baseline :=
        Render_Backend_Swapchain_Recreate_Count (Window.Backend);
      Smoke_Atlas_Upload_Baseline :=
        Render_Backend_Font_Atlas_Upload_Count (Window.Backend);
      Smoke_Start_Time := (if Smoke_Mode then Glfw.Time else 0.0);

      while not Window.Should_Close loop
         Glfw.Input.Poll_Events;

         if Editor.C_API.Editor_Should_Quit /= 0 then
            Window.Set_Should_Close (True);
         end if;

         declare
            Width  : Glfw.Size := 0;
            Height : Glfw.Size := 0;
         begin
            Window.Get_Framebuffer_Size (Width, Height);

            if Smoke_Mode then
               declare
                  Smoke_Elapsed : constant Glfw.Seconds :=
                    Glfw.Time - Smoke_Start_Time;
               begin
                  if Smoke_Elapsed > Glfw.Seconds (Smoke_Max_Seconds) then
                     return Fail
                       ("runtime smoke error: exceeded internal smoke timeout before requested frames completed");
                  end if;
               end;

               Loop_Iterations := Loop_Iterations + 1;
               if Loop_Iterations > Max_Iterations then
                  return Fail
                    ("runtime smoke error: exceeded bounded loop without rendering requested frames");
               end if;
            end if;

            if Width <= 0 or else Height <= 0 then
               if Smoke_Mode then
                  Glfw.Input.Poll_Events;
               else
                  Glfw.Input.Wait_For_Events;
               end if;
            else
               if Smoke_Mode
                 and then Smoke_Zero_Framebuffer
                 and then not Smoke_Zero_Framebuffer_Checked
                 and then Rendered_Frames >= 1
               then
                  Smoke_Zero_Framebuffer_Recreate_Baseline :=
                    Render_Backend_Swapchain_Recreate_Count
                      (Window.Backend);

                  if Render_Backend_Begin_Frame
                       (Window.Backend, 0, 0) = 0
                    or else Render_Backend_Draw_Editor
                       (Window.Backend) = 0
                    or else Render_Backend_End_Frame
                       (Window.Backend) = 0
                  then
                     return Fail
                       ("runtime smoke error: zero-framebuffer skip path failed");
                  end if;

                  if Render_Backend_Frame_Was_Rendered
                       (Window.Backend) /= 0
                  then
                     return Fail
                       ("runtime smoke error: zero-framebuffer skip path counted as a rendered frame");
                  end if;

                  Smoke_Zero_Framebuffer_Checked := True;
                  Window.Set_Size (800, 600);
                  Glfw.Input.Poll_Events;
               else
                  Editor.C_API.Editor_Set_Viewport_Size
                    (C.int (Width), C.int (Height));
                  Editor.C_API.Editor_Set_Time_Seconds
                    (C.double (Glfw.Time));
                  Editor.C_API.Editor_Tick;

                  if Smoke_Mode
                    and then Smoke_Resize
                    and then Smoke_Resize_Requests < Smoke_Resize_Count
                    and then Rendered_Frames >= Smoke_Resize_Requests + 1
                  then
                     case Integer (Smoke_Resize_Requests mod 4) is
                        when 0 =>
                           Window.Set_Size (640, 480);
                        when 1 =>
                           Window.Set_Size (960, 540);
                        when 2 =>
                           Window.Set_Size (320, 240);
                        when others =>
                           Window.Set_Size (800, 600);
                     end case;

                     Render_Backend_Request_Swapchain_Recreate
                       (Window.Backend);
                     Smoke_Resize_Requests := Smoke_Resize_Requests + 1;
                  end if;

                  if Render_Backend_Begin_Frame
                       (Window.Backend, C.int (Width), C.int (Height)) = 0
                    or else Render_Backend_Draw_Editor
                       (Window.Backend) = 0
                    or else Render_Backend_End_Frame
                       (Window.Backend) = 0
                  then
                     return Fail ("runtime error: render frame failed");
                  end if;

                  if Render_Backend_Frame_Was_Rendered
                       (Window.Backend) /= 0
                  then
                     declare
                        Current_Atlas_Uploads : constant C.unsigned :=
                          Render_Backend_Font_Atlas_Upload_Count
                            (Window.Backend);
                     begin
                        Rendered_Frames := Rendered_Frames + 1;

                        if Smoke_Mode and then Smoke_Visual_Contract then
                           declare
                              Rect_Count : constant C.unsigned :=
                                Render_Backend_Last_Visual_Rect_Count
                                  (Window.Backend);
                              Glyph_Count : constant C.unsigned :=
                                Render_Backend_Last_Visual_Glyph_Count
                                  (Window.Backend);
                              Geometry_Checksum : constant C.unsigned :=
                                Render_Backend_Last_Visual_Geometry_Checksum
                                  (Window.Backend);
                              Color_Checksum : constant C.unsigned :=
                                Render_Backend_Last_Visual_Color_Checksum
                                  (Window.Backend);
                           begin
                              if not Smoke_Visual_Contract_Observed
                                or else
                                  (Rect_Count >= Smoke_Visual_Min_Rects
                                   and then Glyph_Count >= Smoke_Visual_Min_Glyphs
                                   and then Geometry_Checksum /= 0
                                   and then Color_Checksum /= 0)
                              then
                                 Smoke_Visual_First_Rect_Count := Rect_Count;
                                 Smoke_Visual_First_Glyph_Count := Glyph_Count;
                                 Smoke_Visual_First_Geometry_Checksum :=
                                   Geometry_Checksum;
                                 Smoke_Visual_First_Color_Checksum :=
                                   Color_Checksum;
                                 Smoke_Visual_Contract_Observed := True;
                              end if;
                           end;
                        end if;

                        if Smoke_Mode then
                           if Current_Atlas_Uploads >
                                Smoke_Atlas_Upload_Baseline
                             and then Current_Atlas_Uploads /=
                                Smoke_First_Atlas_Upload_Count
                           then
                              Smoke_First_Atlas_Upload_Count :=
                                Current_Atlas_Uploads;
                              Smoke_First_Atlas_Width :=
                                Render_Backend_Font_Atlas_Last_Upload_Width
                                  (Window.Backend);
                              Smoke_First_Atlas_Height :=
                                Render_Backend_Font_Atlas_Last_Upload_Height
                                  (Window.Backend);
                              Smoke_First_Atlas_Nonzero_Bytes :=
                                Render_Backend_Font_Atlas_Last_Upload_Nonzero_Bytes
                                  (Window.Backend);
                              Smoke_First_Atlas_Checksum :=
                                Render_Backend_Font_Atlas_Last_Upload_Checksum
                                  (Window.Backend);
                              Smoke_Frames_After_First_Atlas_Upload := 0;
                           elsif Smoke_First_Atlas_Upload_Count /= 0 then
                              if Render_Backend_Font_Atlas_Last_Upload_Width
                                   (Window.Backend) /=
                                   Smoke_First_Atlas_Width
                                or else
                                  Render_Backend_Font_Atlas_Last_Upload_Height
                                    (Window.Backend) /=
                                    Smoke_First_Atlas_Height
                                or else
                                  Render_Backend_Font_Atlas_Last_Upload_Nonzero_Bytes
                                    (Window.Backend) /=
                                    Smoke_First_Atlas_Nonzero_Bytes
                                or else
                                  Render_Backend_Font_Atlas_Last_Upload_Checksum
                                    (Window.Backend) /=
                                    Smoke_First_Atlas_Checksum
                              then
                                 Smoke_Atlas_Metadata_Changed_After_Cache_Hit :=
                                   True;
                              end if;
                              Smoke_Frames_After_First_Atlas_Upload :=
                                Smoke_Frames_After_First_Atlas_Upload + 1;
                           end if;
                        end if;
                     end;
                  end if;

                  if Smoke_Mode and then Rendered_Frames >= Smoke_Max_Frames then
                     if Smoke_Visual_Contract then
                        if not Smoke_Visual_Contract_Observed then
                           return Fail
                             ("runtime smoke error: visual contract metrics were not observed on a rendered frame");
                        end if;
                        if Smoke_Visual_First_Rect_Count <
                          Smoke_Visual_Min_Rects
                        then
                           return Fail
                             ("runtime smoke error: visual contract recorded too few visible rectangle commands");
                        end if;
                        if Smoke_Visual_First_Glyph_Count <
                          Smoke_Visual_Min_Glyphs
                        then
                           return Fail
                             ("runtime smoke error: visual contract recorded too few visible glyph commands");
                        end if;
                        if Smoke_Visual_First_Geometry_Checksum = 0
                          or else Smoke_Visual_First_Color_Checksum = 0
                        then
                           return Fail
                             ("runtime smoke error: visual contract checksums were not recorded");
                        end if;
                     end if;

                     if Render_Backend_Font_Atlas_Upload_Count
                       (Window.Backend) <= Smoke_Atlas_Upload_Baseline
                     then
                        return Fail
                          ("runtime smoke error: deterministic text did not trigger a font atlas upload");
                     end if;

                     if Render_Backend_Font_Atlas_Last_Upload_Width
                          (Window.Backend) = 0
                       or else Render_Backend_Font_Atlas_Last_Upload_Height
                          (Window.Backend) = 0
                     then
                        return Fail
                          ("runtime smoke error: font atlas upload dimensions were not recorded");
                     end if;

                     if Render_Backend_Font_Atlas_Last_Upload_Nonzero_Bytes
                       (Window.Backend) = 0
                     then
                        return Fail
                          ("runtime smoke error: uploaded font atlas contained no rasterized glyph pixels");
                     end if;

                     if Render_Backend_Font_Atlas_Last_Upload_Nonzero_Bytes
                       (Window.Backend) < Smoke_Atlas_Min_Nonzero_Bytes
                     then
                        return Fail
                          ("runtime smoke error: font atlas upload had fewer "
                           & "non-zero bytes than the required deterministic "
                           & "text threshold");
                     end if;

                     if Render_Backend_Font_Atlas_Last_Upload_Checksum
                       (Window.Backend) = 0
                     then
                        return Fail
                          ("runtime smoke error: font atlas upload checksum was not recorded");
                     end if;

                     if Render_Backend_Font_Atlas_Dirty
                       (Window.Backend) /= 0
                     then
                        return Fail
                          ("runtime smoke error: font atlas dirty flag remained set after upload");
                     end if;

                     if Smoke_Frames_After_First_Atlas_Upload < 1 then
                        return Fail
                          ("runtime smoke error: font atlas upload did not "
                           & "reach a stable cache-hit frame after dirty "
                           & "upload");
                     end if;

                     if Smoke_Atlas_Metadata_Changed_After_Cache_Hit then
                        return Fail
                          ("runtime smoke error: font atlas upload metadata changed during cache-hit stability frame");
                     end if;

                     if Smoke_Zero_Framebuffer
                       and then not Smoke_Zero_Framebuffer_Checked
                     then
                        return Fail
                          ("runtime smoke error: zero-framebuffer transition was not exercised");
                     end if;

                     if Smoke_Zero_Framebuffer
                       and then Render_Backend_Swapchain_Recreate_Count
                         (Window.Backend) <=
                           Smoke_Zero_Framebuffer_Recreate_Baseline
                     then
                        return Fail
                          ("runtime smoke error: zero-framebuffer restore did not recreate the swapchain");
                     end if;

                     if Smoke_Resize
                       and then Smoke_Resize_Requests < Smoke_Resize_Count
                     then
                        return Fail
                          ("runtime smoke error: requested resize sequence did not complete");
                     end if;

                     if Smoke_Resize
                       and then Render_Backend_Swapchain_Recreate_Count
                         (Window.Backend) <
                           Smoke_Recreate_Baseline
                           + C.unsigned (Smoke_Resize_Count)
                           + (if Smoke_Zero_Framebuffer then 1 else 0)
                     then
                        return Fail
                          ("runtime smoke error: requested resize sequence "
                           & "did not recreate swapchain for every "
                           & "transition");
                     end if;

                     Window.Set_Should_Close (True);
                  end if;
               end if;
            end if;
         end;
      end loop;

      Cleanup;
      return 0;
   exception
      when others =>
         Cleanup;
         raise;
   end Runtime_Glfw_Run_With_Options;
end Runtime_GLFW;
