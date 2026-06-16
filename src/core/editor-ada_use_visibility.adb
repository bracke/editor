with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Use_Visibility is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Declarative_Regions.Region_Id;
   use type Editor.Ada_Direct_Visibility.Declaration_Id;
   use type Editor.Ada_Direct_Visibility.Lookup_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;


   function Trim (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trim;

   function Lower (Text : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (Text);
   end Lower;

   function Normalize (Text : String) return String is
   begin
      return Lower (Trim (Text));
   end Normalize;

   function Starts_With_Word (Text : String; Word : String) return Boolean is
      L : constant String := Lower (Trim (Text));
      W : constant String := Lower (Word);
   begin
      if L'Length < W'Length then
         return False;
      elsif L (L'First .. L'First + W'Length - 1) /= W then
         return False;
      elsif L'Length = W'Length then
         return True;
      else
         declare
            Next : constant Character := L (L'First + W'Length);
         begin
            return not (Next in 'a' .. 'z' or else Next in '0' .. '9' or else Next = '_');
         end;
      end if;
   end Starts_With_Word;

   function Hash_Mix
     (Seed       : Natural;
      Addend     : Long_Long_Integer;
      Multiplier : Long_Long_Integer;
      Modulus    : Long_Long_Integer := Long_Long_Integer (Natural'Last))
      return Natural
   is
   begin
      return Natural
        ((Long_Long_Integer (Seed) * Multiplier + Addend) mod Modulus);
   end Hash_Mix;

   function Hash_Text (Text : String) return Natural is
      H : Natural := 2166136261 mod Natural'Last;
   begin
      for C of Text loop
         H := Hash_Mix
           (H, Long_Long_Integer (Character'Pos (C)) + 1, 16_777_619);
      end loop;
      return H;
   end Hash_Text;

   procedure Mix (Model : in out Use_Visibility_Model; Value : Natural) is
   begin
      Model.Result_Fingerprint :=
        Hash_Mix (Model.Result_Fingerprint, Long_Long_Integer (Value) + 59, 65_599);
   end Mix;

   function Strip_Terminator (Text : String) return String is
      T : constant String := Trim (Text);
   begin
      if T'Length > 0 and then T (T'Last) = ';' then
         return Trim (T (T'First .. T'Last - 1));
      end if;
      return T;
   end Strip_Terminator;

   function Tail_After_Use (Text : String) return String is
      T : constant String := Strip_Terminator (Text);
   begin
      if Starts_With_Word (T, "use") and then T'Length > 3 then
         return Trim (T (T'First + 3 .. T'Last));
      end if;
      return "";
   end Tail_After_Use;

   function Clause_Kind (Text : String) return Use_Clause_Kind is
      Tail : constant String := Tail_After_Use (Text);
      L    : constant String := Lower (Tail);
   begin
      if Starts_With_Word (L, "all") then
         return Use_All_Type_Clause;
      elsif Starts_With_Word (L, "type") then
         return Use_Type_Clause;
      else
         return Use_Package_Clause;
      end if;
   end Clause_Kind;

   function Name_List_Text (Text : String; Kind : Use_Clause_Kind) return String is
      Tail : constant String := Tail_After_Use (Text);
   begin
      case Kind is
         when Use_Package_Clause =>
            return Tail;
         when Use_Type_Clause =>
            if Tail'Length > 4 then
               return Trim (Tail (Tail'First + 4 .. Tail'Last));
            end if;
            return "";
         when Use_All_Type_Clause =>
            --  "all type" is eight characters plus the separating blank in the
            --  source spelling; tolerate malformed spacing by trimming the
            --  remainder after both reserved words.
            declare
               L : constant String := Lower (Tail);
            begin
               if Starts_With_Word (L, "all") and then Tail'Length > 3 then
                  declare
                     After_All : constant String := Trim (Tail (Tail'First + 3 .. Tail'Last));
                  begin
                     if Starts_With_Word (After_All, "type") and then After_All'Length > 4 then
                        return Trim (After_All (After_All'First + 4 .. After_All'Last));
                     end if;
                  end;
               end if;
            end;
            return "";
      end case;
   end Name_List_Text;

   function Target_Region_For_Declaration
     (Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Decl    : Editor.Ada_Direct_Visibility.Declaration_Info)
      return Editor.Ada_Declarative_Regions.Region_Id
   is
      use type Editor.Ada_Declarative_Regions.Region_Id;
      Candidate : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.Region_For_Node (Regions, Decl.Node);
      Info : constant Editor.Ada_Declarative_Regions.Region_Info :=
        Editor.Ada_Declarative_Regions.Region (Regions, Candidate);
   begin
      if Candidate = Editor.Ada_Declarative_Regions.No_Region then
         return Editor.Ada_Declarative_Regions.No_Region;
      elsif Info.Owner_Node = Decl.Node then
         return Candidate;
      else
         return Editor.Ada_Declarative_Regions.No_Region;
      end if;
   end Target_Region_For_Declaration;

   procedure Add_Clause
     (Model      : in out Use_Visibility_Model;
      Kind       : Use_Clause_Kind;
      Name       : String;
      Node       : Editor.Ada_Syntax_Tree.Node_Info;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model)
   is
      use type Editor.Ada_Direct_Visibility.Lookup_Status;
      use type Editor.Ada_Direct_Visibility.Declaration_Id;
      Id      : constant Use_Clause_Id := Use_Clause_Id (Natural (Model.Clauses.Length) + 1);
      Norm    : constant String := Normalize (Name);
      Lookup  : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
        Editor.Ada_Direct_Visibility.Lookup_Visible (Visibility, Regions, Region, Name);
      Info    : Use_Clause_Info;
      Decl    : Editor.Ada_Direct_Visibility.Declaration_Info;
   begin
      if Norm = "" or else Region = Editor.Ada_Declarative_Regions.No_Region then
         return;
      end if;

      Info.Id := Id;
      Info.Kind := Kind;
      Info.Name := To_Unbounded_String (Trim (Name));
      Info.Normalized := To_Unbounded_String (Norm);
      Info.Node := Node.Id;
      Info.Region := Region;
      Info.Start_Line := Node.Source_Span.Start_Line;
      Info.End_Line := Node.Source_Span.End_Line;

      if Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found
        and then Lookup.Declaration /= Editor.Ada_Direct_Visibility.No_Declaration
      then
         Info.Target_Declaration := Lookup.Declaration;
         Decl := Editor.Ada_Direct_Visibility.Declaration (Visibility, Lookup.Declaration);
         Info.Target_Region := Target_Region_For_Declaration (Regions, Decl);
         Info.Is_Resolved := Info.Target_Region /= Editor.Ada_Declarative_Regions.No_Region;
      end if;

      Info.Fingerprint :=
        (Use_Clause_Kind'Pos (Kind) * 1000003
         + Natural (Node.Id) * 1009
         + Natural (Region) * 97
         + Natural (Info.Target_Declaration) * 53
         + Natural (Info.Target_Region) * 17
         + Node.Source_Span.Start_Line * 11
         + Hash_Text (Norm)) mod Natural'Last;
      Model.Clauses.Append (Info);
      Mix (Model, Info.Fingerprint);
   end Add_Clause;

   procedure Add_Use_Clause_Names
     (Model      : in out Use_Visibility_Model;
      Node       : Editor.Ada_Syntax_Tree.Node_Info;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model)
   is
      Kind  : constant Use_Clause_Kind := Clause_Kind (To_String (Node.Label));
      Names : constant String := Name_List_Text (To_String (Node.Label), Kind);
      Start : Natural := Names'First;
      Comma : Natural;
   begin
      if Names = "" then
         return;
      end if;

      while Start <= Names'Last loop
         Comma := 0;
         for I in Start .. Names'Last loop
            if Names (I) = ',' then
               Comma := I;
               exit;
            end if;
         end loop;

         declare
            Piece : constant String :=
              Trim (if Comma = 0 then Names (Start .. Names'Last) else Names (Start .. Comma - 1));
         begin
            if Piece /= "" then
               Add_Clause (Model, Kind, Piece, Node, Region, Regions, Visibility);
            end if;
         end;

         exit when Comma = 0;
         Start := Comma + 1;
      end loop;
   end Add_Use_Clause_Names;

   function Empty_Clause return Use_Clause_Info is
   begin
      return (Id => No_Use_Clause,
              Kind => Use_Package_Clause,
              Name => Null_Unbounded_String,
              Normalized => Null_Unbounded_String,
              Node => Editor.Ada_Syntax_Tree.No_Node,
              Region => Editor.Ada_Declarative_Regions.No_Region,
              Target_Declaration => Editor.Ada_Direct_Visibility.No_Declaration,
              Target_Region => Editor.Ada_Declarative_Regions.No_Region,
              Is_Resolved => False,
              Start_Line => 1,
              End_Line => 1,
              Fingerprint => 0);
   end Empty_Clause;

   procedure Clear (Model : in out Use_Visibility_Model) is
   begin
      Model.Clauses.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model)
      return Use_Visibility_Model
   is
      use type Editor.Ada_Syntax_Tree.Node_Kind;
      Model : Use_Visibility_Model;
   begin
      Clear (Model);

      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
         begin
            if Node.Kind = Editor.Ada_Syntax_Tree.Node_Use_Clause then
               Add_Use_Clause_Names
                 (Model,
                  Node,
                  Editor.Ada_Declarative_Regions.Region_For_Node (Regions, Node.Id),
                  Regions,
                  Visibility);
            end if;
         end;
      end loop;

      Mix (Model, Editor.Ada_Syntax_Tree.Fingerprint (Tree));
      Mix (Model, Editor.Ada_Declarative_Regions.Fingerprint (Regions));
      Mix (Model, Editor.Ada_Direct_Visibility.Fingerprint (Visibility));
      return Model;
   end Build;

   function Has_Use_Clauses (Model : Use_Visibility_Model) return Boolean is
   begin
      return not Model.Clauses.Is_Empty;
   end Has_Use_Clauses;

   function Use_Clause_Count (Model : Use_Visibility_Model) return Natural is
   begin
      return Natural (Model.Clauses.Length);
   end Use_Clause_Count;

   function Use_Clause_At
     (Model : Use_Visibility_Model;
      Index : Positive) return Use_Clause_Info
   is
   begin
      if Index > Natural (Model.Clauses.Length) then
         return Empty_Clause;
      end if;
      return Model.Clauses (Index);
   end Use_Clause_At;

   function Use_Clause
     (Model : Use_Visibility_Model;
      Id    : Use_Clause_Id) return Use_Clause_Info
   is
   begin
      if Id = No_Use_Clause or else Natural (Id) > Natural (Model.Clauses.Length) then
         return Empty_Clause;
      end if;
      return Model.Clauses (Positive (Id));
   end Use_Clause;

   function Direct_Use_Clause_Count
     (Model  : Use_Visibility_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Model.Clauses loop
         if Info.Region = Region then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Direct_Use_Clause_Count;

   function Direct_Use_Clause_At
     (Model  : Use_Visibility_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Index  : Positive) return Use_Clause_Id
   is
      Count : Natural := 0;
   begin
      for Info of Model.Clauses loop
         if Info.Region = Region then
            Count := Count + 1;
            if Count = Index then
               return Info.Id;
            end if;
         end if;
      end loop;
      return No_Use_Clause;
   end Direct_Use_Clause_At;

   function Lookup_From_Use_Clauses
     (Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Uses       : Use_Visibility_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Name       : String) return Editor.Ada_Direct_Visibility.Lookup_Result
   is
      use type Editor.Ada_Declarative_Regions.Region_Id;
      use type Editor.Ada_Direct_Visibility.Lookup_Status;
      Result : Editor.Ada_Direct_Visibility.Lookup_Result :=
        (Status => Editor.Ada_Direct_Visibility.Lookup_Not_Found,
         Declaration => Editor.Ada_Direct_Visibility.No_Declaration,
         Region => Region,
         Match_Count => 0);
   begin
      for Clause of Uses.Clauses loop
         if Clause.Region = Region
           and then Clause.Kind = Use_Package_Clause
           and then Clause.Target_Region /= Editor.Ada_Declarative_Regions.No_Region
         then
            declare
               Candidate : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
                 Editor.Ada_Direct_Visibility.Lookup_Direct
                   (Visibility, Clause.Target_Region, Name);
            begin
               if Candidate.Status = Editor.Ada_Direct_Visibility.Lookup_Found then
                  Result.Match_Count := Result.Match_Count + 1;
                  if Result.Declaration = Editor.Ada_Direct_Visibility.No_Declaration then
                     Result.Declaration := Candidate.Declaration;
                     Result.Region := Clause.Target_Region;
                  end if;
               elsif Candidate.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous then
                  Result.Match_Count := Result.Match_Count + Candidate.Match_Count;
                  if Result.Declaration = Editor.Ada_Direct_Visibility.No_Declaration then
                     Result.Declaration := Candidate.Declaration;
                     Result.Region := Clause.Target_Region;
                  end if;
               end if;
            end;
         end if;
      end loop;

      if Result.Match_Count = 1 then
         Result.Status := Editor.Ada_Direct_Visibility.Lookup_Found;
      elsif Result.Match_Count > 1 then
         Result.Status := Editor.Ada_Direct_Visibility.Lookup_Ambiguous;
      end if;
      return Result;
   end Lookup_From_Use_Clauses;

   function Lookup_Visible
     (Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Uses       : Use_Visibility_Model;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Name       : String) return Editor.Ada_Direct_Visibility.Lookup_Result
   is
      use type Editor.Ada_Declarative_Regions.Region_Id;
      use type Editor.Ada_Direct_Visibility.Lookup_Status;
      Current : Editor.Ada_Declarative_Regions.Region_Id := Region;
      Result  : Editor.Ada_Direct_Visibility.Lookup_Result;
   begin
      while Current /= Editor.Ada_Declarative_Regions.No_Region loop
         Result := Editor.Ada_Direct_Visibility.Lookup_Direct (Visibility, Current, Name);
         if Result.Status /= Editor.Ada_Direct_Visibility.Lookup_Not_Found then
            Result.Region := Current;
            return Result;
         end if;

         Result := Lookup_From_Use_Clauses (Visibility, Uses, Current, Name);
         if Result.Status /= Editor.Ada_Direct_Visibility.Lookup_Not_Found then
            return Result;
         end if;

         Current := Editor.Ada_Declarative_Regions.Region (Regions, Current).Parent;
      end loop;

      return (Status => Editor.Ada_Direct_Visibility.Lookup_Not_Found,
              Declaration => Editor.Ada_Direct_Visibility.No_Declaration,
              Region => Editor.Ada_Declarative_Regions.No_Region,
              Match_Count => 0);
   end Lookup_Visible;

   function Fingerprint (Model : Use_Visibility_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Use_Visibility;
