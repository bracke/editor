with Ada.Strings.Unbounded;
with Editor.Commands;
with Editor.Input_Field;
with Editor.Keybindings;

package Editor.Guided_Prompts is

   use Ada.Strings.Unbounded;

   type Prompt_Kind is
     (No_Prompt,
      Project_Open_Prompt,
      Project_Switch_Prompt,
      Workspace_Load_Prompt,
      Workspace_Save_Prompt,
      Search_Query_Prompt,
      Replace_Text_Prompt,
      Settings_Value_Prompt,
      Keybinding_Capture_Prompt,
      File_Tree_Create_File_Prompt,
      File_Tree_Create_Directory_Prompt,
      File_Tree_Rename_Prompt,
      Confirmation_Prompt,
      Configuration_Reset_Prompt);

   type Prompt_Validation_State is
     (Validation_Empty_Input,
      Validation_Invalid_Syntax,
      Validation_Target_Unavailable,
      Validation_Target_Stale,
      Validation_Outside_Project,
      Validation_Requires_Confirmation,
      Validation_Ready);

   type Prompt_Lifecycle_State is
     (Prompt_Inactive,
      Prompt_Started,
      Prompt_Editing,
      Prompt_Validating,
      Prompt_Ready_To_Confirm,
      Prompt_Blocked,
      Prompt_Confirmed,
      Prompt_Cancelled,
      Prompt_Completed,
      Prompt_Failed);

   type Prompt_State is record
      Active : Boolean := False;
      Kind   : Prompt_Kind := No_Prompt;
      Lifecycle : Prompt_Lifecycle_State := Prompt_Inactive;
      Title : Unbounded_String := Null_Unbounded_String;
      Description : Unbounded_String := Null_Unbounded_String;
      Owning_Command : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Input : Editor.Input_Field.Input_Field_State;
      Has_Captured_Chord : Boolean := False;
      Captured_Chord : Editor.Keybindings.Key_Chord :=
        (Key => Editor.Keybindings.Key_A, Modifiers => (others => False));
      Validation : Prompt_Validation_State := Validation_Empty_Input;
      Validation_Message : Unbounded_String := To_Unbounded_String ("Prompt requires input");
      Confirm_Label : Unbounded_String := To_Unbounded_String ("Confirm");
      Cancel_Label : Unbounded_String := To_Unbounded_String ("Cancel");
      Previous_Focus_Label : Unbounded_String := Null_Unbounded_String;
      Target_Domain_Label : Unbounded_String := Null_Unbounded_String;
      Requires_Confirmation : Boolean := False;
      Destructive : Boolean := False;
      Lifecycle_Command : Boolean := False;
      Configuration_Command : Boolean := False;
      Affected_Count : Natural := 0;
   end record;

   type Prompt_Snapshot is record
      Active : Boolean := False;
      Kind : Prompt_Kind := No_Prompt;
      Title : Unbounded_String := Null_Unbounded_String;
      Description : Unbounded_String := Null_Unbounded_String;
      Owning_Command_Name : Unbounded_String := Null_Unbounded_String;
      Input_Text : Unbounded_String := Null_Unbounded_String;
      Has_Captured_Chord : Boolean := False;
      Captured_Chord_Label : Unbounded_String := Null_Unbounded_String;
      Validation : Prompt_Validation_State := Validation_Empty_Input;
      Validation_Label : Unbounded_String := Null_Unbounded_String;
      Confirm_Label : Unbounded_String := Null_Unbounded_String;
      Cancel_Label : Unbounded_String := Null_Unbounded_String;
      Target_Domain_Label : Unbounded_String := Null_Unbounded_String;
      Requires_Confirmation : Boolean := False;
      Destructive : Boolean := False;
      Lifecycle_Command : Boolean := False;
      Configuration_Command : Boolean := False;
      Affected_Count : Natural := 0;
   end record;

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
      Affected_Count : Natural := 0);

   procedure Update_Input (Prompt : in out Prompt_State; Text : String);
   procedure Insert_Text (Prompt : in out Prompt_State; Text : String);
   procedure Backspace (Prompt : in out Prompt_State);
   procedure Delete_Forward (Prompt : in out Prompt_State);
   procedure Capture_Chord
     (Prompt : in out Prompt_State;
      Chord : Editor.Keybindings.Key_Chord);
   procedure Validate (Prompt : in out Prompt_State);
   procedure Mark_Confirmed (Prompt : in out Prompt_State);
   procedure Mark_Completed (Prompt : in out Prompt_State);
   procedure Mark_Failed (Prompt : in out Prompt_State; Reason : String);
   procedure Cancel (Prompt : in out Prompt_State);
   procedure Clear (Prompt : in out Prompt_State);

   function Is_Active (Prompt : Prompt_State) return Boolean;
   function Ready (Prompt : Prompt_State) return Boolean;
   function Input_Text (Prompt : Prompt_State) return String;
   function Has_Captured_Key_Chord (Prompt : Prompt_State) return Boolean;
   function Captured_Key_Chord
     (Prompt : Prompt_State) return Editor.Keybindings.Key_Chord;
   function Validation_Label (State : Prompt_Validation_State) return String;
   function Kind_Label (Kind : Prompt_Kind) return String;
   function Snapshot (Prompt : Prompt_State) return Prompt_Snapshot;

   function Is_Confirmation (Prompt : Prompt_State) return Boolean;
   function Is_File_Tree_Name_Prompt (Prompt : Prompt_State) return Boolean;
   function Prompt_Validation_Is_Side_Effect_Free
     (Before : Prompt_State; After : Prompt_State) return Boolean;
   function Prompt_Cancel_Is_Atomic
     (Before : Prompt_State; After : Prompt_State) return Boolean;
   function Carries_No_Persisted_Payload (Prompt : Prompt_State) return Boolean;
   function Assert_Guided_Workflow_Prompts_Coherent
     (Prompt : Prompt_State) return Boolean;
end Editor.Guided_Prompts;
