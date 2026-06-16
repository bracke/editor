with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Accessibility_Lifetime_Legality is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Assignment_Legality.Assignment_Legality_Status;
   use type Editor.Ada_Return_Legality.Return_Legality_Status;
   use type Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Status;
   use type Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Status;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 271) + (B * 41) + 1111) mod 1_000_000_007;
   end Mix;

   function Kind_Slot (Kind : Access_Context_Kind) return Natural is
   begin
      return Access_Context_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function Status_Slot (Status : Accessibility_Legality_Status) return Natural is
   begin
      return Accessibility_Legality_Status'Pos (Status) + 1;
   end Status_Slot;

   function Level_Slot (Level : Accessibility_Level) return Natural is
   begin
      return Accessibility_Level'Pos (Level) + 1;
   end Level_Slot;

   function Alias_Slot (State : Alias_Requirement) return Natural is
   begin
      return Alias_Requirement'Pos (State) + 1;
   end Alias_Slot;

   function Target_Slot (Kind : Access_Target_Kind) return Natural is
   begin
      return Access_Target_Kind'Pos (Kind) + 1;
   end Target_Slot;

   function Is_Legal (Status : Accessibility_Legality_Status) return Boolean is
   begin
      return Status in
        Accessibility_Legality_Static_Compatible |
        Accessibility_Legality_Dynamic_Check_Required |
        Accessibility_Legality_Null_Exclusion_Checked |
        Accessibility_Legality_Aliased_Object_Compatible |
        Accessibility_Legality_Allocator_Compatible |
        Accessibility_Legality_Access_Conversion_Compatible |
        Accessibility_Legality_Return_Access_Compatible;
   end Is_Legal;

   function Is_Lifetime_Error (Status : Accessibility_Legality_Status) return Boolean is
   begin
      return Status in
        Accessibility_Legality_Level_Too_Deep |
        Accessibility_Legality_Return_Object_Too_Short_Lived |
        Accessibility_Legality_Anonymous_Access_Level_Unresolved |
        Accessibility_Legality_Access_Discriminant_Lifetime_Error |
        Accessibility_Legality_Access_Parameter_Escapes |
        Accessibility_Legality_Dangling_Rename_Risk;
   end Is_Lifetime_Error;

   function Is_Linked_Error (Status : Accessibility_Legality_Status) return Boolean is
   begin
      return Status in
        Accessibility_Legality_Linked_Assignment_Error |
        Accessibility_Legality_Linked_Return_Error |
        Accessibility_Legality_Linked_Semantic_Error |
        Accessibility_Legality_Linked_Staticness_Error;
   end Is_Linked_Error;

   function Assignment_Error (Status : Assignment_Legality_Status) return Boolean is
   begin
      return Status in
        Editor.Ada_Assignment_Legality.Assignment_Legality_Incompatible_Subtype |
        Editor.Ada_Assignment_Legality.Assignment_Legality_Class_Wide_Incompatible |
        Editor.Ada_Assignment_Legality.Assignment_Legality_Target_Unresolved |
        Editor.Ada_Assignment_Legality.Assignment_Legality_Source_Unresolved |
        Editor.Ada_Assignment_Legality.Assignment_Legality_Private_View_Barrier |
        Editor.Ada_Assignment_Legality.Assignment_Legality_Limited_View_Barrier |
        Editor.Ada_Assignment_Legality.Assignment_Legality_Cross_Unit_Unresolved_View |
        Editor.Ada_Assignment_Legality.Assignment_Legality_Assignment_To_Constant |
        Editor.Ada_Assignment_Legality.Assignment_Legality_Assignment_To_In_Formal |
        Editor.Ada_Assignment_Legality.Assignment_Legality_Null_Exclusion_Violation |
        Editor.Ada_Assignment_Legality.Assignment_Legality_Static_Range_Violation |
        Editor.Ada_Assignment_Legality.Assignment_Legality_Universal_Numeric_Unresolved |
        Editor.Ada_Assignment_Legality.Assignment_Legality_Indeterminate;
   end Assignment_Error;

   function Return_Error (Status : Return_Legality_Status) return Boolean is
   begin
      return Status in
        Editor.Ada_Return_Legality.Return_Legality_Procedure_Return_With_Expression |
        Editor.Ada_Return_Legality.Return_Legality_Function_Return_Missing_Expression |
        Editor.Ada_Return_Legality.Return_Legality_Result_Incompatible_Subtype |
        Editor.Ada_Return_Legality.Return_Legality_Result_Class_Wide_Incompatible |
        Editor.Ada_Return_Legality.Return_Legality_Result_Private_View_Barrier |
        Editor.Ada_Return_Legality.Return_Legality_Result_Limited_View_Barrier |
        Editor.Ada_Return_Legality.Return_Legality_Result_Cross_Unit_Unresolved_View |
        Editor.Ada_Return_Legality.Return_Legality_Result_Target_Unresolved |
        Editor.Ada_Return_Legality.Return_Legality_Result_Source_Unresolved |
        Editor.Ada_Return_Legality.Return_Legality_Result_Static_Range_Violation |
        Editor.Ada_Return_Legality.Return_Legality_Result_Universal_Numeric_Unresolved |
        Editor.Ada_Return_Legality.Return_Legality_No_Return_Subprogram_Return |
        Editor.Ada_Return_Legality.Return_Legality_Indeterminate;
   end Return_Error;

   function Semantic_Error (Status : Semantic_Legality_Status) return Boolean is
   begin
      return Status in
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Target_Unresolved |
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Operand_Unresolved |
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Incompatible_Type |
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Private_View_Barrier |
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Limited_View_Barrier |
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Cross_Unit_Unresolved_View |
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Static_Range_Violation |
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Null_Exclusion_Violation |
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Access_Kind_Mismatch |
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Accessibility_Indeterminate |
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Illegal_Access_Conversion |
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Allocator_Designated_Subtype_Mismatch |
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Universal_Numeric_Unresolved |
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Indeterminate;
   end Semantic_Error;

   function Static_Error (Status : Static_Legality_Status) return Boolean is
   begin
      return Status in
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Requires_Static_Expression |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Non_Static_Expression |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Unresolved_Static_Name |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Malformed_Static_Expression |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Static_Division_By_Zero |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Static_Cycle |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Unsupported_Static_Attribute |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Range_Violation |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Null_Range |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Choice_Out_Of_Range |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Duplicate_Static_Choice |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Choice_Coverage_Gap |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Predicate_Static_Failure |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Predicate_Unresolved |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Predicate_Non_Static_Where_Static_Required |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Linked_Assignment_Error |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Linked_Return_Error |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Linked_Semantic_Error |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Linked_Overload_Error |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Universal_Numeric_Unresolved |
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Indeterminate;
   end Static_Error;

   function Level_Compatible
     (Source_Level : Accessibility_Level;
      Target_Level : Accessibility_Level) return Boolean
   is
   begin
      if Source_Level = Accessibility_Level_Unknown or else
        Target_Level = Accessibility_Level_Unknown
      then
         return False;
      end if;

      return Accessibility_Level'Pos (Source_Level) <=
        Accessibility_Level'Pos (Target_Level);
   end Level_Compatible;

   function Context_Fingerprint (Info : Accessibility_Context_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Kind_Slot (Info.Kind));
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Natural (Info.Source_Node) + 1);
      H := Mix (H, Natural (Info.Target_Node) + 1);
      H := Mix (H, Target_Slot (Info.Source_Access));
      H := Mix (H, Target_Slot (Info.Target_Access));
      H := Mix (H, Level_Slot (Info.Source_Level));
      H := Mix (H, Level_Slot (Info.Target_Level));
      H := Mix (H, Alias_Slot (Info.Alias_State));
      H := Mix (H, Natural (Boolean'Pos (Info.Source_Is_Null_Literal)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Target_Is_Null_Excluding)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Requires_Aliased_Target)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Target_Is_Aliased)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Requires_Dynamic_Check)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Accessibility_Known_Compatible)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Escapes_Current_Master)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Return_Object_Context)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Access_Discriminant_Context)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Private_View_Barrier)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Limited_View_Barrier)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Cross_Unit_Unresolved)) + 1);
      H := Mix (H, Natural (Info.Assignment) + 1);
      H := Mix (H, Editor.Ada_Assignment_Legality.Assignment_Legality_Status'Pos (Info.Assignment_Status) + 1);
      H := Mix (H, Natural (Info.Return_Item) + 1);
      H := Mix (H, Editor.Ada_Return_Legality.Return_Legality_Status'Pos (Info.Return_Status) + 1);
      H := Mix (H, Natural (Info.Semantic_Item) + 1);
      H := Mix (H, Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Status'Pos (Info.Semantic_Status) + 1);
      H := Mix (H, Natural (Info.Static_Item) + 1);
      H := Mix (H, Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Status'Pos (Info.Static_Status) + 1);
      H := Mix (H, Info.Start_Line);
      H := Mix (H, Info.End_Line);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Context_Fingerprint;

   function Row_Fingerprint (Info : Accessibility_Legality_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Kind_Slot (Info.Kind));
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Natural (Info.Source_Node) + 1);
      H := Mix (H, Natural (Info.Target_Node) + 1);
      H := Mix (H, Status_Slot (Info.Status));
      H := Mix (H, Target_Slot (Info.Source_Access));
      H := Mix (H, Target_Slot (Info.Target_Access));
      H := Mix (H, Level_Slot (Info.Source_Level));
      H := Mix (H, Level_Slot (Info.Target_Level));
      H := Mix (H, Alias_Slot (Info.Alias_State));
      H := Mix (H, Editor.Ada_Assignment_Legality.Assignment_Legality_Status'Pos (Info.Assignment_Status) + 1);
      H := Mix (H, Editor.Ada_Return_Legality.Return_Legality_Status'Pos (Info.Return_Status) + 1);
      H := Mix (H, Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Status'Pos (Info.Semantic_Status) + 1);
      H := Mix (H, Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Status'Pos (Info.Static_Status) + 1);
      H := Mix (H, Info.Start_Line);
      H := Mix (H, Info.End_Line);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Row_Fingerprint;

   function Message_For (Status : Accessibility_Legality_Status) return String is
   begin
      case Status is
         when Accessibility_Legality_Static_Compatible =>
            return "accessibility levels are statically compatible";
         when Accessibility_Legality_Dynamic_Check_Required =>
            return "accessibility requires a dynamic check";
         when Accessibility_Legality_Null_Exclusion_Checked =>
            return "null exclusion is satisfied";
         when Accessibility_Legality_Aliased_Object_Compatible =>
            return "aliased-object requirement is satisfied";
         when Accessibility_Legality_Allocator_Compatible =>
            return "allocator accessibility is compatible";
         when Accessibility_Legality_Access_Conversion_Compatible =>
            return "access conversion accessibility is compatible";
         when Accessibility_Legality_Return_Access_Compatible =>
            return "return accessibility is compatible";
         when Accessibility_Legality_Null_Exclusion_Violation =>
            return "null literal violates a null-excluding access target";
         when Accessibility_Legality_Access_Kind_Mismatch =>
            return "access-to-object and access-to-subprogram kinds do not match";
         when Accessibility_Legality_Target_Not_Aliased =>
            return "target object must be aliased";
         when Accessibility_Legality_Level_Too_Deep =>
            return "source accessibility level is deeper than the target permits";
         when Accessibility_Legality_Return_Object_Too_Short_Lived =>
            return "returned access value may outlive the designated object";
         when Accessibility_Legality_Anonymous_Access_Level_Unresolved =>
            return "anonymous access parameter accessibility is unresolved";
         when Accessibility_Legality_Allocator_Designated_Subtype_Mismatch =>
            return "allocator designated subtype is incompatible";
         when Accessibility_Legality_Access_Discriminant_Lifetime_Error =>
            return "access discriminant designated object may not live long enough";
         when Accessibility_Legality_Access_Parameter_Escapes =>
            return "access parameter escapes its permitted master";
         when Accessibility_Legality_Dangling_Rename_Risk =>
            return "renaming may preserve a dangling access value";
         when Accessibility_Legality_Private_View_Barrier =>
            return "private view hides required accessibility metadata";
         when Accessibility_Legality_Limited_View_Barrier =>
            return "limited view hides required accessibility metadata";
         when Accessibility_Legality_Cross_Unit_Unresolved_View =>
            return "cross-unit accessibility dependency is unresolved";
         when Accessibility_Legality_Linked_Assignment_Error =>
            return "linked assignment legality rejects this access use";
         when Accessibility_Legality_Linked_Return_Error =>
            return "linked return legality rejects this access use";
         when Accessibility_Legality_Linked_Semantic_Error =>
            return "linked conversion/access/aggregate legality rejects this access use";
         when Accessibility_Legality_Linked_Staticness_Error =>
            return "linked staticness/range/predicate legality rejects this access use";
         when Accessibility_Legality_Indeterminate =>
            return "accessibility legality is indeterminate";
         when others =>
            return "accessibility legality was not checked";
      end case;
   end Message_For;

   function Classify (Info : Accessibility_Context_Info) return Accessibility_Legality_Status is
   begin
      if Info.Private_View_Barrier then
         return Accessibility_Legality_Private_View_Barrier;
      elsif Info.Limited_View_Barrier then
         return Accessibility_Legality_Limited_View_Barrier;
      elsif Info.Cross_Unit_Unresolved then
         return Accessibility_Legality_Cross_Unit_Unresolved_View;
      elsif Assignment_Error (Info.Assignment_Status) then
         return Accessibility_Legality_Linked_Assignment_Error;
      elsif Return_Error (Info.Return_Status) then
         return Accessibility_Legality_Linked_Return_Error;
      elsif Semantic_Error (Info.Semantic_Status) then
         if Info.Semantic_Status =
           Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Null_Exclusion_Violation
         then
            return Accessibility_Legality_Null_Exclusion_Violation;
         elsif Info.Semantic_Status =
           Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Access_Kind_Mismatch
         then
            return Accessibility_Legality_Access_Kind_Mismatch;
         elsif Info.Semantic_Status =
           Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Allocator_Designated_Subtype_Mismatch
         then
            return Accessibility_Legality_Allocator_Designated_Subtype_Mismatch;
         else
            return Accessibility_Legality_Linked_Semantic_Error;
         end if;
      elsif Static_Error (Info.Static_Status) then
         return Accessibility_Legality_Linked_Staticness_Error;
      elsif Info.Source_Is_Null_Literal and then Info.Target_Is_Null_Excluding then
         return Accessibility_Legality_Null_Exclusion_Violation;
      elsif Info.Source_Access /= Access_Target_Unknown and then
        Info.Target_Access /= Access_Target_Unknown and then
        Info.Source_Access /= Info.Target_Access and then
        Info.Source_Access /= Access_Target_None and then
        Info.Target_Access /= Access_Target_None
      then
         return Accessibility_Legality_Access_Kind_Mismatch;
      elsif (Info.Requires_Aliased_Target or else Info.Alias_State = Alias_Required) and then
        not Info.Target_Is_Aliased and then Info.Alias_State /= Alias_Satisfied
      then
         return Accessibility_Legality_Target_Not_Aliased;
      elsif Info.Escapes_Current_Master and then
        Info.Kind = Access_Context_Anonymous_Access_Parameter
      then
         return Accessibility_Legality_Access_Parameter_Escapes;
      elsif Info.Escapes_Current_Master and then Info.Return_Object_Context then
         return Accessibility_Legality_Return_Object_Too_Short_Lived;
      elsif Info.Escapes_Current_Master and then Info.Access_Discriminant_Context then
         return Accessibility_Legality_Access_Discriminant_Lifetime_Error;
      elsif Info.Escapes_Current_Master and then Info.Kind = Access_Context_Renaming then
         return Accessibility_Legality_Dangling_Rename_Risk;
      elsif Info.Kind = Access_Context_Anonymous_Access_Parameter and then
        (Info.Source_Level = Accessibility_Level_Unknown or else
         Info.Target_Level = Accessibility_Level_Unknown)
      then
         return Accessibility_Legality_Anonymous_Access_Level_Unresolved;
      elsif Info.Source_Level = Accessibility_Level_Deeper and then
        Info.Target_Level /= Accessibility_Level_Deeper
      then
         return Accessibility_Legality_Level_Too_Deep;
      elsif Info.Source_Level /= Accessibility_Level_Unknown and then
        Info.Target_Level /= Accessibility_Level_Unknown and then
        not Level_Compatible (Info.Source_Level, Info.Target_Level)
      then
         return Accessibility_Legality_Level_Too_Deep;
      elsif Info.Requires_Dynamic_Check and then not Info.Accessibility_Known_Compatible then
         return Accessibility_Legality_Dynamic_Check_Required;
      elsif Info.Kind = Access_Context_Allocator then
         return Accessibility_Legality_Allocator_Compatible;
      elsif Info.Kind = Access_Context_Access_Conversion then
         return Accessibility_Legality_Access_Conversion_Compatible;
      elsif Info.Kind in Access_Context_Return_Object | Access_Context_Return_Access then
         return Accessibility_Legality_Return_Access_Compatible;
      elsif Info.Requires_Aliased_Target or else Info.Alias_State = Alias_Satisfied then
         return Accessibility_Legality_Aliased_Object_Compatible;
      elsif Info.Target_Is_Null_Excluding then
         return Accessibility_Legality_Null_Exclusion_Checked;
      elsif Info.Accessibility_Known_Compatible or else
        Level_Compatible (Info.Source_Level, Info.Target_Level)
      then
         return Accessibility_Legality_Static_Compatible;
      else
         return Accessibility_Legality_Indeterminate;
      end if;
   end Classify;

   function Build_Row
     (Info : Accessibility_Context_Info;
      Id   : Accessibility_Legality_Id) return Accessibility_Legality_Info
   is
      Status : constant Accessibility_Legality_Status := Classify (Info);
      Row    : Accessibility_Legality_Info;
   begin
      Row.Id := Id;
      Row.Context := Info.Id;
      Row.Kind := Info.Kind;
      Row.Node := Info.Node;
      Row.Source_Node := Info.Source_Node;
      Row.Target_Node := Info.Target_Node;
      Row.Status := Status;
      Row.Message := To_Unbounded_String (Message_For (Status));
      Row.Detail := To_Unbounded_String (Access_Context_Kind'Image (Info.Kind));
      Row.Source_Access := Info.Source_Access;
      Row.Target_Access := Info.Target_Access;
      Row.Source_Level := Info.Source_Level;
      Row.Target_Level := Info.Target_Level;
      Row.Alias_State := Info.Alias_State;
      Row.Assignment_Status := Info.Assignment_Status;
      Row.Return_Status := Info.Return_Status;
      Row.Semantic_Status := Info.Semantic_Status;
      Row.Static_Status := Info.Static_Status;
      Row.Start_Line := Info.Start_Line;
      Row.Start_Column := Info.Start_Column;
      Row.End_Line := Info.End_Line;
      Row.End_Column := Info.End_Column;
      Row.Source_Fingerprint := Info.Source_Fingerprint;
      Row.Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Build_Row;

   procedure Add_Row
     (Model : in out Accessibility_Legality_Model;
      Row   : Accessibility_Legality_Info)
   is
   begin
      Model.Items.Append (Row);
      if Is_Legal (Row.Status) then
         Model.Legal_Total := Model.Legal_Total + 1;
      else
         Model.Error_Total := Model.Error_Total + 1;
      end if;

      if Is_Lifetime_Error (Row.Status) then
         Model.Lifetime_Error_Total := Model.Lifetime_Error_Total + 1;
      end if;
      if Row.Status = Accessibility_Legality_Null_Exclusion_Violation then
         Model.Null_Exclusion_Error_Total := Model.Null_Exclusion_Error_Total + 1;
      end if;
      if Row.Status = Accessibility_Legality_Target_Not_Aliased then
         Model.Aliasing_Error_Total := Model.Aliasing_Error_Total + 1;
      end if;
      if Is_Linked_Error (Row.Status) then
         Model.Linked_Error_Total := Model.Linked_Error_Total + 1;
      end if;
      if Row.Status = Accessibility_Legality_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Row.Fingerprint + 1);
   end Add_Row;

   procedure Clear (Model : in out Accessibility_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Accessibility_Context_Model;
      Info  : Accessibility_Context_Info)
   is
      Normalized : Accessibility_Context_Info := Info;
   begin
      if Normalized.Id = No_Accessibility_Context then
         Normalized.Id := Accessibility_Context_Id (Natural (Model.Contexts.Length) + 1);
      end if;
      Normalized.Source_Fingerprint := Mix
        (Normalized.Source_Fingerprint, Context_Fingerprint (Normalized));
      Model.Contexts.Append (Normalized);
      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint, Context_Fingerprint (Normalized) + 1);
   end Add_Context;

   function Context_Count (Model : Accessibility_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Accessibility_Context_Model;
      Index : Positive) return Accessibility_Context_Info
   is
   begin
      if Index > Natural (Model.Contexts.Length) then
         return (others => <>);
      end if;
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Accessibility_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build
     (Contexts : Accessibility_Context_Model) return Accessibility_Legality_Model
   is
      Model : Accessibility_Legality_Model;
      Next  : Accessibility_Legality_Id := 1;
   begin
      for C of Contexts.Contexts loop
         Add_Row (Model, Build_Row (C, Next));
         Next := Next + 1;
      end loop;
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Fingerprint (Contexts) + 1);
      return Model;
   end Build;

   function Legality_Count (Model : Accessibility_Legality_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Legality_Count;

   function Legality_At
     (Model : Accessibility_Legality_Model;
      Index : Positive) return Accessibility_Legality_Info
   is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Legality_At;

   function First_For_Node
     (Model : Accessibility_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Accessibility_Legality_Info
   is
   begin
      for Row of Model.Items loop
         if Row.Node = Node or else Row.Source_Node = Node or else Row.Target_Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Accessibility_Legality_Model;
      Status : Accessibility_Legality_Status) return Accessibility_Result_Set
   is
      Results : Accessibility_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Results.Items.Append (Row);
            Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint + 1);
         end if;
      end loop;
      return Results;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Accessibility_Legality_Model;
      Kind  : Access_Context_Kind) return Accessibility_Result_Set
   is
      Results : Accessibility_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Results.Items.Append (Row);
            Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint + 1);
         end if;
      end loop;
      return Results;
   end Rows_For_Kind;

   function Rows_For_Alias_State
     (Model : Accessibility_Legality_Model;
      State : Alias_Requirement) return Accessibility_Result_Set
   is
      Results : Accessibility_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Alias_State = State then
            Results.Items.Append (Row);
            Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint + 1);
         end if;
      end loop;
      return Results;
   end Rows_For_Alias_State;

   function Rows_For_Level
     (Model : Accessibility_Legality_Model;
      Level : Accessibility_Level) return Accessibility_Result_Set
   is
      Results : Accessibility_Result_Set;
   begin
      for Row of Model.Items loop
         if (Level = Accessibility_Level_Unknown
             and then Row.Status =
               Accessibility_Legality_Anonymous_Access_Level_Unresolved
             and then
               (Row.Source_Level = Level or else Row.Target_Level = Level))
           or else
             (Level /= Accessibility_Level_Unknown
              and then
                (Row.Source_Level = Level or else Row.Target_Level = Level))
         then
            Results.Items.Append (Row);
            Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint + 1);
         end if;
      end loop;
      return Results;
   end Rows_For_Level;

   function Result_Count (Results : Accessibility_Result_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Result_Count;

   function Result_At
     (Results : Accessibility_Result_Set;
      Index   : Positive) return Accessibility_Legality_Info
   is
   begin
      if Index > Natural (Results.Items.Length) then
         return (others => <>);
      end if;
      return Results.Items.Element (Index);
   end Result_At;

   function Count_Status
     (Model  : Accessibility_Legality_Model;
      Status : Accessibility_Legality_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind
     (Model : Accessibility_Legality_Model;
      Kind  : Access_Context_Kind) return Natural
   is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Count_Alias_State
     (Model : Accessibility_Legality_Model;
      State : Alias_Requirement) return Natural
   is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Alias_State = State then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Alias_State;

   function Count_Level
     (Model : Accessibility_Legality_Model;
      Level : Accessibility_Level) return Natural
   is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if (Level = Accessibility_Level_Unknown
             and then Row.Status =
               Accessibility_Legality_Anonymous_Access_Level_Unresolved
             and then
               (Row.Source_Level = Level or else Row.Target_Level = Level))
           or else
             (Level /= Accessibility_Level_Unknown
              and then
                (Row.Source_Level = Level or else Row.Target_Level = Level))
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Level;

   function Legal_Count (Model : Accessibility_Legality_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Error_Count (Model : Accessibility_Legality_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Lifetime_Error_Count (Model : Accessibility_Legality_Model) return Natural is
   begin
      return Model.Lifetime_Error_Total;
   end Lifetime_Error_Count;

   function Null_Exclusion_Error_Count (Model : Accessibility_Legality_Model) return Natural is
   begin
      return Model.Null_Exclusion_Error_Total;
   end Null_Exclusion_Error_Count;

   function Aliasing_Error_Count (Model : Accessibility_Legality_Model) return Natural is
   begin
      return Model.Aliasing_Error_Total;
   end Aliasing_Error_Count;

   function Linked_Error_Count (Model : Accessibility_Legality_Model) return Natural is
   begin
      return Model.Linked_Error_Total;
   end Linked_Error_Count;

   function Indeterminate_Count (Model : Accessibility_Legality_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Accessibility_Legality_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Has_Legality (Info : Accessibility_Legality_Info) return Boolean is
   begin
      return Info.Id /= No_Accessibility_Legality and then
        Info.Status /= Accessibility_Legality_Not_Checked;
   end Has_Legality;

end Editor.Ada_Accessibility_Lifetime_Legality;
