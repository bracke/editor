with Ada.Characters.Handling;
with Ada.Containers;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;
with GNAT.OS_Lib;
with Editor.Workspace_Persistence.Text_Format; use Editor.Workspace_Persistence.Text_Format;
with Editor.Workspace_Persistence.Path_Validation; use Editor.Workspace_Persistence.Path_Validation;
with Editor.Workspace_Persistence.Snapshot_Model; use Editor.Workspace_Persistence.Snapshot_Model;
with Editor.Workspace_Persistence.Parsing; use Editor.Workspace_Persistence.Parsing;
with Editor.Workspace_Persistence.File_IO; use Editor.Workspace_Persistence.File_IO;

package body Editor.Workspace_Persistence.Audits is

   use type Ada.Containers.Count_Type;
   use type Ada.Directories.File_Kind;

   function Audit_Serialized_Buffer_Persistence
     (Serialized_Workspace : String) return Workspace_Buffer_Persistence_Audit
   is
      Result  : Workspace_Buffer_Persistence_Audit;
      Section : Section_Id := Root_Section;

      function Canonical_Field_Name (Text : String) return String is
         use Ada.Characters.Handling;
         Trimmed : constant String := Trim (Text);
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

      function Field_Name_Of (Field : String) return String is
         Eq : constant Natural := Ada.Strings.Fixed.Index (Field, "=");
      begin
         if Eq = 0 then
            return Canonical_Field_Name (Field);
         elsif Eq = Field'First then
            return "";
         else
            return Canonical_Field_Name (Field (Field'First .. Eq - 1));
         end if;
      end Field_Name_Of;

      procedure Mark_Forbidden_Field (Raw_Name : String) is
         Name : constant String := Field_Name_Of (Raw_Name);
      begin
         if Name'Length = 0 then
            return;
         end if;

         if Name = "runtime-buffer-id"
           or else Name = "buffer-runtime-id"
           or else Name = "buffer-id"
           or else Name = "row-buffer-id"
           or else Name = "payload-buffer"
           or else Name = "payload-buffer-id"
         then
            Result.Runtime_Buffer_Id_Persisted := True;
         elsif Name = "active-buffer-id"
           or else Name = "active-runtime-buffer-id"
         then
            Result.Active_Buffer_Id_Persisted := True;
         elsif Name = "selected-buffer-id"
           or else Name = "selected-runtime-buffer-id"
         then
            Result.Selected_Buffer_Id_Persisted := True;
         elsif Name = "buffer-list"
           or else Name = "buffer-list-selection"
           or else Name = "buffer-list-selected"
           or else Name = "buffer-list-filter"
           or else Name = "buffer-list-row"
           or else Name = "buffer-list-state"
           or else Name = "selected-row"
           or else Name = "selected-buffer-row"
         then
            Result.Buffer_List_State_Persisted := True;
         elsif Name = "dirty-text"
           or else Name = "modified-text"
           or else Name = "dirty-buffer-text"
         then
            Result.Dirty_Text_Persisted := True;
         elsif Name = "scratch-text"
           or else Name = "scratch-buffer-text"
         then
            Result.Scratch_Text_Persisted := True;
         elsif Name = "conflict-token"
           or else Name = "file-conflict-token"
           or else Name = "observed-file-token"
           or else Name = "observed-file-status-code"
         then
            Result.Conflict_Token_Persisted := True;
         elsif Name = "close-prompt"
           or else Name = "close-prompt-state"
           or else Name = "pending-close"
           or else Name = "pending-close-buffer-ids"
           or else Name = "dirty-close-prompt-buffer-ids"
           or else Name = "file-conflict-prompt"
           or else Name = "file-conflict-prompt-state"
         then
            Result.Close_Prompt_State_Persisted := True;
         elsif Name = "undo-stack"
           or else Name = "redo-stack"
           or else Name = "clipboard"
           or else Name = "clipboard-text"
         then
            Result.Undo_Redo_Clipboard_Persisted := True;
         end if;
      end Mark_Forbidden_Field;

      procedure Audit_Bar_Separated_Metadata
        (Line      : String;
         First_Pos : Natural)
      is
         Pos  : Natural := First_Pos;
         Next : Natural;
      begin
         if First_Pos = 0 or else First_Pos > Line'Last then
            return;
         end if;

         while Pos <= Line'Last loop
            Next := Ada.Strings.Fixed.Index (Line (Pos .. Line'Last), "|");
            if Next = 0 then
               if Ada.Strings.Fixed.Index (Line (Pos .. Line'Last), "=") > 0 then
                  Mark_Forbidden_Field (Line (Pos .. Line'Last));
               end if;
               Pos := Line'Last + 1;
            else
               if Next > Pos
                 and then Ada.Strings.Fixed.Index (Line (Pos .. Next - 1), "=") > 0
               then
                  Mark_Forbidden_Field (Line (Pos .. Next - 1));
               end if;
               Pos := Next + 1;
            end if;
         end loop;
      end Audit_Bar_Separated_Metadata;

      procedure Audit_Structural_Line (Raw_Line : String) is
         Line : constant String := Trim (Raw_Line);
         Eq   : Natural;
         Bar  : Natural;
      begin
         if Line'Length = 0 then
            return;
         end if;

         if Line (Line'First) = '[' and then Line (Line'Last) = ']' then
            declare
               Name : constant String := Canonical_Field_Name
                 (Line (Line'First + 1 .. Line'Last - 1));
            begin
               if Name = "open-files" then
                  Section := Open_Files_Section;
               elsif Name = "active-file" then
                  Section := Active_File_Section;
               elsif Name = "file-tree-expanded" then
                  Section := File_Tree_Expanded_Section;
               elsif Name = "panels" then
                  Section := Panels_Section;
               elsif Name = "continuity" then
                  Section := Continuity_Section;
               else
                  Section := Unknown_Section;
                  --  Unknown sections are not blanket failures: old/future
                  --  workspace files may carry unrelated sections.  Only
                  --  structurally named buffer-runtime sections fail here.
                  Mark_Forbidden_Field (Name);
               end if;
               return;
            end;
         end if;

         case Section is
            when Root_Section | Panels_Section | Unknown_Section =>
               Eq := Ada.Strings.Fixed.Index (Line, "=");
               if Eq > 0 and then Eq > Line'First then
                  Mark_Forbidden_Field (Line (Line'First .. Eq - 1));
               end if;

            when Continuity_Section =>
               Eq := Ada.Strings.Fixed.Index (Line, "=");
               if Eq > 0 and then Eq > Line'First then
                  Mark_Forbidden_Field (Line (Line'First .. Eq - 1));
               end if;

            when Open_Files_Section | Active_File_Section =>
               Bar := Ada.Strings.Fixed.Index (Line, "|");
               if Bar > 0 then
                  Audit_Bar_Separated_Metadata (Line, Bar + 1);
               elsif Ada.Strings.Fixed.Index (Line, "=") > 0 then
                  --  A key/value row in an open-file section is metadata, not
                  --  a path reference, so audit the field name structurally.
                  Mark_Forbidden_Field (Line);
               end if;

            when File_Tree_Expanded_Section =>
               --  Expanded paths are structural path references.  Do not scan
               --  path values for forbidden words; only explicit metadata after
               --  a separator is audited as persisted fields.
               Bar := Ada.Strings.Fixed.Index (Line, "|");
               if Bar > 0 then
                  Audit_Bar_Separated_Metadata (Line, Bar + 1);
               end if;
         end case;
      end Audit_Structural_Line;

      Pos : Natural := Serialized_Workspace'First;
      LF  : Natural;
   begin
      while Pos <= Serialized_Workspace'Last loop
         LF := Ada.Strings.Fixed.Index
           (Serialized_Workspace (Pos .. Serialized_Workspace'Last),
            (1 => Character'Val (10)));
         if LF = 0 then
            Audit_Structural_Line
              (Serialized_Workspace (Pos .. Serialized_Workspace'Last));
            Pos := Serialized_Workspace'Last + 1;
         else
            Audit_Structural_Line (Serialized_Workspace (Pos .. LF - 1));
            Pos := LF + 1;
         end if;
      end loop;

      Result.Safe :=
        not Result.Runtime_Buffer_Id_Persisted
        and then not Result.Active_Buffer_Id_Persisted
        and then not Result.Selected_Buffer_Id_Persisted
        and then not Result.Buffer_List_State_Persisted
        and then not Result.Dirty_Text_Persisted
        and then not Result.Scratch_Text_Persisted
        and then not Result.Conflict_Token_Persisted
        and then not Result.Close_Prompt_State_Persisted
        and then not Result.Undo_Redo_Clipboard_Persisted;

      return Result;
   end Audit_Serialized_Buffer_Persistence;


   function Audit_Buffer_Persistence
     (Snapshot : Workspace_Snapshot) return Workspace_Buffer_Persistence_Audit
   is
   begin
      return Audit_Serialized_Buffer_Persistence (Serialized_Text (Snapshot));
   end Audit_Buffer_Persistence;

   function Restore_Details_Label
     (Summary : Workspace_Restore_Summary) return String
   is
   begin
      return "restore details: files " & Natural_Text (Summary.Files_Restored)
        & "/" & Natural_Text (Summary.Files_Requested)
        & ", skipped files " & Natural_Text (Summary.Files_Skipped)
        & ", expanded paths " & Natural_Text (Summary.Expansions_Restored)
        & "/" & Natural_Text (Summary.Expansions_Requested)
        & ", skipped expanded paths " & Natural_Text (Summary.Expansions_Skipped)
        & ", clamped panels " & Natural_Text (Summary.Panel_Values_Clamped);
   end Restore_Details_Label;

   function Audit_Restore_Roundtrip
     (Before  : Workspace_Snapshot;
      After   : Workspace_Snapshot;
      Summary : Workspace_Restore_Summary) return Workspace_Restore_Audit
   is
      Normalized_Before : Workspace_Snapshot := Before;
      Normalized_After  : Workspace_Snapshot := After;
      Buffer_Audit      : Workspace_Buffer_Persistence_Audit;
      Result            : Workspace_Restore_Audit;
   begin
      Normalize (Normalized_Before);
      Normalize (Normalized_After);
      Buffer_Audit := Audit_Buffer_Persistence (Normalized_After);

      Result.Snapshots_Equivalent := Equivalent (Normalized_Before, Normalized_After);
      Result.Runtime_State_Excluded := Buffer_Audit.Safe;
      Result.Restore_Counts_Coherent :=
        Summary.Files_Restored <= Summary.Files_Requested
        and then Summary.Files_Skipped <= Summary.Files_Requested
        and then Summary.Files_Restored + Summary.Files_Skipped =
          Summary.Files_Requested
        and then Summary.Expansions_Restored <= Summary.Expansions_Requested
        and then Summary.Expansions_Skipped <= Summary.Expansions_Requested
        and then Summary.Expansions_Restored + Summary.Expansions_Skipped =
          Summary.Expansions_Requested;
      Result.Continuity_State_Restored :=
        Normalized_Before.Has_Recent_Project = Normalized_After.Has_Recent_Project
        and then To_String (Normalized_Before.Recent_Project) =
          To_String (Normalized_After.Recent_Project)
        and then To_String (Normalized_Before.Quick_Open_Scope) =
          To_String (Normalized_After.Quick_Open_Scope)
        and then Normalized_Before.Quick_Open_Filter =
          Normalized_After.Quick_Open_Filter
        and then Normalized_Before.Feature_Panel_Visible =
          Normalized_After.Feature_Panel_Visible
        and then Normalized_Before.Active_Feature_Panel =
          Normalized_After.Active_Feature_Panel;
      Result.Safe := Result.Snapshots_Equivalent
        and then Result.Runtime_State_Excluded
        and then Result.Restore_Counts_Coherent
        and then Result.Continuity_State_Restored;
      return Result;
   end Audit_Restore_Roundtrip;



end Editor.Workspace_Persistence.Audits;
