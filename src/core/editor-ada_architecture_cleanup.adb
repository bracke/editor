with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Architecture_Cleanup is

   pragma Suppress (Overflow_Check);

   procedure Add_Row (Input : in out Cleanup_Input; Row : Cleanup_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Row;

   function Class_For_Status (Status : Cleanup_Status)
      return Cleanup_Result_Class is
   begin
      case Status is
         when Status_Canonical_Production_Surface
            | Status_Release_Documented
            | Status_Test_Harness_Covered =>
            return Class_Accepted;
         when Status_Quarantined_Historical_Scaffold =>
            return Class_Quarantined;
         when Status_Rejected_Command_Alias
            | Status_Rejected_Compatibility_Spelling
            | Status_Rejected_Render_Side_Parsing
            | Status_Rejected_Dirty_State_Mutation
            | Status_Rejected_Workspace_Keybinding_Render_Leak
            | Status_Rejected_Unowned_API_Surface
            | Status_Rejected_Obsolete_Scaffold_Export
            | Status_Rejected_Pass_Churn_Intent
            | Status_Rejected_Reopened_Remaining_Gap
            | Status_Rejected_Fingerprint_Mismatch
            | Status_Rejected_Duplicate_Surface =>
            return Class_Rejected;
         when Status_Indeterminate_Missing_Cleanup_Evidence =>
            return Class_Indeterminate;
         when Status_Not_Checked =>
            return Class_Unknown;
      end case;
   end Class_For_Status;

   function Fingerprints_Fresh (Row : Cleanup_Row) return Boolean is
   begin
      return Row.Source_Fingerprint = Row.Expected_Source_Fingerprint
        and then Row.API_Fingerprint = Row.Expected_API_Fingerprint
        and then Row.Cleanup_Fingerprint = Row.Expected_Cleanup_Fingerprint;
   end Fingerprints_Fresh;

   function Missing_Cleanup_Evidence (Row : Cleanup_Row) return Boolean is
   begin
      return Length (Row.Source_File) = 0
        or else Length (Row.Package_Name) = 0
        or else Length (Row.Canonical_Owner) = 0
        or else Length (Row.Final_Intent) = 0
        or else Length (Row.Blocker_Family) = 0;
   end Missing_Cleanup_Evidence;

   function Evaluate (Row : Cleanup_Row) return Cleanup_Status is
   begin
      if Missing_Cleanup_Evidence (Row) then
         return Status_Indeterminate_Missing_Cleanup_Evidence;
      elsif Row.Has_Command_Alias then
         return Status_Rejected_Command_Alias;
      elsif Row.Has_Compatibility_Spelling then
         return Status_Rejected_Compatibility_Spelling;
      elsif Row.Performs_Render_Side_Parsing then
         return Status_Rejected_Render_Side_Parsing;
      elsif Row.Mutates_Dirty_State_During_Analysis then
         return Status_Rejected_Dirty_State_Mutation;
      elsif Row.Mutates_Command_Palette_Keybindings_Workspace_Or_Render then
         return Status_Rejected_Workspace_Keybinding_Render_Leak;
      elsif Row.Reopens_Remaining_Gap then
         return Status_Rejected_Reopened_Remaining_Gap;
      elsif not Fingerprints_Fresh (Row) then
         return Status_Rejected_Fingerprint_Mismatch;
      elsif not Row.Final_Intent_Comment_Present or else not Row.Canonical_Name then
         return Status_Rejected_Pass_Churn_Intent;
      elsif not Row.Public_API_Owned then
         return Status_Rejected_Unowned_API_Surface;
      elsif Row.Is_Historical_Pass_Scaffold then
         if Row.Quarantined
           and then not Row.Exported_To_Production
           and then Length (Row.Quarantine_Reason) > 0
         then
            return Status_Quarantined_Historical_Scaffold;
         else
            return Status_Rejected_Obsolete_Scaffold_Export;
         end if;
      elsif Row.Is_Release_Document or else Row.Surface = Surface_Release_Document then
         if Row.Release_Doc_Present then
            return Status_Release_Documented;
         else
            return Status_Indeterminate_Missing_Cleanup_Evidence;
         end if;
      elsif Row.Is_Test_Surface or else Row.Surface = Surface_Test_Harness then
         if Row.Test_Coverage_Present and then Row.Registered_In_Suite then
            return Status_Test_Harness_Covered;
         else
            return Status_Indeterminate_Missing_Cleanup_Evidence;
         end if;
      elsif Row.Is_Production_Surface then
         return Status_Canonical_Production_Surface;
      else
         return Status_Indeterminate_Missing_Cleanup_Evidence;
      end if;
   end Evaluate;

   function Result_Fingerprint_For
     (Row : Cleanup_Row; Status : Cleanup_Status) return Natural is
   begin
      return Row.Id * 83
        + Architecture_Surface'Pos (Row.Surface) * 47
        + Cleanup_Status'Pos (Status) * 31
        + Row.Source_Fingerprint
        + Row.API_Fingerprint
        + Row.Cleanup_Fingerprint;
   end Result_Fingerprint_For;

   procedure Tally (Model : in out Cleanup_Model; Feed_Item : Cleanup_Entry) is
   begin
      case Feed_Item.Status is
         when Status_Canonical_Production_Surface =>
            Model.Canonical_Count := Model.Canonical_Count + 1;
         when Status_Quarantined_Historical_Scaffold =>
            Model.Quarantined_Count := Model.Quarantined_Count + 1;
         when Status_Release_Documented =>
            Model.Documented_Count := Model.Documented_Count + 1;
         when Status_Test_Harness_Covered =>
            Model.Test_Count := Model.Test_Count + 1;
         when Status_Rejected_Command_Alias
            | Status_Rejected_Compatibility_Spelling
            | Status_Rejected_Render_Side_Parsing
            | Status_Rejected_Dirty_State_Mutation
            | Status_Rejected_Workspace_Keybinding_Render_Leak
            | Status_Rejected_Unowned_API_Surface
            | Status_Rejected_Obsolete_Scaffold_Export
            | Status_Rejected_Pass_Churn_Intent
            | Status_Rejected_Reopened_Remaining_Gap
            | Status_Rejected_Fingerprint_Mismatch
            | Status_Rejected_Duplicate_Surface =>
            Model.Rejected_Count := Model.Rejected_Count + 1;
         when Status_Indeterminate_Missing_Cleanup_Evidence =>
            Model.Indeterminate_Count := Model.Indeterminate_Count + 1;
         when Status_Not_Checked =>
            null;
      end case;
   end Tally;

   function Build (Input : Cleanup_Input) return Cleanup_Model is
      function Is_Required_Surface (Surface : Architecture_Surface) return Boolean is
      begin
         return Surface /= Surface_Unknown;
      end Is_Required_Surface;

      function Required_Surface_Total return Natural is
         Count : Natural := 0;
      begin
         for Surface in Architecture_Surface loop
            if Is_Required_Surface (Surface) then
               Count := Count + 1;
            end if;
         end loop;
         return Count;
      end Required_Surface_Total;

      function Is_Coverage_Status (Status : Cleanup_Status) return Boolean is
      begin
         case Status is
            when Status_Canonical_Production_Surface
               | Status_Quarantined_Historical_Scaffold
               | Status_Release_Documented
               | Status_Test_Harness_Covered =>
               return True;
            when others =>
               return False;
         end case;
      end Is_Coverage_Status;

      Seen : array (Architecture_Surface) of Boolean := (others => False);
      Model : Cleanup_Model;
   begin
      Model.Required_Surface_Count := Required_Surface_Total;
      for Row of Input.Rows loop
         declare
            Status : Cleanup_Status := Evaluate (Row);
            Feed_Item : Cleanup_Entry;
         begin
            if Is_Coverage_Status (Status) and then Is_Required_Surface (Row.Surface) then
               if Seen (Row.Surface) then
                  Status := Status_Rejected_Duplicate_Surface;
                  Model.Duplicate_Surface_Count := Model.Duplicate_Surface_Count + 1;
               else
                  Seen (Row.Surface) := True;
               end if;
            end if;

            Feed_Item.Id := Row.Id;
            Feed_Item.Surface := Row.Surface;
            Feed_Item.Status := Status;
            Feed_Item.Result_Class := Class_For_Status (Status);
            Feed_Item.Result_Fingerprint := Result_Fingerprint_For (Row, Status);

            Model.Entries.Append (Feed_Item);
            Model.Total_Rows := Model.Total_Rows + 1;
            Model.Audit_Fingerprint := Model.Audit_Fingerprint + Feed_Item.Result_Fingerprint;
            Tally (Model, Feed_Item);
         end;
      end loop;
      for Surface in Architecture_Surface loop
         if Is_Required_Surface (Surface) and then not Seen (Surface) then
            Model.Missing_Surface_Count := Model.Missing_Surface_Count + 1;
         end if;
      end loop;
      return Model;
   end Build;

   function Result_For (Model : Cleanup_Model; Id : Natural) return Cleanup_Entry is
   begin
      for Feed_Item of Model.Entries loop
         if Feed_Item.Id = Id then
            return Feed_Item;
         end if;
      end loop;
      return (Id => Id,
              Surface => Surface_Unknown,
              Status => Status_Not_Checked,
              Result_Class => Class_Unknown,
              Result_Fingerprint => 0);
   end Result_For;

   function Final_Cleanup_Achieved (Model : Cleanup_Model) return Boolean is
   begin
      return Model.Total_Rows = Model.Required_Surface_Count
        and then Model.Required_Surface_Count = 10
        and then Model.Canonical_Count = 7
        and then Model.Quarantined_Count = 1
        and then Model.Documented_Count = 1
        and then Model.Test_Count = 1
        and then Model.Rejected_Count = 0
        and then Model.Indeterminate_Count = 0
        and then Model.Missing_Surface_Count = 0
        and then Model.Duplicate_Surface_Count = 0;
   end Final_Cleanup_Achieved;

end Editor.Ada_Architecture_Cleanup;
