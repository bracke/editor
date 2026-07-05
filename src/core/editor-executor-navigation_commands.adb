with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Ada.Strings.Fixed;
with Ada.Containers;
with Ada.Directories;

with Editor.Ada_Language_Service;
with Editor.Ada_Project_Index;
with Editor.Executor.File_Open_Commands;
with Editor.Messages;
with Editor.Navigation;
with Editor.Recent_Buffers;
with Editor.View;
with Editor.Buffers;
with Editor.Go_To_Line;
with Editor.Navigation_History;
with Editor.Overlay_Focus;
with Editor.Render_Cache;
with Editor.State;

package body Editor.Executor.Navigation_Commands is

   use type Ada.Containers.Count_Type;
   use type Editor.Buffers.Buffer_Id;
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

   function Current_Navigation_Location
     (S      : Editor.State.State_Type;
      Reason : Editor.Navigation_History.Navigation_History_Reason :=
        Editor.Navigation_History.Navigation_Reason_Unknown)
      return Editor.Navigation_History.Navigation_Location
   is
      Row : Natural := 0;
      Col : Natural := 0;
   begin
      if not Editor.State.Has_Active_Buffer (S)
        or else S.Carets.Length = 0
        or else Editor.State.Line_Count (S) = 0
      then
         return (others => <>);
      end if;

      Editor.Navigation.Line_Column_For_Index
        (S, Natural (Editor.Executor.Safe_Caret (S)), Row, Col);

      return
        (Buffer_Id      => Editor.Executor.Active_Feature_Buffer_Token (S),
         Has_File_Path  => S.File_Info.Has_Path,
         File_Path      => S.File_Info.Path,
         Display_Path   => S.File_Info.Display_Name,
         Line           => Row + 1,
         Column         => Col,
         Viewport_Row   => Editor.View.Scroll_Y,
         Reason         => Reason);
   end Current_Navigation_Location;

   function Structured_File_Navigation_Target
     (Path   : String;
      Line   : Natural := 1;
      Column : Natural := 0;
      Reason : Editor.Navigation_History.Navigation_History_Reason :=
        Editor.Navigation_History.Navigation_Reason_Unknown)
      return Editor.Navigation_History.Navigation_Location
   is
   begin
      if Path'Length = 0 or else Line = 0 then
         return (others => <>);
      end if;

      return
        (Buffer_Id      => 0,
         Has_File_Path  => True,
         File_Path      => To_Unbounded_String (Path),
         Display_Path   => To_Unbounded_String (Path),
         Line           => Line,
         Column         => Column,
         Viewport_Row   => 0,
         Reason         => Reason);
   end Structured_File_Navigation_Target;

   function Same_Navigation_Place
     (S        : Editor.State.State_Type;
      Location : Editor.Navigation_History.Navigation_Location) return Boolean
   is
   begin
      return Editor.Navigation_History.Locations_Equal
        (Current_Navigation_Location (S), Location);
   end Same_Navigation_Place;

   procedure Record_Navigation_If_Target_Changed
     (S        : in out Editor.State.State_Type;
      Previous : Editor.Navigation_History.Navigation_Location;
      Target   : Editor.Navigation_History.Navigation_Location)
   is
   begin
      Editor.Navigation_History.Record_Explicit_Navigation_If_Target_Changed
        (S.Navigation_History, Previous, Target);
   end Record_Navigation_If_Target_Changed;

   procedure Record_Navigation_If_Current_Changed
     (S        : in out Editor.State.State_Type;
      Previous : Editor.Navigation_History.Navigation_Location)
   is
   begin
      Record_Navigation_If_Target_Changed
        (S, Previous, Current_Navigation_Location (S));
   end Record_Navigation_If_Current_Changed;

   function Navigation_Target_Is_Valid
     (S        : Editor.State.State_Type;
      Location : Editor.Navigation_History.Navigation_Location) return Boolean
   is
      Target_State : Editor.State.State_Type;
      Found        : Boolean := False;
      Id           : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      if Location.Has_File_Path then
         if S.File_Info.Has_Path
           and then To_String (S.File_Info.Path) = To_String (Location.File_Path)
         then
            Target_State := S;
         else
            Id := Editor.Buffers.Global_Find_By_Path
              (To_String (Location.File_Path), Found);
            if not Found or else Id = Editor.Buffers.No_Buffer then
               return Ada.Directories.Exists (To_String (Location.File_Path));
            end if;
            Target_State := Editor.Buffers.Buffer
              (Editor.Buffers.Global_Registry_For_UI, Id);
         end if;
      elsif Location.Buffer_Id /= 0 then
         if Location.Buffer_Id = Editor.Executor.Active_Feature_Buffer_Token (S) then
            Target_State := S;
         elsif Editor.Buffers.Global_Contains
           (Editor.Buffers.Buffer_Id (Location.Buffer_Id))
         then
            Target_State := Editor.Buffers.Buffer
              (Editor.Buffers.Global_Registry_For_UI,
               Editor.Buffers.Buffer_Id (Location.Buffer_Id));
         else
            return False;
         end if;
      else
         return False;
      end if;

      return Location.Line > 0
        and then Location.Line <= Editor.State.Line_Count (Target_State)
        and then Location.Column <= Editor.Navigation.Line_Length
          (Target_State, Location.Line - 1);
   end Navigation_Target_Is_Valid;

   function Apply_Navigation_Location
     (S        : in out Editor.State.State_Type;
      Location : Editor.Navigation_History.Navigation_Location;
      Status   : out Editor.Executor.Navigation_Apply_Status) return Boolean
   is
      Path       : constant String := To_String (Location.File_Path);
      Found_Open : Boolean := False;
      Id         : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Status := Editor.Executor.Navigation_Target_Missing;

      if Location.Has_File_Path and then Path'Length > 0 then
         Id := Editor.Buffers.Global_Find_By_Path (Path, Found_Open);
         if Found_Open and then Id /= Editor.Buffers.No_Buffer then
            --  completeness: for already-open file-backed targets,
            --  validate the stored line/column before changing the active buffer.
            --  A stale line must restore history stacks without silently moving the
            --  user to the failed target buffer.
            if not Navigation_Target_Is_Valid (S, Location) then
               Status := Editor.Executor.Navigation_Target_Invalid_Location;
               return False;
            end if;
            Editor.Buffers.Global_Set_Active_Buffer (Id);
            declare
               Saved_Index : constant Editor.Ada_Project_Index.Index_State :=
                 S.Language_Index;
               Saved_Service : constant Editor.Ada_Language_Service.Service_State :=
                 S.Language_Service;
            begin
               Editor.Buffers.Load_Global_Active_Into_State (S);
               S.Language_Index := Saved_Index;
               S.Language_Service := Saved_Service;
            end;
            Editor.Recent_Buffers.Mark_Activated (S.Recent_Buffers, Natural (Id));
         else
            if not Ada.Directories.Exists (Path) then
               Status := Editor.Executor.Navigation_Target_Missing;
               return False;
            end if;
            Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
            Editor.Messages.Dismiss_Latest (S.Messages);
            if not S.File_Info.Has_Path or else To_String (S.File_Info.Path) /= Path then
               Status := Editor.Executor.Navigation_Target_Missing;
               return False;
            end if;
            if not Navigation_Target_Is_Valid (S, Location) then
               --  completeness: if the file was successfully opened
               --  but the stored line/column is stale, treat navigation as a
               --  partial success.  The active file changed through the normal
               --  open path, so back/forward stacks must advance rather than
               --  being restored as if no navigation occurred.
               Status := Editor.Executor.Navigation_Target_Invalid_Location;
               return True;
            end if;
         end if;
      elsif Location.Buffer_Id /= 0 then
         if not Navigation_Target_Is_Valid (S, Location) then
            Status := Editor.Executor.Navigation_Target_Invalid_Location;
            return False;
         end if;
         if not Editor.Executor.Focus_Feature_Target_Buffer (S, Location.Buffer_Id) then
            Status := Editor.Executor.Navigation_Target_Missing;
            return False;
         end if;
      else
         Status := Editor.Executor.Navigation_Target_Missing;
         return False;
      end if;

      Editor.Executor.Apply_Feature_Target_Handoff (S, Location.Line - 1, Location.Column);
      Status := Editor.Executor.Navigation_Applied;
      return True;
   end Apply_Navigation_Location;

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
         Editor.Executor.Shared_Services.Report_Info (S, "No previous navigation location");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      if Editor.Executor.Same_Navigation_Place (S, Target)
        or else not Editor.Executor.Apply_Navigation_Location (S, Target, Status)
      then
         Restore_Navigation_Stacks (S, Old_Back, Old_Forward);
         Editor.Executor.Shared_Services.Report_Warning
           (S, "Could not navigate to " & Navigation_Display (Target)
            & ": " & Navigation_Failure_Detail (Status));
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Editor.Navigation_History.Record_Forward_Navigation
        (S.Navigation_History, Current);
      if Status = Editor.Executor.Navigation_Target_Invalid_Location then
         Editor.Executor.Shared_Services.Report_Info
           (S, "Navigated back to " & Navigation_Display (Target)
            & "; could not move to line "
            & Ada.Strings.Fixed.Trim
              (Natural'Image (Target.Line), Ada.Strings.Both));
      else
         Editor.Executor.Shared_Services.Report_Info
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
         Editor.Executor.Shared_Services.Report_Info (S, "No next navigation location");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      if Editor.Executor.Same_Navigation_Place (S, Target)
        or else not Editor.Executor.Apply_Navigation_Location (S, Target, Status)
      then
         Restore_Navigation_Stacks (S, Old_Back, Old_Forward);
         Editor.Executor.Shared_Services.Report_Warning
           (S, "Could not navigate to " & Navigation_Display (Target)
            & ": " & Navigation_Failure_Detail (Status));
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Editor.Navigation_History.Record_Back_Navigation
        (S.Navigation_History, Current);
      if Status = Editor.Executor.Navigation_Target_Invalid_Location then
         Editor.Executor.Shared_Services.Report_Info
           (S, "Navigated forward to " & Navigation_Display (Target)
            & "; could not move to line "
            & Ada.Strings.Fixed.Trim
              (Natural'Image (Target.Line), Ada.Strings.Both));
      else
         Editor.Executor.Shared_Services.Report_Info
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
         Editor.Executor.Shared_Services.Report_Info (S, "No navigation history to clear");
      else
         Editor.Navigation_History.Clear (S.Navigation_History);
         Editor.Executor.Shared_Services.Report_Info (S, "Navigation history cleared");
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
      Editor.Executor.Shared_Services.Report_Info (S, "Go To Line shown");
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
         Editor.Executor.Shared_Services.Report_Warning (S, "No active buffer.");
         return;
      elsif S.Carets.Length = 0 or else Editor.State.Line_Count (S) = 0 then
         Editor.Executor.Shared_Services.Report_Warning (S, "No current caret location");
         return;
      end if;

      Location := Editor.Executor.Current_Navigation_Location
        (S, Editor.Navigation_History.Navigation_Reason_Go_To_Line);

      if not Editor.Navigation_History.Is_Recordable (Location)
        or else Location.Line = 0
      then
         Editor.Executor.Shared_Services.Report_Warning (S, "No current caret location");
         return;
      end if;

      Editor.Executor.Activate_Overlay
        (S, Editor.Overlay_Focus.Go_To_Line_Overlay);
      Editor.Go_To_Line.Open (S.Go_To_Line);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, Number_Image (Location.Line));
      Editor.Executor.Shared_Services.Report_Info
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
      Editor.Executor.Shared_Services.Report_Info (S, "Go To Line hidden");
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
         Editor.Executor.Shared_Services.Report_Warning (S, Text);
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

            Editor.Executor.Shared_Services.Report_Info
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

         Editor.Executor.Shared_Services.Report_Success
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
            Editor.Executor.Shared_Services.Report_Info (S, "No go-to-line query to clear");
         else
            Editor.Go_To_Line.Set_Text (S.Go_To_Line, "");
            Editor.Executor.Shared_Services.Report_Info (S, "Go To Line query cleared");
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
