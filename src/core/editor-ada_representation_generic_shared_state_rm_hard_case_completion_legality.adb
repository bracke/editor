with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Representation_Generic_Shared_State_RM_Hard_Case_Completion_Legality is

   pragma Suppress (Overflow_Check);
   use type Previous.Representation_Generic_Final_Row_Id;
   use type Overload_Edges.Overload_Generic_RM_Edge_Completion_Id;
   use type Closure.Generic_Shared_State_Final_Stabilized_Closure_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;


   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 131) + B + 17) mod 2_147_483_647;
   end Mix;

   function Closure_Accepted
     (Status : Closure.Generic_Shared_State_Final_Stabilized_Closure_Status) return Boolean is
   begin
      return Status in
        Closure.Generic_Shared_State_Final_Stabilized_Closure_Accepted_Current |
        Closure.Generic_Shared_State_Final_Stabilized_Closure_Accepted_Not_Required;
   end Closure_Accepted;

   function Is_Accepted (Status : Representation_Generic_RM_Hard_Case_Status) return Boolean is
   begin
      return Status in
        Representation_Generic_RM_Hard_Case_Legal_Volatile_Atomic_Representation_Clause_Accepted |
        Representation_Generic_RM_Hard_Case_Legal_Independent_Component_Accepted |
        Representation_Generic_RM_Hard_Case_Legal_Limited_Private_Stream_Attribute_Accepted |
        Representation_Generic_RM_Hard_Case_Legal_Inherited_Operational_Attribute_Accepted |
        Representation_Generic_RM_Hard_Case_Legal_Generic_Formal_Instance_Freezing_Accepted |
        Representation_Generic_RM_Hard_Case_Legal_Discriminant_Dependent_Layout_Accepted |
        Representation_Generic_RM_Hard_Case_Legal_Controlled_Finalized_Component_Accepted |
        Representation_Generic_RM_Hard_Case_Legal_Protected_Task_Representation_Effect_Accepted;
   end Is_Accepted;

   function Is_Indeterminate (Status : Representation_Generic_RM_Hard_Case_Status) return Boolean is
   begin
      return Status = Representation_Generic_RM_Hard_Case_Indeterminate;
   end Is_Indeterminate;

   function Is_Blocked (Status : Representation_Generic_RM_Hard_Case_Status) return Boolean is
   begin
      return not Is_Accepted (Status)
        and then Status /= Representation_Generic_RM_Hard_Case_Not_Checked
        and then not Is_Indeterminate (Status);
   end Is_Blocked;

   function Accepted_For
     (Kind : Representation_Generic_RM_Hard_Case_Kind) return Representation_Generic_RM_Hard_Case_Status is
   begin
      case Kind is
         when Representation_Generic_RM_Hard_Case_Volatile_Atomic_Representation_Clause =>
            return Representation_Generic_RM_Hard_Case_Legal_Volatile_Atomic_Representation_Clause_Accepted;
         when Representation_Generic_RM_Hard_Case_Independent_Component =>
            return Representation_Generic_RM_Hard_Case_Legal_Independent_Component_Accepted;
         when Representation_Generic_RM_Hard_Case_Limited_Private_Stream_Attribute =>
            return Representation_Generic_RM_Hard_Case_Legal_Limited_Private_Stream_Attribute_Accepted;
         when Representation_Generic_RM_Hard_Case_Inherited_Operational_Attribute =>
            return Representation_Generic_RM_Hard_Case_Legal_Inherited_Operational_Attribute_Accepted;
         when Representation_Generic_RM_Hard_Case_Generic_Formal_Instance_Freezing =>
            return Representation_Generic_RM_Hard_Case_Legal_Generic_Formal_Instance_Freezing_Accepted;
         when Representation_Generic_RM_Hard_Case_Discriminant_Dependent_Layout =>
            return Representation_Generic_RM_Hard_Case_Legal_Discriminant_Dependent_Layout_Accepted;
         when Representation_Generic_RM_Hard_Case_Controlled_Finalized_Component =>
            return Representation_Generic_RM_Hard_Case_Legal_Controlled_Finalized_Component_Accepted;
         when Representation_Generic_RM_Hard_Case_Protected_Task_Representation_Effect =>
            return Representation_Generic_RM_Hard_Case_Legal_Protected_Task_Representation_Effect_Accepted;
         when Representation_Generic_RM_Hard_Case_Unknown =>
            return Representation_Generic_RM_Hard_Case_Indeterminate;
      end case;
   end Accepted_For;

   function Family_For
     (Status : Representation_Generic_RM_Hard_Case_Status) return Representation_Generic_RM_Hard_Case_Blocker_Family is
   begin
      case Status is
         when Representation_Generic_RM_Hard_Case_Missing_Previous_Representation_Row |
              Representation_Generic_RM_Hard_Case_Previous_Representation_Blocker =>
            return Representation_Generic_RM_Hard_Case_Blocker_Previous_Representation;
         when Representation_Generic_RM_Hard_Case_Missing_Overload_RM_Edge_Row |
              Representation_Generic_RM_Hard_Case_Overload_RM_Edge_Blocker =>
            return Representation_Generic_RM_Hard_Case_Blocker_Overload_RM_Edge;
         when Representation_Generic_RM_Hard_Case_Missing_Stabilized_Closure_Row |
              Representation_Generic_RM_Hard_Case_Stabilized_Closure_Blocker =>
            return Representation_Generic_RM_Hard_Case_Blocker_Stabilized_Closure;
         when Representation_Generic_RM_Hard_Case_Volatile_Atomic_Clause_Blocker =>
            return Representation_Generic_RM_Hard_Case_Blocker_Volatile_Atomic_Clause;
         when Representation_Generic_RM_Hard_Case_Independent_Component_Blocker =>
            return Representation_Generic_RM_Hard_Case_Blocker_Independent_Component;
         when Representation_Generic_RM_Hard_Case_Limited_Private_View_Blocker =>
            return Representation_Generic_RM_Hard_Case_Blocker_Limited_Private_View;
         when Representation_Generic_RM_Hard_Case_Inherited_Operational_Attribute_Blocker =>
            return Representation_Generic_RM_Hard_Case_Blocker_Inherited_Operational_Attribute;
         when Representation_Generic_RM_Hard_Case_Generic_Freezing_Blocker =>
            return Representation_Generic_RM_Hard_Case_Blocker_Generic_Freezing;
         when Representation_Generic_RM_Hard_Case_Discriminant_Layout_Blocker =>
            return Representation_Generic_RM_Hard_Case_Blocker_Discriminant_Layout;
         when Representation_Generic_RM_Hard_Case_Controlled_Finalization_Blocker =>
            return Representation_Generic_RM_Hard_Case_Blocker_Controlled_Finalization;
         when Representation_Generic_RM_Hard_Case_Protected_Task_Representation_Blocker =>
            return Representation_Generic_RM_Hard_Case_Blocker_Protected_Task_Representation;
         when Representation_Generic_RM_Hard_Case_Source_Fingerprint_Mismatch =>
            return Representation_Generic_RM_Hard_Case_Blocker_Source_Fingerprint;
         when Representation_Generic_RM_Hard_Case_Substitution_Fingerprint_Mismatch =>
            return Representation_Generic_RM_Hard_Case_Blocker_Substitution_Fingerprint;
         when Representation_Generic_RM_Hard_Case_Multiple_Blockers =>
            return Representation_Generic_RM_Hard_Case_Blocker_Multiple;
         when Representation_Generic_RM_Hard_Case_Indeterminate =>
            return Representation_Generic_RM_Hard_Case_Blocker_Indeterminate;
         when others =>
            return Representation_Generic_RM_Hard_Case_Blocker_None;
      end case;
   end Family_For;

   function Local_Blocker_Count (C : Representation_Generic_RM_Hard_Case_Context) return Natural is
      Result : Natural := 0;
   begin
      if C.Requires_Previous_Representation
        and then (C.Previous_Representation_Row = Previous.No_Representation_Generic_Final_Row
                  or else not Previous.Is_Accepted (C.Previous_Representation_Status))
      then
         Result := Result + 1;
      end if;
      if C.Requires_Overload_RM_Edge
        and then (C.Overload_RM_Edge_Row = Overload_Edges.No_Overload_Generic_RM_Edge_Completion
                  or else not Overload_Edges.Is_Accepted (C.Overload_RM_Edge_Status))
      then
         Result := Result + 1;
      end if;
      if C.Requires_Stabilized_Closure
        and then (C.Stabilized_Closure_Row = Closure.No_Generic_Shared_State_Final_Stabilized_Closure
                  or else not Closure_Accepted (C.Stabilized_Closure_Status))
      then
         Result := Result + 1;
      end if;
      if C.Volatile_Atomic_Clause_Blocker then Result := Result + 1; end if;
      if C.Independent_Component_Blocker then Result := Result + 1; end if;
      if C.Limited_Private_View_Blocker then Result := Result + 1; end if;
      if C.Inherited_Operational_Attribute_Blocker then Result := Result + 1; end if;
      if C.Generic_Freezing_Blocker then Result := Result + 1; end if;
      if C.Discriminant_Layout_Blocker then Result := Result + 1; end if;
      if C.Controlled_Finalization_Blocker then Result := Result + 1; end if;
      if C.Protected_Task_Representation_Blocker then Result := Result + 1; end if;
      if C.Expected_Source_Fingerprint /= 0 and then C.Source_Fingerprint /= C.Expected_Source_Fingerprint then Result := Result + 1; end if;
      if C.Expected_Substitution_Fingerprint /= 0 and then C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then Result := Result + 1; end if;
      return Result;
   end Local_Blocker_Count;

   function Classify (C : Representation_Generic_RM_Hard_Case_Context) return Representation_Generic_RM_Hard_Case_Status is
      Blockers : constant Natural := Local_Blocker_Count (C);
   begin
      if C.Kind = Representation_Generic_RM_Hard_Case_Unknown then
         return Representation_Generic_RM_Hard_Case_Indeterminate;
      elsif Blockers > 1 then
         return Representation_Generic_RM_Hard_Case_Multiple_Blockers;
      elsif C.Volatile_Atomic_Clause_Blocker then
         return Representation_Generic_RM_Hard_Case_Volatile_Atomic_Clause_Blocker;
      elsif C.Independent_Component_Blocker then
         return Representation_Generic_RM_Hard_Case_Independent_Component_Blocker;
      elsif C.Limited_Private_View_Blocker then
         return Representation_Generic_RM_Hard_Case_Limited_Private_View_Blocker;
      elsif C.Inherited_Operational_Attribute_Blocker then
         return Representation_Generic_RM_Hard_Case_Inherited_Operational_Attribute_Blocker;
      elsif C.Generic_Freezing_Blocker then
         return Representation_Generic_RM_Hard_Case_Generic_Freezing_Blocker;
      elsif C.Discriminant_Layout_Blocker then
         return Representation_Generic_RM_Hard_Case_Discriminant_Layout_Blocker;
      elsif C.Controlled_Finalization_Blocker then
         return Representation_Generic_RM_Hard_Case_Controlled_Finalization_Blocker;
      elsif C.Protected_Task_Representation_Blocker then
         return Representation_Generic_RM_Hard_Case_Protected_Task_Representation_Blocker;
      elsif C.Expected_Source_Fingerprint /= 0 and then C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         return Representation_Generic_RM_Hard_Case_Source_Fingerprint_Mismatch;
      elsif C.Expected_Substitution_Fingerprint /= 0 and then C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then
         return Representation_Generic_RM_Hard_Case_Substitution_Fingerprint_Mismatch;
      elsif C.Requires_Previous_Representation and then C.Previous_Representation_Row = Previous.No_Representation_Generic_Final_Row then
         return Representation_Generic_RM_Hard_Case_Missing_Previous_Representation_Row;
      elsif C.Requires_Previous_Representation and then not Previous.Is_Accepted (C.Previous_Representation_Status) then
         return Representation_Generic_RM_Hard_Case_Previous_Representation_Blocker;
      elsif C.Requires_Overload_RM_Edge and then C.Overload_RM_Edge_Row = Overload_Edges.No_Overload_Generic_RM_Edge_Completion then
         return Representation_Generic_RM_Hard_Case_Missing_Overload_RM_Edge_Row;
      elsif C.Requires_Overload_RM_Edge and then not Overload_Edges.Is_Accepted (C.Overload_RM_Edge_Status) then
         return Representation_Generic_RM_Hard_Case_Overload_RM_Edge_Blocker;
      elsif C.Requires_Stabilized_Closure and then C.Stabilized_Closure_Row = Closure.No_Generic_Shared_State_Final_Stabilized_Closure then
         return Representation_Generic_RM_Hard_Case_Missing_Stabilized_Closure_Row;
      elsif C.Requires_Stabilized_Closure and then not Closure_Accepted (C.Stabilized_Closure_Status) then
         return Representation_Generic_RM_Hard_Case_Stabilized_Closure_Blocker;
      else
         return Accepted_For (C.Kind);
      end if;
   end Classify;

   function Message_For
     (Status : Representation_Generic_RM_Hard_Case_Status;
      Kind   : Representation_Generic_RM_Hard_Case_Kind;
      Family : Representation_Generic_RM_Hard_Case_Blocker_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("representation/generic shared-state RM hard-case completion legality " &
         Representation_Generic_RM_Hard_Case_Status'Image (Status) &
         " kind=" & Representation_Generic_RM_Hard_Case_Kind'Image (Kind) &
         " blocker=" & Representation_Generic_RM_Hard_Case_Blocker_Family'Image (Family));
   end Message_For;

   function Compute_Row_Fingerprint (Row : Representation_Generic_RM_Hard_Case_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Context));
      H := Mix (H, Representation_Generic_RM_Hard_Case_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Representation_Generic_RM_Hard_Case_Status'Pos (Row.Status) + 1);
      H := Mix (H, Representation_Generic_RM_Hard_Case_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Blocker_Count);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Compute_Row_Fingerprint;

   function Make_Row (C : Representation_Generic_RM_Hard_Case_Context; Index : Positive) return Representation_Generic_RM_Hard_Case_Row is
      Status : constant Representation_Generic_RM_Hard_Case_Status := Classify (C);
      Family : constant Representation_Generic_RM_Hard_Case_Blocker_Family := Family_For (Status);
      Row : Representation_Generic_RM_Hard_Case_Row;
   begin
      Row.Id := Representation_Generic_RM_Hard_Case_Id (Index);
      Row.Context := C.Id;
      Row.Kind := C.Kind;
      Row.Status := Status;
      Row.Blocker_Family := Family;
      Row.Node := C.Node;
      Row.Representation_Name := C.Representation_Name;
      Row.Type_Name := C.Type_Name;
      Row.State_Name := C.State_Name;
      Row.Generic_Unit_Name := C.Generic_Unit_Name;
      Row.Instance_Name := C.Instance_Name;
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
      Row.Row_Fingerprint := Compute_Row_Fingerprint (Row);
      return Row;
   end Make_Row;

   procedure Clear (Model : in out Representation_Generic_RM_Hard_Case_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model   : in out Representation_Generic_RM_Hard_Case_Context_Model;
      Context : Representation_Generic_RM_Hard_Case_Context) is
   begin
      Model.Items.Append (Context);
      Model.Fingerprint := Mix (Model.Fingerprint, Natural (Context.Id));
      Model.Fingerprint := Mix (Model.Fingerprint, Representation_Generic_RM_Hard_Case_Kind'Pos (Context.Kind) + 1);
      Model.Fingerprint := Mix (Model.Fingerprint, Natural (Context.Node));
      Model.Fingerprint := Mix (Model.Fingerprint, Context.Source_Fingerprint);
      Model.Fingerprint := Mix (Model.Fingerprint, Context.Substitution_Fingerprint);
      Model.Fingerprint := Mix (Model.Fingerprint, Context.Expected_Source_Fingerprint);
      Model.Fingerprint := Mix (Model.Fingerprint, Context.Expected_Substitution_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Representation_Generic_RM_Hard_Case_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At
     (Model : Representation_Generic_RM_Hard_Case_Context_Model;
      Index : Positive) return Representation_Generic_RM_Hard_Case_Context is
   begin
      return Model.Items.Element (Index);
   end Context_At;

   function Context_Fingerprint (Model : Representation_Generic_RM_Hard_Case_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Context_Fingerprint;

   function Build (Contexts : Representation_Generic_RM_Hard_Case_Context_Model) return Representation_Generic_RM_Hard_Case_Model is
      Result : Representation_Generic_RM_Hard_Case_Model;
   begin
      for I in 1 .. Natural (Contexts.Items.Length) loop
         declare
            Row : constant Representation_Generic_RM_Hard_Case_Row := Make_Row (Contexts.Items.Element (I), I);
         begin
            Result.Rows.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Row_Fingerprint);
         end;
      end loop;
      return Result;
   end Build;

   function Count (Model : Representation_Generic_RM_Hard_Case_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : Representation_Generic_RM_Hard_Case_Model;
      Index : Positive) return Representation_Generic_RM_Hard_Case_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Representation_Generic_RM_Hard_Case_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Representation_Generic_RM_Hard_Case_Set;
      Index : Positive) return Representation_Generic_RM_Hard_Case_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   function Query_Status
     (Model  : Representation_Generic_RM_Hard_Case_Model;
      Status : Representation_Generic_RM_Hard_Case_Status) return Representation_Generic_RM_Hard_Case_Set is
      Result : Representation_Generic_RM_Hard_Case_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Query_Status;

   function Query_Blocker_Family
     (Model  : Representation_Generic_RM_Hard_Case_Model;
      Family : Representation_Generic_RM_Hard_Case_Blocker_Family) return Representation_Generic_RM_Hard_Case_Set is
      Result : Representation_Generic_RM_Hard_Case_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Family then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Query_Blocker_Family;

   function Find_By_Node
     (Model : Representation_Generic_RM_Hard_Case_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Representation_Generic_RM_Hard_Case_Set is
      Result : Representation_Generic_RM_Hard_Case_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Find_By_Node;

   function Find_By_Source_Fingerprint
     (Model              : Representation_Generic_RM_Hard_Case_Model;
      Source_Fingerprint : Natural) return Representation_Generic_RM_Hard_Case_Set is
      Result : Representation_Generic_RM_Hard_Case_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Source_Fingerprint then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Find_By_Source_Fingerprint;

   function Count_By_Status
     (Model  : Representation_Generic_RM_Hard_Case_Model;
      Status : Representation_Generic_RM_Hard_Case_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_By_Status;

   function Count_By_Blocker_Family
     (Model  : Representation_Generic_RM_Hard_Case_Model;
      Family : Representation_Generic_RM_Hard_Case_Blocker_Family) return Natural is
   begin
      return Query_Count (Query_Blocker_Family (Model, Family));
   end Count_By_Blocker_Family;

   function Accepted_Count (Model : Representation_Generic_RM_Hard_Case_Model) return Natural is
      Result : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Accepted then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Accepted_Count;

   function Blocked_Count (Model : Representation_Generic_RM_Hard_Case_Model) return Natural is
      Result : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Blocked then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Blocked_Count;

   function Indeterminate_Count (Model : Representation_Generic_RM_Hard_Case_Model) return Natural is
      Result : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Indeterminate (Row.Status) then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Representation_Generic_RM_Hard_Case_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Representation_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
