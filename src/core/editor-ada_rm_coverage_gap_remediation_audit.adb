with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_RM_Coverage_Gap_Remediation_Audit is

   pragma Suppress (Overflow_Check);
   use type Matrix.RM_Family;
   use type Matrix.Coverage_Level;
   use type Matrix.Implementing_Slice;


   procedure Add_Remediation_Item
     (Input : in out Remediation_Input;
      Item : Remediation_Item) is
   begin
      Input.Items.Append (Item);
   end Add_Remediation_Item;

   function Count (Results : Remediation_Model) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Count;

   function Result_At (Results : Remediation_Model; Index : Positive) return Remediation_Entry is
   begin
      return Results.Items.Element (Index - 1);
   end Result_At;

   function Result_For (Results : Remediation_Model; Family : RM_Family) return Remediation_Entry is
   begin
      for R of Results.Items loop
         if R.Family = Family then
            return R;
         end if;
      end loop;

      return
        (Family => Family,
         Owner => Matrix.Slice_Unknown,
         State => State_Unknown,
         Status => Status_Not_Checked,
         Matrix_Level => Matrix.Coverage_Unknown,
         Missing_Subrule_Count => 0,
         Blocker_Count => 0,
         Actionable_Gap => False,
         Entry_Fingerprint => 0);
   end Result_For;

   function Coverage_Gap_Remediation_Audit_Valid (Results : Remediation_Model) return Boolean is
   begin
      return Results.Total_Families > 0
        and then Results.Invalid_Count = 0
        and then Count (Results) >= Results.Total_Families;
   end Coverage_Gap_Remediation_Audit_Valid;

   function RM_Gaps_Remediated (Results : Remediation_Model) return Boolean is
   begin
      return Coverage_Gap_Remediation_Audit_Valid (Results)
        and then Results.Covered_Count = Results.Total_Families
        and then Results.Partial_Count = 0
        and then Results.Blocked_Count = 0
        and then Results.Missing_Count = 0
        and then Results.Actionable_Gap_Count = 0;
   end RM_Gaps_Remediated;

   function Actionable_Gaps_Present (Results : Remediation_Model) return Boolean is
   begin
      return Results.Actionable_Gap_Count > 0;
   end Actionable_Gaps_Present;

   function Real_Family_Count return Natural is
      Total : Natural := 0;
   begin
      for F in Matrix.RM_Family loop
         if F /= Matrix.Family_Unknown then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Real_Family_Count;

   function Item_Count_For_Family
     (Input : Remediation_Input;
      Family : RM_Family) return Natural is
      Total : Natural := 0;
   begin
      for I of Input.Items loop
         if I.Family = Family then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Item_Count_For_Family;

   function Package_Named (Item : Remediation_Item) return Boolean is
   begin
      return Length (Item.Implementing_Package) > 0;
   end Package_Named;

   function Base_Status (State : Remediation_State) return Remediation_Status is
   begin
      case State is
         when State_Covered =>
            return Status_Covered;
         when State_Partial =>
            return Status_Partial_Actionable;
         when State_Blocked =>
            return Status_Blocked_Actionable;
         when State_Missing =>
            return Status_Missing_Actionable;
         when State_Unknown =>
            return Status_Indeterminate;
      end case;
   end Base_Status;

   function Matrix_Level_Matches (Item : Remediation_Item) return Boolean is
   begin
      case Item.State is
         when State_Covered =>
            return Item.Matrix_Level = Matrix.Coverage_Covered;
         when State_Partial =>
            return Item.Matrix_Level = Matrix.Coverage_Partial;
         when State_Blocked =>
            return Item.Matrix_Level = Matrix.Coverage_Blocked;
         when State_Missing =>
            return Item.Matrix_Level in Matrix.Coverage_None | Matrix.Coverage_Unknown;
         when State_Unknown =>
            return False;
      end case;
   end Matrix_Level_Matches;

   function Status_Is_Valid (Status : Remediation_Status) return Boolean is
   begin
      return Status in Status_Covered
        | Status_Partial_Actionable
        | Status_Blocked_Actionable
        | Status_Missing_Actionable;
   end Status_Is_Valid;

   procedure Add_Blocker
     (Result : in out Remediation_Entry;
      Status : Remediation_Status;
      Owner : Implementing_Slice) is
   begin
      Result.Blocker_Count := Result.Blocker_Count + 1;
      if Result.Status in Status_Not_Checked
        | Status_Covered
        | Status_Partial_Actionable
        | Status_Blocked_Actionable
        | Status_Missing_Actionable
      then
         Result.Status := Status;
         if Result.Owner = Matrix.Slice_Unknown then
            Result.Owner := Owner;
         end if;
      elsif Result.Status /= Status then
         Result.Status := Status_Multiple_Blockers;
         if Result.Owner = Matrix.Slice_Unknown then
            Result.Owner := Owner;
         end if;
      end if;
   end Add_Blocker;

   procedure Check_Fingerprints
     (Item : Remediation_Item;
      Result : in out Remediation_Entry) is
   begin
      if Item.Remediation_Fingerprint /= Item.Expected_Remediation_Fingerprint then
         Add_Blocker (Result, Status_Stale_Remediation_Fingerprint, Item.Owner);
      end if;
      if Item.Source_Fingerprint /= Item.Expected_Source_Fingerprint then
         Add_Blocker (Result, Status_Source_Fingerprint_Mismatch, Item.Owner);
      end if;
      if Item.AST_Fingerprint /= Item.Expected_AST_Fingerprint then
         Add_Blocker (Result, Status_AST_Fingerprint_Mismatch, Item.Owner);
      end if;
      if Item.Type_Fingerprint /= Item.Expected_Type_Fingerprint then
         Add_Blocker (Result, Status_Type_Fingerprint_Mismatch, Item.Owner);
      end if;
      if Item.Profile_Fingerprint /= Item.Expected_Profile_Fingerprint then
         Add_Blocker (Result, Status_Profile_Fingerprint_Mismatch, Item.Owner);
      end if;
      if Item.Substitution_Fingerprint /= Item.Expected_Substitution_Fingerprint then
         Add_Blocker (Result, Status_Substitution_Fingerprint_Mismatch, Item.Owner);
      end if;
      if Item.Effect_Fingerprint /= Item.Expected_Effect_Fingerprint then
         Add_Blocker (Result, Status_Effect_Fingerprint_Mismatch, Item.Owner);
      end if;
   end Check_Fingerprints;

   procedure Check_Item
     (Input : Remediation_Input;
      Item : Remediation_Item;
      Result : in out Remediation_Entry) is
   begin
      Result.Entry_Fingerprint :=
        Result.Entry_Fingerprint
        + Item.Id
        + Matrix.RM_Family'Pos (Item.Family)
        + Matrix.Implementing_Slice'Pos (Item.Owner)
        + Remediation_State'Pos (Item.State)
        + Matrix.Coverage_Level'Pos (Item.Matrix_Level)
        + Item.Remediation_Fingerprint
        + Item.Source_Fingerprint
        + Item.AST_Fingerprint
        + Item.Type_Fingerprint
        + Item.Profile_Fingerprint
        + Item.Substitution_Fingerprint
        + Item.Effect_Fingerprint;

      if not Item.Matrix_Entry_Present then
         Add_Blocker (Result, Status_Missing_Matrix_Coverage, Item.Owner);
      end if;

      if not Matrix_Level_Matches (Item) then
         Add_Blocker (Result, Status_State_Matrix_Mismatch, Item.Owner);
      end if;

      if Item.Owner = Matrix.Slice_Unknown or else not Package_Named (Item) then
         Add_Blocker (Result, Status_Missing_Implementing_Package, Item.Owner);
      end if;

      if Item.Duplicate_Ownership or else Item_Count_For_Family (Input, Item.Family) > 1 then
         Add_Blocker (Result, Status_Duplicate_Remediation_Owner, Item.Owner);
      end if;

      if not Item.Source_Shaped_Evidence then
         Add_Blocker (Result, Status_Missing_Source_Shaped_Evidence, Item.Owner);
      end if;

      if Item.State in State_Covered | State_Partial
        and then not Item.Semantic_Result_Consumed
      then
         Add_Blocker (Result, Status_Unconsumed_Semantic_Result, Item.Owner);
      end if;

      if Item.State = State_Covered and then not Item.End_To_End_Consumed then
         Add_Blocker (Result, Status_Unconsumed_End_To_End_Result, Item.Owner);
      end if;

      if Item.State = State_Partial and then not Item.Missing_Subrules_Named then
         Add_Blocker (Result, Status_Vague_Partial, Item.Owner);
      end if;

      if Item.State in State_Partial | State_Blocked | State_Missing
        and then (Item.Missing_Subrule_Count = 0
                  or else not Item.Concrete_Blocker_Family)
      then
         Add_Blocker (Result, Status_Missing_Subrule_Evidence, Item.Owner);
      end if;

      if Item.State = State_Blocked and then Item.Required_Evidence_Absent = Evidence_None then
         Add_Blocker (Result, Status_Missing_Subrule_Evidence, Item.Owner);
      end if;

      if Item.State in State_Partial | State_Blocked
        and then not Item.Blocker_Source_Traceable
      then
         Add_Blocker (Result, Status_Untraceable_Blocker, Item.Owner);
      end if;

      Check_Fingerprints (Item, Result);
   end Check_Item;

   procedure Count_Result
     (Results : in out Remediation_Model;
      Result : Remediation_Entry) is
   begin
      case Result.Status is
         when Status_Covered =>
            Results.Covered_Count := Results.Covered_Count + 1;
         when Status_Partial_Actionable =>
            Results.Partial_Count := Results.Partial_Count + 1;
            Results.Actionable_Gap_Count := Results.Actionable_Gap_Count + 1;
         when Status_Blocked_Actionable =>
            Results.Blocked_Count := Results.Blocked_Count + 1;
            Results.Actionable_Gap_Count := Results.Actionable_Gap_Count + 1;
         when Status_Missing_Actionable =>
            Results.Missing_Count := Results.Missing_Count + 1;
            Results.Actionable_Gap_Count := Results.Actionable_Gap_Count + 1;
         when others =>
            Results.Invalid_Count := Results.Invalid_Count + 1;
      end case;

      if not Status_Is_Valid (Result.Status) then
         null;
      end if;

      Results.Audit_Fingerprint :=
        Results.Audit_Fingerprint
        + Result.Entry_Fingerprint
        + Result.Blocker_Count
        + Remediation_Status'Pos (Result.Status);
   end Count_Result;

   function Missing_Family_Entry (Family : RM_Family) return Remediation_Entry is
   begin
      return
        (Family => Family,
         Owner => Matrix.Slice_Unknown,
         State => State_Unknown,
         Status => Status_Missing_Remediation_Entry,
         Matrix_Level => Matrix.Coverage_Unknown,
         Missing_Subrule_Count => 0,
         Blocker_Count => 1,
         Actionable_Gap => False,
         Entry_Fingerprint =>
           1_339_900 + Matrix.RM_Family'Pos (Family));
   end Missing_Family_Entry;

   function Build (Input : Remediation_Input) return Remediation_Model is
      Results : Remediation_Model;
   begin
      Results.Total_Families := Real_Family_Count;

      for Item of Input.Items loop
         declare
            R : Remediation_Entry :=
              (Family => Item.Family,
               Owner => Item.Owner,
               State => Item.State,
               Status => Base_Status (Item.State),
               Matrix_Level => Item.Matrix_Level,
               Missing_Subrule_Count => Item.Missing_Subrule_Count,
               Blocker_Count => 0,
               Actionable_Gap => (Item.State in State_Partial | State_Blocked | State_Missing),
               Entry_Fingerprint => 1_339_000 + Item.Id);
         begin
            Check_Item (Input, Item, R);
            if R.Status not in Status_Partial_Actionable | Status_Blocked_Actionable | Status_Missing_Actionable then
               R.Actionable_Gap := False;
            end if;
            Count_Result (Results, R);
            Results.Items.Append (R);
         end;
      end loop;

      for F in Matrix.RM_Family loop
         if F /= Matrix.Family_Unknown and then Item_Count_For_Family (Input, F) = 0 then
            declare
               R : constant Remediation_Entry := Missing_Family_Entry (F);
            begin
               Count_Result (Results, R);
               Results.Items.Append (R);
            end;
         end if;
      end loop;

      return Results;
   end Build;

end Editor.Ada_RM_Coverage_Gap_Remediation_Audit;
