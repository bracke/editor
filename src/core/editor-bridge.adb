with Editor.Input_Bridge;
with Editor.Commands;
with Editor.View;
with Interfaces.C; use Interfaces.C;
with Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Unicode;
with Editor.UTF8;
with Editor.Keybindings;
package body Editor.Bridge is

   procedure Send_Break_Group is
      Cmd : Editor.Commands.Command;
   begin
      Cmd.Kind := Editor.Commands.Break_Group;
      Editor.Input_Bridge.Handle (Cmd);
   end Send_Break_Group;

   function To_Bool (V : Interfaces.C.int) return Boolean is
   begin
      return V /= 0;
   end To_Bool;

   function To_Natural (V : Interfaces.C.int) return Natural is
   begin
      if V < 0 then
         return 0;
      else
         return Natural (V);
      end if;
   end To_Natural;

   function Primary_Modifier (Ev : Platform_Event) return Boolean is
   begin
      --  Platform mapping remains at the bridge boundary. Linux/Windows use
      --  Ctrl as the primary modifier; a future macOS bridge can map Command
      --  here without changing keybinding storage or executor semantics.
      return To_Bool (Ev.Ctrl);
   end Primary_Modifier;

   function To_Key_Chord
     (Ev    : Platform_Event;
      Chord : out Editor.Keybindings.Key_Chord) return Boolean
   is
   begin
      Chord.Modifiers :=
        (Ctrl  => Primary_Modifier (Ev),
         Shift => To_Bool (Ev.Shift),
         Alt   => To_Bool (Ev.Alt),
         Meta  => False);

      case Ev.Kind is
         when Key_Left =>
            Chord.Key := Editor.Keybindings.Key_Left;
         when Key_Right =>
            Chord.Key := Editor.Keybindings.Key_Right;
         when Key_Up =>
            Chord.Key := Editor.Keybindings.Key_Up;
         when Key_Down =>
            Chord.Key := Editor.Keybindings.Key_Down;
         when Key_Home =>
            Chord.Key := Editor.Keybindings.Key_Home;
         when Key_End =>
            Chord.Key := Editor.Keybindings.Key_End;
         when Key_Page_Up =>
            Chord.Key := Editor.Keybindings.Key_Page_Up;
         when Key_Page_Down =>
            Chord.Key := Editor.Keybindings.Key_Page_Down;
         when Key_Backspace =>
            Chord.Key := Editor.Keybindings.Key_Backspace;
         when Key_Delete =>
            Chord.Key := Editor.Keybindings.Key_Delete;
         when Key_Tab =>
            Chord.Key := Editor.Keybindings.Key_Tab;
         when Key_F2 =>
            Chord.Key := Editor.Keybindings.Key_F2;
         when Key_F3 =>
            Chord.Key := Editor.Keybindings.Key_F3;
         when Key_Undo =>
            Chord.Key := Editor.Keybindings.Key_Z;
            Chord.Modifiers.Ctrl := True;
         when Key_Redo =>
            Chord.Key := Editor.Keybindings.Key_Y;
            Chord.Modifiers.Ctrl := True;
            Chord.Modifiers.Shift := False;
         when Key_Save =>
            Chord.Key := Editor.Keybindings.Key_S;
            Chord.Modifiers.Ctrl := True;
         when Open_Command_Palette =>
            Chord.Key := Editor.Keybindings.Key_P;
            Chord.Modifiers.Ctrl := True;
         when Clear_Extra_Carets =>
            Chord.Key := Editor.Keybindings.Key_Escape;
            Chord.Modifiers := (Ctrl => False, Shift => False, Alt => False, Meta => False);
         when others =>
            return False;
      end case;

      return True;
   end To_Key_Chord;


   function To_Character_Key_Chord
     (Ev    : Platform_Event;
      Chord : out Editor.Keybindings.Key_Chord) return Boolean
   is
      Raw : constant Natural := Natural (Ev.Ch);
      Ch  : Character := ASCII.NUL;
   begin
      if Raw > 255 then
         return False;
      end if;

      Ch := Character'Val (Raw);
      Chord.Modifiers :=
        (Ctrl  => Primary_Modifier (Ev),
         Shift => To_Bool (Ev.Shift),
         Alt   => To_Bool (Ev.Alt),
         Meta  => False);

      case Ch is
         when 'a' | 'A' =>
            Chord.Key := Editor.Keybindings.Key_A;
         when 's' | 'S' =>
            Chord.Key := Editor.Keybindings.Key_S;
         when 'c' | 'C' =>
            Chord.Key := Editor.Keybindings.Key_C;
         when 'x' | 'X' =>
            Chord.Key := Editor.Keybindings.Key_X;
         when 'v' | 'V' =>
            Chord.Key := Editor.Keybindings.Key_V;
         when 'f' | 'F' =>
            Chord.Key := Editor.Keybindings.Key_F;
         when 'h' | 'H' =>
            Chord.Key := Editor.Keybindings.Key_H;
         when 'p' | 'P' =>
            Chord.Key := Editor.Keybindings.Key_P;
         when 'm' | 'M' =>
            Chord.Key := Editor.Keybindings.Key_M;
         when 'l' | 'L' =>
            Chord.Key := Editor.Keybindings.Key_L;
         when 'z' | 'Z' =>
            Chord.Key := Editor.Keybindings.Key_Z;
         when 'y' | 'Y' =>
            Chord.Key := Editor.Keybindings.Key_Y;
         when others =>
            return False;
      end case;

      return True;
   end To_Character_Key_Chord;

   function To_Command
     (Ev : Platform_Event) return Editor.Commands.Command
   is
      Cmd : Editor.Commands.Command;
   begin
      Cmd.Shift := To_Bool (Ev.Shift);
      Cmd.Ctrl  := To_Bool (Ev.Ctrl);
      Cmd.Alt   := To_Bool (Ev.Alt);

      Cmd.Click_X := To_Natural (Ev.X);
      Cmd.Click_Y := To_Natural (Ev.Y);

      case Ev.Kind is
         when Char_Input =>
            Cmd.Kind := Editor.Commands.Insert_Text_Input;
            if Ev.Ch <= Interfaces.C.unsigned (16#10FFFF#) then
               declare
                  Raw  : constant Natural := Natural (Ev.Ch);
                  Code : constant Editor.Unicode.Code_Point :=
                    Editor.Unicode.Code_Point'Val (Raw);
               begin
                  if Editor.Unicode.Is_Valid_Scalar (Code) then
                     Cmd.Code := Code;
                  else
                     Cmd.Code := Editor.Unicode.Replacement_Character;
                  end if;

                  if Raw <= 255 and then Editor.Unicode.Is_Valid_Scalar (Code) then
                     Cmd.Ch := Character'Val (Raw);
                  else
                     Cmd.Ch := ASCII.NUL;
                  end if;

                  Cmd.Text := To_Unbounded_String (Editor.UTF8.Encode_UTF8 (Cmd.Code));
               end;
            else
               Cmd.Code := Editor.Unicode.Replacement_Character;
               Cmd.Ch := ASCII.NUL;
               Cmd.Text := To_Unbounded_String (Editor.UTF8.Encode_UTF8 (Cmd.Code));
            end if;

         when Mouse_Down =>
            if Cmd.Shift and then Cmd.Alt then
               Cmd.Kind := Editor.Commands.Start_Rectangle_Selection;
            elsif Cmd.Alt then
               Cmd.Kind := Editor.Commands.Add_Caret_At_Point;
            elsif Cmd.Shift then
               Cmd.Kind := Editor.Commands.Drag_To_Point;
            else
               Cmd.Kind := Editor.Commands.Move_To_Point;
            end if;

         when Mouse_Drag =>
            if Cmd.Shift and then Cmd.Alt then
               Cmd.Kind := Editor.Commands.Drag_Rectangle_To_Point;
            else
               Cmd.Kind := Editor.Commands.Drag_To_Point;
            end if;

         when Mouse_Move =>
            Cmd.Kind := Editor.Commands.Pointer_Hover;

         when Select_Word =>
            Cmd.Kind := Editor.Commands.Select_Word_At_Point;

         when Select_Line =>
            Cmd.Kind := Editor.Commands.Select_Line_At_Point;

         when Add_Caret =>
            Cmd.Kind := Editor.Commands.Add_Caret_At_Point;

         when others =>
            Cmd.Kind := Editor.Commands.Break_Group;
      end case;

      return Cmd;
   end To_Command;

   procedure Editor_Init is
   begin
      Editor.Input_Bridge.Reset;
      Editor.View.Reset_Scroll;
   end Editor_Init;

   procedure Editor_Handle_Event
   (Ev : Platform_Event)
   is
      Chord : Editor.Keybindings.Key_Chord;
   begin
      case Ev.Kind is
         when Char_Input =>
            if To_Bool (Ev.Ctrl) or else To_Bool (Ev.Alt) then
               Send_Break_Group;
               if To_Character_Key_Chord (Ev, Chord) then
                  Editor.Input_Bridge.Handle_Key_Chord (Chord);
               end if;
            else
               if Ev.Ch = Interfaces.C.unsigned (Character'Pos (ASCII.LF)) then
                  Send_Break_Group;
               end if;
               Editor.Input_Bridge.Handle (To_Command (Ev));
            end if;

         when Mouse_Drag | Mouse_Move =>
            Editor.Input_Bridge.Handle (To_Command (Ev));

         when Mouse_Wheel =>
            Editor.Input_Bridge.Handle_Wheel
              (X       => To_Natural (Ev.X),
               Y       => To_Natural (Ev.Y),
               Delta_X => Integer (Ev.Wheel_X),
               Delta_Y => Integer (Ev.Wheel_Y));

         when Mouse_Down | Select_Word | Select_Line | Add_Caret =>
            Send_Break_Group;
            Editor.Input_Bridge.Handle (To_Command (Ev));

         when others =>
            Send_Break_Group;
            if To_Key_Chord (Ev, Chord) then
               Editor.Input_Bridge.Handle_Key_Chord (Chord);
            end if;
      end case;
   end Editor_Handle_Event;

end Editor.Bridge;
