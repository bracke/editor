package body Editor.Ada_RM_Gap_Burn_Down_Pass1347 is

   pragma Suppress (Overflow_Check);
   use type Remediation.Remediation_State;
   use type Matrix.Coverage_Level;
   use type Precision.Precision_Classification;
   use type Consumers.Semantic_Consumer;


   procedure Add_Burn_Down_Row
     (Input : in out Burn_Down_Input;
      Row : Burn_Down_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Burn_Down_Row;

   function Count (Results : Burn_Down_Model) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Count;

   function Result_At (Results : Burn_Down_Model; Index : Positive) return Burn_Down_Entry is
   begin
      return Results.Items.Element (Index - 1);
   end Result_At;

   function Result_For (Results : Burn_Down_Model; Id : Natural) return Burn_Down_Entry is
   begin
      for R of Results.Items loop
         if R.Id = Id then
            return R;
         end if;
      end loop;

      return
        (Id => Id,
         Gap => Gap_Unknown,
         Family => Matrix.Family_Unknown,
         Owner => Matrix.Slice_Unknown,
         Previous_State => Remediation.State_Unknown,
         Promoted_State => Remediation.State_Unknown,
         Matrix_Level_After => Matrix.Coverage_Unknown,
         Consumer => Consumers.Consumer_Unknown,
         Classification => Precision.Class_Unknown,
         Status => Status_Not_Checked,
         Blocker_Count => 0,
         Entry_Fingerprint => 0);
   end Result_For;

   function RM_Gap_Burn_Down_Ready (Results : Burn_Down_Model) return Boolean is
   begin
      return Count (Results) > 0
        and then Results.Invalid_Count = 0
        and then Results.Burned_Down_Count = Count (Results)
        and then Results.Legal_Count > 0
        and then Results.Illegal_Count > 0
        and then Results.Runtime_Check_Count > 0
        and then Results.Indeterminate_Count > 0;
   end RM_Gap_Burn_Down_Ready;

   function Representation_Freezing_Interfacing_Gap_Closed
     (Results : Burn_Down_Model) return Boolean is
      Saw_Target_Gap : Boolean := False;
   begin
      if not RM_Gap_Burn_Down_Ready (Results) then
         return False;
      end if;

      for R of Results.Items loop
         if R.Gap = Gap_Representation_Freezing_Interfacing
           and then R.Promoted_State = Remediation.State_Covered
           and then R.Matrix_Level_After = Matrix.Coverage_Covered
         then
            Saw_Target_Gap := True;
         end if;
      end loop;

      return Saw_Target_Gap;
   end Representation_Freezing_Interfacing_Gap_Closed;

   function Is_Valid_Status (Status : Burn_Down_Status) return Boolean is
   begin
      return Status in Status_Gap_Burned_Down
                     | Status_Legal_Gap_Burned_Down
                     | Status_Illegal_Late_Representation_After_Freezing
                     | Status_Illegal_Late_Aspect_After_Freezing
                     | Status_Illegal_Missing_Representation_Target
                     | Status_Illegal_Wrong_Kind_Representation_Target
                     | Status_Illegal_Private_Full_View_Freezing_Disagreement
                     | Status_Illegal_Nonstatic_Component_Position
                     | Status_Illegal_Component_First_Last_Bit_Range
                     | Status_Illegal_Record_Component_Overlap
                     | Status_Illegal_Record_Size_Overflow
                     | Status_Illegal_Component_Size_Overflow
                     | Status_Illegal_Alignment_Conflict
                     | Status_Illegal_Storage_Order_Conflict
                     | Status_Illegal_Enum_Representation_Incomplete
                     | Status_Illegal_Enum_Extra_Literal
                     | Status_Illegal_Enum_Duplicate_Code
                     | Status_Illegal_Enum_Nonstatic_Value
                     | Status_Illegal_Enum_Negative_Value
                     | Status_Illegal_Enum_Nonmonotonic_Order
                     | Status_Illegal_Stream_Profile_Mismatch
                     | Status_Illegal_Stream_View_Barrier
                     | Status_Illegal_Stream_External_Representation_Conflict
                     | Status_Illegal_Convention_Profile_Mismatch
                     | Status_Illegal_C_Profile_Incompatible
                     | Status_Illegal_Import_Export_Target_Mismatch
                     | Status_Illegal_Import_Export_Conflict
                     | Status_Illegal_Duplicate_Interfacing_Item
                     | Status_Illegal_External_Name
                     | Status_Illegal_Link_Name
                     | Status_Illegal_Access_Subprogram_Convention_Mismatch
                     | Status_Illegal_Address_Storage_Conflict
                     | Status_Illegal_Aggregate_Layout_Evidence_Not_Consumed
                     | Status_Illegal_Assignment_Representation_Barrier_Lost
                     | Status_Illegal_Callable_Convention_Disagreement
                     | Status_Illegal_Dispatch_Convention_Evidence_Lost
                     | Status_Illegal_Generic_Replay_Stale_Representation
                     | Status_Runtime_Address_Alignment_Check_Preserved
                     | Status_Runtime_Stream_Tag_Check_Preserved
                     | Status_Indeterminate_Private_View
                     | Status_Indeterminate_Limited_View
                     | Status_Indeterminate_Incomplete_View
                     | Status_Indeterminate_Generic_Formal_View
                     | Status_Indeterminate_Generic_Template_Freezing_Barrier
                     | Status_Indeterminate_Missing_Full_View
                     | Status_Indeterminate_Missing_Cross_Unit_Evidence;
   end Is_Valid_Status;

   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification is
   begin
      case Status is
         when Status_Legal_Gap_Burned_Down | Status_Gap_Burned_Down =>
            return Precision.Class_Legal;
         when Status_Illegal_Late_Representation_After_Freezing
            | Status_Illegal_Late_Aspect_After_Freezing
            | Status_Illegal_Missing_Representation_Target
            | Status_Illegal_Wrong_Kind_Representation_Target
            | Status_Illegal_Private_Full_View_Freezing_Disagreement
            | Status_Illegal_Nonstatic_Component_Position
            | Status_Illegal_Component_First_Last_Bit_Range
            | Status_Illegal_Record_Component_Overlap
            | Status_Illegal_Record_Size_Overflow
            | Status_Illegal_Component_Size_Overflow
            | Status_Illegal_Alignment_Conflict
            | Status_Illegal_Storage_Order_Conflict
            | Status_Illegal_Enum_Representation_Incomplete
            | Status_Illegal_Enum_Extra_Literal
            | Status_Illegal_Enum_Duplicate_Code
            | Status_Illegal_Enum_Nonstatic_Value
            | Status_Illegal_Enum_Negative_Value
            | Status_Illegal_Enum_Nonmonotonic_Order
            | Status_Illegal_Stream_Profile_Mismatch
            | Status_Illegal_Stream_View_Barrier
            | Status_Illegal_Stream_External_Representation_Conflict
            | Status_Illegal_Convention_Profile_Mismatch
            | Status_Illegal_C_Profile_Incompatible
            | Status_Illegal_Import_Export_Target_Mismatch
            | Status_Illegal_Import_Export_Conflict
            | Status_Illegal_Duplicate_Interfacing_Item
            | Status_Illegal_External_Name
            | Status_Illegal_Link_Name
            | Status_Illegal_Access_Subprogram_Convention_Mismatch
            | Status_Illegal_Address_Storage_Conflict
            | Status_Illegal_Aggregate_Layout_Evidence_Not_Consumed
            | Status_Illegal_Assignment_Representation_Barrier_Lost
            | Status_Illegal_Callable_Convention_Disagreement
            | Status_Illegal_Dispatch_Convention_Evidence_Lost
            | Status_Illegal_Generic_Replay_Stale_Representation =>
            return Precision.Class_Illegal;
         when Status_Runtime_Address_Alignment_Check_Preserved
            | Status_Runtime_Stream_Tag_Check_Preserved
            | Status_Runtime_Check_Evidence_Lost =>
            return Precision.Class_Legal_With_Runtime_Check;
         when Status_Indeterminate_Private_View
            | Status_Indeterminate_Limited_View
            | Status_Indeterminate_Incomplete_View
            | Status_Indeterminate_Generic_Formal_View
            | Status_Indeterminate_Generic_Template_Freezing_Barrier
            | Status_Indeterminate_Missing_Full_View
            | Status_Indeterminate_Missing_Cross_Unit_Evidence
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
      if Result.Status = Status_Not_Checked
        or else Is_Valid_Status (Result.Status)
      then
         Result.Status := Status;
      elsif Result.Status /= Status then
         Result.Status := Status_Multiple_Blockers;
      end if;
   end Add_Blocker;

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
      if Row.Type_Fingerprint /= Row.Expected_Type_Fingerprint then
         Add_Blocker (Result, Status_Type_Fingerprint_Mismatch);
      end if;
      if Row.Profile_Fingerprint /= Row.Expected_Profile_Fingerprint then
         Add_Blocker (Result, Status_Profile_Fingerprint_Mismatch);
      end if;
      if Row.Substitution_Fingerprint /= Row.Expected_Substitution_Fingerprint then
         Add_Blocker (Result, Status_Substitution_Fingerprint_Mismatch);
      end if;
      if Row.Representation_Fingerprint /= Row.Expected_Representation_Fingerprint then
         Add_Blocker (Result, Status_Representation_Fingerprint_Mismatch);
      end if;
      if Row.Freezing_Fingerprint /= Row.Expected_Freezing_Fingerprint then
         Add_Blocker (Result, Status_Freezing_Fingerprint_Mismatch);
      end if;
      if Row.Effect_Fingerprint /= Row.Expected_Effect_Fingerprint then
         Add_Blocker (Result, Status_Effect_Fingerprint_Mismatch);
      end if;
      if Row.Consumer_Fingerprint /= Row.Expected_Consumer_Fingerprint then
         Add_Blocker (Result, Status_Consumer_Fingerprint_Mismatch);
      end if;
   end Check_Fingerprints;

   function Rule_Status (Row : Burn_Down_Row) return Burn_Down_Status is
   begin
      if Row.Private_View_Barrier then
         return Status_Indeterminate_Private_View;
      elsif Row.Limited_View_Barrier then
         return Status_Indeterminate_Limited_View;
      elsif Row.Incomplete_View_Barrier then
         return Status_Indeterminate_Incomplete_View;
      elsif Row.Generic_Formal_View_Barrier then
         return Status_Indeterminate_Generic_Formal_View;
      elsif Row.Generic_Formal_Freezing_Barrier
        or else Row.Generic_Template_Freezing_Barrier
      then
         return Status_Indeterminate_Generic_Template_Freezing_Barrier;
      elsif Row.Missing_Full_View then
         return Status_Indeterminate_Missing_Full_View;
      elsif Row.Missing_Cross_Unit_Evidence then
         return Status_Indeterminate_Missing_Cross_Unit_Evidence;
      elsif not Row.Representation_Target_Present then
         return Status_Illegal_Missing_Representation_Target;
      elsif not Row.Representation_Target_Kind_Compatible then
         return Status_Illegal_Wrong_Kind_Representation_Target;
      elsif not Row.Representation_Clause_Before_Freezing then
         return Status_Illegal_Late_Representation_After_Freezing;
      elsif not Row.Aspect_Before_Freezing then
         return Status_Illegal_Late_Aspect_After_Freezing;
      elsif not Row.Private_Full_View_Freezing_Agrees then
         return Status_Illegal_Private_Full_View_Freezing_Disagreement;
      elsif not Row.Record_Component_Positions_Static then
         return Status_Illegal_Nonstatic_Component_Position;
      elsif not Row.Component_First_Last_Bits_Valid then
         return Status_Illegal_Component_First_Last_Bit_Range;
      elsif not Row.Record_Components_Nonoverlapping then
         return Status_Illegal_Record_Component_Overlap;
      elsif not Row.Record_Size_Fits then
         return Status_Illegal_Record_Size_Overflow;
      elsif not Row.Component_Size_Fits then
         return Status_Illegal_Component_Size_Overflow;
      elsif not Row.Alignment_Compatible then
         return Status_Illegal_Alignment_Conflict;
      elsif not Row.Storage_Order_Compatible then
         return Status_Illegal_Storage_Order_Conflict;
      elsif not Row.Enum_Representation_Complete then
         return Status_Illegal_Enum_Representation_Incomplete;
      elsif not Row.Enum_No_Extra_Literals then
         return Status_Illegal_Enum_Extra_Literal;
      elsif not Row.Enum_No_Duplicate_Codes then
         return Status_Illegal_Enum_Duplicate_Code;
      elsif not Row.Enum_Values_Static then
         return Status_Illegal_Enum_Nonstatic_Value;
      elsif not Row.Enum_Values_Nonnegative then
         return Status_Illegal_Enum_Negative_Value;
      elsif not Row.Enum_Order_Monotonic then
         return Status_Illegal_Enum_Nonmonotonic_Order;
      elsif not Row.Stream_Profile_Compatible then
         return Status_Illegal_Stream_Profile_Mismatch;
      elsif not Row.Stream_View_Allowed then
         return Status_Illegal_Stream_View_Barrier;
      elsif not Row.No_Stream_External_Representation_Conflict then
         return Status_Illegal_Stream_External_Representation_Conflict;
      elsif not Row.Convention_Profile_Compatible then
         return Status_Illegal_Convention_Profile_Mismatch;
      elsif not Row.C_Profile_Compatible then
         return Status_Illegal_C_Profile_Incompatible;
      elsif not Row.Import_Export_Target_Compatible then
         return Status_Illegal_Import_Export_Target_Mismatch;
      elsif not Row.No_Import_Export_Conflict then
         return Status_Illegal_Import_Export_Conflict;
      elsif not Row.No_Duplicate_Interfacing_Items then
         return Status_Illegal_Duplicate_Interfacing_Item;
      elsif not Row.External_Name_Legal then
         return Status_Illegal_External_Name;
      elsif not Row.Link_Name_Legal then
         return Status_Illegal_Link_Name;
      elsif not Row.Access_Subprogram_Convention_Compatible then
         return Status_Illegal_Access_Subprogram_Convention_Mismatch;
      elsif not Row.Address_Storage_Compatible then
         return Status_Illegal_Address_Storage_Conflict;
      elsif not Row.Aggregate_Consumes_Layout_Evidence then
         return Status_Illegal_Aggregate_Layout_Evidence_Not_Consumed;
      elsif not Row.Assignment_Conversion_Consumes_Representation then
         return Status_Illegal_Assignment_Representation_Barrier_Lost;
      elsif not Row.Callable_Profile_Consumes_Convention then
         return Status_Illegal_Callable_Convention_Disagreement;
      elsif not Row.Dispatch_Consumes_Convention then
         return Status_Illegal_Dispatch_Convention_Evidence_Lost;
      elsif not Row.Generic_Replay_Uses_Fresh_Representation then
         return Status_Illegal_Generic_Replay_Stale_Representation;
      elsif Row.Runtime_Address_Alignment_Check then
         if Row.Runtime_Check_Evidence_Preserved then
            return Status_Runtime_Address_Alignment_Check_Preserved;
         else
            return Status_Runtime_Check_Evidence_Lost;
         end if;
      elsif Row.Runtime_Stream_Tag_Check then
         if Row.Runtime_Check_Evidence_Preserved then
            return Status_Runtime_Stream_Tag_Check_Preserved;
         else
            return Status_Runtime_Check_Evidence_Lost;
         end if;
      else
         return Status_Legal_Gap_Burned_Down;
      end if;
   end Rule_Status;

   procedure Check_Row
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
      Status : constant Burn_Down_Status := Rule_Status (Row);
      Classification : constant Precision_Classification := Expected_For_Status (Status);
   begin
      Result.Status := Status;
      Result.Classification := Classification;
      Result.Promoted_State := Row.Target_State;
      Result.Entry_Fingerprint :=
        1_347_000
        + Row.Id
        + Burn_Down_Gap'Pos (Row.Gap)
        + Matrix.RM_Family'Pos (Row.Family)
        + Matrix.Implementing_Slice'Pos (Row.Owner)
        + Remediation.Remediation_State'Pos (Row.Previous_State)
        + Remediation.Remediation_State'Pos (Row.Target_State)
        + Matrix.Coverage_Level'Pos (Row.Matrix_Level_Before)
        + Matrix.Coverage_Level'Pos (Row.Matrix_Level_After)
        + Representation_Item_Kind'Pos (Row.Item)
        + Representation_Context_Kind'Pos (Row.Context)
        + Precision.Precision_Classification'Pos (Row.Expected)
        + Row.Burn_Down_Fingerprint
        + Row.Source_Fingerprint
        + Row.AST_Fingerprint
        + Row.Type_Fingerprint
        + Row.Profile_Fingerprint
        + Row.Substitution_Fingerprint
        + Row.Representation_Fingerprint
        + Row.Freezing_Fingerprint
        + Row.Effect_Fingerprint
        + Row.Consumer_Fingerprint;

      if not Row.Source_Shaped_Evidence then
         Add_Blocker (Result, Status_Source_Shaped_Evidence_Missing);
      end if;
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
      if Row.Target_State /= Remediation.State_Covered
        or else Row.Matrix_Level_After /= Matrix.Coverage_Covered
        or else not Row.Coverage_Entry_Updated_To_Covered
      then
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
      if not Row.Consumer_Representation_Model_Agrees then
         Add_Blocker (Result, Status_Consumer_Representation_Model_Disagreement);
      end if;
      if not Row.Consumer_Freezing_Model_Agrees then
         Add_Blocker (Result, Status_Consumer_Freezing_Model_Disagreement);
      end if;
      if not Row.Consumer_Interfacing_Model_Agrees then
         Add_Blocker (Result, Status_Consumer_Interfacing_Model_Disagreement);
      end if;
      if not Row.Consumer_Diagnostic_Bridge_Agrees then
         Add_Blocker (Result, Status_Consumer_Diagnostic_Bridge_Disagreement);
      end if;
      if not Row.Stable_Blocker_Family
        and then Classification = Precision.Class_Illegal
      then
         Add_Blocker (Result, Status_Unstable_Blocker_Family);
      end if;
      if Status = Status_Runtime_Check_Evidence_Lost then
         Add_Blocker (Result, Status_Runtime_Check_Evidence_Lost);
      end if;
      if Row.Expected /= Precision.Class_Unknown
        and then Row.Expected /= Classification
      then
         Add_Blocker (Result, Status_Unexpected_Classification);
      end if;

      Check_Fingerprints (Row, Result);
   end Check_Row;

   procedure Count_Result
     (Results : in out Burn_Down_Model;
      Result : Burn_Down_Entry) is
   begin
      if Is_Valid_Status (Result.Status) then
         Results.Burned_Down_Count := Results.Burned_Down_Count + 1;
      else
         Results.Invalid_Count := Results.Invalid_Count + 1;
      end if;

      case Result.Classification is
         when Precision.Class_Legal =>
            Results.Legal_Count := Results.Legal_Count + 1;
         when Precision.Class_Illegal =>
            Results.Illegal_Count := Results.Illegal_Count + 1;
         when Precision.Class_Legal_With_Runtime_Check =>
            Results.Runtime_Check_Count := Results.Runtime_Check_Count + 1;
         when Precision.Class_Indeterminate =>
            Results.Indeterminate_Count := Results.Indeterminate_Count + 1;
         when others =>
            null;
      end case;

      Results.Audit_Fingerprint :=
        Results.Audit_Fingerprint
        + Result.Entry_Fingerprint
        + Burn_Down_Status'Pos (Result.Status)
        + Precision.Precision_Classification'Pos (Result.Classification)
        + Result.Blocker_Count;
   end Count_Result;

   function Build (Input : Burn_Down_Input) return Burn_Down_Model is
      Results : Burn_Down_Model;
   begin
      for Row of Input.Rows loop
         declare
            R : Burn_Down_Entry :=
              (Id => Row.Id,
               Gap => Row.Gap,
               Family => Row.Family,
               Owner => Row.Owner,
               Previous_State => Row.Previous_State,
               Promoted_State => Remediation.State_Unknown,
               Matrix_Level_After => Row.Matrix_Level_After,
               Consumer => Row.Consumer,
               Classification => Precision.Class_Unknown,
               Status => Status_Not_Checked,
               Blocker_Count => 0,
               Entry_Fingerprint => 0);
         begin
            Check_Row (Row, R);
            Results.Items.Append (R);
            Count_Result (Results, R);
         end;
      end loop;

      return Results;
   end Build;

end Editor.Ada_RM_Gap_Burn_Down_Pass1347;
