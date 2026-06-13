with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;

package body Editor.Ada_Static_Expressions is

   use type Editor.Ada_Declarative_Regions.Region_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Static_Binding_Id;
   use type Static_Enumeration_Literal_Id;
   use type Static_Fixed_Type_Id;
   use type Static_Modular_Type_Id;

   function To_Unbounded_String (Value : String)
      return Ada.Strings.Unbounded.Unbounded_String
      renames Ada.Strings.Unbounded.To_Unbounded_String;
   function To_String (Value : Ada.Strings.Unbounded.Unbounded_String) return String
      renames Ada.Strings.Unbounded.To_String;

   function Trim (Text : String) return String is
     (Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both));

   function Normalize_Name (Text : String) return String is
      T : constant String := Trim (Text);
      R : String (T'Range) := T;
   begin
      for I in R'Range loop
         R (I) := Ada.Characters.Handling.To_Lower (R (I));
      end loop;
      return R;
   end Normalize_Name;


   function Is_Letter (C : Character) return Boolean is
   begin
      return (C in 'a' .. 'z') or else (C in 'A' .. 'Z');
   end Is_Letter;

   function Is_Digit (C : Character) return Boolean is
   begin
      return C in '0' .. '9';
   end Is_Digit;

   function Is_Identifier_Char (C : Character) return Boolean is
   begin
      return Is_Letter (C) or else Is_Digit (C) or else C = '_';
   end Is_Identifier_Char;

   function Contains (Text : String; Pattern : String) return Boolean is
   begin
      return Pattern /= "" and then Ada.Strings.Fixed.Index (Text, Pattern) /= 0;
   end Contains;

   function Segment_After (Text : String; Pattern : String) return String is
      Pos : constant Natural := Ada.Strings.Fixed.Index (Text, Pattern);
   begin
      if Pos = 0 then
         return "";
      end if;
      return Trim (Text (Pos + Pattern'Length .. Text'Last));
   end Segment_After;

   function Segment_Before (Text : String; Pattern : String) return String is
      Pos : constant Natural := Ada.Strings.Fixed.Index (Text, Pattern);
   begin
      if Pos = 0 then
         return Trim (Text);
      elsif Pos = Text'First then
         return "";
      else
         return Trim (Text (Text'First .. Pos - 1));
      end if;
   end Segment_Before;

   function Lookup_Type_Bound
     (Model  : Static_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name   : String) return Static_Type_Bound_Id
   is
      Current    : Editor.Ada_Declarative_Regions.Region_Id := Region;
      Normalized : constant String := Normalize_Name (Name);
   begin
      while Current /= Editor.Ada_Declarative_Regions.No_Region loop
         for Index in 1 .. Natural (Model.Type_Bounds.Length) loop
            declare
               Item : constant Static_Type_Bound_Info := Model.Type_Bounds.Element (Positive (Index));
            begin
               if Item.Region = Current and then To_String (Item.Normalized_Name) = Normalized then
                  return Item.Id;
               end if;
            end;
         end loop;
         Current := Editor.Ada_Declarative_Regions.Region (Model.Regions, Current).Parent;
      end loop;

      for Index in 1 .. Natural (Model.Type_Bounds.Length) loop
         declare
            Item : constant Static_Type_Bound_Info := Model.Type_Bounds.Element (Positive (Index));
         begin
            if To_String (Item.Normalized_Name) = Normalized then
               return Item.Id;
            end if;
         end;
      end loop;
      return No_Static_Type_Bound;
   end Lookup_Type_Bound;

   function Static_Type_Bound
     (Model : Static_Model;
      Id    : Static_Type_Bound_Id) return Static_Type_Bound_Info is
   begin
      if Id = No_Static_Type_Bound or else Natural (Id) > Natural (Model.Type_Bounds.Length) then
         return (others => <>);
      end if;
      return Model.Type_Bounds.Element (Positive (Id));
   end Static_Type_Bound;

   function Hash_Text (Text : String) return Natural is
      Result : Natural := 0;
   begin
      for C of Text loop
         Result := (Result * 131 + Character'Pos (Ada.Characters.Handling.To_Lower (C)) + 1)
           mod Natural'Last;
      end loop;
      return Result;
   end Hash_Text;

   function Hash_Value (Value : Static_Value_Info) return Natural is
   begin
      return (Static_Value_Status'Pos (Value.Status) * 1000003
              + Natural (abs (Value.Integer_Value) mod 1_000_003) * 97
              + Natural (abs (Long_Long_Integer (Value.Real_Value * 1000.0)) mod 1_000_003) * 89
              + Hash_Text (To_String (Value.Normalized_Text)) * 17
              + Hash_Text (To_String (Value.Referenced_Name)) * 31
              + Hash_Text (To_String (Value.Attribute_Prefix)) * 43
              + Hash_Text (To_String (Value.Attribute_Name)) * 59
              + Hash_Text (To_String (Value.Literal_Name)) * 67
              + Natural (abs (Value.Literal_Position) mod 1_000_003) * 71
              + Hash_Text (To_String (Value.Modular_Type_Name)) * 79
              + Natural (abs (Value.Modulus_Value) mod 1_000_003) * 83
              + Hash_Text (To_String (Value.Fixed_Type_Name)) * 97
              + Natural (abs (Long_Long_Integer (Value.Delta_Value * 1_000_000.0)) mod 1_000_003) * 109) mod Natural'Last;
   end Hash_Value;

   function Make_Value
     (Status          : Static_Value_Status;
      Expression_Text : String;
      Integer_Value   : Long_Long_Integer := 0;
      Referenced_Name : String := "";
      Attribute_Prefix : String := "";
      Attribute_Name   : String := "";
      Literal_Name     : String := "";
      Literal_Position : Long_Long_Integer := 0;
      Modular_Type_Name : String := "";
      Modulus_Value    : Long_Long_Integer := 0;
      Real_Value       : Long_Float := 0.0;
      Fixed_Type_Name  : String := "";
      Delta_Value      : Long_Float := 0.0) return Static_Value_Info
   is
      Info : Static_Value_Info;
   begin
      Info.Status := Status;
      Info.Integer_Value := Integer_Value;
      Info.Real_Value := Real_Value;
      Info.Expression_Text := To_Unbounded_String (Expression_Text);
      Info.Normalized_Text := To_Unbounded_String (Normalize_Name (Expression_Text));
      Info.Referenced_Name := To_Unbounded_String (Referenced_Name);
      Info.Attribute_Prefix := To_Unbounded_String (Attribute_Prefix);
      Info.Attribute_Name := To_Unbounded_String (Attribute_Name);
      Info.Literal_Name := To_Unbounded_String (Literal_Name);
      Info.Literal_Position := Literal_Position;
      Info.Modular_Type_Name := To_Unbounded_String (Modular_Type_Name);
      Info.Modulus_Value := Modulus_Value;
      Info.Fixed_Type_Name := To_Unbounded_String (Fixed_Type_Name);
      Info.Delta_Value := Delta_Value;
      Info.Fingerprint := Hash_Value (Info);
      return Info;
   end Make_Value;

   procedure Clear (Model : in out Static_Model) is
   begin
      Model.Bindings.Clear;
      Model.Type_Bounds.Clear;
      Model.Fixed_Types.Clear;
      Model.Modular_Types.Clear;
      Model.Enumeration_Literals.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Has_Static_Bindings (Model : Static_Model) return Boolean is
   begin
      return not Model.Bindings.Is_Empty;
   end Has_Static_Bindings;

   function Static_Binding_Count (Model : Static_Model) return Natural is
   begin
      return Natural (Model.Bindings.Length);
   end Static_Binding_Count;

   function Static_Binding_At (Model : Static_Model; Index : Positive) return Static_Binding_Info is
   begin
      if Index > Natural (Model.Bindings.Length) then
         return (others => <>);
      end if;
      return Model.Bindings.Element (Index);
   end Static_Binding_At;

   function Static_Type_Bound_Count (Model : Static_Model) return Natural is
   begin
      return Natural (Model.Type_Bounds.Length);
   end Static_Type_Bound_Count;

   function Static_Type_Bound_At
     (Model : Static_Model; Index : Positive) return Static_Type_Bound_Info is
   begin
      if Index > Natural (Model.Type_Bounds.Length) then
         return (others => <>);
      end if;
      return Model.Type_Bounds.Element (Index);
   end Static_Type_Bound_At;


   function Static_Fixed_Type_Count (Model : Static_Model) return Natural is
   begin
      return Natural (Model.Fixed_Types.Length);
   end Static_Fixed_Type_Count;

   function Static_Fixed_Type_At
     (Model : Static_Model; Index : Positive) return Static_Fixed_Type_Info is
   begin
      if Index > Natural (Model.Fixed_Types.Length) then
         return (others => <>);
      end if;
      return Model.Fixed_Types.Element (Index);
   end Static_Fixed_Type_At;

   function Lookup_Fixed_Type
     (Model  : Static_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name   : String) return Static_Fixed_Type_Id
   is
      Current    : Editor.Ada_Declarative_Regions.Region_Id := Region;
      Normalized : constant String := Normalize_Name (Name);
   begin
      while Current /= Editor.Ada_Declarative_Regions.No_Region loop
         for Index in 1 .. Natural (Model.Fixed_Types.Length) loop
            declare
               Item : constant Static_Fixed_Type_Info :=
                 Model.Fixed_Types.Element (Positive (Index));
            begin
               if Item.Region = Current
                 and then To_String (Item.Normalized_Name) = Normalized
               then
                  return Item.Id;
               end if;
            end;
         end loop;
         Current := Editor.Ada_Declarative_Regions.Region (Model.Regions, Current).Parent;
      end loop;

      for Index in 1 .. Natural (Model.Fixed_Types.Length) loop
         declare
            Item : constant Static_Fixed_Type_Info :=
              Model.Fixed_Types.Element (Positive (Index));
         begin
            if To_String (Item.Normalized_Name) = Normalized then
               return Item.Id;
            end if;
         end;
      end loop;
      return No_Static_Fixed_Type;
   end Lookup_Fixed_Type;

   function Static_Fixed_Type
     (Model : Static_Model;
      Id    : Static_Fixed_Type_Id) return Static_Fixed_Type_Info is
   begin
      if Id = No_Static_Fixed_Type or else Natural (Id) > Natural (Model.Fixed_Types.Length) then
         return (others => <>);
      end if;
      return Model.Fixed_Types.Element (Positive (Id));
   end Static_Fixed_Type;

   function Quantize_Fixed_Value
     (Model      : Static_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Type_Name  : String;
      Expression : String) return Static_Value_Info
   is
      Type_Id : constant Static_Fixed_Type_Id := Lookup_Fixed_Type (Model, Region, Type_Name);
      Raw     : constant Static_Value_Info := Evaluate_Numeric_Expression (Model, Region, Expression);
   begin
      if Type_Id = No_Static_Fixed_Type then
         return Make_Value (Static_Value_Unresolved_Name, Expression, 0, Type_Name);
      end if;
      declare
         Type_Info : constant Static_Fixed_Type_Info := Static_Fixed_Type (Model, Type_Id);
         Delta_Value     : constant Static_Value_Info := Type_Info.Delta_Value;
         First     : constant Static_Value_Info := Type_Info.First_Value;
         Last      : constant Static_Value_Info := Type_Info.Last_Value;
         Raw_Real  : Long_Float := 0.0;
      begin
         if Raw.Status = Static_Value_Integer then
            Raw_Real := Long_Float (Raw.Integer_Value);
         elsif Raw.Status = Static_Value_Real then
            Raw_Real := Raw.Real_Value;
         else
            return Raw;
         end if;

         if Delta_Value.Status /= Static_Value_Real and then Delta_Value.Status /= Static_Value_Integer then
            return Make_Value
              (Static_Value_Malformed, Expression, 0, "", "", "", "", 0, "", 0,
               Fixed_Type_Name => To_String (Type_Info.Name));
         end if;

         declare
            Delta_Real : constant Long_Float :=
              (if Delta_Value.Status = Static_Value_Real then Delta_Value.Real_Value
               else Long_Float (Delta_Value.Integer_Value));
            Ratio      : Long_Float;
            Rounded    : Long_Long_Integer;
            Quantized  : Long_Float;
            Epsilon    : constant Long_Float := 0.000_001;
         begin
            if Delta_Real <= 0.0 then
               return Make_Value
                 (Static_Value_Malformed, Expression, 0, "", "", "", "", 0, "", 0,
                  Fixed_Type_Name => To_String (Type_Info.Name));
            end if;

            Ratio := Raw_Real / Delta_Real;
            Rounded := Long_Long_Integer (Ratio);
            if abs (Long_Float (Rounded) - Ratio) > Epsilon then
               return Make_Value
                 (Static_Value_Fixed_Delta_Mismatch, Expression, 0, "", "", "", "", 0, "", 0,
                  Real_Value => Raw_Real, Fixed_Type_Name => To_String (Type_Info.Name),
                  Delta_Value => Delta_Real);
            end if;
            Quantized := Long_Float (Rounded) * Delta_Real;

            if (First.Status = Static_Value_Real or else First.Status = Static_Value_Integer)
              and then (Last.Status = Static_Value_Real or else Last.Status = Static_Value_Integer)
            then
               declare
                  First_Real : constant Long_Float :=
                    (if First.Status = Static_Value_Real then First.Real_Value
                     else Long_Float (First.Integer_Value));
                  Last_Real : constant Long_Float :=
                    (if Last.Status = Static_Value_Real then Last.Real_Value
                     else Long_Float (Last.Integer_Value));
               begin
                  if Quantized < First_Real - Epsilon or else Quantized > Last_Real + Epsilon then
                     return Make_Value
                       (Static_Value_Fixed_Range_Error, Expression, 0, "", "", "", "", 0, "", 0,
                        Real_Value => Quantized, Fixed_Type_Name => To_String (Type_Info.Name),
                        Delta_Value => Delta_Real);
                  end if;
               end;
            end if;

            return Make_Value
              (Static_Value_Fixed_Point, Expression, 0, "", "", "", "", 0, "", 0,
               Real_Value => Quantized, Fixed_Type_Name => To_String (Type_Info.Name),
               Delta_Value => Delta_Real);
         end;
      end;
   end Quantize_Fixed_Value;

   function Static_Modular_Type_Count (Model : Static_Model) return Natural is
   begin
      return Natural (Model.Modular_Types.Length);
   end Static_Modular_Type_Count;

   function Static_Modular_Type_At
     (Model : Static_Model; Index : Positive) return Static_Modular_Type_Info is
   begin
      if Index > Natural (Model.Modular_Types.Length) then
         return (others => <>);
      end if;
      return Model.Modular_Types.Element (Index);
   end Static_Modular_Type_At;

   function Lookup_Modular_Type
     (Model  : Static_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name   : String) return Static_Modular_Type_Id
   is
      Current    : Editor.Ada_Declarative_Regions.Region_Id := Region;
      Normalized : constant String := Normalize_Name (Name);
   begin
      while Current /= Editor.Ada_Declarative_Regions.No_Region loop
         for Index in 1 .. Natural (Model.Modular_Types.Length) loop
            declare
               Item : constant Static_Modular_Type_Info :=
                 Model.Modular_Types.Element (Positive (Index));
            begin
               if Item.Region = Current
                 and then To_String (Item.Normalized_Name) = Normalized
               then
                  return Item.Id;
               end if;
            end;
         end loop;
         Current := Editor.Ada_Declarative_Regions.Region (Model.Regions, Current).Parent;
      end loop;

      for Index in 1 .. Natural (Model.Modular_Types.Length) loop
         declare
            Item : constant Static_Modular_Type_Info :=
              Model.Modular_Types.Element (Positive (Index));
         begin
            if To_String (Item.Normalized_Name) = Normalized then
               return Item.Id;
            end if;
         end;
      end loop;
      return No_Static_Modular_Type;
   end Lookup_Modular_Type;

   function Static_Modular_Type
     (Model : Static_Model;
      Id    : Static_Modular_Type_Id) return Static_Modular_Type_Info is
   begin
      if Id = No_Static_Modular_Type or else Natural (Id) > Natural (Model.Modular_Types.Length) then
         return (others => <>);
      end if;
      return Model.Modular_Types.Element (Positive (Id));
   end Static_Modular_Type;

   function Reduce_Modular_Integer
     (Model      : Static_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Type_Name  : String;
      Expression : String) return Static_Value_Info
   is
      Type_Id : constant Static_Modular_Type_Id := Lookup_Modular_Type (Model, Region, Type_Name);
      Raw     : constant Static_Value_Info := Evaluate_Integer_Expression (Model, Region, Expression);
   begin
      if Type_Id = No_Static_Modular_Type then
         return Make_Value (Static_Value_Unresolved_Name, Expression, 0, Type_Name);
      end if;
      declare
         Type_Info : constant Static_Modular_Type_Info := Static_Modular_Type (Model, Type_Id);
         Modulus   : constant Static_Value_Info := Type_Info.Modulus_Value;
      begin
         if Modulus.Status /= Static_Value_Integer or else Modulus.Integer_Value <= 0 then
            return Make_Value
              (Static_Value_Malformed, Expression, 0, "", "", "", "", 0,
               To_String (Type_Info.Name), 0);
         elsif Raw.Status /= Static_Value_Integer then
            return Raw;
         else
            declare
               Reduced : Long_Long_Integer := Raw.Integer_Value mod Modulus.Integer_Value;
            begin
               return Make_Value
                 (Static_Value_Modular_Integer, Expression, Reduced, "", "", "", "", 0,
                  To_String (Type_Info.Name), Modulus.Integer_Value);
            end;
         end if;
      end;
   end Reduce_Modular_Integer;

   function Static_Enumeration_Literal_Count (Model : Static_Model) return Natural is
   begin
      return Natural (Model.Enumeration_Literals.Length);
   end Static_Enumeration_Literal_Count;

   function Static_Enumeration_Literal_At
     (Model : Static_Model; Index : Positive) return Static_Enumeration_Literal_Info is
   begin
      if Index > Natural (Model.Enumeration_Literals.Length) then
         return (others => <>);
      end if;
      return Model.Enumeration_Literals.Element (Index);
   end Static_Enumeration_Literal_At;

   function Static_Enumeration_Literal
     (Model : Static_Model;
      Id    : Static_Enumeration_Literal_Id) return Static_Enumeration_Literal_Info is
   begin
      if Id = No_Static_Enumeration_Literal
        or else Natural (Id) > Natural (Model.Enumeration_Literals.Length)
      then
         return (others => <>);
      end if;
      return Model.Enumeration_Literals.Element (Positive (Id));
   end Static_Enumeration_Literal;

   function Lookup_Enumeration_Literal
     (Model     : Static_Model;
      Region    : Editor.Ada_Declarative_Regions.Region_Id;
      Type_Name : String;
      Literal   : String) return Static_Enumeration_Literal_Id
   is
      Current : Editor.Ada_Declarative_Regions.Region_Id := Region;
      T       : constant String := Normalize_Name (Type_Name);
      L       : constant String := Normalize_Name (Literal);
   begin
      while Current /= Editor.Ada_Declarative_Regions.No_Region loop
         for Index in 1 .. Natural (Model.Enumeration_Literals.Length) loop
            declare
               Item : constant Static_Enumeration_Literal_Info :=
                 Model.Enumeration_Literals.Element (Positive (Index));
            begin
               if Item.Region = Current
                 and then To_String (Item.Normalized_Type_Name) = T
                 and then To_String (Item.Normalized_Literal_Name) = L
               then
                  return Item.Id;
               end if;
            end;
         end loop;
         Current := Editor.Ada_Declarative_Regions.Region (Model.Regions, Current).Parent;
      end loop;

      for Index in 1 .. Natural (Model.Enumeration_Literals.Length) loop
         declare
            Item : constant Static_Enumeration_Literal_Info :=
              Model.Enumeration_Literals.Element (Positive (Index));
         begin
            if To_String (Item.Normalized_Type_Name) = T
              and then To_String (Item.Normalized_Literal_Name) = L
            then
               return Item.Id;
            end if;
         end;
      end loop;
      return No_Static_Enumeration_Literal;
   end Lookup_Enumeration_Literal;

   function Lookup_Enumeration_Literal_By_Position
     (Model     : Static_Model;
      Region    : Editor.Ada_Declarative_Regions.Region_Id;
      Type_Name : String;
      Position  : Long_Long_Integer) return Static_Enumeration_Literal_Id
   is
      Current : Editor.Ada_Declarative_Regions.Region_Id := Region;
      T       : constant String := Normalize_Name (Type_Name);
   begin
      while Current /= Editor.Ada_Declarative_Regions.No_Region loop
         for Index in 1 .. Natural (Model.Enumeration_Literals.Length) loop
            declare
               Item : constant Static_Enumeration_Literal_Info :=
                 Model.Enumeration_Literals.Element (Positive (Index));
            begin
               if Item.Region = Current
                 and then To_String (Item.Normalized_Type_Name) = T
                 and then Item.Position = Position
               then
                  return Item.Id;
               end if;
            end;
         end loop;
         Current := Editor.Ada_Declarative_Regions.Region (Model.Regions, Current).Parent;
      end loop;

      for Index in 1 .. Natural (Model.Enumeration_Literals.Length) loop
         declare
            Item : constant Static_Enumeration_Literal_Info :=
              Model.Enumeration_Literals.Element (Positive (Index));
         begin
            if To_String (Item.Normalized_Type_Name) = T and then Item.Position = Position then
               return Item.Id;
            end if;
         end;
      end loop;
      return No_Static_Enumeration_Literal;
   end Lookup_Enumeration_Literal_By_Position;

   function Static_Binding
     (Model : Static_Model;
      Id    : Static_Binding_Id) return Static_Binding_Info is
   begin
      if Id = No_Static_Binding or else Natural (Id) > Natural (Model.Bindings.Length) then
         return (others => <>);
      end if;
      return Model.Bindings.Element (Positive (Id));
   end Static_Binding;

   function Lookup_Static_Binding_In_Region
     (Model  : Static_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name   : String) return Static_Binding_Id
   is
      Normalized : constant String := Normalize_Name (Name);
   begin
      for Index in 1 .. Natural (Model.Bindings.Length) loop
         declare
            Item : constant Static_Binding_Info := Model.Bindings.Element (Positive (Index));
         begin
            if Item.Region = Region and then To_String (Item.Normalized_Name) = Normalized then
               return Item.Id;
            end if;
         end;
      end loop;
      return No_Static_Binding;
   end Lookup_Static_Binding_In_Region;

   function Lookup_Static_Binding
     (Model  : Static_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name   : String) return Static_Binding_Id
   is
      Current    : Editor.Ada_Declarative_Regions.Region_Id := Region;
      Found      : Static_Binding_Id;
      Normalized : constant String := Normalize_Name (Name);
   begin
      while Current /= Editor.Ada_Declarative_Regions.No_Region loop
         Found := Lookup_Static_Binding_In_Region (Model, Current, Name);
         if Found /= No_Static_Binding then
            return Found;
         end if;
         Current := Editor.Ada_Declarative_Regions.Region (Model.Regions, Current).Parent;
      end loop;

      --  Recovery fallback for older syntax-tree snapshots where declaration
      --  nodes may not yet have a precise owner-region entry.  This preserves
      --  deterministic static-expression staging while later region passes
      --  tighten ownership.
      for Index in 1 .. Natural (Model.Bindings.Length) loop
         declare
            Item : constant Static_Binding_Info := Model.Bindings.Element (Positive (Index));
         begin
            if To_String (Item.Normalized_Name) = Normalized then
               return Item.Id;
            end if;
         end;
      end loop;
      return No_Static_Binding;
   end Lookup_Static_Binding;

   type Parser is record
      Model      : Static_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id := Editor.Ada_Declarative_Regions.No_Region;
      Text       : Ada.Strings.Unbounded.Unbounded_String;
      Pos        : Natural := 1;
      In_Resolve : Natural := 0;
      Allow_Real  : Boolean := False;
   end record;

   function Source (P : Parser) return String is (To_String (P.Text));

   procedure Skip_Spaces (P : in out Parser) is
      S : constant String := Source (P);
   begin
      while P.Pos <= S'Length and then S (P.Pos) = ' ' loop
         P.Pos := P.Pos + 1;
      end loop;
   end Skip_Spaces;

   function At_End (P : in out Parser) return Boolean is
   begin
      Skip_Spaces (P);
      return P.Pos > Source (P)'Length;
   end At_End;

   function Peek (P : in out Parser) return Character is
      S : constant String := Source (P);
   begin
      Skip_Spaces (P);
      if P.Pos > S'Length then
         return ASCII.NUL;
      end if;
      return S (P.Pos);
   end Peek;

   function Match_Char (P : in out Parser; C : Character) return Boolean is
   begin
      if Peek (P) = C then
         P.Pos := P.Pos + 1;
         return True;
      end if;
      return False;
   end Match_Char;

   function Parse_Identifier (P : in out Parser) return String is
      S     : constant String := Source (P);
      Start : Natural;
   begin
      Skip_Spaces (P);
      if P.Pos > S'Length
        or else not (Is_Letter (S (P.Pos)) or else S (P.Pos) = '_')
      then
         return "";
      end if;
      Start := P.Pos;
      while P.Pos <= S'Length
        and then (Is_Identifier_Char (S (P.Pos)))
      loop
         P.Pos := P.Pos + 1;
      end loop;
      return S (Start .. P.Pos - 1);
   end Parse_Identifier;

   function Match_Word (P : in out Parser; Word : String) return Boolean is
      Save : constant Natural := P.Pos;
      Id   : constant String := Parse_Identifier (P);
   begin
      if Normalize_Name (Id) = Normalize_Name (Word) then
         return True;
      end if;
      P.Pos := Save;
      return False;
   end Match_Word;

   function Parse_Primary (P : in out Parser) return Static_Value_Info;
   function Parse_Factor (P : in out Parser) return Static_Value_Info;
   function Parse_Term (P : in out Parser) return Static_Value_Info;
   function Parse_Expression (P : in out Parser) return Static_Value_Info;

   function Combine
     (Left  : Static_Value_Info;
      Right : Static_Value_Info;
      Op    : String;
      Text  : String) return Static_Value_Info is
   begin
      if Left.Status = Static_Value_Real or else Right.Status = Static_Value_Real then
         if not ((Left.Status = Static_Value_Integer or else Left.Status = Static_Value_Real)
                 and then (Right.Status = Static_Value_Integer or else Right.Status = Static_Value_Real))
         then
            return (if Left.Status /= Static_Value_Integer and then Left.Status /= Static_Value_Real
                    then Left else Right);
         else
            declare
               L : constant Long_Float :=
                 (if Left.Status = Static_Value_Real then Left.Real_Value else Long_Float (Left.Integer_Value));
               R : constant Long_Float :=
                 (if Right.Status = Static_Value_Real then Right.Real_Value else Long_Float (Right.Integer_Value));
            begin
               if Op = "mod" or else Op = "rem" then
                  return Make_Value (Static_Value_Non_Static, Text);
               elsif Op = "/" and then R = 0.0 then
                  return Make_Value (Static_Value_Division_By_Zero, Text);
               elsif Op = "+" then
                  return Make_Value (Static_Value_Real, Text, 0, Real_Value => L + R);
               elsif Op = "-" then
                  return Make_Value (Static_Value_Real, Text, 0, Real_Value => L - R);
               elsif Op = "*" then
                  return Make_Value (Static_Value_Real, Text, 0, Real_Value => L * R);
               elsif Op = "/" then
                  return Make_Value (Static_Value_Real, Text, 0, Real_Value => L / R);
               else
                  return Make_Value (Static_Value_Malformed, Text);
               end if;
            end;
         end if;
      elsif Left.Status /= Static_Value_Integer then
         return Left;
      elsif Right.Status /= Static_Value_Integer then
         return Right;
      elsif (Op = "/" or else Op = "mod" or else Op = "rem") and then Right.Integer_Value = 0 then
         return Make_Value (Static_Value_Division_By_Zero, Text);
      elsif Op = "+" then
         return Make_Value (Static_Value_Integer, Text, Left.Integer_Value + Right.Integer_Value);
      elsif Op = "-" then
         return Make_Value (Static_Value_Integer, Text, Left.Integer_Value - Right.Integer_Value);
      elsif Op = "*" then
         return Make_Value (Static_Value_Integer, Text, Left.Integer_Value * Right.Integer_Value);
      elsif Op = "/" then
         return Make_Value (Static_Value_Integer, Text, Left.Integer_Value / Right.Integer_Value);
      elsif Op = "mod" then
         return Make_Value (Static_Value_Integer, Text, Left.Integer_Value mod Right.Integer_Value);
      elsif Op = "rem" then
         return Make_Value (Static_Value_Integer, Text, Left.Integer_Value rem Right.Integer_Value);
      else
         return Make_Value (Static_Value_Malformed, Text);
      end if;
   end Combine;

   function Parse_Primary (P : in out Parser) return Static_Value_Info is
      S     : constant String := Source (P);
      Start : Natural;
   begin
      Skip_Spaces (P);
      if P.Pos > S'Length then
         return Make_Value (Static_Value_Malformed, S);
      elsif Match_Char (P, '(') then
         declare
            Value : Static_Value_Info := Parse_Expression (P);
         begin
            if not Match_Char (P, ')') then
               return Make_Value (Static_Value_Malformed, S);
            end if;
            return Value;
         end;
      elsif P.Pos <= S'Length and then Is_Digit (S (P.Pos)) then
         Start := P.Pos;
         while P.Pos <= S'Length and then (Is_Digit (S (P.Pos)) or else S (P.Pos) = '_') loop
            P.Pos := P.Pos + 1;
         end loop;
         if P.Pos < S'Length and then S (P.Pos) = '.' and then S (P.Pos + 1) /= '.' then
            P.Pos := P.Pos + 1;
            while P.Pos <= S'Length and then (Is_Digit (S (P.Pos)) or else S (P.Pos) = '_') loop
               P.Pos := P.Pos + 1;
            end loop;
         end if;
         if P.Pos <= S'Length and then (S (P.Pos) = 'e' or else S (P.Pos) = 'E') then
            declare
               Save : constant Natural := P.Pos;
            begin
               P.Pos := P.Pos + 1;
               if P.Pos <= S'Length and then (S (P.Pos) = '+' or else S (P.Pos) = '-') then
                  P.Pos := P.Pos + 1;
               end if;
               if P.Pos <= S'Length and then Is_Digit (S (P.Pos)) then
                  while P.Pos <= S'Length and then (Is_Digit (S (P.Pos)) or else S (P.Pos) = '_') loop
                     P.Pos := P.Pos + 1;
                  end loop;
               else
                  P.Pos := Save;
               end if;
            end;
         end if;
         declare
            Raw : constant String := S (Start .. P.Pos - 1);
            Clean : String (1 .. Raw'Length);
            Last  : Natural := 0;
            Real_Literal : Boolean := False;
         begin
            for C of Raw loop
               if C /= '_' then
                  Last := Last + 1;
                  Clean (Last) := C;
                  if C = '.' or else C = 'e' or else C = 'E' then
                     Real_Literal := True;
                  end if;
               end if;
            end loop;
            if Real_Literal then
               if P.Allow_Real then
                  return Make_Value
                    (Static_Value_Real, Raw, 0, Real_Value => Long_Float'Value (Clean (1 .. Last)));
               else
                  return Make_Value (Static_Value_Non_Static, Raw);
               end if;
            else
               return Make_Value (Static_Value_Integer, Raw, Long_Long_Integer'Value (Clean (1 .. Last)));
            end if;
         exception
            when others =>
               return Make_Value (Static_Value_Malformed, Raw);
         end;
      else
         declare
            Name : constant String := Parse_Identifier (P);
         begin
            if Name = "" then
               return Make_Value (Static_Value_Non_Static, S);
            elsif Match_Char (P, Character'Val (39)) then
               declare
                  Attr : constant String := Parse_Identifier (P);
                  Attr_Norm : constant String := Normalize_Name (Attr);
               begin
                  if Attr_Norm = "first" or else Attr_Norm = "last" then
                     declare
                        Bound_Id : constant Static_Type_Bound_Id :=
                          Lookup_Type_Bound (P.Model, P.Region, Name);
                     begin
                        if Bound_Id = No_Static_Type_Bound then
                           return Make_Value
                             (Static_Value_Unresolved_Name, Name & "'" & Attr, 0, Name,
                              Name, Attr_Norm);
                        else
                           declare
                              Bound : constant Static_Type_Bound_Info :=
                                Static_Type_Bound (P.Model, Bound_Id);
                              Value : constant Static_Value_Info :=
                                (if Attr_Norm = "first" then Bound.First_Value else Bound.Last_Value);
                           begin
                              if Value.Status = Static_Value_Integer then
                                 return Make_Value
                                   (Static_Value_Integer, Name & "'" & Attr, Value.Integer_Value, "",
                                    Name, Attr_Norm);
                              else
                                 return Value;
                              end if;
                           end;
                        end if;
                     end;
                  elsif Attr_Norm = "pos" or else Attr_Norm = "val" then
                     if not Match_Char (P, '(') then
                        return Make_Value (Static_Value_Malformed, Name & "'" & Attr, 0, "", Name, Attr_Norm);
                     end if;
                     declare
                        Arg : Static_Value_Info := Parse_Expression (P);
                     begin
                        if not Match_Char (P, ')') then
                           return Make_Value (Static_Value_Malformed, S, 0, "", Name, Attr_Norm);
                        elsif Attr_Norm = "pos"
                          and then Arg.Status = Static_Value_Unresolved_Name
                          and then To_String (Arg.Referenced_Name) /= ""
                        then
                           declare
                              Literal_Id : constant Static_Enumeration_Literal_Id :=
                                Lookup_Enumeration_Literal
                                  (P.Model, P.Region, Name, To_String (Arg.Referenced_Name));
                           begin
                              if Literal_Id /= No_Static_Enumeration_Literal then
                                 declare
                                    Literal : constant Static_Enumeration_Literal_Info :=
                                      Static_Enumeration_Literal (P.Model, Literal_Id);
                                 begin
                                    return Make_Value
                                      (Static_Value_Integer, Name & "'" & Attr, Literal.Position, "",
                                       Name, Attr_Norm, To_String (Literal.Literal_Name),
                                       Literal.Position);
                                 end;
                              end if;
                           end;
                           return Arg;
                        elsif Attr_Norm = "val" and then Arg.Status = Static_Value_Integer then
                           declare
                              Literal_Id : constant Static_Enumeration_Literal_Id :=
                                Lookup_Enumeration_Literal_By_Position
                                  (P.Model, P.Region, Name, Arg.Integer_Value);
                           begin
                              if Literal_Id /= No_Static_Enumeration_Literal then
                                 declare
                                    Literal : constant Static_Enumeration_Literal_Info :=
                                      Static_Enumeration_Literal (P.Model, Literal_Id);
                                 begin
                                    return Make_Value
                                      (Static_Value_Enumeration_Literal, Name & "'" & Attr,
                                       Arg.Integer_Value, "", Name, Attr_Norm,
                                       To_String (Literal.Literal_Name), Literal.Position);
                                 end;
                              end if;
                           end;
                           return Make_Value
                             (Static_Value_Integer, Name & "'" & Attr, Arg.Integer_Value, "",
                              Name, Attr_Norm);
                        elsif Arg.Status = Static_Value_Integer then
                           return Make_Value
                             (Static_Value_Integer, Name & "'" & Attr, Arg.Integer_Value, "",
                              Name, Attr_Norm);
                        else
                           return Arg;
                        end if;
                     end;
                  else
                     return Make_Value
                       (Static_Value_Unsupported_Attribute, Name & "'" & Attr, 0, "",
                        Name, Attr_Norm);
                  end if;
               end;
            elsif P.In_Resolve > 32 then
               return Make_Value (Static_Value_Cycle, Name, 0, Name);
            else
               declare
                  Id : constant Static_Binding_Id := Lookup_Static_Binding (P.Model, P.Region, Name);
               begin
                  if Id = No_Static_Binding then
                     return Make_Value (Static_Value_Unresolved_Name, Name, 0, Name);
                  else
                     declare
                        Binding : constant Static_Binding_Info := Static_Binding (P.Model, Id);
                     begin
                        if Binding.Value.Status = Static_Value_Not_Checked then
                           return Make_Value (Static_Value_Non_Static, Name, 0, Name);
                        end if;
                        return Binding.Value;
                     end;
                  end if;
               end;
            end if;
         end;
      end if;
   end Parse_Primary;

   function Parse_Factor (P : in out Parser) return Static_Value_Info is
      S : constant String := Source (P);
   begin
      if Match_Char (P, '+') then
         return Parse_Factor (P);
      elsif Match_Char (P, '-') then
         declare
            Value : Static_Value_Info := Parse_Factor (P);
         begin
            if Value.Status = Static_Value_Integer then
               return Make_Value (Static_Value_Integer, S, -Value.Integer_Value);
            elsif Value.Status = Static_Value_Real then
               return Make_Value (Static_Value_Real, S, 0, Real_Value => -Value.Real_Value);
            else
               return Value;
            end if;
         end;
      else
         return Parse_Primary (P);
      end if;
   end Parse_Factor;

   function Parse_Term (P : in out Parser) return Static_Value_Info is
      S      : constant String := Source (P);
      Result : Static_Value_Info := Parse_Factor (P);
   begin
      loop
         if Match_Char (P, '*') then
            Result := Combine (Result, Parse_Factor (P), "*", S);
         elsif Match_Char (P, '/') then
            Result := Combine (Result, Parse_Factor (P), "/", S);
         elsif Match_Word (P, "mod") then
            Result := Combine (Result, Parse_Factor (P), "mod", S);
         elsif Match_Word (P, "rem") then
            Result := Combine (Result, Parse_Factor (P), "rem", S);
         else
            return Result;
         end if;
      end loop;
   end Parse_Term;

   function Parse_Expression (P : in out Parser) return Static_Value_Info is
      S      : constant String := Source (P);
      Result : Static_Value_Info := Parse_Term (P);
   begin
      loop
         if Match_Char (P, '+') then
            Result := Combine (Result, Parse_Term (P), "+", S);
         elsif Match_Char (P, '-') then
            Result := Combine (Result, Parse_Term (P), "-", S);
         else
            return Result;
         end if;
      end loop;
   end Parse_Expression;

   function Evaluate_Integer_Expression
     (Model      : Static_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Expression : String) return Static_Value_Info
   is
      Value : constant Static_Value_Info :=
        Evaluate_Numeric_Expression (Model, Region, Expression);
   begin
      if Value.Status = Static_Value_Real then
         return Make_Value (Static_Value_Non_Static, Expression);
      end if;
      return Value;
   end Evaluate_Integer_Expression;

   function Evaluate_Numeric_Expression
     (Model      : Static_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Expression : String) return Static_Value_Info
   is
      P : aliased Parser :=
        (Model      => Model,
         Region     => Region,
         Text       => To_Unbounded_String (Expression),
         Pos        => 1,
         In_Resolve => 0,
         Allow_Real  => True);
      Value : Static_Value_Info;
   begin
      if Trim (Expression) = "" then
         return Make_Value (Static_Value_Malformed, Expression);
      end if;
      Value := Parse_Expression (P);
      if (Value.Status = Static_Value_Integer or else Value.Status = Static_Value_Real)
        and then not At_End (P)
      then
         return Make_Value (Static_Value_Non_Static, Expression);
      end if;
      Value.Expression_Text := To_Unbounded_String (Expression);
      Value.Normalized_Text := To_Unbounded_String (Normalize_Name (Expression));
      Value.Fingerprint := Hash_Value (Value);
      return Value;
   end Evaluate_Numeric_Expression;

   function Child_Label
     (Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Parent : Editor.Ada_Syntax_Tree.Node_Id;
      Kind   : Editor.Ada_Syntax_Tree.Node_Kind) return String
   is
      use type Editor.Ada_Syntax_Tree.Node_Kind;
   begin
      for Index in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Parent) loop
         declare
            Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node (Tree, Editor.Ada_Syntax_Tree.Child_At (Tree, Parent, Index));
         begin
            if Child.Kind = Kind then
               return To_String (Child.Label);
            end if;
         end;
      end loop;
      return "";
   end Child_Label;

   function Range_First_Text (Subtype_Text : String) return String is
      Lowered     : constant String := Normalize_Name (Subtype_Text);
      After_Range : constant String := Segment_After (Lowered, "range");
   begin
      if After_Range = "" or else not Contains (After_Range, "..") then
         return "";
      end if;
      return Segment_Before (After_Range, "..");
   end Range_First_Text;

   function Range_Last_Text (Subtype_Text : String) return String is
      Lowered     : constant String := Normalize_Name (Subtype_Text);
      After_Range : constant String := Segment_After (Lowered, "range");
   begin
      if After_Range = "" or else not Contains (After_Range, "..") then
         return "";
      end if;
      return Segment_After (After_Range, "..");
   end Range_Last_Text;


   function Fixed_Delta_Text (Subtype_Text : String) return String is
      Lowered     : constant String := Normalize_Name (Subtype_Text);
      After_Delta : constant String := Segment_After (Lowered, "delta");
      Before_Range : constant String := Segment_Before (After_Delta, "range");
      Before_Digits : constant String := Segment_Before (Before_Range, "digits");
   begin
      if After_Delta = "" then
         return "";
      end if;
      return Trim (Before_Digits);
   end Fixed_Delta_Text;

   function Fixed_Digits_Text (Subtype_Text : String) return String is
      Lowered      : constant String := Normalize_Name (Subtype_Text);
      After_Digits : constant String := Segment_After (Lowered, "digits");
   begin
      if After_Digits = "" then
         return "";
      end if;
      return Segment_Before (After_Digits, "range");
   end Fixed_Digits_Text;

   function Modular_Modulus_Text (Subtype_Text : String) return String is
      Lowered : constant String := Normalize_Name (Subtype_Text);
      Pos     : Natural := Ada.Strings.Fixed.Index (Lowered, "mod");
   begin
      while Pos /= 0 loop
         declare
            Before_OK : constant Boolean :=
              Pos = Lowered'First
              or else not Is_Identifier_Char (Lowered (Pos - 1));
            After_Index : constant Natural := Pos + 3;
            After_OK : constant Boolean :=
              After_Index > Lowered'Last
              or else not Is_Identifier_Char (Lowered (After_Index));
         begin
            if Before_OK and then After_OK then
               if After_Index > Lowered'Last then
                  return "";
               end if;
               return Trim (Lowered (After_Index .. Lowered'Last));
            end if;
         end;
         declare
            Rest_Start : constant Natural := Pos + 1;
            Rest_Pos   : Natural := 0;
         begin
            if Rest_Start <= Lowered'Last then
               Rest_Pos := Ada.Strings.Fixed.Index (Lowered (Rest_Start .. Lowered'Last), "mod");
            end if;
            if Rest_Pos = 0 then
               Pos := 0;
            else
               Pos := Rest_Start + Rest_Pos - 1;
            end if;
         end;
      end loop;
      return "";
   end Modular_Modulus_Text;

   function Build
     (Tree    : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions : Editor.Ada_Declarative_Regions.Region_Model) return Static_Model
   is
      use type Editor.Ada_Syntax_Tree.Node_Kind;
      Model : Static_Model;
   begin
      Model.Regions := Regions;
      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            Node : constant Editor.Ada_Syntax_Tree.Node_Info := Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
         begin
            if Node.Kind = Editor.Ada_Syntax_Tree.Node_Number_Declaration
              or else Node.Kind = Editor.Ada_Syntax_Tree.Node_Constant_Declaration
            then
               declare
                  Name : constant String := Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Declaration_Name);
                  Expr : constant String := Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Declaration_Default);
                  Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
                    Editor.Ada_Declarative_Regions.Region_For_Node (Regions, Node.Id);
                  Value : constant Static_Value_Info := Evaluate_Numeric_Expression (Model, Region, Expr);
                  Item  : Static_Binding_Info;
               begin
                  if Name /= "" and then Expr /= "" then
                     Item.Id := Static_Binding_Id (Natural (Model.Bindings.Length) + 1);
                     Item.Kind := (if Node.Kind = Editor.Ada_Syntax_Tree.Node_Number_Declaration
                                   then Static_Binding_Named_Number
                                   else Static_Binding_Constant);
                     Item.Node := Node.Id;
                     Item.Region := Region;
                     Item.Name := To_Unbounded_String (Name);
                     Item.Normalized_Name := To_Unbounded_String (Normalize_Name (Name));
                     Item.Expression_Text := To_Unbounded_String (Expr);
                     Item.Value := Value;
                     Item.Start_Line := Node.Source_Span.Start_Line;
                     Item.End_Line := Node.Source_Span.End_Line;
                     Item.Fingerprint :=
                       (Natural (Item.Id) * 1000003
                        + Static_Binding_Kind'Pos (Item.Kind) * 10007
                        + Hash_Text (Name) * 101
                        + Value.Fingerprint * 31) mod Natural'Last;
                     Model.Result_Fingerprint :=
                       (Model.Result_Fingerprint * 65599 + Item.Fingerprint) mod Natural'Last;
                     Model.Bindings.Append (Item);
                  end if;
               end;
            end if;

            if Node.Kind = Editor.Ada_Syntax_Tree.Node_Type_Declaration
              or else Node.Kind = Editor.Ada_Syntax_Tree.Node_Subtype_Declaration
              or else Node.Kind = Editor.Ada_Syntax_Tree.Node_Formal_Type_Declaration
            then
               declare
                  Name : constant String :=
                    Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Declaration_Name);
                  Subtype_Text : constant String :=
                    Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Declaration_Subtype);
                  Delta_Text : constant String := Fixed_Delta_Text (Subtype_Text);
                  Digits_Text : constant String := Fixed_Digits_Text (Subtype_Text);
                  First_Text : constant String := Range_First_Text (Subtype_Text);
                  Last_Text  : constant String := Range_Last_Text (Subtype_Text);
                  Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
                    Editor.Ada_Declarative_Regions.Region_For_Node (Regions, Node.Id);
                  Item : Static_Fixed_Type_Info;
               begin
                  if Name /= "" and then Delta_Text /= "" and then Delta_Text /= "<>" then
                     Item.Id := Static_Fixed_Type_Id (Natural (Model.Fixed_Types.Length) + 1);
                     Item.Node := Node.Id;
                     Item.Region := Region;
                     Item.Name := To_Unbounded_String (Name);
                     Item.Normalized_Name := To_Unbounded_String (Normalize_Name (Name));
                     Item.Delta_Text := To_Unbounded_String (Delta_Text);
                     Item.Digits_Text := To_Unbounded_String (Digits_Text);
                     Item.First_Text := To_Unbounded_String (First_Text);
                     Item.Last_Text := To_Unbounded_String (Last_Text);
                     Item.Delta_Value := Evaluate_Numeric_Expression (Model, Region, Delta_Text);
                     Item.Digits_Value :=
                       (if Digits_Text = "" or else Digits_Text = "<>"
                        then Make_Value (Static_Value_Not_Checked, Digits_Text)
                        else Evaluate_Integer_Expression (Model, Region, Digits_Text));
                     Item.First_Value :=
                       (if First_Text = "" then Make_Value (Static_Value_Not_Checked, First_Text)
                        else Evaluate_Numeric_Expression (Model, Region, First_Text));
                     Item.Last_Value :=
                       (if Last_Text = "" then Make_Value (Static_Value_Not_Checked, Last_Text)
                        else Evaluate_Numeric_Expression (Model, Region, Last_Text));
                     Item.Start_Line := Node.Source_Span.Start_Line;
                     Item.End_Line := Node.Source_Span.End_Line;
                     Item.Fingerprint :=
                       (Natural (Item.Id) * 1000003
                        + Hash_Text (Name) * 101
                        + Item.Delta_Value.Fingerprint * 211
                        + Item.First_Value.Fingerprint * 307
                        + Item.Last_Value.Fingerprint * 401) mod Natural'Last;
                     Model.Fixed_Types.Append (Item);
                  end if;
               end;
            end if;

            if Node.Kind = Editor.Ada_Syntax_Tree.Node_Type_Declaration then
               declare
                  Name : constant String :=
                    Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Declaration_Name);
                  Subtype_Text : constant String :=
                    Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Declaration_Subtype);
                  Modulus_Text : constant String := Modular_Modulus_Text (Subtype_Text);
                  Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
                    Editor.Ada_Declarative_Regions.Region_For_Node (Regions, Node.Id);
                  Item : Static_Modular_Type_Info;
               begin
                  if Name /= "" and then Modulus_Text /= "" then
                     Item.Id := Static_Modular_Type_Id (Natural (Model.Modular_Types.Length) + 1);
                     Item.Node := Node.Id;
                     Item.Region := Region;
                     Item.Name := To_Unbounded_String (Name);
                     Item.Normalized_Name := To_Unbounded_String (Normalize_Name (Name));
                     Item.Modulus_Text := To_Unbounded_String (Modulus_Text);
                     Item.Modulus_Value := Evaluate_Integer_Expression (Model, Region, Modulus_Text);
                     Item.Start_Line := Node.Source_Span.Start_Line;
                     Item.End_Line := Node.Source_Span.End_Line;
                     Item.Fingerprint :=
                       (Natural (Item.Id) * 1000003
                        + Hash_Text (Name) * 101
                        + Item.Modulus_Value.Fingerprint * 313) mod Natural'Last;
                     Model.Modular_Types.Append (Item);
                  end if;
               end;
            end if;

            if Node.Kind = Editor.Ada_Syntax_Tree.Node_Type_Declaration then
               declare
                  Name : constant String :=
                    Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Declaration_Name);
                  Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
                    Editor.Ada_Declarative_Regions.Region_For_Node (Regions, Node.Id);
                  Position : Long_Long_Integer := 0;
               begin
                  if Name /= "" then
                     for Child_Index in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Node.Id) loop
                        declare
                           Child_Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
                             Editor.Ada_Syntax_Tree.Node
                               (Tree, Editor.Ada_Syntax_Tree.Child_At (Tree, Node.Id, Child_Index));
                           Literal_Name : constant String := To_String (Child_Node.Label);
                           Item : Static_Enumeration_Literal_Info;
                        begin
                           if Child_Node.Kind = Editor.Ada_Syntax_Tree.Node_Enumeration_Literal_Declaration
                             and then Literal_Name /= ""
                           then
                              Item.Id := Static_Enumeration_Literal_Id
                                (Natural (Model.Enumeration_Literals.Length) + 1);
                              Item.Node := Child_Node.Id;
                              Item.Region := Region;
                              Item.Type_Name := To_Unbounded_String (Name);
                              Item.Normalized_Type_Name := To_Unbounded_String (Normalize_Name (Name));
                              Item.Literal_Name := To_Unbounded_String (Literal_Name);
                              Item.Normalized_Literal_Name := To_Unbounded_String (Normalize_Name (Literal_Name));
                              Item.Position := Position;
                              Item.Start_Line := Child_Node.Source_Span.Start_Line;
                              Item.End_Line := Child_Node.Source_Span.End_Line;
                              Item.Fingerprint :=
                                (Natural (Item.Id) * 1000003
                                 + Hash_Text (Name) * 101
                                 + Hash_Text (Literal_Name) * 211
                                 + Natural (Position mod 1_000_003) * 307) mod Natural'Last;
                              Model.Enumeration_Literals.Append (Item);
                              Position := Position + 1;
                           end if;
                        end;
                     end loop;
                  end if;
               end;
            end if;

            if Node.Kind = Editor.Ada_Syntax_Tree.Node_Type_Declaration
              or else Node.Kind = Editor.Ada_Syntax_Tree.Node_Subtype_Declaration
              or else Node.Kind = Editor.Ada_Syntax_Tree.Node_Formal_Type_Declaration
            then
               declare
                  Name : constant String :=
                    Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Declaration_Name);
                  Subtype_Text : constant String :=
                    Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Declaration_Subtype);
                  First_Text : constant String := Range_First_Text (Subtype_Text);
                  Last_Text  : constant String := Range_Last_Text (Subtype_Text);
                  Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
                    Editor.Ada_Declarative_Regions.Region_For_Node (Regions, Node.Id);
                  Item : Static_Type_Bound_Info;
               begin
                  if Name /= "" and then First_Text /= "" and then Last_Text /= "" then
                     Item.Id := Static_Type_Bound_Id (Natural (Model.Type_Bounds.Length) + 1);
                     Item.Node := Node.Id;
                     Item.Region := Region;
                     Item.Name := To_Unbounded_String (Name);
                     Item.Normalized_Name := To_Unbounded_String (Normalize_Name (Name));
                     Item.First_Text := To_Unbounded_String (First_Text);
                     Item.Last_Text := To_Unbounded_String (Last_Text);
                     Item.First_Value := Evaluate_Integer_Expression (Model, Region, First_Text);
                     Item.Last_Value := Evaluate_Integer_Expression (Model, Region, Last_Text);
                     Item.Start_Line := Node.Source_Span.Start_Line;
                     Item.End_Line := Node.Source_Span.End_Line;
                     Item.Fingerprint :=
                       (Natural (Item.Id) * 1000003
                        + Hash_Text (Name) * 101
                        + Item.First_Value.Fingerprint * 17
                        + Item.Last_Value.Fingerprint * 31) mod Natural'Last;
                     Model.Type_Bounds.Append (Item);
                  end if;
               end;
            end if;
         end;
      end loop;

      --  Re-evaluate once after all same-region bindings are known, so later
      --  constants can reference earlier named numbers and constants.
      for Index in 1 .. Natural (Model.Bindings.Length) loop
         declare
            Item : Static_Binding_Info := Model.Bindings.Element (Positive (Index));
         begin
            Item.Value := Evaluate_Numeric_Expression
              (Model, Item.Region, To_String (Item.Expression_Text));
            Item.Fingerprint :=
              (Natural (Item.Id) * 1000003
               + Static_Binding_Kind'Pos (Item.Kind) * 10007
               + Hash_Text (To_String (Item.Name)) * 101
               + Item.Value.Fingerprint * 31) mod Natural'Last;
            Model.Bindings.Replace_Element (Positive (Index), Item);
         end;
      end loop;

      for Index in 1 .. Natural (Model.Type_Bounds.Length) loop
         declare
            Item : Static_Type_Bound_Info := Model.Type_Bounds.Element (Positive (Index));
         begin
            Item.First_Value := Evaluate_Integer_Expression
              (Model, Item.Region, To_String (Item.First_Text));
            Item.Last_Value := Evaluate_Integer_Expression
              (Model, Item.Region, To_String (Item.Last_Text));
            Item.Fingerprint :=
              (Natural (Item.Id) * 1000003
               + Hash_Text (To_String (Item.Name)) * 101
               + Item.First_Value.Fingerprint * 17
               + Item.Last_Value.Fingerprint * 31) mod Natural'Last;
            Model.Type_Bounds.Replace_Element (Positive (Index), Item);
         end;
      end loop;

      for Index in 1 .. Natural (Model.Fixed_Types.Length) loop
         declare
            Item : Static_Fixed_Type_Info := Model.Fixed_Types.Element (Positive (Index));
         begin
            Item.Delta_Value := Evaluate_Numeric_Expression
              (Model, Item.Region, To_String (Item.Delta_Text));
            if To_String (Item.Digits_Text) /= "" and then To_String (Item.Digits_Text) /= "<>" then
               Item.Digits_Value := Evaluate_Integer_Expression
                 (Model, Item.Region, To_String (Item.Digits_Text));
            end if;
            if To_String (Item.First_Text) /= "" then
               Item.First_Value := Evaluate_Numeric_Expression
                 (Model, Item.Region, To_String (Item.First_Text));
            end if;
            if To_String (Item.Last_Text) /= "" then
               Item.Last_Value := Evaluate_Numeric_Expression
                 (Model, Item.Region, To_String (Item.Last_Text));
            end if;
            Item.Fingerprint :=
              (Natural (Item.Id) * 1000003
               + Hash_Text (To_String (Item.Name)) * 101
               + Item.Delta_Value.Fingerprint * 211
               + Item.First_Value.Fingerprint * 307
               + Item.Last_Value.Fingerprint * 401) mod Natural'Last;
            Model.Fixed_Types.Replace_Element (Positive (Index), Item);
         end;
      end loop;

      for Index in 1 .. Natural (Model.Modular_Types.Length) loop
         declare
            Item : Static_Modular_Type_Info := Model.Modular_Types.Element (Positive (Index));
         begin
            Item.Modulus_Value := Evaluate_Integer_Expression
              (Model, Item.Region, To_String (Item.Modulus_Text));
            Item.Fingerprint :=
              (Natural (Item.Id) * 1000003
               + Hash_Text (To_String (Item.Name)) * 101
               + Item.Modulus_Value.Fingerprint * 313) mod Natural'Last;
            Model.Modular_Types.Replace_Element (Positive (Index), Item);
         end;
      end loop;

      --  Re-evaluate again after subtype bounds have been staged, so static
      --  constants can depend on scalar subtype attributes such as T'First
      --  and T'Last.
      for Index in 1 .. Natural (Model.Bindings.Length) loop
         declare
            Item : Static_Binding_Info := Model.Bindings.Element (Positive (Index));
         begin
            Item.Value := Evaluate_Numeric_Expression
              (Model, Item.Region, To_String (Item.Expression_Text));
            Item.Fingerprint :=
              (Natural (Item.Id) * 1000003
               + Static_Binding_Kind'Pos (Item.Kind) * 10007
               + Hash_Text (To_String (Item.Name)) * 101
               + Item.Value.Fingerprint * 31) mod Natural'Last;
            Model.Bindings.Replace_Element (Positive (Index), Item);
         end;
      end loop;

      Model.Result_Fingerprint := 0;
      for Index in 1 .. Natural (Model.Fixed_Types.Length) loop
         Model.Result_Fingerprint :=
           (Model.Result_Fingerprint * 65599
            + Model.Fixed_Types.Element (Positive (Index)).Fingerprint)
           mod Natural'Last;
      end loop;
      for Index in 1 .. Natural (Model.Modular_Types.Length) loop
         Model.Result_Fingerprint :=
           (Model.Result_Fingerprint * 65599
            + Model.Modular_Types.Element (Positive (Index)).Fingerprint)
           mod Natural'Last;
      end loop;
      for Index in 1 .. Natural (Model.Enumeration_Literals.Length) loop
         Model.Result_Fingerprint :=
           (Model.Result_Fingerprint * 65599
            + Model.Enumeration_Literals.Element (Positive (Index)).Fingerprint)
           mod Natural'Last;
      end loop;
      for Index in 1 .. Natural (Model.Type_Bounds.Length) loop
         Model.Result_Fingerprint :=
           (Model.Result_Fingerprint * 65599 + Model.Type_Bounds.Element (Positive (Index)).Fingerprint)
           mod Natural'Last;
      end loop;
      for Index in 1 .. Natural (Model.Bindings.Length) loop
         Model.Result_Fingerprint :=
           (Model.Result_Fingerprint * 65599 + Model.Bindings.Element (Positive (Index)).Fingerprint)
           mod Natural'Last;
      end loop;
      return Model;
   end Build;

   function Is_Static_Integer (Value : Static_Value_Info) return Boolean is
   begin
      return Value.Status = Static_Value_Integer
        or else Value.Status = Static_Value_Modular_Integer;
   end Is_Static_Integer;

   function Is_Static_Real (Value : Static_Value_Info) return Boolean is
   begin
      return Value.Status = Static_Value_Real
        or else Value.Status = Static_Value_Fixed_Point;
   end Is_Static_Real;

   function Is_Static_Numeric (Value : Static_Value_Info) return Boolean is
   begin
      return Is_Static_Integer (Value) or else Is_Static_Real (Value);
   end Is_Static_Numeric;

   function Is_Decided (Value : Static_Value_Info) return Boolean is
   begin
      return Value.Status /= Static_Value_Not_Checked
        and then Value.Status /= Static_Value_Unresolved_Name;
   end Is_Decided;

   function Fingerprint (Model : Static_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Static_Expressions;
