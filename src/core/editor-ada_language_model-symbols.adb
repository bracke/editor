with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Syntax;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Language_Model.Hashing; use Editor.Ada_Language_Model.Hashing;
with Editor.Ada_Language_Model.Symbols; use Editor.Ada_Language_Model.Symbols;
with Editor.Ada_Language_Model.Generic_Metadata; use Editor.Ada_Language_Model.Generic_Metadata;
with Editor.Ada_Language_Model.Representation_Metadata; use Editor.Ada_Language_Model.Representation_Metadata;
with Editor.Ada_Language_Model.Diagnostics; use Editor.Ada_Language_Model.Diagnostics;
with Editor.Ada_Language_Model.Visibility; use Editor.Ada_Language_Model.Visibility;
with Editor.Ada_Language_Model.Syntax_Attachment; use Editor.Ada_Language_Model.Syntax_Attachment;

package body Editor.Ada_Language_Model.Symbols is

   pragma Suppress (Overflow_Check);

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



end Editor.Ada_Language_Model.Symbols;
