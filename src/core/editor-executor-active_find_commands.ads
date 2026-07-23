with Editor.Commands;
with Editor.Search;
with Editor.State;

package Editor.Executor.Active_Find_Commands is

   function Has_Find_Target_Buffer
     (S : Editor.State.State_Type) return Boolean;

   procedure Recompute_Active_Find_Matches
     (S : in out Editor.State.State_Type);

   function Find_Match_By_Ordinal
     (S       : Editor.State.State_Type;
      Ordinal : Natural) return Editor.Search.Search_Match;

   function Selected_Find_Ordinal
     (S : Editor.State.State_Type) return Natural;

   function Active_Find_Match_Is_Selected
     (S : Editor.State.State_Type) return Boolean;

   function Active_Find_Match_Is_Current
     (S : Editor.State.State_Type) return Boolean;

   function First_Find_Ordinal_At_Or_After_Caret
     (S : Editor.State.State_Type) return Natural;

   function First_Find_Ordinal_Before_Caret
     (S : Editor.State.State_Type) return Natural;

   procedure Set_Active_Find_Query_And_Report
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Execute_Find_Case_Toggle
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_Case_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_Whole_Word_Toggle
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_Whole_Word_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_Next
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_Previous
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_First
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_Last
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_Reveal_Current
     (S : in out Editor.State.State_Type);

end Editor.Executor.Active_Find_Commands;
