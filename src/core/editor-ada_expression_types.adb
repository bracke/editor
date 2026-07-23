with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Editor.Ada_Language_Model;
with Editor.Ada_Expression_Types.Cross_Unit_Selected_Subtype_Refinement;
with Editor.Ada_Expression_Types.Access_Text_Helpers;
with Editor.Ada_Expression_Types.Inference_Support;
with Editor.Ada_Expression_Types.Call_Inference;
with Editor.Ada_Expression_Types.Call_Text_Helpers;
with Editor.Ada_Expression_Types.Model_Accessors;
with Editor.Ada_Expression_Types.Operator_Helpers;
with Editor.Ada_Expression_Types.Statistics;
with Editor.Ada_Use_Type_Operators;
with Editor.Ada_Expression_Types.Status_Helpers;

package body Editor.Ada_Expression_Types is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Call_Resolution.Call_Resolution_Id;
   use type Editor.Ada_Call_Resolution.Call_Resolution_Status;
   use type Editor.Ada_Direct_Visibility.Lookup_Status;
   use type Editor.Ada_Expected_Type_Contexts.Expected_Context_Id;
   use type Editor.Ada_Expected_Type_Contexts.Expected_Context_Status;
   use type Editor.Ada_Selected_Name_Resolution.Selected_Name_Status;
   use type Editor.Ada_Static_Expressions.Static_Value_Status;
   use type Editor.Ada_Static_Expressions.Static_Modular_Type_Id;
   use type Editor.Ada_Static_Expressions.Static_Fixed_Type_Id;
   use type Editor.Ada_Syntax_Tree.Node_Kind;
   use type Editor.Ada_Declarative_Regions.Region_Id;
   use type Editor.Ada_Direct_Visibility.Declaration_Id;
   use type Editor.Ada_Direct_Visibility.Declaration_Kind;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Type_Graph.Type_Id;
   use type Editor.Ada_Type_Graph.Type_Category;
   use type Editor.Ada_Type_Graph.Compatibility_Status;
   use type Editor.Ada_Use_Type_Operators.Primitive_Use_Status;

   function To_Unbounded_String (Value : String)
      return Ada.Strings.Unbounded.Unbounded_String
      renames Ada.Strings.Unbounded.To_Unbounded_String;
   function To_String (Value : Ada.Strings.Unbounded.Unbounded_String) return String
      renames Ada.Strings.Unbounded.To_String;

   function Trim (Text : String) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Trim;

   function Normalize (Text : String) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Normalize;

   function Contains (Text : String; Pattern : String) return Boolean
     renames Editor.Ada_Expression_Types.Status_Helpers.Contains;

   function Hash_Mix
     (Seed       : Natural;
      Addend     : Long_Long_Integer;
      Multiplier : Long_Long_Integer := 131) return Natural
     renames Editor.Ada_Expression_Types.Status_Helpers.Hash_Mix;

   function Hash_Text (Text : String) return Natural
     renames Editor.Ada_Expression_Types.Status_Helpers.Hash_Text;

   function Conditional_Status_Text
     (Status : Conditional_Type_Inference_Status) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Conditional_Status_Text;

   function Membership_Range_Status_Text
     (Status : Membership_Range_Inference_Status) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Membership_Range_Status_Text;

   function Target_Name_Status_Text
     (Status : Target_Name_Inference_Status) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Target_Name_Status_Text;

   function Indexed_Slice_Status_Text
     (Status : Indexed_Slice_Inference_Status) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Indexed_Slice_Status_Text;

   function Boolean_Context_Status_Text
     (Status : Boolean_Context_Inference_Status) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Boolean_Context_Status_Text;

   function Raise_No_Return_Status_Text
     (Status : Raise_No_Return_Inference_Status) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Raise_No_Return_Status_Text;

   function Allocator_Status_Text
     (Status : Allocator_Type_Inference_Status) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Allocator_Status_Text;

   function Universal_Numeric_Status_Text
     (Status : Universal_Numeric_Resolution_Status) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Universal_Numeric_Status_Text;

   function Dispatching_Call_Status_Text
     (Status : Dispatching_Call_Inference_Status) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Dispatching_Call_Status_Text;

   function Call_Actual_Type_Status_Text
     (Status : Call_Actual_Type_Resolution_Status) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Call_Actual_Type_Status_Text;

   function Parameter_Association_Status_Text
     (Status : Parameter_Association_Inference_Status) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Parameter_Association_Status_Text;

   function Dereference_Access_Status_Text
     (Status : Dereference_Access_Inference_Status) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Dereference_Access_Status_Text;

   function Attribute_Status_Text
     (Status : Attribute_Type_Inference_Status) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Attribute_Status_Text;

   function Operator_Status_Text
     (Status : Operator_Type_Inference_Status) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Operator_Status_Text;

   function Concatenation_Status_Text
     (Status : Concatenation_Type_Inference_Status) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Concatenation_Status_Text;

   function Aggregate_Status_Text
     (Status : Aggregate_Type_Inference_Status) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Aggregate_Status_Text;

   function Conversion_Status_Text
     (Status : Conversion_Type_Inference_Status) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Conversion_Status_Text;

   function Expected_Status_Text
     (Status : Expected_Type_Propagation_Status) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Expected_Status_Text;

   function Status_Text (Status : Expression_Type_Status) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Status_Text;

   function Fingerprint_For (Info : Expression_Type_Info) return Natural
     renames Editor.Ada_Expression_Types.Inference_Support.Fingerprint_For;

   function Region_For_Line
     (Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Line    : Positive) return Editor.Ada_Declarative_Regions.Region_Id
     renames Editor.Ada_Expression_Types.Inference_Support.Region_For_Line;

   function Primary_Name (Text : String) return String
     renames Editor.Ada_Expression_Types.Inference_Support.Primary_Name;

   function Simple_Name (Text : String) return String
     renames Editor.Ada_Expression_Types.Inference_Support.Simple_Name;

   function Prefix_Before (Text : String; Mark : Character) return String
     renames Editor.Ada_Expression_Types.Inference_Support.Prefix_Before;

   function Suffix_After (Text : String; Mark : Character) return String
     renames Editor.Ada_Expression_Types.Inference_Support.Suffix_After;

   function Attribute_Name_From_Text (Text : String) return String
     renames Editor.Ada_Expression_Types.Inference_Support.Attribute_Name_From_Text;

   function Attribute_Prefix_From_Text (Text : String) return String
     renames Editor.Ada_Expression_Types.Inference_Support.Attribute_Prefix_From_Text;

   function Is_String_Literal (Text : String) return Boolean
     renames Editor.Ada_Expression_Types.Inference_Support.Is_String_Literal;

   function Is_Character_Literal_Text (Text : String) return Boolean
     renames Editor.Ada_Expression_Types.Inference_Support.Is_Character_Literal_Text;

   function Looks_Real (Text : String) return Boolean
     renames Editor.Ada_Expression_Types.Inference_Support.Looks_Real;

   function Is_Universal_Compatible (Actual : String; Expected : String) return Boolean
     renames Editor.Ada_Expression_Types.Inference_Support.Is_Universal_Compatible;

   function Is_Context_Dependent
     (Status : Expression_Type_Status) return Boolean
     renames Editor.Ada_Expression_Types.Inference_Support.Is_Context_Dependent;

   function Subtype_From_Declaration_Label (Label : String) return String
     renames Editor.Ada_Expression_Types.Inference_Support.Subtype_From_Declaration_Label;

   procedure Apply_Syntax_Expected_Context
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Info : in out Expression_Type_Info)
     renames Editor.Ada_Expression_Types.Inference_Support.Apply_Syntax_Expected_Context;

   procedure Apply_Expected_Context
     (Info     : in out Expression_Type_Info;
      Expected : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model)
     renames Editor.Ada_Expression_Types.Inference_Support.Apply_Expected_Context;

   procedure Append
     (Model : in out Expression_Type_Model;
      Info  : in out Expression_Type_Info)
     renames Editor.Ada_Expression_Types.Inference_Support.Append;

   function Operator_Symbol_From_Text (Text : String) return String
     renames Editor.Ada_Expression_Types.Operator_Helpers.Operator_Symbol_From_Text;

   function Is_Relational_Operator (Symbol : String) return Boolean
     renames Editor.Ada_Expression_Types.Operator_Helpers.Is_Relational_Operator;

   function Is_Boolean_Operator (Symbol : String) return Boolean
     renames Editor.Ada_Expression_Types.Operator_Helpers.Is_Boolean_Operator;

   function Is_Numeric_Operator (Symbol : String) return Boolean
     renames Editor.Ada_Expression_Types.Operator_Helpers.Is_Numeric_Operator;

   function Is_Integer_Family (Subtype_Name : String) return Boolean
     renames Editor.Ada_Expression_Types.Operator_Helpers.Is_Integer_Family;

   function Is_Real_Family (Subtype_Name : String) return Boolean
     renames Editor.Ada_Expression_Types.Operator_Helpers.Is_Real_Family;

   function Is_Numeric_Family (Subtype_Name : String) return Boolean
     renames Editor.Ada_Expression_Types.Operator_Helpers.Is_Numeric_Family;

   function Is_String_Family (Subtype_Name : String) return Boolean
     renames Editor.Ada_Expression_Types.Operator_Helpers.Is_String_Family;

   function Is_Character_Family (Subtype_Name : String) return Boolean
     renames Editor.Ada_Expression_Types.Operator_Helpers.Is_Character_Family;

   function Is_Array_Family
     (Types   : Editor.Ada_Type_Graph.Type_Model;
      Region  : Editor.Ada_Declarative_Regions.Region_Id;
      Subtype_Name : String) return Boolean
     renames Editor.Ada_Expression_Types.Operator_Helpers.Is_Array_Family;

   function Simple_Subtype_Compatible (Left : String; Right : String) return Boolean
     renames Editor.Ada_Expression_Types.Operator_Helpers.Simple_Subtype_Compatible;

   function Looks_Range_Choice (Text : String) return Boolean
     renames Editor.Ada_Expression_Types.Operator_Helpers.Looks_Range_Choice;

   procedure Set_Boolean_Result (Info : in out Expression_Type_Info)
     renames Editor.Ada_Expression_Types.Operator_Helpers.Set_Boolean_Result;

   function Infer_Operand_Subtype
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Parent     : Editor.Ada_Syntax_Tree.Node_Info;
      Child_Index : Positive) return String
     is separate;

   function Lookup_Operand_Subtype_Text
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Text       : String) return String;

   function Count_Commas (Text : String) return Natural is
      Result : Natural := 0;
   begin
      for C of Text loop
         if C = ',' then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Count_Commas;

   function Strip_Aggregate_Delimiters (Text : String) return String is
      T : constant String := Trim (Text);
   begin
      if T'Length >= 2 and then T (T'First) = '(' and then T (T'Last) = ')' then
         return Trim (T (T'First + 1 .. T'Last - 1));
      else
         return T;
      end if;
   end Strip_Aggregate_Delimiters;

   function Top_Level_Association_Count (Text : String) return Natural is
      T : constant String := Strip_Aggregate_Delimiters (Text);
      Depth : Natural := 0;
      Count : Natural := 1;
   begin
      if T = "" then
         return 0;
      end if;

      for C of T loop
         if C = '(' then
            Depth := Depth + 1;
         elsif C = ')' and then Depth > 0 then
            Depth := Depth - 1;
         elsif C = ',' and then Depth = 0 then
            Count := Count + 1;
         end if;
      end loop;

      return Count;
   end Top_Level_Association_Count;

   function Top_Level_Association_At (Text : String; Index : Positive) return String is
      T : constant String := Strip_Aggregate_Delimiters (Text);
      Depth : Natural := 0;
      Current : Positive := 1;
      Start : Natural := T'First;
   begin
      if T = "" then
         return "";
      end if;

      for I in T'Range loop
         if T (I) = '(' then
            Depth := Depth + 1;
         elsif T (I) = ')' and then Depth > 0 then
            Depth := Depth - 1;
         elsif T (I) = ',' and then Depth = 0 then
            if Current = Index then
               return Trim (T (Start .. I - 1));
            end if;
            Current := Current + 1;
            Start := I + 1;
         end if;
      end loop;

      if Current = Index and then Start <= T'Last then
         return Trim (T (Start .. T'Last));
      else
         return "";
      end if;
   end Top_Level_Association_At;

   function Looks_Record_Aggregate (Text : String) return Boolean is
      T : constant String := Normalize (Text);
   begin
      return Contains (T, "=>") and then not Contains (T, " for ") and then
        not Contains (T, " of ");
   end Looks_Record_Aggregate;

   function Looks_Container_Aggregate (Text : String) return Boolean is
      T : constant String := Normalize (Text);
   begin
      return Contains (T, " for ") or else Contains (T, " of ") or else
        Contains (T, " use ") or else Contains (T, "=> <>");
   end Looks_Container_Aggregate;

   function Extract_Array_Element_Subtype (Expected : String) return String is
      T : constant String := Trim (Expected);
      N : constant String := Normalize (T);
      Mark : constant String := " of ";
      P : constant Natural := Ada.Strings.Fixed.Index (N, Mark);
   begin
      if P /= 0 and then P + Mark'Length <= T'Last then
         return Trim (T (P + Mark'Length .. T'Last));
      elsif Contains (N, "string") then
         return "Character";
      elsif Contains (N, "integer_array") then
         return "Integer";
      elsif N'Length > 6 and then N (N'Last - 5 .. N'Last) = "_array" then
         declare
            Base : constant String := T (T'First .. T'Last - 6);
         begin
            if Base /= "" then
               return Base;
            else
               return "";
            end if;
         end;
      else
         return "";
      end if;
   end Extract_Array_Element_Subtype;

   function Array_Element_Subtype_For
     (Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Types  : Editor.Ada_Type_Graph.Type_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Expected : String) return String
     is separate;

   function Extract_Array_Index_Subtype (Expected : String) return String is
      T : constant String := Trim (Expected);
      N : constant String := Normalize (T);
      L : constant Natural := Ada.Strings.Fixed.Index (N, "(");
      R : constant Natural := Ada.Strings.Fixed.Index (N, ")");
   begin
      if L /= 0 and then R > L then
         return Trim (T (L + 1 .. R - 1));
      else
         return "";
      end if;
   end Extract_Array_Index_Subtype;

   function Aggregate_Association_Name (Text : String) return String is
      T : constant String := Trim (Text);
      P : constant Natural := Ada.Strings.Fixed.Index (T, "=>");
   begin
      if P = 0 or else P <= T'First then
         return "";
      end if;
      declare
         Raw_Text : constant String := Trim (T (T'First .. P - 1));
         Dot : constant Natural := Ada.Strings.Fixed.Index (Raw_Text, ".");
      begin
         if Dot /= 0 and then Dot < Raw_Text'Last then
            return Trim (Raw_Text (Dot + 1 .. Raw_Text'Last));
         else
            return Raw_Text;
         end if;
      end;
   end Aggregate_Association_Name;

   function Aggregate_Association_Value (Text : String) return String is
      T : constant String := Trim (Text);
      P : constant Natural := Ada.Strings.Fixed.Index (T, "=>");
   begin
      if P = 0 or else P + 2 > T'Last then
         return T;
      else
         return Trim (T (P + 2 .. T'Last));
      end if;
   end Aggregate_Association_Value;

   function Type_Category_For_Subtype
     (Types  : Editor.Ada_Type_Graph.Type_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name   : String) return Editor.Ada_Type_Graph.Type_Category
   is
      Id : constant Editor.Ada_Type_Graph.Type_Id :=
        Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Name);
   begin
      if Id = Editor.Ada_Type_Graph.No_Type then
         declare
            N : constant String := Normalize (Name);
         begin
            if Contains (N, "array") or else Contains (N, "string") then
               return Editor.Ada_Type_Graph.Type_Category_Array;
            elsif Contains (N, "record") then
               return Editor.Ada_Type_Graph.Type_Category_Record;
            else
               return Editor.Ada_Type_Graph.Type_Category_Unknown;
            end if;
         end;
      else
         return Editor.Ada_Type_Graph.Type_Node (Types, Id).Category;
      end if;
   end Type_Category_For_Subtype;

   function Record_Component_Known
     (Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Types  : Editor.Ada_Type_Graph.Type_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Record_Subtype : String;
      Component_Name : String) return Boolean
   is
      Type_Id : constant Editor.Ada_Type_Graph.Type_Id :=
        Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Record_Subtype);
      Target : constant String := Normalize (Component_Name);
   begin
      if Target = "" then
         return False;
      end if;
      if Type_Id = Editor.Ada_Type_Graph.No_Type then
         return False;
      end if;

      declare
         Root : constant Editor.Ada_Syntax_Tree.Node_Id :=
           Editor.Ada_Type_Graph.Type_Node (Types, Type_Id).Node;
      begin
         if Root = Editor.Ada_Syntax_Tree.No_Node then
            return False;
         end if;
         for I in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
            declare
               N : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node_At (Tree, I);
               Name_Text : Ada.Strings.Unbounded.Unbounded_String;
            begin
               if N.Kind = Editor.Ada_Syntax_Tree.Node_Component_Declaration
                 and then N.Source_Span.Start_Line >= Editor.Ada_Type_Graph.Type_Node (Types, Type_Id).Start_Line
                 and then N.Source_Span.End_Line <= Editor.Ada_Type_Graph.Type_Node (Types, Type_Id).End_Line
               then
                  Name_Text := To_Unbounded_String (Aggregate_Association_Name (To_String (N.Label)));
                  if To_String (Name_Text) = "" then
                     declare
                        L : constant String := To_String (N.Label);
                        Colon : constant Natural := Ada.Strings.Fixed.Index (L, ":");
                     begin
                        if Colon > L'First then
                           Name_Text := To_Unbounded_String (Trim (L (L'First .. Colon - 1)));
                        end if;
                     end;
                  end if;
                  if Normalize (To_String (Name_Text)) = Target then
                     return True;
                  end if;
               end if;
            end;
         end loop;
      end;
      return False;
   end Record_Component_Known;

   function Looks_Element_Compatible (Value_Text : String; Element_Subtype : String) return Boolean is
      V : constant String := Normalize (Trim (Value_Text));
      E : constant String := Normalize (Trim (Element_Subtype));
   begin
      if E = "" or else V = "" or else V = "<>" then
         return False;
      elsif E = "character" then
         return V'Length >= 3 and then V (V'First) = Character'Val (39) and then V (V'Last) = Character'Val (39);
      elsif E = "string" then
         return V'Length >= 2 and then V (V'First) = Character'Val (34) and then V (V'Last) = Character'Val (34);
      elsif Contains (E, "integer") or else Contains (E, "natural") or else Contains (E, "positive") then
         return not Looks_Real (V) and then V /= "true" and then V /= "false";
      elsif Contains (E, "float") or else Contains (E, "real") or else Contains (E, "fixed") then
         return Looks_Real (V) or else (V /= "true" and then V /= "false" and then V /= "null");
      elsif E = "boolean" then
         return V = "true" or else V = "false";
      else
         return True;
      end if;
   end Looks_Element_Compatible;


   function Extract_Designator_Before_Call (Text : String) return String
     renames Editor.Ada_Expression_Types.Call_Text_Helpers.Extract_Designator_Before_Call;

   function Extract_First_Actual_Text (Text : String) return String
     renames Editor.Ada_Expression_Types.Call_Text_Helpers.Extract_First_Actual_Text;

   function Subtype_Compatible_By_Graph
     (Types    : Editor.Ada_Type_Graph.Type_Model;
      Region   : Editor.Ada_Declarative_Regions.Region_Id;
      Expected : String;
      Actual   : String) return Boolean
   is
      E : constant Editor.Ada_Type_Graph.Type_Id :=
        Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Expected);
      A : constant Editor.Ada_Type_Graph.Type_Id :=
        Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Actual);
      C : Editor.Ada_Type_Graph.Compatibility_Status :=
        Editor.Ada_Type_Graph.Type_Compatibility_Not_Checked;
   begin
      if Normalize (Expected) = Normalize (Actual) then
         return True;
      elsif E = Editor.Ada_Type_Graph.No_Type or else A = Editor.Ada_Type_Graph.No_Type then
         return False;
      else
         C := Editor.Ada_Type_Graph.Compatibility (Types, E, A);
         return C = Editor.Ada_Type_Graph.Type_Compatibility_Exact_Type or else
           C = Editor.Ada_Type_Graph.Type_Compatibility_Subtype_Of or else
           C = Editor.Ada_Type_Graph.Type_Compatibility_Class_Wide;
      end if;
   end Subtype_Compatible_By_Graph;

   function Universal_Compatible_By_Category
     (Types    : Editor.Ada_Type_Graph.Type_Model;
      Region   : Editor.Ada_Declarative_Regions.Region_Id;
      Actual   : String;
      Expected : String) return Boolean
   is
      A : constant String := Normalize (Actual);
      Category : constant Editor.Ada_Type_Graph.Type_Category :=
        Type_Category_For_Subtype (Types, Region, Expected);
   begin
      if A = "universal_integer" then
         return Category in Editor.Ada_Type_Graph.Type_Category_Integer |
                            Editor.Ada_Type_Graph.Type_Category_Modular |
                            Editor.Ada_Type_Graph.Type_Category_Floating |
                            Editor.Ada_Type_Graph.Type_Category_Fixed;
      elsif A = "universal_real" then
         return Category in Editor.Ada_Type_Graph.Type_Category_Floating |
                            Editor.Ada_Type_Graph.Type_Category_Fixed;
      else
         return False;
      end if;
   end Universal_Compatible_By_Category;

   function Operand_Subtype_From_Text
     (Static : Editor.Ada_Static_Expressions.Static_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Text   : String) return String
   is
      T : constant String := Trim (Text);
      N : constant String := Normalize (T);
      V : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
        Editor.Ada_Static_Expressions.Evaluate_Numeric_Expression (Static, Region, T);
   begin
      if T = "" then
         return "";
      elsif V.Status = Editor.Ada_Static_Expressions.Static_Value_Integer then
         return "Universal_Integer";
      elsif V.Status = Editor.Ada_Static_Expressions.Static_Value_Real then
         return "Universal_Real";
      elsif N = "true" or else N = "false" then
         return "Boolean";
      elsif N = "null" then
         return "universal_access";
      elsif Is_String_Literal (T) then
         return "String";
      elsif Is_Character_Literal_Text (T) then
         return "Character";
      else
         return "";
      end if;
   end Operand_Subtype_From_Text;

   procedure Apply_Conversion_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
     is separate;

   procedure Apply_Aggregate_Inference
     (Tree    : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Types   : Editor.Ada_Type_Graph.Type_Model;
      Info    : in out Expression_Type_Info;
      Node    : Editor.Ada_Syntax_Tree.Node_Info)
     is separate;

   procedure Apply_Operator_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
     is separate;

   function Lookup_Operand_Subtype_Text
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Text       : String) return String
     is separate;

   procedure Split_Concatenation_Text
     (Text  : String;
      Left  : out Ada.Strings.Unbounded.Unbounded_String;
      Right : out Ada.Strings.Unbounded.Unbounded_String)
     is separate;

   procedure Apply_Concatenation_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Info       : in out Expression_Type_Info)
     is separate;

   procedure Apply_Operator_Overload_Resolution
     (Regions        : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility     : Editor.Ada_Direct_Visibility.Visibility_Model;
      Primitives     : Editor.Ada_Use_Type_Operators.Primitive_Use_Model;
      Info           : in out Expression_Type_Info;
      Use_Primitives : Boolean)
     is separate;

   function Infer_One
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Node       : Editor.Ada_Syntax_Tree.Node_Info) return Expression_Type_Info;

   procedure Apply_Target_Name_Update_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
     is separate;

   function Declaration_Definition_Text
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return String
     renames Editor.Ada_Expression_Types.Access_Text_Helpers.Declaration_Definition_Text;

   function Starts_With (Text : String; Prefix : String) return Boolean
     renames Editor.Ada_Expression_Types.Access_Text_Helpers.Starts_With;

   function Drop_Prefix (Text : String; Length : Natural) return String
     renames Editor.Ada_Expression_Types.Access_Text_Helpers.Drop_Prefix;

   function Strip_Access_Qualifiers (Text : String) return String
     renames Editor.Ada_Expression_Types.Access_Text_Helpers.Strip_Access_Qualifiers;

   function Designated_Subtype_For_Access_Type
     (Tree  : Editor.Ada_Syntax_Tree.Tree_Type;
      Types : Editor.Ada_Type_Graph.Type_Model;
      Id    : Editor.Ada_Type_Graph.Type_Id) return String
     renames Editor.Ada_Expression_Types.Access_Text_Helpers.Designated_Subtype_For_Access_Type;

   function Object_Subtype_For_Name
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Name       : String;
      Declaration : out Editor.Ada_Direct_Visibility.Declaration_Id;
      Candidates  : out Natural) return String
     renames Editor.Ada_Expression_Types.Access_Text_Helpers.Object_Subtype_For_Name;

   function Allocator_Target_From_Text (Text : String) return String
     renames Editor.Ada_Expression_Types.Access_Text_Helpers.Allocator_Target_From_Text;

   function Expected_Access_Designated_Subtype (Expected : String) return String
     renames Editor.Ada_Expression_Types.Access_Text_Helpers.Expected_Access_Designated_Subtype;


   function Formal_List_Text (Label : String) return String
     renames Editor.Ada_Expression_Types.Call_Text_Helpers.Formal_List_Text;

   function Count_Names_In_Formal (Names : String) return Natural
     renames Editor.Ada_Expression_Types.Call_Text_Helpers.Count_Names_In_Formal;

   function Name_At_In_Formal (Names : String; Index : Positive) return String
     renames Editor.Ada_Expression_Types.Call_Text_Helpers.Name_At_In_Formal;

   function Clean_Formal_Subtype (Text : String) return String
     renames Editor.Ada_Expression_Types.Call_Text_Helpers.Clean_Formal_Subtype;

   function Formal_Subtype_By_Position (Callable_Label : String; Position : Positive) return String
     renames Editor.Ada_Expression_Types.Call_Text_Helpers.Formal_Subtype_By_Position;

   function Formal_Subtype_By_Name (Callable_Label : String; Name : String) return String
     renames Editor.Ada_Expression_Types.Call_Text_Helpers.Formal_Subtype_By_Name;

   function Named_Actual_Formal_Name (Text : String) return String
     renames Editor.Ada_Expression_Types.Call_Text_Helpers.Named_Actual_Formal_Name;

   function Actual_Expression_Text (Text : String) return String
     renames Editor.Ada_Expression_Types.Call_Text_Helpers.Actual_Expression_Text;

   function Infer_Text_Subtype
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Text       : String) return String
     renames Editor.Ada_Expression_Types.Call_Text_Helpers.Infer_Text_Subtype;

   function Actual_Position_In_Call
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Call : Editor.Ada_Syntax_Tree.Node_Id;
      Node : Editor.Ada_Syntax_Tree.Node_Info) return Natural
     renames Editor.Ada_Expression_Types.Call_Text_Helpers.Actual_Position_In_Call;

   function Callable_Result_Subtype (Callable_Label : String) return String
     renames Editor.Ada_Expression_Types.Call_Text_Helpers.Callable_Result_Subtype;

   function Is_Class_Wide_Subtype (Text : String) return Boolean
     renames Editor.Ada_Expression_Types.Call_Text_Helpers.Is_Class_Wide_Subtype;

   function Looks_Primitive_Call_Designator (Text : String) return Boolean
     renames Editor.Ada_Expression_Types.Call_Text_Helpers.Looks_Primitive_Call_Designator;

   procedure Apply_Call_Actual_Type_Resolution
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
     renames Editor.Ada_Expression_Types.Call_Inference.Apply_Call_Actual_Type_Resolution;



   procedure Apply_Dispatching_Call_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
     renames Editor.Ada_Expression_Types.Call_Inference.Apply_Dispatching_Call_Inference;


   procedure Apply_Parameter_Association_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
     renames Editor.Ada_Expression_Types.Call_Inference.Apply_Parameter_Association_Inference;



   function Is_Integer_Expected_Subtype (Text : String) return Boolean is
      N : constant String := Normalize (Text);
   begin
      return N = "integer" or else N = "natural" or else N = "positive" or else
        Contains (N, "integer") or else Contains (N, "natural") or else
        Contains (N, "positive") or else Contains (N, "count") or else
        Contains (N, "range");
   end Is_Integer_Expected_Subtype;

   function Is_Real_Expected_Subtype (Text : String) return Boolean is
      N : constant String := Normalize (Text);
   begin
      return N = "float" or else N = "long_float" or else N = "duration" or else
        Contains (N, "float") or else Contains (N, "real") or else
        Contains (N, "duration");
   end Is_Real_Expected_Subtype;

   function Has_Static_Integer_Bounds
     (Static : Editor.Ada_Static_Expressions.Static_Model;
      Text   : String) return Boolean
   is
      NText : constant String := Normalize (Text);
   begin
      for Index in 1 .. Editor.Ada_Static_Expressions.Static_Type_Bound_Count (Static) loop
         declare
            Bound : constant Editor.Ada_Static_Expressions.Static_Type_Bound_Info :=
              Editor.Ada_Static_Expressions.Static_Type_Bound_At (Static, Index);
         begin
            if To_String (Bound.Normalized_Name) = NText and then
              Editor.Ada_Static_Expressions.Is_Static_Integer (Bound.First_Value) and then
              Editor.Ada_Static_Expressions.Is_Static_Integer (Bound.Last_Value)
            then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Has_Static_Integer_Bounds;


   function Looks_Modular_Expected_Subtype
     (Static : Editor.Ada_Static_Expressions.Static_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Text   : String) return Boolean
   is
   begin
      return Editor.Ada_Static_Expressions.Lookup_Modular_Type (Static, Region, Text) /=
        Editor.Ada_Static_Expressions.No_Static_Modular_Type;
   end Looks_Modular_Expected_Subtype;

   function Looks_Fixed_Expected_Subtype
     (Static : Editor.Ada_Static_Expressions.Static_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Text   : String) return Boolean
   is
   begin
      return Editor.Ada_Static_Expressions.Lookup_Fixed_Type (Static, Region, Text) /=
        Editor.Ada_Static_Expressions.No_Static_Fixed_Type;
   end Looks_Fixed_Expected_Subtype;

   procedure Apply_Integer_Range_Metadata
     (Static : Editor.Ada_Static_Expressions.Static_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Expected : String;
      Value : Long_Long_Integer;
      Info : in out Expression_Type_Info)
   is
      pragma Unreferenced (Region);
      NExpected : constant String := Normalize (Expected);
   begin
      for Index in 1 .. Editor.Ada_Static_Expressions.Static_Type_Bound_Count (Static) loop
         declare
            Bound : constant Editor.Ada_Static_Expressions.Static_Type_Bound_Info :=
              Editor.Ada_Static_Expressions.Static_Type_Bound_At (Static, Index);
         begin
            if To_String (Bound.Normalized_Name) = NExpected and then
              Editor.Ada_Static_Expressions.Is_Static_Integer (Bound.First_Value) and then
              Editor.Ada_Static_Expressions.Is_Static_Integer (Bound.Last_Value)
            then
               Info.Universal_Numeric_Has_Range := True;
               Info.Universal_Numeric_First_Value := Bound.First_Value.Integer_Value;
               Info.Universal_Numeric_Last_Value := Bound.Last_Value.Integer_Value;
               if Value < Bound.First_Value.Integer_Value or else
                 Value > Bound.Last_Value.Integer_Value
               then
                  Info.Universal_Numeric_Status := Universal_Numeric_Range_Error;
                  Info.Expected_Status := Expected_Type_Mismatch;
               elsif Info.Universal_Numeric_Status /= Universal_Numeric_Range_Error then
                  Info.Universal_Numeric_Status := Universal_Numeric_Range_Compatible;
               end if;
               return;
            end if;
         end;
      end loop;
   end Apply_Integer_Range_Metadata;

   procedure Apply_Universal_Numeric_Resolution
     (Tree    : Editor.Ada_Syntax_Tree.Tree_Type;
      Static  : Editor.Ada_Static_Expressions.Static_Model;
      Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Info    : in out Expression_Type_Info;
      Node    : Editor.Ada_Syntax_Tree.Node_Info)
     is separate;

   procedure Apply_Allocator_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
     is separate;

   function Looks_Like_Raise_Text (Text : String) return Boolean is
      N : constant String := Normalize (Text);
   begin
      return Starts_With (N, "raise") or else Contains (N, " raise ");
   end Looks_Like_Raise_Text;

   function Raise_Target_From_Text (Text : String) return String is
      T : constant String := Trim (Text);
      N : constant String := Normalize (T);
      Start : Natural := 0;
      Stop  : Natural := 0;
      With_Pos : Natural := 0;
   begin
      if Starts_With (N, "raise") then
         Start := T'First + 5;
      else
         Start := Ada.Strings.Fixed.Index (N, " raise ");
         if Start = 0 then
            return "";
         end if;
         Start := Start + 7;
      end if;
      while Start <= T'Last and then T (Start) = ' ' loop
         Start := Start + 1;
      end loop;
      if Start > T'Last then
         return "";
      end if;
      With_Pos := Ada.Strings.Fixed.Index (N, " with ");
      if With_Pos /= 0 and then With_Pos > Start then
         Stop := With_Pos - 1;
      else
         Stop := T'Last;
      end if;
      return Trim (T (Start .. Stop));
   end Raise_Target_From_Text;

   function Raise_Message_From_Text (Text : String) return String is
      T : constant String := Trim (Text);
      N : constant String := Normalize (T);
      Pos : constant Natural := Ada.Strings.Fixed.Index (N, " with ");
   begin
      if Pos = 0 or else Pos + 6 > T'Last then
         return "";
      end if;
      return Trim (T (Pos + 6 .. T'Last));
   end Raise_Message_From_Text;

   function Looks_Like_Boolean_Context (Kind : Editor.Ada_Syntax_Tree.Node_Kind; Text : String) return Boolean is
      Lower : constant String := Normalize (Text);
   begin
      return Kind = Editor.Ada_Syntax_Tree.Node_Short_Circuit_Expression
        or else Kind = Editor.Ada_Syntax_Tree.Node_Quantified_Expression
        or else Contains (Lower, " and then ")
        or else Contains (Lower, " or else ")
        or else Contains (Lower, " not ")
        or else Contains (Lower, "if ")
        or else Contains (Lower, " while ")
        or else Contains (Lower, " when ")
        or else Contains (Lower, "exit when")
        or else Contains (Lower, "for all ")
        or else Contains (Lower, "for some ");
   end Looks_Like_Boolean_Context;

   function Boolean_Operand_Status (Subtype_Name : String) return Boolean_Context_Inference_Status is
      N : constant String := Normalize (Subtype_Name);
   begin
      if N = "boolean" or else N = "standard.boolean" then
         return Boolean_Context_Operand_Compatible;
      elsif N = "" or else N = "unknown" or else N = "indeterminate" then
         return Boolean_Context_Operand_Unknown;
      else
         return Boolean_Context_Operand_Mismatch;
      end if;
   end Boolean_Operand_Status;

   procedure Apply_Boolean_Context_Inference
     (Info : in out Expression_Type_Info;
      N    : Editor.Ada_Syntax_Tree.Node_Info)
     is separate;

   procedure Apply_Raise_No_Return_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
     is separate;

   procedure Apply_Dereference_Access_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
     is separate;

   procedure Apply_Indexed_Slice_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
     is separate;

   procedure Apply_Membership_Range_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
     is separate;

   procedure Apply_Conditional_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
     is separate;

   function Infer_One
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Node       : Editor.Ada_Syntax_Tree.Node_Info) return Expression_Type_Info
     is separate;

   procedure Clear (Model : in out Expression_Type_Model) is
   begin
      Model.Expressions.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;


   function Build_Internal
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Selected   : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
      Use_Selected : Boolean;
      Expected   : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model;
      Use_Expected : Boolean;
      Primitives : Editor.Ada_Use_Type_Operators.Primitive_Use_Model;
      Use_Primitives : Boolean)
      return Expression_Type_Model
     is separate;

   function Build_With_Selected_Names
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Selected   : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model)
      return Expression_Type_Model
   is
      Empty_Expected : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model;
      Empty_Primitives : Editor.Ada_Use_Type_Operators.Primitive_Use_Model;
   begin
      return Build_Internal
        (Tree, Regions, Visibility, Types, Static, Calls, Selected, True,
         Empty_Expected, False, Empty_Primitives, False);
   end Build_With_Selected_Names;

   function Build_With_Selected_Names_And_Expected
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Selected   : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
      Expected   : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model)
      return Expression_Type_Model
   is
      Empty_Primitives : Editor.Ada_Use_Type_Operators.Primitive_Use_Model;
   begin
      return Build_Internal
        (Tree, Regions, Visibility, Types, Static, Calls, Selected, True,
         Expected, True, Empty_Primitives, False);
   end Build_With_Selected_Names_And_Expected;


   function Build_With_Cross_Unit_Selected_Names
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Selected   : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model)
      return Expression_Type_Model
   is
   begin
      return Build_With_Selected_Names
        (Tree, Regions, Visibility, Types, Static, Calls, Selected);
   end Build_With_Cross_Unit_Selected_Names;

   function Build_With_Cross_Unit_Selected_Names_And_Expected
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Selected   : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
      Expected   : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model)
      return Expression_Type_Model
   is
   begin
      return Build_With_Selected_Names_And_Expected
        (Tree, Regions, Visibility, Types, Static, Calls, Selected, Expected);
   end Build_With_Cross_Unit_Selected_Names_And_Expected;

   function Build_With_Cross_Unit_Selected_Names_Operator_Uses_And_Expected
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Selected   : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
      Primitives : Editor.Ada_Use_Type_Operators.Primitive_Use_Model;
      Expected   : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model)
      return Expression_Type_Model
   is
   begin
      return Build_Internal
        (Tree, Regions, Visibility, Types, Static, Calls, Selected, True,
         Expected, True, Primitives, True);
   end Build_With_Cross_Unit_Selected_Names_Operator_Uses_And_Expected;

   function Cross_Unit_Selected_Subtype
     (Index    : Editor.Ada_Project_Index.Index_State;
      Path     : String;
      Selector : String) return String
     renames Editor.Ada_Expression_Types.Cross_Unit_Selected_Subtype_Refinement.Cross_Unit_Selected_Subtype;

   procedure Refine_Project_Cross_Unit_Selected_Subtypes
     (Model : in out Expression_Type_Model;
      Index : Editor.Ada_Project_Index.Index_State)
   is
      Refined : Expression_Type_Model;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         declare
            Info : Expression_Type_Info := Model.Expressions.Element (I);
            Subtype_Text : constant String :=
              Cross_Unit_Selected_Subtype
                (Index,
                 To_String (Info.Cross_Unit_Selected_Path),
                 To_String (Info.Cross_Unit_Selected_Selector));
         begin
            if Info.Status = Expression_Type_Selected_Name_Cross_Unit_Resolved
              and then Subtype_Text'Length > 0
            then
               Info.Inferred_Subtype := To_Unbounded_String (Subtype_Text);
               Info.Normalized_Subtype :=
                 To_Unbounded_String (Normalize (Subtype_Text));
            end if;

            Append (Refined, Info);
         end;
      end loop;

      Model := Refined;
   end Refine_Project_Cross_Unit_Selected_Subtypes;

   procedure Propagate_Project_Wrapper_Subtypes
     (Model : in out Expression_Type_Model;
      Tree  : Editor.Ada_Syntax_Tree.Tree_Type)
   is
      function Wrapper_Can_Inherit
        (Kind : Editor.Ada_Syntax_Tree.Node_Kind) return Boolean is
      begin
         return Kind = Editor.Ada_Syntax_Tree.Node_Expression
           or else Kind = Editor.Ada_Syntax_Tree.Node_Parenthesized_Expression;
      end Wrapper_Can_Inherit;
   begin
      for Pass in 1 .. 3 loop
         declare
            Source  : constant Expression_Type_Model := Model;
            Refined : Expression_Type_Model;
         begin
            for I in 1 .. Natural (Source.Expressions.Length) loop
               declare
                  Info : Expression_Type_Info := Source.Expressions.Element (I);
                  Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
                    Editor.Ada_Syntax_Tree.Node (Tree, Info.Node);
                  Child_Info : Expression_Type_Info := (others => <>);
                  Candidate_Count : Natural := 0;
               begin
                  if Wrapper_Can_Inherit (Node.Kind)
                    and then (To_String (Info.Normalized_Subtype) = ""
                              or else Info.Expected_Status = Expected_Type_Propagated)
                  then
                     for Child_Index in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Node.Id) loop
                        declare
                           Child_Id : constant Editor.Ada_Syntax_Tree.Node_Id :=
                             Editor.Ada_Syntax_Tree.Child_At
                               (Tree, Node.Id, Child_Index);
                           Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
                             Editor.Ada_Syntax_Tree.Node (Tree, Child_Id);
                           Candidate : constant Expression_Type_Info :=
                             Expression_Type_For_Node (Source, Child_Id);
                        begin
                           if Child.Kind in Editor.Ada_Syntax_Tree.Node_Expression ..
                             Editor.Ada_Syntax_Tree.Node_Allocator
                             and then To_String (Candidate.Normalized_Subtype) /= ""
                           then
                              Candidate_Count := Candidate_Count + 1;
                              Child_Info := Candidate;
                           end if;
                        end;
                     end loop;

                     if Candidate_Count = 1 then
                        Info.Status := Child_Info.Status;
                        Info.Inferred_Subtype := Child_Info.Inferred_Subtype;
                        Info.Normalized_Subtype := Child_Info.Normalized_Subtype;
                        if To_String (Info.Normalized_Expected_Subtype) /= "" then
                           if To_String (Info.Normalized_Subtype) =
                             To_String (Info.Normalized_Expected_Subtype)
                             or else Is_Universal_Compatible
                               (To_String (Info.Normalized_Subtype),
                                To_String (Info.Normalized_Expected_Subtype))
                           then
                              Info.Expected_Status := Expected_Type_Compatible;
                           else
                              Info.Expected_Status := Expected_Type_Mismatch;
                           end if;
                        end if;
                     end if;
                  end if;

                  Append (Refined, Info);
               end;
            end loop;

            Model := Refined;
         end;
      end loop;
   end Propagate_Project_Wrapper_Subtypes;

   function Build_With_Project_Cross_Unit_Selected_Names_Operator_Uses_And_Expected
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Selected   : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
      Primitives : Editor.Ada_Use_Type_Operators.Primitive_Use_Model;
      Expected   : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model;
      Index      : Editor.Ada_Project_Index.Index_State)
      return Expression_Type_Model
   is
      Model : Expression_Type_Model :=
        Build_With_Cross_Unit_Selected_Names_Operator_Uses_And_Expected
          (Tree, Regions, Visibility, Types, Static, Calls, Selected,
           Primitives, Expected);
   begin
      Refine_Project_Cross_Unit_Selected_Subtypes (Model, Index);
      Propagate_Project_Wrapper_Subtypes (Model, Tree);
      return Model;
   end Build_With_Project_Cross_Unit_Selected_Names_Operator_Uses_And_Expected;

   function Build_With_Operator_Uses
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Primitives : Editor.Ada_Use_Type_Operators.Primitive_Use_Model)
      return Expression_Type_Model
   is
      Empty_Selected : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
      Empty_Expected : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model;
   begin
      return Build_Internal
        (Tree, Regions, Visibility, Types, Static, Calls, Empty_Selected, False,
         Empty_Expected, False, Primitives, True);
   end Build_With_Operator_Uses;

   function Build_With_Operator_Uses_And_Expected
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Primitives : Editor.Ada_Use_Type_Operators.Primitive_Use_Model;
      Expected   : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model)
      return Expression_Type_Model
   is
      Empty_Selected : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
   begin
      return Build_Internal
        (Tree, Regions, Visibility, Types, Static, Calls, Empty_Selected, False,
         Expected, True, Primitives, True);
   end Build_With_Operator_Uses_And_Expected;

   function Build_With_Expected_Contexts
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Expected   : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model)
      return Expression_Type_Model
   is
      Empty_Selected : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
      Empty_Primitives : Editor.Ada_Use_Type_Operators.Primitive_Use_Model;
   begin
      return Build_Internal
        (Tree, Regions, Visibility, Types, Static, Calls, Empty_Selected, False,
         Expected, True, Empty_Primitives, False);
   end Build_With_Expected_Contexts;

   function Build
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model)
      return Expression_Type_Model
   is
      Empty_Selected : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
      Empty_Expected : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model;
      Empty_Primitives : Editor.Ada_Use_Type_Operators.Primitive_Use_Model;
   begin
      return Build_Internal
        (Tree, Regions, Visibility, Types, Static, Calls, Empty_Selected, False,
         Empty_Expected, False, Empty_Primitives, False);
   end Build;

   function Has_Expression_Types (Model : Expression_Type_Model) return Boolean is
   begin
      return Editor.Ada_Expression_Types.Model_Accessors.Has_Expression_Types (Model);
   end Has_Expression_Types;

   function Expression_Type_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Editor.Ada_Expression_Types.Model_Accessors.Expression_Type_Count (Model);
   end Expression_Type_Count;

   function Expression_Type_At
     (Model : Expression_Type_Model;
      Index : Positive) return Expression_Type_Info is
   begin
      return Editor.Ada_Expression_Types.Model_Accessors.Expression_Type_At
        (Model, Index);
   end Expression_Type_At;

   function Expression_Type
     (Model : Expression_Type_Model;
      Id    : Expression_Type_Id) return Expression_Type_Info is
   begin
      return Editor.Ada_Expression_Types.Model_Accessors.Expression_Type
        (Model, Id);
   end Expression_Type;

   function Expression_Type_For_Node
     (Model : Expression_Type_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Expression_Type_Info is
   begin
      return Editor.Ada_Expression_Types.Model_Accessors.Expression_Type_For_Node
        (Model, Node);
   end Expression_Type_For_Node;

   function Count_Status
     (Model  : Expression_Type_Model;
      Status : Expression_Type_Status) return Natural
   is
   begin
      return Editor.Ada_Expression_Types.Model_Accessors.Count_Status
        (Model, Status);
   end Count_Status;

   function Resolved_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Resolved_Count;
   function Unresolved_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Unresolved_Count;
   function Ambiguous_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Ambiguous_Count;
   function Static_Numeric_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Static_Numeric_Count;
   function Operator_Unknown_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Operator_Unknown_Count;
   function Cross_Unit_Selected_Name_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Cross_Unit_Selected_Name_Count;
   function Cross_Unit_Selected_Name_Resolved_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Cross_Unit_Selected_Name_Resolved_Count;
   function Cross_Unit_Selected_Name_Limited_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Cross_Unit_Selected_Name_Limited_Count;
   function Cross_Unit_Selected_Name_Private_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Cross_Unit_Selected_Name_Private_Count;
   function Cross_Unit_Selected_Name_Unresolved_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Cross_Unit_Selected_Name_Unresolved_Count;
   function Expected_Context_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Expected_Context_Count;
   function Expected_Propagated_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Expected_Propagated_Count;
   function Expected_Mismatch_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Expected_Mismatch_Count;
   function Expected_Unknown_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Expected_Unknown_Count;
   function Operator_Resolved_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Operator_Resolved_Count;
   function Operator_Operand_Mismatch_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Operator_Operand_Mismatch_Count;
   function Operator_Operand_Unknown_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Operator_Operand_Unknown_Count;
   function Operator_Ambiguous_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Operator_Ambiguous_Count;
   function Operator_Overload_Resolved_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Operator_Overload_Resolved_Count;
   function Operator_Overload_Ambiguous_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Operator_Overload_Ambiguous_Count;
   function Operator_Overload_Mismatch_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Operator_Overload_Mismatch_Count;
   function Operator_Overload_Unknown_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Operator_Overload_Unknown_Count;
   function Concatenation_Resolved_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Concatenation_Resolved_Count;
   function Concatenation_String_Result_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Concatenation_String_Result_Count;
   function Concatenation_Array_Result_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Concatenation_Array_Result_Count;
   function Concatenation_Mismatch_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Concatenation_Mismatch_Count;
   function Concatenation_Unknown_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Concatenation_Unknown_Count;
   function Aggregate_Context_Required_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Aggregate_Context_Required_Count;
   function Aggregate_Context_Resolved_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Aggregate_Context_Resolved_Count;
   function Aggregate_Record_Component_Compatible_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Aggregate_Record_Component_Compatible_Count;
   function Aggregate_Record_Component_Missing_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Aggregate_Record_Component_Missing_Count;
   function Aggregate_Record_Component_Duplicate_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Aggregate_Record_Component_Duplicate_Count;
   function Aggregate_Array_Element_Compatible_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Aggregate_Array_Element_Compatible_Count;
   function Aggregate_Array_Element_Mismatch_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Aggregate_Array_Element_Mismatch_Count;
   function Aggregate_Array_Element_Unknown_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Aggregate_Array_Element_Unknown_Count;
   function Aggregate_Mismatch_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Aggregate_Mismatch_Count;
   function Aggregate_Unknown_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Aggregate_Unknown_Count;
   function Conversion_Target_Resolved_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Conversion_Target_Resolved_Count;
   function Conversion_Compatible_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Conversion_Compatible_Count;
   function Conversion_Explicit_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Conversion_Explicit_Count;
   function Conversion_Mismatch_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Conversion_Mismatch_Count;
   function Conversion_Unknown_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Conversion_Unknown_Count;
   function Conditional_Resolved_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Conditional_Resolved_Count;
   function Conditional_Branch_Mismatch_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Conditional_Branch_Mismatch_Count;
   function Conditional_Branch_Unknown_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Conditional_Branch_Unknown_Count;
   function Conditional_Reduction_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Conditional_Reduction_Count;
   function Conditional_Declare_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Conditional_Declare_Count;
   function Membership_Resolved_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Membership_Resolved_Count;
   function Membership_Mismatch_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Membership_Mismatch_Count;
   function Membership_Unknown_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Membership_Unknown_Count;
   function Range_Resolved_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Range_Resolved_Count;
   function Range_Mismatch_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Range_Mismatch_Count;
   function Range_Unknown_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Range_Unknown_Count;
   function Target_Name_Context_Propagated_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Target_Name_Context_Propagated_Count;
   function Target_Name_Context_Required_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Target_Name_Context_Required_Count;
   function Target_Name_Update_Compatible_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Target_Name_Update_Compatible_Count;
   function Target_Name_Update_Mismatch_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Target_Name_Update_Mismatch_Count;
   function Target_Name_Update_Unknown_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Target_Name_Update_Unknown_Count;
   function Indexed_Slice_Prefix_Resolved_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Indexed_Slice_Prefix_Resolved_Count;
   function Indexed_Slice_Index_Compatible_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Indexed_Slice_Index_Compatible_Count;
   function Indexed_Slice_Index_Mismatch_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Indexed_Slice_Index_Mismatch_Count;
   function Indexed_Slice_Index_Unknown_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Indexed_Slice_Index_Unknown_Count;
   function Indexed_Slice_Result_Element_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Indexed_Slice_Result_Element_Count;
   function Indexed_Slice_Result_Array_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Indexed_Slice_Result_Array_Count;
   function Dereference_Resolved_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Dereference_Resolved_Count;
   function Dereference_Target_Error_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Dereference_Target_Error_Count;
   function Dereference_Unknown_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Dereference_Unknown_Count;
   function Access_Result_Resolved_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Access_Result_Resolved_Count;
   function Access_Result_Unknown_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Access_Result_Unknown_Count;
   function Allocator_Resolved_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Allocator_Resolved_Count;
   function Allocator_Target_Error_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Allocator_Target_Error_Count;
   function Allocator_Designated_Resolved_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Allocator_Designated_Resolved_Count;
   function Allocator_Unknown_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Allocator_Unknown_Count;
   function Universal_Numeric_Resolved_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Universal_Numeric_Resolved_Count;
   function Universal_Numeric_Range_Error_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Universal_Numeric_Range_Error_Count;
   function Universal_Numeric_Mismatch_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Universal_Numeric_Mismatch_Count;
   function Universal_Numeric_Unknown_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Universal_Numeric_Unknown_Count;
   function Boolean_Context_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Boolean_Context_Count;
   function Boolean_Context_Compatible_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Boolean_Context_Compatible_Count;
   function Boolean_Context_Mismatch_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Boolean_Context_Mismatch_Count;
   function Boolean_Context_Unknown_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Boolean_Context_Unknown_Count;
   function Raise_Expression_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Raise_Expression_Count;
   function Raise_No_Return_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Raise_No_Return_Count;
   function Raise_Message_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Raise_Message_Count;
   function Raise_Unknown_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Raise_Unknown_Count;
   function Call_Actual_Type_Compatible_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Call_Actual_Type_Compatible_Count;
   function Call_Actual_Type_Mismatch_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Call_Actual_Type_Mismatch_Count;
   function Call_Actual_Type_Unknown_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Call_Actual_Type_Unknown_Count;
   function Call_Actual_Type_Ambiguous_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Call_Actual_Type_Ambiguous_Count;
   function Dispatching_Call_Resolved_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Dispatching_Call_Resolved_Count;
   function Dispatching_Call_Dynamic_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Dispatching_Call_Dynamic_Count;
   function Dispatching_Call_Static_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Dispatching_Call_Static_Count;
   function Dispatching_Call_Ambiguous_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Dispatching_Call_Ambiguous_Count;
   function Dispatching_Call_Unknown_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Dispatching_Call_Unknown_Count;
   function Parameter_Association_Context_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Parameter_Association_Context_Count;
   function Parameter_Association_Propagated_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Parameter_Association_Propagated_Count;
   function Parameter_Association_Mismatch_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Parameter_Association_Mismatch_Count;
   function Parameter_Association_Unknown_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Parameter_Association_Unknown_Count;
   function Attribute_Resolved_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Attribute_Resolved_Count;
   function Attribute_Static_Result_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Attribute_Static_Result_Count;
   function Attribute_String_Result_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Attribute_String_Result_Count;
   function Attribute_Unknown_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Attribute_Unknown_Count;
   function Attribute_Prefix_Unresolved_Count (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Attribute_Prefix_Unresolved_Count;
   function Fingerprint (Model : Expression_Type_Model) return Natural
     renames Editor.Ada_Expression_Types.Statistics.Fingerprint;

end Editor.Ada_Expression_Types;
