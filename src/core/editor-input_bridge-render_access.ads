with Editor.Diagnostics;
with Editor.Feature_Panel;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.Problems;
with Editor.Project_Search;
with Editor.Render_Model;
with Editor.Search_Results;
with Editor.State;

package Editor.Input_Bridge.Render_Access is

   procedure Get_Render_Snapshot
     (S            : in out Editor.State.State_Type;
      Out_Snapshot : out Editor.Render_Model.Render_Snapshot);

   function File_Tree_For_Render
     (S : Editor.State.State_Type) return Editor.File_Tree.File_Tree_State;

   function Problems_For_Render
     (S : Editor.State.State_Type) return Editor.Problems.Problems_Snapshot;

   function Problems_Total_Count_For_Render
     (S : Editor.State.State_Type) return Natural;

   function Search_Results_For_Render
     (S : Editor.State.State_Type) return Editor.Search_Results.Search_Results_Snapshot;

   function Search_Results_Focused_For_Render
     (S : Editor.State.State_Type) return Boolean;

   function Problems_Focused_For_Render
     (S : Editor.State.State_Type) return Boolean;

   function File_Tree_Focused_For_Render
     (S : Editor.State.State_Type) return Boolean;

   function Feature_Panel_For_Render
     (S : Editor.State.State_Type) return Editor.Feature_Panel.Feature_Panel_State;

   function Feature_Panel_Focused_For_Render
     (S : Editor.State.State_Type) return Boolean;

   function File_Tree_View_For_Render
     (S : Editor.State.State_Type) return Editor.File_Tree_View.File_Tree_View_State;

   function Problems_View_For_Render
     (S : Editor.State.State_Type) return Editor.Problems.Problems_View_State;

   function Project_Search_For_Render
     (S : Editor.State.State_Type) return Editor.Project_Search.Project_Search_State;

   function Active_Diagnostic_For_Render
     (S : Editor.State.State_Type) return Editor.Diagnostics.Diagnostic_Index;

end Editor.Input_Bridge.Render_Access;
