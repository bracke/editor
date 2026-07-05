with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package body Editor.Ada_Language_Model is

   pragma Suppress (Overflow_Check);

   Fingerprint_Modulus : constant Long_Long_Integer := 2_147_483_647;

   type Natural_Addend_Array is array (Positive range <>) of Natural;

   function Hash_Mix
     (Seed       : Natural;
      Addend     : Long_Long_Integer;
      Multiplier : Long_Long_Integer := 131) return Natural
   is
   begin
      return Natural
        ((Long_Long_Integer (Seed) * Multiplier + Addend) mod Fingerprint_Modulus);
   end Hash_Mix;

   function Hash_Mix
     (Seed       : Natural;
      Addends    : Natural_Addend_Array;
      Multiplier : Long_Long_Integer := 131) return Natural
   is
      Acc : Long_Long_Integer := Long_Long_Integer (Seed) * Multiplier;
   begin
      for Addend of Addends loop
         Acc := Acc + Long_Long_Integer (Addend);
      end loop;
      return Natural (Acc mod Fingerprint_Modulus);
   end Hash_Mix;

   function Hash_String (Seed : Natural; Text : String) return Natural is
      H : Natural := Seed;
   begin
      for C of Text loop
         H := Hash_Mix (H, Long_Long_Integer (Character'Pos (C)) + 1);
      end loop;
      return H;
   end Hash_String;

   function Normalize_Name (Name : String) return String is
      Result : String (Name'Range);
   begin
      for I in Name'Range loop
         Result (I) := Ada.Characters.Handling.To_Lower (Name (I));
      end loop;
      return Result;
   end Normalize_Name;

   function Hash_Boolean (Seed : Natural; Value : Boolean) return Natural is
   begin
      if Value then
         return Hash_Mix (Seed, 1);
      else
         return Hash_Mix (Seed, 2);
      end if;
   end Hash_Boolean;

   function Hash_Flags
     (Seed  : Natural;
      Flags : Declaration_Flags) return Natural
   is
      H : Natural := Seed;
   begin
      H := Hash_Boolean (H, Flags.Is_Private);
      H := Hash_Boolean (H, Flags.Is_Abstract);
      H := Hash_Boolean (H, Flags.Is_Overriding);
      H := Hash_Boolean (H, Flags.Is_Not_Overriding);
      H := Hash_Boolean (H, Flags.Is_Generic);
      H := Hash_Boolean (H, Flags.Is_Rename);
      H := Hash_Boolean (H, Flags.Is_Instantiation);
      H := Hash_Boolean (H, Flags.Is_Separate);
      H := Hash_Boolean (H, Flags.Is_Body);
      H := Hash_Boolean (H, Flags.Has_Representation_Clause);
      H := Hash_Boolean (H, Flags.Has_Aspect_Specification);
      H := Hash_Boolean (H, Flags.Has_Pragma_Metadata);
      H := Hash_Boolean (H, Flags.Has_Null_Exclusion);
      H := Hash_Boolean (H, Flags.Has_Aliased_Metadata);
      H := Hash_Boolean (H, Flags.Has_Limited_Metadata);
      H := Hash_Boolean (H, Flags.Has_Tagged_Metadata);
      H := Hash_Boolean (H, Flags.Has_Interface_Metadata);
      H := Hash_Boolean (H, Flags.Has_Synchronized_Metadata);
      H := Hash_Boolean (H, Flags.Has_Task_Interface_Metadata);
      H := Hash_Boolean (H, Flags.Has_Protected_Interface_Metadata);
      H := Hash_Boolean (H, Flags.Has_Task_Type_Metadata);
      H := Hash_Boolean (H, Flags.Has_Protected_Type_Metadata);
      H := Hash_Boolean (H, Flags.Has_Access_Metadata);
      H := Hash_Boolean (H, Flags.Has_Access_All_Metadata);
      H := Hash_Boolean (H, Flags.Has_Access_Constant_Metadata);
      H := Hash_Boolean (H, Flags.Has_Class_Wide_Metadata);
      H := Hash_Boolean (H, Flags.Has_Access_Subprogram_Metadata);
      H := Hash_Boolean (H, Flags.Has_Access_Protected_Metadata);
      H := Hash_Boolean (H, Flags.Has_Array_Metadata);
      H := Hash_Boolean (H, Flags.Has_Derived_Metadata);
      H := Hash_Boolean (H, Flags.Has_Range_Metadata);
      H := Hash_Boolean (H, Flags.Has_Modular_Metadata);
      H := Hash_Boolean (H, Flags.Has_Digits_Metadata);
      H := Hash_Boolean (H, Flags.Has_Delta_Metadata);
      H := Hash_Boolean (H, Flags.Has_Variant_Record_Metadata);
      H := Hash_Boolean (H, Flags.Has_Default_Expression_Metadata);
      H := Hash_Boolean (H, Flags.Has_Entry_Family_Metadata);
      H := Hash_Boolean (H, Flags.Has_Incomplete_Type_Metadata);
      H := Hash_Boolean (H, Flags.Has_Profile_Mode_Metadata);
      H := Hash_Boolean (H, Flags.Has_Entry_Barrier_Metadata);
      H := Hash_Boolean (H, Flags.Has_Box_Metadata);
      H := Hash_Boolean (H, Flags.Has_Private_Extension_Metadata);
      H := Hash_Boolean (H, Flags.Has_Named_Number_Metadata);
      H := Hash_Boolean (H, Flags.Has_Deferred_Constant_Metadata);
      H := Hash_Boolean (H, Flags.Has_Null_Subprogram_Metadata);
      H := Hash_Boolean (H, Flags.Has_Expression_Function_Metadata);
      H := Hash_Boolean (H, Flags.Has_Null_Record_Metadata);
      H := Hash_Boolean (H, Flags.Has_Discriminant_Part_Metadata);
      H := Hash_Boolean (H, Flags.Has_Body_Stub_Metadata);
      H := Hash_Boolean (H, Flags.Has_Constraint_Metadata);
      H := Hash_Boolean (H, Flags.Has_Child_Unit_Metadata);
      H := Hash_Boolean (H, Flags.Has_Generic_Actual_Part_Metadata);
      return H;
   end Hash_Flags;

   procedure Clear (Analysis : in out Analysis_Result) is
   begin
      Analysis.Symbols.Clear;
      Analysis.Executable_Bindings.Clear;
      Analysis.Visibility_Clauses.Clear;
      Analysis.Generic_Actuals.Clear;
      Analysis.Profile_Parameters.Clear;
      Analysis.Generic_Formal_Types.Clear;
      Analysis.Pragmas.Clear;
      Analysis.Representation_Clauses.Clear;
      Analysis.Enumeration_Representation_Literals.Clear;
      Analysis.Representation_Components.Clear;
      Analysis.Freezing_Points.Clear;
      Analysis.Legality_Diagnostics.Clear;
      Analysis.Symbol_Overflow := False;
      Analysis.Generated_Source_Aware := False;
      Analysis.Conditional_Source_Aware := False;
      Analysis.With_Clause_Aware := False;
      Analysis.Use_Clause_Aware := False;
      Analysis.Statement_Aware := False;
      Analysis.Statement_Counts := (others => 0);
      Editor.Ada_Syntax_Tree.Clear (Analysis.Syntax_Tree_Value);
      Analysis.Syntax_Tree_Aware := False;
      Analysis.Result_Fingerprint := 0;
   end Clear;

   function Add_Symbol
     (Analysis           : in out Analysis_Result;
      Name               : String;
      Kind               : Symbol_Kind;
      Source_Span              : Source_Range;
      Declaration_Column : Positive := 1;
      Enclosing_Scope    : Scope_Id := Root_Scope;
      Parent_Symbol      : Symbol_Id := No_Symbol;
      Depth              : Natural := 0;
      Profile_Summary    : String := "";
      Flags              : Declaration_Flags := (others => False);
      Target_Name        : String := "") return Symbol_Id
   is
      Id : Symbol_Id;
      Normalized : constant String := Normalize_Name (Name);
      H : Natural := Analysis.Result_Fingerprint;
   begin
      if Name'Length = 0 then
         return No_Symbol;
      end if;

      if Natural (Analysis.Symbols.Length) >= Max_Analysis_Symbols then
         --  overflow is part of the analysis validity state.  Make
         --  the bounded-truncation transition visible through the same
         --  fingerprint used by the project index and stale semantic/outline
         --  consumers, even though no extra symbol row can be appended.
         if not Analysis.Symbol_Overflow then
            Analysis.Symbol_Overflow := True;
            Analysis.Result_Fingerprint :=
              Hash_Mix (Analysis.Result_Fingerprint, 142);
         end if;
         return No_Symbol;
      end if;

      Id := Symbol_Id (Natural (Analysis.Symbols.Length) + 1);
      H := Hash_Mix (H, (Natural (Symbol_Kind'Pos (Kind)), 1));
      H := Hash_String (H, Normalized);
      --  lookup remains Ada case-insensitive, but the analysis
      --  fingerprint also covers source spelling because Outline labels,
      --  target metadata, and cached semantic/outline rows preserve spelling.
      --  Two otherwise identical declarations that differ only by identifier
      --  case must not become cache-equivalent.
      H := Hash_String (H, Name);
      H := Hash_Mix
        (H,
         (Source_Span.Start_Line,
          Source_Span.Start_Column,
          Source_Span.End_Line,
          Source_Span.End_Column,
          Declaration_Column,
          Depth,
          1));
      --  symbol ownership is parser-owned metadata too.  The
      --  aggregate fingerprint must distinguish identical declarations that
      --  are retained under different lexical scopes or parent symbols,
      --  because outline hierarchy, scoped resolver lookup, and semantic
      --  colouring all consume those ownership stamps.
      H := Hash_Mix
        (H, (Natural (Enclosing_Scope), Natural (Parent_Symbol), 1));
      --  the initial symbol fingerprint must cover all parser-owned
      --  metadata that can affect outline rows, semantic classification, and
      --  stale-cache stamps.  Earlier stamps only covered the symbol kind,
      --  normalized name, start position, and depth; symbols inserted with a
      --  different end range, declaration column, flags, profile, or target
      --  could therefore look cache-equivalent until a later mutator touched
      --  them.
      H := Hash_String (H, Profile_Summary);
      H := Hash_String (H, Normalize_Name (Target_Name));
      H := Hash_String (H, Target_Name);
      H := Hash_Flags (H, Flags);
      Analysis.Result_Fingerprint := H;

      Analysis.Symbols.Append
        (Symbol_Info'(Id                 => Id,
          Name               => To_Unbounded_String (Name),
          Normalized_Name    => To_Unbounded_String (Normalized),
          Kind               => Kind,
          Source_Span              => Source_Span,
          Declaration_Line   => Source_Span.Start_Line,
          Declaration_Column => Declaration_Column,
          Enclosing_Scope    => Enclosing_Scope,
          Parent_Symbol      => Parent_Symbol,
          Depth              => Depth,
          Profile_Summary    => To_Unbounded_String (Profile_Summary),
          Flags              => Flags,
          Target_Name        => To_Unbounded_String (Target_Name),
          Fingerprint        => H));
      return Id;
   end Add_Symbol;

   procedure Set_Symbol_Kind
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id;
      Kind     : Symbol_Kind)
   is
      Info : Symbol_Info;
   begin
      if Id = No_Symbol
        or else Natural (Id) = 0
        or else Natural (Id) > Natural (Analysis.Symbols.Length)
      then
         return;
      end if;

      Info := Analysis.Symbols.Element (Positive (Id));
      if Info.Kind = Kind then
         return;
      end if;

      Info.Kind := Kind;
      Info.Fingerprint :=
        (Info.Fingerprint * 131 + Natural (Symbol_Kind'Pos (Kind)) + 1)
        mod 2_147_483_647;
      Analysis.Result_Fingerprint :=
        Hash_Mix (Analysis.Result_Fingerprint, Long_Long_Integer (Info.Fingerprint) + 1);
      Analysis.Symbols.Replace_Element (Positive (Id), Info);
   end Set_Symbol_Kind;


   procedure Set_Symbol_Target
     (Analysis    : in out Analysis_Result;
      Id          : Symbol_Id;
      Target_Name : String)
   is
      Info : Symbol_Info;
   begin
      if Id = No_Symbol
        or else Natural (Id) = 0
        or else Natural (Id) > Natural (Analysis.Symbols.Length)
      then
         return;
      end if;

      Info := Analysis.Symbols.Element (Positive (Id));
      if To_String (Info.Target_Name) = Target_Name then
         return;
      end if;

      Info.Target_Name := To_Unbounded_String (Target_Name);
      --  target spelling is displayed/propagated metadata.  Keep
      --  normalized target hashing for Ada lookup equivalence, but also hash
      --  the spelling actually retained by the model.
      Info.Fingerprint := Hash_String (Info.Fingerprint, Normalize_Name (Target_Name));
      Info.Fingerprint := Hash_String (Info.Fingerprint, Target_Name);
      Analysis.Result_Fingerprint :=
        Hash_Mix (Analysis.Result_Fingerprint, Long_Long_Integer (Info.Fingerprint) + 1);
      Analysis.Symbols.Replace_Element (Positive (Id), Info);
   end Set_Symbol_Target;


   procedure Set_Symbol_Profile
     (Analysis        : in out Analysis_Result;
      Id              : Symbol_Id;
      Profile_Summary : String)
   is
      Info : Symbol_Info;
   begin
      if Id = No_Symbol
        or else Natural (Id) = 0
        or else Natural (Id) > Natural (Analysis.Symbols.Length)
      then
         return;
      end if;

      Info := Analysis.Symbols.Element (Positive (Id));
      if To_String (Info.Profile_Summary) = Profile_Summary then
         return;
      end if;

      --  profile updates are part of the deterministic analysis
      --  stamp only when the stored profile actually changes.  Re-applying
      --  the same parser/refinement profile must be idempotent, otherwise
      --  parse-cache and project-index fingerprints can churn even though
      --  the language model is semantically unchanged.
      Info.Profile_Summary := To_Unbounded_String (Profile_Summary);
      Info.Fingerprint := Hash_String (Info.Fingerprint, Profile_Summary);
      Analysis.Result_Fingerprint :=
        Hash_Mix (Analysis.Result_Fingerprint, Long_Long_Integer (Info.Fingerprint) + 1);
      Analysis.Symbols.Replace_Element (Positive (Id), Info);
   end Set_Symbol_Profile;

   procedure Mark_Symbol_Instantiation
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id)
   is
      Info : Symbol_Info;
   begin
      if Id = No_Symbol
        or else Natural (Id) = 0
        or else Natural (Id) > Natural (Analysis.Symbols.Length)
      then
         return;
      end if;

      Info := Analysis.Symbols.Element (Positive (Id));
      if Info.Flags.Is_Instantiation then
         return;
      end if;

      Info.Flags.Is_Instantiation := True;
      Info.Fingerprint :=
        (Info.Fingerprint * 131 + 17) mod 2_147_483_647;
      Analysis.Result_Fingerprint :=
        Hash_Mix (Analysis.Result_Fingerprint, Long_Long_Integer (Info.Fingerprint) + 1);
      Analysis.Symbols.Replace_Element (Positive (Id), Info);
   end Mark_Symbol_Instantiation;



   procedure Mark_Symbol_Representation_Clause
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id)
   is
      Info : Symbol_Info;
   begin
      if Id = No_Symbol
        or else Natural (Id) = 0
        or else Natural (Id) > Natural (Analysis.Symbols.Length)
      then
         return;
      end if;

      Info := Analysis.Symbols.Element (Positive (Id));
      if Info.Flags.Has_Representation_Clause then
         return;
      end if;

      Info.Flags.Has_Representation_Clause := True;
      Info.Fingerprint :=
        (Info.Fingerprint * 131 + 579195) mod 2_147_483_647;
      Analysis.Result_Fingerprint :=
        Hash_Mix (Analysis.Result_Fingerprint, Long_Long_Integer (Info.Fingerprint) + 1);
      Analysis.Symbols.Replace_Element (Positive (Id), Info);
   end Mark_Symbol_Representation_Clause;



   procedure Mark_Symbol_Pragma_Metadata
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id)
   is
      Info : Symbol_Info;
   begin
      if Id = No_Symbol
        or else Natural (Id) = 0
        or else Natural (Id) > Natural (Analysis.Symbols.Length)
      then
         return;
      end if;

      Info := Analysis.Symbols.Element (Positive (Id));
      if Info.Flags.Has_Pragma_Metadata then
         return;
      end if;

      Info.Flags.Has_Pragma_Metadata := True;
      Info.Fingerprint :=
        (Info.Fingerprint * 131 + 579205) mod 2_147_483_647;
      Analysis.Result_Fingerprint :=
        Hash_Mix (Analysis.Result_Fingerprint, Long_Long_Integer (Info.Fingerprint) + 1);
      Analysis.Symbols.Replace_Element (Positive (Id), Info);
   end Mark_Symbol_Pragma_Metadata;




   procedure Mark_Symbol_Aspect_Specification
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id)
   is
      Info : Symbol_Info;
   begin
      if Id = No_Symbol
        or else Natural (Id) = 0
        or else Natural (Id) > Natural (Analysis.Symbols.Length)
      then
         return;
      end if;

      Info := Analysis.Symbols.Element (Positive (Id));
      if Info.Flags.Has_Aspect_Specification then
         return;
      end if;

      --  Split aspect clauses are declaration metadata just like same-line
      --  aspects.  Marking the owner through this mutator keeps semantic and
      --  outline fingerprints stable and avoids creating symbols for aspect
      --  identifiers or aspect expressions.
      Info.Flags.Has_Aspect_Specification := True;
      Info.Fingerprint :=
        (Info.Fingerprint * 131 + 579239) mod 2_147_483_647;
      Analysis.Result_Fingerprint :=
        Hash_Mix (Analysis.Result_Fingerprint, Long_Long_Integer (Info.Fingerprint) + 1);
      Analysis.Symbols.Replace_Element (Positive (Id), Info);
   end Mark_Symbol_Aspect_Specification;

   procedure Mark_Symbol_Access_Subprogram_Metadata
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id)
   is
      Info : Symbol_Info;
   begin
      if Id = No_Symbol
        or else Natural (Id) = 0
        or else Natural (Id) > Natural (Analysis.Symbols.Length)
      then
         return;
      end if;

      Info := Analysis.Symbols.Element (Positive (Id));
      if Info.Flags.Has_Access_Subprogram_Metadata then
         return;
      end if;

      Info.Flags.Has_Access_Subprogram_Metadata := True;
      Info.Fingerprint :=
        (Info.Fingerprint * 131 + 579214) mod 2_147_483_647;
      Analysis.Result_Fingerprint :=
        Hash_Mix (Analysis.Result_Fingerprint, Long_Long_Integer (Info.Fingerprint) + 1);
      Analysis.Symbols.Replace_Element (Positive (Id), Info);
   end Mark_Symbol_Access_Subprogram_Metadata;


   procedure Add_Generic_Actual
     (Analysis        : in out Analysis_Result;
      Instance_Symbol : Symbol_Id;
      Formal_Name     : String := "";
      Actual_Name     : String;
      Position        : Natural := 0;
      Source_Span           : Source_Range := (others => 1))
   is
      H : Natural := Analysis.Result_Fingerprint;
      Normal_Formal : constant String := Normalize_Name (Formal_Name);
      Normal_Actual : constant String := Normalize_Name (Actual_Name);
   begin
      if Instance_Symbol = No_Symbol or else Actual_Name'Length = 0 then
         return;
      end if;

      if Natural (Analysis.Generic_Actuals.Length) >= Max_Generic_Actuals then
         if not Analysis.Symbol_Overflow then
            Analysis.Symbol_Overflow := True;
            Analysis.Result_Fingerprint :=
              Hash_Mix (Analysis.Result_Fingerprint, 579367);
         end if;
         return;
      end if;

      H := Hash_Mix (H, (Natural (Instance_Symbol), Position, 579367));
      H := Hash_String (H, Formal_Name);
      H := Hash_String (H, Normal_Formal);
      H := Hash_String (H, Actual_Name);
      H := Hash_String (H, Normal_Actual);
      H := Hash_Mix
        (H,
         (Source_Span.Start_Line,
          Source_Span.Start_Column,
          Source_Span.End_Line,
          Source_Span.End_Column));

      Analysis.Generic_Actuals.Append
        (Generic_Actual_Info'(Instance_Symbol => Instance_Symbol,
          Formal_Name => To_Unbounded_String (Formal_Name),
          Normalized_Formal_Name => To_Unbounded_String (Normal_Formal),
          Actual_Name => To_Unbounded_String (Actual_Name),
          Normalized_Actual_Name => To_Unbounded_String (Normal_Actual),
          Position => Position,
          Source_Span => Source_Span,
          Fingerprint => H));
      Analysis.Result_Fingerprint := H;
   end Add_Generic_Actual;


   function Generic_Actual_Count
     (Analysis        : Analysis_Result;
      Instance_Symbol : Symbol_Id := No_Symbol) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Generic_Actuals loop
         if Instance_Symbol = No_Symbol or else Info.Instance_Symbol = Instance_Symbol then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Generic_Actual_Count;


   function Generic_Actual_At
     (Analysis        : Analysis_Result;
      Instance_Symbol : Symbol_Id;
      Index           : Positive) return Generic_Actual_Info
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Generic_Actuals loop
         if Instance_Symbol = No_Symbol or else Info.Instance_Symbol = Instance_Symbol then
            Count := Count + 1;
            if Count = Index then
               return Info;
            end if;
         end if;
      end loop;

      return (Instance_Symbol => No_Symbol,
              Formal_Name => Null_Unbounded_String,
              Normalized_Formal_Name => Null_Unbounded_String,
              Actual_Name => Null_Unbounded_String,
              Normalized_Actual_Name => Null_Unbounded_String,
              Position => 0,
              Source_Span => (1, 1, 1, 1),
              Fingerprint => 0);
   end Generic_Actual_At;


   procedure Add_Profile_Parameter_Metadata
     (Analysis                      : in out Analysis_Result;
      Owner_Symbol                  : Symbol_Id;
      Parameter_Symbol              : Symbol_Id;
      Name                          : String;
      Mode                          : Profile_Parameter_Mode;
      Type_Text                     : String := "";
      Has_Aliased                   : Boolean := False;
      Has_Access_Definition         : Boolean := False;
      Has_Access_Subprogram_Profile : Boolean := False;
      Has_Default_Expression        : Boolean := False;
      Default_Text                  : String := "";
      Group_Index                   : Natural := 0;
      Group_Position                : Natural := 0;
      Group_Name_Count              : Natural := 0;
      Source_Span                         : Source_Range := (others => 1))
   is
      Info : Profile_Parameter_Info;
      H    : Natural := Analysis.Result_Fingerprint;
   begin
      if Name'Length = 0 then
         return;
      end if;

      if (Owner_Symbol /= No_Symbol
          and then Natural (Owner_Symbol) > Natural (Analysis.Symbols.Length))
        or else (Parameter_Symbol /= No_Symbol
                 and then Natural (Parameter_Symbol) > Natural (Analysis.Symbols.Length))
      then
         return;
      end if;

      if Natural (Analysis.Profile_Parameters.Length) >= Max_Profile_Parameters then
         if not Analysis.Symbol_Overflow then
            Analysis.Symbol_Overflow := True;
            Analysis.Result_Fingerprint :=
              (Analysis.Result_Fingerprint * 131 + 579744) mod 2_147_483_647;
         end if;
         return;
      end if;

      Info.Owner_Symbol := Owner_Symbol;
      Info.Parameter_Symbol := Parameter_Symbol;
      Info.Name := To_Unbounded_String (Name);
      Info.Normalized_Name := To_Unbounded_String (Normalize_Name (Name));
      Info.Mode := Mode;
      Info.Type_Text := To_Unbounded_String (Type_Text);
      Info.Normalized_Type_Text := To_Unbounded_String (Normalize_Name (Type_Text));
      Info.Has_Aliased := Has_Aliased;
      Info.Has_Access_Definition := Has_Access_Definition;
      Info.Has_Access_Subprogram_Profile := Has_Access_Subprogram_Profile;
      Info.Has_Default_Expression := Has_Default_Expression;
      Info.Default_Text := To_Unbounded_String (Default_Text);
      Info.Group_Index := Group_Index;
      Info.Group_Position := Group_Position;
      Info.Group_Name_Count := Group_Name_Count;
      Info.Source_Span := Source_Span;

      H := (H * 131 + Natural (Owner_Symbol) + Natural (Parameter_Symbol)
            + Natural (Profile_Parameter_Mode'Pos (Mode)) + Group_Index
            + Group_Position + Group_Name_Count + 579744) mod 2_147_483_647;
      H := Hash_String (H, Name);
      H := Hash_String (H, Normalize_Name (Name));
      H := Hash_String (H, Type_Text);
      H := Hash_String (H, Normalize_Name (Type_Text));
      H := Hash_Boolean (H, Has_Aliased);
      H := Hash_Boolean (H, Has_Access_Definition);
      H := Hash_Boolean (H, Has_Access_Subprogram_Profile);
      H := Hash_Boolean (H, Has_Default_Expression);
      H := Hash_String (H, Default_Text);
      H := (H * 131 + Source_Span.Start_Line + Source_Span.Start_Column + Source_Span.End_Line
            + Source_Span.End_Column) mod 2_147_483_647;
      Info.Fingerprint := H;

      Analysis.Profile_Parameters.Append (Info);
      Analysis.Result_Fingerprint := H;
   end Add_Profile_Parameter_Metadata;


   function Profile_Parameter_Count
     (Analysis     : Analysis_Result;
      Owner_Symbol : Symbol_Id := No_Symbol) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Profile_Parameters loop
         if Owner_Symbol = No_Symbol or else Info.Owner_Symbol = Owner_Symbol then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Profile_Parameter_Count;


   function Profile_Parameter_At
     (Analysis     : Analysis_Result;
      Owner_Symbol : Symbol_Id;
      Index        : Positive) return Profile_Parameter_Info
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Profile_Parameters loop
         if Owner_Symbol = No_Symbol or else Info.Owner_Symbol = Owner_Symbol then
            Count := Count + 1;
            if Count = Index then
               return Info;
            end if;
         end if;
      end loop;

      return (Owner_Symbol => No_Symbol,
              Parameter_Symbol => No_Symbol,
              Name => Null_Unbounded_String,
              Normalized_Name => Null_Unbounded_String,
              Mode => Profile_Parameter_Default_In,
              Type_Text => Null_Unbounded_String,
              Normalized_Type_Text => Null_Unbounded_String,
              Has_Aliased => False,
              Has_Access_Definition => False,
              Has_Access_Subprogram_Profile => False,
              Has_Default_Expression => False,
              Default_Text => Null_Unbounded_String,
              Group_Index => 0,
              Group_Position => 0,
              Group_Name_Count => 0,
              Source_Span => (1, 1, 1, 1),
              Fingerprint => 0);
   end Profile_Parameter_At;


   procedure Add_Generic_Formal_Type_Metadata
     (Analysis                  : in out Analysis_Result;
      Formal_Symbol             : Symbol_Id;
      Name                      : String;
      Family                    : Generic_Formal_Type_Family;
      Target_Type_Text          : String := "";
      Profile_Text              : String := "";
      Has_Private               : Boolean := False;
      Has_Limited               : Boolean := False;
      Has_Tagged                : Boolean := False;
      Has_Abstract              : Boolean := False;
      Has_Synchronized          : Boolean := False;
      Has_Interface             : Boolean := False;
      Has_Box                   : Boolean := False;
      Has_Discriminant_Part     : Boolean := False;
      Source_Span                     : Source_Range := (others => 1))
   is
      Info : Generic_Formal_Type_Info;
      H    : Natural := Analysis.Result_Fingerprint;
   begin
      if Name'Length = 0 then
         return;
      end if;

      if Formal_Symbol /= No_Symbol
        and then Natural (Formal_Symbol) > Natural (Analysis.Symbols.Length)
      then
         return;
      end if;

      if Natural (Analysis.Generic_Formal_Types.Length) >= Max_Generic_Formal_Types then
         if not Analysis.Symbol_Overflow then
            Analysis.Symbol_Overflow := True;
            Analysis.Result_Fingerprint :=
              (Analysis.Result_Fingerprint * 131 + 579745) mod 2_147_483_647;
         end if;
         return;
      end if;

      Info.Formal_Symbol := Formal_Symbol;
      Info.Name := To_Unbounded_String (Name);
      Info.Normalized_Name := To_Unbounded_String (Normalize_Name (Name));
      Info.Family := Family;
      Info.Target_Type_Text := To_Unbounded_String (Target_Type_Text);
      Info.Normalized_Target_Type_Text :=
        To_Unbounded_String (Normalize_Name (Target_Type_Text));
      Info.Profile_Text := To_Unbounded_String (Profile_Text);
      Info.Has_Private := Has_Private;
      Info.Has_Limited := Has_Limited;
      Info.Has_Tagged := Has_Tagged;
      Info.Has_Abstract := Has_Abstract;
      Info.Has_Synchronized := Has_Synchronized;
      Info.Has_Interface := Has_Interface;
      Info.Has_Box := Has_Box;
      Info.Has_Discriminant_Part := Has_Discriminant_Part;
      Info.Source_Span := Source_Span;

      H := (H * 131 + Natural (Formal_Symbol)
            + Natural (Generic_Formal_Type_Family'Pos (Family)) + 579745)
        mod 2_147_483_647;
      H := Hash_String (H, Name);
      H := Hash_String (H, Normalize_Name (Name));
      H := Hash_String (H, Target_Type_Text);
      H := Hash_String (H, Normalize_Name (Target_Type_Text));
      H := Hash_String (H, Profile_Text);
      H := Hash_Boolean (H, Has_Private);
      H := Hash_Boolean (H, Has_Limited);
      H := Hash_Boolean (H, Has_Tagged);
      H := Hash_Boolean (H, Has_Abstract);
      H := Hash_Boolean (H, Has_Synchronized);
      H := Hash_Boolean (H, Has_Interface);
      H := Hash_Boolean (H, Has_Box);
      H := Hash_Boolean (H, Has_Discriminant_Part);
      H := (H * 131 + Source_Span.Start_Line + Source_Span.Start_Column
            + Source_Span.End_Line + Source_Span.End_Column) mod 2_147_483_647;
      Info.Fingerprint := H;

      Analysis.Generic_Formal_Types.Append (Info);
      Analysis.Result_Fingerprint := H;
   end Add_Generic_Formal_Type_Metadata;


   function Generic_Formal_Type_Metadata_Count
     (Analysis      : Analysis_Result;
      Formal_Symbol : Symbol_Id := No_Symbol) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Generic_Formal_Types loop
         if Formal_Symbol = No_Symbol or else Info.Formal_Symbol = Formal_Symbol then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Generic_Formal_Type_Metadata_Count;


   function Generic_Formal_Type_Metadata_At
     (Analysis      : Analysis_Result;
      Formal_Symbol : Symbol_Id;
      Index         : Positive) return Generic_Formal_Type_Info
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Generic_Formal_Types loop
         if Formal_Symbol = No_Symbol or else Info.Formal_Symbol = Formal_Symbol then
            Count := Count + 1;
            if Count = Index then
               return Info;
            end if;
         end if;
      end loop;

      return (Formal_Symbol => No_Symbol,
              Name => Null_Unbounded_String,
              Normalized_Name => Null_Unbounded_String,
              Family => Generic_Formal_Type_Unknown,
              Target_Type_Text => Null_Unbounded_String,
              Normalized_Target_Type_Text => Null_Unbounded_String,
              Profile_Text => Null_Unbounded_String,
              Has_Private => False,
              Has_Limited => False,
              Has_Tagged => False,
              Has_Abstract => False,
              Has_Synchronized => False,
              Has_Interface => False,
              Has_Box => False,
              Has_Discriminant_Part => False,
              Source_Span => (1, 1, 1, 1),
              Fingerprint => 0);
   end Generic_Formal_Type_Metadata_At;



   procedure Add_Representation_Clause
     (Analysis          : in out Analysis_Result;
      Target_Symbol     : Symbol_Id := No_Symbol;
      Target_Name       : String;
      Kind              : Representation_Clause_Kind;
      Attribute_Name    : String := "";
      Item_Text         : String;
      Source_Form       : Representation_Source_Form :=
        Representation_Source_Attribute_Definition;
      Has_Static_Value  : Boolean := False;
      Static_Value      : Natural := 0;
      Source_Span             : Source_Range)
   is
      Info : Representation_Clause_Info;
      Flags : Declaration_Flags := (others => False);
      H : Natural := Analysis.Result_Fingerprint;
   begin
      if Target_Symbol = No_Symbol and then Target_Name'Length = 0 then
         return;
      end if;

      if Target_Symbol /= No_Symbol
        and then Natural (Target_Symbol) > Natural (Analysis.Symbols.Length)
      then
         return;
      end if;

      if Natural (Analysis.Representation_Clauses.Length) >= Max_Representation_Clauses then
         if not Analysis.Symbol_Overflow then
            Analysis.Symbol_Overflow := True;
            Analysis.Result_Fingerprint :=
              (Analysis.Result_Fingerprint * 131 + 579371) mod 2_147_483_647;
         end if;
         return;
      end if;

      Info.Target_Symbol := Target_Symbol;
      Info.Target_Name := To_Unbounded_String (Target_Name);
      Info.Normalized_Target_Name := To_Unbounded_String (Normalize_Name (Target_Name));
      Info.Kind := Kind;
      Info.Attribute_Name := To_Unbounded_String (Attribute_Name);
      Info.Item_Text := To_Unbounded_String (Item_Text);
      Info.Source_Form := Source_Form;
      Info.Has_Static_Value := Has_Static_Value;
      Info.Static_Value := Static_Value;
      Info.Source_Span := Source_Span;

      H := Hash_String (H, Target_Name);
      H := Hash_String (H, Attribute_Name);
      H := Hash_String (H, Item_Text);
      H := (H * 131 + Natural (Target_Symbol) + Representation_Clause_Kind'Pos (Kind) + 579372)
        mod 2_147_483_647;
      H := (H * 131 + Representation_Source_Form'Pos (Source_Form) + 579377)
        mod 2_147_483_647;
      if Has_Static_Value then
         H := (H * 131 + Static_Value + 23) mod 2_147_483_647;
      end if;
      Info.Fingerprint := H;

      Analysis.Representation_Clauses.Append (Info);
      Flags.Has_Representation_Clause := True;
      if Target_Symbol /= No_Symbol then
         Merge_Symbol_Flags (Analysis, Target_Symbol, Flags);
      end if;
      Analysis.Result_Fingerprint :=
        (Analysis.Result_Fingerprint * 131 + H + 579373) mod 2_147_483_647;
   end Add_Representation_Clause;


   function Representation_Clause_Count
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id := No_Symbol) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Representation_Clauses loop
         if Target_Symbol = No_Symbol or else Info.Target_Symbol = Target_Symbol then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Representation_Clause_Count;


   function Representation_Clause_At
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id;
      Index         : Positive) return Representation_Clause_Info
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Representation_Clauses loop
         if Target_Symbol = No_Symbol or else Info.Target_Symbol = Target_Symbol then
            Count := Count + 1;
            if Count = Index then
               return Info;
            end if;
         end if;
      end loop;

      return (Target_Symbol => No_Symbol,
              Target_Name => Null_Unbounded_String,
              Normalized_Target_Name => Null_Unbounded_String,
              Kind => Representation_Other_Clause,
              Attribute_Name => Null_Unbounded_String,
              Item_Text => Null_Unbounded_String,
              Source_Form => Representation_Source_Attribute_Definition,
              Has_Static_Value => False,
              Static_Value => 0,
              Source_Span => (1, 1, 1, 1),
              Fingerprint => 0);
   end Representation_Clause_At;


   procedure Add_Enumeration_Representation_Literal
     (Analysis         : in out Analysis_Result;
      Target_Symbol    : Symbol_Id;
      Literal_Symbol   : Symbol_Id := No_Symbol;
      Literal_Name     : String;
      Value_Text       : String;
      Has_Static_Value : Boolean := False;
      Static_Value     : Natural := 0;
      Source_Span            : Source_Range)
   is
      Info : Enumeration_Representation_Literal_Info;
      Flags : Declaration_Flags := (others => False);
      H : Natural := Analysis.Result_Fingerprint;
   begin
      if Target_Symbol = No_Symbol or else Literal_Name'Length = 0 then
         return;
      end if;

      if Natural (Target_Symbol) > Natural (Analysis.Symbols.Length) then
         return;
      end if;

      if Natural (Analysis.Enumeration_Representation_Literals.Length) >= Max_Enumeration_Representation_Literals then
         if not Analysis.Symbol_Overflow then
            Analysis.Symbol_Overflow := True;
            Analysis.Result_Fingerprint :=
              (Analysis.Result_Fingerprint * 131 + 579374) mod 2_147_483_647;
         end if;
         return;
      end if;

      Info.Target_Symbol := Target_Symbol;
      Info.Literal_Symbol := Literal_Symbol;
      Info.Literal_Name := To_Unbounded_String (Literal_Name);
      Info.Value_Text := To_Unbounded_String (Value_Text);
      Info.Has_Static_Value := Has_Static_Value;
      Info.Static_Value := Static_Value;
      Info.Source_Span := Source_Span;

      H := Hash_String (H, Literal_Name);
      H := Hash_String (H, Value_Text);
      H := (H * 131 + Natural (Target_Symbol) + Natural (Literal_Symbol) + 579375)
        mod 2_147_483_647;
      if Has_Static_Value then
         H := (H * 131 + Static_Value + 29) mod 2_147_483_647;
      end if;
      Info.Fingerprint := H;

      Analysis.Enumeration_Representation_Literals.Append (Info);
      Flags.Has_Representation_Clause := True;
      Merge_Symbol_Flags (Analysis, Target_Symbol, Flags);
      if Literal_Symbol /= No_Symbol then
         Merge_Symbol_Flags (Analysis, Literal_Symbol, Flags);
      end if;
      Analysis.Result_Fingerprint :=
        (Analysis.Result_Fingerprint * 131 + H + 579376) mod 2_147_483_647;
   end Add_Enumeration_Representation_Literal;


   function Enumeration_Representation_Literal_Count
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id := No_Symbol) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Enumeration_Representation_Literals loop
         if Target_Symbol = No_Symbol or else Info.Target_Symbol = Target_Symbol then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Enumeration_Representation_Literal_Count;


   function Enumeration_Representation_Literal_At
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id;
      Index         : Positive) return Enumeration_Representation_Literal_Info
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Enumeration_Representation_Literals loop
         if Target_Symbol = No_Symbol or else Info.Target_Symbol = Target_Symbol then
            Count := Count + 1;
            if Count = Index then
               return Info;
            end if;
         end if;
      end loop;

      return (Target_Symbol => No_Symbol,
              Literal_Symbol => No_Symbol,
              Literal_Name => Null_Unbounded_String,
              Value_Text => Null_Unbounded_String,
              Has_Static_Value => False,
              Static_Value => 0,
              Source_Span => (1, 1, 1, 1),
              Fingerprint => 0);
   end Enumeration_Representation_Literal_At;

   procedure Add_Record_Representation_Component
     (Analysis          : in out Analysis_Result;
      Target_Symbol     : Symbol_Id;
      Component_Symbol  : Symbol_Id := No_Symbol;
      Component_Name    : String;
      Storage_Unit_Text : String;
      First_Bit_Text    : String;
      Last_Bit_Text     : String;
      Source_Form       : Representation_Source_Form :=
        Representation_Source_Record_Component_Clause;
      Has_Static_Storage_Unit : Boolean := False;
      Static_Storage_Unit     : Natural := 0;
      Has_Static_First_Bit    : Boolean := False;
      Static_First_Bit        : Natural := 0;
      Has_Static_Last_Bit     : Boolean := False;
      Static_Last_Bit         : Natural := 0;
      Source_Span             : Source_Range)
   is
      Info : Representation_Component_Info;
      Flags : Declaration_Flags := (others => False);
      H : Natural := Analysis.Result_Fingerprint;
   begin
      if Target_Symbol = No_Symbol or else Component_Name'Length = 0 then
         return;
      end if;

      if Natural (Target_Symbol) > Natural (Analysis.Symbols.Length) then
         return;
      end if;

      if Natural (Analysis.Representation_Components.Length) >= Max_Representation_Components then
         --  Record layout metadata is analysis-owned and bounded just like
         --  symbols.  Overflow is exposed through the existing analysis
         --  overflow/fingerprint state so semantic and outline users can
         --  degrade deterministically instead of retaining unbounded layout
         --  rows from very large generated specs.
         if not Analysis.Symbol_Overflow then
            Analysis.Symbol_Overflow := True;
            Analysis.Result_Fingerprint :=
              (Analysis.Result_Fingerprint * 131 + 579360) mod 2_147_483_647;
         end if;
         return;
      end if;

      Info.Target_Symbol := Target_Symbol;
      Info.Component_Symbol := Component_Symbol;
      Info.Component_Name := To_Unbounded_String (Component_Name);
      Info.Storage_Unit_Text := To_Unbounded_String (Storage_Unit_Text);
      Info.First_Bit_Text := To_Unbounded_String (First_Bit_Text);
      Info.Last_Bit_Text := To_Unbounded_String (Last_Bit_Text);
      Info.Source_Form := Source_Form;
      Info.Has_Static_Storage_Unit := Has_Static_Storage_Unit;
      Info.Static_Storage_Unit := Static_Storage_Unit;
      Info.Has_Static_First_Bit := Has_Static_First_Bit;
      Info.Static_First_Bit := Static_First_Bit;
      Info.Has_Static_Last_Bit := Has_Static_Last_Bit;
      Info.Static_Last_Bit := Static_Last_Bit;
      Info.Source_Span := Source_Span;

      H := Hash_String (H, Component_Name);
      H := Hash_String (H, Storage_Unit_Text);
      H := Hash_String (H, First_Bit_Text);
      H := Hash_String (H, Last_Bit_Text);
      H := (H * 131 + Natural (Target_Symbol) + Natural (Component_Symbol) + 579351)
        mod 2_147_483_647;
      H := (H * 131 + Representation_Source_Form'Pos (Source_Form) + 579353)
        mod 2_147_483_647;
      if Has_Static_Storage_Unit then
         H := (H * 131 + Static_Storage_Unit + 11) mod 2_147_483_647;
      end if;
      if Has_Static_First_Bit then
         H := (H * 131 + Static_First_Bit + 13) mod 2_147_483_647;
      end if;
      if Has_Static_Last_Bit then
         H := (H * 131 + Static_Last_Bit + 17) mod 2_147_483_647;
      end if;
      Info.Fingerprint := H;

      Analysis.Representation_Components.Append (Info);
      Flags.Has_Representation_Clause := True;
      Merge_Symbol_Flags (Analysis, Target_Symbol, Flags);
      if Component_Symbol /= No_Symbol then
         Merge_Symbol_Flags (Analysis, Component_Symbol, Flags);
      end if;
      Analysis.Result_Fingerprint :=
        (Analysis.Result_Fingerprint * 131 + H + 579352) mod 2_147_483_647;
   end Add_Record_Representation_Component;


   function Representation_Component_Count
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id := No_Symbol) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Representation_Components loop
         if Target_Symbol = No_Symbol or else Info.Target_Symbol = Target_Symbol then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Representation_Component_Count;


   function Representation_Component_At
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id;
      Index         : Positive) return Representation_Component_Info
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Representation_Components loop
         if Target_Symbol = No_Symbol or else Info.Target_Symbol = Target_Symbol then
            Count := Count + 1;
            if Count = Index then
               return Info;
            end if;
         end if;
      end loop;

      return (Target_Symbol => No_Symbol,
              Component_Symbol => No_Symbol,
              Component_Name => Null_Unbounded_String,
              Storage_Unit_Text => Null_Unbounded_String,
              First_Bit_Text => Null_Unbounded_String,
              Last_Bit_Text => Null_Unbounded_String,
              Source_Form => Representation_Source_Record_Component_Clause,
              Has_Static_Storage_Unit => False,
              Static_Storage_Unit => 0,
              Has_Static_First_Bit => False,
              Static_First_Bit => 0,
              Has_Static_Last_Bit => False,
              Static_Last_Bit => 0,
              Source_Span => (1, 1, 1, 1),
              Fingerprint => 0);
   end Representation_Component_At;



   procedure Add_Freezing_Point
     (Analysis       : in out Analysis_Result;
      Target_Symbol  : Symbol_Id;
      Trigger_Symbol : Symbol_Id;
      Kind           : Freezing_Point_Kind;
      Reason         : String;
      Source_Span          : Source_Range)
   is
      Info : Freezing_Point_Info;
      H    : Natural := Analysis.Result_Fingerprint;
   begin
      if Target_Symbol = No_Symbol or else Reason'Length = 0 then
         return;
      end if;

      if Natural (Analysis.Freezing_Points.Length) >= Max_Freezing_Points then
         if not Analysis.Symbol_Overflow then
            Analysis.Symbol_Overflow := True;
            Analysis.Result_Fingerprint :=
              (Analysis.Result_Fingerprint * 131 + 579458) mod 2_147_483_647;
         end if;
         return;
      end if;

      --  Avoid recording the same bounded freezing trigger more than once;
      --  diagnostics may inspect multiple representation clauses for one
      --  target.
      for Existing of Analysis.Freezing_Points loop
         if Existing.Target_Symbol = Target_Symbol
           and then Existing.Trigger_Symbol = Trigger_Symbol
           and then Existing.Kind = Kind
           and then Existing.Source_Span.Start_Line = Source_Span.Start_Line
         then
            return;
         end if;
      end loop;

      Info.Target_Symbol := Target_Symbol;
      Info.Trigger_Symbol := Trigger_Symbol;
      Info.Kind := Kind;
      Info.Reason := To_Unbounded_String (Reason);
      Info.Source_Span := Source_Span;
      H := (H * 131 + Natural (Target_Symbol) + Natural (Trigger_Symbol) + 579459)
        mod 2_147_483_647;
      H := (H * 131 + Natural (Freezing_Point_Kind'Pos (Kind)) + 7)
        mod 2_147_483_647;
      H := Hash_String (H, Reason);
      Info.Fingerprint := H;
      Analysis.Freezing_Points.Append (Info);
      Analysis.Result_Fingerprint :=
        (Analysis.Result_Fingerprint * 131 + H + 579460) mod 2_147_483_647;
   end Add_Freezing_Point;


   function Freezing_Point_Count
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id := No_Symbol) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Freezing_Points loop
         if Target_Symbol = No_Symbol or else Info.Target_Symbol = Target_Symbol then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Freezing_Point_Count;


   function Freezing_Point_At
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id;
      Index         : Positive) return Freezing_Point_Info
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Freezing_Points loop
         if Target_Symbol = No_Symbol or else Info.Target_Symbol = Target_Symbol then
            Count := Count + 1;
            if Count = Index then
               return Info;
            end if;
         end if;
      end loop;

      return (Target_Symbol => No_Symbol,
              Trigger_Symbol => No_Symbol,
              Kind => Freezing_First_Use,
              Reason => Null_Unbounded_String,
              Source_Span => (1, 1, 1, 1),
              Fingerprint => 0);
   end Freezing_Point_At;


   procedure Add_Legality_Diagnostic
     (Analysis       : in out Analysis_Result;
      Kind           : Legality_Diagnostic_Kind;
      Message        : String;
      Severity       : Legality_Diagnostic_Severity := Legality_Error;
      Primary_Symbol : Symbol_Id := No_Symbol;
      Related_Symbol : Symbol_Id := No_Symbol;
      Source_Span          : Source_Range := (others => 1))
   is
      Info : Legality_Diagnostic_Info;
      H    : Natural := Analysis.Result_Fingerprint;
   begin
      if Message'Length = 0 then
         return;
      end if;

      if Natural (Analysis.Legality_Diagnostics.Length) >= Max_Legality_Diagnostics then
         if not Analysis.Symbol_Overflow then
            Analysis.Symbol_Overflow := True;
            Analysis.Result_Fingerprint :=
              (Analysis.Result_Fingerprint * 131 + 579456) mod 2_147_483_647;
         end if;
         return;
      end if;

      Info.Kind := Kind;
      Info.Severity := Severity;
      Info.Primary_Symbol := Primary_Symbol;
      Info.Related_Symbol := Related_Symbol;
      if Primary_Symbol /= No_Symbol
        and then Natural (Primary_Symbol) <= Natural (Analysis.Symbols.Length)
      then
         Info.Target_Name :=
           Analysis.Symbols.Element (Positive (Primary_Symbol)).Name;
      end if;
      Info.Message := To_Unbounded_String (Message);
      Info.Source_Span := Source_Span;

      H := (H * 131 + Natural (Legality_Diagnostic_Kind'Pos (Kind)) + 1)
        mod 2_147_483_647;
      H := (H * 131 + Natural (Legality_Diagnostic_Severity'Pos (Severity)) + 3)
        mod 2_147_483_647;
      H := (H * 131 + Natural (Primary_Symbol) + Natural (Related_Symbol) + 5)
        mod 2_147_483_647;
      H := Hash_String (H, Message);
      Info.Fingerprint := H;

      Analysis.Legality_Diagnostics.Append (Info);
      Analysis.Result_Fingerprint :=
        (Analysis.Result_Fingerprint * 131 + H + 579457) mod 2_147_483_647;
   end Add_Legality_Diagnostic;


   function Legality_Diagnostic_Count
     (Analysis : Analysis_Result;
      Severity : Legality_Diagnostic_Severity := Legality_Error) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Legality_Diagnostics loop
         if Info.Severity = Severity then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Legality_Diagnostic_Count;


   function Legality_Diagnostic_At
     (Analysis : Analysis_Result;
      Index    : Positive) return Legality_Diagnostic_Info
   is
   begin
      if Natural (Analysis.Legality_Diagnostics.Length) > 0
        and then Index <= Positive (Analysis.Legality_Diagnostics.Length)
      then
         return Analysis.Legality_Diagnostics.Element (Index);
      end if;

      return (Kind => Legality_Duplicate_Declaration,
              Severity => Legality_Error,
              Primary_Symbol => No_Symbol,
              Related_Symbol => No_Symbol,
              Target_Name => Null_Unbounded_String,
              Message => Null_Unbounded_String,
              Source_Span => (1, 1, 1, 1),
              Fingerprint => 0);
   end Legality_Diagnostic_At;


   function Has_Legality_Diagnostics
     (Analysis : Analysis_Result;
      Severity : Legality_Diagnostic_Severity := Legality_Error) return Boolean
   is
   begin
      return Legality_Diagnostic_Count (Analysis, Severity) > 0;
   end Has_Legality_Diagnostics;


   function Diagnostic_Count
     (Analysis : Analysis_Result;
      Severity : Legality_Diagnostic_Severity := Legality_Error) return Natural is
   begin
      return Legality_Diagnostic_Count (Analysis, Severity);
   end Diagnostic_Count;


   function Diagnostic_At
     (Analysis : Analysis_Result;
      Index    : Positive) return Diagnostic_Info is
   begin
      return Legality_Diagnostic_At (Analysis, Index);
   end Diagnostic_At;


   procedure Merge_Symbol_Flags
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id;
      Flags    : Declaration_Flags)
   is
      Info    : Symbol_Info;
      Changed : Boolean := False;

      procedure Merge (Target : in out Boolean; Source : Boolean) is
      begin
         if Source and then not Target then
            Target := True;
            Changed := True;
         end if;
      end Merge;
   begin
      if Id = No_Symbol
        or else Natural (Id) = 0
        or else Natural (Id) > Natural (Analysis.Symbols.Length)
      then
         return;
      end if;

      Info := Analysis.Symbols.Element (Positive (Id));

      Merge (Info.Flags.Is_Private, Flags.Is_Private);
      Merge (Info.Flags.Is_Abstract, Flags.Is_Abstract);
      Merge (Info.Flags.Is_Overriding, Flags.Is_Overriding);
      Merge (Info.Flags.Is_Not_Overriding, Flags.Is_Not_Overriding);
      Merge (Info.Flags.Is_Generic, Flags.Is_Generic);
      Merge (Info.Flags.Is_Rename, Flags.Is_Rename);
      Merge (Info.Flags.Is_Instantiation, Flags.Is_Instantiation);
      Merge (Info.Flags.Is_Separate, Flags.Is_Separate);
      Merge (Info.Flags.Is_Body, Flags.Is_Body);
      Merge (Info.Flags.Has_Representation_Clause, Flags.Has_Representation_Clause);
      Merge (Info.Flags.Has_Aspect_Specification, Flags.Has_Aspect_Specification);
      Merge (Info.Flags.Has_Pragma_Metadata, Flags.Has_Pragma_Metadata);
      Merge (Info.Flags.Has_Null_Exclusion, Flags.Has_Null_Exclusion);
      Merge (Info.Flags.Has_Aliased_Metadata, Flags.Has_Aliased_Metadata);
      Merge (Info.Flags.Has_Limited_Metadata, Flags.Has_Limited_Metadata);
      Merge (Info.Flags.Has_Tagged_Metadata, Flags.Has_Tagged_Metadata);
      Merge (Info.Flags.Has_Interface_Metadata, Flags.Has_Interface_Metadata);
      Merge (Info.Flags.Has_Synchronized_Metadata, Flags.Has_Synchronized_Metadata);
      Merge (Info.Flags.Has_Task_Interface_Metadata, Flags.Has_Task_Interface_Metadata);
      Merge (Info.Flags.Has_Protected_Interface_Metadata, Flags.Has_Protected_Interface_Metadata);
      Merge (Info.Flags.Has_Task_Type_Metadata, Flags.Has_Task_Type_Metadata);
      Merge (Info.Flags.Has_Protected_Type_Metadata, Flags.Has_Protected_Type_Metadata);
      Merge (Info.Flags.Has_Access_Metadata, Flags.Has_Access_Metadata);
      Merge (Info.Flags.Has_Access_All_Metadata, Flags.Has_Access_All_Metadata);
      Merge (Info.Flags.Has_Access_Constant_Metadata, Flags.Has_Access_Constant_Metadata);
      Merge (Info.Flags.Has_Class_Wide_Metadata, Flags.Has_Class_Wide_Metadata);
      Merge (Info.Flags.Has_Access_Subprogram_Metadata, Flags.Has_Access_Subprogram_Metadata);
      Merge (Info.Flags.Has_Access_Protected_Metadata, Flags.Has_Access_Protected_Metadata);
      Merge (Info.Flags.Has_Array_Metadata, Flags.Has_Array_Metadata);
      Merge (Info.Flags.Has_Derived_Metadata, Flags.Has_Derived_Metadata);
      Merge (Info.Flags.Has_Range_Metadata, Flags.Has_Range_Metadata);
      Merge (Info.Flags.Has_Modular_Metadata, Flags.Has_Modular_Metadata);
      Merge (Info.Flags.Has_Digits_Metadata, Flags.Has_Digits_Metadata);
      Merge (Info.Flags.Has_Delta_Metadata, Flags.Has_Delta_Metadata);
      Merge (Info.Flags.Has_Variant_Record_Metadata, Flags.Has_Variant_Record_Metadata);
      Merge (Info.Flags.Has_Default_Expression_Metadata, Flags.Has_Default_Expression_Metadata);
      Merge (Info.Flags.Has_Entry_Family_Metadata, Flags.Has_Entry_Family_Metadata);
      Merge (Info.Flags.Has_Incomplete_Type_Metadata, Flags.Has_Incomplete_Type_Metadata);
      Merge (Info.Flags.Has_Profile_Mode_Metadata, Flags.Has_Profile_Mode_Metadata);
      Merge (Info.Flags.Has_Entry_Barrier_Metadata, Flags.Has_Entry_Barrier_Metadata);
      Merge (Info.Flags.Has_Box_Metadata, Flags.Has_Box_Metadata);
      Merge (Info.Flags.Has_Private_Extension_Metadata, Flags.Has_Private_Extension_Metadata);
      Merge (Info.Flags.Has_Named_Number_Metadata, Flags.Has_Named_Number_Metadata);
      Merge (Info.Flags.Has_Deferred_Constant_Metadata, Flags.Has_Deferred_Constant_Metadata);
      Merge (Info.Flags.Has_Null_Subprogram_Metadata, Flags.Has_Null_Subprogram_Metadata);
      Merge (Info.Flags.Has_Expression_Function_Metadata, Flags.Has_Expression_Function_Metadata);
      Merge (Info.Flags.Has_Null_Record_Metadata, Flags.Has_Null_Record_Metadata);
      Merge (Info.Flags.Has_Discriminant_Part_Metadata, Flags.Has_Discriminant_Part_Metadata);
      Merge (Info.Flags.Has_Body_Stub_Metadata, Flags.Has_Body_Stub_Metadata);
      Merge (Info.Flags.Has_Constraint_Metadata, Flags.Has_Constraint_Metadata);
      Merge (Info.Flags.Has_Child_Unit_Metadata, Flags.Has_Child_Unit_Metadata);
      Merge (Info.Flags.Has_Generic_Actual_Part_Metadata, Flags.Has_Generic_Actual_Part_Metadata);

      if Changed then
         Info.Fingerprint := Hash_Flags ((Info.Fingerprint * 131 + 579348) mod 2_147_483_647, Info.Flags);
         Analysis.Result_Fingerprint :=
           (Analysis.Result_Fingerprint * 131 + Info.Fingerprint + 1)
           mod 2_147_483_647;
         Analysis.Symbols.Replace_Element (Positive (Id), Info);
      end if;
   end Merge_Symbol_Flags;


   procedure Mark_Symbol_Variant_Record_Metadata
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id)
   is
      Info : Symbol_Info;
   begin
      if Id = No_Symbol
        or else Natural (Id) = 0
        or else Natural (Id) > Natural (Analysis.Symbols.Length)
      then
         return;
      end if;

      Info := Analysis.Symbols.Element (Positive (Id));
      if Info.Flags.Has_Variant_Record_Metadata then
         return;
      end if;

      Info.Flags.Has_Variant_Record_Metadata := True;
      Info.Fingerprint :=
        (Info.Fingerprint * 131 + 579215) mod 2_147_483_647;
      Analysis.Result_Fingerprint :=
        Hash_Mix (Analysis.Result_Fingerprint, Long_Long_Integer (Info.Fingerprint) + 1);
      Analysis.Symbols.Replace_Element (Positive (Id), Info);
   end Mark_Symbol_Variant_Record_Metadata;


   procedure Mark_Statement_Kind
     (Analysis : in out Analysis_Result;
      Kind     : Statement_Kind)
   is
   begin
      Analysis.Statement_Aware := True;
      Analysis.Statement_Counts (Kind) := Analysis.Statement_Counts (Kind) + 1;
      Analysis.Result_Fingerprint :=
        (Analysis.Result_Fingerprint * 131 +
         Natural (Statement_Kind'Pos (Kind)) +
         Analysis.Statement_Counts (Kind) + 579240)
        mod 2_147_483_647;
   end Mark_Statement_Kind;

   function Statement_Count
     (Analysis : Analysis_Result;
      Kind     : Statement_Kind) return Natural
   is
   begin
      return Analysis.Statement_Counts (Kind);
   end Statement_Count;

   function Total_Statement_Count (Analysis : Analysis_Result) return Natural is
      Total : Natural := 0;
   begin
      for Kind in Statement_Kind loop
         Total := Total + Analysis.Statement_Counts (Kind);
      end loop;
      return Total;
   end Total_Statement_Count;

   function Has_Statement_Awareness (Analysis : Analysis_Result) return Boolean is
   begin
      return Analysis.Statement_Aware;
   end Has_Statement_Awareness;



   procedure Add_Executable_Binding
     (Analysis        : in out Analysis_Result;
      Kind            : Executable_Binding_Kind;
      Name            : String;
      Expression_Text : String := "";
      Scope           : Scope_Id := Root_Scope;
      Target_Symbol   : Symbol_Id := No_Symbol;
      Source_Span           : Source_Range := (others => 1))
   is
      H : Natural := Analysis.Result_Fingerprint;
      Info : Executable_Binding_Info;
   begin
      if Name'Length = 0 then
         return;
      elsif Natural (Analysis.Executable_Bindings.Length) >= Max_Executable_Bindings then
         if not Analysis.Symbol_Overflow then
            Analysis.Symbol_Overflow := True;
            Analysis.Result_Fingerprint :=
              Hash_Mix (Analysis.Result_Fingerprint, 579375);
         end if;
         return;
      end if;

      H := Hash_Mix
        (H, (Natural (Executable_Binding_Kind'Pos (Kind)), 1));
      H := Hash_String (H, Normalize_Name (Name));
      H := Hash_String (H, Name);
      H := Hash_String (H, Expression_Text);
      H := Hash_Mix
        (H,
         (Natural (Scope),
          Natural (Target_Symbol),
          Source_Span.Start_Line,
          Source_Span.Start_Column,
          Source_Span.End_Line,
          Source_Span.End_Column,
          579375));

      Info :=
        (Kind            => Kind,
         Name            => To_Unbounded_String (Name),
         Normalized_Name => To_Unbounded_String (Normalize_Name (Name)),
         Expression_Text => To_Unbounded_String (Expression_Text),
         Scope           => Scope,
         Target_Symbol   => Target_Symbol,
         Source_Span           => Source_Span,
         Fingerprint     => H);

      Analysis.Executable_Bindings.Append (Info);
      Analysis.Result_Fingerprint := H;
   end Add_Executable_Binding;

   function Executable_Binding_Count
     (Analysis : Analysis_Result;
      Kind     : Executable_Binding_Kind := Binding_Any)
      return Natural
   is
      Total : Natural := 0;
   begin
      if Kind = Binding_Any then
         return Natural (Analysis.Executable_Bindings.Length);
      end if;

      for Info of Analysis.Executable_Bindings loop
         if Info.Kind = Kind then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Executable_Binding_Count;

   function Executable_Binding_At
     (Analysis : Analysis_Result;
      Index    : Positive) return Executable_Binding_Info
   is
   begin
      if Index <= Natural (Analysis.Executable_Bindings.Length) then
         return Analysis.Executable_Bindings.Element (Index);
      else
         return
           (Kind            => Binding_Call_Target,
            Name            => Null_Unbounded_String,
            Normalized_Name => Null_Unbounded_String,
            Expression_Text => Null_Unbounded_String,
            Scope           => Root_Scope,
            Target_Symbol   => No_Symbol,
            Source_Span           => (others => 1),
            Fingerprint     => 0);
      end if;
   end Executable_Binding_At;

   function Has_Executable_Bindings (Analysis : Analysis_Result) return Boolean is
   begin
      return not Analysis.Executable_Bindings.Is_Empty;
   end Has_Executable_Bindings;


   function Symbol_Count (Analysis : Analysis_Result) return Natural is
   begin
      return Natural (Analysis.Symbols.Length);
   end Symbol_Count;

   function Symbol (Analysis : Analysis_Result; Id : Symbol_Id) return Symbol_Info is
   begin
      if Id = No_Symbol
        or else Natural (Id) = 0
        or else Natural (Id) > Natural (Analysis.Symbols.Length)
      then
         return (others => <>);
      end if;
      return Analysis.Symbols.Element (Positive (Id));
   end Symbol;

   function Symbol_At (Analysis : Analysis_Result; Index : Positive) return Symbol_Info is
   begin
      if Index > Natural (Analysis.Symbols.Length) then
         return (others => <>);
      end if;
      return Analysis.Symbols.Element (Index);
   end Symbol_At;

   function Valid_Child_Parent
     (Analysis : Analysis_Result;
      Parent   : Symbol_Id) return Boolean
   is
      Owner : Symbol_Info;
   begin
      if Parent = No_Symbol
        or else Natural (Parent) = 0
        or else Natural (Parent) > Symbol_Count (Analysis)
      then
         return False;
      end if;

      Owner := Analysis.Symbols.Element (Positive (Parent));

      --  use the shared declaration-owner predicate so child
      --  traversal, overload scopes, resolver/index qualification, and
      --  semantic consumers do not drift apart on which symbols may own
      --  nested declarations.
      return Is_Declaration_Owner (Owner.Kind);
   end Valid_Child_Parent;

   function Is_Direct_Child
     (Info   : Symbol_Info;
      Parent : Symbol_Id) return Boolean
   is
   begin
      --  direct child enumeration is only valid when both ownership
      --  stamps agree.  Parent_Symbol links the row to the displayed outline
      --  parent, while Enclosing_Scope drives overload/resolver lookup.  A
      --  malformed row with only one of those stamps set must not leak into
      --  child traversal because downstream navigation assumes the two are
      --  synchronized by the parser.
      return Info.Parent_Symbol = Parent
        and then Info.Id /= Parent
        and then Info.Enclosing_Scope = Scope_Id (Parent);
   end Is_Direct_Child;

   function Child_Count
     (Analysis : Analysis_Result;
      Parent   : Symbol_Id) return Natural
   is
      Count : Natural := 0;
   begin
      if not Valid_Child_Parent (Analysis, Parent) then
         --  /163: parent-child traversal is only valid for
         --  declaration-owning symbols owned by this analysis result.
         --  Malformed or stale ids must not expose children that happen to
         --  carry the same invalid/non-owner parent number.
         return 0;
      end if;

      for I in 1 .. Symbol_Count (Analysis) loop
         declare
            Info : constant Symbol_Info := Analysis.Symbols.Element (Positive (I));
         begin
            if Is_Direct_Child (Info, Parent) then
               --  /165: skip self-parent edges and require matching
               --  lexical scope metadata before exposing deterministic direct
               --  children.
               Count := Count + 1;
            end if;
         end;
      end loop;

      return Count;
   end Child_Count;

   function Child_At
     (Analysis : Analysis_Result;
      Parent   : Symbol_Id;
      Index    : Positive) return Symbol_Id
   is
      Seen : Natural := 0;
   begin
      if not Valid_Child_Parent (Analysis, Parent) then
         --  /163: stale, invalid, or value-like parent ids degrade
         --  to No_Symbol rather than enumerating orphaned rows attached to
         --  malformed metadata.
         return No_Symbol;
      end if;

      for I in 1 .. Symbol_Count (Analysis) loop
         declare
            Info : constant Symbol_Info := Analysis.Symbols.Element (Positive (I));
         begin
            if Is_Direct_Child (Info, Parent) then
               --  /165: keep Child_At consistent with Child_Count by
               --  skipping self-parent edges and mismatched parent/scope
               --  ownership stamps.
               Seen := Seen + 1;
               if Seen = Index then
                  return Info.Id;
               end if;
            end if;
         end;
      end loop;

      return No_Symbol;
   end Child_At;

   function Valid_Scope
     (Analysis : Analysis_Result;
      Scope    : Scope_Id) return Boolean
   is
      Owner : Symbol_Info;
   begin
      if Scope = Root_Scope then
         return True;
      end if;

      if Natural (Scope) = 0
        or else Natural (Scope) > Symbol_Count (Analysis)
      then
         return False;
      end if;

      Owner := Analysis.Symbols.Element (Positive (Scope));

      --  use the shared declaration-owner predicate so child
      --  traversal, overload scopes, resolver/index qualification, and
      --  semantic consumers do not drift apart on which symbols may own
      --  nested declarations.
      return Is_Declaration_Owner (Owner.Kind);
   end Valid_Scope;

   function Is_Direct_Overload
     (Info  : Symbol_Info;
      Scope : Scope_Id) return Boolean
   is
   begin
      if Scope = Root_Scope then
         return Info.Enclosing_Scope = Root_Scope
           and then Info.Parent_Symbol = No_Symbol;
      else
         --  overload enumeration is a direct-scope API.  The
         --  parser-owned lexical stamp and parent symbol stamp must agree,
         --  matching the child traversal invariant added in .
         --  Malformed rows that merely carry the requested Enclosing_Scope
         --  but point at another parent must not appear as same-scope
         --  overloads for Outline/navigation or semantic consumers.
         return Info.Enclosing_Scope = Scope
           and then Info.Parent_Symbol = Symbol_Id (Scope);
      end if;
   end Is_Direct_Overload;

   function Overload_Count
     (Analysis : Analysis_Result;
      Scope    : Scope_Id;
      Name     : String) return Natural
   is
      Wanted : constant String := Normalize_Name (Name);
      Count  : Natural := 0;
   begin
      if Name'Length = 0 then
         return 0;
      end if;

      if not Valid_Scope (Analysis, Scope) then
         --  overload-set traversal must only operate on the root
         --  scope or scopes owned by this analysis result.  Malformed rows
         --  with an impossible Enclosing_Scope must not become externally
         --  enumerable through the overload API.
         return 0;
      end if;

      for I in 1 .. Symbol_Count (Analysis) loop
         declare
            Info : constant Symbol_Info := Analysis.Symbols.Element (Positive (I));
         begin
            if Is_Direct_Overload (Info, Scope)
              and then To_String (Info.Normalized_Name) = Wanted
            then
               Count := Count + 1;
            end if;
         end;
      end loop;

      return Count;
   end Overload_Count;

   function Overload_At
     (Analysis : Analysis_Result;
      Scope    : Scope_Id;
      Name     : String;
      Index    : Positive) return Symbol_Id
   is
      Wanted : constant String := Normalize_Name (Name);
      Seen   : Natural := 0;
   begin
      if Name'Length = 0 then
         return No_Symbol;
      end if;

      if not Valid_Scope (Analysis, Scope) then
         --  invalid/stale scope ids degrade rather than exposing
         --  orphaned overload rows that carry malformed scope metadata.
         return No_Symbol;
      end if;

      for I in 1 .. Symbol_Count (Analysis) loop
         declare
            Info : constant Symbol_Info := Analysis.Symbols.Element (Positive (I));
         begin
            if Is_Direct_Overload (Info, Scope)
              and then To_String (Info.Normalized_Name) = Wanted
            then
               Seen := Seen + 1;
               if Seen = Index then
                  return Info.Id;
               end if;
            end if;
         end;
      end loop;

      return No_Symbol;
   end Overload_At;



   procedure Mark_Generated_Source_Awareness (Analysis : in out Analysis_Result) is
   begin
      if Analysis.Generated_Source_Aware then
         return;
      end if;
      Analysis.Generated_Source_Aware := True;
      Analysis.Result_Fingerprint :=
        (Analysis.Result_Fingerprint * 131 + 579196) mod 2_147_483_647;
   end Mark_Generated_Source_Awareness;

   procedure Mark_Conditional_Source_Awareness (Analysis : in out Analysis_Result) is
   begin
      if Analysis.Conditional_Source_Aware then
         return;
      end if;
      Analysis.Conditional_Source_Aware := True;
      Analysis.Result_Fingerprint :=
        (Analysis.Result_Fingerprint * 131 + 579197) mod 2_147_483_647;
   end Mark_Conditional_Source_Awareness;


   procedure Mark_With_Clause_Awareness (Analysis : in out Analysis_Result) is
   begin
      if Analysis.With_Clause_Aware then
         return;
      end if;
      Analysis.With_Clause_Aware := True;
      Analysis.Result_Fingerprint :=
        (Analysis.Result_Fingerprint * 131 + 579206) mod 2_147_483_647;
   end Mark_With_Clause_Awareness;

   procedure Mark_Use_Clause_Awareness (Analysis : in out Analysis_Result) is
   begin
      if Analysis.Use_Clause_Aware then
         return;
      end if;
      Analysis.Use_Clause_Aware := True;
      Analysis.Result_Fingerprint :=
        (Analysis.Result_Fingerprint * 131 + 579207) mod 2_147_483_647;
   end Mark_Use_Clause_Awareness;



   procedure Add_Visibility_Clause
     (Analysis             : in out Analysis_Result;
      Kind                 : Visibility_Clause_Kind;
      Name                 : String;
      Scope                : Scope_Id := Root_Scope;
      Source_Span                : Source_Range := (others => 1);
      Is_Context_Clause    : Boolean := False;
      Has_Limited_Modifier : Boolean := False;
      Has_Private_Modifier : Boolean := False)
   is
      Info : Visibility_Clause_Info;
      H    : Natural := Analysis.Result_Fingerprint;
   begin
      if Name'Length = 0 then
         return;
      end if;

      if Natural (Analysis.Visibility_Clauses.Length) >= Max_Visibility_Clauses then
         if not Analysis.Symbol_Overflow then
            Analysis.Symbol_Overflow := True;
            Analysis.Result_Fingerprint :=
              (Analysis.Result_Fingerprint * 131 + 579351) mod 2_147_483_647;
         end if;
         return;
      end if;

      Info.Kind := Kind;
      Info.Name := To_Unbounded_String (Name);
      Info.Normalized_Name := To_Unbounded_String (Normalize_Name (Name));
      Info.Scope := Scope;
      Info.Is_Context_Clause := Is_Context_Clause;
      Info.Has_Limited_Modifier :=
        Has_Limited_Modifier or else Kind = Visibility_Limited_With_Clause;
      Info.Has_Private_Modifier :=
        Has_Private_Modifier or else Kind = Visibility_Private_With_Clause;
      Info.Source_Span := Source_Span;

      H := Hash_String (H, Visibility_Clause_Kind'Image (Kind));
      H := Hash_String (H, Normalize_Name (Name));
      if Is_Context_Clause then
         H := Hash_Mix (H, 758001);
      end if;
      if Info.Has_Limited_Modifier then
         H := Hash_Mix (H, 758002);
      end if;
      if Info.Has_Private_Modifier then
         H := Hash_Mix (H, 758003);
      end if;
      H := Hash_Mix
        (H,
         (Natural (Scope),
          Source_Span.Start_Line,
          Source_Span.Start_Column,
          Source_Span.End_Line,
          Source_Span.End_Column));
      Info.Fingerprint := H;

      Analysis.Visibility_Clauses.Append (Info);
      Analysis.Result_Fingerprint := H;

      case Kind is
         when Visibility_With_Clause
            | Visibility_Limited_With_Clause
            | Visibility_Private_With_Clause =>
            Mark_With_Clause_Awareness (Analysis);
         when Visibility_Use_Package_Clause
            | Visibility_Use_Type_Clause
            | Visibility_Use_All_Type_Clause =>
            Mark_Use_Clause_Awareness (Analysis);
      end case;
   end Add_Visibility_Clause;

   function Visibility_Clause_Count
     (Analysis : Analysis_Result;
      Scope    : Scope_Id := Scope_Id'Last) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Visibility_Clauses loop
         if Scope = Scope_Id'Last or else Info.Scope = Scope then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Visibility_Clause_Count;

   function Visibility_Clause_At
     (Analysis : Analysis_Result;
      Scope    : Scope_Id;
      Index    : Positive) return Visibility_Clause_Info
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Visibility_Clauses loop
         if Scope = Scope_Id'Last or else Info.Scope = Scope then
            Count := Count + 1;
            if Count = Index then
               return Info;
            end if;
         end if;
      end loop;
      return (Kind => Visibility_With_Clause,
              Name => To_Unbounded_String (""),
              Normalized_Name => To_Unbounded_String (""),
              Scope => Root_Scope,
              Is_Context_Clause => False,
              Has_Limited_Modifier => False,
              Has_Private_Modifier => False,
              Source_Span => (others => 1),
              Fingerprint => 0);
   end Visibility_Clause_At;

   function Context_Clause_Count
     (Analysis : Analysis_Result) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Visibility_Clauses loop
         if Info.Is_Context_Clause then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Context_Clause_Count;

   function Context_Clause_At
     (Analysis : Analysis_Result;
      Index    : Positive) return Visibility_Clause_Info
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Visibility_Clauses loop
         if Info.Is_Context_Clause then
            Count := Count + 1;
            if Count = Index then
               return Info;
            end if;
         end if;
      end loop;

      return (Kind => Visibility_With_Clause,
              Name => To_Unbounded_String (""),
              Normalized_Name => To_Unbounded_String (""),
              Scope => Root_Scope,
              Is_Context_Clause => False,
              Has_Limited_Modifier => False,
              Has_Private_Modifier => False,
              Source_Span => (others => 1),
              Fingerprint => 0);
   end Context_Clause_At;

   function Use_Clause_Count
     (Analysis : Analysis_Result;
      Scope    : Scope_Id := Scope_Id'Last) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Visibility_Clauses loop
         if (Scope = Scope_Id'Last or else Info.Scope = Scope)
           and then (Info.Kind = Visibility_Use_Package_Clause
                     or else Info.Kind = Visibility_Use_Type_Clause
                     or else Info.Kind = Visibility_Use_All_Type_Clause)
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Use_Clause_Count;

   function Use_Clause_At
     (Analysis : Analysis_Result;
      Scope    : Scope_Id;
      Index    : Positive) return Visibility_Clause_Info
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Visibility_Clauses loop
         if (Scope = Scope_Id'Last or else Info.Scope = Scope)
           and then (Info.Kind = Visibility_Use_Package_Clause
                     or else Info.Kind = Visibility_Use_Type_Clause
                     or else Info.Kind = Visibility_Use_All_Type_Clause)
         then
            Count := Count + 1;
            if Count = Index then
               return Info;
            end if;
         end if;
      end loop;

      return (Kind => Visibility_Use_Package_Clause,
              Name => To_Unbounded_String (""),
              Normalized_Name => To_Unbounded_String (""),
              Scope => Root_Scope,
              Is_Context_Clause => False,
              Has_Limited_Modifier => False,
              Has_Private_Modifier => False,
              Source_Span => (others => 1),
              Fingerprint => 0);
   end Use_Clause_At;

   procedure Add_Pragma_Metadata
     (Analysis             : in out Analysis_Result;
      Name                 : String;
      Placement            : Pragma_Placement_Kind;
      Scope                : Scope_Id := Root_Scope;
      Target_Name          : String := "";
      Argument_Count       : Natural := 0;
      Named_Argument_Count : Natural := 0;
      Source_Span                : Source_Range := (others => 1))
   is
      Info : Pragma_Info;
      H    : Natural := Analysis.Result_Fingerprint;
   begin
      if Name'Length = 0 then
         return;
      end if;

      if Natural (Analysis.Pragmas.Length) >= Max_Pragmas then
         if not Analysis.Symbol_Overflow then
            Analysis.Symbol_Overflow := True;
            Analysis.Result_Fingerprint :=
              (Analysis.Result_Fingerprint * 131 + 579729) mod 2_147_483_647;
         end if;
         return;
      end if;

      Info.Name := To_Unbounded_String (Name);
      Info.Normalized_Name := To_Unbounded_String (Normalize_Name (Name));
      Info.Placement := Placement;
      Info.Scope := Scope;
      Info.Target_Name := To_Unbounded_String (Target_Name);
      Info.Normalized_Target_Name := To_Unbounded_String (Normalize_Name (Target_Name));
      Info.Argument_Count := Argument_Count;
      Info.Named_Argument_Count := Named_Argument_Count;
      Info.Source_Span := Source_Span;

      H := Hash_String (H, Normalize_Name (Name));
      H := Hash_String (H, Pragma_Placement_Kind'Image (Placement));
      H := Hash_String (H, Normalize_Name (Target_Name));
      H := (H * 131 + Natural (Scope) + Argument_Count + Named_Argument_Count
            + Source_Span.Start_Line + Source_Span.Start_Column + Source_Span.End_Line
            + Source_Span.End_Column) mod 2_147_483_647;
      Info.Fingerprint := H;

      Analysis.Pragmas.Append (Info);
      Analysis.Result_Fingerprint := H;
   end Add_Pragma_Metadata;

   function Pragma_Metadata_Count
     (Analysis  : Analysis_Result;
      Placement : Pragma_Placement_Kind := Pragma_Placement_Declaration;
      Any_Placement : Boolean := True) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Pragmas loop
         if Any_Placement or else Info.Placement = Placement then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Pragma_Metadata_Count;

   function Pragma_Metadata_At
     (Analysis  : Analysis_Result;
      Index     : Positive) return Pragma_Info
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Pragmas loop
         Count := Count + 1;
         if Count = Index then
            return Info;
         end if;
      end loop;

      return (Name => To_Unbounded_String (""),
              Normalized_Name => To_Unbounded_String (""),
              Placement => Pragma_Placement_Declaration,
              Scope => Root_Scope,
              Target_Name => To_Unbounded_String (""),
              Normalized_Target_Name => To_Unbounded_String (""),
              Argument_Count => 0,
              Named_Argument_Count => 0,
              Source_Span => (others => 1),
              Fingerprint => 0);
   end Pragma_Metadata_At;

   function Overflowed (Analysis : Analysis_Result) return Boolean is
   begin
      return Analysis.Symbol_Overflow;
   end Overflowed;

   function Has_Generated_Source_Awareness (Analysis : Analysis_Result) return Boolean is
   begin
      return Analysis.Generated_Source_Aware;
   end Has_Generated_Source_Awareness;

   function Has_Conditional_Source_Awareness (Analysis : Analysis_Result) return Boolean is
   begin
      return Analysis.Conditional_Source_Aware;
   end Has_Conditional_Source_Awareness;


   function Has_With_Clause_Awareness (Analysis : Analysis_Result) return Boolean is
   begin
      return Analysis.With_Clause_Aware;
   end Has_With_Clause_Awareness;

   function Has_Use_Clause_Awareness (Analysis : Analysis_Result) return Boolean is
   begin
      return Analysis.Use_Clause_Aware;
   end Has_Use_Clause_Awareness;

   procedure Set_Syntax_Tree
     (Analysis : in out Analysis_Result;
      Tree     : Editor.Ada_Syntax_Tree.Tree_Type)
   is
   begin
      Analysis.Syntax_Tree_Value := Tree;
      Analysis.Syntax_Tree_Aware := Editor.Ada_Syntax_Tree.Has_Nodes (Tree);
      Analysis.Result_Fingerprint :=
        (Analysis.Result_Fingerprint * 65599
         + Editor.Ada_Syntax_Tree.Fingerprint (Tree) + 37) mod Natural'Last;
   end Set_Syntax_Tree;

   function Has_Syntax_Tree (Analysis : Analysis_Result) return Boolean is
   begin
      return Analysis.Syntax_Tree_Aware;
   end Has_Syntax_Tree;

   function Syntax_Tree_Node_Count (Analysis : Analysis_Result) return Natural is
   begin
      return Editor.Ada_Syntax_Tree.Node_Count (Analysis.Syntax_Tree_Value);
   end Syntax_Tree_Node_Count;

   function Syntax_Tree_Root_Kind
     (Analysis : Analysis_Result) return Editor.Ada_Syntax_Tree.Node_Kind
   is
   begin
      if not Analysis.Syntax_Tree_Aware then
         return Editor.Ada_Syntax_Tree.Node_Unknown;
      end if;
      return Editor.Ada_Syntax_Tree.Node
        (Analysis.Syntax_Tree_Value,
         Editor.Ada_Syntax_Tree.Root (Analysis.Syntax_Tree_Value)).Kind;
   end Syntax_Tree_Root_Kind;

   function Syntax_Tree_Fingerprint (Analysis : Analysis_Result) return Natural is
   begin
      return Editor.Ada_Syntax_Tree.Fingerprint (Analysis.Syntax_Tree_Value);
   end Syntax_Tree_Fingerprint;

   function Syntax_Tree
     (Analysis : Analysis_Result) return Editor.Ada_Syntax_Tree.Tree_Type
   is
   begin
      return Analysis.Syntax_Tree_Value;
   end Syntax_Tree;

   function Fingerprint (Analysis : Analysis_Result) return Natural is
   begin
      return Analysis.Result_Fingerprint;
   end Fingerprint;

   function Kind_To_Syntax_Kind (Kind : Symbol_Kind) return Editor.Syntax.Token_Kind is
   begin
      case Kind is
         when Symbol_Package | Symbol_Package_Body | Symbol_Generic_Package =>
            return Editor.Syntax.Package_Identifier;
         when Symbol_Type | Symbol_Subtype | Symbol_Record_Type
            | Symbol_Task | Symbol_Protected =>
            return Editor.Syntax.Type_Identifier;
         when Symbol_Procedure | Symbol_Function | Symbol_Operator_Function
            | Symbol_Entry | Symbol_Generic_Subprogram | Symbol_Separate_Body =>
            return Editor.Syntax.Subprogram_Identifier;
         when Symbol_Generic_Formal_Type | Symbol_Generic_Formal_Object
            | Symbol_Generic_Formal_Subprogram | Symbol_Generic_Formal_Package =>
            return Editor.Syntax.Generic_Formal;
         when Symbol_Object | Symbol_Constant | Symbol_Record_Component
            | Symbol_Discriminant | Symbol_Enumeration_Literal
            | Symbol_Exception =>
            --  The renderer theme currently has no dedicated value/component/
            --  exception buckets.  Keep these parser-owned semantic symbols
            --  distinguishable from ordinary identifiers using the existing
            --  value-like semantic token bucket rather than dropping them.
            return Editor.Syntax.Parameter_Identifier;
         when others =>
            return Editor.Syntax.Identifier;
      end case;
   end Kind_To_Syntax_Kind;

   function Is_Subprogram (Kind : Symbol_Kind) return Boolean is
   begin
      --  keep predicate classification aligned with the semantic
      --  token mapping above.  Separate body rows navigate/colour as callable
      --  body targets, so callers using this predicate must not treat them as
      --  unknown non-callable symbols.
      return Kind in Symbol_Procedure | Symbol_Function | Symbol_Operator_Function
        | Symbol_Entry | Symbol_Generic_Subprogram | Symbol_Separate_Body;
   end Is_Subprogram;

   function Is_Type_Like (Kind : Symbol_Kind) return Boolean is
   begin
      --  Generic formal types participate in type-name lookup/colouring even
      --  though they use a dedicated Generic_Formal token bucket.  Treating
      --  them as type-like keeps model predicates consistent with Ada name
      --  resolution consumers that need a broader type classification.
      return Kind in Symbol_Type | Symbol_Subtype | Symbol_Record_Type
        | Symbol_Task | Symbol_Protected | Symbol_Generic_Formal_Type;
   end Is_Type_Like;

   function Is_Declaration_Owner (Kind : Symbol_Kind) return Boolean is
   begin
      --  one canonical ownership predicate backs child traversal,
      --  overload scopes, and project-index selected-name construction.
      --  Value-like symbols such as objects/constants/components/literals do
      --  not own nested declarations in this retained model.
      return Kind in Symbol_Package | Symbol_Package_Body
        | Symbol_Procedure | Symbol_Function | Symbol_Operator_Function
        | Symbol_Type | Symbol_Record_Type
        | Symbol_Task | Symbol_Protected | Symbol_Entry
        | Symbol_Generic_Package | Symbol_Generic_Subprogram
        | Symbol_Generic_Formal_Type | Symbol_Generic_Formal_Subprogram
        | Symbol_Generic_Formal_Package
        | Symbol_Separate_Body;
   end Is_Declaration_Owner;

   function Is_Separate_Body_Parent_Target (Symbol : Symbol_Info) return Boolean is
   begin
      --  separate-body parent navigation may only target
      --  declaration-owning/callable non-body symbols.  This keeps indexed
      --  Outline navigation from accepting an object/component/literal merely
      --  because it shares a retained Target_Name.
      return not Symbol.Flags.Is_Body
        and then
          (Symbol.Kind = Symbol_Package
           or else Symbol.Kind = Symbol_Generic_Package
           or else Symbol.Kind = Symbol_Procedure
           or else Symbol.Kind = Symbol_Function
           or else Symbol.Kind = Symbol_Operator_Function
           or else Symbol.Kind = Symbol_Generic_Subprogram
           or else Symbol.Kind = Symbol_Task
           or else Symbol.Kind = Symbol_Protected
           or else Symbol.Kind = Symbol_Entry);
   end Is_Separate_Body_Parent_Target;


   function Position_Not_After
     (A_Line   : Positive;
      A_Column : Positive;
      B_Line   : Positive;
      B_Column : Positive) return Boolean
   is
   begin
      return A_Line < B_Line
        or else (A_Line = B_Line and then A_Column <= B_Column);
   end Position_Not_After;

   function Range_Extends_Past_Start (Source_Span : Source_Range) return Boolean is
   begin
      return Source_Span.End_Line > Source_Span.Start_Line;
   end Range_Extends_Past_Start;

   function Position_In_Range
     (Source_Span  : Source_Range;
      Line   : Positive;
      Column : Positive) return Boolean
   is
   begin
      if not Position_Not_After (Source_Span.Start_Line, Source_Span.Start_Column, Line, Column) then
         return False;
      end if;

      if not Range_Extends_Past_Start (Source_Span) then
         return True;
      end if;

      return Position_Not_After (Line, Column, Source_Span.End_Line, Source_Span.End_Column);
   end Position_In_Range;

   function Allows_Open_Ended_Scope (Kind : Symbol_Kind) return Boolean is
   begin
      return Kind not in Symbol_Type | Symbol_Record_Type | Symbol_Generic_Formal_Type;
   end Allows_Open_Ended_Scope;

   function Scope_For_Position
     (Analysis : Analysis_Result;
      Line     : Positive;
      Column   : Positive) return Symbol_Id
   is
      Best       : Symbol_Id := No_Symbol;
      Best_Depth : Natural := 0;
      Best_Line  : Positive := 1;
      Best_Column : Positive := 1;
   begin
      --  render-time semantic colouring needs a parser-owned
      --  lexical scope for the token being classified.  The parser currently
      --  retains declaration ownership and source starts, not a full token
      --  scope table, so this conservative bridge selects the deepest
      --  declaration-owning symbol whose declaration begins before the token.
      --  Invalid ownership metadata is ignored; callers still degrade through
      --  resolver/root lookup when no precise owner is available.
      --  once the parser/model retains a real source range, scope
      --  selection also respects that end boundary so a finished package/body
      --  does not keep colouring later declarations as though they were still
      --  nested inside it.
      for I in 1 .. Symbol_Count (Analysis) loop
         declare
            Info : constant Symbol_Info := Analysis.Symbols.Element (Positive (I));
         begin
            if Is_Declaration_Owner (Info.Kind)
              and then Info.Id /= No_Symbol
              and then Position_Not_After
                (Info.Declaration_Line, Info.Declaration_Column, Line, Column)
              and then Position_In_Range (Info.Source_Span, Line, Column)
              and then (Range_Extends_Past_Start (Info.Source_Span)
                        or else Line = Info.Source_Span.Start_Line
                        or else Allows_Open_Ended_Scope (Info.Kind))
              and then (Info.Depth > Best_Depth
                        or else Best = No_Symbol
                        or else (Info.Depth = Best_Depth
                                 and then Position_Not_After
                                   (Best_Line, Best_Column,
                                    Info.Declaration_Line,
                                    Info.Declaration_Column)))
            then
               Best := Info.Id;
               Best_Depth := Info.Depth;
               Best_Line := Info.Declaration_Line;
               Best_Column := Info.Declaration_Column;
            end if;
         end;
      end loop;

      return Best;
   end Scope_For_Position;


end Editor.Ada_Language_Model;
