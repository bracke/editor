with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Phase579_Documentation_Cleanup_Pass1444 is

   pragma Suppress (Overflow_Check);

   procedure Add_Row (Input : in out Documentation_Input; Row : Documentation_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Row;

   function Class_For_Status (Status : Documentation_Status)
                              return Documentation_Class is
   begin
      case Status is
         when Status_Canonical_Map_Accepted
            | Status_Release_Gate_Accepted
            | Status_Validation_Report_Accepted
            | Status_Cleanup_Ledger_Accepted
            | Status_Historical_Note_Archived =>
            return Class_Accepted;
         when Status_Rejected_Missing_Canonical_Owner
            | Status_Rejected_Reopened_Remaining_Gap
            | Status_Rejected_Speculative_Semantic_Edge
            | Status_Rejected_Stale_Documentation
            | Status_Rejected_Missing_Architecture_Map
            | Status_Rejected_Contradicts_Core_Suite
            | Status_Rejected_Fingerprint_Mismatch =>
            return Class_Rejected;
         when Status_Indeterminate_Unknown_Kind
            | Status_Indeterminate_Unknown_Action =>
            return Class_Indeterminate;
         when Status_Not_Checked =>
            return Class_Unknown;
      end case;
   end Class_For_Status;

   function Fingerprints_Fresh (Row : Documentation_Row) return Boolean is
   begin
      return Row.Source_Fingerprint = Row.Expected_Source_Fingerprint
        and then Row.Documentation_Fingerprint =
          Row.Expected_Documentation_Fingerprint
        and then Row.Suite_Fingerprint = Row.Expected_Suite_Fingerprint;
   end Fingerprints_Fresh;

   function Has_Required_Text (Row : Documentation_Row) return Boolean is
   begin
      return Length (Row.Path) > 0
        and then Length (Row.Canonical_Owner) > 0
        and then Length (Row.Summary) > 0
        and then Length (Row.Blocker_Family) > 0;
   end Has_Required_Text;

   function Evaluate (Row : Documentation_Row) return Documentation_Status is
   begin
      if Row.Kind = Kind_Unknown then
         return Status_Indeterminate_Unknown_Kind;
      elsif Row.Action = Action_Unknown then
         return Status_Indeterminate_Unknown_Action;
      elsif not Has_Required_Text (Row) then
         return Status_Rejected_Missing_Canonical_Owner;
      elsif Row.Reopens_Remaining_Gap then
         return Status_Rejected_Reopened_Remaining_Gap;
      elsif Row.Adds_Speculative_Semantic_Edge then
         return Status_Rejected_Speculative_Semantic_Edge;
      elsif Row.Stale_Documentation then
         return Status_Rejected_Stale_Documentation;
      elsif Row.Contradicts_Core_Suite then
         return Status_Rejected_Contradicts_Core_Suite;
      elsif not Fingerprints_Fresh (Row) then
         return Status_Rejected_Fingerprint_Mismatch;
      end if;

      case Row.Action is
         when Action_Keep_Canonical =>
            if not Row.Document_Present
              or else not Row.Architecture_Map_Present
              or else not Row.References_Canonical_API
            then
               return Status_Rejected_Missing_Architecture_Map;
            elsif Row.Kind = Kind_Canonical_Architecture_Map then
               return Status_Canonical_Map_Accepted;
            else
               return Status_Rejected_Missing_Canonical_Owner;
            end if;

         when Action_Keep_Release_Evidence =>
            if not Row.Document_Present
              or else not Row.Architecture_Map_Present
              or else not Row.References_Core_Suite_Prune
            then
               return Status_Rejected_Missing_Architecture_Map;
            elsif Row.Kind = Kind_Release_Gate then
               return Status_Release_Gate_Accepted;
            elsif Row.Kind = Kind_Validation_Report then
               return Status_Validation_Report_Accepted;
            elsif Row.Kind = Kind_Cleanup_Ledger then
               return Status_Cleanup_Ledger_Accepted;
            else
               return Status_Rejected_Missing_Canonical_Owner;
            end if;

         when Action_Archive_Historical_Note =>
            if Row.Document_Present and then Row.Historical_Only then
               return Status_Historical_Note_Archived;
            else
               return Status_Rejected_Missing_Canonical_Owner;
            end if;

         when Action_Reject_Stale_Note =>
            return Status_Rejected_Stale_Documentation;

         when Action_Unknown =>
            return Status_Indeterminate_Unknown_Action;
      end case;
   end Evaluate;

   function Result_Fingerprint
     (Row : Documentation_Row; Status : Documentation_Status) return Natural is
   begin
      return Row.Id * 43
        + Document_Kind'Pos (Row.Kind) * 47
        + Documentation_Action'Pos (Row.Action) * 53
        + Documentation_Status'Pos (Status) * 59
        + Row.Source_Fingerprint
        + Row.Documentation_Fingerprint
        + Row.Suite_Fingerprint;
   end Result_Fingerprint;

   function Build (Input : Documentation_Input) return Documentation_Model is
      Model : Documentation_Model;
      Status : Documentation_Status;
      Feed_Item : Documentation_Entry;
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
         Model.Documentation_Audit_Fingerprint :=
           Model.Documentation_Audit_Fingerprint + Feed_Item.Result_Fingerprint;

         case Status is
            when Status_Canonical_Map_Accepted =>
               Model.Canonical_Count := Model.Canonical_Count + 1;
            when Status_Release_Gate_Accepted
               | Status_Validation_Report_Accepted
               | Status_Cleanup_Ledger_Accepted =>
               Model.Release_Evidence_Count := Model.Release_Evidence_Count + 1;
            when Status_Historical_Note_Archived =>
               Model.Archived_Historical_Count :=
                 Model.Archived_Historical_Count + 1;
            when Status_Rejected_Missing_Canonical_Owner
               | Status_Rejected_Reopened_Remaining_Gap
               | Status_Rejected_Speculative_Semantic_Edge
               | Status_Rejected_Stale_Documentation
               | Status_Rejected_Missing_Architecture_Map
               | Status_Rejected_Contradicts_Core_Suite
               | Status_Rejected_Fingerprint_Mismatch =>
               Model.Rejected_Count := Model.Rejected_Count + 1;
            when Status_Indeterminate_Unknown_Kind
               | Status_Indeterminate_Unknown_Action =>
               Model.Indeterminate_Count := Model.Indeterminate_Count + 1;
            when Status_Not_Checked =>
               null;
         end case;
      end loop;
      return Model;
   end Build;

   function Result_For (Model : Documentation_Model; Id : Natural)
                        return Documentation_Entry is
   begin
      for Feed_Item of Model.Entries loop
         if Feed_Item.Id = Id then
            return Feed_Item;
         end if;
      end loop;
      return (others => <>);
   end Result_For;

   function Documentation_Cleaned (Model : Documentation_Model) return Boolean is
   begin
      return Model.Total_Rows >= 6
        and then Model.Canonical_Count >= 1
        and then Model.Release_Evidence_Count >= 3
        and then Model.Archived_Historical_Count >= 1
        and then Model.Rejected_Count = 0
        and then Model.Indeterminate_Count = 0
        and then Model.Documentation_Audit_Fingerprint /= 0;
   end Documentation_Cleaned;

   function Ready_For_Final_Dead_Code_Sweep (Model : Documentation_Model)
                                           return Boolean is
   begin
      return Documentation_Cleaned (Model)
        and then Model.Release_Evidence_Count >= 4;
   end Ready_For_Final_Dead_Code_Sweep;

end Editor.Ada_Phase579_Documentation_Cleanup_Pass1444;
