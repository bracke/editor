with Editor.Ada_Language_Model;
with Editor.Ada_Declaration_Parser.Declaration_Collectors;

package Editor.Ada_Declaration_Parser.Same_Line_Emitters is

   use Editor.Ada_Language_Model;

   procedure Add_Same_Line_Subtype_Groups
     (Analysis        : in out Analysis_Result;
      Raw_Line        : String;
      Line_Number     : Positive;
      Depth           : Natural;
      Parent          : Symbol_Id;
      Parent_Is_Private : Boolean);

   procedure Add_Same_Line_Type_Groups
     (Analysis        : in out Analysis_Result;
      Raw_Line        : String;
      Line_Number     : Positive;
      Depth           : Natural;
      Parent          : Symbol_Id;
      Parent_Is_Private : Boolean;
      Pending_Generic : Boolean);

   procedure Add_Same_Line_Package_Groups
     (Analysis        : in out Analysis_Result;
      Raw_Line        : String;
      Line_Number     : Positive;
      Depth           : Natural;
      Parent          : Symbol_Id;
      Parent_Is_Private : Boolean;
      Pending_Generic : Boolean);

   procedure Add_Same_Line_Callable_Groups
     (Analysis        : in out Analysis_Result;
      Raw_Line        : String;
      Line_Number     : Positive;
      Depth           : Natural;
      Parent          : Symbol_Id;
      Parent_Is_Private : Boolean;
      Pending_Generic : Boolean;
      Pending_Profile_Access_Target_Owners :
        in out Editor.Ada_Declaration_Parser.Declaration_Collectors.Collected_Symbol_List;
      Pending_Profile_Access_Target_Count : in out Natural);

   procedure Add_Same_Line_Concurrent_Groups
     (Analysis        : in out Analysis_Result;
      Raw_Line        : String;
      Line_Number     : Positive;
      Depth           : Natural;
      Parent          : Symbol_Id;
      Parent_Is_Private : Boolean;
      Pending_Profile_Access_Target_Owners :
        in out Editor.Ada_Declaration_Parser.Declaration_Collectors.Collected_Symbol_List;
      Pending_Profile_Access_Target_Count : in out Natural);

end Editor.Ada_Declaration_Parser.Same_Line_Emitters;
