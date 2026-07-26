with Editor.Problems;
with Editor.State;

package Editor.Executor.Diagnostics_Problems_Commands is

   procedure Execute_Problems_Move_Up
     (S : in out Editor.State.State_Type);

   procedure Execute_Problems_Move_Down
     (S : in out Editor.State.State_Type);

   procedure Execute_Problems_Page_Up
     (S : in out Editor.State.State_Type);

   procedure Execute_Problems_Page_Down
     (S : in out Editor.State.State_Type);

   procedure Execute_Problems_Open_Selected
     (S : in out Editor.State.State_Type);

   procedure Execute_Problems_Filter
     (S      : in out Editor.State.State_Type;
      Filter : Editor.Problems.Problems_Severity_Filter);

   procedure Execute_Problems_Sort
     (S    : in out Editor.State.State_Type;
      Sort : Editor.Problems.Problems_Sort_Mode);

   procedure Execute_Problems_Group
     (S     : in out Editor.State.State_Type;
      Group : Editor.Problems.Problems_Group_Mode);

   procedure Execute_Problems_Focus_Editor
     (S : in out Editor.State.State_Type);

end Editor.Executor.Diagnostics_Problems_Commands;
