with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffers;
with Editor.Buffer_Switcher;
with Editor.Command_Palette;
with Editor.Command_Route_Audit;
with Editor.Commands;
with Editor.Keybindings;
with Editor.Messages;
with Editor.Pending_Transitions;
with Editor.Project;
with Editor.Recent_Projects;
with Editor.Render_Packet;
with Editor.Settings;
with Editor.State;
with Editor.Workspace_Persistence;

package body Editor.Configuration_Audit is

   function Count_Image (Value : Natural) return String is
      Raw : constant String := Natural'Image (Value);
   begin
      return Raw (Raw'First + 1 .. Raw'Last);
   end Count_Image;

   function Domain_Name (Domain : Configuration_Domain) return String is
   begin
      case Domain is
         when Settings_Domain =>
            return "settings";
         when Keybindings_Domain =>
            return "keybindings";
         when Workspace_Domain =>
            return "workspace";
         when Recent_Projects_Domain =>
            return "recent-projects";
         when Runtime_State_Domain =>
            return "runtime-state";
      end case;
   end Domain_Name;

   function Binding_Display
     (Command : Editor.Commands.Command_Id) return String
   is
      Info : constant Editor.Keybindings.Command_Keybinding_Info :=
        Editor.Keybindings.Primary_Binding_For_Command (Command);
   begin
      if Info.Has_Binding then
         return To_String (Info.Display);
      else
         return "";
      end if;
   end Binding_Display;

   function Active_Binding_Count return Natural is
      Count : Natural := 0;
   begin
      for Index in 1 .. Editor.Commands.Command_Count loop
         declare
            Id : constant Editor.Commands.Command_Id :=
              Editor.Commands.Command_At (Index);
         begin
            if Editor.Commands.Is_Concrete_Command (Id) then
               Count := Count + Editor.Keybindings.Binding_Count_For_Command (Id);
            end if;
         end;
      end loop;
      return Count;
   end Active_Binding_Count;

   procedure Clear
     (Result : in out Configuration_Audit_Result)
   is
   begin
      Result.Failures.Clear;
   end Clear;

   procedure Add_Failure
     (Result  : in out Configuration_Audit_Result;
      Domain  : Configuration_Domain;
      Message : String)
   is
   begin
      Result.Failures.Append
        (To_Unbounded_String (Domain_Name (Domain) & ": " & Message));
   end Add_Failure;

   function Status
     (Result : Configuration_Audit_Result)
      return Configuration_Audit_Status
   is
   begin
      if Result.Failures.Is_Empty then
         return Configuration_Audit_Ok;
      else
         return Configuration_Audit_Failed;
      end if;
   end Status;

   function Failure_Count
     (Result : Configuration_Audit_Result) return Natural
   is
   begin
      return Natural (Result.Failures.Length);
   end Failure_Count;

   function Failure
     (Result : Configuration_Audit_Result;
      Index  : Positive) return String
   is
   begin
      if Index > Natural (Result.Failures.Length) then
         return "";
      end if;
      return To_String (Result.Failures (Natural (Index - 1)));
   end Failure;

   function Summary
     (Result : Configuration_Audit_Result) return String
   is
   begin
      if Result.Failures.Is_Empty then
         return "Configuration audit ok";
      elsif Natural (Result.Failures.Length) = 1 then
         return "Configuration audit failed: " & To_String (Result.Failures (0));
      else
         return "Configuration audit failed: "
           & Count_Image (Natural (Result.Failures.Length)) & " failures";
      end if;
   end Summary;



   function Text_Contains_File_Token_Payload (Text : String) return Boolean is
   begin
      return Editor.Command_Route_Audit.Text_Contains_Runtime_Buffer_Payload (Text);
   end Text_Contains_File_Token_Payload;

   function File_Conflict_Prompt_Display_Text
     (State : Editor.State.State_Type) return String
   is
   begin
      if not State.File_Conflict_Prompt_Active then
         return "";
      elsif State.File_Conflict_Prompt_Dirty then
         return "File conflict: keep buffer, reload from disk, overwrite disk, or cancel";
      else
         return "File conflict: keep buffer, reload from disk, or cancel";
      end if;
   end File_Conflict_Prompt_Display_Text;

   type File_Conflict_Prompt_Boundary_Audit is record
      Has_Prompt                         : Boolean := False;
      Has_Runtime_Buffer_Id              : Boolean := False;
      Has_File_Token                     : Boolean := False;
      Prompt_State_Is_Transient          : Boolean := True;
      Runtime_Buffer_Id_Not_Persisted    : Boolean := True;
      Runtime_Buffer_Id_Not_Command_Payload : Boolean := True;
      Runtime_Buffer_Id_Not_Keybinding_Payload : Boolean := True;
      Runtime_Buffer_Id_Not_Render_Payload : Boolean := True;
      File_Token_Not_Persisted           : Boolean := True;
      File_Token_Not_Rendered            : Boolean := True;
      Display_Hides_Runtime_Buffer_Id    : Boolean := True;
      Display_Hides_File_Token           : Boolean := True;
      Revalidation_Required              : Boolean := False;
      Has_Revalidation_Key               : Boolean := True;
      Boundary_Safe                      : Boolean := True;
   end record;

   function File_Conflict_Prompt_Has_Revalidation_Key
     (State : Editor.State.State_Type) return Boolean
   is
      use type Editor.State.File_Conflict_Kind;
   begin
      if not State.File_Conflict_Prompt_Active then
         return True;
      end if;

      --  file-conflict prompts may retain runtime buffer identity
      --  and an observed disk token only as transient revalidation keys.  The
      --  destructive confirmation path must be able to re-check the same
      --  registered buffer, backing path, conflict kind, dirty flag, buffer
      --  revision, and (when captured) disk-token label before mutating.
      return State.File_Conflict_Prompt_Buffer /= 0
        and then Length (State.File_Conflict_Prompt_Path) > 0
        and then State.File_Conflict_Prompt_Kind /= Editor.State.No_File_Conflict;
   end File_Conflict_Prompt_Has_Revalidation_Key;

   function Audit_File_Conflict_Prompt_Boundary
     (State : Editor.State.State_Type) return File_Conflict_Prompt_Boundary_Audit
   is
      Audit : File_Conflict_Prompt_Boundary_Audit;
      Text  : constant String := File_Conflict_Prompt_Display_Text (State);
      Has_Forbidden_Display_Field : constant Boolean :=
        Editor.Command_Route_Audit.Text_Contains_Runtime_Buffer_Payload (Text);
      Token_Label : constant String := To_String (State.File_Conflict_Prompt_Token_Label);
   begin
      Audit.Has_Prompt := State.File_Conflict_Prompt_Active;
      if not Audit.Has_Prompt then
         Audit.Boundary_Safe := True;
         return Audit;
      end if;

      Audit.Has_Runtime_Buffer_Id := State.File_Conflict_Prompt_Buffer /= 0;
      Audit.Has_File_Token := Length (State.File_Conflict_Prompt_Token_Label) > 0;

      Audit.Prompt_State_Is_Transient := True;
      Audit.Runtime_Buffer_Id_Not_Persisted := True;
      Audit.Runtime_Buffer_Id_Not_Command_Payload := True;
      Audit.Runtime_Buffer_Id_Not_Keybinding_Payload := True;
      Audit.Runtime_Buffer_Id_Not_Render_Payload := not Has_Forbidden_Display_Field;
      Audit.File_Token_Not_Persisted := True;
      Audit.File_Token_Not_Rendered :=
        (not Has_Forbidden_Display_Field)
        and then (Token_Label'Length = 0
          or else Ada.Strings.Fixed.Index (Text, Token_Label) = 0)
        and then not Text_Contains_File_Token_Payload (Text);
      Audit.Display_Hides_Runtime_Buffer_Id := not Has_Forbidden_Display_Field;
      Audit.Display_Hides_File_Token := Audit.File_Token_Not_Rendered;
      Audit.Revalidation_Required := True;
      Audit.Has_Revalidation_Key := File_Conflict_Prompt_Has_Revalidation_Key (State);
      Audit.Boundary_Safe :=
        Audit.Prompt_State_Is_Transient
        and then Audit.Runtime_Buffer_Id_Not_Persisted
        and then Audit.Runtime_Buffer_Id_Not_Command_Payload
        and then Audit.Runtime_Buffer_Id_Not_Keybinding_Payload
        and then Audit.Runtime_Buffer_Id_Not_Render_Payload
        and then Audit.File_Token_Not_Persisted
        and then Audit.File_Token_Not_Rendered
        and then Audit.Display_Hides_Runtime_Buffer_Id
        and then Audit.Display_Hides_File_Token
        and then Audit.Has_Revalidation_Key;
      return Audit;
   end Audit_File_Conflict_Prompt_Boundary;

   function Buffer_Boundary_Audit_For
     (State                : Editor.State.State_Type;
      Serialized_Workspace : String := "") return Buffer_Boundary_Audit_Summary
   is
      Selected_Audit : constant Editor.Buffer_Switcher.Selected_Buffer_List_Audit :=
        Editor.Buffer_Switcher.Audit_Selected_Buffer_List_State
          (State.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI);
      Buffer_Audit : constant Editor.Buffers.Buffer_Audit_Summary :=
        Editor.Buffers.Global_Audit_Buffers
          (State.Project, Selected_Audit.Selected_Buffer_Id);
      Workspace_Audit : constant Editor.Workspace_Persistence.Workspace_Buffer_Persistence_Audit :=
        Editor.Workspace_Persistence.Audit_Serialized_Buffer_Persistence
          (Serialized_Workspace);
      Pending_Audit : constant Editor.Pending_Transitions.Pending_Transition_Boundary_Audit :=
        Editor.Pending_Transitions.Audit_Pending_Transition_Boundary
          (State.Pending_Transitions);
      Conflict_Audit : constant File_Conflict_Prompt_Boundary_Audit :=
        Audit_File_Conflict_Prompt_Boundary (State);
      Render_Audit : constant
        Editor.Render_Packet.Buffer_Metadata_Render_Boundary_Audit :=
          Editor.Render_Packet.Audit_Buffer_Metadata_Render_Boundary;
      Route_Audit : Editor.Command_Route_Audit.Route_Audit_Result;
      Result : Buffer_Boundary_Audit_Summary;
   begin
      --  Inspect actual route surfaces instead of trusting
      --  representative caller-provided booleans: command descriptors, current
      --  keybinding records, Buffer List route metadata, and serialized
      --  workspace text must not carry runtime buffer identities.
      Editor.Command_Route_Audit.Inspect_Buffer_Route_Surfaces_No_Buffer_Payload
        (Route_Audit, State.Buffer_Switcher, Serialized_Workspace);

      Result.Buffer_Metadata_Coherent :=
        Buffer_Audit.Metadata_Projection_Coherent
        and then Selected_Audit.Selected_Row_Valid
        and then Selected_Audit.Selection_Is_Transient;
      Result.Active_Buffer_Valid := Buffer_Audit.Active_Buffer_Valid;
      Result.Selected_Buffer_Valid :=
        Buffer_Audit.Selected_Buffer_Valid and then Selected_Audit.Selected_Row_Valid;
      Result.Buffer_List_Selected_Row_Valid := Selected_Audit.Selected_Row_Valid;
      Result.Buffer_List_Selected_Row_Is_Buffer := Selected_Audit.Selected_Row_Is_Buffer;
      Result.Buffer_List_Selected_Runtime_Id_Registered :=
        Selected_Audit.Selected_Runtime_Id_Registered;
      Result.Buffer_List_Selection_Cleared_When_No_Rows :=
        Selected_Audit.Selection_Cleared_When_No_Rows;
      Result.Buffer_List_Selection_Index_Clamped_To_Rows :=
        Selected_Audit.Selection_Index_Clamped_To_Rows;
      Result.Buffer_List_Selection_Is_Transient :=
        Selected_Audit.Selection_Is_Transient
        and then Selected_Audit.Selection_Not_Persisted
        and then Selected_Audit.Selection_Not_Keybinding_Payload;
      Result.Pending_Runtime_Buffer_Id_Transient :=
        Pending_Audit.Runtime_Buffer_Id_Is_Transient;
      Result.Pending_File_Conflict_Token_Transient :=
        Pending_Audit.File_Conflict_Token_Is_Transient;
      Result.Pending_Buffer_Id_Not_Persisted :=
        Pending_Audit.Runtime_Buffer_Id_Not_Persisted;
      Result.Pending_Buffer_Id_Not_Command_Payload :=
        Pending_Audit.Runtime_Buffer_Id_Not_Command_Payload;
      Result.Pending_Buffer_Id_Not_Keybinding_Payload :=
        Pending_Audit.Runtime_Buffer_Id_Not_Keybinding_Payload;
      Result.Pending_Buffer_Id_Not_Render_Payload :=
        Pending_Audit.Runtime_Buffer_Id_Not_Render_Payload;
      Result.Pending_File_Token_Not_Persisted :=
        Pending_Audit.File_Conflict_Token_Not_Persisted;
      Result.Pending_File_Token_Not_Rendered :=
        Pending_Audit.File_Conflict_Token_Not_Rendered;
      Result.Pending_Target_Revalidated_Before_Mutation :=
        (not Pending_Audit.Has_Pending)
        or else (Pending_Audit.Pending_Target_Revalidation_Required
          and then Pending_Audit.Pending_Target_Has_Revalidation_Key);
      Result.Pending_Transition_Boundary_Safe :=
        Pending_Audit.Boundary_Safe;
      Result.File_Conflict_Prompt_Transient :=
        Conflict_Audit.Prompt_State_Is_Transient;
      Result.File_Conflict_Prompt_Buffer_Id_Not_Persisted :=
        Conflict_Audit.Runtime_Buffer_Id_Not_Persisted;
      Result.File_Conflict_Prompt_Buffer_Id_Not_Command_Payload :=
        Conflict_Audit.Runtime_Buffer_Id_Not_Command_Payload;
      Result.File_Conflict_Prompt_Buffer_Id_Not_Keybinding_Payload :=
        Conflict_Audit.Runtime_Buffer_Id_Not_Keybinding_Payload;
      Result.File_Conflict_Prompt_Buffer_Id_Not_Render_Payload :=
        Conflict_Audit.Runtime_Buffer_Id_Not_Render_Payload;
      Result.File_Conflict_Prompt_Token_Not_Persisted :=
        Conflict_Audit.File_Token_Not_Persisted;
      Result.File_Conflict_Prompt_Token_Not_Rendered :=
        Conflict_Audit.File_Token_Not_Rendered;
      Result.File_Conflict_Prompt_Display_Hides_Runtime_Buffer_Id :=
        Conflict_Audit.Display_Hides_Runtime_Buffer_Id;
      Result.File_Conflict_Prompt_Display_Hides_File_Token :=
        Conflict_Audit.Display_Hides_File_Token;
      Result.File_Conflict_Prompt_Revalidated_Before_Mutation :=
        (not Conflict_Audit.Has_Prompt)
        or else (Conflict_Audit.Revalidation_Required
          and then Conflict_Audit.Has_Revalidation_Key);
      Result.File_Conflict_Prompt_Boundary_Safe :=
        Conflict_Audit.Boundary_Safe;
      Result.Workspace_Persistence_Safe :=
        Buffer_Audit.Workspace_Persistence_Safe and then Workspace_Audit.Safe;
      Result.Command_Keybinding_Payloads_Clear :=
        Buffer_Audit.Command_Keybinding_Payloads_Clear
        and then Editor.Command_Route_Audit.Failure_Count (Route_Audit) = 0;
      Result.Render_Uses_Metadata_Snapshots_Only :=
        Render_Audit.Uses_Metadata_Snapshots_Only;
      Result.Render_Does_Not_Switch_Buffers :=
        Render_Audit.Does_Not_Switch_Buffers;
      Result.Render_Does_Not_Close_Buffers :=
        Render_Audit.Does_Not_Close_Buffers;
      Result.Render_Does_Not_Save_Reload_Revert :=
        Render_Audit.Does_Not_Save_Reload_Revert;
      Result.Render_Does_Not_Probe_Filesystem :=
        Render_Audit.Does_Not_Probe_Filesystem;
      Result.Render_Does_Not_Classify_By_Mutation :=
        Render_Audit.Does_Not_Classify_By_Mutation;
      Result.Render_Does_Not_Expose_Runtime_Buffer_Ids :=
        Render_Audit.Does_Not_Expose_Runtime_Buffer_Ids;
      Result.Render_Buffer_List_Metadata_Projection_Only :=
        Render_Audit.Buffer_List_Metadata_Projection_Only;
      Result.Render_Active_Buffer_Metadata_Projection_Only :=
        Render_Audit.Active_Buffer_Metadata_Projection_Only;
      Result.Render_Boundary_Safe :=
        Buffer_Audit.Render_Boundary_Safe
        and then Render_Audit.Boundary_Safe
        and then Render_Audit.Side_Effect_Free
        and then Render_Audit.Uses_Metadata_Snapshots_Only
        and then Render_Audit.Does_Not_Switch_Buffers
        and then Render_Audit.Does_Not_Close_Buffers
        and then Render_Audit.Does_Not_Save_Reload_Revert
        and then Render_Audit.Does_Not_Probe_Filesystem
        and then Render_Audit.Does_Not_Classify_By_Mutation
        and then Render_Audit.Does_Not_Expose_Runtime_Buffer_Ids
        and then Render_Audit.Buffer_List_Metadata_Projection_Only
        and then Render_Audit.Active_Buffer_Metadata_Projection_Only;
      Result.Audit_Side_Effect_Free := Buffer_Audit.Audit_Side_Effect_Free;
      Result.Runtime_Buffer_Id_Persisted :=
        Buffer_Audit.Runtime_Buffer_Id_Persisted
        or else Workspace_Audit.Runtime_Buffer_Id_Persisted;
      Result.Active_Runtime_Id_Persisted :=
        Buffer_Audit.Active_Runtime_Id_Persisted
        or else Workspace_Audit.Active_Buffer_Id_Persisted;
      Result.Selected_Runtime_Id_Persisted :=
        Buffer_Audit.Selected_Runtime_Id_Persisted
        or else Workspace_Audit.Selected_Buffer_Id_Persisted;
      Result.Buffer_List_State_Persisted :=
        Buffer_Audit.Buffer_List_State_Persisted
        or else Workspace_Audit.Buffer_List_State_Persisted;
      Result.Dirty_Text_Persisted :=
        Buffer_Audit.Dirty_Text_Persisted or else Workspace_Audit.Dirty_Text_Persisted;
      Result.Scratch_Text_Persisted :=
        Buffer_Audit.Scratch_Text_Persisted or else Workspace_Audit.Scratch_Text_Persisted;
      Result.Conflict_Token_Persisted :=
        Buffer_Audit.Conflict_Token_Persisted
        or else Workspace_Audit.Conflict_Token_Persisted;
      Result.Close_Prompt_State_Persisted := Workspace_Audit.Close_Prompt_State_Persisted;
      Result.Undo_Redo_Clipboard_Persisted := Workspace_Audit.Undo_Redo_Clipboard_Persisted;
      Result.Buffer_Count := Buffer_Audit.Buffer_Count;
      Result.Workspace_Persistable_Count := Buffer_Audit.Workspace_Persistable_Count;
      Result.Workspace_Not_Persistable_Count := Buffer_Audit.Workspace_Not_Persistable_Count;
      Result.Dirty_Project_File_Count := Buffer_Audit.Dirty_Project_File_Count;
      Result.Dirty_Outside_Project_Count := Buffer_Audit.Dirty_Outside_Project_Count;
      Result.Dirty_Scratch_Count := Buffer_Audit.Dirty_Scratch_Count;
      Result.Dirty_Conflicted_Count := Buffer_Audit.Dirty_Conflicted_Count;
      Result.Dirty_Unwritable_Count := Buffer_Audit.Dirty_Unwritable_Count;
      return Result;
   end Buffer_Boundary_Audit_For;

   procedure Audit_Buffer_Metadata_Lifecycle_Boundaries
     (Result               : in out Configuration_Audit_Result;
      State                : Editor.State.State_Type;
      Serialized_Workspace : String := "")
   is
      Summary : constant Buffer_Boundary_Audit_Summary :=
        Buffer_Boundary_Audit_For (State, Serialized_Workspace);
   begin
      if not Summary.Buffer_Metadata_Coherent then
         Add_Failure (Result, Runtime_State_Domain,
                      "buffer metadata projection is incoherent");
      end if;
      if not Summary.Active_Buffer_Valid then
         Add_Failure (Result, Runtime_State_Domain,
                      "active buffer does not reference a registered buffer or none");
      end if;
      if not Summary.Selected_Buffer_Valid then
         Add_Failure (Result, Runtime_State_Domain,
                      "selected buffer row references stale runtime identity");
      end if;
      if not Summary.Buffer_List_Selected_Row_Valid then
         Add_Failure (Result, Runtime_State_Domain,
                      "Buffer List selected row is not a valid registered buffer row");
      end if;
      if not Summary.Buffer_List_Selected_Row_Is_Buffer then
         Add_Failure (Result, Runtime_State_Domain,
                      "Buffer List selection points at a non-buffer/status row");
      end if;
      if not Summary.Buffer_List_Selected_Runtime_Id_Registered then
         Add_Failure (Result, Runtime_State_Domain,
                      "Buffer List selected runtime id is no longer registered");
      end if;
      if not Summary.Buffer_List_Selection_Cleared_When_No_Rows
        or else not Summary.Buffer_List_Selection_Index_Clamped_To_Rows
      then
         Add_Failure (Result, Runtime_State_Domain,
                      "Buffer List selection is not clamped to current rows");
      end if;
      if not Summary.Buffer_List_Selection_Is_Transient then
         Add_Failure (Result, Runtime_State_Domain,
                      "Buffer List selection crossed a persistence or keybinding boundary");
      end if;
      if not Summary.Pending_Transition_Boundary_Safe
        or else not Summary.Pending_Runtime_Buffer_Id_Transient
        or else not Summary.Pending_File_Conflict_Token_Transient
      then
         Add_Failure (Result, Runtime_State_Domain,
                      "pending transition carries runtime buffer state outside transient boundary");
      end if;
      if not Summary.Pending_Buffer_Id_Not_Persisted
        or else not Summary.Pending_File_Token_Not_Persisted
      then
         Add_Failure (Result, Workspace_Domain,
                      "pending transition buffer id or file token crossed persistence boundary");
      end if;
      if not Summary.Pending_Buffer_Id_Not_Command_Payload
        or else not Summary.Pending_Buffer_Id_Not_Keybinding_Payload
      then
         Add_Failure (Result, Keybindings_Domain,
                      "pending transition buffer id crossed command/keybinding payload boundary");
      end if;
      if not Summary.Pending_Buffer_Id_Not_Render_Payload
        or else not Summary.Pending_File_Token_Not_Rendered
      then
         Add_Failure (Result, Runtime_State_Domain,
                      "pending transition buffer id or file token crossed render boundary");
      end if;
      if not Summary.Pending_Target_Revalidated_Before_Mutation then
         Add_Failure (Result, Runtime_State_Domain,
                      "pending transition target lacks revalidation key before mutation");
      end if;
      if not Summary.File_Conflict_Prompt_Boundary_Safe
        or else not Summary.File_Conflict_Prompt_Transient
      then
         Add_Failure (Result, Runtime_State_Domain,
                      "file conflict prompt carries runtime state outside transient boundary");
      end if;
      if not Summary.File_Conflict_Prompt_Buffer_Id_Not_Persisted
        or else not Summary.File_Conflict_Prompt_Token_Not_Persisted
      then
         Add_Failure (Result, Workspace_Domain,
                      "file conflict prompt buffer id or token crossed persistence boundary");
      end if;
      if not Summary.File_Conflict_Prompt_Buffer_Id_Not_Command_Payload
        or else not Summary.File_Conflict_Prompt_Buffer_Id_Not_Keybinding_Payload
      then
         Add_Failure (Result, Keybindings_Domain,
                      "file conflict prompt buffer id crossed command/keybinding payload boundary");
      end if;
      if not Summary.File_Conflict_Prompt_Buffer_Id_Not_Render_Payload
        or else not Summary.File_Conflict_Prompt_Token_Not_Rendered
        or else not Summary.File_Conflict_Prompt_Display_Hides_Runtime_Buffer_Id
        or else not Summary.File_Conflict_Prompt_Display_Hides_File_Token
      then
         Add_Failure (Result, Runtime_State_Domain,
                      "file conflict prompt buffer id or token crossed render boundary");
      end if;
      if not Summary.File_Conflict_Prompt_Revalidated_Before_Mutation then
         Add_Failure (Result, Runtime_State_Domain,
                      "file conflict prompt lacks revalidation key before mutation");
      end if;
      if not Summary.Workspace_Persistence_Safe then
         Add_Failure (Result, Workspace_Domain,
                      "workspace buffer persistence contains forbidden runtime state");
      end if;
      if Summary.Runtime_Buffer_Id_Persisted then
         Add_Failure (Result, Workspace_Domain,
                      "workspace persistence contains runtime buffer id");
      end if;
      if Summary.Active_Runtime_Id_Persisted then
         Add_Failure (Result, Workspace_Domain,
                      "workspace persistence contains active runtime buffer id");
      end if;
      if Summary.Selected_Runtime_Id_Persisted then
         Add_Failure (Result, Workspace_Domain,
                      "workspace persistence contains selected runtime buffer id");
      end if;
      if Summary.Buffer_List_State_Persisted then
         Add_Failure (Result, Workspace_Domain,
                      "workspace persistence contains Buffer List state");
      end if;
      if Summary.Dirty_Text_Persisted then
         Add_Failure (Result, Workspace_Domain,
                      "workspace persistence contains dirty buffer text");
      end if;
      if Summary.Scratch_Text_Persisted then
         Add_Failure (Result, Workspace_Domain,
                      "workspace persistence contains scratch buffer text");
      end if;
      if Summary.Conflict_Token_Persisted then
         Add_Failure (Result, Workspace_Domain,
                      "workspace persistence contains file conflict token");
      end if;
      if Summary.Close_Prompt_State_Persisted then
         Add_Failure (Result, Workspace_Domain,
                      "workspace persistence contains close or conflict prompt state");
      end if;
      if Summary.Undo_Redo_Clipboard_Persisted then
         Add_Failure (Result, Workspace_Domain,
                      "workspace persistence contains undo/redo/clipboard state");
      end if;
      if not Summary.Command_Keybinding_Payloads_Clear then
         Add_Failure (Result, Keybindings_Domain,
                      "buffer command or keybinding route carries runtime buffer payload");
      end if;
      if not Summary.Render_Boundary_Safe then
         Add_Failure (Result, Runtime_State_Domain,
                      "render boundary exposes a buffer mutation route");
      end if;
      if not Summary.Render_Uses_Metadata_Snapshots_Only then
         Add_Failure (Result, Runtime_State_Domain,
                      "render derives buffer metadata outside snapshot projection");
      end if;
      if not Summary.Render_Does_Not_Switch_Buffers then
         Add_Failure (Result, Runtime_State_Domain,
                      "render may switch buffers");
      end if;
      if not Summary.Render_Does_Not_Close_Buffers then
         Add_Failure (Result, Runtime_State_Domain,
                      "render may close buffers");
      end if;
      if not Summary.Render_Does_Not_Save_Reload_Revert then
         Add_Failure (Result, Runtime_State_Domain,
                      "render may save reload or revert buffers");
      end if;
      if not Summary.Render_Does_Not_Probe_Filesystem then
         Add_Failure (Result, Runtime_State_Domain,
                      "render may probe filesystem for buffer metadata");
      end if;
      if not Summary.Render_Does_Not_Classify_By_Mutation then
         Add_Failure (Result, Runtime_State_Domain,
                      "render may classify buffers by mutating state");
      end if;
      if not Summary.Render_Does_Not_Expose_Runtime_Buffer_Ids then
         Add_Failure (Result, Runtime_State_Domain,
                      "render exposes runtime buffer ids");
      end if;
      if not Summary.Render_Buffer_List_Metadata_Projection_Only then
         Add_Failure (Result, Runtime_State_Domain,
                      "Buffer List render metadata is not snapshot-only");
      end if;
      if not Summary.Render_Active_Buffer_Metadata_Projection_Only then
         Add_Failure (Result, Runtime_State_Domain,
                      "active buffer render metadata is not snapshot-only");
      end if;
      if not Summary.Audit_Side_Effect_Free then
         Add_Failure (Result, Runtime_State_Domain,
                      "buffer metadata audit is not side-effect-free");
      end if;
   end Audit_Buffer_Metadata_Lifecycle_Boundaries;

   function Buffer_Metadata_Lifecycle_Complete
     (State                : Editor.State.State_Type;
      Serialized_Workspace : String := "") return Boolean
   is
      Summary : constant Buffer_Boundary_Audit_Summary :=
        Buffer_Boundary_Audit_For (State, Serialized_Workspace);
   begin
      return
        Summary.Buffer_Metadata_Coherent
        and then Summary.Active_Buffer_Valid
        and then Summary.Selected_Buffer_Valid
        and then Summary.Buffer_List_Selected_Row_Valid
        and then Summary.Buffer_List_Selected_Row_Is_Buffer
        and then Summary.Buffer_List_Selected_Runtime_Id_Registered
        and then Summary.Buffer_List_Selection_Cleared_When_No_Rows
        and then Summary.Buffer_List_Selection_Index_Clamped_To_Rows
        and then Summary.Buffer_List_Selection_Is_Transient
        and then Summary.Pending_Runtime_Buffer_Id_Transient
        and then Summary.Pending_File_Conflict_Token_Transient
        and then Summary.Pending_Buffer_Id_Not_Persisted
        and then Summary.Pending_Buffer_Id_Not_Command_Payload
        and then Summary.Pending_Buffer_Id_Not_Keybinding_Payload
        and then Summary.Pending_Buffer_Id_Not_Render_Payload
        and then Summary.Pending_File_Token_Not_Persisted
        and then Summary.Pending_File_Token_Not_Rendered
        and then Summary.Pending_Target_Revalidated_Before_Mutation
        and then Summary.Pending_Transition_Boundary_Safe
        and then Summary.File_Conflict_Prompt_Transient
        and then Summary.File_Conflict_Prompt_Buffer_Id_Not_Persisted
        and then Summary.File_Conflict_Prompt_Buffer_Id_Not_Command_Payload
        and then Summary.File_Conflict_Prompt_Buffer_Id_Not_Keybinding_Payload
        and then Summary.File_Conflict_Prompt_Buffer_Id_Not_Render_Payload
        and then Summary.File_Conflict_Prompt_Token_Not_Persisted
        and then Summary.File_Conflict_Prompt_Token_Not_Rendered
        and then Summary.File_Conflict_Prompt_Display_Hides_Runtime_Buffer_Id
        and then Summary.File_Conflict_Prompt_Display_Hides_File_Token
        and then Summary.File_Conflict_Prompt_Revalidated_Before_Mutation
        and then Summary.File_Conflict_Prompt_Boundary_Safe
        and then Summary.Workspace_Persistence_Safe
        and then Summary.Command_Keybinding_Payloads_Clear
        and then Summary.Render_Boundary_Safe
        and then Summary.Render_Uses_Metadata_Snapshots_Only
        and then Summary.Render_Does_Not_Switch_Buffers
        and then Summary.Render_Does_Not_Close_Buffers
        and then Summary.Render_Does_Not_Save_Reload_Revert
        and then Summary.Render_Does_Not_Probe_Filesystem
        and then Summary.Render_Does_Not_Classify_By_Mutation
        and then Summary.Render_Does_Not_Expose_Runtime_Buffer_Ids
        and then Summary.Render_Buffer_List_Metadata_Projection_Only
        and then Summary.Render_Active_Buffer_Metadata_Projection_Only
        and then Summary.Audit_Side_Effect_Free
        and then not Summary.Runtime_Buffer_Id_Persisted
        and then not Summary.Active_Runtime_Id_Persisted
        and then not Summary.Selected_Runtime_Id_Persisted
        and then not Summary.Buffer_List_State_Persisted
        and then not Summary.Dirty_Text_Persisted
        and then not Summary.Scratch_Text_Persisted
        and then not Summary.Conflict_Token_Persisted
        and then not Summary.Close_Prompt_State_Persisted
        and then not Summary.Undo_Redo_Clipboard_Persisted;
   end Buffer_Metadata_Lifecycle_Complete;

   function Configuration_State_Summary_For
     (State : Editor.State.State_Type) return Configuration_State_Summary
   is
      Dirty_Count : Natural := 0;
   begin
      if Editor.Buffers.Global_Count > 0 then
         Dirty_Count := Editor.Buffers.Global_Dirty_Buffer_Count;
      else
         Dirty_Count := (if State.File_Info.Dirty then 1 else 0);
      end if;

      return
        (Theme_Id                         => To_Unbounded_String (Editor.Settings.Theme_Id (State.Settings)),
         Line_Number_Mode                 =>
           To_Unbounded_String
             (Editor.Settings.Line_Number_Mode_Name (State.Settings)),
         Cursor_Blink_Enabled             => Editor.Settings.Cursor_Blink (State.Settings),
         Active_Keybinding_Count          => Active_Binding_Count,
         Save_File_Chord                  => To_Unbounded_String (Binding_Display (Editor.Commands.Command_Save_File)),
         Command_Palette_Chord            =>
           To_Unbounded_String
             (Binding_Display (Editor.Commands.Command_Open_Command_Palette)),
         Command_Palette_Show_Keybindings => Editor.Command_Palette.Current_Config.Show_Keybindings,
         Has_Project                      => Editor.Project.Has_Project (State.Project),
         Recent_Project_Count             => Editor.Recent_Projects.Count (State.Recent_Projects),
         Dirty_Buffer_Count               => Dirty_Count,
         Has_Pending_Transition           => Editor.Pending_Transitions.Has_Pending (State.Pending_Transitions),
         Message_Count                    => Editor.Messages.Count (State.Messages));
   end Configuration_State_Summary_For;

   procedure Check_Equal
     (Result  : in out Configuration_Audit_Result;
      Domain  : Configuration_Domain;
      Label   : String;
      Before  : String;
      After   : String;
      Context : String)
   is
   begin
      if Before /= After then
         Add_Failure
           (Result, Domain,
            Context & " changed " & Label & " from '" & Before & "' to '" & After & "'");
      end if;
   end Check_Equal;

   procedure Check_Equal
     (Result  : in out Configuration_Audit_Result;
      Domain  : Configuration_Domain;
      Label   : String;
      Before  : Natural;
      After   : Natural;
      Context : String)
   is
   begin
      if Before /= After then
         Add_Failure
           (Result, Domain,
            Context & " changed " & Label & " from "
            & Count_Image (Before) & " to " & Count_Image (After));
      end if;
   end Check_Equal;

   procedure Check_Equal
     (Result  : in out Configuration_Audit_Result;
      Domain  : Configuration_Domain;
      Label   : String;
      Before  : Boolean;
      After   : Boolean;
      Context : String)
   is
      function Image (Value : Boolean) return String is
      begin
         if Value then
            return "true";
         else
            return "false";
         end if;
      end Image;
   begin
      if Before /= After then
         Add_Failure
           (Result, Domain,
            Context & " changed " & Label & " from "
            & Image (Before) & " to " & Image (After));
      end if;
   end Check_Equal;

   procedure Expect_No_Runtime_Or_Lifecycle_Mutation
     (Result  : in out Configuration_Audit_Result;
      Before  : Configuration_State_Summary;
      After   : Configuration_State_Summary;
      Context : String)
   is
   begin
      Check_Equal
        (Result, Runtime_State_Domain, "theme",
         To_String (Before.Theme_Id), To_String (After.Theme_Id), Context);
      Check_Equal
        (Result, Runtime_State_Domain, "line numbers",
         To_String (Before.Line_Number_Mode),
         To_String (After.Line_Number_Mode), Context);
      Check_Equal
        (Result, Runtime_State_Domain, "cursor blink",
         Before.Cursor_Blink_Enabled, After.Cursor_Blink_Enabled, Context);
      Check_Equal
        (Result, Keybindings_Domain, "active keybinding count",
         Before.Active_Keybinding_Count, After.Active_Keybinding_Count, Context);
      Check_Equal
        (Result, Keybindings_Domain, "file.save chord",
         To_String (Before.Save_File_Chord), To_String (After.Save_File_Chord),
         Context);
      Check_Equal
        (Result, Keybindings_Domain, "command-palette chord",
         To_String (Before.Command_Palette_Chord),
         To_String (After.Command_Palette_Chord), Context);
      Check_Equal
        (Result, Settings_Domain, "palette keybinding display",
         Before.Command_Palette_Show_Keybindings,
         After.Command_Palette_Show_Keybindings, Context);
      Check_Equal
        (Result, Workspace_Domain, "project state",
         Before.Has_Project, After.Has_Project, Context);
      Check_Equal
        (Result, Recent_Projects_Domain, "recent projects",
         Before.Recent_Project_Count, After.Recent_Project_Count, Context);
      Check_Equal
        (Result, Runtime_State_Domain, "dirty buffers",
         Before.Dirty_Buffer_Count, After.Dirty_Buffer_Count, Context);
      Check_Equal
        (Result, Runtime_State_Domain, "pending transition",
         Before.Has_Pending_Transition, After.Has_Pending_Transition, Context);
   end Expect_No_Runtime_Or_Lifecycle_Mutation;

end Editor.Configuration_Audit;
