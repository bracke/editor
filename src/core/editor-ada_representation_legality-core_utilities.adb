with Ada.Characters.Handling;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Representation_Legality.Core_Utilities is

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Syntax_Tree.Node_Kind;

   function Mix (A, B : Natural) return Natural is
      type Hash_Value is mod 2 ** 64;
   begin
      return Natural
        ((Hash_Value (A) * 131 + Hash_Value (B) + 989)
         mod Hash_Value (Natural'Last));
   end Mix;

   function Trimmed (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trimmed;

   function Lower (Text : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (Trimmed (Text));
   end Lower;

   function Normalized (Text : String) return String is
      Clean : constant String := Trimmed (Text);
      Dot   : Natural := 0;
      Tick  : Natural := 0;
   begin
      if Clean = "" then
         return "";
      end if;

      for Index in Clean'Range loop
         if Clean (Index) = '.' then
            Dot := Index;
         elsif Character'Pos (Clean (Index)) = 39 then
            Tick := Index;
            exit;
         end if;
      end loop;

      declare
         Base : constant String :=
           (if Tick /= 0 then Clean (Clean'First .. Tick - 1) else Clean);
      begin
         if Dot /= 0 and then Dot < Base'Last then
            return Lower (Base (Dot + 1 .. Base'Last));
         else
            return Lower (Base);
         end if;
      end;
   end Normalized;

   function Child_Label
     (Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Parent : Editor.Ada_Syntax_Tree.Node_Id;
      Kind   : Editor.Ada_Syntax_Tree.Node_Kind) return String is
   begin
      if Parent = Editor.Ada_Syntax_Tree.No_Node then
         return "";
      end if;

      for Index in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Parent) loop
         declare
            Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node
                (Tree, Editor.Ada_Syntax_Tree.Child_At (Tree, Parent, Index));
         begin
            if Child.Kind = Kind then
               return To_String (Child.Label);
            end if;
         end;
      end loop;

      return "";
   end Child_Label;

   function Attribute_Name (Target_Text : String) return String is
      T : constant String := Trimmed (Target_Text);
   begin
      for I in T'Range loop
         if Character'Pos (T (I)) = 39 then
            if I < T'Last then
               return Lower (T (I + 1 .. T'Last));
            else
               return "";
            end if;
         end if;
      end loop;
      return "";
   end Attribute_Name;

   function Strip_Leading_At (Text : String) return String is
      T : constant String := Trimmed (Text);
      L : constant String := Lower (T);
   begin
      if T'Length >= 2 and then L (L'First .. L'First + 1) = "at" then
         if T'Length = 2 then
            return "";
         else
            return Trimmed (T (T'First + 2 .. T'Last));
         end if;
      end if;
      return T;
   end Strip_Leading_At;

   function Range_First (Text : String) return String is
      T : constant String := Trimmed (Text);
      P : constant Natural := Ada.Strings.Fixed.Index (T, "..");
   begin
      if P = 0 then
         return T;
      elsif P = T'First then
         return "";
      else
         return Trimmed (T (T'First .. P - 1));
      end if;
   end Range_First;

   function Range_Last (Text : String) return String is
      T : constant String := Trimmed (Text);
      P : constant Natural := Ada.Strings.Fixed.Index (T, "..");
   begin
      if P = 0 or else P + 2 > T'Last then
         return "";
      else
         return Trimmed (T (P + 2 .. T'Last));
      end if;
   end Range_Last;

   function Ancestor_Representation_Clause
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return Editor.Ada_Syntax_Tree.Node_Id is
      Cur : Editor.Ada_Syntax_Tree.Node_Id := Node;
   begin
      while Cur /= Editor.Ada_Syntax_Tree.No_Node loop
         declare
            N : constant Editor.Ada_Syntax_Tree.Node_Info := Editor.Ada_Syntax_Tree.Node (Tree, Cur);
         begin
            if N.Kind = Editor.Ada_Syntax_Tree.Node_Representation_Clause then
               return Cur;
            end if;
            Cur := N.Parent;
         end;
      end loop;
      return Editor.Ada_Syntax_Tree.No_Node;
   end Ancestor_Representation_Clause;

   function Declaration_Name
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return String is
   begin
      return Child_Label (Tree, Node, Editor.Ada_Syntax_Tree.Node_Declaration_Name);
   end Declaration_Name;

   function Name_List_Contains (List_Text, Name : String) return Boolean is
      L : constant String := Lower (List_Text);
      N : constant String := Lower (Name);
      Start : Positive := L'First;
      Stop  : Natural;
   begin
      if N = "" then
         return False;
      end if;

      while Start <= L'Last loop
         Stop := 0;
         for I in Start .. L'Last loop
            if L (I) = ',' then
               Stop := I;
               exit;
            end if;
         end loop;
         declare
            Part : constant String :=
              Trimmed (if Stop = 0 then L (Start .. L'Last) else L (Start .. Stop - 1));
         begin
            if Part = N then
               return True;
            end if;
         end;
         exit when Stop = 0;
         Start := Stop + 1;
      end loop;

      return False;
   end Name_List_Contains;

   function Has_Record_Component
     (Tree           : Editor.Ada_Syntax_Tree.Tree_Type;
      Record_Type    : Editor.Ada_Syntax_Tree.Node_Id;
      Component_Name : String) return Boolean is
   begin
      if Record_Type = Editor.Ada_Syntax_Tree.No_Node then
         return False;
      end if;

      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            N : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
         begin
            if N.Kind = Editor.Ada_Syntax_Tree.Node_Component_Declaration
              and then Name_List_Contains (Declaration_Name (Tree, N.Id), Component_Name)
            then
               return True;
            end if;
         end;
      end loop;

      return False;
   end Has_Record_Component;

   function Clause_Kind
     (Target_Text : String;
      Item_Text   : String;
      Full_Text   : String) return Editor.Ada_Language_Model.Representation_Clause_Kind is
      Attr : constant String := Attribute_Name (Target_Text);
      Text : constant String := Lower (Full_Text);
      Item : constant String := Trimmed (Item_Text);
   begin
      if Ada.Strings.Fixed.Index (Text, " at ") /= 0 then
         return Editor.Ada_Language_Model.Representation_Address_Clause;
      elsif Ada.Strings.Fixed.Index (Text, " use record") /= 0 then
         return Editor.Ada_Language_Model.Representation_Record_Clause;
      elsif Item'Length > 0
        and then Item (Item'First) = '('
      then
         return Editor.Ada_Language_Model.Representation_Enumeration_Clause;
      elsif Attr = "size" then
         return Editor.Ada_Language_Model.Representation_Size_Clause;
      elsif Attr = "alignment" then
         return Editor.Ada_Language_Model.Representation_Alignment_Clause;
      elsif Attr = "component_size" then
         return Editor.Ada_Language_Model.Representation_Component_Size_Clause;
      elsif Attr = "object_size" then
         return Editor.Ada_Language_Model.Representation_Object_Size_Clause;
      elsif Attr = "value_size" then
         return Editor.Ada_Language_Model.Representation_Value_Size_Clause;
      elsif Attr = "storage_size" then
         return Editor.Ada_Language_Model.Representation_Storage_Size_Clause;
      elsif Attr = "small" then
         return Editor.Ada_Language_Model.Representation_Small_Clause;
      elsif Attr = "machine_radix" then
         return Editor.Ada_Language_Model.Representation_Machine_Radix_Clause;
      elsif Attr = "aft" then
         return Editor.Ada_Language_Model.Representation_Aft_Clause;
      elsif Attr = "bit_order" then
         return Editor.Ada_Language_Model.Representation_Bit_Order_Clause;
      elsif Attr = "scalar_storage_order" then
         return Editor.Ada_Language_Model.Representation_Scalar_Storage_Order_Clause;
      elsif Attr = "default_scalar_storage_order" then
         return Editor.Ada_Language_Model.Representation_Default_Scalar_Storage_Order_Clause;
      elsif Attr = "pack" then
         return Editor.Ada_Language_Model.Representation_Pack_Clause;
      elsif Attr = "atomic" then
         return Editor.Ada_Language_Model.Representation_Atomic_Clause;
      elsif Attr = "volatile" then
         return Editor.Ada_Language_Model.Representation_Volatile_Clause;
      elsif Attr = "independent" then
         return Editor.Ada_Language_Model.Representation_Independent_Clause;
      elsif Attr = "atomic_components" then
         return Editor.Ada_Language_Model.Representation_Atomic_Components_Clause;
      elsif Attr = "volatile_components" then
         return Editor.Ada_Language_Model.Representation_Volatile_Components_Clause;
      elsif Attr = "independent_components" then
         return Editor.Ada_Language_Model.Representation_Independent_Components_Clause;
      elsif Attr = "suppress_initialization" then
         return Editor.Ada_Language_Model.Representation_Suppress_Initialization_Clause;
      elsif Attr = "address" then
         return Editor.Ada_Language_Model.Representation_Address_Clause;
      elsif Attr = "convention" then
         return Editor.Ada_Language_Model.Representation_Convention_Clause;
      elsif Attr = "import" then
         return Editor.Ada_Language_Model.Representation_Import_Clause;
      elsif Attr = "export" then
         return Editor.Ada_Language_Model.Representation_Export_Clause;
      elsif Attr = "external_name" then
         return Editor.Ada_Language_Model.Representation_External_Name_Clause;
      elsif Attr = "link_name" then
         return Editor.Ada_Language_Model.Representation_Link_Name_Clause;
      elsif Attr = "read" then
         return Editor.Ada_Language_Model.Representation_Read_Clause;
      elsif Attr = "write" then
         return Editor.Ada_Language_Model.Representation_Write_Clause;
      elsif Attr = "input" then
         return Editor.Ada_Language_Model.Representation_Input_Clause;
      elsif Attr = "output" then
         return Editor.Ada_Language_Model.Representation_Output_Clause;
      elsif Attr = "put_image" then
         return Editor.Ada_Language_Model.Representation_Put_Image_Clause;
      else
         return Editor.Ada_Language_Model.Representation_Other_Clause;
      end if;
   end Clause_Kind;

end Editor.Ada_Representation_Legality.Core_Utilities;
