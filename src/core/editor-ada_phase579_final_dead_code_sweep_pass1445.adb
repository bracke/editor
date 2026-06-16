with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Phase579_Final_Dead_Code_Sweep_Pass1445 is

   pragma Suppress (Overflow_Check);

   procedure Add_Row (Input : in out Sweep_Input; Row : Sweep_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Row;

   function Class_For_Status (Status : Sweep_Status) return Sweep_Class is
   begin
      case Status is
         when Status_Removed_Orphan
            | Status_Retained_Regression_Dependency
            | Status_Retained_Canonical =>
            return Class_Accepted;
         when Status_Rejected_Still_In_Core_Suite
            | Status_Rejected_Active_Removed_Reference
            | Status_Rejected_Missing_Removal_Evidence
            | Status_Rejected_Unowned_Legacy_Source
            | Status_Rejected_Reopened_Remaining_Gap
            | Status_Rejected_Fingerprint_Mismatch =>
            return Class_Rejected;
         when Status_Indeterminate_Unknown_Kind
            | Status_Indeterminate_Unknown_Action =>
            return Class_Indeterminate;
         when Status_Not_Checked =>
            return Class_Unknown;
      end case;
   end Class_For_Status;

   function Fingerprints_Fresh (Row : Sweep_Row) return Boolean is
   begin
      return Row.Source_Fingerprint = Row.Expected_Source_Fingerprint
        and then Row.Test_Fingerprint = Row.Expected_Test_Fingerprint
        and then Row.Suite_Fingerprint = Row.Expected_Suite_Fingerprint
        and then Row.Cleanup_Fingerprint = Row.Expected_Cleanup_Fingerprint;
   end Fingerprints_Fresh;

   function Has_Required_Text (Row : Sweep_Row) return Boolean is
   begin
      return Length (Row.Path) > 0
        and then Length (Row.Canonical_Owner) > 0
        and then Length (Row.Reason) > 0
        and then Length (Row.Blocker_Family) > 0;
   end Has_Required_Text;

   function Evaluate (Row : Sweep_Row) return Sweep_Status is
   begin
      if Row.Kind = Kind_Unknown then
         return Status_Indeterminate_Unknown_Kind;
      elsif Row.Action = Action_Unknown then
         return Status_Indeterminate_Unknown_Action;
      elsif not Has_Required_Text (Row) then
         return Status_Rejected_Unowned_Legacy_Source;
      elsif Row.Reopens_Remaining_Gap then
         return Status_Rejected_Reopened_Remaining_Gap;
      elsif Row.References_Removed_Surface then
         return Status_Rejected_Active_Removed_Reference;
      elsif not Fingerprints_Fresh (Row) then
         return Status_Rejected_Fingerprint_Mismatch;
      end if;

      case Row.Action is
         when Action_Remove_Orphan =>
            if Row.Registered_In_Core_Suite then
               return Status_Rejected_Still_In_Core_Suite;
            elsif not Row.Artifact_Present_Before
              or else Row.Artifact_Present_After
              or else not Row.Has_Removal_Evidence
            then
               return Status_Rejected_Missing_Removal_Evidence;
            else
               return Status_Removed_Orphan;
            end if;

         when Action_Retain_Regression_Dependency =>
            if not Row.Artifact_Present_After
              or else not Row.Has_Active_Dependent
              or else not Row.Regression_Only
            then
               return Status_Rejected_Unowned_Legacy_Source;
            else
               return Status_Retained_Regression_Dependency;
            end if;

         when Action_Retain_Canonical =>
            if Row.Artifact_Present_After
              and then Row.Canonical_Production_Surface
              and then not Row.Regression_Only
            then
               return Status_Retained_Canonical;
            else
               return Status_Rejected_Unowned_Legacy_Source;
            end if;

         when Action_Reject_Active_Removed_Reference =>
            return Status_Rejected_Active_Removed_Reference;

         when Action_Unknown =>
            return Status_Indeterminate_Unknown_Action;
      end case;
   end Evaluate;

   function Result_Fingerprint
     (Row : Sweep_Row; Status : Sweep_Status) return Natural is
   begin
      return Row.Id * 61
        + Artifact_Kind'Pos (Row.Kind) * 67
        + Sweep_Action'Pos (Row.Action) * 71
        + Sweep_Status'Pos (Status) * 73
        + Row.Source_Fingerprint
        + Row.Test_Fingerprint
        + Row.Suite_Fingerprint
        + Row.Cleanup_Fingerprint;
   end Result_Fingerprint;

   function Build (Input : Sweep_Input) return Sweep_Model is
      Model : Sweep_Model;
      Status : Sweep_Status;
      Item : Sweep_Result;
   begin
      for Row of Input.Rows loop
         Status := Evaluate (Row);
         Item :=
           (Id => Row.Id,
            Status => Status,
            Result_Class => Class_For_Status (Status),
            Result_Fingerprint => Result_Fingerprint (Row, Status));
         Model.Results.Append (Item);
         Model.Total_Rows := Model.Total_Rows + 1;
         Model.Sweep_Fingerprint :=
           Model.Sweep_Fingerprint + Item.Result_Fingerprint;

         case Item.Result_Class is
            when Class_Accepted =>
               case Status is
                  when Status_Removed_Orphan =>
                     Model.Removed_Count := Model.Removed_Count + 1;
                  when Status_Retained_Regression_Dependency =>
                     Model.Retained_Regression_Count :=
                       Model.Retained_Regression_Count + 1;
                  when Status_Retained_Canonical =>
                     Model.Retained_Canonical_Count :=
                       Model.Retained_Canonical_Count + 1;
                  when others =>
                     null;
               end case;
            when Class_Rejected =>
               Model.Rejected_Count := Model.Rejected_Count + 1;
            when Class_Indeterminate =>
               Model.Indeterminate_Count := Model.Indeterminate_Count + 1;
            when Class_Unknown =>
               null;
         end case;
      end loop;

      return Model;
   end Build;

   function Result_For (Model : Sweep_Model; Id : Natural) return Sweep_Result is
   begin
      for Item of Model.Results loop
         if Item.Id = Id then
            return Item;
         end if;
      end loop;
      return (Id => Id,
              Status => Status_Not_Checked,
              Result_Class => Class_Unknown,
              Result_Fingerprint => 0);
   end Result_For;

   function Dead_Code_Sweep_Complete (Model : Sweep_Model) return Boolean is
   begin
      return Model.Total_Rows >= 6
        and then Model.Removed_Count >= 3
        and then Model.Retained_Regression_Count >= 2
        and then Model.Retained_Canonical_Count >= 1
        and then Model.Rejected_Count = 0
        and then Model.Indeterminate_Count = 0
        and then Model.Sweep_Fingerprint /= 0;
   end Dead_Code_Sweep_Complete;

   function Ready_For_Phase_Handoff (Model : Sweep_Model) return Boolean is
   begin
      return Dead_Code_Sweep_Complete (Model)
        and then Model.Removed_Count + Model.Retained_Regression_Count
          + Model.Retained_Canonical_Count = Model.Total_Rows;
   end Ready_For_Phase_Handoff;

end Editor.Ada_Phase579_Final_Dead_Code_Sweep_Pass1445;
