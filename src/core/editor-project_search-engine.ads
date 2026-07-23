package Editor.Project_Search.Engine is

   procedure Search_Project
     (State   : in out Project_Search_State;
      Tree    : Editor.File_Tree.File_Tree_State;
      Reader  : Read_File_Access;
      Options : Project_Search_Options);

   procedure Search_Known_Project_Files
     (State   : in out Project_Search_State;
      Project : Editor.Project.Project_State;
      Options : Project_Search_Options);

   procedure Search_Known_Project_Files
     (State   : in out Project_Search_State;
      Tree    : Editor.File_Tree.File_Tree_State;
      Project : Editor.Project.Project_State;
      Options : Project_Search_Options);

end Editor.Project_Search.Engine;
