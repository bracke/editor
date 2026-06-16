with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Accessibility_Generic_Shared_State_RM_Completion_Legality is

   pragma Suppress (Overflow_Check);

   use type Cross_RM.Cross_Unit_RM_Completion_Closure_Id;
   use type Prior_Access.Accessibility_Generic_Final_Row_Id;
   use type Elaboration_RM.Elaboration_RM_Completion_Row_Id;
   use type Overload_RM.Overload_Generic_RM_Edge_Completion_Id;
   use type Representation_RM.Representation_Generic_RM_Hard_Case_Id;
   use type Tasking_RM.Tasking_Generic_RM_Hard_Case_Id;
   use type AST_Repair.Coverage_Proven_AST_Repair_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (Left, Right : Natural) return Natural is
      type Hash_Value is mod 2 ** 32;
      Mixed : constant Hash_Value := Hash_Value (Left) * 131 + Hash_Value (Right) + 17;
   begin
      return Natural (Mixed mod Hash_Value (2_147_483_647));
   end Mix;

   function Accepted_For (Kind : Accessibility_RM_Completion_Kind) return Accessibility_RM_Completion_Status is
   begin
      case Kind is
         when Accessibility_RM_Completion_Anonymous_Access_Result => return Accessibility_RM_Completion_Legal_Anonymous_Access_Result_Accepted;
         when Accessibility_RM_Completion_Anonymous_Access_Parameter => return Accessibility_RM_Completion_Legal_Anonymous_Access_Parameter_Accepted;
         when Accessibility_RM_Completion_Access_Discriminant => return Accessibility_RM_Completion_Legal_Access_Discriminant_Accepted;
         when Accessibility_RM_Completion_Allocator_Master => return Accessibility_RM_Completion_Legal_Allocator_Master_Accepted;
         when Accessibility_RM_Completion_Access_Conversion => return Accessibility_RM_Completion_Legal_Access_Conversion_Accepted;
         when Accessibility_RM_Completion_Return_Object => return Accessibility_RM_Completion_Legal_Return_Object_Accepted;
         when Accessibility_RM_Completion_Return_Access => return Accessibility_RM_Completion_Legal_Return_Access_Accepted;
         when Accessibility_RM_Completion_Generic_Access_Actual => return Accessibility_RM_Completion_Legal_Generic_Access_Actual_Accepted;
         when Accessibility_RM_Completion_Generic_Replay_Escape => return Accessibility_RM_Completion_Legal_Generic_Replay_Escape_Accepted;
         when Accessibility_RM_Completion_Renaming => return Accessibility_RM_Completion_Legal_Renaming_Accepted;
         when Accessibility_RM_Completion_Controlled_Finalization => return Accessibility_RM_Completion_Legal_Controlled_Finalization_Accepted;
         when Accessibility_RM_Completion_Private_Full_View => return Accessibility_RM_Completion_Legal_Private_Full_View_Accepted;
         when Accessibility_RM_Completion_Cross_Unit_Lifetime => return Accessibility_RM_Completion_Legal_Cross_Unit_Lifetime_Accepted;
         when Accessibility_RM_Completion_Task_Protected_Lifetime => return Accessibility_RM_Completion_Legal_Task_Protected_Lifetime_Accepted;
         when Accessibility_RM_Completion_Representation_Sensitive_Lifetime => return Accessibility_RM_Completion_Legal_Representation_Sensitive_Lifetime_Accepted;
         when Accessibility_RM_Completion_Dispatching_Access_Result => return Accessibility_RM_Completion_Legal_Dispatching_Access_Result_Accepted;
         when Accessibility_RM_Completion_Variant_Component_Access => return Accessibility_RM_Completion_Legal_Variant_Component_Access_Accepted;
         when Accessibility_RM_Completion_Protected_Access => return Accessibility_RM_Completion_Legal_Protected_Access_Accepted;
         when Accessibility_RM_Completion_Unknown => return Accessibility_RM_Completion_Indeterminate;
      end case;
   end Accepted_For;

   function Is_Accepted (Status : Accessibility_RM_Completion_Status) return Boolean is
   begin
      case Status is
         when Accessibility_RM_Completion_Legal_Anonymous_Access_Result_Accepted
            | Accessibility_RM_Completion_Legal_Anonymous_Access_Parameter_Accepted
            | Accessibility_RM_Completion_Legal_Access_Discriminant_Accepted
            | Accessibility_RM_Completion_Legal_Allocator_Master_Accepted
            | Accessibility_RM_Completion_Legal_Access_Conversion_Accepted
            | Accessibility_RM_Completion_Legal_Return_Object_Accepted
            | Accessibility_RM_Completion_Legal_Return_Access_Accepted
            | Accessibility_RM_Completion_Legal_Generic_Access_Actual_Accepted
            | Accessibility_RM_Completion_Legal_Generic_Replay_Escape_Accepted
            | Accessibility_RM_Completion_Legal_Renaming_Accepted
            | Accessibility_RM_Completion_Legal_Controlled_Finalization_Accepted
            | Accessibility_RM_Completion_Legal_Private_Full_View_Accepted
            | Accessibility_RM_Completion_Legal_Cross_Unit_Lifetime_Accepted
            | Accessibility_RM_Completion_Legal_Task_Protected_Lifetime_Accepted
            | Accessibility_RM_Completion_Legal_Representation_Sensitive_Lifetime_Accepted
            | Accessibility_RM_Completion_Legal_Dispatching_Access_Result_Accepted
            | Accessibility_RM_Completion_Legal_Variant_Component_Access_Accepted
            | Accessibility_RM_Completion_Legal_Protected_Access_Accepted => return True;
         when others => return False;
      end case;
   end Is_Accepted;

   function Is_Indeterminate (Status : Accessibility_RM_Completion_Status) return Boolean is
   begin
      return Status = Accessibility_RM_Completion_Indeterminate;
   end Is_Indeterminate;

   function Is_Blocked (Status : Accessibility_RM_Completion_Status) return Boolean is
   begin
      return not Is_Accepted (Status)
        and then Status /= Accessibility_RM_Completion_Not_Checked
        and then not Is_Indeterminate (Status);
   end Is_Blocked;

   function Family_For (Status : Accessibility_RM_Completion_Status) return Accessibility_RM_Completion_Blocker_Family is
   begin
      case Status is
         when Accessibility_RM_Completion_Missing_Cross_Unit_RM_Row | Accessibility_RM_Completion_Cross_Unit_RM_Blocker => return Accessibility_RM_Completion_Blocker_Cross_Unit_RM_Completion;
         when Accessibility_RM_Completion_Missing_Prior_Accessibility_Row | Accessibility_RM_Completion_Prior_Accessibility_Blocker => return Accessibility_RM_Completion_Blocker_Prior_Accessibility;
         when Accessibility_RM_Completion_Missing_Elaboration_RM_Row | Accessibility_RM_Completion_Elaboration_RM_Blocker => return Accessibility_RM_Completion_Blocker_Elaboration_RM_Completion;
         when Accessibility_RM_Completion_Missing_Overload_RM_Row | Accessibility_RM_Completion_Overload_RM_Blocker => return Accessibility_RM_Completion_Blocker_Overload_RM_Completion;
         when Accessibility_RM_Completion_Missing_Representation_RM_Row | Accessibility_RM_Completion_Representation_RM_Blocker => return Accessibility_RM_Completion_Blocker_Representation_RM_Completion;
         when Accessibility_RM_Completion_Missing_Tasking_RM_Row | Accessibility_RM_Completion_Tasking_RM_Blocker => return Accessibility_RM_Completion_Blocker_Tasking_RM_Completion;
         when Accessibility_RM_Completion_Missing_AST_Repair_Row | Accessibility_RM_Completion_AST_Repair_Blocker => return Accessibility_RM_Completion_Blocker_AST_Repair;
         when Accessibility_RM_Completion_Access_Level_Blocker => return Accessibility_RM_Completion_Blocker_Access_Level;
         when Accessibility_RM_Completion_Master_Escape_Blocker => return Accessibility_RM_Completion_Blocker_Master_Escape;
         when Accessibility_RM_Completion_Return_Object_Blocker => return Accessibility_RM_Completion_Blocker_Return_Object;
         when Accessibility_RM_Completion_Renaming_Lifetime_Blocker => return Accessibility_RM_Completion_Blocker_Renaming_Lifetime;
         when Accessibility_RM_Completion_Finalization_Master_Blocker => return Accessibility_RM_Completion_Blocker_Finalization_Master;
         when Accessibility_RM_Completion_Private_Full_View_Blocker => return Accessibility_RM_Completion_Blocker_Private_Full_View;
         when Accessibility_RM_Completion_Cross_Unit_Lifetime_Blocker => return Accessibility_RM_Completion_Blocker_Cross_Unit_Lifetime;
         when Accessibility_RM_Completion_Task_Protected_Lifetime_Blocker => return Accessibility_RM_Completion_Blocker_Task_Protected_Lifetime;
         when Accessibility_RM_Completion_Representation_Sensitive_Lifetime_Blocker => return Accessibility_RM_Completion_Blocker_Representation_Sensitive_Lifetime;
         when Accessibility_RM_Completion_Dispatching_Access_Result_Blocker => return Accessibility_RM_Completion_Blocker_Dispatching_Access_Result;
         when Accessibility_RM_Completion_Variant_Component_Access_Blocker => return Accessibility_RM_Completion_Blocker_Variant_Component_Access;
         when Accessibility_RM_Completion_Protected_Access_Blocker => return Accessibility_RM_Completion_Blocker_Protected_Access;
         when Accessibility_RM_Completion_Generic_Body_Unavailable => return Accessibility_RM_Completion_Blocker_Generic_Body;
         when Accessibility_RM_Completion_View_Barrier => return Accessibility_RM_Completion_Blocker_View_Barrier;
         when Accessibility_RM_Completion_Source_Fingerprint_Mismatch => return Accessibility_RM_Completion_Blocker_Source_Fingerprint;
         when Accessibility_RM_Completion_Substitution_Fingerprint_Mismatch => return Accessibility_RM_Completion_Blocker_Substitution_Fingerprint;
         when Accessibility_RM_Completion_Multiple_Blockers => return Accessibility_RM_Completion_Blocker_Multiple;
         when Accessibility_RM_Completion_Indeterminate => return Accessibility_RM_Completion_Blocker_Indeterminate;
         when others => return Accessibility_RM_Completion_Blocker_None;
      end case;
   end Family_For;

   function Local_Blocker_Count (C : Accessibility_RM_Completion_Context) return Natural is
      Count : Natural := 0;
   begin
      if C.Access_Level_Blocker then Count := Count + 1; end if;
      if C.Master_Escape_Blocker then Count := Count + 1; end if;
      if C.Return_Object_Blocker then Count := Count + 1; end if;
      if C.Renaming_Lifetime_Blocker then Count := Count + 1; end if;
      if C.Finalization_Master_Blocker then Count := Count + 1; end if;
      if C.Private_Full_View_Blocker then Count := Count + 1; end if;
      if C.Cross_Unit_Lifetime_Blocker then Count := Count + 1; end if;
      if C.Task_Protected_Lifetime_Blocker then Count := Count + 1; end if;
      if C.Representation_Sensitive_Lifetime_Blocker then Count := Count + 1; end if;
      if C.Dispatching_Access_Result_Blocker then Count := Count + 1; end if;
      if C.Variant_Component_Access_Blocker then Count := Count + 1; end if;
      if C.Protected_Access_Blocker then Count := Count + 1; end if;
      if C.Generic_Body_Unavailable then Count := Count + 1; end if;
      if C.View_Barrier then Count := Count + 1; end if;
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then Count := Count + 1; end if;
      if C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then Count := Count + 1; end if;
      return Count;
   end Local_Blocker_Count;

   function Classify (C : Accessibility_RM_Completion_Context) return Accessibility_RM_Completion_Status is
   begin
      if Local_Blocker_Count (C) > 1 then
         return Accessibility_RM_Completion_Multiple_Blockers;
      elsif C.Access_Level_Blocker then
         return Accessibility_RM_Completion_Access_Level_Blocker;
      elsif C.Master_Escape_Blocker then
         return Accessibility_RM_Completion_Master_Escape_Blocker;
      elsif C.Return_Object_Blocker then
         return Accessibility_RM_Completion_Return_Object_Blocker;
      elsif C.Renaming_Lifetime_Blocker then
         return Accessibility_RM_Completion_Renaming_Lifetime_Blocker;
      elsif C.Finalization_Master_Blocker then
         return Accessibility_RM_Completion_Finalization_Master_Blocker;
      elsif C.Private_Full_View_Blocker then
         return Accessibility_RM_Completion_Private_Full_View_Blocker;
      elsif C.Cross_Unit_Lifetime_Blocker then
         return Accessibility_RM_Completion_Cross_Unit_Lifetime_Blocker;
      elsif C.Task_Protected_Lifetime_Blocker then
         return Accessibility_RM_Completion_Task_Protected_Lifetime_Blocker;
      elsif C.Representation_Sensitive_Lifetime_Blocker then
         return Accessibility_RM_Completion_Representation_Sensitive_Lifetime_Blocker;
      elsif C.Dispatching_Access_Result_Blocker then
         return Accessibility_RM_Completion_Dispatching_Access_Result_Blocker;
      elsif C.Variant_Component_Access_Blocker then
         return Accessibility_RM_Completion_Variant_Component_Access_Blocker;
      elsif C.Protected_Access_Blocker then
         return Accessibility_RM_Completion_Protected_Access_Blocker;
      elsif C.Generic_Body_Unavailable then
         return Accessibility_RM_Completion_Generic_Body_Unavailable;
      elsif C.View_Barrier then
         return Accessibility_RM_Completion_View_Barrier;
      elsif C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         return Accessibility_RM_Completion_Source_Fingerprint_Mismatch;
      elsif C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then
         return Accessibility_RM_Completion_Substitution_Fingerprint_Mismatch;
      elsif C.Requires_Cross_RM and then C.Cross_RM_Row = Cross_RM.No_Cross_Unit_RM_Completion_Closure then
         return Accessibility_RM_Completion_Missing_Cross_Unit_RM_Row;
      elsif C.Requires_Cross_RM and then not Cross_RM.Is_Accepted (C.Cross_RM_Status) then
         return Accessibility_RM_Completion_Cross_Unit_RM_Blocker;
      elsif C.Requires_Prior_Accessibility and then C.Prior_Accessibility_Row = Prior_Access.No_Accessibility_Generic_Final_Row then
         return Accessibility_RM_Completion_Missing_Prior_Accessibility_Row;
      elsif C.Requires_Prior_Accessibility and then not Prior_Access.Is_Accepted (C.Prior_Accessibility_Status) then
         return Accessibility_RM_Completion_Prior_Accessibility_Blocker;
      elsif C.Requires_Elaboration_RM and then C.Elaboration_RM_Row = Elaboration_RM.No_Elaboration_RM_Completion_Row then
         return Accessibility_RM_Completion_Missing_Elaboration_RM_Row;
      elsif C.Requires_Elaboration_RM and then not Elaboration_RM.Is_Accepted (C.Elaboration_RM_Status) then
         return Accessibility_RM_Completion_Elaboration_RM_Blocker;
      elsif C.Requires_Overload_RM and then C.Overload_RM_Row = Overload_RM.No_Overload_Generic_RM_Edge_Completion then
         return Accessibility_RM_Completion_Missing_Overload_RM_Row;
      elsif C.Requires_Overload_RM and then not Overload_RM.Is_Accepted (C.Overload_RM_Status) then
         return Accessibility_RM_Completion_Overload_RM_Blocker;
      elsif C.Requires_Representation_RM and then C.Representation_RM_Row = Representation_RM.No_Representation_Generic_RM_Hard_Case then
         return Accessibility_RM_Completion_Missing_Representation_RM_Row;
      elsif C.Requires_Representation_RM and then not Representation_RM.Is_Accepted (C.Representation_RM_Status) then
         return Accessibility_RM_Completion_Representation_RM_Blocker;
      elsif C.Requires_Tasking_RM and then C.Tasking_RM_Row = Tasking_RM.No_Tasking_Generic_RM_Hard_Case then
         return Accessibility_RM_Completion_Missing_Tasking_RM_Row;
      elsif C.Requires_Tasking_RM and then not Tasking_RM.Is_Accepted (C.Tasking_RM_Status) then
         return Accessibility_RM_Completion_Tasking_RM_Blocker;
      elsif C.Requires_AST_Repair and then C.AST_Repair_Row = AST_Repair.No_Coverage_Proven_AST_Repair then
         return Accessibility_RM_Completion_Missing_AST_Repair_Row;
      elsif C.Requires_AST_Repair and then not AST_Repair.Is_Repaired (C.AST_Repair_Status) then
         return Accessibility_RM_Completion_AST_Repair_Blocker;
      else
         return Accepted_For (C.Kind);
      end if;
   end Classify;

   function Message_For (Status : Accessibility_RM_Completion_Status; Kind : Accessibility_RM_Completion_Kind; Family : Accessibility_RM_Completion_Blocker_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("accessibility generic/shared-state RM completion legality " &
         Accessibility_RM_Completion_Status'Image (Status) &
         " kind=" & Accessibility_RM_Completion_Kind'Image (Kind) &
         " blocker=" & Accessibility_RM_Completion_Blocker_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint (Row : Accessibility_RM_Completion_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Context));
      H := Mix (H, Accessibility_RM_Completion_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Accessibility_RM_Completion_Status'Pos (Row.Status) + 1);
      H := Mix (H, Accessibility_RM_Completion_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Blocker_Count);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Build_Row (C : Accessibility_RM_Completion_Context) return Accessibility_RM_Completion_Row is
      Status : constant Accessibility_RM_Completion_Status := Classify (C);
      Family : constant Accessibility_RM_Completion_Blocker_Family := Family_For (Status);
      Row : Accessibility_RM_Completion_Row;
   begin
      Row.Id := C.Id;
      Row.Context := C.Id;
      Row.Kind := C.Kind;
      Row.Status := Status;
      Row.Blocker_Family := Family;
      Row.Node := C.Node;
      Row.Object_Name := C.Object_Name;
      Row.Type_Name := C.Type_Name;
      Row.Generic_Unit_Name := C.Generic_Unit_Name;
      Row.Instance_Name := C.Instance_Name;
      Row.State_Name := C.State_Name;
      Row.Accepted := Is_Accepted (Status);
      Row.Blocked := Is_Blocked (Status);
      Row.Blocks_Downstream := Row.Blocked;
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
   end Build_Row;

   procedure Clear (Model : in out Accessibility_RM_Completion_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Stable_Fingerprint := 0;
   end Clear;

   procedure Add_Context (Model : in out Accessibility_RM_Completion_Context_Model; Info : Accessibility_RM_Completion_Context) is
   begin
      Model.Items.Append (Info);
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Natural (Info.Id));
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Accessibility_RM_Completion_Kind'Pos (Info.Kind) + 1);
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Natural (Info.Node));
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Info.Source_Fingerprint);
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Info.Substitution_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Accessibility_RM_Completion_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At (Model : Accessibility_RM_Completion_Context_Model; Index : Positive) return Accessibility_RM_Completion_Context is
   begin
      return Model.Items.Element (Index);
   end Context_At;

   function Context_Fingerprint (Model : Accessibility_RM_Completion_Context_Model) return Natural is
   begin
      return Model.Stable_Fingerprint;
   end Context_Fingerprint;

   function Build (Contexts : Accessibility_RM_Completion_Context_Model) return Accessibility_RM_Completion_Model is
      Result : Accessibility_RM_Completion_Model;
   begin
      for I in 1 .. Context_Count (Contexts) loop
         declare
            Row : constant Accessibility_RM_Completion_Row := Build_Row (Context_At (Contexts, I));
         begin
            Result.Rows.Append (Row);
            Result.Stable_Fingerprint := Mix (Result.Stable_Fingerprint, Row.Fingerprint);
         end;
      end loop;
      Result.Stable_Fingerprint := Mix (Result.Stable_Fingerprint, Context_Fingerprint (Contexts));
      return Result;
   end Build;

   function Count (Model : Accessibility_RM_Completion_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At (Model : Accessibility_RM_Completion_Model; Index : Positive) return Accessibility_RM_Completion_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Accessibility_RM_Completion_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At (Set : Accessibility_RM_Completion_Set; Index : Positive) return Accessibility_RM_Completion_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   function Query_Status (Model : Accessibility_RM_Completion_Model; Status : Accessibility_RM_Completion_Status) return Accessibility_RM_Completion_Set is
      Result : Accessibility_RM_Completion_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Query_Status;

   function Query_Blocker_Family (Model : Accessibility_RM_Completion_Model; Family : Accessibility_RM_Completion_Blocker_Family) return Accessibility_RM_Completion_Set is
      Result : Accessibility_RM_Completion_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Family then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Query_Blocker_Family;

   function Find_By_Node (Model : Accessibility_RM_Completion_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Accessibility_RM_Completion_Set is
      Result : Accessibility_RM_Completion_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Find_By_Node;

   function Find_By_Source_Fingerprint (Model : Accessibility_RM_Completion_Model; Source_Fingerprint : Natural) return Accessibility_RM_Completion_Set is
      Result : Accessibility_RM_Completion_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Source_Fingerprint then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Find_By_Source_Fingerprint;

   function Count_By_Status (Model : Accessibility_RM_Completion_Model; Status : Accessibility_RM_Completion_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_By_Status;

   function Count_By_Blocker_Family (Model : Accessibility_RM_Completion_Model; Family : Accessibility_RM_Completion_Blocker_Family) return Natural is
   begin
      return Query_Count (Query_Blocker_Family (Model, Family));
   end Count_By_Blocker_Family;

   function Accepted_Count (Model : Accessibility_RM_Completion_Model) return Natural is
      Result : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Accepted then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Accepted_Count;

   function Blocked_Count (Model : Accessibility_RM_Completion_Model) return Natural is
      Result : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Blocked then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Blocked_Count;

   function Indeterminate_Count (Model : Accessibility_RM_Completion_Model) return Natural is
      Result : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Indeterminate (Row.Status) then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Accessibility_RM_Completion_Model) return Natural is
   begin
      return Model.Stable_Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Accessibility_Generic_Shared_State_RM_Completion_Legality;
