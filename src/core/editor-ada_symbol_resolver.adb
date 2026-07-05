with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;

package body Editor.Ada_Symbol_Resolver is

   pragma Suppress (Overflow_Check);

   function Leaf_Name (Name : String) return String is
      Dot : Natural := 0;
   begin
      for I in reverse Name'Range loop
         if Name (I) = '.' then
            Dot := I;
            exit;
         end if;
      end loop;
      if Dot /= 0 and then Dot < Name'Last then
         return Name (Dot + 1 .. Name'Last);
      end if;
      return Name;
   end Leaf_Name;


   function Prefix_Name (Name : String) return String is
      Dot : Natural := 0;
   begin
      for I in reverse Name'Range loop
         if Name (I) = '.' then
            Dot := I;
            exit;
         end if;
      end loop;
      if Dot /= 0 and then Dot > Name'First then
         return Name (Name'First .. Dot - 1);
      end if;
      return "";
   end Prefix_Name;

   function Stored_Name_Is_Selected
     (S : Editor.Ada_Language_Model.Symbol_Info) return Boolean;

   function Name_Matches
     (S      : Editor.Ada_Language_Model.Symbol_Info;
      Wanted : String;
      Wanted_Leaf : String) return Boolean
   is
      use Ada.Strings.Unbounded;
      use Editor.Ada_Language_Model;
      N : constant String := To_String (S.Normalized_Name);
      L : constant String := Normalize_Name (Leaf_Name (To_String (S.Name)));
   begin
      if N = Wanted then
         return True;
      end if;

      --  the compatibility resolver must follow the same
      --  conservative selected-name boundary as Resolve_In_Scope.  An
      --  unselected lookup such as Widget must not bind to a stored dotted
      --  declaration such as Inner.Widget merely because the leaf matches;
      --  callers asking for the selected name can still resolve the exact
      --  dotted spelling through the selected-name path above.
      return (not Stored_Name_Is_Selected (S)) and then L = Wanted_Leaf;
   end Name_Matches;



   function Stored_Name_Is_Selected
     (S : Editor.Ada_Language_Model.Symbol_Info) return Boolean
   is
      use Ada.Strings.Unbounded;
      Source : constant String := To_String (S.Name);
   begin
      return Source'Length /= Leaf_Name (Source)'Length;
   end Stored_Name_Is_Selected;

   function Scoped_Name_Matches
     (S      : Editor.Ada_Language_Model.Symbol_Info;
      Wanted : String;
      Wanted_Leaf : String) return Boolean
   is
      use Ada.Strings.Unbounded;
      use Editor.Ada_Language_Model;
      N : constant String := To_String (S.Normalized_Name);
      L : constant String := Normalize_Name (Leaf_Name (To_String (S.Name)));
   begin
      if N = Wanted then
         return True;
      end if;

      --  scoped unselected lookup must not treat the leaf of a
      --  selected/dotted declaration name as an ordinary direct declaration in
      --  the current lexical scope.  Otherwise a stored child such as
      --  Inner.Widget can satisfy an unselected lookup for Widget and leak
      --  into semantic colouring/navigation as though Widget had been declared
      --  directly in the current scope.
      return (not Stored_Name_Is_Selected (S)) and then L = Wanted_Leaf;
   end Scoped_Name_Matches;

   function Resolve
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Name     : String;
      From_Depth : Natural := Natural'Last) return Resolution_Result
   is
      use Editor.Ada_Language_Model;
      Wanted : constant String := Normalize_Name (Name);
      Wanted_Leaf : constant String := Normalize_Name (Leaf_Name (Name));
      Selected : constant Boolean := Name'Length /= Leaf_Name (Name)'Length;
      Result : Resolution_Result;
      Best_Depth : Natural := Natural'First;
   begin
      --  Compatibility lookup for older callers: depth still bounds visibility,
      --  but overload sets are retained at the nearest visible depth.
      if Selected then
         for I in 1 .. Symbol_Count (Analysis) loop
            declare
               S : constant Symbol_Info := Symbol_At (Analysis, I);
               N : constant String := Ada.Strings.Unbounded.To_String (S.Normalized_Name);
            begin
               if S.Depth <= From_Depth and then N = Wanted then
                  Result.Matches.Append (S.Id);
               end if;
            end;
         end loop;
         if not Result.Matches.Is_Empty then
            Result.Overflow := Editor.Ada_Language_Model.Overflowed (Analysis);
            return Result;
         end if;
      end if;

      if Selected then
         --  a selected-name query must not degrade to a leaf-only
         --  match.  Doing so lets Missing.Widget bind to an unrelated Widget
         --  declaration and creates exactly the false positives the shared
         --  IDE-grade model is meant to avoid.  Callers with a concrete
         --  lexical scope should use Resolve_In_Scope for prefix/leaf walking.
         Result.Overflow := Editor.Ada_Language_Model.Overflowed (Analysis);
         return Result;
      end if;

      for I in 1 .. Symbol_Count (Analysis) loop
         declare
            S : constant Symbol_Info := Symbol_At (Analysis, I);
         begin
            if S.Depth <= From_Depth
              and then Name_Matches (S, Wanted, Wanted_Leaf)
              and then S.Depth >= Best_Depth
            then
               Best_Depth := S.Depth;
            end if;
         end;
      end loop;

      for I in 1 .. Symbol_Count (Analysis) loop
         declare
            S : constant Symbol_Info := Symbol_At (Analysis, I);
         begin
            if S.Depth = Best_Depth
              and then S.Depth <= From_Depth
              and then Name_Matches (S, Wanted, Wanted_Leaf)
            then
               Result.Matches.Append (S.Id);
            end if;
         end;
      end loop;

      Result.Overflow := Editor.Ada_Language_Model.Overflowed (Analysis);
      return Result;
   end Resolve;


   function Scope_Is_Visible
     (Analysis   : Editor.Ada_Language_Model.Analysis_Result;
      Scope      : Editor.Ada_Language_Model.Scope_Id;
      From_Scope : Editor.Ada_Language_Model.Symbol_Id) return Boolean
   is
      use Editor.Ada_Language_Model;
      Current : Symbol_Id := From_Scope;
      Steps   : Natural := 0;
   begin
      if Scope = Root_Scope then
         return True;
      end if;

      if Natural (Scope) = 0
        or else Natural (Scope) > Symbol_Count (Analysis)
        or else From_Scope = No_Symbol
        or else Natural (From_Scope) > Symbol_Count (Analysis)
      then
         return False;
      end if;

      loop
         exit when Steps > Symbol_Count (Analysis);
         Steps := Steps + 1;

         if Current = No_Symbol
           or else Natural (Current) > Symbol_Count (Analysis)
         then
            return False;
         end if;

         if Scope = Scope_Id (Natural (Current)) then
            return True;
         end if;

         Current := Symbol (Analysis, Current).Parent_Symbol;
      end loop;

      return False;
   end Scope_Is_Visible;


   procedure Append_Use_Visible_Matches
     (Analysis   : Editor.Ada_Language_Model.Analysis_Result;
      Name       : String;
      From_Scope : Editor.Ada_Language_Model.Symbol_Id;
      Result     : in out Resolution_Result)
   is
      use Ada.Strings.Unbounded;
      use Editor.Ada_Language_Model;
      Wanted      : constant String := Normalize_Name (Name);
      Wanted_Leaf : constant String := Normalize_Name (Leaf_Name (Name));

      function Clause_Is_Applicable (Clause : Visibility_Clause_Info) return Boolean is
      begin
         return Scope_Is_Visible (Analysis, Clause.Scope, From_Scope);
      end Clause_Is_Applicable;

      function Package_Target (Clause : Visibility_Clause_Info) return Symbol_Id is
         Target_Name : constant String := To_String (Clause.Normalized_Name);
         Prefix      : constant String := Prefix_Name (To_String (Clause.Name));
         Leaf        : constant String := Leaf_Name (To_String (Clause.Name));
      begin
         for I in 1 .. Symbol_Count (Analysis) loop
            declare
               S : constant Symbol_Info := Symbol_At (Analysis, I);
            begin
               if To_String (S.Normalized_Name) = Target_Name
                 and then (S.Kind = Symbol_Package
                           or else S.Kind = Symbol_Package_Body
                           or else S.Kind = Symbol_Generic_Package)
                 and then Scope_Is_Visible (Analysis, S.Enclosing_Scope, From_Scope)
               then
                  return S.Id;
               end if;
            end;
         end loop;

         --  a use-clause target may be a selected nested package
         --  whose declaration is retained as a leaf child under its enclosing
         --  package, e.g. ``package Parent is package Child is ...`` followed
         --  by ``use Parent.Child``.  Resolve the prefix first, then accept
         --  only a direct package-like child with synchronized lexical-scope
         --  and parent-symbol ownership.  This avoids leaf-only fallback for
         --  missing prefixes while making selected nested package clauses
         --  useful for semantic colouring/navigation.
         if Prefix'Length /= 0 then
            declare
               Prefix_Result : constant Resolution_Result :=
                 Resolve_In_Scope (Analysis, Prefix, From_Scope);
               Wanted_Leaf : constant String := Normalize_Name (Leaf);
            begin
               for P of Prefix_Result.Matches loop
                  for I in 1 .. Symbol_Count (Analysis) loop
                     declare
                        S : constant Symbol_Info := Symbol_At (Analysis, I);
                     begin
                        if S.Enclosing_Scope = Scope_Id (Natural (P))
                          and then S.Parent_Symbol = P
                          and then (S.Kind = Symbol_Package
                                    or else S.Kind = Symbol_Package_Body
                                    or else S.Kind = Symbol_Generic_Package)
                          and then To_String (S.Normalized_Name) = Wanted_Leaf
                        then
                           return S.Id;
                        end if;
                     end;
                  end loop;
               end loop;
            end;
         end if;

         return No_Symbol;
      end Package_Target;

      function Type_Target (Clause : Visibility_Clause_Info) return Symbol_Id is
         Target_Name : constant String := To_String (Clause.Normalized_Name);
         Prefix      : constant String := Prefix_Name (To_String (Clause.Name));
         Leaf        : constant String := Leaf_Name (To_String (Clause.Name));
      begin
         for I in 1 .. Symbol_Count (Analysis) loop
            declare
               S : constant Symbol_Info := Symbol_At (Analysis, I);
            begin
               if To_String (S.Normalized_Name) = Target_Name
                 and then Is_Type_Like (S.Kind)
                 and then Scope_Is_Visible (Analysis, S.Enclosing_Scope, From_Scope)
               then
                  return S.Id;
               end if;
            end;
         end loop;

         --  Selected use-type clauses normally name a package-visible type
         --  such as Shared.Count while the retained type declaration itself is
         --  stored as Count under Shared's lexical scope.  Resolve the prefix
         --  through the ordinary scoped selected-name path, then accept only a
         --  direct type-like child of that prefix symbol.
         if Prefix'Length /= 0 then
            declare
               Prefix_Result : constant Resolution_Result :=
                 Resolve_In_Scope (Analysis, Prefix, From_Scope);
               Wanted_Leaf : constant String := Normalize_Name (Leaf);
            begin
               for P of Prefix_Result.Matches loop
                  for I in 1 .. Symbol_Count (Analysis) loop
                     declare
                        S : constant Symbol_Info := Symbol_At (Analysis, I);
                     begin
                        if S.Enclosing_Scope = Scope_Id (Natural (P))
                          and then S.Parent_Symbol = P
                          and then Is_Type_Like (S.Kind)
                          and then To_String (S.Normalized_Name) = Wanted_Leaf
                        then
                           return S.Id;
                        end if;
                     end;
                  end loop;
               end loop;
            end;
         end if;

         return No_Symbol;
      end Type_Target;

      function Profile_References_Type
        (Profile : String;
         Type_Symbol : Symbol_Info) return Boolean
      is
         Normal_Profile : constant String := Normalize_Name (Profile);
         Type_Name      : constant String := To_String (Type_Symbol.Normalized_Name);
         Type_Leaf      : constant String := Normalize_Name (Leaf_Name (To_String (Type_Symbol.Name)));
      begin
         if Type_Name'Length = 0 then
            return False;
         end if;

         return Ada.Strings.Fixed.Index (Normal_Profile, Type_Name) /= 0
           or else (Type_Leaf'Length /= 0
                    and then Ada.Strings.Fixed.Index (Normal_Profile, Type_Leaf) /= 0);
      end Profile_References_Type;

      procedure Append_Primitive_Operator_Matches (Type_Id : Symbol_Id) is
      begin
         if Type_Id = No_Symbol
           or else Natural (Type_Id) > Symbol_Count (Analysis)
         then
            return;
         end if;

         declare
            Type_Info : constant Symbol_Info := Symbol (Analysis, Type_Id);
         begin
            for I in 1 .. Symbol_Count (Analysis) loop
               declare
                  S : constant Symbol_Info := Symbol_At (Analysis, I);
               begin
                  if S.Kind = Symbol_Operator_Function
                    and then S.Enclosing_Scope = Type_Info.Enclosing_Scope
                    and then S.Parent_Symbol = Type_Info.Parent_Symbol
                    and then Scoped_Name_Matches (S, Wanted, Wanted_Leaf)
                    and then Profile_References_Type
                      (To_String (S.Profile_Summary), Type_Info)
                  then
                     Result.Matches.Append (S.Id);
                  end if;
               end;
            end loop;
         end;
      end Append_Primitive_Operator_Matches;

      procedure Append_Child_Matches (Parent : Symbol_Id) is
      begin
         if Parent = No_Symbol then
            return;
         end if;

         for I in 1 .. Symbol_Count (Analysis) loop
            declare
               S : constant Symbol_Info := Symbol_At (Analysis, I);
            begin
               if S.Enclosing_Scope = Scope_Id (Natural (Parent))
                 and then S.Parent_Symbol = Parent
                 and then Scoped_Name_Matches (S, Wanted, Wanted_Leaf)
               then
                  Result.Matches.Append (S.Id);
               end if;
            end;
         end loop;
      end Append_Child_Matches;
   begin
      if Name'Length /= Leaf_Name (Name)'Length then
         return;
      end if;

      for I in 1 .. Use_Clause_Count (Analysis) loop
         declare
            Clause : constant Visibility_Clause_Info :=
              Use_Clause_At (Analysis, Scope_Id'Last, I);
         begin
            if Clause_Is_Applicable (Clause) then
               case Clause.Kind is
                  when Visibility_Use_Package_Clause =>
                     Append_Child_Matches (Package_Target (Clause));
                  when Visibility_Use_Type_Clause | Visibility_Use_All_Type_Clause =>
                     Append_Primitive_Operator_Matches (Type_Target (Clause));
                  when others =>
                     null;
               end case;
            end if;
         end;
      end loop;
   end Append_Use_Visible_Matches;


   function Generic_Target_Symbol
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Instance : Editor.Ada_Language_Model.Symbol_Id) return Editor.Ada_Language_Model.Symbol_Id
   is
      use Ada.Strings.Unbounded;
      use Editor.Ada_Language_Model;
   begin
      if Instance = No_Symbol or else Natural (Instance) > Symbol_Count (Analysis) then
         return No_Symbol;
      end if;

      declare
         Inst : constant Symbol_Info := Symbol (Analysis, Instance);
         Target : constant String := To_String (Inst.Target_Name);
         Normal_Target : constant String := Normalize_Name (Target);
      begin
         if (Inst.Kind /= Symbol_Instantiation
           and then Inst.Kind /= Symbol_Generic_Formal_Package)
          or else Target'Length = 0
        then
            return No_Symbol;
         end if;

         for I in 1 .. Symbol_Count (Analysis) loop
            declare
               S : constant Symbol_Info := Symbol_At (Analysis, I);
            begin
               if (S.Kind = Symbol_Generic_Package or else S.Kind = Symbol_Generic_Subprogram)
                 and then (To_String (S.Normalized_Name) = Normal_Target
                           or else Normalize_Name (Leaf_Name (To_String (S.Name))) = Normal_Target)
               then
                  return S.Id;
               end if;
            end;
         end loop;
      end;

      return No_Symbol;
   end Generic_Target_Symbol;


   function Generic_Formal_Position
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Generic_Unit  : Editor.Ada_Language_Model.Symbol_Id;
      Formal   : String) return Natural
   is
      use Ada.Strings.Unbounded;
      use Editor.Ada_Language_Model;
      Wanted : constant String := Normalize_Name (Formal);
      Pos    : Natural := 0;
   begin
      if Generic_Unit = No_Symbol then
         return 0;
      end if;

      for I in 1 .. Symbol_Count (Analysis) loop
         declare
            S : constant Symbol_Info := Symbol_At (Analysis, I);
         begin
            if (S.Parent_Symbol = Generic_Unit
                or else
                  (Generic_Unit /= No_Symbol
                   and then S.Parent_Symbol = Symbol (Analysis, Generic_Unit).Parent_Symbol
                   and then S.Enclosing_Scope = Symbol (Analysis, Generic_Unit).Enclosing_Scope))
              and then (S.Kind = Symbol_Generic_Formal_Type
                        or else S.Kind = Symbol_Generic_Formal_Object
                        or else S.Kind = Symbol_Generic_Formal_Subprogram
                        or else S.Kind = Symbol_Generic_Formal_Package)
            then
               Pos := Pos + 1;
               if To_String (S.Normalized_Name) = Wanted then
                  return Pos;
               end if;
            end if;
         end;
      end loop;

      return 0;
   end Generic_Formal_Position;


   function Generic_Actual_For_Formal
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Instance : Editor.Ada_Language_Model.Symbol_Id;
      Generic_Unit  : Editor.Ada_Language_Model.Symbol_Id;
      Formal   : String) return String
   is
      use Ada.Strings.Unbounded;
      use Editor.Ada_Language_Model;
      Wanted : constant String := Normalize_Name (Formal);
      Pos    : constant Natural := Generic_Formal_Position (Analysis, Generic_Unit, Formal);
   begin
      if Instance = No_Symbol or else Formal'Length = 0 then
         return "";
      end if;

      for I in 1 .. Generic_Actual_Count (Analysis, Instance) loop
         declare
            A : constant Generic_Actual_Info := Generic_Actual_At (Analysis, Instance, I);
         begin
            if To_String (A.Normalized_Formal_Name) = Wanted
              and then To_String (A.Actual_Name)'Length /= 0
            then
               return To_String (A.Actual_Name);
            end if;
         end;
      end loop;

      if Pos /= 0 then
         for I in 1 .. Generic_Actual_Count (Analysis, Instance) loop
            declare
               A : constant Generic_Actual_Info := Generic_Actual_At (Analysis, Instance, I);
            begin
               if To_String (A.Formal_Name)'Length = 0
                 and then A.Position = Pos
                 and then To_String (A.Actual_Name)'Length /= 0
               then
                  return To_String (A.Actual_Name);
               end if;
            end;
         end loop;
      end if;

      return "";
   end Generic_Actual_For_Formal;


   function Generic_Instance_For_Candidate
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Selected_Name : String;
      From_Scope    : Editor.Ada_Language_Model.Symbol_Id;
      Candidate : Editor.Ada_Language_Model.Symbol_Info) return Editor.Ada_Language_Model.Symbol_Id
   is
      use Editor.Ada_Language_Model;
      Prefix : constant String := Prefix_Name (Selected_Name);
   begin
      if Prefix'Length = 0 then
         return No_Symbol;
      end if;

      declare
         Prefix_Result : constant Resolution_Result := Resolve_In_Scope (Analysis, Prefix, From_Scope);
      begin
         for P of Prefix_Result.Matches loop
            if Natural (P) <= Symbol_Count (Analysis)
              and then (Symbol (Analysis, P).Kind = Symbol_Instantiation
                        or else Symbol (Analysis, P).Kind = Symbol_Generic_Formal_Package)
              and then Generic_Target_Symbol (Analysis, P) = Candidate.Parent_Symbol
            then
               return P;
            end if;
         end loop;
      end;

      return No_Symbol;
   end Generic_Instance_For_Candidate;


   function Substitute_Generic_Actual_Type
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Instance : Editor.Ada_Language_Model.Symbol_Id;
      Generic_Unit  : Editor.Ada_Language_Model.Symbol_Id;
      Type_Text : String) return String
   is
      use Ada.Strings.Unbounded;
      use Editor.Ada_Language_Model;
      Clean : constant String := Ada.Strings.Fixed.Trim (Type_Text, Ada.Strings.Both);
      Normal : constant String := Normalize_Name (Clean);
   begin
      if Instance = No_Symbol or else Generic_Unit = No_Symbol or else Clean'Length = 0 then
         return Clean;
      end if;

      for I in 1 .. Symbol_Count (Analysis) loop
         declare
            S : constant Symbol_Info := Symbol_At (Analysis, I);
         begin
            if (S.Parent_Symbol = Generic_Unit
                or else
                  (Generic_Unit /= No_Symbol
                   and then S.Parent_Symbol = Symbol (Analysis, Generic_Unit).Parent_Symbol
                   and then S.Enclosing_Scope = Symbol (Analysis, Generic_Unit).Enclosing_Scope))
              and then (S.Kind = Symbol_Generic_Formal_Type
                        or else S.Kind = Symbol_Generic_Formal_Object
                        or else S.Kind = Symbol_Generic_Formal_Subprogram
                        or else S.Kind = Symbol_Generic_Formal_Package)
              and then (To_String (S.Normalized_Name) = Normal
                        or else Normalize_Name (Leaf_Name (To_String (S.Name))) = Normal)
            then
               declare
                  Actual : constant String := Generic_Actual_For_Formal
                    (Analysis, Instance, Generic_Unit, To_String (S.Name));
               begin
                  if Actual'Length /= 0 then
                     return Actual;
                  end if;
               end;
            end if;
         end;
      end loop;

      return Clean;
   end Substitute_Generic_Actual_Type;

   function Resolve_In_Scope
     (Analysis   : Editor.Ada_Language_Model.Analysis_Result;
      Name       : String;
      From_Scope : Editor.Ada_Language_Model.Symbol_Id) return Resolution_Result
   is
      use Editor.Ada_Language_Model;
      Wanted : constant String := Normalize_Name (Name);
      Wanted_Leaf : constant String := Normalize_Name (Leaf_Name (Name));
      Selected : constant Boolean := Name'Length /= Leaf_Name (Name)'Length;
      Result : Resolution_Result;
      Current : Symbol_Id := From_Scope;
      Steps   : Natural := 0;
   begin
      if From_Scope /= No_Symbol then
         if Natural (From_Scope) > Symbol_Count (Analysis) then
            --  an invalid lexical scope stamp must not silently walk
            --  back to the root scope.  Stale outline/navigation/semantic callers
            --  can otherwise resolve root declarations through a scope id that no
            --  longer exists in the bounded analysis result.
            Result.Overflow := Editor.Ada_Language_Model.Overflowed (Analysis);
            return Result;
         end if;

         if not Is_Declaration_Owner (Symbol (Analysis, From_Scope).Kind) then
            --  a numerically valid symbol id is not necessarily a
            --  lexical scope.  Value-like rows such as objects, components, or
            --  literals must not be accepted as resolver starting scopes, or
            --  malformed rows with matching Enclosing_Scope metadata can leak
            --  into Outline/navigation and semantic-colouring resolution.
            Result.Overflow := Editor.Ada_Language_Model.Overflowed (Analysis);
            return Result;
         end if;
      end if;

      --  First prefer exact dotted unit names preserved by the parser.  This is
      --  deterministic support for selected names without claiming GNAT-grade
      --  visibility or use-clause semantics.
      if Selected then
         for I in 1 .. Symbol_Count (Analysis) loop
            declare
               S : constant Symbol_Info := Symbol_At (Analysis, I);
               N : constant String := Ada.Strings.Unbounded.To_String (S.Normalized_Name);
            begin
               if N = Wanted
                 and then Scope_Is_Visible (Analysis, S.Enclosing_Scope, From_Scope)
               then
                  --  exact dotted declarations are still preferred,
                  --  but they must be root-owned units or declarations visible
                  --  from the caller's lexical scope chain.  Otherwise an
                  --  unrelated nested declaration with the same preserved
                  --  selected spelling can leak into semantic colouring or
                  --  navigation from another scope.
                  Result.Matches.Append (S.Id);
               end if;
            end;
         end loop;
         if not Result.Matches.Is_Empty then
            Result.Overflow := Editor.Ada_Language_Model.Overflowed (Analysis);
            return Result;
         end if;

         --  If the exact selected name was not preserved as one declaration
         --  name, resolve the prefix in the current lexical chain and then
         --  resolve the leaf inside each matching prefix symbol.  This covers
         --  common in-buffer selected names such as Pkg.Type while retaining
         --  overload sets in the selected scope.
         declare
            Prefix : constant String := Prefix_Name (Name);
            Leaf   : constant String := Leaf_Name (Name);
            Prefix_Result : constant Resolution_Result :=
              Resolve_In_Scope (Analysis, Prefix, From_Scope);
         begin
            for P of Prefix_Result.Matches loop
               for I in 1 .. Symbol_Count (Analysis) loop
                  declare
                     S : constant Symbol_Info := Symbol_At (Analysis, I);
                  begin
                     if S.Enclosing_Scope = Scope_Id (Natural (P))
                       and then S.Parent_Symbol = P
                       and then Ada.Strings.Unbounded.To_String (S.Normalized_Name) =
                         Normalize_Name (Leaf)
                     then
                        --  selected-prefix lookup must use the same
                        --  synchronized ownership boundary as child and
                        --  overload enumeration.  After Pkg resolves, Pkg.Name
                        --  may bind only to a direct declaration whose lexical
                        --  scope and parent symbol both name P.  A malformed row
                        --  with Enclosing_Scope = P but Parent_Symbol = Other
                        --  must not leak into semantic colouring/navigation as a
                        --  selected child of P.
                        Result.Matches.Append (S.Id);
                     end if;
                  end;
               end loop;

               --  selected-name lookup through a generic package
               --  instance exposes declarations retained inside the generic
               --  template as an expanded, conservative instance view.  The
               --  resolver returns the template symbol id so existing semantic
               --  colouring/navigation can keep using Symbol_Id sets, while
               --  call overload filtering substitutes retained generic actuals
               --  before comparing formal parameter types.
               declare
                  Generic_Target : constant Symbol_Id := Generic_Target_Symbol (Analysis, P);
               begin
                  if Generic_Target /= No_Symbol then
                     for I in 1 .. Symbol_Count (Analysis) loop
                        declare
                           S : constant Symbol_Info := Symbol_At (Analysis, I);
                        begin
                           if S.Enclosing_Scope = Scope_Id (Natural (Generic_Target))
                             and then S.Parent_Symbol = Generic_Target
                             and then Ada.Strings.Unbounded.To_String (S.Normalized_Name) =
                               Normalize_Name (Leaf)
                           then
                              Result.Matches.Append (S.Id);
                           end if;
                        end;
                     end loop;
                  end if;
               end;
            end loop;

            if Prefix_Result.Matches.Is_Empty
              and then From_Scope = No_Symbol
            then
               for Prefix_Index in 1 .. Symbol_Count (Analysis) loop
                  declare
                     P_Info : constant Symbol_Info := Symbol_At (Analysis, Prefix_Index);
                     P : constant Symbol_Id := P_Info.Id;
                  begin
                     if Ada.Strings.Unbounded.To_String (P_Info.Normalized_Name) =
                       Normalize_Name (Prefix)
                     then
                        for I in 1 .. Symbol_Count (Analysis) loop
                           declare
                              S : constant Symbol_Info := Symbol_At (Analysis, I);
                           begin
                              if S.Enclosing_Scope = Scope_Id (Natural (P))
                                and then S.Parent_Symbol = P
                                and then Ada.Strings.Unbounded.To_String (S.Normalized_Name) =
                                  Normalize_Name (Leaf)
                              then
                                 Result.Matches.Append (S.Id);
                              end if;
                           end;
                        end loop;

                        declare
                           Generic_Target : constant Symbol_Id := Generic_Target_Symbol (Analysis, P);
                        begin
                           if Generic_Target /= No_Symbol then
                              for I in 1 .. Symbol_Count (Analysis) loop
                                 declare
                                    S : constant Symbol_Info := Symbol_At (Analysis, I);
                                 begin
                                    if S.Enclosing_Scope = Scope_Id (Natural (Generic_Target))
                                      and then S.Parent_Symbol = Generic_Target
                                      and then Ada.Strings.Unbounded.To_String (S.Normalized_Name) =
                                        Normalize_Name (Leaf)
                                    then
                                       Result.Matches.Append (S.Id);
                                    end if;
                                 end;
                              end loop;
                           end if;
                        end;
                     end if;
                  end;
               end loop;
            end if;
            if not Result.Matches.Is_Empty then
               Result.Overflow := Editor.Ada_Language_Model.Overflowed (Analysis) or else Prefix_Result.Overflow;
               return Result;
            end if;
         end;

         --  scoped selected-name lookup has the same false-positive
         --  boundary as compatibility Resolve.  If neither an exact selected
         --  declaration nor a resolved selected prefix produced a child match,
         --  the query must degrade to no match.  Falling through into the
         --  ordinary lexical leaf walk would let Missing.Widget bind to an
         --  unrelated direct Widget in the current scope.
         Result.Overflow := Editor.Ada_Language_Model.Overflowed (Analysis);
         return Result;
      end if;

      --  Walk the actual lexical parent chain.  The first scope with one or
      --  more matching declarations wins; multiple matches in that same scope
      --  are retained as an overload set.
      loop
         --  malformed parser/test data can create a cyclic parent
         --  chain even when the starting scope id itself is in range.  Bound
         --  lexical walking by the number of retained symbols so stale or
         --  corrupt scope ownership degrades to no match instead of looping
         --  indefinitely in semantic colouring or outline navigation.
         exit when Steps > Symbol_Count (Analysis);
         Steps := Steps + 1;

         if Current /= No_Symbol
           and then Natural (Current) > Symbol_Count (Analysis)
         then
            --  do not perform one lookup iteration through an
            --  impossible parent scope.  Corrupt Parent_Symbol metadata can
            --  otherwise set Current to a stale id and expose orphaned rows
            --  whose Enclosing_Scope carries that same impossible number.
            Result.Matches.Clear;
            exit;
         end if;

         if Current /= No_Symbol
           and then not Is_Declaration_Owner (Symbol (Analysis, Current).Kind)
         then
            --  parent-chain walking must also stop if corrupt
            --  metadata reaches a value-like symbol.  Only declaration-owning
            --  symbols may act as lexical scopes for scoped resolver lookup.
            Result.Matches.Clear;
            exit;
         end if;

         for I in 1 .. Symbol_Count (Analysis) loop
            declare
               S : constant Symbol_Info := Symbol_At (Analysis, I);
            begin
               if S.Enclosing_Scope = Scope_Id (Natural (Current))
                 and then Scoped_Name_Matches (S, Wanted, Wanted_Leaf)
               then
                  Result.Matches.Append (S.Id);
               end if;
            end;
         end loop;

         exit when not Result.Matches.Is_Empty;
         exit when Current = No_Symbol;
         Current := Symbol (Analysis, Current).Parent_Symbol;
      end loop;

      if Result.Matches.Is_Empty then
         Append_Use_Visible_Matches (Analysis, Name, From_Scope, Result);
      end if;

      if Result.Matches.Is_Empty
        and then From_Scope = No_Symbol
      then
         for I in 1 .. Symbol_Count (Analysis) loop
            declare
               S : constant Symbol_Info := Symbol_At (Analysis, I);
            begin
               if Scoped_Name_Matches (S, Wanted, Wanted_Leaf) then
                  Result.Matches.Append (S.Id);
               end if;
            end;
         end loop;
      end if;

      Result.Overflow := Editor.Ada_Language_Model.Overflowed (Analysis);
      return Result;
   end Resolve_In_Scope;


   function Trimmed_Text (Value : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both);
   end Trimmed_Text;

   function Strip_Default_Text (Value : String) return String is
      P : constant Natural := Ada.Strings.Fixed.Index (Value, ":=");
   begin
      if P = 0 then
         return Value;
      elsif P = Value'First then
         return "";
      else
         return Value (Value'First .. P - 1);
      end if;
   end Strip_Default_Text;

   function Strip_Mode_Text (Value : String) return String is
      Text : constant String := Editor.Ada_Language_Model.Normalize_Name
        (Trimmed_Text (Strip_Default_Text (Value)));

      function Drop (Word : String) return String is
      begin
         if Text'Length = Word'Length then
            return "";
         elsif Text'Length > Word'Length
           and then Text (Text'First .. Text'First + Word'Length - 1) = Word
           and then Text (Text'First + Word'Length) = ' '
         then
            return Trimmed_Text (Text (Text'First + Word'Length + 1 .. Text'Last));
         else
            return Text;
         end if;
      end Drop;
   begin
      if Text'Length >= 8
        and then Text (Text'First .. Text'First + 7) = "not null"
      then
         return Drop ("not null");
      elsif Text'Length >= 8
        and then Text (Text'First .. Text'First + 7) = "constant"
      then
         return Drop ("constant");
      elsif Text'Length >= 7
        and then Text (Text'First .. Text'First + 6) = "aliased"
      then
         return Drop ("aliased");
      elsif Text'Length >= 6
        and then Text (Text'First .. Text'First + 5) = "access"
      then
         return Drop ("access");
      elsif Text'Length >= 6
        and then Text (Text'First .. Text'First + 5) = "in out"
      then
         return Drop ("in out");
      elsif Text'Length >= 3
        and then Text (Text'First .. Text'First + 2) = "out"
      then
         return Drop ("out");
      elsif Text'Length >= 2
        and then Text (Text'First .. Text'First + 1) = "in"
      then
         return Drop ("in");
      else
         return Trimmed_Text (Text);
      end if;
   end Strip_Mode_Text;

   function Return_Type_From_Profile (Profile : String) return String is
      Normal : constant String := Editor.Ada_Language_Model.Normalize_Name (Profile);
      Pos    : constant Natural := Ada.Strings.Fixed.Index (Normal, " return ");
   begin
      if Pos = 0 then
         return "";
      end if;
      return Strip_Mode_Text (Normal (Pos + 8 .. Normal'Last));
   end Return_Type_From_Profile;

   function Declaration_Type_From_Profile (Profile : String) return String is
      Clean : constant String := Trimmed_Text (Profile);
      Colon : constant Natural := Ada.Strings.Fixed.Index (Clean, ":");
      Stop  : Natural := Clean'Last;
   begin
      if Clean'Length = 0 or else Colon = 0 or else Colon = Clean'Last then
         return "";
      end if;

      declare
         Tail : constant String := Clean (Colon + 1 .. Clean'Last);
         Semi : constant Natural := Ada.Strings.Fixed.Index (Tail, ";");
         Assign : constant Natural := Ada.Strings.Fixed.Index (Tail, ":=");
      begin
         Stop := Tail'Last;
         if Semi /= 0 then
            Stop := Natural'Min (Stop, Tail'First + Semi - 2);
         end if;
         if Assign /= 0 then
            Stop := Natural'Min (Stop, Tail'First + Assign - 2);
         end if;
         if Stop < Tail'First then
            return "";
         end if;
         return Strip_Mode_Text (Tail (Tail'First .. Stop));
      end;
   end Declaration_Type_From_Profile;

   function Is_Integer_Literal_Text (Text : String) return Boolean is
      Clean : constant String := Trimmed_Text (Text);
      Has_Digit : Boolean := False;
   begin
      if Clean'Length = 0 then
         return False;
      end if;
      for C of Clean loop
         if C in '0' .. '9' then
            Has_Digit := True;
         elsif C = '_' or else C = '#' then
            null;
         else
            return False;
         end if;
      end loop;
      return Has_Digit;
   end Is_Integer_Literal_Text;

   function Is_Real_Literal_Text (Text : String) return Boolean is
      Clean : constant String := Trimmed_Text (Text);
      Has_Digit : Boolean := False;
      Has_Point : Boolean := False;
   begin
      if Clean'Length = 0 then
         return False;
      end if;
      for C of Clean loop
         if C in '0' .. '9' then
            Has_Digit := True;
         elsif C = '.' then
            Has_Point := True;
         elsif C = '_' or else C = '#' or else C = 'e' or else C = 'E'
           or else C = '+' or else C = '-'
         then
            null;
         else
            return False;
         end if;
      end loop;
      return Has_Digit and then Has_Point;
   end Is_Real_Literal_Text;

   function Top_Level_Operator (Text : String; Operator : String) return Natural is
      Depth : Natural := 0;
   begin
      if Text'Length < Operator'Length or else Operator'Length = 0 then
         return 0;
      end if;
      for I in Text'First .. Text'Last - Operator'Length + 1 loop
         if Text (I) = '(' then
            Depth := Depth + 1;
         elsif Text (I) = ')' then
            if Depth > 0 then
               Depth := Depth - 1;
            end if;
         elsif Depth = 0
           and then Text (I .. I + Operator'Length - 1) = Operator
         then
            return I;
         end if;
      end loop;
      return 0;
   end Top_Level_Operator;

   function Matching_Open_Paren (Text : String) return Natural is
      Depth : Natural := 0;
   begin
      if Text'Length = 0 or else Text (Text'Last) /= ')' then
         return 0;
      end if;
      for I in reverse Text'Range loop
         if Text (I) = ')' then
            Depth := Depth + 1;
         elsif Text (I) = '(' then
            if Depth = 0 then
               return 0;
            end if;
            Depth := Depth - 1;
            if Depth = 0 then
               return I;
            end if;
         end if;
      end loop;
      return 0;
   end Matching_Open_Paren;

   function Quoted_Operator_Name (Operator : String) return String is
      Quote : constant Character := Character'Val (16#22#);
   begin
      return String'(1 => Quote) & Operator & String'(1 => Quote);
   end Quoted_Operator_Name;

   function Top_Level_Binary_Operator (Text : String; Operator : String) return Natural is
      Pos : Natural := Top_Level_Operator (Text, Operator);

      function Is_Name_Character (C : Character) return Boolean is
      begin
         return C in 'A' .. 'Z' or else C in 'a' .. 'z'
           or else C in '0' .. '9' or else C = '_';
      end Is_Name_Character;

      function Has_Word_Boundary return Boolean is
      begin
         if not (Operator (Operator'First) in 'A' .. 'Z'
                 or else Operator (Operator'First) in 'a' .. 'z')
         then
            return True;
         end if;

         return (Pos = Text'First or else not Is_Name_Character (Text (Pos - 1)))
           and then (Pos + Operator'Length > Text'Last
                     or else not Is_Name_Character (Text (Pos + Operator'Length)));
      end Has_Word_Boundary;
   begin
      while Pos /= 0 loop
         --  A leading + or - is a sign, not a binary operator.  Also avoid
         --  splitting an exponent sign inside a numeric literal.  Word
         --  operators require identifier boundaries so names like Candy do not
         --  get split at an embedded ``and``.  This is not a full expression
         --  parser; it is the bounded expression typer used by overload
         --  filtering, so it deliberately recognizes only safe top-level
         --  binary forms.
         if Pos > Text'First
           and then Has_Word_Boundary
           and then not
             ((Operator = "+" or else Operator = "-")
              and then Pos > Text'First
              and then (Text (Pos - 1) = 'e' or else Text (Pos - 1) = 'E'))
         then
            return Pos;
         end if;

         if Pos + Operator'Length > Text'Last then
            return 0;
         end if;

         declare
            Tail : constant String := Text (Pos + Operator'Length .. Text'Last);
            Next : constant Natural := Top_Level_Operator (Tail, Operator);
         begin
            if Next = 0 then
               return 0;
            end if;
            Pos := Pos + Operator'Length + Next - 1;
         end;
      end loop;
      return 0;
   end Top_Level_Binary_Operator;

   function Inferred_Type_From_Symbol
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Id       : Editor.Ada_Language_Model.Symbol_Id) return String
   is
      use Ada.Strings.Unbounded;
      use Editor.Ada_Language_Model;
      S : constant Symbol_Info := Symbol (Analysis, Id);
      Profile : constant String := To_String (S.Profile_Summary);
   begin
      case S.Kind is
         when Symbol_Object | Symbol_Constant | Symbol_Generic_Formal_Object =>
            declare
               From_Profile : constant String := Declaration_Type_From_Profile (Profile);
            begin
               if From_Profile'Length /= 0 then
                  return From_Profile;
               else
                  return To_String (S.Target_Name);
               end if;
            end;
         when Symbol_Function | Symbol_Operator_Function =>
            declare
               From_Profile : constant String := Return_Type_From_Profile (Profile);
            begin
               if From_Profile'Length /= 0 then
                  return From_Profile;
               else
                  return To_String (S.Target_Name);
               end if;
            end;
         when Symbol_Type | Symbol_Subtype | Symbol_Record_Type =>
            return To_String (S.Name);
         when Symbol_Enumeration_Literal =>
            if S.Parent_Symbol /= No_Symbol then
               return To_String (Symbol (Analysis, S.Parent_Symbol).Name);
            end if;
            return "";
         when others =>
            return "";
      end case;
   end Inferred_Type_From_Symbol;

   function Effective_Inferred_Type_From_Symbol
     (Analysis   : Editor.Ada_Language_Model.Analysis_Result;
      Expression : String;
      From_Scope : Editor.Ada_Language_Model.Symbol_Id;
      Id         : Editor.Ada_Language_Model.Symbol_Id) return String
   is
      use Editor.Ada_Language_Model;
      Base : constant String := Inferred_Type_From_Symbol (Analysis, Id);
   begin
      if Base'Length = 0 then
         return "";
      end if;

      --  expression inference through a selected generic package
      --  instance must substitute the instance actual for formal result/object
      --  types.  Resolve_In_Scope returns the retained template symbol id for
      --  Instance.Child, so callers need this small effective-view layer;
      --  otherwise Instance.Object and Instance.Function_Call would infer the
      --  formal name (for example Element) and reject valid overloads expecting
      --  the actual type (for example Count).
      declare
         Candidate : constant Symbol_Info := Symbol (Analysis, Id);
         Instance  : constant Symbol_Id :=
           Generic_Instance_For_Candidate
             (Analysis, Expression, From_Scope, Candidate);
      begin
         if Instance = No_Symbol then
            return Base;
         end if;

         return Substitute_Generic_Actual_Type
           (Analysis, Instance, Candidate.Parent_Symbol, Base);
      end;
   end Effective_Inferred_Type_From_Symbol;

   function Infer_Expression_Type_In_Scope
     (Analysis   : Editor.Ada_Language_Model.Analysis_Result;
      Expression : String;
      From_Scope : Editor.Ada_Language_Model.Symbol_Id) return String
   is
      use Ada.Strings.Unbounded;
      use Editor.Ada_Language_Model;
      Clean : constant String := Trimmed_Text (Expression);
      Lower : constant String := Normalize_Name (Clean);
      Tick  : constant Character := Character'Val (16#27#);
   begin
      if Clean'Length = 0 then
         return "";
      end if;

      declare
         Open_Pos : constant Natural := Matching_Open_Paren (Clean);
      begin
         if Open_Pos = Clean'First
           and then Clean (Clean'Last) = ')'
           and then Clean'Length > 2
         then
            return Infer_Expression_Type_In_Scope
              (Analysis, Clean (Clean'First + 1 .. Clean'Last - 1), From_Scope);
         end if;
      end;

      --  Ada 2012 conditional expressions are common inside actual
      --  parameters.  Infer their result type conservatively when the
      --  condition is Boolean and both branches have a compatible inferred
      --  type.  This keeps overload filtering expression-aware without
      --  treating unknown branch expressions as wildcards.
      if Lower'Length > 3
        and then Lower (Lower'First .. Lower'First + 2) = "if "
      then
         declare
            Then_Pos : constant Natural := Top_Level_Binary_Operator (Lower, "then");
            Else_Pos : constant Natural := Top_Level_Binary_Operator (Lower, "else");
         begin
            if Then_Pos /= 0
              and then Else_Pos /= 0
              and then Then_Pos > Lower'First + 2
              and then Else_Pos > Then_Pos + 4
              and then Else_Pos + 4 <= Clean'Last
            then
               declare
                  Condition_Expr : constant String := Trimmed_Text
                    (Clean (Clean'First + 3 .. Then_Pos - 1));
                  Then_Expr : constant String := Trimmed_Text
                    (Clean (Then_Pos + 4 .. Else_Pos - 1));
                  Else_Expr : constant String := Trimmed_Text
                    (Clean (Else_Pos + 4 .. Clean'Last));
                  Condition_Type : constant String := Infer_Expression_Type_In_Scope
                    (Analysis, Condition_Expr, From_Scope);
                  Then_Type : constant String := Infer_Expression_Type_In_Scope
                    (Analysis, Then_Expr, From_Scope);
                  Else_Type : constant String := Infer_Expression_Type_In_Scope
                    (Analysis, Else_Expr, From_Scope);
               begin
                  if Normalize_Name (Leaf_Name (Condition_Type)) /= "boolean"
                    or else Then_Type'Length = 0
                    or else Else_Type'Length = 0
                  then
                     return "";
                  end if;

                  if Then_Type = Else_Type then
                     return Then_Type;
                  elsif Then_Type = "universal_integer"
                    and then Else_Type /= "universal_real"
                  then
                     return Else_Type;
                  elsif Else_Type = "universal_integer"
                    and then Then_Type /= "universal_real"
                  then
                     return Then_Type;
                  elsif Then_Type = "universal_real"
                    and then Else_Type = "universal_real"
                  then
                     return "universal_real";
                  end if;
               end;
            end if;
         end;
      end if;

      if Clean'Length > 1
        and then (Clean (Clean'First) = '+' or else Clean (Clean'First) = '-')
      then
         declare
            Tail : constant String := Trimmed_Text (Clean (Clean'First + 1 .. Clean'Last));
         begin
            if Is_Real_Literal_Text (Tail) then
               return "universal_real";
            elsif Is_Integer_Literal_Text (Tail) then
               return "universal_integer";
            end if;
         end;
      end if;

      if Lower = "true" or else Lower = "false" then
         return "Boolean";
      elsif Lower = "null" then
         return "access";
      elsif Lower'Length > 4
        and then Lower (Lower'First .. Lower'First + 3) = "not "
      then
         declare
            Operand : constant String := Trimmed_Text
              (Clean (Clean'First + 4 .. Clean'Last));
            Operand_Type : constant String := Infer_Expression_Type_In_Scope
              (Analysis, Operand, From_Scope);
         begin
            if Normalize_Name (Leaf_Name (Operand_Type)) = "boolean" then
               return "Boolean";
            end if;

            declare
               Operator_Result : constant Resolution_Result :=
                 Resolve_Call_Expression_In_Scope
                   (Analysis, Quoted_Operator_Name ("not"), From_Scope, Operand);
            begin
               if Natural (Operator_Result.Matches.Length) = 1 then
                  return Inferred_Type_From_Symbol
                    (Analysis, Operator_Result.Matches.First_Element);
               end if;
            end;

            return "";
         end;
      elsif Lower'Length > 4
        and then Lower (Lower'First .. Lower'First + 3) = "abs "
      then
         declare
            Operand : constant String := Trimmed_Text
              (Clean (Clean'First + 4 .. Clean'Last));
            Operand_Type : constant String := Infer_Expression_Type_In_Scope
              (Analysis, Operand, From_Scope);
         begin
            if Operand_Type'Length /= 0 then
               declare
                  Operator_Result : constant Resolution_Result :=
                    Resolve_Call_Expression_In_Scope
                      (Analysis, Quoted_Operator_Name ("abs"), From_Scope, Operand);
               begin
                  if Natural (Operator_Result.Matches.Length) = 1 then
                     return Inferred_Type_From_Symbol
                       (Analysis, Operator_Result.Matches.First_Element);
                  end if;
               end;

               return Operand_Type;
            end if;

            return "";
         end;
      elsif Clean'Length >= 2
        and then Clean (Clean'First) = '"'
        and then Clean (Clean'Last) = '"'
      then
         return "String";
      elsif Clean'Length = 3
        and then Clean (Clean'First) = Tick
        and then Clean (Clean'Last) = Tick
      then
         return "Character";
      elsif Is_Real_Literal_Text (Clean) then
         return "universal_real";
      elsif Is_Integer_Literal_Text (Clean) then
         return "universal_integer";
      end if;

      declare
         Tick_Pos : constant Natural := Ada.Strings.Fixed.Index (Clean, String'(1 => Tick));
      begin
         if Tick_Pos /= 0
           and then Tick_Pos < Clean'Last
           and then Clean (Tick_Pos + 1) = '('
           and then Clean (Clean'Last) = ')'
         then
            return Trimmed_Text (Clean (Clean'First .. Tick_Pos - 1));
         end if;
      end;

      declare
         Open_Pos : constant Natural := Matching_Open_Paren (Clean);
      begin
         if Open_Pos /= 0 and then Open_Pos > Clean'First then
            declare
               Prefix : constant String := Trimmed_Text (Clean (Clean'First .. Open_Pos - 1));
               Args   : constant String := Clean (Open_Pos + 1 .. Clean'Last - 1);
               Prefix_Result : constant Resolution_Result :=
                 Resolve_In_Scope (Analysis, Prefix, From_Scope);
            begin
               if Natural (Prefix_Result.Matches.Length) = 1 then
                  declare
                     Prefix_Symbol : constant Symbol_Info :=
                       Symbol (Analysis, Prefix_Result.Matches.First_Element);
                  begin
                     if Prefix_Symbol.Kind = Symbol_Type
                       or else Prefix_Symbol.Kind = Symbol_Subtype
                       or else Prefix_Symbol.Kind = Symbol_Record_Type
                     then
                        return To_String (Prefix_Symbol.Name);
                     end if;
                  end;
               end if;

               declare
                  Call_Result : constant Resolution_Result :=
                    Resolve_Call_Expression_In_Scope
                      (Analysis, Prefix, From_Scope, Args);
               begin
                  if Natural (Call_Result.Matches.Length) = 1 then
                     return Effective_Inferred_Type_From_Symbol
                       (Analysis, Prefix, From_Scope,
                        Call_Result.Matches.First_Element);
                  end if;
               end;
            end;
         end if;
      end;

      declare
         type Operator_Info is record
            Text       : Unbounded_String;
            Comparison : Boolean := False;
            Boolean_Op : Boolean := False;
         end record;
         Operators : constant array (Positive range <>) of Operator_Info :=
           ((To_Unbounded_String ("and then"), False, True),
            (To_Unbounded_String ("or else"), False, True),
            (To_Unbounded_String ("not in"), True, False),
            (To_Unbounded_String ("/="), True, False),
            (To_Unbounded_String ("<="), True, False),
            (To_Unbounded_String (">="), True, False),
            (To_Unbounded_String ("="), True, False),
            (To_Unbounded_String ("<"), True, False),
            (To_Unbounded_String (">"), True, False),
            (To_Unbounded_String ("mod"), False, False),
            (To_Unbounded_String ("rem"), False, False),
            (To_Unbounded_String ("in"), True, False),
            (To_Unbounded_String ("xor"), False, True),
            (To_Unbounded_String ("and"), False, True),
            (To_Unbounded_String ("or"), False, True),
            (To_Unbounded_String ("+"), False, False),
            (To_Unbounded_String ("-"), False, False),
            (To_Unbounded_String ("**"), False, False),
            (To_Unbounded_String ("*"), False, False),
            (To_Unbounded_String ("/"), False, False),
            (To_Unbounded_String ("&"), False, False));
      begin
         for Op of Operators loop
            declare
               Op_Text : constant String := To_String (Op.Text);
               Pos     : constant Natural := Top_Level_Binary_Operator (Clean, Op_Text);
            begin
               if Pos /= 0
                 and then Pos > Clean'First
                 and then Pos + Op_Text'Length <= Clean'Last
               then
                  declare
                     Left_Expr : constant String := Trimmed_Text
                       (Clean (Clean'First .. Pos - 1));
                     Right_Expr : constant String := Trimmed_Text
                       (Clean (Pos + Op_Text'Length .. Clean'Last));
                     Left_Type : constant String := Infer_Expression_Type_In_Scope
                       (Analysis, Left_Expr, From_Scope);
                     Right_Type : constant String := Infer_Expression_Type_In_Scope
                       (Analysis, Right_Expr, From_Scope);
                  begin
                     if Left_Type'Length = 0 or else Right_Type'Length = 0 then
                        return "";
                     end if;

                     if Op.Comparison then
                        return "Boolean";
                     elsif Op.Boolean_Op
                       and then Normalize_Name (Leaf_Name (Left_Type)) = "boolean"
                       and then Normalize_Name (Leaf_Name (Right_Type)) = "boolean"
                     then
                        return "Boolean";
                     end if;

                     declare
                        Operator_Result : constant Resolution_Result :=
                          Resolve_Call_Expression_In_Scope
                            (Analysis, Quoted_Operator_Name (Op_Text), From_Scope,
                             Left_Expr & ", " & Right_Expr);
                     begin
                        if Natural (Operator_Result.Matches.Length) = 1 then
                           return Effective_Inferred_Type_From_Symbol
                             (Analysis, Quoted_Operator_Name (Op_Text), From_Scope,
                              Operator_Result.Matches.First_Element);
                        end if;
                     end;

                     if Left_Type = Right_Type then
                        return Left_Type;
                     elsif Left_Type = "universal_integer"
                       and then Right_Type /= "universal_real"
                     then
                        return Right_Type;
                     elsif Right_Type = "universal_integer"
                       and then Left_Type /= "universal_real"
                     then
                        return Left_Type;
                     elsif Left_Type = "universal_real"
                       and then Right_Type = "universal_real"
                     then
                        return "universal_real";
                     end if;

                     return "";
                  end;
               end if;
            end;
         end loop;
      end;

      declare
         R : constant Resolution_Result := Resolve_In_Scope (Analysis, Clean, From_Scope);
      begin
         if Natural (R.Matches.Length) = 1 then
            return Effective_Inferred_Type_From_Symbol
              (Analysis, Clean, From_Scope, R.Matches.First_Element);
         end if;
      end;

      return "";
   end Infer_Expression_Type_In_Scope;

   function Expression_Profile_From_List
     (Analysis    : Editor.Ada_Language_Model.Analysis_Result;
      Expressions : String;
      From_Scope  : Editor.Ada_Language_Model.Symbol_Id) return String
   is
      use Ada.Strings.Unbounded;
      Result : Unbounded_String;
      Clean  : constant String := Trimmed_Text (Expressions);
      Start  : Natural := Clean'First;
      Depth  : Natural := 0;

      procedure Append_Segment (First, Last : Natural) is
      begin
         if Last < First then
            return;
         end if;
         declare
            Segment : constant String := Trimmed_Text (Clean (First .. Last));
            Arrow   : constant Natural := Top_Level_Operator (Segment, "=>");
            Name_Text : Unbounded_String;
            Expr_Text : Unbounded_String := To_Unbounded_String (Segment);
            Type_Text : Unbounded_String;
         begin
            if Segment'Length = 0 then
               return;
            end if;
            if Arrow /= 0 then
               Name_Text := To_Unbounded_String
                 (Trimmed_Text (Segment (Segment'First .. Arrow - 1)));
               Expr_Text := To_Unbounded_String
                 (Trimmed_Text (Segment (Arrow + 2 .. Segment'Last)));
            end if;
            declare
               Inferred : constant String := Infer_Expression_Type_In_Scope
                 (Analysis, To_String (Expr_Text), From_Scope);
            begin
               if Inferred'Length = 0 then
                  Type_Text := To_Unbounded_String ("<?>");
               else
                  Type_Text := To_Unbounded_String (Inferred);
               end if;
            end;

            if Length (Result) /= 0 then
               Append (Result, ", ");
            end if;
            if Length (Name_Text) /= 0 then
               Append (Result, To_String (Name_Text) & " => ");
            end if;
            Append (Result, To_String (Type_Text));
         end;
      end Append_Segment;
   begin
      if Clean'Length = 0 or else Clean = "()" then
         return "";
      end if;

      for I in Clean'Range loop
         if Clean (I) = '(' then
            Depth := Depth + 1;
         elsif Clean (I) = ')' then
            if Depth > 0 then
               Depth := Depth - 1;
            end if;
         elsif Clean (I) = ',' and then Depth = 0 then
            Append_Segment (Start, I - 1);
            Start := I + 1;
         end if;
      end loop;
      Append_Segment (Start, Clean'Last);
      return To_String (Result);
   end Expression_Profile_From_List;

   function Resolve_Call_Expression_In_Scope
     (Analysis                   : Editor.Ada_Language_Model.Analysis_Result;
      Name                       : String;
      From_Scope                 : Editor.Ada_Language_Model.Symbol_Id;
      Actual_Expressions         : String := "";
      Expected_Result_Expression : String := "") return Resolution_Result
   is
      Actual_Profile : constant String :=
        (if Actual_Expressions'Length = 0 then "()"
         else Expression_Profile_From_List (Analysis, Actual_Expressions, From_Scope));
      Expected_Type  : constant String :=
        (if Expected_Result_Expression'Length = 0 then ""
         else Infer_Expression_Type_In_Scope
           (Analysis, Expected_Result_Expression, From_Scope));
      Empty_Result : Resolution_Result;
   begin
      if Expected_Result_Expression'Length /= 0
        and then Expected_Type'Length = 0
      then
         Empty_Result.Overflow := Editor.Ada_Language_Model.Overflowed (Analysis);
         return Empty_Result;
      end if;

      return Resolve_Call_In_Scope
        (Analysis, Name, From_Scope, Actual_Profile, Expected_Type);
   end Resolve_Call_Expression_In_Scope;



   function Resolve_Call_In_Scope
     (Analysis             : Editor.Ada_Language_Model.Analysis_Result;
      Name                 : String;
      From_Scope           : Editor.Ada_Language_Model.Symbol_Id;
      Actual_Profile       : String := "";
      Expected_Result_Type : String := "") return Resolution_Result
   is
      use Ada.Strings.Unbounded;
      use Editor.Ada_Language_Model;

      Max_Parameters : constant Positive := 32;
      subtype Parameter_Index is Positive range 1 .. Max_Parameters;

      type Parameter_Info is record
         Name        : Unbounded_String;
         Type_Name   : Unbounded_String;
         Has_Name    : Boolean := False;
         Has_Default : Boolean := False;
      end record;

      type Parameter_Array is array (Parameter_Index) of Parameter_Info;

      function Trimmed (Value : String) return String is
      begin
         return Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both);
      end Trimmed;

      function Strip_Default (Value : String) return String is
         P : constant Natural := Ada.Strings.Fixed.Index (Value, ":=");
      begin
         if P = 0 then
            return Value;
         elsif P = Value'First then
            return "";
         else
            return Value (Value'First .. P - 1);
         end if;
      end Strip_Default;

      function Strip_Mode_Words (Value : String) return String is
         Text : constant String := Normalize_Name (Trimmed (Strip_Default (Value)));

         function Drop (Word : String) return String is
         begin
            if Text'Length = Word'Length then
               return "";
            elsif Text'Length > Word'Length
              and then Text (Text'First .. Text'First + Word'Length - 1) = Word
              and then Text (Text'First + Word'Length) = ' '
            then
               return Trimmed (Text (Text'First + Word'Length + 1 .. Text'Last));
            else
               return Text;
            end if;
         end Drop;
      begin
         if Text'Length >= 8
           and then Text (Text'First .. Text'First + 7) = "not null"
         then
            return Drop ("not null");
         elsif Text'Length >= 8
           and then Text (Text'First .. Text'First + 7) = "constant"
         then
            return Drop ("constant");
         elsif Text'Length >= 7
           and then Text (Text'First .. Text'First + 6) = "aliased"
         then
            return Drop ("aliased");
         elsif Text'Length >= 6
           and then Text (Text'First .. Text'First + 5) = "access"
         then
            return Drop ("access");
         elsif Text'Length >= 6
           and then Text (Text'First .. Text'First + 5) = "in out"
         then
            return Drop ("in out");
         elsif Text'Length >= 3
           and then Text (Text'First .. Text'First + 2) = "out"
         then
            return Drop ("out");
         elsif Text'Length >= 2
           and then Text (Text'First .. Text'First + 1) = "in"
         then
            return Drop ("in");
         else
            return Trimmed (Text);
         end if;
      end Strip_Mode_Words;

      function Profile_Parameter_Text (Profile : String) return String is
         Open_Pos  : Natural := 0;
         Close_Pos : Natural := 0;
         Depth     : Natural := 0;
      begin
         for I in Profile'Range loop
            if Profile (I) = '(' then
               if Depth = 0 and then Open_Pos = 0 then
                  Open_Pos := I;
               end if;
               Depth := Depth + 1;
            elsif Profile (I) = ')' then
               if Depth > 0 then
                  Depth := Depth - 1;
                  if Depth = 0 then
                     Close_Pos := I;
                     exit;
                  end if;
               end if;
            end if;
         end loop;

         if Open_Pos = 0 or else Close_Pos <= Open_Pos then
            return "";
         end if;

         return Profile (Open_Pos + 1 .. Close_Pos - 1);
      end Profile_Parameter_Text;

      function Profile_Return_Type (Profile : String) return String is
         Normal : constant String := Normalize_Name (Profile);
         Pos    : constant Natural := Ada.Strings.Fixed.Index (Normal, " return ");
      begin
         if Pos = 0 then
            return "";
         end if;

         return Strip_Mode_Words (Normal (Pos + 8 .. Normal'Last));
      end Profile_Return_Type;

      procedure Append_Actual
        (Items       : in out Parameter_Array;
         Count       : in out Natural;
         Name_Text   : String;
         Type_Text   : String;
         Has_Name    : Boolean;
         Has_Default : Boolean := False) is
      begin
         if Count >= Max_Parameters then
            return;
         end if;

         Count := Count + 1;
         Items (Count).Name := To_Unbounded_String (Normalize_Name (Trimmed (Name_Text)));
         Items (Count).Type_Name := To_Unbounded_String (Strip_Mode_Words (Type_Text));
         Items (Count).Has_Name := Has_Name;
         Items (Count).Has_Default := Has_Default;
      end Append_Actual;

      procedure Parse_Actual_Profile
        (Text  : String;
         Items : in out Parameter_Array;
         Count : in out Natural) is
         Clean_First : Natural := Text'First;
         Clean_Last  : Natural := Text'Last;
         Start       : Natural := Text'First;
         Depth       : Natural := 0;

         procedure Add_Segment (First, Last : Natural) is
         begin
            if Last < First then
               return;
            end if;
            declare
               Segment : constant String := Trimmed (Text (First .. Last));
               Arrow   : constant Natural := Ada.Strings.Fixed.Index (Segment, "=>");
            begin
               if Segment'Length = 0 then
                  return;
               elsif Arrow /= 0 then
                  Append_Actual
                    (Items, Count,
                     Segment (Segment'First .. Arrow - 1),
                     Segment (Arrow + 2 .. Segment'Last),
                     True);
               else
                  Append_Actual (Items, Count, "", Segment, False);
               end if;
            end;
         end Add_Segment;
      begin
         if Text'Length = 0 then
            return;
         end if;

         declare
            Clean : constant String := Trimmed (Text);
         begin
            if Clean = "()" then
               return;
            elsif Clean'Length >= 2
              and then Clean (Clean'First) = '('
              and then Clean (Clean'Last) = ')'
            then
               Clean_First := Clean'First + 1;
               Clean_Last := Clean'Last - 1;
               Start := Clean_First;
            else
               Clean_First := Clean'First;
               Clean_Last := Clean'Last;
               Start := Clean_First;
            end if;
         end;

         for I in Clean_First .. Clean_Last loop
            if Text (I) = '(' then
               Depth := Depth + 1;
            elsif Text (I) = ')' then
               if Depth > 0 then
                  Depth := Depth - 1;
               end if;
            elsif Text (I) = ',' and then Depth = 0 then
               Add_Segment (Start, I - 1);
               Start := I + 1;
            end if;
         end loop;
         Add_Segment (Start, Clean_Last);
      end Parse_Actual_Profile;

      procedure Parse_Formal_Profile
        (Profile : String;
         Items   : in out Parameter_Array;
         Count   : in out Natural) is
         Text  : constant String := Profile_Parameter_Text (Profile);
         Start : Natural := Text'First;
         Depth : Natural := 0;

         procedure Add_Segment (First, Last : Natural) is
         begin
            if Text'Length = 0 or else Last < First then
               return;
            end if;
            declare
               Segment : constant String := Trimmed (Text (First .. Last));
               Colon   : constant Natural := Ada.Strings.Fixed.Index (Segment, ":");
            begin
               if Segment'Length = 0 or else Colon = 0 then
                  return;
               end if;

               declare
                  Names : constant String := Segment (Segment'First .. Colon - 1);
                  Typ   : constant String := Segment (Colon + 1 .. Segment'Last);
                  Defaulted : constant Boolean :=
                    Ada.Strings.Fixed.Index (Typ, ":=") /= 0;
                  Name_Start : Natural := Names'First;
               begin
                  for J in Names'Range loop
                     if Names (J) = ',' then
                        Append_Actual
                          (Items, Count, Names (Name_Start .. J - 1), Typ, True, Defaulted);
                        Name_Start := J + 1;
                     end if;
                  end loop;
                  Append_Actual
                    (Items, Count, Names (Name_Start .. Names'Last), Typ, True, Defaulted);
               end;
            end;
         end Add_Segment;
      begin
         if Text'Length = 0 then
            return;
         end if;

         for I in Text'Range loop
            if Text (I) = '(' then
               Depth := Depth + 1;
            elsif Text (I) = ')' then
               if Depth > 0 then
                  Depth := Depth - 1;
               end if;
            elsif Text (I) = ';' and then Depth = 0 then
               Add_Segment (Start, I - 1);
               Start := I + 1;
            end if;
         end loop;
         Add_Segment (Start, Text'Last);
      end Parse_Formal_Profile;

      function Types_Compatible (Actual_Type, Formal_Type : String) return Boolean is
         A : constant String := Normalize_Name (Trimmed (Actual_Type));
         F : constant String := Normalize_Name (Trimmed (Formal_Type));
      begin
         if A'Length = 0 then
            return True;
         end if;

         if A = "universal_integer" then
            return F = "integer" or else F = "natural" or else F = "positive"
              or else F = "long_integer" or else F = "short_integer"
              or else F = "long_long_integer"
              or else Leaf_Name (F) = "integer";
         elsif A = "universal_real" then
            return F = "float" or else F = "long_float"
              or else F = "long_long_float" or else F = "short_float"
              or else Leaf_Name (F) = "float";
         end if;

         return A = F
           or else Leaf_Name (A) = Leaf_Name (F)
           or else A = Normalize_Name (Leaf_Name (F))
           or else Normalize_Name (Leaf_Name (A)) = F;
      end Types_Compatible;

      function Effective_Formal_Type
        (Candidate   : Symbol_Info;
         Formal_Type : String) return String
      is
         Instance : constant Symbol_Id :=
           Generic_Instance_For_Candidate (Analysis, Name, From_Scope, Candidate);
      begin
         if Instance = No_Symbol then
            return Formal_Type;
         end if;

         return Substitute_Generic_Actual_Type
           (Analysis, Instance, Candidate.Parent_Symbol, Formal_Type);
      end Effective_Formal_Type;

      function Candidate_Matches_Actuals (Candidate : Symbol_Info) return Boolean is
         Actuals      : Parameter_Array;
         Formals      : Parameter_Array;
         Actual_Count : Natural := 0;
         Formal_Count : Natural := 0;
         Formal_Used  : array (Parameter_Index) of Boolean := (others => False);
         Next_Positional : Natural := 1;
      begin
         if Actual_Profile'Length = 0 then
            return True;
         end if;

         Parse_Actual_Profile (Actual_Profile, Actuals, Actual_Count);
         Parse_Formal_Profile (To_String (Candidate.Profile_Summary), Formals, Formal_Count);

         if Actual_Count > Formal_Count then
            return False;
         end if;

         --  Ada calls may omit formals that have default
         --  expressions.  Match positional actuals to the next available
         --  formal, match named associations by formal name, and then require
         --  every unmatched formal to carry retained default metadata.  The
         --  resolver remains conservative: it does not synthesize expression
         --  types or apply compiler legality rules beyond this bounded call
         --  shape filter.
         for A in 1 .. Actual_Count loop
            declare
               Matched : Boolean := False;
            begin
               if Actuals (A).Has_Name then
                  for F in 1 .. Formal_Count loop
                     if not Formal_Used (F)
                       and then To_String (Actuals (A).Name) = To_String (Formals (F).Name)
                       and then Types_Compatible
                         (To_String (Actuals (A).Type_Name),
                          Effective_Formal_Type (Candidate, To_String (Formals (F).Type_Name)))
                     then
                        Formal_Used (F) := True;
                        Matched := True;
                        exit;
                     end if;
                  end loop;
               else
                  while Next_Positional <= Formal_Count
                    and then Formal_Used (Next_Positional)
                  loop
                     Next_Positional := Next_Positional + 1;
                  end loop;

                  if Next_Positional <= Formal_Count
                    and then Types_Compatible
                      (To_String (Actuals (A).Type_Name),
                       Effective_Formal_Type (Candidate, To_String (Formals (Next_Positional).Type_Name)))
                  then
                     Formal_Used (Next_Positional) := True;
                     Matched := True;
                     Next_Positional := Next_Positional + 1;
                  end if;
               end if;

               if not Matched then
                  return False;
               end if;
            end;
         end loop;

         for F in 1 .. Formal_Count loop
            if not Formal_Used (F)
              and then not Formals (F).Has_Default
            then
               return False;
            end if;
         end loop;

         return True;
      end Candidate_Matches_Actuals;

      function Candidate_Matches_Result (Candidate : Symbol_Info) return Boolean is
         Expected_Text : constant String := Trimmed (Expected_Result_Type);
         Inferred_Expected : constant String :=
           (if Expected_Text'Length = 0 then ""
            else Infer_Expression_Type_In_Scope (Analysis, Expected_Text, From_Scope));
         Expected : constant String :=
           Normalize_Name
             (if Inferred_Expected'Length /= 0 then Inferred_Expected else Expected_Text);
         Candidate_Result : constant String :=
           (if Profile_Return_Type (To_String (Candidate.Profile_Summary)) /= ""
            then Profile_Return_Type (To_String (Candidate.Profile_Summary))
            else To_String (Candidate.Target_Name));
         Returned : constant String := Effective_Formal_Type
           (Candidate, Candidate_Result);
      begin
         if Expected'Length = 0 then
            return True;
         end if;

         if Candidate.Kind /= Symbol_Function
           and then Candidate.Kind /= Symbol_Operator_Function
         then
            return False;
         end if;

         return Types_Compatible (Expected, Returned);
      end Candidate_Matches_Result;

      Candidates : constant Resolution_Result :=
        Resolve_In_Scope (Analysis, Name, From_Scope);
      Result : Resolution_Result;
   begin
      for Candidate_Id of Candidates.Matches loop
         if Natural (Candidate_Id) <= Symbol_Count (Analysis) then
            declare
               Candidate : constant Symbol_Info := Symbol (Analysis, Candidate_Id);
            begin
               if (Candidate.Kind = Symbol_Procedure
                   or else Candidate.Kind = Symbol_Function
                   or else Candidate.Kind = Symbol_Operator_Function
                   or else Candidate.Kind = Symbol_Entry
                   or else Candidate.Kind = Symbol_Generic_Formal_Subprogram)
                 and then Candidate_Matches_Actuals (Candidate)
                 and then Candidate_Matches_Result (Candidate)
               then
                  Result.Matches.Append (Candidate_Id);
               end if;
            end;
         end if;
      end loop;

      Result.Overflow := Candidates.Overflow or else Editor.Ada_Language_Model.Overflowed (Analysis);
      return Result;
   end Resolve_Call_In_Scope;

   function First_Match_In_Scope
     (Analysis   : Editor.Ada_Language_Model.Analysis_Result;
      Name       : String;
      From_Scope : Editor.Ada_Language_Model.Symbol_Id) return Editor.Ada_Language_Model.Symbol_Id
   is
      R : constant Resolution_Result := Resolve_In_Scope (Analysis, Name, From_Scope);
   begin
      if R.Matches.Is_Empty then
         return Editor.Ada_Language_Model.No_Symbol;
      end if;
      return R.Matches.First_Element;
   end First_Match_In_Scope;

   function First_Match
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Name     : String;
      From_Depth : Natural := Natural'Last) return Editor.Ada_Language_Model.Symbol_Id
   is
      R : constant Resolution_Result := Resolve (Analysis, Name, From_Depth);
   begin
      if R.Matches.Is_Empty then
         return Editor.Ada_Language_Model.No_Symbol;
      end if;
      return R.Matches.First_Element;
   end First_Match;

end Editor.Ada_Symbol_Resolver;
