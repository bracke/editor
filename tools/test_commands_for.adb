with Ada.Command_Line;
with Ada.Text_IO;
with GNAT.OS_Lib;
with Editor_Tool_Common; use Editor_Tool_Common;
with Test_Slice_Rules;

procedure Test_Commands_For is
   use type Test_Slice_Rules.Changed_File_Filter_Category;

   Max_Slices : constant Positive := 12;
   Max_Commands : constant Positive := 16;
   type Slice_List is array (Positive range 1 .. Max_Slices) of
     String (1 .. Test_Slice_Rules.Max_Slice_Length);
   type Command_List is array (Positive range 1 .. Max_Commands) of
     String (1 .. 80);
   Slices : Slice_List := (others => (others => ' '));
   Count  : Natural := 0;
   Commands : Command_List := (others => (others => ' '));
   Command_Count : Natural := 0;
   Explain : Boolean := False;
   First_Path_Arg : Positive := 1;
   Read_Stdin : Boolean := False;
   Read_Changed : Boolean := False;
   Ignored_Archive_Count : Natural := 0;
   Ignored_Generated_Count : Natural := 0;
   Ignored_Empty_Count : Natural := 0;
   Diff_Output : constant String := "/tmp/editor_test_commands_for_changed.txt";

   function Pad (Slice : String) return String is
      Result : String (1 .. Test_Slice_Rules.Max_Slice_Length) := (others => ' ');
   begin
      Result (1 .. Slice'Length) := Slice;
      return Result;
   end Pad;

   function Trim (Slice : String) return String is
      Last : Natural := Slice'Last;
   begin
      while Last >= Slice'First and then Slice (Last) = ' ' loop
         exit when Last = Slice'First;
         Last := Last - 1;
      end loop;
      return Slice (Slice'First .. Last);
   end Trim;

   procedure Add_Slice (Slice : String) is
      Padded : constant String := Pad (Slice);
   begin
      for I in 1 .. Count loop
         if Slices (I) = Padded then
            return;
         end if;
      end loop;

      Count := Count + 1;
      Slices (Count) := Padded;
   end Add_Slice;

   function Pad_Command (Command : String) return String is
      Result : String (1 .. 80) := (others => ' ');
   begin
      Result (1 .. Command'Length) := Command;
      return Result;
   end Pad_Command;

   function Trim_Command (Command : String) return String is
      Last : Natural := Command'Last;
   begin
      while Last >= Command'First and then Command (Last) = ' ' loop
         exit when Last = Command'First;
         Last := Last - 1;
      end loop;
      return Command (Command'First .. Last);
   end Trim_Command;

   function Image (Value : Natural) return String is
      Raw : constant String := Natural'Image (Value);
   begin
      return Raw (Raw'First + 1 .. Raw'Last);
   end Image;

   function Contains (Text, Needle : String) return Boolean is
   begin
      if Needle'Length = 0 or else Text'Length < Needle'Length then
         return False;
      end if;

      for I in Text'First .. Text'Last - Needle'Length + 1 loop
         if Text (I .. I + Needle'Length - 1) = Needle then
            return True;
         end if;
      end loop;
      return False;
   end Contains;

   procedure Add_Command (Command : String) is
   begin
      if Command'Length = 0 then
         return;
      end if;

      declare
         Padded : constant String := Pad_Command (Command);
      begin

         for I in 1 .. Command_Count loop
            if Commands (I) = Padded then
               return;
            end if;
         end loop;

         Command_Count := Command_Count + 1;
         Commands (Command_Count) := Padded;
      end;
   end Add_Command;

   procedure Add_Path (Path : String) is
      Category : constant Test_Slice_Rules.Changed_File_Filter_Category :=
        Test_Slice_Rules.Changed_File_Category (Path);
   begin
      case Category is
         when Test_Slice_Rules.Changed_File_Actionable =>
            null;
         when Test_Slice_Rules.Changed_File_Archive =>
            Ignored_Archive_Count := Ignored_Archive_Count + 1;
            return;
         when Test_Slice_Rules.Changed_File_Generated =>
            Ignored_Generated_Count := Ignored_Generated_Count + 1;
            return;
         when Test_Slice_Rules.Changed_File_Empty =>
            Ignored_Empty_Count := Ignored_Empty_Count + 1;
            return;
      end case;

      if not Test_Slice_Rules.Is_Actionable_Changed_File (Path) then
         return;
      end if;

      Add_Slice (Test_Slice_Rules.Slice_For (Path));
      declare
         Companion : constant String :=
           Test_Slice_Rules.Companion_Slice_For (Path);
         Additional_Companion : constant String :=
           Test_Slice_Rules.Additional_Companion_Slice_For (Path);
      begin
         if Companion'Length > 0 then
            Add_Slice (Companion);
         end if;
         if Additional_Companion'Length > 0 then
            Add_Slice (Additional_Companion);
         end if;
      end;
      if Contains (Path, "editor-executor-test_support") then
         Add_Slice ("executor-navigation");
         Add_Slice ("executor-buffer-switcher");
         Add_Slice ("executor-buffer-prune");
         Add_Slice ("executor-lifecycle");
      end if;
      Add_Command (Test_Slice_Rules.Product_Smoke_Command_For (Path));
      Add_Command (Test_Slice_Rules.Workflow_Gate_Command_For (Path));
   end Add_Path;

   procedure Add_Paths_From_Text (Raw : String) is
      Start : Positive := Raw'First;
      Stop  : Natural;
   begin
      if Raw'Length = 0 then
         return;
      end if;

      while Start <= Raw'Last loop
         Stop := Start;
         while Stop <= Raw'Last and then Raw (Stop) /= ASCII.LF loop
            Stop := Stop + 1;
         end loop;

         if Stop > Start then
            Add_Path (Raw (Start .. Stop - 1));
         end if;

         Start := Stop + 1;
      end loop;
   end Add_Paths_From_Text;
begin
   if Ada.Command_Line.Argument_Count = 0 then
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "usage: tools/bin/test_commands_for [--why] <changed-path> [<changed-path> ...]");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      return;
   end if;

   if Ada.Command_Line.Argument (1) = "--why" then
      Explain := True;
      First_Path_Arg := 2;
      if Ada.Command_Line.Argument_Count < 2 then
         Ada.Text_IO.Put_Line
           (Ada.Text_IO.Standard_Error,
            "usage: tools/bin/test_commands_for [--why] <changed-path> [<changed-path> ...]");
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
         return;
      end if;
   end if;

   for I in First_Path_Arg .. Ada.Command_Line.Argument_Count loop
      if Ada.Command_Line.Argument (I) = "-" then
         Read_Stdin := True;
      elsif Test_Slice_Rules.Is_Changed_File_Set_Argument
        (Ada.Command_Line.Argument (I))
      then
         Read_Changed := True;
      else
         Add_Path (Ada.Command_Line.Argument (I));
      end if;
   end loop;

   if Read_Stdin then
      while not Ada.Text_IO.End_Of_File loop
         Add_Path (Ada.Text_IO.Get_Line);
      end loop;
   end if;

   if Read_Changed then
      declare
         Args : GNAT.OS_Lib.Argument_List (1 .. 2) :=
           (new String'("diff"), new String'("--name-only"));
         Result : constant Captured_Command_Output :=
           Run_Capture_Bounded ("git", Args, Diff_Output);
      begin
         if Result.Exit_Code /= 0 then
            Fail ("test_commands_for", "git diff --name-only failed");
         end if;
         Add_Paths_From_Text (Output_Text (Result));
      end;
   end if;

   for I in 1 .. Count loop
      declare
         Command : constant String :=
           Test_Slice_Rules.Unit_Test_Command (Trim (Slices (I)));
      begin
         if Command'Length > 0 then
            Ada.Text_IO.Put_Line (Command);
         end if;
      end;
   end loop;

   for I in 1 .. Command_Count loop
      Ada.Text_IO.Put_Line (Trim_Command (Commands (I)));
   end loop;

   if Explain then
      Ada.Text_IO.Put_Line ("# run next:");
      for I in 1 .. Count loop
         declare
            Command : constant String :=
              Test_Slice_Rules.Unit_Test_Command (Trim (Slices (I)));
         begin
            if Command'Length > 0 then
               Ada.Text_IO.Put_Line
                 (Test_Slice_Rules.Run_Next_Command_Line (Command));
            end if;
         end;
      end loop;
      for I in 1 .. Command_Count loop
         Ada.Text_IO.Put_Line
           (Test_Slice_Rules.Run_Next_Command_Line
              (Trim_Command (Commands (I))));
      end loop;
      if Count > 1 or else Command_Count > 1 then
         Ada.Text_IO.Put_Line
           ("# recommended: tools/bin/editor_workflow_gate --quick for cross-area workflow coverage");
      end if;
      if Ignored_Archive_Count > 0
        or else Ignored_Generated_Count > 0
        or else Ignored_Empty_Count > 0
      then
         Ada.Text_IO.Put_Line
           ("# ignored changed paths: archive="
            & Image (Ignored_Archive_Count)
            & ", generated="
            & Image (Ignored_Generated_Count)
            & ", empty="
            & Image (Ignored_Empty_Count));
      end if;

      for I in First_Path_Arg .. Ada.Command_Line.Argument_Count loop
         if Ada.Command_Line.Argument (I) = "-" then
            Ada.Text_IO.Put_Line
              ("# why stdin: paths read from standard input and grouped above");
         elsif Test_Slice_Rules.Is_Changed_File_Set_Argument
           (Ada.Command_Line.Argument (I))
         then
            Ada.Text_IO.Put_Line
              ("# why --changed: paths read from git diff --name-only and grouped above");
         else
         declare
            Path : constant String := Ada.Command_Line.Argument (I);
            Category : constant Test_Slice_Rules.Changed_File_Filter_Category :=
              Test_Slice_Rules.Changed_File_Category (Path);
            Slice : constant String := Test_Slice_Rules.Slice_For (Path);
            Companion : constant String :=
              Test_Slice_Rules.Companion_Slice_For (Path);
            Additional_Companion : constant String :=
              Test_Slice_Rules.Additional_Companion_Slice_For (Path);
            Extra_Executor_Support : constant Boolean :=
              Contains (Path, "editor-executor-test_support");
            Unit_Command : constant String := Test_Slice_Rules.Unit_Test_Command (Slice);
            Smoke_Command : constant String :=
              Test_Slice_Rules.Product_Smoke_Command_For (Path);
            Gate_Command : constant String :=
              Test_Slice_Rules.Workflow_Gate_Command_For (Path);
         begin
            if Category /= Test_Slice_Rules.Changed_File_Actionable then
               Ada.Text_IO.Put_Line
                 ("# why " & Path & ": ignored="
                  & (case Category is
                     when Test_Slice_Rules.Changed_File_Archive => "archive",
                     when Test_Slice_Rules.Changed_File_Generated => "generated",
                     when Test_Slice_Rules.Changed_File_Empty => "empty",
                     when Test_Slice_Rules.Changed_File_Actionable => "none"));
            else
               Ada.Text_IO.Put_Line
                 ("# why " & Path & ": slice=" & Slice
                  & (if Companion'Length > 0
                     then ", companion=" & Companion
                     else ", companion=none")
                  & (if Additional_Companion'Length > 0
                     then ", additional=" & Additional_Companion
                     else ", additional=none")
                  & (if Extra_Executor_Support
                     then ", extra=executor-navigation,executor-buffer-switcher,"
                       & "executor-buffer-prune,executor-lifecycle"
                     else ", extra=none")
                  & (if Unit_Command'Length > 0
                     then ", unit=" & Unit_Command
                     else ", unit=none")
                  & (if Smoke_Command'Length > 0
                     then ", smoke=" & Smoke_Command
                     else ", smoke=none")
                  & (if Gate_Command'Length > 0
                     then ", gate=" & Gate_Command
                     else ", gate=none"));
            end if;
         end;
         end if;
      end loop;
   end if;
end Test_Commands_For;
