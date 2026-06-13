with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Use_Type_Operators is

   use type Editor.Ada_Declarative_Regions.Region_Id;
   use type Editor.Ada_Direct_Visibility.Declaration_Id;
   use type Editor.Ada_Direct_Visibility.Declaration_Kind;
   use type Editor.Ada_Direct_Visibility.Lookup_Status;
   use type Editor.Ada_Use_Visibility.Use_Clause_Kind;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Trim (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trim;

   function Normalize (Text : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (Trim (Text));
   end Normalize;

   function Hash_Text (Text : String) return Natural is
      H : Natural := 2166136261 mod Natural'Last;
   begin
      for C of Text loop
         H := (H * 16777619 + Character'Pos (C) + 1) mod Natural'Last;
      end loop;
      return H;
   end Hash_Text;

   procedure Mix (Model : in out Primitive_Use_Model; Value : Natural) is
   begin
      Model.Result_Fingerprint :=
        (Model.Result_Fingerprint * 65599 + Value + 83) mod Natural'Last;
   end Mix;

   function Empty_Primitive_Use return Primitive_Use_Info is
   begin
      return (Id => No_Primitive_Use,
              Kind => Primitive_Use_Type_Operator,
              Status => Primitive_Use_Unresolved_Type,
              Clause => Editor.Ada_Use_Visibility.No_Use_Clause,
              Clause_Region => Editor.Ada_Declarative_Regions.No_Region,
              Type_Name => Null_Unbounded_String,
              Normalized_Type_Name => Null_Unbounded_String,
              Type_Declaration => Editor.Ada_Direct_Visibility.No_Declaration,
              Primitive_Region => Editor.Ada_Declarative_Regions.No_Region,
              Primitive_Declaration => Editor.Ada_Direct_Visibility.No_Declaration,
              Primitive_Name => Null_Unbounded_String,
              Normalized_Primitive => Null_Unbounded_String,
              Is_Operator => False,
              Start_Line => 1,
              End_Line => 1,
              Fingerprint => 0);
   end Empty_Primitive_Use;

   function Last_Dot (Text : String) return Natural is
      Result : Natural := 0;
   begin
      for I in Text'Range loop
         if Text (I) = '.' then
            Result := I;
         end if;
      end loop;
      return Result;
   end Last_Dot;

   function Target_Region_For_Declaration
     (Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Decl    : Editor.Ada_Direct_Visibility.Declaration_Info)
      return Editor.Ada_Declarative_Regions.Region_Id
   is
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

   function Resolve_Type_Declaration
     (Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Uses       : Editor.Ada_Use_Visibility.Use_Visibility_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Name       : String) return Editor.Ada_Direct_Visibility.Lookup_Result
   is
      Dot : constant Natural := Last_Dot (Name);
   begin
      if Dot = 0 or else Dot = Name'First or else Dot = Name'Last then
         return Editor.Ada_Use_Visibility.Lookup_Visible
           (Visibility, Uses, Regions, Region, Name);
      end if;

      declare
         Prefix : constant String := Trim (Name (Name'First .. Dot - 1));
         Leaf   : constant String := Trim (Name (Dot + 1 .. Name'Last));
         Prefix_Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
           Editor.Ada_Use_Visibility.Lookup_Visible
             (Visibility, Uses, Regions, Region, Prefix);
      begin
         if Prefix_Lookup.Status /= Editor.Ada_Direct_Visibility.Lookup_Found then
            return (Status => Prefix_Lookup.Status,
                    Declaration => Prefix_Lookup.Declaration,
                    Region => Region,
                    Match_Count => Prefix_Lookup.Match_Count);
         end if;

         declare
            Prefix_Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
              Editor.Ada_Direct_Visibility.Declaration
                (Visibility, Prefix_Lookup.Declaration);
            Prefix_Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
              Target_Region_For_Declaration (Regions, Prefix_Decl);
         begin
            if Prefix_Region = Editor.Ada_Declarative_Regions.No_Region then
               return (Status => Editor.Ada_Direct_Visibility.Lookup_Not_Found,
                       Declaration => Editor.Ada_Direct_Visibility.No_Declaration,
                       Region => Region,
                       Match_Count => 0);
            end if;
            return Editor.Ada_Direct_Visibility.Lookup_Direct
              (Visibility, Prefix_Region, Leaf);
         end;
      end;
   end Resolve_Type_Declaration;

   function Is_Type_Declaration
     (Kind : Editor.Ada_Direct_Visibility.Declaration_Kind) return Boolean is
   begin
      return Kind = Editor.Ada_Direct_Visibility.Declaration_Type
        or else Kind = Editor.Ada_Direct_Visibility.Declaration_Subtype
        or else Kind = Editor.Ada_Direct_Visibility.Declaration_Formal_Type;
   end Is_Type_Declaration;

   function Unquote (Text : String) return String is
      T : constant String := Trim (Text);
   begin
      if T'Length >= 2 and then T (T'First) = '"' and then T (T'Last) = '"' then
         return T (T'First + 1 .. T'Last - 1);
      end if;
      return T;
   end Unquote;

   function Is_Operator_Name (Text : String) return Boolean is
      N : constant String := Normalize (Unquote (Text));
   begin
      return N = "and" or else N = "or" or else N = "xor"
        or else N = "=" or else N = "/=" or else N = "<" or else N = "<="
        or else N = ">" or else N = ">=" or else N = "+" or else N = "-"
        or else N = "&" or else N = "*" or else N = "/" or else N = "mod"
        or else N = "rem" or else N = "**" or else N = "abs" or else N = "not";
   end Is_Operator_Name;

   procedure Add_Primitive
     (Model       : in out Primitive_Use_Model;
      Clause      : Editor.Ada_Use_Visibility.Use_Clause_Info;
      Kind        : Primitive_Use_Kind;
      Status      : Primitive_Use_Status;
      Type_Decl   : Editor.Ada_Direct_Visibility.Declaration_Id;
      Prim_Region : Editor.Ada_Declarative_Regions.Region_Id;
      Prim_Decl   : Editor.Ada_Direct_Visibility.Declaration_Info;
      Is_Operator : Boolean)
   is
      Id : constant Primitive_Use_Id :=
        Primitive_Use_Id (Natural (Model.Uses.Length) + 1);
      Prim_Name : constant String := Unquote (To_String (Prim_Decl.Name));
      Info : Primitive_Use_Info;
   begin
      Info.Id := Id;
      Info.Kind := Kind;
      Info.Status := Status;
      Info.Clause := Clause.Id;
      Info.Clause_Region := Clause.Region;
      Info.Type_Name := Clause.Name;
      Info.Normalized_Type_Name := Clause.Normalized;
      Info.Type_Declaration := Type_Decl;
      Info.Primitive_Region := Prim_Region;
      Info.Primitive_Declaration := Prim_Decl.Id;
      Info.Primitive_Name := To_Unbounded_String (Prim_Name);
      Info.Normalized_Primitive := To_Unbounded_String (Normalize (Prim_Name));
      Info.Is_Operator := Is_Operator;
      Info.Start_Line := Clause.Start_Line;
      Info.End_Line := Clause.End_Line;
      Info.Fingerprint :=
        (Primitive_Use_Kind'Pos (Kind) * 1000003
         + Primitive_Use_Status'Pos (Status) * 65599
         + Natural (Clause.Id) * 1009
         + Natural (Clause.Region) * 97
         + Natural (Type_Decl) * 53
         + Natural (Prim_Region) * 31
         + Natural (Prim_Decl.Id) * 17
         + Hash_Text (To_String (Info.Normalized_Type_Name)) * 11
         + Hash_Text (To_String (Info.Normalized_Primitive))) mod Natural'Last;
      Model.Uses.Append (Info);
      Mix (Model, Info.Fingerprint);
   end Add_Primitive;

   procedure Add_Status_Only
     (Model     : in out Primitive_Use_Model;
      Clause    : Editor.Ada_Use_Visibility.Use_Clause_Info;
      Kind      : Primitive_Use_Kind;
      Status    : Primitive_Use_Status;
      Type_Decl : Editor.Ada_Direct_Visibility.Declaration_Id :=
        Editor.Ada_Direct_Visibility.No_Declaration;
      Prim_Region : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region)
   is
      Dummy : Editor.Ada_Direct_Visibility.Declaration_Info;
   begin
      Add_Primitive
        (Model, Clause, Kind, Status, Type_Decl, Prim_Region, Dummy, False);
   end Add_Status_Only;

   procedure Add_Clause_Primitives
     (Model      : in out Primitive_Use_Model;
      Clause     : Editor.Ada_Use_Visibility.Use_Clause_Info;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Uses       : Editor.Ada_Use_Visibility.Use_Visibility_Model)
   is
      Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
        Resolve_Type_Declaration
          (Regions, Visibility, Uses, Clause.Region, To_String (Clause.Name));
      Type_Decl : Editor.Ada_Direct_Visibility.Declaration_Info;
      Primitive_Region : Editor.Ada_Declarative_Regions.Region_Id;
      Wanted_Kind : constant Primitive_Use_Kind :=
        (if Clause.Kind = Editor.Ada_Use_Visibility.Use_All_Type_Clause
         then Primitive_Use_All_Type_Subprogram
         else Primitive_Use_Type_Operator);
   begin
      if Lookup.Status /= Editor.Ada_Direct_Visibility.Lookup_Found then
         Add_Status_Only (Model, Clause, Wanted_Kind, Primitive_Use_Unresolved_Type);
         return;
      end if;

      Type_Decl := Editor.Ada_Direct_Visibility.Declaration
        (Visibility, Lookup.Declaration);
      if not Is_Type_Declaration (Type_Decl.Kind) then
         Add_Status_Only
           (Model, Clause, Wanted_Kind, Primitive_Use_Target_Not_Type, Type_Decl.Id);
         return;
      end if;

      Primitive_Region := Type_Decl.Region;
      if Primitive_Region = Editor.Ada_Declarative_Regions.No_Region then
         Add_Status_Only
           (Model, Clause, Wanted_Kind, Primitive_Use_No_Primitive_Region,
            Type_Decl.Id, Primitive_Region);
         return;
      end if;

      for Index in 1 .. Editor.Ada_Direct_Visibility.Direct_Declaration_Count
        (Visibility, Primitive_Region)
      loop
         declare
            Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
              Editor.Ada_Direct_Visibility.Declaration
                (Visibility,
                 Editor.Ada_Direct_Visibility.Direct_Declaration_At
                   (Visibility, Primitive_Region, Index));
            Is_Op : constant Boolean := Is_Operator_Name (To_String (Decl.Name));
         begin
            if Decl.Kind = Editor.Ada_Direct_Visibility.Declaration_Subprogram
              and then (Is_Op
                        or else Clause.Kind = Editor.Ada_Use_Visibility.Use_All_Type_Clause)
            then
               Add_Primitive
                 (Model,
                  Clause,
                  (if Clause.Kind = Editor.Ada_Use_Visibility.Use_All_Type_Clause
                   then Primitive_Use_All_Type_Subprogram
                   else Primitive_Use_Type_Operator),
                  Primitive_Use_Found,
                  Type_Decl.Id,
                  Primitive_Region,
                  Decl,
                  Is_Op);
            end if;
         end;
      end loop;
   end Add_Clause_Primitives;

   procedure Clear (Model : in out Primitive_Use_Model) is
   begin
      Model.Uses.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Uses       : Editor.Ada_Use_Visibility.Use_Visibility_Model)
      return Primitive_Use_Model
   is
      pragma Unreferenced (Tree);
      Model : Primitive_Use_Model;
   begin
      Clear (Model);
      for Index in 1 .. Editor.Ada_Use_Visibility.Use_Clause_Count (Uses) loop
         declare
            Clause : constant Editor.Ada_Use_Visibility.Use_Clause_Info :=
              Editor.Ada_Use_Visibility.Use_Clause_At (Uses, Index);
         begin
            if Clause.Kind = Editor.Ada_Use_Visibility.Use_Type_Clause
              or else Clause.Kind = Editor.Ada_Use_Visibility.Use_All_Type_Clause
            then
               Add_Clause_Primitives (Model, Clause, Regions, Visibility, Uses);
            end if;
         end;
      end loop;

      Mix (Model, Editor.Ada_Declarative_Regions.Fingerprint (Regions));
      Mix (Model, Editor.Ada_Direct_Visibility.Fingerprint (Visibility));
      Mix (Model, Editor.Ada_Use_Visibility.Fingerprint (Uses));
      return Model;
   end Build;

   function Has_Primitive_Uses (Model : Primitive_Use_Model) return Boolean is
   begin
      return not Model.Uses.Is_Empty;
   end Has_Primitive_Uses;

   function Primitive_Use_Count (Model : Primitive_Use_Model) return Natural is
   begin
      return Natural (Model.Uses.Length);
   end Primitive_Use_Count;

   function Primitive_Use_At
     (Model : Primitive_Use_Model;
      Index : Positive) return Primitive_Use_Info
   is
   begin
      if Index > Natural (Model.Uses.Length) then
         return Empty_Primitive_Use;
      end if;
      return Model.Uses (Index);
   end Primitive_Use_At;

   function Primitive_Use
     (Model : Primitive_Use_Model;
      Id    : Primitive_Use_Id) return Primitive_Use_Info
   is
   begin
      if Id = No_Primitive_Use or else Natural (Id) > Natural (Model.Uses.Length) then
         return Empty_Primitive_Use;
      end if;
      return Model.Uses (Positive (Id));
   end Primitive_Use;

   function Lookup_Operator
     (Model  : Primitive_Use_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name   : String) return Editor.Ada_Direct_Visibility.Lookup_Result
   is
      Wanted : constant String := Normalize (Unquote (Name));
      Result : Editor.Ada_Direct_Visibility.Lookup_Result :=
        (Status => Editor.Ada_Direct_Visibility.Lookup_Not_Found,
         Declaration => Editor.Ada_Direct_Visibility.No_Declaration,
         Region => Region,
         Match_Count => 0);
   begin
      for Info of Model.Uses loop
         if Info.Clause_Region = Region
           and then Info.Status = Primitive_Use_Found
           and then Info.Is_Operator
           and then To_String (Info.Normalized_Primitive) = Wanted
         then
            Result.Match_Count := Result.Match_Count + 1;
            if Result.Declaration = Editor.Ada_Direct_Visibility.No_Declaration then
               Result.Declaration := Info.Primitive_Declaration;
               Result.Region := Info.Primitive_Region;
            end if;
         end if;
      end loop;

      if Result.Match_Count = 1 then
         Result.Status := Editor.Ada_Direct_Visibility.Lookup_Found;
      elsif Result.Match_Count > 1 then
         Result.Status := Editor.Ada_Direct_Visibility.Lookup_Ambiguous;
      end if;
      return Result;
   end Lookup_Operator;

   function Fingerprint (Model : Primitive_Use_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Use_Type_Operators;
