with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Bookmarks;
with Editor.Buffer_Switcher;
with Editor.Navigation_History;
with Editor.Project_Search;
with Editor.Quick_Open;

package body Editor.Projection_Surface_File_Lifecycle_Audit.Surface_Checks is

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

   function Default_Contract
     (Surface : Projection_Surface_Id) return Projection_Surface_Contract
   is
   begin
      return (Surface => Surface, others => True);
   end Default_Contract;


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

end Editor.Projection_Surface_File_Lifecycle_Audit.Surface_Checks;
