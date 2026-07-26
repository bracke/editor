with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Commands.Descriptors; use Editor.Commands.Descriptors;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands.Workflow_Messages;

with Editor.Commands.Name_Metadata;



package body Editor.Commands.Reference_Metadata is

   type Command_Reference_Metadata is record
      Summary : Unbounded_String;
      Availability_Summary : Unbounded_String;
      Mutation_Summary : Unbounded_String;
      Filesystem_Effect_Summary : Unbounded_String;
      State_Preservation_Summary : Unbounded_String;
      Non_Goal_Summary : Unbounded_String;
      Family : Command_Family_Id;
      Effect_Classification : Command_Effect_Classification_Id;
   end record;

   Empty_Command_Reference_Metadata : constant Command_Reference_Metadata :=
     (Summary => To_Unbounded_String (""),
      Availability_Summary => To_Unbounded_String (""),
      Mutation_Summary => To_Unbounded_String (""),
      Filesystem_Effect_Summary => To_Unbounded_String (""),
      State_Preservation_Summary => To_Unbounded_String (""),
      Non_Goal_Summary => To_Unbounded_String (""),
      Family => No_Command_Family,
      Effect_Classification => No_Command_Effect);

   function Canonical_Command_Reference_Metadata
     (Id : Command_Id) return Command_Reference_Metadata
   is
   begin
      case Id is
         when Command_Save_File =>
            return
              (Summary => To_Unbounded_String ("Saves the active buffer to its current associated file path."),
               Availability_Summary => To_Unbounded_String ("Requires an active associated buffer that can be saved."),
               Mutation_Summary => To_Unbounded_String ("Updates the active buffer save baseline and dirty state only after a successful write."),
               Filesystem_Effect_Summary => To_Unbounded_String ("Writes active buffer text to the current associated file path."),
               State_Preservation_Summary => To_Unbounded_String ("Preserves open-buffer identity, text content, selection, clipboard, find state, and visible feature panels."),
               Non_Goal_Summary => To_Unbounded_String ("Does not choose a new target path or save every buffer."),
               Family => File_Lifecycle_Family,
               Effect_Classification => Writes_Buffer_Text_To_Associated_File);
         when Command_Save_File_As =>
            return
              (Summary => To_Unbounded_String ("Saves the active buffer to an explicit target path and associates the buffer with that path after success."),
               Availability_Summary => To_Unbounded_String ("Requires an active buffer and an explicit non-empty target path."),
               Mutation_Summary => To_Unbounded_String ("Updates the active buffer association, save baseline, and dirty state only after a successful explicit-target write."),
               Filesystem_Effect_Summary => To_Unbounded_String ("Writes active buffer text to an explicit target path."),
               State_Preservation_Summary => To_Unbounded_String ("Preserves text and current editor UI state while changing association after successful write."),
               Non_Goal_Summary => To_Unbounded_String ("Does not rename or move the existing backing file, infer a target path, or prompt from hidden details."),
               Family => File_Lifecycle_Family,
               Effect_Classification => Writes_Buffer_Text_To_Explicit_Target_And_Associates);
         when Command_Close_Active_Buffer =>
            return
              (Summary => To_Unbounded_String ("Closes the active buffer only when it is safe under the retained dirty-buffer policy."),
               Availability_Summary => To_Unbounded_String ("Requires an active buffer that may be closed under the dirty-buffer review policy."),
               Mutation_Summary => To_Unbounded_String ("Removes the active buffer from the open-buffer set and may create a safe reopen candidate."),
               Filesystem_Effect_Summary => To_Unbounded_String ("Performs no filesystem operation."),
               State_Preservation_Summary => To_Unbounded_String ("Preserves unrelated buffers and project/configuration domains; closes only the selected safe buffer."),
               Non_Goal_Summary => To_Unbounded_String ("Does not delete the associated file, force-close dirty buffers, or persist closed-buffer history."),
               Family => File_Lifecycle_Family,
               Effect_Classification => Closes_Active_Buffer);
         when Command_Confirm_Close_Save
            | Command_Confirm_Close_Discard
            | Command_Cancel_Close =>
            return
              (Summary => To_Unbounded_String ("Resolves the dirty-buffer close review through an explicit user action."),
               Availability_Summary => To_Unbounded_String ("Requires an active dirty close prompt."),
               Mutation_Summary => To_Unbounded_String ("Save and discard confirmations recheck the selected buffer before closing; cancel clears only the prompt."),
               Filesystem_Effect_Summary => To_Unbounded_String ("Save confirmation may write dirty file-backed buffers; discard and cancel write nothing."),
               State_Preservation_Summary => To_Unbounded_String ("Preserves dirty text on cancel, stale targets, conflicts, and save failures."),
               Non_Goal_Summary => To_Unbounded_String ("Does not remember close requests, store dirty text, delete files, or show generated buffer names in commands or keybindings."),
               Family => File_Lifecycle_Family,
               Effect_Classification => Closes_Active_Buffer);
         when Command_Reopen_Closed_Buffer =>
            return
              (Summary => To_Unbounded_String ("Reopens the latest safe closed-buffer file reference through canonical file-open behavior."),
               Availability_Summary => To_Unbounded_String ("Requires a safe transient reopen candidate for a recently closed file."),
               Mutation_Summary => To_Unbounded_String ("Uses the safe reopen candidate through normal open behavior and creates or activates the reopened buffer."),
               Filesystem_Effect_Summary => To_Unbounded_String ("Reads the reopen candidate through canonical file-open behavior."),
               State_Preservation_Summary => To_Unbounded_String ("Uses normal open behavior and does not restore command-reference or operation-history state."),
               Non_Goal_Summary => To_Unbounded_String ("Does not restore unsaved closed-buffer memory, watch files, repair missing files, or remember reopen history."),
               Family => File_Lifecycle_Family,
               Effect_Classification => Reopens_Safe_File_Reference);
         when Command_Reload_Active_Buffer =>
            return
              (Summary => To_Unbounded_String ("Reloads the active clean associated buffer from disk without discarding dirty text."),
               Availability_Summary => To_Unbounded_String ("Requires an active clean associated buffer; dirty buffers are blocked before disk reread."),
               Mutation_Summary => To_Unbounded_String ("Replaces active clean buffer text and saved baseline from the associated file after a successful read."),
               Filesystem_Effect_Summary => To_Unbounded_String ("Reads the current associated file path."),
               State_Preservation_Summary => To_Unbounded_String ("Preserves unrelated buffers and current UI state; blocked dirty reload preserves dirty text."),
               Non_Goal_Summary => To_Unbounded_String ("Does not discard dirty text; use revert for explicit discard."),
               Family => File_Lifecycle_Family,
               Effect_Classification => Rereads_Associated_File);
         when Command_Revert_Active_Buffer =>
            return
              (Summary => To_Unbounded_String ("Explicitly discards unsaved changes in the active dirty associated buffer and rereads from disk."),
               Availability_Summary => To_Unbounded_String ("Requires an active dirty associated buffer and an explicit revert command invocation."),
               Mutation_Summary => To_Unbounded_String ("Replaces dirty active buffer text with disk contents and clears dirty state after a successful read."),
               Filesystem_Effect_Summary => To_Unbounded_String ("Reads the current associated file path after explicit discard intent."),
               State_Preservation_Summary => To_Unbounded_String ("Preserves unrelated buffers and current UI state while intentionally replacing dirty active text."),
               Non_Goal_Summary => To_Unbounded_String ("Does not autosave, create recovery snapshots, or affect unrelated buffers."),
               Family => File_Lifecycle_Family,
               Effect_Classification => Discards_Unsaved_Changes_And_Rereads);
         when Command_File_Conflict_Keep_Buffer
            | Command_File_Conflict_Reload_From_Disk
            | Command_File_Conflict_Overwrite_Disk
            | Command_File_Conflict_Cancel =>
            return
              (Summary => To_Unbounded_String ("Resolves the active file-conflict prompt through an explicit user action."),
               Availability_Summary => To_Unbounded_String ("Requires an active file conflict prompt."),
               Mutation_Summary => To_Unbounded_String ("Changes files only after the current prompt is confirmed; cancel and keep write nothing."),
               Filesystem_Effect_Summary => To_Unbounded_String ("May read or write only for explicit reload/overwrite conflict actions."),
               State_Preservation_Summary => To_Unbounded_String ("Preserves dirty buffer text on cancel, keep, stale prompt, and filesystem failure."),
               Non_Goal_Summary => To_Unbounded_String ("Does not store paths, generated buffer names, conflict details, or text in keybindings or Command Palette."),
               Family => File_Lifecycle_Family,
               Effect_Classification => Rereads_Associated_File);
         when Command_Rename_Buffer_File =>
            return
              (Summary => To_Unbounded_String ("Renames the active clean associated backing file to an explicit target path and updates association after filesystem success."),
               Availability_Summary => To_Unbounded_String ("Requires an active clean associated buffer and a valid explicit target path that does not already exist."),
               Mutation_Summary => To_Unbounded_String ("Updates active buffer association only after filesystem rename success; preserves text, saved baseline, and dirty state."),
               Filesystem_Effect_Summary => To_Unbounded_String ("Renames the current associated backing file to the explicit target path."),
               State_Preservation_Summary => To_Unbounded_String ("Preserves active text, saved baseline, dirty state, open-buffer identity, and unrelated buffers."),
               Non_Goal_Summary => To_Unbounded_String ("Does not write buffer text, overwrite targets, rename dirty buffers, open the target separately, or rename project files."),
               Family => File_Lifecycle_Family,
               Effect_Classification => Renames_Associated_File);
         when Command_Delete_Buffer_File =>
            return
              (Summary => To_Unbounded_String ("Deletes the active clean associated backing file, preserves text in memory, and clears association after filesystem success."),
               Availability_Summary => To_Unbounded_String ("Requires an active clean associated buffer; dirty associated files cannot be deleted by this command."),
               Mutation_Summary => To_Unbounded_String ("Clears active buffer association only after filesystem delete success; preserves text and leaves the buffer open under the no-associated-file policy."),
               Filesystem_Effect_Summary => To_Unbounded_String ("Deletes the current associated backing file."),
               State_Preservation_Summary => To_Unbounded_String ("Preserves active text and open-buffer identity; the no-associated-file policy marks retained text dirty."),
               Non_Goal_Summary => To_Unbounded_String ("Does not delete dirty buffers, close the buffer, move files to trash, or create recovery records."),
               Family => File_Lifecycle_Family,
               Effect_Classification => Deletes_Associated_File);
         when Command_Copy_Buffer_File =>
            return
              (Summary => To_Unbounded_String ("Copies the active clean associated backing file to an explicit target path without changing association."),
               Availability_Summary => To_Unbounded_String ("Requires an active clean associated buffer and a valid explicit target path that does not already exist."),
               Mutation_Summary => To_Unbounded_String ("Does not mutate association; Preserves active buffer association, text, saved baseline, dirty state, and open-buffer collection on success."),
               Filesystem_Effect_Summary => To_Unbounded_String ("Copies the current associated backing file to the explicit target path."),
               State_Preservation_Summary => To_Unbounded_String ("Preserves active association, text, saved baseline, dirty state, open-buffer identity, and unrelated buffers."),
               Non_Goal_Summary => To_Unbounded_String ("Does not overwrite targets, copy dirty buffers, adopt the target, or open the copied file."),
               Family => File_Lifecycle_Family,
               Effect_Classification => Copies_Associated_File);
         when Command_Move_Buffer_File =>
            return
              (Summary => To_Unbounded_String ("Moves the active clean associated backing file to an explicit target path and updates association after filesystem success."),
               Availability_Summary => To_Unbounded_String ("Requires an active clean associated buffer and a valid explicit target path that does not already exist."),
               Mutation_Summary => To_Unbounded_String ("Updates active buffer association only after filesystem move success; preserves text, saved baseline, and dirty state."),
               Filesystem_Effect_Summary => To_Unbounded_String ("Moves the current associated backing file to the explicit target path."),
               State_Preservation_Summary => To_Unbounded_String ("Preserves active text, saved baseline, dirty state, open-buffer identity, and unrelated buffers."),
               Non_Goal_Summary => To_Unbounded_String ("Does not write buffer text, overwrite targets, move dirty buffers, open the moved file separately, or copy-then-delete as a public command."),
               Family => File_Lifecycle_Family,
               Effect_Classification => Moves_Associated_File);
         when others =>
            return Empty_Command_Reference_Metadata;
      end case;
   end Canonical_Command_Reference_Metadata;

   function Is_File_Lifecycle_Command
     (Id : Command_Id) return Boolean
   is
   begin
      case Id is
         when Command_Save_File
            | Command_Save_File_As
            | Command_Close_Active_Buffer
            | Command_Confirm_Close_Save
            | Command_Confirm_Close_Discard
            | Command_Cancel_Close
            | Command_Reopen_Closed_Buffer
            | Command_Reload_Active_Buffer
            | Command_Revert_Active_Buffer
            | Command_File_Conflict_Keep_Buffer
            | Command_File_Conflict_Reload_From_Disk
            | Command_File_Conflict_Overwrite_Disk
            | Command_File_Conflict_Cancel
            | Command_Rename_Buffer_File
            | Command_Delete_Buffer_File
            | Command_Copy_Buffer_File
            | Command_Move_Buffer_File =>
            return True;
         when others =>
            return False;
      end case;
   end Is_File_Lifecycle_Command;

   function Reference_Summary
     (Id : Command_Id) return String
   is
      M : constant Command_Reference_Metadata := Canonical_Command_Reference_Metadata (Id);
   begin
      return To_String (M.Summary);
   end Reference_Summary;

   function Reference_Availability_Summary
     (Id : Command_Id) return String
   is
      M : constant Command_Reference_Metadata := Canonical_Command_Reference_Metadata (Id);
   begin
      return To_String (M.Availability_Summary);
   end Reference_Availability_Summary;

   function Reference_Mutation_Summary
     (Id : Command_Id) return String
   is
      M : constant Command_Reference_Metadata := Canonical_Command_Reference_Metadata (Id);
   begin
      return To_String (M.Mutation_Summary);
   end Reference_Mutation_Summary;

   function Reference_Filesystem_Effect_Summary
     (Id : Command_Id) return String
   is
      M : constant Command_Reference_Metadata := Canonical_Command_Reference_Metadata (Id);
   begin
      return To_String (M.Filesystem_Effect_Summary);
   end Reference_Filesystem_Effect_Summary;

   function Reference_State_Preservation_Summary
     (Id : Command_Id) return String
   is
      M : constant Command_Reference_Metadata := Canonical_Command_Reference_Metadata (Id);
   begin
      return To_String (M.State_Preservation_Summary);
   end Reference_State_Preservation_Summary;

   function Reference_Non_Goal_Summary
     (Id : Command_Id) return String
   is
      M : constant Command_Reference_Metadata := Canonical_Command_Reference_Metadata (Id);
   begin
      return To_String (M.Non_Goal_Summary);
   end Reference_Non_Goal_Summary;

   function Reference_Command_Family
     (Id : Command_Id) return Command_Family_Id
   is
      M : constant Command_Reference_Metadata := Canonical_Command_Reference_Metadata (Id);
   begin
      return M.Family;
   end Reference_Command_Family;

   function Reference_Effect_Classification
     (Id : Command_Id) return Command_Effect_Classification_Id
   is
      M : constant Command_Reference_Metadata := Canonical_Command_Reference_Metadata (Id);
   begin
      return M.Effect_Classification;
   end Reference_Effect_Classification;

   type Minimal_Target_Prompt_Metadata is record
      Requires_Explicit_Target : Boolean := False;
      Target_Prompt_Capable    : Boolean := False;
      Target_Prompt_Label      : Unbounded_String := Null_Unbounded_String;
   end record;

   Empty_Target_Prompt_Metadata : constant Minimal_Target_Prompt_Metadata :=
     (Requires_Explicit_Target => False,
      Target_Prompt_Capable    => False,
      Target_Prompt_Label      => Null_Unbounded_String);

   function Canonical_Target_Prompt_Metadata
     (Id : Command_Id) return Minimal_Target_Prompt_Metadata
   is
      function Metadata (Label : String) return Minimal_Target_Prompt_Metadata is
      begin
         return
           (Requires_Explicit_Target => True,
            Target_Prompt_Capable    => True,
            Target_Prompt_Label      => To_Unbounded_String (Label));
      end Metadata;
   begin
      case Id is
         when Command_Save_File_As =>
            return Metadata ("Save As target");
         when Command_Rename_Buffer_File =>
            return Metadata ("Rename target");
         when Command_Copy_Buffer_File =>
            return Metadata ("Copy target");
         when Command_Move_Buffer_File =>
            return Metadata ("Move target");
         when others =>
            return Empty_Target_Prompt_Metadata;
      end case;
   end Canonical_Target_Prompt_Metadata;

   function Command_Requires_Explicit_Target
     (Id : Command_Id) return Boolean
   is
   begin
      return Canonical_Target_Prompt_Metadata (Id).Requires_Explicit_Target;
   end Command_Requires_Explicit_Target;

   function Command_Is_Target_Prompt_Capable
     (Id : Command_Id) return Boolean
   is
   begin
      return Canonical_Target_Prompt_Metadata (Id).Target_Prompt_Capable;
   end Command_Is_Target_Prompt_Capable;

   function Command_Target_Prompt_Label
     (Id : Command_Id) return String
   is
   begin
      return To_String (Canonical_Target_Prompt_Metadata (Id).Target_Prompt_Label);
   end Command_Target_Prompt_Label;

   function Command_Summary
     (Id : Command_Id) return String is (Reference_Summary (Id));

   function Command_Availability_Summary
     (Id : Command_Id) return String is (Reference_Availability_Summary (Id));

   function Command_Mutation_Summary
     (Id : Command_Id) return String is (Reference_Mutation_Summary (Id));

   function Command_Filesystem_Effect_Summary
     (Id : Command_Id) return String is (Reference_Filesystem_Effect_Summary (Id));

   function Command_State_Preservation_Summary
     (Id : Command_Id) return String is (Reference_State_Preservation_Summary (Id));

   function Command_Non_Goal_Summary
     (Id : Command_Id) return String is (Reference_Non_Goal_Summary (Id));

   function Command_Family
     (Id : Command_Id) return Command_Family_Id is (Reference_Command_Family (Id));

   function Command_Effect_Classification
     (Id : Command_Id) return Command_Effect_Classification_Id is
       (Reference_Effect_Classification (Id));

   function Command_Family_Label
     (Family : Command_Family_Id) return String
   is
   begin
      case Family is
         when File_Lifecycle_Family =>
            return "File Operations";
         when No_Command_Family =>
            return "";
      end case;
   end Command_Family_Label;

   function Command_Effect_Classification_Label
     (Effect : Command_Effect_Classification_Id) return String
   is
   begin
      case Effect is
         when Writes_Buffer_Text_To_Associated_File =>
            return "writes-buffer-text-to-associated-file";
         when Writes_Buffer_Text_To_Explicit_Target_And_Associates =>
            return "writes-buffer-text-to-explicit-target-and-associates";
         when Closes_Active_Buffer =>
            return "closes-active-buffer";
         when Reopens_Safe_File_Reference =>
            return "reopens-safe-file-reference";
         when Rereads_Associated_File =>
            return "rereads-associated-file";
         when Discards_Unsaved_Changes_And_Rereads =>
            return "discards-unsaved-changes-and-rereads";
         when Renames_Associated_File =>
            return "renames-associated-file";
         when Deletes_Associated_File =>
            return "deletes-associated-file";
         when Copies_Associated_File =>
            return "copies-associated-file";
         when Moves_Associated_File =>
            return "moves-associated-file";
         when No_Command_Effect =>
            return "";
      end case;
   end Command_Effect_Classification_Label;

   function File_Lifecycle_Target_Prompt_Metadata_Minimal return Boolean
   is
      Covered : constant array (Positive range 1 .. 10) of Command_Id :=
        (Command_Save_File,
         Command_Save_File_As,
         Command_Close_Active_Buffer,
         Command_Reopen_Closed_Buffer,
         Command_Reload_Active_Buffer,
         Command_Revert_Active_Buffer,
         Command_Rename_Buffer_File,
         Command_Delete_Buffer_File,
         Command_Copy_Buffer_File,
         Command_Move_Buffer_File);

      D : Command_Descriptor;
      M : Minimal_Target_Prompt_Metadata;
      Prompt_Capable_Count : Natural := 0;
   begin
      for Id of Covered loop
         D := Descriptor (Id);
         M := Canonical_Target_Prompt_Metadata (Id);

         if D.Requires_Explicit_Target /= M.Requires_Explicit_Target
           or else D.Target_Prompt_Capable /= M.Target_Prompt_Capable
           or else To_String (D.Target_Prompt_Label) /= To_String (M.Target_Prompt_Label)
           or else D.Requires_Explicit_Target /= Command_Requires_Explicit_Target (Id)
           or else D.Target_Prompt_Capable /= Command_Is_Target_Prompt_Capable (Id)
           or else To_String (D.Target_Prompt_Label) /= Command_Target_Prompt_Label (Id)
         then
            return False;
         end if;

         if M.Target_Prompt_Capable then
            Prompt_Capable_Count := Prompt_Capable_Count + 1;
            if not M.Requires_Explicit_Target
              or else To_String (M.Target_Prompt_Label)'Length = 0
            then
               return False;
            end if;
         elsif M.Requires_Explicit_Target
           or else To_String (M.Target_Prompt_Label)'Length /= 0
         then
            return False;
         end if;
      end loop;

      if Prompt_Capable_Count /= 4 then
         return False;
      end if;

      for Id in Command_Id loop
         M := Canonical_Target_Prompt_Metadata (Id);
         if (Command_Requires_Explicit_Target (Id) /= M.Requires_Explicit_Target)
           or else (Command_Is_Target_Prompt_Capable (Id) /= M.Target_Prompt_Capable)
           or else (Command_Target_Prompt_Label (Id) /= To_String (M.Target_Prompt_Label))
         then
            return False;
         end if;

         if M.Target_Prompt_Capable
           and then not Is_File_Lifecycle_Command (Id)
         then
            return False;
         end if;
      end loop;

      return True;
   end File_Lifecycle_Target_Prompt_Metadata_Minimal;

   function File_Lifecycle_Target_Prompt_Metadata_Canonical_And_Minimal
     return Boolean
   is
   begin
      return File_Lifecycle_Target_Prompt_Metadata_Minimal;
   end File_Lifecycle_Target_Prompt_Metadata_Canonical_And_Minimal;

   function File_Lifecycle_Target_Prompt_Metadata_Frozen return Boolean
   is
      type Expected_Metadata is record
         Id       : Command_Id;
         Name     : Unbounded_String;
         Required : Boolean;
         Capable  : Boolean;
         Label    : Unbounded_String;
      end record;

      Expected : constant array (Positive range 1 .. 14) of Expected_Metadata :=
        ((Command_Save_File, To_Unbounded_String ("file.save"), False, False, Null_Unbounded_String),
         (Command_Save_File_As, To_Unbounded_String ("file.save-as"), True, True, To_Unbounded_String ("Save As target")),
         (Command_Close_Active_Buffer, To_Unbounded_String ("file.close-buffer"), False, False, Null_Unbounded_String),
         (Command_Reopen_Closed_Buffer, To_Unbounded_String ("file.reopen-closed-buffer"), False, False, Null_Unbounded_String),
         (Command_Reload_Active_Buffer, To_Unbounded_String ("file.reload-buffer"), False, False, Null_Unbounded_String),
         (Command_Revert_Active_Buffer, To_Unbounded_String ("file.revert-buffer"), False, False, Null_Unbounded_String),
         (Command_File_Conflict_Keep_Buffer, To_Unbounded_String ("file-conflict.keep-buffer"), False, False, Null_Unbounded_String),
         (Command_File_Conflict_Reload_From_Disk, To_Unbounded_String ("file-conflict.reload-from-disk"), False, False, Null_Unbounded_String),
         (Command_File_Conflict_Overwrite_Disk, To_Unbounded_String ("file-conflict.overwrite-disk"), False, False, Null_Unbounded_String),
         (Command_File_Conflict_Cancel, To_Unbounded_String ("file-conflict.cancel"), False, False, Null_Unbounded_String),
         (Command_Rename_Buffer_File, To_Unbounded_String ("file.rename-buffer-file"), True, True, To_Unbounded_String ("Rename target")),
         (Command_Delete_Buffer_File, To_Unbounded_String ("file.delete-buffer-file"), False, False, Null_Unbounded_String),
         (Command_Copy_Buffer_File, To_Unbounded_String ("file.copy-buffer-file"), True, True, To_Unbounded_String ("Copy target")),
         (Command_Move_Buffer_File, To_Unbounded_String ("file.move-buffer-file"), True, True, To_Unbounded_String ("Move target")));

      Prompt_Capable_Count : Natural := 0;
      Required_Count       : Natural := 0;

      function Prompted_Name_Absent (Name : String) return Boolean
      is
         Found : Boolean := False;
         Id    : Command_Id := No_Command;
      begin
         Id := Name_Metadata.Command_Id_From_Stable_Name (Name, Found);
         return (not Found) and then Id = No_Command;
      end Prompted_Name_Absent;
   begin
      if not File_Lifecycle_Target_Prompt_Metadata_Canonical_And_Minimal then
         return False;
      end if;

      for E of Expected loop
         declare
            D : constant Command_Descriptor := Descriptor (E.Id);
         begin
            if D.Id /= E.Id
              or else Name_Metadata.Stable_Command_Name (E.Id) /= To_String (E.Name)
              or else D.Requires_Explicit_Target /= E.Required
              or else D.Target_Prompt_Capable /= E.Capable
              or else To_String (D.Target_Prompt_Label) /= To_String (E.Label)
              or else Command_Requires_Explicit_Target (E.Id) /= E.Required
              or else Command_Is_Target_Prompt_Capable (E.Id) /= E.Capable
              or else Command_Target_Prompt_Label (E.Id) /= To_String (E.Label)
            then
               return False;
            end if;

            if E.Required then
               Required_Count := Required_Count + 1;
            end if;
            if E.Capable then
               Prompt_Capable_Count := Prompt_Capable_Count + 1;
               if To_String (E.Label)'Length = 0 then
                  return False;
               end if;
            elsif To_String (E.Label)'Length /= 0 then
               return False;
            end if;
         end;
      end loop;

      if Required_Count /= 4 or else Prompt_Capable_Count /= 4 then
         return False;
      end if;

      for Id in Command_Id loop
         if Command_Is_Target_Prompt_Capable (Id)
           and then Id not in Command_Save_File_As
                        | Command_Rename_Buffer_File
                        | Command_Copy_Buffer_File
                        | Command_Move_Buffer_File
         then
            return False;
         end if;

         if Command_Requires_Explicit_Target (Id)
           and then not Command_Is_Target_Prompt_Capable (Id)
         then
            return False;
         end if;

         if (not Command_Is_Target_Prompt_Capable (Id))
           and then Command_Target_Prompt_Label (Id)'Length /= 0
         then
            return False;
         end if;
      end loop;

      return Prompted_Name_Absent ("file.save-as-prompt")
        and then Prompted_Name_Absent ("file.prompt-save-as")
        and then Prompted_Name_Absent ("file.rename-buffer-file-prompt")
        and then Prompted_Name_Absent ("file.copy-buffer-file-prompt")
        and then Prompted_Name_Absent ("file.move-buffer-file-prompt")
        and then Prompted_Name_Absent ("file.save-as-with-target-prompt")
        and then Prompted_Name_Absent ("file.rename-with-target-prompt")
        and then Prompted_Name_Absent ("file.copy-with-target-prompt")
        and then Prompted_Name_Absent ("file.move-with-target-prompt")
        and then Prompted_Name_Absent ("prompt.file.save-as")
        and then Prompted_Name_Absent ("prompt.file.rename-buffer-file")
        and then Prompted_Name_Absent ("prompt.file.copy-buffer-file")
        and then Prompted_Name_Absent ("prompt.file.move-buffer-file")
        and then Prompted_Name_Absent ("leg" & "acy.file-target-prompt");
   end File_Lifecycle_Target_Prompt_Metadata_Frozen;

end Editor.Commands.Reference_Metadata;
