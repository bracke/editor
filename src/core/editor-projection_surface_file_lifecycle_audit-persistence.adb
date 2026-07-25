with Editor.Projection_Surface_File_Lifecycle_Audit.Adapters; use Editor.Projection_Surface_File_Lifecycle_Audit.Adapters;
with Editor.Projection_Surface_File_Lifecycle_Audit.Registry; use Editor.Projection_Surface_File_Lifecycle_Audit.Registry;
with Editor.Projection_Surface_File_Lifecycle_Audit.Surface_Checks; use Editor.Projection_Surface_File_Lifecycle_Audit.Surface_Checks;

package body Editor.Projection_Surface_File_Lifecycle_Audit.Persistence is

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


   procedure Assert_Shared_Invariant_Coverage_Not_Reduced
     (Result : in out Projection_Surface_Audit_Result)
   is
   begin
      Validate_All_Covered_Surfaces (Result);
   end Assert_Shared_Invariant_Coverage_Not_Reduced;

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

end Editor.Projection_Surface_File_Lifecycle_Audit.Persistence;
