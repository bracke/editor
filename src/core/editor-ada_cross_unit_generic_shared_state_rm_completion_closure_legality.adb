with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Cross_Unit_Generic_Shared_State_RM_Completion_Closure_Legality is

   pragma Suppress (Overflow_Check);

   use type AST_Repair.Coverage_Proven_AST_Repair_Id;
   use type AST_Repair.Coverage_Proven_AST_Repair_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Overload_RM.Overload_Generic_RM_Edge_Completion_Id;
   use type Prior_Cross.Cross_Unit_Generic_Final_Row_Id;
   use type Representation_RM.Representation_Generic_RM_Hard_Case_Id;
   use type Stabilized.Generic_Shared_State_Final_Stabilized_Closure_Id;
   use type Stabilized.Generic_Shared_State_Final_Stabilized_Closure_Status;
   use type Tasking_RM.Tasking_Generic_RM_Hard_Case_Id;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 16777619 + Right + 19) mod 2_147_483_647;
   end Mix;

   function Is_Accepted (Status : Cross_Unit_RM_Completion_Status) return Boolean is
   begin
      return Status in Cross_Unit_RM_Completion_Legal_Local_Accepted .. Cross_Unit_RM_Completion_Legal_AST_Repair_Accepted;
   end Is_Accepted;

   function Is_Indeterminate (Status : Cross_Unit_RM_Completion_Status) return Boolean is
   begin
      return Status = Cross_Unit_RM_Completion_Indeterminate;
   end Is_Indeterminate;

   function Is_Blocked (Status : Cross_Unit_RM_Completion_Status) return Boolean is
   begin
      return not Is_Accepted (Status)
        and then Status /= Cross_Unit_RM_Completion_Not_Checked
        and then not Is_Indeterminate (Status);
   end Is_Blocked;

   function AST_Repair_Accepted
     (Status : AST_Repair.Coverage_Proven_AST_Repair_Status) return Boolean is
   begin
      return AST_Repair.Is_Repaired (Status)
        or else Status = AST_Repair.Coverage_Proven_AST_Repair_Not_Required;
   end AST_Repair_Accepted;

   function Accepted_For (Kind : Cross_Unit_RM_Completion_Kind) return Cross_Unit_RM_Completion_Status is
   begin
      case Kind is
         when Cross_Unit_RM_Completion_Local => return Cross_Unit_RM_Completion_Legal_Local_Accepted;
         when Cross_Unit_RM_Completion_Spec_Body => return Cross_Unit_RM_Completion_Legal_Spec_Body_Accepted;
         when Cross_Unit_RM_Completion_With_Use => return Cross_Unit_RM_Completion_Legal_With_Use_Accepted;
         when Cross_Unit_RM_Completion_Parent_Child => return Cross_Unit_RM_Completion_Legal_Parent_Child_Accepted;
         when Cross_Unit_RM_Completion_Private_Child => return Cross_Unit_RM_Completion_Legal_Private_Child_Accepted;
         when Cross_Unit_RM_Completion_Separate_Body => return Cross_Unit_RM_Completion_Legal_Separate_Body_Accepted;
         when Cross_Unit_RM_Completion_Generic_Instance => return Cross_Unit_RM_Completion_Legal_Generic_Instance_Accepted;
         when Cross_Unit_RM_Completion_Generic_Body => return Cross_Unit_RM_Completion_Legal_Generic_Body_Accepted;
         when Cross_Unit_RM_Completion_Abstract_State => return Cross_Unit_RM_Completion_Legal_Abstract_State_Accepted;
         when Cross_Unit_RM_Completion_Volatile_Atomic => return Cross_Unit_RM_Completion_Legal_Volatile_Atomic_Accepted;
         when Cross_Unit_RM_Completion_Overload_Type => return Cross_Unit_RM_Completion_Legal_Overload_Type_Accepted;
         when Cross_Unit_RM_Completion_Representation => return Cross_Unit_RM_Completion_Legal_Representation_Accepted;
         when Cross_Unit_RM_Completion_Tasking_Protected => return Cross_Unit_RM_Completion_Legal_Tasking_Protected_Accepted;
         when Cross_Unit_RM_Completion_AST_Repair => return Cross_Unit_RM_Completion_Legal_AST_Repair_Accepted;
         when Cross_Unit_RM_Completion_Unknown => return Cross_Unit_RM_Completion_Indeterminate;
      end case;
   end Accepted_For;

   function Dependency_Status (D : Cross_Unit_RM_Dependency_State) return Cross_Unit_RM_Completion_Status is
   begin
      case D is
         when RM_Dependency_Missing => return Cross_Unit_RM_Completion_Missing_Dependency;
         when RM_Dependency_Ambiguous => return Cross_Unit_RM_Completion_Ambiguous_Dependency;
         when RM_Dependency_Overflow => return Cross_Unit_RM_Completion_Dependency_Overflow;
         when RM_Dependency_Stale => return Cross_Unit_RM_Completion_Stale_Dependency;
         when RM_Dependency_Unknown => return Cross_Unit_RM_Completion_Indeterminate;
         when others => return Cross_Unit_RM_Completion_Not_Checked;
      end case;
   end Dependency_Status;

   function Family_For
     (Status : Cross_Unit_RM_Completion_Status) return Cross_Unit_RM_Completion_Blocker_Family is
   begin
      case Status is
         when Cross_Unit_RM_Completion_Missing_Prior_Cross_Row |
              Cross_Unit_RM_Completion_Prior_Cross_Blocker =>
            return Cross_Unit_RM_Completion_Blocker_Prior_Cross_Unit_Generic_Shared_State;
         when Cross_Unit_RM_Completion_Missing_Stabilized_Row |
              Cross_Unit_RM_Completion_Stabilized_Blocker =>
            return Cross_Unit_RM_Completion_Blocker_Stabilized_Generic_Shared_State;
         when Cross_Unit_RM_Completion_Missing_Overload_RM_Row |
              Cross_Unit_RM_Completion_Overload_RM_Blocker =>
            return Cross_Unit_RM_Completion_Blocker_Overload_RM_Completion;
         when Cross_Unit_RM_Completion_Missing_Representation_RM_Row |
              Cross_Unit_RM_Completion_Representation_RM_Blocker =>
            return Cross_Unit_RM_Completion_Blocker_Representation_RM_Completion;
         when Cross_Unit_RM_Completion_Missing_Tasking_RM_Row |
              Cross_Unit_RM_Completion_Tasking_RM_Blocker =>
            return Cross_Unit_RM_Completion_Blocker_Tasking_RM_Completion;
         when Cross_Unit_RM_Completion_Missing_AST_Repair_Row |
              Cross_Unit_RM_Completion_AST_Repair_Blocker =>
            return Cross_Unit_RM_Completion_Blocker_AST_Repair;
         when Cross_Unit_RM_Completion_Missing_Dependency |
              Cross_Unit_RM_Completion_Ambiguous_Dependency |
              Cross_Unit_RM_Completion_Dependency_Overflow |
              Cross_Unit_RM_Completion_Stale_Dependency =>
            return Cross_Unit_RM_Completion_Blocker_Dependency;
         when Cross_Unit_RM_Completion_Limited_View_Barrier |
              Cross_Unit_RM_Completion_Private_View_Barrier =>
            return Cross_Unit_RM_Completion_Blocker_View_Barrier;
         when Cross_Unit_RM_Completion_Private_Child_Visibility_Blocker =>
            return Cross_Unit_RM_Completion_Blocker_Private_Child;
         when Cross_Unit_RM_Completion_Separate_Body_Blocker =>
            return Cross_Unit_RM_Completion_Blocker_Separate_Body;
         when Cross_Unit_RM_Completion_Generic_Body_Unavailable =>
            return Cross_Unit_RM_Completion_Blocker_Generic_Body;
         when Cross_Unit_RM_Completion_Generic_Backmapping_Blocker =>
            return Cross_Unit_RM_Completion_Blocker_Generic_Backmapping;
         when Cross_Unit_RM_Completion_State_Visibility_Blocker =>
            return Cross_Unit_RM_Completion_Blocker_State_Visibility;
         when Cross_Unit_RM_Completion_Source_Fingerprint_Mismatch =>
            return Cross_Unit_RM_Completion_Blocker_Source_Fingerprint;
         when Cross_Unit_RM_Completion_Substitution_Fingerprint_Mismatch =>
            return Cross_Unit_RM_Completion_Blocker_Substitution_Fingerprint;
         when Cross_Unit_RM_Completion_Multiple_Blockers =>
            return Cross_Unit_RM_Completion_Blocker_Multiple;
         when Cross_Unit_RM_Completion_Indeterminate =>
            return Cross_Unit_RM_Completion_Blocker_Indeterminate;
         when others =>
            return Cross_Unit_RM_Completion_Blocker_None;
      end case;
   end Family_For;

   function Local_Blocker_Count (C : Cross_Unit_RM_Completion_Context) return Natural is
      Count : Natural := 0;
   begin
      if Dependency_Status (C.Dependency) /= Cross_Unit_RM_Completion_Not_Checked then Count := Count + 1; end if;
      if C.Limited_View_Barrier then Count := Count + 1; end if;
      if C.Private_View_Barrier then Count := Count + 1; end if;
      if C.Private_Child_Visibility_Blocker then Count := Count + 1; end if;
      if C.Separate_Body_Blocker then Count := Count + 1; end if;
      if C.Generic_Body_Unavailable then Count := Count + 1; end if;
      if C.Generic_Backmapping_Blocker then Count := Count + 1; end if;
      if C.State_Visibility_Blocker then Count := Count + 1; end if;
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then Count := Count + 1; end if;
      if C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then Count := Count + 1; end if;
      if C.Requires_Prior_Cross and then C.Prior_Cross_Row = Prior_Cross.No_Cross_Unit_Generic_Final_Row then Count := Count + 1; end if;
      if C.Requires_Prior_Cross and then C.Prior_Cross_Row /= Prior_Cross.No_Cross_Unit_Generic_Final_Row and then not Prior_Cross.Is_Accepted (C.Prior_Cross_Status) then Count := Count + 1; end if;
      if C.Requires_Stabilized and then C.Stabilized_Row = Stabilized.No_Generic_Shared_State_Final_Stabilized_Closure then Count := Count + 1; end if;
      if C.Requires_Stabilized and then C.Stabilized_Row /= Stabilized.No_Generic_Shared_State_Final_Stabilized_Closure and then not Stabilized.Is_Accepted (C.Stabilized_Status) then Count := Count + 1; end if;
      if C.Requires_Overload_RM and then C.Overload_RM_Row = Overload_RM.No_Overload_Generic_RM_Edge_Completion then Count := Count + 1; end if;
      if C.Requires_Overload_RM and then C.Overload_RM_Row /= Overload_RM.No_Overload_Generic_RM_Edge_Completion and then not Overload_RM.Is_Accepted (C.Overload_RM_Status) then Count := Count + 1; end if;
      if C.Requires_Representation_RM and then C.Representation_RM_Row = Representation_RM.No_Representation_Generic_RM_Hard_Case then Count := Count + 1; end if;
      if C.Requires_Representation_RM and then C.Representation_RM_Row /= Representation_RM.No_Representation_Generic_RM_Hard_Case and then not Representation_RM.Is_Accepted (C.Representation_RM_Status) then Count := Count + 1; end if;
      if C.Requires_Tasking_RM and then C.Tasking_RM_Row = Tasking_RM.No_Tasking_Generic_RM_Hard_Case then Count := Count + 1; end if;
      if C.Requires_Tasking_RM and then C.Tasking_RM_Row /= Tasking_RM.No_Tasking_Generic_RM_Hard_Case and then not Tasking_RM.Is_Accepted (C.Tasking_RM_Status) then Count := Count + 1; end if;
      if C.Requires_AST_Repair and then C.AST_Repair_Row = AST_Repair.No_Coverage_Proven_AST_Repair then Count := Count + 1; end if;
      if C.Requires_AST_Repair and then C.AST_Repair_Row /= AST_Repair.No_Coverage_Proven_AST_Repair and then not AST_Repair_Accepted (C.AST_Repair_Status) then Count := Count + 1; end if;
      return Count;
   end Local_Blocker_Count;

   function Classify (C : Cross_Unit_RM_Completion_Context) return Cross_Unit_RM_Completion_Status is
      Dep_Status : constant Cross_Unit_RM_Completion_Status := Dependency_Status (C.Dependency);
   begin
      if Local_Blocker_Count (C) > 1 then
         return Cross_Unit_RM_Completion_Multiple_Blockers;
      elsif Dep_Status /= Cross_Unit_RM_Completion_Not_Checked then
         return Dep_Status;
      elsif C.Limited_View_Barrier then
         return Cross_Unit_RM_Completion_Limited_View_Barrier;
      elsif C.Private_View_Barrier then
         return Cross_Unit_RM_Completion_Private_View_Barrier;
      elsif C.Private_Child_Visibility_Blocker then
         return Cross_Unit_RM_Completion_Private_Child_Visibility_Blocker;
      elsif C.Separate_Body_Blocker then
         return Cross_Unit_RM_Completion_Separate_Body_Blocker;
      elsif C.Generic_Body_Unavailable then
         return Cross_Unit_RM_Completion_Generic_Body_Unavailable;
      elsif C.Generic_Backmapping_Blocker then
         return Cross_Unit_RM_Completion_Generic_Backmapping_Blocker;
      elsif C.State_Visibility_Blocker then
         return Cross_Unit_RM_Completion_State_Visibility_Blocker;
      elsif C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         return Cross_Unit_RM_Completion_Source_Fingerprint_Mismatch;
      elsif C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then
         return Cross_Unit_RM_Completion_Substitution_Fingerprint_Mismatch;
      elsif C.Requires_Prior_Cross and then C.Prior_Cross_Row = Prior_Cross.No_Cross_Unit_Generic_Final_Row then
         return Cross_Unit_RM_Completion_Missing_Prior_Cross_Row;
      elsif C.Requires_Prior_Cross and then not Prior_Cross.Is_Accepted (C.Prior_Cross_Status) then
         return Cross_Unit_RM_Completion_Prior_Cross_Blocker;
      elsif C.Requires_Stabilized and then C.Stabilized_Row = Stabilized.No_Generic_Shared_State_Final_Stabilized_Closure then
         return Cross_Unit_RM_Completion_Missing_Stabilized_Row;
      elsif C.Requires_Stabilized and then not Stabilized.Is_Accepted (C.Stabilized_Status) then
         return Cross_Unit_RM_Completion_Stabilized_Blocker;
      elsif C.Requires_Overload_RM and then C.Overload_RM_Row = Overload_RM.No_Overload_Generic_RM_Edge_Completion then
         return Cross_Unit_RM_Completion_Missing_Overload_RM_Row;
      elsif C.Requires_Overload_RM and then not Overload_RM.Is_Accepted (C.Overload_RM_Status) then
         return Cross_Unit_RM_Completion_Overload_RM_Blocker;
      elsif C.Requires_Representation_RM and then C.Representation_RM_Row = Representation_RM.No_Representation_Generic_RM_Hard_Case then
         return Cross_Unit_RM_Completion_Missing_Representation_RM_Row;
      elsif C.Requires_Representation_RM and then not Representation_RM.Is_Accepted (C.Representation_RM_Status) then
         return Cross_Unit_RM_Completion_Representation_RM_Blocker;
      elsif C.Requires_Tasking_RM and then C.Tasking_RM_Row = Tasking_RM.No_Tasking_Generic_RM_Hard_Case then
         return Cross_Unit_RM_Completion_Missing_Tasking_RM_Row;
      elsif C.Requires_Tasking_RM and then not Tasking_RM.Is_Accepted (C.Tasking_RM_Status) then
         return Cross_Unit_RM_Completion_Tasking_RM_Blocker;
      elsif C.Requires_AST_Repair and then C.AST_Repair_Row = AST_Repair.No_Coverage_Proven_AST_Repair then
         return Cross_Unit_RM_Completion_Missing_AST_Repair_Row;
      elsif C.Requires_AST_Repair and then not AST_Repair_Accepted (C.AST_Repair_Status) then
         return Cross_Unit_RM_Completion_AST_Repair_Blocker;
      else
         return Accepted_For (C.Kind);
      end if;
   end Classify;

   function Message_For
     (Status : Cross_Unit_RM_Completion_Status;
      Kind   : Cross_Unit_RM_Completion_Kind;
      Family : Cross_Unit_RM_Completion_Blocker_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("cross-unit generic/shared-state RM completion closure legality " &
         Cross_Unit_RM_Completion_Status'Image (Status) &
         " kind=" & Cross_Unit_RM_Completion_Kind'Image (Kind) &
         " blocker=" & Cross_Unit_RM_Completion_Blocker_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint (Row : Cross_Unit_RM_Completion_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H    : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Context));
      H := Mix (H, Cross_Unit_RM_Completion_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Cross_Unit_RM_Dependency_State'Pos (Row.Dependency) + 1);
      H := Mix (H, Cross_Unit_RM_Completion_Status'Pos (Row.Status) + 1);
      H := Mix (H, Cross_Unit_RM_Completion_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Blocker_Count);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row (C : Cross_Unit_RM_Completion_Context; Index : Positive) return Cross_Unit_RM_Completion_Row is
      Status : constant Cross_Unit_RM_Completion_Status := Classify (C);
      Family : constant Cross_Unit_RM_Completion_Blocker_Family := Family_For (Status);
      Row    : Cross_Unit_RM_Completion_Row;
   begin
      Row.Id := Cross_Unit_RM_Completion_Closure_Id (Index);
      Row.Context := C.Id;
      Row.Kind := C.Kind;
      Row.Dependency := C.Dependency;
      Row.Status := Status;
      Row.Blocker_Family := Family;
      Row.Node := C.Node;
      Row.Unit_Name := C.Unit_Name;
      Row.Dependency_Name := C.Dependency_Name;
      Row.Generic_Unit_Name := C.Generic_Unit_Name;
      Row.Instance_Name := C.Instance_Name;
      Row.State_Name := C.State_Name;
      Row.Accepted := Is_Accepted (Status);
      Row.Blocked := Is_Blocked (Status);
      Row.Blocks_Downstream := Row.Blocked or else Is_Indeterminate (Status);
      Row.Blocker_Count := Local_Blocker_Count (C);
      if Row.Blocked and then Row.Blocker_Count = 0 then
         Row.Blocker_Count := 1;
      end if;
      Row.Source_Fingerprint := C.Source_Fingerprint;
      Row.Substitution_Fingerprint := C.Substitution_Fingerprint;
      Row.Start_Line := C.Start_Line;
      Row.Start_Column := C.Start_Column;
      Row.End_Line := C.End_Line;
      Row.End_Column := C.End_Column;
      Row.Message := Message_For (Status, C.Kind, Family);
      Row.Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Make_Row;

   procedure Clear (Model : in out Cross_Unit_RM_Completion_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context (Model : in out Cross_Unit_RM_Completion_Context_Model; Info : Cross_Unit_RM_Completion_Context) is
      Local : Natural := Natural (Info.Id);
   begin
      Model.Items.Append (Info);
      Local := Mix (Local, Cross_Unit_RM_Completion_Kind'Pos (Info.Kind) + 1);
      Local := Mix (Local, Cross_Unit_RM_Dependency_State'Pos (Info.Dependency) + 1);
      Local := Mix (Local, Natural (Info.Node));
      Local := Mix (Local, Info.Source_Fingerprint);
      Local := Mix (Local, Info.Substitution_Fingerprint);
      Model.Fingerprint := Mix (Model.Fingerprint, Local);
   end Add_Context;

   function Context_Count (Model : Cross_Unit_RM_Completion_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At (Model : Cross_Unit_RM_Completion_Context_Model; Index : Positive) return Cross_Unit_RM_Completion_Context is
   begin
      return Model.Items.Element (Index);
   end Context_At;

   function Context_Fingerprint (Model : Cross_Unit_RM_Completion_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Context_Fingerprint;

   function Build (Contexts : Cross_Unit_RM_Completion_Context_Model) return Cross_Unit_RM_Completion_Model is
      Result : Cross_Unit_RM_Completion_Model;
      Index  : Positive := 1;
   begin
      for C of Contexts.Items loop
         declare
            Row : constant Cross_Unit_RM_Completion_Row := Make_Row (C, Index);
         begin
            Result.Rows.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
         end;
         Index := Index + 1;
      end loop;
      return Result;
   end Build;

   function Count (Model : Cross_Unit_RM_Completion_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At (Model : Cross_Unit_RM_Completion_Model; Index : Positive) return Cross_Unit_RM_Completion_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Cross_Unit_RM_Completion_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At (Set : Cross_Unit_RM_Completion_Set; Index : Positive) return Cross_Unit_RM_Completion_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   function Query_Status (Model : Cross_Unit_RM_Completion_Model; Status : Cross_Unit_RM_Completion_Status) return Cross_Unit_RM_Completion_Set is
      Result : Cross_Unit_RM_Completion_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Query_Status;

   function Query_Blocker_Family (Model : Cross_Unit_RM_Completion_Model; Family : Cross_Unit_RM_Completion_Blocker_Family) return Cross_Unit_RM_Completion_Set is
      Result : Cross_Unit_RM_Completion_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Family then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Query_Blocker_Family;

   function Find_By_Node (Model : Cross_Unit_RM_Completion_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Cross_Unit_RM_Completion_Set is
      Result : Cross_Unit_RM_Completion_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Find_By_Node;

   function Find_By_Source_Fingerprint (Model : Cross_Unit_RM_Completion_Model; Source_Fingerprint : Natural) return Cross_Unit_RM_Completion_Set is
      Result : Cross_Unit_RM_Completion_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Source_Fingerprint then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Find_By_Source_Fingerprint;

   function Count_By_Status (Model : Cross_Unit_RM_Completion_Model; Status : Cross_Unit_RM_Completion_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_By_Status;

   function Count_By_Blocker_Family (Model : Cross_Unit_RM_Completion_Model; Family : Cross_Unit_RM_Completion_Blocker_Family) return Natural is
   begin
      return Query_Count (Query_Blocker_Family (Model, Family));
   end Count_By_Blocker_Family;

   function Accepted_Count (Model : Cross_Unit_RM_Completion_Model) return Natural is
      Total : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Accepted then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Accepted_Count;

   function Blocked_Count (Model : Cross_Unit_RM_Completion_Model) return Natural is
      Total : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Blocked then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Blocked_Count;

   function Indeterminate_Count (Model : Cross_Unit_RM_Completion_Model) return Natural is
      Total : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Indeterminate (Row.Status) then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Cross_Unit_RM_Completion_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Cross_Unit_Generic_Shared_State_RM_Completion_Closure_Legality;
