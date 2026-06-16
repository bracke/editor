with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands;

package body Editor.Configuration_Recovery is

   use type Editor.Settings.Settings_Status;
   use type Editor.Keybinding_Config.Keybinding_Config_Status;
   use type Editor.Workspace_Persistence.Workspace_Persistence_Status;
   use type Editor.Recent_Projects.Recent_Project_Status;

   Pending_Reset_All_Confirmation : Boolean := False;
   Recorded_Recovery_Summary      : Configuration_Recovery_Summary := (others => <>);
   Recorded_Recovery_Summary_Set  : Boolean := False;

   function Count_Image (Value : Natural) return String is
      Raw : constant String := Natural'Image (Value);
   begin
      return Raw (Raw'First + 1 .. Raw'Last);
   end Count_Image;

   function Bounded_Text (Text : String) return Unbounded_String is
   begin
      if Text'Length <= Max_Recovery_Message_Length then
         return To_Unbounded_String (Text);
      elsif Max_Recovery_Message_Length <= 3 then
         return To_Unbounded_String (Text (Text'First .. Text'First + Max_Recovery_Message_Length - 1));
      else
         return To_Unbounded_String
           (Text (Text'First .. Text'First + Max_Recovery_Message_Length - 4) & "...");
      end if;
   end Bounded_Text;

   function Domain_Label (Domain : Configuration_Domain) return String is
   begin
      case Domain is
         when Settings_Domain => return "Settings";
         when Keybindings_Domain => return "Keybindings";
         when Workspace_Domain => return "Workspace";
         when Recent_Projects_Domain => return "Recent Projects";
         when Command_Routes_Domain => return "Command Routes";
         when Runtime_Defaults_Domain => return "Runtime Defaults";
      end case;
   end Domain_Label;

   function Load_Status_Label (Status : Domain_Load_Status) return String is
   begin
      case Status is
         when Domain_Ok => return "ok";
         when Domain_Missing => return "missing";
         when Domain_Unreadable => return "unreadable";
         when Domain_Malformed => return "malformed";
         when Domain_Loaded_With_Warnings => return "loaded with warnings";
         when Domain_Loaded_With_Defaults => return "loaded with defaults";
         when Domain_Partially_Loaded => return "partially loaded";
         when Domain_Ignored_Unsupported_Fields => return "ignored unsupported fields";
         when Domain_Reset_Required => return "reset required";
         when Domain_Reset_Available => return "reset available";
      end case;
   end Load_Status_Label;

   function Recovery_Action_Label (Action : Recovery_Action) return String is
   begin


      case Action is
         when No_Recovery_Action => return "No recovery action required.";
         when Use_Safe_Defaults => return "Safe defaults are active.";
         when Keep_Valid_Entries => return "Valid entries were kept.";
         when Ignore_Invalid_Entries => return "Invalid entries were ignored.";
         when Ignore_Unsupported_Fields => return "Unsupported fields were ignored.";
         when Clear_Structural_State => return "Workspace structural state was cleared.";
         when Clear_Recent_Project_List => return "Recent Projects list was cleared.";
         when Reset_Domain_Available => return "Reset this domain to defaults if needed.";
         when Save_Clean_Available => return "Save a clean file for this domain if desired.";
         when Explicit_Reset_All_Required => return "Reset all requires explicit confirmation.";
      end case;
   end Recovery_Action_Label;



   function Recovery_Command_Stable_Name
     (Action : Recovery_Command_Action) return String
   is
   begin
      case Action is
         when Recovery_Action_Show => return "configuration.recover-show";
         when Recovery_Action_Audit => return "configuration.audit";
         when Recovery_Action_Reset_Settings => return "configuration.reset-settings";
         when Recovery_Action_Reset_Keybindings => return "configuration.reset-keybindings";
         when Recovery_Action_Reset_Workspace => return "configuration.reset-workspace";
         when Recovery_Action_Reset_Recent_Projects => return "configuration.reset-recent-projects";
         when Recovery_Action_Reset_All => return "configuration.reset-all";
         when Recovery_Action_Confirm_Reset_All => return "configuration.reset-all.confirm";
         when Recovery_Action_Cancel_Reset_All => return "configuration.reset-all.cancel";
         when Recovery_Action_Save_Clean_Settings => return "configuration.save-clean-settings";
         when Recovery_Action_Save_Clean_Keybindings => return "configuration.save-clean-keybindings";
         when Recovery_Action_Save_Clean_Workspace => return "configuration.save-clean-workspace";
         when Recovery_Action_Save_Clean_Recent_Projects => return "configuration.save-clean-recent-projects";
      end case;
   end Recovery_Command_Stable_Name;

   function Summary_Has_Domain_Issue
     (Summary : Configuration_Recovery_Summary;
      Domain  : Configuration_Domain) return Boolean
   is
   begin
      for I in 1 .. Summary.Domain_Count loop
         if I <= Max_Recovery_Domains
           and then Summary.Rows (I).Domain = Domain
           and then Domain_Has_Recovery_Issue (Summary.Rows (I))
         then
            return True;
         end if;
      end loop;
      return False;
   end Summary_Has_Domain_Issue;

   function Summary_Has_Any_Domain_Issue
     (Summary : Configuration_Recovery_Summary) return Boolean
   is
   begin
      for I in 1 .. Summary.Domain_Count loop
         if I <= Max_Recovery_Domains
           and then Domain_Has_Recovery_Issue (Summary.Rows (I))
         then
            return True;
         end if;
      end loop;
      return False;
   end Summary_Has_Any_Domain_Issue;

   function Recovery_Command_Availability_For
     (Action                : Recovery_Command_Action;
      Summary               : Configuration_Recovery_Summary;
      Reset_All_Confirmation : Boolean := False) return Recovery_Command_Availability
   is
      Result : Recovery_Command_Availability;
   begin
      if Reset_All_Confirmation
        and then Action not in
          Recovery_Action_Show
        | Recovery_Action_Audit
        | Recovery_Action_Confirm_Reset_All
        | Recovery_Action_Cancel_Reset_All
      then
         Result.Available := False;
         Result.Reason :=
           To_Unbounded_String ("Command unavailable while confirmation is pending.");
         return Result;
      end if;

      case Action is
         when Recovery_Action_Show =>
            Result.Available := Summary.Domain_Count > 0;
            if not Result.Available then
               Result.Reason := To_Unbounded_String ("No configuration audit results.");
            end if;
         when Recovery_Action_Audit =>
            Result.Available := True;
         when Recovery_Action_Reset_Settings =>
            Result.Available := Summary_Has_Domain_Issue (Summary, Settings_Domain);
            if not Result.Available then
               Result.Reason := To_Unbounded_String ("Domain already clean.");
            end if;
         when Recovery_Action_Reset_Keybindings =>
            Result.Available := Summary_Has_Domain_Issue (Summary, Keybindings_Domain);
            if not Result.Available then
               Result.Reason := To_Unbounded_String ("Domain already clean.");
            end if;
         when Recovery_Action_Reset_Workspace =>
            Result.Available := Summary_Has_Domain_Issue (Summary, Workspace_Domain);
            if not Result.Available then
               Result.Reason := To_Unbounded_String ("Domain already clean.");
            end if;
         when Recovery_Action_Reset_Recent_Projects =>
            Result.Available := Summary_Has_Domain_Issue (Summary, Recent_Projects_Domain);
            if not Result.Available then
               Result.Reason := To_Unbounded_String ("Domain already clean.");
            end if;
         when Recovery_Action_Save_Clean_Settings =>
            Result.Available := Summary_Has_Domain_Issue (Summary, Settings_Domain);
            if not Result.Available then
               Result.Reason := To_Unbounded_String ("Domain already clean.");
            end if;
         when Recovery_Action_Save_Clean_Keybindings =>
            Result.Available := Summary_Has_Domain_Issue (Summary, Keybindings_Domain);
            if not Result.Available then
               Result.Reason := To_Unbounded_String ("Domain already clean.");
            end if;
         when Recovery_Action_Save_Clean_Workspace =>
            Result.Available := Summary_Has_Domain_Issue (Summary, Workspace_Domain);
            if not Result.Available then
               Result.Reason := To_Unbounded_String ("Domain already clean.");
            end if;
         when Recovery_Action_Save_Clean_Recent_Projects =>
            Result.Available := Summary_Has_Domain_Issue (Summary, Recent_Projects_Domain);
            if not Result.Available then
               Result.Reason := To_Unbounded_String ("Domain already clean.");
            end if;
         when Recovery_Action_Reset_All =>
            Result.Available := Summary_Has_Any_Domain_Issue (Summary)
              and then not Reset_All_Confirmation;
            if not Result.Available then
               if Reset_All_Confirmation then
                  Result.Reason := To_Unbounded_String ("Reset requires confirmation.");
               else
                  Result.Reason := To_Unbounded_String ("No recovery issues.");
               end if;
            end if;
         when Recovery_Action_Confirm_Reset_All
            | Recovery_Action_Cancel_Reset_All =>
            Result.Available := Reset_All_Confirmation;
            if not Result.Available then
               Result.Reason := To_Unbounded_String ("No pending reset-all confirmation.");
            end if;
      end case;
      return Result;
   end Recovery_Command_Availability_For;

   procedure Request_Reset_All_Confirmation is
   begin
      Pending_Reset_All_Confirmation := True;
   end Request_Reset_All_Confirmation;

   procedure Clear_Reset_All_Confirmation is
   begin
      Pending_Reset_All_Confirmation := False;
   end Clear_Reset_All_Confirmation;

   function Has_Pending_Reset_All_Confirmation return Boolean is
   begin
      return Pending_Reset_All_Confirmation;
   end Has_Pending_Reset_All_Confirmation;

   function Recovery_Command_Row_For
     (Action                : Recovery_Command_Action;
      Display               : String;
      Domain                : Configuration_Domain;
      Domain_Specific       : Boolean := True;
      Requires_Confirmation : Boolean := False;
      Confirmation_Action   : Boolean := False;
      Save_Clean_Action     : Boolean := False;
      Reset_Action          : Boolean := False) return Recovery_Command_Row
   is
   begin
      return
        (Stable_Name => To_Unbounded_String (Recovery_Command_Stable_Name (Action)),
         Display_Name => To_Unbounded_String (Display),
         Action => Action,
         Domain => Domain,
         Domain_Specific => Domain_Specific,
         Requires_Confirmation => Requires_Confirmation,
         Confirmation_Action => Confirmation_Action,
         Save_Clean_Action => Save_Clean_Action,
         Reset_Action => Reset_Action,
         No_Payload => True,
         Mutates_Only_Domain => True);
   end Recovery_Command_Row_For;

   function Build_Recovery_Command_Catalog return Recovery_Command_Catalog
   is
      Result : Recovery_Command_Catalog;

      procedure Append (Row : Recovery_Command_Row) is
      begin
         if Result.Row_Count < Max_Recovery_Command_Rows then
            Result.Row_Count := Result.Row_Count + 1;
            Result.Rows (Result.Row_Count) := Row;
         end if;
         if Row.Reset_Action then
            Result.Reset_Count := Result.Reset_Count + 1;
         end if;
         if Row.Save_Clean_Action then
            Result.Save_Clean_Count := Result.Save_Clean_Count + 1;
         end if;
         if Row.Requires_Confirmation or else Row.Confirmation_Action then
            Result.Confirmation_Count := Result.Confirmation_Count + 1;
         end if;
         if not Row.No_Payload then
            Result.Payload_Command_Count := Result.Payload_Command_Count + 1;
         end if;
         if not Row.Mutates_Only_Domain then
            Result.Cross_Domain_Command_Count := Result.Cross_Domain_Command_Count + 1;
         end if;
      end Append;
   begin
      Append (Recovery_Command_Row_For
        (Recovery_Action_Show, "Show Configuration Recovery", Settings_Domain,
         Domain_Specific => False));
      Append (Recovery_Command_Row_For
        (Recovery_Action_Audit, "Review Configuration", Command_Routes_Domain,
         Domain_Specific => False));
      Append (Recovery_Command_Row_For
        (Recovery_Action_Reset_Settings, "Reset Settings", Settings_Domain,
         Reset_Action => True));
      Append (Recovery_Command_Row_For
        (Recovery_Action_Reset_Keybindings, "Reset Keybindings", Keybindings_Domain,
         Reset_Action => True));
      Append (Recovery_Command_Row_For
        (Recovery_Action_Reset_Workspace, "Reset Workspace", Workspace_Domain,
         Reset_Action => True));
      Append (Recovery_Command_Row_For
        (Recovery_Action_Reset_Recent_Projects, "Reset Recent Projects", Recent_Projects_Domain,
         Reset_Action => True));
      Append (Recovery_Command_Row_For
        (Recovery_Action_Reset_All, "Reset All Configuration Domains", Runtime_Defaults_Domain,
         Domain_Specific => False, Requires_Confirmation => True, Reset_Action => True));
      Append (Recovery_Command_Row_For
        (Recovery_Action_Confirm_Reset_All, "Confirm Reset All Configuration Domains", Runtime_Defaults_Domain,
         Domain_Specific => False, Confirmation_Action => True));
      Append (Recovery_Command_Row_For
        (Recovery_Action_Cancel_Reset_All, "Cancel Reset All Configuration Domains", Runtime_Defaults_Domain,
         Domain_Specific => False, Confirmation_Action => True));
      Append (Recovery_Command_Row_For
        (Recovery_Action_Save_Clean_Settings, "Save Clean Settings", Settings_Domain,
         Save_Clean_Action => True));
      Append (Recovery_Command_Row_For
        (Recovery_Action_Save_Clean_Keybindings, "Save Clean Keybindings", Keybindings_Domain,
         Save_Clean_Action => True));
      Append (Recovery_Command_Row_For
        (Recovery_Action_Save_Clean_Workspace, "Save Clean Workspace", Workspace_Domain,
         Save_Clean_Action => True));
      Append (Recovery_Command_Row_For
        (Recovery_Action_Save_Clean_Recent_Projects, "Save Clean Recent Projects", Recent_Projects_Domain,
         Save_Clean_Action => True));
      return Result;
   end Build_Recovery_Command_Catalog;


   function Issue_Row
     (Domain      : Configuration_Domain;
      Load_Status : Domain_Load_Status;
      Action      : Recovery_Action;
      Suggestion  : String;
      Warnings    : Natural := 0;
      Errors      : Natural := 0) return Domain_Recovery_Status
   is
      Result : Domain_Recovery_Status;
   begin
      Result.Domain := Domain;
      Result.Load_Status := Load_Status;
      Result.Validation_Status := Load_Status;
      Result.Action := Action;
      Result.Warning_Count := Warnings;
      Result.Error_Count := Errors;
      Result.User_Action_Suggestion := Bounded_Text (Suggestion);
      Result.Missing_File := Load_Status = Domain_Missing;
      Result.Unreadable_File := Load_Status = Domain_Unreadable;
      Result.Malformed_File := Load_Status = Domain_Malformed;
      Result.Safe_Defaults_Active := Action = Use_Safe_Defaults
        or else Load_Status = Domain_Loaded_With_Defaults;
      return Result;
   end Issue_Row;

   function Status_From_Settings
     (Status : Editor.Settings.Settings_Status) return Domain_Recovery_Status
   is
      Result : Domain_Recovery_Status;
   begin
      case Status is
         when Editor.Settings.Settings_Ok =>
            Result := Issue_Row
              (Settings_Domain, Domain_Ok, No_Recovery_Action,
               "Settings are valid.");
         when Editor.Settings.Settings_Not_Found =>
            Result := Issue_Row
              (Settings_Domain, Domain_Missing, Use_Safe_Defaults,
               "Settings defaults active.", Warnings => 1);
            Result.Defaulted_Value_Count := 1;
         when Editor.Settings.Settings_Invalid_Format
            | Editor.Settings.Settings_Unsupported_Version =>
            Result := Issue_Row
              (Settings_Domain, Domain_Malformed, Use_Safe_Defaults,
               "Settings file malformed; using defaults.", Errors => 1);
            Result.Defaulted_Value_Count := 1;
         when Editor.Settings.Settings_Read_Error =>
            Result := Issue_Row
              (Settings_Domain, Domain_Unreadable, Use_Safe_Defaults,
               "Settings file unreadable; using defaults.", Errors => 1);
            Result.Defaulted_Value_Count := 1;
         when Editor.Settings.Settings_Write_Error =>
            Result := Issue_Row
              (Settings_Domain, Domain_Reset_Available, Save_Clean_Available,
               "Settings could not be written; save clean settings is available.", Errors => 1);
         when Editor.Settings.Settings_Partial_Load =>
            Result := Issue_Row
              (Settings_Domain, Domain_Loaded_With_Defaults, Save_Clean_Available,
               "Settings loaded with invalid values reset to defaults.", Warnings => 1);
            Result.Defaulted_Value_Count := Editor.Settings.Last_Load_Defaulted_Count;
            Result.Ignored_Field_Count := Editor.Settings.Last_Load_Ignored_Count;
            if Result.Defaulted_Value_Count = 0
              and then Result.Ignored_Field_Count = 0
            then
               Result.Defaulted_Value_Count := 1;
            end if;
      end case;
      return Result;
   end Status_From_Settings;

   function Status_From_Keybindings
     (Status : Editor.Keybinding_Config.Keybinding_Config_Status) return Domain_Recovery_Status
   is
      Rejected : constant Natural := Editor.Keybinding_Config.Last_Load_Ignored_Count;
      Result   : Domain_Recovery_Status;
   begin
      case Status is
         when Editor.Keybinding_Config.Keybinding_Config_Ok =>
            Result := Issue_Row
              (Keybindings_Domain, Domain_Ok, No_Recovery_Action,
               "Keybindings are valid.");
         when Editor.Keybinding_Config.Keybinding_Config_Not_Found =>
            Result := Issue_Row
              (Keybindings_Domain, Domain_Missing, Use_Safe_Defaults,
               "Default keybindings active.", Warnings => 1);
         when Editor.Keybinding_Config.Keybinding_Config_Invalid_Format
            | Editor.Keybinding_Config.Keybinding_Config_Unsupported_Version =>
            Result := Issue_Row
              (Keybindings_Domain, Domain_Malformed, Use_Safe_Defaults,
               "Keybindings file malformed; default keybindings active.", Errors => 1);
         when Editor.Keybinding_Config.Keybinding_Config_Read_Error =>
            Result := Issue_Row
              (Keybindings_Domain, Domain_Unreadable, Use_Safe_Defaults,
               "Keybindings file unreadable; default keybindings active.", Errors => 1);
         when Editor.Keybinding_Config.Keybinding_Config_Write_Error =>
            Result := Issue_Row
              (Keybindings_Domain, Domain_Reset_Available, Save_Clean_Available,
               "Keybindings could not be written; save clean keybindings is available.", Errors => 1);
         when Editor.Keybinding_Config.Keybinding_Config_Partial_Load =>
            Result := Issue_Row
              (Keybindings_Domain, Domain_Partially_Loaded, Keep_Valid_Entries,
               "Keybindings loaded with rejected invalid bindings.", Warnings => 1);
            Result.Rejected_Entry_Count := Rejected;
            Result.Invalid_Entry_Count := Rejected;
            Result.Ignored_Field_Count :=
              Editor.Keybinding_Config.Last_Load_Diagnostic_Count
                (Editor.Keybinding_Config.Unsupported_Payload);
      end case;
      return Result;
   end Status_From_Keybindings;

   function Status_From_Workspace
     (Status      : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Diagnostics : Natural := 0) return Domain_Recovery_Status
   is
      Result : Domain_Recovery_Status;
   begin
      case Status is
         when Editor.Workspace_Persistence.Workspace_Persistence_Ok =>
            Result := Issue_Row
              (Workspace_Domain, Domain_Ok, No_Recovery_Action,
               "Workspace session is valid.");
         when Editor.Workspace_Persistence.Workspace_Persistence_Not_Found =>
            Result := Issue_Row
              (Workspace_Domain, Domain_Missing, Clear_Structural_State,
               "No workspace session restored.", Warnings => 1);
            Result.Safe_Defaults_Active := True;
         when Editor.Workspace_Persistence.Workspace_Persistence_Invalid_Format
            | Editor.Workspace_Persistence.Workspace_Persistence_Unsupported_Version =>
            Result := Issue_Row
              (Workspace_Domain, Domain_Malformed, Clear_Structural_State,
               "Workspace session malformed; no session restored.", Errors => 1);
            Result.Safe_Defaults_Active := True;
         when Editor.Workspace_Persistence.Workspace_Persistence_Read_Error =>
            Result := Issue_Row
              (Workspace_Domain, Domain_Unreadable, Clear_Structural_State,
               "Workspace session unreadable; no session restored.", Errors => 1);
            Result.Safe_Defaults_Active := True;
         when Editor.Workspace_Persistence.Workspace_Persistence_Write_Error =>
            Result := Issue_Row
              (Workspace_Domain, Domain_Reset_Available, Save_Clean_Available,
               "Workspace session could not be written; save clean workspace is available.", Errors => 1);
         when Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore =>
            Result := Issue_Row
              (Workspace_Domain, Domain_Partially_Loaded, Ignore_Invalid_Entries,
               "Workspace loaded with stale or unsupported structural entries ignored.", Warnings => 1);
            Result.Ignored_Field_Count := Diagnostics;
            Result.Invalid_Entry_Count := Diagnostics;
      end case;
      return Result;
   end Status_From_Workspace;

   function Status_From_Recent_Projects
     (Status : Editor.Recent_Projects.Recent_Project_Status) return Domain_Recovery_Status
   is
      Result : Domain_Recovery_Status;
   begin
      case Status is
         when Editor.Recent_Projects.Recent_Project_Ok =>
            Result := Issue_Row
              (Recent_Projects_Domain, Domain_Ok, No_Recovery_Action,
               "Recent Projects list is valid.");
         when Editor.Recent_Projects.Recent_Project_Not_Found =>
            Result := Issue_Row
              (Recent_Projects_Domain, Domain_Missing, Clear_Recent_Project_List,
               "Recent Projects list empty.", Warnings => 1);
            Result.Safe_Defaults_Active := True;
         when Editor.Recent_Projects.Recent_Project_Invalid_Format =>
            Result := Issue_Row
              (Recent_Projects_Domain, Domain_Malformed, Clear_Recent_Project_List,
               "Recent Projects file malformed; list cleared.", Errors => 1);
            Result.Safe_Defaults_Active := True;
         when Editor.Recent_Projects.Recent_Project_Read_Error =>
            Result := Issue_Row
              (Recent_Projects_Domain, Domain_Unreadable, Clear_Recent_Project_List,
               "Recent Projects file unreadable; list cleared.", Errors => 1);
            Result.Safe_Defaults_Active := True;
         when Editor.Recent_Projects.Recent_Project_Write_Error =>
            Result := Issue_Row
              (Recent_Projects_Domain, Domain_Reset_Available, Save_Clean_Available,
               "Recent Projects could not be written; save clean recent projects is available.", Errors => 1);
         when Editor.Recent_Projects.Recent_Project_Partial_Load =>
            Result := Issue_Row
              (Recent_Projects_Domain, Domain_Partially_Loaded, Ignore_Invalid_Entries,
               "Recent Projects loaded with invalid lightweight entries ignored.", Warnings => 1);
            Result.Invalid_Entry_Count := Editor.Recent_Projects.Last_Load_Ignored_Count;
            Result.Ignored_Field_Count := Editor.Recent_Projects.Last_Load_Ignored_Count;
      end case;
      return Result;
   end Status_From_Recent_Projects;

   procedure Normalize_Recovery_Status
     (Status : in out Domain_Recovery_Status)
   is
   begin
      Status.User_Action_Suggestion :=
        Bounded_Text (To_String (Status.User_Action_Suggestion));
   end Normalize_Recovery_Status;

   function Recovery_Message_Is_Bounded
     (Status : Domain_Recovery_Status) return Boolean
   is
   begin
      return Length (Status.User_Action_Suggestion) <= Max_Recovery_Message_Length;
   end Recovery_Message_Is_Bounded;

   procedure Normalize_Recovery_Summary
     (Summary : in out Configuration_Recovery_Summary)
   is
      Last : Natural := Summary.Domain_Count;
   begin
      if Last > Max_Recovery_Domains then
         Last := Max_Recovery_Domains;
         Summary.Bounded := False;
      end if;

      for I in 1 .. Last loop
         Normalize_Recovery_Status (Summary.Rows (I));
      end loop;
   end Normalize_Recovery_Summary;

   procedure Append
     (Summary : in out Configuration_Recovery_Summary;
      Row     : Domain_Recovery_Status)
   is
      Stored : Domain_Recovery_Status := Row;
   begin
      Normalize_Recovery_Status (Stored);
      if Summary.Domain_Count < Max_Recovery_Domains then
         Summary.Domain_Count := Summary.Domain_Count + 1;
         Summary.Rows (Summary.Domain_Count) := Stored;
      else
         Summary.Bounded := False;
      end if;
      Summary.Warning_Count := Summary.Warning_Count + Stored.Warning_Count;
      Summary.Error_Count := Summary.Error_Count + Stored.Error_Count;
      if Stored.Safe_Defaults_Active then
         Summary.Domains_With_Defaults_Count := Summary.Domains_With_Defaults_Count + 1;
      end if;
      if Stored.Warning_Count > 0 or else Stored.Error_Count > 0
        or else Stored.Load_Status /= Domain_Ok
      then
         Summary.Domains_With_Issues_Count := Summary.Domains_With_Issues_Count + 1;
      end if;
   end Append;

   function Summary_Label
     (Summary : Configuration_Recovery_Summary) return String
   is
   begin
      if Summary.Error_Count = 0 and then Summary.Warning_Count = 0 then
         return "Configuration recovery clean";
      elsif Summary.Error_Count > 0 then
         return "Configuration recovery: "
           & Count_Image (Summary.Domains_With_Issues_Count)
           & " domains need attention";
      else
         return "Configuration recovery: "
           & Count_Image (Summary.Warning_Count) & " warnings";
      end if;
   end Summary_Label;

   function Domain_Has_Recovery_Issue
     (Row : Domain_Recovery_Status) return Boolean
   is
   begin
      return Row.Load_Status /= Domain_Ok
        or else Row.Validation_Status /= Domain_Ok
        or else Row.Warning_Count > 0
        or else Row.Error_Count > 0
        or else Row.Ignored_Field_Count > 0
        or else Row.Invalid_Entry_Count > 0
        or else Row.Defaulted_Value_Count > 0
        or else Row.Rejected_Entry_Count > 0
        or else Row.Missing_File
        or else Row.Unreadable_File
        or else Row.Malformed_File
        or else Row.Safe_Defaults_Active;
   end Domain_Has_Recovery_Issue;

   function Build_Startup_Recovery_Summary
     (Settings_Row    : Domain_Recovery_Status;
      Keybindings_Row : Domain_Recovery_Status;
      Workspace_Row   : Domain_Recovery_Status;
      Recent_Row      : Domain_Recovery_Status) return Configuration_Recovery_Summary
   is
      Result : Configuration_Recovery_Summary;
   begin
      Append (Result, Settings_Row);
      Append (Result, Keybindings_Row);
      Append (Result, Workspace_Row);
      Append (Result, Recent_Row);
      Append (Result, Issue_Row
        (Command_Routes_Domain, Domain_Ok, No_Recovery_Action,
         "Command descriptors and routes remain audit-only."));
      Append (Result, Issue_Row
        (Runtime_Defaults_Domain, Domain_Ok, No_Recovery_Action,
         "Runtime safe defaults are available."));
      return Result;
   end Build_Startup_Recovery_Summary;

   function Build_Surface_Snapshot
     (Summary        : Configuration_Recovery_Summary;
      Selected_Index : Natural := 0) return Configuration_Recovery_Surface_Snapshot
   is
      Result : Configuration_Recovery_Surface_Snapshot;
      Last   : Natural := Summary.Domain_Count;
   begin
      if Last > Max_Recovery_Domains then
         Last := Max_Recovery_Domains;
      end if;
      Result.Row_Count := Last;
      Result.Warning_Count := Summary.Warning_Count;
      Result.Error_Count := Summary.Error_Count;
      Result.Bounded := Summary.Bounded and then Summary.Domain_Count <= Max_Recovery_Domains;
      Result.Summary_Label := To_Unbounded_String (Summary_Label (Summary));
      for I in 1 .. Last loop
         Result.Rows (I).Domain_Label :=
           To_Unbounded_String (Domain_Label (Summary.Rows (I).Domain));
         Result.Rows (I).Status_Label :=
           To_Unbounded_String (Load_Status_Label (Summary.Rows (I).Load_Status));
         Result.Rows (I).Action_Label :=
           To_Unbounded_String (Recovery_Action_Label (Summary.Rows (I).Action));
         Result.Rows (I).Warning_Count := Summary.Rows (I).Warning_Count;
         Result.Rows (I).Error_Count := Summary.Rows (I).Error_Count;
         Result.Rows (I).Ignored_Field_Count := Summary.Rows (I).Ignored_Field_Count;
         Result.Rows (I).Invalid_Entry_Count := Summary.Rows (I).Invalid_Entry_Count;
         Result.Rows (I).Defaulted_Value_Count := Summary.Rows (I).Defaulted_Value_Count;
         Result.Rows (I).Rejected_Entry_Count := Summary.Rows (I).Rejected_Entry_Count;
         Result.Rows (I).Missing_File := Summary.Rows (I).Missing_File;
         Result.Rows (I).Unreadable_File := Summary.Rows (I).Unreadable_File;
         Result.Rows (I).Malformed_File := Summary.Rows (I).Malformed_File;
         Result.Rows (I).Safe_Defaults_Active := Summary.Rows (I).Safe_Defaults_Active;
         Result.Rows (I).Action_Suggestion := Summary.Rows (I).User_Action_Suggestion;
         Result.Rows (I).Selected := Selected_Index = I;
      end loop;
      return Result;
   end Build_Surface_Snapshot;


   procedure Record_Recovery_Summary
     (Summary : Configuration_Recovery_Summary)
   is
      Clean : Configuration_Recovery_Summary := Summary;
   begin
      Normalize_Recovery_Summary (Clean);
      Recorded_Recovery_Summary := Clean;
      Recorded_Recovery_Summary_Set := True;
   end Record_Recovery_Summary;

   function Has_Recorded_Recovery_Summary return Boolean is
   begin
      return Recorded_Recovery_Summary_Set;
   end Has_Recorded_Recovery_Summary;

   function Current_Recovery_Summary return Configuration_Recovery_Summary is
   begin
      return Recorded_Recovery_Summary;
   end Current_Recovery_Summary;

   procedure Clear_Recorded_Recovery_Summary is
   begin
      Recorded_Recovery_Summary := (others => <>);
      Recorded_Recovery_Summary_Set := False;
   end Clear_Recorded_Recovery_Summary;

   procedure Clear_Recovery_Runtime_State is
   begin
      Clear_Reset_All_Confirmation;
      Clear_Recorded_Recovery_Summary;
   end Clear_Recovery_Runtime_State;

   function Recovery_Summary_Has_Only_Clean_Domains
     (Summary : Configuration_Recovery_Summary) return Boolean
   is
   begin
      if Summary.Domain_Count = 0 then
         return True;
      end if;

      for I in 1 .. Summary.Domain_Count loop
         if I <= Max_Recovery_Domains
           and then Domain_Has_Recovery_Issue (Summary.Rows (I))
         then
            return False;
         end if;
      end loop;
      return True;
   end Recovery_Summary_Has_Only_Clean_Domains;

   procedure Append_Domain_Local_Status
     (Summary : in out Configuration_Recovery_Summary;
      Status  : Domain_Recovery_Status)
   is
      Local : Domain_Recovery_Status := Status;
   begin
      --  Domain-local command results must not fabricate command route or
      --  runtime-default rows.  The caller can compose a broader summary
      --  explicitly when it is auditing all domains.
      if Local.Domain = Command_Routes_Domain
        or else Local.Domain = Runtime_Defaults_Domain
      then
         return;
      end if;
      Append (Summary, Local);
   end Append_Domain_Local_Status;

   procedure Load_All_Domains_Safely
     (Settings_Path    : String;
      Keybindings_Path : String;
      Workspace_Path   : String;
      Recent_Path      : String;
      Settings         : out Editor.Settings.Settings_Model;
      Keybindings      : out Editor.Keybinding_Config.Keybinding_Config_Model;
      Workspace        : out Editor.Workspace_Persistence.Workspace_Snapshot;
      Recent           : out Editor.Recent_Projects.Recent_Project_List;
      Summary          : out Configuration_Recovery_Summary)
   is
      Settings_Status    : Editor.Settings.Settings_Status := Editor.Settings.Settings_Ok;
      Keybindings_Status : Editor.Keybinding_Config.Keybinding_Config_Status :=
        Editor.Keybinding_Config.Keybinding_Config_Ok;
      Workspace_Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status :=
        Editor.Workspace_Persistence.Workspace_Persistence_Ok;
      Recent_Status      : Editor.Recent_Projects.Recent_Project_Status :=
        Editor.Recent_Projects.Recent_Project_Ok;
   begin
      Summary := (others => <>);

      begin
         Editor.Settings.Load_From_File (Settings_Path, Settings, Settings_Status);
      exception
         when others =>
            Editor.Settings.Set_Defaults (Settings);
            Settings_Status := Editor.Settings.Settings_Read_Error;
      end;
      if Settings_Status /= Editor.Settings.Settings_Ok
        and then Settings_Status /= Editor.Settings.Settings_Partial_Load
      then
         Editor.Settings.Set_Defaults (Settings);
      end if;
      declare
         Settings_Row : constant Domain_Recovery_Status :=
           Status_From_Settings (Settings_Status);
      begin
         Append (Summary, Settings_Row);
      end;

      begin
         Editor.Keybinding_Config.Load_From_File
           (Keybindings_Path, Keybindings, Keybindings_Status);
      exception
         when others =>
            Editor.Keybinding_Config.Set_Defaults (Keybindings);
            Keybindings_Status := Editor.Keybinding_Config.Keybinding_Config_Read_Error;
      end;
      if Keybindings_Status /= Editor.Keybinding_Config.Keybinding_Config_Ok
        and then Keybindings_Status /= Editor.Keybinding_Config.Keybinding_Config_Partial_Load
      then
         Editor.Keybinding_Config.Set_Defaults (Keybindings);
      end if;
      Append (Summary, Status_From_Keybindings (Keybindings_Status));

      begin
         Editor.Workspace_Persistence.Load_From_File
           (Workspace_Path, Workspace, Workspace_Status);
      exception
         when others =>
            Editor.Workspace_Persistence.Clear (Workspace);
            Workspace_Status := Editor.Workspace_Persistence.Workspace_Persistence_Read_Error;
      end;
      if Workspace_Status /= Editor.Workspace_Persistence.Workspace_Persistence_Ok
        and then Workspace_Status /= Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore
      then
         Editor.Workspace_Persistence.Clear (Workspace);
      end if;
      Append (Summary, Status_From_Workspace
        (Workspace_Status,
         Editor.Workspace_Persistence.Diagnostic_Count (Workspace)));

      begin
         Editor.Recent_Projects.Load_From_File (Recent_Path, Recent, Recent_Status);
      exception
         when others =>
            Editor.Recent_Projects.Clear (Recent);
            Recent_Status := Editor.Recent_Projects.Recent_Project_Read_Error;
      end;
      if Recent_Status /= Editor.Recent_Projects.Recent_Project_Ok
        and then Recent_Status /= Editor.Recent_Projects.Recent_Project_Partial_Load
      then
         Editor.Recent_Projects.Clear (Recent);
      end if;
      Append (Summary, Status_From_Recent_Projects (Recent_Status));

      Append (Summary, Issue_Row
        (Command_Routes_Domain, Domain_Ok, No_Recovery_Action,
         "Command descriptors and routes remain audit-only."));
      Append (Summary, Issue_Row
        (Runtime_Defaults_Domain, Domain_Ok, No_Recovery_Action,
         "Runtime safe defaults are available."));
      Record_Recovery_Summary (Summary);
   end Load_All_Domains_Safely;

   procedure Reset_Settings_Domain
     (Settings : in out Editor.Settings.Settings_Model;
      Status   : out Domain_Recovery_Status)
   is
   begin
      Editor.Settings.Set_Defaults (Settings);
      Status := Issue_Row
        (Settings_Domain, Domain_Loaded_With_Defaults, Use_Safe_Defaults,
         "Settings reset to defaults.");
      Status.Defaulted_Value_Count := 1;
   end Reset_Settings_Domain;

   procedure Reset_Keybindings_Domain
     (Keybindings : in out Editor.Keybinding_Config.Keybinding_Config_Model;
      Status      : out Domain_Recovery_Status)
   is
   begin
      Editor.Keybinding_Config.Set_Defaults (Keybindings);
      Status := Issue_Row
        (Keybindings_Domain, Domain_Loaded_With_Defaults, Use_Safe_Defaults,
         "Keybindings reset to defaults.");
   end Reset_Keybindings_Domain;

   procedure Reset_Workspace_Domain
     (Workspace : in out Editor.Workspace_Persistence.Workspace_Snapshot;
      Status    : out Domain_Recovery_Status)
   is
   begin
      Editor.Workspace_Persistence.Clear (Workspace);
      Status := Issue_Row
        (Workspace_Domain, Domain_Loaded_With_Defaults, Clear_Structural_State,
         "Workspace cleared.");
      Status.Safe_Defaults_Active := True;
   end Reset_Workspace_Domain;

   procedure Reset_Recent_Projects_Domain
     (Recent : in out Editor.Recent_Projects.Recent_Project_List;
      Status : out Domain_Recovery_Status)
   is
   begin
      Editor.Recent_Projects.Clear (Recent);
      Status := Issue_Row
        (Recent_Projects_Domain, Domain_Loaded_With_Defaults, Clear_Recent_Project_List,
         "Recent Projects cleared.");
      Status.Safe_Defaults_Active := True;
   end Reset_Recent_Projects_Domain;


   procedure Reset_All_Domains
     (Settings  : in out Editor.Settings.Settings_Model;
      Keybindings : in out Editor.Keybinding_Config.Keybinding_Config_Model;
      Workspace : in out Editor.Workspace_Persistence.Workspace_Snapshot;
      Recent    : in out Editor.Recent_Projects.Recent_Project_List;
      Confirmed : Boolean;
      Summary   : out Configuration_Recovery_Summary)
   is
      Row : Domain_Recovery_Status;
   begin
      Summary := (others => <>);
      if not Confirmed then
         Append (Summary, Issue_Row
           (Runtime_Defaults_Domain, Domain_Reset_Required, Explicit_Reset_All_Required,
            "Reset all requires explicit confirmation.", Warnings => 1));
         Record_Recovery_Summary (Summary);
         return;
      end if;

      Reset_Settings_Domain (Settings, Row);
      Append (Summary, Row);
      Reset_Keybindings_Domain (Keybindings, Row);
      Append (Summary, Row);
      Reset_Workspace_Domain (Workspace, Row);
      Append (Summary, Row);
      Reset_Recent_Projects_Domain (Recent, Row);
      Append (Summary, Row);
      Append (Summary, Issue_Row
        (Runtime_Defaults_Domain, Domain_Loaded_With_Defaults, Use_Safe_Defaults,
         "All configuration domains reset after explicit confirmation."));
      Record_Recovery_Summary (Summary);
   end Reset_All_Domains;

   procedure Save_Clean_Settings
     (Settings : Editor.Settings.Settings_Model;
      Path     : String;
      Status   : out Domain_Recovery_Status)
   is
      Write_Status : Editor.Settings.Settings_Status;
      Clean        : Editor.Settings.Settings_Model := Settings;
   begin
      begin
         Editor.Settings.Normalize (Clean);
         Editor.Settings.Save_To_File (Clean, Path, Write_Status);
         Status := Status_From_Settings (Write_Status);
         if Write_Status = Editor.Settings.Settings_Ok then
            Status.User_Action_Suggestion := To_Unbounded_String
              ("Clean settings saved with supported fields only.");
         end if;
      exception
         when others =>
            Status := Status_From_Settings (Editor.Settings.Settings_Write_Error);
            Status.User_Action_Suggestion := To_Unbounded_String
              ("Clean settings save failed; settings runtime state was left unchanged.");
      end;
   end Save_Clean_Settings;

   procedure Save_Clean_Keybindings
     (Keybindings : Editor.Keybinding_Config.Keybinding_Config_Model;
      Path        : String;
      Status      : out Domain_Recovery_Status)
   is
      Write_Status : Editor.Keybinding_Config.Keybinding_Config_Status;
      Clean        : Editor.Keybinding_Config.Keybinding_Config_Model := Keybindings;
   begin
      begin
         Editor.Keybinding_Config.Normalize (Clean);
         Editor.Keybinding_Config.Save_To_File (Clean, Path, Write_Status);
         Status := Status_From_Keybindings (Write_Status);
         if Write_Status = Editor.Keybinding_Config.Keybinding_Config_Ok then
            Status.User_Action_Suggestion := To_Unbounded_String
              ("Clean keybindings saved as normalized chords only.");
         end if;
      exception
         when others =>
            Status := Status_From_Keybindings
              (Editor.Keybinding_Config.Keybinding_Config_Write_Error);
            Status.User_Action_Suggestion := To_Unbounded_String
              ("Clean keybindings save failed; keybinding runtime state was left unchanged.");
      end;
   end Save_Clean_Keybindings;

   procedure Save_Clean_Workspace
     (Workspace : Editor.Workspace_Persistence.Workspace_Snapshot;
      Path      : String;
      Status    : out Domain_Recovery_Status)
   is
      Write_Status : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Clean        : Editor.Workspace_Persistence.Workspace_Snapshot := Workspace;
   begin
      begin
         Editor.Workspace_Persistence.Normalize (Clean);
         Editor.Workspace_Persistence.Save_To_File_Atomically
           (Clean, Path, Write_Status);
         Status := Status_From_Workspace (Write_Status);
         if Write_Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok then
            Status.User_Action_Suggestion := To_Unbounded_String
              ("Clean workspace saved with structural fields only.");
         end if;
      exception
         when others =>
            Status := Status_From_Workspace
              (Editor.Workspace_Persistence.Workspace_Persistence_Write_Error);
            Status.User_Action_Suggestion := To_Unbounded_String
              ("Clean workspace save failed; workspace runtime state was left unchanged.");
      end;
   end Save_Clean_Workspace;

   procedure Save_Clean_Recent_Projects
     (Recent : Editor.Recent_Projects.Recent_Project_List;
      Path   : String;
      Status : out Domain_Recovery_Status)
   is
      Write_Status : Editor.Recent_Projects.Recent_Project_Status;
      Clean        : Editor.Recent_Projects.Recent_Project_List := Recent;
   begin
      begin
         Editor.Recent_Projects.Normalize (Clean);
         Editor.Recent_Projects.Save_To_File (Clean, Path, Write_Status);
         Status := Status_From_Recent_Projects (Write_Status);
         if Write_Status = Editor.Recent_Projects.Recent_Project_Ok then
            Status.User_Action_Suggestion := To_Unbounded_String
              ("Clean recent projects saved with lightweight entries only.");
         end if;
      exception
         when others =>
            Status := Status_From_Recent_Projects
              (Editor.Recent_Projects.Recent_Project_Write_Error);
            Status.User_Action_Suggestion := To_Unbounded_String
              ("Clean recent projects save failed; recent-project runtime state was left unchanged.");
      end;
   end Save_Clean_Recent_Projects;

   function Assert_Configuration_Domains_Load_Independently return Boolean is
      S : Editor.Settings.Settings_Model;
      K : Editor.Keybinding_Config.Keybinding_Config_Model;
      W : Editor.Workspace_Persistence.Workspace_Snapshot;
      R : Editor.Recent_Projects.Recent_Project_List;
      Summary : Configuration_Recovery_Summary;
   begin
      Load_All_Domains_Safely
        ("/definitely/missing/settings",
         "/definitely/missing/keybindings",
         "/definitely/missing/workspace",
         "/definitely/missing/recent",
         S, K, W, R, Summary);
      return Summary.Domain_Count = Max_Recovery_Domains
        and then Summary.Rows (1).Domain = Settings_Domain
        and then Summary.Rows (2).Domain = Keybindings_Domain
        and then Summary.Rows (3).Domain = Workspace_Domain
        and then Summary.Rows (4).Domain = Recent_Projects_Domain
        and then Summary.Rows (1).Safe_Defaults_Active
        and then Summary.Rows (2).Safe_Defaults_Active
        and then Summary.Rows (3).Safe_Defaults_Active
        and then Summary.Rows (4).Safe_Defaults_Active;
   end Assert_Configuration_Domains_Load_Independently;

   function Assert_Safe_Defaults_Are_Always_Available return Boolean is
      S : Editor.Settings.Settings_Model;
      K : Editor.Keybinding_Config.Keybinding_Config_Model;
      W : Editor.Workspace_Persistence.Workspace_Snapshot;
      R : Editor.Recent_Projects.Recent_Project_List;
      RS, RK, RW, RR : Domain_Recovery_Status;
   begin
      Reset_Settings_Domain (S, RS);
      Reset_Keybindings_Domain (K, RK);
      Reset_Workspace_Domain (W, RW);
      Reset_Recent_Projects_Domain (R, RR);
      return RS.Safe_Defaults_Active
        and then RK.Safe_Defaults_Active
        and then RW.Safe_Defaults_Active
        and then RR.Safe_Defaults_Active
        and then Editor.Recent_Projects.Count (R) = 0
        and then Editor.Workspace_Persistence.Open_File_Count (W) = 0;
   end Assert_Safe_Defaults_Are_Always_Available;

   function Assert_Recovery_Commands_Do_Not_Cross_Write_Domains return Boolean is
      S1, S2 : Editor.Settings.Settings_Model;
      K1, K2 : Editor.Keybinding_Config.Keybinding_Config_Model;
      W1, W2 : Editor.Workspace_Persistence.Workspace_Snapshot;
      R1, R2 : Editor.Recent_Projects.Recent_Project_List;
      Row : Domain_Recovery_Status;
   begin
      Editor.Settings.Set_Defaults (S1);
      Editor.Settings.Set_Defaults (S2);
      Editor.Keybinding_Config.Set_Defaults (K1);
      K2 := K1;
      Editor.Workspace_Persistence.Clear (W1);
      W2 := W1;
      Editor.Recent_Projects.Clear (R1);
      R2 := R1;

      Reset_Settings_Domain (S1, Row);
      if not Editor.Keybinding_Config.Equivalent (K1, K2)
        or else not Editor.Workspace_Persistence.Equivalent (W1, W2)
        or else Editor.Recent_Projects.Count (R1) /= Editor.Recent_Projects.Count (R2)
      then
         return False;
      end if;

      Reset_Keybindings_Domain (K1, Row);
      return Editor.Settings.Equivalent (S1, S2)
        and then Editor.Workspace_Persistence.Equivalent (W1, W2)
        and then Editor.Recent_Projects.Count (R1) = Editor.Recent_Projects.Count (R2);
   end Assert_Recovery_Commands_Do_Not_Cross_Write_Domains;

   function Assert_Surface_Contains_Actionable_Domain_Details return Boolean is
      Summary : Configuration_Recovery_Summary;
      Surface : Configuration_Recovery_Surface_Snapshot;
      Row     : Domain_Recovery_Status;
   begin
      Row := Issue_Row
        (Keybindings_Domain, Domain_Partially_Loaded, Keep_Valid_Entries,
         "Keybindings loaded with rejected invalid bindings.", Warnings => 1);
      Row.Rejected_Entry_Count := 3;
      Row.Invalid_Entry_Count := 3;
      Append (Summary, Row);
      Surface := Build_Surface_Snapshot (Summary, 1);
      return Surface.Row_Count = 1
        and then To_String (Surface.Rows (1).Domain_Label) = "Keybindings"
        and then To_String (Surface.Rows (1).Status_Label) = "partially loaded"
        and then Surface.Rows (1).Warning_Count = 1
        and then Surface.Rows (1).Rejected_Entry_Count = 3
        and then Surface.Rows (1).Invalid_Entry_Count = 3
        and then To_String (Surface.Rows (1).Action_Label) = "Valid entries were kept."
        and then Surface.Rows (1).Selected;
   end Assert_Surface_Contains_Actionable_Domain_Details;

   function Assert_Save_Clean_Status_Is_Domain_Local return Boolean is
      S : constant Domain_Recovery_Status := Status_From_Settings
        (Editor.Settings.Settings_Write_Error);
      K : constant Domain_Recovery_Status := Status_From_Keybindings
        (Editor.Keybinding_Config.Keybinding_Config_Write_Error);
      W : constant Domain_Recovery_Status := Status_From_Workspace
        (Editor.Workspace_Persistence.Workspace_Persistence_Write_Error);
      R : constant Domain_Recovery_Status := Status_From_Recent_Projects
        (Editor.Recent_Projects.Recent_Project_Write_Error);
   begin
      return S.Domain = Settings_Domain
        and then K.Domain = Keybindings_Domain
        and then W.Domain = Workspace_Domain
        and then R.Domain = Recent_Projects_Domain
        and then S.Action = Save_Clean_Available
        and then K.Action = Save_Clean_Available
        and then W.Action = Save_Clean_Available
        and then R.Action = Save_Clean_Available;
   end Assert_Save_Clean_Status_Is_Domain_Local;

   function Assert_Recovery_Command_Availability_Is_Domain_Local return Boolean is
      Summary : Configuration_Recovery_Summary;
      Settings_Reset : Recovery_Command_Availability;
      Keybindings_Reset : Recovery_Command_Availability;
      Settings_Save : Recovery_Command_Availability;
      Confirm_Reset_All : Recovery_Command_Availability;
   begin
      Append (Summary, Issue_Row
        (Settings_Domain, Domain_Loaded_With_Defaults, Use_Safe_Defaults,
         "Settings defaults active.", Warnings => 1));
      Append (Summary, Issue_Row
        (Keybindings_Domain, Domain_Ok, No_Recovery_Action,
         "Keybindings are valid."));

      Settings_Reset := Recovery_Command_Availability_For
        (Recovery_Action_Reset_Settings, Summary);
      Keybindings_Reset := Recovery_Command_Availability_For
        (Recovery_Action_Reset_Keybindings, Summary);
      Settings_Save := Recovery_Command_Availability_For
        (Recovery_Action_Save_Clean_Settings, Summary);
      Confirm_Reset_All := Recovery_Command_Availability_For
        (Recovery_Action_Confirm_Reset_All, Summary,
         Reset_All_Confirmation => False);

      return Settings_Reset.Available
        and then Settings_Save.Available
        and then not Keybindings_Reset.Available
        and then To_String (Keybindings_Reset.Reason) = "Domain already clean."
        and then not Confirm_Reset_All.Available
        and then To_String (Confirm_Reset_All.Reason) =
          "No pending reset-all confirmation.";
   end Assert_Recovery_Command_Availability_Is_Domain_Local;

   function Assert_Recovery_Summary_Overflow_Is_Bounded return Boolean is
      Summary : Configuration_Recovery_Summary;
      Surface : Configuration_Recovery_Surface_Snapshot;
   begin
      for I in 1 .. Max_Recovery_Domains + 2 loop
         Append (Summary, Issue_Row
           (Runtime_Defaults_Domain, Domain_Ok, No_Recovery_Action,
            "Synthetic boundedness row."));
      end loop;
      Surface := Build_Surface_Snapshot (Summary);
      return Summary.Domain_Count = Max_Recovery_Domains
        and then not Summary.Bounded
        and then Surface.Row_Count = Max_Recovery_Domains
        and then not Surface.Bounded;
   end Assert_Recovery_Summary_Overflow_Is_Bounded;

   function Assert_Settings_Recovery_Counts_Are_Actionable return Boolean is
      Row : constant Domain_Recovery_Status := Status_From_Settings
        (Editor.Settings.Settings_Partial_Load);
   begin
      return Row.Domain = Settings_Domain
        and then Row.Action = Save_Clean_Available
        and then Row.Warning_Count = 1
        and then (Row.Defaulted_Value_Count > 0
                  or else Row.Ignored_Field_Count > 0);
   end Assert_Settings_Recovery_Counts_Are_Actionable;

   function Assert_Recent_Projects_Partial_Load_Is_Preserved return Boolean is
      Row : constant Domain_Recovery_Status := Status_From_Recent_Projects
        (Editor.Recent_Projects.Recent_Project_Partial_Load);
   begin
      return Row.Domain = Recent_Projects_Domain
        and then Row.Load_Status = Domain_Partially_Loaded
        and then Row.Action = Ignore_Invalid_Entries
        and then Row.Warning_Count = 1;
   end Assert_Recent_Projects_Partial_Load_Is_Preserved;

   function Assert_Configuration_Recovery_Render_Is_Side_Effect_Free return Boolean is
      Summary : Configuration_Recovery_Summary;
      Before  : Configuration_Recovery_Summary;
      Surface : Configuration_Recovery_Surface_Snapshot;
   begin
      Summary := (others => <>);
      Append (Summary, Issue_Row
        (Settings_Domain, Domain_Loaded_With_Defaults, Use_Safe_Defaults,
         "Settings defaults active.", Warnings => 1));
      Before := Summary;
      Surface := Build_Surface_Snapshot (Summary, 1);
      return Surface.Row_Count = 1
        and then Surface.Rows (1).Selected
        and then Summary.Domain_Count = Before.Domain_Count
        and then Summary.Warning_Count = Before.Warning_Count
        and then Summary.Rows (1).Load_Status = Before.Rows (1).Load_Status;
   end Assert_Configuration_Recovery_Render_Is_Side_Effect_Free;

   function Assert_Recovery_State_Not_Persisted return Boolean is
      Surface : constant Configuration_Recovery_Surface_Snapshot :=
        Build_Surface_Snapshot ((others => <>));
   begin
      return Surface.Row_Count = 0
        and then Surface.Bounded
        and then To_String (Surface.Summary_Label) = "Configuration recovery clean";
   end Assert_Recovery_State_Not_Persisted;


   function Assert_Save_Clean_Failure_Status_Is_Exception_Contained return Boolean is
      S : constant Domain_Recovery_Status := Status_From_Settings
        (Editor.Settings.Settings_Write_Error);
      K : constant Domain_Recovery_Status := Status_From_Keybindings
        (Editor.Keybinding_Config.Keybinding_Config_Write_Error);
      W : constant Domain_Recovery_Status := Status_From_Workspace
        (Editor.Workspace_Persistence.Workspace_Persistence_Write_Error);
      R : constant Domain_Recovery_Status := Status_From_Recent_Projects
        (Editor.Recent_Projects.Recent_Project_Write_Error);
   begin
      return S.Domain = Settings_Domain
        and then K.Domain = Keybindings_Domain
        and then W.Domain = Workspace_Domain
        and then R.Domain = Recent_Projects_Domain
        and then S.Error_Count = 1
        and then K.Error_Count = 1
        and then W.Error_Count = 1
        and then R.Error_Count = 1
        and then S.Action = Save_Clean_Available
        and then K.Action = Save_Clean_Available
        and then W.Action = Save_Clean_Available
        and then R.Action = Save_Clean_Available
        and then not S.Safe_Defaults_Active
        and then not K.Safe_Defaults_Active
        and then not W.Safe_Defaults_Active
        and then not R.Safe_Defaults_Active;
   end Assert_Save_Clean_Failure_Status_Is_Exception_Contained;

   function Assert_Recovery_Keybindings_Have_No_Payloads return Boolean is
      Catalog : constant Recovery_Command_Catalog := Build_Recovery_Command_Catalog;
   begin
      for I in 1 .. Catalog.Row_Count loop
         if not Catalog.Rows (I).No_Payload then
            return False;
         end if;
      end loop;
      return Editor.Keybinding_Config.Keybinding_Value_Has_Unsupported_Payload
          ("Ctrl+S:{payload}")
        and then not Editor.Keybinding_Config.Keybinding_Value_Has_Unsupported_Payload
          ("Ctrl+S");
   end Assert_Recovery_Keybindings_Have_No_Payloads;


   function Assert_Reset_All_Requires_Confirmation return Boolean is
      S : Editor.Settings.Settings_Model;
      K : Editor.Keybinding_Config.Keybinding_Config_Model;
      W : Editor.Workspace_Persistence.Workspace_Snapshot;
      R : Editor.Recent_Projects.Recent_Project_List;
      Summary : Configuration_Recovery_Summary;
      Denied  : Recovery_Command_Availability;
      Allowed : Recovery_Command_Availability;
   begin
      Editor.Settings.Set_Defaults (S);
      Editor.Keybinding_Config.Set_Defaults (K);
      Editor.Workspace_Persistence.Clear (W);
      Editor.Recent_Projects.Clear (R);

      Reset_All_Domains (S, K, W, R, False, Summary);
      if Summary.Domain_Count /= 1
        or else Summary.Rows (1).Load_Status /= Domain_Reset_Required
        or else Summary.Rows (1).Action /= Explicit_Reset_All_Required
      then
         return False;
      end if;

      Denied := Recovery_Command_Availability_For
        (Recovery_Action_Confirm_Reset_All, Summary, Reset_All_Confirmation => False);
      Allowed := Recovery_Command_Availability_For
        (Recovery_Action_Reset_All, Summary, Reset_All_Confirmation => False);
      if Denied.Available or else not Allowed.Available then
         return False;
      end if;

      Request_Reset_All_Confirmation;
      Denied := Recovery_Command_Availability_For
        (Recovery_Action_Reset_All, Summary,
         Reset_All_Confirmation => Has_Pending_Reset_All_Confirmation);
      Allowed := Recovery_Command_Availability_For
        (Recovery_Action_Confirm_Reset_All, Summary,
         Reset_All_Confirmation => Has_Pending_Reset_All_Confirmation);
      if Denied.Available or else not Allowed.Available
        or else not Has_Pending_Reset_All_Confirmation
      then
         Clear_Reset_All_Confirmation;
         return False;
      end if;
      Clear_Reset_All_Confirmation;

      Reset_All_Domains (S, K, W, R, True, Summary);
      return Summary.Domain_Count = 5
        and then Summary.Rows (1).Domain = Settings_Domain
        and then Summary.Rows (2).Domain = Keybindings_Domain
        and then Summary.Rows (3).Domain = Workspace_Domain
        and then Summary.Rows (4).Domain = Recent_Projects_Domain;
   end Assert_Reset_All_Requires_Confirmation;

   function Assert_Recovery_Command_Catalog_Is_Payload_Free return Boolean is
      Catalog : constant Recovery_Command_Catalog := Build_Recovery_Command_Catalog;
      Saw_Reset_All : Boolean := False;
      Saw_Save_Clean_Keybindings : Boolean := False;
   begin
      if Catalog.Row_Count /= Max_Recovery_Command_Rows
        or else Catalog.Payload_Command_Count /= 0
        or else Catalog.Reset_Count /= 5
        or else Catalog.Save_Clean_Count /= 4
        or else Catalog.Confirmation_Count /= 3
      then
         return False;
      end if;

      for I in 1 .. Catalog.Row_Count loop
         declare
            Row : constant Recovery_Command_Row := Catalog.Rows (I);
            Name : constant String := To_String (Row.Stable_Name);
         begin
            if Name'Length = 0 or else not Row.No_Payload then
               return False;
            end if;
            if Name = "configuration.reset-all" then
               Saw_Reset_All := Row.Requires_Confirmation and then Row.Reset_Action;
            elsif Name = "configuration.save-clean-keybindings" then
               Saw_Save_Clean_Keybindings := Row.Save_Clean_Action
                 and then Row.Domain = Keybindings_Domain;
            end if;
         end;
      end loop;

      return Saw_Reset_All and then Saw_Save_Clean_Keybindings;
   end Assert_Recovery_Command_Catalog_Is_Payload_Free;

   function Assert_Load_All_Domains_Contains_Failures return Boolean is
      S : Editor.Settings.Settings_Model;
      K : Editor.Keybinding_Config.Keybinding_Config_Model;
      W : Editor.Workspace_Persistence.Workspace_Snapshot;
      R : Editor.Recent_Projects.Recent_Project_List;
      Summary : Configuration_Recovery_Summary;
   begin
      Load_All_Domains_Safely
        ("/definitely/missing/settings",
         "/definitely/missing/keybindings",
         "/definitely/missing/workspace",
         "/definitely/missing/recent",
         S, K, W, R, Summary);
      return Summary.Domain_Count = Max_Recovery_Domains
        and then Summary.Domains_With_Defaults_Count >= 4
        and then Summary.Rows (1).Missing_File
        and then Summary.Rows (2).Missing_File
        and then Summary.Rows (3).Missing_File
        and then Summary.Rows (4).Missing_File
        and then Summary.Rows (5).Domain = Command_Routes_Domain
        and then Summary.Rows (6).Domain = Runtime_Defaults_Domain;
   end Assert_Load_All_Domains_Contains_Failures;


   function Assert_Recorded_Recovery_Summary_Is_Transient return Boolean is
      Summary : Configuration_Recovery_Summary;
      S : Editor.Settings.Settings_Model;
      K : Editor.Keybinding_Config.Keybinding_Config_Model;
      W : Editor.Workspace_Persistence.Workspace_Snapshot;
      R : Editor.Recent_Projects.Recent_Project_List;
   begin
      Clear_Recorded_Recovery_Summary;
      if Has_Recorded_Recovery_Summary then
         return False;
      end if;

      Load_All_Domains_Safely
        ("/definitely/missing/settings",
         "/definitely/missing/keybindings",
         "/definitely/missing/workspace",
         "/definitely/missing/recent",
         S, K, W, R, Summary);

      if not Has_Recorded_Recovery_Summary
        or else Current_Recovery_Summary.Domain_Count /= Summary.Domain_Count
      then
         return False;
      end if;

      Clear_Recorded_Recovery_Summary;
      return not Has_Recorded_Recovery_Summary
        and then Current_Recovery_Summary.Domain_Count = 0;
   end Assert_Recorded_Recovery_Summary_Is_Transient;

   function Assert_Recovery_Runtime_State_Clear_Is_Local return Boolean is
      Summary : Configuration_Recovery_Summary;
   begin
      Append (Summary, Issue_Row
        (Settings_Domain, Domain_Loaded_With_Defaults, Use_Safe_Defaults,
         "Settings defaults active.", Warnings => 1));
      Record_Recovery_Summary (Summary);
      Request_Reset_All_Confirmation;

      if not Has_Recorded_Recovery_Summary
        or else not Has_Pending_Reset_All_Confirmation
      then
         return False;
      end if;

      Clear_Recovery_Runtime_State;
      return not Has_Recorded_Recovery_Summary
        and then not Has_Pending_Reset_All_Confirmation
        and then Current_Recovery_Summary.Domain_Count = 0;
   end Assert_Recovery_Runtime_State_Clear_Is_Local;

   function Assert_Clean_Summary_Disables_Reset_And_Save_Clean return Boolean is
      Summary : Configuration_Recovery_Summary;
      Reset_Settings : Recovery_Command_Availability;
      Save_Settings  : Recovery_Command_Availability;
      Reset_All      : Recovery_Command_Availability;
   begin
      Append (Summary, Issue_Row
        (Settings_Domain, Domain_Ok, No_Recovery_Action,
         "Settings are valid."));
      Append (Summary, Issue_Row
        (Keybindings_Domain, Domain_Ok, No_Recovery_Action,
         "Keybindings are valid."));

      Reset_Settings := Recovery_Command_Availability_For
        (Recovery_Action_Reset_Settings, Summary);
      Save_Settings := Recovery_Command_Availability_For
        (Recovery_Action_Save_Clean_Settings, Summary);
      Reset_All := Recovery_Command_Availability_For
        (Recovery_Action_Reset_All, Summary);

      return Recovery_Summary_Has_Only_Clean_Domains (Summary)
        and then not Reset_Settings.Available
        and then not Save_Settings.Available
        and then not Reset_All.Available
        and then To_String (Reset_Settings.Reason) = "Domain already clean."
        and then To_String (Save_Settings.Reason) = "Domain already clean."
        and then To_String (Reset_All.Reason) = "No recovery issues.";
   end Assert_Clean_Summary_Disables_Reset_And_Save_Clean;

   function Assert_Domain_Local_Status_Record_Is_Bounded return Boolean is
      Summary : Configuration_Recovery_Summary;
      Runtime_Row : Domain_Recovery_Status;
      Settings_Row : Domain_Recovery_Status;
   begin
      Runtime_Row := Issue_Row
        (Runtime_Defaults_Domain, Domain_Ok, No_Recovery_Action,
         "Runtime defaults available.");
      Settings_Row := Issue_Row
        (Settings_Domain, Domain_Loaded_With_Defaults, Use_Safe_Defaults,
         "Settings reset to defaults.", Warnings => 1);

      Append_Domain_Local_Status (Summary, Runtime_Row);
      Append_Domain_Local_Status (Summary, Settings_Row);

      return Summary.Domain_Count = 1
        and then Summary.Rows (1).Domain = Settings_Domain
        and then Summary.Bounded;
   end Assert_Domain_Local_Status_Record_Is_Bounded;

   function Assert_Recovery_Messages_Are_Bounded return Boolean is
      Long_Text : constant String (1 .. Max_Recovery_Message_Length + 40) :=
        (others => 'x');
      Row       : Domain_Recovery_Status;
      Summary   : Configuration_Recovery_Summary;
      Recorded  : Configuration_Recovery_Summary;
   begin
      Row := Issue_Row
        (Settings_Domain, Domain_Loaded_With_Warnings, Ignore_Unsupported_Fields,
         Long_Text, Warnings => 1);
      if not Recovery_Message_Is_Bounded (Row) then
         return False;
      end if;

      Row.User_Action_Suggestion := To_Unbounded_String (Long_Text);
      Append (Summary, Row);
      if not Recovery_Message_Is_Bounded (Summary.Rows (1)) then
         return False;
      end if;

      Record_Recovery_Summary (Summary);
      Recorded := Current_Recovery_Summary;
      return Recorded.Domain_Count = 1
        and then Recovery_Message_Is_Bounded (Recorded.Rows (1));
   end Assert_Recovery_Messages_Are_Bounded;

   function Assert_Recovery_Availability_Blocks_Domain_Mutation_While_Pending return Boolean is
      Summary : Configuration_Recovery_Summary;
      Reset_Settings : Recovery_Command_Availability;
      Save_Settings  : Recovery_Command_Availability;
      Show_Recovery  : Recovery_Command_Availability;
      Confirm_All    : Recovery_Command_Availability;
   begin
      Append (Summary, Issue_Row
        (Settings_Domain, Domain_Loaded_With_Defaults, Use_Safe_Defaults,
         "Settings defaults active.", Warnings => 1));

      Reset_Settings := Recovery_Command_Availability_For
        (Recovery_Action_Reset_Settings, Summary, Reset_All_Confirmation => True);
      Save_Settings := Recovery_Command_Availability_For
        (Recovery_Action_Save_Clean_Settings, Summary, Reset_All_Confirmation => True);
      Show_Recovery := Recovery_Command_Availability_For
        (Recovery_Action_Show, Summary, Reset_All_Confirmation => True);
      Confirm_All := Recovery_Command_Availability_For
        (Recovery_Action_Confirm_Reset_All, Summary, Reset_All_Confirmation => True);

      return not Reset_Settings.Available
        and then not Save_Settings.Available
        and then To_String (Reset_Settings.Reason) =
          "Command unavailable while confirmation is pending."
        and then To_String (Save_Settings.Reason) =
          "Command unavailable while confirmation is pending."
        and then Show_Recovery.Available
        and then Confirm_All.Available;
   end Assert_Recovery_Availability_Blocks_Domain_Mutation_While_Pending;


   function Assert_Reset_All_Keybinding_Failure_Status_Is_Not_Fabricated return Boolean is
      Row : Domain_Recovery_Status := Status_From_Keybindings
        (Editor.Keybinding_Config.Keybinding_Config_Write_Error);
   begin
      Row.User_Action_Suggestion := To_Unbounded_String
        ("Keybindings reset failed during reset-all confirmation; keybinding runtime state was left unchanged.");

      return Row.Domain = Keybindings_Domain
        and then Row.Load_Status = Domain_Reset_Available
        and then Row.Action = Save_Clean_Available
        and then Row.Error_Count > 0
        and then not Row.Safe_Defaults_Active
        and then To_String (Row.User_Action_Suggestion) /= "Keybindings reset to defaults.";
   end Assert_Reset_All_Keybinding_Failure_Status_Is_Not_Fabricated;


   function Assert_Configuration_Recovery_Coherent return Boolean is
   begin
      return Assert_Configuration_Domains_Load_Independently
        and then Assert_Safe_Defaults_Are_Always_Available
        and then Assert_Recovery_Commands_Do_Not_Cross_Write_Domains
        and then Assert_Reset_All_Requires_Confirmation
        and then Assert_Recovery_Command_Catalog_Is_Payload_Free
        and then Assert_Load_All_Domains_Contains_Failures
        and then Assert_Surface_Contains_Actionable_Domain_Details
        and then Assert_Save_Clean_Status_Is_Domain_Local
        and then Assert_Recovery_Command_Availability_Is_Domain_Local
        and then Assert_Recovery_Summary_Overflow_Is_Bounded
        and then Assert_Settings_Recovery_Counts_Are_Actionable
        and then Assert_Recent_Projects_Partial_Load_Is_Preserved
        and then Assert_Configuration_Recovery_Render_Is_Side_Effect_Free
        and then Assert_Recovery_State_Not_Persisted
        and then Assert_Recorded_Recovery_Summary_Is_Transient
        and then Assert_Recovery_Runtime_State_Clear_Is_Local
        and then Assert_Clean_Summary_Disables_Reset_And_Save_Clean
        and then Assert_Domain_Local_Status_Record_Is_Bounded
        and then Assert_Save_Clean_Failure_Status_Is_Exception_Contained
        and then Assert_Recovery_Messages_Are_Bounded
        and then Assert_Recovery_Availability_Blocks_Domain_Mutation_While_Pending
        and then Assert_Reset_All_Keybinding_Failure_Status_Is_Not_Fabricated
        and then Assert_Recovery_Keybindings_Have_No_Payloads;
   end Assert_Configuration_Recovery_Coherent;

end Editor.Configuration_Recovery;
