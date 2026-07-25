with Editor.Projection_Surface_File_Lifecycle_Audit.Surface_Checks; use Editor.Projection_Surface_File_Lifecycle_Audit.Surface_Checks;

package body Editor.Projection_Surface_File_Lifecycle_Audit.Adapters is

   function Expected_Canonical_Source_Count
     (Surface : Projection_Surface_Id) return Natural
   is
   begin
      case Surface is
         when Open_Buffer_Switcher_Surface =>
            return 7;
         when Quick_Open_Surface =>
            return 7;
         when Project_Search_Surface =>
            return 8;
         when Bookmarks_Surface =>
            return 8;
         when Navigation_History_Surface =>
            return 8;
      end case;
   end Expected_Canonical_Source_Count;

   function Expected_Forbidden_Field_Count
     (Surface : Projection_Surface_Id) return Natural
   is
      pragma Unreferenced (Surface);
   begin
      --  last observed targets/sources, operation/target histories, prompt
      --  state, probe/cache/repair/migration/watch/import/local-route state.
      return 22;
   end Expected_Forbidden_Field_Count;

   function Expected_Forbidden_Route_Count
     (Surface : Projection_Surface_Id) return Natural
   is
      pragma Unreferenced (Surface);
   begin
      --  save, save-as, close/reopen, reload/revert, rename/delete/copy/move,
      --  target inference/repair/migration/probe/import routes.
      return 18;
   end Expected_Forbidden_Route_Count;

   function Expected_Forbidden_Render_Field_Count
     (Surface : Projection_Surface_Id) return Natural
   is
      pragma Unreferenced (Surface);
   begin
      --  Fields that render snapshots may display only when derived from
      --  canonical projection rows; these lifecycle-local fields must never
      --  appear as rendered product truth on projection surfaces.
      return 16;
   end Expected_Forbidden_Render_Field_Count;

   function Canonical_Source_Name
     (Surface : Projection_Surface_Id;
      Index   : Positive) return String
   is
   begin
      case Surface is
         when Open_Buffer_Switcher_Surface =>
            case Index is
               when 1 => return "open-buffer collection";
               when 2 => return "buffer identity";
               when 3 => return "active buffer identity";
               when 4 => return "buffer display name";
               when 5 => return "buffer associated path";
               when 6 => return "buffer dirty state";
               when 7 => return "retained switcher visibility and selection";
               when others => return "";
            end case;
         when Quick_Open_Surface =>
            case Index is
               when 1 => return "Quick Open query text";
               when 2 => return "Quick Open selection state";
               when 3 => return "retained Quick Open scope/filter configuration";
               when 4 => return "open-buffer collection under retained policy";
               when 5 => return "buffer identity and association for open-buffer candidates";
               when 6 => return "buffer dirty state where dirty hints are shown";
               when 7 => return "retained project/file candidate source";
               when others => return "";
            end case;
         when Project_Search_Surface =>
            case Index is
               when 1 => return "Project Search query text";
               when 2 => return "Project Search selection state";
               when 3 => return "retained Project Search scope/filter configuration";
               when 4 => return "retained project/searchable-file source";
               when 5 => return "retained search result rows";
               when 6 => return "open/current-buffer rows where already present";
               when 7 => return "buffer identity and association where represented";
               when 8 => return "buffer dirty state where dirty hints are shown";
               when others => return "";
            end case;
         when Bookmarks_Surface =>
            case Index is
               when 1 => return "bookmark entry list";
               when 2 => return "bookmark selection and focus state";
               when 3 => return "retained bookmark target data";
               when 4 => return "retained bookmark labels where present";
               when 5 => return "buffer identity and association for buffer-backed rows";
               when 6 => return "buffer dirty state where dirty hints are shown";
               when 7 => return "open-buffer collection where markers are represented";
               when 8 => return "retained bookmark ordering policy";
               when others => return "";
            end case;
         when Navigation_History_Surface =>
            case Index is
               when 1 => return "navigation history entry list";
               when 2 => return "navigation current/back-forward state";
               when 3 => return "retained navigation target data";
               when 4 => return "retained navigation labels where present";
               when 5 => return "buffer identity and association for buffer-backed entries";
               when 6 => return "buffer dirty state where dirty hints are shown";
               when 7 => return "open-buffer collection where markers are represented";
               when 8 => return "retained navigation ordering/back-forward policy";
               when others => return "";
            end case;
      end case;
   end Canonical_Source_Name;

   function Forbidden_Lifecycle_Field_Name
     (Index : Positive) return String
   is
   begin
      case Index is
         when 1 => return "last observed save-as target";
         when 2 => return "last observed rename target";
         when 3 => return "last observed copy target";
         when 4 => return "last observed move target";
         when 5 => return "last observed delete source";
         when 6 => return "file lifecycle command history";
         when 7 => return "target history";
         when 8 => return "prompt target text";
         when 9 => return "filesystem probe cache";
         when 10 => return "association repair cache";
         when 11 => return "retained target repair cache";
         when 12 => return "target migration cache";
         when 13 => return "operation log";
         when 14 => return "lifecycle observation cache";
         when 15 => return "file-watch state";
         when 16 => return "external-modification state";
         when 17 => return "stale path-label cache";
         when 18 => return "dirty indicator cache";
         when 19 => return "prompt ownership state";
         when 20 => return "local file route state";
         when 21 => return "source override state";
         when 22 => return "cross-surface projection import state";
         when others => return "";
      end case;
   end Forbidden_Lifecycle_Field_Name;

   function Forbidden_Lifecycle_Route_Name
     (Index : Positive) return String
   is
   begin
      case Index is
         when 1 => return "surface-local save";
         when 2 => return "surface-local save-as";
         when 3 => return "surface-local close-buffer";
         when 4 => return "surface-local reopen-closed-buffer";
         when 5 => return "surface-local reload-buffer";
         when 6 => return "surface-local revert-buffer";
         when 7 => return "surface-local rename-buffer-file";
         when 8 => return "surface-local delete-buffer-file";
         when 9 => return "surface-local copy-buffer-file";
         when 10 => return "surface-local move-buffer-file";
         when 11 => return "prompt-specific local command name";
         when 12 => return "target prompt ownership route";
         when 13 => return "target inference route";
         when 14 => return "source override route";
         when 15 => return "filesystem probe route";
         when 16 => return "association repair route";
         when 17 => return "retained-target repair or migration route";
         when 18 => return "cross-surface projection import route";
         when others => return "";
      end case;
   end Forbidden_Lifecycle_Route_Name;

   function Forbidden_Rendered_Field_Name
     (Index : Positive) return String
   is
   begin
      case Index is
         when 1 => return "rendered last save-as target";
         when 2 => return "rendered last rename target";
         when 3 => return "rendered last copy target";
         when 4 => return "rendered last move target";
         when 5 => return "rendered last deleted source";
         when 6 => return "rendered target history";
         when 7 => return "rendered operation history";
         when 8 => return "rendered prompt input";
         when 9 => return "rendered filesystem probe result";
         when 10 => return "rendered association repair status";
         when 11 => return "rendered retained target repair status";
         when 12 => return "rendered target migration status";
         when 13 => return "rendered cross-surface projection import marker";
         when 14 => return "rendered file-watch state";
         when 15 => return "rendered external-modification state";
         when 16 => return "rendered operation log";
         when others => return "";
      end case;
   end Forbidden_Rendered_Field_Name;

   function Adapter_For_Surface
     (Surface : Projection_Surface_Id) return Projection_Surface_Adapter
   is
   begin
      return
        (Surface                     => Surface,
         Has_Visibility_State        => True,
         Has_Row_Projection          => True,
         Has_Row_Identity            => True,
         Has_Row_Label               => True,
         Has_Selected_Or_Current_State => True,
         Has_Query_State             => True,
         Has_Dirty_Hint_State        => True,
         Has_Retained_Target_State   => True,
         Has_Retained_Source_Snapshot => True,
         Has_Forbidden_Field_List    => True,
         Has_Forbidden_Route_List    => True,
         Has_Persistence_Output      => True,
         Has_Prompt_Ownership_Metadata => True,
         Has_Cross_Surface_Import_Metadata => True,
         Has_Snapshot_Freshness_Metadata => True,
         Exposes_Raw_Retained_State    => True,
         No_Path_Label_Normalization   => True,
         No_Dirty_Hint_Normalization   => True,
         No_Inferred_Target_Reconstruction => True,
         No_Command_Execution          => True,
         No_Prompt_Control             => True,
         No_Filesystem_Probe           => True,
         No_Row_Repair                 => True,
         No_Cross_Surface_Row_Lookup   => True,
         No_Persistence_Field_Filtering => True,
         Has_Projection_Helper_Metadata => True,
         Projection_Helpers_Pure       => True,
         Canonical_Source_Count       => Expected_Canonical_Source_Count (Surface),
         Forbidden_Field_Count        => Expected_Forbidden_Field_Count (Surface),
         Forbidden_Route_Count        => Expected_Forbidden_Route_Count (Surface),
         Forbidden_Render_Field_Count => Expected_Forbidden_Render_Field_Count (Surface));
   end Adapter_For_Surface;

   function Adapter_Supports_Shared_Harness
     (Adapter : Projection_Surface_Adapter) return Boolean
   is
   begin
      return Adapter.Has_Visibility_State
        and then Adapter.Has_Row_Projection
        and then Adapter.Has_Row_Identity
        and then Adapter.Has_Row_Label
        and then Adapter.Has_Selected_Or_Current_State
        and then Adapter.Has_Query_State
        and then Adapter.Has_Dirty_Hint_State
        and then Adapter.Has_Retained_Target_State
        and then Adapter.Has_Retained_Source_Snapshot
        and then Adapter.Has_Forbidden_Field_List
        and then Adapter.Has_Forbidden_Route_List
        and then Adapter.Has_Persistence_Output
        and then Adapter.Has_Prompt_Ownership_Metadata
        and then Adapter.Has_Cross_Surface_Import_Metadata
        and then Adapter.Has_Snapshot_Freshness_Metadata
        and then Adapter.Exposes_Raw_Retained_State
        and then Adapter.No_Path_Label_Normalization
        and then Adapter.No_Dirty_Hint_Normalization
        and then Adapter.No_Inferred_Target_Reconstruction
        and then Adapter.No_Command_Execution
        and then Adapter.No_Prompt_Control
        and then Adapter.No_Filesystem_Probe
        and then Adapter.No_Row_Repair
        and then Adapter.No_Cross_Surface_Row_Lookup
        and then Adapter.No_Persistence_Field_Filtering
        and then Adapter.Has_Projection_Helper_Metadata
        and then Adapter.Projection_Helpers_Pure
        and then Adapter.Canonical_Source_Count = Expected_Canonical_Source_Count (Adapter.Surface)
        and then Adapter.Forbidden_Field_Count = Expected_Forbidden_Field_Count (Adapter.Surface)
        and then Adapter.Forbidden_Route_Count = Expected_Forbidden_Route_Count (Adapter.Surface)
        and then Adapter.Forbidden_Render_Field_Count = Expected_Forbidden_Render_Field_Count (Adapter.Surface);
   end Adapter_Supports_Shared_Harness;

   procedure Validate_Adapter
     (Result  : in out Projection_Surface_Audit_Result;
      Adapter : Projection_Surface_Adapter)
   is
   begin
      if not Adapter.Has_Visibility_State then
         Add_Failure (Result, Adapter.Surface, "adapter does not expose retained visibility state");
      end if;
      if not Adapter.Has_Row_Projection then
         Add_Failure (Result, Adapter.Surface, "adapter does not expose row projection");
      end if;
      if not Adapter.Has_Row_Identity then
         Add_Failure (Result, Adapter.Surface, "adapter does not expose retained row identity");
      end if;
      if not Adapter.Has_Row_Label then
         Add_Failure (Result, Adapter.Surface, "adapter does not expose retained row labels");
      end if;
      if not Adapter.Has_Selected_Or_Current_State then
         Add_Failure (Result, Adapter.Surface, "adapter does not expose selected/current UI state");
      end if;
      if not Adapter.Has_Query_State then
         Add_Failure (Result, Adapter.Surface, "adapter does not expose query/filter UI state");
      end if;
      if not Adapter.Has_Dirty_Hint_State then
         Add_Failure (Result, Adapter.Surface, "adapter does not expose dirty hint observation state");
      end if;
      if not Adapter.Has_Retained_Target_State then
         Add_Failure (Result, Adapter.Surface, "adapter does not expose retained target state");
      end if;
      if not Adapter.Has_Retained_Source_Snapshot then
         Add_Failure (Result, Adapter.Surface, "adapter does not expose retained source snapshot");
      end if;
      if not Adapter.Has_Forbidden_Field_List then
         Add_Failure (Result, Adapter.Surface, "adapter does not expose forbidden lifecycle field catalog");
      end if;
      if not Adapter.Has_Forbidden_Route_List then
         Add_Failure (Result, Adapter.Surface, "adapter does not expose forbidden lifecycle route catalog");
      end if;
      if not Adapter.Has_Persistence_Output then
         Add_Failure (Result, Adapter.Surface, "adapter does not expose persistence output boundary");
      end if;
      if not Adapter.Has_Prompt_Ownership_Metadata then
         Add_Failure (Result, Adapter.Surface, "adapter does not expose prompt ownership absence metadata");
      end if;
      if not Adapter.Has_Cross_Surface_Import_Metadata then
         Add_Failure (Result, Adapter.Surface, "adapter does not expose cross-surface import absence metadata");
      end if;
      if not Adapter.Has_Snapshot_Freshness_Metadata then
         Add_Failure (Result, Adapter.Surface, "adapter does not expose snapshot freshness metadata");
      end if;
      if not Adapter.Exposes_Raw_Retained_State then
         Add_Failure (Result, Adapter.Surface, "adapter does not expose raw retained projection state");
      end if;
      if not Adapter.No_Path_Label_Normalization then
         Add_Failure (Result, Adapter.Surface, "adapter normalizes path labels instead of exposing snapshots");
      end if;
      if not Adapter.No_Dirty_Hint_Normalization then
         Add_Failure (Result, Adapter.Surface, "adapter normalizes dirty hints instead of exposing snapshots");
      end if;
      if not Adapter.No_Inferred_Target_Reconstruction then
         Add_Failure (Result, Adapter.Surface, "adapter reconstructs inferred retained targets");
      end if;
      if not Adapter.No_Command_Execution then
         Add_Failure (Result, Adapter.Surface, "adapter executes commands to establish expected lifecycle state");
      end if;
      if not Adapter.No_Prompt_Control then
         Add_Failure (Result, Adapter.Surface, "adapter opens, confirms, or cancels target prompts");
      end if;
      if not Adapter.No_Filesystem_Probe then
         Add_Failure (Result, Adapter.Surface, "adapter probes filesystem state for lifecycle observation");
      end if;
      if not Adapter.No_Row_Repair then
         Add_Failure (Result, Adapter.Surface, "adapter repairs stale projection rows");
      end if;
      if not Adapter.No_Cross_Surface_Row_Lookup then
         Add_Failure (Result, Adapter.Surface, "adapter imports another surface's rows as lifecycle truth");
      end if;
      if not Adapter.No_Persistence_Field_Filtering then
         Add_Failure (Result, Adapter.Surface, "adapter filters persistence leaks instead of exposing raw output");
      end if;
      if not Adapter.Has_Projection_Helper_Metadata then
         Add_Failure (Result, Adapter.Surface, "adapter does not expose projection helper purity metadata");
      end if;
      if not Adapter.Projection_Helpers_Pure then
         Add_Failure (Result, Adapter.Surface, "projection helpers are not pure retained-source composition");
      end if;
      if Adapter.Canonical_Source_Count /= Expected_Canonical_Source_Count (Adapter.Surface) then
         Add_Failure (Result, Adapter.Surface, "adapter canonical source count is incomplete");
      end if;
      if Adapter.Forbidden_Field_Count /= Expected_Forbidden_Field_Count (Adapter.Surface) then
         Add_Failure (Result, Adapter.Surface, "adapter forbidden field count is incomplete");
      end if;
      if Adapter.Forbidden_Route_Count /= Expected_Forbidden_Route_Count (Adapter.Surface) then
         Add_Failure (Result, Adapter.Surface, "adapter forbidden route count is incomplete");
      end if;
      if Adapter.Forbidden_Render_Field_Count /= Expected_Forbidden_Render_Field_Count (Adapter.Surface) then
         Add_Failure (Result, Adapter.Surface, "adapter forbidden render field count is incomplete");
      end if;

      --  completeness: adapter catalog validation is part of the
      --  reusable harness, not just a separate AUnit catalog smoke test.
      --  This catches a future surface that advertises a count but leaves
      --  unnamed retained sources, forbidden fields, or forbidden routes.
      for Index in 1 .. Adapter.Canonical_Source_Count loop
         if Canonical_Source_Name (Adapter.Surface, Index) = "" then
            Add_Failure
              (Result, Adapter.Surface,
               "adapter canonical source catalog has an unnamed entry");
         end if;
      end loop;

      for Left in 1 .. Adapter.Canonical_Source_Count loop
         for Right in Left + 1 .. Adapter.Canonical_Source_Count loop
            if Canonical_Source_Name (Adapter.Surface, Left) /= ""
              and then Canonical_Source_Name (Adapter.Surface, Left)
                       = Canonical_Source_Name (Adapter.Surface, Right)
            then
               Add_Failure
                 (Result, Adapter.Surface,
                  "adapter canonical source catalog contains duplicate entries");
            end if;
         end loop;
      end loop;

      for Index in 1 .. Adapter.Forbidden_Field_Count loop
         if Forbidden_Lifecycle_Field_Name (Index) = "" then
            Add_Failure
              (Result, Adapter.Surface,
               "adapter forbidden lifecycle field catalog has an unnamed entry");
         end if;
      end loop;

      for Left in 1 .. Adapter.Forbidden_Field_Count loop
         for Right in Left + 1 .. Adapter.Forbidden_Field_Count loop
            if Forbidden_Lifecycle_Field_Name (Left) /= ""
              and then Forbidden_Lifecycle_Field_Name (Left)
                       = Forbidden_Lifecycle_Field_Name (Right)
            then
               Add_Failure
                 (Result, Adapter.Surface,
                  "adapter forbidden lifecycle field catalog contains duplicate entries");
            end if;
         end loop;
      end loop;

      for Index in 1 .. Adapter.Forbidden_Route_Count loop
         if Forbidden_Lifecycle_Route_Name (Index) = "" then
            Add_Failure
              (Result, Adapter.Surface,
               "adapter forbidden lifecycle route catalog has an unnamed entry");
         end if;
      end loop;

      for Left in 1 .. Adapter.Forbidden_Route_Count loop
         for Right in Left + 1 .. Adapter.Forbidden_Route_Count loop
            if Forbidden_Lifecycle_Route_Name (Left) /= ""
              and then Forbidden_Lifecycle_Route_Name (Left)
                       = Forbidden_Lifecycle_Route_Name (Right)
            then
               Add_Failure
                 (Result, Adapter.Surface,
                  "adapter forbidden lifecycle route catalog contains duplicate entries");
            end if;
         end loop;
      end loop;

      for Index in 1 .. Adapter.Forbidden_Render_Field_Count loop
         if Forbidden_Rendered_Field_Name (Index) = "" then
            Add_Failure
              (Result, Adapter.Surface,
               "adapter forbidden rendered field catalog has an unnamed entry");
         end if;
      end loop;

      for Left in 1 .. Adapter.Forbidden_Render_Field_Count loop
         for Right in Left + 1 .. Adapter.Forbidden_Render_Field_Count loop
            if Forbidden_Rendered_Field_Name (Left) /= ""
              and then Forbidden_Rendered_Field_Name (Left)
                       = Forbidden_Rendered_Field_Name (Right)
            then
               Add_Failure
                 (Result, Adapter.Surface,
                  "adapter forbidden rendered field catalog contains duplicate entries");
            end if;
         end loop;
      end loop;
   end Validate_Adapter;

end Editor.Projection_Surface_File_Lifecycle_Audit.Adapters;
