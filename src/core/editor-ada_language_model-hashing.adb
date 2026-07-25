with Ada.Characters.Handling;

package body Editor.Ada_Language_Model.Hashing is

   pragma Suppress (Overflow_Check);

   Fingerprint_Modulus : constant Long_Long_Integer := 2_147_483_647;

   function Hash_Mix
     (Seed       : Natural;
      Addend     : Long_Long_Integer;
      Multiplier : Long_Long_Integer := 131) return Natural
   is
   begin
      return Natural
        ((Long_Long_Integer (Seed) * Multiplier + Addend) mod Fingerprint_Modulus);
   end Hash_Mix;

   function Hash_Mix
     (Seed       : Natural;
      Addends    : Natural_Addend_Array;
      Multiplier : Long_Long_Integer := 131) return Natural
   is
      Acc : Long_Long_Integer := Long_Long_Integer (Seed) * Multiplier;
   begin
      for Addend of Addends loop
         Acc := Acc + Long_Long_Integer (Addend);
      end loop;
      return Natural (Acc mod Fingerprint_Modulus);
   end Hash_Mix;

   function Hash_String (Seed : Natural; Text : String) return Natural is
      H : Natural := Seed;
   begin
      for C of Text loop
         H := Hash_Mix (H, Long_Long_Integer (Character'Pos (C)) + 1);
      end loop;
      return H;
   end Hash_String;

   function Normalize_Name (Name : String) return String is
      Result : String (Name'Range);
   begin
      for I in Name'Range loop
         Result (I) := Ada.Characters.Handling.To_Lower (Name (I));
      end loop;
      return Result;
   end Normalize_Name;

   function Hash_Boolean (Seed : Natural; Value : Boolean) return Natural is
   begin
      if Value then
         return Hash_Mix (Seed, 1);
      else
         return Hash_Mix (Seed, 2);
      end if;
   end Hash_Boolean;

   function Hash_Flags
     (Seed  : Natural;
      Flags : Declaration_Flags) return Natural
   is
      H : Natural := Seed;
   begin
      H := Hash_Boolean (H, Flags.Is_Private);
      H := Hash_Boolean (H, Flags.Is_Abstract);
      H := Hash_Boolean (H, Flags.Is_Overriding);
      H := Hash_Boolean (H, Flags.Is_Not_Overriding);
      H := Hash_Boolean (H, Flags.Is_Generic);
      H := Hash_Boolean (H, Flags.Is_Rename);
      H := Hash_Boolean (H, Flags.Is_Instantiation);
      H := Hash_Boolean (H, Flags.Is_Separate);
      H := Hash_Boolean (H, Flags.Is_Body);
      H := Hash_Boolean (H, Flags.Has_Representation_Clause);
      H := Hash_Boolean (H, Flags.Has_Aspect_Specification);
      H := Hash_Boolean (H, Flags.Has_Pragma_Metadata);
      H := Hash_Boolean (H, Flags.Has_Null_Exclusion);
      H := Hash_Boolean (H, Flags.Has_Aliased_Metadata);
      H := Hash_Boolean (H, Flags.Has_Limited_Metadata);
      H := Hash_Boolean (H, Flags.Has_Tagged_Metadata);
      H := Hash_Boolean (H, Flags.Has_Interface_Metadata);
      H := Hash_Boolean (H, Flags.Has_Synchronized_Metadata);
      H := Hash_Boolean (H, Flags.Has_Task_Interface_Metadata);
      H := Hash_Boolean (H, Flags.Has_Protected_Interface_Metadata);
      H := Hash_Boolean (H, Flags.Has_Task_Type_Metadata);
      H := Hash_Boolean (H, Flags.Has_Protected_Type_Metadata);
      H := Hash_Boolean (H, Flags.Has_Access_Metadata);
      H := Hash_Boolean (H, Flags.Has_Access_All_Metadata);
      H := Hash_Boolean (H, Flags.Has_Access_Constant_Metadata);
      H := Hash_Boolean (H, Flags.Has_Class_Wide_Metadata);
      H := Hash_Boolean (H, Flags.Has_Access_Subprogram_Metadata);
      H := Hash_Boolean (H, Flags.Has_Access_Protected_Metadata);
      H := Hash_Boolean (H, Flags.Has_Array_Metadata);
      H := Hash_Boolean (H, Flags.Has_Derived_Metadata);
      H := Hash_Boolean (H, Flags.Has_Range_Metadata);
      H := Hash_Boolean (H, Flags.Has_Modular_Metadata);
      H := Hash_Boolean (H, Flags.Has_Digits_Metadata);
      H := Hash_Boolean (H, Flags.Has_Delta_Metadata);
      H := Hash_Boolean (H, Flags.Has_Variant_Record_Metadata);
      H := Hash_Boolean (H, Flags.Has_Default_Expression_Metadata);
      H := Hash_Boolean (H, Flags.Has_Entry_Family_Metadata);
      H := Hash_Boolean (H, Flags.Has_Incomplete_Type_Metadata);
      H := Hash_Boolean (H, Flags.Has_Profile_Mode_Metadata);
      H := Hash_Boolean (H, Flags.Has_Entry_Barrier_Metadata);
      H := Hash_Boolean (H, Flags.Has_Box_Metadata);
      H := Hash_Boolean (H, Flags.Has_Private_Extension_Metadata);
      H := Hash_Boolean (H, Flags.Has_Named_Number_Metadata);
      H := Hash_Boolean (H, Flags.Has_Deferred_Constant_Metadata);
      H := Hash_Boolean (H, Flags.Has_Null_Subprogram_Metadata);
      H := Hash_Boolean (H, Flags.Has_Expression_Function_Metadata);
      H := Hash_Boolean (H, Flags.Has_Null_Record_Metadata);
      H := Hash_Boolean (H, Flags.Has_Discriminant_Part_Metadata);
      H := Hash_Boolean (H, Flags.Has_Body_Stub_Metadata);
      H := Hash_Boolean (H, Flags.Has_Constraint_Metadata);
      H := Hash_Boolean (H, Flags.Has_Child_Unit_Metadata);
      H := Hash_Boolean (H, Flags.Has_Generic_Actual_Part_Metadata);
      return H;
   end Hash_Flags;


end Editor.Ada_Language_Model.Hashing;
