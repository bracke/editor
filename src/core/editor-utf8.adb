with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Unicode;

package body Editor.UTF8 is
   use Editor.Unicode;

   procedure Invalid
     (Mode  : UTF8_Error_Mode;
      Visit : not null access procedure (Code : Code_Point)) is
   begin
      if Mode = Reject then
         raise Invalid_UTF8;
      else
         Visit (Replacement_Character);
      end if;
   end Invalid;

   function Byte_Val
     (Bytes : String;
      J     : Integer) return Natural is
   begin
      return Character'Pos (Bytes (J));
   end Byte_Val;

   function Is_Continuation
     (Bytes : String;
      J     : Integer) return Boolean
   is
      B : constant Natural := Byte_Val (Bytes, J);
   begin
      return B in 16#80# .. 16#BF#;
   end Is_Continuation;

   function Decoded_Sequence_Length
     (Bytes : String;
      I     : Integer;
      Code  : out Natural) return Natural
   is
      B1 : constant Natural := Byte_Val (Bytes, I);
      B2 : Natural := 0;
      B3 : Natural := 0;
      B4 : Natural := 0;
   begin
      Code := 0;

      if B1 <= 16#7F# then
         Code := B1;
         return 1;

      elsif B1 in 16#C2# .. 16#DF# then
         if I + 1 <= Bytes'Last and then Is_Continuation (Bytes, I + 1) then
            B2 := Byte_Val (Bytes, I + 1);
            Code := (B1 - 16#C0#) * 16#40# + (B2 - 16#80#);
            return 2;
         end if;

      elsif B1 in 16#E0# .. 16#EF# then
         if I + 2 <= Bytes'Last
           and then Is_Continuation (Bytes, I + 1)
           and then Is_Continuation (Bytes, I + 2)
         then
            B2 := Byte_Val (Bytes, I + 1);
            B3 := Byte_Val (Bytes, I + 2);
            Code := (B1 - 16#E0#) * 16#1000#
              + (B2 - 16#80#) * 16#40#
              + (B3 - 16#80#);

            if Code >= 16#800# and then not (Code in 16#D800# .. 16#DFFF#) then
               return 3;
            end if;
         end if;

      elsif B1 in 16#F0# .. 16#F4# then
         if I + 3 <= Bytes'Last
           and then Is_Continuation (Bytes, I + 1)
           and then Is_Continuation (Bytes, I + 2)
           and then Is_Continuation (Bytes, I + 3)
         then
            B2 := Byte_Val (Bytes, I + 1);
            B3 := Byte_Val (Bytes, I + 2);
            B4 := Byte_Val (Bytes, I + 3);
            Code := (B1 - 16#F0#) * 16#40000#
              + (B2 - 16#80#) * 16#1000#
              + (B3 - 16#80#) * 16#40#
              + (B4 - 16#80#);

            if Code >= 16#10000# and then Code <= 16#10FFFF# then
               return 4;
            end if;
         end if;
      end if;

      return 0;
   end Decoded_Sequence_Length;

   procedure Decode_UTF8
     (Bytes      : String;
      Visit      : not null access procedure (Code : Code_Point);
      On_Invalid : UTF8_Error_Mode := Replace)
   is
      I    : Integer := Bytes'First;
      Code : Natural := 0;
      Step : Natural := 0;
   begin
      while I <= Bytes'Last loop
         Step := Decoded_Sequence_Length (Bytes, I, Code);

         if Step = 0 then
            Invalid (On_Invalid, Visit);
            I := I + 1;
         else
            Visit (Code_Point'Val (Code));
            I := I + Integer (Step);
         end if;
      end loop;
   end Decode_UTF8;

   function Encode_UTF8 (Code : Code_Point) return String is
      V : Natural := Code_Point'Pos (Code);
   begin
      if not Editor.Unicode.Is_Valid_Scalar (Code) then
         V := 16#FFFD#;
      end if;

      if V <= 16#7F# then
         return String'(1 => Character'Val (V));
      elsif V <= 16#7FF# then
         return String'
           (1 => Character'Val (16#C0# + V / 16#40#),
            2 => Character'Val (16#80# + V mod 16#40#));
      elsif V <= 16#FFFF# then
         return String'
           (1 => Character'Val (16#E0# + V / 16#1000#),
            2 => Character'Val (16#80# + (V / 16#40#) mod 16#40#),
            3 => Character'Val (16#80# + V mod 16#40#));
      else
         return String'
           (1 => Character'Val (16#F0# + V / 16#40000#),
            2 => Character'Val (16#80# + (V / 16#1000#) mod 16#40#),
            3 => Character'Val (16#80# + (V / 16#40#) mod 16#40#),
            4 => Character'Val (16#80# + V mod 16#40#));
      end if;
   end Encode_UTF8;

   function Code_Point_Count
     (Bytes      : String;
      On_Invalid : UTF8_Error_Mode := Replace) return Natural
   is
      Count : Natural := 0;
      procedure Visit (Code : Code_Point) is
         pragma Unreferenced (Code);
      begin
         Count := Count + 1;
      end Visit;
   begin
      Decode_UTF8 (Bytes, Visit'Access, On_Invalid);
      return Count;
   end Code_Point_Count;

   function Byte_Offset_For_Code_Point_Index
     (Bytes : String;
      Index : Natural) return Natural
   is
      I     : Integer := Bytes'First;
      Seen  : Natural := 0;
      Code  : Natural := 0;
      Step  : Natural := 0;
   begin
      if Index = 0 then
         return 0;
      end if;

      while I <= Bytes'Last loop
         exit when Seen = Index;

         Step := Decoded_Sequence_Length (Bytes, I, Code);
         if Step = 0 then
            Step := 1;
         end if;

         I := I + Integer (Step);
         Seen := Seen + 1;
      end loop;

      if I > Bytes'Last then
         return Bytes'Length;
      else
         return Natural (I - Bytes'First);
      end if;
   end Byte_Offset_For_Code_Point_Index;
end Editor.UTF8;
