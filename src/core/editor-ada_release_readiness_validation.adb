with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Release_Readiness_Validation is

   pragma Suppress (Overflow_Check);

   procedure Add_Row (Input : in out Readiness_Input; Row : Readiness_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Row;

   function Class_For_Status (Status : Readiness_Status) return Readiness_Result_Class is
   begin
      case Status is
         when Status_Validated =>
            return Class_Validated;
         when Status_Rejected_Missing_Source
            | Status_Rejected_Missing_Test
            | Status_Rejected_Missing_Readme
            | Status_Rejected_Unregistered_Test
            | Status_Rejected_Orphan_Source
            | Status_Rejected_Duplicate_Registration
            | Status_Rejected_Duplicate_Surface
            | Status_Rejected_Reopened_Remaining_Gap
            | Status_Rejected_Stale_Readiness_Evidence
            | Status_Rejected_Release_Documentation_Drift =>
            return Class_Rejected;
         when Status_Indeterminate_Missing_Evidence =>
            return Class_Indeterminate;
         when Status_Not_Checked =>
            return Class_Unknown;
      end case;
   end Class_For_Status;

   function Has_Names (Row : Readiness_Row) return Boolean is
   begin
      return Length (Row.Name) > 0
        and then Row.Surface /= Surface_Unknown
        and then Row.Evidence_Present;
   end Has_Names;

   function Fingerprints_Fresh (Row : Readiness_Row) return Boolean is
   begin
      return Row.Source_Fingerprint = Row.Expected_Source_Fingerprint
        and then Row.Test_Fingerprint = Row.Expected_Test_Fingerprint
        and then Row.Suite_Fingerprint = Row.Expected_Suite_Fingerprint
        and then Row.Documentation_Fingerprint = Row.Expected_Documentation_Fingerprint;
   end Fingerprints_Fresh;

   function Is_Required_Surface (Surface : Readiness_Surface) return Boolean is
   begin
      return Surface /= Surface_Unknown;
   end Is_Required_Surface;

   function Required_Surface_Total return Natural is
      Total : Natural := 0;
   begin
      for Surface in Readiness_Surface loop
         if Is_Required_Surface (Surface) then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Required_Surface_Total;

   function Evaluate (Row : Readiness_Row) return Readiness_Status is
   begin
      if not Has_Names (Row) then
         return Status_Indeterminate_Missing_Evidence;
      elsif not Fingerprints_Fresh (Row) then
         return Status_Rejected_Stale_Readiness_Evidence;
      elsif not Row.Source_Present then
         return Status_Rejected_Missing_Source;
      elsif not Row.Test_Present then
         return Status_Rejected_Missing_Test;
      elsif not Row.Readme_Present then
         return Status_Rejected_Missing_Readme;
      elsif not Row.Registered_In_Suite then
         return Status_Rejected_Unregistered_Test;
      elsif Row.Orphan_Source then
         return Status_Rejected_Orphan_Source;
      elsif Row.Duplicate_Suite_Registration then
         return Status_Rejected_Duplicate_Registration;
      elsif Row.Reopened_Remaining_Gap then
         return Status_Rejected_Reopened_Remaining_Gap;
      elsif not Row.Release_Documentation_Agreed then
         return Status_Rejected_Release_Documentation_Drift;
      else
         return Status_Validated;
      end if;
   end Evaluate;

   function Result_Fingerprint_For
     (Row : Readiness_Row; Status : Readiness_Status) return Natural is
   begin
      return Row.Id * 131
        + Readiness_Surface'Pos (Row.Surface) * 67
        + Readiness_Status'Pos (Status) * 43
        + Row.Source_Fingerprint
        + Row.Test_Fingerprint
        + Row.Suite_Fingerprint
        + Row.Documentation_Fingerprint;
   end Result_Fingerprint_For;

   procedure Tally (Model : in out Readiness_Model; Feed_Item : Readiness_Entry) is
   begin
      case Feed_Item.Status is
         when Status_Validated =>
            Model.Validated_Count := Model.Validated_Count + 1;
         when Status_Rejected_Missing_Source
            | Status_Rejected_Missing_Test
            | Status_Rejected_Missing_Readme
            | Status_Rejected_Unregistered_Test
            | Status_Rejected_Orphan_Source
            | Status_Rejected_Duplicate_Registration
            | Status_Rejected_Duplicate_Surface
            | Status_Rejected_Reopened_Remaining_Gap
            | Status_Rejected_Stale_Readiness_Evidence
            | Status_Rejected_Release_Documentation_Drift =>
            Model.Rejected_Count := Model.Rejected_Count + 1;
         when Status_Indeterminate_Missing_Evidence =>
            Model.Indeterminate_Count := Model.Indeterminate_Count + 1;
         when Status_Not_Checked =>
            null;
      end case;
   end Tally;

   function Build (Input : Readiness_Input) return Readiness_Model is
      Seen   : array (Readiness_Surface) of Boolean := (others => False);
      Model : Readiness_Model;
      Status : Readiness_Status;
      Feed_Item : Readiness_Entry;
   begin
      for Row of Input.Rows loop
         Status := Evaluate (Row);
         if Status = Status_Validated
           and then Is_Required_Surface (Row.Surface)
         then
            if Seen (Row.Surface) then
               Status := Status_Rejected_Duplicate_Surface;
               Model.Duplicate_Surface_Count :=
                 Model.Duplicate_Surface_Count + 1;
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
         Model.Readiness_Fingerprint :=
           Model.Readiness_Fingerprint + Feed_Item.Result_Fingerprint;
         Tally (Model, Feed_Item);
      end loop;

      Model.Required_Surface_Count := Required_Surface_Total;
      for Surface in Readiness_Surface loop
         if Is_Required_Surface (Surface) and then not Seen (Surface) then
            Model.Missing_Surface_Count := Model.Missing_Surface_Count + 1;
         end if;
      end loop;

      return Model;
   end Build;

   function Result_For (Model : Readiness_Model; Id : Natural) return Readiness_Entry is
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

   function Release_Readiness_Achieved (Model : Readiness_Model) return Boolean is
   begin
      return Model.Total_Rows = Model.Required_Surface_Count
        and then Model.Required_Surface_Count = 7
        and then Model.Missing_Surface_Count = 0
        and then Model.Duplicate_Surface_Count = 0
        and then Model.Validated_Count = Model.Required_Surface_Count
        and then Model.Rejected_Count = 0
        and then Model.Indeterminate_Count = 0
        and then Model.Readiness_Fingerprint > 0;
   end Release_Readiness_Achieved;

end Editor.Ada_Release_Readiness_Validation;
