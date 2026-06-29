with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;

package body Editor.Ada_Expected_Type_Contexts is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Call_Resolution.Call_Resolution_Id;
   use type Editor.Ada_Call_Resolution.Call_Resolution_Status;
   use type Editor.Ada_Call_Profile_Shapes.Actual_Profile_Id;
   use type Editor.Ada_Direct_Visibility.Declaration_Id;
   use type Editor.Ada_Declarative_Regions.Region_Id;
   use type Editor.Ada_Direct_Visibility.Lookup_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Syntax_Tree.Node_Kind;

   function To_String
     (Value : Ada.Strings.Unbounded.Unbounded_String) return String
      renames Ada.Strings.Unbounded.To_String;

   function To_Unbounded_String (Value : String)
      return Ada.Strings.Unbounded.Unbounded_String
      renames Ada.Strings.Unbounded.To_Unbounded_String;

   procedure Mix (Model : in out Expected_Context_Model; Value : Natural) is
   begin
      Model.Result_Fingerprint :=
        (Model.Result_Fingerprint * 65599 + Value + 229) mod Natural'Last;
   end Mix;

   function Hash_Text (Text : String) return Natural is
      Result : Natural := 0;
   begin
      for C of Text loop
         Result :=
           (Result * 131 + Character'Pos (Ada.Characters.Handling.To_Lower (C)) + 1)
           mod Natural'Last;
      end loop;
      return Result;
   end Hash_Text;

   function Normalize (Text : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both));
   end Normalize;

   function Empty_Context return Expected_Context_Info is
   begin
      return (Id => No_Expected_Context,
              Node => Editor.Ada_Syntax_Tree.No_Node,
              Context_Node => Editor.Ada_Syntax_Tree.No_Node,
              Region => Editor.Ada_Declarative_Regions.No_Region,
              Resolution => Editor.Ada_Call_Resolution.No_Call_Resolution,
              Kind => Expected_Context_None,
              Expected_Subtype => Ada.Strings.Unbounded.Null_Unbounded_String,
              Normalized_Subtype => Ada.Strings.Unbounded.Null_Unbounded_String,
              Status => Expected_Context_Not_Checked,
              Start_Line => 1,
              End_Line => 1,
              Fingerprint => 0);
   end Empty_Context;

   function Region_For_Node
     (Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Node    : Editor.Ada_Syntax_Tree.Node_Id)
      return Editor.Ada_Declarative_Regions.Region_Id is
   begin
      return Editor.Ada_Declarative_Regions.Region_For_Node (Regions, Node);
   exception
      when others =>
         return Editor.Ada_Declarative_Regions.No_Region;
   end Region_For_Node;

   function Child_Label
     (Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Parent : Editor.Ada_Syntax_Tree.Node_Id;
      Kind   : Editor.Ada_Syntax_Tree.Node_Kind) return String
   is
      Child : Editor.Ada_Syntax_Tree.Node_Id;
      Info  : Editor.Ada_Syntax_Tree.Node_Info;
   begin
      if Parent = Editor.Ada_Syntax_Tree.No_Node then
         return "";
      end if;
      for Index in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Parent) loop
         Child := Editor.Ada_Syntax_Tree.Child_At (Tree, Parent, Index);
         Info := Editor.Ada_Syntax_Tree.Node (Tree, Child);
         if Info.Kind = Kind then
            return Ada.Strings.Fixed.Trim (To_String (Info.Label), Ada.Strings.Both);
         end if;
      end loop;
      return "";
   end Child_Label;

   function Enclosing_Node_Of_Kind
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Id;
      Kind : Editor.Ada_Syntax_Tree.Node_Kind)
      return Editor.Ada_Syntax_Tree.Node_Id
   is
      Current : Editor.Ada_Syntax_Tree.Node_Id := Node;
      Info    : Editor.Ada_Syntax_Tree.Node_Info;
   begin
      while Current /= Editor.Ada_Syntax_Tree.No_Node loop
         Info := Editor.Ada_Syntax_Tree.Node (Tree, Current);
         if Info.Kind = Kind then
            return Current;
         end if;
         Current := Info.Parent;
      end loop;
      return Editor.Ada_Syntax_Tree.No_Node;
   end Enclosing_Node_Of_Kind;

   function Enclosing_Declaration_Default
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Id)
      return Editor.Ada_Syntax_Tree.Node_Id is
   begin
      return Enclosing_Node_Of_Kind
        (Tree, Node, Editor.Ada_Syntax_Tree.Node_Declaration_Default);
   end Enclosing_Declaration_Default;

   function Enclosing_Return
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Id)
      return Editor.Ada_Syntax_Tree.Node_Id is
   begin
      return Enclosing_Node_Of_Kind
        (Tree, Node, Editor.Ada_Syntax_Tree.Node_Return_Statement);
   end Enclosing_Return;

   function Enclosing_Assignment
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Id)
      return Editor.Ada_Syntax_Tree.Node_Id is
   begin
      return Enclosing_Node_Of_Kind
        (Tree, Node, Editor.Ada_Syntax_Tree.Node_Assignment_Statement);
   end Enclosing_Assignment;

   function Is_Expression_Node
     (Kind : Editor.Ada_Syntax_Tree.Node_Kind) return Boolean is
   begin
      return Kind in Editor.Ada_Syntax_Tree.Node_Expression ..
        Editor.Ada_Syntax_Tree.Node_Allocator
        or else Kind = Editor.Ada_Syntax_Tree.Node_Statement_Action;
   end Is_Expression_Node;

   function Last_Expression_Child
     (Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Parent : Editor.Ada_Syntax_Tree.Node_Id)
      return Editor.Ada_Syntax_Tree.Node_Id
   is
      Result : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
   begin
      if Parent = Editor.Ada_Syntax_Tree.No_Node then
         return Result;
      end if;

      for Index in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Parent) loop
         declare
            Child : constant Editor.Ada_Syntax_Tree.Node_Id :=
              Editor.Ada_Syntax_Tree.Child_At (Tree, Parent, Index);
            Info  : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node (Tree, Child);
         begin
            if Is_Expression_Node (Info.Kind) then
               Result := Child;
            else
               declare
                  Nested : constant Editor.Ada_Syntax_Tree.Node_Id :=
                    Last_Expression_Child (Tree, Child);
               begin
                  if Nested /= Editor.Ada_Syntax_Tree.No_Node then
                     Result := Nested;
                  end if;
               end;
            end if;
         end;
      end loop;

      return Result;
   end Last_Expression_Child;

   function Enclosing_Outer_Call
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Id)
      return Editor.Ada_Syntax_Tree.Node_Id
   is
      Current : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Info    : Editor.Ada_Syntax_Tree.Node_Info;
   begin
      if Node = Editor.Ada_Syntax_Tree.No_Node then
         return Editor.Ada_Syntax_Tree.No_Node;
      end if;

      Current := Editor.Ada_Syntax_Tree.Node (Tree, Node).Parent;
      while Current /= Editor.Ada_Syntax_Tree.No_Node loop
         Info := Editor.Ada_Syntax_Tree.Node (Tree, Current);
         if Info.Kind = Editor.Ada_Syntax_Tree.Node_Function_Call
           or else Info.Kind = Editor.Ada_Syntax_Tree.Node_Call_Statement
         then
            return Current;
         end if;
         Current := Info.Parent;
      end loop;
      return Editor.Ada_Syntax_Tree.No_Node;
   end Enclosing_Outer_Call;

   function Declaration_For_Detail
     (Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Detail : Editor.Ada_Syntax_Tree.Node_Id)
      return Editor.Ada_Syntax_Tree.Node_Id
   is
      Parent : constant Editor.Ada_Syntax_Tree.Node_Id :=
        Editor.Ada_Syntax_Tree.Node (Tree, Detail).Parent;
   begin
      return Parent;
   end Declaration_For_Detail;

   function Declaration_Context_Kind
     (Tree        : Editor.Ada_Syntax_Tree.Tree_Type;
      Declaration : Editor.Ada_Syntax_Tree.Node_Id) return Expected_Context_Kind
   is
      Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
        Editor.Ada_Syntax_Tree.Node (Tree, Declaration);
   begin
      if Info.Kind = Editor.Ada_Syntax_Tree.Node_Object_Declaration then
         return Expected_Context_Object_Default;
      elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Constant_Declaration then
         return Expected_Context_Constant_Default;
      elsif Declaration /= Editor.Ada_Syntax_Tree.No_Node then
         return Expected_Context_Declaration_Default;
      else
         return Expected_Context_None;
      end if;
   end Declaration_Context_Kind;

   function Result_Subtype_For_Region
     (Profiles : Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model;
      Region   : Editor.Ada_Declarative_Regions.Region_Id) return String
   is
      Info : Editor.Ada_Call_Profile_Shapes.Callable_Profile_Info;
   begin
      if Region = Editor.Ada_Declarative_Regions.No_Region then
         return "";
      end if;
      for Index in 1 .. Editor.Ada_Call_Profile_Shapes.Callable_Profile_Count (Profiles) loop
         Info := Editor.Ada_Call_Profile_Shapes.Callable_Profile_At (Profiles, Index);
         if Info.Region = Region and then Info.Has_Result then
            return Ada.Strings.Fixed.Trim (To_String (Info.Result_Subtype), Ada.Strings.Both);
         end if;
      end loop;
      return "";
   end Result_Subtype_For_Region;

   function Callable_Result_Subtype (Callable_Label : String) return String is
      N : constant String := Normalize (Callable_Label);
      R : constant Natural := Ada.Strings.Fixed.Index (N, " return ");
      Original : constant String := Callable_Label;
   begin
      if R = 0 then
         return "";
      end if;

      declare
         Tail : constant String :=
           Ada.Strings.Fixed.Trim
             (Original (Original'First + R + 7 - 1 .. Original'Last),
              Ada.Strings.Both);
         Normalized_Tail : constant String := Normalize (Tail);
         Semi : constant Natural := Ada.Strings.Fixed.Index (Tail, ";");
         Is_Pos : constant Natural :=
           Ada.Strings.Fixed.Index (Normalized_Tail, " is");
         Body_Pos : constant Natural :=
           Ada.Strings.Fixed.Index (Normalized_Tail, " is ");
         Stop_Pos : constant Natural :=
           (if Body_Pos /= 0 then Body_Pos
            elsif Is_Pos /= 0 then Is_Pos
            else Semi);
         End_Pos : Natural := 0;
      begin
         if Stop_Pos /= 0 and then Semi /= 0 then
            End_Pos := Natural'Min (Stop_Pos, Semi) - 1;
         elsif Stop_Pos /= 0 then
            End_Pos := Stop_Pos - 1;
         elsif Semi /= 0 then
            End_Pos := Semi - 1;
         else
            End_Pos := Tail'Length;
         end if;

         if End_Pos <= 0 then
            return "";
         end if;

         return Ada.Strings.Fixed.Trim
           (Tail (Tail'First .. Tail'First + End_Pos - 1),
            Ada.Strings.Both);
      end;
   end Callable_Result_Subtype;

   function Result_Subtype_For_Return_Node
     (Tree        : Editor.Ada_Syntax_Tree.Tree_Type;
      Return_Node : Editor.Ada_Syntax_Tree.Node_Id) return String
   is
      Body_Node : constant Editor.Ada_Syntax_Tree.Node_Id :=
        Enclosing_Node_Of_Kind
          (Tree, Return_Node, Editor.Ada_Syntax_Tree.Node_Subprogram_Body);
   begin
      if Body_Node = Editor.Ada_Syntax_Tree.No_Node then
         return "";
      end if;

      return Callable_Result_Subtype
        (To_String (Editor.Ada_Syntax_Tree.Node (Tree, Body_Node).Label));
   end Result_Subtype_For_Return_Node;

   function Simple_Assignment_Target
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Assignment : Editor.Ada_Syntax_Tree.Node_Id) return String
   is
      Info   : constant Editor.Ada_Syntax_Tree.Node_Info :=
        Editor.Ada_Syntax_Tree.Node (Tree, Assignment);
      Label  : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Info.Label), Ada.Strings.Both);
      Assign : constant Natural := Ada.Strings.Fixed.Index (Label, ":=");
   begin
      if Label = "" or else Assign <= Label'First then
         return "";
      end if;

      declare
         Target : constant String :=
           Ada.Strings.Fixed.Trim (Label (Label'First .. Assign - 1), Ada.Strings.Both);
      begin
         if Target = ""
           or else Ada.Strings.Fixed.Index (Target, ".") /= 0
           or else Ada.Strings.Fixed.Index (Target, "(") /= 0
           or else Ada.Strings.Fixed.Index (Target, ")") /= 0
         then
            return "";
         end if;

         return Target;
      end;
   end Simple_Assignment_Target;

   function Declaration_Subtype
     (Tree        : Editor.Ada_Syntax_Tree.Tree_Type;
      Visibility  : Editor.Ada_Direct_Visibility.Visibility_Model;
      Declaration : Editor.Ada_Direct_Visibility.Declaration_Id) return String
   is
      Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
        Editor.Ada_Direct_Visibility.Declaration (Visibility, Declaration);
   begin
      if Decl.Node = Editor.Ada_Syntax_Tree.No_Node then
         return "";
      end if;
      return Child_Label
        (Tree, Decl.Node, Editor.Ada_Syntax_Tree.Node_Declaration_Subtype);
   end Declaration_Subtype;

   function Assignment_Target_Subtype
     (Tree        : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions     : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility  : Editor.Ada_Direct_Visibility.Visibility_Model;
      Region      : Editor.Ada_Declarative_Regions.Region_Id;
      Assignment  : Editor.Ada_Syntax_Tree.Node_Id) return String
   is
      Target : constant String := Simple_Assignment_Target (Tree, Assignment);
      Lookup : Editor.Ada_Direct_Visibility.Lookup_Result;
   begin
      if Target = "" or else Region = Editor.Ada_Declarative_Regions.No_Region then
         return "";
      end if;

      Lookup := Editor.Ada_Direct_Visibility.Lookup_Visible
        (Visibility, Regions, Region, Target);
      if Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found then
         return Declaration_Subtype (Tree, Visibility, Lookup.Declaration);
      else
         return "";
      end if;
   end Assignment_Target_Subtype;

   function Clean_Formal_Subtype (Text : String) return String is
      function Drop_Prefix (Text : String; Prefix : String) return String is
         T : constant String := Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
         N : constant String := Normalize (T);
      begin
         if N'Length > Prefix'Length
           and then N (N'First .. N'First + Prefix'Length - 1) = Prefix
         then
            return Ada.Strings.Fixed.Trim
              (T (T'First + Prefix'Length .. T'Last), Ada.Strings.Both);
         end if;
         return T;
      end Drop_Prefix;

      T : constant String := Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
      Stop : Natural := T'Last;
   begin
      if T = "" then
         return "";
      end if;

      for I in T'Range loop
         if I < T'Last and then T (I) = ':' and then T (I + 1) = '=' then
            Stop := I - 1;
            exit;
         elsif T (I) = ')' then
            Stop := I - 1;
            exit;
         end if;
      end loop;

      declare
         Subtype_Text : constant String :=
           (if Stop >= T'First then
               Ada.Strings.Fixed.Trim (T (T'First .. Stop), Ada.Strings.Both)
            else "");
      begin
         return Drop_Prefix
           (Drop_Prefix
              (Drop_Prefix
                 (Drop_Prefix (Subtype_Text, "aliased "), "in out "),
               "in "),
            "out ");
      end;
   end Clean_Formal_Subtype;

   function Count_Names_In_Formal (Names : String) return Natural is
      T : constant String := Ada.Strings.Fixed.Trim (Names, Ada.Strings.Both);
      Count : Natural := (if T = "" then 0 else 1);
   begin
      for C of T loop
         if C = ',' then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Names_In_Formal;

   function Name_At_In_Formal (Names : String; Index : Positive) return String is
      T : constant String := Ada.Strings.Fixed.Trim (Names, Ada.Strings.Both);
      Start : Natural := T'First;
      Current : Positive := 1;
   begin
      if T = "" then
         return "";
      end if;
      for I in T'Range loop
         if T (I) = ',' then
            if Current = Index then
               return Ada.Strings.Fixed.Trim (T (Start .. I - 1), Ada.Strings.Both);
            end if;
            Current := Current + 1;
            Start := I + 1;
         end if;
      end loop;
      if Current = Index then
         return Ada.Strings.Fixed.Trim (T (Start .. T'Last), Ada.Strings.Both);
      end if;
      return "";
   end Name_At_In_Formal;

   function Formal_Subtype_By_Position
     (Profile : String;
      Position : Positive) return String
   is
      P : constant String := Ada.Strings.Fixed.Trim (Profile, Ada.Strings.Both);
      Start : Natural := (if P = "" then 0 else P'First);
      Pos : Natural := 0;

      procedure Match_Part
        (Part_Text : String;
         Found     : in out Ada.Strings.Unbounded.Unbounded_String)
      is
         Part : constant String := Ada.Strings.Fixed.Trim (Part_Text, Ada.Strings.Both);
         Colon : constant Natural := Ada.Strings.Fixed.Index (Part, ":");
      begin
         if Part /= "" and then Colon /= 0 then
            declare
               Names : constant String := Part (Part'First .. Colon - 1);
               Cnt : constant Natural := Count_Names_In_Formal (Names);
            begin
               if Position > Pos and then Position <= Pos + Cnt then
                  Found := To_Unbounded_String
                    (Clean_Formal_Subtype (Part (Colon + 1 .. Part'Last)));
               end if;
               Pos := Pos + Cnt;
            end;
         end if;
      end Match_Part;

      Found : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   begin
      if P = "" then
         return "";
      end if;

      for I in P'Range loop
         if P (I) = ';' then
            Match_Part (P (Start .. I - 1), Found);
            Start := I + 1;
         end if;
      end loop;
      if Start <= P'Last and then To_String (Found) = "" then
         Match_Part (P (Start .. P'Last), Found);
      end if;
      return To_String (Found);
   end Formal_Subtype_By_Position;

   function Formal_Subtype_By_Name (Profile : String; Name : String) return String is
      P : constant String := Ada.Strings.Fixed.Trim (Profile, Ada.Strings.Both);
      Wanted : constant String := Normalize (Name);
      Start : Natural := (if P = "" then 0 else P'First);

      procedure Match_Part
        (Part_Text : String;
         Found     : in out Ada.Strings.Unbounded.Unbounded_String)
      is
         Part : constant String := Ada.Strings.Fixed.Trim (Part_Text, Ada.Strings.Both);
         Colon : constant Natural := Ada.Strings.Fixed.Index (Part, ":");
      begin
         if Part /= "" and then Colon /= 0 then
            declare
               Names : constant String := Part (Part'First .. Colon - 1);
               Cnt : constant Natural := Count_Names_In_Formal (Names);
            begin
               for J in 1 .. Cnt loop
                  if Normalize (Name_At_In_Formal (Names, J)) = Wanted then
                     Found := To_Unbounded_String
                       (Clean_Formal_Subtype (Part (Colon + 1 .. Part'Last)));
                  end if;
               end loop;
            end;
         end if;
      end Match_Part;

      Found : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   begin
      if P = "" or else Wanted = "" then
         return "";
      end if;

      for I in P'Range loop
         if P (I) = ';' then
            Match_Part (P (Start .. I - 1), Found);
            Start := I + 1;
         end if;
      end loop;
      if Start <= P'Last and then To_String (Found) = "" then
         Match_Part (P (Start .. P'Last), Found);
      end if;
      return To_String (Found);
   end Formal_Subtype_By_Name;

   function Named_Actual_Formal_Name (Text : String) return String is
      Arrow : constant Natural := Ada.Strings.Fixed.Index (Text, "=>");
   begin
      if Arrow = 0 or else Arrow = Text'First then
         return "";
      end if;
      return Ada.Strings.Fixed.Trim (Text (Text'First .. Arrow - 1), Ada.Strings.Both);
   end Named_Actual_Formal_Name;

   function Actual_Expression_Text (Text : String) return String is
      Arrow : constant Natural := Ada.Strings.Fixed.Index (Text, "=>");
   begin
      if Arrow /= 0 and then Arrow + 2 <= Text'Last then
         return Ada.Strings.Fixed.Trim (Text (Arrow + 2 .. Text'Last), Ada.Strings.Both);
      end if;
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Actual_Expression_Text;

   procedure Locate_Nested_Actual
     (Outer_Label : String;
      Inner_Label : String;
      Position    : out Natural;
      Formal_Name : out Ada.Strings.Unbounded.Unbounded_String)
   is
      Open  : Natural := 0;
      Depth : Natural := 0;
      First : Natural := 0;
      Wanted : constant String := Normalize (Inner_Label);
      Current_Position : Natural := 0;

      procedure Add_Actual (F : Natural; L : Natural) is
         Segment : constant String :=
           Ada.Strings.Fixed.Trim (Outer_Label (F .. L), Ada.Strings.Both);
         Expr : constant String := Normalize (Actual_Expression_Text (Segment));
      begin
         if Segment = "" then
            return;
         end if;
         Current_Position := Current_Position + 1;
         if Position = 0
           and then Wanted /= ""
           and then Ada.Strings.Fixed.Index (Expr, Wanted) /= 0
         then
            Position := Current_Position;
            Formal_Name := To_Unbounded_String (Named_Actual_Formal_Name (Segment));
         end if;
      end Add_Actual;
   begin
      Position := 0;
      Formal_Name := Ada.Strings.Unbounded.Null_Unbounded_String;
      for I in Outer_Label'Range loop
         if Outer_Label (I) = '(' then
            if Open = 0 then
               Open := I;
               First := I + 1;
            else
               Depth := Depth + 1;
            end if;
         elsif Outer_Label (I) = ')' then
            if Open /= 0 and then Depth = 0 then
               if I > First then
                  Add_Actual (First, I - 1);
               end if;
               return;
            elsif Depth > 0 then
               Depth := Depth - 1;
            end if;
         elsif Outer_Label (I) = ',' and then Open /= 0 and then Depth = 0 then
            if I > First then
               Add_Actual (First, I - 1);
            end if;
            First := I + 1;
         end if;
      end loop;
   end Locate_Nested_Actual;

   function Parameter_Actual_Subtype
     (Tree        : Editor.Ada_Syntax_Tree.Tree_Type;
      Visibility  : Editor.Ada_Direct_Visibility.Visibility_Model;
      Profiles    : Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model;
      Resolutions : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Call_Node   : Editor.Ada_Syntax_Tree.Node_Id) return String
   is
      Outer_Call : constant Editor.Ada_Syntax_Tree.Node_Id :=
        Enclosing_Outer_Call (Tree, Call_Node);
      Outer_Resolution : Editor.Ada_Call_Resolution.Call_Resolution_Info;
      Outer_Actual : Editor.Ada_Call_Profile_Shapes.Actual_Profile_Info;
      Decl : Editor.Ada_Direct_Visibility.Declaration_Info;
      Nested_Position : Natural := 0;
      Nested_Formal_Name : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   begin
      if Outer_Call = Editor.Ada_Syntax_Tree.No_Node then
         return "";
      end if;

      Outer_Resolution :=
        Editor.Ada_Call_Resolution.Resolution_For_Node (Resolutions, Outer_Call);
      if Outer_Resolution.Status /=
        Editor.Ada_Call_Resolution.Call_Resolution_Unique_Profile_Match
        or else Outer_Resolution.Declaration =
          Editor.Ada_Direct_Visibility.No_Declaration
      then
         return "";
      end if;

      Outer_Actual :=
        Editor.Ada_Call_Profile_Shapes.Actual_Profile_For_Node (Profiles, Outer_Call);
      if Outer_Actual.Id = Editor.Ada_Call_Profile_Shapes.No_Actual_Profile then
         return "";
      end if;

      Decl := Editor.Ada_Direct_Visibility.Declaration
        (Visibility, Outer_Resolution.Declaration);
      if Decl.Node = Editor.Ada_Syntax_Tree.No_Node then
         return "";
      end if;

      Locate_Nested_Actual
        (To_String (Editor.Ada_Syntax_Tree.Node (Tree, Outer_Call).Label),
         To_String (Editor.Ada_Syntax_Tree.Node (Tree, Call_Node).Label),
         Nested_Position,
         Nested_Formal_Name);

      if To_String (Nested_Formal_Name) /= "" then
         return Formal_Subtype_By_Name
           (Child_Label (Tree, Decl.Node, Editor.Ada_Syntax_Tree.Node_Declaration_Profile),
            To_String (Nested_Formal_Name));
      elsif Nested_Position > 0 then
         return Formal_Subtype_By_Position
           (Child_Label (Tree, Decl.Node, Editor.Ada_Syntax_Tree.Node_Declaration_Profile),
            Positive (Nested_Position));
      else
         return "";
      end if;
   end Parameter_Actual_Subtype;

   procedure Add_Context
     (Model       : in out Expected_Context_Model;
      Tree        : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions     : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility  : Editor.Ada_Direct_Visibility.Visibility_Model;
      Profiles    : Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model;
      Resolutions : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Resolution  : Editor.Ada_Call_Resolution.Call_Resolution_Info)
   is
      Node_Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
        Editor.Ada_Syntax_Tree.Node (Tree, Resolution.Call_Node);
      Id : constant Expected_Context_Id :=
        Expected_Context_Id (Natural (Model.Contexts.Length) + 1);
      Info : Expected_Context_Info := Empty_Context;
      Default_Node : constant Editor.Ada_Syntax_Tree.Node_Id :=
        Enclosing_Declaration_Default (Tree, Resolution.Call_Node);
      Return_Node : constant Editor.Ada_Syntax_Tree.Node_Id :=
        Enclosing_Return (Tree, Resolution.Call_Node);
      Assignment_Node : constant Editor.Ada_Syntax_Tree.Node_Id :=
        Enclosing_Assignment (Tree, Resolution.Call_Node);
      Decl_Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Expected : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Region : Editor.Ada_Declarative_Regions.Region_Id :=
        Region_For_Node (Regions, Resolution.Call_Node);
   begin
      Info.Id := Id;
      Info.Node := Resolution.Call_Node;
      Info.Resolution := Resolution.Id;
      Info.Region := Region;
      Info.Start_Line := Node_Info.Source_Span.Start_Line;
      Info.End_Line := Node_Info.Source_Span.End_Line;

      if Resolution.Call_Node = Editor.Ada_Syntax_Tree.No_Node then
         Info.Status := Expected_Context_No_Call_Node;
      elsif Enclosing_Outer_Call (Tree, Resolution.Call_Node) /=
        Editor.Ada_Syntax_Tree.No_Node
      then
         Info.Context_Node := Enclosing_Outer_Call (Tree, Resolution.Call_Node);
         Info.Kind := Expected_Context_Parameter_Actual;
         Expected := To_Unbounded_String
           (Parameter_Actual_Subtype
              (Tree, Visibility, Profiles, Resolutions, Resolution.Call_Node));
         if To_String (Expected) = "" then
            Info.Status := Expected_Context_Context_Without_Subtype;
         else
            Info.Status := Expected_Context_Found;
         end if;
      elsif Default_Node /= Editor.Ada_Syntax_Tree.No_Node then
         Decl_Node := Declaration_For_Detail (Tree, Default_Node);
         Info.Context_Node := Decl_Node;
         Info.Kind := Declaration_Context_Kind (Tree, Decl_Node);
         Expected := To_Unbounded_String
           (Child_Label (Tree, Decl_Node, Editor.Ada_Syntax_Tree.Node_Declaration_Subtype));
         if To_String (Expected) = "" then
            Info.Status := Expected_Context_Context_Without_Subtype;
         else
            Info.Status := Expected_Context_Found;
         end if;
      elsif Return_Node /= Editor.Ada_Syntax_Tree.No_Node then
         Info.Context_Node := Return_Node;
         Info.Kind := Expected_Context_Return_Statement;
         Expected := To_Unbounded_String (Result_Subtype_For_Region (Profiles, Region));
         if To_String (Expected) = "" then
            Expected := To_Unbounded_String
              (Result_Subtype_For_Return_Node (Tree, Return_Node));
         end if;
         if To_String (Expected) = "" then
            Info.Status := Expected_Context_Context_Without_Subtype;
         else
            Info.Status := Expected_Context_Found;
         end if;
      elsif Assignment_Node /= Editor.Ada_Syntax_Tree.No_Node then
         Info.Context_Node := Assignment_Node;
         Info.Kind := Expected_Context_Assignment_Target;
         Expected := To_Unbounded_String
           (Assignment_Target_Subtype
              (Tree, Regions, Visibility, Region, Assignment_Node));
         if To_String (Expected) = "" then
            Info.Status := Expected_Context_Context_Without_Subtype;
         else
            Info.Status := Expected_Context_Found;
         end if;
      else
         Info.Status := Expected_Context_No_Context;
      end if;

      Info.Expected_Subtype := Expected;
      Info.Normalized_Subtype := To_Unbounded_String (Normalize (To_String (Expected)));
      Info.Fingerprint :=
        (Expected_Context_Status'Pos (Info.Status) * 1000003
         + Expected_Context_Kind'Pos (Info.Kind) * 65537
         + Natural (Info.Node) * 1009
         + Natural (Info.Context_Node) * 503
         + Natural (Info.Region) * 211
         + Natural (Info.Resolution) * 97
         + Hash_Text (To_String (Info.Expected_Subtype))) mod Natural'Last;
      Model.Contexts.Append (Info);
      Mix (Model, Info.Fingerprint);
   end Add_Context;

   function Has_Context_For
     (Model        : Expected_Context_Model;
      Node         : Editor.Ada_Syntax_Tree.Node_Id;
      Context_Node : Editor.Ada_Syntax_Tree.Node_Id)
      return Boolean is
   begin
      for Info of Model.Contexts loop
         if Info.Node = Node and then Info.Context_Node = Context_Node then
            return True;
         end if;
      end loop;
      return False;
   end Has_Context_For;

   procedure Add_Syntax_Context
     (Model      : in out Expected_Context_Model;
      Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Profiles   : Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
   is
      Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Region_For_Node (Regions, Node.Id);
      Expr_Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind : Expected_Context_Kind := Expected_Context_None;
      Expected : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Info : Expected_Context_Info := Empty_Context;
   begin
      case Node.Kind is
         when Editor.Ada_Syntax_Tree.Node_Declaration_Default =>
            Expr_Node := Last_Expression_Child (Tree, Node.Id);
            declare
               Decl_Node : constant Editor.Ada_Syntax_Tree.Node_Id :=
                 Declaration_For_Detail (Tree, Node.Id);
            begin
               Kind := Declaration_Context_Kind (Tree, Decl_Node);
               Expected := To_Unbounded_String
                 (Child_Label
                    (Tree, Decl_Node,
                     Editor.Ada_Syntax_Tree.Node_Declaration_Subtype));
               Info.Context_Node := Decl_Node;
            end;
         when Editor.Ada_Syntax_Tree.Node_Return_Statement =>
            Expr_Node := Last_Expression_Child (Tree, Node.Id);
            Kind := Expected_Context_Return_Statement;
            Expected := To_Unbounded_String (Result_Subtype_For_Region (Profiles, Region));
            if To_String (Expected) = "" then
               Expected := To_Unbounded_String
                 (Result_Subtype_For_Return_Node (Tree, Node.Id));
            end if;
            Info.Context_Node := Node.Id;
         when Editor.Ada_Syntax_Tree.Node_Assignment_Statement =>
            Expr_Node := Last_Expression_Child (Tree, Node.Id);
            Kind := Expected_Context_Assignment_Target;
            Expected := To_Unbounded_String
              (Assignment_Target_Subtype
                 (Tree, Regions, Visibility, Region, Node.Id));
            Info.Context_Node := Node.Id;
         when others =>
            return;
      end case;

      if Expr_Node = Editor.Ada_Syntax_Tree.No_Node
        or else To_String (Expected) = ""
        or else Has_Context_For (Model, Expr_Node, Info.Context_Node)
      then
         return;
      end if;

      declare
         Expr_Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
           Editor.Ada_Syntax_Tree.Node (Tree, Expr_Node);
      begin
         Info.Id := Expected_Context_Id (Natural (Model.Contexts.Length) + 1);
         Info.Node := Expr_Node;
         Info.Region := Region;
         Info.Kind := Kind;
         Info.Expected_Subtype := Expected;
         Info.Normalized_Subtype :=
           To_Unbounded_String (Normalize (To_String (Expected)));
         Info.Status := Expected_Context_Found;
         Info.Start_Line := Expr_Info.Source_Span.Start_Line;
         Info.End_Line := Expr_Info.Source_Span.End_Line;
         Info.Fingerprint :=
           (Expected_Context_Status'Pos (Info.Status) * 1000003
            + Expected_Context_Kind'Pos (Info.Kind) * 65537
            + Natural (Info.Node) * 1009
            + Natural (Info.Context_Node) * 503
            + Natural (Info.Region) * 211
            + Hash_Text (To_String (Info.Expected_Subtype))) mod Natural'Last;
         Model.Contexts.Append (Info);
         Mix (Model, Info.Fingerprint);
      end;
   end Add_Syntax_Context;

   procedure Clear (Model : in out Expected_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Tree        : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions     : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility  : Editor.Ada_Direct_Visibility.Visibility_Model;
      Profiles    : Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model;
      Resolutions : Editor.Ada_Call_Resolution.Call_Resolution_Model)
      return Expected_Context_Model
   is
      Model : Expected_Context_Model;
   begin
      Clear (Model);
      for Index in 1 .. Editor.Ada_Call_Resolution.Call_Resolution_Count (Resolutions) loop
         Add_Context
           (Model, Tree, Regions, Visibility, Profiles, Resolutions,
            Editor.Ada_Call_Resolution.Call_Resolution_At (Resolutions, Index));
      end loop;
      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         Add_Syntax_Context
           (Model, Tree, Regions, Visibility, Profiles,
            Editor.Ada_Syntax_Tree.Node_At (Tree, Index));
      end loop;
      Mix (Model, Editor.Ada_Syntax_Tree.Fingerprint (Tree));
      Mix (Model, Editor.Ada_Declarative_Regions.Fingerprint (Regions));
      Mix (Model, Editor.Ada_Direct_Visibility.Fingerprint (Visibility));
      Mix (Model, Editor.Ada_Call_Profile_Shapes.Fingerprint (Profiles));
      Mix (Model, Editor.Ada_Call_Resolution.Fingerprint (Resolutions));
      return Model;
   end Build;

   function Build
     (Tree        : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions     : Editor.Ada_Declarative_Regions.Region_Model;
      Profiles    : Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model;
      Resolutions : Editor.Ada_Call_Resolution.Call_Resolution_Model)
      return Expected_Context_Model
   is
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
   begin
      Editor.Ada_Direct_Visibility.Clear (Visibility);
      return Build (Tree, Regions, Visibility, Profiles, Resolutions);
   end Build;



   function Build
     (Tree        : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions     : Editor.Ada_Declarative_Regions.Region_Model;
      Resolutions : Editor.Ada_Call_Resolution.Call_Resolution_Model)
      return Expected_Context_Model
   is
      Profiles : Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model;
   begin
      return Build (Tree, Regions, Profiles, Resolutions);
   end Build;

   function Has_Expected_Contexts (Model : Expected_Context_Model) return Boolean is
   begin
      return not Model.Contexts.Is_Empty;
   end Has_Expected_Contexts;

   function Expected_Context_Count (Model : Expected_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Expected_Context_Count;

   function Expected_Context_At
     (Model : Expected_Context_Model;
      Index : Positive) return Expected_Context_Info is
   begin
      if Index > Natural (Model.Contexts.Length) then
         return Empty_Context;
      end if;
      return Model.Contexts (Index);
   end Expected_Context_At;

   function Expected_Context
     (Model : Expected_Context_Model;
      Id    : Expected_Context_Id) return Expected_Context_Info is
   begin
      if Id = No_Expected_Context
        or else Natural (Id) > Natural (Model.Contexts.Length)
      then
         return Empty_Context;
      end if;
      return Model.Contexts (Positive (Id));
   end Expected_Context;

   function Expected_Context_For_Node
     (Model : Expected_Context_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Expected_Context_Info is
   begin
      for Info of Model.Contexts loop
         if Info.Node = Node then
            return Info;
         end if;
      end loop;
      return Empty_Context;
   end Expected_Context_For_Node;

   function Count_Status
     (Model  : Expected_Context_Model;
      Status : Expected_Context_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Model.Contexts loop
         if Info.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind
     (Model : Expected_Context_Model;
      Kind  : Expected_Context_Kind) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Model.Contexts loop
         if Info.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Fingerprint (Model : Expected_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Expected_Type_Contexts;
