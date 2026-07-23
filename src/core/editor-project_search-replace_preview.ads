package Editor.Project_Search.Replace_Preview is

   function Replacement_Text_Is_Valid
     (Text : String) return Boolean;

   procedure Set_Replace_Text
     (State : in out Project_Search_State;
      Text  : String);

   function Replace_Text
     (State : Project_Search_State) return String;

   function Replace_Text_Is_Valid
     (State : Project_Search_State) return Boolean;

   function Replace_Mode_Active
     (State : Project_Search_State) return Boolean;

   procedure Set_Replace_Mode_Active
     (State  : in out Project_Search_State;
      Active : Boolean);

   procedure Clear_Replace_Preview
     (State : in out Project_Search_State);

   procedure Generate_Replace_Preview
     (State : in out Project_Search_State;
      Status : out Project_Replace_Preview_Status);

   function Replace_Preview_Status
     (State : Project_Search_State) return Project_Replace_Preview_Status;

   function Replace_Preview_Count
     (State : Project_Search_State) return Natural;

   function Included_Replacement_Count
     (State : Project_Search_State) return Natural;

   function Eligible_Replacement_Count
     (State : Project_Search_State) return Natural;

   function Eligible_Replacement_File_Count
     (State : Project_Search_State) return Natural;

   function Included_Replacement_File_Count
     (State : Project_Search_State) return Natural;

   function Replace_Preview_Row_At
     (State : Project_Search_State;
      Index : Positive) return Project_Replace_Preview_Row;

   function Selected_Replace_Preview_Index
     (State : Project_Search_State) return Natural;

   procedure Set_Selected_Replace_Preview_Index
     (State : in out Project_Search_State;
      Index : Natural);

   procedure Toggle_Selected_Replacement
     (State : in out Project_Search_State);

   procedure Include_Selected_Replacement
     (State : in out Project_Search_State);

   procedure Exclude_Selected_Replacement
     (State : in out Project_Search_State);

   procedure Include_File_Replacements
     (State : in out Project_Search_State;
      Relative_Path : String);

   procedure Exclude_File_Replacements
     (State : in out Project_Search_State;
      Relative_Path : String);

   procedure Include_All_Replacements
     (State : in out Project_Search_State);

   procedure Exclude_All_Replacements
     (State : in out Project_Search_State);

   function Replace_Preview_Is_Stale
     (State : Project_Search_State) return Boolean;

   procedure Mark_Replace_Preview_Stale
     (State : in out Project_Search_State);

   procedure Mark_Replace_Preview_Stale_For_File
     (State : in out Project_Search_State;
      Relative_Path : String);

   procedure Mark_Replace_Preview_Stale_For_Absolute_File
     (State : in out Project_Search_State;
      Absolute_Path : String);

   function Included_Replacements_Overlap
     (State : Project_Search_State) return Boolean;

   function Apply_Included_Replacements_To_Text
     (State         : Project_Search_State;
      Relative_Path : String;
      Text          : String;
      Changed       : out Boolean;
      Replacement_Count : out Natural) return String;


end Editor.Project_Search.Replace_Preview;
