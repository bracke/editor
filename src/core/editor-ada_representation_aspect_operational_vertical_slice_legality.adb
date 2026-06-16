with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Representation_Aspect_Operational_Vertical_Slice_Legality is

   pragma Suppress (Overflow_Check);

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 31337) + 1321) mod 1_000_000_007;
   end Mix;

   function Normalize (S : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower
        (Ada.Strings.Fixed.Trim (S, Ada.Strings.Both));
   end Normalize;

   function Same (L, R : Unbounded_String) return Boolean is
   begin
      return Normalize (To_String (L)) = Normalize (To_String (R));
   end Same;

   function Is_Representation_Item (K : Representation_Item_Kind) return Boolean is
   begin
      return K in Item_Address | Item_Size | Item_Object_Size | Item_Value_Size |
        Item_Alignment | Item_Storage_Size | Item_Component_Size | Item_Bit_Order |
        Item_Scalar_Storage_Order | Item_Volatile | Item_Atomic |
        Item_Atomic_Components | Item_Volatile_Components | Item_Independent |
        Item_Independent_Components;
   end Is_Representation_Item;

   function Is_Operational_Item (K : Representation_Item_Kind) return Boolean is
   begin
      return K in Item_Convention | Item_Import | Item_Export | Item_External_Name |
        Item_Link_Name | Item_Read | Item_Write | Item_Input | Item_Output;
   end Is_Operational_Item;

   function Is_Stream_Item (K : Representation_Item_Kind) return Boolean is
   begin
      return K in Item_Read | Item_Write | Item_Input | Item_Output;
   end Is_Stream_Item;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.Missing_Target_Blockers
        + R.Target_Kind_Blockers
        + R.Private_View_Blockers
        + R.Limited_View_Blockers
        + R.Incomplete_View_Blockers
        + R.Generic_Formal_Blockers
        + R.Late_Freezing_Blockers
        + R.Duplicate_Blockers
        + R.Conflict_Blockers
        + R.Static_Expression_Blockers
        + R.Address_Blockers
        + R.Size_Blockers
        + R.Alignment_Blockers
        + R.Storage_Size_Blockers
        + R.Convention_Blockers
        + R.Import_Export_Blockers
        + R.External_Link_Name_Blockers
        + R.Stream_Profile_Blockers
        + R.Stream_View_Blockers
        + R.Volatile_Atomic_Blockers
        + R.Operational_Attribute_Blockers
        + R.Source_Fingerprint_Blockers
        + R.Target_Fingerprint_Blockers
        + R.Item_Fingerprint_Blockers;
   end Blocker_Count;

   function Status_For (R : Result_Info; I : Item_Info) return Legality_Status is
      Blocks : constant Natural := Blocker_Count (R);
   begin
      if Blocks > 1 then
         return Legality_Multiple_Blockers;
      elsif R.Missing_Target_Blockers > 0 then
         return Legality_Missing_Target;
      elsif R.Target_Kind_Blockers > 0 then
         return Legality_Target_Kind_Mismatch;
      elsif R.Private_View_Blockers > 0 then
         return Legality_Private_View_Barrier;
      elsif R.Limited_View_Blockers > 0 then
         return Legality_Limited_View_Barrier;
      elsif R.Incomplete_View_Blockers > 0 then
         return Legality_Incomplete_View_Barrier;
      elsif R.Generic_Formal_Blockers > 0 then
         return Legality_Generic_Formal_Barrier;
      elsif R.Late_Freezing_Blockers > 0 then
         return Legality_Late_After_Freezing;
      elsif R.Duplicate_Blockers > 0 then
         return Legality_Duplicate_Item;
      elsif R.Conflict_Blockers > 0 then
         return Legality_Conflicting_Item;
      elsif R.Static_Expression_Blockers > 0 then
         return Legality_Invalid_Static_Expression;
      elsif R.Address_Blockers > 0 then
         return Legality_Invalid_Address;
      elsif R.Size_Blockers > 0 then
         return Legality_Invalid_Size;
      elsif R.Alignment_Blockers > 0 then
         return Legality_Invalid_Alignment;
      elsif R.Storage_Size_Blockers > 0 then
         return Legality_Invalid_Storage_Size;
      elsif R.Convention_Blockers > 0 then
         return Legality_Invalid_Convention;
      elsif R.Import_Export_Blockers > 0 then
         return Legality_Import_Export_Profile_Mismatch;
      elsif R.External_Link_Name_Blockers > 0 then
         return Legality_External_Link_Name_Mismatch;
      elsif R.Stream_Profile_Blockers > 0 then
         return Legality_Stream_Profile_Mismatch;
      elsif R.Stream_View_Blockers > 0 then
         return Legality_Stream_View_Barrier;
      elsif R.Volatile_Atomic_Blockers > 0 then
         return Legality_Volatile_Atomic_Conflict;
      elsif R.Operational_Attribute_Blockers > 0 then
         return Legality_Operational_Attribute_Conflict;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return Legality_Source_Fingerprint_Mismatch;
      elsif R.Target_Fingerprint_Blockers > 0 then
         return Legality_Target_Fingerprint_Mismatch;
      elsif R.Item_Fingerprint_Blockers > 0 then
         return Legality_Item_Fingerprint_Mismatch;
      elsif Blocks = 0 and then I.Requires_Runtime_Check then
         return Legality_Legal_Runtime_Check;
      elsif Blocks = 0 then
         return Legality_Legal;
      else
         return Legality_Indeterminate;
      end if;
   end Status_For;

   function Find_Target (Targets : Target_Model; Id : Target_Id) return Target_Info is
   begin
      for T of Targets.Items loop
         if T.Id = Id then
            return T;
         end if;
      end loop;
      return (others => <>);
   end Find_Target;

   function Has_Duplicate_Before (Items : Item_Model; I : Item_Info) return Boolean is
   begin
      for Other of Items.Items loop
         exit when Other.Id = I.Id;
         if Other.Target = I.Target and then Other.Kind = I.Kind then
            return True;
         end if;
      end loop;
      return False;
   end Has_Duplicate_Before;

   function Has_Conflicting_Unified_Item (Items : Item_Model; I : Item_Info) return Boolean is
   begin
      for Other of Items.Items loop
         exit when Other.Id = I.Id;
         if Other.Target = I.Target
           and then Other.Kind = I.Kind
           and then Other.Form /= I.Form
           and then not Same (Other.Expression_Text, I.Expression_Text)
         then
            return True;
         end if;
      end loop;
      return False;
   end Has_Conflicting_Unified_Item;

   procedure Evaluate_Item
     (Targets : Target_Model; Items : Item_Model; I : Item_Info; R : in out Result_Info)
   is
      T : constant Target_Info := Find_Target (Targets, I.Target);
   begin
      R.Id := Result_Id (Natural (I.Id));
      R.Item := I.Id;
      R.Target := I.Target;
      R.Node := I.Node;
      R.Form := I.Form;
      R.Kind := I.Kind;

      if I.Target = No_Target or else T.Id = No_Target then
         R.Missing_Target_Blockers := R.Missing_Target_Blockers + 1;
      else
         if I.Required_Target_Kind /= Target_Unknown
           and then T.Kind /= I.Required_Target_Kind
         then
            R.Target_Kind_Blockers := R.Target_Kind_Blockers + 1;
         end if;

         case T.View is
            when View_Private =>
               R.Private_View_Blockers := R.Private_View_Blockers + 1;
            when View_Limited =>
               R.Limited_View_Blockers := R.Limited_View_Blockers + 1;
            when View_Incomplete =>
               R.Incomplete_View_Blockers := R.Incomplete_View_Blockers + 1;
            when View_Generic_Formal =>
               R.Generic_Formal_Blockers := R.Generic_Formal_Blockers + 1;
            when others =>
               null;
         end case;

         if T.Frozen and then I.Placement_Order >= T.Freeze_Order then
            R.Late_Freezing_Blockers := R.Late_Freezing_Blockers + 1;
         end if;

         if Is_Representation_Item (I.Kind) and then not T.Allows_Representation then
            R.Conflict_Blockers := R.Conflict_Blockers + 1;
         end if;

         if Is_Operational_Item (I.Kind) and then not T.Allows_Operational then
            R.Operational_Attribute_Blockers := R.Operational_Attribute_Blockers + 1;
         end if;
      end if;

      if Has_Duplicate_Before (Items, I) then
         R.Duplicate_Blockers := R.Duplicate_Blockers + 1;
      elsif Has_Conflicting_Unified_Item (Items, I) then
         R.Conflict_Blockers := R.Conflict_Blockers + 1;
      end if;

      if not I.Static_Expression then
         R.Static_Expression_Blockers := R.Static_Expression_Blockers + 1;
      end if;

      if I.Kind = Item_Address and then not I.Address_Expression_Valid then
         R.Address_Blockers := R.Address_Blockers + 1;
      elsif I.Kind in Item_Size | Item_Object_Size | Item_Value_Size | Item_Component_Size
        and then (not I.Size_Expression_Valid or else not I.Positive_Value)
      then
         R.Size_Blockers := R.Size_Blockers + 1;
      elsif I.Kind = Item_Alignment
        and then (not I.Alignment_Expression_Valid or else not I.Positive_Value)
      then
         R.Alignment_Blockers := R.Alignment_Blockers + 1;
      elsif I.Kind = Item_Storage_Size
        and then (not I.Storage_Size_Expression_Valid or else not I.Positive_Value)
      then
         R.Storage_Size_Blockers := R.Storage_Size_Blockers + 1;
      elsif I.Kind = Item_Convention and then not I.Convention_Valid then
         R.Convention_Blockers := R.Convention_Blockers + 1;
      elsif I.Kind in Item_Import | Item_Export
        and then not I.Import_Export_Profile_Valid
      then
         R.Import_Export_Blockers := R.Import_Export_Blockers + 1;
      elsif I.Kind in Item_External_Name | Item_Link_Name
        and then not I.External_Link_Name_Valid
      then
         R.External_Link_Name_Blockers := R.External_Link_Name_Blockers + 1;
      elsif Is_Stream_Item (I.Kind) and then not I.Stream_Profile_Valid then
         R.Stream_Profile_Blockers := R.Stream_Profile_Blockers + 1;
      end if;

      if Is_Stream_Item (I.Kind) and then T.View in View_Private | View_Limited then
         R.Stream_View_Blockers := R.Stream_View_Blockers + 1;
      end if;

      if I.Kind in Item_Volatile | Item_Atomic | Item_Atomic_Components |
        Item_Volatile_Components | Item_Independent | Item_Independent_Components
        and then not I.Volatile_Atomic_Compatible
      then
         R.Volatile_Atomic_Blockers := R.Volatile_Atomic_Blockers + 1;
      end if;

      if not I.Operational_Attribute_Compatible then
         R.Operational_Attribute_Blockers := R.Operational_Attribute_Blockers + 1;
      end if;

      if I.Source_Fingerprint /= I.Expected_Source_Fingerprint then
         R.Source_Fingerprint_Blockers := R.Source_Fingerprint_Blockers + 1;
      end if;
      if I.Target_Fingerprint /= I.Expected_Target_Fingerprint then
         R.Target_Fingerprint_Blockers := R.Target_Fingerprint_Blockers + 1;
      end if;
      if I.Item_Fingerprint /= I.Expected_Item_Fingerprint then
         R.Item_Fingerprint_Blockers := R.Item_Fingerprint_Blockers + 1;
      end if;

      R.Status := Status_For (R, I);
      R.Message := To_Unbounded_String ("representation/aspect operational item legality");
      R.Detail := I.Name;
      R.Fingerprint := Mix
        (Natural (I.Id), Mix (Natural (I.Target), Mix (Representation_Item_Kind'Pos (I.Kind), Blocker_Count (R))));
   end Evaluate_Item;

   procedure Clear (Model : in out Target_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Item_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Target (Model : in out Target_Model; Info : Target_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
   end Add_Target;

   procedure Add_Item (Model : in out Item_Model; Info : Item_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
   end Add_Item;

   function Build (Targets : Target_Model; Items : Item_Model) return Result_Model is
      Result : Result_Model;
      R : Result_Info;
   begin
      Result.Result_Fingerprint := Mix (Targets.Result_Fingerprint, Items.Result_Fingerprint);
      for I of Items.Items loop
         R := (others => <>);
         Evaluate_Item (Targets, Items, I, R);
         Result.Items.Append (R);
         Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, R.Fingerprint);
      end loop;
      return Result;
   end Build;

   function Target_Count (Model : Target_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Target_Count;

   function Item_Count (Model : Item_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Item_Count;

   function Result_Count (Model : Result_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Result_Count;

   function Result_At (Model : Result_Model; Index : Positive) return Result_Info is
   begin
      return Model.Items.Element (Index);
   end Result_At;

   function Count_Status (Model : Result_Model; Status : Legality_Status) return Natural is
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
      return Count_Status (Model, Legality_Legal)
        + Count_Status (Model, Legality_Legal_Runtime_Check);
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
      return Info.Id /= No_Result and then Info.Status /= Legality_Not_Checked;
   end Has_Result;

end Editor.Ada_Representation_Aspect_Operational_Vertical_Slice_Legality;
