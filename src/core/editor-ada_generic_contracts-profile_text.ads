with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Generic_Contracts.Profile_Text is

   function Delimited_Text_At
     (List  : String;
      Index : Positive) return String;

   function Named_Text_For
     (List : String;
      Name : String) return String;

   function Strip_Default_And_Mode (Text : String) return String;

   function Append_Repeated_Subtype
     (List  : Ada.Strings.Unbounded.Unbounded_String;
      Count : Natural;
      Text  : String) return Ada.Strings.Unbounded.Unbounded_String;

   function Mode_From_Parameter_Tail (Text : String) return String;

   function Append_Repeated_Mode
     (List  : Ada.Strings.Unbounded.Unbounded_String;
      Count : Natural;
      Text  : String) return Ada.Strings.Unbounded.Unbounded_String;

   function Default_From_Parameter_Tail (Text : String) return String;

   function Append_Repeated_Default
     (List  : Ada.Strings.Unbounded.Unbounded_String;
      Count : Natural;
      Text  : String) return Ada.Strings.Unbounded.Unbounded_String;

   function Append_Parameter_Names
     (List  : Ada.Strings.Unbounded.Unbounded_String;
      Names : String) return Ada.Strings.Unbounded.Unbounded_String;

   function Parameter_Defaults_Conform
     (Formal_Defaults : String;
      Actual_Defaults : String) return Boolean;

   procedure Analyze_Subprogram_Profile
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Node       : Editor.Ada_Syntax_Tree.Node_Id;
      Parameters : out Natural;
      Subtypes   : out Ada.Strings.Unbounded.Unbounded_String;
      Modes      : out Ada.Strings.Unbounded.Unbounded_String;
      Names      : out Ada.Strings.Unbounded.Unbounded_String;
      Defaults   : out Ada.Strings.Unbounded.Unbounded_String;
      Has_Result : out Boolean;
      Result     : out Ada.Strings.Unbounded.Unbounded_String;
      Malformed  : out Boolean);

end Editor.Ada_Generic_Contracts.Profile_Text;
