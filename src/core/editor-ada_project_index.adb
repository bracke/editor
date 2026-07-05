with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Language_Model;
use type Editor.Ada_Language_Model.Symbol_Kind;

package body Editor.Ada_Project_Index is

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


   function Trim_Image (Value : Natural) return String is
   begin
      return Ada.Strings.Fixed.Trim (Natural'Image (Value), Both);
   end Trim_Image;

   function Symbol_Kind_Label
     (Kind : Editor.Ada_Language_Model.Symbol_Kind) return String
   is
      use Editor.Ada_Language_Model;
   begin
      case Kind is
         when Symbol_Package => return "package spec";
         when Symbol_Package_Body => return "package body";
         when Symbol_Procedure => return "procedure";
         when Symbol_Function => return "function";
         when Symbol_Operator_Function => return "operator function";
         when Symbol_Type => return "type";
         when Symbol_Subtype => return "subtype";
         when Symbol_Record_Type => return "record type";
         when Symbol_Object => return "object";
         when Symbol_Constant => return "constant";
         when Symbol_Exception => return "exception";
         when Symbol_Task => return "task";
         when Symbol_Protected => return "protected";
         when Symbol_Entry => return "entry";
         when Symbol_Generic_Package => return "generic package";
         when Symbol_Generic_Subprogram => return "generic subprogram";
         when Symbol_Rename => return "rename";
         when Symbol_Instantiation => return "instantiation";
         when Symbol_Separate_Body => return "separate body";
         when others => return "symbol";
      end case;
   end Symbol_Kind_Label;


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

   function Has_Dot (Name : String) return Boolean is
   begin
      for C of Name loop
         if C = '.' then
            return True;
         end if;
      end loop;
      return False;
   end Has_Dot;


   function Qualified_Name
     (Analysis  : Editor.Ada_Language_Model.Analysis_Result;
      Symbol    : Editor.Ada_Language_Model.Symbol_Info;
      Remaining : Natural;
      Truncated : in out Boolean) return String
   is
      use Editor.Ada_Language_Model;
      Local : constant String := To_String (Symbol.Name);
      Prefix : Unbounded_String;
   begin
      if Symbol.Parent_Symbol = No_Symbol then
         return Local;
      end if;

      if Remaining = 0
        or else Natural (Symbol.Parent_Symbol) > Symbol_Count (Analysis)
      then
         --  project-index qualified-name construction must be
         --  bounded by the retained symbol table.  Malformed parser/test data
         --  can otherwise create cyclic Parent_Symbol chains and make a
         --  project-wide lookup recurse forever while preparing selected-name
         --  candidates.  Invalid or exhausted parent chains degrade to local
         --  spelling only; they must not fabricate partial dotted targets.
         Truncated := True;
         return Local;
      end if;

      declare
         Parent : constant Editor.Ada_Language_Model.Symbol_Info :=
           Editor.Ada_Language_Model.Symbol (Analysis, Symbol.Parent_Symbol);
      begin
         if not Editor.Ada_Language_Model.Is_Declaration_Owner (Parent.Kind) then
            --  use the shared language-model declaration-owner
            --  predicate for project-index selected-name construction, so the
            --  index cannot drift from child/overload ownership rules.
            Truncated := True;
            return Local;
         end if;

         Prefix := To_Unbounded_String
           (Qualified_Name
              (Analysis,
               Parent,
               Remaining - 1,
               Truncated));
      end;

      if Truncated then
         return Local;
      end if;

      if Length (Prefix) = 0 then
         return Local;
      end if;
      return To_String (Prefix) & "." & Local;
   exception
      when others =>
         --  Corrupt or stale analysis data must not make the project index
         --  fabricate a match.  Fall back to the local spelling only.
         Truncated := True;
         return Local;
   end Qualified_Name;

   function Qualified_Name
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Symbol   : Editor.Ada_Language_Model.Symbol_Info) return String
   is
      Truncated : Boolean := False;
   begin
      return Qualified_Name
        (Analysis, Symbol, Editor.Ada_Language_Model.Symbol_Count (Analysis),
         Truncated);
   end Qualified_Name;

   function Symbol_Matches
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Symbol   : Editor.Ada_Language_Model.Symbol_Info;
      Name     : String) return Boolean
   is
      Wanted      : constant String := Editor.Ada_Language_Model.Normalize_Name (Name);
      Wanted_Leaf : constant String := Editor.Ada_Language_Model.Normalize_Name (Leaf_Name (Name));
      Symbol_Name : constant String := To_String (Symbol.Normalized_Name);
      Symbol_Qualified : constant String :=
        Editor.Ada_Language_Model.Normalize_Name (Qualified_Name (Analysis, Symbol));
      Symbol_Leaf : constant String :=
        Editor.Ada_Language_Model.Normalize_Name (Leaf_Name (To_String (Symbol.Name)));
   begin
      if Has_Dot (Name) then
         --  Qualified project-index lookup must not devolve to leaf-only
         --  matching, otherwise Other.Widget can satisfy Shared.Widget.
         return Symbol_Name = Wanted or else Symbol_Qualified = Wanted;
      end if;

      if Has_Dot (To_String (Symbol.Name)) then
         --  keep project-wide unselected lookup aligned with the
         --  scoped resolver.  A declaration stored with selected/dotted source
         --  spelling is not a direct declaration of its leaf in the current
         --  project index, so Widget must not bind to Inner.Widget merely
         --  because their retained leaf text matches.  Exact selected lookup
         --  above remains supported.
         return Symbol_Name = Wanted;
      end if;

      return Symbol_Name = Wanted or else Symbol_Leaf = Wanted_Leaf;
   end Symbol_Matches;



   function Unit_Role_For
     (Symbol : Editor.Ada_Language_Model.Symbol_Info) return Indexed_Unit_Role
   is
      use Editor.Ada_Language_Model;
   begin
      case Symbol.Kind is
         when Symbol_Package | Symbol_Generic_Package =>
            if Symbol.Flags.Is_Body then
               return Unit_Package_Body;
            elsif Symbol.Flags.Is_Private then
               return Unit_Private_Package_Spec;
            else
               return Unit_Package_Spec;
            end if;

         when Symbol_Package_Body =>
            return Unit_Package_Body;

         when Symbol_Procedure | Symbol_Function | Symbol_Operator_Function
            | Symbol_Generic_Subprogram | Symbol_Entry =>
            if Symbol.Flags.Is_Body then
               return Unit_Subprogram_Body;
            else
               return Unit_Subprogram_Spec;
            end if;

         when Symbol_Separate_Body =>
            return Unit_Separate_Body;

         when others =>
            return Unit_Any;
      end case;
   end Unit_Role_For;


   function Unit_Role_For_Symbol
     (Symbol : Editor.Ada_Language_Model.Symbol_Info) return Indexed_Unit_Role
   is
   begin
      return Unit_Role_For (Symbol);
   end Unit_Role_For_Symbol;

   function Is_Unit_Symbol
     (Symbol : Editor.Ada_Language_Model.Symbol_Info) return Boolean
   is
   begin
      return Unit_Role_For (Symbol) /= Unit_Any;
   end Is_Unit_Symbol;

   function Is_Library_Unit_Symbol
     (Symbol : Editor.Ada_Language_Model.Symbol_Info) return Boolean
   is
      use Editor.Ada_Language_Model;
   begin
      --  the cross-file Ada unit table must represent library
      --  units, not every nested declaration that happens to be package-like
      --  or subprogram-like.  Nested packages/subprograms retain ordinary
      --  symbol-index lookup, but they are not spec/body/separate file-level
      --  navigation units.  Library child units such as Parent.Child are
      --  parsed as a single top-level dotted unit symbol and therefore keep
      --  No_Symbol parent ownership.
      return Is_Unit_Symbol (Symbol)
        and then Symbol.Parent_Symbol = No_Symbol
        and then Symbol.Enclosing_Scope = Root_Scope;
   end Is_Library_Unit_Symbol;

   function Role_Matches
     (Candidate : Indexed_Unit_Role;
      Wanted    : Indexed_Unit_Role) return Boolean
   is
   begin
      if Wanted = Unit_Any then
         return True;
      elsif Wanted = Unit_Package_Spec then
         return Candidate = Unit_Package_Spec
           or else Candidate = Unit_Private_Package_Spec;
      else
         return Candidate = Wanted;
      end if;
   end Role_Matches;

   function Unit_Name_For
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Symbol   : Editor.Ada_Language_Model.Symbol_Info) return String
   is
   begin
      if Symbol.Kind = Editor.Ada_Language_Model.Symbol_Separate_Body
        and then Length (Symbol.Target_Name) > 0
      then
         return To_String (Symbol.Target_Name);
      end if;

      return Qualified_Name (Analysis, Symbol);
   end Unit_Name_For;

   function Parent_Unit_Name (Unit_Name : String) return String is
      Dot : Natural := 0;
   begin
      for I in reverse Unit_Name'Range loop
         if Unit_Name (I) = '.' then
            Dot := I;
            exit;
         end if;
      end loop;

      if Dot = 0 or else Dot <= Unit_Name'First then
         return "";
      end if;

      return Unit_Name (Unit_Name'First .. Dot - 1);
   end Parent_Unit_Name;


   procedure Append_Unit
     (Index    : in out Index_State;
      File_Row : Indexed_File;
      Symbol   : Editor.Ada_Language_Model.Symbol_Info)
   is
      Name : constant String := Unit_Name_For (File_Row.Analysis, Symbol);
      Role : constant Indexed_Unit_Role := Unit_Role_For (Symbol);
   begin
      if Role = Unit_Any or else Name'Length = 0 then
         return;
      end if;

      if Natural (Index.Units.Length) >= Max_Index_Units then
         Index.Unit_Overflow := True;
         return;
      end if;

      Index.Units.Append
        (Indexed_Unit'(Unit_Name            => To_Unbounded_String (Name),
          Normalized_Unit_Name => To_Unbounded_String
            (Editor.Ada_Language_Model.Normalize_Name (Name)),
          Role                 => Role,
          Path                 => File_Row.Key.Path,
          Key                  => File_Row.Key,
          Symbol               => Symbol));
   end Append_Unit;

   procedure Rebuild_Units (Index : in out Index_State) is
   begin
      --  keep Ada unit relationships as first-class project-index
      --  state keyed by normalized Ada unit name.  Rebuilding from retained
      --  file analyses after every mutation keeps path/buffer/lifecycle
      --  invalidation simple and prevents stale unit rows from outliving their
      --  source file key.
      Index.Units.Clear;
      Index.Unit_Overflow := False;

      for F of Index.Files loop
         for I in 1 .. Editor.Ada_Language_Model.Symbol_Count (F.Analysis) loop
            declare
               S : constant Editor.Ada_Language_Model.Symbol_Info :=
                 Editor.Ada_Language_Model.Symbol_At (F.Analysis, I);
            begin
               if Is_Library_Unit_Symbol (S) then
                  Append_Unit (Index, F, S);
               end if;
            end;
         end loop;
      end loop;
   end Rebuild_Units;

   procedure Recompute (Index : in out Index_State) is
      H : Natural := 0;
   begin
      Rebuild_Units (Index);

      for F of Index.Files loop
         --  project-index fingerprints must include the indexed
         --  path as well as the buffer/revision/lifecycle/fingerprint stamps.
         --  Otherwise two different project files with identical analysis and
         --  ownership numbers can produce the same aggregate stamp, weakening
         --  stale-target detection for status/navigation consumers.
         H := Hash_String (H, To_String (F.Key.Path));
         H := Hash_Mix
           (H,
            (F.Key.Buffer_Token,
             F.Key.Buffer_Revision,
             F.Key.Lifecycle_Generation,
             F.Key.Fingerprint,
             1));
      end loop;

      --  include the bounded file-table overflow bit in the
      --  aggregate fingerprint.  A failed Put_Analysis past Max_Index_Files
      --  changes the conservative validity state even though no new file row is
      --  appended; status/navigation consumers must be able to observe that
      --  transition through the same stamp used for non-overflow mutations.
      if Index.Index_Overflow then
         H := Hash_Mix (H, 97);
      end if;

      if Index.Unit_Overflow then
         H := Hash_Mix (H, 193);
      end if;

      for U of Index.Units loop
         H := Hash_String (H, To_String (U.Normalized_Unit_Name));
         H := Hash_Mix
           (H,
            (Natural (Indexed_Unit_Role'Pos (U.Role)), U.Key.Fingerprint, 1));
      end loop;

      Index.Index_Fingerprint := H;
   end Recompute;

   procedure Clear (Index : in out Index_State) is
   begin
      Index.Files.Clear;
      Index.Units.Clear;
      Index.Index_Overflow := False;
      Index.Unit_Overflow := False;
      Index.Index_Fingerprint := 0;
   end Clear;

   function Same_Path (Left : String; Right : String) return Boolean;

   procedure Put_Analysis
     (Index                : in out Index_State;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis             : Editor.Ada_Language_Model.Analysis_Result)
   is
      Key : constant Indexed_File_Key :=
        (Path                 => To_Unbounded_String (Path),
         Buffer_Token         => Buffer_Token,
         Buffer_Revision      => Buffer_Revision,
         Lifecycle_Generation => Lifecycle_Generation,
         Fingerprint          => Editor.Ada_Language_Model.Fingerprint (Analysis));
   begin
      for I in 1 .. Natural (Index.Files.Length) loop
         if Same_Path (To_String (Index.Files.Element (I).Key.Path), Path) then
            Index.Files.Replace_Element (I, (Key => Key, Analysis => Analysis));
            Recompute (Index);
            return;
         end if;
      end loop;

      if Natural (Index.Files.Length) >= Max_Index_Files then
         Index.Index_Overflow := True;
         Recompute (Index);
         return;
      end if;

      Index.Files.Append (Indexed_File'(Key => Key, Analysis => Analysis));
      Recompute (Index);
   end Put_Analysis;

   function Same_Or_Descendant_Path (Path : String; Root_Path : String) return Boolean is
      function Normalized (Text : String) return String is
         Result : String := Text;
         Write  : Natural := Result'First;
         Last   : Natural;
         Prev_Sep : Boolean := False;
      begin
         if Text'Length = 0 then
            return "";
         end if;

         for I in Text'Range loop
            declare
               Ch : Character := Text (I);
            begin
               if Character'Pos (Ch) = 16#5C# then
                  Ch := '/';
               end if;

               if Ch = '/' then
                  if not Prev_Sep then
                     Result (Write) := Ch;
                     Write := Write + 1;
                  end if;
                  Prev_Sep := True;
               else
                  Result (Write) := Ch;
                  Write := Write + 1;
                  Prev_Sep := False;
               end if;
            end;
         end loop;

         if Write = Result'First then
            return "";
         end if;

         Last := Write - 1;

         while Last >= Result'First and then Result (Last) = '/' loop
            if Last = 0 then
               exit;
            end if;
            Last := Last - 1;
         end loop;

         if Last < Result'First then
            return "";
         end if;

         return Result (Result'First .. Last);
      end Normalized;

      P : constant String := Normalized (Path);
      R : constant String := Normalized (Root_Path);
   begin
      if P = R then
         return True;
      elsif R'Length = 0 or else P'Length <= R'Length then
         return False;
      end if;

      return P (P'First .. P'First + R'Length - 1) = R
        and then P (P'First + R'Length) = '/';
   end Same_Or_Descendant_Path;

   function Same_Path (Left : String; Right : String) return Boolean is
   begin
      return Same_Or_Descendant_Path (Left, Right)
        and then Same_Or_Descendant_Path (Right, Left);
   end Same_Path;

   procedure Invalidate_Path (Index : in out Index_State; Path : String) is
      I : Positive := 1;
   begin
      --  exact path invalidation uses the same slash and
      --  trailing-separator normalization as subtree invalidation.  Active
      --  buffer reload/revert/save-as and file lifecycle hooks may receive
      --  platform-native path spellings, while project refresh stores the
      --  canonical project/file spelling.  These two representations must
      --  still invalidate the same indexed Ada analysis row.
      while I <= Natural (Index.Files.Length) loop
         if Same_Path (To_String (Index.Files.Element (I).Key.Path), Path) then
            Index.Files.Delete (I);
         else
            I := I + 1;
         end if;
      end loop;
      Recompute (Index);
   end Invalidate_Path;

   procedure Invalidate_Path_Subtree
     (Index : in out Index_State; Root_Path : String)
   is
      I : Positive := 1;
   begin
      while I <= Natural (Index.Files.Length) loop
         if Same_Or_Descendant_Path
              (To_String (Index.Files.Element (I).Key.Path), Root_Path)
         then
            Index.Files.Delete (I);
         else
            I := I + 1;
         end if;
      end loop;
      Recompute (Index);
   end Invalidate_Path_Subtree;


   function Contains_Path
     (Index : Index_State;
      Path  : String) return Boolean
   is
   begin
      for I in 1 .. Natural (Index.Files.Length) loop
         if Same_Path (To_String (Index.Files.Element (I).Key.Path), Path) then
            return True;
         end if;
      end loop;

      return False;
   end Contains_Path;

   procedure Invalidate_Buffer (Index : in out Index_State; Buffer_Token : Natural) is
      I : Positive := 1;
   begin
      while I <= Natural (Index.Files.Length) loop
         if Index.Files.Element (I).Key.Buffer_Token = Buffer_Token then
            Index.Files.Delete (I);
         else
            I := I + 1;
         end if;
      end loop;
      Recompute (Index);
   end Invalidate_Buffer;

   procedure Invalidate_Lifecycle
     (Index : in out Index_State; Lifecycle_Generation : Natural)
   is
      I : Positive := 1;
   begin
      while I <= Natural (Index.Files.Length) loop
         if Index.Files.Element (I).Key.Lifecycle_Generation = Lifecycle_Generation then
            --  delete exactly the matching element and keep I
            --  stationary so adjacent files from the same lifecycle
            --  generation are checked next.  A second delete at the same
            --  index can remove unrelated survivor files or raise when the
            --  matching element was the final entry.
            Index.Files.Delete (I);
         else
            I := I + 1;
         end if;
      end loop;
      Recompute (Index);
   end Invalidate_Lifecycle;

   function Contains_Current
     (Index                : Index_State;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Boolean
   is
   begin
      for F of Index.Files loop
         if Same_Path (To_String (F.Key.Path), Path)
           and then F.Key.Buffer_Token = Buffer_Token
           and then F.Key.Buffer_Revision = Buffer_Revision
           and then F.Key.Lifecycle_Generation = Lifecycle_Generation
           and then F.Key.Fingerprint = Analysis_Fingerprint
         then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Current;

   function Current_Analysis_Fingerprint
     (Index                : Index_State;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural) return Natural
   is
   begin
      for F of Index.Files loop
         if Same_Path (To_String (F.Key.Path), Path)
           and then F.Key.Buffer_Token = Buffer_Token
           and then F.Key.Buffer_Revision = Buffer_Revision
           and then F.Key.Lifecycle_Generation = Lifecycle_Generation
         then
            return F.Key.Fingerprint;
         end if;
      end loop;

      return 0;
   end Current_Analysis_Fingerprint;


   function Contains_Key
     (Index : Index_State;
      Key   : Indexed_File_Key) return Boolean
   is
   begin
      --  indexed navigation targets carry the exact parser-owned
      --  file key they were resolved from.  The executor revalidates that key
      --  immediately before navigation so a stale availability projection
      --  cannot jump after a project-index clear, lifecycle invalidation, or
      --  path replacement.
      for F of Index.Files loop
         if Same_Path (To_String (F.Key.Path), To_String (Key.Path))
           and then F.Key.Buffer_Token = Key.Buffer_Token
           and then F.Key.Buffer_Revision = Key.Buffer_Revision
           and then F.Key.Lifecycle_Generation = Key.Lifecycle_Generation
           and then F.Key.Fingerprint = Key.Fingerprint
         then
            return True;
         end if;
      end loop;

      return False;
   end Contains_Key;


   function Contains_Open_Buffer_Key
     (Index                : Index_State;
      Key                  : Indexed_File_Key;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural) return Boolean
   is
   begin
      if Key.Buffer_Token = 0 then
         return False;
      end if;

      return Same_Path (To_String (Key.Path), Path)
        and then Key.Buffer_Token = Buffer_Token
        and then Key.Buffer_Revision = Buffer_Revision
        and then Key.Lifecycle_Generation = Lifecycle_Generation
        and then Contains_Key (Index, Key);
   end Contains_Open_Buffer_Key;


   function Key_Is_Current
     (Key                  : Indexed_File_Key;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Boolean
   is
   begin
      return Same_Path (To_String (Key.Path), Path)
        and then Key.Buffer_Token = Buffer_Token
        and then Key.Buffer_Revision = Buffer_Revision
        and then Key.Lifecycle_Generation = Lifecycle_Generation
        and then Key.Fingerprint = Analysis_Fingerprint;
   end Key_Is_Current;


   function Resolve
     (Index : Index_State;
      Name  : String;
      Max_Matches : Natural := 0) return Index_Resolution_Result
   is
      Result : Index_Resolution_Result;
   begin
      for F of Index.Files loop
         --  propagate per-file language-model overflow through
         --  project-index resolution.  A non-full index can still contain a
         --  truncated bounded analysis result, and semantic callers must know
         --  to degrade unresolved identifiers conservatively.
         Result.Overflow := Result.Overflow
           or else Editor.Ada_Language_Model.Overflowed (F.Analysis);

         for I in 1 .. Editor.Ada_Language_Model.Symbol_Count (F.Analysis) loop
            declare
               S : constant Editor.Ada_Language_Model.Symbol_Info :=
                 Editor.Ada_Language_Model.Symbol_At (F.Analysis, I);
            begin
               if Symbol_Matches (F.Analysis, S, Name) then
                  if Max_Matches > 0
                    and then Natural (Result.Matches.Length) >= Max_Matches
                  then
                     Result.Overflow := True;
                     Result.Overflow := Result.Overflow or else Index.Index_Overflow;
                     return Result;
                  end if;

                  Result.Matches.Append
                    (Indexed_Symbol'(Path   => F.Key.Path,
                      Key    => F.Key,
                      Symbol => S));
               end if;
            end;
         end loop;
      end loop;
      Result.Overflow := Result.Overflow or else Index.Index_Overflow;
      return Result;
   end Resolve;

   function Resolve_Current
     (Index                : Index_State;
      Name                 : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Index_Resolution_Result
   is
      Result : Index_Resolution_Result;
   begin
      for F of Index.Files loop
         if Key_Is_Current
              (F.Key, Path, Buffer_Token, Buffer_Revision,
               Lifecycle_Generation, Analysis_Fingerprint)
         then
            --  current-stamped navigation/semantic lookups must not
            --  hide analysis overflow just because the path/token/revision
            --  stamp itself is current.
            Result.Overflow := Result.Overflow
              or else Editor.Ada_Language_Model.Overflowed (F.Analysis);

            for I in 1 .. Editor.Ada_Language_Model.Symbol_Count (F.Analysis) loop
               declare
                  S : constant Editor.Ada_Language_Model.Symbol_Info :=
                    Editor.Ada_Language_Model.Symbol_At (F.Analysis, I);
               begin
                  if Symbol_Matches (F.Analysis, S, Name) then
                     Result.Matches.Append
                       (Indexed_Symbol'(Path   => F.Key.Path,
                         Key    => F.Key,
                         Symbol => S));
                  end if;
               end;
            end loop;
         end if;
      end loop;
      Result.Overflow := Result.Overflow or else Index.Index_Overflow;
      return Result;
   end Resolve_Current;

   function First_Match
     (Index : Index_State;
      Name  : String) return Indexed_Symbol
   is
      Empty_Key : constant Indexed_File_Key :=
        (Path                 => To_Unbounded_String (""),
         Buffer_Token         => 0,
         Buffer_Revision      => 0,
         Lifecycle_Generation => 0,
         Fingerprint          => 0);
      Empty : constant Indexed_Symbol :=
        (Path   => To_Unbounded_String (""),
         Key    => Empty_Key,
         Symbol => <>);
      R : constant Index_Resolution_Result := Resolve (Index, Name);
   begin
      if R.Matches.Is_Empty then
         return Empty;
      end if;
      return R.Matches.First_Element;
   end First_Match;

   function Has_Match
     (Index : Index_State;
      Name  : String) return Boolean
   is
      R : constant Index_Resolution_Result := Resolve (Index, Name);
   begin
      return not R.Matches.Is_Empty;
   end Has_Match;

   function First_Current_Match
     (Index                : Index_State;
      Name                 : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Indexed_Symbol
   is
      Empty_Key : constant Indexed_File_Key :=
        (Path                 => To_Unbounded_String (""),
         Buffer_Token         => 0,
         Buffer_Revision      => 0,
         Lifecycle_Generation => 0,
         Fingerprint          => 0);
      Empty : constant Indexed_Symbol :=
        (Path   => To_Unbounded_String (""),
         Key    => Empty_Key,
         Symbol => <>);
      R : constant Index_Resolution_Result :=
        Resolve_Current
          (Index, Name, Path, Buffer_Token, Buffer_Revision,
           Lifecycle_Generation, Analysis_Fingerprint);
   begin
      if R.Matches.Is_Empty then
         return Empty;
      end if;
      return R.Matches.First_Element;
   end First_Current_Match;

   function Has_Current_Match
     (Index                : Index_State;
      Name                 : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Boolean
   is
      R : constant Index_Resolution_Result :=
        Resolve_Current
          (Index, Name, Path, Buffer_Token, Buffer_Revision,
           Lifecycle_Generation, Analysis_Fingerprint);
   begin
      return not R.Matches.Is_Empty;
   end Has_Current_Match;



   procedure Stamp_Navigation_Candidate_Status
     (Result   : in out Navigation_Candidate_Result;
      Overflow : Boolean := False)
   is
      Count : constant Natural := Natural (Result.Candidates.Length);
   begin
      if Result.Status = Navigation_Target_Overflow and then not Overflow then
         return;
      elsif Overflow then
         Result.Status := Navigation_Target_Overflow;
      elsif Count = 0 then
         Result.Status := Navigation_Target_Unavailable;
      elsif Count = 1 then
         Result.Status := Navigation_Target_Unique;
      else
         Result.Status := Navigation_Target_Ambiguous;
      end if;
   end Stamp_Navigation_Candidate_Status;

   function Navigation_Candidate_Display_Label
     (Candidate : Indexed_Symbol) return String
   is
      Path     : constant String := To_String (Candidate.Path);
      Name     : constant String := To_String (Candidate.Symbol.Name);
      Profile  : constant String := To_String (Candidate.Symbol.Profile_Summary);
      Position : constant String :=
        Trim_Image (Candidate.Symbol.Source_Span.Start_Line) & ":" &
        Trim_Image (Candidate.Symbol.Source_Span.Start_Column);
      Prefix   : constant String :=
        (if Path'Length = 0 then Position else Path & ":" & Position);
   begin
      --  ambiguity-aware navigation needs stable, user-presentable
      --  labels for chooser rows.  Keep this formatter pure and table-driven:
      --  it uses only validated indexed-symbol metadata and never opens files,
      --  scans the filesystem, mutates buffers, or guesses a target.
      if Profile'Length > 0 then
         return Prefix & " — " & Symbol_Kind_Label (Candidate.Symbol.Kind) &
           " " & Name & " " & Profile;
      elsif Name'Length > 0 then
         return Prefix & " — " & Symbol_Kind_Label (Candidate.Symbol.Kind) &
           " " & Name;
      else
         return Prefix & " — " & Symbol_Kind_Label (Candidate.Symbol.Kind);
      end if;
   end Navigation_Candidate_Display_Label;

   function Navigation_Candidate_Detail_Label
     (Candidate : Indexed_Symbol) return String
   is
      Target : constant String := To_String (Candidate.Symbol.Target_Name);
      Profile : constant String := To_String (Candidate.Symbol.Profile_Summary);
      Detail : Unbounded_String :=
        To_Unbounded_String (Symbol_Kind_Label (Candidate.Symbol.Kind));
   begin
      if Profile'Length > 0 then
         Append (Detail, " ");
         Append (Detail, Profile);
      end if;
      if Candidate.Symbol.Flags.Is_Body then
         Append (Detail, ", body");
      end if;
      if Candidate.Symbol.Flags.Is_Generic then
         Append (Detail, ", generic");
      end if;
      if Candidate.Symbol.Flags.Is_Rename then
         Append (Detail, ", rename");
      end if;
      if Candidate.Symbol.Flags.Is_Instantiation then
         Append (Detail, ", instantiation");
      end if;
      if Candidate.Symbol.Flags.Is_Separate then
         Append (Detail, ", separate");
      end if;
      if Target'Length > 0 then
         Append (Detail, ", target => ");
         Append (Detail, Target);
      end if;
      return To_String (Detail);
   end Navigation_Candidate_Detail_Label;

   function Resolve_Navigation_Candidates
     (Index                       : Index_State;
      Name                        : String;
      Kind                        : Editor.Ada_Language_Model.Symbol_Kind;
      Want_Body                   : Boolean;
      Profile_Summary             : String := "";
      Require_Profile             : Boolean := False;
      Accept_Generic_Package_Spec : Boolean := False;
      Accept_Generic_Subprogram   : Boolean := False;
      Accept_Operator_Function    : Boolean := False) return Navigation_Candidate_Result
   is
      use Editor.Ada_Language_Model;
      Result : Navigation_Candidate_Result;
      Res    : constant Index_Resolution_Result := Resolve (Index, Name);

      function Kind_Matches (Symbol : Symbol_Info) return Boolean is
      begin
         if Symbol.Kind = Kind then
            return True;
         elsif Accept_Generic_Package_Spec
           and then Kind = Symbol_Package
           and then Symbol.Kind = Symbol_Generic_Package
         then
            return True;
         elsif Accept_Generic_Subprogram
           and then Kind = Symbol_Procedure
           and then Symbol.Kind = Symbol_Generic_Subprogram
         then
            return True;
         elsif Accept_Operator_Function
           and then Kind = Symbol_Function
           and then Symbol.Kind = Symbol_Operator_Function
         then
            return True;
         end if;

         return False;
      end Kind_Matches;

      function Body_Side_Matches (Symbol : Symbol_Info) return Boolean is
      begin
         if Symbol.Kind = Symbol_Package_Body then
            return Want_Body;
         elsif Symbol.Kind = Symbol_Package
           or else Symbol.Kind = Symbol_Generic_Package
         then
            return not Want_Body;
         elsif Is_Subprogram (Symbol.Kind) then
            return Symbol.Flags.Is_Body = Want_Body;
         end if;

         return True;
      end Body_Side_Matches;

      function Profile_Matches (Symbol : Symbol_Info) return Boolean is
         Wanted_Profile    : constant String := Normalize_Name (Profile_Summary);
         Candidate_Profile : constant String := Normalize_Name
           (To_String (Symbol.Profile_Summary));
      begin
         if not Require_Profile then
            return True;
         elsif Wanted_Profile'Length = 0 then
            return True;
         elsif Candidate_Profile'Length = 0 then
            return False;
         end if;

         return Candidate_Profile = Wanted_Profile;
      end Profile_Matches;
   begin
      if Res.Overflow then
         Stamp_Navigation_Candidate_Status (Result, Overflow => True);
         return Result;
      end if;

      for I in Res.Matches.First_Index .. Res.Matches.Last_Index loop
         declare
            Match : constant Indexed_Symbol := Res.Matches (I);
         begin
            if Kind_Matches (Match.Symbol)
              and then Body_Side_Matches (Match.Symbol)
              and then Profile_Matches (Match.Symbol)
            then
               Result.Candidates.Append (Match);
            end if;
         end;
      end loop;

      Stamp_Navigation_Candidate_Status (Result);
      return Result;
   end Resolve_Navigation_Candidates;



   function Resolve_Unique_Navigation_Target
     (Index                       : Index_State;
      Name                        : String;
      Kind                        : Editor.Ada_Language_Model.Symbol_Kind;
      Want_Body                   : Boolean;
      Profile_Summary             : String := "";
      Require_Profile             : Boolean := False;
      Accept_Generic_Package_Spec : Boolean := False;
      Accept_Generic_Subprogram   : Boolean := False;
      Accept_Operator_Function    : Boolean := False) return Unique_Target_Result
   is
      use Editor.Ada_Language_Model;
      Result : Unique_Target_Result;
      Res    : constant Index_Resolution_Result := Resolve (Index, Name);

      function Kind_Matches (Symbol : Symbol_Info) return Boolean is
      begin
         if Symbol.Kind = Kind then
            return True;
         elsif Accept_Generic_Package_Spec
           and then Kind = Symbol_Package
           and then Symbol.Kind = Symbol_Generic_Package
         then
            return True;
         elsif Accept_Generic_Subprogram
           and then Kind = Symbol_Procedure
           and then Symbol.Kind = Symbol_Generic_Subprogram
         then
            return True;
         elsif Accept_Operator_Function
           and then Kind = Symbol_Function
           and then Symbol.Kind = Symbol_Operator_Function
         then
            return True;
         end if;

         return False;
      end Kind_Matches;

      function Body_Side_Matches (Symbol : Symbol_Info) return Boolean is
      begin
         if Symbol.Kind = Symbol_Package_Body then
            return Want_Body;
         elsif Symbol.Kind = Symbol_Package
           or else Symbol.Kind = Symbol_Generic_Package
         then
            return not Want_Body;
         elsif Is_Subprogram (Symbol.Kind) then
            return Symbol.Flags.Is_Body = Want_Body;
         end if;

         return True;
      end Body_Side_Matches;

      function Profile_Matches (Symbol : Symbol_Info) return Boolean is
         Wanted_Profile    : constant String := Normalize_Name (Profile_Summary);
         Candidate_Profile : constant String := Normalize_Name
           (To_String (Symbol.Profile_Summary));
      begin
         if not Require_Profile then
            return True;
         elsif Wanted_Profile'Length = 0 then
            return True;
         elsif Candidate_Profile'Length = 0 then
            return False;
         end if;

         return Candidate_Profile = Wanted_Profile;
      end Profile_Matches;
   begin
      Result.Overflow := Res.Overflow;

      if Res.Overflow then
         --  declaration/body/spec navigation is a safety-critical
         --  consumer of the project index.  When either the file table or any
         --  retained per-file analysis overflowed, the index cannot prove that
         --  the visible candidate set is complete.  Do not return a seemingly
         --  unique target from a truncated index; command availability must
         --  degrade to unavailable instead of jumping to the only retained
         --  match while an omitted duplicate may exist.
         return Result;
      end if;

      if Res.Matches.Is_Empty then
         return Result;
      end if;

      for I in Res.Matches.First_Index .. Res.Matches.Last_Index loop
         declare
            Match : constant Indexed_Symbol := Res.Matches (I);
         begin
            if Kind_Matches (Match.Symbol)
              and then Body_Side_Matches (Match.Symbol)
              and then Profile_Matches (Match.Symbol)
            then
               if Result.Available then
                  --  declaration/body/spec navigation must not pick
                  --  the first same-name indexed target when multiple current
                  --  candidates still satisfy the requested kind/body/profile
                  --  filters.  Ambiguity degrades to no target so commands
                  --  remain deterministic and conservative instead of jumping
                  --  to an unrelated package, overload set, or duplicate unit.
                  Result.Available := False;
                  Result.Ambiguous := True;
                  return Result;
               end if;

               Result.Available := True;
               Result.Target := Match;
            end if;
         end;
      end loop;

      return Result;
   end Resolve_Unique_Navigation_Target;




   function Resolve_Unit
     (Index     : Index_State;
      Unit_Name : String;
      Role      : Indexed_Unit_Role := Unit_Any) return Unit_Resolution_Result
   is
      Result : Unit_Resolution_Result;
      Wanted : constant String := Editor.Ada_Language_Model.Normalize_Name (Unit_Name);
   begin
      Result.Overflow := Index.Index_Overflow or else Index.Unit_Overflow;

      for F of Index.Files loop
         Result.Overflow := Result.Overflow
           or else Editor.Ada_Language_Model.Overflowed (F.Analysis);
      end loop;

      for U of Index.Units loop
         if To_String (U.Normalized_Unit_Name) = Wanted
           and then Role_Matches (U.Role, Role)
         then
            Result.Matches.Append (U);
         end if;
      end loop;

      return Result;
   end Resolve_Unit;

   function Resolve_Unique_Unit_Target
     (Index     : Index_State;
      Unit_Name : String;
      Role      : Indexed_Unit_Role := Unit_Any) return Unique_Target_Result
   is
      Result : Unique_Target_Result;
      Res    : constant Unit_Resolution_Result := Resolve_Unit (Index, Unit_Name, Role);
   begin
      Result.Overflow := Res.Overflow;

      if Res.Overflow then
         return Result;
      end if;

      if Res.Matches.Is_Empty then
         return Result;
      end if;

      for I in Res.Matches.First_Index .. Res.Matches.Last_Index loop
         declare
            U : constant Indexed_Unit := Res.Matches (I);
            S : constant Indexed_Symbol :=
              (Path   => U.Path,
               Key    => U.Key,
               Symbol => U.Symbol);
         begin
            if Result.Available then
               Result.Available := False;
               Result.Ambiguous := True;
               return Result;
            end if;

            Result.Available := True;
            Result.Target := S;
         end;
      end loop;

      return Result;
   end Resolve_Unique_Unit_Target;

   function Unit_Name_For_Target
     (Index  : Index_State;
      Target : Indexed_Symbol) return String
   is
   begin
      for F of Index.Files loop
         if Same_Path (To_String (F.Key.Path), To_String (Target.Key.Path))
           and then F.Key.Buffer_Token = Target.Key.Buffer_Token
           and then F.Key.Buffer_Revision = Target.Key.Buffer_Revision
           and then F.Key.Lifecycle_Generation = Target.Key.Lifecycle_Generation
           and then F.Key.Fingerprint = Target.Key.Fingerprint
         then
            return Unit_Name_For (F.Analysis, Target.Symbol);
         end if;
      end loop;

      if Length (Target.Symbol.Target_Name) > 0 then
         return To_String (Target.Symbol.Target_Name);
      end if;

      return To_String (Target.Symbol.Name);
   end Unit_Name_For_Target;


   function Resolve_Related_Unit_Candidates
     (Index     : Index_State;
      From      : Indexed_Symbol;
      Want_Body : Boolean) return Navigation_Candidate_Result
   is
      use Editor.Ada_Language_Model;
      Result    : Navigation_Candidate_Result;
      From_Role : constant Indexed_Unit_Role := Unit_Role_For (From.Symbol);
      Unit_Name : constant String := Unit_Name_For_Target (Index, From);
      Wanted    : Indexed_Unit_Role := Unit_Any;

      procedure Append_Unit_Matches
        (Res                    : Unit_Resolution_Result;
         Require_Separate_Parent : Boolean := False)
      is
      begin
         if Res.Overflow then
            Stamp_Navigation_Candidate_Status (Result, Overflow => True);
            return;
         end if;

         for I in Res.Matches.First_Index .. Res.Matches.Last_Index loop
            declare
               U : constant Indexed_Unit := Res.Matches (I);
            begin
               if (not Require_Separate_Parent)
                 or else Is_Separate_Body_Parent_Target (U.Symbol)
               then
                  Result.Candidates.Append
                    (Indexed_Symbol'(Path   => U.Path,
                      Key    => U.Key,
                      Symbol => U.Symbol));
               end if;
            end;
         end loop;
      end Append_Unit_Matches;
   begin
      --  ambiguity-aware IDE navigation consumers need the same
      --  validated targets that unique goto-spec/body uses, but without
      --  forcing ambiguous families to collapse to unavailable.  Return the
      --  complete candidate set so UI code can present a deterministic chooser
      --  while command execution can still require Status = Unique.
      if From.Symbol.Kind = Symbol_Separate_Body and then not Want_Body then
         Append_Unit_Matches
           (Resolve_Unit (Index, To_String (From.Symbol.Target_Name), Unit_Any),
            Require_Separate_Parent => True);
         Stamp_Navigation_Candidate_Status (Result);
         return Result;
      end if;

      case From_Role is
         when Unit_Package_Spec | Unit_Private_Package_Spec =>
            if Want_Body then
               Wanted := Unit_Package_Body;
            else
               Wanted := Unit_Package_Spec;
            end if;

         when Unit_Package_Body =>
            if Want_Body then
               Wanted := Unit_Package_Body;
            else
               Wanted := Unit_Package_Spec;
            end if;

         when Unit_Subprogram_Spec =>
            if Want_Body then
               Wanted := Unit_Subprogram_Body;
            else
               Wanted := Unit_Subprogram_Spec;
            end if;

         when Unit_Subprogram_Body =>
            if Want_Body then
               Wanted := Unit_Subprogram_Body;
            else
               Wanted := Unit_Subprogram_Spec;
            end if;

         when Unit_Separate_Body =>
            if Want_Body then
               Wanted := Unit_Separate_Body;
            else
               Append_Unit_Matches
                 (Resolve_Unit (Index, To_String (From.Symbol.Target_Name), Unit_Any),
                  Require_Separate_Parent => True);
               Stamp_Navigation_Candidate_Status (Result);
               return Result;
            end if;

         when Unit_Any =>
            Stamp_Navigation_Candidate_Status (Result);
            return Result;
      end case;

      if Unit_Name'Length > 0 then
         Append_Unit_Matches (Resolve_Unit (Index, Unit_Name, Wanted));
      end if;

      Stamp_Navigation_Candidate_Status (Result);
      return Result;
   end Resolve_Related_Unit_Candidates;

   function Resolve_Separate_Parent_Target
     (Index         : Index_State;
      Separate_Body : Indexed_Symbol) return Unique_Target_Result
   is
      use Editor.Ada_Language_Model;
      Result : Unique_Target_Result;
      Parent_Name : constant String := To_String (Separate_Body.Symbol.Target_Name);
      Res : constant Unit_Resolution_Result := Resolve_Unit (Index, Parent_Name, Unit_Any);

      procedure Consider (U : Indexed_Unit) is
         S : constant Indexed_Symbol :=
           (Path   => U.Path,
            Key    => U.Key,
            Symbol => U.Symbol);
      begin
         if Result.Available then
            Result.Available := False;
            Result.Ambiguous := True;
         else
            Result.Available := True;
            Result.Target := S;
         end if;
      end Consider;
   begin
      Result.Overflow := Res.Overflow;

      if Separate_Body.Symbol.Kind /= Symbol_Separate_Body
        or else Parent_Name'Length = 0
        or else Res.Overflow
      then
         return Result;
      end if;

      for I in Res.Matches.First_Index .. Res.Matches.Last_Index loop
         declare
            U : constant Indexed_Unit := Res.Matches (I);
         begin
            if Is_Separate_Body_Parent_Target (U.Symbol) then
               Consider (U);
               if Result.Ambiguous then
                  return Result;
               end if;
            end if;
         end;
      end loop;

      if Result.Available then
         return Result;
      end if;

      --  Prefer the declaration/spec when available for navigation, but a
      --  body-only index still resolves separate-body legality and stub
      --  checks through the enclosing body.
      for I in Res.Matches.First_Index .. Res.Matches.Last_Index loop
         declare
            U : constant Indexed_Unit := Res.Matches (I);
         begin
            if U.Role in Unit_Package_Body | Unit_Subprogram_Body then
               Consider (U);
               if Result.Ambiguous then
                  return Result;
               end if;
            end if;
         end;
      end loop;

      return Result;
   end Resolve_Separate_Parent_Target;

   function Resolve_Related_Unit_Target
     (Index     : Index_State;
      From      : Indexed_Symbol;
      Want_Body : Boolean) return Unique_Target_Result
   is
      use Editor.Ada_Language_Model;
      From_Role : constant Indexed_Unit_Role := Unit_Role_For (From.Symbol);
      Unit_Name : constant String := Unit_Name_For_Target (Index, From);
      Wanted    : Indexed_Unit_Role := Unit_Any;
   begin
      if From.Symbol.Kind = Symbol_Separate_Body and then not Want_Body then
         return Resolve_Separate_Parent_Target (Index, From);
      end if;

      case From_Role is
         when Unit_Package_Spec | Unit_Private_Package_Spec =>
            if Want_Body then
               Wanted := Unit_Package_Body;
            else
               Wanted := Unit_Package_Spec;
            end if;

         when Unit_Package_Body =>
            if Want_Body then
               Wanted := Unit_Package_Body;
            else
               Wanted := Unit_Package_Spec;
            end if;

         when Unit_Subprogram_Spec =>
            if Want_Body then
               Wanted := Unit_Subprogram_Body;
            else
               Wanted := Unit_Subprogram_Spec;
            end if;

         when Unit_Subprogram_Body =>
            if Want_Body then
               Wanted := Unit_Subprogram_Body;
            else
               Wanted := Unit_Subprogram_Spec;
            end if;

         when Unit_Separate_Body =>
            if Want_Body then
               Wanted := Unit_Separate_Body;
            else
               return Resolve_Separate_Parent_Target (Index, From);
            end if;

         when Unit_Any =>
            declare
               Empty : Unique_Target_Result;
            begin
               return Empty;
            end;
      end case;

      return Resolve_Unique_Unit_Target (Index, Unit_Name, Wanted);
   end Resolve_Related_Unit_Target;

   function Resolve_Parent_Unit_Target
     (Index : Index_State;
      From  : Indexed_Symbol) return Unique_Target_Result
   is
      Unit_Name   : constant String := Unit_Name_For_Target (Index, From);
      Parent_Name : constant String := Parent_Unit_Name (Unit_Name);
      Empty       : Unique_Target_Result;
   begin
      --  child-unit relationships are now explicit unit-table
      --  lookups rather than name scans.  This lets navigation/index
      --  consumers ask for the indexed parent of Parent.Child while preserving
      --  the same conservative unavailable/ambiguous/overflow behaviour used
      --  by spec/body/separate relationships.
      if Unit_Role_For (From.Symbol) = Unit_Any
        or else Parent_Name'Length = 0
      then
         return Empty;
      end if;

      return Resolve_Unique_Unit_Target
        (Index, Parent_Name, Unit_Package_Spec);
   end Resolve_Parent_Unit_Target;

   function Is_Direct_Child_Unit
     (Parent_Name    : String;
      Candidate_Name : String) return Boolean
   is
      Parent_Normalized : constant String :=
        Editor.Ada_Language_Model.Normalize_Name (Parent_Name);
      Candidate_Normalized : constant String :=
        Editor.Ada_Language_Model.Normalize_Name (Candidate_Name);
      Prefix : constant String := Parent_Normalized & ".";
      Suffix_First : Natural;
   begin
      if Parent_Normalized'Length = 0
        or else Candidate_Normalized'Length <= Prefix'Length
      then
         return False;
      end if;

      if Candidate_Normalized
           (Candidate_Normalized'First .. Candidate_Normalized'First + Prefix'Length - 1)
         /= Prefix
      then
         return False;
      end if;

      Suffix_First := Candidate_Normalized'First + Prefix'Length;
      for I in Suffix_First .. Candidate_Normalized'Last loop
         if Candidate_Normalized (I) = '.' then
            return False;
         end if;
      end loop;

      return True;
   end Is_Direct_Child_Unit;

   function Resolve_Child_Units
     (Index  : Index_State;
      Parent : Indexed_Symbol;
      Role   : Indexed_Unit_Role := Unit_Any) return Unit_Resolution_Result
   is
      Result      : Unit_Resolution_Result;
      Parent_Name : constant String := Unit_Name_For_Target (Index, Parent);
   begin
      --  expose the inverse of parent lookup.  Consumers can ask
      --  which directly indexed child units belong to an indexed parent unit
      --  without scanning file paths or falling back to leaf-name symbol
      --  matches.  Grandchildren are intentionally excluded so callers can
      --  build deterministic tree/navigation views one level at a time.
      if Unit_Role_For (Parent.Symbol) = Unit_Any
        or else Parent_Name'Length = 0
      then
         return Result;
      end if;

      Result.Overflow := Index.Index_Overflow or else Index.Unit_Overflow;

      for F of Index.Files loop
         Result.Overflow := Result.Overflow
           or else Editor.Ada_Language_Model.Overflowed (F.Analysis);
      end loop;

      if Result.Overflow then
         return Result;
      end if;

      for U of Index.Units loop
         if Role_Matches (U.Role, Role)
           and then Is_Direct_Child_Unit
             (Parent_Name, To_String (U.Unit_Name))
         then
            Result.Matches.Append (U);
         end if;
      end loop;

      return Result;
   end Resolve_Child_Units;

   function Resolve_Unit_Family
     (Index : Index_State;
      From  : Indexed_Symbol;
      Role  : Indexed_Unit_Role := Unit_Any) return Unit_Resolution_Result
   is
      Result    : Unit_Resolution_Result;
      Unit_Name : constant String := Unit_Name_For_Target (Index, From);
   begin
      --  expose the complete indexed family for a unit identity so
      --  navigation consumers can present all validated spec/body/separate
      --  targets without leaf-name scans.  This is deliberately table-driven:
      --  duplicates are returned as multiple matches for caller disambiguation,
      --  while stale/overflowed analyses retain the same conservative overflow
      --  behaviour as unique target lookup.
      if Unit_Role_For (From.Symbol) = Unit_Any
        or else Unit_Name'Length = 0
      then
         return Result;
      end if;

      Result := Resolve_Unit (Index, Unit_Name, Role);
      return Result;
   end Resolve_Unit_Family;


   function Resolve_Unit_Family_Targets
     (Index : Index_State;
      From  : Indexed_Symbol;
      Role  : Indexed_Unit_Role := Unit_Any) return Navigation_Candidate_Result
   is
      Result : Navigation_Candidate_Result;
      Res    : constant Unit_Resolution_Result := Resolve_Unit_Family (Index, From, Role);
   begin
      if Res.Overflow then
         Stamp_Navigation_Candidate_Status (Result, Overflow => True);
         return Result;
      end if;

      for I in Res.Matches.First_Index .. Res.Matches.Last_Index loop
         declare
            U : constant Indexed_Unit := Res.Matches (I);
         begin
            Result.Candidates.Append
              (Indexed_Symbol'(Path   => U.Path,
                Key    => U.Key,
                Symbol => U.Symbol));
         end;
      end loop;

      Stamp_Navigation_Candidate_Status (Result);
      return Result;
   end Resolve_Unit_Family_Targets;


   function Unit_At
     (Index : Index_State;
      Position : Positive) return Indexed_Unit
   is
   begin
      if Index.Units.Is_Empty
        or else Position < Index.Units.First_Index
        or else Position > Index.Units.Last_Index
      then
         return (others => <>);
      end if;
      return Index.Units (Position);
   end Unit_At;

   function File_Count (Index : Index_State) return Natural is
   begin
      return Natural (Index.Files.Length);
   end File_Count;

   function File_Key_At
     (Index : Index_State;
      Position : Positive) return Indexed_File_Key
   is
   begin
      if Index.Files.Is_Empty
        or else Position < Index.Files.First_Index
        or else Position > Index.Files.Last_Index
      then
         return (others => <>);
      end if;
      return Index.Files (Position).Key;
   end File_Key_At;

   function File_Analysis_At
     (Index : Index_State;
      Position : Positive) return Editor.Ada_Language_Model.Analysis_Result
   is
      Empty : Editor.Ada_Language_Model.Analysis_Result;
   begin
      if Index.Files.Is_Empty
        or else Position < Index.Files.First_Index
        or else Position > Index.Files.Last_Index
      then
         return Empty;
      end if;
      return Index.Files (Position).Analysis;
   end File_Analysis_At;

   function Unit_Count (Index : Index_State) return Natural is
   begin
      return Natural (Index.Units.Length);
   end Unit_Count;

   function Symbol_Count (Index : Index_State) return Natural is
      Count : Natural := 0;
   begin
      for F of Index.Files loop
         Count := Count + Editor.Ada_Language_Model.Symbol_Count (F.Analysis);
      end loop;
      return Count;
   end Symbol_Count;

   function Overflowed (Index : Index_State) return Boolean is
   begin
      --  the public aggregate overflow flag must include both
      --  the index file-table budget and every bounded per-file analysis.
      --  A project index can stay within Max_Index_Files while still
      --  containing an analysis truncated at Max_Analysis_Symbols; status
      --  commands and semantic callers must see that conservative state
      --  without having to perform a lookup first.
      if Index.Index_Overflow or else Index.Unit_Overflow then
         return True;
      end if;

      for F of Index.Files loop
         if Editor.Ada_Language_Model.Overflowed (F.Analysis) then
            return True;
         end if;
      end loop;

      return False;
   end Overflowed;

   function Fingerprint (Index : Index_State) return Natural is
   begin
      return Index.Index_Fingerprint;
   end Fingerprint;

end Editor.Ada_Project_Index;
