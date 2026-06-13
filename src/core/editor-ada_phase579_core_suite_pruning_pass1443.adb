with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Phase579_Core_Suite_Pruning_Pass1443 is

   procedure Add_Row (Input : in out Prune_Input; Row : Prune_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Row;

   function Class_For_Status (Status : Prune_Status) return Prune_Class is
   begin
      case Status is
         when Status_Kept_Canonical_Test
            | Status_Kept_Regression_Test
            | Status_Kept_Cleanup_Gate_Test
            | Status_Pruned_Removed_Legacy_Test
            | Status_Pruned_Quarantined_Legacy_Test
            | Status_Removed_Legacy_Test_Files
            | Status_Kept_Unregistered_Evidence =>
            return Class_Accepted;
         when Status_Rejected_Missing_Justification
            | Status_Rejected_Missing_Registered_Test
            | Status_Rejected_Stale_Legacy_Registration
            | Status_Rejected_Test_File_Dangling_Active
            | Status_Rejected_Removed_Test_File_Still_Present
            | Status_Rejected_Reopened_Remaining_Gap
            | Status_Rejected_Command_Alias
            | Status_Rejected_Fingerprint_Mismatch =>
            return Class_Rejected;
         when Status_Indeterminate_Unknown_Surface
            | Status_Indeterminate_Unknown_Action =>
            return Class_Indeterminate;
         when Status_Not_Checked =>
            return Class_Unknown;
      end case;
   end Class_For_Status;

   function Fingerprints_Fresh (Row : Prune_Row) return Boolean is
   begin
      return Row.Suite_Fingerprint = Row.Expected_Suite_Fingerprint
        and then Row.Test_Fingerprint = Row.Expected_Test_Fingerprint
        and then Row.Inventory_Fingerprint = Row.Expected_Inventory_Fingerprint;
   end Fingerprints_Fresh;

   function Has_Justification (Row : Prune_Row) return Boolean is
   begin
      return Length (Row.Package_Name) > 0
        and then Length (Row.Test_Package_Name) > 0
        and then Length (Row.Justification) > 0
        and then Length (Row.Blocker_Family) > 0;
   end Has_Justification;

   function Is_Registered (Row : Prune_Row) return Boolean is
   begin
      return Row.Suite_With_Present and then Row.Suite_Add_Test_Present;
   end Is_Registered;

   function Has_Test_Files (Row : Prune_Row) return Boolean is
   begin
      return Row.Test_Spec_Present and then Row.Test_Body_Present;
   end Has_Test_Files;

   function Evaluate (Row : Prune_Row) return Prune_Status is
   begin
      if Row.Surface = Surface_Unknown then
         return Status_Indeterminate_Unknown_Surface;
      elsif Row.Action = Action_Unknown then
         return Status_Indeterminate_Unknown_Action;
      elsif not Has_Justification (Row) then
         return Status_Rejected_Missing_Justification;
      elsif Row.Reopens_Remaining_Gap then
         return Status_Rejected_Reopened_Remaining_Gap;
      elsif Row.Adds_Command_Alias then
         return Status_Rejected_Command_Alias;
      elsif not Fingerprints_Fresh (Row) then
         return Status_Rejected_Fingerprint_Mismatch;
      end if;

      case Row.Action is
         when Action_Keep_Registered =>
            if not Is_Registered (Row) or else not Has_Test_Files (Row) then
               return Status_Rejected_Missing_Registered_Test;
            elsif Row.Removed_Legacy_Surface
              or else Row.Quarantined_Legacy_Surface
            then
               return Status_Rejected_Stale_Legacy_Registration;
            elsif Row.Surface = Surface_Canonical_Production then
               return Status_Kept_Canonical_Test;
            elsif Row.Surface = Surface_Regression_Evidence
              and then Row.Meaningful_Regression_Evidence
            then
               return Status_Kept_Regression_Test;
            elsif Row.Surface = Surface_Cleanup_Gate then
               return Status_Kept_Cleanup_Gate_Test;
            else
               return Status_Rejected_Missing_Justification;
            end if;

         when Action_Prune_From_Core_Suite =>
            if Is_Registered (Row) then
               return Status_Rejected_Stale_Legacy_Registration;
            elsif not Has_Test_Files (Row) then
               return Status_Rejected_Test_File_Dangling_Active;
            elsif Row.Surface = Surface_Removed_Legacy
              and then Row.Removed_Legacy_Surface
            then
               return Status_Pruned_Removed_Legacy_Test;
            elsif Row.Surface = Surface_Quarantined_Legacy
              and then Row.Quarantined_Legacy_Surface
            then
               return Status_Pruned_Quarantined_Legacy_Test;
            else
               return Status_Rejected_Missing_Justification;
            end if;

         when Action_Remove_Test_Files =>
            if Has_Test_Files (Row) or else Is_Registered (Row) then
               return Status_Rejected_Removed_Test_File_Still_Present;
            elsif Row.Removed_Legacy_Surface then
               return Status_Removed_Legacy_Test_Files;
            else
               return Status_Rejected_Missing_Justification;
            end if;

         when Action_Keep_Unregistered_Evidence =>
            if Is_Registered (Row) then
               return Status_Rejected_Stale_Legacy_Registration;
            elsif not Has_Test_Files (Row)
              or else not Row.Meaningful_Regression_Evidence
            then
               return Status_Rejected_Test_File_Dangling_Active;
            else
               return Status_Kept_Unregistered_Evidence;
            end if;

         when Action_Unknown =>
            return Status_Indeterminate_Unknown_Action;
      end case;
   end Evaluate;

   function Result_Fingerprint (Row : Prune_Row; Status : Prune_Status)
                                return Natural is
   begin
      return Row.Id * 29
        + Prune_Status'Pos (Status) * 31
        + Suite_Surface'Pos (Row.Surface) * 37
        + Prune_Action'Pos (Row.Action) * 41
        + Row.Suite_Fingerprint
        + Row.Test_Fingerprint
        + Row.Inventory_Fingerprint;
   end Result_Fingerprint;

   function Build (Input : Prune_Input) return Prune_Model is
      Model : Prune_Model;
      Status : Prune_Status;
      Feed_Item : Prune_Entry;
   begin
      for Row of Input.Rows loop
         Status := Evaluate (Row);
         Feed_Item :=
           (Id => Row.Id,
            Status => Status,
            Result_Class => Class_For_Status (Status),
            Result_Fingerprint => Result_Fingerprint (Row, Status));
         Model.Entries.Append (Feed_Item);
         Model.Total_Rows := Model.Total_Rows + 1;
         Model.Suite_Audit_Fingerprint :=
           Model.Suite_Audit_Fingerprint + Feed_Item.Result_Fingerprint;

         case Status is
            when Status_Kept_Canonical_Test
               | Status_Kept_Regression_Test
               | Status_Kept_Cleanup_Gate_Test =>
               Model.Kept_Registered_Count := Model.Kept_Registered_Count + 1;
            when Status_Pruned_Removed_Legacy_Test
               | Status_Pruned_Quarantined_Legacy_Test =>
               Model.Pruned_From_Suite_Count := Model.Pruned_From_Suite_Count + 1;
            when Status_Removed_Legacy_Test_Files =>
               Model.Removed_Test_File_Count := Model.Removed_Test_File_Count + 1;
            when Status_Kept_Unregistered_Evidence =>
               Model.Unregistered_Evidence_Count :=
                 Model.Unregistered_Evidence_Count + 1;
            when Status_Rejected_Missing_Justification
               | Status_Rejected_Missing_Registered_Test
               | Status_Rejected_Stale_Legacy_Registration
               | Status_Rejected_Test_File_Dangling_Active
               | Status_Rejected_Removed_Test_File_Still_Present
               | Status_Rejected_Reopened_Remaining_Gap
               | Status_Rejected_Command_Alias
               | Status_Rejected_Fingerprint_Mismatch =>
               Model.Rejected_Count := Model.Rejected_Count + 1;
            when Status_Indeterminate_Unknown_Surface
               | Status_Indeterminate_Unknown_Action =>
               Model.Indeterminate_Count := Model.Indeterminate_Count + 1;
            when Status_Not_Checked =>
               null;
         end case;
      end loop;
      return Model;
   end Build;

   function Result_For (Model : Prune_Model; Id : Natural) return Prune_Entry is
   begin
      for Feed_Item of Model.Entries loop
         if Feed_Item.Id = Id then
            return Feed_Item;
         end if;
      end loop;
      return (others => <>);
   end Result_For;

   function Core_Suite_Pruned (Model : Prune_Model) return Boolean is
   begin
      return Model.Total_Rows >= 7
        and then Model.Kept_Registered_Count >= 3
        and then Model.Pruned_From_Suite_Count >= 3
        and then Model.Removed_Test_File_Count >= 1
        and then Model.Rejected_Count = 0
        and then Model.Indeterminate_Count = 0
        and then Model.Suite_Audit_Fingerprint /= 0;
   end Core_Suite_Pruned;

   function Ready_For_Documentation_Cleanup (Model : Prune_Model)
                                            return Boolean is
   begin
      return Core_Suite_Pruned (Model)
        and then Model.Unregistered_Evidence_Count >= 1;
   end Ready_For_Documentation_Cleanup;

end Editor.Ada_Phase579_Core_Suite_Pruning_Pass1443;
