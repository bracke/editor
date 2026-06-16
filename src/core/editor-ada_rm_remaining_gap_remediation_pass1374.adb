with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_RM_Remaining_Gap_Remediation_Pass1374 is

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
            | Status_Legal_Static_String_Bounds_Agreement =>
            return Precision.Class_Legal;
         when Status_Runtime_Index_Check_Preserved
            | Status_Runtime_Range_Check_Preserved =>
            return Precision.Class_Legal_With_Runtime_Check;
         when Status_Illegal_Static_Lower_Above_Upper
            | Status_Illegal_Static_Index_Out_Of_Range
            | Status_Illegal_String_Length_Mismatch
            | Status_Illegal_Character_Element_Mismatch
            | Status_Illegal_Null_Literal_Non_Access_Context
            | Status_Illegal_Consumer_Surface_Disagreement =>
            return Precision.Class_Illegal;
         when Status_Indeterminate_Missing_Expected_Array_Type
            | Status_Indeterminate_Missing_Index_Subtype
            | Status_Indeterminate_Stale_Static_Evidence
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
            | Status_Type_Fingerprint_Mismatch
            | Status_Static_Fingerprint_Mismatch
            | Status_Choice_Fingerprint_Mismatch
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
        + Natural (Literal_Context'Pos (Row.Context)) * 5
        + Natural (Bounds_Form'Pos (Row.Bounds)) * 7
        + Row.Source_Fingerprint + Row.AST_Fingerprint
        + Row.Type_Fingerprint + Row.Static_Fingerprint
        + Row.Choice_Fingerprint + Row.Consumer_Fingerprint;
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
      if not Row.Expected_Array_Type_Present then
         Set_Status (Item, Status_Indeterminate_Missing_Expected_Array_Type);
      elsif not Row.Index_Subtype_Present then
         Set_Status (Item, Status_Indeterminate_Missing_Index_Subtype);
      elsif Row.Stale_Static_Evidence then
         Set_Status (Item, Status_Indeterminate_Stale_Static_Evidence);
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
      elsif Row.Type_Fingerprint /= Row.Expected_Type_Fingerprint then
         Set_Status (Item, Status_Type_Fingerprint_Mismatch);
      elsif Row.Static_Fingerprint /= Row.Expected_Static_Fingerprint then
         Set_Status (Item, Status_Static_Fingerprint_Mismatch);
      elsif Row.Choice_Fingerprint /= Row.Expected_Choice_Fingerprint then
         Set_Status (Item, Status_Choice_Fingerprint_Mismatch);
      elsif Row.Consumer_Fingerprint /= Row.Expected_Consumer_Fingerprint then
         Set_Status (Item, Status_Consumer_Fingerprint_Mismatch);
      end if;
   end Check_Fingerprints;

   procedure Check_Static_String_Bounds_Rule
     (Row : Remediation_Row;
      Item : in out Remediation_Entry) is
   begin
      if Row.Static_Lower_Above_Upper then
         Set_Status (Item, Status_Illegal_Static_Lower_Above_Upper);
      elsif Row.Static_Index_Out_Of_Range then
         Set_Status (Item, Status_Illegal_Static_Index_Out_Of_Range);
      elsif not Row.String_Length_Matches_Target then
         Set_Status (Item, Status_Illegal_String_Length_Mismatch);
      elsif not Row.Character_Element_Compatible then
         Set_Status (Item, Status_Illegal_Character_Element_Mismatch);
      elsif not Row.Null_Literal_In_Access_Context then
         Set_Status (Item, Status_Illegal_Null_Literal_Non_Access_Context);
      elsif not Row.Consumer_Surface_Agrees then
         Set_Status (Item, Status_Illegal_Consumer_Surface_Disagreement);
      elsif Row.Runtime_Index_Check then
         Set_Status (Item, Status_Runtime_Index_Check_Preserved);
      elsif Row.Runtime_Range_Check then
         Set_Status (Item, Status_Runtime_Range_Check_Preserved);
      elsif Row.Bounds = Bounds_Compatible then
         Set_Status (Item, Status_Legal_Static_String_Bounds_Agreement);
      end if;
   end Check_Static_String_Bounds_Rule;

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
            Check_Static_String_Bounds_Rule (Row, Item);
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

end Editor.Ada_RM_Remaining_Gap_Remediation_Pass1374;
