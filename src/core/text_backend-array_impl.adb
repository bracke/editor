package body Text_Backend.Array_Impl is

   procedure Clear (B : in out Buffer_Type) is
   begin
      B.Last := 0;
   end Clear;

   ------------------------------------------------------------------------


   procedure Set_Text
     (B    : in out Buffer_Type;
      Text : String) is
      N : constant Natural := Natural'Min (Text'Length, B.Data'Length);
   begin
      B.Last := N;
      for I in 1 .. N loop
         B.Data (I) := Text (Text'First + I - 1);
      end loop;
   end Set_Text;

   ------------------------------------------------------------------------

   procedure Insert
  (B     : in out Buffer_Type;
   Index : Natural;
   Ch    : Character) is
   I : Positive;
begin
   if B.Last = B.Data'Last then
      return;
   end if;

   -- caret insert at end
   if Index >= B.Last then
      B.Last := B.Last + 1;
      B.Data (B.Last) := Ch;
      return;
   end if;

   -- convert caret index -> storage index
   I := Index + 1;

   for J in reverse I .. B.Last loop
      B.Data (J + 1) := B.Data (J);
   end loop;

   B.Data (I) := Ch;
   B.Last := B.Last + 1;
end Insert;

   ------------------------------------------------------------------------

   procedure Insert_Range
   (B     : in out Buffer_Type;
      Index : Natural;
      Ch    : Character;
      Count : Natural) is
   begin
      for I in 1 .. Count loop
         Insert (B, Index + 1, Ch);
      end loop;
   end Insert_Range;

   ------------------------------------------------------------------------

procedure Delete
  (B     : in out Buffer_Type;
   Index : Natural) is
   I : Positive;
begin
   if B.Last = 0 then
      return;
   end if;

   if Index >= B.Last then
      -- delete last char
      B.Last := B.Last - 1;
      return;
   end if;

   I := Index + 1;

   for J in I .. B.Last - 1 loop
      B.Data (J) := B.Data (J + 1);
   end loop;

   B.Last := B.Last - 1;
end Delete;

   ------------------------------------------------------------------------

procedure Delete_Range
  (B     : in out Buffer_Type;
   Start : Natural;
   Span  : Natural) is
begin
   if Span = 0 then
      return;
   end if;

   -- Start is a 0-based caret position.
   -- Delete always removes the character after Start,
   -- which is buffer index Start + 1.
   for I in 1 .. Span loop
      exit when Start >= B.Last;
      Delete (B, Start + 1);
   end loop;
end Delete_Range;

   ------------------------------------------------------------------------

procedure Replace_Range
  (B     : in out Buffer_Type;
   Start : Natural;
   Span  : Natural;
   Ch    : Character) is
begin
   Delete_Range (B, Start, Span);
   Insert (B, Start, Ch);
end Replace_Range;

   ------------------------------------------------------------------------

   function Length (B : Buffer_Type) return Natural is
   begin
      return B.Last;
   end Length;

   ------------------------------------------------------------------------


   procedure For_Each_Char
     (B  : Buffer_Type;
      Fn : not null access procedure (Ch : Character)) is
   begin
      for I in 1 .. B.Last loop
         Fn (B.Data (I));
      end loop;
   end For_Each_Char;

   ------------------------------------------------------------------------

   procedure For_Each_Char_Range
     (B     : Buffer_Type;
      Start : Natural;
      Stop  : Natural;
      Fn    : not null access procedure (Ch : Character))
   is
      First : constant Natural := Natural'Min (Start + 1, B.Last + 1);
      Last  : constant Natural := Natural'Min (Stop, B.Last);
   begin
      if Stop <= Start or else First > Last then
         return;
      end if;

      for I in First .. Last loop
         Fn (B.Data (I));
      end loop;
   end For_Each_Char_Range;

   ------------------------------------------------------------------------

   function Element
     (B     : Buffer_Type;
      Index : Natural) return Character is
   begin
      if Index = 0 or else Index > B.Last then
         return Character'Val (0);
      end if;

      return B.Data (Index);
   end Element;

end Text_Backend.Array_Impl;