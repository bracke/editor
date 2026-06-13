with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Type_Graph is

   use type Editor.Ada_Direct_Visibility.Declaration_Id;
   use type Editor.Ada_Declarative_Regions.Region_Id;

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

   function Hash_Text (Text : String) return Natural is
      H : Natural := 2166136261 mod Natural'Last;
   begin
      for C of Text loop
         H := (H * 16777619 + Character'Pos (Ada.Characters.Handling.To_Lower (C)) + 1) mod Natural'Last;
      end loop;
      return H;
   end Hash_Text;

   procedure Mix (Model : in out Type_Model; Value : Natural) is
   begin
      Model.Result_Fingerprint :=
        (Model.Result_Fingerprint * 65599 + Value + 61) mod Natural'Last;
   end Mix;

   function Starts_With (Text : String; Prefix : String) return Boolean is
      T : constant String := Lower (Trim (Text));
      P : constant String := Lower (Prefix);
   begin
      return T'Length >= P'Length and then T (T'First .. T'First + P'Length - 1) = P;
   end Starts_With;

   function Contains (Text : String; Pattern : String) return Boolean is
   begin
      return Ada.Strings.Fixed.Index (Lower (Text), Lower (Pattern)) /= 0;
   end Contains;

   function Segment_Before (Text : String; Pattern : String) return String is
      Pos : constant Natural := Ada.Strings.Fixed.Index (Lower (Text), Lower (Pattern));
   begin
      if Pos = 0 then
         return Text;
      elsif Pos = Text'First then
         return "";
      else
         return Text (Text'First .. Pos - 1);
      end if;
   end Segment_Before;

   function First_Word (Text : String) return String is
      T : constant String := Trim (Text);
   begin
      for I in T'Range loop
         if T (I) = ' ' or else T (I) = ASCII.HT
           or else T (I) = '(' or else T (I) = ';'
         then
            if I = T'First then
               return "";
            else
               return T (T'First .. I - 1);
            end if;
         end if;
      end loop;
      return T;
   end First_Word;

   function Strip_Constraints (Text : String) return String is
      First  : constant String := Segment_Before (Trim (Text), " range ");
      Second : constant String := Segment_Before (First, " with ");
      Third  : constant String := Segment_Before (Second, ";");
   begin
      return Trim (Third);
   end Strip_Constraints;

   function Base_Name_For_Definition (Definition : String) return String is
      Work : constant String := Trim (Definition);
      L    : constant String := Lower (Work);
   begin
      if Starts_With (L, "new ") then
         if Work'Length <= 4 then
            return "";
         end if;
         return Strip_Constraints (Work (Work'First + 4 .. Work'Last));
      elsif Starts_With (L, "range ")
        or else Starts_With (L, "mod ")
        or else Starts_With (L, "digits ")
        or else Starts_With (L, "delta ")
        or else Starts_With (L, "array")
        or else Starts_With (L, "record")
        or else Starts_With (L, "access")
        or else Starts_With (L, "private")
        or else Starts_With (L, "interface")
      then
         return "";
      else
         return First_Word (Strip_Constraints (Work));
      end if;
   end Base_Name_For_Definition;

   function Category_For
     (Kind       : Editor.Ada_Syntax_Tree.Node_Kind;
      Definition : String) return Type_Category
   is
      use type Editor.Ada_Syntax_Tree.Node_Kind;
      L : constant String := Lower (Trim (Definition));
   begin
      if Kind = Editor.Ada_Syntax_Tree.Node_Formal_Type_Declaration then
         return Type_Category_Formal;
      elsif Kind = Editor.Ada_Syntax_Tree.Node_Subtype_Declaration then
         return Type_Category_Subtype;
      elsif Starts_With (L, "new ") then
         return Type_Category_Derived;
      elsif Starts_With (L, "range ") then
         return Type_Category_Integer;
      elsif Starts_With (L, "mod ") then
         return Type_Category_Modular;
      elsif Starts_With (L, "digits ") then
         return Type_Category_Floating;
      elsif Starts_With (L, "delta ") then
         return Type_Category_Fixed;
      elsif Starts_With (L, "array") then
         return Type_Category_Array;
      elsif Starts_With (L, "record") or else Contains (L, " record") then
         return Type_Category_Record;
      elsif Starts_With (L, "access") then
         return Type_Category_Access;
      elsif Starts_With (L, "interface") or else Contains (L, " interface") then
         return Type_Category_Interface;
      elsif Starts_With (L, "private") or else Contains (L, " private") then
         return Type_Category_Private;
      else
         return Type_Category_Unknown;
      end if;
   end Category_For;

   function Declaration_Subtype_Text
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return String
   is
      use type Editor.Ada_Syntax_Tree.Node_Kind;
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
   end Declaration_Subtype_Text;

   function Is_Type_Declaration
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Info : Editor.Ada_Direct_Visibility.Declaration_Info) return Boolean
   is
      use type Editor.Ada_Syntax_Tree.Node_Kind;
      Kind : constant Editor.Ada_Syntax_Tree.Node_Kind :=
        Editor.Ada_Syntax_Tree.Node (Tree, Info.Node).Kind;
   begin
      return Kind = Editor.Ada_Syntax_Tree.Node_Type_Declaration
        or else Kind = Editor.Ada_Syntax_Tree.Node_Subtype_Declaration
        or else Kind = Editor.Ada_Syntax_Tree.Node_Formal_Type_Declaration
        or else Kind = Editor.Ada_Syntax_Tree.Node_Incomplete_Type_Declaration
        or else Kind = Editor.Ada_Syntax_Tree.Node_Private_Extension_Declaration;
   end Is_Type_Declaration;

   function Empty_Type return Type_Info is
   begin
      return (Id => No_Type,
              Declaration => Editor.Ada_Direct_Visibility.No_Declaration,
              Node => Editor.Ada_Syntax_Tree.No_Node,
              Region => Editor.Ada_Declarative_Regions.No_Region,
              Name => Null_Unbounded_String,
              Normalized_Name => Null_Unbounded_String,
              Category => Type_Category_Unknown,
              Base_Subtype => Null_Unbounded_String,
              Normalized_Base => Null_Unbounded_String,
              Base_Declaration => Editor.Ada_Direct_Visibility.No_Declaration,
              Base_Type => No_Type,
              Relation_Status => Type_Relation_No_Base,
              View_Status => Type_View_Ordinary,
              Partial_View => No_Type,
              Full_View => No_Type,
              Start_Line => 1,
              End_Line => 1,
              Fingerprint => 0);
   end Empty_Type;

   procedure Add_Type
     (Model      : in out Type_Model;
      Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Decl       : Editor.Ada_Direct_Visibility.Declaration_Info)
   is
      use type Editor.Ada_Direct_Visibility.Lookup_Status;
      use type Editor.Ada_Direct_Visibility.Declaration_Id;
      use type Editor.Ada_Declarative_Regions.Region_Id;
      Node_Info  : constant Editor.Ada_Syntax_Tree.Node_Info :=
        Editor.Ada_Syntax_Tree.Node (Tree, Decl.Node);
      Def        : constant String := Declaration_Subtype_Text (Tree, Decl.Node);
      Base       : constant String := Base_Name_For_Definition (Def);
      Lookup     : Editor.Ada_Direct_Visibility.Lookup_Result;
      Info       : Type_Info := Empty_Type;
   begin
      Info.Id := Type_Id (Natural (Model.Types.Length) + 1);
      Info.Declaration := Decl.Id;
      Info.Node := Decl.Node;
      Info.Region := Decl.Region;
      Info.Name := Decl.Name;
      Info.Normalized_Name := Decl.Normalized;
      Info.Category := Category_For (Node_Info.Kind, Def);
      if Info.Category = Type_Category_Private then
         Info.View_Status := Type_View_Private_Completion_Unresolved;
      end if;
      Info.Base_Subtype := To_Unbounded_String (Base);
      Info.Normalized_Base := To_Unbounded_String (Normalize (Base));
      Info.Start_Line := Decl.Start_Line;
      Info.End_Line := Decl.End_Line;

      if Base = "" then
         Info.Relation_Status := Type_Relation_No_Base;
      else
         Lookup := Editor.Ada_Direct_Visibility.Lookup_Visible
           (Visibility, Regions, Decl.Region, Base);
         if Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found then
            Info.Base_Declaration := Lookup.Declaration;
            Info.Relation_Status := Type_Relation_Base_Resolved;
         elsif Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous then
            Info.Relation_Status := Type_Relation_Base_Ambiguous;
         else
            Info.Relation_Status := Type_Relation_Base_Unresolved;
         end if;
      end if;

      Info.Fingerprint :=
        (Type_Category'Pos (Info.Category) * 1000003
         + Type_Relation_Status'Pos (Info.Relation_Status) * 10007
         + Type_View_Status'Pos (Info.View_Status) * 3001
         + Natural (Info.Declaration) * 1009
         + Natural (Info.Region) * 97
         + Hash_Text (To_String (Info.Normalized_Name)) * 53
         + Hash_Text (To_String (Info.Normalized_Base)) * 17) mod Natural'Last;
      Model.Types.Append (Info);
      Mix (Model, Info.Fingerprint);
   end Add_Type;

   procedure Resolve_Base_Type_Ids (Model : in out Type_Model) is
      use type Editor.Ada_Direct_Visibility.Declaration_Id;
   begin
      for I in 1 .. Natural (Model.Types.Length) loop
         if Model.Types (I).Base_Declaration /= Editor.Ada_Direct_Visibility.No_Declaration then
            for J in 1 .. Natural (Model.Types.Length) loop
               if Model.Types (J).Declaration = Model.Types (I).Base_Declaration then
                  declare
                     Info : Type_Info := Model.Types (I);
                  begin
                     Info.Base_Type := Model.Types (J).Id;
                     Info.Fingerprint :=
                       (Info.Fingerprint * 131 + Natural (Info.Base_Type) + 19) mod Natural'Last;
                     Model.Types.Replace_Element (I, Info);
                  end;
                  exit;
               end if;
            end loop;
         end if;
      end loop;
   end Resolve_Base_Type_Ids;



   function Same_View_Region
     (Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Left    : Editor.Ada_Declarative_Regions.Region_Id;
      Right   : Editor.Ada_Declarative_Regions.Region_Id) return Boolean is
      use type Editor.Ada_Declarative_Regions.Region_Id;
      Left_Info  : constant Editor.Ada_Declarative_Regions.Region_Info :=
        Editor.Ada_Declarative_Regions.Region (Regions, Left);
      Right_Info : constant Editor.Ada_Declarative_Regions.Region_Info :=
        Editor.Ada_Declarative_Regions.Region (Regions, Right);
   begin
      return Left = Right
        or else (Left_Info.Parent /= Editor.Ada_Declarative_Regions.No_Region
                 and then Left_Info.Parent = Right)
        or else (Right_Info.Parent /= Editor.Ada_Declarative_Regions.No_Region
                 and then Right_Info.Parent = Left)
        or else (Left_Info.Parent /= Editor.Ada_Declarative_Regions.No_Region
                 and then Left_Info.Parent = Right_Info.Parent);
   end Same_View_Region;

   procedure Link_Private_Views
     (Model   : in out Type_Model;
      Regions : Editor.Ada_Declarative_Regions.Region_Model) is
      use type Type_Id;
      use type Type_Category;
   begin
      for I in 1 .. Natural (Model.Types.Length) loop
         if Model.Types (I).Category = Type_Category_Private then
            declare
               Partial : Type_Info := Model.Types (I);
            begin
               for J in 1 .. Natural (Model.Types.Length) loop
                  if I /= J
                    and then Same_View_Region (Regions, Model.Types (J).Region, Partial.Region)
                    and then To_String (Model.Types (J).Normalized_Name) = To_String (Partial.Normalized_Name)
                    and then Model.Types (J).Category /= Type_Category_Private
                  then
                     Partial.Full_View := Model.Types (J).Id;
                     Partial.View_Status := Type_View_Private_Partial;
                     Partial.Fingerprint :=
                       (Partial.Fingerprint * 131 + Natural (Partial.Full_View) + 29) mod Natural'Last;
                     Model.Types.Replace_Element (I, Partial);
                     declare
                        Full : Type_Info := Model.Types (J);
                     begin
                        Full.Partial_View := Partial.Id;
                        Full.View_Status := Type_View_Private_Full;
                        Full.Fingerprint :=
                          (Full.Fingerprint * 131 + Natural (Full.Partial_View) + 31) mod Natural'Last;
                        Model.Types.Replace_Element (J, Full);
                     end;
                     exit;
                  end if;
               end loop;
            end;
         end if;
      end loop;
   end Link_Private_Views;

   procedure Clear (Model : in out Type_Model) is
   begin
      Model.Types.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model)
      return Type_Model
   is
      Model : Type_Model;
   begin
      Clear (Model);
      for Index in 1 .. Editor.Ada_Direct_Visibility.Declaration_Count (Visibility) loop
         declare
            Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
              Editor.Ada_Direct_Visibility.Declaration_At (Visibility, Index);
         begin
            if Is_Type_Declaration (Tree, Decl) then
               Add_Type (Model, Tree, Regions, Visibility, Decl);
            end if;
         end;
      end loop;
      Resolve_Base_Type_Ids (Model);
      Link_Private_Views (Model, Regions);
      Mix (Model, Editor.Ada_Syntax_Tree.Fingerprint (Tree));
      Mix (Model, Editor.Ada_Direct_Visibility.Fingerprint (Visibility));
      return Model;
   end Build;

   function Has_Types (Model : Type_Model) return Boolean is
   begin
      return not Model.Types.Is_Empty;
   end Has_Types;

   function Type_Count (Model : Type_Model) return Natural is
   begin
      return Natural (Model.Types.Length);
   end Type_Count;

   function Type_At (Model : Type_Model; Index : Positive) return Type_Info is
   begin
      if Index > Natural (Model.Types.Length) then
         return Empty_Type;
      end if;
      return Model.Types (Index);
   end Type_At;

   function Type_Node (Model : Type_Model; Id : Type_Id) return Type_Info is
   begin
      if Id = No_Type or else Natural (Id) > Natural (Model.Types.Length) then
         return Empty_Type;
      end if;
      return Model.Types (Positive (Id));
   end Type_Node;

   function Type_For_Declaration
     (Model       : Type_Model;
      Declaration : Editor.Ada_Direct_Visibility.Declaration_Id) return Type_Id
   is
   begin
      for Info of Model.Types loop
         if Info.Declaration = Declaration then
            return Info.Id;
         end if;
      end loop;
      return No_Type;
   end Type_For_Declaration;

   function Lookup_Type
     (Model  : Type_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name   : String) return Type_Id
   is
      Wanted : constant String := Normalize (Name);
   begin
      for Info of Model.Types loop
         if Info.Region = Region and then To_String (Info.Normalized_Name) = Wanted then
            return Info.Id;
         end if;
      end loop;
      return No_Type;
   end Lookup_Type;

   function Is_Derived_From
     (Model    : Type_Model;
      Derived  : Type_Id;
      Ancestor : Type_Id) return Boolean
   is
      use type Type_Id;
      Current : Type_Id := Derived;
      Guard   : Natural := 0;
   begin
      if Derived = No_Type or else Ancestor = No_Type then
         return False;
      end if;
      while Current /= No_Type and then Guard <= Natural (Model.Types.Length) loop
         if Current = Ancestor then
            return True;
         end if;
         Current := Type_Node (Model, Current).Base_Type;
         Guard := Guard + 1;
      end loop;
      return False;
   end Is_Derived_From;

   function Compatibility
     (Model    : Type_Model;
      Expected : Type_Id;
      Actual   : Type_Id) return Compatibility_Status
   is
      use type Type_Id;
      Expected_Info : constant Type_Info := Type_Node (Model, Expected);
      Actual_Info   : constant Type_Info := Type_Node (Model, Actual);
   begin
      if Expected = No_Type or else Actual = No_Type then
         return Type_Compatibility_Indeterminate;
      elsif Expected = Actual then
         return Type_Compatibility_Exact_Type;
      elsif Actual_Info.Category = Type_Category_Subtype
        and then Is_Derived_From (Model, Actual_Info.Base_Type, Expected)
      then
         return Type_Compatibility_Subtype_Of;
      elsif Is_Derived_From (Model, Actual, Expected) then
         return Type_Compatibility_Derived_From;
      elsif Expected_Info.Full_View /= No_Type and then Expected_Info.Full_View = Actual then
         return Type_Compatibility_Exact_Type;
      elsif Expected_Info.Partial_View /= No_Type and then Expected_Info.Partial_View = Actual then
         return Type_Compatibility_Exact_Type;
      elsif Expected_Info.Base_Type /= No_Type and then Actual_Info.Base_Type /= No_Type
        and then Expected_Info.Base_Type /= Actual_Info.Base_Type
      then
         return Type_Compatibility_Known_Different_Root;
      else
         return Type_Compatibility_Indeterminate;
      end if;
   end Compatibility;



   function Class_Wide_Compatibility
     (Model         : Type_Model;
      Expected_Root : Type_Id;
      Actual        : Type_Id) return Compatibility_Status
   is
      use type Type_Id;
   begin
      if Expected_Root = No_Type or else Actual = No_Type then
         return Type_Compatibility_Indeterminate;
      elsif Expected_Root = Actual then
         return Type_Compatibility_Class_Wide;
      elsif Is_Derived_From (Model, Actual, Expected_Root) then
         return Type_Compatibility_Class_Wide;
      else
         return Compatibility (Model, Expected_Root, Actual);
      end if;
   end Class_Wide_Compatibility;

   function Fingerprint (Model : Type_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Type_Graph;
