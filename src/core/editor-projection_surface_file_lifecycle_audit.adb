with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Bookmarks;
with Editor.Buffer_Switcher;
with Editor.Navigation_History;
with Editor.Project_Search;
with Editor.Quick_Open;

package body Editor.Projection_Surface_File_Lifecycle_Audit is

   procedure Add_Failure
     (Result  : in out Projection_Surface_Audit_Result;
      Surface : Projection_Surface_Id;
      Field   : String)
   is
   begin
      if Result.Count < Result.Failures'Length then
         Result.Count := Result.Count + 1;
         Result.Failures (Result.Count) :=
           To_Unbounded_String (Surface_Name (Surface) & ": " & Field);
      end if;
   end Add_Failure;

   function Surface_Name (Surface : Projection_Surface_Id) return String is
   begin
      case Surface is
         when Open_Buffer_Switcher_Surface =>
            return "Open Buffer Switcher";
         when Quick_Open_Surface =>
            return "Quick Open";
         when Project_Search_Surface =>
            return "Project Search";
         when Bookmarks_Surface =>
            return "Bookmarks";
         when Navigation_History_Surface =>
            return "Navigation History";
      end case;
   end Surface_Name;

   function Classification_Name
     (Classification : Projection_Surface_Classification) return String
   is
   begin
      case Classification is
         when Projection_Surface_None           => return "none";
         when Projection_Surface_File_Like      => return "file-like";
         when Projection_Surface_Buffer_Like    => return "buffer-like";
         when Projection_Surface_Path_Like      => return "path-like";
         when Projection_Surface_Target_Like    => return "target-like";
         when Projection_Surface_Candidate_Like => return "candidate-like";
         when Projection_Surface_Result_Like    => return "result-like";
         when Projection_Surface_Bookmark_Like  => return "bookmark-like";
         when Projection_Surface_History_Like   => return "history-like";
         when Projection_Surface_Mixed          => return "mixed";
      end case;
   end Classification_Name;

   function Surface_Classification
     (Surface : Projection_Surface_Id) return Projection_Surface_Classification
   is
   begin
      case Surface is
         when Open_Buffer_Switcher_Surface =>
            return Projection_Surface_Buffer_Like;
         when Quick_Open_Surface =>
            return Projection_Surface_Candidate_Like;
         when Project_Search_Surface =>
            return Projection_Surface_Result_Like;
         when Bookmarks_Surface =>
            return Projection_Surface_Bookmark_Like;
         when Navigation_History_Surface =>
            return Projection_Surface_History_Like;
      end case;
   end Surface_Classification;

   function Registration_For_Surface
     (Surface : Projection_Surface_Id) return Projection_Surface_Registration
   is
      R : Projection_Surface_Registration :=
        (Surface                         => Surface,
         Classification                  => Surface_Classification (Surface),
         Is_Registered                   => True,
         Rows_May_Contain_Buffer_Identity => True,
         Rows_May_Contain_Retained_Target => True,
         Rows_May_Contain_Path_File_Labels => True,
         Rows_May_Contain_Dirty_Hints    => True,
         Rows_May_Contain_Current_Markers => True,
         Has_Query_Or_Filter_Text        => False,
         Has_Selected_Or_Current_Row     => True,
         Has_Activation_Behavior         => True,
         Has_Retained_Persistence        => False,
         Has_Surface_Adapter_Factory     => True,
         Has_Forbidden_Field_Metadata    => True,
         Has_Forbidden_Route_Metadata    => True,
         Has_Persistence_Inspection_Hook => True,
         Has_Render_Snapshot_Inspection_Hook => True,
         Runs_Shared_Invariant_Harness   => True);
   begin
      case Surface is
         when Open_Buffer_Switcher_Surface =>
            R.Rows_May_Contain_Retained_Target := False;
         when Quick_Open_Surface =>
            R.Has_Query_Or_Filter_Text := True;
         when Project_Search_Surface =>
            R.Has_Query_Or_Filter_Text := True;
            R.Has_Retained_Persistence := True;
         when Bookmarks_Surface =>
            R.Has_Retained_Persistence := True;
         when Navigation_History_Surface =>
            R.Has_Retained_Persistence := True;
      end case;
      return R;
   end Registration_For_Surface;

   function Surface_Is_Registered
     (Surface : Projection_Surface_Id) return Boolean
   is
   begin
      return Registration_For_Surface (Surface).Is_Registered;
   end Surface_Is_Registered;

   function Registration_Lifecycle_Sensitive
     (Registration : Projection_Surface_Registration) return Boolean
   is
   begin
      return Registration.Classification /= Projection_Surface_None
        or else Registration.Rows_May_Contain_Buffer_Identity
        or else Registration.Rows_May_Contain_Retained_Target
        or else Registration.Rows_May_Contain_Path_File_Labels
        or else Registration.Rows_May_Contain_Dirty_Hints
        or else Registration.Rows_May_Contain_Current_Markers;
   end Registration_Lifecycle_Sensitive;

   function Projection_Surface_Registration_Coherent
     (Registration : Projection_Surface_Registration) return Boolean
   is
   begin
      return (not Registration_Lifecycle_Sensitive (Registration)
              or else Registration.Is_Registered)
        and then (Registration.Classification = Projection_Surface_None
                  or else Registration.Runs_Shared_Invariant_Harness)
        and then (not Registration.Is_Registered
                  or else Registration.Has_Surface_Adapter_Factory)
        and then (not Registration.Is_Registered
                  or else Registration.Has_Forbidden_Field_Metadata)
        and then (not Registration.Is_Registered
                  or else Registration.Has_Forbidden_Route_Metadata)
        and then (not Registration.Has_Retained_Persistence
                  or else Registration.Has_Persistence_Inspection_Hook)
        and then (not Registration.Is_Registered
                  or else Registration.Has_Render_Snapshot_Inspection_Hook)
        and then Adapter_Supports_Shared_Harness
          (Adapter_For_Surface (Registration.Surface));
   end Projection_Surface_Registration_Coherent;

   function Projection_Surface_Inspection_Lifecycle_Sensitive
     (Inspection : Projection_Surface_Inspection) return Boolean
   is
   begin
      return Inspection.Classification /= Projection_Surface_None
        or else Inspection.Exposes_Buffer_Identity
        or else Inspection.Exposes_Retained_Target
        or else Inspection.Exposes_Path_File_Label
        or else Inspection.Exposes_Dirty_Hint
        or else Inspection.Exposes_Current_Or_Open_Marker
        or else Inspection.Exposes_Candidate_Result_Target
        or else Inspection.Exposes_Bookmark_Or_History_Target
        or else Inspection.Has_Local_Lifecycle_Route
        or else Inspection.Has_Target_Prompt_Ownership
        or else Inspection.Has_Source_Override_Or_Target_Inference
        or else Inspection.Has_Repair_Migration_Or_Probe
        or else Inspection.Has_Cross_Surface_Import
        or else Inspection.Has_Lifecycle_Persistence_Field;
   end Projection_Surface_Inspection_Lifecycle_Sensitive;

   function Projection_Surface_Inspection_Coherent
     (Inspection : Projection_Surface_Inspection) return Boolean
   is
      Sensitive : constant Boolean :=
        Projection_Surface_Inspection_Lifecycle_Sensitive (Inspection);
   begin
      if Inspection.Has_Explicit_Audit_Exemption then
         return not Inspection.Registered
           and then Inspection.Classification = Projection_Surface_None
           and then not Inspection.Has_Local_Lifecycle_Route
           and then not Inspection.Has_Lifecycle_Persistence_Field
           and then not Inspection.Has_Retained_Persistence;
      end if;

      return (not Sensitive or else Inspection.Registered)
        and then (Inspection.Registered or else not Inspection.Has_Retained_Persistence)
        and then (Inspection.Classification /= Projection_Surface_None
                  or else not Inspection.Exposes_Buffer_Identity)
        and then (Inspection.Classification /= Projection_Surface_None
                  or else not Inspection.Exposes_Retained_Target)
        and then (Inspection.Classification /= Projection_Surface_None
                  or else not Inspection.Exposes_Path_File_Label)
        and then (Inspection.Classification /= Projection_Surface_None
                  or else not Inspection.Exposes_Dirty_Hint)
        and then (Inspection.Classification /= Projection_Surface_None
                  or else not Inspection.Exposes_Current_Or_Open_Marker);
   end Projection_Surface_Inspection_Coherent;

   function Build_Future_Surface_Projection_Surface_Adapter
     (Surface        : Projection_Surface_Id;
      Classification : Projection_Surface_Classification)
      return Projection_Surface_Adapter
   is
      pragma Unreferenced (Classification);
   begin
      --  Template adapter for future surfaces: expose raw retained state and
      --  metadata to the shared harness.  It deliberately does not normalize,
      --  repair, infer, probe, execute commands, or mask persistence output.
      return Adapter_For_Surface (Surface);
   end Build_Future_Surface_Projection_Surface_Adapter;

   function Default_Contract
     (Surface : Projection_Surface_Id) return Projection_Surface_Contract
   is
   begin
      return (Surface => Surface, others => True);
   end Default_Contract;


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

   function Cross_Surface_Import_Name
     (Producer : Projection_Surface_Id;
      Consumer : Projection_Surface_Id) return String
   is
   begin
      return Surface_Name (Producer) & " rows -> "
        & Surface_Name (Consumer) & " lifecycle truth";
   end Cross_Surface_Import_Name;

   function Cross_Surface_Import_Forbidden
     (Producer : Projection_Surface_Id;
      Consumer : Projection_Surface_Id) return Boolean
   is
   begin
      --  A surface may of course read its own retained product state.  The
      --  shared boundary forbids only using a different projection
      --  surface's rows/candidates/results/history entries as lifecycle truth.
      return Producer /= Consumer;
   end Cross_Surface_Import_Forbidden;

   function Expected_Prompt_Boundary_Rule_Count return Natural is
   begin
      return 12;
   end Expected_Prompt_Boundary_Rule_Count;

   function Prompt_Boundary_Rule_Name
     (Index : Positive) return String
   is
   begin
      case Index is
         when 1 => return "selected/current row is not lifecycle source";
         when 2 => return "selected/current row is not lifecycle target";
         when 3 => return "query text is not target input";
         when 4 => return "row label is not target input";
         when 5 => return "retained target path is not target input";
         when 6 => return "surface interaction does not mutate prompt input";
         when 7 => return "surface does not open target prompts";
         when 8 => return "surface does not confirm target prompts";
         when 9 => return "surface does not cancel target prompts";
         when 10 => return "prompt confirmation remains Executor-routed";
         when 11 => return "prompt cancellation remains non-mutating";
         when 12 => return "prompt cleanup remains canonical";
         when others => return "";
      end case;
   end Prompt_Boundary_Rule_Name;

   function Prompt_Boundary_Rule_Holds
     (Contract : Projection_Surface_Contract;
      Index    : Positive) return Boolean
   is
   begin
      case Index is
         when 1 => return Contract.Surface_Selected_Row_Not_Source;
         when 2 => return Contract.Surface_Selected_Row_Not_Target;
         when 3 => return Contract.Surface_Query_Text_Not_Target;
         when 4 => return Contract.Surface_Row_Label_Not_Target;
         when 5 => return Contract.Surface_Retained_Target_Not_Input;
         when 6 => return Contract.Surface_Prompt_Input_Not_Mutated;
         when 7 => return Contract.Surface_Does_Not_Open_Target_Prompt;
         when 8 => return Contract.Surface_Does_Not_Confirm_Target_Prompt;
         when 9 => return Contract.Surface_Does_Not_Cancel_Target_Prompt;
         when 10 => return Contract.Prompt_Confirmation_Executor_Routed;
         when 11 => return Contract.Prompt_Cancellation_Non_Mutating;
         when 12 => return Contract.Prompt_Cleanup_Canonical;
         when others => return False;
      end case;
   end Prompt_Boundary_Rule_Holds;


   function Operation_Name
     (Operation : File_Lifecycle_Operation) return String
   is
   begin
      case Operation is
         when Save_Operation => return "file.save";
         when Save_As_Operation => return "file.save-as";
         when Rename_Operation => return "file.rename-buffer-file";
         when Copy_Operation => return "file.copy-buffer-file";
         when Move_Operation => return "file.move-buffer-file";
         when Delete_Operation => return "file.delete-buffer-file";
         when Close_Operation => return "file.close-buffer";
         when Reopen_Operation => return "file.reopen-closed-buffer";
         when Reload_Operation => return "file.reload-from-disk";
         when Revert_Operation => return "file.revert-buffer";
      end case;
   end Operation_Name;

   function Observation_Expectation
     (Operation : File_Lifecycle_Operation)
      return Projection_Surface_Observation_Expectation
   is
   begin
      case Operation is
         when Save_Operation =>
            return
              (Operation => Operation,
               Dirty_Follows_Canonical_State => True,
               Association_Follows_Canonical_Update => False,
               Row_Identity_Preserved => True,
               Row_Order_Follows_Retained_Policy => True,
               No_Surface_Specific_State => True,
               No_Target_History_Created => True,
               No_Failed_Target_Displayed => True,
               Retained_Static_Target_Not_Repaired => True,
               Projection_Unchanged_On_Failure => True,
               No_New_Target_Row_From_Operation => True,
               No_Delete_Recovery_Row => True,
               No_Reopen_Candidate_Ownership => True,
               Open_Buffer_Membership_Canonical => True,
               No_Reload_Revert_Surface_State => True);
         when Save_As_Operation | Rename_Operation | Move_Operation =>
            return
              (Operation => Operation,
               Dirty_Follows_Canonical_State => True,
               Association_Follows_Canonical_Update => True,
               Row_Identity_Preserved => True,
               Row_Order_Follows_Retained_Policy => True,
               No_Surface_Specific_State => True,
               No_Target_History_Created => True,
               No_Failed_Target_Displayed => True,
               Retained_Static_Target_Not_Repaired => True,
               Projection_Unchanged_On_Failure => True,
               No_New_Target_Row_From_Operation => True,
               No_Delete_Recovery_Row => True,
               No_Reopen_Candidate_Ownership => True,
               Open_Buffer_Membership_Canonical => True,
               No_Reload_Revert_Surface_State => True);
         when Copy_Operation =>
            return
              (Operation => Operation,
               Dirty_Follows_Canonical_State => False,
               Association_Follows_Canonical_Update => False,
               Row_Identity_Preserved => True,
               Row_Order_Follows_Retained_Policy => True,
               No_Surface_Specific_State => True,
               No_Target_History_Created => True,
               No_Failed_Target_Displayed => True,
               Retained_Static_Target_Not_Repaired => True,
               Projection_Unchanged_On_Failure => True,
               No_New_Target_Row_From_Operation => True,
               No_Delete_Recovery_Row => True,
               No_Reopen_Candidate_Ownership => True,
               Open_Buffer_Membership_Canonical => True,
               No_Reload_Revert_Surface_State => True);
         when Delete_Operation | Close_Operation | Reopen_Operation =>
            return
              (Operation => Operation,
               Dirty_Follows_Canonical_State => True,
               Association_Follows_Canonical_Update => True,
               Row_Identity_Preserved => True,
               Row_Order_Follows_Retained_Policy => True,
               No_Surface_Specific_State => True,
               No_Target_History_Created => True,
               No_Failed_Target_Displayed => True,
               Retained_Static_Target_Not_Repaired => True,
               Projection_Unchanged_On_Failure => True,
               No_New_Target_Row_From_Operation => True,
               No_Delete_Recovery_Row => True,
               No_Reopen_Candidate_Ownership => True,
               Open_Buffer_Membership_Canonical => True,
               No_Reload_Revert_Surface_State => True);
         when Reload_Operation | Revert_Operation =>
            return
              (Operation => Operation,
               Dirty_Follows_Canonical_State => True,
               Association_Follows_Canonical_Update => False,
               Row_Identity_Preserved => True,
               Row_Order_Follows_Retained_Policy => True,
               No_Surface_Specific_State => True,
               No_Target_History_Created => True,
               No_Failed_Target_Displayed => True,
               Retained_Static_Target_Not_Repaired => True,
               Projection_Unchanged_On_Failure => True,
               No_New_Target_Row_From_Operation => True,
               No_Delete_Recovery_Row => True,
               No_Reopen_Candidate_Ownership => True,
               Open_Buffer_Membership_Canonical => True,
               No_Reload_Revert_Surface_State => True);
      end case;
   end Observation_Expectation;

   function Observation_Expectation_Coherent
     (Expectation : Projection_Surface_Observation_Expectation) return Boolean
   is
   begin
      return Expectation.Row_Identity_Preserved
        and then Expectation.Row_Order_Follows_Retained_Policy
        and then Expectation.No_Surface_Specific_State
        and then Expectation.No_Target_History_Created
        and then Expectation.No_Failed_Target_Displayed
        and then Expectation.Retained_Static_Target_Not_Repaired
        and then Expectation.Projection_Unchanged_On_Failure
        and then Expectation.No_New_Target_Row_From_Operation
        and then Expectation.No_Delete_Recovery_Row
        and then Expectation.No_Reopen_Candidate_Ownership
        and then Expectation.Open_Buffer_Membership_Canonical
        and then Expectation.No_Reload_Revert_Surface_State;
   end Observation_Expectation_Coherent;

   function Surface_Operation_Observation_Coherent
     (Surface   : Projection_Surface_Id;
      Operation : File_Lifecycle_Operation) return Boolean
   is
      pragma Unreferenced (Surface);
   begin
      return Observation_Expectation_Coherent (Observation_Expectation (Operation));
   end Surface_Operation_Observation_Coherent;


   function Lifecycle_Event_Name
     (Event : Projection_Surface_Lifecycle_Event) return String
   is
   begin
      case Event is
         when Project_Close_Event => return "project close";
         when Project_Switch_Event => return "project switch";
         when Project_Reset_Event => return "project reset";
         when Workspace_Reload_Event => return "workspace reload";
         when Settings_Load_Event => return "settings load";
         when Recent_Projects_Load_Event => return "recent projects load";
         when Keybindings_Load_Event => return "keybindings load";
         when Session_Restart_Event => return "session restart";
         when Active_Buffer_Close_Event => return "active buffer close";
         when Target_Prompt_Cleanup_Event => return "target prompt lifecycle cleanup";
         when Overlay_Supersession_Event => return "overlay supersession";
         when Retained_Surface_Load_Save_Event => return "retained surface load/save";
      end case;
   end Lifecycle_Event_Name;

   function Lifecycle_Event_Expectation
     (Event : Projection_Surface_Lifecycle_Event)
      return Projection_Surface_Lifecycle_Event_Expectation
   is
   begin
      return
        (Event => Event,
         Transient_UI_Follows_Retained_Cleanup => True,
         No_Lifecycle_Observation_State => True,
         No_Target_Or_Operation_History_Survives => True,
         No_Prompt_State_Survives => True,
         Canonical_Open_Buffer_Policy_Only => True,
         Retained_Surface_Persistence_Only => True,
         Failed_Transition_Does_Not_Create_State => True);
   end Lifecycle_Event_Expectation;

   function Lifecycle_Event_Expectation_Coherent
     (Expectation : Projection_Surface_Lifecycle_Event_Expectation) return Boolean
   is
   begin
      return Expectation.Transient_UI_Follows_Retained_Cleanup
        and then Expectation.No_Lifecycle_Observation_State
        and then Expectation.No_Target_Or_Operation_History_Survives
        and then Expectation.No_Prompt_State_Survives
        and then Expectation.Canonical_Open_Buffer_Policy_Only
        and then Expectation.Retained_Surface_Persistence_Only
        and then Expectation.Failed_Transition_Does_Not_Create_State;
   end Lifecycle_Event_Expectation_Coherent;

   function Surface_Lifecycle_Event_Coherent
     (Surface : Projection_Surface_Id;
      Event   : Projection_Surface_Lifecycle_Event) return Boolean
   is
      Contract : constant Projection_Surface_Contract := Contract_For_Surface (Surface);
   begin
      return Lifecycle_Event_Expectation_Coherent (Lifecycle_Event_Expectation (Event))
        and then Surface_Does_Not_Record_Operation_Or_Target_History (Contract)
        and then Surface_Does_Not_Persist_Lifecycle_State (Contract)
        and then Surface_Does_Not_Own_Target_Prompt (Contract)
        and then Surface_Persistence_Boundary_Remains_Canonical (Contract)
        and then Surface_Behavior_Preserved (Contract);
   end Surface_Lifecycle_Event_Coherent;


   function Workflow_Context_Name
     (Context : Projection_Surface_Workflow_Context) return String
   is
   begin
      case Context is
         when Surface_Hidden_Context => return "surface hidden";
         when Surface_Visible_Context => return "surface visible";
         when Surface_Visible_Selected_Row_Context => return "surface visible with selected row";
         when Surface_Visible_Path_Like_Selected_Row_Context =>
            return "surface visible with path-like selected/current row";
         when Surface_Visible_Query_Filter_Context =>
            return "surface visible with query/filter text";
         when Surface_Visible_Current_Row_Context =>
            return "surface visible with active/current row marker";
         when All_Surfaces_Co_Visible_Context =>
            return "all covered projection surfaces co-visible";
      end case;
   end Workflow_Context_Name;

   function Reliability_Family_Name
     (Family : Projection_Surface_Reliability_Family) return String
   is
   begin
      case Family is
         when Successful_Operation_Reliability => return "successful operation observation";
         when Failed_Blocked_Operation_Preservation => return "failed/blocked operation preservation";
         when Source_Target_Boundary_Reliability => return "source/target boundary";
         when Prompt_Boundary_Reliability => return "prompt boundary";
         when Direct_Prompted_Equivalence_Reliability => return "direct/prompted equivalence";
         when Cross_Surface_Co_Visibility_Reliability => return "cross-surface co-visibility";
         when Snapshot_Freshness_Reliability => return "snapshot freshness/staleness";
         when Render_Side_Effect_Reliability => return "render side-effect freedom";
         when Route_Audit_Reliability => return "route/audit side-effect freedom";
         when Lifecycle_Cleanup_Reliability => return "lifecycle cleanup";
         when Persistence_Exclusion_Reliability => return "persistence exclusion";
      end case;
   end Reliability_Family_Name;

   function Reliability_Expectation
     (Surface   : Projection_Surface_Id;
      Family    : Projection_Surface_Reliability_Family;
      Operation : File_Lifecycle_Operation;
      Context   : Projection_Surface_Workflow_Context)
      return Projection_Surface_Reliability_Expectation
   is
      Contract : constant Projection_Surface_Contract := Contract_For_Surface (Surface);
      Adapter  : constant Projection_Surface_Adapter := Adapter_For_Surface (Surface);
      Operation_Expectation : constant Projection_Surface_Observation_Expectation :=
        Observation_Expectation (Operation);
   begin
      return
        (Surface => Surface,
         Family => Family,
         Operation => Operation,
         Context => Context,
         Adapter_Complete => Adapter_Supports_Shared_Harness (Adapter),
         Successful_Observation =>
           Surface_Operation_Observation_Coherent (Surface, Operation)
           and then Surface_Observes_Retained_Sources_Only (Contract)
           and then Surface_Does_Not_Cache_Path_Or_Dirty_Observation (Contract),
         Failure_Preservation =>
           Operation_Expectation.Projection_Unchanged_On_Failure
           and then Operation_Expectation.No_Failed_Target_Displayed
           and then Surface_Does_Not_Record_Operation_Or_Target_History (Contract),
         Source_Target_Boundary =>
           Surface_Local_UI_State_Is_Not_Lifecycle_Input (Contract)
           and then Surface_Does_Not_Infer_Source_Or_Target (Contract),
         Prompt_Boundary =>
           Surface_Does_Not_Own_Target_Prompt (Contract)
           and then Surface_Target_Prompt_Lifecycle_Is_Canonical (Contract),
         Direct_Prompted_Equivalence =>
           Surface_Command_Routes_Remain_Canonical (Contract)
           and then Surface_Target_Prompt_Lifecycle_Is_Canonical (Contract)
           and then Surface_Operation_Observation_Coherent (Surface, Operation),
         Cross_Surface_Co_Visibility =>
           Surface_Does_Not_Import_Projection_Truth (Contract)
           and then Adapter.Has_Cross_Surface_Import_Metadata,
         Snapshot_Freshness =>
           Adapter.Has_Snapshot_Freshness_Metadata
           and then Surface_Observes_Retained_Sources_Only (Contract)
           and then Surface_Render_Is_Side_Effect_Free (Contract),
         Render_Reliability =>
           Surface_Render_Is_Side_Effect_Free (Contract),
         Audit_Reliability =>
           Surface_Audit_Is_Side_Effect_Free (Contract)
           and then Surface_Command_Routes_Remain_Canonical (Contract),
         Lifecycle_Cleanup =>
           Surface_Lifecycle_Event_Coherent (Surface, Workspace_Reload_Event)
           and then Surface_Lifecycle_Event_Coherent (Surface, Target_Prompt_Cleanup_Event),
         Persistence_Exclusion =>
           Surface_Persistence_Boundary_Remains_Canonical (Contract)
           and then Adapter.Has_Persistence_Output,
         Behavior_Preserved => Surface_Behavior_Preserved (Contract));
   end Reliability_Expectation;

   function Reliability_Expectation_Coherent
     (Expectation : Projection_Surface_Reliability_Expectation) return Boolean
   is
   begin
      return Expectation.Adapter_Complete
        and then Expectation.Successful_Observation
        and then Expectation.Failure_Preservation
        and then Expectation.Source_Target_Boundary
        and then Expectation.Prompt_Boundary
        and then Expectation.Direct_Prompted_Equivalence
        and then Expectation.Cross_Surface_Co_Visibility
        and then Expectation.Snapshot_Freshness
        and then Expectation.Render_Reliability
        and then Expectation.Audit_Reliability
        and then Expectation.Lifecycle_Cleanup
        and then Expectation.Persistence_Exclusion
        and then Expectation.Behavior_Preserved;
   end Reliability_Expectation_Coherent;

   function Surface_Reliability_Coherent
     (Surface   : Projection_Surface_Id;
      Family    : Projection_Surface_Reliability_Family;
      Operation : File_Lifecycle_Operation;
      Context   : Projection_Surface_Workflow_Context) return Boolean
   is
   begin
      return Reliability_Expectation_Coherent
        (Reliability_Expectation (Surface, Family, Operation, Context));
   end Surface_Reliability_Coherent;

   function Final_Freeze_Expectation
     (Surface : Projection_Surface_Id)
      return Projection_Surface_Final_Freeze_Expectation
   is
      Contract : constant Projection_Surface_Contract := Contract_For_Surface (Surface);
      Adapter  : constant Projection_Surface_Adapter := Adapter_For_Surface (Surface);
      Result   : Projection_Surface_Audit_Result;
   begin
      Assert_File_Lifecycle_Projection_Surface_Cleanup_Coherent (Result);

      return
        (Surface => Surface,
         Shared_Invariant_Single_Authority =>
           File_Lifecycle_Projection_Surface_Cleanup_Coherent,
         Coverage_Not_Reduced => Result.Count = 0,
         Adapter_Raw_State_Frozen =>
           Adapter_Supports_Shared_Harness (Adapter)
           and then Surface_Adapter_Is_Raw_And_Nonrepairing (Contract),
         Projection_Helper_Purity_Frozen =>
           Surface_Projection_Helper_Is_Pure (Contract)
           and then Adapter.Projection_Helpers_Pure,
         Successful_Observation_Frozen =>
           Surface_Observes_Retained_Sources_Only (Contract)
           and then Surface_Operation_Observation_Coherent
             (Surface, Save_Operation)
           and then Surface_Operation_Observation_Coherent
             (Surface, Rename_Operation)
           and then Surface_Operation_Observation_Coherent
             (Surface, Delete_Operation),
         Failed_Blocked_Preservation_Frozen =>
           Surface_Operation_Observation_Coherent
             (Surface, Save_As_Operation)
           and then Surface_Operation_Observation_Coherent
             (Surface, Copy_Operation)
           and then Surface_Operation_Observation_Coherent
             (Surface, Move_Operation)
           and then Surface_Does_Not_Record_Operation_Or_Target_History
             (Contract),
         Direct_Prompted_Equivalence_Frozen =>
           Surface_Reliability_Coherent
             (Surface, Direct_Prompted_Equivalence_Reliability,
              Move_Operation, Surface_Visible_Path_Like_Selected_Row_Context),
         Source_Target_Prompt_Boundary_Frozen =>
           Surface_Source_Target_Prompt_Boundary_Is_Canonical (Contract)
           and then Surface_Target_Prompt_Lifecycle_Is_Canonical (Contract),
         Activation_Boundary_Frozen =>
           Surface_Activation_Does_Not_Execute_File_Lifecycle (Contract),
         Cross_Surface_Import_Absent_Frozen =>
           Surface_Does_Not_Import_Projection_Truth (Contract)
           and then Adapter.Has_Cross_Surface_Import_Metadata,
         Render_Boundary_Frozen => Surface_Render_Is_Side_Effect_Free (Contract),
         Audit_Boundary_Frozen => Surface_Audit_Is_Side_Effect_Free (Contract),
         Lifecycle_Cleanup_Frozen =>
           Surface_Lifecycle_Event_Coherent (Surface, Project_Close_Event)
           and then Surface_Lifecycle_Event_Coherent
             (Surface, Workspace_Reload_Event)
           and then Surface_Lifecycle_Event_Coherent
             (Surface, Target_Prompt_Cleanup_Event),
         Persistence_Exclusion_Frozen =>
           Surface_Persistence_Boundary_Remains_Canonical (Contract)
           and then Adapter.Has_Persistence_Output,
         Removed_Field_Drop_Frozen => Contract.Removed_Lifecycle_Fields_Dropped,
         Duplicate_Ownership_Absent_Frozen =>
           Surface_Does_Not_Own_File_Lifecycle_Routes (Contract)
           and then Surface_Does_Not_Own_Target_Prompt (Contract)
           and then Surface_Does_Not_Persist_Lifecycle_State (Contract)
           and then Contract.No_Duplicate_Lifecycle_State,
         Behavior_Preserved => Surface_Behavior_Preserved (Contract));
   end Final_Freeze_Expectation;

   function Final_Freeze_Expectation_Coherent
     (Expectation : Projection_Surface_Final_Freeze_Expectation) return Boolean
   is
   begin
      return Expectation.Shared_Invariant_Single_Authority
        and then Expectation.Coverage_Not_Reduced
        and then Expectation.Adapter_Raw_State_Frozen
        and then Expectation.Projection_Helper_Purity_Frozen
        and then Expectation.Successful_Observation_Frozen
        and then Expectation.Failed_Blocked_Preservation_Frozen
        and then Expectation.Direct_Prompted_Equivalence_Frozen
        and then Expectation.Source_Target_Prompt_Boundary_Frozen
        and then Expectation.Activation_Boundary_Frozen
        and then Expectation.Cross_Surface_Import_Absent_Frozen
        and then Expectation.Render_Boundary_Frozen
        and then Expectation.Audit_Boundary_Frozen
        and then Expectation.Lifecycle_Cleanup_Frozen
        and then Expectation.Persistence_Exclusion_Frozen
        and then Expectation.Removed_Field_Drop_Frozen
        and then Expectation.Duplicate_Ownership_Absent_Frozen
        and then Expectation.Behavior_Preserved;
   end Final_Freeze_Expectation_Coherent;

   function Surface_Final_Freeze_Coherent
     (Surface : Projection_Surface_Id) return Boolean
   is
   begin
      return Final_Freeze_Expectation_Coherent
        (Final_Freeze_Expectation (Surface));
   end Surface_Final_Freeze_Coherent;


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

   procedure Validate_Projection_Surface_Registration
     (Result       : in out Projection_Surface_Audit_Result;
      Registration : Projection_Surface_Registration)
   is
   begin
      if Registration_Lifecycle_Sensitive (Registration)
        and then not Registration.Is_Registered
      then
         Add_Failure
           (Result, Registration.Surface,
            "lifecycle-sensitive projection surface is not registered");
      end if;

      if Registration.Classification /= Projection_Surface_None
        and then not Registration.Runs_Shared_Invariant_Harness
      then
         Add_Failure
           (Result, Registration.Surface,
            "registered projection surface does not run shared invariant harness");
      end if;

      if Registration.Is_Registered and then not Registration.Has_Surface_Adapter_Factory then
         Add_Failure (Result, Registration.Surface, "registration does not expose adapter factory");
      end if;
      if Registration.Is_Registered and then not Registration.Has_Forbidden_Field_Metadata then
         Add_Failure (Result, Registration.Surface, "registration does not expose forbidden field metadata");
      end if;
      if Registration.Is_Registered and then not Registration.Has_Forbidden_Route_Metadata then
         Add_Failure (Result, Registration.Surface, "registration does not expose forbidden route metadata");
      end if;
      if Registration.Has_Retained_Persistence and then not Registration.Has_Persistence_Inspection_Hook then
         Add_Failure (Result, Registration.Surface, "retained surface persistence lacks inspection hook");
      end if;
      if Registration.Is_Registered and then not Registration.Has_Render_Snapshot_Inspection_Hook then
         Add_Failure (Result, Registration.Surface, "registration does not expose render snapshot inspection hook");
      end if;

      if Registration.Is_Registered then
         Validate_Adapter (Result, Adapter_For_Surface (Registration.Surface));
      end if;
   end Validate_Projection_Surface_Registration;

   procedure Validate_Projection_Surface_Inspection
     (Result     : in out Projection_Surface_Audit_Result;
      Inspection : Projection_Surface_Inspection)
   is
      Sensitive : constant Boolean :=
        Projection_Surface_Inspection_Lifecycle_Sensitive (Inspection);
   begin
      if Inspection.Has_Explicit_Audit_Exemption then
         if Inspection.Registered then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "audit exemption cannot replace an existing registration");
         end if;
         if Inspection.Classification /= Projection_Surface_None then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "audit exemption must remain non-lifecycle classified");
         end if;
         if Inspection.Has_Local_Lifecycle_Route then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "audit exemption cannot allow local lifecycle route");
         end if;
         if Inspection.Has_Lifecycle_Persistence_Field then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "audit exemption cannot allow lifecycle persistence field");
         end if;
         if Inspection.Has_Retained_Persistence then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "audit exemption cannot hide retained persistence");
         end if;
         return;
      end if;

      if Sensitive and then not Inspection.Registered then
         Add_Failure
           (Result, Open_Buffer_Switcher_Surface,
            "unregistered projection surface exposes lifecycle-sensitive row state");
      end if;

      if Inspection.Classification = Projection_Surface_None then
         if Inspection.Exposes_Buffer_Identity then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "none-classified surface exposes buffer identity");
         end if;
         if Inspection.Exposes_Retained_Target then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "none-classified surface exposes retained target");
         end if;
         if Inspection.Exposes_Path_File_Label then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "none-classified surface exposes path/file label");
         end if;
         if Inspection.Exposes_Dirty_Hint then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "none-classified surface exposes dirty hint");
         end if;
         if Inspection.Exposes_Current_Or_Open_Marker then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "none-classified surface exposes current/open marker");
         end if;
      end if;

      if not Inspection.Registered then
         if Inspection.Has_Local_Lifecycle_Route then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "unregistered surface owns local lifecycle route");
         end if;
         if Inspection.Has_Target_Prompt_Ownership then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "unregistered surface owns target prompt");
         end if;
         if Inspection.Has_Source_Override_Or_Target_Inference then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "unregistered surface owns source override or target inference");
         end if;
         if Inspection.Has_Repair_Migration_Or_Probe then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "unregistered surface owns repair, migration, or filesystem probe");
         end if;
         if Inspection.Has_Cross_Surface_Import then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "unregistered surface imports cross-surface projection truth");
         end if;
         if Inspection.Has_Retained_Persistence then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "unregistered surface has retained persistence without gate");
         end if;
         if Inspection.Has_Lifecycle_Persistence_Field then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "unregistered surface persists lifecycle observation field");
         end if;
      end if;
   end Validate_Projection_Surface_Inspection;

   procedure Validate_Surface_Operation
     (Result    : in out Projection_Surface_Audit_Result;
      Surface   : Projection_Surface_Id;
      Operation : File_Lifecycle_Operation)
   is
      Expectation : constant Projection_Surface_Observation_Expectation :=
        Observation_Expectation (Operation);
   begin
      if not Expectation.Row_Identity_Preserved then
         Add_Failure (Result, Surface, Operation_Name (Operation) & " changes retained row identity");
      end if;
      if not Expectation.Row_Order_Follows_Retained_Policy then
         Add_Failure (Result, Surface, Operation_Name (Operation) & " changes row order outside retained policy");
      end if;
      if not Expectation.No_Surface_Specific_State then
         Add_Failure (Result, Surface, Operation_Name (Operation) & " creates surface-specific lifecycle state");
      end if;
      if not Expectation.No_Target_History_Created then
         Add_Failure (Result, Surface, Operation_Name (Operation) & " creates target history");
      end if;
      if not Expectation.No_Failed_Target_Displayed then
         Add_Failure (Result, Surface, Operation_Name (Operation) & " displays failed target path");
      end if;
      if not Expectation.Retained_Static_Target_Not_Repaired then
         Add_Failure (Result, Surface, Operation_Name (Operation) & " repairs retained static targets");
      end if;
      if not Expectation.Projection_Unchanged_On_Failure then
         Add_Failure (Result, Surface, Operation_Name (Operation) & " mutates projection after failed operation");
      end if;
      if not Expectation.No_New_Target_Row_From_Operation then
         Add_Failure (Result, Surface, Operation_Name (Operation) & " creates a new row from lifecycle target");
      end if;
      if not Expectation.No_Delete_Recovery_Row then
         Add_Failure (Result, Surface, Operation_Name (Operation) & " creates delete recovery row");
      end if;
      if not Expectation.No_Reopen_Candidate_Ownership then
         Add_Failure (Result, Surface, Operation_Name (Operation) & " owns reopen candidates");
      end if;
      if not Expectation.Open_Buffer_Membership_Canonical then
         Add_Failure (Result, Surface, Operation_Name (Operation) & " observes open-buffer membership outside canonical collection");
      end if;
      if not Expectation.No_Reload_Revert_Surface_State then
         Add_Failure (Result, Surface, Operation_Name (Operation) & " creates reload/revert surface state");
      end if;
   end Validate_Surface_Operation;

   procedure Validate_Surface_Lifecycle_Event
     (Result  : in out Projection_Surface_Audit_Result;
      Surface : Projection_Surface_Id;
      Event   : Projection_Surface_Lifecycle_Event)
   is
      Expectation : constant Projection_Surface_Lifecycle_Event_Expectation :=
        Lifecycle_Event_Expectation (Event);
      Contract : constant Projection_Surface_Contract := Contract_For_Surface (Surface);
   begin
      if not Expectation.Transient_UI_Follows_Retained_Cleanup then
         Add_Failure (Result, Surface, Lifecycle_Event_Name (Event) & " ignores retained transient cleanup policy");
      end if;
      if not Expectation.No_Lifecycle_Observation_State
        or else not Surface_Does_Not_Persist_Lifecycle_State (Contract)
      then
         Add_Failure (Result, Surface, Lifecycle_Event_Name (Event) & " creates lifecycle observation state");
      end if;
      if not Expectation.No_Target_Or_Operation_History_Survives
        or else not Surface_Does_Not_Record_Operation_Or_Target_History (Contract)
      then
         Add_Failure (Result, Surface, Lifecycle_Event_Name (Event) & " preserves target or operation history");
      end if;
      if not Expectation.No_Prompt_State_Survives
        or else not Surface_Does_Not_Own_Target_Prompt (Contract)
      then
         Add_Failure (Result, Surface, Lifecycle_Event_Name (Event) & " preserves prompt-owned state");
      end if;
      if not Expectation.Canonical_Open_Buffer_Policy_Only then
         Add_Failure (Result, Surface, Lifecycle_Event_Name (Event) & " restores open buffers outside canonical policy");
      end if;
      if not Expectation.Retained_Surface_Persistence_Only
        or else not Surface_Persistence_Boundary_Remains_Canonical (Contract)
      then
         Add_Failure (Result, Surface, Lifecycle_Event_Name (Event) & " restores lifecycle state through surface persistence");
      end if;
      if not Expectation.Failed_Transition_Does_Not_Create_State then
         Add_Failure (Result, Surface, Lifecycle_Event_Name (Event) & " creates state after failed lifecycle transition");
      end if;
   end Validate_Surface_Lifecycle_Event;


   procedure Validate_Cross_Surface_Import
     (Result   : in out Projection_Surface_Audit_Result;
      Producer : Projection_Surface_Id;
      Consumer : Projection_Surface_Id)
   is
   begin
      if Producer /= Consumer and then not Cross_Surface_Import_Forbidden (Producer, Consumer) then
         Add_Failure
           (Result, Consumer,
            "allows forbidden cross-surface import: "
            & Cross_Surface_Import_Name (Producer, Consumer));
      end if;

      if Producer = Consumer and then Cross_Surface_Import_Forbidden (Producer, Consumer) then
         Add_Failure
           (Result, Consumer,
            "rejects own retained source as though it were a cross-surface import");
      end if;
   end Validate_Cross_Surface_Import;


   procedure Validate_Surface_Reliability
     (Result    : in out Projection_Surface_Audit_Result;
      Surface   : Projection_Surface_Id;
      Family    : Projection_Surface_Reliability_Family;
      Operation : File_Lifecycle_Operation;
      Context   : Projection_Surface_Workflow_Context)
   is
      Expectation : constant Projection_Surface_Reliability_Expectation :=
        Reliability_Expectation (Surface, Family, Operation, Context);
      Prefix : constant String := Reliability_Family_Name (Family)
        & " / " & Operation_Name (Operation)
        & " / " & Workflow_Context_Name (Context) & ": ";
   begin
      if not Expectation.Adapter_Complete then
         Add_Failure (Result, Surface, Prefix & "adapter is not complete for shared reliability harness");
      end if;
      if not Expectation.Successful_Observation then
         Add_Failure (Result, Surface, Prefix & "successful observation is not derived from retained canonical sources");
      end if;
      if not Expectation.Failure_Preservation then
         Add_Failure (Result, Surface, Prefix & "failed/blocked operations leak or mutate projection state");
      end if;
      if not Expectation.Source_Target_Boundary then
         Add_Failure (Result, Surface, Prefix & "surface UI state can become lifecycle source or target");
      end if;
      if not Expectation.Prompt_Boundary then
         Add_Failure (Result, Surface, Prefix & "surface owns or mutates target prompt state");
      end if;
      if not Expectation.Direct_Prompted_Equivalence then
         Add_Failure (Result, Surface, Prefix & "direct and prompted command observations diverge");
      end if;
      if not Expectation.Cross_Surface_Co_Visibility then
         Add_Failure (Result, Surface, Prefix & "co-visible surfaces can import projection truth");
      end if;
      if not Expectation.Snapshot_Freshness then
         Add_Failure (Result, Surface, Prefix & "fresh snapshots do not remain canonical or stale snapshots are repaired");
      end if;
      if not Expectation.Render_Reliability then
         Add_Failure (Result, Surface, Prefix & "render path has lifecycle side effects");
      end if;
      if not Expectation.Audit_Reliability then
         Add_Failure (Result, Surface, Prefix & "route/configuration audit is not side-effect-free or canonical");
      end if;
      if not Expectation.Lifecycle_Cleanup then
         Add_Failure (Result, Surface, Prefix & "lifecycle cleanup restores projection lifecycle state");
      end if;
      if not Expectation.Persistence_Exclusion then
         Add_Failure (Result, Surface, Prefix & "persistence leaks projection lifecycle state");
      end if;
      if not Expectation.Behavior_Preserved then
         Add_Failure (Result, Surface, Prefix & "prior behavior is not preserved");
      end if;
   end Validate_Surface_Reliability;


   procedure Validate_Surface_Final_Freeze
     (Result  : in out Projection_Surface_Audit_Result;
      Surface : Projection_Surface_Id)
   is
      Expectation : constant Projection_Surface_Final_Freeze_Expectation :=
        Final_Freeze_Expectation (Surface);
      Prefix : constant String := "final freeze: ";
   begin
      if not Expectation.Shared_Invariant_Single_Authority then
         Add_Failure
           (Result, Surface,
            Prefix & "shared invariant is not the single lifecycle-observation authority");
      end if;
      if not Expectation.Coverage_Not_Reduced then
         Add_Failure
           (Result, Surface, Prefix & "shared coverage was reduced or bypassed");
      end if;
      if not Expectation.Adapter_Raw_State_Frozen then
         Add_Failure
           (Result, Surface, Prefix & "adapter raw-state contract is not frozen");
      end if;
      if not Expectation.Projection_Helper_Purity_Frozen then
         Add_Failure
           (Result, Surface, Prefix & "projection helper purity is not frozen");
      end if;
      if not Expectation.Successful_Observation_Frozen then
         Add_Failure
           (Result, Surface, Prefix & "successful lifecycle observation is not frozen");
      end if;
      if not Expectation.Failed_Blocked_Preservation_Frozen then
         Add_Failure
           (Result, Surface, Prefix & "failed/blocked preservation is not frozen");
      end if;
      if not Expectation.Direct_Prompted_Equivalence_Frozen then
         Add_Failure
           (Result, Surface, Prefix & "direct/prompted equivalence is not frozen");
      end if;
      if not Expectation.Source_Target_Prompt_Boundary_Frozen then
         Add_Failure
           (Result, Surface, Prefix & "source/target/prompt boundary is not frozen");
      end if;
      if not Expectation.Activation_Boundary_Frozen then
         Add_Failure
           (Result, Surface, Prefix & "activation boundary is not frozen");
      end if;
      if not Expectation.Cross_Surface_Import_Absent_Frozen then
         Add_Failure
           (Result, Surface, Prefix & "cross-surface import absence is not frozen");
      end if;
      if not Expectation.Render_Boundary_Frozen then
         Add_Failure
           (Result, Surface, Prefix & "render boundary is not frozen");
      end if;
      if not Expectation.Audit_Boundary_Frozen then
         Add_Failure
           (Result, Surface, Prefix & "audit boundary is not frozen");
      end if;
      if not Expectation.Lifecycle_Cleanup_Frozen then
         Add_Failure
           (Result, Surface, Prefix & "lifecycle cleanup boundary is not frozen");
      end if;
      if not Expectation.Persistence_Exclusion_Frozen then
         Add_Failure
           (Result, Surface, Prefix & "persistence exclusion is not frozen");
      end if;
      if not Expectation.Removed_Field_Drop_Frozen then
         Add_Failure
           (Result, Surface, Prefix & "removed field drop behavior is not frozen");
      end if;
      if not Expectation.Duplicate_Ownership_Absent_Frozen then
         Add_Failure
           (Result, Surface, Prefix & "duplicate per-surface ownership is reachable");
      end if;
      if not Expectation.Behavior_Preserved then
         Add_Failure
           (Result, Surface, Prefix & "prior behavior is not preserved");
      end if;
   end Validate_Surface_Final_Freeze;


   procedure Clear (Result : in out Projection_Surface_Audit_Result) is
   begin
      Result.Count := 0;
      Result.Failures := (others => Null_Unbounded_String);
   end Clear;

   procedure Validate_Surface
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
   is
      S : constant Projection_Surface_Id := Contract.Surface;
   begin
      if not Contract.Observes_Retained_Sources_Only then
         Add_Failure (Result, S, "does not observe retained canonical sources only");
      end if;
      if not Contract.No_Duplicate_Lifecycle_State then
         Add_Failure (Result, S, "owns duplicate lifecycle observation state");
      end if;
      if not Contract.No_File_Lifecycle_Routes then
         Add_Failure (Result, S, "owns local file lifecycle routes");
      end if;
      if not Contract.No_Target_Prompt_Ownership then
         Add_Failure (Result, S, "owns target prompt state or routes");
      end if;
      if not Contract.No_Source_Or_Target_Inference then
         Add_Failure (Result, S, "infers lifecycle source or target from UI state");
      end if;
      if not Contract.No_Association_Repair then
         Add_Failure (Result, S, "repairs buffer/file associations");
      end if;
      if not Contract.No_Retained_Target_Repair then
         Add_Failure (Result, S, "repairs retained targets");
      end if;
      if not Contract.No_Target_Migration then
         Add_Failure (Result, S, "migrates retained targets");
      end if;
      if not Contract.No_Filesystem_Probe then
         Add_Failure (Result, S, "probes filesystem for lifecycle observation");
      end if;
      if not Contract.No_Operation_History then
         Add_Failure (Result, S, "records operation history");
      end if;
      if not Contract.No_Target_History then
         Add_Failure (Result, S, "records target history");
      end if;
      if not Contract.No_Stale_Path_Label_Cache then
         Add_Failure (Result, S, "caches stale path labels");
      end if;
      if not Contract.No_Dirty_Hint_Cache then
         Add_Failure (Result, S, "caches dirty hints");
      end if;
      if not Contract.Row_Identity_Not_Path_Label then
         Add_Failure (Result, S, "derives row identity from path labels");
      end if;
      if not Contract.Row_Order_Retained_Policy then
         Add_Failure (Result, S, "derives row order from lifecycle observations");
      end if;
      if not Contract.Selection_Query_Local_Only then
         Add_Failure (Result, S, "promotes query/selection UI state to lifecycle input");
      end if;
      if not Contract.Activation_Not_Lifecycle_Command then
         Add_Failure (Result, S, "executes file lifecycle commands during surface activation");
      end if;
      if not Contract.No_Cross_Surface_Projection_Imports then
         Add_Failure (Result, S, "imports another projection surface as lifecycle truth");
      end if;
      if not Surface_Adapter_Is_Raw_And_Nonrepairing (Contract) then
         Add_Failure (Result, S, "adapter is not raw retained state or performs lifecycle repair/normalization");
      end if;
      if not Surface_Projection_Helper_Is_Pure (Contract) then
         Add_Failure (Result, S, "projection helper reads lifecycle inputs outside retained canonical sources");
      end if;
      if not Contract.No_Lifecycle_Persistence_State then
         Add_Failure (Result, S, "persists lifecycle observation/cache/history state");
      end if;
      if not Contract.Source_Target_Prompt_Boundary then
         Add_Failure (Result, S, "allows surface UI state to become lifecycle source/target/prompt state");
      end if;
      for Rule in 1 .. Expected_Prompt_Boundary_Rule_Count loop
         if not Prompt_Boundary_Rule_Holds (Contract, Rule) then
            Add_Failure (Result, S, "breaks prompt/source/target boundary: "
                         & Prompt_Boundary_Rule_Name (Rule));
         end if;
      end loop;
      if not Surface_Target_Prompt_Lifecycle_Is_Canonical (Contract) then
         Add_Failure (Result, S, "target prompt lifecycle is not canonical Executor/cleanup-owned behavior");
      end if;
      if not Contract.Render_Side_Effect_Free then
         Add_Failure (Result, S, "render path is not side-effect-free");
      end if;
      if not Contract.Render_Consumes_Snapshots_Only then
         Add_Failure (Result, S, "render path consumes non-snapshot lifecycle truth");
      end if;
      if not Contract.No_Forbidden_Rendered_Lifecycle_Fields then
         Add_Failure (Result, S, "render path exposes forbidden lifecycle-local fields");
      end if;
      if not Contract.No_Render_Lifecycle_State then
         Add_Failure (Result, S, "render path owns projection lifecycle state");
      end if;
      if not Contract.Audit_Side_Effect_Free then
         Add_Failure (Result, S, "audit path is not side-effect-free");
      end if;
      if not Contract.Audit_Not_Product_Truth then
         Add_Failure (Result, S, "audit path becomes product truth");
      end if;
      if not Contract.No_Audit_Product_Truth_State then
         Add_Failure (Result, S, "audit helper owns product truth state");
      end if;
      if not Contract.File_Lifecycle_Commands_Executor_Routed then
         Add_Failure (Result, S, "file lifecycle commands no longer route through Executor");
      end if;
      if not Contract.Command_Invocation_Surface_Canonical then
         Add_Failure (Result, S, "Command Palette/keybinding invocation is not descriptor/canonical-command based");
      end if;
      if not Contract.Persistence_Domains_Separated then
         Add_Failure (Result, S, "settings/workspace/recent/keybinding persistence domains are not separated");
      end if;
      if not Contract.Removed_Lifecycle_Fields_Dropped then
         Add_Failure (Result, S, "removed projection lifecycle fields survive load/save cleanup");
      end if;
      if not Contract.Behavior_Preserved then
         Add_Failure (Result, S, "previous per-surface behavior is not preserved");
      end if;
   end Validate_Surface;

   procedure Validate_All_Covered_Surfaces
     (Result : in out Projection_Surface_Audit_Result)
   is
   begin
      for Surface in Projection_Surface_Id loop
         Validate_Adapter (Result, Adapter_For_Surface (Surface));
         Validate_Surface (Result, Contract_For_Surface (Surface));
         for Operation in File_Lifecycle_Operation loop
            Validate_Surface_Operation (Result, Surface, Operation);
         end loop;
         for Event in Projection_Surface_Lifecycle_Event loop
            Validate_Surface_Lifecycle_Event (Result, Surface, Event);
         end loop;
         for Producer in Projection_Surface_Id loop
            Validate_Cross_Surface_Import (Result, Producer, Surface);
         end loop;
         for Family in Projection_Surface_Reliability_Family loop
            for Operation in File_Lifecycle_Operation loop
               for Context in Projection_Surface_Workflow_Context loop
                  Validate_Surface_Reliability
                    (Result, Surface, Family, Operation, Context);
               end loop;
            end loop;
         end loop;
      end loop;
   end Validate_All_Covered_Surfaces;

   function Contract_For_Surface
     (Surface : Projection_Surface_Id) return Projection_Surface_Contract
   is
      C : Projection_Surface_Contract := Default_Contract (Surface);
   begin
      case Surface is
         when Open_Buffer_Switcher_Surface =>
            declare
               State : Editor.Buffer_Switcher.Buffer_Switcher_State;
            begin
               C.Observes_Retained_Sources_Only :=
                 Editor.Buffer_Switcher.Open_Buffer_Switcher_File_Lifecycle_Observation_Frozen (State);
               C.No_Duplicate_Lifecycle_State :=
                 Editor.Buffer_Switcher.Open_Buffer_Switcher_No_Duplicate_Lifecycle_State (State);
               C.No_Target_Prompt_Ownership :=
                 Editor.Buffer_Switcher.Open_Buffer_Switcher_No_Prompt_State (State);
               C.No_Source_Or_Target_Inference :=
                 Editor.Buffer_Switcher.Open_Buffer_Switcher_No_File_Lifecycle_Source_Override (State);
               C.Source_Target_Prompt_Boundary :=
                 C.No_Target_Prompt_Ownership
                 and then C.No_Source_Or_Target_Inference;
               C.Selection_Query_Local_Only := C.Source_Target_Prompt_Boundary;
               C.Activation_Not_Lifecycle_Command := C.No_File_Lifecycle_Routes;
               C.Row_Identity_Not_Path_Label := C.No_Duplicate_Lifecycle_State;
               C.Row_Order_Retained_Policy := C.Observes_Retained_Sources_Only;
               C.Adapter_Raw_Retained_State :=
                 C.Observes_Retained_Sources_Only
                 and then C.No_Duplicate_Lifecycle_State;
               C.No_Adapter_Lifecycle_Normalization :=
                 C.No_Duplicate_Lifecycle_State
                 and then C.No_Stale_Path_Label_Cache
                 and then C.No_Dirty_Hint_Cache;
               C.Projection_Helpers_Retained_Only := C.Observes_Retained_Sources_Only;
               C.Projection_Helpers_No_Lifecycle_Inputs :=
                 C.No_Operation_History
                 and then C.No_Target_History
                 and then C.No_Target_Prompt_Ownership
                 and then C.No_Filesystem_Probe
                 and then C.No_Association_Repair
                 and then C.No_Retained_Target_Repair
                 and then C.No_Target_Migration
                 and then C.No_Cross_Surface_Projection_Imports;
               C.No_Render_Lifecycle_State :=
                 C.Render_Side_Effect_Free
                 and then C.Render_Consumes_Snapshots_Only
                 and then C.No_Forbidden_Rendered_Lifecycle_Fields;
               C.No_Audit_Product_Truth_State :=
                 C.Audit_Side_Effect_Free
                 and then C.Audit_Not_Product_Truth;
               C.Behavior_Preserved :=
                 Editor.Buffer_Switcher.Open_Buffer_Switcher_File_Lifecycle_Observation_Frozen (State);
            end;

         when Quick_Open_Surface =>
            declare
               State : Editor.Quick_Open.Quick_Open_State;
            begin
               C.Observes_Retained_Sources_Only :=
                 Editor.Quick_Open.Quick_Open_File_Lifecycle_Observation_Canonical (State);
               C.No_Duplicate_Lifecycle_State :=
                 Editor.Quick_Open.Quick_Open_No_Duplicate_Lifecycle_State (State);
               C.No_Target_Prompt_Ownership :=
                 Editor.Quick_Open.Quick_Open_No_Prompt_State (State);
               C.No_Source_Or_Target_Inference :=
                 Editor.Quick_Open.Quick_Open_Query_Selection_Source_Target_Boundary (State);
               C.Source_Target_Prompt_Boundary :=
                 C.No_Target_Prompt_Ownership
                 and then C.No_Source_Or_Target_Inference;
               C.Selection_Query_Local_Only := C.Source_Target_Prompt_Boundary;
               C.Activation_Not_Lifecycle_Command := C.No_File_Lifecycle_Routes;
               C.Row_Identity_Not_Path_Label := C.No_Duplicate_Lifecycle_State;
               C.Row_Order_Retained_Policy := C.Observes_Retained_Sources_Only;
               C.Adapter_Raw_Retained_State :=
                 C.Observes_Retained_Sources_Only
                 and then C.No_Duplicate_Lifecycle_State;
               C.No_Adapter_Lifecycle_Normalization :=
                 C.No_Duplicate_Lifecycle_State
                 and then C.No_Stale_Path_Label_Cache
                 and then C.No_Dirty_Hint_Cache;
               C.Projection_Helpers_Retained_Only := C.Observes_Retained_Sources_Only;
               C.Projection_Helpers_No_Lifecycle_Inputs :=
                 C.No_Operation_History
                 and then C.No_Target_History
                 and then C.No_Target_Prompt_Ownership
                 and then C.No_Filesystem_Probe
                 and then C.No_Association_Repair
                 and then C.No_Retained_Target_Repair
                 and then C.No_Target_Migration
                 and then C.No_Cross_Surface_Projection_Imports;
               C.No_Render_Lifecycle_State :=
                 C.Render_Side_Effect_Free
                 and then C.Render_Consumes_Snapshots_Only
                 and then C.No_Forbidden_Rendered_Lifecycle_Fields;
               C.No_Audit_Product_Truth_State :=
                 C.Audit_Side_Effect_Free
                 and then C.Audit_Not_Product_Truth;
               C.Behavior_Preserved :=
                 Editor.Quick_Open.Quick_Open_File_Lifecycle_Observation_Frozen (State);
            end;

         when Project_Search_Surface =>
            declare
               State : Editor.Project_Search.Project_Search_State;
            begin
               C.Observes_Retained_Sources_Only :=
                 Editor.Project_Search.Project_Search_Project_Source_Boundary_Canonical (State)
                 and then Editor.Project_Search.Project_Search_File_Lifecycle_Observation_Canonical (State);
               C.No_Duplicate_Lifecycle_State :=
                 Editor.Project_Search.Project_Search_No_Duplicate_Lifecycle_State (State);
               C.No_Target_Prompt_Ownership :=
                 Editor.Project_Search.Project_Search_No_Prompt_State (State);
               C.No_Source_Or_Target_Inference :=
                 Editor.Project_Search.Project_Search_Query_Selection_Source_Target_Boundary (State);
               C.Source_Target_Prompt_Boundary :=
                 C.No_Target_Prompt_Ownership
                 and then C.No_Source_Or_Target_Inference;
               C.Selection_Query_Local_Only := C.Source_Target_Prompt_Boundary;
               C.Activation_Not_Lifecycle_Command := C.No_File_Lifecycle_Routes;
               C.Row_Identity_Not_Path_Label := C.No_Duplicate_Lifecycle_State;
               C.Row_Order_Retained_Policy := C.Observes_Retained_Sources_Only;
               C.Adapter_Raw_Retained_State :=
                 C.Observes_Retained_Sources_Only
                 and then C.No_Duplicate_Lifecycle_State;
               C.No_Adapter_Lifecycle_Normalization :=
                 C.No_Duplicate_Lifecycle_State
                 and then C.No_Stale_Path_Label_Cache
                 and then C.No_Dirty_Hint_Cache;
               C.Projection_Helpers_Retained_Only := C.Observes_Retained_Sources_Only;
               C.Projection_Helpers_No_Lifecycle_Inputs :=
                 C.No_Operation_History
                 and then C.No_Target_History
                 and then C.No_Target_Prompt_Ownership
                 and then C.No_Filesystem_Probe
                 and then C.No_Association_Repair
                 and then C.No_Retained_Target_Repair
                 and then C.No_Target_Migration
                 and then C.No_Cross_Surface_Projection_Imports;
               C.No_Render_Lifecycle_State :=
                 C.Render_Side_Effect_Free
                 and then C.Render_Consumes_Snapshots_Only
                 and then C.No_Forbidden_Rendered_Lifecycle_Fields;
               C.No_Audit_Product_Truth_State :=
                 C.Audit_Side_Effect_Free
                 and then C.Audit_Not_Product_Truth;
               C.Behavior_Preserved :=
                 Editor.Project_Search.Project_Search_File_Lifecycle_Observation_Frozen (State);
            end;

         when Bookmarks_Surface =>
            declare
               State : Editor.Bookmarks.Bookmark_State;
            begin
               C.Observes_Retained_Sources_Only :=
                 Editor.Bookmarks.Bookmark_Row_Projection_Canonical (State)
                 and then Editor.Bookmarks.Bookmarks_File_Lifecycle_Observation_Canonical (State);
               C.No_Duplicate_Lifecycle_State :=
                 Editor.Bookmarks.Bookmarks_No_Duplicate_Lifecycle_State (State);
               C.No_Target_Prompt_Ownership :=
                 Editor.Bookmarks.Bookmarks_No_Prompt_State (State);
               C.No_Source_Or_Target_Inference :=
                 Editor.Bookmarks.Bookmark_Selection_Source_Target_Boundary (State);
               C.Source_Target_Prompt_Boundary :=
                 C.No_Target_Prompt_Ownership
                 and then C.No_Source_Or_Target_Inference;
               C.Selection_Query_Local_Only := C.Source_Target_Prompt_Boundary;
               C.Activation_Not_Lifecycle_Command := C.No_File_Lifecycle_Routes;
               C.Row_Identity_Not_Path_Label := C.No_Duplicate_Lifecycle_State;
               C.Row_Order_Retained_Policy := C.Observes_Retained_Sources_Only;
               C.Adapter_Raw_Retained_State :=
                 C.Observes_Retained_Sources_Only
                 and then C.No_Duplicate_Lifecycle_State;
               C.No_Adapter_Lifecycle_Normalization :=
                 C.No_Duplicate_Lifecycle_State
                 and then C.No_Stale_Path_Label_Cache
                 and then C.No_Dirty_Hint_Cache;
               C.Projection_Helpers_Retained_Only := C.Observes_Retained_Sources_Only;
               C.Projection_Helpers_No_Lifecycle_Inputs :=
                 C.No_Operation_History
                 and then C.No_Target_History
                 and then C.No_Target_Prompt_Ownership
                 and then C.No_Filesystem_Probe
                 and then C.No_Association_Repair
                 and then C.No_Retained_Target_Repair
                 and then C.No_Target_Migration
                 and then C.No_Cross_Surface_Projection_Imports;
               C.No_Render_Lifecycle_State :=
                 C.Render_Side_Effect_Free
                 and then C.Render_Consumes_Snapshots_Only
                 and then C.No_Forbidden_Rendered_Lifecycle_Fields;
               C.No_Audit_Product_Truth_State :=
                 C.Audit_Side_Effect_Free
                 and then C.Audit_Not_Product_Truth;
               C.Behavior_Preserved :=
                 Editor.Bookmarks.Bookmarks_File_Lifecycle_Observation_Final_Frozen (State);
            end;

         when Navigation_History_Surface =>
            declare
               State : Editor.Navigation_History.Navigation_History_State;
            begin
               C.Observes_Retained_Sources_Only :=
                 Editor.Navigation_History.Navigation_History_File_Lifecycle_Observation_Canonical (State);
               C.No_Duplicate_Lifecycle_State :=
                 Editor.Navigation_History.Navigation_History_No_Duplicate_Lifecycle_State (State);
               C.No_Target_Prompt_Ownership :=
                 Editor.Navigation_History.Navigation_History_No_Prompt_State (State);
               C.No_Source_Or_Target_Inference :=
                 Editor.Navigation_History.Navigation_History_Source_Target_Boundary (State);
               C.Source_Target_Prompt_Boundary :=
                 C.No_Target_Prompt_Ownership
                 and then C.No_Source_Or_Target_Inference;
               C.Selection_Query_Local_Only := C.Source_Target_Prompt_Boundary;
               C.Activation_Not_Lifecycle_Command := C.No_File_Lifecycle_Routes;
               C.Row_Identity_Not_Path_Label := C.No_Duplicate_Lifecycle_State;
               C.Row_Order_Retained_Policy := C.Observes_Retained_Sources_Only;
               C.Adapter_Raw_Retained_State :=
                 C.Observes_Retained_Sources_Only
                 and then C.No_Duplicate_Lifecycle_State;
               C.No_Adapter_Lifecycle_Normalization :=
                 C.No_Duplicate_Lifecycle_State
                 and then C.No_Stale_Path_Label_Cache
                 and then C.No_Dirty_Hint_Cache;
               C.Projection_Helpers_Retained_Only := C.Observes_Retained_Sources_Only;
               C.Projection_Helpers_No_Lifecycle_Inputs :=
                 C.No_Operation_History
                 and then C.No_Target_History
                 and then C.No_Target_Prompt_Ownership
                 and then C.No_Filesystem_Probe
                 and then C.No_Association_Repair
                 and then C.No_Retained_Target_Repair
                 and then C.No_Target_Migration
                 and then C.No_Cross_Surface_Projection_Imports;
               C.No_Render_Lifecycle_State :=
                 C.Render_Side_Effect_Free
                 and then C.Render_Consumes_Snapshots_Only
                 and then C.No_Forbidden_Rendered_Lifecycle_Fields;
               C.No_Audit_Product_Truth_State :=
                 C.Audit_Side_Effect_Free
                 and then C.Audit_Not_Product_Truth;
               C.Behavior_Preserved :=
                 Editor.Navigation_History.Navigation_History_File_Lifecycle_Observation_Frozen (State);
            end;
      end case;

      return C;
   end Contract_For_Surface;

   function Surface_Invariant_Holds
     (Surface : Projection_Surface_Id) return Boolean
   is
      Result : Projection_Surface_Audit_Result;
   begin
      Validate_Surface (Result, Contract_For_Surface (Surface));
      return Failure_Count (Result) = 0;
   end Surface_Invariant_Holds;

   function Open_Buffer_Switcher_Shared_Projection_Invariant return Boolean is
   begin
      return Surface_Invariant_Holds (Open_Buffer_Switcher_Surface);
   end Open_Buffer_Switcher_Shared_Projection_Invariant;

   function Quick_Open_Shared_Projection_Invariant return Boolean is
   begin
      return Surface_Invariant_Holds (Quick_Open_Surface);
   end Quick_Open_Shared_Projection_Invariant;

   function Project_Search_Shared_Projection_Invariant return Boolean is
   begin
      return Surface_Invariant_Holds (Project_Search_Surface);
   end Project_Search_Shared_Projection_Invariant;

   function Bookmarks_Shared_Projection_Invariant return Boolean is
   begin
      return Surface_Invariant_Holds (Bookmarks_Surface);
   end Bookmarks_Shared_Projection_Invariant;

   function Navigation_History_Shared_Projection_Invariant return Boolean is
   begin
      return Surface_Invariant_Holds (Navigation_History_Surface);
   end Navigation_History_Shared_Projection_Invariant;


   function Surface_Observes_Retained_Sources_Only
     (Contract : Projection_Surface_Contract) return Boolean
   is
   begin
      return Contract.Observes_Retained_Sources_Only;
   end Surface_Observes_Retained_Sources_Only;

   function Surface_Does_Not_Own_File_Lifecycle_Routes
     (Contract : Projection_Surface_Contract) return Boolean
   is
   begin
      return Contract.No_File_Lifecycle_Routes;
   end Surface_Does_Not_Own_File_Lifecycle_Routes;

   function Surface_Does_Not_Own_Target_Prompt
     (Contract : Projection_Surface_Contract) return Boolean
   is
   begin
      return Contract.No_Target_Prompt_Ownership
        and then Surface_Source_Target_Prompt_Boundary_Is_Canonical (Contract);
   end Surface_Does_Not_Own_Target_Prompt;

   function Surface_Does_Not_Infer_Source_Or_Target
     (Contract : Projection_Surface_Contract) return Boolean
   is
   begin
      return Contract.No_Source_Or_Target_Inference
        and then Surface_Source_Target_Prompt_Boundary_Is_Canonical (Contract);
   end Surface_Does_Not_Infer_Source_Or_Target;

   function Surface_Does_Not_Repair_Associations
     (Contract : Projection_Surface_Contract) return Boolean
   is
   begin
      return Contract.No_Association_Repair;
   end Surface_Does_Not_Repair_Associations;

   function Surface_Does_Not_Repair_Retained_Targets
     (Contract : Projection_Surface_Contract) return Boolean
   is
   begin
      return Contract.No_Retained_Target_Repair;
   end Surface_Does_Not_Repair_Retained_Targets;

   function Surface_Does_Not_Migrate_Targets
     (Contract : Projection_Surface_Contract) return Boolean
   is
   begin
      return Contract.No_Target_Migration;
   end Surface_Does_Not_Migrate_Targets;

   function Surface_Does_Not_Probe_Filesystem
     (Contract : Projection_Surface_Contract) return Boolean
   is
   begin
      return Contract.No_Filesystem_Probe;
   end Surface_Does_Not_Probe_Filesystem;

   function Surface_Does_Not_Record_Operation_Or_Target_History
     (Contract : Projection_Surface_Contract) return Boolean
   is
   begin
      return Contract.No_Operation_History
        and then Contract.No_Target_History;
   end Surface_Does_Not_Record_Operation_Or_Target_History;

   function Surface_Does_Not_Cache_Path_Or_Dirty_Observation
     (Contract : Projection_Surface_Contract) return Boolean
   is
   begin
      return Contract.No_Stale_Path_Label_Cache
        and then Contract.No_Dirty_Hint_Cache
        and then Contract.No_Duplicate_Lifecycle_State;
   end Surface_Does_Not_Cache_Path_Or_Dirty_Observation;

   function Surface_Row_Identity_Is_Retained
     (Contract : Projection_Surface_Contract) return Boolean
   is
   begin
      return Contract.Row_Identity_Not_Path_Label
        and then Contract.No_Duplicate_Lifecycle_State;
   end Surface_Row_Identity_Is_Retained;

   function Surface_Row_Order_Follows_Retained_Policy
     (Contract : Projection_Surface_Contract) return Boolean
   is
   begin
      return Contract.Row_Order_Retained_Policy
        and then Contract.Observes_Retained_Sources_Only;
   end Surface_Row_Order_Follows_Retained_Policy;

   function Surface_Local_UI_State_Is_Not_Lifecycle_Input
     (Contract : Projection_Surface_Contract) return Boolean
   is
   begin
      return Contract.Selection_Query_Local_Only
        and then Surface_Source_Target_Prompt_Boundary_Is_Canonical (Contract);
   end Surface_Local_UI_State_Is_Not_Lifecycle_Input;

   function Surface_Source_Target_Prompt_Boundary_Is_Canonical
     (Contract : Projection_Surface_Contract) return Boolean
   is
   begin
      if not Contract.Source_Target_Prompt_Boundary then
         return False;
      end if;

      for Rule in 1 .. Expected_Prompt_Boundary_Rule_Count loop
         if not Prompt_Boundary_Rule_Holds (Contract, Rule) then
            return False;
         end if;
      end loop;

      return True;
   end Surface_Source_Target_Prompt_Boundary_Is_Canonical;

   function Surface_Activation_Does_Not_Execute_File_Lifecycle
     (Contract : Projection_Surface_Contract) return Boolean
   is
   begin
      return Contract.Activation_Not_Lifecycle_Command
        and then Contract.No_File_Lifecycle_Routes;
   end Surface_Activation_Does_Not_Execute_File_Lifecycle;

   function Surface_Target_Prompt_Lifecycle_Is_Canonical
     (Contract : Projection_Surface_Contract) return Boolean
   is
   begin
      return Contract.No_Target_Prompt_Ownership
        and then Contract.Surface_Does_Not_Open_Target_Prompt
        and then Contract.Surface_Does_Not_Confirm_Target_Prompt
        and then Contract.Surface_Does_Not_Cancel_Target_Prompt
        and then Contract.Prompt_Confirmation_Executor_Routed
        and then Contract.Prompt_Cancellation_Non_Mutating
        and then Contract.Prompt_Cleanup_Canonical;
   end Surface_Target_Prompt_Lifecycle_Is_Canonical;

   function Surface_Does_Not_Import_Projection_Truth
     (Contract : Projection_Surface_Contract) return Boolean
   is
   begin
      return Contract.No_Cross_Surface_Projection_Imports;
   end Surface_Does_Not_Import_Projection_Truth;

   function Surface_Does_Not_Persist_Lifecycle_State
     (Contract : Projection_Surface_Contract) return Boolean
   is
   begin
      return Contract.No_Lifecycle_Persistence_State;
   end Surface_Does_Not_Persist_Lifecycle_State;

   function Surface_Adapter_Is_Raw_And_Nonrepairing
     (Contract : Projection_Surface_Contract) return Boolean
   is
   begin
      return Contract.Adapter_Raw_Retained_State
        and then Contract.No_Adapter_Lifecycle_Normalization
        and then Contract.No_Association_Repair
        and then Contract.No_Retained_Target_Repair
        and then Contract.No_Target_Migration
        and then Contract.No_Filesystem_Probe
        and then Contract.No_Cross_Surface_Projection_Imports;
   end Surface_Adapter_Is_Raw_And_Nonrepairing;

   function Surface_Projection_Helper_Is_Pure
     (Contract : Projection_Surface_Contract) return Boolean
   is
   begin
      return Contract.Projection_Helpers_Retained_Only
        and then Contract.Projection_Helpers_No_Lifecycle_Inputs
        and then Contract.Observes_Retained_Sources_Only
        and then Contract.No_Operation_History
        and then Contract.No_Target_History
        and then Contract.No_Target_Prompt_Ownership
        and then Contract.No_Filesystem_Probe
        and then Contract.No_Association_Repair
        and then Contract.No_Retained_Target_Repair
        and then Contract.No_Target_Migration
        and then Contract.No_Cross_Surface_Projection_Imports
        and then Contract.No_Lifecycle_Persistence_State;
   end Surface_Projection_Helper_Is_Pure;

   function Surface_Render_Is_Side_Effect_Free
     (Contract : Projection_Surface_Contract) return Boolean
   is
   begin
      return Contract.Render_Side_Effect_Free
        and then Contract.Render_Consumes_Snapshots_Only
        and then Contract.No_Forbidden_Rendered_Lifecycle_Fields
        and then Contract.No_Render_Lifecycle_State;
   end Surface_Render_Is_Side_Effect_Free;

   function Surface_Audit_Is_Side_Effect_Free
     (Contract : Projection_Surface_Contract) return Boolean
   is
   begin
      return Contract.Audit_Side_Effect_Free
        and then Contract.Audit_Not_Product_Truth
        and then Contract.No_Audit_Product_Truth_State;
   end Surface_Audit_Is_Side_Effect_Free;

   function Surface_Command_Routes_Remain_Canonical
     (Contract : Projection_Surface_Contract) return Boolean
   is
   begin
      return Contract.File_Lifecycle_Commands_Executor_Routed
        and then Contract.Command_Invocation_Surface_Canonical
        and then Contract.No_File_Lifecycle_Routes;
   end Surface_Command_Routes_Remain_Canonical;

   function Surface_Persistence_Boundary_Remains_Canonical
     (Contract : Projection_Surface_Contract) return Boolean
   is
   begin
      return Contract.Persistence_Domains_Separated
        and then Contract.Removed_Lifecycle_Fields_Dropped
        and then Contract.No_Lifecycle_Persistence_State;
   end Surface_Persistence_Boundary_Remains_Canonical;

   function Surface_Behavior_Preserved
     (Contract : Projection_Surface_Contract) return Boolean
   is
   begin
      return Contract.Behavior_Preserved;
   end Surface_Behavior_Preserved;

   procedure Assert_Surface_Observes_Retained_Sources_Only
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
   is
   begin
      if not Surface_Observes_Retained_Sources_Only (Contract) then
         Add_Failure (Result, Contract.Surface, "shared assertion failed: retained canonical sources only");
      end if;
   end Assert_Surface_Observes_Retained_Sources_Only;

   procedure Assert_Surface_Does_Not_Own_File_Lifecycle_Routes
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
   is
   begin
      if not Surface_Does_Not_Own_File_Lifecycle_Routes (Contract) then
         Add_Failure (Result, Contract.Surface, "shared assertion failed: no local lifecycle routes");
      end if;
   end Assert_Surface_Does_Not_Own_File_Lifecycle_Routes;

   procedure Assert_Surface_Does_Not_Own_Target_Prompt
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
   is
   begin
      if not Surface_Does_Not_Own_Target_Prompt (Contract) then
         Add_Failure (Result, Contract.Surface, "shared assertion failed: no target prompt ownership");
      end if;
   end Assert_Surface_Does_Not_Own_Target_Prompt;

   procedure Assert_Surface_Does_Not_Infer_Source_Or_Target
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
   is
   begin
      if not Surface_Does_Not_Infer_Source_Or_Target (Contract) then
         Add_Failure (Result, Contract.Surface, "shared assertion failed: no source/target inference");
      end if;
   end Assert_Surface_Does_Not_Infer_Source_Or_Target;

   procedure Assert_Surface_Does_Not_Persist_Lifecycle_State
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
   is
   begin
      if not Surface_Does_Not_Persist_Lifecycle_State (Contract) then
         Add_Failure (Result, Contract.Surface, "shared assertion failed: no lifecycle persistence state");
      end if;
   end Assert_Surface_Does_Not_Persist_Lifecycle_State;

   procedure Assert_Surface_Adapter_Is_Raw_And_NonRepairing
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
   is
   begin
      if not Surface_Adapter_Is_Raw_And_Nonrepairing (Contract) then
         Add_Failure (Result, Contract.Surface, "shared cleanup assertion failed: adapter is not raw/nonrepairing");
      end if;
   end Assert_Surface_Adapter_Is_Raw_And_NonRepairing;

   procedure Assert_Surface_Projection_Helper_Is_Pure
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
   is
   begin
      if not Surface_Projection_Helper_Is_Pure (Contract) then
         Add_Failure
           (Result, Contract.Surface,
            "shared cleanup assertion failed: projection helper is not pure");
      end if;
   end Assert_Surface_Projection_Helper_Is_Pure;

   procedure Assert_Surface_Has_No_Local_Lifecycle_Routes
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
   is
   begin
      Assert_Surface_Does_Not_Own_File_Lifecycle_Routes (Result, Contract);
   end Assert_Surface_Has_No_Local_Lifecycle_Routes;

   procedure Assert_Surface_Has_No_Cross_Surface_Lifecycle_Imports
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
   is
   begin
      if not Surface_Does_Not_Import_Projection_Truth (Contract) then
         Add_Failure
           (Result, Contract.Surface,
            "shared cleanup assertion failed: cross-surface import exists");
      end if;
   end Assert_Surface_Has_No_Cross_Surface_Lifecycle_Imports;

   procedure Assert_Render_Has_No_Projection_Lifecycle_State
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
   is
   begin
      if not Contract.No_Render_Lifecycle_State then
         Add_Failure
           (Result, Contract.Surface,
            "shared cleanup assertion failed: render owns lifecycle state");
      end if;
   end Assert_Render_Has_No_Projection_Lifecycle_State;

   procedure Assert_Audit_Has_No_Product_Truth_State
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
   is
   begin
      if not Contract.No_Audit_Product_Truth_State then
         Add_Failure (Result, Contract.Surface, "shared cleanup assertion failed: audit owns product truth state");
      end if;
   end Assert_Audit_Has_No_Product_Truth_State;

   procedure Assert_Persistence_Has_No_Projection_Lifecycle_State
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
   is
   begin
      Assert_Surface_Does_Not_Persist_Lifecycle_State (Result, Contract);
   end Assert_Persistence_Has_No_Projection_Lifecycle_State;

   procedure Assert_Removed_Projection_Lifecycle_Fields_Dropped
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
   is
   begin
      if not Contract.Removed_Lifecycle_Fields_Dropped then
         Add_Failure
           (Result, Contract.Surface,
            "shared cleanup assertion failed: removed fields survive save/load");
      end if;
   end Assert_Removed_Projection_Lifecycle_Fields_Dropped;

   procedure Assert_Shared_Invariant_Coverage_Not_Reduced
     (Result : in out Projection_Surface_Audit_Result)
   is
   begin
      Validate_All_Covered_Surfaces (Result);
   end Assert_Shared_Invariant_Coverage_Not_Reduced;

   procedure Assert_Surface_Render_Is_Side_Effect_Free
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
   is
   begin
      if not Surface_Render_Is_Side_Effect_Free (Contract) then
         Add_Failure (Result, Contract.Surface, "shared assertion failed: render side-effect freedom");
      end if;
   end Assert_Surface_Render_Is_Side_Effect_Free;

   procedure Assert_Surface_Audit_Is_Side_Effect_Free
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
   is
   begin
      if not Surface_Audit_Is_Side_Effect_Free (Contract) then
         Add_Failure (Result, Contract.Surface, "shared assertion failed: audit side-effect freedom");
      end if;
   end Assert_Surface_Audit_Is_Side_Effect_Free;

   procedure Assert_Surface_Behavior_Preserved
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
   is
   begin
      if not Surface_Behavior_Preserved (Contract) then
         Add_Failure (Result, Contract.Surface, "shared assertion failed: behavior preserved");
      end if;
   end Assert_Surface_Behavior_Preserved;

   procedure Assert_Surface_Lifecycle_Operation_Semantics
     (Result    : in out Projection_Surface_Audit_Result;
      Surface   : Projection_Surface_Id;
      Operation : File_Lifecycle_Operation)
   is
   begin
      Validate_Surface_Operation (Result, Surface, Operation);
   end Assert_Surface_Lifecycle_Operation_Semantics;

   procedure Assert_Surface_Lifecycle_Event_Semantics
     (Result  : in out Projection_Surface_Audit_Result;
      Surface : Projection_Surface_Id;
      Event   : Projection_Surface_Lifecycle_Event)
   is
   begin
      Validate_Surface_Lifecycle_Event (Result, Surface, Event);
   end Assert_Surface_Lifecycle_Event_Semantics;

   procedure Assert_File_Lifecycle_Projection_Surface_Milestone_Coherent
     (Result : in out Projection_Surface_Audit_Result)
   is
   begin
      Validate_All_Covered_Surfaces (Result);
   end Assert_File_Lifecycle_Projection_Surface_Milestone_Coherent;

   procedure Assert_File_Lifecycle_Projection_Surface_Reliability_Coherent
     (Result : in out Projection_Surface_Audit_Result)
   is
   begin
      for Surface in Projection_Surface_Id loop
         for Family in Projection_Surface_Reliability_Family loop
            for Operation in File_Lifecycle_Operation loop
               for Context in Projection_Surface_Workflow_Context loop
                  Validate_Surface_Reliability
                    (Result, Surface, Family, Operation, Context);
               end loop;
            end loop;
         end loop;
      end loop;
   end Assert_File_Lifecycle_Projection_Surface_Reliability_Coherent;

   procedure Assert_File_Lifecycle_Projection_Surface_Cleanup_Coherent
     (Result : in out Projection_Surface_Audit_Result)
   is
   begin
      --  makes the shared harness the cleanup authority.  It runs
      --  the complete milestone/reliability surface matrix, then adds the
      --  cleanup-specific raw-adapter, pure-helper, render/audit/persistence,
      --  local-route, and cross-surface import assertions.
      Validate_All_Covered_Surfaces (Result);
      Assert_File_Lifecycle_Projection_Surface_Reliability_Coherent (Result);

      for Surface in Projection_Surface_Id loop
         declare
            Contract : constant Projection_Surface_Contract :=
              Contract_For_Surface (Surface);
         begin
            Assert_Surface_Adapter_Is_Raw_And_NonRepairing (Result, Contract);
            Assert_Surface_Projection_Helper_Is_Pure (Result, Contract);
            Assert_Surface_Has_No_Local_Lifecycle_Routes (Result, Contract);
            Assert_Surface_Has_No_Cross_Surface_Lifecycle_Imports (Result, Contract);
            Assert_Render_Has_No_Projection_Lifecycle_State (Result, Contract);
            Assert_Audit_Has_No_Product_Truth_State (Result, Contract);
            Assert_Persistence_Has_No_Projection_Lifecycle_State (Result, Contract);
            Assert_Removed_Projection_Lifecycle_Fields_Dropped (Result, Contract);
         end;
      end loop;
   end Assert_File_Lifecycle_Projection_Surface_Cleanup_Coherent;

   procedure Assert_File_Lifecycle_Projection_Surface_Final_Freeze_Coherent
     (Result : in out Projection_Surface_Audit_Result)
   is
   begin
      Assert_File_Lifecycle_Projection_Surface_Cleanup_Coherent (Result);

      for Surface in Projection_Surface_Id loop
         Validate_Surface_Final_Freeze (Result, Surface);
      end loop;
   end Assert_File_Lifecycle_Projection_Surface_Final_Freeze_Coherent;

   procedure Assert_Projection_Surface_Invariant_Adoption_Gate_Coherent
     (Result : in out Projection_Surface_Audit_Result)
   is
      Exempt_None : constant Projection_Surface_Inspection :=
        (Registered                       => False,
         Classification                   => Projection_Surface_None,
         Exposes_Buffer_Identity          => False,
         Exposes_Retained_Target          => False,
         Exposes_Path_File_Label          => False,
         Exposes_Dirty_Hint               => False,
         Exposes_Current_Or_Open_Marker   => False,
         Exposes_Candidate_Result_Target  => False,
         Exposes_Bookmark_Or_History_Target => False,
         Has_Local_Lifecycle_Route        => False,
         Has_Target_Prompt_Ownership      => False,
         Has_Source_Override_Or_Target_Inference => False,
         Has_Repair_Migration_Or_Probe    => False,
         Has_Cross_Surface_Import         => False,
         Has_Retained_Persistence         => False,
         Has_Lifecycle_Persistence_Field  => False,
         Has_Explicit_Audit_Exemption     => True);
   begin
      Assert_File_Lifecycle_Projection_Surface_Final_Freeze_Coherent (Result);

      for Surface in Projection_Surface_Id loop
         Validate_Projection_Surface_Registration
           (Result, Registration_For_Surface (Surface));
      end loop;

      Validate_Projection_Surface_Inspection (Result, Exempt_None);
   end Assert_Projection_Surface_Invariant_Adoption_Gate_Coherent;

   function Projection_Surface_Invariant_Adoption_Gate_Coherent
     return Boolean
   is
      Result : Projection_Surface_Audit_Result;
   begin
      Assert_Projection_Surface_Invariant_Adoption_Gate_Coherent (Result);
      return Result.Count = 0;
   end Projection_Surface_Invariant_Adoption_Gate_Coherent;


   function Failure_Count
     (Result : Projection_Surface_Audit_Result) return Natural
   is
   begin
      return Result.Count;
   end Failure_Count;

   function Failure
     (Result : Projection_Surface_Audit_Result;
      Index  : Positive) return String
   is
   begin
      if Index > Result.Count then
         return "";
      end if;
      return To_String (Result.Failures (Index));
   end Failure;

   function Summary
     (Result : Projection_Surface_Audit_Result) return String
   is
      Text : Unbounded_String;
   begin
      if Result.Count = 0 then
         return "projection surface file lifecycle audit ok";
      end if;

      Text := To_Unbounded_String ("projection surface file lifecycle audit failed:");
      for I in 1 .. Result.Count loop
         Append (Text, ASCII.LF & "  ");
         Append (Text, To_String (Result.Failures (I)));
      end loop;
      return To_String (Text);
   end Summary;

   function File_Lifecycle_Projection_Surface_Milestone_Coherent
     return Boolean
   is
      Result : Projection_Surface_Audit_Result;
   begin
      Validate_All_Covered_Surfaces (Result);
      return Result.Count = 0;
   end File_Lifecycle_Projection_Surface_Milestone_Coherent;

   function File_Lifecycle_Projection_Surface_Reliability_Coherent
     return Boolean
   is
      Result : Projection_Surface_Audit_Result;
   begin
      Assert_File_Lifecycle_Projection_Surface_Reliability_Coherent (Result);
      return Result.Count = 0;
   end File_Lifecycle_Projection_Surface_Reliability_Coherent;

   function File_Lifecycle_Projection_Surface_Cleanup_Coherent
     return Boolean
   is
      Result : Projection_Surface_Audit_Result;
   begin
      Assert_File_Lifecycle_Projection_Surface_Cleanup_Coherent (Result);
      return Result.Count = 0;
   end File_Lifecycle_Projection_Surface_Cleanup_Coherent;

   function File_Lifecycle_Projection_Surface_Final_Freeze_Coherent
     return Boolean
   is
      Result : Projection_Surface_Audit_Result;
   begin
      Assert_File_Lifecycle_Projection_Surface_Final_Freeze_Coherent (Result);
      return Result.Count = 0;
   end File_Lifecycle_Projection_Surface_Final_Freeze_Coherent;

end Editor.Projection_Surface_File_Lifecycle_Audit;
