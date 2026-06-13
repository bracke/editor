package body Editor.Ada_RM_Gap_Burn_Down_Pass1358 is

   function Is_Valid_Status (Status : Burn_Down_Status) return Boolean is
   begin
      return Status in
        Status_Gap_Burned_Down
        | Status_Legal_Gap_Burned_Down
        | Status_Runtime_String_Bounds_Check_Preserved
        | Status_Runtime_Range_Check_Preserved
        | Status_Illegal_Standard_Entity_Identity_Disagreement
        | Status_Illegal_Standard_Entity_Missing
        | Status_Illegal_Predefined_Exception_Identity_Disagreement
        | Status_Illegal_Predefined_Attribute_Identity_Disagreement
        | Status_Illegal_Predefined_Operator_Identity_Disagreement
        | Status_Illegal_Integer_Literal_Resolution_Disagreement
        | Status_Illegal_Real_Literal_Resolution_Disagreement
        | Status_Illegal_Static_Overload_Literal_Disagreement
        | Status_Illegal_Character_Enumeration_Literal_Ambiguity
        | Status_Illegal_String_Literal_Array_Incompatible
        | Status_Illegal_Wide_String_Literal_Incompatible
        | Status_Illegal_Null_Literal_No_Access_Context
        | Status_Illegal_Null_Literal_Access_View_Disagreement
        | Status_Illegal_Root_Type_Identity_Disagreement
        | Status_Illegal_Universal_Type_Conversion_Disagreement
        | Status_Illegal_Expected_Type_Literal_Context_Lost
        | Status_Illegal_Aggregate_Assignment_Literal_Disagreement
        | Status_Illegal_Subtype_Range_Literal_Disagreement
        | Status_Illegal_Diagnostics_Predefined_Disagreement
        | Status_Illegal_Colouring_Predefined_Disagreement
        | Status_Illegal_Outline_Predefined_Disagreement
        | Status_Illegal_Navigation_Predefined_Disagreement
        | Status_Illegal_Hover_Predefined_Disagreement
        | Status_Illegal_Diagnostic_Bridge_Predefined_Disagreement
        | Status_Indeterminate_Private_View
        | Status_Indeterminate_Limited_View
        | Status_Indeterminate_Incomplete_View
        | Status_Indeterminate_Generic_Formal_View
        | Status_Indeterminate_Missing_Full_View
        | Status_Indeterminate_Missing_Cross_Unit_Evidence
        | Status_Indeterminate_Missing_Predefined_Environment
        | Status_Indeterminate_Missing_Literal_Evidence
        | Status_Indeterminate_Missing_Type_Evidence
        | Status_Indeterminate_Missing_Expected_Type_Evidence
        | Status_Indeterminate_Missing_Static_Evidence
        | Status_Indeterminate_Missing_Overload_Evidence
        | Status_Indeterminate_Missing_Profile_Evidence
        | Status_Indeterminate_Missing_Substitution_Evidence
        | Status_Indeterminate_Missing_Consumer_Evidence;
   end Is_Valid_Status;

   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification is
   begin
      case Status is
         when Status_Gap_Burned_Down
            | Status_Legal_Gap_Burned_Down =>
            return Precision.Class_Legal;
         when Status_Runtime_String_Bounds_Check_Preserved
            | Status_Runtime_Range_Check_Preserved
            | Status_Runtime_Check_Evidence_Lost =>
            return Precision.Class_Legal_With_Runtime_Check;
         when Status_Illegal_Standard_Entity_Identity_Disagreement
            | Status_Illegal_Standard_Entity_Missing
            | Status_Illegal_Predefined_Exception_Identity_Disagreement
            | Status_Illegal_Predefined_Attribute_Identity_Disagreement
            | Status_Illegal_Predefined_Operator_Identity_Disagreement
            | Status_Illegal_Integer_Literal_Resolution_Disagreement
            | Status_Illegal_Real_Literal_Resolution_Disagreement
            | Status_Illegal_Static_Overload_Literal_Disagreement
            | Status_Illegal_Character_Enumeration_Literal_Ambiguity
            | Status_Illegal_String_Literal_Array_Incompatible
            | Status_Illegal_Wide_String_Literal_Incompatible
            | Status_Illegal_Null_Literal_No_Access_Context
            | Status_Illegal_Null_Literal_Access_View_Disagreement
            | Status_Illegal_Root_Type_Identity_Disagreement
            | Status_Illegal_Universal_Type_Conversion_Disagreement
            | Status_Illegal_Expected_Type_Literal_Context_Lost
            | Status_Illegal_Aggregate_Assignment_Literal_Disagreement
            | Status_Illegal_Subtype_Range_Literal_Disagreement
            | Status_Illegal_Diagnostics_Predefined_Disagreement
            | Status_Illegal_Colouring_Predefined_Disagreement
            | Status_Illegal_Outline_Predefined_Disagreement
            | Status_Illegal_Navigation_Predefined_Disagreement
            | Status_Illegal_Hover_Predefined_Disagreement
            | Status_Illegal_Diagnostic_Bridge_Predefined_Disagreement =>
            return Precision.Class_Illegal;
         when Status_Indeterminate_Private_View
            | Status_Indeterminate_Limited_View
            | Status_Indeterminate_Incomplete_View
            | Status_Indeterminate_Generic_Formal_View
            | Status_Indeterminate_Missing_Full_View
            | Status_Indeterminate_Missing_Cross_Unit_Evidence
            | Status_Indeterminate_Missing_Predefined_Environment
            | Status_Indeterminate_Missing_Literal_Evidence
            | Status_Indeterminate_Missing_Type_Evidence
            | Status_Indeterminate_Missing_Expected_Type_Evidence
            | Status_Indeterminate_Missing_Static_Evidence
            | Status_Indeterminate_Missing_Overload_Evidence
            | Status_Indeterminate_Missing_Profile_Evidence
            | Status_Indeterminate_Missing_Substitution_Evidence
            | Status_Indeterminate_Missing_Consumer_Evidence
            | Status_Indeterminate =>
            return Precision.Class_Indeterminate;
         when others =>
            return Precision.Class_Unknown;
      end case;
   end Expected_For_Status;

   procedure Add_Blocker
     (Result : in out Burn_Down_Entry;
      Status : Burn_Down_Status) is
   begin
      Result.Blocker_Count := Result.Blocker_Count + 1;
      if Result.Status = Status_Not_Checked then
         Result.Status := Status;
      elsif Result.Status /= Status then
         Result.Status := Status_Multiple_Blockers;
      end if;
   end Add_Blocker;

   procedure Check_Audit_Gates
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if not Row.Remediation_Entry_Present then
         Add_Blocker (Result, Status_Missing_Remediation_Evidence);
      end if;
      if not Row.Matrix_Coverage_Present then
         Add_Blocker (Result, Status_Missing_Matrix_Coverage);
      end if;
      if not Row.Implementing_Package_Present then
         Add_Blocker (Result, Status_Missing_Implementing_Package);
      end if;
      if not Row.New_Legality_Rule_Added then
         Add_Blocker (Result, Status_No_New_Legality_Rule);
      end if;
      if not Row.Coverage_Entry_Updated_To_Covered then
         Add_Blocker (Result, Status_Coverage_Not_Updated_To_Covered);
      end if;
      if not Row.Balanced_Regression_Evidence then
         Add_Blocker (Result, Status_Regression_Corpus_Not_Balanced);
      end if;
      if not Row.Semantic_Result_Consumed then
         Add_Blocker (Result, Status_Semantic_Result_Unconsumed);
      end if;
      if not Row.Consumer_Reached then
         Add_Blocker (Result, Status_Consumer_Not_Reached);
      end if;
      if not Row.Source_Shaped_Evidence then
         Add_Blocker (Result, Status_Source_Shaped_Evidence_Missing);
      end if;
      if not Row.Stable_Blocker_Family then
         Add_Blocker (Result, Status_Unstable_Blocker_Family);
      end if;
   end Check_Audit_Gates;

   procedure Check_Fingerprints
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if Row.Evidence_Stale
        or else Row.Burn_Down_Fingerprint /= Row.Expected_Burn_Down_Fingerprint
      then
         Add_Blocker (Result, Status_Stale_Burn_Down_Fingerprint);
      end if;
      if Row.Source_Fingerprint /= Row.Expected_Source_Fingerprint then
         Add_Blocker (Result, Status_Source_Fingerprint_Mismatch);
      end if;
      if Row.AST_Fingerprint /= Row.Expected_AST_Fingerprint then
         Add_Blocker (Result, Status_AST_Fingerprint_Mismatch);
      end if;
      if Row.Predefined_Fingerprint /= Row.Expected_Predefined_Fingerprint then
         Add_Blocker (Result, Status_Predefined_Fingerprint_Mismatch);
      end if;
      if Row.Literal_Fingerprint /= Row.Expected_Literal_Fingerprint then
         Add_Blocker (Result, Status_Literal_Fingerprint_Mismatch);
      end if;
      if Row.Root_Type_Fingerprint /= Row.Expected_Root_Type_Fingerprint then
         Add_Blocker (Result, Status_Root_Type_Fingerprint_Mismatch);
      end if;
      if Row.Type_Fingerprint /= Row.Expected_Type_Fingerprint then
         Add_Blocker (Result, Status_Type_Fingerprint_Mismatch);
      end if;
      if Row.Expected_Type_Context_Fingerprint /=
        Row.Expected_Expected_Type_Context_Fingerprint
      then
         Add_Blocker (Result, Status_Expected_Type_Fingerprint_Mismatch);
      end if;
      if Row.Static_Fingerprint /= Row.Expected_Static_Fingerprint then
         Add_Blocker (Result, Status_Static_Fingerprint_Mismatch);
      end if;
      if Row.Overload_Fingerprint /= Row.Expected_Overload_Fingerprint then
         Add_Blocker (Result, Status_Overload_Fingerprint_Mismatch);
      end if;
      if Row.Profile_Fingerprint /= Row.Expected_Profile_Fingerprint then
         Add_Blocker (Result, Status_Profile_Fingerprint_Mismatch);
      end if;
      if Row.Substitution_Fingerprint /= Row.Expected_Substitution_Fingerprint then
         Add_Blocker (Result, Status_Substitution_Fingerprint_Mismatch);
      end if;
      if Row.Consumer_Fingerprint /= Row.Expected_Consumer_Fingerprint then
         Add_Blocker (Result, Status_Consumer_Fingerprint_Mismatch);
      end if;
   end Check_Fingerprints;

   procedure Check_Indeterminate_Evidence
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if Row.Private_View then
         Add_Blocker (Result, Status_Indeterminate_Private_View);
      end if;
      if Row.Limited_View then
         Add_Blocker (Result, Status_Indeterminate_Limited_View);
      end if;
      if Row.Incomplete_View then
         Add_Blocker (Result, Status_Indeterminate_Incomplete_View);
      end if;
      if Row.Generic_Formal_View then
         Add_Blocker (Result, Status_Indeterminate_Generic_Formal_View);
      end if;
      if Row.Missing_Full_View then
         Add_Blocker (Result, Status_Indeterminate_Missing_Full_View);
      end if;
      if Row.Missing_Cross_Unit_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Cross_Unit_Evidence);
      end if;
      if Row.Missing_Predefined_Environment then
         Add_Blocker (Result, Status_Indeterminate_Missing_Predefined_Environment);
      end if;
      if Row.Missing_Literal_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Literal_Evidence);
      end if;
      if Row.Missing_Type_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Type_Evidence);
      end if;
      if Row.Missing_Expected_Type_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Expected_Type_Evidence);
      end if;
      if Row.Missing_Static_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Static_Evidence);
      end if;
      if Row.Missing_Overload_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Overload_Evidence);
      end if;
      if Row.Missing_Profile_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Profile_Evidence);
      end if;
      if Row.Missing_Substitution_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Substitution_Evidence);
      end if;
      if Row.Missing_Consumer_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Consumer_Evidence);
      end if;
   end Check_Indeterminate_Evidence;

   procedure Check_Predefined_Environment
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if not Row.Same_Standard_Entity then
         Add_Blocker (Result,
                      Status_Illegal_Standard_Entity_Identity_Disagreement);
      end if;
      if not Row.Standard_Entity_Present then
         Add_Blocker (Result, Status_Illegal_Standard_Entity_Missing);
      end if;
      if not Row.Predefined_Exception_Identity_Agrees then
         Add_Blocker (Result,
                      Status_Illegal_Predefined_Exception_Identity_Disagreement);
      end if;
      if not Row.Predefined_Attribute_Identity_Agrees then
         Add_Blocker (Result,
                      Status_Illegal_Predefined_Attribute_Identity_Disagreement);
      end if;
      if not Row.Predefined_Operator_Identity_Agrees then
         Add_Blocker (Result,
                      Status_Illegal_Predefined_Operator_Identity_Disagreement);
      end if;
      if not Row.Root_Type_Identity_Agrees then
         Add_Blocker (Result, Status_Illegal_Root_Type_Identity_Disagreement);
      end if;
      if not Row.Universal_Type_Conversion_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Universal_Type_Conversion_Disagreement);
      end if;
   end Check_Predefined_Environment;

   procedure Check_Literal_Resolution
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if not Row.Integer_Literal_Resolution_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Integer_Literal_Resolution_Disagreement);
      end if;
      if not Row.Real_Literal_Resolution_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Real_Literal_Resolution_Disagreement);
      end if;
      if not Row.Static_Evaluation_Agrees_With_Overload then
         Add_Blocker
           (Result, Status_Illegal_Static_Overload_Literal_Disagreement);
      end if;
      if Row.Character_Enumeration_Literal_Ambiguous then
         Add_Blocker
           (Result, Status_Illegal_Character_Enumeration_Literal_Ambiguity);
      end if;
      if not Row.String_Literal_Array_Compatible then
         Add_Blocker
           (Result, Status_Illegal_String_Literal_Array_Incompatible);
      end if;
      if not Row.Wide_String_Literal_Compatible then
         Add_Blocker
           (Result, Status_Illegal_Wide_String_Literal_Incompatible);
      end if;
      if not Row.Null_Literal_Has_Access_Context then
         Add_Blocker (Result, Status_Illegal_Null_Literal_No_Access_Context);
      end if;
      if not Row.Null_Literal_Access_View_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Null_Literal_Access_View_Disagreement);
      end if;
      if not Row.Expected_Type_Context_Preserved then
         Add_Blocker
           (Result, Status_Illegal_Expected_Type_Literal_Context_Lost);
      end if;
      if not Row.Aggregate_Assignment_Literal_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Aggregate_Assignment_Literal_Disagreement);
      end if;
      if not Row.Subtype_Range_Literal_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Subtype_Range_Literal_Disagreement);
      end if;
      if Row.Runtime_String_Bounds_Check then
         if Row.Runtime_Check_Evidence_Preserved then
            Add_Blocker (Result,
                         Status_Runtime_String_Bounds_Check_Preserved);
         else
            Add_Blocker (Result, Status_Runtime_Check_Evidence_Lost);
         end if;
      end if;
      if Row.Runtime_Range_Check then
         if Row.Runtime_Check_Evidence_Preserved then
            Add_Blocker (Result, Status_Runtime_Range_Check_Preserved);
         else
            Add_Blocker (Result, Status_Runtime_Check_Evidence_Lost);
         end if;
      end if;
   end Check_Literal_Resolution;

   procedure Check_Consumers
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if not Row.Consumer_Predefined_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Diagnostics_Predefined_Disagreement);
      end if;
      if not Row.Consumer_Colouring_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Colouring_Predefined_Disagreement);
      end if;
      if not Row.Consumer_Outline_Agrees then
         Add_Blocker (Result, Status_Illegal_Outline_Predefined_Disagreement);
      end if;
      if not Row.Consumer_Navigation_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Navigation_Predefined_Disagreement);
      end if;
      if not Row.Consumer_Hover_Agrees then
         Add_Blocker (Result, Status_Illegal_Hover_Predefined_Disagreement);
      end if;
      if not Row.Consumer_Bridge_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Diagnostic_Bridge_Predefined_Disagreement);
      end if;
   end Check_Consumers;

   function Evaluate (Row : Burn_Down_Row) return Burn_Down_Entry is
      Result : Burn_Down_Entry;
   begin
      Result.Id := Row.Id;
      Result.Gap := Row.Gap;
      Result.Family := Row.Family;
      Result.Owner := Row.Owner;
      Result.Consumer := Row.Consumer;
      Result.Expected := Row.Expected;
      Result.Construct := Row.Construct;
      Result.Context := Row.Context;
      Result.Result_Fingerprint :=
        Row.Id
        + Natural (Burn_Down_Gap'Pos (Row.Gap))
        + Natural (Predefined_Construct_Kind'Pos (Row.Construct))
        + Natural (Resolution_Context_Kind'Pos (Row.Context))
        + Row.Source_Fingerprint
        + Row.AST_Fingerprint
        + Row.Predefined_Fingerprint
        + Row.Literal_Fingerprint
        + Row.Root_Type_Fingerprint
        + Row.Type_Fingerprint
        + Row.Expected_Type_Context_Fingerprint
        + Row.Static_Fingerprint
        + Row.Overload_Fingerprint
        + Row.Profile_Fingerprint
        + Row.Substitution_Fingerprint
        + Row.Consumer_Fingerprint;

      Check_Audit_Gates (Row, Result);
      Check_Fingerprints (Row, Result);
      Check_Indeterminate_Evidence (Row, Result);
      Check_Predefined_Environment (Row, Result);
      Check_Literal_Resolution (Row, Result);
      Check_Consumers (Row, Result);

      if Result.Status = Status_Not_Checked then
         case Row.Expected is
            when Precision.Class_Legal =>
               Result.Status := Status_Legal_Gap_Burned_Down;
            when Precision.Class_Legal_With_Runtime_Check =>
               Result.Status := Status_Runtime_Check_Evidence_Lost;
            when Precision.Class_Illegal =>
               Result.Status := Status_Unexpected_Classification;
            when Precision.Class_Indeterminate =>
               Result.Status := Status_Indeterminate;
            when others =>
               Result.Status := Status_Unexpected_Classification;
         end case;
      end if;

      return Result;
   end Evaluate;

   procedure Add_Row (Input : in out Burn_Down_Input; Row : Burn_Down_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Row;

   function Build (Input : Burn_Down_Input) return Burn_Down_Model is
      Results : Burn_Down_Model;
      Item : Burn_Down_Entry;
      Classification : Precision_Classification;
   begin
      Results.Total_Rows := Natural (Input.Rows.Length);
      for Row of Input.Rows loop
         Item := Evaluate (Row);
         Results.Entries.Append (Item);
         Results.Audit_Fingerprint := Results.Audit_Fingerprint
           + Item.Result_Fingerprint
           + Natural (Burn_Down_Status'Pos (Item.Status))
           + Item.Blocker_Count;

         if Item.Consumer /= Consumers.Consumer_Unknown then
            Results.Consumer_Count := Results.Consumer_Count + 1;
         end if;

         Classification := Expected_For_Status (Item.Status);
         case Classification is
            when Precision.Class_Legal =>
               Results.Legal_Count := Results.Legal_Count + 1;
            when Precision.Class_Illegal =>
               Results.Illegal_Count := Results.Illegal_Count + 1;
            when Precision.Class_Legal_With_Runtime_Check =>
               Results.Runtime_Check_Count := Results.Runtime_Check_Count + 1;
            when Precision.Class_Indeterminate =>
               Results.Indeterminate_Count := Results.Indeterminate_Count + 1;
            when others =>
               Results.Blocked_Count := Results.Blocked_Count + 1;
         end case;
      end loop;
      return Results;
   end Build;

   function Count (Results : Burn_Down_Model) return Natural is
   begin
      return Natural (Results.Entries.Length);
   end Count;

   function Result_At (Results : Burn_Down_Model; Index : Positive)
     return Burn_Down_Entry is
   begin
      return Results.Entries.Element (Index - 1);
   end Result_At;

   function Result_For (Results : Burn_Down_Model; Id : Natural)
     return Burn_Down_Entry is
   begin
      for Item of Results.Entries loop
         if Item.Id = Id then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end Result_For;

   function Predefined_Environment_Literal_Resolution_Gap_Closed
     (Results : Burn_Down_Model) return Boolean is
      Saw_Target_Gap : Boolean := False;
   begin
      if Count (Results) = 0 then
         return False;
      end if;

      for Item of Results.Entries loop
         if Item.Gap = Gap_Predefined_Environment_Literal_Resolution then
            Saw_Target_Gap := True;
         end if;
         if not Is_Valid_Status (Item.Status) then
            return False;
         end if;
      end loop;

      return Saw_Target_Gap;
   end Predefined_Environment_Literal_Resolution_Gap_Closed;

end Editor.Ada_RM_Gap_Burn_Down_Pass1358;
