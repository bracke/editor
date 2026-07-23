with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Text_Helpers;
with Editor.Ada_Language_Model;

package body Editor.Ada_Declaration_Parser.Range_Structure_Helpers is

   use Editor.Text_Helpers;
   use Editor.Ada_Language_Model;

   function Same_Text
     (Left, Right : Unbounded_String) return Boolean is
   begin
      return To_String (Left) = To_String (Right);
   end Same_Text;

   function Text_Names_Target
     (Text : Unbounded_String;
      Name : Unbounded_String) return Boolean
   is
      T : constant String := Lower (To_String (Text));
      N : constant String := To_String (Name);
      From : Positive := T'First;
      Found : Natural;

      function Boundary_Before (Pos : Positive) return Boolean is
      begin
         return Pos = T'First
           or else not Is_Word_Char (T (Pos - 1));
      end Boundary_Before;

      function Boundary_After (Pos : Positive) return Boolean is
         Last : constant Natural := Pos + N'Length - 1;
      begin
         return Last >= T'Last
           or else not Is_Word_Char (T (Last + 1));
      end Boundary_After;
   begin
      if N = "" or else T = "" or else N'Length > T'Length then
         return False;
      end if;

      loop
         Found := Ada.Strings.Fixed.Index
           (Source  => T,
            Pattern => N,
            From    => From);
         exit when Found = 0;

         if Boundary_Before (Found) and then Boundary_After (Found) then
            return True;
         end if;

         exit when Found = T'Last;
         From := Found + 1;
      end loop;

      return False;
   end Text_Names_Target;

   function Same_Local_Representation_Target
     (Current, Previous : Representation_Clause_Info) return Boolean is
   begin
      return Current.Target_Symbol /= No_Symbol
        and then Previous.Target_Symbol /= No_Symbol
        and then Current.Target_Symbol = Previous.Target_Symbol;
   end Same_Local_Representation_Target;

   function Ranges_Overlap
     (Left_First, Left_Last, Right_First, Right_Last : Natural) return Boolean is
   begin
      return Left_First <= Right_Last and then Right_First <= Left_Last;
   end Ranges_Overlap;

   function Contains_Range_Dots (Expr : String) return Boolean is
   begin
      return Ada.Strings.Fixed.Index (Expr, "..") /= 0;
   end Contains_Range_Dots;

   Storage_Unit_Bits : constant Natural := 8;

   function Global_First_Bit (Unit, First_Bit : Natural) return Natural is
   begin
      return Unit * Storage_Unit_Bits + First_Bit;
   end Global_First_Bit;

   function Global_Last_Bit (Unit, Last_Bit : Natural) return Natural is
   begin
      return Unit * Storage_Unit_Bits + Last_Bit;
   end Global_Last_Bit;

   function Find_Type_By_Name
     (Analysis : Analysis_Result;
      Name     : Unbounded_String) return Symbol_Id is
      Wanted : constant String := Lower (Trim (To_String (Name)));
   begin
      if Wanted = "" then
         return No_Symbol;
      end if;

      for I in 1 .. Symbol_Count (Analysis) loop
         declare
            S : constant Symbol_Info := Symbol_At (Analysis, I);
         begin
            if S.Kind in Symbol_Type | Symbol_Subtype | Symbol_Record_Type | Symbol_Generic_Formal_Type
              and then To_String (S.Normalized_Name) = Wanted
            then
               return S.Id;
            end if;
         end;
      end loop;

      return No_Symbol;
   end Find_Type_By_Name;

   function Static_Size_For_Target
     (Analysis : Analysis_Result;
      Target   : Symbol_Id;
      Found    : out Boolean) return Natural is
   begin
      Found := False;
      if Target = No_Symbol then
         return 0;
      end if;

      for I in 1 .. Representation_Clause_Count (Analysis) loop
         declare
            R : constant Representation_Clause_Info :=
              Representation_Clause_At (Analysis, No_Symbol, I);
         begin
            if R.Target_Symbol = Target
              and then R.Kind in Representation_Size_Clause
                           | Representation_Object_Size_Clause
                           | Representation_Value_Size_Clause
              and then R.Has_Static_Value
            then
               Found := True;
               return R.Static_Value;
            end if;
         end;
      end loop;

      return 0;
   end Static_Size_For_Target;

   function Is_Local_Name_Start (C : Character) return Boolean is
   begin
      return (C >= 'A' and then C <= 'Z')
        or else (C >= 'a' and then C <= 'z');
   end Is_Local_Name_Start;

   function Is_Local_Name_Char (C : Character) return Boolean is
   begin
      return Is_Local_Name_Start (C)
        or else (C >= '0' and then C <= '9')
        or else C = '_';
   end Is_Local_Name_Char;

end Editor.Ada_Declaration_Parser.Range_Structure_Helpers;
