with Ada.Containers;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Terminal_Tasks is

   use type Ada.Containers.Count_Type;
   use type Editor.External_Producers.Process_Run_Status;

   Max_Output_Rows : constant Natural := 500;

   function Empty_State return Terminal_Task_State is
   begin
      return (others => <>);
   end Empty_State;

   function Status_Text (Status : Terminal_Task_Status) return String is
   begin
      case Status is
         when Task_Not_Run =>
            return "not run";
         when Task_Running =>
            return "running";
         when Task_Succeeded =>
            return "succeeded";
         when Task_Failed =>
            return "failed";
         when Task_Not_Available =>
            return "not available";
         when Task_Rejected =>
            return "rejected";
         when Task_Timed_Out =>
            return "timed out";
         when Task_Cancelled =>
            return "cancelled";
      end case;
   end Status_Text;

   function Profile_Text (Profile : Terminal_Task_Profile) return String is
   begin
      case Profile is
         when Task_Profile_Default =>
            return "default";
         when Task_Profile_Build =>
            return "build";
         when Task_Profile_Run =>
            return "run";
         when Task_Profile_Development =>
            return "development";
         when Task_Profile_Release =>
            return "release";
         when Task_Profile_Validation =>
            return "validation";
         when Task_Profile_Test =>
            return "test";
         when Task_Profile_Custom =>
            return "custom";
      end case;
   end Profile_Text;

   function Map_Status
     (Status : Editor.External_Producers.Process_Run_Status)
      return Terminal_Task_Status
   is
   begin
      case Status is
         when Editor.External_Producers.Process_Run_Succeeded =>
            return Task_Succeeded;
         when Editor.External_Producers.Process_Run_Failed
            | Editor.External_Producers.Process_Run_Execution_Error
            | Editor.External_Producers.Process_Run_Output_Truncated =>
            return Task_Failed;
         when Editor.External_Producers.Process_Run_Not_Available =>
            return Task_Not_Available;
         when Editor.External_Producers.Process_Run_Rejected =>
            return Task_Rejected;
         when Editor.External_Producers.Process_Run_Timed_Out =>
            return Task_Timed_Out;
         when Editor.External_Producers.Process_Run_Cancelled =>
            return Task_Cancelled;
         when Editor.External_Producers.Process_Run_Cancellation_Unsupported =>
            return Task_Not_Available;
      end case;
   end Map_Status;

   function Index_For_Id
     (State : Terminal_Task_State;
      Id    : Natural) return Natural
   is
   begin
      if Id = 0 then
         return 0;
      end if;

      for I in State.Rows.First_Index .. State.Rows.Last_Index loop
         if State.Rows (I).Id = Id then
            return I;
         end if;
      end loop;

      return 0;
   end Index_For_Id;

   procedure Refresh_Selection (State : in out Terminal_Task_State) is
   begin
      if State.Rows.Is_Empty then
         State.Selected_Index := 0;
      elsif State.Selected_Index < State.Rows.First_Index
        or else State.Selected_Index > State.Rows.Last_Index
      then
         State.Selected_Index := State.Rows.First_Index;
      end if;

      for I in State.Rows.First_Index .. State.Rows.Last_Index loop
         declare
            Row : Terminal_Task_Row := State.Rows (I);
         begin
            Row.Selected := I = State.Selected_Index;
            State.Rows.Replace_Element (I, Row);
         end;
      end loop;
   end Refresh_Selection;

   procedure Append_Output_Line
     (State : in out Terminal_Task_State;
      Text  : String)
   is
   begin
      State.Output_Rows.Append (To_Unbounded_String (Text));
      while Natural (State.Output_Rows.Length) > Max_Output_Rows loop
         State.Output_Rows.Delete_First;
      end loop;
   end Append_Output_Line;

   procedure Append_Output_Text
     (State : in out Terminal_Task_State;
      Text  : Unbounded_String)
   is
      S     : constant String := To_String (Text);
      Start : Positive := S'First;
   begin
      if S'Length = 0 then
         return;
      end if;

      for I in S'Range loop
         if S (I) = ASCII.LF then
            if I > Start then
               Append_Output_Line (State, S (Start .. I - 1));
            else
               Append_Output_Line (State, "");
            end if;
            Start := I + 1;
         end if;
      end loop;

      if Start <= S'Last then
         Append_Output_Line (State, S (Start .. S'Last));
      end if;
   end Append_Output_Text;

   function Command_Line (Row : Terminal_Task_Row) return String is
      Result : Unbounded_String := Row.Program_Label;
   begin
      for Arg of Row.Arguments loop
         Append (Result, " ");
         Append (Result, To_String (Arg));
      end loop;
      return To_String (Result);
   end Command_Line;

   function Has_Project_Task
     (State        : Terminal_Task_State;
      Project_Root : String;
      Profile      : Terminal_Task_Profile;
      First_Arg     : String) return Boolean
   is
   begin
      if State.Rows.Is_Empty then
         return False;
      end if;

      for I in State.Rows.First_Index .. State.Rows.Last_Index loop
         declare
            Row : constant Terminal_Task_Row := State.Rows (I);
         begin
            if Row.Profile = Profile
              and then To_String (Row.Working_Label) = Project_Root
              and then Natural (Row.Arguments.Length) > 0
              and then To_String (Row.Arguments (Row.Arguments.First_Index)) =
                First_Arg
            then
               return True;
            end if;
         end;
      end loop;

      return False;
   end Has_Project_Task;

   procedure Show (State : in out Terminal_Task_State) is
   begin
      State.Visible := True;
   end Show;

   procedure Focus (State : in out Terminal_Task_State) is
   begin
      State.Visible := True;
      State.Focused := True;
   end Focus;

   procedure Unfocus (State : in out Terminal_Task_State) is
   begin
      State.Focused := False;
   end Unfocus;

   procedure Hide (State : in out Terminal_Task_State) is
   begin
      State.Visible := False;
      State.Focused := False;
   end Hide;

   procedure Toggle (State : in out Terminal_Task_State) is
   begin
      if State.Visible then
         Hide (State);
      else
         Show (State);
      end if;
   end Toggle;

   procedure Clear (State : in out Terminal_Task_State) is
   begin
      State.Rows.Clear;
      State.Output_Rows.Clear;
      State.Selected_Index := 0;
      State.Has_Last_Run := False;
      State.Last_Run_Id := 0;
      State.Status_Label := To_Unbounded_String ("No terminal tasks");
      State.Active_Command_Line := Null_Unbounded_String;
      State.Working_Directory := Null_Unbounded_String;
   end Clear;

   procedure Clear_Output (State : in out Terminal_Task_State) is
   begin
      State.Output_Rows.Clear;
      State.Status_Label := To_Unbounded_String ("Terminal output cleared");
   end Clear_Output;

   procedure Ensure_Project_Default_Tasks
     (State      : in out Terminal_Task_State;
      Project_Root : String)
   is
      Root : constant String :=
        Ada.Strings.Fixed.Trim (Project_Root, Ada.Strings.Both);

      procedure Ensure_Alire_Build_Task
        (Label       : String;
         Profile     : Terminal_Task_Profile;
         Profile_Arg : String := "")
      is
         Id : Natural;
      begin
         if Has_Project_Task (State, Root, Profile, "build") then
            return;
         end if;

         Id := Register_Task (State, Label, "alr", Root, Profile);
         Append_Argument (State, Id, "build");
         if Profile_Arg'Length > 0 then
            Append_Argument (State, Id, Profile_Arg);
         end if;
      end Ensure_Alire_Build_Task;
   begin
      if Root'Length = 0 then
         return;
      end if;

      Ensure_Alire_Build_Task ("Alire Build", Task_Profile_Build);

      if not Has_Project_Task (State, Root, Task_Profile_Run, "run") then
         declare
            Id : constant Natural :=
              Register_Task
                (State, "Alire Run", "alr", Root, Task_Profile_Run);
         begin
            Append_Argument (State, Id, "run");
         end;
      end if;

      Ensure_Alire_Build_Task
        ("Alire Build Development", Task_Profile_Development,
         "--development");
      Ensure_Alire_Build_Task
        ("Alire Build Release", Task_Profile_Release, "--release");
      Ensure_Alire_Build_Task
        ("Alire Build Validation", Task_Profile_Validation,
         "--validation");

      if not Has_Project_Task (State, Root, Task_Profile_Test, "test") then
         declare
            Id : constant Natural :=
              Register_Task
                (State, "Alire Test", "alr", Root, Task_Profile_Test);
         begin
            Append_Argument (State, Id, "test");
         end;
      end if;
   end Ensure_Project_Default_Tasks;

   procedure Select_Next (State : in out Terminal_Task_State) is
   begin
      if State.Rows.Is_Empty then
         State.Selected_Index := 0;
      elsif State.Selected_Index >= State.Rows.Last_Index then
         State.Selected_Index := State.Rows.First_Index;
      else
         State.Selected_Index := State.Selected_Index + 1;
      end if;
      Refresh_Selection (State);
   end Select_Next;

   procedure Select_Previous (State : in out Terminal_Task_State) is
   begin
      if State.Rows.Is_Empty then
         State.Selected_Index := 0;
      elsif State.Selected_Index <= State.Rows.First_Index then
         State.Selected_Index := State.Rows.Last_Index;
      else
         State.Selected_Index := State.Selected_Index - 1;
      end if;
      Refresh_Selection (State);
   end Select_Previous;

   function Select_First_Profile
     (State   : in out Terminal_Task_State;
      Profile : Terminal_Task_Profile) return Boolean
   is
   begin
      if State.Rows.Is_Empty then
         State.Selected_Index := 0;
         return False;
      end if;

      for I in State.Rows.First_Index .. State.Rows.Last_Index loop
         if State.Rows (I).Profile = Profile then
            State.Selected_Index := I;
            Refresh_Selection (State);
            return True;
         end if;
      end loop;

      Refresh_Selection (State);
      return False;
   end Select_First_Profile;

   function Register_Task
     (State         : in out Terminal_Task_State;
      Label         : String;
      Program_Label : String;
      Working_Label : String := "";
      Profile       : Terminal_Task_Profile := Task_Profile_Custom)
      return Natural
   is
      Id  : constant Natural := State.Next_Id;
      Row : Terminal_Task_Row;
   begin
      Row.Id := Id;
      Row.Label := To_Unbounded_String
        (Ada.Strings.Fixed.Trim (Label, Ada.Strings.Both));
      Row.Program_Label := To_Unbounded_String
        (Ada.Strings.Fixed.Trim (Program_Label, Ada.Strings.Both));
      Row.Working_Label := To_Unbounded_String
        (Ada.Strings.Fixed.Trim (Working_Label, Ada.Strings.Both));
      Row.Profile := Profile;
      Row.Profile_Label := To_Unbounded_String (Profile_Text (Profile));
      Row.Status_Label := To_Unbounded_String (Status_Text (Row.Status));
      Row.Rerunnable := To_String (Row.Program_Label)'Length > 0;
      State.Rows.Append (Row);
      State.Next_Id := State.Next_Id + 1;
      if State.Selected_Index = 0 then
         State.Selected_Index := State.Rows.Last_Index;
      end if;
      State.Status_Label := To_Unbounded_String ("Task registered: " & Label);
      Refresh_Selection (State);
      return Id;
   end Register_Task;

   procedure Append_Argument
     (State : in out Terminal_Task_State;
      Id    : Natural;
      Value : String)
   is
      Index : constant Natural := Index_For_Id (State, Id);
   begin
      if Index = 0 then
         return;
      end if;

      declare
         Row : Terminal_Task_Row := State.Rows (Index);
      begin
         Row.Arguments.Append (To_Unbounded_String (Value));
         State.Rows.Replace_Element (Index, Row);
      end;
   end Append_Argument;

   procedure Apply_Result
     (State  : in out Terminal_Task_State;
      Index  : Natural;
      Result : Editor.External_Producers.Process_Run_Result)
   is
      Row : Terminal_Task_Row := State.Rows (Index);
   begin
      Row.Status := Map_Status (Result.Status);
      Row.Status_Label := To_Unbounded_String (Status_Text (Row.Status));
      Row.Has_Exit_Code := Result.Has_Exit_Code;
      Row.Exit_Code := Result.Exit_Code;
      Row.Rerunnable := True;
      Row.Last_Output := Result.Stdout_Text;
      if To_String (Row.Last_Output)'Length = 0 then
         Row.Last_Output := Result.Stderr_Text;
      end if;

      State.Rows.Replace_Element (Index, Row);
      State.Selected_Index := Index;
      State.Has_Last_Run := True;
      State.Last_Run_Id := Row.Id;
      State.Status_Label := To_Unbounded_String
        ("Task " & To_String (Row.Label) & " " & Status_Text (Row.Status));
      State.Active_Command_Line := To_Unbounded_String (Command_Line (Row));
      State.Working_Directory := Row.Working_Label;
      Append_Output_Line (State, "$ " & Command_Line (Row));
      Append_Output_Text (State, Result.Stdout_Text);
      Append_Output_Text (State, Result.Stderr_Text);
      Refresh_Selection (State);
   end Apply_Result;

   procedure Run_Selected_With_Result
     (State  : in out Terminal_Task_State;
      Result : Editor.External_Producers.Process_Run_Result)
   is
   begin
      if Has_Selected_Task (State) then
         Apply_Result (State, State.Selected_Index, Result);
      end if;
   end Run_Selected_With_Result;

   procedure Rerun_Last_With_Result
     (State  : in out Terminal_Task_State;
      Result : Editor.External_Producers.Process_Run_Result)
   is
      Index : constant Natural := Index_For_Id (State, State.Last_Run_Id);
   begin
      if State.Has_Last_Run and then Index /= 0 then
         Apply_Result (State, Index, Result);
      end if;
   end Rerun_Last_With_Result;

   function Has_Selected_Task (State : Terminal_Task_State) return Boolean is
   begin
      return not State.Rows.Is_Empty
        and then State.Selected_Index >= State.Rows.First_Index
        and then State.Selected_Index <= State.Rows.Last_Index;
   end Has_Selected_Task;

   function Can_Rerun_Last (State : Terminal_Task_State) return Boolean is
   begin
      return State.Has_Last_Run
        and then Index_For_Id (State, State.Last_Run_Id) /= 0;
   end Can_Rerun_Last;

   function Request_For_Row
     (Row : Terminal_Task_Row)
      return Editor.External_Producers.Process_Run_Request
   is
      Request : Editor.External_Producers.Process_Run_Request;
   begin
      Request.Program_Label := Row.Program_Label;
      Request.Working_Label := Row.Working_Label;
      for Arg of Row.Arguments loop
         Editor.External_Producers.Append_Process_Argument
           (Request.Structured_Arguments, To_String (Arg));
      end loop;
      return Request;
   end Request_For_Row;

   function Selected_Task_Request
     (State : Terminal_Task_State)
      return Editor.External_Producers.Process_Run_Request
   is
   begin
      if Has_Selected_Task (State) then
         return Request_For_Row (State.Rows (State.Selected_Index));
      end if;
      return (others => <>);
   end Selected_Task_Request;

   function Last_Task_Request
     (State : Terminal_Task_State)
      return Editor.External_Producers.Process_Run_Request
   is
      Index : constant Natural := Index_For_Id (State, State.Last_Run_Id);
   begin
      if State.Has_Last_Run and then Index /= 0 then
         return Request_For_Row (State.Rows (Index));
      end if;
      return (others => <>);
   end Last_Task_Request;

   function Build_Render_Snapshot
     (State : Terminal_Task_State) return Terminal_Task_Render_Snapshot
   is
      Snapshot : Terminal_Task_Render_Snapshot;
   begin
      Snapshot.Visible := State.Visible;
      Snapshot.Focused := State.Focused;
      Snapshot.Row_Count := Natural (State.Rows.Length);
      Snapshot.Selected_Index := State.Selected_Index;
      Snapshot.Has_Selected := Has_Selected_Task (State);
      Snapshot.Can_Run_Selected := Snapshot.Has_Selected;
      Snapshot.Can_Rerun_Last := Can_Rerun_Last (State);
      Snapshot.Can_Clear := Snapshot.Row_Count > 0
        or else Natural (State.Output_Rows.Length) > 0;
      Snapshot.Can_Cancel := False;
      Snapshot.Rows := State.Rows;
      Snapshot.Output_Row_Count := Natural (State.Output_Rows.Length);
      Snapshot.Output_Rows := State.Output_Rows;
      Snapshot.Status_Label := State.Status_Label;
      Snapshot.Active_Command_Line := State.Active_Command_Line;
      Snapshot.Working_Directory := State.Working_Directory;
      return Snapshot;
   end Build_Render_Snapshot;

end Editor.Terminal_Tasks;
