with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Enumeration_Representation_Vertical_Slice_Legality is

   pragma Suppress (Overflow_Check);

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 31337) + 1323) mod 1_000_000_007;
   end Mix;

   function Pow2 (Bits : Natural) return Natural is
      Result : Natural := 1;
   begin
      if Bits = 0 or else Bits >= Natural'Size then
         return 0;
      end if;
      for I in 1 .. Bits loop
         pragma Unreferenced (I);
         Result := Result * 2;
      end loop;
      return Result;
   end Pow2;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.Missing_Type_Blockers
        + R.Missing_Literal_Blockers
        + R.Private_View_Blockers
        + R.Limited_View_Blockers
        + R.Incomplete_View_Blockers
        + R.Generic_Formal_Blockers
        + R.Late_Freezing_Blockers
        + R.Incomplete_Clause_Blockers
        + R.Extra_Literal_Blockers
        + R.Duplicate_Literal_Blockers
        + R.Duplicate_Code_Blockers
        + R.Non_Static_Code_Blockers
        + R.Negative_Code_Blockers
        + R.Code_Size_Blockers
        + R.Non_Monotonic_Blockers
        + R.Stream_Profile_Blockers
        + R.Representation_Blockers
        + R.Source_Fingerprint_Blockers
        + R.Type_Fingerprint_Blockers
        + R.Clause_Fingerprint_Blockers;
   end Blocker_Count;

   function Status_For (R : Result_Info) return Enum_Status is
      Blocks : constant Natural := Blocker_Count (R);
   begin
      if Blocks > 1 then
         return Enum_Multiple_Blockers;
      elsif R.Missing_Type_Blockers > 0 then
         return Enum_Missing_Type;
      elsif R.Missing_Literal_Blockers > 0 then
         return Enum_Missing_Literal;
      elsif R.Private_View_Blockers > 0 then
         return Enum_Private_View_Barrier;
      elsif R.Limited_View_Blockers > 0 then
         return Enum_Limited_View_Barrier;
      elsif R.Incomplete_View_Blockers > 0 then
         return Enum_Incomplete_View_Barrier;
      elsif R.Generic_Formal_Blockers > 0 then
         return Enum_Generic_Formal_Barrier;
      elsif R.Late_Freezing_Blockers > 0 then
         return Enum_Late_After_Freezing;
      elsif R.Incomplete_Clause_Blockers > 0 then
         return Enum_Incomplete_Clause;
      elsif R.Extra_Literal_Blockers > 0 then
         return Enum_Extra_Literal;
      elsif R.Duplicate_Literal_Blockers > 0 then
         return Enum_Duplicate_Literal;
      elsif R.Duplicate_Code_Blockers > 0 then
         return Enum_Duplicate_Code;
      elsif R.Non_Static_Code_Blockers > 0 then
         return Enum_Non_Static_Code;
      elsif R.Negative_Code_Blockers > 0 then
         return Enum_Negative_Code;
      elsif R.Code_Size_Blockers > 0 then
         return Enum_Code_Out_Of_Size;
      elsif R.Non_Monotonic_Blockers > 0 then
         return Enum_Non_Monotonic_Code;
      elsif R.Stream_Profile_Blockers > 0 then
         return Enum_Stream_Profile_Conflict;
      elsif R.Representation_Blockers > 0 then
         return Enum_Representation_Conflict;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return Enum_Source_Fingerprint_Mismatch;
      elsif R.Type_Fingerprint_Blockers > 0 then
         return Enum_Type_Fingerprint_Mismatch;
      elsif R.Clause_Fingerprint_Blockers > 0 then
         return Enum_Clause_Fingerprint_Mismatch;
      elsif Blocks = 0 then
         return Enum_Legal;
      else
         return Enum_Indeterminate;
      end if;
   end Status_For;

   function Find_Type (Types : Enum_Type_Model; Id : Enum_Type_Id) return Enum_Type_Info is
   begin
      for T of Types.Items loop
         if T.Id = Id then
            return T;
         end if;
      end loop;
      return (others => <>);
   end Find_Type;

   function Find_Literal (Literals : Literal_Model; Id : Literal_Id) return Literal_Info is
   begin
      for L of Literals.Items loop
         if L.Id = Id then
            return L;
         end if;
      end loop;
      return (others => <>);
   end Find_Literal;

   function Has_Duplicate_Literal_Before
     (Items : Clause_Model; Item : Representation_Item_Info) return Boolean is
   begin
      for Other of Items.Items loop
         exit when Other.Id = Item.Id;
         if Other.Enum_Type = Item.Enum_Type and then Other.Literal = Item.Literal then
            return True;
         end if;
      end loop;
      return False;
   end Has_Duplicate_Literal_Before;

   function Has_Duplicate_Code_Before
     (Items : Clause_Model; Item : Representation_Item_Info) return Boolean is
   begin
      for Other of Items.Items loop
         exit when Other.Id = Item.Id;
         if Other.Enum_Type = Item.Enum_Type
           and then Other.Code = Item.Code
           and then Other.Code_Static
           and then Item.Code_Static
         then
            return True;
         end if;
      end loop;
      return False;
   end Has_Duplicate_Code_Before;

   function Previous_Code
     (Items : Clause_Model; Literals : Literal_Model; Item : Representation_Item_Info) return Integer is
      Lit : constant Literal_Info := Find_Literal (Literals, Item.Literal);
      Best_Order : Natural := 0;
      Best_Code : Integer := Integer'First;
   begin
      for Other of Items.Items loop
         exit when Other.Id = Item.Id;
         if Other.Enum_Type = Item.Enum_Type and then Other.Code_Static then
            declare
               OL : constant Literal_Info := Find_Literal (Literals, Other.Literal);
            begin
               if OL.Id /= No_Literal and then Lit.Id /= No_Literal
                 and then OL.Declaration_Order < Lit.Declaration_Order
                 and then OL.Declaration_Order >= Best_Order
               then
                  Best_Order := OL.Declaration_Order;
                  Best_Code := Other.Code;
               end if;
            end;
         end if;
      end loop;
      return Best_Code;
   end Previous_Code;

   function Clause_Count_For (Items : Clause_Model; T : Enum_Type_Id) return Natural is
      Count : Natural := 0;
   begin
      for I of Items.Items loop
         if I.Enum_Type = T then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Clause_Count_For;

   procedure Clear (Model : in out Enum_Type_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Literal_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Clause_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Type (Model : in out Enum_Type_Model; Info : Enum_Type_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Type_Fingerprint);
   end Add_Type;

   procedure Add_Literal (Model : in out Literal_Model; Info : Literal_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Enum_Type));
   end Add_Literal;

   procedure Add_Item (Model : in out Clause_Model; Info : Representation_Item_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Clause_Fingerprint);
   end Add_Item;

   function Build
     (Types : Enum_Type_Model;
      Literals : Literal_Model;
      Items : Clause_Model) return Result_Model
   is
      Results : Result_Model;
      Next_Id : Natural := 1;
   begin
      for I of Items.Items loop
         declare
            T : constant Enum_Type_Info := Find_Type (Types, I.Enum_Type);
            L : constant Literal_Info := Find_Literal (Literals, I.Literal);
            R : Result_Info;
            Limit : constant Natural := (if T.Size_Bits = 0 then 0 else Pow2 (T.Size_Bits));
         begin
            R.Id := Result_Id (Next_Id);
            Next_Id := Next_Id + 1;
            R.Clause := I.Id;
            R.Enum_Type := I.Enum_Type;
            R.Literal := I.Literal;

            if T.Id = No_Enum_Type then
               R.Missing_Type_Blockers := 1;
            else
               case T.View is
                  when View_Private => R.Private_View_Blockers := 1;
                  when View_Limited => R.Limited_View_Blockers := 1;
                  when View_Incomplete => R.Incomplete_View_Blockers := 1;
                  when View_Generic_Formal => R.Generic_Formal_Blockers := 1;
                  when others => null;
               end case;

               if T.Frozen and then I.Placement_Order >= T.Freeze_Order then
                  R.Late_Freezing_Blockers := 1;
               end if;
               if Clause_Count_For (Items, T.Id) < T.Literal_Count then
                  R.Incomplete_Clause_Blockers := 1;
               elsif Clause_Count_For (Items, T.Id) > T.Literal_Count then
                  R.Extra_Literal_Blockers := 1;
               end if;
               if T.Has_Stream_Attributes and then not T.Stream_Profile_Compatible then
                  R.Stream_Profile_Blockers := 1;
               end if;
               if T.Existing_Representation_Clause then
                  R.Representation_Blockers := 1;
               end if;
               if T.Source_Fingerprint /= T.Expected_Source_Fingerprint
                 or else I.Source_Fingerprint /= I.Expected_Source_Fingerprint
               then
                  R.Source_Fingerprint_Blockers := 1;
               end if;
               if T.Type_Fingerprint /= T.Expected_Type_Fingerprint
                 or else I.Type_Fingerprint /= I.Expected_Type_Fingerprint
               then
                  R.Type_Fingerprint_Blockers := 1;
               end if;
            end if;

            if L.Id = No_Literal or else L.Enum_Type /= I.Enum_Type then
               R.Missing_Literal_Blockers := 1;
            else
               if L.Source_Fingerprint /= L.Expected_Source_Fingerprint then
                  R.Source_Fingerprint_Blockers := R.Source_Fingerprint_Blockers + 1;
               end if;
            end if;

            if I.Clause_Fingerprint /= I.Expected_Clause_Fingerprint then
               R.Clause_Fingerprint_Blockers := 1;
            end if;
            if Has_Duplicate_Literal_Before (Items, I) then
               R.Duplicate_Literal_Blockers := 1;
            end if;
            if Has_Duplicate_Code_Before (Items, I) then
               R.Duplicate_Code_Blockers := 1;
            end if;
            if not I.Code_Static then
               R.Non_Static_Code_Blockers := 1;
            end if;
            if I.Code < 0 then
               R.Negative_Code_Blockers := 1;
            end if;
            if T.Id /= No_Enum_Type and then Limit > 0
              and then I.Code_Static and then I.Code >= Integer (Limit)
            then
               R.Code_Size_Blockers := 1;
            end if;
            if I.Requires_Monotonic_Order and then L.Id /= No_Literal
              and then Previous_Code (Items, Literals, I) /= Integer'First
              and then I.Code <= Previous_Code (Items, Literals, I)
            then
               R.Non_Monotonic_Blockers := 1;
            end if;
            if not I.Representation_Compatible then
               R.Representation_Blockers := R.Representation_Blockers + 1;
            end if;

            R.Status := Status_For (R);
            R.Message := To_Unbounded_String (Enum_Status'Image (R.Status));
            R.Detail := To_Unbounded_String ("enumeration representation clause legality");
            R.Fingerprint := Mix (Natural (R.Clause), Blocker_Count (R));
            R.Fingerprint := Mix (R.Fingerprint, Natural (Enum_Status'Pos (R.Status)));
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, R.Fingerprint);
            Results.Items.Append (R);
         end;
      end loop;
      return Results;
   end Build;

   function Type_Count (Model : Enum_Type_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Type_Count;

   function Literal_Count (Model : Literal_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Literal_Count;

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
      return Model.Items.Element (Index);
   end Result_At;

   function Count_Status (Model : Result_Model; Status : Enum_Status) return Natural is
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
      return Count_Status (Model, Enum_Legal);
   end Legal_Count;

   function Error_Count (Model : Result_Model) return Natural is
   begin
      return Result_Count (Model) - Legal_Count (Model);
   end Error_Count;

   function Fingerprint (Model : Result_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Has_Result (Info : Result_Info) return Boolean is
   begin
      return Info.Id /= No_Result and then Info.Status /= Enum_Not_Checked;
   end Has_Result;

end Editor.Ada_Enumeration_Representation_Vertical_Slice_Legality;
