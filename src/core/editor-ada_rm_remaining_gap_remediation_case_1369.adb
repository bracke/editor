with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_RM_Remaining_Gap_Remediation_Case_1369 is

   pragma Suppress (Overflow_Check);
   use type Matrix.Coverage_Level;
   use type Remediation.Remediation_State;
   use type Precision.Precision_Classification;
   use type Consumers.Semantic_Consumer;


   procedure Add_Blocker
     (Result : in out Remediation_Entry;
      Status : Remediation_Status) is
   begin
      Result.Status := Status;
      Result.Blocker_Count := Result.Blocker_Count + 1;
   end Add_Blocker;

   function Expected_For_Status
     (Status : Remediation_Status) return Precision_Classification is
   begin
      case Status is
         when Status_Gap_Remediated
            | Status_Legal_Stream_External_Agreement =>
            return Precision.Class_Legal;
         when Status_Runtime_Address_Check_Preserved =>
            return Precision.Class_Legal_With_Runtime_Check;
         when Status_Illegal_Stream_Profile_Mismatch
            | Status_Illegal_Import_Stream_Conflict
            | Status_Illegal_Export_Stream_Conflict
            | Status_Illegal_Convention_Profile_Mismatch
            | Status_Illegal_Late_Stream_Item_After_Freezing
            | Status_Illegal_Stream_Target_Kind_Mismatch
            | Status_Illegal_Operational_Item_Duplicate
            | Status_Illegal_External_Name_Missing
            | Status_Illegal_Link_Name_Mismatch
            | Status_Illegal_C_Callable_Profile_Mismatch
            | Status_Illegal_Access_Subprogram_Convention_Lost
            | Status_Illegal_Representation_Evidence_Lost
            | Status_Illegal_Freezing_Evidence_Lost
            | Status_Illegal_Consumer_Surface_Disagreement
            | Status_Missing_Final_Inventory_Row
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
            | Status_Unstable_Blocker_Family =>
            return Precision.Class_Illegal;
         when Status_Indeterminate_Private_View_Only
            | Status_Indeterminate_Limited_View_Only
            | Status_Indeterminate_Missing_Stream_Profile
            | Status_Indeterminate_Missing_Convention_Evidence
            | Status_Indeterminate_Missing_Freezing_Evidence
            | Status_Indeterminate_Missing_Cross_Unit_Evidence
            | Status_Indeterminate_Stale_Inventory_Evidence
            | Status_Source_Fingerprint_Mismatch
            | Status_AST_Fingerprint_Mismatch
            | Status_Stream_Fingerprint_Mismatch
            | Status_Type_Fingerprint_Mismatch
            | Status_Profile_Fingerprint_Mismatch
            | Status_Representation_Fingerprint_Mismatch
            | Status_Freezing_Fingerprint_Mismatch
            | Status_Convention_Fingerprint_Mismatch
            | Status_Consumer_Fingerprint_Mismatch
            | Status_Indeterminate =>
            return Precision.Class_Indeterminate;
         when others =>
            return Precision.Class_Unknown;
      end case;
   end Expected_For_Status;

   procedure Check_Remediation_Gates
     (Row : Remediation_Row;
      Result : in out Remediation_Entry) is
   begin
      if not Row.Inventory_Row_From_Final_Burn_Down then
         Add_Blocker (Result, Status_Missing_Final_Inventory_Row);
      elsif not Row.Named_Concrete_Subrule
        or else Length (Row.Concrete_Subrule) = 0
      then
         Add_Blocker (Result, Status_Missing_Concrete_Subrule_Name);
      elsif not Row.Candidate_Owner_Named
        or else Length (Row.Candidate_Implementing_Package) = 0
      then
         Add_Blocker (Result, Status_Missing_Candidate_Owner);
      elsif not Row.New_Legality_Rule_Added then
         Add_Blocker (Result, Status_No_New_Legality_Rule);
      elsif not Row.Source_Shaped_Evidence then
         Add_Blocker (Result, Status_Source_Shaped_Evidence_Missing);
      elsif not Row.Coverage_Promoted_To_Covered
        or else Row.Matrix_Level_After /= Matrix.Coverage_Covered
      then
         Add_Blocker (Result, Status_Coverage_Not_Promoted);
      elsif Row.Target_Remediation /= Remediation.State_Covered then
         Add_Blocker (Result, Status_Remediation_State_Not_Covered);
      elsif not Row.Final_Gate_No_Longer_Reports_Gap then
         Add_Blocker (Result, Status_Final_Gate_Still_Reports_Gap);
      elsif not (Row.Legal_Test_Present
                 and Row.Illegal_Test_Present
                 and Row.Runtime_Check_Test_Present
                 and Row.Indeterminate_Test_Present
                 and Row.Consumer_Surfaced_Test_Present)
      then
         Add_Blocker (Result, Status_Regression_Corpus_Not_Balanced);
      elsif not Row.Semantic_Result_Consumed then
         Add_Blocker (Result, Status_Semantic_Result_Unconsumed);
      elsif not Row.Consumer_Reached then
         Add_Blocker (Result, Status_Consumer_Not_Reached);
      elsif not Row.Stable_Blocker_Family then
         Add_Blocker (Result, Status_Unstable_Blocker_Family);
      end if;
   end Check_Remediation_Gates;

   procedure Check_Indeterminate_Evidence
     (Row : Remediation_Row;
      Result : in out Remediation_Entry) is
   begin
      if Row.Private_View_Only then
         Add_Blocker (Result, Status_Indeterminate_Private_View_Only);
      elsif Row.Limited_View_Only then
         Add_Blocker (Result, Status_Indeterminate_Limited_View_Only);
      elsif Row.Missing_Stream_Profile then
         Add_Blocker (Result, Status_Indeterminate_Missing_Stream_Profile);
      elsif Row.Missing_Convention_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Convention_Evidence);
      elsif Row.Missing_Freezing_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Freezing_Evidence);
      elsif Row.Missing_Cross_Unit_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Cross_Unit_Evidence);
      elsif Row.Stale_Inventory_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Stale_Inventory_Evidence);
      end if;
   end Check_Indeterminate_Evidence;

   procedure Check_Fingerprints
     (Row : Remediation_Row;
      Result : in out Remediation_Entry) is
   begin
      if Row.Source_Fingerprint /= Row.Expected_Source_Fingerprint then
         Add_Blocker (Result, Status_Source_Fingerprint_Mismatch);
      elsif Row.AST_Fingerprint /= Row.Expected_AST_Fingerprint then
         Add_Blocker (Result, Status_AST_Fingerprint_Mismatch);
      elsif Row.Stream_Fingerprint /= Row.Expected_Stream_Fingerprint then
         Add_Blocker (Result, Status_Stream_Fingerprint_Mismatch);
      elsif Row.Type_Fingerprint /= Row.Expected_Type_Fingerprint then
         Add_Blocker (Result, Status_Type_Fingerprint_Mismatch);
      elsif Row.Profile_Fingerprint /= Row.Expected_Profile_Fingerprint then
         Add_Blocker (Result, Status_Profile_Fingerprint_Mismatch);
      elsif Row.Representation_Fingerprint /= Row.Expected_Representation_Fingerprint then
         Add_Blocker (Result, Status_Representation_Fingerprint_Mismatch);
      elsif Row.Freezing_Fingerprint /= Row.Expected_Freezing_Fingerprint then
         Add_Blocker (Result, Status_Freezing_Fingerprint_Mismatch);
      elsif Row.Convention_Fingerprint /= Row.Expected_Convention_Fingerprint then
         Add_Blocker (Result, Status_Convention_Fingerprint_Mismatch);
      elsif Row.Consumer_Fingerprint /= Row.Expected_Consumer_Fingerprint then
         Add_Blocker (Result, Status_Consumer_Fingerprint_Mismatch);
      end if;
   end Check_Fingerprints;

   procedure Check_Stream_External_Rule
     (Row : Remediation_Row;
      Result : in out Remediation_Entry) is
   begin
      if not Row.Stream_Profile_Present then
         Add_Blocker (Result, Status_Indeterminate_Missing_Stream_Profile);
      elsif not Row.Stream_Profile_Conforms then
         Add_Blocker (Result, Status_Illegal_Stream_Profile_Mismatch);
      elsif not Row.Target_Kind_Valid then
         Add_Blocker (Result, Status_Illegal_Stream_Target_Kind_Mismatch);
      elsif Row.Import_Stream_Conflict then
         Add_Blocker (Result, Status_Illegal_Import_Stream_Conflict);
      elsif Row.Export_Stream_Conflict then
         Add_Blocker (Result, Status_Illegal_Export_Stream_Conflict);
      elsif not Row.Convention_Profile_Agrees then
         Add_Blocker (Result, Status_Illegal_Convention_Profile_Mismatch);
      elsif not Row.C_Callable_Profile_Agrees then
         Add_Blocker (Result, Status_Illegal_C_Callable_Profile_Mismatch);
      elsif not Row.Access_Subprogram_Convention_Preserved then
         Add_Blocker (Result, Status_Illegal_Access_Subprogram_Convention_Lost);
      elsif not Row.External_Name_Present then
         Add_Blocker (Result, Status_Illegal_External_Name_Missing);
      elsif not Row.Link_Name_Agrees then
         Add_Blocker (Result, Status_Illegal_Link_Name_Mismatch);
      elsif Row.Duplicate_Operational_Item then
         Add_Blocker (Result, Status_Illegal_Operational_Item_Duplicate);
      elsif not Row.Representation_Evidence_Preserved then
         Add_Blocker (Result, Status_Illegal_Representation_Evidence_Lost);
      elsif not Row.Freezing_Evidence_Preserved then
         Add_Blocker (Result, Status_Illegal_Freezing_Evidence_Lost);
      elsif not Row.Stream_Item_Before_Freezing then
         Add_Blocker (Result, Status_Illegal_Late_Stream_Item_After_Freezing);
      elsif not Row.Consumer_Surface_Agrees then
         Add_Blocker (Result, Status_Illegal_Consumer_Surface_Disagreement);
      elsif Row.Runtime_Address_Check then
         Add_Blocker (Result, Status_Runtime_Address_Check_Preserved);
      elsif Row.Expected = Precision.Class_Legal_With_Runtime_Check then
         Add_Blocker (Result, Status_Runtime_Address_Check_Preserved);
      elsif Row.Expected = Precision.Class_Legal then
         Add_Blocker (Result, Status_Legal_Stream_External_Agreement);
      else
         Add_Blocker (Result, Status_Gap_Remediated);
      end if;
   end Check_Stream_External_Rule;

   function Row_Fingerprint (Row : Remediation_Row) return Natural is
   begin
      return Row.Id
        + Natural (Remediated_Gap_Family'Pos (Row.Gap))
        + Natural (RM_Family'Pos (Row.Family))
        + Natural (Stream_Item_Form'Pos (Row.Form))
        + Natural (External_Representation_Form'Pos (Row.External))
        + Natural (Semantic_Consumer'Pos (Row.Consumer))
        + Natural (Precision_Classification'Pos (Row.Expected))
        + Row.Source_Fingerprint
        + Row.AST_Fingerprint
        + Row.Stream_Fingerprint
        + Row.Type_Fingerprint
        + Row.Profile_Fingerprint
        + Row.Representation_Fingerprint
        + Row.Freezing_Fingerprint
        + Row.Convention_Fingerprint
        + Row.Consumer_Fingerprint;
   end Row_Fingerprint;

   procedure Add_Row (Input : in out Remediation_Input; Row : Remediation_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Row;

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
            Check_Stream_External_Rule (Row, Item);
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

   function Count (Results : Remediation_Model) return Natural is
   begin
      return Natural (Results.Entries.Length);
   end Count;

   function Result_At (Results : Remediation_Model; Index : Positive)
     return Remediation_Entry is
   begin
      return Results.Entries.Element (Index - 1);
   end Result_At;

   function Result_For (Results : Remediation_Model; Id : Natural)
     return Remediation_Entry is
      Empty : Remediation_Entry;
   begin
      for Item of Results.Entries loop
         if Item.Id = Id then
            return Item;
         end if;
      end loop;
      return Empty;
   end Result_For;

   function Gap_Remediated (Results : Remediation_Model) return Boolean is
   begin
      return Results.Total_Rows > 0
        and then Results.Invalid_Count = 0
        and then Results.Illegal_Count > 0
        and then Results.Runtime_Check_Count > 0
        and then Results.Indeterminate_Count > 0
        and then Results.Remediated_Count > 0;
   end Gap_Remediated;

end Editor.Ada_RM_Remaining_Gap_Remediation_Case_1369;
