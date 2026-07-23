package Editor.Project_Search.Navigation is

   function Result_At
     (State : Project_Search_State;
      Index : Positive) return Project_Search_Result;

   function Result_Key
     (State : Project_Search_State;
      Index : Positive) return Project_Search_Result_Key;

   function File_Group_At
     (State : Project_Search_State;
      Index : Positive) return Project_Search_File_Group;

   function Selected_Result_Index
     (State : Project_Search_State) return Natural;

   procedure Set_Selected_Result_Index
     (State : in out Project_Search_State;
      Index : Natural);

   procedure Ensure_Valid_Selection
     (State : in out Project_Search_State);

   function Can_Move_Next
     (State : Project_Search_State) return Boolean;

   function Can_Move_Previous
     (State : Project_Search_State) return Boolean;

   procedure Move_Selected_Result
     (State     : in out Project_Search_State;
      Direction : Project_Search_Result_Direction;
      Wrap      : Boolean := True);

   procedure Select_First_Result
     (State : in out Project_Search_State);

   procedure Select_Last_Result
     (State : in out Project_Search_State);

   function Select_First_Result_For_Path
     (State : in out Project_Search_State;
      Path  : String) return Boolean;

   function Directory_Scope_Of_Path
     (Path : String) return String;

   function Selected_Result_Directory
     (State : Project_Search_State;
      Found : out Boolean) return String;

   function Selected_Result
     (State : Project_Search_State;
      Found : out Boolean) return Project_Search_Result;

   procedure Move_Selection_Down
     (State : in out Project_Search_State);

   procedure Move_Selection_Up
     (State : in out Project_Search_State);

end Editor.Project_Search.Navigation;
