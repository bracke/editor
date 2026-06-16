with Ada.Characters.Handling;
with Ada.Containers;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Call_Profile_Shapes;
with Editor.Ada_Direct_Visibility;

package body Editor.Ada_Representation_Legality is

   pragma Suppress (Overflow_Check);

   use type Ada.Containers.Count_Type;
   use type Editor.Ada_Declarative_Regions.Region_Id;
   use type Editor.Ada_Freezing_Points.Freezable_Id;
   use type Editor.Ada_Freezing_Points.Freezable_Kind;
   use type Editor.Ada_Freezing_Points.Representation_Freezing_Status;
   use type Editor.Ada_Freezing_Points.Freezing_Status;
   use type Editor.Ada_Static_Expressions.Static_Value_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Syntax_Tree.Node_Kind;
   use type Editor.Ada_Type_Graph.Type_Category;
   use type Editor.Ada_Type_Graph.Type_Id;
   use type Editor.Ada_Language_Model.Representation_Clause_Kind;
   use type Editor.Ada_Language_Model.Representation_Source_Form;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 131) + B + 989) mod 2_147_483_647;
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
      Type_Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
        (if Record_Type = Editor.Ada_Syntax_Tree.No_Node then
            (Id => Editor.Ada_Syntax_Tree.No_Node,
             Kind => Editor.Ada_Syntax_Tree.Node_Unknown,
             Source_Span => (1, 1, 1, 1),
             Parent => Editor.Ada_Syntax_Tree.No_Node,
             Depth => 0,
             Label => Null_Unbounded_String,
             Fingerprint => 0)
         else Editor.Ada_Syntax_Tree.Node (Tree, Record_Type));
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
              and then N.Source_Span.Start_Line >= Type_Node.Source_Span.Start_Line
              and then N.Source_Span.End_Line <= Type_Node.Source_Span.End_Line
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
      pragma Unreferenced (Item_Text);
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

   function Static_Value_Required
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean is
   begin
      return Kind in Editor.Ada_Language_Model.Representation_Size_Clause |
                     Editor.Ada_Language_Model.Representation_Alignment_Clause |
                     Editor.Ada_Language_Model.Representation_Component_Size_Clause |
                     Editor.Ada_Language_Model.Representation_Object_Size_Clause |
                     Editor.Ada_Language_Model.Representation_Value_Size_Clause |
                     Editor.Ada_Language_Model.Representation_Storage_Size_Clause |
                     Editor.Ada_Language_Model.Representation_Machine_Radix_Clause |
                     Editor.Ada_Language_Model.Representation_Aft_Clause |
                     Editor.Ada_Language_Model.Representation_Small_Clause;
   end Static_Value_Required;

   function Positive_Value_Required
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean is
   begin
      return Kind in Editor.Ada_Language_Model.Representation_Size_Clause |
                     Editor.Ada_Language_Model.Representation_Alignment_Clause |
                     Editor.Ada_Language_Model.Representation_Component_Size_Clause |
                     Editor.Ada_Language_Model.Representation_Object_Size_Clause |
                     Editor.Ada_Language_Model.Representation_Value_Size_Clause |
                     Editor.Ada_Language_Model.Representation_Storage_Size_Clause |
                     Editor.Ada_Language_Model.Representation_Machine_Radix_Clause |
                     Editor.Ada_Language_Model.Representation_Aft_Clause;
   end Positive_Value_Required;

   function Compatible_Target_Kind
     (Kind     : Editor.Ada_Language_Model.Representation_Clause_Kind;
      Category : Editor.Ada_Type_Graph.Type_Category) return Boolean is
   begin
      case Kind is
         when Editor.Ada_Language_Model.Representation_Record_Clause =>
            return Category = Editor.Ada_Type_Graph.Type_Category_Record
              or else Category = Editor.Ada_Type_Graph.Type_Category_Private
              or else Category = Editor.Ada_Type_Graph.Type_Category_Unknown;
         when Editor.Ada_Language_Model.Representation_Component_Size_Clause =>
            return Category = Editor.Ada_Type_Graph.Type_Category_Array
              or else Category = Editor.Ada_Type_Graph.Type_Category_Unknown;
         when Editor.Ada_Language_Model.Representation_Small_Clause |
              Editor.Ada_Language_Model.Representation_Aft_Clause =>
            return Category = Editor.Ada_Type_Graph.Type_Category_Fixed
              or else Category = Editor.Ada_Type_Graph.Type_Category_Unknown;
         when Editor.Ada_Language_Model.Representation_Machine_Radix_Clause =>
            return Category = Editor.Ada_Type_Graph.Type_Category_Floating
              or else Category = Editor.Ada_Type_Graph.Type_Category_Unknown;
         when others =>
            return True;
      end case;
   end Compatible_Target_Kind;

   function Compatible_Address_Target
     (Kind : Editor.Ada_Freezing_Points.Freezable_Kind) return Boolean is
   begin
      return Kind in Editor.Ada_Freezing_Points.Freezable_Object |
                     Editor.Ada_Freezing_Points.Freezable_Subprogram |
                     Editor.Ada_Freezing_Points.Freezable_Unknown;
   end Compatible_Address_Target;

   function Size_Target_Compatible
     (Freezable : Editor.Ada_Freezing_Points.Freezable_Kind) return Boolean is
   begin
      return Freezable in Editor.Ada_Freezing_Points.Freezable_Type |
                         Editor.Ada_Freezing_Points.Freezable_Subtype |
                         Editor.Ada_Freezing_Points.Freezable_Object |
                         Editor.Ada_Freezing_Points.Freezable_Unknown;
   end Size_Target_Compatible;

   function Alignment_Target_Compatible
     (Freezable : Editor.Ada_Freezing_Points.Freezable_Kind) return Boolean is
   begin
      return Freezable in Editor.Ada_Freezing_Points.Freezable_Type |
                         Editor.Ada_Freezing_Points.Freezable_Subtype |
                         Editor.Ada_Freezing_Points.Freezable_Object |
                         Editor.Ada_Freezing_Points.Freezable_Unknown;
   end Alignment_Target_Compatible;

   function Storage_Size_Target_Compatible
     (Freezable : Editor.Ada_Freezing_Points.Freezable_Kind;
      Category  : Editor.Ada_Type_Graph.Type_Category) return Boolean is
   begin
      if Freezable not in Editor.Ada_Freezing_Points.Freezable_Type |
                          Editor.Ada_Freezing_Points.Freezable_Subtype |
                          Editor.Ada_Freezing_Points.Freezable_Unknown
      then
         return False;
      end if;

      return Category in Editor.Ada_Type_Graph.Type_Category_Access |
                         Editor.Ada_Type_Graph.Type_Category_Private |
                         Editor.Ada_Type_Graph.Type_Category_Unknown;
   end Storage_Size_Target_Compatible;

   function Integer_Value_Required
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean is
   begin
      return Kind in Editor.Ada_Language_Model.Representation_Size_Clause |
                     Editor.Ada_Language_Model.Representation_Alignment_Clause |
                     Editor.Ada_Language_Model.Representation_Component_Size_Clause |
                     Editor.Ada_Language_Model.Representation_Object_Size_Clause |
                     Editor.Ada_Language_Model.Representation_Value_Size_Clause |
                     Editor.Ada_Language_Model.Representation_Storage_Size_Clause |
                     Editor.Ada_Language_Model.Representation_Machine_Radix_Clause |
                     Editor.Ada_Language_Model.Representation_Aft_Clause;
   end Integer_Value_Required;

   function Interfacing_Clause
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean is
   begin
      return Kind in Editor.Ada_Language_Model.Representation_Convention_Clause |
                     Editor.Ada_Language_Model.Representation_Import_Clause |
                     Editor.Ada_Language_Model.Representation_Export_Clause |
                     Editor.Ada_Language_Model.Representation_External_Name_Clause |
                     Editor.Ada_Language_Model.Representation_Link_Name_Clause;
   end Interfacing_Clause;


   function Stream_Attribute_Clause
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean is
   begin
      return Kind in Editor.Ada_Language_Model.Representation_Read_Clause |
                     Editor.Ada_Language_Model.Representation_Write_Clause |
                     Editor.Ada_Language_Model.Representation_Input_Clause |
                     Editor.Ada_Language_Model.Representation_Output_Clause |
                     Editor.Ada_Language_Model.Representation_Put_Image_Clause;
   end Stream_Attribute_Clause;

   function Stream_Target_Compatible
     (Freezable : Editor.Ada_Freezing_Points.Freezable_Kind) return Boolean is
   begin
      return Freezable in Editor.Ada_Freezing_Points.Freezable_Type |
                         Editor.Ada_Freezing_Points.Freezable_Subtype |
                         Editor.Ada_Freezing_Points.Freezable_Unknown;
   end Stream_Target_Compatible;

   function Boolean_Operational_Clause
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean is
   begin
      return Kind in Editor.Ada_Language_Model.Representation_Pack_Clause |
                     Editor.Ada_Language_Model.Representation_Atomic_Clause |
                     Editor.Ada_Language_Model.Representation_Volatile_Clause |
                     Editor.Ada_Language_Model.Representation_Independent_Clause |
                     Editor.Ada_Language_Model.Representation_Atomic_Components_Clause |
                     Editor.Ada_Language_Model.Representation_Volatile_Components_Clause |
                     Editor.Ada_Language_Model.Representation_Independent_Components_Clause |
                     Editor.Ada_Language_Model.Representation_Suppress_Initialization_Clause;
   end Boolean_Operational_Clause;

   function Order_Operational_Clause
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean is
   begin
      return Kind in Editor.Ada_Language_Model.Representation_Bit_Order_Clause |
                     Editor.Ada_Language_Model.Representation_Scalar_Storage_Order_Clause |
                     Editor.Ada_Language_Model.Representation_Default_Scalar_Storage_Order_Clause;
   end Order_Operational_Clause;

   function Operational_Clause
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean is
   begin
      return Boolean_Operational_Clause (Kind) or else Order_Operational_Clause (Kind);
   end Operational_Clause;

   function Operational_Target_Compatible
     (Kind      : Editor.Ada_Language_Model.Representation_Clause_Kind;
      Freezable : Editor.Ada_Freezing_Points.Freezable_Kind;
      Category  : Editor.Ada_Type_Graph.Type_Category) return Boolean is
   begin
      case Kind is
         when Editor.Ada_Language_Model.Representation_Pack_Clause =>
            return Freezable in Editor.Ada_Freezing_Points.Freezable_Type |
                               Editor.Ada_Freezing_Points.Freezable_Subtype |
                               Editor.Ada_Freezing_Points.Freezable_Unknown
              and then Category in Editor.Ada_Type_Graph.Type_Category_Record |
                                   Editor.Ada_Type_Graph.Type_Category_Array |
                                   Editor.Ada_Type_Graph.Type_Category_Private |
                                   Editor.Ada_Type_Graph.Type_Category_Unknown;
         when Editor.Ada_Language_Model.Representation_Atomic_Components_Clause |
              Editor.Ada_Language_Model.Representation_Volatile_Components_Clause |
              Editor.Ada_Language_Model.Representation_Independent_Components_Clause =>
            return Freezable in Editor.Ada_Freezing_Points.Freezable_Type |
                               Editor.Ada_Freezing_Points.Freezable_Subtype |
                               Editor.Ada_Freezing_Points.Freezable_Unknown
              and then Category in Editor.Ada_Type_Graph.Type_Category_Array |
                                   Editor.Ada_Type_Graph.Type_Category_Private |
                                   Editor.Ada_Type_Graph.Type_Category_Unknown;
         when Editor.Ada_Language_Model.Representation_Atomic_Clause |
              Editor.Ada_Language_Model.Representation_Volatile_Clause |
              Editor.Ada_Language_Model.Representation_Independent_Clause |
              Editor.Ada_Language_Model.Representation_Suppress_Initialization_Clause =>
            return Freezable in Editor.Ada_Freezing_Points.Freezable_Type |
                               Editor.Ada_Freezing_Points.Freezable_Subtype |
                               Editor.Ada_Freezing_Points.Freezable_Object |
                               Editor.Ada_Freezing_Points.Freezable_Unknown;
         when Editor.Ada_Language_Model.Representation_Bit_Order_Clause =>
            return Freezable in Editor.Ada_Freezing_Points.Freezable_Type |
                               Editor.Ada_Freezing_Points.Freezable_Subtype |
                               Editor.Ada_Freezing_Points.Freezable_Unknown
              and then Category in Editor.Ada_Type_Graph.Type_Category_Record |
                                   Editor.Ada_Type_Graph.Type_Category_Private |
                                   Editor.Ada_Type_Graph.Type_Category_Unknown;
         when Editor.Ada_Language_Model.Representation_Scalar_Storage_Order_Clause |
              Editor.Ada_Language_Model.Representation_Default_Scalar_Storage_Order_Clause =>
            return Freezable in Editor.Ada_Freezing_Points.Freezable_Type |
                               Editor.Ada_Freezing_Points.Freezable_Subtype |
                               Editor.Ada_Freezing_Points.Freezable_Unknown
              and then Category in Editor.Ada_Type_Graph.Type_Category_Record |
                                   Editor.Ada_Type_Graph.Type_Category_Array |
                                   Editor.Ada_Type_Graph.Type_Category_Private |
                                   Editor.Ada_Type_Graph.Type_Category_Unknown;
         when others =>
            return True;
      end case;
   end Operational_Target_Compatible;

   function Interfacing_Target_Compatible
     (Kind      : Editor.Ada_Language_Model.Representation_Clause_Kind;
      Freezable : Editor.Ada_Freezing_Points.Freezable_Kind) return Boolean is
   begin
      case Kind is
         when Editor.Ada_Language_Model.Representation_Convention_Clause =>
            return Freezable in Editor.Ada_Freezing_Points.Freezable_Type |
                               Editor.Ada_Freezing_Points.Freezable_Subtype |
                               Editor.Ada_Freezing_Points.Freezable_Subprogram |
                               Editor.Ada_Freezing_Points.Freezable_Object |
                               Editor.Ada_Freezing_Points.Freezable_Unknown;
         when Editor.Ada_Language_Model.Representation_Import_Clause |
              Editor.Ada_Language_Model.Representation_Export_Clause =>
            return Freezable in Editor.Ada_Freezing_Points.Freezable_Subprogram |
                               Editor.Ada_Freezing_Points.Freezable_Object |
                               Editor.Ada_Freezing_Points.Freezable_Unknown;
         when Editor.Ada_Language_Model.Representation_External_Name_Clause |
              Editor.Ada_Language_Model.Representation_Link_Name_Clause =>
            return Freezable in Editor.Ada_Freezing_Points.Freezable_Subprogram |
                               Editor.Ada_Freezing_Points.Freezable_Object |
                               Editor.Ada_Freezing_Points.Freezable_Unknown;
         when others =>
            return True;
      end case;
   end Interfacing_Target_Compatible;

   function Is_Known_Convention (Name : String) return Boolean is
      N : constant String := Lower (Name);
   begin
      return N = "ada" or else N = "intrinsic" or else N = "c"
        or else N = "c_pass_by_copy" or else N = "cobol"
        or else N = "fortran" or else N = "assembler"
        or else N = "stdcall" or else N = "win32" or else N = "cpp";
   end Is_Known_Convention;

   function Is_Identifier_Text (Text : String) return Boolean is
      T : constant String := Trimmed (Text);
   begin
      if T = "" then
         return False;
      end if;
      if not (T (T'First) in 'A' .. 'Z' or else T (T'First) in 'a' .. 'z') then
         return False;
      end if;
      for I in T'First + 1 .. T'Last loop
         if not (T (I) in 'A' .. 'Z' or else T (I) in 'a' .. 'z'
                 or else T (I) in '0' .. '9' or else T (I) = '_') then
            return False;
         end if;
      end loop;
      return True;
   end Is_Identifier_Text;

   function Is_Static_String_Text (Text : String) return Boolean is
      T : constant String := Trimmed (Text);
   begin
      return T'Length >= 2 and then T (T'First) = '"' and then T (T'Last) = '"';
   end Is_Static_String_Text;

   function Is_Static_Boolean_True (Text : String) return Boolean is
      T : constant String := Lower (Text);
   begin
      return T = "true" or else T = "standard.true";
   end Is_Static_Boolean_True;

   function Is_Static_Boolean_False (Text : String) return Boolean is
      T : constant String := Lower (Text);
   begin
      return T = "false" or else T = "standard.false";
   end Is_Static_Boolean_False;

   function Is_High_Order_First (Text : String) return Boolean is
      T : constant String := Lower (Text);
   begin
      return T = "high_order_first" or else T = "system.high_order_first";
   end Is_High_Order_First;

   function Is_Low_Order_First (Text : String) return Boolean is
      T : constant String := Lower (Text);
   begin
      return T = "low_order_first" or else T = "system.low_order_first";
   end Is_Low_Order_First;

   function Operational_Value_Status_For
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind;
      Text : String) return Operational_Value_Status is
      T : constant String := Trimmed (Text);
   begin
      if not Operational_Clause (Kind) then
         return Operational_Value_Not_Operational_Clause;
      elsif T = "" then
         return Operational_Value_Malformed;
      elsif Boolean_Operational_Clause (Kind) then
         if Is_Static_Boolean_True (T) then
            return Operational_Value_Static_Boolean_True;
         elsif Is_Static_Boolean_False (T) then
            return Operational_Value_Static_Boolean_False;
         else
            return Operational_Value_Malformed;
         end if;
      elsif Order_Operational_Clause (Kind) then
         if Is_High_Order_First (T) then
            return Operational_Value_Order_High_Order_First;
         elsif Is_Low_Order_First (T) then
            return Operational_Value_Order_Low_Order_First;
         else
            return Operational_Value_Malformed;
         end if;
      else
         return Operational_Value_Not_Operational_Clause;
      end if;
   end Operational_Value_Status_For;

   function Interfacing_Value_Status_For
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind;
      Text : String) return Interfacing_Value_Status is
      T : constant String := Trimmed (Text);
   begin
      if not Interfacing_Clause (Kind) then
         return Interfacing_Value_Not_Interfacing_Clause;
      elsif T = "" then
         return Interfacing_Value_Malformed;
      end if;

      case Kind is
         when Editor.Ada_Language_Model.Representation_Convention_Clause =>
            if not Is_Identifier_Text (T) then
               return Interfacing_Value_Malformed;
            elsif Is_Known_Convention (T) then
               return Interfacing_Value_Convention_Identifier;
            else
               return Interfacing_Value_Convention_Unknown_Identifier;
            end if;
         when Editor.Ada_Language_Model.Representation_Import_Clause |
              Editor.Ada_Language_Model.Representation_Export_Clause =>
            if Is_Static_Boolean_True (T) then
               return Interfacing_Value_Static_Boolean_True;
            elsif Is_Static_Boolean_False (T) then
               return Interfacing_Value_Static_Boolean_False;
            else
               return Interfacing_Value_Malformed;
            end if;
         when Editor.Ada_Language_Model.Representation_External_Name_Clause |
              Editor.Ada_Language_Model.Representation_Link_Name_Clause =>
            if Is_Static_String_Text (T) then
               return Interfacing_Value_Static_String;
            else
               return Interfacing_Value_Malformed;
            end if;
         when others =>
            return Interfacing_Value_Not_Interfacing_Clause;
      end case;
   end Interfacing_Value_Status_For;


   function Starts_With_Digit_Or_Sign (Text : String) return Boolean;

   function Stream_Subprogram_Status_For
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind;
      Text : String) return Stream_Subprogram_Status is
      T : constant String := Trimmed (Text);
      L : constant String := Lower (T);
   begin
      if not Stream_Attribute_Clause (Kind) then
         return Stream_Subprogram_Not_Stream_Clause;
      elsif T = "" then
         return Stream_Subprogram_Malformed;
      elsif Is_Static_String_Text (T) or else Starts_With_Digit_Or_Sign (T)
        or else L = "null" or else L = "true" or else L = "false"
      then
         return Stream_Subprogram_Malformed;
      elsif Ada.Strings.Fixed.Index (L, "(") /= 0
        or else Ada.Strings.Fixed.Index (L, ";") /= 0
      then
         return Stream_Subprogram_Malformed;
      elsif Is_Identifier_Text (T)
        or else Ada.Strings.Fixed.Index (T, ".") /= 0
      then
         --  The parser-level model can prove that the representation item is
         --  a callable designator.  Full profile matching is layered through
         --  subsequent call/profile metadata and is therefore preserved as
         --  unknown rather than silently accepted as profile-conformant.
         return Stream_Subprogram_Profile_Unknown;
      else
         return Stream_Subprogram_Unknown;
      end if;
   end Stream_Subprogram_Status_For;

   function Starts_With_Digit_Or_Sign (Text : String) return Boolean is
      T : constant String := Trimmed (Text);
   begin
      if T = "" then
         return False;
      end if;

      return T (T'First) in '0' .. '9'
        or else T (T'First) = '+'
        or else T (T'First) = '-';
   end Starts_With_Digit_Or_Sign;


   function Deepest_Region_Containing_Line
     (Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Line    : Positive) return Editor.Ada_Declarative_Regions.Region_Id;

   function Aspect_Representation_Name (Name : String) return Boolean is
      N : constant String := Lower (Name);
   begin
      return N = "size" or else N = "alignment" or else N = "component_size"
        or else N = "object_size" or else N = "value_size"
        or else N = "storage_size" or else N = "small"
        or else N = "machine_radix" or else N = "aft"
        or else N = "bit_order" or else N = "scalar_storage_order"
        or else N = "default_scalar_storage_order" or else N = "pack"
        or else N = "atomic" or else N = "volatile"
        or else N = "independent" or else N = "atomic_components"
        or else N = "volatile_components"
        or else N = "independent_components"
        or else N = "suppress_initialization" or else N = "address"
        or else N = "convention" or else N = "import" or else N = "export"
        or else N = "external_name" or else N = "link_name"
        or else N = "read" or else N = "write" or else N = "input"
        or else N = "output" or else N = "put_image";
   end Aspect_Representation_Name;

   function Aspect_Default_Value (Name, Value : String) return String is
      N : constant String := Lower (Name);
      V : constant String := Trimmed (Value);
   begin
      if V /= "" then
         return V;
      elsif N = "pack" or else N = "atomic" or else N = "volatile"
        or else N = "independent" or else N = "atomic_components"
        or else N = "volatile_components"
        or else N = "independent_components"
        or else N = "suppress_initialization" or else N = "import"
        or else N = "export"
      then
         return "True";
      else
         return V;
      end if;
   end Aspect_Default_Value;

   function Ancestor_Declaration_Target
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return String is
      Cur : Editor.Ada_Syntax_Tree.Node_Id := Node;
   begin
      while Cur /= Editor.Ada_Syntax_Tree.No_Node loop
         declare
            N : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node (Tree, Cur);
            Name : constant String := Declaration_Name (Tree, Cur);
         begin
            if Name /= "" then
               return Name;
            end if;
            Cur := N.Parent;
         end;
      end loop;
      return "";
   end Ancestor_Declaration_Target;

   function Freeze_Info_For_Target_At
     (Freezing : Editor.Ada_Freezing_Points.Freezing_Model;
      Regions  : Editor.Ada_Declarative_Regions.Region_Model;
      Line     : Positive;
      Target   : String) return Editor.Ada_Freezing_Points.Representation_Freeze_Info is
      Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Deepest_Region_Containing_Line (Regions, Line);
      Id : constant Editor.Ada_Freezing_Points.Freezable_Id :=
        Editor.Ada_Freezing_Points.Lookup_Freezable (Freezing, Region, Target);
      Result : Editor.Ada_Freezing_Points.Representation_Freeze_Info;
   begin
      Result.Clause_Line := Line;
      Result.Target_Name := To_Unbounded_String (Trimmed (Target));
      Result.Normalized_Target := To_Unbounded_String (Normalized (Target));
      Result.Target := Id;

      if Id = Editor.Ada_Freezing_Points.No_Freezable then
         Result.Status := Editor.Ada_Freezing_Points.Representation_Target_Unresolved;
      else
         declare
            F : constant Editor.Ada_Freezing_Points.Freezable_Info :=
              Editor.Ada_Freezing_Points.Freezable_Node (Freezing, Id);
         begin
            Result.Freeze_Line := F.First_Freeze_Line;
            if F.Status = Editor.Ada_Freezing_Points.Freezing_Not_Frozen then
               Result.Status := Editor.Ada_Freezing_Points.Representation_Target_Not_Frozen;
            elsif Line < F.First_Freeze_Line then
               Result.Status := Editor.Ada_Freezing_Points.Representation_Before_Freezing;
            elsif Line = F.First_Freeze_Line then
               Result.Status := Editor.Ada_Freezing_Points.Representation_At_Freezing_Point;
            else
               Result.Status := Editor.Ada_Freezing_Points.Representation_After_Freezing;
            end if;
         end;
      end if;

      Result.Fingerprint :=
        Mix (Natural (Id), Mix (Line, Editor.Ada_Freezing_Points.Representation_Freezing_Status'Pos (Result.Status)));
      return Result;
   end Freeze_Info_For_Target_At;

   function Address_Value_Status_For (Text : String) return Address_Value_Status is
      T : constant String := Trimmed (Strip_Leading_At (Text));
      L : constant String := Lower (T);
   begin
      if T = "" then
         return Address_Value_Malformed;
      elsif L = "null" then
         return Address_Value_Null_Literal;
      elsif Ada.Strings.Fixed.Index (L, "'address") /= 0
        or else Ada.Strings.Fixed.Index (L, "to_address") /= 0
      then
         return Address_Value_Static_Address;
      elsif Starts_With_Digit_Or_Sign (T) then
         return Address_Value_Raw_Literal;
      else
         return Address_Value_Non_Static_Name;
      end if;
   end Address_Value_Status_For;

   function Value_Status_For
     (Value : Editor.Ada_Static_Expressions.Static_Value_Info) return Representation_Value_Status is
   begin
      case Value.Status is
         when Editor.Ada_Static_Expressions.Static_Value_Integer |
              Editor.Ada_Static_Expressions.Static_Value_Static_Attribute |
              Editor.Ada_Static_Expressions.Static_Value_Modular_Integer =>
            return Representation_Value_Static_Integer;
         when Editor.Ada_Static_Expressions.Static_Value_Real |
              Editor.Ada_Static_Expressions.Static_Value_Fixed_Point =>
            return Representation_Value_Static_Real;
         when Editor.Ada_Static_Expressions.Static_Value_Division_By_Zero =>
            return Representation_Value_Division_By_Zero;
         when Editor.Ada_Static_Expressions.Static_Value_Malformed =>
            return Representation_Value_Malformed;
         when Editor.Ada_Static_Expressions.Static_Value_Unresolved_Name =>
            return Representation_Value_Unresolved;
         when Editor.Ada_Static_Expressions.Static_Value_Unsupported_Attribute =>
            return Representation_Value_Unsupported;
         when others =>
            return Representation_Value_Non_Static;
      end case;
   end Value_Status_For;

   function Type_Category_For_Target
     (Types   : Editor.Ada_Type_Graph.Type_Model;
      Target  : Editor.Ada_Freezing_Points.Freezable_Info)
      return Editor.Ada_Type_Graph.Type_Category is
   begin
      if Target.Type_Node = Editor.Ada_Type_Graph.No_Type then
         return Editor.Ada_Type_Graph.Type_Category_Unknown;
      end if;

      return Editor.Ada_Type_Graph.Type_Node (Types, Target.Type_Node).Category;
   end Type_Category_For_Target;

   procedure Classify
     (Info : in out Representation_Legality_Info;
      Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) is
   begin
      if Info.Freeze_Status = Editor.Ada_Freezing_Points.Representation_Target_Unresolved then
         Info.Status := Representation_Legality_Target_Unresolved;
      elsif Info.Freeze_Status = Editor.Ada_Freezing_Points.Representation_Target_Ambiguous then
         Info.Status := Representation_Legality_Target_Ambiguous;
      elsif Info.Freeze_Status = Editor.Ada_Freezing_Points.Representation_Target_Not_Freezable then
         Info.Status := Representation_Legality_Target_Not_Freezable;
      elsif Info.Freeze_Status = Editor.Ada_Freezing_Points.Representation_After_Freezing then
         Info.Status := Representation_Legality_After_Freezing;
      elsif Info.Freeze_Status = Editor.Ada_Freezing_Points.Representation_At_Freezing_Point then
         Info.Status := Representation_Legality_At_Freezing_Point;
      elsif Operational_Clause (Kind)
        and then not Operational_Target_Compatible
          (Kind, Info.Target_Freezable_Kind, Info.Target_Category)
      then
         Info.Status := Representation_Legality_Operational_Target_Incompatible;
      elsif Boolean_Operational_Clause (Kind)
        and then Info.Operational_Status not in Operational_Value_Static_Boolean_True |
                                            Operational_Value_Static_Boolean_False
      then
         Info.Status := Representation_Legality_Operational_Boolean_Value_Required;
      elsif Order_Operational_Clause (Kind)
        and then Info.Operational_Status not in Operational_Value_Order_High_Order_First |
                                            Operational_Value_Order_Low_Order_First
      then
         Info.Status := Representation_Legality_Operational_Order_Value_Required;
      elsif Interfacing_Clause (Kind)
        and then not Interfacing_Target_Compatible (Kind, Info.Target_Freezable_Kind)
      then
         Info.Status := Representation_Legality_Interfacing_Target_Incompatible;
      elsif Kind = Editor.Ada_Language_Model.Representation_Convention_Clause
        and then Info.Interfacing_Status = Interfacing_Value_Malformed
      then
         Info.Status := Representation_Legality_Convention_Identifier_Required;
      elsif Kind = Editor.Ada_Language_Model.Representation_Convention_Clause
        and then Info.Interfacing_Status = Interfacing_Value_Convention_Unknown_Identifier
      then
         Info.Status := Representation_Legality_Convention_Identifier_Unknown;
      elsif Kind in Editor.Ada_Language_Model.Representation_Import_Clause |
                    Editor.Ada_Language_Model.Representation_Export_Clause
        and then Info.Interfacing_Status = Interfacing_Value_Malformed
      then
         Info.Status := Representation_Legality_Import_Export_Boolean_Value_Required;
      elsif Kind in Editor.Ada_Language_Model.Representation_External_Name_Clause |
                    Editor.Ada_Language_Model.Representation_Link_Name_Clause
        and then Info.Interfacing_Status = Interfacing_Value_Malformed
      then
         Info.Status := Representation_Legality_Link_Name_String_Value_Required;
      elsif Stream_Attribute_Clause (Kind)
        and then not Stream_Target_Compatible (Info.Target_Freezable_Kind)
      then
         Info.Status := Representation_Legality_Stream_Target_Incompatible;
      elsif Stream_Attribute_Clause (Kind)
        and then Info.Stream_Status in Stream_Subprogram_Malformed |
                                   Stream_Subprogram_Unknown
      then
         Info.Status := Representation_Legality_Stream_Subprogram_Malformed;
      elsif Stream_Attribute_Clause (Kind)
        and then Info.Stream_Status = Stream_Subprogram_Profile_Unknown
      then
         Info.Status := Representation_Legality_Stream_Subprogram_Profile_Unknown;
      elsif Stream_Attribute_Clause (Kind)
        and then Info.Stream_Status = Stream_Subprogram_Profile_Known_Mismatch
      then
         Info.Status := Representation_Legality_Stream_Subprogram_Profile_Mismatch;
      elsif Kind = Editor.Ada_Language_Model.Representation_Address_Clause
        and then not Compatible_Address_Target (Info.Target_Freezable_Kind)
      then
         Info.Status := Representation_Legality_Address_Target_Incompatible;
      elsif Kind = Editor.Ada_Language_Model.Representation_Address_Clause
        and then Info.Address_Status = Address_Value_Null_Literal
      then
         Info.Status := Representation_Legality_Address_Value_Null_Not_Allowed;
      elsif Kind = Editor.Ada_Language_Model.Representation_Address_Clause
        and then Info.Address_Status in Address_Value_Non_Static_Name |
                                        Address_Value_Unknown
      then
         Info.Status := Representation_Legality_Address_Value_Not_Static_Address;
      elsif Kind = Editor.Ada_Language_Model.Representation_Address_Clause
        and then Info.Address_Status = Address_Value_Raw_Literal
      then
         Info.Status := Representation_Legality_Address_Value_Incompatible;
      elsif Kind = Editor.Ada_Language_Model.Representation_Address_Clause
        and then Info.Address_Status = Address_Value_Malformed
      then
         Info.Status := Representation_Legality_Address_Value_Malformed;
      elsif Kind in Editor.Ada_Language_Model.Representation_Size_Clause |
                    Editor.Ada_Language_Model.Representation_Object_Size_Clause |
                    Editor.Ada_Language_Model.Representation_Value_Size_Clause
        and then not Size_Target_Compatible (Info.Target_Freezable_Kind)
      then
         Info.Status := Representation_Legality_Size_Target_Incompatible;
      elsif Kind = Editor.Ada_Language_Model.Representation_Alignment_Clause
        and then not Alignment_Target_Compatible (Info.Target_Freezable_Kind)
      then
         Info.Status := Representation_Legality_Alignment_Target_Incompatible;
      elsif Kind = Editor.Ada_Language_Model.Representation_Storage_Size_Clause
        and then not Storage_Size_Target_Compatible
          (Info.Target_Freezable_Kind, Info.Target_Category)
      then
         Info.Status := Representation_Legality_Storage_Size_Target_Incompatible;
      elsif not Compatible_Target_Kind (Kind, Info.Target_Category) then
         Info.Status := Representation_Legality_Target_Kind_Mismatch;
      elsif Static_Value_Required (Kind)
        and then Info.Value_Status not in Representation_Value_Static_Integer |
                                      Representation_Value_Static_Real
      then
         case Info.Value_Status is
            when Representation_Value_Malformed =>
               Info.Status := Representation_Legality_Static_Value_Malformed;
            when Representation_Value_Division_By_Zero =>
               Info.Status := Representation_Legality_Static_Value_Division_By_Zero;
            when others =>
               Info.Status := Representation_Legality_Static_Value_Required;
         end case;
      elsif Integer_Value_Required (Kind)
        and then Info.Value_Status = Representation_Value_Static_Real
      then
         Info.Status := Representation_Legality_Static_Value_Not_Integer;
      elsif Positive_Value_Required (Kind)
        and then Info.Value_Status = Representation_Value_Static_Integer
        and then Info.Static_Integer <= 0
      then
         Info.Status := Representation_Legality_Static_Value_Not_Positive;
      else
         Info.Status := Representation_Legality_Ok;
      end if;
   end Classify;

   procedure Clear (Model : in out Representation_Legality_Model) is
   begin
      Model.Checks.Clear;
      Model.Component_Checks.Clear;
      Model.Enumeration_Checks.Clear;
      Model.Ok_Total := 0;
      Model.Error_Total := 0;
      Model.Static_Error_Total := 0;
      Model.Kind_Error_Total := 0;
      Model.Freeze_Error_Total := 0;
      Model.Component_Error_Total := 0;
      Model.Component_Duplicate_Total := 0;
      Model.Component_Static_Error_Total := 0;
      Model.Enumeration_Error_Total := 0;
      Model.Enumeration_Duplicate_Literal_Total := 0;
      Model.Enumeration_Duplicate_Value_Total := 0;
      Model.Enumeration_Static_Error_Total := 0;
      Model.Enumeration_Incomplete_Total := 0;
      Model.Address_Target_Error_Total := 0;
      Model.Address_Value_Error_Total := 0;
      Model.Address_Static_Value_Total := 0;
      Model.Size_Alignment_Storage_Error_Total := 0;
      Model.Size_Alignment_Storage_Static_Error_Total := 0;
      Model.Interfacing_Error_Total := 0;
      Model.Interfacing_Target_Error_Total := 0;
      Model.Interfacing_Value_Error_Total := 0;
      Model.Import_Export_Conflict_Total := 0;
      Model.Link_Name_Requires_Import_Export_Total := 0;
      Model.Stream_Error_Total := 0;
      Model.Stream_Target_Error_Total := 0;
      Model.Stream_Profile_Error_Total := 0;
      Model.Stream_Profile_Unknown_Total := 0;
      Model.Operational_Error_Total := 0;
      Model.Operational_Target_Error_Total := 0;
      Model.Operational_Value_Error_Total := 0;
      Model.Operational_Static_Boolean_Total := 0;
      Model.Operational_Order_Value_Total := 0;
      Model.Aspect_Source_Total := 0;
      Model.Attribute_Definition_Source_Total := 0;
      Model.Unified_Property_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;



   function Is_Enumeration_Type_Node
     (Tree      : Editor.Ada_Syntax_Tree.Tree_Type;
      Type_Node : Editor.Ada_Syntax_Tree.Node_Id) return Boolean is
   begin
      if Type_Node = Editor.Ada_Syntax_Tree.No_Node then
         return False;
      end if;

      for Index in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Type_Node) loop
         declare
            Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node
                (Tree, Editor.Ada_Syntax_Tree.Child_At (Tree, Type_Node, Index));
         begin
            if Child.Kind = Editor.Ada_Syntax_Tree.Node_Enumeration_Literal_Declaration then
               return True;
            end if;
         end;
      end loop;

      declare
         Def : constant String :=
           Trimmed (Child_Label (Tree, Type_Node, Editor.Ada_Syntax_Tree.Node_Declaration_Subtype));
      begin
         return Def'Length >= 2
           and then Def (Def'First) = '('
           and then Def (Def'Last) = ')';
      end;
   end Is_Enumeration_Type_Node;

   function Enumeration_Literal_Count
     (Tree      : Editor.Ada_Syntax_Tree.Tree_Type;
      Type_Node : Editor.Ada_Syntax_Tree.Node_Id) return Natural is
      Count : Natural := 0;
   begin
      if Type_Node = Editor.Ada_Syntax_Tree.No_Node then
         return 0;
      end if;

      for Index in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Type_Node) loop
         declare
            Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node
                (Tree, Editor.Ada_Syntax_Tree.Child_At (Tree, Type_Node, Index));
         begin
            if Child.Kind = Editor.Ada_Syntax_Tree.Node_Enumeration_Literal_Declaration then
               Count := Count + 1;
            end if;
         end;
      end loop;
      return Count;
   end Enumeration_Literal_Count;

   function Enumeration_Literal_Name_At
     (Tree      : Editor.Ada_Syntax_Tree.Tree_Type;
      Type_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Position  : Positive) return String is
      Count : Natural := 0;
   begin
      if Type_Node = Editor.Ada_Syntax_Tree.No_Node then
         return "";
      end if;

      for Index in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Type_Node) loop
         declare
            Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node
                (Tree, Editor.Ada_Syntax_Tree.Child_At (Tree, Type_Node, Index));
         begin
            if Child.Kind = Editor.Ada_Syntax_Tree.Node_Enumeration_Literal_Declaration then
               Count := Count + 1;
               if Count = Position then
                  return Child_Label
                    (Tree, Child.Id, Editor.Ada_Syntax_Tree.Node_Declaration_Name);
               end if;
            end if;
         end;
      end loop;
      return "";
   end Enumeration_Literal_Name_At;

   function Enumeration_Literal_Exists
     (Tree      : Editor.Ada_Syntax_Tree.Tree_Type;
      Type_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Name      : String) return Boolean is
      N : constant String := Lower (Name);
   begin
      if Type_Node = Editor.Ada_Syntax_Tree.No_Node or else N = "" then
         return False;
      end if;

      for Index in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Type_Node) loop
         declare
            Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node
                (Tree, Editor.Ada_Syntax_Tree.Child_At (Tree, Type_Node, Index));
         begin
            if Child.Kind = Editor.Ada_Syntax_Tree.Node_Enumeration_Literal_Declaration
              and then Lower (Child_Label (Tree, Child.Id, Editor.Ada_Syntax_Tree.Node_Declaration_Name)) = N
            then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Enumeration_Literal_Exists;

   function Enumeration_Literal_Position
     (Tree      : Editor.Ada_Syntax_Tree.Tree_Type;
      Type_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Name      : String) return Natural is
      N : constant String := Lower (Name);
      Count : Natural := 0;
   begin
      if Type_Node = Editor.Ada_Syntax_Tree.No_Node or else N = "" then
         return 0;
      end if;

      for Index in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Type_Node) loop
         declare
            Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node
                (Tree, Editor.Ada_Syntax_Tree.Child_At (Tree, Type_Node, Index));
         begin
            if Child.Kind = Editor.Ada_Syntax_Tree.Node_Enumeration_Literal_Declaration then
               Count := Count + 1;
               if Lower (Child_Label (Tree, Child.Id, Editor.Ada_Syntax_Tree.Node_Declaration_Name)) = N then
                  return Count;
               end if;
            end if;
         end;
      end loop;
      return 0;
   end Enumeration_Literal_Position;

   function Enumeration_Literal_Duplicate
     (Model         : Representation_Legality_Model;
      Parent_Clause : Editor.Ada_Syntax_Tree.Node_Id;
      Normalized_Name : String) return Boolean is
   begin
      for Index in 1 .. Natural (Model.Enumeration_Checks.Length) loop
         declare
            Prior : constant Enumeration_Representation_Legality_Info :=
              Model.Enumeration_Checks (Index);
         begin
            if Prior.Parent_Clause = Parent_Clause
              and then To_String (Prior.Normalized_Literal) = Normalized_Name
            then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Enumeration_Literal_Duplicate;

   function Enumeration_Value_Duplicate
     (Model         : Representation_Legality_Model;
      Parent_Clause : Editor.Ada_Syntax_Tree.Node_Id;
      Static_Value  : Long_Long_Integer) return Boolean is
   begin
      for Index in 1 .. Natural (Model.Enumeration_Checks.Length) loop
         declare
            Prior : constant Enumeration_Representation_Legality_Info :=
              Model.Enumeration_Checks (Index);
         begin
            if Prior.Parent_Clause = Parent_Clause
              and then Prior.Value_Status = Representation_Value_Static_Integer
              and then Prior.Static_Value = Static_Value
            then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Enumeration_Value_Duplicate;

   procedure Count_Enumeration_Result
     (Model : in out Representation_Legality_Model;
      Info  : Enumeration_Representation_Legality_Info) is
   begin
      if Info.Status /= Representation_Legality_Ok then
         Model.Enumeration_Error_Total := Model.Enumeration_Error_Total + 1;
         if Info.Status = Representation_Legality_Enumeration_Literal_Duplicate then
            Model.Enumeration_Duplicate_Literal_Total :=
              Model.Enumeration_Duplicate_Literal_Total + 1;
         elsif Info.Status = Representation_Legality_Enumeration_Value_Duplicate then
            Model.Enumeration_Duplicate_Value_Total :=
              Model.Enumeration_Duplicate_Value_Total + 1;
         elsif Info.Status = Representation_Legality_Enumeration_Value_Static_Required then
            Model.Enumeration_Static_Error_Total :=
              Model.Enumeration_Static_Error_Total + 1;
         elsif Info.Status = Representation_Legality_Enumeration_Incomplete then
            Model.Enumeration_Incomplete_Total := Model.Enumeration_Incomplete_Total + 1;
         end if;
      end if;
   end Count_Enumeration_Result;

   procedure Add_Enumeration_Check
     (Model           : in out Representation_Legality_Model;
      Tree            : Editor.Ada_Syntax_Tree.Tree_Type;
      Static          : Editor.Ada_Static_Expressions.Static_Model;
      Parent_Info     : Representation_Legality_Info;
      Association     : Editor.Ada_Syntax_Tree.Node_Info;
      Literal_Name    : String;
      Value_Text      : String;
      Expected_Pos    : Natural;
      Target_Type_Node : Editor.Ada_Syntax_Tree.Node_Id) is
      Value : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
        Editor.Ada_Static_Expressions.Evaluate_Numeric_Expression
          (Static, Editor.Ada_Declarative_Regions.No_Region, Value_Text);
      Info : Enumeration_Representation_Legality_Info;
      Literal_Pos : Natural := 0;
   begin
      Info.Clause_Node := Association.Id;
      Info.Parent_Clause := Parent_Info.Clause_Node;
      Info.Target_Name := Parent_Info.Target_Name;
      Info.Literal_Name := To_Unbounded_String (Trimmed (Literal_Name));
      Info.Normalized_Literal := To_Unbounded_String (Lower (Literal_Name));
      Info.Value_Text := To_Unbounded_String (Trimmed (Value_Text));
      Info.Value_Status := Value_Status_For (Value);
      Info.Static_Value := Value.Integer_Value;
      Info.Expected_Position := Expected_Pos;
      Info.Source_Line := Association.Source_Span.Start_Line;

      if not Is_Enumeration_Type_Node (Tree, Target_Type_Node) then
         Info.Status := Representation_Legality_Enumeration_Target_Not_Enumeration;
      elsif not Enumeration_Literal_Exists (Tree, Target_Type_Node, Literal_Name) then
         Info.Status := Representation_Legality_Enumeration_Literal_Unresolved;
      elsif Enumeration_Literal_Duplicate
              (Model, Parent_Info.Clause_Node, To_String (Info.Normalized_Literal))
      then
         Info.Status := Representation_Legality_Enumeration_Literal_Duplicate;
      elsif Info.Value_Status /= Representation_Value_Static_Integer then
         Info.Status := Representation_Legality_Enumeration_Value_Static_Required;
      elsif Enumeration_Value_Duplicate (Model, Parent_Info.Clause_Node, Info.Static_Value) then
         Info.Status := Representation_Legality_Enumeration_Value_Duplicate;
      else
         Literal_Pos := Enumeration_Literal_Position (Tree, Target_Type_Node, Literal_Name);
         if Literal_Pos > 1 then
            for Index in 1 .. Natural (Model.Enumeration_Checks.Length) loop
               declare
                  Prior : constant Enumeration_Representation_Legality_Info :=
                    Model.Enumeration_Checks (Index);
               begin
                  if Prior.Parent_Clause = Parent_Info.Clause_Node
                    and then Prior.Value_Status = Representation_Value_Static_Integer
                    and then Prior.Expected_Position < Literal_Pos
                    and then Prior.Static_Value >= Info.Static_Value
                  then
                     Info.Status := Representation_Legality_Enumeration_Value_Order;
                     exit;
                  end if;
               end;
            end loop;
         end if;

         if Info.Status = Representation_Legality_Unknown then
            Info.Status := Representation_Legality_Ok;
         end if;
      end if;

      Info.Fingerprint :=
        Mix (Natural (Info.Clause_Node),
             Mix (Natural (Info.Parent_Clause),
                  Mix (Info.Source_Line,
                       Mix (Representation_Legality_Status'Pos (Info.Status),
                            Natural (abs Info.Static_Value mod 2_147_483_647)))));
      Model.Enumeration_Checks.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint);
      Count_Enumeration_Result (Model, Info);
   end Add_Enumeration_Check;

   procedure Add_Enumeration_Incomplete_Check
     (Model           : in out Representation_Legality_Model;
      Parent_Info     : Representation_Legality_Info;
      Missing_Literal  : String;
      Source_Line      : Positive) is
      Info : Enumeration_Representation_Legality_Info;
   begin
      Info.Parent_Clause := Parent_Info.Clause_Node;
      Info.Target_Name := Parent_Info.Target_Name;
      Info.Literal_Name := To_Unbounded_String (Missing_Literal);
      Info.Normalized_Literal := To_Unbounded_String (Lower (Missing_Literal));
      Info.Status := Representation_Legality_Enumeration_Incomplete;
      Info.Source_Line := Source_Line;
      Info.Fingerprint :=
        Mix (Natural (Info.Parent_Clause),
             Mix (Info.Source_Line,
                  Representation_Legality_Status'Pos (Info.Status)));
      Model.Enumeration_Checks.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint);
      Count_Enumeration_Result (Model, Info);
   end Add_Enumeration_Incomplete_Check;

   procedure Add_Enumeration_Representation_Checks
     (Model    : in out Representation_Legality_Model;
      Tree     : Editor.Ada_Syntax_Tree.Tree_Type;
      Types    : Editor.Ada_Type_Graph.Type_Model;
      Static   : Editor.Ada_Static_Expressions.Static_Model;
      Clause   : Editor.Ada_Syntax_Tree.Node_Info;
      Parent_Info : Representation_Legality_Info) is
      Target_Type_Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Positional_Index : Positive := 1;
   begin
      if Parent_Info.Target_Type /= Editor.Ada_Type_Graph.No_Type then
         Target_Type_Node := Editor.Ada_Type_Graph.Type_Node (Types, Parent_Info.Target_Type).Node;
      end if;

      for C in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Clause.Id) loop
         declare
            Child_Id : constant Editor.Ada_Syntax_Tree.Node_Id :=
              Editor.Ada_Syntax_Tree.Child_At (Tree, Clause.Id, C);
            Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node (Tree, Child_Id);
         begin
            if Child.Kind = Editor.Ada_Syntax_Tree.Node_Named_Association then
               declare
                  Selector_Text : constant String :=
                    Child_Label (Tree, Child.Id, Editor.Ada_Syntax_Tree.Node_Statement_Target);
                  Action_Text : constant String :=
                    Child_Label (Tree, Child.Id, Editor.Ada_Syntax_Tree.Node_Statement_Action);
                  Is_Named : constant Boolean := Action_Text /= "";
                  Literal_Name : constant String :=
                    (if Is_Named then Selector_Text
                     else Enumeration_Literal_Name_At (Tree, Target_Type_Node, Positional_Index));
                  Value_Text : constant String :=
                    (if Is_Named then Action_Text else Selector_Text);
                  Expected_Pos : constant Natural :=
                    (if Is_Named then Enumeration_Literal_Position (Tree, Target_Type_Node, Selector_Text)
                     else Natural (Positional_Index));
               begin
                  Add_Enumeration_Check
                    (Model, Tree, Static, Parent_Info, Child, Literal_Name,
                     Value_Text, Expected_Pos, Target_Type_Node);
                  if not Is_Named then
                     Positional_Index := Positional_Index + 1;
                  end if;
               end;
            end if;
         end;
      end loop;

      if Is_Enumeration_Type_Node (Tree, Target_Type_Node) then
         declare
            Total : constant Natural := Enumeration_Literal_Count (Tree, Target_Type_Node);
         begin
            for Pos in 1 .. Total loop
               declare
                  Lit : constant String := Enumeration_Literal_Name_At (Tree, Target_Type_Node, Pos);
               begin
                  if not Enumeration_Literal_Duplicate
                           (Model, Parent_Info.Clause_Node, Lower (Lit))
                  then
                     Add_Enumeration_Incomplete_Check
                       (Model, Parent_Info, Lit, Clause.Source_Span.Start_Line);
                  end if;
               end;
            end loop;
         end;
      end if;
   end Add_Enumeration_Representation_Checks;

   function Component_Duplicate
     (Model         : Representation_Legality_Model;
      Parent_Clause : Editor.Ada_Syntax_Tree.Node_Id;
      Normalized_Name : String) return Boolean is
   begin
      for Index in 1 .. Natural (Model.Component_Checks.Length) loop
         declare
            Prior : constant Record_Component_Legality_Info := Model.Component_Checks (Index);
         begin
            if Prior.Parent_Clause = Parent_Clause
              and then To_String (Prior.Normalized_Component) = Normalized_Name
            then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Component_Duplicate;

   procedure Count_Component_Result
     (Model : in out Representation_Legality_Model;
      Info  : Record_Component_Legality_Info) is
   begin
      if Info.Status /= Representation_Legality_Ok then
         Model.Component_Error_Total := Model.Component_Error_Total + 1;
         if Info.Status = Representation_Legality_Record_Component_Duplicate then
            Model.Component_Duplicate_Total := Model.Component_Duplicate_Total + 1;
         elsif Info.Status in Representation_Legality_Record_Component_Static_Value_Required |
                              Representation_Legality_Record_Component_Bit_Range_Reversed |
                              Representation_Legality_Record_Component_Negative_Position
         then
            Model.Component_Static_Error_Total := Model.Component_Static_Error_Total + 1;
         end if;
      end if;
   end Count_Component_Result;

   procedure Add_Record_Component_Check
     (Model    : in out Representation_Legality_Model;
      Tree     : Editor.Ada_Syntax_Tree.Tree_Type;
      Types    : Editor.Ada_Type_Graph.Type_Model;
      Static   : Editor.Ada_Static_Expressions.Static_Model;
      Node     : Editor.Ada_Syntax_Tree.Node_Info) is
      Parent_Clause : constant Editor.Ada_Syntax_Tree.Node_Id :=
        Ancestor_Representation_Clause (Tree, Node.Id);
      Parent_Info : constant Representation_Legality_Info :=
        Check_For_Clause (Model, Parent_Clause);
      Component_Text : constant String :=
        Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Representation_Target);
      Storage_Text : constant String :=
        Strip_Leading_At (Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Representation_Item));
      Range_Text : constant String :=
        Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Range_Expression);
      First_Text : constant String := Range_First (Range_Text);
      Last_Text  : constant String := Range_Last (Range_Text);
      Storage_Value : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
        Editor.Ada_Static_Expressions.Evaluate_Numeric_Expression
          (Static, Editor.Ada_Declarative_Regions.No_Region, Storage_Text);
      First_Value : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
        Editor.Ada_Static_Expressions.Evaluate_Numeric_Expression
          (Static, Editor.Ada_Declarative_Regions.No_Region, First_Text);
      Last_Value : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
        Editor.Ada_Static_Expressions.Evaluate_Numeric_Expression
          (Static, Editor.Ada_Declarative_Regions.No_Region, Last_Text);
      Info : Record_Component_Legality_Info;
      Target_Type_Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
   begin
      Info.Clause_Node := Node.Id;
      Info.Parent_Clause := Parent_Clause;
      Info.Target_Name := Parent_Info.Target_Name;
      Info.Component_Name := To_Unbounded_String (Trimmed (Component_Text));
      Info.Normalized_Component := To_Unbounded_String (Lower (Component_Text));
      Info.Storage_Unit_Text := To_Unbounded_String (Storage_Text);
      Info.First_Bit_Text := To_Unbounded_String (First_Text);
      Info.Last_Bit_Text := To_Unbounded_String (Last_Text);
      Info.Storage_Value_Status := Value_Status_For (Storage_Value);
      Info.First_Bit_Value_Status := Value_Status_For (First_Value);
      Info.Last_Bit_Value_Status := Value_Status_For (Last_Value);
      Info.Static_Storage_Unit := Storage_Value.Integer_Value;
      Info.Static_First_Bit := First_Value.Integer_Value;
      Info.Static_Last_Bit := Last_Value.Integer_Value;
      Info.Source_Line := Node.Source_Span.Start_Line;

      if Parent_Info.Target_Type /= Editor.Ada_Type_Graph.No_Type then
         Target_Type_Node := Editor.Ada_Type_Graph.Type_Node (Types, Parent_Info.Target_Type).Node;
      end if;

      if Parent_Info.Target_Category /= Editor.Ada_Type_Graph.Type_Category_Record
        and then Parent_Info.Target_Category /= Editor.Ada_Type_Graph.Type_Category_Private
        and then Parent_Info.Target_Category /= Editor.Ada_Type_Graph.Type_Category_Unknown
      then
         Info.Status := Representation_Legality_Target_Kind_Mismatch;
      elsif not Has_Record_Component (Tree, Target_Type_Node, Component_Text) then
         Info.Status := Representation_Legality_Record_Component_Unresolved;
      elsif Component_Duplicate (Model, Parent_Clause, To_String (Info.Normalized_Component)) then
         Info.Status := Representation_Legality_Record_Component_Duplicate;
      elsif Info.Storage_Value_Status /= Representation_Value_Static_Integer
        or else Info.First_Bit_Value_Status /= Representation_Value_Static_Integer
        or else Info.Last_Bit_Value_Status /= Representation_Value_Static_Integer
      then
         Info.Status := Representation_Legality_Record_Component_Static_Value_Required;
      elsif Info.Static_Storage_Unit < 0
        or else Info.Static_First_Bit < 0
        or else Info.Static_Last_Bit < 0
      then
         Info.Status := Representation_Legality_Record_Component_Negative_Position;
      elsif Info.Static_Last_Bit < Info.Static_First_Bit then
         Info.Status := Representation_Legality_Record_Component_Bit_Range_Reversed;
      else
         Info.Status := Representation_Legality_Ok;
      end if;

      Info.Fingerprint :=
        Mix (Natural (Info.Clause_Node),
             Mix (Natural (Info.Parent_Clause),
                  Mix (Info.Source_Line,
                       Mix (Representation_Legality_Status'Pos (Info.Status),
                            Mix (Natural (abs Info.Static_Storage_Unit mod 2_147_483_647),
                                 Natural (abs Info.Static_First_Bit mod 2_147_483_647))))));

      Model.Component_Checks.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint);
      Count_Component_Result (Model, Info);
   end Add_Record_Component_Check;

   function Import_Export_Enabled_For_Target
     (Model  : Representation_Legality_Model;
      Target : String) return Boolean is
   begin
      for Index in 1 .. Natural (Model.Checks.Length) loop
         declare
            Info : constant Representation_Legality_Info := Model.Checks (Index);
         begin
            if To_String (Info.Normalized_Target) = Target
              and then Info.Status = Representation_Legality_Ok
              and then Info.Clause_Kind in Editor.Ada_Language_Model.Representation_Import_Clause |
                                           Editor.Ada_Language_Model.Representation_Export_Clause
              and then Info.Interfacing_Status = Interfacing_Value_Static_Boolean_True
            then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Import_Export_Enabled_For_Target;

   function Has_Opposite_Enabled_Import_Export
     (Model : Representation_Legality_Model;
      Info  : Representation_Legality_Info) return Boolean is
      Target : constant String := To_String (Info.Normalized_Target);
      Opposite : constant Editor.Ada_Language_Model.Representation_Clause_Kind :=
        (if Info.Clause_Kind = Editor.Ada_Language_Model.Representation_Import_Clause
         then Editor.Ada_Language_Model.Representation_Export_Clause
         else Editor.Ada_Language_Model.Representation_Import_Clause);
   begin
      if Info.Clause_Kind not in Editor.Ada_Language_Model.Representation_Import_Clause |
                                Editor.Ada_Language_Model.Representation_Export_Clause
        or else Info.Interfacing_Status /= Interfacing_Value_Static_Boolean_True
      then
         return False;
      end if;

      for Index in 1 .. Natural (Model.Checks.Length) loop
         declare
            Other : constant Representation_Legality_Info := Model.Checks (Index);
         begin
            if Other.Clause_Node /= Info.Clause_Node
              and then To_String (Other.Normalized_Target) = Target
              and then Other.Clause_Kind = Opposite
              and then Other.Status = Representation_Legality_Ok
              and then Other.Interfacing_Status = Interfacing_Value_Static_Boolean_True
            then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Has_Opposite_Enabled_Import_Export;

   procedure Finalize_Interfacing_Conflicts
     (Model : in out Representation_Legality_Model) is
   begin
      for Index in 1 .. Natural (Model.Checks.Length) loop
         declare
            Info : Representation_Legality_Info := Model.Checks (Index);
         begin
            if Info.Status = Representation_Legality_Ok
              and then Has_Opposite_Enabled_Import_Export (Model, Info)
            then
               Info.Status := Representation_Legality_Import_Export_Conflict;
               Info.Fingerprint := Mix (Info.Fingerprint,
                 Representation_Legality_Status'Pos (Info.Status));
               Model.Checks.Replace_Element (Index, Info);
            elsif Info.Status = Representation_Legality_Ok
              and then Info.Clause_Kind in Editor.Ada_Language_Model.Representation_External_Name_Clause |
                                           Editor.Ada_Language_Model.Representation_Link_Name_Clause
              and then not Import_Export_Enabled_For_Target
                (Model, To_String (Info.Normalized_Target))
            then
               Info.Status := Representation_Legality_Link_Name_Requires_Import_Export;
               Info.Fingerprint := Mix (Info.Fingerprint,
                 Representation_Legality_Status'Pos (Info.Status));
               Model.Checks.Replace_Element (Index, Info);
            end if;
         end;
      end loop;
   end Finalize_Interfacing_Conflicts;

   procedure Recount (Model : in out Representation_Legality_Model) is
   begin
      Model.Ok_Total := 0;
      Model.Error_Total := 0;
      Model.Static_Error_Total := 0;
      Model.Kind_Error_Total := 0;
      Model.Freeze_Error_Total := 0;
      Model.Component_Error_Total := 0;
      Model.Component_Duplicate_Total := 0;
      Model.Component_Static_Error_Total := 0;
      Model.Enumeration_Error_Total := 0;
      Model.Enumeration_Duplicate_Literal_Total := 0;
      Model.Enumeration_Duplicate_Value_Total := 0;
      Model.Enumeration_Static_Error_Total := 0;
      Model.Enumeration_Incomplete_Total := 0;
      Model.Address_Target_Error_Total := 0;
      Model.Address_Value_Error_Total := 0;
      Model.Address_Static_Value_Total := 0;
      Model.Size_Alignment_Storage_Error_Total := 0;
      Model.Size_Alignment_Storage_Static_Error_Total := 0;
      Model.Interfacing_Error_Total := 0;
      Model.Interfacing_Target_Error_Total := 0;
      Model.Interfacing_Value_Error_Total := 0;
      Model.Import_Export_Conflict_Total := 0;
      Model.Link_Name_Requires_Import_Export_Total := 0;
      Model.Stream_Error_Total := 0;
      Model.Stream_Target_Error_Total := 0;
      Model.Stream_Profile_Error_Total := 0;
      Model.Stream_Profile_Unknown_Total := 0;
      Model.Operational_Error_Total := 0;
      Model.Operational_Target_Error_Total := 0;
      Model.Operational_Value_Error_Total := 0;
      Model.Operational_Static_Boolean_Total := 0;
      Model.Operational_Order_Value_Total := 0;
      Model.Aspect_Source_Total := 0;
      Model.Attribute_Definition_Source_Total := 0;
      Model.Unified_Property_Total := 0;
      Model.Result_Fingerprint := 0;

      for Index in 1 .. Natural (Model.Checks.Length) loop
         declare
            Info : constant Representation_Legality_Info := Model.Checks (Index);
         begin
            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint);
            if Info.Source_Form = Editor.Ada_Language_Model.Representation_Source_Aspect then
               Model.Aspect_Source_Total := Model.Aspect_Source_Total + 1;
               Model.Unified_Property_Total := Model.Unified_Property_Total + 1;
            elsif Info.Source_Form =
              Editor.Ada_Language_Model.Representation_Source_Attribute_Definition
            then
               Model.Attribute_Definition_Source_Total :=
                 Model.Attribute_Definition_Source_Total + 1;
               Model.Unified_Property_Total := Model.Unified_Property_Total + 1;
            end if;
            if Info.Status = Representation_Legality_Ok then
               Model.Ok_Total := Model.Ok_Total + 1;
            else
               Model.Error_Total := Model.Error_Total + 1;
            end if;

            if Info.Status in Representation_Legality_Static_Value_Required |
                              Representation_Legality_Static_Value_Malformed |
                              Representation_Legality_Static_Value_Division_By_Zero |
                              Representation_Legality_Static_Value_Not_Positive |
                              Representation_Legality_Static_Value_Not_Integer
            then
               Model.Static_Error_Total := Model.Static_Error_Total + 1;
            end if;

            if Info.Status in Representation_Legality_Target_Kind_Mismatch |
                              Representation_Legality_Size_Target_Incompatible |
                              Representation_Legality_Alignment_Target_Incompatible |
                              Representation_Legality_Storage_Size_Target_Incompatible
            then
               Model.Kind_Error_Total := Model.Kind_Error_Total + 1;
            end if;

            if Info.Status in Representation_Legality_Size_Target_Incompatible |
                              Representation_Legality_Alignment_Target_Incompatible |
                              Representation_Legality_Storage_Size_Target_Incompatible
            then
               Model.Size_Alignment_Storage_Error_Total :=
                 Model.Size_Alignment_Storage_Error_Total + 1;
            end if;

            if Info.Status in Representation_Legality_Static_Value_Required |
                              Representation_Legality_Static_Value_Malformed |
                              Representation_Legality_Static_Value_Division_By_Zero |
                              Representation_Legality_Static_Value_Not_Positive |
                              Representation_Legality_Static_Value_Not_Integer
              and then Info.Clause_Kind in Editor.Ada_Language_Model.Representation_Size_Clause |
                                           Editor.Ada_Language_Model.Representation_Alignment_Clause |
                                           Editor.Ada_Language_Model.Representation_Component_Size_Clause |
                                           Editor.Ada_Language_Model.Representation_Object_Size_Clause |
                                           Editor.Ada_Language_Model.Representation_Value_Size_Clause |
                                           Editor.Ada_Language_Model.Representation_Storage_Size_Clause |
                                           Editor.Ada_Language_Model.Representation_Machine_Radix_Clause |
                                           Editor.Ada_Language_Model.Representation_Aft_Clause
            then
               Model.Size_Alignment_Storage_Static_Error_Total :=
                 Model.Size_Alignment_Storage_Static_Error_Total + 1;
            end if;

            if Info.Status in Representation_Legality_After_Freezing |
                              Representation_Legality_At_Freezing_Point
            then
               Model.Freeze_Error_Total := Model.Freeze_Error_Total + 1;
            end if;

            if Info.Status = Representation_Legality_Address_Target_Incompatible then
               Model.Address_Target_Error_Total := Model.Address_Target_Error_Total + 1;
            elsif Info.Status in Representation_Legality_Address_Value_Null_Not_Allowed |
                                 Representation_Legality_Address_Value_Not_Static_Address |
                                 Representation_Legality_Address_Value_Incompatible |
                                 Representation_Legality_Address_Value_Malformed
            then
               Model.Address_Value_Error_Total := Model.Address_Value_Error_Total + 1;
            end if;
            if Info.Address_Status = Address_Value_Static_Address then
               Model.Address_Static_Value_Total := Model.Address_Static_Value_Total + 1;
            end if;

            if Info.Status in Representation_Legality_Interfacing_Target_Incompatible |
                              Representation_Legality_Convention_Identifier_Required |
                              Representation_Legality_Convention_Identifier_Unknown |
                              Representation_Legality_Import_Export_Boolean_Value_Required |
                              Representation_Legality_Link_Name_String_Value_Required |
                              Representation_Legality_Import_Export_Conflict |
                              Representation_Legality_Link_Name_Requires_Import_Export
            then
               Model.Interfacing_Error_Total := Model.Interfacing_Error_Total + 1;
            end if;
            if Info.Status = Representation_Legality_Interfacing_Target_Incompatible then
               Model.Interfacing_Target_Error_Total := Model.Interfacing_Target_Error_Total + 1;
            elsif Info.Status in Representation_Legality_Convention_Identifier_Required |
                                 Representation_Legality_Convention_Identifier_Unknown |
                                 Representation_Legality_Import_Export_Boolean_Value_Required |
                                 Representation_Legality_Link_Name_String_Value_Required
            then
               Model.Interfacing_Value_Error_Total := Model.Interfacing_Value_Error_Total + 1;
            elsif Info.Status = Representation_Legality_Import_Export_Conflict then
               Model.Import_Export_Conflict_Total := Model.Import_Export_Conflict_Total + 1;
            elsif Info.Status = Representation_Legality_Link_Name_Requires_Import_Export then
               Model.Link_Name_Requires_Import_Export_Total :=
                 Model.Link_Name_Requires_Import_Export_Total + 1;
            end if;

            if Info.Status in Representation_Legality_Operational_Target_Incompatible |
                              Representation_Legality_Operational_Boolean_Value_Required |
                              Representation_Legality_Operational_Order_Value_Required
            then
               Model.Operational_Error_Total := Model.Operational_Error_Total + 1;
            end if;
            if Info.Status = Representation_Legality_Operational_Target_Incompatible then
               Model.Operational_Target_Error_Total := Model.Operational_Target_Error_Total + 1;
            elsif Info.Status in Representation_Legality_Operational_Boolean_Value_Required |
                                 Representation_Legality_Operational_Order_Value_Required
            then
               Model.Operational_Value_Error_Total := Model.Operational_Value_Error_Total + 1;
            end if;
            if Info.Operational_Status in Operational_Value_Static_Boolean_True |
                                          Operational_Value_Static_Boolean_False
            then
               Model.Operational_Static_Boolean_Total :=
                 Model.Operational_Static_Boolean_Total + 1;
            elsif Info.Operational_Status in Operational_Value_Order_High_Order_First |
                                       Operational_Value_Order_Low_Order_First
            then
               Model.Operational_Order_Value_Total :=
                 Model.Operational_Order_Value_Total + 1;
            end if;

            if Info.Status in Representation_Legality_Stream_Target_Incompatible |
                              Representation_Legality_Stream_Subprogram_Required |
                              Representation_Legality_Stream_Subprogram_Malformed |
                              Representation_Legality_Stream_Subprogram_Profile_Unknown |
                              Representation_Legality_Stream_Subprogram_Profile_Mismatch
            then
               Model.Stream_Error_Total := Model.Stream_Error_Total + 1;
            end if;
            if Info.Status = Representation_Legality_Stream_Target_Incompatible then
               Model.Stream_Target_Error_Total := Model.Stream_Target_Error_Total + 1;
            elsif Info.Status = Representation_Legality_Stream_Subprogram_Profile_Mismatch then
               Model.Stream_Profile_Error_Total := Model.Stream_Profile_Error_Total + 1;
            elsif Info.Status = Representation_Legality_Stream_Subprogram_Profile_Unknown then
               Model.Stream_Profile_Unknown_Total := Model.Stream_Profile_Unknown_Total + 1;
            end if;
         end;
      end loop;

      for Index in 1 .. Natural (Model.Component_Checks.Length) loop
         Count_Component_Result (Model, Model.Component_Checks (Index));
      end loop;
      for Index in 1 .. Natural (Model.Enumeration_Checks.Length) loop
         Count_Enumeration_Result (Model, Model.Enumeration_Checks (Index));
      end loop;
   end Recount;

   function Build
     (Tree     : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions  : Editor.Ada_Declarative_Regions.Region_Model;
      Types    : Editor.Ada_Type_Graph.Type_Model;
      Static   : Editor.Ada_Static_Expressions.Static_Model;
      Freezing : Editor.Ada_Freezing_Points.Freezing_Model)
      return Representation_Legality_Model is
      Model : Representation_Legality_Model;
   begin
      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
         begin
            if Node.Kind = Editor.Ada_Syntax_Tree.Node_Representation_Clause then
               declare
                  Target_Text : constant String :=
                    Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Representation_Target);
                  Item_Text : constant String :=
                    Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Representation_Item);
                  Kind : constant Editor.Ada_Language_Model.Representation_Clause_Kind :=
                    Clause_Kind (Target_Text, Item_Text, To_String (Node.Label));
                  Freeze : constant Editor.Ada_Freezing_Points.Representation_Freeze_Info :=
                    Editor.Ada_Freezing_Points.Representation_Check_For_Clause (Freezing, Node.Id);
                  Info : Representation_Legality_Info;
               begin
                  Info.Clause_Node := Node.Id;
                  Info.Target_Name := To_Unbounded_String (Trimmed (Target_Text));
                  Info.Normalized_Target := To_Unbounded_String (Normalized (Target_Text));
                  Info.Clause_Kind := Kind;
                  Info.Source_Form :=
                    Editor.Ada_Language_Model.Representation_Source_Attribute_Definition;
                  Info.Item_Text := To_Unbounded_String (Trimmed (Item_Text));
                  Info.Target := Freeze.Target;
                  Info.Freeze_Status := Freeze.Status;
                  Info.Source_Line := Node.Source_Span.Start_Line;

                  if Info.Target /= Editor.Ada_Freezing_Points.No_Freezable then
                     declare
                        Target_Info : constant Editor.Ada_Freezing_Points.Freezable_Info :=
                          Editor.Ada_Freezing_Points.Freezable_Node (Freezing, Info.Target);
                     begin
                        Info.Target_Freezable_Kind := Target_Info.Kind;
                        Info.Target_Type := Target_Info.Type_Node;
                        Info.Target_Category := Type_Category_For_Target (Types, Target_Info);
                     end;
                  end if;

                  if Operational_Clause (Kind) then
                     Info.Operational_Status := Operational_Value_Status_For (Kind, Item_Text);
                     Info.Value_Status := Representation_Value_Not_Required;
                  elsif Interfacing_Clause (Kind) then
                     Info.Interfacing_Status := Interfacing_Value_Status_For (Kind, Item_Text);
                     if Kind = Editor.Ada_Language_Model.Representation_Convention_Clause then
                        Info.Convention_Name := To_Unbounded_String (Trimmed (Item_Text));
                     end if;
                     Info.Value_Status := Representation_Value_Not_Required;
                  elsif Stream_Attribute_Clause (Kind) then
                     Info.Stream_Status := Stream_Subprogram_Status_For (Kind, Item_Text);
                     Info.Stream_Designator := To_Unbounded_String (Trimmed (Item_Text));
                     Info.Value_Status := Representation_Value_Not_Required;
                  elsif Kind = Editor.Ada_Language_Model.Representation_Address_Clause then
                     Info.Address_Status := Address_Value_Status_For (Item_Text);
                     Info.Value_Status := Representation_Value_Not_Required;
                  elsif Static_Value_Required (Kind) then
                     declare
                        Value : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
                          Editor.Ada_Static_Expressions.Evaluate_Numeric_Expression
                            (Static, Editor.Ada_Declarative_Regions.No_Region, Item_Text);
                     begin
                        Info.Value_Status := Value_Status_For (Value);
                        Info.Static_Integer := Value.Integer_Value;
                        Info.Static_Real := Value.Real_Value;
                     end;
                  else
                     Info.Value_Status := Representation_Value_Not_Required;
                  end if;

                  Classify (Info, Kind);
                  Info.Fingerprint := Mix (Natural (Info.Clause_Node), Natural (Info.Target));
                  Info.Fingerprint := Mix (Info.Fingerprint, Natural (Info.Target_Type));
                  Info.Fingerprint := Mix (Info.Fingerprint, Info.Source_Line);
                  Info.Fingerprint := Mix (Info.Fingerprint, Representation_Legality_Status'Pos (Info.Status));
                  Info.Fingerprint := Mix (Info.Fingerprint, Representation_Value_Status'Pos (Info.Value_Status));
                  Info.Fingerprint := Mix (Info.Fingerprint, Address_Value_Status'Pos (Info.Address_Status));
                  Info.Fingerprint := Mix (Info.Fingerprint, Interfacing_Value_Status'Pos (Info.Interfacing_Status));
                  Info.Fingerprint := Mix (Info.Fingerprint, Stream_Subprogram_Status'Pos (Info.Stream_Status));
                  Info.Fingerprint := Mix (Info.Fingerprint, Operational_Value_Status'Pos (Info.Operational_Status));

                  Model.Checks.Append (Info);
                  Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint);

                  if Info.Status = Representation_Legality_Ok then
                     Model.Ok_Total := Model.Ok_Total + 1;
                  else
                     Model.Error_Total := Model.Error_Total + 1;
                     if Info.Status in Representation_Legality_Static_Value_Required |
                                       Representation_Legality_Static_Value_Malformed |
                                       Representation_Legality_Static_Value_Division_By_Zero |
                                       Representation_Legality_Static_Value_Not_Positive |
                                       Representation_Legality_Static_Value_Not_Integer
                     then
                        Model.Static_Error_Total := Model.Static_Error_Total + 1;
                        if Kind in Editor.Ada_Language_Model.Representation_Size_Clause |
                                   Editor.Ada_Language_Model.Representation_Alignment_Clause |
                                   Editor.Ada_Language_Model.Representation_Component_Size_Clause |
                                   Editor.Ada_Language_Model.Representation_Object_Size_Clause |
                                   Editor.Ada_Language_Model.Representation_Value_Size_Clause |
                                   Editor.Ada_Language_Model.Representation_Storage_Size_Clause |
                                   Editor.Ada_Language_Model.Representation_Machine_Radix_Clause |
                                   Editor.Ada_Language_Model.Representation_Aft_Clause
                        then
                           Model.Size_Alignment_Storage_Static_Error_Total :=
                             Model.Size_Alignment_Storage_Static_Error_Total + 1;
                        end if;
                     elsif Info.Status in Representation_Legality_Size_Target_Incompatible |
                                        Representation_Legality_Alignment_Target_Incompatible |
                                        Representation_Legality_Storage_Size_Target_Incompatible
                     then
                        Model.Kind_Error_Total := Model.Kind_Error_Total + 1;
                        Model.Size_Alignment_Storage_Error_Total :=
                          Model.Size_Alignment_Storage_Error_Total + 1;
                     elsif Info.Status = Representation_Legality_Target_Kind_Mismatch then
                        Model.Kind_Error_Total := Model.Kind_Error_Total + 1;
                     elsif Info.Status = Representation_Legality_Address_Target_Incompatible then
                        Model.Address_Target_Error_Total := Model.Address_Target_Error_Total + 1;
                     elsif Info.Status in Representation_Legality_Address_Value_Null_Not_Allowed |
                                        Representation_Legality_Address_Value_Not_Static_Address |
                                        Representation_Legality_Address_Value_Incompatible |
                                        Representation_Legality_Address_Value_Malformed
                     then
                        Model.Address_Value_Error_Total := Model.Address_Value_Error_Total + 1;
                     elsif Info.Status in Representation_Legality_After_Freezing |
                                        Representation_Legality_At_Freezing_Point
                     then
                        Model.Freeze_Error_Total := Model.Freeze_Error_Total + 1;
                     end if;

                  end if;

                  if Info.Address_Status = Address_Value_Static_Address then
                     Model.Address_Static_Value_Total := Model.Address_Static_Value_Total + 1;
                  end if;

                  if Kind = Editor.Ada_Language_Model.Representation_Enumeration_Clause then
                     Add_Enumeration_Representation_Checks
                       (Model, Tree, Types, Static, Node, Info);
                  end if;
               end;
            elsif Node.Kind = Editor.Ada_Syntax_Tree.Node_Aspect_Association then
               declare
                  Label_Text : constant String := To_String (Node.Label);
                  Arrow : constant Natural := Ada.Strings.Fixed.Index (Label_Text, "=>");
                  Named_Aspect : constant String :=
                    Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Aspect_Name);
                  Value_Child : constant String :=
                    Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Aspect_Value);
                  Aspect_Name : constant String :=
                    (if Named_Aspect /= "" then Trimmed (Named_Aspect)
                     elsif Arrow /= 0 then Trimmed (Label_Text (Label_Text'First .. Arrow - 1))
                     else Trimmed (Label_Text));
                  Raw_Value : constant String :=
                    (if Value_Child /= "" then Trimmed (Value_Child)
                     elsif Arrow /= 0 and then Arrow + 2 <= Label_Text'Last then
                        Trimmed (Label_Text (Arrow + 2 .. Label_Text'Last))
                     else "");
                  Item_Text : constant String := Aspect_Default_Value (Aspect_Name, Raw_Value);
                  Target_Text : constant String := Ancestor_Declaration_Target (Tree, Node.Id);
               begin
                  if Target_Text /= "" and then Aspect_Representation_Name (Aspect_Name) then
                     declare
                        Synthetic_Target : constant String :=
                          Target_Text & Character'Val (39) & Aspect_Name;
                        Kind : constant Editor.Ada_Language_Model.Representation_Clause_Kind :=
                          Clause_Kind (Synthetic_Target, Item_Text, Synthetic_Target & " use " & Item_Text);
                        Freeze : constant Editor.Ada_Freezing_Points.Representation_Freeze_Info :=
                          Freeze_Info_For_Target_At
                            (Freezing, Regions, Node.Source_Span.Start_Line, Target_Text);
                        Info : Representation_Legality_Info;
                     begin
                        Info.Clause_Node := Node.Id;
                        Info.Target_Name := To_Unbounded_String (Trimmed (Target_Text));
                        Info.Normalized_Target := To_Unbounded_String (Normalized (Target_Text));
                        Info.Clause_Kind := Kind;
                        Info.Source_Form := Editor.Ada_Language_Model.Representation_Source_Aspect;
                        Info.Item_Text := To_Unbounded_String (Trimmed (Item_Text));
                        Info.Target := Freeze.Target;
                        Info.Freeze_Status := Freeze.Status;
                        Info.Source_Line := Node.Source_Span.Start_Line;

                        if Info.Target /= Editor.Ada_Freezing_Points.No_Freezable then
                           declare
                              Target_Info : constant Editor.Ada_Freezing_Points.Freezable_Info :=
                                Editor.Ada_Freezing_Points.Freezable_Node (Freezing, Info.Target);
                           begin
                              Info.Target_Freezable_Kind := Target_Info.Kind;
                              Info.Target_Type := Target_Info.Type_Node;
                              Info.Target_Category := Type_Category_For_Target (Types, Target_Info);
                           end;
                        end if;

                        if Operational_Clause (Kind) then
                           Info.Operational_Status := Operational_Value_Status_For (Kind, Item_Text);
                           Info.Value_Status := Representation_Value_Not_Required;
                        elsif Interfacing_Clause (Kind) then
                           Info.Interfacing_Status := Interfacing_Value_Status_For (Kind, Item_Text);
                           if Kind = Editor.Ada_Language_Model.Representation_Convention_Clause then
                              Info.Convention_Name := To_Unbounded_String (Trimmed (Item_Text));
                           end if;
                           Info.Value_Status := Representation_Value_Not_Required;
                        elsif Stream_Attribute_Clause (Kind) then
                           Info.Stream_Status := Stream_Subprogram_Status_For (Kind, Item_Text);
                           Info.Stream_Designator := To_Unbounded_String (Trimmed (Item_Text));
                           Info.Value_Status := Representation_Value_Not_Required;
                        elsif Kind = Editor.Ada_Language_Model.Representation_Address_Clause then
                           Info.Address_Status := Address_Value_Status_For (Item_Text);
                           Info.Value_Status := Representation_Value_Not_Required;
                        elsif Static_Value_Required (Kind) then
                           declare
                              Value : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
                                Editor.Ada_Static_Expressions.Evaluate_Numeric_Expression
                                  (Static, Editor.Ada_Declarative_Regions.No_Region, Item_Text);
                           begin
                              Info.Value_Status := Value_Status_For (Value);
                              Info.Static_Integer := Value.Integer_Value;
                              Info.Static_Real := Value.Real_Value;
                           end;
                        else
                           Info.Value_Status := Representation_Value_Not_Required;
                        end if;

                        Classify (Info, Kind);
                        Info.Fingerprint := Mix (Natural (Info.Clause_Node), Natural (Info.Target));
                        Info.Fingerprint := Mix (Info.Fingerprint, Natural (Info.Target_Type));
                        Info.Fingerprint := Mix (Info.Fingerprint, Info.Source_Line);
                        Info.Fingerprint := Mix (Info.Fingerprint, Representation_Legality_Status'Pos (Info.Status));
                        Info.Fingerprint := Mix (Info.Fingerprint, Representation_Value_Status'Pos (Info.Value_Status));
                        Info.Fingerprint := Mix (Info.Fingerprint, Address_Value_Status'Pos (Info.Address_Status));
                        Info.Fingerprint := Mix (Info.Fingerprint, Interfacing_Value_Status'Pos (Info.Interfacing_Status));
                        Info.Fingerprint := Mix (Info.Fingerprint, Stream_Subprogram_Status'Pos (Info.Stream_Status));
                        Info.Fingerprint := Mix (Info.Fingerprint, Operational_Value_Status'Pos (Info.Operational_Status));

                        Model.Checks.Append (Info);
                        Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint);
                     end;
                  end if;
               end;
            elsif Node.Kind = Editor.Ada_Syntax_Tree.Node_Representation_Component_Clause then
               Add_Record_Component_Check (Model, Tree, Types, Static, Node);
            end if;
         end;
      end loop;

      Finalize_Interfacing_Conflicts (Model);
      Recount (Model);
      return Model;
   end Build;


   function Deepest_Region_Containing_Line
     (Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Line    : Positive) return Editor.Ada_Declarative_Regions.Region_Id is
      Result : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Depth  : Natural := 0;
   begin
      for Index in 1 .. Editor.Ada_Declarative_Regions.Region_Count (Regions) loop
         declare
            R : constant Editor.Ada_Declarative_Regions.Region_Info :=
              Editor.Ada_Declarative_Regions.Region_At (Regions, Index);
         begin
            if R.Start_Line <= Line and then Line <= R.End_Line
              and then (Result = Editor.Ada_Declarative_Regions.No_Region
                        or else R.Depth >= Depth)
            then
               Result := R.Id;
               Depth := R.Depth;
            end if;
         end;
      end loop;
      return Result;
   end Deepest_Region_Containing_Line;

   function Stream_Profile_Conforms
     (Kind    : Editor.Ada_Language_Model.Representation_Clause_Kind;
      Profile : Editor.Ada_Call_Profile_Shapes.Callable_Profile_Info) return Boolean is
      use type Editor.Ada_Call_Profile_Shapes.Callable_Profile_Status;
   begin
      if Profile.Status /= Editor.Ada_Call_Profile_Shapes.Callable_Profile_Found then
         return False;
      end if;

      case Kind is
         when Editor.Ada_Language_Model.Representation_Read_Clause |
              Editor.Ada_Language_Model.Representation_Write_Clause |
              Editor.Ada_Language_Model.Representation_Output_Clause |
              Editor.Ada_Language_Model.Representation_Put_Image_Clause =>
            return (not Profile.Has_Result) and then Profile.Parameter_Count = 2;
         when Editor.Ada_Language_Model.Representation_Input_Clause =>
            return Profile.Has_Result and then Profile.Parameter_Count = 1;
         when others =>
            return False;
      end case;
   end Stream_Profile_Conforms;

   procedure Apply_Stream_Profile_Resolution
     (Model      : in out Representation_Legality_Model;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Profiles   : Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model) is
      use type Editor.Ada_Direct_Visibility.Lookup_Status;
      use type Editor.Ada_Direct_Visibility.Declaration_Kind;
      use type Editor.Ada_Call_Profile_Shapes.Callable_Profile_Status;
   begin
      for Index in 1 .. Natural (Model.Checks.Length) loop
         declare
            Info : Representation_Legality_Info := Model.Checks (Index);
         begin
            if Stream_Attribute_Clause (Info.Clause_Kind)
              and then Info.Stream_Status = Stream_Subprogram_Profile_Unknown
            then
               declare
                  Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
                    Deepest_Region_Containing_Line (Regions, Info.Source_Line);
                  Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
                    Editor.Ada_Direct_Visibility.Lookup_Visible
                      (Visibility, Regions, Region, To_String (Info.Stream_Designator));
               begin
                  if Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found then
                     declare
                        Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
                          Editor.Ada_Direct_Visibility.Declaration
                            (Visibility, Lookup.Declaration);
                        Profile : constant Editor.Ada_Call_Profile_Shapes.Callable_Profile_Info :=
                          Editor.Ada_Call_Profile_Shapes.Callable_Profile_For_Node
                            (Profiles, Decl.Node);
                     begin
                        if Decl.Kind = Editor.Ada_Direct_Visibility.Declaration_Subprogram
                          and then Stream_Profile_Conforms (Info.Clause_Kind, Profile)
                        then
                           Info.Stream_Status := Stream_Subprogram_Profile_Known_Compatible;
                           Info.Status := Representation_Legality_Ok;
                        elsif Decl.Kind = Editor.Ada_Direct_Visibility.Declaration_Subprogram
                          and then Profile.Status = Editor.Ada_Call_Profile_Shapes.Callable_Profile_Found
                        then
                           Info.Stream_Status := Stream_Subprogram_Profile_Known_Mismatch;
                           Info.Status := Representation_Legality_Stream_Subprogram_Profile_Mismatch;
                        else
                           Info.Stream_Status := Stream_Subprogram_Profile_Unknown;
                           Info.Status := Representation_Legality_Stream_Subprogram_Profile_Unknown;
                        end if;
                     end;
                  else
                     Info.Stream_Status := Stream_Subprogram_Profile_Unknown;
                     Info.Status := Representation_Legality_Stream_Subprogram_Profile_Unknown;
                  end if;
               end;

               Info.Fingerprint :=
                 Mix (Natural (Info.Clause_Node),
                      Mix (Info.Source_Line,
                           Mix (Representation_Legality_Status'Pos (Info.Status),
                                Stream_Subprogram_Status'Pos (Info.Stream_Status))));
               Model.Checks.Replace_Element (Index, Info);
            end if;
         end;
      end loop;
      Recount (Model);
   end Apply_Stream_Profile_Resolution;

   function Build_With_Stream_Profiles
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Freezing   : Editor.Ada_Freezing_Points.Freezing_Model;
      Profiles   : Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model)
      return Representation_Legality_Model is
      Model : Representation_Legality_Model :=
        Build (Tree, Regions, Types, Static, Freezing);
   begin
      Apply_Stream_Profile_Resolution (Model, Regions, Visibility, Profiles);
      return Model;
   end Build_With_Stream_Profiles;

   function Check_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Natural (Model.Checks.Length);
   end Check_Count;

   function Check_At
     (Model : Representation_Legality_Model;
      Index : Positive) return Representation_Legality_Info is
   begin
      return Model.Checks (Index);
   end Check_At;

   function Check_For_Clause
     (Model  : Representation_Legality_Model;
      Clause : Editor.Ada_Syntax_Tree.Node_Id) return Representation_Legality_Info is
   begin
      for Index in 1 .. Natural (Model.Checks.Length) loop
         if Model.Checks (Index).Clause_Node = Clause then
            return Model.Checks (Index);
         end if;
      end loop;
      return (others => <>);
   end Check_For_Clause;

   function Record_Component_Check_Count
     (Model : Representation_Legality_Model) return Natural is
   begin
      return Natural (Model.Component_Checks.Length);
   end Record_Component_Check_Count;

   function Record_Component_Check_At
     (Model : Representation_Legality_Model;
      Index : Positive) return Record_Component_Legality_Info is
   begin
      return Model.Component_Checks (Index);
   end Record_Component_Check_At;

   function Ok_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Ok_Total;
   end Ok_Count;

   function Error_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Static_Error_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Static_Error_Total;
   end Static_Error_Count;

   function Target_Kind_Mismatch_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Kind_Error_Total;
   end Target_Kind_Mismatch_Count;

   function After_Freezing_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Freeze_Error_Total;
   end After_Freezing_Count;

   function Record_Component_Error_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Component_Error_Total;
   end Record_Component_Error_Count;

   function Record_Component_Duplicate_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Component_Duplicate_Total;
   end Record_Component_Duplicate_Count;

   function Record_Component_Static_Error_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Component_Static_Error_Total;
   end Record_Component_Static_Error_Count;


   function Enumeration_Representation_Check_Count
     (Model : Representation_Legality_Model) return Natural is
   begin
      return Natural (Model.Enumeration_Checks.Length);
   end Enumeration_Representation_Check_Count;

   function Enumeration_Representation_Check_At
     (Model : Representation_Legality_Model;
      Index : Positive) return Enumeration_Representation_Legality_Info is
   begin
      return Model.Enumeration_Checks (Index);
   end Enumeration_Representation_Check_At;

   function Enumeration_Representation_Error_Count
     (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Enumeration_Error_Total;
   end Enumeration_Representation_Error_Count;

   function Enumeration_Representation_Duplicate_Literal_Count
     (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Enumeration_Duplicate_Literal_Total;
   end Enumeration_Representation_Duplicate_Literal_Count;

   function Enumeration_Representation_Duplicate_Value_Count
     (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Enumeration_Duplicate_Value_Total;
   end Enumeration_Representation_Duplicate_Value_Count;

   function Enumeration_Representation_Static_Error_Count
     (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Enumeration_Static_Error_Total;
   end Enumeration_Representation_Static_Error_Count;

   function Enumeration_Representation_Incomplete_Count
     (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Enumeration_Incomplete_Total;
   end Enumeration_Representation_Incomplete_Count;


   function Address_Target_Error_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Address_Target_Error_Total;
   end Address_Target_Error_Count;

   function Address_Value_Error_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Address_Value_Error_Total;
   end Address_Value_Error_Count;

   function Address_Static_Value_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Address_Static_Value_Total;
   end Address_Static_Value_Count;

   function Size_Alignment_Storage_Error_Count
     (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Size_Alignment_Storage_Error_Total;
   end Size_Alignment_Storage_Error_Count;

   function Size_Alignment_Storage_Static_Error_Count
     (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Size_Alignment_Storage_Static_Error_Total;
   end Size_Alignment_Storage_Static_Error_Count;

   function Interfacing_Error_Count
     (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Interfacing_Error_Total;
   end Interfacing_Error_Count;

   function Interfacing_Target_Error_Count
     (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Interfacing_Target_Error_Total;
   end Interfacing_Target_Error_Count;

   function Interfacing_Value_Error_Count
     (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Interfacing_Value_Error_Total;
   end Interfacing_Value_Error_Count;

   function Import_Export_Conflict_Count
     (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Import_Export_Conflict_Total;
   end Import_Export_Conflict_Count;

   function Link_Name_Requires_Import_Export_Count
     (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Link_Name_Requires_Import_Export_Total;
   end Link_Name_Requires_Import_Export_Count;


   function Stream_Error_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Stream_Error_Total;
   end Stream_Error_Count;

   function Stream_Target_Error_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Stream_Target_Error_Total;
   end Stream_Target_Error_Count;

   function Stream_Profile_Error_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Stream_Profile_Error_Total;
   end Stream_Profile_Error_Count;

   function Stream_Profile_Unknown_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Stream_Profile_Unknown_Total;
   end Stream_Profile_Unknown_Count;

   function Operational_Error_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Operational_Error_Total;
   end Operational_Error_Count;

   function Operational_Target_Error_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Operational_Target_Error_Total;
   end Operational_Target_Error_Count;

   function Operational_Value_Error_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Operational_Value_Error_Total;
   end Operational_Value_Error_Count;

   function Operational_Static_Boolean_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Operational_Static_Boolean_Total;
   end Operational_Static_Boolean_Count;

   function Operational_Order_Value_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Operational_Order_Value_Total;
   end Operational_Order_Value_Count;

   function Aspect_Source_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Aspect_Source_Total;
   end Aspect_Source_Count;

   function Attribute_Definition_Source_Count
     (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Attribute_Definition_Source_Total;
   end Attribute_Definition_Source_Count;

   function Unified_Property_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Unified_Property_Total;
   end Unified_Property_Count;

   function Fingerprint (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Representation_Legality;
