with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Freezing_Representation_Vertical_Slice_Legality is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 719) + 1299) mod 1_000_000_007;
   end Mix;

   function Is_Representation (Kind : Clause_Kind) return Boolean is
   begin
      return Kind in Clause_Record_Representation
        | Clause_Enumeration_Representation
        | Clause_At_Address
        | Clause_Size
        | Clause_Alignment
        | Clause_Bit_Order
        | Clause_Scalar_Storage_Order
        | Clause_Stream_Attribute
        | Clause_Convention
        | Clause_Operational_Attribute;
   end Is_Representation;

   function Is_Legal (Status : Freezing_Status) return Boolean is
   begin
      return Status in Freezing_Legal_Before_Point
        | Freezing_Legal_Full_View
        | Freezing_Legal_Generic_Pre_Freeze
        | Freezing_Legal_Operational_Inheritance;
   end Is_Legal;

   procedure Clear (Model : in out Type_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Clause_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Type (Model : in out Type_Model; Info : Type_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint,
         Natural (Info.Id) + Info.Declaration_Order + Info.Freezing_Order
         + Info.Representation_Fingerprint + Info.Source_Fingerprint);
   end Add_Type;

   procedure Add_Clause (Model : in out Clause_Model; Info : Clause_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint,
         Natural (Info.Id) + Natural (Info.Target) + Info.Clause_Order
         + Info.Source_Fingerprint + Info.Clause_Fingerprint);
   end Add_Clause;

   function Find_Type (Types : Type_Model; Id : Type_Id) return Type_Info is
   begin
      for T of Types.Items loop
         if T.Id = Id then
            return T;
         end if;
      end loop;
      return (others => <>);
   end Find_Type;

   function Status_For (R : Result_Info; T : Type_Info; C : Clause_Info)
      return Freezing_Status is
   begin
      if R.Missing_Target_Blockers > 0 then
         return Freezing_Missing_Target;
      elsif R.Fingerprint_Blockers > 0 then
         return Freezing_Source_Fingerprint_Mismatch;
      elsif R.Late_Blockers > 0 then
         return Freezing_Late_Representation_Clause;
      elsif R.View_Blockers > 0 then
         if C.Kind = Clause_Stream_Attribute and then C.Uses_Limited_View then
            return Freezing_Stream_Limited_View_Barrier;
         else
            return Freezing_Private_View_Barrier;
         end if;
      elsif R.Generic_Blockers > 0 then
         return Freezing_Generic_Formal_Barrier;
      elsif R.Operational_Blockers > 0 then
         return Freezing_Inherited_Operational_Conflict;
      elsif T.Has_Discriminants and then C.Discriminant_Dependent
        and then R.Layout_Blockers > 0
      then
         return Freezing_Discriminant_Layout_Conflict;
      elsif T.Has_Variants and then C.Variant_Dependent
        and then R.Layout_Blockers > 0
      then
         return Freezing_Variant_Layout_Conflict;
      elsif T.Has_Controlled_Or_Finalized_Component and then C.Finalization_Sensitive
        and then R.Layout_Blockers > 0
      then
         return Freezing_Finalization_Layout_Conflict;
      elsif R.Address_Size_Alignment_Blockers > 0 then
         return Freezing_Address_Size_Alignment_Conflict;
      elsif C.Inherited_Operational or else C.Overrides_Inherited_Operational then
         return Freezing_Legal_Operational_Inheritance;
      elsif T.Generic_Formal or else C.In_Generic_Template then
         return Freezing_Legal_Generic_Pre_Freeze;
      elsif C.Applies_To_Full_View then
         return Freezing_Legal_Full_View;
      end if;
      return Freezing_Legal_Before_Point;
   end Status_For;

   function Build
     (Types   : Type_Model;
      Clauses : Clause_Model) return Result_Model
   is
      Result : Result_Model;
      Next_Id : Natural := 1;
   begin
      for C of Clauses.Items loop
         declare
            T : constant Type_Info := Find_Type (Types, C.Target);
            R : Result_Info;
         begin
            R.Id := Result_Id (Next_Id);
            Next_Id := Next_Id + 1;
            R.Clause := C.Id;
            R.Target := C.Target;
            R.Node := C.Node;
            R.Source_Fingerprint := C.Source_Fingerprint;
            R.Clause_Fingerprint := C.Clause_Fingerprint;

            if T.Id = No_Type then
               R.Missing_Target_Blockers := 1;
            else
               if Is_Representation (C.Kind)
                 and then T.Freezing_Order > 0
                 and then C.Clause_Order >= T.Freezing_Order
               then
                  R.Late_Blockers := R.Late_Blockers + 1;
               end if;

               if C.Requires_Full_View and then
                 (T.View in View_Private_Partial | View_Limited_Private
                  or else not T.Full_View_Available)
               then
                  R.View_Blockers := R.View_Blockers + 1;
               end if;

               if C.Applies_To_Full_View and then T.View = View_Private_Partial then
                  R.View_Blockers := R.View_Blockers + 1;
               end if;

               if C.Kind = Clause_Stream_Attribute and then
                 (C.Uses_Limited_View or else T.View = View_Limited_Private)
               then
                  R.View_Blockers := R.View_Blockers + 1;
                  R.Stream_Blockers := R.Stream_Blockers + 1;
               end if;

               if (T.Generic_Formal or else T.View = View_Generic_Formal
                   or else C.In_Generic_Template)
                 and then (T.Generic_Actual_Frozen or else
                            (T.Freezing_Order > 0 and then C.Clause_Order >= T.Freezing_Order))
               then
                  R.Generic_Blockers := R.Generic_Blockers + 1;
               end if;

               if C.Inherited_Operational and then C.Overrides_Inherited_Operational then
                  R.Operational_Blockers := R.Operational_Blockers + 1;
               end if;

               if C.Discriminant_Dependent and then T.Has_Discriminants
                 and then C.Kind = Clause_Record_Representation
               then
                  R.Layout_Blockers := R.Layout_Blockers + 1;
               end if;

               if C.Variant_Dependent and then T.Has_Variants
                 and then C.Kind = Clause_Record_Representation
               then
                  R.Layout_Blockers := R.Layout_Blockers + 1;
               end if;

               if C.Finalization_Sensitive
                 and then T.Has_Controlled_Or_Finalized_Component
                 and then C.Kind in Clause_Record_Representation | Clause_Size | Clause_Alignment
               then
                  R.Layout_Blockers := R.Layout_Blockers + 1;
               end if;

               if C.Address_Size_Alignment_Sensitive
                 and then C.Kind in Clause_At_Address | Clause_Size | Clause_Alignment
                 and then T.Has_Controlled_Or_Finalized_Component
               then
                  R.Address_Size_Alignment_Blockers :=
                    R.Address_Size_Alignment_Blockers + 1;
               end if;

               if T.Source_Fingerprint = 0 or else C.Source_Fingerprint = 0
                 or else T.Representation_Fingerprint = 0
                 or else C.Clause_Fingerprint = 0
               then
                  R.Fingerprint_Blockers := R.Fingerprint_Blockers + 1;
               end if;
            end if;

            declare
               Total_Blockers : constant Natural :=
                 R.Late_Blockers + R.View_Blockers + R.Generic_Blockers
                 + R.Operational_Blockers + R.Layout_Blockers
                 + R.Address_Size_Alignment_Blockers
                 + R.Fingerprint_Blockers + R.Missing_Target_Blockers;
            begin
               if Total_Blockers > 1
                 and then R.Fingerprint_Blockers = 0
                 and then R.Missing_Target_Blockers = 0
               then
                  R.Status := Freezing_Multiple_Blockers;
               else
                  R.Status := Status_For (R, T, C);
               end if;
            end;

            if Is_Legal (R.Status) then
               R.Message := To_Unbounded_String ("representation clause accepted before freezing");
               Result.Legal_Total := Result.Legal_Total + 1;
            else
               R.Message := To_Unbounded_String ("representation clause rejected by freezing legality");
               Result.Error_Total := Result.Error_Total + 1;
            end if;

            R.Detail := To_Unbounded_String
              ("late=" & Natural'Image (R.Late_Blockers)
               & " view=" & Natural'Image (R.View_Blockers)
               & " generic=" & Natural'Image (R.Generic_Blockers)
               & " layout=" & Natural'Image (R.Layout_Blockers));
            R.Fingerprint := Mix
              (R.Source_Fingerprint + R.Clause_Fingerprint,
               Natural (Freezing_Status'Pos (R.Status)) + R.Late_Blockers
               + R.View_Blockers + R.Generic_Blockers + R.Operational_Blockers
               + R.Layout_Blockers + R.Stream_Blockers
               + R.Address_Size_Alignment_Blockers + R.Fingerprint_Blockers
               + R.Missing_Target_Blockers);
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, R.Fingerprint);
            Result.Items.Append (R);
         end;
      end loop;
      return Result;
   end Build;

   function Type_Count (Model : Type_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Type_Count;

   function Clause_Count (Model : Clause_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Clause_Count;

   function Result_Count (Model : Result_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Result_Count;

   function Result_At (Model : Result_Model; Index : Positive) return Result_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items (Index);
   end Result_At;

   function First_For_Node
     (Model : Result_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Result_Info is
   begin
      for R of Model.Items loop
         if R.Node = Node then
            return R;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Count_Status (Model : Result_Model; Status : Freezing_Status) return Natural is
      Count : Natural := 0;
   begin
      for R of Model.Items loop
         if R.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Legal_Count (Model : Result_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Error_Count (Model : Result_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Fingerprint (Model : Result_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Has_Result (Info : Result_Info) return Boolean is
   begin
      return Info.Id /= No_Result;
   end Has_Result;

end Editor.Ada_Freezing_Representation_Vertical_Slice_Legality;
