package Text_Backend.Array_Impl is

   type Buffer_Type is private;

   procedure Clear (B : in out Buffer_Type);

   procedure Set_Text
     (B    : in out Buffer_Type;
      Text : String);

   procedure Insert
     (B     : in out Buffer_Type;
      Index : Natural;
      Ch    : Character);

   procedure Insert_Range
      (B     : in out Buffer_Type;
      Index : Natural;
      Ch    : Character;
      Count : Natural);

   procedure Delete
     (B     : in out Buffer_Type;
      Index : Natural);

   procedure Delete_Range (B : in out Buffer_Type; Start, Span : Natural);

   procedure Replace_Range
      (B    : in out Buffer_Type;
      Start : Natural;
      Span  : Natural;
      Ch    : Character);

   function Length (B : Buffer_Type) return Natural;

   procedure For_Each_Char
     (B  : Buffer_Type;
      Fn : not null access procedure (Ch : Character));

   procedure For_Each_Char_Range
     (B     : Buffer_Type;
      Start : Natural;
      Stop  : Natural;
      Fn    : not null access procedure (Ch : Character));

   function Element
     (B     : Buffer_Type;
      Index : Natural) return Character;

private

   subtype Buffer_Index is Natural;

   type Char_Array is array (Positive range <>) of Character;

   type Buffer_Type is record
      Data : Char_Array (1 .. 1024);
      Last : Natural := 0;
   end record;

end Text_Backend.Array_Impl;