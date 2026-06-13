package body Editor.Recent_Buffers is

   function Index_Of
     (Items : Buffer_Key_Vectors.Vector;
      Id    : Buffer_Key) return Natural
   is
   begin
      if Items.Is_Empty then
         return Natural'Last;
      end if;
      for I in Items.First_Index .. Items.Last_Index loop
         if Items (I) = Id then
            return I;
         end if;
      end loop;
      return Natural'Last;
   end Index_Of;

   procedure Clear (State : in out Recent_Buffer_State) is
   begin
      State.Order.Clear;
      Clear_Traversal (State);
   end Clear;

   procedure Clear_Traversal (State : in out Recent_Buffer_State) is
   begin
      State.Traversal_Order.Clear;
      State.Traversal_Active := False;
      State.Traversal_Index := 0;
   end Clear_Traversal;

   procedure Mark_Activated
     (State              : in out Recent_Buffer_State;
      Id                 : Buffer_Key;
      Preserve_Traversal : Boolean := False)
   is
      I : Natural;
   begin
      if Id = No_Buffer_Key then
         return;
      end if;

      I := Index_Of (State.Order, Id);
      if I /= Natural'Last then
         State.Order.Delete (I);
      end if;
      State.Order.Prepend (Id);

      if not Preserve_Traversal then
         Clear_Traversal (State);
      end if;
   end Mark_Activated;

   procedure Remove
     (State : in out Recent_Buffer_State;
      Id    : Buffer_Key)
   is
      I : Natural;
   begin
      I := Index_Of (State.Order, Id);
      if I /= Natural'Last then
         State.Order.Delete (I);
      end if;

      I := Index_Of (State.Traversal_Order, Id);
      if I /= Natural'Last then
         State.Traversal_Order.Delete (I);
         if Natural (State.Traversal_Order.Length) = 0 then
            State.Traversal_Index := 0;
         elsif State.Traversal_Index >= Natural (State.Traversal_Order.Length) then
            State.Traversal_Index := Natural (State.Traversal_Order.Length) - 1;
         end if;
         if Natural (State.Traversal_Order.Length) < 2 then
            Clear_Traversal (State);
         end if;
      end if;
   end Remove;

   function Count (State : Recent_Buffer_State) return Natural is
   begin
      return Natural (State.Order.Length);
   end Count;

   function Contains
     (State : Recent_Buffer_State;
      Id    : Buffer_Key) return Boolean
   is
   begin
      return Index_Of (State.Order, Id) /= Natural'Last;
   end Contains;

   function Id_At
     (State : Recent_Buffer_State;
      Index : Positive) return Buffer_Key
   is
   begin
      if Index > Natural (State.Order.Length) then
         return No_Buffer_Key;
      end if;
      return State.Order (Index - 1);
   end Id_At;

   function Has_Previous
     (State  : Recent_Buffer_State;
      Active : Buffer_Key) return Boolean
   is
      Copy : Recent_Buffer_State := State;
   begin
      return Previous_Target (Copy, Active) /= No_Buffer_Key;
   end Has_Previous;

   function Has_Next (State : Recent_Buffer_State) return Boolean
   is
      Copy : Recent_Buffer_State := State;
   begin
      return Next_Target (Copy) /= No_Buffer_Key;
   end Has_Next;

   function Previous_Target
     (State  : in out Recent_Buffer_State;
      Active : Buffer_Key) return Buffer_Key
   is
      Len : Natural;
   begin
      if Active = No_Buffer_Key or else Natural (State.Order.Length) < 2 then
         return No_Buffer_Key;
      end if;

      if not State.Traversal_Active then
         State.Traversal_Order := State.Order;
         State.Traversal_Index := Index_Of (State.Traversal_Order, Active);
         if State.Traversal_Index = Natural'Last then
            State.Traversal_Order.Prepend (Active);
            State.Traversal_Index := 0;
         end if;
         State.Traversal_Active := True;
      end if;

      Len := Natural (State.Traversal_Order.Length);
      if Len < 2 then
         Clear_Traversal (State);
         return No_Buffer_Key;
      end if;

      if State.Traversal_Index >= Len - 1 then
         State.Traversal_Index := 0;
      else
         State.Traversal_Index := State.Traversal_Index + 1;
      end if;

      if State.Traversal_Order (State.Traversal_Index) = Active and then Len > 1 then
         if State.Traversal_Index >= Len - 1 then
            State.Traversal_Index := 0;
         else
            State.Traversal_Index := State.Traversal_Index + 1;
         end if;
      end if;

      return State.Traversal_Order (State.Traversal_Index);
   end Previous_Target;

   function Next_Target
     (State : in out Recent_Buffer_State) return Buffer_Key
   is
      Len : Natural;
   begin
      if not State.Traversal_Active then
         return No_Buffer_Key;
      end if;

      Len := Natural (State.Traversal_Order.Length);
      if Len < 2 then
         Clear_Traversal (State);
         return No_Buffer_Key;
      end if;

      if State.Traversal_Index = 0 then
         State.Traversal_Index := Len - 1;
      else
         State.Traversal_Index := State.Traversal_Index - 1;
      end if;

      return State.Traversal_Order (State.Traversal_Index);
   end Next_Target;

end Editor.Recent_Buffers;
