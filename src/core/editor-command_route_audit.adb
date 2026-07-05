with Ada.Characters.Handling;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Keybindings;

package body Editor.Command_Route_Audit is

   use type Editor.Keybindings.Keybinding_Validation_Status;

   procedure Clear
     (Result : in out Route_Audit_Result)
   is
   begin
      Result.Routes := 0;
      Result.Failures := 0;
      Result.Last_Source := Route_From_Test;
      Result.Last_Kind := Route_Custom_Failure;
      Result.Last_Expected := Editor.Commands.No_Command;
      Result.Last_Actual := Editor.Commands.No_Command;
      Result.Last_Message := Null_Unbounded_String;
      Result.Failure_Log := Null_Unbounded_String;
   end Clear;

   procedure Record_Route
     (Result  : in out Route_Audit_Result;
      Source  : Route_Source;
      Command : Editor.Commands.Command_Id)
   is
   begin
      Result.Routes := Result.Routes + 1;
      if not Editor.Commands.Is_Concrete_Command (Command) then
         Record_Route_Failure
           (Result   => Result,
            Source   => Source,
            Kind     => Route_Targeted_Non_Concrete_Command,
            Expected => Editor.Commands.No_Command,
            Actual   => Command,
            Message  => "route target is not a concrete command");
      end if;
   end Record_Route;

   procedure Record_Command_Palette_Route
     (Result                   : in out Route_Audit_Result;
      Command                  : Editor.Commands.Command_Id;
      Routed_Through_Executor  : Boolean;
      Used_Stable_Command_Name : Boolean;
      Carried_Payload          : Boolean)
   is
   begin
      Record_Route (Result, Route_From_Command_Palette, Command);

      if not Routed_Through_Executor then
         Record_Route_Failure
           (Result  => Result,
            Source  => Route_From_Command_Palette,
            Kind    => Route_Bypassed_Executor,
            Actual  => Command,
            Message => "command palette route did not use Executor");
      end if;

      if not Used_Stable_Command_Name then
         Record_Route_Failure
           (Result  => Result,
            Source  => Route_From_Command_Palette,
            Kind    => Route_Selected_By_Display_Label,
            Actual  => Command,
            Message => "command palette route did not use stable command identity");
      end if;

      if Carried_Payload then
         Record_Route_Failure
           (Result  => Result,
            Source  => Route_From_Command_Palette,
            Kind    => Route_Carried_Command_Payload,
            Actual  => Command,
            Message => "command palette route carried a row-specific payload");
      end if;
   end Record_Command_Palette_Route;


   procedure Record_Keybinding_Management_Route
     (Result                   : in out Route_Audit_Result;
      Command                  : Editor.Commands.Command_Id;
      Routed_Through_Executor  : Boolean;
      Used_Stable_Command_Name : Boolean;
      Carried_Payload          : Boolean)
   is
   begin
      Record_Route (Result, Route_From_Keybinding, Command);

      if not Routed_Through_Executor then
         Record_Route_Failure
           (Result  => Result,
            Source  => Route_From_Keybinding,
            Kind    => Route_Bypassed_Executor,
            Actual  => Command,
            Message => "keybinding management route did not use Executor");
      end if;

      if not Used_Stable_Command_Name then
         Record_Route_Failure
           (Result  => Result,
            Source  => Route_From_Keybinding,
            Kind    => Route_Selected_By_Display_Label,
            Actual  => Command,
            Message => "keybinding management route did not use stable command identity");
      end if;

      if Carried_Payload then
         Record_Route_Failure
           (Result  => Result,
            Source  => Route_From_Keybinding,
            Kind    => Route_Carried_Command_Payload,
            Actual  => Command,
            Message => "keybinding management route carried chord or row payload");
      end if;
   end Record_Keybinding_Management_Route;


   procedure Record_Suggested_Action_Route
     (Result                               : in out Route_Audit_Result;
      Command                              : Editor.Commands.Command_Id;
      Routed_Through_Executor              : Boolean;
      Used_Stable_Command_Name             : Boolean;
      Availability_Checked                 : Boolean;
      Carried_Payload                      : Boolean;
      Routed_Through_Command_Palette_Entry : Boolean := False)
   is
   begin
      Record_Route (Result, Route_From_Suggested_Action, Command);

      if not Routed_Through_Executor
        and then not Routed_Through_Command_Palette_Entry
      then
         Record_Route_Failure
           (Result  => Result,
            Source  => Route_From_Suggested_Action,
            Kind    => Route_Bypassed_Executor,
            Actual  => Command,
            Message => "suggested action route did not use Executor or the canonical Command Palette entry point");
      elsif Routed_Through_Executor
        and then Routed_Through_Command_Palette_Entry
      then
         Record_Route_Failure
           (Result  => Result,
            Source  => Route_From_Suggested_Action,
            Kind    => Route_Custom_Failure,
            Actual  => Command,
            Message => "suggested action route mixed direct Executor dispatch with Command Palette entry routing");
      end if;

      if not Used_Stable_Command_Name then
         Record_Route_Failure
           (Result  => Result,
            Source  => Route_From_Suggested_Action,
            Kind    => Route_Selected_By_Display_Label,
            Actual  => Command,
            Message => "suggested action route did not use stable command identity");
      end if;

      if not Availability_Checked then
         Record_Route_Failure
           (Result  => Result,
            Source  => Route_From_Suggested_Action,
            Kind    => Route_Bypassed_Availability,
            Actual  => Command,
            Message => "suggested action route did not observe availability before activation");
      end if;

      if Carried_Payload then
         Record_Route_Failure
           (Result  => Result,
            Source  => Route_From_Suggested_Action,
            Kind    => Route_Carried_Command_Payload,
            Actual  => Command,
            Message => "suggested action route carried file/project/result/candidate payload data");
      end if;
   end Record_Suggested_Action_Route;

   procedure Record_Buffer_Workflow_Route
     (Result                  : in out Route_Audit_Result;
      Source                  : Route_Source;
      Command                 : Editor.Commands.Command_Id;
      Routed_Through_Executor : Boolean;
      Availability_Checked    : Boolean;
      Carried_Buffer_Payload  : Boolean)
   is
   begin
      Record_Route (Result, Source, Command);

      if not Routed_Through_Executor then
         Record_Route_Failure
           (Result  => Result,
            Source  => Source,
            Kind    => Route_Bypassed_Executor,
            Actual  => Command,
            Message => "buffer workflow route did not use Executor");
      end if;

      if not Availability_Checked then
         Record_Route_Failure
           (Result  => Result,
            Source  => Source,
            Kind    => Route_Bypassed_Availability,
            Actual  => Command,
            Message => "buffer workflow route did not observe availability");
      end if;

      if Carried_Buffer_Payload then
         Record_Route_Failure
           (Result  => Result,
            Source  => Source,
            Kind    => Route_Carried_Command_Payload,
            Actual  => Command,
            Message => "buffer workflow route carried a runtime buffer id payload");
      end if;
   end Record_Buffer_Workflow_Route;

   procedure Record_Command_UI_Route
     (Result                   : in out Route_Audit_Result;
      Source                   : Route_Source;
      Command                  : Editor.Commands.Command_Id;
      Dispatch_Count           : Natural;
      Routed_Through_Executor  : Boolean;
      Used_Stable_Command_Name : Boolean;
      Availability_Checked     : Boolean;
      Carried_Payload          : Boolean)
   is
   begin
      Record_Route (Result, Source, Command);

      if Dispatch_Count = 0 then
         Record_Route_Failure
           (Result  => Result,
            Source  => Source,
            Kind    => Route_Bypassed_Executor,
            Actual  => Command,
            Message => "command-like UI route did not dispatch a command");
      elsif Dispatch_Count > 1 then
         Record_Route_Failure
           (Result  => Result,
            Source  => Source,
            Kind    => Route_Dispatched_More_Than_Once,
            Actual  => Command,
            Message => "command-like UI route dispatched more than once");
      end if;

      if not Routed_Through_Executor then
         Record_Route_Failure
           (Result  => Result,
            Source  => Source,
            Kind    => Route_Bypassed_Executor,
            Actual  => Command,
            Message => "command-like UI route did not use Executor");
      end if;

      if not Used_Stable_Command_Name then
         Record_Route_Failure
           (Result  => Result,
            Source  => Source,
            Kind    => Route_Selected_By_Display_Label,
            Actual  => Command,
            Message => "command-like UI route did not use stable command identity");
      end if;

      if not Availability_Checked then
         Record_Route_Failure
           (Result  => Result,
            Source  => Source,
            Kind    => Route_Bypassed_Availability,
            Actual  => Command,
            Message => "command-like UI route did not observe availability");
      end if;

      if Carried_Payload then
         Record_Route_Failure
           (Result  => Result,
            Source  => Source,
            Kind    => Route_Carried_Command_Payload,
            Actual  => Command,
            Message => "command-like UI route carried row/path/result payload data");
      end if;
   end Record_Command_UI_Route;


   function Lowercase (Text : String) return String
   is
      Result : String (Text'Range);
   begin
      for I in Text'Range loop
         Result (I) := Ada.Characters.Handling.To_Lower (Text (I));
      end loop;
      return Result;
   end Lowercase;

   function Contains (Haystack : String; Needle : String) return Boolean
   is
   begin
      return Ada.Strings.Fixed.Index (Haystack, Needle) /= 0;
   end Contains;

   function Structural_Route_Text_Contains_Runtime_Buffer_Payload
     (Text : String) return Boolean;

   function Text_Contains_Runtime_Buffer_Payload
     (Text : String) return Boolean
   is
   begin
      return Structural_Route_Text_Contains_Runtime_Buffer_Payload (Text);
   end Text_Contains_Runtime_Buffer_Payload;


   function Structural_Route_Text_Contains_Runtime_Buffer_Payload
     (Text : String) return Boolean
   is
      function Canonical_Field_Name (Raw : String) return String is
         use Ada.Characters.Handling;
         Trimmed : constant String := Ada.Strings.Fixed.Trim (Raw, Ada.Strings.Both);
         Result  : String (Trimmed'Range);
      begin
         for I in Trimmed'Range loop
            if Trimmed (I) = '_' or else Trimmed (I) = ' ' then
               Result (I) := '-';
            else
               Result (I) := To_Lower (Trimmed (I));
            end if;
         end loop;
         return Result;
      end Canonical_Field_Name;

      function Field_Name_Of (Segment : String) return String is
         Eq : constant Natural := Ada.Strings.Fixed.Index (Segment, "=");
      begin
         if Eq = 0 then
            return "";
         elsif Eq = Segment'First then
            return "";
         else
            return Canonical_Field_Name (Segment (Segment'First .. Eq - 1));
         end if;
      end Field_Name_Of;

      function Forbidden_Field_Name (Name : String) return Boolean is
      begin
         return Name = "runtime-buffer-id"
           or else Name = "buffer-runtime-id"
           or else Name = "buffer-id"
           or else Name = "row-buffer-id"
           or else Name = "payload-buffer"
           or else Name = "payload-buffer-id"
           or else Name = "active-buffer-id"
           or else Name = "active-runtime-buffer-id"
           or else Name = "selected-buffer-id"
           or else Name = "selected-runtime-buffer-id"
           or else Name = "buffer-list"
           or else Name = "buffer-list-selection"
           or else Name = "buffer-list-selected"
           or else Name = "buffer-list-filter"
           or else Name = "buffer-list-row"
           or else Name = "buffer-list-state"
           or else Name = "selected-row"
           or else Name = "selected-buffer-row"
           or else Name = "file-conflict-token"
           or else Name = "conflict-token"
           or else Name = "observed-file-token"
           or else Name = "observed-file-status-code"
           or else Name = "dirty-close-prompt-buffer-ids"
           or else Name = "pending-close-buffer-ids";
      end Forbidden_Field_Name;

      function Segment_Has_Forbidden_Field (Segment : String) return Boolean is
         Name : constant String := Field_Name_Of (Segment);
      begin
         return Name'Length > 0 and then Forbidden_Field_Name (Name);
      end Segment_Has_Forbidden_Field;

      function Line_Has_Forbidden_Field (Line : String) return Boolean is
         Pos  : Natural := Line'First;
         Next : Natural;
      begin
         if Line'Length = 0 then
            return False;
         end if;

         if Line (Line'First) = '[' and then Line (Line'Last) = ']' then
            return Forbidden_Field_Name
              (Canonical_Field_Name (Line (Line'First + 1 .. Line'Last - 1)));
         end if;

         while Pos <= Line'Last loop
            Next := Ada.Strings.Fixed.Index (Line (Pos .. Line'Last), "|");
            if Next = 0 then
               return Segment_Has_Forbidden_Field (Line (Pos .. Line'Last));
            else
               if Next > Pos
                 and then Segment_Has_Forbidden_Field (Line (Pos .. Next - 1))
               then
                  return True;
               end if;
               Pos := Next + 1;
            end if;
         end loop;

         return False;
      end Line_Has_Forbidden_Field;

      Pos : Natural := Text'First;
      LF  : Natural;
   begin
      while Pos <= Text'Last loop
         LF := Ada.Strings.Fixed.Index
           (Text (Pos .. Text'Last), (1 => Character'Val (10)));
         if LF = 0 then
            return Line_Has_Forbidden_Field (Text (Pos .. Text'Last));
         elsif Line_Has_Forbidden_Field (Text (Pos .. LF - 1)) then
            return True;
         else
            Pos := LF + 1;
         end if;
      end loop;

      return False;
   end Structural_Route_Text_Contains_Runtime_Buffer_Payload;


   procedure Reject_If_Buffer_Payload_Text
     (Result  : in out Route_Audit_Result;
      Source  : Route_Source;
      Command : Editor.Commands.Command_Id;
      Text    : String;
      Context : String)
   is
   begin
      if Structural_Route_Text_Contains_Runtime_Buffer_Payload (Text) then
         Record_Route_Failure
           (Result  => Result,
            Source  => Source,
            Kind    => Route_Carried_Command_Payload,
            Actual  => Command,
            Message => Context & " contains a forbidden runtime buffer identity field");
      end if;
   end Reject_If_Buffer_Payload_Text;

   procedure Inspect_Command_Descriptor_No_Buffer_Payload
     (Result     : in out Route_Audit_Result;
      Source     : Route_Source;
      Descriptor : Editor.Commands.Command_Descriptor)
   is
      Stable_Name : constant String :=
        (if Editor.Commands.Is_Concrete_Command (Descriptor.Id)
         then Editor.Commands.Stable_Command_Name (Descriptor.Id)
         else "");
   begin
      Record_Route (Result, Source, Descriptor.Id);
      Reject_If_Buffer_Payload_Text
        (Result, Source, Descriptor.Id, Stable_Name, "command stable name");
      Reject_If_Buffer_Payload_Text
        (Result, Source, Descriptor.Id, To_String (Descriptor.Name),
         "command label");
      Reject_If_Buffer_Payload_Text
        (Result, Source, Descriptor.Id, To_String (Descriptor.Target_Prompt_Label),
         "command prompt label");
      Reject_If_Buffer_Payload_Text
        (Result, Source, Descriptor.Id, To_String (Descriptor.Summary),
         "command summary");
      Reject_If_Buffer_Payload_Text
        (Result, Source, Descriptor.Id, To_String (Descriptor.Mutation_Summary),
         "command mutation summary");
      if Descriptor.Requires_Explicit_Target
        and then Structural_Route_Text_Contains_Runtime_Buffer_Payload
          (To_String (Descriptor.Target_Prompt_Label))
      then
         Record_Route_Failure
           (Result  => Result,
            Source  => Source,
            Kind    => Route_Carried_Command_Payload,
            Actual  => Descriptor.Id,
            Message => "explicit-target command prompt names runtime buffer identity");
      end if;
   end Inspect_Command_Descriptor_No_Buffer_Payload;

   procedure Inspect_Command_Palette_Row_No_Buffer_Payload
     (Result : in out Route_Audit_Result;
      Row    : Editor.Command_Palette.Command_Palette_Row)
   is
   begin
      Reject_If_Buffer_Payload_Text
        (Result, Route_From_Command_Palette, Editor.Commands.No_Command,
         To_String (Row.Primary_Text), "command palette primary text");
      Reject_If_Buffer_Payload_Text
        (Result, Route_From_Command_Palette, Editor.Commands.No_Command,
         To_String (Row.Secondary_Text), "command palette secondary text");
      Reject_If_Buffer_Payload_Text
        (Result, Route_From_Command_Palette, Editor.Commands.No_Command,
         To_String (Row.Keybinding_Text), "command palette keybinding text");
   end Inspect_Command_Palette_Row_No_Buffer_Payload;

   procedure Inspect_Command_Palette_Snapshot_No_Buffer_Payload
     (Result   : in out Route_Audit_Result;
      Snapshot : Editor.Command_Palette.Command_Palette_Snapshot)
   is
      Found           : Boolean := False;
      Candidate_Index : Natural := 0;
      Candidate       : Editor.Commands.Command_Palette_Candidate;
   begin
      for I in 1 .. Editor.Command_Palette.Row_Count (Snapshot) loop
         Inspect_Command_Palette_Row_No_Buffer_Payload
           (Result, Editor.Command_Palette.Row (Snapshot, I));
         Candidate_Index :=
           Editor.Command_Palette.Candidate_For_Row (Snapshot, I, Found);
         if Found then
            Candidate := Editor.Command_Palette.Candidate (Snapshot, Candidate_Index);
            Record_Route (Result, Route_From_Command_Palette, Candidate.Id);
            if Editor.Commands.Is_Concrete_Command (Candidate.Id) then
               Reject_If_Buffer_Payload_Text
                 (Result, Route_From_Command_Palette, Candidate.Id,
                  Editor.Commands.Stable_Command_Name (Candidate.Id),
                  "command palette candidate stable name");
            end if;
            Reject_If_Buffer_Payload_Text
              (Result, Route_From_Command_Palette, Candidate.Id,
               To_String (Candidate.Label), "command palette candidate label");
            Reject_If_Buffer_Payload_Text
              (Result, Route_From_Command_Palette, Candidate.Id,
               To_String (Candidate.Keybinding_Display),
               "command palette candidate keybinding");
         end if;
      end loop;
   end Inspect_Command_Palette_Snapshot_No_Buffer_Payload;

   procedure Inspect_Keybinding_Table_No_Buffer_Payload
     (Result : in out Route_Audit_Result)
   is
      Validation : constant Editor.Keybindings.Keybinding_Validation_Result :=
        Editor.Keybindings.Validate;
      Command    : Editor.Commands.Command_Id;
      Binding    : Editor.Keybindings.Key_Chord;
   begin
      if Editor.Keybindings.Status (Validation)
        /= Editor.Keybindings.Valid_Keybindings
      then
         Record_Route_Failure
           (Result  => Result,
            Source  => Route_From_Keybinding,
            Kind    => Route_Used_Stale_Keybinding_Table,
            Message => "keybinding table validation failed before buffer payload audit");
      end if;

      for I in 1 .. Editor.Keybindings.Bound_Command_Count loop
         Command := Editor.Keybindings.Bound_Command_At (I);
         Record_Route (Result, Route_From_Keybinding, Command);
         if Editor.Commands.Is_Concrete_Command (Command) then
            Reject_If_Buffer_Payload_Text
              (Result, Route_From_Keybinding, Command,
               Editor.Commands.Stable_Command_Name (Command),
               "keybinding command stable name");
         end if;
         for J in 1 .. Editor.Keybindings.Binding_Count_For_Command (Command) loop
            Binding := Editor.Keybindings.Binding_For_Command (Command, J);
            Reject_If_Buffer_Payload_Text
              (Result, Route_From_Keybinding, Command,
               Editor.Keybindings.Format_Chord (Binding),
               "keybinding chord display");
         end loop;
      end loop;
   end Inspect_Keybinding_Table_No_Buffer_Payload;

   procedure Inspect_Buffer_Switcher_Row_No_Buffer_Payload
     (Result : in out Route_Audit_Result;
      Row    : Editor.Buffer_Switcher.Buffer_Switcher_Row)
   is
   begin
      Reject_If_Buffer_Payload_Text
        (Result, Route_From_Tab_Bar, Editor.Commands.No_Command,
         To_String (Row.Display_Label), "Buffer List display label");
      Reject_If_Buffer_Payload_Text
        (Result, Route_From_Tab_Bar, Editor.Commands.No_Command,
         To_String (Row.Path), "Buffer List path label");
      Reject_If_Buffer_Payload_Text
        (Result, Route_From_Tab_Bar, Editor.Commands.No_Command,
         To_String (Row.Project_Ownership_Label),
         "Buffer List ownership label");
      Reject_If_Buffer_Payload_Text
        (Result, Route_From_Tab_Bar, Editor.Commands.No_Command,
         To_String (Row.Group_Name), "Buffer List group label");
      Reject_If_Buffer_Payload_Text
        (Result, Route_From_Tab_Bar, Editor.Commands.No_Command,
         To_String (Row.Label_Text), "Buffer List custom label");
   end Inspect_Buffer_Switcher_Row_No_Buffer_Payload;

   procedure Inspect_Buffer_Switcher_State_No_Buffer_Payload
     (Result : in out Route_Audit_Result;
      State  : Editor.Buffer_Switcher.Buffer_Switcher_State)
   is
   begin
      for I in 1 .. Editor.Buffer_Switcher.Row_Count (State) loop
         Inspect_Buffer_Switcher_Row_No_Buffer_Payload
           (Result, Editor.Buffer_Switcher.Row_At (State, I));
      end loop;

      Record_Buffer_Workflow_Route
        (Result, Route_From_Tab_Bar,
         Editor.Commands.Command_Accept_Buffer_Switcher,
         Routed_Through_Executor => True,
         Availability_Checked    => True,
         Carried_Buffer_Payload  => False);
      Record_Buffer_Workflow_Route
        (Result, Route_From_Tab_Bar,
         Editor.Commands.Command_Buffer_Switcher_Selected_Close,
         Routed_Through_Executor => True,
         Availability_Checked    => True,
         Carried_Buffer_Payload  => False);
   end Inspect_Buffer_Switcher_State_No_Buffer_Payload;

   procedure Inspect_Serialized_Route_Text_No_Buffer_Payload
     (Result : in out Route_Audit_Result;
      Source : Route_Source;
      Text   : String)
   is
   begin
      if Structural_Route_Text_Contains_Runtime_Buffer_Payload (Text) then
         Record_Route_Failure
           (Result  => Result,
            Source  => Source,
            Kind    => Route_Carried_Command_Payload,
            Actual  => Editor.Commands.No_Command,
            Message => "serialized route text contains a forbidden runtime buffer identity field");
      end if;
   end Inspect_Serialized_Route_Text_No_Buffer_Payload;

   procedure Inspect_Buffer_Route_Surfaces_No_Buffer_Payload
     (Result                : in out Route_Audit_Result;
      Buffer_Switcher_State : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Serialized_Workspace  : String := "")
   is
      Command : Editor.Commands.Command_Id;
   begin
      for I in 1 .. Editor.Commands.Command_Count loop
         Command := Editor.Commands.Command_At (I);
         if Editor.Commands.Is_Concrete_Command (Command) then
            Inspect_Command_Descriptor_No_Buffer_Payload
              (Result, Route_From_Command_Palette,
               Editor.Commands.Descriptor (Command));
         end if;
      end loop;

      Inspect_Keybinding_Table_No_Buffer_Payload (Result);
      Inspect_Buffer_Switcher_State_No_Buffer_Payload
        (Result, Buffer_Switcher_State);
      Inspect_Serialized_Route_Text_No_Buffer_Payload
        (Result, Route_From_Test, Serialized_Workspace);
   end Inspect_Buffer_Route_Surfaces_No_Buffer_Payload;

   procedure Record_Failure
     (Result  : in out Route_Audit_Result;
      Source  : Route_Source;
      Message : String)
   is
   begin
      Record_Route_Failure
        (Result  => Result,
         Source  => Source,
         Kind    => Route_Custom_Failure,
         Message => Message);
   end Record_Failure;

   procedure Record_Route_Failure
     (Result   : in out Route_Audit_Result;
      Source   : Route_Source;
      Kind     : Route_Audit_Failure_Kind;
      Expected : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Actual   : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Message  : String := "")
   is
   begin
      Result.Failures := Result.Failures + 1;
      Result.Last_Source := Source;
      Result.Last_Kind := Kind;
      Result.Last_Expected := Expected;
      Result.Last_Actual := Actual;
      Result.Last_Message := To_Unbounded_String (Message);
      if Length (Result.Failure_Log) = 0 then
         Append (Result.Failure_Log, "Feature route audit failed:");
      end if;
      Append (Result.Failure_Log, ASCII.LF & "  ");
      Append (Result.Failure_Log, Route_Source'Image (Source));
      Append (Result.Failure_Log, ":");
      Append (Result.Failure_Log, ASCII.LF & "    ");
      Append (Result.Failure_Log, Route_Audit_Failure_Kind'Image (Kind));
      Append (Result.Failure_Log, " expected=");
      Append (Result.Failure_Log, Editor.Commands.Command_Id'Image (Expected));
      Append (Result.Failure_Log, " actual=");
      Append (Result.Failure_Log, Editor.Commands.Command_Id'Image (Actual));
      if Message'Length > 0 then
         Append (Result.Failure_Log, ASCII.LF & "    ");
         Append (Result.Failure_Log, Message);
      end if;
   end Record_Route_Failure;

   function Failure_Count
     (Result : Route_Audit_Result) return Natural
   is
   begin
      return Result.Failures;
   end Failure_Count;

   function Last_Failure_Message
     (Result : Route_Audit_Result) return String
   is
      Text : Unbounded_String := Null_Unbounded_String;
   begin
      if Result.Failures = 0 then
         return "";
      end if;

      Append (Text, Route_Audit_Failure_Kind'Image (Result.Last_Kind));
      Append (Text, " source=");
      Append (Text, Route_Source'Image (Result.Last_Source));
      Append (Text, " expected=");
      Append (Text, Editor.Commands.Command_Id'Image (Result.Last_Expected));
      Append (Text, " actual=");
      Append (Text, Editor.Commands.Command_Id'Image (Result.Last_Actual));
      if Length (Result.Last_Message) > 0 then
         Append (Text, " message=");
         Append (Text, To_String (Result.Last_Message));
      end if;
      return To_String (Text);
   end Last_Failure_Message;

   function Summary
     (Result : Route_Audit_Result) return String
   is
      Text : Unbounded_String := Null_Unbounded_String;
   begin
      Append (Text, "routes=");
      Append (Text, Natural'Image (Result.Routes));
      Append (Text, "; failures=");
      Append (Text, Natural'Image (Result.Failures));
      if Result.Failures > 0 then
         Append (Text, "; last=");
         Append (Text, Last_Failure_Message (Result));
         Append (Text, ASCII.LF);
         Append (Text, To_String (Result.Failure_Log));
      end if;
      return To_String (Text);
   end Summary;

end Editor.Command_Route_Audit;
