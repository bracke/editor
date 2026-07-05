with Ada.Strings.Fixed;
with Ada.Containers;

with Editor.Buffers;
with Editor.Go_To_Line;
with Editor.Navigation_History;
with Editor.Overlay_Focus;
with Editor.Render_Cache;
with Editor.State;

package body Editor.Executor.Navigation_Commands is

   use type Ada.Containers.Count_Type;
   use type Editor.Executor.Navigation_Apply_Status;

   function Navigation_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
   begin
      case Id is
         when Editor.Commands.Command_Move_Left
            | Editor.Commands.Command_Move_Right
            | Editor.Commands.Command_Move_Up
            | Editor.Commands.Command_Move_Down
            | Editor.Commands.Command_Move_Line_Start
            | Editor.Commands.Command_Move_Line_End
            | Editor.Commands.Command_Move_Document_Start
            | Editor.Commands.Command_Move_Document_End
            | Editor.Commands.Command_Move_Word_Left
            | Editor.Commands.Command_Move_Word_Right
            | Editor.Commands.Command_Page_Up
            | Editor.Commands.Command_Page_Down
            | Editor.Commands.Command_Insert_Newline
            | Editor.Commands.Command_Goto_Start
            | Editor.Commands.Command_Goto_End =>
            if not Editor.State.Has_Active_Buffer (S) then
               return Editor.Commands.Unavailable ("No active buffer.");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Navigation_Back =>
            if not Editor.Navigation_History.Has_Back (S.Navigation_History) then
               return Editor.Commands.Unavailable
                 ("No previous navigation location");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Navigation_Forward =>
            if not Editor.Navigation_History.Has_Forward
              (S.Navigation_History)
            then
               return Editor.Commands.Unavailable
                 ("No next navigation location");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Navigation_History_Clear =>
            if not Editor.Navigation_History.Has_Back (S.Navigation_History)
              and then not Editor.Navigation_History.Has_Forward
                (S.Navigation_History)
            then
               return Editor.Commands.Unavailable ("No navigation history");
            end if;
            return Editor.Commands.Available;

         when others =>
            return Editor.Commands.Unavailable
              ("Command is not a navigation command");
      end case;
   end Navigation_Command_Availability;

   procedure Restore_Navigation_Stacks
     (S       : in out Editor.State.State_Type;
      Back    : Editor.Navigation_History.Location_Vectors.Vector;
      Forward : Editor.Navigation_History.Location_Vectors.Vector)
   is
   begin
      S.Navigation_History.Back_Stack := Back;
      S.Navigation_History.Forward_Stack := Forward;
   end Restore_Navigation_Stacks;

   function Navigation_Display
     (Location : Editor.Navigation_History.Navigation_Location) return String
   is
      Display : constant String :=
        (if Length (Location.Display_Path) > 0
         then To_String (Location.Display_Path)
         else To_String (Location.File_Path));
   begin
      if Location.Line > 0 then
         return Display & ":"
           & Ada.Strings.Fixed.Trim
             (Natural'Image (Location.Line), Ada.Strings.Both);
      end if;
      return Display;
   end Navigation_Display;

   function Navigation_Failure_Detail
     (Status : Editor.Executor.Navigation_Apply_Status) return String
   is
   begin
      case Status is
         when Editor.Executor.Navigation_Target_Invalid_Location =>
            return "invalid location";
         when others =>
            return "file not found";
      end case;
   end Navigation_Failure_Detail;

   procedure Execute_Navigation_Back
     (S : in out Editor.State.State_Type)
   is
      Target  : Editor.Navigation_History.Navigation_Location;
      Current : constant Editor.Navigation_History.Navigation_Location :=
        Editor.Executor.Current_Navigation_Location
          (S, Editor.Navigation_History.Navigation_Reason_Back);
      Old_Back    : constant Editor.Navigation_History.Location_Vectors.Vector :=
        S.Navigation_History.Back_Stack;
      Old_Forward : constant Editor.Navigation_History.Location_Vectors.Vector :=
        S.Navigation_History.Forward_Stack;
      Status      : Editor.Executor.Navigation_Apply_Status :=
        Editor.Executor.Navigation_Target_Missing;
   begin
      if not Editor.Navigation_History.Pop_Back (S.Navigation_History, Target) then
         Editor.Executor.Report_Info (S, "No previous navigation location");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      if Editor.Executor.Same_Navigation_Place (S, Target)
        or else not Editor.Executor.Apply_Navigation_Location (S, Target, Status)
      then
         Restore_Navigation_Stacks (S, Old_Back, Old_Forward);
         Editor.Executor.Report_Warning
           (S, "Could not navigate to " & Navigation_Display (Target)
            & ": " & Navigation_Failure_Detail (Status));
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Editor.Navigation_History.Record_Forward_Navigation
        (S.Navigation_History, Current);
      if Status = Editor.Executor.Navigation_Target_Invalid_Location then
         Editor.Executor.Report_Info
           (S, "Navigated back to " & Navigation_Display (Target)
            & "; could not move to line "
            & Ada.Strings.Fixed.Trim
              (Natural'Image (Target.Line), Ada.Strings.Both));
      else
         Editor.Executor.Report_Info
           (S, "Navigated back to " & Navigation_Display (Target));
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Navigation_Back;

   procedure Execute_Navigation_Forward
     (S : in out Editor.State.State_Type)
   is
      Target  : Editor.Navigation_History.Navigation_Location;
      Current : constant Editor.Navigation_History.Navigation_Location :=
        Editor.Executor.Current_Navigation_Location
          (S, Editor.Navigation_History.Navigation_Reason_Forward);
      Old_Back    : constant Editor.Navigation_History.Location_Vectors.Vector :=
        S.Navigation_History.Back_Stack;
      Old_Forward : constant Editor.Navigation_History.Location_Vectors.Vector :=
        S.Navigation_History.Forward_Stack;
      Status      : Editor.Executor.Navigation_Apply_Status :=
        Editor.Executor.Navigation_Target_Missing;
   begin
      if not Editor.Navigation_History.Pop_Forward
        (S.Navigation_History, Target)
      then
         Editor.Executor.Report_Info (S, "No next navigation location");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      if Editor.Executor.Same_Navigation_Place (S, Target)
        or else not Editor.Executor.Apply_Navigation_Location (S, Target, Status)
      then
         Restore_Navigation_Stacks (S, Old_Back, Old_Forward);
         Editor.Executor.Report_Warning
           (S, "Could not navigate to " & Navigation_Display (Target)
            & ": " & Navigation_Failure_Detail (Status));
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Editor.Navigation_History.Record_Back_Navigation
        (S.Navigation_History, Current);
      if Status = Editor.Executor.Navigation_Target_Invalid_Location then
         Editor.Executor.Report_Info
           (S, "Navigated forward to " & Navigation_Display (Target)
            & "; could not move to line "
            & Ada.Strings.Fixed.Trim
              (Natural'Image (Target.Line), Ada.Strings.Both));
      else
         Editor.Executor.Report_Info
           (S, "Navigated forward to " & Navigation_Display (Target));
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Navigation_Forward;

   procedure Execute_Navigation_History_Clear
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Navigation_History.Has_Back (S.Navigation_History)
        and then not Editor.Navigation_History.Has_Forward (S.Navigation_History)
      then
         Editor.Executor.Report_Info (S, "No navigation history to clear");
      else
         Editor.Navigation_History.Clear (S.Navigation_History);
         Editor.Executor.Report_Info (S, "Navigation history cleared");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Navigation_History_Clear;

   procedure Execute_Navigation_History_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind)
   is
   begin
      case Kind is
         when Editor.Commands.Navigation_Back =>
            Execute_Navigation_Back (S);
         when Editor.Commands.Navigation_Forward =>
            Execute_Navigation_Forward (S);
         when Editor.Commands.Navigation_History_Clear =>
            Execute_Navigation_History_Clear (S);
         when others =>
            null;
      end case;
   end Execute_Navigation_History_Kind;

   procedure Execute_Open_Goto_Line
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Activate_Overlay
        (S, Editor.Overlay_Focus.Go_To_Line_Overlay);
      Editor.Go_To_Line.Open (S.Go_To_Line);
      Editor.Go_To_Line.Clear_Error (S.Go_To_Line);
      Editor.Executor.Report_Info (S, "Go To Line shown");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Open_Goto_Line;

   procedure Execute_Toggle_Goto_Line
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Go_To_Line.Is_Open (S.Go_To_Line)
        and then Editor.Overlay_Focus.Is_Active
          (S.Overlay_Focus, Editor.Overlay_Focus.Go_To_Line_Overlay)
      then
         Execute_Close_Goto_Line (S);
      else
         Execute_Open_Goto_Line (S);
      end if;
   end Execute_Toggle_Goto_Line;

   procedure Execute_Prefill_Goto_Line_Current
     (S : in out Editor.State.State_Type)
   is
      Location : Editor.Navigation_History.Navigation_Location;

      function Number_Image (Value : Natural) return String is
      begin
         return Ada.Strings.Fixed.Trim
           (Natural'Image (Value), Ada.Strings.Both);
      end Number_Image;
   begin
      if not Editor.State.Has_Active_Buffer (S) then
         Editor.Executor.Report_Warning (S, "No active buffer.");
         return;
      elsif S.Carets.Length = 0 or else Editor.State.Line_Count (S) = 0 then
         Editor.Executor.Report_Warning (S, "No current caret location");
         return;
      end if;

      Location := Editor.Executor.Current_Navigation_Location
        (S, Editor.Navigation_History.Navigation_Reason_Go_To_Line);

      if not Editor.Navigation_History.Is_Recordable (Location)
        or else Location.Line = 0
      then
         Editor.Executor.Report_Warning (S, "No current caret location");
         return;
      end if;

      Editor.Executor.Activate_Overlay
        (S, Editor.Overlay_Focus.Go_To_Line_Overlay);
      Editor.Go_To_Line.Open (S.Go_To_Line);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, Number_Image (Location.Line));
      Editor.Executor.Report_Info
        (S, "Go To Line target: " & Number_Image (Location.Line));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Prefill_Goto_Line_Current;

   procedure Execute_Close_Goto_Line
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Go_To_Line_Overlay)
      then
         Editor.Executor.Dismiss_Active_Overlay
           (S, Editor.Overlay_Focus.Dismiss_Command);
         Editor.Go_To_Line.Clear (S.Go_To_Line);
      else
         Editor.Go_To_Line.Clear (S.Go_To_Line);
      end if;
      Editor.Executor.Report_Info (S, "Go To Line hidden");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Close_Goto_Line;

   procedure Execute_Accept_Goto_Line
     (S : in out Editor.State.State_Type)
   is
      Target_Row      : Natural := 0;
      Target_Column   : Natural := 0;
      Before_Location : Editor.Navigation_History.Navigation_Location;
      Target_Location : Editor.Navigation_History.Navigation_Location;

      function Number_Image (Value : Natural) return String is
      begin
         return Ada.Strings.Fixed.Trim
           (Natural'Image (Value), Ada.Strings.Both);
      end Number_Image;

      function Target_Text
        (Result : Editor.Go_To_Line.Go_To_Line_Validation_Result) return String
      is
      begin
         if Result.Has_Column then
            return Number_Image (Result.Line) & ":"
              & Number_Image (Result.Column);
         else
            return Number_Image (Result.Line);
         end if;
      end Target_Text;

      procedure Report_Goto_Line_Error (Text : String) is
      begin
         Editor.Go_To_Line.Set_Error (S.Go_To_Line, Text);
         Editor.Executor.Report_Warning (S, Text);
         Editor.Render_Cache.Invalidate_All;
      end Report_Goto_Line_Error;

      function Same_Goto_Target
        (Location      : Editor.Navigation_History.Navigation_Location;
         Result        : Editor.Go_To_Line.Go_To_Line_Validation_Result;
         Target_Column : Natural) return Boolean
      is
      begin
         if not Editor.Navigation_History.Is_Recordable (Location)
           or else Location.Line /= Result.Line
         then
            return False;
         end if;

         if Result.Has_Column then
            return Location.Column = Target_Column;
         else
            return True;
         end if;
      end Same_Goto_Target;
   begin
      if not Editor.Go_To_Line.Is_Open (S.Go_To_Line) then
         Report_Goto_Line_Error ("No active overlay");
         return;
      end if;

      if Ada.Strings.Fixed.Trim
        (Editor.Go_To_Line.Text (S.Go_To_Line), Ada.Strings.Both)'Length = 0
      then
         Report_Goto_Line_Error ("No go-to-line target");
         return;
      end if;

      if not Editor.State.Has_Active_Buffer (S) then
         Report_Goto_Line_Error ("No active buffer.");
         return;
      end if;

      declare
         Result : constant Editor.Go_To_Line.Go_To_Line_Validation_Result :=
           Editor.Go_To_Line.Validate
             (S.Go_To_Line, Editor.State.Line_Count (S));
      begin
         case Result.Status is
            when Editor.Go_To_Line.Go_To_Line_Empty =>
               Report_Goto_Line_Error ("No go-to-line target");
               return;
            when Editor.Go_To_Line.Go_To_Line_Invalid =>
               Report_Goto_Line_Error ("Invalid go-to-line target");
               return;
            when Editor.Go_To_Line.Go_To_Line_Out_Of_Range =>
               Report_Goto_Line_Error
                 ("Line " & Number_Image (Result.Line)
                  & " is outside the active buffer");
               return;
            when Editor.Go_To_Line.Go_To_Line_Valid =>
               null;
         end case;

         Target_Row := Result.Line - 1;
         if Result.Has_Column then
            Target_Column := Result.Column - 1;
         else
            Target_Column := 0;
         end if;

         if not Editor.Buffers.Global_Registry_Current_For (S) then
            Editor.Buffers.Ensure_Global_Registry (S);
         end if;
         Before_Location := Editor.Executor.Current_Navigation_Location
           (S, Editor.Navigation_History.Navigation_Reason_Go_To_Line);
         Target_Location := Before_Location;
         Target_Location.Line := Result.Line;
         Target_Location.Column := Target_Column;
         Target_Location.Reason :=
           Editor.Navigation_History.Navigation_Reason_Go_To_Line;

         if Same_Goto_Target (Before_Location, Result, Target_Column) then
            if Editor.Overlay_Focus.Is_Active
              (S.Overlay_Focus, Editor.Overlay_Focus.Go_To_Line_Overlay)
            then
               Editor.Executor.Dismiss_Active_Overlay
                 (S, Editor.Overlay_Focus.Dismiss_Accept);
               Editor.Go_To_Line.Clear (S.Go_To_Line);
            else
               Editor.Go_To_Line.Clear (S.Go_To_Line);
            end if;

            Editor.Executor.Report_Info
              (S, "Already at line " & Target_Text (Result));
            Editor.Render_Cache.Invalidate_All;
            return;
         end if;

         Editor.Executor.Apply_Feature_Target_Handoff
           (S, Target_Row, Target_Column);
         Editor.Executor.Record_Navigation_If_Target_Changed
           (S, Before_Location, Target_Location);

         if Editor.Overlay_Focus.Is_Active
           (S.Overlay_Focus, Editor.Overlay_Focus.Go_To_Line_Overlay)
         then
            Editor.Executor.Dismiss_Active_Overlay
              (S, Editor.Overlay_Focus.Dismiss_Accept);
            Editor.Go_To_Line.Clear (S.Go_To_Line);
         else
            Editor.Go_To_Line.Clear (S.Go_To_Line);
         end if;

         Editor.Executor.Report_Success
           (S, "Went to line " & Target_Text (Result));
         Editor.Render_Cache.Invalidate_All;
      end;
   end Execute_Accept_Goto_Line;

   procedure Execute_Goto_Line_Set_Query
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      if Editor.Go_To_Line.Is_Open (S.Go_To_Line) then
         Editor.Go_To_Line.Set_Text (S.Go_To_Line, Text);
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Execute_Goto_Line_Set_Query;

   procedure Execute_Goto_Line_Clear_Query
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Go_To_Line.Is_Open (S.Go_To_Line) then
         if Ada.Strings.Fixed.Trim
           (Editor.Go_To_Line.Text (S.Go_To_Line), Ada.Strings.Both)'Length = 0
         then
            Editor.Go_To_Line.Clear_Error (S.Go_To_Line);
            Editor.Executor.Report_Info (S, "No go-to-line query to clear");
         else
            Editor.Go_To_Line.Set_Text (S.Go_To_Line, "");
            Editor.Executor.Report_Info (S, "Go To Line query cleared");
         end if;
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Execute_Goto_Line_Clear_Query;

   procedure Execute_Goto_Line_Insert_Text
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      if Editor.Go_To_Line.Is_Open (S.Go_To_Line) then
         Editor.Go_To_Line.Insert_Text (S.Go_To_Line, Text);
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Execute_Goto_Line_Insert_Text;

   procedure Execute_Goto_Line_Backspace
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Go_To_Line.Is_Open (S.Go_To_Line) then
         Editor.Go_To_Line.Backspace (S.Go_To_Line);
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Execute_Goto_Line_Backspace;

   procedure Execute_Goto_Line_Delete_Forward
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Go_To_Line.Is_Open (S.Go_To_Line) then
         Editor.Go_To_Line.Delete_Forward (S.Go_To_Line);
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Execute_Goto_Line_Delete_Forward;

end Editor.Executor.Navigation_Commands;
