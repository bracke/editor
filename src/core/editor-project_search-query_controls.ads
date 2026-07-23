package Editor.Project_Search.Query_Controls is

   procedure Clear
     (State : in out Project_Search_State);

   procedure Clear_Results_Preserve_Query
     (State : in out Project_Search_State);

   function Query
     (State : Project_Search_State) return String;

   procedure Set_Query
     (State : in out Project_Search_State;
      Query : String);

   function Has_Query
     (State : Project_Search_State) return Boolean;

   function Status
     (State : Project_Search_State) return Project_Search_Status;

   procedure Set_Status
     (State  : in out Project_Search_State;
      Status : Project_Search_Status);

   function File_Kind_Filter
     (State : Project_Search_State) return Project_Search_File_Kind_Filter;

   function File_Kind_Filter_Image
     (Kind : Project_Search_File_Kind_Filter) return String;

   procedure Cycle_File_Kind_Filter
     (State : in out Project_Search_State;
      Forward : Boolean := True);

   procedure Clear_File_Kind_Filter
     (State : in out Project_Search_State);

   function Path_Scope
     (State : Project_Search_State) return String;

   function Include_Path_Filter
     (State : Project_Search_State) return String;

   function Exclude_Path_Filter
     (State : Project_Search_State) return String;

   function Normalize_Path_Scope
     (Scope : String;
      Valid : out Boolean) return String;

   procedure Set_Path_Scope
     (State : in out Project_Search_State;
      Scope : String;
      Valid : out Boolean);

   procedure Clear_Path_Scope
     (State : in out Project_Search_State);

   function Normalize_Path_Filter
     (Filter : String;
      Valid  : out Boolean) return String;

   procedure Set_Include_Path_Filter
     (State  : in out Project_Search_State;
      Filter : String;
      Valid  : out Boolean);

   procedure Set_Exclude_Path_Filter
     (State  : in out Project_Search_State;
      Filter : String;
      Valid  : out Boolean);

   procedure Clear_Include_Path_Filter
     (State : in out Project_Search_State);

   procedure Clear_Exclude_Path_Filter
     (State : in out Project_Search_State);

   function Case_Sensitive
     (State : Project_Search_State) return Boolean;

   procedure Set_Case_Sensitive
     (State : in out Project_Search_State;
      Value : Boolean);

   procedure Toggle_Case_Sensitive
     (State : in out Project_Search_State);

   function Whole_Word
     (State : Project_Search_State) return Boolean;

   procedure Set_Whole_Word
     (State : in out Project_Search_State;
      Value : Boolean);

   procedure Toggle_Whole_Word
     (State : in out Project_Search_State);

   function Regex_Enabled
     (State : Project_Search_State) return Boolean;

   function Regex_Error
     (State : Project_Search_State) return String;

   procedure Set_Regex_Enabled
     (State : in out Project_Search_State;
      Value : Boolean);

   procedure Toggle_Regex
     (State : in out Project_Search_State);

   procedure Clear_Regex
     (State : in out Project_Search_State);

   function Is_Stale
     (State : Project_Search_State) return Boolean;

   procedure Mark_Stale
     (State : in out Project_Search_State);

   procedure Mark_Stale_Unconditionally
     (State : in out Project_Search_State);

   procedure Clear_Stale
     (State : in out Project_Search_State);

end Editor.Project_Search.Query_Controls;
