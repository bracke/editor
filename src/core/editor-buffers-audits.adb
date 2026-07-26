with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.State;
with Editor.Dirty_Guards;
with Editor.Project;

package body Editor.Buffers.Audits is

   function Counted_Label
     (Count    : Natural;
      Singular : String;
      Plural   : String) return String
   is
   begin
      if Count = 1 then
         return Natural'Image (Count) & " " & Singular & ".";
      else
         return Natural'Image (Count) & " " & Plural & ".";
      end if;
   end Counted_Label;

   function Trim_Count_Label (Value : String) return String is
   begin
      if Value'Length > 0 and then Value (Value'First) = ' ' then
         return Value (Value'First + 1 .. Value'Last);
      else
         return Value;
      end if;
   end Trim_Count_Label;

   function Project_Lifecycle_Buffer_Sets
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State) return Buffer_Project_Lifecycle_Sets
   is
      Result : Buffer_Project_Lifecycle_Sets;
   begin
      if Registry.Items.Is_Empty then
         return Result;
      end if;

      for Item of Registry.Items loop
         if Item.State /= null then
            declare
               M : constant Buffer_Metadata_Snapshot :=
                 Metadata_For (Registry, Project, Item.Id);
            begin
               case M.Ownership is
                  when Buffer_Project_Owned =>
                     Result.Project_Owned.Append (Item.Id);
                     Result.Project_Close_Affected.Append (Item.Id);
                     if M.Is_Dirty then
                        Result.Project_Owned_Dirty.Append (Item.Id);
                     else
                        Result.Project_Owned_Clean.Append (Item.Id);
                     end if;

                  when Buffer_Outside_Project =>
                     Result.Outside_Project.Append (Item.Id);
                     Result.Project_Close_Unaffected.Append (Item.Id);

                  when Buffer_Scratch_Unbacked =>
                     Result.Scratch.Append (Item.Id);
                     Result.Project_Close_Unaffected.Append (Item.Id);

                  when Buffer_Missing_Project_Context |
                       Buffer_Unknown_File_Backed =>
                     null;
               end case;
            end;
         end if;
      end loop;

      return Result;
   end Project_Lifecycle_Buffer_Sets;

   function Audit_Buffers
     (Registry    : Buffer_Registry;
      Project     : Editor.Project.Project_State;
      Selected_Id : Buffer_Id := No_Buffer) return Buffer_Audit_Summary
   is
      Result : Buffer_Audit_Summary;
   begin
      Result.Buffer_Count := Count (Registry);
      Result.Active_Buffer_Valid :=
        (Registry.Active = No_Buffer and then Registry.Items.Is_Empty)
        or else Contains (Registry, Registry.Active);
      Result.Selected_Buffer_Valid :=
        Selected_Id = No_Buffer or else Contains (Registry, Selected_Id);

      if not Registry.Items.Is_Empty then
         for Item of Registry.Items loop
            declare
               M : constant Buffer_Metadata_Snapshot :=
                 Metadata_For (Registry, Project, Item.Id, Selected_Id);
            begin
               case M.Ownership is
                  when Buffer_Project_Owned =>
                     Result.Project_Owned_Count := Result.Project_Owned_Count + 1;
                  when Buffer_Outside_Project =>
                     Result.Outside_Project_Count := Result.Outside_Project_Count + 1;
                  when Buffer_Scratch_Unbacked =>
                     Result.Scratch_Count := Result.Scratch_Count + 1;
                  when others =>
                     null;
               end case;

               if M.Missing_Backing_File or else M.External_Conflict then
                  Result.Missing_Or_Conflicted_Count := Result.Missing_Or_Conflicted_Count + 1;
               end if;

               if M.Stale_Backing_State then
                  Result.Stale_Backing_State_Count :=
                    Result.Stale_Backing_State_Count + 1;
               end if;

               if M.Missing_Backing_File
                 or else M.External_Conflict
                 or else M.Unreadable
                 or else M.Unwritable
               then
                  Result.Lifecycle_Problem_Count := Result.Lifecycle_Problem_Count + 1;
               end if;

               if M.Ownership = Buffer_Project_Owned then
                  Result.Project_Close_Affected_Count :=
                    Result.Project_Close_Affected_Count + 1;
               elsif M.Ownership = Buffer_Outside_Project
                 or else M.Ownership = Buffer_Scratch_Unbacked
               then
                  Result.Project_Close_Unaffected_Count :=
                    Result.Project_Close_Unaffected_Count + 1;
               end if;

               if M.Unreadable then
                  Result.Unreadable_Count := Result.Unreadable_Count + 1;
               end if;

               if M.Unwritable then
                  Result.Unwritable_Count := Result.Unwritable_Count + 1;
               end if;

               case M.Ownership is
                  when Buffer_Project_Owned =>
                     if M.Is_Dirty then
                        Result.Project_Owned_Dirty_Count := Result.Project_Owned_Dirty_Count + 1;
                     else
                        Result.Project_Owned_Clean_Count := Result.Project_Owned_Clean_Count + 1;
                     end if;
                  when Buffer_Outside_Project =>
                     if M.Is_Dirty then
                        Result.Outside_Project_Dirty_Count := Result.Outside_Project_Dirty_Count + 1;
                     else
                        Result.Outside_Project_Clean_Count := Result.Outside_Project_Clean_Count + 1;
                     end if;
                  when Buffer_Scratch_Unbacked =>
                     if M.Is_Dirty then
                        Result.Scratch_Dirty_Count := Result.Scratch_Dirty_Count + 1;
                     else
                        Result.Scratch_Clean_Count := Result.Scratch_Clean_Count + 1;
                     end if;
                  when others =>
                     null;
               end case;

               case M.Close_Eligibility is
                  when Buffer_Closable_Clean =>
                     Result.Close_Direct_Count := Result.Close_Direct_Count + 1;
                  when Buffer_Requires_Dirty_Confirmation =>
                     Result.Close_Needs_Confirmation_Count :=
                       Result.Close_Needs_Confirmation_Count + 1;
                  when Buffer_Requires_Save_As_Or_Discard =>
                     Result.Close_Needs_Save_As_Count :=
                       Result.Close_Needs_Save_As_Count + 1;
                  when Buffer_Requires_Conflict_Resolution_Or_Discard =>
                     Result.Close_Needs_Conflict_Count :=
                       Result.Close_Needs_Conflict_Count + 1;
                  when Buffer_Blocked_By_Pending_Confirmation =>
                     Result.Close_Blocked_Count := Result.Close_Blocked_Count + 1;
                  when Buffer_Not_A_Real_Row =>
                     null;
               end case;

               case M.Dirty_Category is
                  when Buffer_Dirty_Project_File =>
                     Result.Dirty_Project_File_Count := Result.Dirty_Project_File_Count + 1;
                  when Buffer_Dirty_Outside_Project_File =>
                     Result.Dirty_Outside_Project_Count := Result.Dirty_Outside_Project_Count + 1;
                  when Buffer_Dirty_Scratch =>
                     Result.Dirty_Scratch_Count := Result.Dirty_Scratch_Count + 1;
                  when Buffer_Dirty_Missing_File =>
                     Result.Dirty_Missing_Count := Result.Dirty_Missing_Count + 1;
                  when Buffer_Dirty_Conflicted_File =>
                     Result.Dirty_Conflicted_Count := Result.Dirty_Conflicted_Count + 1;
                  when Buffer_Dirty_Unwritable_File =>
                     Result.Dirty_Unwritable_Count := Result.Dirty_Unwritable_Count + 1;
                  when Buffer_Not_Dirty =>
                     null;
               end case;

               if M.Workspace_Persistability = Buffer_Persistable_File_Reference then
                  Result.Workspace_Persistable_Count := Result.Workspace_Persistable_Count + 1;
               else
                  Result.Workspace_Not_Persistable_Count :=
                    Result.Workspace_Not_Persistable_Count + 1;
               end if;
            end;
         end loop;
      end if;

      declare
         Sets : constant Buffer_Project_Lifecycle_Sets :=
           Project_Lifecycle_Buffer_Sets (Registry, Project);
      begin
         Result.Project_Owned_Count := Natural (Sets.Project_Owned.Length);
         Result.Outside_Project_Count := Natural (Sets.Outside_Project.Length);
         Result.Scratch_Count := Natural (Sets.Scratch.Length);
         Result.Project_Close_Affected_Count :=
           Natural (Sets.Project_Close_Affected.Length);
         Result.Project_Close_Unaffected_Count :=
           Natural (Sets.Project_Close_Unaffected.Length);
         Result.Project_Owned_Dirty_Count := Natural (Sets.Project_Owned_Dirty.Length);
         Result.Project_Owned_Clean_Count := Natural (Sets.Project_Owned_Clean.Length);
      end;

      Result.Dirty_Project_Files_Summary_Label := To_Unbounded_String
        (Trim_Count_Label
          (Counted_Label
            (Result.Project_Owned_Dirty_Count,
             "dirty project file",
             "dirty project files")));
      Result.Dirty_Outside_Project_Summary_Label := To_Unbounded_String
        (Trim_Count_Label
          (Counted_Label
            (Result.Outside_Project_Dirty_Count,
             "dirty outside-project file",
             "dirty outside-project files")));
      Result.Dirty_Scratch_Summary_Label := To_Unbounded_String
        (Trim_Count_Label
          (Counted_Label
            (Result.Scratch_Dirty_Count,
             "unsaved scratch buffer",
             "unsaved scratch buffers")));
      Result.Dirty_File_Conflict_Summary_Label := To_Unbounded_String
        (Trim_Count_Label
          (Counted_Label
            (Result.Dirty_Missing_Count + Result.Dirty_Conflicted_Count,
             "dirty buffer has file conflict",
             "dirty buffers have file conflicts")));
      Result.Workspace_Persistability_Summary_Label := To_Unbounded_String
        (Trim_Count_Label
          (Counted_Label
            (Result.Workspace_Persistable_Count,
             "workspace-persistable file reference",
             "workspace-persistable file references"))
         & " "
         & Trim_Count_Label
             (Counted_Label
               (Result.Workspace_Not_Persistable_Count,
                "runtime-only buffer excluded",
                "runtime-only buffers excluded")));
      Result.Project_Lifecycle_Buffer_Set_Summary_Label := To_Unbounded_String
        (Trim_Count_Label
          (Counted_Label
            (Result.Project_Close_Affected_Count,
             "project-close affected buffer",
             "project-close affected buffers"))
         & " "
         & Trim_Count_Label
             (Counted_Label
               (Result.Project_Close_Unaffected_Count,
                "retained outside/scratch buffer",
                "retained outside/scratch buffers")));

      Result.Active_Runtime_Id_Persisted := False;
      Result.Selected_Runtime_Id_Persisted := False;
      Result.Buffer_List_State_Persisted := False;
      Result.Dirty_Text_Persisted := False;
      Result.Scratch_Text_Persisted := False;
      Result.Conflict_Token_Persisted := False;
      Result.Runtime_Buffer_Id_Persisted := False;
      Result.Command_Or_Keybinding_Payload := False;
      Result.Render_Mutation_Route := False;
      Result.Metadata_Projection_Coherent :=
        Result.Active_Buffer_Valid
        and then Result.Selected_Buffer_Valid
        and then (Result.Close_Direct_Count
          + Result.Close_Needs_Confirmation_Count
          + Result.Close_Needs_Save_As_Count
          + Result.Close_Needs_Conflict_Count
          + Result.Close_Blocked_Count = Result.Buffer_Count)
        and then (Result.Workspace_Persistable_Count
          + Result.Workspace_Not_Persistable_Count = Result.Buffer_Count);
      Result.Workspace_Persistence_Safe :=
        not Result.Active_Runtime_Id_Persisted
        and then not Result.Selected_Runtime_Id_Persisted
        and then not Result.Buffer_List_State_Persisted
        and then not Result.Dirty_Text_Persisted
        and then not Result.Scratch_Text_Persisted
        and then not Result.Conflict_Token_Persisted
        and then not Result.Runtime_Buffer_Id_Persisted;
      Result.Command_Keybinding_Payloads_Clear :=
        not Result.Command_Or_Keybinding_Payload;
      Result.Render_Boundary_Safe := not Result.Render_Mutation_Route;
      Result.Audit_Side_Effect_Free := True;
      return Result;
   end Audit_Buffers;

   function Buffer_Metadata_Lifecycle_Audit_Coherent
     (Registry    : Buffer_Registry;
      Project     : Editor.Project.Project_State;
      Selected_Id : Buffer_Id := No_Buffer) return Boolean
   is
      Audit : constant Buffer_Audit_Summary :=
        Audit_Buffers (Registry, Project, Selected_Id);
   begin
      return Audit.Metadata_Projection_Coherent
        and then Audit.Workspace_Persistence_Safe
        and then Audit.Command_Keybinding_Payloads_Clear
        and then Audit.Render_Boundary_Safe
        and then Audit.Audit_Side_Effect_Free;
   end Buffer_Metadata_Lifecycle_Audit_Coherent;

   function Project_Owned_Buffer_Count
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State) return Natural
   is
   begin
      return Audit_Buffers (Registry, Project).Project_Owned_Count;
   end Project_Owned_Buffer_Count;

   function Outside_Project_Buffer_Count
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State) return Natural
   is
   begin
      return Audit_Buffers (Registry, Project).Outside_Project_Count;
   end Outside_Project_Buffer_Count;

   function Scratch_Buffer_Count (Registry : Buffer_Registry) return Natural is
      Result : Natural := 0;
   begin
      for Item of Registry.Items loop
         if Item.State /= null and then not Item.State.Buffer_Lifecycle.File_Info.Has_Path then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Scratch_Buffer_Count;

   function Project_Owned_Dirty_Buffer_Count
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State) return Natural
   is
   begin
      return Audit_Buffers (Registry, Project).Project_Owned_Dirty_Count;
   end Project_Owned_Dirty_Buffer_Count;

   function Outside_Project_Dirty_Buffer_Count
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State) return Natural
   is
   begin
      return Audit_Buffers (Registry, Project).Outside_Project_Dirty_Count;
   end Outside_Project_Dirty_Buffer_Count;

   function Scratch_Dirty_Buffer_Count
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State) return Natural
   is
   begin
      return Audit_Buffers (Registry, Project).Scratch_Dirty_Count;
   end Scratch_Dirty_Buffer_Count;

   function Categorized_Dirty_Buffer_Summary
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State)
      return Editor.Dirty_Guards.Dirty_Buffer_Summary
   is
      Audit : constant Buffer_Audit_Summary := Audit_Buffers (Registry, Project);
      Dirty : constant Natural :=
        Audit.Dirty_Project_File_Count
        + Audit.Dirty_Outside_Project_Count
        + Audit.Dirty_Scratch_Count
        + Audit.Dirty_Missing_Count
        + Audit.Dirty_Conflicted_Count
        + Audit.Dirty_Unwritable_Count;
   begin
      return
        (Dirty_Count       => Dirty,
         Untitled_Count    => Audit.Dirty_Scratch_Count,
         File_Backed_Count => Dirty - Audit.Dirty_Scratch_Count);
   end Categorized_Dirty_Buffer_Summary;

   function Project_Lifecycle_Dirty_Buffer_Summary
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State)
      return Editor.Dirty_Guards.Dirty_Buffer_Summary
   is
      Audit : constant Buffer_Audit_Summary := Audit_Buffers (Registry, Project);
   begin
      return
        (Dirty_Count       => Audit.Project_Owned_Dirty_Count,
         Untitled_Count    => 0,
         File_Backed_Count => Audit.Project_Owned_Dirty_Count);
   end Project_Lifecycle_Dirty_Buffer_Summary;

   function Unpinned_Clean_Buffer_Count
     (Registry : Buffer_Registry) return Natural
   is
      Result : Natural := 0;
   begin
      for Item of Registry.Items loop
         if Item.State /= null
           and then not Item.Pinned
           and then not Item.State.Buffer_Lifecycle.File_Info.Dirty
         then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Unpinned_Clean_Buffer_Count;

   function Dirty_Buffer_Count
     (Registry : Buffer_Registry) return Natural
   is
      Result : Natural := 0;
   begin
      for Item of Registry.Items loop
         if Item.State /= null and then Item.State.Buffer_Lifecycle.File_Info.Dirty then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Dirty_Buffer_Count;

   function Dirty_File_Backed_Buffer_Count
     (Registry : Buffer_Registry) return Natural
   is
      Result : Natural := 0;
   begin
      for Item of Registry.Items loop
         if Item.State /= null
           and then Item.State.Buffer_Lifecycle.File_Info.Dirty
           and then Item.State.Buffer_Lifecycle.File_Info.Has_Path
         then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Dirty_File_Backed_Buffer_Count;

   function Dirty_Untitled_Buffer_Count
     (Registry : Buffer_Registry) return Natural
   is
      Result : Natural := 0;
   begin
      for Item of Registry.Items loop
         if Item.State /= null
           and then Item.State.Buffer_Lifecycle.File_Info.Dirty
           and then not Item.State.Buffer_Lifecycle.File_Info.Has_Path
         then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Dirty_Untitled_Buffer_Count;

   function Clean_Buffer_Count
     (Registry : Buffer_Registry) return Natural
   is
      Result : Natural := 0;
   begin
      for Item of Registry.Items loop
         if Item.State /= null and then not Item.State.Buffer_Lifecycle.File_Info.Dirty then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Clean_Buffer_Count;

   function Dirty_Buffer_Display_Name
     (Registry : Buffer_Registry;
      Index    : Positive) return String
   is
      Seen : Natural := 0;
   begin
      for Item of Registry.Items loop
         if Item.State /= null and then Item.State.Buffer_Lifecycle.File_Info.Dirty then
            Seen := Seen + 1;
            if Seen = Index then
               return To_String (Item.State.Buffer_Lifecycle.File_Info.Display_Name);
            end if;
         end if;
      end loop;
      return "<invalid buffer>";
   end Dirty_Buffer_Display_Name;

   function Dirty_Buffer_Summary
     (Registry : Buffer_Registry)
      return Editor.Dirty_Guards.Dirty_Buffer_Summary
   is
   begin
      return (Dirty_Count       => Dirty_Buffer_Count (Registry),
              Untitled_Count    => Dirty_Untitled_Buffer_Count (Registry),
              File_Backed_Count => Dirty_File_Backed_Buffer_Count (Registry));
   end Dirty_Buffer_Summary;

   function Closeable_Unpinned_Clean_Outside_Active_Group_Count
     (Registry : Buffer_Registry) return Natural
   is
      Result : Natural := 0;
      Group : constant String := Active_Buffer_Group (Registry);
   begin
      if not Registry.Has_Active_Group then
         return 0;
      end if;
      for Item of Registry.Items loop
         if Item.State /= null
           and then not Item.Pinned
           and then not Item.State.Buffer_Lifecycle.File_Info.Dirty
           and then (not Item.Has_Group or else To_String (Item.Group) /= Group)
         then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Closeable_Unpinned_Clean_Outside_Active_Group_Count;

end Editor.Buffers.Audits;
