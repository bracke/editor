with Editor.Diagnostics;
with Editor.Feature_Panel;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.Instance;
with Editor.Problems;
with Editor.Project_Search;
with Editor.Render_Model;
with Editor.Render_Packet;
with Editor.Search_Results;

package Editor.Input_Bridge.Render_Interface is

   procedure Build_Render_Packet
     (Initialized : Boolean;
      Packet      : out Editor.Render_Packet.Render_Packet);

   procedure Get_Render_Snapshot
     (Instance     : in out Editor.Instance.Editor_Instance;
      Initialized  : Boolean;
      Out_Snapshot : out Editor.Render_Model.Render_Snapshot);

   procedure Get_File_Tree_For_Render
     (Instance    : Editor.Instance.Editor_Instance;
      Initialized : Boolean;
      Out_Tree    : out Editor.File_Tree.File_Tree_State);

   procedure Get_Problems_For_Render
     (Instance     : Editor.Instance.Editor_Instance;
      Initialized  : Boolean;
      Out_Snapshot : out Editor.Problems.Problems_Snapshot);

   function Problems_Total_Count_For_Render
     (Instance    : Editor.Instance.Editor_Instance;
      Initialized : Boolean) return Natural;

   procedure Get_Search_Results_For_Render
     (Instance     : Editor.Instance.Editor_Instance;
      Initialized  : Boolean;
      Out_Snapshot : out Editor.Search_Results.Search_Results_Snapshot);

   function Search_Results_Focused_For_Render
     (Instance    : Editor.Instance.Editor_Instance;
      Initialized : Boolean) return Boolean;

   function Problems_Focused_For_Render
     (Instance    : Editor.Instance.Editor_Instance;
      Initialized : Boolean) return Boolean;

   function File_Tree_Focused_For_Render
     (Instance    : Editor.Instance.Editor_Instance;
      Initialized : Boolean) return Boolean;

   function Feature_Panel_For_Render
     (Instance    : Editor.Instance.Editor_Instance;
      Initialized : Boolean) return Editor.Feature_Panel.Feature_Panel_State;

   function Feature_Panel_Focused_For_Render
     (Instance    : Editor.Instance.Editor_Instance;
      Initialized : Boolean) return Boolean;

   function File_Tree_View_For_Render
     (Instance    : Editor.Instance.Editor_Instance;
      Initialized : Boolean) return Editor.File_Tree_View.File_Tree_View_State;

   function Problems_View_For_Render
     (Instance    : Editor.Instance.Editor_Instance;
      Initialized : Boolean) return Editor.Problems.Problems_View_State;

   function Project_Search_For_Render
     (Instance    : Editor.Instance.Editor_Instance;
      Initialized : Boolean) return Editor.Project_Search.Project_Search_State;

   function Active_Diagnostic_For_Render
     (Instance : Editor.Instance.Editor_Instance)
      return Editor.Diagnostics.Diagnostic_Index;

end Editor.Input_Bridge.Render_Interface;
