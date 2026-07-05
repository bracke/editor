with Ada.Strings.Unbounded;
with Editor.Dirty_Guards;

package Editor.Pending_Transitions is

   type Pending_Transition_Kind is
     (No_Pending_Transition,
      Pending_Close_Buffer,
      Pending_Close_All_Buffers,
      Pending_Close_Other_Buffers,
      Pending_Reload_Active_Buffer,
      Pending_Revert_Active_Buffer,
      Pending_Close_Project,
      Pending_Open_Project,
      Pending_Switch_Project,
      Pending_Open_Recent_Project,
      Pending_Restore_Workspace,
      Pending_Clear_Workspace_State,
      Pending_Clear_Project);

   type Pending_Transition_Target is record
      Kind        : Pending_Transition_Kind := No_Pending_Transition;
      Path        : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Display     : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Buffer_Id   : Natural := 0;
      Has_Buffer  : Boolean := False;
      Has_Path    : Boolean := False;
      Source_Path : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Has_Source_Path : Boolean := False;
      --  dirty reload/revert confirmations may be opened while
      --  the backing file has a known external state.  Capture that observed
      --  command-boundary state transiently so confirmation retry can reject
      --  a prompt if the backing file changes again before destructive read.
      Observed_File_Status_Code : Natural := 0;
      Has_Observed_File_Status  : Boolean := False;
      Observed_File_Token_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Has_Observed_File_Token   : Boolean := False;
   end record;


   type Pending_Transition_Boundary_Audit is record
      Has_Pending                         : Boolean := False;
      Has_Runtime_Buffer_Id               : Boolean := False;
      Has_File_Conflict_Token             : Boolean := False;
      Runtime_Buffer_Id_Is_Transient      : Boolean := True;
      Runtime_Buffer_Id_Not_Persisted     : Boolean := True;
      Runtime_Buffer_Id_Not_Command_Payload : Boolean := True;
      Runtime_Buffer_Id_Not_Keybinding_Payload : Boolean := True;
      Runtime_Buffer_Id_Not_Render_Payload : Boolean := True;
      File_Conflict_Token_Is_Transient    : Boolean := True;
      File_Conflict_Token_Not_Persisted   : Boolean := True;
      File_Conflict_Token_Not_Rendered    : Boolean := True;
      Prompt_Display_Hides_Runtime_Buffer_Id : Boolean := True;
      Prompt_Display_Hides_File_Conflict_Token : Boolean := True;
      Pending_Target_Revalidation_Required : Boolean := False;
      Pending_Target_Has_Revalidation_Key : Boolean := True;
      Boundary_Safe                       : Boolean := True;
   end record;

   type Pending_Transition_State is private;

   procedure Clear
     (State : in out Pending_Transition_State);

   function Has_Pending
     (State : Pending_Transition_State) return Boolean;

   function Target
     (State : Pending_Transition_State) return Pending_Transition_Target;

   function Target_Kind
     (State : Pending_Transition_State) return Pending_Transition_Kind;

   function Has_Target_Buffer
     (State : Pending_Transition_State) return Boolean;

   function Target_Buffer_Id
     (State : Pending_Transition_State;
      Found : out Boolean) return Natural;

   function Has_Target_Path
     (State : Pending_Transition_State) return Boolean;

   function Target_Path
     (State : Pending_Transition_State;
      Found : out Boolean) return String;

   function Dirty_Summary
     (State : Pending_Transition_State)
      return Editor.Dirty_Guards.Dirty_Buffer_Summary;

   procedure Set_Pending
     (State   : in out Pending_Transition_State;
      Target  : Pending_Transition_Target;
      Summary : Editor.Dirty_Guards.Dirty_Buffer_Summary);

   function Audit_Pending_Transition_Boundary
     (State : Pending_Transition_State) return Pending_Transition_Boundary_Audit;

   function Display_Text
     (State : Pending_Transition_State) return String;

private

   type Pending_Transition_State is record
      Has_Target : Boolean := False;
      Target     : Pending_Transition_Target;
      Summary    : Editor.Dirty_Guards.Dirty_Buffer_Summary;
   end record;

end Editor.Pending_Transitions;
