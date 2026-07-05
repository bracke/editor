with Editor.Buffer_Switcher;
with Editor.Buffers;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Executor;
with Editor.Executor.Buffer_Switcher_Shared;
with Editor.Messages;
with Editor.Overlay_Focus;
with Editor.Render_Cache;

package body Editor.Executor.Buffer_Switcher_Preview_Commands is

   use type Editor.Buffers.Buffer_Id;
   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Kind;
   use type Editor.Messages.Message_Severity;

   function Active_Buffer_Switcher_Overlay
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Buffer_Switcher_Overlay)
        and then Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher);
   end Active_Buffer_Switcher_Overlay;

   function Selected_Row
     (S     : Editor.State.State_Type;
      Found : out Boolean) return Editor.Buffer_Switcher.Buffer_Switcher_Row
   is
   begin
      return Editor.Executor.Buffer_Switcher_Shared.Selected_Switcher_Buffer
        (S, Found);
   end Selected_Row;

   function Selected_Open_Buffer_Availability
     (S : Editor.State.State_Type) return Editor.Commands.Command_Availability
   is
      Found : Boolean := False;
      Row   : Editor.Buffer_Switcher.Buffer_Switcher_Row;
   begin
      if not Active_Buffer_Switcher_Overlay (S) then
         return Editor.Commands.Unavailable ("No active overlay");
      end if;

      Row := Selected_Row (S, Found);
      if not Found then
         return Editor.Commands.Unavailable ("No buffer selected");
      elsif Row.Id = Editor.Buffers.No_Buffer then
         return Editor.Commands.Unavailable ("Selected row is not a buffer");
      elsif not Editor.Buffers.Global_Contains (Row.Id) then
         return Editor.Commands.Unavailable ("Selected buffer is no longer open");
      end if;

      return Editor.Commands.Available;
   end Selected_Open_Buffer_Availability;

   procedure Report_No_Selected_Switcher_Buffer
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Report_Info (S, "No selected buffer");
   end Report_No_Selected_Switcher_Buffer;

   function Visible_Preview_Availability
     (S              : Editor.State.State_Type;
      Require_Row    : Boolean;
      Require_Open   : Boolean)
      return Editor.Commands.Command_Availability
   is
   begin
      if not Active_Buffer_Switcher_Overlay (S) then
         return Editor.Commands.Unavailable ("No active overlay");
      elsif Require_Open
        and then not Editor.Buffer_Switcher.Has_Preview (S.Buffer_Switcher)
      then
         return Editor.Commands.Unavailable ("Switcher preview is hidden");
      elsif Require_Row then
         declare
            Found : Boolean := False;
            Row   : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
              Selected_Row (S, Found);
         begin
            if not Found or else Row.Id = Editor.Buffers.No_Buffer then
               return Editor.Commands.Unavailable ("No buffer selected");
            end if;
         end;
      end if;

      return Editor.Commands.Available;
   end Visible_Preview_Availability;

   function Buffer_Switcher_Preview_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
   begin
      case Id is
         when Editor.Commands.Command_Buffer_Switcher_Preview_Toggle
            | Editor.Commands.Command_Buffer_Switcher_Preview_Show =>
            return Selected_Open_Buffer_Availability (S);

         when Editor.Commands.Command_Buffer_Switcher_Preview_Hide =>
            return Visible_Preview_Availability
              (S, Require_Row => False, Require_Open => True);

         when Editor.Commands.Command_Buffer_Switcher_Preview_Next_Line
            | Editor.Commands.Command_Buffer_Switcher_Preview_Previous_Line
            | Editor.Commands.Command_Buffer_Switcher_Preview_Center_Cursor =>
            return Visible_Preview_Availability
              (S, Require_Row => True, Require_Open => True);

         when others =>
            return Editor.Commands.Unavailable
              ("Not a buffer switcher preview command");
      end case;
   end Buffer_Switcher_Preview_Command_Availability;

   procedure Execute_Buffer_Switcher_Preview_Toggle
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Buffer_Switcher.Has_Preview (S.Buffer_Switcher) then
         Execute_Buffer_Switcher_Preview_Hide (S);
      else
         Execute_Buffer_Switcher_Preview_Show (S);
      end if;
   end Execute_Buffer_Switcher_Preview_Toggle;

   procedure Execute_Buffer_Switcher_Preview_Show
     (S : in out Editor.State.State_Type)
   is
      Found : Boolean := False;
      Row   : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
        Selected_Row (S, Found);
   begin
      if not Found or else Row.Id = Editor.Buffers.No_Buffer then
         Report_No_Selected_Switcher_Buffer (S);
         return;
      end if;

      Editor.Buffer_Switcher.Show_Preview (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Set_Preview_Target
        (S.Buffer_Switcher, Row.Id,
         Editor.Executor.Buffer_Switcher_Shared.Primary_Cursor_Line_Of_Buffer
           (Row.Id));
      Editor.Executor.Report_Info (S, "Switcher preview shown");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Preview_Show;

   procedure Execute_Buffer_Switcher_Preview_Hide
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Buffer_Switcher.Hide_Preview (S.Buffer_Switcher);
      Editor.Executor.Report_Info (S, "Switcher preview hidden");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Preview_Hide;

   procedure Execute_Buffer_Switcher_Preview_Next_Line
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Buffer_Switcher.Scroll_Preview_Next_Line (S.Buffer_Switcher);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Preview_Next_Line;

   procedure Execute_Buffer_Switcher_Preview_Previous_Line
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Buffer_Switcher.Scroll_Preview_Previous_Line (S.Buffer_Switcher);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Preview_Previous_Line;

   procedure Execute_Buffer_Switcher_Preview_Center_Cursor
     (S : in out Editor.State.State_Type)
   is
      Found : Boolean := False;
      Row   : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
        Selected_Row (S, Found);
   begin
      if not Found or else Row.Id = Editor.Buffers.No_Buffer then
         Report_No_Selected_Switcher_Buffer (S);
         return;
      end if;

      if not Editor.Buffer_Switcher.Has_Preview (S.Buffer_Switcher) then
         Editor.Buffer_Switcher.Show_Preview (S.Buffer_Switcher);
      end if;
      Editor.Buffer_Switcher.Set_Preview_Target
        (S.Buffer_Switcher, Row.Id,
         Editor.Executor.Buffer_Switcher_Shared.Primary_Cursor_Line_Of_Buffer
           (Row.Id));
      Editor.Executor.Report_Info (S, "Preview at cursor");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Preview_Center_Cursor;

   procedure Execute_Buffer_Switcher_Preview_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind)
   is
   begin
      case Kind is
         when Editor.Commands.Buffer_Switcher_Preview_Toggle =>
            Execute_Buffer_Switcher_Preview_Toggle (S);
         when Editor.Commands.Buffer_Switcher_Preview_Show =>
            Execute_Buffer_Switcher_Preview_Show (S);
         when Editor.Commands.Buffer_Switcher_Preview_Hide =>
            Execute_Buffer_Switcher_Preview_Hide (S);
         when Editor.Commands.Buffer_Switcher_Preview_Next_Line =>
            Execute_Buffer_Switcher_Preview_Next_Line (S);
         when Editor.Commands.Buffer_Switcher_Preview_Previous_Line =>
            Execute_Buffer_Switcher_Preview_Previous_Line (S);
         when Editor.Commands.Buffer_Switcher_Preview_Center_Cursor =>
            Execute_Buffer_Switcher_Preview_Center_Cursor (S);
         when others =>
            null;
      end case;
   end Execute_Buffer_Switcher_Preview_Kind;

   function Execute_Buffer_Switcher_Preview_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Before_Messages : constant Natural := Editor.Messages.Count (S.Messages);

      function Result_After_Command
        (Command : Editor.Commands.Command_Id)
         return Editor.Command_Execution.Command_Execution_Result
      is
         Found : Boolean := False;
         Msg   : Editor.Messages.Editor_Message;
      begin
         if Editor.Messages.Count (S.Messages) > Before_Messages then
            Msg := Editor.Messages.Active_Message (S.Messages, Found);
            if Found then
               if Editor.Messages.Severity (Msg) =
                 Editor.Messages.Error_Message
               then
                  return Editor.Command_Execution.Failed (Command);
               elsif Editor.Messages.Severity (Msg) =
                 Editor.Messages.Warning_Message
               then
                  return Editor.Command_Execution.Unavailable (Command);
               end if;
            end if;
         end if;

         return Editor.Command_Execution.Executed (Command);
      end Result_After_Command;
   begin
      case Id is
         when Editor.Commands.Command_Buffer_Switcher_Preview_Toggle =>
            Execute_Buffer_Switcher_Preview_Toggle (S);
         when Editor.Commands.Command_Buffer_Switcher_Preview_Show =>
            Execute_Buffer_Switcher_Preview_Show (S);
         when Editor.Commands.Command_Buffer_Switcher_Preview_Hide =>
            Execute_Buffer_Switcher_Preview_Hide (S);
         when Editor.Commands.Command_Buffer_Switcher_Preview_Next_Line =>
            Execute_Buffer_Switcher_Preview_Next_Line (S);
         when Editor.Commands.Command_Buffer_Switcher_Preview_Previous_Line =>
            Execute_Buffer_Switcher_Preview_Previous_Line (S);
         when Editor.Commands.Command_Buffer_Switcher_Preview_Center_Cursor =>
            Execute_Buffer_Switcher_Preview_Center_Cursor (S);
         when others =>
            return Editor.Command_Execution.No_Op (Id);
      end case;

      return Result_After_Command (Id);
   end Execute_Buffer_Switcher_Preview_Command;

end Editor.Executor.Buffer_Switcher_Preview_Commands;
