with Editor.Commands;
with Editor.State;

package Editor.Executor.Find_Replace_Commands is

   function Find_Replace_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   function Has_Find_Target_Buffer
     (S : Editor.State.State_Type) return Boolean;

   procedure Execute_Find_Show
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_Hide
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_Toggle
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_Set_Query
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Execute_Find_Clear_Query
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_Case_Toggle
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_Case_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_Whole_Word_Toggle
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_Whole_Word_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_From_Selection
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_From_Active_Word
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

   procedure Execute_Replace_Show
     (S : in out Editor.State.State_Type);

   procedure Execute_Replace_Hide
     (S : in out Editor.State.State_Type);

   procedure Execute_Replace_Toggle
     (S : in out Editor.State.State_Type);

   procedure Execute_Replace_Set_Text
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Execute_Replace_Clear_Text
     (S : in out Editor.State.State_Type);

   procedure Execute_Replace_Current
     (S : in out Editor.State.State_Type);

   procedure Execute_Replace_All
     (S : in out Editor.State.State_Type);

   procedure Set_Active_Find_Query_And_Report
     (S    : in out Editor.State.State_Type;
      Text : String);

end Editor.Executor.Find_Replace_Commands;
