with Editor.Workspace_Persistence;
with Ada.Strings.Unbounded;

package Editor.Workspace_Persistence.Text_Format is

   Current_Format_Version : constant Natural := 1;
   Default_File_Tree_Width : constant Natural := 28;
   Default_Bottom_Height   : constant Natural := 8;

   type Section_Id is
     (Root_Section,
      Open_Files_Section,
      Active_File_Section,
      File_Tree_Expanded_Section,
      Panels_Section,
      Continuity_Section,
      Unknown_Section);

   function Trim (Text : String) return String;
   function Natural_Text (Value : Natural) return String;
   function Bool_Text (Value : Boolean) return String;
   function Content_Text (Content : Bottom_Content_Id) return String;
   function Feature_Panel_Text
     (Feature : Workspace_Feature_Panel_Id) return String;
   function Quick_Open_Filter_Text
     (Filter : Workspace_Quick_Open_File_Kind_Filter) return String;
   function Is_Decimal_Natural_Text (Text : String) return Boolean;
   function Parse_Natural_Strict
     (Text  : String;
      Value : out Natural) return Boolean;
   function Parse_Boolean_Strict
     (Text  : String;
      Value : out Boolean) return Boolean;
   function Parse_Content_Strict
     (Text    : String;
      Content : out Bottom_Content_Id) return Boolean;
   function Parse_Feature_Panel_Strict
     (Text    : String;
      Feature : out Workspace_Feature_Panel_Id) return Boolean;
   function Parse_Quick_Open_Filter_Strict
     (Text   : String;
      Filter : out Workspace_Quick_Open_File_Kind_Filter) return Boolean;
   function Normalize_Directory_Scope
     (Scope : String;
      Valid : out Boolean) return String;
   function Value_After_Strict
     (Field : String;
      Key   : String;
      Found : out Boolean) return String;

end Editor.Workspace_Persistence.Text_Format;
