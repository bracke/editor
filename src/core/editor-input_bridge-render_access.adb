with Editor.Buffers;
with Editor.Feature_Panel;
with Editor.Layout;
with Editor.Panels;
with Editor.Panel_Focus;
with Editor.Problems;
with Editor.Project;
with Editor.Render_Model;
with Editor.Search_Results;
with Editor.Settings;
with Editor.View;

package body Editor.Input_Bridge.Render_Access is

   use type Editor.Panel_Focus.Bottom_Focus_Content;

   procedure Get_Render_Snapshot
     (S            : in out Editor.State.State_Type;
      Out_Snapshot : out Editor.Render_Model.Render_Snapshot)
   is
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      if Editor.Settings.Use_Syntax_Colouring then
         Editor.State.Prepare_Syntax_For_Visible_Range
           (S,
            0,
            (if Editor.State.Line_Count (S) = 0 then 0
             else Editor.State.Line_Count (S) - 1),
            Editor.Settings.Use_Semantic_Colouring);
      end if;
      Editor.Render_Model.Build_Render_Snapshot (S, Out_Snapshot);
   end Get_Render_Snapshot;

   function File_Tree_For_Render
     (S : Editor.State.State_Type) return Editor.File_Tree.File_Tree_State is
   begin
      return S.File_Tree;
   end File_Tree_For_Render;

   function Problems_For_Render
     (S : Editor.State.State_Type) return Editor.Problems.Problems_Snapshot
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Panel  : constant Editor.Layout.Rect :=
        Editor.Layout.Panel_Rect
          (Layout,
           Editor.Panels.Bottom_Panel,
           Editor.View.Viewport_Width,
           Editor.View.Viewport_Height);
      Full   : constant Editor.Problems.Problems_Snapshot :=
        Editor.Problems.Build_Snapshot (S.Diagnostics);
      Rows   : Natural :=
        (if Editor.Layout.Cell_H = 0 then 0 else Panel.Height / Editor.Layout.Cell_H);
   begin
      if Rows > 1 then
         Rows := Rows - 1;
      end if;
      return Editor.Problems.Visible_Snapshot (Full, S.Problems_View, Rows);
   end Problems_For_Render;

   function Problems_Total_Count_For_Render
     (S : Editor.State.State_Type) return Natural is
   begin
      return Editor.Problems.Row_Count
        (Editor.Problems.Build_Snapshot (S.Diagnostics));
   end Problems_Total_Count_For_Render;

   function Search_Results_For_Render
     (S : Editor.State.State_Type) return Editor.Search_Results.Search_Results_Snapshot
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Panel  : constant Editor.Layout.Rect :=
        Editor.Layout.Panel_Rect
          (Layout,
           Editor.Panels.Bottom_Panel,
           Editor.View.Viewport_Width,
           Editor.View.Viewport_Height);
      Full   : constant Editor.Search_Results.Search_Results_Snapshot :=
        Editor.Search_Results.Build_Snapshot
          (S.Project_Search, (others => <>), Editor.Buffers.Global_Registry_For_UI);
   begin
      return Editor.Search_Results.Visible_Snapshot
        (Full,
         S.Search_Results_View,
         (if Editor.Layout.Cell_H = 0 then 0 else Panel.Height / Editor.Layout.Cell_H));
   end Search_Results_For_Render;

   function Search_Results_Focused_For_Render
     (S : Editor.State.State_Type) return Boolean is
   begin
      return Editor.Panel_Focus.Bottom_Panel_Has_Focus (S.Panel_Focus)
        and then Editor.Panel_Focus.Bottom_Content (S.Panel_Focus) =
          Editor.Panel_Focus.Search_Results_Focus;
   end Search_Results_Focused_For_Render;

   function Problems_Focused_For_Render
     (S : Editor.State.State_Type) return Boolean is
   begin
      return Editor.Panel_Focus.Bottom_Panel_Has_Focus (S.Panel_Focus)
        and then Editor.Panel_Focus.Bottom_Content (S.Panel_Focus) =
          Editor.Panel_Focus.Problems_Focus;
   end Problems_Focused_For_Render;

   function File_Tree_Focused_For_Render
     (S : Editor.State.State_Type) return Boolean is
   begin
      return Editor.Panel_Focus.File_Tree_Has_Focus (S.Panel_Focus)
        and then Editor.Project.Has_Project (S.Project)
        and then Editor.Panels.Is_Visible (S.Panels, Editor.Panels.File_Tree_Panel);
   end File_Tree_Focused_For_Render;

   function Feature_Panel_For_Render
     (S : Editor.State.State_Type) return Editor.Feature_Panel.Feature_Panel_State is
   begin
      return S.Feature_Panel;
   end Feature_Panel_For_Render;

   function Feature_Panel_Focused_For_Render
     (S : Editor.State.State_Type) return Boolean is
   begin
      return Editor.Feature_Panel.Is_Focused (S.Feature_Panel);
   end Feature_Panel_Focused_For_Render;

   function File_Tree_View_For_Render
     (S : Editor.State.State_Type) return Editor.File_Tree_View.File_Tree_View_State is
   begin
      return S.File_Tree_View;
   end File_Tree_View_For_Render;

   function Problems_View_For_Render
     (S : Editor.State.State_Type) return Editor.Problems.Problems_View_State is
   begin
      return S.Problems_View;
   end Problems_View_For_Render;

   function Project_Search_For_Render
     (S : Editor.State.State_Type) return Editor.Project_Search.Project_Search_State is
   begin
      return S.Project_Search;
   end Project_Search_For_Render;

   function Active_Diagnostic_For_Render
     (S : Editor.State.State_Type) return Editor.Diagnostics.Diagnostic_Index is
   begin
      if S.Active_Diagnostic.Has_Active then
         return S.Active_Diagnostic.Index;
      else
         return Editor.Diagnostics.No_Diagnostic;
      end if;
   end Active_Diagnostic_For_Render;

end Editor.Input_Bridge.Render_Access;
