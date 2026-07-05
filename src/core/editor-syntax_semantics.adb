with Editor.Syntax;
with Editor.Outline;
with Editor.Ada_Syntax_Core;
with Editor.Ada_Language_Model;
with Editor.Ada_Symbol_Resolver;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Characters.Handling;

package body Editor.Syntax_Semantics is

   use type Editor.Ada_Language_Model.Symbol_Id;
   use type Editor.Syntax.Syntax_Kind;

   function Lower (S : String) return String is
      Result : String (S'Range);
   begin
      for I in S'Range loop
         Result (I) := Ada.Characters.Handling.To_Lower (S (I));
      end loop;
      return Result;
   end Lower;

   function Is_Name_Char (Ch : Character) return Boolean is
   begin
      return (Ch >= 'A' and then Ch <= 'Z')
        or else (Ch >= 'a' and then Ch <= 'z')
        or else (Ch >= '0' and then Ch <= '9')
        or else Ch = '_'
        or else Character'Pos (Ch) >= 128;
   end Is_Name_Char;

   procedure Add
     (Map  : in out Semantic_Map;
      Name : String;
      Kind : Editor.Syntax.Token_Kind)
   is
      Key : constant String := Lower (Name);
      Len : constant Natural := Natural'Min (Key'Length, Stored_Name'Length);
   begin
      if Len = 0 then
         return;
      elsif Key'Length > Stored_Name'Length then
         --  do not silently truncate semantic keys.  Truncation can
         --  make two distinct long Ada identifiers share the same retained
         --  prefix and miscolour an unrelated token.  Treat an overlong name
         --  as bounded semantic overflow and leave it unclassified instead.
         Map.Symbol_Overflow := True;
         return;
      end if;

      for I in Map.Symbols'Range loop
         if Map.Symbols (I).Used
           and then Map.Symbols (I).Len = Len
           and then Map.Symbols (I).Name (1 .. Len) = Key (Key'First .. Key'First + Len - 1)
         then
            Map.Symbols (I).Kind := Kind;
            return;
         end if;
      end loop;

      for I in Map.Symbols'Range loop
         if not Map.Symbols (I).Used then
            Map.Symbols (I).Used := True;
            Map.Symbols (I).Len := Len;
            Map.Symbols (I).Name (1 .. Len) := Key (Key'First .. Key'First + Len - 1);
            Map.Symbols (I).Kind := Kind;
            return;
         end if;
      end loop;

      Map.Symbol_Overflow := True;
   end Add;

   procedure Add_With_Qualified_Leaf
     (Map  : in out Semantic_Map;
      Name : String;
      Kind : Editor.Syntax.Token_Kind)
   is
      Dot : Natural := 0;
   begin
      Add (Map, Name, Kind);
      for I in reverse Name'Range loop
         if Name (I) = '.' then
            Dot := I;
            exit;
         end if;
      end loop;

      if Dot /= 0 and then Dot < Name'Last then
         Add (Map, Name (Dot + 1 .. Name'Last), Kind);
      end if;
   end Add_With_Qualified_Leaf;

   function Has_Substring (Text : String; Pattern : String) return Boolean is
   begin
      if Pattern'Length = 0 then
         return True;
      elsif Text'Length < Pattern'Length then
         return False;
      end if;

      for I in Text'First .. Text'Last - Pattern'Length + 1 loop
         if Text (I .. I + Pattern'Length - 1) = Pattern then
            return True;
         end if;
      end loop;

      return False;
   end Has_Substring;

   function Is_Recovered_Partial_Name (Text : String) return Boolean is
   begin
      --  Case 891: parser recovery can expose partial selected names through
      --  metadata-only semantic paths (for example Broken. or Broken.' in a
      --  malformed allocator/qualified expression).  Such names must not seed
      --  the flat semantic-colouring map, otherwise a recovered prefix can be
      --  coloured as a complete type/package/value declaration.
      return Text'Length = 0
        or else Text (Text'Last) = '.'
        or else Has_Substring (Text, "..");
   end Is_Recovered_Partial_Name;

   function Is_Recovered_Unresolved_Binding
     (Binding : Editor.Ada_Language_Model.Executable_Binding_Info) return Boolean
   is
      Name_Text : constant String := To_String (Binding.Name);
      Expr_Text : constant String := To_String (Binding.Expression_Text);
   begin
      if Binding.Target_Symbol /= Editor.Ada_Language_Model.No_Symbol then
         return False;
      elsif Is_Recovered_Partial_Name (Name_Text) then
         return True;
      elsif Expr_Text'Length = 0 then
         return False;
      end if;

      return Has_Substring (Expr_Text, ".'")
        or else (Name_Text'Length > 0
                 and then Has_Substring (Expr_Text, Name_Text & "."));
   end Is_Recovered_Unresolved_Binding;

   function Word_After (Line : String; Marker : String) return String is
      Lower_Line : constant String := Lower (Line);
      Lower_Marker : constant String := Lower (Marker);
      Start : Natural := 0;
   begin
      if Lower_Line'Length < Lower_Marker'Length then
         return "";
      end if;

      for I in Lower_Line'First .. Lower_Line'Last - Lower_Marker'Length + 1 loop
         if Lower_Line (I .. I + Lower_Marker'Length - 1) = Lower_Marker then
            Start := I + Lower_Marker'Length;
            exit;
         end if;
      end loop;

      if Start = 0 then
         return "";
      end if;

      while Start <= Line'Last and then (Line (Start) = ' ' or else Line (Start) = ASCII.HT) loop
         Start := Start + 1;
      end loop;

      if Start > Line'Last then
         return "";
      end if;

      if Line (Start) = '"' then
         declare
            Stop : Natural := Start + 1;
         begin
            while Stop <= Line'Last and then Line (Stop) /= '"' loop
               Stop := Stop + 1;
            end loop;
            if Stop <= Line'Last and then Stop > Start + 1 then
               return Line (Start .. Stop);
            end if;
         end;
         return "";
      end if;

      if not Is_Name_Char (Line (Start)) then
         return "";
      end if;

      declare
         Stop : Natural := Start;
      begin
         while Stop + 1 <= Line'Last
           and then (Is_Name_Char (Line (Stop + 1))
                     or else Line (Stop + 1) = '.')
         loop
            Stop := Stop + 1;
         end loop;
         return Line (Start .. Stop);
      end;
   end Word_After;

   function Word_After_Code_Marker
     (Original_Line : String;
      Code_Line     : String;
      Marker        : String) return String
   is
      Name : constant String := Word_After (Code_Line, Marker);
   begin
      if Name'Length > 0 or else Marker /= "function" then
         return Name;
      end if;

      declare
         Lower_Code   : constant String := Lower (Code_Line);
         Lower_Marker : constant String := Lower (Marker);
         Start        : Natural := 0;
      begin
         if Lower_Code'Length < Lower_Marker'Length then
            return "";
         end if;

         for I in Lower_Code'First .. Lower_Code'Last - Lower_Marker'Length + 1 loop
            if Lower_Code (I .. I + Lower_Marker'Length - 1) = Lower_Marker then
               Start := I + Lower_Marker'Length;
               exit;
            end if;
         end loop;

         if Start = 0 then
            return "";
         end if;

         while Start <= Original_Line'Last
           and then (Original_Line (Start) = ' '
                     or else Original_Line (Start) = ASCII.HT)
         loop
            Start := Start + 1;
         end loop;

         if Start <= Original_Line'Last and then Original_Line (Start) = '"' then
            declare
               Stop : Natural := Start + 1;
            begin
               while Stop <= Original_Line'Last
                 and then Original_Line (Stop) /= '"'
               loop
                  Stop := Stop + 1;
               end loop;

               if Stop <= Original_Line'Last and then Stop > Start + 1 then
                  return Original_Line (Start .. Stop);
               end if;
            end;
         end if;
      end;

      return "";
   end Word_After_Code_Marker;

   procedure Clear (Map : in out Semantic_Map) is
   begin
      Map.Symbols := (others => <>);
      Map.Symbol_Overflow := False;
   end Clear;

   function Code_Prefix (Line : String) return String is
   begin
      --  Share the neutral Ada lexical safety pass so semantic colour symbols are
      --  learned only from code columns.  Comments, string literals, and simple
      --  character literals are replaced with spaces while preserving columns.
      return Editor.Ada_Syntax_Core.Sanitize_Line (Line);
   end Code_Prefix;

   procedure Learn_Declarations_From_Line
     (Map  : in out Semantic_Map;
      Line : String)
   is
      Code : constant String := Code_Prefix (Line);
      procedure Learn
        (Marker : String;
         Kind   : Editor.Syntax.Token_Kind;
         Done   : in out Boolean)
      is
         Name : constant String := Word_After_Code_Marker (Line, Code, Marker);
      begin
         if not Done and then Name'Length > 0 then
            Add_With_Qualified_Leaf (Map, Name, Kind);
            Done := True;
         end if;
      end Learn;

      Done : Boolean := False;
   begin
      Learn ("package body", Editor.Syntax.Package_Identifier, Done);
      Learn ("package", Editor.Syntax.Package_Identifier, Done);
      Learn ("procedure", Editor.Syntax.Subprogram_Identifier, Done);
      Learn ("function", Editor.Syntax.Subprogram_Identifier, Done);
      Learn ("subtype", Editor.Syntax.Type_Identifier, Done);
      Learn ("type", Editor.Syntax.Type_Identifier, Done);
      Learn ("task type", Editor.Syntax.Type_Identifier, Done);
      Learn ("task", Editor.Syntax.Type_Identifier, Done);
      Learn ("protected type", Editor.Syntax.Type_Identifier, Done);
      Learn ("protected", Editor.Syntax.Type_Identifier, Done);
      Learn ("entry", Editor.Syntax.Subprogram_Identifier, Done);
   end Learn_Declarations_From_Line;



   function Outline_Label_Name (Label : String) return String is
      Stop  : Natural := Label'Last;
      Start : Natural := Label'First;
   begin
      if Label'Length = 0 then
         return "";
      end if;

      while Stop >= Label'First
        and then (Label (Stop) = ' ' or else Label (Stop) = ASCII.HT)
      loop
         if Stop = Label'First then
            return "";
         end if;
         Stop := Stop - 1;
      end loop;

      --  Outline labels are user-facing strings such as "procedure Draw",
      --  "procedure body Draw", "record type Color", or
      --  "package Foo renames".  Store only the declared symbol, not the
      --  display prefix/suffix, so semantic lookup can match identifier tokens.
      declare
         Trimmed : constant String := Label (Label'First .. Stop);
         Lowered : constant String := Lower (Trimmed);
      begin
         if Lowered'Length > 8
           and then Lowered (Lowered'Last - 7 .. Lowered'Last) = " renames"
         then
            return Outline_Label_Name (Trimmed (Trimmed'First .. Trimmed'Last - 8));
         end if;
      end;

      Start := Stop;
      while Start > Label'First
        and then Label (Start - 1) /= ' '
        and then Label (Start - 1) /= ASCII.HT
      loop
         Start := Start - 1;
      end loop;

      return Label (Start .. Stop);
   end Outline_Label_Name;

   procedure Build_Map_From_Outline
     (Map   : in out Semantic_Map;
      Items : Editor.Outline.Outline_Item_Array)
   is
      function Kind_For_Item
        (Kind : Editor.Outline.Outline_Item_Kind) return Editor.Syntax.Token_Kind
      is
      begin
         case Kind is
            when Editor.Outline.Outline_Package
               | Editor.Outline.Outline_Package_Body =>
               return Editor.Syntax.Package_Identifier;
            when Editor.Outline.Outline_Type
               | Editor.Outline.Outline_Task
               | Editor.Outline.Outline_Protected =>
               return Editor.Syntax.Type_Identifier;
            when Editor.Outline.Outline_Subprogram
               | Editor.Outline.Outline_Procedure
               | Editor.Outline.Outline_Function =>
               return Editor.Syntax.Subprogram_Identifier;
            when Editor.Outline.Outline_Generic_Formal =>
               return Editor.Syntax.Generic_Formal;
            when others =>
               return Editor.Syntax.Identifier;
         end case;
      end Kind_For_Item;
   begin
      Clear (Map);
      for Item of Items loop
         declare
            K : constant Editor.Syntax.Token_Kind := Kind_For_Item (Item.Kind);
            L : constant String := Outline_Label_Name (To_String (Item.Label));
         begin
            if K /= Editor.Syntax.Identifier then
               Add_With_Qualified_Leaf (Map, L, K);
            end if;
         end;
      end loop;
   end Build_Map_From_Outline;

   procedure Build_Map_From_Outline_State
     (Map     : in out Semantic_Map;
      Outline : Editor.Outline.Outline_State)
   is
      function Kind_For_Item
        (Kind : Editor.Outline.Outline_Item_Kind) return Editor.Syntax.Token_Kind
      is
      begin
         case Kind is
            when Editor.Outline.Outline_Package
               | Editor.Outline.Outline_Package_Body =>
               return Editor.Syntax.Package_Identifier;
            when Editor.Outline.Outline_Type
               | Editor.Outline.Outline_Task
               | Editor.Outline.Outline_Protected =>
               return Editor.Syntax.Type_Identifier;
            when Editor.Outline.Outline_Subprogram
               | Editor.Outline.Outline_Procedure
               | Editor.Outline.Outline_Function =>
               return Editor.Syntax.Subprogram_Identifier;
            when Editor.Outline.Outline_Generic_Formal =>
               return Editor.Syntax.Generic_Formal;
            when others =>
               return Editor.Syntax.Identifier;
         end case;
      end Kind_For_Item;
   begin
      Clear (Map);
      for Index in 1 .. Editor.Outline.Item_Count (Outline) loop
         declare
            K : constant Editor.Syntax.Token_Kind :=
              Kind_For_Item (Editor.Outline.Item_Kind (Outline, Index));
            L : constant String :=
              Outline_Label_Name (Editor.Outline.Item_Label (Outline, Index));
         begin
            if K /= Editor.Syntax.Identifier then
               Add_With_Qualified_Leaf (Map, L, K);
            end if;
         end;
      end loop;
   end Build_Map_From_Outline_State;


   procedure Build_Map_From_Analysis
     (Map      : in out Semantic_Map;
      Analysis : Editor.Ada_Language_Model.Analysis_Result)
   is
      function Has_Metadata_Name (Name : String) return Boolean is
      begin
         return Kind_For_Identifier (Map, Name) /= Editor.Syntax.Identifier;
      end Has_Metadata_Name;

      procedure Add_Metadata_Name
        (Name              : Ada.Strings.Unbounded.Unbounded_String;
         Kind              : Editor.Syntax.Token_Kind;
         Preserve_Existing : Boolean := False)
      is
         Text : constant String := To_String (Name);
         Dot  : Natural := 0;
      begin
         if Text'Length = 0
           or else Kind = Editor.Syntax.Identifier
           or else Is_Recovered_Partial_Name (Text)
         then
            return;
         elsif not Preserve_Existing then
            Add_With_Qualified_Leaf (Map, Text, Kind);
            return;
         end if;

         if not Has_Metadata_Name (Text) then
            Add (Map, Text, Kind);
         end if;

         for I in reverse Text'Range loop
            if Text (I) = '.' then
               Dot := I;
               exit;
            end if;
         end loop;

         if Dot /= 0
           and then Dot < Text'Last
           and then not Has_Metadata_Name (Text (Dot + 1 .. Text'Last))
         then
            Add (Map, Text (Dot + 1 .. Text'Last), Kind);
         end if;
      end Add_Metadata_Name;
   begin
      Clear (Map);
      for Index in 1 .. Editor.Ada_Language_Model.Symbol_Count (Analysis) loop
         declare
            S : constant Editor.Ada_Language_Model.Symbol_Info :=
              Editor.Ada_Language_Model.Symbol_At (Analysis, Index);
            K : constant Editor.Syntax.Token_Kind :=
              Editor.Ada_Language_Model.Kind_To_Syntax_Kind (S.Kind);
            N : constant String := To_String (S.Name);
         begin
            if K /= Editor.Syntax.Identifier then
               Add_With_Qualified_Leaf (Map, N, K);
            end if;
         end;
      end loop;

      --  Case 761: newer parser/model metadata families are now consumed by
      --  semantic colouring through this parser-owned seam.  These names are
      --  still bounded map entries, not render-side parsing and not legality
      --  conclusions.  Metadata-only constructs are classified conservatively:
      --  context/use clause names navigate like package-like names, generic
      --  formal type metadata keeps its dedicated bucket, profile parameters
      --  remain value-like, and pragma identifiers/targets use existing pragma
      --  and value-like buckets.
      for Index in 1 .. Editor.Ada_Language_Model.Context_Clause_Count (Analysis) loop
         declare
            C : constant Editor.Ada_Language_Model.Visibility_Clause_Info :=
              Editor.Ada_Language_Model.Context_Clause_At (Analysis, Index);
         begin
            Add_Metadata_Name (C.Name, Editor.Syntax.Package_Identifier, Preserve_Existing => True);
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Language_Model.Use_Clause_Count (Analysis) loop
         declare
            U : constant Editor.Ada_Language_Model.Visibility_Clause_Info :=
              Editor.Ada_Language_Model.Use_Clause_At
                (Analysis, Editor.Ada_Language_Model.Scope_Id'Last, Index);
         begin
            case U.Kind is
               when Editor.Ada_Language_Model.Visibility_Use_Package_Clause =>
                  Add_Metadata_Name (U.Name, Editor.Syntax.Package_Identifier, Preserve_Existing => True);
               when Editor.Ada_Language_Model.Visibility_Use_Type_Clause
                  | Editor.Ada_Language_Model.Visibility_Use_All_Type_Clause =>
                  Add_Metadata_Name (U.Name, Editor.Syntax.Type_Identifier, Preserve_Existing => True);
               when others =>
                  null;
            end case;
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Language_Model.Generic_Formal_Type_Metadata_Count (Analysis) loop
         declare
            F : constant Editor.Ada_Language_Model.Generic_Formal_Type_Info :=
              Editor.Ada_Language_Model.Generic_Formal_Type_Metadata_At
                (Analysis, Editor.Ada_Language_Model.No_Symbol, Index);
         begin
            Add_Metadata_Name (F.Name, Editor.Syntax.Generic_Formal, Preserve_Existing => True);
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Language_Model.Profile_Parameter_Count (Analysis) loop
         declare
            P : constant Editor.Ada_Language_Model.Profile_Parameter_Info :=
              Editor.Ada_Language_Model.Profile_Parameter_At
                (Analysis, Editor.Ada_Language_Model.No_Symbol, Index);
         begin
            Add_Metadata_Name (P.Name, Editor.Syntax.Parameter_Identifier, Preserve_Existing => True);
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Language_Model.Pragma_Metadata_Count (Analysis) loop
         declare
            P : constant Editor.Ada_Language_Model.Pragma_Info :=
              Editor.Ada_Language_Model.Pragma_Metadata_At (Analysis, Index);
         begin
            Add_Metadata_Name (P.Name, Editor.Syntax.Pragma_Name, Preserve_Existing => True);
            Add_Metadata_Name (P.Target_Name, Editor.Syntax.Parameter_Identifier, Preserve_Existing => True);
         end;
      end loop;

      --  Representation/operational projection metadata carries source forms
      --  for aspects and pragmas added after the original semantic-colouring
      --  map.  Attribute/aspect names can safely use the existing Attribute or
      --  Aspect_Name buckets; retained target names stay value-like unless a
      --  concrete target symbol later provides a sharper symbol kind.
      for Index in 1 .. Editor.Ada_Language_Model.Representation_Clause_Count (Analysis) loop
         declare
            R : constant Editor.Ada_Language_Model.Representation_Clause_Info :=
              Editor.Ada_Language_Model.Representation_Clause_At
                (Analysis, Editor.Ada_Language_Model.No_Symbol, Index);
            Target_Kind : Editor.Syntax.Token_Kind := Editor.Syntax.Parameter_Identifier;
         begin
            if R.Target_Symbol /= Editor.Ada_Language_Model.No_Symbol then
               Target_Kind := Editor.Ada_Language_Model.Kind_To_Syntax_Kind
                 (Editor.Ada_Language_Model.Symbol
                    (Analysis, R.Target_Symbol).Kind);
            end if;

            Add_Metadata_Name (R.Target_Name, Target_Kind, Preserve_Existing => True);

            case R.Source_Form is
               when Editor.Ada_Language_Model.Representation_Source_Aspect =>
                  Add_Metadata_Name (R.Attribute_Name, Editor.Syntax.Aspect_Name, Preserve_Existing => True);
               when Editor.Ada_Language_Model.Representation_Source_Pragma =>
                  Add_Metadata_Name (R.Attribute_Name, Editor.Syntax.Pragma_Name, Preserve_Existing => True);
               when others =>
                  Add_Metadata_Name (R.Attribute_Name, Editor.Syntax.Attribute, Preserve_Existing => True);
            end case;
         end;
      end loop;

      --  executable-statement semantic bindings are parser-owned
      --  metadata, not render-side parsing.  Classify only definition-like or
      --  syntax-role-safe unresolved bindings.  Selector-like roles introduced
      --  by the generic/aggregate grammar-depth passes intentionally degrade to
      --  ordinary identifiers unless the resolver has a concrete target symbol:
      --  a generic actual selector or aggregate component selector is not, by
      --  itself, a local value declaration.
      for Index in 1 .. Editor.Ada_Language_Model.Executable_Binding_Count (Analysis) loop
         declare
            B : constant Editor.Ada_Language_Model.Executable_Binding_Info :=
              Editor.Ada_Language_Model.Executable_Binding_At (Analysis, Index);
            K : Editor.Syntax.Token_Kind := Editor.Syntax.Identifier;
         begin
            if B.Target_Symbol /= Editor.Ada_Language_Model.No_Symbol then
               K := Editor.Ada_Language_Model.Kind_To_Syntax_Kind
                 (Editor.Ada_Language_Model.Symbol
                    (Analysis, B.Target_Symbol).Kind);
            else
               case B.Kind is
                  when Editor.Ada_Language_Model.Binding_Call_Target
                     | Editor.Ada_Language_Model.Binding_Call_Selected_Operation
                     | Editor.Ada_Language_Model.Binding_Call_Entry_Family_Candidate
                     | Editor.Ada_Language_Model.Binding_Select_Entry_Call
                     | Editor.Ada_Language_Model.Binding_Requeue_Target
                     | Editor.Ada_Language_Model.Binding_Accept_Entry =>
                     K := Editor.Syntax.Subprogram_Identifier;

                  when Editor.Ada_Language_Model.Binding_Qualified_Expression_Target
                     | Editor.Ada_Language_Model.Binding_Type_Conversion_Target
                     | Editor.Ada_Language_Model.Binding_Allocator =>
                     K := Editor.Syntax.Type_Identifier;

                  when Editor.Ada_Language_Model.Binding_Loop_Parameter
                     | Editor.Ada_Language_Model.Binding_Assignment_Target
                     | Editor.Ada_Language_Model.Binding_Declare_Object
                     | Editor.Ada_Language_Model.Binding_Return_Object
                     | Editor.Ada_Language_Model.Binding_Return_Object_Defining_Name
                     | Editor.Ada_Language_Model.Binding_Quantified_Parameter
                     | Editor.Ada_Language_Model.Binding_Pragma_Argument
                     | Editor.Ada_Language_Model.Binding_Aspect_Expression
                     | Editor.Ada_Language_Model.Binding_Case_Choice
                     | Editor.Ada_Language_Model.Binding_Case_Expression_Selector
                     | Editor.Ada_Language_Model.Binding_Case_Expression_Choice
                     | Editor.Ada_Language_Model.Binding_Conditional_Expression_Condition
                     | Editor.Ada_Language_Model.Binding_Conditional_Expression_Branch
                     | Editor.Ada_Language_Model.Binding_Raise_Target
                     | Editor.Ada_Language_Model.Binding_Raise_Expression_Target
                     | Editor.Ada_Language_Model.Binding_Delay_Target
                     | Editor.Ada_Language_Model.Binding_Abort_Target
                     | Editor.Ada_Language_Model.Binding_Delta_Aggregate_Base
                     | Editor.Ada_Language_Model.Binding_Iteration_Filter
                     | Editor.Ada_Language_Model.Binding_Select_Guard
                     | Editor.Ada_Language_Model.Binding_Select_Delay_Target
                     | Editor.Ada_Language_Model.Binding_Select_Terminate
                     | Editor.Ada_Language_Model.Binding_Select_Abort
                     | Editor.Ada_Language_Model.Binding_Entry_Barrier
                     | Editor.Ada_Language_Model.Binding_Accept_Parameter
                     | Editor.Ada_Language_Model.Binding_Entry_Family_Index
                     | Editor.Ada_Language_Model.Binding_Exception_Handler_Choice
                     | Editor.Ada_Language_Model.Binding_Exception_Occurrence
                     | Editor.Ada_Language_Model.Binding_Block_Label
                     | Editor.Ada_Language_Model.Binding_Label_Declaration
                     | Editor.Ada_Language_Model.Binding_Exit_Target
                     | Editor.Ada_Language_Model.Binding_Goto_Target =>
                     K := Editor.Syntax.Parameter_Identifier;

                  when Editor.Ada_Language_Model.Binding_Selected_Component
                     | Editor.Ada_Language_Model.Binding_Call_Selected_Prefix
                     | Editor.Ada_Language_Model.Binding_Call_Dispatching_Prefix
                     | Editor.Ada_Language_Model.Binding_Call_Indexed_Prefix
                     | Editor.Ada_Language_Model.Binding_Array_Index
                     | Editor.Ada_Language_Model.Binding_Array_Slice
                     | Editor.Ada_Language_Model.Binding_Range_Bound
                     | Editor.Ada_Language_Model.Binding_Quantified_Source
                     | Editor.Ada_Language_Model.Binding_Dereference
                     | Editor.Ada_Language_Model.Binding_Named_Actual
                     | Editor.Ada_Language_Model.Binding_Generic_Actual_Selector
                     | Editor.Ada_Language_Model.Binding_Aggregate_Component
                     | Editor.Ada_Language_Model.Binding_Aggregate_Component_Selector
                     | Editor.Ada_Language_Model.Binding_Delta_Aggregate_Component
                     | Editor.Ada_Language_Model.Binding_Attribute_Prefix
                     | Editor.Ada_Language_Model.Binding_Return_Target
                     | Editor.Ada_Language_Model.Binding_Condition_Target
                     | Editor.Ada_Language_Model.Binding_Iteration_Source
                     | Editor.Ada_Language_Model.Binding_Any =>
                     K := Editor.Syntax.Identifier;
               end case;
            end if;

            if Is_Recovered_Unresolved_Binding (B) then
               K := Editor.Syntax.Identifier;
            end if;

            if K /= Editor.Syntax.Identifier then
               if B.Target_Symbol /= Editor.Ada_Language_Model.No_Symbol then
                  Add_With_Qualified_Leaf (Map, To_String (B.Name), K);
               else
                  Add_Metadata_Name (B.Name, K, Preserve_Existing => True);
               end if;
            end if;
         end;
      end loop;

      if Editor.Ada_Language_Model.Overflowed (Analysis) then
         Map.Symbol_Overflow := True;
      end if;
   end Build_Map_From_Analysis;

   function Kind_For_Identifier
     (Map  : Semantic_Map;
      Name : String) return Editor.Syntax.Token_Kind
   is
      Key : constant String := Lower (Name);
      Len : constant Natural := Natural'Min (Key'Length, Stored_Name'Length);
   begin
      if Len = 0 then
         return Editor.Syntax.Identifier;
      elsif Key'Length > Stored_Name'Length then
         --  completeness: lookup must mirror Add's no-truncation
         --  policy.  An overlong token sharing the first 64 columns with a
         --  retained short declaration must not be coloured as that shorter
         --  symbol.  Long identifiers degrade conservatively to lexical
         --  Identifier.
         return Editor.Syntax.Identifier;
      end if;

      for I in Map.Symbols'Range loop
         if Map.Symbols (I).Used
           and then Map.Symbols (I).Len = Len
           and then Map.Symbols (I).Name (1 .. Len) = Key (Key'First .. Key'First + Len - 1)
         then
            return Map.Symbols (I).Kind;
         end if;
      end loop;

      return Editor.Syntax.Identifier;
   end Kind_For_Identifier;

   function Kind_For_Identifier_In_Scope
     (Analysis   : Editor.Ada_Language_Model.Analysis_Result;
      Name       : String;
      From_Scope : Editor.Ada_Language_Model.Symbol_Id)
      return Editor.Syntax.Token_Kind
   is
      R : Editor.Ada_Symbol_Resolver.Resolution_Result;
   begin
      if Name'Length = 0 then
         return Editor.Syntax.Identifier;
      elsif Name'Length > Stored_Name'Length then
         --  completeness: the parser-backed scoped semantic path must
         --  obey the same bounded-name policy as the flat Semantic_Map.  The
         --  render path may receive a retained language-model symbol with an
         --  overlong Ada identifier, but colouring that token would bypass the
         --  fixed semantic key budget and make scoped rendering less
         --  conservative than semantic.refresh-buffer.  Degrade instead of
         --  resolving or prefix-matching overlong tokens.
         return Editor.Syntax.Identifier;
      end if;

      R := Editor.Ada_Symbol_Resolver.Resolve_In_Scope
        (Analysis, Name, From_Scope);

      if R.Matches.Is_Empty then
         return Editor.Syntax.Identifier;
      end if;

      return Editor.Ada_Language_Model.Kind_To_Syntax_Kind
        (Editor.Ada_Language_Model.Symbol
           (Analysis, R.Matches.First_Element).Kind);
   end Kind_For_Identifier_In_Scope;

   function Symbol_Count
     (Map : Semantic_Map) return Natural
   is
      Count : Natural := 0;
   begin
      for I in Map.Symbols'Range loop
         if Map.Symbols (I).Used then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Symbol_Count;

   function Symbol_Cap_Reached
     (Map : Semantic_Map) return Boolean
   is
   begin
      return Map.Symbol_Overflow;
   end Symbol_Cap_Reached;

end Editor.Syntax_Semantics;
