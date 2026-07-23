with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Expression_Types.Inference_Support;
with Editor.Ada_Expression_Types.Status_Helpers;

package body Editor.Ada_Expression_Types.Call_Text_Helpers is

   use type Editor.Ada_Syntax_Tree.Node_Kind;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Direct_Visibility.Lookup_Status;
   use type Editor.Ada_Static_Expressions.Static_Value_Status;

   function Trim (Text : String) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Trim;

   function Normalize (Text : String) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Normalize;

   function Contains (Text : String; Pattern : String) return Boolean
     renames Editor.Ada_Expression_Types.Status_Helpers.Contains;

   function Formal_List_Text (Label : String) return String is
      L : constant String := Label;
      Open_Paren  : Natural := 0;
      Close_Paren : Natural := 0;
   begin
      for I in L'Range loop
         if L (I) = '(' then
            Open_Paren := I;
            exit;
         end if;
      end loop;
      if Open_Paren = 0 or else Open_Paren = L'Last then
         return "";
      end if;
      for I in reverse Open_Paren + 1 .. L'Last loop
         if L (I) = ')' then
            Close_Paren := I;
            exit;
         end if;
      end loop;
      if Close_Paren = 0 or else Close_Paren <= Open_Paren + 1 then
         return "";
      end if;
      return L (Open_Paren + 1 .. Close_Paren - 1);
   end Formal_List_Text;

   function Count_Names_In_Formal (Names : String) return Natural is
      T : constant String := Trim (Names);
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
      T : constant String := Trim (Names);
      Start : Natural := T'First;
      Current : Positive := 1;
   begin
      for I in T'Range loop
         if T (I) = ',' then
            if Current = Index then
               return Trim (T (Start .. I - 1));
            end if;
            Current := Current + 1;
            Start := I + 1;
         end if;
      end loop;
      if Current = Index and then T /= "" then
         return Trim (T (Start .. T'Last));
      end if;
      return "";
   end Name_At_In_Formal;

   function Clean_Formal_Subtype (Text : String) return String is
      T : constant String := Trim (Text);
      N : constant String := Normalize (T);
      Stop : Natural := 0;
      First : Natural := T'First;
   begin
      if T = "" then
         return "";
      end if;
      if N'Length >= 3 and then N (N'First .. N'First + 2) = "in " then
         First := T'First + 3;
         if N'Length >= 7 and then N (N'First .. N'First + 6) = "in out " then
            First := T'First + 7;
         end if;
      elsif N'Length >= 4 and then N (N'First .. N'First + 3) = "out " then
         First := T'First + 4;
      end if;
      for I in First .. T'Last loop
         if I < T'Last and then T (I) = ':' and then T (I + 1) = '=' then
            Stop := I;
            exit;
         elsif T (I) = ';' or else T (I) = ')' then
            Stop := I;
            exit;
         end if;
      end loop;
      if Stop = 0 then
         return Trim (T (First .. T'Last));
      elsif Stop > First then
         return Trim (T (First .. Stop - 1));
      else
         return "";
      end if;
   end Clean_Formal_Subtype;

   function Formal_Subtype_By_Position (Callable_Label : String; Position : Positive) return String is
      List : constant String := Formal_List_Text (Callable_Label);
      Start : Natural := (if List = "" then 0 else List'First);
      Pos : Natural := 0;
   begin
      if List = "" then
         return "";
      end if;
      for I in List'Range loop
         if List (I) = ';' then
            declare
               Part : constant String := Trim (List (Start .. I - 1));
               Colon : constant Natural := Ada.Strings.Fixed.Index (Part, ":");
            begin
               if Colon /= 0 then
                  declare
                     Names : constant String := Part (Part'First .. Colon - 1);
                     Cnt   : constant Natural := Count_Names_In_Formal (Names);
                  begin
                     if Position > Pos and then Position <= Pos + Cnt then
                        return Clean_Formal_Subtype (Part (Colon + 1 .. Part'Last));
                     end if;
                     Pos := Pos + Cnt;
                  end;
               end if;
            end;
            Start := I + 1;
         end if;
      end loop;
      declare
         Part : constant String := Trim (List (Start .. List'Last));
         Colon : constant Natural := Ada.Strings.Fixed.Index (Part, ":");
      begin
         if Colon /= 0 then
            declare
               Names : constant String := Part (Part'First .. Colon - 1);
               Cnt   : constant Natural := Count_Names_In_Formal (Names);
            begin
               if Position > Pos and then Position <= Pos + Cnt then
                  return Clean_Formal_Subtype (Part (Colon + 1 .. Part'Last));
               end if;
            end;
         end if;
      end;
      return "";
   end Formal_Subtype_By_Position;

   function Formal_Subtype_By_Name (Callable_Label : String; Name : String) return String is
      List : constant String := Formal_List_Text (Callable_Label);
      NName : constant String := Normalize (Name);
      Start : Natural := (if List = "" then 0 else List'First);
   begin
      if List = "" or else NName = "" then
         return "";
      end if;
      for I in List'Range loop
         if List (I) = ';' then
            declare
               Part : constant String := Trim (List (Start .. I - 1));
               Colon : constant Natural := Ada.Strings.Fixed.Index (Part, ":");
            begin
               if Colon /= 0 then
                  declare
                     Names : constant String := Part (Part'First .. Colon - 1);
                     Cnt   : constant Natural := Count_Names_In_Formal (Names);
                  begin
                     for J in 1 .. Cnt loop
                        if Normalize (Name_At_In_Formal (Names, J)) = NName then
                           return Clean_Formal_Subtype (Part (Colon + 1 .. Part'Last));
                        end if;
                     end loop;
                  end;
               end if;
            end;
            Start := I + 1;
         end if;
      end loop;
      declare
         Part : constant String := Trim (List (Start .. List'Last));
         Colon : constant Natural := Ada.Strings.Fixed.Index (Part, ":");
      begin
         if Colon /= 0 then
            declare
               Names : constant String := Part (Part'First .. Colon - 1);
               Cnt   : constant Natural := Count_Names_In_Formal (Names);
            begin
               for J in 1 .. Cnt loop
                  if Normalize (Name_At_In_Formal (Names, J)) = NName then
                     return Clean_Formal_Subtype (Part (Colon + 1 .. Part'Last));
                  end if;
               end loop;
            end;
         end if;
      end;
      return "";
   end Formal_Subtype_By_Name;

   function Named_Actual_Formal_Name (Text : String) return String is
      Arrow : constant Natural := Ada.Strings.Fixed.Index (Text, "=>");
   begin
      if Arrow = 0 or else Arrow = Text'First then
         return "";
      end if;
      return Trim (Text (Text'First .. Arrow - 1));
   end Named_Actual_Formal_Name;

   function Actual_Expression_Text (Text : String) return String is
      Arrow : constant Natural := Ada.Strings.Fixed.Index (Text, "=>");
   begin
      if Arrow /= 0 and then Arrow + 2 <= Text'Last then
         return Trim (Text (Arrow + 2 .. Text'Last));
      end if;
      return Trim (Text);
   end Actual_Expression_Text;

   function Extract_Designator_Before_Call (Text : String) return String is
      T : constant String := Trim (Text);
      Last : Natural := T'Last;
   begin
      while Last >= T'First and then T (Last) = ';' loop
         if Last = T'First then
            return "";
         end if;
         Last := Last - 1;
      end loop;
      for I in T'Range loop
         if T (I) = '(' then
            if I = T'First then
               return "";
            else
               return Trim (T (T'First .. I - 1));
            end if;
         end if;
      end loop;
      return Trim (T (T'First .. Last));
   end Extract_Designator_Before_Call;

   function Extract_First_Actual_Text (Text : String) return String is
      T : constant String := Trim (Text);
      L : Natural := 0;
      R : Natural := 0;
      Depth : Natural := 0;
   begin
      for I in T'Range loop
         if T (I) = '(' then
            L := I;
            exit;
         end if;
      end loop;
      if L = 0 or else L = T'Last then
         return "";
      end if;
      for I in L + 1 .. T'Last loop
         if T (I) = '(' then
            Depth := Depth + 1;
         elsif T (I) = ')' then
            if Depth = 0 then
               R := I;
               exit;
            else
               Depth := Depth - 1;
            end if;
         elsif T (I) = ',' and then Depth = 0 then
            R := I;
            exit;
         end if;
      end loop;
      if R = 0 or else R <= L + 1 then
         return "";
      end if;
      return Trim (T (L + 1 .. R - 1));
   end Extract_First_Actual_Text;

   function Infer_Text_Subtype
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Text       : String) return String
   is
      T : constant String := Trim (Text);
      NT : constant String := Normalize (T);
   begin
      if T = "" then
         return "";
      elsif NT = "true" or else NT = "false" then
         return "Boolean";
      elsif NT = "null" then
         return "null";
      elsif (T (T'First) = '"' and then T (T'Last) = '"') then
         return "String";
      elsif T (T'First) in '0' .. '9' then
         declare
            V : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
              Editor.Ada_Static_Expressions.Evaluate_Numeric_Expression (Static, Region, T);
         begin
            if V.Status = Editor.Ada_Static_Expressions.Static_Value_Integer then
               return "Universal_Integer";
            elsif V.Status = Editor.Ada_Static_Expressions.Static_Value_Real then
               return "Universal_Real";
            end if;
         end;
      else
         declare
            Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
              Editor.Ada_Direct_Visibility.Lookup_Visible
                (Visibility, Regions, Region, Editor.Ada_Expression_Types.Inference_Support.Primary_Name (T));
         begin
            if Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found then
               declare
                  Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
                    Editor.Ada_Direct_Visibility.Declaration (Visibility, Lookup.Declaration);
               begin
                  return Inference_Support.Subtype_From_Declaration_Label
                    (To_String (Editor.Ada_Syntax_Tree.Node (Tree, Decl.Node).Label));
               end;
            end if;
         end;
      end if;
      return "";
   end Infer_Text_Subtype;

   function Actual_Position_In_Call
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Call : Editor.Ada_Syntax_Tree.Node_Id;
      Node : Editor.Ada_Syntax_Tree.Node_Info) return Natural
   is
      Count : Natural := 0;
   begin
      if Call = Editor.Ada_Syntax_Tree.No_Node then
         return 0;
      end if;
      for I in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Call) loop
         declare
            Child_Id : constant Editor.Ada_Syntax_Tree.Node_Id :=
              Editor.Ada_Syntax_Tree.Child_At (Tree, Call, I);
            Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node (Tree, Child_Id);
         begin
            if Child.Kind = Editor.Ada_Syntax_Tree.Node_Positional_Association or else
              Child.Kind = Editor.Ada_Syntax_Tree.Node_Named_Association or else
              Child.Kind = Editor.Ada_Syntax_Tree.Node_Association or else
              Child.Kind in Editor.Ada_Syntax_Tree.Node_Expression .. Editor.Ada_Syntax_Tree.Node_Allocator
            then
               Count := Count + 1;
               if Child.Id = Node.Id then
                  return Count;
               end if;
            end if;
         end;
      end loop;
      return 0;
   end Actual_Position_In_Call;

   function Callable_Result_Subtype (Callable_Label : String) return String is
      N : constant String := Normalize (Callable_Label);
      R : constant Natural := Ada.Strings.Fixed.Index (N, " return ");
      Original : constant String := Callable_Label;
   begin
      if R = 0 then
         return "";
      end if;
      declare
         Tail : constant String := Trim (Original (Original'First + R + 7 - 1 .. Original'Last));
         Normalized_Tail : constant String := Normalize (Tail);
         Semi : constant Natural := Ada.Strings.Fixed.Index (Tail, ";");
         Is_Pos : constant Natural := Ada.Strings.Fixed.Index (Normalized_Tail, " is");
         Body_Pos : constant Natural := Ada.Strings.Fixed.Index (Normalized_Tail, " is ");
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
         return Trim (Tail (Tail'First .. Tail'First + End_Pos - 1));
      end;
   end Callable_Result_Subtype;

   function Is_Class_Wide_Subtype (Text : String) return Boolean is
      N : constant String := Normalize (Text);
   begin
      return Contains (N, "'class") or else Contains (N, " class");
   end Is_Class_Wide_Subtype;

   function Looks_Primitive_Call_Designator (Text : String) return Boolean is
      T : constant String := Normalize (Text);
   begin
      return Contains (T, ".") or else Contains (T, "(");
   end Looks_Primitive_Call_Designator;

end Editor.Ada_Expression_Types.Call_Text_Helpers;
