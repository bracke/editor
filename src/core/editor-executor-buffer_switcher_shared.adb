with Editor.Buffer_Switcher;
with Editor.Buffers;
use type Editor.Buffers.Buffer_Id;
with Editor.Executor;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Project;
with Editor.Recent_Buffers;
with Editor.Render_Cache;
with Editor.State;

package body Editor.Executor.Buffer_Switcher_Shared is

   function Default_Buffer_Switcher_Config return Editor.Buffer_Switcher.Buffer_Switcher_Config is
   begin
      return (others => <>);
   end Default_Buffer_Switcher_Config;

   procedure Recompute_Buffer_Switcher
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher,
         Editor.Buffers.Global_Registry_For_UI,
         S.Recent_Buffers,
         S.Project,
         Default_Buffer_Switcher_Config);
      Editor.Render_Cache.Invalidate_All;
   end Recompute_Buffer_Switcher;

   function Primary_Cursor_Line_Of_Buffer
     (Id : Editor.Buffers.Buffer_Id) return Natural
   is
      pragma Unreferenced (Id);
   begin
      return 1;
   end Primary_Cursor_Line_Of_Buffer;

   procedure Normalize_Switcher_Preview_Target
     (S : in out Editor.State.State_Type)
   is
      Found : Boolean := False;
      Row   : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
        Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
   begin
      if not Editor.Buffer_Switcher.Has_Preview (S.Buffer_Switcher) then
         return;
      end if;

      if Found and then Row.Id /= Editor.Buffers.No_Buffer then
         Editor.Buffer_Switcher.Set_Preview_Target
           (S.Buffer_Switcher, Row.Id, Primary_Cursor_Line_Of_Buffer (Row.Id));
      else
         Editor.Buffer_Switcher.Clear_Preview_Target (S.Buffer_Switcher);
      end if;
   end Normalize_Switcher_Preview_Target;


   function Selected_Switcher_Buffer
     (S     : Editor.State.State_Type;
      Found : out Boolean) return Editor.Buffer_Switcher.Buffer_Switcher_Row
   is
   begin
      if not Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher) then
         Found := False;
         return (others => <>);
      end if;
      return Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
   end Selected_Switcher_Buffer;

   procedure Recompute_Buffer_Switcher_After_Selected_Action
     (S              : in out Editor.State.State_Type;
      Preferred_Id   : Editor.Buffers.Buffer_Id;
      Fallback_Index : Natural)
   is
   begin
      Recompute_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Select_Buffer_Or_Row
        (S.Buffer_Switcher, Preferred_Id, Fallback_Index);
      Normalize_Switcher_Preview_Target (S);
      Editor.Render_Cache.Invalidate_All;
   end Recompute_Buffer_Switcher_After_Selected_Action;

   procedure Report_No_Selected_Switcher_Buffer
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Shared_Services.Report_Info (S, "No selected buffer");
   end Report_No_Selected_Switcher_Buffer;

   function Marked_Open_Count (S : Editor.State.State_Type) return Natural is
      Count : Natural := 0;
      Registry : constant Editor.Buffers.Buffer_Registry := Editor.Buffers.Global_Registry_For_UI;
   begin
      for I in 1 .. Editor.Buffers.Count (Registry) loop
         if Editor.Buffer_Switcher.Is_Marked
           (S.Buffer_Switcher, Editor.Buffers.Summary_At (Registry, I).Id)
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Marked_Open_Count;

   procedure Recompute_Buffer_Switcher_After_Marked_Action
     (S : in out Editor.State.State_Type)
   is
      Preferred : constant Editor.Buffers.Buffer_Id :=
        Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher);
      Fallback : constant Natural := Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
   begin
      Recompute_Buffer_Switcher_After_Selected_Action (S, Preferred, Fallback);
   end Recompute_Buffer_Switcher_After_Marked_Action;

end Editor.Executor.Buffer_Switcher_Shared;
