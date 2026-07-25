with Ada.Characters.Latin_1;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Text_Helpers;
with Editor.Ada_Declaration_Parser.Executable_Binding_Text_Helpers;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Line_Dispatch;
with Editor.Ada_Declaration_Parser.Metadata_Helpers;
with Editor.Ada_Declaration_Parser.Name_Profile_Helpers;
with Editor.Ada_Declaration_Parser.Range_Structure_Helpers;
with Editor.Ada_Syntax_Core;
with Editor.Ada_Language_Model;

package body Editor.Ada_Declaration_Parser.Executable_Binding_Scanner.Text_Scan is


   use Editor.Ada_Language_Model;
   use Editor.Text_Helpers;
   use Editor.Ada_Declaration_Parser.Executable_Binding_Text_Helpers;
   use Editor.Ada_Declaration_Parser.Lexical_Helpers;
   use type Executable_Binding_Kind;
   use type Scope_Id;
   use type Symbol_Id;
   use type Symbol_Kind;

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

   function Starts_With_Declaration_Or_Metadata
     (Decl_Lower : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Line_Dispatch.Starts_With_Declaration_Or_Metadata;

   function Normalize_Name (Name : String) return String
     renames Editor.Ada_Language_Model.Normalize_Name;

   function Scope_For_Position
     (Analysis : Analysis_Result;
      Line     : Positive;
      Column   : Positive) return Symbol_Id
     renames Editor.Ada_Language_Model.Scope_For_Position;

   procedure Add_Executable_Binding
     (Analysis        : in out Analysis_Result;
      Kind            : Executable_Binding_Kind;
      Name            : String;
      Expression_Text : String;
      Scope           : Scope_Id;
      Target_Symbol   : Symbol_Id;
      Source_Span     : Source_Range)
     renames Editor.Ada_Language_Model.Add_Executable_Binding;

   package Binding_Publication is
      function Resolve_Local_Target
        (Name : String;
         Line : Positive;
         Column : Positive) return Symbol_Id;

      procedure Add_Binding
        (Kind : Executable_Binding_Kind;
         Name : String;
         Expr : String;
         Line : Positive;
         Col  : Positive);

      function Is_Indexable_Target
        (Name : String;
         Line : Positive;
         Col  : Positive) return Boolean;

      function Is_Type_Conversion_Target
        (Name : String;
         Line : Positive;
         Col  : Positive) return Boolean;

      function Is_Entry_Family_Target
        (Name : String;
         Line : Positive;
         Col  : Positive) return Boolean;
   end Binding_Publication;

   package body Binding_Publication is separate;

   package Candidate_Classification is
      function Is_Executable_Scan_Keyword (Name : String) return Boolean;
      function Is_Executable_Declaration_Line (LWork : String) return Boolean;
      function Call_Right_Paren (Expr : String; Open_Pos : Natural) return Natural;
      function Matching_Right_Paren (Expr : String; Open_Pos : Natural) return Natural;
      function Contains_Range_Dots (Expr : String) return Boolean;
      function Is_Executable_Pragma_Name (Name : String) return Boolean;
      function Is_Executable_Aspect_Name (Name : String) return Boolean;

      procedure Add_Call_Targets_In_Expression
        (Expr : String;
         Line : Positive;
         Base_Column : Positive);
      procedure Add_Call_Resolver_Hints_In_Expression
        (Expr : String;
         Line : Positive;
         Base_Column : Positive);
      procedure Add_Selected_Components_In_Expression
        (Expr : String;
         Line : Positive;
         Base_Column : Positive);
      procedure Add_Range_Bounds_In_Expression
        (Expr : String;
         Line : Positive;
         Base_Column : Positive);
      procedure Add_Quantified_Bindings_In_Expression
        (Expr : String;
         Line : Positive;
         Base_Column : Positive);
      procedure Add_Conditional_Expression_Bindings_In_Expression
        (Expr : String;
         Line : Positive;
         Base_Column : Positive);
      procedure Add_Raise_Expression_Bindings_In_Expression
        (Expr : String;
         Line : Positive;
         Base_Column : Positive);
      procedure Add_Delta_Aggregate_Bindings_In_Expression
        (Expr : String;
         Line : Positive;
         Base_Column : Positive);
      procedure Add_Case_Expression_Bindings_In_Expression
        (Expr : String;
         Line : Positive;
         Base_Column : Positive);
      procedure Add_Deep_Expression_Name_Bindings
        (Expr : String;
         Line : Positive;
         Base_Column : Positive);
      procedure Add_Aspect_Expression_Bindings
        (Expr : String;
         Line : Positive;
         Base_Column : Positive);
      procedure Add_Pragma_Named_Argument_Bindings
        (Args : String;
         Line : Positive;
         Base_Column : Positive);
      procedure Add_Pragma_Expression_Argument_Bindings
        (Args : String;
         Line : Positive;
         Base_Column : Positive);
   end Candidate_Classification;

   package body Candidate_Classification is separate;

   package Text_Scan_Phase is
      procedure Scan_Text (Text : String);
   end Text_Scan_Phase;

   package body Text_Scan_Phase is separate;

   procedure Scan_Text (Text : String) renames Text_Scan_Phase.Scan_Text;

end Editor.Ada_Declaration_Parser.Executable_Binding_Scanner.Text_Scan;
