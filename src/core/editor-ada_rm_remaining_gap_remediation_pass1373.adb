with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_RM_Remaining_Gap_Remediation_Pass1373 is

   procedure Add_Row (Input : in out Remediation_Input; Row : Remediation_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Row;

   function Expected_For_Status (Status : Remediation_Status)
      return Precision_Classification is
   begin
      case Status is
         when Status_Gap_Remediated
            | Status_Legal_Renamed_Visibility_Agreement =>
            return Precision.Class_Legal;
         when Status_Runtime_Access_Check_Preserved =>
            return Precision.Class_Legal_With_Runtime_Check;
         when Status_Illegal_Private_Child_Visibility_Leak
            | Status_Illegal_Renamed_Target_Invisible
            | Status_Illegal_Selected_Name_Ambiguous
            | Status_Illegal_Alias_Cycle
            | Status_Illegal_Alias_Depth_Overflow
            | Status_Illegal_Renamed_Profile_Mismatch
            | Status_Illegal_Renamed_Type_View_Mismatch
            | Status_Illegal_Use_Visible_Homograph_Conflict
            | Status_Illegal_Private_Full_View_Disagreement
            | Status_Illegal_Consumer_Surface_Disagreement =>
            return Precision.Class_Illegal;
         when Status_Indeterminate_Limited_View_Only
            | Status_Indeterminate_Private_View_Only
            | Status_Indeterminate_Missing_Cross_Unit_Evidence
            | Status_Indeterminate_Missing_Selected_Name_Evidence
            | Status_Indeterminate_Stale_Inventory_Evidence
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
            | Status_Entity_Fingerprint_Mismatch
            | Status_View_Fingerprint_Mismatch
            | Status_Profile_Fingerprint_Mismatch
            | Status_Alias_Fingerprint_Mismatch
            | Status_Visibility_Fingerprint_Mismatch
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
      if Item.Status = Status_Not_Checked then
         Item.Status := Status;
         Item.Blocker_Count := Item.Blocker_Count + 1;
      else
         Item.Status := Status_Multiple_Blockers;
         Item.Blocker_Count := Item.Blocker_Count + 1;
      end if;
   end Set_Status;

   function Text_Missing (Value : Unbounded_String) return Boolean is
   begin
      return Length (Value) = 0;
   end Text_Missing;

   function Row_Fingerprint (Row : Remediation_Row) return Natural is
   begin
      return Row.Id
        + Natural (Remediated_Gap_Family'Pos (Row.Gap)) * 3
        + Natural (Renaming_Form'Pos (Row.Form)) * 5
        + Natural (Visibility_Form'Pos (Row.Visibility)) * 7
        + Row.Source_Fingerprint + Row.AST_Fingerprint
        + Row.Entity_Fingerprint + Row.View_Fingerprint
        + Row.Profile_Fingerprint + Row.Alias_Fingerprint
        + Row.Visibility_Fingerprint + Row.Consumer_Fingerprint;
   end Row_Fingerprint;

   procedure Check_Remediation_Gates
     (Row : Remediation_Row;
      Item : in out Remediation_Entry) is
   begin
      if not Row.Inventory_Row_From_Pass1366 then
         Set_Status (Item, Status_Missing_Pass1366_Inventory_Row);
      elsif not Row.Named_Concrete_Subrule or else Text_Missing (Row.Concrete_Subrule) then
         Set_Status (Item, Status_Missing_Concrete_Subrule_Name);
      elsif not Row.Candidate_Owner_Named or else Text_Missing (Row.Candidate_Implementing_Package) then
         Set_Status (Item, Status_Missing_Candidate_Owner);
      elsif not Row.New_Legality_Rule_Added then
         Set_Status (Item, Status_No_New_Legality_Rule);
      elsif not Row.Source_Shaped_Evidence then
         Set_Status (Item, Status_Source_Shaped_Evidence_Missing);
      elsif not Row.Coverage_Promoted_To_Covered
        or else Row.Matrix_Level_After /= Matrix.Coverage_Covered then
         Set_Status (Item, Status_Coverage_Not_Promoted);
      elsif Row.Target_Remediation /= Remediation.State_Covered then
         Set_Status (Item, Status_Remediation_State_Not_Covered);
      elsif not Row.Final_Gate_No_Longer_Reports_Gap then
         Set_Status (Item, Status_Final_Gate_Still_Reports_Gap);
      elsif not (Row.Legal_Test_Present
                 and then Row.Illegal_Test_Present
                 and then Row.Runtime_Check_Test_Present
                 and then Row.Indeterminate_Test_Present) then
         Set_Status (Item, Status_Regression_Corpus_Not_Balanced);
      elsif not Row.Semantic_Result_Consumed then
         Set_Status (Item, Status_Semantic_Result_Unconsumed);
      elsif not Row.Consumer_Reached then
         Set_Status (Item, Status_Consumer_Not_Reached);
      elsif not Row.Stable_Blocker_Family or else Text_Missing (Row.Blocker_Family) then
         Set_Status (Item, Status_Unstable_Blocker_Family);
      end if;
   end Check_Remediation_Gates;

   procedure Check_Indeterminate_Evidence
     (Row : Remediation_Row;
      Item : in out Remediation_Entry) is
   begin
      if Row.Limited_View_Only then
         Set_Status (Item, Status_Indeterminate_Limited_View_Only);
      elsif Row.Private_View_Only then
         Set_Status (Item, Status_Indeterminate_Private_View_Only);
      elsif Row.Missing_Cross_Unit_Evidence then
         Set_Status (Item, Status_Indeterminate_Missing_Cross_Unit_Evidence);
      elsif Row.Missing_Selected_Name_Evidence then
         Set_Status (Item, Status_Indeterminate_Missing_Selected_Name_Evidence);
      elsif Row.Stale_Inventory_Evidence then
         Set_Status (Item, Status_Indeterminate_Stale_Inventory_Evidence);
      end if;
   end Check_Indeterminate_Evidence;

   procedure Check_Fingerprints
     (Row : Remediation_Row;
      Item : in out Remediation_Entry) is
   begin
      if Row.Source_Fingerprint /= Row.Expected_Source_Fingerprint then
         Set_Status (Item, Status_Source_Fingerprint_Mismatch);
      elsif Row.AST_Fingerprint /= Row.Expected_AST_Fingerprint then
         Set_Status (Item, Status_AST_Fingerprint_Mismatch);
      elsif Row.Entity_Fingerprint /= Row.Expected_Entity_Fingerprint then
         Set_Status (Item, Status_Entity_Fingerprint_Mismatch);
      elsif Row.View_Fingerprint /= Row.Expected_View_Fingerprint then
         Set_Status (Item, Status_View_Fingerprint_Mismatch);
      elsif Row.Profile_Fingerprint /= Row.Expected_Profile_Fingerprint then
         Set_Status (Item, Status_Profile_Fingerprint_Mismatch);
      elsif Row.Alias_Fingerprint /= Row.Expected_Alias_Fingerprint then
         Set_Status (Item, Status_Alias_Fingerprint_Mismatch);
      elsif Row.Visibility_Fingerprint /= Row.Expected_Visibility_Fingerprint then
         Set_Status (Item, Status_Visibility_Fingerprint_Mismatch);
      elsif Row.Consumer_Fingerprint /= Row.Expected_Consumer_Fingerprint then
         Set_Status (Item, Status_Consumer_Fingerprint_Mismatch);
      end if;
   end Check_Fingerprints;

   procedure Check_Renamed_Visibility_Rule
     (Row : Remediation_Row;
      Item : in out Remediation_Entry) is
   begin
      if not Row.Private_Child_Visible then
         Set_Status (Item, Status_Illegal_Private_Child_Visibility_Leak);
      elsif not Row.Renamed_Target_Visible then
         Set_Status (Item, Status_Illegal_Renamed_Target_Invisible);
      elsif not Row.Selected_Name_Unambiguous then
         Set_Status (Item, Status_Illegal_Selected_Name_Ambiguous);
      elsif Row.Alias_Cycle then
         Set_Status (Item, Status_Illegal_Alias_Cycle);
      elsif Row.Alias_Depth_Overflow then
         Set_Status (Item, Status_Illegal_Alias_Depth_Overflow);
      elsif not Row.Renamed_Profile_Agrees then
         Set_Status (Item, Status_Illegal_Renamed_Profile_Mismatch);
      elsif not Row.Renamed_Type_View_Agrees then
         Set_Status (Item, Status_Illegal_Renamed_Type_View_Mismatch);
      elsif Row.Use_Visible_Homograph_Conflict then
         Set_Status (Item, Status_Illegal_Use_Visible_Homograph_Conflict);
      elsif not Row.Private_Full_View_Agrees then
         Set_Status (Item, Status_Illegal_Private_Full_View_Disagreement);
      elsif not Row.Consumer_Surface_Agrees then
         Set_Status (Item, Status_Illegal_Consumer_Surface_Disagreement);
      elsif Row.Runtime_Access_Check then
         Set_Status (Item, Status_Runtime_Access_Check_Preserved);
      elsif Row.Visibility = Visibility_Compatible then
         Set_Status (Item, Status_Legal_Renamed_Visibility_Agreement);
      end if;
   end Check_Renamed_Visibility_Rule;

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
            Check_Indeterminate_Evidence (Row, Item);
         end if;
         if Item.Status = Status_Not_Checked then
            Check_Fingerprints (Row, Item);
         end if;
         if Item.Status = Status_Not_Checked then
            Check_Renamed_Visibility_Rule (Row, Item);
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
        and then Model.Runtime_Check_Count > 0
        and then Model.Indeterminate_Count > 0
        and then Model.Invalid_Count = 0;
   end Gap_Remediated;

end Editor.Ada_RM_Remaining_Gap_Remediation_Pass1373;
