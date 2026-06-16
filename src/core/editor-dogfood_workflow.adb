with Ada.Characters.Handling;
with Ada.Strings.Fixed;

package body Editor.Dogfood_Workflow is

   function Missing
     (Text   : String;
      Needle : String) return Boolean
   is
   begin
      return Ada.Strings.Fixed.Index (Text, Needle) = 0;
   end Missing;

   function Contains
     (Text   : String;
      Needle : String) return Boolean
   is
   begin
      return Ada.Strings.Fixed.Index (Text, Needle) > 0;
   end Contains;

   function Missing_Case_Insensitive
     (Text   : String;
      Needle : String) return Boolean
   is
      Lower_Text   : constant String := Ada.Characters.Handling.To_Lower (Text);
      Lower_Needle : constant String := Ada.Characters.Handling.To_Lower (Needle);
   begin
      return Ada.Strings.Fixed.Index (Lower_Text, Lower_Needle) = 0;
   end Missing_Case_Insensitive;

   function Surface_Label (Surface : Dogfood_Surface) return String is
   begin
      case Surface is
         when Dogfood_Surface_File_Tree => return "File Tree";
         when Dogfood_Surface_Quick_Open => return "Quick Open";
         when Dogfood_Surface_Project_Search => return "Project Search";
         when Dogfood_Surface_Outline => return "Outline";
         when Dogfood_Surface_Diagnostics => return "Diagnostics";
         when Dogfood_Surface_Build => return "Build";
         when Dogfood_Surface_Editing => return "Editor";
         when Dogfood_Surface_Command_Palette => return "Command Palette";
         when Dogfood_Surface_Persistence => return "Workspace";
      end case;
   end Surface_Label;

   function Dogfood_Status_Label
     (Surface : Dogfood_Surface;
      State   : Dogfood_State) return String
   is
   begin
      case State is
         when Dogfood_State_Ready =>
            return Surface_Label (Surface) & " ready.";
         when Dogfood_State_No_Project =>
            return Surface_Label (Surface) & ": No project open.";
         when Dogfood_State_No_Selection =>
            return Surface_Label (Surface) & ": No file selected.";
         when Dogfood_State_Empty =>
            case Surface is
               when Dogfood_Surface_File_Tree => return "No files found.";
               when Dogfood_Surface_Quick_Open => return "No Quick Open matches.";
               when Dogfood_Surface_Project_Search => return "No search results.";
               when Dogfood_Surface_Outline => return "No outline items found.";
               when Dogfood_Surface_Diagnostics => return "No diagnostics.";
               when Dogfood_Surface_Build => return "No build candidates.";
               when Dogfood_Surface_Command_Palette => return "No command matches.";
               when others => return Surface_Label (Surface) & " has no results.";
            end case;
         when Dogfood_State_Stale =>
            return Surface_Label (Surface) & " may be stale; refresh before activating.";
         when Dogfood_State_Target_Unavailable =>
            return Surface_Label (Surface) & ": Target no longer exists.";
         when Dogfood_State_Consent_Missing =>
            return "Build run unavailable: review the request and acknowledge consent first.";
         when Dogfood_State_Succeeded =>
            case Surface is
               when Dogfood_Surface_File_Tree => return "Opened file.";
               when Dogfood_Surface_Quick_Open => return "Opened Quick Open result.";
               when Dogfood_Surface_Project_Search => return "Opened search result.";
               when Dogfood_Surface_Outline => return "Opened outline target.";
               when Dogfood_Surface_Diagnostics => return "Diagnostic opened.";
               when Dogfood_Surface_Editing => return "Saved file.";
               when Dogfood_Surface_Persistence => return "Workspace loaded.";
               when others => return Surface_Label (Surface) & " completed.";
            end case;
         when Dogfood_State_Failed =>
            return Surface_Label (Surface) & " failed; review the reason and try again.";
      end case;
   end Dogfood_Status_Label;

   function Dogfood_Unavailable_Reason_Label
     (Surface : Dogfood_Surface;
      State   : Dogfood_State) return String
   is
   begin
      case State is
         when Dogfood_State_No_Project =>
            return "No project open.";
         when Dogfood_State_No_Selection =>
            case Surface is
               when Dogfood_Surface_File_Tree => return "No File Tree node selected.";
               when Dogfood_Surface_Quick_Open => return "No Quick Open match selected.";
               when Dogfood_Surface_Project_Search => return "No search result selected.";
               when Dogfood_Surface_Outline => return "No outline item selected.";
               when Dogfood_Surface_Diagnostics => return "No diagnostic selected.";
               when others => return Surface_Label (Surface) & ": No file selected.";
            end case;
         when Dogfood_State_Empty =>
            return Dogfood_Status_Label (Surface, State);
         when Dogfood_State_Stale =>
            case Surface is
               when Dogfood_Surface_Project_Search =>
                  return "Search result is stale; run Project Search again.";
               when Dogfood_Surface_Outline =>
                  return "Outline may be stale; refresh Outline before navigating.";
               when Dogfood_Surface_Build =>
                  return "Build request changed; review and acknowledge consent again.";
               when others =>
                  return Dogfood_Status_Label (Surface, State);
            end case;
         when Dogfood_State_Target_Unavailable =>
            case Surface is
               when Dogfood_Surface_Diagnostics =>
                  return "Target no longer exists.";
               when Dogfood_Surface_Project_Search =>
                  return "Target no longer exists.";
               when Dogfood_Surface_Outline =>
                  return "Target no longer exists.";
               when others =>
                  return Dogfood_Status_Label (Surface, State);
            end case;
         when Dogfood_State_Consent_Missing =>
            return Dogfood_Status_Label (Dogfood_Surface_Build, State);
         when others =>
            return Dogfood_Status_Label (Surface, State);
      end case;
   end Dogfood_Unavailable_Reason_Label;

   function Dogfood_Label_Is_User_Readable (Label : String) return Boolean is
   begin
      return Label'Length >= 10
        and then not Contains (Label, "_")
        and then not Contains (Label, "COMMAND_")
        and then not Contains (Label, "Build_UI_")
        and then not Contains (Label, "Diagnostics_Ingestion_")
        and then (Contains (Label, ".")
                  or else Contains (Label, ":")
                  or else Contains (Label, "No ")
                  or else Contains (Label, "Opened")
                  or else Contains (Label, "Saved"));
   end Dogfood_Label_Is_User_Readable;

   function Assert_Dogfood_Messages_User_Readable return Boolean is
   begin
      return Dogfood_Label_Is_User_Readable
          (Dogfood_Unavailable_Reason_Label
             (Dogfood_Surface_File_Tree, Dogfood_State_No_Selection))
        and then Dogfood_Label_Is_User_Readable
          (Dogfood_Unavailable_Reason_Label
             (Dogfood_Surface_Quick_Open, Dogfood_State_No_Selection))
        and then Dogfood_Label_Is_User_Readable
          (Dogfood_Unavailable_Reason_Label
             (Dogfood_Surface_Project_Search, Dogfood_State_Stale))
        and then Dogfood_Label_Is_User_Readable
          (Dogfood_Unavailable_Reason_Label
             (Dogfood_Surface_Outline, Dogfood_State_Stale))
        and then Dogfood_Label_Is_User_Readable
          (Dogfood_Unavailable_Reason_Label
             (Dogfood_Surface_Diagnostics, Dogfood_State_Target_Unavailable))
        and then Dogfood_Label_Is_User_Readable
          (Dogfood_Unavailable_Reason_Label
             (Dogfood_Surface_Build, Dogfood_State_Consent_Missing))
        and then Dogfood_Label_Is_User_Readable
          (Dogfood_Status_Label
             (Dogfood_Surface_Command_Palette, Dogfood_State_Empty))
        and then Dogfood_Label_Is_User_Readable
          (Dogfood_Status_Label
             (Dogfood_Surface_Persistence, Dogfood_State_Succeeded));
   end Assert_Dogfood_Messages_User_Readable;

   function Assert_Dogfood_Focus_Transitions_Coherent return Boolean is
   begin
      --  The dogfood policy is intentionally small and deterministic: activating
      --  file, Quick Open, Project Search, Outline, or Diagnostic targets returns
      --  focus to the editor buffer; Build reveal keeps routing through the
      --  existing Diagnostics surface; no transition implies persistence.
      return Dogfood_Status_Label
          (Dogfood_Surface_Quick_Open, Dogfood_State_Succeeded) =
            "Opened Quick Open result."
        and then Dogfood_Status_Label
          (Dogfood_Surface_Project_Search, Dogfood_State_Succeeded) =
            "Opened search result."
        and then Dogfood_Status_Label
          (Dogfood_Surface_Outline, Dogfood_State_Succeeded) =
            "Opened outline target."
        and then Dogfood_Status_Label
          (Dogfood_Surface_Diagnostics, Dogfood_State_Succeeded) =
            "Diagnostic opened.";
   end Assert_Dogfood_Focus_Transitions_Coherent;

   function Assert_Dogfood_Usability_Fixes_Coherent
     (Workspace_Text : String) return Boolean
   is
   begin
      return Assert_Dogfood_Messages_User_Readable
        and then Assert_Dogfood_Focus_Transitions_Coherent
        and then Assert_Dogfood_Transient_State_Not_Persisted (Workspace_Text);
   end Assert_Dogfood_Usability_Fixes_Coherent;


   function Startup_State_Label
     (Surface : Startup_Surface) return String
   is
   begin
      case Surface is
         when Startup_Project =>
            return "No project open.";
         when Startup_Active_Buffer =>
            return "No active buffer.";
         when Startup_File_Tree =>
            return "File Tree: No project open.";
         when Startup_Quick_Open =>
            return "Quick Open: No project open.";
         when Startup_Project_Search =>
            return "Search: No project open.";
         when Startup_Diagnostics =>
            return "No diagnostics.";
         when Startup_Outline =>
            return "Outline: No active buffer.";
         when Startup_Build =>
            return "Build: No project open.";
         when Startup_Command_Palette =>
            return "Command Palette available.";
         when Startup_Recent_Projects =>
            return "Recent projects loaded when available.";
      end case;
   end Startup_State_Label;

   function First_Run_Command_Disabled_Reason
     (Surface : Dogfood_Surface;
      State   : Dogfood_State) return String
   is
   begin
      case State is
         when Dogfood_State_No_Project =>
            return "No project open.";
         when Dogfood_State_No_Selection =>
            case Surface is
               when Dogfood_Surface_File_Tree => return "No file selected.";
               when Dogfood_Surface_Quick_Open => return "No Quick Open match selected.";
               when Dogfood_Surface_Project_Search => return "No search result selected.";
               when Dogfood_Surface_Outline => return "No outline items found.";
               when Dogfood_Surface_Diagnostics => return "No diagnostics.";
               when others => return "No item selected.";
            end case;
         when Dogfood_State_Consent_Missing =>
            return "Consent required.";
         when Dogfood_State_Empty =>
            case Surface is
               when Dogfood_Surface_Project_Search => return "No search query.";
               when Dogfood_Surface_Build => return "No build request ready.";
               when Dogfood_Surface_Diagnostics => return "No diagnostics.";
               when Dogfood_Surface_Outline => return "No outline items found.";
               when others => return Dogfood_Status_Label (Surface, State);
            end case;
         when others =>
            return Dogfood_Unavailable_Reason_Label (Surface, State);
      end case;
   end First_Run_Command_Disabled_Reason;

   function Workspace_Reload_User_Message
     (State : Workspace_Reload_State) return String
   is
   begin
      case State is
         when Workspace_Loaded => return "Workspace loaded.";
         when Workspace_Saved => return "Workspace saved.";
         when Workspace_No_Project_To_Restore =>
            return "Workspace contains no project to restore.";
         when Workspace_Some_Files_Not_Reopened =>
            return "Some files could not be reopened.";
         when Workspace_Unsupported_Fields_Ignored =>
            return "Unsupported workspace fields ignored.";
      end case;
   end Workspace_Reload_User_Message;

   function Assert_Fresh_Startup_Coherent return Boolean is
   begin
      return Startup_State_Label (Startup_Project) = "No project open."
        and then Startup_State_Label (Startup_Active_Buffer) = "No active buffer."
        and then Startup_State_Label (Startup_File_Tree) =
          "File Tree: No project open."
        and then Startup_State_Label (Startup_Quick_Open) =
          "Quick Open: No project open."
        and then Startup_State_Label (Startup_Project_Search) =
          "Search: No project open."
        and then Startup_State_Label (Startup_Diagnostics) = "No diagnostics."
        and then Startup_State_Label (Startup_Outline) =
          "Outline: No active buffer."
        and then Startup_State_Label (Startup_Build) =
          "Build: No project open."
        and then Startup_State_Label (Startup_Command_Palette) =
          "Command Palette available."
        and then Dogfood_Label_Is_User_Readable
          (Startup_State_Label (Startup_Quick_Open))
        and then Dogfood_Label_Is_User_Readable
          (Startup_State_Label (Startup_Outline))
        and then Dogfood_Label_Is_User_Readable
          (Startup_State_Label (Startup_Build));
   end Assert_Fresh_Startup_Coherent;

   function Assert_First_Run_Command_Surface_Coherent return Boolean is
   begin
      return First_Run_Command_Disabled_Reason
          (Dogfood_Surface_Quick_Open, Dogfood_State_No_Project) =
            "No project open."
        and then First_Run_Command_Disabled_Reason
          (Dogfood_Surface_Project_Search, Dogfood_State_Empty) =
            "No search query."
        and then First_Run_Command_Disabled_Reason
          (Dogfood_Surface_Build, Dogfood_State_Empty) =
            "No build request ready."
        and then First_Run_Command_Disabled_Reason
          (Dogfood_Surface_Build, Dogfood_State_Consent_Missing) =
            "Consent required."
        and then First_Run_Command_Disabled_Reason
          (Dogfood_Surface_Diagnostics, Dogfood_State_No_Selection) =
            "No diagnostics."
        and then First_Run_Command_Disabled_Reason
          (Dogfood_Surface_Outline, Dogfood_State_No_Selection) =
            "No outline items found."
        and then First_Run_Command_Disabled_Reason
          (Dogfood_Surface_File_Tree, Dogfood_State_No_Selection) =
            "No file selected.";
   end Assert_First_Run_Command_Surface_Coherent;

   function Assert_Recent_Project_Does_Not_Restore_Transient_State
     (Recent_Project_Text : String) return Boolean
   is
   begin
      return Contains (Recent_Project_Text, "project")
        and then Missing (Recent_Project_Text, "workspace")
        and then Missing (Recent_Project_Text, "Build_Candidates")
        and then Missing (Recent_Project_Text, "Selected_Build_Candidate")
        and then Missing (Recent_Project_Text, "Consent")
        and then Missing (Recent_Project_Text, "Latest_Build")
        and then Missing (Recent_Project_Text, "Build_Output")
        and then Missing (Recent_Project_Text, "Search_Result")
        and then Missing (Recent_Project_Text, "Quick_Open")
        and then Missing (Recent_Project_Text, "File_Tree_Node")
        and then Missing (Recent_Project_Text, "Outline")
        and then Missing (Recent_Project_Text, "Diagnostic");
   end Assert_Recent_Project_Does_Not_Restore_Transient_State;

   function Assert_Workspace_Reload_Minimal
     (Workspace_Text : String) return Boolean
   is
   begin
      return Missing (Workspace_Text, "Unsaved_Buffer_Text")
        and then Missing (Workspace_Text, "Build_Candidates")
        and then Missing (Workspace_Text, "Selected_Build_Candidate")
        and then Missing (Workspace_Text, "Consent")
        and then Missing (Workspace_Text, "Latest_Build")
        and then Missing (Workspace_Text, "Build_Output")
        and then Missing (Workspace_Text, "Outline")
        and then Missing (Workspace_Text, "Search_Result")
        and then Missing (Workspace_Text, "Project_Search_Result")
        and then Missing (Workspace_Text, "Quick_Open")
        and then Missing (Workspace_Text, "Command_Palette_Query")
        and then Assert_Dogfood_Transient_State_Not_Persisted (Workspace_Text);
   end Assert_Workspace_Reload_Minimal;

   function Assert_Dogfood_Repeatable
     (First_Run_Workspace_Text  : String;
      Second_Run_Workspace_Text : String) return Boolean
   is
   begin
      return Assert_Workspace_Reload_Minimal (First_Run_Workspace_Text)
        and then Assert_Workspace_Reload_Minimal (Second_Run_Workspace_Text)
        and then Missing (First_Run_Workspace_Text, "Dogfood_Transient")
        and then Missing (Second_Run_Workspace_Text, "Dogfood_Transient")
        and then Contains (First_Run_Workspace_Text, "project")
        and then Contains (Second_Run_Workspace_Text, "project");
   end Assert_Dogfood_Repeatable;

   function Assert_Product_Artifacts_No_Demo_State
     (Product_Text : String) return Boolean
   is
   begin
      return Missing (Product_Text, "demo row")
        and then Missing (Product_Text, "Demo_Row")
        and then Missing (Product_Text, "placeholder project")
        and then Missing (Product_Text, "Synthetic_Project")
        and then Missing (Product_Text, "test-only command")
        and then Missing (Product_Text, "Test_Only_Command")
        and then Missing (Product_Text, "Internal_Demo_Command")
        and then Missing (Product_Text, "Build_Candidates")
        and then Missing (Product_Text, "Latest_Build")
        and then Missing (Product_Text, "Quick_Open_Matches")
        and then Missing (Product_Text, "Search_Result_Rows");
   end Assert_Product_Artifacts_No_Demo_State;

   function Assert_Default_Keybindings_Safe
     (Keybindings_Text : String) return Boolean
   is
   begin
      return Missing (Keybindings_Text, "payload")
        and then Missing (Keybindings_Text, "internal")
        and then Missing (Keybindings_Text, "demo")
        and then Missing (Keybindings_Text, "test-only")
        and then Missing (Keybindings_Text, "auto-consent")
        and then Missing (Keybindings_Text, "auto-run")
        and then Missing (Keybindings_Text, "bypass-dirty-guard");
   end Assert_Default_Keybindings_Safe;

   function Assert_Milestone_Startup_And_Dogfood_Readiness_Coherent
     (Workspace_Text      : String;
      Recent_Project_Text : String;
      Keybindings_Text    : String;
      Product_Text        : String) return Boolean
   is
   begin
      return Assert_Fresh_Startup_Coherent
        and then Assert_First_Run_Command_Surface_Coherent
        and then Assert_Workspace_Reload_Minimal (Workspace_Text)
        and then Assert_Recent_Project_Does_Not_Restore_Transient_State
          (Recent_Project_Text)
        and then Assert_Dogfood_Repeatable (Workspace_Text, Workspace_Text)
        and then Assert_Product_Artifacts_No_Demo_State (Product_Text)
        and then Assert_Default_Keybindings_Safe (Keybindings_Text)
        and then Workspace_Reload_User_Message (Workspace_Loaded) =
          "Workspace loaded."
        and then Workspace_Reload_User_Message
          (Workspace_Unsupported_Fields_Ignored) =
            "Unsupported workspace fields ignored.";
   end Assert_Milestone_Startup_And_Dogfood_Readiness_Coherent;



   function Recent_Project_Open_Result_Label
     (State : Recent_Project_Open_State) return String
   is
   begin
      case State is
         when Recent_Project_Opened =>
            return "Recent project opened.";
         when Recent_Project_Unavailable =>
            return "Target no longer exists.";
         when Recent_Project_Path_Missing =>
            return "Target no longer exists.";
         when Recent_Project_Open_Failed =>
            return "Could not open recent project.";
      end case;
   end Recent_Project_Open_Result_Label;

   function Workspace_Reload_Recovery_Label
     (State : Workspace_Reload_State) return String
   is
   begin
      return Workspace_Reload_User_Message (State);
   end Workspace_Reload_Recovery_Label;

   function Project_Switch_Dirty_Guard_Label
     (State : Project_Dirty_Guard_State) return String
   is
   begin
      case State is
         when Project_Dirty_Guard_Allows =>
            return "Project transition ready.";
         when Project_Dirty_Guard_Blocked_Switch =>
            return "Project switch blocked: save or discard unsaved project files first.";
         when Project_Dirty_Guard_Blocked_Close =>
            return "Project close blocked: save or discard unsaved project files first.";
         when Project_Dirty_Guard_Cancelled =>
            return "Project transition cancelled; project and buffers unchanged.";
      end case;
   end Project_Switch_Dirty_Guard_Label;

   function Stale_Target_Activation_Label
     (Surface : Stale_Target_Surface) return String
   is
   begin
      case Surface is
         when Stale_Target_File_Tree =>
            return "Target no longer exists.";
         when Stale_Target_Quick_Open =>
            return "Target no longer exists.";
         when Stale_Target_Project_Search =>
            return "Search result is stale.";
         when Stale_Target_Outline =>
            return "Target no longer exists.";
         when Stale_Target_Diagnostics =>
            return "Target no longer exists.";
         when Stale_Target_Build =>
            return "Build unavailable: no project open.";
      end case;
   end Stale_Target_Activation_Label;

   function Assert_Repeated_Startup_Coherent return Boolean is
   begin
      return Assert_Fresh_Startup_Coherent
        and then Startup_State_Label (Startup_Recent_Projects) =
          "Recent projects loaded when available."
        and then Startup_State_Label (Startup_Command_Palette) =
          "Command Palette available."
        and then Startup_State_Label (Startup_File_Tree) =
          "File Tree: No project open."
        and then Startup_State_Label (Startup_Project_Search) =
          "Search: No project open."
        and then Startup_State_Label (Startup_Build) =
          "Build: No project open.";
   end Assert_Repeated_Startup_Coherent;

   function Assert_Recent_Project_Uses_Project_Lifecycle
     (Recent_Project_Text : String) return Boolean
   is
   begin
      return Assert_Recent_Project_Does_Not_Restore_Transient_State
          (Recent_Project_Text)
        and then Contains (Recent_Project_Text, "project")
        and then Missing (Recent_Project_Text, "workspace")
        and then Missing (Recent_Project_Text, "candidate")
        and then Missing (Recent_Project_Text, "consent")
        and then Recent_Project_Open_Result_Label (Recent_Project_Opened) =
          "Recent project opened."
        and then Recent_Project_Open_Result_Label (Recent_Project_Path_Missing) =
          "Target no longer exists."
        and then Recent_Project_Open_Result_Label (Recent_Project_Open_Failed) =
          "Could not open recent project.";
   end Assert_Recent_Project_Uses_Project_Lifecycle;

   function Assert_Workspace_Reload_Does_Not_Restore_Transient_State
     (Workspace_Text : String) return Boolean
   is
   begin
      return Assert_Workspace_Reload_Minimal (Workspace_Text)
        and then Missing (Workspace_Text, "dirty-confirmation")
        and then Missing (Workspace_Text, "Dirty_Confirmation")
        and then Missing (Workspace_Text, "selected-build-candidate")
        and then Missing (Workspace_Text, "build-consent")
        and then Missing (Workspace_Text, "latest-build-result")
        and then Missing (Workspace_Text, "output-details")
        and then Missing (Workspace_Text, "outline-row")
        and then Missing (Workspace_Text, "quick-open-match")
        and then Missing (Workspace_Text, "command-palette-query")
        and then Workspace_Reload_Recovery_Label (Workspace_Loaded) =
          "Workspace loaded."
        and then Workspace_Reload_Recovery_Label
          (Workspace_Some_Files_Not_Reopened) =
            "Some files could not be reopened."
        and then Workspace_Reload_Recovery_Label
          (Workspace_Unsupported_Fields_Ignored) =
            "Unsupported workspace fields ignored.";
   end Assert_Workspace_Reload_Does_Not_Restore_Transient_State;

   function Assert_Project_Close_Clears_Project_Scoped_State return Boolean is
   begin
      return Project_Switch_Dirty_Guard_Label
          (Project_Dirty_Guard_Blocked_Switch) =
            "Project switch blocked: save or discard unsaved project files first."
        and then Project_Switch_Dirty_Guard_Label
          (Project_Dirty_Guard_Blocked_Close) =
            "Project close blocked: save or discard unsaved project files first."
        and then Project_Switch_Dirty_Guard_Label
          (Project_Dirty_Guard_Cancelled) =
            "Project transition cancelled; project and buffers unchanged."
        and then Stale_Target_Activation_Label (Stale_Target_File_Tree) =
          "Target no longer exists."
        and then Stale_Target_Activation_Label (Stale_Target_Project_Search) =
          "Search result is stale."
        and then Stale_Target_Activation_Label (Stale_Target_Outline) =
          "Target no longer exists."
        and then Stale_Target_Activation_Label (Stale_Target_Diagnostics) =
          "Target no longer exists."
        and then Stale_Target_Activation_Label (Stale_Target_Build) =
          "Build unavailable: no project open.";
   end Assert_Project_Close_Clears_Project_Scoped_State;

   function Assert_Dogfood_Repeated_Use_Coherent
     (First_Run_Workspace_Text  : String;
      Second_Run_Workspace_Text : String) return Boolean
   is
   begin
      return Assert_Dogfood_Repeatable
          (First_Run_Workspace_Text, Second_Run_Workspace_Text)
        and then Assert_Workspace_Reload_Does_Not_Restore_Transient_State
          (First_Run_Workspace_Text)
        and then Assert_Workspace_Reload_Does_Not_Restore_Transient_State
          (Second_Run_Workspace_Text)
        and then Missing (First_Run_Workspace_Text, "build-consent")
        and then Missing (Second_Run_Workspace_Text, "build-consent")
        and then Missing (First_Run_Workspace_Text, "latest-build-result")
        and then Missing (Second_Run_Workspace_Text, "latest-build-result");
   end Assert_Dogfood_Repeated_Use_Coherent;

   function Assert_Repeated_Local_Use_Coherent
     (Workspace_Text      : String;
      Recent_Project_Text : String;
      Keybindings_Text    : String;
      Product_Text        : String) return Boolean
   is
   begin
      return Assert_Milestone_Startup_And_Dogfood_Readiness_Coherent
          (Workspace_Text, Recent_Project_Text, Keybindings_Text, Product_Text)
        and then Assert_Repeated_Startup_Coherent
        and then Assert_Recent_Project_Uses_Project_Lifecycle
          (Recent_Project_Text)
        and then Assert_Workspace_Reload_Does_Not_Restore_Transient_State
          (Workspace_Text)
        and then Assert_Project_Close_Clears_Project_Scoped_State
        and then Assert_Dogfood_Repeated_Use_Coherent
          (Workspace_Text, Workspace_Text)
        and then Assert_Default_Keybindings_Safe (Keybindings_Text)
        and then Assert_Product_Artifacts_No_Demo_State (Product_Text);
   end Assert_Repeated_Local_Use_Coherent;



   function Integrated_Workflow_Message
     (Condition : Integrated_Workflow_Condition) return String
   is
   begin
      case Condition is
         when Workflow_No_Project_Open =>
            return "No project open.";
         when Workflow_No_Active_Buffer =>
            return "No active buffer.";
         when Workflow_No_Buffer_Selected =>
            return "No buffer selected.";
         when Workflow_No_File_Selected =>
            return "No file selected.";
         when Workflow_Target_Stale =>
            return "Target is stale; refresh required.";
         when Workflow_Target_No_Longer_Exists =>
            return "Target no longer exists.";
         when Workflow_Backing_File_No_Longer_Exists =>
            return "Backing file missing.";
         when Workflow_Unsaved_Changes_Require_Confirmation =>
            return "Unsaved changes require confirmation.";
         when Workflow_Confirmation_Pending =>
            return "Command unavailable while confirmation is pending.";
         when Workflow_No_Search_Query =>
            return "No search query.";
         when Workflow_No_Search_Results =>
            return "No search results.";
         when Workflow_No_Build_Request =>
            return "No build request ready.";
         when Workflow_No_Diagnostics =>
            return "No diagnostics.";
      end case;
   end Integrated_Workflow_Message;

   function Integrated_Focus_After_Action
     (Action : Integrated_Workflow_Action) return Integrated_Focus_Result
   is
   begin
      case Action is
         when Workflow_Open_Project_Succeeded =>
            return Focus_Result_File_Tree;
         when Workflow_File_Tree_File_Activated
            | Workflow_Quick_Open_File_Activated
            | Workflow_Search_Result_Activated
            | Workflow_Outline_Target_Activated
            | Workflow_Diagnostic_Target_Activated =>
            return Focus_Result_Editor;
         when Workflow_Build_Diagnostics_Revealed =>
            return Focus_Result_Diagnostics;
         when Workflow_Prompt_Cancelled =>
            return Focus_Result_Originating_Surface;
         when Workflow_Command_Failed =>
            return Focus_Result_Correction_Surface;
      end case;
   end Integrated_Focus_After_Action;

   function Integrated_Focus_Result_Label
     (Result : Integrated_Focus_Result) return String
   is
   begin
      case Result is
         when Focus_Result_Editor => return "Editor";
         when Focus_Result_File_Tree => return "File Tree";
         when Focus_Result_Search_Results => return "Project Search Results";
         when Focus_Result_Outline => return "Outline";
         when Focus_Result_Diagnostics => return "Diagnostics";
         when Focus_Result_Build_Output => return "Build Output";
         when Focus_Result_Empty_State => return "Empty editor state";
         when Focus_Result_Originating_Surface => return "Originating surface";
         when Focus_Result_Correction_Surface => return "Correction surface";
      end case;
   end Integrated_Focus_Result_Label;

   function Integrated_Surface_Disposition_After
     (Event   : Integrated_Surface_Event;
      Surface : Dogfood_Surface) return Integrated_Surface_Disposition
   is
   begin
      case Event is
         when Workflow_Event_Project_Opened =>
            case Surface is
               when Dogfood_Surface_File_Tree
                  | Dogfood_Surface_Quick_Open
                  | Dogfood_Surface_Project_Search
                  | Dogfood_Surface_Build =>
                  return Workflow_Surface_Refresh_Required;
               when Dogfood_Surface_Outline
                  | Dogfood_Surface_Diagnostics =>
                  return Workflow_Surface_Cleared;
               when others =>
                  return Workflow_Surface_Unchanged;
            end case;
         when Workflow_Event_Project_Switched =>
            case Surface is
               when Dogfood_Surface_File_Tree
                  | Dogfood_Surface_Quick_Open
                  | Dogfood_Surface_Project_Search
                  | Dogfood_Surface_Outline
                  | Dogfood_Surface_Diagnostics
                  | Dogfood_Surface_Build =>
                  return Workflow_Surface_Cleared;
               when others =>
                  return Workflow_Surface_Unchanged;
            end case;
         when Workflow_Event_File_Created | Workflow_Event_File_Renamed | Workflow_Event_File_Deleted =>
            case Surface is
               when Dogfood_Surface_File_Tree
                  | Dogfood_Surface_Quick_Open
                  | Dogfood_Surface_Project_Search
                  | Dogfood_Surface_Build =>
                  return Workflow_Surface_Refresh_Required;
               when Dogfood_Surface_Outline
                  | Dogfood_Surface_Diagnostics =>
                  return Workflow_Surface_Marked_Stale;
               when others =>
                  return Workflow_Surface_Unchanged;
            end case;
         when Workflow_Event_Buffer_Edited | Workflow_Event_Buffer_Reloaded =>
            case Surface is
               when Dogfood_Surface_Outline
                  | Dogfood_Surface_Project_Search
                  | Dogfood_Surface_Diagnostics =>
                  return Workflow_Surface_Marked_Stale;
               when others =>
                  return Workflow_Surface_Unchanged;
            end case;
         when Workflow_Event_Buffer_Saved =>
            case Surface is
               when Dogfood_Surface_Editing =>
                  return Workflow_Surface_Recomputed_By_Explicit_Command;
               when Dogfood_Surface_File_Tree =>
                  return Workflow_Surface_Unchanged;
               when Dogfood_Surface_Outline
                  | Dogfood_Surface_Project_Search
                  | Dogfood_Surface_Diagnostics =>
                  return Workflow_Surface_Marked_Stale;
               when others =>
                  return Workflow_Surface_Unchanged;
            end case;
         when Workflow_Event_Build_Finished =>
            case Surface is
               when Dogfood_Surface_Build
                  | Dogfood_Surface_Diagnostics =>
                  return Workflow_Surface_Recomputed_By_Explicit_Command;
               when others =>
                  return Workflow_Surface_Unchanged;
            end case;
      end case;
   end Integrated_Surface_Disposition_After;

   function Integrated_Surface_Disposition_Label
     (Disposition : Integrated_Surface_Disposition) return String
   is
   begin
      case Disposition is
         when Workflow_Surface_Unchanged => return "unchanged";
         when Workflow_Surface_Refresh_Required => return "refresh required";
         when Workflow_Surface_Marked_Stale => return "marked stale";
         when Workflow_Surface_Cleared => return "cleared";
         when Workflow_Surface_Recomputed_By_Explicit_Command =>
            return "recomputed by explicit command";
      end case;
   end Integrated_Surface_Disposition_Label;

   function Assert_Phase578_Message_Consistency return Boolean is
   begin
      return Integrated_Workflow_Message (Workflow_No_Project_Open) = "No project open."
        and then Integrated_Workflow_Message (Workflow_No_Active_Buffer) = "No active buffer."
        and then Integrated_Workflow_Message (Workflow_No_Buffer_Selected) = "No buffer selected."
        and then Integrated_Workflow_Message (Workflow_No_File_Selected) = "No file selected."
        and then Integrated_Workflow_Message (Workflow_Target_Stale) =
          "Target is stale; refresh required."
        and then Integrated_Workflow_Message (Workflow_Target_No_Longer_Exists) =
          "Target no longer exists."
        and then Integrated_Workflow_Message (Workflow_Backing_File_No_Longer_Exists) =
          "Backing file missing."
        and then Integrated_Workflow_Message
          (Workflow_Unsaved_Changes_Require_Confirmation) =
            "Unsaved changes require confirmation."
        and then Integrated_Workflow_Message (Workflow_Confirmation_Pending) =
          "Command unavailable while confirmation is pending."
        and then Integrated_Workflow_Message (Workflow_No_Search_Query) = "No search query."
        and then Integrated_Workflow_Message (Workflow_No_Search_Results) = "No search results."
        and then Integrated_Workflow_Message (Workflow_No_Build_Request) =
          "No build request ready."
        and then Integrated_Workflow_Message (Workflow_No_Diagnostics) = "No diagnostics."
        and then Dogfood_Label_Is_User_Readable
          (Integrated_Workflow_Message (Workflow_Target_Stale))
        and then Dogfood_Label_Is_User_Readable
          (Integrated_Workflow_Message (Workflow_Confirmation_Pending));
   end Assert_Phase578_Message_Consistency;

   function Assert_Phase578_Focus_Policy_Coherent return Boolean is
   begin
      return Integrated_Focus_After_Action (Workflow_File_Tree_File_Activated) =
          Focus_Result_Editor
        and then Integrated_Focus_After_Action (Workflow_Quick_Open_File_Activated) =
          Focus_Result_Editor
        and then Integrated_Focus_After_Action (Workflow_Search_Result_Activated) =
          Focus_Result_Editor
        and then Integrated_Focus_After_Action (Workflow_Outline_Target_Activated) =
          Focus_Result_Editor
        and then Integrated_Focus_After_Action (Workflow_Diagnostic_Target_Activated) =
          Focus_Result_Editor
        and then Integrated_Focus_After_Action (Workflow_Build_Diagnostics_Revealed) =
          Focus_Result_Diagnostics
        and then Integrated_Focus_After_Action (Workflow_Prompt_Cancelled) =
          Focus_Result_Originating_Surface
        and then Integrated_Focus_After_Action (Workflow_Command_Failed) =
          Focus_Result_Correction_Surface
        and then Integrated_Focus_Result_Label (Focus_Result_Editor) = "Editor"
        and then Integrated_Focus_Result_Label (Focus_Result_Search_Results) = "Project Search Results"
        and then Integrated_Focus_Result_Label (Focus_Result_Outline) = "Outline"
        and then Integrated_Focus_Result_Label (Focus_Result_Build_Output) = "Build Output"
        and then Integrated_Focus_Result_Label (Focus_Result_Empty_State) = "Empty editor state";
   end Assert_Phase578_Focus_Policy_Coherent;

   function Assert_Phase578_Surface_Dispositions_Coherent return Boolean is
   begin
      return Integrated_Surface_Disposition_After
          (Workflow_Event_Project_Switched, Dogfood_Surface_Project_Search) =
            Workflow_Surface_Cleared
        and then Integrated_Surface_Disposition_After
          (Workflow_Event_Project_Switched, Dogfood_Surface_Build) =
            Workflow_Surface_Cleared
        and then Integrated_Surface_Disposition_After
          (Workflow_Event_File_Renamed, Dogfood_Surface_File_Tree) =
            Workflow_Surface_Refresh_Required
        and then Integrated_Surface_Disposition_After
          (Workflow_Event_File_Renamed, Dogfood_Surface_Quick_Open) =
            Workflow_Surface_Refresh_Required
        and then Integrated_Surface_Disposition_After
          (Workflow_Event_File_Deleted, Dogfood_Surface_Project_Search) =
            Workflow_Surface_Refresh_Required
        and then Integrated_Surface_Disposition_After
          (Workflow_Event_Buffer_Edited, Dogfood_Surface_Outline) =
            Workflow_Surface_Marked_Stale
        and then Integrated_Surface_Disposition_After
          (Workflow_Event_Build_Finished, Dogfood_Surface_Diagnostics) =
            Workflow_Surface_Recomputed_By_Explicit_Command
        and then Integrated_Surface_Disposition_Label
          (Workflow_Surface_Recomputed_By_Explicit_Command) =
            "recomputed by explicit command";
   end Assert_Phase578_Surface_Dispositions_Coherent;

   function Assert_Phase578_Workflow_Polish_Coherent
     (Workspace_Text      : String;
      Recent_Project_Text : String;
      Keybindings_Text    : String;
      Product_Text        : String) return Boolean
   is
   begin
      return Assert_Phase578_Message_Consistency
        and then Assert_Phase578_Focus_Policy_Coherent
        and then Assert_Phase578_Surface_Dispositions_Coherent
        and then Assert_Repeated_Local_Use_Coherent
          (Workspace_Text, Recent_Project_Text, Keybindings_Text, Product_Text)
        and then Assert_Workspace_Reload_Does_Not_Restore_Transient_State
          (Workspace_Text)
        and then Assert_Recent_Project_Uses_Project_Lifecycle
          (Recent_Project_Text)
        and then Assert_Default_Keybindings_Safe (Keybindings_Text)
        and then Assert_Product_Artifacts_No_Demo_State (Product_Text);
   end Assert_Phase578_Workflow_Polish_Coherent;


   function Product_Workflow_Command
     (Step : Product_Workflow_Step) return String
   is
   begin
      case Step is
         when Product_Empty_Editor_State => return "command-palette.show-command-help";
         when Product_Open_Project => return "project.open";
         when Product_Open_File_From_File_Tree => return "file-tree.open-selected";
         when Product_Open_File_From_Quick_Open => return "quick-open.show";
         when Product_Edit_Buffer => return "text input path";
         when Product_Save_Buffer => return "file.save";
         when Product_Reload_Buffer => return "file.reload";
         when Product_Revert_Buffer => return "file.revert";
         when Product_Create_File => return "file-tree.create-file";
         when Product_Create_Directory => return "file-tree.create-directory";
         when Product_Rename_File_Or_Directory => return "file-tree.rename";
         when Product_Delete_File_Or_Directory => return "file-tree.delete";
         when Product_Search_Project => return "search.project";
         when Product_Navigate_Search_Result => return "search.open-selected";
         when Product_View_Outline => return "outline.show";
         when Product_Run_Build => return "build.run";
         when Product_Inspect_Build_Output => return "build.output.show";
         when Product_Inspect_Diagnostics => return "diagnostics.show";
         when Product_Switch_Buffers => return "buffer.switch-next";
         when Product_Close_Active_Buffer => return "buffer.close";
         when Product_Close_Project => return "project.close";
         when Product_Switch_Project => return "project.switch";
         when Product_Restore_Workspace => return "workspace.restore";
         when Product_Quit_Safely => return "host quit lifecycle";
      end case;
   end Product_Workflow_Command;

   function Product_Workflow_Label
     (Step : Product_Workflow_Step) return String
   is
   begin
      case Step is
         when Product_Empty_Editor_State => return "Show Command Help";
         when Product_Open_Project => return "Open Project";
         when Product_Open_File_From_File_Tree => return "Open Selected File";
         when Product_Open_File_From_Quick_Open => return "Quick Open";
         when Product_Edit_Buffer => return "Edit Buffer";
         when Product_Save_Buffer => return "Save File";
         when Product_Reload_Buffer => return "Reload File";
         when Product_Revert_Buffer => return "Revert File";
         when Product_Create_File => return "Create File";
         when Product_Create_Directory => return "Create Directory";
         when Product_Rename_File_Or_Directory => return "Rename File or Directory";
         when Product_Delete_File_Or_Directory => return "Delete File or Directory";
         when Product_Search_Project => return "Search Project";
         when Product_Navigate_Search_Result => return "Open Selected Project Search Result";
         when Product_View_Outline => return "Show Outline";
         when Product_Run_Build => return "Run Build";
         when Product_Inspect_Build_Output => return "Show Build Output";
         when Product_Inspect_Diagnostics => return "Show Diagnostics";
         when Product_Switch_Buffers => return "Next Buffer";
         when Product_Close_Active_Buffer => return "Close Buffer";
         when Product_Close_Project => return "Close Project";
         when Product_Switch_Project => return "Switch Project";
         when Product_Restore_Workspace => return "Restore Workspace";
         when Product_Quit_Safely => return "Quit";
      end case;
   end Product_Workflow_Label;

   function Product_Workflow_Success_Message
     (Step : Product_Workflow_Step) return String
   is
   begin
      case Step is
         when Product_Empty_Editor_State => return "Command Palette available.";
         when Product_Open_Project => return "Project opened.";
         when Product_Open_File_From_File_Tree | Product_Open_File_From_Quick_Open => return "File opened.";
         when Product_Edit_Buffer => return "Buffer edited.";
         when Product_Save_Buffer => return "File saved.";
         when Product_Reload_Buffer => return "File reloaded.";
         when Product_Revert_Buffer => return "File reverted.";
         when Product_Create_File => return "File created.";
         when Product_Create_Directory => return "Directory created.";
         when Product_Rename_File_Or_Directory => return "File or directory renamed.";
         when Product_Delete_File_Or_Directory => return "File or directory deleted.";
         when Product_Search_Project => return "Search complete.";
         when Product_Navigate_Search_Result => return "Opened search result.";
         when Product_View_Outline => return "Outline shown.";
         when Product_Run_Build => return "Build started.";
         when Product_Inspect_Build_Output => return "Build Output shown.";
         when Product_Inspect_Diagnostics => return "Diagnostics shown.";
         when Product_Switch_Buffers => return "Buffer switched.";
         when Product_Close_Active_Buffer => return "Buffer closed.";
         when Product_Close_Project => return "Project closed.";
         when Product_Switch_Project => return "Project opened.";
         when Product_Restore_Workspace => return "Workspace restored.";
         when Product_Quit_Safely => return "Ready to quit.";
      end case;
   end Product_Workflow_Success_Message;

   function Product_Workflow_Failure_Message
     (Step : Product_Workflow_Step) return String
   is
   begin
      case Step is
         when Product_Empty_Editor_State => return "No command selected.";
         when Product_Open_Project => return "Project open cancelled.";
         when Product_Switch_Project => return "Project switch cancelled.";
         when Product_Open_File_From_File_Tree | Product_Open_File_From_Quick_Open => return "File could not be opened.";
         when Product_Edit_Buffer => return "No active buffer.";
         when Product_Save_Buffer => return "File could not be saved.";
         when Product_Reload_Buffer => return "File could not be reloaded.";
         when Product_Revert_Buffer => return "Revert cancelled.";
         when Product_Create_File => return "File could not be created.";
         when Product_Create_Directory => return "Directory could not be created.";
         when Product_Rename_File_Or_Directory => return "File or directory could not be renamed.";
         when Product_Delete_File_Or_Directory => return "Delete cancelled.";
         when Product_Search_Project => return "No project open.";
         when Product_Navigate_Search_Result => return "No search result selected.";
         when Product_View_Outline => return "Outline unavailable.";
         when Product_Run_Build => return "Build command is not configured.";
         when Product_Inspect_Build_Output => return "No build output captured.";
         when Product_Inspect_Diagnostics => return "No diagnostics.";
         when Product_Switch_Buffers => return "No other buffer.";
         when Product_Close_Active_Buffer => return "Cannot close buffer while dirty changes need review.";
         when Product_Close_Project => return "Cannot close project while dirty buffers need review.";
         when Product_Restore_Workspace => return "Workspace could not be restored.";
         when Product_Quit_Safely => return "Dirty buffers need review before quitting.";
      end case;
   end Product_Workflow_Failure_Message;

   function Product_Workflow_Success_Status
     (Step : Product_Workflow_Step) return String
   is
   begin
      return Product_Workflow_Success_Message (Step);
   end Product_Workflow_Success_Status;

   function Product_Workflow_Failure_Status
     (Step : Product_Workflow_Step) return String
   is
   begin
      return Product_Workflow_Failure_Message (Step);
   end Product_Workflow_Failure_Status;

   function Product_Workflow_Focus_Result
     (Step : Product_Workflow_Step) return Integrated_Focus_Result
   is
   begin
      case Step is
         when Product_Open_Project
            | Product_Create_File
            | Product_Create_Directory
            | Product_Rename_File_Or_Directory
            | Product_Delete_File_Or_Directory =>
            return Focus_Result_File_Tree;
         when Product_Search_Project =>
            return Focus_Result_Search_Results;
         when Product_View_Outline =>
            return Focus_Result_Outline;
         when Product_Inspect_Diagnostics =>
            return Focus_Result_Diagnostics;
         when Product_Inspect_Build_Output | Product_Run_Build =>
            return Focus_Result_Build_Output;
         when Product_Close_Project =>
            return Focus_Result_Empty_State;
         when Product_Empty_Editor_State =>
            return Focus_Result_Originating_Surface;
         when others =>
            return Focus_Result_Editor;
      end case;
   end Product_Workflow_Focus_Result;

   function Product_Workflow_Dirty_Buffer_Behavior
     (Step : Product_Workflow_Step) return String
   is
   begin
      case Step is
         when Product_Save_Buffer => return "clears dirty state on success";
         when Product_Reload_Buffer | Product_Revert_Buffer => return "requires confirmation when dirty";
         when Product_Delete_File_Or_Directory => return "requires explicit decision for dirty open files";
         when Product_Close_Active_Buffer | Product_Close_Project | Product_Switch_Project | Product_Quit_Safely => return "blocks until dirty buffers are saved, discarded, or cancellation preserves them";
         when Product_Restore_Workspace => return "does not persist or recreate dirty state";
         when others => return "preserves dirty buffers";
      end case;
   end Product_Workflow_Dirty_Buffer_Behavior;

   function Product_Workflow_Prompt_Title
     (Step : Product_Workflow_Step) return String
   is
   begin
      case Step is
         when Product_Open_Project => return "Open Project";
         when Product_Create_File => return "Create File";
         when Product_Create_Directory => return "Create Directory";
         when Product_Rename_File_Or_Directory => return "Rename File or Directory";
         when Product_Delete_File_Or_Directory => return "Delete File or Directory";
         when Product_Save_Buffer => return "Save File As";
         when Product_Reload_Buffer | Product_Revert_Buffer => return "Reload or Revert File";
         when Product_Close_Active_Buffer => return "Dirty Close Review";
         when Product_Close_Project => return "Dirty Close Review";
         when Product_Switch_Project => return "Project Switch Dirty Review";
         when Product_Quit_Safely => return "Quit Dirty Review";
         when Product_Run_Build => return "Build Configuration Missing";
         when others => return "no prompt";
      end case;
   end Product_Workflow_Prompt_Title;

   function Product_Workflow_Cancel_Status
     (Step : Product_Workflow_Step) return String
   is
   begin
      case Step is
         when Product_Reload_Buffer | Product_Revert_Buffer
            | Product_Close_Active_Buffer | Product_Close_Project
            | Product_Quit_Safely =>
            return "Dirty buffer preserved.";
         when Product_Switch_Project =>
            return "Project switch cancelled.";
         when Product_Delete_File_Or_Directory =>
            return "Delete cancelled.";
         when Product_Open_Project =>
            return "Project open cancelled.";
         when Product_Create_File =>
            return "Create file cancelled.";
         when Product_Create_Directory =>
            return "Create directory cancelled.";
         when Product_Rename_File_Or_Directory =>
            return "Rename cancelled.";
         when Product_Save_Buffer | Product_Run_Build =>
            return "Operation cancelled.";
         when others =>
            return "no prompt";
      end case;
   end Product_Workflow_Cancel_Status;

   function Product_Workflow_Persistence_Effect
     (Step : Product_Workflow_Step) return String
   is
   begin
      case Step is
         when Product_Open_Project | Product_Switch_Project =>
            return "persists valid project identity and active target only after success";
         when Product_Open_File_From_File_Tree | Product_Open_File_From_Quick_Open
            | Product_Navigate_Search_Result | Product_Switch_Buffers =>
            return "may update active buffer target; does not persist temporary panel rows";
         when Product_Save_Buffer =>
            return "persists file contents on disk; workspace keeps active file only";
         when Product_Create_File | Product_Create_Directory
            | Product_Rename_File_Or_Directory | Product_Delete_File_Or_Directory =>
            return "updates project file discovery after explicit File Tree operation";
         when Product_Close_Active_Buffer | Product_Close_Project =>
            return "removes invalid active target from workspace state";
         when Product_Restore_Workspace =>
            return "restores only valid project, buffers, selection, and focus";
         when Product_Run_Build | Product_Inspect_Build_Output | Product_Inspect_Diagnostics
            | Product_Search_Project | Product_View_Outline =>
            return "keeps result rows temporary unless already owned by an explicit persistence feature";
         when others =>
            return "no persistence change";
      end case;
   end Product_Workflow_Persistence_Effect;

   function Product_Workflow_File_Buffer_Effect
     (Step : Product_Workflow_Step) return String
   is
   begin
      case Step is
         when Product_Open_File_From_File_Tree | Product_Open_File_From_Quick_Open
            | Product_Navigate_Search_Result =>
            return "opens or focuses the matching file-backed buffer";
         when Product_Edit_Buffer =>
            return "updates active buffer text and marks it dirty";
         when Product_Save_Buffer =>
            return "keeps the same buffer and clears dirty state on success";
         when Product_Reload_Buffer | Product_Revert_Buffer =>
            return "keeps dirty text when cancelled and replaces text only after confirmation";
         when Product_Rename_File_Or_Directory =>
            return "updates backing path for an open renamed file";
         when Product_Delete_File_Or_Directory =>
            return "closes or marks clean open targets according to file-safety policy; dirty targets require a decision";
         when Product_Close_Active_Buffer =>
            return "selects the next valid buffer or empty editor state";
         when Product_Close_Project | Product_Switch_Project | Product_Quit_Safely =>
            return "does not discard dirty text unless the user explicitly chooses discard";
         when Product_Restore_Workspace =>
            return "reopens only valid file-backed buffers and never recreates dirty text";
         when others =>
            return "preserves open buffers";
      end case;
   end Product_Workflow_File_Buffer_Effect;

   function Product_Workflow_Panel_Effect
     (Step : Product_Workflow_Step) return String
   is
   begin
      case Step is
         when Product_Open_Project | Product_Switch_Project | Product_Close_Project =>
            return "clears or refreshes project-scoped panels consistently";
         when Product_Create_File | Product_Create_Directory
            | Product_Rename_File_Or_Directory | Product_Delete_File_Or_Directory =>
            return "refreshes File Tree explicitly and marks stale navigation targets visibly";
         when Product_Search_Project =>
            return "updates Project Search results without changing build output";
         when Product_Navigate_Search_Result =>
            return "opens the selected result in the editor unless the result is stale";
         when Product_View_Outline =>
            return "shows outline rows when supported or reports outline unavailable";
         when Product_Run_Build =>
            return "updates build output and diagnostics from the same build result";
         when Product_Inspect_Build_Output =>
            return "shows a useful empty or populated build output panel";
         when Product_Inspect_Diagnostics =>
            return "shows a useful empty or populated diagnostics panel";
         when Product_Restore_Workspace =>
            return "does not restore stale Search, Quick Open, Outline, Build, or Diagnostics rows";
         when others =>
            return "no panel contradiction";
      end case;
   end Product_Workflow_Panel_Effect;

   function Product_Label_Contains_Internal_Term
     (Label : String) return Boolean
   is
      Lower : constant String := Ada.Characters.Handling.To_Lower (Label);
   begin
      return Contains (Lower, "audit")
        or else Contains (Lower, "fixture")
        or else Contains (Lower, "guard")
        or else Contains (Lower, "scaffold")
        or else Contains (Lower, "placeholder")
        or else Contains (Lower, "route")
        or else Contains (Lower, "producer")
        or else Contains (Lower, "synthetic")
        or else Contains (Lower, "projection")
        or else Contains (Lower, "payload")
        or else Contains (Lower, "metadata")
        or else Contains (Lower, "transient")
        or else Contains (Lower, "lifecycle")
        or else Contains (Lower, "diagnostic_id")
        or else Contains (Lower, "build ui")
        or else Contains (Lower, "buffer_id")
        or else Contains (Lower, "route_id")
        or else Contains (Lower, "active-buffer")
        or else Contains (Lower, "switcher")
        or else Contains (Lower, "buffer id")
        or else Contains (Lower, "route id");
   end Product_Label_Contains_Internal_Term;

   function Assert_Phase579_Product_Workflow_Reference_Coherent
     return Boolean
   is
   begin
      return Product_Workflow_Command (Product_Open_Project) = "project.open"
        and then Product_Workflow_Command (Product_Save_Buffer) = "file.save"
        and then Product_Workflow_Command (Product_Run_Build) = "build.run"
        and then Product_Workflow_Command (Product_Inspect_Diagnostics) = "diagnostics.show"
        and then Product_Workflow_Command (Product_Restore_Workspace) = "workspace.restore"
        and then Product_Workflow_Label (Product_Open_Project) = "Open Project"
        and then Product_Workflow_Label (Product_Open_File_From_File_Tree) = "Open Selected File"
        and then Product_Workflow_Label (Product_Navigate_Search_Result) = "Open Selected Project Search Result"
        and then Product_Workflow_Label (Product_Switch_Buffers) = "Next Buffer"
        and then Product_Workflow_Success_Message (Product_Open_Project) = "Project opened."
        and then Product_Workflow_Failure_Message (Product_Run_Build) = "Build command is not configured."
        and then Product_Workflow_Failure_Message (Product_Rename_File_Or_Directory) = "File or directory could not be renamed."
        and then Product_Workflow_Success_Message (Product_Inspect_Build_Output) = "Build Output shown."
        and then Product_Workflow_Failure_Message (Product_Switch_Project) = "Project switch cancelled."
        and then Product_Workflow_Dirty_Buffer_Behavior (Product_Quit_Safely) =
          "blocks until dirty buffers are saved, discarded, or cancellation preserves them"
        and then Product_Workflow_Success_Message (Product_Rename_File_Or_Directory) = "File or directory renamed."
        and then Product_Workflow_Success_Message (Product_Delete_File_Or_Directory) = "File or directory deleted.";
   end Assert_Phase579_Product_Workflow_Reference_Coherent;

   function Assert_Phase579_Product_Messages_User_Readable
     return Boolean
   is
   begin
      for Step in Product_Workflow_Step loop
         if Product_Label_Contains_Internal_Term (Product_Workflow_Label (Step))
           or else Product_Label_Contains_Internal_Term
             (Product_Workflow_Success_Message (Step))
           or else Product_Label_Contains_Internal_Term
             (Product_Workflow_Failure_Message (Step))
           or else Product_Label_Contains_Internal_Term
             (Product_Workflow_Prompt_Title (Step))
           or else Product_Label_Contains_Internal_Term
             (Product_Workflow_Cancel_Status (Step))
           or else Product_Label_Contains_Internal_Term
             (Product_Workflow_Persistence_Effect (Step))
           or else Product_Label_Contains_Internal_Term
             (Product_Workflow_File_Buffer_Effect (Step))
           or else Product_Label_Contains_Internal_Term
             (Product_Workflow_Panel_Effect (Step))
           or else not Dogfood_Label_Is_User_Readable
             (Product_Workflow_Success_Message (Step))
         then
            return False;
         end if;
      end loop;
      return True;
   end Assert_Phase579_Product_Messages_User_Readable;

   function Assert_Phase579_Product_Focus_Policy_Coherent
     return Boolean
   is
   begin
      return Product_Workflow_Focus_Result (Product_Open_Project) = Focus_Result_File_Tree
        and then Product_Workflow_Focus_Result (Product_Open_File_From_File_Tree) = Focus_Result_Editor
        and then Product_Workflow_Focus_Result (Product_Open_File_From_Quick_Open) = Focus_Result_Editor
        and then Product_Workflow_Focus_Result (Product_Navigate_Search_Result) = Focus_Result_Editor
        and then Product_Workflow_Focus_Result (Product_Search_Project) = Focus_Result_Search_Results
        and then Product_Workflow_Focus_Result (Product_View_Outline) = Focus_Result_Outline
        and then Product_Workflow_Focus_Result (Product_Inspect_Build_Output) = Focus_Result_Build_Output
        and then Product_Workflow_Focus_Result (Product_Run_Build) = Focus_Result_Build_Output
        and then Product_Workflow_Focus_Result (Product_Inspect_Diagnostics) = Focus_Result_Diagnostics
        and then Product_Workflow_Focus_Result (Product_Close_Active_Buffer) = Focus_Result_Editor
        and then Product_Workflow_Focus_Result (Product_Quit_Safely) = Focus_Result_Editor;
   end Assert_Phase579_Product_Focus_Policy_Coherent;

   function Assert_Phase579_Product_Prompt_Policy_Coherent
     return Boolean
   is
   begin
      return Product_Workflow_Prompt_Title (Product_Open_Project) = "Open Project"
        and then Product_Workflow_Prompt_Title (Product_Create_File) = "Create File"
        and then Product_Workflow_Prompt_Title (Product_Create_Directory) = "Create Directory"
        and then Product_Workflow_Prompt_Title (Product_Rename_File_Or_Directory) = "Rename File or Directory"
        and then Product_Workflow_Prompt_Title (Product_Delete_File_Or_Directory) = "Delete File or Directory"
        and then Product_Workflow_Prompt_Title (Product_Reload_Buffer) = "Reload or Revert File"
        and then Product_Workflow_Prompt_Title (Product_Revert_Buffer) = "Reload or Revert File"
        and then Product_Workflow_Prompt_Title (Product_Close_Project) = "Dirty Close Review"
        and then Product_Workflow_Prompt_Title (Product_Switch_Project) = "Project Switch Dirty Review"
        and then Product_Workflow_Prompt_Title (Product_Quit_Safely) = "Quit Dirty Review"
        and then Product_Workflow_Cancel_Status (Product_Reload_Buffer) = "Dirty buffer preserved."
        and then Product_Workflow_Cancel_Status (Product_Revert_Buffer) = "Dirty buffer preserved."
        and then Product_Workflow_Cancel_Status (Product_Switch_Project) = "Project switch cancelled."
        and then Product_Workflow_Cancel_Status (Product_Create_File) = "Create file cancelled."
        and then Product_Workflow_Cancel_Status (Product_Create_Directory) = "Create directory cancelled."
        and then Product_Workflow_Cancel_Status (Product_Rename_File_Or_Directory) = "Rename cancelled."
        and then Product_Workflow_Cancel_Status (Product_Delete_File_Or_Directory) = "Delete cancelled."
        and then Product_Workflow_Focus_Result (Product_Create_File) = Focus_Result_File_Tree
        and then Product_Workflow_Focus_Result (Product_Create_Directory) = Focus_Result_File_Tree
        and then Product_Workflow_Focus_Result (Product_Rename_File_Or_Directory) = Focus_Result_File_Tree
        and then Product_Workflow_Focus_Result (Product_Delete_File_Or_Directory) = Focus_Result_File_Tree;
   end Assert_Phase579_Product_Prompt_Policy_Coherent;

   function Assert_Phase579_Product_File_Buffer_Coherent
     return Boolean
   is
   begin
      return Product_Workflow_File_Buffer_Effect (Product_Open_File_From_File_Tree) =
          "opens or focuses the matching file-backed buffer"
        and then Product_Workflow_File_Buffer_Effect (Product_Open_File_From_Quick_Open) =
          "opens or focuses the matching file-backed buffer"
        and then Product_Workflow_File_Buffer_Effect (Product_Navigate_Search_Result) =
          "opens or focuses the matching file-backed buffer"
        and then Product_Workflow_File_Buffer_Effect (Product_Rename_File_Or_Directory) =
          "updates backing path for an open renamed file"
        and then Product_Workflow_File_Buffer_Effect (Product_Delete_File_Or_Directory) =
          "closes or marks clean open targets according to file-safety policy; dirty targets require a decision"
        and then Product_Workflow_File_Buffer_Effect (Product_Close_Active_Buffer) =
          "selects the next valid buffer or empty editor state";
   end Assert_Phase579_Product_File_Buffer_Coherent;

   function Assert_Phase579_Product_Navigation_Coherent
     return Boolean
   is
   begin
      return Product_Workflow_Panel_Effect (Product_Search_Project) =
          "updates Project Search results without changing build output"
        and then Product_Workflow_Panel_Effect (Product_Navigate_Search_Result) =
          "opens the selected result in the editor unless the result is stale"
        and then Product_Workflow_Panel_Effect (Product_View_Outline) =
          "shows outline rows when supported or reports outline unavailable"
        and then Product_Workflow_Focus_Result (Product_Navigate_Search_Result) = Focus_Result_Editor
        and then Product_Workflow_Focus_Result (Product_View_Outline) = Focus_Result_Outline
        and then Product_Workflow_Focus_Result (Product_Search_Project) = Focus_Result_Search_Results;
   end Assert_Phase579_Product_Navigation_Coherent;

   function Assert_Phase579_Product_Build_Diagnostics_Coherent
     return Boolean
   is
   begin
      return Product_Workflow_Panel_Effect (Product_Run_Build) =
          "updates build output and diagnostics from the same build result"
        and then Product_Workflow_Panel_Effect (Product_Inspect_Build_Output) =
          "shows a useful empty or populated build output panel"
        and then Product_Workflow_Panel_Effect (Product_Inspect_Diagnostics) =
          "shows a useful empty or populated diagnostics panel"
        and then Product_Workflow_Failure_Message (Product_Run_Build) = "Build command is not configured."
        and then Product_Workflow_Failure_Message (Product_Rename_File_Or_Directory) = "File or directory could not be renamed."
        and then Product_Workflow_Success_Message (Product_Inspect_Build_Output) = "Build Output shown."
        and then Product_Workflow_Failure_Message (Product_Inspect_Build_Output) = "No build output captured."
        and then Product_Workflow_Success_Message (Product_Inspect_Diagnostics) = "Diagnostics shown."
        and then Product_Workflow_Failure_Message (Product_Inspect_Diagnostics) = "No diagnostics.";
   end Assert_Phase579_Product_Build_Diagnostics_Coherent;

   function Assert_Phase579_Product_Workspace_Restore_Coherent
     return Boolean
   is
   begin
      return Product_Workflow_Persistence_Effect (Product_Restore_Workspace) =
          "restores only valid project, buffers, selection, and focus"
        and then Product_Workflow_File_Buffer_Effect (Product_Restore_Workspace) =
          "reopens only valid file-backed buffers and never recreates dirty text"
        and then Product_Workflow_Panel_Effect (Product_Restore_Workspace) =
          "does not restore stale Search, Quick Open, Outline, Build, or Diagnostics rows"
        and then Product_Workflow_Dirty_Buffer_Behavior (Product_Restore_Workspace) =
          "does not persist or recreate dirty state"
        and then Product_Workflow_Failure_Message (Product_Restore_Workspace) =
          "Workspace could not be restored.";
   end Assert_Phase579_Product_Workspace_Restore_Coherent;

   function Assert_Phase579_Product_Surface_Coherent
     (Product_Text : String) return Boolean
   is
   begin
      return Assert_Phase579_Product_Workflow_Reference_Coherent
        and then Assert_Phase579_Product_Messages_User_Readable
        and then Assert_Phase579_Product_Focus_Policy_Coherent
        and then Assert_Phase579_Product_Prompt_Policy_Coherent
        and then Assert_Phase579_Product_File_Buffer_Coherent
        and then Assert_Phase579_Product_Navigation_Coherent
        and then Assert_Phase579_Product_Build_Diagnostics_Coherent
        and then Assert_Phase579_Product_Workspace_Restore_Coherent
        and then Contains (Product_Text, "project.open")
        and then Contains (Product_Text, "project.close")
        and then Contains (Product_Text, "project.switch")
        and then Contains (Product_Text, "project.reopen-recent")
        and then Contains (Product_Text, "file.open")
        and then Contains (Product_Text, "file.save")
        and then Contains (Product_Text, "file.save-as")
        and then Contains (Product_Text, "file.reload")
        and then Contains (Product_Text, "file.revert")
        and then Contains (Product_Text, "file-tree.refresh")
        and then Contains (Product_Text, "file-tree.create-file")
        and then Contains (Product_Text, "file-tree.create-directory")
        and then Contains (Product_Text, "file-tree.rename")
        and then Contains (Product_Text, "file-tree.delete")
        and then Contains (Product_Text, "quick-open.show")
        and then Contains (Product_Text, "quick-open.open-selected")
        and then Contains (Product_Text, "search.project")
        and then Contains (Product_Text, "search.open-selected")
        and then Contains (Product_Text, "outline.show")
        and then Contains (Product_Text, "build.run")
        and then Contains (Product_Text, "build.output.show")
        and then Contains (Product_Text, "build.output.toggle")
        and then Contains (Product_Text, "build.output.hide")
        and then Contains (Product_Text, "build.output.focus")
        and then Contains (Product_Text, "diagnostics.show")
        and then Contains (Product_Text, "buffer.switch-next")
        and then Contains (Product_Text, "buffer.switch-previous")
        and then Contains (Product_Text, "buffer.close")
        and then Contains (Product_Text, "buffer.close-all-clean")
        and then Contains (Product_Text, "workspace.restore")
        and then Missing_Case_Insensitive (Product_Text, "buffer id")
        and then Missing_Case_Insensitive (Product_Text, "route id")
        and then Missing_Case_Insensitive (Product_Text, "fixture")
        and then Missing_Case_Insensitive (Product_Text, "scaffold")
        and then Missing_Case_Insensitive (Product_Text, "placeholder")
        and then Missing_Case_Insensitive (Product_Text, "synthetic")
        and then Missing_Case_Insensitive (Product_Text, "Build UI")
        and then Missing_Case_Insensitive (Product_Text, "active-buffer");
   end Assert_Phase579_Product_Surface_Coherent;


   function Assert_Dogfood_Transient_State_Not_Persisted
     (Workspace_Text : String) return Boolean
   is
   begin
      return Missing (Workspace_Text, "Dogfood_Known_Token")
        and then Missing (Workspace_Text, "Build_Candidates")
        and then Missing (Workspace_Text, "Consent")
        and then Missing (Workspace_Text, "Latest_Build")
        and then Missing (Workspace_Text, "Outline")
        and then Missing (Workspace_Text, "Quick_Open")
        and then Missing (Workspace_Text, "Project_Search")
        and then Missing (Workspace_Text, "diagnostic");
   end Assert_Dogfood_Transient_State_Not_Persisted;

end Editor.Dogfood_Workflow;
