with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Phase579_Real_Ada_Corpus_Validation_Pass1430 is

   procedure Add_Row (Input : in out Corpus_Input; Row : Corpus_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Row;

   function Class_For_Status (Status : Corpus_Status) return Corpus_Result_Class is
   begin
      case Status is
         when Status_Accepted_Legal_Corpus
            | Status_Rejected_Illegal_Corpus
            | Status_Runtime_Check_Preserved
            | Status_Warning_Only_Preserved
            | Status_Cross_Unit_Consumer_Agreed =>
            return Class_Validated;
         when Status_Rejected_False_Positive
            | Status_Rejected_False_Negative
            | Status_Rejected_Missing_Diagnostic_Span
            | Status_Rejected_Duplicate_Diagnostic_Flood
            | Status_Rejected_Consumer_Disagreement
            | Status_Rejected_Stale_Corpus_Evidence =>
            return Class_Rejected;
         when Status_Indeterminate_Missing_Corpus_Evidence =>
            return Class_Indeterminate;
         when Status_Not_Checked =>
            return Class_Unknown;
      end case;
   end Class_For_Status;

   function Evidence_Present (Row : Corpus_Row) return Boolean is
   begin
      return Length (Row.Scenario_Name) > 0
        and then Length (Row.Source_Shape) > 0
        and then Length (Row.RM_Anchor) > 0
        and then Row.Family /= Family_Unknown;
   end Evidence_Present;

   function Fingerprints_Fresh (Row : Corpus_Row) return Boolean is
   begin
      return Row.Source_Fingerprint = Row.Expected_Source_Fingerprint
        and then Row.AST_Fingerprint = Row.Expected_AST_Fingerprint
        and then Row.Semantic_Fingerprint = Row.Expected_Semantic_Fingerprint
        and then Row.Consumer_Fingerprint = Row.Expected_Consumer_Fingerprint;
   end Fingerprints_Fresh;

   function Consumers_Agree (Row : Corpus_Row) return Boolean is
   begin
      return Row.Consumer_Agreed
        and then Row.Project_Index_Agreed
        and then Row.Snapshot_Owned
        and then not Row.Reopened_Remaining_Gap;
   end Consumers_Agree;

   function Evaluate (Row : Corpus_Row) return Corpus_Status is
   begin
      if not Evidence_Present (Row) then
         return Status_Indeterminate_Missing_Corpus_Evidence;
      elsif not Row.Stale_Evidence_Rejected or else not Fingerprints_Fresh (Row) then
         return Status_Rejected_Stale_Corpus_Evidence;
      elsif not Consumers_Agree (Row) then
         return Status_Rejected_Consumer_Disagreement;
      elsif not Row.Diagnostic_Span_Present then
         return Status_Rejected_Missing_Diagnostic_Span;
      elsif Row.Duplicate_Diagnostic_Flood then
         return Status_Rejected_Duplicate_Diagnostic_Flood;
      end if;

      case Row.Expected is
         when Expect_Accepted =>
            if Row.Actual_Accepted and then not Row.Actual_Rejected then
               if Row.Family = Family_Cross_Unit_Project then
                  return Status_Cross_Unit_Consumer_Agreed;
               else
                  return Status_Accepted_Legal_Corpus;
               end if;
            else
               return Status_Rejected_False_Positive;
            end if;
         when Expect_Rejected =>
            if Row.Actual_Rejected and then not Row.Actual_Accepted then
               return Status_Rejected_Illegal_Corpus;
            else
               return Status_Rejected_False_Negative;
            end if;
         when Expect_Runtime_Check =>
            if Row.Actual_Accepted and then Row.Runtime_Check_Preserved then
               return Status_Runtime_Check_Preserved;
            else
               return Status_Rejected_False_Positive;
            end if;
         when Expect_Warning_Only =>
            if Row.Actual_Accepted and then Row.Warning_Only_Preserved then
               return Status_Warning_Only_Preserved;
            else
               return Status_Rejected_False_Positive;
            end if;
         when Expect_Indeterminate =>
            return Status_Indeterminate_Missing_Corpus_Evidence;
      end case;
   end Evaluate;

   function Result_Fingerprint_For
     (Row : Corpus_Row; Status : Corpus_Status) return Natural is
   begin
      return Row.Id * 97
        + Corpus_Scenario_Family'Pos (Row.Family) * 53
        + Expected_Corpus_Verdict'Pos (Row.Expected) * 41
        + Corpus_Status'Pos (Status) * 29
        + Row.Source_Fingerprint
        + Row.AST_Fingerprint
        + Row.Semantic_Fingerprint
        + Row.Consumer_Fingerprint;
   end Result_Fingerprint_For;

   procedure Tally (Model : in out Corpus_Model; Feed_Item : Corpus_Entry) is
   begin
      case Feed_Item.Status is
         when Status_Accepted_Legal_Corpus =>
            Model.Legal_Accepted_Count := Model.Legal_Accepted_Count + 1;
         when Status_Rejected_Illegal_Corpus =>
            Model.Illegal_Rejected_Count := Model.Illegal_Rejected_Count + 1;
         when Status_Runtime_Check_Preserved =>
            Model.Runtime_Check_Count := Model.Runtime_Check_Count + 1;
         when Status_Warning_Only_Preserved =>
            Model.Warning_Only_Count := Model.Warning_Only_Count + 1;
         when Status_Cross_Unit_Consumer_Agreed =>
            Model.Cross_Unit_Agreed_Count := Model.Cross_Unit_Agreed_Count + 1;
         when Status_Rejected_False_Positive
            | Status_Rejected_False_Negative
            | Status_Rejected_Missing_Diagnostic_Span
            | Status_Rejected_Duplicate_Diagnostic_Flood
            | Status_Rejected_Consumer_Disagreement
            | Status_Rejected_Stale_Corpus_Evidence =>
            Model.Rejected_Count := Model.Rejected_Count + 1;
         when Status_Indeterminate_Missing_Corpus_Evidence =>
            Model.Indeterminate_Count := Model.Indeterminate_Count + 1;
         when Status_Not_Checked =>
            null;
      end case;
   end Tally;

   function Build (Input : Corpus_Input) return Corpus_Model is
      Model : Corpus_Model;
   begin
      for Row of Input.Rows loop
         declare
            Status : constant Corpus_Status := Evaluate (Row);
            Feed_Item : Corpus_Entry;
         begin
            Feed_Item.Id := Row.Id;
            Feed_Item.Family := Row.Family;
            Feed_Item.Status := Status;
            Feed_Item.Result_Class := Class_For_Status (Status);
            Feed_Item.Result_Fingerprint := Result_Fingerprint_For (Row, Status);

            Model.Entries.Append (Feed_Item);
            Model.Total_Rows := Model.Total_Rows + 1;
            Model.Corpus_Fingerprint :=
              Model.Corpus_Fingerprint + Feed_Item.Result_Fingerprint;
            Tally (Model, Feed_Item);
         end;
      end loop;
      return Model;
   end Build;

   function Result_For (Model : Corpus_Model; Id : Natural) return Corpus_Entry is
   begin
      for Feed_Item of Model.Entries loop
         if Feed_Item.Id = Id then
            return Feed_Item;
         end if;
      end loop;
      return (Id => Id,
              Family => Family_Unknown,
              Status => Status_Not_Checked,
              Result_Class => Class_Unknown,
              Result_Fingerprint => 0);
   end Result_For;

   function Corpus_Validation_Achieved (Model : Corpus_Model) return Boolean is
   begin
      return Model.Total_Rows >= 5
        and then Model.Legal_Accepted_Count > 0
        and then Model.Illegal_Rejected_Count > 0
        and then Model.Runtime_Check_Count > 0
        and then Model.Warning_Only_Count > 0
        and then Model.Cross_Unit_Agreed_Count > 0
        and then Model.Rejected_Count = 0
        and then Model.Indeterminate_Count = 0;
   end Corpus_Validation_Achieved;

end Editor.Ada_Phase579_Real_Ada_Corpus_Validation_Pass1430;
