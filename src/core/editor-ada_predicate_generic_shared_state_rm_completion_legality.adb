package body Editor.Ada_Predicate_Generic_Shared_State_RM_Completion_Legality is

   pragma Suppress (Overflow_Check);
   use type Prior_Predicate.Predicate_Generic_Final_Row_Id;
   use type Cross_RM.Cross_Unit_RM_Completion_Closure_Id;
   use type Elaboration_RM.Elaboration_RM_Completion_Row_Id;
   use type Accessibility_RM.Accessibility_RM_Completion_Row_Id;
   use type Exception_RM.Exception_RM_Completion_Row_Id;
   use type Dataflow_Final.Dataflow_Generic_Final_Row_Id;
   use type Overload_RM.Overload_Generic_RM_Edge_Completion_Id;
   use type Representation_RM.Representation_Generic_RM_Hard_Case_Id;
   use type Tasking_RM.Tasking_Generic_RM_Hard_Case_Id;
   use type AST_Repair.Coverage_Proven_AST_Repair_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   Fingerprint_Modulus : constant Natural := 1_000_003;

   function Mix (Seed : Natural; Value : Natural) return Natural is
   begin
      return (Seed * 131 + Value + 17) mod Fingerprint_Modulus;
   end Mix;

   function Is_AST_Repair_Accepted
     (Status : AST_Repair.Coverage_Proven_AST_Repair_Status) return Boolean is
   begin
      return Status in AST_Repair.Coverage_Proven_AST_Repair_Not_Required
        | AST_Repair.Coverage_Proven_AST_Repair_Parser_Node_Repaired
        | AST_Repair.Coverage_Proven_AST_Repair_Structural_AST_Repaired
        | AST_Repair.Coverage_Proven_AST_Repair_Token_Only_Parse_Repaired
        | AST_Repair.Coverage_Proven_AST_Repair_Source_Span_Repaired
        | AST_Repair.Coverage_Proven_AST_Repair_Metadata_Repaired
        | AST_Repair.Coverage_Proven_AST_Repair_Consumer_Integration_Repaired;
   end Is_AST_Repair_Accepted;

   function Accepted_Status_For
     (Kind : Predicate_RM_Completion_Kind) return Predicate_RM_Completion_Status is
   begin
      case Kind is
         when Predicate_RM_Completion_Assignment =>
            return Predicate_RM_Completion_Legal_Assignment_Accepted;
         when Predicate_RM_Completion_Object_Initialization =>
            return Predicate_RM_Completion_Legal_Object_Initialization_Accepted;
         when Predicate_RM_Completion_Return =>
            return Predicate_RM_Completion_Legal_Return_Accepted;
         when Predicate_RM_Completion_Conversion =>
            return Predicate_RM_Completion_Legal_Conversion_Accepted;
         when Predicate_RM_Completion_Aggregate =>
            return Predicate_RM_Completion_Legal_Aggregate_Accepted;
         when Predicate_RM_Completion_Call_Actual =>
            return Predicate_RM_Completion_Legal_Call_Actual_Accepted;
         when Predicate_RM_Completion_Call_Result =>
            return Predicate_RM_Completion_Legal_Call_Result_Accepted;
         when Predicate_RM_Completion_Generic_Actual =>
            return Predicate_RM_Completion_Legal_Generic_Actual_Accepted;
         when Predicate_RM_Completion_Derived_Type =>
            return Predicate_RM_Completion_Legal_Derived_Type_Accepted;
         when Predicate_RM_Completion_Private_View =>
            return Predicate_RM_Completion_Legal_Private_View_Accepted;
         when Predicate_RM_Completion_Dispatching_Call =>
            return Predicate_RM_Completion_Legal_Dispatching_Call_Accepted;
         when Predicate_RM_Completion_Renamed_Object =>
            return Predicate_RM_Completion_Legal_Renamed_Object_Accepted;
         when Predicate_RM_Completion_Controlled_Finalization =>
            return Predicate_RM_Completion_Legal_Controlled_Finalization_Accepted;
         when Predicate_RM_Completion_Discriminant_Dependent_Object =>
            return Predicate_RM_Completion_Legal_Discriminant_Dependent_Object_Accepted;
         when Predicate_RM_Completion_Cross_Unit_State =>
            return Predicate_RM_Completion_Legal_Cross_Unit_State_Accepted;
         when Predicate_RM_Completion_Variant_Component =>
            return Predicate_RM_Completion_Legal_Variant_Component_Accepted;
         when Predicate_RM_Completion_Access_Escape =>
            return Predicate_RM_Completion_Legal_Access_Escape_Accepted;
         when Predicate_RM_Completion_Volatile_Atomic_State =>
            return Predicate_RM_Completion_Legal_Volatile_Atomic_State_Accepted;
         when Predicate_RM_Completion_Unknown =>
            return Predicate_RM_Completion_Indeterminate;
      end case;
   end Accepted_Status_For;

   function Make_Row
     (Info : Predicate_RM_Completion_Context) return Predicate_RM_Completion_Row is
      Status  : Predicate_RM_Completion_Status := Accepted_Status_For (Info.Kind);
      Family  : Predicate_RM_Completion_Blocker_Family := Predicate_RM_Completion_Blocker_None;
      Blocker_Count : Natural := 0;

      procedure Note
        (New_Status : Predicate_RM_Completion_Status;
         New_Family : Predicate_RM_Completion_Blocker_Family) is
      begin
         if Family = Predicate_RM_Completion_Blocker_None then
            Status := New_Status;
            Family := New_Family;
         end if;
         Blocker_Count := Blocker_Count + 1;
      end Note;

      Fingerprint : Natural := 1254;
   begin
      if Info.Kind = Predicate_RM_Completion_Unknown then
         Note (Predicate_RM_Completion_Indeterminate,
               Predicate_RM_Completion_Blocker_Indeterminate);
      end if;

      if Info.Requires_Prior_Predicate then
         if Info.Prior_Predicate_Row = Prior_Predicate.No_Predicate_Generic_Final_Row then
            Note (Predicate_RM_Completion_Missing_Prior_Predicate_Row,
                  Predicate_RM_Completion_Blocker_Prior_Predicate);
         elsif not Prior_Predicate.Is_Accepted (Info.Prior_Predicate_Status) then
            Note (Predicate_RM_Completion_Prior_Predicate_Blocker,
                  Predicate_RM_Completion_Blocker_Prior_Predicate);
         end if;
      end if;

      if Info.Requires_Cross_RM then
         if Info.Cross_RM_Row = Cross_RM.No_Cross_Unit_RM_Completion_Closure then
            Note (Predicate_RM_Completion_Missing_Cross_Unit_RM_Row,
                  Predicate_RM_Completion_Blocker_Cross_Unit_RM_Completion);
         elsif not Cross_RM.Is_Accepted (Info.Cross_RM_Status) then
            Note (Predicate_RM_Completion_Cross_Unit_RM_Blocker,
                  Predicate_RM_Completion_Blocker_Cross_Unit_RM_Completion);
         end if;
      end if;

      if Info.Requires_Elaboration_RM then
         if Info.Elaboration_RM_Row = Elaboration_RM.No_Elaboration_RM_Completion_Row then
            Note (Predicate_RM_Completion_Missing_Elaboration_RM_Row,
                  Predicate_RM_Completion_Blocker_Elaboration_RM_Completion);
         elsif not Elaboration_RM.Is_Accepted (Info.Elaboration_RM_Status) then
            Note (Predicate_RM_Completion_Elaboration_RM_Blocker,
                  Predicate_RM_Completion_Blocker_Elaboration_RM_Completion);
         end if;
      end if;

      if Info.Requires_Accessibility_RM then
         if Info.Accessibility_RM_Row = Accessibility_RM.No_Accessibility_RM_Completion_Row then
            Note (Predicate_RM_Completion_Missing_Accessibility_RM_Row,
                  Predicate_RM_Completion_Blocker_Accessibility_RM_Completion);
         elsif not Accessibility_RM.Is_Accepted (Info.Accessibility_RM_Status) then
            Note (Predicate_RM_Completion_Accessibility_RM_Blocker,
                  Predicate_RM_Completion_Blocker_Accessibility_RM_Completion);
         end if;
      end if;

      if Info.Requires_Exception_RM then
         if Info.Exception_RM_Row = Exception_RM.No_Exception_RM_Completion_Row then
            Note (Predicate_RM_Completion_Missing_Exception_RM_Row,
                  Predicate_RM_Completion_Blocker_Exception_Finalization_RM_Completion);
         elsif not Exception_RM.Is_Accepted (Info.Exception_RM_Status) then
            Note (Predicate_RM_Completion_Exception_RM_Blocker,
                  Predicate_RM_Completion_Blocker_Exception_Finalization_RM_Completion);
         end if;
      end if;

      if Info.Requires_Dataflow then
         if Info.Dataflow_Row = Dataflow_Final.No_Dataflow_Generic_Final_Row then
            Note (Predicate_RM_Completion_Missing_Dataflow_Row,
                  Predicate_RM_Completion_Blocker_Dataflow_Final);
         elsif not Dataflow_Final.Is_Accepted (Info.Dataflow_Status) then
            Note (Predicate_RM_Completion_Dataflow_Blocker,
                  Predicate_RM_Completion_Blocker_Dataflow_Final);
         end if;
      end if;

      if Info.Requires_Overload_RM then
         if Info.Overload_RM_Row = Overload_RM.No_Overload_Generic_RM_Edge_Completion then
            Note (Predicate_RM_Completion_Missing_Overload_RM_Row,
                  Predicate_RM_Completion_Blocker_Overload_RM_Completion);
         elsif not Overload_RM.Is_Accepted (Info.Overload_RM_Status) then
            Note (Predicate_RM_Completion_Overload_RM_Blocker,
                  Predicate_RM_Completion_Blocker_Overload_RM_Completion);
         end if;
      end if;

      if Info.Requires_Representation_RM then
         if Info.Representation_RM_Row = Representation_RM.No_Representation_Generic_RM_Hard_Case then
            Note (Predicate_RM_Completion_Missing_Representation_RM_Row,
                  Predicate_RM_Completion_Blocker_Representation_RM_Completion);
         elsif not Representation_RM.Is_Accepted (Info.Representation_RM_Status) then
            Note (Predicate_RM_Completion_Representation_RM_Blocker,
                  Predicate_RM_Completion_Blocker_Representation_RM_Completion);
         end if;
      end if;

      if Info.Requires_Tasking_RM then
         if Info.Tasking_RM_Row = Tasking_RM.No_Tasking_Generic_RM_Hard_Case then
            Note (Predicate_RM_Completion_Missing_Tasking_RM_Row,
                  Predicate_RM_Completion_Blocker_Tasking_RM_Completion);
         elsif not Tasking_RM.Is_Accepted (Info.Tasking_RM_Status) then
            Note (Predicate_RM_Completion_Tasking_RM_Blocker,
                  Predicate_RM_Completion_Blocker_Tasking_RM_Completion);
         end if;
      end if;

      if Info.Requires_AST_Repair then
         if Info.AST_Repair_Row = AST_Repair.No_Coverage_Proven_AST_Repair then
            Note (Predicate_RM_Completion_Missing_AST_Repair_Row,
                  Predicate_RM_Completion_Blocker_AST_Repair);
         elsif not Is_AST_Repair_Accepted (Info.AST_Repair_Status) then
            Note (Predicate_RM_Completion_AST_Repair_Blocker,
                  Predicate_RM_Completion_Blocker_AST_Repair);
         end if;
      end if;

      if Info.Static_Predicate_Error then
         Note (Predicate_RM_Completion_Static_Predicate_Blocker,
               Predicate_RM_Completion_Blocker_Static_Predicate);
      end if;
      if Info.Dynamic_Predicate_Check_Error then
         Note (Predicate_RM_Completion_Dynamic_Predicate_Check_Blocker,
               Predicate_RM_Completion_Blocker_Dynamic_Predicate_Check);
      end if;
      if Info.Invariant_Error then
         Note (Predicate_RM_Completion_Invariant_Blocker,
               Predicate_RM_Completion_Blocker_Invariant);
      end if;
      if Info.Private_View_Error then
         Note (Predicate_RM_Completion_Private_View_Blocker,
               Predicate_RM_Completion_Blocker_Private_View);
      end if;
      if Info.Derived_Invariant_Error then
         Note (Predicate_RM_Completion_Derived_Invariant_Blocker,
               Predicate_RM_Completion_Blocker_Derived_Invariant);
      end if;
      if Info.Generic_Substitution_Error then
         Note (Predicate_RM_Completion_Generic_Substitution_Blocker,
               Predicate_RM_Completion_Blocker_Generic_Substitution);
      end if;
      if Info.Discriminant_Predicate_Error then
         Note (Predicate_RM_Completion_Discriminant_Predicate_Blocker,
               Predicate_RM_Completion_Blocker_Discriminant_Predicate);
      end if;
      if Info.Controlled_Finalization_Error then
         Note (Predicate_RM_Completion_Controlled_Finalization_Blocker,
               Predicate_RM_Completion_Blocker_Controlled_Finalization);
      end if;
      if Info.Renamed_Predicate_Source_Error then
         Note (Predicate_RM_Completion_Renamed_Predicate_Source_Blocker,
               Predicate_RM_Completion_Blocker_Renamed_Predicate_Source);
      end if;
      if Info.Dispatching_Effect_Error then
         Note (Predicate_RM_Completion_Dispatching_Effect_Blocker,
               Predicate_RM_Completion_Blocker_Dispatching_Effect);
      end if;
      if Info.Variant_Component_Error then
         Note (Predicate_RM_Completion_Variant_Component_Blocker,
               Predicate_RM_Completion_Blocker_Variant_Component);
      end if;
      if Info.Access_Escape_Error then
         Note (Predicate_RM_Completion_Access_Escape_Blocker,
               Predicate_RM_Completion_Blocker_Access_Escape);
      end if;
      if Info.Volatile_Atomic_Effect_Error then
         Note (Predicate_RM_Completion_Volatile_Atomic_Effect_Blocker,
               Predicate_RM_Completion_Blocker_Volatile_Atomic_Effect);
      end if;
      if Info.View_Barrier then
         Note (Predicate_RM_Completion_View_Barrier,
               Predicate_RM_Completion_Blocker_View_Barrier);
      end if;

      if Info.Source_Fingerprint /= Info.Expected_Source_Fingerprint then
         Note (Predicate_RM_Completion_Source_Fingerprint_Mismatch,
               Predicate_RM_Completion_Blocker_Source_Fingerprint);
      end if;
      if Info.Substitution_Fingerprint /= Info.Expected_Substitution_Fingerprint then
         Note (Predicate_RM_Completion_Substitution_Fingerprint_Mismatch,
               Predicate_RM_Completion_Blocker_Substitution_Fingerprint);
      end if;
      if Info.Explicit_Indeterminate then
         Note (Predicate_RM_Completion_Indeterminate,
               Predicate_RM_Completion_Blocker_Indeterminate);
      end if;
      if Info.Explicit_Multiple_Blockers or else Blocker_Count > 1 then
         Status := Predicate_RM_Completion_Multiple_Blockers;
         Family := Predicate_RM_Completion_Blocker_Multiple;
      end if;

      Fingerprint := Mix (Fingerprint, Natural (Info.Id));
      Fingerprint := Mix (Fingerprint, Predicate_RM_Completion_Kind'Pos (Info.Kind));
      Fingerprint := Mix (Fingerprint, Predicate_RM_Completion_Status'Pos (Status));
      Fingerprint := Mix (Fingerprint, Predicate_RM_Completion_Blocker_Family'Pos (Family));
      Fingerprint := Mix (Fingerprint, Natural (Info.Node));
      Fingerprint := Mix (Fingerprint, Info.Source_Fingerprint);
      Fingerprint := Mix (Fingerprint, Info.Substitution_Fingerprint);

      return
        (Id                 => Info.Id,
         Kind               => Info.Kind,
         Status             => Status,
         Blocker_Family     => Family,
         Node               => Info.Node,
         Source_Fingerprint => Info.Source_Fingerprint,
         Stable_Fingerprint => Fingerprint,
         Message            => Info.Message);
   end Make_Row;

   procedure Clear (Model : in out Predicate_RM_Completion_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Stable_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Predicate_RM_Completion_Context_Model;
      Info  : Predicate_RM_Completion_Context) is
   begin
      Model.Items.Append (Info);
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Natural (Info.Id));
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Predicate_RM_Completion_Kind'Pos (Info.Kind));
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Natural (Info.Node));
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Info.Source_Fingerprint);
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Info.Substitution_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Predicate_RM_Completion_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At
     (Model : Predicate_RM_Completion_Context_Model;
      Index : Positive) return Predicate_RM_Completion_Context is
   begin
      return Model.Items.Element (Index);
   end Context_At;

   function Context_Fingerprint (Model : Predicate_RM_Completion_Context_Model) return Natural is
   begin
      return Model.Stable_Fingerprint;
   end Context_Fingerprint;

   function Build
     (Contexts : Predicate_RM_Completion_Context_Model) return Predicate_RM_Completion_Model is
      Result : Predicate_RM_Completion_Model;
   begin
      for Info of Contexts.Items loop
         declare
            Row : constant Predicate_RM_Completion_Row := Make_Row (Info);
         begin
            Result.Rows.Append (Row);
            Result.Stable_Fingerprint := Mix (Result.Stable_Fingerprint, Row.Stable_Fingerprint);
         end;
      end loop;
      return Result;
   end Build;

   function Count (Model : Predicate_RM_Completion_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : Predicate_RM_Completion_Model;
      Index : Positive) return Predicate_RM_Completion_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Predicate_RM_Completion_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Predicate_RM_Completion_Set;
      Index : Positive) return Predicate_RM_Completion_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   function Query_Status
     (Model  : Predicate_RM_Completion_Model;
      Status : Predicate_RM_Completion_Status) return Predicate_RM_Completion_Set is
      Result : Predicate_RM_Completion_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Query_Status;

   function Query_Blocker_Family
     (Model  : Predicate_RM_Completion_Model;
      Family : Predicate_RM_Completion_Blocker_Family) return Predicate_RM_Completion_Set is
      Result : Predicate_RM_Completion_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Family then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Query_Blocker_Family;

   function Find_By_Node
     (Model : Predicate_RM_Completion_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Predicate_RM_Completion_Set is
      Result : Predicate_RM_Completion_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Find_By_Node;

   function Find_By_Source_Fingerprint
     (Model              : Predicate_RM_Completion_Model;
      Source_Fingerprint : Natural) return Predicate_RM_Completion_Set is
      Result : Predicate_RM_Completion_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Source_Fingerprint then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Find_By_Source_Fingerprint;

   function Count_By_Status
     (Model  : Predicate_RM_Completion_Model;
      Status : Predicate_RM_Completion_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_By_Status;

   function Count_By_Blocker_Family
     (Model  : Predicate_RM_Completion_Model;
      Family : Predicate_RM_Completion_Blocker_Family) return Natural is
   begin
      return Query_Count (Query_Blocker_Family (Model, Family));
   end Count_By_Blocker_Family;

   function Accepted_Count (Model : Predicate_RM_Completion_Model) return Natural is
      Result : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Accepted (Row.Status) then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Accepted_Count;

   function Blocked_Count (Model : Predicate_RM_Completion_Model) return Natural is
      Result : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Blocked (Row.Status) then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Blocked_Count;

   function Indeterminate_Count (Model : Predicate_RM_Completion_Model) return Natural is
      Result : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Indeterminate (Row.Status) then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Predicate_RM_Completion_Model) return Natural is
   begin
      return Model.Stable_Fingerprint;
   end Stable_Fingerprint;

   function Is_Accepted (Status : Predicate_RM_Completion_Status) return Boolean is
   begin
      return Status in Predicate_RM_Completion_Legal_Assignment_Accepted
        | Predicate_RM_Completion_Legal_Object_Initialization_Accepted
        | Predicate_RM_Completion_Legal_Return_Accepted
        | Predicate_RM_Completion_Legal_Conversion_Accepted
        | Predicate_RM_Completion_Legal_Aggregate_Accepted
        | Predicate_RM_Completion_Legal_Call_Actual_Accepted
        | Predicate_RM_Completion_Legal_Call_Result_Accepted
        | Predicate_RM_Completion_Legal_Generic_Actual_Accepted
        | Predicate_RM_Completion_Legal_Derived_Type_Accepted
        | Predicate_RM_Completion_Legal_Private_View_Accepted
        | Predicate_RM_Completion_Legal_Dispatching_Call_Accepted
        | Predicate_RM_Completion_Legal_Renamed_Object_Accepted
        | Predicate_RM_Completion_Legal_Controlled_Finalization_Accepted
        | Predicate_RM_Completion_Legal_Discriminant_Dependent_Object_Accepted
        | Predicate_RM_Completion_Legal_Cross_Unit_State_Accepted
        | Predicate_RM_Completion_Legal_Variant_Component_Accepted
        | Predicate_RM_Completion_Legal_Access_Escape_Accepted
        | Predicate_RM_Completion_Legal_Volatile_Atomic_State_Accepted;
   end Is_Accepted;

   function Is_Blocked (Status : Predicate_RM_Completion_Status) return Boolean is
   begin
      return (Status not in Predicate_RM_Completion_Not_Checked
              | Predicate_RM_Completion_Indeterminate)
        and then not Is_Accepted (Status);
   end Is_Blocked;

   function Is_Indeterminate (Status : Predicate_RM_Completion_Status) return Boolean is
   begin
      return Status = Predicate_RM_Completion_Indeterminate;
   end Is_Indeterminate;

end Editor.Ada_Predicate_Generic_Shared_State_RM_Completion_Legality;
