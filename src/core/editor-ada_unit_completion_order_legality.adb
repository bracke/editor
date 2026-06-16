with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Unit_Completion_Order_Legality is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Syntax_Tree.Node_Id;

   Modulus : constant Natural := 2 ** 30 - 35;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 131 + Right * 17 + 113) mod Modulus;
   end Mix;

   function Kind_Slot (Kind : Unit_Completion_Kind) return Natural is
   begin
      return Unit_Completion_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function Subject_Slot (Subject : Completion_Subject_Kind) return Natural is
   begin
      return Completion_Subject_Kind'Pos (Subject) + 1;
   end Subject_Slot;

   function Relation_Slot (Relation : Completion_Relation_State) return Natural is
   begin
      return Completion_Relation_State'Pos (Relation) + 1;
   end Relation_Slot;

   function Order_Slot (Order : Completion_Order_State) return Natural is
   begin
      return Completion_Order_State'Pos (Order) + 1;
   end Order_Slot;

   function Visibility_Slot (Visibility : Completion_Visibility_State) return Natural is
   begin
      return Completion_Visibility_State'Pos (Visibility) + 1;
   end Visibility_Slot;

   function Status_Slot (Status : Completion_Legality_Status) return Natural is
   begin
      return Completion_Legality_Status'Pos (Status) + 1;
   end Status_Slot;

   function Is_Legal_Status (Status : Completion_Legality_Status) return Boolean is
   begin
      return Status in
        Completion_Legality_Legal_Unit_Body |
        Completion_Legality_Legal_Subprogram_Body |
        Completion_Legality_Legal_Task_Body |
        Completion_Legality_Legal_Protected_Body |
        Completion_Legality_Legal_Generic_Body |
        Completion_Legality_Legal_Private_Type_Completion |
        Completion_Legality_Legal_Deferred_Constant_Completion |
        Completion_Legality_Legal_Incomplete_Type_Completion |
        Completion_Legality_Legal_Body_Stub_Completion |
        Completion_Legality_Legal_Declaration_Order;
   end Is_Legal_Status;

   function Is_Completion_Error (Status : Completion_Legality_Status) return Boolean is
   begin
      return Status in
        Completion_Legality_Private_Type_Not_Completed |
        Completion_Legality_Private_Extension_Not_Completed |
        Completion_Legality_Deferred_Constant_Not_Completed |
        Completion_Legality_Incomplete_Type_Not_Completed |
        Completion_Legality_Body_Stub_Not_Completed |
        Completion_Legality_Use_Before_Completion |
        Completion_Legality_Frozen_Before_Completion;
   end Is_Completion_Error;

   function Is_Body_Error (Status : Completion_Legality_Status) return Boolean is
   begin
      return Status in
        Completion_Legality_Missing_Body |
        Completion_Legality_Duplicate_Body |
        Completion_Legality_Ambiguous_Body |
        Completion_Legality_Body_Kind_Mismatch |
        Completion_Legality_Profile_Mismatch |
        Completion_Legality_Mode_Mismatch |
        Completion_Legality_Result_Mismatch |
        Completion_Legality_Generic_Formal_Mismatch |
        Completion_Legality_Separate_Parent_Missing |
        Completion_Legality_Separate_Parent_Ambiguous |
        Completion_Legality_Body_Before_Spec;
   end Is_Body_Error;

   function Is_Order_Error (Status : Completion_Legality_Status) return Boolean is
   begin
      return Status in
        Completion_Legality_Body_Before_Spec |
        Completion_Legality_Use_Before_Declaration |
        Completion_Legality_Use_Before_Full_View |
        Completion_Legality_Use_Before_Completion |
        Completion_Legality_Frozen_Before_Completion |
        Completion_Legality_Private_Part_Order_Error;
   end Is_Order_Error;

   function Is_View_Barrier (Status : Completion_Legality_Status) return Boolean is
   begin
      return Status in
        Completion_Legality_Limited_View_Barrier |
        Completion_Legality_Private_View_Barrier;
   end Is_View_Barrier;

   function Is_Linked_Error (Status : Completion_Legality_Status) return Boolean is
   begin
      return Status in
        Completion_Legality_Linked_Cross_Unit_Error |
        Completion_Legality_Linked_Contract_Error |
        Completion_Legality_Linked_Elaboration_Error |
        Completion_Legality_Linked_Generic_Instance_Error |
        Completion_Legality_Linked_Accessibility_Error;
   end Is_Linked_Error;

   function Cross_Unit_Error (Status : Cross_Unit_Semantic_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Not_Checked |
        Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Closed |
        Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Local_Only |
        Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_With_Visible |
        Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Use_Visible;
   end Cross_Unit_Error;

   function Contract_Error (Status : Contract_Legality_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Not_Checked |
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Legal_Precondition |
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Legal_Postcondition |
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Legal_Invariant |
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Legal_Predicate |
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Legal_Assertion |
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Legal_Contract_Case |
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Legal_Flow_Aspect;
   end Contract_Error;

   function Elaboration_Error (Status : Elaboration_Legality_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Not_Checked |
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Legal_Dependency |
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Legal_Elaborate_Pragma |
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Legal_Elaborate_All_Pragma |
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Legal_Elaborate_Body_Pragma |
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Legal_Preelaborate |
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Legal_Pure |
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Legal_Body_Before_Use |
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Legal_Generic_Instance;
   end Elaboration_Error;

   function Instance_Error (Status : Instance_Legality_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Not_Checked |
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Legal_Instance |
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Legal_Body_Substitution |
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Legal_Default_Substitution |
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Legal_Formal_Package_Substitution |
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Legal_Boxed_Formal_Package |
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Legal_Instance_Freezing |
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Legal_Representation_Item;
   end Instance_Error;

   function Accessibility_Error (Status : Accessibility_Legality_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Not_Checked |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Static_Compatible |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Dynamic_Check_Required |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Null_Exclusion_Checked |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Aliased_Object_Compatible |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Allocator_Compatible |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Access_Conversion_Compatible |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Return_Access_Compatible;
   end Accessibility_Error;

   function Classify (Info : Completion_Context_Info) return Completion_Legality_Status is
   begin
      if Cross_Unit_Error (Info.Cross_Unit_Status) then
         return Completion_Legality_Linked_Cross_Unit_Error;
      elsif Contract_Error (Info.Contract_Status) then
         return Completion_Legality_Linked_Contract_Error;
      elsif Elaboration_Error (Info.Elaboration_Status) then
         return Completion_Legality_Linked_Elaboration_Error;
      elsif Instance_Error (Info.Instance_Status) then
         return Completion_Legality_Linked_Generic_Instance_Error;
      elsif Accessibility_Error (Info.Accessibility_Status) then
         return Completion_Legality_Linked_Accessibility_Error;
      elsif Info.Visibility = Completion_Visibility_Limited_View then
         return Completion_Legality_Limited_View_Barrier;
      elsif Info.Visibility = Completion_Visibility_Private_View
        and then Info.Kind /= Completion_Context_Private_Type_Completion
        and then Info.Kind /= Completion_Context_Private_Extension_Completion
      then
         return Completion_Legality_Private_View_Barrier;
      elsif Info.Visibility = Completion_Visibility_Missing then
         return Completion_Legality_Missing_Visible_Declaration;
      elsif Info.Visibility = Completion_Visibility_Ambiguous then
         return Completion_Legality_Ambiguous_Visible_Declaration;
      elsif Info.Duplicate_Body or else Info.Relation = Completion_Relation_Duplicate_Body then
         return Completion_Legality_Duplicate_Body;
      elsif Info.Ambiguous_Body or else Info.Relation = Completion_Relation_Ambiguous_Body then
         return Completion_Legality_Ambiguous_Body;
      elsif Info.Body_Kind_Mismatch or else Info.Relation = Completion_Relation_Kind_Mismatch then
         return Completion_Legality_Body_Kind_Mismatch;
      elsif Info.Profile_Mismatch or else Info.Relation = Completion_Relation_Profile_Mismatch then
         return Completion_Legality_Profile_Mismatch;
      elsif Info.Mode_Mismatch or else Info.Relation = Completion_Relation_Mode_Mismatch then
         return Completion_Legality_Mode_Mismatch;
      elsif Info.Result_Mismatch or else Info.Relation = Completion_Relation_Result_Mismatch then
         return Completion_Legality_Result_Mismatch;
      elsif Info.Generic_Formal_Mismatch
        or else Info.Relation = Completion_Relation_Generic_Formal_Mismatch
      then
         return Completion_Legality_Generic_Formal_Mismatch;
      elsif Info.Separate_Body
        and then Info.Relation = Completion_Relation_Separate_Parent_Missing
      then
         return Completion_Legality_Separate_Parent_Missing;
      elsif Info.Separate_Body
        and then Info.Relation = Completion_Relation_Separate_Parent_Ambiguous
      then
         return Completion_Legality_Separate_Parent_Ambiguous;
      elsif Info.Requires_Body and then not Info.Body_Present then
         return Completion_Legality_Missing_Body;
      elsif Info.Requires_Completion and then not Info.Completion_Present then
         if Info.Private_Extension then
            return Completion_Legality_Private_Extension_Not_Completed;
         elsif Info.Private_Type then
            return Completion_Legality_Private_Type_Not_Completed;
         elsif Info.Deferred_Constant then
            return Completion_Legality_Deferred_Constant_Not_Completed;
         elsif Info.Incomplete_Type then
            return Completion_Legality_Incomplete_Type_Not_Completed;
         elsif Info.Body_Stub then
            return Completion_Legality_Body_Stub_Not_Completed;
         else
            return Completion_Legality_Use_Before_Completion;
         end if;
      elsif Info.Frozen_Before_Completion
        or else Info.Order = Completion_Order_Frozen_Before_Completion
      then
         return Completion_Legality_Frozen_Before_Completion;
      elsif Info.Order = Completion_Order_Body_Before_Spec then
         return Completion_Legality_Body_Before_Spec;
      elsif Info.Order = Completion_Order_Use_Before_Declaration then
         return Completion_Legality_Use_Before_Declaration;
      elsif Info.Order = Completion_Order_Use_Before_Full_View then
         return Completion_Legality_Use_Before_Full_View;
      elsif Info.Order = Completion_Order_Use_Before_Completion then
         return Completion_Legality_Use_Before_Completion;
      elsif Info.Order = Completion_Order_Full_View_Before_Private_View then
         return Completion_Legality_Private_Part_Order_Error;
      end if;

      case Info.Kind is
         when Completion_Context_Package_Body =>
            return Completion_Legality_Legal_Unit_Body;
         when Completion_Context_Subprogram_Body =>
            return Completion_Legality_Legal_Subprogram_Body;
         when Completion_Context_Task_Body =>
            return Completion_Legality_Legal_Task_Body;
         when Completion_Context_Protected_Body =>
            return Completion_Legality_Legal_Protected_Body;
         when Completion_Context_Generic_Body =>
            return Completion_Legality_Legal_Generic_Body;
         when Completion_Context_Private_Type_Completion |
              Completion_Context_Private_Extension_Completion =>
            return Completion_Legality_Legal_Private_Type_Completion;
         when Completion_Context_Deferred_Constant_Completion =>
            return Completion_Legality_Legal_Deferred_Constant_Completion;
         when Completion_Context_Incomplete_Type_Completion =>
            return Completion_Legality_Legal_Incomplete_Type_Completion;
         when Completion_Context_Body_Stub_Completion |
              Completion_Context_Separate_Body_Completion =>
            return Completion_Legality_Legal_Body_Stub_Completion;
         when Completion_Context_Declaration_Before_Use |
              Completion_Context_Private_Part_Ordering |
              Completion_Context_Body_Declaration_Order =>
            return Completion_Legality_Legal_Declaration_Order;
         when Completion_Context_Unknown =>
            return Completion_Legality_Indeterminate;
      end case;
   end Classify;

   function Message_For (Status : Completion_Legality_Status) return String is
   begin
      case Status is
         when Completion_Legality_Legal_Unit_Body => return "unit body completion is legal";
         when Completion_Legality_Legal_Subprogram_Body => return "subprogram body completion is legal";
         when Completion_Legality_Legal_Task_Body => return "task body completion is legal";
         when Completion_Legality_Legal_Protected_Body => return "protected body completion is legal";
         when Completion_Legality_Legal_Generic_Body => return "generic body completion is legal";
         when Completion_Legality_Legal_Private_Type_Completion => return "private type completion is legal";
         when Completion_Legality_Legal_Deferred_Constant_Completion => return "deferred constant completion is legal";
         when Completion_Legality_Legal_Incomplete_Type_Completion => return "incomplete type completion is legal";
         when Completion_Legality_Legal_Body_Stub_Completion => return "body stub completion is legal";
         when Completion_Legality_Legal_Declaration_Order => return "declaration order is legal";
         when Completion_Legality_Missing_Body => return "required body is missing";
         when Completion_Legality_Duplicate_Body => return "duplicate body completion";
         when Completion_Legality_Ambiguous_Body => return "ambiguous body completion";
         when Completion_Legality_Body_Kind_Mismatch => return "body kind does not match declaration";
         when Completion_Legality_Profile_Mismatch => return "body profile does not conform to declaration";
         when Completion_Legality_Mode_Mismatch => return "body parameter mode does not conform";
         when Completion_Legality_Result_Mismatch => return "body result subtype does not conform";
         when Completion_Legality_Generic_Formal_Mismatch => return "generic body formals do not conform";
         when Completion_Legality_Private_Type_Not_Completed => return "private type lacks full completion";
         when Completion_Legality_Private_Extension_Not_Completed => return "private extension lacks full completion";
         when Completion_Legality_Deferred_Constant_Not_Completed => return "deferred constant lacks completion";
         when Completion_Legality_Incomplete_Type_Not_Completed => return "incomplete type lacks completion";
         when Completion_Legality_Body_Stub_Not_Completed => return "body stub lacks separate body";
         when Completion_Legality_Separate_Parent_Missing => return "separate body parent is missing";
         when Completion_Legality_Separate_Parent_Ambiguous => return "separate body parent is ambiguous";
         when Completion_Legality_Body_Before_Spec => return "body appears before required declaration";
         when Completion_Legality_Use_Before_Declaration => return "entity is used before declaration";
         when Completion_Legality_Use_Before_Full_View => return "entity is used before full view";
         when Completion_Legality_Use_Before_Completion => return "entity is used before completion";
         when Completion_Legality_Frozen_Before_Completion => return "entity is frozen before completion";
         when Completion_Legality_Private_Part_Order_Error => return "private part ordering is illegal";
         when Completion_Legality_Limited_View_Barrier => return "limited view prevents completion legality";
         when Completion_Legality_Private_View_Barrier => return "private view prevents completion legality";
         when Completion_Legality_Missing_Visible_Declaration => return "visible declaration is missing";
         when Completion_Legality_Ambiguous_Visible_Declaration => return "visible declaration is ambiguous";
         when Completion_Legality_Linked_Cross_Unit_Error => return "cross-unit semantic closure blocks completion legality";
         when Completion_Legality_Linked_Contract_Error => return "contract/aspect legality blocks completion legality";
         when Completion_Legality_Linked_Elaboration_Error => return "elaboration legality blocks completion legality";
         when Completion_Legality_Linked_Generic_Instance_Error => return "generic-instance legality blocks completion legality";
         when Completion_Legality_Linked_Accessibility_Error => return "accessibility legality blocks completion legality";
         when Completion_Legality_Indeterminate => return "completion legality is indeterminate";
         when Completion_Legality_Not_Checked => return "completion legality was not checked";
      end case;
   end Message_For;

   function Detail_For (Info : Completion_Context_Info; Status : Completion_Legality_Status) return String is
      pragma Unreferenced (Info);
   begin
      return "unit completion/order status " & Completion_Legality_Status'Image (Status);
   end Detail_For;

   function Row_Fingerprint (Row : Completion_Legality_Info) return Natural is
      Value : Natural := Status_Slot (Row.Status);
   begin
      Value := Mix (Value, Natural (Row.Context));
      Value := Mix (Value, Kind_Slot (Row.Kind));
      Value := Mix (Value, Subject_Slot (Row.Subject));
      Value := Mix (Value, Relation_Slot (Row.Relation));
      Value := Mix (Value, Order_Slot (Row.Order));
      Value := Mix (Value, Visibility_Slot (Row.Visibility));
      Value := Mix (Value, Natural (Row.Node));
      Value := Mix (Value, Natural (Row.Spec_Node));
      Value := Mix (Value, Natural (Row.Body_Node));
      Value := Mix (Value, Natural (Row.Declaration_Node));
      Value := Mix (Value, Natural (Row.Completion_Node));
      Value := Mix (Value, Row.Start_Line);
      Value := Mix (Value, Row.Start_Column);
      Value := Mix (Value, Row.End_Line);
      Value := Mix (Value, Row.End_Column);
      Value := Mix (Value, Row.Source_Fingerprint);
      return Value;
   end Row_Fingerprint;

   procedure Clear (Model : in out Completion_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Completion_Context_Model;
      Info  : Completion_Context_Info)
   is
      Value : Natural := Model.Fingerprint;
   begin
      Model.Contexts.Append (Info);
      Value := Mix (Value, Natural (Info.Id));
      Value := Mix (Value, Kind_Slot (Info.Kind));
      Value := Mix (Value, Subject_Slot (Info.Subject));
      Value := Mix (Value, Relation_Slot (Info.Relation));
      Value := Mix (Value, Order_Slot (Info.Order));
      Value := Mix (Value, Visibility_Slot (Info.Visibility));
      Value := Mix (Value, Natural (Info.Node));
      Value := Mix (Value, Info.Source_Fingerprint);
      Model.Fingerprint := Value;
   end Add_Context;

   function Context_Count (Model : Completion_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Completion_Context_Model;
      Index : Positive) return Completion_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Completion_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Build (Contexts : Completion_Context_Model) return Completion_Legality_Model is
      Result : Completion_Legality_Model;
      Next   : Natural := 1;
   begin
      for Info of Contexts.Contexts loop
         declare
            Status : constant Completion_Legality_Status := Classify (Info);
            Row    : Completion_Legality_Info;
         begin
            Row.Id := Completion_Legality_Id (Next);
            Row.Context := Info.Id;
            Row.Kind := Info.Kind;
            Row.Subject := Info.Subject;
            Row.Relation := Info.Relation;
            Row.Order := Info.Order;
            Row.Visibility := Info.Visibility;
            Row.Node := Info.Node;
            Row.Spec_Node := Info.Spec_Node;
            Row.Body_Node := Info.Body_Node;
            Row.Declaration_Node := Info.Declaration_Node;
            Row.Completion_Node := Info.Completion_Node;
            Row.Use_Node := Info.Use_Node;
            Row.Parent_Node := Info.Parent_Node;
            Row.Name := Info.Name;
            Row.Normalized_Name := Info.Normalized_Name;
            Row.Status := Status;
            Row.Message := To_Unbounded_String (Message_For (Status));
            Row.Detail := To_Unbounded_String (Detail_For (Info, Status));
            Row.Cross_Unit_Status := Info.Cross_Unit_Status;
            Row.Contract_Status := Info.Contract_Status;
            Row.Elaboration_Status := Info.Elaboration_Status;
            Row.Instance_Status := Info.Instance_Status;
            Row.Accessibility_Status := Info.Accessibility_Status;
            Row.Start_Line := Info.Start_Line;
            Row.Start_Column := Info.Start_Column;
            Row.End_Line := Info.End_Line;
            Row.End_Column := Info.End_Column;
            Row.Source_Fingerprint := Info.Source_Fingerprint;
            Row.Fingerprint := Row_Fingerprint (Row);
            Result.Rows.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
            Next := Next + 1;
         end;
      end loop;
      return Result;
   end Build;

   function Legality_Count (Model : Completion_Legality_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Legality_Count;

   function Legality_At
     (Model : Completion_Legality_Model;
      Index : Positive) return Completion_Legality_Info is
   begin
      return Model.Rows.Element (Index);
   end Legality_At;

   function First_For_Node
     (Model : Completion_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Completion_Legality_Info is
   begin
      for Row of Model.Rows loop
         if Row.Node = Node
           or else Row.Spec_Node = Node
           or else Row.Body_Node = Node
           or else Row.Declaration_Node = Node
           or else Row.Completion_Node = Node
           or else Row.Use_Node = Node
         then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Completion_Legality_Model;
      Status : Completion_Legality_Status) return Completion_Result_Set is
      Result : Completion_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result.Results.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Completion_Legality_Model;
      Kind  : Unit_Completion_Kind) return Completion_Result_Set is
      Result : Completion_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Result.Results.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Kind;

   function Rows_For_Subject
     (Model   : Completion_Legality_Model;
      Subject : Completion_Subject_Kind) return Completion_Result_Set is
      Result : Completion_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Subject = Subject then
            Result.Results.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Subject;

   function Rows_For_Relation
     (Model    : Completion_Legality_Model;
      Relation : Completion_Relation_State) return Completion_Result_Set is
      Result : Completion_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Relation = Relation then
            Result.Results.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Relation;

   function Rows_For_Order
     (Model : Completion_Legality_Model;
      Order : Completion_Order_State) return Completion_Result_Set is
      Result : Completion_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Order = Order then
            Result.Results.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Order;

   function Rows_For_Visibility
     (Model      : Completion_Legality_Model;
      Visibility : Completion_Visibility_State) return Completion_Result_Set is
      Result : Completion_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Visibility = Visibility then
            Result.Results.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Visibility;

   function Rows_For_Name
     (Model : Completion_Legality_Model;
      Name  : Ada.Strings.Unbounded.Unbounded_String) return Completion_Result_Set is
      Result : Completion_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Normalized_Name = Name or else Row.Name = Name then
            Result.Results.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Name;

   function Result_Count (Set : Completion_Result_Set) return Natural is
   begin
      return Natural (Set.Results.Length);
   end Result_Count;

   function Result_At
     (Set   : Completion_Result_Set;
      Index : Positive) return Completion_Legality_Info is
   begin
      return Set.Results.Element (Index);
   end Result_At;

   function Legal_Count (Model : Completion_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Legal_Status (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Legal_Count;

   function Error_Count (Model : Completion_Legality_Model) return Natural is
   begin
      return Legality_Count (Model) - Legal_Count (Model);
   end Error_Count;

   function Completion_Error_Count (Model : Completion_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Completion_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Completion_Error_Count;

   function Body_Error_Count (Model : Completion_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Body_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Body_Error_Count;

   function Order_Error_Count (Model : Completion_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Order_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Order_Error_Count;

   function View_Barrier_Count (Model : Completion_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_View_Barrier (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end View_Barrier_Count;

   function Linked_Error_Count (Model : Completion_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Linked_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Linked_Error_Count;

   function Indeterminate_Count (Model : Completion_Legality_Model) return Natural is
   begin
      return Count_Status (Model, Completion_Legality_Indeterminate);
   end Indeterminate_Count;

   function Count_Status
     (Model  : Completion_Legality_Model;
      Status : Completion_Legality_Status) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind
     (Model : Completion_Legality_Model;
      Kind  : Unit_Completion_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Count_Subject
     (Model   : Completion_Legality_Model;
      Subject : Completion_Subject_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Subject = Subject then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Subject;

   function Count_Relation
     (Model    : Completion_Legality_Model;
      Relation : Completion_Relation_State) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Relation = Relation then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Relation;

   function Count_Order
     (Model : Completion_Legality_Model;
      Order : Completion_Order_State) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Order = Order then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Order;

   function Count_Visibility
     (Model      : Completion_Legality_Model;
      Visibility : Completion_Visibility_State) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Visibility = Visibility then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Visibility;

   function Fingerprint (Model : Completion_Legality_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Unit_Completion_Order_Legality;
