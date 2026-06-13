with Ada.Strings.Fixed;
with Editor.Commands;
with Editor.Keybindings;
use type Editor.Commands.Command_Id;
package body Editor.Guided_Prompts is

   function Trimmed (S : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (S, Ada.Strings.Both);
   end Trimmed;

   function Contains_Path_Escape (S : String) return Boolean is
      Segment : Unbounded_String := Null_Unbounded_String;

      procedure Check_Segment (Found : in out Boolean) is
      begin
         if To_String (Segment) = ".." then
            Found := True;
         end if;
         Segment := Null_Unbounded_String;
      end Check_Segment;

      Found : Boolean := False;
   begin
      --  Phase 572 completeness: create prompts may accept explicit
      --  project-relative paths such as "src/new_unit.adb", but parent
      --  traversal must still be blocked by prompt validation for every
      --  segment, including trailing "src/.." forms.
      for Ch of S loop
         if Ch = '/' or else Ch = '\' then
            Check_Segment (Found);
            exit when Found;
         else
            Append (Segment, Ch);
         end if;
      end loop;
      if not Found then
         Check_Segment (Found);
      end if;
      return Found;
   end Contains_Path_Escape;

   function Contains_Current_Directory_Segment (S : String) return Boolean is
      Segment : Unbounded_String := Null_Unbounded_String;

      procedure Check_Segment (Found : in out Boolean) is
      begin
         if To_String (Segment) = "." then
            Found := True;
         end if;
         Segment := Null_Unbounded_String;
      end Check_Segment;

      Found : Boolean := False;
   begin
      for Ch of S loop
         if Ch = '/' or else Ch = '\' then
            Check_Segment (Found);
            exit when Found;
         else
            Append (Segment, Ch);
         end if;
      end loop;
      if not Found then
         Check_Segment (Found);
      end if;
      return Found;
   end Contains_Current_Directory_Segment;

   function Contains_Empty_Path_Segment (S : String) return Boolean is
      Previous_Was_Separator : Boolean := False;
      Saw_Separator          : Boolean := False;
   begin
      for Ch of S loop
         if Ch = '/' or else Ch = '\' then
            if Saw_Separator and then Previous_Was_Separator then
               return True;
            end if;
            Saw_Separator := True;
            Previous_Was_Separator := True;
         else
            Previous_Was_Separator := False;
         end if;
      end loop;
      return False;
   end Contains_Empty_Path_Segment;

   function Has_Trailing_Path_Separator (S : String) return Boolean is
   begin
      return S'Length > 0
        and then (S (S'Last) = '/' or else S (S'Last) = '\');
   end Has_Trailing_Path_Separator;

   function Contains_Path_Separator (S : String) return Boolean is
   begin
      return (for some I in S'Range => S (I) = '/' or else S (I) = '\');
   end Contains_Path_Separator;

   function Contains_Control_Character (S : String) return Boolean is
   begin
      return (for some I in S'Range => Character'Pos (S (I)) < 32
              or else Character'Pos (S (I)) = 127);
   end Contains_Control_Character;

   function Looks_Like_Drive_Qualified_Path (S : String) return Boolean is
      function Is_Ascii_Letter (Ch : Character) return Boolean is
      begin
         return (Ch >= 'A' and then Ch <= 'Z')
           or else (Ch >= 'a' and then Ch <= 'z');
      end Is_Ascii_Letter;
   begin
      return S'Length >= 2
        and then Is_Ascii_Letter (S (S'First))
        and then S (S'First + 1) = ':';
   end Looks_Like_Drive_Qualified_Path;

   function Looks_Like_Absolute_Path (S : String) return Boolean is
   begin
      return (S'Length >= 1 and then (S (S'First) = '/' or else S (S'First) = '\'))
        or else
          (S'Length >= 3
           and then S (S'First + 1) = ':'
           and then (S (S'First + 2) = '/' or else S (S'First + 2) = '\'));
   end Looks_Like_Absolute_Path;

   function Is_File_Tree_Name_Kind (Kind : Prompt_Kind) return Boolean is
     (Kind = File_Tree_Create_File_Prompt
      or else Kind = File_Tree_Create_Directory_Prompt
      or else Kind = File_Tree_Rename_Prompt);

   function File_Tree_Invalid_Syntax_Message (Kind : Prompt_Kind) return String is
   begin
      case Kind is
         when File_Tree_Create_File_Prompt =>
            return "Invalid file name";
         when File_Tree_Create_Directory_Prompt =>
            return "Invalid directory name";
         when File_Tree_Rename_Prompt =>
            return "Invalid rename target";
         when others =>
            return "Invalid File Tree target";
      end case;
   end File_Tree_Invalid_Syntax_Message;

   procedure Start
     (Prompt : in out Prompt_State;
      Kind : Prompt_Kind;
      Owning_Command : Editor.Commands.Command_Id;
      Title : String;
      Description : String;
      Target_Domain : String;
      Previous_Focus : String := "editor";
      Confirm_Label : String := "Confirm";
      Cancel_Label : String := "Cancel";
      Requires_Confirmation : Boolean := False;
      Destructive : Boolean := False;
      Lifecycle_Command : Boolean := False;
      Configuration_Command : Boolean := False;
      Affected_Count : Natural := 0) is
   begin
      Clear (Prompt);
      Prompt.Active := True;
      Prompt.Kind := Kind;
      Prompt.Lifecycle := Prompt_Started;
      Prompt.Title := To_Unbounded_String (Title);
      Prompt.Description := To_Unbounded_String (Description);
      Prompt.Owning_Command := Owning_Command;
      Prompt.Confirm_Label := To_Unbounded_String (Confirm_Label);
      Prompt.Cancel_Label := To_Unbounded_String (Cancel_Label);
      Prompt.Previous_Focus_Label := To_Unbounded_String (Previous_Focus);
      Prompt.Target_Domain_Label := To_Unbounded_String (Target_Domain);
      Prompt.Requires_Confirmation := Requires_Confirmation;
      Prompt.Destructive := Destructive;
      Prompt.Lifecycle_Command := Lifecycle_Command;
      Prompt.Configuration_Command := Configuration_Command;
      Prompt.Affected_Count := Affected_Count;
      Validate (Prompt);
   end Start;

   procedure Update_Input (Prompt : in out Prompt_State; Text : String) is
   begin
      if Prompt.Active then
         Editor.Input_Field.Set_Text (Prompt.Input, Text);
         Prompt.Lifecycle := Prompt_Editing;
         Validate (Prompt);
      end if;
   end Update_Input;

   procedure Insert_Text (Prompt : in out Prompt_State; Text : String) is
   begin
      if Prompt.Active then
         Editor.Input_Field.Insert_Text (Prompt.Input, Text);
         Prompt.Lifecycle := Prompt_Editing;
         Validate (Prompt);
      end if;
   end Insert_Text;

   procedure Backspace (Prompt : in out Prompt_State) is
   begin
      if Prompt.Active then
         Editor.Input_Field.Backspace (Prompt.Input);
         Prompt.Lifecycle := Prompt_Editing;
         Validate (Prompt);
      end if;
   end Backspace;

   procedure Delete_Forward (Prompt : in out Prompt_State) is
   begin
      if Prompt.Active then
         Editor.Input_Field.Delete_Forward (Prompt.Input);
         Prompt.Lifecycle := Prompt_Editing;
         Validate (Prompt);
      end if;
   end Delete_Forward;

   procedure Capture_Chord
     (Prompt : in out Prompt_State;
      Chord : Editor.Keybindings.Key_Chord) is
   begin
      if Prompt.Active and then Prompt.Kind = Keybinding_Capture_Prompt then
         Prompt.Captured_Chord := Chord;
         Prompt.Has_Captured_Chord := True;
         Prompt.Lifecycle := Prompt_Editing;
         Validate (Prompt);
      end if;
   end Capture_Chord;

   procedure Validate (Prompt : in out Prompt_State) is
      Text : constant String := Trimmed (Editor.Input_Field.Text (Prompt.Input));
   begin
      if not Prompt.Active then
         return;
      end if;

      Prompt.Lifecycle := Prompt_Validating;

      if Prompt.Kind = Confirmation_Prompt or else Prompt.Kind = Configuration_Reset_Prompt then
         Prompt.Validation := Validation_Requires_Confirmation;
         Prompt.Validation_Message := To_Unbounded_String ("Confirmation required");
         Prompt.Lifecycle := Prompt_Ready_To_Confirm;
      elsif Prompt.Kind = Keybinding_Capture_Prompt then
         if not Prompt.Has_Captured_Chord then
            Prompt.Validation := Validation_Empty_Input;
            Prompt.Validation_Message := To_Unbounded_String ("Capture one key chord");
            Prompt.Lifecycle := Prompt_Blocked;
         else
            Prompt.Validation := Validation_Ready;
            Prompt.Validation_Message := To_Unbounded_String ("Ready");
            Prompt.Lifecycle := Prompt_Ready_To_Confirm;
         end if;
      elsif Text = ""
        and then Is_File_Tree_Name_Kind (Prompt.Kind)
      then
         --  Phase 572 completeness: File Tree mutation prompts should use the
         --  operation-model validation language, not the generic guided
         --  prompt placeholder.  Empty create/rename input is a blocked File
         --  Tree target and must tell the user to enter a name while remaining
         --  side-effect-free and transient.
         Prompt.Validation := Validation_Empty_Input;
         Prompt.Validation_Message := To_Unbounded_String ("Enter a name.");
         Prompt.Lifecycle := Prompt_Blocked;
      elsif Text = ""
        and then Prompt.Kind /= Replace_Text_Prompt
        and then Prompt.Kind /= Workspace_Save_Prompt
      then
         Prompt.Validation := Validation_Empty_Input;
         Prompt.Validation_Message := To_Unbounded_String ("Prompt requires input");
         Prompt.Lifecycle := Prompt_Blocked;
      elsif Is_File_Tree_Name_Kind (Prompt.Kind)
        and then Looks_Like_Absolute_Path (Text)
      then
         Prompt.Validation := Validation_Outside_Project;
         --  Phase 572 completeness: absolute File Tree prompt text is not a
         --  raw filesystem payload.  Use the same project-relative wording as
         --  Executor-time validation for absolute paths that would otherwise
         --  be accepted by the host path parser, while remaining
         --  side-effect-free and without probing the active project root from
         --  prompt validation.
         Prompt.Validation_Message := To_Unbounded_String
           ("Target path must be project-relative");
         Prompt.Lifecycle := Prompt_Blocked;
      elsif Prompt.Kind = File_Tree_Rename_Prompt
        and then Contains_Path_Separator (Text)
      then
         --  Phase 572 completeness: rename is a leaf-name workflow even
         --  though create prompts accept project-relative paths.  Check this
         --  before the generic File Tree syntax bucket so path fragments get
         --  the rename-specific validation message shown by the prompt UI.
         Prompt.Validation := Validation_Invalid_Syntax;
         Prompt.Validation_Message := To_Unbounded_String
           ("Rename expects a single new name");
         Prompt.Lifecycle := Prompt_Blocked;
      elsif Is_File_Tree_Name_Kind (Prompt.Kind)
        and then
          (Contains_Path_Escape (Text)
           or else Looks_Like_Drive_Qualified_Path (Text)
           or else Contains_Current_Directory_Segment (Text)
           or else Contains_Empty_Path_Segment (Text)
           or else Has_Trailing_Path_Separator (Text)
           or else Contains_Control_Character (Text))
      then
         Prompt.Validation := Validation_Invalid_Syntax;
         --  Phase 572 completeness: prompt-time validation should use the
         --  same operation-specific malformed-name vocabulary as direct
         --  Executor validation.  Create-file, create-directory, and rename
         --  all share the same syntax bucket, but their user-facing outcome
         --  labels must not collapse to a generic File Tree target message.
         Prompt.Validation_Message := To_Unbounded_String
           (File_Tree_Invalid_Syntax_Message (Prompt.Kind));
         Prompt.Lifecycle := Prompt_Blocked;
      elsif (for some I in Text'Range => Text (I) = ASCII.NUL) then
         Prompt.Validation := Validation_Invalid_Syntax;
         Prompt.Validation_Message := To_Unbounded_String ("Invalid input syntax");
         Prompt.Lifecycle := Prompt_Blocked;
      else
         Prompt.Validation := Validation_Ready;
         Prompt.Validation_Message := To_Unbounded_String ("Ready");
         Prompt.Lifecycle := Prompt_Ready_To_Confirm;
      end if;
   end Validate;

   procedure Mark_Confirmed (Prompt : in out Prompt_State) is
   begin
      if Prompt.Active then
         Prompt.Lifecycle := Prompt_Confirmed;
      end if;
   end Mark_Confirmed;

   procedure Mark_Completed (Prompt : in out Prompt_State) is
   begin
      Prompt.Lifecycle := Prompt_Completed;
      Clear (Prompt);
   end Mark_Completed;

   procedure Mark_Failed (Prompt : in out Prompt_State; Reason : String) is
   begin
      if Prompt.Active then
         Prompt.Lifecycle := Prompt_Failed;
         Prompt.Validation := Validation_Target_Unavailable;
         Prompt.Validation_Message := To_Unbounded_String (Reason);
      end if;
   end Mark_Failed;

   procedure Cancel (Prompt : in out Prompt_State) is
   begin
      if Prompt.Active then
         Prompt.Lifecycle := Prompt_Cancelled;
      end if;
      Clear (Prompt);
   end Cancel;

   procedure Clear (Prompt : in out Prompt_State) is
   begin
      Prompt.Active := False;
      Prompt.Kind := No_Prompt;
      Prompt.Lifecycle := Prompt_Inactive;
      Prompt.Title := Null_Unbounded_String;
      Prompt.Description := Null_Unbounded_String;
      Prompt.Owning_Command := Editor.Commands.No_Command;
      Editor.Input_Field.Clear (Prompt.Input);
      Prompt.Has_Captured_Chord := False;
      Prompt.Validation := Validation_Empty_Input;
      Prompt.Validation_Message := To_Unbounded_String ("Prompt requires input");
      Prompt.Confirm_Label := To_Unbounded_String ("Confirm");
      Prompt.Cancel_Label := To_Unbounded_String ("Cancel");
      Prompt.Previous_Focus_Label := Null_Unbounded_String;
      Prompt.Target_Domain_Label := Null_Unbounded_String;
      Prompt.Requires_Confirmation := False;
      Prompt.Destructive := False;
      Prompt.Lifecycle_Command := False;
      Prompt.Configuration_Command := False;
      Prompt.Affected_Count := 0;
   end Clear;

   function Is_Active (Prompt : Prompt_State) return Boolean is (Prompt.Active);
   function Ready (Prompt : Prompt_State) return Boolean is
     (Prompt.Active and then
      (Prompt.Validation = Validation_Ready or else Prompt.Validation = Validation_Requires_Confirmation));
   function Input_Text (Prompt : Prompt_State) return String is
     (Editor.Input_Field.Text (Prompt.Input));

   function Has_Captured_Key_Chord (Prompt : Prompt_State) return Boolean is
     (Prompt.Active and then Prompt.Kind = Keybinding_Capture_Prompt
      and then Prompt.Has_Captured_Chord);

   function Captured_Key_Chord
     (Prompt : Prompt_State) return Editor.Keybindings.Key_Chord is
     (Prompt.Captured_Chord);

   function Validation_Label (State : Prompt_Validation_State) return String is
   begin
      case State is
         when Validation_Empty_Input => return "Prompt requires input";
         when Validation_Invalid_Syntax => return "Invalid syntax";
         when Validation_Target_Unavailable => return "Prompt target unavailable";
         when Validation_Target_Stale => return "Prompt target stale";
         when Validation_Outside_Project => return "Target outside project";
         when Validation_Requires_Confirmation => return "Confirmation required";
         when Validation_Ready => return "Ready";
      end case;
   end Validation_Label;

   function Kind_Label (Kind : Prompt_Kind) return String is
   begin
      case Kind is
         when No_Prompt => return "No prompt";
         when Project_Open_Prompt => return "Open Project";
         when Project_Switch_Prompt => return "Switch Project";
         when Workspace_Load_Prompt => return "Restore Workspace";
         when Workspace_Save_Prompt => return "Save Workspace";
         when Search_Query_Prompt => return "Search Project";
         when Replace_Text_Prompt => return "Replace Text";
         when Settings_Value_Prompt => return "Change Setting";
         when Keybinding_Capture_Prompt => return "Assign Keybinding";
         when File_Tree_Create_File_Prompt => return "Create File";
         when File_Tree_Create_Directory_Prompt => return "Create Directory";
         when File_Tree_Rename_Prompt => return "Rename File or Directory";
         when Confirmation_Prompt => return "Confirmation";
         when Configuration_Reset_Prompt => return "Reset Configuration";
      end case;
   end Kind_Label;

   function Snapshot (Prompt : Prompt_State) return Prompt_Snapshot is
      S : Prompt_Snapshot;
   begin
      S.Active := Prompt.Active;
      S.Kind := Prompt.Kind;
      S.Title := Prompt.Title;
      S.Description := Prompt.Description;
      S.Owning_Command_Name := To_Unbounded_String
        (Editor.Commands.Stable_Command_Name (Prompt.Owning_Command));
      S.Input_Text := To_Unbounded_String (Editor.Input_Field.Text (Prompt.Input));
      S.Has_Captured_Chord := Prompt.Has_Captured_Chord;
      S.Captured_Chord_Label := To_Unbounded_String
        (if Prompt.Has_Captured_Chord then Editor.Keybindings.Format_Chord (Prompt.Captured_Chord) else "");
      S.Validation := Prompt.Validation;
      S.Validation_Label := Prompt.Validation_Message;
      S.Confirm_Label := Prompt.Confirm_Label;
      S.Cancel_Label := Prompt.Cancel_Label;
      S.Target_Domain_Label := Prompt.Target_Domain_Label;
      S.Requires_Confirmation := Prompt.Requires_Confirmation;
      S.Destructive := Prompt.Destructive;
      S.Lifecycle_Command := Prompt.Lifecycle_Command;
      S.Configuration_Command := Prompt.Configuration_Command;
      S.Affected_Count := Prompt.Affected_Count;
      return S;
   end Snapshot;

   function Is_Confirmation (Prompt : Prompt_State) return Boolean is
     (Prompt.Active and then
      (Prompt.Kind = Confirmation_Prompt
       or else Prompt.Kind = Configuration_Reset_Prompt
       or else Prompt.Requires_Confirmation));

   function Is_File_Tree_Name_Prompt (Prompt : Prompt_State) return Boolean is
     (Prompt.Active and then
      (Prompt.Kind = File_Tree_Create_File_Prompt
       or else Prompt.Kind = File_Tree_Create_Directory_Prompt
       or else Prompt.Kind = File_Tree_Rename_Prompt));

   function Prompt_Validation_Is_Side_Effect_Free
     (Before : Prompt_State; After : Prompt_State) return Boolean is
   begin
      --  Validation may update only derived validation/lifecycle labels.  It
      --  must not alter kind, owner, input text, captured chord, target domain,
      --  confirmation markers, or affected-count payload.
      return Before.Active = After.Active
        and then Before.Kind = After.Kind
        and then Before.Owning_Command = After.Owning_Command
        and then Editor.Input_Field.Text (Before.Input) =
          Editor.Input_Field.Text (After.Input)
        and then Before.Has_Captured_Chord = After.Has_Captured_Chord
        and then (not Before.Has_Captured_Chord
                  or else Editor.Keybindings.Format_Chord (Before.Captured_Chord) =
                    Editor.Keybindings.Format_Chord (After.Captured_Chord))
        and then To_String (Before.Target_Domain_Label) =
          To_String (After.Target_Domain_Label)
        and then Before.Requires_Confirmation = After.Requires_Confirmation
        and then Before.Destructive = After.Destructive
        and then Before.Lifecycle_Command = After.Lifecycle_Command
        and then Before.Configuration_Command = After.Configuration_Command
        and then Before.Affected_Count = After.Affected_Count;
   end Prompt_Validation_Is_Side_Effect_Free;

   function Prompt_Cancel_Is_Atomic
     (Before : Prompt_State; After : Prompt_State) return Boolean is
   begin
      return Before.Active
        and then not After.Active
        and then After.Kind = No_Prompt
        and then After.Owning_Command = Editor.Commands.No_Command
        and then Editor.Input_Field.Text (After.Input) = ""
        and then not After.Has_Captured_Chord
        and then After.Lifecycle = Prompt_Inactive;
   end Prompt_Cancel_Is_Atomic;

   function Carries_No_Persisted_Payload (Prompt : Prompt_State) return Boolean is
   begin
      --  The prompt object is allowed to carry transient input while active,
      --  but its persistence-facing contract is intentionally negative: the
      --  only stable reference is the owning command id.  Target/domain labels
      --  are display labels only, never serialized paths, queries, setting
      --  values, chords, row ids, or confirmation payloads.
      return not Prompt.Active or else
        (Prompt.Owning_Command /= Editor.Commands.No_Command
         and then Length (Prompt.Target_Domain_Label) <= 64
         and then (if Prompt.Kind = No_Prompt then False else True));
   end Carries_No_Persisted_Payload;

   function Assert_Guided_Workflow_Prompts_Coherent
     (Prompt : Prompt_State) return Boolean is
   begin
      if not Prompt.Active then
         return Prompt.Kind = No_Prompt and then Prompt.Lifecycle = Prompt_Inactive;
      end if;

      return Prompt.Kind /= No_Prompt
        and then Prompt.Owning_Command /= Editor.Commands.No_Command
        and then Carries_No_Persisted_Payload (Prompt)
        and then Length (Prompt.Title) > 0
        and then Length (Prompt.Validation_Message) > 0
        and then Length (Prompt.Confirm_Label) > 0
        and then Length (Prompt.Cancel_Label) > 0
        and then (if Is_Confirmation (Prompt)
                  then Prompt.Lifecycle_Command or else Prompt.Destructive
                    or else Prompt.Configuration_Command
                  else True)
        and then (if Prompt.Kind = Keybinding_Capture_Prompt
                  then Length (Prompt.Target_Domain_Label) > 0
                  else True);
   end Assert_Guided_Workflow_Prompts_Coherent;
end Editor.Guided_Prompts;
