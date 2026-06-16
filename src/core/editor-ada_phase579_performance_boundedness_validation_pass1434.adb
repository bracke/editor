with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Phase579_Performance_Boundedness_Validation_Pass1434 is

   pragma Suppress (Overflow_Check);

   procedure Add_Row (Input : in out Boundedness_Input; Row : Boundedness_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Row;

   function Class_For_Status
     (Status : Boundedness_Status) return Boundedness_Result_Class is
   begin
      case Status is
         when Status_Accepted =>
            return Class_Accepted;
         when Status_Rejected_Unbounded_Work
            | Status_Rejected_Cancellation_Ignored
            | Status_Rejected_Stale_Result_Accepted
            | Status_Rejected_Nondeterministic_Replay
            | Status_Rejected_Index_Traversal_Unbounded
            | Status_Rejected_Consumer_Disagreement
            | Status_Rejected_Reopened_Remaining_Gap
            | Status_Rejected_Stale_Evidence =>
            return Class_Rejected;
         when Status_Indeterminate_Missing_Evidence =>
            return Class_Indeterminate;
         when Status_Not_Checked =>
            return Class_Unknown;
      end case;
   end Class_For_Status;

   function Has_Evidence (Row : Boundedness_Row) return Boolean is
   begin
      return Row.Evidence_Present
        and then Row.Scenario /= Scenario_Unknown
        and then Length (Row.Name) > 0
        and then Row.Work_Budget > 0
        and then Row.Index_Traversal_Bound > 0;
   end Has_Evidence;

   function Fingerprints_Fresh (Row : Boundedness_Row) return Boolean is
   begin
      return Row.Source_Fingerprint = Row.Expected_Source_Fingerprint
        and then Row.Snapshot_Fingerprint = Row.Expected_Snapshot_Fingerprint
        and then Row.Schedule_Fingerprint = Row.Expected_Schedule_Fingerprint
        and then Row.Consumer_Fingerprint = Row.Expected_Consumer_Fingerprint;
   end Fingerprints_Fresh;

   function Evaluate (Row : Boundedness_Row) return Boundedness_Status is
   begin
      if not Has_Evidence (Row) then
         return Status_Indeterminate_Missing_Evidence;
      elsif not Fingerprints_Fresh (Row) or else not Row.Snapshot_Fresh then
         return Status_Rejected_Stale_Evidence;
      elsif Row.Observed_Work > Row.Work_Budget then
         return Status_Rejected_Unbounded_Work;
      elsif Row.Observed_Index_Traversal > Row.Index_Traversal_Bound then
         return Status_Rejected_Index_Traversal_Unbounded;
      elsif Row.Cancellation_Requested and then not Row.Cancellation_Acknowledged then
         return Status_Rejected_Cancellation_Ignored;
      elsif not Row.Stale_Result_Rejected then
         return Status_Rejected_Stale_Result_Accepted;
      elsif not Row.Deterministic_Replay then
         return Status_Rejected_Nondeterministic_Replay;
      elsif not Row.Consumer_Agreement then
         return Status_Rejected_Consumer_Disagreement;
      elsif Row.Reopens_Remaining_Gap then
         return Status_Rejected_Reopened_Remaining_Gap;
      else
         return Status_Accepted;
      end if;
   end Evaluate;

   function Result_Fingerprint_For
     (Row : Boundedness_Row; Status : Boundedness_Status) return Natural is
   begin
      return Row.Id * 157
        + Scenario_Kind'Pos (Row.Scenario) * 89
        + Boundedness_Status'Pos (Status) * 59
        + Row.Source_Fingerprint
        + Row.Snapshot_Fingerprint
        + Row.Schedule_Fingerprint
        + Row.Consumer_Fingerprint;
   end Result_Fingerprint_For;

   procedure Tally (Model : in out Boundedness_Model; Item : Boundedness_Entry) is
   begin
      case Item.Status is
         when Status_Accepted =>
            Model.Accepted_Count := Model.Accepted_Count + 1;
         when Status_Rejected_Unbounded_Work
            | Status_Rejected_Cancellation_Ignored
            | Status_Rejected_Stale_Result_Accepted
            | Status_Rejected_Nondeterministic_Replay
            | Status_Rejected_Index_Traversal_Unbounded
            | Status_Rejected_Consumer_Disagreement
            | Status_Rejected_Reopened_Remaining_Gap
            | Status_Rejected_Stale_Evidence =>
            Model.Rejected_Count := Model.Rejected_Count + 1;
         when Status_Indeterminate_Missing_Evidence =>
            Model.Indeterminate_Count := Model.Indeterminate_Count + 1;
         when Status_Not_Checked =>
            null;
      end case;
   end Tally;

   function Build (Input : Boundedness_Input) return Boundedness_Model is
      Model : Boundedness_Model;
      Status : Boundedness_Status;
      Item : Boundedness_Entry;
   begin
      for Row of Input.Rows loop
         Status := Evaluate (Row);
         Item.Id := Row.Id;
         Item.Scenario := Row.Scenario;
         Item.Status := Status;
         Item.Result_Class := Class_For_Status (Status);
         Item.Result_Fingerprint := Result_Fingerprint_For (Row, Status);
         Model.Entries.Append (Item);
         Model.Total_Rows := Model.Total_Rows + 1;
         Model.Performance_Fingerprint :=
           Model.Performance_Fingerprint + Item.Result_Fingerprint;
         Tally (Model, Item);
      end loop;
      return Model;
   end Build;

   function Result_For
     (Model : Boundedness_Model; Id : Natural) return Boundedness_Entry is
   begin
      for Item of Model.Entries loop
         if Item.Id = Id then
            return Item;
         end if;
      end loop;
      return (Id => Id,
              Scenario => Scenario_Unknown,
              Status => Status_Not_Checked,
              Result_Class => Class_Unknown,
              Result_Fingerprint => 0);
   end Result_For;

   function Performance_Boundedness_Complete
     (Model : Boundedness_Model) return Boolean is
   begin
      return Model.Total_Rows > 0
        and then Model.Accepted_Count = Model.Total_Rows
        and then Model.Rejected_Count = 0
        and then Model.Indeterminate_Count = 0
        and then Model.Performance_Fingerprint > 0;
   end Performance_Boundedness_Complete;

end Editor.Ada_Phase579_Performance_Boundedness_Validation_Pass1434;
