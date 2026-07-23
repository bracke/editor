with Ada.Strings.Unbounded;
with Editor.Ada_Declarative_Regions;
with Editor.Ada_Expected_Type_Contexts;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Expression_Types.Inference_Support is

   function Fingerprint_For (Info : Expression_Type_Info) return Natural;

   function Region_For_Line
     (Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Line    : Positive) return Editor.Ada_Declarative_Regions.Region_Id;

   function Primary_Name (Text : String) return String;
   function Simple_Name (Text : String) return String;
   function Prefix_Before (Text : String; Mark : Character) return String;
   function Suffix_After (Text : String; Mark : Character) return String;
   function Attribute_Name_From_Text (Text : String) return String;
   function Attribute_Prefix_From_Text (Text : String) return String;
   function Is_String_Literal (Text : String) return Boolean;
   function Is_Character_Literal_Text (Text : String) return Boolean;
   function Looks_Real (Text : String) return Boolean;
   function Is_Universal_Compatible (Actual : String; Expected : String) return Boolean;
   function Is_Context_Dependent
     (Status : Expression_Type_Status) return Boolean;
   function Subtype_From_Declaration_Label (Label : String) return String;

   procedure Apply_Syntax_Expected_Context
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Info : in out Expression_Type_Info);

   procedure Apply_Expected_Context
     (Info     : in out Expression_Type_Info;
      Expected : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model);

   procedure Append
     (Model : in out Expression_Type_Model;
      Info  : in out Expression_Type_Info);

end Editor.Ada_Expression_Types.Inference_Support;
