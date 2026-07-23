with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Phase_Types;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_String_Metadata;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Declaration_Parser.Declaration_Projection_Helpers;
with Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers;
with Editor.Ada_Declaration_Parser.Representation_Static_Values;
with Editor.Ada_Declaration_Parser.Static_Attribute_Registry;
with Editor.Ada_Language_Model;
with Editor.Ada_Syntax_Tree;
with Editor.Text_Helpers;

package body Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Derivation is

   use Editor.Ada_Syntax_Tree;
   use Editor.Text_Helpers;
   package Target_String_Metadata renames
     Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_String_Metadata;

   procedure Apply_Static_Number_Metadata_Phase
     (Phase   : in out Context;
      Actions : Operations)
   is
   begin
      for I in 1 .. Phase.Static_Declaration_Count loop
         declare
            D : constant Phase_Types.Static_Declaration_Info :=
              Phase.Static_Declaration_Infos (I);
            Name : constant String := To_String (D.Name);
            Default_Text : constant String := To_String (D.Default_Text);
         begin
            if D.Kind = Node_Number_Declaration then
               if Default_Text /= ""
                 and then Actions.Is_Static_Numeric_Value (Default_Text)
               then
                  Register_Static_Numeric_Name (Phase, Name);
               end if;
               Register_Static_Named_Number
                 (Phase,
                  Name,
                  Default_Text,
                  Actions.Parse_Static_Natural,
                  Actions.Parse_Static_Integer,
                  Actions.Is_Static_Numeric_Value);
            end if;
         end;
      end loop;
   end Apply_Static_Number_Metadata_Phase;

   procedure Apply_Static_Constant_Metadata_Phase
     (Phase   : in out Context;
      Actions : Operations)
   is
   begin
      for I in 1 .. Phase.Static_Declaration_Count loop
         declare
            D : constant Phase_Types.Static_Declaration_Info :=
              Phase.Static_Declaration_Infos (I);
            Name : constant String := To_String (D.Name);
            Subtype_Text : constant String := To_String (D.Subtype_Text);
            Default_Text : constant String := To_String (D.Default_Text);
         begin
            if D.Kind = Node_Constant_Declaration and then Default_Text /= "" then
               declare
                  Constant_Subtype_Text : constant String :=
                    Editor.Ada_Declaration_Parser.Representation_Static_Values.
                      Strip_Constant_Subtype_Prefix (Subtype_Text);
               begin
                  if Actions.Static_Constant_Default_Compatible
                    (Constant_Subtype_Text, Default_Text)
                  then
                     if Actions.Is_Static_Numeric_Value (Default_Text) then
                        Register_Static_Numeric_Name (Phase, Name);
                     end if;
                     Register_Static_Named_Number
                       (Phase,
                        Name,
                        Default_Text,
                        Actions.Parse_Static_Natural,
                        Actions.Parse_Static_Integer,
                        Actions.Is_Static_Numeric_Value);
                  end if;

                  if Actions.Is_Simple_Static_Type_Name (Constant_Subtype_Text) then
                     Register_Static_Discrete_Constant
                       (Phase,
                        Name,
                        Constant_Subtype_Text,
                        Default_Text,
                        Actions.Static_Discrete_Default_Position);
                  end if;

                  if Static_Subtype_Root (Phase, Constant_Subtype_Text) = "string"
                    or else Static_Subtype_Root (Phase, Constant_Subtype_Text) =
                      "standard.string"
                  then
                     Target_String_Metadata.Register_Static_String_Constant
                       (Phase,
                        Name,
                        Constant_Subtype_Text,
                        Default_Text,
                        Actions.Static_String_Default_Value);
                  end if;
               end;
            end if;
         end;
      end loop;
   end Apply_Static_Constant_Metadata_Phase;

   procedure Apply_Static_Enumeration_Type_Metadata_Phase
     (Phase   : in out Context;
      Actions : Operations)
   is
   begin
      for I in 1 .. Phase.Static_Declaration_Count loop
         declare
            D : constant Phase_Types.Static_Declaration_Info :=
              Phase.Static_Declaration_Infos (I);
            Name : constant String := To_String (D.Name);
            Subtype_Text : constant String := To_String (D.Subtype_Text);
            L : constant String := Lower (Trim (Subtype_Text));
         begin
            if D.Kind = Node_Type_Declaration
              and then L'Length >= 2
              and then L (L'First) = '('
              and then L (L'Last) = ')'
            then
               Register_Static_Enumeration_Type (Phase, Name, Subtype_Text);
            end if;
         end;
      end loop;
   end Apply_Static_Enumeration_Type_Metadata_Phase;

   procedure Register_Static_Type_Range
     (Phase      : in out Context;
      Actions    : Operations;
      Name       : String;
      Low_Text   : String;
      High_Text  : String;
      Is_Modular : Boolean := False)
   is
      Low_Int_Valid  : Boolean := False;
      Low_Int        : Integer := 0;
      High_Valid     : Boolean := False;
      High_Nat       : Natural := 0;
      High_Int_Valid : Boolean := False;
      High_Int       : Integer := 0;
      N              : constant String :=
        Editor.Ada_Language_Model.Normalize_Name (Name);
      Low_Value      : Integer := 0;
      High_Value     : Integer := 0;
      Low_Source     : constant String := Trim (Low_Text);
      High_Source    : constant String := Trim (High_Text);
   begin
      if N = "" then
         return;
      end if;

      if Is_Modular then
         Actions.Parse_Static_Natural (High_Source, High_Valid, High_Nat);
         if not High_Valid or else High_Nat = 0 then
            return;
         end if;

         Low_Value := 0;
         High_Value := Integer (High_Nat - 1);
      else
         Actions.Parse_Static_Integer (Low_Source, Low_Int_Valid, Low_Int);
         Actions.Parse_Static_Integer (High_Source, High_Int_Valid, High_Int);
         if not (Low_Int_Valid and then High_Int_Valid) then
            return;
         end if;

         Low_Value := Low_Int;
         High_Value := High_Int;
         if Low_Value > High_Value then
            return;
         end if;
      end if;

      Store_Static_Type_Range (Phase, N, Low_Value, High_Value, Is_Modular);
   exception
      when Constraint_Error =>
         null;
   end Register_Static_Type_Range;

   procedure Apply_Static_Type_Range_Metadata_Phase
     (Phase   : in out Context;
      Actions : Operations)
   is
   begin
      for I in 1 .. Phase.Static_Declaration_Count loop
         declare
            D : constant Phase_Types.Static_Declaration_Info :=
              Phase.Static_Declaration_Infos (I);
            Name : constant String := To_String (D.Name);
            Subtype_Text : constant String := To_String (D.Subtype_Text);
            L : constant String := Lower (Trim (Subtype_Text));
            At_Range : constant Natural := Ada.Strings.Fixed.Index (L, "range");
            At_Dots : constant Natural := Ada.Strings.Fixed.Index (Subtype_Text, "..");
            At_Mod : constant Natural := Ada.Strings.Fixed.Index (L, "mod");
         begin
            if D.Kind = Node_Type_Declaration
              and then At_Range /= 0
              and then At_Dots /= 0
            then
               Register_Static_Type_Range
                 (Phase,
                  Actions,
                  Name,
                  Trim (Subtype_Text (At_Range + 5 .. At_Dots - 1)),
                  Trim (Subtype_Text (At_Dots + 2 .. Subtype_Text'Last)),
                  False);
            elsif D.Kind = Node_Type_Declaration
              and then At_Mod /= 0
              and then At_Mod + 3 <= Subtype_Text'Last
            then
               Register_Static_Type_Range
                 (Phase,
                  Actions,
                  Name,
                  "0",
                  Trim (Subtype_Text (At_Mod + 3 .. Subtype_Text'Last)),
                  True);
            elsif D.Kind = Node_Type_Declaration
              and then L'Length > 4
              and then L (L'First .. L'First + 3) = "new "
              and then Actions.Is_Simple_Static_Type_Name
                (Trim (Subtype_Text (Subtype_Text'First + 4 .. Subtype_Text'Last)))
            then
               Register_Static_Type_Range_From_Base
                 (Phase,
                  Name,
                  Trim (Subtype_Text (Subtype_Text'First + 4 .. Subtype_Text'Last)));
            end if;
         end;
      end loop;
   end Apply_Static_Type_Range_Metadata_Phase;

   procedure Register_Static_Subtype_Range_From_Base
     (Phase     : in out Context;
      Actions   : Operations;
      Name      : String;
      Base_Name : String;
      Low_Text  : String;
      High_Text : String)
   is
      Low_Valid       : Boolean := False;
      Low_Value       : Integer := 0;
      High_Valid      : Boolean := False;
      High_Value      : Integer := 0;
      Low_Pos_Valid   : Boolean := False;
      Low_Pos         : Natural := 0;
      High_Pos_Valid  : Boolean := False;
      High_Pos        : Natural := 0;
   begin
      if Name = "" or else Base_Name = "" then
         return;
      end if;

      Actions.Parse_Static_Integer (Low_Text, Low_Valid, Low_Value);
      Actions.Parse_Static_Integer (High_Text, High_Valid, High_Value);

      if not Low_Valid then
         Low_Pos_Valid :=
           Actions.Static_Discrete_Default_Position
             (Base_Name, Low_Text, Low_Pos);
         if Low_Pos_Valid then
            Low_Value := Integer (Low_Pos);
            Low_Valid := True;
         end if;
      end if;

      if not High_Valid then
         High_Pos_Valid :=
           Actions.Static_Discrete_Default_Position
             (Base_Name, High_Text, High_Pos);
         if High_Pos_Valid then
            High_Value := Integer (High_Pos);
            High_Valid := True;
         end if;
      end if;

      if Low_Valid and then High_Valid and then Low_Value <= High_Value then
         Store_Static_Type_Range
           (Phase,
            Name,
            Low_Value,
            High_Value,
            Is_Modular => Static_Type_Is_Modular (Phase, Base_Name));
         Store_Static_Subtype_Alias (Phase, Name, Base_Name);
         Register_Static_Discrete_Literals_From_Base (Phase, Name, Base_Name);
      end if;
   exception
      when Constraint_Error =>
         null;
   end Register_Static_Subtype_Range_From_Base;

   procedure Apply_Static_Subtype_Range_Metadata_Phase
     (Phase   : in out Context;
      Actions : Operations)
   is
   begin
      for I in 1 .. Phase.Static_Declaration_Count loop
         declare
            D : constant Phase_Types.Static_Declaration_Info :=
              Phase.Static_Declaration_Infos (I);
            Name : constant String := To_String (D.Name);
            Subtype_Text : constant String := To_String (D.Subtype_Text);
            L : constant String := Lower (Trim (Subtype_Text));
            At_Range : constant Natural := Ada.Strings.Fixed.Index (L, "range");
            At_Dots : constant Natural := Ada.Strings.Fixed.Index (Subtype_Text, "..");
            At_Paren : constant Natural := Ada.Strings.Fixed.Index (Subtype_Text, "(");
         begin
            if D.Kind = Node_Subtype_Declaration
              and then At_Range /= 0
              and then At_Dots /= 0
              and then At_Paren = 0
            then
               declare
                  Base_Text : constant String :=
                    Trim (Subtype_Text (Subtype_Text'First .. At_Range - 1));
               begin
                  if Actions.Is_Simple_Static_Type_Name (Base_Text) then
                     Register_Static_Subtype_Range_From_Base
                       (Phase,
                        Actions,
                        Name,
                        Base_Text,
                        Trim (Subtype_Text (At_Range + 5 .. At_Dots - 1)),
                        Trim (Subtype_Text (At_Dots + 2 .. Subtype_Text'Last)));
                  else
                     Register_Static_Type_Range
                       (Phase,
                        Actions,
                        Name,
                        Trim (Subtype_Text (At_Range + 5 .. At_Dots - 1)),
                        Trim (Subtype_Text (At_Dots + 2 .. Subtype_Text'Last)),
                        False);
                  end if;
               end;
            end if;
         end;
      end loop;
   end Apply_Static_Subtype_Range_Metadata_Phase;

   procedure Store_Static_String_Subtype_Bounds
     (Phase     : in out Context;
      Actions   : Operations;
      Name      : String;
      Low_Text  : String;
      High_Text : String)
   is
      N : constant String := Editor.Ada_Language_Model.Normalize_Name (Name);
      Low_Valid  : Boolean := False;
      High_Valid : Boolean := False;
      Low_Value  : Integer := 1;
      High_Value : Integer := 0;

      function String_Bound_Low_Expression (Text : String) return String is
         T        : constant String := Trim (Text);
         L        : constant String := Lower (T);
         Range_At : Natural := 0;
      begin
         declare
            J : Natural := L'First;
         begin
            while J <= L'Last loop
               if L (J) = '"' then
                  J := J + 1;
                  while J <= L'Last loop
                     if L (J) = '"' then
                        if J < L'Last and then L (J + 1) = '"' then
                           J := J + 2;
                        else
                           J := J + 1;
                           exit;
                        end if;
                     else
                        J := J + 1;
                     end if;
                  end loop;
               elsif L (J) = Character'Val (39)
                 and then J + 2 <= L'Last
                 and then L (J + 2) = Character'Val (39)
               then
                  J := J + 3;
               elsif J + 4 <= L'Last
                 and then L (J .. J + 4) = "range"
                 and then (J = L'First or else not Is_Word_Char (L (J - 1)))
                 and then (J + 5 > L'Last or else not Is_Word_Char (L (J + 5)))
                 and then (J = L'First or else T (J - 1) /= Character'Val (39))
               then
                  Range_At := J;
                  exit;
               else
                  J := J + 1;
               end if;
            end loop;
         end;

         if Range_At /= 0 then
            if Range_At + 5 <= T'Last then
               return Trim (T (Range_At + 5 .. T'Last));
            else
               return "";
            end if;
         else
            return T;
         end if;
      exception
         when Constraint_Error =>
            return T;
      end String_Bound_Low_Expression;
   begin
      if N = "" then
         return;
      end if;

      Actions.Parse_Static_Integer
        (String_Bound_Low_Expression (Low_Text), Low_Valid, Low_Value);
      Actions.Parse_Static_Integer (High_Text, High_Valid, High_Value);
      if not (Low_Valid and then High_Valid) then
         return;
      end if;

      Store_Static_String_Subtype_Bounds_Values
        (Phase, N, Low_Value, High_Value);
   exception
      when Constraint_Error =>
         null;
   end Store_Static_String_Subtype_Bounds;

   procedure Apply_Static_String_Subtype_Metadata_Phase
     (Phase   : in out Context;
      Actions : Operations)
   is
   begin
      for I in 1 .. Phase.Static_Declaration_Count loop
         declare
            D : constant Phase_Types.Static_Declaration_Info :=
              Phase.Static_Declaration_Infos (I);
            Name : constant String := To_String (D.Name);
            Subtype_Text : constant String := To_String (D.Subtype_Text);
            At_Paren : constant Natural := Ada.Strings.Fixed.Index (Subtype_Text, "(");

            function String_Index_Constraint_Dots return Natural is
               Depth : Integer := 0;
               J     : Natural;
            begin
               if At_Paren = 0 or else At_Paren >= Subtype_Text'Last then
                  return 0;
               end if;

               J := At_Paren + 1;
               while J <= Subtype_Text'Last loop
                  if Subtype_Text (J) = '"' then
                     J := J + 1;
                     while J <= Subtype_Text'Last loop
                        if Subtype_Text (J) = '"' then
                           if J < Subtype_Text'Last
                             and then Subtype_Text (J + 1) = '"'
                           then
                              J := J + 2;
                           else
                              J := J + 1;
                              exit;
                           end if;
                        else
                           J := J + 1;
                        end if;
                     end loop;
                  elsif Subtype_Text (J) = Character'Val (39)
                    and then J + 2 <= Subtype_Text'Last
                    and then Subtype_Text (J + 2) = Character'Val (39)
                  then
                     J := J + 3;
                  elsif Subtype_Text (J) = '(' then
                     Depth := Depth + 1;
                     J := J + 1;
                  elsif Subtype_Text (J) = ')' then
                     if Depth = 0 then
                        exit;
                     end if;
                     Depth := Depth - 1;
                     J := J + 1;
                  elsif Subtype_Text (J) = '.'
                    and then J < Subtype_Text'Last
                    and then Subtype_Text (J + 1) = '.'
                    and then Depth = 0
                  then
                     return J;
                  else
                     J := J + 1;
                  end if;
               end loop;

               return 0;
            exception
               when Constraint_Error =>
                  return 0;
            end String_Index_Constraint_Dots;

            function Is_String_Index_Subtype return Boolean is
            begin
               return At_Paren /= 0
                 and then At_Paren > Subtype_Text'First
                 and then
                   (Static_Subtype_Root
                      (Phase,
                       Trim
                         (Subtype_Text
                            (Subtype_Text'First .. At_Paren - 1))) = "string"
                    or else Static_Subtype_Root
                      (Phase,
                       Trim
                         (Subtype_Text
                            (Subtype_Text'First .. At_Paren - 1))) =
                      "standard.string");
            exception
               when Constraint_Error =>
                  return False;
            end Is_String_Index_Subtype;
         begin
            if D.Kind = Node_Subtype_Declaration
              and then Is_String_Index_Subtype
            then
               Store_Static_Subtype_Alias (Phase, Name, "String");
               if Subtype_Text (Subtype_Text'Last) = ')' then
                  declare
                     Constraint_Dots : constant Natural :=
                       String_Index_Constraint_Dots;
                  begin
                     if Constraint_Dots /= 0 and then Constraint_Dots > At_Paren then
                        Store_Static_String_Subtype_Bounds
                          (Phase,
                           Actions,
                           Name,
                           Trim
                             (Subtype_Text (At_Paren + 1 .. Constraint_Dots - 1)),
                           Trim
                             (Subtype_Text
                                (Constraint_Dots + 2 .. Subtype_Text'Last - 1)));
                     else
                        Target_String_Metadata
                          .Store_Static_String_Subtype_Bounds_From_Range_Attribute
                          (Phase,
                           Name,
                           Trim
                             (Subtype_Text
                                (At_Paren + 1 .. Subtype_Text'Last - 1)),
                           Actions.Parse_Static_Integer,
                           Actions.Normalize_Character_Pos_Static_Operands,
                           Actions.Static_String_Default_Value,
                           Actions.Static_String_Bound_Value);
                     end if;
                  end;
               end if;
            end if;
         end;
      end loop;
   end Apply_Static_String_Subtype_Metadata_Phase;

   procedure Apply_Static_Subtype_Alias_Metadata_Phase
     (Phase   : in out Context;
      Actions : Operations)
   is
   begin
      for I in 1 .. Phase.Static_Declaration_Count loop
         declare
            D : constant Phase_Types.Static_Declaration_Info :=
              Phase.Static_Declaration_Infos (I);
            Name : constant String := To_String (D.Name);
            Subtype_Text : constant String := To_String (D.Subtype_Text);
         begin
            if D.Kind = Node_Subtype_Declaration
              and then Actions.Is_Simple_Static_Type_Name (Subtype_Text)
            then
               Register_Static_Type_Range_From_Base (Phase, Name, Subtype_Text);
               Store_Static_Subtype_Alias (Phase, Name, Subtype_Text);
               if Static_Subtype_Root (Phase, Subtype_Text) = "string"
                 or else Static_Subtype_Root (Phase, Subtype_Text) = "standard.string"
               then
                  Copy_Static_String_Subtype_Bounds_From_Base
                    (Phase, Name, Subtype_Text);
               end if;
            end if;
         end;
      end loop;
   end Apply_Static_Subtype_Alias_Metadata_Phase;

   procedure Run
     (Phase                  : in out Context;
      Declaration_Is_Complete : Boolean;
      Tree                   : Editor.Ada_Syntax_Tree.Tree_Type;
      Source_Text            : String;
      Actions                : Operations)
   is
      function First_Child_Label
        (Parent : Node_Id;
         Kind   : Node_Kind) return String
      is
      begin
         return Editor.Ada_Declaration_Parser.Declaration_Projection_Helpers
           .First_Child_Label (Tree, Parent, Kind);
      end First_Child_Label;
   begin
      Phase_Types.Require_Phase
        (Declaration_Is_Complete,
         "target derivation requires declaration collection");

      for I in 1 .. Node_Count (Tree) loop
         declare
            N : constant Node_Info := Node_At (Tree, I);
         begin
            if Editor.Ada_Declaration_Parser.Declaration_Projection_Helpers
              .Is_Declaration_Node (N.Kind)
            then
               declare
                  Subtype_Label : constant String :=
                    First_Child_Label (N.Id, Node_Declaration_Subtype);
                  Target_Label : constant String :=
                    First_Child_Label (N.Id, Node_Declaration_Target);
               begin
                  Phase.Static_Declaration_Count :=
                    Phase.Static_Declaration_Count + 1;
                  Phase.Static_Declaration_Infos
                    (Phase.Static_Declaration_Count) :=
                    (Kind => N.Kind,
                     Name => To_Unbounded_String
                       (Editor.Ada_Declaration_Parser
                          .Declaration_Projection_Metadata_Helpers
                          .Clean_Projected_Declaration_Name
                            (First_Child_Label (N.Id, Node_Declaration_Name))),
                     Subtype_Text => To_Unbounded_String
                       (if Subtype_Label /= "" then Subtype_Label else Target_Label),
                     Default_Text => To_Unbounded_String
                       (Editor.Ada_Declaration_Parser.Declaration_Projection_Helpers
                          .Full_Declaration_Default_Text
                            (Source_Text,
                             N,
                             First_Child_Label
                               (N.Id, Node_Declaration_Default))));
               end;
            end if;
         end;
      end loop;

      Apply_Static_Number_Metadata_Phase (Phase, Actions);
      Apply_Static_Enumeration_Type_Metadata_Phase (Phase, Actions);
      Apply_Static_Type_Range_Metadata_Phase (Phase, Actions);
      Apply_Static_Subtype_Range_Metadata_Phase (Phase, Actions);
      Apply_Static_String_Subtype_Metadata_Phase (Phase, Actions);
      Apply_Static_Subtype_Alias_Metadata_Phase (Phase, Actions);
      Apply_Static_Constant_Metadata_Phase (Phase, Actions);
      Apply_Static_Type_Range_Metadata_Phase (Phase, Actions);
      Apply_Static_Subtype_Range_Metadata_Phase (Phase, Actions);
      Apply_Static_String_Subtype_Metadata_Phase (Phase, Actions);
      Apply_Static_Subtype_Alias_Metadata_Phase (Phase, Actions);
      Apply_Static_Constant_Metadata_Phase (Phase, Actions);
      Apply_Static_Number_Metadata_Phase (Phase, Actions);
      Apply_Static_Type_Range_Metadata_Phase (Phase, Actions);
      Phase.Static_Metadata_Applied := True;
   end Run;

   function Static_Numeric_Name_Exists
     (Phase : Context;
      Name  : String) return Boolean
   is
      N : constant String := Editor.Ada_Language_Model.Normalize_Name (Name);
   begin
      if N = "" then
         return False;
      end if;

      for I in 1 .. Phase.Static.Numeric_Name_Count loop
         if To_String (Phase.Static.Numeric_Names (I)) = N then
            return True;
         end if;
      end loop;
      return False;
   end Static_Numeric_Name_Exists;

   procedure Register_Static_Numeric_Name
     (Phase : in out Context;
      Name  : String)
   is
      N : constant String := Editor.Ada_Language_Model.Normalize_Name (Name);
   begin
      if N = ""
        or else Phase.Static.Numeric_Name_Count >= Phase_Types.Max_Static_Numeric_Names
      then
         return;
      end if;

      if Static_Numeric_Name_Exists (Phase, N) then
         return;
      end if;

      Phase.Static.Numeric_Name_Count := Phase.Static.Numeric_Name_Count + 1;
      Phase.Static.Numeric_Names (Phase.Static.Numeric_Name_Count) :=
        To_Unbounded_String (N);
   end Register_Static_Numeric_Name;

   function Static_Named_Number_Value
     (Phase : Context;
      Name  : String;
      Value : out Natural) return Boolean
   is
      N : constant String := Editor.Ada_Language_Model.Normalize_Name (Name);
   begin
      Value := 0;
      if N = "" then
         return False;
      end if;

      for I in 1 .. Phase.Static.Named_Number_Count loop
         if To_String (Phase.Static.Named_Numbers (I).Normalized_Name) = N
           and then Phase.Static.Named_Numbers (I).Has_Natural_Value
         then
            Value := Phase.Static.Named_Numbers (I).Value;
            return True;
         end if;
      end loop;

      return False;
   end Static_Named_Number_Value;

   function Static_Integer_Name_Value
     (Phase : Context;
      Name  : String;
      Value : out Integer) return Boolean
   is
      N : constant String := Editor.Ada_Language_Model.Normalize_Name (Name);
   begin
      Value := 0;
      if N = "" then
         return False;
      end if;

      for I in 1 .. Phase.Static.Named_Number_Count loop
         if To_String (Phase.Static.Named_Numbers (I).Normalized_Name) = N
           and then Phase.Static.Named_Numbers (I).Has_Signed_Value
         then
            Value := Phase.Static.Named_Numbers (I).Signed_Value;
            return True;
         end if;
      end loop;

      return False;
   end Static_Integer_Name_Value;

   procedure Register_Static_Named_Number
     (Phase                   : in out Context;
      Name                    : String;
      Text                    : String;
      Parse_Static_Natural    : not null Static_Natural_Parser;
      Parse_Static_Integer    : not null Static_Integer_Parser;
      Is_Static_Numeric_Value : not null String_Query)
   is
      Valid : Boolean := False;
      Value : Natural := 0;
      Signed_Valid : Boolean := False;
      Signed_Value : Integer := 0;
      N     : constant String := Editor.Ada_Language_Model.Normalize_Name (Name);
   begin
      if N = ""
        or else Phase.Static.Named_Number_Count >= Phase_Types.Max_Static_Named_Numbers
      then
         return;
      end if;

      Parse_Static_Natural (Text, Valid, Value);
      Parse_Static_Integer (Text, Signed_Valid, Signed_Value);
      if not Valid and then not Signed_Valid then
         if Is_Static_Numeric_Value (Text) then
            Register_Static_Numeric_Name (Phase, Name);
         end if;
         return;
      end if;

      Register_Static_Numeric_Name (Phase, Name);

      for I in 1 .. Phase.Static.Named_Number_Count loop
         if To_String (Phase.Static.Named_Numbers (I).Normalized_Name) = N then
            Phase.Static.Named_Numbers (I).Has_Natural_Value := Valid;
            if Valid then
               Phase.Static.Named_Numbers (I).Value := Value;
            end if;
            Phase.Static.Named_Numbers (I).Has_Signed_Value := Signed_Valid;
            Phase.Static.Named_Numbers (I).Signed_Value := Signed_Value;
            return;
         end if;
      end loop;

      Phase.Static.Named_Number_Count := Phase.Static.Named_Number_Count + 1;
      Phase.Static.Named_Numbers (Phase.Static.Named_Number_Count) :=
        (Normalized_Name => To_Unbounded_String (N),
         Has_Natural_Value => Valid,
         Value => Value,
         Has_Signed_Value => Signed_Valid,
         Signed_Value => Signed_Value);
   end Register_Static_Named_Number;

   function Canonical_Static_Type_Name (Name : String) return String is
      N : constant String := Editor.Ada_Language_Model.Normalize_Name (Name);
   begin
      if N = "standard.boolean" then
         return "boolean";
      elsif N = "standard.character" then
         return "character";
      elsif N = "standard.string" then
         return "string";
      else
         return N;
      end if;
   end Canonical_Static_Type_Name;

   procedure Store_Static_Subtype_Alias
     (Phase     : in out Context;
      Name      : String;
      Base_Name : String)
   is
      N : constant String := Canonical_Static_Type_Name (Name);
      B : constant String := Canonical_Static_Type_Name (Base_Name);
   begin
      if N = "" or else B = "" or else N = B then
         return;
      end if;

      for I in 1 .. Phase.Static.Subtype_Alias_Count loop
         if To_String (Phase.Static.Subtype_Aliases (I).Normalized_Name) = N then
            Phase.Static.Subtype_Aliases (I).Normalized_Base :=
              To_Unbounded_String (B);
            return;
         end if;
      end loop;

      if Phase.Static.Subtype_Alias_Count >= Phase_Types.Max_Static_Subtype_Aliases then
         return;
      end if;

      Phase.Static.Subtype_Alias_Count := Phase.Static.Subtype_Alias_Count + 1;
      Phase.Static.Subtype_Aliases (Phase.Static.Subtype_Alias_Count) :=
        (Normalized_Name => To_Unbounded_String (N),
         Normalized_Base => To_Unbounded_String (B));
   end Store_Static_Subtype_Alias;

   function Static_Subtype_Root
     (Phase : Context;
      Name  : String) return String
   is
      Current : Unbounded_String :=
        To_Unbounded_String (Canonical_Static_Type_Name (Name));
      Previous : Unbounded_String := Null_Unbounded_String;
   begin
      if To_String (Current) = "" then
         return "";
      end if;

      for Step in 1 .. Phase_Types.Max_Static_Subtype_Aliases loop
         Previous := Current;
         for I in 1 .. Phase.Static.Subtype_Alias_Count loop
            if To_String (Phase.Static.Subtype_Aliases (I).Normalized_Name) =
              To_String (Current)
            then
               Current := Phase.Static.Subtype_Aliases (I).Normalized_Base;
               exit;
            end if;
         end loop;

         if To_String (Current) = To_String (Previous) then
            return To_String (Current);
         end if;
      end loop;

      return To_String (Current);
   end Static_Subtype_Root;

   procedure Store_Static_Type_Range
     (Phase      : in out Context;
      Name       : String;
      Low_Value  : Integer;
      High_Value : Integer;
      Is_Modular : Boolean := False)
   is
      N : constant String := Editor.Ada_Language_Model.Normalize_Name (Name);
   begin
      if N = "" or else Low_Value > High_Value then
         return;
      end if;

      for I in 1 .. Phase.Static.Type_Range_Count loop
         if To_String (Phase.Static.Type_Ranges (I).Normalized_Name) = N then
            Phase.Static.Type_Ranges (I) :=
              (Normalized_Name => To_Unbounded_String (N),
               Has_Low => True,
               Low => Low_Value,
               Has_High => True,
               High => High_Value,
               Is_Modular => Is_Modular);
            return;
         end if;
      end loop;

      if Phase.Static.Type_Range_Count >= Phase_Types.Max_Static_Type_Ranges then
         return;
      end if;

      Phase.Static.Type_Range_Count := Phase.Static.Type_Range_Count + 1;
      Phase.Static.Type_Ranges (Phase.Static.Type_Range_Count) :=
        (Normalized_Name => To_Unbounded_String (N),
         Has_Low => True,
         Low => Low_Value,
         Has_High => True,
         High => High_Value,
         Is_Modular => Is_Modular);
   end Store_Static_Type_Range;

   procedure Register_Static_Type_Range_From_Base
     (Phase     : in out Context;
      Name      : String;
      Base_Name : String)
   is
      Has_Low  : Boolean := False;
      Low      : Integer := 0;
      Has_High : Boolean := False;
      High     : Integer := 0;
   begin
      if Name = "" or else Base_Name = "" then
         return;
      end if;

      if Static_Type_Range (Phase, Base_Name, Has_Low, Low, Has_High, High)
        and then Has_Low
        and then Has_High
      then
         Store_Static_Type_Range
           (Phase,
            Name,
            Low,
            High,
            Is_Modular => Static_Type_Is_Modular (Phase, Base_Name));
         Register_Static_Discrete_Literals_From_Base (Phase, Name, Base_Name);
      end if;
   end Register_Static_Type_Range_From_Base;

   function Static_Type_Range
     (Phase    : Context;
      Name     : String;
      Has_Low  : out Boolean;
      Low      : out Integer;
      Has_High : out Boolean;
      High     : out Integer) return Boolean
   is
      N : constant String := Editor.Ada_Language_Model.Normalize_Name (Name);
   begin
      Has_Low := False;
      Low := 0;
      Has_High := False;
      High := 0;

      if N = "" then
         return False;
      elsif N = "natural" then
         Has_Low := True;
         Low := 0;
         return True;
      elsif N = "positive" then
         Has_Low := True;
         Low := 1;
         return True;
      elsif N = "integer" then
         return True;
      elsif N = "boolean" or else N = "standard.boolean" then
         Has_Low := True;
         Low := 0;
         Has_High := True;
         High := 1;
         return True;
      elsif N = "character" or else N = "standard.character" then
         Has_Low := True;
         Low := 0;
         Has_High := True;
         High := 255;
         return True;
      end if;

      for I in 1 .. Phase.Static.Type_Range_Count loop
         if To_String (Phase.Static.Type_Ranges (I).Normalized_Name) = N then
            Has_Low := Phase.Static.Type_Ranges (I).Has_Low;
            Low := Phase.Static.Type_Ranges (I).Low;
            Has_High := Phase.Static.Type_Ranges (I).Has_High;
            High := Phase.Static.Type_Ranges (I).High;
            return True;
         end if;
      end loop;

      return False;
   end Static_Type_Range;

   function Static_Value_In_Type_Range
     (Phase     : Context;
      Type_Name : String;
      Value     : Natural) return Boolean
   is
      Has_Low  : Boolean := False;
      Low      : Integer := 0;
      Has_High : Boolean := False;
      High     : Integer := 0;
   begin
      if not Static_Type_Range (Phase, Type_Name, Has_Low, Low, Has_High, High) then
         return True;
      else
         return Editor.Ada_Declaration_Parser.Representation_Static_Values
           .Natural_In_Integer_Range
             (Value, Has_Low, Low, Has_High, High);
      end if;
   end Static_Value_In_Type_Range;

   function Static_Type_Is_Modular
     (Phase : Context;
      Name  : String) return Boolean
   is
      N : constant String := Editor.Ada_Language_Model.Normalize_Name (Name);
   begin
      if N = "" then
         return False;
      end if;

      for I in 1 .. Phase.Static.Type_Range_Count loop
         if To_String (Phase.Static.Type_Ranges (I).Normalized_Name) = N then
            return Phase.Static.Type_Ranges (I).Is_Modular;
         end if;
      end loop;

      return False;
   end Static_Type_Is_Modular;

   function Static_Type_Modulus
     (Phase : Context;
      Name  : String;
      Value : out Natural) return Boolean
   is
      N : constant String := Editor.Ada_Language_Model.Normalize_Name (Name);
   begin
      Value := 0;
      if N = "" then
         return False;
      end if;

      declare
         Root : constant String := Static_Subtype_Root (Phase, Name);
      begin
         if Root /= N and then Static_Type_Modulus (Phase, Root, Value) then
            return True;
         end if;
      end;

      for I in 1 .. Phase.Static.Type_Range_Count loop
         if To_String (Phase.Static.Type_Ranges (I).Normalized_Name) = N
           and then Phase.Static.Type_Ranges (I).Is_Modular
           and then Phase.Static.Type_Ranges (I).Has_Low
           and then Phase.Static.Type_Ranges (I).Low = 0
           and then Phase.Static.Type_Ranges (I).Has_High
           and then Phase.Static.Type_Ranges (I).High >= 0
         then
            Value := Natural (Phase.Static.Type_Ranges (I).High) + 1;
            return True;
         end if;
      end loop;

      return False;
   exception
      when Constraint_Error =>
         return False;
   end Static_Type_Modulus;

   function Static_Type_Is_Character
     (Phase : Context;
      Name  : String) return Boolean
   is
      N : constant String := Editor.Ada_Language_Model.Normalize_Name (Name);
   begin
      if N = "" then
         return False;
      elsif N = "character" or else N = "standard.character" then
         return True;
      end if;

      for I in 1 .. Phase.Static.Character_Type_Count loop
         if To_String (Phase.Static.Character_Types (I)) = N then
            return True;
         end if;
      end loop;

      return False;
   end Static_Type_Is_Character;

   procedure Register_Static_Character_Type
     (Phase : in out Context;
      Name  : String)
   is
      N : constant String := Editor.Ada_Language_Model.Normalize_Name (Name);
   begin
      if N = "" or else Static_Type_Is_Character (Phase, N) then
         return;
      end if;

      if Phase.Static.Character_Type_Count >= Phase_Types.Max_Static_Character_Types then
         return;
      end if;

      Phase.Static.Character_Type_Count := Phase.Static.Character_Type_Count + 1;
      Phase.Static.Character_Types (Phase.Static.Character_Type_Count) :=
        To_Unbounded_String (N);
   end Register_Static_Character_Type;

   procedure Register_Static_Enumeration_Literal
     (Phase        : in out Context;
      Type_Name    : String;
      Literal_Name : String;
      Position     : Natural)
   is
      T : constant String := Editor.Ada_Language_Model.Normalize_Name (Type_Name);
      L : constant String := Editor.Ada_Language_Model.Normalize_Name (Literal_Name);
   begin
      if T = "" or else L = "" then
         return;
      end if;

      for I in 1 .. Phase.Static.Enumeration_Literal_Count loop
         if To_String
              (Phase.Static.Enumeration_Literals (I).Normalized_Type_Name) = T
           and then To_String
              (Phase.Static.Enumeration_Literals (I).Normalized_Literal_Name) = L
         then
            Phase.Static.Enumeration_Literals (I).Position := Position;
            return;
         end if;
      end loop;

      if Phase.Static.Enumeration_Literal_Count >=
        Phase_Types.Max_Static_Enumeration_Literals
      then
         return;
      end if;

      Phase.Static.Enumeration_Literal_Count :=
        Phase.Static.Enumeration_Literal_Count + 1;
      Phase.Static.Enumeration_Literals (Phase.Static.Enumeration_Literal_Count) :=
        (Normalized_Type_Name => To_Unbounded_String (T),
         Normalized_Literal_Name => To_Unbounded_String (L),
         Position => Position);
   end Register_Static_Enumeration_Literal;

   procedure Register_Static_Enumeration_Type
     (Phase        : in out Context;
      Name         : String;
      Subtype_Text : String)
   is
      T : constant String := Trim (Subtype_Text);
      Start : Natural;
      Item_Start : Natural;
      Item_Stop : Natural;
      Position : Natural := 0;

      function Is_Static_Identifier_Name (Text : String) return Boolean is
         T : constant String := Trim (Text);
      begin
         if T = "" then
            return False;
         end if;

         for I in T'Range loop
            if I = T'First then
               if not (T (I) in 'A' .. 'Z' or else T (I) in 'a' .. 'z') then
                  return False;
               end if;
            elsif not (T (I) in 'A' .. 'Z'
                       or else T (I) in 'a' .. 'z'
                       or else T (I) in '0' .. '9'
                       or else T (I) = '_')
            then
               return False;
            end if;
         end loop;

         return True;
      end Is_Static_Identifier_Name;
   begin
      if Name = "" or else T'Length < 2
        or else T (T'First) /= '(' or else T (T'Last) /= ')'
      then
         return;
      end if;

      Start := T'First + 1;
      Item_Start := Start;
      while Item_Start <= T'Last - 1 loop
         Item_Stop := Item_Start;
         while Item_Stop <= T'Last - 1
           and then T (Item_Stop) /= ','
         loop
            Item_Stop := Item_Stop + 1;
         end loop;

         declare
            Literal : constant String := Trim (T (Item_Start .. Item_Stop - 1));
         begin
            if not Is_Static_Identifier_Name (Literal) then
               return;
            end if;

            Register_Static_Enumeration_Literal (Phase, Name, Literal, Position);
         end;

         Position := Position + 1;
         Item_Start := Item_Stop + 1;
      end loop;

      if Position > 0 then
         Store_Static_Type_Range (Phase, Name, 0, Integer (Position - 1));
      end if;
   exception
      when Constraint_Error =>
         null;
   end Register_Static_Enumeration_Type;

   procedure Register_Static_Discrete_Literals_From_Base
     (Phase     : in out Context;
      Name      : String;
      Base_Name : String)
   is
      N : constant String := Editor.Ada_Language_Model.Normalize_Name (Name);
      B : constant String := Editor.Ada_Language_Model.Normalize_Name (Base_Name);
   begin
      if N = "" or else B = "" then
         return;
      end if;

      if B = "boolean" or else B = "standard.boolean" then
         Register_Static_Enumeration_Literal (Phase, Name, "False", 0);
         Register_Static_Enumeration_Literal (Phase, Name, "True", 1);
      elsif Static_Type_Is_Character (Phase, Base_Name) then
         Register_Static_Character_Type (Phase, Name);
      else
         for I in 1 .. Phase.Static.Enumeration_Literal_Count loop
            if To_String
                 (Phase.Static.Enumeration_Literals (I).Normalized_Type_Name) = B
            then
               Register_Static_Enumeration_Literal
                 (Phase,
                  Name,
                  To_String
                    (Phase.Static.Enumeration_Literals (I).Normalized_Literal_Name),
                  Phase.Static.Enumeration_Literals (I).Position);
            end if;
         end loop;
      end if;
   exception
      when Constraint_Error =>
         null;
   end Register_Static_Discrete_Literals_From_Base;

   function Static_Enumeration_Literal_Position
     (Phase        : Context;
      Type_Name    : String;
      Literal_Name : String;
      Position     : out Natural) return Boolean
   is
      T : constant String := Editor.Ada_Language_Model.Normalize_Name (Type_Name);
      L : constant String := Editor.Ada_Language_Model.Normalize_Name (Literal_Name);
   begin
      Position := 0;
      if T = "" or else L = "" then
         return False;
      end if;

      for I in 1 .. Phase.Static.Enumeration_Literal_Count loop
         if To_String
              (Phase.Static.Enumeration_Literals (I).Normalized_Type_Name) = T
           and then To_String
              (Phase.Static.Enumeration_Literals (I).Normalized_Literal_Name) = L
         then
            Position := Phase.Static.Enumeration_Literals (I).Position;
            return True;
         end if;
      end loop;

      return False;
   end Static_Enumeration_Literal_Position;

   function Static_Enumeration_Position_Image
     (Phase      : Context;
      Type_Name  : String;
      Position   : Natural;
      Image_Text : out Unbounded_String) return Boolean
   is
      T : constant String := Editor.Ada_Language_Model.Normalize_Name (Type_Name);
   begin
      Image_Text := Null_Unbounded_String;

      if T = "" then
         return False;
      end if;

      for I in 1 .. Phase.Static.Enumeration_Literal_Count loop
         if To_String
              (Phase.Static.Enumeration_Literals (I).Normalized_Type_Name) = T
           and then Phase.Static.Enumeration_Literals (I).Position = Position
         then
            Image_Text :=
              Phase.Static.Enumeration_Literals (I).Normalized_Literal_Name;
            return True;
         end if;
      end loop;

      return False;
   exception
      when Constraint_Error =>
         Image_Text := Null_Unbounded_String;
         return False;
   end Static_Enumeration_Position_Image;

   function Static_Discrete_Constant_Position
     (Phase     : Context;
      Type_Name : String;
      Name      : String;
      Position  : out Natural) return Boolean
   is
      T : constant String := Canonical_Static_Type_Name (Type_Name);
      N : constant String := Editor.Ada_Language_Model.Normalize_Name (Name);
   begin
      Position := 0;
      if T = "" or else N = "" then
         return False;
      end if;

      for I in 1 .. Phase.Static.Discrete_Constant_Count loop
         if To_String
              (Phase.Static.Discrete_Constants (I).Normalized_Name) = N
           and then To_String
              (Phase.Static.Discrete_Constants (I).Normalized_Type_Name) = T
         then
            Position := Phase.Static.Discrete_Constants (I).Position;
            return True;
         end if;
      end loop;

      for I in 1 .. Phase.Static.Discrete_Constant_Count loop
         if To_String
              (Phase.Static.Discrete_Constants (I).Normalized_Name) = N
           and then Static_Subtype_Root (Phase, Type_Name) =
             Static_Subtype_Root
               (Phase,
                To_String
                  (Phase.Static.Discrete_Constants (I).Normalized_Type_Name))
           and then Static_Value_In_Type_Range
             (Phase, Type_Name, Phase.Static.Discrete_Constants (I).Position)
         then
            Position := Phase.Static.Discrete_Constants (I).Position;
            return True;
         end if;
      end loop;

      return False;
   exception
      when Constraint_Error =>
         return False;
   end Static_Discrete_Constant_Position;

   function Static_Character_Constant_Position
     (Phase    : Context;
      Name     : String;
      Position : out Natural) return Boolean
   is
      N : constant String := Editor.Ada_Language_Model.Normalize_Name (Name);
   begin
      Position := 0;
      if N = "" then
         return False;
      end if;

      for I in 1 .. Phase.Static.Discrete_Constant_Count loop
         if To_String
              (Phase.Static.Discrete_Constants (I).Normalized_Name) = N
           and then Static_Type_Is_Character
             (Phase,
              To_String
                (Phase.Static.Discrete_Constants (I).Normalized_Type_Name))
           and then Phase.Static.Discrete_Constants (I).Position
             <= Character'Pos (Character'Last)
         then
            Position := Phase.Static.Discrete_Constants (I).Position;
            return True;
         end if;
      end loop;

      return False;
   exception
      when Constraint_Error =>
         return False;
   end Static_Character_Constant_Position;

   procedure Register_Static_Discrete_Constant
     (Phase                            : in out Context;
      Name                             : String;
      Type_Name                        : String;
      Default_Text                     : String;
      Static_Discrete_Default_Position : not null Static_Discrete_Position_Query)
   is
      N : constant String := Editor.Ada_Language_Model.Normalize_Name (Name);
      T : constant String := Canonical_Static_Type_Name (Type_Name);
      Position : Natural := 0;
   begin
      if N = "" or else T = "" then
         return;
      end if;

      if not Static_Discrete_Default_Position
               (Type_Name, Default_Text, Position)
      then
         return;
      end if;

      if not Static_Value_In_Type_Range (Phase, Type_Name, Position) then
         return;
      end if;

      for I in 1 .. Phase.Static.Discrete_Constant_Count loop
         if To_String
              (Phase.Static.Discrete_Constants (I).Normalized_Name) = N
           and then To_String
              (Phase.Static.Discrete_Constants (I).Normalized_Type_Name) = T
         then
            Phase.Static.Discrete_Constants (I).Position := Position;
            return;
         end if;
      end loop;

      if Phase.Static.Discrete_Constant_Count >=
        Phase_Types.Max_Static_Discrete_Constants
      then
         return;
      end if;

      Phase.Static.Discrete_Constant_Count :=
        Phase.Static.Discrete_Constant_Count + 1;
      Phase.Static.Discrete_Constants (Phase.Static.Discrete_Constant_Count) :=
        (Normalized_Name      => To_Unbounded_String (N),
         Normalized_Type_Name => To_Unbounded_String (T),
         Position             => Position);
   exception
      when Constraint_Error =>
         null;
   end Register_Static_Discrete_Constant;

   procedure Store_Static_String_Subtype_Bounds_Values
     (Phase      : in out Context;
      Name       : String;
      First      : Integer;
      Last       : Integer)
   is
      N : constant String := Canonical_Static_Type_Name (Name);
   begin
      if N = "" then
         return;
      end if;

      for I in 1 .. Phase.Static.String_Subtype_Bound_Count loop
         if To_String
              (Phase.Static.String_Subtype_Bounds (I).Normalized_Name) = N
         then
            Phase.Static.String_Subtype_Bounds (I) :=
              (Normalized_Name => To_Unbounded_String (N),
               Has_First       => True,
               First           => First,
               Has_Last        => True,
               Last            => Last);
            return;
         end if;
      end loop;

      if Phase.Static.String_Subtype_Bound_Count >=
        Phase_Types.Max_Static_String_Subtype_Bounds
      then
         return;
      end if;

      Phase.Static.String_Subtype_Bound_Count :=
        Phase.Static.String_Subtype_Bound_Count + 1;
      Phase.Static.String_Subtype_Bounds
        (Phase.Static.String_Subtype_Bound_Count) :=
        (Normalized_Name => To_Unbounded_String (N),
         Has_First       => True,
         First           => First,
         Has_Last        => True,
         Last            => Last);
   end Store_Static_String_Subtype_Bounds_Values;

   procedure Copy_Static_String_Subtype_Bounds_From_Base
     (Phase     : in out Context;
      Name      : String;
      Base_Name : String)
   is
      B : constant String := Canonical_Static_Type_Name (Base_Name);
   begin
      if B = "" then
         return;
      end if;

      for I in 1 .. Phase.Static.String_Subtype_Bound_Count loop
         if To_String
              (Phase.Static.String_Subtype_Bounds (I).Normalized_Name) = B
           and then Phase.Static.String_Subtype_Bounds (I).Has_First
           and then Phase.Static.String_Subtype_Bounds (I).Has_Last
         then
            Store_Static_String_Subtype_Bounds_Values
              (Phase,
               Name,
               Phase.Static.String_Subtype_Bounds (I).First,
               Phase.Static.String_Subtype_Bounds (I).Last);
            return;
         end if;
      end loop;
   exception
      when Constraint_Error =>
         null;
   end Copy_Static_String_Subtype_Bounds_From_Base;

   function Static_String_Subtype_Length_Compatible
     (Phase      : Context;
      Type_Name  : String;
      Image_Text : Unbounded_String) return Boolean
   is
      N : constant String := Canonical_Static_Type_Name (Type_Name);
      Expected_Length : Natural := 0;
      Actual_Length   : constant Natural := To_String (Image_Text)'Length;
   begin
      if N = "" then
         return True;
      end if;

      for I in 1 .. Phase.Static.String_Subtype_Bound_Count loop
         if To_String
              (Phase.Static.String_Subtype_Bounds (I).Normalized_Name) = N
           and then Phase.Static.String_Subtype_Bounds (I).Has_First
           and then Phase.Static.String_Subtype_Bounds (I).Has_Last
         then
            if Phase.Static.String_Subtype_Bounds (I).Last
                 < Phase.Static.String_Subtype_Bounds (I).First
            then
               Expected_Length := 0;
            else
               Expected_Length :=
                 Natural
                   (Phase.Static.String_Subtype_Bounds (I).Last
                    - Phase.Static.String_Subtype_Bounds (I).First + 1);
            end if;

            return Actual_Length = Expected_Length;
         end if;
      end loop;

      return True;
   exception
      when Constraint_Error =>
         return False;
   end Static_String_Subtype_Length_Compatible;

   function Static_String_Subtype_Bound_Value
     (Phase     : Context;
      Type_Name : String;
      Attr_Name : String;
      Bound     : out Natural) return Boolean
   is
      N : constant String := Canonical_Static_Type_Name (Type_Name);
      A : constant String :=
        Lower (Editor.Ada_Language_Model.Normalize_Name (Attr_Name));
      Length_Value : Natural := 0;
   begin
      Bound := 0;

      if N = "" then
         return False;
      end if;

      for I in 1 .. Phase.Static.String_Subtype_Bound_Count loop
         if To_String
              (Phase.Static.String_Subtype_Bounds (I).Normalized_Name) = N
           and then Phase.Static.String_Subtype_Bounds (I).Has_First
           and then Phase.Static.String_Subtype_Bounds (I).Has_Last
         then
            if Phase.Static.String_Subtype_Bounds (I).Last
                 < Phase.Static.String_Subtype_Bounds (I).First
            then
               Length_Value := 0;
            else
               Length_Value :=
                 Natural
                   (Phase.Static.String_Subtype_Bounds (I).Last
                    - Phase.Static.String_Subtype_Bounds (I).First + 1);
            end if;

            if A = "first" then
               if Phase.Static.String_Subtype_Bounds (I).First < 0 then
                  return False;
               end if;
               Bound := Natural (Phase.Static.String_Subtype_Bounds (I).First);
               return True;
            elsif A = "last" then
               if Phase.Static.String_Subtype_Bounds (I).Last < 0 then
                  return False;
               end if;
               Bound := Natural (Phase.Static.String_Subtype_Bounds (I).Last);
               return True;
            elsif A = "length" then
               Bound := Length_Value;
               return True;
            else
               return False;
            end if;
         end if;
      end loop;

      return False;
   exception
      when Constraint_Error =>
         return False;
   end Static_String_Subtype_Bound_Value;

   function Static_String_Subtype_Bounds
     (Phase     : Context;
      Type_Name : String;
      First     : out Integer;
      Last      : out Integer) return Boolean
   is
      N : constant String := Canonical_Static_Type_Name (Type_Name);
   begin
      First := 1;
      Last := 0;

      if N = "" then
         return False;
      end if;

      for I in 1 .. Phase.Static.String_Subtype_Bound_Count loop
         if To_String
              (Phase.Static.String_Subtype_Bounds (I).Normalized_Name) = N
           and then Phase.Static.String_Subtype_Bounds (I).Has_First
           and then Phase.Static.String_Subtype_Bounds (I).Has_Last
         then
            First := Phase.Static.String_Subtype_Bounds (I).First;
            Last := Phase.Static.String_Subtype_Bounds (I).Last;
            return True;
         end if;
      end loop;

      return False;
   exception
      when Constraint_Error =>
         return False;
   end Static_String_Subtype_Bounds;

   function Static_String_Constant_Value
     (Phase      : Context;
      Name       : String;
      Image_Text : out Unbounded_String) return Boolean
   is
      N : constant String := Editor.Ada_Language_Model.Normalize_Name (Name);
   begin
      Image_Text := Null_Unbounded_String;
      if N = "" then
         return False;
      end if;

      for I in 1 .. Phase.Static.String_Constant_Count loop
         if To_String (Phase.Static.String_Constants (I).Normalized_Name) = N then
            Image_Text := Phase.Static.String_Constants (I).Image_Text;
            return True;
         end if;
      end loop;

      return False;
   end Static_String_Constant_Value;

   function Static_String_Constant_Bound_Value
     (Phase     : Context;
      Name      : String;
      Attr_Name : String;
      Bound     : out Natural) return Boolean
   is
      N : constant String := Editor.Ada_Language_Model.Normalize_Name (Name);
      A : constant String :=
        Lower (Editor.Ada_Language_Model.Normalize_Name (Attr_Name));
      Length_Value : Natural := 0;
   begin
      Bound := 0;

      if N = "" then
         return False;
      end if;

      for I in 1 .. Phase.Static.String_Constant_Count loop
         if To_String (Phase.Static.String_Constants (I).Normalized_Name) = N
           and then Phase.Static.String_Constants (I).Has_First
           and then Phase.Static.String_Constants (I).Has_Last
         then
            if Phase.Static.String_Constants (I).Last
                 < Phase.Static.String_Constants (I).First
            then
               Length_Value := 0;
            else
               Length_Value :=
                 Phase.Static.String_Constants (I).Last
                 - Phase.Static.String_Constants (I).First + 1;
            end if;

            if A = "first" then
               Bound := Phase.Static.String_Constants (I).First;
               return True;
            elsif A = "last" then
               Bound := Phase.Static.String_Constants (I).Last;
               return True;
            elsif A = "length" then
               Bound := Length_Value;
               return True;
            else
               return False;
            end if;
         end if;
      end loop;

      return False;
   exception
      when Constraint_Error =>
         return False;
   end Static_String_Constant_Bound_Value;

   function Static_String_Constant_Range
     (Phase : Context;
      Name  : String;
      First : out Natural;
      Last  : out Natural) return Boolean
   is
      N : constant String := Editor.Ada_Language_Model.Normalize_Name (Name);
   begin
      First := 1;
      Last := 0;

      if N = "" then
         return False;
      end if;

      for I in 1 .. Phase.Static.String_Constant_Count loop
         if To_String (Phase.Static.String_Constants (I).Normalized_Name) = N then
            if Phase.Static.String_Constants (I).Has_First
              and then Phase.Static.String_Constants (I).Has_Last
            then
               First := Phase.Static.String_Constants (I).First;
               Last := Phase.Static.String_Constants (I).Last;
            else
               First := 1;
               Last :=
                 To_String (Phase.Static.String_Constants (I).Image_Text)'Length;
            end if;
            return True;
         end if;
      end loop;

      return False;
   exception
      when Constraint_Error =>
         return False;
   end Static_String_Constant_Range;

   procedure Store_Static_String_Constant
     (Phase      : in out Context;
      Name       : String;
      Image_Text : Unbounded_String;
      Has_First  : Boolean;
      First      : Natural;
      Has_Last   : Boolean;
      Last       : Natural)
   is
      N : constant String := Editor.Ada_Language_Model.Normalize_Name (Name);
   begin
      if N = "" then
         return;
      end if;

      for I in 1 .. Phase.Static.String_Constant_Count loop
         if To_String (Phase.Static.String_Constants (I).Normalized_Name) = N then
            Phase.Static.String_Constants (I).Image_Text := Image_Text;
            Phase.Static.String_Constants (I).Has_First := Has_First;
            Phase.Static.String_Constants (I).First := First;
            Phase.Static.String_Constants (I).Has_Last := Has_Last;
            Phase.Static.String_Constants (I).Last := Last;
            return;
         end if;
      end loop;

      if Phase.Static.String_Constant_Count >=
        Phase_Types.Max_Static_String_Constants
      then
         return;
      end if;

      Phase.Static.String_Constant_Count :=
        Phase.Static.String_Constant_Count + 1;
      Phase.Static.String_Constants (Phase.Static.String_Constant_Count) :=
        (Normalized_Name => To_Unbounded_String (N),
         Image_Text      => Image_Text,
         Has_First       => Has_First,
         First           => First,
         Has_Last        => Has_Last,
         Last            => Last);
   end Store_Static_String_Constant;

   function Static_Type_Width
     (Phase : Context;
      Name  : String;
      Value : out Natural) return Boolean
   is
      N : constant String := Editor.Ada_Language_Model.Normalize_Name (Name);
      Max_Length : Natural := 0;
      Seen       : Boolean := False;
   begin
      Value := 0;
      if N = "" then
         return False;
      elsif N = "boolean" or else N = "standard.boolean" then
         Value := 5;
         return True;
      elsif Static_Type_Is_Character (Phase, Name) then
         Value := 3;
         return True;
      end if;

      for I in 1 .. Phase.Static.Enumeration_Literal_Count loop
         if To_String
              (Phase.Static.Enumeration_Literals (I).Normalized_Type_Name) = N
         then
            declare
               Literal_Length : constant Natural :=
                 Length
                   (Phase.Static.Enumeration_Literals (I).Normalized_Literal_Name);
            begin
               if Literal_Length > Max_Length then
                  Max_Length := Literal_Length;
               end if;
               Seen := True;
            end;
         end if;
      end loop;

      if Seen then
         Value := Max_Length;
         return True;
      else
         return False;
      end if;
   exception
      when Constraint_Error =>
         return False;
   end Static_Type_Width;

   function Static_Attribute_Value
     (Phase     : Context;
      Name      : String;
      Attribute : String;
      Value     : out Natural) return Boolean
   is
      N : constant String := Editor.Ada_Language_Model.Normalize_Name (Name);
      A : constant String :=
        Lower (Editor.Ada_Language_Model.Normalize_Name (Attribute));
   begin
      return Editor.Ada_Declaration_Parser.Static_Attribute_Registry.Value
        (Phase.Static.Attributes, N, A, Value);
   end Static_Attribute_Value;

   procedure Register_Static_Attribute_Value
     (Phase     : in out Context;
      Name      : String;
      Attribute : String;
      Value     : Natural)
   is
      N : constant String := Editor.Ada_Language_Model.Normalize_Name (Name);
      A : constant String :=
        Lower (Editor.Ada_Language_Model.Normalize_Name (Attribute));
   begin
      Editor.Ada_Declaration_Parser.Static_Attribute_Registry.Register
        (Phase.Static.Attributes, N, A, Value);
   end Register_Static_Attribute_Value;

   procedure Register_Static_Representation_Attribute_Value
     (Phase     : in out Context;
      Name      : String;
      Attribute : String;
      Value     : Natural)
   is
      A : constant String :=
        Lower (Editor.Ada_Language_Model.Normalize_Name (Attribute));
   begin
      if A = "size"
        or else A = "object_size"
        or else A = "value_size"
        or else A = "alignment"
        or else A = "storage_size"
      then
         Register_Static_Attribute_Value (Phase, Name, A, Value);
      end if;
   end Register_Static_Representation_Attribute_Value;

   function Static_Metadata_Is_Applied (Phase : Context) return Boolean is
   begin
      return Phase.Static_Metadata_Applied;
   end Static_Metadata_Is_Applied;

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Derivation;
