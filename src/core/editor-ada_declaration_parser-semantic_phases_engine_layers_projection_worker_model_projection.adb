with Ada.Characters.Latin_1;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Text_Helpers;
with Editor.Ada_Declaration_Parser.Declaration_Projection_Helpers;
with Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers;
with Editor.Ada_Declaration_Parser.Declaration_Collectors;
with Editor.Ada_Declaration_Parser.Attribute_Value_Helpers;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Line_Dispatch;
with Editor.Ada_Declaration_Parser.Metadata_Helpers;
with Editor.Ada_Declaration_Parser.Legality_Profile_Helpers;
with Editor.Ada_Declaration_Parser.Name_Profile_Helpers;
with Editor.Ada_Declaration_Parser.Syntax_Tree_Helpers;
with Editor.Ada_Declaration_Parser.Pragma_Helpers;
with Editor.Ada_Declaration_Parser.Profile_Parameter_Collectors;
with Editor.Ada_Declaration_Parser.Pragma_Helpers;
with Editor.Ada_Declaration_Parser.Representation_Application;
with Editor.Ada_Declaration_Parser.Representation_Metadata;
with Editor.Ada_Declaration_Parser.Representation_Static_Values;
with Editor.Ada_Declaration_Parser.Same_Line_Declarations;
with Editor.Ada_Declaration_Parser.Same_Line_Emitters;
with Editor.Ada_Declaration_Parser.Target_Helpers;
with Editor.Ada_Declaration_Parser.Source_Awareness;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Phase_Types;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Declaration_Collection;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Derivation;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_String_Evaluation;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Discrete_Evaluation;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Numeric_Parsing;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Legality;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Executable_Binding;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Publication;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Pipeline;
with Editor.Ada_Syntax_Core;
with Editor.Ada_Language_Model;

use Editor.Ada_Language_Model;
use Editor.Text_Helpers;
use Editor.Ada_Declaration_Parser.Lexical_Helpers;
use Editor.Ada_Declaration_Parser.Source_Awareness;
use Editor.Ada_Declaration_Parser.Metadata_Helpers;
use Editor.Ada_Declaration_Parser.Pragma_Helpers;
package body Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection is

   procedure Project_Syntax_Tree_Into_Model
     (Analysis    : in out Analysis_Result;
      Tree        : Editor.Ada_Syntax_Tree.Tree_Type;
      Source_Text : String)
   is
      use Editor.Ada_Syntax_Tree;

      Count : constant Natural := Node_Count (Tree);
      package Phase_Types renames
        Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Phase_Types;
      package Declaration_Collection renames
        Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Declaration_Collection;
      package Target_Derivation renames
        Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Derivation;
      package Target_String_Evaluation renames
        Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_String_Evaluation;
      package Target_Discrete_Evaluation renames
        Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Discrete_Evaluation;
      package Target_Numeric_Parsing renames
        Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Numeric_Parsing;
      package Legality renames
        Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Legality;
      package Executable_Binding renames
        Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Executable_Binding;
      package Publication renames
        Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Publication;
      package Projection_Pipeline renames
        Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Pipeline;

      subtype Static_Named_Number_Info is Phase_Types.Static_Named_Number_Info;
      subtype Static_Numeric_Name_Table is Phase_Types.Static_Numeric_Name_Table;
      subtype Static_Type_Range_Info is Phase_Types.Static_Type_Range_Info;
      subtype Static_Projection_Context is Phase_Types.Static_Projection_Context;
      subtype Metadata_Fact_Info is Phase_Types.Metadata_Fact_Info;
      subtype Static_Declaration_Info is Phase_Types.Static_Declaration_Info;
      subtype Declaration_Collection_Context is Declaration_Collection.Context;
      subtype Target_Derivation_Context is Target_Derivation.Context;
      subtype Legality_Context is Legality.Context;
      subtype Executable_Binding_Context is Executable_Binding.Context;
      subtype Publication_Context is Publication.Context;


      Context : Projection_Pipeline.Context (Natural'Max (Count, 1));

      Node_Symbols renames Context.Declaration.Node_Symbols;
      function To_Model_Range (R : Editor.Ada_Syntax_Tree.Source_Range) return Editor.Ada_Language_Model.Source_Range is
      begin
         return Declaration_Projection_Helpers.To_Model_Range (R);
      end To_Model_Range;

      function First_Child_Label
        (Parent : Node_Id;
         Kind   : Node_Kind) return String
      is
      begin
         return Declaration_Projection_Helpers.First_Child_Label (Tree, Parent, Kind);
      end First_Child_Label;

      function Source_Index_For
        (Line   : Positive;
         Column : Positive) return Natural
      is
      begin
         return Declaration_Projection_Helpers.Source_Index_For (Source_Text, Line, Column);
      end Source_Index_For;

      function Has_Child_Kind
        (Parent : Node_Id;
         Kind   : Node_Kind) return Boolean
      is
      begin
         return Declaration_Projection_Helpers.Has_Child_Kind (Tree, Parent, Kind);
      end Has_Child_Kind;

      function Ancestor_Symbol (Id : Node_Id) return Symbol_Id is
         P : Node_Id;
      begin
         if Id = No_Node then
            return No_Symbol;
         end if;

         P := Node (Tree, Id).Parent;
         while P /= No_Node loop
            if Natural (P) >= Natural (Node_Symbols'First)
              and then Natural (P) <= Natural (Node_Symbols'Last)
              and then Node_Symbols (Positive (P)) /= No_Symbol
            then
               return Node_Symbols (Positive (P));
            end if;
            P := Node (Tree, P).Parent;
         end loop;
         return No_Symbol;
      end Ancestor_Symbol;

      function Has_Ancestor_Kind
        (Id   : Node_Id;
         Kind : Node_Kind) return Boolean
      is
      begin
         return Declaration_Projection_Helpers.Has_Ancestor_Kind (Tree, Id, Kind);
      end Has_Ancestor_Kind;

      function Has_Direct_Generic_Parent (N : Node_Info) return Boolean
      is
      begin
         return Declaration_Projection_Helpers.Has_Direct_Generic_Parent (Tree, N);
      end Has_Direct_Generic_Parent;

      function Pragma_Metadata_Name (Text : String) return String
        renames Editor.Ada_Declaration_Parser.Pragma_Helpers.Pragma_Metadata_Name;

      function Pragma_Metadata_Argument_Count (Node : Node_Info) return Natural is
      begin
         return Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers
           .Pragma_Metadata_Argument_Count (Node);
      end Pragma_Metadata_Argument_Count;

      function Pragma_Metadata_Named_Argument_Count (Node : Node_Info) return Natural is
      begin
         return Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers
           .Pragma_Metadata_Named_Argument_Count (Node);
      end Pragma_Metadata_Named_Argument_Count;

      function Pragma_Metadata_Target (Node : Node_Info) return String is
      begin
         return Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers
           .Pragma_Metadata_Target (Node);
      end Pragma_Metadata_Target;

      function Pragma_Placement_For_Node
        (Node  : Node_Info;
         Owner : Symbol_Id) return Pragma_Placement_Kind
      is
      begin
         return Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers
           .Pragma_Placement_For_Node (Tree, Node, Owner);
      end Pragma_Placement_For_Node;

      function Syntax_Node_Symbol_Kind (N : Node_Info) return Symbol_Kind is
      begin
         return Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers
           .Syntax_Node_Symbol_Kind (Tree, N);
      end Syntax_Node_Symbol_Kind;

      function Syntax_Node_Flags (N : Node_Info) return Declaration_Flags is
      begin
         return Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers
           .Syntax_Node_Flags (Tree, N);
      end Syntax_Node_Flags;

      function Qualified_Name
        (Symbol    : Symbol_Info;
         Remaining : Natural;
         Truncated : in out Boolean) return String
      is
      begin
         return Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers
           .Qualified_Name (Analysis, Symbol, Remaining, Truncated);
      end Qualified_Name;

      function Qualified_Name (Symbol : Symbol_Info) return String is
      begin
         return Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers
           .Qualified_Name (Analysis, Symbol);
      end Qualified_Name;

      function Kind_Compatible
        (Existing : Symbol_Kind;
         Wanted   : Symbol_Kind) return Boolean
        renames Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers.Kind_Compatible;

      function Same_Line_Projection_Compatible
        (Existing : Symbol_Kind;
         Wanted   : Symbol_Kind) return Boolean
        renames Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers.Same_Line_Projection_Compatible;

      function Preferred_Merged_Kind
        (Existing : Symbol_Kind;
         Wanted   : Symbol_Kind) return Symbol_Kind
        renames Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers.Preferred_Merged_Kind;

      function Target_Name_Matches
        (Symbol : Symbol_Info;
         Name   : String) return Boolean
      is
      begin
         return Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers
           .Target_Name_Matches (Analysis, Symbol, Name);
      end Target_Name_Matches;

      function Direct_Name_Matches
        (Symbol : Symbol_Info;
         Name   : String) return Boolean
        renames Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers.Direct_Name_Matches;

      function Is_Access_Subprogram_Profile_Projection
        (Kind   : Symbol_Kind;
         Parent : Symbol_Id) return Boolean
      is
      begin
         if Kind /= Symbol_Discriminant
           or else Parent = No_Symbol
           or else Natural (Parent) > Symbol_Count (Analysis)
         then
            return False;
         end if;

         declare
            Parent_Info : constant Symbol_Info :=
              Symbol_At (Analysis, Positive (Parent));
         begin
            return Parent_Info.Flags.Has_Access_Subprogram_Metadata;
         end;
      end Is_Access_Subprogram_Profile_Projection;

      function Find_Existing
        (Name : String;
         Kind : Symbol_Kind;
         Line : Positive) return Symbol_Id
      is
      begin
         return Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers
           .Find_Existing (Analysis, Name, Kind, Line);
      end Find_Existing;

      function Parent_Selected_Name (Symbol : Symbol_Info) return String is
      begin
         return Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers
           .Parent_Selected_Name (Analysis, Symbol);
      end Parent_Selected_Name;

      function Clean_Metadata_Name (Name : String) return String
        renames Editor.Ada_Declaration_Parser.Metadata_Helpers.Clean_Metadata_Name;

      function Find_Metadata_Target_Direct (Target_Name : String) return Symbol_Id
      is
      begin
         return Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers
           .Find_Metadata_Target_Direct (Analysis, Target_Name);
      end Find_Metadata_Target_Direct;

      function Resolve_Renamed_Metadata_Target
        (Alias : Symbol_Info;
         Depth : Natural := 0) return Symbol_Id
      is
      begin
         return Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers
           .Resolve_Renamed_Metadata_Target (Analysis, Alias, Depth);
      end Resolve_Renamed_Metadata_Target;

      function Selected_Prefix_Matches_Target
        (Actual_Parent : String;
         Requested_Prefix : String) return Boolean
      is
      begin
         return Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers
           .Selected_Prefix_Matches_Target (Analysis, Actual_Parent, Requested_Prefix);
      end Selected_Prefix_Matches_Target;

      function Find_Metadata_Target (Target_Name : String) return Symbol_Id
      is
      begin
         return Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers
           .Find_Metadata_Target (Analysis, Target_Name);
      end Find_Metadata_Target;

      procedure Apply_Metadata_To_Target
        (Target_Name : String;
         Flags       : Declaration_Flags)
      is
      begin
         Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers
           .Apply_Metadata_To_Target (Analysis, Target_Name, Flags);
      end Apply_Metadata_To_Target;

      function Last_Child_Label
        (Parent : Node_Id;
         Kind   : Node_Kind) return String
      is
         Result : Unbounded_String := Null_Unbounded_String;
      begin
         for C in 1 .. Child_Count (Tree, Parent) loop
            declare
               Child_Id : constant Node_Id := Child_At (Tree, Parent, C);
               Child    : constant Node_Info := Node (Tree, Child_Id);
            begin
               if Child.Kind = Kind then
                  Result := Child.Label;
               end if;
            end;
         end loop;
         return To_String (Result);
      end Last_Child_Label;

      function Parent_Representation_Target (Component_Node : Node_Id) return Symbol_Id is
      begin
         return Representation_Application.Parent_Representation_Target
           (Tree => Tree,
            First_Child_Label => First_Child_Label'Unrestricted_Access,
            Find_Metadata_Target => Find_Metadata_Target'Unrestricted_Access,
            Component_Node => Component_Node);
      end Parent_Representation_Target;

      function Find_Component_Symbol
        (Target : Symbol_Id;
         Name   : String) return Symbol_Id
      is
      begin
         return Representation_Application.Find_Component_Symbol
           (Analysis,
            Normalize_Name'Unrestricted_Access,
            Target,
            Name);
      end Find_Component_Symbol;


      function Find_Enumeration_Literal_Symbol
        (Target : Symbol_Id;
         Name   : String) return Symbol_Id
      is
      begin
         return Representation_Application.Find_Enumeration_Literal_Symbol
           (Analysis,
            Normalize_Name'Unrestricted_Access,
            Target,
            Name);
      end Find_Enumeration_Literal_Symbol;

      function Enumeration_Literal_Symbol_At_Position
        (Target   : Symbol_Id;
         Position : Positive) return Symbol_Id
      is
      begin
         return Representation_Application.Enumeration_Literal_Symbol_At_Position
           (Analysis,
            Target,
            Position);
      end Enumeration_Literal_Symbol_At_Position;

      function Symbol_Name_Or_Empty (Id : Symbol_Id) return String is
      begin
         return Representation_Application.Symbol_Name_Or_Empty (Analysis, Id);
      end Symbol_Name_Or_Empty;

      procedure Parse_Static_Natural
        (Text  : String;
         Valid : out Boolean;
         Value : out Natural);
      procedure Parse_Static_Integer
        (Text  : String;
         Valid : out Boolean;
         Value : out Integer);
      function Is_Static_Numeric_Value (Text : String) return Boolean;
      function Static_Integer_Name_Value
        (Name  : String;
         Value : out Integer) return Boolean;
      function Static_Type_Range
        (Name     : String;
         Has_Low  : out Boolean;
         Low      : out Integer;
         Has_High : out Boolean;
         High     : out Integer) return Boolean;
      function Static_Value_In_Type_Range
        (Type_Name : String;
         Value     : Natural) return Boolean;
      function Static_Type_Modulus
        (Name  : String;
         Value : out Natural) return Boolean;
      function Static_Type_Width
        (Name  : String;
         Value : out Natural) return Boolean;
      function Static_Attribute_Value
        (Name      : String;
         Attribute : String;
         Value     : out Natural) return Boolean;
      function Static_Numeric_Name_Exists (Name : String) return Boolean;
      procedure Register_Static_Numeric_Name (Name : String);
      function Is_Simple_Static_Type_Name (Text : String) return Boolean;
      function Canonical_Static_Type_Name (Name : String) return String;
      function Static_Subtype_Root (Name : String) return String;
      function Static_Discrete_Literal_Position
        (Type_Name    : String;
         Literal_Text : String;
         Position     : out Natural) return Boolean;
      function Static_Discrete_Value_String_Position
        (Type_Name   : String;
         String_Text : String;
         Position    : out Natural) return Boolean;
      function Static_Discrete_Constant_Position
        (Type_Name : String;
         Name      : String;
         Position  : out Natural) return Boolean;

      function Static_Numeric_Name_Exists (Name : String) return Boolean is
      begin
         return Target_Derivation.Static_Numeric_Name_Exists
           (Context.Target, Name);
      end Static_Numeric_Name_Exists;

      procedure Register_Static_Numeric_Name (Name : String) is
      begin
         Target_Derivation.Register_Static_Numeric_Name (Context.Target, Name);
      end Register_Static_Numeric_Name;

      function Is_Static_Numeric_Value (Text : String) return Boolean is
         Natural_Valid : Boolean := False;
         Natural_Value : Natural := 0;
         Integer_Valid : Boolean := False;
         Integer_Value : Integer := 0;
      begin
         Parse_Static_Natural (Text, Natural_Valid, Natural_Value);
         if Natural_Valid then
            return True;
         end if;

         Parse_Static_Integer (Text, Integer_Valid, Integer_Value);
         return Integer_Valid
           or else Attribute_Value_Helpers.Has_Static_Numeric_Tokens
             (Text, Static_Numeric_Name_Exists'Unrestricted_Access);
      end Is_Static_Numeric_Value;

      function Static_Named_Number_Value
        (Name  : String;
         Value : out Natural) return Boolean
      is
      begin
         return Target_Derivation.Static_Named_Number_Value
           (Context.Target, Name, Value);
      end Static_Named_Number_Value;

      function Static_Integer_Name_Value
        (Name  : String;
         Value : out Integer) return Boolean
      is
      begin
         return Target_Derivation.Static_Integer_Name_Value
           (Context.Target, Name, Value);
      end Static_Integer_Name_Value;

      function Static_Type_Range
        (Name     : String;
         Has_Low  : out Boolean;
         Low      : out Integer;
         Has_High : out Boolean;
         High     : out Integer) return Boolean
      is
      begin
         return Target_Derivation.Static_Type_Range
           (Context.Target, Name, Has_Low, Low, Has_High, High);
      end Static_Type_Range;

      function Static_Value_In_Type_Range
        (Type_Name : String;
         Value     : Natural) return Boolean
      is
      begin
         return Target_Derivation.Static_Value_In_Type_Range
           (Context.Target, Type_Name, Value);
      end Static_Value_In_Type_Range;

      function Static_Type_Modulus
        (Name  : String;
         Value : out Natural) return Boolean
      is
      begin
         return Target_Derivation.Static_Type_Modulus
           (Context.Target, Name, Value);
      end Static_Type_Modulus;

      function Static_Type_Is_Character (Name : String) return Boolean;

      function Static_Type_Width
        (Name  : String;
         Value : out Natural) return Boolean
      is
      begin
         return Target_Derivation.Static_Type_Width
           (Context.Target, Name, Value);
      end Static_Type_Width;

      function Static_Attribute_Value
        (Name      : String;
         Attribute : String;
         Value     : out Natural) return Boolean
      is
      begin
         return Target_Derivation.Static_Attribute_Value
           (Context.Target, Name, Attribute, Value);
      end Static_Attribute_Value;

      procedure Register_Static_Attribute_Value
        (Name      : String;
         Attribute : String;
         Value     : Natural)
      is
      begin
         Target_Derivation.Register_Static_Attribute_Value
           (Context.Target, Name, Attribute, Value);
      end Register_Static_Attribute_Value;

      procedure Register_Static_Representation_Attribute_Value
        (Name      : String;
         Attribute : String;
         Value     : Natural)
      is
      begin
         Target_Derivation.Register_Static_Representation_Attribute_Value
           (Context.Target, Name, Attribute, Value);
      end Register_Static_Representation_Attribute_Value;

      function Is_Simple_Static_Type_Name (Text : String) return Boolean is
         T : constant String := Trim (Text);

      begin
         if T = "" or else not Is_Name_Start (T (T'First)) then
            return False;
         end if;

         for C of T loop
            if not Is_Name_Char (C) then
               return False;
            end if;
         end loop;

         return True;
      end Is_Simple_Static_Type_Name;

      function Static_Type_Is_Character (Name : String) return Boolean is
      begin
         return Target_Derivation.Static_Type_Is_Character
           (Context.Target, Name);
      end Static_Type_Is_Character;

      function Canonical_Static_Type_Name (Name : String) return String is
      begin
         return Target_Derivation.Canonical_Static_Type_Name (Name);
      end Canonical_Static_Type_Name;

      function Static_Subtype_Root (Name : String) return String is
      begin
         return Target_Derivation.Static_Subtype_Root (Context.Target, Name);
      exception
         when Constraint_Error =>
            return Canonical_Static_Type_Name (Name);
      end Static_Subtype_Root;

      function Static_Subtypes_Compatible
        (Left_Name  : String;
         Right_Name : String) return Boolean
      is
      begin
         return Static_Subtype_Root (Left_Name) = Static_Subtype_Root (Right_Name);
      end Static_Subtypes_Compatible;

      function Static_String_Default_Value
        (Default_Text : String;
         Image_Text   : out Unbounded_String) return Boolean;

      function Static_String_Bound_Value
        (Name       : String;
         Attr_Name  : String;
         Bound      : out Natural) return Boolean;


      function Static_String_Subtype_Length_Compatible
        (Type_Name  : String;
         Image_Text : Unbounded_String) return Boolean
      is
      begin
         return Target_Derivation.Static_String_Subtype_Length_Compatible
           (Context.Target, Type_Name, Image_Text);
      end Static_String_Subtype_Length_Compatible;

      function Static_String_Subtype_Bound_Value
        (Type_Name : String;
         Attr_Name : String;
         Bound     : out Natural) return Boolean
      is
      begin
         return Target_Derivation.Static_String_Subtype_Bound_Value
           (Context.Target, Type_Name, Attr_Name, Bound);
      end Static_String_Subtype_Bound_Value;

      function Static_Enumeration_Literal_Position
        (Type_Name    : String;
         Literal_Name : String;
         Position     : out Natural) return Boolean
      is
      begin
         return Target_Derivation.Static_Enumeration_Literal_Position
           (Context.Target, Type_Name, Literal_Name, Position);
      end Static_Enumeration_Literal_Position;

      function Static_Character_Literal_Position
        (Literal_Text : String;
         Position     : out Natural) return Boolean
      is
         L : constant String := Trim (Literal_Text);
      begin
         Position := 0;

         if L'Length = 3
           and then L (L'First) = Character'Val (39)
           and then L (L'Last) = Character'Val (39)
         then
            Position := Character'Pos (L (L'First + 1));
            return True;
         elsif L'Length = 4
           and then L (L'First) = Character'Val (39)
           and then L (L'First + 1) = Character'Val (39)
           and then L (L'First + 2) = Character'Val (39)
           and then L (L'First + 3) = Character'Val (39)
         then
            --  Ada spells an apostrophe character literal as four
            --  consecutive apostrophes.  Keep this decoded at the shared
            --  discrete-character boundary so Character'Pos, typed Character
            --  constants, and string concatenation all agree on the value.
            Position := Character'Pos (Character'Val (39));
            return True;
         else
            return False;
         end if;
      exception
         when Constraint_Error =>
            return False;
      end Static_Character_Literal_Position;


      function Static_Discrete_Literal_Position
        (Type_Name    : String;
         Literal_Text : String;
         Position     : out Natural) return Boolean
      is
         T : constant String := Normalize_Name (Type_Name);
         L : constant String := Trim (Literal_Text);
         NL : constant String := Normalize_Name (L);
      begin
         Position := 0;

         if T = "" or else L = "" then
            return False;
         end if;

         if T = "boolean" or else T = "standard.boolean" then
            if NL = "false" then
               Position := 0;
               return True;
            elsif NL = "true" then
               Position := 1;
               return True;
            else
               return False;
            end if;
         elsif Static_Type_Is_Character (Type_Name) then
            --  Bounded retained static evaluation for ordinary character
            --  literals, Character subtype aliases/derivations, and the Ada
            --  apostrophe literal spelling handled by
            --  Static_Character_Literal_Position.
            return Static_Character_Literal_Position (L, Position);
         end if;

         return Static_Enumeration_Literal_Position (Type_Name, L, Position);
      exception
         when Constraint_Error =>
            return False;
      end Static_Discrete_Literal_Position;


      function Static_Discrete_Default_Position
        (Type_Name    : String;
         Default_Text : String;
         Position     : out Natural) return Boolean;

      function Static_Discrete_Position_Image
        (Type_Name  : String;
         Position   : Natural;
         Image_Text : out Unbounded_String) return Boolean
      is
         T : constant String := Normalize_Name (Type_Name);
      begin
         Image_Text := Null_Unbounded_String;

         if T = "boolean" or else T = "standard.boolean" then
            if Position = 0 then
               Image_Text := To_Unbounded_String ("false");
               return True;
            elsif Position = 1 then
               Image_Text := To_Unbounded_String ("true");
               return True;
            else
               return False;
            end if;
         elsif Static_Type_Is_Character (Type_Name) then
            if Position <= Character'Pos (Character'Last) then
               declare
                  C : constant Character := Character'Val (Position);
               begin
                  --  preserve Ada's doubled apostrophe spelling when
                  --  producing Character'Image for the apostrophe character.
                  --  The source-level image is four apostrophes (''''), not the
                  --  three-character text that a naive quote + char + quote
                  --  concatenation would produce.  Keeping the canonical image
                  --  here lets Character'Value(Character'Image('''')) and
                  --  String'Length over that image remain static and correct.
                  if C = Character'Val (39) then
                     Image_Text := To_Unbounded_String
                       (Character'Val (39) & Character'Val (39) &
                        Character'Val (39) & Character'Val (39));
                  else
                     Image_Text := To_Unbounded_String
                       (Character'Val (39) & C & Character'Val (39));
                  end if;
                  return True;
               end;
            else
               return False;
            end if;
         end if;

         return Target_Derivation.Static_Enumeration_Position_Image
           (Context.Target, T, Position, Image_Text);
      exception
         when Constraint_Error =>
            return False;
      end Static_Discrete_Position_Image;

      function Static_String_Constant_Value
        (Name       : String;
         Image_Text : out Unbounded_String) return Boolean
      is
      begin
         return Target_Derivation.Static_String_Constant_Value
           (Context.Target, Name, Image_Text);
      end Static_String_Constant_Value;

      function Static_String_Length_Value
        (Name   : String;
         Length : out Natural) return Boolean
      is
         Image_Text : Unbounded_String;
      begin
         Length := 0;
         if Static_String_Constant_Value (Name, Image_Text) then
            Length := To_String (Image_Text)'Length;
            return True;
         end if;
         return False;
      exception
         when Constraint_Error =>
            return False;
      end Static_String_Length_Value;

      function Static_String_Constant_Bound_Value
        (Name      : String;
         Attr_Name : String;
         Bound     : out Natural) return Boolean
      is
      begin
         return Target_Derivation.Static_String_Constant_Bound_Value
           (Context.Target, Name, Attr_Name, Bound);
      end Static_String_Constant_Bound_Value;

      function Static_String_Bound_Value
        (Name       : String;
         Attr_Name  : String;
         Bound      : out Natural) return Boolean
      is
      begin
         return Target_String_Evaluation.Static_String_Bound_Value
           (Context.Target,
            Name,
            Attr_Name,
            Static_String_Default_Value'Unrestricted_Access,
            Bound);
      end Static_String_Bound_Value;

      function Static_Character_Constant_Position
        (Name     : String;
         Position : out Natural) return Boolean;

      function Static_String_Element_Position
        (Indexed_Text : String;
         Position     : out Natural) return Boolean
      is
      begin
         return Target_String_Evaluation.Static_String_Element_Position
           (Context.Target,
            Indexed_Text,
            Parse_Static_Integer'Unrestricted_Access,
            Static_String_Default_Value'Unrestricted_Access,
            Static_String_Bound_Value'Unrestricted_Access,
            Position);
      end Static_String_Element_Position;

      function Static_String_Slice_Value
        (Slice_Text : String;
         Image_Text : out Unbounded_String) return Boolean
      is
      begin
         return Target_String_Evaluation.Static_String_Slice_Value
           (Context.Target,
            Slice_Text,
            Parse_Static_Integer'Unrestricted_Access,
            Static_String_Default_Value'Unrestricted_Access,
            Static_String_Bound_Value'Unrestricted_Access,
            Image_Text);
      end Static_String_Slice_Value;

      function Static_String_Default_Value
        (Default_Text : String;
         Image_Text   : out Unbounded_String) return Boolean
      is
      begin
         return Target_String_Evaluation.Static_String_Default_Value
           (Context.Target,
            Default_Text,
            Parse_Static_Integer'Unrestricted_Access,
            Static_Discrete_Default_Position'Unrestricted_Access,
            Static_Discrete_Position_Image'Unrestricted_Access,
            Image_Text);
      end Static_String_Default_Value;

      function Static_Discrete_Value_String_Position
        (Type_Name   : String;
         String_Text : String;
         Position    : out Natural) return Boolean
      is
      begin
         return Target_String_Evaluation.Static_Discrete_Value_String_Position
           (Context.Target,
            Type_Name,
            String_Text,
            Static_String_Default_Value'Unrestricted_Access,
            Static_Discrete_Literal_Position'Unrestricted_Access,
            Static_Discrete_Default_Position'Unrestricted_Access,
            Position);
      end Static_Discrete_Value_String_Position;

      function Static_Integer_Value_String_Value
        (Type_Name   : String;
         String_Text : String;
         Value       : out Integer) return Boolean
      is
      begin
         return Target_String_Evaluation.Static_Integer_Value_String_Value
           (Context.Target,
            Type_Name,
            String_Text,
            Static_String_Default_Value'Unrestricted_Access,
            Parse_Static_Integer'Unrestricted_Access,
            Value);
      end Static_Integer_Value_String_Value;

      function Static_Discrete_Constant_Position
        (Type_Name : String;
         Name      : String;
         Position  : out Natural) return Boolean
      is
      begin
         return Target_Derivation.Static_Discrete_Constant_Position
           (Context.Target, Type_Name, Name, Position);
      end Static_Discrete_Constant_Position;

      function Static_Discrete_Default_Position
        (Type_Name    : String;
         Default_Text : String;
         Position     : out Natural) return Boolean
      is
      begin
         return Target_Discrete_Evaluation.Static_Discrete_Default_Position
           (Context.Target,
            Type_Name,
            Default_Text,
            Parse_Static_Natural'Unrestricted_Access,
            Parse_Static_Integer'Unrestricted_Access,
            Static_Discrete_Literal_Position'Unrestricted_Access,
            Static_Discrete_Position_Image'Unrestricted_Access,
            Position);
      end Static_Discrete_Default_Position;

      function Static_Character_Constant_Position
        (Name     : String;
         Position : out Natural) return Boolean
      is
      begin
         return Target_Derivation.Static_Character_Constant_Position
           (Context.Target, Name, Position);
      end Static_Character_Constant_Position;


      function Static_Constant_Default_Compatible
        (Subtype_Text : String;
         Default_Text : String) return Boolean
      is
         T : constant String :=
           Editor.Ada_Declaration_Parser.Representation_Static_Values.
             Strip_Constant_Subtype_Prefix (Subtype_Text);
         Valid : Boolean := False;
         Value : Integer := 0;
         Has_Low  : Boolean := False;
         Low      : Integer := 0;
         Has_High : Boolean := False;
         High     : Integer := 0;
      begin
         if T = "" or else not Is_Simple_Static_Type_Name (T) then
            return True;
         end if;

         if not Static_Type_Range (T, Has_Low, Low, Has_High, High)
           and then not Static_Type_Range
             (Static_Subtype_Root (T), Has_Low, Low, Has_High, High)
         then
            return True;
         end if;

         if not Has_Low and then not Has_High then
            return False;
         end if;

         Parse_Static_Integer (Default_Text, Valid, Value);
         if not Valid then
            return False;
         end if;

         if Has_Low and then Value < Low then
            return False;
         elsif Has_High and then Value > High then
            return False;
         else
            return True;
         end if;
      exception
         when Constraint_Error =>
            return False;
      end Static_Constant_Default_Compatible;



      Numeric_Parse_Actions : constant Target_Numeric_Parsing.Operations :=
        (Clean_Metadata_Name => Clean_Metadata_Name'Unrestricted_Access,
         Static_String_Bound_Value => Static_String_Bound_Value'Unrestricted_Access,
         Static_Discrete_Default_Position =>
           Static_Discrete_Default_Position'Unrestricted_Access,
         Static_Discrete_Literal_Position =>
           Static_Discrete_Literal_Position'Unrestricted_Access,
         Static_Discrete_Constant_Position =>
           Static_Discrete_Constant_Position'Unrestricted_Access,
         Static_Value_In_Type_Range =>
           Static_Value_In_Type_Range'Unrestricted_Access,
         Static_Discrete_Value_String_Position =>
           Static_Discrete_Value_String_Position'Unrestricted_Access,
         Static_Integer_Value_String_Value =>
           Static_Integer_Value_String_Value'Unrestricted_Access,
         Static_Type_Range => Static_Type_Range'Unrestricted_Access,
         Static_Type_Modulus => Static_Type_Modulus'Unrestricted_Access,
         Static_Type_Width => Static_Type_Width'Unrestricted_Access,
         Static_Attribute_Value => Static_Attribute_Value'Unrestricted_Access,
         Static_Named_Number_Value => Static_Named_Number_Value'Unrestricted_Access,
         Static_Integer_Name_Value => Static_Integer_Name_Value'Unrestricted_Access,
         Static_String_Subtype_Bound_Value =>
           Static_String_Subtype_Bound_Value'Unrestricted_Access,
         Static_String_Constant_Bound_Value =>
           Static_String_Constant_Bound_Value'Unrestricted_Access,
         Static_Subtype_Root => Static_Subtype_Root'Unrestricted_Access);

      procedure Parse_Static_Natural
        (Text  : String;
         Valid : out Boolean;
         Value : out Natural)
      is
      begin
         Target_Numeric_Parsing.Parse_Static_Natural
           (Numeric_Parse_Actions, Text, Valid, Value);
      end Parse_Static_Natural;

      procedure Parse_Static_Integer
        (Text  : String;
         Valid : out Boolean;
         Value : out Integer)
      is
      begin
         Target_Numeric_Parsing.Parse_Static_Integer
           (Numeric_Parse_Actions, Text, Valid, Value);
      end Parse_Static_Integer;

      Representation_Context : constant
        Representation_Application.Application_Context :=
        Representation_Application.Create_Context
          (First_Child_Label => First_Child_Label'Unrestricted_Access,
           Last_Child_Label  => Last_Child_Label'Unrestricted_Access,
           To_Model_Range    => To_Model_Range'Unrestricted_Access,
           Find_Metadata_Target =>
             Find_Metadata_Target'Unrestricted_Access,
           Normalize_Name => Normalize_Name'Unrestricted_Access,
           Ancestor_Symbol => Ancestor_Symbol'Unrestricted_Access,
           Parent_Representation_Target =>
             Parent_Representation_Target'Unrestricted_Access,
           Find_Enumeration_Literal =>
             Find_Enumeration_Literal_Symbol'Unrestricted_Access,
           Enumeration_Literal_At =>
             Enumeration_Literal_Symbol_At_Position'Unrestricted_Access,
           Find_Component => Find_Component_Symbol'Unrestricted_Access,
           Symbol_Name => Symbol_Name_Or_Empty'Unrestricted_Access,
           Parse_Static_Natural => Parse_Static_Natural'Unrestricted_Access,
           Register_Static_Attribute =>
             Register_Static_Representation_Attribute_Value
               'Unrestricted_Access);


      Target_Actions : constant Target_Derivation.Operations :=
        (Is_Static_Numeric_Value =>
           Is_Static_Numeric_Value'Unrestricted_Access,
         Parse_Static_Natural =>
           Parse_Static_Natural'Unrestricted_Access,
         Parse_Static_Integer =>
           Parse_Static_Integer'Unrestricted_Access,
         Static_Constant_Default_Compatible =>
           Static_Constant_Default_Compatible'Unrestricted_Access,
         Static_Discrete_Default_Position =>
           Static_Discrete_Default_Position'Unrestricted_Access,
         Is_Simple_Static_Type_Name =>
           Is_Simple_Static_Type_Name'Unrestricted_Access,
         Normalize_Character_Pos_Static_Operands =>
           Normalize_Character_Pos_Static_Operands'Unrestricted_Access,
         Static_String_Default_Value =>
           Static_String_Default_Value'Unrestricted_Access,
         Static_String_Bound_Value =>
           Static_String_Bound_Value'Unrestricted_Access);

   begin
      if Count = 0 then
         return;
      end if;

      Projection_Pipeline.Run
        (Context,
         Analysis,
         Tree,
         Source_Text,
         Representation_Context,
         Target_Actions,
         Apply_Metadata_To_Target'Unrestricted_Access);
   end Project_Syntax_Tree_Into_Model;

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection;
