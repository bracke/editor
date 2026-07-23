with Ada.Strings.Unbounded;
with Editor.Ada_Expression_Types.Status_Helpers;
with Editor.Ada_Declarative_Regions;
with Editor.Ada_Expected_Type_Contexts;
with Editor.Ada_Selected_Name_Resolution;
with Editor.Ada_Static_Expressions;
with Editor.Ada_Syntax_Tree;

package body Editor.Ada_Expression_Types.Inference_Support is

   use type Editor.Ada_Expected_Type_Contexts.Expected_Context_Id;
   use type Editor.Ada_Expected_Type_Contexts.Expected_Context_Status;
   use type Editor.Ada_Declarative_Regions.Region_Id;
   use type Editor.Ada_Syntax_Tree.Node_Kind;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Expression_Type_Status;

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

   use Editor.Ada_Expression_Types.Status_Helpers;

   function Fingerprint_For (Info : Expression_Type_Info) return Natural is
   begin
      return Hash_Text
        (Natural'Image (Natural (Info.Node)) & ":" &
         Status_Text (Info.Status) & ":" &
         To_String (Info.Normalized_Text) & ":" &
         To_String (Info.Normalized_Subtype) & ":" &
         Natural'Image (Natural (Info.Selected_Name)) & ":" &
         Editor.Ada_Selected_Name_Resolution.Selected_Name_Status'Image (Info.Selected_Name_Status) & ":" &
         To_String (Info.Normalized_Cross_Unit_Selected_Target) & ":" &
         To_String (Info.Normalized_Cross_Unit_Selected_Selector) & ":" &
         Expected_Status_Text (Info.Expected_Status) & ":" &
         To_String (Info.Normalized_Expected_Subtype) & ":" &
         Operator_Status_Text (Info.Operator_Status) & ":" &
         To_String (Info.Operator_Symbol) & ":" &
         To_String (Info.Normalized_Left_Operand_Subtype) & ":" &
         To_String (Info.Normalized_Right_Operand_Subtype) & ":" &
         To_String (Info.Normalized_Operator_Result_Subtype) & ":" &
         Natural'Image (Info.Operator_Compatible_Operand_Count) & ":" &
         Natural'Image (Info.Operator_Mismatched_Operand_Count) & ":" &
         Natural'Image (Info.Operator_Unknown_Operand_Count) & ":" &
         Natural'Image (Info.Operator_Overload_Candidate_Count) & ":" &
         Natural'Image (Info.Operator_Overload_Selected_Count) & ":" &
         Natural'Image (Info.Operator_Overload_Ambiguous_Count) & ":" &
         Natural'Image (Info.Operator_Overload_Mismatch_Count) & ":" &
         Concatenation_Status_Text (Info.Concatenation_Status) & ":" &
         To_String (Info.Normalized_Concatenation_Left_Subtype) & ":" &
         To_String (Info.Normalized_Concatenation_Right_Subtype) & ":" &
         To_String (Info.Normalized_Concatenation_Result_Subtype) & ":" &
         Natural'Image (Info.Concatenation_Compatible_Count) & ":" &
         Natural'Image (Info.Concatenation_Mismatch_Count) & ":" &
         Natural'Image (Info.Concatenation_Unknown_Count) & ":" &
         Aggregate_Status_Text (Info.Aggregate_Status) & ":" &
         To_String (Info.Normalized_Aggregate_Element_Subtype) & ":" &
         To_String (Info.Normalized_Aggregate_Index_Subtype) & ":" &
         Natural'Image (Info.Aggregate_Component_Count) & ":" &
         Natural'Image (Info.Aggregate_Named_Association_Count) & ":" &
         Natural'Image (Info.Aggregate_Positional_Association_Count) & ":" &
         Natural'Image (Info.Aggregate_Record_Component_Compatible_Count) & ":" &
         Natural'Image (Info.Aggregate_Record_Component_Missing_Count) & ":" &
         Natural'Image (Info.Aggregate_Record_Component_Duplicate_Count) & ":" &
         Natural'Image (Info.Aggregate_Array_Element_Compatible_Count) & ":" &
         Natural'Image (Info.Aggregate_Array_Element_Mismatch_Count) & ":" &
         Natural'Image (Info.Aggregate_Array_Element_Unknown_Count) & ":" &
         Natural'Image (Info.Aggregate_Mismatch_Count) & ":" &
         Natural'Image (Info.Aggregate_Unknown_Count) & ":" &
         Conversion_Status_Text (Info.Conversion_Status) & ":" &
         To_String (Info.Normalized_Conversion_Target_Subtype) & ":" &
         To_String (Info.Normalized_Conversion_Operand_Subtype) & ":" &
         Natural'Image (Info.Conversion_Compatible_Operand_Count) & ":" &
         Natural'Image (Info.Conversion_Explicit_Operand_Count) & ":" &
         Natural'Image (Info.Conversion_Mismatched_Operand_Count) & ":" &
         Natural'Image (Info.Conversion_Unknown_Operand_Count) & ":" &
         Conditional_Status_Text (Info.Conditional_Status) & ":" &
         Natural'Image (Info.Conditional_Branch_Count) & ":" &
         Natural'Image (Info.Conditional_Compatible_Branch_Count) & ":" &
         Natural'Image (Info.Conditional_Mismatched_Branch_Count) & ":" &
         Natural'Image (Info.Conditional_Unknown_Branch_Count) & ":" &
         To_String (Info.Normalized_Conditional_Result_Subtype) & ":" &
         Membership_Range_Status_Text (Info.Membership_Range_Status) & ":" &
         To_String (Info.Normalized_Membership_Test_Subtype) & ":" &
         To_String (Info.Normalized_Membership_Choice_Subtype) & ":" &
         To_String (Info.Normalized_Range_Low_Subtype) & ":" &
         To_String (Info.Normalized_Range_High_Subtype) & ":" &
         Natural'Image (Info.Membership_Compatible_Count) & ":" &
         Natural'Image (Info.Membership_Mismatch_Count) & ":" &
         Natural'Image (Info.Membership_Unknown_Count) & ":" &
         Natural'Image (Info.Range_Compatible_Count) & ":" &
         Natural'Image (Info.Range_Mismatch_Count) & ":" &
         Natural'Image (Info.Range_Unknown_Count) & ":" &
         Target_Name_Status_Text (Info.Target_Name_Status) & ":" &
         To_String (Info.Normalized_Target_Name_Expected_Subtype) & ":" &
         To_String (Info.Normalized_Target_Name_Source_Subtype) & ":" &
         Natural'Image (Info.Target_Name_Compatible_Count) & ":" &
         Natural'Image (Info.Target_Name_Mismatch_Count) & ":" &
         Natural'Image (Info.Target_Name_Unknown_Count) & ":" &
         Natural'Image (Info.Delta_Update_Count) & ":" &
         Indexed_Slice_Status_Text (Info.Indexed_Slice_Status) & ":" &
         To_String (Info.Normalized_Indexed_Slice_Prefix_Subtype) & ":" &
         To_String (Info.Normalized_Indexed_Slice_Index_Subtype) & ":" &
         To_String (Info.Normalized_Indexed_Slice_Result_Subtype) & ":" &
         Natural'Image (Info.Indexed_Slice_Index_Count) & ":" &
         Natural'Image (Info.Indexed_Slice_Compatible_Index_Count) & ":" &
         Natural'Image (Info.Indexed_Slice_Mismatched_Index_Count) & ":" &
         Natural'Image (Info.Indexed_Slice_Unknown_Index_Count) & ":" &
         Boolean_Context_Status_Text (Info.Boolean_Context_Status) & ":" &
         To_String (Info.Normalized_Boolean_Context_Expression_Subtype) & ":" &
         To_String (Info.Normalized_Boolean_Context_Expected_Subtype) & ":" &
         Natural'Image (Info.Boolean_Context_Compatible_Count) & ":" &
         Natural'Image (Info.Boolean_Context_Mismatch_Count) & ":" &
         Natural'Image (Info.Boolean_Context_Unknown_Count) & ":" &
         Dereference_Access_Status_Text (Info.Dereference_Access_Status) & ":" &
         To_String (Info.Normalized_Dereference_Prefix_Subtype) & ":" &
         To_String (Info.Normalized_Dereference_Designated_Subtype) & ":" &
         To_String (Info.Normalized_Access_Target_Subtype) & ":" &
         To_String (Info.Normalized_Access_Result_Subtype) & ":" &
         Allocator_Status_Text (Info.Allocator_Status) & ":" &
         To_String (Info.Normalized_Allocator_Target_Subtype) & ":" &
         To_String (Info.Normalized_Allocator_Expected_Access_Subtype) & ":" &
         To_String (Info.Normalized_Allocator_Designated_Subtype) & ":" &
         To_String (Info.Normalized_Allocator_Result_Subtype) & ":" &
         Raise_No_Return_Status_Text (Info.Raise_No_Return_Status) & ":" &
         To_String (Info.Normalized_Raise_Exception_Target) & ":" &
         To_String (Info.Normalized_Raise_Message_Subtype) & ":" &
         To_String (Info.Normalized_Raise_Result_Subtype) & ":" &
         Universal_Numeric_Status_Text (Info.Universal_Numeric_Status) & ":" &
         To_String (Info.Normalized_Universal_Numeric_Expected_Subtype) & ":" &
         To_String (Info.Normalized_Universal_Numeric_Result_Subtype) & ":" &
         Editor.Ada_Static_Expressions.Static_Value_Status'Image
           (Info.Universal_Numeric_Static_Status) & ":" &
         Long_Long_Integer'Image (Info.Universal_Numeric_Integer_Value) & ":" &
         Long_Float'Image (Info.Universal_Numeric_Real_Value) & ":" &
         Call_Actual_Type_Status_Text (Info.Call_Actual_Type_Status) & ":" &
         Natural'Image (Info.Call_Actual_Type_Compatible_Count) & ":" &
         Natural'Image (Info.Call_Actual_Type_Mismatch_Count) & ":" &
         Natural'Image (Info.Call_Actual_Type_Unknown_Count) & ":" &
         Natural'Image (Info.Call_Actual_Type_Candidate_Count) & ":" &
         Dispatching_Call_Status_Text (Info.Dispatching_Call_Status) & ":" &
         To_String (Info.Normalized_Dispatching_Call_Controlling_Subtype) & ":" &
         To_String (Info.Normalized_Dispatching_Call_Result_Subtype) & ":" &
         Natural'Image (Info.Dispatching_Call_Primitive_Count) & ":" &
         Natural'Image (Info.Dispatching_Call_Controlling_Operand_Count) & ":" &
         Natural'Image (Info.Dispatching_Call_Controlling_Result_Count) & ":" &
         Natural'Image (Info.Dispatching_Call_Ambiguous_Count) & ":" &
         Natural'Image (Info.Dispatching_Call_Unknown_Count) & ":" &
         Parameter_Association_Status_Text (Info.Parameter_Association_Status) & ":" &
         Natural'Image (Info.Parameter_Association_Position) & ":" &
         To_String (Info.Normalized_Parameter_Association_Formal_Name) & ":" &
         To_String (Info.Normalized_Parameter_Association_Formal_Subtype) & ":" &
         To_String (Info.Normalized_Parameter_Association_Actual_Subtype) & ":" &
         Attribute_Status_Text (Info.Attribute_Status) & ":" &
         To_String (Info.Normalized_Attribute_Name) & ":" &
         To_String (Info.Normalized_Attribute_Prefix) & ":" &
         To_String (Info.Normalized_Attribute_Result_Subtype) & ":" &
         Natural'Image (Info.Attribute_Static_Result_Count) & ":" &
         Natural'Image (Info.Attribute_String_Result_Count) & ":" &
         Natural'Image (Info.Attribute_Unknown_Count) & ":" &
         Natural'Image (Info.Candidate_Count));
   end Fingerprint_For;

   function Region_For_Line
     (Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Line    : Positive) return Editor.Ada_Declarative_Regions.Region_Id
   is
      Best       : Editor.Ada_Declarative_Regions.Region_Id := Editor.Ada_Declarative_Regions.No_Region;
      Best_Depth : Natural := 0;
   begin
      for I in 1 .. Editor.Ada_Declarative_Regions.Region_Count (Regions) loop
         declare
            R : constant Editor.Ada_Declarative_Regions.Region_Info :=
              Editor.Ada_Declarative_Regions.Region_At (Regions, I);
         begin
            if Line >= R.Start_Line and then Line <= R.End_Line and then
              (Best = Editor.Ada_Declarative_Regions.No_Region or else R.Depth >= Best_Depth)
            then
               Best := R.Id;
               Best_Depth := R.Depth;
            end if;
         end;
      end loop;
      return Best;
   end Region_For_Line;

   function Primary_Name (Text : String) return String is
      T : constant String := Trim (Text);
   begin
      if T = "" then
         return "";
      end if;
      for I in T'Range loop
         if not (T (I) in 'A' .. 'Z' or else T (I) in 'a' .. 'z' or else
                 T (I) in '0' .. '9' or else T (I) = '_' or else T (I) = '.')
         then
            if I = T'First then
               return "";
            else
               return T (T'First .. I - 1);
            end if;
         end if;
      end loop;
      return T;
   end Primary_Name;

   function Simple_Name (Text : String) return String is
      T : constant String := Primary_Name (Text);
   begin
      for I in reverse T'Range loop
         if T (I) = '.' then
            if I < T'Last then
               return T (I + 1 .. T'Last);
            else
               return "";
            end if;
         end if;
      end loop;
      return T;
   end Simple_Name;

   function Prefix_Before (Text : String; Mark : Character) return String is
      T : constant String := Trim (Text);
   begin
      for I in T'Range loop
         if T (I) = Mark then
            if I = T'First then
               return "";
            else
               return Trim (T (T'First .. I - 1));
            end if;
         end if;
      end loop;
      return "";
   end Prefix_Before;

   function Suffix_After (Text : String; Mark : Character) return String is
      T : constant String := Trim (Text);
   begin
      for I in T'Range loop
         if T (I) = Mark then
            if I = T'Last then
               return "";
            else
               return Trim (T (I + 1 .. T'Last));
            end if;
         end if;
      end loop;
      return "";
   end Suffix_After;

   function Attribute_Name_From_Text (Text : String) return String is
      Raw : constant String := Suffix_After (Text, Character'Val (39));
      T   : constant String := Trim (Raw);
   begin
      if T = "" then
         return "";
      end if;
      for I in T'Range loop
         if not (T (I) in 'A' .. 'Z' or else T (I) in 'a' .. 'z' or else
                 T (I) in '0' .. '9' or else T (I) = '_')
         then
            if I = T'First then
               return "";
            else
               return T (T'First .. I - 1);
            end if;
         end if;
      end loop;
      return T;
   end Attribute_Name_From_Text;

   function Attribute_Prefix_From_Text (Text : String) return String is
   begin
      return Prefix_Before (Text, Character'Val (39));
   end Attribute_Prefix_From_Text;

   function Is_String_Literal (Text : String) return Boolean is
      T : constant String := Trim (Text);
   begin
      return T'Length >= 2 and then T (T'First) = '"' and then T (T'Last) = '"';
   end Is_String_Literal;

   function Is_Character_Literal_Text (Text : String) return Boolean is
      T : constant String := Trim (Text);
   begin
      return T'Length >= 3 and then T (T'First) = Character'Val (39) and then
        T (T'Last) = Character'Val (39);
   end Is_Character_Literal_Text;

   function Looks_Real (Text : String) return Boolean is
      T : constant String := Normalize (Text);
   begin
      return Contains (T, ".") or else Contains (T, "e+") or else
        Contains (T, "e-") or else Contains (T, "e");
   end Looks_Real;

   function Is_Universal_Compatible (Actual : String; Expected : String) return Boolean is
      A : constant String := Normalize (Actual);
      E : constant String := Normalize (Expected);
   begin
      return (A = "universal_integer" and then
              (E = "integer" or else E = "natural" or else E = "positive" or else
               Contains (E, "integer") or else Contains (E, "natural") or else
               Contains (E, "positive") or else Contains (E, "count")))
        or else (A = "universal_real" and then
                 (E = "float" or else E = "long_float" or else E = "duration" or else
                  Contains (E, "float") or else Contains (E, "real") or else
                  Contains (E, "duration")))
        or else (A = "universal_integer" and then
                 (E = "float" or else E = "long_float" or else E = "duration"));
   end Is_Universal_Compatible;

   function Is_Context_Dependent
     (Status : Expression_Type_Status) return Boolean is
   begin
      return Status = Expression_Type_Aggregate or else
        Status = Expression_Type_Qualified or else
        Status = Expression_Type_Conversion or else
        Status = Expression_Type_Indeterminate or else
        Status = Expression_Type_Operator_Numeric or else
        Status = Expression_Type_Operator_Concatenation or else
        Status = Expression_Type_Null_Literal or else
        Status = Expression_Type_Allocator;
   end Is_Context_Dependent;

   function Subtype_From_Declaration_Label (Label : String) return String is
      T : constant String := Trim (Label);
      Colon : Natural := 0;
      Assign : Natural := 0;
   begin
      for I in T'Range loop
         if T (I) = ':' then
            Colon := I;
            exit;
         end if;
      end loop;
      if Colon = 0 or else Colon = T'Last then
         return "";
      end if;
      for I in Colon + 1 .. T'Last loop
         if I < T'Last and then T (I) = ':' and then T (I + 1) = '=' then
            Assign := I;
            exit;
         elsif T (I) = ';' then
            Assign := I;
            exit;
         end if;
      end loop;
      if Assign = 0 then
         return Trim (T (Colon + 1 .. T'Last));
      elsif Assign > Colon + 1 then
         declare
            Raw : constant String := Trim (T (Colon + 1 .. Assign - 1));
            N : constant String := Normalize (Raw);
         begin
            if N'Length > 9 and then N (N'First .. N'First + 8) = "constant " then
               return Trim (Raw (Raw'First + 9 .. Raw'Last));
            else
               return Raw;
            end if;
         end;
      else
         return "";
      end if;
   end Subtype_From_Declaration_Label;

   procedure Apply_Syntax_Expected_Context
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Info : in out Expression_Type_Info)
   is
      N : constant Editor.Ada_Syntax_Tree.Node_Info :=
        Editor.Ada_Syntax_Tree.Node (Tree, Info.Node);
      Parent : Editor.Ada_Syntax_Tree.Node_Info;
      Grand  : Editor.Ada_Syntax_Tree.Node_Info;
      Expected : Ada.Strings.Unbounded.Unbounded_String;
   begin
      if Info.Expected_Context /= Editor.Ada_Expected_Type_Contexts.No_Expected_Context then
         return;
      end if;
      if N.Parent = Editor.Ada_Syntax_Tree.No_Node then
         return;
      end if;

      Parent := Editor.Ada_Syntax_Tree.Node (Tree, N.Parent);
      if Parent.Kind = Editor.Ada_Syntax_Tree.Node_Declaration_Default and then
        Parent.Parent /= Editor.Ada_Syntax_Tree.No_Node
      then
         Grand := Editor.Ada_Syntax_Tree.Node (Tree, Parent.Parent);
         if Grand.Kind = Editor.Ada_Syntax_Tree.Node_Object_Declaration or else
           Grand.Kind = Editor.Ada_Syntax_Tree.Node_Constant_Declaration or else
           Grand.Kind = Editor.Ada_Syntax_Tree.Node_Formal_Object_Declaration
         then
            Expected := To_Unbounded_String
              (Subtype_From_Declaration_Label (To_String (Grand.Label)));
         end if;
      elsif Parent.Kind = Editor.Ada_Syntax_Tree.Node_Object_Declaration or else
        Parent.Kind = Editor.Ada_Syntax_Tree.Node_Constant_Declaration or else
        Parent.Kind = Editor.Ada_Syntax_Tree.Node_Formal_Object_Declaration
      then
         Expected := To_Unbounded_String
           (Subtype_From_Declaration_Label (To_String (Parent.Label)));
      end if;

      if To_String (Expected) /= "" then
         Info.Expected_Status := Expected_Type_Context_Found;
         Info.Expected_Subtype := Expected;
         Info.Normalized_Expected_Subtype := To_Unbounded_String (Normalize (To_String (Expected)));
         if To_String (Info.Normalized_Subtype) = "" or else
           To_String (Info.Normalized_Subtype) = "aggregate_context_required" or else
           Is_Context_Dependent (Info.Status)
         then
            Info.Expected_Status := Expected_Type_Propagated;
            Info.Inferred_Subtype := Expected;
            Info.Normalized_Subtype := Info.Normalized_Expected_Subtype;
         elsif To_String (Info.Normalized_Subtype) = To_String (Info.Normalized_Expected_Subtype) or else
           Is_Universal_Compatible
             (To_String (Info.Normalized_Subtype),
              To_String (Info.Normalized_Expected_Subtype))
         then
            Info.Expected_Status := Expected_Type_Compatible;
         else
            Info.Expected_Status := Expected_Type_Mismatch;
         end if;
      end if;
   end Apply_Syntax_Expected_Context;

   procedure Apply_Expected_Context
     (Info     : in out Expression_Type_Info;
      Expected : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model)
   is
      Ctx : Editor.Ada_Expected_Type_Contexts.Expected_Context_Info :=
        Editor.Ada_Expected_Type_Contexts.Expected_Context_For_Node (Expected, Info.Node);
      Inferred : constant String := To_String (Info.Normalized_Subtype);
   begin
      if Ctx.Id = Editor.Ada_Expected_Type_Contexts.No_Expected_Context then
         Info.Expected_Status := Expected_Type_No_Context;
         return;
      end if;

      Info.Expected_Context := Ctx.Id;
      Info.Expected_Subtype := Ctx.Expected_Subtype;
      Info.Normalized_Expected_Subtype := Ctx.Normalized_Subtype;

      if Ctx.Status /= Editor.Ada_Expected_Type_Contexts.Expected_Context_Found then
         Info.Expected_Status := Expected_Type_Unknown;
      elsif To_String (Ctx.Normalized_Subtype) = "" then
         Info.Expected_Status := Expected_Type_Unknown;
      elsif Inferred = "" or else Inferred = "aggregate_context_required" or else
        Inferred = "attribute_result_unknown"
      then
         if Is_Context_Dependent (Info.Status) then
            Info.Expected_Status := Expected_Type_Propagated;
            Info.Inferred_Subtype := Ctx.Expected_Subtype;
            Info.Normalized_Subtype := Ctx.Normalized_Subtype;
         else
            Info.Expected_Status := Expected_Type_Unknown;
         end if;
      elsif Inferred = To_String (Ctx.Normalized_Subtype) or else
        Is_Universal_Compatible (Inferred, To_String (Ctx.Normalized_Subtype))
      then
         Info.Expected_Status := Expected_Type_Compatible;
      elsif Is_Context_Dependent (Info.Status) then
         Info.Expected_Status := Expected_Type_Propagated;
         Info.Inferred_Subtype := Ctx.Expected_Subtype;
         Info.Normalized_Subtype := Ctx.Normalized_Subtype;
      else
         Info.Expected_Status := Expected_Type_Mismatch;
      end if;
   end Apply_Expected_Context;

   procedure Append
     (Model : in out Expression_Type_Model;
      Info  : in out Expression_Type_Info)
   is
   begin
      Info.Id := Expression_Type_Id (Natural (Model.Expressions.Length) + 1);
      Info.Fingerprint := Fingerprint_For (Info);
      Model.Expressions.Append (Info);
      Model.Result_Fingerprint :=
        Hash_Mix (Model.Result_Fingerprint, Long_Long_Integer (Info.Fingerprint));
   end Append;

end Editor.Ada_Expression_Types.Inference_Support;
