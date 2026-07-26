with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Token_Cursor.Tokenization;
with Editor.Text_Helpers;

package body Editor.Ada_Token_Cursor.Range_Structure_Helpers is
   use Editor.Ada_Token_Cursor.Tokenization;

   function Lower (S : String) return String
     renames Editor.Text_Helpers.Lower;

   function At_Iterator_Filter_Condition_Boundary
     (Position : Cursor) return Boolean is
      T : constant String := To_String (Current (Position).Text);
      L : constant String := To_String (Current (Position).Lower);
   begin
      return At_End (Position)
        or else T = "=>"
        or else T = ";"
        or else T = ","
        or else T = ")"
        or else L = "loop"
        or else L = "end"
        or else L = "else"
        or else L = "elsif";
   end At_Iterator_Filter_Condition_Boundary;

   function At_Case_Statement_Selector_Reserved_Boundary
     (Position : Cursor) return Boolean is
      T : constant String := To_String (Current (Position).Text);
      L : constant String := To_String (Current (Position).Lower);
   begin
      return At_End (Position)
        or else T = ";"
        or else T = ","
        or else T = ")"
        or else T = "=>"
        or else L = "is"
        or else L = "when"
        or else L = "then"
        or else L = "else"
        or else L = "elsif"
        or else L = "or"
        or else L = "exception"
        or else L = "end";
   end At_Case_Statement_Selector_Reserved_Boundary;

   function At_Loop_Domain_Reserved_Boundary
     (Position : Cursor) return Boolean is
      T : constant String := To_String (Current (Position).Text);
      L : constant String := To_String (Current (Position).Lower);
   begin
      return At_End (Position)
        or else T = ";"
        or else T = ","
        or else T = ")"
        or else T = "=>"
        or else L = "loop"
        or else L = "when"
        or else L = "then"
        or else L = "else"
        or else L = "elsif"
        or else L = "or"
        or else L = "exception"
        or else L = "end";
   end At_Loop_Domain_Reserved_Boundary;

   function At_Iterated_Component_Expression_Boundary
     (Position : Cursor) return Boolean is
      T : constant String := To_String (Current (Position).Text);
      L : constant String := To_String (Current (Position).Lower);
   begin
      return At_End (Position)
        or else T = ";"
        or else T = ","
        or else T = ")"
        or else T = "=>"
        or else L = "when"
        or else L = "else"
        or else L = "elsif"
        or else L = "end";
   end At_Iterated_Component_Expression_Boundary;

   function At_Aggregate_Component_Expression_Boundary
     (Position : Cursor) return Boolean is
      T : constant String := To_String (Current (Position).Text);
      L : constant String := To_String (Current (Position).Lower);
   begin
      return At_End (Position)
        or else T = ";"
        or else T = ","
        or else T = ")"
        or else T = "]"
        or else T = "=>"
        or else L = "then"
        or else L = "else"
        or else L = "elsif"
        or else L = "or"
        or else L = "when"
        or else L = "exception"
        or else L = "end";
   end At_Aggregate_Component_Expression_Boundary;

   function At_Conditional_Expression_Dependent_Boundary
     (Position : Cursor) return Boolean is
      T : constant String := To_String (Current (Position).Text);
      L : constant String := To_String (Current (Position).Lower);
   begin
      return At_End (Position)
        or else T = ";"
        or else T = ","
        or else T = ")"
        or else T = "=>"
        or else L = "then"
        or else L = "else"
        or else L = "elsif"
        or else L = "when"
        or else L = "is"
        or else L = "begin"
        or else L = "private"
        or else L = "end";
   end At_Conditional_Expression_Dependent_Boundary;

   function At_Case_Expression_Selector_Boundary
     (Position : Cursor) return Boolean is
      T : constant String := To_String (Current (Position).Text);
      L : constant String := To_String (Current (Position).Lower);
   begin
      return At_End (Position)
        or else T = ";"
        or else T = ","
        or else T = ")"
        or else T = "=>"
        or else L = "is"
        or else L = "when"
        or else L = "then"
        or else L = "else"
        or else L = "elsif"
        or else L = "begin"
        or else L = "private"
        or else L = "end";
   end At_Case_Expression_Selector_Boundary;

   function At_Quantified_Predicate_Boundary
     (Position : Cursor) return Boolean is
      T : constant String := To_String (Current (Position).Text);
      L : constant String := To_String (Current (Position).Lower);
   begin
      return At_End (Position)
        or else T = ";"
        or else T = ","
        or else T = ")"
        or else T = "=>"
        or else L = "then"
        or else L = "else"
        or else L = "elsif"
        or else L = "when"
        or else L = "end";
   end At_Quantified_Predicate_Boundary;

   function At_Declare_Expression_Body_Boundary
     (Position : Cursor) return Boolean is
      T : constant String := To_String (Current (Position).Text);
      L : constant String := To_String (Current (Position).Lower);
   begin
      return At_End (Position)
        or else T = ";"
        or else T = ","
        or else T = ")"
        or else T = "=>"
        or else L = "when"
        or else L = "else"
        or else L = "elsif"
        or else L = "end";
   end At_Declare_Expression_Body_Boundary;

   function At_Digits_Or_Delta_Reserved_Boundary
     (Position : Cursor) return Boolean is
      L : constant String := To_String (Current (Position).Lower);
   begin
      return L = "with"
        or else L = "do"
        or else L = "else"
        or else L = "elsif"
        or else L = "then"
        or else L = "when"
        or else L = "or"
        or else L = "exception";
   end At_Digits_Or_Delta_Reserved_Boundary;

   function At_Digits_Or_Delta_Expression_Boundary
     (Position : Cursor) return Boolean is
      T : constant String := To_String (Current (Position).Text);
      L : constant String := To_String (Current (Position).Lower);
   begin
      return At_End (Position)
        or else T = ";"
        or else T = ","
        or else T = ")"
        or else L = "is"
        or else L = "begin"
        or else L = "end"
        or else L = "private"
        or else L = "record"
        or else At_Digits_Or_Delta_Reserved_Boundary (Position);
   end At_Digits_Or_Delta_Expression_Boundary;

   function Parenthesized_Constraint_Has_Arrow
     (Position : Cursor) return Boolean is
      Probe : Cursor := Position;
      Depth : Natural := 0;
   begin
      if To_String (Current (Probe).Text) /= "(" then
         return False;
      end if;

      while not At_End (Probe) loop
         declare
            T : constant String := To_String (Current (Probe).Text);
         begin
            if T = "(" then
               Depth := Depth + 1;
            elsif T = ")" then
               if Depth = 0 then
                  exit;
               end if;
               Depth := Depth - 1;
            elsif T = "=>" and then Depth = 1 then
               return True;
            elsif T = ";" and then Depth = 0 then
               exit;
            end if;
         end;
         Advance (Probe);
      end loop;

      return False;
   end Parenthesized_Constraint_Has_Arrow;

   function Has_Top_Level_Arrow_Before_Constraint_Association_End
     (Position : Cursor) return Boolean is
      Probe : Cursor := Position;
      Depth : Natural := 0;
   begin
      while not At_End (Probe) loop
         declare
            T : constant String := To_String (Current (Probe).Text);
         begin
            if T = "(" then
               Depth := Depth + 1;
            elsif T = ")" then
               if Depth = 0 then
                  exit;
               end if;
               Depth := Depth - 1;
            elsif T = "=>" and then Depth = 0 then
               return True;
            elsif T = "," and then Depth = 0 then
               exit;
            end if;
         end;
         Advance (Probe);
      end loop;

      return False;
   end Has_Top_Level_Arrow_Before_Constraint_Association_End;

   function Parenthesized_Name_Suffix_Is_Slice
     (Position : Cursor) return Boolean is
      Probe : Cursor := Position;
      Depth : Natural := 0;
   begin
      if To_String (Current (Probe).Text) /= "(" then
         return False;
      end if;

      while not At_End (Probe) loop
         declare
            T : constant String := To_String (Current (Probe).Text);
         begin
            if T = "(" then
               Depth := Depth + 1;
            elsif T = ")" then
               if Depth = 0 then
                  exit;
               end if;
               Depth := Depth - 1;
            elsif T = ".." and then Depth = 1 then
               return True;
            end if;
         end;
         Advance (Probe);
      end loop;

      return False;
   end Parenthesized_Name_Suffix_Is_Slice;

   function Has_Top_Level_Arrow_Before_Association_End
     (Position : Cursor) return Boolean is
      Probe : Cursor := Position;
      Depth : Natural := 0;
   begin
      while not At_End (Probe) loop
         declare
            T : constant String := To_String (Current (Probe).Text);
         begin
            if T = "(" or else T = "[" then
               Depth := Depth + 1;
            elsif T = ")" or else T = "]" then
               if Depth = 0 then
                  exit;
               end if;
               Depth := Depth - 1;
            elsif T = "=>" and then Depth = 0 then
               return True;
            elsif (T = "," or else T = ";") and then Depth = 0 then
               exit;
            end if;
         end;
         Advance (Probe);
      end loop;

      return False;
   end Has_Top_Level_Arrow_Before_Association_End;

   function Parenthesized_Has_Top_Level_Token
     (Position : Cursor;
      Text     : String) return Boolean is
      Probe : Cursor := Position;
      Depth : Natural := 0;
      Wanted : constant String := Lower (Text);
   begin
      if To_String (Current (Probe).Text) /= "(" then
         return False;
      end if;

      while not At_End (Probe) loop
         declare
            T : constant String := To_String (Current (Probe).Text);
            L : constant String := To_String (Current (Probe).Lower);
         begin
            if T = "(" then
               Depth := Depth + 1;
            elsif T = ")" then
               if Depth = 0 then
                  exit;
               end if;
               Depth := Depth - 1;
               exit when Depth = 0;
            elsif Depth = 1 and then (T = Text or else L = Wanted) then
               return True;
            elsif Depth = 0 and then (T = "," or else T = ";" or else T = "=>" or else T = ")") then
               exit;
            end if;
         end;
         Advance (Probe);
      end loop;

      return False;
   end Parenthesized_Has_Top_Level_Token;

end Editor.Ada_Token_Cursor.Range_Structure_Helpers;
