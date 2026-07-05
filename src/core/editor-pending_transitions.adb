with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;

package body Editor.Pending_Transitions is

   function Count_Text (Count : Natural) return String is
   begin
      return Ada.Strings.Fixed.Trim (Natural'Image (Count), Ada.Strings.Both);
   end Count_Text;

   function Summary_Text
     (Summary : Editor.Dirty_Guards.Dirty_Buffer_Summary) return String
   is
   begin
      if Summary.Dirty_Count = 1 then
         return "1 unsaved buffer";
      else
         return Count_Text (Summary.Dirty_Count) & " unsaved buffers";
      end if;
   end Summary_Text;

   procedure Clear
     (State : in out Pending_Transition_State)
   is
   begin
      State := (Has_Target => False,
                Target     => <>,
                Summary    => <>);
   end Clear;

   function Has_Pending
     (State : Pending_Transition_State) return Boolean
   is
   begin
      return State.Has_Target
        and then State.Target.Kind /= No_Pending_Transition;
   end Has_Pending;

   function Target
     (State : Pending_Transition_State) return Pending_Transition_Target
   is
   begin
      return State.Target;
   end Target;

   function Target_Kind
     (State : Pending_Transition_State) return Pending_Transition_Kind
   is
   begin
      if not Has_Pending (State) then
         return No_Pending_Transition;
      end if;
      return State.Target.Kind;
   end Target_Kind;

   function Has_Target_Buffer
     (State : Pending_Transition_State) return Boolean
   is
   begin
      return Has_Pending (State) and then State.Target.Has_Buffer;
   end Has_Target_Buffer;

   function Target_Buffer_Id
     (State : Pending_Transition_State;
      Found : out Boolean) return Natural
   is
   begin
      Found := Has_Target_Buffer (State);
      if Found then
         return State.Target.Buffer_Id;
      end if;
      return 0;
   end Target_Buffer_Id;

   function Has_Target_Path
     (State : Pending_Transition_State) return Boolean
   is
   begin
      return Has_Pending (State) and then State.Target.Has_Path;
   end Has_Target_Path;

   function Target_Path
     (State : Pending_Transition_State;
      Found : out Boolean) return String
   is
   begin
      Found := Has_Target_Path (State);
      if Found then
         return To_String (State.Target.Path);
      end if;
      return "";
   end Target_Path;

   function Dirty_Summary
     (State : Pending_Transition_State)
      return Editor.Dirty_Guards.Dirty_Buffer_Summary
   is
   begin
      return State.Summary;
   end Dirty_Summary;

   procedure Set_Pending
     (State   : in out Pending_Transition_State;
      Target  : Pending_Transition_Target;
      Summary : Editor.Dirty_Guards.Dirty_Buffer_Summary)
   is
   begin
      State.Has_Target := Target.Kind /= No_Pending_Transition;
      State.Target := Target;
      State.Summary := Summary;
   end Set_Pending;

   function Confirmation_Action_Text
     (Target : Pending_Transition_Target) return String
   is
   begin
      --  completeness: dirty reload/revert confirmations are
      --  file-lifecycle discard prompts for one captured buffer.  Their prompt
      --  text must not advertise the project/buffer transition clean-close
      --  escape hatch as if it completed the reload/revert operation.  The
      --  pending bar may still expose global cleanup actions separately, but
      --  the confirmation copy names only the lifecycle choice itself.
      case Target.Kind is
         when Pending_Reload_Active_Buffer
            | Pending_Revert_Active_Buffer
            | Pending_Clear_Workspace_State =>
            return "Retry or Cancel";
         when others =>
            return "Save All, Discard, Close Clean, Retry, or Cancel";
      end case;
   end Confirmation_Action_Text;


   function Contains (Text : String; Pattern : String) return Boolean is
   begin
      return Pattern'Length > 0
        and then Ada.Strings.Fixed.Index (Text, Pattern) > 0;
   end Contains;

   function Contains_Forbidden_Pending_Payload_Marker
     (Text : String) return Boolean
   is
   begin
      return Contains (Text, "runtime_buffer_id=")
        or else Contains (Text, "runtime-buffer-id=")
        or else Contains (Text, "active_buffer_id=")
        or else Contains (Text, "active-buffer-id=")
        or else Contains (Text, "selected_buffer_id=")
        or else Contains (Text, "selected-buffer-id=")
        or else Contains (Text, "buffer_id=")
        or else Contains (Text, "buffer-id=")
        or else Contains (Text, "file_conflict_token=")
        or else Contains (Text, "file-conflict-token=")
        or else Contains (Text, "observed_file_token=")
        or else Contains (Text, "observed-file-token=");
   end Contains_Forbidden_Pending_Payload_Marker;

   function Target_Has_Revalidation_Key
     (Target : Pending_Transition_Target) return Boolean
   is
   begin
      case Target.Kind is
         when No_Pending_Transition =>
            return True;
         when Pending_Close_Buffer
            | Pending_Close_Other_Buffers
            | Pending_Reload_Active_Buffer
            | Pending_Revert_Active_Buffer =>
            return Target.Has_Buffer;
         when Pending_Close_All_Buffers =>
            return True;
         when Pending_Open_Project
            | Pending_Switch_Project
            | Pending_Open_Recent_Project
            | Pending_Restore_Workspace
            | Pending_Clear_Workspace_State =>
            return Target.Has_Path and then Length (Target.Path) > 0;
         when Pending_Close_Project
            | Pending_Clear_Project =>
            return Target.Has_Source_Path
              or else Target.Has_Path
              or else True;
      end case;
   end Target_Has_Revalidation_Key;

   function Audit_Pending_Transition_Boundary
     (State : Pending_Transition_State) return Pending_Transition_Boundary_Audit
   is
      Audit : Pending_Transition_Boundary_Audit;
      Text  : constant String := Display_Text (State);
      Target : constant Pending_Transition_Target := State.Target;
   begin
      Audit.Has_Pending := Has_Pending (State);
      if not Audit.Has_Pending then
         Audit.Boundary_Safe := True;
         return Audit;
      end if;

      Audit.Has_Runtime_Buffer_Id := Target.Has_Buffer;
      Audit.Has_File_Conflict_Token := Target.Has_Observed_File_Token;

      --  pending transitions may retain a runtime buffer id or an
      --  observed file token only as an in-process revalidation key.  The
      --  pending bar text is user copy only; it must not serialize or render
      --  structured runtime-buffer/file-token payload markers.
      Audit.Runtime_Buffer_Id_Is_Transient := True;
      Audit.Runtime_Buffer_Id_Not_Persisted := True;
      Audit.Runtime_Buffer_Id_Not_Command_Payload := True;
      Audit.Runtime_Buffer_Id_Not_Keybinding_Payload := True;
      Audit.Runtime_Buffer_Id_Not_Render_Payload :=
        not Contains_Forbidden_Pending_Payload_Marker (Text);
      Audit.File_Conflict_Token_Is_Transient := True;
      Audit.File_Conflict_Token_Not_Persisted := True;
      Audit.File_Conflict_Token_Not_Rendered :=
        not Contains_Forbidden_Pending_Payload_Marker (Text)
        and then (not Target.Has_Observed_File_Token
          or else not Contains (Text, To_String (Target.Observed_File_Token_Label)));
      Audit.Prompt_Display_Hides_Runtime_Buffer_Id :=
        not Contains_Forbidden_Pending_Payload_Marker (Text);
      Audit.Prompt_Display_Hides_File_Conflict_Token :=
        not Contains_Forbidden_Pending_Payload_Marker (Text)
        and then (not Target.Has_Observed_File_Token
          or else not Contains (Text, To_String (Target.Observed_File_Token_Label)));
      Audit.Pending_Target_Revalidation_Required := True;
      Audit.Pending_Target_Has_Revalidation_Key := Target_Has_Revalidation_Key (Target);

      Audit.Boundary_Safe :=
        Audit.Runtime_Buffer_Id_Not_Persisted
        and then Audit.Runtime_Buffer_Id_Not_Command_Payload
        and then Audit.Runtime_Buffer_Id_Not_Keybinding_Payload
        and then Audit.Runtime_Buffer_Id_Not_Render_Payload
        and then Audit.File_Conflict_Token_Not_Persisted
        and then Audit.File_Conflict_Token_Not_Rendered
        and then Audit.Prompt_Display_Hides_Runtime_Buffer_Id
        and then Audit.Prompt_Display_Hides_File_Conflict_Token
        and then Audit.Pending_Target_Has_Revalidation_Key;
      return Audit;
   end Audit_Pending_Transition_Boundary;

   function Display_Text
     (State : Pending_Transition_State) return String
   is
      Target : constant Pending_Transition_Target := State.Target;
      What   : Unbounded_String := Null_Unbounded_String;
      Actions : constant String := Confirmation_Action_Text (Target);
   begin
      if not Has_Pending (State) then
         return "";
      end if;

      case Target.Kind is
         when No_Pending_Transition =>
            return "";
         when Pending_Close_Buffer =>
            What := To_Unbounded_String ("buffer close");
         when Pending_Close_All_Buffers =>
            What := To_Unbounded_String ("closing all buffers");
         when Pending_Close_Other_Buffers =>
            What := To_Unbounded_String ("closing other buffers");
         when Pending_Reload_Active_Buffer =>
            What := To_Unbounded_String ("reloading buffer from disk");
         when Pending_Revert_Active_Buffer =>
            What := To_Unbounded_String ("reverting buffer");
         when Pending_Close_Project =>
            What := To_Unbounded_String ("closing project");
         when Pending_Clear_Project =>
            What := To_Unbounded_String ("clearing project context");
         when Pending_Clear_Workspace_State =>
            if Length (Target.Display) > 0 then
               return "Clear " & To_String (Target.Display)
                 & "? Retry to confirm or Cancel";
            elsif Target.Has_Path then
               return "Clear workspace state: " & To_String (Target.Path)
                 & "? Retry to confirm or Cancel";
            else
               return "Clear workspace state? Retry to confirm or Cancel";
            end if;
         when Pending_Open_Project | Pending_Switch_Project | Pending_Open_Recent_Project =>
            What := To_Unbounded_String ("project switch");
         when Pending_Restore_Workspace =>
            What := To_Unbounded_String ("workspace restore");
      end case;

      if Length (Target.Display) > 0 then
         return "Unsaved changes block " & To_String (What)
           & ": " & To_String (Target.Display)
           & " (" & Summary_Text (State.Summary)
           & ") — " & Actions;
      elsif Target.Has_Path then
         return "Unsaved changes block " & To_String (What)
           & ": " & To_String (Target.Path)
           & " (" & Summary_Text (State.Summary)
           & ") — " & Actions;
      end if;

      return "Unsaved changes block " & To_String (What)
        & " (" & Summary_Text (State.Summary) & ") — " & Actions;
   end Display_Text;

end Editor.Pending_Transitions;
