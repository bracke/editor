with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Assignment_Legality is

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Expression_Types.Expression_Type_Id;
   use type Editor.Ada_Expression_Types.Expression_Type_Status;
   use type Editor.Ada_Static_Expressions.Static_Value_Status;
   use type Editor.Ada_Subtype_Compatibility.Compatibility_Status;
   use type Editor.Ada_View_Aware_Compatibility.View_Compatibility_Status;
   use type Editor.Ada_View_Aware_Compatibility.View_Compatibility_Id;
   use type Assignment_Context_Id;
   use type Assignment_Legality_Status;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 263) + B + 211) mod 1_000_000_007;
   end Mix;

   function Status_Slot (Status : Assignment_Legality_Status) return Natural is
   begin
      return Assignment_Legality_Status'Pos (Status) + 1;
   end Status_Slot;

   function Context_Kind_Slot (Kind : Assignment_Context_Kind) return Natural is
   begin
      return Assignment_Context_Kind'Pos (Kind) + 1;
   end Context_Kind_Slot;

   function Target_Mode_Slot (Mode : Assignment_Target_Mode) return Natural is
   begin
      return Assignment_Target_Mode'Pos (Mode) + 1;
   end Target_Mode_Slot;

   function Compatibility_Slot
     (Status : Editor.Ada_Subtype_Compatibility.Compatibility_Status)
      return Natural is
   begin
      return Editor.Ada_Subtype_Compatibility.Compatibility_Status'Pos (Status) + 1;
   end Compatibility_Slot;

   function View_Slot
     (Status : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Status)
      return Natural is
   begin
      return Editor.Ada_View_Aware_Compatibility.View_Compatibility_Status'Pos (Status) + 1;
   end View_Slot;

   function Static_Slot
     (Status : Editor.Ada_Static_Expressions.Static_Value_Status) return Natural is
   begin
      return Editor.Ada_Static_Expressions.Static_Value_Status'Pos (Status) + 1;
   end Static_Slot;

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

   function Context_Fingerprint (Context : Assignment_Context_Info) return Natural is
      H : Natural := Natural (Context.Id) + 1;
   begin
      H := Mix (H, Context_Kind_Slot (Context.Kind));
      H := Mix (H, Natural (Context.Target_Node) + 1);
      H := Mix (H, Natural (Context.Source_Node) + 1);
      H := Mix (H, Natural (Context.Source_Expression) + 1);
      H := Mix (H, Target_Mode_Slot (Context.Target_Mode));
      H := Mix (H, Length (Context.Normalized_Target_Subtype) + 1);
      H := Mix (H, Length (Context.Normalized_Source_Subtype) + 1);
      H := Mix (H, Bool_Slot (Context.Target_Is_Null_Excluding));
      H := Mix (H, Bool_Slot (Context.Target_Is_Class_Wide));
      H := Mix (H, Bool_Slot (Context.Source_Is_Class_Wide));
      H := Mix (H, Bool_Slot (Context.Source_Is_Null_Literal));
      H := Mix (H, Bool_Slot (Context.Source_Is_Universal_Numeric));
      H := Mix (H, Static_Slot (Context.Source_Static_Status));
      H := Mix (H, Safe_Long_Long_Slot (Context.Source_Static_Integer_Value));
      H := Mix (H, Bool_Slot (Context.Target_Has_Static_Range));
      H := Mix (H, Safe_Long_Long_Slot (Context.Target_Static_First));
      H := Mix (H, Safe_Long_Long_Slot (Context.Target_Static_Last));
      H := Mix (H, Context.Start_Line);
      H := Mix (H, Context.Start_Column);
      H := Mix (H, Context.End_Line);
      H := Mix (H, Context.End_Column);
      return H;
   end Context_Fingerprint;

   function Legality_Fingerprint (Info : Assignment_Legality_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Context_Kind_Slot (Info.Kind));
      H := Mix (H, Natural (Info.Target_Node) + 1);
      H := Mix (H, Natural (Info.Source_Node) + 1);
      H := Mix (H, Natural (Info.Source_Expression) + 1);
      H := Mix (H, Target_Mode_Slot (Info.Target_Mode));
      H := Mix (H, Status_Slot (Info.Status));
      H := Mix (H, Length (Info.Normalized_Target_Subtype) + 1);
      H := Mix (H, Length (Info.Normalized_Source_Subtype) + 1);
      H := Mix (H, Compatibility_Slot (Info.Subtype_Status));
      H := Mix (H, View_Slot (Info.View_Status));
      H := Mix (H, Bool_Slot (Info.Target_Is_Null_Excluding));
      H := Mix (H, Bool_Slot (Info.Target_Is_Class_Wide));
      H := Mix (H, Bool_Slot (Info.Source_Is_Class_Wide));
      H := Mix (H, Bool_Slot (Info.Source_Is_Null_Literal));
      H := Mix (H, Bool_Slot (Info.Source_Is_Universal_Numeric));
      H := Mix (H, Static_Slot (Info.Source_Static_Status));
      H := Mix (H, Safe_Long_Long_Slot (Info.Source_Static_Integer_Value));
      H := Mix (H, Bool_Slot (Info.Target_Has_Static_Range));
      H := Mix (H, Safe_Long_Long_Slot (Info.Target_Static_First));
      H := Mix (H, Safe_Long_Long_Slot (Info.Target_Static_Last));
      H := Mix (H, Info.Start_Line);
      H := Mix (H, Info.Start_Column);
      H := Mix (H, Info.End_Line);
      H := Mix (H, Info.End_Column);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Legality_Fingerprint;

   function Is_Compatible_Status (Status : Assignment_Legality_Status) return Boolean is
   begin
      return Status in Assignment_Legality_Compatible |
        Assignment_Legality_Class_Wide_Compatible |
        Assignment_Legality_Static_Range_Compatible;
   end Is_Compatible_Status;

   function Is_Error_Status (Status : Assignment_Legality_Status) return Boolean is
   begin
      return Status in Assignment_Legality_Incompatible_Subtype |
        Assignment_Legality_Class_Wide_Incompatible |
        Assignment_Legality_Target_Unresolved |
        Assignment_Legality_Source_Unresolved |
        Assignment_Legality_Private_View_Barrier |
        Assignment_Legality_Limited_View_Barrier |
        Assignment_Legality_Cross_Unit_Unresolved_View |
        Assignment_Legality_Assignment_To_Constant |
        Assignment_Legality_Assignment_To_In_Formal |
        Assignment_Legality_Null_Exclusion_Violation |
        Assignment_Legality_Static_Range_Violation |
        Assignment_Legality_Universal_Numeric_Unresolved;
   end Is_Error_Status;

   function Is_Warning_Status (Status : Assignment_Legality_Status) return Boolean is
   begin
      return Status = Assignment_Legality_Indeterminate;
   end Is_Warning_Status;

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

   function Message_For (Status : Assignment_Legality_Status) return String is
   begin
      case Status is
         when Assignment_Legality_Compatible =>
            return "assignment source is compatible with target subtype";
         when Assignment_Legality_Class_Wide_Compatible =>
            return "assignment is class-wide compatible";
         when Assignment_Legality_Static_Range_Compatible =>
            return "static assignment value is within target range";
         when Assignment_Legality_Incompatible_Subtype =>
            return "assignment source subtype is incompatible with target subtype";
         when Assignment_Legality_Class_Wide_Incompatible =>
            return "class-wide assignment is incompatible";
         when Assignment_Legality_Target_Unresolved =>
            return "assignment target subtype is unresolved";
         when Assignment_Legality_Source_Unresolved =>
            return "assignment source expression type is unresolved";
         when Assignment_Legality_Private_View_Barrier =>
            return "assignment legality is blocked by a private view";
         when Assignment_Legality_Limited_View_Barrier =>
            return "assignment legality is blocked by a limited view";
         when Assignment_Legality_Cross_Unit_Unresolved_View =>
            return "assignment view compatibility is unresolved across units";
         when Assignment_Legality_Assignment_To_Constant =>
            return "assignment target is a constant";
         when Assignment_Legality_Assignment_To_In_Formal =>
            return "assignment target is an in-mode formal";
         when Assignment_Legality_Null_Exclusion_Violation =>
            return "null assigned to a null-excluding access subtype";
         when Assignment_Legality_Static_Range_Violation =>
            return "static assignment value is outside the target range";
         when Assignment_Legality_Universal_Numeric_Unresolved =>
            return "universal numeric assignment was not finally resolved";
         when Assignment_Legality_Indeterminate =>
            return "assignment legality is indeterminate";
         when others =>
            return "assignment legality was not checked";
      end case;
   end Message_For;

   function Detail_For (Status : Assignment_Legality_Status) return String is
   begin
      case Status is
         when Assignment_Legality_Compatible =>
            return "The source expression subtype is assignment-compatible with the target subtype metadata.";
         when Assignment_Legality_Class_Wide_Compatible =>
            return "The class-wide source/target relationship is accepted by the current type metadata.";
         when Assignment_Legality_Static_Range_Compatible =>
            return "The source is a static integer value and falls inside the recorded target subtype bounds.";
         when Assignment_Legality_Incompatible_Subtype =>
            return "Subtype compatibility rejected the target/source subtype pair.";
         when Assignment_Legality_Class_Wide_Incompatible =>
            return "The current metadata marks one side as class-wide while subtype compatibility does not accept it.";
         when Assignment_Legality_Target_Unresolved =>
            return "No deterministic target subtype is available for this assignment-like context.";
         when Assignment_Legality_Source_Unresolved =>
            return "No deterministic source expression subtype is available for this assignment-like context.";
         when Assignment_Legality_Private_View_Barrier =>
            return "Private-view metadata prevents accepting the assignment until the proper view is known.";
         when Assignment_Legality_Limited_View_Barrier =>
            return "Limited_View-view metadata exposes only an incomplete view, so assignment cannot be accepted.";
         when Assignment_Legality_Cross_Unit_Unresolved_View =>
            return "The required cross-unit private/limited view was missing, stale, or unresolved.";
         when Assignment_Legality_Assignment_To_Constant =>
            return "Ada assignment statements may not update constants.";
         when Assignment_Legality_Assignment_To_In_Formal =>
            return "Ada assignment statements may not update in-mode formals.";
         when Assignment_Legality_Null_Exclusion_Violation =>
            return "The target access subtype excludes null and the source expression is the null literal.";
         when Assignment_Legality_Static_Range_Violation =>
            return "Static evaluation proves the source integer value is outside the target range.";
         when Assignment_Legality_Universal_Numeric_Unresolved =>
            return "The source remains universal numeric without a compatible final target subtype resolution.";
         when Assignment_Legality_Indeterminate =>
            return "Assignment, expression, subtype, and view metadata are insufficient for a deterministic result.";
         when others =>
            return "The context is not currently an assignment-legality candidate.";
      end case;
   end Detail_For;

   procedure Clear (Model : in out Assignment_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Model_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model   : in out Assignment_Context_Model;
      Context : Assignment_Context_Info) is
      Item : Assignment_Context_Info := Context;
   begin
      if Item.Id = No_Assignment_Context then
         Item.Id := Assignment_Context_Id (Natural (Model.Items.Length) + 1);
      end if;

      if Length (Item.Normalized_Target_Subtype) = 0 and then Length (Item.Target_Subtype) > 0 then
         Item.Normalized_Target_Subtype := To_Unbounded_String
           (Editor.Ada_Subtype_Compatibility.Normalize_Subtype_Name
              (To_String (Item.Target_Subtype)));
      end if;

      if Length (Item.Normalized_Source_Subtype) = 0 and then Length (Item.Source_Subtype) > 0 then
         Item.Normalized_Source_Subtype := To_Unbounded_String
           (Editor.Ada_Subtype_Compatibility.Normalize_Subtype_Name
              (To_String (Item.Source_Subtype)));
      end if;

      Item.Fingerprint := Context_Fingerprint (Item);
      Model.Items.Append (Item);
      Model.Model_Fingerprint := Mix (Model.Model_Fingerprint, Item.Fingerprint + 1);
   end Add_Context;

   function Context_Count (Model : Assignment_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At
     (Model : Assignment_Context_Model;
      Index : Positive) return Assignment_Context_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Context_At;

   function Fingerprint (Model : Assignment_Context_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

   function Expression_For
     (Expressions : Editor.Ada_Expression_Types.Expression_Type_Model;
      Id          : Expression_Type_Id)
      return Editor.Ada_Expression_Types.Expression_Type_Info is
   begin
      if Id = Editor.Ada_Expression_Types.No_Expression_Type then
         return (others => <>);
      end if;
      return Editor.Ada_Expression_Types.Expression_Type (Expressions, Id);
   end Expression_For;

   function Context_With_Expression_Metadata
     (Context     : Assignment_Context_Info;
      Expressions : Editor.Ada_Expression_Types.Expression_Type_Model)
      return Assignment_Context_Info is
      Result : Assignment_Context_Info := Context;
      Expr   : constant Editor.Ada_Expression_Types.Expression_Type_Info :=
        Expression_For (Expressions, Context.Source_Expression);
   begin
      if Expr.Id /= Editor.Ada_Expression_Types.No_Expression_Type then
         if Result.Source_Node = Editor.Ada_Syntax_Tree.No_Node then
            Result.Source_Node := Expr.Node;
         end if;
         if Length (Result.Source_Subtype) = 0 then
            Result.Source_Subtype := Expr.Inferred_Subtype;
         end if;
         if Length (Result.Normalized_Source_Subtype) = 0 then
            Result.Normalized_Source_Subtype := Expr.Normalized_Subtype;
         end if;
         if Expr.Status = Editor.Ada_Expression_Types.Expression_Type_Null_Literal then
            Result.Source_Is_Null_Literal := True;
         end if;
         if Expr.Universal_Numeric_Status in
           Editor.Ada_Expression_Types.Universal_Numeric_Expected_Context_Found |
           Editor.Ada_Expression_Types.Universal_Numeric_Integer_Resolved |
           Editor.Ada_Expression_Types.Universal_Numeric_Real_Resolved |
           Editor.Ada_Expression_Types.Universal_Numeric_Modular_Resolved |
           Editor.Ada_Expression_Types.Universal_Numeric_Fixed_Resolved |
           Editor.Ada_Expression_Types.Universal_Numeric_Range_Compatible |
           Editor.Ada_Expression_Types.Universal_Numeric_Range_Error |
           Editor.Ada_Expression_Types.Universal_Numeric_Expected_Mismatch |
           Editor.Ada_Expression_Types.Universal_Numeric_Static_Unknown
         then
            Result.Source_Is_Universal_Numeric := True;
            Result.Source_Static_Status := Expr.Universal_Numeric_Static_Status;
            Result.Source_Static_Integer_Value := Expr.Universal_Numeric_Integer_Value;
            if Length (Result.Source_Subtype) = 0 then
               Result.Source_Subtype := Expr.Universal_Numeric_Result_Subtype;
            end if;
            if Length (Result.Normalized_Source_Subtype) = 0 then
               Result.Normalized_Source_Subtype := Expr.Normalized_Universal_Numeric_Result_Subtype;
            end if;
         end if;
         Result.Fingerprint := Mix (Context_Fingerprint (Result), Expr.Fingerprint + 1);
      end if;
      return Result;
   end Context_With_Expression_Metadata;

   function Status_From_View
     (View : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Info)
      return Assignment_Legality_Status is
   begin
      if View.Id = Editor.Ada_View_Aware_Compatibility.No_View_Compatibility then
         return Assignment_Legality_Not_Checked;
      elsif Is_Private_View_Status (View.Status) then
         return Assignment_Legality_Private_View_Barrier;
      elsif Is_Limited_View_Status (View.Status) then
         return Assignment_Legality_Limited_View_Barrier;
      elsif View.Status = Editor.Ada_View_Aware_Compatibility.View_Compatibility_Cross_Unit_Unresolved then
         return Assignment_Legality_Cross_Unit_Unresolved_View;
      elsif View.Status = Editor.Ada_View_Aware_Compatibility.View_Compatibility_Known_Incompatible then
         return Assignment_Legality_Incompatible_Subtype;
      elsif View.Status = Editor.Ada_View_Aware_Compatibility.View_Compatibility_Indeterminate then
         return Assignment_Legality_Indeterminate;
      else
         return Assignment_Legality_Not_Checked;
      end if;
   end Status_From_View;

   function Status_From_Subtype
     (Info : Editor.Ada_Subtype_Compatibility.Compatibility_Info;
      Context : Assignment_Context_Info) return Assignment_Legality_Status is
   begin
      if Editor.Ada_Subtype_Compatibility.Is_Compatible (Info) then
         if Context.Target_Is_Class_Wide or else Context.Source_Is_Class_Wide then
            return Assignment_Legality_Class_Wide_Compatible;
         elsif Context.Target_Has_Static_Range
           and then Context.Source_Static_Status in
             Editor.Ada_Static_Expressions.Static_Value_Integer |
             Editor.Ada_Static_Expressions.Static_Value_Modular_Integer |
             Editor.Ada_Static_Expressions.Static_Value_Enumeration_Literal
         then
            return Assignment_Legality_Static_Range_Compatible;
         else
            return Assignment_Legality_Compatible;
         end if;
      elsif Info.Status = Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Known_Incompatible then
         if Context.Target_Is_Class_Wide or else Context.Source_Is_Class_Wide then
            return Assignment_Legality_Class_Wide_Incompatible;
         else
            return Assignment_Legality_Incompatible_Subtype;
         end if;
      elsif Info.Status in
        Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Private_View_Partial_View |
        Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Private_View_Full_View |
        Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Private_View_Hidden_Full_View
      then
         return Assignment_Legality_Private_View_Barrier;
      elsif Info.Status = Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Indeterminate then
         return Assignment_Legality_Indeterminate;
      else
         return Assignment_Legality_Indeterminate;
      end if;
   end Status_From_Subtype;

   function Classify
     (Context   : Assignment_Context_Info;
      View      : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Info;
      Source_Fp : Natural) return Assignment_Legality_Info is
      Result : Assignment_Legality_Info;
      Subtype_Info : Editor.Ada_Subtype_Compatibility.Compatibility_Info;
      View_Status_Result : constant Assignment_Legality_Status := Status_From_View (View);
   begin
      Result.Id := Assignment_Legality_Id (Natural (Context.Id));
      Result.Context := Context.Id;
      Result.Kind := Context.Kind;
      Result.Target_Node := Context.Target_Node;
      Result.Source_Node := Context.Source_Node;
      Result.Source_Expression := Context.Source_Expression;
      Result.Target_Mode := Context.Target_Mode;
      Result.Target_Subtype := Context.Target_Subtype;
      Result.Source_Subtype := Context.Source_Subtype;
      Result.Normalized_Target_Subtype := Context.Normalized_Target_Subtype;
      Result.Normalized_Source_Subtype := Context.Normalized_Source_Subtype;
      Result.Target_Is_Null_Excluding := Context.Target_Is_Null_Excluding;
      Result.Target_Is_Class_Wide := Context.Target_Is_Class_Wide;
      Result.Source_Is_Class_Wide := Context.Source_Is_Class_Wide;
      Result.Source_Is_Null_Literal := Context.Source_Is_Null_Literal;
      Result.Source_Is_Universal_Numeric := Context.Source_Is_Universal_Numeric;
      Result.Source_Static_Status := Context.Source_Static_Status;
      Result.Source_Static_Integer_Value := Context.Source_Static_Integer_Value;
      Result.Target_Has_Static_Range := Context.Target_Has_Static_Range;
      Result.Target_Static_First := Context.Target_Static_First;
      Result.Target_Static_Last := Context.Target_Static_Last;
      Result.Start_Line := Context.Start_Line;
      Result.Start_Column := Context.Start_Column;
      Result.End_Line := Context.End_Line;
      Result.End_Column := Context.End_Column;
      Result.Source_Fingerprint := Mix (Context.Fingerprint, Source_Fp + 1);

      if View.Id /= Editor.Ada_View_Aware_Compatibility.No_View_Compatibility then
         Result.View_Status := View.Status;
      end if;

      if Context.Target_Mode = Assignment_Target_Constant
        and then Context.Kind = Assignment_Context_Assignment_Statement
      then
         Result.Status := Assignment_Legality_Assignment_To_Constant;
      elsif Context.Target_Mode = Assignment_Target_In_Formal
        and then Context.Kind = Assignment_Context_Assignment_Statement
      then
         Result.Status := Assignment_Legality_Assignment_To_In_Formal;
      elsif Length (Context.Normalized_Target_Subtype) = 0 then
         Result.Status := Assignment_Legality_Target_Unresolved;
      elsif Context.Source_Is_Universal_Numeric
        and then Length (Context.Normalized_Source_Subtype) = 0
      then
         Result.Status := Assignment_Legality_Universal_Numeric_Unresolved;
      elsif Length (Context.Normalized_Source_Subtype) = 0 then
         Result.Status := Assignment_Legality_Source_Unresolved;
      elsif Context.Target_Is_Null_Excluding and then Context.Source_Is_Null_Literal then
         Result.Status := Assignment_Legality_Null_Exclusion_Violation;
      elsif Context.Target_Has_Static_Range
        and then Context.Source_Static_Status in
          Editor.Ada_Static_Expressions.Static_Value_Integer |
             Editor.Ada_Static_Expressions.Static_Value_Modular_Integer |
             Editor.Ada_Static_Expressions.Static_Value_Enumeration_Literal
        and then (Context.Source_Static_Integer_Value < Context.Target_Static_First
                  or else Context.Source_Static_Integer_Value > Context.Target_Static_Last)
      then
         Result.Status := Assignment_Legality_Static_Range_Violation;
      elsif View_Status_Result /= Assignment_Legality_Not_Checked then
         Result.Status := View_Status_Result;
      else
         Subtype_Info := Editor.Ada_Subtype_Compatibility.Check
           (To_String (Context.Normalized_Target_Subtype),
            To_String (Context.Normalized_Source_Subtype));
         Result.Subtype_Status := Subtype_Info.Status;
         Result.Status := Status_From_Subtype (Subtype_Info, Context);
      end if;

      Result.Message := To_Unbounded_String (Message_For (Result.Status));
      Result.Detail := To_Unbounded_String (Detail_For (Result.Status));
      Result.Fingerprint := Legality_Fingerprint (Result);
      return Result;
   end Classify;

   procedure Append (Model : in out Assignment_Legality_Model; Info : Assignment_Legality_Info) is
   begin
      if not Has_Legality (Info) then
         return;
      end if;

      Model.Items.Append (Info);
      Model.Model_Fingerprint := Mix (Model.Model_Fingerprint, Info.Fingerprint + 1);

      if Is_Compatible_Status (Info.Status) then
         Model.Compatible_Total := Model.Compatible_Total + 1;
      end if;
      if Is_Error_Status (Info.Status) then
         Model.Error_Total := Model.Error_Total + 1;
      elsif Is_Warning_Status (Info.Status) then
         Model.Warning_Total := Model.Warning_Total + 1;
      else
         Model.Info_Total := Model.Info_Total + 1;
      end if;

      case Info.Status is
         when Assignment_Legality_Target_Unresolved =>
            Model.Target_Unresolved_Total := Model.Target_Unresolved_Total + 1;
         when Assignment_Legality_Source_Unresolved =>
            Model.Source_Unresolved_Total := Model.Source_Unresolved_Total + 1;
         when Assignment_Legality_Incompatible_Subtype |
              Assignment_Legality_Class_Wide_Incompatible =>
            Model.Incompatible_Total := Model.Incompatible_Total + 1;
         when Assignment_Legality_Private_View_Barrier =>
            Model.Private_View_Barrier_Total := Model.Private_View_Barrier_Total + 1;
         when Assignment_Legality_Limited_View_Barrier =>
            Model.Limited_View_Barrier_Total := Model.Limited_View_Barrier_Total + 1;
         when Assignment_Legality_Null_Exclusion_Violation =>
            Model.Null_Exclusion_Violation_Total := Model.Null_Exclusion_Violation_Total + 1;
         when Assignment_Legality_Static_Range_Violation =>
            Model.Static_Range_Violation_Total := Model.Static_Range_Violation_Total + 1;
         when Assignment_Legality_Universal_Numeric_Unresolved =>
            Model.Universal_Numeric_Unresolved_Total :=
              Model.Universal_Numeric_Unresolved_Total + 1;
         when Assignment_Legality_Assignment_To_Constant =>
            Model.Constant_Target_Total := Model.Constant_Target_Total + 1;
         when Assignment_Legality_Assignment_To_In_Formal =>
            Model.In_Formal_Target_Total := Model.In_Formal_Target_Total + 1;
         when others =>
            null;
      end case;
   end Append;

   function Build
     (Contexts   : Assignment_Context_Model;
      Expressions : Editor.Ada_Expression_Types.Expression_Type_Model)
      return Assignment_Legality_Model is
      Empty_Views : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Model;
   begin
      return Build_With_View_Compatibility (Contexts, Expressions, Empty_Views);
   end Build;

   function Build_With_View_Compatibility
     (Contexts    : Assignment_Context_Model;
      Expressions : Editor.Ada_Expression_Types.Expression_Type_Model;
      Views       : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Model)
      return Assignment_Legality_Model is
      Model : Assignment_Legality_Model;
   begin
      Model.Model_Fingerprint := Mix
        (Fingerprint (Contexts), Editor.Ada_Expression_Types.Fingerprint (Expressions) + 1);
      Model.Model_Fingerprint := Mix
        (Model.Model_Fingerprint, Editor.Ada_View_Aware_Compatibility.Fingerprint (Views) + 1);

      for Index in 1 .. Natural (Contexts.Items.Length) loop
         declare
            Base_Context : constant Assignment_Context_Info := Contexts.Items.Element (Index);
            Context      : constant Assignment_Context_Info :=
              Context_With_Expression_Metadata (Base_Context, Expressions);
            Expr         : constant Editor.Ada_Expression_Types.Expression_Type_Info :=
              Expression_For (Expressions, Context.Source_Expression);
            View         : constant Editor.Ada_View_Aware_Compatibility.View_Compatibility_Info :=
              Editor.Ada_View_Aware_Compatibility.First_For_Expression
                (Views, Context.Source_Expression);
            Info         : constant Assignment_Legality_Info :=
              Classify (Context, View, Expr.Fingerprint);
         begin
            Append (Model, Info);
         end;
      end loop;

      return Model;
   end Build_With_View_Compatibility;

   function Legality_Count (Model : Assignment_Legality_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Legality_Count;

   function Legality_At
     (Model : Assignment_Legality_Model;
      Index : Positive) return Assignment_Legality_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Legality_At;

   function First_For_Context
     (Model   : Assignment_Legality_Model;
      Context : Assignment_Context_Id) return Assignment_Legality_Info is
   begin
      for Item of Model.Items loop
         if Item.Context = Context then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end First_For_Context;

   function First_For_Source_Expression
     (Model      : Assignment_Legality_Model;
      Expression : Expression_Type_Id) return Assignment_Legality_Info is
   begin
      for Item of Model.Items loop
         if Item.Source_Expression = Expression then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end First_For_Source_Expression;

   function First_For_Target_Node
     (Model : Assignment_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Assignment_Legality_Info is
   begin
      for Item of Model.Items loop
         if Item.Target_Node = Node then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end First_For_Target_Node;

   function Results_For_Status
     (Model  : Assignment_Legality_Model;
      Status : Assignment_Legality_Status) return Assignment_Legality_Result_Set is
      Results : Assignment_Legality_Result_Set;
   begin
      for Item of Model.Items loop
         if Item.Status = Status then
            Results.Items.Append (Item);
            Results.Fingerprint := Mix (Results.Fingerprint, Item.Fingerprint + 1);
         end if;
      end loop;
      return Results;
   end Results_For_Status;

   function Result_Count (Results : Assignment_Legality_Result_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Result_Count;

   function Result_At
     (Results : Assignment_Legality_Result_Set;
      Index   : Positive) return Assignment_Legality_Info is
   begin
      if Index > Natural (Results.Items.Length) then
         return (others => <>);
      end if;
      return Results.Items.Element (Index);
   end Result_At;

   function Count_Status
     (Model  : Assignment_Legality_Model;
      Status : Assignment_Legality_Status) return Natural is
      Count : Natural := 0;
   begin
      for Item of Model.Items loop
         if Item.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Compatible_Count (Model : Assignment_Legality_Model) return Natural is
   begin
      return Model.Compatible_Total;
   end Compatible_Count;

   function Error_Count (Model : Assignment_Legality_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : Assignment_Legality_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Info_Count (Model : Assignment_Legality_Model) return Natural is
   begin
      return Model.Info_Total;
   end Info_Count;

   function Target_Unresolved_Count (Model : Assignment_Legality_Model) return Natural is
   begin
      return Model.Target_Unresolved_Total;
   end Target_Unresolved_Count;

   function Source_Unresolved_Count (Model : Assignment_Legality_Model) return Natural is
   begin
      return Model.Source_Unresolved_Total;
   end Source_Unresolved_Count;

   function Incompatible_Count (Model : Assignment_Legality_Model) return Natural is
   begin
      return Model.Incompatible_Total;
   end Incompatible_Count;

   function Private_View_Barrier_Count (Model : Assignment_Legality_Model) return Natural is
   begin
      return Model.Private_View_Barrier_Total;
   end Private_View_Barrier_Count;

   function Limited_View_Barrier_Count (Model : Assignment_Legality_Model) return Natural is
   begin
      return Model.Limited_View_Barrier_Total;
   end Limited_View_Barrier_Count;

   function Null_Exclusion_Violation_Count (Model : Assignment_Legality_Model) return Natural is
   begin
      return Model.Null_Exclusion_Violation_Total;
   end Null_Exclusion_Violation_Count;

   function Static_Range_Violation_Count (Model : Assignment_Legality_Model) return Natural is
   begin
      return Model.Static_Range_Violation_Total;
   end Static_Range_Violation_Count;

   function Universal_Numeric_Unresolved_Count (Model : Assignment_Legality_Model) return Natural is
   begin
      return Model.Universal_Numeric_Unresolved_Total;
   end Universal_Numeric_Unresolved_Count;

   function Constant_Target_Count (Model : Assignment_Legality_Model) return Natural is
   begin
      return Model.Constant_Target_Total;
   end Constant_Target_Count;

   function In_Formal_Target_Count (Model : Assignment_Legality_Model) return Natural is
   begin
      return Model.In_Formal_Target_Total;
   end In_Formal_Target_Count;

   function Has_Legality (Info : Assignment_Legality_Info) return Boolean is
   begin
      return Info.Id /= No_Assignment_Legality
        and then Info.Context /= No_Assignment_Context
        and then Info.Status /= Assignment_Legality_Not_Checked;
   end Has_Legality;

   function Fingerprint (Model : Assignment_Legality_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

end Editor.Ada_Assignment_Legality;
