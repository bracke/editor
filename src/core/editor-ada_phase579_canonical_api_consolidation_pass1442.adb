with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Phase579_Canonical_API_Consolidation_Pass1442 is

   procedure Add_Row (Input : in out API_Input; Row : API_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Row;

   function Class_For_Status (Status : API_Status) return API_Result_Class is
   begin
      case Status is
         when Status_Canonical_Production_API
            | Status_Canonical_Regression_Evidence
            | Status_Canonical_Cleanup_Gate
            | Status_Canonical_Removed_Legacy
            | Status_Canonical_Quarantined_Legacy =>
            return Class_Accepted;
         when Status_Rejected_Missing_Owner
            | Status_Rejected_Production_Alias
            | Status_Rejected_Legacy_Production_Leak
            | Status_Rejected_Removed_Surface_Reference
            | Status_Rejected_Reopened_Remaining_Gap
            | Status_Rejected_Missing_Test_Coverage
            | Status_Rejected_Missing_Documentation
            | Status_Rejected_Fingerprint_Mismatch =>
            return Class_Rejected;
         when Status_Indeterminate_Unknown_Role
            | Status_Indeterminate_Unknown_Family =>
            return Class_Indeterminate;
         when Status_Not_Checked =>
            return Class_Unknown;
      end case;
   end Class_For_Status;

   function Missing_Owner (Row : API_Row) return Boolean is
   begin
      return Length (Row.Package_Name) = 0
        or else Length (Row.Source_Path) = 0
        or else Length (Row.Canonical_Owner) = 0
        or else Length (Row.Public_Surface) = 0
        or else Length (Row.Blocker_Family) = 0;
   end Missing_Owner;

   function Fingerprints_Fresh (Row : API_Row) return Boolean is
   begin
      return Row.Source_Fingerprint = Row.Expected_Source_Fingerprint
        and then Row.Test_Fingerprint = Row.Expected_Test_Fingerprint
        and then Row.Documentation_Fingerprint =
          Row.Expected_Documentation_Fingerprint
        and then Row.API_Fingerprint = Row.Expected_API_Fingerprint;
   end Fingerprints_Fresh;

   function Production_Role_Consistent (Row : API_Row) return Boolean is
   begin
      return Row.Role = Role_Production_API
        and then Row.Production_Facing
        and then not Row.Regression_Only
        and then not Row.Cleanup_Only
        and then not Row.Removed_Legacy
        and then not Row.Quarantined_Legacy;
   end Production_Role_Consistent;

   function Evidence_Role_Consistent (Row : API_Row) return Boolean is
   begin
      return Row.Role = Role_Regression_Evidence
        and then Row.Regression_Only
        and then not Row.Production_Facing
        and then not Row.Removed_Legacy;
   end Evidence_Role_Consistent;

   function Cleanup_Role_Consistent (Row : API_Row) return Boolean is
   begin
      return Row.Role = Role_Cleanup_Gate
        and then Row.Cleanup_Only
        and then not Row.Production_Facing
        and then not Row.Removed_Legacy;
   end Cleanup_Role_Consistent;

   function Removed_Role_Consistent (Row : API_Row) return Boolean is
   begin
      return Row.Role = Role_Removed_Legacy
        and then Row.Removed_Legacy
        and then not Row.Production_Facing;
   end Removed_Role_Consistent;

   function Quarantined_Role_Consistent (Row : API_Row) return Boolean is
   begin
      return Row.Role = Role_Quarantined_Legacy
        and then Row.Quarantined_Legacy
        and then not Row.Production_Facing;
   end Quarantined_Role_Consistent;

   function Evaluate (Row : API_Row) return API_Status is
   begin
      if Row.Family = Family_Unknown then
         return Status_Indeterminate_Unknown_Family;
      elsif Row.Role = Role_Unknown then
         return Status_Indeterminate_Unknown_Role;
      elsif Missing_Owner (Row) then
         return Status_Rejected_Missing_Owner;
      elsif Row.Reopens_Remaining_Gap then
         return Status_Rejected_Reopened_Remaining_Gap;
      elsif Row.References_Removed_Surface then
         return Status_Rejected_Removed_Surface_Reference;
      elsif Row.Adds_Command_Alias then
         return Status_Rejected_Production_Alias;
      elsif Row.Legacy_Production_Leak then
         return Status_Rejected_Legacy_Production_Leak;
      elsif not Row.Has_Test_Coverage then
         return Status_Rejected_Missing_Test_Coverage;
      elsif not Row.Has_Documentation
        or else Length (Row.Documentation_Path) = 0
      then
         return Status_Rejected_Missing_Documentation;
      elsif not Fingerprints_Fresh (Row) then
         return Status_Rejected_Fingerprint_Mismatch;
      elsif Production_Role_Consistent (Row) then
         return Status_Canonical_Production_API;
      elsif Evidence_Role_Consistent (Row) then
         return Status_Canonical_Regression_Evidence;
      elsif Cleanup_Role_Consistent (Row) then
         return Status_Canonical_Cleanup_Gate;
      elsif Removed_Role_Consistent (Row) then
         return Status_Canonical_Removed_Legacy;
      elsif Quarantined_Role_Consistent (Row) then
         return Status_Canonical_Quarantined_Legacy;
      else
         return Status_Rejected_Legacy_Production_Leak;
      end if;
   end Evaluate;

   function Result_Fingerprint_For
     (Row : API_Row; Status : API_Status) return Natural is
   begin
      return Row.Id * 113
        + API_Family'Pos (Row.Family) * 73
        + API_Role'Pos (Row.Role) * 47
        + API_Status'Pos (Status) * 31
        + Row.Source_Fingerprint
        + Row.Test_Fingerprint
        + Row.Documentation_Fingerprint
        + Row.API_Fingerprint;
   end Result_Fingerprint_For;

   procedure Tally (Model : in out API_Model; Feed_Item : API_Entry) is
   begin
      case Feed_Item.Status is
         when Status_Canonical_Production_API =>
            Model.Production_API_Count := Model.Production_API_Count + 1;
         when Status_Canonical_Regression_Evidence =>
            Model.Regression_Evidence_Count :=
              Model.Regression_Evidence_Count + 1;
         when Status_Canonical_Cleanup_Gate =>
            Model.Cleanup_Gate_Count := Model.Cleanup_Gate_Count + 1;
         when Status_Canonical_Removed_Legacy =>
            Model.Removed_Legacy_Count := Model.Removed_Legacy_Count + 1;
         when Status_Canonical_Quarantined_Legacy =>
            Model.Quarantined_Legacy_Count :=
              Model.Quarantined_Legacy_Count + 1;
         when Status_Rejected_Missing_Owner
            | Status_Rejected_Production_Alias
            | Status_Rejected_Legacy_Production_Leak
            | Status_Rejected_Removed_Surface_Reference
            | Status_Rejected_Reopened_Remaining_Gap
            | Status_Rejected_Missing_Test_Coverage
            | Status_Rejected_Missing_Documentation
            | Status_Rejected_Fingerprint_Mismatch =>
            Model.Rejected_Count := Model.Rejected_Count + 1;
         when Status_Indeterminate_Unknown_Role
            | Status_Indeterminate_Unknown_Family =>
            Model.Indeterminate_Count := Model.Indeterminate_Count + 1;
         when Status_Not_Checked =>
            null;
      end case;
   end Tally;

   function Build (Input : API_Input) return API_Model is
      Model : API_Model;
   begin
      for Row of Input.Rows loop
         declare
            Status : constant API_Status := Evaluate (Row);
            Feed_Item : API_Entry;
         begin
            Feed_Item.Id := Row.Id;
            Feed_Item.Family := Row.Family;
            Feed_Item.Role := Row.Role;
            Feed_Item.Status := Status;
            Feed_Item.Result_Class := Class_For_Status (Status);
            Feed_Item.Result_Fingerprint := Result_Fingerprint_For (Row, Status);
            Model.Entries.Append (Feed_Item);
            Model.Total_Rows := Model.Total_Rows + 1;
            Model.API_Audit_Fingerprint :=
              Model.API_Audit_Fingerprint + Feed_Item.Result_Fingerprint;
            Tally (Model, Feed_Item);
         end;
      end loop;
      return Model;
   end Build;

   function Result_For (Model : API_Model; Id : Natural) return API_Entry is
   begin
      for Feed_Item of Model.Entries loop
         if Feed_Item.Id = Id then
            return Feed_Item;
         end if;
      end loop;
      return (others => <>);
   end Result_For;

   function Canonical_API_Consolidated (Model : API_Model) return Boolean is
   begin
      return Model.Total_Rows >= 10
        and then Model.Production_API_Count >= 5
        and then Model.Regression_Evidence_Count >= 2
        and then Model.Cleanup_Gate_Count >= 2
        and then Model.Removed_Legacy_Count >= 1
        and then Model.Rejected_Count = 0
        and then Model.Indeterminate_Count = 0
        and then Model.API_Audit_Fingerprint /= 0;
   end Canonical_API_Consolidated;

   function Ready_For_Core_Suite_Pruning (Model : API_Model) return Boolean is
   begin
      return Canonical_API_Consolidated (Model)
        and then Model.Quarantined_Legacy_Count >= 1;
   end Ready_For_Core_Suite_Pruning;

end Editor.Ada_Phase579_Canonical_API_Consolidation_Pass1442;
