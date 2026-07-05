with Editor.Buffer_Switcher;
with Editor.Buffers;
with Editor.State;

package Editor.Executor.Buffer_Switcher_Shared is

   procedure Recompute_Buffer_Switcher
     (S : in out Editor.State.State_Type);

   function Primary_Cursor_Line_Of_Buffer
     (Id : Editor.Buffers.Buffer_Id) return Natural;

   procedure Normalize_Switcher_Preview_Target
     (S : in out Editor.State.State_Type);

   procedure Recompute_Buffer_Switcher_After_Selected_Action
     (S              : in out Editor.State.State_Type;
      Preferred_Id   : Editor.Buffers.Buffer_Id;
      Fallback_Index : Natural);

   procedure Recompute_Buffer_Switcher_After_Marked_Action
     (S : in out Editor.State.State_Type);

   function Marked_Open_Count
     (S : Editor.State.State_Type) return Natural;

   function Selected_Switcher_Buffer
     (S     : Editor.State.State_Type;
      Found : out Boolean) return Editor.Buffer_Switcher.Buffer_Switcher_Row;

   procedure Report_No_Selected_Switcher_Buffer
     (S : in out Editor.State.State_Type);

end Editor.Executor.Buffer_Switcher_Shared;
