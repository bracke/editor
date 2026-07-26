with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Token_Cursor.Tokenization;
with Editor.Text_Helpers;

package body Editor.Ada_Token_Cursor.Contracts is
   use Editor.Ada_Token_Cursor.Tokenization;

   function Current_Lower (Position : Cursor) return String is
   begin
      return Editor.Text_Helpers.Lower (To_String (Current (Position).Text));
   end Current_Lower;

   function Is_Contract_Aspect_Mark (Name : String) return Boolean is
      L : constant String := Editor.Text_Helpers.Lower (Name);
   begin
      return L = "pre"
        or else L = "post"
        or else L = "type_invariant"
        or else L = "type_invariant'class"
        or else L = "dynamic_predicate"
        or else L = "static_predicate"
        or else L = "predicate"
        or else L = "global"
        or else L = "depends"
        or else L = "refined_global"
        or else L = "refined_depends"
        or else L = "initializes"
        or else L = "contract_cases"
        or else L = "exceptional_cases"
        or else L = "exit_cases"
        or else L = "always_terminates"
        or else L = "nonblocking"
        or else L = "pre'class"
        or else L = "post'class";
   end Is_Contract_Aspect_Mark;

   function Is_Classwide_Contract_Mark
     (Position    : Cursor;
      Aspect_Name : String) return Boolean is
      Probe : Cursor := Position;
   begin
      if not Is_Contract_Aspect_Mark (Aspect_Name) then
         return False;
      end if;
      if Editor.Text_Helpers.Lower (Aspect_Name) /= "pre"
        and then Editor.Text_Helpers.Lower (Aspect_Name) /= "post"
      then
         return False;
      end if;

      Advance (Probe);
      if At_End (Probe) or else To_String (Current (Probe).Text) /= "'" then
         return False;
      end if;

      Advance (Probe);
      return not At_End (Probe) and then Current_Lower (Probe) = "class";
   end Is_Classwide_Contract_Mark;

   function Has_Contract_Aspect_Before_Stop
     (Position     : Cursor;
      Stop_Keyword : String) return Boolean is
      Probe : Cursor := Position;
      Depth : Natural := 0;
   begin
      while not At_End (Probe) loop
         declare
            T : constant String := To_String (Current (Probe).Text);
            L : constant String := Current_Lower (Probe);
         begin
            exit when Depth = 0
              and then (T = ";"
                        or else (Stop_Keyword'Length > 0
                                 and then L = Editor.Text_Helpers.Lower (Stop_Keyword)));

            if Current (Probe).Kind = Token_Identifier
              or else Current (Probe).Kind = Token_Keyword
            then
               if Is_Contract_Aspect_Mark (To_String (Current (Probe).Text)) then
                  return True;
               end if;
            end if;

            if T = "(" then
               Depth := Depth + 1;
            elsif T = ")" and then Depth > 0 then
               Depth := Depth - 1;
            end if;
         end;
         Advance (Probe);
      end loop;

      return False;
   end Has_Contract_Aspect_Before_Stop;

   function At_Profile_Item_End (Position : Cursor) return Boolean is
      T : constant String := To_String (Current (Position).Text);
   begin
      return At_End (Position) or else T = ";" or else T = ")";
   end At_Profile_Item_End;

   function Access_Subprogram_Result_Has_Constraint
     (Position : Cursor) return Boolean is
      Depth : Natural := 0;
      Probe : Cursor := Position;
   begin
      while not At_End (Probe) loop
         declare
            Text : constant String := To_String (Current (Probe).Text);
            Lower : constant String := Current_Lower (Probe);
         begin
            if Text = "(" then
               if Depth = 0 then
                  return True;
               end if;
               Depth := Depth + 1;
            elsif Text = ")" then
               exit when Depth = 0;
               Depth := Depth - 1;
            elsif Depth = 0 and then (Lower = "range" or else Lower = "digits" or else Lower = "delta") then
               return True;
            elsif Depth = 0 and then (Text = ";" or else Text = ",") then
               return False;
            end if;
         end;
         Advance (Probe);
      end loop;
      return False;
   end Access_Subprogram_Result_Has_Constraint;

   function At_Component_Default_Reserved_Boundary
     (Position : Cursor) return Boolean is
      T : constant String := To_String (Current (Position).Text);
      L : constant String := Current_Lower (Position);
   begin
      return At_End (Position)
        or else T = ";"
        or else T = ","
        or else T = ")"
        or else L = "with"
        or else L = "is"
        or else L = "begin"
        or else L = "private"
        or else L = "end"
        or else L = "then"
        or else L = "else"
        or else L = "elsif"
        or else L = "or"
        or else L = "when"
        or else L = "exception"
        or else L = "do";
   end At_Component_Default_Reserved_Boundary;

   function At_Profile_Default_Reserved_Boundary
     (Position : Cursor) return Boolean is
      T : constant String := To_String (Current (Position).Text);
      L : constant String := Current_Lower (Position);
   begin
      return At_End (Position)
        or else T = ";"
        or else T = ")"
        or else T = ","
        or else T = "=>"
        or else L = "is"
        or else L = "with"
        or else L = "then"
        or else L = "else"
        or else L = "elsif"
        or else L = "or"
        or else L = "when"
        or else L = "exception"
        or else L = "end";
   end At_Profile_Default_Reserved_Boundary;

   function At_Number_Initialization_Reserved_Boundary
     (Position : Cursor) return Boolean is
      T : constant String := To_String (Current (Position).Text);
      L : constant String := Current_Lower (Position);
   begin
      return At_End (Position)
        or else T = ";"
        or else T = ","
        or else T = ")"
        or else L = "with"
        or else L = "is"
        or else L = "begin"
        or else L = "private"
        or else L = "end"
        or else L = "then"
        or else L = "else"
        or else L = "elsif"
        or else L = "or"
        or else L = "when"
        or else L = "exception"
        or else L = "do";
   end At_Number_Initialization_Reserved_Boundary;

   function At_Object_Subtype_Reserved_Boundary
     (Position : Cursor) return Boolean is
      T : constant String := To_String (Current (Position).Text);
      L : constant String := Current_Lower (Position);
   begin
      return At_End (Position)
        or else T = ";"
        or else T = ","
        or else T = ")"
        or else T = ":="
        or else L = "is"
        or else L = "with"
        or else L = "begin"
        or else L = "private"
        or else L = "end"
        or else L = "then"
        or else L = "else"
        or else L = "elsif"
        or else L = "or"
        or else L = "when"
        or else L = "exception"
        or else L = "do";
   end At_Object_Subtype_Reserved_Boundary;

end Editor.Ada_Token_Cursor.Contracts;
