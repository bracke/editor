with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Expression_Types.Inference_Support;
with Editor.Ada_Expression_Types.Status_Helpers;

package body Editor.Ada_Expression_Types.Access_Text_Helpers is

   use type Editor.Ada_Type_Graph.Type_Id;
   use type Editor.Ada_Type_Graph.Type_Category;
   use type Editor.Ada_Syntax_Tree.Node_Kind;
   use type Editor.Ada_Direct_Visibility.Lookup_Status;
   use Editor.Ada_Expression_Types.Inference_Support;

   function Trim (Text : String) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Trim;

   function Normalize (Text : String) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Normalize;

   function Contains (Text : String; Pattern : String) return Boolean
     renames Editor.Ada_Expression_Types.Status_Helpers.Contains;

   function Declaration_Definition_Text
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return String
   is
   begin
      for Index in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Node) loop
         declare
            Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node
                (Tree, Editor.Ada_Syntax_Tree.Child_At (Tree, Node, Index));
         begin
            if Child.Kind = Editor.Ada_Syntax_Tree.Node_Declaration_Subtype then
               return Trim (To_String (Child.Label));
            end if;
         end;
      end loop;
      return "";
   end Declaration_Definition_Text;

   function Starts_With (Text : String; Prefix : String) return Boolean is
   begin
      return Text'Length >= Prefix'Length and then
        Text (Text'First .. Text'First + Prefix'Length - 1) = Prefix;
   end Starts_With;

   function Drop_Prefix (Text : String; Length : Natural) return String is
      T : constant String := Trim (Text);
   begin
      if T'Length <= Length then
         return "";
      else
         return Trim (T (T'First + Length .. T'Last));
      end if;
   end Drop_Prefix;

   function Strip_Access_Qualifiers (Text : String) return String is
      T : constant String := Trim (Text);
      N : constant String := Normalize (T);
   begin
      if T = "" then
         return "";
      elsif Starts_With (N, "not null access") then
         return Drop_Prefix (T, 15);
      elsif Starts_With (N, "access all") then
         return Drop_Prefix (T, 10);
      elsif Starts_With (N, "access constant") then
         return Drop_Prefix (T, 15);
      elsif Starts_With (N, "access") then
         return Drop_Prefix (T, 6);
      else
         return "";
      end if;
   end Strip_Access_Qualifiers;

   function Designated_Subtype_For_Access_Type
     (Tree  : Editor.Ada_Syntax_Tree.Tree_Type;
      Types : Editor.Ada_Type_Graph.Type_Model;
      Id    : Editor.Ada_Type_Graph.Type_Id) return String
   is
   begin
      if Id = Editor.Ada_Type_Graph.No_Type then
         return "";
      else
         declare
            T : constant Editor.Ada_Type_Graph.Type_Info :=
              Editor.Ada_Type_Graph.Type_Node (Types, Id);
            Def : constant String := Declaration_Definition_Text (Tree, T.Node);
            Direct : constant String := Strip_Access_Qualifiers (Def);
         begin
            if T.Category /= Editor.Ada_Type_Graph.Type_Category_Access then
               return "";
            elsif Direct /= "" then
               return Direct;
            elsif To_String (T.Base_Subtype) /= "" then
               return Strip_Access_Qualifiers (To_String (T.Base_Subtype));
            else
               return "";
            end if;
         end;
      end if;
   end Designated_Subtype_For_Access_Type;

   function Object_Subtype_For_Name
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Name       : String;
      Declaration : out Editor.Ada_Direct_Visibility.Declaration_Id;
      Candidates  : out Natural) return String
   is
      Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
        Editor.Ada_Direct_Visibility.Lookup_Visible
          (Visibility, Regions, Region, Primary_Name (Name));
   begin
      Declaration := Editor.Ada_Direct_Visibility.No_Declaration;
      Candidates := Lookup.Match_Count;
      if Lookup.Status /= Editor.Ada_Direct_Visibility.Lookup_Found then
         return "";
      end if;
      Declaration := Lookup.Declaration;
      declare
         Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
           Editor.Ada_Direct_Visibility.Declaration (Visibility, Lookup.Declaration);
         Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
           Editor.Ada_Syntax_Tree.Node (Tree, Decl.Node);
         Subt : constant String := Inference_Support.Subtype_From_Declaration_Label
           (To_String (Editor.Ada_Syntax_Tree.Node (Tree, Decl.Node).Label));
      begin
         if Node.Kind = Editor.Ada_Syntax_Tree.Node_Object_Declaration or else
           Node.Kind = Editor.Ada_Syntax_Tree.Node_Constant_Declaration or else
           Node.Kind = Editor.Ada_Syntax_Tree.Node_Formal_Object_Declaration
         then
            return Subt;
         elsif Node.Kind = Editor.Ada_Syntax_Tree.Node_Subprogram_Declaration or else
           Node.Kind = Editor.Ada_Syntax_Tree.Node_Subprogram_Body or else
           Node.Kind = Editor.Ada_Syntax_Tree.Node_Formal_Subprogram_Declaration
         then
            return "subprogram";
         else
            return Subt;
         end if;
      end;
   end Object_Subtype_For_Name;

   function Allocator_Target_From_Text (Text : String) return String is
      T : constant String := Trim (Text);
      N : constant String := Normalize (T);
      New_Pos : Natural := 0;
      Start : Natural := 0;
      Stop  : Natural := 0;
      Depth : Natural := 0;
   begin
      if Starts_With (N, "new") then
         New_Pos := T'First;
      else
         New_Pos := Ada.Strings.Fixed.Index (N, " new ");
         if New_Pos /= 0 then
            New_Pos := New_Pos + 1;
         end if;
      end if;
      if New_Pos = 0 then
         return "";
      end if;
      Start := New_Pos + 3;
      while Start <= T'Last and then T (Start) = ' ' loop
         Start := Start + 1;
      end loop;
      if Start > T'Last then
         return "";
      end if;
      Stop := T'Last;
      for I in Start .. T'Last loop
         if T (I) = '(' then
            if Depth = 0 then
               Stop := I - 1;
               exit;
            else
               Depth := Depth + 1;
            end if;
         elsif T (I) = Character'Val (39) then
            Stop := I - 1;
            exit;
         elsif T (I) = ';' then
            Stop := I - 1;
            exit;
         end if;
      end loop;
      if Stop < Start then
         return "";
      else
         return Trim (T (Start .. Stop));
      end if;
   end Allocator_Target_From_Text;

   function Expected_Access_Designated_Subtype (Expected : String) return String is
   begin
      return Strip_Access_Qualifiers (Expected);
   end Expected_Access_Designated_Subtype;

end Editor.Ada_Expression_Types.Access_Text_Helpers;
