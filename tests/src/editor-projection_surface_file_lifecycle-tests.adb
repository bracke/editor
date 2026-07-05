with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Bookmarks;
with Editor.Buffer_Switcher;
with Editor.Navigation_History;
with Editor.Project_Search;
with Editor.Projection_Surface_File_Lifecycle_Audit;
with Editor.Quick_Open;

package body Editor.Projection_Surface_File_Lifecycle.Tests is

   package Audit renames Editor.Projection_Surface_File_Lifecycle_Audit;

   use type Audit.Projection_Surface_Id;
   use type Audit.File_Lifecycle_Operation;
   use type Audit.Projection_Surface_Lifecycle_Event;
   use type Audit.Projection_Surface_Reliability_Family;
   use type Audit.Projection_Surface_Workflow_Context;
   use type Audit.Projection_Surface_Classification;

   overriding function Name
     (T : Projection_Surface_File_Lifecycle_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Projection_Surface_File_Lifecycle.Tests");
   end Name;

   function Open_Buffer_Switcher_Contract
     return Audit.Projection_Surface_Contract
   is
      State : Editor.Buffer_Switcher.Buffer_Switcher_State;
      C     : Audit.Projection_Surface_Contract :=
        Audit.Default_Contract (Audit.Open_Buffer_Switcher_Surface);
   begin
      C.No_Duplicate_Lifecycle_State :=
        Editor.Buffer_Switcher.Open_Buffer_Switcher_No_Duplicate_Lifecycle_State (State);
      C.No_Target_Prompt_Ownership :=
        Editor.Buffer_Switcher.Open_Buffer_Switcher_No_Prompt_State (State);
      C.No_Source_Or_Target_Inference :=
        Editor.Buffer_Switcher.Open_Buffer_Switcher_No_File_Lifecycle_Source_Override (State);
      C.Source_Target_Prompt_Boundary := C.No_Source_Or_Target_Inference;
      C.Behavior_Preserved :=
        Editor.Buffer_Switcher.Open_Buffer_Switcher_File_Lifecycle_Observation_Frozen (State);
      return C;
   end Open_Buffer_Switcher_Contract;

   function Quick_Open_Contract
     return Audit.Projection_Surface_Contract
   is
      State : Editor.Quick_Open.Quick_Open_State;
      C     : Audit.Projection_Surface_Contract :=
        Audit.Default_Contract (Audit.Quick_Open_Surface);
   begin
      C.No_Duplicate_Lifecycle_State :=
        Editor.Quick_Open.Quick_Open_No_Duplicate_Lifecycle_State (State);
      C.No_Target_Prompt_Ownership :=
        Editor.Quick_Open.Quick_Open_No_Prompt_State (State);
      C.No_Source_Or_Target_Inference :=
        Editor.Quick_Open.Quick_Open_Query_Selection_Source_Target_Boundary (State);
      C.Source_Target_Prompt_Boundary := C.No_Source_Or_Target_Inference;
      C.Behavior_Preserved :=
        Editor.Quick_Open.Quick_Open_File_Lifecycle_Observation_Frozen (State);
      return C;
   end Quick_Open_Contract;

   function Project_Search_Contract
     return Audit.Projection_Surface_Contract
   is
      State : Editor.Project_Search.Project_Search_State;
      C     : Audit.Projection_Surface_Contract :=
        Audit.Default_Contract (Audit.Project_Search_Surface);
   begin
      C.No_Duplicate_Lifecycle_State :=
        Editor.Project_Search.Project_Search_No_Duplicate_Lifecycle_State (State);
      C.No_Target_Prompt_Ownership :=
        Editor.Project_Search.Project_Search_No_Prompt_State (State);
      C.No_Source_Or_Target_Inference :=
        Editor.Project_Search.Project_Search_Query_Selection_Source_Target_Boundary (State);
      C.Source_Target_Prompt_Boundary := C.No_Source_Or_Target_Inference;
      C.Observes_Retained_Sources_Only :=
        Editor.Project_Search.Project_Search_Project_Source_Boundary_Canonical (State);
      C.Behavior_Preserved :=
        Editor.Project_Search.Project_Search_File_Lifecycle_Observation_Frozen (State);
      return C;
   end Project_Search_Contract;

   function Bookmarks_Contract
     return Audit.Projection_Surface_Contract
   is
      State : Editor.Bookmarks.Bookmark_State;
      C     : Audit.Projection_Surface_Contract :=
        Audit.Default_Contract (Audit.Bookmarks_Surface);
   begin
      C.No_Duplicate_Lifecycle_State :=
        Editor.Bookmarks.Bookmarks_No_Duplicate_Lifecycle_State (State);
      C.No_Target_Prompt_Ownership :=
        Editor.Bookmarks.Bookmarks_No_Prompt_State (State);
      C.No_Source_Or_Target_Inference :=
        Editor.Bookmarks.Bookmark_Selection_Source_Target_Boundary (State);
      C.Source_Target_Prompt_Boundary := C.No_Source_Or_Target_Inference;
      C.Observes_Retained_Sources_Only :=
        Editor.Bookmarks.Bookmark_Row_Projection_Canonical (State);
      C.Behavior_Preserved :=
        Editor.Bookmarks.Bookmarks_File_Lifecycle_Observation_Final_Frozen (State);
      return C;
   end Bookmarks_Contract;

   function Navigation_History_Contract
     return Audit.Projection_Surface_Contract
   is
      State : Editor.Navigation_History.Navigation_History_State;
      C     : Audit.Projection_Surface_Contract :=
        Audit.Default_Contract (Audit.Navigation_History_Surface);
   begin
      C.No_Duplicate_Lifecycle_State :=
        Editor.Navigation_History.Navigation_History_No_Duplicate_Lifecycle_State (State);
      C.No_Target_Prompt_Ownership :=
        Editor.Navigation_History.Navigation_History_No_Prompt_State (State);
      C.No_Source_Or_Target_Inference :=
        Editor.Navigation_History.Navigation_History_Source_Target_Boundary (State);
      C.Source_Target_Prompt_Boundary := C.No_Source_Or_Target_Inference;
      C.Behavior_Preserved :=
        Editor.Navigation_History.Navigation_History_File_Lifecycle_Observation_Frozen (State);
      return C;
   end Navigation_History_Contract;

   procedure Assert_Surface_Contract
     (Contract : Audit.Projection_Surface_Contract;
      Message  : String)
   is
      Result : Audit.Projection_Surface_Audit_Result;
   begin
      Audit.Validate_Surface (Result, Contract);
      Assert (Audit.Failure_Count (Result) = 0,
              Message & ": " & Audit.Summary (Result));
   end Assert_Surface_Contract;

   procedure Test_Audit_Result_Collects_Forbidden_Ownership
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result   : Audit.Projection_Surface_Audit_Result;
      Contract : Audit.Projection_Surface_Contract :=
        Audit.Default_Contract (Audit.Quick_Open_Surface);
   begin
      Contract.No_File_Lifecycle_Routes := False;
      Contract.No_Target_Prompt_Ownership := False;
      Contract.No_Cross_Surface_Projection_Imports := False;
      Contract.No_Operation_History := False;
      Contract.No_Target_History := False;
      Contract.No_Stale_Path_Label_Cache := False;
      Contract.No_Dirty_Hint_Cache := False;
      Contract.Source_Target_Prompt_Boundary := False;
      Contract.Render_Consumes_Snapshots_Only := False;
      Contract.Audit_Not_Product_Truth := False;

      Audit.Validate_Surface (Result, Contract);

      Assert (Audit.Failure_Count (Result) >= 11,
              "audit must report every violated shared projection rule, "
              & "including prompt ownership and cleanup hazards");
      Assert (Audit.Failure (Result, 1) /= "",
              "audit failures must be readable by one-based index");
      Assert (Audit.Summary (Result) /= "projection surface file lifecycle audit ok",
              "failed audit summary must not report success");
   end Test_Audit_Result_Collects_Forbidden_Ownership;

   procedure Test_All_Covered_Surface_Defaults_Are_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : Audit.Projection_Surface_Audit_Result;
   begin
      Audit.Validate_All_Covered_Surfaces (Result);
      Assert (Audit.Failure_Count (Result) = 0,
              "default shared projection-surface contract must cover all surfaces: "
              & Audit.Summary (Result));
      Assert (Audit.File_Lifecycle_Projection_Surface_Milestone_Coherent,
              "milestone helper must validate the shared contract for all covered surfaces");
   end Test_All_Covered_Surface_Defaults_Are_Coherent;

   procedure Test_Surface_Wrappers_Preserve_Per_Surface_Freezes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert_Surface_Contract
        (Open_Buffer_Switcher_Contract,
         "Open Buffer Switcher must satisfy the shared projection contract");
      Assert_Surface_Contract
        (Quick_Open_Contract,
         "Quick Open must satisfy the shared projection contract");
      Assert_Surface_Contract
        (Project_Search_Contract,
         "Project Search must satisfy the shared projection contract");
      Assert_Surface_Contract
        (Bookmarks_Contract,
         "Bookmarks must satisfy the shared projection contract");
      Assert_Surface_Contract
        (Navigation_History_Contract,
         "Navigation History must satisfy the shared projection contract");
   end Test_Surface_Wrappers_Preserve_Per_Surface_Freezes;

   procedure Test_Cross_Surface_Imports_Are_Not_Product_Truth
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      for Surface in Audit.Projection_Surface_Id loop
         declare
            Contract : constant Audit.Projection_Surface_Contract :=
              Audit.Default_Contract (Surface);
         begin
            Assert (Contract.No_Cross_Surface_Projection_Imports,
                    Audit.Surface_Name (Surface)
                    & " must not import adjacent projection rows as lifecycle truth");
            Assert (Contract.No_Filesystem_Probe,
                    Audit.Surface_Name (Surface)
                    & " must not probe the filesystem for lifecycle observation");
            Assert (Contract.No_Lifecycle_Persistence_State,
                    Audit.Surface_Name (Surface)
                    & " must not persist lifecycle observation state");
         end;
      end loop;
   end Test_Cross_Surface_Imports_Are_Not_Product_Truth;

   procedure Test_Render_And_Audit_Boundaries_Are_Shared
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      for Surface in Audit.Projection_Surface_Id loop
         declare
            Contract : constant Audit.Projection_Surface_Contract :=
              Audit.Default_Contract (Surface);
         begin
            Assert (Contract.Render_Side_Effect_Free,
                    Audit.Surface_Name (Surface)
                    & " render must consume snapshots only");
            Assert (Contract.Audit_Side_Effect_Free,
                    Audit.Surface_Name (Surface)
                    & " audit helpers must inspect without becoming product truth");
            Assert (Contract.No_Target_Migration,
                    Audit.Surface_Name (Surface)
                    & " must not migrate retained targets");
         end;
      end loop;
   end Test_Render_And_Audit_Boundaries_Are_Shared;

   procedure Test_Shared_Named_Predicates_Map_To_Contract
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      for Surface in Audit.Projection_Surface_Id loop
         declare
            Contract : constant Audit.Projection_Surface_Contract :=
              Audit.Default_Contract (Surface);
         begin
            Assert (Audit.Surface_Observes_Retained_Sources_Only (Contract),
                    Audit.Surface_Name (Surface) & " must read retained sources only");
            Assert (Audit.Surface_Does_Not_Own_File_Lifecycle_Routes (Contract),
                    Audit.Surface_Name (Surface) & " must not own lifecycle routes");
            Assert (Audit.Surface_Does_Not_Own_Target_Prompt (Contract),
                    Audit.Surface_Name (Surface) & " must not own target prompts");
            Assert (Audit.Surface_Does_Not_Infer_Source_Or_Target (Contract),
                    Audit.Surface_Name (Surface) & " must not infer source or target");
            Assert (Audit.Surface_Does_Not_Repair_Associations (Contract),
                    Audit.Surface_Name (Surface) & " must not repair associations");
            Assert (Audit.Surface_Does_Not_Repair_Retained_Targets (Contract),
                    Audit.Surface_Name (Surface) & " must not repair retained targets");
            Assert (Audit.Surface_Does_Not_Migrate_Targets (Contract),
                    Audit.Surface_Name (Surface) & " must not migrate targets");
            Assert (Audit.Surface_Does_Not_Probe_Filesystem (Contract),
                    Audit.Surface_Name (Surface) & " must not probe filesystem");
            Assert (Audit.Surface_Does_Not_Record_Operation_Or_Target_History (Contract),
                    Audit.Surface_Name (Surface) & " must not record lifecycle histories");
            Assert (Audit.Surface_Does_Not_Cache_Path_Or_Dirty_Observation (Contract),
                    Audit.Surface_Name (Surface) & " must not cache labels or dirty hints");
            Assert (Audit.Surface_Row_Identity_Is_Retained (Contract),
                    Audit.Surface_Name (Surface) & " row identity must be retained and not path-label-derived");
            Assert (Audit.Surface_Row_Order_Follows_Retained_Policy (Contract),
                    Audit.Surface_Name (Surface) & " row order must follow retained surface policy");
            Assert (Audit.Surface_Local_UI_State_Is_Not_Lifecycle_Input (Contract),
                    Audit.Surface_Name (Surface) & " local query/selection state must not become lifecycle input");
            Assert (Audit.Surface_Source_Target_Prompt_Boundary_Is_Canonical (Contract),
                    Audit.Surface_Name (Surface) & " source/target/prompt boundary must satisfy all shared subrules");
            Assert (Audit.Surface_Target_Prompt_Lifecycle_Is_Canonical (Contract),
                    Audit.Surface_Name (Surface) & " target prompt lifecycle must remain canonical and Executor-owned");
            Assert (Audit.Surface_Activation_Does_Not_Execute_File_Lifecycle (Contract),
                    Audit.Surface_Name (Surface) & " activation must not execute lifecycle commands");
            Assert (Audit.Surface_Does_Not_Import_Projection_Truth (Contract),
                    Audit.Surface_Name (Surface) & " must not import projection truth");
            Assert (Audit.Surface_Does_Not_Persist_Lifecycle_State (Contract),
                    Audit.Surface_Name (Surface) & " must not persist lifecycle state");
            Assert (Audit.Surface_Render_Is_Side_Effect_Free (Contract),
                    Audit.Surface_Name (Surface) & " render must be snapshot-only and pure");
            Assert (Audit.Surface_Audit_Is_Side_Effect_Free (Contract),
                    Audit.Surface_Name (Surface) & " audit must be pure and non-product truth");
            Assert (Audit.Surface_Command_Routes_Remain_Canonical (Contract),
                    Audit.Surface_Name (Surface) & " lifecycle command routes must remain canonical");
            Assert (Audit.Surface_Persistence_Boundary_Remains_Canonical (Contract),
                    Audit.Surface_Name (Surface) & " persistence boundaries must remain canonical");
            Assert (Audit.Surface_Behavior_Preserved (Contract),
                    Audit.Surface_Name (Surface) & " previous behavior must be preserved");
         end;
      end loop;
   end Test_Shared_Named_Predicates_Map_To_Contract;



   procedure Test_Shared_Audit_Adapters_Read_Surface_Predicates
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      for Surface in Audit.Projection_Surface_Id loop
         declare
            Contract : constant Audit.Projection_Surface_Contract :=
              Audit.Contract_For_Surface (Surface);
         begin
            Assert_Surface_Contract
              (Contract,
               Audit.Surface_Name (Surface)
               & " shared adapter must fold the surface's exported predicates");
            Assert (Contract.Surface = Surface,
                    "shared adapter must preserve the audited surface identity");
         end;
      end loop;

      Assert (Audit.Open_Buffer_Switcher_Shared_Projection_Invariant,
              "Open Buffer Switcher shared wrapper must pass");
      Assert (Audit.Quick_Open_Shared_Projection_Invariant,
              "Quick Open shared wrapper must pass");
      Assert (Audit.Project_Search_Shared_Projection_Invariant,
              "Project Search shared wrapper must pass");
      Assert (Audit.Bookmarks_Shared_Projection_Invariant,
              "Bookmarks shared wrapper must pass");
      Assert (Audit.Navigation_History_Shared_Projection_Invariant,
              "Navigation History shared wrapper must pass");
   end Test_Shared_Audit_Adapters_Read_Surface_Predicates;

   procedure Test_Named_Predicates_Reject_Broken_Contract
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contract : Audit.Projection_Surface_Contract :=
        Audit.Default_Contract (Audit.Project_Search_Surface);
   begin
      Contract.Observes_Retained_Sources_Only := False;
      Assert (not Audit.Surface_Observes_Retained_Sources_Only (Contract),
              "retained-source predicate must reject noncanonical sources");
      Contract.Observes_Retained_Sources_Only := True;

      Contract.No_Source_Or_Target_Inference := False;
      Assert (not Audit.Surface_Does_Not_Infer_Source_Or_Target (Contract),
              "source/target predicate must reject inference");
      Contract.No_Source_Or_Target_Inference := True;

      Contract.Source_Target_Prompt_Boundary := False;
      Assert (not Audit.Surface_Does_Not_Own_Target_Prompt (Contract),
              "prompt predicate must reject broken prompt boundary");
      Assert (not Audit.Surface_Does_Not_Infer_Source_Or_Target (Contract),
              "source/target predicate must reject broken boundary even without direct inference");
      Contract.Source_Target_Prompt_Boundary := True;

      Contract.No_Operation_History := False;
      Assert (not Audit.Surface_Does_Not_Record_Operation_Or_Target_History (Contract),
              "history predicate must reject operation history");
      Contract.No_Operation_History := True;

      Contract.No_Stale_Path_Label_Cache := False;
      Assert (not Audit.Surface_Does_Not_Cache_Path_Or_Dirty_Observation (Contract),
              "cache predicate must reject stale path-label cache");
      Contract.No_Stale_Path_Label_Cache := True;

      Contract.Render_Consumes_Snapshots_Only := False;
      Assert (not Audit.Surface_Render_Is_Side_Effect_Free (Contract),
              "render predicate must reject non-snapshot lifecycle truth");
      Contract.Render_Consumes_Snapshots_Only := True;

      Contract.No_Forbidden_Rendered_Lifecycle_Fields := False;
      Assert (not Audit.Surface_Render_Is_Side_Effect_Free (Contract),
              "render predicate must reject forbidden rendered lifecycle-local fields");
      Contract.No_Forbidden_Rendered_Lifecycle_Fields := True;

      Contract.Row_Identity_Not_Path_Label := False;
      Assert (not Audit.Surface_Row_Identity_Is_Retained (Contract),
              "row identity predicate must reject path-label-derived identity");
      Contract.Row_Identity_Not_Path_Label := True;

      Contract.Row_Order_Retained_Policy := False;
      Assert (not Audit.Surface_Row_Order_Follows_Retained_Policy (Contract),
              "row-order predicate must reject lifecycle-derived ordering");
      Contract.Row_Order_Retained_Policy := True;

      Contract.Selection_Query_Local_Only := False;
      Assert (not Audit.Surface_Local_UI_State_Is_Not_Lifecycle_Input (Contract),
              "local UI predicate must reject query/selection lifecycle input");
      Contract.Selection_Query_Local_Only := True;

      Contract.Surface_Row_Label_Not_Target := False;
      Assert (not Audit.Surface_Source_Target_Prompt_Boundary_Is_Canonical (Contract),
              "expanded prompt boundary predicate must reject row-label-as-target input");
      Assert (not Audit.Surface_Local_UI_State_Is_Not_Lifecycle_Input (Contract),
              "local UI predicate must reject broken detailed source/target boundary");
      Contract.Surface_Row_Label_Not_Target := True;

      Contract.Activation_Not_Lifecycle_Command := False;
      Assert (not Audit.Surface_Activation_Does_Not_Execute_File_Lifecycle (Contract),
              "activation predicate must reject lifecycle command execution");
      Contract.Activation_Not_Lifecycle_Command := True;

      Contract.Surface_Does_Not_Confirm_Target_Prompt := False;
      Assert (not Audit.Surface_Target_Prompt_Lifecycle_Is_Canonical (Contract),
              "prompt lifecycle predicate must reject surface-owned prompt confirmation");
      Contract.Surface_Does_Not_Confirm_Target_Prompt := True;

      Contract.Audit_Not_Product_Truth := False;
      Assert (not Audit.Surface_Audit_Is_Side_Effect_Free (Contract),
              "audit predicate must reject audit-local product truth");
      Contract.Audit_Not_Product_Truth := True;

      Contract.File_Lifecycle_Commands_Executor_Routed := False;
      Assert (not Audit.Surface_Command_Routes_Remain_Canonical (Contract),
              "route predicate must reject non-Executor lifecycle command routing");
      Contract.File_Lifecycle_Commands_Executor_Routed := True;

      Contract.Persistence_Domains_Separated := False;
      Assert (not Audit.Surface_Persistence_Boundary_Remains_Canonical (Contract),
              "persistence predicate must reject merged persistence domains");
      Contract.Persistence_Domains_Separated := True;

      Contract.Removed_Lifecycle_Fields_Dropped := False;
      Assert (not Audit.Surface_Persistence_Boundary_Remains_Canonical (Contract),
              "persistence predicate must reject removed lifecycle-field survival");
   end Test_Named_Predicates_Reject_Broken_Contract;


   procedure Test_Surface_Adapters_Expose_Shared_Harness_Shape
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      for Surface in Audit.Projection_Surface_Id loop
         declare
            Adapter : constant Audit.Projection_Surface_Adapter :=
              Audit.Adapter_For_Surface (Surface);
         begin
            Assert (Adapter.Surface = Surface,
                    "adapter must preserve covered surface identity");
            Assert (Adapter.Canonical_Source_Count = Audit.Expected_Canonical_Source_Count (Surface),
                    Audit.Surface_Name (Surface) & " adapter must declare the covered canonical source count");
            Assert (Adapter.Forbidden_Field_Count = Audit.Expected_Forbidden_Field_Count (Surface),
                    Audit.Surface_Name (Surface) & " adapter must declare forbidden lifecycle fields");
            Assert (Adapter.Forbidden_Route_Count = Audit.Expected_Forbidden_Route_Count (Surface),
                    Audit.Surface_Name (Surface) & " adapter must declare forbidden lifecycle routes");
            Assert (Adapter.Forbidden_Render_Field_Count = Audit.Expected_Forbidden_Render_Field_Count (Surface),
                    Audit.Surface_Name (Surface) & " adapter must declare forbidden rendered lifecycle fields");
            Assert (Adapter.Exposes_Raw_Retained_State,
                    Audit.Surface_Name (Surface) & " adapter must expose raw retained state");
            Assert (Adapter.No_Path_Label_Normalization,
                    Audit.Surface_Name (Surface) & " adapter must not normalize path labels");
            Assert (Adapter.No_Dirty_Hint_Normalization,
                    Audit.Surface_Name (Surface) & " adapter must not normalize dirty hints");
            Assert (Adapter.No_Inferred_Target_Reconstruction,
                    Audit.Surface_Name (Surface) & " adapter must not reconstruct inferred targets");
            Assert (Adapter.No_Command_Execution,
                    Audit.Surface_Name (Surface) & " adapter must not execute lifecycle commands");
            Assert (Adapter.No_Prompt_Control,
                    Audit.Surface_Name (Surface) & " adapter must not control target prompts");
            Assert (Adapter.No_Filesystem_Probe,
                    Audit.Surface_Name (Surface) & " adapter must not probe the filesystem");
            Assert (Adapter.No_Row_Repair,
                    Audit.Surface_Name (Surface) & " adapter must not repair stale rows");
            Assert (Adapter.No_Cross_Surface_Row_Lookup,
                    Audit.Surface_Name (Surface) & " adapter must not import adjacent surface rows");
            Assert (Adapter.No_Persistence_Field_Filtering,
                    Audit.Surface_Name (Surface) & " adapter must expose persistence output without masking leaks");
            Assert (Adapter.Has_Projection_Helper_Metadata,
                    Audit.Surface_Name (Surface) & " adapter must expose projection helper purity metadata");
            Assert (Adapter.Projection_Helpers_Pure,
                    Audit.Surface_Name (Surface) & " projection helpers must be pure retained-source composition");
            Assert (Audit.Adapter_Supports_Shared_Harness (Adapter),
                    Audit.Surface_Name (Surface)
                    & " adapter must expose rows, sources, forbidden "
                    & "fields/routes, persistence output, and cleanup metadata");
         end;
      end loop;
   end Test_Surface_Adapters_Expose_Shared_Harness_Shape;


   procedure Test_Command_And_Persistence_Boundaries_Are_Shared
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result   : Audit.Projection_Surface_Audit_Result;
      Contract : Audit.Projection_Surface_Contract :=
        Audit.Default_Contract (Audit.Bookmarks_Surface);
   begin
      Contract.File_Lifecycle_Commands_Executor_Routed := False;
      Contract.Command_Invocation_Surface_Canonical := False;
      Contract.Persistence_Domains_Separated := False;
      Contract.Removed_Lifecycle_Fields_Dropped := False;

      Audit.Validate_Surface (Result, Contract);

      Assert (Audit.Failure_Count (Result) = 4,
              "shared audit must report command-routing and persistence-boundary regressions");
      Assert (Audit.Failure (Result, 1) /= "",
              "command/persistence boundary failures must be inspectable");
   end Test_Command_And_Persistence_Boundaries_Are_Shared;

   procedure Test_Adapters_Expose_Named_Source_Field_And_Route_Catalogs
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      for Surface in Audit.Projection_Surface_Id loop
         for Index in 1 .. Audit.Expected_Canonical_Source_Count (Surface) loop
            Assert (Audit.Canonical_Source_Name (Surface, Index) /= "",
                    Audit.Surface_Name (Surface)
                    & " canonical source catalog must name every retained source");
         end loop;
         Assert
           (Audit.Canonical_Source_Name
              (Surface, Audit.Expected_Canonical_Source_Count (Surface) + 1) = "",
            Audit.Surface_Name (Surface)
            & " canonical source catalog must reject out-of-range entries");
      end loop;

      for Index in 1 .. Audit.Expected_Forbidden_Field_Count (Audit.Bookmarks_Surface) loop
         Assert (Audit.Forbidden_Lifecycle_Field_Name (Index) /= "",
                 "forbidden lifecycle field catalog must name every excluded field");
      end loop;
      Assert
        (Audit.Forbidden_Lifecycle_Field_Name
           (Audit.Expected_Forbidden_Field_Count (Audit.Bookmarks_Surface) + 1) = "",
         "forbidden lifecycle field catalog must reject out-of-range entries");

      for Index in 1 .. Audit.Expected_Forbidden_Route_Count (Audit.Bookmarks_Surface) loop
         Assert (Audit.Forbidden_Lifecycle_Route_Name (Index) /= "",
                 "forbidden lifecycle route catalog must name every excluded route");
      end loop;
      Assert
        (Audit.Forbidden_Lifecycle_Route_Name
           (Audit.Expected_Forbidden_Route_Count (Audit.Bookmarks_Surface) + 1) = "",
         "forbidden lifecycle route catalog must reject out-of-range entries");

      for Index in 1 .. Audit.Expected_Forbidden_Render_Field_Count (Audit.Bookmarks_Surface) loop
         Assert (Audit.Forbidden_Rendered_Field_Name (Index) /= "",
                 "forbidden rendered field catalog must name every excluded render-local lifecycle field");
      end loop;
      Assert
        (Audit.Forbidden_Rendered_Field_Name
           (Audit.Expected_Forbidden_Render_Field_Count (Audit.Bookmarks_Surface) + 1) = "",
         "forbidden rendered field catalog must reject out-of-range entries");
      Assert (Audit.Forbidden_Rendered_Field_Name (13) = "rendered cross-surface projection import marker",
              "forbidden rendered field catalog must explicitly exclude cross-surface import markers");
      Assert (Audit.Forbidden_Lifecycle_Field_Name (19) = "prompt ownership state",
              "forbidden lifecycle field catalog must explicitly exclude prompt ownership persistence");
      Assert (Audit.Forbidden_Lifecycle_Field_Name (20) = "local file route state",
              "forbidden lifecycle field catalog must explicitly exclude local lifecycle route persistence");
   end Test_Adapters_Expose_Named_Source_Field_And_Route_Catalogs;

   procedure Test_Catalogs_Are_Deterministic_And_Nonduplicated
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      for Surface in Audit.Projection_Surface_Id loop
         for Left in 1 .. Audit.Expected_Canonical_Source_Count (Surface) loop
            for Right in Left + 1 .. Audit.Expected_Canonical_Source_Count (Surface) loop
               Assert
                 (Audit.Canonical_Source_Name (Surface, Left)
                  /= Audit.Canonical_Source_Name (Surface, Right),
                  Audit.Surface_Name (Surface)
                  & " canonical source catalog must not contain duplicate names");
            end loop;
         end loop;
      end loop;

      for Left in 1 .. Audit.Expected_Forbidden_Field_Count (Audit.Bookmarks_Surface) loop
         for Right in Left + 1 .. Audit.Expected_Forbidden_Field_Count (Audit.Bookmarks_Surface) loop
            Assert
              (Audit.Forbidden_Lifecycle_Field_Name (Left)
               /= Audit.Forbidden_Lifecycle_Field_Name (Right),
               "forbidden lifecycle field catalog must not contain duplicate names");
         end loop;
      end loop;

      for Left in 1 .. Audit.Expected_Forbidden_Route_Count (Audit.Bookmarks_Surface) loop
         for Right in Left + 1 .. Audit.Expected_Forbidden_Route_Count (Audit.Bookmarks_Surface) loop
            Assert
              (Audit.Forbidden_Lifecycle_Route_Name (Left)
               /= Audit.Forbidden_Lifecycle_Route_Name (Right),
               "forbidden lifecycle route catalog must not contain duplicate names");
         end loop;
      end loop;

      for Left in 1 .. Audit.Expected_Forbidden_Render_Field_Count (Audit.Bookmarks_Surface) loop
         for Right in Left + 1 .. Audit.Expected_Forbidden_Render_Field_Count (Audit.Bookmarks_Surface) loop
            Assert
              (Audit.Forbidden_Rendered_Field_Name (Left)
               /= Audit.Forbidden_Rendered_Field_Name (Right),
               "forbidden rendered field catalog must not contain duplicate names");
         end loop;
      end loop;
   end Test_Catalogs_Are_Deterministic_And_Nonduplicated;

   procedure Test_Shared_Assertion_Helpers_Add_Failures
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result   : Audit.Projection_Surface_Audit_Result;
      Contract : Audit.Projection_Surface_Contract :=
        Audit.Default_Contract (Audit.Navigation_History_Surface);
   begin
      Contract.Observes_Retained_Sources_Only := False;
      Contract.No_File_Lifecycle_Routes := False;
      Contract.No_Target_Prompt_Ownership := False;
      Contract.No_Source_Or_Target_Inference := False;
      Contract.No_Lifecycle_Persistence_State := False;
      Contract.Render_Side_Effect_Free := False;
      Contract.Audit_Side_Effect_Free := False;
      Contract.Behavior_Preserved := False;

      Audit.Assert_Surface_Observes_Retained_Sources_Only (Result, Contract);
      Audit.Assert_Surface_Does_Not_Own_File_Lifecycle_Routes (Result, Contract);
      Audit.Assert_Surface_Does_Not_Own_Target_Prompt (Result, Contract);
      Audit.Assert_Surface_Does_Not_Infer_Source_Or_Target (Result, Contract);
      Audit.Assert_Surface_Does_Not_Persist_Lifecycle_State (Result, Contract);
      Audit.Assert_Surface_Render_Is_Side_Effect_Free (Result, Contract);
      Audit.Assert_Surface_Audit_Is_Side_Effect_Free (Result, Contract);
      Audit.Assert_Surface_Behavior_Preserved (Result, Contract);

      Assert (Audit.Failure_Count (Result) = 8,
              "shared assertion helpers must append deterministic failures");
   end Test_Shared_Assertion_Helpers_Add_Failures;

   procedure Test_Milestone_Assertion_Helper_Runs_All_Surface_Adapters
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : Audit.Projection_Surface_Audit_Result;
   begin
      Audit.Assert_File_Lifecycle_Projection_Surface_Milestone_Coherent (Result);
      Assert (Audit.Failure_Count (Result) = 0,
              "milestone assertion helper must run all covered surface adapters: "
              & Audit.Summary (Result));
   end Test_Milestone_Assertion_Helper_Runs_All_Surface_Adapters;


   procedure Test_Lifecycle_Operation_Expectation_Matrix_Covers_All_Commands
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      for Operation in Audit.File_Lifecycle_Operation loop
         declare
            Expectation : constant Audit.Projection_Surface_Observation_Expectation :=
              Audit.Observation_Expectation (Operation);
         begin
            Assert (Expectation.Operation = Operation,
                    "operation expectation must preserve command identity");
            Assert (Audit.Operation_Name (Operation) /= "",
                    "operation matrix must name every lifecycle command");
            Assert (Audit.Observation_Expectation_Coherent (Expectation),
                    Audit.Operation_Name (Operation)
                    & " expectation must preserve no-history/no-cache/no-repair semantics");
            Assert (Expectation.Projection_Unchanged_On_Failure,
                    Audit.Operation_Name (Operation)
                    & " failed/blocked operation must leave projection observation unchanged");
            Assert (Expectation.No_New_Target_Row_From_Operation,
                    Audit.Operation_Name (Operation)
                    & " must not create projection rows from lifecycle target paths");
            Assert (Expectation.No_Delete_Recovery_Row,
                    Audit.Operation_Name (Operation)
                    & " must not create delete recovery rows");
            Assert (Expectation.No_Reopen_Candidate_Ownership,
                    Audit.Operation_Name (Operation)
                    & " must not create or consume projection-owned reopen candidates");

            for Surface in Audit.Projection_Surface_Id loop
               Assert (Audit.Surface_Operation_Observation_Coherent (Surface, Operation),
                       Audit.Surface_Name (Surface) & " must satisfy "
                       & Audit.Operation_Name (Operation)
                       & " shared observation semantics");
            end loop;
         end;
      end loop;
   end Test_Lifecycle_Operation_Expectation_Matrix_Covers_All_Commands;

   procedure Test_Adapter_Validation_Rejects_Incomplete_Adapters
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result  : Audit.Projection_Surface_Audit_Result;
      Adapter : Audit.Projection_Surface_Adapter :=
        Audit.Adapter_For_Surface (Audit.Quick_Open_Surface);
   begin
      Adapter.Has_Row_Identity := False;
      Adapter.Has_Retained_Source_Snapshot := False;
      Adapter.Canonical_Source_Count := Adapter.Canonical_Source_Count - 1;
      Adapter.Forbidden_Field_Count := Adapter.Forbidden_Field_Count - 1;
      Adapter.Forbidden_Route_Count := Adapter.Forbidden_Route_Count - 1;
      Adapter.Forbidden_Render_Field_Count := Adapter.Forbidden_Render_Field_Count - 1;

      Audit.Validate_Adapter (Result, Adapter);

      Assert (Audit.Failure_Count (Result) = 6,
              "adapter validation must reject incomplete shared-harness adapters");
      Assert (not Audit.Adapter_Supports_Shared_Harness (Adapter),
              "adapter support predicate must reject incomplete adapters");
   end Test_Adapter_Validation_Rejects_Incomplete_Adapters;

   procedure Test_Adapter_Validation_Rejects_Unnamed_Catalog_Entries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result  : Audit.Projection_Surface_Audit_Result;
      Adapter : Audit.Projection_Surface_Adapter :=
        Audit.Adapter_For_Surface (Audit.Navigation_History_Surface);
   begin
      --  Oversized counts force the reusable adapter validation through the
      --  out-of-range catalog entries.  This proves the milestone helper does
      --  not merely compare counts; it also validates that the named retained
      --  source, forbidden field, and forbidden route catalogs are populated.
      Adapter.Canonical_Source_Count := Adapter.Canonical_Source_Count + 1;
      Adapter.Forbidden_Field_Count := Adapter.Forbidden_Field_Count + 1;
      Adapter.Forbidden_Route_Count := Adapter.Forbidden_Route_Count + 1;
      Adapter.Forbidden_Render_Field_Count := Adapter.Forbidden_Render_Field_Count + 1;

      Audit.Validate_Adapter (Result, Adapter);

      Assert (Audit.Failure_Count (Result) = 8,
              "adapter validation must reject oversized counts and unnamed catalog entries: "
              & Audit.Summary (Result));
      Assert (not Audit.Adapter_Supports_Shared_Harness (Adapter),
              "adapter support predicate must reject adapters with catalog/count drift");
   end Test_Adapter_Validation_Rejects_Unnamed_Catalog_Entries;

   procedure Test_Operation_Expectation_Rejects_Broken_Semantics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result      : Audit.Projection_Surface_Audit_Result;
      Expectation : Audit.Projection_Surface_Observation_Expectation :=
        Audit.Observation_Expectation (Audit.Save_As_Operation);
   begin
      Expectation.No_Target_History_Created := False;
      Assert (not Audit.Observation_Expectation_Coherent (Expectation),
              "operation expectation must reject target-history creation");

      Expectation := Audit.Observation_Expectation (Audit.Rename_Operation);
      Expectation.No_Failed_Target_Displayed := False;
      Assert (not Audit.Observation_Expectation_Coherent (Expectation),
              "operation expectation must reject failed-target display");

      Audit.Assert_Surface_Lifecycle_Operation_Semantics
        (Result, Audit.Bookmarks_Surface, Audit.Move_Operation);
      Assert (Audit.Failure_Count (Result) = 0,
              "shared operation assertion must accept canonical move observation semantics");
   end Test_Operation_Expectation_Rejects_Broken_Semantics;

   procedure Test_Lifecycle_Event_Expectation_Matrix_Covers_Shared_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : Audit.Projection_Surface_Audit_Result;
   begin
      for Event in Audit.Projection_Surface_Lifecycle_Event loop
         declare
            Expectation : constant Audit.Projection_Surface_Lifecycle_Event_Expectation :=
              Audit.Lifecycle_Event_Expectation (Event);
         begin
            Assert (Expectation.Event = Event,
                    "lifecycle event expectation must preserve event identity");
            Assert (Audit.Lifecycle_Event_Name (Event) /= "",
                    "lifecycle matrix must name every shared lifecycle event");
            Assert (Audit.Lifecycle_Event_Expectation_Coherent (Expectation),
                    Audit.Lifecycle_Event_Name (Event)
                    & " expectation must preserve no-history/no-prompt/no-persistence cleanup");

            for Surface in Audit.Projection_Surface_Id loop
               Assert (Audit.Surface_Lifecycle_Event_Coherent (Surface, Event),
                       Audit.Surface_Name (Surface) & " must satisfy "
                       & Audit.Lifecycle_Event_Name (Event)
                       & " shared cleanup semantics");
               Audit.Assert_Surface_Lifecycle_Event_Semantics (Result, Surface, Event);
            end loop;
         end;
      end loop;

      Assert (Audit.Failure_Count (Result) = 0,
              "shared lifecycle event assertions must accept all covered surfaces: "
              & Audit.Summary (Result));
   end Test_Lifecycle_Event_Expectation_Matrix_Covers_Shared_Cleanup;

   procedure Test_Lifecycle_Event_Expectation_Rejects_Broken_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Expectation : Audit.Projection_Surface_Lifecycle_Event_Expectation :=
        Audit.Lifecycle_Event_Expectation (Audit.Workspace_Reload_Event);
   begin
      Expectation.No_Target_Or_Operation_History_Survives := False;
      Assert (not Audit.Lifecycle_Event_Expectation_Coherent (Expectation),
              "lifecycle event expectation must reject surviving target/operation history");

      Expectation := Audit.Lifecycle_Event_Expectation (Audit.Target_Prompt_Cleanup_Event);
      Expectation.No_Prompt_State_Survives := False;
      Assert (not Audit.Lifecycle_Event_Expectation_Coherent (Expectation),
              "lifecycle event expectation must reject prompt state surviving cleanup");

      Expectation := Audit.Lifecycle_Event_Expectation (Audit.Settings_Load_Event);
      Expectation.Retained_Surface_Persistence_Only := False;
      Assert (not Audit.Lifecycle_Event_Expectation_Coherent (Expectation),
              "lifecycle event expectation must reject lifecycle state restored through persistence");
   end Test_Lifecycle_Event_Expectation_Rejects_Broken_Cleanup;


   procedure Test_Cross_Surface_Import_Matrix_Is_Explicit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : Audit.Projection_Surface_Audit_Result;
   begin
      for Producer in Audit.Projection_Surface_Id loop
         for Consumer in Audit.Projection_Surface_Id loop
            if Producer = Consumer then
               Assert (not Audit.Cross_Surface_Import_Forbidden (Producer, Consumer),
                       "a surface's own retained source must not be classified as a cross-surface import");
            else
               Assert (Audit.Cross_Surface_Import_Forbidden (Producer, Consumer),
                       Audit.Cross_Surface_Import_Name (Producer, Consumer)
                       & " must be forbidden as lifecycle product truth");
            end if;

            Audit.Validate_Cross_Surface_Import (Result, Producer, Consumer);
         end loop;
      end loop;

      Assert (Audit.Failure_Count (Result) = 0,
              "explicit cross-surface import matrix must validate without failures: "
              & Audit.Summary (Result));
   end Test_Cross_Surface_Import_Matrix_Is_Explicit;

   procedure Test_Source_Target_Prompt_Boundary_Subrules_Are_Explicit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contract : Audit.Projection_Surface_Contract :=
        Audit.Default_Contract (Audit.Navigation_History_Surface);
      Result : Audit.Projection_Surface_Audit_Result;
   begin
      Assert (Audit.Expected_Prompt_Boundary_Rule_Count = 12,
              "shared prompt boundary must enumerate source/target input and target-prompt lifecycle subrules");

      for Rule in 1 .. Audit.Expected_Prompt_Boundary_Rule_Count loop
         Assert (Audit.Prompt_Boundary_Rule_Name (Rule) /= "",
                 "prompt boundary rule must have a deterministic name");
         Assert (Audit.Prompt_Boundary_Rule_Holds (Contract, Rule),
                 "default contract must satisfy prompt boundary subrule");
      end loop;

      Assert (Audit.Prompt_Boundary_Rule_Name
                (Audit.Expected_Prompt_Boundary_Rule_Count + 1) = "",
              "out-of-range prompt boundary rule names must be empty");
      Assert (not Audit.Prompt_Boundary_Rule_Holds
                    (Contract, Audit.Expected_Prompt_Boundary_Rule_Count + 1),
              "out-of-range prompt boundary rules must fail closed");

      Contract.Surface_Selected_Row_Not_Source := False;
      Contract.Surface_Query_Text_Not_Target := False;
      Contract.Surface_Retained_Target_Not_Input := False;
      Contract.Surface_Prompt_Input_Not_Mutated := False;
      Contract.Surface_Does_Not_Open_Target_Prompt := False;
      Contract.Surface_Does_Not_Confirm_Target_Prompt := False;
      Contract.Surface_Does_Not_Cancel_Target_Prompt := False;
      Contract.Prompt_Confirmation_Executor_Routed := False;
      Contract.Prompt_Cancellation_Non_Mutating := False;
      Contract.Prompt_Cleanup_Canonical := False;

      Audit.Validate_Surface (Result, Contract);
      Assert (Audit.Failure_Count (Result) = 11,
              "surface validation must report each broken detailed source/target/prompt boundary plus canonical prompt lifecycle failure");
      Assert (not Audit.Surface_Source_Target_Prompt_Boundary_Is_Canonical (Contract),
              "canonical prompt boundary predicate must reject any broken detailed subrule");
   end Test_Source_Target_Prompt_Boundary_Subrules_Are_Explicit;

   procedure Test_Reliability_Matrix_Covers_All_Workflows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : Audit.Projection_Surface_Audit_Result;
   begin
      for Surface in Audit.Projection_Surface_Id loop
         for Family in Audit.Projection_Surface_Reliability_Family loop
            Assert (Audit.Reliability_Family_Name (Family) /= "",
                    "reliability family must have a deterministic name");

            for Operation in Audit.File_Lifecycle_Operation loop
               for Context in Audit.Projection_Surface_Workflow_Context loop
                  declare
                     Expectation : constant Audit.Projection_Surface_Reliability_Expectation :=
                       Audit.Reliability_Expectation
                         (Surface, Family, Operation, Context);
                  begin
                     Assert (Audit.Workflow_Context_Name (Context) /= "",
                             "workflow context must have a deterministic name");
                     Assert (Expectation.Surface = Surface,
                             "reliability expectation must preserve surface identity");
                     Assert (Expectation.Family = Family,
                             "reliability expectation must preserve family identity");
                     Assert (Expectation.Operation = Operation,
                             "reliability expectation must preserve operation identity");
                     Assert (Expectation.Context = Context,
                             "reliability expectation must preserve workflow context identity");
                     Assert (Audit.Reliability_Expectation_Coherent (Expectation),
                             Audit.Surface_Name (Surface) & " must satisfy "
                             & Audit.Reliability_Family_Name (Family)
                             & " for " & Audit.Operation_Name (Operation)
                             & " while " & Audit.Workflow_Context_Name (Context));
                     Assert (Audit.Surface_Reliability_Coherent
                               (Surface, Family, Operation, Context),
                             "surface reliability predicate must match coherent expectation");

                     Audit.Validate_Surface_Reliability
                       (Result, Surface, Family, Operation, Context);
                  end;
               end loop;
            end loop;
         end loop;
      end loop;

      Assert (Audit.Failure_Count (Result) = 0,
              "shared reliability matrix must pass all covered surfaces: "
              & Audit.Summary (Result));
   end Test_Reliability_Matrix_Covers_All_Workflows;


   procedure Test_Reliability_Expectation_Rejects_Hazards
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Expectation : Audit.Projection_Surface_Reliability_Expectation :=
        Audit.Reliability_Expectation
          (Audit.Quick_Open_Surface,
           Audit.Failed_Blocked_Operation_Preservation,
           Audit.Rename_Operation,
           Audit.Surface_Visible_Path_Like_Selected_Row_Context);
   begin
      Assert (Audit.Reliability_Expectation_Coherent (Expectation),
              "baseline reliability expectation must be coherent");

      Expectation.Failure_Preservation := False;
      Assert (not Audit.Reliability_Expectation_Coherent (Expectation),
              "reliability must reject failed target leakage or mutation");

      Expectation := Audit.Reliability_Expectation
        (Audit.Project_Search_Surface,
         Audit.Source_Target_Boundary_Reliability,
         Audit.Move_Operation,
         Audit.Surface_Visible_Query_Filter_Context);
      Expectation.Source_Target_Boundary := False;
      Assert (not Audit.Reliability_Expectation_Coherent (Expectation),
              "reliability must reject query/selection source-target inference");

      Expectation := Audit.Reliability_Expectation
        (Audit.Bookmarks_Surface,
         Audit.Persistence_Exclusion_Reliability,
         Audit.Save_As_Operation,
         Audit.All_Surfaces_Co_Visible_Context);
      Expectation.Persistence_Exclusion := False;
      Assert (not Audit.Reliability_Expectation_Coherent (Expectation),
              "reliability must reject persistence leakage");

      Expectation := Audit.Reliability_Expectation
        (Audit.Navigation_History_Surface,
         Audit.Cross_Surface_Co_Visibility_Reliability,
         Audit.Copy_Operation,
         Audit.All_Surfaces_Co_Visible_Context);
      Expectation.Cross_Surface_Co_Visibility := False;
      Assert (not Audit.Reliability_Expectation_Coherent (Expectation),
              "reliability must reject cross-surface projection imports");
   end Test_Reliability_Expectation_Rejects_Hazards;


   procedure Test_Adapter_Requires_Runtime_Reliability_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result  : Audit.Projection_Surface_Audit_Result;
      Adapter : Audit.Projection_Surface_Adapter :=
        Audit.Adapter_For_Surface (Audit.Open_Buffer_Switcher_Surface);
   begin
      Adapter.Has_Selected_Or_Current_State := False;
      Adapter.Has_Query_State := False;
      Adapter.Has_Dirty_Hint_State := False;
      Adapter.Has_Retained_Target_State := False;
      Adapter.Has_Prompt_Ownership_Metadata := False;
      Adapter.Has_Cross_Surface_Import_Metadata := False;
      Adapter.Has_Snapshot_Freshness_Metadata := False;

      Audit.Validate_Adapter (Result, Adapter);

      Assert (Audit.Failure_Count (Result) = 7,
              "adapter validation must reject missing runtime reliability metadata: "
              & Audit.Summary (Result));
      Assert (not Audit.Adapter_Supports_Shared_Harness (Adapter),
              "adapter support predicate must reject missing reliability metadata");
   end Test_Adapter_Requires_Runtime_Reliability_Metadata;


   procedure Test_Reliability_Helper_Runs_All_Surface_Adapters
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : Audit.Projection_Surface_Audit_Result;
   begin
      Audit.Assert_File_Lifecycle_Projection_Surface_Reliability_Coherent (Result);
      Assert (Audit.Failure_Count (Result) = 0,
              "reliability helper must run all covered surfaces: "
              & Audit.Summary (Result));
      Assert (Audit.File_Lifecycle_Projection_Surface_Reliability_Coherent,
              "boolean reliability helper must validate all covered surfaces");
   end Test_Reliability_Helper_Runs_All_Surface_Adapters;




   procedure Test_Cleanup_Adapter_Rejects_Normalization_And_Repair
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result  : Audit.Projection_Surface_Audit_Result;
      Adapter : Audit.Projection_Surface_Adapter :=
        Audit.Adapter_For_Surface (Audit.Project_Search_Surface);
   begin
      Adapter.Exposes_Raw_Retained_State := False;
      Adapter.No_Path_Label_Normalization := False;
      Adapter.No_Dirty_Hint_Normalization := False;
      Adapter.No_Inferred_Target_Reconstruction := False;
      Adapter.No_Command_Execution := False;
      Adapter.No_Prompt_Control := False;
      Adapter.No_Filesystem_Probe := False;
      Adapter.No_Row_Repair := False;
      Adapter.No_Cross_Surface_Row_Lookup := False;
      Adapter.No_Persistence_Field_Filtering := False;
      Adapter.Has_Projection_Helper_Metadata := False;
      Adapter.Projection_Helpers_Pure := False;

      Audit.Validate_Adapter (Result, Adapter);

      Assert (Audit.Failure_Count (Result) = 12,
              "adapter cleanup must reject normalization, repair, "
              & "command/prompt control, probes, imports, filtering, "
              & "and impure helpers: " & Audit.Summary (Result));
      Assert (not Audit.Adapter_Supports_Shared_Harness (Adapter),
              "adapter support predicate must reject cleanup hazards");
   end Test_Cleanup_Adapter_Rejects_Normalization_And_Repair;

   procedure Test_Cleanup_Contract_Rejects_Local_Models
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result   : Audit.Projection_Surface_Audit_Result;
      Contract : Audit.Projection_Surface_Contract :=
        Audit.Default_Contract (Audit.Quick_Open_Surface);
   begin
      Contract.Adapter_Raw_Retained_State := False;
      Contract.No_Adapter_Lifecycle_Normalization := False;
      Contract.Projection_Helpers_Retained_Only := False;
      Contract.Projection_Helpers_No_Lifecycle_Inputs := False;
      Contract.No_Render_Lifecycle_State := False;
      Contract.No_Audit_Product_Truth_State := False;
      Contract.No_File_Lifecycle_Routes := False;
      Contract.No_Cross_Surface_Projection_Imports := False;
      Contract.No_Lifecycle_Persistence_State := False;
      Contract.Removed_Lifecycle_Fields_Dropped := False;

      Audit.Assert_Surface_Adapter_Is_Raw_And_NonRepairing (Result, Contract);
      Audit.Assert_Surface_Projection_Helper_Is_Pure (Result, Contract);
      Audit.Assert_Surface_Has_No_Local_Lifecycle_Routes (Result, Contract);
      Audit.Assert_Surface_Has_No_Cross_Surface_Lifecycle_Imports (Result, Contract);
      Audit.Assert_Render_Has_No_Projection_Lifecycle_State (Result, Contract);
      Audit.Assert_Audit_Has_No_Product_Truth_State (Result, Contract);
      Audit.Assert_Persistence_Has_No_Projection_Lifecycle_State (Result, Contract);
      Audit.Assert_Removed_Projection_Lifecycle_Fields_Dropped (Result, Contract);

      Assert (Audit.Failure_Count (Result) = 8,
              "cleanup assertions must report each consolidated cleanup boundary");
      Assert (not Audit.Surface_Adapter_Is_Raw_And_Nonrepairing (Contract),
              "raw adapter predicate must reject normalization/repair hazards");
      Assert (not Audit.Surface_Projection_Helper_Is_Pure (Contract),
              "pure helper predicate must reject lifecycle input dependencies");
   end Test_Cleanup_Contract_Rejects_Local_Models;

   procedure Test_Cleanup_Helper_Runs_Single_Shared_Authority
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : Audit.Projection_Surface_Audit_Result;
   begin
      Audit.Assert_File_Lifecycle_Projection_Surface_Cleanup_Coherent (Result);
      Assert (Audit.Failure_Count (Result) = 0,
              "cleanup helper must preserve the milestone/reliability harness while adding cleanup checks: "
              & Audit.Summary (Result));
      Assert (Audit.File_Lifecycle_Projection_Surface_Cleanup_Coherent,
              "boolean cleanup helper must validate all covered surfaces");
   end Test_Cleanup_Helper_Runs_Single_Shared_Authority;

   procedure Test_Final_Freeze_Helper_Runs_Single_Authority
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : Audit.Projection_Surface_Audit_Result;
   begin
      Audit.Assert_File_Lifecycle_Projection_Surface_Final_Freeze_Coherent (Result);
      Assert (Audit.Failure_Count (Result) = 0,
              "final freeze must preserve the shared milestone, "
              & "reliability, cleanup, and final regression boundaries: "
              & Audit.Summary (Result));
      Assert (Audit.File_Lifecycle_Projection_Surface_Final_Freeze_Coherent,
              "boolean final freeze helper must validate all surfaces");
   end Test_Final_Freeze_Helper_Runs_Single_Authority;

   procedure Test_Final_Freeze_Expectation_Covers_All_Surfaces
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : Audit.Projection_Surface_Audit_Result;
   begin
      for Surface in Audit.Projection_Surface_Id loop
         declare
            Expectation : constant Audit.Projection_Surface_Final_Freeze_Expectation :=
              Audit.Final_Freeze_Expectation (Surface);
         begin
            Assert (Expectation.Surface = Surface,
                    "final freeze expectation must preserve surface identity");
            Assert (Audit.Final_Freeze_Expectation_Coherent (Expectation),
                    Audit.Surface_Name (Surface)
                    & " must satisfy every final-freeze boundary");
            Assert (Audit.Surface_Final_Freeze_Coherent (Surface),
                    Audit.Surface_Name (Surface)
                    & " final-freeze predicate must match the expectation");
            Audit.Validate_Surface_Final_Freeze (Result, Surface);
         end;
      end loop;

      Assert (Audit.Failure_Count (Result) = 0,
              "final freeze validation must pass every covered surface: "
              & Audit.Summary (Result));
   end Test_Final_Freeze_Expectation_Covers_All_Surfaces;

   procedure Test_Final_Freeze_Rejects_Reintroduced_Ownership
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Expectation : Audit.Projection_Surface_Final_Freeze_Expectation :=
        Audit.Final_Freeze_Expectation (Audit.Navigation_History_Surface);
   begin
      Assert (Audit.Final_Freeze_Expectation_Coherent (Expectation),
              "baseline final freeze expectation must be coherent");

      Expectation.Shared_Invariant_Single_Authority := False;
      Assert (not Audit.Final_Freeze_Expectation_Coherent (Expectation),
              "final freeze must reject bypassing the shared invariant authority");
      Expectation.Shared_Invariant_Single_Authority := True;

      Expectation.Adapter_Raw_State_Frozen := False;
      Assert (not Audit.Final_Freeze_Expectation_Coherent (Expectation),
              "final freeze must reject adapter normalization or repair");
      Expectation.Adapter_Raw_State_Frozen := True;

      Expectation.Projection_Helper_Purity_Frozen := False;
      Assert (not Audit.Final_Freeze_Expectation_Coherent (Expectation),
              "final freeze must reject projection helper lifecycle inputs");
      Expectation.Projection_Helper_Purity_Frozen := True;

      Expectation.Source_Target_Prompt_Boundary_Frozen := False;
      Assert (not Audit.Final_Freeze_Expectation_Coherent (Expectation),
              "final freeze must reject source/target/prompt boundary drift");
      Expectation.Source_Target_Prompt_Boundary_Frozen := True;

      Expectation.Cross_Surface_Import_Absent_Frozen := False;
      Assert (not Audit.Final_Freeze_Expectation_Coherent (Expectation),
              "final freeze must reject cross-surface projection imports");
      Expectation.Cross_Surface_Import_Absent_Frozen := True;

      Expectation.Persistence_Exclusion_Frozen := False;
      Assert (not Audit.Final_Freeze_Expectation_Coherent (Expectation),
              "final freeze must reject persistence leakage");
      Expectation.Persistence_Exclusion_Frozen := True;

      Expectation.Removed_Field_Drop_Frozen := False;
      Assert (not Audit.Final_Freeze_Expectation_Coherent (Expectation),
              "final freeze must reject removed lifecycle fields surviving");
      Expectation.Removed_Field_Drop_Frozen := True;

      Expectation.Duplicate_Ownership_Absent_Frozen := False;
      Assert (not Audit.Final_Freeze_Expectation_Coherent (Expectation),
              "final freeze must reject duplicate per-surface ownership paths");
   end Test_Final_Freeze_Rejects_Reintroduced_Ownership;


   procedure Test_Current_Surfaces_Are_Registered
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : Audit.Projection_Surface_Audit_Result;
   begin
      for Surface in Audit.Projection_Surface_Id loop
         declare
            Registration : constant Audit.Projection_Surface_Registration :=
              Audit.Registration_For_Surface (Surface);
         begin
            Assert (Registration.Is_Registered,
                    Audit.Surface_Name (Surface) & " must be registered");
            Assert (Registration.Classification /= Audit.Projection_Surface_None,
                    Audit.Surface_Name (Surface) & " must be lifecycle classified");
            Assert (Audit.Surface_Is_Registered (Surface),
                    Audit.Surface_Name (Surface) & " registration predicate must be true");
            Assert (Audit.Projection_Surface_Registration_Coherent (Registration),
                    Audit.Surface_Name (Surface) & " registration must be coherent");
            Audit.Validate_Projection_Surface_Registration (Result, Registration);
         end;
      end loop;

      Assert (Audit.Failure_Count (Result) = 0,
              "registration gate must accept all covered surfaces: "
              & Audit.Summary (Result));
   end Test_Current_Surfaces_Are_Registered;

   procedure Test_Unregistered_Surface_Audit_Rejects_Row_Fields
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result     : Audit.Projection_Surface_Audit_Result;
      Inspection : Audit.Projection_Surface_Inspection;
   begin
      Inspection.Exposes_Path_File_Label := True;
      Audit.Validate_Projection_Surface_Inspection (Result, Inspection);
      Assert (Audit.Failure_Count (Result) > 0,
              "unregistered path-like rows must fail the adoption gate");

      Audit.Clear (Result);
      Inspection := (others => <>);
      Inspection.Exposes_Dirty_Hint := True;
      Audit.Validate_Projection_Surface_Inspection (Result, Inspection);
      Assert (Audit.Failure_Count (Result) > 0,
              "unregistered dirty hints must fail the adoption gate");

      Audit.Clear (Result);
      Inspection := (others => <>);
      Inspection.Exposes_Retained_Target := True;
      Audit.Validate_Projection_Surface_Inspection (Result, Inspection);
      Assert (Audit.Failure_Count (Result) > 0,
              "unregistered retained targets must fail the adoption gate");

      Audit.Clear (Result);
      Inspection := (others => <>);
      Inspection.Exposes_Buffer_Identity := True;
      Audit.Validate_Projection_Surface_Inspection (Result, Inspection);
      Assert (Audit.Failure_Count (Result) > 0,
              "unregistered buffer associations must fail the adoption gate");
   end Test_Unregistered_Surface_Audit_Rejects_Row_Fields;

   procedure Test_Unregistered_Surface_Audit_Rejects_Routes_And_Persistence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result     : Audit.Projection_Surface_Audit_Result;
      Inspection : Audit.Projection_Surface_Inspection;
   begin
      Inspection.Has_Local_Lifecycle_Route := True;
      Audit.Validate_Projection_Surface_Inspection (Result, Inspection);
      Assert (Audit.Failure_Count (Result) > 0,
              "unregistered local lifecycle routes must fail the adoption gate");

      Audit.Clear (Result);
      Inspection := (others => <>);
      Inspection.Has_Lifecycle_Persistence_Field := True;
      Audit.Validate_Projection_Surface_Inspection (Result, Inspection);
      Assert (Audit.Failure_Count (Result) > 0,
              "unregistered lifecycle persistence fields must fail the adoption gate");
   end Test_Unregistered_Surface_Audit_Rejects_Routes_And_Persistence;

   procedure Test_None_Surface_Without_Lifecycle_State_Is_Allowed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result     : Audit.Projection_Surface_Audit_Result;
      Inspection : Audit.Projection_Surface_Inspection :=
        (Registered                       => False,
         Classification                   => Audit.Projection_Surface_None,
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
         Has_Explicit_Audit_Exemption     => False);
   begin
      Audit.Validate_Projection_Surface_Inspection (Result, Inspection);
      Assert (Audit.Failure_Count (Result) = 0,
              "non-lifecycle surfaces classified as none must be allowed: "
              & Audit.Summary (Result));
      Assert (Audit.Projection_Surface_Inspection_Coherent (Inspection),
              "none-classified non-lifecycle inspection should be coherent");
   end Test_None_Surface_Without_Lifecycle_State_Is_Allowed;

   procedure Test_Registration_Audit_Rejects_Missing_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result       : Audit.Projection_Surface_Audit_Result;
      Registration : Audit.Projection_Surface_Registration :=
        Audit.Registration_For_Surface (Audit.Project_Search_Surface);
   begin
      Registration.Has_Forbidden_Field_Metadata := False;
      Registration.Has_Forbidden_Route_Metadata := False;
      Registration.Has_Persistence_Inspection_Hook := False;
      Registration.Runs_Shared_Invariant_Harness := False;

      Audit.Validate_Projection_Surface_Registration (Result, Registration);
      Assert (Audit.Failure_Count (Result) = 4,
              "registration gate must reject missing shared harness/metadata: "
              & Audit.Summary (Result));
      Assert (not Audit.Projection_Surface_Registration_Coherent (Registration),
              "registration coherence predicate must reject missing metadata");
   end Test_Registration_Audit_Rejects_Missing_Metadata;

   procedure Test_Future_Surface_Template_Is_Raw_And_Nonrepairing
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result  : Audit.Projection_Surface_Audit_Result;
      Adapter : constant Audit.Projection_Surface_Adapter :=
        Audit.Build_Future_Surface_Projection_Surface_Adapter
          (Audit.Quick_Open_Surface, Audit.Projection_Surface_Candidate_Like);
   begin
      Assert (Adapter.Exposes_Raw_Retained_State,
              "future template must expose raw retained state");
      Assert (Adapter.Has_Selected_Or_Current_State and then Adapter.Has_Query_State,
              "future template must expose selected/current/query state where applicable");
      Assert (Adapter.No_Persistence_Field_Filtering,
              "future template must not mask persistence leaks");
      Assert (Adapter.No_Filesystem_Probe,
              "future template must reject filesystem probing");
      Assert (Adapter.No_Command_Execution,
              "future template must reject command execution");
      Assert (Adapter.No_Row_Repair,
              "future template must reject target/row repair");
      Assert (Adapter.No_Cross_Surface_Row_Lookup,
              "future template must reject cross-surface imports");

      Audit.Validate_Adapter (Result, Adapter);
      Assert (Audit.Failure_Count (Result) = 0,
              "future surface template must support shared harness: "
              & Audit.Summary (Result));
   end Test_Future_Surface_Template_Is_Raw_And_Nonrepairing;

   procedure Test_Adoption_Gate_Helper_Preserves_Final_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : Audit.Projection_Surface_Audit_Result;
   begin
      Audit.Assert_Projection_Surface_Invariant_Adoption_Gate_Coherent (Result);
      Assert (Audit.Failure_Count (Result) = 0,
              "adoption gate must preserve final freeze: "
              & Audit.Summary (Result));
      Assert (Audit.Projection_Surface_Invariant_Adoption_Gate_Coherent,
              "boolean helper must validate adoption gate");
   end Test_Adoption_Gate_Helper_Preserves_Final_Freeze;

   overriding procedure Register_Tests
     (T : in out Projection_Surface_File_Lifecycle_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Audit_Result_Collects_Forbidden_Ownership'Access,
         "shared audit reports forbidden projection ownership");
      Register_Routine
        (T, Test_All_Covered_Surface_Defaults_Are_Coherent'Access,
         "shared milestone helper covers all projection surfaces");
      Register_Routine
        (T, Test_Surface_Wrappers_Preserve_Per_Surface_Freezes'Access,
         "surface wrappers preserve per-surface lifecycle freezes");
      Register_Routine
        (T, Test_Cross_Surface_Imports_Are_Not_Product_Truth'Access,
         "cross-surface projection imports are forbidden as product truth");
      Register_Routine
        (T, Test_Render_And_Audit_Boundaries_Are_Shared'Access,
         "render and audit boundaries are shared across projection surfaces");
      Register_Routine
        (T, Test_Shared_Named_Predicates_Map_To_Contract'Access,
         "shared named predicates map to the projection-surface contract");
      Register_Routine
        (T, Test_Shared_Audit_Adapters_Read_Surface_Predicates'Access,
         "shared audit adapters read each surface's exported predicates");
      Register_Routine
        (T, Test_Named_Predicates_Reject_Broken_Contract'Access,
         "shared named predicates reject broken projection contracts");
      Register_Routine
        (T, Test_Surface_Adapters_Expose_Shared_Harness_Shape'Access,
         "surface adapters expose the reusable shared harness shape");
      Register_Routine
        (T, Test_Command_And_Persistence_Boundaries_Are_Shared'Access,
         "command routing and persistence boundaries are shared");
      Register_Routine
        (T, Test_Adapters_Expose_Named_Source_Field_And_Route_Catalogs'Access,
         "shared adapters expose named source/field/route catalogs");
      Register_Routine
        (T, Test_Catalogs_Are_Deterministic_And_Nonduplicated'Access,
         "shared catalogs are deterministic and nonduplicated");
      Register_Routine
        (T, Test_Shared_Assertion_Helpers_Add_Failures'Access,
         "shared assertion helpers append deterministic failures");
      Register_Routine
        (T, Test_Lifecycle_Operation_Expectation_Matrix_Covers_All_Commands'Access,
         "shared lifecycle operation expectation matrix covers canonical commands");
      Register_Routine
        (T, Test_Adapter_Validation_Rejects_Incomplete_Adapters'Access,
         "shared adapter validation rejects incomplete adapters");
      Register_Routine
        (T, Test_Adapter_Validation_Rejects_Unnamed_Catalog_Entries'Access,
         "shared adapter validation rejects unnamed catalog entries");
      Register_Routine
        (T, Test_Operation_Expectation_Rejects_Broken_Semantics'Access,
         "shared operation expectations reject broken lifecycle semantics");
      Register_Routine
        (T, Test_Lifecycle_Event_Expectation_Matrix_Covers_Shared_Cleanup'Access,
         "shared lifecycle event matrix covers cleanup/load/restart boundaries");
      Register_Routine
        (T, Test_Lifecycle_Event_Expectation_Rejects_Broken_Cleanup'Access,
         "shared lifecycle event expectations reject broken cleanup semantics");
      Register_Routine
        (T, Test_Cross_Surface_Import_Matrix_Is_Explicit'Access,
         "shared cross-surface import matrix is explicit");
      Register_Routine
        (T, Test_Source_Target_Prompt_Boundary_Subrules_Are_Explicit'Access,
         "shared source/target/prompt boundary subrules are explicit");
      Register_Routine
        (T, Test_Reliability_Matrix_Covers_All_Workflows'Access,
         "shared reliability matrix covers all workflow families");
      Register_Routine
        (T, Test_Reliability_Expectation_Rejects_Hazards'Access,
         "reliability expectations reject lifecycle hazards");
      Register_Routine
        (T, Test_Adapter_Requires_Runtime_Reliability_Metadata'Access,
         "adapters expose runtime reliability metadata");
      Register_Routine
        (T, Test_Reliability_Helper_Runs_All_Surface_Adapters'Access,
         "reliability helper runs all surface adapters");
      Register_Routine
        (T, Test_Cleanup_Adapter_Rejects_Normalization_And_Repair'Access,
         "cleanup adapters reject normalization and repair");
      Register_Routine
        (T, Test_Cleanup_Contract_Rejects_Local_Models'Access,
         "cleanup contract rejects local lifecycle models");
      Register_Routine
        (T, Test_Cleanup_Helper_Runs_Single_Shared_Authority'Access,
         "cleanup helper runs the single shared authority");
      Register_Routine
        (T, Test_Final_Freeze_Helper_Runs_Single_Authority'Access,
         "final freeze helper runs the single shared authority");
      Register_Routine
        (T, Test_Final_Freeze_Expectation_Covers_All_Surfaces'Access,
         "final freeze expectations cover all surfaces");
      Register_Routine
        (T, Test_Final_Freeze_Rejects_Reintroduced_Ownership'Access,
         "final freeze rejects reintroduced ownership");
      Register_Routine
        (T, Test_Current_Surfaces_Are_Registered'Access,
         "current projection surfaces are registered");
      Register_Routine
        (T, Test_Unregistered_Surface_Audit_Rejects_Row_Fields'Access,
         "audit rejects unregistered lifecycle row fields");
      Register_Routine
        (T, Test_Unregistered_Surface_Audit_Rejects_Routes_And_Persistence'Access,
         "audit rejects unregistered routes and persistence");
      Register_Routine
        (T, Test_None_Surface_Without_Lifecycle_State_Is_Allowed'Access,
         "audit permits non-lifecycle none surfaces");
      Register_Routine
        (T, Test_Registration_Audit_Rejects_Missing_Metadata'Access,
         "registration audit rejects missing metadata");
      Register_Routine
        (T, Test_Future_Surface_Template_Is_Raw_And_Nonrepairing'Access,
         "future surface template is raw and nonrepairing");
      Register_Routine
        (T, Test_Adoption_Gate_Helper_Preserves_Final_Freeze'Access,
         "adoption gate preserves final freeze");
      Register_Routine
        (T, Test_Milestone_Assertion_Helper_Runs_All_Surface_Adapters'Access,
         "milestone assertion helper runs all surface adapters");
   end Register_Tests;

end Editor.Projection_Surface_File_Lifecycle.Tests;
