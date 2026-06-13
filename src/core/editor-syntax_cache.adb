with Ada.Unchecked_Deallocation;
with Editor.Syntax;
package body Editor.Syntax_Cache is
   use type Editor.Syntax.Lexical_State;

   procedure Free is new Ada.Unchecked_Deallocation (Line_Table, Line_Table_Access);

   procedure Ensure_Lines (Cache : in out Syntax_Cache) is
   begin
      if Cache.Lines = null then
         Cache.Lines := new Line_Table'(others => (others => <>));
      end if;
   end Ensure_Lines;

   overriding procedure Adjust (Cache : in out Syntax_Cache) is
   begin
      --  Syntax cache data is derived from buffer text and revision state.  Do
      --  not clone the large line table for State_Type snapshots; copied states
      --  rebuild the cache lazily before render consumption.
      Cache.Line_Count := 0;
      Cache.Lines := null;
   end Adjust;

   overriding procedure Finalize (Cache : in out Syntax_Cache) is
   begin
      if Cache.Lines /= null then
         Free (Cache.Lines);
      end if;
      Cache.Line_Count := 0;
   end Finalize;

   procedure Clear (Cache : in out Syntax_Cache) is
   begin
      Cache.Line_Count := 0;
      if Cache.Lines /= null then
         for I in Cache.Lines'Range loop
            Cache.Lines (I) := (others => <>);
         end loop;
      end if;
   end Clear;

   procedure Set_Line_Count (Cache : in out Syntax_Cache; Line_Count : Natural) is
      Old_Bounded : constant Natural := Cache.Line_Count;
      Bounded : constant Natural := Natural'Min (Line_Count, Max_Cached_Lines);
   begin
      if Bounded > 0 then
         Ensure_Lines (Cache);
      end if;
      Cache.Line_Count := Bounded;

      if Cache.Lines = null then
         return;
      end if;

      if Bounded > Old_Bounded then
         for I in Old_Bounded + 1 .. Bounded loop
            Cache.Lines (I) := (others => <>);
            Cache.Lines (I).Dirty := True;
         end loop;
      elsif Bounded < Old_Bounded then
         for I in Bounded + 1 .. Old_Bounded loop
            Cache.Lines (I) := (others => <>);
         end loop;
      end if;
   end Set_Line_Count;

   procedure Mark_Line_Dirty
     (Cache       : in out Syntax_Cache;
      Line_Number : Positive) is
      Old_Bounded : constant Natural := Cache.Line_Count;
   begin
      if Line_Number <= Max_Cached_Lines then
         Ensure_Lines (Cache);
         if Cache.Line_Count < Line_Number then
            for I in Old_Bounded + 1 .. Line_Number loop
               Cache.Lines (I) := (others => <>);
               Cache.Lines (I).Dirty := True;
            end loop;
            Cache.Line_Count := Line_Number;
         end if;
         Cache.Lines (Line_Number).Dirty := True;
      end if;
   end Mark_Line_Dirty;

   procedure Mark_Range_Dirty
     (Cache      : in out Syntax_Cache;
      First_Line : Positive;
      Last_Line  : Positive) is
      Stop : constant Natural := Natural'Min (Last_Line, Max_Cached_Lines);
      Old_Bounded : constant Natural := Cache.Line_Count;
   begin
      if First_Line > Stop then
         return;
      end if;

      Ensure_Lines (Cache);
      if Cache.Line_Count < Stop then
         for I in Old_Bounded + 1 .. Stop loop
            Cache.Lines (I) := (others => <>);
            Cache.Lines (I).Dirty := True;
         end loop;
         Cache.Line_Count := Stop;
      end if;

      for I in First_Line .. Stop loop
         Cache.Lines (I).Dirty := True;
      end loop;
   end Mark_Range_Dirty;

   procedure Relex_Dirty_Line
     (Cache         : in out Syntax_Cache;
      Line_Number   : Positive;
      Line_Text     : String;
      State_Changed : out Boolean)
   is
   begin
      State_Changed := False;

      if Line_Number > Max_Cached_Lines then
         return;
      end if;

      Ensure_Lines (Cache);
      declare
         Line_Data : Line_Entry renames Cache.Lines (Line_Number);
         Old_End : constant Editor.Syntax.Lexical_State := Line_Data.End_State;

         procedure Store
           (Start_Col : Natural;
            End_Col   : Natural;
            Kind      : Editor.Syntax.Token_Kind)
         is
         begin
            if Line_Data.Token_Count < Max_Tokens_Per_Line then
               Line_Data.Token_Count := Line_Data.Token_Count + 1;
               Line_Data.Tokens (Line_Data.Token_Count) :=
                 (Start_Col => Start_Col,
                  End_Col   => End_Col,
                  Kind      => Kind);
            else
               Line_Data.Token_Overflow := True;
            end if;
         end Store;
      begin
         if Line_Number > Cache.Line_Count then
            Cache.Line_Count := Line_Number;
         end if;

         if Line_Number = 1 then
            Line_Data.Start_State := Editor.Syntax.Normal_State;
         else
            Line_Data.Start_State := Cache.Lines (Line_Number - 1).End_State;
         end if;

         Line_Data.Token_Count := 0;
         Line_Data.Token_Overflow := False;
         Editor.Syntax.Classify_Line
           (Line          => Line_Text,
            Initial_State => Line_Data.Start_State,
            Visit         => Store'Access,
            Final_State   => Line_Data.End_State);

         Line_Data.Dirty := False;
         State_Changed := Line_Data.End_State /= Old_End;

         if State_Changed and then Line_Number < Cache.Line_Count then
            Cache.Lines (Line_Number + 1).Dirty := True;
         end if;
      end;
   end Relex_Dirty_Line;

   function Tokens_For_Line
     (Cache       : Syntax_Cache;
      Line_Number : Positive) return Editor.Syntax.Token_Span_Array
   is
   begin
      if Cache.Lines = null
        or else Line_Number > Cache.Line_Count
        or else Line_Number > Max_Cached_Lines
      then
         declare
            Empty : Editor.Syntax.Token_Span_Array (1 .. 0);
         begin
            return Empty;
         end;
      end if;

      declare
         Count : constant Natural := Cache.Lines (Line_Number).Token_Count;
         Result : Editor.Syntax.Token_Span_Array (1 .. Count);
      begin
         for I in 1 .. Count loop
            Result (I) := Cache.Lines (Line_Number).Tokens (I);
         end loop;
         return Result;
      end;
   end Tokens_For_Line;


   function Cached_Line_Count (Cache : Syntax_Cache) return Natural is
   begin
      return Cache.Line_Count;
   end Cached_Line_Count;

   function Line_Is_Cacheable
     (Cache       : Syntax_Cache;
      Line_Number : Positive) return Boolean is
      pragma Unreferenced (Cache);
   begin
      return Line_Number <= Max_Cached_Lines;
   end Line_Is_Cacheable;

   function Token_Overflowed
     (Cache       : Syntax_Cache;
      Line_Number : Positive) return Boolean is
   begin
      return Cache.Lines /= null
        and then Line_Number <= Cache.Line_Count
        and then Line_Number <= Max_Cached_Lines
        and then Cache.Lines (Line_Number).Token_Overflow;
   end Token_Overflowed;

   function Is_Dirty
     (Cache       : Syntax_Cache;
      Line_Number : Positive) return Boolean is
   begin
      return Cache.Lines /= null
        and then Line_Number <= Cache.Line_Count
        and then Line_Number <= Max_Cached_Lines
        and then Cache.Lines (Line_Number).Dirty;
   end Is_Dirty;

end Editor.Syntax_Cache;
