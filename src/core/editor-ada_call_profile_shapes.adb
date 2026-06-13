with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Call_Profile_Shapes is

   use type Editor.Ada_Declarative_Regions.Region_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Syntax_Tree.Node_Kind;

   function Trim (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trim;

   function Normalize (Text : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (Trim (Text));
   end Normalize;

   function Contains (Text : String; Pattern : String) return Boolean is
   begin
      return Pattern'Length = 0
        or else Ada.Strings.Fixed.Index (Text, Pattern) /= 0;
   end Contains;

   function Hash_Text (Text : String) return Natural is
      H : Natural := 2166136261 mod Natural'Last;
   begin
      for C of Text loop
         H := (H * 16777619 + Character'Pos (C) + 1) mod Natural'Last;
      end loop;
      return H;
   end Hash_Text;

   procedure Mix (Model : in out Profile_Shape_Model; Value : Natural) is
   begin
      Model.Result_Fingerprint :=
        (Model.Result_Fingerprint * 65599 + Value + 101) mod Natural'Last;
   end Mix;

   function Is_Callable_Declaration
     (Kind : Editor.Ada_Syntax_Tree.Node_Kind) return Boolean is
   begin
      return Kind = Editor.Ada_Syntax_Tree.Node_Subprogram_Declaration
        or else Kind = Editor.Ada_Syntax_Tree.Node_Abstract_Subprogram_Declaration
        or else Kind = Editor.Ada_Syntax_Tree.Node_Null_Procedure_Declaration
        or else Kind = Editor.Ada_Syntax_Tree.Node_Expression_Function_Declaration
        or else Kind = Editor.Ada_Syntax_Tree.Node_Subprogram_Body
        or else Kind = Editor.Ada_Syntax_Tree.Node_Formal_Subprogram_Declaration
        or else Kind = Editor.Ada_Syntax_Tree.Node_Entry_Declaration
        or else Kind = Editor.Ada_Syntax_Tree.Node_Entry_Body
        or else Kind = Editor.Ada_Syntax_Tree.Node_Entry_Body_Stub;
   end Is_Callable_Declaration;

   function Is_Call_Node (Kind : Editor.Ada_Syntax_Tree.Node_Kind) return Boolean is
   begin
      return Kind = Editor.Ada_Syntax_Tree.Node_Function_Call
        or else Kind = Editor.Ada_Syntax_Tree.Node_Call_Statement;
   end Is_Call_Node;

   function Empty_Callable return Callable_Profile_Info is
   begin
      return (Id => No_Callable_Profile,
              Node => Editor.Ada_Syntax_Tree.No_Node,
              Region => Editor.Ada_Declarative_Regions.No_Region,
              Name => Null_Unbounded_String,
              Normalized_Name => Null_Unbounded_String,
              Parameter_Count => 0,
              Defaulted_Parameter_Count => 0,
              Formal_Names => Null_Unbounded_String,
              Defaulted_Formal_Names => Null_Unbounded_String,
              Has_Result => False,
              Result_Subtype => Null_Unbounded_String,
              Status => Callable_Profile_Not_Callable,
              Start_Line => 1,
              End_Line => 1,
              Fingerprint => 0);
   end Empty_Callable;

   function Empty_Actual return Actual_Profile_Info is
   begin
      return (Id => No_Actual_Profile,
              Node => Editor.Ada_Syntax_Tree.No_Node,
              Region => Editor.Ada_Declarative_Regions.No_Region,
              Name => Null_Unbounded_String,
              Normalized_Name => Null_Unbounded_String,
              Positional_Count => 0,
              Named_Count => 0,
              Named_Actual_Names => Null_Unbounded_String,
              Total_Actual_Count => 0,
              Status => Actual_Profile_Not_Call,
              Start_Line => 1,
              End_Line => 1,
              Fingerprint => 0);
   end Empty_Actual;

   function Child_Label
     (Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Parent : Editor.Ada_Syntax_Tree.Node_Id;
      Kind   : Editor.Ada_Syntax_Tree.Node_Kind) return String
   is
   begin
      for Index in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Parent) loop
         declare
            Child_Id : constant Editor.Ada_Syntax_Tree.Node_Id :=
              Editor.Ada_Syntax_Tree.Child_At (Tree, Parent, Index);
            Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node (Tree, Child_Id);
         begin
            if Child.Kind = Kind then
               return To_String (Child.Label);
            end if;
         end;
      end loop;
      return "";
   end Child_Label;

   function Is_Name_Char (C : Character) return Boolean is
   begin
      return (C in 'A' .. 'Z') or else (C in 'a' .. 'z')
        or else (C in '0' .. '9') or else C = '_'
        or else C = '.' or else C = '"' or else C = '+'
        or else C = '-' or else C = '*' or else C = '/'
        or else C = '=' or else C = '<' or else C = '>';
   end Is_Name_Char;

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

      Operator := T (T'First) = '"';

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

   function Between_First_Parens (Text : String; Malformed : out Boolean) return String is
      Open  : Natural := 0;
      Depth : Natural := 0;
   begin
      Malformed := False;
      for I in Text'Range loop
         if Text (I) = '(' then
            if Open = 0 then
               Open := I;
            end if;
            Depth := Depth + 1;
         elsif Text (I) = ')' then
            if Depth = 0 then
               Malformed := True;
               return "";
            end if;
            Depth := Depth - 1;
            if Depth = 0 and then Open /= 0 then
               if I = Open + 1 then
                  return "";
               else
                  return Text (Open + 1 .. I - 1);
               end if;
            end if;
         end if;
      end loop;
      if Open /= 0 then
         Malformed := True;
      end if;
      return "";
   end Between_First_Parens;

   function Append_Normalized_Name
     (List : Unbounded_String;
      Name : String) return Unbounded_String
   is
      N : constant String := Normalize (Name);
   begin
      if N = "" then
         return List;
      elsif To_String (List) = "" then
         return To_Unbounded_String (N);
      else
         return List & "|" & N;
      end if;
   end Append_Normalized_Name;

   procedure Analyze_Profile_Formals
     (Profile        : String;
      Count          : out Natural;
      Defaulted      : out Natural;
      Formal_Names   : out Unbounded_String;
      Defaulted_Names : out Unbounded_String;
      Malformed      : out Boolean)
   is
      P : constant String := Trim (Profile);
      Segment_First : Natural := P'First;

      procedure Add_Segment (First : Natural; Last : Natural) is
         Segment : constant String := Trim (P (First .. Last));
         Colon   : constant Natural := Ada.Strings.Fixed.Index (Segment, ":");
         Default : constant Boolean := Contains (Segment, ":=");
         Names_Last : Natural := 0;
         Name_First : Natural := 0;

         procedure Add_Name (F : Natural; L : Natural) is
            Name : constant String := Trim (Segment (F .. L));
         begin
            if Name = "" then
               Malformed := True;
               return;
            end if;
            Count := Count + 1;
            Formal_Names := Append_Normalized_Name (Formal_Names, Name);
            if Default then
               Defaulted := Defaulted + 1;
               Defaulted_Names := Append_Normalized_Name (Defaulted_Names, Name);
            end if;
         end Add_Name;
      begin
         if Segment = "" then
            return;
         end if;
         if Colon = 0 then
            Malformed := True;
            Count := Count + 1;
            return;
         end if;
         if Colon = Segment'First then
            Malformed := True;
            return;
         end if;

         Names_Last := Colon - 1;
         Name_First := Segment'First;
         for I in Segment'First .. Names_Last loop
            if Segment (I) = ',' then
               if I > Name_First then
                  Add_Name (Name_First, I - 1);
               else
                  Malformed := True;
               end if;
               Name_First := I + 1;
            end if;
         end loop;
         if Name_First <= Names_Last then
            Add_Name (Name_First, Names_Last);
         end if;
      end Add_Segment;
   begin
      Count := 0;
      Defaulted := 0;
      Formal_Names := Null_Unbounded_String;
      Defaulted_Names := Null_Unbounded_String;
      Malformed := False;
      if P = "" then
         return;
      end if;

      for I in P'Range loop
         if P (I) = ';' then
            if I > Segment_First then
               Add_Segment (Segment_First, I - 1);
            else
               Malformed := True;
            end if;
            Segment_First := I + 1;
         end if;
      end loop;

      if Segment_First <= P'Last then
         Add_Segment (Segment_First, P'Last);
      end if;
   end Analyze_Profile_Formals;

   procedure Count_Actuals
     (Actuals     : String;
      Positional  : out Natural;
      Named       : out Natural;
      Named_Names : out Unbounded_String;
      Malformed   : out Boolean)
   is
      A : constant String := Trim (Actuals);
      Depth : Natural := 0;
      First : Natural := A'First;

      procedure Add_Actual (F : Natural; L : Natural) is
         Segment : constant String := Trim (A (F .. L));
         Arrow   : constant Natural := Ada.Strings.Fixed.Index (Segment, "=>");
      begin
         if Segment = "" then
            Malformed := True;
         elsif Arrow /= 0 then
            Named := Named + 1;
            if Arrow = Segment'First then
               Malformed := True;
            else
               Named_Names := Append_Normalized_Name
                 (Named_Names, Segment (Segment'First .. Arrow - 1));
            end if;
         else
            Positional := Positional + 1;
         end if;
      end Add_Actual;
   begin
      Positional := 0;
      Named := 0;
      Named_Names := Null_Unbounded_String;
      Malformed := False;
      if A = "" then
         return;
      end if;

      for I in A'Range loop
         if A (I) = '(' then
            Depth := Depth + 1;
         elsif A (I) = ')' then
            if Depth = 0 then
               Malformed := True;
            else
               Depth := Depth - 1;
            end if;
         elsif A (I) = ',' and then Depth = 0 then
            if I > First then
               Add_Actual (First, I - 1);
            else
               Malformed := True;
            end if;
            First := I + 1;
         end if;
      end loop;

      if First <= A'Last then
         Add_Actual (First, A'Last);
      end if;

      if Depth /= 0 then
         Malformed := True;
      end if;
   end Count_Actuals;

   procedure Add_Callable
     (Model  : in out Profile_Shape_Model;
      Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Node   : Editor.Ada_Syntax_Tree.Node_Info;
      Region : Editor.Ada_Declarative_Regions.Region_Id)
   is
      Id     : constant Callable_Profile_Id :=
        Callable_Profile_Id (Natural (Model.Callables.Length) + 1);
      Name   : constant String :=
        Trim (Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Declaration_Name));
      Profile : constant String :=
        Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Declaration_Profile);
      Result  : constant String :=
        Trim (Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Declaration_Result));
      Param_Count : Natural := 0;
      Defaulted_Count : Natural := 0;
      Formal_Names : Unbounded_String;
      Defaulted_Names : Unbounded_String;
      Malformed   : Boolean := False;
      Info        : Callable_Profile_Info;
      Norm        : constant String := Normalize (Name);
      Status      : Callable_Profile_Status := Callable_Profile_Found;
   begin
      Analyze_Profile_Formals
        (Profile, Param_Count, Defaulted_Count, Formal_Names, Defaulted_Names,
         Malformed);
      if Profile = "" then
         Status := Callable_Profile_No_Profile;
      elsif Malformed then
         Status := Callable_Profile_Malformed;
      end if;

      Info.Id := Id;
      Info.Node := Node.Id;
      Info.Region := Region;
      Info.Name := To_Unbounded_String (Name);
      Info.Normalized_Name := To_Unbounded_String (Norm);
      Info.Parameter_Count := Param_Count;
      Info.Defaulted_Parameter_Count := Defaulted_Count;
      Info.Formal_Names := Formal_Names;
      Info.Defaulted_Formal_Names := Defaulted_Names;
      Info.Has_Result := Result /= "";
      Info.Result_Subtype := To_Unbounded_String (Result);
      Info.Status := Status;
      Info.Start_Line := Node.Source_Span.Start_Line;
      Info.End_Line := Node.Source_Span.End_Line;
      Info.Fingerprint :=
        (Callable_Profile_Status'Pos (Status) * 1000003
         + Natural (Node.Id) * 1009
         + Natural (Region) * 97
         + Param_Count * 31
         + Defaulted_Count * 23
         + Hash_Text (To_String (Formal_Names))
         + Hash_Text (To_String (Defaulted_Names))
         + (if Result /= "" then 17 else 0)
         + Hash_Text (Norm)
         + Hash_Text (Normalize (Result))) mod Natural'Last;
      Model.Callables.Append (Info);
      Mix (Model, Info.Fingerprint);
   end Add_Callable;

   procedure Add_Actual
     (Model  : in out Profile_Shape_Model;
      Node   : Editor.Ada_Syntax_Tree.Node_Info;
      Region : Editor.Ada_Declarative_Regions.Region_Id)
   is
      Id     : constant Actual_Profile_Id :=
        Actual_Profile_Id (Natural (Model.Actuals.Length) + 1);
      Label  : constant String := To_String (Node.Label);
      Name   : constant String := Clean_Call_Name (Label);
      Actual_Text_U : Unbounded_String;
      Malformed_Parens : Boolean := False;
      Positional : Natural := 0;
      Named      : Natural := 0;
      Named_Names : Unbounded_String;
      Malformed_Actuals : Boolean := False;
      Status : Actual_Profile_Status := Actual_Profile_Found;
      Info   : Actual_Profile_Info;
      Norm   : constant String := Normalize (Name);
   begin
      Actual_Text_U := To_Unbounded_String (Between_First_Parens (Label, Malformed_Parens));
      Count_Actuals
        (To_String (Actual_Text_U), Positional, Named, Named_Names,
         Malformed_Actuals);

      if Name = "" then
         Status := Actual_Profile_No_Call_Name;
      elsif To_String (Actual_Text_U) = "" and then not Malformed_Parens then
         Status := Actual_Profile_No_Arguments;
      elsif Malformed_Parens or else Malformed_Actuals then
         Status := Actual_Profile_Malformed;
      end if;

      Info.Id := Id;
      Info.Node := Node.Id;
      Info.Region := Region;
      Info.Name := To_Unbounded_String (Name);
      Info.Normalized_Name := To_Unbounded_String (Norm);
      Info.Positional_Count := Positional;
      Info.Named_Count := Named;
      Info.Named_Actual_Names := Named_Names;
      Info.Total_Actual_Count := Positional + Named;
      Info.Status := Status;
      Info.Start_Line := Node.Source_Span.Start_Line;
      Info.End_Line := Node.Source_Span.End_Line;
      Info.Fingerprint :=
        (Actual_Profile_Status'Pos (Status) * 1000003
         + Natural (Node.Id) * 1009
         + Natural (Region) * 97
         + Positional * 31
         + Named * 17
         + Hash_Text (To_String (Named_Names))
         + Hash_Text (Norm)) mod Natural'Last;
      Model.Actuals.Append (Info);
      Mix (Model, Info.Fingerprint);
   end Add_Actual;

   procedure Clear (Model : in out Profile_Shape_Model) is
   begin
      Model.Callables.Clear;
      Model.Actuals.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Tree    : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions : Editor.Ada_Declarative_Regions.Region_Model)
      return Profile_Shape_Model
   is
      Model : Profile_Shape_Model;
   begin
      Clear (Model);
      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
            Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
              Editor.Ada_Declarative_Regions.Region_For_Node (Regions, Node.Id);
         begin
            if Is_Callable_Declaration (Node.Kind) then
               Add_Callable (Model, Tree, Node, Region);
            elsif Is_Call_Node (Node.Kind) then
               Add_Actual (Model, Node, Region);
            end if;
         end;
      end loop;
      Mix (Model, Editor.Ada_Syntax_Tree.Fingerprint (Tree));
      Mix (Model, Editor.Ada_Declarative_Regions.Fingerprint (Regions));
      return Model;
   end Build;

   function Has_Callable_Profiles (Model : Profile_Shape_Model) return Boolean is
   begin
      return not Model.Callables.Is_Empty;
   end Has_Callable_Profiles;

   function Callable_Profile_Count (Model : Profile_Shape_Model) return Natural is
   begin
      return Natural (Model.Callables.Length);
   end Callable_Profile_Count;

   function Callable_Profile_At
     (Model : Profile_Shape_Model;
      Index : Positive) return Callable_Profile_Info is
   begin
      if Index > Natural (Model.Callables.Length) then
         return Empty_Callable;
      end if;
      return Model.Callables (Index);
   end Callable_Profile_At;

   function Callable_Profile
     (Model : Profile_Shape_Model;
      Id    : Callable_Profile_Id) return Callable_Profile_Info is
   begin
      if Id = No_Callable_Profile or else Natural (Id) > Natural (Model.Callables.Length) then
         return Empty_Callable;
      end if;
      return Model.Callables (Positive (Id));
   end Callable_Profile;

   function Has_Actual_Profiles (Model : Profile_Shape_Model) return Boolean is
   begin
      return not Model.Actuals.Is_Empty;
   end Has_Actual_Profiles;

   function Actual_Profile_Count (Model : Profile_Shape_Model) return Natural is
   begin
      return Natural (Model.Actuals.Length);
   end Actual_Profile_Count;

   function Actual_Profile_At
     (Model : Profile_Shape_Model;
      Index : Positive) return Actual_Profile_Info is
   begin
      if Index > Natural (Model.Actuals.Length) then
         return Empty_Actual;
      end if;
      return Model.Actuals (Index);
   end Actual_Profile_At;

   function Actual_Profile
     (Model : Profile_Shape_Model;
      Id    : Actual_Profile_Id) return Actual_Profile_Info is
   begin
      if Id = No_Actual_Profile or else Natural (Id) > Natural (Model.Actuals.Length) then
         return Empty_Actual;
      end if;
      return Model.Actuals (Positive (Id));
   end Actual_Profile;

   function Callable_Profile_For_Node
     (Model : Profile_Shape_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Callable_Profile_Info is
   begin
      for Info of Model.Callables loop
         if Info.Node = Node then
            return Info;
         end if;
      end loop;
      return Empty_Callable;
   end Callable_Profile_For_Node;

   function Actual_Profile_For_Node
     (Model : Profile_Shape_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Actual_Profile_Info is
   begin
      for Info of Model.Actuals loop
         if Info.Node = Node then
            return Info;
         end if;
      end loop;
      return Empty_Actual;
   end Actual_Profile_For_Node;

   function Fingerprint (Model : Profile_Shape_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Call_Profile_Shapes;
