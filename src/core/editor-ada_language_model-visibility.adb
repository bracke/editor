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

package body Editor.Ada_Language_Model.Visibility is

   pragma Suppress (Overflow_Check);

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


end Editor.Ada_Language_Model.Visibility;
