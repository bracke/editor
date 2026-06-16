with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_RM_Remaining_Gap_Remediation_Pass1384 is

   pragma Suppress (Overflow_Check);
   use type Matrix.Coverage_Level;
   use type Remediation.Remediation_State;
   use type Precision.Precision_Classification;
   use type Consumers.Semantic_Consumer;


   procedure Add_Row (Input : in out Remediation_Input; Row : Remediation_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Row;

   function Expected_For_Status (Status : Remediation_Status)
      return Precision_Classification is
   begin
      case Status is
         when Status_Gap_Remediated
            | Status_Legal_Open_Buffer_Project_Index_Agreement =>
            return Precision.Class_Legal;
         when Status_Illegal_Duplicate_Library_Unit
            | Status_Illegal_Private_Child_Visibility_Leak
            | Status_Illegal_Consumer_Surface_Disagreement =>
            return Precision.Class_Illegal;
         when Status_Indeterminate_Missing_Unit_Evidence
            | Status_Indeterminate_Missing_Project_File
            | Status_Indeterminate_Stale_Project_Index
            | Status_Missing_Pass1366_Inventory_Row
            | Status_Missing_Concrete_Subrule_Name
            | Status_Missing_Candidate_Owner
            | Status_No_New_Legality_Rule
            | Status_Source_Shaped_Evidence_Missing
            | Status_Coverage_Not_Promoted
            | Status_Remediation_State_Not_Covered
            | Status_Final_Gate_Still_Reports_Gap
            | Status_Regression_Corpus_Not_Balanced
            | Status_Semantic_Result_Unconsumed
            | Status_Consumer_Not_Reached
            | Status_Unstable_Blocker_Family
            | Status_Source_Fingerprint_Mismatch
            | Status_AST_Fingerprint_Mismatch
            | Status_Unit_Fingerprint_Mismatch
            | Status_Project_Index_Fingerprint_Mismatch
            | Status_View_Fingerprint_Mismatch
            | Status_Consumer_Fingerprint_Mismatch
            | Status_Multiple_Blockers
            | Status_Indeterminate =>
            return Precision.Class_Indeterminate;
         when Status_Not_Checked =>
            return Precision.Class_Unknown;
      end case;
   end Expected_For_Status;

   procedure Set_Status
     (Item : in out Remediation_Entry;
      Status : Remediation_Status) is
   begin
      Item.Status := Status;
      Item.Blocker_Count := Item.Blocker_Count + 1;
   end Set_Status;

   function Row_Fingerprint (Row : Remediation_Row) return Natural is
   begin
      return Row.Id
        + Natural (Remediated_Gap_Family'Pos (Row.Gap)) * 3
        + Natural (Project_Index_Context'Pos (Row.Context)) * 5
        + Natural (Project_Index_Form'Pos (Row.Form)) * 7
        + Row.Source_Fingerprint
        + Row.AST_Fingerprint
        + Row.Unit_Fingerprint
        + Row.Project_Index_Fingerprint
        + Row.View_Fingerprint
        + Row.Consumer_Fingerprint;
   end Row_Fingerprint;

   procedure Check_Remediation_Gates
     (Row : Remediation_Row;
      Item : in out Remediation_Entry) is
   begin
      if not Row.Inventory_Row_From_Pass1366 then
         Set_Status (Item, Status_Missing_Pass1366_Inventory_Row);
      elsif (not Row.Named_Concrete_Subrule)
        or else Length (Row.Concrete_Subrule) = 0 then
         Set_Status (Item, Status_Missing_Concrete_Subrule_Name);
      elsif (not Row.Candidate_Owner_Named)
        or else Length (Row.Candidate_Implementing_Package) = 0
        or else Length (Row.Candidate_Pass) = 0 then
         Set_Status (Item, Status_Missing_Candidate_Owner);
      elsif not Row.New_Legality_Rule_Added then
         Set_Status (Item, Status_No_New_Legality_Rule);
      elsif not Row.Source_Shaped_Evidence then
         Set_Status (Item, Status_Source_Shaped_Evidence_Missing);
      elsif not Row.Coverage_Promoted_To_Covered then
         Set_Status (Item, Status_Coverage_Not_Promoted);
      elsif Row.Target_Remediation /= Remediation.State_Covered then
         Set_Status (Item, Status_Remediation_State_Not_Covered);
      elsif not Row.Final_Gate_No_Longer_Reports_Gap then
         Set_Status (Item, Status_Final_Gate_Still_Reports_Gap);
      elsif not (Row.Legal_Test_Present
                 and Row.Illegal_Test_Present
                 and Row.Indeterminate_Test_Present
                 and Row.Consumer_Surfaced_Test_Present) then
         Set_Status (Item, Status_Regression_Corpus_Not_Balanced);
      elsif not Row.Semantic_Result_Consumed then
         Set_Status (Item, Status_Semantic_Result_Unconsumed);
      elsif not Row.Consumer_Reached then
         Set_Status (Item, Status_Consumer_Not_Reached);
      elsif not Row.Stable_Blocker_Family then
         Set_Status (Item, Status_Unstable_Blocker_Family);
      end if;
   end Check_Remediation_Gates;

   procedure Check_Fingerprints
     (Row : Remediation_Row;
      Item : in out Remediation_Entry) is
   begin
      if Row.Source_Fingerprint /= Row.Expected_Source_Fingerprint then
         Set_Status (Item, Status_Source_Fingerprint_Mismatch);
      elsif Row.AST_Fingerprint /= Row.Expected_AST_Fingerprint then
         Set_Status (Item, Status_AST_Fingerprint_Mismatch);
      elsif Row.Unit_Fingerprint /= Row.Expected_Unit_Fingerprint then
         Set_Status (Item, Status_Unit_Fingerprint_Mismatch);
      elsif Row.Project_Index_Fingerprint /= Row.Expected_Project_Index_Fingerprint then
         Set_Status (Item, Status_Project_Index_Fingerprint_Mismatch);
      elsif Row.View_Fingerprint /= Row.Expected_View_Fingerprint then
         Set_Status (Item, Status_View_Fingerprint_Mismatch);
      elsif Row.Consumer_Fingerprint /= Row.Expected_Consumer_Fingerprint then
         Set_Status (Item, Status_Consumer_Fingerprint_Mismatch);
      end if;
   end Check_Fingerprints;

   procedure Check_Project_Index_Rule
     (Row : Remediation_Row;
      Item : in out Remediation_Entry) is
   begin
      if not Row.Unit_Evidence_Present then
         Set_Status (Item, Status_Indeterminate_Missing_Unit_Evidence);
      elsif not Row.Project_File_Present then
         Set_Status (Item, Status_Indeterminate_Missing_Project_File);
      elsif Row.Stale_Project_Index then
         Set_Status (Item, Status_Indeterminate_Stale_Project_Index);
      elsif Row.Duplicate_Library_Unit then
         Set_Status (Item, Status_Illegal_Duplicate_Library_Unit);
      elsif Row.Private_Child_Visibility_Leak then
         Set_Status (Item, Status_Illegal_Private_Child_Visibility_Leak);
      elsif not Row.Consumer_Surface_Agrees then
         Set_Status (Item, Status_Illegal_Consumer_Surface_Disagreement);
      elsif Row.Form = Project_Index_Open_Buffer_Precedence
        and then Row.Open_Buffer_Precedence
        and then Row.Dirty_Snapshot_Used then
         Set_Status (Item, Status_Legal_Open_Buffer_Project_Index_Agreement);
      end if;
   end Check_Project_Index_Rule;

   function Build (Input : Remediation_Input) return Remediation_Model is
      Results : Remediation_Model;
      Item : Remediation_Entry;
   begin
      Results.Total_Rows := Natural (Input.Rows.Length);
      for Row of Input.Rows loop
         Item := (Id => Row.Id,
                  Gap => Row.Gap,
                  Status => Status_Not_Checked,
                  Expected => Precision.Class_Unknown,
                  Blocker_Count => 0,
                  Result_Fingerprint => 0);

         Check_Remediation_Gates (Row, Item);
         if Item.Status = Status_Not_Checked then
            Check_Fingerprints (Row, Item);
         end if;
         if Item.Status = Status_Not_Checked then
            Check_Project_Index_Rule (Row, Item);
         end if;

         if Item.Status = Status_Not_Checked then
            Item.Status := Status_Gap_Remediated;
         end if;

         Item.Expected := Expected_For_Status (Item.Status);
         Item.Result_Fingerprint := Row_Fingerprint (Row)
           + Natural (Remediation_Status'Pos (Item.Status))
           + Item.Blocker_Count;
         Results.Audit_Fingerprint := Results.Audit_Fingerprint
           + Item.Result_Fingerprint;

         case Item.Expected is
            when Precision.Class_Legal =>
               Results.Remediated_Count := Results.Remediated_Count + 1;
            when Precision.Class_Legal_With_Runtime_Check =>
               Results.Runtime_Check_Count := Results.Runtime_Check_Count + 1;
            when Precision.Class_Illegal =>
               Results.Illegal_Count := Results.Illegal_Count + 1;
            when Precision.Class_Indeterminate =>
               Results.Indeterminate_Count := Results.Indeterminate_Count + 1;
            when others =>
               Results.Invalid_Count := Results.Invalid_Count + 1;
         end case;

         Results.Entries.Append (Item);
      end loop;
      return Results;
   end Build;

   function Result_For
     (Model : Remediation_Model;
      Id : Natural) return Remediation_Entry is
   begin
      for Item of Model.Entries loop
         if Item.Id = Id then
            return Item;
         end if;
      end loop;
      return (Id => Id,
              Gap => Remaining_Gap_Unknown,
              Status => Status_Not_Checked,
              Expected => Precision.Class_Unknown,
              Blocker_Count => 0,
              Result_Fingerprint => 0);
   end Result_For;

   function Gap_Remediated (Model : Remediation_Model) return Boolean is
   begin
      return Model.Total_Rows > 0
        and then Model.Remediated_Count > 0
        and then Model.Illegal_Count > 0
        and then Model.Indeterminate_Count > 0
        and then Model.Invalid_Count = 0;
   end Gap_Remediated;

end Editor.Ada_RM_Remaining_Gap_Remediation_Pass1384;
