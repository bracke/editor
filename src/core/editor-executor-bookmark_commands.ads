with Editor.Commands;
with Editor.State;

package Editor.Executor.Bookmark_Commands is

   function Bookmark_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   procedure Execute_Toggle_Bookmark
     (S : in out Editor.State.State_Type);

   procedure Execute_Toggle_Bookmark_At_Row
     (S   : in out Editor.State.State_Type;
      Row : Natural);

   procedure Execute_Next_Bookmark
     (S : in out Editor.State.State_Type);

   procedure Execute_Previous_Bookmark
     (S : in out Editor.State.State_Type);

   procedure Execute_Clear_Bookmarks
     (S : in out Editor.State.State_Type);

   procedure Execute_Clear_All_Bookmarks
     (S : in out Editor.State.State_Type);

   procedure Execute_Bookmark_Toggle_Current_Location
     (S : in out Editor.State.State_Type);

   procedure Execute_Bookmark_Clear_All
     (S : in out Editor.State.State_Type);

   procedure Execute_Bookmark_Next
     (S : in out Editor.State.State_Type);

   procedure Execute_Bookmark_Previous
     (S : in out Editor.State.State_Type);

   procedure Execute_Bookmark_Goto_Next
     (S : in out Editor.State.State_Type);

   procedure Execute_Bookmark_Goto_Previous
     (S : in out Editor.State.State_Type);

   procedure Execute_Bookmark_Open_Selected
     (S : in out Editor.State.State_Type);

   procedure Execute_Bookmark_Reveal_Current
     (S : in out Editor.State.State_Type);

   procedure Execute_Bookmark_Remove_Selected
     (S : in out Editor.State.State_Type);

   procedure Execute_Bookmark_Show
     (S : in out Editor.State.State_Type);

   procedure Execute_Bookmark_Hide
     (S : in out Editor.State.State_Type);

   procedure Execute_Bookmark_Toggle_Surface
     (S : in out Editor.State.State_Type);

   procedure Execute_Bookmark_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind);

end Editor.Executor.Bookmark_Commands;
