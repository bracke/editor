with Editor.Buffer_Switcher;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.Go_To_Line;
with Editor.Project_Search;
with Editor.Project_Search_Bar;
with Editor.Quick_Open;

package Editor.State_Surface is

   type Surface_Runtime_State is record
      File_Tree          : Editor.File_Tree.File_Tree_State;
      File_Tree_View     : Editor.File_Tree_View.File_Tree_View_State;
      Quick_Open         : Editor.Quick_Open.Quick_Open_State;
      Buffer_Switcher    : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Go_To_Line         : Editor.Go_To_Line.Go_To_Line_State;
      Project_Search     : Editor.Project_Search.Project_Search_State;
      Project_Search_Bar : Editor.Project_Search_Bar.Project_Search_Bar_State;
   end record;

end Editor.State_Surface;
