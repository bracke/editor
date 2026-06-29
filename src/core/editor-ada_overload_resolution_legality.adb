with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Implicit_Conversions;

package body Editor.Ada_Overload_Resolution_Legality is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Status;
   use type Editor.Ada_Overload_Ranking.Overload_Ranking_Id;
   use type Editor.Ada_Overload_Ranking.Overload_Ranking_Status;
   use type Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 263) + (B * 31) + 1109) mod 1_000_000_007;
   end Mix;

   function Status_Slot (Status : Overload_Legality_Status) return Natural is
   begin
      return Overload_Legality_Status'Pos (Status) + 1;
   end Status_Slot;

   function Kind_Slot (Kind : Overload_Context_Kind) return Natural is
   begin
      return Overload_Context_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function Is_Legal (Status : Overload_Legality_Status) return Boolean is
   begin
      return Status in
        Overload_Legality_Legal_Exact |
        Overload_Legality_Legal_Expected_Type_Preferred |
        Overload_Legality_Legal_Universal_Integer_Preferred |
        Overload_Legality_Legal_Universal_Real_Preferred |
        Overload_Legality_Legal_Primitive_Operator_Preferred |
        Overload_Legality_Legal_Implicit_Numeric_Conversion |
        Overload_Legality_Legal_Class_Wide_Conversion |
        Overload_Legality_Legal_Access_Conversion |
        Overload_Legality_Legal_Named_Actual_Profile |
        Overload_Legality_Legal_Defaulted_Formal_Profile;
   end Is_Legal;

   function Context_Fingerprint (Info : Overload_Context_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Kind_Slot (Info.Kind));
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Length (Info.Designator) + 1);
      H := Mix (H, Length (Info.Expected_Subtype) + 1);
      H := Mix (H, Length (Info.Selected_Subtype) + 1);
      H := Mix (H, Info.Candidate_Count + 1);
      H := Mix (H, Info.Visible_Candidate_Count + 1);
      H := Mix (H, Info.Exact_Match_Count + 1);
      H := Mix (H, Info.Expected_Type_Match_Count + 1);
      H := Mix (H, Info.Universal_Integer_Count + 1);
      H := Mix (H, Info.Universal_Real_Count + 1);
      H := Mix (H, Info.Primitive_Operator_Count + 1);
      H := Mix (H, Info.Implicit_Numeric_Conversion_Count + 1);
      H := Mix (H, Info.Class_Wide_Conversion_Count + 1);
      H := Mix (H, Info.Access_Conversion_Count + 1);
      H := Mix (H, Info.Named_Actual_Match_Count + 1);
      H := Mix (H, Info.Defaulted_Formal_Count + 1);
      H := Mix (H, Info.Profile_Mismatch_Count + 1);
      H := Mix (H, Info.Actual_Type_Mismatch_Count + 1);
      H := Mix (H, Info.Defaulted_Formal_Mismatch_Count + 1);
      H := Mix (H, Info.Ambiguous_Candidate_Count + 1);
      H := Mix (H, Info.Candidate_Not_Visible_Count + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Private_View_Barrier)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Limited_View_Barrier)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Cross_Unit_Unresolved)) + 1);
      H := Mix (H, Natural (Info.Linked_Wide_Diagnostic) + 1);
      H := Mix (H, Natural (Info.Ranking) + 1);
      H := Mix (H, Info.Start_Line);
      H := Mix (H, Info.End_Line);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Context_Fingerprint;

   function Legality_Fingerprint (Info : Overload_Legality_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Kind_Slot (Info.Kind));
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Status_Slot (Info.Status));
      H := Mix (H, Natural (Info.Ranking) + 1);
      H := Mix (H, Editor.Ada_Overload_Ranking.Overload_Ranking_Status'Pos (Info.Ranking_Status) + 1);
      H := Mix (H, Natural (Info.Linked_Wide_Diagnostic) + 1);
      H := Mix (H, Info.Candidate_Count + 1);
      H := Mix (H, Info.Visible_Candidate_Count + 1);
      H := Mix (H, Info.Selected_Count + 1);
      H := Mix (H, Info.Rejected_Count + 1);
      H := Mix (H, Info.Start_Line);
      H := Mix (H, Info.End_Line);
      H := Mix (H, Info.Source_Fingerprint + 1);
      H := Mix (H, Info.Ranking_Fingerprint + 1);
      H := Mix (H, Info.Wide_Diagnostic_Fingerprint + 1);
      H := Mix (H, Length (Info.Message) + Length (Info.Detail) + 1);
      return H;
   end Legality_Fingerprint;

   function Message_For (Status : Overload_Legality_Status) return String is
   begin
      case Status is
         when Overload_Legality_Legal_Exact =>
            return "overload resolution selected an exact legal interpretation";
         when Overload_Legality_Legal_Expected_Type_Preferred =>
            return "expected type selects the overload interpretation";
         when Overload_Legality_Legal_Universal_Integer_Preferred =>
            return "universal integer preference selects the overload interpretation";
         when Overload_Legality_Legal_Universal_Real_Preferred =>
            return "universal real preference selects the overload interpretation";
         when Overload_Legality_Legal_Primitive_Operator_Preferred =>
            return "primitive operator preference selects the overload interpretation";
         when Overload_Legality_Legal_Implicit_Numeric_Conversion =>
            return "implicit numeric conversion selects the overload interpretation";
         when Overload_Legality_Legal_Class_Wide_Conversion =>
            return "class-wide conversion selects the overload interpretation";
         when Overload_Legality_Legal_Access_Conversion =>
            return "access conversion selects the overload interpretation";
         when Overload_Legality_Legal_Named_Actual_Profile =>
            return "named actual/profile matching selects the overload interpretation";
         when Overload_Legality_Legal_Defaulted_Formal_Profile =>
            return "defaulted formal profile evidence selects the overload interpretation";
         when Overload_Legality_Ambiguous_After_Preference =>
            return "overload resolution remains ambiguous after applying preferences";
         when Overload_Legality_No_Visible_Candidate =>
            return "overload resolution found no visible candidate";
         when Overload_Legality_Not_Visible =>
            return "candidate exists but is not visible";
         when Overload_Legality_Profile_Mismatch =>
            return "overload candidate profile does not match actuals";
         when Overload_Legality_Actual_Type_Mismatch =>
            return "actual expression type does not match overload candidate";
         when Overload_Legality_Defaulted_Formal_Mismatch =>
            return "defaulted formal evidence does not match overload candidate";
         when Overload_Legality_Private_View_Barrier =>
            return "private view prevents overload legality confirmation";
         when Overload_Legality_Limited_View_Barrier =>
            return "limited view prevents overload legality confirmation";
         when Overload_Legality_Cross_Unit_Unresolved =>
            return "cross-unit dependency prevents overload legality confirmation";
         when Overload_Legality_Linked_Semantic_Error =>
            return "linked semantic legality error prevents overload selection";
         when Overload_Legality_Unknown =>
            return "overload legality is unknown";
         when Overload_Legality_Indeterminate =>
            return "overload legality is indeterminate";
         when Overload_Legality_Not_Checked =>
            return "overload legality was not checked";
      end case;
   end Message_For;

   function Classify
     (Context : Overload_Context_Info;
      Ranking : Editor.Ada_Overload_Ranking.Overload_Ranking_Info;
      Wide : Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Info)
      return Overload_Legality_Status
   is
      Has_Wide : constant Boolean :=
        Wide.Id /= Editor.Ada_Wide_Semantic_Legality_Diagnostics.No_Wide_Semantic_Diagnostic;
   begin
      if Has_Wide then
         case Wide.Kind is
            when Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_View_Barrier =>
               if Context.Limited_View_Barrier then
                  return Overload_Legality_Limited_View_Barrier;
               end if;
               return Overload_Legality_Private_View_Barrier;
            when Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Unresolved_Semantic_State =>
               return Overload_Legality_Cross_Unit_Unresolved;
            when others =>
               return Overload_Legality_Linked_Semantic_Error;
         end case;
      end if;

      if Context.Private_View_Barrier then
         return Overload_Legality_Private_View_Barrier;
      elsif Context.Limited_View_Barrier then
         return Overload_Legality_Limited_View_Barrier;
      elsif Context.Cross_Unit_Unresolved then
         return Overload_Legality_Cross_Unit_Unresolved;
      elsif Context.Visible_Candidate_Count = 0 and then Context.Candidate_Count > 0 then
         return Overload_Legality_Not_Visible;
      elsif Context.Candidate_Count = 0 then
         return Overload_Legality_No_Visible_Candidate;
      elsif Context.Ambiguous_Candidate_Count > 0 then
         return Overload_Legality_Ambiguous_After_Preference;
      elsif Context.Profile_Mismatch_Count > 0 then
         return Overload_Legality_Profile_Mismatch;
      elsif Context.Actual_Type_Mismatch_Count > 0 then
         return Overload_Legality_Actual_Type_Mismatch;
      elsif Context.Defaulted_Formal_Mismatch_Count > 0 then
         return Overload_Legality_Defaulted_Formal_Mismatch;
      elsif Context.Expected_Type_Match_Count > 0 then
         return Overload_Legality_Legal_Expected_Type_Preferred;
      elsif Context.Universal_Integer_Count > 0 then
         return Overload_Legality_Legal_Universal_Integer_Preferred;
      elsif Context.Universal_Real_Count > 0 then
         return Overload_Legality_Legal_Universal_Real_Preferred;
      elsif Context.Primitive_Operator_Count > 0 then
         return Overload_Legality_Legal_Primitive_Operator_Preferred;
      elsif Context.Implicit_Numeric_Conversion_Count > 0 then
         return Overload_Legality_Legal_Implicit_Numeric_Conversion;
      elsif Context.Class_Wide_Conversion_Count > 0 then
         return Overload_Legality_Legal_Class_Wide_Conversion;
      elsif Context.Access_Conversion_Count > 0 then
         return Overload_Legality_Legal_Access_Conversion;
      elsif Context.Named_Actual_Match_Count > 0 then
         return Overload_Legality_Legal_Named_Actual_Profile;
      elsif Context.Defaulted_Formal_Count > 0 then
         return Overload_Legality_Legal_Defaulted_Formal_Profile;
      elsif Context.Exact_Match_Count > 0 then
         return Overload_Legality_Legal_Exact;
      elsif Editor.Ada_Overload_Ranking.Has_Ranking (Ranking) then
         case Ranking.Status is
            when Editor.Ada_Overload_Ranking.Overload_Ranking_Exact_Match =>
               return Overload_Legality_Legal_Exact;
            when Editor.Ada_Overload_Ranking.Overload_Ranking_Implicit_Conversion =>
               return Overload_Legality_Legal_Implicit_Numeric_Conversion;
            when Editor.Ada_Overload_Ranking.Overload_Ranking_Universal_Numeric_Tie_Break =>
               return Overload_Legality_Legal_Universal_Integer_Preferred;
            when Editor.Ada_Overload_Ranking.Overload_Ranking_Ambiguous_After_Ranking =>
               return Overload_Legality_Ambiguous_After_Preference;
            when Editor.Ada_Overload_Ranking.Overload_Ranking_No_Ranked_Candidate =>
               return Overload_Legality_No_Visible_Candidate;
            when Editor.Ada_Overload_Ranking.Overload_Ranking_Unknown =>
               return Overload_Legality_Unknown;
            when others =>
               return Overload_Legality_Indeterminate;
         end case;
      end if;

      return Overload_Legality_Indeterminate;
   end Classify;

   function Detail_For (Context : Overload_Context_Info) return String is
   begin
      return
        "candidates=" & Natural'Image (Context.Candidate_Count) &
        " visible=" & Natural'Image (Context.Visible_Candidate_Count) &
        " exact=" & Natural'Image (Context.Exact_Match_Count) &
        " expected=" & Natural'Image (Context.Expected_Type_Match_Count) &
        " universal_integer=" & Natural'Image (Context.Universal_Integer_Count) &
        " universal_real=" & Natural'Image (Context.Universal_Real_Count) &
        " primitive=" & Natural'Image (Context.Primitive_Operator_Count) &
        " implicit_numeric=" & Natural'Image (Context.Implicit_Numeric_Conversion_Count) &
        " classwide=" & Natural'Image (Context.Class_Wide_Conversion_Count) &
        " access=" & Natural'Image (Context.Access_Conversion_Count) &
        " rejected=" & Natural'Image
          (Context.Profile_Mismatch_Count + Context.Actual_Type_Mismatch_Count +
           Context.Defaulted_Formal_Mismatch_Count + Context.Candidate_Not_Visible_Count);
   end Detail_For;

   function Make_Item
     (Context : Overload_Context_Info;
      Id      : Overload_Legality_Id;
      Ranking : Editor.Ada_Overload_Ranking.Overload_Ranking_Info;
      Wide    : Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Info)
      return Overload_Legality_Info
   is
      Result : Overload_Legality_Info;
   begin
      Result.Id := Id;
      Result.Context := Context.Id;
      Result.Kind := Context.Kind;
      Result.Node := Context.Node;
      Result.Designator := Context.Designator;
      Result.Status := Classify (Context, Ranking, Wide);
      Result.Message := To_Unbounded_String (Message_For (Result.Status));
      Result.Detail := To_Unbounded_String (Detail_For (Context));
      Result.Ranking := Ranking.Id;
      Result.Ranking_Status := Ranking.Status;
      Result.Linked_Wide_Diagnostic := Wide.Id;
      Result.Candidate_Count := Context.Candidate_Count;
      Result.Visible_Candidate_Count := Context.Visible_Candidate_Count;
      Result.Selected_Count := Context.Exact_Match_Count + Context.Expected_Type_Match_Count +
        Context.Universal_Integer_Count + Context.Universal_Real_Count +
        Context.Primitive_Operator_Count + Context.Implicit_Numeric_Conversion_Count +
        Context.Class_Wide_Conversion_Count + Context.Access_Conversion_Count +
        Context.Named_Actual_Match_Count + Context.Defaulted_Formal_Count;
      Result.Rejected_Count := Context.Profile_Mismatch_Count + Context.Actual_Type_Mismatch_Count +
        Context.Defaulted_Formal_Mismatch_Count + Context.Candidate_Not_Visible_Count +
        Context.Ambiguous_Candidate_Count;
      Result.Start_Line := Context.Start_Line;
      Result.Start_Column := Context.Start_Column;
      Result.End_Line := Context.End_Line;
      Result.End_Column := Context.End_Column;
      Result.Source_Fingerprint := Context.Source_Fingerprint;
      Result.Ranking_Fingerprint := Ranking.Fingerprint;
      Result.Wide_Diagnostic_Fingerprint := Wide.Fingerprint;
      Result.Fingerprint := Legality_Fingerprint (Result);
      return Result;
   end Make_Item;

   procedure Append (Model : in out Overload_Legality_Model; Info : Overload_Legality_Info) is
   begin
      if not Has_Legality (Info) then
         return;
      end if;
      Model.Items.Append (Info);
      if Is_Legal (Info.Status) then
         Model.Legal_Total := Model.Legal_Total + 1;
      else
         Model.Error_Total := Model.Error_Total + 1;
      end if;
      case Info.Status is
         when Overload_Legality_Ambiguous_After_Preference =>
            Model.Ambiguous_Total := Model.Ambiguous_Total + 1;
         when Overload_Legality_No_Visible_Candidate | Overload_Legality_Not_Visible =>
            Model.Visibility_Total := Model.Visibility_Total + 1;
         when Overload_Legality_Private_View_Barrier | Overload_Legality_Limited_View_Barrier =>
            Model.View_Barrier_Total := Model.View_Barrier_Total + 1;
         when Overload_Legality_Cross_Unit_Unresolved =>
            Model.Cross_Unit_Total := Model.Cross_Unit_Total + 1;
         when Overload_Legality_Linked_Semantic_Error =>
            Model.Linked_Error_Total := Model.Linked_Error_Total + 1;
         when Overload_Legality_Indeterminate | Overload_Legality_Unknown =>
            Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
         when others =>
            null;
      end case;
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint);
   end Append;

   procedure Clear (Model : in out Overload_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Overload_Context_Model;
      Info  : Overload_Context_Info)
   is
      Item : Overload_Context_Info := Info;
   begin
      if Item.Id = No_Overload_Context then
         Item.Id := Overload_Context_Id (Natural (Model.Contexts.Length) + 1);
      end if;
      Model.Contexts.Append (Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Context_Fingerprint (Item));
   end Add_Context;

   function Expected_Filter_Selects
     (Status : Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Status)
      return Boolean is
   begin
      return Status =
        Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Result_Subtype_Matches
        or else Status =
          Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Result_Subtype_Compatible;
   end Expected_Filter_Selects;

   function Expected_Filter_Selects
     (Info : Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Info)
      return Boolean is
   begin
      return Expected_Filter_Selects (Info.Status)
        and then Editor.Ada_Implicit_Conversions.Is_Implicitly_Allowed
          ((Compatibility => Info.Compatibility,
            Status        => Info.Implicit_Conversion,
            Fingerprint   => 0));
   end Expected_Filter_Selects;

   function Node_Has_Selected_Expected_Filter
     (Filters : Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Model;
      Node    : Editor.Ada_Syntax_Tree.Node_Id) return Boolean
   is
      Info : Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Info;
   begin
      for I in 1 .. Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Count (Filters) loop
         Info := Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_At (Filters, I);
         if Info.Call_Node = Node and then Expected_Filter_Selects (Info) then
            return True;
         end if;
      end loop;
      return False;
   end Node_Has_Selected_Expected_Filter;

   function Selected_Context_Already_Added
     (Model : Overload_Context_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Boolean
   is
      Info : Overload_Context_Info;
   begin
      for I in 1 .. Context_Count (Model) loop
         Info := Context_At (Model, I);
         if Info.Node = Node and then Info.Expected_Type_Match_Count > 0 then
            return True;
         end if;
      end loop;
      return False;
   end Selected_Context_Already_Added;

   function Context_From_Expected_Filter
     (Info : Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Info)
      return Overload_Context_Info
   is
      Context : Overload_Context_Info;
   begin
      Context.Kind := Overload_Context_Call;
      Context.Node := Info.Call_Node;
      Context.Designator := To_Unbounded_String ("call");
      Context.Expected_Subtype := Info.Expected_Subtype;
      Context.Selected_Subtype := Info.Result_Subtype;
      Context.Start_Line := Info.Start_Line;
      Context.End_Line := Info.End_Line;
      Context.Source_Fingerprint := Info.Fingerprint;

      if Expected_Filter_Selects (Info) then
         Context.Candidate_Count := 1;
         Context.Visible_Candidate_Count := 1;
         Context.Expected_Type_Match_Count := 1;
      else
         case Info.Status is
            when Editor.Ada_Expected_Call_Filters
              .Expected_Call_Filter_Result_Subtype_Requires_Explicit_Conversion =>
               Context.Candidate_Count := 1;
               Context.Visible_Candidate_Count := 1;
               Context.Actual_Type_Mismatch_Count := 1;
            when Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Result_Subtype_Compatible =>
               Context.Candidate_Count := 1;
               Context.Visible_Candidate_Count := 1;
               Context.Actual_Type_Mismatch_Count := 1;
            when Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Result_Subtype_Mismatch =>
               Context.Candidate_Count := 1;
               Context.Visible_Candidate_Count := 1;
               Context.Actual_Type_Mismatch_Count := 1;
            when Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_No_Unique_Profile =>
               Context.Candidate_Count := 2;
               Context.Visible_Candidate_Count := 2;
               Context.Ambiguous_Candidate_Count := 1;
            when Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_No_Profile_Filter |
                 Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_No_Callable_Profile |
                 Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Callable_Has_No_Result =>
               Context.Candidate_Count := 1;
               Context.Visible_Candidate_Count := 1;
               Context.Profile_Mismatch_Count := 1;
            when Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_No_Call_Resolution =>
               Context.Candidate_Count := 0;
               Context.Visible_Candidate_Count := 0;
            when others =>
               Context.Candidate_Count := 1;
               Context.Visible_Candidate_Count := 1;
         end case;
      end if;

      return Context;
   end Context_From_Expected_Filter;

   function Build_Contexts_From_Expected_Call_Filters
     (Filters : Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Model)
      return Overload_Context_Model
   is
      Model : Overload_Context_Model;
      Info  : Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Info;
   begin
      for I in 1 .. Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Count (Filters) loop
         Info := Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_At (Filters, I);
         if Expected_Filter_Selects (Info) then
            if not Selected_Context_Already_Added (Model, Info.Call_Node) then
               Add_Context (Model, Context_From_Expected_Filter (Info));
            end if;
         elsif not Node_Has_Selected_Expected_Filter (Filters, Info.Call_Node) then
            Add_Context (Model, Context_From_Expected_Filter (Info));
         end if;
      end loop;
      return Model;
   end Build_Contexts_From_Expected_Call_Filters;

   function Context_Count (Model : Overload_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Overload_Context_Model;
      Index : Positive) return Overload_Context_Info is
   begin
      if Index > Natural (Model.Contexts.Length) then
         return (others => <>);
      end if;
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Overload_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build
     (Contexts : Overload_Context_Model;
      Rankings : Editor.Ada_Overload_Ranking.Overload_Ranking_Model;
      Wide_Diagnostics : Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Model)
      return Overload_Legality_Model
   is
      Model : Overload_Legality_Model;
      Context : Overload_Context_Info;
      Ranking : Editor.Ada_Overload_Ranking.Overload_Ranking_Info;
      Wide    : Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Info;
   begin
      Model.Result_Fingerprint := Mix
        (Fingerprint (Contexts), Mix
          (Editor.Ada_Overload_Ranking.Fingerprint (Rankings),
           Editor.Ada_Wide_Semantic_Legality_Diagnostics.Fingerprint (Wide_Diagnostics)));
      for I in 1 .. Context_Count (Contexts) loop
         Context := Context_At (Contexts, I);
         Ranking := Editor.Ada_Overload_Ranking.First_For_Node (Rankings, Context.Node);
         Wide := Editor.Ada_Wide_Semantic_Legality_Diagnostics.First_For_Node
           (Wide_Diagnostics, Context.Node);
         Append (Model, Make_Item
           (Context,
            Overload_Legality_Id (Natural (Model.Items.Length) + 1),
            Ranking,
            Wide));
      end loop;
      return Model;
   end Build;

   function Legality_Count (Model : Overload_Legality_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Legality_Count;

   function Legality_At
     (Model : Overload_Legality_Model;
      Index : Positive) return Overload_Legality_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Legality_At;

   function First_For_Node
     (Model : Overload_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Overload_Legality_Info is
   begin
      for Item of Model.Items loop
         if Item.Node = Node then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Overload_Legality_Model;
      Status : Overload_Legality_Status) return Overload_Legality_Result_Set
   is
      Results : Overload_Legality_Result_Set;
   begin
      for Item of Model.Items loop
         if Item.Status = Status then
            Results.Items.Append (Item);
            Results.Fingerprint := Mix (Results.Fingerprint, Item.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Overload_Legality_Model;
      Kind  : Overload_Context_Kind) return Overload_Legality_Result_Set
   is
      Results : Overload_Legality_Result_Set;
   begin
      for Item of Model.Items loop
         if Item.Kind = Kind then
            Results.Items.Append (Item);
            Results.Fingerprint := Mix (Results.Fingerprint, Item.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Kind;

   function Rows_For_Designator
     (Model      : Overload_Legality_Model;
      Designator : String) return Overload_Legality_Result_Set
   is
      Results : Overload_Legality_Result_Set;
      Needle  : constant String := Ada.Characters.Handling.To_Lower (Designator);
   begin
      for Item of Model.Items loop
         if Ada.Characters.Handling.To_Lower (To_String (Item.Designator)) = Needle then
            Results.Items.Append (Item);
            Results.Fingerprint := Mix (Results.Fingerprint, Item.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Designator;

   function Result_Count (Results : Overload_Legality_Result_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Result_Count;

   function Result_At
     (Results : Overload_Legality_Result_Set;
      Index   : Positive) return Overload_Legality_Info is
   begin
      if Index > Natural (Results.Items.Length) then
         return (others => <>);
      end if;
      return Results.Items.Element (Index);
   end Result_At;

   function Count_Status
     (Model  : Overload_Legality_Model;
      Status : Overload_Legality_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for Item of Model.Items loop
         if Item.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind
     (Model : Overload_Legality_Model;
      Kind  : Overload_Context_Kind) return Natural
   is
      Count : Natural := 0;
   begin
      for Item of Model.Items loop
         if Item.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Overload_Legality_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Error_Count (Model : Overload_Legality_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Ambiguous_Count (Model : Overload_Legality_Model) return Natural is
   begin
      return Model.Ambiguous_Total;
   end Ambiguous_Count;

   function Visibility_Error_Count (Model : Overload_Legality_Model) return Natural is
   begin
      return Model.Visibility_Total;
   end Visibility_Error_Count;

   function View_Barrier_Count (Model : Overload_Legality_Model) return Natural is
   begin
      return Model.View_Barrier_Total;
   end View_Barrier_Count;

   function Cross_Unit_Unresolved_Count (Model : Overload_Legality_Model) return Natural is
   begin
      return Model.Cross_Unit_Total;
   end Cross_Unit_Unresolved_Count;

   function Linked_Semantic_Error_Count (Model : Overload_Legality_Model) return Natural is
   begin
      return Model.Linked_Error_Total;
   end Linked_Semantic_Error_Count;

   function Indeterminate_Count (Model : Overload_Legality_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Overload_Legality_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Has_Legality (Info : Overload_Legality_Info) return Boolean is
   begin
      return Info.Id /= No_Overload_Legality
        and then Info.Status /= Overload_Legality_Not_Checked;
   end Has_Legality;

end Editor.Ada_Overload_Resolution_Legality;
