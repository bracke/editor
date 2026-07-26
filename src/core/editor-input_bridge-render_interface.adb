with Editor.Input_Bridge.Render_Access;
with Editor.Render_Packet;

package body Editor.Input_Bridge.Render_Interface is

   procedure Build_Render_Packet
     (Initialized : Boolean;
      Packet      : out Editor.Render_Packet.Render_Packet) is
   begin
      pragma Assert (Initialized,
       "Input_Bridge must be initialized before rendering");

      Editor.Render_Packet.Build_Render_Packet (Packet);
   end Build_Render_Packet;

   procedure Get_Render_Snapshot
     (Instance     : in out Editor.Instance.Editor_Instance;
      Initialized  : Boolean;
      Out_Snapshot : out Editor.Render_Model.Render_Snapshot) is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering");

      Editor.Input_Bridge.Render_Access.Get_Render_Snapshot
        (Instance.State, Out_Snapshot);
   end Get_Render_Snapshot;

   procedure Get_File_Tree_For_Render
     (Instance    : Editor.Instance.Editor_Instance;
      Initialized : Boolean;
      Out_Tree    : out Editor.File_Tree.File_Tree_State)
   is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering file tree");

      Out_Tree := Editor.Input_Bridge.Render_Access.File_Tree_For_Render
        (Instance.State);
   end Get_File_Tree_For_Render;

   procedure Get_Problems_For_Render
     (Instance     : Editor.Instance.Editor_Instance;
      Initialized  : Boolean;
      Out_Snapshot : out Editor.Problems.Problems_Snapshot)
   is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering problems");

      Out_Snapshot := Editor.Input_Bridge.Render_Access.Problems_For_Render
        (Instance.State);
   end Get_Problems_For_Render;

   function Problems_Total_Count_For_Render
     (Instance    : Editor.Instance.Editor_Instance;
      Initialized : Boolean) return Natural is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering problem count");
      return Editor.Input_Bridge.Render_Access.Problems_Total_Count_For_Render
        (Instance.State);
   end Problems_Total_Count_For_Render;

   procedure Get_Search_Results_For_Render
     (Instance     : Editor.Instance.Editor_Instance;
      Initialized  : Boolean;
      Out_Snapshot : out Editor.Search_Results.Search_Results_Snapshot)
   is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering search results");

      Out_Snapshot := Editor.Input_Bridge.Render_Access.Search_Results_For_Render
        (Instance.State);
   end Get_Search_Results_For_Render;

   function Search_Results_Focused_For_Render
     (Instance    : Editor.Instance.Editor_Instance;
      Initialized : Boolean) return Boolean is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering focus state");
      return Editor.Input_Bridge.Render_Access.Search_Results_Focused_For_Render
        (Instance.State);
   end Search_Results_Focused_For_Render;

   function Problems_Focused_For_Render
     (Instance    : Editor.Instance.Editor_Instance;
      Initialized : Boolean) return Boolean is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering focus state");
      return Editor.Input_Bridge.Render_Access.Problems_Focused_For_Render
        (Instance.State);
   end Problems_Focused_For_Render;

   function File_Tree_Focused_For_Render
     (Instance    : Editor.Instance.Editor_Instance;
      Initialized : Boolean) return Boolean is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering file tree focus state");
      return Editor.Input_Bridge.Render_Access.File_Tree_Focused_For_Render
        (Instance.State);
   end File_Tree_Focused_For_Render;

   function Feature_Panel_For_Render
     (Instance    : Editor.Instance.Editor_Instance;
      Initialized : Boolean) return Editor.Feature_Panel.Feature_Panel_State is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering feature panel");
      return Editor.Input_Bridge.Render_Access.Feature_Panel_For_Render
        (Instance.State);
   end Feature_Panel_For_Render;

   function Feature_Panel_Focused_For_Render
     (Instance    : Editor.Instance.Editor_Instance;
      Initialized : Boolean) return Boolean is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering feature panel focus state");
      return Editor.Input_Bridge.Render_Access.Feature_Panel_Focused_For_Render
        (Instance.State);
   end Feature_Panel_Focused_For_Render;

   function File_Tree_View_For_Render
     (Instance    : Editor.Instance.Editor_Instance;
      Initialized : Boolean) return Editor.File_Tree_View.File_Tree_View_State is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering file tree view state");
      return Editor.Input_Bridge.Render_Access.File_Tree_View_For_Render
        (Instance.State);
   end File_Tree_View_For_Render;

   function Problems_View_For_Render
     (Instance    : Editor.Instance.Editor_Instance;
      Initialized : Boolean) return Editor.Problems.Problems_View_State is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering problems view state");
      return Editor.Input_Bridge.Render_Access.Problems_View_For_Render
        (Instance.State);
   end Problems_View_For_Render;

   function Project_Search_For_Render
     (Instance    : Editor.Instance.Editor_Instance;
      Initialized : Boolean) return Editor.Project_Search.Project_Search_State
   is
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before rendering project search");
      return Editor.Input_Bridge.Render_Access.Project_Search_For_Render
        (Instance.State);
   end Project_Search_For_Render;

   function Active_Diagnostic_For_Render
     (Instance : Editor.Instance.Editor_Instance)
      return Editor.Diagnostics.Diagnostic_Index
   is
   begin
      return Editor.Input_Bridge.Render_Access.Active_Diagnostic_For_Render
        (Instance.State);
   end Active_Diagnostic_For_Render;

end Editor.Input_Bridge.Render_Interface;
