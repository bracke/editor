with Ada.Containers;
with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Text_Helpers;
with Editor.Ada_Declaration_Parser.Attribute_Value_Helpers;
with Editor.Ada_Declaration_Parser.Declaration_Collectors;
with Editor.Ada_Declaration_Parser.Freezing_Helpers;
with Editor.Ada_Declaration_Parser.Legality_Profile_Helpers;
with Editor.Ada_Declaration_Parser.Legality_Text_Helpers;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Line_Metadata;
with Editor.Ada_Declaration_Parser.Metadata_Helpers;
with Editor.Ada_Declaration_Parser.Name_Profile_Helpers;
with Editor.Ada_Declaration_Parser.Pragma_Helpers;
with Editor.Ada_Declaration_Parser.Profile_Parameter_Collectors;
with Editor.Ada_Declaration_Parser.Range_Structure_Helpers;
with Editor.Ada_Declaration_Parser.Representation_Legality_Diagnostics;
with Editor.Ada_Declaration_Parser.Representation_Application;
with Editor.Ada_Declaration_Parser.Representation_Metadata;
with Editor.Ada_Declaration_Parser.Representation_Static_Values;
with Editor.Ada_Declaration_Parser.Syntax_Tree_Helpers;
with Editor.Ada_Declaration_Parser.Representation_Target_Helpers;
with Editor.Ada_Declaration_Parser.Same_Line_Declarations;
with Editor.Ada_Declaration_Parser.Same_Line_Emitters;
with Editor.Ada_Declaration_Parser.Source_Awareness;
with Editor.Ada_Declaration_Parser.Static_Attribute_Registry;
with Editor.Ada_Declaration_Parser.Target_Helpers;
with Editor.Ada_Syntax_Core;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Language_Model;

package body Editor.Ada_Declaration_Parser.Legality_Diagnostics is

   use Editor.Ada_Language_Model;
   use Editor.Text_Helpers;
   use type Ada.Containers.Count_Type;
   use type Executable_Binding_Kind;
   use type Freezing_Point_Kind;
   use type Legality_Diagnostic_Kind;
   use type Legality_Diagnostic_Severity;
   use type Representation_Clause_Kind;
   use type Scope_Id;
   use type Symbol_Id;
   use type Symbol_Kind;
   use Editor.Ada_Declaration_Parser.Legality_Profile_Helpers;
   use Editor.Ada_Declaration_Parser.Representation_Legality_Diagnostics;

   function Has_Code_Char (Line : String; C : Character) return Boolean
     renames Editor.Ada_Declaration_Parser.Lexical_Helpers.Has_Code_Char;

   function Has_Declaration_Colon (Line : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Lexical_Helpers.Has_Declaration_Colon;

   function Has_Token (Line, Token : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Lexical_Helpers.Has_Token;

   function Has_Token_Pair
     (Line, First_Token, Second_Token : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Lexical_Helpers.Has_Token_Pair;

   function First_Non_Blank_Column (Line : String) return Positive
     renames Editor.Ada_Declaration_Parser.Metadata_Helpers.First_Non_Blank_Column;

   function Strip_Prefixes (Line : String) return String
     renames Editor.Ada_Declaration_Parser.Name_Profile_Helpers.Strip_Prefixes;

   function Same_Text
     (Left, Right : Unbounded_String) return Boolean
     renames Editor.Ada_Declaration_Parser.Range_Structure_Helpers.Same_Text;

   function Same_Local_Representation_Target
     (Current, Previous : Representation_Clause_Info) return Boolean
     renames Editor.Ada_Declaration_Parser.Range_Structure_Helpers
       .Same_Local_Representation_Target;

   function Ranges_Overlap
     (Left_First, Left_Last, Right_First, Right_Last : Natural) return Boolean
     renames Editor.Ada_Declaration_Parser.Range_Structure_Helpers.Ranges_Overlap;

   function Global_First_Bit (Unit, First_Bit : Natural) return Natural
     renames Editor.Ada_Declaration_Parser.Range_Structure_Helpers.Global_First_Bit;

   function Global_Last_Bit (Unit, Last_Bit : Natural) return Natural
     renames Editor.Ada_Declaration_Parser.Range_Structure_Helpers.Global_Last_Bit;

   function Is_Local_Name_Start (C : Character) return Boolean
     renames Editor.Ada_Declaration_Parser.Range_Structure_Helpers.Is_Local_Name_Start;

   function Is_Local_Name_Char (C : Character) return Boolean
     renames Editor.Ada_Declaration_Parser.Range_Structure_Helpers.Is_Local_Name_Char;

   procedure Add_Legality_Diagnostics (Analysis : in out Analysis_Result) is
      Storage_Unit_Bits : constant Natural := 8;

      function Kind_Image (Kind : Symbol_Kind) return String is
      begin
         return Symbol_Kind'Image (Kind);
      end Kind_Image;

      function Is_Body_Only (Info : Symbol_Info) return Boolean is
      begin
         return Info.Kind in Symbol_Package_Body | Symbol_Separate_Body
           or else Info.Flags.Is_Body;
      end Is_Body_Only;

      function Is_Overloadable_Pair (Left, Right : Symbol_Info) return Boolean is
      begin
         return Is_Subprogram (Left.Kind) and then Is_Subprogram (Right.Kind);
      end Is_Overloadable_Pair;

      function Top_Level_Named_Actual_Count
        (Args : String; Formal_Name : String) return Natural
        renames Editor.Ada_Declaration_Parser.Legality_Text_Helpers.Top_Level_Named_Actual_Count;

      function Top_Level_Arrow_Position (Text : String) return Natural
        renames Editor.Ada_Declaration_Parser.Legality_Text_Helpers.Top_Level_Arrow_Position;

      function Has_Top_Level_Positional_After_Named (Args : String) return Boolean
        renames Editor.Ada_Declaration_Parser.Legality_Text_Helpers.Has_Top_Level_Positional_After_Named;

      function First_Top_Level_Named_Actual (Args : String) return String
        renames Editor.Ada_Declaration_Parser.Legality_Text_Helpers.First_Top_Level_Named_Actual;

      function Normalized_Aspect_Mark (Association_Label : String) return String
        renames Editor.Ada_Declaration_Parser.Legality_Text_Helpers.Normalized_Aspect_Mark;

      function Normalized_Choice_Text (Raw : String) return String
        renames Editor.Ada_Declaration_Parser.Legality_Text_Helpers.Normalized_Choice_Text;

      function Choice_Count_In_List
        (Choice_List : String;
         Choice      : String) return Natural
        renames Editor.Ada_Declaration_Parser.Legality_Text_Helpers.Choice_Count_In_List;

      function Looks_Like_Aggregate_Context (Expression_Text : String) return Boolean
        renames Editor.Ada_Declaration_Parser.Legality_Text_Helpers.Looks_Like_Aggregate_Context;



      function Is_Type_Like_Target (Kind : Symbol_Kind) return Boolean
        renames Editor.Ada_Declaration_Parser.Representation_Target_Helpers.Is_Type_Like_Target;

      function Is_Object_Like_Target (Kind : Symbol_Kind) return Boolean
        renames Editor.Ada_Declaration_Parser.Representation_Target_Helpers.Is_Object_Like_Target;

      function Is_Stream_Operational_Attribute
        (Name : Unbounded_String) return Boolean
        renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Stream_Operational_Attribute;

      function Is_Stream_Input_Attribute
        (Name : Unbounded_String) return Boolean
        renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Stream_Input_Attribute;

      function Is_Operational_Attribute
        (Name : Unbounded_String) return Boolean
        renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Operational_Attribute;

      function Is_Interfacing_Attribute
        (Name : Unbounded_String) return Boolean
        renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Interfacing_Attribute;

      function Is_Link_Name_Attribute
        (Name : Unbounded_String) return Boolean
        renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Link_Name_Attribute;

      function Is_Import_Export_Attribute
        (Name : Unbounded_String) return Boolean
        renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Import_Export_Attribute;

      function Is_Convention_Attribute
        (Name : Unbounded_String) return Boolean
        renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Convention_Attribute;

      function Is_Convention_Identifier (Text : String) return Boolean
        renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Convention_Identifier;

      function Is_Static_Boolean_Value (Text : String) return Boolean
        renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Static_Boolean_Value;

      function Is_Static_True_Value (Text : String) return Boolean
        renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Static_True_Value;

      function Is_Static_False_Value (Text : String) return Boolean
        renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Static_False_Value;

      function Is_Known_Convention_Identifier (Text : String) return Boolean
        renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Known_Convention_Identifier;

      function Is_Static_String_Literal (Text : String) return Boolean
        renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Static_String_Literal;

      function Is_Raw_Numeric_Literal (Text : String) return Boolean
        renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Raw_Numeric_Literal;

      function Is_Static_Numeric_Value (Text : String) return Boolean
        renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Static_Numeric_Value;

      function Is_Positive_Static_Natural_Value (Text : String) return Boolean
        renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Positive_Static_Natural_Value;

      function Is_Storage_Pool_Value (Text : String) return Boolean
        renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Storage_Pool_Value;

      function Is_Address_Null_Value (Text : String) return Boolean
        renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Address_Null_Value;

      function Is_Address_Attribute_Reference (Text : String) return Boolean
        renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Address_Attribute_Reference;

      function Is_Address_Conversion_Call (Text : String) return Boolean
        renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Address_Conversion_Call;

      function Is_Address_Name_Reference (Text : String) return Boolean
        renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Address_Name_Reference;

      function Is_Address_Compatible_Expression (Text : String) return Boolean
        renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Address_Compatible_Expression;

      function Is_Interfacing_Attribute_Target
        (Attribute_Name : Unbounded_String;
         Kind           : Symbol_Kind) return Boolean
        renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Interfacing_Attribute_Target;

      function Is_Access_Type_Target (Info : Symbol_Info) return Boolean
        renames Editor.Ada_Declaration_Parser.Representation_Target_Helpers.Is_Access_Type_Target;

      function Is_Storage_Size_Target (Info : Symbol_Info) return Boolean
        renames Editor.Ada_Declaration_Parser.Representation_Target_Helpers.Is_Storage_Size_Target;

      function Is_Array_Type_Target (Info : Symbol_Info) return Boolean
        renames Editor.Ada_Declaration_Parser.Representation_Target_Helpers.Is_Array_Type_Target;

      function Is_Fixed_Point_Type_Target (Info : Symbol_Info) return Boolean
        renames Editor.Ada_Declaration_Parser.Representation_Target_Helpers.Is_Fixed_Point_Type_Target;

      function Is_Floating_Point_Type_Target (Info : Symbol_Info) return Boolean
        renames Editor.Ada_Declaration_Parser.Representation_Target_Helpers.Is_Floating_Point_Type_Target;

      function Is_Atomic_Volatile_Target (Info : Symbol_Info) return Boolean
        renames Editor.Ada_Declaration_Parser.Representation_Target_Helpers.Is_Atomic_Volatile_Target;

      function Is_Suppress_Initialization_Target (Info : Symbol_Info) return Boolean
        renames Editor.Ada_Declaration_Parser.Representation_Target_Helpers.Is_Suppress_Initialization_Target;

      function Is_Unchecked_Union_Target (Info : Symbol_Info) return Boolean
        renames Editor.Ada_Declaration_Parser.Representation_Target_Helpers.Is_Unchecked_Union_Target;

      function Operational_Handler_Name (Text : String) return String
        renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Operational_Handler_Name;

      function Operational_Handler_Is_Compatible
        (Attribute_Name : Unbounded_String;
         Handler_Kind   : Symbol_Kind) return Boolean
        renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Operational_Handler_Is_Compatible;

      function Is_Subprogram_Like_Target (Kind : Symbol_Kind) return Boolean
        renames Editor.Ada_Declaration_Parser.Representation_Target_Helpers.Is_Subprogram_Like_Target;

      function Is_Address_Clause_Target (Kind : Symbol_Kind) return Boolean
        renames Editor.Ada_Declaration_Parser.Representation_Target_Helpers.Is_Address_Clause_Target;

      procedure Check_Syntax_Recovery_Diagnostics is
         use Editor.Ada_Syntax_Tree;
         Tree : constant Tree_Type := Syntax_Tree (Analysis);

         function Has_Ancestor_Kind
           (Id   : Node_Id;
            Kind : Node_Kind) return Boolean
         is
            P : Node_Id := (if Id = No_Node then No_Node else Node (Tree, Id).Parent);
         begin
            while P /= No_Node loop
               if Node (Tree, P).Kind = Kind then
                  return True;
               end if;
               P := Node (Tree, P).Parent;
            end loop;
            return False;
         end Has_Ancestor_Kind;

         function To_Model_Range
           (R : Editor.Ada_Syntax_Tree.Source_Range) return Editor.Ada_Language_Model.Source_Range is
         begin
            return
              (Start_Line   => R.Start_Line,
               Start_Column => R.Start_Column,
               End_Line     => R.End_Line,
               End_Column   => R.End_Column);
         end To_Model_Range;

         function Parent_Label (N : Node_Info) return String is
         begin
            if N.Parent = No_Node then
               return "";
            end if;
            return Lower (To_String (Node (Tree, N.Parent).Label));
         end Parent_Label;
      begin
         if not Has_Syntax_Tree (Analysis) then
            return;
         end if;

         for I in 1 .. Node_Count (Tree) loop
            declare
               N : constant Node_Info := Node_At (Tree, I);
            begin
               if N.Kind = Node_Expected_Token then
                  declare
                     Expected : constant String := Trim (To_String (N.Label));
                     Context  : constant String := Parent_Label (N);
                  begin
                     if Expected = ";"
                       and then Ada.Strings.Fixed.Index (Context, "malformed pragma") /= 0
                     then
                        Add_Legality_Diagnostic
                          (Analysis,
                           Legality_Malformed_Pragma_Syntax,
                           "malformed pragma is missing a terminating semicolon",
                           Legality_Error, No_Symbol, No_Symbol, To_Model_Range (N.Source_Span));
                     elsif Expected = ";"
                       and then Ada.Strings.Fixed.Index (Context, "malformed metadata clause") /= 0
                     then
                        Add_Legality_Diagnostic
                          (Analysis,
                           Legality_Missing_Metadata_Terminator,
                           "metadata clause is missing a terminating semicolon",
                           Legality_Error, No_Symbol, No_Symbol, To_Model_Range (N.Source_Span));
                     elsif Expected = ";"
                       and then Ada.Strings.Fixed.Index (Context, "malformed declaration") /= 0
                     then
                        Add_Legality_Diagnostic
                          (Analysis,
                           Legality_Missing_Declaration_Terminator,
                           "declaration is missing a terminating semicolon",
                           Legality_Error, No_Symbol, No_Symbol, To_Model_Range (N.Source_Span));
                     elsif (Expected = ")" or else Expected = "(")
                       and then Has_Ancestor_Kind (N.Id, Node_Aspect_Specification)
                     then
                        Add_Legality_Diagnostic
                          (Analysis,
                           Legality_Malformed_Aspect_Association,
                           "aspect association list has unbalanced delimiters",
                           Legality_Error, No_Symbol, No_Symbol, To_Model_Range (N.Source_Span));
                     elsif Expected = "=>"
                       and then Has_Ancestor_Kind (N.Id, Node_Exception_Handler)
                     then
                        Add_Legality_Diagnostic
                          (Analysis,
                           Legality_Malformed_Handler_Alternative,
                           "exception handler alternative is missing =>",
                           Legality_Error, No_Symbol, No_Symbol, To_Model_Range (N.Source_Span));
                     elsif Expected = "=>"
                       and then Has_Ancestor_Kind (N.Id, Node_Variant)
                     then
                        Add_Legality_Diagnostic
                          (Analysis,
                           Legality_Malformed_Variant_Alternative,
                           "variant alternative is missing =>",
                           Legality_Error, No_Symbol, No_Symbol, To_Model_Range (N.Source_Span));
                     elsif Expected = "=>"
                       and then Has_Ancestor_Kind (N.Id, Node_When_Alternative)
                     then
                        Add_Legality_Diagnostic
                          (Analysis,
                           Legality_Malformed_Case_Alternative,
                           "case alternative is missing =>",
                           Legality_Error, No_Symbol, No_Symbol, To_Model_Range (N.Source_Span));
                     end if;
                  end;
               end if;
            end;
         end loop;
      end Check_Syntax_Recovery_Diagnostics;



   begin
      Build_Freezing_Point_Index (Analysis);
      Check_Syntax_Recovery_Diagnostics;

      --  Declaration uniqueness: this is intentionally conservative and only
      --  diagnoses same-scope homographs where the retained model has enough
      --  information to avoid subprogram overload and package body/spec pairs.
      for I in 1 .. Symbol_Count (Analysis) loop
         declare
            Current : constant Symbol_Info := Symbol_At (Analysis, I);
         begin
            if To_String (Current.Normalized_Name) /= ""
              and then not Is_Body_Only (Current)
            then
               for J in 1 .. I - 1 loop
                  declare
                     Previous : constant Symbol_Info := Symbol_At (Analysis, J);
                  begin
                     if Same_Text (Current.Normalized_Name, Previous.Normalized_Name)
                       and then Current.Enclosing_Scope = Previous.Enclosing_Scope
                       and then not Is_Body_Only (Previous)
                       and then not Is_Overloadable_Pair (Current, Previous)
                     then
                        Add_Legality_Diagnostic
                          (Analysis,
                           Legality_Duplicate_Declaration,
                           "duplicate declaration of " & To_String (Current.Name) &
                             " in the same declarative region (" &
                             Kind_Image (Previous.Kind) & " already exists)",
                           Legality_Error,
                           Current.Id,
                           Previous.Id,
                           Current.Source_Span);
                        exit;
                     end if;
                  end;
               end loop;
            end if;
         end;
      end loop;

      --  Profile parameter names: a retained callable profile can diagnose
      --  duplicate parameter identifiers within the same profile group/list.
      --  This is deliberately local and structural; it does not attempt
      --  subtype conformance, overriding, or overload resolution.
      for I in 1 .. Symbol_Count (Analysis) loop
         declare
            Current : constant Symbol_Info := Symbol_At (Analysis, I);
            Duplicate : constant String :=
              Editor.Ada_Declaration_Parser.Profile_Parameter_Collectors.Profile_Parameter_Duplicate
                (To_String (Current.Profile_Summary));
         begin
            if Duplicate /= ""
              and then Current.Kind in Symbol_Procedure | Symbol_Function |
                Symbol_Operator_Function | Symbol_Entry |
                Symbol_Generic_Subprogram | Symbol_Generic_Formal_Subprogram
            then
               Add_Legality_Diagnostic
                 (Analysis,
                  Legality_Duplicate_Profile_Parameter,
                  "duplicate parameter name " & Duplicate &
                    " in retained callable profile",
                  Legality_Error,
                  Current.Id,
                  No_Symbol,
                  Current.Source_Span);
            end if;
         end;
      end loop;

      --  Local declaration-family duplicates: retain narrowly-scoped, low
      --  false-positive diagnostics for declaration families whose enclosing
      --  parent/scope is structural and local.  This deliberately avoids
      --  overload resolution and does not infer visibility across scopes.
      for I in 1 .. Symbol_Count (Analysis) loop
         declare
            Current : constant Symbol_Info := Symbol_At (Analysis, I);
            Duplicate_Kind : Legality_Diagnostic_Kind := Legality_Duplicate_Declaration;
            Applies : Boolean := False;
            Family_Name : String (1 .. 32) := (others => ' ');
            Family_Len  : Natural := 0;
         begin
            case Current.Kind is
               when Symbol_Record_Component =>
                  Duplicate_Kind := Legality_Duplicate_Record_Component_Name;
                  Applies := Current.Parent_Symbol /= No_Symbol;
                  Family_Name (1 .. 16) := "record component";
                  Family_Len := 16;
               when Symbol_Object =>
                  Duplicate_Kind := Legality_Duplicate_Record_Component_Name;
                  Applies := Current.Parent_Symbol /= No_Symbol;
                  Family_Name (1 .. 16) := "record component";
                  Family_Len := 16;
               when Symbol_Discriminant =>
                  Duplicate_Kind := Legality_Duplicate_Discriminant_Name;
                  Applies := Current.Parent_Symbol /= No_Symbol;
                  Family_Name (1 .. 12) := "discriminant";
                  Family_Len := 12;
               when Symbol_Enumeration_Literal =>
                  Duplicate_Kind := Legality_Duplicate_Enumeration_Literal_Name;
                  Applies := Current.Parent_Symbol /= No_Symbol;
                  Family_Name (1 .. 19) := "enumeration literal";
                  Family_Len := 19;
               when Symbol_Generic_Formal_Type |
                    Symbol_Generic_Formal_Object |
                    Symbol_Generic_Formal_Subprogram |
                    Symbol_Generic_Formal_Package =>
                  Duplicate_Kind := Legality_Duplicate_Generic_Formal_Name;
                  Applies := True;
                  Family_Name (1 .. 14) := "generic formal";
                  Family_Len := 14;
               when others =>
                  null;
            end case;

            if Applies and then To_String (Current.Normalized_Name) /= "" then
               for J in 1 .. I - 1 loop
                  declare
                     Previous : constant Symbol_Info := Symbol_At (Analysis, J);
                     Same_Family : constant Boolean :=
                       (case Current.Kind is
                          when Symbol_Record_Component =>
                             Previous.Kind = Symbol_Record_Component
                             and then Previous.Parent_Symbol = Current.Parent_Symbol,
                          when Symbol_Object =>
                             Previous.Kind = Symbol_Object
                             and then Previous.Parent_Symbol = Current.Parent_Symbol,
                          when Symbol_Discriminant =>
                             Previous.Kind = Symbol_Discriminant
                             and then Previous.Parent_Symbol = Current.Parent_Symbol,
                          when Symbol_Enumeration_Literal =>
                             Previous.Kind = Symbol_Enumeration_Literal
                             and then Previous.Parent_Symbol = Current.Parent_Symbol,
                          when Symbol_Generic_Formal_Type |
                               Symbol_Generic_Formal_Object |
                               Symbol_Generic_Formal_Subprogram |
                               Symbol_Generic_Formal_Package =>
                             Previous.Kind in Symbol_Generic_Formal_Type |
                               Symbol_Generic_Formal_Object |
                               Symbol_Generic_Formal_Subprogram |
                               Symbol_Generic_Formal_Package
                             and then Previous.Enclosing_Scope = Current.Enclosing_Scope,
                          when others => False);
                  begin
                     if Same_Family
                       and then Same_Text (Current.Normalized_Name,
                                           Previous.Normalized_Name)
                     then
                        Add_Legality_Diagnostic
                          (Analysis,
                           Duplicate_Kind,
                           "duplicate " & Family_Name (1 .. Family_Len) &
                             " name " & To_String (Current.Name) &
                             " in the same local declaration family",
                           Legality_Error,
                           Current.Id,
                           Previous.Id,
                           Current.Source_Span);
                        exit;
                     end if;
                  end;
               end loop;
            end if;
         end;
      end loop;

      --  Generic actual associations: after the first named association,
      --  subsequent associations must also be named, and a named formal may
      --  appear at most once within the same instantiation/formal package
      --  actual part.  This is a lightweight legality pass over the retained
      --  actual metadata; it deliberately leaves contract matching and type
      --  conformance to later semantic phases.
      for I in 1 .. Generic_Actual_Count (Analysis) loop
         declare
            Current : constant Generic_Actual_Info :=
              Generic_Actual_At (Analysis, No_Symbol, I);
            Current_Formal : constant String :=
              To_String (Current.Normalized_Formal_Name);
         begin
            if Current.Instance_Symbol /= No_Symbol then
               if Current_Formal = "" then
                  for J in 1 .. I - 1 loop
                     declare
                        Previous : constant Generic_Actual_Info :=
                          Generic_Actual_At (Analysis, No_Symbol, J);
                     begin
                        if Previous.Instance_Symbol = Current.Instance_Symbol
                          and then To_String (Previous.Normalized_Formal_Name) /= ""
                        then
                           Add_Legality_Diagnostic
                             (Analysis,
                              Legality_Positional_Generic_Actual_After_Named,
                              "positional generic actual appears after a named association",
                              Legality_Error,
                              Current.Instance_Symbol,
                              Previous.Instance_Symbol,
                              Current.Source_Span);
                           exit;
                        end if;
                     end;
                  end loop;
               else
                  for J in 1 .. I - 1 loop
                     declare
                        Previous : constant Generic_Actual_Info :=
                          Generic_Actual_At (Analysis, No_Symbol, J);
                     begin
                        if Previous.Instance_Symbol = Current.Instance_Symbol
                          and then Same_Text (Current.Normalized_Formal_Name,
                                              Previous.Normalized_Formal_Name)
                        then
                           Add_Legality_Diagnostic
                             (Analysis,
                              Legality_Duplicate_Generic_Actual_Formal,
                              "duplicate generic actual association for formal " &
                                To_String (Current.Formal_Name),
                              Legality_Error,
                              Current.Instance_Symbol,
                              Previous.Instance_Symbol,
                              Current.Source_Span);
                           exit;
                        end if;
                     end;
                  end loop;

                  --  Formal package actual parts may use the reserved
                  --  association ``others => <>`` only as a final catch-all
                  --  box association.  The lightweight model cannot yet
                  --  distinguish every generic-instantiation context from
                  --  every formal-package context, but any retained formal
                  --  selector named ``others`` is necessarily this syntactic
                  --  catch-all rather than a user-defined formal.
                  if Current_Formal = "others" then
                     if Trim (To_String (Current.Actual_Name)) /= "<>" then
                        Add_Legality_Diagnostic
                          (Analysis,
                           Legality_Generic_Others_Actual_Must_Be_Box,
                           "generic others association must use the box actual <>" ,
                           Legality_Error,
                           Current.Instance_Symbol,
                           No_Symbol,
                           Current.Source_Span);
                     end if;

                     for J in I + 1 .. Generic_Actual_Count (Analysis) loop
                        declare
                           Later : constant Generic_Actual_Info :=
                             Generic_Actual_At (Analysis, No_Symbol, J);
                        begin
                           if Later.Instance_Symbol = Current.Instance_Symbol then
                              Add_Legality_Diagnostic
                                (Analysis,
                                 Legality_Generic_Others_Actual_Not_Last,
                                 "generic others association must be the final actual association",
                                 Legality_Error,
                                 Current.Instance_Symbol,
                                 Later.Instance_Symbol,
                                 Current.Source_Span);
                              exit;
                           end if;
                        end;
                     end loop;
                  end if;
               end if;
            end if;
         end;
      end loop;


      --  Visibility clauses are declarative-context items.  Repeating the same
      --  with/use item in the same retained scope does not change visibility
      --  and is illegal/noisy enough for IDE diagnostics, so report it while
      --  keeping distinct clause kinds independent (for example ``use`` versus
      --  ``use type``).
      for I in 1 .. Visibility_Clause_Count (Analysis) loop
         declare
            Current : constant Visibility_Clause_Info :=
              Visibility_Clause_At (Analysis, Scope_Id'Last, I);
         begin
            if To_String (Current.Normalized_Name) /= "" then
               for J in 1 .. I - 1 loop
                  declare
                     Previous : constant Visibility_Clause_Info :=
                       Visibility_Clause_At (Analysis, Scope_Id'Last, J);
                  begin
                     if Previous.Kind = Current.Kind
                       and then Previous.Scope = Current.Scope
                       and then Same_Text (Previous.Normalized_Name,
                                           Current.Normalized_Name)
                     then
                        Add_Legality_Diagnostic
                          (Analysis,
                           Legality_Duplicate_Visibility_Clause,
                           "duplicate visibility clause for " &
                             To_String (Current.Name),
                           Legality_Error,
                           No_Symbol,
                           No_Symbol,
                           Current.Source_Span);
                        exit;
                     end if;
                  end;
               end loop;
            end if;
         end;
      end loop;

      --  Renaming declarations must name a renamed entity and the retained
      --  entity must not be the declaration itself.  This is intentionally
      --  syntactic/name-based: full visibility resolution is future semantic work,
      --  but these two cases are unambiguous from the structural model.
      for I in 1 .. Symbol_Count (Analysis) loop
         declare
            Current : constant Symbol_Info := Symbol_At (Analysis, I);
            Target  : constant String := Trim (To_String (Current.Target_Name));
         begin
            if Current.Flags.Is_Rename then
               if Target = "" then
                  Add_Legality_Diagnostic
                    (Analysis,
                     Legality_Renaming_Missing_Target,
                     "renaming declaration " & To_String (Current.Name) &
                       " does not retain a renamed entity",
                     Legality_Error,
                     Current.Id,
                     No_Symbol,
                     Current.Source_Span);
               elsif Lower (Target) = To_String (Current.Normalized_Name) then
                  Add_Legality_Diagnostic
                    (Analysis,
                     Legality_Renaming_Self_Target,
                     "renaming declaration " & To_String (Current.Name) &
                       " renames itself",
                     Legality_Error,
                     Current.Id,
                     Current.Id,
                     Current.Source_Span);
               end if;
            end if;
         end;
      end loop;

      --  Label, goto, and named-exit legality: labels identify local
      --  transfer targets, and named exits identify retained loop/block labels.
      --  This remains a conservative same-scope pass over executable binding
      --  metadata; it deliberately avoids full control-flow/accessibility
      --  analysis while still catching common stale-target mistakes.
      for I in 1 .. Executable_Binding_Count (Analysis) loop
         declare
            Current : constant Executable_Binding_Info :=
              Executable_Binding_At (Analysis, I);
            Current_Name : constant String :=
              To_String (Current.Normalized_Name);
         begin
            if Current.Kind = Binding_Label_Declaration
              and then Current_Name /= ""
            then
               for J in 1 .. I - 1 loop
                  declare
                     Previous : constant Executable_Binding_Info :=
                       Executable_Binding_At (Analysis, J);
                  begin
                     if Previous.Kind = Binding_Label_Declaration
                       and then Previous.Scope = Current.Scope
                       and then Same_Text (Previous.Normalized_Name,
                                           Current.Normalized_Name)
                     then
                        Add_Legality_Diagnostic
                          (Analysis,
                           Legality_Duplicate_Label,
                           "duplicate label " & To_String (Current.Name) &
                             " in the same executable region",
                           Legality_Error,
                           Current.Target_Symbol,
                           Previous.Target_Symbol,
                           Current.Source_Span);
                        exit;
                     end if;
                  end;
               end loop;

            elsif Current.Kind = Binding_Block_Label
              and then Current_Name /= ""
            then
               for J in 1 .. I - 1 loop
                  declare
                     Previous : constant Executable_Binding_Info :=
                       Executable_Binding_At (Analysis, J);
                  begin
                     if Previous.Kind = Binding_Block_Label
                       and then Previous.Scope = Current.Scope
                       and then Same_Text (Previous.Normalized_Name,
                                           Current.Normalized_Name)
                     then
                        Add_Legality_Diagnostic
                          (Analysis,
                           Legality_Duplicate_Block_Label,
                           "duplicate block/loop label " & To_String (Current.Name) &
                             " in the same executable region",
                           Legality_Error,
                           Current.Target_Symbol,
                           Previous.Target_Symbol,
                           Current.Source_Span);
                        exit;
                     end if;
                  end;
               end loop;

            elsif Current.Kind = Binding_Goto_Target
              and then Current_Name /= ""
            then
               declare
                  Found : Boolean := False;
               begin
                  for J in 1 .. Executable_Binding_Count (Analysis) loop
                     declare
                        Candidate : constant Executable_Binding_Info :=
                          Executable_Binding_At (Analysis, J);
                     begin
                        if Candidate.Kind = Binding_Label_Declaration
                          and then Candidate.Scope = Current.Scope
                          and then Same_Text (Candidate.Normalized_Name,
                                              Current.Normalized_Name)
                        then
                           Found := True;
                           exit;
                        end if;
                     end;
                  end loop;

                  if not Found then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Goto_Missing_Target,
                        "goto target " & To_String (Current.Name) &
                          " does not name a retained label",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  end if;
               end;

            elsif Current.Kind = Binding_Exit_Target
              and then Current_Name /= ""
            then
               declare
                  Found : Boolean := False;
               begin
                  for J in 1 .. Executable_Binding_Count (Analysis) loop
                     declare
                        Candidate : constant Executable_Binding_Info :=
                          Executable_Binding_At (Analysis, J);
                     begin
                        if Candidate.Kind = Binding_Block_Label
                          and then Candidate.Scope = Current.Scope
                          and then Same_Text (Candidate.Normalized_Name,
                                              Current.Normalized_Name)
                        then
                           Found := True;
                           exit;
                        end if;
                     end;
                  end loop;

                  if not Found then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Exit_Missing_Target,
                        "exit target " & To_String (Current.Name) &
                          " does not name a retained loop/block label",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  end if;
               end;
            end if;
         end;
      end loop;


      --  Case and exception alternatives are discrete local choice lists.
      --  This pass only diagnoses choices that are duplicated within the same
      --  retained ``when`` line, which avoids false positives across separate
      --  nested case statements while still catching the common syntactic
      --  ``when A | A =>`` shape.
      for I in 1 .. Executable_Binding_Count (Analysis) loop
         declare
            Current : constant Executable_Binding_Info :=
              Executable_Binding_At (Analysis, I);
            Current_Name : constant String :=
              To_String (Current.Normalized_Name);
            Choices : constant String := To_String (Current.Expression_Text);
         begin
            if Current_Name /= ""
              and then Current.Kind in Binding_Case_Choice |
                                      Binding_Exception_Handler_Choice
              and then Choice_Count_In_List (Choices, Current_Name) > 1
            then
               Add_Legality_Diagnostic
                 (Analysis,
                  (if Current.Kind = Binding_Case_Choice then
                      Legality_Duplicate_Case_Choice
                   else
                      Legality_Duplicate_Exception_Choice),
                  "duplicate " &
                    (if Current.Kind = Binding_Case_Choice then "case" else "exception") &
                    " choice " & To_String (Current.Name) &
                    " in the same alternative",
                  Legality_Error,
                  Current.Target_Symbol,
                  No_Symbol,
                  Current.Source_Span);
            end if;
         end;
      end loop;


      --  Variant choices are retained in the syntax tree as alternatives
      --  owned by the local variant part.  The same conservative line-local
      --  duplicate rule is used here: it catches ``when A | A =>`` without
      --  attempting full static variant coverage analysis.
      declare
         use type Editor.Ada_Syntax_Tree.Node_Kind;
         use type Editor.Ada_Syntax_Tree.Node_Id;
         Tree : constant Editor.Ada_Syntax_Tree.Tree_Type := Syntax_Tree (Analysis);
      begin
         if Editor.Ada_Syntax_Tree.Has_Nodes (Tree) then
            for I in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
               declare
                  Current : constant Editor.Ada_Syntax_Tree.Node_Info :=
                    Editor.Ada_Syntax_Tree.Node_At (Tree, I);
               begin
                  if Current.Kind = Editor.Ada_Syntax_Tree.Node_Variant then
                     declare
                        Choices : constant String :=
                          Editor.Ada_Declaration_Parser.Syntax_Tree_Helpers.First_Child_Label
                            (Tree,
                             Current.Id,
                             Editor.Ada_Syntax_Tree.Node_Statement_Alternative);
                        Start : Natural := Choices'First;
                        Reported : Boolean := False;
                     begin
                        if Choices /= "" then
                           for C in Choices'Range loop
                              if Choices (C) = '|' then
                                 declare
                                    Choice : constant String := Trim (Choices (Start .. C - 1));
                                 begin
                                    if Choice_Count_In_List (Choices, Choice) > 1 then
                                       Add_Legality_Diagnostic
                                         (Analysis,
                                          Legality_Duplicate_Variant_Choice,
                                          "duplicate variant choice " & Choice &
                                            " in the same variant alternative",
                                          Legality_Error,
                                          No_Symbol,
                                          No_Symbol,
                                          (Current.Source_Span.Start_Line, Current.Source_Span.Start_Column,
                                           Current.Source_Span.End_Line, Current.Source_Span.End_Column));
                                       Reported := True;
                                       exit;
                                    end if;
                                 end;
                                 Start := C + 1;
                              end if;
                           end loop;

                           if not Reported and then Start <= Choices'Last then
                              declare
                                 Choice : constant String := Trim (Choices (Start .. Choices'Last));
                              begin
                                 if Choice_Count_In_List (Choices, Choice) > 1 then
                                    Add_Legality_Diagnostic
                                      (Analysis,
                                       Legality_Duplicate_Variant_Choice,
                                       "duplicate variant choice " & Choice &
                                         " in the same variant alternative",
                                       Legality_Error,
                                       No_Symbol,
                                       No_Symbol,
                                       (Current.Source_Span.Start_Line, Current.Source_Span.Start_Column,
                                        Current.Source_Span.End_Line, Current.Source_Span.End_Column));
                                 end if;
                              end;
                           end if;
                        end if;
                     end;
                  end if;
               end;
            end loop;
         end if;
      end;


      --  Aggregate associations use selector syntax that is intentionally
      --  distinct from call named actuals.  Diagnose duplicate selectors only
      --  where the retained expression text looks aggregate-shaped, so normal
      --  calls continue to be handled by the call-actual diagnostic below.
      for I in 1 .. Executable_Binding_Count (Analysis) loop
         declare
            Current : constant Executable_Binding_Info :=
              Executable_Binding_At (Analysis, I);
            Current_Name : constant String :=
              To_String (Current.Normalized_Name);
            Expr : constant String := To_String (Current.Expression_Text);
         begin
            if Current_Name /= ""
              and then Current.Kind in Binding_Aggregate_Component |
                                      Binding_Aggregate_Component_Selector |
                                      Binding_Delta_Aggregate_Component
              and then Looks_Like_Aggregate_Context (Expr)
            then
               for J in 1 .. I - 1 loop
                  declare
                     Previous : constant Executable_Binding_Info :=
                       Executable_Binding_At (Analysis, J);
                  begin
                     if Previous.Kind = Current.Kind
                       and then Previous.Scope = Current.Scope
                       and then To_String (Previous.Expression_Text) = Expr
                       and then Same_Text (Previous.Normalized_Name,
                                           Current.Normalized_Name)
                     then
                        Add_Legality_Diagnostic
                          (Analysis,
                           (if Current.Kind = Binding_Delta_Aggregate_Component then
                              Legality_Duplicate_Delta_Aggregate_Component
                            else
                              Legality_Duplicate_Aggregate_Component_Choice),
                           "duplicate aggregate component selector " &
                             To_String (Current.Name) &
                             " in the same aggregate expression",
                           Legality_Error,
                           Current.Target_Symbol,
                           Previous.Target_Symbol,
                           Current.Source_Span);
                        exit;
                     end if;
                  end;
               end loop;
            end if;
         end;
      end loop;


      --  Subprogram and entry calls use the same Ada association-list
      --  ordering rules as other association lists: a named actual may only
      --  appear once within a single call, and no positional actual may follow
      --  the first named association.  The executable binding pass stores the
      --  original top-level argument list for each retained named actual, so
      --  this check can diagnose the local ordering shape without relying on
      --  overload or target resolution.
      for I in 1 .. Executable_Binding_Count (Analysis) loop
         declare
            Current : constant Executable_Binding_Info :=
              Executable_Binding_At (Analysis, I);
            Current_Name : constant String :=
              To_String (Current.Normalized_Name);
            Args : constant String := To_String (Current.Expression_Text);
         begin
            if Current.Kind = Binding_Named_Actual
              and then Current_Name /= ""
            then
               if Top_Level_Named_Actual_Count (Args, Current_Name) > 1 then
                  Add_Legality_Diagnostic
                    (Analysis,
                     Legality_Duplicate_Call_Named_Actual,
                     "duplicate named actual " & To_String (Current.Name) &
                       " in the same call",
                     Legality_Error,
                     Current.Target_Symbol,
                     No_Symbol,
                     Current.Source_Span);
               end if;

               if Has_Top_Level_Positional_After_Named (Args)
                 and then First_Top_Level_Named_Actual (Args) = Current_Name
               then
                  Add_Legality_Diagnostic
                    (Analysis,
                     Legality_Positional_Call_Actual_After_Named,
                     "positional actual appears after a named call association",
                     Legality_Error,
                     Current.Target_Symbol,
                     No_Symbol,
                     Current.Source_Span);
               end if;
            end if;
         end;
      end loop;


      --  Aspect specifications also use association-list syntax, and a single
      --  aspect specification may not define the same aspect mark twice.  This
      --  checks the retained syntax tree instead of line text so attached
      --  aspects on bodies, declarations, task/protected items, and standalone
      --  aspect clauses are all covered uniformly.
      declare
         use type Editor.Ada_Syntax_Tree.Node_Kind;
         use type Editor.Ada_Syntax_Tree.Node_Id;

         Tree : constant Editor.Ada_Syntax_Tree.Tree_Type := Syntax_Tree (Analysis);
      begin
         if Editor.Ada_Syntax_Tree.Has_Nodes (Tree) then
            for I in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
               declare
                  Current : constant Editor.Ada_Syntax_Tree.Node_Info :=
                    Editor.Ada_Syntax_Tree.Node_At (Tree, I);
               begin
                  if Current.Kind = Editor.Ada_Syntax_Tree.Node_Aspect_Association then
                     declare
                        Current_Mark : constant String :=
                          Normalized_Aspect_Mark (To_String (Current.Label));
                     begin
                        if Current_Mark /= "" then
                           for J in 1 .. I - 1 loop
                              declare
                                 Previous : constant Editor.Ada_Syntax_Tree.Node_Info :=
                                   Editor.Ada_Syntax_Tree.Node_At (Tree, J);
                              begin
                                 if Previous.Kind = Editor.Ada_Syntax_Tree.Node_Aspect_Association
                                   and then Previous.Parent = Current.Parent
                                   and then Normalized_Aspect_Mark
                                     (To_String (Previous.Label)) = Current_Mark
                                 then
                                    Add_Legality_Diagnostic
                                      (Analysis,
                                       Legality_Duplicate_Aspect_Association,
                                       "duplicate aspect association for " &
                                         To_String (Current.Label),
                                       Legality_Error,
                                       No_Symbol,
                                       No_Symbol,
                                       (Current.Source_Span.Start_Line, Current.Source_Span.Start_Column,
                                        Current.Source_Span.End_Line, Current.Source_Span.End_Column));
                                    exit;
                                 end if;
                              end;
                           end loop;
                        end if;
                     end;
                  end if;
               end;
            end loop;
         end if;
      end;


      --  Pragmas that use named associations also require each named
      --  argument selector to appear at most once within the pragma argument
      --  list.  This pass is intentionally syntactic and mirrors the bounded
      --  duplicate call actual check without trying to classify pragma names
      --  beyond the executable-pragmas already retained by the scanner.
      for I in 1 .. Executable_Binding_Count (Analysis) loop
         declare
            Current : constant Executable_Binding_Info :=
              Executable_Binding_At (Analysis, I);
            Current_Name : constant String :=
              To_String (Current.Normalized_Name);
            Args : constant String := To_String (Current.Expression_Text);
         begin
            if Current.Kind = Binding_Pragma_Argument
              and then Current_Name /= ""
              and then Top_Level_Named_Actual_Count (Args, Current_Name) > 1
            then
               Add_Legality_Diagnostic
                 (Analysis,
                  Legality_Duplicate_Pragma_Named_Argument,
                  "duplicate named pragma argument " & To_String (Current.Name) &
                    " in the same pragma",
                  Legality_Error,
                  Current.Target_Symbol,
                  No_Symbol,
                  Current.Source_Span);
            end if;
         end;
      end loop;


      Editor.Ada_Declaration_Parser.Representation_Legality_Diagnostics
        .Add_Representation_Legality_Diagnostics (Analysis);
   end Add_Legality_Diagnostics;

end Editor.Ada_Declaration_Parser.Legality_Diagnostics;
