with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Overload_Preference_Legality is

   pragma Suppress (Overflow_Check);

   package ORL renames Editor.Ada_Overload_Resolution_Legality;

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type ORL.Overload_Legality_Id;
   use type ORL.Overload_Legality_Status;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 281) + (B * 43) + 1126) mod 1_000_000_007;
   end Mix;

   function Kind_Slot (Kind : Preference_Context_Kind) return Natural is
   begin
      return Preference_Context_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function Status_Slot (Status : Preference_Legality_Status) return Natural is
   begin
      return Preference_Legality_Status'Pos (Status) + 1;
   end Status_Slot;

   function Overload_Is_Legal
     (Status : ORL.Overload_Legality_Status) return Boolean is
   begin
      return Status in
        ORL.Overload_Legality_Legal_Exact |
        ORL.Overload_Legality_Legal_Expected_Type_Preferred |
        ORL.Overload_Legality_Legal_Universal_Integer_Preferred |
        ORL.Overload_Legality_Legal_Universal_Real_Preferred |
        ORL.Overload_Legality_Legal_Primitive_Operator_Preferred |
        ORL.Overload_Legality_Legal_Implicit_Numeric_Conversion |
        ORL.Overload_Legality_Legal_Class_Wide_Conversion |
        ORL.Overload_Legality_Legal_Access_Conversion |
        ORL.Overload_Legality_Legal_Named_Actual_Profile |
        ORL.Overload_Legality_Legal_Defaulted_Formal_Profile;
   end Overload_Is_Legal;

   function Is_Legal (Status : Preference_Legality_Status) return Boolean is
   begin
      return Status in
        Preference_Legality_Legal_Exact_Profile |
        Preference_Legality_Legal_Direct_Visibility_Preferred |
        Preference_Legality_Legal_Use_Visibility_Preferred |
        Preference_Legality_Legal_Expected_Type_Profile_Preferred |
        Preference_Legality_Legal_Primitive_Operator_Preferred |
        Preference_Legality_Legal_Dispatching_Primitive_Preferred |
        Preference_Legality_Legal_Universal_Integer_Preferred |
        Preference_Legality_Legal_Universal_Real_Preferred |
        Preference_Legality_Legal_Implicit_Conversion_Preferred |
        Preference_Legality_Legal_Class_Wide_Preferred |
        Preference_Legality_Legal_Access_Conversion_Preferred |
        Preference_Legality_Legal_Named_Actual_Profile_Preferred |
        Preference_Legality_Legal_Defaulted_Formal_Profile_Preferred;
   end Is_Legal;

   function Is_Ambiguous (Status : Preference_Legality_Status) return Boolean is
   begin
      return Status in
        Preference_Legality_Ambiguous_Homograph_Tie |
        Preference_Legality_Ambiguous_Visibility_Tie |
        Preference_Legality_Ambiguous_Profile_Tie |
        Preference_Legality_Ambiguous_Expected_Type_Tie |
        Preference_Legality_Ambiguous_Universal_Numeric_Tie |
        Preference_Legality_Ambiguous_Conversion_Tie |
        Preference_Legality_Ambiguous_After_RM_Preferences;
   end Is_Ambiguous;

   function Context_Fingerprint (Info : Preference_Context_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Kind_Slot (Info.Kind));
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Length (Info.Designator) + 1);
      H := Mix (H, Info.Direct_Visibility_Count + 1);
      H := Mix (H, Info.Use_Visibility_Count + 1);
      H := Mix (H, Info.Selected_Profile_Count + 1);
      H := Mix (H, Info.Exact_Profile_Count + 1);
      H := Mix (H, Info.Expected_Type_Profile_Count + 1);
      H := Mix (H, Info.Primitive_Operator_Count + 1);
      H := Mix (H, Info.Dispatching_Primitive_Count + 1);
      H := Mix (H, Info.Universal_Integer_Count + 1);
      H := Mix (H, Info.Universal_Real_Count + 1);
      H := Mix (H, Info.Implicit_Conversion_Count + 1);
      H := Mix (H, Info.Class_Wide_Count + 1);
      H := Mix (H, Info.Access_Conversion_Count + 1);
      H := Mix (H, Info.Named_Actual_Count + 1);
      H := Mix (H, Info.Defaulted_Formal_Count + 1);
      H := Mix (H, Info.Homograph_Tie_Count + 1);
      H := Mix (H, Info.Visibility_Tie_Count + 1);
      H := Mix (H, Info.Profile_Tie_Count + 1);
      H := Mix (H, Info.Expected_Type_Tie_Count + 1);
      H := Mix (H, Info.Universal_Numeric_Tie_Count + 1);
      H := Mix (H, Info.Conversion_Tie_Count + 1);
      H := Mix (H, Info.Remaining_Ambiguous_Count + 1);
      H := Mix (H, Info.Legal_Candidate_Count + 1);
      H := Mix (H, Info.Rejected_Candidate_Count + 1);
      H := Mix (H, Info.Start_Line);
      H := Mix (H, Info.End_Line);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Context_Fingerprint;

   function Legality_Fingerprint (Info : Preference_Legality_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Kind_Slot (Info.Kind));
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Status_Slot (Info.Status));
      H := Mix (H, Natural (Info.Linked_Overload) + 1);
      H := Mix (H, ORL.Overload_Legality_Status'Pos (Info.Linked_Overload_Status) + 1);
      H := Mix (H, Info.Legal_Candidate_Count + 1);
      H := Mix (H, Info.Selected_Candidate_Count + 1);
      H := Mix (H, Info.Rejected_Candidate_Count + 1);
      H := Mix (H, Info.Ambiguous_Candidate_Count + 1);
      H := Mix (H, Info.Start_Line);
      H := Mix (H, Info.End_Line);
      H := Mix (H, Info.Source_Fingerprint + 1);
      H := Mix (H, Info.Overload_Fingerprint + 1);
      H := Mix (H, Length (Info.Message) + Length (Info.Detail) + 1);
      return H;
   end Legality_Fingerprint;

   function Message_For (Status : Preference_Legality_Status) return String is
   begin
      case Status is
         when Preference_Legality_Legal_Exact_Profile =>
            return "Ada overload preferences selected the exact profile";
         when Preference_Legality_Legal_Direct_Visibility_Preferred =>
            return "direct visibility preferred the selected overload";
         when Preference_Legality_Legal_Use_Visibility_Preferred =>
            return "use visibility supplied the selected overload after direct candidates were exhausted";
         when Preference_Legality_Legal_Expected_Type_Profile_Preferred =>
            return "expected type and profile evidence preferred the selected overload";
         when Preference_Legality_Legal_Primitive_Operator_Preferred =>
            return "primitive operator preference selected the overload";
         when Preference_Legality_Legal_Dispatching_Primitive_Preferred =>
            return "dispatching primitive preference selected the overload";
         when Preference_Legality_Legal_Universal_Integer_Preferred =>
            return "universal integer preference selected the overload";
         when Preference_Legality_Legal_Universal_Real_Preferred =>
            return "universal real preference selected the overload";
         when Preference_Legality_Legal_Implicit_Conversion_Preferred =>
            return "implicit conversion preference selected the overload";
         when Preference_Legality_Legal_Class_Wide_Preferred =>
            return "class-wide conversion preference selected the overload";
         when Preference_Legality_Legal_Access_Conversion_Preferred =>
            return "access conversion preference selected the overload";
         when Preference_Legality_Legal_Named_Actual_Profile_Preferred =>
            return "named actual/profile preference selected the overload";
         when Preference_Legality_Legal_Defaulted_Formal_Profile_Preferred =>
            return "defaulted formal/profile preference selected the overload";
         when Preference_Legality_Ambiguous_Homograph_Tie =>
            return "homograph candidates remain tied after overload preference checks";
         when Preference_Legality_Ambiguous_Visibility_Tie =>
            return "visibility tiers leave multiple overload candidates tied";
         when Preference_Legality_Ambiguous_Profile_Tie =>
            return "profile evidence leaves multiple overload candidates tied";
         when Preference_Legality_Ambiguous_Expected_Type_Tie =>
            return "expected-type evidence leaves multiple overload candidates tied";
         when Preference_Legality_Ambiguous_Universal_Numeric_Tie =>
            return "universal numeric preference leaves multiple overload candidates tied";
         when Preference_Legality_Ambiguous_Conversion_Tie =>
            return "conversion preferences leave multiple overload candidates tied";
         when Preference_Legality_Ambiguous_After_RM_Preferences =>
            return "overload resolution remains ambiguous after Ada preference ordering";
         when Preference_Legality_No_Legal_Overload_Input =>
            return "no legal overload row is available for preference refinement";
         when Preference_Legality_Linked_Overload_Legality_Error =>
            return "linked overload legality error prevents preference refinement";
         when Preference_Legality_Unknown =>
            return "overload preference legality is unknown";
         when Preference_Legality_Indeterminate =>
            return "overload preference legality is indeterminate";
         when Preference_Legality_Not_Checked =>
            return "overload preference legality was not checked";
      end case;
   end Message_For;

   function Classify
     (Context  : Preference_Context_Info;
      Overload : ORL.Overload_Legality_Info) return Preference_Legality_Status
   is
      Has_Overload : constant Boolean := ORL.Has_Legality (Overload);
   begin
      if not Has_Overload then
         return Preference_Legality_No_Legal_Overload_Input;
      elsif Context.Homograph_Tie_Count > 0 then
         return Preference_Legality_Ambiguous_Homograph_Tie;
      elsif Context.Visibility_Tie_Count > 0 then
         return Preference_Legality_Ambiguous_Visibility_Tie;
      elsif Context.Profile_Tie_Count > 0 then
         return Preference_Legality_Ambiguous_Profile_Tie;
      elsif Context.Expected_Type_Tie_Count > 0 then
         return Preference_Legality_Ambiguous_Expected_Type_Tie;
      elsif Context.Universal_Numeric_Tie_Count > 0 then
         return Preference_Legality_Ambiguous_Universal_Numeric_Tie;
      elsif Context.Conversion_Tie_Count > 0 then
         return Preference_Legality_Ambiguous_Conversion_Tie;
      elsif Context.Remaining_Ambiguous_Count > 0 then
         return Preference_Legality_Ambiguous_After_RM_Preferences;
      elsif not Overload_Is_Legal (Overload.Status) then
         return Preference_Legality_Linked_Overload_Legality_Error;
      elsif Context.Direct_Visibility_Count = 1 and then Context.Use_Visibility_Count > 0 then
         return Preference_Legality_Legal_Direct_Visibility_Preferred;
      elsif Context.Use_Visibility_Count = 1 and then Context.Direct_Visibility_Count = 0 then
         return Preference_Legality_Legal_Use_Visibility_Preferred;
      elsif Context.Expected_Type_Profile_Count = 1 then
         return Preference_Legality_Legal_Expected_Type_Profile_Preferred;
      elsif Context.Dispatching_Primitive_Count = 1 then
         return Preference_Legality_Legal_Dispatching_Primitive_Preferred;
      elsif Context.Primitive_Operator_Count = 1 then
         return Preference_Legality_Legal_Primitive_Operator_Preferred;
      elsif Context.Universal_Integer_Count = 1 and then Context.Universal_Real_Count = 0 then
         return Preference_Legality_Legal_Universal_Integer_Preferred;
      elsif Context.Universal_Real_Count = 1 and then Context.Universal_Integer_Count = 0 then
         return Preference_Legality_Legal_Universal_Real_Preferred;
      elsif Context.Implicit_Conversion_Count = 1 then
         return Preference_Legality_Legal_Implicit_Conversion_Preferred;
      elsif Context.Class_Wide_Count = 1 then
         return Preference_Legality_Legal_Class_Wide_Preferred;
      elsif Context.Access_Conversion_Count = 1 then
         return Preference_Legality_Legal_Access_Conversion_Preferred;
      elsif Context.Named_Actual_Count = 1 then
         return Preference_Legality_Legal_Named_Actual_Profile_Preferred;
      elsif Context.Defaulted_Formal_Count = 1 then
         return Preference_Legality_Legal_Defaulted_Formal_Profile_Preferred;
      elsif Context.Exact_Profile_Count = 1 or else Overload.Status = ORL.Overload_Legality_Legal_Exact then
         return Preference_Legality_Legal_Exact_Profile;
      elsif Overload.Status = ORL.Overload_Legality_Legal_Expected_Type_Preferred then
         return Preference_Legality_Legal_Expected_Type_Profile_Preferred;
      elsif Overload.Status = ORL.Overload_Legality_Legal_Primitive_Operator_Preferred then
         return Preference_Legality_Legal_Primitive_Operator_Preferred;
      elsif Overload.Status = ORL.Overload_Legality_Legal_Universal_Integer_Preferred then
         return Preference_Legality_Legal_Universal_Integer_Preferred;
      elsif Overload.Status = ORL.Overload_Legality_Legal_Universal_Real_Preferred then
         return Preference_Legality_Legal_Universal_Real_Preferred;
      elsif Overload.Status = ORL.Overload_Legality_Legal_Implicit_Numeric_Conversion then
         return Preference_Legality_Legal_Implicit_Conversion_Preferred;
      elsif Overload.Status = ORL.Overload_Legality_Legal_Class_Wide_Conversion then
         return Preference_Legality_Legal_Class_Wide_Preferred;
      elsif Overload.Status = ORL.Overload_Legality_Legal_Access_Conversion then
         return Preference_Legality_Legal_Access_Conversion_Preferred;
      elsif Overload.Status = ORL.Overload_Legality_Legal_Named_Actual_Profile then
         return Preference_Legality_Legal_Named_Actual_Profile_Preferred;
      elsif Overload.Status = ORL.Overload_Legality_Legal_Defaulted_Formal_Profile then
         return Preference_Legality_Legal_Defaulted_Formal_Profile_Preferred;
      end if;

      return Preference_Legality_Indeterminate;
   end Classify;

   function Detail_For (Context : Preference_Context_Info) return String is
   begin
      return
        "legal=" & Natural'Image (Context.Legal_Candidate_Count) &
        " selected=" & Natural'Image (Context.Selected_Profile_Count) &
        " direct=" & Natural'Image (Context.Direct_Visibility_Count) &
        " use=" & Natural'Image (Context.Use_Visibility_Count) &
        " expected=" & Natural'Image (Context.Expected_Type_Profile_Count) &
        " primitive=" & Natural'Image (Context.Primitive_Operator_Count) &
        " dispatching=" & Natural'Image (Context.Dispatching_Primitive_Count) &
        " universal_integer=" & Natural'Image (Context.Universal_Integer_Count) &
        " universal_real=" & Natural'Image (Context.Universal_Real_Count) &
        " conversions=" & Natural'Image
          (Context.Implicit_Conversion_Count + Context.Class_Wide_Count + Context.Access_Conversion_Count) &
        " ties=" & Natural'Image
          (Context.Homograph_Tie_Count + Context.Visibility_Tie_Count + Context.Profile_Tie_Count +
           Context.Expected_Type_Tie_Count + Context.Universal_Numeric_Tie_Count +
           Context.Conversion_Tie_Count + Context.Remaining_Ambiguous_Count);
   end Detail_For;

   function Make_Item
     (Context  : Preference_Context_Info;
      Id       : Preference_Legality_Id;
      Overload : ORL.Overload_Legality_Info) return Preference_Legality_Info
   is
      Result : Preference_Legality_Info;
   begin
      Result.Id := Id;
      Result.Context := Context.Id;
      Result.Kind := Context.Kind;
      Result.Node := Context.Node;
      Result.Designator := Context.Designator;
      Result.Status := Classify (Context, Overload);
      Result.Message := To_Unbounded_String (Message_For (Result.Status));
      Result.Detail := To_Unbounded_String (Detail_For (Context));
      Result.Linked_Overload := Overload.Id;
      Result.Linked_Overload_Status := Overload.Status;
      Result.Legal_Candidate_Count := Context.Legal_Candidate_Count;
      Result.Selected_Candidate_Count := Context.Selected_Profile_Count;
      Result.Rejected_Candidate_Count := Context.Rejected_Candidate_Count;
      Result.Ambiguous_Candidate_Count :=
        Context.Homograph_Tie_Count + Context.Visibility_Tie_Count + Context.Profile_Tie_Count +
        Context.Expected_Type_Tie_Count + Context.Universal_Numeric_Tie_Count +
        Context.Conversion_Tie_Count + Context.Remaining_Ambiguous_Count;
      Result.Start_Line := Context.Start_Line;
      Result.Start_Column := Context.Start_Column;
      Result.End_Line := Context.End_Line;
      Result.End_Column := Context.End_Column;
      Result.Source_Fingerprint := Context.Source_Fingerprint;
      Result.Overload_Fingerprint := Overload.Fingerprint;
      Result.Fingerprint := Legality_Fingerprint (Result);
      return Result;
   end Make_Item;

   procedure Append
     (Model : in out Preference_Legality_Model;
      Info  : Preference_Legality_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint);
      if Is_Legal (Info.Status) then
         Model.Legal_Total := Model.Legal_Total + 1;
      elsif Is_Ambiguous (Info.Status) then
         Model.Ambiguous_Total := Model.Ambiguous_Total + 1;
      elsif Info.Status = Preference_Legality_Linked_Overload_Legality_Error or else
            Info.Status = Preference_Legality_No_Legal_Overload_Input
      then
         Model.Linked_Error_Total := Model.Linked_Error_Total + 1;
      elsif Info.Status = Preference_Legality_Indeterminate or else
            Info.Status = Preference_Legality_Unknown
      then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
   end Append;

   procedure Clear (Model : in out Preference_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Preference_Context_Model;
      Info  : Preference_Context_Info) is
      Item : Preference_Context_Info := Info;
   begin
      if Item.Id = No_Preference_Context then
         Item.Id := Preference_Context_Id (Natural (Model.Contexts.Length) + 1);
      end if;
      Model.Contexts.Append (Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Context_Fingerprint (Item));
   end Add_Context;

   function Context_Count (Model : Preference_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Preference_Context_Model;
      Index : Positive) return Preference_Context_Info is
   begin
      if Index > Natural (Model.Contexts.Length) then
         return (others => <>);
      end if;
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Preference_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build
     (Overloads : ORL.Overload_Legality_Model;
      Contexts  : Preference_Context_Model) return Preference_Legality_Model
   is
      Model : Preference_Legality_Model;
      Context : Preference_Context_Info;
      Overload : ORL.Overload_Legality_Info;
   begin
      Model.Result_Fingerprint := Mix (Fingerprint (Contexts), ORL.Fingerprint (Overloads));
      for I in 1 .. Context_Count (Contexts) loop
         Context := Context_At (Contexts, I);
         Overload := ORL.First_For_Node (Overloads, Context.Node);
         Append
           (Model,
            Make_Item
              (Context,
               Preference_Legality_Id (Natural (Model.Items.Length) + 1),
               Overload));
      end loop;
      return Model;
   end Build;

   function Context_Kind_For
     (Kind : ORL.Overload_Context_Kind) return Preference_Context_Kind is
   begin
      case Kind is
         when ORL.Overload_Context_Call =>
            return Preference_Context_Call;
         when ORL.Overload_Context_Operator =>
            return Preference_Context_Operator;
         when ORL.Overload_Context_Dispatching_Call =>
            return Preference_Context_Dispatching_Call;
         when ORL.Overload_Context_Attribute_Call =>
            return Preference_Context_Attribute_Call;
         when ORL.Overload_Context_Generic_Actual_Subprogram =>
            return Preference_Context_Generic_Actual_Subprogram;
         when ORL.Overload_Context_Unknown =>
            return Preference_Context_Unknown;
      end case;
   end Context_Kind_For;

   function Build_Contexts_From_Overload_Legality
     (Overloads : ORL.Overload_Legality_Model) return Preference_Context_Model
   is
      Contexts : Preference_Context_Model;
   begin
      for Index in 1 .. ORL.Legality_Count (Overloads) loop
         declare
            O : constant ORL.Overload_Legality_Info :=
              ORL.Legality_At (Overloads, Index);
            C : Preference_Context_Info;
         begin
            if ORL.Has_Legality (O) then
               C.Id := Preference_Context_Id (Natural (O.Id));
               C.Kind := Context_Kind_For (O.Kind);
               C.Node := O.Node;
               C.Designator := O.Designator;
               C.Legal_Candidate_Count := O.Selected_Count;
               C.Selected_Profile_Count := O.Selected_Count;
               C.Rejected_Candidate_Count := O.Rejected_Count;
               C.Start_Line := O.Start_Line;
               C.Start_Column := O.Start_Column;
               C.End_Line := O.End_Line;
               C.End_Column := O.End_Column;
               C.Source_Fingerprint := O.Fingerprint;

               case O.Status is
                  when ORL.Overload_Legality_Legal_Exact =>
                     C.Exact_Profile_Count := O.Selected_Count;
                  when ORL.Overload_Legality_Legal_Expected_Type_Preferred =>
                     C.Expected_Type_Profile_Count := O.Selected_Count;
                  when ORL.Overload_Legality_Legal_Universal_Integer_Preferred =>
                     C.Universal_Integer_Count := O.Selected_Count;
                  when ORL.Overload_Legality_Legal_Universal_Real_Preferred =>
                     C.Universal_Real_Count := O.Selected_Count;
                  when ORL.Overload_Legality_Legal_Primitive_Operator_Preferred =>
                     C.Primitive_Operator_Count := O.Selected_Count;
                  when ORL.Overload_Legality_Legal_Implicit_Numeric_Conversion =>
                     C.Implicit_Conversion_Count := O.Selected_Count;
                  when ORL.Overload_Legality_Legal_Class_Wide_Conversion =>
                     C.Class_Wide_Count := O.Selected_Count;
                  when ORL.Overload_Legality_Legal_Access_Conversion =>
                     C.Access_Conversion_Count := O.Selected_Count;
                  when ORL.Overload_Legality_Legal_Named_Actual_Profile =>
                     C.Named_Actual_Count := O.Selected_Count;
                  when ORL.Overload_Legality_Legal_Defaulted_Formal_Profile =>
                     C.Defaulted_Formal_Count := O.Selected_Count;
                  when ORL.Overload_Legality_Ambiguous_After_Preference =>
                     C.Remaining_Ambiguous_Count := O.Candidate_Count;
                     C.Selected_Profile_Count := O.Candidate_Count;
                  when ORL.Overload_Legality_Profile_Mismatch =>
                     C.Profile_Tie_Count := O.Candidate_Count;
                  when ORL.Overload_Legality_Actual_Type_Mismatch =>
                     C.Expected_Type_Tie_Count := O.Candidate_Count;
                  when others =>
                     null;
               end case;

               Add_Context (Contexts, C);
            end if;
         end;
      end loop;
      return Contexts;
   end Build_Contexts_From_Overload_Legality;

   function Legality_Count (Model : Preference_Legality_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Legality_Count;

   function Legality_At
     (Model : Preference_Legality_Model;
      Index : Positive) return Preference_Legality_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Legality_At;

   function First_For_Node
     (Model : Preference_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Preference_Legality_Info is
   begin
      for Item of Model.Items loop
         if Item.Node = Node then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Preference_Legality_Model;
      Status : Preference_Legality_Status) return Preference_Legality_Result_Set
   is
      Results : Preference_Legality_Result_Set;
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
     (Model : Preference_Legality_Model;
      Kind  : Preference_Context_Kind) return Preference_Legality_Result_Set
   is
      Results : Preference_Legality_Result_Set;
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
     (Model      : Preference_Legality_Model;
      Designator : String) return Preference_Legality_Result_Set
   is
      Results : Preference_Legality_Result_Set;
   begin
      for Item of Model.Items loop
         if To_String (Item.Designator) = Designator then
            Results.Items.Append (Item);
            Results.Fingerprint := Mix (Results.Fingerprint, Item.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Designator;

   function Result_Count (Results : Preference_Legality_Result_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Result_Count;

   function Result_At
     (Results : Preference_Legality_Result_Set;
      Index   : Positive) return Preference_Legality_Info is
   begin
      if Index > Natural (Results.Items.Length) then
         return (others => <>);
      end if;
      return Results.Items.Element (Index);
   end Result_At;

   function Count_Status
     (Model  : Preference_Legality_Model;
      Status : Preference_Legality_Status) return Natural
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
     (Model : Preference_Legality_Model;
      Kind  : Preference_Context_Kind) return Natural
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

   function Legal_Count (Model : Preference_Legality_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Ambiguous_Count (Model : Preference_Legality_Model) return Natural is
   begin
      return Model.Ambiguous_Total;
   end Ambiguous_Count;

   function Linked_Overload_Error_Count (Model : Preference_Legality_Model) return Natural is
   begin
      return Model.Linked_Error_Total;
   end Linked_Overload_Error_Count;

   function Indeterminate_Count (Model : Preference_Legality_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Preference_Legality_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Has_Legality (Info : Preference_Legality_Info) return Boolean is
   begin
      return Info.Id /= No_Preference_Legality;
   end Has_Legality;

end Editor.Ada_Overload_Preference_Legality;
