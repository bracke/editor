with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Call_Candidates is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Declarative_Regions.Region_Id;
   use type Editor.Ada_Direct_Visibility.Declaration_Id;
   use type Editor.Ada_Direct_Visibility.Lookup_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Trim (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trim;

   function Normalize (Text : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (Trim (Text));
   end Normalize;

   function Is_Name_Char (C : Character) return Boolean is
   begin
      return (C in 'A' .. 'Z') or else (C in 'a' .. 'z')
        or else (C in '0' .. '9') or else C = '_'
        or else C = '.' or else C = '"' or else C = '+'
        or else C = '-' or else C = '*' or else C = '/'
        or else C = '=' or else C = '<' or else C = '>';
   end Is_Name_Char;

   function Hash_Text (Text : String) return Natural is
      H : Natural := 2166136261 mod Natural'Last;
   begin
      for C of Text loop
         H := (H * 16777619 + Character'Pos (C) + 1) mod Natural'Last;
      end loop;
      return H;
   end Hash_Text;

   procedure Mix (Model : in out Call_Candidate_Model; Value : Natural) is
   begin
      Model.Result_Fingerprint :=
        (Model.Result_Fingerprint * 65599 + Value + 83) mod Natural'Last;
   end Mix;

   function Empty_Candidate return Call_Candidate_Info is
   begin
      return (Id => No_Call_Candidate,
              Node => Editor.Ada_Syntax_Tree.No_Node,
              Region => Editor.Ada_Declarative_Regions.No_Region,
              Name => Null_Unbounded_String,
              Normalized_Name => Null_Unbounded_String,
              Source => Candidate_Direct_Visible,
              Declaration => Editor.Ada_Direct_Visibility.No_Declaration,
              Status => Call_Candidate_Not_Resolved,
              Candidate_Count => 0,
              Start_Line => 1,
              End_Line => 1,
              Fingerprint => 0);
   end Empty_Candidate;

   function Clean_Call_Name (Text : String) return String is
      T        : constant String := Trim (Text);
      Stop     : Natural := 0;
      First    : Natural := 0;
      Operator : Boolean := False;
   begin
      if T = "" then
         return "";
      end if;

      for I in T'Range loop
         if T (I) = '(' then
            Stop := I - 1;
            exit;
         end if;
      end loop;

      if Stop = 0 then
         Stop := T'Last;
      end if;

      while Stop >= T'First and then T (Stop) = ' ' loop
         Stop := Stop - 1;
         exit when Stop < T'First;
      end loop;

      if Stop < T'First then
         return "";
      end if;

      if T (T'First) = '"' then
         Operator := True;
      end if;

      for I in reverse T'First .. Stop loop
         if Operator then
            if T (I) = '"' and then I /= Stop then
               First := I;
               exit;
            end if;
         elsif not Is_Name_Char (T (I)) then
            First := I + 1;
            exit;
         elsif I = T'First then
            First := T'First;
         end if;
      end loop;

      if First = 0 or else First > Stop then
         return "";
      end if;

      return Trim (T (First .. Stop));
   end Clean_Call_Name;

   function Is_Call_Node (Kind : Editor.Ada_Syntax_Tree.Node_Kind) return Boolean is
      use type Editor.Ada_Syntax_Tree.Node_Kind;
   begin
      return Kind = Editor.Ada_Syntax_Tree.Node_Function_Call
        or else Kind = Editor.Ada_Syntax_Tree.Node_Call_Statement;
   end Is_Call_Node;

   function Candidate_Source_For
     (Direct     : Editor.Ada_Direct_Visibility.Lookup_Result;
      Primitive  : Editor.Ada_Direct_Visibility.Lookup_Result)
      return Candidate_Source
   is
   begin
      if Direct.Status /= Editor.Ada_Direct_Visibility.Lookup_Not_Found then
         if Direct.Region /= Editor.Ada_Declarative_Regions.No_Region then
            return Candidate_Direct_Visible;
         else
            return Candidate_Use_Package_Visible;
         end if;
      elsif Primitive.Status /= Editor.Ada_Direct_Visibility.Lookup_Not_Found then
         return Candidate_Use_Type_Primitive;
      else
         return Candidate_Direct_Visible;
      end if;
   end Candidate_Source_For;

   function Lookup_Call
     (Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Uses       : Editor.Ada_Use_Visibility.Use_Visibility_Model;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Primitives : Editor.Ada_Use_Type_Operators.Primitive_Use_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Name       : String) return Editor.Ada_Direct_Visibility.Lookup_Result
   is
      Direct : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
        Editor.Ada_Use_Visibility.Lookup_Visible
          (Visibility, Uses, Regions, Region, Name);
      Primitive : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
        Editor.Ada_Use_Type_Operators.Lookup_Operator (Primitives, Region, Name);
      Result : Editor.Ada_Direct_Visibility.Lookup_Result := Direct;
   begin
      if Direct.Status = Editor.Ada_Direct_Visibility.Lookup_Not_Found then
         return Primitive;
      elsif Primitive.Status = Editor.Ada_Direct_Visibility.Lookup_Not_Found then
         return Direct;
      else
         Result.Status := Editor.Ada_Direct_Visibility.Lookup_Ambiguous;
         Result.Match_Count := Direct.Match_Count + Primitive.Match_Count;
         return Result;
      end if;
   end Lookup_Call;

   procedure Add_Candidate
     (Model      : in out Call_Candidate_Model;
      Node       : Editor.Ada_Syntax_Tree.Node_Info;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Name       : String;
      Source     : Candidate_Source;
      Decl       : Editor.Ada_Direct_Visibility.Declaration_Id;
      Status     : Call_Candidate_Status;
      Count      : Natural)
   is
      Id   : constant Call_Candidate_Id :=
        Call_Candidate_Id (Natural (Model.Candidates.Length) + 1);
      Norm : constant String := Normalize (Name);
      Info : Call_Candidate_Info;
   begin
      Info.Id := Id;
      Info.Node := Node.Id;
      Info.Region := Region;
      Info.Name := To_Unbounded_String (Trim (Name));
      Info.Normalized_Name := To_Unbounded_String (Norm);
      Info.Source := Source;
      Info.Declaration := Decl;
      Info.Status := Status;
      Info.Candidate_Count := Count;
      Info.Start_Line := Node.Source_Span.Start_Line;
      Info.End_Line := Node.Source_Span.End_Line;
      Info.Fingerprint :=
        (Call_Candidate_Status'Pos (Status) * 1000003
         + Candidate_Source'Pos (Source) * 100003
         + Natural (Node.Id) * 1009
         + Natural (Region) * 97
         + Natural (Decl) * 53
         + Count * 17
         + Hash_Text (Norm)) mod Natural'Last;
      Model.Candidates.Append (Info);
      Mix (Model, Info.Fingerprint);
   end Add_Candidate;

   procedure Clear (Model : in out Call_Candidate_Model) is
   begin
      Model.Candidates.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Uses       : Editor.Ada_Use_Visibility.Use_Visibility_Model;
      Primitives : Editor.Ada_Use_Type_Operators.Primitive_Use_Model)
      return Call_Candidate_Model
   is
      Model : Call_Candidate_Model;
   begin
      Clear (Model);

      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
         begin
            if Is_Call_Node (Node.Kind) then
               declare
                  Name : constant String := Clean_Call_Name (To_String (Node.Label));
                  Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
                    Editor.Ada_Declarative_Regions.Region_For_Node (Regions, Node.Id);
                  Direct : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
                    Editor.Ada_Use_Visibility.Lookup_Visible
                      (Visibility, Uses, Regions, Region, Name);
                  Primitive : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
                    Editor.Ada_Use_Type_Operators.Lookup_Operator (Primitives, Region, Name);
                  Combined : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
                    Lookup_Call (Visibility, Uses, Regions, Primitives, Region, Name);
                  Source : constant Candidate_Source := Candidate_Source_For (Direct, Primitive);
                  Status : Call_Candidate_Status := Call_Candidate_No_Candidates;
                  Decl   : Editor.Ada_Direct_Visibility.Declaration_Id := Combined.Declaration;
                  Count  : Natural := Combined.Match_Count;
               begin
                  if Name = "" then
                     Status := Call_Candidate_No_Call_Name;
                     Count := 0;
                     Decl := Editor.Ada_Direct_Visibility.No_Declaration;
                  elsif Combined.Status = Editor.Ada_Direct_Visibility.Lookup_Not_Found then
                     Status := Call_Candidate_No_Candidates;
                  elsif Combined.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous then
                     Status := Call_Candidate_Ambiguous;
                  else
                     Status := Call_Candidate_Found;
                  end if;

                  Add_Candidate (Model, Node, Region, Name, Source, Decl, Status, Count);
               end;
            end if;
         end;
      end loop;

      Mix (Model, Editor.Ada_Syntax_Tree.Fingerprint (Tree));
      Mix (Model, Editor.Ada_Declarative_Regions.Fingerprint (Regions));
      Mix (Model, Editor.Ada_Direct_Visibility.Fingerprint (Visibility));
      Mix (Model, Editor.Ada_Use_Visibility.Fingerprint (Uses));
      Mix (Model, Editor.Ada_Use_Type_Operators.Fingerprint (Primitives));
      return Model;
   end Build;

   function Has_Call_Candidates (Model : Call_Candidate_Model) return Boolean is
   begin
      return not Model.Candidates.Is_Empty;
   end Has_Call_Candidates;

   function Call_Candidate_Count (Model : Call_Candidate_Model) return Natural is
   begin
      return Natural (Model.Candidates.Length);
   end Call_Candidate_Count;

   function Call_Candidate_At
     (Model : Call_Candidate_Model;
      Index : Positive) return Call_Candidate_Info
   is
   begin
      if Index > Natural (Model.Candidates.Length) then
         return Empty_Candidate;
      end if;
      return Model.Candidates (Index);
   end Call_Candidate_At;

   function Call_Candidate
     (Model : Call_Candidate_Model;
      Id    : Call_Candidate_Id) return Call_Candidate_Info
   is
   begin
      if Id = No_Call_Candidate or else Natural (Id) > Natural (Model.Candidates.Length) then
         return Empty_Candidate;
      end if;
      return Model.Candidates (Positive (Id));
   end Call_Candidate;

   function Candidate_Count_For_Node
     (Model : Call_Candidate_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Model.Candidates loop
         if Info.Node = Node then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Candidate_Count_For_Node;

   function Candidate_At_For_Node
     (Model : Call_Candidate_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id;
      Index : Positive) return Call_Candidate_Info
   is
      Count : Natural := 0;
   begin
      for Info of Model.Candidates loop
         if Info.Node = Node then
            Count := Count + 1;
            if Count = Index then
               return Info;
            end if;
         end if;
      end loop;
      return Empty_Candidate;
   end Candidate_At_For_Node;

   function Fingerprint (Model : Call_Candidate_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Call_Candidates;
