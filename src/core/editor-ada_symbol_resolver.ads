with Ada.Containers.Vectors;
with Editor.Ada_Language_Model;
use type Editor.Ada_Language_Model.Symbol_Id;

package Editor.Ada_Symbol_Resolver is

   package Symbol_Id_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Editor.Ada_Language_Model.Symbol_Id);

   type Resolution_Result is record
      Matches  : Symbol_Id_Vectors.Vector;
      Overflow : Boolean := False;
   end record;

   function Resolve
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Name     : String;
      From_Depth : Natural := Natural'Last) return Resolution_Result;

   function Resolve_In_Scope
     (Analysis   : Editor.Ada_Language_Model.Analysis_Result;
      Name       : String;
      From_Scope : Editor.Ada_Language_Model.Symbol_Id) return Resolution_Result;


   --  Conservative overload selection for call/navigation consumers.
   --  Actual_Profile is a bounded, normalized call-shape string such as
   --  "Integer, Boolean" or "Left => Integer, Right => Count".  It is
   --  matched against retained subprogram Profile_Summary text by actual
   --  count, named associations, simple parameter type names, and trailing
   --  or skipped formals with retained default expressions.
   --  Expected_Result_Type, when non-empty, filters function/operator
   --  overloads by their retained return type.  Ambiguous matches are
   --  deliberately preserved in Matches.
   function Resolve_Call_In_Scope
     (Analysis             : Editor.Ada_Language_Model.Analysis_Result;
      Name                 : String;
      From_Scope           : Editor.Ada_Language_Model.Symbol_Id;
      Actual_Profile       : String := "";
      Expected_Result_Type : String := "") return Resolution_Result;

   --  Infer a conservative type name for one expression in From_Scope.
   --  This is intentionally bounded and editor-oriented: it recognizes
   --  literals, qualified expressions, simple conversions, object/constant
   --  declarations with retained subtype metadata, enumeration literals,
   --  and nested calls that resolve to a unique function/operator result.
   --  Unknown or ambiguous expressions return the empty string.
   function Infer_Expression_Type_In_Scope
     (Analysis   : Editor.Ada_Language_Model.Analysis_Result;
      Expression : String;
      From_Scope : Editor.Ada_Language_Model.Symbol_Id) return String;

   --  Expression-aware overload selection.  Actual_Expressions is a bounded
   --  comma-separated Ada expression list.  Each expression is reduced to a
   --  conservative type name before Resolve_Call_In_Scope is applied.
   --  Named associations such as ``Right => Value`` are preserved.
   --  Expected_Result_Expression, when present, is inferred the same way and
   --  used as the expected function result type.
   function Resolve_Call_Expression_In_Scope
     (Analysis                   : Editor.Ada_Language_Model.Analysis_Result;
      Name                       : String;
      From_Scope                 : Editor.Ada_Language_Model.Symbol_Id;
      Actual_Expressions         : String := "";
      Expected_Result_Expression : String := "") return Resolution_Result;

   function First_Match_In_Scope
     (Analysis   : Editor.Ada_Language_Model.Analysis_Result;
      Name       : String;
      From_Scope : Editor.Ada_Language_Model.Symbol_Id) return Editor.Ada_Language_Model.Symbol_Id;

   function First_Match
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Name     : String;
      From_Depth : Natural := Natural'Last) return Editor.Ada_Language_Model.Symbol_Id;

end Editor.Ada_Symbol_Resolver;
