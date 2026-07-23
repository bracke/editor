with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Text_Helpers;
with Editor.Ada_Token_Cursor.Navigation_Helpers;

package body Editor.Ada_Token_Cursor.Parsing_Predicates is

   function Lower (S : String) return String
     renames Editor.Text_Helpers.Lower;

   function Is_Statement_Starter_After_Label
     (Position : Editor.Ada_Token_Cursor.Cursor) return Boolean is
      L0 : constant String :=
        Editor.Ada_Token_Cursor.Navigation_Helpers.Current_Lower (Position);
      L1 : constant String :=
        Editor.Ada_Token_Cursor.Navigation_Helpers.Lookahead_Lower (Position, 1);
   begin
      return
        L0 = "if"
        or else L0 = "case"
        or else L0 = "loop"
        or else L0 = "while"
        or else L0 = "for"
        or else L0 = "declare"
        or else L0 = "begin"
        or else L0 = "select"
        or else L0 = "accept"
        or else L0 = "return"
        or else L0 = "raise"
        or else L0 = "null"
        or else L0 = "exit"
        or else L0 = "goto"
        or else L0 = "delay"
        or else L0 = "requeue"
        or else L0 = "abort"
        or else L0 = "pragma"
        or else (L0 = "then" and then L1 = "abort");
   end Is_Statement_Starter_After_Label;

   function Parenthesized_Actual_Has_Top_Level_Arrow
     (Position : Editor.Ada_Token_Cursor.Cursor) return Boolean is
      Probe : Editor.Ada_Token_Cursor.Cursor := Position;
      Depth : Natural := 0;
   begin
      if To_String (Editor.Ada_Token_Cursor.Current (Probe).Text) /= "(" then
         return False;
      end if;

      while not Editor.Ada_Token_Cursor.At_End (Probe) loop
         declare
            T : constant String := To_String (Editor.Ada_Token_Cursor.Current (Probe).Text);
         begin
            if T = "(" or else T = "[" then
               Depth := Depth + 1;
            elsif T = ")" then
               if Depth = 0 then
                  return False;
               elsif Depth = 1 then
                  return False;
               else
                  Depth := Depth - 1;
               end if;
            elsif T = "]" then
               if Depth > 0 then
                  Depth := Depth - 1;
               end if;
            elsif Depth = 1 and then T = "=>" then
               return True;
            end if;
         end;
         Editor.Ada_Token_Cursor.Advance (Probe);
      end loop;
      return False;
   end Parenthesized_Actual_Has_Top_Level_Arrow;

   function Starts_Generic_Instantiation
     (Position  : Editor.Ada_Token_Cursor.Cursor;
      Unit_Kind : String) return Boolean is
      Probe : Editor.Ada_Token_Cursor.Cursor := Position;
   begin
      if Editor.Ada_Token_Cursor.Navigation_Helpers.Current_Lower (Probe) /= Unit_Kind then
         return False;
      end if;

      Editor.Ada_Token_Cursor.Advance (Probe);

      if Unit_Kind = "package" then
         if Editor.Ada_Token_Cursor.Current (Probe).Kind /= Editor.Ada_Token_Cursor.Token_Identifier
           and then Editor.Ada_Token_Cursor.Current (Probe).Kind /= Editor.Ada_Token_Cursor.Token_Keyword
         then
            return False;
         end if;

         Editor.Ada_Token_Cursor.Advance (Probe);
         while not Editor.Ada_Token_Cursor.At_End (Probe)
           and then To_String (Editor.Ada_Token_Cursor.Current (Probe).Text) = "."
         loop
            Editor.Ada_Token_Cursor.Advance (Probe);
            if Editor.Ada_Token_Cursor.Current (Probe).Kind = Editor.Ada_Token_Cursor.Token_Identifier
              or else Editor.Ada_Token_Cursor.Current (Probe).Kind = Editor.Ada_Token_Cursor.Token_Keyword
            then
               Editor.Ada_Token_Cursor.Advance (Probe);
            else
               return False;
            end if;
         end loop;
      else
         while not Editor.Ada_Token_Cursor.At_End (Probe)
           and then Editor.Ada_Token_Cursor.Navigation_Helpers.Current_Lower (Probe) /= "is"
           and then To_String (Editor.Ada_Token_Cursor.Current (Probe).Text) /= ";"
         loop
            Editor.Ada_Token_Cursor.Advance (Probe);
         end loop;
      end if;

      if Editor.Ada_Token_Cursor.Navigation_Helpers.Current_Lower (Probe) /= "is" then
         return False;
      end if;

      Editor.Ada_Token_Cursor.Advance (Probe);
      return Editor.Ada_Token_Cursor.Navigation_Helpers.Current_Lower (Probe) = "new";
   end Starts_Generic_Instantiation;

   function Formal_Package_Actual_Has_Top_Level_Arrow
     (Position : Editor.Ada_Token_Cursor.Cursor) return Boolean is
      Probe : Editor.Ada_Token_Cursor.Cursor := Position;
      Depth : Natural := 0;
   begin
      while not Editor.Ada_Token_Cursor.At_End (Probe) loop
         declare
            T : constant String := To_String (Editor.Ada_Token_Cursor.Current (Probe).Text);
         begin
            if T = "(" or else T = "[" then
               Depth := Depth + 1;
            elsif T = ")" then
               if Depth = 0 then
                  return False;
               else
                  Depth := Depth - 1;
               end if;
            elsif T = "]" then
               if Depth > 0 then
                  Depth := Depth - 1;
               end if;
            elsif Depth = 0 and then (T = "," or else T = ";") then
               return False;
            elsif Depth = 0 and then T = "=>" then
               return True;
            end if;
         end;
         Editor.Ada_Token_Cursor.Advance (Probe);
      end loop;
      return False;
   end Formal_Package_Actual_Has_Top_Level_Arrow;

   function Formal_Package_Actual_Looks_Like_Missing_Arrow
     (Position : Editor.Ada_Token_Cursor.Cursor) return Boolean is
      Probe : Editor.Ada_Token_Cursor.Cursor := Position;
      Depth : Natural := 0;
      Top_Level_Tokens : Natural := 0;
      Saw_Operator : Boolean := False;
   begin
      while not Editor.Ada_Token_Cursor.At_End (Probe) loop
         declare
            T : constant String := To_String (Editor.Ada_Token_Cursor.Current (Probe).Text);
         begin
            if T = "(" or else T = "[" then
               Depth := Depth + 1;
            elsif T = ")" then
               if Depth = 0 then
                  exit;
               else
                  Depth := Depth - 1;
               end if;
            elsif T = "]" then
               if Depth > 0 then
                  Depth := Depth - 1;
               end if;
            elsif Depth = 0 and then (T = "," or else T = ";") then
               exit;
            elsif Depth = 0 and then T = "=>" then
               return False;
            elsif Depth = 0 then
               Top_Level_Tokens := Top_Level_Tokens + 1;
               if T = "+" or else T = "-" or else T = "*"
                 or else T = "/" or else T = "**" or else T = "&"
                 or else T = "=" or else T = "/=" or else T = "<"
                 or else T = "<=" or else T = ">" or else T = ">="
               then
                  Saw_Operator := True;
               end if;
            end if;
         end;
         Editor.Ada_Token_Cursor.Advance (Probe);
      end loop;

      return Top_Level_Tokens >= 2 and then not Saw_Operator;
   end Formal_Package_Actual_Looks_Like_Missing_Arrow;

   function Has_Top_Level_With_Before_Association_End
     (Position : Editor.Ada_Token_Cursor.Cursor) return Boolean is
      Probe : Editor.Ada_Token_Cursor.Cursor := Position;
      Depth : Natural := 0;
   begin
      while not Editor.Ada_Token_Cursor.At_End (Probe) loop
         declare
            T : constant String := To_String (Editor.Ada_Token_Cursor.Current (Probe).Text);
            L : constant String :=
              Editor.Ada_Token_Cursor.Navigation_Helpers.Current_Lower (Probe);
         begin
            if T = "(" or else T = "[" then
               Depth := Depth + 1;
            elsif T = ")" then
               if Depth = 0 then
                  return False;
               else
                  Depth := Depth - 1;
               end if;
            elsif T = "]" then
               if Depth > 0 then
                  Depth := Depth - 1;
               end if;
            elsif Depth = 0 and then T = "," then
               return False;
            elsif Depth = 0 and then L = "with" then
               return Editor.Ada_Token_Cursor.Navigation_Helpers.Lookahead_Lower (Probe, 1) /= "delta";
            end if;
         end;
         Editor.Ada_Token_Cursor.Advance (Probe);
      end loop;
      return False;
   end Has_Top_Level_With_Before_Association_End;

   function Has_Top_Level_With_Delta_Before_Association_End
     (Position : Editor.Ada_Token_Cursor.Cursor) return Boolean is
      Probe : Editor.Ada_Token_Cursor.Cursor := Position;
      Depth : Natural := 0;
   begin
      while not Editor.Ada_Token_Cursor.At_End (Probe) loop
         declare
            T : constant String := To_String (Editor.Ada_Token_Cursor.Current (Probe).Text);
            L : constant String :=
              Editor.Ada_Token_Cursor.Navigation_Helpers.Current_Lower (Probe);
         begin
            if T = "(" or else T = "[" then
               Depth := Depth + 1;
            elsif T = ")" then
               if Depth = 0 then
                  return False;
               else
                  Depth := Depth - 1;
               end if;
            elsif T = "]" then
               if Depth > 0 then
                  Depth := Depth - 1;
               end if;
            elsif Depth = 0 and then T = "," then
               return False;
            elsif Depth = 0 and then L = "with" then
               return Editor.Ada_Token_Cursor.Navigation_Helpers.Lookahead_Lower (Probe, 1) = "delta";
            end if;
         end;
         Editor.Ada_Token_Cursor.Advance (Probe);
      end loop;
      return False;
   end Has_Top_Level_With_Delta_Before_Association_End;

end Editor.Ada_Token_Cursor.Parsing_Predicates;
