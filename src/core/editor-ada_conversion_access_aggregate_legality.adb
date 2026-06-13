with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Conversion_Access_Aggregate_Legality is

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Static_Expressions.Static_Value_Status;
   use type Editor.Ada_View_Aware_Compatibility.View_Compatibility_Status;
   use type Semantic_Context_Id;
   use type Semantic_Legality_Status;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 271) + B + 227) mod 1_000_000_007;
   end Mix;

   function Bool_Slot (Value : Boolean) return Natural is
   begin
      if Value then
         return 2;
      else
         return 1;
      end if;
   end Bool_Slot;

   function Safe_Long_Long_Slot (Value : Long_Long_Integer) return Natural is
      M : constant Long_Long_Integer := 1_000_000_007;
      R : Long_Long_Integer := Value mod M;
   begin
      if R < 0 then
         R := R + M;
      end if;
      return Natural (R);
   end Safe_Long_Long_Slot;

   function Kind_Slot (Kind : Semantic_Context_Kind) return Natural is
   begin
      return Semantic_Context_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function Status_Slot (Status : Semantic_Legality_Status) return Natural is
   begin
      return Semantic_Legality_Status'Pos (Status) + 1;
   end Status_Slot;

   function Access_Slot (Kind : Access_Kind) return Natural is
   begin
      return Access_Kind'Pos (Kind) + 1;
   end Access_Slot;

   function Static_Slot
     (Status : Editor.Ada_Static_Expressions.Static_Value_Status) return Natural is
   begin
      return Editor.Ada_Static_Expressions.Static_Value_Status'Pos (Status) + 1;
   end Static_Slot;

   function View_Slot
     (Status : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Status)
      return Natural is
   begin
      return Editor.Ada_View_Aware_Compatibility.View_Compatibility_Status'Pos
        (Status) + 1;
   end View_Slot;

   function Is_Private_View_Status
     (Status : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Status)
      return Boolean is
   begin
      return Status in
        Editor.Ada_View_Aware_Compatibility.View_Compatibility_Private_Partial_View |
        Editor.Ada_View_Aware_Compatibility.View_Compatibility_Private_Full_View |
        Editor.Ada_View_Aware_Compatibility.View_Compatibility_Private_Full_View_Hidden |
        Editor.Ada_View_Aware_Compatibility.View_Compatibility_Cross_Unit_Private_View;
   end Is_Private_View_Status;

   function Is_Limited_View_Status
     (Status : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Status)
      return Boolean is
   begin
      return Status in
        Editor.Ada_View_Aware_Compatibility.View_Compatibility_Limited_Incomplete_View |
        Editor.Ada_View_Aware_Compatibility.View_Compatibility_Limited_Full_View_Hidden;
   end Is_Limited_View_Status;

   function Is_Cross_Unit_Unresolved_View
     (Status : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Status)
      return Boolean is
   begin
      return Status =
        Editor.Ada_View_Aware_Compatibility.View_Compatibility_Cross_Unit_Unresolved;
   end Is_Cross_Unit_Unresolved_View;

   function Is_Compatible_Status (Status : Semantic_Legality_Status) return Boolean is
   begin
      return Status in Semantic_Legality_Legal_Conversion |
        Semantic_Legality_Legal_Qualified_Expression |
        Semantic_Legality_Legal_Access_Conversion |
        Semantic_Legality_Legal_Access_Parameter |
        Semantic_Legality_Legal_Allocator |
        Semantic_Legality_Legal_Aggregate |
        Semantic_Legality_Legal_Container_Aggregate |
        Semantic_Legality_Numeric_Conversion |
        Semantic_Legality_Tagged_Conversion |
        Semantic_Legality_Class_Wide_Conversion |
        Semantic_Legality_Static_Range_Compatible;
   end Is_Compatible_Status;

   function Is_Warning_Status (Status : Semantic_Legality_Status) return Boolean is
   begin
      return Status in Semantic_Legality_Accessibility_Indeterminate |
        Semantic_Legality_Indeterminate;
   end Is_Warning_Status;

   function Is_Error_Status (Status : Semantic_Legality_Status) return Boolean is
   begin
      return Status in Semantic_Legality_Target_Unresolved |
        Semantic_Legality_Operand_Unresolved |
        Semantic_Legality_Incompatible_Type |
        Semantic_Legality_Private_View_Barrier |
        Semantic_Legality_Limited_View_Barrier |
        Semantic_Legality_Cross_Unit_Unresolved_View |
        Semantic_Legality_Static_Range_Violation |
        Semantic_Legality_Null_Exclusion_Violation |
        Semantic_Legality_Access_Kind_Mismatch |
        Semantic_Legality_Illegal_Access_Conversion |
        Semantic_Legality_Allocator_Designated_Subtype_Mismatch |
        Semantic_Legality_Aggregate_Missing_Component |
        Semantic_Legality_Aggregate_Duplicate_Component |
        Semantic_Legality_Aggregate_Component_Type_Mismatch |
        Semantic_Legality_Aggregate_Positional_After_Named |
        Semantic_Legality_Aggregate_Index_Coverage_Error |
        Semantic_Legality_Container_Aggregate_Missing_Aspect |
        Semantic_Legality_Universal_Numeric_Unresolved;
   end Is_Error_Status;

   function Is_Aggregate_Status (Status : Semantic_Legality_Status) return Boolean is
   begin
      return Status in Semantic_Legality_Aggregate_Missing_Component |
        Semantic_Legality_Aggregate_Duplicate_Component |
        Semantic_Legality_Aggregate_Component_Type_Mismatch |
        Semantic_Legality_Aggregate_Positional_After_Named |
        Semantic_Legality_Aggregate_Index_Coverage_Error |
        Semantic_Legality_Container_Aggregate_Missing_Aspect;
   end Is_Aggregate_Status;

   function Is_Access_Kind (Kind : Semantic_Context_Kind) return Boolean is
   begin
      return Kind in Semantic_Context_Access_Conversion |
        Semantic_Context_Access_Parameter |
        Semantic_Context_Allocator |
        Semantic_Context_Null_Assignment;
   end Is_Access_Kind;

   function Is_Aggregate_Kind (Kind : Semantic_Context_Kind) return Boolean is
   begin
      return Kind in Semantic_Context_Aggregate |
        Semantic_Context_Array_Aggregate |
        Semantic_Context_Record_Aggregate |
        Semantic_Context_Container_Aggregate;
   end Is_Aggregate_Kind;

   function Context_Fingerprint (Context : Semantic_Context_Info) return Natural is
      H : Natural := Natural (Context.Id) + 1;
   begin
      H := Mix (H, Kind_Slot (Context.Kind));
      H := Mix (H, Natural (Context.Node) + 1);
      H := Mix (H, Natural (Context.Target_Node) + 1);
      H := Mix (H, Natural (Context.Operand_Node) + 1);
      H := Mix (H, Length (Context.Normalized_Target_Subtype) + 1);
      H := Mix (H, Length (Context.Normalized_Operand_Subtype) + 1);
      H := Mix (H, Access_Slot (Context.Target_Access));
      H := Mix (H, Access_Slot (Context.Operand_Access));
      H := Mix (H, Bool_Slot (Context.Target_Is_Null_Excluding));
      H := Mix (H, Bool_Slot (Context.Operand_Is_Null_Literal));
      H := Mix (H, Bool_Slot (Context.Is_Numeric_Target));
      H := Mix (H, Bool_Slot (Context.Is_Numeric_Operand));
      H := Mix (H, Bool_Slot (Context.Is_Tagged_Target));
      H := Mix (H, Bool_Slot (Context.Is_Tagged_Operand));
      H := Mix (H, Bool_Slot (Context.Target_Is_Class_Wide));
      H := Mix (H, Bool_Slot (Context.Operand_Is_Class_Wide));
      H := Mix (H, Bool_Slot (Context.Operand_Is_Universal_Numeric));
      H := Mix (H, Static_Slot (Context.Operand_Static_Status));
      H := Mix (H, Safe_Long_Long_Slot (Context.Operand_Static_Integer_Value));
      H := Mix (H, Bool_Slot (Context.Target_Has_Static_Range));
      H := Mix (H, Safe_Long_Long_Slot (Context.Target_Static_First));
      H := Mix (H, Safe_Long_Long_Slot (Context.Target_Static_Last));
      H := Mix (H, Bool_Slot (Context.Requires_Accessibility_Check));
      H := Mix (H, Bool_Slot (Context.Accessibility_Known_Compatible));
      H := Mix (H, Context.Aggregate_Component_Count + 1);
      H := Mix (H, Context.Aggregate_Expected_Component_Count + 1);
      H := Mix (H, Bool_Slot (Context.Aggregate_Has_Duplicate_Component));
      H := Mix (H, Bool_Slot (Context.Aggregate_Has_Component_Type_Mismatch));
      H := Mix (H, Bool_Slot (Context.Aggregate_Has_Positional_After_Named));
      H := Mix (H, Bool_Slot (Context.Aggregate_Has_Index_Coverage_Error));
      H := Mix (H, Bool_Slot (Context.Container_Has_Required_Aspect));
      H := Mix (H, View_Slot (Context.View_Status));
      H := Mix (H, Context.Start_Line);
      H := Mix (H, Context.Start_Column);
      H := Mix (H, Context.End_Line);
      H := Mix (H, Context.End_Column);
      return H;
   end Context_Fingerprint;

   function Legality_Fingerprint (Info : Semantic_Legality_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Kind_Slot (Info.Kind));
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Natural (Info.Target_Node) + 1);
      H := Mix (H, Natural (Info.Operand_Node) + 1);
      H := Mix (H, Status_Slot (Info.Status));
      H := Mix (H, Length (Info.Normalized_Target_Subtype) + 1);
      H := Mix (H, Length (Info.Normalized_Operand_Subtype) + 1);
      H := Mix (H, Access_Slot (Info.Target_Access));
      H := Mix (H, Access_Slot (Info.Operand_Access));
      H := Mix (H, View_Slot (Info.View_Status));
      H := Mix (H, Info.Start_Line);
      H := Mix (H, Info.Start_Column);
      H := Mix (H, Info.End_Line);
      H := Mix (H, Info.End_Column);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Legality_Fingerprint;

   function Message_For (Status : Semantic_Legality_Status) return String is
   begin
      case Status is
         when Semantic_Legality_Legal_Conversion =>
            return "conversion is legal";
         when Semantic_Legality_Legal_Qualified_Expression =>
            return "qualified expression is legal";
         when Semantic_Legality_Legal_Access_Conversion =>
            return "access conversion is legal";
         when Semantic_Legality_Legal_Access_Parameter =>
            return "access parameter use is legal";
         when Semantic_Legality_Legal_Allocator =>
            return "allocator designated subtype is legal";
         when Semantic_Legality_Legal_Aggregate =>
            return "aggregate is structurally legal";
         when Semantic_Legality_Legal_Container_Aggregate =>
            return "container aggregate has required semantic support";
         when Semantic_Legality_Numeric_Conversion =>
            return "numeric conversion is legal";
         when Semantic_Legality_Tagged_Conversion =>
            return "tagged conversion is legal";
         when Semantic_Legality_Class_Wide_Conversion =>
            return "class-wide conversion is legal";
         when Semantic_Legality_Static_Range_Compatible =>
            return "static operand value is within target range";
         when Semantic_Legality_Target_Unresolved =>
            return "target subtype is unresolved";
         when Semantic_Legality_Operand_Unresolved =>
            return "operand subtype is unresolved";
         when Semantic_Legality_Incompatible_Type =>
            return "operand type is incompatible with target type";
         when Semantic_Legality_Private_View_Barrier =>
            return "legality is blocked by a private view";
         when Semantic_Legality_Limited_View_Barrier =>
            return "legality is blocked by a limited view";
         when Semantic_Legality_Cross_Unit_Unresolved_View =>
            return "view compatibility is unresolved across units";
         when Semantic_Legality_Static_Range_Violation =>
            return "static operand value is outside target range";
         when Semantic_Legality_Null_Exclusion_Violation =>
            return "null is illegal for a null-excluding access subtype";
         when Semantic_Legality_Access_Kind_Mismatch =>
            return "access-to-object and access-to-subprogram kinds do not match";
         when Semantic_Legality_Accessibility_Indeterminate =>
            return "accessibility check is required but not yet fully resolved";
         when Semantic_Legality_Illegal_Access_Conversion =>
            return "access conversion is illegal";
         when Semantic_Legality_Allocator_Designated_Subtype_Mismatch =>
            return "allocator designated subtype is incompatible";
         when Semantic_Legality_Aggregate_Missing_Component =>
            return "aggregate is missing required components";
         when Semantic_Legality_Aggregate_Duplicate_Component =>
            return "aggregate contains duplicate component associations";
         when Semantic_Legality_Aggregate_Component_Type_Mismatch =>
            return "aggregate component expression type is incompatible";
         when Semantic_Legality_Aggregate_Positional_After_Named =>
            return "aggregate has a positional association after a named association";
         when Semantic_Legality_Aggregate_Index_Coverage_Error =>
            return "array aggregate index coverage is incomplete or inconsistent";
         when Semantic_Legality_Container_Aggregate_Missing_Aspect =>
            return "container aggregate is missing required aggregate aspect support";
         when Semantic_Legality_Universal_Numeric_Unresolved =>
            return "universal numeric operand was not finally resolved";
         when Semantic_Legality_Indeterminate =>
            return "semantic legality is indeterminate";
         when others =>
            return "semantic legality was not checked";
      end case;
   end Message_For;

   function Detail_For (Status : Semantic_Legality_Status) return String is
   begin
      case Status is
         when Semantic_Legality_Accessibility_Indeterminate =>
            return "later accessibility/lifetime analysis must discharge this context";
         when Semantic_Legality_Indeterminate =>
            return "insufficient semantic metadata was available for a final legality decision";
         when others =>
            return Message_For (Status);
      end case;
   end Detail_For;

   function Decide_Status (Context : Semantic_Context_Info) return Semantic_Legality_Status is
   begin
      if Length (Context.Target_Subtype) = 0 and then
        not Is_Aggregate_Kind (Context.Kind)
      then
         return Semantic_Legality_Target_Unresolved;
      elsif Length (Context.Operand_Subtype) = 0 and then
        Context.Kind not in Semantic_Context_Null_Assignment |
          Semantic_Context_Aggregate |
          Semantic_Context_Array_Aggregate |
          Semantic_Context_Record_Aggregate |
          Semantic_Context_Container_Aggregate
      then
         return Semantic_Legality_Operand_Unresolved;
      elsif Is_Private_View_Status (Context.View_Status) then
         return Semantic_Legality_Private_View_Barrier;
      elsif Is_Limited_View_Status (Context.View_Status) then
         return Semantic_Legality_Limited_View_Barrier;
      elsif Is_Cross_Unit_Unresolved_View (Context.View_Status) then
         return Semantic_Legality_Cross_Unit_Unresolved_View;
      elsif Context.Target_Is_Null_Excluding and then Context.Operand_Is_Null_Literal then
         return Semantic_Legality_Null_Exclusion_Violation;
      elsif Context.Operand_Is_Universal_Numeric then
         return Semantic_Legality_Universal_Numeric_Unresolved;
      elsif Context.Target_Has_Static_Range and then
        Context.Operand_Static_Status =
          Editor.Ada_Static_Expressions.Static_Value_Integer
      then
         if Context.Operand_Static_Integer_Value < Context.Target_Static_First or else
           Context.Operand_Static_Integer_Value > Context.Target_Static_Last
         then
            return Semantic_Legality_Static_Range_Violation;
         else
            return Semantic_Legality_Static_Range_Compatible;
         end if;
      elsif Is_Access_Kind (Context.Kind) then
         if Context.Target_Access /= Access_Kind_None and then
           Context.Operand_Access /= Access_Kind_None and then
           Context.Target_Access /= Context.Operand_Access and then
           not (Context.Target_Access = Access_Kind_Object and then
                Context.Operand_Access = Access_Kind_Anonymous_Object) and then
           not (Context.Target_Access = Access_Kind_Subprogram and then
                Context.Operand_Access = Access_Kind_Anonymous_Subprogram)
         then
            return Semantic_Legality_Access_Kind_Mismatch;
         elsif Context.Requires_Accessibility_Check and then
           not Context.Accessibility_Known_Compatible
         then
            return Semantic_Legality_Accessibility_Indeterminate;
         elsif Context.Kind = Semantic_Context_Allocator and then
           Length (Context.Target_Subtype) /= 0 and then
           Length (Context.Operand_Subtype) /= 0 and then
           To_String (Context.Normalized_Target_Subtype) /=
             To_String (Context.Normalized_Operand_Subtype)
         then
            return Semantic_Legality_Allocator_Designated_Subtype_Mismatch;
         elsif Context.Kind = Semantic_Context_Access_Parameter then
            return Semantic_Legality_Legal_Access_Parameter;
         elsif Context.Kind = Semantic_Context_Allocator then
            return Semantic_Legality_Legal_Allocator;
         elsif Context.Kind = Semantic_Context_Null_Assignment then
            return Semantic_Legality_Legal_Access_Conversion;
         else
            return Semantic_Legality_Legal_Access_Conversion;
         end if;
      elsif Is_Aggregate_Kind (Context.Kind) then
         if Context.Kind = Semantic_Context_Container_Aggregate and then
           not Context.Container_Has_Required_Aspect
         then
            return Semantic_Legality_Container_Aggregate_Missing_Aspect;
         elsif Context.Aggregate_Has_Positional_After_Named then
            return Semantic_Legality_Aggregate_Positional_After_Named;
         elsif Context.Aggregate_Has_Duplicate_Component then
            return Semantic_Legality_Aggregate_Duplicate_Component;
         elsif Context.Aggregate_Has_Component_Type_Mismatch then
            return Semantic_Legality_Aggregate_Component_Type_Mismatch;
         elsif Context.Aggregate_Has_Index_Coverage_Error then
            return Semantic_Legality_Aggregate_Index_Coverage_Error;
         elsif Context.Aggregate_Expected_Component_Count > 0 and then
           Context.Aggregate_Component_Count < Context.Aggregate_Expected_Component_Count
         then
            return Semantic_Legality_Aggregate_Missing_Component;
         elsif Context.Kind = Semantic_Context_Container_Aggregate then
            return Semantic_Legality_Legal_Container_Aggregate;
         else
            return Semantic_Legality_Legal_Aggregate;
         end if;
      elsif Context.Is_Numeric_Target and then Context.Is_Numeric_Operand then
         return Semantic_Legality_Numeric_Conversion;
      elsif Context.Target_Is_Class_Wide or else Context.Operand_Is_Class_Wide then
         return Semantic_Legality_Class_Wide_Conversion;
      elsif Context.Is_Tagged_Target and then Context.Is_Tagged_Operand then
         return Semantic_Legality_Tagged_Conversion;
      elsif To_String (Context.Normalized_Target_Subtype) =
        To_String (Context.Normalized_Operand_Subtype)
      then
         if Context.Kind = Semantic_Context_Qualified_Expression then
            return Semantic_Legality_Legal_Qualified_Expression;
         else
            return Semantic_Legality_Legal_Conversion;
         end if;
      elsif Context.Kind = Semantic_Context_Conversion or else
        Context.Kind = Semantic_Context_Qualified_Expression
      then
         return Semantic_Legality_Incompatible_Type;
      else
         return Semantic_Legality_Indeterminate;
      end if;
   end Decide_Status;

   procedure Increment (Model : in out Semantic_Legality_Model; Info : Semantic_Legality_Info) is
   begin
      if Is_Compatible_Status (Info.Status) then
         Model.Compatible_Total := Model.Compatible_Total + 1;
      elsif Is_Error_Status (Info.Status) then
         Model.Error_Total := Model.Error_Total + 1;
      elsif Is_Warning_Status (Info.Status) then
         Model.Warning_Total := Model.Warning_Total + 1;
      end if;

      if Info.Kind in Semantic_Context_Conversion |
        Semantic_Context_Qualified_Expression
      then
         Model.Conversion_Total := Model.Conversion_Total + 1;
      elsif Is_Access_Kind (Info.Kind) then
         Model.Access_Total := Model.Access_Total + 1;
      elsif Is_Aggregate_Kind (Info.Kind) then
         Model.Aggregate_Total := Model.Aggregate_Total + 1;
      end if;

      if Info.Status = Semantic_Legality_Static_Range_Violation then
         Model.Static_Range_Violation_Total :=
           Model.Static_Range_Violation_Total + 1;
      elsif Info.Status = Semantic_Legality_Null_Exclusion_Violation then
         Model.Null_Exclusion_Violation_Total :=
           Model.Null_Exclusion_Violation_Total + 1;
      elsif Info.Status = Semantic_Legality_Access_Kind_Mismatch then
         Model.Access_Kind_Mismatch_Total :=
           Model.Access_Kind_Mismatch_Total + 1;
      elsif Info.Status = Semantic_Legality_Accessibility_Indeterminate then
         Model.Accessibility_Indeterminate_Total :=
           Model.Accessibility_Indeterminate_Total + 1;
      elsif Is_Aggregate_Status (Info.Status) then
         Model.Aggregate_Error_Total := Model.Aggregate_Error_Total + 1;
      elsif Info.Status = Semantic_Legality_Universal_Numeric_Unresolved then
         Model.Universal_Numeric_Unresolved_Total :=
           Model.Universal_Numeric_Unresolved_Total + 1;
      end if;
   end Increment;

   procedure Clear (Model : in out Semantic_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Model_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model   : in out Semantic_Context_Model;
      Context : Semantic_Context_Info)
   is
      Item : Semantic_Context_Info := Context;
      FP   : constant Natural :=
        (if Context.Fingerprint /= 0 then Context.Fingerprint else Context_Fingerprint (Context));
   begin
      Item.Fingerprint := FP;
      if Length (Item.Normalized_Target_Subtype) = 0 then
         Item.Normalized_Target_Subtype := Item.Target_Subtype;
      end if;
      if Length (Item.Normalized_Operand_Subtype) = 0 then
         Item.Normalized_Operand_Subtype := Item.Operand_Subtype;
      end if;
      Model.Items.Append (Item);
      Model.Model_Fingerprint := Mix (Model.Model_Fingerprint, FP + 1);
   end Add_Context;

   function Context_Count (Model : Semantic_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At
     (Model : Semantic_Context_Model;
      Index : Positive) return Semantic_Context_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Context_At;

   function Fingerprint (Model : Semantic_Context_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

   function Build (Contexts : Semantic_Context_Model) return Semantic_Legality_Model is
      Model : Semantic_Legality_Model;
      Next_Id : Natural := 1;
   begin
      for Context of Contexts.Items loop
         declare
            Status : constant Semantic_Legality_Status := Decide_Status (Context);
            Info   : Semantic_Legality_Info;
         begin
            Info.Id := Semantic_Legality_Id (Next_Id);
            Next_Id := Next_Id + 1;
            Info.Context := Context.Id;
            Info.Kind := Context.Kind;
            Info.Node := Context.Node;
            Info.Target_Node := Context.Target_Node;
            Info.Operand_Node := Context.Operand_Node;
            Info.Status := Status;
            Info.Message := To_Unbounded_String (Message_For (Status));
            Info.Detail := To_Unbounded_String (Detail_For (Status));
            Info.Target_Subtype := Context.Target_Subtype;
            Info.Operand_Subtype := Context.Operand_Subtype;
            Info.Normalized_Target_Subtype := Context.Normalized_Target_Subtype;
            Info.Normalized_Operand_Subtype := Context.Normalized_Operand_Subtype;
            Info.Target_Access := Context.Target_Access;
            Info.Operand_Access := Context.Operand_Access;
            Info.View_Status := Context.View_Status;
            Info.Start_Line := Context.Start_Line;
            Info.Start_Column := Context.Start_Column;
            Info.End_Line := Context.End_Line;
            Info.End_Column := Context.End_Column;
            Info.Source_Fingerprint := Context.Fingerprint;
            Info.Fingerprint := Legality_Fingerprint (Info);
            Model.Items.Append (Info);
            Increment (Model, Info);
            Model.Model_Fingerprint := Mix (Model.Model_Fingerprint, Info.Fingerprint + 1);
         end;
      end loop;
      return Model;
   end Build;

   function Legality_Count (Model : Semantic_Legality_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Legality_Count;

   function Legality_At
     (Model : Semantic_Legality_Model;
      Index : Positive) return Semantic_Legality_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Legality_At;

   function First_For_Context
     (Model   : Semantic_Legality_Model;
      Context : Semantic_Context_Id) return Semantic_Legality_Info is
   begin
      for Info of Model.Items loop
         if Info.Context = Context then
            return Info;
         end if;
      end loop;
      return (others => <>);
   end First_For_Context;

   function First_For_Node
     (Model : Semantic_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Semantic_Legality_Info is
   begin
      for Info of Model.Items loop
         if Info.Node = Node then
            return Info;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Results_For_Status
     (Model  : Semantic_Legality_Model;
      Status : Semantic_Legality_Status) return Semantic_Legality_Result_Set is
      Results : Semantic_Legality_Result_Set;
   begin
      for Info of Model.Items loop
         if Info.Status = Status then
            Results.Items.Append (Info);
            Results.Fingerprint := Mix (Results.Fingerprint, Info.Fingerprint + 1);
         end if;
      end loop;
      return Results;
   end Results_For_Status;

   function Rows_For_Kind
     (Model : Semantic_Legality_Model;
      Kind  : Semantic_Context_Kind) return Semantic_Legality_Result_Set is
      Results : Semantic_Legality_Result_Set;
   begin
      for Info of Model.Items loop
         if Info.Kind = Kind then
            Results.Items.Append (Info);
            Results.Fingerprint := Mix (Results.Fingerprint, Info.Fingerprint + 1);
         end if;
      end loop;
      return Results;
   end Rows_For_Kind;

   function Result_Count (Results : Semantic_Legality_Result_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Result_Count;

   function Result_At
     (Results : Semantic_Legality_Result_Set;
      Index   : Positive) return Semantic_Legality_Info is
   begin
      if Index > Natural (Results.Items.Length) then
         return (others => <>);
      end if;
      return Results.Items.Element (Index);
   end Result_At;

   function Count_Status
     (Model  : Semantic_Legality_Model;
      Status : Semantic_Legality_Status) return Natural is
      Total : Natural := 0;
   begin
      for Info of Model.Items loop
         if Info.Status = Status then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_Status;

   function Count_Kind
     (Model : Semantic_Legality_Model;
      Kind  : Semantic_Context_Kind) return Natural is
      Total : Natural := 0;
   begin
      for Info of Model.Items loop
         if Info.Kind = Kind then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_Kind;

   function Compatible_Count (Model : Semantic_Legality_Model) return Natural is
   begin
      return Model.Compatible_Total;
   end Compatible_Count;

   function Error_Count (Model : Semantic_Legality_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : Semantic_Legality_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Conversion_Count (Model : Semantic_Legality_Model) return Natural is
   begin
      return Model.Conversion_Total;
   end Conversion_Count;

   function Access_Count (Model : Semantic_Legality_Model) return Natural is
   begin
      return Model.Access_Total;
   end Access_Count;

   function Aggregate_Count (Model : Semantic_Legality_Model) return Natural is
   begin
      return Model.Aggregate_Total;
   end Aggregate_Count;

   function Static_Range_Violation_Count (Model : Semantic_Legality_Model) return Natural is
   begin
      return Model.Static_Range_Violation_Total;
   end Static_Range_Violation_Count;

   function Null_Exclusion_Violation_Count (Model : Semantic_Legality_Model) return Natural is
   begin
      return Model.Null_Exclusion_Violation_Total;
   end Null_Exclusion_Violation_Count;

   function Access_Kind_Mismatch_Count (Model : Semantic_Legality_Model) return Natural is
   begin
      return Model.Access_Kind_Mismatch_Total;
   end Access_Kind_Mismatch_Count;

   function Accessibility_Indeterminate_Count (Model : Semantic_Legality_Model) return Natural is
   begin
      return Model.Accessibility_Indeterminate_Total;
   end Accessibility_Indeterminate_Count;

   function Aggregate_Error_Count (Model : Semantic_Legality_Model) return Natural is
   begin
      return Model.Aggregate_Error_Total;
   end Aggregate_Error_Count;

   function Universal_Numeric_Unresolved_Count (Model : Semantic_Legality_Model) return Natural is
   begin
      return Model.Universal_Numeric_Unresolved_Total;
   end Universal_Numeric_Unresolved_Count;

   function Has_Legality (Info : Semantic_Legality_Info) return Boolean is
   begin
      return Info.Id /= No_Semantic_Legality;
   end Has_Legality;

   function Fingerprint (Model : Semantic_Legality_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

end Editor.Ada_Conversion_Access_Aggregate_Legality;
