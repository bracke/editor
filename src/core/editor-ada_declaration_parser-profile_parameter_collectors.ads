with Editor.Ada_Declaration_Parser.Declaration_Collectors;
with Editor.Ada_Language_Model;

package Editor.Ada_Declaration_Parser.Profile_Parameter_Collectors is

   use Editor.Ada_Declaration_Parser.Declaration_Collectors;
   use Editor.Ada_Language_Model;

   procedure Add_Profile_Parameter_Names
     (Analysis      : in out Analysis_Result;
      Raw_Line      : String;
      Line_Number   : Positive;
      Depth         : Natural;
      Parent        : Symbol_Id;
      Declared_Name : String;
      Pending_Profile_Access_Target_Owners : in out Collected_Symbol_List;
      Pending_Profile_Access_Target_Count  : in out Natural);

   function Profile_Still_Open
     (Raw_Line      : String;
      Declared_Name : String) return Boolean;

   procedure Add_Profile_Parameter_Names_Continuation
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id;
      Pending_Profile_Access_Target_Owners : in out Collected_Symbol_List;
      Pending_Profile_Access_Target_Count  : in out Natural;
      Closed      : out Boolean);

end Editor.Ada_Declaration_Parser.Profile_Parameter_Collectors;
