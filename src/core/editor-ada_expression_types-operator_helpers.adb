with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Expression_Types.Inference_Support;
with Editor.Ada_Expression_Types.Status_Helpers;

package body Editor.Ada_Expression_Types.Operator_Helpers is

   use type Editor.Ada_Declarative_Regions.Region_Id;
   use type Editor.Ada_Type_Graph.Type_Id;
   use type Editor.Ada_Type_Graph.Type_Category;

   function Trim (Text : String) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Trim;

   function Normalize (Text : String) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Normalize;

   function Contains (Text : String; Pattern : String) return Boolean
     renames Editor.Ada_Expression_Types.Status_Helpers.Contains;

   function Is_Universal_Compatible (Actual : String; Expected : String) return Boolean
     renames Editor.Ada_Expression_Types.Inference_Support.Is_Universal_Compatible;

   function Operator_Symbol_From_Text (Text : String) return String is
      T : constant String := Normalize (Text);
   begin
      if Contains (T, " and then ") then return "and then"; end if;
      if Contains (T, " or else ") then return "or else"; end if;
      if Contains (T, " and ") then return "and"; end if;
      if Contains (T, " or ") then return "or"; end if;
      if Contains (T, " xor ") then return "xor"; end if;
      if Contains (T, " not ") or else (T'Length >= 3 and then T (T'First .. T'First + 2) = "not") then return "not"; end if;
      if Contains (T, " /= ") or else Contains (T, "/=") then return "/="; end if;
      if Contains (T, " <= ") or else Contains (T, "<=") then return "<="; end if;
      if Contains (T, " >= ") or else Contains (T, ">=") then return ">="; end if;
      if Contains (T, " < ") then return "<"; end if;
      if Contains (T, " > ") then return ">"; end if;
      if Contains (T, " = ") then return "="; end if;
      if Contains (T, " mod ") then return "mod"; end if;
      if Contains (T, " rem ") then return "rem"; end if;
      if Contains (T, " ** ") or else Contains (T, "**") then return "**"; end if;
      if Contains (T, " * ") then return "*"; end if;
      if Contains (T, " / ") then return "/"; end if;
      if Contains (T, " & ") or else Contains (T, "&") then return "&"; end if;
      if Contains (T, " + ") or else (T'Length > 1 and then T (T'First) = '+') then return "+"; end if;
      if Contains (T, " - ") or else (T'Length > 1 and then T (T'First) = '-') then return "-"; end if;
      if Contains (T, " in ") or else Contains (T, " not in ") then return "in"; end if;
      return "";
   end Operator_Symbol_From_Text;

   function Is_Relational_Operator (Symbol : String) return Boolean is
      S : constant String := Normalize (Symbol);
   begin
      return S = "=" or else S = "/=" or else S = "<" or else S = "<=" or else
        S = ">" or else S = ">=" or else S = "in";
   end Is_Relational_Operator;

   function Is_Boolean_Operator (Symbol : String) return Boolean is
      S : constant String := Normalize (Symbol);
   begin
      return S = "and" or else S = "or" or else S = "xor" or else
        S = "and then" or else S = "or else" or else S = "not";
   end Is_Boolean_Operator;

   function Is_Numeric_Operator (Symbol : String) return Boolean is
      S : constant String := Normalize (Symbol);
   begin
      return S = "+" or else S = "-" or else S = "*" or else S = "/" or else
        S = "mod" or else S = "rem" or else S = "**";
   end Is_Numeric_Operator;

   function Is_Integer_Family (Subtype_Name : String) return Boolean is
      S : constant String := Normalize (Subtype_Name);
   begin
      return S = "integer" or else S = "natural" or else S = "positive" or else
        S = "universal_integer" or else Contains (S, "integer") or else
        Contains (S, "natural") or else Contains (S, "positive");
   end Is_Integer_Family;

   function Is_Real_Family (Subtype_Name : String) return Boolean is
      S : constant String := Normalize (Subtype_Name);
   begin
      return S = "float" or else S = "long_float" or else S = "universal_real" or else
        S = "duration" or else Contains (S, "float") or else Contains (S, "real") or else
        Contains (S, "duration");
   end Is_Real_Family;

   function Is_Numeric_Family (Subtype_Name : String) return Boolean is
   begin
      return Is_Integer_Family (Subtype_Name) or else Is_Real_Family (Subtype_Name);
   end Is_Numeric_Family;

   function Is_String_Family (Subtype_Name : String) return Boolean is
      S : constant String := Normalize (Subtype_Name);
   begin
      return S = "string" or else S = "wide_string" or else
        S = "wide_wide_string" or else Contains (S, "string");
   end Is_String_Family;

   function Is_Character_Family (Subtype_Name : String) return Boolean is
      S : constant String := Normalize (Subtype_Name);
   begin
      return S = "character" or else S = "wide_character" or else
        S = "wide_wide_character" or else Contains (S, "character");
   end Is_Character_Family;

   function Is_Array_Family
     (Types   : Editor.Ada_Type_Graph.Type_Model;
      Region  : Editor.Ada_Declarative_Regions.Region_Id;
      Subtype_Name : String) return Boolean
   is
      T : constant Editor.Ada_Type_Graph.Type_Id :=
        Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Subtype_Name);
   begin
      if Is_String_Family (Subtype_Name) then
         return True;
      elsif T = Editor.Ada_Type_Graph.No_Type then
         return Contains (Normalize (Subtype_Name), "array");
      else
         return Editor.Ada_Type_Graph.Type_Node (Types, T).Category =
           Editor.Ada_Type_Graph.Type_Category_Array;
      end if;
   end Is_Array_Family;

   function Simple_Subtype_Compatible (Left : String; Right : String) return Boolean is
      NL : constant String := Normalize (Left);
      NR : constant String := Normalize (Right);
   begin
      return (NL /= "" and then NL = NR) or else
        (Is_Numeric_Family (Left) and then Is_Numeric_Family (Right)) or else
        Is_Universal_Compatible (NL, NR) or else Is_Universal_Compatible (NR, NL);
   end Simple_Subtype_Compatible;

   function Looks_Range_Choice (Text : String) return Boolean is
      T : constant String := Normalize (Text);
   begin
      return Contains (T, " .. ") or else Contains (T, " range ") or else
        Contains (T, "'range") or else Contains (T, "..");
   end Looks_Range_Choice;

   procedure Set_Boolean_Result (Info : in out Expression_Type_Info) is
   begin
      Info.Status := Expression_Type_Operator_Boolean;
      Info.Inferred_Subtype := To_Unbounded_String ("Boolean");
      Info.Normalized_Subtype := To_Unbounded_String ("boolean");
      Info.Operator_Result_Subtype := To_Unbounded_String ("Boolean");
      Info.Normalized_Operator_Result_Subtype := To_Unbounded_String ("boolean");
   end Set_Boolean_Result;

end Editor.Ada_Expression_Types.Operator_Helpers;
