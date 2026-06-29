with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Phase579_Diagnostic_Quality_Validation_Pass1435 is

   pragma Suppress (Overflow_Check);

   procedure Add_Row (Input : in out Diagnostic_Input; Row : Diagnostic_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Row;

   function Class_For_Status
     (Status : Diagnostic_Status) return Diagnostic_Result_Class is
   begin
      case Status is
         when Status_Accepted =>
            return Class_Accepted;
         when Status_Rejected_Missing_Source_Span
            | Status_Rejected_Unstable_Blocker_Family
            | Status_Rejected_Wrong_Severity
            | Status_Rejected_Duplicate_Flood
            | Status_Rejected_Duplicate_Scenario
            | Status_Rejected_Misleading_Final_State
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

   function Has_Evidence (Row : Diagnostic_Row) return Boolean is
   begin
      return Row.Evidence_Present
        and then Row.Scenario /= Scenario_Unknown
        and then Length (Row.Name) > 0
        and then Row.Expected_Severity /= Severity_None
        and then Row.Duplicate_Limit > 0;
   end Has_Evidence;

   function Fingerprints_Fresh (Row : Diagnostic_Row) return Boolean is
   begin
      return Row.Source_Fingerprint = Row.Expected_Source_Fingerprint
        and then Row.Diagnostic_Fingerprint = Row.Expected_Diagnostic_Fingerprint
        and then Row.Consumer_Fingerprint = Row.Expected_Consumer_Fingerprint
        and then Row.Projection_Fingerprint = Row.Expected_Projection_Fingerprint;
   end Fingerprints_Fresh;

   function Is_Required_Scenario
     (Scenario : Diagnostic_Scenario_Kind) return Boolean is
   begin
      return Scenario /= Scenario_Unknown;
   end Is_Required_Scenario;

   function Required_Scenario_Total return Natural is
      Total : Natural := 0;
   begin
      for Scenario in Diagnostic_Scenario_Kind loop
         if Is_Required_Scenario (Scenario) then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Required_Scenario_Total;

   function Evaluate (Row : Diagnostic_Row) return Diagnostic_Status is
   begin
      if not Has_Evidence (Row) then
         return Status_Indeterminate_Missing_Evidence;
      elsif not Fingerprints_Fresh (Row) then
         return Status_Rejected_Stale_Evidence;
      elsif not Row.Has_Source_Span then
         return Status_Rejected_Missing_Source_Span;
      elsif not Row.Stable_Blocker_Family then
         return Status_Rejected_Unstable_Blocker_Family;
      elsif Row.Actual_Severity /= Row.Expected_Severity then
         return Status_Rejected_Wrong_Severity;
      elsif Row.Duplicate_Count > Row.Duplicate_Limit then
         return Status_Rejected_Duplicate_Flood;
      elsif not Row.Final_State_Matches_Result then
         return Status_Rejected_Misleading_Final_State;
      elsif not Row.Consumer_Agreement then
         return Status_Rejected_Consumer_Disagreement;
      elsif Row.Reopens_Remaining_Gap then
         return Status_Rejected_Reopened_Remaining_Gap;
      else
         return Status_Accepted;
      end if;
   end Evaluate;

   function Result_Fingerprint_For
     (Row : Diagnostic_Row; Status : Diagnostic_Status) return Natural is
   begin
      return Row.Id * 163
        + Diagnostic_Scenario_Kind'Pos (Row.Scenario) * 97
        + Diagnostic_Status'Pos (Status) * 61
        + Diagnostic_Severity'Pos (Row.Actual_Severity) * 31
        + Row.Source_Fingerprint
        + Row.Diagnostic_Fingerprint
        + Row.Consumer_Fingerprint
        + Row.Projection_Fingerprint;
   end Result_Fingerprint_For;

   procedure Tally (Model : in out Diagnostic_Model; Item : Diagnostic_Entry) is
   begin
      case Item.Status is
         when Status_Accepted =>
            Model.Accepted_Count := Model.Accepted_Count + 1;
         when Status_Rejected_Missing_Source_Span
            | Status_Rejected_Unstable_Blocker_Family
            | Status_Rejected_Wrong_Severity
            | Status_Rejected_Duplicate_Flood
            | Status_Rejected_Duplicate_Scenario
            | Status_Rejected_Misleading_Final_State
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

   function Build (Input : Diagnostic_Input) return Diagnostic_Model is
      Seen   : array (Diagnostic_Scenario_Kind) of Boolean := (others => False);
      Model : Diagnostic_Model;
      Status : Diagnostic_Status;
      Item : Diagnostic_Entry;
   begin
      for Row of Input.Rows loop
         Status := Evaluate (Row);
         if Status = Status_Accepted
           and then Is_Required_Scenario (Row.Scenario)
         then
            if Seen (Row.Scenario) then
               Status := Status_Rejected_Duplicate_Scenario;
               Model.Duplicate_Scenario_Count :=
                 Model.Duplicate_Scenario_Count + 1;
            else
               Seen (Row.Scenario) := True;
            end if;
         end if;

         Item.Id := Row.Id;
         Item.Scenario := Row.Scenario;
         Item.Status := Status;
         Item.Result_Class := Class_For_Status (Status);
         Item.Result_Fingerprint := Result_Fingerprint_For (Row, Status);
         Model.Entries.Append (Item);
         Model.Total_Rows := Model.Total_Rows + 1;
         Model.Quality_Fingerprint := Model.Quality_Fingerprint + Item.Result_Fingerprint;
         Tally (Model, Item);
      end loop;

      Model.Required_Scenario_Count := Required_Scenario_Total;
      for Scenario in Diagnostic_Scenario_Kind loop
         if Is_Required_Scenario (Scenario) and then not Seen (Scenario) then
            Model.Missing_Scenario_Count := Model.Missing_Scenario_Count + 1;
         end if;
      end loop;

      return Model;
   end Build;

   function Result_For
     (Model : Diagnostic_Model; Id : Natural) return Diagnostic_Entry is
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

   function Diagnostic_Quality_Complete
     (Model : Diagnostic_Model) return Boolean is
   begin
      return Model.Total_Rows = Model.Required_Scenario_Count
        and then Model.Required_Scenario_Count = 8
        and then Model.Missing_Scenario_Count = 0
        and then Model.Duplicate_Scenario_Count = 0
        and then Model.Accepted_Count = Model.Required_Scenario_Count
        and then Model.Rejected_Count = 0
        and then Model.Indeterminate_Count = 0
        and then Model.Quality_Fingerprint > 0;
   end Diagnostic_Quality_Complete;

end Editor.Ada_Phase579_Diagnostic_Quality_Validation_Pass1435;
